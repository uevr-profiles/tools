local uevrUtils = require('libs/uevr_utils')
local hands = require('libs/hands')
local controllers = require('libs/controllers')
local handsCreated = false
local handsRequired = true
local isHoldingWeapon = false
local leftHandCqcKnife = false
local attachementName = "WP_None"
local handsVisible = false
local hideHands = false
local twoHandsHandling = false

-- function on_level_change(level)
-- 	-- controllers.createController(0)
-- 	-- controllers.createController(1)
-- 	-- hands.reset()

	
-- 	local paramsFile = 'hands_parameters' -- found in the [game profile]/data directory
-- 	local configName = 'Main' -- the name you gave your config
-- 	local animationName = 'Shared' -- the name you gave your animation
-- 	hands.createFromConfig(paramsFile, configName, animationName)

-- 	if (hands.exists()) then
-- 		uevr.api:dispatch_custom_event("HandsCreated", "1")
-- 		handsCreated = true
-- 	end
-- end

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	if hands.exists() and not handsVisible and not hideHands then
		hands.hideHands(false);
	end

	if hands.exists() and not handsRequired then
		hands.destroyHands()
		uevr.api:dispatch_custom_event("HandsCreated", "0")
		handsCreated = false
		return
	end

	if hands.exists() and handsRequired then
		handsCreated = true
		return
	end

	if handsRequired and not hands.exists() then
		controllers.createController(0)
		controllers.createController(1)
		hands.reset()

		local paramsFile = 'hands_parameters' -- found in the [game profile]/data directory
		local configName = 'Main'      -- the name you gave your config
		local animationName = 'Shared' -- the name you gave your animation
		hands.createFromConfig(paramsFile, configName, animationName)
		hands.hideHands(true)
		handsVisible = false
		if (hands.exists()) then
			uevr.api:dispatch_custom_event("HandsCreated", "1")
			-- print(hands.getHandComponent(Handed.Right).get_full_name())
			handsCreated = true
		end
	end
end)

local function two_hands_weapon_handling(attachementName)
	print("two_hands_weapon_handling")
	if attachementName == "wp_gove" or
		attachementName == "wp_mk22" or
		attachementName == "wp_easygun" or
		attachementName == "wp_saarmy" then
		hands.handleInputIndividualHand(false, "wp_gove2", Handed.Left, false, false, true)
	elseif attachementName == "wp_patriotpostol" then
		hands.handleInputIndividualHand(false, "wp_patriotpostol2", Handed.Left, false, false, true)
	elseif attachementName == "wp_scorpion" then
		hands.handleInputIndividualHand(false, "wp_scorpion2", Handed.Left, false, false, true)
	elseif attachementName == "wp_m63" or
		attachementName == "wp_m16a1" then
		hands.handleInputIndividualHand(false, "wp_m63_2", Handed.Left, false, false, true)
	elseif attachementName == "wp_ithaca" then
		hands.handleInputIndividualHand(false, "wp_ithaca2", Handed.Left, false, false, true)
	elseif attachementName == "wp_akm" or
		attachementName == "wp_dragnov" or
		attachementName == "wp_mosinnagant" then
		hands.handleInputIndividualHand(false, "wp_akm2", Handed.Left, false, false, true)
	elseif attachementName == "wp_rpg" then
		hands.handleInputIndividualHand(false, "wp_rpg2", Handed.Left, false, false, true)
	else
		hands.handleInputIndividualHand(false, attachementName, Handed.Left, false, false, true)
	end
end

uevr.sdk.callbacks.on_lua_event(function(event_name, event_string)
	if event_name == "HideHands" then
		if event_string == "1" then
			hands.hideHands(true)
			hideHands = true
			handsVisible = false
		else
			hands.hideHands(false)
			hideHands = false
			handsVisible = true
		end
	end

    if event_name == "PlayerTookControl" then
		if event_string =="1" then
			print("Player took Control lua")
			handsRequired = true
		else
			print("Player lost Control lua")
			handsRequired = false
		end
	end

	if event_name == "CurrentWeapon" then
		if hands.exists() then
			attachementName = event_string	
			if event_string == "wp_none" then
				isHoldingWeapon = false
				hands.handleInputIndividualHand(true, false, Handed.Right, false, false, false)
				hands.handleInputIndividualHand(true, false, Handed.Left, false, false, false)
			elseif (twoHandsHandling) then
				two_hands_weapon_handling(event_string)
			else
				isHoldingWeapon = true
				hands.handleInputIndividualHand(false, attachementName, Handed.Right, false, false, false)
				if attachementName == "wp_gove" or
				attachementName == "wp_mk22" or
				attachementName == "wp_easygun" then
					leftHandCqcKnife = true;
					hands.handleInputIndividualHand(false, "wp_gove", Handed.Left, false, false, false)
				elseif attachementName == "wp_tnt" then
					leftHandCqcKnife = false;
					hands.handleInputIndividualHand(false, attachementName, Handed.Left, false, false, false)
				else
					leftHandCqcKnife = false;
					hands.handleInputIndividualHand(true, false, Handed.Left, false, false, false)
				end
			end
		end
	end

	if event_name == "TwoHandsHandling" then
		print(event_string)
		if event_string == "1" then
			twoHandsHandling = true
			two_hands_weapon_handling(attachementName)
		else
			twoHandsHandling = false
			if attachementName == "wp_gove" or
				attachementName == "wp_mk22" or
				attachementName == "wp_easygun" then
				hands.handleInputIndividualHand(false, "wp_gove", Handed.Left, false, false, false)
			else
				hands.handleInputIndividualHand(true, false, Handed.Left, false, false, false)
			end
		end
	end

	if event_name == "HandsReset" then
		hands.destroyHands()
		handsCreated = false
	end
end)

function on_xinput_get_state(retval, user_index, state)
	if hands.exists() then
		if isHoldingWeapon then
			if leftHandCqcKnife then
				if twoHandsHandling then
					hands.handleInputIndividualHand(state, "wp_gove2", Handed.Left, false, false, true)
				else
					hands.handleInputIndividualHand(state, "wp_gove", Handed.Left, false, false, false)
				end
			elseif attachementName == "wp_tnt" then
				hands.handleInputIndividualHand(state, attachementName, Handed.Left, false, false, false)
			elseif not twoHandsHandling then
				hands.handleInputIndividualHand(state, false, Handed.Left, false, false, false)
			end
			hands.handleInputIndividualHand(state, attachementName, Handed.Right, false, false, false)
		else
			hands.handleInputIndividualHand(state, false, Handed.Right, false, false, false)
			hands.handleInputIndividualHand(state, false, Handed.Left, false, false, false)
		end
	end
end
