
	local vr = uevr.params.vr
	
    local leftTrigger = false
    local rightTrigger = false
	local DPAD_UP = false
	local DPAD_DOWN = false
	local DPAD_LEFT = false
	local DPAD_RIGHT = false
	local START = false
	local BACK = false
	local LEFT_THUMB = false
	local RIGHT_THUMB = false
	local LEFT_SHOULDER = false
	local RIGHT_SHOULDER = false
	local GAMEPAD_Y = false
	local GAMEPAD_X = false
	local GAMEPAD_A = false
	local GAMEPAD_B = false
	
	local last_GAMEPAD_A = false
	local last_RIGHT_SHOULDER = false
	
	uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
	
		local gamepad = state.Gamepad
		
        leftTrigger = gamepad.bLeftTrigger ~= 0
        rightTrigger = gamepad.bRightTrigger ~= 0
		DPAD_UP = gamepad.wButtons & XINPUT_GAMEPAD_DPAD_UP ~= 0
		DPAD_DOWN = gamepad.wButtons & XINPUT_GAMEPAD_DPAD_DOWN ~= 0
		DPAD_LEFT = gamepad.wButtons & XINPUT_GAMEPAD_DPAD_LEFT ~= 0
		DPAD_RIGHT = gamepad.wButtons & XINPUT_GAMEPAD_DPAD_RIGHT ~= 0
		START = gamepad.wButtons & XINPUT_GAMEPAD_START ~= 0
		BACK = gamepad.wButtons & XINPUT_GAMEPAD_BACK ~= 0
		LEFT_THUMB = gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB ~= 0
		RIGHT_THUMB = gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_THUMB ~= 0
		LEFT_SHOULDER = gamepad.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER ~= 0
		RIGHT_SHOULDER = gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER ~= 0
		GAMEPAD_Y = gamepad.wButtons & XINPUT_GAMEPAD_Y ~= 0
		GAMEPAD_X = gamepad.wButtons & XINPUT_GAMEPAD_X ~= 0
		GAMEPAD_A = gamepad.wButtons & XINPUT_GAMEPAD_A ~= 0
		GAMEPAD_B = gamepad.wButtons & XINPUT_GAMEPAD_B ~= 0
		
        if LEFT_THUMB and GAMEPAD_A then -- recentralize
            gamepad.wButtons = gamepad.wButtons & ~XINPUT_GAMEPAD_LEFT_THUMB
            gamepad.wButtons = gamepad.wButtons & ~XINPUT_GAMEPAD_A
            if not last_GAMEPAD_A then
                vr.recenter_view()
                vr.recenter_horizon()
            end
        end
		
		last_GAMEPAD_A = GAMEPAD_A
		last_RIGHT_SHOULDER = RIGHT_SHOULDER
	
    end)