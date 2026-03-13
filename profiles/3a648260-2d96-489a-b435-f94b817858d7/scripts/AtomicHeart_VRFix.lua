local uevrUtils = require("libs/uevr_utils")
local controllers = require("libs/controllers")
uevrUtils.initUEVR(uevr)

local MOVEMENT_ORIENTATION = "1" -- 1: HMD, 3: Left Controller
local PLAYER_HEIGHT = 80.0 -- Default player height
local TWO_HANDED_MODELS = false -- Disable to hide left hand model with two handed weapons i.e. shotguns, heavy weapons, etc.
local CUTSCENE_LERP = false -- Enable to reduct motion sickness in cutscenes, but camera may sometimes face incorrect directions
local DEV_BUILD = false -- Enable if using developer build of Atomic Heart; Disable for retail Steam release

local api = uevr.api
local vr = uevr.params.vr
local params = uevr.params
local callbacks = params.sdk.callbacks

function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        error("Cannot find " .. name)
        return nil
    end

    return obj
end

local temp_vec3f = Vector3f.new(0, 0, 0)

local bIsRangeWeapon = false
local bIsClimbing = false
local bIsPolymer = false
local bIsNotCutscene = false
local bIsSplash = false
local bIsMouse = false
local bIsMenu = false
local bIsNoraSkills = false
local bIsNoraCrafting = false
local bIsLockPuzzle = false
local bIsPinPuzzle = false
local bIsOneHandedWeapon = false
local bIsLevelLoaded = false
local bIsChargingWeapon = false
local bIsChargingWeaponActive = false
local bIsPickupAnim = false
local bIsReload = false
local bIsReloadOneHand = false
local bIsWhipActive = false
local bIsConsumeItem = false
local bIsDelayWhipActive = false
local bIsSwimming = false
local bIsStunned = false
local bForceAimReset = false
local bForceRebind = false
local bForcePolymer = false
local bIsWorldMap = false
local bIsMainMenu = false
local bIsScanning = false
local bIsCrouched = false
local bAudioFix = false
local bIsAiming = false
local bSetListenerOnetime = false
local bClearListenerOnetime = false
local bGuiToggleOnetime = false
local bGuiToggleEnable = false
local CurrentWeapon = nil
local SkeletalMesh = nil
local FPWeapon = nil
local SwingingFast = nil
local PosResetEn = nil
local AimResetTime = 0
local StunTime = 0
local GuiToggleTime = 0
local SpecialOffsetX = 0
local SpecialOffsetY = 0
local SpecialOffsetZ = 0

local ak47_collimator_scope = false
local ak47_thermal_scope = false
local pm_collimator_scope = false
local pm_thermal_scope = false
local shotgun_collimator_scope = false
local shotgun_thermal_scope = false

local CurrentWeapon_Mesh = nil
local CurrentWeapon_Mesh_RelativeLocation = nil
local CurrentWeapon_Mesh_RelativeScale3D = nil

local Capsule_C = find_required_object("Class /Script/Engine.CapsuleComponent")
local Sphere_C = find_required_object("Class /Script/Engine.SphereComponent")

-------------------------------------------------------------------------------
-- hook_function
--
-- Hooks a UEVR function. 
--
-- class_name = the class to find, such as "Class /Script.GunfireRuntime.RangedWeapon"
-- function_name = the function to Hook
-- native = true or false whether or not to set the native function flag.
-- prefn = the function to run if you hook pre. Pass nil to not use
-- postfn = the function to run if you hook post. Pass nil to not use.
-- dbgout = true to print the debug outputs, false to not
--
-- Example:
--    hook_function("Class /Script/GunfireRuntime.RangedWeapon", "OnFireBegin", true, nil, gun_firingbegin_hook, true)
--
-- Returns: true on success, false on failure.
-------------------------------------------------------------------------------
function hook_function(class_name, function_name, native, prefn, postfn, dbgout)
	if(dbgout) then print("Hook_function for ", class_name, function_name) end
    local result = false
    local class_obj = uevr.api:find_uobject(class_name)
    if(class_obj ~= nil) then
        if dbgout then print("hook_function: found class obj for", class_name) end
        local class_fn = class_obj:find_function(function_name)
        if(class_fn ~= nil) then 
            if dbgout then print("hook_function: found function", function_name, "for", class_name) end
            if (native == true) then
                class_fn:set_function_flags(class_fn:get_function_flags() | 0x400)
                if dbgout then print("hook_function: set native flag") end
            end
            
            class_fn:hook_ptr(prefn, postfn)
            result = true
            if dbgout then print("hook_function: set function hook for", prefn, "and", postfn) end
        end
    end
    
    return result
end

-- Blueprint hooks must be done on level load
function hookLevelFunctions()

	-- Hook functions to toggle aiming back on (for fixing hand mesh angle in VR) after weapon swap detected.  Required as swapping weapons will reset the aim mode state.	
	-- Aiming needs to be forced via a flag that toggles the Aim input.
	-- Setting the Aim Mode via C++/Lua is not practical as different aim modes are required for melee versus ranged weapons. If we hook the Aim function we will not know what aim mode to use as the game sets the aim mode before the weapon mesh is loaded.	
	hook_function("Class /Script/AtomicHeart.AHPlayerController", "ActivatePreviousSlot", true, 
		function(fn, obj, locals, result)
			print("AHPlayerController ActivatePreviousSlot")
			bForceAimReset = true
			AimResetTime = os.clock()
			return true
		end
	, nil, true)

	hook_function("Class /Script/AtomicHeart.AHPlayerController", "ActivateNextSlot", true, 
		function(fn, obj, locals, result)
			print("AHPlayerController ActivateNextSlot")
			bForceAimReset = true
			AimResetTime = os.clock()
			return true
		end
	, nil, true)

	hook_function("Class /Script/AtomicHeart.AHPlayerController", "ActivateSlot0", true, 
		function(fn, obj, locals, result)
			print("AHPlayerController ActivatePreviousSlot")
			bForceAimReset = true
			AimResetTime = os.clock()
			return true
		end
	, nil, true)

	hook_function("Class /Script/AtomicHeart.AHPlayerController", "ActivateSlot1", true, 
		function(fn, obj, locals, result)
			print("AHPlayerController ActivateNextSlot")
			bForceAimReset = true
			AimResetTime = os.clock()
			return true
		end
	, nil, true)

	hook_function("Class /Script/AtomicHeart.AHPlayerController", "ActivateSlot2", true, 
		function(fn, obj, locals, result)
			print("AHPlayerController ActivatePreviousSlot")
			bForceAimReset = true
			AimResetTime = os.clock()
			return true
		end
	, nil, true)

	hook_function("Class /Script/AtomicHeart.AHPlayerController", "ActivateSlot3", true, 
		function(fn, obj, locals, result)
			print("AHPlayerController ActivateNextSlot")
			bForceAimReset = true
			AimResetTime = os.clock()
			return true
		end
	, nil, true)

	hook_function("Class /Script/AtomicHeart.AHPlayerController", "ActivateSlot4", true, 
		function(fn, obj, locals, result)
			print("AHPlayerController ActivatePreviousSlot")
			bForceAimReset = true
			AimResetTime = os.clock()
			return true
		end
	, nil, true)

	hook_function("Class /Script/AtomicHeart.AHPlayerController", "ActivateSlot5", true, 
		function(fn, obj, locals, result)
			print("AHPlayerController ActivateNextSlot")
			bForceAimReset = true
			AimResetTime = os.clock()
			return true
		end
	, nil, true)

	hook_function("Class /Script/AtomicHeart.AHPlayerController", "ActivateSlot6", true, 
		function(fn, obj, locals, result)
			print("AHPlayerController ActivatePreviousSlot")
			bForceAimReset = true
			AimResetTime = os.clock()
			return true
		end
	, nil, true)

	hook_function("Class /Script/AtomicHeart.AHPlayerController", "OnSpecialAbility1ActivationButtonReleased", true, 
		function(fn, obj, locals, result)
			print("Called AHPlayerController OnSpecialAbility1ActivationButtonReleased")
			aim_reset = true
			aim_reset_time = os.clock()
			return true
		end
	, nil, true)
	
	
	
	-- Hook functions to check if World Map is active
	hook_function("WidgetBlueprintGeneratedClass /Game/Core/UI/WorldMap/WorldMapWidgetBP.WorldMapWidgetBP_C", "OnEndOpenMap", true, 
		function(fn, obj, locals, result)
			print("Called WorldMapWidgetBP_C OnEndOpenMap") -- Detect when World Map is active
			bIsWorldMap = true
			return true
		end
	, nil, true)
	
	
	
	-- Hook Scanning functions
	hook_function("Class /Script/AtomicHeart.AHPlayerController", "ScanInputPressed", true, 
		function(fn, obj, locals, result)
			print("Called AHPlayerController ScanInputPressed") -- Detect when scanning starts
			bIsScanning = true 
			return true
		end
	, nil, true)
	
	hook_function("Class /Script/AtomicHeart.AHPlayerController", "ScanInputReleased", true, 
		function(fn, obj, locals, result)
			print("Called AHPlayerController ScanInputReleased") -- Detect when scanning ends
			bIsScanning = false 
			return true
		end
	, nil, true)



	-- Hook Lock and Pin Puzzle functions	
	hook_function("Class /Script/AtomicHeart.UniversalLockPart", "DoneStartAnimation", true, 
		function(fn, obj, locals, result)
			print("Called UniversalLock DoneStartAnimation") -- Detect when Pin Puzzle activated
			bIsPinPuzzle = true
			return true
		end
	, nil, true)
	
	hook_function("AnimBlueprintGeneratedClass /Game/Core/Objects/Interactive/UniversalLock/ABP_UniversalLockHands.ABP_UniversalLockHands_C", "EvaluateGraphExposedInputs_ExecuteUbergraph_ABP_UniversalLockHands_AnimGraphNode_TransitionResult_6A140598408B8EC5FC7F07A0567F7DF8", true, 
		function(fn, obj, locals, result)
			print("Called ABP_UniversalLockHands_C AnimGraphNode_TransitionResult_6A140598408B8EC5FC7F07A0567F7DF8")
			bIsPinPuzzle = true -- Detect when alternate Pin Puzzle activated
			return true
		end
	, nil, true)	
	
	hook_function("Class /Script/AtomicHeart.UniversalLock", "ExitAnimationSetup", true, 
		function(fn, obj, locals, result)
			print("Called UniversalLock ExitAnimationSetup") -- Detect when Pin Puzzle exited
			bIsPinPuzzle = false
			return true
		end
	, nil, true)
	
	hook_function("BlueprintGeneratedClass /Game/Core/AbilitySystem/Abilities/GA_Lockpick.GA_Lockpick_C", "K2_CommitExecute", true, 
		function(fn, obj, locals, result)
			print("Called GA_Lockpick_C K2_CommitExecute") -- Detect when Lock Puzzle entered
			bIsLockPuzzle = true
			bIsPolymer = true
			return true
		end
	, nil, true)
	
	hook_function("BlueprintGeneratedClass /Game/Core/LockPicking/Blueprints/BP_MechanicalLock.BP_MechanicalLock_C", "ExitEvent", true, 
		function(fn, obj, locals, result)
			print("Called BP_MechanicalLock_C ExitEvent") -- Detect when Lock Puzzle exited
			bIsLockPuzzle = false
			bIsPolymer = false
			return true
		end
	, nil, true)
	
	hook_function("BlueprintGeneratedClass /Game/Core/LockPicking/Blueprints/BP_MechanicalLock.BP_MechanicalLock_C", "DoneExitEvent", true, 
		function(fn, obj, locals, result)
			print("Called BP_MechanicalLock_C ExitEvent") -- Detect when Lock Puzzle completed
			bIsLockPuzzle = false
			bIsPolymer = false
			return true
		end
	, nil, true)	
	
	hook_function("Class /Script/AtomicHeart.AHBaseCharacter", "ProcessIncomingDamage", true, 
		function(fn, obj, locals, result)
			print("Called AHBaseCharacter ProcessIncomingDamage") -- Detect when game state altered from taking damage
			bIsLockPuzzle = false
			bIsPolymer = false
			bIsNoraCrafting = false
			bIsNoraSkills = false
			return true
		end
	, nil, true)

	

	-- Hook function to detect when Nora is active
	hook_function("WidgetBlueprintGeneratedClass /Game/Core/UI/Widgets/CraftMenu/CraftWindow/WBP_CraftWindowMain.WBP_CraftWindowMain_C", "Construct", true, 
		function(fn, obj, locals, result)
			print("Called WBP_CraftWindowMain_C Construct") -- Detect Nora Crafting window initialized, do not use Nora Skills detection flag as Crafting window does not need camera adjustments
			bIsNoraCrafting = true 
			return true
		end
	, nil, true)
	
	hook_function("WidgetBlueprintGeneratedClass /Game/Core/UI/Widgets/CraftMenu/CraftWindow/WBP_CraftWindowMain.WBP_CraftWindowMain_C", "Destruct", true, 
		function(fn, obj, locals, result)
			print("Called WBP_CraftWindowMain_C Destruct") -- Detect Nora Crafting window closed
			bIsNoraCrafting = false 
			return true
		end
	, nil, true)
	
	hook_function("Class /Script/AtomicHeart.AHCraftMachine", "InitSkillTree", true, 
		function(fn, obj, locals, result)
			print("Called AHCraftMachine InitSkillTree") -- Detect when Nora Skills window initialized
			bIsNoraSkills = true
			return true
		end
	, nil, true)
		
	hook_function("Class /Script/AtomicHeart.CraftWindowMainWidget", "SwitchToSkills", true, 
		function(fn, obj, locals, result)
			print("CraftWindowMainWidget SwitchToSkills") -- Detect when Nora switches to Skills window	
			bIsNoraSkills = true
			bIsNoraCrafting = false
			return true
		end
	, nil, true)

	hook_function("Class /Script/AtomicHeart.SkillTreeMenuWidget", "SwitchToCraftWindow", true, 
		function(fn, obj, locals, result)
			print("SkillTreeMenuWidget SwitchToCraftWindow") -- Detect when Nora switches to Crafting window	
			bIsNoraSkills = false
			bIsNoraCrafting = true
			return true
		end
	, nil, true)

	hook_function("WidgetBlueprintGeneratedClass /Game/Core/UI/Widgets/CraftMenu/CraftWindow/WBP_CraftItem.WBP_CraftItem_C", "OnCraftProgressIsDone", true, 
		function(fn, obj, locals, result)
			print("Called WBP_CraftItem_C OnCraftProgressIsDone") -- Detect when Crafting window is closed
			bIsNoraCrafting = false
			return true
		end
	, nil, true)

	hook_function("BlueprintGeneratedClass /Game/Core/Objects/Interactive/CraftMachine/BP_Base_CraftMachine.BP_Base_CraftMachine_C", "K2_OnWidgetClose", true, 
		function(fn, obj, locals, result)
			print("Called BP_Base_CraftMachine_C K2_OnWidgetClose") -- Detect when Crafting window is closed
			bIsNoraCrafting = false
			return true
		end
	, nil, true)	



	-- Hook functions to detect Menu state	
	hook_function("Class /Script/AtomicHeart.InGameMenuWidget", "OpenSubMenu", true, 
		function(fn, obj, locals, result)
			print("Called InGameMenuWidget OpenSubMenu") -- Detect when menu is active
			bIsMenu = true
			return true
		end
	, nil, true)

	hook_function("Class /Script/AtomicHeart.PlayerInventoryWidget", "OnTryToUseItem", true, 
		function(fn, obj, locals, result)
			print("Called PlayerInventoryWidget OnTryToUseItem") -- Detect when menu exited from using inventory item
			bIsMenu = false
			return true
		end
	, nil, true)
		
	hook_function("WidgetBlueprintGeneratedClass /Game/Core/UI/WBP_InGameMenu.WBP_InGameMenu_C", "Destruct", true, 
		function(fn, obj, locals, result)
			print("Called WBP_InGameMenu_C Destruct") -- Detect when menu is closed
			bIsMenu = false
			return true
		end
	, nil, true)
	
	hook_function("WidgetBlueprintGeneratedClass /Game/Core/UI/Widgets/MainMenu/WBP_MainMenu.WBP_MainMenu_C", "Construct", true, 
		function(fn, obj, locals, result)
			print("Called WBP_MainMenu_C Construct") -- Detect when main menu is open
			bIsMainMenu = true
			return true
		end
	, nil, true)
	
	hook_function("Class /Script/AtomicHeart.MainMenuWidget", "OnClosed", true, 
		function(fn, obj, locals, result)
			print("Called MainMenuWidget OnClosed") -- Detect when main menu is closed
			bIsMainMenu = false
			return true
		end
	, nil, true)
	
	

	-- FORCE POWERS HOOKS --
	-- Left Hand meshes require unique offsets for 6DOF motion controls depending on which force power is active --
	
	-- GRAB --
	hook_function("BlueprintGeneratedClass /Game/Core/AbilitySystem/Abilities/GA_Grab.GA_Grab_C", "K2_CommitExecute", true, 
		function(fn, obj, locals, result)
			print("Called GA_Grab_C K2_CommitExecute")	
			SpecialOffsetX = -11
			
			if bIsRangeWeapon == true then
				SpecialOffsetY = 0
				SpecialOffsetZ = -10
			else
				SpecialOffsetY = 10
				SpecialOffsetZ = 0
			end				

			
			return true
		end
	, nil, true)

	hook_function("Class /Script/AtomicHeart.AHPlayerController", "DropGrabbedObjectPressed", true, 
		function(fn, obj, locals, result)
			print("Called AHPlayerController DropGrabbedObjectPressed")
			SpecialOffsetX = 0
			SpecialOffsetY = 0
			SpecialOffsetZ = 0
			return true
		end
	, nil, true)

	-- SHOK --
	hook_function("BlueprintGeneratedClass /Game/Core/AbilitySystem/Cues/GCA_Shocker.GCA_Shocker_C", "K2_SpawnEmptyActivationFX", true, 
		function(fn, obj, locals, result)
			print("Called GCA_Shocker_C K2_SpawnEmptyActivationFX")
			SpecialOffsetX = 0
			SpecialOffsetY = 5
			SpecialOffsetZ = -5
			return true
		end
	, nil, true)

	-- FROSTBITE --
	hook_function("BlueprintGeneratedClass /Game/Core/AnimNotifiers/AnimNotify_PlayerFingers_frost.AnimNotify_PlayerFingers_frost_C", "Received_NotifyTick", true, 
		function(fn, obj, locals, result)
			print("Called AnimNotify_PlayerFingers_frost_C Received_NotifyTick")
			SpecialOffsetX = -5
			SpecialOffsetY = 0
			SpecialOffsetZ = -15	
			return true
		end
	, nil, true)

	hook_function("BlueprintGeneratedClass /Game/Core/AbilitySystem/Abilities/GA_FreezeRay.GA_FreezeRay_C", "ShouldUseAlternativeFreezingStreamFX", true, 
		function(fn, obj, locals, result)
			print("Called GA_FreezeRay_C ShouldUseAlternativeFreezingStreamFX")
			SpecialOffsetX = -5
			SpecialOffsetY = 0
			SpecialOffsetZ = -15
			return true
		end
	, nil, true)

	hook_function("BlueprintGeneratedClass /Game/Core/AbilitySystem/Cues/GCA_AlternativeCostFreezeRay.GCA_AlternativeCostFreezeRay_C", "AlternativeCostFXEnd", true, 
		function(fn, obj, locals, result)
			print("Called GCA_AlternativeCostFreezeRay_C AlternativeCostFXEnd")
			SpecialOffsetX = 0
			SpecialOffsetY = 0
			SpecialOffsetZ = 0
			return true
		end
	, nil, true)

	-- MASS TELEKENESIS --
	hook_function("BlueprintGeneratedClass /Game/Core/AbilitySystem/Cues/GCA_TelekineticSmash.GCA_TelekineticSmash_C", "K2_OnTakeOff", true, 
		function(fn, obj, locals, result)
			print("Called GCA_TelekineticSmash_C K2_OnTakeOff")
			SpecialOffsetX = 0
			SpecialOffsetY = 17
			SpecialOffsetZ = 0
			return true
		end
	, nil, true)

	hook_function("BlueprintGeneratedClass /Game/Core/AbilitySystem/Abilities/AI/GA_TelekineticSmashAI.GA_TelekineticSmashAI_C", "K2_OnEndAbility", true, 
		function(fn, obj, locals, result)
			print("Called GA_TelekineticSmashAI_C K2_OnEndAbility")
			SpecialOffsetX = 0
			SpecialOffsetY = 0
			SpecialOffsetZ = 0
			return true
		end
	, nil, true)

	-- POLYMERIC SHIELD --
	hook_function("BlueprintGeneratedClass /Game/Core/Objects/Polymer/Shield/BP_PolymerShield.BP_PolymerShield_C", "ReceiveBeginPlay", true, 
		function(fn, obj, locals, result)
			print("Called BP_PolymerShield_C ReceiveBeginPlay")
			SpecialOffsetX = 0
			SpecialOffsetY = 0
			SpecialOffsetZ = 0
			return true
		end
	, nil, true)

	hook_function("BlueprintGeneratedClass /Game/Core/Objects/Polymer/Shield/BP_PolymerShield.BP_PolymerShield_C", "ReceiveEndPlay", true, 
		function(fn, obj, locals, result)
			print("Called BP_PolymerShield_C ReceiveEndPlay")
			SpecialOffsetX = 0
			SpecialOffsetY = 0
			SpecialOffsetZ = 0
			return true
		end
	, nil, true)

	-- POLYMERIC JET --
	hook_function("BlueprintGeneratedClass /Game/Core/Weapons/Bombs/BP_ExplosivePolymerBomb.BP_ExplosivePolymerBomb_C", "ReceiveBeginPlay", true, 
		function(fn, obj, locals, result)
			print("Called BP_ExplosivePolymerBomb_C ReceiveBeginPlay")
			SpecialOffsetX = -7
			SpecialOffsetY = 0
			SpecialOffsetZ = -10
			return true
		end
	, nil, true)
	
end

-- Prevent the game from applying dynamic offsets to hand meshes.  This prevents weapons from having a floaty feeling and being positioned incorrectly with 6DOF motion control attachments.
--
-- This also mitigates gun wobble but additional animation Blueprint PAK modding is required to fully implement Smooth Locomotion.
-- For Smooth Locomotion, we can PAK mod the weapon animations with idle animations.  We can swap animations by switching the animation files in Windows Explorer and updating the .uasset filenames under UAssetGui > Name Map 
-- For example, if we replace AS_PlayerCharacterHands_AK_IdleAimNew with AS_PlayerCharacterHands_AK_Idle, we must open AS_PlayerCharacterHands_AK_Idle in UAssetGui and update the filename records under Name Map to AS_PlayerCharacterHands_AK_IdleAimNew.
-- Note that we must swap firing animations with idle animations for the Electro Gun and Dominator as these are special weapons which need additional animation edits.
-- The following animations must be swapped for smooth locomotion:
--
-- Replace the following with AS_PlayerCharacterHands_AK_Idle: AS_PlayerCharacterHands_AK_IdleAimNew, AS_PlayerCharacterHands_AK_IdleSprintLoop, AS_PlayerCharacterHands_AK_WalkAimF, AS_PlayerCharacterHands_AK_WalkF
-- Replace the following with AS_PlayerCharacterHands_Arms_Idle: AS_PlayerCharacterHands_Arms_Sprint, AS_PlayerCharacterHands_Arms_WalkF
-- Replace the following with AS_PlayerCharacterHands_Bidonist_Idle: AS_PlayerCharacterHands_Bidonist_Sprint, AS_PlayerCharacterHands_Bidonist_WalkB, AS_PlayerCharacterHands_Bidonist_WalkF, AS_PlayerCharacterHands_Bidonist_WalkL, AS_PlayerCharacterHands_Bidonist_WalkR
-- Replace the following with AS_PlayerCharacterHands_Dominator_Idle: AC_PlayerCharacterHands_Dominator_Sprint, AS_PlayerCharacterHands_Dominator_IdleAim, AS_PlayerCharacterHands_Dominator_Shot01
--                                                                    AS_PlayerCharacterHands_Dominator_Sprint_New, AS_PlayerCharacterHands_Dominator_Super_Charge, AS_PlayerCharacterHands_Dominator_Super_Loop, AS_PlayerCharacterHands_Dominator_Super_Shot, AS_PlayerCharacterHands_Dominator_WalkF, AS_PlayerCharacterHands_Dominator_WalkFAim
-- Replace the following with AS_PlayerCharacterHands_Electrogun_Idle: AS_PlayerCharacterHands_Electrogun_AimIdle, AS_PlayerCharacterHands_Electrogun_AimWalkF, AS_PlayerCharacterHands_Electrogun_Idle, AS_PlayerCharacterHands_Electrogun_Shot01, AS_PlayerCharacterHands_Electrogun_Sprint, AS_PlayerCharacterHands_Electrogun_WalkF
-- Replace the following with AS_PlayerCharacterHands_Flamethrower_Idle: AS_PlayerCharacterHands_Flamethrower_Sprint, AS_PlayerCharacterHands_Flamethrower_WalkB, AS_PlayerCharacterHands_Flamethrower_WalkF, AS_PlayerCharacterHands_Flamethrower_WalkL, AS_PlayerCharacterHands_Flamethrower_WalkR
-- Replace the following with AS_PlayerCharacterHands_Kilka_Idle: AS_PlayerCharacterHands_Kilka_Sprint, AS_PlayerCharacterHands_Kilka_WalkF
-- Replace the following with AS_PlayerCharacterHands_Krepysh_Idle01: AS_PlayerCharacterHands_Krepysh_AimIdle, AS_PlayerCharacterHands_Krepysh_AimIdlePos, AS_PlayerCharacterHands_Krepysh_AimWalkB, AS_PlayerCharacterHands_Krepysh_AimWalkF, AS_PlayerCharacterHands_Krepysh_AimWalkL, AS_PlayerCharacterHands_Krepysh_AimWalkR, 
--                                                                    AS_PlayerCharacterHands_Krepysh_Idle_to_UltimateIdle, AS_PlayerCharacterHands_Krepysh_Idle02, AS_PlayerCharacterHands_Krepysh_IdlePos, AS_PlayerCharacterHands_Krepysh_Sprint, AS_PlayerCharacterHands_Krepysh_SprintOffsetC, AS_PlayerCharacterHands_Krepysh_SprintOffsetD,
--                                                                    AS_PlayerCharacterHands_Krepysh_SprintOffsetL, AS_PlayerCharacterHands_Krepysh_SprintOffsetR, AS_PlayerCharacterHands_Krepysh_SprintOffsetU, AS_PlayerCharacterHands_Krepysh_UltimateIdle, AS_PlayerCharacterHands_Krepysh_UltimateSprint, 
--                                                                    AS_PlayerCharacterHands_Krepysh_UltimateWalkB, AS_PlayerCharacterHands_Krepysh_UltimateWalkF, AS_PlayerCharacterHands_Krepysh_UltimateWalkL, AS_PlayerCharacterHands_Krepysh_UltimateWalkR, AS_PlayerCharacterHands_Krepysh_WalkB, AS_PlayerCharacterHands_Krepysh_WalkF,
--                                                                    AS_PlayerCharacterHands_Krepysh_WalkL, AS_PlayerCharacterHands_Krepysh_WalkR
-- Replace the following with AS_PlayerCharacterHands_Lisa_Idle: AS_PlayerCharacterHands_Lisa_IdlePos, AS_PlayerCharacterHands_Lisa_SprintLoop, AS_PlayerCharacterHands_Lisa_WalkF
-- Replace the following with AS_PlayerCharacterHands_PM_Idle: AS_PlayerCharacterHands_PM_IdleAim, AS_PlayerCharacterHands_PM_IdleSprintLoop, AS_PlayerCharacterHands_PM_WalkF, AS_PlayerCharacterHands_PM_WalkFAim
-- Replace the following with AS_PlayerCharacterHands_RailgunIdle: AC_PlayerCharacterHands_RailgunSprint, AC_PlayerCharacterHands_RailgunWalkAim, AS_PlayerCharacterHands_RailgunIdleAim, AS_PlayerCharacterHands_RailgunSprint, AS_PlayerCharacterHands_RailgunWalkF     
-- Replace the following with AS_PlayerCharacterHands_ShotgunKS23_Idle: AS_PlayerCharacterHands_ShotgunKS23_AimIdle, AS_PlayerCharacterHands_ShotgunKS23_AimWalkF, AS_PlayerCharacterHands_ShotgunKS23_IdleSprintLoop, AS_PlayerCharacterHands_ShotgunKS23_WalkF
-- Replace the following with AS_PlayerCharacterHands_ShotgunKuzmich_Idle: AS_PlayerCharacterHands_ShotgunKuzmich_AimIdle, AS_PlayerCharacterHands_ShotgunKuzmich_AimWalkF, AS_PlayerCharacterHands_ShotgunKuzmich_Sprint, AS_PlayerCharacterHands_ShotgunKuzmich_WalkB, AS_PlayerCharacterHands_ShotgunKuzmich_WalkF,  
--                                                                         AS_PlayerCharacterHands_ShotgunKuzmich_WalkL, AS_PlayerCharacterHands_ShotgunKuzmich_WalkR
-- Replace the following with AS_PlayerCharacterHands_Shprits_Idle: AS_PlayerCharacterHands_Shprits_AimIdle, AS_PlayerCharacterHands_Shprits_AimWalkB, AS_PlayerCharacterHands_Shprits_AimWalkF, AS_PlayerCharacterHands_Shprits_AimWalkL, AS_PlayerCharacterHands_Shprits_AimWalkR, AS_PlayerCharacterHands_Shprits_Sprint,        
-- 																	AS_PlayerCharacterHands_Shprits_WalkB, AS_PlayerCharacterHands_Shprits_WalkF, AS_PlayerCharacterHands_Shprits_WalkL, AS_PlayerCharacterHands_Shprits_WalkR
-- Replace the following with AS_PlayerCharacterHands_ZvezdochkaIdle: AC_PlayerCharacterHands_ZvezdochkaSprint, AS_PlayerCharacterHands_ZvezdochkaIdleAngleOffsetC, AS_PlayerCharacterHands_ZvezdochkaIdleAngleOffsetD, AS_PlayerCharacterHands_ZvezdochkaIdleAngleOffsetL, AS_PlayerCharacterHands_ZvezdochkaIdleAngleOffsetR,
--                                                                    AS_PlayerCharacterHands_ZvezdochkaIdleAngleOffsetU, AS_PlayerCharacterHands_ZvezdochkaSprint, AS_PlayerCharacterHands_ZvezdochkaSprintOffsetCPlaceholder, AS_PlayerCharacterHands_ZvezdochkaSprintOffsetD, AS_PlayerCharacterHands_ZvezdochkaSprintOffsetL,
--                                                                    AS_PlayerCharacterHands_ZvezdochkaSprintOffsetR, AS_PlayerCharacterHands_ZvezdochkaSprintOffsetU, AS_PlayerCharacterHands_ZvezdochkaWalkF   
-- Replace the following with AS_PlayerCharacterHands_Gromoverzec_Idle: AS_PlayerCharacterHands_Gromoverzec_Sprint, AS_PlayerCharacterHands_Gromoverzec_WalkF
-- Replace the following with AS_PlayerCharacterHands_Kuzmich_Idle: AS_PlayerCharacterHands_Kuzmich_IdleAim, AS_PlayerCharacterHands_Kuzmich_Sprint, AS_PlayerCharacterHands_Kuzmich_WalkAimF, AS_PlayerCharacterHands_Kuzmich_WalkF        
   
function ResetMeshOffsets()

	local pawn = api:get_local_pawn()
	if pawn ~= nil then
	
		local mesh = pawn.Mesh
		local player_anim_instance = mesh.AnimScriptInstance		

		if player_anim_instance ~= nil then
			local CurrentOffsetSettings = player_anim_instance.CurrentOffsetSettings
			
			if player_anim_instance.CurrentWeapon ~= nil then	
				local CurrentWeapon = player_anim_instance.CurrentWeapon				
				local OffsetSettings = CurrentWeapon.OffsetSettings
				local AttackBlockedOffset = OffsetSettings.AttackBlockedOffset
				local AttackBlockedOffset_Rotation = AttackBlockedOffset.Rotation
				local AttackBlockedOffset_Translation = AttackBlockedOffset.Translation
				local CrouchAdditionalRotationOffset = OffsetSettings.CrouchAdditionalRotationOffset
				local CrouchAdditionalTranslationOffset = OffsetSettings.CrouchAdditionalTranslationOffset
				local ObstacleOffset = OffsetSettings.ObstacleOffset
				local ObstacleOffset_Offset = ObstacleOffset.Offset
				local ObstacleOffset_Offset_Rotation = ObstacleOffset_Offset.Rotation
				local ObstacleOffset_Offset_Translation = ObstacleOffset_Offset.Translation
				
				local SprintOffset = OffsetSettings.SprintOffset
				local SprintOffset_Rotation = SprintOffset.Rotation
				local SprintOffset_Translation = SprintOffset.Translation
				
				OffsetSettings.AimForwardOffsetDependingOnPlayerForwardVelocity = 0
				OffsetSettings.AimHorizontalOffsetDependingOnPlayerHorizontalCameraMovement = 0
				OffsetSettings.AimHorizontalOffsetDependingOnPlayerHorizontalVelocity = 0
				OffsetSettings.AimTiltDependingOnPlayerVerticalCameraMovement = 0
				OffsetSettings.AimTurnDependingOnPlayerHorizontalCameraMovement = 0
				OffsetSettings.AimTwistDependingOnPlayerSideVelocity = 0
				OffsetSettings.AimTwistDependingOnPlayerVerticalCameraMovement = 0
				OffsetSettings.AimVerticalOffsetDependingOnPlayerVerticalCameraMovement = 0
				OffsetSettings.AimVerticalOffsetDependingOnPlayerVerticalVelocity = 0
				
				AttackBlockedOffset_Rotation.Pitch = 0
				AttackBlockedOffset_Rotation.Roll = 0
				AttackBlockedOffset_Rotation.Yaw = 0
				AttackBlockedOffset_Translation.Pitch = 0
				AttackBlockedOffset_Translation.Roll = 0
				AttackBlockedOffset_Translation.Yaw = 0
				
				OffsetSettings.AttackBlockedOffsetsInterpolationSpeed = 0
				
				CrouchAdditionalRotationOffset.Pitch = 0
				CrouchAdditionalRotationOffset.Roll = 0
				CrouchAdditionalRotationOffset.Yaw = 0
				CrouchAdditionalTranslationOffset.X = 0
				CrouchAdditionalTranslationOffset.Y = 0
				CrouchAdditionalTranslationOffset.Z = 0
								
				OffsetSettings.ForwardOffsetDependingOnPlayerForwardVelocity = 0
				OffsetSettings.HorizontalOffsetDependingOnPlayerHorizontalCameraMovement = 0
				OffsetSettings.HorizontalOffsetDependingOnPlayerHorizontalVelocity = 0
				OffsetSettings.MeleeWeaponAttackSkillOffsetAlpha = 0
				
				ObstacleOffset.Distance = 0
				ObstacleOffset.InterpolationSpeed = 0
				ObstacleOffset_Offset_Rotation.Pitch  = 0
				ObstacleOffset_Offset_Rotation.Roll = 0
				ObstacleOffset_Offset_Rotation.Yaw  = 0
				ObstacleOffset_Offset_Translation.X = 0
				ObstacleOffset_Offset_Translation.Y = 0
				ObstacleOffset_Offset_Translation.Z = 0
				
				OffsetSettings.ObstacleOffsetOffsetInterpolationSpeed = 0
				OffsetSettings.OffsetDisabledInterpolationSpeed = 0
				
				OffsetSettings.PitchSlopeMultiplier = 0
				
				OffsetSettings.SkillOffsetsInterpolationSpeed = 0
				
				SprintOffset_Rotation.Pitch = 0
				SprintOffset_Rotation.Roll = 0
				SprintOffset_Rotation.Yaw = 0
				SprintOffset_Translation.Z = 0
				SprintOffset_Translation.Y = 0
				SprintOffset_Translation.Z = 0
				
				OffsetSettings.SprintOffsetInterpolationSpeed = 0
				OffsetSettings.TiltDependingOnPlayerVerticalCameraMovement = 0
				OffsetSettings.TurnDependingOnPlayerHorizontalCameraMovement = 0
				OffsetSettings.TwistDependingOnPlayerSideVelocity = 0
				OffsetSettings.TwistDependingOnPlayerVerticalCameraMovement = 0
				
				OffsetSettings.VelocityInterpolationSpeed = 0
				OffsetSettings.VerticalOffsetDependingOnPlayerVerticalCameraMovement = 0
				OffsetSettings.VerticalOffsetDependingOnPlayerVerticalVelocity = 0
				OffsetSettings.YRotationInterpolationSpeed = 0
				OffsetSettings.ZRotationInterpolationSpeed = 0				
			end		

			local DefaultHandOffsets = player_anim_instance.DefaultHandOffsets

			local AttackBlockedOffset = DefaultHandOffsets.AttackBlockedOffset
			local AttackBlockedOffset_Rotation = AttackBlockedOffset.Rotation
			local AttackBlockedOffset_Translation = AttackBlockedOffset.Translation
			local CrouchAdditionalRotationOffset = DefaultHandOffsets.CrouchAdditionalRotationOffset
			local CrouchAdditionalTranslationOffset = DefaultHandOffsets.CrouchAdditionalTranslationOffset
			local ObstacleOffset = DefaultHandOffsets.ObstacleOffset
			local ObstacleOffset_Offset = ObstacleOffset.Offset
			local ObstacleOffset_Offset_Rotation = ObstacleOffset_Offset.Rotation
			local ObstacleOffset_Offset_Translation = ObstacleOffset_Offset.Translation
				
			local SprintOffset = DefaultHandOffsets.SprintOffset
			local SprintOffset_Rotation = SprintOffset.Rotation
			local SprintOffset_Translation = SprintOffset.Translation
				
			DefaultHandOffsets.AimForwardOffsetDependingOnPlayerForwardVelocity = 0
			DefaultHandOffsets.AimHorizontalOffsetDependingOnPlayerHorizontalCameraMovement = 0
			DefaultHandOffsets.AimHorizontalOffsetDependingOnPlayerHorizontalVelocity = 0
			DefaultHandOffsets.AimTiltDependingOnPlayerVerticalCameraMovement = 0
			DefaultHandOffsets.AimTurnDependingOnPlayerHorizontalCameraMovement = 0
			DefaultHandOffsets.AimTwistDependingOnPlayerSideVelocity = 0
			DefaultHandOffsets.AimTwistDependingOnPlayerVerticalCameraMovement = 0
			DefaultHandOffsets.AimVerticalOffsetDependingOnPlayerVerticalCameraMovement = 0
			DefaultHandOffsets.AimVerticalOffsetDependingOnPlayerVerticalVelocity = 0
				
			AttackBlockedOffset_Rotation.Pitch = 0
			AttackBlockedOffset_Rotation.Roll = 0
			AttackBlockedOffset_Rotation.Yaw = 0
			AttackBlockedOffset_Translation.Pitch = 0
			AttackBlockedOffset_Translation.Roll = 0
			AttackBlockedOffset_Translation.Yaw = 0
				
			DefaultHandOffsets.AttackBlockedOffsetsInterpolationSpeed = 0
				
			CrouchAdditionalRotationOffset.Pitch = 0
			CrouchAdditionalRotationOffset.Roll = 0
			CrouchAdditionalRotationOffset.Yaw = 0
			CrouchAdditionalTranslationOffset.X = 0
			CrouchAdditionalTranslationOffset.Y = 0
			CrouchAdditionalTranslationOffset.Z = 0
								
			DefaultHandOffsets.ForwardOffsetDependingOnPlayerForwardVelocity = 0
			DefaultHandOffsets.HorizontalOffsetDependingOnPlayerHorizontalCameraMovement = 0
			DefaultHandOffsets.HorizontalOffsetDependingOnPlayerHorizontalVelocity = 0
			DefaultHandOffsets.MeleeWeaponAttackSkillOffsetAlpha = 0
				
			ObstacleOffset.Distance = 0
			ObstacleOffset.InterpolationSpeed = 0
			ObstacleOffset_Offset_Rotation.Pitch  = 0
			ObstacleOffset_Offset_Rotation.Roll = 0
			ObstacleOffset_Offset_Rotation.Yaw  = 0
			ObstacleOffset_Offset_Translation.X = 0
			ObstacleOffset_Offset_Translation.Y = 0
			ObstacleOffset_Offset_Translation.Z = 0
				
			DefaultHandOffsets.ObstacleOffsetOffsetInterpolationSpeed = 0
			DefaultHandOffsets.OffsetDisabledInterpolationSpeed = 0
				
			DefaultHandOffsets.PitchSlopeMultiplier = 0
				
			DefaultHandOffsets.SkillOffsetsInterpolationSpeed = 0
				
			SprintOffset_Rotation.Pitch = 0
			SprintOffset_Rotation.Roll = 0
			SprintOffset_Rotation.Yaw = 0
			SprintOffset_Translation.X = 0
			SprintOffset_Translation.Y = 0
			SprintOffset_Translation.Z = 0
				
			DefaultHandOffsets.SprintOffsetInterpolationSpeed = 0
			DefaultHandOffsets.TiltDependingOnPlayerVerticalCameraMovement = 0
			DefaultHandOffsets.TurnDependingOnPlayerHorizontalCameraMovement = 0
			DefaultHandOffsets.TwistDependingOnPlayerSideVelocity = 0
			DefaultHandOffsets.TwistDependingOnPlayerVerticalCameraMovement = 0
				
			DefaultHandOffsets.VelocityInterpolationSpeed = 0
			DefaultHandOffsets.VerticalOffsetDependingOnPlayerVerticalCameraMovement = 0
			DefaultHandOffsets.VerticalOffsetDependingOnPlayerVerticalVelocity = 0
			DefaultHandOffsets.YRotationInterpolationSpeed = 0
			DefaultHandOffsets.ZRotationInterpolationSpeed = 0		
		end
	end
end

local melee_data = {
    right_hand_pos_raw = UEVR_Vector3f.new(),
    right_hand_q_raw = UEVR_Quaternionf.new(),
    right_hand_pos = Vector3f.new(0, 0, 0),
    last_right_hand_raw_pos = Vector3f.new(0, 0, 0),
    last_time_messed_with_attack_request = 0.0,
    first = true,
}

uevr.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
    local pawn = api:get_local_pawn()

    if pawn == nil then
        return
    end
	
	local pawn_pos = nil
	
	pawn_pos = pawn.RootComponent:K2_GetComponentLocation()

	if bIsPinPuzzle == false and bIsLockPuzzle == false and bIsWorldMap == false and bIsNotCutscene == true or DEV_BUILD == true then 
		-- Attach camera to pawn during normal gameplay to prevent player from flying outside the map
		position.x = pawn_pos.x
		position.y = pawn_pos.y
		
		if bIsNoraSkills == true then 
			position.z = pawn_pos.z + 80.0	-- Adjust player height when using Nora
		else
			position.z = pawn_pos.z + PLAYER_HEIGHT	
		end
	end
	
end)

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)

    vr.get_pose(vr.get_right_controller_index(), melee_data.right_hand_pos_raw, melee_data.right_hand_q_raw)

    -- Copy without creating new userdata
    melee_data.right_hand_pos:set(melee_data.right_hand_pos_raw.x, melee_data.right_hand_pos_raw.y, melee_data.right_hand_pos_raw.z)

    if melee_data.first then
        melee_data.last_right_hand_raw_pos:set(melee_data.right_hand_pos.x, melee_data.right_hand_pos.y, melee_data.right_hand_pos.z)
        melee_data.first = false
    end

    local velocity = (melee_data.right_hand_pos - melee_data.last_right_hand_raw_pos) * (1 / delta)

    -- Clone without creating new userdata
    melee_data.last_right_hand_raw_pos.x = melee_data.right_hand_pos_raw.x
    melee_data.last_right_hand_raw_pos.y = melee_data.right_hand_pos_raw.y
    melee_data.last_right_hand_raw_pos.z = melee_data.right_hand_pos_raw.z
    melee_data.last_time_messed_with_attack_request = melee_data.last_time_messed_with_attack_request + delta
	
	local vel_len = velocity:length()
    
	if velocity.y < 0 then
		SwingingFast = vel_len >= 2.5 -- Detect melee gesture
	end
	
	----------------------------------------------------------------------------------------------------------
	
	local game_engine_class = api:find_uobject("Class /Script/Engine.GameEngine")
    local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)

    local viewport = game_engine.GameViewport
    if viewport == nil then
        print("Viewport is nil")
        return
    end
	
    local world = viewport.World
    if world == nil then
        print("World is nil")
        return
    end

    if world ~= last_world then
        print("World changed")
		
		bIsLevelLoaded = true

    end

    last_world = world
    local level = world.PersistentLevel

    if level == nil then
        print("Level is nil")
        return
    end
	
	--print("Level name: " .. level:get_full_name())
	
	-- Set UEVR config values when main menu active
	if string.find(tostring(level:get_full_name()), "MainMenuScene.MainMenuScene.PersistentLevel") then	
		vr.set_mod_value("VR_AimMethod", "0")
		vr.set_mod_value("VR_RoomscaleMovement", "0")
		vr.set_mod_value("VR_DecoupledPitch", "1")		
		vr.set_mod_value("VR_MotionControlsInactivityTimer", "9999.000000")
		vr.set_mod_value("VR_AimUsePawnControlRotation", "0")		
		vr.set_mod_value("VR_NativeStereoFix", "1") -- Fixes volumetric clouds
		vr.set_mod_value("VR_NativeStereoFixSamePass", "1")
		
		vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
		vr.set_mod_value("VR_CameraRightOffset", "0.000000")
		vr.set_mod_value("VR_CameraUpOffset", "0.000000")	
		vr.set_mod_value("UI_X_Offset", "-0.200000")
		vr.set_mod_value("UI_Y_Offset", ".05000")
		vr.set_mod_value("UI_Distance", "2.000000")
		
		return
	end		
	
	----------------------------------------------------------------------------------------------------------
	
	
	-- The player mesh contains shoulder and upper arm bones which need hidden for VR.  We can hide these by creating a floating hands PAK mod with Blender and Unreal Editor 4.27.
	-- Perform the following steps for the following player models: SK_PlayerCharacterHands, SK_PlayerCharacterHandsDLC, SK_PlayerCharacterHandsDLC3 
	--
    -- 01) Locate player model in Fmodel and export the model into a .pskx file.
    -- 02) Install the Blender .psk plugin and load the file into Blender 4.x without scaling it down.
    -- 03) Set root object name to Armature
    -- 04) Add Mask modifiers and set Vertex Group to mesh you want to hide i.e. upperarm_l, upperarm_twist_01_l, upperarm_r, upperarm_twist_01_r, shlang_1_joint, shlang_6_joint, shlang_8_joint, shlang_12_joint, pelvis
    -- 05) Hit the double arrow icon to invert all masks
    -- 06) Export the model to .fbx with the following settings
     --   * Scale = 0.01
    --    * Smoothing = Face
    --    * Add Leaf Bones = Unticked
    -- 07) Import .fbx into Unreal Engine 4.27. Hit Import All when prompted. 
    -- 08) Make sure Skeletal Mesh, Physics Asset, Skeleton, and Materials have same path and filename structure as Fmodel
    -- 09) Under Project Setings > Packaging, tick Use Pak File and Generate Chunks.
    -- 10) Under Editor Preferences > Experimental, tick Allow ChunkID Assignments.
    -- 11) Right click Skeletal Mesh and Physics Asset.  Under Asset Actions, assign each to a chunk.  DO NOT ADD MATERIALS OR SKELETON.
    -- 12) Hit File > Package Project > Windows, and copy the generated PAK to Steam folder.
    	
	local pawn = api:get_local_pawn()
	local mesh = pawn.Mesh	

    if pawn ~= nil then	
		
		-- Initialize VR settings
		vr.set_mod_value("VR_MotionControlsInactivityTimer", "9999.000000")	
		vr.set_mod_value("VR_NativeStereoFix", "1") -- Fixes volumetric clouds
		vr.set_mod_value("VR_NativeStereoFixSamePass", "1")
		vr.set_mod_value("VR_CameraUpOffset", "0.000000")		
			
		-- Check if pawn detected	
		if string.find(tostring(pawn:get_full_name()), "BP_PlayerCharacter_C") or string.find(tostring(pawn:get_full_name()), "BP_PlayerCharacter_NewtonDLC_C") or string.find(tostring(pawn:get_full_name()), "BP_PlayerCharacter_DLC3_C") then
		
			vr.set_mod_value("VR_AimUsePawnControlRotation", "1")

			-- Animation instance
			local player_anim_instance = mesh.AnimScriptInstance		

			if player_anim_instance ~= nil then
				bIsReload = player_anim_instance.Reload
				bIsReloadOneHand = player_anim_instance.ReloadOneHand
				bIsRangeWeapon = player_anim_instance.IsRangeWeapon
				bIsNotCutscene = player_anim_instance.bShouldApplyEyeSmother -- bShouldApplyEyeSmother oddly tells us when in-game cutscenes/animations are playing
				bIsSplash = player_anim_instance.LockEye -- LockEye tells us if a menu splash screen is active
				bIsClimbing = player_anim_instance.IsClimbing	
				bIsWhipActive = player_anim_instance.IsWhipActive
				bIsConsumeItem = player_anim_instance.ConsumeItem
				bIsDelayWhipActive = player_anim_instance.DelayWhipActived
				bIsSwimming = player_anim_instance.IsSwimming
				bIsAiming = player_anim_instance.IsAiming
				
				if bIsStunned == true then
					bIsNotCutscene = true
				end
				
				if player_anim_instance.CurrentWeapon ~= nil then	
					CurrentWeapon = player_anim_instance.CurrentWeapon
					BlueprintCreatedComponents = CurrentWeapon.BlueprintCreatedComponents -- Get blueprint components for the current weapon.  This gives us all the individual meshes used by the equipped (right hand) weapon. These should be hidden when using the left hand Polymer glove.
					FPWeapon = CurrentWeapon.Mesh
										
					------- Test code for replacing gesture based melee with collision based melee -------
					-------------------------------------------------------------------------------
					local BaseWeaponAttack = CurrentWeapon.BaseWeaponAttack
					
					local DamageType_c = find_required_object("Class /Script/Engine.DamageType")
					local damage_types = DamageType_c:get_objects_matching(true) -- Include defaults

					for k, v in pairs(damage_types) do
						--if v:as_struct() ~= nil then
							--print("Found damage type: " .. v:get_full_name())
							local c = v:get_class()
							--table.insert(melee_data.known_damage_types, c)
							--melee_data.damage_type_dict[c:get_fname():to_string()] = c
						--end
					end
					
					local CapsuleComponents= UEVR_UObjectHook.get_objects_by_class(Capsule_C,false)		
					for i, comp in ipairs(CapsuleComponents) do
						if comp:get_fname():to_string() == "Collision" then
							--print(comp:get_fname():to_string())
							comp:SetCollisionEnabled(1)
							comp:SetGenerateOverlapEvents(true)
							comp:SetCollisionResponseToAllChannels(1)
						end
					end
					
					local SphereComponents= UEVR_UObjectHook.get_objects_by_class(Sphere_C,false)
					for i, comp in ipairs(SphereComponents) do
						if comp:get_fname():to_string() == "Collision" then
							--print(comp:get_fname():to_string())
							comp:SetCollisionEnabled(1)				
							comp:SetGenerateOverlapEvents(true)	
							comp:SetCollisionResponseToAllChannels(1)
						end
					end	
					
					--Set melee collision
					local  weapon_physics = FPWeapon

					--weapon_physics:SetHiddenInGame(false,true) -- This nukes the game
					weapon_physics:SetVisibility(true)
					weapon_physics:SetCollisionEnabled(1)
					weapon_physics:SetGenerateOverlapEvents(true)
					weapon_physics.BodyInstance.CollisionResponses.ResponseToChannels.WorldStatic = 1
					weapon_physics:SetCollisionResponseToAllChannels(1)
					weapon_physics:SetCollisionObjectType(0)
					
					--Get weapon overlaps
					local weapon_overlap_comps = {}
					weapon_physics:GetOverlappingComponents(weapon_overlap_comps)

					for _, comp in ipairs(weapon_overlap_comps) do
						if string.find(comp:get_full_name(), "Vov") then
							--print("Weapon Collided with: ", comp:get_full_name())							
							--AHDamageUtils:ApplyDamage(comp:GetOwner(),30,nil,pawn,DamageTypes)
						end
					end
					
					-------------------------------------------------------
					
					ResetMeshOffsets() -- Reset dynamic mesh offsets
					
				end
			end		

			if CurrentWeapon ~= nil then
			
				-- We can typically poll the IsPolimerActiveSkill boolean to detect if the Polymer glove is active.  If fists are equipped, IsPolimerActiveSkill is forced true so we must poll the controller input to detect if the glove is being used. 
				-- It is preferred to poll IsPolimerActiveSkill when possible as the glove could still be active for a short duration after the input for the glove is no longer being depressed.
				if string.find(CurrentWeapon:get_full_name(), "BP_EmptyHands_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonEmptyHands_C") or string.find(CurrentWeapon:get_full_name(), "BP_EmptyHands_DLC3_C") then 
					if bForcePolymer == false then -- Check if the left controller glove input is being used
						bIsPolymer = false -- Set boolean manually if IsPolimerActiveSkill is unavailable 		 	
					else
						bIsPolymer = true -- Set boolean manually if IsPolimerActiveSkill is unavailable 	
					end
				else
					bIsPolymer = player_anim_instance.IsPolimerActiveSkill -- We can always use IsPolimerActiveSkill to set bIsPolymer when any weapon other than fists are equipped
				end	
			
			else			
				if bForcePolymer == false then -- Check if the left controller glove input is being used
					bIsPolymer = false -- Set boolean manually if IsPolimerActiveSkill is unavailable 				
				else
					bIsPolymer = true -- Set boolean manually if IsPolimerActiveSkill is unavailable 	
				end
			end
			
			-- Hide legs mesh
            local FPLegs = pawn.FPLegsMesh
            FPLegs:SetVisibility(false)
			
			local player_legs_anim_instance = FPLegs.AnimScriptInstance
			bIsCrouched = player_legs_anim_instance.IsCrouch
			
			-- Settings for rotating the player arms
			local FPHands = pawn.FPHandsPostProcessMesh
			local FPHands_RelativeLocation = FPHands.RelativeLocation
			local FPHands_RelativeRotation = FPHands.RelativeRotation
			
			-- Settings for fixing hand positions
			local FPMesh_RelativeLocation = mesh.RelativeLocation
			local FPMesh_RelativeRotation = mesh.RelativeRotation
			
			if CurrentWeapon ~= nil then			
				-- Settings for rescaling and repositioning melee weapons for better VR comfort
				CurrentWeapon_Mesh = CurrentWeapon.Mesh
				CurrentWeapon_Mesh_RelativeLocation = CurrentWeapon_Mesh.RelativeLocation
				CurrentWeapon_Mesh_RelativeScale3D = CurrentWeapon_Mesh.RelativeScale3D
			end	
			
			--Controller settings	
			local controller_component = pawn.Controller
			bIsMouse = controller_component.bShowMouseCursor
			
			local acknowledged_pawn_component = controller_component.AcknowledgedPawn
			local character_movement_component = acknowledged_pawn_component.CharacterMovement
			
			if bIsAiming == true and bIsCrouched == false then
				character_movement_component.MaxWalkSpeed = 800 -- Boost movement speed when aiming is active
			end
			
			--Attachment settings		
			local mesh_state = UEVR_UObjectHook.get_or_add_motion_controller_state(mesh)
			
			if bIsPolymer == true then -- Check if left handed Polymer glove is active
				mesh_state:set_hand(0) -- Left hand attachment
			else
				mesh_state:set_hand(1) -- Right hand attachment
				SpecialOffsetX = 0 -- Reset left hand attachment offset
				SpecialOffsetY = 0 -- Reset left hand attachment offset
				SpecialOffsetZ = 0 -- Reset left hand attachment offset
			end
			
			if bIsClimbing or bIsNotCutscene == false then
				mesh_state:set_permanent(false) -- Clear permanent to fix hand positions during cutscenes and climbing.
				
				-- Relative Location and Relative Position must be reset when toggling the mesh Permanent state or hands will be positioned incorrectly and the player can be rocketed out of the map
				if PosResetEn == true then
					FPMesh_RelativeLocation.X = 0.000
					FPMesh_RelativeLocation.Y = 0.000
					FPMesh_RelativeLocation.Z = -165.000
					FPMesh_RelativeRotation.Pitch = 0.000
					FPMesh_RelativeRotation.Roll = 0.000	
					FPMesh_RelativeRotation.Yaw = 0.000
					PosResetEn = false
				end
			
			else
				mesh_state:set_permanent(true) -- Set permanent to fix projectiles 
				PosResetEn = true
			end
			
			-- 3D spatial audio fix	when Right Hand aiming is active	
			local playerController = uevr.api:get_player_controller(0)
			local hmdController = controllers.getController(2)
						
			if bAudioFix == true then				
				if playerController ~= nil and hmdController ~= nil and bSetListenerOnetime == false then
					playerController:SetAudioListenerOverride(hmdController,uevrUtils.vector(0,0,0),uevrUtils.rotator(0,0,0))
				end
				
				bSetListenerOnetime = true
				bClearListenerOnetime = false
			else			
				if playerController ~= nil and bClearListenerOnetime == false then
					playerController:ClearAudioListenerOverride() -- Reset audio overrides when aiming is in Game mode 
				end
				
				bSetListenerOnetime = false
				bClearListenerOnetime = true
			end	
						
			if bIsWorldMap == true then
				UEVR_UObjectHook.set_disabled(true) -- Map fix
			    vr.set_mod_value("VR_AimMethod", "0") -- Map fix
				vr.set_mod_value("VR_MovementOrientation", "0")
				vr.set_mod_value("VR_RoomscaleMovement", "1")
				vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
				vr.set_mod_value("VR_CameraRightOffset", "0.000000")
				vr.set_mod_value("UI_X_Offset", "0.000000")
				vr.set_mod_value("UI_Y_Offset", "0.000000")
				vr.set_mod_value("UI_Distance", "2.000000")
				vr.set_mod_value("VR_DecoupledPitch", "0") -- Map fix
				vr.set_mod_value("VR_LerpCameraPitch", "false")
				vr.set_mod_value("VR_LerpCameraYaw", "false")
				vr.set_mod_value("VR_LerpCameraRoll", "false")
				vr.set_mod_value("VR_LerpCameraSpeed", "0.000000")			
				bForceRebind = false	
				bAudioFix = false
				print("Is World Map")				
			elseif bIsClimbing == true then
				UEVR_UObjectHook.set_disabled(true) -- Immediately lock UObjectHooks as enabled or vaulting will trigger cutscene detection and cause player to get rocketed into walls
			    vr.set_mod_value("VR_AimMethod", "0")
				vr.set_mod_value("VR_MovementOrientation", MOVEMENT_ORIENTATION)
				vr.set_mod_value("VR_RoomscaleMovement", "1")
				vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
				vr.set_mod_value("VR_CameraRightOffset", "0.000000")
				vr.set_mod_value("UI_X_Offset", "0.000000")
				vr.set_mod_value("UI_Y_Offset", "0.000000")
				vr.set_mod_value("UI_Distance", "2.000000")
				vr.set_mod_value("VR_DecoupledPitch", "1")
				vr.set_mod_value("VR_LerpCameraPitch", "false")
				vr.set_mod_value("VR_LerpCameraYaw", "false")
				vr.set_mod_value("VR_LerpCameraRoll", "false")
				vr.set_mod_value("VR_LerpCameraSpeed", "0.000000")						
				bForceRebind = false
				bAudioFix = false
				print("Is Climbing")
			elseif bIsLockPuzzle == true then
				bIsPolymer = true -- Temporarily force glove active for lock picking
				UEVR_UObjectHook.set_disabled(true) -- Lock puzzle fix
				vr.set_mod_value("VR_AimMethod", "0") -- Lock puzzle fix			
				vr.set_mod_value("VR_MovementOrientation", MOVEMENT_ORIENTATION)
				vr.set_mod_value("VR_RoomscaleMovement", "0") -- Lock puzzle fix
				vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
				vr.set_mod_value("VR_CameraRightOffset", "0.000000")
				vr.set_mod_value("UI_X_Offset", "0.000000")
				vr.set_mod_value("UI_Y_Offset", "0.000000")
				vr.set_mod_value("UI_Distance", "2.000000")
				vr.set_mod_value("VR_DecoupledPitch", "1")
				vr.set_mod_value("VR_LerpCameraPitch", "false")
				vr.set_mod_value("VR_LerpCameraYaw", "false")
				vr.set_mod_value("VR_LerpCameraRoll", "false")
				vr.set_mod_value("VR_LerpCameraSpeed", "0.000000")						
				bForceRebind = true -- Remap controls during normal gameplay
				bAudioFix = true
				print("Is Lock Puzzle")
			elseif bIsPinPuzzle == true then
				UEVR_UObjectHook.set_disabled(true) -- Disable UObjectHooks to fix pin puzzles
				vr.set_mod_value("VR_AimMethod", "0")  -- Set aim mode to Game to fix pin puzzles	
				vr.set_mod_value("VR_MovementOrientation", MOVEMENT_ORIENTATION)
				vr.set_mod_value("VR_RoomscaleMovement", "0") -- Disable Roomscale to fix pin puzzles			
				vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
				vr.set_mod_value("VR_CameraRightOffset", "0.000000")
				vr.set_mod_value("UI_X_Offset", "-0.200000") -- Offset UI to realign cursor when pin puzzles active 
				vr.set_mod_value("UI_Y_Offset", ".05000")
				vr.set_mod_value("UI_Distance", "2.000000")
				vr.set_mod_value("VR_DecoupledPitch", "1")
				vr.set_mod_value("VR_LerpCameraPitch", "false")
				vr.set_mod_value("VR_LerpCameraYaw", "false")
				vr.set_mod_value("VR_LerpCameraRoll", "false")
				vr.set_mod_value("VR_LerpCameraSpeed", "0.000000")				
				bForceRebind = false
				bAudioFix = false
				print("Is Pin Puzzle")
			elseif bIsNoraSkills == true then
				UEVR_UObjectHook.set_disabled(true) -- Disable UObjectHooks to fix Nora
			    vr.set_mod_value("VR_AimMethod", "0") -- Set aim mode to Game to fix Nora	
				vr.set_mod_value("VR_MovementOrientation", MOVEMENT_ORIENTATION)
				vr.set_mod_value("VR_RoomscaleMovement", "1")				
				vr.set_mod_value("VR_CameraForwardOffset", "50.000000") -- Realign camera when Nora active
				vr.set_mod_value("VR_CameraRightOffset", "-25.000000")
				vr.set_mod_value("UI_X_Offset", "-0.250000") -- Offset UI to realign cursor when Nora active 
				vr.set_mod_value("UI_Y_Offset", "-1.050000")
				vr.set_mod_value("UI_Distance", "4.000000")
				vr.set_mod_value("VR_DecoupledPitch", "1")
				vr.set_mod_value("VR_LerpCameraPitch", "false")
				vr.set_mod_value("VR_LerpCameraYaw", "false")
				vr.set_mod_value("VR_LerpCameraRoll", "false")
				vr.set_mod_value("VR_LerpCameraSpeed", "0.000000")						
				bForceRebind = false	
				bAudioFix = false				
				print("Is Nora")				
			elseif bIsMenu == true or bIsNoraCrafting == true then
				UEVR_UObjectHook.set_disabled(true) -- Disable UObjectHooks to fix Nora and menus
			    vr.set_mod_value("VR_AimMethod", "0") -- Set aim mode to Game to fix Nora and menus
				vr.set_mod_value("VR_MovementOrientation", MOVEMENT_ORIENTATION)
				vr.set_mod_value("VR_RoomscaleMovement", "1") 				
				vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
				vr.set_mod_value("VR_CameraRightOffset", "0.000000")
				vr.set_mod_value("UI_X_Offset", "0.000000")
				vr.set_mod_value("UI_Y_Offset", "0.000000")
				vr.set_mod_value("UI_Distance", "2.000000")
				vr.set_mod_value("VR_DecoupledPitch", "1")
				vr.set_mod_value("VR_LerpCameraPitch", "false")
				vr.set_mod_value("VR_LerpCameraYaw", "false")
				vr.set_mod_value("VR_LerpCameraRoll", "false")
				vr.set_mod_value("VR_LerpCameraSpeed", "0.000000")
				bForceRebind = false
				bAudioFix = false
				print("Is Menu")
			elseif bIsNotCutscene == true and bIsSplash == false then
				UEVR_UObjectHook.set_disabled(false) -- Enable UObjectHooks for normal gameplay
				
				if bIsPolymer == true then
					vr.set_mod_value("VR_AimMethod", "3") -- Left hand aim when Polymer glove active
				else
					vr.set_mod_value("VR_AimMethod", "2") -- Right hand aim when weapon active				
				end				
				
				vr.set_mod_value("VR_MovementOrientation", MOVEMENT_ORIENTATION)
				vr.set_mod_value("VR_RoomscaleMovement", "1")
				vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
				vr.set_mod_value("VR_CameraRightOffset", "0.000000")
				vr.set_mod_value("UI_X_Offset", "0.000000")
				vr.set_mod_value("UI_Y_Offset", "0.000000")
				vr.set_mod_value("UI_Distance", "2.000000")
				vr.set_mod_value("VR_DecoupledPitch", "1")
				vr.set_mod_value("VR_LerpCameraPitch", "false")
				vr.set_mod_value("VR_LerpCameraYaw", "false")
				vr.set_mod_value("VR_LerpCameraRoll", "false")
				vr.set_mod_value("VR_LerpCameraSpeed", "0.000000")				
				bForceRebind = true -- Remap controls during normal gameplay
				bAudioFix = true
				-- print("Normal gameplay")				
			elseif DEV_BUILD == true then
				UEVR_UObjectHook.set_disabled(false) -- Enable UObjectHooks for normal gameplay
				
				if bIsPolymer == true then
					vr.set_mod_value("VR_AimMethod", "3") -- Left hand aim when Polymer glove active
				else
					vr.set_mod_value("VR_AimMethod", "2") -- Right hand aim when weapon active				
				end	
				
				vr.set_mod_value("VR_MovementOrientation", MOVEMENT_ORIENTATION)
				vr.set_mod_value("VR_RoomscaleMovement", "1")
				vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
				vr.set_mod_value("VR_CameraRightOffset", "0.000000")
				vr.set_mod_value("UI_X_Offset", "0.000000")
				vr.set_mod_value("UI_Y_Offset", "0.000000")
				vr.set_mod_value("UI_Distance", "2.000000")
				vr.set_mod_value("VR_DecoupledPitch", "1")
				vr.set_mod_value("VR_LerpCameraPitch", "false")
				vr.set_mod_value("VR_LerpCameraYaw", "false")
				vr.set_mod_value("VR_LerpCameraRoll", "false")
				vr.set_mod_value("VR_LerpCameraSpeed", "0.000000")				
				bForceRebind = true -- Remap controls during normal gameplay
				bAudioFix = true
				-- print("Normal gameplay")				
			else

				UEVR_UObjectHook.set_disabled(true) -- Disable UObjectHooks to fix cutscenes
			    vr.set_mod_value("VR_AimMethod", "0") -- Set aim mode to Game to fix cutscenes
				vr.set_mod_value("VR_MovementOrientation", MOVEMENT_ORIENTATION)
				vr.set_mod_value("VR_RoomscaleMovement", "0") -- Disable Roomscale to fix cutscenes
				vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
				vr.set_mod_value("VR_CameraRightOffset", "0.000000")
				vr.set_mod_value("UI_X_Offset", "0.000000")
				vr.set_mod_value("UI_Y_Offset", "0.000000")
				vr.set_mod_value("UI_Distance", "2.000000")
				vr.set_mod_value("VR_DecoupledPitch", "1")
				
				if CUTSCENE_LERP == true then
					vr.set_mod_value("VR_LerpCameraPitch", "true") -- Test settings for comfort, may cause directional issues during cutscenes
					vr.set_mod_value("VR_LerpCameraYaw", "true")
					vr.set_mod_value("VR_LerpCameraRoll", "true")
				else
					vr.set_mod_value("VR_LerpCameraPitch", "false")
					vr.set_mod_value("VR_LerpCameraYaw", "false")
					vr.set_mod_value("VR_LerpCameraRoll", "false")
				end
				
				vr.set_mod_value("VR_LerpCameraSpeed", "0.000000")
				bForceRebind = false -- Remap controls during normal gameplay
				bAudioFix = false
				print("Is Cutscene")				
			end
			
			-- pawn:GetCurrentMontage()
			
			-- Use this function to implement physical melee.  We can probably do this with Lua/C++ but we will use GetCurrentMontage() data to build a melee PAK mod as this is less complex. 
			-- After we obtain the montages associated with a weapon, replace all montages with an attack montage.  Swap them in Windows Explorer, then update the filenames under Name Map in UAssetGUI. This will force the game to apply damage, hit FX, dismemberment, and audio cues immediately after an attack without waiting for weapon animations to finish playing.
			-- Next, we need to replace the attack animation sequence (get the filename by opening the attack montage from GetCurrentMontage() in UAssetGUI and searching for AnimReference) with an idle weapon animation (locate this in Fmodel) so the weapon will move 1:1 with the motion controller during the attack montage. Swap them in Windows Explorer, then update the filenames under Name Map in Uassetgui.
			-- Finally, stop the animation of duplicate montages with Lua via 'pawn:StopAnimMontage(montage_name)' to prevent multiple "swoosh" audio FX.
			--
			-- Shved: Replace AM_Shved_Hands_Right_Rise_Montage and AM_Shved_Hands_Release_Left_Attack with AM_Shved_PlayerHands_Right_Attack.  Replace AS_Zvezdochka_PlayerCharacterHands_RightAttack1 with AS_PlayerCharacterHands_ZvezdochkaIdle. Stop AM_Shved_PlayerHands_Right_Attack.
			-- Lisa: Replace AM_PlayerCharacterHands_Lisa_Rise and AM_PlayerCharacterHands_Lisa_Attack_Left with AM_PlayerCharacterHands_Lisa_Attack_Right.  Replace AS_PlayerCharacterHands_Lisa_Attack01 and AS_PlayerCharacterHands_Lisa_AttackC2_v2 with AS_PlayerCharacterHands_Lisa_CombatIdle. Stop AM_PlayerCharacterHands_Lisa_Attack_Right.
			-- Gromoverzhec: Replace AM_PlayerCharacterHands_Gromoverzec_SimpleAttack_Rise and AM_PlayerCharacterHands_Gromoverzec_SimpleAttack_02 with AM_PlayerCharacterHands_Gromoverzec_SimpleAttack_01.  Replace AS_PlayerCharacterHands_Gromoverzec_SimpleAttack1 with AS_PlayerCharacterHands_Gromoverzec_Idle.  Stop AM_PlayerCharacterHands_Gromoverzec_SimpleAttack_01.
			-- Pashtet: Replace AM_PlayerCharacterHands_Pashtet_Attack_R_Rise_Montage and AM_PlayerCharacterHands_Pashtet_Attack_Left with AM_PlayerCharacterHands_Pashtet_Right_Attack.  We can ignore the anim sequences as these are shared with the Lisa.  Stop AM_PlayerCharacterHands_Pashtet_Right_Attack.
			-- Zvezdochka: Replace AM_PlayerCharacterHands_Zvezdochka_Attack_Right_Rise and AM_PlayerCharacterHands_Zvezdochka_Attack_Left with AM_PlayerCharacterHands_Zvezdochka_Attack_Right. Replace AS_PlayerCharacterHands_Zvezdochka_AttackRight with AS_PlayerCharacterHands_ZvezdochkaIdle. Stop AM_PlayerCharacterHands_Zvezdochka_Attack_Right.
			-- Snejok: Replace AM_Snejok_Hands_Right_Rise and AM_Snejok_Hands_Release_Left_Attack with AM_Snejok_PlayerHands_Right_Attack. We can ignore the anim sequence as these are shared with the Zvezdochka.  Stop AM_Snejok_PlayerHands_Right_Attack.
			
			-- We should also disable all "_DamageMeleeHitHardFallReaction_Montage" montages to prevent enemy knockback. 
			
			-- The Shved, Snejok, and Zvezdochka models are too large for VR and need rescaled.  This causes issues with heavy melee animations.  To fix this, stop AM_PlayerCharacterHands_ShvedToggleAttack_Hold, AM_PlayerCharacterHands_Snejok_Toggle_Hold, and AM_PlayerCharacterHands_Zvezdochka_ToggleAttack_Hold.
			-- AM_PlayerCharacterHands_ShvedToggleAttack_Rise, AM_PlayerCharacterHands_Snejok_Toggle_Rise, AM_PlayerCharacterHands_Zvezdochka_ToggleAttack_Rise cannot be stopped with StopAnimMontage() so we will stop these by zeroing out all their time values in UassetGUI and PAK modding them back into the game. 
			
			-- AM_PlayerCharacterHands_ContinuousPickup_Start should also be replaced with AM_PlayerCharacterHards_CastingActiveIdleShortLength to keep hand tracking 1:1 when looting.
			
			local montage = pawn:GetCurrentMontage()
			if montage ~= nil then
				--print (montage:get_full_name())
				
				if string.find(tostring(montage:get_full_name()), "Damage") then
					bIsStunned = true
					StunTime = os.clock()
				end			

				if os.clock() - StunTime >= 3 then 
					bIsStunned = false
				end				
				
				-- Detect Telekenisis here as we cannot seem to hook these functions reliably
				if string.find(tostring(montage:get_full_name()), "AM_PlayerCharacterHands_TelekineticSmash_LiftUp_V02") then 
					print("Called GCA_TelekineticSmash_C K2_OnTakeOff")
					SpecialOffsetX = 0
					SpecialOffsetY = 17
					SpecialOffsetZ = 0
				elseif string.find(tostring(montage:get_full_name()), "AM_PlayerCharacterHands_TelekineticSmash_OverheatedEnd") then 
					print("Called GA_TelekineticSmashAI_C K2_OnEndAbility")
					SpecialOffsetX = 0
					SpecialOffsetY = 0
					SpecialOffsetZ = 0
				end
				
				if string.find(tostring(montage:get_full_name()), "PickUp") then
					bIsPickupAnim = true -- Set flag to unhide right hand mesh when the left hand transfers items to the right hand
				else
					bIsPickupAnim = false
				end				
			else
				bIsPickupAnim = false				
			end	
	
			-- Set attachment location and rotation
			if player_anim_instance.CurrentWeapon ~= nil then	
				if bIsPolymer == true then
					if bIsChargingWeapon == true then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(-22.000+SpecialOffsetX, 155.000+SpecialOffsetY, -40.000+SpecialOffsetZ)) -- Left,Down,Forward
						bIsOneHandedWeapon = false
					elseif string.find(CurrentWeapon:get_full_name(), "BP_AK47_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonAK47_C") or string.find(CurrentWeapon:get_full_name(), "BP_AK47_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_AK47_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(-22.000+SpecialOffsetX, 155.000+SpecialOffsetY, -42.000+SpecialOffsetZ))
						bIsOneHandedWeapon = false
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Electro_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonElectro_C") or string.find(CurrentWeapon:get_full_name(), "BP_Electro_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Electro_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(-22.000+SpecialOffsetX, 155.000+SpecialOffsetY, -38.000+SpecialOffsetZ)) 
						bIsOneHandedWeapon = false
					elseif string.find(CurrentWeapon:get_full_name(), "BP_EmptyHands_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonEmptyHands_C") or string.find(CurrentWeapon:get_full_name(), "BP_EmptyHands_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_EmptyHands_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(-22.000+SpecialOffsetX, 155.000+SpecialOffsetY, -38.000+SpecialOffsetZ)) 
						bIsOneHandedWeapon = false
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Krepysh_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonKrepysh_C") or string.find(CurrentWeapon:get_full_name(), "BP_Krepysh_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Krepysh_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(-22.000+SpecialOffsetX, 153.000+SpecialOffsetY, -38.000+SpecialOffsetZ)) 
						bIsOneHandedWeapon = false		
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Lisa_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonLisa_C") or string.find(CurrentWeapon:get_full_name(), "BP_Lisa_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Lisa_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(-20.000+SpecialOffsetX, 154.000+SpecialOffsetY, -40.000+SpecialOffsetZ)) 
						bIsOneHandedWeapon = true -- Set flag to hide left arm bones
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Gromoverzhec_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonGromoverzhec_C") or string.find(CurrentWeapon:get_full_name(), "BP_Gromoverzhec_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Gromoverzhec_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(-20.000+SpecialOffsetX, 154.000+SpecialOffsetY, -40.000+SpecialOffsetZ)) 
						bIsOneHandedWeapon = true -- Set flag to hide left arm bones						
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Pashtet_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonPashtet_C") or string.find(CurrentWeapon:get_full_name(), "BP_Pashtet_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Pashtet_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(-20.000+SpecialOffsetX, 154.000+SpecialOffsetY, -40.000+SpecialOffsetZ)) 
						bIsOneHandedWeapon = true -- Set flag to hide left arm bones
					elseif string.find(CurrentWeapon:get_full_name(), "BP_PM_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonPM_C") or string.find(CurrentWeapon:get_full_name(), "BP_PM_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_PM_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(-22.000+SpecialOffsetX, 153.000+SpecialOffsetY, -38.000+SpecialOffsetZ)) 
						bIsOneHandedWeapon = false		
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Railgun_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonRailgun_C") or string.find(CurrentWeapon:get_full_name(), "BP_Railgun_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Railgun_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(-22.000+SpecialOffsetX, 155.000+SpecialOffsetY, -42.000+SpecialOffsetZ))
						bIsOneHandedWeapon = false
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Kuzmich_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonKuzmich_C") or string.find(CurrentWeapon:get_full_name(), "BP_Kuzmich_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Kuzmich_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(-22.000+SpecialOffsetX, 155.000+SpecialOffsetY, -42.000+SpecialOffsetZ))
						bIsOneHandedWeapon = false						
					elseif string.find(CurrentWeapon:get_full_name(), "BP_ShotgunKS23_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonShotgunKS23_C") or string.find(CurrentWeapon:get_full_name(), "BP_ShotgunKS23_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_ShotgunKS23_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(-22.000+SpecialOffsetX, 155.000+SpecialOffsetY, -42.000+SpecialOffsetZ))
						bIsOneHandedWeapon = false
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Shved_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonShved_C") or string.find(CurrentWeapon:get_full_name(), "BP_Shved_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Shved_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(-22.000+SpecialOffsetX, 155.000+SpecialOffsetY, -40.000+SpecialOffsetZ)) 
						bIsOneHandedWeapon = true -- Set flag to hide left arm bones
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Snejok_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonSnejok_C") or string.find(CurrentWeapon:get_full_name(), "BP_Snejok_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Snejok_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(-20.000+SpecialOffsetX, 154.000+SpecialOffsetY, -40.000+SpecialOffsetZ)) 
						bIsOneHandedWeapon = true -- Set flag to hide left arm bones					
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Dominator_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonDominator_C") or string.find(CurrentWeapon:get_full_name(), "BP_Dominator_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Dominator_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(-22.000+SpecialOffsetX, 155.000+SpecialOffsetY, -40.000+SpecialOffsetZ)) 
						bIsOneHandedWeapon = false
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Zvezdochka_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonZvezdochka_C") or string.find(CurrentWeapon:get_full_name(), "BP_Zvezdochka_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Zvezdochka_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(-28.000+SpecialOffsetX, 148.000+SpecialOffsetY, -50.000+SpecialOffsetZ)) 
						bIsOneHandedWeapon = true -- Set flag to hide left arm bones
					end	
					
					-- Reset player arm rotation
					FPHands_RelativeLocation.X = 0.000
					FPHands_RelativeLocation.Y = 0.000
					FPHands_RelativeLocation.Z = 0.000
					FPHands_RelativeRotation.Pitch = 0.000
					FPHands_RelativeRotation.Roll = 0.000
					FPHands_RelativeRotation.Yaw = 0.000		

				elseif bIsPolymer == false then	
					if bIsWhipActive == true or bIsDelayWhipActive == true then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(0.500, 158.000, -47.000))
						
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000
						FPHands_RelativeRotation.Yaw = 0.000	
						
						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000
												
						bIsOneHandedWeapon = false				
					elseif shotgun_thermal_scope == true then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(0.000, 160.000, -25.000))  -- Left,Down,Forward
						
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000
						FPHands_RelativeRotation.Yaw = 0.000	
						
						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000

						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Krepysh/AM_PlayerCharacterHands_Krepysh_DamageMeleeHitHardFallReaction_Montage.AM_PlayerCharacterHands_Krepysh_DamageMeleeHitHardFallReaction_Montage")
						pawn:StopAnimMontage(stunned_anim)						
					
						bIsOneHandedWeapon = false			
					elseif shotgun_collimator_scope == true then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(0.000, 160.000, -25.000))
						
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000
						FPHands_RelativeRotation.Yaw = 0.000	
						
						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000

						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Krepysh/AM_PlayerCharacterHands_Krepysh_DamageMeleeHitHardFallReaction_Montage.AM_PlayerCharacterHands_Krepysh_DamageMeleeHitHardFallReaction_Montage")
						pawn:StopAnimMontage(stunned_anim)						
					
						bIsOneHandedWeapon = false			
					elseif pm_thermal_scope == true then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000)) 
						mesh_state:set_location_offset(temp_vec3f:set(0.500, 155.000, -37.000))
						
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000
						FPHands_RelativeRotation.Yaw = 0.000
						
						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000

						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/PM/AM_PlayerCharacterHands_PM_DamageMeleeHitHardFallReaction_Montage.AM_PlayerCharacterHands_PM_DamageMeleeHitHardFallReaction_Montage")
						pawn:StopAnimMontage(stunned_anim)						
						
						bIsOneHandedWeapon = false					
					elseif pm_collimator_scope == true then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000)) 
						mesh_state:set_location_offset(temp_vec3f:set(0.500, 155.000, -45.000))
						
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000
						FPHands_RelativeRotation.Yaw = 0.000	
						
						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000

						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/PM/AM_PlayerCharacterHands_PM_DamageMeleeHitHardFallReaction_Montage.AM_PlayerCharacterHands_PM_DamageMeleeHitHardFallReaction_Montage")
						pawn:StopAnimMontage(stunned_anim)						
						
						bIsOneHandedWeapon = false	
					elseif ak47_thermal_scope == true then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000)) 
						mesh_state:set_location_offset(temp_vec3f:set(0.000, 155.000, -40.000))
						
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000
						FPHands_RelativeRotation.Yaw = 0.000		
						
						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000
						
						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Krepysh/AM_PlayerCharacterHands_Krepysh_DamageMeleeHitHardFallReaction_Montage.AM_PlayerCharacterHands_Krepysh_DamageMeleeHitHardFallReaction_Montage")
						pawn:StopAnimMontage(stunned_anim)		
						
						bIsOneHandedWeapon = false	
					elseif ak47_collimator_scope == true then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000)) 
						mesh_state:set_location_offset(temp_vec3f:set(0.000, 155.000, -35.000))
						
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000
						FPHands_RelativeRotation.Yaw = 0.000
						
						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000
						
						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Krepysh/AM_PlayerCharacterHands_Krepysh_DamageMeleeHitHardFallReaction_Montage.AM_PlayerCharacterHands_Krepysh_DamageMeleeHitHardFallReaction_Montage")
						pawn:StopAnimMontage(stunned_anim)		
						
						bIsOneHandedWeapon = false				
					elseif string.find(CurrentWeapon:get_full_name(), "BP_AK47_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonAK47_C") or string.find(CurrentWeapon:get_full_name(), "BP_AK47_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_AK47_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(0.000, 155.000, -35.000))  --was 0 150 -15
						
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000
						FPHands_RelativeRotation.Yaw = 0.000
						
						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000
						
						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Krepysh/AM_PlayerCharacterHands_Krepysh_DamageMeleeHitHardFallReaction_Montage.AM_PlayerCharacterHands_Krepysh_DamageMeleeHitHardFallReaction_Montage")
						pawn:StopAnimMontage(stunned_anim)						
						
						bIsOneHandedWeapon = false
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Electro_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonElectro_C") or string.find(CurrentWeapon:get_full_name(), "BP_Electro_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Electro_Limbo_C") then
					
						if bIsChargingWeaponActive == false then
							mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
							mesh_state:set_location_offset(temp_vec3f:set(1.000, 157.000, -35.000))
						else
							mesh_state:set_rotation_offset(temp_vec3f:set(0.345, -0.145, -0.365))
							mesh_state:set_location_offset(temp_vec3f:set(5.000, 145.000, -26.000))
						end
						
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000
						FPHands_RelativeRotation.Yaw = 0.000		

						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000						
						
						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/PM/AM_PlayerCharacterHands_PM_DamageMeleeHitHardFallReaction_Montage.AM_PlayerCharacterHands_PM_DamageMeleeHitHardFallReaction_Montage")
						pawn:StopAnimMontage(stunned_anim)
						
						bIsOneHandedWeapon = false
					elseif string.find(CurrentWeapon:get_full_name(), "BP_EmptyHands_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonEmptyHands_C") or string.find(CurrentWeapon:get_full_name(), "BP_EmptyHands_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_EmptyHands_Limbo_C") then 
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(18.000, 144.000, -24.000))
						
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000
						FPHands_RelativeRotation.Yaw = 0.000	

						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000						
						
						bIsOneHandedWeapon = false
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Krepysh_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonKrepysh_C") or string.find(CurrentWeapon:get_full_name(), "BP_Krepysh_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Krepysh_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(14.000, 152.000, -20.000))
						
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000
						FPHands_RelativeRotation.Yaw = 0.000	
						
						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000

						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Krepysh/AM_PlayerCharacterHands_Krepysh_DamageMeleeHitHardFallReaction_Montage.AM_PlayerCharacterHands_Krepysh_DamageMeleeHitHardFallReaction_Montage")
						pawn:StopAnimMontage(stunned_anim)						
						
						bIsOneHandedWeapon = false				
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Lisa_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonLisa_C") or string.find(CurrentWeapon:get_full_name(), "BP_Lisa_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Lisa_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(30.000, 146.000, -34.000))
						
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000
						FPHands_RelativeRotation.Yaw = 0.000	

						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000						

						local attack_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/MeleeAttacks/OneHanded/Lisa/Primary/AM_PlayerCharacterHands_Lisa_Attack_Right.AM_PlayerCharacterHands_Lisa_Attack_Right")
						pawn:StopAnimMontage(attack_anim)												
						
						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Lisa/AM_PlayerCharacterHands_Lisa_DamageMeleeHitHardFallReaction.AM_PlayerCharacterHands_Lisa_DamageMeleeHitHardFallReaction")
						pawn:StopAnimMontage(stunned_anim)						
													
						bIsOneHandedWeapon = true -- Set flag to hide left arm bones
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Gromoverzhec_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonGromoverzhec_C") or string.find(CurrentWeapon:get_full_name(), "BP_Gromoverzhec_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Gromoverzhec_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(31.000, 146.000, -32.000))				
					
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000
						FPHands_RelativeRotation.Yaw = 0.000	
						
						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000

						local attack_anim = find_required_object("AnimMontage /Game/DLC3/Development/WeaponAssets/Gromoverzec/Animations/Player/Attacks/AM_PlayerCharacterHands_Gromoverzec_SimpleAttack_01.AM_PlayerCharacterHands_Gromoverzec_SimpleAttack_01")
						pawn:StopAnimMontage(attack_anim)		

						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Lisa/AM_PlayerCharacterHands_Lisa_DamageMeleeHitHardFallReaction.AM_PlayerCharacterHands_Lisa_DamageMeleeHitHardFallReaction")
						pawn:StopAnimMontage(stunned_anim)								
						
						bIsOneHandedWeapon = true -- Set flag to hide left arm bones
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Pashtet_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonPashtet_C") or string.find(CurrentWeapon:get_full_name(), "BP_Pashtet_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Pashtet_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(31.000, 145.000, -34.000))
						
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000						
						FPHands_RelativeRotation.Yaw = 0.000
						
						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000
						
						local attack_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Pashtet/AM_PlayerCharacterHands_Pashtet_Right_Attack.AM_PlayerCharacterHands_Pashtet_Right_Attack")
						pawn:StopAnimMontage(attack_anim)		

						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Lisa/AM_PlayerCharacterHands_Lisa_DamageMeleeHitHardFallReaction.AM_PlayerCharacterHands_Lisa_DamageMeleeHitHardFallReaction")
						pawn:StopAnimMontage(stunned_anim)		
												
						bIsOneHandedWeapon = true -- Set flag to hide left arm bones
					elseif string.find(CurrentWeapon:get_full_name(), "BP_PM_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonPM_C") or string.find(CurrentWeapon:get_full_name(), "BP_PM_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_PM_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(0.500, 158.000, -47.000))
						
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000
						FPHands_RelativeRotation.Yaw = 0.000	
						
						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000
						
						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/PM/AM_PlayerCharacterHands_PM_DamageMeleeHitHardFallReaction_Montage.AM_PlayerCharacterHands_PM_DamageMeleeHitHardFallReaction_Montage")
						pawn:StopAnimMontage(stunned_anim)
						
						bIsOneHandedWeapon = false
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Railgun_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonRailgun_C") or string.find(CurrentWeapon:get_full_name(), "BP_Railgun_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Railgun_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(8.000, 150.000, -25.000))
						
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000
						FPHands_RelativeRotation.Yaw = 0.000
						
						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000						
												
						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Railgun/AM_PlayerCharacterHands_RailgunDamageMeleeHitHardFallReaction.AM_PlayerCharacterHands_RailgunDamageMeleeHitHardFallReaction")
						pawn:StopAnimMontage(stunned_anim)						
						
						bIsOneHandedWeapon = false
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Kuzmich_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonKuzmich_C") or string.find(CurrentWeapon:get_full_name(), "BP_Kuzmich_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Kuzmich_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(13.000, 143.000, -18.000))
						
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000
						FPHands_RelativeRotation.Yaw = 0.000	
						
						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000

						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Krepysh/AM_PlayerCharacterHands_Krepysh_DamageMeleeHitHardFallReaction_Montage.AM_PlayerCharacterHands_Krepysh_DamageMeleeHitHardFallReaction_Montage")
						pawn:StopAnimMontage(stunned_anim)								
						
						bIsOneHandedWeapon = false
					elseif string.find(CurrentWeapon:get_full_name(), "BP_ShotgunKS23_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonShotgunKS23_C") or string.find(CurrentWeapon:get_full_name(), "BP_ShotgunKS23_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_ShotgunKS23_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
						mesh_state:set_location_offset(temp_vec3f:set(0.000, 160.000, -25.000))
												
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000
						FPHands_RelativeRotation.Yaw = 0.000
						
						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000
						
						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Krepysh/AM_PlayerCharacterHands_Krepysh_DamageMeleeHitHardFallReaction_Montage.AM_PlayerCharacterHands_Krepysh_DamageMeleeHitHardFallReaction_Montage")
						pawn:StopAnimMontage(stunned_anim)		
						
						bIsOneHandedWeapon = false
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Shved_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonShved_C") or string.find(CurrentWeapon:get_full_name(), "BP_Shved_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Shved_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.133, -0.175, 0.623))
						mesh_state:set_location_offset(temp_vec3f:set(18.000, 148.000, -34.000))	
						
						if montage == nil or string.find(tostring(montage:get_full_name()), "AM_Shved_Hands_Release_Left_Attack") or string.find(tostring(montage:get_full_name()), "AM_Shved_Hands_Right_Rise_Montage") or string.find(tostring(montage:get_full_name()), "AM_Shved_PlayerHands_Right_Attack") then
							-- Rotate right arm to adjust the angle the melee weapon is held
							FPHands_RelativeLocation.X = 20.000
							FPHands_RelativeLocation.Y = -20.000
							FPHands_RelativeLocation.Z = -3.370
							FPHands_RelativeRotation.Pitch = 0.000
							FPHands_RelativeRotation.Roll = 0.000
							FPHands_RelativeRotation.Yaw = 38.000
						else
							-- Reset right arm for strong melee attacks
							FPHands_RelativeLocation.X = 0.000
							FPHands_RelativeLocation.Y = 0.000
							FPHands_RelativeLocation.Z = 0.000
							FPHands_RelativeRotation.Pitch = 0.000
							FPHands_RelativeRotation.Roll = 0.000
							FPHands_RelativeRotation.Yaw = 0.000						
						end
												
						-- Adjust weapon scale and position for better VR comfort
						CurrentWeapon_Mesh_RelativeLocation.Z = 30.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 0.500
											
						local heavy_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Shved/AM_PlayerCharacterHands_ShvedToggleAttack_Hold.AM_PlayerCharacterHands_ShvedToggleAttack_Hold")
						pawn:StopAnimMontage(heavy_anim)							
						
						local attack_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Shved/AM_Shved_PlayerHands_Right_Attack.AM_Shved_PlayerHands_Right_Attack")
						pawn:StopAnimMontage(attack_anim)
						
						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Zvezdochka/AM_PlayerCharacterHands_ZvezdochkaMeeleeHitHardFall.AM_PlayerCharacterHands_ZvezdochkaMeeleeHitHardFall")
						pawn:StopAnimMontage(stunned_anim)
						
						bIsOneHandedWeapon = true -- Set flag to hide left arm bones	
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Snejok_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonSnejok_C") or string.find(CurrentWeapon:get_full_name(), "BP_Snejok_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Snejok_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.133, -0.175, 0.623))
						mesh_state:set_location_offset(temp_vec3f:set(18.000, 148.000, -34.000))	

						if montage == nil or string.find(tostring(montage:get_full_name()), "AM_Snejok_Hands_Release_Left_Attack") or string.find(tostring(montage:get_full_name()), "AM_Snejok_Hands_Right_Rise") or string.find(tostring(montage:get_full_name()), "AM_Snejok_PlayerHands_Right_Attack") then
							-- Rotate right arm to adjust the angle the melee weapon is held
							FPHands_RelativeLocation.X = 20.000
							FPHands_RelativeLocation.Y = -20.000
							FPHands_RelativeLocation.Z = -3.370
							FPHands_RelativeRotation.Pitch = 0.000
							FPHands_RelativeRotation.Roll = 0.000
							FPHands_RelativeRotation.Yaw = 38.000
						else
							-- Reset right arm for strong melee attacks
							FPHands_RelativeLocation.X = 0.000
							FPHands_RelativeLocation.Y = 0.000
							FPHands_RelativeLocation.Z = 0.000
							FPHands_RelativeRotation.Pitch = 0.000
							FPHands_RelativeRotation.Roll = 0.000
							FPHands_RelativeRotation.Yaw = 0.000						
						end
						
						-- Adjust weapon scale and position for better VR comfort
						CurrentWeapon_Mesh_RelativeLocation.Z = 30.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 0.750
						
						local heavy_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/MeleeAttacks/TwoHanded/Snejok/AM_PlayerCharacterHands_Snejok_Toggle_Hold.AM_PlayerCharacterHands_Snejok_Toggle_Hold")
						pawn:StopAnimMontage(heavy_anim)						
						
						local attack_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Snejok/AM_Snejok_PlayerHands_Right_Attack.AM_Snejok_PlayerHands_Right_Attack")
						pawn:StopAnimMontage(attack_anim)							
						
						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Zvezdochka/AM_PlayerCharacterHands_ZvezdochkaMeeleeHitHardFall.AM_PlayerCharacterHands_ZvezdochkaMeeleeHitHardFall")
						pawn:StopAnimMontage(stunned_anim)
												
						bIsOneHandedWeapon = true -- Set flag to hide left arm bones					
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Dominator_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonDominator_C") or string.find(CurrentWeapon:get_full_name(), "BP_Dominator_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Dominator_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, -0.060, 0.000)) -- This gun requires a rotation offset or projectiles will fire at an incorrect angle
						mesh_state:set_location_offset(temp_vec3f:set(15.000, 150.000, -15.000))
						
						FPHands_RelativeLocation.X = 0.000
						FPHands_RelativeLocation.Y = 0.000
						FPHands_RelativeLocation.Z = 0.000
						FPHands_RelativeRotation.Pitch = 0.000
						FPHands_RelativeRotation.Roll = 0.000
						FPHands_RelativeRotation.Yaw = 0.000
						
						CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
						CurrentWeapon_Mesh_RelativeScale3D.Z = 1.000

						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Krepysh/AM_PlayerCharacterHands_Krepysh_DamageMeleeHitHardFallReaction_Montage.AM_PlayerCharacterHands_Krepysh_DamageMeleeHitHardFallReaction_Montage")
						pawn:StopAnimMontage(stunned_anim)						
						
						bIsOneHandedWeapon = false
					elseif string.find(CurrentWeapon:get_full_name(), "BP_Zvezdochka_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonZvezdochka_C") or string.find(CurrentWeapon:get_full_name(), "BP_Zvezdochka_DLC3_C") or string.find(CurrentWeapon:get_full_name(), "BP_Zvezdochka_Limbo_C") then
						mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 1.000)) -- Adjust Z angle for better VR comfort 
						mesh_state:set_location_offset(temp_vec3f:set(18.000, 148.000, -34.000))
					
						if montage == nil or string.find(tostring(montage:get_full_name()), "AM_PlayerCharacterHands_Zvezdochka_Attack_Left") or string.find(tostring(montage:get_full_name()), "AM_PlayerCharacterHands_Zvezdochka_Attack_Right_Rise") or string.find(tostring(montage:get_full_name()), "AM_PlayerCharacterHands_Zvezdochka_Attack_Right") then
							-- Rotate right arm to adjust the angle the melee weapon is held
							FPHands_RelativeLocation.X = 20.000
							FPHands_RelativeLocation.Y = -20.000
							FPHands_RelativeLocation.Z = -3.370
							FPHands_RelativeRotation.Pitch = 0.000
							FPHands_RelativeRotation.Roll = 0.000
							FPHands_RelativeRotation.Yaw = 38.000
						else
							-- Reset right arm for strong melee attacks
							FPHands_RelativeLocation.X = 0.000
							FPHands_RelativeLocation.Y = 0.000
							FPHands_RelativeLocation.Z = 0.000
							FPHands_RelativeRotation.Pitch = 0.000
							FPHands_RelativeRotation.Roll = 0.000
							FPHands_RelativeRotation.Yaw = 0.000						
						end
						
						if montage ~= nil then
							if string.find(tostring(montage:get_full_name()), "AM_PlayerCharacterHands_Zvezdochka_LiftAttack_Release") then
								-- Reset weapon scale and position for heavy melee animations
								CurrentWeapon_Mesh_RelativeLocation.Z = 0.000
								CurrentWeapon_Mesh_RelativeScale3D.Z = 0.750
							else
								-- Adjust weapon scale and position for better VR comfort
								CurrentWeapon_Mesh_RelativeLocation.Z = 30.000
								CurrentWeapon_Mesh_RelativeScale3D.Z = 0.750					
							end
						else	
							-- Adjust weapon scale and position for better VR comfort
							CurrentWeapon_Mesh_RelativeLocation.Z = 30.000
							CurrentWeapon_Mesh_RelativeScale3D.Z = 0.750	
						end
						
						local heavy_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/MeleeAttacks/TwoHanded/Zvezdochka/Secondary/AM_PlayerCharacterHands_Zvezdochka_ToggleAttack_Hold.AM_PlayerCharacterHands_Zvezdochka_ToggleAttack_Hold")
						pawn:StopAnimMontage(heavy_anim)						
						
						local attack_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/MeleeAttacks/TwoHanded/Zvezdochka/Primary/AM_PlayerCharacterHands_Zvezdochka_Attack_Right.AM_PlayerCharacterHands_Zvezdochka_Attack_Right")
						pawn:StopAnimMontage(attack_anim)	
						
						local stunned_anim = find_required_object("AnimMontage /Game/Development/Characters/PlayerCharacterHands/Animations/Zvezdochka/AM_PlayerCharacterHands_ZvezdochkaMeeleeHitHardFall.AM_PlayerCharacterHands_ZvezdochkaMeeleeHitHardFall")
						pawn:StopAnimMontage(stunned_anim)
						
						bIsOneHandedWeapon = true -- Set flag to hide left arm bones
					end	
				end
			else		
				-- Offsets when no items are equipped
				mesh_state:set_rotation_offset(temp_vec3f:set(0.000, 0.000, 0.000))
				
				if string.find(tostring(pawn:get_full_name()), "BP_PlayerCharacter_C") then
					mesh_state:set_location_offset(temp_vec3f:set(-23.000, 153.000, -40.000)) -- Base game offsets
				else
					mesh_state:set_location_offset(temp_vec3f:set(50.000, 90.000, 0.000)) -- DLC offsets
				end				
				
				FPHands_RelativeLocation.X = 0.000
				FPHands_RelativeLocation.Y = 0.000
				FPHands_RelativeLocation.Z = 0.000
				FPHands_RelativeRotation.Pitch = 0.000
				FPHands_RelativeRotation.Roll = 0.000
				FPHands_RelativeRotation.Yaw = 0.000
				
				bIsOneHandedWeapon = false
			end
			
			if CurrentWeapon ~= nil then
				--print(CurrentWeapon:get_full_name())
			end
			
			-- Add logic to dynamically disable the left and right hand meshes as needed.
			-- When the player has no equipped items, the left and right hand meshes are hidden.
			-- When the player is using the left handed Polymer glove, the right hand mesh is hidden and weapons are disabled.
			-- When the player is not using the left handed Polymer glove, the left hand mesh is hidden and the right hand mesh and weapon are enabled.
			-- When the player is using a two handed weapon, the left and right hand meshes and weapon are enabled.
            -- All meshes are visible during cutscenes.			
			
			-- Update mesh visibility during cutscene/montage state changes or any time the player has a weapon or glove equipped
			if bIsNotCutscene == false or player_anim_instance.CurrentWeapon ~= nil or bIsPolymer == true or bIsPickupAnim == true then 
			
				if bIsPolymer == true and bIsNotCutscene == true and bIsPickupAnim == false then -- Check if the glove is active outside of cutscenes
				
					 -- Show left arm only when left handed Polymer glove active
					FPHands:UnHideBoneByName(kismet_string_library:Conv_StringToName("upperarm_l"))
					FPHands:HideBoneByName(kismet_string_library:Conv_StringToName("upperarm_r")) 
					
					-- Hide right handed weapon meshes
					if FPWeapon ~= null then FPWeapon:SetVisibility(false) end
					
					if BlueprintCreatedComponents ~= nil then
					
						for i, comp in ipairs(BlueprintCreatedComponents) do
							if string.find(tostring(comp:get_full_name()), "SK_") or string.find(tostring(comp:get_full_name()), "Mag") then
								--print(comp:get_fname():to_string())
								if comp ~= null then comp:SetVisibility(false) end							
							end
						end	
						
					end						
					
					if FPWeapon ~= null then FPWeapon:HideBoneByName(kismet_string_library:Conv_StringToName("forearm")) end
					if FPWeapon ~= null then FPWeapon:HideBoneByName(kismet_string_library:Conv_StringToName("RootComponent")) end
					
				else
			
					-- Show weapon meshes
					if FPWeapon ~= null then FPWeapon:SetVisibility(true) end
					
					ak47_collimator_scope = false
					ak47_thermal_scope = false
					pm_collimator_scope = false
					pm_thermal_scope = false
					shotgun_thermal_scope = false
					shotgun_collimator_scope = false
					bIsChargingWeapon = false
					
					if BlueprintCreatedComponents ~= nil then
					
						for i, comp in ipairs(BlueprintCreatedComponents) do
						    if string.find(tostring(comp:get_full_name()), "SK_Kuzmich_Magazine") then
								if comp ~= null then comp:SetVisibility(false) end
								bIsChargingWeapon = true
							elseif string.find(tostring(comp:get_full_name()), "SK_") or string.find(tostring(comp:get_full_name()), "Mag") then
								--print(comp:get_full_name())
								if comp ~= null then comp:SetVisibility(true) end		
								
								-- Check for meshes which require custom attachment offsets for 6DOF motion controls
								SkeletalMesh = comp.SkeletalMesh	
								if SkeletalMesh ~= null then 		
									if string.find(tostring(SkeletalMesh:get_full_name()), "AK47_Aim04") then
									  --print("Collimator scope active")							
									  ak47_collimator_scope = true	
									elseif string.find(tostring(SkeletalMesh:get_full_name()), "AK47_Aim03") then	
									  --print("Thermal scope active")							
									  ak47_thermal_scope = true	
									elseif string.find(tostring(SkeletalMesh:get_full_name()), "SK_PM_Aim04") then
									  --print("Collimator scope active")							
									  pm_collimator_scope = true	
									elseif string.find(tostring(SkeletalMesh:get_full_name()), "SK_PM_Aim03") then
									  --print("Thermal scope active")							
									  pm_thermal_scope = true
									elseif string.find(tostring(SkeletalMesh:get_full_name()), "SK_ShotgunKS23_Aim_04") then
									  --print("Collimator scope active")							
									  shotgun_collimator_scope = true	
									elseif string.find(tostring(SkeletalMesh:get_full_name()), "SK_ShotgunKS23_Aim_03") then
									  --print("Thermal scope active")							
									  shotgun_thermal_scope = true											  
									elseif string.find(tostring(SkeletalMesh:get_full_name()), "SK_Electro_BarrelEnd01") or string.find(tostring(SkeletalMesh:get_full_name()), "SK_Electro_BarrelEnd02")  then	
									  bIsChargingWeapon = true			
									end
								end													
							end							
						end
					end	
					
					if bIsOneHandedWeapon == false then 					
						if TWO_HANDED_MODELS == true or bIsReload == true or bIsReloadOneHand == true or bIsNotCutscene == false or bIsMenu == true or bIsChargingWeaponActive == true or bIsSwimming == true or bIsConsumeItem == true or bIsClimbing == true or bIsDelayWhipActive == true or bIsWhipActive == true or bIsPolymer == true or bForcePolymer == true or bIsPickupAnim == true then
							FPHands:UnHideBoneByName(kismet_string_library:Conv_StringToName("upperarm_l")) -- Show both arms when two handed weapon meshes are enabled OR offhand is active when two handed weapon meshes are disabled
							FPHands:UnHideBoneByName(kismet_string_library:Conv_StringToName("upperarm_r"))					
						else
							FPHands:HideBoneByName(kismet_string_library:Conv_StringToName("upperarm_l")) -- Hide left arm when two handed weapons are equipped
							FPHands:UnHideBoneByName(kismet_string_library:Conv_StringToName("upperarm_r"))	
						end		
					elseif bIsOneHandedWeapon == true then						
						if bIsReload == true or bIsReloadOneHand == true or bIsNotCutscene == false or bIsMenu == true or bIsChargingWeaponActive == true or bIsSwimming == true or bIsConsumeItem == true or bIsClimbing == true or bIsDelayWhipActive == true or bIsWhipActive == true or bIsPolymer == true or bForcePolymer == true or bIsPickupAnim == true then
							FPHands:UnHideBoneByName(kismet_string_library:Conv_StringToName("upperarm_l")) -- Show both arms when two handed weapon meshes are enabled OR offhand is active when two handed weapon meshes are disabled
							FPHands:UnHideBoneByName(kismet_string_library:Conv_StringToName("upperarm_r"))					
						else
							FPHands:HideBoneByName(kismet_string_library:Conv_StringToName("upperarm_l")) -- Hide left arm when one handed weapons are equipped
							FPHands:UnHideBoneByName(kismet_string_library:Conv_StringToName("upperarm_r"))
						end		
					end
				end	
				
			else
				FPHands:HideBoneByName(kismet_string_library:Conv_StringToName("upperarm_l")) -- Hide arms if player has no items equipped
				FPHands:HideBoneByName(kismet_string_library:Conv_StringToName("upperarm_r"))
			end
			
			if bIsLevelLoaded == true and bForceRebind == true then
				hookLevelFunctions() -- Hook functions on level load
				bIsLevelLoaded = false		
				bIsMainMenu = false -- If level has loaded we are no longer in the menu		
			end
		
		elseif string.find(tostring(pawn:get_full_name()), "Moskvich") then		
			vr.set_mod_value("VR_AimUsePawnControlRotation", "0") -- Vehicle fix
			
			UEVR_UObjectHook.set_disabled(true) 
			vr.set_mod_value("VR_AimMethod", "0") 
			vr.set_mod_value("VR_MovementOrientation", "0")
			vr.set_mod_value("VR_RoomscaleMovement", "0")
			vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
			vr.set_mod_value("VR_CameraRightOffset", "0.000000")
			vr.set_mod_value("UI_X_Offset", "0.000000")
			vr.set_mod_value("UI_Y_Offset", "0.000000")
			vr.set_mod_value("UI_Distance", "2.000000")
			vr.set_mod_value("VR_DecoupledPitch", "1")
			vr.set_mod_value("VR_LerpCameraPitch", "false")
			vr.set_mod_value("VR_LerpCameraYaw", "false")
			vr.set_mod_value("VR_LerpCameraRoll", "false")
			vr.set_mod_value("VR_LerpCameraSpeed", "0.000000")		
		end	
	
	else	
		-- Reset flags when no pawn detected
		bForceRebind = false		
	end
end)
		
uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)

	if (state ~= nil) then
	
		-- Toggle GUI with LT 
		if state.Gamepad.bLeftTrigger >= 200 and bGuiToggleOnetime == false then
			GuiToggleTime = os.clock()
			bGuiToggleEnable = true
			bGuiToggleOnetime = true
		end
			
		if state.Gamepad.bLeftTrigger == 0  then
			GuiToggleTime = 0
			bGuiToggleEnable = false
			bGuiToggleOnetime = false
		end
			
		if os.clock() - GuiToggleTime >= 3 and bGuiToggleEnable == true then 
			local controller_component = pawn.Controller
			controller_component:ToggleHUDVisibility()
			print("ToggleHUDVisibility")
			bGuiToggleEnable = false
		end
		
		-- Enable walking via RS when scanning with left controller
		if bIsScanning == true then
			state.Gamepad.sThumbLY=state.Gamepad.sThumbRY
		end		
	
		-- Check if inputs depressed for Polymer glove
		if state.Gamepad.wButtons & XINPUT_GAMEPAD_B ~= 0 or state.Gamepad.wButtons & XINPUT_GAMEPAD_Y ~= 0 or state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER ~= 0  then
			bForcePolymer = true -- Set flag to force left handed attachments in case IsPolimerActiveSkill boolean is unavailable
		else
			bForcePolymer = false
		end			
	
		-- Disable weapon inputs when using Polymer glove; This allows right handed weapon meshes to be safely hidden when using left handed glove attachments.
		if bIsPolymer == true then
			state.Gamepad.bLeftTrigger = 0
			state.Gamepad.bRightTrigger = 0
		end
		
		-- Rebind controls during normal gameplay
		if bForceRebind == true and bIsMouse == false then
		
			-- Swap B & RG (Rebind left glove controls to left controller, vanilla button prompts will no longer match VR controllers)			
			if state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER ~= 0 and block_t1 == false then
				block_t2 = true
				state.Gamepad.wButtons = state.Gamepad.wButtons & ~(XINPUT_GAMEPAD_RIGHT_SHOULDER)
				state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_B
				--print("RG to B Button")
			else
				block_t2 = false
			end

			if state.Gamepad.wButtons & XINPUT_GAMEPAD_B ~= 0 and block_t2 == false then
				block_t1 = true
				state.Gamepad.wButtons = state.Gamepad.wButtons & ~(XINPUT_GAMEPAD_B)
				state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_RIGHT_SHOULDER
				--print("B to RG Button")
			else
				block_t1 = false
			end	
		else

			-- Swap B & X (If left glove not available we have more available inputs, swap B & X so vanilla button prompts match VR controllers)			
			if state.Gamepad.wButtons & XINPUT_GAMEPAD_X ~= 0 and block_t1 == false then
				block_t2 = true
				state.Gamepad.wButtons = state.Gamepad.wButtons & ~(XINPUT_GAMEPAD_X)
				state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_B
				--print("X to B Button")
			else
				block_t2 = false
			end

			if state.Gamepad.wButtons & XINPUT_GAMEPAD_B ~= 0 and block_t2 == false then
				block_t1 = true
				state.Gamepad.wButtons = state.Gamepad.wButtons & ~(XINPUT_GAMEPAD_B)
				state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_X
				--print("B to X Button")
			else
				block_t1 = false
			end	
		end
		
		if bIsNoraSkills == true then		
			-- Terminate Nora when player presses input to exit
			if state.Gamepad.wButtons & XINPUT_GAMEPAD_B ~= 0 or state.Gamepad.wButtons & XINPUT_GAMEPAD_START ~= 0 then				
				bIsNoraSkills = false
			end			
		end	

		if bIsOneHandedWeapon == true then		
            -- Swap light melee with heavy attacks as light melee is now handled with physical gestures	
			if state.Gamepad.bRightTrigger ~= 0 then	
				state.Gamepad.bLeftTrigger = 200 			
				state.Gamepad.bRightTrigger = 0
			end			
		end			
		
		
		
		if bIsWorldMap  == true then
		-- Terminate World Map state when player presses input to exit
			if state.Gamepad.wButtons & XINPUT_GAMEPAD_B ~= 0 or state.Gamepad.wButtons & XINPUT_GAMEPAD_START ~= 0 or state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER ~= 0 or state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER ~= 0 then				
				bIsWorldMap = false
			end			
		end				

		-- Force Aiming on ranged weapons to fix weapon angles
		if bIsRangeWeapon == true then	
			if bForceAimReset == false then 
			    if string.find(CurrentWeapon:get_full_name(), "BP_Dominator_C") or string.find(CurrentWeapon:get_full_name(), "BP_NewtonDominator_C") or string.find(CurrentWeapon:get_full_name(), "BP_Dominator_DLC3_C") then
					-- Do nothing
				elseif bIsChargingWeapon == false and bIsPolymer == false then
					state.Gamepad.bLeftTrigger = 200 -- Force aiming if the player equips a weapon which is not a charging weapon as the game binds aiming and charging to the same input.  
				end                                  -- For charging weapons, we will use the Aim input for charging, and aiming will be forced via an animation Blueprint PAK mod.
				
				if bIsChargingWeapon == true and state.Gamepad.bLeftTrigger >= 200 then
					bIsChargingWeaponActive = true
				else
					bIsChargingWeaponActive = false
				end
													 
			else 
				state.Gamepad.bLeftTrigger = 0 -- Reset Aiming after swapping weapons					
				
				if os.clock() - AimResetTime >= 1 then 
					bForceAimReset = false -- Clear flag after timer expires
					print("Reset aiming...")
				end

			end
		else
			-- Enable melee attacks with physical gestures. 
			-- Note that bRightTrigger does not emulate right trigger, weapon animations are disabled via PAK modding so the right trigger input will immediately trigger AnimNotify_MeleeHit and AnimNotify_DirectMeleeHit which allows us to emulate collision based melee.
			if SwingingFast == true and bIsPolymer == false then				
				if state.Gamepad.bLeftTrigger >= 200 then 
					state.Gamepad.bLeftTrigger = 0 -- Heavy melee swing
				else	
					state.Gamepad.bRightTrigger = 200 -- Light melee swing
				end	
			end		
		end
	end
end)







