local api = uevr.api
local vr = uevr.params.vr

local config_filename = "exp33modconfig.txt"
local config_data = nil
local first_person = 1
local enable_lumen = 0
local toggle_fp_dpad_left = 1
local toggle_lumen_dpad_right = 1
local enable_fog = 1

local function write_config()
	config_data = "first_person=" .. tostring(first_person) .. "\n" ..
	              "enable_lumen=" .. tostring(enable_lumen) .. "\n" ..
				  "toggle_fp_dpad_left=" .. tostring(toggle_fp_dpad_left) .. "\n" ..
				  "toggle_lumen_dpad_right=" .. tostring(toggle_lumen_dpad_right) .. "\n" ..
				  "enable_fog=" .. tostring(enable_fog) .. "\n"
    fs.write(config_filename, config_data)
end

local function read_config()
    print("reading config")
    config_data = fs.read(config_filename)
    if config_data then -- Check if file was read successfully
        print("config read")
        for key, value in config_data:gmatch("([^=]+)=([^\n]+)\n?") do
            print("parsing key:", key, "value:", value)
            if key == "first_person" then
                first_person = (value == "true" or value == "1") and 1 or 0
            elseif key == "enable_lumen" then
                enable_lumen = (value == "true" or value == "1") and 1 or 0
            elseif key == "toggle_fp_dpad_left" then
                toggle_fp_dpad_left = tonumber(value) or 0
            elseif key == "toggle_lumen_dpad_right" then
                toggle_lumen_dpad_right = tonumber(value) or 0
            elseif key == "enable_fog" then
                enable_fog = tonumber(value) or 0
            end

            print ("Config: first_person", first_person, "enable_lumen", enable_lumen)
        end
    else
        print("Error: Could not read config file.")
    end
end

function set_cvar_int(cvar, value)
    local console_manager = api:get_console_manager()
    
    local var = console_manager:find_variable(cvar)
    if(var ~= nil) then
        var:set_int(value)
    end
end

function set_cvar_float(cvar, value)
    local console_manager = api:get_console_manager()
    
    local var = console_manager:find_variable(cvar)
    if(var ~= nil) then
        print("setting float", value)
        var:set_float(value)
    else   
        print("cvar does not exist: ", cvar)
    end
end

function toggle_lumen()
	if enable_lumen == 1 then
		set_cvar_int("r.Lumen.Reflections.Temporal", 1)
		set_cvar_int("r.Lumen.Reflections.Allow", 1)
		set_cvar_int("r.Lumen.DiffuseIndirect.Allow", 1)
		set_cvar_int("r.Nanite.AllowComputeMaterials", 1)
		set_cvar_int("r.Nanite.AllowLegacyMaterials", 1)
		set_cvar_int("r.DFDistanceScale", 2)
		set_cvar_int("r.FRXGI.Allow", 0)
        set_cvar_float("r.TonemapperGamma", 0.000000)
	else
		set_cvar_int("r.Lumen.Reflections.Temporal", 0)
		set_cvar_int("r.Lumen.Reflections.Allow", 0)
		set_cvar_int("r.Lumen.DiffuseIndirect.Allow", 0)
		set_cvar_int("r.Nanite.AllowComputeMaterials", 0)
		set_cvar_int("r.Nanite.AllowLegacyMaterials", 0)
		set_cvar_int("r.DFDistanceScale", 1)
		set_cvar_int("r.FRXGI.Allow", 1)
        set_cvar_float("r.TonemapperGamma", 1.800000)
	end
end

function toggle_fog()
	if enable_fog == 1 then
		set_cvar_int("r.Fog", 1)
	else
		set_cvar_int("r.Fog", 0)
	end
end


read_config()
toggle_fog()
toggle_lumen()

local function disable_object_hooks(state)
    if state ~= obj_hook_disabled then
        obj_hook_disabled = state
        UEVR_UObjectHook.set_disabled(state)
    end
end

if first_person == 0 then
	disable_object_hooks(true)
end

uevr.sdk.callbacks.on_draw_ui(function()
    imgui.text("Clair Obscure Mod Settings")
    imgui.text("Mod by markmon and hookman")
    imgui.text("")
    local needs_save = false
    local changed, new_value

    -- Use more concise boolean conversion
    local first_person_bool = (first_person == 1)
    local enable_lumen_bool = (enable_lumen == 1)
    local enable_fog_bool = (enable_fog == 1)
    local toggle_fp_dpad_left_bool = (toggle_fp_dpad_left == 1)
    local toggle_lumen_dpad_right_bool = (toggle_lumen_dpad_right == 1)

    changed, new_value = imgui.checkbox("First Person Exploration:", first_person_bool)
    if changed then
        needs_save = true
        first_person = new_value and 1 or 0 -- Correctly use new_value
        prevViewTarget = nil
        if first_person == 0 then
            disable_object_hooks(true)
        end
    end

    changed, new_value = imgui.checkbox("Left DPAD toggles first / third person:", toggle_fp_dpad_left_bool)
    if changed then
        needs_save = true
        toggle_fp_dpad_left = new_value and 1 or 0 -- Correctly use new_value
    end

    changed, new_value = imgui.checkbox("Enable Fog:", enable_fog_bool)
    if changed then
        needs_save = true
        enable_fog = new_value and 1 or 0 -- Correctly use new_value
        toggle_fog() -- Consider moving this outside the draw callback
    end

    changed, new_value = imgui.checkbox("Enable Lumen (big hit on performance, much better lighting):", enable_lumen_bool)
    if changed then
        needs_save = true
        enable_lumen = new_value and 1 or 0 -- Correctly use new_value
        toggle_lumen() -- Consider moving this outside the draw callback
    end

    changed, new_value = imgui.checkbox("Right DPAD toggles lumen:", toggle_lumen_dpad_right_bool)
    if changed then
        needs_save = true
        toggle_lumen_dpad_right = new_value and 1 or 0 -- Correctly use new_value
    end

    if needs_save then
        write_config()
    end
end)

----------------------------------------------------
-- CONFIGURATION: Set the button to use for toggle
----------------------------------------------------
local first_person_toggle_button = XINPUT_GAMEPAD_DPAD_LEFT
local lumen_toggle_button = XINPUT_GAMEPAD_DPAD_RIGHT
----------------------------------------------------

-- State variables
local is_uobjecthook_enabled = false -- Start tracking as DISABLED
local fp_button_was_pressed = false -- Track previous state for the chosen button
local lumen_button_was_pressed = false -- Track previous state for the chosen button
local obj_hook_disabled = nil -- start in unknown state

-- Input Callback Function
local function process_input(retval, user_index, state)
    -- Only process for user 0 (primary controller) and if state is valid
    if state == nil or state.Gamepad == nil then
        return
    end

    -- Check if the configured button is currently pressed using bitwise AND
    local fp_button_pressed = (state.Gamepad.wButtons & first_person_toggle_button) ~= 0
    local lumen_button_pressed = (state.Gamepad.wButtons & lumen_toggle_button) ~= 0

    if toggle_fp_dpad_left ~= 1 then fp_button_pressed = false end
    if toggle_lumen_dpad_right ~= 1 then lumen_button_pressed = false end
    
    -- Check if the button was just pressed (state changed from false to true)
    if fp_button_pressed and not fp_button_was_pressed then
        -- Toggle the locally tracked state
        is_uobjecthook_enabled = not is_uobjecthook_enabled

        -- Apply the change based on the new tracked state        
        disable_object_hooks(not is_uobjecthook_enabled)
    end

    -- Check if the button was just pressed (state changed from false to true)
    if lumen_button_pressed and not lumen_button_was_pressed then
        enable_lumen = (enable_lumen == 1) and 0 or 1
		toggle_lumen()
    end

    -- Update the previous state for the next frame
    fp_button_was_pressed = fp_button_pressed
	lumen_button_pressed = lumen_button_was_pressed
end

-- Register the input callback (assumes it exists)
uevr.sdk.callbacks.on_xinput_get_state(process_input)


local prevViewTarget = nil
local game_engine_class = uevr.api:find_uobject("Class /Script/Engine.GameEngine")

local iterated = false
local was_in_dialog = false
local was_in_cinematic = false
local was_in_grapple = false
local time_elapsed = 0.0
local was_grappling = false
--local isindialoglastframe = false
-- pawn.Mesh ends in .Body


-- run this every engine tick, *after* the world has been updated
uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)   
	-- if first person is off, just return and avoid this function
	if first_person == 0 then return end 
	
    -- We only go 1st person for main character gestatd
    local pawn = api:get_local_pawn(0)
    if pawn == nil then return end
    
    if pawn.Mesh then
        local Mesh_Name = pawn.Mesh:get_full_name()
        if Mesh_Name:sub(-5) ~= ".Body" then
            print("Disabling hooks", Mesh_Name)
            -- we think not main character, returning
            prevViewTarget = nil
            disable_object_hooks(true)
            return
        end
    end
    
    local game_engine       = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
    local player            = uevr.api:get_player_controller(0)
    if player then       
        local isindialog = false
        local isincinematic = false
        local isatgrapple = false
        
        -- check grapple
		if player.BP_InteractionSystem and player.BP_InteractionSystem.InteractiveObjects ~= nil then
			if #player.BP_InteractionSystem.InteractiveObjects > 0 then
				--print("Grapple", Interaction_Name)
                --isatgrapple = Interaction_Name:find("Grapple",1,true)~=nil 
                was_grappling = true
                time_elapsed = 0
                disable_object_hooks(true)
                return
            end
        end
        
        if was_grappling == true then
            time_elapsed = time_elapsed + delta
            if time_elapsed > 2.5 then
                time_elapsed = 0
                was_grappling = false
                was_in_grapple = true
            end
        end
        
        -- check dialogue
        if player.BP_DialogueSystemComponent and
            player.BP_DialogueSystemComponent.DialogueUI then
                isindialog = player.BP_DialogueSystemComponent.DialogueUI.IsActive
                if isindialog == true then
                    --print("in dialog, disabling")
                    disable_object_hooks(true)
                    was_in_dialog = true
                    return
                end
                --print("Dialog Active", isindialog, isindialoglastframe)
        end

        -- if here, we are not in dialog. check cinematic next
        if player.BP_CinematicSystem then
            isincinematic = player.BP_CinematicSystem.IsPlayingCinematic 
            if isincinematic == true then
                disable_object_hooks(true)
                was_in_cinematic = true
                return
            end
                --print("Dialog Active", isindialog, isindialoglastframe)
        end
        
        -- if we are still here, we are not in either dialog or cinematic.
        
        -- If we were in dialog or cinematic, reset prevViewTarget
        -- forcing world state to determine hook
        if was_in_dialog == true or was_in_cinematic == true or was_in_grapple then
            prevViewTarget = nil
            print("out of dialog and cinematic, clearing state")
            was_in_dialog = false
            was_in_cinematic = false
            was_in_grapple = false
        end
        
        local currentVT = player:GetViewTarget()        
        if prevViewTarget ~= currentVT then                        
            local world_name = currentVT:get_full_name()
            local is_main_world = world_name:find("BP_jRPG_Character_World",1,true)~=nil
            disable_object_hooks(is_main_world~=true)
            prevViewTarget = currentVT                
        end
    end
end)

