UEVR_UObjectHook.activate()

local api = uevr.api
local callbacks = uevr.sdk.callbacks

local hidden = {}
local skeletal_class = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")

local function safe_name(obj)
    if not obj then return "" end
    local ok, name = pcall(function() return obj:get_full_name() end)
    if ok and name then return tostring(name) end
    return ""
end

local function hide_runtime_nodes()
    if not skeletal_class then return end
    local objs = skeletal_class:get_objects_matching(false)
    if not objs then return end

    for _, obj in ipairs(objs) do
        local name = safe_name(obj)
        if string.find(name, "NODE_AddSkeletalMeshComponent", 1, true) then
            if not hidden[name] then
                pcall(function() obj:SetVisibility(false, true) end)
                pcall(function() obj:SetHiddenInGame(true, true) end)
                hidden[name] = true
            end
        end
    end
end

callbacks.on_pre_engine_tick(function()
    hide_runtime_nodes()
end)