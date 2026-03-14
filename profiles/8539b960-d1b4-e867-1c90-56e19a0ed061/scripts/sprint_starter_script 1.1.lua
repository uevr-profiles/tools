local api = uevr.api
local configui = require('libs/configui')

-- Run/Sprint state
local runToggled = false

-- Toggle disable state
local sprintDisabled = false
local sprintDisabledJustChanged = false

-- UI Configuration
local configDefinition = {
    {
        panelLabel = "Pawn Movement - Run/Sprint",
        saveFile = "run_sprint_config",
        layout = {
            {
                widgetType = "text",
                label = "=== Speed Settings ==="
            },
            {
                widgetType = "slider_int",
                id = "walk_speed",
                label = "Walk Speed",
                initialValue = 750,
                range = {"100", "3000"}
            },
            {
                widgetType = "slider_float",
                id = "run_speed_multiplier",
                label = "Run Speed Multiplier",
                initialValue = 2.0,
                range = {"1.0", "5.0"}
            },
            {
                widgetType = "text",
                label = "=== Toggle Disable ==="
            },
            {
                widgetType = "combo",
                id = "toggle_disable_button",
                label = "Toggle disable button",
                selections = {"None", "Dpad right", "Dpad left", "Dpad up", "Dpad down", "Y", "LB", "RB"},
                initialValue = 1,
                width = 110
            }
        }
    }
}

-- Initialize UI
configui.create(configDefinition)

-- Get the toggle disable button based on config
function getToggleDisableButton()
    local buttonSetting = configui.getValue("toggle_disable_button")
    if buttonSetting == nil or buttonSetting == 1 then
        return nil
    elseif buttonSetting == 2 then
        return XINPUT_GAMEPAD_DPAD_RIGHT
    elseif buttonSetting == 3 then
        return XINPUT_GAMEPAD_DPAD_LEFT
    elseif buttonSetting == 4 then
        return XINPUT_GAMEPAD_DPAD_UP
    elseif buttonSetting == 5 then
        return XINPUT_GAMEPAD_DPAD_DOWN
    elseif buttonSetting == 6 then
        return XINPUT_GAMEPAD_Y
    elseif buttonSetting == 7 then
        return XINPUT_GAMEPAD_LEFT_SHOULDER
    elseif buttonSetting == 8 then
        return XINPUT_GAMEPAD_RIGHT_SHOULDER
    end
end

-- XInput callback for run toggle
uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if state ~= nil then
        -- Handle toggle disable button
        if configui.getValue("toggle_disable_button") ~= nil and configui.getValue("toggle_disable_button") ~= 1 then
            if state.Gamepad.wButtons & getToggleDisableButton() ~= 0 then
                if sprintDisabledJustChanged == false then
                    sprintDisabled = not sprintDisabled
                    sprintDisabledJustChanged = true
                    print("Sprint script disabled: ", sprintDisabled)
                end
                state.Gamepad.wButtons = state.Gamepad.wButtons - getToggleDisableButton()
            else
                if sprintDisabledJustChanged == true then
                    sprintDisabledJustChanged = false
                end
            end
        end

        -- Skip sprint functionality if disabled
        if sprintDisabled then
            return
        end

        -- Toggle run on left thumbstick click + forward movement
        if not runToggled then
            if state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB ~= 0 and state.Gamepad.sThumbLY > 10000 then
                runToggled = true
            end
        else
            if state.Gamepad.sThumbLY < 10000 then
                runToggled = false
            end
        end

        -- Apply movement when left stick is pushed forward/backward
        if state.Gamepad.sThumbLY > 10000 or state.Gamepad.sThumbLY < -10000 then
            moveForward(state.Gamepad.sThumbLY)
        end
    end
end)

-- Movement function with run/walk speed handling
function moveForward(value)
    local pawn = api:get_local_pawn(0)
    if pawn ~= nil and value ~= 0.0 then
        if pawn.CharacterMovement ~= nil then
            local walkSpeed = configui.getValue("walk_speed") or 750
            local runMultiplier = configui.getValue("run_speed_multiplier") or 2.0

            if runToggled then
                pawn.CharacterMovement.MaxWalkSpeed = walkSpeed * runMultiplier
            else
                pawn.CharacterMovement.MaxWalkSpeed = walkSpeed
            end
        end

        if value > 0 then
            local direction = pawn:GetActorForwardVector()
            pawn:AddMovementInput(direction, 1)
        end
    end
end
