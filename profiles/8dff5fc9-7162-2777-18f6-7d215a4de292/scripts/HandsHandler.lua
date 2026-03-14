--[[
	1) At this point you should have hands attached to the correct location on your controller. This step is for
		animating fingers
	2) If you needed the offset in step 5 of step_1.lua then you will need it here as well
	3) If you needed the FOV adjustment in step 6 of step_1.lua then you will need it here as well for both hands
	4) Look at the text file of bone names that you created in step_1.lua. Find the knuckle bones of each finger,
		starting with the left thumb going to the left pinky, then the right thumb to right pinky. The knuckle bones
		will be named like "RightHandThumb1_JNT" or "thumb_01_r" and should be the ones with a "1" in the name for that
		finger. For each knuckle bone, make a note of the index number (the number to the left of the name in your text file)
		Put all the numbers in order from left thumb to left pinky, followed by right thumb to right pinky in 
		the knuckleBoneList on line 58
	5) Run UEVR and press the Spawn Debug Console button. Go into the game your hands should be in the correct location.
		Press F1 and then Number 5 on the number pad until the console says "Adjust Mode Finger Angles". Press Number 7
		until the console indicates the number of the finger you wish to edit. For example, to edit the right index finger, 
		the console should say "Current finger:Right Index finger joint:1". Note that "joint:1" is the knuckle and you can 
		press Number 9 to change to the other bones in the finger.
	6) As you update the fingers you will see the current bone angles displayed in the console window. When you have the
		hands positioned as you want them, you can populate the hand_animations.lua file in the addons directory. In this file
		"off" refers to the open hands angles and "on" refers to the closed hand angles.
	7) Once your hand_animations.lua file is populated, uncomment line 87 and your hands should animate. The animations in
		hand_animations.lua correspond to basic animations supported by the hands.handleInput(state, isHoldingWeapon) function
		in hands.lua. You can, however, create any set of animations you want and call your own function instead of 
		hands.handleInput(state, isHoldingWeapon).
]]--
require(".\\Trackers\\Trackers")
require(".\\Subsystems\\UEHelper")
local api = uevr.api
local params = uevr.params
local callbacks = params.sdk.callbacks
local vr=uevr.params.vr
local uevrUtils = require("libs/uevr_utils")
uevrUtils.setLogLevel(LogLevel.Debug)
uevrUtils.initUEVR(uevr)
local flickerFixer = require("libs/flicker_fixer")
local controllers = require("libs/controllers")
local animation = require("libs/animation")
local hands = require("libs/hands")
  handAnimations = require("addons/hand_animations")


local handParams = 
{
	Arms = 
	{
		Left = 
		{
			Name = "hand_L", -- Replace this with your findings from Step 1
			Rotation = {0, -0, 180},	-- Replace this with your findings from Step 7
			Location = {-4.8, -4.2, -1.2},	-- Replace this with your findings from Step 7
			Scale = {1, 1, 1},			
			AnimationID = "left_hand"
		},
		Right = 
		{
			Name = "hand_R", -- Replace this with your findings from Step 1
			Rotation = {-13, -175, 0},
			Location =  {-8.0, 3.6, -1.0},	-- Replace this with your findings from Step 7		
			Scale = {1, 1, 1},			
			AnimationID = "right_hand"
		}
	}
}


local knuckleBoneList = {28, 16, 19, 22, 25, 49, 37, 40, 43, 46} -- Replace this with your findings from Step 2

function on_level_change(level)
	print("Level changed\n")
	if pawn~=nil then
	--controllers.onLevelChange()
	--controllers.createController(0)
	--controllers.createController(1)
	--controllers.createController(2)
		--update_weapon_offset(pawn.Mesh)
	
	--uevr.params.vr.set_mod_value("VR_AimMethod", "2")
		--vr:recenter_view()
		--Once you have your hand_animations.lua file populated, uncomment the handAnimations on the next line
		--pawn.Mesh.Mobility=0
	
	
		pawn.Mesh.OverrideMaterials[3].Parent.BlendMode=0
		hands.reset()
	end
end

function on_lazy_poll()
	
if pawn~= nil then

	if not hands.exists() then	
		--hands.setOffset({X=0, Y=0, Z=0, Pitch=0, Yaw=90, Roll=0})	
		--uevr.params.vr.set_mod_value("VR_AimMethod", "2")
		--vr:recenter_view()
		--Once you have your hand_animations.lua file populated, uncomment the handAnimations on the next line
		--pawn.Mesh.Mobility=0
		hands.create(pawn.Mesh, handParams, handAnimations) --replace pawn.FPVMesh with what you found in Step 1 of step_1.lua. 
		
	end
	if hands.exists() then
		--uevrUtils.fixMeshFOV(hands.getHandComponent(0), "ForegroundPriorityEnabled", 0.0, true, true, false)
		--uevrUtils.fixMeshFOV(hands.getHandComponent(1), "ForegroundPriorityEnabled", 0.0, true, true, false)
	end
end
end

function on_xinput_get_state(retval, user_index, state)
	local isHoldingWeapon = false
	
	
	if hands.exists() then
		hands.handleInput(state, isHoldingWeapon)
	end
	
end

register_key_bind("F1", function()
    print("F1 pressed\n")
	hands.enableHandAdjustments(knuckleBoneList)
end)
