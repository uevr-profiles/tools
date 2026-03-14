local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")

local M = {}

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[grabbables] " .. text, logLevel)
	end
end

local grabbedMapping = {
	{name="Katana", pos={0.0, 0.0, 50.0}, rot={-80.0, 0.0, 0.0}},
	{name="ExplosiveCanister", pos={5.0, 30.0, 3.0}, rot={0.0, 0.0, 0.0}},
	{name="ExplosiveBarrel", pos={-20.0, 0.0, 17.0}, rot={0.0, 0.0, 0.0}},
	{name="CryoBarrel", pos={-20.0, 0.0, 17.0}, rot={0.0, 0.0, 0.0}},
	{name="ExplosiveMonitor", pos={-4.8, -0.2, 9.8}, rot={0.0, 0.0, 0.0}},
	{name="ExplosiveExpoMine", pos={-2.6, 5.6, 13.0}, rot={0.0, 0.0, 0.0}},
	{name="ThrowableAxe", pos={0.0, 5.0, -20.0}, rot={-70.0, 0.0, 0.0}},
	{name="TV", pos={-8.2, 7.4, 18.4}, rot={0.0, 0.0, 0.0}},
	{name="CourthouseBench", pos={0.0, 25.0, -12.0}, rot={30.0, 0.0, 90.0}},
	{name="JetPack", pos={7.2, -0.6, -8.6}, rot={0.0, 0.0, -2.0}},
	{name="ThrowableObject_Trash", pos={24.8, 9.4, 77.8}, rot={0.0, 0.0, 0.0}},
	{name="PlasticDrum", pos={19, 12.2, 16.4}, rot={0.0, -90.0, 0.0}},
	{name="Basketball", pos={5.4, 13.2, -9.4}, rot={0.0, 0.0, 0.0}},
	{name="ExplosiveGasTank", pos={11.0, 11.8, 5.0}, rot={0.0, 0.0, 0.0}},
	{name="ExplosiveFuelCanister", pos={5.6, 11.8, 13.2}, rot={0.0, 0.0, 0.0}},
	{name="Explosive_CompressedAirTank", pos={0.6, 39.2, -1.4}, rot={-54.6, 0.2, -0.4}},
	{name="Wights_Throwable", pos={0.6, 0.2, -0.8}, rot={0.0, -14.6, 90}},
	{name="BikersBike", pos={-87, 28.2, 13}, rot={0.0, 90.0, 5.0}},	
	{name="ThrowableHammer", pos={0.0, -45.0, 0.0}, rot={12.0, 0.0, 0.0}},	
	{name="SM_chair_02_Throwable", pos={0.0, 30.2, 0.0}, rot={0, 0, 0}},
	{name="Throwable_Chair1", pos={-19.2, 10.8, 22.6}, rot={0, 34, 0}},
	{staticmesh="SM_Basketball_01a", pos={9.4, 12.2, 4.2}, rot={0.0, 0.0, 0.0}},
	{staticmesh="SM_Barbells_01", pos={0.6, 0.2, -0.8}, rot={0.0, -14.6, 90}},
	{staticmesh="SM_Barbells_02", pos={0.6, 0.2, -0.8}, rot={0.0, -14.6, 90}},
	{staticmesh="SM_Chair_01a", pos={-29.6, 16.0, 30.2}, rot={14.4, -0.2, 9.4}},
	{staticmesh="SM_LP_Radiator1", pos={7.8, 9.6, -22.6}, rot={0, 0, 0}},
	{staticmesh="SM_LobbyChair_01b", pos={-27.4, 3.8, 28.2}, rot={0, 0, 0}},	
	{skeletalmesh="SK_Armchair", pos={-28.6, 3.8, 27}, rot={0, 0, 0}},
	{skeletalmesh="SK_LP_ComputerChair", pos={0.0, 20.2, -3.4}, rot={0, 0, 0}},
	
}
--B_ExplosiveCanisterSpline_Throwable_Child
--B_Throwable_ExplosiveBarrel_C_1.StaticMesh
--B_Throwable_CryoBarrel_C_12
--BP_ExplosiveMonitor_Throwable_C_7
--BP_ExplosiveExpoMine_Throwable_C_1
--BP_ThrowableAxe_C_0
--BP_Police_TV_Throwable_02_C_0
--BP_CourthouseBench_Throwable_C_11 (skeletalmesh)
--ChildActor_GEN_VARIABLE_BP_JetPack_Throwable_C_CAT_3070
--BP_ThrowableObject_Trash_C_4
--BP_PlasticDrum_Throwable_C_7
--BP_SM_Wights_Throwable_03
--BP_Basketball_Throwable_C_1
--BP_ExplosiveGasTank_Throwable_C_1
--P_Explosive_CompressedAirTank_Throwable_C_1
--BP_ExplosiveFuelCanister_Throwable_C_1
--StaticMeshActor_400 (other weights)
--StaticMeshActor_323 (more weights)
--StaticMeshActor_80 (chair)
function getGrabbedOffset(weapon, offsetType) -- 1 position, 2 rotation
	if uevrUtils.getValid(weapon) ~= nil and (offsetType == 1 or offsetType == 2) then
		local ext = {"pos", "rot"}
		local weaponName = weapon:get_full_name()
		M.print("Getting offset for " .. weaponName .. " " .. offsetType)
		for i = 1, #grabbedMapping do
			local name = grabbedMapping[i]["name"]
			if name ~= nil then
				if string.find(weaponName, name) then
					local value = uevrUtils.vector(grabbedMapping[i][ext[offsetType]])
					M.print("Found offset for " .. weaponName .. " " .. offsetType .. " " .. value.X .. " " .. value.Y .. " " .. value.Z )
					if value ~= nil then
						return value
					end				
				end
			end

			local staticMesh = grabbedMapping[i]["staticmesh"]
			if staticMesh ~= nil and weapon.StaticMesh ~= nil then
				local staticMeshName = weapon.StaticMesh:get_full_name()
				if string.find(staticMeshName, staticMesh) then
					local value = uevrUtils.vector(grabbedMapping[i][ext[offsetType]])
					M.print("Found offset for " .. weaponName .. " " .. offsetType .. " " .. value.X .. " " .. value.Y .. " " .. value.Z )
					if value ~= nil then
						return value
					end				
				end
			end

			local skeletalMesh = grabbedMapping[i]["skeletalmesh"]
			if skeletalMesh ~= nil and weapon.SkeletalMesh ~= nil then
				local skeletalMeshName = weapon.SkeletalMesh:get_full_name()
				if string.find(skeletalMeshName, skeletalMesh) then
					local value = uevrUtils.vector(grabbedMapping[i][ext[offsetType]])
					M.print("Found offset for " .. weaponName .. " " .. offsetType .. " " .. value.X .. " " .. value.Y .. " " .. value.Z )
					if value ~= nil then
						return value
					end				
				end
			end
		end
	end
	return uevrUtils.vector(0,0,0)
end


local hasGrabbed = false
local grabbedState = nil
local originalGrabbedComponent = nil
local lastDisabledComponent = nil
local clonedGrabbedComponent = nil
function M.checkGrabbedComponent(handedness, disable)
	local grabbedComponent = nil
	if disable == false then 
		grabbedComponent = uevrUtils.getValid(pawn,{"PhysicsHandle","GrabbedComponent"})
		--do no allow regrabbing a component that was disabled
		if lastDisabledComponent == grabbedComponent then
			grabbedComponent = nil
		end
	end
	if grabbedComponent ~= nil and hasGrabbed == false then 
		M.print("Grabbed component "	.. grabbedComponent:get_full_name())	
		if grabbedComponent.StaticMesh ~= nil then
			M.print("Grabbed component static mesh name is "	.. grabbedComponent.StaticMesh:get_full_name())	
		end
		if grabbedComponent.SkeletalMesh ~= nil then
			M.print("Grabbed component skeletal mesh name is "	.. grabbedComponent.SkeletalMesh:get_full_name())	
		end
		if pawn.GrabbingMesh ~= nil then
			pawn.GrabbingMesh:SetVisibility(false, true)
		end
		grabbedComponent:SetVisibility(false, true)
		clonedGrabbedComponent = uevrUtils.cloneComponent(grabbedComponent)
		
		if clonedGrabbedComponent ~= nil then
			local state = UEVR_UObjectHook.get_or_add_motion_controller_state(clonedGrabbedComponent)
			state:set_hand(handedness)
			state:set_permanent(false)
			local rot = getGrabbedOffset(grabbedComponent, 2)
			local loc = getGrabbedOffset(grabbedComponent, 1)
			state:set_location_offset(Vector3f.new(loc.X, loc.Y, loc.Z)) 
			state:set_rotation_offset(Vector3f.new( math.rad(rot.X), math.rad(rot.Y),  math.rad(rot.Z)))

			uevrUtils.fixMeshFOV(clonedGrabbedComponent, "UsePanini", 0.0, true, true, true) 
			
			grabbedState = state
		end
		originalGrabbedComponent = grabbedComponent
	end
	if grabbedComponent == nil and hasGrabbed == true then 
		if disable then 
			lastDisabledComponent = originalGrabbedComponent
		end
		if not disable and uevrUtils.getValid(originalGrabbedComponent) ~= nil and originalGrabbedComponent.SetVisibility ~= nil then
			originalGrabbedComponent:SetVisibility(true)
		end
		if clonedGrabbedComponent ~= nil then clonedGrabbedComponent:SetVisibility(false) end
		uevrUtils.destroyComponent(clonedGrabbedComponent, true, true)
		originalGrabbedComponent = nil
		clonedGrabbedComponent = nil
	end
	
	if grabbedComponent == nil then
		grabbedState = nil
	end
	hasGrabbed = grabbedComponent ~= nil
end

function M.updateGrabbedOrientation()
	if grabbedState ~= nil then
		local loc = configui.getValue("grabbed_item_location")
		local rot = configui.getValue("grabbed_item_rotation")
		grabbedState:set_location_offset(Vector3f.new(loc.X, loc.Y, loc.Z)) 
		grabbedState:set_rotation_offset(Vector3f.new( math.rad(rot.X), math.rad(rot.Y),  math.rad(rot.Z)))
	end
end

function M.isGrabbing()
	return hasGrabbed
end

return M