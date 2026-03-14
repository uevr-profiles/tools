print("Initializing Dynamic Weapon Offsets")

UEVR_UObjectHook.activate()
local api = uevr.api

-- DEBUG FLAGS
local DEBUG_ARMS = true
local DEBUG_WEAPONS = true
local DEBUG_OFFSETS = false

-- Load offsets table
local weapon_offsets = require(".\\Config\\WeaponOffsetsTable")

-- Kismet Math Library
local kismet_math_library = api:find_uobject("Class /Script/Engine.KismetMathLibrary"):get_class_default_object()

local last_pawn = nil
local last_arms = nil
local last_weapon = nil

-- Pistol delay logic
local pistol_timer_start = nil
local pistol_pending_weapon = nil
local PISTOL_DELAY = 1.2  -- seconds
local pistols_applied = {} -- set to track pistols that already got the offset

-- =========================
-- HELPERS
-- =========================

local function get_local_pawn()
    local pc = api:get_player_controller(0)
    if not pc then return nil end
    return pc.Pawn
end

local function get_weapon_name(uobject)
    if not uobject then return nil end
    local full_name = uobject:get_full_name()
    if not full_name then return nil end

    local space_pos = string.find(full_name, " ")
    if space_pos then
        return string.sub(full_name, 1, space_pos - 1)
    end
    return full_name
end

local function apply_offsets_to_arms(arms, weapon_name)
    if not arms or not weapon_name then return end

    local weapon_data = weapon_offsets[weapon_name]
    if not weapon_data then return end

    local global_data = weapon_offsets.GlobalOffset or {}

    local mc_state = UEVR_UObjectHook.get_or_add_motion_controller_state(arms)
    if not mc_state then return end

    local w_rot = weapon_data.rotation_offset or { x = 0, y = 0, z = 0 }
    local w_loc = weapon_data.location_offset or { x = 0, y = 0, z = 0 }

    local g_rot = global_data.rotation_offset or { x = 0, y = 0, z = 0 }
    local g_loc = global_data.location_offset or { x = 0, y = 0, z = 0 }

    -- Combine global + weapon offsets
    local final_rot = {
        x = w_rot.x + g_rot.x,
        y = w_rot.y + g_rot.y,
        z = w_rot.z + g_rot.z
    }

    local final_loc = {
        x = w_loc.x + g_loc.x,
        y = w_loc.y + g_loc.y,
        z = w_loc.z + g_loc.z
    }

    local rot_vec = kismet_math_library:MakeVector(final_rot.x, final_rot.y, final_rot.z)
    local loc_vec = kismet_math_library:MakeVector(final_loc.x, final_loc.y, final_loc.z)

    mc_state:set_hand(1)
    mc_state:set_rotation_offset(rot_vec)
    mc_state:set_location_offset(loc_vec)
    mc_state:set_permanent(true)

    if DEBUG_OFFSETS then
        print(string.format(
            "[UEVR] Offsets applied to %s | Rot(%.3f, %.3f, %.3f) Loc(%.3f, %.3f, %.3f)",
            weapon_name,
            final_rot.x, final_rot.y, final_rot.z,
            final_loc.x, final_loc.y, final_loc.z
        ))
    end
end

-- =========================
-- MAIN LOOP
-- =========================

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    local pawn = get_local_pawn()
    if not pawn then return end

    -- Pawn changed
    if pawn ~= last_pawn then
        if DEBUG_ARMS then
            if pawn then
                print("[UEVR] Pawn changed -> " .. pawn:get_full_name())
            else
                print("[UEVR] Pawn lost (nil)")
            end
        end

        last_pawn = pawn
        last_arms = nil
        last_weapon = nil
        return
    end

    -- FirstPersonArms detection
    local arms = pawn.FirstPersonArms
    if arms ~= last_arms then
        if DEBUG_ARMS then
            if arms then
                print("[UEVR] FirstPersonArms found -> " .. arms:get_full_name())
            else
                print("[UEVR] FirstPersonArms lost")
            end
        end

        last_arms = arms

        -- Re-apply offsets when arms change
        if arms and last_weapon then
            apply_offsets_to_arms(arms, last_weapon)
        end
    end

    -- Weapon detection
    local equipped_item = pawn.EquippedItem
    local weapon_name = get_weapon_name(equipped_item)
    local weapon_data = weapon_offsets[weapon_name]

    if weapon_name ~= last_weapon then
        last_weapon = weapon_name

        if DEBUG_WEAPONS then
            if weapon_name then
                print("[Weapon Detection] Equipped -> " .. weapon_name)
            else
                print("[Weapon Detection] No weapon equipped")
            end
        end

        -- Apply offsets immediately
        if last_arms and weapon_name then
            apply_offsets_to_arms(last_arms, weapon_name)
        end

        -- --- PISTOL DELAY LOGIC ---
        if weapon_data and weapon_data.is_pistol and not pistols_applied[weapon_name] then
            pistol_timer_start = os.clock()
            pistol_pending_weapon = weapon_name
        else
            pistol_timer_start = nil
            pistol_pending_weapon = nil
        end
    end

    -- --- APPLY PISTOL FIRSTPERSONOFFSET AFTER DELAY ---
    if pistol_timer_start and pistol_pending_weapon then
        local elapsed = os.clock() - pistol_timer_start
        if elapsed >= PISTOL_DELAY then
            if last_weapon == pistol_pending_weapon and last_arms and not pistols_applied[pistol_pending_weapon] then
                local anim_instance = last_arms.AnimScriptInstance
                if anim_instance and anim_instance.RangedWeaponData and anim_instance.RangedWeaponData.PositionOffset then
                    anim_instance.RangedWeaponData.PositionOffset.FirstPersonOffset.X = 0
                    anim_instance.RangedWeaponData.PositionOffset.FirstPersonOffset.Y = -2.5
                    anim_instance.RangedWeaponData.PositionOffset.FirstPersonOffset.Z = 12
                    pistols_applied[pistol_pending_weapon] = true
                    print("[Pistol Offset] Applied to " .. pistol_pending_weapon)
                end

                pistol_timer_start = nil
                pistol_pending_weapon = nil
            elseif last_weapon ~= pistol_pending_weapon then
                -- Weapon switched before timer finished
                pistol_timer_start = nil
                pistol_pending_weapon = nil
            end
        end
    end
end)

uevr.sdk.callbacks.on_script_reset(function()
    print("Dynamic Weapon Offsets Script Reset")
    pistols_applied = {}
end)
