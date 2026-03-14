require(".\\Subsystems\\MeleePower")
local controllers = require('libs/controllers')
require(".\\Config\\CONFIG")


 api = uevr.api
 params = uevr.params
 callbacks = params.sdk.callbacks
 vr=uevr.params.vr



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

function find_first_of(className, includeDefault)
	if includeDefault == nil then includeDefault = false end
	local class =  find_required_object(className)
	if class ~= nil then
		return UEVR_UObjectHook.get_first_object_by_class(class, includeDefault)
	end
	return nil
end

function find_required_object_no_cache(class, full_name)


    local matches = class:get_objects_matching(false)


    for i, obj in ipairs(matches) do


        if obj ~= nil and obj:get_full_name() == full_name then


            return obj


        end


    end


    return nil


end

function SearchSubObjectArrayForObject(ObjArray, string_partial)
local FoundItem= nil
	for i, InvItems in ipairs(ObjArray) do
				if string.find(InvItems:get_fname():to_string(), string_partial) then
				--	print("found")
					FoundItem=InvItems
					--return FoundItem
				break
				end
	end
return	FoundItem
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
--
--Statics
 game_engine_class = find_required_object("Class /Script/Engine.GameEngine")
 kismet_string_library = find_static_class("Class /Script/Engine.KismetStringLibrary")
 kismet_math_library = find_static_class("Class /Script/Engine.KismetMathLibrary")
 kismet_system_library = find_static_class("Class /Script/Engine.KismetSystemLibrary")
 Statics = find_static_class("Class /Script/Engine.GameplayStatics")
-- other glob classes 
 VHitBoxClass= find_required_object("Class /Script/Engine.BoxComponent")
local hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
local Key_C= find_required_object("ScriptStruct /Script/InputCore.Key")


--GLOBAL VARIABLES
current_scope_state=false
local hitresult = StructObject.new(hitresult_c)
BoxCompLH=nil
	Key = StructObject.new(Key_C)

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
 AbsThumbFactor = 0
 hmd_component = nil
 right_hand_component= nil
 left_hand_component=nil 
 CurrentEquipmentArray = {}
 canReload=false
 isReloading=false
 ReloadInProgress=false
 LeftController=uevr.params.vr.get_left_joystick_source()
 StickFactor = 0
 gDelta = 0
 isMenu=false
 isSprinting=false
 AltLoHmdDelRot = 0
 AltLoHmdLastRot = 0
 
local function changeSpeed(pawn)
	if pawn~=nil and hmd_component~=nil then
		AbsThumbFactor= math.sqrt(ThumbLX^2+ThumbLY^2)
		local LeftRightScaleFactor= ThumbLX/32767		
		local ForwardBackwardScaleFactor = ThumbLY/32767
		local PosNegValue = 1
	 
		if pawn.MovementSpeeds ~=nil then
			 --AbsThumbFactor= math.sqrt(ThumbLX^2+ThumbLY^2)
			
			if ThumbLY <0 then
				PosNegValue=-1
			end	
				
			pawn.MovementSpeeds.Run =  AbsThumbFactor/32767*328
		end
		if ThumbLY>0 then
			pawn:AddMovementInput(hmd_component:GetForwardVector(),ForwardBackwardScaleFactor,true)
			--pawn:InpAxisEvt_MoveForward_K2Node_InputAxisEvent_2(math.abs(ThumbLY))
		elseif ThumbLY<0 then
			--pawn:AddMovementInput(hmd_component:GetForwardVector(),ForwardBackwardScaleFactor,true)
			pawn:InpAxisEvt_MoveBackwards_K2Node_InputAxisEvent_3(ThumbLY)
		end
		--pawn:AddMovementInput(hmd_component:GetForwardVector()*PosNegValue,ForwardBackwardScaleFactor*PosNegValue,true)
		pawn:AddMovementInput(hmd_component:GetRightVector(),LeftRightScaleFactor,true)	
		
		
		
		
	end
end
local PosDiffAvrg = 0
local AvrgArray={}
local function GetPosDiffAvrg()
	local dTime= gDelta
	local PosSum =  (PosDiffWeaponHand+PosDiffSecondaryHand+PosDiffHMD)
	--print(PosSum)
	if PosSum>11 then PosSum = PosSum/2 end
	
	if math.abs(AltLoHmdDelRot*gDelta) > 0.016 then --heavy rotation filter
		PosSum=PosSum/3
	end
	local dValue =PosSum/(MotionMovementStrength)*dTime 
	--dValue = 1*dTime
	local ArrayVal = {}
	ArrayVal.Time = dTime
	ArrayVal.Value= dValue
	table.insert (AvrgArray, ArrayVal)
		
	
	local ArrayTimeSum = 0.01
	for i, comp in ipairs(AvrgArray) do
		ArrayTimeSum = ArrayTimeSum + comp.Time
	end
	local ArrayValSum = 0.01
	for i, comp in ipairs(AvrgArray) do
		ArrayValSum = ArrayValSum + comp.Value
	end
	
	local Average = ArrayValSum/2
	
	if ArrayTimeSum > 2 then
		table.remove(AvrgArray,1)
		table.remove(AvrgArray,1)
		table.remove(AvrgArray,1)
	end
	return Average
end
	

local function StckFactor()
	
	
	
	--if dpawn~=nil then
		if not isCinematic and not isMenu then
			--print((PosDiffWeaponHand+PosDiffSecondaryHand+PosDiffHMD)/(MotionMovementStrength))
			print(GetPosDiffAvrg())
			--if (PosDiffWeaponHand+PosDiffSecondaryHand+PosDiffHMD)/(MotionMovementStrength) > StickFactor then
			--	if StickFactor< 0.3 then 
			--		StickFactor = StickFactor+ gDelta*0.11 --probably higher
			--	elseif StickFactor< 0.8 then
			--		StickFactor = StickFactor+ gDelta*0.1  -- probably higher as well
			--	else
			--		StickFactor = StickFactor+ gDelta*0.5 
			--	end											-- (PosDiffWeaponHand+PosDiffSecondaryHand+PosDiffHMD)/MotionMovementStrength*2/MotionMovementStrength
			--elseif StickFactor>0.5 then StickFactor=StickFactor - gDelta*0.9
			--elseif StickFactor<=0.3 then StickFactor=StickFactor - gDelta*0.5
			--end
			StickFactor = GetPosDiffAvrg()/(1)
			
			if StickFactor>=1 then
				StickFactor=1
			end
			if StickFactor<NaloMin then
				StickFactor=NaloMin
			end
			if (PosDiffWeaponHand+PosDiffSecondaryHand+PosDiffHMD)/(MotionMovementStrength*2) > NaloSprintTreshhold and StickFactor==1 then
				isSprinting= true
			else isSprinting=false
			end
			print(StickFactor)
			
			
		end
		return StickFactor
	--end
end

local function NaloWalk(state)
	--if not isMenu  then
		local newThumbLX=0
		local newThumbLY=0
		local AbsThumbFactor= math.sqrt(ThumbLX^2+ThumbLY^2)
		if AbsThumbFactor >=14000 then
			newThumbLX=ThumbLX/AbsThumbFactor
			newThumbLY=ThumbLY/AbsThumbFactor
		end
		--if ThumbLX>1 then ThumbLX= 1 end
		--if ThumbLY>1 then ThumbLY= 1 end
		--if ThumbLX<-1 then ThumbLX= -1 end
		--if ThumbLY>-1 then ThumbLY= -1 end
		local newThumbLXFinal=newThumbLX* StckFactor()*32767
		if newThumbLXFinal> 32767 then newThumbLXFinal=32767
		elseif newThumbLXFinal< -32767 then newThumbLX=-32767
		end
		local newThumbLYFinal=newThumbLY* StckFactor()*32767
		if newThumbLYFinal> 32767 then newThumbLYFinal=32767
		elseif newThumbLYFinal< -32767 then newThumbLY=-32767
		end
		if math.abs(ThumbLX)>14000 or math.abs(ThumbLY)>14000 then
			state.Gamepad.sThumbLX= newThumbLXFinal--* GetCatWalkStckFactor(dDelta)*32767
			state.Gamepad.sThumbLY= newThumbLYFinal--* GetCatWalkStckFactor(dDelta)*32767
		else
			state.Gamepad.sThumbLX=0
			state.Gamepad.sThumbLY=0
		end
--UnpressButton
--	end	
end


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

	
--UnpressButton

	--	unpressButton(state,XINPUT_GAMEPAD_LEFT_SHOULDER)
	--	unpressButton(state,XINPUT_GAMEPAD_LEFT_THUMB)
	if isSprinting then
		pressButton(state, XINPUT_GAMEPAD_LEFT_THUMB)
	end
	--if lThumb then
	--	pressButton(state,XINPUT_GAMEPAD_LEFT_SHOULDER)
	--end
	--if lShoulder then
	--	pressButton(state,XINPUT_GAMEPAD_LEFT_THUMB)
	--end

end



uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)
local dpawn=nil
dpawn=api:get_local_pawn(0)


	--UpdateDriveStatus(dpawn)
	

	

	UpdateInput(state)
	--changeSpeed(dpawn)
	if MotionMovement then
		NaloWalk(state)
	end

end)

local last_level=nil

uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)
local dpawn=nil
dpawn=api:get_local_pawn(0)	
local Player=api:get_player_controller(0)	

local engine = game_engine_class:get_first_object_matching(false)
		if not engine then
			return
		end
	
		local viewport = engine.GameViewport
	
		if viewport then
			local world = viewport.World
	
			if world then
				local level = world.PersistentLevel
	
				if last_level ~= level then
					--hmd_component=nil
					--right_hand_component=nil
					--left_hand_component=nil	
					--BoxCompLH=nil
					--controllers.onLevelChange()
					
				
					
				end
	
				last_level = level
			end
		end
		if dpawn~=nil then
			--gDelta = delta
			--CreateLHandBoxCollision(dpawn)
			--local CurrWpnBP = dpawn:BP_GetWeaponObject()
			--UpdateWeaponCollisionZones(dpawn,CurrWpnBP)
			--CollisionFunctions(dpawn, CurrWpnBP)
		end
end)

uevr.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
local CurrentRot = rotation.y

if CurrentRot - AltLoHmdLastRot ~= 0.00 then
	AltLoHmdDelRot = CurrentRot - AltLoHmdLastRot
end

AltLoHmdLastRot = CurrentRot



end)