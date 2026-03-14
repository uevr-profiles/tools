
--caled in attach lua
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

--local Mesh_C= find_required_object("Class /Script/Engine.MeshComponent")

--local Equip_C= find_required_object("Class /Script/Test_C.PickUpActor")
--local Weapon=nil
--local PawnObjects= pawn.Children
--for i, comp in ipairs(PawnObjects) do
----	print(comp:get_full_name())
--	if string.find(comp:get_full_name(),"74M_C") then
--		Weapon=comp.SkeletalMesh
--		print("OK")
--	end
--end
--
--local OvMats= Weapon.OverrideMaterials
--for i ,comp in ipairs(OvMats) do
--	comp:SetScalarParameterValue("FOV_Alpha",0.0)
--end
--if Weapon~=nil then
--	local ChildrenOfWeapon= Weapon.AttachChildren
--	
--	for j , comp in ipairs(ChildrenOfWeapon) do
--		
--		local OvMatsC= comp.OverrideMaterials
--		for d ,comp2 in ipairs(OvMatsC) do
--			comp2:SetScalarParameterValue("FOV_Alpha",0.0)
--		end	
--	end
--end
--Material1= find_required_object("MaterialInstanceConstant /Game/Characters/Mannequins/Materials/Gloves/MI_Oakley_FP.MI_Oakley_FP")
--Material1.ScalarParameterValues[1].ParameterValue=0
function checkChildrenForMat2(Mesh,MatScalString)
	if Mesh.AttachChildren ~=nil then
		local ChildrenOfWeapon= Mesh.AttachChildren
				--	
		for s , comp1 in ipairs(ChildrenOfWeapon) do
			if comp1.OverrideMaterials ~=nil then
				local OvMatsC= comp1.OverrideMaterials
				for d , comp2 in ipairs(OvMatsC) do
					comp2:SetScalarParameterValue(MatScalString,0.0)
				end
			end
		end
	end
end	
function checkChildrenForMat(Mesh,MatScalString)
	if Mesh.AttachChildren ~=nil then
		local ChildrenOfWeapon= Mesh.AttachChildren
				--	
		for s , comp1 in ipairs(ChildrenOfWeapon) do
			if comp1.OverrideMaterials ~=nil then
				local OvMatsC= comp1.OverrideMaterials
				for d , comp2 in ipairs(OvMatsC) do
					comp2:SetScalarParameterValue(MatScalString,0.0)
				end
			end
			--checkChildrenForMat2(comp1,MatScalString)
		end
	end
end	
	
function checkMaterial(pawn,dMeshArray,MatScalString)
	--if pawn.Children~=nil then 
		local MeshArray = dMeshArray
		
		--print(#MeshArray)
		
		for i , comp in ipairs(MeshArray) do
			if comp["ShowcaseWeapon?"] ~=nil then
				local OvMats= comp.SkeletalMesh.OverrideMaterials
				--print(#OvMats)
				
				for k , comp2 in ipairs(OvMats) do
					if comp2.ScalarParameterValues ~= nil then
						--print(comp2parent)--comp2.ScalarParameterValues[1].ParameterValue)
					end
					comp2:SetScalarParameterValue(MatScalString,0.0)
				end
				local OvMats2= comp.DynamicMaterials
				--print(#OvMats)
				
				for k , comp2 in ipairs(OvMats2) do
					if comp2.ScalarParameterValues ~= nil then
						--print(comp2parent)--comp2.ScalarParameterValues[1].ParameterValue)
					end
					comp2:SetScalarParameterValue(MatScalString,0.0)
				end
				if comp.BP_WeaponComponent.Mag~=nil then
					local MagMats = comp.BP_WeaponComponent.Mag.StaticMesh.AttachChildren[1]
					if MagMats~=nil then
						MagMats:SetScalarParameterValueOnMaterials(MatScalString,0.0)
					end
				end
				if comp.SkeletalMesh.AttachChildren ~=nil then
					local ChildrenOfWeapon= comp.SkeletalMesh.AttachChildren
				--	
					for s , comp1 in ipairs(ChildrenOfWeapon) do
						if comp1.OverrideMaterials ~=nil then
							local OvMatsC= comp1.OverrideMaterials
							for d , comp2 in ipairs(OvMatsC) do
								comp2:SetScalarParameterValue(MatScalString,0.0)
							end
						end
						checkChildrenForMat(comp1,MatScalString)
					end
				end
			end
		end
		
		
--	end
end

--CALLED IN ATTACH Lua As well
local CheckDelta=0
uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)

pawn= api:get_local_pawn(0)



if pawn~=nil then
	if pawn.Children~=nil  then
		if CheckDelta>3 or ReloadMontage then
			CheckDelta=0

		local MeshArray = pawn.Children
		
		checkMaterial(pawn,MeshArray,"FOV_Alpha")
		
		else CheckDelta=CheckDelta+delta
		end
	end
end
end)