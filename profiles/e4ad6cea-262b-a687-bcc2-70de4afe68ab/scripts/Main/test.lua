
--local controllers = require('libs/controllers')
--local uevrUtils = require("libs/uevr_utils")
--require(".\\Subsystems\\Motion")
local api = uevr.api
local params = uevr.params
local callbacks = params.sdk.callbacks
local vr=uevr.params.vr
function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        error("Cannot find " .. name)
        return nil
    end

    return obj
end
function find_static_class(name)
    local c = find_required_object(name)
    return c:get_class_default_object()
end

function find_first_of(className, includeDefault)
	if includeDefault == nil then includeDefault = false end
	local class =  find_required_object(className)
	if class ~= nil then
		return UEVR_UObjectHook.get_first_object_by_class(class, includeDefault)
	end
	return nil
end
--
local array ={}
--array1={}
--array2={}
local MeshStatic_c= find_required_object("Class /Script/Engine.StaticMeshComponent")
local MeshSkelt_c = find_required_object("Class /Script/Engine.SkeletalMeshComponent")

local MeshArrayStatic=  UEVR_UObjectHook.get_objects_by_class(MeshStatic_c,false)	
local MeshArraySkelt =  UEVR_UObjectHook.get_objects_by_class(MeshSkelt_c,false)	


local function DisableFoliage()
	array= {}


	for i,comp in ipairs(MeshArrayStatic) do
		--comp.MinDrawDistance = 0.01
		if string.find(comp:get_full_name(),"foliage") 
		or string.find(comp:get_full_name(),"Grass")
		or string.find(comp:get_full_name(),"Foliage") then
			comp:SetVisibility(false,true)
			table.insert(array, comp)
		end
	end
	for i,comp in ipairs(MeshArraySkelt) do
		--comp.MinDrawDistance=0
		if string.find(comp:get_full_name(),"Patch") or
			string.find(comp:get_full_name(),"Belt")or
			string.find(comp:get_full_name(),"NVG")then
	--	comp.ForcedLodModel=100	
		comp:SetVisibility(false,false)
		table.insert(array, comp)
		end
	end	
end
if Potato()
	DisableFoliage()
end
	
	--comp.MinDesiredLOD  = 1


--local VHitBoxClass= find_required_object("Class /Script/Engine.BoxComponent")
--local SHitBoxClass= find_required_object("Class /Script/Engine.SplineMeshComponent")
--local Vec_c = find_required_object("ScriptStruct /Script/CoreUObject.Vector")

--local testMat= find_required_object("MaterialInstanceDynamic /Engine/Transient.MID_EX_MI_Reddot_Reticle_Cross_282")
----MaterialInstanceDynamic /Engine/Transient.MID_EX_MI_Reddot_Reticle_Cross_282
--testMat.BasePropertyOverrides.DisplacementFadeRange.EndSizePixels=1000
--testMat.BasePropertyOverrides.DisplacementFadeRange.StartSizePixels=500
--testMat.BasePropertyOverrides.DisplacementScaling.Magnitude=500
--testMat.BasePropertyOverrides.DisplacementScaling.Center=10
 hmd_component =nil
 right_hand_component=nil
local  HmdVector=	Vector3d.new(0,0,0)--StructObject.new(Vec_c)
local HandVector=	Vector3d.new(0,0,0)--StructObject.new(Vec_c)
local HmdVector2=	Vector3d.new(0,0,0)--StructObject.new(Vec_c)
local HandVector2=	Vector3d.new(0,0,0)--StructObject.new(Vec_c)
local HmdVector3=	Vector3d.new(0,0,0)--StructObject.new(Vec_c)
local HandVector3=	Vector3d.new(0,0,0)--StructObject.new(Vec_c)
--local Array111={HmdVector,HandVector,HmdVector2,HandVector2,HmdVector3,HandVector3}
 --print("hey")
 
 
 --local class_obj = uevr.api:find_uobject("MST_BP_SquadSpawnMarker_C /Game/MisultinAI/Core/Spawners/MST_BP_SquadSpawnMarker.Default__MST_BP_SquadSpawnMarker_C")
 --
 --local function test()
--	local  HmdVector=nil
--	
--	if pawn~=nil then
--		
--		HmdVector=		dMesh:K2_GetComponentLocation()
--	local HandVector=	dMesh:K2_GetComponentLocation()
--	--local HmdVector2=	dMesh:K2_GetComponentLocation()
--	--local HandVector2=	dMesh:K2_GetComponentLocation()
--	--local HmdVector3=	dMesh:K2_GetComponentLocation()
--	--local HandVector3=	dMesh:K2_GetComponentLocation()
 --
--	end
--		return HmdVector
e--nd
 
 
-- class_obj:ActivateAISpawner(10)
-- 
-- 
-- 
-- local dMesh = nil   --pawn.Mesh
-- local pawn = nil --api:get_local_pawn(0)
-- uevr.sdk.callbacks.on_pre_engine_tick(
--function(engine, delta)
--	print("hey")
--	
--if pawn ~= nil then	
--	
--	if dMesh==nil then
--		dMesh=pawn.Mesh
--	end
--
--else
--	pawn= api:get_local_pawn(0)
--end	
--
--end)