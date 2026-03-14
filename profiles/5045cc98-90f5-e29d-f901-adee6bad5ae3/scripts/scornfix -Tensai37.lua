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

callbacks.on_pre_engine_tick(function(engine, delta_time)
    local pawn = api:get_local_pawn()
    local pc = api:get_player_controller()

    if not pawn or not pc then
        last_aim = -1
        stable_want = -1
        stable_time = 0.0
        return
    end

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
    local pawn_rot = pawn:K2_GetActorRotation()

    local new_rot = {
        Pitch = pawn_rot.Pitch,
        Yaw = control_rot.Yaw,
        Roll = pawn_rot.Roll
    }

    pawn:K2_SetActorRotation(new_rot, false)
end)