local api = uevr.api
local configui = require('libs/configui')

-- Run/Sprint state
local runToggled = false

-- UI Configuration
local configDefinition = {
    {
        panelLabel = "Run/Sprint",
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
            }
        }
    }
}

-- Initialize UI
configui.create(configDefinition)

-- XInput callback for run toggle
uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if state ~= nil then
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