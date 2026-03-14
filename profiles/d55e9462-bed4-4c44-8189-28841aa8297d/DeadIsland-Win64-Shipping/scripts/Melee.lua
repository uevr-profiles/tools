--[[
    Dead Island 2 - Melee Script (Final Version - Correct Path Check)
    
    This version uses the correct method to get an object's asset path
    by first getting its class, and then getting the full name of the class.
--]]

-- =========================================================================
-- SETUP
-- =========================================================================
local api = uevr.api
local vr = uevr.params.vr
local sdk = uevr.sdk

-- =========================================================================
-- CONFIGURATION & STATE
-- =========================================================================
local DEBUG_MODE = true -- Change to false to turn off debug prints.
local MELEE_SWING_THRESHOLD = 2.5
local swinging_fast = false

local melee_motion_data = {
    right_hand_pos_raw = UEVR_Vector3f.new(),
    right_hand_q_raw = UEVR_Quaternionf.new(),
    right_hand_pos = Vector3f.new(0, 0, 0),
    last_right_hand_raw_pos = Vector3f.new(0, 0, 0),
    first_tick = true,
}

-- =========================================================================
-- INITIALIZATION
-- =========================================================================
sdk.callbacks.on_script_reset(function()
    print("DI2 Melee Script (Correct Path Check) - Initialized.")
    melee_motion_data.first_tick = true
    swinging_fast = false
end)

-- =========================================================================
-- MAIN LOGIC (Per-Frame)
-- =========================================================================
sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    if delta == 0 then return end

    -- Motion detection logic
    local right_controller_idx = vr.get_right_controller_index()
    if not right_controller_idx then return end
    vr.get_pose(right_controller_idx, melee_motion_data.right_hand_pos_raw, melee_motion_data.right_hand_q_raw)
    melee_motion_data.right_hand_pos:set(melee_motion_data.right_hand_pos_raw.x, melee_motion_data.right_hand_pos_raw.y, melee_motion_data.right_hand_pos_raw.z)
    if melee_motion_data.first_tick then
        melee_motion_data.last_right_hand_raw_pos:set(melee_motion_data.right_hand_pos.x, melee_motion_data.right_hand_pos.y, melee_motion_data.right_hand_pos.z)
        melee_motion_data.first_tick = false
        return
    end
    local velocity = (melee_motion_data.right_hand_pos - melee_motion_data.last_right_hand_raw_pos) * (1 / delta)
    melee_motion_data.last_right_hand_raw_pos:set(melee_motion_data.right_hand_pos_raw.x, melee_motion_data.right_hand_pos_raw.y, melee_motion_data.right_hand_pos_raw.z)
    local vel_len = velocity:length()
    
    swinging_fast = false 
    
    if vel_len >= MELEE_SWING_THRESHOLD then
        local player_pawn = api:get_local_pawn(0)
        if not player_pawn then return end
        
        local equipped_weapon_actor = nil

        -- Full logic to get the equipped weapon actor
        if player_pawn.BPC_Player_PaperDoll then
            local paper_doll_comp = player_pawn.BPC_Player_PaperDoll
            local active_slot_name = paper_doll_comp.WeaponSlot
            
            if active_slot_name then
                local equippable_component = paper_doll_comp:GetEquippableAssignedToSlot(active_slot_name)
                if equippable_component then
                    equipped_weapon_actor = equippable_component:get_outer()
                end
            end
        end
        
        if equipped_weapon_actor then
            -- !! THE FINAL AND CORRECT CHECK !!
            -- 1. Get the weapon's CLASS object.
            local weapon_class = equipped_weapon_actor:get_class()
            
            if weapon_class then
                -- 2. Get the full name of the CLASS, which is the asset path.
                local weapon_asset_path = weapon_class:get_full_name()
                
                if DEBUG_MODE then
                    print("____________________________________________________")
                    print("DEBUG: Equipped Weapon Actor: " .. equipped_weapon_actor:get_fname():to_string())
                    print("DEBUG: Equipped Weapon ASSET PATH: " .. weapon_asset_path)
                end

                -- 3. Check if the asset path contains the "/Melee/" folder string.
                --    NOTE: You found that some weapons are in "/MeleeWeapons/", others might just be in "/Melee/".
                --    Searching for "/Melee/" is a broader and safer check.
                if string.find(weapon_asset_path, "/Melee/") then
                    swinging_fast = true
                    if DEBUG_MODE then print("DEBUG: SUCCESS! Melee weapon confirmed by asset path.") end
                else
                    if DEBUG_MODE then print("DEBUG: This does not appear to be a melee weapon based on its asset path.") end
                end
            end
        end
    end
end)
        
-- =========================================================================
-- INPUT SIMULATION
-- =========================================================================
sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if (state ~= nil) and swinging_fast then
        if state.Gamepad.bRightTrigger >= 200 then 
            state.Gamepad.bRightTrigger = 0
        else    
            state.Gamepad.bRightTrigger = 200
        end         
    end
end)