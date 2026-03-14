local api = uevr.api
local vr = uevr.params.vr
local pawn_pre
local LastPoseTickTimePre=0
isDriving=false
isMenu=false

local function UpdateDrivingState(pawn_b)
	if string.find(pawn_b:get_fname():to_string(), "Vehicle") then
		isDriving =true
		
	else
		isDriving=false
		
	end
end
local function UpdateMenuState(pawn)
	if pawn:AreAnyMenusOpen()==true then
		isMenu=true
	else isMenu=false
	end
--	print(isMenu)
end



uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)

	
	local pawn_b=api:get_local_pawn(0)
	local player_b=api:get_player_controller(0)
	UpdateDrivingState(pawn_b)
	UpdateMenuState(player_b)
	--print(isDriving)

end)