local api = uevr.api
local vr = uevr.params.vr
local params = uevr.params
local callbacks = params.sdk.callbacks

local uevrUtils = require('libs/uevr_utils')
local configui = require('libs/configui')
local hands = require('libs/hands')
local controllers = require('libs/controllers')
local enteringRoom = false


local viewTargetTransitionParams_c = uevrUtils.find_required_object("ScriptStruct /Script/Engine.ViewTargetTransitionParams")
local empty_viewTargetTransitionParams = StructObject.new(viewTargetTransitionParams_c)
local hitresult_c = uevrUtils.find_required_object("ScriptStruct /Script/Engine.HitResult")
local empty_hitresult = StructObject.new(hitresult_c)


local lastFixedCamera = nil
local fixedCameras3rdPersonMode = false
local fixedCameras3rdPersonModeJustChanged = false

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    local pawn = api:get_local_pawn()
    if pawn ~= nil and pawn.GameInstance ~= nil then
        if enteringRoom == false then
            if pawn.bIsEnteringRoom == true then
                enteringRoom = true --entering
            end
        else 
            if pawn.bIsEnteringRoom == false then
                enteringRoom = false -- entered
            end
        end
    end
    
    if isMainMenu() then
        applyMainMenuSettings()
    elseif fixedCameras3rdPersonMode == true or enteringRoom == true then
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
        if player.PlayerCameraManager ~= nil and player.PlayerCameraManager.ViewTarget ~= nil and player.PlayerCameraManager.ViewTarget.Target ~= nil then                    
			return string.find(player.PlayerCameraManager.ViewTarget.Target:get_full_name(), "CineCameraActor")
		end
	end
	return false
end

function applyFixedCameras3rdPersonModeSettings()
	normalPlay = false
	--vr.set_mod_value("VR_2DScreenMode", true)
	--vr.set_mod_value("UI_Distance", 3.320)

	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
				
	--vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	--vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	--vr.set_mod_value("VR_CameraUpOffset", "0.000000")
	--vr.set_mod_value("VR_CameraRightOffset", "-10.000000")
	--vr.set_mod_value("VR_CameraUpOffset", "13.000000")				
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
		
		pawn.Mesh:SetVisibility(false)
		pawn.Mesh:SetRenderInMainPass(false)
		pawn.Mesh:SetRenderCustomDepth(false)
		pawn.Mesh:SetCastShadow(false)
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
				end
				player.PlayerCameraManager.ViewTarget.Target = pawn
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
	if normalPlay == true then
		if (state ~= nil) then		
			state.Gamepad.sThumbLX = state.Gamepad.sThumbRX  --control tank X axis via R stick						
			state.Gamepad.sThumbRX  = 0 --disable R stick X as it will be used to move tank 
		end 
	end
	if not isMainMenu() then	
    -- Check for right thumbstick press
    if state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_THUMB ~= 0 then
        if fixedCameras3rdPersonModeJustChanged == false then
            fixedCameras3rdPersonMode = not fixedCameras3rdPersonMode
            fixedCameras3rdPersonModeJustChanged = true
        end

        print(fixedCameras3rdPersonMode)

        -- Clear the button so it won't retrigger
        state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_RIGHT_THUMB

    else -- right thumbstick released
        if fixedCameras3rdPersonModeJustChanged == true then
            fixedCameras3rdPersonModeJustChanged = false
        
uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if state == nil or not normalPlay then return end

    local pawn = api:get_local_pawn(0)
    if pawn == nil then return end

    -- Read HMD yaw every frame
    local hmd_rot = uevr.params.vr:get_hmd_rotation()
    local hmd_yaw = hmd_rot.Yaw

    -- Right stick modifies OFFSET, not absolute yaw
    local rx = state.Gamepad.sThumbRX
    local DEADZONE = 8000

    if math.abs(rx) > DEADZONE then
        local turn = rx / 32767.0
        local TURN_SPEED = 120.0 -- deg/sec

        yawOffsetFromHMD = yawOffsetFromHMD + (turn * TURN_SPEED * uevr.delta_time)
    end

    -- Final pawn yaw = HMD + offset
    local rot = pawn:K2_GetActorRotation()
    rot.Yaw = hmd_yaw + yawOffsetFromHMD
    pawn:K2_SetActorRotation(rot, false)

    -- Block right stick from game
    state.Gamepad.sThumbRX = 0
    state.Gamepad.sThumbRY = 0
end)
        end
		end
	end
end)
