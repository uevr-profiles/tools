local api = uevr.api
local params = uevr.params
local callbacks = params.sdk.callbacks
local trigger_clicked = false
local JustCentered = false
local in_transition = nil
local is_inactive = false
local in_menu = false
local not_active = nil
local w_time = nil
local in_intro = false
local ToiletOnce = false
local cur_speed = nil
local toilet_cut_active = false
local intro_cut_active = false
local jump_cut_active = false
local cur_cut_time = nil
local TT_Stop = false
local Intro_Stop = false
local Jump_Stop = false
local glitch_active = false
local glitch_Stop = false
local end_active = false
local end_Stop = false
local do_lock = false

print("P.T.VR_Fix_CJ117")

params.vr.set_mod_value("UI_Distance", "5.012")
params.vr.set_mod_value("UI_Size", "6.007")

local function reset_height()
	local base = UEVR_Vector3f.new()
	params.vr.get_standing_origin(base)
	local hmd_index = params.vr.get_hmd_index()
	local hmd_pos = UEVR_Vector3f.new()
	local hmd_rot = UEVR_Quaternionf.new()
	params.vr.get_pose(hmd_index, hmd_pos, hmd_rot)
	base.x = hmd_pos.x
	base.y = hmd_pos.y
	base.z = hmd_pos.z
	params.vr.set_standing_origin(base)
end

local function SceneCuts()
	local my_cut_c = api:find_uobject("Class /Script/UMG.UserWidget")
	if my_cut_c == nil then else 
		local my_cut = my_cut_c:get_objects_matching(false)

		for i, mesh in ipairs(my_cut) do
			--print(tostring(mesh:get_full_name()))
			if string.find(mesh:get_full_name(), "Transient.GameEngine_") and string.find(mesh:get_full_name(), ".ToiletCutscene_C_") then
				if toilet_cut_active == false and TT_Stop == false then
					toilet_cut_active = true
					cur_cut_time = w_time
					--print("Toilet Cut")
				end
				break
			end
			if string.find(mesh:get_full_name(), "Transient.GameEngine_") and string.find(mesh:get_full_name(), ".Intro") then
				if intro_cut_active == false and Intro_Stop == false then
					intro_cut_active = true
					cur_cut_time = w_time
					--print("Intro Cut")
				end
				break
			end
			if string.find(mesh:get_full_name(), "Transient.GameEngine_") and string.find(mesh:get_full_name(), ".Jumpscare") then
				if jump_cut_active == false and Jump_Stop == false then
					jump_cut_active = true
					cur_cut_time = w_time
					--print("Jump Cut")
				end
				break
			end
			if string.find(mesh:get_full_name(), "Transient.GameEngine_") and string.find(mesh:get_full_name(), "Glitch_") then
				if glitch_active == false and glitch_Stop == false then
					glitch_active = true
					cur_cut_time = w_time
					--print("Glitch Cut")
				end
				break
			end
			if string.find(mesh:get_full_name(), "Transient.GameEngine_") and string.find(mesh:get_full_name(), "DemoEndWidget_C_") then
				if end_active == false and end_Stop == false then
					end_active = true
					cur_cut_time = w_time
					--print("End Cut")
				end
				break
			end
		end
	end
end

local function UIFix()
	
	--LockMesh
	if do_lock == false then
		--do_lock = true
		local right_controller_index = params.vr.get_right_controller_index()
		local right_controller_position = UEVR_Vector3f.new()
		local right_controller_rotation = UEVR_Quaternionf.new()
		params.vr.get_pose(right_controller_index, right_controller_position, right_controller_rotation)
		local RControllerRot = right_controller_rotation.x
		--print("Rotation: " .. tostring(right_controller_rotation.x))
		--local LockLoc = nil
	
	
	if RControllerRot >= 0.5 then
		params.vr.set_mod_value("UI_Y_Offset", (RControllerRot*-0.70))
	elseif RControllerRot <= 0.5 and RControllerRot >= 0.0 then
		params.vr.set_mod_value("UI_Y_Offset", (RControllerRot/-10.70))
	elseif RControllerRot <= 0.0 then
		params.vr.set_mod_value("UI_Y_Offset", (RControllerRot*-5.70))
	else
		params.vr.set_mod_value("UI_Y_Offset", "0.00")
	end
	end

end

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	SceneCuts()
	

	local game_engine_class = api:find_uobject("Class /Script/Engine.GameEngine")
    local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)

    local viewport = game_engine.GameViewport
    if viewport == nil then 
		print("Viewport is nil")
        return
    end
    local world = viewport.World
	w_time = world.GameState.ReplicatedWorldTimeSeconds
	
	if w_time <= 24.0 then
		in_intro = true
	else
		in_intro = false
	end	
	
	if w_time == 0.0 then
		--print("Game Reset")
		jump_cut_active = false
		Jump_Stop = false
		glitch_active = false
		glitch_Stop = false
		toilet_cut_active = false
		TT_Stop = false
		end_active = false
		end_Stop = false
		intro_cut_active = false
		Intro_Stop = false
	end
	
	--print(tostring(w_time))
	if cur_cut_time ~= nil then
		if toilet_cut_active == true and w_time >= (cur_cut_time+4) then
			toilet_cut_active = false
			TT_Stop = true
			--print("Toilet Stopped")
		end
		if intro_cut_active == true and w_time >= (cur_cut_time+15) then
			intro_cut_active = false
			Intro_Stop = true
			--print("Intro Stopped")
		end
		if jump_cut_active == true and w_time >= (cur_cut_time+28) then
			jump_cut_active = false
			Jump_Stop = true
			--print("Jump Stopped")
		end
		if glitch_active == true and w_time >= (cur_cut_time+17) then
			glitch_active = false
			glitch_Stop = true
			--print("Glitch Stopped")
		end
		if end_active == true and w_time >= (cur_cut_time+145) then
			end_active = false
			end_Stop = true
			--print("End Stopped")
		end
		if jump_cut_active == false and Jump_Stop == true and w_time >= (cur_cut_time+50) or
			jump_cut_active == false and Jump_Stop == true and cur_cut_time > w_time then
			Jump_Stop = false
			--print("Jump Ready")
		end
	end
	
	local pawn = api:get_local_pawn(0)
	local pcont = api:get_player_controller(0)
	if pawn ~= nil then
		in_transition = pawn.Mesh.bHiddenInGame
		in_menu = pcont.bShowMouseCursor
		not_active = pcont.InactiveStateInputComponent
		if not_active == nil then 
			is_inactive = false
		else
			is_inactive = true
		end
	end	

	if pawn == nil or string.find(pawn:get_full_name(), "HoleBP") or in_transition == true or in_menu == true or is_inactive == true or in_intro == true or toilet_cut_active == true or intro_cut_active == true or jump_cut_active == true or glitch_active == true or end_active == true then
		local cur_aim = params.vr.get_aim_method()
		if cur_aim ~= 0 then
			params.vr.set_aim_method(0)
		end
		if in_menu == true then
			params.vr.set_mod_value("FrameworkConfig_AlwaysShowCursor", "true")
		else
			params.vr.set_mod_value("FrameworkConfig_AlwaysShowCursor", "false")
		end
		if pawn ~= nil then
			if string.find(pawn:get_full_name(), "HoleBP") then
				params.vr.set_mod_value("UI_Distance", "0.400")
				params.vr.set_mod_value("UI_Size", "1.00")
			else
				params.vr.set_mod_value("VR_DecoupledPitchUIAdjust", "false")
			end
		end		
	else
		local cur_aim = params.vr.get_aim_method()
		if cur_aim ~= 2 then
			params.vr.set_aim_method(2)
		end	
		params.vr.set_mod_value("FrameworkConfig_AlwaysShowCursor", "false")
		UIFix()
		params.vr.set_mod_value("UI_Distance", "5.012")
		params.vr.set_mod_value("UI_Size", "6.007")
		params.vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
	end	
	

end)		


uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)

if (state ~= nil) then

	if state.Gamepad.bRightTrigger ~= 0 then
		if trigger_clicked == false then
			trigger_clicked = true
			state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_RIGHT_THUMB
			--print("Clicked")
			--trigger_clicked = false
		end
	end
	
	if state.Gamepad.bRightTrigger == 0 then
		if trigger_clicked == true then
			trigger_clicked = false
			--print("Released")
		end
	end
	
	if state.Gamepad.bLeftTrigger ~= 0 then
		if JustCentered == false then
			JustCentered = true
			reset_height()
			params.vr.recenter_view()
		end
	end
	
	if state.Gamepad.bLeftTrigger == 0 then
		if JustCentered == true then
			JustCentered = false
		end
	end

end

end)
