	--CONFIG
	--require(".\\Subsystems\\Trackers")
	local MeleePower = 200 --Default = 1000
	---------------------------------------
	local MeleeDistance=1 -- 30cm + MeleeDistance per meter,e.g. 30cm+ 0.4*1m = 70cm
	local api = uevr.api
	local vr = uevr.params.vr
	--local params = uevr.params
	local callbacks = uevr.params.sdk.callbacks
	local pawn = api:get_local_pawn(0)
	local lHand_Pos =UEVR_Vector3f.new()
	local lHand_Rot =UEVR_Quaternionf.new()
	local rHand_Pos =UEVR_Vector3f.new()
	local rHand_Rot =UEVR_Quaternionf.new()
	local rHand_Joy =UEVR_Vector2f.new()
	local PosZOld=0
	local PosYOld=0
	local PosXOld=0
	local PosZOldR=0
	local PosYOldR=0
	local PosXOldR=0
	local tickskip=0
	local PosDiff = 0
	local PosDiffR = 0
	
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

--Helper functions
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
local swinging_fast = nil

local melee_data = {
    right_hand_pos_raw = UEVR_Vector3f.new(),
    right_hand_q_raw = UEVR_Quaternionf.new(),
    right_hand_pos = Vector3f.new(0, 0, 0),
    last_right_hand_raw_pos = Vector3f.new(0, 0, 0),
    last_time_messed_with_attack_request = 0.0,
    first = true,
}

local isHit1=false
local isHit2=false
local isHit3=false
local isHit4=false
local isHit5=false



--Library
local kismet_system_library = find_static_class("Class /Script/Engine.KismetSystemLibrary")

local UGameplayStatics_library= find_static_class("Class /Script/Engine.GameplayStatics")
local game_engine_class = find_required_object("Class /Script/Engine.GameEngine")

local zero_color = nil
local color_c = find_required_object("ScriptStruct /Script/CoreUObject.LinearColor")
local    actor_c = find_required_object("Class /Script/Engine.Actor")
local zero_color = StructObject.new(color_c)
	
local hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
local GameplayStaticsDefault= find_required_object("GameplayStatics /Script/Engine.Default__GameplayStatics")
local reusable_hit_result1 = StructObject.new(hitresult_c)
--local reusable_hit_result2=  StructObject.new(hitresult_c)
--local reusable_hit_result3 = StructObject.new(hitresult_c)
--local reusable_hit_result4 = StructObject.new(hitresult_c)
--local reusable_hit_result5 = StructObject.new(hitresult_c)

local DeltaCheck=0
local Mouse1=false
local DeltaAimMethod =0
local isAimMethodSwitched=false
local Hittest = nil
uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)

	DeltaCheck=DeltaCheck+delta
	--print(DeltaCheck)
	pawn = api:get_local_pawn(0)

	--local rHandIndex = uevr.params.vr.get_right_controller_index()
	uevr.params.vr.get_pose(2, lHand_Pos, lHand_Rot)
	
	local PosXNew=lHand_Pos.x
	local PosYNew=lHand_Pos.y
	local PosZNew=lHand_Pos.z
	
	PosDiff = math.sqrt((PosXNew-PosXOld)^2+(PosYNew-PosYOld)^3+(PosZNew-PosZOld)^2)*10000
	PosZOld=PosZNew
	PosYOld=PosYNew
	PosXOld=PosXNew
	
	uevr.params.vr.get_pose(1, rHand_Pos, rHand_Rot)
	local PosXNewR=rHand_Pos.x
	local PosYNewR=rHand_Pos.y
	local PosZNewR=rHand_Pos.z
	
	PosDiffR = math.sqrt((PosXNewR-PosXOldR)^2+(PosYNewR-PosYOldR)^3+(PosZNewR-PosZOldR)^2)*10000
	PosZOldR=PosZNewR
	PosYOldR=PosYNewR
	PosXOldR=PosXNewR
	--print(PosDiff)
--Praydog VARIUANT:	use swinging_fast
	--vr.get_pose(vr.get_right_controller_index(), melee_data.right_hand_pos_raw, melee_data.right_hand_q_raw)
	--
    ---- Copy without creating new userdata
    --melee_data.right_hand_pos:set(melee_data.right_hand_pos_raw.x, melee_data.right_hand_pos_raw.y, melee_data.right_hand_pos_raw.z)
	--
    --if melee_data.first then
    --    melee_data.last_right_hand_raw_pos:set(melee_data.right_hand_pos.x, melee_data.right_hand_pos.y, melee_data.right_hand_pos.z)
    --    melee_data.first = false
    --end
	--
    --local velocity = (melee_data.right_hand_pos - melee_data.last_right_hand_raw_pos) * (1 / delta)
	--
    ---- Clone without creating new userdata
    --melee_data.last_right_hand_raw_pos.x = melee_data.right_hand_pos_raw.x
    --melee_data.last_right_hand_raw_pos.y = melee_data.right_hand_pos_raw.y
    --melee_data.last_right_hand_raw_pos.z = melee_data.right_hand_pos_raw.z
    --melee_data.last_time_messed_with_attack_request = melee_data.last_time_messed_with_attack_request + delta


	--local vel_len = velocity:length()
	--    
	--if velocity.y < 0 then
	--swinging_fast = vel_len >= 2.5
	--end
--

	
	
	
	--Hitscan
	if pawn.MeleeWeapon ~=nil then--Weapon condition
		--local MeleeMesh= right_hand_component:K2_GetComponentLocation()--pawn.CurrentMeleeWeapon.StaticMesh
		local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
		local viewport = game_engine.GameViewport
		local world = viewport.World
		local ignore2_actors = {}
		local Array_Objects ={}
		local Upvector= pawn.MeleeWeapon:GetUpVector()
		local RightVector= pawn.MeleeWeapon:GetRightVector()
		local MeshLocation1=pawn.MeleeWeapon:K2_GetComponentLocation()-pawn.MeleeWeapon:GetRightVector()*30
		local endPos1=MeshLocation1+(pawn.MeleeWeapon:GetForwardVector())*8192
	--	local MeshLocation2=pawn.Equipment.EquippedWeapon.SkeletalMeshComponent:K2_GetComponentLocation()+RightVector*-20+pawn.Equipment.EquippedWeapon.SkeletalMeshComponent:GetForwardVector()*30
	--	local endPos2=MeshLocation2+(pawn.Equipment.EquippedWeapon.SkeletalMeshComponent:GetForwardVector())*8192
	--	local MeshLocation3=pawn.Equipment.EquippedWeapon.SkeletalMeshComponent:K2_GetComponentLocation()+Upvector*20+pawn.Equipment.EquippedWeapon.SkeletalMeshComponent:GetForwardVector()*30
	--	local endPos3=MeshLocation3+(pawn.Equipment.EquippedWeapon.SkeletalMeshComponent:GetForwardVector())*8192
	--	local MeshLocation4=pawn.Equipment.EquippedWeapon.SkeletalMeshComponent:K2_GetComponentLocation()+Upvector*-20+pawn.Equipment.EquippedWeapon.SkeletalMeshComponent:GetForwardVector()*30
	--	local endPos4=MeshLocation4+(pawn.Equipment.EquippedWeapon.SkeletalMeshComponent:GetForwardVector())*8192
	--	local MeshLocation5=pawn.Equipment.EquippedWeapon.SkeletalMeshComponent:K2_GetComponentLocation()+pawn.Equipment.EquippedWeapon.SkeletalMeshComponent:GetForwardVector()*30
	--	local endPos5=MeshLocation5+(pawn.Equipment.EquippedWeapon.SkeletalMeshComponent:GetForwardVector())*8192
	--	GameplayStaticsDefault:FindCollisionUV(reusable_hit_result1, 2,UV, true)
		local hit1 = kismet_system_library:LineTraceSingle_NEW(world, MeshLocation1, endPos1, 0, true, ignore2_actors, 0, reusable_hit_result1, true, zero_color, zero_color, 10.0)
	--	local hit2 = kismet_system_library:LineTraceSingle(world, MeshLocation2, endPos2, "ECC_Visibility", true, ignore2_actors, 0, reusable_hit_result2, true, zero_color, zero_color, 10.0)
	--	--local FHitRes= UGameplayStatics_library:BreakHitResult(reusable_hit_result2)
	--	local hit3 = kismet_system_library:LineTraceSingle(world, MeshLocation3, endPos3, 0, true, ignore2_actors, 0, reusable_hit_result3, true, zero_color, zero_color, 10.0)
	--	local hit4 = kismet_system_library:LineTraceSingle(world, MeshLocation4, endPos4, 0, true, ignore2_actors, 0, reusable_hit_result4, true, zero_color, zero_color, 10.0)
	--	local hit5 = kismet_system_library:LineTraceSingle(world, MeshLocation5, endPos5, 0, true, ignore2_actors, 0, reusable_hit_result5, true, zero_color, zero_color, 10.0)
	--	local hit6= world:LineTraceSingleByChannels()
		if hit1 and reusable_hit_result1.Distance < 1000*MeleeDistance then
			isHit1=true
		else isHit1=false
		end
		if isHit1  then
			local EndPoint = Vector3f.new(reusable_hit_result1.ImpactPoint.X, reusable_hit_result1.ImpactPoint.Y, reusable_hit_result1.ImpactPoint.Z)
			pawn.MeleeWeapon:AddForceAtLocation(EndPoint*200,EndPoint, reusable_hit_result1.BoneName)
		end
		--if hit2 and reusable_hit_result2.Distance < 100*MeleeDistance then
		--	isHit2=true
		--else isHit2=false
		--end
		--if hit3 and reusable_hit_result3.Distance < 100*MeleeDistance then
		--	isHit3=true
		--else isHit3=false
		--end
		--if hit4 and reusable_hit_result4.Distance < 100*MeleeDistance then
		--	isHit4=true
		--else isHit4=false
		--end
		--if hit5 and reusable_hit_result5.Distance < 50*MeleeDistance then
		--	isHit5=true
		--else isHit5=false
		--end
		--if reusable_hit_result2.Actor ~=nil then
	Hittest = reusable_hit_result1
	print(Hittest.ImpactPoint)
	print(Hittest.Component)
	print(Hittest.BoneName)
	print(Hittest.Item)
	print(Hittest.bBlockingHit)
	print(" ")
	--end
		
		--print(reusable_hit_result2.Distance)
		--print(isHit1)
		--print(isHit2)
		--print(isHit3)
		--print(isHit4)
		--print(isHit5)
		--print("  ")
	end
	--if Mouse1==true then
	--	
	--	if DeltaCheck >=0.3 then
	--	--uevr.params.vr.set_mod_value("VR_AimMethod", "2")
	--	Mouse1 =false
	--	DeltaCheck=0
	--	--isHit1=false
	--	--	isHit2=false
	--	--	isHit3=false
	--	--	isHit4=false
	--	--	uevr.params.vr.set_mod_value("VR_AimMethod", "2")
	--	--uevr.params.vr.set_mod_value("VR_ControllerPitchOffset", "-21")
	--	end
	--end

	
	--if isHit5  then
	--DeltaAimMethod=DeltaAimMethod+delta
	--	if DeltaAimMethod > 0.1 and isAimMethodSwitched==false then
	--	isAimMethodSwitched=true
	--	uevr.params.vr.set_mod_value("VR_AimMethod", "0")
	--	DeltaAimMethod=0
	--	end
	--elseif Mouse1==false  then
	--	uevr.params.vr.set_mod_value("VR_AimMethod", "2")
	--	isAimMethodSwitched=false
	--	
	--end
	
end)

local Prep=false
local PrepR=false

uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)




--local TriggerR = state.Gamepad.bRightTrigger
--if PosDiff >= MeleePower and Prep == false then
--	Prep=true
--elseif PosDiff <=150 and Prep ==true then
--	SendKeyDown('0x01')
--	Prep=false
--	Mouse1=true
--end
--state.Gamepad.bRightTrigger=0



--if PosDiffR >= MeleePower and PrepR == false then
--	Prep=true
--elseif PosDiffR <=10 and PrepR ==true then
--	state.Gamepad.bRightTrigger= 255
--	PrepR=false
--end	



--	if PosDiff >= MeleePower and Mouse1==false then
--	
--	
--	--uevr.params.vr.set_mod_value("VR_AimMethod", "1")
--		if state.Gamepad.bRightTrigger==255 then
--			state.Gamepad.bRightTrigger=0
--		elseif state.Gamepad.bRightTrigger==0 then
--			state.Gamepad.bRightTrigger=255
--		end
--		DeltaCheck=0
--		isHit1=false
--		isHit2=false
--		isHit3=false
--		isHit4=false
--		Mouse1=true
--		Prep=false
--		print("Collision Hit")
--	end
--elseif PosDiff >= MeleePower and Prep == false and Mouse1==false then
--	Prep=true
--	isHit1=false
--		isHit2=false
--		isHit3=false
--		isHit4=false
--elseif PosDiff <=50 and Prep ==true and Mouse1==false then
--	uevr.params.vr.set_mod_value("VR_ControllerPitchOffset", "0")
--	state.Gamepad.bRightTrigger=255
--	Prep=false
--	isHit1=false
--		isHit2=false
--		isHit3=false
--		isHit4=false
--	Mouse1=true
--	DeltaCheck=0
--		print("freehit")
	
--end





--Read Gamepad stick input for rotation compensation
	
	
 
	--testrotato.Y= CurrentPressAngle


		--RotationOffset
	--ConvertedAngle= kismet_math_library:Quat_MakeFromEuler(testrotato)
	--print("x: " .. ConvertedAngle.X .. "     y: ".. ConvertedAngle.Y .."     z: ".. ConvertedAngle.Z .. "     w: ".. ConvertedAngle.W)





end)