local uevrUtils = require("libs/uevr_utils")

local M = {}

local modifiers = nil
local count = 0

function M.onLevelChange()
end

function M.update()
	modifiers = uevrUtils.find_all_instances("Class /Script/Engine.CameraModifier", false)
	if modifiers ~= nil then
		--print(#modifiers, "modifiers turned off")
		for i, mod in ipairs(modifiers) do
			if uevrUtils.getValid(mod) ~= nil and mod.DisableModifier ~= nil then
				mod:DisableModifier(true)
				--print(mod:get_full_name(), "disabled")
			end
		end
	end
end

return M

--[[
not
Class /Script/GameplayCameras.CameraAnimationCameraModifier
Class /Script/Game.RotationLimitCameraModifier

CameraModifier_CameraShake /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.CameraModifier_CameraShake_0 disabled
CameraAnimationCameraModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.CameraAnimationCameraModifier_0   disabled
RecoilCameraModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.RecoilCameraModifier_0     disabled
MagnetismCameraModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.MagnetismCameraModifier_0       disabled
AimingCameraModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.AimingCameraModifier_0     disabled
RotationLimitCameraModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.RotationLimitCameraModifier_0       disabled
FramerateIndependentRotation /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.FramerateIndependentRotation_0     disabled
PanOnEnemyWhileWalkingModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.PanOnEnemyWhileWalkingModifier_0 disabled
PanOnEnemyWhileWalkingModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.PanOnEnemyWhileWalkingModifier_1 disabled
9

8       modifiers turned off
CameraModifier_CameraShake /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.CameraModifier_CameraShake_0 disabled
CameraAnimationCameraModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.CameraAnimationCameraModifier_0   disabled
RecoilCameraModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.RecoilCameraModifier_0     disabled
MagnetismCameraModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.MagnetismCameraModifier_0       disabled
AimingCameraModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.AimingCameraModifier_0     disabled
FramerateIndependentRotation /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.FramerateIndependentRotation_0     disabled
RotationLimitCameraModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.RotationLimitCameraModifier_0       disabled
PanOnEnemyWhileWalkingModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.PanOnEnemyWhileWalkingModifier_0 disabled


FramerateIndependentRotation /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.FramerateIndependentRotation_0     disabled
CameraModifier_CameraShake /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.CameraModifier_CameraShake_0 disabled
PanOnEnemyWhileWalkingModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.PanOnEnemyWhileWalkingModifier_0 disabled
CameraAnimationCameraModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.CameraAnimationCameraModifier_0   disabled
RecoilCameraModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.RecoilCameraModifier_0     disabled
MagnetismCameraModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.MagnetismCameraModifier_0       disabled
AimingCameraModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.AimingCameraModifier_0     disabled
RotationLimitCameraModifier /Game/Maps/DLC/DLC_L09_ED209_ALL.DLC_L09_ED209_ALL.PersistentLevel.BP_MyPlayerCameraManager_C_0.RotationLimitCameraModifier_0       disabled

]]--
	--Handled in camera_modifiers.lua
	-- --Fix the shooting gallery
	-- local modifiers = uevrUtils.find_all_instances("Class /Script/Game.RotationLimitCameraModifier", false)
	-- for i, mesh in ipairs(modifiers) do
		-- if mesh:get_fname():to_string() == "RotationLimitCameraModifier_0" then
			-- mesh:DisableModifier(true)
			-- break
		-- end
	-- end
	--uevr.api:get_player_controller(0).PlayerCameraManager.CachedCameraShakeMod:DisableModifier(true)
	
	-- --Turn off any auto-aiming
	-- local modifiers = uevrUtils.find_all_instances("Class /Script/Engine.CameraModifier", false)
	-- print("Here",modifiers)
	-- if modifiers ~= nil then
		-- print(#modifiers, "modifiers turned off")
		-- for i, mod in ipairs(modifiers) do
			-- mod:DisableModifier(true)
			-- print(mod:get_full_name(), "disabled")
		-- end
	-- end
