-- Activate UObjectHook to ensure property access and pawn tracking are active
UEVR_UObjectHook.activate()

-- Register a callback to run every engine tick
uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    -- Retrieve the Acknowledged Pawn
    local pawn = uevr.api:get_local_pawn(0)
    
    if pawn ~= nil then
        -- Access the "CurrentPlayerAnimation" property
        local anim = pawn.CurrentPlayerAnimation
        
        -- Check if the animation property is empty
        if anim == nil or anim == "" or anim == "None" then
            -- Set Aiming Method to Right Controller
            uevr.params.vr.set_aim_method(2)
			uevr.params.vr.set_mod_value("VR_RoomscaleMovement", "true")
            --uevr.params.vr.set_decoupled_pitch_enabled(true)
        else
            -- Set Aiming Method back to Game
            uevr.params.vr.set_aim_method(0)
			uevr.params.vr.set_mod_value("VR_RoomscaleMovement", "false")
            --uevr.params.vr.set_decoupled_pitch_enabled(false)
        end
    end
end)

-- 2. Stick Remapping Logic
-- Intercepts and modifies the controller state before the game sees it
uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    local gamepad = state.Gamepad
    
    -- Check if the Y button (bitmask 0x8000) is held.
    local y_pressed = (gamepad.wButtons & 0x8000) ~= 0
    
    if y_pressed then
        -- Map Right Stick values to the Left Stick.
        gamepad.sThumbLX = gamepad.sThumbRX
        gamepad.sThumbLY = gamepad.sThumbRY
        
        -- Zero out the Right Stick
        gamepad.sThumbRX = 0
        gamepad.sThumbRY = 0
    end
end)