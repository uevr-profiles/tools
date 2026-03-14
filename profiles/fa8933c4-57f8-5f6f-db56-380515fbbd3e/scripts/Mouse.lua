require(".\\Subsystems\\UEHelper")
print("init")
local api = uevr.api
local params = uevr.params
local callbacks = params.sdk.callbacks
local vr=uevr.params.vr


local HandVRRot =UEVR_Quaternionf.new()
local HandVRPos =UEVR_Vector3f.new()
local HmdVRRot =UEVR_Quaternionf.new()
local HmdVRPos =UEVR_Vector3f.new()
local HmdRotLast=0
local HmdRotLast=0
local isReset=false

--IntX=kismet_string_library:Conv_StringToInt("1")
--print(IntX)

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)

local player = api:get_player_controller(0)
local Inf_pawn=api:get_local_pawn(0)

if  isMenu and isReset ==false then
	isReset = true
	--vr.recenter_view()
elseif not inMenu and pawn~=nil then isReset=false
end



uevr.params.vr.get_pose(2, HandVRPos, HandVRRot)


local CurrMouseY= -HandVRRot.x* 1440*3
local CurrMouseX= -HandVRRot.y* 2560*2

player:SetMouseLocation(2560/2 + CurrMouseX, 1440*2 + CurrMouseY)


end)