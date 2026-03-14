local api = uevr.api
local vr = uevr.params.vr
local callbacks = uevr.params.sdk.callbacks

local configui = require('libs/configui')

-------------------------------------------------------------
-- Configuration UI Definition
-------------------------------------------------------------
local configDefinition = {
	{
		panelLabel = "Left Gesture-Based Melee",
		saveFile = "left_melee_configuration",
		layout = {
			{
				widgetType = "text",
				label = "=== Swing Detection Settings ===",
			},
			{
				widgetType = "slider_float",
				id = "swing_speed",
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
				widgetType = "slider_int",
				id = "rt_value",
				label = "Right Trigger Output Value",
				initialValue = 255,
				range = {"50", "255"}
			},
			{
				widgetType = "text",
				label = "255 = full press, lower values = partial press",
			},
			{
				widgetType = "text",
				label = "=== Advanced Settings ===",
			},
			{
				widgetType = "checkbox",
				id = "enable_swing_detection",
				label = "Enable Swing Detection",
				initialValue = true
			},
			{
				widgetType = "combo",
				id = "swing_direction",
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
    local val = configui.getValue("swing_speed")
    return val ~= nil and val or 2.5
end

local function getRTValue()
    local val = configui.getValue("rt_value")
    return val ~= nil and val or 255
end

local function isEnabled()
    local val = configui.getValue("enable_swing_detection")
    return val == nil or val == true
end

local function getSwingDirection()
    local val = configui.getValue("swing_direction")
    return val ~= nil and val or 1
end

-------------------------------------------------------------
-- ENGINE TICK
-- Detect swing on LEFT controller
-------------------------------------------------------------
callbacks.on_pre_engine_tick(function(engine, delta)
    if not isEnabled() then
        swing_candidate = false
        return
    end

    local pos_raw = UEVR_Vector3f.new()
    local rot_raw = UEVR_Quaternionf.new()

    -- LEFT controller pose
    vr.get_pose(vr.get_left_controller_index(), pos_raw, rot_raw)

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
-- Inject Left Trigger when swing detected
-------------------------------------------------------------
callbacks.on_xinput_get_state(function(retval, user_index, state)
    if state == nil then return end

    if swing_candidate then
        -- Fire LT for one poll
        state.Gamepad.bLeftTrigger = getRTValue()
        swing_candidate = false
    end
end)
