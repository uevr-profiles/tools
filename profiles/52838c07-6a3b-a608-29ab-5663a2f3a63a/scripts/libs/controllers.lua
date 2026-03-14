--[[ 
Usage
	Drop the lib folder containing this file into your project folder
	At the top of your script file add 
		local controllers = require("libs/controllers")
		
	In your code call function like this
		controllers.destroyControllers()
		
	In all of the functions, controllerID=0 is the left controller, controllerID=1 is the right controller and controllerID=2 is the hmd controller
	
	Available functions:
	
	controllers.onLevelChange() - call this function when there is a level change to clean up any allocated resources
		
	controllers.createController(controllerID) - creates the left controller (controllerID=0), right controller (controllerID=1) or hmd controller (controllerID=2)		
		example:
			function on_level_change(level)
				print("Level changed\n")
				controllers.onLevelChange()
				controllers.createController(0)
				controllers.createController(1)
				controllers.createController(2) 
			end
			
	controllers.createHMDController() - same as calling controllers.createController(2)
	
	controllers.getController(controllerID) - returns the component associated with the controllerID. 
		For controllerIDs 0 and 1 this is a "Class /Script/HeadMountedDisplay.MotionControllerComponent" class. 
		For controllerID 2 this is a "Class /Script/Engine.SceneComponent" class
		example:
			local hmdComponent = controllers.getController(2)
			
	controllers.getHMDController()  - same as calling controllers.getController(2)
	
	controllers.controllerExists(controllerID) - returns true if the given controllerID is already created. 
		Same as calling controllers.getController(controllerID) ~= nil
		example:
			local hmdExists = controllers.controllerExists(2)
			
	controllers.hmdControllerExists() - same as calling controllers.controllerExists(2)
	
	controllers.destroyController(controllerID) - deallocate the resources associated the given controllerID
		example:
			controllers.destroyController(2)
	
	controllers.destroyControllers() - deallocate the resources associated with all controllers
		example:
			controllers.destroyControllers()
			
	controllers.attachComponentToController(controllerID, childComponent, (optional)socketName, (optional)attachType, (optional)weld) - attach an 
		element derived from a component class to the given controller.
		Returns true if successful
		example:
			local weapon = pawn:GetCurrentWeapon()
			if weapon ~= nil  then
				local meshComponent = weapon.SkeletalMeshComponent
				if meshComponent ~= nil then
					meshComponent:DetachFromParent(false,false)
					meshComponent:SetVisibility(true, true)
					meshComponent:SetHiddenInGame(false, true)
					weaponConnected = controllers.attachComponentToController(1, meshComponent)
					uevrUtils.set_component_relative_transform(meshComponent, {X=0,Y=0,Z=0}, {Pitch=0,Yaw=0,Roll=0})
				end
			end

	controllers.getControllerLocation(controllerID) - gets the current position FVector in world space of the given controller or nil if none found
		example:
			local rightLocation = controllers.getControllerLocation(1)
			print("X is", rightLocation.X)

	controllers.getControllerRotation(controllerID) - gets the current rotation FRotator in world space of the given controller or nil if none found
		example:
			local rightRotation = controllers.getControllerRotation(1)
			print("Yaw is", rightRotation.Yaw)

	controllers.getControllerDirection(controllerID) - gets the current forward vector FVector of the given controller or nil if none found
		example:
			local hmdDirection = controllers.getControllerDirection(2)
			print("Forward Vector is", hmdDirection.X, hmdDirection.Y, hmdDirection.Z)

	controllers.getControllerUpVector(controllerID) - gets the current up vector FVector of the given controller or nil if none found
		example:
			local rightUpVector = controllers.getControllerUpVector(1)
			print("Up Vector is", rightUpVector.X, rightUpVector.Y, rightUpVector.Z)

	controllers.getControllerRightVector(controllerID) - gets the current right vector FVector of the given controller or nil if none found
		example:
			local leftRightVector = controllers.getControllerRightVector(0)
			print("Right Vector is", leftRightVector.X, leftRightVector.Y, leftRightVector.Z)

	controllers.getControllerTargetLocation(handed, collisionChannel, ignoreActors, traceComplex, minHitDistance) - performs line trace from controller and returns hit location
		example:
			local hitLocation = controllers.getControllerTargetLocation(0, 0, {}, false, 10)

	controllers.setLogLevel(val) - sets the logging level for controller debug output
		example:
			controllers.setLogLevel(LogLevel.Info)

]]--

local uevrUtils = require("libs/uevr_utils")

local M = {}

local sourceNames = {[0]="Left",[1]="Right"}
local actors = {}

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[controllers] " .. text, logLevel)
	end
end

local function getCachedController(controllerID)
	local actor = actors[controllerID]
	if actor ~= nil and UEVR_UObjectHook.exists(actor) then
		local components = actor.BlueprintCreatedComponents
		if components ~= nil then
			for index, component in pairs(components) do
				if component ~= nil then
					return component	
				end
			end
		end
	end
	return nil
end 


local function destroyActor(actor)
	if actor ~= nil then
		pcall(function()
			local components = actor.BlueprintCreatedComponents
			for index, component in pairs(components) do
				if component ~= nil then
					M.print("Destroying controller component " .. component:get_full_name()) 
					pcall(function()
						if actor.K2_DestroyComponent ~= nil then
							actor:K2_DestroyComponent(component)
							M.print("HMD Controller component destroyed")
						end
					end)	
				end
			end
			if actor.K2_DestroyActor ~= nil then
				actor:K2_DestroyActor()
				M.print("HMD Controller actor destroyed")
			end
		end)	
	end
end

local function createControllerComponent(parentActor, sourceName, handIndex)	
	-- CORREÇÃO: Validação dos parâmetros antes de concatenar
	local sourceNameStr = sourceName or "Unknown"
	local handIndexStr = handIndex ~= nil and tostring(handIndex) or "Unknown"
	
	M.print("Creating controller " .. sourceNameStr .. " " .. handIndexStr)
	
	if not parentActor then
		M.print("ERROR: parentActor is nil, cannot create controller component", LogLevel.Error)
		return nil
	end
	
	local motionControllerComponent = uevrUtils.create_component_of_class(
		"Class /Script/HeadMountedDisplay.MotionControllerComponent", 
		true, 
		uevrUtils.get_transform(), 
		false, 
		parentActor
	)
	
	if motionControllerComponent ~= nil then
		motionControllerComponent:SetCollisionEnabled(0, false)	
		
		if sourceName then
			motionControllerComponent.MotionSource = uevrUtils.fname_from_string(sourceName)
		end
		
		if motionControllerComponent.Hand ~= nil and handIndex ~= nil then
			motionControllerComponent.Hand = handIndex
		end
		
		M.print("Controller created successfully")
		return motionControllerComponent
	else
		M.print("Failed to create motion controller component", LogLevel.Error)
	end
	
	return nil
end

local function createHMDControllerComponent()	
	M.print("Creating HMD controller")
	local hmdIndex = 2
	local parentActor = uevrUtils.spawn_actor(uevrUtils.get_transform(), 1, nil)
	if parentActor ~= nil then
		M.print("Created HMD controller actor " .. parentActor:get_full_name())
		local motionControllerComponent = uevrUtils.create_component_of_class("Class /Script/Engine.SceneComponent", true, uevrUtils.get_transform(), false, parentActor)
		if motionControllerComponent ~= nil then
			local hmdState = UEVR_UObjectHook.get_or_add_motion_controller_state(motionControllerComponent)	
			if hmdState ~= nil then
				hmdState:set_hand(hmdIndex) 
				hmdState:set_permanent(true)
				actors[hmdIndex] = parentActor
				M.print("HMD Controller created successfully")
				return motionControllerComponent
			else
				M.print("HMD Controller state creation failed", LogLevel.Warning)
			end	
		else
			M.print("HMD Controller component creation failed", LogLevel.Warning)
		end
	else
		M.print("HMD Controller actor creation failed", LogLevel.Warning)
	end
	destroyActor(parentActor)
	return nil
end

local function createActor(controllerID)
	local actor = uevrUtils.spawn_actor(uevrUtils.get_transform(), 1, nil)
	if actor then
		actors[controllerID] = actor
		M.print("Created actor for controller " .. tostring(controllerID))
	else
		M.print("Failed to create actor for controller " .. tostring(controllerID), LogLevel.Error)
	end
	return actor
end

local function resetMotionControllers()
	M.print("Removing all motion controller states")
	if UEVR_UObjectHook.remove_all_motion_controller_states ~= nil then
		UEVR_UObjectHook.remove_all_motion_controller_states()
	end
end

function M.onLevelChange()
	resetMotionControllers()
    M.resetControllers()
end

function M.getHMDController()
	return getCachedController(2)
end


function M.getController(controllerID, useCached)
	if useCached == true then
		return getCachedController(controllerID)
	else
		if controllerID == 2 then
			return M.getHMDController()
		else
			M.print("Getting controller without cache")
			local controllers = uevrUtils.find_all_of("Class /Script/HeadMountedDisplay.MotionControllerComponent", false)
			if controllers ~= nil then
				for index, controller in pairs(controllers) do
					if controller.Hand ~= nil then
						if controller.Hand == controllerID then 
							return controller 
						end
					else
						if controller.MotionSource:to_string() == sourceNames[controllerID] then 
							return controller 
						end
					end
				end
			end
		end
	end

	return nil
end

--called after a script restart
function M.restoreExistingComponents()
	for i = 0, 1 do
		if getCachedController(i) == nil then
			local controller = M.getController(i)
			if controller ~= nil then
				print("Restoring existing controller " .. i .. ": " .. controller:get_full_name() .. " " .. controller:GetOwner():get_full_name())
				actors[i] = controller:GetOwner()
			end
		end
	end
end

function M.hmdControllerExists()
	return M.getHMDController() ~= nil
end

function M.controllerExists(controllerID, useCached)
	if useCached == nil then useCached = true end
	local controller = M.getController(controllerID, useCached)
	return controller ~= nil
end

function M.createHMDController()
	local controller = nil
	if not M.hmdControllerExists() then
		controller = createHMDControllerComponent()
	end
	return controller
end

function M.createController(controllerID)
	M.print("Creating controller " ..  tostring(controllerID))
	
	if controllerID == 2 then
		return M.createHMDController()
	else
		local controller = nil
		if not M.controllerExists(controllerID, true) then
			if not M.controllerExists(controllerID, false) then
				local parentActor = createActor(controllerID)
				if parentActor then
					controller = createControllerComponent(parentActor, sourceNames[controllerID], controllerID)
				else
					M.print("Failed to create controller " .. tostring(controllerID) .. " because actor creation failed", LogLevel.Error)
				end
			else
				M.restoreExistingComponents()
			end
		end
		return controller
	end
end

function M.destroyController(controllerID)
	destroyActor(actors[controllerID])
	actors[controllerID] = nil
end

function M.destroyControllers()
	M.destroyController(0)
	M.destroyController(1)
	M.destroyController(2)
	M.resetControllers()
end

function M.resetControllers()
	actors[0] = nil
	actors[1] = nil
	actors[2] = nil
	actors = {}
end

--controllerID 0-left, 1-right, 2-head
function M.attachComponentToController(controllerID, childComponent, socketName, attachType, weld, createIfNotExists)
	if socketName == nil then socketName = "" end
	if attachType == nil then attachType = 0 end
	if weld == nil then weld = false end
	if childComponent ~= nil then
		M.print("Attaching component " .. childComponent:get_full_name() .. " to controller " .. tostring(controllerID))
		local controller = M.getController(controllerID)
		if controller == nil and createIfNotExists == true then
			controller = M.createController(controllerID)
		end
		if controller ~= nil then
			return childComponent:K2_AttachTo(controller, uevrUtils.fname_from_string(socketName), attachType, weld)
		else
			M.print("Could not attach component to controller " .. tostring(controllerID) .. " because controller is nil")
		end
	else
		M.print("Could not attach component to controller " .. tostring(controllerID) .. "  because childComponent is nil")
	end
	return false
end

-- returns an FVector or nil
function M.getControllerLocation(controllerID)
	local controller = M.getController(controllerID, true)
	if controller ~= nil then
		return controller:K2_GetComponentLocation()
	end
	return nil
end

function M.getControllerRotation(controllerID)
	local controller = M.getController(controllerID, true)
	if controller ~= nil then
		return controller:K2_GetComponentRotation()
	end
	return nil
end

function M.getControllerDirection(controllerID)
	local controller = M.getController(controllerID, true)
	if controller ~= nil then
		return kismet_math_library:GetForwardVector(M.getControllerRotation(controllerID))
	end
	return nil
end

function M.getControllerUpVector(controllerID)
	local controller = M.getController(controllerID, true)
	if controller ~= nil then
		return kismet_math_library:GetUpVector(M.getControllerRotation(controllerID))
	end
	return nil
end

function M.getControllerRightVector(controllerID)
	local controller = M.getController(controllerID, true)
	if controller ~= nil then
		return kismet_math_library:GetRightVector(M.getControllerRotation(controllerID))
	end
	return nil
end

function M.getControllerTargetLocation(handed, collisionChannel, ignoreActors, traceComplex, minHitDistance)
	if not M.controllerExists(handed) then
		M.createController(handed)
	end
	local direction = M.getControllerDirection(handed)
	if direction ~= nil then
		local startLocation = M.getControllerLocation(handed)
		if startLocation ~= nil then
			return uevrUtils.getTargetLocation(startLocation, direction, collisionChannel, ignoreActors, traceComplex, minHitDistance)
		else
			M.print("Error in getControllerTargetLocation. Controller location was nil")
		end
	else
		M.print("Error in getControllerTargetLocation. Controller direction was nil")
	end
	return nil
end

local isRestored = false
uevrUtils.registerPreLevelChangeCallback(function(level)
	M.print("Pre-Level changed in controllers")
	M.onLevelChange()
	if not isRestored then
		M.restoreExistingComponents()
		isRestored = true
	end
end)

uevrUtils.registerLevelChangeCallback(function(level)
	M.createController(0)
	M.createController(1)
	M.createController(2)
end)


return M