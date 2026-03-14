local api = uevr.api
	
	local params = uevr.params
	local callbacks = params.sdk.callbacks
	local pawn = api:get_local_pawn(0)
	local vr=uevr.params.vr



function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        error("Cannot find " .. name)
        return nil
    end

    return obj
end
function find_static_class(name)
    local c = find_required_object(name)
    return c:get_class_default_object()
end



--INPUT functions:-------------
-------------------------------

--VR to key functions
function SendKeyPress(key_value, key_up)
    local key_up_string = "down"
    if key_up == true then 
        key_up_string = "up"
    end
    
    api:dispatch_custom_event(key_value, key_up_string)
end

function SendKeyDown(key_value)
    SendKeyPress(key_value, false)
end

function SendKeyUp(key_value)
    SendKeyPress(key_value, true)
end

function PositiveIntegerMask(text)
	return text:gsub("[^%-%d]", "")
end
--
--Xinput helpers
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
--

--GLOBAL VARIABLES
current_scope_state=false


--Dynamic helper functions:
 ThumbLX   = 0
 ThumbLY   = 0
 ThumbRX   = 0
 ThumbRY   = 0
 LTrigger  = 0
 RTrigger  = 0
 rShoulder = false
 lShoulder = false
 lThumb    = false
 rThumb    = false
 Abutton = false
 Bbutton = false
 Xbutton = false
 Ybutton = false
 SelectButton=false




function UpdateInput(state)

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
end



local function UpdateMenuStatus(Player)
	if Player.bShowMouseCursor then
		isMenu=true
	else isMenu=false
	end
end

local ProneDel=0
local isJumpPressed=false
local isJumping=false
local isProning=false
local isCrouching=false
local ProneTriggered=false
local CrouchTriggered=false
local ProneWasReset=false
local Key_C= find_required_object("ScriptStruct /Script/InputCore.Key")
	Key = StructObject.new(Key_C)

local function ChangeControls(state)  --edit here
	local player= api:get_player_controller(0)
	if  ThumbRY>20000 then
		isJumpPressed=true
	else isJumpPressed=false
		if isJumping then
			isJumping=false
		end
	end
	if isJumpPressed and not isJumping  then
		player:InpActEvt_Climb_K2Node_InputActionEvent_112(Key )
		player:InpActEvt_Climb_K2Node_InputActionEvent_113(Key )
		isJumping=true
		isProning=false
	end
	
	
	
	
	
	if  ThumbRY<-20000 then
		isCrouchPressed=true
	else isCrouchPressed=false
		ProneWasReset=true
		CrouchTriggered=false
		ProneTriggered=false
	end
	if CrouchTriggered and  isCrouching  then
		player:InpActEvt_Position_K2Node_InputActionEvent_132(Key )
		player:InpActEvt_Position_K2Node_InputActionEvent_133(Key )
		isCrouching=false
		ProneDel=0
	end
	if ProneTriggered  and isProning then
		player:InpActEvt_Crawling_K2Node_InputActionEvent_8(Key )
		player:InpActEvt_Crawling_K2Node_InputActionEvent_9(Key )
		isProning=false
		ProneDel=0
	end
	
	
	--pressButton(state, XINPUT_GAMEPAD_A)
	--end
end


		
		

uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)
local dpawn=nil
dpawn=api:get_local_pawn(0)
--Read Gamepad stick input 
UpdateInput(state)

if dpawn~=nil then
	ChangeControls(state)
end



end)



uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)

if pawn~=nil then
	if isCrouchPressed then
		ProneDel=ProneDel+delta
	end	
	if ProneDel>0 and not isCrouchPressed then
		if ProneDel < 0.5 then
			CrouchTriggered=true
			
			isCrouching=true
		end
	elseif ProneDel>=0.5 and isCrouchPressed and ProneWasReset then	
		ProneTriggered=true
		ProneWasReset=false
		isProning=true	
		
	end
end


	
local Player=api:get_player_controller(0)	
UpdateMenuStatus(Player)
	--Player:InpActEvt_Position_K2Node_InputActionEvent_132(Key )
	--Player:InpActEvt_Climb_K2Node_InputActionEvent_113(Key )
end)