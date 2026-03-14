--require(".\\Trackers\\Trackers")
require(".\\Config\\CONFIG")
require(".\\Subsystems\\UEHelper")
local controllers = require('libs/controllers')
--require(".\\Config\\CONFIG")
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




local CamAngle=RightRotator
local AttackDelta=0
local HandVector= Vector3f.new(0.0,0.0,0.0)
local HmdVector = Vector3d.new(0.0,0.0,0.0)
local VecAlpha  = Vector3f.new(0,0,0)
local Alpha  	= nil
local AlphaDiff =0
local LastState= isBow
local ConditionChagned=false
local isMenuEnter=false
local YawLast=0

local LeftRightScaleFactor		=0
local ForwardBackwardScaleFactor=0
local dynamic_material=nil
 --testCam= nil	


local game_engine_class = find_required_object("Class /Script/Engine.GameEngine")
--local SplineCams_C = find_required_object("BlueprintGeneratedClass /Game/GPE/Camera/BP_SplineCamera.BP_SplineCamera_C")
--local SplineCams ={}
--
local last_level=nil
--
--local function UpdateSplineCams()
--	if FirstCatMode~= 1 then
--		for i, comp in ipairs(SplineCams)	do
--			comp:SetActorEnableCollision(false)
--			local Camera= comp.Camera
--			if Camera~=nil then
--				UEVR_UObjectHook.get_or_add_motion_controller_state(Camera):set_hand(2)
--				UEVR_UObjectHook.get_or_add_motion_controller_state(Camera):set_permanent(true)
--			end
--		end
--	end
--end	
local SwappedCam=nil
--local spline= find_required_object("SplineComponent /Game/Map/_MainGame/BaseMap.BaseMap.PersistentLevel.BP_CameraThirdPerson_C_2147480311.smoothedTargetSpline")
--local spline2= find_required_object("SplineComponent /Game/Map/_MainGame/BaseMap.BaseMap.PersistentLevel.BP_CameraThirdPerson_C_2147480311.smoothedCameraSpline")
uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)
local pawn = api:get_local_pawn(0)
local player =api:get_player_controller(0)

local engine = game_engine_class:get_first_object_matching(false)
		if not engine then
			return
		end
	
		local viewport = engine.GameViewport
	
		if viewport then
			world = viewport.World
	
			if world then
				local level = world.PersistentLevel
	
				if last_level ~= level then
					testCam=nil
					 FurM= nil
				--	if SplineCams_C==nil then	
				--		SplineCams_C = find_required_object("BlueprintGeneratedClass /Game/GPE/Camera/BP_SplineCamera.BP_SplineCamera_C")
				--	end
				--	SplineCams= UEVR_UObjectHook.get_objects_by_class(SplineCams_C,false)  --	player:SetAudioListenerOverride(controllers.getController(2),Vector3d.new(0,0,0),Vector3d.new(0,0,0))
				--	UpdateSplineCams()
				end
	
				last_level = level
			end
		end

	if controllers.getController(2)==nil then
		controllers.createController(2)
	end
	local CurrCam= player.PlayerCameraManager.ViewTarget.Target.CameraComponent
	if CurrCam==nil then 
		CurrCam = player.PlayerCameraManager.ViewTarget.Target.Camera
	end
	
	
	if CurrCam~=testCam and CurrCam~=nil and not isCinematic then
		SwappedCam=CurrCam
		player.PlayerCameraManager.ViewTarget.Target:SetActorEnableCollision(false)
		UEVR_UObjectHook.get_or_add_motion_controller_state(CurrCam):set_hand(2)
		UEVR_UObjectHook.get_or_add_motion_controller_state(CurrCam):set_permanent(true)
	end
	if isCinematic then
		UEVR_UObjectHook.remove_motion_controller_state(CurrCam)
	end
	if CurrCam~=SwappedCam then
		
		UEVR_UObjectHook.remove_motion_controller_state(SwappedCam)
	end

	if pawn~=nil then
		if testCam==nil then
			
			testCam=find_first_of("Class /Script/Hk_project.CameraThirdPerson",false)
			
		--elseif not string.find(testCam:get_fname():to_string(),"_C_") then
		--	print(testCam:get_fname():to_string())
		--	testCam=find_first_of("Class /Script/Hk_project.CameraThirdPerson",false)
		end
		--print(testCam:get_full_name())
	end
		local hmd_component=controllers.getController(2)
		if hmd_component~=nil then
			HmdVector=KismetMathLibrary:Add_VectorVector(hmd_component:GetForwardVector(),(hmd_component:GetUpVector())*(-0.5))
		end
		local AimVector= Vector3d.new(0,0,0)
		if pawn~=nil and testCam~=nil  then
			HmdVector.X= HmdVector.X*(-500)
			HmdVector.Y= HmdVector.Y*(-500)
			HmdVector.Z= HmdVector.Z*(-500)
		
			AimVector=KismetMathLibrary:Add_VectorVector(hmd_component:K2_GetComponentLocation(),HmdVector)
			--pawn:K2_GetActorLocation()-HmdVector*500
			
		--   right_hand_component:GetForwardVector()
			if FirstCatMode~=1 then
				testCam:AlignToPosition(AimVector,false)
			end
		end
		local RHandComponent = controllers.getController(1)
		if RHandComponent~=nil then
			HandVector= RHandComponent:GetForwardVector()
		end
		--print(HmdVector.Y)
	--	VecAlpha = (HandVector.x - HmdVector.x, HandVector.y - HmdVector.y, HandVector.z - HmdVector.z)
							local VecAlphaX= HandVector.x - HmdVector.x
							local VecAlphaY= HandVector.y - HmdVector.y
							local Alpha1
							local Alpha2
							if HandVector.x >=0 and HandVector.y>=0 then	
							Alpha1 =math.pi/2-math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
							--print("Quad1")
							elseif HandVector.x <0 and HandVector.y>=0 then
							--print("Quad2")
							Alpha1 =math.pi/2-math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
							elseif HandVector.x <0 and HandVector.y<0 then
							--print("Quad3")
							Alpha1 =math.pi+math.pi/2+math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
							elseif HandVector.x >=0 and HandVector.y<0 then
							--print("Quad4")
							Alpha1 =3/2*math.pi+math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
							end
							
							if HmdVector.x >=0 and HmdVector.y>=0 then	
							Alpha2 =math.pi/2-math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
							--print("Quad1")
							elseif HmdVector.x <0 and HmdVector.y>=0 then
							--print("Quad2")
							Alpha2 =math.pi/2-math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
							elseif HmdVector.x <0 and HmdVector.y<0 then
							--print("Quad3")
							Alpha2 =math.pi+math.pi/2+math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
							elseif HmdVector.x >=0 and HmdVector.y<0 then
							--print("Quad4")
							Alpha2 =3/2*math.pi+math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
							end
							
							
							AlphaDiff= Alpha2-Alpha1
							if isBow and RTrigger ~= 0 then
								AlphaDiff=AlphaDiff-math.pi*20/180
							end
		
		
		



end)

local DecoupledYawCurrentRot = 0
local RXState=0
local SnapAngle
 



uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)


--Read Gamepad stick input for rotation compensation
	--if HeadBasedMovement   then
	
	
	
	
	
	--	state.Gamepad.sThumbLX= ThumbLX*math.cos(-AlphaDiff)- ThumbLY*math.sin(-AlphaDiff)
				
	--	state.Gamepad.sThumbLY= math.sin(-AlphaDiff)*ThumbLX + ThumbLY*math.cos(-AlphaDiff)
		
	--end



	SnapAngle = PositiveIntegerMask(uevr.params.vr:get_mod_value("VR_SnapturnTurnAngle"))
	if SnapTurn then
		if ThumbRX >200 and RXState ==0 and not isMenu then
			DecoupledYawCurrentRot=DecoupledYawCurrentRot + SnapAngle
			RXState=1
		elseif ThumbRX <-200 and RXState ==0 and not isMenu  then
			DecoupledYawCurrentRot=DecoupledYawCurrentRot - SnapAngle
			RXState=1
		elseif ThumbRX <= 200 and ThumbRX >=-200  then
			RXState=0
		end
 
	
	else
		
		SmoothTurnRate = PositiveIntegerMask(uevr.params.vr:get_mod_value("VR_SnapturnTurnAngle"))/90
	
	
		local rate = state.Gamepad.sThumbRX/32767
					rate =  rate*rate*rate
		if ThumbRX >2200 and not isMenu   then
			DecoupledYawCurrentRot=DecoupledYawCurrentRot + SmoothTurnRate * rate
			
		elseif ThumbRX <-2200 and not isMenu   then
			DecoupledYawCurrentRot=DecoupledYawCurrentRot + SmoothTurnRate * rate
		
		end
	end


end)



local PreRot
local DiffRot
local DecoupledYawCurrentRotLast=0
uevr.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
PreRot=rotation.y
--DiffRot= HmdRotator.y - RightRotator.y

	--vr.recenter_view()
local pawn = api:get_local_pawn(0)	
if FirstCatMode~= 1 and pawn.m_visual~=nil then
	rotation.y = DecoupledYawCurrentRot
	if FirstCatMode== 3 then
		position.z = pawn.m_visual:GetSocketLocation("face_Head_JNT").z
		position.x = pawn.m_visual:GetSocketLocation("face_Head_JNT").x
		position.y = pawn.m_visual:GetSocketLocation("face_Head_JNT").y
	elseif FirstCatMode==2 then
		position.z = pawn:K2_GetActorLocation().z+34
		position.x = pawn:K2_GetActorLocation().x
		position.y = pawn:K2_GetActorLocation().y
	end
end


end)

uevr.sdk.callbacks.on_post_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
	--print(DecoupledYawCurrentRot)
local pawn=api:get_local_pawn(0)

	

	DecoupledYawCurrentRotLast=rotation.y	

end)