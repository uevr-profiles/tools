



local api = uevr.api
	
	local params = uevr.params
	local callbacks = params.sdk.callbacks
	local pawn = api:get_local_pawn(0)
	local player= api:get_player_controller(0)
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

KismetStringLibrary = find_static_class("Class /Script/Engine.KismetStringLibrary")

CurrAttachedObj=nil

local function AttachItems(dpawn)
	if dpawn==nil then return end
	local AtObj = nil
	if dpawn.CurrentlyActiveItem.WeaponMesh~=nil then
		
		AtObj=dpawn.CurrentlyActiveItem.WeaponMesh
		if CurrAttachedObj~=nil and CurrAttachedObj~=AtObj  then
			UEVR_UObjectHook.remove_motion_controller_state(CurrAttachedObj)
		end		
		CurrAttachedObj=AtObj
		UEVR_UObjectHook.get_or_add_motion_controller_state(AtObj):set_hand(1)
		UEVR_UObjectHook.get_or_add_motion_controller_state(AtObj):set_location_offset(Vector3d.new(-8.94,-3.56,0))
		UEVR_UObjectHook.get_or_add_motion_controller_state(AtObj):set_rotation_offset(Vector3d.new(0,math.pi/2,0))
		UEVR_UObjectHook.get_or_add_motion_controller_state(AtObj):set_permanent(true)
	elseif dpawn.CurrentlyActiveItem.SkeletalMesh ~=nil then
		
		AtObj=dpawn.CurrentlyActiveItem.SkeletalMesh
		if CurrAttachedObj~=nil and CurrAttachedObj~=AtObj  then
			UEVR_UObjectHook.remove_motion_controller_state(CurrAttachedObj)
		end		
		
		CurrAttachedObj=AtObj
		UEVR_UObjectHook.get_or_add_motion_controller_state(AtObj):set_hand(1)
		UEVR_UObjectHook.get_or_add_motion_controller_state(AtObj):set_location_offset(Vector3d.new(-8.94,-3.56,0))
		UEVR_UObjectHook.get_or_add_motion_controller_state(AtObj):set_rotation_offset(Vector3d.new(0,0,0))
		UEVR_UObjectHook.get_or_add_motion_controller_state(AtObj):set_permanent(true)
	elseif dpawn.CurrentlyActiveItem.StaticMesh ~=nil then
		
		AtObj=dpawn.CurrentlyActiveItem.StaticMesh
		if CurrAttachedObj~=nil and CurrAttachedObj~=AtObj  then
			UEVR_UObjectHook.remove_motion_controller_state(CurrAttachedObj)
		end		
		print("StaticM")
		CurrAttachedObj=AtObj
		UEVR_UObjectHook.get_or_add_motion_controller_state(AtObj):set_hand(1)
		UEVR_UObjectHook.get_or_add_motion_controller_state(AtObj):set_location_offset(Vector3d.new(0,-3.56,0))
		UEVR_UObjectHook.get_or_add_motion_controller_state(AtObj):set_rotation_offset(Vector3d.new(0,math.pi,0))
		UEVR_UObjectHook.get_or_add_motion_controller_state(AtObj):set_permanent(true)
	end
end

local function AttachFPCAM(dpawn)
	if dpawn~=nil then return end
	local Weapon = nil
	local FPCam = dpawn.FirstPersonCamera
	if dpawn.CurrentWeapon~=nil then
		Weapon=dpawn.CurrentWeapon.WeaponMesh
		FPCam:DetachFromParent(false,false)
		FPCam:K2_AttachTo(Weapon , KismetStringLibrary:Conv_StringToName("Root"), 0,false)
	end
end




uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)

pawn= api:get_local_pawn(0)

AttachItems(pawn)
--AttachFPCAM(pawn)

end)