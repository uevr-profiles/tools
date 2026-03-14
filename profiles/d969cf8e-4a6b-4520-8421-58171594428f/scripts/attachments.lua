local uevrUtils = require('libs/uevr_utils')
local attachments = require('libs/attachments')
local controllers = require('libs/controllers')

uevrUtils.setDeveloperMode(false)
attachments.setLogLevel(LogLevel.Debug)
uevrUtils.setLogLevel(LogLevel.Debug)

attachments.init()

function getWeaponMesh()
	if uevrUtils.getValid(pawn) ~= nil and pawn.GetCurrentWeapon ~= nil then
		local currentWeapon = pawn:GetCurrentWeapon()
		if currentWeapon ~= nil then return currentWeapon.RootComponent end
	end
	return nil
end

attachments.registerOnGripUpdateCallback(function()	
	return getWeaponMesh()
	--return getWeaponMesh(), controllers.getController(Handed.Right)
end)

