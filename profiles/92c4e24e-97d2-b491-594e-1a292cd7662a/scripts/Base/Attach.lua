

local api = uevr.api
local pawn = api:get_local_pawn(0) 

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

local kismet_string_library = find_static_class("Class /Script/Engine.KismetStringLibrary")
local kismet_math_library = find_static_class("Class /Script/Engine.KismetMathLibrary")
local kismet_system_library = find_static_class("Class /Script/Engine.KismetSystemLibrary")
local Statics = find_static_class("Class /Script/Engine.GameplayStatics")
local hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")

local hitresult = StructObject.new(hitresult_c)

local last_PMesh=nil

local function update_weapon_offset(dpawn,weapon_mesh)
    if not weapon_mesh then return end
	
	
    local attach_socket_name = weapon_mesh.AttachSocketName
	local PMesh= weapon_mesh
	if last_PMesh~=nil and last_PMesh~=PMesh then
	    UEVR_UObjectHook.get_or_add_motion_controller_state(last_PMesh):set_permanent(false)
		UEVR_UObjectHook.remove_motion_controller_state(last_PMesh)
		last_PMesh:K2_SetRelativeLocation(Vector3f.new(0,0,-74.8),false,hitresult,true)
	end
	last_PMesh= PMesh	 
    -- Get socket transforms
    local default_transform = PMesh:GetSocketTransform("Hand_R_Gun",2)--Transform(attach_socket_name, 2)
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
	local CounterAngle= dpawn.AimingY/180*math.pi
	
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
	if dpawn.Inventory_Comp== nil then return end
	if dpawn~= PawnLast then
		
		for i, comp in ipairs (CompLastActor) do
			comp:SetVisibility(true)
			comp:SetRenderInMainPass(true)
			print("Okay")
		end
		PawnLast=dpawn
		CompLastActor= {}
			
		--dpawn.Inventory_Comp.BP_Gloves.SK_Gloves:SetVisibility(false)
		if dpawn.Inventory_Comp.BP_Shoes  then
			dpawn.Inventory_Comp.BP_Shoes.SK_Shoes  :SetVisibility(false)
			table.insert(CompLastActor, dpawn.Inventory_Comp.BP_Shoes.SK_Shoes )
		end
		if dpawn.Inventory_Comp.BP_Pants then
			dpawn.Inventory_Comp.BP_Pants.SK_Pants	:SetVisibility(false)
			table.insert(CompLastActor, dpawn.Inventory_Comp.BP_Pants.SK_Pants	)
		end
		if dpawn.Inventory_Comp.BP_Shirt then
			dpawn.Inventory_Comp.BP_Shirt.SK_Shirt  :SetVisibility(false)
				table.insert(CompLastActor, dpawn.Inventory_Comp.BP_Shirt.SK_Shirt )
		end
		if dpawn.Inventory_Comp.BP_Belt then
			table.insert(CompLastActor, dpawn.Inventory_Comp.BP_Belt.SK_Belt_A )
			table.insert(CompLastActor, dpawn.Inventory_Comp.BP_Belt.SK_Belt_B )
			dpawn.Inventory_Comp.BP_Belt.SK_Belt_A  :SetVisibility(false)
			dpawn.Inventory_Comp.BP_Belt.SK_Belt_B  :SetVisibility(false)
		--table.insert(CompLastActor, dpawn.Inventory_Comp.BP_Gloves.SK_Gloves)
		end
		
	end		
end
local function UpdateADS()

	if pawn.Inventory_Comp then
		if pawn.Inventory_Comp.BP_Weapon_1.BP_Attach_Sight.Sight_1st then
			--if pawn.Inventory_Comp.BP_Weapon_1.BP_Attach_Sight.Use_ADS then
				pawn.Inventory_Comp.BP_Weapon_1.BP_Attach_Sight.Sight_1st.OverrideMaterials[1]:SetScalarParameterValue("Offset",-1000)
				pawn.Inventory_Comp.BP_Weapon_1.BP_Attach_Sight.Sight_1st.OverrideMaterials[1]:SetScalarParameterValue("Scale",3)
			--elseif not pawn.Inventory_Comp.BP_Weapon_1.BP_Attach_Sight.Use_ADS and  pawn.Inventory_Comp.BP_Weapon_1.BP_Attach_Sight.Use_ADS_Secondary then
				--pawn.Inventory_Comp.BP_Weapon_1.BP_Attach_Sight.Sight_1st.OverrideMaterials[1]:SetScalarParameterValue("Enable",1)
		elseif 	pawn.Inventory_Comp.BP_Weapon_1.BP_Attach_Sight.StaticMesh then
				pawn.Inventory_Comp.BP_Weapon_1.BP_Attach_Sight.StaticMesh.OverrideMaterials[1]:SetScalarParameterValue("Offset",-1000)
				pawn.Inventory_Comp.BP_Weapon_1.BP_Attach_Sight.StaticMesh.OverrideMaterials[1]:SetScalarParameterValue("Scale",3)
		end		
		if pawn.Inventory_Comp.BP_Weapon_1.BP_Attach_Sight.Sight_2nd then		
				
				pawn.Inventory_Comp.BP_Weapon_1.BP_Attach_Sight.Sight_2nd.OverrideMaterials[1]:SetScalarParameterValue("Offset",-1000)
				pawn.Inventory_Comp.BP_Weapon_1.BP_Attach_Sight.Sight_2nd.OverrideMaterials[1]:SetScalarParameterValue("Scale",3)
		end
	end
end



uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)
		pawn = api:get_local_pawn(0)
if pawn~=nil then--  and  not string.find(pawn:get_full_name(), "Dead")  then
	PrimaryMesh= pawn.Mesh-- pawn.Inventory_Comp.BP_Gloves
	
	update_weapon_offset( pawn,PrimaryMesh)
	UpdateVisibility(pawn)
	UpdateADS()
end

end)