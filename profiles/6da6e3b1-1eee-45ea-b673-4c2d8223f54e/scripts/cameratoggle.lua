-- Toggles UEVR's UObjectHook system on/off using a configured Gamepad button.
-- Starts with UObjectHook DISABLED.

-- XInput Button Constants (Standard values - Hexadecimal)
-- Use these names in the 'button_to_check' variable below
local XINPUT_GAMEPAD_DPAD_UP        = 0x0001
local XINPUT_GAMEPAD_DPAD_DOWN      = 0x0002
local XINPUT_GAMEPAD_DPAD_LEFT      = 0x0004
local XINPUT_GAMEPAD_DPAD_RIGHT     = 0x0008
local XINPUT_GAMEPAD_START          = 0x0010
local XINPUT_GAMEPAD_BACK           = 0x0020
local XINPUT_GAMEPAD_LEFT_THUMB     = 0x0040 -- Left Stick Click
local XINPUT_GAMEPAD_RIGHT_THUMB    = 0x0080 -- Right Stick Click
local XINPUT_GAMEPAD_LEFT_SHOULDER  = 0x0100 -- LB
local XINPUT_GAMEPAD_RIGHT_SHOULDER = 0x0200 -- RB
local XINPUT_GAMEPAD_A              = 0x1000
local XINPUT_GAMEPAD_B              = 0x2000
local XINPUT_GAMEPAD_X              = 0x4000
local XINPUT_GAMEPAD_Y              = 0x8000

----------------------------------------------------
-- CONFIGURATION: Set the button to use for toggle
----------------------------------------------------
local button_to_check = XINPUT_GAMEPAD_DPAD_LEFT
----------------------------------------------------

-- State variables
local is_uobjecthook_enabled = false -- Start tracking as DISABLED
local button_was_pressed = false -- Track previous state for the chosen button

-- Disable UObjectHook at script startup
-- Assumes UEVR_UObjectHook object is available here
UEVR_UObjectHook.set_disabled(true)

-- Input Callback Function
local function process_input(retval, user_index, state)
    -- Only process for user 0 (primary controller) and if state is valid
    if state == nil or state.Gamepad == nil then
        return
    end

    -- Check if the configured button is currently pressed using bitwise AND
    local button_is_pressed = (state.Gamepad.wButtons & button_to_check) ~= 0

    -- Check if the button was just pressed (state changed from false to true)
    if button_is_pressed and not button_was_pressed then
        -- Toggle the locally tracked state
        is_uobjecthook_enabled = not is_uobjecthook_enabled

        -- Apply the change based on the new tracked state        
        UEVR_UObjectHook.set_disabled(not is_uobjecthook_enabled)
    end

    -- Update the previous state for the next frame
    button_was_pressed = button_is_pressed
end

-- Register the input callback (assumes it exists)
uevr.sdk.callbacks.on_xinput_get_state(process_input)

local game_engine_class = uevr.api:find_uobject("Class /Script/Engine.GameEngine")
-- run this every engine tick, *after* the world has been updated
uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)    
    -- assume single local player, index 1
    local game_engine       = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
    local player            = game_engine.GameInstance.LocalPlayers[1].PlayerController
    if player then
        local currentVT = player:GetViewTarget()
        if prevViewTarget ~= currentVT then
            --print("changed")
            --print(currentVT:get_full_name())            
            UEVR_UObjectHook.set_disabled(currentVT:get_full_name():find("BP_jRPG_Character_World",1,true)==nil)            
            prevViewTarget = currentVT
        end
    end
end)