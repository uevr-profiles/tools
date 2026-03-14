UEVR_UObjectHook.activate()

local api = uevr.api
local callbacks = uevr.sdk.callbacks

local cached_weapon_mesh = nil

callbacks.on_pre_engine_tick(function(engine, delta_time)
    local pawn = api:get_local_pawn()
    if not pawn then
        cached_weapon_mesh = nil
        return
    end

    local weapon_controller = pawn.WeaponController
    if not weapon_controller then
        cached_weapon_mesh = nil
        return
    end

    local current_weapon = weapon_controller.CurrentWeapon
    if not current_weapon then
        cached_weapon_mesh = nil
        return
    end

    local weapon_mesh = current_weapon.WeaponMesh
    if not weapon_mesh then
        cached_weapon_mesh = nil
        return
    end

    local visible = true
    pcall(function()
        visible = weapon_mesh:IsVisible()
    end)

    if not visible then
        cached_weapon_mesh = nil
        return
    end

    if weapon_mesh ~= cached_weapon_mesh then
        local body_mesh = pawn.Mesh
        if body_mesh then
            pcall(function()
                weapon_mesh:K2_AttachToComponent(body_mesh, "hand_r", 1, 1, 1, false)
            end)
        end
        cached_weapon_mesh = weapon_mesh
    end

    local target_loc = { X = 0.182, Y = 166.238, Z = -70.337 }
    local target_rot = { Pitch = 0.254, Yaw = -0.443, Roll = 0.117 }

    pcall(function()
        weapon_mesh:K2_SetRelativeLocationAndRotation(target_loc, target_rot, false, nil, false)
    end)
end)