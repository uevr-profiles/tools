local api = uevr.api
local vr = uevr.params.vr
local callbacks = uevr.params.sdk.callbacks

-------------------------------------------------------------
-- Swing tuning
-------------------------------------------------------------
local SWING_SPEED = 2.5     -- speed threshold
local RT_VALUE    = 255     -- full press for Right Trigger

-------------------------------------------------------------
-- Internal state
-------------------------------------------------------------
local last_pos = Vector3f.new(0,0,0)
local first = true
local swing_candidate = false

-------------------------------------------------------------
-- ENGINE TICK
-- Detect swing on LEFT controller
-------------------------------------------------------------
callbacks.on_pre_engine_tick(function(engine, delta)
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

    last_pos:set(pos.x, pos.y, pos.z)

    -- Any-direction swing
    if speed > SWING_SPEED then
        swing_candidate = true
    end
end)

-------------------------------------------------------------
-- XINPUT
-- Inject Right Trigger when swing detected
-------------------------------------------------------------
callbacks.on_xinput_get_state(function(retval, user_index, state)
    if state == nil then return end

    if swing_candidate then
        -- Fire RT for one poll
        state.Gamepad.bRightTrigger = RT_VALUE
        swing_candidate = false
    end
end)

