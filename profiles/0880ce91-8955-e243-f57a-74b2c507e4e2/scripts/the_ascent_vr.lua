local api = uevr.api
local vr = uevr.params.vr
local params = uevr.params
local callbacks = params.sdk.callbacks

local uevrUtils = require('libs/uevr_utils')
local configui = require('libs/configui')
local hands = require('libs/hands')
local controllers = require('libs/controllers')
local gestures = require('libs/gestures')

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
local kismet_math_library = uevrUtils.find_default_instance("Class /Script/Engine.KismetMathLibrary")
local reusable_hit_result = uevrUtils.get_reuseable_struct_object("ScriptStruct /Script/Engine.HitResult")
local zero_color = uevrUtils.get_reuseable_struct_object("ScriptStruct /Script/CoreUObject.LinearColor")

local currentCameraSpringArm = nil
local currentCameraSpringArmTargetArmLength = nil
local originalCameraSpringArmBInheritPitch = true
local originalCameraSpringArmBInheritRoll = true
local originalCameraSpringArmBInheritYaw = true

local currentProjectileMovementComponent = nil


local needToFixCamera = false

local needToFixSpringArmRotation = false

local onBulletTraceHooked = false
local onFirePressedHooked = false

local onReceiveTickHooked = false

local fireSingleMuzzleHooked = false

local onProjectileReceiveBeginPlayHooked = false
local onUziProjectileReceiveBeginPlayHooked = false
local onSawbladeProjectileReceiveBeginPlayHooked = false
local onBazookaProjectileReceiveBeginPlayHooked = false
local onProjectileReceiveEndPlayHooked = false
local laserLength = 1000

local reloadMontageInProgress = false
local reloadMontageHandled = false

local currentProjectiles = {}

local configDefinition = {
	{
		panelLabel = "The Ascent VR", 
		saveFile = "user_configuration", 
		layout = {
			{
				widgetType = "text",
				label = "=== Gameplay ===",
			},
			--[[{
				widgetType = "checkbox",
				id = "show_laser",
				label = "Show laser",
				initialValue = true
			},]]
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
				range = {"0.01", "0.50"}
			},
			{
				widgetType = "slider_float",
				id = "run_speed_multiplier",
				label = "Run speed multiplier (walk speed * multiplier = run speed)",
				initialValue = 2,
				range = {"0", "3"}
			},
			{
				widgetType = "slider_int",
				id = "strafe_speed",
				label = "Strafing Speed",
				initialValue = 6,
				range = {"1", "10"}
			},
			{
				widgetType = "slider_int",
				id = "move_back_speed",
				label = "Move back speed",
				initialValue = 6,
				range = {"1", "10"}
			},
		}
	}
}

configui.create(configDefinition)

function on_level_change(level)
	findCurrentProjectileMovementComponent()
	findCurrentCameraSpringArms()
	initHands()
end

function initHands()
	controllers.createController(0)
	controllers.createController(1)
	hands.reset()

	local paramsFile = 'hands_parameters' -- found in the [game profile]/data directory
	local configName = 'Main' -- the name you gave your config
	local animationName = 'Shared' -- the name you gave your animation
	hands.createFromConfig(paramsFile, configName, animationName)
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
end)

function getCurrentWeaponMesh()
	--[[local pawn = api:get_local_pawn(0)
	currentGuns = uevrUtils.find_all_instances("BlueprintGeneratedClass /Game/Blueprints/Weapons/WeaponBaseGun_BP.WeaponBaseGun_BP_C", false)
	if currentGuns ~= nil then
		for _, currentGun in pairs(currentGuns) do
			--print("currentGun", currentGun:get_full_name())
			if currentGun.Owner ~= nil and currentGun.Owner == pawn then
				activeWeaponWeapon = currentGun
				if configui.getValue("show_laser") ~= nil then
					if activeWeaponWeapon ~= nil then
						activeWeaponWeapon.HasLaserSight = configui.getValue("show_laser")
					end
				end
				return currentGun.SkeletalMeshComponent
			end
		end
	end
	currentMelees = uevrUtils.find_all_instances("BlueprintGeneratedClass /Game/Blueprints/Weapons/WeaponBaseMelee_BP.WeaponBaseMelee_BP_C", false)
	if currentMelees ~= nil then
		for _, currentMelee in pairs(currentMelees) do
			if currentMelee.Owner ~= nil and currentMelee.Owner == pawn then
				activeWeaponWeapon = currentMelee
				return currentMelee.SkeletalMeshComponent
			end
		end
	end
	activeWeaponWeapon = nil
	return nil]]
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil and pawn.PlayerWeaponHandlerComponent ~= nil and pawn.PlayerWeaponHandlerComponent.CarriedWeapon ~= nil then
		--print("activeWeaponWeapon found")
		activeWeaponWeapon = pawn.PlayerWeaponHandlerComponent.CarriedWeapon
		--if configui.getValue("show_laser") ~= nil then
			if activeWeaponWeapon ~= nil then
				--activeWeaponWeapon.HasLaserSight = configui.getValue("show_laser")
				if normalPlay == true then
					if activeWeaponWeapon.HasLaserSight ~= nil then
						activeWeaponWeapon.HasLaserSight = false
					end
					if activeWeaponWeapon.LaserSightPoint ~= nil then
						activeWeaponWeapon.LaserSightPoint:SetVisibility(false)
					end
					if activeWeaponWeapon.WeaponVFXComp ~= nil and activeWeaponWeapon.WeaponVFXComp.LaserSightVisible ~= nil then
						--print("hiding laser")
						activeWeaponWeapon.WeaponVFXComp.LaserSightVisible = false
					end
				end
			end
		--end
		return activeWeaponWeapon.SkeletalMeshComponent
	end
	return nil
end

function updateEquippedWeapon(currentWeapon, hand)
	if hand == nil then hand = Handed.Right end
	--[[if reloadMontageInProgress == true then
		if currentWeapon ~= nil and reloadMontageHandled == false then
			hands.attachHandToMesh(0, currentWeapon, "LeftHandIK", nil, nil)
		end
	else
		if reloadMontageHandled == true then
			reloadMontageHandled = false
			hands.attachHandToController(0)
		end]]
		local lastWeapon = activeWeapon
		pcall(disconnectPreviousWeapon, currentWeapon, hand)
		
		if currentWeapon ~= nil and activeWeapon ~= currentWeapon then
			backupEquippedWeaponAttachmentSettings(currentWeapon)
			print("Connecting weapon ".. currentWeapon:get_full_name() .. " " .. currentWeapon:get_fname():to_string() .. " to hand " .. hand)
			if activeWeaponWeapon.Projectile ~= nil then
				print("weapon has projectile", activeWeaponWeapon.Projectile:get_full_name())
			end
			local state = UEVR_UObjectHook.get_or_add_motion_controller_state(currentWeapon)
			state:set_hand(hand)
			state:set_permanent(true)
			
			if string.find(currentWeapon:get_full_name(), "PistolWeapon") then
				state:set_rotation_offset(Vector3f.new(0.180, 1.447, -0.105)) -- left, down
				state:set_location_offset(Vector3f.new(-0.498, -4.480, -5.368)) --forward , up, right
			elseif string.find(currentWeapon:get_full_name(), "Burst_Energy") then
				state:set_rotation_offset(Vector3f.new(0.180, 1.447, -0.105)) -- left, down
				state:set_location_offset(Vector3f.new(-0.498, -4.480, -5.368)) --forward , up, right
				onProjectileReceiveBeginPlayHooked = false --workaround for hooks failing
			elseif string.find(currentWeapon:get_full_name(), "AR_Burst_Mk1") then
				state:set_rotation_offset(Vector3f.new(0.180, 1.447, -0.105)) -- left, down
				state:set_location_offset(Vector3f.new(-0.498, -4.480, -5.368)) --forward , up, right
				onProjectileReceiveBeginPlayHooked = false --workaround for hooks failing
			elseif string.find(currentWeapon:get_full_name(), "UziR") then --no pitch
				state:set_rotation_offset(Vector3f.new(0.180, 1.447, -0.105)) -- left, down
				state:set_location_offset(Vector3f.new(-0.498, -4.480, -5.368)) --forward , up, right
				onUziProjectileReceiveBeginPlayHooked = false --workaround for hooks failing
			elseif string.find(currentWeapon:get_full_name(), "Sawblade") then -- no pitch
				state:set_rotation_offset(Vector3f.new(0.180, 1.447, -0.105)) -- left, down
				state:set_location_offset(Vector3f.new(-0.498, -4.480, -5.368)) --forward , up, right
				onSawbladeProjectileReceiveBeginPlayHooked = false --workaround for hooks failing
			elseif string.find(currentWeapon:get_full_name(), "RocketLauncher_Mk1") then
				state:set_rotation_offset(Vector3f.new(0.180, 1.447, -0.105)) -- left, down
				state:set_location_offset(Vector3f.new(-0.498, -4.480, -5.368)) --forward , up, right
				onProjectileReceiveBeginPlayHooked = false
			elseif string.find(currentWeapon:get_full_name(), "HMG") then --no pitch
				state:set_rotation_offset(Vector3f.new(0.180, 1.447, -0.105)) -- left, down
				state:set_location_offset(Vector3f.new(-0.498, -4.480, -5.368)) --forward , up, right
				onProjectileReceiveBeginPlayHooked = false
			elseif string.find(currentWeapon:get_full_name(), "BigClip") then --no pitch
				state:set_rotation_offset(Vector3f.new(0.180, 1.447, -0.105)) -- left, down
				state:set_location_offset(Vector3f.new(-0.498, -4.480, -5.368)) --forward , up, right
				onProjectileReceiveBeginPlayHooked = false
			elseif string.find(currentWeapon:get_full_name(), "MinigunRocket") then --no pitch
				state:set_rotation_offset(Vector3f.new(0.180, 1.447, -0.105)) -- left, down
				state:set_location_offset(Vector3f.new(-0.498, -4.480, -5.368)) --forward , up, right
				onProjectileReceiveBeginPlayHooked = false
			elseif string.find(currentWeapon:get_full_name(), "Bazooka") then --no pitch
				state:set_rotation_offset(Vector3f.new(0.180, 1.447, -0.105)) -- left, down
				state:set_location_offset(Vector3f.new(-0.498, -4.480, -5.368)) --forward , up, right
				onBazookaProjectileReceiveBeginPlayHooked = false
			else
				state:set_rotation_offset(Vector3f.new(0.180, 1.447, -0.105)) -- left, down
				state:set_location_offset(Vector3f.new(-0.498, -4.480, -5.368)) --forward , up, right
				onProjectileReceiveBeginPlayHooked = false
			end
		--end
		
		activeHand = hand
		activeWeapon = currentWeapon
	end
	
end

function updateEquippedWeaponHands(currentWeapon, hand)
	if hand == nil then hand = Handed.Right end
	--[[if reloadMontageInProgress == true then
		if currentWeapon ~= nil and reloadMontageHandled == false then
			hands.attachHandToMesh(0, currentWeapon, "LeftHandIK", nil, nil)
		end
	else
		if reloadMontageHandled == true then
			reloadMontageHandled = false
			hands.attachHandToController(0)
		end]]
		local lastWeapon = activeWeapon
		pcall(disconnectPreviousWeapon, currentWeapon, hand)
		
		if currentWeapon ~= nil and activeWeapon ~= currentWeapon then
			backupEquippedWeaponAttachmentSettings(currentWeapon)
			print("Connecting weapon ".. currentWeapon:get_full_name() .. " " .. currentWeapon:get_fname():to_string() .. " to hand " .. hand)
			if activeWeaponWeapon.Projectile ~= nil then
				print("weapon has projectile", activeWeaponWeapon.Projectile:get_full_name())
			end
			local state = UEVR_UObjectHook.get_or_add_motion_controller_state(currentWeapon)
			state:set_hand(hand)
			state:set_permanent(true)
			
			if string.find(currentWeapon:get_full_name(), "PistolWeapon") then
				state:set_rotation_offset(Vector3f.new(0.180, 1.447, -0.105))
				state:set_location_offset(Vector3f.new(-0.498, -4.480, -5.368)) --forward , up, right
			elseif string.find(currentWeapon:get_full_name(), "Burst_Energy") then
				state:set_rotation_offset(Vector3f.new(0.330, 1.573, 0.134))
				state:set_location_offset(Vector3f.new(7.747, 10.799, 7.818)) --forward , up, right
				onProjectileReceiveBeginPlayHooked = false --workaround for hooks failing
			elseif string.find(currentWeapon:get_full_name(), "AR_Burst_Mk1") then
				state:set_rotation_offset(Vector3f.new(0.330, 1.573, 0.134))
				state:set_location_offset(Vector3f.new(7.747, 10.799, 7.818)) --forward , up, right
				onProjectileReceiveBeginPlayHooked = false --workaround for hooks failing
			elseif string.find(currentWeapon:get_full_name(), "UziR") then --no pitch
				state:set_rotation_offset(Vector3f.new(0.330, 1.573, 0.134)) -- left, down
				state:set_location_offset(Vector3f.new(7.747, 10.799, 7.818)) --forward , up, right
				onUziProjectileReceiveBeginPlayHooked = false --workaround for hooks failing
			elseif string.find(currentWeapon:get_full_name(), "Sawblade") then -- no pitch
				state:set_rotation_offset(Vector3f.new(0.330, 1.573, 0.134)) -- left, down
				state:set_location_offset(Vector3f.new(7.747, 10.799, 7.818)) --forward , up, right
				onSawbladeProjectileReceiveBeginPlayHooked = false --workaround for hooks failing
			elseif string.find(currentWeapon:get_full_name(), "RocketLauncher_Mk1") then
				state:set_rotation_offset(Vector3f.new(0.330, 1.573, 0.134)) -- left, down
				state:set_location_offset(Vector3f.new(7.747, 10.799, 7.818)) --forward , up, right
				onProjectileReceiveBeginPlayHooked = false
			elseif string.find(currentWeapon:get_full_name(), "HMG") then --no pitch
				state:set_rotation_offset(Vector3f.new(0.330, 1.573, 0.134)) -- left, down
				state:set_location_offset(Vector3f.new(7.747, 10.799, 7.818)) --forward , up, right
				onProjectileReceiveBeginPlayHooked = false
			elseif string.find(currentWeapon:get_full_name(), "BigClip") then --no pitch
				state:set_rotation_offset(Vector3f.new(0.330, 1.573, 0.134)) -- left, down
				state:set_location_offset(Vector3f.new(7.747, 10.799, 7.818)) --forward , up, right
				onProjectileReceiveBeginPlayHooked = false
			elseif string.find(currentWeapon:get_full_name(), "MinigunRocket") then --no pitch
				state:set_rotation_offset(Vector3f.new(0.330, 1.573, 0.134)) -- left, down
				state:set_location_offset(Vector3f.new(7.747, 10.799, 7.818)) --forward , up, right
				onProjectileReceiveBeginPlayHooked = false
			elseif string.find(currentWeapon:get_full_name(), "Bazooka") then --no pitch
				state:set_rotation_offset(Vector3f.new(0.330, 1.573, 0.134)) -- left, down
				state:set_location_offset(Vector3f.new(7.747, 10.799, 7.818)) --forward , up, right
				onBazookaProjectileReceiveBeginPlayHooked = false
			else
				state:set_rotation_offset(Vector3f.new(0.330, 1.573, 0.134))
				state:set_location_offset(Vector3f.new(7.747, 10.799, 7.818)) --forward , up, right
				onProjectileReceiveBeginPlayHooked = false
			end
		--end
		
		activeHand = hand
		activeWeapon = currentWeapon
	end
	
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
		local state = UEVR_UObjectHook.get_or_add_motion_controller_state(currentWeapon)
		UEVR_UObjectHook.remove_motion_controller_state(activeWeapon)
	end
end

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	hookFuntionsForRuntimeGeneratedClasses()
	if isMainMenu() then
		applyMainMenuSettings()
	elseif fixedCameras3rdPersonMode == true then
		--print("apply 3rd")
		applyFixedCameras3rdPersonModeSettings()
	elseif isInCutScene() then
		applyCinematicSettings()
	else --regular play	
		if not hands.exists() then
			initHands()
		end
		applyNormalModeSettings(delta)
	end	
end)

function hookFuntionsForRuntimeGeneratedClasses() 
	if onSawbladeProjectileReceiveBeginPlayHooked == false then
		-- Dismemberer (Sawblade)
		hook_function("BlueprintGeneratedClass /Game/Blueprints/Projectiles/SawbladeStuckProjectile_BP.SawbladeStuckProjectile_BP_C", "ReceiveBeginPlay", false,
			function(fn, obj, locals, result)
				print("ReceiveBeginPlay started", obj:get_full_name())
				if activeWeapon ~= nil and activeWeaponWeapon ~= nil and obj.Owner == activeWeaponWeapon then
					--table.insert(currentProjectiles, obj)
					print("ReceiveBeginPlay started", obj.ProjectileMovementComponent:get_full_name())
					--pawn.AimLowPoint.RelativeLocation =activeWeapon:GetSocketLocation("Barrel")
					--local targetLocation = activeWeapon:GetForwardVector()
					local muzzleRotator = activeWeapon:GetSocketRotation("Barell")
					--local muzzleRotator = activeWeapon:K2_GetComponentRotation()
					--magmamaker (FlamethrowerWeapon_BP_C), overwhelmer (HMGExplosiveWeapon_BP_C), EBR enforcer (Burst_Energy), ABR Commander (AR_Burst_Mk1_Weapon)
					if string.find(obj:get_full_name(),"Sawblade") then						
						muzzleRotator.Yaw = muzzleRotator.Yaw +90
					else --flamethrower
					end
					local targetLocation = kismet_math_library:GetForwardVector(muzzleRotator)
					--[[local endPoint = activeWeapon:GetForwardVector()
					if endPoint ~= nil then
						targetLocation = Vector3f.new(
						targetLocation.X * 8192.0,
						targetLocation.Y * 8192.0,
						targetLocation.Z * 8192.0)
					end]]
					obj.ProjectileMovementComponent.Velocity.X = targetLocation.X * obj.ProjectileMovementComponent.InitialSpeed 
					obj.ProjectileMovementComponent.Velocity.Y = targetLocation.Y * obj.ProjectileMovementComponent.InitialSpeed 
					obj.ProjectileMovementComponent.Velocity.Z = targetLocation.Z * obj.ProjectileMovementComponent.InitialSpeed 
					
					
					print("z",obj.ProjectileMovementComponent.Velocity.Z)
				end
			end,
			function(fn, obj, locals, result)
				print("ReceiveBeginPlay ended", obj:get_full_name())
				if activeWeaponWeapon ~= nil and obj.Owner == activeWeaponWeapon then
				end
			end,
		true)
		onSawbladeProjectileReceiveBeginPlayHooked = true		
	end
	if onUziProjectileReceiveBeginPlayHooked == false then
		-- The CrazyMaker (Uzi) 
		hook_function("BlueprintGeneratedClass /Game/Blueprints/Projectiles/UziRicochetProjectile_BP.UziRicochetProjectile_BP_C", "ReceiveBeginPlay", false,
			function(fn, obj, locals, result)
				print("ReceiveBeginPlay started", obj:get_full_name())
				if activeWeapon ~= nil and activeWeaponWeapon ~= nil and obj.Owner == activeWeaponWeapon then
					--table.insert(currentProjectiles, obj)
					print("ReceiveBeginPlay started", obj.ProjectileMovementComponent:get_full_name())
					--pawn.AimLowPoint.RelativeLocation =activeWeapon:GetSocketLocation("Barrel")
					--local targetLocation = activeWeapon:GetForwardVector()
					local muzzleRotator = activeWeapon:GetSocketRotation("Barrel")
					--local muzzleRotator = activeWeapon:K2_GetComponentRotation()
					--magmamaker (FlamethrowerWeapon_BP_C), overwhelmer (HMGExplosiveWeapon_BP_C), EBR enforcer (Burst_Energy), ABR Commander (AR_Burst_Mk1_Weapon)
					if string.find(obj:get_full_name(),"Uzi") then						
						muzzleRotator.Yaw = muzzleRotator.Yaw +90
					else --flamethrower
					end
					local targetLocation = kismet_math_library:GetForwardVector(muzzleRotator)
					--[[local endPoint = activeWeapon:GetForwardVector()
					if endPoint ~= nil then
						targetLocation = Vector3f.new(
						targetLocation.X * 8192.0,
						targetLocation.Y * 8192.0,
						targetLocation.Z * 8192.0)
					end]]
					obj.ProjectileMovementComponent.Velocity.X = targetLocation.X * obj.ProjectileMovementComponent.InitialSpeed 
					obj.ProjectileMovementComponent.Velocity.Y = targetLocation.Y * obj.ProjectileMovementComponent.InitialSpeed 
					obj.ProjectileMovementComponent.Velocity.Z = targetLocation.Z * obj.ProjectileMovementComponent.InitialSpeed 
					
					
					print("z",obj.ProjectileMovementComponent.Velocity.Z)
				end
			end,
			function(fn, obj, locals, result)
				print("ReceiveBeginPlay ended", obj:get_full_name())
				if activeWeaponWeapon ~= nil and obj.Owner == activeWeaponWeapon then
				end
			end,
		true)
		onUziProjectileReceiveBeginPlayHooked = true		
	end
	
	if onBazookaProjectileReceiveBeginPlayHooked == false then
		--Besieger (BigClipRocket)
		hook_function("BlueprintGeneratedClass /Game/Blueprints/Projectiles/BigClipRocketLauncherProjectile_BP.BigClipRocketLauncherProjectile_BP_C", "ReceiveBeginPlay", false,
			function(fn, obj, locals, result)
				print("ReceiveBeginPlay started", obj:get_full_name())
				if activeWeapon ~= nil and activeWeaponWeapon ~= nil and obj.Owner == activeWeaponWeapon then
					--table.insert(currentProjectiles, obj)					
					print("ReceiveBeginPlay started", obj.ProjectileMovementComponent:get_full_name())
					--pawn.AimLowPoint.RelativeLocation =activeWeapon:GetSocketLocation("Barrel")
					--local targetLocation = activeWeapon:GetForwardVector()
					local muzzleRotator = activeWeapon:GetSocketRotation("Barrel")
					--local muzzleRotator = activeWeapon:K2_GetComponentRotation()
					--magmamaker (FlamethrowerWeapon_BP_C), overwhelmer (HMGExplosiveWeapon_BP_C), EBR enforcer (Burst_Energy), ABR Commander (AR_Burst_Mk1_Weapon)
					if string.find(obj:get_full_name(),"BigClipRocket") or string.find(obj:get_full_name(),"Minigun") or string.find(obj:get_full_name(),"Bazooka") or string.find(obj:get_full_name(),"Homing") then						
						muzzleRotator.Yaw = muzzleRotator.Yaw +90
					else --flamethrower
					end
					local targetLocation = kismet_math_library:GetForwardVector(muzzleRotator)
					--[[local endPoint = activeWeapon:GetForwardVector()
					if endPoint ~= nil then
						targetLocation = Vector3f.new(
						targetLocation.X * 8192.0,
						targetLocation.Y * 8192.0,
						targetLocation.Z * 8192.0)
					end]]
					obj.ProjectileMovementComponent.Velocity.X = targetLocation.X * obj.ProjectileMovementComponent.InitialSpeed 
					obj.ProjectileMovementComponent.Velocity.Y = targetLocation.Y * obj.ProjectileMovementComponent.InitialSpeed 
					obj.ProjectileMovementComponent.Velocity.Z = targetLocation.Z * obj.ProjectileMovementComponent.InitialSpeed 
					
					
					print("z",obj.ProjectileMovementComponent.Velocity.Z)
				end
			end,
			function(fn, obj, locals, result)
				print("ReceiveBeginPlay ended", obj:get_full_name())
				if activeWeaponWeapon ~= nil and obj.Owner == activeWeaponWeapon then
				end
			end,
		true)
		onBazookaProjectileReceiveBeginPlayHooked = true
	end
	
	if onProjectileReceiveBeginPlayHooked == false then
		--Besieger (BigClipRocket), AstroMasher (minigun), BlastMaster (Bazooka), RPG23 Launcher (Homing)
		hook_function("BlueprintGeneratedClass /Game/Blueprints/Projectiles/RocketLauncherProjectile_BP.RocketLauncherProjectile_BP_C", "ReceiveBeginPlay", false,
			function(fn, obj, locals, result)
				print("ReceiveBeginPlay started", obj:get_full_name())
				if activeWeapon ~= nil and activeWeaponWeapon ~= nil and obj.Owner == activeWeaponWeapon then
					--table.insert(currentProjectiles, obj)
					print("ReceiveBeginPlay started", obj:get_full_name())
					print("ReceiveBeginPlay started", obj.ProjectileMovementComponent:get_full_name())
					--pawn.AimLowPoint.RelativeLocation =activeWeapon:GetSocketLocation("Barrel")
					--local targetLocation = activeWeapon:GetForwardVector()
					local muzzleRotator = activeWeapon:GetSocketRotation("Barrel")
					--local muzzleRotator = activeWeapon:K2_GetComponentRotation()
					--magmamaker (FlamethrowerWeapon_BP_C), overwhelmer (HMGExplosiveWeapon_BP_C), EBR enforcer (Burst_Energy), ABR Commander (AR_Burst_Mk1_Weapon)
					if string.find(obj:get_full_name(),"BigClipRocket") or string.find(obj:get_full_name(),"Minigun") or string.find(obj:get_full_name(),"Bazooka") or string.find(obj:get_full_name(),"Homing") then						
						muzzleRotator.Yaw = muzzleRotator.Yaw +90
					else --flamethrower
					end
					local targetLocation = kismet_math_library:GetForwardVector(muzzleRotator)
					--[[local endPoint = activeWeapon:GetForwardVector()
					if endPoint ~= nil then
						targetLocation = Vector3f.new(
						targetLocation.X * 8192.0,
						targetLocation.Y * 8192.0,
						targetLocation.Z * 8192.0)
					end]]
					obj.ProjectileMovementComponent.Velocity.X = targetLocation.X * obj.ProjectileMovementComponent.InitialSpeed 
					obj.ProjectileMovementComponent.Velocity.Y = targetLocation.Y * obj.ProjectileMovementComponent.InitialSpeed 
					obj.ProjectileMovementComponent.Velocity.Z = targetLocation.Z * obj.ProjectileMovementComponent.InitialSpeed 
					
					
					print("z",obj.ProjectileMovementComponent.Velocity.Z)
				end
			end,
			function(fn, obj, locals, result)
				print("ReceiveBeginPlay ended", obj:get_full_name())
				if activeWeaponWeapon ~= nil and obj.Owner == activeWeaponWeapon then
				end
			end,
		true)
		
		
		
		-- ABR Commander, EBR enforcer , overwhelmer, magmamaker
		hook_function("BlueprintGeneratedClass /Game/Blueprints/Projectiles/BaseProjectile_BP.BaseProjectile_BP_C", "ReceiveBeginPlay", false,
			function(fn, obj, locals, result)
				print("ReceiveBeginPlay started", obj:get_full_name())
				if activeWeapon ~= nil and activeWeaponWeapon ~= nil and obj.Owner == activeWeaponWeapon then
					--table.insert(currentProjectiles, obj)
					print("ReceiveBeginPlay started", obj.ProjectileMovementComponent:get_full_name())
					--pawn.AimLowPoint.RelativeLocation =activeWeapon:GetSocketLocation("Barrel")
					--local targetLocation = activeWeapon:GetForwardVector()
					local muzzleRotator = activeWeapon:GetSocketRotation("Barrel")
					--local muzzleRotator = activeWeapon:K2_GetComponentRotation()
					--magmamaker (FlamethrowerWeapon_BP_C), overwhelmer (HMGExplosiveWeapon_BP_C), EBR enforcer (Burst_Energy), ABR Commander (AR_Burst_Mk1_Weapon)
					if string.find(obj:get_full_name(),"Burst_Energy") or string.find(obj:get_full_name(),"HMGExplosiveProjectile") or string.find(obj:get_full_name(),"Burst_Base_Projectile") then						
						muzzleRotator.Yaw = muzzleRotator.Yaw +90
					else --flamethrower
					end
					local targetLocation = kismet_math_library:GetForwardVector(muzzleRotator)
					--[[local endPoint = activeWeapon:GetForwardVector()
					if endPoint ~= nil then
						targetLocation = Vector3f.new(
						targetLocation.X * 8192.0,
						targetLocation.Y * 8192.0,
						targetLocation.Z * 8192.0)
					end]]
					obj.ProjectileMovementComponent.Velocity.X = targetLocation.X * obj.ProjectileMovementComponent.InitialSpeed 
					obj.ProjectileMovementComponent.Velocity.Y = targetLocation.Y * obj.ProjectileMovementComponent.InitialSpeed 
					obj.ProjectileMovementComponent.Velocity.Z = targetLocation.Z * obj.ProjectileMovementComponent.InitialSpeed 
					
					
					print("z",obj.ProjectileMovementComponent.Velocity.Z)
				end
			end,
			function(fn, obj, locals, result)
				print("ReceiveBeginPlay ended", obj:get_full_name())
				if activeWeaponWeapon ~= nil and obj.Owner == activeWeaponWeapon then
				end
			end,
		true)
				
		onProjectileReceiveBeginPlayHooked = true		
	end
		--[[if onProjectileReceiveEndPlayHooked == false then
		hook_function("BlueprintGeneratedClass /Game/Blueprints/Projectiles/BaseProjectile_BP.BaseProjectile_BP_C", "ReceiveEndPlay", false,
			function(fn, obj, locals, result)
				if currentProjectiles ~= nil and activeWeapon ~= nil and activeWeaponWeapon ~= nil and obj.Owner == activeWeaponWeapon then
					print("currentProjectiles", #currentProjectiles)
					for i, curentProjectile in pairs(currentProjectiles) do
						if curentProjectile:get_full_name() == obj:get_full_name() then
							print("removed from table")
							--table.remove(currentProjectiles, i)
							break
						end
					end
				end
			end,
			function(fn, obj, locals, result)
				print("ReceiveEndPlay ended", obj:get_full_name())
			end,
		true)
		
		onProjectileReceiveEndPlayHooked = true
	end]]
	--[[
	if onBulletTraceHooked == false then
		hook_function("BlueprintGeneratedClass /Game/Blueprints/Weapons/WeaponGunBaseVFXComponent_BP.WeaponGunBaseVFXComponent_BP_C", "OnBulletTrace", false,
			function(fn, obj, locals, result)
				print("OnBulletTrace started")
				print("end before ", locals.End)
				--print("obj.LaserSightEndPoint", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation", obj.LaserSightRotation)
				--print("obj.BulletTraceEndPoints", obj.BulletTraceEndPoints)
				print("obj.LastRotation", obj.LastRotation)
				--print("obj[Spawned Bullet Line]", obj["Spawned Bullet Line"])
				
				obj.LaserSightEndPoint = calculateBulletTraceEndPoint()
				obj.LaserSightRotation = controllers.getControllerRotation(1)
				--print("obj.LaserSightEndPoint after", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation after", obj.LaserSightRotation)
				locals.End = calculateBulletTraceEndPoint()
				print("end after ", locals.End)
				--if activeWeaponWeapon ~= nil and activeWeaponWeapon.Projectile ~= nil then
				---	print("projectile ", activeWeaponWeapon.Projectile:get_full_name())
				--end
			end,
			function(fn, obj, locals, result)
				print("OnBulletTrace ended")
				print("end before ", locals.End)
				--print("obj.LaserSightEndPoint", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation", obj.LaserSightRotation)
				--print("obj.BulletTraceEndPoints", #obj.BulletTraceEndPoints)
				print("obj.LastRotation", obj.LastRotation)
				--print("obj[Spawned Bullet Line]", obj["Spawned Bullet Line"])
				
				obj.LaserSightEndPoint = calculateBulletTraceEndPoint()
				obj.LaserSightRotation = controllers.getControllerRotation(1)
				--print("obj.LaserSightEndPoint after", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation after", obj.LaserSightRotation)

				locals.End = calculateBulletTraceEndPoint()
				print("end after ", locals.End)
				
				--obj.BulletTraceEndPoints = {}
				--table.insert(obj.BulletTraceEndPoints, locals.End)
				--if activeWeaponWeapon ~= nil and activeWeaponWeapon.Projectile ~= nil then
				--	print("projectile ", activeWeaponWeapon.Projectile:get_full_name())
				--end
			end,
		true)
		
		onBulletTraceHooked = true
	end
	if fireSingleMuzzleHooked == false then
		hook_function("BlueprintGeneratedClass /Game/Blueprints/Weapons/WeaponGunBaseVFXComponent_BP.WeaponGunBaseVFXComponent_BP_C", "FireSingleMuzzle", false,
			function(fn, obj, locals, result)
				print("FireSingleMuzzle started")
				--print("obj.LaserSightEndPoint", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation", obj.LaserSightRotation)
				--print("obj.BulletTraceEndPoints", #obj.BulletTraceEndPoints)
				print("obj.LastRotation", obj.LastRotation)
				--print("obj[Spawned Bullet Line]", obj["Spawned Bullet Line"])
				
				obj.LaserSightEndPoint = calculateBulletTraceEndPoint()
				obj.LaserSightRotation = controllers.getControllerRotation(1)
				--print("obj.LaserSightEndPoint after", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation after", obj.LaserSightRotation)
				--if activeWeaponWeapon ~= nil and activeWeaponWeapon.Projectile ~= nil then
				--	print("projectile ", activeWeaponWeapon.Projectile:get_full_name())
				--end
			end,
			function(fn, obj, locals, result)
				print("FireSingleMuzzle ended")
				--print("obj.LaserSightEndPoint", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation", obj.LaserSightRotation)
				--print("obj.BulletTraceEndPoints", #obj.BulletTraceEndPoints)
				print("obj.LastRotation", obj.LastRotation)
				--print("obj[Spawned Bullet Line]", obj["Spawned Bullet Line"])

				obj.LaserSightEndPoint = calculateBulletTraceEndPoint()
				obj.LaserSightRotation = controllers.getControllerRotation(1)
				--print("obj.LaserSightEndPoint after", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation after", obj.LaserSightRotation)
				--if activeWeaponWeapon ~= nil and activeWeaponWeapon.Projectile ~= nil then
				--	print("projectile ", activeWeaponWeapon.Projectile:get_full_name())
				--end
			end,
		true)
		
		fireSingleMuzzleHooked = true
	end]]
	--[[if onReceiveTickHooked == false then
		hook_function("BlueprintGeneratedClass /Game/Blueprints/Weapons/WeaponGunBaseVFXComponent_BP.WeaponGunBaseVFXComponent_BP_C", "ReceiveTick", false,
			function(fn, obj, locals, result)
				print("ReceiveTick started")
				--print("obj.LaserSightEndPoint", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation", obj.LaserSightRotation)
				--print("obj.BulletTraceEndPoints", obj.BulletTraceEndPoints)
				print("obj.LastRotation", obj.LastRotation)
				--print("obj[Spawned Bullet Line]", obj["Spawned Bullet Line"])
				
				obj.LaserSightEndPoint = calculateBulletTraceEndPoint()
				obj.LaserSightRotation = controllers.getControllerRotation(1)
				--print("obj.LaserSightEndPoint after", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation after", obj.LaserSightRotation)
			end,
			function(fn, obj, locals, result)
				print("ReceiveTick ended")
				--print("obj.LaserSightEndPoint", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation", obj.LaserSightRotation)
				--print("obj.BulletTraceEndPoints", obj.BulletTraceEndPoints)
				print("obj.LastRotation", obj.LastRotation)
				--print("obj[Spawned Bullet Line]", obj["Spawned Bullet Line"])

				obj.LaserSightEndPoint = calculateBulletTraceEndPoint()
				obj.LaserSightRotation = controllers.getControllerRotation(1)
				--print("obj.LaserSightEndPoint after", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation after", obj.LaserSightRotation)
			end,
		true)
		
		onReceiveTickHooked = true
	end]]
	--[[if onFirePressedHooked == false then
		hook_function("Class /Script/TheAscent.TheAscentWeaponVFXComponent", "OnFirePressed", true,
			function(fn, obj, locals, result)
				print("OnFirePressed started")
				print("end before ", locals.End)
				--print("obj.LaserSightEndPoint", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation", obj.LaserSightRotation)
				--print("obj.BulletTraceEndPoints", obj.BulletTraceEndPoints)
				print("obj.LastRotation", obj.LastRotation)
				--print("obj[Spawned Bullet Line]", obj["Spawned Bullet Line"])
				
				obj.LaserSightEndPoint = calculateBulletTraceEndPoint()
				obj.LaserSightRotation = controllers.getControllerRotation(1)
				--print("obj.LaserSightEndPoint after", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation after", obj.LaserSightRotation)
				locals.End = calculateBulletTraceEndPoint()
				print("end after ", locals.End)
			end,
			function(fn, obj, locals, result)
				print("OnFirePressed ended")
				print("end before ", locals.End)
				--print("obj.LaserSightEndPoint", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation", obj.LaserSightRotation)
				--print("obj.BulletTraceEndPoints", obj.BulletTraceEndPoints)
				print("obj.LastRotation", obj.LastRotation)
				--print("obj[Spawned Bullet Line]", obj["Spawned Bullet Line"])
				
				obj.LaserSightEndPoint = calculateBulletTraceEndPoint()
				obj.LaserSightRotation = controllers.getControllerRotation(1)
				--print("obj.LaserSightEndPoint after", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation after", obj.LaserSightRotation)

				locals.End = calculateBulletTraceEndPoint()
				print("end after ", locals.End)
			end,
		true)
		
		onFirePressedHooked = true
	end]]
end


--[[function hookFuntionsForRuntimeGeneratedClasses() 
	if fireSingleMuzzleHooked == false then
		hook_function("BlueprintGeneratedClass /Game/Blueprints/Weapons/WeaponGunBaseVFXComponent_BP.WeaponGunBaseVFXComponent_BP_C", "FireSingleMuzzle", false,
			function(fn, obj, locals, result)
				print("FireSingleMuzzle started")
				--print("obj.LaserSightEndPoint", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation", obj.LaserSightRotation)
				--print("obj.BulletTraceEndPoints", obj.BulletTraceEndPoints)
				print("obj.LastRotation", obj.LastRotation)
				--print("obj[Spawned Bullet Line]", obj["Spawned Bullet Line"])
				
				obj.LaserSightEndPoint = calculateBulletTraceEndPoint()
				obj.LaserSightRotation = controllers.getControllerRotation(1)
				--print("obj.LaserSightEndPoint after", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation after", obj.LaserSightRotation)
			end,
			function(fn, obj, locals, result)
				print("FireSingleMuzzle ended")
				--print("obj.LaserSightEndPoint", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation", obj.LaserSightRotation)
				--print("obj.BulletTraceEndPoints", obj.BulletTraceEndPoints)
				print("obj.LastRotation", obj.LastRotation)
				--print("obj[Spawned Bullet Line]", obj["Spawned Bullet Line"])

				obj.LaserSightEndPoint = calculateBulletTraceEndPoint()
				obj.LaserSightRotation = controllers.getControllerRotation(1)
				--print("obj.LaserSightEndPoint after", obj.LaserSightEndPoint)
				print("obj.LaserSightRotation after", obj.LaserSightRotation)
			end,
		true)
		
		fireSingleMuzzleHooked = true
	end
end]]


function calculateBulletTraceEndPoint()
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
			return string.find(player.PlayerCameraManager.ViewTarget.Target:get_full_name(), "CineCameraActor")
		end
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

	hands.hideHands(true)
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
	if pawn ~= nil and pawn.charactercircle ~= nil then
		pawn.charactercircle:SetVisibility(true)
		pawn.charactercircle:SetRenderInMainPass(true)
		pawn.charactercircle:SetRenderCustomDepth(true)
	end
	if pawn ~= nil and pawn.BodyParts ~=nil then
		for _, mesh in pairs(pawn.BodyParts) do	
			mesh:SetVisibility(true)
			mesh:SetRenderInMainPass(true)
			mesh:SetRenderCustomDepth(true)
			mesh:SetCastShadow(true)
		end
	end
	
	UEVR_UObjectHook.set_disabled(true)
	
	pcall(disconnectPreviousWeapon, currentWeapon, hand)
	pcall(restoreEquippedWeaponAttachmentSettings, activeWeapon)
	--pcall(toogleActiveWeaponVisibility, false)
	--attachCurrentWeaponToPawn()
	hands.hideHands(true)
end

function toogleActiveWeaponVisibility(enable)
	if activeWeapon ~= nil then
		activeWeapon:SetRenderInMainPass(enable)
		activeWeapon:SetRenderCustomDepth(enable)
		if activeWeaponLight~= nil then
			activeWeaponLight:SetRenderInMainPass(enable)
			activeWeaponLight:SetRenderCustomDepth(enable)
		end
	end
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
	if pawn ~= nil and pawn.charactercircle ~= nil then
		pawn.charactercircle:SetVisibility(true)
		pawn.charactercircle:SetRenderInMainPass(false)
		pawn.charactercircle:SetRenderCustomDepth(false)
	end
	if pawn ~= nil and pawn.BodyParts ~=nil then
		for _, mesh in pairs(pawn.BodyParts) do	
			--if not string.find(mesh:get_full_name(), "Leg") then
				mesh:SetVisibility(true)
				mesh:SetRenderInMainPass(false)
				mesh:SetRenderCustomDepth(false)
				mesh:SetCastShadow(true)
			--end
		end
	end
	normalPlay = isRegularPlay()
	if normalPlay == true then
		--fixShooting()
		--fixCurrentProjectiles()
	end
	pcall(toogleActiveWeaponVisibility, true)
	--findCurrentCameraSpringArms()
	pcall(fixDirection)
	hands.hideHands(false)
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
	if pawn ~= nil and pawn.charactercircle ~= nil then
		pawn.charactercircle:SetVisibility(true)
		pawn.charactercircle:SetRenderInMainPass(true)
		pawn.charactercircle:SetRenderCustomDepth(true)
	end
	if pawn ~= nil and pawn.BodyParts ~=nil then
		for _, mesh in pairs(pawn.BodyParts) do	
			mesh:SetVisibility(true)
			mesh:SetRenderInMainPass(true)
			mesh:SetRenderCustomDepth(true)
			mesh:SetCastShadow(true)
		end
	end
	
	UEVR_UObjectHook.set_disabled(true)
	pcall(disconnectPreviousWeapon, activeWeapon, hand)
	--pcall(toogleActiveWeaponVisibility, false)
	pcall(restoreEquippedWeaponAttachmentSettings, activeWeapon)

	--attachCurrentWeaponToPawn()
	hands.hideHands(true)
	
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
	local player = api:get_player_controller(0)
	if player ~= nil then  
		--print(player:IsMoveInputIgnored())
		if not player:CanMove() or not player:CanInput() or player:IsMoveInputIgnored() or player.bIsInUI then
			return false
		end
	end
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		--if pawn.CharacterMovement ~= nil then
		--	if pawn.CharacterMovement.bJustTeleported == true then --pause menu
		--		return false
		--	end	
		--end
		--local talkingtoNpc = false
		--pawn:BPI_IsTalkingToNPC(talkingtoNpc)
		--print(talkingtoNpc)
		--print(pawn.StateMachine:GetState():get_full_name())
		return pawn.bIsInJournal == false --and talkingtoNpc == false --and pawn.StateMachine:IsInState(4) == false -- 4 == Interacting
	end
end

--Shooting fix attempts section start

hook_function("Class /Script/Engine.SceneComponent", "K2_SetWorldRotation", true, 
	function(fn, obj, locals, result)
		if string.find(obj:get_full_name(), "LowAimPoint") then
			print("found LowAimPoint")
		end
	end,
	function(fn, obj, locals, result)
		if string.find(obj:get_full_name(), "LowAimPoint") then
			print("found LowAimPoint")
		end
	end,
true)



local function subtract(a, b)
    return { X = a.X - b.X, Y = a.Y - b.Y, Z = a.Z - b.Z }
end

local function magnitude(v)
    return math.sqrt(v.X*v.X + v.Y*v.Y + v.Z*v.Z)
end

local reloadGripOn = false
local function detectReload(state, hand, continuous)
	local gripButton = XINPUT_GAMEPAD_LEFT_SHOULDER
	if hand == Handed.Left then
		gripButton = XINPUT_GAMEPAD_RIGHT_SHOULDER
	end
	if (continuous == true or not reloadGripOn) and uevrUtils.isButtonPressed(state, gripButton) then
		reloadGripOn = true
		local gripLocation = controllers.getControllerLocation(1-hand)
		local targetLocation = controllers.getControllerLocation(hand)
		--change to location of magwell
		if gripLocation ~= nil and targetLocation ~= nil then
			local distance = magnitude(subtract(gripLocation, targetLocation))
			--print(distance)
			--only reload if one hand is close to the other when grip is pulled
			if distance < 20 then
				return true
			end
		end
	elseif reloadGripOn and uevrUtils.isButtonNotPressed(state, gripButton) then
		reloadGripOn = false
	end
	return false
end


--[[uevrUtils.registerMontageChangeCallback(function(montage, montageName)
    if montageName ~= nil then
        print("montageName", montageName)
    end
	if string.find(montageName, "Reload") then
		reloadMontageInProgress = true
	else
		reloadMontageInProgress = false
	end
end)]]

function fixCurrentProjectiles()
	if currentProjectiles ~= nil then
		for _, obj in pairs(currentProjectiles) do
			if obj ~= nil then
				local muzzleRotator = activeWeapon:GetSocketRotation("Barrel")
				--local muzzleRotator = activeWeapon:K2_GetComponentRotation()
				--magmamaker (FlamethrowerWeapon_BP_C), overwhelmer (HMGExplosiveWeapon_BP_C), EBR enforcer (Burst_Energy), ABR Commander (AR_Burst_Mk1_Weapon)
				if string.find(obj:get_full_name(),"Burst_Energy") or string.find(obj:get_full_name(),"HMGExplosiveProjectile") or string.find(obj:get_full_name(),"Burst_Base_Projectile") then						
					muzzleRotator.Yaw = muzzleRotator.Yaw +90
				else --flamethrower
				end
				local targetLocation = kismet_math_library:GetForwardVector(muzzleRotator)
				--[[local endPoint = activeWeapon:GetForwardVector()
				if endPoint ~= nil then
					targetLocation = Vector3f.new(
					targetLocation.X * 8192.0,
					targetLocation.Y * 8192.0,
					targetLocation.Z * 8192.0)
				end]]
				--print("fixing current projectile", obj:get_full_name())
				obj.ProjectileMovementComponent.Velocity.X = targetLocation.X * obj.ProjectileMovementComponent.InitialSpeed 
				obj.ProjectileMovementComponent.Velocity.Y = targetLocation.Y * obj.ProjectileMovementComponent.InitialSpeed 
				obj.ProjectileMovementComponent.Velocity.Z = targetLocation.Z * obj.ProjectileMovementComponent.InitialSpeed 
			end
		end
	end
	--local pawn = api:get_local_pawn(0)
	--if pawn.EquippedWeapon ~= nil and pawn.EquippedWeapon.ExtenderComponent ~= nil and pawn.EquippedWeapon.ExtenderComponent.MuzzelLight ~= nil then
	--	pawn.EquippedWeapon.ExtenderComponent.MuzzelLight:SetRenderCustomDepth(false)
	--	pawn.EquippedWeapon.ExtenderComponent.MuzzelLight:SetRenderCustomDepth(false)
	--end
end

function fixShooting()
	local pawn = api:get_local_pawn(0)
	if activeWeaponWeapon ~= nil and activeWeaponWeapon.WeaponVFXComp ~= nil and activeWeaponWeapon.WeaponVFXComp.BulletTraceEndPoints~=nil then -- and #activeWeaponWeapon.WeaponVFXComp.BulletTraceEndPoints >0 then
		print("replace trace")
		activeWeaponWeapon.WeaponVFXComp.BulletTraceEndPoints[0] = calculateBulletTraceEndPoint()
	end
	--[[if activeWeapon ~= nil and pawn ~= nil and pawn.AimLowPoint ~= nil then
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
	end]]
	
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

hook_function("Class /Script/TheAscent.TheAscentWeaponUser", "CalculateLaserEndPoint", false, --Calculates where the laser ends up
	function(fn, obj, locals, result)
		--print("CalculateLaserEndPoint started")
		--print("original result", result)
		--[[if hand == Handed.Right then
			result = controllers.getControllerRotation(1)
			--print("changed result", result)
			return controllers.getControllerRotation(1)
		else
			result = controllers.getControllerRotation(0)
			return controllers.getControllerRotation(0)
		end]]
		--result = controllers.getControllerRotation(1)
		--result = {0,0,0}
		--if activeWeaponWeapon ~= nil and activeWeaponWeapon.Projectile ~= nil then
		--	print("projectile ", activeWeaponWeapon.Projectile:get_full_name())
		--end
	end,
	function(fn, obj, locals, result)
		--print("CalculateLaserEndPoint ended")
		--print("original result", result)
		--activeWeaponWeapon.LaserSightPoint.RelativeRotation = controllers.getControllerRotation(1)
		--[[if hand == Handed.Right then
			result = controllers.getControllerRotation(1)
			--print("changed result", result)
			return controllers.getControllerRotation(1)
		else
			result = controllers.getControllerRotation(0)
			return controllers.getControllerRotation(0)
		end]]
		--result = controllers.getControllerRotation(1)
		--result = {0,0,0}
		--if activeWeaponWeapon ~= nil and activeWeaponWeapon.Projectile ~= nil then
		--	print("projectile ", activeWeaponWeapon.Projectile:get_full_name())
		--end
	end,
true)

hook_function("Class /Script/TheAscent.TheAscentWeaponUser", "CalculateAimEndPoint", false, --Determines where shots actually hit - not sure if need to hook it at all, seems like hooking CalculateLaserEndPoint will be enough, as shots seem to hit where laser ends...
	function(fn, obj, locals, result)
		--print("CalculateAimEndPoint started")
		--print("original result", result)
		--activeWeaponWeapon.LaserSightPoint.RelativeRotation = controllers.getControllerRotation(1)
		--[[if hand == Handed.Right then
			result = controllers.getControllerRotation(1)
			--print("changed result", result)
			return controllers.getControllerRotation(1)
		else
			result = controllers.getControllerRotation(0)
			return controllers.getControllerRotation(0)
		end]]
		--result = controllers.getControllerRotation(1)
		--result = {0,0,0}
		--if activeWeaponWeapon ~= nil and activeWeaponWeapon.Projectile ~= nil then
		--	print("projectile ", activeWeaponWeapon.Projectile:get_full_name())
		--end
	end,
	function(fn, obj, locals, result)
		--print("CalculateAimEndPoint ended")
		--print("original result", result)
		--activeWeaponWeapon.LaserSightPoint.RelativeRotation = controllers.getControllerRotation(1)
		--[[if hand == Handed.Right then
			result = controllers.getControllerRotation(1)
			--print("changed result", result)
			return controllers.getControllerRotation(1)
		else
			result = controllers.getControllerRotation(0)
			return controllers.getControllerRotation(0)
		end]]
		--result = controllers.getControllerRotation(1)
		--result = {0,0,0}
		--if activeWeaponWeapon ~= nil and activeWeaponWeapon.Projectile ~= nil then
		--	print("projectile ", activeWeaponWeapon.Projectile:get_full_name())
		--end
	end,
true)



hook_function("Class /Script/TheAscent.TheAscentWeaponUser", "OnWeaponFireStarted", false, 
	function(fn, obj, locals, result)
		--print("OnWeaponFireStarted started")
		--print("original result", result)
		--activeWeaponWeapon.LaserSightPoint.RelativeRotation = controllers.getControllerRotation(1)
		--activeWeaponWeapon.LaserSightPoint.RelativeRotation = controllers.getControllerRotation(1)
		--if hand == Handed.Right then
			--result = controllers.getControllerRotation(1)
			--print("changed result", result)
			--return controllers.getControllerRotation(1)
		--else
			--result = controllers.getControllerRotation(0)
			--return controllers.getControllerRotation(0)
		--end
		--if activeWeaponWeapon ~= nil and activeWeaponWeapon.Projectile ~= nil then
		--	print("projectile ", activeWeaponWeapon.Projectile:get_full_name())
		--end
	end,
	function(fn, obj, locals, result)
		--print("OnWeaponFireStarted ended")
		--print("original result", result)
		--activeWeaponWeapon.LaserSightPoint.RelativeRotation = controllers.getControllerRotation(1)
		--activeWeaponWeapon.LaserSightPoint.RelativeRotation = controllers.getControllerRotation(1)
		--if hand == Handed.Right then
			--result = controllers.getControllerRotation(1)
		--	print("changed result", result)
		--	return controllers.getControllerRotation(1)
		--else
		--	result = controllers.getControllerRotation(0)
		--	return controllers.getControllerRotation(0)
		--end
		--if activeWeaponWeapon ~= nil and activeWeaponWeapon.Projectile ~= nil then
		--	print("projectile ", activeWeaponWeapon.Projectile:get_full_name())
		--end
	end,
true)


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
			currentCameraSpringArm.RelativeRotation = {Pitch=-40, Roll = 0, Yaw= -45}
			currentCameraSpringArm.bInheritPitch = originalCameraSpringArmBInheritPitch
			currentCameraSpringArm.bInheritRoll = originalCameraSpringArmBInheritRoll
			currentCameraSpringArm.bInheritYaw = originalCameraSpringArmBInheritYaw
		end
	end
end 

function findCurrentCameraSpringArms()
	local val = false
    local springArms = uevrUtils.find_all_instances("Class /Script/Engine.SpringArmComponent", true)
	if springArms ~= nil then
		for _, springArm in pairs(springArms) do
			if string.find(springArm:get_full_name(), "CoopCamera_C") and not string.find(springArm:get_full_name(), "Default") then
				--print(springArm:get_full_name())	
				if string.find(springArm:get_full_name(), "CameraSpringArm") then
					currentCameraSpringArm = springArm
					currentCameraSpringArm.bInheritPitch = false
					currentCameraSpringArm.bInheritRoll = false
					currentCameraSpringArm.bInheritYaw = false
					currentCameraSpringArmTargetArmLength = springArm.TargetArmLength
					--currentCameraSpringArm.bUsePawnControlRotation = true 
				end
				--break
			end
		end
	end
end

function findCurrentProjectileMovementComponent()
	local val = false
    local movementSystems = uevrUtils.find_all_instances("Class /Script/Engine.ProjectileMovementComponent", true)
	-- Class /Script/TheAscent.TAProjectileMovementComponent
	if movementSystems ~= nil then
		--TAProjectileMovementComponent /Script/TheAscent.Default__TAProjectileBase.ProjectileMovementComponent
		--TAProjectileMovementComponent /Game/Blueprints/Projectiles/BaseProjectile_BP.Default__BaseProjectile_BP_C.ProjectileMovementComponent
		for _, movementSystem in pairs(movementSystems) do
			if string.find(movementSystem:get_full_name(), "Default__TAProjectileBase.ProjectileMovementComponent") then
			--print(movementSystem:get_full_name())	
				currentProjectileMovementComponent = movementSystem
				--if currentProjectileMovementComponent.bRotationFollowsVelocity == false then
					--print("enable currentProjectileMovementComponent.bRotationFollowsVelocity")
					--currentProjectileMovementComponent.bRotationFollowsVelocity = true
				--end			
				--break
			end
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
			if player.PlayerCameraManager.ViewTarget.Target ~= nil and player.PlayerCameraManager.ViewTarget.Target ~= pawn and not string.find(player.PlayerCameraManager.ViewTarget.Target:get_full_name(), "CineCameraActor") then
				lastFixedCamera = player.PlayerCameraManager.ViewTarget.Target
				
				player.PlayerCameraManager.ViewTarget.Target = pawn
			end		
		end
	end
end

function applyLastFixedCamera()
	print("applying last fixed camera")
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
					pawn.CharacterMovement.MaxWalkSpeed = 3000.0
					if configui.getValue("walk_speed") ~= nil and configui.getValue("run_speed_multiplier") ~= nil then
						pawn.CharacterMovement.MaxWalkSpeed = configui.getValue("walk_speed") * configui.getValue("run_speed_multiplier")
					end
					
				else
					pawn.CharacterMovement.MaxWalkSpeed = 1500.0
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
				local speed = 6
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
			local speed = 6
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
			--if canMoveActorToLocation(currentLocation, newLocation) then
				local success = pcall(setActorLocation, newLocation)
				--if success == false then
				--	pcall(setActorLocation, currentLocation)
				--end
			--end
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
			--pawn:K2_SetActorRotation(newRotation)
			pcall(setActorRotation, newRotation)
			triggerPawnMovement()
		end
	end
end

--"Enhanced Movement" section end


uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
	if (state ~= nil) then
		--[[if detectReload(state, Handed.Left) then
			print("Reload gesture detected")
			state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_LEFT_SHOULDER
			-- Reload weapon logic here - press square
			state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_X
		end]]
		
		if state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER ~= 0 and state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER ~= 0 then
				state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_LEFT_SHOULDER
				state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_RIGHT_SHOULDER
				params.vr.recenter_view()
		end
		
		if normalPlay == true then
			--switch run to toggle left thumb stick
			if not runToggled then
				if state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB ~= 0 and state.Gamepad.sThumbLY > 10000 then
					--state.Gamepad.bLeftTrigger = 30000
					runToggled = true
					--print("runToggled")
				end	
			else
				if state.Gamepad.sThumbLY < 10000  then
					runToggled = false
					--print("runToggled end")
				else -- run is toggled
					--state.Gamepad.bLeftTrigger = 30000
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
			end
			
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