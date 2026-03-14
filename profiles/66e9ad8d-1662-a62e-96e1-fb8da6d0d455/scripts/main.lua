UEVR_UObjectHook.activate()

local api = uevr.api;
local params = uevr.params
local callbacks = params.sdk.callbacks
Runonce = false

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    local pawn = uevr.api:get_local_pawn()
    local player = pawn:get_full_name()



    if string.find(player, "Default") then
        Runonce = false
        --print("Not Ready")
    else
        local playerpos = pawn:get_full_name() .. ".GroundOffset"
        local HeadClass = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")
        local HeadInstances = HeadClass:get_objects_matching(false)
        for Index, HeadInstances in pairs(HeadInstances) do
            if HeadInstances:get_fname():to_string() == "FPVMesh" and string.find(tostring(HeadInstances:get_full_name()), "PersistentLevel.IndianaPlayerCharacter_BP_C") then
                Fpvmesh = HeadInstances
                --print(Fpvmesh:get_full_name())

                break
            end
        end

        local isset = tostring(Fpvmesh.RelativeScale3D.X)
        if not string.find(tostring(isset), "0.75") then
            print("Retying")
            print(isset)
            Runonce = false
        end

        if Runonce == false then
            local skeletal_mesh_c = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")
            if skeletal_mesh_c == nil then print("skeletal_mesh_c is nil") end
            local skeletal_meshes = skeletal_mesh_c:get_objects_matching(false)

            local arms_mesh = nil
            for i, mesh in ipairs(skeletal_meshes) do
                if string.find(tostring(mesh:get_full_name()), ".Inventory.SkeletalMeshComponent_") and string.find(tostring(mesh:get_full_name()), "PersistentLevel.IndianaPlayerCharacter_BP_C") then
                    Fpmesh = mesh
                    --print(Fpmesh:get_full_name())

                    break
                end
            end

            local fppos = string.gsub(playerpos, "IndianaPlayerCharacter_BP_C ", "SceneComponent ")
            local fpvpos = api:find_uobject(fppos)


            --Fpmesh.RelativeLocation.Z = -15.00
            --Fpmesh.RelativeLocation.X = 15.00
            Fpvmesh.RelativeScale3D.X = 0.76
            Fpvmesh.RelativeScale3D.Y = 0.74
            Fpvmesh.RelativeScale3D.Z = 0.71
            fpvpos.RelativeLocation.Z = -25.0
            Fpvmesh:call("SetRenderInMainPass", false)

            print("Applied")
            Runonce = true
        end
    end
end)


uevr.sdk.callbacks.on_script_reset(function()
    Runonce = false
end)
