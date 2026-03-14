local uevrUtils = require("libs/uevr_utils")
local configui = require("libs/configui")
local scope = require("libs/scope")
scope.setLogLevel(LogLevel.Debug)

local M = {}

local activeWeapon = nil
local activeHand = nil
local currentLocationOffset = {0, 0, 0}

local debugWeaponLocationComponent = nil
local debugTargetLocationComponent = nil

local weaponState = nil

local weaponMapping = {
	{name="BerettaAuto", pos={0.0, 0.0, 0.0}, rot={-0.5, 0.2, 0.0}},
	{name="SigSauer", pos={0.0, 0.0, 0.0}, rot={0.0, 0.0, 0.0}},
	{name="AKM", pos={-6.0, -3.2, 0}, rot={0.0, 0.0, 0.0}},
	{name="SmgUZI", pos={-0.8, 0.0, 0.6}, rot={-0.2, 0.6, 0.0}},
	{name="SteyrAUG", pos={-0.8, -0.8, 2.0}, rot={-0.4, 0.6, 0.0}, scope={ocular_position={-1.350, -11.00, 16.500}, ocular_scale=0.66, objective_rotation={90,0,-90}, fov=5.0, socket="MuzzleSocket", brightness=1.0}},
	{name="BrowningM60", pos={-1.4, 0.7, 0.6}, rot={0.0, 0.0, 0.0}},
	{name="Mossberg", pos={0.0, 0.0, 0.0}, rot={-2.0, 0.2, 0.0}},
	{name="HK21", pos={0.0, 0.0, 0.0}, rot={0.0, 0.0, 0.0}},
	{name="DesertEagle", pos={0.0, 0.0, 0.0}, rot={-0.3, 0.9, 0.0}},
	{name="ATGM", pos={0.0, 0.3, 0.6}, rot={0.0, 0.0, 0.0}, scope={ocular_position={8.55, -4.15, 17.95}, ocular_scale=0.347, objective_rotation={90,0,90}, fov=5.0, socket="MuzzleSocket", brightness=1.0}},
	{name="IntraTec", pos={0.0, 0.0, 0.0}, rot={0.0, 0.3, 0.0}},
	{name="HKG11", pos={0.0, 0.0, 0.0}, rot={-0.6, 0.7, 0.0}, scope={ocular_position={0, -10.25, 21.4}, ocular_scale=0.66, objective_rotation={90,0,-90}, fov=3.0, socket="MuzzleSocket", brightness=1.0}},
	{name="Spas12", pos={0.0, 0.0, 0.0}, rot={0.0, 0.4, 0.0}},
	{name="MM1GL", pos={-0.5, 0.7, -0.2}, rot={0.0, -0.6, 0.0}},
	{name="Sniper", pos={-2.4, 0.0, 0.0}, rot={-0.1, 0.0, 0.0}, scope={ocular_position={0.3, -6.75, 18.5}, ocular_scale=0.876, objective_rotation={90,0,90}, fov=2.0, socket="TrueMuzzle", brightness=1.0}},
	{name="BarrettM82_explosive", pos={0.0, 0.0, 0.0}, rot={-1.4, 0.0, 0.0}, scope={ocular_position={0.3, -1.95, 16.85}, ocular_scale=1.028, objective_rotation={90,0,90}, fov=2.0, socket="TrueMuzzle", brightness=1.0}},
	{name="BarrettM82", pos={0.0, 0.0, 0.0}, rot={0.0, 0.0, 0.0}},
	{name="SterlingMk6", pos={0.0, 0.0, 0.0}, rot={0.0, 0.6, 0.0}},
	{name="Minigun", pos={1.9, 2.9, 0.5}, rot={0.0, 0.0, 0.0}},
	{name="Cryo", pos={0.7, 3.0, -1.5}, rot={0.0, 0.0, 0.0}},
	{name="ED_MachineGun", pos={0.0, 0.0, 0.0}, rot={0.0, 0.0, 0.0}},
}

--RifleScope
--WB_RifleScope_C /Engine/Transient.GameEngine_0.BP_MyGameInstance_C_0.WB_RifleScope_C_1
--WidgetBlueprintGeneratedClass /Game/UI/WeaponsWidgets/WB_RifleScope.WB_RifleScope_C
--WB_HUDFPP_C /Engine/Transient.GameEngine_0.BP_MyGameInstance_C_0.WB_HUDFPP_C_1
--get first of WidgetBlueprintGeneratedClass /Game/UI/HUD/WB_HUDFPP.WB_HUDFPP_C
-- then call void ScopeMode(bool Active);

local configDefinition = {
	{
		panelLabel = "RoboCop Weapons", 
		saveFile = "config_weapons",
		isHidden = true,
		layout = 
		{		
			{
				widgetType = "checkbox",
				id = "robocop_weapons_show_debug",
				label = "Show debug meshes",
				initialValue = false
			},
		}	
	}
}

configui.onUpdate("robocop_weapons_show_debug", function(value)
	M.showDebug(value)
end)


function createConfig()
	
	table.insert(configDefinition[1]["layout"], 
		{
			widgetType = "tree_node",
			id = "robocop_weapons",
			initialOpen = true,
			label = "Robocop Weapon Config"
		}
	)

	for i = 1, #weaponMapping do
		local name = weaponMapping[i]["name"]
		local pos = weaponMapping[i]["pos"]
		local rot = weaponMapping[i]["rot"]
		table.insert(configDefinition[1]["layout"], 
				{
					id = "robocop_weapons_" .. name, label = name, widgetType = "tree_node",
				}
		)
		table.insert(configDefinition[1]["layout"], 
					{					
						id = "robocop_" .. name .. "_pos", label = "Position",
						widgetType = "drag_float3", speed = .1, range = {-10, 10}, initialValue = pos
					}
		)
		table.insert(configDefinition[1]["layout"], 
					{					
						id = "robocop_" .. name .. "_rot", label = "Rotation",
						widgetType = "drag_float3", speed = .1, range = {-360, 360}, initialValue = rot
					}
		)
		table.insert(configDefinition[1]["layout"], 
				{
					widgetType = "tree_pop"
				}
		)
		
		configui.onUpdate("robocop_" .. name .. "_pos", function(value)
			updateWeaponTransform(value, nil, name) 
		end)
		configui.onUpdate("robocop_" .. name .. "_rot", function(value)
			updateWeaponTransform(nil, value, name)
		end)
			
	end
	
	table.insert(configDefinition[1]["layout"], 
		{
			widgetType = "tree_pop"
		}
	)

	configui.create(configDefinition)

end
createConfig()

function M.print(str, logLevel)
	uevrUtils.print("[Weapons] " .. str, logLevel)
end

function M.onLevelChange()
	M.reset()
	M.showDebug(configui.getValue("robocop_weapons_show_debug"))
end

function M.reset()
	activeWeapon = nil
	activeHand = nil
	debugWeaponLocationComponent = nil
	debugTargetLocationComponent = nil
end

function getWeaponOffset(weapon, offsetType) -- 1 position, 2 rotation
	if uevrUtils.getValid(weapon) ~= nil and (offsetType == 1 or offsetType == 2) then
		local ext = {"_pos", "_rot"}
		local weaponName = weapon:get_full_name()
		M.print("Getting offset for " .. weaponName .. " " .. offsetType)
		for i = 1, #weaponMapping do
			local name = weaponMapping[i]["name"]
			if string.find(weaponName, name) then
				local id = "robocop_" .. name .. ext[offsetType]
				local value = configui.getValue(id)	
				if value ~= nil then
					return value
				end				
			end
		end
	end
	return uevrUtils.vector(0,0,0)
end

function isWeaponScoped(weapon) -- 1 position, 2 rotation
	if uevrUtils.getValid(weapon) ~= nil then
		local weaponName = weapon:get_full_name()
		for i = 1, #weaponMapping do
			local name = weaponMapping[i]["name"]
			if string.find(weaponName, name) then
				return weaponMapping[i]["scope"] ~= nil
			end
		end
	end
	return false
end

function getScopeSettings(weapon) -- 1 position, 2 rotation
	if uevrUtils.getValid(weapon) ~= nil then
		local weaponName = weapon:get_full_name()
		for i = 1, #weaponMapping do
			local name = weaponMapping[i]["name"]
			if string.find(weaponName, name) then
				return name, weaponMapping[i]["scope"]
			end
		end
	end
	return nil
end

function updateScope(currentWeapon)
	local weaponID, scopeSettings = getScopeSettings(currentWeapon)
	if scopeSettings ~= nil then
		M.print("Found scope settings. Creating scope")
		local ocularLensComponent, objectiveLensComponent = scope.create({id=weaponID, disabled=false, fov=scopeSettings.fov, brightness=scopeSettings.brightness, scale=scopeSettings["ocular_scale"], deactivateDistance=8.75, hideOcularLensOnDisable=true})
		if objectiveLensComponent ~= nil then
			objectiveLensComponent:K2_AttachToComponent(
					currentWeapon,
					scopeSettings["socket"],
					0, -- Location rule
					0, -- Rotation rule
					0, -- Scale rule
					false -- Weld simulated bodies
				)
		else
			M.print("Objective lens component creation failed")
		end
		if ocularLensComponent ~= nil then
			ocularLensComponent:K2_AttachToComponent(
					currentWeapon,
					"",
					0, -- Location rule
					0, -- Rotation rule
					0, -- Scale rule
					false -- Weld simulated bodies
				)
		else
			M.print("Ocular lens component creation failed")
		end
		scope.setObjectiveLensRelativeRotation(scopeSettings["objective_rotation"])
		scope.setOcularLensRelativeRotation({0,0,-90})
		scope.setOcularLensRelativeLocation(scopeSettings["ocular_position"])
		M.print("Scope created")
	else
		M.print("No weapon scope settings found. Destroying scope")
		scope.destroy()
	end
end

function updateWeaponTransform(pos, rot, name)
	if uevrUtils.validate_object(activeWeapon) ~= nil then
		local weaponName = activeWeapon:get_full_name()
		if string.find(weaponName, name) then		
			if weaponState ~= nil then
				if pos ~= nil then
					weaponState:set_location_offset(Vector3f.new( pos.X, pos.Y, pos.Z))
				end
				if rot ~= nil then
					weaponState:set_rotation_offset(Vector3f.new( math.rad(rot.X), math.rad(rot.Y+90),  math.rad(rot.Z)))
				end
			end
		end
	end
end

function updateDebug()
	if activeWeapon ~= nil and debugWeaponLocationComponent ~= nil and debugTargetLocationComponent ~= nil then
		local weaponDirection = kismet_math_library:GetForwardVector( activeWeapon:GetSocketRotation(uevrUtils.fname_from_string("MuzzleSocket")))
		weaponLocation = activeWeapon:GetSocketLocation(uevrUtils.fname_from_string("MuzzleSocket"))
		local targetLocation = weaponLocation + (weaponDirection * 8192.0)
		
		local ignore_actors = {}
		local world = uevrUtils.get_world()
		if world ~= nil then
			local hit = kismet_system_library:LineTraceSingle(world, weaponLocation, targetLocation, 0, true, ignore_actors, 0, reusable_hit_result, true, zero_color, zero_color, 1.0)
			if hit and reusable_hit_result.Distance > 10 then
				targetLocation = {X=reusable_hit_result.Location.X, Y=reusable_hit_result.Location.Y, Z=reusable_hit_result.Location.Z}
			end
		end
		debugWeaponLocationComponent:K2_SetWorldLocation(weaponLocation, false, reusable_hit_result, false)
		debugTargetLocationComponent:K2_SetWorldLocation(targetLocation, false, reusable_hit_result, false)
	end
end

function M.update(currentWeapon, hand)
	if hand == nil then hand = Handed.Right end
	local lastWeapon = activeWeapon
	if hand ~= activeHand or (uevrUtils.validate_object(activeWeapon) ~= nil and uevrUtils.validate_object(currentWeapon) ~= nil and activeWeapon ~= currentWeapon) then
		M.print("Disconnecting weapon")
		UEVR_UObjectHook.remove_motion_controller_state(activeWeapon)
		activeWeapon = nil
	end
	
	if uevrUtils.validate_object(currentWeapon) ~= nil and not string.find(currentWeapon:get_full_name(), "NoWeapon") and activeWeapon ~= currentWeapon then
		M.print("Connecting weapon ".. currentWeapon:get_full_name() .. " " .. currentWeapon:get_fname():to_string() .. " to hand " .. hand)
		local state = UEVR_UObjectHook.get_or_add_motion_controller_state(currentWeapon)
		state:set_hand(hand)
		state:set_permanent(true)
		local rot = getWeaponOffset(currentWeapon, 2)
		local loc = getWeaponOffset(currentWeapon, 1)
		state:set_rotation_offset(Vector3f.new( math.rad(rot.X), math.rad(rot.Y+90),  math.rad(rot.Z)))
		state:set_location_offset(Vector3f.new(loc.X, loc.Y, loc.Z)) --uevrUtils.vector(getWeaponOffset(currentWeapon, 1)))
		weaponState = state
		--print(currentWeapon:get_full_name())
		
		uevrUtils.fixMeshFOV(currentWeapon, "UsePanini", 0.0, true, true, true)	
		activeWeapon = currentWeapon			
	end
	activeHand = hand
	
	if lastWeapon ~= activeWeapon then
		if on_weapon_change ~= nil then
			on_weapon_change(activeWeapon,	activeWeapon ~= nil and not string.find(activeWeapon:get_full_name(), "NoWeapon"))
		end
		
		updateScope(activeWeapon)
	end
	
	updateDebug()
end


function M.connectToSocket(pawn, handComponent, socketName, offset)
	local lastWeapon = activeWeapon
	local currentWeapon = uevrUtils.getValid(pawn,{"Weapon","WeaponMesh"})
	if uevrUtils.validate_object(activeWeapon) ~= nil and currentWeapon ~= nil and activeWeapon ~= currentWeapon then
		M.print("Disconnecting weapon")
		activeWeapon = nil
	end


	if currentWeapon ~= nil and not string.find(pawn.Weapon:get_full_name(), "NoWeapon") and activeWeapon ~= currentWeapon then
	M.print("Attaching weapon to socket")
		currentWeapon:K2_AttachTo(handComponent, uevrUtils.fname_from_string(socketName), 0, false)
		uevrUtils.set_component_relative_transform(currentWeapon, offset, offset)	
		activeWeapon = currentWeapon			
	end
	if lastWeapon ~= activeWeapon then
		M.print("Weapon changed")

		if on_weapon_change ~= nil then
			on_weapon_change(activeWeapon)
		end
	end
end


function M.getActiveWeapon()
	return activeWeapon
end

function M.showDebug(value)
	if value == true then
		if debugWeaponLocationComponent == nil then
			debugWeaponLocationComponent = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/EngineMeshes/Sphere.Sphere") 
			uevrUtils.set_component_relative_transform(debugWeaponLocationComponent, nil, nil, {0.01,0.01,0.01})
		end
		if debugTargetLocationComponent == nil then
			debugTargetLocationComponent = uevrUtils.createStaticMeshComponent("StaticMesh /Engine/EngineMeshes/Sphere.Sphere") 
			uevrUtils.set_component_relative_transform(debugTargetLocationComponent, nil, nil, {0.05,0.05,0.05})
		end
	else
		if debugWeaponLocationComponent ~= nil then		 
			uevrUtils.destroyComponent(debugWeaponLocationComponent,true,true)
			debugWeaponLocationComponent = nil
		end
		if debugTargetLocationComponent ~= nil then
			uevrUtils.destroyComponent(debugTargetLocationComponent,true,true)
			debugTargetLocationComponent = nil
		end
	
	end
end




-- not needed anymore, using configui instead
function M.adjustLocation(axis, delta)
	if uevrUtils.getValid(activeWeapon) ~= nil then
		local state = UEVR_UObjectHook.get_or_add_motion_controller_state(activeWeapon)
		currentLocationOffset[axis] = currentLocationOffset[axis] + delta
		state:set_location_offset(Vector3f.new(currentLocationOffset[1], currentLocationOffset[2], currentLocationOffset[3]))
		M.printHandTranforms()
	end
end

function M.adjustRotation(axis, delta)
	M.print("adjustRotation not implemented")
end
local adjustMode = 2  -- 1-weapon rotation  2-weapon location
local adjustModeLabels = {"Weapon Rotation", "Weapon Location"}
local positionDelta = 0.2
local rotationDelta = 5

function M.enableAdjustments()	
	M.print("Adjust Mode " .. adjustModeLabels[adjustMode])
	
	register_key_bind("NumPadFive", function()
		M.print("Num5 pressed")
		adjustMode = (adjustMode % 2) + 1
		M.print("Adjust Mode " .. adjustModeLabels[adjustMode])
	end)

	register_key_bind("NumPadEight", function()
		M.print("Num8 pressed")
		if adjustMode == 1 then
			M.adjustRotation(1, rotationDelta)
		elseif adjustMode == 2 then
			M.adjustLocation(1, positionDelta)
		end
	end)
	register_key_bind("NumPadTwo", function()
		M.print("Num2 pressed")
		if adjustMode == 1 then
			M.adjustRotation(1, -rotationDelta)
		elseif adjustMode == 2 then
			M.adjustLocation(1, -positionDelta)
		end
	end)

	register_key_bind("NumPadFour", function()
		M.print("Num4 pressed")
		if adjustMode == 1 then
			M.adjustRotation(2, rotationDelta)
		elseif adjustMode == 2 then
			M.adjustLocation(2, positionDelta)
		end
	end)
	register_key_bind("NumPadSix", function()
		M.print("Num6 pressed")
		if adjustMode == 1 then
			M.adjustRotation(2, -rotationDelta)
		elseif adjustMode == 2 then
			M.adjustLocation(2, -positionDelta)
		end
	end)

	register_key_bind("NumPadThree", function()
		M.print("Num3 pressed")
		if adjustMode == 1 then
			M.adjustRotation(3, rotationDelta)
		elseif adjustMode == 2 then
			M.adjustLocation(3, positionDelta)
		end
	end)
	register_key_bind("NumPadOne", function()
		M.print("Num1 pressed")
		if adjustMode == 1 then
			M.adjustRotation(3, -rotationDelta)
		elseif adjustMode == 2 then
			M.adjustLocation(3, -positionDelta)
		end
	end)
end

function M.printHandTranforms()
	--M.print("Rotation = {" .. currentRotationOffset[1] .. ", " .. currentRotationOffset[2] .. ", "  .. currentRotationOffset[3] ..  "}", LogLevel.Info)
	M.print("Location = {" .. currentLocationOffset[1] .. ", " .. currentLocationOffset[2] .. ", "  .. currentLocationOffset[3] ..  "}", LogLevel.Info)
end




return M