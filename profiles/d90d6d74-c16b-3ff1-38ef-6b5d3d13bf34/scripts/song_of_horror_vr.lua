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
local activeWeaponLight = nil
local activeWeaponOriginalParent = nil
local activeWeaponOriginalParentSocket = nil
local activeWeaponOriginalRelativeRotation= {}
local activeWeaponOriginalRelativeLocation= {}

local runToggled = false

local isStairsCinematicsFix = false


local needToApply2dSettings = false
local in2dMode = false

local fixedCameras3rdPersonMode = false
local fixedCameras3rdPersonModeJustChanged = false

local lastFixedCamera = nil

local viewTargetTransitionParams_c = uevrUtils.find_required_object("ScriptStruct /Script/Engine.ViewTargetTransitionParams")
local empty_viewTargetTransitionParams = StructObject.new(viewTargetTransitionParams_c)
local hitresult_c = uevrUtils.find_required_object("ScriptStruct /Script/Engine.HitResult")
local empty_hitresult = StructObject.new(hitresult_c)

local configDefinition = {
	{
		panelLabel = "Song Of Horror VR", 
		saveFile = "user_configuration", 
		layout = {
			{
				widgetType = "text",
				label = "=== Accessibility ===",
			},
			{
				widgetType = "checkbox",
				id = "enable_prononocued_interaction_widget",
				label = "Prononounced Interaction Icon",
				initialValue = true
			},	
			{
				widgetType = "text",
				label = "=== Enahnced Movement ===",
			},
			{
				widgetType = "slider_int",
				id = "walk_speed",
				label = "Walk Speed",
				initialValue = 115,
				range = {"10", "300"}
			},
			{
				widgetType = "slider_float",
				id = "turn_speed",
				label = "Turn Speed",
				initialValue = 0.17,
				range = {"0.05", "0.50"}
			},
			{
				widgetType = "slider_float",
				id = "run_speed_multiplier",
				label = "Run speed muliplier (walk speed * multipler = run speed)",
				initialValue = 2,
				range = {"0", "3"}
			},
			{
				widgetType = "slider_int",
				id = "strafe_speed",
				label = "Strafing Speed",
				initialValue = 3,
				range = {"1", "6"}
			},
			{
				widgetType = "slider_int",
				id = "move_back_speed",
				label = "Move back speed",
				initialValue = 3,
				range = {"1", "6"}
			},
		}
	}
}

configui.create(configDefinition)

function on_level_change(level)
	fix_interaction_icon()
	--alwaysShowRegularIcons()
	initHands()
end

function isMale()
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		if string.find(pawn:get_full_name(), "Daniel") or string.find(pawn:get_full_name(), "Etienne") or string.find(pawn:get_full_name(), "Alexander") or string.find(pawn:get_full_name(), "Artigas") or string.find(pawn:get_full_name(), "Omar") or string.find(pawn:get_full_name(), "Ernest") then
			return true
		end
	end
	return false
end

function isFemale()
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		if string.find(pawn:get_full_name(), "Alina") or string.find(pawn:get_full_name(), "Sophie") or string.find(pawn:get_full_name(), "Erica") or string.find(pawn:get_full_name(), "Berenice") or string.find(pawn:get_full_name(), "Grace") or string.find(pawn:get_full_name(), "Lidia") then
			return true
		end
	end
	return false
end

function initHands() 
	controllers.createController(0)
	controllers.createController(1)
	hands.reset()
	local paramsFile = 'hands_parameters' -- found in the [game profile]/data directory
	if isMale() then
		print("init hands male")
		local configName = 'Main' -- the name you gave your config
		local animationName = 'Shared' -- the name you gave your animation
		hands.createFromConfig(paramsFile, configName, animationName)
	elseif isFemale() then
		print("init hands female")
		local configName = 'MainFemale' -- the name you gave your config
		local animationName = 'SharedFemale' -- the name you gave your animation
		hands.createFromConfig(paramsFile, configName, animationName)
	end
end

function isLightSourceAvailable()
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		if string.find(pawn:get_full_name(), "Daniel") or string.find(pawn:get_full_name(), "Alina")  or string.find(pawn:get_full_name(), "Artigas") then
			if pawn.Linterna ~=nil then
				if pawn.Linterna.SM_Linterna ~= nil then
					return not pawn.Linterna.SM_Linterna.bHiddenInGame
				end
			end
		elseif string.find(pawn:get_full_name(), "Etienne") or string.find(pawn:get_full_name(), "Erica") or string.find(pawn:get_full_name(), "Omar") then
			if pawn.Mechero ~=nil then
				if pawn.Mechero.SM_Vela ~= nil then
					return not pawn.Mechero.SM_Vela.bHiddenInGame
				end
			end
		elseif string.find(pawn:get_full_name(), "Alexander") or string.find(pawn:get_full_name(), "Sophie") or string.find(pawn:get_full_name(), "Ernest") or string.find(pawn:get_full_name(), "Berenice") then
			if pawn.Vela ~=nil then
				if pawn.Vela.SM_Vela ~= nil then
					return not pawn.Vela.SM_Vela.bHiddenInGame
				end
			end
		end
	end
end


function on_xinput_get_state(retval, user_index, state)
	if hands.exists() then
		local isHoldingWeapon = isLightSourceAvailable()
		hands.handleInput(state, isHoldingWeapon, hand)
	end
end

uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
	if normalPlay then	
		local currentWeapon = nil 
		if isLightSourceAvailable() then
			local pawn = api:get_local_pawn(0)
			if pawn ~= nil then
				if string.find(pawn:get_full_name(), "Daniel") or string.find(pawn:get_full_name(), "Alina") or string.find(pawn:get_full_name(), "Artigas") then
					if pawn.Linterna ~=nil then
						if pawn.Linterna.SM_Linterna ~= nil then
							currentWeapon = pawn.Linterna.SM_Linterna
							activeWeaponLight = nil
						end
					end
				elseif string.find(pawn:get_full_name(), "Etienne") or string.find(pawn:get_full_name(), "Erica") or string.find(pawn:get_full_name(), "Omar") then
					if pawn.Mechero ~=nil then
						if pawn.Mechero.SM_Vela ~= nil then
							if pawn.Mechero.SM_LlamaVela ~= nil then
								pawn.Mechero.SM_LlamaVela:K2_AttachTo(pawn.Mechero.SM_Vela, "", 0, false)
							end
							currentWeapon = pawn.Mechero.SM_Vela
							activeWeaponLight = pawn.Mechero.SM_LlamaVela
						end
					end
				elseif string.find(pawn:get_full_name(), "Alexander") or string.find(pawn:get_full_name(), "Sophie") or string.find(pawn:get_full_name(), "Ernest") or string.find(pawn:get_full_name(), "Berenice") then
					if pawn.Vela ~=nil then
						if pawn.Vela.SM_Vela ~= nil then
							if pawn.Vela.SM_LlamaVela ~= nil then
								pawn.Vela.SM_LlamaVela:K2_AttachTo(pawn.Vela.SM_Vela, "", 0, false)
								activeWeaponLight = pawn.Vela.SM_LlamaVela
							end
							currentWeapon = pawn.Vela.SM_Vela
						end
					end
				end
			end
		end
		updateEquippedWeapon(currentWeapon , hand)	
	end
end)

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
		
		if string.find(currentWeapon:get_full_name(), "Linterna") then
			if isMale() then
				state:set_rotation_offset(Vector3f.new(-0.907, 2.877, -3.088))
				state:set_location_offset(Vector3f.new(6.199, -1.153, 9.506)) --forward , up, right	
			else 
				state:set_rotation_offset(Vector3f.new(-1.026, -2.903, 2.869))
				state:set_location_offset(Vector3f.new(-1.348, -3.579, 11.886)) --forward , up, right	
			end
			
		elseif string.find(currentWeapon:get_full_name(), "Mechero") then
			if isMale() then
				state:set_rotation_offset(Vector3f.new(1.067, 2.848, -0.530))
				state:set_location_offset(Vector3f.new(-4.460, 3.002, 9.480)) --forward , up, right
			else
				
			end
		elseif string.find(currentWeapon:get_full_name(), "Vela") then
			if isMale() then
				state:set_rotation_offset(Vector3f.new(0.548, -0.072, 0.362))
				state:set_location_offset(Vector3f.new(0.223, 3.855, -10.839)) --forward , up, right	
			else
				state:set_rotation_offset(Vector3f.new(0.734, 2.526, -0.180))
				state:set_location_offset(Vector3f.new(5.284, 6.909, 10.002)) --forward , up, right	
			end
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
		local state = UEVR_UObjectHook.get_or_add_motion_controller_state(currentWeapon)
		UEVR_UObjectHook.remove_motion_controller_state(activeWeapon)
	end
end

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	if isMainMenu() then
		applyMainMenuSettings()
		needToApply2dSettings = false
	elseif isMapDisplayed() or isStairsCinematicsFix == true then
		applyInGame2dSettings()
		needToApply2dSettings = true
	
	elseif fixedCameras3rdPersonMode == true or isSolvingPuzzles()  then
		--print("apply 3rd")
		applyFixedCameras3rdPersonModeSettings()
		needToApply2dSettings = false
	elseif isInCutScene() or isInAutomaticCameraSwitchInteractions() then
		applyCinematicSettings()
		needToApply2dSettings = false
	--elseif isStairsCinematicsFix == true then
	--	needToApply2dSettings = true
	else --if isStairsCinematicsFix == false then --regular play
		needToApply2dSettings = false
		if not hands.exists() then
			initHands()
		end
		applyNormalModeSettings(delta)
	end	
end)


function isMainMenu()
	local pawn = api:get_local_pawn(0)
	return pawn == nil	
end

function isMouseCursorActive() --pause or inventory
    local player = api:get_player_controller(0)
    if player ~= nil then
        if player.bShowMouseCursor == true then
            return true
        end
    end
    return false
end

function isMapDisplayed()
	local player = api:get_player_controller(0)
	if player ~= nil then 
		if player.MyHUD ~= nil then
			if player.MyHUD.MapaAbierto ~= nil and player.MyHUD.MapaAbierto == true then
				--print("map")
				return true
			end
		end
	end
end

function isInventoryOrDocumentsDisplayed()
	local player = api:get_player_controller(0)
	if player ~= nil then --invenoty/documents open
		if player.MyHUD ~= nil then
			if player.MyHUD.InGameHUDAbierto ~= nil and player.MyHUD.InGameHUDAbierto == true then
				--print("inventory")
				return true
			end
		end
	end
end

function isInAutomaticCameraSwitchInteractions()
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		return pawn.UsandoCamaraInteraccion == true  --interactions that force the camera to change
	end
	return false
end

function isSolvingPuzzles()
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		return pawn.PersonajePulsandoInterruptor == true or 
		pawn.PersonajeRecogiendoBolsaCadaver == true or 
		pawn.PersonajeRecogiendoObjetoRec == true or 
		pawn.PersonajeResolviendoPuzzle == true or 
		pawn.PersonajeResolviendoPuzzle_EnCamaraMovil == true
	end
	return false

end

function isInCutScene()
	local player = api:get_player_controller(0)
	--[[if player.bInputEnabled == false then
		print("bInputDisabled")
		return true
	end	
	local pawn = api:get_local_pawn(0)
	if pawn.CharacterMovement.MovementState ~= nil then
		if pawn.CharacterMovement.MovementState.bCanWalk == false then
			print("char can't walk")
			return false
		end
	end]]
	if player ~= nil then 
		success, result = pcall(checkInGamePlayCinematic)
		if success == true then
			if result == true then
				if isOnStairs() then
					isStairsCinematicsFix = true
					print("stairs fix enabled")
				end
				return true
			else
				if isStairsCinematicsFix == true then --out of cinematics but sill on stairs, fix needed
					--[[local pawn = api:get_local_pawn(0)
					if pawn ~= nil then
						if pawn.CharacterMovement ~= nil and pawn.CharacterMovement.bMovementInProgress == true then -- pawn started moving, turn it by 180 degrees
							local newRotation = pawn:K2_GetActorRotation()
						newRotation.Yaw = newRotation.Yaw +45

						-- applying fix by rotating pawn by 180 degrees so hee can walk downstairs instead of upstairs
						pawn:K2_SetActorRotation(newRotation)
						isStairsCinematicsFix = false
						print("stairs fix done")	
						end
					end]]
					if not isOnStairs() then
						--print("stairs fix disabled because the pawn is no longer on stairs")	
						isStairsCinematicsFix = false
					end
					return true
				end
			end
		end
        if player.PlayerCameraManager ~= nil and player.PlayerCameraManager.ViewTarget ~= nil and player.PlayerCameraManager.ViewTarget.Target ~= nil then                    
			return string.find(player.PlayerCameraManager.ViewTarget.Target:get_full_name(), "CineCameraActor")
		end
	end
	return false
end

function checkInGamePlayCinematic()
	local player = api:get_player_controller(0)
	if player.CinematicaActual ~= nil then
		return player.CinematicaActual.Status == 1
	end
	return false
end

function isOnStairs()
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil and pawn.EnEscaleras ~= nil then
		return pawn.EnEscaleras
	end
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
	if pawn ~= nil and pawn.Mesh ~=nil then		
		pawn.Mesh:SetVisibility(true)
		pawn.Mesh:SetRenderInMainPass(true)
		pawn.Mesh:SetRenderCustomDepth(true)
		pawn.Mesh:SetCastShadow(true)
	end
	
	UEVR_UObjectHook.set_disabled(true)
	--pcall(disconnectPreviousWeapon, currentWeapon, hand)
	restoreEquippedWeaponAttachmentSettings(activeWeapon)

	--pcall(toogleActiveWeaponVisibility, false)
	--attachCurrentWeaponToPawn()
	hands.hideHands(true)
end

function attachCurrentWeaponToPawn() 
	local pawn = api:get_local_pawn(0)
	if activeWeapon ~= nil then
		if string.find(activeWeapon:get_full_name(), "Linterna") then
			if pawn ~= nil and pawn.Linterna ~= nil then 
				activeWeapon:K2_AttachTo(pawn.Linterna, "", 0, false)
			end
			
		elseif string.find(activeWeapon:get_full_name(), "Mechero") then
			if pawn ~= nil and pawn.Mechero ~= nil then 
				activeWeapon:K2_AttachTo(pawn.Mechero, "", 0, false)
				if activeWeaponLight~= nil then
					activeWeaponLight:K2_AttachTo(activeWeapon, "", 0, false)
				end
			end
		elseif string.find(activeWeapon:get_full_name(), "Vela") then
			if pawn ~= nil and pawn.Vela ~= nil then 
				activeWeapon:K2_AttachTo(pawn.Vela, "", 0, false)
				if activeWeaponLight~= nil then
					activeWeaponLight:K2_AttachTo(activeWeapon, "", 0, false)
				end
			end
		end
	end
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

function applyInGame2dSettings()
	normalPlay = false
	
	
	vr.set_mod_value("VR_2DScreenMode", false)
	--vr.set_mod_value("UI_Distance", 5.0)

	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
				
	vr.set_mod_value("VR_CameraForwardOffset", "1.000000")
	vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	vr.set_mod_value("VR_CameraUpOffset", "5.000000")				
	vr.set_mod_value("VR_LerpCameraYaw", "false")
	
    vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
	
	
	UEVR_UObjectHook.set_disabled(true)

	local pawn = api:get_local_pawn(0)
	if pawn ~= nil and pawn.Mesh ~=nil then		
		pawn.Mesh:SetVisibility(true)
		pawn.Mesh:SetRenderInMainPass(false)
		pawn.Mesh:SetRenderCustomDepth(false)
		pawn.Mesh:SetCastShadow(false)
	end
	hands.hideHands(true)
	
	if isStairsCinematicsFix == true then --out of cinematics but sill on stairs, fix needed
		--print("stairs fix in effect")
		if not isOnStairs() then
			print("stairs fix disabled because the pawn is no longer on stairs")	
			isStairsCinematicsFix = false
		end
		return true
	end
end


function applyNormalModeSettings(delta) 
		
	vr.set_mod_value("VR_2DScreenMode", false)
	--vr.set_mod_value("UI_Distance", 2.0)


	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "1")
	vr.set_mod_value("VR_DecoupledPitch", "1")
	if isInventoryOrDocumentsDisplayed() then
		vr.set_mod_value("VR_CameraForwardOffset", "-10.0000000")
	else
		vr.set_mod_value("VR_CameraForwardOffset", "0.0000000")
	end
	
	vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	vr.set_mod_value("VR_CameraUpOffset", "0.000000")				
	vr.set_mod_value("VR_LerpCameraYaw", "false")

	
    vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
	UEVR_UObjectHook.set_disabled(false)
	
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil and pawn.Mesh ~=nil then			
		normalPlay = isRegularPlay() 
		
		pawn.Mesh:SetVisibility(true)
		pawn.Mesh:SetRenderInMainPass(false)
		pawn.Mesh:SetRenderCustomDepth(false)
		pawn.Mesh:SetCastShadow(false)
	end
	pcall(toogleActiveWeaponVisibility, true)
	
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
	if pawn ~= nil and pawn.Mesh ~=nil then		
		pawn.Mesh:SetVisibility(true)
		pawn.Mesh:SetRenderInMainPass(true)
		pawn.Mesh:SetRenderCustomDepth(true)
		pawn.Mesh:SetCastShadow(true)
	end
	
	UEVR_UObjectHook.set_disabled(true)
	pcall(disconnectPreviousWeapon, currentWeapon, hand)
	--pcall(toogleActiveWeaponVisibility, false)
	--attachCurrentWeaponToPawn()
	restoreEquippedWeaponAttachmentSettings(activeWeapon)
	hands.hideHands(true)
	
	if fixedCameras3rdPersonModeJustChanged and fixedCameras3rdPersonMode == true then --manual switch
		applyLastFixedCamera()
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
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil and pawn.CharacterMovement ~= nil then
		if pawn.CharacterMovement.bJustTeleported == true then --pause menu
			--print("pause")
			return false
		end		
	end
	if pawn ~= nil then 
		if pawn.PuertaActual ~= nil and  pawn.PuedoRecibirSusto == false then --opening door
			return false
		end
	end
	if pawn ~= nil then --and pawnPersonajeInteractuandoConAlgo ~= nil then
		if pawn.MirandoAutomaticamente == true or --Automatic camera/head rotation is being applied
		pawn.PersonajePulsandoInterruptor == true or 
		pawn.PersonajeRecogiendoBolsaCadaver == true or 
		pawn.PersonajeRecogiendoObjetoRec == true or 
		pawn.PersonajeResolviendoPuzzle == true or 
		pawn.PersonajeResolviendoPuzzle_EnCamaraMovil == true then --interacting
			--print("interacting")
			return false
		end
		--[[local currentInteractedWithObject = nil
		local currentInteractedWithDoor = nil
		pawn:ObtieneInteractuablesActuales(currentInteractedWithDoor, currentInteractedWithObject, nil, nil, nil, nil)
		if currentInteractedWithDoor ~= nil then
			print(currentInteractedWithDoor)
		end]]
	end
	if isInventoryOrDocumentsDisplayed() then 
		return false
	end
	--[[local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		return pawn.CanMove or pawn.isDodging
	end]]
	return not isMouseCursorActive()
end


function fixDirection()
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		local player = api:get_player_controller(0)
		if player ~= nil then       
				if player.PlayerCameraManager ~= nil and player.PlayerCameraManager.Owner ~= nil then                    
						--player.PlayerCameraManager.Owner:ClientSetLocation(pawn:K2_GetActorLocation(), pawn:K2_GetActorRotation())
						player.PlayerCameraManager.Owner:ClientSetRotation(pawn:K2_GetActorRotation())
				end
		end
	end
end 


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
				--[[
				-- Store original camera properties before switching
				local originalCamera = player.PlayerCameraManager.ViewTarget ~= nil and player.PlayerCameraManager.ViewTarget.Target or nil
			
				if originalCamera ~= nil then
					-- Save FOV and other properties from original camera
					if originalCamera.FOVAngle ~= nil then
						originalCameraProps.FOV = originalCamera.FOVAngle
					end
					if originalCamera.CameraComponent ~= nil and originalCamera.CameraComponent.FOV ~= nil then
						originalCameraProps.FOV = originalCamera.CameraComponent.FOV
					end
					if originalCamera.PostProcessSettings ~= nil then
						originalCameraProps.PostProcessSettings = originalCamera.PostProcessSettings
					end
				end]]
				if player.PlayerCameraManager.ViewTarget.Target ~= nil and player.PlayerCameraManager.ViewTarget.Target ~= pawn and not string.find(player.PlayerCameraManager.ViewTarget.Target:get_full_name(), "CineCameraActor") then
					lastFixedCamera = player.PlayerCameraManager.ViewTarget.Target
					print("lastFixedCamera: ", lastFixedCamera:get_full_name())
				end
				
				player.PlayerCameraManager.ViewTarget.Target = pawn
				--player.PlayerCameraManager.DefaultFOV = 150.0
				--[[-- Apply the saved camera properties to the PlayerCameraManager
				-- This is crucial for preventing blurriness
				if player.PlayerCameraManager.FOVAngle ~= nil and originalCameraProps.FOV ~= nil then
					player.PlayerCameraManager.FOVAngle = originalCameraProps.FOV
				end
				
				-- Force a camera update to apply the new settings]]
				--player:ClientSetViewTarget(pawn, empty_viewTargetTransitionParams)
				
			end
			--[[if player.PlayerCameraManager ~= nil and player.PlayerCameraManager.Children ~= nil and #player.PlayerCameraManager.Children == 1 then
				player.PlayerCameraManager.Children[1] = pawn
			end]]
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

uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
	if normalPlay then
		fixCamera()
	end
end)

function fix_interaction_icon() 
	if configui.getValue("enable_prononocued_interaction_widget") then
		interactWidgets = uevrUtils.find_all_instances("WidgetBlueprintGeneratedClass /Game/01_Blueprints/Interactuables/HUDIcono.HUDIcono_C", false)

		if interactWidgets ~= nil then
			for _, interactWidget in pairs(interactWidgets) do
				--print("working on",interactWidget:get_full_name())
				interactWidget:SetVisibility(0) --1 - disable
				interactWidget.ColorAndOpacity.A = 1
				interactWidget.ColorAndOpacity.B = 0
				interactWidget.ColorAndOpacity.G = 1
				interactWidget.ColorAndOpacity.R = 0
				interactWidget.RenderTransform.Scale.X = 1--2
				interactWidget.RenderTransform.Scale.Y = 1--2
				interactWidget.Clipping = 0
				interactWidget.Priority = 100
			end
		end
	end
end

function alwaysShowRegularIcons()
	interactWidgets = uevrUtils.find_all_instances("WidgetBlueprintGeneratedClass /Game/01_Blueprints/Interactuables/HUDIcono_Proximidad.HUDIcono_Proximidad_C", false)

	if interactWidgets ~= nil then
		for _, interactWidget in pairs(interactWidgets) do
			--print("working on",interactWidget:get_full_name())
			interactWidget:SetVisibility(0) --1 - disable
			interactWidget.ColorAndOpacity.A = 1
			interactWidget.ColorAndOpacity.B = 0
			interactWidget.ColorAndOpacity.G = 1
			interactWidget.ColorAndOpacity.R = 0
			interactWidget.RenderTransform.Scale.X = 2
			interactWidget.RenderTransform.Scale.Y = 2
			interactWidget.Clipping = 0
			interactWidget.Priority = 100
			interactWidget:AjustarOpacidadParaVisibleOInvisible(true)
		end
	end
end

function triggerPawnMovement()
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		if pawn.CharacterMovement ~= nil then
			pawn.CharacterMovement.bMovementInProgress = true
		end
	end
	 
end

function moveForward(value)
	--print("move forward", value)
	
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		if value ~= 0.0 then
			if pawn.CharacterMovement ~= nil then
				if runToggled == true then
					pawn.CharacterMovement.MaxWalkSpeed = 230.0
					if configui.getValue("walk_speed") ~= nil and configui.getValue("run_speed_multiplier") ~= nil then
						pawn.CharacterMovement.MaxWalkSpeed = configui.getValue("walk_speed") * configui.getValue("run_speed_multiplier")
					end
					
				else
					pawn.CharacterMovement.MaxWalkSpeed = 115.0
					if configui.getValue("walk_speed") ~= nil then
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
				local moveDistance = math.abs(-1 * speed) -- -2 seems to be the just the right amount...

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
				--prevent deadlock when switching cameras
				local success = pcall(setActorLocaion, newLocation)
				--if success == false then
				--	pcall(setActorLocaion, currentLocation)
				--end
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
			local backwardX
			local backwardY
			if value > 0 then
				backwardX = -math.sin(yawRadians)
				backwardY = math.cos(yawRadians)
			else			
				-- left movement 
				-- Calculate left direction based on current rotation
				backwardX = math.sin(yawRadians)
				backwardY = -math.cos(yawRadians)
			end
			local newLocation = {
				X = currentLocation.X + backwardX * moveDistance,
				Y = currentLocation.Y + backwardY * moveDistance,
				Z = currentLocation.Z -- Keep Z unchanged for ground movement
			}
			--prevent deadlock when switching cameras
			local success = pcall(setActorLocaion, newLocation)
			--if success == false then
			--	pcall(setActorLocaion, currentLocation)
			--end
			triggerPawnMovement()
		end
	end
end

function setActorLocaion(newLocation)
										  --sweep                --teleport
	pawn:K2_SetActorLocation(newLocation, true, empty_hitresult, true)
end

function turn(value)
	--print("turn")

	local turnRateGamepad = 0.16
	if configui.getValue("turn_speed") ~= nil then
		turnRateGamepad = configui.getValue("turn_speed") 
	end
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		if value ~= 0.0 then
			newRotation = pawn:K2_GetActorRotation();
			newRotation.Yaw = newRotation.Yaw + value * turnRateGamepad
			pawn:K2_SetActorRotation(newRotation)
			triggerPawnMovement()
		end
	end
end

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
	if (state ~= nil) then
		if state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER ~= 0 and state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER ~= 0 then
				state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_LEFT_SHOULDER
				state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_RIGHT_SHOULDER
				params.vr.recenter_view()
		end
		
		if normalPlay == true then
			--switch run to toggle left thumb stick
			if not runToggled then
				if state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB ~= 0 and state.Gamepad.sThumbLY > 10000 then
					state.Gamepad.bLeftTrigger = 30000
					runToggled = true
					--print("runToggled")
				end	
			else
				if state.Gamepad.sThumbLY < 10000  then
					runToggled = false
					--print("runToggled end")
				else -- run is toggled - press bLeftTrigger (maybe it's needed so why not press it?)
					state.Gamepad.bLeftTrigger = 30000
				end
			end
			
			--map button switch
			if state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB ~= 0 then --cancel map on left thumbstick
				--print("cancelling left thumbstick so it won't open map")
				state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_LEFT_THUMB
			end
			if state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_THUMB ~= 0 then -- move map to right thumbstick
				state.Gamepad.wButtons = state.Gamepad.wButtons + XINPUT_GAMEPAD_LEFT_THUMB -- click left thumbstick to enable map
				state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_RIGHT_THUMB -- disable right thumbstick so that lightsource won't toggle
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
			
			state.Gamepad.sThumbRX  = 0 --disable R stick X as it will be used to move pawn 
			
			
			--state.Gamepad.sThumbRX = state.Gamepad.sThumbLX -- move eyes left right to left stick
			-- disable L stick - use movement functions instead
			state.Gamepad.sThumbLX = 0 
			state.Gamepad.sThumbLY = 0
		elseif fixedCameras3rdPersonMode == true then
			--map button switch
			if state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB ~= 0 then --cancel map on left thumbstick
				--print("cancelling left thumbstick so it won't open map")
				state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_LEFT_THUMB
			end
			if state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_THUMB ~= 0 then -- move map to right thumbstick
				state.Gamepad.wButtons = state.Gamepad.wButtons + XINPUT_GAMEPAD_LEFT_THUMB -- click left thumbstick to enable map
				state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_RIGHT_THUMB -- disable right thumbstick so that lightsource won't toggle
			end
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
				print(fixedCameras3rdPersonMode)
				state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_DPAD_RIGHT 
			else -- dpad down released
				if fixedCameras3rdPersonModeJustChanged == true then
					fixedCameras3rdPersonModeJustChanged = false
				end
			end
		end
	end
end)