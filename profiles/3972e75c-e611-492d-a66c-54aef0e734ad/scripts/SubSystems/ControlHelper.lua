require(".\\Subsystems\\Helper")
require(".\\Config\\Keys")
require(".\\Config\\CONFIG")
local api = uevr.api
	
	local params = uevr.params
	local callbacks = params.sdk.callbacks
	local pawn = api:get_local_pawn(0)
	local player= api:get_player_controller(0)
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
--Library
local GameplayStDef= find_required_object("GameplayStatics /Script/Engine.Default__GameplayStatics")
local game_engine_class = find_required_object("Class /Script/Engine.GameEngine")
local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)

local viewport = game_engine.GameViewport
local world = viewport.World

local color = StructObject.new(flinearColor_c)



--GLOBAL VARIABLES
CinematicTimer=0
isMenu=false
isCinematic =false
isSaber1Extended=false
isSaber2Extended=false
isNavMode=true
isTwinSaber=true
isSaberDetached=false
isSaberDetachedL=false
isSwimDive=false
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
 TargetButton = false
 rThumbShort=false
 rThumbLong=false
 BrUpButton =false
 BrDownButton =false
--local variables
local isRecentered=false
local isTutorial=false
local ArrTable = {}
local ArrTable2 ={}   
local ArrTable3 ={} 
local ArrTable4 ={} 
 ArrTable.KeyName =  KismetStringLibrary:Conv_StringToName(TargetKey)
 ArrTable2.KeyName =  KismetStringLibrary:Conv_StringToName(HMCSKey)
ArrTable3.KeyName =  KismetStringLibrary:Conv_StringToName(BrUpKey)
ArrTable4.KeyName =  KismetStringLibrary:Conv_StringToName(BrDownKey)


function UpdateInput(state)

--Read Gamepad stick input 
	--print(state.Gamepad.sThumbRX)
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
	local player= api:get_player_controller(0)
	TargetButton = player:IsInputKeyDown(ArrTable)
	HMCSButton = player:IsInputKeyDown(ArrTable2)
	BrUpButton =player:IsInputKeyDown(ArrTable3)
	BrDownButton =player:IsInputKeyDown(ArrTable4)
	

	--	if not isMenu  then
	--
	--		unpressButton(state,XINPUT_GAMEPAD_RIGHT_THUMB)
	--
	--	else 
	--		state.Gamepad.sThumbRX=ThumbRX
	--	end

end





local function UpdateMenuStatus(pawn,world,player)
	if pawn==nil then return end
	
	if GameplayStDef:IsGamePaused(world) then
		isMenu=true
		if isRecentered == false then
			--vr:recenter_view()
			isRecentered=true
		end
		uevr.params.vr.set_mod_value("VR_2DScreenMode", "true") 
		--uevr.params.vr.set_mod_value("UI_FollowView", "false")
	else isMenu=false
		isRecentered=false
		uevr.params.vr.set_mod_value("VR_2DScreenMode", "false") 
		--uevr.params.vr.set_mod_value("UI_FollowView", "true")
	end	
end
local function CinematicStatus(dpawn,dDelta)
	if dpawn ==nil then return end
	pcall(function()
	if CameraManager.ViewTarget~=nil then
		if CameraManager.ViewTarget.Target ~= dpawn then
			isCinematic=true
		--	UEVR_UObjectHook.set_disabled(true)
		else isCinematic=false
		--	UEVR_UObjectHook.set_disabled(false)
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



uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)
local dpawn=nil
dpawn=api:get_local_pawn(0)
player=api:get_player_controller(0)

	--UpdateDriveStatus(dpawn)



--Read Gamepad stick input 
--if PhysicalDriving then
	UpdateInput(state)
--if not isMenu then
--	state.Gamepad.sThumbRX=0
--end	
--end

end)
local rThumbDelta=0
local rThumbWasPressed=false
local HMCSButtonPressed=false
local BrDownButtonPressed=false
local BrUpButtonPressed = false
local config_filename = "main-config.json"
local function ToggleHMCS()
	local bVisbility= not HMCComponent.bVisible
	HMCComponent:SetVisibility(bVisbility)
	HMCShieldComponent:SetVisibility(bVisbility)
	HMCArmorComponent:SetVisibility(bVisbility)
	HMCHullComponent:SetVisibility(bVisbility)
end
local function UpdateColor()
	
	color.R = config_table["HudBrightness_C"]
	color.G = config_table["HudBrightness_C"]
	color.B = config_table["HudBrightness_C"]
	color.A = 0.8
	
	if config_table["HudBrightness_C"] <= 0 then
	HMCComponent:SetVisibility(false)
	HMCShieldComponent:SetVisibility(false)
	HMCArmorComponent:SetVisibility(false)
	HMCHullComponent:SetVisibility(false)
	else
	HMCComponent:SetVisibility(true)
	HMCShieldComponent:SetVisibility(true)
	HMCArmorComponent:SetVisibility(true)
	HMCHullComponent:SetVisibility(true)
	end
	
	
	HMCShieldComponent:SetTintColorAndOpacity(color)
	HMCArmorComponent:SetTintColorAndOpacity(color)
	HMCHullComponent:SetTintColorAndOpacity(color)
	
	color.R = 0
	color.G = config_table["HudBrightness_C"]
	color.B = 0
	color.A = 0.8
	HMCComponent:SetTintColorAndOpacity(color)
	
	
end	
	

uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)

if (rThumb or TargetButton) and rThumbDelta<1 and not rThumbWasPressed then
	rThumbDelta=rThumbDelta+delta
	
else 
	rThumbWasPressed=true
	if rThumbDelta>0 then
		if rThumbDelta<1  then
			rThumbDelta=0
			rThumbShort=true
		elseif rThumbDelta>=1 then
			rThumbDelta=0
			rThumbLong=true
		end
	end
	if not rThumb and not TargetButton then
		rThumbWasPressed=false
	end
end

if HMCSButton and not HMCSButtonPressed then
	ToggleHMCS()
	HMCSButtonPressed=true
elseif not HMCSButton and HMCSButtonPressed then
	HMCSButtonPressed=false
end

if BrDownButton and not BrDownButtonPressed then
	if config_table["HudBrightness_C"]>=0 then
	 config_table["HudBrightness_C"] = config_table["HudBrightness_C"] - 1
	end
       json.dump_file(config_filename, config_table, 4)
	  UpdateColor()
	--WasLowered=true
	BrDownButtonPressed=true
elseif not BrDownButton and BrDownButtonPressed then
	BrDownButtonPressed=false
end
if BrUpButton and not BrUpButtonPressed then
	--WasRaised=true
	if config_table["HudBrightness_C"]<=30 then
		config_table["HudBrightness_C"] = config_table["HudBrightness_C"] + 1
	end
       json.dump_file(config_filename, config_table, 4)	
	BrUpButtonPressed=true
	UpdateColor()
elseif not BrUpButton and BrUpButtonPressed then
	BrUpButtonPressed=false
end


--local	dpawn=api:get_local_pawn(0)
	viewport = game_engine.GameViewport
	world = viewport.World
	local cpawn=api:get_local_pawn(0)	
	local Player=api:get_player_controller(0)	
	
	UpdateMenuStatus(cpawn,world,Player)
	
	CinematicStatus(cpawn,delta)	

	--isTutLevel(world)
		--isMenu=GameplayStDef:IsGamePaused(world)
	--print(ThumbRX)
		--local PMesh=pawn.FirstPersonSkeletalMeshComponent
--print(isMenu)
end)