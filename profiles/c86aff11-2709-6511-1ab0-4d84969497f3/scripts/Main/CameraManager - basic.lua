--local controllers = require('libs/controllers')
require(".\\Config\\CONFIG")
require(".\\Subsystems\\GlobalData")
require(".\\Subsystems\\GlobalCustomData")
require(".\\Subsystems\\HelperFunctions")
	




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
	


--local neededPitch= 0--hmd_component:K2_GetComponentRotation().X
--local neededYaw = 0
local CurrentPitch = 0--player.ControlRotation.X
local DiffPitch = 0--(neededPitch - CurrentPitch)
--local Target = KismetMathLib:Add_VectorVector(hmd_component:K2_GetComponentRotation(), hmd_component:GetForwardVector()*500)
local rotdelta =0
local CamDelta=20

uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)
local pawn = api:get_local_pawn(0)
local player =api:get_player_controller(0)

if pawn~=nil and hmd_component~=nil and right_hand_component~=nil then
	
	
	
	--if CamDelta> 20 then
		if Cam==nil then
			Cam= pawn.FP_Camera
		end	
		--CamDelta=0
		if Cam~=nil and Cam.AttachParent~=pawn.CapsuleComponent then
			Cam= pawn.FP_Camera--player.PlayerCameraManager.ActiveCameraState.CameraComp
			Cam:K2_AttachToComponent(pawn.CapsuleComponent,"",2,2,0,false)
			Cam.RelativeLocation.Z= 80
		end
	--else 
	--	CamDelta=CamDelta+delta
	--end
	
	

--	local altRot= hmd_component:K2_GetComponentRotation()
--	if not HeadBasedMovement then 
--	
--		altRot= right_hand_component:K2_GetComponentRotation()
--		
--	end
--	
--		player:SetControlRotation(altRot)--,delta,false)
--	
--
--
--		if hmd_component	~=nil then	
--			--print("HmdFound")
--			HmdVector = hmd_component:GetForwardVector()
--			HandVector= right_hand_component:GetForwardVector()
--			
--		--	VecAlpha = (HandVector.x - HmdVector.x, HandVector.y - HmdVector.y, HandVector.z - HmdVector.z)
--								local VecAlphaX= HandVector.x - HmdVector.x
--								local VecAlphaY= HandVector.y - HmdVector.y
--								local Alpha1=0
--								local Alpha2=0
--								if HandVector.x >=0 and HandVector.y>=0 then	
--								Alpha1 =math.pi/2-math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
--								--print("Quad1")
--								elseif HandVector.x <0 and HandVector.y>=0 then
--								--print("Quad2")
--								Alpha1 =math.pi/2-math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
--								elseif HandVector.x <0 and HandVector.y<0 then
--								--print("Quad3")
--								Alpha1 =math.pi+math.pi/2+math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
--								elseif HandVector.x >=0 and HandVector.y<0 then
--								--print("Quad4")
--								Alpha1 =3/2*math.pi+math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
--								end
--								
--								if HmdVector.x >=0 and HmdVector.y>=0 then	
--								Alpha2 =math.pi/2-math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
--								--print("Quad1")
--								elseif HmdVector.x <0 and HmdVector.y>=0 then
--								--print("Quad2")
--								Alpha2 =math.pi/2-math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
--								elseif HmdVector.x <0 and HmdVector.y<0 then
--								--print("Quad3")
--								Alpha2 =math.pi+math.pi/2+math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
--								elseif HmdVector.x >=0 and HmdVector.y<0 then
--								--print("Quad4")
--								Alpha2 =3/2*math.pi+math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
--								end
--								
--								
--								AlphaDiff= Alpha2-Alpha1
--								
--			
--			
--	
--	
--	end
end
end)

local DecoupledYawCurrentRot = 0
local RXState=0
local SnapAngle
 



uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)
	
	pawn= api:get_local_pawn(0)
	--Read Gamepad stick input for rotation compensation
		--if HeadBasedMovement   then
	--	if  HeadBasedMovement and not isCinematic  then-- then-- and not isCinematic and not isMenu then
	--			state.Gamepad.sThumbLX= ThumbLX*math.cos(-AlphaDiff)- ThumbLY*math.sin(-AlphaDiff)
					--	print(AlphaDiff)
	--			state.Gamepad.sThumbLY= math.sin(-AlphaDiff)*ThumbLX + ThumbLY*math.cos(-AlphaDiff)
	--	end
		
		
		
if pawn~=nil and pawn.Controller~= nil then	
	if pawn.Controller.ControlRotation~=nil then	
		--end
		DecoupledYawCurrentRot= pawn.Controller.ControlRotation.Yaw 
		
		
		SnapAngle = PositiveIntegerMask(uevr.params.vr:get_mod_value("VR_SnapturnTurnAngle"))
		if SnapTurn and not isMenu then
			if StickR.x >0.2 and RXState ==0  then
				pawn.Controller.ControlRotation.Yaw =DecoupledYawCurrentRot + SnapAngle
				RXState=1
			elseif StickR.x <-0.2 and RXState ==0   then
				pawn.Controller.ControlRotation.Yaw =DecoupledYawCurrentRot - SnapAngle
				RXState=1
			elseif StickR.x <= 0.200 and StickR.x >=-0.200  then
				RXState=0
			end
	
		
		else
			
			SmoothTurnRate = PositiveIntegerMask(uevr.params.vr:get_mod_value("VR_SnapturnTurnAngle"))/90
		
		
			local rate = StickR.x
						rate =  rate*rate*rate
			if StickR.x >0.1 and not isMenu  then
				pawn.Controller.ControlRotation.Yaw =DecoupledYawCurrentRot + SmoothTurnRate * rate
				
			elseif StickR.x <-0.1 and not isMenu  then
				pawn.Controller.ControlRotation.Yaw =DecoupledYawCurrentRot + SmoothTurnRate * rate
			
			end
		end
	end	
end
end)
--			
--			
--			
--			local PreRot
--			local DiffRot
--			local DecoupledYawCurrentRotLast=0
--			uevr.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
--			
--			local pawn = api:get_local_pawn(0)	
--			if pawn~=nil and not isCinematic  then
--				
--				
--			--	rotation.y = DecoupledYawCurrentRot
--				
--				
--				--vr.recenter_view()
--			
--				--local default_transform = pawn.Mesh:GetSocketTransform("headSocket",2).Translation.Z
--				--print(default_transform)
--				
--			--	position.z = pawn:K2_GetActorLocation().z+90
--			--	--if default_transform<100 then
--			--	--	position.z = pawn:K2_GetActorLocation().z+10
--			--	--end
--			--	position.x = pawn:K2_GetActorLocation().x
--			--	position.y = pawn:K2_GetActorLocation().y
--			end
--			
--			end)
--			
			uevr.sdk.callbacks.on_post_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
				--print(DecoupledYawCurrentRot)
			--local pawn=api:get_local_pawn(0)
			
			neededYaw=rotation.y
			neededPitch=rotation.x
			neededRoll=rotation.z
		--	DecoupledYawCurrentRotLast=rotation.y	
			
			end)