UEVR_UObjectHook.activate()

local api = uevr.api
local callbacks = uevr.sdk.callbacks
local vr = uevr.params.vr

local AIM_HEAD = 1
local AIM_RIGHT_CONTROLLER = 2

local last_aim = -1
local stable_want = -1
local stable_time = 0.0
local SWITCH_DELAY = 0.20

local TURN_RATE = 180.0
local DEADZONE = 0.20
local CURVE = 1.35

local turn_input = 0.0
local gameplay_active = false

local function normalize_stick(raw)
    local v = raw / 32767.0

    if v > 1.0 then v = 1.0 end
    if v < -1.0 then v = -1.0 end

    local av = math.abs(v)
    if av < DEADZONE then
        return 0.0
    end

    local scaled = (av - DEADZONE) / (1.0 - DEADZONE)
    scaled = scaled ^ CURVE

    if v < 0.0 then
        scaled = -scaled
    end

    return scaled
end

local function gun_is_active(pawn)
    local wc = pawn.WeaponController
    if not wc then return false end

    local w = wc.CurrentWeapon
    if not w then return false end

    local wm = w.WeaponMesh
    if not wm then return false end

    local ok_visible, visible = pcall(function()
        return wm:IsVisible()
    end)
    if ok_visible and visible == false then return false end

    local body = pawn.Mesh
    if not body then return false end

    local ok_parent, parent = pcall(function()
        return wm:GetAttachParent()
    end)
    if ok_parent and parent ~= body then return false end

    return true
end

callbacks.on_xinput_get_state(function(retval, user_index, state)
    if not state then
        turn_input = 0.0
        return
    end

    if not vr then
        turn_input = 0.0
        return
    end

    local lowest_index = nil
    local ok_lowest = pcall(function()
        lowest_index = vr.get_lowest_xinput_index()
    end)

    if not ok_lowest or lowest_index == nil then
        turn_input = 0.0
        return
    end

    if user_index ~= lowest_index then
        return
    end

    local using_controllers = true
    pcall(function()
        using_controllers = vr.is_using_controllers()
    end)

    if using_controllers == false then
        turn_input = 0.0
        return
    end

    if not gameplay_active then
        turn_input = 0.0
        return
    end

    turn_input = normalize_stick(state.Gamepad.sThumbRX)

    if turn_input ~= 0.0 then
        state.Gamepad.sThumbRX = 0
    end
end)

callbacks.on_pre_engine_tick(function(engine, delta_time)
    local pawn = api:get_local_pawn()
    local pc = api:get_player_controller()

    if not pawn or not pc then
        gameplay_active = false
        turn_input = 0.0
        last_aim = -1
        stable_want = -1
        stable_time = 0.0
        return
    end

    gameplay_active = true

    local want = AIM_HEAD
    if gun_is_active(pawn) then
        want = AIM_RIGHT_CONTROLLER
    end

    if want ~= stable_want then
        stable_want = want
        stable_time = 0.0
    else
        stable_time = stable_time + delta_time
    end

    if vr and stable_time >= SWITCH_DELAY and stable_want ~= last_aim then
        local ok = pcall(function()
            vr.set_aim_method(stable_want)
        end)

        if ok then
            last_aim = stable_want
        else
            last_aim = -1
        end
    end

    pawn.bUseControllerRotationYaw = false

    local control_rot = pc:GetControlRotation()

    if turn_input ~= 0.0 then
        control_rot.Yaw = control_rot.Yaw + (turn_input * TURN_RATE * delta_time)
        pc:SetControlRotation(control_rot)
        control_rot = pc:GetControlRotation()
    end

    local pawn_rot = pawn:K2_GetActorRotation()

    local new_rot = {
        Pitch = pawn_rot.Pitch,
        Yaw = control_rot.Yaw,
        Roll = pawn_rot.Roll
    }

    pawn:K2_SetActorRotation(new_rot, false)
end)

callbacks.on_script_reset(function()
    gameplay_active = false
    turn_input = 0.0
    last_aim = -1
    stable_want = -1
    stable_time = 0.0
end)