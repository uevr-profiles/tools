local api = uevr.api
	
	local params = uevr.params
	local callbacks = params.sdk.callbacks
	local pawn = api:get_local_pawn(0)
	local player= api:get_player_controller(0)
	local vr=uevr.params.vr
	local Mesh=nil
	local PrimaryEquipped= true

uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)

	pawn= api:get_local_pawn(0)
	if pawn~=nil then
		PrimaryEquipped = pawn.PrimaryEquipped
		Mesh= pawn.Gun
		if not PrimaryEquipped and  string.find(pawn.SecondaryWeapon:get_full_name(),"Bat")  then
			--UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_hand(1)
			UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_rotation_offset(Vector3f.new(math.pi/180*30,0,0))
		elseif not PrimaryEquipped and  string.find(pawn.SecondaryWeapon:get_full_name(),"Katana")  then
			UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_rotation_offset(Vector3f.new(math.pi/180*30,math.pi/180*90,0))
		else 
			UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_rotation_offset(Vector3f.new(0,0,0))
		end
	end
end)
		--UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_location_offset(lossy_offset)