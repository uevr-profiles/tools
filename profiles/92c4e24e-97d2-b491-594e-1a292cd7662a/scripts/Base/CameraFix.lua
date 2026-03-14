require(".\\Base\\Subsystems\\UEHelperFunctions")
local api = uevr.api

  local pawn = api:get_local_pawn(0) 
  
  local EquipState = 0
  local pawnMeshIsCrouched = false
--  local transform_c = api:find_uobject("ScriptStruct /Script/CoreUObject.Transform")
 -- local my_transform = StructObject.new(transform_c)
  local CrouchedHeightOffset = 35
  local StandingHeightOffset = 72.955
  local Optiwand_position = nil
  local OptiwandInUse = false
  local DefaultOffset= uevr.params.vr:get_mod_value("VR_ControllerPitchOffset")
  local inMenu = false
  
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

local Vec_temp_C= find_required_object("ScriptStruct /Script/CoreUObject.Vector")
local Vec_temp= StructObject.new(Vec_temp_C)
  
local Rot_temp_C= find_required_object("ScriptStruct /Script/CoreUObject.Rotator")
local Rot_temp= StructObject.new(Rot_temp_C)
  
  
  function PositiveIntegerMask(text)
	return text:gsub("[^%-%d]", "")
end
-- variables for math transform --
--function QuatToEuler(q1)
--	local SingTest= q1.x * q1.y + q1.z * q1.w
--	local e1={}
--	--e1.x= math.atan(0.2,0.1)
--	if SingTest>0.499 then -- singularty at north pole
--		e1.y=2*math.atan2(q1.x,q1.w)
--		e1.z=math.pi/2
--		e1.x=0
--		print("np")
--		
--	elseif SingTest<-0.499 then--singularity at southpole
--		e1.y=-2* math.atan2(q1.x,q1.w)
--		e1.z=-math.pi/2
--		e1.x=0
--		print("sp")
--	else
--		sqx = q1.x*q1.x
--		sqy =q1.y*q1.y
--		sqz =q1.z*q1.z
--		atn1=(2* q1.y * q1.w - 2* q1.x * q1.z )
--		atn2=(1 - 2*sqy - 2*sqz)
--		--print(atn1)
--		--print(atn2)
--		
--		e1.x= math.atan(2*q1.x*q1.w-2*q1.y*q1.z , 1 - 2*sqx - 2*sqz)---math.pi   --pitch
--		e1.y= -math.atan(atn1,atn2)									    --yaw
--		e1.z = -math.asin(2*SingTest)								    --roll
--		
--	end
--	return e1
--end
--
--local hmd_rotation = {}
--
--function EulerToQuad(e2)
--    --Assuming the angles are in radians.
--	--local e2= vec3.new(e2.x,e2.y,e2.z)
--	local c1 = math.cos(e2.y/2)
--	local s1 = math.sin(e2.y/2)
--	local c2 = math.cos(e2.x/2)
--	local s2 = math.sin(e2.x/2)
--	local c3 = math.cos(e2.z/2)
--	local s3 = math.sin(e2.z/2)
--	local c1c2 = c1*c2
--	local s1s2 = s1*s2
--	
--	
--    w =c1c2*c3 - s1s2*s3
--  	x =c1c2*s3 + s1s2*c3
--	y =s1*c2*c3 + c1*s2*s3
--	z =c1*s2*c3 - s1*c2*s3
--	
--	local Check= Vector4f.new(-w,-x,-y,-z)
--	return Check
--end


--callback loop based on input--



	
	

--callback based on View calculation tick--
local RotSave=0
local RotDiff=0
local RotationXStart=0
local RotationXCur=0
local LastTickRot=0
uevr.params.sdk.callbacks.on_early_calculate_stereo_view_offset(

function(device, view_index, world_to_meters, position, rotation, is_double)
--print(rotation.x)
	    
local dpawn=api:get_local_pawn(0)
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
		
		if dpawn ~= nil  then
			pawn_pos = dpawn.RootComponent:K2_GetComponentLocation()
		--	print(pawn:get_fname():to_string())
			position.x = pawn_pos.x 
			position.y = pawn_pos.y -- +5
			if pawnMeshIsCrouched==0 then
				position.z = pawn_pos.z + 74
			elseif pawnMeshIsCrouched == 1 then
				position.z = pawn_pos.z + 50
			elseif pawnMeshIsCrouched == 2 then
				position.z = pawn_pos.z
			end
		end
	

end)

--uevr.sdk.callbacks.on_post_calculate_stereo_view_offset(
--function(device, view_index, world_to_meters, position, rotation, is_double)
--uevr.params.vr.set_mod_value("VR_AimMethod" , "2")
--
--end)

local UsedPrimary=1

--uevr.sdk.callbacks.on_xinput_set_state(
--function(retval, user_index, state)
--print(state.wRightMotorSpeed)
--	if UsedPrimary <= 0.04 then
--		state.wRightMotorSpeed 	= 0000
--		state.wLeftMotorSpeed 	= 0000
--	elseif UsedPrimary >0.04 then
--		state.wRightMotorSpeed = 0
--		state.wLeftMotorSpeed = 0
--	end
--end)

--local VertTickCount=0
--local VertDiffLast=0
--local RotDiffLast=0
--local VertDiffsecondaryLast=0
--		
--local VertDiffOut =0
--local VertDiffPreTick=0
--local VertDiffsecondaryPreTick=0
--local RotDiffPretick=0
--
--local ResetTick=0
--local TT = 0
--callback always

uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)

--uevr.params.vr.set_mod_value("VR_AimMethod" , "2")
--	if ResetTick==3 then
--		VertDiffPreTick=VertDiff
--	end
end)


local angleRot=0
local isInit=false
uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)

angleRot=angleRot+10*delta



		pawn = api:get_local_pawn(0)
		
		local lplayer = api:get_player_controller(0)

if pawn~=nil then	
																							--		print(MeshC)	
--Find Mesh of Char0
			local pawnMesh= pawn.Mesh
			if pawnMesh~=nil then
				pawnMeshIsCrouched = pawn.Position_Body
			end
end

			
end)	
			
