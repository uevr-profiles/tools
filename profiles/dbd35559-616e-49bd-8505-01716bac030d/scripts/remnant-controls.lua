--#########################################
-- Preferences
--#########################################
local swapltrb = true
local melee_swing = false
local right_stick_big_vert_deadzone = true
-- Define the threshold for the swipe detection. Bigger is more sensitive
local swipe_threshold = 0.05

--#########################################
-- Dont edit below this line
--#########################################

local api = uevr.api
local vr = uevr.params.vr


-- Initialize variables
local combo_state = 0          -- 0 = no combo, 1 = right-to-left, 2 = left-to-right, 3 = up-to-down
local combo_timer = 0          -- Tracks time elapsed for the combo
local combo_threshold = 60     -- Frames allowed between combo inputs (adjust based on frame rate)
local last_position = nil      -- Tracks the last controller position
local frame_counter = 0        -- Simulated frame counter (incremented each callback)
local swipe_left = false
local is_in_menu = false
local back_down = false
local start_down = false
local b_down = false
local in_main_menu = false
local close_menu_flag = 0
local hooked_can_save = false

local function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        error("Cannot find " .. name)
        return nil
    end

    return obj
end

local hooked_infinite_ammo = false

local function set_infinite_ammo()
    local ranged_weapon_class = api:find_uobject("Class /Script/GunfireRuntime.RangedWeapon")
    local has_infinite_clip_fn = ranged_weapon_class:find_function("GetAmmo")
    
    if (has_infinite_clip_fn ~= nil and hooked_infinite_ammo == false) then
        print("GetAmmo function found")
        hooked_infinite_ammo = true
        has_infinite_clip_fn:hook_ptr(nil, function(fn, obj, locals, result)
            result = 200
            print("Set GetAmmo ammo to 200")
        end)
    end

end

local function hook_save()
    --Here we set the object and find the function we want to work with
    local gunfire_class = api:find_uobject("Class /Script/GunfireRuntime.GameInstanceGunfire")
    local can_save_fn = gunfire_class:find_function("CanSave")

    --Once UEVR finds the function, this will trigger.
    --Once triggered, the commands within "introplay_fn:hook_ptr" will run when the function is triggered in-game
    if can_save_fn ~= nil and hooked_can_save == false then
        hooked_can_save = true
        print("Hooking!")
        can_save_fn:hook_ptr(nil, function(fn, obj, locals, result)
            result = true
            print("Calling can save hook")
        end)
    end
end

local function First_P()
	local tpawn = api:get_local_pawn(0)
	tpawn.RemnantStateCamera.CurrentCamera.Distance = 0
	tpawn.RemnantStateCamera.CurrentCamera.FadeCharacterDistance = 0
	tpawn.RemnantStateCamera.CurrentCamera.LeftRightOffset = 0
end

local function Third_P()
	local tpawn = api:get_local_pawn(0)
	tpawn.RemnantStateCamera.CurrentCamera.Distance = 180
	tpawn.RemnantStateCamera.CurrentCamera.FadeCharacterDistance = 50
	tpawn.RemnantStateCamera.CurrentCamera.LeftRightOffset = 55
end

-- bool can_save_pre(fn: UFunction*, obj: UObject*, locals: StructObject*, result: void*)
local game_engine_class = find_required_object("Class /Script/Engine.GameEngine")

function ModifyRecoil (Weapon)
    if Weapon == nil then return end

    Mode = Weapon:GetWeaponMode()
    if Mode == nil then return end
    
    Item = Mode.CachedProfile;
    if Item == nil then return end
    
    print("ModifyRecoil still here")
	Item.SwayScalarScope = 0
	Item.SwayScalarAim = 0
	Item.FiringSpreadIncrement = 0
	Item.RecoilVertical = 0
	Item.RecoilHorizontalMin = 0
	Item.RecoilHorizontalMax = 0
	Item.FiringSpreadAimMoveMin = 0
	Item.FiringSpreadAimMoveMax = 0
	Item.FiringSpreadAimMin = 0
	Item.FiringSpreadAimMax = 0
end



uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    local is_in_cinematic = false
    local player_instance = api:get_player_controller(0)
    if player_instance ~= nil then
        is_in_cinematic = player_instance:IsInCinematic()
        if is_in_cinematic == true then
            vr.set_mod_value("FrameworkConfig_AlwaysShowCursor", "false")
            UEVR_UObjectHook.set_disabled(true)
        elseif UEVR_UObjectHook.is_disabled() == true then
            UEVR_UObjectHook.set_disabled(false)
        end
    end

    -- if both start and back are together, clear start.
    if ((state.Gamepad.wButtons & XINPUT_GAMEPAD_BACK) ~= 0) and 
       ((state.Gamepad.wButtons & XINPUT_GAMEPAD_START) ~= 0) then
        -- Clear the START bit
        state.Gamepad.wButtons = state.Gamepad.wButtons & ~XINPUT_GAMEPAD_START
    end
    
    -- if we are at main menu, bail out.
    local game_instance_gf = find_required_object("Class /Script/GunfireRuntime.GameInstanceGunfire")
    local game_instance_gf_instance = UEVR_UObjectHook.get_first_object_by_class(game_instance_gf)
    local local_in_main_menu = game_instance_gf_instance:IsInMainMenuLevel()
    if (local_in_main_menu == true) then
        vr.set_mod_value("FrameworkConfig_AlwaysShowCursor", "true")
        return
    end
    
    -- map screen
    local minimap = find_required_object("Class /Script/GunfireRuntime.ExplorableMinimapManager")
    local minimap_instance = UEVR_UObjectHook.get_first_object_by_class(minimap)
    local is_map_fullscreen = minimap_instance:IsFullscreenMinimapActive()
    
    local uihud = find_required_object("Class /Script/GunfireRuntime.UIHud")
    local uihud_instance = UEVR_UObjectHook.get_first_object_by_class(uihud)
    local is_in_menu = not uihud_instance:IsVisible()

    --local is_in_gameplay = game_instance_gf_instance:IsInGameplay()
    
    if (is_in_menu == true) then
    
        local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
        local viewport = game_engine.GameViewport
        if viewport == nil then
            print("Viewport is nil")
            vr.set_mod_value("FrameworkConfig_AlwaysShowCursor", "false")
           return
        end

        local world = viewport.World
        if world == nil then
            print("World is nil")
            vr.set_mod_value("FrameworkConfig_AlwaysShowCursor", "false")
            return
        end
        
        local inputmgr = find_required_object("Class /Script/GunfireRuntime.InputDeviceManager")
        local inputmgr_instance = UEVR_UObjectHook.get_first_object_by_class(inputmgr)
        local using_cursor = inputmgr_instance:IsUsingGamepadAnalogCursor(world)
        
        if (using_cursor == true) then
            is_in_menu = true
            vr.set_mod_value("FrameworkConfig_AlwaysShowCursor", "true")
        end
    else
        vr.set_mod_value("FrameworkConfig_AlwaysShowCursor", "false")
    end
    
    if (is_in_menu == true or is_map_fullscreen == true) then
        return
    end
    
	
	--/Script/GunfireRuntime.Equipment
	--Equipment.SetInHand
	-- Put gun in hand if aiming but (more importantly) remove it if not
	local pawn = api:get_local_pawn(0)
    if pawn ~= nil then
		local equipped_weapon = pawn:GetCurrentRangedWeapon()
		if equipped_weapon ~= nil then
			local IsAiming = equipped_weapon:IsAiming()
			if IsAiming then
				First_P()
				equipped_weapon:SetInHand(true)
                ModifyRecoil(equipped_weapon)
			else
				UEVR_UObjectHook.set_disabled(true)
				Third_P()
				equipped_weapon:SetInHand(false)
			end
		end
        pawn.bUseControllerRotationPitch = true
        pawn.bUseControllerRotationRoll = true
		pawn.bUseControllerRotationYaw = (state.Gamepad.sThumbRX > 5000 or state.Gamepad.sThumbRX < -5000)
	end
	
    
    -- add massive right stick deadzone
    if (right_stick_big_vert_deadzone) then 
        if (state.Gamepad.sThumbRY > -32000 and state.Gamepad.sThumbRY < 32000) then
            state.Gamepad.sThumbRY = 0
        end
    end 
    
    local LTDown = state.Gamepad.bLeftTrigger > 200
    
    if swapltrb then
        local RBDown = (state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER) > 0
        
        -- Swap left trigger with right shoulder button
        state.Gamepad.bLeftTrigger = RBDown and 255 or 0
        state.Gamepad.wButtons = LTDown and (state.Gamepad.wButtons | XINPUT_GAMEPAD_RIGHT_SHOULDER) or (state.Gamepad.wButtons & ~XINPUT_GAMEPAD_RIGHT_SHOULDER)
        LTDown = state.Gamepad.bLeftTrigger > 200
    end


    -- Gesture detection and combo logic
    if (melee_swing) then
        if (LTDown == false) then
            state.Gamepad.bRightTrigger = 0
            
            local right_controller_index = vr.get_right_controller_index()
            if right_controller_index ~= -1 then
                -- Get the current position of the right controller
                local current_position = UEVR_Vector3f.new()
                local right_controller_rotation = UEVR_Quaternionf.new()
                vr.get_pose(right_controller_index, current_position, right_controller_rotation)

                -- Check gestures
                if last_position then
                    local delta_x = current_position.x - last_position.x
                    local delta_y = current_position.y - last_position.y * 0.6 -- lower threshld for vertical
                    -- Determine gesture based on combo state
                    if combo_state == 0 then
                        -- Right-to-Left gesture to start combo
                        if delta_x * -1 >= swipe_threshold then
                            combo_state = 1
                            combo_timer = frame_counter
                            state.Gamepad.bRightTrigger = 255
                        end
                    elseif combo_state == 1 then
                        -- Left-to-Right gesture for second combo hit
                        if frame_counter - combo_timer <= combo_threshold and delta_x >= swipe_threshold then
                            combo_state = 2
                            combo_timer = frame_counter
                            state.Gamepad.bRightTrigger = 255
                        elseif frame_counter - combo_timer > combo_threshold then
                            -- Reset combo if too much time has passed
                            combo_state = 0
                        end
                    elseif combo_state == 2 then
                        -- Up-to-Down gesture for third combo hit
                        if frame_counter - combo_timer <= combo_threshold and delta_y * -1 >= swipe_threshold then
                            combo_state = 0
                            combo_timer = frame_counter
                            state.Gamepad.bRightTrigger = 255
                        elseif frame_counter - combo_timer > combo_threshold then
                            -- Reset combo if too much time has passed
                            combo_state = 0
                        end
                    end
                end

                -- Update last position
                last_position = current_position
            end

            -- Reset combo if LT is held down
            if LTDown then
                combo_state = 0
            end

            -- Increment frame counter (simulating a frame-by-frame environment)
            frame_counter = frame_counter + 1
        else
            combo_state = 0
            frame_counter = 0
        end
    end
end)
