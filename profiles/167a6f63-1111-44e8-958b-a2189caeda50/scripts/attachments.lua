local uevrUtils = require('libs/uevr_utils')
local attachments = require('libs/attachments')
local controllers = require('libs/controllers')
local hands = require('libs/hands')
uevrUtils.setDeveloperMode(true)
attachments.setLogLevel(LogLevel.Debug)
uevrUtils.setLogLevel(LogLevel.Debug)


-- You will need to find the way to retrieve the weapon skeletal mesh or static mesh
-- for your specific game and replace getWeaponMesh() function with your own implemetation

-- replace this --
attachments.init()
function getWeaponMesh()
local pawn = uevrUtils.get_local_pawn()
    if not pawn then
	return
    end
	local melee_root = nil
	local ranged_root = nil
	local attached_actors = {}
	if pawn then
		pawn:GetAttachedActors(attached_actors, true)
		for i, actor in ipairs(attached_actors) do
			if uevrUtils.getValid(actor) and not string.find(actor:get_full_name(),"DESTROYED") then
				local melee_mesh_component = actor.WeaponMesh
				local ranged_mesh_component = actor.SkeletalMesh
				if melee_mesh_component and melee_mesh_component.bOnlyOwnerSee 
					and not string.find(melee_mesh_component:get_full_name(), "DESTROYED") then
					melee_root = melee_mesh_component
					-- print ("A:" .. melee_root:get_full_name())
					break 
				end
				if ranged_mesh_component and ranged_mesh_component.bOnlyOwnerSee 
					and not string.find(ranged_mesh_component:get_full_name(), "DESTROYED") then
					ranged_root = ranged_mesh_component
					-- print ("B:" .. ranged_root:get_full_name())
					break 
				end
			end
		end
		return melee_root or ranged_root
	end
end

attachments.registerOnGripUpdateCallback(function()	
	-- return getWeaponMesh()
	-- return getWeaponMesh(), controllers.getController(Handed.Right)
	return getWeaponMesh(), hands.getHandComponent(Handed.Right)
end)

