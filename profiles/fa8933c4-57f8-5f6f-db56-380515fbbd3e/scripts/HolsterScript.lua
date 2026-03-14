--CONFIG--
--------	
require(".\\Subsystems\\Trackers")

	local isRhand = true
	local HapticFeedback = true
	local PhysicalLeaning = false
--------
--------	
	local api = uevr.api
	
	local params = uevr.params
	local callbacks = params.sdk.callbacks
	local pawn = api:get_local_pawn(0)
	--local vr=uevr.params.vr
local function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        error("Cannot find " .. name)
        return nil
    end

    return obj
end
local find_static_class = function(name)
    local c = find_required_object(name)
    return c:get_class_default_object()
end
local kismet_string_library = find_static_class("Class /Script/Engine.KismetStringLibrary")
local kismet_math_library = find_static_class("Class /Script/Engine.KismetMathLibrary")
local kismet_system_library = find_static_class("Class /Script/Engine.KismetSystemLibrary")
local Statics = find_static_class("Class /Script/Engine.GameplayStatics")
function isButtonPressed(state, button)
	return state.Gamepad.wButtons & button ~= 0
end
function isButtonNotPressed(state, button)
	return state.Gamepad.wButtons & button == 0
end
function pressButton(state, button)
	state.Gamepad.wButtons = state.Gamepad.wButtons | button
end
function unpressButton(state, button)
	state.Gamepad.wButtons = state.Gamepad.wButtons & ~(button)
end

local lControllerIndex= 1
local rControllerIndex= 2


--VR to key functions
local function SendKeyPress(key_value, key_up)
    local key_up_string = "down"
    if key_up == true then 
        key_up_string = "up"
    end
    
    api:dispatch_custom_event(key_value, key_up_string)
end

local function SendKeyDown(key_value)
    SendKeyPress(key_value, false)
end

local function SendKeyUp(key_value)
    SendKeyPress(key_value, true)
end




local rGrabActive =false
local lGrabActive =false
local LZone=0
local ThumbLX   = 0
local ThumbLY   = 0
local ThumbRX   = 0
local ThumbRY   = 0
local LTrigger  = 0
local RTrigger  = 0
local rShoulder = false
local lShoulder = false
local lThumb    = false
local rThumb    = false
local lThumbSwitchState= 0
local lThumbOut= false
local rThumbSwitchState= 0
local rThumbOut= false
local isReloading= false
local ReadyUpTick = 0
local RZone=0
local LWeaponZone=0
local RWeaponZone=0
local inMenu=false
local LTriggerWasPressed = 0
local RTriggerWasPressed = 0
local isFlashlightToggle =false
local isButtonA =false
local isButtonB  =false
local isButtonX =false
local isButtonY  =false
local isCrouch = 0
local StanceButton= false
local isJournal=0
local GrenadeReady=false
local KeyG=false
local KeyM=false
local KeyF=false
local KeyR=false
local vecy=0
uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)


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
	
	
	
	--inMenu = api:get_player_controller().bShowMouseCursor
	
	if  LTrigger<10 then
		LTriggerWasPressed = 0
	end
	if  RTrigger<10 then
		RTriggerWasPressed = 0
	end
	
	
	if isRhand then
		if not rShoulder then
			unpressButton(state, XINPUT_GAMEPAD_DPAD_RIGHT		)
			unpressButton(state, XINPUT_GAMEPAD_DPAD_LEFT		)
			--unpressButton(state, XINPUT_GAMEPAD_DPAD_UP			)
			unpressButton(state, XINPUT_GAMEPAD_DPAD_DOWN	    )
		end
	else 
		if not lShoulder then
			unpressButton(state, XINPUT_GAMEPAD_DPAD_RIGHT		)
			unpressButton(state, XINPUT_GAMEPAD_DPAD_LEFT		)
			--unpressButton(state, XINPUT_GAMEPAD_DPAD_UP			)
			unpressButton(state, XINPUT_GAMEPAD_DPAD_DOWN	    )
		end
	end
	
	if not isRhand then
		state.Gamepad.sThumbRX=ThumbLX
		state.Gamepad.sThumbRY=ThumbLY
		state.Gamepad.sThumbLX=ThumbRX
		state.Gamepad.sThumbLY=ThumbRY
		state.Gamepad.bLeftTrigger=RTrigger
		state.Gamepad.bRightTrigger=LTrigger
		unpressButton(state, XINPUT_GAMEPAD_B)
		unpressButton(state, XINPUT_GAMEPAD_A				)
		unpressButton(state, XINPUT_GAMEPAD_X				)	
		unpressButton(state, XINPUT_GAMEPAD_Y				)
		----unpressButton(state, XINPUT_GAMEPAD_DPAD_RIGHT		)
		----unpressButton(state, XINPUT_GAMEPAD_DPAD_LEFT		)
		----unpressButton(state, XINPUT_GAMEPAD_DPAD_UP			)
		----unpressButton(state, XINPUT_GAMEPAD_DPAD_DOWN	    )
		--unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER	)
		unpressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER	)
		unpressButton(state, XINPUT_GAMEPAD_LEFT_THUMB		)
		unpressButton(state, XINPUT_GAMEPAD_RIGHT_THUMB		)
		if Ybutton then
			pressButton(state,XINPUT_GAMEPAD_X)
		end
		if Bbutton then
		--	unpressButton(state, XINPUT_GAMEPAD_B)	
			pressButton(state,XINPUT_GAMEPAD_A)
		end
		if Xbutton then
			pressButton(state,XINPUT_GAMEPAD_Y)
			--unpressButton(state, XINPUT_GAMEPAD_X)
		end	
		if Abutton then
			pressButton(state,XINPUT_GAMEPAD_B)
			--unpressButton(state, XINPUT_GAMEPAD_A)
		end		
		
		if lShoulder then
			pressButton(state,XINPUT_GAMEPAD_RIGHT_SHOULDER)
	--		unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
		end
		if rShoulder then
			pressButton(state,XINPUT_GAMEPAD_LEFT_SHOULDER)
		--	unpressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
		end
		if lThumb then
			pressButton(state,XINPUT_GAMEPAD_RIGHT_THUMB)
--			unpressButton(state, XINPUT_GAMEPAD_LEFT_THUMB)
		end	
		if rThumb then
			pressButton(state,XINPUT_GAMEPAD_LEFT_THUMB)
	--		unpressButton(state, XINPUT_GAMEPAD_RIGHT_THUMB)
		end
		
	end
		--pressdpad--
	if isDpadUp then
		pressButton(state, XINPUT_GAMEPAD_DPAD_UP)
		isDpadUp=false
	end
	if isDpadRight then
		pressButton(state, XINPUT_GAMEPAD_DPAD_RIGHT)
		isDpadRight=false
	end
	if isDpadLeft then
		pressButton(state, XINPUT_GAMEPAD_DPAD_LEFT)
		isDpadLeft=false
	end
	if isDpadDown then
		pressButton(state, XINPUT_GAMEPAD_DPAD_DOWN)
		isDpadDown=false
	end
	if isButtonX then
		pressButton(state, XINPUT_GAMEPAD_X)
		isButtonX=false
	end
	if isButtonA then
		pressButton(state, XINPUT_GAMEPAD_A)
		isButtonA=false
	end
	if isButtonY then
		pressButton(state, XINPUT_GAMEPAD_Y)
		isButtonY=false
	end
	--if not inMenu then
	--	unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER	)		
	--	unpressButton(state, XINPUT_GAMEPAD_B)
	--	--unpressButton(state, XINPUT_GAMEPAD_A				)
	--	unpressButton(state, XINPUT_GAMEPAD_X				)	
	--	unpressButton(state, XINPUT_GAMEPAD_Y				)
	--end
	
	--Unpress when in Zone

	if isRhand then	
		if  RZone ~=0 then
			--unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
			unpressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
			--unpressButton(state, XINPUT_GAMEPAD_LEFT_THUMB)
			unpressButton(state, XINPUT_GAMEPAD_RIGHT_THUMB)
		end
	else
		if LZone ~= 0 then
			--unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
			unpressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
			--unpressButton(state, XINPUT_GAMEPAD_LEFT_THUMB)
			unpressButton(state, XINPUT_GAMEPAD_RIGHT_THUMB)
		end
	end
	--print(RWeaponZone .. "   " .. RZone)
	--disable Trigger for modeswitch
	if RWeaponZone == 2 then
		state.Gamepad.bLeftTrigger=0
	end
	-- Attachement singlepress fix
	if lThumb and lThumbSwitchState==0 then 
		lThumbOut = true 
		lThumbSwitchState=1
	elseif lThumb and lThumbSwitchState ==1 then
		lThumbOut = false
	elseif not lThumb then
		lThumbOut = false
		lThumbSwitchState=0
	end
	if rThumb and rThumbSwitchState==0 then 
		rThumbOut = true 
		rThumbSwitchState=1
	elseif rThumb and rThumbSwitchState ==1 then
		rThumbOut = false
	elseif not rThumb then
		rThumbOut = false
		rThumbSwitchState=0
	end
	--print(rThumbOut)
	if isReloading then
		pressButton(state, XINPUT_GAMEPAD_X)
	end
	
	
	--Ready UP
	--if lGrabActive and rGrabActive then
	--    ReadyUpTick= ReadyUpTick+1
	--	if ReadyUpTick ==120 then
	--		api:get_player_controller(0):ReadyUp()
	--	end
	--else 
	--	ReadyUpTick=0
	--end
	
	--Grab activation
	if rShoulder then
		rGrabActive= true
	else rGrabActive =false
		isFlashlightToggle=false
	end
	if lShoulder  then
		lGrabActive =true
		--unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
	else lGrabActive=false
		if KeyR==true then
			KeyR=false
			SendKeyUp('R')
		end
	end
	
	if isRhand then
		
		if LZone==9 and LTrigger>=230 then
			pressButton(state, XINPUT_GAMEPAD_Y)
		end
		
	
	
		if LZone == 5 and lGrabActive then
			pressButton(state, XINPUT_GAMEPAD_LEFT_THUMB)
		end
	
	end
	
	pawn=api:get_local_pawn(0)
	
	
	--COntrol edits:
	if GrenadeReady == false and KeyG then
		SendKeyUp('G')
		KeyG=false
	end
	if KeyN and not lShoulder then
		KeyN=false
		SendKeyUp('N')
	end
	if KeyM and not lGrabActive then
		SendKeyUp('M')
		KeyM=false
	end
	if KeyF ==true and Abutton==false then
		SendKeyUp('F')
		KeyF=false
	end
	if KeyR ==true and not lGrabActive  then
		SendKeyUp('R')
		KeyF=false
	end
	if StanceButton == true and math.abs(vecy) < 0.1 then
		StanceButton=false
	end
	if isJournal == 1 then
		if not lShoulder then
		isJournal=0
		end
	end

	if not inMenu then	
		if vecy > 0.8 and StanceButton==false then
			if isCrouch == 0 then
			pawn:Jump()
			StanceButton = true
			elseif isCrouch ==1 then
			pawn:MC_UnCrouch()
			isCrouch=0
			StanceButton = true
			end
		end
		
		if vecy <-0.8 and isCrouch == 0 and StanceButton==false then
			pawn:MC_Crouch()
			isCrouch=1
			StanceButton = true
		end
	end	
	
	if GrenadeReady then
		if rGrabActive==false then
		SendKeyDown('G')
		GrenadeReady=false
		KeyG=true
		end
	end
	if lShoulder then
		SendKeyDown('N')
		KeyN=true
	end
	
	if KeyM then 
		SendKeyDown('M')
	end
	if KeyR then 
		SendKeyDown('R')
	end
	if Abutton then
		KeyF = true
		SendKeyDown('F')
	end
--	print(VecA.x)
	
end)


	local RHandLocation=Vector3f.new (0,0,0) 
	local LHandLocation=Vector3f.new (0,0,0)
	local HmdLocation=Vector3f.new (0,0,0)
	local isHapticZoneR = false
	local isHapticZoneL = false
	local isHapticZoneWR = false
	local isHapticZoneWL = false
	local isHapticZoneRLast= false
	local isHapticZoneWRLast= false
	local isHapticZoneWLLast= false
	local LeftController=uevr.params.vr.get_left_joystick_source()
	local RightController= uevr.params.vr.get_right_joystick_source()
	local RightJoystickIndex= uevr.params.vr.get_right_joystick_source()
	local RAxis=UEVR_Vector2f.new()
	params.vr.get_joystick_axis(RightJoystickIndex,RAxis)
	local leanState=0 --1 =left, 2=right
	print(RightJoystickIndex)
	--print(right_hand_component:K2_GetComponentLocation())
--local LHandLocation = left_hand_actor:K2_GetActorLocation()
--local HMDLocation = hmd_actor:K2_GetActorLocation()

uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)
pcall(function()
	pawn=api:get_local_pawn(0)


	params.vr.get_joystick_axis(RightJoystickIndex,RAxis)
	 vecy=RAxis.y
	print(vecx)



	RHandLocation=right_hand_component:K2_GetComponentLocation()
	LHandLocation=left_hand_component:K2_GetComponentLocation()
	HmdLocation= hmd_component:K2_GetComponentLocation()

	local HmdRotation= hmd_component:K2_GetComponentRotation()
	local RHandRotation = right_hand_component:K2_GetComponentRotation()
	local LHandRotation = left_hand_component:K2_GetComponentRotation()

	--Show Cursor
	if api:get_player_controller().bShowMouseCursor or pawn["RadialMenuOpen?"] then
		--uevr.params.vr.set_mod_value("FrameworkConfig_AlwaysShowCursor", "true")
		inMenu=true
	else --uevr.params.vr.set_mod_value("FrameworkConfig_AlwaysShowCursor", "false")
		inMenu=false
	end

	--LEANING
	if PhysicalLeaning then
	
		if HmdRotation.z > 20 then
			leanState = 2
			--pawn:ToggleLeanRight(true)
		elseif HmdRotation.z <20 and HmdRotation.z>-20 then
			leanState=0
			--pawn:ToggleLeanRight(false) 
			--pawn:ToggleLeanLeft(false)
		elseif HmdRotation.z < -20 then 
			leanState=1
			--pawn:ToggleLeanLeft(true)
		end
		
		if leanState == 0 and leanStateLast ~= leanState then
			if leanStateLast == 1 then
				pawn:ToggleLeanLeft(false)
			elseif leanStateLast ==2 then
				pawn:ToggleLeanRight(false)
			end
			leanStateLast=leanState
			uevr.params.vr.set_mod_value("VR_RoomscaleMovement", "true")
		elseif leanState ==1 and leanStateLast ~= leanState then
			pawn:ToggleLeanLeft(true)
			leanStateLast=leanState
			uevr.params.vr.set_mod_value("VR_RoomscaleMovement", "false")
		elseif leanState == 2 and leanStateLast ~= leanState then
			pawn:ToggleLeanRight(true)
			leanStateLast=leanState
			uevr.params.vr.set_mod_value("VR_RoomscaleMovement", "false")
		end
	
	end	
	
	-- Y IS LEFT RIGHT, X IS BACK FORWARD, Z IS DOWN  UP
	local RotDiff= HmdRotation.y	--(z axis of location)
	local LHandNewX= (LHandLocation.x-HmdLocation.x)*math.cos(-RotDiff/180*math.pi)- (LHandLocation.y-HmdLocation.y)*math.sin(-RotDiff/180*math.pi)
			
	local LHandNewY= (LHandLocation.x-HmdLocation.x)*math.sin(-RotDiff/180*math.pi) + (LHandLocation.y-HmdLocation.y)*math.cos(-RotDiff/180*math.pi)
	
	local RHandNewX= (RHandLocation.x-HmdLocation.x)*math.cos(-RotDiff/180*math.pi)- (RHandLocation.y-HmdLocation.y)*math.sin(-RotDiff/180*math.pi)
		  
	local RHandNewY= (RHandLocation.x-HmdLocation.x)*math.sin(-RotDiff/180*math.pi) + (RHandLocation.y-HmdLocation.y)*math.cos(-RotDiff/180*math.pi)
	
	local RHandNewZ= RHandLocation.z-HmdLocation.z
	local LHandNewZ= LHandLocation.z-HmdLocation.z
	
	--for R Handed 
	--z,yaw Rotation
	local RotWeaponZ= RHandRotation.y
	local LHandWeaponX = (LHandLocation.x-RHandLocation.x)*math.cos(-RotWeaponZ/180*math.pi)- (LHandLocation.y-RHandLocation.y)*math.sin(-RotWeaponZ/180*math.pi)
	local LHandWeaponY = (LHandLocation.x-RHandLocation.x)*math.sin(-RotWeaponZ/180*math.pi) + (LHandLocation.y-RHandLocation.y)*math.cos(-RotWeaponZ/180*math.pi)
	local LHandWeaponZ = (LHandLocation.z-RHandLocation.z)
	--print(RHandRotation.z)
	-- x, Roll Rotation
	local RotWeaponX =RHandRotation.z
	LHandWeaponY = LHandWeaponY*math.cos(RotWeaponX/180*math.pi)- LHandWeaponZ*math.sin (RotWeaponX/180*math.pi)
	LHandWeaponZ = LHandWeaponY*math.sin(RotWeaponX/180*math.pi) + LHandWeaponZ*math.cos(RotWeaponX/180*math.pi)
	-- y, Pitch Rotation
	local RotWeaponY =RHandRotation.x
	LHandWeaponX = LHandWeaponX*math.cos(-RotWeaponY/180*math.pi)- LHandWeaponZ*math.sin(-RotWeaponY/180*math.pi)
	LHandWeaponZ = LHandWeaponX*math.sin(-RotWeaponY/180*math.pi) + LHandWeaponZ*math.cos(-RotWeaponY/180*math.pi)
	
	-- 3d Rotation Complete
	--print(RotWeaponX)
	--print(RotWeaponY)
	--for LEFT
	local RotWeaponLZ= LHandRotation.y
	local RHandWeaponX = (RHandLocation.x-LHandLocation.x)*math.cos(-RotWeaponLZ/180*math.pi)- 	(RHandLocation.y-LHandLocation.y)*math.sin(-RotWeaponLZ/180*math.pi)
	local RHandWeaponY = (RHandLocation.x-LHandLocation.x)*math.sin(-RotWeaponLZ/180*math.pi) + (RHandLocation.y-LHandLocation.y)*math.cos(-RotWeaponLZ/180*math.pi)
	local RHandWeaponZ = (RHandLocation.z-LHandLocation.z)
		
	local RotWeaponLX =LHandRotation.z
	RHandWeaponY = RHandWeaponY*math.cos(RotWeaponLX/180*math.pi)-  RHandWeaponZ*math.sin (RotWeaponLX/180*math.pi)
	RHandWeaponZ = RHandWeaponY*math.sin(RotWeaponLX/180*math.pi) + RHandWeaponZ*math.cos (RotWeaponLX/180*math.pi)
	
	local RotWeaponLY =LHandRotation.x
	RHandWeaponX = RHandWeaponX*math.cos(-RotWeaponLY/180*math.pi)-  RHandWeaponZ*math.sin(-RotWeaponLY/180*math.pi)
	RHandWeaponZ = RHandWeaponX*math.sin(-RotWeaponLY/180*math.pi) + RHandWeaponZ*math.cos(-RotWeaponLY/180*math.pi)
	
	--small force feedback on enter and leave
	if HapticFeedback then	
		if isHapticZoneRLast ~= isHapticZoneR  then
			uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 100.0, RightController)
			isHapticZoneRLast=isHapticZoneR
		end
		if isHapticZoneLLast ~= isHapticZoneL then
			uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 100.0, LeftController)
			isHapticZoneLLast=isHapticZoneL
		end
		if isHapticZoneWRLast ~= isHapticZoneWR  then
			uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 100.0, RightController)
			isHapticZoneWRLast=isHapticZoneWR
		end
		if isHapticZoneWLLast ~= isHapticZoneWL then
			uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 100.0, LeftController)
			isHapticZoneWLLast=isHapticZoneWL
		end
	end
	-----EDIT HERE-------------
	---------------------------
	--define Haptic zones RHand
	if RHandNewZ > -10 and RHandNewY > 10 and RHandNewX < -5 then
		--pawn:EquipPrimaryItem()
		isHapticZoneR =true
		RZone=1-- RShoulder
	elseif RHandNewZ >-10 and RHandNewY < -10 and RHandNewX < -5 then
		isHapticZoneR =true
		RZone=2--Left Shoulder
	elseif RHandNewZ >0 and RHandNewY < 5 and RHandNewY > -5 and RHandNewX < 10 and RHandNewX >0 then
		isHapticZoneR= true
		RZone=3-- Over Head
	elseif RHandNewZ < -60 and RHandNewY > 22 and RHandNewX < 10   then
		isHapticZoneR= true
		RZone=4--RPouch
	elseif RHandNewZ < -60 and RHandNewY < -22 and RHandNewX < 10  then
		isHapticZoneR= true
		RZone=5--LPouch
	elseif RHandNewZ < -25 and RHandNewZ > -40 and RHandNewY <-5 and RHandNewY > -15  and RHandNewX > 0 and RHandNewX < 10  then
		isHapticZoneR= true
		RZone=6--ChestLeft
	elseif RHandNewZ < -25 and RHandNewZ > -40 and RHandNewY < 15 and RHandNewY > 5 and RHandNewX > 0 and RHandNewX < 10  then
		isHapticZoneR= true
		RZone=7--ChestRight
	elseif RHandNewZ < -50  and RHandNewY < 20 and RHandNewY > -20 and RHandNewX < -15  then
		isHapticZoneR= true
		RZone=8--LowerBack Center
	elseif RHandNewZ > -5  and RHandNewZ < 10 and RHandNewY < 0 and RHandNewY > -10 and RHandNewX > 0 and RHandNewX < 10  then
		isHapticZoneR= true
		RZone=9--LeftEar
	elseif RHandNewZ > -5  and RHandNewZ < 10 and RHandNewY < 10 and RHandNewY > 0 and RHandNewX > 0 and RHandNewX < 10  then
		isHapticZoneR= true
		RZone=10--RightEar
	else 
		isHapticZoneR= false
		RZone=0--EMPTY
	end
	--define Haptic zone Lhandx
	if LHandNewZ > -10 and LHandNewY > 10 and LHandNewX < -5 then
		isHapticZoneL =true
		LZone=1-- RShoulder
	elseif LHandNewZ >-10 and LHandNewY < -10 and LHandNewX < -5 then
		isHapticZoneL =true
		LZone=2--Left Shoulder
	elseif LHandNewZ >0 and LHandNewY < 5 and LHandNewY > -5 and LHandNewX < 10 and LHandNewX >0 then
		isHapticZoneL= true
		LZone=3-- Over Head
	elseif LHandNewZ < -60 and LHandNewY > 22 and LHandNewX < 10   then
		isHapticZoneL= true
		LZone=4--RPouch
	elseif LHandNewZ < -60 and LHandNewY < -22 and LHandNewX < 10  then
		isHapticZoneL= true
		LZone=5--LPouch
	elseif LHandNewZ < -25 and LHandNewZ > -40 and LHandNewY <-5 and LHandNewY > -15  and LHandNewX > 0 and LHandNewX < 10  then
		isHapticZoneL= true
		LZone=6--ChestLeft
	elseif LHandNewZ < -25 and LHandNewZ > -40 and LHandNewY < 15 and LHandNewY > 5 and LHandNewX > 0 and LHandNewX < 10  then
		isHapticZoneL= true
		LZone=7--ChestRight
	elseif LHandNewZ < -50  and LHandNewY < 20 and LHandNewY > -20 and LHandNewX < -15  then
		isHapticZoneL= true
		LZone=8--LowerBack Center
	elseif LHandNewZ > -15  and LHandNewZ < 10 and LHandNewY < -5 and LHandNewY > -15 and LHandNewX > 0 and LHandNewX < 10  then
		isHapticZoneL= true
		LZone=9--LeftEar
	elseif LHandNewZ > -15  and LHandNewZ < 10 and LHandNewY < 15 and LHandNewY > 5 and LHandNewX > 0 and LHandNewX < 10  then
		isHapticZoneL= true
		LZone=10--RightEar
	else 
		isHapticZoneL= false
		LZone=0--EMPTY
	end
	
	--define Haptic Zone RWeapon
	if isRhand then	
		if LHandWeaponZ <-5 and LHandWeaponZ > -30 and LHandWeaponX < 20 and LHandWeaponX > -15 and LHandWeaponY < 12 and LHandWeaponY > -12 then
			isHapticZoneWL = true
			RWeaponZone = 1 --below gun, e.g. mag reload
		elseif LHandWeaponZ < 10 and LHandWeaponZ > 0 and LHandWeaponX < 10 and LHandWeaponX > -5 and LHandWeaponY < 12 and LHandWeaponY > -12 then
			isHapticZoneWL = true
			RWeaponZone = 2 --close above RHand, e.g. WeaponModeSwitch
		elseif LHandWeaponZ < 25 and LHandWeaponZ > 0 and LHandWeaponX < 45 and LHandWeaponX > 15 and LHandWeaponY < 15 and LHandWeaponY > -15 then
			isHapticZoneWL = true
			RWeaponZone = 3 --Front at barrel l, e.g. Attachement
		else
			RWeaponZone= 0
			isHapticZoneWL=false
		end
	else
		if RHandWeaponZ <-5 and RHandWeaponZ > -30 and RHandWeaponX < 20 and RHandWeaponX > -5 and RHandWeaponY < 12 and RHandWeaponY > -12 then
			isHapticZoneWR = true
	    	LWeaponZone = 1 --below gun, e.g. mag reload
	    elseif RHandWeaponZ < 10 and RHandWeaponZ > 0 and RHandWeaponX < 10 and RHandWeaponX > -5 and RHandWeaponY < 12 and RHandWeaponY > -12 then
	    	isHapticZoneWR = true
	    	LWeaponZone = 2 --close above RHand, e.g. WeaponModeSwitch
	    elseif RHandWeaponZ < 25 and RHandWeaponZ > 0 and RHandWeaponX < 45 and RHandWeaponX > 15 and RHandWeaponY < 12 and RHandWeaponY > -12 then
	    	isHapticZoneWR = true
	    	LWeaponZone = 3 --Front at barrel l, e.g. Attachement
		else
			LWeaponZone=0
			isHapticZoneWR= false
	    end
	end
	
	
	--Code to equip
	if isRhand then
		if RZone== 1 and rGrabActive then
			--local Primary= pawn.Inventory:GetPrimaryWeapon()
			pawn:EquipPrimary()
		elseif RZone== 2 and rGrabActive then
			pawn:EquipSecondary()
		elseif RZone== 4 and rGrabActive then
			pawn:EquipSidearm()
		elseif RZone== 3 and rGrabActive then
		--	pawn:ToggleNightvisionGoggles()
		elseif LZone== 3 and lGrabActive then
		--	pawn:ToggleNightvisionGoggles()
		elseif RZone== 8 and rGrabActive then
			pawn:Event_Journal()
		elseif RZone== 6 and rGrabActive then
			--pawn.Inventory:SwitchToAltGrenade()
		elseif RZone== 7 and rGrabActive  then
				GrenadeReady=true
		elseif LZone==2 and lGrabActive then
			KeyM=true
		elseif LZone==5 and lGrabActive then
			pawn:EquipMelee()
		elseif LZone==8 and lGrabActive and isJournal==0 then
		 pawn:Event_Journal()
		 isJournal=1
		end
	else 
		if LZone == 2 and lGrabActive then
		--	pawn:EquipPrimaryItem()
		elseif LZone== 1 and lGrabActive then
		--	pawn:EquipLongTactical()
		elseif LZone== 5 and lGrabActive then
		--	pawn:EquipSecondaryItem()
		elseif LZone== 3 and lGrabActive then
		--	pawn:ToggleNightvisionGoggles()
		elseif RZone== 3 and rGrabActive then
		--	pawn:ToggleNightvisionGoggles()
		elseif LZone== 8 and lGrabActive then
		--	pawn:EquipFlashbang()
		elseif LZone== 6 and lGrabActive then
			
		elseif LZone== 7 and lGrabActive then
			GrenadeReady=true
		elseif RZone==1 and rGrabActive then
		--	pawn:EquipLongTactical()
		elseif RZone==4 and rGrabActive then
		--	pawn.InventoryComp:EquipItemFromGroup_Index(1,1)
		elseif RZone==8 and rGrabActive then
		--	pawn.InventoryComp:EquipItemFromGroup_Index(8,0)
		end
		
	end
	--Code to trigger Weapon
	if isRhand then
		if RWeaponZone ==1 and lGrabActive then
			--print(pawn.Equipped_Primary:Jig_CanChamberWeapon())
			KeyR=true
		elseif RWeaponZone == 2 and LTrigger > 230 and LTriggerWasPressed ==0 then
			pawn:ChamberWeapon(false)
			--pawn.Inventory.ActiveWeapon:CycleFireMode()
			--	LTriggerWasPressed=1
				
		elseif RWeaponZone==3 and lThumbOut then
			--pawn:ToggleFlashlight()
		end
	else
		
		if LWeaponZone==1 then
			if rGrabActive then
				isReloading = true
			else isReloading = false
			end
		elseif LWeaponZone== 2 and RTrigger > 230 and RTriggerWasPressed ==0 then
			pawn.Inventory.ActiveWeapon:CycleFireMode()
			RTriggerWasPressed=1
		elseif LWeaponZone ==3 and rThumbOut then
			pawn:ToggleFlashlight()
		end
	end
--print(LWeaponZone)
--DEBUG PRINTS--
--TURN ON FOR HELP WITH COORDINATES

----COORDINATES FOR HOLSTERS
--print("RHandz: " .. RHandLocation.z .. "     Rhandx: ".. RHandLocation.x )
--print("RHandx: " .. RHandNewX .. "     Lhandx: ".. LHandNewX .."      HMDx: " .. HmdLocation.x)
--print("RHandy: " .. RHandNewY .. "     Lhandy: ".. LHandNewY .."      HMDy: " .. HmdLocation.y)
--print(HmdRotation.y)
--print("                   ")
--print("                   ")
--print("                   ")

----COORDINATES FOR WEAPON ZONES:
--print("RHandz: " .. RHandWeaponZ .. "     Lhandz: ".. LHandWeaponZ )
--print("RHandx: " .. RHandWeaponX .. "     Lhandx: ".. LHandWeaponX )
--print("RHandy: " .. RHandWeaponY .. "     Lhandy: ".. LHandWeaponY )
--print("                   ")
--print("                   ")
--print("                   ")
end)

end)