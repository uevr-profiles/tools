local Threshold = 25000
--#################################
local forward_monitor = 0
local stick_counter = 0
local l3_down = false


uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    local LTDown = state.Gamepad.bLeftTrigger > 200


    -- Double-tap forward detection
    local stickLY = state.Gamepad.sThumbLY

    if forward_monitor == 0 and stickLY > Threshold then
        -- First forward press detected
        forward_monitor = 1
    elseif forward_monitor == 1 and stickLY < 5000 then
        -- Release detected
        forward_monitor = 2
        stick_counter = 0 -- Start counting frames
    elseif forward_monitor == 2 then
        stick_counter = stick_counter + 1
        if stick_counter > 20 then
            -- Timeout after 10 frames
            forward_monitor = 0
            stick_counter = 0
        elseif stickLY >= Threshold then
            -- Second forward press detected
            state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_LEFT_THUMB
            l3_down = true
            forward_monitor = 0
            stick_counter = 0
        end
    end

    -- Release L3 if forward is no longer held
    if stickLY < Threshold and l3_down then
        l3_down = false
        state.Gamepad.wButtons = state.Gamepad.wButtons & ~XINPUT_GAMEPAD_LEFT_THUMB
    end
end)

