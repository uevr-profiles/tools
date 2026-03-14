local uevrUtils = require('libs/uevr_utils')
local hands = require('libs/hands')
local controllers = require('libs/controllers')
local api = uevr.api

-- --- New Global State Variables ---
local prevViewTarget = nil
local is_hands_active = true

local function create_hands()
    if not is_hands_active then return end
    controllers.createController(0)
    controllers.createController(1)
    
    -- If hands already exist, just show them
    if hands.exists() then
        hands.hideHands(false)
        print("[HandsSetup] Hands shown.")
        return
    end
    
    -- Otherwise create new hands
    hands.reset()
    local paramsFile = 'hands_parameters'
    local configName = 'Main'
    local animationName = 'Shared'
    hands.createFromConfig(paramsFile, configName, animationName)
    
    print("[HandsSetup] Hands configuration created/re-created.")
end

local function destroy_hands()
    -- Hide hands instead of destroying to prevent auto-recreation
    hands.hideHands(true)
    print("[HandsSetup] Hands hidden.")
end

-- --- Object Hook State Detection ---
local prevHookDisabledState = false

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    -- Check current object hook disabled state
    local isHookDisabled = UEVR_UObjectHook.is_disabled()
    
    -- Only act if the state has changed
    if isHookDisabled ~= prevHookDisabledState then
        if isHookDisabled then
            -- Object hooks just became disabled: destroy hands
            if is_hands_active then
                is_hands_active = false
                destroy_hands()
                print("[HandsSetup] Object hooks disabled - hands destroyed.")
            end
        else
            -- Object hooks just became enabled: recreate hands
            if not is_hands_active then
                is_hands_active = true
                hands.destroyHands()
                hands.reset()
                print("[HandsSetup] Object hooks enabled - hands recreated.")
            end
        end
        
        prevHookDisabledState = isHookDisabled
    end
end)

-- --- Original Hands Logic (Adjusted) ---

function on_level_change(level)
    -- Only create hands if they don't already exist AND they are allowed to be active.
    if is_hands_active and not hands.exists() then
        create_hands()
        print("[HandsSetup] Hands loaded automatically on Level Change: " .. tostring(level))
    end
end

uevrUtils.setInterval(5000, function()
    -- Skip if hands are not supposed to be active
    if not is_hands_active then return end
    
    if controllers.controllerExists(Handed.Left, false) == false or controllers.controllerExists(Handed.Right, false) == false then
        controllers.createController(Handed.Left)
        controllers.createController(Handed.Right)
        hands.destroyHands()
        hands.reset()
    end
end)

function on_lazy_poll()
    -- Only create hands if they are allowed to be active
    if not is_hands_active then return end
    
    -- Check if hands have not been created yet.
    if not hands.exists() then
        local paramsFile = 'hands_parameters'
        local configName = 'Main'
        local animationName = 'Shared'
        
        -- Create the hands only if they don't already exist.
        hands.createFromConfig(paramsFile, configName, animationName)
    end
end

function on_xinput_get_state(retval, user_index, state)
	-- Ensure hands exist and are allowed to be active before trying to process input for them
	if is_hands_active and hands.exists() then
		local isHoldingWeapon = false
		local hand = Handed.Right
        -- Note: A complete script would call handleInput for both Handed.Left and Handed.Right
		hands.handleInput(state, isHoldingWeapon, hand)
	end
end