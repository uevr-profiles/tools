local api = uevr.api
local vr = uevr.params.vr
local callbacks = uevr.params.sdk.callbacks

local configui = require('libs/configui')

-------------------------------------------------------------
-- Button Mapping Configuration
-------------------------------------------------------------
-- XINPUT button bitmasks:
-- 0x0001 = D-Pad Up
-- 0x0002 = D-Pad Down
-- 0x0004 = D-Pad Left
-- 0x0008 = D-Pad Right
-- 0x0010 = Start
-- 0x0020 = Back
-- 0x0040 = Left Stick Click (L3)
-- 0x0080 = Right Stick Click (R3)
-- 0x0100 = LB (Left Bumper)
-- 0x0200 = RB (Right Bumper)
-- 0x1000 = A Button
-- 0x2000 = B Button
-- 0x4000 = X Button
-- 0x8000 = Y Button
local BUTTON_OPTIONS = {
    { id = 1, name = "Right Trigger (RT)", isTrigger = true },
    { id = 2, name = "Left Trigger (LT)", isTrigger = true },
    { id = 3, name = "Right Bumper (RB)", bitmask = 0x0200 },
    { id = 4, name = "Left Bumper (LB)", bitmask = 0x0100 },
    { id = 5, name = "A Button", bitmask = 0x1000 },
    { id = 6, name = "B Button", bitmask = 0x2000 },
    { id = 7, name = "X Button", bitmask = 0x4000 },
    { id = 8, name = "Y Button", bitmask = 0x8000 },
    { id = 9, name = "Left Stick Click (LS)", bitmask = 0x0040 },
    { id = 10, name = "Right Stick Click (RS)", bitmask = 0x0080 },
    { id = 11, name = "Start Button", bitmask = 0x0010 },
    { id = 12, name = "Back Button", bitmask = 0x0020 },
    { id = 13, name = "D-Pad Up", bitmask = 0x0001 },
    { id = 14, name = "D-Pad Down", bitmask = 0x0002 },
    { id = 15, name = "D-Pad Left", bitmask = 0x0004 },
    { id = 16, name = "D-Pad Right", bitmask = 0x0008 }
}

-------------------------------------------------------------
-- Configuration UI Definition
-------------------------------------------------------------
local configDefinition = {
	{
		panelLabel = "Right Gesture-Based Melee",
		saveFile = "right_melee_configuration",
		layout = {
			{
				widgetType = "text",
				label = "=== Swing Detection Settings ===",
			},
			{
				widgetType = "slider_float",
				id = "swing_speed_right",
				label = "Swing Speed Threshold",
				initialValue = 2.5,
				range = {"0.5", "10.0"}
			},
			{
				widgetType = "text",
				label = "Lower = more sensitive, Higher = requires faster swings",
			},
			{
				widgetType = "text",
				label = "=== Trigger Output Settings ===",
			},
			{
				widgetType = "combo",
				id = "output_button_right",
				label = "Output Button",
				selections = (function()
					local names = {}
					for _, btn in ipairs(BUTTON_OPTIONS) do
						table.insert(names, btn.name)
					end
					return names
				end)(),
				initialValue = 1,
				width = 200
			},
			{
				widgetType = "text",
				label = "Select which button to inject on swing detection",
			},
			{
				widgetType = "slider_int",
				id = "button_value_right",
				label = "Button Output Value",
				initialValue = 255,
				range = {"50", "255"}
			},
			{
				widgetType = "text",
				label = "255 = full press, lower values = partial press",
			},
			{
				widgetType = "text",
				label = "For trigger buttons (RT/LT): 0-255. For others: 0 or 255",
			},
			{
				widgetType = "text",
				label = "=== Advanced Settings ===",
			},
			{
				widgetType = "checkbox",
				id = "enable_swing_detection_right",
				label = "Enable Swing Detection",
				initialValue = true
			},
			{
				widgetType = "combo",
				id = "swing_direction_right",
				label = "Swing Direction Filter",
				selections = {"Any Direction", "Horizontal Only", "Vertical Only", "Forward Only"},
				initialValue = 1,
				width = 180
			}
		}
	}
}

-- Initialize config UI
configui.create(configDefinition)

-------------------------------------------------------------
-- Internal state
-------------------------------------------------------------
local last_pos = Vector3f.new(0,0,0)
local first = true
local swing_candidate = false

-------------------------------------------------------------
-- Helper function to get config values with defaults
-------------------------------------------------------------
local function getSwingSpeed()
    local val = configui.getValue("swing_speed_right")
    return val ~= nil and val or 2.5
end

local function getButtonValue()
    local val = configui.getValue("button_value_right")
    return val ~= nil and val or 255
end

local function getOutputButton()
    local val = configui.getValue("output_button_right")
    return val ~= nil and val or 1  -- Default to RT (index 1)
end

local function getSelectedButtonConfig()
    local buttonIndex = getOutputButton()
    return BUTTON_OPTIONS[buttonIndex] or BUTTON_OPTIONS[1]
end

local function isEnabled()
    local val = configui.getValue("enable_swing_detection_right")
    return val == nil or val == true
end

local function getSwingDirection()
    local val = configui.getValue("swing_direction_right")
    return val ~= nil and val or 1
end

-------------------------------------------------------------
-- ENGINE TICK
-- Detect swing on RIGHT controller
-------------------------------------------------------------
callbacks.on_pre_engine_tick(function(engine, delta)
    if not isEnabled() then
        swing_candidate = false
        return
    end

    local pos_raw = UEVR_Vector3f.new()
    local rot_raw = UEVR_Quaternionf.new()

    -- RIGHT controller pose
    vr.get_pose(vr.get_right_controller_index(), pos_raw, rot_raw)

    local pos = Vector3f.new(pos_raw.x, pos_raw.y, pos_raw.z)

    if first then
        last_pos:set(pos.x, pos.y, pos.z)
        first = false
        return
    end

    local vel = (pos - last_pos) * (1 / delta)
    local speed = vel:length()

    -- Direction-based filtering
    local direction = getSwingDirection()
    local passesFilter = false

    if direction == 1 then
        -- Any Direction
        passesFilter = speed > getSwingSpeed()
    elseif direction == 2 then
        -- Horizontal Only (X and Z axes)
        local horizontalSpeed = math.sqrt(vel.x * vel.x + vel.z * vel.z)
        passesFilter = horizontalSpeed > getSwingSpeed()
    elseif direction == 3 then
        -- Vertical Only (Y axis)
        local verticalSpeed = math.abs(vel.y)
        passesFilter = verticalSpeed > getSwingSpeed()
    elseif direction == 4 then
        -- Forward Only (Z axis, negative direction typically forward)
        local forwardSpeed = math.abs(vel.z)
        passesFilter = forwardSpeed > getSwingSpeed()
    end

    last_pos:set(pos.x, pos.y, pos.z)

    if passesFilter then
        swing_candidate = true
    end
end)

-------------------------------------------------------------
-- XINPUT
-- Inject selected button when swing detected
-------------------------------------------------------------
callbacks.on_xinput_get_state(function(retval, user_index, state)
    if state == nil then return end

    if swing_candidate then
        -- Get the selected button configuration
        local buttonConfig = getSelectedButtonConfig()
        local buttonVal = getButtonValue()

        -- Handle trigger buttons (RT/LT) which use analog values (0-255)
        if buttonConfig.isTrigger then
            -- ID 1 = RT, ID 2 = LT
            if buttonConfig.id == 1 then
                state.Gamepad.bRightTrigger = buttonVal
            elseif buttonConfig.id == 2 then
                state.Gamepad.bLeftTrigger = buttonVal
            end
        -- Handle all other buttons (bumpers, face buttons, stick clicks, start/back, D-pad)
        -- These all use bitmasks in wButtons - use Lua's | operator directly
        elseif buttonConfig.bitmask then
            state.Gamepad.wButtons = state.Gamepad.wButtons | buttonConfig.bitmask
        end

        swing_candidate = false
    end
end)
