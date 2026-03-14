local api = uevr.api
local vr = uevr.params.vr
local params = uevr.params
local callbacks = params.sdk.callbacks

local uevrUtils = require('libs/uevr_utils')
local configui = require('libs/configui')
local hands = require('libs/hands')
local controllers = require('libs/controllers')

local hitresult_c = uevrUtils.find_required_object("ScriptStruct /Script/Engine.HitResult")
local empty_hitresult = StructObject.new(hitresult_c)

local kismet_system_library = uevrUtils.find_default_instance("Class /Script/Engine.KismetSystemLibrary")
local reusable_hit_result = uevrUtils.get_reuseable_struct_object("ScriptStruct /Script/Engine.HitResult")
local zero_color = uevrUtils.get_reuseable_struct_object("ScriptStruct /Script/CoreUObject.LinearColor")

local lastFixedCamera = nil
local fixedCameras3rdPersonMode = false
local fixedCameras3rdPersonModeJustChanged = false


local runToggled = false


local configDefinition = {
	{
		panelLabel = "Fixed Cameras starter script", 
		saveFile = "user_configuration", 
		layout = {
			{
				widgetType = "text",
				label = "=== Gameplay ===",
			},
			{
				widgetType = "combo",
				id = "movement_system",
				label = "Movement system",
				selections = {"Tank controls", "Tank controls with strafing", "Enhanced Movement"},
				initialValue = 1,
				width = 200
			},
			{
				widgetType = "combo",
				id = "game_hold_button_to_run",
				label = "Replace 'hold to run' button with left thumbstick toggle",
				selections = {"Disabled/Toggle exists already", "X", "Y", "A", "B", "LB", "RB", "LT", "RT"},
				initialValue = 1,
				width = 220
			},
			{
				widgetType = "checkbox",
				id = "maintain_improved_controls_for_fixed_cameras_mode",
				label = "Maintain improved movement for 'fixed cameras' mode (toggle run + right stick controlling tank)",
				initialValue = true
			},
			{
				widgetType = "text",
				label = "=== Misc ===",
			},
			{
				widgetType = "combo",
				id = "revert_fixed_cameras_button",
				label = "1st person/fixed cameras toggle",
				selections = {"None", "Dpad right", "Dpad left", "Dpad up", "Dpad down", "A", "B", "X", "Y", "LB", "RB", "LT", "RT", "Left Thumb", "Right Thumb", "Start", "Back"},
				initialValue = 2,
				width = 130
			},
			{
				widgetType = "checkbox",
				id = "1st_person_for_cinematic_cameras",
				label = "1st person for Cinematic Cameras",
				initialValue = false
			},
			{
				id = "enhancement_movement_label",
				widgetType = "text",
				label = "=== Enhanced Movement ===",
			},
			{
				widgetType = "slider_int",
				id = "walk_speed",
				label = "Walk Speed (To match game: AcknowledgedPawn.CharacterMovement.MaxWalkSpeed)",
				initialValue = 750,
				range = {"10", "6000"}
			},
			{
				widgetType = "slider_float",
				id = "turn_speed",
				label = "Turn Speed",
				initialValue = 0.10,
				range = {"0.01", "2.0"}
			},
			{
				widgetType = "slider_float",
				id = "run_speed_multiplier",
				label = "Run speed multiplier (walk speed * multiplier = run speed)",
				initialValue = 2,
				range = {"0.01", "5"}
			},
			{
				widgetType = "slider_int",
				id = "strafe_speed",
				label = "Strafing Speed",
				initialValue = 3,
				range = {"1", "20"}
			},
			{
				widgetType = "slider_int",
				id = "move_back_speed",
				label = "Move back speed",
				initialValue = 3,
				range = {"1", "20"}
			},
			{
				widgetType = "combo",
				id = "strafe_and_back_compatibility_mode",
				label = "Strafing/Moving back compatibility mode",
				selections = {"Sweep and Teleport - on (Recommended)", "Sweep - on, Teleport - off", "Sweep - off, Teleport - on", "Sweep and Teleport - off"},
				initialValue = 1,
				width = 300
			},
			{
				widgetType = "checkbox",
				id = "strafe_and_back_collision_detection",
				label = "Strafing/Moving back collision detection",
				initialValue = false
			},
			{
				id = "enhancement_movement_left_stick_label1",
				widgetType = "text",
				label = "=== Enhanced Movement button + left stick options ===",
			},
			{
				id = "enhancement_movement_left_stick_label2",
				widgetType = "text",
				label = "Enable for actions that require a button + left stick together (e.g. dodge, jump, etc...)",
			},
			{
				widgetType = "checkbox",
				id = "enhancement_movement_left_stick_a",
				label = "Support A + left stick",
				initialValue = false
			},
			{
				widgetType = "checkbox",
				id = "enhancement_movement_left_stick_x",
				label = "Support X + left stick",
				initialValue = false
			},	
			{
				widgetType = "checkbox",
				id = "enhancement_movement_left_stick_b",
				label = "Support B + left stick",
				initialValue = false
			},		
			{
				widgetType = "checkbox",
				id = "enhancement_movement_left_stick_y",
				label = "Support Y + left stick",
				initialValue = false
			},
			{
				widgetType = "checkbox",
				id = "enhancement_movement_left_stick_lb",
				label = "Support LB + left stick",
				initialValue = false
			},
			{
				widgetType = "checkbox",
				id = "enhancement_movement_left_stick_rb",
				label = "Support RB + left stick",
				initialValue = false
			},
			{
				widgetType = "checkbox",
				id = "enhancement_movement_left_stick_lt",
				label = "Support LT + left stick",
				initialValue = false
			},
			{
				widgetType = "checkbox",
				id = "enhancement_movement_left_stick_rt",
				label = "Support RT + left stick",
				initialValue = false
			},
			{
				widgetType = "checkbox",
				id = "invert_left_stick",
				label = "Invert left stick",
				initialValue = false
			}
		}
	}
}

function onMovementSystemChanged(i)
	print(i)
	configui.hideWidget("game_hold_button_to_run", i == 3)
	configui.hideWidget("maintain_improved_controls_for_fixed_cameras_mode", i == 3)
	configui.hideWidget("enhancement_movement_label", i == 1)
	configui.hideWidget("walk_speed", i ~= 3)
	configui.hideWidget("turn_speed", i ~= 3)
	configui.hideWidget("run_speed_multiplier", i ~= 3)
	configui.hideWidget("strafe_speed", i ==1)
	configui.hideWidget("strafe_and_back_compatibility_mode", i ==1)
	configui.hideWidget("strafe_and_back_collision_detection", i ==1)
	configui.hideWidget("move_back_speed", i ~= 3)	
	configui.hideWidget("enhancement_movement_left_stick_label1", i ~= 3)
	configui.hideWidget("enhancement_movement_left_stick_label2", i ~= 3)
	configui.hideWidget("enhancement_movement_left_stick_a", i ~= 3)
	configui.hideWidget("enhancement_movement_left_stick_x", i ~= 3)
	configui.hideWidget("enhancement_movement_left_stick_b", i ~= 3)
	configui.hideWidget("enhancement_movement_left_stick_y", i ~= 3)
	configui.hideWidget("enhancement_movement_left_stick_lb", i ~= 3)
	configui.hideWidget("enhancement_movement_left_stick_rb", i ~= 3)
	configui.hideWidget("enhancement_movement_left_stick_lt", i ~= 3)
	configui.hideWidget("enhancement_movement_left_stick_rt", i ~= 3)
	configui.hideWidget("invert_left_stick", i ~= 3)
end

configui.create(configDefinition)
if configui.getValue("movement_system") ~= nil then
	onMovementSystemChanged(configui.getValue("movement_system"))
	configui.create(configDefinition)
end

configui.onUpdate("movement_system", function() onMovementSystemChanged(configui.getValue("movement_system")) end)

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	if isMainMenu() then
		applyMainMenuSettings()
	elseif fixedCameras3rdPersonMode == true then
		applyFixedCameras3rdPersonModeSettings()
	elseif isInCutScene() then
		applyCinematicSettings()
	else ---regular play
		applyNormalModeSettings(delta)
	end	
end)


function isMainMenu()
	local pawn = api:get_local_pawn(0)
	return pawn == nil	
end


function isInCutScene()
	local player = api:get_player_controller(0)
	if player ~= nil then
		if configui.getValue("1st_person_for_cinematic_cameras") == nil or configui.getValue("1st_person_for_cinematic_cameras") == false then
			if player.PlayerCameraManager ~= nil and player.PlayerCameraManager.ViewTarget ~= nil and player.PlayerCameraManager.ViewTarget.Target ~= nil then                    
				return string.find(player.PlayerCameraManager.ViewTarget.Target:get_full_name(), "CineCameraActor")
			end
		end
	end
	return false
end

function applyFixedCameras3rdPersonModeSettings()
	normalPlay = false
	--vr.set_mod_value("VR_2DScreenMode", true)
	--vr.set_mod_value("UI_Distance", 2.0)

	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
				
	--vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	--vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	--vr.set_mod_value("VR_CameraUpOffset", "0.000000")				
	--vr.set_mod_value("VR_LerpCameraYaw", "false")

    vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
	
	--todo: change pawn:Mesh to your mesh...
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil and pawn.Mesh ~=nil then		
		pawn.Mesh:SetVisibility(true)
		pawn.Mesh:SetRenderInMainPass(true)
		pawn.Mesh:SetRenderCustomDepth(true)
		pawn.Mesh:SetCastShadow(true)
	end
	
	UEVR_UObjectHook.set_disabled(true)
	
	if fixedCameras3rdPersonModeJustChanged and fixedCameras3rdPersonMode == true then --manual switch
		applyLastFixedCamera()
	end
end

function applyMainMenuSettings() 
	normalPlay = false

	vr.set_mod_value("VR_2DScreenMode", false)
	--vr.set_mod_value("UI_Distance", 2.0)

	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
				
	--vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	--vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	--vr.set_mod_value("VR_CameraUpOffset", "0.000000")				
	--vr.set_mod_value("VR_LerpCameraYaw", "false")

	
    vr.set_mod_value("VR_DecoupledPitchUIAdjust", "false")

	UEVR_UObjectHook.set_disabled(true)

end


function applyCinematicSettings() 
	normalPlay = false
	vr.set_mod_value("VR_2DScreenMode", true)
	--vr.set_mod_value("UI_Distance", 2.0)

	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
				
	vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	vr.set_mod_value("VR_CameraUpOffset", "0.000000")				
	vr.set_mod_value("VR_LerpCameraYaw", "false")
	
    vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
	
	
	--todo: change pawn:Mesh to your mesh...
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil and pawn.Mesh ~=nil then		
		pawn.Mesh:SetVisibility(true)
		pawn.Mesh:SetRenderInMainPass(true)
		pawn.Mesh:SetRenderCustomDepth(true)
		pawn.Mesh:SetCastShadow(true)
	end
	
	UEVR_UObjectHook.set_disabled(true)
end


function applyNormalModeSettings(delta) 
		
	vr.set_mod_value("VR_2DScreenMode", false)
	--vr.set_mod_value("UI_Distance", 2.0)


	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "1")
	vr.set_mod_value("VR_DecoupledPitch", "1")
	vr.set_mod_value("VR_CameraForwardOffset", "0.0000000")
	
	vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	vr.set_mod_value("VR_CameraUpOffset", "0.000000")				
	vr.set_mod_value("VR_LerpCameraYaw", "false")

	
    vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
	UEVR_UObjectHook.set_disabled(false)
	
	--todo: change pawn:Mesh to your mesh...

	local pawn = api:get_local_pawn(0)
	if pawn ~= nil and pawn.Mesh ~=nil then			
		normalPlay = isRegularPlay() 
		
		pawn.Mesh:SetVisibility(true)
		pawn.Mesh:SetRenderInMainPass(false)
		pawn.Mesh:SetRenderCustomDepth(false)
		pawn.Mesh:SetCastShadow(true)
	end
	
	pcall(fixDirection)
end

function isRegularPlay()
	return true
end


function fixDirection()
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		local player = api:get_player_controller(0)
		if player ~= nil then       
				if player.PlayerCameraManager ~= nil and player.PlayerCameraManager.Owner ~= nil then                    
						--player.PlayerCameraManager.Owner:ClientSetLocation(pawn:K2_GetActorLocation(), pawn:K2_GetActorRotation())
						player.PlayerCameraManager.Owner:ClientSetRotation(pawn:K2_GetActorRotation())

				end
		end
	end
end 


hook_function("Class /Script/Engine.PlayerController", "SetViewTargetWithBlend", false, 
	function(fn, obj, locals, result)
		if normalPlay then
			pcall(setNeedTofixCamera)
		end
	end,
	function(fn, obj, locals, result)
		if needToFixCamera then
			fixCamera()					
		end 
		needToFixCamera = false
	end,
true)


	
function setNeedTofixCamera()
	player = api:get_player_controller(0)
	if player.PlayerCameraManager ~= nil and player.PlayerCameraManager.ViewTarget ~= nil and player.PlayerCameraManager.ViewTarget.Target ~= nil then
		if player ~= nil and player.PlayerCameraManager.ViewTarget.Target == pawn then
			--if string.find(player.PlayerCameraManager.ViewTarget.Target:get_full_name(), "PersistentLevel.CameraActor") then
				--print("last camera switched to: ", player.PlayerCameraManager.ViewTarget.Target:get_full_name())
			--end
			needToFixCamera = true	
		end
	end
end


function fixCamera()
		local player = api:get_player_controller(0)
		if player ~= nil then       
			if player.PlayerCameraManager ~= nil and player.PlayerCameraManager.ViewTarget ~= nil and player.PlayerCameraManager.ViewTarget.Target ~= nil then
				if player.PlayerCameraManager.ViewTarget.Target ~= nil and player.PlayerCameraManager.ViewTarget.Target ~= pawn and not string.find(player.PlayerCameraManager.ViewTarget.Target:get_full_name(), "CineCameraActor") then
					lastFixedCamera = player.PlayerCameraManager.ViewTarget.Target
					print("lastFixedCamera: ", lastFixedCamera:get_full_name())
					player.PlayerCameraManager.ViewTarget.Target = pawn
				end
				if configui.getValue("1st_person_for_cinematic_cameras") ~= nil and configui.getValue("1st_person_for_cinematic_cameras") == true then
					player.PlayerCameraManager.ViewTarget.Target = pawn
				end
			end
		end
end

function applyLastFixedCamera()
	print("applying last fixed camera")
	if lastFixedCamera ~= nil then
		local player = api:get_player_controller(0)
		if player ~= nil then       
			if player.PlayerCameraManager ~= nil and player.PlayerCameraManager.ViewTarget ~= nil and player.PlayerCameraManager.ViewTarget.Target ~= nil then	
				player.PlayerCameraManager.ViewTarget.Target = lastFixedCamera
				print("applied last fixed camera", lastFixedCamera:get_full_name())
			end
		end
	end
end

uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
	if normalPlay then
		fixCamera()
	end
end)


uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
	if (state ~= nil) then
		if configui.getValue("movement_system") == nil or configui.getValue("movement_system") ~= 3 then --tank or tank with strafe				
			if normalPlay == true then
				if configui.getValue("movement_system") ~= 2 then -- tank with strafe
					if state.Gamepad.sThumbLX > 15000 or state.Gamepad.sThumbLX < -15000 then
						strafe(state.Gamepad.sThumbLX)
					end
				end
			end
			if normalMode == true or configui.getValue("maintain_improved_controls_for_fixed_cameras_mode") == nil or configui.getValue("maintain_improved_controls_for_fixed_cameras_mode") == true then 	
				state.Gamepad.sThumbLX = state.Gamepad.sThumbRX  --control tank X axis via R stick						
				state.Gamepad.sThumbRX  = 0 --disable R stick X as it will be used to move tank 
			
				if configui.getValue("game_hold_button_to_run") ~= nil and configui.getValue("game_hold_button_to_run") ~= 1 then
					--switch run to toggle left thumb stick
					if not runToggled then
						if state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB ~= 0 and state.Gamepad.sThumbLY > 10000 then
							clickRunButton()
							runToggled = true	
						end	
					else
						if state.Gamepad.sThumbLY < 10000  then
							runToggled = false
						else -- run is toggled - press X 
							clickRunButton()
						end
					end
				end
			end
		elseif configui.getValue("movement_system") == 3 then  -- enhanced movement (works in all modes)
			-- Check if left stick inversion is enabled
			local ly_value = state.Gamepad.sThumbLY
			local lx_value = state.Gamepad.sThumbLX
			local ly_sprint = ly_value  -- Store original for sprint check

			if configui.getValue("invert_left_stick") ~= nil and configui.getValue("invert_left_stick") == true then
				ly_value = -ly_value
				lx_value = -lx_value
			end

			--switch run to toggle left thumb stick (always use original value for sprint - push up to sprint)
			if not runToggled then
				if state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB ~= 0 and ly_sprint > 10000 then
					runToggled = true
					--print("runToggled")
				end
			else
				if ly_sprint < 10000  then
					runToggled = false
					--print("runToggled end")
				end
			end

			if state.Gamepad.sThumbRX > 10000 or state.Gamepad.sThumbRX < -10000 then
				turn(state.Gamepad.sThumbRX/1000)
			end

			if ly_value > 10000 or ly_value < -10000 then
				moveForward(ly_value)
			end

			if lx_value > 15000 or lx_value < -15000 then
				strafe(lx_value)
			end
			
			--disable R stick X - use movement functions instead
			state.Gamepad.sThumbRX  = 0
			
			-- disable L stick - use movement functions instead 
			local disableSThumbL = true
			if configui.getValue("enhancement_movement_left_stick_a") ~= nil and configui.getValue("enhancement_movement_left_stick_a") == true then
				if state.Gamepad.wButtons & XINPUT_GAMEPAD_A ~= 0 then 
					disableSThumbL = false
				end
			end
			if configui.getValue("enhancement_movement_left_stick_x") ~= nil and configui.getValue("enhancement_movement_left_stick_x") == true then
				if state.Gamepad.wButtons & XINPUT_GAMEPAD_X ~= 0 then 
					disableSThumbL = false
				end
			end
			if configui.getValue("enhancement_movement_left_stick_b") ~= nil and configui.getValue("enhancement_movement_left_stick_b") == true then
				if state.Gamepad.wButtons & XINPUT_GAMEPAD_B ~= 0 then 
					disableSThumbL = false
				end
			end
			if configui.getValue("enhancement_movement_left_stick_y") ~= nil and configui.getValue("enhancement_movement_left_stick_y") == true then
				if state.Gamepad.wButtons & XINPUT_GAMEPAD_Y ~= 0 then 
					disableSThumbL = false
				end
			end
			if configui.getValue("enhancement_movement_left_stick_lb") ~= nil and configui.getValue("enhancement_movement_left_stick_lb") == true then
				if state.Gamepad.bLeftButton >= 200  then 
					disableSThumbL = false
				end
			end
			if configui.getValue("enhancement_movement_left_stick_rb") ~= nil and configui.getValue("enhancement_movement_left_stick_rb") == true then
				if state.Gamepad.bRightButton >= 200  then 
					disableSThumbL = false
				end
			end
			if configui.getValue("enhancement_movement_left_stick_lt") ~= nil and configui.getValue("enhancement_movement_left_stick_lt") == true then
				if state.Gamepad.bLeftTrigger >= 200  then 
					disableSThumbL = false
				end
			end
			if configui.getValue("enhancement_movement_left_stick_rt") ~= nil and configui.getValue("enhancement_movement_left_stick_rt") == true then
				if state.Gamepad.bRightTrigger >= 200  then 
					disableSThumbL = false
				end
			end
			if disableSThumbL == true then
				state.Gamepad.sThumbLX = 0 
				state.Gamepad.sThumbLY = 0
			end
		end
	end 
	if not isMainMenu() then
		if configui.getValue("revert_fixed_cameras_button") == nil or configui.getValue("revert_fixed_cameras_button") ~= 1 then
			local buttonPressed = false
			local revertButton = getRevertTo3rdPersonModeButton()

			-- Check for special buttons (LB, RB, LT, RT, Left Thumb, Right Thumb, Start, Back)
			if revertButton == "LB" then
				buttonPressed = state.Gamepad.bLeftButton >= 200
			elseif revertButton == "RB" then
				buttonPressed = state.Gamepad.bRightButton >= 200
			elseif revertButton == "LT" then
				buttonPressed = state.Gamepad.bLeftTrigger >= 200
			elseif revertButton == "RT" then
				buttonPressed = state.Gamepad.bRightTrigger >= 200
			elseif revertButton == "LTHUMB" then
				buttonPressed = state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB ~= 0
			elseif revertButton == "RTHUMB" then
				buttonPressed = state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_THUMB ~= 0
			elseif revertButton == "START" then
				buttonPressed = state.Gamepad.wButtons & XINPUT_GAMEPAD_START ~= 0
			elseif revertButton == "BACK" then
				buttonPressed = state.Gamepad.wButtons & XINPUT_GAMEPAD_BACK ~= 0
			elseif revertButton ~= nil then
				buttonPressed = state.Gamepad.wButtons & revertButton ~= 0
			end

			if buttonPressed then --toggle fixedCameras3rdPersonMode
				if fixedCameras3rdPersonModeJustChanged == false then
					fixedCameras3rdPersonMode = not fixedCameras3rdPersonMode
					fixedCameras3rdPersonModeJustChanged = true
					--if fixedCameras3rdPersonMode == true then
					--	applyLastFixedCamera()
					--end
				end
				print(fixedCameras3rdPersonMode)
				-- Clear the button if it's a standard button
				if revertButton ~= nil and revertButton ~= "LB" and revertButton ~= "RB" and revertButton ~= "LT" and revertButton ~= "RT" and revertButton ~= "LTHUMB" and revertButton ~= "RTHUMB" and revertButton ~= "START" and revertButton ~= "BACK" then
					state.Gamepad.wButtons = state.Gamepad.wButtons - revertButton
				end
			else --dpad down released
				if fixedCameras3rdPersonModeJustChanged == true then
					fixedCameras3rdPersonModeJustChanged = false
				end
			end
		end
	end
end)

function getRevertTo3rdPersonModeButton()
	--selections = {"None", "Dpad right", "Dpad left", "Dpad up", "Dpad down", "A", "B", "X", "Y", "LB", "RB", "LT", "RT", "Left Thumb", "Right Thumb", "Start", "Back"},
	if configui.getValue("revert_fixed_cameras_button") == nil or configui.getValue("revert_fixed_cameras_button") == 1 then
		return nil
	elseif configui.getValue("revert_fixed_cameras_button") == 2 then
		return XINPUT_GAMEPAD_DPAD_RIGHT
	elseif configui.getValue("revert_fixed_cameras_button") == 3 then
		return XINPUT_GAMEPAD_DPAD_LEFT
	elseif configui.getValue("revert_fixed_cameras_button") == 4 then
		return XINPUT_GAMEPAD_DPAD_UP
	elseif configui.getValue("revert_fixed_cameras_button") == 5 then
		return XINPUT_GAMEPAD_DPAD_DOWN
	elseif configui.getValue("revert_fixed_cameras_button") == 6 then
		return XINPUT_GAMEPAD_A
	elseif configui.getValue("revert_fixed_cameras_button") == 7 then
		return XINPUT_GAMEPAD_B
	elseif configui.getValue("revert_fixed_cameras_button") == 8 then
		return XINPUT_GAMEPAD_X
	elseif configui.getValue("revert_fixed_cameras_button") == 9 then
		return XINPUT_GAMEPAD_Y
	elseif configui.getValue("revert_fixed_cameras_button") == 10 then
		return "LB"
	elseif configui.getValue("revert_fixed_cameras_button") == 11 then
		return "RB"
	elseif configui.getValue("revert_fixed_cameras_button") == 12 then
		return "LT"
	elseif configui.getValue("revert_fixed_cameras_button") == 13 then
		return "RT"
	elseif configui.getValue("revert_fixed_cameras_button") == 14 then
		return "LTHUMB"
	elseif configui.getValue("revert_fixed_cameras_button") == 15 then
		return "RTHUMB"
	elseif configui.getValue("revert_fixed_cameras_button") == 16 then
		return "START"
	elseif configui.getValue("revert_fixed_cameras_button") == 17 then
		return "BACK"
	end

end
function clickRunButton()
	--selections = {"None (left thumbstick toggle)", "X", "Y", "A", "B", "LB", "RB", "LT", "RT"},
	if configui.getValue("game_hold_button_to_run") == 2 then
		state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_X
	elseif configui.getValue("game_hold_button_to_run") == 3 then
		state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_Y
	elseif configui.getValue("game_hold_button_to_run") == 4 then
		state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_A
	elseif configui.getValue("game_hold_button_to_run") == 5 then
		state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_B
	elseif configui.getValue("game_hold_button_to_run") == 6 then
		state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_LEFT_SHOULDER
	elseif configui.getValue("game_hold_button_to_run") == 7 then
		state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_RIGHT_SHOULDER
	elseif configui.getValue("game_hold_button_to_run") == 8 then
		state.Gamepad.bLeftTrigger = 30000
	elseif configui.getValue("game_hold_button_to_run") == 9 then
		state.Gamepad.bRightTrigger = 30000
	end
end


--"Enhanced Movement" section start

function triggerPawnMovement()
	--optional - put here the stuff that determines if pawn moves - maybe it will help certain games not glitch when character movement is replaced by the "Enhanced Movement" system
end

function moveForward(value)
	--print("move forward", value)
	
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		if value ~= 0.0 then
			if pawn.CharacterMovement ~= nil then
				if runToggled == true then
					pawn.CharacterMovement.MaxWalkSpeed = 3000.0
					if configui.getValue("walk_speed") ~= nil and configui.getValue("run_speed_multiplier") ~= nil then
						pawn.CharacterMovement.MaxWalkSpeed = configui.getValue("walk_speed") * configui.getValue("run_speed_multiplier")
					end
				else
					pawn.CharacterMovement.MaxWalkSpeed = 1500.0
					if configui.getValue("walk_speed") ~= nil then
						pawn.CharacterMovement.MaxWalkSpeed = configui.getValue("walk_speed")
						if pawn.CharacterMovement.MaxWalkSpeedCrouched ~= nil then
							pawn.CharacterMovement.MaxWalkSpeedCrouched = configui.getValue("walk_speed")
						end
					end
				end
			end	
			if value > 0 then
				direction = pawn:GetActorForwardVector();
				pawn:AddMovementInput(direction, 1); -- the value is between 0.0 and 1.0 - set to max and let the pawn.CharacterMovement.MaxWalkSpeed control the actual speed
			else
				local currentLocation = pawn:K2_GetActorLocation()
				local currentRotation = pawn:K2_GetActorRotation()
				local speed = 3
				if configui.getValue("move_back_speed") ~= nil then
					speed =  configui.getValue("move_back_speed")
				end
				local moveDistance = math.abs(-1 * speed) -- -3 seems to be the just the right amount...

				-- Backward movement - calculate backward from rotation
				-- Convert rotation to radians
				local yawRadians = math.rad(currentRotation.Yaw)
				
				-- Calculate backward direction based on current rotation
				local backwardX = -math.cos(yawRadians)	
				local backwardY = -math.sin(yawRadians)
									
				local newLocation = {
					X = currentLocation.X + backwardX * moveDistance,
					Y = currentLocation.Y + backwardY * moveDistance,
					Z = currentLocation.Z -- Keep Z unchanged for ground movement
				}
				if configui.getValue("strafe_and_back_collision_detection") == nil or configui.getValue("strafe_and_back_collision_detection") == false then
					--prevent deadlock when switching cameras
					pcall(setActorLocation, newLocation)
				else 
					if canMoveActorToLocation(currentLocation, newLocation) then
						pcall(setActorLocation, newLocation)
					end
				end
			end
			triggerPawnMovement()
		end
	end
end

function strafe(value)
	--print("strafe", value)
	if value ~= 0 then
		local pawn = api:get_local_pawn(0)
		if pawn ~= nil then	
			local currentLocation = pawn:K2_GetActorLocation()
			local currentRotation = pawn:K2_GetActorRotation()
			local speed = 3
			if configui.getValue("strafe_speed") ~= nil then
				 speed =  configui.getValue("strafe_speed")
			end
			local moveDistance = math.abs(-1 * speed) -- -3 seems to be the just the right amount...
			local yawRadians = math.rad(currentRotation.Yaw)
			local strafeX
			local strafeY
			if value > 0 then
				strafeX = -math.sin(yawRadians)
				strafeY = math.cos(yawRadians)
			else			
				-- left movement 
				-- Calculate left direction based on current rotation
				strafeX = math.sin(yawRadians)
				strafeY = -math.cos(yawRadians)
			end
			local newLocation = {
				X = currentLocation.X + strafeX * moveDistance,
				Y = currentLocation.Y +strafeY * moveDistance,
				Z = currentLocation.Z -- Keep Z unchanged for ground movement
			}
			if configui.getValue("strafe_and_back_collision_detection") == nil or configui.getValue("strafe_and_back_collision_detection") == false then
				--prevent deadlock when switching cameras
				pcall(setActorLocation, newLocation)
			else 
				if canMoveActorToLocation(currentLocation, newLocation) then
					pcall(setActorLocation, newLocation)
				end
			end
			triggerPawnMovement()
		end
	end
end

function canMoveActorToLocation(startLocation, targetLocation)
	-- Perform a line trace from start to target to check for walls
	local world = uevrUtils.get_world()
	if world == nil then
		return true -- No world, allow movement
	end
	--[[
	https://www.youtube.com/watch?v=VNQYyoSLnh0
	
	UFUNCTION (BlueprintCallable, Category="Collision",  
	          Meta=(bIgnoreSelf="true", WorldContext="WorldContextObject", AutoCreateRefTerm="ActorsToIgnore", DisplayName="Line Trace By Channel", AdvancedDisplay="TraceColor,TraceHitColor,DrawTime", Keywords="raycast"))  
	static bool LineTraceSingle  
	(  
	    const UObject * WorldContextObject,  
	    const FVector Start,  
	    const FVector End,  
	    ETraceTypeQuery TraceChannel,   0 - visibility, 1 - camera, 2 - destructible, 3 - pawn, 4- vehicle, 5 - physicsbody, 6 - worldDynamic, 7 - worldstatic, 8-... - engine stuff
	    bool bTraceComplex,  
	    const TArray < AActor * > & ActorsToIgnore,  
	    EDrawDebugTrace::Type DrawDebugType,  
	    FHitResult & OutHit,  
	    bool bIgnoreSelf,  
	    FLinearColor TraceColor,  
	    FLinearColor TraceHitColor,  
	    float DrawTime  
	)  
	]]
	local ignore_actors = {}
	local centerOfmassHit = kismet_system_library:LineTraceSingle(world, startLocation, targetLocation, 0, true, ignore_actors, 0, reusable_hit_result, true, zero_color, zero_color, 1.0)
	--if centerOfmassHit == true then
	--	print("line trace hit", reusable_hit_result.Distance)
	--end
	return not centerOfmassHit == true

end

function setActorLocation(newLocation)
	--pawn:K2_SetActorLocation(newLocation, false, empty_hitresult, true)
	if configui.getValue("strafe_and_back_compatibility_mode") ~= nil then
		if configui.getValue("strafe_and_back_compatibility_mode") == 1 then
			pawn:K2_SetActorLocation(newLocation, true, empty_hitresult, true)
		elseif configui.getValue("strafe_and_back_compatibility_mode") == 2 then
			pawn:K2_SetActorLocation(newLocation, true, empty_hitresult, false)
		elseif configui.getValue("strafe_and_back_compatibility_mode") == 3 then
			pawn:K2_SetActorLocation(newLocation, false, empty_hitresult, true)
		elseif configui.getValue("strafe_and_back_compatibility_mode") == 4 then
			pawn:K2_SetActorLocation(newLocation, false, empty_hitresult, false)
		end
	else
											  --sweep                --teleport
		pawn:K2_SetActorLocation(newLocation, true, empty_hitresult, true)
	end
	
end

function setActorRotation(newRotation)
	pawn:K2_SetActorRotation(newRotation)
end

function turn(value)
	--print("turn")

	local turnRateGamepad = 0.10
	if configui.getValue("turn_speed") ~= nil then
		turnRateGamepad = configui.getValue("turn_speed") 
	end
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		if value ~= 0.0 then
			newRotation = pawn:K2_GetActorRotation();
			newRotation.Yaw = newRotation.Yaw + value * turnRateGamepad
			--pawn:K2_SetActorRotation(newRotation)
			pcall(setActorRotation, newRotation)
			triggerPawnMovement()
		end
	end
end

--"Enhanced Movement" section end
