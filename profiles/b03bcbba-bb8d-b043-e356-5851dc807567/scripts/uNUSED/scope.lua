--Custom Stuff
--
--weapon mesh path, ll.457
--the scope mesh path or a location as to where you wanna spawn it
--scope size ll. 394
--scope activate condition, ll. 399+
--Camera Manager ll. 116
--ScopeMesh or location as to where to attach scope, ll 378
--
local api = uevr.api
local vr = uevr.params.vr

local emissive_material_amplifier = 2.0 
local fov = 2.0

-- Static variables
local emissive_mesh_material_name = "Material /Engine/EngineMaterials/EmissiveMeshMaterial.EmissiveMeshMaterial"
local reticle_mesh_material_name = "Material /Game/TEH/Gear/_Shared/Sights/PP_Sight.PP_Sight"
local ftransform_c = nil
local flinearColor_c = nil
local hitresult_c = nil
local game_engine_class = nil
local Statics = nil
local Kismet = nil
local KismetMaterialLibrary = nil
local AssetRegistryHelpers = nil
local actor_c = nil
local staic_mesh_component_c = nil
local staic_mesh_c = nil
local scene_capture_component_c = nil
local MeshC = nil
local StaticMeshC = nil
local CameraManager_c = nil


-- Instance variables
local scope_actor = nil
local scope_plane_component = nil
local reticle_plane_component= nil
local scene_capture_component = nil
local render_target = nil
local reusable_hit_result = nil
local temp_vec3 = Vector3d.new(0, 0, 0)
local temp_vec3f = Vector3f.new(0, 0, 0)
local zero_color = nil
local zero_transform = nil

local function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        error("Cannot find " .. name)
        return nil
    end
    return obj
end

local function find_required_object_no_cache(class, full_name)
    local matches = class:get_objects_matching(false)
    for i, obj in ipairs(matches) do
        if obj ~= nil and obj:get_full_name() == full_name then
            return obj
        end
    end
    return nil
end

local find_static_class = function(name)
    local c = find_required_object(name)
    return c:get_class_default_object()
end

local function init_static_objects()
    -- Try to initialize all required objects
    ftransform_c = find_required_object("ScriptStruct /Script/CoreUObject.Transform")
    if not ftransform_c then return false end
    
    flinearColor_c = find_required_object("ScriptStruct /Script/CoreUObject.LinearColor")
    if not flinearColor_c then return false end
    
    hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
    if not hitresult_c then return false end
    
    game_engine_class = find_required_object("Class /Script/Engine.GameEngine")
    if not game_engine_class then return false end
    
    Statics = find_static_class("Class /Script/Engine.GameplayStatics")
    if not Statics then return false end
    
    Kismet = find_static_class("Class /Script/Engine.KismetRenderingLibrary")
    if not Kismet then return false end
    
    KismetMaterialLibrary = find_static_class("Class /Script/Engine.KismetMaterialLibrary")
    if not KismetMaterialLibrary then return false end
    
	
  --  AssetRegistryHelpers = find_static_class("Class /Script/AssetRegistry.AssetRegistryHelpers")
  --  if not AssetRegistryHelpers then return false end
    
    actor_c = find_required_object("Class /Script/Engine.Actor")
    if not actor_c then return false end
    
    staic_mesh_component_c = find_required_object("Class /Script/Engine.StaticMeshComponent")
    if not staic_mesh_component_c then 
	print("false")
	return false end

    staic_mesh_c = find_required_object("Class /Script/Engine.StaticMesh")
    if not staic_mesh_c then return false end
    
    scene_capture_component_c = find_required_object("Class /Script/Engine.SceneCaptureComponent2D")
    if not scene_capture_component_c then return false end
    
    MeshC = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")
    if not MeshC then return false end
    
    StaticMeshC = api:find_uobject("Class /Script/Engine.StaticMeshComponent")
    if not StaticMeshC then return false end

    CameraManager_c = find_required_object("Class /Script/Engine.PlayerCameraManager")
    if not CameraManager_c then return false end

    -- Initialize reusable objects
    reusable_hit_result = StructObject.new(hitresult_c)
    if not reusable_hit_result then return false end
    
    zero_color = StructObject.new(flinearColor_c)
    if not zero_color then return false end
    
    zero_transform = StructObject.new(ftransform_c)
    if not zero_transform then return false end
    zero_transform.Rotation.W = 1.0
    zero_transform.Scale3D = temp_vec3:set(1.0, 1.0, 1.0)

    return true
end

local function reset_static_objects()
    ftransform_c = nil
    flinearColor_c = nil
    hitresult_c = nil
    game_engine_class = nil
    Statics = nil
    Kismet = nil
    KismetMaterialLibrary = nil
    AssetRegistryHelpers = nil
    actor_c = nil
    staic_mesh_component_c = nil
    staic_mesh_c = nil
    scene_capture_component_c = nil
    MeshC = nil
    StaticMeshC = nil
    CameraManager_c = nil

    
    reusable_hit_result = nil
    zero_color = nil
    zero_transform = nil
end

local function validate_object(object)
    if object == nil or not UEVR_UObjectHook.exists(object) then
        return nil
    else
        return object
    end
end

local function destroy_actor(actor)
    if actor ~= nil and not UEVR_UObjectHook.exists(actor) then
        pcall(function() 
            if actor.K2_DestroyActor ~= nil then
                actor:K2_DestroyActor()
            end
        end)
    end
    return nil
end


local function spawn_actor(world_context, actor_class, location, collision_method, owner)

    local actor = Statics:BeginDeferredActorSpawnFromClass(world_context, actor_class, zero_transform, collision_method, owner)

    if actor == nil then
        print("Failed to spawn actor")
        return nil
    end

    Statics:FinishSpawningActor(actor, zero_transform)
    print("Spawned actor")

    return actor
end

local function get_scope_mesh(parent_mesh)
    if not parent_mesh then return nil end

    local child_components = parent_mesh.AttachChildren
    if not child_components then return nil end

    for _, component in ipairs(child_components) do
        if component:is_a(StaticMeshC) and string.find(component:get_fname():to_string(), "scope") then
            return component
        end
    end

    return nil
end


local function get_equipped_weapon(pawn)
    if not pawn then return nil end
    local sk_mesh = pawn.Mesh
    if not sk_mesh then return nil end
    local anim_instance = sk_mesh.AnimScriptInstance
    if not anim_instance then return nil end
    local weapon_mesh = anim_instance.WeaponData.WeaponMesh
    return weapon_mesh
end

local function get_render_target(world)
    render_target = validate_object(render_target)
    if render_target == nil then
        render_target = Kismet:CreateRenderTarget2D(world, 1024, 1024, 6, zero_color, false)
    end
    return render_target
end

local function spawn_scope_plane(world, owner, pos, rt)
    local local_scope_mesh = api:add_component_by_class(scope_actor, staic_mesh_component_c,false)--:AddComponent(staic_mesh_component_c:get_fname(), false, zero_transform,nil, false)
	if local_scope_mesh == nil then
        print("Failed to spawn scope mesh")
        return
    end

    local wanted_mat = api:find_uobject(emissive_mesh_material_name)
    if wanted_mat == nil then
        print("Failed to find material")
        return
    end
    wanted_mat:set_property("BlendMode", 0)
	wanted_mat:set_property("TwoSided", false)
    --     wanted_mat.bDisableDepthTest = true
    --     --wanted_mat.MaterialDomain = 0
    --     --wanted_mat.ShadingModel = 0

    local plane = find_required_object_no_cache(staic_mesh_c, "StaticMesh /Engine/BasicShapes/Cylinder.Cylinder")
    -- local plane = find_required_object("StaticMesh /Engine/BasicShapes/Cylinder.Cylinder")
    -- local plane = find_required_object_no_cache("StaticMesh /Engine/BasicShapes/Cylinder.Cylinder")

    if plane == nil then
        print("Failed to find plane mesh")
        api:dispatch_custom_event("LoadAsset", "StaticMesh /Engine/BasicShapes/Cylinder.Cylinder")
        return
    end
    local_scope_mesh:SetStaticMesh(plane)
    local_scope_mesh:SetVisibility(flase)
    -- local_scope_mesh:SetHiddenInGame(false)
    local_scope_mesh:SetCollisionEnabled(0)

    local dynamic_material = local_scope_mesh:CreateDynamicMaterialInstance(0, wanted_mat, "ScopeMaterial")

    dynamic_material:SetTextureParameterValue("LinearColor", rt)
    local color = StructObject.new(flinearColor_c)
    color.R = emissive_material_amplifier
    color.G = emissive_material_amplifier
    color.B = emissive_material_amplifier
    color.A = emissive_material_amplifier
    dynamic_material:SetVectorParameterValue("Color", color)
    scope_plane_component = local_scope_mesh
end
local function spawn_reticle_plane(world, owner, pos, rt)
    local local_reticle_mesh = api:add_component_by_class(scope_actor, staic_mesh_component_c,false)--scope_actor:AddComponentByClass(staic_mesh_component_c, false, zero_transform, false)
	if local_reticle_mesh == nil then
        print("Failed to spawn local_reticle_mesh")
        return
    end

    local wanted_mat = api:find_uobject(reticle_mesh_material_name)
    if wanted_mat == nil then
        print("Failed to find material")
        return
    end
    --wanted_mat:set_property("BlendMode", 0)
	--wanted_mat:set_property("TwoSided", false)
    --     wanted_mat.bDisableDepthTest = true
    --     --wanted_mat.MaterialDomain = 0
    --     --wanted_mat.ShadingModel = 0

    local plane = find_required_object_no_cache(staic_mesh_c, "StaticMesh /Engine/BasicShapes/Cylinder.Cylinder")
    -- local plane = find_required_object("StaticMesh /Engine/BasicShapes/Cylinder.Cylinder")
    -- local plane = find_required_object_no_cache("StaticMesh /Engine/BasicShapes/Cylinder.Cylinder")

    if plane == nil then
        print("Failed to find plane mesh")
        api:dispatch_custom_event("LoadAsset", "StaticMesh /Engine/BasicShapes/Cylinder.Cylinder")
        return
    end
    local_reticle_mesh:SetStaticMesh(plane)
    local_reticle_mesh:SetVisibility(true)
    -- local_scope_mesh:SetHiddenInGame(false)
    local_reticle_mesh:SetCollisionEnabled(0)

    local dynamic_material = local_scope_mesh:CreateDynamicMaterialInstance(0, wanted_mat, "ReticleMaterial")

    dynamic_material:SetTextureParameterValue("LinearColor", rt)
    local color = StructObject.new(flinearColor_c)
    color.R = 1
    color.G = 1
    color.B = 1
    color.A = 1
    dynamic_material:SetVectorParameterValue("Color", color)
    reticle_plane_component = local_reticle_mesh
end

-- local function create_emissive_mat(component, materialSocketName)
--     -- local wanted_mat = api:find_uobject(emissive_mesh_material_name)
--     -- if wanted_mat == nil then
--     --     print("Failed to find material")
--     --     return
--     -- end
--     -- wanted_mat.BlendMode = 0
--     -- wanted_mat.TwoSided = 1
--     local index = component:GetMaterialIndex(materialSocketName)
--     -- local dynamic_material = component:CreateDynamicMaterialInstance(index, wanted_mat, "ScopeMaterial")
--     local materials = component:GetMaterials()
--     local materal = materials[index]
--     materal:SetTextureParameterValue("SightMask ", render_target)
--     material.ShadingModel = 0
--     material.BlendMode = 0
--     -- dynamic_material:SetTextureParameterValue("LinearColor", render_target)
-- end

local function spawn_scene_capture_component(world, owner, pos, fov, rt)
    scene_capture_component = api:add_component_by_class(scope_actor, scene_capture_component_c,false)--scope_actor:AddComponent(scene_capture_component_c:get_fname(), false, zero_transform,scene_capture_component_c, false)
    if scene_capture_component == nil then
        print("Failed to spawn scene capture")
        return
    end
    scene_capture_component.TextureTarget = rt
    scene_capture_component.FOVAngle = fov
    scene_capture_component:SetVisibility(flase)
end

local function spawn_scope(game_engine, pawn)
    local viewport = game_engine.GameViewport
    if viewport == nil then
        print("Viewport is nil")
        return
    end

    local world = viewport.World
    if world == nil then
        print("World is nil")
        return
    end

    if not pawn then
        print("pawn is nil")
        return
    end

    local rt = get_render_target(world)

    if rt == nil then
        print("Failed to get render target destroying actors")
        rt = nil
        scope_actor = destroy_actor(scope_actor)
        scope_plane_component = nil
        scene_capture_component = nil
		reticle_plane_component = nil
        return
    end

    local pawn_pos = pawn:K2_GetActorLocation()
    if not validate_object(scope_actor) then
        scope_actor = destroy_actor(scope_actor)
        scope_plane_component = nil
		reticle_plane_component = nil
        scene_capture_component = nil
        scope_actor = spawn_actor(world, actor_c, temp_vec3:set(0, 0, 0), 1, nil)
        if scope_actor == nil then
            print("Failed to spawn scope actor")
            return
        end
    end

    if not validate_object(scope_plane_component) then
        print("scope_plane_component is invalid -- recreating")
        spawn_scope_plane(world, nil, pawn_pos, rt)
		--spawn_reticle_plane(world, nil, pawn_pos, rt)
    end

    if not validate_object(scene_capture_component) then
        print("spawn_scene_capture_component is invalid -- recreating")
        spawn_scene_capture_component(world, nil, pawn_pos, fov, rt)
    end

end


local scope_mesh = nil
local last_scope_state = false

local function attach_components_to_weapon(weapon_mesh)
    if not weapon_mesh then return end
    
    -- Attach scene capture to weapon
    if scene_capture_component ~= nil then
        -- scene_capture:DetachFromParent(true, false)
        -- "AimSocket"
        print("Attaching scene_capture_component to weapon:" .. weapon_mesh:get_fname():to_string())
        scene_capture_component:K2_AttachToComponent(
            weapon_mesh,
            "Muzzle",
            2, -- Location rule
            2, -- Rotation rule
            0, -- Scale rule
            true -- Weld simulated bodies
        )
        scene_capture_component:K2_SetRelativeRotation(temp_vec3:set(0, 0, 90), false, reusable_hit_result, false)
        scene_capture_component:SetVisibility(false)
    end
    
    -- Attach plane to weapon
    if scope_plane_component then
        scope_mesh = weapon_mesh.AttachChildren[2]--get_scope_mesh(weapon_mesh)
        if scope_mesh == nil then
            print("Failed to find scope mesh")
            return
        end
        -- OpticCutoutSocket
        scope_plane_component:K2_AttachToComponent(
            scope_mesh,
            "AimSocket",
            2, -- Location rule
            2, -- Rotation rule
            2, -- Scale rule
            true -- Weld simulated bodies
        )
		scope_plane_component:K2_SetRelativeRotation(temp_vec3:set(0, 90, 90), false, reusable_hit_result, false)
        scope_plane_component:K2_SetRelativeLocation(temp_vec3:set(0.22, 0, 0), false, reusable_hit_result, false)
        scope_plane_component:SetWorldScale3D(temp_vec3:set(1.025,1.025,1.00001))
        scope_plane_component:SetVisibility(true)
    end
	if reticle_plane_component then
        scope_mesh = weapon_mesh.AttachChildren[1]--get_scope_mesh(weapon_mesh)
        if scope_mesh == nil then
            print("Failed to find scope mesh")
            return
        end
        -- OpticCutoutSocket
        reticle_plane_component:K2_AttachToComponent(
            scope_mesh,
            "AimSocket",
            2, -- Location rule
            2, -- Rotation rule
            2, -- Scale rule
            true -- Weld simulated bodies
        )
		reticle_plane_component:K2_SetRelativeRotation(temp_vec3:set(0, 90, 90), false, reusable_hit_result, false)
        reticle_plane_component:K2_SetRelativeLocation(temp_vec3:set(0.24, 0, 0), false, reusable_hit_result, false)
        reticle_plane_component:SetWorldScale3D(temp_vec3:set(0.025,0.025, 0.00001))
        reticle_plane_component:SetVisibility(false)
    end
end

local function is_scope_active(pawn)
    if not pawn then return false end
    local optical_scope = true--pawn.PlayerOpticScopeComponent
    if not optical_scope then return false end
    local scope_active = 1--optical_scope:read_byte(0xA8, 1)--
    if scope_active > 0 then
        return true
    end
    return false
end

local function switch_scope_state(pawn)
    local current_scope_state = is_scope_active(pawn)
    -- if current_scope_state == last_scope_state then
    --     return
    -- end
    last_scope_state = current_scope_state
    if scope_plane_component ~= nil then
        scope_plane_component:SetVisibility(current_scope_state)
    end
    if scene_capture_component ~= nil then
        scene_capture_component:SetVisibility(current_scope_state)
    end
end

-- Initialize static objects when the script loads
if not init_static_objects() then
    print("Failed to initialize static objects")
end

local current_weapon = nil
local last_level = nil


local function GetActiveWeaponMeshWithScope(pawn_c)
	if pawn_c==nil then return nil end
	
	if pawn_c.SidearmSkeletal.AttachSocketName:to_string() ~= "Sidearm_Attach" then
		if pawn_c.SidearmScope.LastRenderTime == pawn_c.SidearmScope.LastSubmitTime then
			return pawn_c.SidearmSkeletal
		end
	elseif	pawn_c.LongarmSkeletal.AttachSocketName:to_string() ~= "RangedAttach" then
		if pawn_c.LongarmScope.LastRenderTime == pawn_c.LongarmScope.LastSubmitTime  then
			return pawn_c.LongarmSkeletal
		end
	--elseif pawn_c.MeleeWeapon.AttachSocketName:to_string() =="Weapon1Socket" then
	--	return pawn_c.MeleeWeapon
	end
end
	


uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)
        local viewport = engine.GameViewport
        if viewport then
            local world = viewport.World
    
            if world then
                local level = world.PersistentLevel
    
                if last_level ~= level then
                    print("Level changed .. Reseting")
                    destroy_actor(scope_actor)
                    scope_plane_component = nil
                    scene_capture_component = nil
                    render_target = nil
                    scope_mesh = nil
                    reset_static_objects()
                    init_static_objects()
                end
                last_level = level
            end
        end

        -- reset_scope_actor_if_deleted()
        local c_pawn = api:get_local_pawn(0)
        local weapon_mesh = GetActiveWeaponMeshWithScope(c_pawn)--.Equipment.EquippedWeapon.SkeletalMeshComponent--get_equipped_weapon(c_pawn)
        if weapon_mesh then
            -- fix_materials(weapon_mesh)
            local weapon_changed = not current_weapon or weapon_mesh.AnimScriptInstance ~= current_weapon.AnimScriptInstance
            local scope_changed = (not scope_mesh or not scope_mesh.AttachParent) and is_scope_active(c_pawn)
            if weapon_changed or scope_changed then
                print("Weapon changed")
                print("Previous weapon: " .. (current_weapon and current_weapon:get_fname():to_string() or "none"))
                print("New weapon: " .. weapon_mesh:get_fname():to_string())
                
                -- Update current weapon reference
                current_weapon = weapon_mesh
                
                -- Attempt to attach components
                spawn_scope(engine, c_pawn)
                attach_components_to_weapon(weapon_mesh)
            end
        else
            -- Weapon was removed/unequipped
            if current_weapon then
                print("Weapon unequipped")
                current_weapon = nil
                scope_mesh = nil
                last_scope_state = false
            end
        end
        switch_scope_state(c_pawn)
    end
)


uevr.sdk.callbacks.on_script_reset(function()
    print("Resetting")
    destroy_actor(scope_actor)
    scope_plane_component = nil
    scene_capture_component = nil
    render_target = nil
    scope_mesh = nil
    reset_static_objects()
end)
