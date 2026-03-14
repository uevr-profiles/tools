
--local controllers = require('libs/controllers')
--local uevrUtils = require("libs/uevr_utils")
require(".\\Config\\CONFIG")
require(".\\Subsystems\\Motion")
local api = uevr.api
local params = uevr.params
local callbacks = params.sdk.callbacks
local vr=uevr.params.vr
--function find_required_object(name)
--    local obj = uevr.api:find_uobject(name)
--    if not obj then
--        error("Cannot find " .. name)
--        return nil
--    end
--
--    return obj
--end
--function find_static_class(name)
--    local c = find_required_object(name)
--    return c:get_class_default_object()
--end
--
--function find_first_of(className, includeDefault)
--	if includeDefault == nil then includeDefault = false end
--	local class =  find_required_object(className)
--	if class ~= nil then
--		return UEVR_UObjectHook.get_first_object_by_class(class, includeDefault)
--	end
--	return nil
--end
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

if Potato and not CheckedPotato then
	CheckedPotato=true
	DisableFoliage()
end
