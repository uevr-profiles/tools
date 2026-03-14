--Based on the original work of CJ117

local uevrUtils = require("libs/uevr_utils")
--uevrUtils.setLogLevel(LogLevel.Debug)
uevrUtils.initUEVR(uevr)
--local flickerFixer = require("libs/flicker_fixer")
local controllers = require("libs/controllers")
local animation = require("libs/animation")
local hands = require("libs/hands")
local configui = require("libs/configui")
local weapons = require("addons/weapons")
local handAnimations = require("addons/hand_animations")
local handAnimationsMurphy = require("addons/hand_animations_murphy")
local handAnimationsScientist = require("addons/hand_animations_scientist")
local reticule = require("libs/reticule")
--local dev = require("libs/uevr_dev")
local scope = require("libs/scope")
local cameraModifiers = require("addons/camera_modifiers")
local grabbables = require("addons/grabbables")
local gestures = require("libs/gestures")

-- hands.setLogLevel(LogLevel.Debug)
-- reticule.setLogLevel(LogLevel.Debug)
-- controllers.setLogLevel(LogLevel.Debug)
-- grabbables.setLogLevel(LogLevel.Debug)

-- dev.init()

local handedness = Handed.Right

local handParams = 
{
	Arms = 
	{
		Left = 
		{
			Name = "lowerarm_l",
			Rotation = {0, 90, -90},
			Location = {2.8, -40.7, -1.5},	
			Scale = {1, 1, 1},			
			AnimationID = "left_hand"
		},
		Right = 
		{
			Name = "lowerarm_r",
			Rotation = {0, -90, 90},
			Location = {-2.8, -40.7, -1.5},		
			Scale = {1, 1, 1},			
			AnimationID = "right_hand"
		}
	}
}

local handParamsHuman = 
{
	Arms = 
	{
		Left = 
		{
			Name = "lowerarm_l",
			Rotation = {0, 90, -90},
			Location = {3.2, -36.4, -0.7},	
			Scale = {1, 1, 1},			
			AnimationID = "left_hand"
		},
		Right = 
		{
			Name = "lowerarm_r",
			Rotation = {0, -90, 90},
			Location = {-3.2, -36.4, -0.7},		
			Scale = {1, 1, 1},			
			AnimationID = "right_hand"
		}
	}
}
local knuckleBoneList = {24, 12, 15, 21, 18, 48, 36, 39, 45, 42}
local knuckleBoneListMurphy = {25, 41, 55, 69, 83, 178, 165, 151, 137, 123}

local isInMenu = false
local isInMainMenu = false
local levelChanged = false
local isDetecting = false
local isCSI = false
local isInteracting = false
local isConversing = false
local isInCinematic = false
local canCreateHands = false
local wasInCinematic = false
local isShowingScope = false
local currentPlayerMode = nil
local scopeAdjustDirection = 0
local scopeAdjustMode = 0

local isPunching = false
local isOnLadder = false
local isBreaching = false
local isDefusingBomb = false
local hasPunchGesture = false

local userSettings = nil

PlayerMode = {
	Robocop = 1,
	Murphy = 2,
	Scientist = 3,
	Merc = 4,
	Ed = 5,
}

function disableSnapTurn(val)
	if val then
		uevr.params.vr.set_snap_turn_enabled(false)		
	else
		uevr.params.vr.set_snap_turn_enabled(configui.getValue("useSnapTurn"))
	end
end
configui.onUpdate("useSnapTurn", function(value)
	if not isInCinematic then
		disableSnapTurn(not value)
	end
end)

function hideHUD(value)
	local vis = 0
	if value == true then vis = 1 end
	pawn.FPPHudWidget:SetVisibility(vis)
	pawn.FPPHudWidget["WB HUD"]:SetVisibility(vis)
	reticule.hide(value)
end

function onScopeDisplayChanged(isDisplaying)
	hideHUD(isDisplaying)
end

function setFixedCamera(val)
	if (configui.getValue("ui_follows_head") == true) then
		uevr.params.vr.set_aim_method((isCSI or val) and 0 or (handedness == Handed.Right and 2 or 3))
		--uevr.params.vr.set_mod_value("UI_FollowView", val and "false" or "true")
		uevr.params.vr.set_mod_value("UI_FollowView", isInCinematic and "false" or "true")	
	else
		uevr.params.vr.set_aim_method((isCSI or val) and 0 or (handedness == Handed.Right and 2 or 3))
		uevr.params.vr.set_mod_value("UI_FollowView", "false")	
		uevr.params.vr.set_mod_value("VR_DecoupledPitchUIAdjust", val and "false" or "true")		
	end
end

function updateUIMode()
	uevr.params.vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
	if configui.getValue("ui_follows_head") == false then
		uevr.params.vr.set_mod_value("UI_FollowView", "false")		
	end
	if configui.getValue("ui_follows_head") then
		uevr.params.vr.set_mod_value("UI_Distance", configui.getValue("ui_position").Z)
		uevr.params.vr.set_mod_value("UI_Size", "0.50")
		uevr.params.vr.set_mod_value("UI_X_Offset", configui.getValue("ui_position").X)
		uevr.params.vr.set_mod_value("UI_Y_Offset", configui.getValue("ui_position").Y)
	else
		uevr.params.vr.set_mod_value("UI_Distance", "8.500")
		uevr.params.vr.set_mod_value("UI_Size", "7.50")
		uevr.params.vr.set_mod_value("UI_X_Offset", "0.00")
		uevr.params.vr.set_mod_value("UI_Y_Offset", "0.00")
	end
end
updateUIMode()


configui.onUpdate("left_hand_mode", function(value)
	uevrUtils.print("New value for left_hand_mode", value)
	handedness = value and Handed.Left or Handed.Right
	local weaponMesh = getWeaponMesh()
	weapons.update(weaponMesh, handedness)
end)

configui.onUpdate("show_hands", function(value)
	uevrUtils.print("New value for show_hands", value)
	hands.destroyHands()
	hands.reset()
	weapons.reset()
end)

configui.onUpdate("useReticule", function(value)
	if value == false then
		reticule.destroy()
	end
end)

configui.onUpdate("ui_follows_head", function(value)
	setFixedCamera(isInCinematic)
	updateUIMode()
end)

local function setHeightOffset(offset)
	local base = UEVR_Vector3f.new()
	uevr.params.vr.get_standing_origin(base)
	local hmd_index = uevr.params.vr.get_hmd_index()
	local hmd_pos = UEVR_Vector3f.new()
	local hmd_rot = UEVR_Quaternionf.new()
	uevr.params.vr.get_pose(hmd_index, hmd_pos, hmd_rot)
	base.x = hmd_pos.x
	base.y = hmd_pos.y - offset
	base.z = hmd_pos.z
	uevr.params.vr.set_standing_origin(base)
end

function getPlayerMode()
	local playerMode = PlayerMode.Robocop
	if uevrUtils.getValid(pawn) ~= nil then
		local pawnName = pawn:get_full_name()
		if string.find(pawnName,"CH_FPPCharacter_DLC_Murphy_C") then
			playerMode = PlayerMode.Murphy
		elseif string.find(pawnName,"CH_FPPCharacter_DLC_Woman_C") then 
			playerMode = PlayerMode.Scientist
		elseif string.find(pawnName,"CH_FPPCharacter_DLC_Merc_C") then 
			playerMode = PlayerMode.Merc
		elseif string.find(pawnName,"CH_EDCharacter_DLC_C") then 
			playerMode = PlayerMode.Ed
		end
	end
	return playerMode	
end

configui.onUpdate("fixGammaIssue", function(value)
	if value == 1 then
		uevrUtils.print("Setting Gamma Fix to None")
		set_cvar_int("r.ShadowQuality",1)
		uevr.params.vr.set_mod_value("VR_NativeStereoFix","true")
	elseif value == 2 then
		uevrUtils.print("Setting Gamma Fix to Standard")
		if isInCinematic then
			set_cvar_int("r.ShadowQuality",0)
			uevr.params.vr.set_mod_value("VR_NativeStereoFix","false")
		else
			uevr.params.vr.set_mod_value("VR_NativeStereoFix","true")
			set_cvar_int("r.ShadowQuality",1)
		end
	elseif value == 3 then
		uevrUtils.print("Setting Gamma Fix to Max")
		set_cvar_int("r.ShadowQuality",0)
		uevr.params.vr.set_mod_value("VR_NativeStereoFix","false")
	end
end)

function fixGamma()
	-- if configui.getValue("fixGammaIssue") == 1 then
		-- set_cvar_int("r.ShadowQuality",1)
		-- uevr.params.vr.set_mod_value("VR_NativeStereoFix","true")
	-- end
	if configui.getValue("fixGammaIssue") == 2 then
		if isInCinematic and not wasInCinematic then
			set_cvar_int("r.ShadowQuality",0)
			uevr.params.vr.set_mod_value("VR_NativeStereoFix","false")
		elseif not isInCinematic and wasInCinematic then
			uevr.params.vr.set_mod_value("VR_NativeStereoFix","true")
			set_cvar_int("r.ShadowQuality",1)
		end
	elseif configui.getValue("fixGammaIssue") == 3 then
		set_cvar_int("r.ShadowQuality",0)
		uevr.params.vr.set_mod_value("VR_NativeStereoFix","false")
	end
end

function updateViewState()
	fixGamma()
	
	if isInCinematic and not wasInCinematic then
		uevrUtils.print("Start cinematic")
		setFixedCamera(not isCSI)
		hands.hideHands(true)
		disableSnapTurn(true)
		uevr.params.vr.recenter_view()
		reticule.destroy()
		uevr.params.vr.set_mod_value("VR_RoomscaleMovement","false")
	elseif not isInCinematic and wasInCinematic then
		uevrUtils.print("End cinematic")
		setFixedCamera(false)
		updateUIMode()
		hands.hideHands(false)
		disableSnapTurn(false)
		uevr.params.vr.recenter_view()
		uevr.params.vr.set_mod_value("VR_RoomscaleMovement","true")
	end
	wasInCinematic = isInCinematic
	
end

function handleLevelChange(level)
	local levelName = level:get_full_name()
	uevrUtils.print(levelName)
	
	hookLevelFunctions()
	
	if string.find(levelName, "MAP_StartingMap") then
		isInMainMenu = true
		setFixedCamera(true)
	else
		isInMainMenu = false
		setFixedCamera(false)
	end
	
	--get rid of black bars in cinematics
	for i, slot in ipairs(pawn["FPPHudWidget"]["WB HUD"]["CanvasPanel_0"]["Slots"]) do
		if string.find(slot.Content:get_full_name(), "Image_FrameTop") or string.find(slot.Content:get_full_name(), "Image_FrameBot") then
			slot.Content:SetVisibility(1)
		end
	end
		
	cameraModifiers.onLevelChange()
	
	uevr.params.vr.recenter_view()

end


function on_level_change(level)
	uevrUtils.print("Level changed")
	levelChanged = true
	userSettings = uevrUtils.find_first_instance("Class /Script/Game.MyGameUserSettings", false)

	handedness = configui.getValue("left_hand_mode") and Handed.Left or Handed.Right
	--flickerFixer.create()
	controllers.createController(0)
	controllers.createController(1)
	controllers.createController(2)
	canCreateHands = false
	hands.reset()
	weapons.onLevelChange()
	isInCinematic = false
	wasInCinematic = false
	disableSnapTurn(false)
	handleLevelChange(level)
	
	delay(2000, function()
		canCreateHands = true
	end)
end



configui.onUpdate("grabbed_item_location", function(value)
	grabbables.updateGrabbedOrientation()
end)

configui.onUpdate("grabbed_item_rotation", function(value)
	grabbables.updateGrabbedOrientation()
end)


function on_weapon_change(activeWeapon, holdingWeapon)
	uevrUtils.print("on_weapon_change called " .. (holdingWeapon and " holding weapon" or " not holding weapon"))
	local handStr = handedness == Handed.Right and "right" or "left"
	if holdingWeapon then
		animation.updateAnimation(handStr.."_hand", handStr.."_grip_weapon", false)
		animation.updateAnimation(handStr.."_hand", handStr.."_grip_weapon", true)
	else
		animation.pose(handStr.."_hand", "open_"..handStr, true)
		--animation.updateAnimation(handStr.."_hand", handStr.."_grip", false)
	end
end

function createReticule()
	local options = {
		removeFromViewport = true,
		twoSided = true,
		scale = {-0.5,-0.5,0.5}
	}
	local widget = nil
	--for murphy its Myhud ImageDot
	--hud -widget tree- rootwidget-slots-panel 0-content-slots-overlayslot5
	--OverlaySlot /Engine/Transient.GameEngine_0.BP_MyGameInstance_C_0.WB_HUDFPP_C_2.WidgetTree_0.Overlay_0.OverlaySlot_5
	local playerMode = getPlayerMode()
	if playerMode == PlayerMode.Murphy then
		uevrUtils.print("Murphy reticule")		
		options.removeFromViewport = false
	elseif playerMode == PlayerMode.Scientist or playerMode == PlayerMode.Merc then
		uevrUtils.print("Human reticule")		
		options.removeFromViewport = true
	elseif playerMode == PlayerMode.Ed then
		uevrUtils.print("Ed reticule")		
		widget = uevrUtils.getValid(pawn,{"FPPHudWidget","WB_ED209","WB_ED209Crosshair"})
		options.removeFromViewport = true
		--options.position = {0,0,50}
	else
		--print("Robocop reticule")
		-- local widgetName = "WidgetBlueprintGeneratedClass /Game/UI/WeaponsWidgets/WB_ReticleLaser.WB_ReticleLaser_C" -- Robocop		
		-- --reticule.createFromWidget(widgetName, options)					
		-- -- doing this instead to avoid the print statements when reticle cant be found in non combat sequences
		-- local widget = uevrUtils.getActiveWidgetByClass(widgetName)
		-- if uevrUtils.getValid(widget) ~= nil then
			-- reticule.createFromWidget(widget, options)
		-- end			
	end
	if widget == nil then
		widget = uevrUtils.getValid(pawn,{"FPPHudWidget","CurrentReticle"})
		-- if options.removeFromViewport == false then
			-- print("Added reticule to viewport")
			-- widget:AddToViewport(0)
		-- end
	end
	
	if widget ~= nil then
		reticule.createFromWidget(widget, options)		
	end
end

function getWeaponMesh()
	local isHidden = false
	local weaponMesh = uevrUtils.getValid(pawn,{"Weapon","WeaponMesh"})
	--print(weaponMesh)
	--print(pawn.WeaponComponent:GetCurrentWeapon().WeaponMesh)
	if weaponMesh == nil then
		local weaponComponent = uevrUtils.getValid(pawn,{"WeaponComponent"})
		if weaponComponent ~= nil and weaponComponent.GetCurrentWeapon ~= nil then
			local currentWeapon = pawn.WeaponComponent:GetCurrentWeapon()
			if currentWeapon ~= nil then
				isHidden = currentWeapon.bHidden
				weaponMesh = currentWeapon.WeaponMesh
			end
		end
	else
		isHidden = pawn.Weapon.bHidden
	end
	return weaponMesh, isHidden
end

function createHands()
	if currentPlayerMode == PlayerMode.Murphy then
		uevrUtils.print("Murphy hands")
		hands.create(pawn.Mesh, handParamsHuman, handAnimationsMurphy)
		local handStr = handedness == Handed.Right and "right" or "left"
		animation.pose(handStr.."_hand", "grip_"..handStr.."_weapon", true)
	elseif currentPlayerMode == PlayerMode.Scientist or currentPlayerMode == PlayerMode.Merc then
		uevrUtils.print("Human hands")
		hands.create(pawn.Mesh, handParamsHuman, handAnimationsScientist)
		local handStr = handedness == Handed.Right and "right" or "left"
	elseif currentPlayerMode == PlayerMode.Ed then
		uevrUtils.print("Ed hands")
		hands.create(pawn.Mesh, handParams)
	else
		uevrUtils.print("Robocop hands " .. pawn.Mesh:get_full_name())
		hands.create(pawn.Mesh, handParams, handAnimations)
		local handStr = handedness == Handed.Right and "right" or "left"
		if weapons.getActiveWeapon() ~= nil then
			animation.pose(handStr.."_hand", "grip_"..handStr.."_weapon", true)
		else
			animation.pose(handStr.."_hand", "open_"..handStr, true)
		end
	end

	animation.setBoneSpaceLocalRotator(hands.getHandComponent(Handed.Right), "hand_r", uevrUtils.rotator(0, 0, -90))
	animation.setBoneSpaceLocalRotator(hands.getHandComponent(Handed.Left), "hand_l", uevrUtils.rotator(0, 0, -90))

	uevrUtils.fixMeshFOV(hands.getHandComponent(Handed.Left), "UsePanini", 0.0, true, true, false)
	uevrUtils.fixMeshFOV(hands.getHandComponent(Handed.Right), "UsePanini", 0.0, true, true, false)

	if isInCinematic then
		hands.hideHands(true)
	end
	
	uevrUtils.fixMeshFOV(pawn.Mesh, "UsePanini", 0.0, true, true, false)
	
	local weaponMesh = getWeaponMesh()
	if weaponMesh ~= nil then uevrUtils.fixMeshFOV(weaponMesh, "UsePanini", 0.0, true, true, false) end

	uevrUtils.print("Hands created. Weapon active: " .. ((weapons.getActiveWeapon() ~= nil) and "true" or "false"))
end

function updateGameReticule()
	if configui.getValue("ui_follows_head") then
		local dot = uevrUtils.getValid(pawn,{"FPPHudWidget","WB HUD","ImageDot"})
		if dot ~= nil then
			dot:SetVisibility(1)
		end
		
		if currentPlayerMode == PlayerMode.Murphy then
			local widget = uevrUtils.getValid(pawn,{"FPPHudWidget","CanvasPanel_HUD"})
			if widget ~= nil then 
				widget:SetVisibility(1)
			end
		elseif currentPlayerMode == PlayerMode.Ed then
			local widget = uevrUtils.getValid(pawn,{"FPPHudWidget","WB_ED209","WB_ED209Crosshair"})
			if widget ~= nil then 
				widget:RemoveFromViewport()
			end
		else
			local widget = uevrUtils.getValid(pawn,{"FPPHudWidget","CurrentReticle"})
			if widget ~= nil then 
				widget:RemoveFromViewport()
				
				--get rid of the "wings" of the reticle
				if widget.Image_DownLaser ~= nil then
					widget.Image_DownLaser.Brush.DrawAs = 0
					widget.Image_UpLaser.Brush.DrawAs = 0
					widget.Image_LeftLaser.Brush.DrawAs = 0
					widget.Image_RightLaser.Brush.DrawAs = 0

					-- if shady_active == true then
						-- widget.Image_CenterDotLaser.Brush.DrawAs = 0
						-- widget.Image_CenterSquareLaser.Brush.DrawAs = 0
					-- end
				end	

			end
		end
	else
		local widget = uevrUtils.getValid(pawn,{"FPPHudWidget","CurrentReticle"})
		if widget ~= nil then 			
			--get rid of the "wings" of the reticle
			if widget.Image_DownLaser ~= nil then
				widget.Image_DownLaser.Brush.DrawAs = 0
				widget.Image_UpLaser.Brush.DrawAs = 0
				widget.Image_LeftLaser.Brush.DrawAs = 0
				widget.Image_RightLaser.Brush.DrawAs = 0

				-- if shady_active == true then
					-- widget.Image_CenterDotLaser.Brush.DrawAs = 0
					-- widget.Image_CenterSquareLaser.Brush.DrawAs = 0
				-- end
			end	
		end
	end
end

function onMenuChange(isActive)
	if isActive then uevrUtils.print("Start Menu") else uevrUtils.print("End Menu") end
	
	setFixedCamera(isInCinematic or isActive)	
	if isActive == false then
		updateUIMode()
	end
	--print(isInMainMenu, levelChanged,isActive,isInteracting)
	if not isInMainMenu and not levelChanged then
		if not configui.getValue("ui_follows_head") == true then
			if isActive and not isInteracting then
				--print("Locking camera fade")
				uevrUtils.fadeCamera(0.5, true)
			else
				uevrUtils.fadeCamera(0.1, false, false, true)
			end
		else
			uevrUtils.fadeCamera(0.01, false, false, true)
		end
	end
	levelChanged = false
end

function on_lazy_poll()
	-- print(pawn:IsInScopeMode())
	-- if pawn:IsInScopeMode() then
	-- --this hide the scope overlay hud but doesnt allow the scan
		-- pawn.FPPHudWidget:ShowHUD(false,true,true)
	-- end
	
	
	local playerMode = getPlayerMode()
	if currentPlayerMode ~= playerMode then
		uevrUtils.print("Player mode changed, new name is " .. pawn:get_full_name())
		hands.destroyHands()
		if playerMode == PlayerMode.Ed then
			setHeightOffset(0.8)
		else
			setHeightOffset(0.0)
		end
	end
	currentPlayerMode = playerMode
	
	if configui.getValue("show_hands") == true and canCreateHands and not hands.exists() then
		createHands()
	end
	
	
	if configui.getValue("useReticule") == true and not reticule.exists() and not isInCinematic then
		if uevrUtils.getValid(userSettings) ~= nil then
			userSettings:SetCrosshairVisible(true)
			--print("Set game crosshair to visible")
		end
		createReticule()
		-- if uevrUtils.getValid(userSettings) ~= nil then
			-- userSettings:SetCrosshairVisible(false)
			-- print("Set game crosshair to not visible")
		-- end
	end
	
	updateGameReticule()

	cameraModifiers.update()
end

function on_xinput_get_state(retval, user_index, state)
	if (not isInMenu and (isCSI or not isInCinematic))  then
		if hands.exists() then
			hands.handleInput(state, weapons.getActiveWeapon() ~= nil, handedness, true)
		end
		
		scopeAdjustDirection = 0
		--if using game settings with gamepad handedness switched from left to right then use the other stick
		local thumbY = state.Gamepad.sThumbRY
		if uevrUtils.getValid(userSettings) ~= nil and userSettings.bRightHandedControlsEnabled == false then
			thumbY = state.Gamepad.sThumbLY
		end

		if isShowingScope then
			if thumbY >= 10000 or thumbY <= -10000 then
				scopeAdjustDirection = thumbY/32768
			end
			scopeAdjustMode = scope.AdjustMode.ZOOM
			local dpadMethod = uevr.params.vr:get_mod_value("VR_DPadShiftingMethod")
			--print(string.find(dpadMethod,"0"),string.find(dpadMethod,"1"))
			if uevrUtils.isThumbpadTouched(state, string.find(dpadMethod,"1") and Handed.Right or Handed.Left) then
				scopeAdjustMode = scope.AdjustMode.BRIGHTNESS
			end
		end
		
		local physicalPunchMode = configui.getValue("physical_punch")
		if physicalPunchMode == 3 or physicalPunchMode == 4 then
			local isHolstering = gestures.detectGestureWithState(gestures.Gesture.HOLSTER, state, handedness)
			local isReloading = gestures.detectGestureWithState(gestures.Gesture.RELOAD, state, handedness)
			-- local isEating = gestures.detectGestureWithState(gestures.Gesture.EAT, state, 1-handedness, true)
			-- local isGrabbingGlasses = gestures.detectGestureWithState(gestures.Gesture.GLASSESGRAB, state, 1-handedness, true)
			-- local isGrabbingEar = gestures.detectGestureWithState(gestures.Gesture.EARGRAB, state, 1-handedness, true)
			-- local isScratchingEar = gestures.detectGestureWithState(gestures.Gesture.EARSCRATCH, state, 1-handedness, true)
			local isEating, isGrabbingGlasses, gripHead, isGrabbingEar, triggerMouth, isScratchingEyes, triggerHead, isScratchingEar = gestures.getHeadGestures(state, 1-handedness, true)
						
			if physicalPunchMode == 4 then
				if uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_X) then
					uevrUtils.unpressButton(state, XINPUT_GAMEPAD_X)
				end
				if uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_Y) then
					uevrUtils.unpressButton(state, XINPUT_GAMEPAD_Y)
				end
				if not (currentPlayerMode == PlayerMode.Murphy or currentPlayerMode == PlayerMode.Scientist or currentPlayerMode == PlayerMode.Merc) then
					if uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_B) then
						uevrUtils.unpressButton(state, XINPUT_GAMEPAD_B)
					end
				end
				if uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_THUMB) then
					uevrUtils.unpressButton(state, XINPUT_GAMEPAD_RIGHT_THUMB)
				end
				state.Gamepad.bLeftTrigger = 0
				if grabbables.isGrabbing() then
					state.Gamepad.bRightTrigger = 0
				end
				if uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_DPAD_DOWN) then
					uevrUtils.unpressButton(state, XINPUT_GAMEPAD_DPAD_DOWN)
				end
			else

			end

			local gripButton = XINPUT_GAMEPAD_RIGHT_SHOULDER
			if handedness == Handed.Left and uevr.params.vr:get_mod_value("VR_SwapControllerInputs") == false then
				gripButton = XINPUT_GAMEPAD_LEFT_SHOULDER
			end
			if uevrUtils.isButtonPressed(state, gripButton) then
				uevrUtils.unpressButton(state, gripButton)
				if isHolstering then
					uevrUtils.pressButton(state, XINPUT_GAMEPAD_Y)
				else
					uevrUtils.pressButton(state, XINPUT_GAMEPAD_X)
				end
			end
			
			if physicalPunchMode == 3 or physicalPunchMode == 4 then
				uevrUtils.unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
			end
			if physicalPunchMode == 4 then
				uevrUtils.unpressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
			end

			if isReloading then
				uevrUtils.pressButton(state, XINPUT_GAMEPAD_X)
			end
			
			if isEating then
				uevrUtils.pressButton(state, XINPUT_GAMEPAD_B)
			end
			
			if isGrabbingGlasses then
				uevrUtils.pressButton(state, XINPUT_GAMEPAD_RIGHT_THUMB)
			end
			
			if isGrabbingEar then
				state.Gamepad.bLeftTrigger = 255		
			end
			
			if isScratchingEar then
				uevrUtils.pressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
			end
			
			if isScratchingEyes then
				uevrUtils.pressButton(state, XINPUT_GAMEPAD_DPAD_DOWN)
			end
		end
		
		if (physicalPunchMode == 2 or physicalPunchMode == 3 or physicalPunchMode == 4) and hasPunchGesture then
			if grabbables.isGrabbing() then
				state.Gamepad.bRightTrigger = 255
			else
				uevrUtils.pressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
			end
		end
	end
end

function on_game_paused(isPaused)
	setFixedCamera(isPaused)
end

function on_pre_engine_tick(engine, delta)
--investigate uevrUtils.getWorld().AuthorityGameMode.GameState.GammaMaterialInstance	
	
	if uevrUtils.getValid(pawn) ~= nil then
		local is_input = pawn.bInputEnabled
		local is_view = pawn.bIsLocalViewTarget
		local show_mouse = pawn.Controller.bShowMouseCursor
		
		local is_menu = show_mouse or uevrUtils.getWorld().AuthorityGameMode.bIsInGameMenuShown
		if isInMenu ~= is_menu then
			onMenuChange(is_menu)
		end
		isInMenu = is_menu

		if is_view and is_input then
			isInCinematic = false
		else
			isInCinematic = true
		end
		
		isInteracting = false
		isConversing = false
		local isInteractingWith = nil
		if pawn.PawnInteractionComponent ~= nil then
			isInteractingWith = pawn.PawnInteractionComponent.InteractionWith ~= nil
			isInteracting = pawn.PawnInteractionComponent.bIsInteracting
			--isConversing = not pawn.PawnInteractionComponent.bInteractionTextHidden
		end
		
		isDetecting = false
		if pawn.DetectiveModeComponent ~= nil then
			--local one = pawn.DetectiveModeComponent.bIsActive	
			isDetecting = pawn.DetectiveModeComponent:GetIsActive()	--walking scanner is on		
			--local two = pawn.DetectiveModeComponent:IsActive()	
			--print(isDetecting, one, two, pawn.DetectiveModeComponent:GetDMLevel(), pawn.InvestigationPointOverlapClient.bIsActive, pawn.DetectiveModeComponent.DetectiveModeTarget	)
		end
		--isDetecting = isInCinematic and is_input and not isInMenu
		--print(isDetecting, isCSI)

		--print(uevrUtils.isGamePaused(), isInCinematic, isInMenu, isDetecting, is_input, is_view, show_mouse, isInteracting, isInteractingWith, isConversing)
	end

	isOnLadder = false
	isBreaching = false
	if pawn.BreachOverlapActor ~= nil then
		if string.find(pawn.BreachOverlapActor:get_full_name(), "BP_Ladder_C") then
			isOnLadder = pawn.BreachOverlapActor.bIsClimbing
		end
		
		if pawn.bInputEnabled == false and (string.find(pawn.BreachOverlapActor:get_full_name(), "Door")
			or string.find(pawn.BreachOverlapActor:get_full_name(), "Breachable")) then
			isBreaching = true
		end
	end

	if isPunching  or isBreaching then
		pawn.Mesh:call("SetRenderInMainPass", true)
	end
end

function on_post_engine_tick(engine, delta)	
	
	updateViewState()
	
	local isWeaponHidden = false
	--if configui.getValue("show_hands") == true then
		local weaponMesh, isHidden = getWeaponMesh()
		isWeaponHidden = isHidden
		weapons.update(weaponMesh, handedness)
	--end
	
	local m_isShowingScope = scope.isDisplaying()
	if m_isShowingScope ~= isShowingScope then
		onScopeDisplayChanged(m_isShowingScope)
	end
	isShowingScope = m_isShowingScope
	if isShowingScope then
		if scopeAdjustMode == scope.AdjustMode.BRIGHTNESS then
			scope.updateBrightness(scopeAdjustDirection, delta)
		elseif scopeAdjustMode == scope.AdjustMode.ZOOM then
			scope.updateZoom(scopeAdjustDirection, delta)
		end
	end
	

	if currentPlayerMode == PlayerMode.Ed then
		local playerController = uevr.api:get_player_controller(0)
		-- look into playerController.FromEyeWeaponTraceResults specifically playerController.FromEyeWeaponTraceResults.TraceStart/TraceEnd
		--hack
		local loc = controllers.getControllerLocation(2)
		if loc ~= nil then
			loc.Z = loc.Z - 25
			reticule.update(loc, playerController.WeaponTraceEnd, 1000, {configui.getValue("reticuleScale"),configui.getValue("reticuleScale"),configui.getValue("reticuleScale")})
		end
	else
		reticule.update(nil, nil, configui.getValue("reticuleDistance"), {configui.getValue("reticuleScale"),configui.getValue("reticuleScale"),configui.getValue("reticuleScale")})
	end
	
	grabbables.checkGrabbedComponent(handedness, not isWeaponHidden) --if weapon unhid itself then force grabbalbles drop
	
	local physicalPunchMode = configui.getValue("physical_punch")
	if physicalPunchMode == 2 or physicalPunchMode == 3 or physicalPunchMode == 4 then
		hasPunchGesture = gestures.detectGesture(gestures.Gesture.PUNCH, delta )
	end
end

--local optionsMenu = nil
function hookLevelFunctions()
	hook_function("BlueprintGeneratedClass /Game/Blueprints/MapObjects/Interactives/BP_BombUnderBridge.BP_BombUnderBridge_C", "InteractNow", false,
		function(fn, obj, locals, result)
			uevrUtils.print("Bomb defuse started")
			obj.CineCamera.RelativeRotation.Pitch = -20
			--obj.CineCamera.RelativeRotation.Yaw = 40
			obj.CineCamera.RelativeLocation.X = 25
			--isDefusingBomb = true
			if configui.getValue("ui_follows_head") then
				uevr.params.vr.set_mod_value("UI_Distance", 0.53)
				uevr.params.vr.set_mod_value("UI_Size", "0.50")
				uevr.params.vr.set_mod_value("UI_X_Offset", 0.0)
				uevr.params.vr.set_mod_value("UI_Y_Offset", 0.0)
			else
				uevr.params.vr.set_mod_value("UI_Distance", 0.53)
				uevr.params.vr.set_mod_value("UI_Size", "0.50")
				uevr.params.vr.set_mod_value("UI_X_Offset", 0.0)
				uevr.params.vr.set_mod_value("UI_Y_Offset",-0.2)
			end
		end
	, nil, true)
	
	hook_function("BlueprintGeneratedClass /Game/Blueprints/MapObjects/Interactives/BP_BombNPC.BP_BombNPC_C", "InteractNow", false,
		function(fn, obj, locals, result)
			uevrUtils.print("Bomb defuse started")
			obj.CineCamera.RelativeLocation.X = 35
			--isDefusingBomb = true
			uevr.params.vr.set_mod_value("UI_Distance", 0.53)
			uevr.params.vr.set_mod_value("UI_Size", "0.50")
			uevr.params.vr.set_mod_value("UI_X_Offset", 0.0)
			uevr.params.vr.set_mod_value("UI_Y_Offset",0.0)
		end
	, nil, true)
	
	-- hook_function("WidgetBlueprintGeneratedClass /Game/UI/Menu/GameOptions/WB_GameOptions.WB_GameOptions_C", "Construct", false,
		-- function(fn, obj, locals, result)
			-- uevrUtils.print("GameOptions construct called")
			-- optionsMenu = obj
		-- end
	-- , nil, true)
	
	-- hook_function("WidgetBlueprintGeneratedClass /Game/UI/Menu/GameOptions/WB_GameOptions.WB_GameOptions_C", "Destruct", true,
		-- function(fn, obj, locals, result)
			-- uevrUtils.print("GameOptions destruct called")
			-- return false
		-- end
	-- , nil, true)

	hook_function("BlueprintGeneratedClass /Game/Blueprints/MapObjects/Interactives/BP_CSI_InitializerImproved.BP_CSI_InitializerImproved_C", "OnInvestigationStartedDelegateBridge", false,
		function(fn, obj, locals, result)
			uevrUtils.print("CSI started")
			isCSI = true
			updateUIMode()
		end
	, nil, true)
	
	hook_function("BlueprintGeneratedClass /Game/Blueprints/MapObjects/Interactives/BP_CSI_InitializerImproved.BP_CSI_InitializerImproved_C", "OnInvestigationFinishedDelegateBridge", false,
		function(fn, obj, locals, result)
			uevrUtils.print("CSI finished")
			isCSI = false
		end
	, nil, true)


end

hook_function("Class /Script/Game.GrabWeapon", "ActualStartAttack", true, nil,
	function(fn, obj, locals, result)
		--uevrUtils.print("ActualStartAttack called")
		if not (currentPlayerMode == PlayerMode.Murphy or currentPlayerMode == PlayerMode.Scientist or currentPlayerMode == PlayerMode.Merc) then
			hands.hideHands(true)
			isPunching = true
		end
	end
, true)

hook_function("Class /Script/Game.FPPWeaponComponent", "OnMeleeAttackFinished", true, nil,
	function(fn, obj, locals, result)
		--uevrUtils.print("OnMeleeAttackFinished called")
		if not isInCinematic then
			hands.hideHands(false)
		end
		isPunching = false
	end
, true)

-- --not reliable
-- hook_function("Class /Script/Game.GrabWeapon", "OnMeleeStopUsing", true, nil,
	-- function(fn, obj, locals, result)
		-- --uevrUtils.print("OnMeleeStopUsing called")
		-- --hands.hideHands(false)
		-- --isPunching = false
	-- end
-- , true)

-- hook_function("Class /Script/Game.FPPCoverComponent", "OnStartShooting", true, nil,
	-- function(fn, obj, locals, result)
		-- --uevrUtils.print("OnStartShooting called")
	-- end
-- , true)
-- hook_function("Class /Script/Game.FPPCoverComponent", "OnStartAiming", true, nil,
	-- function(fn, obj, locals, result)
		-- --uevrUtils.print("OnStartAiming called")
	-- end
-- , true)
-- hook_function("Class /Script/Game.FPPCoverComponent", "OnStopShooting", true, nil,
	-- function(fn, obj, locals, result)
		-- --uevrUtils.print("OnStopShooting called")
	-- end
-- , true)
-- hook_function("Class /Script/Game.FPPCoverComponent", "OnStopAiming", true, nil,
	-- function(fn, obj, locals, result)
		-- --uevrUtils.print("OnStopAiming called")
	-- end
-- , true)


-- hook_function("Class /Game/Blueprints/Weapons/Engine.PlayerController", "ClientRestart", true, nil,
	-- function(fn, obj, locals, result)
		-- print("ClientRestart called\n")
		-- g_isShowingStartPageIntro = false
	-- end
-- , true)

-- register_key_bind("F1", function()
    -- print("F1 pressed\n")
	-- hands.enableHandAdjustments(knuckleBoneListMurphy)
-- end)

-- register_key_bind("F2", function()
    -- print("F2 pressed\n")
	-- animation.logDescendantBoneTransforms(hands.getHandComponent(Handed.Left), "lowerarm_l", true, true, false)
-- end)

-- register_key_bind("F3", function()
    -- print("F3 pressed\n")
	-- animation.logDescendantBoneTransforms(hands.getHandComponent(Handed.Right), "lowerarm_r", true, true, false)
-- end)


-- register_key_bind("F4", function()
	-- setHeight()
	-- -- set_cvar_int("LensFlareQuality", 0)
	-- -- set_cvar_int("SSFS", 0)
	-- -- set_cvar_int("VolumetricCloud", 0)
	-- -- set_cvar_int("DistanceFieldShadowing", 0)
	-- -- set_cvar_int("GlobalDistanceField", 0)
	-- -- set_cvar_int("Lumen.Reflections.Temporal", 0)
	-- -- set_cvar_int("Lumen.DiffuseIndirect.Allow", 0)
	-- -- set_cvar_int("Lumen.Reflections.Allow", 0)
	-- -- set_cvar_int("OneFrameThreadLag", 1)
	-- -- set_cvar_int("MipMapLodBias", -1)
	-- -- set_cvar_int("StaticMeshLODBias", -1)
	-- -- set_cvar_int("postprocessing.disablematerials", 1)
	-- -- set_cvar_int("FinishCurrentFrame", 0)
	-- -- set_cvar_int("DetailMode", 2)
	-- -- set_cvar_int("VolumetricFog", 0)
	-- -- set_cvar_int("TextureStreaming", 0)
	-- -- set_cvar_int("Streaming.LimitPoolSizeToVRAM", 1)
	-- -- set_cvar_int("LightFunctionQuality", 1)
	-- -- set_cvar_int("ShadowQuality", 2)
	-- -- set_cvar_int("Shadow.CSM.MaxCascades", 1)
	-- -- set_cvar_int("Shadow.MaxResolution", 1024)
	-- -- set_cvar_float("ViewDistanceScale", 0.6)
	-- -- set_cvar_float("Shadow.RadiusThreshold", 0.5)
	-- -- set_cvar_float("Shadow.DistanceScale", 0.7)
	-- -- set_cvar_float("Shadow.CSM.TransitionScale", 0.25)
	    -- print("F4 pressed\n")

-- end)

-- register_key_bind("F1", function()
	-- --pawn.FPPHudWidget:EndScopeMode()
	-- --uevrUtils.fadeCamera(2.0)
	-- uevr.api:get_player_controller(0):Pause()
    -- print("F1 pressed\n")
-- end)
