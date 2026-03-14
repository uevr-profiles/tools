local api = uevr.api
local vr = uevr.params.vr
local params = uevr.params
local callbacks = params.sdk.callbacks

local uevrUtils = require('libs/uevr_utils')
local configui = require('libs/configui')

-- Collision detection setup
local hitresult_c = uevrUtils.find_required_object("ScriptStruct /Script/Engine.HitResult")
local empty_hitresult = StructObject.new(hitresult_c)
local kismet_system_library = uevrUtils.find_default_instance("Class /Script/Engine.KismetSystemLibrary")
local reusable_hit_result = uevrUtils.get_reuseable_struct_object("ScriptStruct /Script/Engine.HitResult")
local zero_color = uevrUtils.get_reuseable_struct_object("ScriptStruct /Script/CoreUObject.LinearColor")

-- State variables
local runToggled = false
local mode3D = true
local mode3DJustChanged = false
local normalPlay = true

-- Configuration Definition
local configDefinition = {
    {
        panelLabel = "TRUE_Tank_ControlsFixedUI",
        saveFile = "true_tank_controls_config",
        layout = {
            {
                widgetType = "text",
                label = "=== Movement Settings ==="
            },
            {
                widgetType = "slider_int",
                id = "walk_speed",
                label = "Walk Speed",
                initialValue = 600,
                range = {"100", "3000"}
            },
            {
                widgetType = "slider_float",
                id = "turn_speed",
                label = "Turn Speed",
                initialValue = 0.10,
                range = {"0.01", "1.0"}
            },
            {
                widgetType = "slider_float",
                id = "run_speed_multiplier",
                label = "Run Speed Multiplier",
                initialValue = 2.0,
                range = {"1.0", "5.0"}
            },
            {
                widgetType = "slider_int",
                id = "backward_speed",
                label = "Backward Movement Speed",
                initialValue = 3,
                range = {"1", "20"}
            },
            {
                widgetType = "slider_int",
                id = "deadzone",
                label = "Stick Deadzone",
                initialValue = 12000,
                range = {"5000", "20000"}
            },
            {
                widgetType = "text",
                label = "=== Collision Detection ==="
            },
            {
                widgetType = "checkbox",
                id = "collision_detection",
                label = "Enable Collision Detection for Backward Movement",
                initialValue = true
            },
            {
                widgetType = "combo",
                id = "collision_mode",
                label = "Collision/Teleport Mode",
                selections = {"Sweep and Teleport - on", "Sweep - on, Teleport - off", "Sweep - off, Teleport - on", "Sweep and Teleport - off"},
                initialValue = 1,
                width = 280
            },
            {
                widgetType = "text",
                label = "=== 3D Mode Toggle ==="
            },
            {
                widgetType = "combo",
                id = "revert_3d_button",
                label = "Revert to 3D Mode Button",
                selections = {"None", "Dpad Right", "Dpad Left", "Dpad Up", "Dpad Down", "Y", "LB", "RB", "A", "B", "X", "R3", "BACK", "START"},
                initialValue = 2,
                width = 140
            },
            {
                widgetType = "checkbox",
                id = "show_mesh_in_3d",
                label = "Show Player Mesh in 3D Mode",
                initialValue = true
            },
            {
                widgetType = "text",
                label = "=== Run Toggle ==="
            },
            {
                widgetType = "combo",
                id = "run_button",
                label = "Run Toggle Button",
                selections = {"Left Thumbstick Click", "X", "Y", "A", "B", "LB", "RB"},
                initialValue = 1,
                width = 180
            }
        }
    }
}

-- Initialize configui
configui.create(configDefinition)

-- Apply 3D mode settings
function apply3DModeSettings()
    normalPlay = false

    vr.set_mod_value("VR_AimMethod", "0")
    vr.set_mod_value("VR_RoomscaleMovement", "0")
    vr.set_mod_value("VR_DecoupledPitch", "0")
    vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")

    local pawn = api:get_local_pawn(0)
    if pawn ~= nil then
        if configui.getValue("show_mesh_in_3d") ~= nil and configui.getValue("show_mesh_in_3d") == true then
            if pawn.Mesh ~= nil then
                pawn.Mesh:SetVisibility(true)
                pawn.Mesh:SetRenderInMainPass(true)
                pawn.Mesh:SetRenderCustomDepth(true)
                pawn.Mesh:SetCastShadow(true)
            end
        end
    end

    UEVR_UObjectHook.set_disabled(true)
end

-- Apply VR/1st person mode settings
function applyVRModeSettings()
    normalPlay = true

    vr.set_mod_value("VR_2DScreenMode", false)
    vr.set_mod_value("VR_AimMethod", "0")
    vr.set_mod_value("VR_RoomscaleMovement", "1")
    vr.set_mod_value("VR_DecoupledPitch", "1")
    vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
    vr.set_mod_value("VR_CameraRightOffset", "0.000000")
    vr.set_mod_value("VR_CameraUpOffset", "0.000000")
    vr.set_mod_value("VR_LerpCameraYaw", "false")
    vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")

    UEVR_UObjectHook.set_disabled(false)

    local pawn = api:get_local_pawn(0)
    if pawn ~= nil and pawn.Mesh ~= nil then
        pawn.Mesh:SetVisibility(true)
        pawn.Mesh:SetRenderInMainPass(false)
        pawn.Mesh:SetRenderCustomDepth(false)
        pawn.Mesh:SetCastShadow(true)
    end
end

-- Check if in main menu
function isMainMenu()
    local pawn = api:get_local_pawn(0)
    return pawn == nil
end

-- Engine tick callback
uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    if isMainMenu() then
        return
    elseif mode3D == false then
        apply3DModeSettings()
    else
        applyVRModeSettings()
    end
end)

-- Get revert button based on config
function getRevert3DButton()
    local buttonConfig = configui.getValue("revert_3d_button")
    if buttonConfig == nil or buttonConfig == 1 then
        return nil
    elseif buttonConfig == 2 then
        return XINPUT_GAMEPAD_DPAD_RIGHT
    elseif buttonConfig == 3 then
        return XINPUT_GAMEPAD_DPAD_LEFT
    elseif buttonConfig == 4 then
        return XINPUT_GAMEPAD_DPAD_UP
    elseif buttonConfig == 5 then
        return XINPUT_GAMEPAD_DPAD_DOWN
    elseif buttonConfig == 6 then
        return XINPUT_GAMEPAD_Y
    elseif buttonConfig == 7 then
        return XINPUT_GAMEPAD_LEFT_SHOULDER
    elseif buttonConfig == 8 then
        return XINPUT_GAMEPAD_RIGHT_SHOULDER
    elseif buttonConfig == 9 then
        return XINPUT_GAMEPAD_A
    elseif buttonConfig == 10 then
        return XINPUT_GAMEPAD_B
    elseif buttonConfig == 11 then
        return XINPUT_GAMEPAD_X
    elseif buttonConfig == 12 then
        return XINPUT_GAMEPAD_RIGHT_THUMB
    elseif buttonConfig == 13 then
        return XINPUT_GAMEPAD_BACK
    elseif buttonConfig == 14 then
        return XINPUT_GAMEPAD_START
    end
    return nil
end

-- Collision detection function
function canMoveActorToLocation(startLocation, targetLocation)
    local world = uevrUtils.get_world()
    if world == nil then
        return true
    end

    local ignore_actors = {}
    local hit = kismet_system_library:LineTraceSingle(world, startLocation, targetLocation, 0, true, ignore_actors, 0, reusable_hit_result, true, zero_color, zero_color, 1.0)

    return not hit
end

-- Set actor location with configurable sweep/teleport
function setActorLocation(pawn, newLocation)
    local collisionMode = configui.getValue("collision_mode")
    if collisionMode ~= nil then
        if collisionMode == 1 then
            pawn:K2_SetActorLocation(newLocation, true, empty_hitresult, true)
        elseif collisionMode == 2 then
            pawn:K2_SetActorLocation(newLocation, true, empty_hitresult, false)
        elseif collisionMode == 3 then
            pawn:K2_SetActorLocation(newLocation, false, empty_hitresult, true)
        elseif collisionMode == 4 then
            pawn:K2_SetActorLocation(newLocation, false, empty_hitresult, false)
        end
    else
        pawn:K2_SetActorLocation(newLocation, true, empty_hitresult, true)
    end
end

-- Move forward function with collision detection
function moveForward(pawn, value)
    local walkSpeed = configui.getValue("walk_speed") or 600
    local runMultiplier = configui.getValue("run_speed_multiplier") or 2.0

    if pawn.CharacterMovement ~= nil then
        if runToggled then
            pawn.CharacterMovement.MaxWalkSpeed = walkSpeed * runMultiplier
        else
            pawn.CharacterMovement.MaxWalkSpeed = walkSpeed
        end
    end

    if value > 0 then
        -- Forward movement using built-in movement system
        local direction = pawn:GetActorForwardVector()
        pawn:AddMovementInput(direction, 1)
    else
        -- Backward movement with collision detection
        local currentLocation = pawn:K2_GetActorLocation()
        local currentRotation = pawn:K2_GetActorRotation()
        local speed = configui.getValue("backward_speed") or 3
        local moveDistance = math.abs(speed)

        local yawRadians = math.rad(currentRotation.Yaw)
        local backwardX = -math.cos(yawRadians)
        local backwardY = -math.sin(yawRadians)

        local newLocation = {
            X = currentLocation.X + backwardX * moveDistance,
            Y = currentLocation.Y + backwardY * moveDistance,
            Z = currentLocation.Z
        }

        local collisionEnabled = configui.getValue("collision_detection")
        if collisionEnabled == nil or collisionEnabled == false then
            pcall(setActorLocation, pawn, newLocation)
        else
            if canMoveActorToLocation(currentLocation, newLocation) then
                pcall(setActorLocation, pawn, newLocation)
            end
        end
    end
end

-- Turn function
function turn(pawn, value)
    local turnSpeed = configui.getValue("turn_speed") or 0.10
    local newRotation = pawn:K2_GetActorRotation()
    newRotation.Yaw = newRotation.Yaw + value * turnSpeed
    pawn:K2_SetActorRotation(newRotation)
end

-- Handle run toggle based on button config
function handleRunToggle(state)
    local runButton = configui.getValue("run_button") or 1
    local triggered = false

    if runButton == 1 then
        triggered = (state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB) ~= 0
    elseif runButton == 2 then
        triggered = (state.Gamepad.wButtons & XINPUT_GAMEPAD_X) ~= 0
    elseif runButton == 3 then
        triggered = (state.Gamepad.wButtons & XINPUT_GAMEPAD_Y) ~= 0
    elseif runButton == 4 then
        triggered = (state.Gamepad.wButtons & XINPUT_GAMEPAD_A) ~= 0
    elseif runButton == 5 then
        triggered = (state.Gamepad.wButtons & XINPUT_GAMEPAD_B) ~= 0
    elseif runButton == 6 then
        triggered = (state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER) ~= 0
    elseif runButton == 7 then
        triggered = (state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER) ~= 0
    end

    return triggered
end

-- Main input callback
uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if state == nil then return end

    local pawn = api:get_local_pawn(0)

    -- Handle 3D mode toggle (works even without pawn for menu)
    if not isMainMenu() then
        local revertButton = getRevert3DButton()
        if revertButton ~= nil then
            if (state.Gamepad.wButtons & revertButton) ~= 0 then
                if mode3DJustChanged == false then
                    mode3D = not mode3D
                    mode3DJustChanged = true
                    print("3D Mode: " .. tostring(not mode3D))
                end
                state.Gamepad.wButtons = state.Gamepad.wButtons - revertButton
            else
                if mode3DJustChanged == true then
                    mode3DJustChanged = false
                end
            end
        end
    end

    if pawn == nil then return end

    local deadzone = configui.getValue("deadzone") or 12000

    -- ONLY apply custom tank controls when in 3D mode (mode3D == true)
    -- When in normal VR mode (mode3D == false), let the game handle controls normally
    if mode3D == true then
        -- Run toggle handling
        if handleRunToggle(state) and state.Gamepad.sThumbLY > deadzone then
            if not runToggled then
                runToggled = true
            end
        else
            if state.Gamepad.sThumbLY < deadzone then
                runToggled = false
            end
        end

        -- TURN LEFT / RIGHT (Tank Rotation)
        if state.Gamepad.sThumbRX > deadzone then
            turn(pawn, state.Gamepad.sThumbRX / 1000)
        elseif state.Gamepad.sThumbRX < -deadzone then
            turn(pawn, state.Gamepad.sThumbRX / 1000)
        end

        -- MOVE FORWARD / BACK
        if state.Gamepad.sThumbLY > deadzone then
            moveForward(pawn, state.Gamepad.sThumbLY)
        elseif state.Gamepad.sThumbLY < -deadzone then
            moveForward(pawn, state.Gamepad.sThumbLY)
        end

        -- Disable original stick input to prevent double input
        state.Gamepad.sThumbLX = 0
        state.Gamepad.sThumbLY = 0
        state.Gamepad.sThumbRX = 0
        state.Gamepad.sThumbRY = 0
    end
    -- When mode3D == false (normal VR mode), don't modify anything - let game controls work normally
end)
