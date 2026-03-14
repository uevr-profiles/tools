local api = uevr.api
local vr = uevr.params.vr
local params = uevr.params
local callbacks = params.sdk.callbacks

local CurrentWeapon = nil
local is_sliding = nil
local is_kicking = nil
local swinging_fast = nil
local player_has_control = nil

local melee_data = {
    right_hand_pos_raw = UEVR_Vector3f.new(),
    right_hand_q_raw = UEVR_Quaternionf.new(),
    right_hand_pos = Vector3f.new(0, 0, 0),
    last_right_hand_raw_pos = Vector3f.new(0, 0, 0),
    last_time_messed_with_attack_request = 0.0,
    first = true,
}

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
		swinging_fast = vel_len >= 2.5
	end
	
    local pawn = api:get_local_pawn(0)
    if string.find(tostring(pawn:get_full_name()), "MenuPawn_C") then
		vr.set_mod_value("VR_AimMethod", "0")
		vr.set_mod_value("VR_RoomscaleMovement", "0")
    else
        if pawn ~= nil then
			
			--Cutscene detection
			player_has_control = pawn.PlayerHasControl			

			local IsPlaying = false
			local GameMode_C = api:find_uobject("BlueprintGeneratedClass /Game/Blueprint/Game/BaseGameMode.BaseGameMode_C")
			if GameMode_C ~= nil then
				local GameModeInstances = GameMode_C:get_objects_matching(false)

				for i, instance in ipairs(GameModeInstances) do
					--print("Checking instance ", i)
					if instance.CurrentCutscene ~= nil then
						--print("Found IsPlaying to be true", i)
						IsPlaying = true
						break
					end
				end
			end
			
			if player_has_control == false then			
			   UEVR_UObjectHook.set_disabled(true)
			   vr.set_mod_value("VR_AimMethod", "0")
			   vr.set_mod_value("VR_AimUsePawnControlRotation", "0")
			   vr.set_mod_value("VR_RoomscaleMovement", "1")
			else
			   	if IsPlaying == false then			
					UEVR_UObjectHook.set_disabled(false)
					vr.set_mod_value("VR_AimMethod", "2")
					vr.set_mod_value("VR_AimUsePawnControlRotation", "1")
					vr.set_mod_value("VR_RoomscaleMovement", "1")
				else
					UEVR_UObjectHook.set_disabled(true)
					vr.set_mod_value("VR_AimMethod", "0")
					vr.set_mod_value("VR_AimUsePawnControlRotation", "1")
					vr.set_mod_value("VR_RoomscaleMovement", "0")
				end
			end						
		
			--FPMesh
            local Fpmesh = pawn.MeshLegs

            is_sliding = pawn.bIsSliding
            is_kicking = pawn.IsKicking
            
            if is_sliding or is_kicking then
               Fpmesh:SetVisibility(true)
            else
               Fpmesh:SetVisibility(false)
            end
        end
    end
end)
		
uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)

	if (state ~= nil) then
	
		-- Lock camera offsets
		vr.set_mod_value("VR_CameraForwardOffset", "0.000000")
		vr.set_mod_value("VR_CameraRightOffset", "0.000000")
		vr.set_mod_value("VR_CameraUpOffset", "0.000000")
		
		-- Swap X & B
	--	if state.Gamepad.wButtons & 0x4000 ~= 0 and block_b == false then
    --        block_x = true
    --        state.Gamepad.wButtons = state.Gamepad.wButtons & ~(XINPUT_GAMEPAD_X)
    --        state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_B
    --        --print("X to B Button")
	--
    --    else
    --        block_x = false
    --    end
	--
    --    if state.Gamepad.wButtons & 0x2000 ~= 0 and block_x == false then
    --        block_b = true
    --        state.Gamepad.wButtons = state.Gamepad.wButtons & ~(XINPUT_GAMEPAD_B)
    --        state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_X
    --        --print("B to X Button")
    --    else
    --        block_b = false
    --    end
		
		-- Get pawn	
		local pawn = api:get_local_pawn(0)
		
		-- Sprinting fix
		
				
		-- Melee gestures					
		if pawn ~= nil then
            CurrentWeapon = pawn.CurrentWeapon
            
            if CurrentWeapon ~= nil then
                if swinging_fast == true then
                    if string.find(CurrentWeapon:get_full_name(), "BP_Sword_C") then
                        state.Gamepad.bRightTrigger = 200
                    else 
                        state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_RIGHT_THUMB
                    end
                end	
            end
        end
	end
end)