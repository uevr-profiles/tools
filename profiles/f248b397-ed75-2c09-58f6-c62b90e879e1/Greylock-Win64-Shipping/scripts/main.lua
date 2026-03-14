local api = uevr.api
local params = uevr.params
local callbacks = params.sdk.callbacks
local in_menu = false
Mactive = false
Playing = false


uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)

local pcont = api:get_player_controller(0)
local in_menu = pcont.bShowMouseCursor
--print(tostring(in_menu))

if in_menu == true then
	if Mactive == false then
		params.vr.set_aim_method(0)
		params.vr.set_mod_value("VR_DecoupledPitchUIAdjust", "false")
		params.vr.set_mod_value("VR_DecoupledPitch", "false")
		Mactive = true
		Playing = false
		--print("Menu Open")
	end
else
	if Playing == false then
	params.vr.set_aim_method(2)
		params.vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
		params.vr.set_mod_value("VR_DecoupledPitch", "true")
		Mactive = false
		Playing = true
		--print("Playing")
	end
end

end)



uevr.sdk.callbacks.on_script_reset(function()
local in_menu = false
Mactive = false
Playing = false
end)
