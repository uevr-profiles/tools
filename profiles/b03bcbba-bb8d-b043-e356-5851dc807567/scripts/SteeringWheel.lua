require(".\\Shared\\Global")
require(".\\Config\\CONFIG")
--require(".\\Base\\Subsystems\\UEHelper")
local api = uevr.api
local vr = uevr.params.vr


 local camera_component_c = api:find_uobject("Class /Script/Engine.CameraComponent")


local ActiveHandState= 0 --0: non, 1:right, 2:left
local isLHandPressed=false
local isRHandPressed=false


--degrees
local CurrentHandRoll_Right = 0
local CurrentHandRoll_Left  = 0
local StartRoll_Left=0
local StartRoll_Right=0

local ThumbLX = nil
local ThumbLY = nil
local ThumbRX = nil
local ThumbRY = nil
local LTrigger= nil
local RTrigger= nil
local rShoulder=nil
local lShoulder=nil
local lThumb   =nil
local rThumb   =nil
local Abutton  =nil
local Bbutton  =nil
local Xbutton  =nil
local Ybutton  =nil









local CurrentSteerVal=0
local LastSteerVal=0
local CheckSteerVal =0
local Roll_Last_Left=0
local Roll_Last_Right=0
local DiffAngleRight=0
local DiffAngleLeft=0
local Tick=0

local function isButtonPressed(state, button)
	return state.Gamepad.wButtons & button ~= 0
end
local function isButtonNotPressed(state, button)
	return state.Gamepad.wButtons & button == 0
end
local function pressButton(state, button)
	state.Gamepad.wButtons = state.Gamepad.wButtons | button
end
local function unpressButton(state, button)
	state.Gamepad.wButtons = state.Gamepad.wButtons & ~(button)
end

local function UpdateHandState()
	
	
	if Tick >=3 then
	DeltaRight= math.abs(CurrentHandRoll_Right - Roll_Last_Right)
	Roll_Last_Right= CurrentHandRoll_Right
	DeltaLeft= math.abs(CurrentHandRoll_Left - Roll_Last_Left	)
	Roll_Last_Left=CurrentHandRoll_Left
	Tick=0
	else
		Tick=Tick+1
	end
	if lShoulder  then
		--ActiveHandState= 2
		--isLHandPressed = true
		if ActiveHandState ~= 2 and DeltaLeft > DeltaRight then
			ActiveHandState = 2
			StartRoll_Left=CurrentHandRoll_Left
		end
	end
		--DeltaLeft= CurrentHandRoll_Left - Roll_Last_Left
		--Roll_Last_Left=CurrentHandRoll_Left
	
	
	if rShoulder  then
		--ActiveHandState= 1
		--isRHandPressed = true
		if ActiveHandState ~= 1 and DeltaRight >= DeltaLeft then
			StartRoll_Right= CurrentHandRoll_Right
			ActiveHandState=1 
		end
	end
			--DeltaRight= CurrentHandRoll_Right - Roll_Last_Right
		--	Roll_Last_Right= CurrentHandRoll_Right
	if not rShoulder and not lShoulder then
		ActiveHandState=0
	end
	if LastHandState==ActiveHandState then
		CheckSteerVal=CurrentSteerVal	
	elseif LastHandState~=ActiveHandState then
		LastSteerVal=CheckSteerVal
	end
	LastHandState=ActiveHandState
	
end

--XINPUT functions

local function UpdateInput(state)

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
	
--Disable controls 
	if isDriving then
		unpressButton(state,XINPUT_GAMEPAD_LEFT_SHOULDER)
		unpressButton(state,XINPUT_GAMEPAD_RIGHT_SHOULDER)
		
	end
--Remap:
	if ThumbRY < -30000 and isDriving == false and isMenu==false then 
		pressButton(state, XINPUT_GAMEPAD_B)
	end
	if ThumbRY > 30000 and isDriving == false and isMenu==false then 
		pressButton(state, XINPUT_GAMEPAD_A)
	end
end

local function Drive(state)
	print(CurrentHandRoll_Right)
	--print(ActiveHandState)
	--print("  ")
	--if isDriving then
		--state.Gamepad.sThumbLX = 0
		--state.Gamepad.sThumbRX = 0
		local StartValue=0
		if ActiveHandState == 1 then
			DiffAngleRight= CurrentHandRoll_Right-StartRoll_Right
			CurrentSteerVal= LastSteerVal + DiffAngleRight
			
		elseif ActiveHandState ==2 then
			DiffAngleLeft= CurrentHandRoll_Left-StartRoll_Left
			CurrentSteerVal= LastSteerVal + DiffAngleLeft
		elseif ActiveHandState==0 then
			CurrentSteerVal = 0
		end
		if CurrentSteerVal>70 then
			CurrentSteerVal=70 
		end
		if CurrentSteerVal<-70 then
			CurrentSteerVal=-70 
		end
		if CurrentSteerVal>1 then
			StartValue=20
		elseif CurrentSteerVal<-1 then
			StartValue=-20
		else
			StartValue=0
		end	
		
		state.Gamepad.sThumbLX = 32767/90*(CurrentSteerVal+StartValue)
	--end	
end
local function Accelerate(state)
	state.Gamepad.sThumbRY=0
	if ThumbRY >0 then
	state.Gamepad.bRightTrigger= ThumbRY/32767*255
	elseif ThumbRY<0 then
	state.Gamepad.bLeftTrigger= -ThumbRY/32767*255
	end
end


uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)

UpdateInput(state)
--Read Gamepad stick input 
if isDriving  then
--INPUT OVerrides:	
	
	Drive(state)
	Accelerate(state)
end


end)

local melee_data = {
    right_hand_pos_raw = UEVR_Vector3f.new(),
    right_hand_q_raw = UEVR_Quaternionf.new(),
    right_hand_pos = Vector3f.new(0, 0, 0),
	left_hand_pos_raw = UEVR_Vector3f.new(),
    left_hand_q_raw = UEVR_Quaternionf.new(),
    left_hand_pos = Vector3f.new(0, 0, 0),
    last_right_hand_raw_pos = Vector3f.new(0, 0, 0),
    last_time_messed_with_attack_request = 0.0,
    first = true,
	
}



local CheckSteerVal

uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)
	
	
	
	pawn=api:get_local_pawn(0)
	
	--print(isDriving)
UpdateHandState()
--print(ActiveHandState)
--print(lShoulder)
--degrees:	
if isDriving then	
	DoorMeshRight=pawn.DoorFrontRight
	DoorMeshLeft=pawn.DoorFrontLeft
	UEVR_UObjectHook.get_or_add_motion_controller_state(DoorMeshRight):set_permanent(true)
	UEVR_UObjectHook.get_or_add_motion_controller_state(DoorMeshRight):set_hand(1)
	UEVR_UObjectHook.get_or_add_motion_controller_state(DoorMeshLeft):set_permanent(true)
	UEVR_UObjectHook.get_or_add_motion_controller_state(DoorMeshLeft):set_hand(0)
	CurrentHandRoll_Right= pawn.DoorFrontRight:K2_GetComponentRotation().z
	CurrentHandRoll_Left= pawn.DoorFrontLeft:K2_GetComponentRotation().z
	uevr.params.vr.set_mod_value("VR_RoomscaleMovement", "false")
else 
	uevr.params.vr.set_mod_value("VR_RoomscaleMovement", "true")
	if DoorMeshRight~=nil then
	pcall(function()
	UEVR_UObjectHook.get_or_add_motion_controller_state(DoorMeshRight):set_permanent(false)
	UEVR_UObjectHook.get_or_add_motion_controller_state(DoorMeshLeft):set_permanent(false)
	end)
	end
end
--print(CurrentSteerVal)
--print(LastSteerVal)
--print("   ")
--print("   ")


	
end)


uevr.params.sdk.callbacks.on_early_calculate_stereo_view_offset(

function(device, view_index, world_to_meters, position, rotation, is_double)
--print(rotation.x)
if	isDriving then    
		
	local pawn_d=api:get_local_pawn(0)
	local RotZ=	pawn_d.RootComponent:K2_GetComponentRotation().z
	
	rotation = RotZ
	--		if LastTickRot~=rotation.x then
	--		RotDiff = rotation.x -LastTickRot
	--		
	--		LastTickRot = rotation.x
	--		end
	--		print("RotDiff    :"..RotDiff)
	--RotSave=1
	--		else
	--	elseif TrState==0 then
	--		RotSave=0
	--		RotDiff=0
	--	end
	--	if RotSave == 1 then
	--		RotDiff=rotation.x - RotationXStart
	--	end
		
		--local FinalAngle=tostring(PositiveIntegerMask(DefaultOffset)/1000000+RotDiff)
		--uevr.params.vr.set_mod_value("VR_ControllerPitchOffset", FinalAngle)
	
	--	if isDriving==false then
	--		pcall(function()
	--		local pawn_pos = Cpawn.RootComponent:K2_GetComponentLocation()
	--		
	--		position.x = pawn_pos.x 
	--		position.y = pawn_pos.y
	--		position.Z = pawn_pos.z + 70-- +5
	--		end)
	--	else
			
			
			
		
	--print(isDriving)
end
end)
