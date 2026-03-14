require(".\\Shared\\Global")

local api = uevr.api
local params = uevr.params
local callbacks = params.sdk.callbacks
local vr=uevr.params.vr

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
local game_engine_class = find_required_object("Class /Script/Engine.GameEngine")
local kismet_system_library = find_static_class("Class /Script/Engine.KismetSystemLibrary")
--local zero_color = nil
local color_c = find_required_object("ScriptStruct /Script/CoreUObject.LinearColor")
local SmoothSetting =find_required_object("CameraPOIAnchorBehavior_C /Game/Camera/Behaviors/CameraPOIAnchorBehavior.Default__CameraPOIAnchorBehavior_C")
local zero_color = StructObject.new(color_c)
	
local zero_color2 = StructObject.new(color_c)
	zero_color2.R = 0
    zero_color2.G =1
    zero_color2.B = 0
    zero_color2.A = 0
local hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
local reusable_hit_result1 = StructObject.new(hitresult_c)
local PawnMeshLast=nil
local TargetPos=nil
local TickCount=0
local ResetTriggered=false

local function Init()
	game_engine_class = find_required_object("Class /Script/Engine.GameEngine")
	kismet_system_library = find_static_class("Class /Script/Engine.KismetSystemLibrary")
	--local zero_color = nil
	color_c = find_required_object("ScriptStruct /Script/CoreUObject.LinearColor")
	SmoothSetting =find_required_object("CameraPOIAnchorBehavior_C /Game/Camera/Behaviors/CameraPOIAnchorBehavior.Default__CameraPOIAnchorBehavior_C")
	zero_color = StructObject.new(color_c)
		
	zero_color2 = StructObject.new(color_c)
		zero_color2.R = 0
		zero_color2.G =1
		zero_color2.B = 0
		zero_color2.A = 0
	hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
	reusable_hit_result1 = StructObject.new(hitresult_c)
end

local ReINIT=false

local function SetCameraRotation(pawn_c)
	--if isMenu then
	--	pawn_c.Camera:ClearLookAtPOIAnchor()
	--end
	if isMenu==false then
		if ResetTriggered and TickCount <5 then
			
			TickCount=TickCount+1
			
			--if TickCount ==5 then
			 pawn_c.Camera:ClearLookAtPOIAnchor()
			--end
			
		end
		if TickCount ==2 then
			ReINIT=true
		end
		
			
		local ignore_actors ={}
		local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
		local viewport = game_engine.GameViewport
		local world = viewport.World
	
		local temp_vec3f1 = Vector3f.new(0, 000, 0)
		local temp_vec3f2 = Vector3f.new(0, 000, 80)
		local CurrentRot = pawn_c.SidearmSkeletal:K2_GetComponentRotation().z
		--print(pawn_c.Camera.PointOfInterestWithAnchorBehavior.BlendInSmoothingSettings.SmoothingFactor)
		
		local hit= kismet_system_library:LineTraceSingle_NEW(world, pawn_c.SidearmSkeletal:K2_GetComponentLocation(), pawn_c.SidearmSkeletal:K2_GetComponentLocation()-(pawn_c.SidearmSkeletal:GetRightVector())*10000, 0, true, ignore_actors, 0, reusable_hit_result1, true, zero_color, zero_color, 1.0)
		--pawn_c.Camera:SetLookAtPOIAnchor(pawn_c.SidearmSkeletal:K2_GetComponentLocation()-(pawn_c.SidearmSkeletal:GetRightVector())*reusable_hit_result1.Distance +(pawn_c.SidearmSkeletal:GetForwardVector())*0, true,temp_vec3f1,temp_vec3f2,0,1,0,-CurrentRot,90,0.89)--,Script_CoreUObject::Vector& TargetPosition, bool bTargetLock, bool bOverrideValues, _Script_CoreUObject::Vector LookAtOffset, _Script_CoreUObject::Vector FollowOffset, float FollowDistance, float FOV, float BlendTime, void* MovementControlMode
		
		local EndPoint = Vector3f.new(reusable_hit_result1.ImpactPoint.X, reusable_hit_result1.ImpactPoint.Y, reusable_hit_result1.ImpactPoint.Z)
			if hit==false then
				EndPoint = pawn_c.SidearmSkeletal:K2_GetComponentLocation()-(pawn_c.SidearmSkeletal:GetRightVector())*10000
			end
		
			if not isMenu or not TickCount==5 then
				pawn_c.Camera:SetLookAtPOIAnchor(EndPoint, true,temp_vec3f1,temp_vec3f2,0,1,0,-CurrentRot+0.5,200,0.89)--,Script_CoreUObject::Vector& TargetPosition, bool bTargetLock, bool bOverrideValues, _Script_CoreUObject::Vector LookAtOffset, _Script_CoreUObject::Vector FollowOffset, float FollowDistance, float FOV, float BlendTime, void* MovementControlMode
			end	--print(EndPoint.x)
			if TickCount== 5 then
				pawn_c.Camera:ClearLookAtPOIAnchor()
				ResetTriggered=false
				TickCount=0
				
			end
	else
	pcall(function()
	pawn_c.Camera:ClearLookAtPOIAnchor()
	end)
	
	pcall(function()
	PawnMeshLast.Camera:ClearLookAtPOIAnchor()
	end)
	print("reset")
	ResetTriggered=true
		TickCount=0
		--ReINIT=true
		Init()
	end
	--print(TickCount)
	PawnMeshLast=pawn_c
end


local ReadyUpTick=0
uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)
	

	
local pawn_c= api:get_local_pawn(0)
if isDriving== false then
--pawn_c.Camera:ClearLookAtPOIAnchor()

	if not ReINIT then
		SetCameraRotation(pawn_c)
	else
		pawn_c.Camera:ClearLookAtPOIAnchor()
		ReINIT=false
	end
	
	if SmoothSetting.BlendInSmoothingSettings.SmoothingFactor ~= 0.0 then
	SmoothSetting.BlendInSmoothingSettings.SmoothingFactor=0.0
	end

end	
end)

uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)



if isButtonPressed(state, XINPUT_GAMEPAD_LEFT_THUMB) then
		    ReadyUpTick= ReadyUpTick+1
		if ReadyUpTick ==120 then
			--api:get_player_controller(0):ReadyUp()
			--pawn_c.Camera:ClearLookAtPOIAnchor()
				ReINIT=true
				TickCount=0
		end
else 
	ReadyUpTick=0
	
end
end)