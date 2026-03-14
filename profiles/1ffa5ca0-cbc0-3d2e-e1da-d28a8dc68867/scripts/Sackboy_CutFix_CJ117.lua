local api = uevr.api
local params = uevr.params
local callbacks = params.sdk.callbacks

local JustCentered = false
local in_menu = false
local cursor_on = false
local running_cut = false

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

params.vr.set_mod_value("VR_DecoupledPitch", "true")

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)


	local game_engine_class = api:find_uobject("Class /Script/Engine.GameEngine")
    local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)

    local viewport = game_engine.GameViewport
    if viewport == nil then 
		print("Viewport is nil")
        return
    end
    local world = viewport.World
	if world.GameState.CutsceneManager.Rep_IsRunningCutscene ~= nil then
		running_cut = world.GameState.CutsceneManager.Rep_IsRunningCutscene
	else	
		running_cut = false
	end
	
	local pawn = api:get_local_pawn(0)
	local pcont = api:get_player_controller(0)
	if pawn ~= nil then
		cursor_on = pcont.bShowMouseCursor
		in_menu = pawn.PlayerState.IsInMenu
	end	
	

	if running_cut == true then
		params.vr.set_mod_value("VR_EnableGUI", "false")
		UEVR_UObjectHook.set_disabled(true)
	else
		params.vr.set_mod_value("VR_EnableGUI", "true")
		UEVR_UObjectHook.set_disabled(false)
	end	
	

end)		


uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)

if (state ~= nil) then

	if running_cut == true or in_menu == true then
		if state.Gamepad.bLeftTrigger ~= 0 and state.Gamepad.bRightTrigger ~= 0 then
			if JustCentered == false then
				JustCentered = true
				reset_height()
				params.vr.recenter_view()
			end
		end
	end
	
	if state.Gamepad.bLeftTrigger == 0 then
		if JustCentered == true then
			JustCentered = false
		end
	end

end

end)