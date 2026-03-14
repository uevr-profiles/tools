local api = uevr.api
local vr = uevr.params.vr
local params = uevr.params
local callbacks = params.sdk.callbacks

local uevrUtils = require("libs/uevr_utils")
uevrUtils.setLogLevel(LogLevel.Debug)
uevrUtils.initUEVR(uevr)

local inASE = false

--pawn skeletal meshes
local SK_Suits = {}
local SK_Helmets = {}
local SK_Moonbears = {}
local SK_brows_and_eyelasheses = {}
local CharacterMesh0es = {}
local SkeletalHairMeshes = {}
local SK_Pickaxe_Lefts = {}
local SK_Pickaxe_Rights = {}
local SM_Oxygen_Lights = {}

local SK_OutfitBeforeEnteringASE
local SM_LensBeforeEnteringASE
local SM_CuttingToolBeforeEnteringASE

--zeroG first person force
local switchToFirstPersonNeeded = false

local hiddenScubaHud = false
local hiddenHelmetHud = false


--climbing
local isClimbing = false
local leftHandFree = false
local rightHandFree = false
local leftPickaxes = {}
local rightPickaxes = {}

--carrying objects
local savedEquippedPickAxesState

local level


--optional
local SUPPORT_3RD_PERSON_AIMING = false

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)

	local game_engine_class = api:find_uobject("Class /Script/Engine.GameEngine")
	local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)

	local viewport = game_engine.GameViewport
	if viewport == nil then
		--print("Viewport is nil")
		return
	end
	local world = viewport.World

	if world == nil then
		--print("World is nil")
        	return
    	end

	if world ~= last_world then
        	--print("World changed")
	end

	world.OwningGameInstance.GameSettingsRef.CameraShakeScale = 0
	
	last_world = world


	level = world.PersistentLevel

	if level == nil then
        	--print("Level is nil")
        	return
    	end
	--print("Level name: " .. level:get_full_name())

	
	if isInASEMode() then --ASE mode makes the acknowledged pawn become the ASE robot instead of the player pawn - so calling initializePawnMeshes() in ASE would have overriden the player pawn's meshes we got from the last tick we want to hide
		applyASESettings()
	else			
		if isInMainMenu() then 
			initializePawnMeshes()
			applyMainMenuSettings()
		elseif isInCinematic() then
			initializePawnMeshes()
			applyCinematicSettings()
		elseif isInspecting() then
			initializePawnMeshes()
			applyInspectingSettings()
		elseif isInZeroG() then
			initializePawnMeshes()
			applyZeroGSettings()
		--[[elseif isInClimbing() then
			initializePawnMeshes()
			applyClimbingSettings()	]]
		--[[elseif isCutting() then
			initializePawnMeshes()
			applyCuttingSettings()]]
		elseif isInDockingSequence() then
			applyDockingSequenceSettings()
		elseif  isDriving() then
			applyDrivingSettings()
		elseif SUPPORT_3RD_PERSON_AIMING and isAimingAndFiring() then
			initializePawnMeshes()
			applyAimingAndFiringSettings()	
		else -- normal mode
			initializePawnMeshes()
			applyNormalModeSettings()
		end	
	end
	if not isInZeroG() then
		hiddenScubaHud = false
		hiddenHelmetHud = false
	end
end)

uevr.sdk.callbacks.on_pre_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
	if isInCinematic() == false and isInMainMenu() == false then
		local pawn = api:get_local_pawn(0)
	
		if pawn == nil then
			return
		end
		
		local pawn_pos = nil
	
		pawn_pos = pawn.RootComponent:K2_GetComponentLocation()
		
		if string.find(tostring(pawn:get_full_name()), "BP_Player_KidKathy_C") then
			position.x = pawn_pos.x
			position.y = pawn_pos.y + 10.100000381469727
			position.z = pawn_pos.z + 52.400001525878906
		else
			position.x = pawn_pos.x
			position.y = pawn_pos.y
			position.z = pawn_pos.z
		end
	end

end)


uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
	if (state ~= nil) then
		if switchToFirstPersonNeeded == true then
			switchToFirstPersonNeeded = false
			state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_LEFT_THUMB
		elseif isInZeroG() then
			if state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB ~= 0 then --cancel clicking on left thumbstick to not go back to 3rd person camera in zero G
				--print("cancelling 3rd person")
				state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_LEFT_THUMB
			end
		--[[elseif isInClimbing() then
			if state.Gamepad.bLeftTrigger == 0 and state.Gamepad.bRightTrigger ~= 0 then
				leftHandFree = true
				rightHandFree = false
			elseif state.Gamepad.bLeftTrigger ~= 0 and state.Gamepad.bRightTrigger == 0 then
				rightHandFree = true
				leftHandFree = false
			else
				rightHandFree = false
				leftHandFree = false
			end]]
		end
		if state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER ~= 0 and state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER ~= 0 then
			params.vr.recenter_view()
		end
	end 
end)

function initializePawnMeshes() 
	local pawn = api:get_local_pawn(0)	
	if pawn ~= nil then
		SK_Suits = {}
		SK_Helmets = {}
		SK_Moonbears = {}
		SK_brows_and_eyelasheses = {}
		CharacterMesh0es = {}
		SkeletalHairMeshes = {}
		SK_Pickaxe_Lefts = {}
		SK_Pickaxe_Rights = {}
		SM_Oxygen_Lights = {}
		rightPickaxes = {}
		leftPickaxes = {}
		SM_Lens = nil
		SM_CuttingTool = nil
		if pawn.SK_Suit ~= nil then
			table.insert(SK_Suits, pawn.SK_Suit)
		end
		if pawn.SK_Outfit ~= nil then
			table.insert(SK_Suits, pawn.SK_Outfit)
			SK_OutfitBeforeEnteringASE = pawn.SK_Outfit
		end
		if pawn.SK_Helmet ~= nil then
			table.insert(SK_Helmets , pawn.SK_Helmet)
			--if string.find(tostring(level:get_full_name()), "HerschelQuarry") then
				--fix glitchy shadows
				pawn.SK_Helmet.CastShadow = false
			--end
		end
		if pawn.SK_Moonbear ~= nil then
			table.insert(SK_Moonbears, pawn.SK_Moonbear)
		end
		if pawn.SK_KidKathy_brows_and_eyelashes ~= nil then
			table.insert(SK_brows_and_eyelasheses, pawn.SK_KidKathy_brows_and_eyelashes)
		end
		if pawn.SK_Kathy_brows_and_eyelashes ~= nil then
			table.insert(SK_brows_and_eyelasheses, pawn.SK_Kathy_brows_and_eyelashes)
		end
		if pawn.Mesh ~= nil then
			table.insert(CharacterMesh0es, pawn.Mesh)
		end
		if pawn.SkeletalHairMesh~= nil then
			table.insert(SkeletalHairMeshes, pawn.SkeletalHairMesh)
		end
		if pawn.StaticHairMeshInHelm~= nil then
			table.insert(SkeletalHairMeshes, pawn.StaticHairMeshInHelm)
		end
		if pawn.SK_Pickaxe_Left ~= nil then
			table.insert(SK_Pickaxe_Lefts, pawn.SK_Pickaxe_Left)
			--if string.find(tostring(level:get_full_name()), "HerschelQuarry") then
				--fix glitchy shadows
				pawn.SK_Pickaxe_Left.CastShadow = false
			--end
		end
		if pawn.SK_Pickaxe_Right ~= nil then
			table.insert(SK_Pickaxe_Rights, pawn.SK_Pickaxe_Right)
			--if string.find(tostring(level:get_full_name()), "HerschelQuarry") then
				--fix glitchy shadows
				pawn.SK_Pickaxe_Right.CastShadow = false
			--end
		end
		if pawn.SM_Lens ~= nil then
			SM_Lens = pawn.SM_Lens
			SM_LensBeforeEnteringASE = pawn.SM_Lens
			--if string.find(tostring(level:get_full_name()), "HerschelQuarry") then
				--fix glitchy shadows
				pawn.SM_Lens.CastShadow = false
			--end
		end
		if pawn.SM_CuttingTool ~= nil then
			SM_CuttingTool = pawn.SM_CuttingTool
			SM_CuttingToolBeforeEnteringASE = pawn.SM_CuttingTool
			--if string.find(tostring(level:get_full_name()), "HerschelQuarry") then
				--fix glitchy shadows
				pawn.SM_CuttingTool.CastShadow = false
			--end
		end
		if pawn.SM_OxygenLight_0 ~= nil then
			table.insert(SM_Oxygen_Lights, pawn.SM_OxygenLight_0)
		end
		if pawn.SM_OxygenLight_1 ~= nil then
			table.insert(SM_Oxygen_Lights, pawn.SM_OxygenLight_1)
		end
		if pawn.SM_OxygenLight_2 ~= nil then
			table.insert(SM_Oxygen_Lights, pawn.SM_OxygenLight_2)
		end
		if pawn.SM_OxygenLight_3 ~= nil then
			table.insert(SM_Oxygen_Lights, pawn.SM_OxygenLight_3)
		end
		if pawn["SM_Pickaxe Left"] ~= nill then
			table.insert(leftPickaxes, pawn["SM_Pickaxe Left"])
		end
		if pawn["SM_Pickaxe Right"] ~= nill then
			table.insert(rightPickaxes, pawn["SM_Pickaxe Right"])
		end
	end
end

function togglePawnMeshesVisibility(visible)
	if SK_Helmets ~= nil then
		for _, SK_Helmet in pairs(SK_Helmets) do
			SK_Helmet:SetVisibility(visible)
			SK_Helmet:SetRenderInMainPass(visible)
			SK_Helmet:SetRenderCustomDepth(visible)
		end
	end
	if SK_brows_and_eyelasheses ~= nil then
		for _, SK_brows_and_eyelashes in pairs(SK_brows_and_eyelasheses) do
			SK_brows_and_eyelashes:SetVisibility(visible)
			SK_brows_and_eyelashes:SetRenderInMainPass(visible)
			SK_brows_and_eyelashes:SetRenderCustomDepth(visible)
		end
	end
	if SkeletalHairMeshes ~= nil then
		for _, SkeletalHairMesh in pairs(SkeletalHairMeshes) do
			SkeletalHairMesh:SetVisibility(visible)
			SkeletalHairMesh:SetRenderInMainPass(visible)
			SkeletalHairMesh:SetRenderCustomDepth(visible)
		end
	end
		
	if CharacterMesh0es ~= nil then
		for _, CharacterMesh0 in pairs(CharacterMesh0es) do
			CharacterMesh0:SetVisibility(visible)
			CharacterMesh0:SetRenderInMainPass(visible)
			CharacterMesh0:SetRenderCustomDepth(visible)
		end
	end
	
	if SK_Suits ~= nil then
		for _, SK_Suit in pairs(SK_Suits) do
			SK_Suit:SetVisibility(visible)
			SK_Suit:SetRenderInMainPass(visible)
			SK_Suit:SetRenderCustomDepth(visible)
		end
	end
	
	if SK_Moonbears ~= nil then
		for _, SK_Moonbear in pairs(SK_Moonbears) do
			SK_Moonbear:SetVisibility(visible)
			SK_Moonbear:SetRenderInMainPass(visible)
			SK_Moonbear:SetRenderCustomDepth(visible)
		end
	end
	
	if SK_Pickaxe_Lefts ~= nil then
		for _, SK_Pickaxe_Left in pairs(SK_Pickaxe_Lefts) do
			SK_Pickaxe_Left:SetVisibility(visible)
			SK_Pickaxe_Left:SetRenderInMainPass(visible)
			SK_Pickaxe_Left:SetRenderCustomDepth(visible)
		end
	end
	if SK_Pickaxe_Rights ~= nil then
		for _, SK_Pickaxe_Right in pairs(SK_Pickaxe_Rights) do
			SK_Pickaxe_Right:SetVisibility(visible)
			SK_Pickaxe_Right:SetRenderInMainPass(visible)
			SK_Pickaxe_Right:SetRenderCustomDepth(visible)
		end
	end
	if SM_Lens ~= nil then
		SM_Lens:SetVisibility(visible)
		SM_Lens:SetRenderInMainPass(visible)
		SM_Lens:SetRenderCustomDepth(visible)
	end
	if SM_CuttingTool ~= nil then
		SM_CuttingTool:SetVisibility(visible)
		SM_CuttingTool:SetRenderInMainPass(visible)
		SM_CuttingTool:SetRenderCustomDepth(visible)
	end
	if SM_Oxygen_Lights ~= nil then
		for _, SM_Oxygen_Light in pairs(SM_Oxygen_Lights) do
			SM_Oxygen_Light:SetVisibility(visible)
			SM_Oxygen_Light:SetRenderInMainPass(visible)
			SM_Oxygen_Light:SetRenderCustomDepth(visible)
		end
	end
	if rightPickaxes ~= nil then
		for _, rightPickaxe in pairs(rightPickaxes) do
			rightPickaxe:SetVisibility(visible)
			rightPickaxe:SetRenderInMainPass(visible)
			rightPickaxe:SetRenderCustomDepth(visible)
		end
	end
	if leftPickaxes ~= nil then
		for _, leftPickaxe in pairs(leftPickaxes) do
			leftPickaxe:SetVisibility(visible)
			leftPickaxe:SetRenderInMainPass(visible)
			leftPickaxe:SetRenderCustomDepth(visible)
		end
	end
end

function isInASEMode() 
	local pawn = api:get_local_pawn(0)
	if pawn ~= nill then
		return string.find(tostring(pawn:get_full_name()), "BP_ASE_C")
	end
end

function isInMainMenu()
	local pawn = api:get_local_pawn(0)

	if pawn ~= nil then
		return false
	else 
		return true
	end
	
	return false
end


function isInCinematic()
	local pawn = api:get_local_pawn(0)

	if pawn ~= nil then
		return pawn.bHidden or pawn.bForzen 
	else 
		return true
	end
	
	return false
end

function isInspecting()
    local val = false
    local list = uevrUtils.find_all_instances("Class /Script/KeoCore.InspectCameraModifier")
	
	if list ~= nil then
	
		for _, object in pairs(list) do
			cameraManagerList = uevrUtils.find_all_instances("BlueprintGeneratedClass /Game/DeliverUsMars/Blueprints/Character/CameraSystem/BP_PlayerCameraManager.BP_PlayerCameraManager_C")
			for _, cameraManager in pairs(cameraManagerList) do
				for _, cameraManagerModifier in pairs(cameraManager.ModifierList) do
					if object == cameraManagerModifier then
						--print ("inspecting...")  
						val = true
					end    
				end
			end
			
		end
	end
	
    return val
end


function isAimingAndFiring()

	local pawn = api:get_local_pawn(0)
	if pawn ~= nill then
		return pawn.bIsAiming and pawn.bIsFiring
	end		
	return false
end

function isCutting()

	local pawn = api:get_local_pawn(0)
	if pawn ~= nill then
		return pawn.bIsFiring
	end		
	return false
end

function isInZeroG() 
	local pawn = api:get_local_pawn(0)
	if pawn ~= nill then
		return pawn.IsZeroG
	end
	return false
end

function isInClimbing() 
	local pawn = api:get_local_pawn(0)
	if pawn ~= nill then	
		return pawn.IsClimbing
	end
	return false
end

function isCarryingObject()
	local pawn = api:get_local_pawn(0)
	if pawn ~= nill then
		return pawn.bCarryingObject
	end		
	return false
end

function isDriving()
	local pawn = api:get_local_pawn(0)
	return string.find(tostring(pawn:get_full_name()), "BP_LunarExplorer_C")
end

function isInDockingSequence()
	local pawn = api:get_local_pawn(0)
	return string.find(tostring(pawn:get_full_name()), "BP_AlignmentPawnDockingSequence_C")
end

function applyMainMenuSettings() 
	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
				
	vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	vr.set_mod_value("VR_CameraUpOffset", "0.000000")				
	vr.set_mod_value("VR_LerpCameraYaw", "false")

	
        vr.set_mod_value("VR_DecoupledPitchUIAdjust", "false")

	UEVR_UObjectHook.set_disabled(true)
end

function applyCinematicSettings() 
	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
				
	vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	vr.set_mod_value("VR_CameraUpOffset", "0.000000")				
	vr.set_mod_value("VR_LerpCameraYaw", "false")

	
        vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
	
	togglePawnMeshesVisibility(true)
	UEVR_UObjectHook.set_disabled(true)
end

function applyInspectingSettings() 
	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
				
	vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	vr.set_mod_value("VR_CameraUpOffset", "0.000000")				
	vr.set_mod_value("VR_LerpCameraYaw", "false")

	
        vr.set_mod_value("VR_DecoupledPitchUIAdjust", "false")
	
	UEVR_UObjectHook.set_disabled(true)
	togglePawnMeshesVisibility(false)
end

function applyASESettings() 		
	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
		
	vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	vr.set_mod_value("VR_CameraUpOffset", "0.000000")
					
	vr.set_mod_value("VR_LerpCameraYaw", "false")
	vr.set_mod_value("VR_LerpCameraSpeed", "0.000000")
	
	--[[if SK_OutfitBeforeEnteringASE ~= nil then
		SK_OutfitBeforeEnteringASE:SetVisibility(false)
	end	
	if SM_LensBeforeEnteringASE ~= nil then
		SM_LensBeforeEnteringASE:SetVisibility(false)
	end
	if SM_CuttingToolBeforeEnteringASE ~= nil then
		SM_CuttingToolBeforeEnteringASE:SetVisibility(false)
	end]]

	vr.set_mod_value("VR_DecoupledPitchUIAdjust", "false")	
	UEVR_UObjectHook.set_disabled(true)
	togglePawnMeshesVisibility(true)
	
end


function applyZeroGSettings()
	if hiddenScubaHud == false then
		local zeroGOverlayClass = uevr.api:find_uobject("WidgetBlueprintGeneratedClass /Game/DeliverUsMars/UI/Helmet/WB_ScubaOverlay.WB_ScubaOverlay_C")
		if zeroGOverlayClass ~=nil then
			local zeroGOverlays = zeroGOverlayClass:get_objects_matching(false)
			--local zeroGOverlays = uevrUtils.find_all_instances("WidgetBlueprintGeneratedClass /Game/DeliverUsMars/UI/Helmet/WB_ScubaOverlay.WB_ScubaOverlay_C", true)
			if zeroGOverlays ~=nil then
				for _, zeroGOverlay in pairs(zeroGOverlays) do
					if zeroGOverlay ~= nil then
						zeroGOverlay:SetRenderOpacity(0.0)
						if zeroGOverlay.ScubaBot ~=nil then
							zeroGOverlay.ScubaTop:SetVisibility(1)
						end	
						if zeroGOverlay.ScubaTop ~=nil then
							zeroGOverlay.ScubaBot:SetVisibility(1)
						end			
					end
					hiddenScubaHud = true
					hiddenHelmetHud = false
				end
			
			end
		end
	end
	
	if hiddenHelmetHud == false then
		local zeroGOverlayClass1 = uevr.api:find_uobject("WidgetBlueprintGeneratedClass /Game/DeliverUsMars/UI/Helmet/WB_HelmetOverlay.WB_HelmetOverlay_C")
		if zeroGOverlayClass1 ~=nil then
			local zeroGOverlays1 = zeroGOverlayClass1:get_objects_matching(false)
	
			--local zeroGOverlays1 = uevrUtils.find_all_instances("WidgetBlueprintGeneratedClass /Game/DeliverUsMars/UI/Helmet/WB_HelmetOverlay.WB_HelmetOverlay_C")
			if zeroGOverlays1 ~= nil then 
				for _, zeroGOverlay1 in pairs(zeroGOverlays1) do
					if zeroGOverlay1 ~= nil then
				
						if zeroGOverlay1.HelmetOverlay ~=nil then
							zeroGOverlay1.HelmetOverlay:SetVisibility(1)
						end	
						if zeroGOverlay1.HelmetOverlay_1 ~=nil then
							zeroGOverlay1.HelmetOverlay_1:SetVisibility(1)
						end
						if zeroGOverlay1.HelmetParent ~=nil then
							if (zeroGOverlay1.WB_OxygenStates == nil or zeroGOverlay1.WB_OxygenStates["Oxygent Stage"] == nil or zeroGOverlay1.WB_OxygenStates["Oxygent Stage"] == 0) then
								zeroGOverlay1.HelmetParent:SetVisibility(1)
								zeroGOverlay1:SetRenderOpacity(0.0)
							else
								zeroGOverlay1.HelmetParent:SetVisibility(0)
								zeroGOverlay1:SetRenderOpacity(0.3)
							end
						end
						hiddenScubaHud = false
						if not string.find(tostring(level:get_full_name()), "020_ZephyrScuba") then
							hiddenHelmetHud = true
							hiddenScubaHud = true	
						end
					end
				end
			end
		end
	end

	--force 1st person camera
	cameraManagerList = uevrUtils.find_all_instances("BlueprintGeneratedClass /Game/DeliverUsMars/Blueprints/Character/CameraSystem/BP_PlayerCameraManager.BP_PlayerCameraManager_C")
	for _, zeroGCameraManager in pairs(cameraManagerList) do
		if zeroGCameraManager ~= nil then
			if zeroGCameraManager.CameraState == 0 then --3rd person
				switchToFirstPersonNeeded = true
			end
		end
	end

	




	
	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
	vr.set_mod_value("VR_DecoupledPitchUIAdjust", "false")
	togglePawnMeshesVisibility(false)
	UEVR_UObjectHook.set_disabled(true)
	if isCutting() then
		applyCuttingSettings() 
	end
	if isInClimbing() then
		applyClimbingSettings() 
	end
	
end

function applyDockingSequenceSettings()
	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
	vr.set_mod_value("VR_DecoupledPitchUIAdjust", "false")
	UEVR_UObjectHook.set_disabled(true)
end

function applyAimingAndFiringSettings() 
	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
				
	vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	vr.set_mod_value("VR_CameraUpOffset", "0.000000")				
	vr.set_mod_value("VR_LerpCameraYaw", "false")

        vr.set_mod_value("VR_DecoupledPitchUIAdjust", "false")
	
	UEVR_UObjectHook.set_disabled(true)
	togglePawnMeshesVisibility(true)
end


function applyClimbingSettings()
	--[[vr.set_mod_value("VR_AimMethod", "2")
	vr.set_mod_value("VR_RoomscaleMovement", "1")
	vr.set_mod_value("VR_DecoupledPitch", "1")

				
	vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	vr.set_mod_value("VR_CameraUpOffset", "0.000000")				
	vr.set_mod_value("VR_LerpCameraYaw", "false")

	
        vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")


	togglePawnMeshesVisibility(false)
	UEVR_UObjectHook.set_disabled(false)]]
	if rightPickaxes ~= nil then
		for _, rightPickaxe1 in pairs(rightPickaxes) do
			rightPickaxe1:SetVisibility(true)
			rightPickaxe1:SetRenderInMainPass(true)
			rightPickaxe1:SetRenderCustomDepth(true)
		end
	end
	if leftPickaxes ~= nil then
		for _, leftPickaxe1 in pairs(leftPickaxes) do
			leftPickaxe1:SetVisibility(true)
			leftPickaxe1:SetRenderInMainPass(true)
			leftPickaxe1:SetRenderCustomDepth(true)
		end
	end
end

function applyCuttingSettings() 
	--[[vr.set_mod_value("VR_AimMethod", "2")
	vr.set_mod_value("VR_RoomscaleMovement", "1")
	vr.set_mod_value("VR_DecoupledPitch", "1")

				
	vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	vr.set_mod_value("VR_CameraUpOffset", "0.000000")				
	vr.set_mod_value("VR_LerpCameraYaw", "false")

	
        vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")

	togglePawnMeshesVisibility(false)
	UEVR_UObjectHook.set_disabled(false)]]
	if SM_CuttingTool ~= nil then
		SM_CuttingTool:SetVisibility(true)
		SM_CuttingTool:SetRenderInMainPass(true)
		SM_CuttingTool:SetRenderCustomDepth(true)
	end

end

function applyCarryingObjectSettings()
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		if savedEquippedPickAxesState == nil then
			if pawn.bEquippedPickAxes == true then
				savedEquippedPickAxesState = true
			else
				savedEquippedPickAxesState = false
			end
		end
		pawn.bEquippedPickAxes = false --weird, but needed to prevent objet somethimes wobbling all over the place when carrying
	end
end

function retrunToNormalAfterCarryingObject() 
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		pawn.bEquippedPickAxes = savedEquippedPickAxesState
	end
end

function applyDrivingSettings()
	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
	vr.set_mod_value("VR_DecoupledPitchUIAdjust", "false")
	UEVR_UObjectHook.set_disabled(true)
end
	
function applyNormalModeSettings() 
	vr.set_mod_value("VR_AimMethod", "2")
	vr.set_mod_value("VR_RoomscaleMovement", "1")
	vr.set_mod_value("VR_DecoupledPitch", "1")

				
	vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	vr.set_mod_value("VR_CameraUpOffset", "0.000000")				
	vr.set_mod_value("VR_LerpCameraYaw", "false")

	
        vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
	UEVR_UObjectHook.set_disabled(false)
	togglePawnMeshesVisibility(false)
	
	if isInClimbing() then
		applyClimbingSettings() 
	elseif isCutting() then
		applyCuttingSettings() 
	end
	
	
	if isCarryingObject() then
		applyCarryingObjectSettings()
	else
		if savedEquippedPickAxesState ~=nil then
			retrunToNormalAfterCarryingObject() 
		end
		savedEquippedPickAxesState = nil	
	end

end


