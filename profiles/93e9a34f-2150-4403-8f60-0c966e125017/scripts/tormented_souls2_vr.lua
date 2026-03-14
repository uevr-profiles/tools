local api = uevr.api
local vr = uevr.params.vr
local params = uevr.params
local callbacks = params.sdk.callbacks

local controllers = require('libs/controllers')
local uevrUtils = require('libs/uevr_utils')
local configui = require('libs/configui')
local hands = require('libs/hands')

kismet_math_library = uevrUtils.find_default_instance("Class /Script/Engine.KismetMathLibrary")

local activeWeapon = nil
local activeWeaponMuzzle = nil
local activeWeaponMuzzleCode = nil

local activeWeaponComponent = nil

local lastAimingOffset = nil
local correctAimingRight = false
local correctAimingLeft = false

local hand = Handed.Right
local activeHand = hand

local currentSetOfFixedCameras = nil

local normalPlay = false

local runToggled = false

local needToFixCamera = fasle

local currentEnemy = nil
local currentEnemyAlreadySwitchedTo = false

local activeWeaponWidget = nil

--melee
local swingingFast = false

local tablePawnMeshMaterials = {}

local hitresult_c = uevrUtils.find_required_object("ScriptStruct /Script/Engine.HitResult")
local empty_hitresult = StructObject.new(hitresult_c)

--auto save
local activeLevelName = nil
local alreadyRestoredDifficulty = false
local lastAutoSaveRoom = nil


--bunker elevator fix
local currentLevelName = nil
local enteringRoom = false

local configDefinition = {
	{
		panelLabel = "Tormented Souls 2 VR", 
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
				label = "Game difficulty Override",
			},
			{
				widgetType = "text",
				label = "- Assisted : game difficulty will be changed to Assisted after entering a new room and a new auto save will be taken each time another room is entered.",
			},
			{
				widgetType = "text",
				label = "(If you just want an auto save for a higher difficuly level, change to Standard/Tormented till next manual save, right after the auto save has been created)",
			},
			{
				widgetType = "text",
				label = "- Standard till next manual save: upon loading an auto save - game difficulty will be changed to Standard. Can be changed to 'Disabled' after taking a manual save.",			
			},
			{
				widgetType = "text",
				label = "(note: need to leave and enter current room after each load of an auto save for Standard difficulty to take effect).",		
			},
			{
				widgetType = "text",
				label = "Can be changed to Disabled after taking a manual save.",		
			},			
			{
				widgetType = "text",
				label = "- Tormented till next manual save: upon loading an auto save - game difficulty will be changed to Tormented. Can be changed to 'Disabled' after taking a manual save.",			
			},
			{
				widgetType = "text",
				label = "(note: need to leave and enter current room after each load of an auto save for Tormented difficulty to take effect).",		
			},
			{
				widgetType = "text",
				label = "Can be changed to Disabled after taking a manual save.",		
			},		
			{
				widgetType = "combo",
				id = "enable_autosave_for_non_assisted_difficulties",
				label = "Override",
				selections = {"Disabled", "Assisted", "Standard till next manual save", "Tormented till next manual save"},
				initialValue = 1,
				width = 150
			},
			{
				widgetType = "text",
				label = "=== GamePlay ===",
			},
			{
				widgetType = "checkbox",
				id = "maintain_original_aim_distance_values",
				label = "Maitain original aim distance values for guns",
				initialValue = false
			},
			{
				widgetType = "checkbox",
				id = "enable_lock_on",
				label = "Enable lock on (every shot will hit when locked on, regardles of where you're aiming)",
				initialValue = true
			},
			{
				widgetType = "checkbox",
				id = "disable_6dof",
				label = "Disable 6DoF aiming (reload save/restart game for changes to take effect)",
				initialValue = false
			}
		}
	}
}

configui.create(configDefinition)

--[[configui.onUpdate("enable_prononocued_interaction_widget", function(value) updatePronouncedInteractionWidget() end)

function updatePronouncedInteractionWidget() 
	
end]]


function on_level_change(level)
	--controllers.createController(2)
	controllers.createController(0)
	controllers.createController(1)
	hands.reset()
	
	if configui.getValue("disable_6dof") == false then
		local paramsFile = 'hands_parameters' -- found in the [game profile]/data directory
		local configName = 'Main' -- the name you gave your config
		local animationName = 'Shared' -- the name you gave your animation
		hands.createFromConfig(paramsFile, configName, animationName)
	end
end

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	--[[local game_engine_class = api:find_uobject("Class /Script/Engine.GameEngine")
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
	
	last_world = world


	level = world.PersistentLevel

	if level == nil then
        	--print("Level is nil")
        	return
    end]]
	--if configui.getValue("enable_autosave_for_non_assisted_difficulties") == 2 then
		--[[local pawn = api:get_local_pawn()
		if pawn ~= nil then
			local currentLevelName = pawn.GameInstance.CurrentLevelName
			if activeLevelName == nil then --first rom after load - set intended difficulty
				print("restored difficulty for first room", configui.getValue("enable_autosave_for_non_assisted_difficulties")-1)
				pawn.GameInstance:write_byte(0x291, configui.getValue("enable_autosave_for_non_assisted_difficulties")-1)
				alreadyRestoredDifficulty = false
			elseif activeLevelName ~= nil and activeLevelName ~= currentLevelName then
				local pawn = api:get_local_pawn()
				--if pawn ~= nil then
					--local currentDifficulty = pawn.GameInstance:read_byte(0x291)
					--print(currentDifficulty:get_full_name())
					--if currentDifficulty == 0 then
						--print("Current difficulty: ASSISTED (Easy)")
						
					--elseif currentDifficulty == 1 then
						--print("Current difficulty: STANDARD (Normal)")  
						--pawn.GameInstance:write_byte(0x291, 0)
					--elseif currentDifficulty == 2 then
						--print("Current difficulty: TORMENT (Hard)")
						--pawn.GameInstance:write_byte(0x291, 0)
					--end
				--end
				print("level changed from: ", activeLevelName)
				print("level changed to: ", currentLevelName)
				print("restored difficulty", configui.getValue("enable_autosave_for_non_assisted_difficulties")-1)
				pawn.GameInstance:write_byte(0x291, configui.getValue("enable_autosave_for_non_assisted_difficulties")-1)
				alreadyRestoredDifficulty = true
			elseif pawn.bIsEnteringRoom == true then
				print("current difficulty", pawn.GameInstance:read_byte(0x291))
				if not alreadyRestoredDifficulty then
					pawn.GameInstance:write_byte(0x291, 0) -- set game to assisted for save
				end
				--print("level changed from: ", activeLevelName)
				--print("level changed to: ", currentLevelName)
				--print("Saving on slot 0")
				--pawn.GameInstance:SaveFromSlotIndex(0)
				--restore intended difficulty
			else 
				alreadyRestoredDifficulty = false -- in same room as last tick
			end
			activeLevelName = currentLevelName
		end]]
		
		--[[hook_function("BlueprintGeneratedClass /Game/InventorySystem/BP_TS2GameInstance.BP_TS2GameInstance_C", "SaveFromSlotIndex", true, 
			function(fn, obj, locals, result)
				print("SaveFromSlotIndex started")
				local pawn = api:get_local_pawn()
				if pawn == nil then
					local currentDifficulty = pawn.GameInstance:read_byte(0x291)
					if currentDifficulty == 0 then
						print("Current difficulty: ASSISTED (Easy)")
					elseif currentDifficulty == 1 then
						print("Current difficulty: STANDARD (Normal)")  
					elseif currentDifficulty == 2 then
						print("Current difficulty: TORMENT (Hard)")
					end
				end
			end,
			function(fn, obj, locals, result)
				print("SaveFromSlotIndex ended")
			end,
		true)
		
		hook_function("BlueprintGeneratedClass /Game/InventorySystem/BP_TS2GameInstance.BP_TS2GameInstance_C", "Save Character Data", true, 
			function(fn, obj, locals, result)
				print("Save Character Data started")
				local pawn = api:get_local_pawn()
				if pawn == nil then
					local currentDifficulty = pawn.GameInstance:read_byte(0x291)
					if currentDifficulty == 0 then
						print("Current difficulty: ASSISTED (Easy)")
					elseif currentDifficulty == 1 then
						print("Current difficulty: STANDARD (Normal)")  
					elseif currentDifficulty == 2 then
						print("Current difficulty: TORMENT (Hard)")
					end
				end
			end,
			function(fn, obj, locals, result)
				print("Save Character Data ended")
			end,
		true)]]
--	end
	local pawn = api:get_local_pawn()
	if pawn ~= nil and pawn.GameInstance ~= nil then
		if enteringRoom == false then
			if pawn.bIsEnteringRoom == true then
				enteringRoom = true
			end
		else 
			if pawn.bIsEnteringRoom == false then
				currentLevelName = pawn.GameInstance.CurrentLevelName
				if string.find(currentLevelName, "Bunker_Elevator") then
					print("bunker_elevator room")
				end
				enteringRoom = false
			end
		end
	end
	
	if configui.getValue("enable_autosave_for_non_assisted_difficulties") == 2 then
		local pawn = api:get_local_pawn()
		if pawn ~= nil then
			if pawn.bIsEnteringRoom == true then
				pawn.GameInstance:write_byte(0x291, 0) -- set game to assisted for save
			end
		end
	elseif configui.getValue("enable_autosave_for_non_assisted_difficulties") == 3 then --Standard
		if pawn ~= nil then
			if pawn.bIsEnteringRoom == true then
				--print("back to standard")
				pawn.GameInstance:write_byte(0x291, 1) -- set game to standard upon entering new room
			end
		end
	elseif configui.getValue("enable_autosave_for_non_assisted_difficulties") == 4 then --Standard
		if pawn ~= nil then
			if pawn.bIsEnteringRoom == true then
				print("back to tormented")
				pawn.GameInstance:write_byte(0x291, 2) -- set game to tormented upon entering new room
			end
		end
	end
	
	if isMainMenu() then
		applyMainMenuSettings() 
	elseif isInCutScene() then
		applyCinematicSettings()
	elseif isSolvingPuzzle() then
		applySolvingPuzzleSettings()
	elseif isClimbing() then
		applySClimbingSettings()
	elseif currentLevelName ~=nil and string.find(currentLevelName, "Bunker_Elevator") then
		applyBunkerElevatorSettings()
	else --regular play
		applyNormalModeSettings(delta)
	end
	

end)

--[[uevr.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
	if not isMainMenu() and not isInCutScene()then
		fixCamera()
	end
	local pawn = api:get_local_pawn()

	if pawn == nil then
		return
	end
		
	local pawn_pos = nil
	
	pawn_pos = pawn.RootComponent:K2_GetComponentLocation()
	position.x = pawn_pos.x
	position.y = pawn_pos.y
	position.z = pawn_pos.z 
end)]]


uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
	if normalPlay then
		fixCamera()
		if configui.getValue("disable_6dof") == false then
			if normalPlay then	
				updateEquippedWeapon(getCurrentWeapon() , hand)
			end
		end
	end
end)


function on_xinput_get_state(retval, user_index, state)
	--if uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_LEFT_SHOULDER) then
	--	initializeWeaponsManager()
	--end
	if configui.getValue("disable_6dof") == false then
		if hands.exists() then
			local isHoldingWeapon = activeWeapon ~= nil
			hands.handleInput(state, isHoldingWeapon, hand)
		end
	end
end

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
	if normalPlay == true then
		if (state ~= nil) then
		
			if state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER ~= 0 and state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER ~= 0 then
				params.vr.recenter_view()
			end
								
			state.Gamepad.sThumbLX = state.Gamepad.sThumbRX  --control tank X axis via R stick						
			
			--quick slots control via dpad
			if state.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_UP ~=0 then
				state.Gamepad.sThumbRY = 30000
				state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_DPAD_UP --cancel dpda press
			elseif state.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_DOWN ~=0 then
				state.Gamepad.sThumbRY = -30000
				state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_DPAD_DOWN --cancel dpda press
			elseif state.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_LEFT ~=0 then
				state.Gamepad.sThumbRX = -30000
				state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_DPAD_LEFT --cancel dpda press
			elseif state.Gamepad.wButtons & XINPUT_GAMEPAD_DPAD_RIGHT ~=0 then
				state.Gamepad.sThumbRX = 30000
				state.Gamepad.wButtons = state.Gamepad.wButtons - XINPUT_GAMEPAD_DPAD_RIGHT --cancel dpda press
			else
				state.Gamepad.sThumbRX  = 0 --disable R stick X as it will be used to move tank 
				state.Gamepad.sThumbRY  = 0 --disable R stick Y 
			end
			
			--switch run to toggle left thumb stick
			if not runToggled then
				if state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_THUMB ~= 0 and state.Gamepad.sThumbLY > 10000 then
					state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_X
					runToggled = true	
				end	
			else
				if state.Gamepad.sThumbLY < 10000  then
					runToggled = false
				else -- run is toggled - press X 
					state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_X
				end
			end
			if configui.getValue("disable_6dof") == false then
				if swingingFast == true then				
					if state.Gamepad.bLeftTrigger >= 200 then --if aiming
						state.Gamepad.bRightTrigger = 200
						fix_interaction_icon() -- need to fix the icon for new collectibles that might appear after melee of vases...
					end	
				end	
			end
		end 
	end
end)


function getCurrentWeapon()
	local currentWeapon1 = nil
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		if pawn.WeaponSystemComponent ~=nil and pawn.WeaponSystemComponent.CurrentWeapon ~=nil then
			if string.find(pawn.WeaponSystemComponent.CurrentWeapon:get_full_name(), "ChainSaw") then
				if pawn.WeaponSystemComponent.CurrentWeapon.StaticMesh ~=nil then --ChainSaw
					currentWeapon1 = pawn.WeaponSystemComponent.CurrentWeapon.StaticMesh
					--hide saw
					if pawn.WeaponSystemComponent.CurrentWeapon.Saw ~= nil then
						pawn.WeaponSystemComponent.CurrentWeapon.Saw:SetRenderInMainPass(false)
						pawn.WeaponSystemComponent.CurrentWeapon.Saw:SetRenderCustomDepth(false)
						pawn.WeaponSystemComponent.CurrentWeapon.Saw:SetRenderInDepthPass(false)
					end
				end
			elseif string.find(pawn.WeaponSystemComponent.CurrentWeapon:get_full_name(), "NailGun_C") then
				if pawn.WeaponSystemComponent.CurrentWeapon.StaticMesh ~=nil then --NailGun_C
					currentWeapon1 = pawn.WeaponSystemComponent.CurrentWeapon.StaticMesh
					--attach upgrade mesh
					if pawn.WeaponSystemComponent.CurrentWeapon.BlueprintCreatedComponents ~= nil then
						for _, component in pairs(pawn.WeaponSystemComponent.CurrentWeapon.BlueprintCreatedComponents) do
							if string.find(component:get_full_name(),"NODE_AddStaticMeshComponent") then
								--component:SetRenderInMainPass(false)
								--component:SetRenderCustomDepth(false)
								--component:SetRenderInDepthPass(false)
								component:K2_AttachTo(pawn.WeaponSystemComponent.CurrentWeapon.StaticMesh, "", 0, false)
								break
							end
						end
						
					end
				end
			elseif string.find(pawn.WeaponSystemComponent.CurrentWeapon:get_full_name(), "Crossbow") then
				if pawn.WeaponSystemComponent.CurrentWeapon.StaticMesh1 ~=nil then --Crossbow					
					currentWeapon1 = pawn.WeaponSystemComponent.CurrentWeapon.StaticMesh1
					if pawn.WeaponSystemComponent.CurrentWeapon.StaticMesh2 ~=nil then
						pawn.WeaponSystemComponent.CurrentWeapon.StaticMesh2:K2_AttachTo(pawn.WeaponSystemComponent.CurrentWeapon.StaticMesh1, "", 0, false)
					end
					if pawn.WeaponSystemComponent.CurrentWeapon.BlueprintCreatedComponents ~= nil then
						for _, component in pairs(pawn.WeaponSystemComponent.CurrentWeapon.BlueprintCreatedComponents) do
							if string.find(component:get_full_name(),"SM_MERGED_Static") then
								--component:SetRenderInMainPass(false)
								--component:SetRenderCustomDepth(false)
								--component:SetRenderInDepthPass(false)
								component:K2_AttachTo(pawn.WeaponSystemComponent.CurrentWeapon.StaticMesh1, "", 0, false)
							end	
							if string.find(component:get_full_name(),"StaticMesh") and not string.find(component:get_full_name(),"StaticMesh1") and not string.find(component:get_full_name(),"StaticMesh2") then
								--component:SetRenderInMainPass(false)
								--component:SetRenderCustomDepth(false)
								--component:SetRenderInDepthPass(false)
								component:K2_AttachTo(pawn.WeaponSystemComponent.CurrentWeapon.StaticMesh1, "", 0, false)
								
							end
						end
						
					end
				end
			else
				if pawn.WeaponSystemComponent.CurrentWeapon.SkeletalMesh ~=nil then --shotgun
					currentWeapon1 = pawn.WeaponSystemComponent.CurrentWeapon.SkeletalMesh
				elseif pawn.WeaponSystemComponent.CurrentWeapon.StaticMesh ~=nil then
					currentWeapon1 = pawn.WeaponSystemComponent.CurrentWeapon.StaticMesh
				end
			end
		end
	end
	return currentWeapon1
end

function disconnectPreviousWeapon(currentWeapon, hand) 
	if hand ~= activeHand or (activeWeapon ~= nil and currentWeapon ~= nil and activeWeapon ~= currentWeapon) then
		--Disconnecting current weapon
		UEVR_UObjectHook.remove_motion_controller_state(activeWeapon)
		--activeWeapon = nil
	end
end


function updateEquippedWeapon(currentWeapon, hand)
	if hand == nil then hand = Handed.Right end
	local lastWeapon = activeWeapon
	pcall(disconnectPreviousWeapon, currentWeapon, hand)
	
	if currentWeapon ~= nil and activeWeapon ~= currentWeapon then
		if configui.getValue("maintain_original_aim_distance_values") == false then
			pawn.WeaponSystemComponent.CurrentWeapon.aimDistance = 200000 -- increase aim distance to all weapons so they feel good to shoot
		end
		activeWeaponMuzzleCode = pawn.WeaponSystemComponent.CurrentWeapon.MuzzleCode
		activeWeaponMuzzleCode:K2_AttachTo(currentWeapon, "", 0, false)
		if pawn.WeaponSystemComponent.CurrentWeapon.SkeletalMesh ~= nil then
			if pawn.WeaponSystemComponent.CurrentWeapon.SkeletalMesh.AttachParent.AttachChildren ~= nil then
				for _, child in pairs(pawn.WeaponSystemComponent.CurrentWeapon.SkeletalMesh.AttachParent.AttachChildren) do
					if string.find(child:get_full_name(), "Muzzle") then					
						print("muzzle found")
						activeWeaponMuzzle = child
						activeWeaponComponent = pawn.WeaponSystemComponent.CurrentWeapon
						activeWeaponMuzzle:K2_AttachTo(currentWeapon, "", 0, false)
						if pawn.WeaponSystemComponent.CurrentWeapon.fixTransform ~= nil then
							print("resetting fixTransform")
							pawn.WeaponSystemComponent.CurrentWeapon.fixTransform = uevrUtils.get_transform()
						end
						if pawn.WeaponSystemComponent.CurrentWeapon.FixTransformAux ~= nil then
							print("resetting fixTransformAux")
							pawn.WeaponSystemComponent.CurrentWeapon.FixTransformAux = uevrUtils.get_transform()
						end
						if pawn.WeaponSystemComponent.CurrentWeapon.FixTransformAux2 ~= nil then
							print("resetting fixTransformAux2")
							pawn.WeaponSystemComponent.CurrentWeapon.FixTransformAux2 = uevrUtils.get_transform()
						end
						break
					end
				end	
			end
		else
			if pawn.WeaponSystemComponent.CurrentWeapon.StaticMesh.AttachParent.AttachChildren ~= nil then
				for _, child in pairs(pawn.WeaponSystemComponent.CurrentWeapon.StaticMesh.AttachParent.AttachChildren) do
					if string.find(child:get_full_name(), "Muzzle") then					
						print("muzzle found")
						activeWeaponMuzzle = child
						activeWeaponComponent = pawn.WeaponSystemComponent.CurrentWeapon
						activeWeaponMuzzle:K2_AttachTo(currentWeapon, "", 0, false)
						if pawn.WeaponSystemComponent.CurrentWeapon.fixTransform ~= nil then
							print("resetting fixTransform")
							pawn.WeaponSystemComponent.CurrentWeapon.fixTransform = uevrUtils.get_transform()
						end
						if pawn.WeaponSystemComponent.CurrentWeapon.FixTransformAux ~= nil then
							print("resetting fixTransformAux")
							pawn.WeaponSystemComponent.CurrentWeapon.FixTransformAux = uevrUtils.get_transform()
						end
						if pawn.WeaponSystemComponent.CurrentWeapon.FixTransformAux2 ~= nil then
							print("resetting fixTransformAux2")
							pawn.WeaponSystemComponent.CurrentWeapon.FixTransformAux2 = uevrUtils.get_transform()
						end
						break
					end
				end	
			end
		end
		print("Connecting weapon ".. currentWeapon:get_full_name() .. " " .. currentWeapon:get_fname():to_string() .. " to hand " .. hand)
		local state = UEVR_UObjectHook.get_or_add_motion_controller_state(currentWeapon)
		state:set_hand(hand)
		state:set_permanent(true)
		--local rot = getWeaponOffset(currentWeapon, 2)
		--local loc = getWeaponOffset(currentWeapon, 1)
		--state:set_rotation_offset(Vector3f.new( math.rad(rot.X), math.rad(rot.Y+90),  math.rad(rot.Z)))
		--state:set_location_offset(Vector3f.new(loc.X, loc.Y, loc.Z)) --uevrUtils.vector(getWeaponOffset(currentWeapon, 1)))
		
		if string.find(currentWeapon:get_full_name(), "Lighter_C") then
			state:set_rotation_offset(Vector3f.new(0, 0.259, 0))
			state:set_location_offset(Vector3f.new(3.050, 0.970, 4.820)) --forward , up, right	
		elseif string.find(currentWeapon:get_full_name(), "Hammer_Weapon_C") then
			state:set_rotation_offset(Vector3f.new(0, 0.259, 0))
			state:set_location_offset(Vector3f.new(3.050, 0.970, 4.920)) --forward , up, right
		elseif string.find(currentWeapon:get_full_name(), "AxeWeapon_C") then
			state:set_rotation_offset(Vector3f.new(0, 0.259, 0))
			state:set_location_offset(Vector3f.new(3.050, 0.970, 4.920)) --forward , up, right
		elseif string.find(currentWeapon:get_full_name(), "MetalDetector_C") then
			state:set_rotation_offset(Vector3f.new(-1.064, 0.883, 0.460))
			state:set_location_offset(Vector3f.new(-23.872, 84.165, 2.986)) --forward , up, right
		elseif string.find(currentWeapon:get_full_name(), "Crowbar_Weapon_C") then
			state:set_rotation_offset(Vector3f.new(1.108, 1.649, 1.607))
			state:set_location_offset(Vector3f.new(1.399, -3.405, -27.158)) --forward , up, right
		elseif string.find(currentWeapon:get_full_name(), "ChainSaw_C") then
			state:set_rotation_offset(Vector3f.new(0.559, 3.086, 0.187))
			state:set_location_offset(Vector3f.new(0.994, -5.387, -31.735)) --forward , up, right
		elseif string.find(currentWeapon:get_full_name(), "NailGun_C") then
			state:set_rotation_offset(Vector3f.new(0, -1.701, 0))
			state:set_location_offset(Vector3f.new(4.410, -3.000, -3.300)) --forward , up, right
		elseif string.find(currentWeapon:get_full_name(), "AutomaticNailer_C") then
			state:set_rotation_offset(Vector3f.new(-0.032, -3.261, 0.116))
			state:set_location_offset(Vector3f.new(-2.782, -0.176, -3.247)) --forward , up, right
		elseif string.find(currentWeapon:get_full_name(), "Shotgun_C") then
			state:set_rotation_offset(Vector3f.new(0.072, 1.547, -0.106))
			state:set_location_offset(Vector3f.new(-28.237, -2.299, 2.913)) --forward , up, right
		elseif string.find(currentWeapon:get_full_name(), "HandCanon_C") then
			state:set_rotation_offset(Vector3f.new(0.072, 1.547, -0.106))
			state:set_location_offset(Vector3f.new(-31.237, -2.299, 2.913)) --forward , up, right
		elseif string.find(currentWeapon:get_full_name(), "Crossbow_C") then
			state:set_rotation_offset(Vector3f.new(-0.022, 1.545, -0.039))
			state:set_location_offset(Vector3f.new(-6.571, 0.516, 4.303)) --forward , up, right
		else --default for all guns
			state:set_rotation_offset(Vector3f.new(0, -1.481, 0))
			state:set_location_offset(Vector3f.new(4.410, -2.790, -2.310)) --forward , up, right			
		end
		--[[local currentWeaponWidget = getCurrentWeaponWidget(currentWeapon)
		if activeWeaponWidget ~= currentWeaponWidget then 
			attachCurrentWeaponWidget(currentWeaponWidget)
		end
		activeWeaponWidget = currentWeaponWidget]]
	end
	--[[if currentWeapon == nil and activeWeapon ~= nil then --transition between weapon and no weapon
		local currentWeaponWidget = getCurrentWeaponWidget(currentWeapon)
		if activeWeaponWidget ~= currentWeaponWidget then 
			attachCurrentWeaponWidget(currentWeaponWidget)
		end
		activeWeaponWidget = currentWeaponWidget
	end]]
	activeHand = hand
	activeWeapon = currentWeapon
	
	--[[if lastWeapon ~= activeWeapon then
		if on_weapon_change ~= nil then
			on_weapon_change(activeWeapon,	activeWeapon ~= nil and not string.find(activeWeapon:get_full_name(), "NoWeapon"))
		end		
	end]]	
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

function isSolvingPuzzle()
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		return pawn.isSolvingPuzzle
	end
end

function isClimbing()
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		return pawn.IsClimbing
	end
end

--[[function createTransparentDynamicMaterialInstance()
	"Class /Script/Engine.MaterialInstanceDynamic"
end]]

function hideAllPawnMeshMaterials()
	allMeterials = uevrUtils.find_all_instances("Class /Script/Engine.Material", true)
	local baseTranslucentMaterial
	if allMeterials ~= nil then
		for _, material in pairs(allMeterials) do
			if material:GetBlendMode() == 2 then -- 2 is translucent (probably, maybe, I think?)
				baseTranslucentMaterial = material
				print(material:get_full_name())
				if string.find(material:get_full_name(),"Widget3DPassThrough.Widget3DPassThrough") then
					break
				end
			end
			--print(material:GetBlendMode())
		end
	end
	tablePawnMeshMaterials = {}
	local pawn = api:get_local_pawn(0)
	local slotNum = 0
	if pawn ~= nil then
		for _, material in pairs(pawn.Mesh:GetMaterials()) do
			--if string.find(material:get_full_name(), "MaterialInstanceConstant") then
				print("saved original material ", material:get_full_name())
				table.insert(tablePawnMeshMaterials, material)
				
				--local dynamicMaterialInstance = find_default_instance("Class /Script/Engine.MaterialInstanceDynamic")
				--local baseMaterial = uevrUtils.spawn_object("Class /Script/Engine.Material")
				--materialClass = uevrUtils.get_class("Class /Script/Engine.Material")
				--materialClass = uevrUtils.get_class("Class /Engine/EngineMaterials/DefaultMaterial.DefaultMaterial")
				--materialInstanceDynamicClass = uevrUtils.get_class("Class /Script/Engine.MaterialInstanceDynamic")
				--local baseMaterial = materialClass.new()
				--local dynamicMaterialInstance = materialInstanceDynamicClass.new(materialClass, pawn, nil)
				--local dynamicMaterialInstance = uevrUtils.spawn_object("Class /Script/Engine.MaterialInstanceDynamic", baseTranslucentMaterial)
				--dynamicMaterialInstance.Parent = baseTranslucentMaterial
				local dynamicMaterialInstance = pawn.Mesh:CreateAndSetMaterialInstanceDynamicFromMaterial(slotNum, baseTranslucentMaterial)
				dynamicMaterialInstance.BasePropertyOverrides.BlendMode = 2
				dynamicMaterialInstance:SetScalarParameterValue("Opacity", 0.0)
				--dynamicMaterialInstance:SetScalarParameterValue("BaseColor", Vector3f.new(0,0,0))
				--pawn.Mesh:SetMaterial(slotNum, dynamicMaterialInstance)
				slotNum = slotNum+1
			--end
		end
		
		for i, material in pairs(pawn.Mesh:GetMaterials()) do
			print("replaced material", material:get_full_name())
		end
	end
end

function unhideAllPawnMeshMaterials()
	local pawn = api:get_local_pawn(0)
	slotNum = 0
	if pawn ~= nil then
		for _, material in pairs(tablePawnMeshMaterials) do
			--if string.find(material:get_full_name(), "MaterialInstanceConstant") then
				print("restoring material ", material:get_full_name())
				pawn.Mesh:SetMaterial(slotNum, material)
				slotNum = slotNum+1
			--end
		end
		
		for i, material in pairs(pawn.Mesh:GetMaterials()) do
			print("restored naterial: ", material:get_full_name())
		end
	end
end

--[[MaterialInstanceConstant /Game/Characters/Caroline/Caroline_Costume_Red/Caroline_Costume_Main_RedDress/MI_Caroline_Main_RedDress_legs_pantys.MI_Caroline_Main_RedDress_legs_pantys
Material /Game/Characters/Caroline/Caroline_Costume_A/Fabric_Physic.Fabric_Physic
MaterialInstanceConstant /Game/Characters/Caroline/Caroline_Costume_Red/Caroline_Costume_Main_RedDress/MI_Caroline_Main_RedDress_jacket.MI_Caroline_Main_RedDress_jacket
MaterialInstanceConstant /Game/Characters/Caroline/Caroline_Costume_Red/Caroline_Costume_Main_RedDress/MI_Caroline_Main_RedDress_Accesories.MI_Caroline_Main_RedDress_Accesories
MaterialInstanceConstant /Game/Characters/Caroline/Caroline_Costume_Red/Caroline_Costume_Main_RedDress/MI_Caroline_Main_RedDress_Dress.MI_Caroline_Main_RedDress_Dress
MaterialInstanceConstant /Game/Characters/Caroline/Caroline_NakedSkin/MI_Caroline_NakedSkin.MI_Caroline_NakedSkin
MaterialInstanceConstant /Game/MetaHumans/NewMetaHumanIdentity/Face/Materials/Baked/MI_HeadSynthesized_Baked_LOD3_Caroline.MI_HeadSynthesized_Baked_LOD3_Caroline]]


--[[hook_function("Class /Script/Engine.Actor", "K2_OnBecomeViewTarget", false, nil,
	function(fn, obj, locals, result)
			print("hooked K2_OnBecomeViewTarget", player.PlayerCameraManager.ViewTarget.Target:get_full_name())
			if regularPlay then
				if string.find(player.PlayerCameraManager.ViewTarget.Target:get_full_name(), "PersistentLevel.CameraActor") then
					print("hooked K2_OnBecomeViewTarget", player.PlayerCameraManager.ViewTarget.Target:get_full_name())
					player = player or api:get_player_controller(0)
					pawn = pawn or api:get_local_pawn(0)
					if player:GetViewTarget() ~= pawn then
						player:SetViewTargetWithBlend(pawn, 0.0, 1, 1.0, nil)
					end
			--fixCamera()
				end
			end		
		end
, true)]]


--[[hook_function("BlueprintGeneratedClass /Game/Characters/BP_TormentedSoulsCharacter.BP_TormentedSoulsCharacter_C", "K2_OnEndViewTarget", false, nil,
	function(fn, obj, locals, result)	
		if normalPlay then
			print("hooked K2_OnEndViewTarget")
			if string.find(player.PlayerCameraManager.ViewTarget.Target:get_full_name(), "PersistentLevel.CameraActor") then
				player = player or api:get_player_controller(0)
				pawn = pawn or api:get_local_pawn(0)
				if player:GetViewTarget() ~= pawn then
					--player:SetViewTargetWithBlend(pawn, 0.0, 1, 1.0, nil)
					fixCamera()
				end
		--fixCamera()
			end
		end	
	end
, true)]]


--[[hook_function("Class /Script/Engine.PlayerController", "SetViewTargetWithBlend", false, nil,
	function(fn, obj, locals, result)
		if normalPlay then
			local player = api:get_player_controller(0)
			if player ~= nil then       
				if player.PlayerCameraManager ~= nil and player.PlayerCameraManager.ViewTarget ~= nil and player.PlayerCameraManager.ViewTarget.Target ~= nil then 			
						if string.find(player.PlayerCameraManager.ViewTarget.Target:get_full_name(), "PersistentLevel.CameraActor") then
							--print("locals.NewViewTarget", locals.NewViewTarget:get_full_name())
							print("destroying camera actor that is about to be switched to: ",player.PlayerCameraManager.ViewTarget.Target:get_full_name())
							--player.PlayerCameraManager.ViewTarget.Target:K2_DestroyActor()
						end
					--if locals.NewViewTarget ~= nil then
					--end
					--print(locals.BlendTime) -- 8.9
					--print(locals.bLockOutgoing) -- false
					--print(locals.BlendFunc)
					--print(locals.BlendExp)
					--locals.BlendFunc = 164
					--locals.BlendExp = 0.0
					--locals.BlendTime = 300
					--locals.bLockOutgoing = true
				end
			end
		end
	end
, true)]]

hook_function("Class /Script/Engine.PlayerController", "SetViewTargetWithBlend", false, 
	function(fn, obj, locals, result)
		if normalPlay then
			pcall(setNeedTofixCamera)
		end
	end,
	function(fn, obj, locals, result)
		if needToFixCamera then
			--CharacterMovementComponent /Game/Characters/Caroline/BP_CarolineNew.Default__BP_CarolineNew_C.CharMoveComp
			fix_interaction_icon() 
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
				print("last camera switched to: ", player.PlayerCameraManager.ViewTarget.Target:get_full_name())
			--end
			needToFixCamera = true	
		end
	end
end


function fixCamera()
	if currentLevelName == nil or not string.find(currentLevelName, "Bunker_Elevator") then
		local pawn = api:get_local_pawn(0)
		if pawn ~= nil then
			--[[if  pawn.NorthCamera ~=nil then	
				pawn.NorthCamera.Roll =0
				pawn.NorthCamera.Yaw =0
				pawn.NorthCamera.Pitch =0
			end]]
			--if pawn.AutoNorth ~= nil then
			--	pawn.AutoNorth = true
			--end
		end
		
		--[[cameraActors = uevrUtils.find_all_instances("Class /Script/Engine.CameraActor", false)
		if cameraActors ~= nil then
			--remove all irelevant actors
	
			for i = #cameraActors, 1, -1 do
				if not string.find(cameraActors[i]:get_full_name(), "PersistentLevel.CameraActor") then
					table.remove(cameraActors, i)
				end
			end
			--if currentSetOfFixedCameras == nil or cameraActors[1] ~= currentSetOfFixedCameras[1] or #cameraActors ~= #currentSetOfFixedCameras then --new set of camera actors to destroy...
				--currentSetOfFixedCameras = cameraActors
				for _, cameraActor in pairs(cameraActors) do
					--if string.find(cameraActor:get_full_name(), "PersistentLevel.CameraActor") then
						--print("working on", cameraActor:get_full_name())
						if cameraActor.K2_DestroyActor ~= nil then
							--print("destroying camera actor: ",cameraActor:get_full_name())
							--cameraActor:K2_DestroyActor()
							--cameraActor:TearOff()
							--cameraActor.bTearOff = true
							--cameraActor.bFindCameraComponentWhenViewTarget = false
						end
					--end
				end
			--end
		end]]
		
		local player = api:get_player_controller(0)
		if player ~= nil then       
			if player.PlayerCameraManager ~= nil and player.PlayerCameraManager.ViewTarget ~= nil and player.PlayerCameraManager.ViewTarget.Target ~= nil then   					
				--if player.PlayerCameraManager.ViewTarget.Target ~= pawn then
					--if string.find(player.PlayerCameraManager.ViewTarget.Target:get_full_name(), "PersistentLevel.CameraActor") then
						--if player.PlayerCameraManager.ViewTarget.Target.K2_DestroyActor ~= nil then
							--print("destroying camera actor on camera change: ", player.PlayerCameraManager.ViewTarget.Target:get_full_name())
							--player.PlayerCameraManager.ViewTarget.Target:K2_DestroyActor()
							--player.PlayerCameraManager.ViewTarget.Target:TearOff()
							--player.PlayerCameraManager.ViewTarget.Target.bTearOff = true
							--player.PlayerCameraManager.ViewTarget.Target.bFindCameraComponentWhenViewTarget = false
						--end
					--print(player.PlayerCameraManager.ViewTarget.Target:get_full_name())
					--print(player.PlayerCameraManager.ViewTarget.Target.bHidden)
					--print(player.PlayerCameraManager.ViewTarget.Target.AutoActivateForPlayer) --0
					--print(player.PlayerCameraManager.ViewTarget.Target.CustomTimeDilation) --1
					--print(player.PlayerCameraManager.ViewTarget.Target.DefaultUpdateOverlapsMethodDuringLevelStreaming) --2
					--player.PlayerCameraManager.ViewTarget.Target.bHidden = false
					--player.PlayerCameraManager.ViewTarget.Target.AutoActivateForPlayer =0
					--player.PlayerCameraManager.ViewTarget.Target.CustomTimeDilation = 1
					--player.PlayerCameraManager.ViewTarget.Target.DefaultUpdateOverlapsMethodDuringLevelStreaming = 200
					--end
				--end
				
				player.PlayerCameraManager.ViewTarget.Target = pawn
				
				--[[if player.PlayerCameraManager.PendingViewTarget ~= nil then
					player.PlayerCameraManager.PendingViewTarget.Target = pawn
				end]]
			end
		end
	end
end

function fixDirection()
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		local player = api:get_player_controller(0)
		if player ~= nil then       
				if player.PlayerCameraManager ~= nil and player.PlayerCameraManager.Owner ~= nil then                    
						player.PlayerCameraManager.Owner:ClientSetLocation(pawn:K2_GetActorLocation(), pawn:K2_GetActorRotation())
				end
		end
	end
end 



function applyMainMenuSettings() 
	normalPlay = false

	vr.set_mod_value("VR_2DScreenMode", false)
	vr.set_mod_value("UI_Distance", 2.0)

	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
				
	vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	vr.set_mod_value("VR_CameraUpOffset", "0.000000")				
	vr.set_mod_value("VR_LerpCameraYaw", "false")

	
    vr.set_mod_value("VR_DecoupledPitchUIAdjust", "false")

	UEVR_UObjectHook.set_disabled(true)

	local pawn = api:get_local_pawn(0)
	if pawn ~= nil and pawn.Mesh ~=nil then		
		pawn.Mesh:SetVisibility(true)
		pawn.Mesh:SetRenderInMainPass(true)
		pawn.Mesh:SetRenderCustomDepth(true)
		pawn.Mesh:SetRenderInDepthPass(true)
		if pawn.Mesh.AttachChildren ~=nil then
			for _, attachChild in pairs(pawn.Mesh.AttachChildren) do
				if string.find(attachChild:get_full_name(), "carolineHair_Proxy") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(true)
					attachChild:SetRenderCustomDepth(true)
				elseif string.find(attachChild:get_full_name(), "EyePatch_lp") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(true)
					attachChild:SetRenderCustomDepth(true)
				elseif string.find(attachChild:get_full_name(), "CarolineFace_General") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(true)
					attachChild:SetRenderCustomDepth(true)
				elseif string.find(attachChild:get_full_name(), "ShoulderLamp_C") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(true)
					attachChild:SetRenderCustomDepth(true)
				elseif string.find(attachChild:get_full_name(), "BP_ShoulderLamp_C") then
					if attachChild ~=nil then
						for _, attachChildChild in pairs(attachChild.AttachChildren) do
							if string.find(attachChildChild:get_full_name(), "StaticMesh") then
								attachChildChild:SetVisibility(true)
								attachChildChild:SetRenderInMainPass(true)
								attachChildChild:SetRenderInDepthPass(true)
								attachChildChild:SetRenderCustomDepth(true)
								break
							end
						end
					end
				end
			end
		end
	end

	lastAimingOffset = nil
	correctAimingRight = false
	correctAimingLeft = false
	if configui.getValue("disable_6dof") == false then
		hands.hideHands(true)
	end

end


function applyCinematicSettings() 
	normalPlay = false
	vr.set_mod_value("VR_2DScreenMode", true)
	vr.set_mod_value("UI_Distance", 2.0)

	vr.set_mod_value("VR_AimMethod", "0")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
				
	vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	vr.set_mod_value("VR_CameraUpOffset", "0.000000")				
	vr.set_mod_value("VR_LerpCameraYaw", "false")

	
        vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
	
	
	UEVR_UObjectHook.set_disabled(true)

	local pawn = api:get_local_pawn(0)
	if pawn ~= nil and pawn.Mesh ~=nil then		
		pawn.Mesh:SetVisibility(true)
		pawn.Mesh:SetRenderInMainPass(true)
		pawn.Mesh:SetRenderCustomDepth(true)
		pawn.Mesh:SetRenderInDepthPass(true)
		if pawn.Mesh.AttachChildren ~=nil then
			for _, attachChild in pairs(pawn.Mesh.AttachChildren) do
				if string.find(attachChild:get_full_name(), "carolineHair_Proxy") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(true)
					attachChild:SetRenderCustomDepth(true)
				elseif string.find(attachChild:get_full_name(), "EyePatch_lp") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(true)
					attachChild:SetRenderCustomDepth(true)
				elseif string.find(attachChild:get_full_name(), "CarolineFace_General") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(true)
					attachChild:SetRenderCustomDepth(true)
				elseif string.find(attachChild:get_full_name(), "BP_ShoulderLamp_C") then
					if attachChild ~=nil then
						for _, attachChildChild in pairs(attachChild.AttachChildren) do
							if string.find(attachChildChild:get_full_name(), "StaticMesh") then
								attachChildChild:SetVisibility(true)
								attachChildChild:SetRenderInMainPass(true)
								attachChildChild:SetRenderInDepthPass(true)
								attachChildChild:SetRenderCustomDepth(true)
								break
							end
						end
					end
				end
			end
		end
	end
		
	lastAimingOffset = nil
	correctAimingRight = false
	correctAimingLeft = false
	if configui.getValue("disable_6dof") == false then
		hands.hideHands(true)
	end
end

function applySClimbingSettings()
	normalPlay = false
	--vr.set_mod_value("VR_2DScreenMode", true)
	--vr.set_mod_value("UI_Distance", 3.320)

	vr.set_mod_value("VR_AimMethod", "2")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
				
	--vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	--vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	--vr.set_mod_value("VR_CameraUpOffset", "0.000000")
	--vr.set_mod_value("VR_CameraRightOffset", "-10.000000")
	--vr.set_mod_value("VR_CameraUpOffset", "13.000000")				
	--vr.set_mod_value("VR_LerpCameraYaw", "false")

	
    vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
	
	
	UEVR_UObjectHook.set_disabled(true)

	local pawn = api:get_local_pawn(0)
	if pawn ~= nil and pawn.Mesh ~=nil then		
		pawn.Mesh:SetVisibility(true)
		pawn.Mesh:SetRenderInMainPass(true)
		pawn.Mesh:SetRenderCustomDepth(true)
		pawn.Mesh:SetRenderInDepthPass(true)
		if pawn.Mesh.AttachChildren ~=nil then
			for _, attachChild in pairs(pawn.Mesh.AttachChildren) do
				if string.find(attachChild:get_full_name(), "carolineHair_Proxy") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(true)
					attachChild:SetRenderCustomDepth(true)
				elseif string.find(attachChild:get_full_name(), "EyePatch_lp") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(true)
					attachChild:SetRenderCustomDepth(true)
				elseif string.find(attachChild:get_full_name(), "CarolineFace_General") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(true)
					attachChild:SetRenderCustomDepth(true)
				elseif string.find(attachChild:get_full_name(), "BP_ShoulderLamp_C") then
					if attachChild ~=nil then
						for _, attachChildChild in pairs(attachChild.AttachChildren) do
							if string.find(attachChildChild:get_full_name(), "StaticMesh") then
								attachChildChild:SetVisibility(true)
								attachChildChild:SetRenderInMainPass(true)
								attachChildChild:SetRenderInDepthPass(true)
								attachChildChild:SetRenderCustomDepth(true)
								break
							end
						end
					end
				end
			end
		end
	end
	
	lastAimingOffset = nil
	correctAimingRight = false
	correctAimingLeft = false
	if configui.getValue("disable_6dof") == false then
		hands.hideHands(true)
	end


end

function applyBunkerElevatorSettings()
	normalPlay = false
	--vr.set_mod_value("VR_2DScreenMode", true)
	--vr.set_mod_value("UI_Distance", 3.320)

	vr.set_mod_value("VR_AimMethod", "2")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
				
	--vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	--vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	--vr.set_mod_value("VR_CameraUpOffset", "0.000000")
	--vr.set_mod_value("VR_CameraRightOffset", "-10.000000")
	--vr.set_mod_value("VR_CameraUpOffset", "13.000000")				
	--vr.set_mod_value("VR_LerpCameraYaw", "false")

	
    vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
	
	
	UEVR_UObjectHook.set_disabled(true)

	local pawn = api:get_local_pawn(0)
	if pawn ~= nil and pawn.Mesh ~=nil then		
		pawn.Mesh:SetVisibility(true)
		pawn.Mesh:SetRenderInMainPass(true)
		pawn.Mesh:SetRenderCustomDepth(true)
		pawn.Mesh:SetRenderInDepthPass(true)
		if pawn.Mesh.AttachChildren ~=nil then
			for _, attachChild in pairs(pawn.Mesh.AttachChildren) do
				if string.find(attachChild:get_full_name(), "carolineHair_Proxy") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(true)
					attachChild:SetRenderCustomDepth(true)
				elseif string.find(attachChild:get_full_name(), "EyePatch_lp") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(true)
					attachChild:SetRenderCustomDepth(true)
				elseif string.find(attachChild:get_full_name(), "CarolineFace_General") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(true)
					attachChild:SetRenderCustomDepth(true)
				elseif string.find(attachChild:get_full_name(), "BP_ShoulderLamp_C") then
					if attachChild ~=nil then
						for _, attachChildChild in pairs(attachChild.AttachChildren) do
							if string.find(attachChildChild:get_full_name(), "StaticMesh") then
								attachChildChild:SetVisibility(true)
								attachChildChild:SetRenderInMainPass(true)
								attachChildChild:SetRenderInDepthPass(true)
								attachChildChild:SetRenderCustomDepth(true)
								break
							end
						end
					end
				end
			end
		end
	end
	normalPlay = isRegularPlay()
	lastAimingOffset = nil
	correctAimingRight = false
	correctAimingLeft = false
	if configui.getValue("disable_6dof") == false then
		hands.hideHands(true)
	end


end


function applySolvingPuzzleSettings() 	
	normalPlay = false
	vr.set_mod_value("VR_2DScreenMode", true)
	--vr.set_mod_value("UI_Distance", 3.320)

	vr.set_mod_value("VR_AimMethod", "2")
	vr.set_mod_value("VR_RoomscaleMovement", "0")
	vr.set_mod_value("VR_DecoupledPitch", "0")
				
	--vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
	--vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	--vr.set_mod_value("VR_CameraUpOffset", "0.000000")
	--vr.set_mod_value("VR_CameraRightOffset", "-10.000000")
	--vr.set_mod_value("VR_CameraUpOffset", "13.000000")				
	--vr.set_mod_value("VR_LerpCameraYaw", "false")

	
        vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
	
	
	UEVR_UObjectHook.set_disabled(true)

	local pawn = api:get_local_pawn(0)
	if pawn ~= nil and pawn.Mesh ~=nil then		
		pawn.Mesh:SetVisibility(true)
		pawn.Mesh:SetRenderInMainPass(true)
		pawn.Mesh:SetRenderCustomDepth(true)
		pawn.Mesh:SetRenderInDepthPass(true)
		if pawn.Mesh.AttachChildren ~=nil then
			for _, attachChild in pairs(pawn.Mesh.AttachChildren) do
				if string.find(attachChild:get_full_name(), "carolineHair_Proxy") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(true)
					attachChild:SetRenderCustomDepth(true)
				elseif string.find(attachChild:get_full_name(), "EyePatch_lp") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(true)
					attachChild:SetRenderCustomDepth(true)
				elseif string.find(attachChild:get_full_name(), "CarolineFace_General") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(true)
					attachChild:SetRenderCustomDepth(true)
				elseif string.find(attachChild:get_full_name(), "BP_ShoulderLamp_C") then
					if attachChild ~=nil then
						for _, attachChildChild in pairs(attachChild.AttachChildren) do
							if string.find(attachChildChild:get_full_name(), "StaticMesh") then
								attachChildChild:SetVisibility(true)
								attachChildChild:SetRenderInMainPass(true)
								attachChildChild:SetRenderInDepthPass(true)
								attachChildChild:SetRenderCustomDepth(true)
								break
							end
						end
					end
				end
			end
		end
	end

	lastAimingOffset = nil
	correctAimingRight = false
	correctAimingLeft = false
	if configui.getValue("disable_6dof") == false then
		hands.hideHands(true)
	end


end


function isRegularPlay() 
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil then
		return pawn.CanMove or pawn.isDodging
	end
end

function fix_interaction_icon() 
	if configui.getValue("enable_prononocued_interaction_widget") then
		interactWidgets = uevrUtils.find_all_instances("WidgetBlueprintGeneratedClass /Game/InventorySystem/PickUps/WBP_InteractionPickUp.WBP_InteractionPickUp_C",false)

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
			end
		end
	end
end

function disableLockOn()
	if configui.getValue("disable_6dof") == false then		
		if configui.getValue("enable_lock_on") == false then	
			if pawn.CurrentEnemy ~= nil then -- no lock on
				--pawn:ResetAimToTarget()
				--pawn:RotateToTarget()
				currentEnemy = pawn.CurrentEnemy
				pawn.CurrentEnemy = nil
			end
			if pawn.TempEnemy ~= nil then -- no lock on
				pawn.TempEnemy = nil
			end
		end
	end
end

function fixShooting()
	correctAimingRight = false
	correctAimingLeft = false
	if pawn.isAiming then
		if activeWeapon ~= nil then
			--forceEnemiesVulnerable()
			
			local controller_index = params.vr.get_right_controller_index()
			local right_controller_position = UEVR_Vector3f.new()
			local right_controller_rotation = UEVR_Quaternionf.new()
			params.vr.get_pose(right_controller_index, right_controller_position, right_controller_rotation)
			
			--[[if lastAimingOffset ~= nil then
				local controller_index
				if hand == Handed.Right then
					controller_index = params.vr.get_right_controller_index()
				else
					controller_index = params.vr.get_left_controller_index()
				end
				
				
				--print(right_controller_position.x- lastAimingOffset.x)
				if right_controller_position.x - lastAimingOffset.x > 0.01 then
					print("correct aiming right")
					correctAimingRight = true
					pawn:ResetAimToTarget()
					pawn:RotateToTarget()
				elseif right_controller_position.x - lastAimingOffset.x < -0.01 then
					print("correct aiming left")
					correctAimingLeft = true
					pawn:ResetAimToTarget()
					pawn:RotateToTarget()
				end
			end
			
			lastAimingOffset = right_controller_position]]			
			
			local ctrlWorldRotation
			if hand == Handed.Right then
				ctrlWorldRotation = controllers.getControllerRotation(1)
			else
				ctrlWorldRotation = controllers.getControllerRotation(0)
			end
			local invCharRot = kismet_math_library:NegateRotator(pawn:K2_GetActorRotation())
			--apply the controller rotation as offset on the pawn's rotation as RotationToAim expects pawn-local coordinates,and the controller provides world coordinates
			local localRotation = kismet_math_library:ComposeRotators(invCharRot, ctrlWorldRotation)
			--local localRotation = kismet_math_library:ComposeRotators(pawn:K2_GetActorRotation(), ctrlWorldRotation)
			--print(localRotation.Y)
			
			--[[if localRotation.Y > 10 then
				correctAimingRight = true
				print("correct aiming right", currentEnemy:get_full_name())
				--pawn:ResetAimToTarget()
				if currentEnemyAlreadySwitchedTo == false then
					pawn.CurrentEnemy = currentEnemy
					currentEnemyAlreadySwitchedTo = true
				else
					pawn.CurrentEnemy = nil
				end
				--pawn:RotateToTarget()
				--pawn["Rotate To Enemy"]()
			elseif localRotation.Y < -10 then
				print("correct aiming left", currentEnemy:get_full_name())
				correctAimingLeft = true
				--pawn:ResetAimToTarget()
				if currentEnemyAlreadySwitchedTo == false then
					pawn.CurrentEnemy = currentEnemy
					currentEnemyAlreadySwitchedTo = true
				else
					pawn.CurrentEnemy = nil
				end
				--pawn:RotateToTarget()
				--pawn["Rotate To Enemy"]()
			else
				currentEnemyAlreadySwitchedTo = false
				pawn.CurrentEnemy = nil
			end]]
		
			-- Apply character-local rotation
			--if pawn.CanRotateTarget == false then
			--	print("pawn.CantRotateTarget")
			--end
			
			pawn.RotationToAim = localRotation
			pawn:RotateToTarget()
			--local invCharRot1 = kismet_math_library:NegateRotator(activeWeaponMuzzleCode:K2_GetActorRotation())
			--apply the controller rotation as offset on the pawn's rotation as RotationToAim expects pawn-local coordinates,and the controller provides world coordinates
			--local localRotation1 = kismet_math_library:ComposeRotators(invCharRot, ctrlWorldRotation)
			
			--[[local ctrlWorldDirection
			if hand == Handed.Right then
				ctrlWorldDirection = controllers.getControllerDirection(1)
			else
				ctrlWorldDirection = controllers.getControllerDirection(0)
			end]]
			--activeWeaponMuzzleCode:SetRelativeRotation(ctrlWorldDirection:ToRotator())
			--[[if pawn.TempEnemy ~= nil then
				pawn.TargetAssigned = true
			end]]
			--pawn:ResetAimToTarget()
			--[[if pawn.WeaponSystemComponent.CurrentWeapon.fixTransform ~= nil then
				print("resetting fixTransform")
				pawn.WeaponSystemComponent.CurrentWeapon.fixTransform = uevrUtils.get_transform({0,0,0},{X=ctrlWorldRotation.X, Y = ctrlWorldRotation.Y, Z = ctrlWorldRotation.Z, W =ctrlWorldRotation.W} ,nil, nil)
			end
			if pawn.WeaponSystemComponent.CurrentWeapon.FixTransformAux ~= nil then
				print("resetting fixTransformAux")
				pawn.WeaponSystemComponent.CurrentWeapon.FixTransformAux = uevrUtils.get_transform({0,0,0},{X=ctrlWorldRotation.X, Y = ctrlWorldRotation.Y, Z = ctrlWorldRotation.Z, W =ctrlWorldRotation.W} ,nil, nil)
			end
			if pawn.WeaponSystemComponent.CurrentWeapon.FixTransformAux2 ~= nil then
				print("resetting fixTransformAux2")
				pawn.WeaponSystemComponent.CurrentWeapon.FixTransformAux2 = uevrUtils.get_transform({0,0,0},{X=ctrlWorldRotation.X, Y = ctrlWorldRotation.Y, Z = ctrlWorldRotation.Z, W =ctrlWorldRotation.W} ,nil, nil)
			end]]
			--pawn:K2_SetActorRotation(localRotation, false)
			--print("fixing aiming")

			--[[if activeWeapon ~= nil and activeWeapon.CanApplyDamage == false then
				print("weapon cooldown detected")
			end
			if pawn.CurrentEnemies ~=nil then
				for _, enemy in pairs(pawn.CurrentEnemies) do
					if enemy.isInvulnerable == true then
						print("Invulnerable", enemy:get_full_name())
					end
				end
			end]]
			
			--print("fixing shooting", pawn.RotationToAim.Yaw )
			--pawn.RotationToAim = activeWeaponMuzzle:K2_GetActorRotation()
			--[[if hand == Handed.Right then
				pawn.RotationToAim = controllers.getControllerRotation(1)
			else
				pawn.RotationToAim = controllers.getControllerRotation(0)
			end]]
			
		end
	else 
		lastAimingOffset = nil
		correctAimingRight = false
		correctAimingLeft = false
	end
end




function forceEnemiesVulnerable()	
	-- Iterate through all current enemies and disable invulnerability
	allEnemies = uevrUtils.find_all_instances("BlueprintGeneratedClass /Game/Enemies/Commmon/Base/BP_BaseEnemy.BP_BaseEnemy_C", false)
	if allEnemies ~= nil then
		print("allEnemies", #allEnemies)	
		for _, enemy in pairs(allEnemies) do
			if enemy ~= nil then
				print("working on enemy", enemy:get_full_name())
				-- Access the enemy's damage system component
				local damageSystem = enemy.BPC_AI_DamageSystem
				if damageSystem ~= nil then
					-- Force the enemy to be vulnerable to damage
					if damageSystem.isInvulnerable then
						print("isInvulnerable")
					end
					damageSystem.isInvulnerable = false
				end
			end
		end
	end
end

local melee_data = {
    right_hand_pos_raw = UEVR_Vector3f.new(),
    right_hand_q_raw = UEVR_Quaternionf.new(),
    right_hand_pos = Vector3f.new(0, 0, 0),
    last_right_hand_raw_pos = Vector3f.new(0, 0, 0),
    last_time_messed_with_attack_request = 0.0,
    first = true,
}

function isMeleeWeapon()
	if activeWeapon ~= nil then
		return string.find(activeWeapon:get_full_name(),"Hammer_Weapon_C") ~= nil or string.find(activeWeapon:get_full_name(),"Crowbar_Weapon_C") ~= nil or string.find(activeWeapon:get_full_name(),"ChainSaw_C") ~= nil or string.find(activeWeapon:get_full_name(),"AxeWeapon_C") ~= nil
	end
	return false
end

function checkMeleeSwing(delta)
	if hand == Handed.Right then
		vr.get_pose(vr.get_right_controller_index(), melee_data.right_hand_pos_raw, melee_data.right_hand_q_raw)
	else
		vr.get_pose(vr.get_right_controller_index(), melee_data.right_hand_pos_raw, melee_data.right_hand_q_raw)
	end

    -- Copy without creating new userdata
    melee_data.right_hand_pos:set(melee_data.right_hand_pos_raw.x, melee_data.right_hand_pos_raw.y, melee_data.right_hand_pos_raw.z)

    if melee_data.first then
        melee_data.last_right_hand_raw_pos:set(melee_data.right_hand_pos.x, melee_data.right_hand_pos.y, melee_data.right_hand_pos.z)
        melee_data.first = false
    end

    local velocity = (melee_data.right_hand_pos - melee_data.last_right_hand_raw_pos) * (1 / delta)

    -- Clone without creating new userdata
    melee_data.last_right_hand_raw_pos.x = melee_data.right_hand_pos_raw.x
    melee_data.last_right_hand_raw_pos.y = melee_data.right_hand_pos_raw.y
    melee_data.last_right_hand_raw_pos.z = melee_data.right_hand_pos_raw.z
    melee_data.last_time_messed_with_attack_request = melee_data.last_time_messed_with_attack_request + delta
	
	local vel_len = velocity:length()
	if velocity.y < 0 then
		swingingFast = vel_len >= 2.5 -- Detect melee gesture
	end
end


function applyNormalModeSettings(delta) 
		

	--normalPlay = true
	vr.set_mod_value("VR_2DScreenMode", false)
	vr.set_mod_value("UI_Distance", 2.0)


	vr.set_mod_value("VR_AimMethod", "2")
	vr.set_mod_value("VR_RoomscaleMovement", "1")
	vr.set_mod_value("VR_DecoupledPitch", "1")
		
	vr.set_mod_value("VR_CameraForwardOffset", forwardoffset)
	vr.set_mod_value("VR_CameraRightOffset", "0.000000")
	vr.set_mod_value("VR_CameraUpOffset", "0.000000")				
	vr.set_mod_value("VR_LerpCameraYaw", "false")

	
    vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
	UEVR_UObjectHook.set_disabled(false)
	
	local pawn = api:get_local_pawn(0)
	if pawn ~= nil and pawn.Mesh ~=nil then	
		
		--[[if normalPlay == false and pawn.CanMove then
			UEVR_UObjectHook.activate()
			UEVR_UObjectHook.remove_motion_controller_state(pawn.Mesh) --workaround for dissapearing mesh after puzzle solving
			newHmdPawn = UEVR_UObjectHook.get_or_add_motion_controller_state(pawn.Mesh)
			newHmdPawn:set_hand(2)
			newHmdPawn:set_permanent(true)
			newHmdPawn:set_location_offset(Vector3f.new(0, 26.899999618530273, -1.249))
		end]]
		local currentNormalPlay = normalPlay
		local newNormalPlay = isRegularPlay() 
		if currentNormalPlay ~= newNormalPlay then
			if newNormalPlay == true then --entering normal play
				--hideAllPawnMeshMaterials()
				fix_interaction_icon() 
			else  --exiting normal play
				--unhideAllPawnMeshMaterials()
			end
		end
		normalPlay = newNormalPlay
		
		pawn.Mesh:SetVisibility(true)
		if configui.getValue("disable_6dof") == false then	
			pawn.Mesh:SetRenderInMainPass(pawn.isInputDisabled)
			pawn.Mesh:SetRenderInDepthPass(pawn.isInputDisabled)
			pawn.Mesh:SetRenderCustomDepth(pawn.isInputDisabled)
		else
			pawn.Mesh:SetRenderInMainPass(true)
			pawn.Mesh:SetRenderInDepthPass(true)
			pawn.Mesh:SetRenderCustomDepth(true)
		end
		--pawn.Mesh.bOwnerNoSee = false
		--pawn.Mesh:K2_SetWorldLocationAndRotation(pawn:K2_GetActorLocation(), pawn:K2_GetActorRotation(), false, )
		if pawn.Mesh.AttachChildren ~=nil then
			for _, attachChild in pairs(pawn.Mesh.AttachChildren) do
				if string.find(attachChild:get_full_name(), "carolineHair_Proxy") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(pawn.isInputDisabled)
					attachChild:SetRenderInDepthPass(pawn.isInputDisabled)
					attachChild:SetRenderCustomDepth(pawn.isInputDisabled)
				elseif string.find(attachChild:get_full_name(), "EyePatch_lp") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(pawn.isInputDisabled)
					attachChild:SetRenderInDepthPass(pawn.isInputDisabled)
					attachChild:SetRenderCustomDepth(pawn.isInputDisabled)
				elseif string.find(attachChild:get_full_name(), "CarolineFace_General") then
					attachChild:SetVisibility(true)
					attachChild:SetRenderInMainPass(pawn.isInputDisabled)
					attachChild:SetRenderInDepthPass(pawn.isInputDisabled)
					attachChild:SetRenderCustomDepth(pawn.isInputDisabled)
				elseif string.find(attachChild:get_full_name(), "BP_ShoulderLamp_C") then
					if attachChild ~=nil then
						for _, attachChildChild in pairs(attachChild.AttachChildren) do
							if string.find(attachChildChild:get_full_name(), "StaticMesh") then
								attachChildChild:SetVisibility(true)
								attachChildChild:SetRenderInMainPass(pawn.isInputDisabled)
								attachChildChild:SetRenderInDepthPass(pawn.isInputDisabled)
								attachChildChild:SetRenderCustomDepth(pawn.isInputDisabled)
								break
							end
						end
					end
				end
			end
		end
	end
	if configui.getValue("disable_6dof") == false then		
		if not pawn.isAiming then
			lastAimingOffset = nil
			correctAimingRight = false
			correctAimingLeft = false
		end
		if pawn.isInputDisabled then
			hands.hideHands(true)
		elseif normalPlay == true then
			hands.hideHands(false)
			disableLockOn()
			fixShooting()
			pcall(fixDirection)
			success, result = pcall(isMeleeWeapon)
			if success == true and result == true then
				checkMeleeSwing(delta)
			end
		end
	else
		pcall(fixDirection)
	end
	
	--[[
	if SUPPORT_HUD_ON_HAND == true then
		--make the foreground color go away
		--attachStatsBar()
		pcall(sortStatsBarOpacity)
		
	end

	if not inMelee then
		
	end]]
end

function getCurrentWeaponWidget(currentWeapon)
	if currentWeapon ~= nil then
		print("Searching for widget for", currentWeapon:get_full_name())
		allItemSlotWidgets = uevrUtils.find_all_instances("WidgetBlueprintGeneratedClass /Game/InventorySystem/UI_Inventory/WBP_ItemSlot.WBP_ItemSlot_C", false)
		if allItemSlotWidgets ~= nil then
			for _, itemSlotWidget in pairs(allItemSlotWidgets) do
				print("curr widget", itemSlotWidget:GetItemID())
				print(itemSlotWidget:get_full_name())
				if string.find(currentWeapon:get_full_name(), "NailGun_C") then
					if string.find(itemSlotWidget:get_full_name(), "Shortcuts") and not string.find(itemSlotWidget:get_full_name(), "Ammo") and string.find(itemSlotWidget:GetItemID(), "Nailgun") then
						print(itemSlotWidget:GetItemID())
						print(itemSlotWidget:get_full_name())
						return itemSlotWidget
					end
				elseif string.find(itemSlotWidget:get_full_name(), "Shortcuts") and not string.find(itemSlotWidget:get_full_name(), "Ammo") and string.find(currentWeapon:get_full_name(), "Shotgun_C") then
					if string.find(itemSlotWidget:GetItemID(), "Shotgun") then
						print(itemSlotWidget:get_full_name())
						return itemSlotWidget
					end
				end
			end
		end
	end
	
	return nil
end

--[[function attachCurrentWeaponWidget(currentWeaponWidget)
	local controllerId
	if hand == Handed.Right then
		controllerId = 0
	else
		controllerId = 1
	end
	if controllers.getController(controllerId) ~= nil and controllers.getController(controllerId).AttachChildren ~=nil then
		for i,attachChild in pairs(controllers.getController(controllerId).AttachChildren) do
			if #controllers.getController(controllerId).AttachChildren == 2 then
					print("detaching widget")
					table.remove(controllers.getController(controllerId).AttachChildren, 1)					
				--if attachChild.Widget ~= nil and string.find(attachChild.Widget:get_full_name(), "ItemSlot") then
					--table.remove(controllers.getController(controllerId).AttachChildren, i) --remove item
				--end
			end
		end				 
	end
	if currentWeaponWidget ~= nil then
		print("attaching current widget")
		currentWeaponWidget.ColorAndOpacity.A = 0.5
		myWidgetComponent = uevrUtils.createWidgetComponent(currentWeaponWidget, {manualAttachment=false, removeFromViewport=false, relativeTransform = uevrUtils.get_transform({X=-17.830,Y=-1.280,Z=6.62},{X=0.0, Y=0.0, Z=0.0, W=1.0}, {X=0.1, Y=0.1, Z=0.1}), drawSize=vector_2(222, 520)}) 			
		controllers.attachComponentToController(controllerId, myWidgetComponent, nil, nil, nil, true)
		uevrUtils.set_component_relative_transform(myWidgetComponent, {X=-21.200000762939453,Y=-4.800000190734863,Z=-0.6000000238418579}, {Pitch=155.0,Yaw=117.0,Roll=277.0}, {0.05, 0.05, 0.05}) -- z - forwad , y = right , x - up
	end
end]]
