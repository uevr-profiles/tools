local controllers = require('libs/controllers')
require(".\\Config\\CONFIG")
require(".\\Subsystems\\MeleePower")

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

 GameplayStDef= find_required_object("GameplayStatics /Script/Engine.Default__GameplayStatics")
local game_engine_class = find_required_object("Class /Script/Engine.GameEngine")
local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
KismetSystemLibrary = find_static_class("Class /Script/Engine.KismetSystemLibrary")
KismetStringLibrary = find_static_class("Class /Script/Engine.KismetStringLibrary")
KismetMathLibrary   = find_static_class("Class /Script/Engine.KismetMathLibrary")
local viewport = game_engine.GameViewport
local world = viewport.World





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
 StickFactor = 0
 gDelta = 0
CinematicTimer=0
isMenu=false
isCinematic =false
world=nil
isYTargetInFront=false
 FurM= nil

local function UpdateMenuStatus(pawn,world,player)
	if pawn==nil then return end
	
	if GameplayStDef:IsGamePaused(world) then
		isMenu=true
		if isRecentered == false then
			vr:recenter_view()
			isRecentered=true
		end
		vr.set_mod_value("VR_2DScreenMode", "true") 
		vr.set_mod_value("UI_FollowView", "false")
		vr.set_mod_value("VR_DecoupledPitch", "false")
	else isMenu=false
		isRecentered=false
		vr.set_mod_value("VR_2DScreenMode", "false") 
		vr.set_mod_value("VR_DecoupledPitch", "true") 
		if UIFollow then
			vr.set_mod_value("UI_FollowView", "true")
		end
	end	
end
local function CinematicStatus(dpawn,dDelta)
	if dpawn ==nil then return end
	pcall(function()
	if CameraManager.ViewTarget~=nil then
		if CameraManager.ViewTarget.Target ~= dpawn then
			isCinematic=true
			UEVR_UObjectHook.set_disabled(true)
		else isCinematic=false
			UEVR_UObjectHook.set_disabled(false)
		end
	end
	
	
	
	
	end)
	
	if isCinematic then
	--JustTurnedOn=true
		CinematicTimer=0
	elseif CinematicTimer< 10 then
		CinematicTimer=CinematicTimer+dDelta
	end
	
	
end

local function GetCatWalkStckFactor()

	--if dpawn~=nil then
		if not isCinematic and not isMenu then
			--print(PosDiffWeaponHand)
			if math.max(PosDiffWeaponHand,PosDiffSecondaryHand)/MotionMovementStrength > StickFactor then
				StickFactor= math.max(PosDiffWeaponHand,PosDiffSecondaryHand)/MotionMovementStrength
			elseif StickFactor>0.5 then StickFactor=StickFactor - gDelta*0.5
			elseif StickFactor<=0.5 then StickFactor=StickFactor - gDelta*0.15
			end
			if StickFactor>=1 then
				StickFactor=1
			end
		end
		return StickFactor
	--end
end

local function CatJump(state)
	if PosDiffSecondaryHand/(MotionMovementStrength) >0.5 and PosDiffWeaponHand/(MotionMovementStrength) > 0.5 then
		local PosHandR=	Vector3d.new(0,0,0)--	controllers.getController(1):K2_GetComponentLocation()
		local PosHandL=	Vector3d.new(0,0,0)--	controllers.getController(0):K2_GetComponentLocation()
		local PosHMD  =	Vector3d.new(0,0,0)--	controllers.getController(2):K2_GetComponentLocation()
		if controllers.getController(0)~=nil then
			PosHandR=controllers.getController(1):K2_GetComponentLocation()
			PosHandL=controllers.getController(0):K2_GetComponentLocation()
			PosHMD  =controllers.getController(2):K2_GetComponentLocation()
		end	
		local DiffDistRHMD = math.sqrt( (PosHandR.X-PosHMD.X)^2+(PosHandR.Y-PosHMD.Y)^2+(PosHandR.Z-PosHMD.Z)^2)
		local DiffDistLHMD = math.sqrt( (PosHandL.X-PosHMD.X)^2+(PosHandL.Y-PosHMD.Y)^2+(PosHandL.Z-PosHMD.Z)^2)
		if DiffDistLHMD> DistanceA and DiffDistRHMD >DistanceA then
			pressButton(state, XINPUT_GAMEPAD_A)
		end
	end
end
local wasBRPressed=false
local wasBLPressed=false
local canPressB=true
local BWasPressedNormal=false

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

	if not isCinematic and not isMenu and MotionMovement then
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
		local newThumbLXFinal=newThumbLX* GetCatWalkStckFactor(dDelta)*32767
		if newThumbLXFinal> 32767 then newThumbLXFinal=32767
		elseif newThumbLXFinal< -32767 then newThumbLX=-32767
		end
		local newThumbLYFinal=newThumbLY* GetCatWalkStckFactor(dDelta)*32767
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
		CatJump(state)
	end
	
		
		unpressButton(state,XINPUT_GAMEPAD_B)
		unpressButton(state,XINPUT_GAMEPAD_X)
	
		
	if Xbutton and not BWasPressedNormal then
		pressButton(state,XINPUT_GAMEPAD_B)
		BWasPressedNormal=true
	elseif not Xbutton then
		BWasPressedNormal=false
	end
	if Bbutton then
		pressButton(state,XINPUT_GAMEPAD_X)
	end
	if isYTargetInFront and (PosDiffWeaponHand/(MotionMovementStrength) > 0.6 or PosDiffSecondaryHand/(MotionMovementStrength) >0.6)  then
		pressButton(state,XINPUT_GAMEPAD_Y)
	end
	
	
	if not canPressB then
		unpressButton(state,XINPUT_GAMEPAD_B)
		canPressB=true
	else	
		
		if MotionMovement and wasBRPressed and PosDiffWeaponHand/MotionMovementStrength < 1  then
			wasBRPressed=false 
		--	unpressButton(state,XINPUT_GAMEPAD_B)
		elseif MotionMovement and not wasBRPressed and Xbutton and PosDiffWeaponHand/MotionMovementStrength >  1 and canPressB then
			--unpressButton(state,XINPUT_GAMEPAD_B) then
			--unpressButton(state,XINPUT_GAMEPAD_B)
			
			pressButton(state,XINPUT_GAMEPAD_B)
			wasBRPressed=true
			canPressB=false
		end
		if MotionMovement and wasBLPressed  and PosDiffSecondaryHand/MotionMovementStrength < 1 then
			wasBLPressed=false 
		--	unpressButton(state,XINPUT_GAMEPAD_B)
		elseif MotionMovement and not wasBLPressed and Xbutton and PosDiffSecondaryHand/MotionMovementStrength > 1 and canPressB then
			--unpressButton(state,XINPUT_GAMEPAD_B)
			
			pressButton(state,XINPUT_GAMEPAD_B)
			wasBRPressed=true
			canPressB=false
		end
	end
	--print((PosDiffWeaponHand/(MotionMovementStrength)))
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
	


--Read Gamepad stick input 
--if PhysicalDriving then
	UpdateInput(state)

--end

end)

uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)
local dpawn=nil
 dpawn=api:get_local_pawn(0)	
local Player=api:get_player_controller(0)	
gDelta = delta
viewport = game_engine.GameViewport
	world = viewport.World
	--local cpawn=api:get_local_pawn(0)	
--	local Player=api:get_player_controller(0)	
	
	UpdateMenuStatus(dpawn,world,Player)
	
	CinematicStatus(dpawn,delta)	



--local PMesh=pawn.FirstPersonSkeletalMeshComponent

end)