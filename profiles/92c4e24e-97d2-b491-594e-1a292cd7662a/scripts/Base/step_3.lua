require(".\\Base\\Subsystems\\UEHelperFunctions")
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

local uevrUtils = require("libs/uevr_utils")
uevrUtils.setLogLevel(LogLevel.Debug)
uevrUtils.initUEVR(uevr)
--local flickerFixer = require("libs/flicker_fixer")
local controllers = require("libs/controllers")
local animation = require("libs/animation")
local hands = require("libs/hands")
local handAnimations = require("addons/hand_animations")
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
local handParams = 
{
	Arms = 
	{
		Left = 
		{
			Name = "lowerarm_l", -- Replace this with your findings from Step 1
			Rotation = {0, 90, -90},	-- Replace this with your findings from Step 7
			Location = {4.6, -31.0, -1.0},	-- Replace this with your findings from Step 7
			Scale = {1, 1, 1},			
			AnimationID = "left_hand"
		},
		Right = 
		{
			Name = "nope", -- Replace this with your findings from Step 1
			Rotation = {0, -90, 90},	-- Replace this with your findings from Step 7
			Location = {-5.8, -31.2, 0},	-- Replace this with your findings from Step 7		
			Scale = {1, 1, 1},			
			AnimationID = "right_hand"
		}
	}
}
 local deltaHand=0
local knuckleBoneList = {12, 17, 22, 27, 32, 55, 59, 64, 69, 74} -- Replace this with your findings from Step 2
local glove_mesh=nil
function on_level_change(level)
	print("Level changed\n")
	
	
	--hands.reset()
	deltaHand=0
		
end


local customization_fp_meshes= nil

local HitBox=nil



function on_lazy_poll()
	if pawn~=nil and not string.find(level:get_full_name(), "MainMenu") then
		--customization_fp_meshes = pawn.CustomizationFirstPersonMeshes
		if deltaHand>10 then
		if not hands.exists() then
		
		hands.setOffset({X=0, Y=0, Z=0, Pitch=0, Yaw=-90, Roll=0})	
		
		
			--if customization_fp_meshes ~= nil then
			--	for _, mesh in ipairs(customization_fp_meshes) do
			--		if string.find(mesh:get_full_name(), "Glove")
			--		or string.find(mesh:get_full_name(), "Ironsight")
			--		or string.find(mesh:get_full_name(), "Nomex")
			--		or string.find(mesh:get_full_name(), "Alpha")
			--		or string.find(mesh:get_full_name(), "DETE")
			--		or string.find(mesh:get_full_name(), "Impact")
			--		
			--				then
			--			glove_mesh = mesh
			--		end
			--		
			--		
			--		
			--		
			--	end
			--end	
			glove_mesh = pawn.Inventory_Comp.BP_Gloves.SK_Gloves
			
			
			hands.create(glove_mesh, handParams, handAnimations) --replace pawn.FPVMesh with what you found in Step 1 of step_1.lua		
			
			
		end
		end
	end
	

end
--local isHoldingWeapon = false
function on_xinput_get_state(retval, user_index, state)
	
	if lShoulder and RWeaponZone~=0 then
		isHoldingWeapon=true
	elseif isHoldingWeapon and not lShoulder then
	isHoldingWeapon=false end
	
	
	if hands.exists() then
		hands.handleInput(state, isHoldingWeapon)
	end
	
	
	
end


local isInAnimation=false
local _Comps={}
local function UpdateVisibilityOnAnimation()
	if pawn==nil then return end
	if pawn.Reloading then
		isInAnimation=true
	else isInAnimation=false end
	--local CusActs=pawn.CustomizationActors
	--if hands.getHandComponent(0)~=nil then
	--	--print("test")
	--	 _Comps={}	
	--	HitBox= controllers.getController(0):GetComponentByClass(VHitBoxClass)
	--	HitBox:SetGenerateOverlapEvents(true)
	--	HitBox:SetCollisionResponseToAllChannels(1)
	--	HitBox:SetCollisionObjectType(0)
	--	HitBox:SetCollisionEnabled(1) 
	--	
	--	pawn.InventoryComp.SpawnedGear.Primary.Mag_02_Comp:SetGenerateOverlapEvents(true)
	--	pawn.InventoryComp.SpawnedGear.Primary.Mag_02_Comp:SetCollisionResponseToAllChannels(1)
	--	pawn.InventoryComp.SpawnedGear.Primary.Mag_02_Comp:SetCollisionObjectType(0)
	--	pawn.InventoryComp.SpawnedGear.Primary.Mag_02_Comp:SetCollisionEnabled(1)
	--	HitBox:GetOverlappingComponents(_Comps)
	--	for i, comp in ipairs(_Comps) do
	--		print(comp:get_full_name())
	--	end	
	--end
	if isInAnimation or isHoldingWeapon then
		if glove_mesh ~=nil and hands.getHandComponent(0) ~=nil then
			--if CusActs~=nil then
			--	if pawn.CustomizationActors[1].WatchMesh~=nil then
			--		
			--		UEVR_UObjectHook.remove_motion_controller_state(pawn.CustomizationActors[1].WatchMesh)
			--		pawn.CustomizationActors[1].WatchMesh:SetVisibility(false,false)
			--	end
			--end
			if  pawn.Inventory_Comp.BP_Gloves.SK_Gloves ~=nil then
				 pawn.Mesh:UnHideBoneByName(uevrUtils.fname_from_string("lowerarm_l"))
			end
			hands.getHandComponent(0):SetVisibility(false,false)
		end
	else 	
		if glove_mesh ~=nil and hands.getHandComponent(0) ~=nil then
			
			--if CusActs ~=nil then
			--	if pawn.CustomizationActors[1].WatchMesh~=nil then
			--			pawn.CustomizationActors[1].WatchMesh:SetVisibility(true,false)
			--		UEVR_UObjectHook.get_or_add_motion_controller_state(pawn.CustomizationActors[1].WatchMesh):set_hand(0)
			--		UEVR_UObjectHook.get_or_add_motion_controller_state(pawn.CustomizationActors[1].WatchMesh):set_location_offset(Vector3d.new(5,0,-10))
			--	end
			--end
			hands.getHandComponent(0):SetVisibility(true,false)
			if  pawn.Inventory_Comp~=nil then
			if  pawn.Inventory_Comp.BP_Gloves.SK_Gloves ~=nil then
				
				 pawn.Mesh:HideBoneByName(uevrUtils.fname_from_string("lowerarm_l"))
			end
			end
		end
	end


end


function on_pre_engine_tick(engine, delta)
	UpdateVisibilityOnAnimation()
	
	if pawn~=nil then
		deltaHand=deltaHand + delta
	 end
 --pawn.Mesh:HideBoneByName("lowerarm_l",1)
		
		
		
		
		
end


--register_key_bind("F1", function()
--    print("F1 pressed\n")
--	hands.enableHandAdjustments(knuckleBoneList)
--end)
