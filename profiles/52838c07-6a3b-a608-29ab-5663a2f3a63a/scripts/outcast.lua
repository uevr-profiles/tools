local uevrUtils = require('libs/uevr_utils')
local controllers = require('libs/controllers')
local interaction = require('libs/interaction')
local hands = require('libs/hands')

--uevrUtils.setDeveloperMode(true)
interaction.init()
interaction.showInteractionLaser(false) -- disable until we aim.
uevrUtils.initUEVR(uevr)

local api = uevr.api
local vr = uevr.params.vr
local dbgout = true
local config_filename = "outcast.txt"
local help_filename = "outcasthelp.txt"
local help_data = ""

local weapon_hooked = false
local weapon_equip_hooked = false
local aim_hooked = false
local map_hooked = false
local menu_hooked = false
local glide_hooked = false
local opacity_hooked = false
local new_proto_hud = false
local new_challenge_hud = false
local ProtoHud = nil
local Challenge_Hud_Instance = nil
local Hud_C = nil -- blueprint generated, will get later.
local Challenge_Widget_C = nil
local last_position = nil      -- Tracks the last controller position
local game_engine = nil
local is_swimming = false

local combo_threshold = 0.33   -- Seconds allowed between combo inputs (adjust based on frame rate)
local frame_counter = 0        -- Simulated frame counter (incremented each callback)
local combo_timer = 0          -- Tracks time elapsed for the combo
local left_swipe_in_progress = nil
local swipe_threshold = 0.4
local block_threshold = 0.25
local aim_timer = 0.0
local aim_regen_factor = 0.25
local max_aim_time = 7.5
local timed_laser_aim = 1
local hide_ui = 1
local hide_compass = 1
local hide_health_and_power = 1
local hide_weapon_meter = 1
local hide_quests = 1
local hide_dpad = 1
local fix_r_StaticMeshLODDistanceScale = 0

local is_in_menu = false
local aim_method = vr:get_mod_value("VR_AimMethod")
local current_level = nil
local is_gliding = false
local glide_is_in_tp = false
local duration = 0.0
local hide_dpad_widget_timer = 0.0
local hide_hud_timer = 0.0
local widgets_attached = false
local AttachedPower = nil
local AttachedHealth = nil
local AttachedCompass = nil
local AttachedWeapon = nil
local remove_widgets_timer = 0.0

local function dbgPrint(to_print)
    if dbgout == true then print(to_print) end
end
    
local function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        return nil
    end

    return obj
end

local find_static_class = function(name)
    local c = find_required_object(name)
    return c:get_class_default_object()
end

-------------------------------------------------------------------------------
-- Pass in the class from find_required_object and the name to match and get
-- the first instance that matches the string.
-------------------------------------------------------------------------------
local function GetFirstMatchingObject(class_object_c, match_string)
	local object_list = class_object_c:get_objects_matching(false)
    for i, instance in ipairs(object_list) do
        if not string.find(instance:get_full_name(), match_string, 1, true) then
			return instance
		end
	end
    
    return nil
end

local widget_main_class = find_required_object("Class /Script/UMG.Widget")
local main_char_animation = find_required_object("Class /Script/O2.MainCharacterAnim")

-------------------------------------------------------------------------------
-- hook_function
--
-- Hooks a UEVR function. 
--
-- class_name = the class to find, such as "Class /Script.GunfireRuntime.RangedWeapon"
-- function_name = the function to Hook
-- native = true or false whether or not to set the native function flag.
-- prefn = the function to run if you hook pre. Pass nil to not use
-- postfn = the function to run if you hook post. Pass nil to not use.
-- dbgout = true to print the debug outputs, false to not
--
-- Example:
--    hook_function("Class /Script/GunfireRuntime.RangedWeapon", "OnFireBegin", true, nil, gun_firingbegin_hook, true)
--
-- Returns: true on success, false on failure.
-------------------------------------------------------------------------------
local function hook_function(class_name, function_name, native, prefn, postfn, dbgout)
    local result = false
    local class_obj = uevr.api:find_uobject(class_name)
    if(class_obj ~= nil) then
        if dbgout then print("hook_function: found class obj for", class_name) end
        local class_fn = class_obj:find_function(function_name)
        if(class_fn ~= nil) then 
            if dbgout then print("hook_function: found function", function_name, "for", class_name) end
            if (native == true) then
                class_fn:set_function_flags(class_fn:get_function_flags() | 0x400)
                if dbgout then print("hook_function: set native flag") end
            else
                class_fn:set_function_flags(class_fn:get_function_flags() & ~0x400)
                if dbgout then print("hook_function: cleared native flag") end
            end
            
            class_fn:hook_ptr(prefn, postfn)
            result = true
            if dbgout then print("hook_function: set function hook for", prefn, "and", postfn) end
        else
            if dbgout then print("hook_function cannot find function for", function_name) end
        end
    else
        print("class obj was nil in hook_function")
    end
    
    return result
end


local first_person = 0
local third_person_glide = 0
local right_stick_down_b = 1
local right_stick_up_sprint = 1
local ui_horizontal_aim_adjust = 0.0
local right_grip_aim = 0
local needs_config_write = false
local crosshair_usage = 0
local melee_swing = 0
local gesture_block = 0

local cinematic_manager_c = find_required_object("Class /Script/O2.CinematicManager")
local dialog_manager_c = find_required_object("Class /Script/O2.DialogueManager")
local game_engine_c = find_required_object("Class /Script/Engine.GameEngine")

local IsInFirstPerson = false
local XDown = false
local RightStickUp = false
local StartKeyDown = false
local ShouldersDown = false
local IsAiming = false

local function get_cvar_float(name)
    local FloatVal = 0.0 -- Initialize to a float value
    local readable = false -- Initialize the status flag
    
    if disableMod == 0 then
        local console_manager = api:get_console_manager()
        if console_manager ~= nil and console_manager.find_variable then
            local var = console_manager:find_variable(name)

            if kismet_system_library ~= nil and var ~= nil then
                if kismet_system_library.GetConsoleVariableFloatValue then
                    FloatVal = kismet_system_library:GetConsoleVariableFloatValue(name)
                    readable = true -- Reading was successful
                end
            end
        end
    end
    
    -- Return the float value AND the boolean status
    return FloatVal, readable
end

local r_StaticMeshLODDistanceScale_orig = get_cvar_float("r.StaticMeshLODDistanceScale")

local function is_char_swimming()
    if main_char_animation == nil then 
        main_char_animation = find_required_object("Class /Script/O2.MainCharacterAnim")
    end
    
    if main_char_animation == nil then return false end

    local main_char_animation_inst = main_char_animation:get_first_object_matching(false)
    if main_char_animation_inst ~= nil then
        if main_char_animation_inst.IsSwimming ~= nil then
            print ("calling is_swimming")
            return main_char_animation_inst:IsSwimming()
        end
    end
    
    return false
end

local function is_in_dialog()
	local IsInDialog = false
	if dialog_manager_c == nil then 
		dialog_manager_c = find_required_object("Class /Script/O2.DialogueManager")
		if dialog_manager_c == nil then return false end
	end
	
	local dialog_manager = nil
	local dialog_manager_list = dialog_manager_c:get_objects_matching(false)
    for i, instance in ipairs(dialog_manager_list) do
        if not string.find(instance:get_full_name(), "GEN_VARIABLE", 1, true) then
			dialog_manager = instance
			break
		end
	end
	
	if dialog_manager ~= nil and dialog_manager.IsInDialogue then
		IsInDialog = dialog_manager:IsInDialogue()
	end
	
	if IsInDialog == true then dbgPrint("is in dialog is true") end
	
	return IsInDialog
end

local function is_in_cinematic()
	local IsInCinematic = false
	if cinematic_manager_c == nil then 
		cinematic_manager_c = find_required_object("Class /Script/O2.CinematicManager")
		if cinematic_manager_c == nil then return false end
	end
	
	local cinematic_manager = nil
	local cinematic_manager_list = cinematic_manager_c:get_objects_matching(false)
    for i, instance in ipairs(cinematic_manager_list) do
        if not string.find(instance:get_full_name(), "GEN_VARIABLE", 1, true) then
			cinematic_manager = instance
			break
		end
	end
	
	if cinematic_manager ~= nil and cinematic_manager.IsCinematicCurrentlyPlaying then
		IsInCinematic = cinematic_manager:IsCinematicCurrentlyPlaying()
	end
	
	if IsInCinematic == true then dbgPrint("is in cinematic is true") end
	
	return IsInCinematic
end

local function get_world()
    return uevrUtils.get_world()
end
local function has_level_changed()
    local new_level = get_current_level()
    if new_level ~= current_level then
        current_level = new_level
        return true
    else
        return false
    end
end

local function get_current_level()
	local world = get_world()
	if world ~= nil then
		return world.PersistentLevel
	end
end

local function get_weapon_mesh()
	local pawn = api:get_local_pawn()
	if pawn == nil then return nil end
	
	if pawn.GetRightHandEmplacement == nil then return nil end
	return pawn:GetRightHandEmplacement()
end

local function hooked_after_init(fn, obj, locals, result)
    local Mesh = get_weapon_mesh()
    if Mesh == nil then
        print("could not get weapon mesh")
        return true
    end

    if Mesh.GetForwardVector then
        local Forward = Mesh:GetForwardVector()
        if Forward ~= nil then
            locals.Direction.X = Forward.X * 8192
            locals.Direction.Y = Forward.Y * 8192
            locals.Direction.Z = Forward.Z * 8192
        end
    end
    
    -- fire haptics
    local RightController = vr.get_right_joystick_source()
    vr.trigger_haptic_vibration(0.0, 0.15, 100.0, 1.0, RightController);

    return true
end

-- Tracks if we are gliding
local function hooked_on_gliding(fn, obj, locals, result)
    is_gliding = locals.Value
    
    if is_gliding == true then
        vr.set_mod_value("VR_AimMethod", "0")
    else
        vr.set_mod_value("VR_AimMethod", aim_method)
        if first_person == 1 then
            IsInFirstPerson = true
            UEVR_UObjectHook.set_disabled(false)
        end
    end
    
    return true
end

-- Tracks if we are changing opacity
local function hooked_opacity(fn, obj, locals, result)
    
	print(string.format("hooked_opacity running before Opacity: %f", locals.Opacity))
	locals.Opacity = 1.0
	
    return true
end

-- this gives a gradual color that can be passed directly to interaction.setLaserColor()
-- max_time is the max timer value, aim_time is current timer value.
-- laser should be pure green at aim_time == max_time and pure red at aim_time = 0
-- and gradually moving from green to yellow to red between.
local function get_color_for_aim_timer(aim_time, max_time)
    if max_time <= 0.0 then return 0xFF000000 end -- Default black/off
    
    -- Normalize aim_time to a 0.0 to 1.0 range (0.0 is empty, 1.0 is full)
    local t = math.max(0.0, math.min(1.0, aim_time / max_time))
    
    local r, g, b = 0, 0, 0
    local a = 255 -- Keep full opacity

    -- The transition from green to red happens across the whole 0-1 range.
    -- We'll use the Hue-Saturation-Value (HSV) logic, which is easier to implement
    -- than RGB segments for a smooth rainbow.
    
    -- In HSV, 0.0 = Red, 0.33 = Green. We want 1.0 (max time) to be green (0.33)
    -- and 0.0 (min time) to be red (0.0).
    -- Hue = t * 0.33
    -- This means when t=1.0, Hue is 0.33 (Green). When t=0.0, Hue is 0.0 (Red).
    
    local h = t * (1/3) -- Range from 0.0 (Red) to 0.333... (Green)

    -- A simple function to convert HSV to RGB where R,G,B are 0-255
    -- We assume V=1 (full value/brightness) and S=1 (full saturation)
    local i = math.floor(h * 6.0)
    local f = h * 6.0 - i
    local p = 0
    local q = math.floor(255 * (1.0 - f))
    local t_rgb = math.floor(255 * f)
    
    i = i % 6

    if i == 0 then r, g, b = 255, t_rgb, p
    elseif i == 1 then r, g, b = q, 255, p
    elseif i == 2 then r, g, b = p, 255, t_rgb
    elseif i == 3 then r, g, b = p, q, 255
    elseif i == 4 then r, g, b = t_rgb, p, 255
    elseif i == 5 then r, g, b = 255, p, q
    else r, g, b = 255, 0, 0 -- Should not happen
    end

    local color_num = (a << 24) | (b << 16) | (g << 8) | r

    return color_num
end

-- this is easier to implement. Should be solid color from max_time to .5 *max_time then
-- gradually fade to 0 at aim_time = 0.0 from aim_time = 0.5 to 0.0
local function get_color_luminance_for_aim_timer(aim_time, max_time)
    local r, g, b = 255, 0, 0 -- Pure Green base color
    local a = 255 -- Default Alpha (full opacity)
    local fade_factor = 1.0
    
    if max_time <= 0.0 or aim_time <= 0.0 then
        a = 0 -- Fully transparent (off)
    else
        -- Define the start point for the fade (50% of max_time)
        local fade_start_time = max_time * 0.5 
        
        if aim_time < fade_start_time then
            -- We are in the fade zone (from 50% down to 0%)
            
            -- Normalize the fade zone to a 0.0 to 1.0 scale
            -- When aim_time = fade_start_time (top of zone), factor should be 1.0
            -- When aim_time = 0.0 (bottom of zone), factor should be 0.0
            fade_factor = aim_time / fade_start_time
            
            -- Set alpha based on the factor (0 to 255)
            a = math.floor(fade_factor * 255)
        end
        -- If aim_time >= fade_start_time, 'a' remains 255 (full opacity)
    end
    
    -- Ensure alpha is a valid integer between 0 and 255
    a = math.max(0, math.min(255, a))
    
    local color_num = (a << 24) | (b << 16) | (g << 8) | r

    print(string.format("color: 0x%08X", color_num))
    return color_num
end

local function handle_aim_laser()
    if crosshair_usage > 0 then
        if IsAiming == true then
            if timed_laser_aim == 0 then aim_timer = max_aim_time end
            
            if aim_timer > 0.0 then
                interaction.setLaserColor(get_color_for_aim_timer(aim_timer, max_aim_time))
                interaction.showInteractionLaser(true)
                if (aim_timer / max_aim_time) > 0.0 and (aim_timer / max_aim_time) < 0.20 then
                    local RightController = vr.get_right_joystick_source()
                    vr.trigger_haptic_vibration(0.0, 0.10, 200.0, 1.0, RightController);
                end
            else
                interaction.showInteractionLaser(false)
            end
        else
            interaction.showInteractionLaser(false)
        end
    end
end

-- Tracks if we are aiming or not.
local function hooked_aim_change(fn, obj, locals, result)
    IsAiming = locals.IsAiming
    
    if obj ~= nil and obj.SetVisibility ~= nil then
        if IsAiming == true then
            if crosshair_usage > 0 then -- 1 (when aiming) or 2 (always enabled)
                obj:SetVisibility(2) -- always hide crosshair.
                --obj:SetVisibility(0) -- this was for crosshair instead of laser pointer mode
            end
        else
            if crosshair_usage < 2 then -- 0 (always disabled) or 1 (when aiming)
                obj:SetVisibility(2) -- always hide crosshair.
            end
        end
    end
    
    return true
end

-- Tracks if we are aiming or not.
local function hooked_aim_post(fn, obj, locals, result)
    IsAiming = locals.IsAiming
    local Visibility = 0
    
        if IsAiming == true then
            if crosshair_usage > 0 then -- 1 (when aiming) or 2 (always enabled)
                Visibility = 0
            end
        else
            if crosshair_usage < 2 then -- 0 (always disabled) or 1 (when aiming)
                Visibility = 2
            end
        end

    Visibility = 2 -- always disable
    if ProtoHud ~= nil then
        local HeatGauge = ProtoHud.HeatGauge
        local Heat_Gauge_Frame = ProtoHud.Heat_Gauge_Frame
        
        if HeatGauge ~= nil then
            HeatGauge:SetVisibility(Visibility)
        end
        
        if Heat_Gauge_Frame ~= nil then
            Heat_Gauge_Frame:SetVisibility(Visibility)
        end
    end
end

-- when in the map, change aim to game so the map doesnt shake with the controller motion.
local function hooked_map_show(fn, obj, locals, result)
    if locals.Open == true then
        vr.set_mod_value("VR_AimMethod", "0")
    else
        vr.set_mod_value("VR_AimMethod", aim_method)
    end

    return true
end

-- when in the menu, change aim to game so the menu doesnt end in a weird level based on the controller.
local function hooked_menu_show(fn, obj, locals, result)
    if locals.Open == true then
        is_in_menu = true
    else
        is_in_menu = false
    end

    return true
end

--[[
WidgetBlueprintGeneratedClass /Game/O2/Core/UI/HUD/ProtoHUD.ProtoHUD_C
ProtoHUD_C
- DPadWidget - RemoveFromViewport removes It - dpad stuff lower left corner
- Compass_WBP_C - RemoveFromViewport = Compass_WBP_C
- WeaponVisualHUD_C - RemoveFromViewport - this is the weapon and ammo stuff that appears on lower right
- HealthBarCutter_C - HealthBarCutter_1 was variable name. removed the whole healthbar group on upper left.  
- EchoPowerGauge - Remove from viewport worked - this is the power bars under the healthbar

-- maybe set these to not visible in crosshair callback
-- NOPE these did not work, tried to setvisiblity on them in the crosshair hook
- Heat_Gauge_Frame (Image ?) SetVisibility didnt do anything
- HeatGauge - (Image?) 

-- get the ProtoHUD instance, maybe on level load
            if Hud_C ~= nil then
                local ProtoHud = UEVR_UObjectHook.get_first_object_by_class(Hud_C)
                
                if ProtoHud.DPadWidget then
                    ProtoHud.DPadWidget:SetVisibility(0)
                end
            end


Not protohud so search for this
WidgetBlueprintGeneratedClass /Game/O2/Core/UI/HUD/FollowedChallengeWidget_V3.FollowedChallengeWidget_V3_C
- FollowedChallengeWidget_V3_C

		options: 
			manualAttachment(bool) 
			relativeTransform(transform) (ex uevrUtils.get_transform(position, rotation, scale, reuseable))
			deferredFinish(bool)
			parent(object) 
			tag(string)
			removeFromViewport(bool)
			twoSided(bool)
			drawSize(Vector2D)
		example:
			local hudComponent = uevrUtils.createWidgetComponent(widget, {removeFromViewport=true, twoSided=true, drawSize=vector_2(620, 75)})	
			local hudComponent = uevrUtils.createWidgetComponent("WidgetBlueprintGeneratedClass /Game/UI/HUD/Reticle/Reticle_BP.Reticle_BP_C", {removeFromViewport=true, twoSided=true, drawSize=vector_2(100, 100)})	

]]
        
local function SetHealthWidgetParams(AttachedHealth)
    uevrUtils.set_component_relative_transform(
        AttachedHealth,
        {X=2.8, Y=4.0, Z=1},      -- location
        {Pitch=0, Yaw=90, Roll=270},  -- rotation
        {X=0.140625, Y=0.0084375, Z=0.00703125}  -- scale
    )
end

local function SetPowerWidgetParams(AttachedPower)
    uevrUtils.set_component_relative_transform(
        AttachedPower,
        {X=1.6, Y=4.0, Z=1},       -- location
        {Pitch=0, Yaw=90, Roll=270},  -- rotation
        {X=0.140625, Y=0.0084375, Z=0.00703125}  -- scale
    )
end

local function SetCompassWidgetParams(AttachedCompass)
    uevrUtils.set_component_relative_transform(
        AttachedCompass,
        {X=8.3, Y=4.0, Z=1},       -- location
        {Pitch=0, Yaw=90, Roll=270},  -- rotation
        {X=0.28125, Y=0.016875, Z=.016875}  -- scale
    )
end

local function SetWeaponWidgetParams(AttachedWeapon, Long)
    pcall(function()
        if Long == true then
            uevrUtils.set_component_relative_transform(
                AttachedWeapon,
                {X=-18.5, Y=-1.6, Z=4.5},       -- location
                {Pitch=180, Yaw=90, Roll=180},  -- rotation
                {X=.28125, Y=0.016875, Z=0.0140625}  -- scale
            )
        else
            uevrUtils.set_component_relative_transform(
                AttachedWeapon,
                {X=-7, Y=-2.0, Z=2},       -- location
                {Pitch=180, Yaw=90, Roll=180},  -- rotation
                {X=.28125, Y=0.016875, Z=0.0140625}  -- scale
            )
        end
   end)
end

local function hook_on_equip(fn, obj, locals, result)
    if AttachedWeapon == nil then return end
    
    if string.find(obj:get_full_name(), "Chassis_Small") ~= nil then
        SetWeaponWidgetParams(AttachedWeapon, false)
    elseif string.find(obj:get_full_name(), "Chassis_Long") ~= nil then
        SetWeaponWidgetParams(AttachedWeapon, true)
    end
end

local function ResetWidgets()
    if AttachedHealth ~= nil then uevrUtils.detachAndDestroyComponent(AttachedHealth, false, false) end
    if AttachedPower ~= nil then uevrUtils.detachAndDestroyComponent(AttachedPower, false, false) end
    if AttachedCompass ~= nil then uevrUtils.detachAndDestroyComponent(AttachedCompass, false, false) end
    if AttachedWeapon ~= nil then uevrUtils.detachAndDestroyComponent(AttachedWeapon, false, false) end
end

local function RemoveWidgets()
    print("Entering RemoveWidgets()")
    if ProtoHud == nil then return false end
    
    if hide_ui == 0 then return end
    
    local HealthBarWidget = ProtoHud.HealthBarCutter_1
    local PowerWidget = ProtoHud.EchoPowerGauge
    local WeaponWidget = ProtoHud.WeaponVisual_HUD
    local CompassWidget = ProtoHud.Compass_WBP

    if hide_health_and_power == 1 then  
        HealthBarWidget:RemoveFromParent()
        PowerWidget:RemoveFromParent()
        pcall(function()
            if PowerWidget.SetVisibility then
                PowerWidget:SetVisibility(0) -- 2 = hidden
            end
        end)
    end    

    if hide_compass == 1 then
        CompassWidget:RemoveFromParent()
    end
    
    if hide_quests == 1 then
        -- remove the challenge hud (missions)
        pcall(function()
            if Challenge_Hud_Instance and Challenge_Hud_Instance.SetVisibility then
                Challenge_Hud_Instance:SetVisibility(2) -- 2 = hidden
            end
        end)
    end
    
    if hide_dpad == 1 then
        -- removing the dpad widget.
        pcall(function()
            if ProtoHud and ProtoHud.DPadWidget and ProtoHud.DPadWidget.SetVisibility then
                ProtoHud.DPadWidget:SetVisibility(2) -- 2 = hidden
            end
        end)
    end
end

local function AttachWidgets()
    if hide_ui == 0 then return end
    if ProtoHud == nil then return false end
    
    local HealthBarWidget = ProtoHud.HealthBarCutter_1
    local PowerWidget = ProtoHud.EchoPowerGauge
    local WeaponWidget = ProtoHud.WeaponVisual_HUD
    local CompassWidget = ProtoHud.Compass_WBP
    
    -- left controller
    if controllers.getController(0) == nil then
        controllers.createController(0)
    end
    
    -- right controller
    if controllers.getController(1) == nil then
        controllers.createController(1)
    end

    if hide_health_and_power == 1 then  
        print("Attaching health")
        if AttachedHealth ~= nil then uevrUtils.detachAndDestroyComponent(AttachedHealth, false, false) end
        AttachedHealth = uevrUtils.createWidgetComponent(HealthBarWidget, {manualAttachment=false, removeFromViewport=false, twoSided=false, drawSize=vector_2(600, 150)})
        if AttachedHealth ~= nil then SetHealthWidgetParams(AttachedHealth) end
        local success = controllers.attachComponentToController(0, AttachedHealth, "Health", nil, nil, true)
        
        print("Attaching power")
        if AttachedPower ~= nil then uevrUtils.detachAndDestroyComponent(AttachedPower, false, false) end
        AttachedPower = uevrUtils.createWidgetComponent(PowerWidget, {manualAttachment=false, removeFromViewport=false, twoSided=false, drawSize=vector_2(600, 150)})
        if AttachedPower ~= nil then SetPowerWidgetParams(AttachedPower) end
        local success = controllers.attachComponentToController(0, AttachedPower, "Power", nil, nil, true)
        PowerWidget:SetVisibility(2) -- 2 = hidden
    end

    if hide_quests == 1 then
        pcall(function()
            if Challenge_Hud_Instance and Challenge_Hud_Instance.SetVisibility then
                print("removing challenge hud")
                Challenge_Hud_Instance:SetVisibility(2) -- 2 = hidden
            end
        end)
    end
    
    if hide_weapon_meter == 1 then
        if AttachedWeapon ~= nil then uevrUtils.detachAndDestroyComponent(AttachedWeapon, false, false) end
        AttachedWeapon = uevrUtils.createWidgetComponent(WeaponWidget, {manualAttachment=false, removeFromViewport=true, twoSided=false, drawSize=vector_2(1500, 500)})
        if AttachedWeapon ~= nil then SetWeaponWidgetParams(AttachedWeapon, true) end
        local success = controllers.attachComponentToController(1, AttachedWeapon, "Weapon", nil, nil, true)
    end
    
    if hide_compass == 1 then
        if CompassWidget ~= nil and CompassWidget.SetColorAndOpacity ~= nil then
            local Color = CompassWidget:GetLinearColor__DelegateSignature()
            Color.R = 0.5
            Color.G = 0.5
            Color.B = 0.5
            Color.A = 0.75
            
            CompassWidget:SetColorAndOpacity(Color)
        end
        
        if AttachedCompass ~= nil then uevrUtils.detachAndDestroyComponent(AttachedCompass, false, false) end
        AttachedCompass = uevrUtils.createWidgetComponent(CompassWidget, {manualAttachment=false, removeFromViewport=false, twoSided=false, drawSize=vector_2(600, 600)})
        if AttachedCompass ~= nil then SetCompassWidgetParams(AttachedCompass) end
        local success = controllers.attachComponentToController(0, AttachedCompass, "Compass", nil, nil, true)
    end
    
    -- signal to pre_engine_tick to remove the widges in 5 seconds.
    remove_widgets_timer = 5.0
    return true
end

uevr.sdk.callbacks.on_script_reset(function()
    ResetWidgets()
end)

-- this is for hands. But it could probably be used for all level processing.
function on_level_change(level)
	controllers.createController(0)
	controllers.createController(1)
	hands.reset()

	local paramsFile = 'hands_parameters' -- found in the [game profile]/data directory
	local configName = 'Main' -- the name you gave your config
	local animationName = 'Shared' -- the name you gave your animation
	hands.createFromConfig(paramsFile, configName, animationName)
    
    if fix_r_StaticMeshLODDistanceScale == 1 then
        uevrUtils.set_cvar_float("r.StaticMeshLODDistanceScale", "0.100000")
    end
end

local melee_notify_hook = false

local function melee_begin(fn, obj, locals, result)
-- 	bool Received_NotifyBegin(class USkeletalMeshComponent* MeshComp, class UAnimSequenceBase* Animation, float TotalDuration, const struct FAnimNotifyEventReference& EventReference) const;
    local mesh_comp = locals.MeshComp
    local anim_instance
    
    print("Received notify begin running")
    -- STEP 1: Get the UAnimInstance from the USkeletalMeshComponent
    if mesh_comp and mesh_comp.GetAnimInstance then 
        anim_instance = mesh_comp:GetAnimInstance()
        print("got the mesh")
    end

    -- STEP 2: Execute the Instant Speed-Up via UAnimInstance
    if anim_instance and anim_instance.GetCurrentActiveMontage and anim_instance.Montage_SetPlayRate then
        print("got the instance")
        
        -- Get the pointer to the currently playing UAnimMontage
        local montage = anim_instance:GetCurrentActiveMontage()
        
        if montage then
            -- Force the Montage to complete immediately (1000x speed)
            -- This ensures the final Anim Notify (Damage/Sound) fires instantly.
            --anim_instance:Montage_SetPlayRate(montage, 100.0) 
            anim_instance:Montage_Stop(0.0, montage)
            print("set rate to 10000")
        end
    end
    
    -- IMPORTANT: Return 'true' or 'nil' to allow the original function to execute normally.
    return true
end


uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta_time)
    local should_remove_widgets = false
    local should_hide_dpad_widget = false
  
    game_engine = engine
    
	-- If we are aiming, deduct delta_time from aim_timer. Otherwise add back to it.
    
	if IsAiming == true then
		aim_timer = aim_timer - delta_time
		if aim_timer < 0.0 then aim_timer = 0.0 end
	else
		aim_timer = aim_timer + (delta_time * aim_regen_factor)
		if aim_timer > max_aim_time then aim_timer = max_aim_time end
	end
	
    handle_aim_laser()
    
    -- this provides a timer that runs some functions every 2 seconds.
    duration = duration + delta_time
	
    -- melee swing timer. We tally it here because we have delta here.
    combo_timer = combo_timer + delta_time 
    
    -- we use this after attaching the widgets to hide the widgets in hope that 
    -- they will still update since they were attached before removed in the same frame.
    if remove_widgets_timer > 0.0 then
        remove_widgets_timer = remove_widgets_timer - delta_time
        if remove_widgets_timer < 0.0 then remove_widgets_timer = 0.0 end
        if remove_widgets_timer == 0.0 then 
            should_remove_widgets = true 
        end
    end
    
    if hide_dpad == 1 then
        if hide_dpad_widget_timer > 0.0 then 
            hide_dpad_widget_timer = hide_dpad_widget_timer - delta_time
            if hide_dpad_widget_timer < 0.0 then hide_dpad_widget_timer = 0.0 end
            if hide_dpad_widget_timer == 0.0 then should_hide_dpad_widget = true end
        end
    end
    
    if hide_hud_timer > 0.0 then 
        hide_hud_timer = hide_hud_timer - delta_time
        if hide_hud_timer < 0.0 then hide_hud_timer = 0 end
    end

    if duration > 2.0 then
        duration = 0.0
        
        -- this seems to ignore hide requests, we will see if calling it every "duration" secs helps.
        if hide_quests == 1 then
            if hide_hud_timer == 0.0 then
                pcall(function()
                    if Challenge_Hud_Instance and Challenge_Hud_Instance.SetVisibility then
                        --print("hiding hud again")
                        Challenge_Hud_Instance:SetVisibility(2) -- 2 = hidden
                    end
                end)
            end
        end
        
        -- cross hair hook needs redone on level load (save game load)
        local new_level = get_current_level()
        if new_level ~= current_level then
            current_level = new_level
            -- no point checking this at the main menu. It's processor intensive, although this check can probably
            -- be removed now that we are only doing this stuff every 2 seconds.
            if string.find(current_level:get_full_name(), "MainMenu.MainMenu", 1, true) then return end
            print("New level loaded: " .. current_level:get_full_name())
            weapon_equip_hooked = false
            aim_hooked = false
            weapon_hooked = false
            map_hooked = false
            is_in_menu = false
            glide_hooked = false
			opacity_hooked = false
            new_proto_hud = false
            widgets_attached = false
            new_challenge_hud = false
            Challenge_Widget_C = nil
            widgets_duration = 0.0
            Hud_C = nil
            aim_timer = max_aim_time
        end
        
        if Hud_C == nil then
            Hud_C = find_required_object("WidgetBlueprintGeneratedClass /Game/O2/Core/UI/HUD/ProtoHUD.ProtoHUD_C")
        end

        if new_proto_hud == false then
            if Hud_C ~= nil then
                ProtoHud = UEVR_UObjectHook.get_first_object_by_class(Hud_C)
                if ProtoHud ~= nil then new_proto_hud = true end
            end
        end
        
        
        if Challenge_Widget_C == nil then
            Challenge_Widget_C = find_required_object("WidgetBlueprintGeneratedClass /Game/O2/Core/UI/HUD/FollowedChallengeWidget_V3.FollowedChallengeWidget_V3_C")
        end
        
        if new_challenge_hud == false then
            if Challenge_Widget_C ~= nil then
                Challenge_Hud_Instance = UEVR_UObjectHook.get_first_object_by_class(Challenge_Widget_C)
                if Challenge_Hud_Instance ~= nil then new_challenge_hud = true end
            end
        end

        if melee_notify_hook == false then 
           -- melee_notify_hook = hook_function("BlueprintGeneratedClass /Game/O2/Core/Characters/Cutter/AnimNotify/AnimNotifyEnableMelee.AnimNotifyEnableMelee_C", "Received_NotifyBegin", false, melee_begin, nil, true)
        end
        
        -- since these are runtime generated, we will do them here until they get hooked.
        if weapon_hooked == false then
            --print("Hooking weapon")
            weapon_hooked = hook_function("BlueprintGeneratedClass /Game/O2/Weapon/WeaponTest/WeaponEffect/CutterProjectile.CutterProjectile_C", "OnAfterInitialize", false, hooked_after_init, nil, true)
        end
        
        if weapon_equip_hooked == false then
            --print("Hooking crosshair")
            -- BlueprintGeneratedClass /Game/O2/Weapon/Chassis_Long_Menu_BP.Chassis_Long_Menu_BP_C
            --weapon_equip_hooked = hook_function("BlueprintGeneratedClass /Game/O2/Weapon/BaseCutterChassis_BP.BaseCutterChassis_BP_C", "OnEquip", false, nil, hook_on_equip, true)
            weapon_equip_hooked = hook_function("BlueprintGeneratedClass /Game/O2/Weapon/BaseCutterChassis_BP.BaseCutterChassis_BP_C", "OnEquip", false, nil, hook_on_equip, true)
        end

        --  Crosshair hook.
        if aim_hooked == false then
            --print("Hooking crosshair")
            aim_hooked = hook_function("WidgetBlueprintGeneratedClass /Game/O2/Core/UI/HUD/Crosshair.Crosshair_C", "AimChange", false, hooked_aim_change, hooked_aim_post, true)
        end

        if map_hooked == false then
            map_hooked = hook_function("Class /Script/O2.EventMenuMapEndLifecycle", "OnMapOpened", true, hooked_map_show, nil, true)
        end
        
        if menu_hooked == false then
            menu_hooked = hook_function("Class /Script/O2.EventGameMenuEndLifecycle", "OnMenuOpened", true, hooked_menu_show, nil, true)
        end
        
        if glide_hooked == false then
            glide_hooked = hook_function("BlueprintGeneratedClass /Game/O2/Core/Characters/Cutter/MainCharacter_BP.MainCharacter_BP_C", "OnGlideEnabled", false, hooked_on_gliding, nil, true)
        end
        
        if opacity_hooked == false then
            --opacity_hooked = hook_function("BlueprintGeneratedClass /Game/O2/Core/Characters/Cutter/MainCharacter_BP.MainCharacter_BP_C", "ChangeOpacityOnMaterialDynamic", false, hooked_opacity, nil, true)
        end

        if widgets_attached == false then
            widgets_attached = AttachWidgets() 
        end
    end
    
    -- removes attached widgets from the hud
    if should_remove_widgets == true then 
        should_remove_widgets = false
        RemoveWidgets() 
    end
    
    -- this gets unhidden when using one of the dpad keys.
    if should_hide_dpad_widget == true then
        should_hide_dpad_widget = false
        pcall(function()
            if ProtoHud and ProtoHud.DPadWidget and ProtoHud.DPadWidget.SetVisibility then
                ProtoHud.DPadWidget:SetVisibility(2) -- 2 = hidden
            end
        end)
    end
end)

-------------------------------------------------------------------------------------------------------------------------
-- xinput callback
-------------------------------------------------------------------------------------------------------------------------
uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)

    -- hands processing
	if hands.exists() then
		local isHoldingWeapon = false
		local hand = Handed.Right
		hands.handleInput(state, isHoldingWeapon, hand)
	end

	if right_stick_down_b == 1 and is_gliding == false then
		if state.Gamepad.sThumbRY <= -25000 then
			state.Gamepad.sThumbRY = 0
			state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_B
		end
	end
    
	if right_stick_up_sprint == 1 and is_gliding == false then
		if state.Gamepad.sThumbRY >= 25000 then
			state.Gamepad.sThumbRY = 0
			state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_LEFT_THUMB
		end
	end

	-- if first_person == 0 then config wants 3rd person. So no obj hook at all.
	if first_person == 0 then
		if UEVR_UObjectHook.is_disabled ~= true then
			UEVR_UObjectHook.set_disabled(true)
            IsInFirstPerson = false
		end
		
		return
	end

    if hide_dpad == 1 then
        if (state.Gamepad.wButtons & (XINPUT_GAMEPAD_DPAD_UP | XINPUT_GAMEPAD_DPAD_LEFT | XINPUT_GAMEPAD_DPAD_RIGHT | XINPUT_GAMEPAD_DPAD_DOWN)) > 0 then
            hide_dpad_widget_timer = 2.0 
            if ProtoHud ~= nil and ProtoHud.DPadWidget and ProtoHud.DPadWidget.SetVisibility then
                ProtoHud.DPadWidget:SetVisibility(0) -- 2 = hidden
            end
        end
    end
    
    is_swimming = is_char_swimming()
    
    if hide_quests == 1 then
        if is_swimming == false then
            if (state.Gamepad.wButtons & (XINPUT_GAMEPAD_X)) > 0 then
                hide_hud_timer = 0.5 
                hide_dpad_widget_timer = 0.5 
                if Challenge_Hud_Instance ~= nil and Challenge_Hud_Instance.SetVisibility then
                    Challenge_Hud_Instance:SetVisibility(0) -- 2 = hidden, 0 = visible
                end
                if ProtoHud ~= nil and ProtoHud.DPadWidget and ProtoHud.DPadWidget.SetVisibility then
                    ProtoHud.DPadWidget:SetVisibility(0) -- 2 = hidden
                end
            end
        end
    end
    
	-- if still here, then first_person == 1
	local IsInCinematic = is_in_cinematic()
	local IsInDialog = is_in_dialog()
    
	if IsInFirstPerson == false and ShouldersDown == false then
		-- if not in dialog or cinematic, set objecthook back to enabled.
		if IsInCinematic == false and IsInDialog == false  then
            vr.set_mod_value("VR_AimMethod", aim_method)

			UEVR_UObjectHook.set_disabled(false)
			IsInFirstPerson = true
		end
	end

    -- RB is used below also.
    local RB = state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER > 0 and 1 or 0
	
    -- swap right grip and LT if we are not in menu where LB / RB are used for navigation
    if right_grip_aim == 1 and is_in_menu == false then
        -- read the state of LT and RB
        local LT = state.Gamepad.bLeftTrigger > 200 and 1 or 0
        
        -- clear the state of LT and RB
        state.Gamepad.bLeftTrigger = 0
        state.Gamepad.wButtons = state.Gamepad.wButtons & ~XINPUT_GAMEPAD_RIGHT_SHOULDER
        
        -- set RB if LT was pressed
        if LT == 1 then
            state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_RIGHT_SHOULDER
        end
        
        -- set LT if RB was pressed
        if RB == 1 then
            state.Gamepad.bLeftTrigger = 255
        end
    end

	-- 3rd person glide will disable object hooks X is held down.
	if third_person_glide == 1 and is_gliding == true then
        if (state.Gamepad.wButtons & (XINPUT_GAMEPAD_X)) > 0 then
            IsInFirstPerson = false
            UEVR_UObjectHook.set_disabled(true)
        elseif IsInFirstPerson == false then
            IsInFirstPerson = true
            UEVR_UObjectHook.set_disabled(false)
        end
	end
    
    
    -- Check if in cinematic (movie) and if so, go to 3rd person.
	if IsInFirstPerson == true then
		if IsInCinematic == true or IsInDialog == true then
			UEVR_UObjectHook.set_disabled(true)
			IsInFirstPerson = false
            vr.set_mod_value("VR_AimMethod", "0") -- turn off controller moving UI when in these.
		end
	end

    -- Global variables required (assuming these are declared outside this block)
    -- combo_timer is the time (in seconds) that has passed since the SWING STARTED.
    -- combo_threshold is the maximum time allowed for the swipe (e.g., 0.33 seconds).
    -- swipe_threshold is the required distance traveled on the X-axis.

    -- State variable to track if the swipe has already begun this combo
    if left_swipe_in_progress == nil then left_swipe_in_progress = false end

    -- GESTURE DETECTION LOGIC (inside the on_pre_engine_tick callback)
    if (melee_swing and is_in_menu == false and is_swimming == false) then
        -- 1. CLEAR X BUTTON (Always clear the button at the start of the frame)
        state.Gamepad.wButtons = state.Gamepad.wButtons & ~XINPUT_GAMEPAD_X
        
        local controller_index = vr.get_left_controller_index()
        if controller_index ~= -1 then
        
            local current_position = UEVR_Vector3f.new()
            local controller_rotation = UEVR_Quaternionf.new()
            vr.get_pose(controller_index, current_position, controller_rotation)

            -- Check if we have a previous frame's position to calculate movement
            if last_position then
                local delta_x_frame = current_position.x - last_position.x
                -- Note: We only care about the X-axis for this left-to-right swipe.

                -- If a swipe is NOT already in progress:
                if not left_swipe_in_progress then
                    -- Check for the START of the swipe (a minimum movement in the desired direction)
                    -- We use a small threshold (e.g., 0.005) to ensure the controller isn't just floating.
                    if delta_x_frame > 0.005 then 
                        -- START SWIPE: Reset timer to 0 and mark as in progress.
                        combo_timer = 0.0
                        left_swipe_in_progress = true
                        -- Store the starting position for total distance calculation (optional, but robust)
                        swipe_start_position = current_position
                    end
                
                -- If a swipe IS in progress:
                else
                    -- Calculate total X-distance traveled since the START
                    local total_delta_x = current_position.x - swipe_start_position.x

                    -- 3. CHECK GESTURE COMPLETION
                    -- Check if total distance is met AND time is within the limit
                    if total_delta_x >= swipe_threshold and combo_timer <= combo_threshold then
                        
                        -- SWIPE SUCCESS!
                        state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_X
                        print("Left-to-Right Swipe detected and X button pressed!")
                        
                        -- Reset the state for the next swing
                        left_swipe_in_progress = false
                        combo_timer = 0.0 
                        
                    -- 4. CHECK GESTURE TIMEOUT
                    elseif combo_timer > combo_threshold then
                        
                        -- SWIPE FAILED (Timeout)
                        left_swipe_in_progress = false
                        combo_timer = 0.0
                    end
                end
            end

            -- Update last position for the NEXT frame's delta calculation
            last_position = current_position
            if not swipe_start_position then
                swipe_start_position = current_position
            end
        end
    end	
    
    -- holding shield by head to block
    if (state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER > 0) and (state.Gamepad.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER > 0) then
        -- gliding
    elseif gesture_block and is_in_menu == false then
        
        local left_controller_index = vr.get_left_controller_index()
        local hmd_index = vr.get_hmd_index()
        
        -- Ensure both devices are connected/tracked
        if left_controller_index ~= -1 and hmd_index ~= -1 then
            
            -- Get Poses
            local controller_pos = UEVR_Vector3f.new()
            local controller_rot = UEVR_Quaternionf.new()
            vr.get_pose(left_controller_index, controller_pos, controller_rot)
            
            local hmd_pos = UEVR_Vector3f.new()
            local hmd_rot = UEVR_Quaternionf.new()
            vr.get_pose(hmd_index, hmd_pos, hmd_rot)
            
            -- Calculate the Euclidean distance between the two points (Vector subtraction, then length/magnitude)
            local dx = controller_pos.x - hmd_pos.x
            local dy = controller_pos.y - hmd_pos.y
            local dz = controller_pos.z - hmd_pos.z
            
            -- Distance = sqrt(dx^2 + dy^2 + dz^2)
            local distance = math.sqrt(dx*dx + dy*dy + dz*dz)
            
            -- Check if the distance is within the blocking threshold
            if distance <= block_threshold then
                -- Controller is near the head (Shield UP!)
                -- Hold the Right Shoulder (RB) button down
                state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_LEFT_SHOULDER
                
            else
                -- Controller is away from the head (Shield DOWN!)
                -- Ensure the Right Shoulder (RB) button is released
                state.Gamepad.wButtons = state.Gamepad.wButtons & ~XINPUT_GAMEPAD_LEFT_SHOULDER
            end
        end
        
    end    
    
end)

local function read_config()
    local config_data = fs.read(config_filename)
    if config_data then
        for key, value in config_data:gmatch("([^=]+)=([^\n]+)\n?") do
            local num_val = tonumber(value)
            if key == "first_person" then 
				first_person = num_val 
            end
			
			if key == "third_person_glide" then
				third_person_glide = num_val
			end

            if key == "right_grip_aim" then
                right_grip_aim = num_val
            end
            
            if key == "melee_swing" then
                melee_swing = num_val
            end
            
            if key == "swipe_threshold" then
                swipe_threshold = num_val
            end
    
            if key == "gesture_block" then
                gesture_block = num_val
            end
            
            if key == "block_threshold" then
                block_threshold = num_val
            end
            
			if key == "right_stick_down_b" then
				right_stick_down_b = num_val
			end
            
            if key == "right_stick_up_sprint" then
                right_stick_up_sprint = num_val
            end
            
            if key == "ui_horizontal_aim_adjust" then
                ui_horizontal_aim_adjust = num_val
            end
            
            if key == "crosshair_usage" then
                crosshair_usage = num_val
            end
            
            if key == "aim_regen_factor" then 
                aim_regen_factor = num_val
            end
            
            if key == "max_aim_time" then
                max_aim_time = num_val
            end
            
            if key == "timed_laser_aim" then
                timed_laser_aim = num_val
            end
            
            if key == "hide_ui" then
                hide_ui = num_val
            end
            
            if key == "hide_compass" then
                hide_compass = num_val
            end
            
            if key == "hide_health_and_power" then
                hide_health_and_power = num_val
            end
            
            if key == "hide_weapon_meter" then
                hide_weapon_meter = num_val
            end
            
            if key == "hide_quests" then
                hide_quests = num_val
            end
            
            if key == "hide_dpad" then
                hide_dpad = num_val
            end
            
            if key == "fix_r_StaticMeshLODDistanceScale" then 
                fix_r_StaticMeshLODDistanceScale = num_val
            end
       end
    end
    
    help_data = fs.read(help_filename)

end

local function write_config()
    local config = "" -- Initialize config as an empty string
	
	config = config .. string.format("first_person=%d\n", first_person) 
	config = config .. string.format("third_person_glide=%d\n", third_person_glide) 
    config = config .. string.format("right_grip_aim=%d\n", right_grip_aim)
	config = config .. string.format("right_stick_down_b=%d\n", right_stick_down_b) 
    config = config .. string.format("right_stick_up_sprint=%d\n", right_stick_up_sprint) 
	config = config .. string.format("ui_horizontal_aim_adjust=%.6f\n", ui_horizontal_aim_adjust) 
    config = config .. string.format("crosshair_usage=%d\n", crosshair_usage) 
    config = config .. string.format("melee_swing=%d\n", melee_swing)
    config = config .. string.format("swipe_threshold=%.1f\n", swipe_threshold)
    config = config .. string.format("gesture_block=%d\n", gesture_block)
    config = config .. string.format("block_threshold=%.2f\n", block_threshold)
    config = config .. string.format("max_aim_time=%.1f\n", max_aim_time)
    config = config .. string.format("timed_laser_aim=%d\n", timed_laser_aim)
    config = config .. string.format("aim_regen_factor=%.2f\n", aim_regen_factor)
    config = config .. string.format("hide_ui=%d\n", hide_ui)
    config = config .. string.format("hide_compass=%d\n", hide_compass)
    config = config .. string.format("hide_health_and_power=%d\n", hide_health_and_power)
    config = config .. string.format("hide_weapon_meter=%d\n", hide_weapon_meter)
    config = config .. string.format("hide_quests=%d\n", hide_quests)
    config = config .. string.format("hide_dpad=%d\n", hide_dpad)
    config = config .. string.format("fix_r_StaticMeshLODDistanceScale=%d\n", fix_r_StaticMeshLODDistanceScale)
    
    fs.write(config_filename, config)
end


uevr.lua.add_script_panel("Outcast Config", function()
    imgui.text("Outcast Mod v1.3 by MarkMon")
    imgui.spacing()
    imgui.spacing()
    imgui.spacing()
    if imgui.collapsing_header("Help and Readme") then
        imgui.text(help_data)
    end
    imgui.spacing()
    imgui.spacing()

	local changed, new_value = imgui.checkbox("First Person - enable first person 6dof mode!", first_person == 1)
	if changed then first_person = new_value and 1 or 0; needs_config_write = true; end

    imgui.spacing()
    if imgui.collapsing_header("Aiming Settings") then
        changed, new_index = imgui.combo("Aiming Laser", crosshair_usage+1, {"Disabled", "Only When Aiming"})
        if changed then crosshair_usage = new_index - 1; needs_config_write = true;  end
        
        imgui.text("Laser aiming makes the game easier but is very cool. ")
        imgui.text("Recommended to limit it to a max usage time in seconds that")
        imgui.text("regenerates slower than you use it. At 30 seconds max and ")
        imgui.text("100% regen, it is basically always available")
        
        changed, new_value = imgui.checkbox("Use timed laser for less of a cheat", timed_laser_aim == 1)
        if changed then timed_laser_aim = new_value and 1 or 0; needs_config_write = true; end
        
        local changed, new_value = imgui.slider_float("Constant Laser Time", max_aim_time, 2.0, 30.0)
        if changed then max_aim_time = new_value; needs_config_write = true; end
        
        local changed, new_value = imgui.slider_float("Laser Refill Rate %", (aim_regen_factor * 100), 10, 100)
        if changed then aim_regen_factor = (new_value / 100); needs_config_write = true; end
        
        imgui.text("Laser pointer starts out as green and fades to red")
        imgui.text("as it gets closer to the time running out.")
        
        changed, new_value = imgui.checkbox("Fix scenery background on aiming", fix_r_StaticMeshLODDistanceScale == 1)
        if changed then 
            fix_r_StaticMeshLODDistanceScale = new_value and 1 or 0; 
            needs_config_write = true; 
            if fix_r_StaticMeshLODDistanceScale == 0 then
                print("setting r.StaticMeshLODDistanceScale to ", r_StaticMeshLODDistanceScale_orig)
                uevrUtils.set_cvar_float("r.StaticMeshLODDistanceScale", "1.000000")
            else
                print("setting r_StaticMeshLODDistanceScale to 0.1")
                uevrUtils.set_cvar_float("r.StaticMeshLODDistanceScale", "0.100000")
            end
        end
        imgui.text("Note: this fix may be performance heavy!")

    end
    
    imgui.spacing()
    if imgui.collapsing_header("Control Options") then
        changed, new_value = imgui.checkbox("Swap LT and Right Grip to use Right Grip for Aiming", right_grip_aim == 1)
        if changed then right_grip_aim = new_value and 1 or 0; needs_config_write = true; end
        
        changed, new_value = imgui.checkbox("X button during gliding toggles 3rd person glide.", third_person_glide == 1)
        if changed then third_person_glide = new_value and 1 or 0; needs_config_write = true; end
        
        changed, new_value = imgui.checkbox("Right Stick Down Dodge", right_stick_down_b == 1)
        if changed then right_stick_down_b = new_value and 1 or 0; needs_config_write = true; end

        changed, new_value = imgui.checkbox("Right Stick Up Sprint", right_stick_up_sprint == 1)
        if changed then right_stick_up_sprint = new_value and 1 or 0; needs_config_write = true; end
    end
    
    imgui.spacing()
    if imgui.collapsing_header("Gestures") then
        changed, new_value = imgui.checkbox("Melee Swing - Swing left controller from left to right for melee.", melee_swing == 1)
        if changed then melee_swing = new_value and 1 or 0; needs_config_write = true; end

        local changed, new_value = imgui.slider_float("Swing Threshold", swipe_threshold, 0.1, 1.0)
        if changed then
            local step = 0.1
            
            -- 3. Multiply by the step size (e.g., 5.0 * 0.5 = 2.5)
            new_value = math.floor((new_value / step) + 0.5) * step

            swipe_threshold = new_value
            needs_config_write = true
        end
            
        imgui.spacing()
        imgui.text("Distance is in virtual meters. Larger number requires bigger swing to register.")
        imgui.spacing()

        changed, new_value = imgui.checkbox("Gesture shield. Hold left controller near head", gesture_block == 1)
        if changed then gesture_block = new_value and 1 or 0; needs_config_write = true; end

        imgui.spacing()
        local changed, new_value = imgui.slider_float("Shield Threshold", block_threshold, 0.1, 0.4)
        if changed then
            local step = 0.05
            
            -- 3. Multiply by the step size (e.g., 5.0 * 0.5 = 2.5)
            new_value = math.floor((new_value / step) + 0.5) * step

            block_threshold = new_value
            needs_config_write = true
        end
        imgui.text("Distance is in virtual meters. Left is closer to head to trigger.")
    end
    imgui.spacing()
    if imgui.collapsing_header("UI and HUD") then
        imgui.text("This enables / disables the entire HUD cleanup.")
        imgui.text("After toggling any of these you must reload your game")
        imgui.text("or save and load again.")

        changed, new_value = imgui.checkbox("Relocate HUD to controllers", hide_ui == 1)
        if changed then hide_ui = new_value and 1 or 0; needs_config_write = true; end
        imgui.spacing()
        imgui.text("These enable / disable specific HUD elements.")
        imgui.spacing()
        changed, new_value = imgui.checkbox("Relocate compass", hide_compass == 1)
        if changed then hide_compass = new_value and 1 or 0; needs_config_write = true; end
        changed, new_value = imgui.checkbox("Relocate Health & Power", hide_health_and_power == 1)
        if changed then hide_health_and_power = new_value and 1 or 0; needs_config_write = true; end
        changed, new_value = imgui.checkbox("Relocate Weapon Meter", hide_weapon_meter == 1)
        if changed then hide_weapon_meter = new_value and 1 or 0; needs_config_write = true; end
        changed, new_value = imgui.checkbox("Remove HUD Quest List", hide_quests == 1)
        if changed then hide_quests = new_value and 1 or 0; needs_config_write = true; end
        changed, new_value = imgui.checkbox("Remove DPAD icons", hide_dpad == 1)
        if changed then hide_dpad = new_value and 1 or 0; needs_config_write = true; end
        imgui.text("The quest list and dpad show up holding X. ")
        imgui.text("The dpad also shows up when you use it ")
        imgui.text("Final Note: if not using melee swing in gestures, then ")
        imgui.text("this will show the UI every time you melee.")
    end    
 
    if needs_config_write == true then
        write_config()
	end
end)

read_config()
