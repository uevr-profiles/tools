local controllers = require('libs/controllers')
require(".\\Subsystems\\Motion")






local CamAngle=RightRotator
local AttackDelta=0
local HandVector= Vector3f.new(0.0,0.0,0.0)
local HmdVector = Vector3f.new(0.0,0.0,0.0)
local VecAlpha  = Vector3f.new(0,0,0)
local Alpha  	= nil
local AlphaDiff =0
local LastState= isBow
local ConditionChagned=false
local isMenuEnter=false
local YawLast=0
local hitresult = StructObject.new(hitresult_c)
local LeftRightScaleFactor		=0
local ForwardBackwardScaleFactor=0
	
local KismetMathLib= kismet_math_library

--local neededPitch= 0--hmd_component:K2_GetComponentRotation().X
--local neededYaw = 0
local CurrentPitch = 0--player.ControlRotation.X
local DiffPitch = 0--(neededPitch - CurrentPitch)
--local Target = KismetMathLib:Add_VectorVector(hmd_component:K2_GetComponentRotation(), hmd_component:GetForwardVector()*500)
local rotdelta =0


uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)
local pawn = api:get_local_pawn(0)
local player =api:get_player_controller(0)

if pawn~=nil then
	
	--pawn.DesiredControllerYaw=neededYaw
	--pawn.DesiredControllerPitch=neededPitch
	
--	if hmd_component~=nil then	
		--neededPitch= right_hand_component:K2_GetComponentRotation().X
		--CurrentPitch = player.ControlRotation.X
		--DiffPitch = (neededPitch - CurrentPitch)		
		--rotdelta = neededYaw- player.ControlRotation.Yaw
		
	local Start= right_hand_component:K2_GetComponentLocation()
	local End = Start+right_hand_component:GetForwardVector()*20000
	
	local color={}
	local Trace= kismet_system_library:LineTraceSingle(world,Start, End, 0,true,{},false,hitresult,true,color,color,0)
	
	local TargetLoc= hitresult.ImpactPoint
	local TargetLoc2=Vector3f.new(TargetLoc.X,TargetLoc.Y,TargetLoc.Z)
	print(hitresult.Distance)
	if hitresult.Distance==0 then
		TargetLoc2 = End
	end
	local TargetObjLoc = pawn:K2_GetActorLocation()
	if pawn.CurrentWeapon~=nil then
		TargetObjLoc=pawn.CurrentWeapon.Mesh:K2_GetComponentLocation()
	end
	local TargetVec= KismetMathLib:Subtract_VectorVector(TargetLoc2,TargetObjLoc)
	local TargetRot= KismetMathLib:Conv_VectorToRotator(TargetVec)
	
	player:SetControlRotation(TargetRot)--,delta,false)
	----end	

	
--	pawn.CameraBoomComponent:SetActorsToIgnore({pawn})
--	pawn.Mesh:SetCollisionEnabled(0)
--	pawn.Mesh:SetCollisionResponseToAllChannels(0)
	--pawn.CapsuleComponent:SetGenerateOverlapEvents(false)
--	UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_hand(1)
--  --  UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_location_offset(lossy_offset)
--	UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_rotation_offset(Vector3f.new(0,math.pi/2,0))
--    UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_permanent(true)
	
		
		--local Target = KismetMathLib:Add_VectorVector(hmd_component:K2_GetComponentRotation(), hmd_component:GetForwardVector()*500)
		
	
		--if rotdelta > 180 then
		--	rotdelta = rotdelta - 360
		--elseif rotdelta < -180 then
		--	rotdelta = rotdelta + 360
		--end
		
		--print(rotdelta)
		
		--if pawn~=nil then
		--	if DiffPitch>0 then
		--		pawn:InpAxisEvt_LookUp_K2Node_InputAxisEvent_1(-math.abs(DiffPitch)*delta)
		--	elseif DiffPitch<-0 then
		--		pawn:InpAxisEvt_LookUp_K2Node_InputAxisEvent_1(math.abs(DiffPitch)*delta)
		--	end
		--	if rotdelta>0 then
		--		pawn:InpAxisEvt_Turn_K2Node_InputAxisEvent_0(math.abs(rotdelta)*delta)
		--	elseif rotdelta<-0 then
		--		pawn:InpAxisEvt_Turn_K2Node_InputAxisEvent_0(-math.abs(rotdelta)*delta)
		--	end
		--end
			
			
			
			--HmdVector=hmd_component:GetForwardVector()
		--	HandVector= right_hand_component:GetForwardVector()
			
		--	VecAlpha = (HandVector.x - HmdVector.x, HandVector.y - HmdVector.y, HandVector.z - HmdVector.z)
						--		local VecAlphaX= HandVector.x - HmdVector.x
						--		local VecAlphaY= HandVector.y - HmdVector.y
						--		local Alpha1
						--		local Alpha2
						--		if HandVector.x >=0 and HandVector.y>=0 then	
						--		Alpha1 =math.pi/2-math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
						--		--print("Quad1")
						--		elseif HandVector.x <0 and HandVector.y>=0 then
						--		--print("Quad2")
						--		Alpha1 =math.pi/2-math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
						--		elseif HandVector.x <0 and HandVector.y<0 then
						--		--print("Quad3")
						--		Alpha1 =math.pi+math.pi/2+math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
						--		elseif HandVector.x >=0 and HandVector.y<0 then
						--		--print("Quad4")
						--		Alpha1 =3/2*math.pi+math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
						--		end
						--		
						--		if HmdVector.x >=0 and HmdVector.y>=0 then	
						--		Alpha2 =math.pi/2-math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
						--		--print("Quad1")
						--		elseif HmdVector.x <0 and HmdVector.y>=0 then
						--		--print("Quad2")
						--		Alpha2 =math.pi/2-math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
						--		elseif HmdVector.x <0 and HmdVector.y<0 then
						--		--print("Quad3")
						--		Alpha2 =math.pi+math.pi/2+math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
						--		elseif HmdVector.x >=0 and HmdVector.y<0 then
						--		--print("Quad4")
						--		Alpha2 =3/2*math.pi+math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
						--		end
						--		
						--		
						--		AlphaDiff= Alpha2-Alpha1
						--		if isBow and RTrigger ~= 0 then
						--			AlphaDiff=AlphaDiff-math.pi*20/180
						--		end
			
			
			
	
	
	--end
end
end)

local DecoupledYawCurrentRot = 0
local RXState=0
local SnapAngle
 



uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)


--Read Gamepad stick input for rotation compensation
	--if HeadBasedMovement   then
	
	
	
	
	
	
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



	rotation.y = DecoupledYawCurrentRot
	
	
	--vr.recenter_view()
local pawn = api:get_local_pawn(0)	
--if pawn~=nil then
	position.z = pawn:K2_GetActorLocation().z+90
	position.x = pawn:K2_GetActorLocation().x
	position.y = pawn:K2_GetActorLocation().y
--end

end)

uevr.sdk.callbacks.on_post_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
	--print(DecoupledYawCurrentRot)
local pawn=api:get_local_pawn(0)

neededYaw=rotation.y
neededPitch=rotation.x
neededRoll=rotation.z
	DecoupledYawCurrentRotLast=rotation.y	

end)