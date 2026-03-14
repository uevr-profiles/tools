--#####################################
--# Z-Target style hold implemented   #
--# for Luna Abyss by help im a ghost # 
--# Alices Lullaby Menu Fix - CJ117   # 
--# Contributions by BudWheizzah      #
--# Added Cutscene Detection          #
--# Added Cutscene lock               #
--# Long LT press for lock/recenter   #
--# Some code improvements            #
--#####################################

local api = uevr.api
local params = uevr.params
local callbacks = params.sdk.callbacks

local LongpressDelay = 0 
local ThumbstickThreshold = 25000
local TriggerThreshold = 128

local CutsceneLock = false
local PlayState = 0
local PlayerControllerState = 0
local PlayerCount = 0

local justPressedCombo = false
local comboPressed = 0
local longpressHeld = false
local countLongpress = 0

local game_engine_class = api:find_uobject("Class /Script/Engine.GameEngine")
local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
local game_instance = nil

local player = nil
local player_controller = nil

-- Backup for parameters so we can restore on release
local backupParams = {
  aim_method = nil,
  decoupled_pitch = nil,
  roomscale_movement = nil
}
local leftTriggerPreviouslyPressed = false

local function reset_height(recenter)

	local base = UEVR_Vector3f.new()
	params.vr.get_standing_origin(base)
	local hmd_index = params.vr.get_hmd_index()
	local hmd_pos = UEVR_Vector3f.new()
	local hmd_rot = UEVR_Quaternionf.new()
	params.vr.get_pose(hmd_index, hmd_pos, hmd_rot)
	base.x = hmd_pos.x
	base.y = hmd_pos.y
	base.z = hmd_pos.z
	params.vr.set_standing_origin(base)

	if recenter == true then
		params.vr.recenter_view()
	end

end

local function toggle_roomscale(tog)

	if tog == true then

		params.vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
		UEVR_UObjectHook.set_disabled(false)
		params.vr.set_aim_method(2)
		-- Enabling RS movement allows player to move physically while keeping a correct rotation center
		params.vr.set_mod_value("VR_RoomscaleMovement","true");

	else

		params.vr.set_mod_value("VR_DecoupledPitchUIAdjust", "true")
		UEVR_UObjectHook.set_disabled(true)
		params.vr.set_aim_method(0)
		-- Ironically, disabling RS movement allows RS movement in cutscenes
		params.vr.set_mod_value("VR_RoomscaleMovement","false");

	end

end

params.vr.set_aim_method(0)
reset_height(false)

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)

	if longpressHeld == true then
		countLongpress = countLongpress + delta
	else
		countLongpress = 0
	end

	local pawn = api:get_local_pawn(0)

	if pawn == nil or string.find(pawn:get_full_name(), "MainMenu") or string.find(pawn:get_full_name(), "UMGSequencePlayer") then

		-- Title screen tick actions
		if PlayState ~= 1 then

			-- Disable hooks and set PlayState to 1
			params.functions.log_info("[HelperScript] Menu detected! PlayState 1, PlayerControllerState 0.")
			PlayState = 1
			toggle_roomscale(false)

		end

--		if PlayState ~= 3 then
--
--			-- Disable hooks and set PlayState to 3
--			params.functions.log_info("[HelperScript] Cutscene detected! PlayState 3, PlayerControllerState 0.")
--			PlayState = 3
--			toggle_roomscale(false)

--		end

		PlayerControllerState = 0
		-- End title screen tick actions

	else

		-- In-game tick actions

		-- Fetch player controller and player pawn for cutscene detection
		game_instance = game_engine.GameInstance
		if game_instance ~= nil then
			PlayerCount = #game_instance.LocalPlayers
			if PlayerCount > 0 then
				player = game_instance.LocalPlayers[1]
			else
				params.functions.log_error("[HelperScript] Zero players found! Critical! Skipping tick")
				return
			end
		else
			params.functions.log_error("[HelperScript] Game instance is null! Critical! Skipping tick")
			return
		end

		if player~=nil then

			player_controller = player.PlayerController

			if PlayerControllerState ~= 1 then
				params.functions.log_info("[HelperScript] We found the player object! PlayerControllerState 1.")
				if player_controller == nil then
					params.functions.log_error("[HelperScript] Player controller is Null!")
				end
			end 

			PlayerControllerState = 1 --checked and not null

		else

			player_controller = nil
			if PlayerControllerState ~= 2 then
				params.functions.log_error("[HelperScript] Player instance is null! PlayerControllerState 2. Count is " .. #game_instance.LocalPlayers)
			end 

			PlayerControllerState = 2 --checked and null

		end

		-- can move by default
		local playerIsBlocked = false

		if player_controller ~= nil then
			-- player_controller:IsLookInputIgnored() Seems like the right call, because notes allow rotation, cutscenes don't
			playerIsBlocked = player_controller:IsLookInputIgnored()
		end

		if playerIsBlocked == true and PlayState ~= 3 then

				params.functions.log_info("[HelperScript] Cutscene detected! PlayState 3")
				PlayState = 3

				toggle_roomscale(false)

		elseif playerIsBlocked == false and PlayState ~= 2 then

				params.functions.log_info("[HelperScript] Gameplay detected! PlayState 2")

				-- Weird error checks
				if player_controller == nil then
					params.functions.log_error("[HelperScript] Player controller is Null still in state 2, not normal!")
				end

				PlayState = 2
				toggle_roomscale(true)

		end
		-- End in-game tick actions

	end

end)

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)

  -- Detect current trigger pressed state
  local leftTriggerPressed = state.Gamepad.bLeftTrigger > TriggerThreshold
  
  -- On press down (transition)
  if leftTriggerPressed and not leftTriggerPreviouslyPressed then
    -- Backup current VR params
    local function safe_get_aim_method()
      if params.vr.get_aim_method then
        local status, value = pcall(params.vr.get_aim_method)
        if status and value ~= nil then
          return value
        end
      end
      return 0 -- default fallback
    end

    backupParams.aim_method = safe_get_aim_method()

    local function safe_get_mod_value(name)
      if params.vr.get_mod_value then
        local status, value = pcall(params.vr.get_mod_value, name)
        if status and value ~= nil then
          return value
        end
      end
      return "false"  -- safe default fallback 
    end

    backupParams.decoupled_pitch = safe_get_mod_value("VR_DecoupledPitchUIAdjust")
    backupParams.roomscale_movement = safe_get_mod_value("VR_RoomscaleMovement")


    -- Apply toggle parameters while held
    params.vr.set_aim_method(2)
    params.vr.set_mod_value("VR_DecoupledPitchUIAdjust", "false")
    params.vr.set_mod_value("VR_RoomscaleMovement", "true")
    UEVR_UObjectHook.set_disabled(false)
    toggle_roomscale(false)
    reset_height(true)

    params.functions.log_info("[HelperScript] Left Trigger pressed: applied VR params toggle")
    params.functions.log_info("[HelperScript] Toggle cutscene lock by long press")

  elseif not leftTriggerPressed and leftTriggerPreviouslyPressed then
    -- On release (transition), restore backed up params
    if backupParams.aim_method ~= nil then
      params.vr.set_aim_method(backupParams.aim_method)
      params.vr.set_mod_value("VR_DecoupledPitchUIAdjust", backupParams.decoupled_pitch)
      params.vr.set_mod_value("VR_RoomscaleMovement", backupParams.roomscale_movement)
      toggle_roomscale(true)
      if backupParams.roomscale_movement == "true" then
        UEVR_UObjectHook.set_disabled(false)
      else
        UEVR_UObjectHook.set_disabled(false)
      end

      params.functions.log_info("[HelperScript] Left Trigger released: restored VR params")
      params.functions.log_info("[HelperScript] Disable cutscene lock!")

      -- Clear backup so we only restore once
      backupParams = {
       aim_method = nil,
       decoupled_pitch = nil,
       roomscale_movement = nil
      }
    end
  end

  leftTriggerPreviouslyPressed = leftTriggerPressed


  comboPressed = 0

  --register combo press globally for all states
  if leftTriggerPressed then
    longpressHeld = true

    --long press timer
    if countLongpress > LongpressDelay then
      comboPressed = 1 -- room scale toggle 
    elseif state.Gamepad.sThumbRY > ThumbstickThreshold then
      comboPressed = 2 -- recenter
    end
  else
    longpressHeld = false
  end

  --For play state 1 (menu) perform re-center on combo press
  if state ~= nil and comboPressed > 0 and justPressedCombo == false then
    if comboPressed == 1 then

        -- Long press Left Trigger (Title screen only)
        params.functions.log_info("[HelperScript] Perform re-center by long press")
        reset_height(true)	

    elseif comboPressed == 2 then

      -- Quick press Left Trigger + Right Stick Up recenter/reset standing
      params.functions.log_info("[HelperScript] Perform re-center by binding")
      reset_height(true)

    end

    justPressedCombo = true
    countLongpress = 0

  end

  --reset justPressedCombo only when combo is released
  if justPressedCombo == true and comboPressed == 0 and longpressHeld == false then

    justPressedCombo = false
    countLongpress = 0

  end

end)