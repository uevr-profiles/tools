require(".\\Config\\CONFIG")
require(".\\Subsystems\\GlobalData")
require(".\\Subsystems\\GlobalCustomData")
require(".\\Subsystems\\HelperFunctions")
require(".\\Main\\FOVFixer")




local last_PMesh=nil

local function update_weapon_offset(dpawn,weapon_mesh,SocketName)
    if not weapon_mesh then return end
	
	
    local attach_socket_name = weapon_mesh.AttachSocketName
	local PMesh= weapon_mesh
	--if last_PMesh~=nil and last_PMesh~=PMesh then
	--    UEVR_UObjectHook.get_or_add_motion_controller_state(last_PMesh):set_permanent(false)
	--	UEVR_UObjectHook.remove_motion_controller_state(last_PMesh)
	--	--last_PMesh:K2_SetRelativeLocation(Vector3f.new(0,0,-74.8),false,hitresult,true)
	--end
	--last_PMesh= PMesh	 
    -- Get socket transforms
    local default_transform = PMesh:GetSocketTransform(SocketName,2)--Transform(attach_socket_name, 2)
    --local offset_transform = PMesh:GetSocketTransform("pinky_4_RI",2)--weapon_mesh:GetSocketTransform("jnt_offset", 2)
	
	--local middle_translation = kismet_math_library:Add_VectorVector(default_transform.Translation, offset_transform.Translation)
    local location_diff = kismet_math_library:Subtract_VectorVector(
        default_transform.Translation,--middle_translation,--.Translation,
        Vector3f.new(0,0,0)
    )
    -- from UE to UEVR X->Z Y->-X, Z->-Y
    -- Z - forward, X - negative right, Y - negative up
    local lossy_offset = Vector3f.new(location_diff.y, location_diff.z, -location_diff.x)
    -- Apply the offset to the weapon using motion controller state
	
	local CounterRoll =	- right_hand_component:K2_GetComponentRotation().Roll
	if CounterRoll < 90 and CounterRoll> -90 then
	elseif CounterRoll>90 then
		CounterRoll = 180- CounterRoll
	elseif CounterRoll<-90 then
		CounterRoll = -180- CounterRoll
	end
	
	
	
	
	--print("Roll " .. CounterRoll)
	local CounterPitch = dpawn.Owner.ControlRotation.Pitch--dpawn.Mesh.AnimScriptInstance.AimPitch--default_transform.Rotation.X * 180/math.pi		--right_hand_component:K2_GetComponentRotation().Pitch
	--print("Pitch".. CounterPitch)
	local CounterAngle= CounterPitch + CounterRoll -- dpawn.Owner.ControlRotation.Pitch
	--print(CounterAngle)
	--if CounterAngle>170 then CounterAngle=170 
	--elseif CounterAngle<-170 then CounterAngle=-170
	--end
	local CounterAngleRad= CounterAngle/180*math.pi
	
	
	
    UEVR_UObjectHook.get_or_add_motion_controller_state(PMesh):set_hand(1)
    UEVR_UObjectHook.get_or_add_motion_controller_state(PMesh):set_location_offset(lossy_offset)
	 UEVR_UObjectHook.get_or_add_motion_controller_state(PMesh):set_rotation_offset(Vector3f.new(CounterAngleRad,math.pi/2,0))
    UEVR_UObjectHook.get_or_add_motion_controller_state(PMesh):set_permanent(true)
 -- print(default_transform.Translation.x.. "   " ..default_transform.Translation.y .. "    " ..default_transform.Translation.z)
end

local PawnLast=nil
local CompLastActor= {}
local function UpdateVisibility(dpawn)
	if dpawn==nil then return end	

end


local WpnArray ={}
local SwitchDelta=0
 
local function StartDelta(dDelta)
	SwitchDelta=SwitchDelta+dDelta
	if SwitchDelta >2.5 then
		SwitchDelta=0
		isDelta=false
		TriggerCheck=true
		WpnSwitch=false
		ChangeReq=false --resets request from collisionb lua
	end
end	
local Offset=0
local HmdRotatorYLast=0


local function GetHmdYawOffset()		
	local deltaOffset= 0
	if math.abs(neededYaw - HmdRotatorYLast) < 90 then
		deltaOffset=neededYaw - HmdRotatorYLast
	else
		deltaOffset= 1
	end	
	if math.abs(Offset) <= 70 then
		Offset= Offset+deltaOffset
	elseif Offset >70 then
		Offset=70
	elseif Offset< -70 then
		Offset=-70
	end	
	if ThumbLY>15000 or neededPitch>-20 then
			Offset=Offset/4
	end
	local YawOffset= Offset/180*math.pi	
	HmdRotatorYLast=neededYaw	
	return YawOffset
end		


local GlockHolstered=false
local BinoHolstered=false

local function UpdateWeaponAttach(dMeshArray,MeshStringFind,MeshSocketString)
		--CurrentWeaponMesh=nil
	for i,comp in ipairs(dMeshArray) do
		if string.find(comp:get_full_name(), MeshStringFind) and not string.find(comp:get_full_name(), "Melee") then
			if comp.AttachSocketName:to_string() == MeshSocketString then
				MeshR = comp
				--if string.find(comp:get_full_name(),"Glock") then
				---	GlockMesh=comp
				--end
				--MeshR:DetachFromParent(true,false)
				if HandSceneComp~=nil then
				MeshR:K2_AttachToComponent(HandSceneComp,MeshSocketString,0,0,0,false)
			--	MeshR.RelativeRotation.Yaw=101
			--	MeshR.RelativeRotation.Roll=-18.76
			--	--MeshR.RelativeRotation.Pitch=14.57
			--	MeshR.RelativeLocation.X=-8.38
			--	MeshR.RelativeLocation.Y=.3
			--	MeshR.RelativeLocation.Z=8.52
				end
--				UEVR_UObjectHook.get_or_add_motion_controller_state(MeshR):set_hand(1)
--				--UEVR_UObjectHook.get_or_add_motion_controller_state(MeshR):set_location_offset(lossy_offset)
--				UEVR_UObjectHook.get_or_add_motion_controller_state(MeshR):set_location_offset(Vector3f.new(-2,-5,0))
--				UEVR_UObjectHook.get_or_add_motion_controller_state(MeshR):set_rotation_offset(Vector3f.new(0,math.pi/2,0))
--				UEVR_UObjectHook.get_or_add_motion_controller_state(MeshR):set_permanent(true)
		

		--	MeshR:SetVisibility(true,true)
			--	MeshR:SetRenderInMainPass(true)
				
				CurrentWeaponMesh=MeshR
			--elseif comp.AttachSocketName:to_string() == "Left_WeaponSocket" then
			--	MeshL = comp
			--	UEVR_UObjectHook.get_or_add_motion_controller_state(MeshL):set_hand(1)
			--	--UEVR_UObjectHook.get_or_add_motion_controller_state(MeshR):set_location_offset(lossy_offset)
			--	UEVR_UObjectHook.get_or_add_motion_controller_state(MeshL):set_rotation_offset(Vector3f.new(0,math.pi/2,0))
			--	UEVR_UObjectHook.get_or_add_motion_controller_state(MeshL):set_location_offset(Vector3f.new(-2,-3,0))
			--	UEVR_UObjectHook.get_or_add_motion_controller_state(MeshL):set_permanent(true)
			else
				Mesh=comp
				--if string.find(comp:get_full_name(),"Glock") then
				--	GlockMesh=comp
				--end
				--if comp:get_outer()["ShowcaseWeapon?"]~=nil then
				--	UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_hand(2)
				--	UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_location_offset(Vector3f.new(200,0,0))
				--comp:K2_SetRelativeLocation(Vector3d.new(0,0,0),false,{},false)
				--end
			end		
			
		end
	end
	if GlockMesh~=nil and GlockMesh.AttachSocketName~=MeshSocketString then
		GlockHolstered=true
	else
		GlockHolstered=false
	end
end

uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)
		pawn = api:get_local_pawn(0)
		
		
	if WpnSwitch or ChangeReq then 
		isDelta =true
	end
	if isDelta then
		StartDelta(delta)
	end	
	
if HandSceneComp~=nil then
	local CrouchOffsetZ=0
	local CrouchOffsetX=0
	local AimOffsetZ = 0
	local AimOffsetX = 0
	local AimOffsetY = 0
	--if pawn.bIsCrouched then
	--	 CrouchOffsetZ = 53
	--	 CrouchOffsetX = 2
	--	--HandSceneComp.RelativeLocation.Z=-70
	--else	CrouchOffsetZ=0 
	--		CrouchOffsetX = 0
	--	--HandSceneComp.RelativeLocation.Z=-144.940
	--end
	--if pawn.Mesh.AnimScriptInstance["Aiming?"] then
	--	AimOffsetZ=-3
	--	AimOffsetX=12
	--	AimOffsetY=7.430
	--else AimOffsetZ=0
	--	AimOffsetX=0
	--	AimOffsetY=0
	--end
		
		--if LTrigger>0  then
				local default_transform = pawn.Mesh:GetSocketTransform("ik_hand_gun",2)
				local DefaultTranslation = default_transform.Translation
				pawn.Mesh.RelativeLocation.Z=-DefaultTranslation.Z +4---144.940
				pawn.Mesh.RelativeLocation.X=-DefaultTranslation.Y +5 ---22.440---39
				pawn.Mesh.RelativeLocation.Y=DefaultTranslation.X    ---7.430---39
		--end
		--HandSceneComp.RelativeLocation.Z=-144.940 + CrouchOffsetZ + AimOffsetZ
		--HandSceneComp.RelativeLocation.X=-22.440 +CrouchOffsetX +AimOffsetX ---39
		--HandSceneComp.RelativeLocation.Y=-7.430+AimOffsetY---39
end
		
if pawn~=nil and (TriggerCheck or Debug) then --see above triggercheck after timer runs out
	CheckCollision=true   --activates collision box refresh in collsionlua
	TriggerCheck=false --reset for next timer
	--pawn.Mesh:SetOwnerNoSee(false)
	local MeshR=nil--pawn.CurrentWeapon:GetCurrentBaseMesh()
	local MeshL=nil
	local WpnArray = {}
	local MeshArray = pawn.Mesh.AttachChildren
	--local UpperBodyArray = pawn.Children[1]
	--if not Debug then
		UpdateWeaponAttach(MeshArray,"SkeletalMesh","ik_hand_gun")--UpdateWeaponAttach(dMeshArray,MeshStringFind,MeshSocketString) --CLEAN
	--end
	local MeshArray1 = pawn.Children
	
	checkMaterial(pawn,MeshArray1,"FOV_Alpha") --from FOV FIXER
	--update_weapon_offset(pawn,pawn.Mesh,"weapon_r")
	
end




--if pawn~=nil  then
--	if 	GlockHolstered then		
--		if GlockMesh~=nil then
--		
--			UEVR_UObjectHook.get_or_add_motion_controller_state(GlockMesh):set_hand(2)
--			UEVR_UObjectHook.get_or_add_motion_controller_state(GlockMesh):set_location_offset(Vector3f.new(0,45,-15))
--			UEVR_UObjectHook.get_or_add_motion_controller_state(GlockMesh):set_rotation_offset(Vector3f.new(neededPitch*math.pi/180,90*math.pi/180+GetHmdYawOffset(),neededRoll*math.pi/180))
--		else GlockHolstered=false
--		end
--	end
--	if 	BinoHolstered then		
--		if BinoMesh~=nil then
--		
--		--	UEVR_UObjectHook.get_or_add_motion_controller_state(BinoMesh):set_hand(2)
--		--	UEVR_UObjectHook.get_or_add_motion_controller_state(BinoMesh):set_location_offset(Vector3f.new(0,45,15))
--		--	UEVR_UObjectHook.get_or_add_motion_controller_state(BinoMesh):set_rotation_offset(Vector3f.new(neededPitch*math.pi/180,90*math.pi/180+GetHmdYawOffset(),neededRoll*math.pi/180))
--		else
--			BinoHolstered=false
--		end
--	end 
--end



end)