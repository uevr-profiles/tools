-- 6DOF Left handed script for Journey to the Savage Planet
-- Swaps left and right triggers, and X and B buttons
-- Code by Rusty Gere, ping me on Flat2VR Discord with any questions

local uevrUtils = require("libs/uevr_utils")
uevrUtils.initUEVR(uevr)

-- Define XINPUT button constants Microsoft XINPUT bitmasks
local XINPUT_GAMEPAD_X = 0x4000  -- X button
local XINPUT_GAMEPAD_B = 0x2000  -- B button

-- Callback for XINPUT state changes
function on_xinput_get_state(retval, user_index, state)
    if user_index == 0 then
        -- Swap left and right trigger analog values
        local leftTriggerValue = state.Gamepad.bLeftTrigger
        local rightTriggerValue = state.Gamepad.bRightTrigger
        state.Gamepad.bLeftTrigger = rightTriggerValue
        state.Gamepad.bRightTrigger = leftTriggerValue

        -- Swap X and B buttons
        local isXPressed = uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_X)
        local isBPressed = uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_B)

        if isXPressed then
            uevrUtils.unpressButton(state, XINPUT_GAMEPAD_X)
            uevrUtils.pressButton(state, XINPUT_GAMEPAD_B)
        elseif isBPressed then
            uevrUtils.unpressButton(state, XINPUT_GAMEPAD_B)
            uevrUtils.pressButton(state, XINPUT_GAMEPAD_X)
        end
    end
end