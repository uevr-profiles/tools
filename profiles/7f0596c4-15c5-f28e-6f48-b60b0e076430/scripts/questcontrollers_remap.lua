------------------------------------------------------------------------------------
-- Installation
-- Needs UEVR nightly 1066 or newer.
-- Copy to %appdata%\unrealvrmod\uevr\scripts folder
-- Copy the accompanying json file to %appdata%\unrealvrmod\uevr\profiles
-- Configure in the UEVR menu under the index controller tab. Configs are saved per game.
--
-- Скрипт помогает назначить дополнительные кнопки. Есть несколько блоков:
--  • ThumbrestTouchRight - работает когда кладешь палец на сенсорный скос ПРАВОГО контроллера Oculus
--  • ThumbrestTouchLeft  - работает когда кладешь палец на сенсорный скос ЛЕВОГО контроллера Oculus
--  • AButtonTouchLeft    - работает когда кладешь палец на сенсорную кнопку X ЛЕВОГО контроллера Oculus
-- Назначить можно практически любую комбинацию! Также при необходимости можно пожертвоать любой (или всеми)
-- кнопкой A,B,X,Y чтобы использовать при дотрагивании до них остальные кнопки ЛЮБОГО контроллера. Пример
-- можно увидеть в блоке AButtonTouchLeft где кнока B (X на контроллере Oculus) используется тоже как 
-- сенсорный переключатель.

------------------------------------------------------------------------------------
-- Helper section
------------------------------------------------------------------------------------
--[[
OpenXR Action Paths 
    static const inline std::string s_action_pose = "/actions/default/in/Pose";
    static const inline std::string s_action_grip_pose = "/actions/default/in/GripPose";
    static const inline std::string s_action_trigger = "/actions/default/in/Trigger";
    static const inline std::string s_action_grip = "/actions/default/in/Grip";
    static const inline std::string s_action_joystick = "/actions/default/in/Joystick";
    static const inline std::string s_action_joystick_click = "/actions/default/in/JoystickClick";

    static const inline std::string s_action_a_button_left = "/actions/default/in/AButtonLeft";
    static const inline std::string s_action_b_button_left = "/actions/default/in/BButtonLeft";
    static const inline std::string s_action_a_button_touch_left = "/actions/default/in/AButtonTouchLeft";
    static const inline std::string s_action_b_button_touch_left = "/actions/default/in/BButtonTouchLeft";

    static const inline std::string s_action_a_button_right = "/actions/default/in/AButtonRight";
    static const inline std::string s_action_b_button_right = "/actions/default/in/BButtonRight";
    static const inline std::string s_action_a_button_touch_right = "/actions/default/in/AButtonTouchRight";
    static const inline std::string s_action_b_button_touch_right = "/actions/default/in/BButtonTouchRight";

    static const inline std::string s_action_dpad_up = "/actions/default/in/DPad_Up";
    static const inline std::string s_action_dpad_right = "/actions/default/in/DPad_Right";
    static const inline std::string s_action_dpad_down = "/actions/default/in/DPad_Down";
    static const inline std::string s_action_dpad_left = "/actions/default/in/DPad_Left";
    static const inline std::string s_action_system_button = "/actions/default/in/SystemButton";
    static const inline std::string s_action_thumbrest_touch_left = "/actions/default/in/ThumbrestTouchLeft";
    static const inline std::string s_action_thumbrest_touch_right = "/actions/default/in/ThumbrestTouchRight";
    
    Trackpad actions, these are touch. You can test if trackpad is clicked to know if they're clicked instead.
    "/actions/default/in/trackpaddown"
    "/actions/default/in/trackpadup"
    "/actions/default/in/thumbresttouch"
    "/actions/default/in/thumbrestclick"
	
--------------------------------------------------------------------------------------------------------------

Кнопки действий (Buttons)
  XINPUT_GAMEPAD_A (Кнопка A)
  XINPUT_GAMEPAD_B (Кнопка B - на контроллере Oculus это X)
  XINPUT_GAMEPAD_X (Кнопка X - на контроллере Oculus это B)
  XINPUT_GAMEPAD_Y (Кнопка Y)
  XINPUT_GAMEPAD_BACK (Кнопка Back / View / Select)
  XINPUT_GAMEPAD_START (Кнопка Start / Menu)

Бамперы и Триггеры (Shoulders & Triggers)
  XINPUT_GAMEPAD_LEFT_SHOULDER (LB - Левый бампер)
  XINPUT_GAMEPAD_RIGHT_SHOULDER (RB - Правый бампер)
  XINPUT_GAMEPAD_LEFT_TRIGGER (LT - Левый триггер, аналоговое значение)
  XINPUT_GAMEPAD_RIGHT_TRIGGER (RT - Правый триггер, аналоговое значение)

Крестовина (D-Pad)
  XINPUT_GAMEPAD_DPAD_UP (Вверх)
  XINPUT_GAMEPAD_DPAD_DOWN (Вниз)
  XINPUT_GAMEPAD_LEFT (Влево)
  XINPUT_GAMEPAD_RIGHT (Вправо) 

Нажатие на стики (Thumbsticks)
  XINPUT_GAMEPAD_LEFT_THUMB (Нажатие на левый стик / L3)
  XINPUT_GAMEPAD_RIGHT_THUMB (Нажатие на правый стик / R3)
--]]


local api = uevr.api
local vr = uevr.params.vr
local param = uevr.params

local open_xr = vr.is_openxr()
local open_vr = (open_xr == false)

------------------------------------------------------------------------------------
-- on_xinput_get_state callback
------------------------------------------------------------------------------------
uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if vr.is_using_controllers() == false then return end
    if open_xr == false then return end
    
    local LeftController = vr.get_left_joystick_source()
    local RightController = vr.get_right_joystick_source()
    
    local ThumbrestTouchRight = vr.get_action_handle("/actions/default/in/ThumbrestTouchRight");
	local ThumbrestTouchLeft = vr.get_action_handle("/actions/default/in/ThumbrestTouchLeft");
	local AButtonTouchLeft = vr.get_action_handle("/actions/default/in/AButtonTouchLeft");
	local AButtonTouchRight = vr.get_action_handle("/actions/default/in/AButtonTouchRight");
	local BButtonTouchLeft = vr.get_action_handle("/actions/default/in/BButtonTouchLeft");
	local BButtonTouchRight = vr.get_action_handle("/actions/default/in/BButtonTouchRight");
	
-- ============================================== ЁМКОСТНЫЕ СЕНСОРЫ ===================================================
--------------------------------------------------------------------------------------------------
-- Назначение кнопок ThumbrestTouchRight, кнопок на ПРАВОМ КОНТРОЛЛЕРЕ, которые активируются только если
-- положить палец на скос левого контроллера Oculus в зону для отдыха большого пальца.
--------------------------------------------------------------------------------------------------

    if (vr.is_action_active(ThumbrestTouchRight, RightController)) then
		vr.trigger_haptic_vibration(0.0, 0.05, 200.0, 0.3, RightController);  
		-- При пальце на ThumbrestTouchRight кнопка Y контроллера срабатывает как Левый бампер
		if state.Gamepad.wButtons & XINPUT_GAMEPAD_Y > 0 then
			state.Gamepad.wButtons = state.Gamepad.wButtons & ~XINPUT_GAMEPAD_Y
			state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_LEFT_SHOULDER -- Левый бампер
		end
	end

--------------------------------------------------------------------------------------------------
-- Назначение кнопок ThumbrestTouchLeft, кнопок на ЛЕВОМ КОНТРОЛЛЕРЕ, которые активируются только если
-- положить палец на скос левого контроллера Oculus в зону для отдыха большого пальца.
--------------------------------------------------------------------------------------------------
--[[
	if (vr.is_action_active(ThumbrestTouchLeft, LeftController)) then
		vr.trigger_haptic_vibration(0.0, 0.05, 200.0, 0.3, LeftController);
		-- X (на контроллере Oculus это B) = LEFT SHOULDER (Левый бампер)
		if state.Gamepad.wButtons & XINPUT_GAMEPAD_X > 0 then
			state.Gamepad.wButtons = state.Gamepad.wButtons & ~XINPUT_GAMEPAD_X  -- turn off X (на контроллере Oculus это B)
			state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_LEFT_SHOULDER -- turn on LEFT SHOULDER (Левый бампер)
		end		
	end
--]]
--------------------------------------------------------------------------------------------------
-- Назначение кнопок AButtonTouchLeft (X на контроллере), кнопок на ЛЕВОМ КОНТРОЛЛЕРЕ, которые активируются
--  только если положить палец на скос левого контроллера Oculus в зону для отдыха большого пальца.
--------------------------------------------------------------------------------------------------
--[[
	if (vr.is_action_active(AButtonTouchLeft, LeftController)) then
		vr.trigger_haptic_vibration(0.0, 0.05, 200.0, 0.3, LeftController);
		-- B (на контроллере Oculus это X) = LEFT SHOULDER (Левый бампер)
		if state.Gamepad.wButtons & XINPUT_GAMEPAD_B > 0 then
			state.Gamepad.wButtons = state.Gamepad.wButtons & ~XINPUT_GAMEPAD_B  -- turn off B (на контроллере Oculus это X)
			state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_LEFT_SHOULDER -- turn on LEFT SHOULDER (Левый бампер)
		end		
	end
--]]
-- ============================================== ЁМКОСТНЫЕ СЕНСОРЫ ===================================================
  
end)

