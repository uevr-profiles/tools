local api = uevr.api
local vr = uevr.params.vr
local params = uevr.params
local callbacks = params.sdk.callbacks

local uevrUtils = require('libs/uevr_utils')
local configui = require('libs/configui')
local hands = require('libs/hands')
local controllers = require('libs/controllers')

local hand = Handed.Right
local activeHand = hand

local activeWeapon = nil
local activeWeaponWeapon = nil

local activeWeaponOriginalParent = nil
local activeWeaponOriginalParentSocket = nil
local activeWeaponOriginalRelativeRotation= {}
local activeWeaponOriginalRelativeLocation= {}


local runToggled = false

local fixedCameras3rdPersonMode = false
local fixedCameras3rdPersonModeJustChanged = false

local lastFixedCamera = nil

local hitresult_c = uevrUtils.find_required_object("ScriptStruct /Script/Engine.HitResult")
local empty_hitresult = StructObject.new(hitresult_c)

local kismet_system_library = uevrUtils.find_default_instance("Class /Script/Engine.KismetSystemLibrary")
local reusable_hit_result = uevrUtils.get_reuseable_struct_object("ScriptStruct /Script/Engine.HitResult")
local zero_color = uevrUtils.get_reuseable_struct_object("ScriptStruct /Script/CoreUObject.LinearColor")

local currentCameraSpringArm = nil
local currentCameraSpringArm1 = nil
local currentCameraSpringArmTargetArmLength = nil
local originalCameraSpringArmBInheritPitch = true
local originalCameraSpringArmBInheritRoll = true
local originalCameraSpringArmBInheritYaw = true


local needToFixCamera = false

local needToFixSpringArmRotation = false

local onBulletTraceHooked = false
local fireSingleMuzzleHooked = false
local laserLength = 1000

local curentProjectile
local inRegularPlay = false

local onSecurityLockConstructHooked = false
local currentSecurityLock = nil
local postLock3rdPersonTime = 0.2
local postLock3rdPersonCurrTimer = 0.0

local configDefinition = {
	{
		panelLabel = "Ruiner VR", 
		saveFile = "user_configuration", 
		layout = {
			{
				widgetType = "text",
				label = "=== Gameplay ===",
			},
			{
				widgetType = "checkbox",
				id = "show_laser",
				label = "Show laser",
				initialValue = true
			},
			{
				widgetType = "text",
				label = "=== Enhanced Movement ===",
			},
			{
				widgetType = "slider_int",
				id = "walk_speed",
				label = "Walk Speed",
				initialValue = 750,
				range = {"300", "2000"}
			},
			{
				widgetType = "slider_float",
				id = "turn_speed",
				label = "Turn Speed",
				initialValue = 0.10,
				range = {"0.01", "0.5"}
			}
		}
	}
}

configui.create(configDefinition)

function on_level_change(level)
	findCurrentCameraSpringArms()
	initHands()
end

function initHands()
	--[[controllers.createController(0)
	controllers.createController(1)
	hands.reset()

	local paramsFile = 'hands_parameters' -- found in the [game profile]/data directory
	local configName = 'Main' -- the name you gave your config
	local animationName = 'Shared' -- the name you gave your animation
	hands.createFromConfig(paramsFile, configName, animationName)]]
end

function on_xinput_get_state(retval, user_index, state)
	if hands.exists() then
		local isHoldingWeapon = activeWeapon ~= nil
		hands.handleInput(state, isHoldingWeapon, hand)
	end
end

uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
	if normalPlay == true then	
		fixCamera()
		local currentWeapon = getCurrentWeaponMesh()
		updateEquippedWeapon(currentWeapon , hand)	
	end
	if inRegularPlay == true and isRegularPlay() == true then		
		pcall(fixCurrentProjectile)
		fixProjectiles()
	end
end)

function getCurrentWeaponMesh()
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil and pawn.EquippedWeapon ~= nil and pawn.EquippedWeapon.Mesh ~= nil and not string.find(pawn.EquippedWeapon.Mesh:get_full_name(), "Player_Pipe_C") and  not string.find(pawn.EquippedWeapon.Mesh:get_full_name(), "Katana_C") then
		activeWeaponWeapon = pawn.EquippedWeapon
		return activeWeaponWeapon.Mesh
	end
	return nil
end

function updateEquippedWeapon(currentWeapon, hand)
	if hand == nil then hand = Handed.Right end
	local lastWeapon = activeWeapon
	pcall(disconnectPreviousWeapon, currentWeapon, hand)
	
	if currentWeapon ~= nil and activeWeapon ~= currentWeapon then
		backupEquippedWeaponAttachmentSettings(currentWeapon)
		print("Connecting weapon ".. currentWeapon:get_full_name() .. " " .. currentWeapon:get_fname():to_string() .. " to hand " .. hand)
		local state = UEVR_UObjectHook.get_or_add_motion_controller_state(currentWeapon)
		state:set_hand(hand)
		state:set_permanent(true)
		
		if string.find(currentWeapon:get_full_name(), "Player_Pipe_C") then
			state:set_rotation_offset(Vector3f.new(0.180, 1.447, -0.105))
			state:set_location_offset(Vector3f.new(-0.498, -4.480, -5.368)) --1st prop - more is down for some reason		
		elseif string.find(currentWeapon:get_full_name(), "ruiner_gun_C") then
			state:set_rotation_offset(Vector3f.new(1.360, 1.367, 3.008))
			state:set_location_offset(Vector3f.new(8, -4.480, -5.368)) --1st prop - more is down for some reason	
		elseif string.find(currentWeapon:get_full_name(), "SHOTGUN") then
			state:set_rotation_offset(Vector3f.new(1.360, 1.367, 3.008))
			state:set_location_offset(Vector3f.new(14, -4.480, -5.368)) --1st prop - more is down for some reason
		elseif string.find(currentWeapon:get_full_name(), "PLASMA_C") then
			state:set_rotation_offset(Vector3f.new(1.360, 1.367, 3.008))
			state:set_location_offset(Vector3f.new(14, -4.480, -5.368)) --1st prop - more is down for some reason
		elseif string.find(currentWeapon:get_full_name(), "PISTOL_PAE") then
			state:set_rotation_offset(Vector3f.new(1.360, 1.367, 3.008))
			state:set_location_offset(Vector3f.new(-0.498, -4.480, -5.368)) --1st prop - more is down for some reason	
		elseif string.find(currentWeapon:get_full_name(), "KRISS") then
			state:set_rotation_offset(Vector3f.new(1.360, 1.367, 3.008))
			state:set_location_offset(Vector3f.new(4, -4.480, -5.368)) --1st prop - more is down for some reason
		elseif string.find(currentWeapon:get_full_name(), "P90") then
			state:set_rotation_offset(Vector3f.new(1.360, 1.367, 3.008))
			state:set_location_offset(Vector3f.new(1, -4.480, -5.368)) --1st prop - more is down for some reason	
		else
			state:set_rotation_offset(Vector3f.new(1.360, 1.367, 3.008))
			state:set_location_offset(Vector3f.new(14, -4.480, -5.368)) --1st prop - more is down for some reason
		end
	end
	
	activeHand = hand
	activeWeapon = currentWeapon
	
end

function backupEquippedWeaponAttachmentSettings(weaponMesh)
	if weaponMesh ~= nil then
		activeWeaponOriginalParent = weaponMesh:GetAttachParent()
		activeWeaponOriginalParentSocket = weaponMesh:GetAttachSocketName()
		activeWeaponOriginalRelativeLocation.X = weaponMesh.RelativeLocation.X
		activeWeaponOriginalRelativeLocation.Y = weaponMesh.RelativeLocation.Y
		activeWeaponOriginalRelativeLocation.Z = weaponMesh.RelativeLocation.Z
		activeWeaponOriginalRelativeRotation.Yaw = weaponMesh.RelativeRotation.Yaw
		activeWeaponOriginalRelativeRotation.Roll = weaponMesh.RelativeRotation.Roll
		activeWeaponOriginalRelativeRotation.Pitch = weaponMesh.RelativeRotation.Pitch

	end
end

function restoreEquippedWeaponAttachmentSettings(weaponMesh)
	if weaponMesh ~= nil and activeWeaponOriginalParent ~= nil then
		weaponMesh:K2_AttachTo(activeWeaponOriginalParent, activeWeaponOriginalParentSocket ~= nil and activeWeaponOriginalParentSocket or "", 1, false)
		weaponMesh.RelativeLocation.X = activeWeaponOriginalRelativeLocation.X
		weaponMesh.RelativeLocation.Y = activeWeaponOriginalRelativeLocation.Y
		weaponMesh.RelativeLocation.Z = activeWeaponOriginalRelativeLocation.Z
		weaponMesh.RelativeRotation.Yaw = activeWeaponOriginalRelativeRotation.Yaw
		weaponMesh.RelativeRotation.Roll = activeWeaponOriginalRelativeRotation.Roll
		weaponMesh.RelativeRotation.Pitch = activeWeaponOriginalRelativeRotation.Pitch
	end
end

function disconnectPreviousWeapon(currentWeapon, hand) 
	if hand ~= activeHand or (activeWeapon ~= nil and currentWeapon ~= nil and activeWeapon ~= currentWeapon) then
		--Disconnecting current weapon
		print("diconnecting weapon ".. activeWeapon:get_full_name() .. " " .. activeWeapon:get_fname():to_string())
		local state = UEVR_UObjectHook.get_or_add_motion_controller_state(currentWeapon)
		UEVR_UObjectHook.remove_motion_controller_state(activeWeapon)
	end
end

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	--hookFuntionsForRuntimeGeneratedClasses()
	inRegularPlay = false
	if isMainMenu() then
		applyMainMenuSettings()
	elseif fixedCameras3rdPersonMode == true or isShouldChangeTo3rdPerson(delta) then
		--print("apply 3rd")
		applyFixedCameras3rdPersonModeSettings()
	elseif isShouldApplySecurityLockYeetFix(delta) then
		revertDirection()
		applyFixedCameras3rdPersonModeSettings()
	elseif isInCutScene() then
		applyCinematicSettings()
	else --regular play	
		inRegularPlay = true
		if not hands.exists() then
			initHands()
		end
		applyNormalModeSettings(delta)
	end	
end)


function hookFuntionsForRuntimeGeneratedClasses() 
	if onBulletTraceHooked == false then
		hook_function("BlueprintGeneratedClass /Game/Blueprints/Player/RuinerController.RuinerController_C", "SetControlRotation", false,
			function(fn, obj, locals, result)
				
				print("GetControlRotation started")
			end,
			function(fn, obj, locals, result)
				print("GetControlRotation ended")
				
			end,
		true)
		
		onBulletTraceHooked = true
	end
	
	--[[if onSecurityLockConstructHooked == false then
		hook_function("WidgetBlueprintGeneratedClass /Game/Blueprints/HUD/Widgets/WorldInteractions/SecurityLock.SecurityLock_C", "Construct", false,
			function(fn, obj, locals, result)
				print("Construct started")
				currentSecurityLock = obj
			end,
			nil,
		true)
		
		onSecurityLockConstructHooked = true
	end]]
end



function calculateBulletTraceEndPoint(activeWeapon)
		local endPoint
	 if activeWeapon ~= nil and activeWeapon.GetForwardVector then
        local forwardVector = activeWeapon:GetForwardVector()
        if forwardVector ~= nil then
			endPoint = Vector3f.new(
            forwardVector.X * 8192.0,
            forwardVector.Y * 8192.0,
            forwardVector.Z * 8192.0)
        end
    end
	return endPoint
    --[[local controllerLocation = controllers.getControllerLocation(1)
	local controllerRotation = controllers.getControllerRotation(1)
    
	local forwardX, forwardY, forwardZ
        
	local pitch = (controllerRotation.Pitch) * math.pi / 180
	local yaw = (controllerRotation.Yaw) * math.pi / 180
	local roll = (controllerRotation.Roll) * math.pi / 180
	
	-- Calculate forward vector from Euler angles
	forwardX = math.cos(yaw) * math.cos(pitch)
	forwardY = math.sin(yaw) * math.cos(pitch)
	forwardZ = math.sin(pitch)

    local forwardVector = Vector3f.new(forwardX or 0, forwardY or 0, forwardZ or 0)
    
    -- Calculate end point: Location + (Forward * Range)
    local endPoint = Vector3f.new(
        controllerLocation.X + (forwardVector.X * laserLength),
        controllerLocation.Y + (forwardVector.Y * laserLength),
        controllerLocation.Z + (forwardVector.Z * laserLength)
    )
    
    return endPoint]]
end

function isMainMenu()
	local pawn = api:get_local_pawn(0)
	return pawn == nil	
end

function isInCutScene()
	local player = api:get_player_controller(0)
	if player ~= nil then 
        if player.PlayerCameraManager ~= nil and player.PlayerCameraManager.ViewTarget ~= nil and player.PlayerCameraManager.ViewTarget.Target ~= nil then                    
			if string.find(player.PlayerCameraManager.ViewTarget.Target:get_full_name(), "FocusCameraEvent_C") then
				return true
			end
		end
	end
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		return not pawn:IsControlled() and not pawn:IsPlayerControlled() and not pawn:IsLocallyControlled()
	end
	return false
end

function isShouldApplySecurityLockYeetFix(delta)
	--bypass bug where player is yeeted off when faiing a security lock QTE - just do it in 3rd person...
	if currentSecurityLock ~= nil and ((currentSecurityLock.StartTimer == false and currentSecurityLock.startTimer == nil) or (currentSecurityLock.startTimer == false and currentSecurityLock.StartTimer  == nil)) then -- timer just ended
		print("bypassing yeet bug")
		postLock3rdPersonCurrTimer = postLock3rdPersonTime 
		currentSecurityLock = nil
		return true
	end
	if postLock3rdPersonCurrTimer > 0.0 then
		postLock3rdPersonCurrTimer = postLock3rdPersonCurrTimer - delta
		if postLock3rdPersonCurrTimer < 0.0 then postLock3rdPersonCurrTimer = 0.0 end
		print("bypassing yeet bug due to timer")
		return true
	end
	
	currentSecurityLock = nil
	local allLocks = uevrUtils.find_all_instances("WidgetBlueprintGeneratedClass /Game/Blueprints/HUD/Widgets/WorldInteractions/SecurityLock.SecurityLock_C", false)
	if allLocks ~= nil then
		for _, lock in pairs(allLocks) do
			if lock.StartTimer == true or lock.startTimer == true then
				currentSecurityLock = lock
				print("current lock detected")
				return true
			end
		end
	end
end

function isShouldChangeTo3rdPerson(delta)
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		if pawn.IsPlayerDead then 
			return true
		end
		--print("pawn.PauseMenuWidget:IsInteractable()", pawn.PauseMenuWidget:IsVisible())
		if pawn.CanUseGadgets == false and pawn.CanUseCombatGadgets == false and pawn.CanLeaveCombat == true and pawn.CanToggleMoveType == false then -- pause? maybe?
			--print("paused")
			return true
		end
		
		--[[	
		--bypass bug where player is yeeted off when faiing a security lock QTE - just do it in 3rd person...
		if currentSecurityLock ~= nil and ((currentSecurityLock.StartTimer == false and currentSecurityLock.startTimer == nil) or (currentSecurityLock.startTimer == false and currentSecurityLock.StartTimer  == nil)) then -- timer just ended
			print("bypassing yeet bug")
			postLock3rdPersonCurrTimer = postLock3rdPersonTime 
			currentSecurityLock = nil
			return true
		end
		if postLock3rdPersonCurrTimer > 0.0 then
			postLock3rdPersonCurrTimer = postLock3rdPersonCurrTimer - delta
			if postLock3rdPersonCurrTimer < 0.0 then postLock3rdPersonCurrTimer = 0.0 end
			print("bypassing yeet bug due to timer")
			return true
		end
		
		currentSecurityLock = nil
		local allLocks = uevrUtils.find_all_instances("WidgetBlueprintGeneratedClass /Game/Blueprints/HUD/Widgets/WorldInteractions/SecurityLock.SecurityLock_C", false)
		if allLocks ~= nil then
			for _, lock in pairs(allLocks) do
				if lock.StartTimer == true or lock.startTimer == true then
					currentSecurityLock = lock
					print("current lock detected")
					return true
				end
			end
		end]]
	end
	return false
end

function applyMainMenuSettings() 
	normalPlay = false

	vr.set_mod_value("VR_2DScreenMode", false)
	--vr.set_mod_value("UI_Distance", 2.0)

	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
				
	--vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	--vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	--vr.set_mod_value("VR_CameraUpOffset", "0.000000")				
	--vr.set_mod_value("VR_LerpCameraYaw", "false")

	
    vr.set_mod_value("VR_DecoupledPitchUIAdjust", "false")

	UEVR_UObjectHook.set_disabled(true)

	--hands.hideHands(true)
end


function applyCinematicSettings() 
	normalPlay = false
	vr.set_mod_value("VR_2DScreenMode", true)
	--vr.set_mod_value("UI_Distance", 2.0)

	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
				
	vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	vr.set_mod_value("VR_CameraUpOffset", "0.000000")				
	vr.set_mod_value("VR_LerpCameraYaw", "false")
	
    vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
	
	

	local pawn = api:get_local_pawn(0)
	if pawn ~= nil and pawn.Mesh ~= nil then
		pawn.Mesh:SetVisibility(true)
		pawn.Mesh:SetRenderInMainPass(true)
		pawn.Mesh:SetRenderCustomDepth(true)
	end
	
	
	UEVR_UObjectHook.set_disabled(true)
	
	--pcall(disconnectPreviousWeapon, currentWeapon, hand)
	--pcall(restoreEquippedWeaponAttachmentSettings, activeWeapon)
	--hands.hideHands(true)
end


function applyNormalModeSettings(delta) 
		
	vr.set_mod_value("VR_2DScreenMode", false)
	--vr.set_mod_value("UI_Distance", 2.0)


	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "1")
	vr.set_mod_value("VR_DecoupledPitch", "1")
	vr.set_mod_value("VR_CameraForwardOffset", "0.0000000")
	vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	vr.set_mod_value("VR_CameraUpOffset", "0.000000")				
	vr.set_mod_value("VR_LerpCameraYaw", "false")

	
    vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
	UEVR_UObjectHook.set_disabled(false)
	
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil and pawn.Mesh ~= nil then
		pawn.Mesh:SetVisibility(true)
		pawn.Mesh:SetRenderInMainPass(false)
		pawn.Mesh:SetRenderCustomDepth(false)
	end
	--hide laser
	if pawn ~= nil and pawn.LaserPointer ~= nil then
		pawn.LaserPointer:SetRenderInMainPass(false)
		pawn.LaserPointer:SetRenderCustomDepth(false)
	end
	
	normalPlay = isRegularPlay()
	if normalPlay == true then
		if pawn ~= nil and pawn.CharacterMovement ~= nil then       
			pawn.CharacterMovement.bUseControllerDesiredRotation = false
			--pawn.bUseWeaponRotation = true
		end
	end
	pcall(toogleActiveWeaponVisibility, true)
	--findCurrentCameraSpringArms()
	pcall(fixDirection)
	--hands.hideHands(false)
end

function applyFixedCameras3rdPersonModeSettings()
	normalPlay = false
	
	--vr.set_mod_value("VR_2DScreenMode", true)
	--vr.set_mod_value("UI_Distance", 3.320)

	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
				
	--vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	--vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	--vr.set_mod_value("VR_CameraUpOffset", "0.000000")
	--vr.set_mod_value("VR_CameraRightOffset", "-10.000000")
	--vr.set_mod_value("VR_CameraUpOffset", "13.000000")				
	--vr.set_mod_value("VR_LerpCameraYaw", "false")

    vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
	

	local pawn = api:get_local_pawn(0)
	if pawn ~= nil and pawn.Mesh ~= nil then
		pawn.Mesh:SetVisibility(true)
		pawn.Mesh:SetRenderInMainPass(true)
		pawn.Mesh:SetRenderCustomDepth(true)
	end
	
	if pawn ~= nil and pawn.CharacterMovement ~= nil then       
		pawn.CharacterMovement.bUseControllerDesiredRotation = true
		--pawn.bUseWeaponRotation = false
	end

	pcall(disconnectPreviousWeapon, activeWeapon, hand)
	UEVR_UObjectHook.set_disabled(true)
	pcall(restoreEquippedWeaponAttachmentSettings, activeWeapon)
	--hands.hideHands(true)
	
	if fixedCameras3rdPersonModeJustChanged and fixedCameras3rdPersonMode == true then --manual switch
		applyLastFixedCamera()
		revertDirection()
	else -- auto switch
		local player = api:get_player_controller(0)
		if player ~= nil then       
			if player.PlayerCameraManager ~= nil and player.PlayerCameraManager.ViewTarget ~= nil and player.PlayerCameraManager.ViewTarget.Target ~= nil and player.PlayerCameraManager.ViewTarget.Target == pawn then
				applyLastFixedCamera()
			end
		end
	end
end

function isRegularPlay()
	return true
end

--Shooting fix attempts section start


function fixProjectiles()
	local allProjectiles = uevrUtils.find_all_instances("Class /Script/Ruiner.Projectile", true)
	if allProjectiles ~= nil then
		for _, projectile in pairs(allProjectiles) do
			local pawn = api:get_local_pawn(0)
			if pawn ~= nil and projectile.Owner == pawn.EquippedWeapon and projectile.Spawned == true then
				--print("projectile.Spawned", projectile:get_full_name())
				local targetLocation = pawn.EquippedWeapon:GetMuzzleDirection()
				--local targetLocation = pawn.EquippedWeapon.Mesh:GetForwardVector()

				projectile.ProjectileMovement.Velocity.X = targetLocation.X * projectile.ProjectileMovement.InitialSpeed *2000
				projectile.ProjectileMovement.Velocity.Y = targetLocation.Y * projectile.ProjectileMovement.InitialSpeed *2000
				projectile.ProjectileMovement.Velocity.Z = targetLocation.Z * projectile.ProjectileMovement.InitialSpeed *2000
				--[[if projectile.RootComponent ~= nil and projectile.RootComponent.RelativeRotation ~= nil then
					projectile.RootComponent.RelativeRotation.Yaw = pawn.EquippedWeapon.Mesh.RelativeRotation.Yaw
					projectile.RootComponent.RelativeRotation.Pitch = pawn.EquippedWeapon.Mesh.RelativeRotation.Pitch
					projectile.RootComponent.RelativeRotation.Roll = pawn.EquippedWeapon.Mesh.RelativeRotation.Roll
				end]]
				break
			end
			
		end
	end
end

function fixCurrentProjectile()
	if curentProjectile ~= nil and curentProjectile.ProjectileMovement ~= nil then
		local pawn = api:get_local_pawn(0)
		local targetLocation = pawn.EquippedWeapon:GetMuzzleDirection()
		curentProjectile.ProjectileMovement.Velocity.X = targetLocation.X * curentProjectile.ProjectileMovement.InitialSpeed*2000
		curentProjectile.ProjectileMovement.Velocity.Y = targetLocation.Y * curentProjectile.ProjectileMovement.InitialSpeed*2000
		curentProjectile.ProjectileMovement.Velocity.Z = targetLocation.Z * curentProjectile.ProjectileMovement.InitialSpeed*2000
	end
	--local pawn = api:get_local_pawn(0)
	--if pawn.EquippedWeapon ~= nil and pawn.EquippedWeapon.ExtenderComponent ~= nil and pawn.EquippedWeapon.ExtenderComponent.MuzzelLight ~= nil then
	--	pawn.EquippedWeapon.ExtenderComponent.MuzzelLight:SetRenderCustomDepth(false)
	--	pawn.EquippedWeapon.ExtenderComponent.MuzzelLight:SetRenderCustomDepth(false)
	--end
end

hook_function("Class /Script/Engine.MovementComponent", "PhysicsVolumeChanged", false,
	function(fn, obj, locals, result)
		--print("PhysicsVolumeChanged started", obj:GetOwner():get_full_name())
		local projectile = obj:GetOwner()
		local pawn = api:get_local_pawn(0)
		if pawn ~= nil and projectile.Owner == pawn.EquippedWeapon then --and projectile.Spawned == true then
			--print("projectile.Spawned", projectile:get_full_name())
			curentProjectile = projectile
			--local targetLocation = pawn.EquippedWeapon:GetMuzzleDirection()
			--projectile.ProjectileMovement.Velocity.X = targetLocation.X * projectile.ProjectileMovement.InitialSpeed
			--projectile.ProjectileMovement.Velocity.Y = targetLocation.Y * projectile.ProjectileMovement.InitialSpeed
			--projectile.ProjectileMovement.Velocity.Z = targetLocation.Z * projectile.ProjectileMovement.InitialSpeed
		end
	end, 
	nil,
	--[[function(fn, obj, locals, result)
		print("PhysicsVolumeChanged ended", obj:GetOwner():get_full_name())
		local projectile = obj:GetOwner()		
		if projectile.Owner == pawn.EquippedWeapon then --and projectile.Spawned == true then
			print("projectile.Spawned", projectile:get_full_name())
			curentProjectile = projectile
			--local targetLocation = pawn.EquippedWeapon:GetMuzzleDirection()
			--projectile.ProjectileMovement.Velocity.X = targetLocation.X * projectile.ProjectileMovement.InitialSpeed
			--projectile.ProjectileMovement.Velocity.Y = targetLocation.Y * projectile.ProjectileMovement.InitialSpeed
			--projectile.ProjectileMovement.Velocity.Z = targetLocation.Z * projectile.ProjectileMovement.InitialSpeed
		end
	end,]]
true)




--[[hook_function("Class /Script/Engine.MovementComponent", "ReceiveBeginPlay", false,
	function(fn, obj, locals, result)
		--if obj.Owner == pawn.EquippedWeapon then
			print("ReceiveBeginPlay started")
		--end
	end, 
	function(fn, obj, locals, result)
		--print("EVENT_OnPoolBeginPlay ended")
		--if obj.Owner == pawn.EquippedWeapon then
			print("ReceiveBeginPlay ended")
		--end
	end,
true)]]


--[[hook_function("Class /Script/Ruiner.Projectile", "EVENT_OnPoolBeginPlay", true,
	function(fn, obj, locals, result)
		if obj.Owner == pawn.EquippedWeapon then
			print("EVENT_OnPoolBeginPlay started")
		end
	end, 
	function(fn, obj, locals, result)
		--print("EVENT_OnPoolBeginPlay ended")
		if obj.Owner == pawn.EquippedWeapon then
			print("EVENT_OnPoolBeginPlay ended")
		end
	end,
true)]]

function fixShooting()
	local pawn = api:get_local_pawn(0)
	if activeWeapon ~= nil and pawn ~= nil and pawn.AimLowPoint ~= nil then
		controllers.attachComponentToController(1, pawn.AimLowPoint, "", 0, true, false )
		pawn.AimLowPoint.RelativeLocation.Z = 0
		pawn.AimLowPoint.RelativeRotation = controllers.getController(1).RelativeRotation
		if activeWeaponWeapon ~= nil then
			local controllerRotation = controllers.getControllerRotation(1)
			
				--activeWeaponWeapon.AimTransform.Rotation.W = controllerRotation.W
				--activeWeaponWeapon.AimTransform.Rotation.X = controllerRotation.X
				--activeWeaponWeapon.AimTransform.Rotation.Y = controllerRotation.Y
				--activeWeaponWeapon.AimTransform.Rotation.Z = controllerRotation.Z

			--activeWeaponWeapon.FirePoint.RelativeRotation = controllers.getController(1).RelativeRotation
			activeWeaponWeapon.DesiredLaserRotation = controllers.getController(1).RelativeRotation
			activeWeaponWeapon.LaserSightPoint.RelativeRotation = controllers.getController(1).RelativeRotation

		end
		--pawn.AimLowPoint.RelativeLocation = controllers.getController(1).RelativeLocation

		--pawn.AimLowPoint:K2_SetWorldLocation(controllers.getController(1):K2_GetComponentLocation(), false, empty_hitresult, false)
		--pawn.AimLowPoint:K2_SetWorldRotation(controllers.getController(1):K2_GetComponentRotation(), false, empty_hitresult, false)

		--pawn.AimLowPoint:K2_AttachTo(activeWeapon, "Barrel", 0, false)
		--pawn.AimLowPoint:K2_SetRelativeRotation(activeWeapon:GetSocketRotation("Barrel"), false, empty_hitresult, false)
		--pawn.AimLowPoint:K2_SetRelativeLocation(activeWeapon:GetSocketLocation("Barrel"), false, empty_hitresult, false)
		--pawn.AimLowPoint:K2_SetRelativeLocation(controllers.getControllerLocation(1), false, empty_hitresult, false)
		--pawn.AimLowPoint:K2_SetWorldLocation(controllers.getControllerLocation(1), false, empty_hitresult, false)

		--pawn.AimLowPoint.RelativeRotation = controllers.getController(1).RelativeRotation

		--pawn.AimLowPoint.RelativeLocation.Y = controllers.getControllerLocation(1).Y

		--pawn.AimLowPoint:K2_SetWorldRotation(controllers.getControllerRotation(1), false, empty_hitresult, false)

	end
	if activeWeapon ~= nil and pawn ~= nil and pawn.AimHighPoint ~= nil then
		controllers.attachComponentToController(1, pawn.AimHighPoint, "", 0, true, false )
		pawn.AimHighPoint.RelativeLocation.Z = 0
		--controllers.attachComponentToController(1, pawn.AimHighPoint, "Barrel", 0, false, false )
		--pawn.AimHighPoint:K2_AttachTo(activeWeapon, "Barrel", 0, false)
		--pawn.AimHighPoint:K2_SetRelativeRotation(activeWeapon:GetSocketRotation("Barrel"), false, empty_hitresult, false)
		--pawn.AimHighPoint:K2_SetRelativeLocation(activeWeapon:GetSocketLocation("Barrel"), false, empty_hitresult, false)
	end
	
	--[[if activeWeaponWeapon ~= nil and activeWeaponWeapon.FirePoint ~=nil and activeWeaponWeapon.LaserSightPoint ~= nil then
		--print("fixing lasetr sight")
		activeWeaponWeapon.LaserSightPoint:K2_SetWorldLocation(activeWeaponWeapon.FirePoint:K2_GetComponentLocation(), false, empty_hitresult, false)
		activeWeaponWeapon.LaserSightPoint:K2_SetWorldRotation(activeWeaponWeapon.FirePoint:K2_GetComponentRotation(), false, empty_hitresult, false)
	end]]
	--[[if activeWeaponWeapon ~= nil and activeWeaponWeapon.WeaponVFXComp ~= nil then
		controllers.attachComponentToController(1, activeWeaponWeapon.LaserSightPoint, "", 0, false, false )
		activeWeaponWeapon.LaserSightPoint.RelativeLocation = pawn.AimLowPoint.RelativeLocation
	end]]
end

--[[hook_function("Class /Script/Ruiner.Projectile", "ReceiveAnyDamage", false, --Determines where shots actually hit - not sure if need to hook it at all, seems like hooking CalculateLaserEndPoint will be enough, as shots seem to hit where laser ends...
	function(fn, obj, locals, result)
		if obj.Owner == pawn.EquippedWeapon then
			print("ReceiveActorBeginCursorOver started")
		end
	end, 
	function(fn, obj, locals, result)
		print("ReceiveActorBeginCursorOver ended")
		if obj.Owner == pawn.EquippedWeapon then
			print("EVENT_OnPoolBeginPlay ended")
		end
	end,
true)]]

--[[hook_function("Class /Script/OBJPool.PooledActor", "EVENT_OnPoolBeginPlay", true, --Determines where shots actually hit - not sure if need to hook it at all, seems like hooking CalculateLaserEndPoint will be enough, as shots seem to hit where laser ends...
	function(fn, obj, locals, result)
		if obj.Owner == pawn.EquippedWeapon then
			--print("EVENT_OnPoolBeginPlay started")
		end
	end, 
	function(fn, obj, locals, result)
		--print("EVENT_OnPoolBeginPlay ended")
		if obj.Owner == pawn.EquippedWeapon then
			print("EVENT_OnPoolBeginPlay ended")
		end
	end,
true)]]



hook_function("Class /Script/Ruiner.Weapon", "OnShootStart", false, --Determines where shots actually hit - not sure if need to hook it at all, seems like hooking CalculateLaserEndPoint will be enough, as shots seem to hit where laser ends...
	function(fn, obj, locals, result)
		print("OnWeaponFired started")

		if obj.Owner == pawn.EquippedWeapon then
			
			--[[--local world = uevrUtils.get_world()
			--if world == nil then
			--	return true -- No world, allow movement
			--end
			local targetLocation = calculateBulletTraceEndPoint(pawn.EquippedWeapon.Mesh)
			--kismet_system_library:LineTraceSingle(world, pawn.EquippedWeapon.Mesh:GetForwardVector(), targetLocation, 0, true, ignore_actors, 0, reusable_hit_result, true, zero_color, zero_color, 1.0)
			--locals.HitResult = reusable_hit_result
			print(obj.Spawned)
			print(obj:get_full_name())
			obj.ProjectileMovement.Velocity.X = targetLocation.X
			obj.ProjectileMovement.Velocity.Y = targetLocation.Y
			obj.ProjectileMovement.Velocity.Z = targetLocation.Z
			locals.HitResult.TraceEnd.X = targetLocation.X
			locals.HitResult.TraceEnd.Y = targetLocation.Y
			locals.HitResult.TraceEnd.Z = targetLocation.Z
			locals.HitResult.ImpactPoint.X = targetLocation.X
			locals.HitResult.ImpactPoint.Y = targetLocation.Y
			locals.HitResult.ImpactPoint.Z = targetLocation.Z]]
		end
	end,
	function(fn, obj, locals, result)
		print("OnWeaponFired ended")
		local pawn = api:get_local_pawn(0)
		local allProjectiles = uevrUtils.find_all_instances("Class /Script/Ruiner.Projectile", true)
		if allProjectiles ~= nil then
			for _, projectile in pairs(allProjectiles) do
				if projectile.Owner == pawn.EquippedWeapon and projectile.Spawned == true then
					print(projectile.Spawned)
					projectile.ProjectileMovement.Velocity.X = targetLocation.X
					projectile.ProjectileMovement.Velocity.Y = targetLocation.Y
					projectile.ProjectileMovement.Velocity.Z = targetLocation.Z
					break
				end
				
			end
		end
		--[[if obj.Owner == pawn.EquippedWeapon then
			local targetLocation = calculateBulletTraceEndPoint(pawn.EquippedWeapon.Mesh)
			--kismet_system_library:LineTraceSingle(world, pawn.EquippedWeapon.Mesh:GetForwardVector(), targetLocation, 0, true, ignore_actors, 0, reusable_hit_result, true, zero_color, zero_color, 1.0)
			--locals.HitResult = reusable_hit_result
			print(obj.Spawned)
			obj.ProjectileMovement.Velocity.X = targetLocation.X
			obj.ProjectileMovement.Velocity.Y = targetLocation.Y
			obj.ProjectileMovement.Velocity.Z = targetLocation.Z
			locals.HitResult.TraceEnd.X = targetLocation.X
			locals.HitResult.TraceEnd.Y = targetLocation.Y
			locals.HitResult.TraceEnd.Z = targetLocation.Z
			locals.HitResult.ImpactPoint.X = targetLocation.X
			locals.HitResult.ImpactPoint.Y = targetLocation.Y
			locals.HitResult.ImpactPoint.Z = targetLocation.Z
		end]]
		
	end,
true)

--[[hook_function("Class /Script/Ruiner.Projectile", "OnImpact", false, --Determines where shots actually hit - not sure if need to hook it at all, seems like hooking CalculateLaserEndPoint will be enough, as shots seem to hit where laser ends...
	function(fn, obj, locals, result)
		if obj.Owner == pawn.EquippedWeapon then
			--print("OnImpact started")
			--local world = uevrUtils.get_world()
			--if world == nil then
			--	return true -- No world, allow movement
			--end
			local targetLocation = calculateBulletTraceEndPoint(pawn.EquippedWeapon.Mesh)
			--kismet_system_library:LineTraceSingle(world, pawn.EquippedWeapon.Mesh:GetForwardVector(), targetLocation, 0, true, ignore_actors, 0, reusable_hit_result, true, zero_color, zero_color, 1.0)
			--locals.HitResult = reusable_hit_result
			print(obj.Spawned)
			print(obj:get_full_name())
			obj.ProjectileMovement.Velocity.X = targetLocation.X
			obj.ProjectileMovement.Velocity.Y = targetLocation.Y
			obj.ProjectileMovement.Velocity.Z = targetLocation.Z
			locals.HitResult.TraceEnd.X = targetLocation.X
			locals.HitResult.TraceEnd.Y = targetLocation.Y
			locals.HitResult.TraceEnd.Z = targetLocation.Z
			locals.HitResult.ImpactPoint.X = targetLocation.X
			locals.HitResult.ImpactPoint.Y = targetLocation.Y
			locals.HitResult.ImpactPoint.Z = targetLocation.Z
		end
	end,
	function(fn, obj, locals, result)
		--print("OnImpact ended")
		if obj.Owner == pawn.EquippedWeapon then
			local targetLocation = calculateBulletTraceEndPoint(pawn.EquippedWeapon.Mesh)
			--kismet_system_library:LineTraceSingle(world, pawn.EquippedWeapon.Mesh:GetForwardVector(), targetLocation, 0, true, ignore_actors, 0, reusable_hit_result, true, zero_color, zero_color, 1.0)
			--locals.HitResult = reusable_hit_result
			print(obj.Spawned)
			obj.ProjectileMovement.Velocity.X = targetLocation.X
			obj.ProjectileMovement.Velocity.Y = targetLocation.Y
			obj.ProjectileMovement.Velocity.Z = targetLocation.Z
			locals.HitResult.TraceEnd.X = targetLocation.X
			locals.HitResult.TraceEnd.Y = targetLocation.Y
			locals.HitResult.TraceEnd.Z = targetLocation.Z
			locals.HitResult.ImpactPoint.X = targetLocation.X
			locals.HitResult.ImpactPoint.Y = targetLocation.Y
			locals.HitResult.ImpactPoint.Z = targetLocation.Z
		end
		
	end,
true)]]

--[[hook_function("Class /Script/Ruiner.Projectile", "K2_SetActorRotation", false, --Determines where shots actually hit - not sure if need to hook it at all, seems like hooking CalculateLaserEndPoint will be enough, as shots seem to hit where laser ends...
	function(fn, obj, locals, result)
		if obj.Owner == pawn.EquippedWeapon then
			print("K2_SetActorRotation started")
			weaponRotation = pawn.EquippedWeapon.Mesh:K2_GetActorRotation()
			locals.NewRotation.Yaw = weaponRotation.Yaw
			locals.NewRotation.Roll = weaponRotation.Roll
			locals.NewRotation.Pitch = weaponRotation.Pitch
			return false
		end
	end,
	function(fn, obj, locals, result)
		--print("K2_SetActorRotation ended")
		if obj.Owner == pawn.EquippedWeapon then
			weaponRotation = pawn.EquippedWeapon.Mesh:K2_GetActorRotation()
			locals.NewRotation.Yaw = weaponRotation.Yaw
			locals.NewRotation.Roll = weaponRotation.Roll
			locals.NewRotation.Pitch = weaponRotation.Pitch
			return false
		end
		
	end,
true)]]



--Shooting fix attempts section end

--Pawn direction fix section start

function fixDirection()
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		local player = api:get_player_controller(0)
		if player ~= nil then       
			if player.PlayerCameraManager ~= nil and player.PlayerCameraManager.Owner ~= nil then
				--print("fixing direction", pawn:K2_GetActorRotation())
				player:ClientSetLocation(pawn:K2_GetActorLocation(), pawn:K2_GetActorRotation())

				--player.PlayerCameraManager.Owner:ClientSetRotation(pawn:K2_GetActorRotation())

			end
		end
		if currentCameraSpringArm ~= nil then
			--print("currentCameraSpringArm", currentCameraSpringArm:get_full_name())
			--currentCameraSpringArm:K2_SetRelativeRotation(pawn:K2_GetActorRotation(), false, empty_hitresult, false)
			currentCameraSpringArm.RelativeRotation = pawn:K2_GetActorRotation()
			--currentCameraSpringArm1.RelativeRotation = pawn:K2_GetActorRotation()
			--currentCameraSpringArm.RelativeLocation.Z = 0
			--currentCameraSpringArm.TargetArmLength = currentCameraSpringArmTargetArmLength
		end
	end
end 



hook_function("Class /Script/Engine.SpringArmComponent", "K2_SetRelativeRotation", false, 
	function(fn, obj, locals, result)
		
		if normalPlay then
			needToFixSpringArmRotation = true
		end
	end,
	function(fn, obj, locals, result)
		if needToFixSpringArmRotation == true then
			--print("in springarm K2_SetRelativeRotation")
			fixDirection()					
		end 
		needToFixSpringArmRotation = false
		return false
	end,
true)

function revertDirection()
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		if currentCameraSpringArm ~= nil then
			--print("currentCameraSpringArm", currentCameraSpringArm:get_full_name())
			currentCameraSpringArm.RelativeRotation = {Pitch=-55, Roll = 0, Yaw= 60}
			currentCameraSpringArm.bInheritPitch = originalCameraSpringArmBInheritPitch
			currentCameraSpringArm.bInheritRoll = originalCameraSpringArmBInheritRoll
			currentCameraSpringArm.bInheritYaw = originalCameraSpringArmBInheritYaw
		end
	end
end 

function findCurrentCameraSpringArms()
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		if pawn.CameraBoom ~= nil then
			currentCameraSpringArm = pawn.CameraBoom
			currentCameraSpringArm.bInheritPitch = false
			currentCameraSpringArm.bInheritRoll = false
			currentCameraSpringArm.bInheritYaw = false
			currentCameraSpringArmTargetArmLength = pawn.CameraBoom.TargetArmLength
		end
		if pawn.SpringArm ~= nil then
			currentCameraSpringArm1 = pawn.SpringArm
			currentCameraSpringArm1.bInheritPitch = false
			currentCameraSpringArm1.bInheritRoll = false
			currentCameraSpringArm1.bInheritYaw = false
		end
	end
end

--Pawn direction fix section end


--Fixed cameras fix section start

hook_function("Class /Script/Engine.PlayerController", "SetViewTargetWithBlend", false, 
	function(fn, obj, locals, result)
		if normalPlay then
			pcall(setNeedTofixCamera)
		end
	end,
	function(fn, obj, locals, result)
		if needToFixCamera then
			fixCamera()					
		end 
		needToFixCamera = false
	end,
true)

function setNeedTofixCamera()
	player = api:get_player_controller(0)
	if player.PlayerCameraManager ~= nil and player.PlayerCameraManager.ViewTarget ~= nil and player.PlayerCameraManager.ViewTarget.Target ~= nil then
		if player ~= nil and player.PlayerCameraManager.ViewTarget.Target == pawn then
			--if string.find(player.PlayerCameraManager.ViewTarget.Target:get_full_name(), "PersistentLevel.CameraActor") then
				--print("last camera switched to: ", player.PlayerCameraManager.ViewTarget.Target:get_full_name())
			--end
			needToFixCamera = true	
		end
	end
end

function fixCamera()
	local player = api:get_player_controller(0)
	if player ~= nil then       
		if player.PlayerCameraManager ~= nil and player.PlayerCameraManager.ViewTarget ~= nil and player.PlayerCameraManager.ViewTarget.Target ~= nil then
			if player.PlayerCameraManager.ViewTarget.Target ~= nil and player.PlayerCameraManager.ViewTarget.Target ~= pawn and not string.find(player.PlayerCameraManager.ViewTarget.Target:get_full_name(), "FocusCameraEvent_C") then
				lastFixedCamera = player.PlayerCameraManager.ViewTarget.Target
				
				player.PlayerCameraManager.ViewTarget.Target = pawn
			end		
		end
	end
end

function applyLastFixedCamera()
	--print("applying last fixed camera")
	if lastFixedCamera ~= nil then
		local player = api:get_player_controller(0)
		if player ~= nil then       
			if player.PlayerCameraManager ~= nil and player.PlayerCameraManager.ViewTarget ~= nil and player.PlayerCameraManager.ViewTarget.Target ~= nil then	
				player.PlayerCameraManager.ViewTarget.Target = lastFixedCamera
				print("applied last fixed camera", lastFixedCamera:get_full_name())
			end
		end
	end
end

--Fixed cameras fix section end


--"Enhanced Movement" section start

function triggerPawnMovement()
	--optional - put here the stuff that determines if pawn moves - maybe it will help certain games not glitch when character movement is replaced by the "Enhanced Movement" system
end

function moveForward(value)
	--print("move forward", value)
	
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		if value ~= 0.0 then
			if pawn.CharacterMovement ~= nil then
				if runToggled == true then
					pawn.CharacterMovement.MaxWalkSpeed = 1200.0
					if configui.getValue("walk_speed") ~= nil and configui.getValue("run_speed_multiplier") ~= nil then
						pawn.CharacterMovement.MaxWalkSpeed = configui.getValue("walk_speed") * configui.getValue("run_speed_multiplier")
					end
					
				else
					pawn.CharacterMovement.MaxWalkSpeed = 600
					if configui.getValue("walk_speed") ~= nil then
						pawn.CharacterMovement.MaxWalkSpeedCrouched = configui.getValue("walk_speed")
						pawn.CharacterMovement.MaxWalkSpeed = configui.getValue("walk_speed")
					end
				end
			end	
			if value > 0 then
				direction = pawn:GetActorForwardVector();
				pawn:AddMovementInput(direction, 1); -- the value is between 0.0 and 1.0 - set to max and let the pawn.CharacterMovement.MaxWalkSpeed control the actual speed
			else
				local currentLocation = pawn:K2_GetActorLocation()
				local currentRotation = pawn:K2_GetActorRotation()
				local speed = 3
				if configui.getValue("move_back_speed") ~= nil then
					speed =  configui.getValue("move_back_speed")
				end
				local moveDistance = math.abs(-1 * speed) -- -3 seems to be the just the right amount...

				-- Backward movement - calculate backward from rotation
				-- Convert rotation to radians
				local yawRadians = math.rad(currentRotation.Yaw)
				
				-- Calculate backward direction based on current rotation
				local backwardX = -math.cos(yawRadians)	
				local backwardY = -math.sin(yawRadians)
									
				local newLocation = {
					X = currentLocation.X + backwardX * moveDistance,
					Y = currentLocation.Y + backwardY * moveDistance,
					Z = currentLocation.Z -- Keep Z unchanged for ground movement
				}
				if canMoveActorToLocation(currentLocation, newLocation) then
					--prevent deadlock when switching cameras
					local success = pcall(setActorLocation, newLocation)
					--if success == false then
					--	pcall(setActorLocation, currentLocation)
					--end
				end
			end
			triggerPawnMovement()
		end
	end
end

function strafe(value)
	--print("strafe", value)
	if value ~= 0 then
		local pawn = api:get_local_pawn(0)
		if pawn ~= nil then	
			local currentLocation = pawn:K2_GetActorLocation()
			local currentRotation = pawn:K2_GetActorRotation()
			local speed = 3
			if configui.getValue("strafe_speed") ~= nil then
				 speed =  configui.getValue("strafe_speed")
			end
			local moveDistance = math.abs(-1 * speed) -- -3 seems to be the just the right amount...
			local yawRadians = math.rad(currentRotation.Yaw)
			local strafeX
			local strafeY
			if value > 0 then
				strafeX = -math.sin(yawRadians)
				strafeY = math.cos(yawRadians)
			else			
				-- left movement 
				-- Calculate left direction based on current rotation
				strafeX = math.sin(yawRadians)
				strafeY = -math.cos(yawRadians)
			end
			local newLocation = {
				X = currentLocation.X + strafeX * moveDistance,
				Y = currentLocation.Y +strafeY * moveDistance,
				Z = currentLocation.Z -- Keep Z unchanged for ground movement
			}
			--prevent deadlock when switching cameras
			if canMoveActorToLocation(currentLocation, newLocation) then
				local success = pcall(setActorLocation, newLocation)
				--if success == false then
				--	pcall(setActorLocation, currentLocation)
				--end
			end
			triggerPawnMovement()
		end
	end
end

function canMoveActorToLocation(startLocation, targetLocation)
	-- Perform a line trace from start to target to check for walls
	local world = uevrUtils.get_world()
	if world == nil then
		return true -- No world, allow movement
	end
	--[[
	-- Calculate distance for trace
	local deltaX = targetLocation.X - startLocation.X
	local deltaY = targetLocation.Y - startLocation.Y
	local deltaZ = targetLocation.Z - startLocation.Z
	local distance = math.sqrt(deltaX^2 + deltaY^2 + deltaZ^2)
	
	-- If distance is very small, no need to trace
	if distance < 0.1 then
		return true
	end]]
	
	--[[
	https://www.youtube.com/watch?v=VNQYyoSLnh0
	
	UFUNCTION (BlueprintCallable, Category="Collision",  
	          Meta=(bIgnoreSelf="true", WorldContext="WorldContextObject", AutoCreateRefTerm="ActorsToIgnore", DisplayName="Line Trace By Channel", AdvancedDisplay="TraceColor,TraceHitColor,DrawTime", Keywords="raycast"))  
	static bool LineTraceSingle  
	(  
	    const UObject * WorldContextObject,  
	    const FVector Start,  
	    const FVector End,  
	    ETraceTypeQuery TraceChannel,   0 - visibility, 1 - camera, 2 - destructible, 3 - pawn, 4- vehicle, 5 - physicsbody, 6 - worldDynamic, 7 - worldstatic, 8-... - engine stuff
	    bool bTraceComplex,  
	    const TArray < AActor * > & ActorsToIgnore,  
	    EDrawDebugTrace::Type DrawDebugType,  
	    FHitResult & OutHit,  
	    bool bIgnoreSelf,  
	    FLinearColor TraceColor,  
	    FLinearColor TraceHitColor,  
	    float DrawTime  
	)  
	]]
	local ignore_actors = {}
	local centerOfmassHit = kismet_system_library:LineTraceSingle(world, startLocation, targetLocation, 0, true, ignore_actors, 0, reusable_hit_result, true, zero_color, zero_color, 1.0)
	--local hit = kismet_system_library:LineTraceSingle(world, startLocation, targetLocation, 0, true, {}, 0, empty_hitresult, true, uevrUtils.zero_color, uevrUtils.zero_color, 1.0)
	--print("hit", hit)
	if centerOfmassHit == true then
		print("line trace hit", reusable_hit_result.Distance)
	end
	
	return not centerOfmassHit == true
	--return not hit or not uevrUtils.reusable_hit_result.bBlockingHit

end

function setActorLocation(newLocation)
										  --sweep                --teleport
	pawn:K2_SetActorLocation(newLocation, true, empty_hitresult, true)
end

function setActorRotation(newRotation)
	pawn:K2_SetActorRotation(newRotation)
	--if pawn.EquippedWeapon ~= nil then
	--		pawn.EquippedWeapon:K2_SetActorRotation(newRotation)
	--end
	--pawn.Mesh.RelativeRotation.Yaw = 180
	--pawn.StaticMesh.RelativeRotation.Yaw = 180
end

function turn(value)
	--print("turn")

	local turnRateGamepad = 0.10
	if configui.getValue("turn_speed") ~= nil then
		turnRateGamepad = configui.getValue("turn_speed") 
	end
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		if value ~= 0.0 then
			newRotation = pawn:K2_GetActorRotation();
			newRotation.Yaw = newRotation.Yaw + value * turnRateGamepad
			--local player = api:get_player_controller(0)
			--if player ~= nil then
				--player.ControlRotation.Yaw = newRotation.Yaw
				--player:SetControlRotation(newRotation)
				--currentCameraSpringArm.RelativeRotation.Yaw = newRotation.Yaw
			--end

			--pawn:K2_SetActorRotation(newRotation)
			pcall(setActorRotation, newRotation)
			triggerPawnMovement()
		end
	end
end

--"Enhanced Movement" section end


uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
	if (state ~= nil) then
		
		if state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER ~= 0 and state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER ~= 0 then
				state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_LEFT_SHOULDER
				state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_RIGHT_SHOULDER
				params.vr.recenter_view()
		end
		
		if normalPlay == true then
			if state.Gamepad.wButtons & XINPUT_GAMEPAD_Y ~= 0 then -- abilities wheel fix - allow both sticks to select abilities while holding Y
				if state.Gamepad.sThumbLX < 1000 and state.Gamepad.sThumbLY < 1000 then 
					state.Gamepad.sThumbLX = state.Gamepad.sThumbRX
					state.Gamepad.sThumbLY = state.Gamepad.sThumbRY
				end
			elseif state.Gamepad.sThumbRX > 10000 or state.Gamepad.sThumbRX < -10000 then
				turn(state.Gamepad.sThumbRX/1000)
			end
			if state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER == 0 then
			 --disable R stick X and Y so that the laser sight won't be moved. enable it for long press dashes
				state.Gamepad.sThumbRX  = 0
				state.Gamepad.sThumbRY  = 0
			end
			--switch run to toggle left thumb stick
			--[[if not runToggled then
				if state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB ~= 0 and state.Gamepad.sThumbLY > 10000 then
					state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_A
					runToggled = true
					--print("runToggled")
				end	
			else
				if state.Gamepad.sThumbLY < 10000  then
					runToggled = false
					--print("runToggled end")
				else -- run is toggled
					state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_A
				end
			end
			
			if state.Gamepad.sThumbRX > 10000 or state.Gamepad.sThumbRX < -10000 then
				turn(state.Gamepad.sThumbRX/1000)
			end
			if state.Gamepad.sThumbLY > 10000 or state.Gamepad.sThumbLY < -10000 then
				moveForward(state.Gamepad.sThumbLY)
			end
			
			if state.Gamepad.sThumbLX > 15000 or state.Gamepad.sThumbLX < -15000 then
				strafe(state.Gamepad.sThumbLX)
			end
			
			 --disable R stick X and Y so that the laser sight won't be moved 
			state.Gamepad.sThumbRX  = 0
			state.Gamepad.sThumbRY  = 0
			
			-- disable L stick - use movement functions instead (except for dodge - i.e. A + left stick direction)
			if state.Gamepad.wButtons & XINPUT_GAMEPAD_A == 0 then --no dodge
				state.Gamepad.sThumbLX = 0 
				state.Gamepad.sThumbLY = 0
			end]]
			
		elseif fixedCameras3rdPersonMode == true then
			--put here stuff that are generic to both 1st person and 3rd person
		end
		
		
		if not isMainMenu() then
			--[[if state.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_UP ~= 0 then --disable palyer clicking dpad up
				print("disable dpad up")
				state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_DPAD_UP
			end
			
			if in2dMode == false and needToApply2dSettings == true then 
				state.Gamepad.wButtons = state.Gamepad.wButtons + XINPUT_GAMEPAD_DPAD_UP --click dpad up to disabled VR
				in2dMode = true
				print("disabling vr")
			elseif in2dMode == true and needToApply2dSettings == false then
				state.Gamepad.wButtons = state.Gamepad.wButtons + XINPUT_GAMEPAD_DPAD_UP --click dpad up to enable VR again
				in2dMode = false
				print("enabling vr")
			end]]
			
			if state.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_RIGHT ~= 0 then --toggle fixedCameras3rdPersonMode
				if fixedCameras3rdPersonModeJustChanged == false then
					fixedCameras3rdPersonMode = not fixedCameras3rdPersonMode
					fixedCameras3rdPersonModeJustChanged = true
					--if fixedCameras3rdPersonMode == true then
					--	applyLastFixedCamera()
					--end
				end
				print("fixedCameras3rdPersonMode", fixedCameras3rdPersonMode)
				state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_DPAD_RIGHT 
			else -- dpad down released
				if fixedCameras3rdPersonModeJustChanged == true then
					fixedCameras3rdPersonModeJustChanged = false
				end
			end
		end
	end
end)