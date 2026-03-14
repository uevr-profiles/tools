UEVR_UObjectHook.activate()

local api = uevr.api
local skeletal_mesh_component_c = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")

local last_pawn_addr = 0
local applied_player_mesh_addr = 0
local applied_weapon_mesh_addr = 0

local function disable_shadow(mesh)
    pcall(function() mesh:SetCastShadow(false) end)
    pcall(function() mesh:SetCastHiddenShadow(false) end)
    pcall(function() mesh:set_property("CastShadow", false) end)
    pcall(function() mesh:set_property("bCastHiddenShadow", false) end)
end

local function apply_fix()
    if not skeletal_mesh_component_c then
        return
    end

    local pawn = api:get_local_pawn(0)
    if not pawn then
        return
    end

    local pawn_addr = pawn:get_address()

    if pawn_addr ~= last_pawn_addr then
        last_pawn_addr = pawn_addr
        applied_player_mesh_addr = 0
        applied_weapon_mesh_addr = 0
    end

    local meshes = skeletal_mesh_component_c:get_objects_matching(false)

    for _, mesh in ipairs(meshes) do
        local full_name = mesh:get_full_name()
        local outer = mesh:get_outer()

        if outer and outer:get_address() == pawn_addr then
            if full_name:find("%.CharacterMesh0$") and mesh:get_address() ~= applied_player_mesh_addr then
                disable_shadow(mesh)
                applied_player_mesh_addr = mesh:get_address()
            end
        end

        if full_name:find("PersistentLevel%.BP_Melee_C_") and full_name:find("%.WeaponMesh$") then
            if mesh:get_address() ~= applied_weapon_mesh_addr then
                disable_shadow(mesh)
                applied_weapon_mesh_addr = mesh:get_address()
            end
        end
    end
end

uevr.sdk.callbacks.on_pre_engine_tick(function()
    apply_fix()
end)