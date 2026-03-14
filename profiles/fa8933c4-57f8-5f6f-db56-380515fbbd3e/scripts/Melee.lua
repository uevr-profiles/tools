	--CONFIG
	require(".\\Subsystems\\Trackers")
	local MeleePower = 800 --Default = 1000
	---------------------------------------
	local MeleeDistance=0.4 -- 30cm + MeleeDistance per meter,e.g. 30cm+ 0.4*1m = 70cm
	local api = uevr.api
	
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

local isHit1=false
local isHit2=false
local isHit3=false
local isHit4=false
local kismet_system_library = find_static_class("Class /Script/Engine.KismetSystemLibrary")
local zero_color = nil
local color_c = find_required_object("ScriptStruct /Script/CoreUObject.LinearColor")
local zero_color1 = StructObject.new(color_c)
	zero_color1.R = 2
    zero_color1.G =0
    zero_color1.B = 0
    zero_color1.A = 0
local zero_color2 = StructObject.new(color_c)
	zero_color2.R = 0
    zero_color2.G =1
    zero_color2.B = 0
    zero_color2.A = 0
local hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
local reusable_hit_result1 = StructObject.new(hitresult_c)
local reusable_hit_result2 = StructObject.new(hitresult_c)
local reusable_hit_result3 = StructObject.new(hitresult_c)
local reusable_hit_result4 = StructObject.new(hitresult_c)

uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)

	
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
--Show Cursor
	if api:get_player_controller().bShowMouseCursor or pawn["RadialMenuOpen?"] then
		uevr.params.vr.set_mod_value("FrameworkConfig_AlwaysShowCursor", "true")
		--inMenu=true
	else uevr.params.vr.set_mod_value("FrameworkConfig_AlwaysShowCursor", "false")
		--inMenu=false
	end

	tickskip=0
	
	--Hitscan
	if pawn.MeleeWeaponEquipped then
		--local MeleeMesh= right_hand_component:K2_GetComponentLocation()--pawn.CurrentMeleeWeapon.StaticMesh
		local ignore_actors = {}
		local Upvector= right_hand_component:GetUpVector()
		local MeshLocation1=right_hand_component:K2_GetComponentLocation()+right_hand_component:GetForwardVector()*30
		local endPos1=MeshLocation1+(right_hand_component:GetForwardVector())*8192
		local MeshLocation2=right_hand_component:K2_GetComponentLocation()+Upvector*10+right_hand_component:GetForwardVector()*30
		local endPos2=MeshLocation2+(right_hand_component:GetForwardVector())*8192
		local MeshLocation3=right_hand_component:K2_GetComponentLocation()+Upvector*20+right_hand_component:GetForwardVector()*30
		local endPos3=MeshLocation3+(right_hand_component:GetForwardVector())*8192
		local MeshLocation4=right_hand_component:K2_GetComponentLocation()+Upvector*30+right_hand_component:GetForwardVector()*30
		local endPos4=MeshLocation4+(right_hand_component:GetForwardVector())*8192
		local hit1 = kismet_system_library:LineTraceSingle(world, MeshLocation1, endPos1, 0, true, ignore_actors, 0, reusable_hit_result1, true, zero_color1, zero_color2, 1.0)
		local hit2 = kismet_system_library:LineTraceSingle(world, MeshLocation2, endPos2, 1, true, ignore_actors, 0, reusable_hit_result2, true, zero_color1, zero_color2, 1.0)
		local hit3 = kismet_system_library:LineTraceSingle(world, MeshLocation3, endPos3, 1, true, ignore_actors, 0, reusable_hit_result3, true, zero_color1, zero_color2, 1.0)
		local hit4 = kismet_system_library:LineTraceSingle(world, MeshLocation4, endPos4, 1, true, ignore_actors, 0, reusable_hit_result4, true, zero_color1, zero_color2, 1.0)
		if hit1 and reusable_hit_result1.Distance < 100*MeleeDistance then
			isHit1=true
		else isHit1=false
		end
		
		if hit2 and reusable_hit_result2.Distance < 100*MeleeDistance then
			isHit2=true
		else isHit2=false
		end
		if hit3 and reusable_hit_result3.Distance < 100*MeleeDistance then
			isHit3=true
		else isHit3=false
		end
		if hit4 and reusable_hit_result4.Distance < 100*MeleeDistance then
			isHit4=true
		else isHit4=false
		end
		
	
		print(reusable_hit_result1.PhysMaterialIndex)
		print(reusable_hit_result1.BoneName)
		print(reusable_hit_result1.HitObject_ManagerIndex)
		print(reusable_hit_result1.ActorIndex)
		print(reusable_hit_result1.HitObject)
		print(reusable_hit_result1.HitObject)
		if pawn["Attacking?"] then
				uevr.params.vr.set_mod_value("VR_AimMethod", "0")
		else    uevr.params.vr.set_mod_value("VR_AimMethod", "2")
		end
		
		
	
		--print(isHit1)
		--print(isHit2)
		--print(isHit3)
		--print(isHit4)
		--print("  ")
	end
	

end)

local Prep=false
local PrepR=false
local Mouse1=false
uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)


if Mouse1==true then
	SendKeyUp('0x01')
	Mouse1 =false
end

--local TriggerR = state.Gamepad.bRightTrigger
--if PosDiff >= MeleePower and Prep == false then
--	Prep=true
--elseif PosDiff <=150 and Prep ==true then
--	SendKeyDown('0x01')
--	Prep=false
--	Mouse1=true
--end



--if PosDiffR >= MeleePower and PrepR == false then
--	Prep=true
--elseif PosDiffR <=10 and PrepR ==true then
--	state.Gamepad.bRightTrigger= 255
--	PrepR=false
--end	

if isHit1 or isHit2 or isHit3 or isHit4  then
	if PosDiff >= MeleePower then
		SendKeyDown('0x01')
		isHit1=false
		isHit2=false
		isHit3=false
		isHit4=false
		Mouse1=true
		print("Collision Hit")
	end
else
	if PosDiff >= MeleePower and Prep == false then
	Prep=true
	elseif PosDiff <=150 and Prep ==true then
	SendKeyDown('0x01')
	Prep=false
	Mouse1=true
		print("freehit")
	end
end




--Read Gamepad stick input for rotation compensation
	
	
 
	--testrotato.Y= CurrentPressAngle


		--RotationOffset
	--ConvertedAngle= kismet_math_library:Quat_MakeFromEuler(testrotato)
	--print("x: " .. ConvertedAngle.X .. "     y: ".. ConvertedAngle.Y .."     z: ".. ConvertedAngle.Z .. "     w: ".. ConvertedAngle.W)





end)