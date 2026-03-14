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
				selections = {"None", "Dpad right", "Dpad left", "Dpad up", "Dpad down", "Y", "LB", "RB"},
				initialValue = 2,
				width = 110
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
	configui.hideWidget("move_back_speed", i ~= 3)	
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
						player.PlayerCameraManager.Owner:ClientSetLocation(pawn:K2_GetActorLocation(), pawn:K2_GetActorRotation())
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
		elseif normalPlay == true then  -- enhanced movement
			--switch run to toggle left thumb stick
			if not runToggled then
				if state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB ~= 0 and state.Gamepad.sThumbLY > 10000 then
					runToggled = true
					--print("runToggled")
				end	
			else
				if state.Gamepad.sThumbLY < 10000  then
					runToggled = false
					--print("runToggled end")
				end
			end
			
			if state.Gamepad.sThumbRX > 10000 or state.Gamepad.sThumbRX < -10000 then
				turn(state.Gamepad.sThumbRX/1000)
			end
			if state.Gamepad.sThumbLY > 10000 or state.Gamepad.sThumbLY < -10000 then
				moveForward(state.Gamepad.sThumbLY)
			end
			
			if state.Gamepad.sThumbLX > 15000 or state.Gamepad.sThumbLX < -15000 then
				strafe(state.Gamepad.sThumbLX)
			end
			
			--disable R stick X - use movement functions instead
			state.Gamepad.sThumbRX  = 0
			
			-- disable L stick - use movement functions instead 	
			state.Gamepad.sThumbLX = 0 
			state.Gamepad.sThumbLY = 0
			
		end
	end 
	if not isMainMenu() then
		if configui.getValue("revert_fixed_cameras_button") == nil or configui.getValue("revert_fixed_cameras_button") ~= 1 then
			if state.Gamepad.wButtons & getRevertTo3rdPersonModeButton() ~= 0 then --toggle fixedCameras3rdPersonMode
				if fixedCameras3rdPersonModeJustChanged == false then
					fixedCameras3rdPersonMode = not fixedCameras3rdPersonMode
					fixedCameras3rdPersonModeJustChanged = true
					--if fixedCameras3rdPersonMode == true then
					--	applyLastFixedCamera()
					--end
				end
				print(fixedCameras3rdPersonMode)
				state.Gamepad.wButtons = state.Gamepad.wButtons - getRevertTo3rdPersonModeButton() 
			else --dpad down released
				if fixedCameras3rdPersonModeJustChanged == true then
					fixedCameras3rdPersonModeJustChanged = false
				end
			end
		end
	end
end)

function getRevertTo3rdPersonModeButton()
	--selections = {"None", "Dpad right", "Dpad left", "Dpad up", "Dpad down", "Y", "LB", "RB"},
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
		return XINPUT_GAMEPAD_Y
	elseif configui.getValue("revert_fixed_cameras_button") == 7 then
		return XINPUT_GAMEPAD_LEFT_SHOULDER
	elseif configui.getValue("revert_fixed_cameras_button") == 8 then
		return XINPUT_GAMEPAD_RIGHT_SHOULDER
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
				--prevent deadlock when switching cameras
				pcall(setActorLocation, newLocation)
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
			--prevent deadlock when switching cameras
			pcall(setActorLocation, newLocation)
			triggerPawnMovement()
		end
	end
end

function setActorLocation(newLocation)
	pawn:K2_SetActorLocation(newLocation, false, empty_hitresult, true)
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
