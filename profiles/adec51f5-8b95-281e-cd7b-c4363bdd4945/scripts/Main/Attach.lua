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
local TriggerCheck=false
local function StartDelta(dDelta)
	SwitchDelta=SwitchDelta+dDelta
	if SwitchDelta >3 then
		SwitchDelta=0
		isDelta=false
		TriggerCheck=true
	end
end	
		

uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)
		pawn = api:get_local_pawn(0)
		
		
	if WpnSwitch then 
		isDelta =true
	end
	if isDelta then
		StartDelta(delta)
	end	
	
		
		
if pawn~=nil and TriggerCheck then
	TriggerCheck=false
	pawn.Mesh:SetOwnerNoSee(true)
	ChildrenArray = pawn.Mesh.AttachChildren
	WpnArray ={}
	for i, comp in ipairs(ChildrenArray) do
		if string.find(comp:get_full_name() ,"Scene") then
			table.insert(WpnArray,comp)
			
		end
	end
	
	for i, comp in ipairs(WpnArray) do
		
		if comp.AttachSocketName:to_string() == "hand_r" then
			local Mesh = comp.AttachChildren[1]
			UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_hand(1)
			UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_permanent(true)
			UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_rotation_offset(Vector3f.new(0,math.pi/2,0))
			
			if string.find(Mesh:get_full_name(), "Glock") then
				UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_location_offset(Vector3f.new(-10,-5,0))
			else	
				UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_location_offset(Vector3f.new(-30,-15,0))
			end
		else
			local Mesh = comp.AttachChildren[1]
			UEVR_UObjectHook.remove_motion_controller_state(Mesh)
		
			comp.RelativeLocation.X=0
			comp.RelativeLocation.Y=0
			comp.RelativeLocation.Z=0
			comp.RelativeRotation.Y=0
		end
	end

if not Ybutton and not Bbutton then
--	update_weapon_offset( pawn,PrimaryMesh, "thumb_02_r")
end

end

end)