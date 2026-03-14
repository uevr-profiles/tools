

local api = uevr.api
	
	local params = uevr.params
	local callbacks = params.sdk.callbacks
	local pawn = api:get_local_pawn(0)
	local player= api:get_player_controller(0)
	local vr=uevr.params.vr
local function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        error("Cannot find " .. name)
        return nil
    end

    return obj
end
local find_static_class = function(name)
    local c = find_required_object(name)
    return c:get_class_default_object()
end

local Mesh_C= find_required_object("Class /Script/Engine.MeshComponent")


local function UpdateHands(dpawn)
	if dpawn==nil then return end
	if dpawn.GameplayHands==nil then return end
	local Mesh = dpawn.GameplayHands
	
	--print(#MeshArray)
	Mesh:SetScalarParameterValueOnMaterials("MasterLerp",0.0)

	

	local ChildrenOfWeapon= Mesh.AttachChildren
--	
	for s , comp1 in ipairs(ChildrenOfWeapon) do
		if comp1.OverrideMaterials~=nil then
			local OvMatsC= comp1.OverrideMaterials
			for d , comp2 in ipairs(OvMatsC) do
				comp2:SetScalarParameterValue("MasterLerp",0.0)
			end
		end
	end
end

local function UnlerpMeshes(dMesh)
	local OvMats= dMesh.OverrideMaterials
		--print(#OvMats)
	
		for k , comp2 in ipairs(OvMats) do
			comp2:SetScalarParameterValue("MasterLerp",0.0)
		end
		if dMesh.AttachChildren~=nil then
			local ChildrenOfWeapon= dMesh.AttachChildren
--			
			for s , comp1 in ipairs(ChildrenOfWeapon) do
				if comp1.OverrideMaterials~=nil then
					local OvMatsC= comp1.OverrideMaterials
					for d , comp2 in ipairs(OvMatsC) do
						comp2:SetScalarParameterValue("MasterLerp",0.0)
					end
				end
			end
		end
end
local wanted_mat = uevr.api:find_uobject("MaterialInstanceConstant /Engine/EngineMaterials/Widget3DPassThrough_Translucent.Widget3DPassThrough_Translucent")
local function UpdateCurrentItem(dpawn)
	if dpawn==nil then return end
	if dpawn.CurrentlyActiveItem==nil then return end
		local Mesh = nil
		if dpawn.CurrentlyActiveItem.WeaponMesh ~=nil then
			Mesh = dpawn.CurrentlyActiveItem.WeaponMesh
			UnlerpMeshes(Mesh)
		end
		
		if dpawn.CurrentlyActiveItem.SkeletalMesh~=nil then
			Mesh= dpawn.CurrentlyActiveItem.SkeletalMesh
			UnlerpMeshes(Mesh)
		end
		
		if dpawn.CurrentlyActiveItem.StaticMesh~=nil then
			Mesh= dpawn.CurrentlyActiveItem.StaticMesh
			UnlerpMeshes(Mesh)
		end
		if dpawn.CurrentlyActiveItem.Screen~=nil then
			Mesh= dpawn.CurrentlyActiveItem.Screen
			
			
				Mesh:SetScalarParameterValueOnMaterials("MasterLerp",0.5)
				Mesh:SetMaterial(0,wanted_mat)			
		end
		
		--print(#MeshArray)		
end





uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)

pawn= api:get_local_pawn(0)

UpdateCurrentItem(pawn)
UpdateHands(pawn)

end)