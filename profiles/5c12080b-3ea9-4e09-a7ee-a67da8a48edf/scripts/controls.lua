------------------------------------------------------------------------------------
-- Config
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
-- code below, do not change.
------------------------------------------------------------------------------------


uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if(state.Gamepad.sThumbLY > 25000) then
        state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_LEFT_SHOULDER;
    end
end)


