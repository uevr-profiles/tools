local utils = require("common.utils")

local api = uevr.api
local vr = uevr.params.vr

local pawn = nil
local world = nil
local weapon = nil
local last_level = nil
local controller = nil
local weapon_name = nil
local weapon_state = nil
local isPaused = false
local isAiming = false
local allowHealing = false
local handsAreShown = false
local isInPauseMode = false
local allowShowHands = false
local allowWeaponSwitch = false
local isMoveInputIgnored = true
local scope_sphere_mesh = nil
local scope_sphere_state = nil
local scope_cylinder_mesh = nil
local scope_cylinder_state = nil

local leftDistance = 0.000
local rightDistance = 0.000
local pitchOffset = "0.00"
local lastPitchOffset = "0.00"
local temp_vec3 = Vector3d.new(0, 0, 0)
local temp_vec3f = Vector3f.new(0, 0, 0)

vr.set_mod_value("UI_Size", "1.15")
vr.set_mod_value("VR_AimMethod", "0")
vr.set_mod_value("UI_Distance", "1.50")
vr.set_mod_value("UI_Y_Offset", "-0.15")
vr.set_mod_value("VR_RoomscaleMovement", "false")
vr.set_mod_value("VR_CameraForwardOffset", "0.00")
vr.set_mod_value("VR_ControllerPitchOffset", "0.00")

--api:execute_command("r.EyeAdaptationQuality 0")
api:execute_command("r.EyeAdaptation.PreExposureOverride 8.0")

local function find_required_object(name)
    local object = uevr.api:find_uobject(name)
    if not object then
        return nil
    end
    return object
end

local find_static_class = function(name)
    local c = find_required_object(name)
    return c:get_class_default_object()
end

local statics = find_static_class("Class /Script/Engine.GameplayStatics")
local staic_mesh_c = utils.find_required_object("Class /Script/Engine.StaticMesh")
local ftransform_c = utils.find_required_object("ScriptStruct /Script/CoreUObject.Transform")
local staic_mesh_component_c = utils.find_required_object("Class /Script/Engine.StaticMeshComponent")
local sphere = utils.find_required_object_no_cache(staic_mesh_c, "StaticMesh /Engine/BasicShapes/Sphere.Sphere")
local cylinder = utils.find_required_object_no_cache(staic_mesh_c, "StaticMesh /Engine/BasicShapes/Cylinder.Cylinder")
local zero_transform = StructObject.new(ftransform_c)

local emissive_mesh_material = "Material /Engine/EngineMaterials/EmissiveMeshMaterial.EmissiveMeshMaterial"
local scope_mat_emissive = utils.find_required_object(emissive_mesh_material)

local flinearColor_c = utils.find_required_object("ScriptStruct /Script/CoreUObject.LinearColor")
local scopeDotColor = StructObject.new(flinearColor_c)
local scopeCircleColor = StructObject.new(flinearColor_c)

scopeDotColor.R = 1.000
scopeDotColor.A = 0.800
scopeCircleColor.R = 0.500
scopeCircleColor.G = 1.000
scopeCircleColor.A = 0.008

local function scope_components_exist(actor)
    local components = actor:K2_GetComponentsByClass(staic_mesh_component_c)
    for i, component in ipairs(components) do
        if component:get_fname():to_string():find("StaticMeshComponent") then
            return true
        end
    end
    return false
end

local function spawn_scope_mesh(actor)

    scope_sphere_mesh = actor:AddComponentByClass(staic_mesh_component_c, false, zero_transform, false)
    scope_cylinder_mesh = actor:AddComponentByClass(staic_mesh_component_c, false, zero_transform, false)

    local scope_dot_material = scope_sphere_mesh:CreateDynamicMaterialInstance(0, scope_mat_emissive, "ScopeMaterial")
    scope_dot_material:SetVectorParameterValue("Color", scopeDotColor)

    local scope_circle_material = scope_cylinder_mesh:CreateDynamicMaterialInstance(0, scope_mat_emissive, "ScopeMaterial")
    scope_circle_material:SetVectorParameterValue("Color", scopeCircleColor)

    scope_sphere_mesh:SetStaticMesh(sphere)
    scope_sphere_mesh:SetVisibility(false)
    scope_sphere_mesh:SetHiddenInGame(false)
    scope_sphere_mesh:SetCollisionEnabled(0)

    scope_cylinder_mesh:SetStaticMesh(cylinder)
    scope_cylinder_mesh:SetVisibility(false)
    scope_cylinder_mesh:SetHiddenInGame(false)
    scope_cylinder_mesh:SetCollisionEnabled(0)

    scope_sphere_mesh.RelativeScale3D.x = 0.0015
    scope_sphere_mesh.RelativeScale3D.y = 0.0015
    scope_sphere_mesh.RelativeScale3D.z = 0.0015

    scope_cylinder_mesh.RelativeScale3D.x = 0.008
    scope_cylinder_mesh.RelativeScale3D.y = 0.008
    scope_cylinder_mesh.RelativeScale3D.z = 0.001

    scope_sphere_state = UEVR_UObjectHook.get_or_add_motion_controller_state(scope_sphere_mesh)
    scope_sphere_state:set_hand(1) -- Right hand
    scope_sphere_state:set_permanent(true)
    scope_sphere_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.040))

    scope_cylinder_state = UEVR_UObjectHook.get_or_add_motion_controller_state(scope_cylinder_mesh)
    scope_cylinder_state:set_hand(1) -- Right hand
    scope_cylinder_state:set_permanent(true)
    scope_cylinder_state:set_rotation_offset(temp_vec3f:set(1.570, 0.000, 0.040))

    print("scope mesh created")
end

local function on_level_changed()
    if pawn and scope_sphere_mesh then
        pawn:K2_DestroyComponent(scope_sphere_mesh)
        pawn:K2_DestroyComponent(scope_cylinder_mesh)
    end
end

uevr.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)

    pawn = api:get_local_pawn(0)

    if pawn and pawn.GetWeapon ~= nil then
        controller = pawn:GetController()
        controller.MyHUD.HitDirectionWidget:SetRenderOpacity(0.000)
        isPaused = statics:IsGamePaused(pawn) or controller.bShowMouseCursor or controller.MyHUD.CinematicMenuWindow:IsVisible()

        if pawn.Mesh1P and pawn.Mesh1P.AnimScriptInstance then
            isAiming = pawn.Mesh1P.AnimScriptInstance.ADS > 0.000
        else
            isAiming = false
        end

        weapon = pawn:GetWeapon()

        if not weapon then
            return
        end

        local currentMontage = pawn.Mesh1P.AnimScriptInstance:GetCurrentActiveMontage()
        if currentMontage then
            local montageName = pawn.Mesh1P.AnimScriptInstance:GetCurrentActiveMontage():get_fname():to_string()
            if montageName:find("Spell") or montageName:find("Melee") or montageName:find("Heat") then
                allowShowHands = true
            else
                allowShowHands = false
            end
            --print(montageName)
        else
            allowShowHands = false
        end

        if not isPaused then
            if allowShowHands and not handsAreShown then
                pawn.Mesh1P:SetHiddenInGame(false)
                vr.set_mod_value("VR_AimMethod", "1")
                handsAreShown = true
                print("shown")
            elseif pawn.Mesh1P:IsVisible() and not weapon.RootComponent.bHiddenInGame and not allowShowHands then
                pawn.Mesh1P:SetHiddenInGame(true)
                vr.set_mod_value("VR_AimMethod", "2")
                handsAreShown = false
                print("hidden")
            end
        end

        pawn.Mesh1P.bRenderWithCustomFOV = false
        weapon.Mesh1P.bRenderWithCustomFOV = false
        weapon.WeaponSightComponent.bSightEnabled = false
        weapon.WeaponSightComponent.bShowWidgetOnFireReady = true

        if weapon.MuzzlePSC then
            weapon.MuzzlePSC.bRenderWithCustomFOV = false
        end

        if weapon.MuzzlePSCSecondary then
            weapon.MuzzlePSCSecondary.bRenderWithCustomFOV = false
        end

        --UEVR_UObjectHook.remove_motion_controller_state(weapon.Mesh1P)
        weapon_name = weapon:get_fname():to_string()
        weapon_state = UEVR_UObjectHook.get_or_add_motion_controller_state(weapon.Mesh1P)
        weapon_state:set_hand(1) -- Right hand
        weapon_state:set_permanent(true)
        --print(weapon_name)

        if weapon_state and weapon_name:find("MachinePistol") then
            weapon_state:set_rotation_offset(temp_vec3f:set(0.000, 1.570, 0.040))
            weapon_state:set_location_offset(temp_vec3f:set(-0.50, -0.50, -1.00))
            pitchOffset = "-25.00"
        elseif weapon_state and weapon_name:find("HandCannon") then
            weapon.Mesh1P.RelativeScale3D.x = 0.900
            weapon.Mesh1P.RelativeScale3D.y = 0.900
            weapon.Mesh1P.RelativeScale3D.z = 0.900

            if weapon_name:find("Light") or weapon_name:find("Medium") then
                weapon_state:set_rotation_offset(temp_vec3f:set(0.000, 1.570, 0.040))
                weapon_state:set_location_offset(temp_vec3f:set(1.000, -2.00, 0.000))
                weapon.Bullet1.bRenderWithCustomFOV = false
                weapon.Bullet2.bRenderWithCustomFOV = false
                weapon.Bullet3.bRenderWithCustomFOV = false
                weapon.Bullet4.bRenderWithCustomFOV = false
                weapon.Bullet5.bRenderWithCustomFOV = false
                weapon.Bullet6.bRenderWithCustomFOV = false
            elseif weapon_name:find("Heavy") then
                weapon_state:set_rotation_offset(temp_vec3f:set(-0.045, 1.570, 0.040))
                weapon_state:set_location_offset(temp_vec3f:set(1.000, -2.000, -1.00))
            end
            pitchOffset = "-20.00"
        elseif weapon_state and weapon_name:find("AutoRifle") then
            if weapon_name:find("Light") then
                weapon_state:set_rotation_offset(temp_vec3f:set(-0.025, 1.575, 0.040))
                weapon_state:set_location_offset(temp_vec3f:set(0.000, -4.000, 0.000))

                weapon.Mesh1P.RelativeScale3D.x = 0.900
                weapon.Mesh1P.RelativeScale3D.y = 0.900
                weapon.Mesh1P.RelativeScale3D.z = 0.900
                pitchOffset = "-20.00"
            elseif weapon_name:find("Medium") then
                weapon_state:set_rotation_offset(temp_vec3f:set(0.000, 1.570, 0.040))
                weapon_state:set_location_offset(temp_vec3f:set(0.000, -3.30, 0.000))

                weapon.Mesh1P.RelativeScale3D.x = 0.900
                weapon.Mesh1P.RelativeScale3D.y = 0.900
                weapon.Mesh1P.RelativeScale3D.z = 0.900
                pitchOffset = "-25.00"
            elseif weapon_name:find("Heavy") then
                weapon_state:set_rotation_offset(temp_vec3f:set(0.000, 1.570, 0.040))
                weapon_state:set_location_offset(temp_vec3f:set(1.000, -3.50, 0.000))

                weapon.Mesh1P.RelativeScale3D.x = 1.000
                weapon.Mesh1P.RelativeScale3D.y = 1.000
                weapon.Mesh1P.RelativeScale3D.z = 1.000
                pitchOffset = "-20.00"
            elseif weapon_name:find("Bone") then
                weapon_state:set_rotation_offset(temp_vec3f:set(0.000, 1.573, 0.040))
                weapon_state:set_location_offset(temp_vec3f:set(-2.50, -4.00, 0.000))

                weapon.Mesh1P.RelativeScale3D.x = 0.600
                weapon.Mesh1P.RelativeScale3D.y = 0.600
                weapon.Mesh1P.RelativeScale3D.z = 0.600
                pitchOffset = "-18.00"
            end
        elseif weapon_state and weapon_name:find("Crossbow") then
            weapon_state:set_rotation_offset(temp_vec3f:set(-0.045, 1.575, 0.040))
            weapon_state:set_location_offset(temp_vec3f:set(5.000, -5.000, -1.00))
            pitchOffset = "-10.00"
        elseif weapon_state and weapon_name:find("StakeGun") then
            weapon_state:set_rotation_offset(temp_vec3f:set(-0.040, 1.570, 0.040))
            weapon.Mesh1P.bRenderWithCustomFOV = true

            if weapon_name:find("Light") then
                weapon.Mesh1P.bRenderWithCustomFOV = false
                weapon_state:set_location_offset(temp_vec3f:set(-3.00, -6.00, 0.000))

                weapon.Mesh1P.RelativeScale3D.x = 0.900
                weapon.Mesh1P.RelativeScale3D.y = 0.900
                weapon.Mesh1P.RelativeScale3D.z = 0.900

                weapon.Stake1.bRenderWithCustomFOV = false
                weapon.Stake2.bRenderWithCustomFOV = false
                weapon.Stake3.bRenderWithCustomFOV = false
                weapon.Stake4.bRenderWithCustomFOV = false
                weapon.Stake5.bRenderWithCustomFOV = false
                weapon.Stake6.bRenderWithCustomFOV = false
                weapon.Stake7.bRenderWithCustomFOV = false
                weapon.Stake8.bRenderWithCustomFOV = false
            elseif weapon_name:find("Medium") then
                local scaleRatio = controller.HipfireFOV / weapon.WeaponFOV
                local shiftRatio = (controller.HipfireFOV - weapon.WeaponFOV) / 15.000
                if isAiming then
                    weapon_state:set_location_offset(temp_vec3f:set(0.000, 3.500 * shiftRatio, -1.000 * shiftRatio))
                    weapon.Mesh1P.RelativeScale3D.x = 0.830 * scaleRatio + (0.080 * shiftRatio)
                    weapon.Mesh1P.RelativeScale3D.y = 1.000
                    weapon.Mesh1P.RelativeScale3D.z = 0.800 * scaleRatio + (0.080 * shiftRatio)
                else
                    weapon_state:set_location_offset(temp_vec3f:set(0.000, 0.000, 0.000))
                    weapon.Mesh1P.RelativeScale3D.x = 0.830
                    weapon.Mesh1P.RelativeScale3D.y = 1.000
                    weapon.Mesh1P.RelativeScale3D.z = 0.800
                end
            end
            pitchOffset = "-20.00"
        elseif weapon_state and weapon_name:find("BoltActionRifle") then
            if weapon_name:find("Light") then
                weapon_state:set_rotation_offset(temp_vec3f:set(-0.015, 1.575, 0.040))
                weapon_state:set_location_offset(temp_vec3f:set(-1.000, -4.00, 0.000))
            elseif weapon_name:find("Medium") then
                weapon_state:set_rotation_offset(temp_vec3f:set(-0.025, 1.573, 0.040))
                weapon_state:set_location_offset(temp_vec3f:set(-1.000, -5.00, 0.000))
            elseif weapon_name:find("Heavy") then
                weapon_state:set_rotation_offset(temp_vec3f:set(-0.025, 1.573, 0.040))
                weapon_state:set_location_offset(temp_vec3f:set(-1.000, -3.00, 0.000))
            end
            pitchOffset = "-18.00"
        elseif weapon_state and weapon_name:find("LeverActionRifle") then
            if weapon_name:find("Light") then
                weapon_state:set_rotation_offset(temp_vec3f:set(-0.020, 1.575, 0.040))
                weapon_state:set_location_offset(temp_vec3f:set(-1.000, -3.00, 0.000))
            end
            pitchOffset = "-15.00"
        elseif weapon_state and weapon_name:find("SniperRifle") then
            if not scope_components_exist(pawn) then
                spawn_scope_mesh(pawn)
            end
            if pawn:IsTargeting() then
                scope_sphere_mesh:SetVisibility(true)
                scope_cylinder_mesh:SetVisibility(true)
            else
                scope_sphere_mesh:SetVisibility(false)
                scope_cylinder_mesh:SetVisibility(false)
            end
            if weapon_name:find("Light") then
                weapon_state:set_rotation_offset(temp_vec3f:set(-0.035, 1.570, 0.040))
                weapon_state:set_location_offset(temp_vec3f:set(0.000, -4.000, 0.000))
                scope_sphere_state:set_location_offset(temp_vec3f:set(-0.050, -16.30, 38.000))
                scope_cylinder_state:set_location_offset(temp_vec3f:set(-0.05, -15.0, -15.45))
            elseif weapon_name:find("Medium") then
                weapon_state:set_rotation_offset(temp_vec3f:set(-0.035, 1.570, 0.040))
                weapon_state:set_location_offset(temp_vec3f:set(0.000, -3.000, 0.000))
                scope_sphere_state:set_location_offset(temp_vec3f:set(0.000, -17.100, 46.000))
                scope_cylinder_state:set_location_offset(temp_vec3f:set(0.00, -15.00, -15.90))
            elseif weapon_name:find("Heavy") then
                weapon_state:set_rotation_offset(temp_vec3f:set(-0.035, 1.570, 0.040))
                weapon_state:set_location_offset(temp_vec3f:set(5.000, -5.000, 0.000))
                scope_sphere_state:set_location_offset(temp_vec3f:set(-0.050, -18.10, 36.000))
                scope_cylinder_state:set_location_offset(temp_vec3f:set(-0.05, -15.0, -17.30))
            end
            pitchOffset = "-20.00"
        elseif weapon_state and weapon_name:find("Shotgun") then
            weapon_state:set_rotation_offset(temp_vec3f:set(-0.030, 1.570, 0.040))

            weapon.Mesh1P.RelativeScale3D.x = 0.800
            weapon.Mesh1P.RelativeScale3D.y = 0.800
            weapon.Mesh1P.RelativeScale3D.z = 0.800

            if weapon_name:find("Light") or weapon_name:find("Heavy") then
                weapon_state:set_location_offset(temp_vec3f:set(-3.000, 3.000, 0.000))
            elseif weapon_name:find("Medium") then
                weapon_state:set_location_offset(temp_vec3f:set(0.000, -1.000, 0.000))
            end
            pitchOffset = "-20.00"
        elseif weapon_state and weapon_name:find("GrenadeLauncher") then
            --weapon.Mesh1P.bRenderWithCustomFOV = true
            weapon_state:set_rotation_offset(temp_vec3f:set(0.000, 1.570, 0.040))
            weapon_state:set_location_offset(temp_vec3f:set(0.000, -3.000, 0.00))

            weapon.Mesh1P.RelativeScale3D.x = 0.800
            weapon.Mesh1P.RelativeScale3D.y = 0.800
            weapon.Mesh1P.RelativeScale3D.z = 0.800

            --weapon.Mesh1P.RelativeScale3D.x = 0.640
            --weapon.Mesh1P.RelativeScale3D.y = 0.800
            --weapon.Mesh1P.RelativeScale3D.z = 0.640
            pitchOffset = "-10.00"
        elseif weapon_state and weapon_name:find("StunGun") then
            weapon_state:set_rotation_offset(temp_vec3f:set(0.000, 1.570, 0.040))
            weapon_state:set_location_offset(temp_vec3f:set(-3.00, -3.00, 0.000))
            pitchOffset = "-15.00"
        end

        if pitchOffset ~= lastPitchOffset then
            vr.set_mod_value("VR_ControllerPitchOffset", pitchOffset)
            lastPitchOffset = pitchOffset
            print("pitch offset", pitchOffset)
        end
 
        if isPaused and not isInPauseMode then
            vr.recenter_view()
            vr.set_mod_value("VR_AimMethod", "0")
            vr.set_mod_value("UI_FollowView", "false")
            vr.set_mod_value("VR_DecoupledPitch", "true")
            vr.set_mod_value("VR_RoomscaleMovement", "false")
            vr.set_mod_value("VR_DecoupledPitchUIAdjust", "false")
            if controller.MyHUD.CinematicMenuWindow:IsVisible() then
                vr.set_mod_value("VR_CameraForwardOffset", "100.00")
            end
            local camera_manager = controller.PlayerCameraManager
            local view_target = camera_manager.ViewTarget.Target:get_fname():to_string()
            if view_target:find("GearUpgradeStation") then
                vr.set_mod_value("VR_CameraUpOffset", "-538.00")
                vr.set_mod_value("VR_CameraRightOffset", "-100.00")
            end

            isMoveInputIgnored = true
            isInPauseMode = true
            print("pause mode")
        elseif controller and not isPaused and isMoveInputIgnored then
            vr.recenter_view()
            vr.set_mod_value("VR_AimMethod", "2")
            vr.set_mod_value("UI_FollowView", "true")
            vr.set_mod_value("VR_CameraUpOffset", "0.00")
            vr.set_mod_value("VR_DecoupledPitch", "false")
            vr.set_mod_value("VR_RoomscaleMovement", "true")
            vr.set_mod_value("VR_CameraRightOffset", "0.00")
            vr.set_mod_value("VR_CameraForwardOffset", "0.00")
            vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")

            isMoveInputIgnored = false
            isInPauseMode = false 
            print("play mode")
        end

        local leftShoulderPosition = pawn.Mesh1P:GetSocketLocation("b_LeftShoulder")
        leftDistance = (leftShoulderPosition - pawn.RearSight_L:K2_GetComponentLocation()):length()
        rightDistance = (leftShoulderPosition - pawn.RearSight_R:K2_GetComponentLocation()):length()

        if leftDistance <= 25.000 then
            vr.trigger_haptic_vibration(0, 0.001, 0.200, 0.200, vr.get_left_joystick_source())
            allowHealing = true
        else
            allowHealing = false
        end

        if rightDistance <= 25.000 then
            vr.trigger_haptic_vibration(0, 0.001, 0.200, 0.200, vr.get_right_joystick_source())
            allowWeaponSwitch = true
        else
            allowWeaponSwitch = false
        end
    end
end)

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    if engine.GameViewport then
        local world = engine.GameViewport.World
        if world then
            local level = world.PersistentLevel
            if last_level ~= level then
                on_level_changed()
            end
            last_level = level
        end
    end
end)

uevr.sdk.callbacks.on_script_reset(function()
    if pawn and scope_sphere_mesh then
        pawn:K2_DestroyComponent(scope_sphere_mesh)
        pawn:K2_DestroyComponent(scope_cylinder_mesh)
    end
end)

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)

    local max_int16 = 0x7FFF

    if state.Gamepad.sThumbRX <= -max_int16 * 0.250 or state.Gamepad.sThumbRY <= -max_int16 * 0.250 then
        if allowWeaponSwitch and not isAiming then
            state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_B
            state.Gamepad.sThumbRX = 0.000
        elseif state.Gamepad.sThumbRY <= -max_int16 * 0.850 then
            state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_LEFT_THUMB
        end
    elseif state.Gamepad.sThumbRX >= max_int16 * 0.250 or state.Gamepad.sThumbRY >= max_int16 * 0.250 then
        if allowWeaponSwitch and not isAiming then
            state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_B
            state.Gamepad.sThumbRX = 0.000
        elseif state.Gamepad.sThumbRY >= max_int16 * 0.850 then
            state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_RIGHT_THUMB
        end
    end

    if pawn.CachedHealth and pawn.CachedMaxHealth then
        if allowHealing and pawn.CachedHealth < pawn.CachedMaxHealth and state.Gamepad.bLeftTrigger ~= 0 then
            pawn:BP_UseHealingAbility()
            state.Gamepad.bLeftTrigger = 0
        end
    end

    if not isPaused then
        state.Gamepad.sThumbRY = 0.000
    end
end)
