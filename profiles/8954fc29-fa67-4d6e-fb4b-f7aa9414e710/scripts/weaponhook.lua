local api = uevr.api
local vr = uevr.params.vr
local uevrUtils = require('libs/uevr_utils')

local current_weapon_name = ""
local last_pawn = nil
local should_reattach = false

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta_time)    
    local pawn = api:get_local_pawn()
    if pawn == nil then return end
    
    if pawn.GetCurrentWeapon == nil then return end
    local weapon = pawn:GetCurrentWeapon()
    if weapon == nil then return end
    
    -- Re-hide bones if pawn changed (level reload, death, etc.)
    if pawn ~= last_pawn and pawn.FPVMesh then
        should_reattach = true
        last_pawn = pawn
        local mesh = pawn.FPVMesh
        if mesh ~= nil then
            -- Hide left arm
            mesh:HideBoneByName(uevrUtils.fname_from_string("l_shoulder_JNT"), 0)
            mesh:HideBoneByName(uevrUtils.fname_from_string("l_scapula_JNT"), 0)
            mesh:HideBoneByName(uevrUtils.fname_from_string("l_upperArm_JNT"), 0)
            mesh:HideBoneByName(uevrUtils.fname_from_string("l_lowerArm_JNT"), 0)
            mesh:HideBoneByName(uevrUtils.fname_from_string("l_wrist_JNT"), 0)
            -- Hide right arm
            mesh:HideBoneByName(uevrUtils.fname_from_string("r_shoulder_JNT"), 0)
            mesh:HideBoneByName(uevrUtils.fname_from_string("r_scapula_JNT"), 0)
            mesh:HideBoneByName(uevrUtils.fname_from_string("r_upperArm_JNT"), 0)
            mesh:HideBoneByName(uevrUtils.fname_from_string("r_lowerArm_JNT"), 0)
            mesh:HideBoneByName(uevrUtils.fname_from_string("r_wrist_JNT"), 0)
            print("Hid arm bones")
        end
    end
    
    local weapon_name = weapon:get_full_name()
    if current_weapon_name == weapon_name then return end
    
    current_weapon_name = weapon_name
    print("Weapon changed: ", weapon_name)
    
    -- Hide TPV mesh
    if weapon.GetTPVMeshComponent then
        local tpv_mesh = weapon:GetTPVMeshComponent()
        if tpv_mesh then
            tpv_mesh:SetVisibility(false, true)
        end
    end
    
    -- Use FPV mesh
    local mesh = nil
    if weapon.GetFPVMeshComponent then
        mesh = weapon:GetFPVMeshComponent()
    end
    
    if mesh == nil then return end
    
    -- Fix weapon FOV
    if pawn.WeaponFOV then
        pawn:WeaponFOV(70.0, false)
    end
    
    if should_reattach == true then
        mesh.RelativeLocation.Z = mesh.RelativeLocation.Z - 35.0
        mesh.RelativeLocation.X = mesh.RelativeLocation.X - 25.0
    end
    --[[
    -- Attach to right controller
    if should_reattach == true then
        should_reattach = false
        local hook = UEVR_UObjectHook.get_or_add_motion_controller_state(mesh)
        if hook then
            hook:set_permanent(true)
            hook:set_hand(1)
        end
    end
    ]]
end)