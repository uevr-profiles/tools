local uevrUtils = require('libs/uevr_utils')
local hands = require('libs/hands')
local controllers = require('libs/controllers')
require(".\\Subsystems\\GlobalCustomData")
require(".\\Subsystems\\GlobalData")
function on_level_change(level)
	controllers.createController(0)
	controllers.createController(1)
	hands.reset()

	local paramsFile = 'hands_parameters' -- found in the [game profile]/data directory
	local configName = 'Main' -- the name you gave your config
	local animationName = 'Shared' -- the name you gave your animation
	hands.createFromConfig(paramsFile, configName, animationName)
--	local LHandM=hands.getHandComponent(Handed.Left)
--	print(LHandM:get_full_name())
--	LHandM:SetMaterial(0,HandMat)
	--hands.getHandComponent(Handed.Right):SetMaterial(MatHand)
end
local InvisL=false


function getCustomHandComponent(key)
  return HandSceneComp
end


function on_xinput_get_state(retval, user_index, state)
	if hands.exists() then
		local isHoldingWeapon = false
		local hand = Handed.Right
		hands.handleInput(state, isHoldingWeapon, hand)
		
		
		
		
		if (lShoulder or ReloadMontage) and not InvisL then
			InvisL=true
			hands.getHandComponent(Handed.Right):SetVisibility(false)
			hands.getHandComponent(Handed.Left):SetVisibility(false)
			pawn.Mesh:UnHideBoneByName("clavicle_l")
		elseif not lShoulder and not ReloadMontage and InvisL then
			hands.getHandComponent(Handed.Left):SetVisibility(true)
			InvisL=false
			pawn.Mesh:HideBoneByName("clavicle_l")
		end
	end
end