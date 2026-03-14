---@diagnostic disable: undefined-global, undefined-field
UEVR_UObjectHook.activate()

local api       = uevr.api
local callbacks = uevr.sdk.callbacks

local last_weapon = nil
local last_pawn   = nil

local skel_class = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent"):as_class()

local function get_pawn()
    local ok, pawn = pcall(function() return api:get_local_pawn() end)
    return ok and pawn or nil
end

local function safe_full(obj)
    if not obj then return nil end
    local ok, name = pcall(function() return obj:get_full_name() end)
    return ok and name or nil
end

-----------------------------------------------------------------------
-- NEW FUNCTION: CLEAR ALL Weapon Meshes ON RESPAWN
-----------------------------------------------------------------------
local function cleanup_after_respawn()
    print("[GHOST_FIX] Respawn detected → clearing stale MC weapon meshes")

    local comps = skel_class:get_objects_matching(false) or {}

    for _, comp in ipairs(comps) do
        local full = safe_full(comp)
        if full then
            -- Matches all named weapon-like meshes
            if full:match("Weapon_") or full:match("Grabbable") then
                print("   [GHOST_FIX] Clearing:", full)
                pcall(function()
                    UEVR_UObjectHook.remove_motion_controller_state(comp)
                    comp:SetHiddenInGame(false)
                    comp:SetVisibility(true, true)
                    comp:SetWorldScale3D({X=1,Y=1,Z=1})
                end)
            end
        end
    end

    print("[GHOST_FIX] Respawn cleanup complete.")
end

callbacks.on_post_engine_tick(function()
    local pawn = get_pawn()
    if not pawn then return end

    -------------------------------------------------------------------
    -- Detect RESPAWN: pawn pointer changed
    -------------------------------------------------------------------
    if pawn ~= last_pawn then
        if last_pawn ~= nil then
            cleanup_after_respawn()
        else
            print("[GHOST_FIX] Initial pawn detected.")
        end
        last_pawn = pawn
    end

    -------------------------------------------------------------------
    -- NORMAL DROP HANDLING (your now-perfect behavior)
    -------------------------------------------------------------------
    local cur = pawn:get_property("Weapon")
    local old = pawn:get_property("OldWeapon")

    if cur == nil and last_weapon ~= nil and old ~= nil then
        print("[GHOST_FIX] Drop detected → remove MC state on weapon mesh")

        local old_full = safe_full(old)
        if old_full then
            local fragment = old_full:match("PersistentLevel%.([%w_]+)")
            if fragment then
                local comps = skel_class:get_objects_matching(false) or {}
                for _, comp in ipairs(comps) do
                    local comp_full = safe_full(comp)
                    if comp_full and comp_full:find(fragment, 1, true) then
                        print("   [GHOST_FIX] Remove MC override:", comp_full)
                        pcall(function()
                            UEVR_UObjectHook.remove_motion_controller_state(comp)
                            comp:SetHiddenInGame(false)
                            comp:SetVisibility(true, true)
                            comp:SetWorldScale3D({X=1,Y=1,Z=1})
                        end)
                    end
                end
            end
        end
    end

    -------------------------------------------------------------------
    -- NORMAL PICKUP HANDLING (restore visibility)
    -------------------------------------------------------------------
    if cur ~= nil and cur ~= last_weapon then
        local cur_full = safe_full(cur)
        local fragment = cur_full and cur_full:match("PersistentLevel%.([%w_]+)")
        if fragment then
            local comps = skel_class:get_objects_matching(false) or {}
            for _, comp in ipairs(comps) do
                local comp_full = safe_full(comp)
                if comp_full and comp_full:find(fragment, 1, true) then
                    print("   [GHOST_FIX] Restore mesh:", comp_full)
                    pcall(function()
                        comp:SetHiddenInGame(false)
                        comp:SetVisibility(true, true)
                        comp:SetWorldScale3D({X=1,Y=1,Z=1})
                    end)
                end
            end
        end
    end

    last_weapon = cur
end)
