local api = uevr.api
local params = uevr.params
local callbacks = params.sdk.callbacks
local hidearms = false
CutActive = false

params.vr.set_aim_method(0)
params.vr.recenter_view()

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    
    local pawn = api:get_local_pawn(0)
	local GetPawn = pawn:get_full_name()
	IsCut = tostring(pawn.IsInCutscene)
	--IsCut = tostring(pawn.IsInCutscene)
	--print(IsCut)
	--print(IsCut)
	
	if IsCut == "true" 
	then 
		if CutActive == false then
		print("InCut")
		CutActive = true 
		UEVR_UObjectHook.set_disabled(true)
        params.vr.set_aim_method(0)
        params.vr.recenter_view()
		end
	else
		if CutActive == true then
		print("Not InCut")
		CutActive = false 
		UEVR_UObjectHook.set_disabled(false)
        params.vr.set_aim_method(2)
		end
	end
	
    
	
end)	