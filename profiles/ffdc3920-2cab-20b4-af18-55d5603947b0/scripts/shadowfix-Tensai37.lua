UEVR_UObjectHook.activate()

local api = uevr.api
local callbacks = uevr.sdk.callbacks

local pawn = nil
local prim_class = nil
local smc_class = nil

local seen = setmetatable({}, { __mode = "k" })

local sweep_active = false
local sweep_t = 0.0
local sweep_elapsed = 0.0
local SWEEP_INTERVAL = 0.25
local SWEEP_MAX = 6.0
local stable = 0
local STABLE_LIMIT = 8

local maint_t = 0.0
local MAINT_INTERVAL = 2.0

local function disable_shadows(c)
    if c == nil then return end
    pcall(function() c:SetCastShadow(false) end)
    pcall(function() c:SetCastInsetShadow(false) end)
    pcall(function() c:SetCastContactShadow(false) end)
    pcall(function() c.CastShadow = false end)
    pcall(function() c.bCastDynamicShadow = false end)
    pcall(function() c.bCastHiddenShadow = false end)
end

local function disable_player_shadows_global_scan(p)
    if prim_class == nil then
        prim_class = api:find_uobject("Class /Script/Engine.PrimitiveComponent")
    end
    if not prim_class then return end

    local arr = UEVR_UObjectHook.get_objects_by_class(prim_class, false)
    if not arr then return end

    for i = 1, #arr do
        local c = arr[i]
        if c ~= nil then
            local o = nil
            pcall(function() o = c:GetOwner() end)
            if o == p then
                disable_shadows(c)
            end
        end
    end
end

local function get_owner_smc_list(p)
    if smc_class == nil then
        smc_class = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")
    end
    if smc_class == nil or p == nil then return nil end

    local comps = nil
    local ok = pcall(function()
        comps = p:GetComponentsByClass(smc_class)
    end)
    if ok and comps ~= nil then
        return comps
    end

    local arr = UEVR_UObjectHook.get_objects_by_class(smc_class, false)
    if not arr then return nil end

    local out = {}
    local n = 0
    for i = 1, #arr do
        local c = arr[i]
        if c ~= nil then
            local o = nil
            pcall(function() o = c:GetOwner() end)
            if o == p then
                n = n + 1
                out[n] = c
            end
        end
    end
    return out
end

local function disable_pawn_smc_shadows(p)
    local list = get_owner_smc_list(p)
    if list == nil then return 0 end

    local new_count = 0
    for i = 1, #list do
        local c = list[i]
        if c ~= nil then
            disable_shadows(c)
            if not seen[c] then
                seen[c] = true
                new_count = new_count + 1
            end
        end
    end
    return new_count
end

callbacks.on_pre_engine_tick(function(engine, delta)
    local dt = delta or 0.0

    if pawn == nil then
        pawn = api:get_local_pawn(0)
        if pawn ~= nil then
            disable_player_shadows_global_scan(pawn)
            sweep_active = true
            sweep_t = 0.0
            sweep_elapsed = 0.0
            stable = 0
        end
    end

    if pawn == nil then return end

    if sweep_active then
        sweep_t = sweep_t + dt
        sweep_elapsed = sweep_elapsed + dt

        if sweep_t >= SWEEP_INTERVAL then
            sweep_t = 0.0
            local newc = disable_pawn_smc_shadows(pawn)
            if newc == 0 then
                stable = stable + 1
            else
                stable = 0
            end
        end

        if sweep_elapsed >= SWEEP_MAX or stable >= STABLE_LIMIT then
            sweep_active = false
            maint_t = 0.0
        end
    else
        maint_t = maint_t + dt
        if maint_t >= MAINT_INTERVAL then
            maint_t = 0.0
            disable_pawn_smc_shadows(pawn)
        end
    end
end)