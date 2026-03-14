require(".\\Subsystems\\Motion")




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
	local CounterAngle= dpawn.Owner.ControlRotation.Pitch/180*math.pi
	
    UEVR_UObjectHook.get_or_add_motion_controller_state(PMesh):set_hand(1)
    UEVR_UObjectHook.get_or_add_motion_controller_state(PMesh):set_location_offset(lossy_offset)
	 UEVR_UObjectHook.get_or_add_motion_controller_state(PMesh):set_rotation_offset(Vector3f.new(CounterAngle,math.pi/2,0))
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
	if SwitchDelta >1.5 then
		SwitchDelta=0
		isDelta=false
		TriggerCheck=true
		ChangeReq=false
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
uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)
		pawn = api:get_local_pawn(0)
		
		
	if WpnSwitch or ChangeReq then 
		isDelta =true
	end
	if isDelta then
		StartDelta(delta)
	end	
	
		
		
if pawn~=nil then
	CheckCollision=true
	TriggerCheck=false
	pawn.Mesh:SetOwnerNoSee(true)
	local MeshR=nil--pawn.CurrentWeapon:GetCurrentBaseMesh()
	local MeshL=nil
	local WpnArray = {}
	local MeshArray = pawn.Mesh.AttachChildren
	for i,comp in ipairs(MeshArray) do
		if string.find(comp:get_full_name(), "WeaponBase") then
			if comp.AttachSocketName:to_string() == "Right_Weapon socket" then
				MeshR = comp
				--MeshR:DetachFromParent(true,false)
				--MeshR:K2_AttachToComponent(right_hand_component,"",0,0,0,false)
				UEVR_UObjectHook.get_or_add_motion_controller_state(MeshR):set_hand(1)
				--UEVR_UObjectHook.get_or_add_motion_controller_state(MeshR):set_location_offset(lossy_offset)
				UEVR_UObjectHook.get_or_add_motion_controller_state(MeshR):set_location_offset(Vector3f.new(-2,-3,0))
				UEVR_UObjectHook.get_or_add_motion_controller_state(MeshR):set_rotation_offset(Vector3f.new(0,math.pi/2,0))
				UEVR_UObjectHook.get_or_add_motion_controller_state(MeshR):set_permanent(true)
				MeshR.BoundsScale=1
				MeshR.ForcedLodModel=0
				MeshR.MinLodModel=0
				
			elseif comp.AttachSocketName:to_string() == "Left_WeaponSocket" then
				MeshL = comp
				UEVR_UObjectHook.get_or_add_motion_controller_state(MeshL):set_hand(1)
				--UEVR_UObjectHook.get_or_add_motion_controller_state(MeshR):set_location_offset(lossy_offset)
				UEVR_UObjectHook.get_or_add_motion_controller_state(MeshL):set_rotation_offset(Vector3f.new(0,math.pi/2,0))
				UEVR_UObjectHook.get_or_add_motion_controller_state(MeshL):set_location_offset(Vector3f.new(-2,-3,0))
				UEVR_UObjectHook.get_or_add_motion_controller_state(MeshL):set_permanent(true)
			else
				Mesh=comp
				UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_hand(2)
				UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_location_offset(Vector3f.new(200,0,0))
				--comp:K2_SetRelativeLocation(Vector3d.new(0,0,0),false,{},false)
				
			end			
		end
	end
	if pawn.CurrentWeapon~=nil then
		if not string.find(pawn.CurrentWeapon:get_full_name(),"PumpAction") then
			pawn.CurrentWeapon.WeaponConfig.Spread.Base=0
		end
	end
	
end
if pawn~=nil  then
	if 	GlockHolstered then		
		if GlockMesh~=nil then
		
		--	UEVR_UObjectHook.get_or_add_motion_controller_state(GlockMesh):set_hand(2)
		--	UEVR_UObjectHook.get_or_add_motion_controller_state(GlockMesh):set_location_offset(Vector3f.new(0,45,-15))
		--	UEVR_UObjectHook.get_or_add_motion_controller_state(GlockMesh):set_rotation_offset(Vector3f.new(neededPitch*math.pi/180,90*math.pi/180+GetHmdYawOffset(),neededRoll*math.pi/180))
		else GlockHolstered=false
		end
	end
	if 	BinoHolstered then		
		if BinoMesh~=nil then
		
		--	UEVR_UObjectHook.get_or_add_motion_controller_state(BinoMesh):set_hand(2)
		--	UEVR_UObjectHook.get_or_add_motion_controller_state(BinoMesh):set_location_offset(Vector3f.new(0,45,15))
		--	UEVR_UObjectHook.get_or_add_motion_controller_state(BinoMesh):set_rotation_offset(Vector3f.new(neededPitch*math.pi/180,90*math.pi/180+GetHmdYawOffset(),neededRoll*math.pi/180))
		else
			BinoHolstered=false
		end
	end 
end



end)