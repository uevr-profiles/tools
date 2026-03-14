require(".\\Subsystems\\MeleePower")
local controllers = require('libs/controllers')
require(".\\Config\\CONFIG")
require(".\\Subsystems\\GlobalData")
require(".\\Subsystems\\GlobalCustomData")
require(".\\Subsystems\\HelperFunctions")
--require(".\\Subsystems\\test")
 
local function CinematicStatus(pawn)
	if pawn ==nil then return end
	if not UEVR_UObjectHook.exists(CameraManager) then
--	if CameraManager.ViewTarget==nil then
		CameraManager= UEVR_UObjectHook.get_first_object_by_class(CameraManager_C)
	end
 	if CameraManager.ViewTarget.Target ~= pawn then
		isCinematic=true
		--UEVR_UObjectHook.set_disabled(true)
	else isCinematic=false
		if not isMenu then
		--	UEVR_UObjectHook.set_disabled(false)
		end
	end
	--print(isCinematic)
end 




local function MenuStatus(Player)
	if Player.bShowMouseCursor then
		isMenu=true
		--	UEVR_UObjectHook.set_disabled(true)
			uevr.params.vr.set_mod_value("UI_FollowView","false")
			uevr.params.vr.set_mod_value("VR_DecoupledPitch","false")
			uevr.params.vr.set_mod_value("VR_AimMethod","0")
			--Player.bShowMouseCursor=true
			
			--uevr.params.vr.set_mod_value("FrameworkConfig_AlwaysShowCursor","true")
			uevr.params.vr.set_mod_value("VR_DecoupledPitch","true")
			if not wasRecentered then
				vr.recenter_view()
				wasRecentered=true
			end
	else
		isMenu=false
		wasRecentered=false
		uevr.params.vr.set_mod_value("VR_AimMethod","1")
		--uevr.params.vr.set_mod_value("FrameworkConfig_AlwaysShowCursor","false")
		uevr.params.vr.set_mod_value("UI_FollowView","true")
		uevr.params.vr.set_mod_value("VR_DecoupledPitch","true")
		
			
	end
end
 
local function SprintRoll(state,cpawn)
	if isThumbMotion and math.abs(StickR.y) < 0.2 then
		isThumbMotion=false
		SendKeyUp("0x20")
			SendKeyUp("C")
	end
		
	
	--print(StickR.x)
	--print(StickR.y)
	if not isMenu and not TactiNavVisible then 
		if StickR.y>0.8 and not isThumbMotion then
			SendKeyDown("0x20")
			
			isThumbMotion=true
		elseif StickR.y<-0.8 and not isThumbMotion then
			isThumbMotion=true
			SendKeyDown("C")
			
		--	pressButton(state, XINPUT_GAMEPAD_B)
		--	pawn:InpActEvt_Crouch_K2Node_InputActionEvent_13(Key)
		
		end
		
		
		
		
	end
	if cpawn~=nil  then
		
		
		if Abutton and cpawn.CharacterMovement~=nil and not isSprinting and canPressA then
			canPressA=false
			isSprinting=true
			cpawn.CharacterMovement.MaxWalkSpeed = 580 
			cpawn.CharacterMovement.MaxWalkSpeedCrouched = 240
		elseif ((Abutton and canPressA) or math.abs(ThumbLY)<20000) and isSprinting and cpawn.CharacterMovement~=nil then
			isSprinting=false
			canPressA=false
			cpawn.CharacterMovement.MaxWalkSpeed = 280
			cpawn.CharacterMovement.MaxWalkSpeedCrouched = 140
		end
	end
	if not Abutton then
			canPressA=true
	end
	
	
	
end

local function CollisionFunctionExecute(state,pawn)
	--local MeshArray1 = pawn.Children
	
	--checkMaterial(pawn,MeshArray1,"FOV_Alpha") --from FOV FIXER
	if pressY then
		--unpressButton(state,XINPUT_GAMEPAD_RIGHT_SHOULDER)
		pressButton(state,XINPUT_GAMEPAD_Y)
		if not rShoulder then
			pressY=false
		end
	end
	
	if ReloadInProgress then
		SendKeyDown("R")
	else SendKeyUp("R")
	end
	-- EDIT COLLISION BODY BOXES:
	
	if pressRS then
		--pressButton(state,XINPUT_GAMEPAD_DPAD_UP)
		SendKeyDown("1")
		if not lShoulder and not rShoulder then
			pressRS=false
			--SendKeyDown("1")
			SendKeyUp("1")
			
		end
	end
	if pressLS then
		SendKeyDown("2")
		--print("pressed2")
		--pressLS=false
		--pressButton(state,XINPUT_GAMEPAD_DPAD_DOWN)
		if not lShoulder and not rShoulder then
			pressLS=false
			--SendKeyDown("2")
			SendKeyUp("2")
		end
	end
	--if pressLS and lShoulder then
	--	SendKeyDown("B")
	--	--pressButton(state,XINPUT_GAMEPAD_DPAD_DOWN)
	--	if not lShoulder and not rShoulder then
	--		pressLS=false
	--		--SendKeyDown("2")
	--		SendKeyUp("B")
	--	end
	--end
	if pressRH then
		SendKeyDown("3")
		--pressButton(state,XINPUT_GAMEPAD_DPAD_RIGHT)
		if not lShoulder and not rShoulder then
			pressRH=false
			--SendKeyDown("3")
			SendKeyUp("3")
		end
	end
	if pressRC then
		--pressButton(state,XINPUT_GAMEPAD_DPAD_LEFT)
		SendKeyDown("4")
		if not lShoulder and not rShoulder then
			pressRC=false
			--SendKeyDown("4")
			SendKeyUp("4")
		end
	end
end



function UpdateInput(state,cpawn)

--Read Gamepad stick input 
	ThumbLX = state.Gamepad.sThumbLX
	ThumbLY = state.Gamepad.sThumbLY
	ThumbRX = state.Gamepad.sThumbRX
	ThumbRY = state.Gamepad.sThumbRY
	LTrigger= state.Gamepad.bLeftTrigger
	RTrigger= state.Gamepad.bRightTrigger
	rShoulder= isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
	lShoulder= isButtonPressed(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
	lThumb   = isButtonPressed(state, XINPUT_GAMEPAD_LEFT_THUMB)
	rThumb   = isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_THUMB)
	Abutton  = isButtonPressed(state, XINPUT_GAMEPAD_A)
	Bbutton  = isButtonPressed(state, XINPUT_GAMEPAD_B)
	Xbutton  = isButtonPressed(state, XINPUT_GAMEPAD_X)
	Ybutton  = isButtonPressed(state, XINPUT_GAMEPAD_Y)
	DPAD_Up   =isButtonPressed(state, XINPUT_GAMEPAD_DPAD_UP)
	DPAD_Right=isButtonPressed(state, XINPUT_GAMEPAD_DPAD_RIGHT)
    DPAD_Left =isButtonPressed(state, XINPUT_GAMEPAD_DPAD_LEFT)
	DPAD_Down =isButtonPressed(state, XINPUT_GAMEPAD_DPAD_DOWN)
	vr.get_joystick_axis(vr.get_right_joystick_source(), StickR)
	if not isCinematic and not isMenu then
		--unpressButton(state,XINPUT_GAMEPAD_RIGHT_SHOULDER)
		--unpressButton(state,XINPUT_GAMEPAD_LEFT_SHOULDER)
		--unpressButton(state,XINPUT_GAMEPAD_X)
		--state.Gamepad.bLeftTrigger=0
	end
	
	if DPAD_Up   
	   or DPAD_Right
	   or DPAD_Left 
	   or DPAD_Down
		then
		WpnSwitch=true
		ChangeReq=true
	end
	
	
	if lShoulder and not canChange then
		--state.Gamepad.bLeftTrigger=255
	end
	--if  GetHandDistance() <=10 and lShoulder and rShoulder then
	--	pressButton(state,XINPUT_GAMEPAD_LEFT_SHOULDER)
		--pressButton(state,XINPUT_GAMEPAD_RIGHT_SHOULDER)
	--end
	if Xbutton and PosDiffWeaponHand > 30 then
		--pressButton(state,XINPUT_GAMEPAD_RIGHT_THUMB)
	end
	
	
	SprintRoll(state,cpawn)	
	CollisionFunctionExecute(state,cpawn)
	--print(PosDiffWeaponHand)
--	print(pressLS)
	
end





uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)
	local dpawn=nil
	dpawn=api:get_local_pawn(0)

	UpdateInput(state,dpawn)
		
end)

local last_level=nil

local function OnLevelChange()
		local engine = game_engine_class:get_first_object_matching(false)
		if not engine then
			return
		end
	
		local viewport = engine.GameViewport
	
		if viewport then
			 world = viewport.World
	
			if world then
				local level = world.PersistentLevel
	
				if last_level ~= level then					
					
					right_hand_component=nil
					left_hand_component=nil	
					
					
					ResetDelta=0
					GlockMesh =nil
					BinoMesh=nil
					CurrentWeaponMesh=nil
					HandSceneComp=nil
					Cam=nil
					
					BodyVisibilityChecked=false
					isReloading=false
					WpnMatArray={}
					ReloadInProgress=false
					
					Cursor=nil
					TactiNav=nil
					
					CameraManager= UEVR_UObjectHook.get_first_object_by_class(CameraManager_C)
					--controllers.destroyControllers()
				----	AssignMotionComp(1)
				--	AssignMotionComp(2)
				--	AssignMotionComp(0)
					controllers.onLevelChange()
					--if not controllers.controllerExists(2)then
						hmd_component=controllers.createHMDController()			
					
					--end
					--print(hmd_component)
					if not controllers.controllerExists(0) then
						left_hand_component =	controllers.createController(0)
						left_hand_component=controllers.getController(0)
					else left_hand_component=controllers.getController(0)
					end
					--left_hand_component= controllers.createControllerComponent(createActor(0), "Left", 0)	
					if not controllers.controllerExists(1) then
						right_hand_component =	controllers.createController(1)
						right_hand_component= controllers.getController(1)
					else right_hand_component= controllers.getController(1)
					end
						
					BoxCompHmdChestRight	=nil
					BoxCompHmdRightHip     =nil
					BoxCompHmdLeftHip      =nil
					BoxCompHmdRightShoulder=nil
					BoxCompHmdLeftShoulder=nil
					BoxCompLH=nil
					BoxCompRH=nil
					MagBox=nil




						
				end
	
				last_level = level
			end
		end
end


uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)
	local dpawn=api:get_local_pawn(0)	
	local Player=api:get_player_controller(0)	
	--Player.bShowMouseCursor=true
		OnLevelChange()
		
		if ResetDelta<5 then
			ResetDelta = ResetDelta+delta
		else WasReset=false
		end
		CustomInput(dpawn)
		--CinematicStatus(pawn)
		MenuStatus(Player)
		SetMouseLocation(Player)
		if not BodyVisibilityChecked and not Debug then
			CheckBodyVisibility(dpawn)
		end
		UpdateHandsVisByMontage(dpawn)
		--if HandSceneComp~=nil then
		--	local CounterPitch= dpawn.Controller.ControlRotation.Pitch
		--	HandSceneComp.RelativeRotation.Roll=CounterPitch
		--end
end)
