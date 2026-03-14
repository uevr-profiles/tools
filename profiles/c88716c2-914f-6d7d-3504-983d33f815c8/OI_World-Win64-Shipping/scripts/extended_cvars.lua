------------------------------------------------------------------------------------
-- Extended CVARs Script
-- Written by markmon and Lukasblaster
------------------------------------------------------------------------------------
local api = uevr.api
local vr = uevr.params.vr
local functions = uevr.params.functions

local config_filename = "extended_cvars_2.txt"

local find_static_class = function(name)
    local c = uevr.api:find_uobject(name)
    if(c ~= nil) then
        return c:get_class_default_object()
    else
        return nil
    end
end
local kismet_system_library = find_static_class("Class /Script/Engine.KismetSystemLibrary")

local function get_cvar_int(name)
    local IntVal = 0
    local readable = false -- Initialize the boolean flag
    
    local console_manager = api:get_console_manager()
    local var = console_manager:find_variable(name)
    
    if kismet_system_library ~= nil and var ~= nil then
        if kismet_system_library.GetConsoleVariableIntValue then
            IntVal = kismet_system_library:GetConsoleVariableIntValue(name)
            readable = true -- Set to true only if the variable could be read
        end
    end
    
    -- Return the integer value AND the boolean status
    return IntVal, readable 
end

local function get_cvar_float(name)
    local FloatVal = 0.0 -- Initialize to a float value
    local readable = false -- Initialize the status flag
    
    local console_manager = api:get_console_manager()
    local var = console_manager:find_variable(name)

    if kismet_system_library ~= nil and var ~= nil then
        if kismet_system_library.GetConsoleVariableFloatValue then
            FloatVal = kismet_system_library:GetConsoleVariableFloatValue(name)
            readable = true -- Reading was successful
        end
    end
    
    -- Return the float value AND the boolean status
    return FloatVal, readable
end

local function get_cvar_bool(name)
    local BoolVal = false -- Initialize to a boolean value (assuming API returns true/false)
    local readable = false -- Initialize the status flag
    
    -- Check for the existence of the variable in the console manager
    local console_manager = api:get_console_manager()
    local var = console_manager:find_variable(name)

    if kismet_system_library ~= nil and var ~= nil then
        if kismet_system_library.GetConsoleVariableBoolValue then
            BoolVal = kismet_system_library:GetConsoleVariableBoolValue(name)
            readable = true -- Reading was successful
        end
    end
    
    -- Return the boolean value AND the boolean status
    return BoolVal, readable
end

local function check_lumen_state()
	local result
    local r_Lumen_val, result = get_cvar_int("r.Lumen") -- 0 or 1
    
    if result == false then
        return 0
    end
    
    -- State 1: Lumen is off (Lumen=1)
    if r_Lumen_val == 0 then
        -- Lumen being off = 1.
        return 1
    
    -- State 2: Partial (Lumen=2)
    elseif r_Lumen_val == 1 and get_cvar_int("r.Lumen.Reflections.Temporal") == 0 then
        -- Partial state is defined by r.Lumen=1 AND the temporal reflection/DFDistanceScale settings being low/off.
        -- We check a reliable "low" setting to identify State 2 (Partial).
        return 2
        
    -- State 3: Full (Lumen=3)
    elseif r_Lumen_val == 1 and get_cvar_int("r.Lumen.Reflections.Temporal") == 1 then
        -- Full state is defined by r.Lumen=1 AND the temporal reflection/DFDistanceScale settings being high/on.
        -- We check a reliable "high" setting to identify State 3 (Full).
        return 3
    end
    
    -- If none of the recognized states match the intended Lumen value, 
    -- we default to assuming the state is NOT the intended default.
    return 0
end

local function check_nanite_state()
	local result
    -- Assuming get_cvar_int now returns the value and ignores the status flag
    local r_Nanite_val, result = get_cvar_int("r.Nanite") -- Expected to be 0 or 1

	if result == false then
		return 0
	end
    
    -- State 1: Nanite is off (Corresponds to Nanite=1)
    if r_Nanite_val == 0 then
        -- Nanite off = 1
        return 1
    
    -- State 2: Partial (Corresponds to Nanite=2)
    -- Defined by r.Nanite=1 AND key sub-settings being 0.
    elseif r_Nanite_val == 1 and get_cvar_int("r.Nanite.AllowComputeMaterials") == 0 then
        -- Partial state: r.Nanite=1 AND AllowComputeMaterials=0.
        return 2
        
    -- State 3: Full (Corresponds to Nanite=3)
    -- Defined by r.Nanite=1 AND key sub-settings being 1.
    elseif r_Nanite_val == 1 and get_cvar_int("r.Nanite.AllowComputeMaterials") == 1 then
        -- Full state: r.Nanite=1 AND AllowComputeMaterials=1.
        return 3
    end
    
    -- If the combination of CVARs is unexpected, 0 signifying undefined state.
    return 0
end



-- Original CVARs
local r_Fog = get_cvar_int("r.Fog"); local r_Fog_s = false
local r_VolumetricFog = get_cvar_int("r.VolumetricFog"); local r_VolumetricFog_s = false
local r_FilmGrain = get_cvar_int("r.FilmGrain"); local r_FilmGrain_s = false 
local Lumen = check_lumen_state(); local Lumen_s = false
local Nanite = check_nanite_state(); local Nanite_s = false
local Global_Illum = get_cvar_int("r.DynamicGlobalIlluminationMethod"); local Global_Illum_s = false

local r_PropagateAlpha = get_cvar_int("r.PostProcessing.PropagateAlpha"); local r_PropagateAlpha_s = false
local r_MeshBlend = get_cvar_int("r.MeshBlend.Enable"); local r_MeshBlend_s = false

-- Scalability Groups
local sg_ViewDistanceQuality = get_cvar_int("sg.ViewDistanceQuality"); local sg_ViewDistanceQuality_s = false
local sg_ShadowQuality = get_cvar_int("sg.ShadowQuality"); local sg_ShadowQuality_s = false
local sg_PostProcessQuality = get_cvar_int("sg.PostProcessQuality"); local sg_PostProcessQuality_s = false
local sg_EffectsQuality = get_cvar_int("sg.EffectsQuality"); local sg_EffectsQuality_s = false
local sg_TextureQuality = get_cvar_int("sg.TextureQuality"); local sg_TextureQuality_s = false
local sg_FoliageQuality = get_cvar_int("sg.FoliageQuality"); local sg_FoliageQuality_s = false

-- LOD Settings
local r_ViewDistanceScale = get_cvar_float("r.ViewDistanceScale"); local r_ViewDistanceScale_s = false
local r_StaticMeshLODDistanceScale = get_cvar_float("r.StaticMeshLODDistanceScale"); local r_StaticMeshLODDistanceScale_s = false
local r_SkeletalMeshLODDistanceScale = get_cvar_float("r.SkeletalMeshLODDistanceScale"); local r_SkeletalMeshLODDistanceScale_s = false
local r_SkeletalMeshLODBias = get_cvar_int("r.SkeletalMeshLODBias"); local r_SkeletalMeshLODBias_s = false
local r_StaticMeshLODBias = get_cvar_int("r.StaticMeshLODBias"); local r_StaticMeshLODBias_s = false
local r_MipMapLODBias = get_cvar_int("r.MipMapLODBias"); local r_MipMapLODBias_s = false
local r_ParticleLODBias = get_cvar_int("r.ParticleLODBias"); local r_ParticleLODBias_s = false
local foliage_LODDistanceScale = get_cvar_float("foliage.LODDistanceScale"); local foliage_LODDistanceScale_s = false

-- Shadow Settings
local r_ShadowQuality = get_cvar_int("r.ShadowQuality"); local r_ShadowQuality_s = false
local r_Shadow_MaxResolution = get_cvar_int("r.Shadow.MaxResolution"); local r_Shadow_MaxResolution_s = false
local r_Shadow_DistanceScale = get_cvar_float("r.Shadow.DistanceScale"); local r_Shadow_DistanceScale_s = false

-- Lumen Settings
local r_Lumen_Reflections_Temporal = get_cvar_int("r.Lumen.Reflections.Temporal"); local r_Lumen_Reflections_Temporal_s = false

local function write_config()
    local config = "" -- Initialize config as an empty string

    ---------------------------------------------------
    -- Group 1: Integer (or Boolean-like) values
    ---------------------------------------------------
    local valid = false
	local var = 0
	
    if r_Fog_s then config = config .. string.format("r_Fog=%d\n", r_Fog) end
    if r_VolumetricFog_s then config = config .. string.format("r_VolumetricFog=%d\n", r_VolumetricFog) end
    if r_FilmGrain_s then config = config .. string.format("r_FilmGrain=%d\n", r_FilmGrain) end
	if Lumen_s then config = config .. string.format("Lumen=%d\n", Lumen) end
    if Nanite_s then config = config .. string.format("Nanite=%d\n", Nanite) end
    if Global_Illum_s then config = config .. string.format("Global_Illum=%d\n", Global_Illum) end
    if r_PropagateAlpha_s then config = config .. string.format("r_PropagateAlpha=%d\n", r_PropagateAlpha) end
	
	var, valid = get_cvar_int("r.MeshBlend.Enable")
	if valid and r_MeshBlend_s then config = config .. string.format("r_MeshBlend=%d\n", r_MeshBlend) end

    -- Scalability Groups (Checking against the original CVar value)
    if sg_ViewDistanceQuality_s then config = config .. string.format("sg_ViewDistanceQuality=%d\n", sg_ViewDistanceQuality) end
    if sg_ShadowQuality_s then config = config .. string.format("sg_ShadowQuality=%d\n", sg_ShadowQuality) end
    if sg_PostProcessQuality_s then config = config .. string.format("sg_PostProcessQuality=%d\n", sg_PostProcessQuality) end
    if sg_EffectsQuality_s then config = config .. string.format("sg_EffectsQuality=%d\n", sg_EffectsQuality) end
    if sg_TextureQuality_s then config = config .. string.format("sg_TextureQuality=%d\n", sg_TextureQuality) end
    if sg_FoliageQuality_s then config = config .. string.format("sg_FoliageQuality=%d\n", sg_FoliageQuality) end

    -- Integer LOD Bias Settings
    if r_SkeletalMeshLODBias_s then config = config .. string.format("r_SkeletalMeshLODBias=%d\n", r_SkeletalMeshLODBias) end
    if r_StaticMeshLODBias_s then config = config .. string.format("r_StaticMeshLODBias=%d\n", r_StaticMeshLODBias) end
    if r_MipMapLODBias_s then config = config .. string.format("r_MipMapLODBias=%d\n", r_MipMapLODBias) end
    if r_ParticleLODBias_s then config = config .. string.format("r_ParticleLODBias=%d\n", r_ParticleLODBias) end

    -- Integer Shadow/Lumen Settings
    if r_ShadowQuality_s then config = config .. string.format("r_ShadowQuality=%d\n", r_ShadowQuality) end
    if r_Shadow_MaxResolution_s then config = config .. string.format("r_Shadow_MaxResolution=%d\n", r_Shadow_MaxResolution) end

	var, valid = get_cvar_int("r.Lumen.Reflections.Temporal") 
    if valid and r_Lumen_Reflections_Temporal_s then config = config .. string.format("r_Lumen_Reflections_Temporal=%d\n", r_Lumen_Reflections_Temporal) end

    ---------------------------------------------------
    -- Group 2: Float values (using %.2f)
    ---------------------------------------------------

    -- Note on Float Checks: Comparing floats for exact equality (e.g., a ~= b)
    -- can be unreliable due to floating-point precision. However, for CVars read 
    -- and written back, it's often close enough, or you might prefer a check like 
    -- 'if math.abs(a - b) > 0.01' to check for a meaningful change. I will use 
    -- direct comparison as requested by your setup.

    if r_ViewDistanceScale_s then config = config .. string.format("r_ViewDistanceScale=%.2f\n", r_ViewDistanceScale) end
    if r_StaticMeshLODDistanceScale_s then config = config .. string.format("r_StaticMeshLODDistanceScale=%.2f\n", r_StaticMeshLODDistanceScale) end
    if r_SkeletalMeshLODDistanceScale_s then config = config .. string.format("r_SkeletalMeshLODDistanceScale=%.2f\n", r_SkeletalMeshLODDistanceScale) end

	var, valid = get_cvar_float("foliage.LODDistanceScale")
	if valid and foliage_LODDistanceScale_s then config = config .. string.format("foliage_LODDistanceScale=%.2f\n", foliage_LODDistanceScale) end
    if r_Shadow_DistanceScale_s then config = config .. string.format("r_Shadow_DistanceScale=%.2f\n", r_Shadow_DistanceScale) end

    ---------------------------------------------------
    -- Final action
    ---------------------------------------------------
    fs.write(config_filename, config)
end

local function read_config()
    local config_data = fs.read(config_filename)
    if config_data then
        for key, value in config_data:gmatch("([^=]+)=([^\n]+)\n?") do
            local num_val = tonumber(value)
            if key == "r_Fog" then r_Fog = num_val; r_Fog_s = true
            elseif key == "r_VolumetricFog" then r_VolumetricFog = num_val; r_VolumetricFog_s = true
            elseif key == "r_FilmGrain" then r_FilmGrain = num_val; r_FilmGrain_s = true
            elseif key == "r_PropagateAlpha" then r_PropagateAlpha = num_val; r_PropagateAlpha_s = true
            elseif key == "r_MeshBlend" then r_MeshBlend = num_val; r_MeshBlend_s = true
            elseif key == "Lumen" then Lumen = num_val; Lumen_s = true;
            elseif key == "Nanite" then Nanite = num_val; Nanite_s = true;
            elseif key == "Global_Illum" then Global_Illum = num_val; Global_Illum_s = true
            elseif key == "sg_ViewDistanceQuality" then sg_ViewDistanceQuality = num_val; sg_ViewDistanceQuality_s = true
            elseif key == "sg_ShadowQuality" then sg_ShadowQuality = num_val; sg_ShadowQuality_s = true
            elseif key == "sg_PostProcessQuality" then sg_PostProcessQuality = num_val; sg_PostProcessQuality_s = true
            elseif key == "sg_EffectsQuality" then sg_EffectsQuality = num_val; sg_EffectsQuality_s = true
            elseif key == "sg_TextureQuality" then sg_TextureQuality = num_val; sg_TextureQuality_s = true
            elseif key == "sg_FoliageQuality" then sg_FoliageQuality = num_val; sg_FoliageQuality_s = true
            elseif key == "r_ViewDistanceScale" then r_ViewDistanceScale = num_val; r_ViewDistanceScale_s = true
            elseif key == "r_StaticMeshLODDistanceScale" then r_StaticMeshLODDistanceScale = num_val; r_StaticMeshLODDistanceScale_s = true
            elseif key == "r_SkeletalMeshLODDistanceScale" then r_SkeletalMeshLODDistanceScale = num_val; r_SkeletalMeshLODDistanceScale_s = true
            elseif key == "r_SkeletalMeshLODBias" then r_SkeletalMeshLODBias = num_val; r_SkeletalMeshLODBias_s = true
            elseif key == "r_StaticMeshLODBias" then r_StaticMeshLODBias = num_val; r_StaticMeshLODBias_s = true
            elseif key == "r_MipMapLODBias" then r_MipMapLODBias = num_val; r_MipMapLODBias_s = true
            elseif key == "r_ParticleLODBias" then r_ParticleLODBias = num_val; r_ParticleLODBias_s = true
            elseif key == "foliage_LODDistanceScale" then foliage_LODDistanceScale = num_val; foliage_LODDistanceScale_s = true
            elseif key == "r_ShadowQuality" then r_ShadowQuality = num_val; r_ShadowQuality_s = true
            elseif key == "r_Shadow_MaxResolution" then r_Shadow_MaxResolution = num_val; r_Shadow_MaxResolution_s = true
            elseif key == "r_Shadow_DistanceScale" then r_Shadow_DistanceScale = num_val; r_Shadow_DistanceScale_s = true
            elseif key == "r_Lumen_Reflections_Temporal" then r_Lumen_Reflections_Temporal = num_val; r_Lumen_Reflections_Temporal_s = true
            end
        end
    end
end

local function set_cvar_int(cvar, value)
	local old_cvar_val, readable = get_cvar_int(cvar)
	
	if value ~= old_cvar_val or readable == false then 
		functions.log_info("Setting cvar int " .. cvar .. " from " .. old_cvar_val .. " to " .. value)
		local console_manager = api:get_console_manager()
		local var = console_manager:find_variable(cvar)
		if var ~= nil then
			var:set_int(value)
		end
	end
end


local function set_cvar_float(cvar, value)
	local old_cvar_val, readable = get_cvar_float(cvar)
	
	if value ~= old_cvar_val or readable == false then 
		functions.log_info("Setting cvar float " .. cvar .. " from " .. old_cvar_val .. " to " .. value)
		local console_manager = api:get_console_manager()
		local var = console_manager:find_variable(cvar)
		if var ~= nil then
			var:set_float(value)
		end
	end
end

local function apply_cvars()
    functions.log_info("cvars: applying_cvars")
    -- Original CVARs
    set_cvar_int("r.Fog", r_Fog)
    set_cvar_int("r.VolumetricFog", r_VolumetricFog)
    set_cvar_int("r.FilmGrain", r_FilmGrain)
    set_cvar_int("r.PostProcessing.PropagateAlpha", r_PropagateAlpha)
    set_cvar_int("r.MeshBlend.Enable", r_MeshBlend)
    set_cvar_int("r.DynamicGlobalIlluminationMethod", Global_Illum)
    
    -- Scalability Groups
    set_cvar_int("sg.ViewDistanceQuality", sg_ViewDistanceQuality)
    set_cvar_int("sg.ShadowQuality", sg_ShadowQuality)
    set_cvar_int("sg.PostProcessQuality", sg_PostProcessQuality)
    set_cvar_int("sg.EffectsQuality", sg_EffectsQuality)
    set_cvar_int("sg.TextureQuality", sg_TextureQuality)
    set_cvar_int("sg.FoliageQuality", sg_FoliageQuality)
    
    -- LOD Settings
    set_cvar_float("r.ViewDistanceScale", r_ViewDistanceScale)
    set_cvar_float("r.StaticMeshLODDistanceScale", r_StaticMeshLODDistanceScale)
    set_cvar_float("r.SkeletalMeshLODDistanceScale", r_SkeletalMeshLODDistanceScale)
    set_cvar_int("r.SkeletalMeshLODBias", r_SkeletalMeshLODBias)
    set_cvar_int("r.StaticMeshLODBias", r_StaticMeshLODBias)
    set_cvar_int("r.MipMapLODBias", r_MipMapLODBias)
    set_cvar_int("r.ParticleLODBias", r_ParticleLODBias)
    set_cvar_float("foliage.LODDistanceScale", foliage_LODDistanceScale)
    
    -- Shadow Settings
    set_cvar_int("r.ShadowQuality", r_ShadowQuality)
    set_cvar_int("r.Shadow.MaxResolution", r_Shadow_MaxResolution)
    set_cvar_float("r.Shadow.DistanceScale", r_Shadow_DistanceScale)
    
    -- Lumen Settings
    set_cvar_int("r.Lumen.Reflections.Temporal", r_Lumen_Reflections_Temporal)
    
    
    -- Original Lumen handling
    if Lumen > 0 then
        if Lumen == 1 then
            set_cvar_int("r.Lumen", 0)
        elseif Lumen == 2 then
            set_cvar_int("r.Lumen", 1)
            set_cvar_int("r.Lumen.Reflections.Temporal", 0)
            set_cvar_int("r.Lumen.Reflections.Allow", 0)
            set_cvar_int("r.Lumen.DiffuseIndirect.Allow", 0)
            set_cvar_int("r.DFDistanceScale", 1)
        else
            set_cvar_int("r.Lumen", 1)
            set_cvar_int("r.Lumen.Reflections.Temporal", 1)
            set_cvar_int("r.Lumen.Reflections.Allow", 1)
            set_cvar_int("r.Lumen.DiffuseIndirect.Allow", 1)
            set_cvar_int("r.DFDistanceScale", 2)
        end
    end
    
    -- Original Nanite handling
    if Nanite > 0 then
        if Nanite == 1 then
            set_cvar_int("r.Nanite", 0)
        elseif Nanite == 2 then
            set_cvar_int("r.Nanite", 1)
            set_cvar_int("r.Nanite.AllowComputeMaterials", 0)
            set_cvar_int("r.Nanite.AllowLegacyMaterials", 0)
        else
            set_cvar_int("r.Nanite", 1)
            set_cvar_int("r.Nanite.AllowComputeMaterials", 1)
            set_cvar_int("r.Nanite.AllowLegacyMaterials", 1)
        end
    end
    
    functions.log_info("Done applying cvars")
end

local function add_imgui_combo(cvar_name, index, combo_values)
    local val, readable = get_cvar_int(cvar_name)

    if readable then
        local changed, new_index = imgui.combo(cvar_name, index+1, combo_values)
        if changed then 
            new_index = new_index - 1
            return true, new_index
        end
        
        -- Return false if no change occurred
        return false, index
    else
        -- If the CVar is not readable (i.e., not available in the current context)
        -- We still call imgui.combo to display a disabled "Not Available" message
        imgui.combo(cvar_name, 1, {"Not Available"})
        return false, nil
    end
end

uevr.lua.add_script_panel("Extended CVARs", function()
    local needs_config_write = false
   	local val = 0
    local readable = false
    local changed = 0
    local new_value = 0	

    
    if imgui.collapsing_header("Original CVARs") then
        changed, new_value = add_imgui_combo("r.Fog", r_Fog, {"Disabled", "Enabled"})
        if changed then r_Fog = new_value; needs_config_write = true; r_Fog_s = true  end
        
        changed, new_value = add_imgui_combo("r.VolumetricFog", r_VolumetricFog, {"Disabled", "Enabled"})
        if changed then r_VolumetricFog = new_value; needs_config_write = true; r_VolumetricFog_s = true end
        
        changed, new_value = add_imgui_combo("r.FilmGrain", r_FilmGrain, {"Disabled", "Enabled"})
        if changed then r_FilmGrain = new_value; needs_config_write = true; r_FilmGrain_s = true end
        
        changed, new_value = add_imgui_combo("r.PostProcessing.PropagateAlpha", r_PropagateAlpha, {"0", "1", "2"})
        if changed then r_PropagateAlpha = new_value; needs_config_write = true; r_PropagateAlpha_s = true end

        changed, new_value = add_imgui_combo("r.MeshBlend.Enable", r_MeshBlend, {"0", "1"})
        if changed then r_MeshBlend = new_value; needs_config_write = true; r_MeshBlend_s = true end

        changed, new_value = add_imgui_combo("r.DynamicGlobalIlluminationMethod", Global_Illum, {"0", "1", "2", "3"})
        if changed then Global_Illum = new_value; needs_config_write = true; Global_Illum_s = true end
    end
    
    if imgui.collapsing_header("Scalability Groups") then
        val, readable = get_cvar_int("sg.ViewDistanceQuality")
        if readable == true then
            local changed, new_value = imgui.slider_int("sg.ViewDistanceQuality", sg_ViewDistanceQuality, 0, 4)
            if changed then sg_ViewDistanceQuality = new_value; needs_config_write = true; sg_ViewDistanceQuality_s = true end
        end
        
        val, readable = get_cvar_int("sg.ShadowQuality")
        if readable == true then
            local changed, new_value = imgui.slider_int("sg.ShadowQuality", sg_ShadowQuality, 0, 4)
            if changed then sg_ShadowQuality = new_value; needs_config_write = true; sg_ShadowQuality_s = true end
        end
        
        val, readable = get_cvar_int("sg.PostProcessQuality")
        if readable == true then
            local changed, new_value = imgui.slider_int("sg.PostProcessQuality", sg_PostProcessQuality, 0, 4)
            if changed then sg_PostProcessQuality = new_value; needs_config_write = true; sg_PostProcessQuality_s = true end
        end
            
        val, readable = get_cvar_int("sg.EffectsQuality")
        if readable == true then
            local changed, new_value = imgui.slider_int("sg.EffectsQuality", sg_EffectsQuality, 0, 4)
            if changed then sg_EffectsQuality = new_value; needs_config_write = true; sg_EffectsQuality_s = true end
        end
            
        val, readable = get_cvar_int("sg.TextureQuality")
        if readable == true then
            local changed, new_value = imgui.slider_int("sg.TextureQuality", sg_TextureQuality, 0, 4)
            if changed then sg_TextureQuality = new_value; needs_config_write = true; sg_TextureQuality_s = true end
        end
            
        val, readable = get_cvar_int("sg.FoliageQuality")
        if readable == true then
            local changed, new_value = imgui.slider_int("sg.FoliageQuality", sg_FoliageQuality, 0, 4)
            if changed then sg_FoliageQuality = new_value; needs_config_write = true; sg_FoliageQuality_s = true end
        end
    end
    
    if imgui.collapsing_header("LOD Settings") then
        val, readable = get_cvar_float("r.ViewDistanceScale")
        if readable == true then
            local changed, new_value = imgui.slider_float("r.ViewDistanceScale", r_ViewDistanceScale, 0.1, 5.0)
            if changed then r_ViewDistanceScale = new_value; needs_config_write = true; r_ViewDistanceScale_s = true end
        end
        
        val, readable = get_cvar_float("r.StaticMeshLODDistanceScale")
        if readable == true then
            local changed, new_value = imgui.slider_float("r.StaticMeshLODDistanceScale", r_StaticMeshLODDistanceScale, 0.1, 3.0)
            if changed then r_StaticMeshLODDistanceScale = new_value; needs_config_write = true; r_StaticMeshLODDistanceScale_s = true end
        end
            
        val, readable = get_cvar_float("r.SkeletalMeshLODDistanceScale")
        if readable == true then
            local changed, new_value = imgui.slider_float("r.SkeletalMeshLODDistanceScale", r_SkeletalMeshLODDistanceScale, 0.1, 3.0)
            if changed then r_SkeletalMeshLODDistanceScale = new_value; needs_config_write = true; r_SkeletalMeshLODDistanceScale_s = true end
        end
            
        val, readable = get_cvar_int("r.SkeletalMeshLODBias")
        if readable == true then
            local changed, new_value = imgui.slider_int("r.SkeletalMeshLODBias", r_SkeletalMeshLODBias, -3, 3)
            if changed then r_SkeletalMeshLODBias = new_value; needs_config_write = true; r_SkeletalMeshLODBias_s = true end
        end
            
        val, readable = get_cvar_int("r.StaticMeshLODBias")
        if readable == true then
            local changed, new_value = imgui.slider_int("r.StaticMeshLODBias", r_StaticMeshLODBias, -3, 3)
            if changed then r_StaticMeshLODBias = new_value; needs_config_write = true; r_StaticMeshLODBias_s = true end
        end
            
        val, readable = get_cvar_int("r.MipMapLODBias")
        if readable == true then
            local changed, new_value = imgui.slider_int("r.MipMapLODBias", r_MipMapLODBias, -3, 3)
            if changed then r_MipMapLODBias = new_value; needs_config_write = true; r_MipMapLODBias_s = true end
        end
            
        val, readable = get_cvar_int("r.ParticleLODBias")
        if readable == true then
            local changed, new_value = imgui.slider_int("r.ParticleLODBias", r_ParticleLODBias, -3, 3)
            if changed then r_ParticleLODBias = new_value; needs_config_write = true; r_ParticleLODBias_s = true end
        end
        
        val, readable = get_cvar_float("foliage.LODDistanceScale")
        if readable == true then
            local changed, new_value = imgui.slider_float("foliage.LODDistanceScale", foliage_LODDistanceScale, 0.1, 5.0)
            if changed then foliage_LODDistanceScale = new_value; needs_config_write = true; foliage_LODDistanceScale_s = true end
        end
    end
    
    if imgui.collapsing_header("Shadow Settings") then
        val, readable = get_cvar_int("r.ShadowQuality")
        if readable == true then
            local changed, new_value = imgui.slider_int("r.ShadowQuality", r_ShadowQuality, 0, 5)
            if changed then r_ShadowQuality = new_value; needs_config_write = true; r_ShadowQuality_s = true end
        end
            
        val, readable = get_cvar_int("r.Shadow.MaxResolution")
        if readable == true then
            local changed, new_value = imgui.slider_int("r.Shadow.MaxResolution", r_Shadow_MaxResolution, 512, 4096)
            if changed then r_Shadow_MaxResolution = new_value; needs_config_write = true; r_Shadow_MaxResolution_s = true end
        end
            
        val, readable = get_cvar_float("r.Shadow.DistanceScale")
        if readable == true then
            local changed, new_value = imgui.slider_float("r.Shadow.DistanceScale", r_Shadow_DistanceScale, 0.1, 5.0)
            if changed then r_Shadow_DistanceScale = new_value; needs_config_write = true; r_Shadow_DistanceScale_s = true end
        end
    end
    
    if imgui.collapsing_header("Lumen / Nanite Settings") then
        val, readable = get_cvar_int("r.Lumen.Reflections.Temporal")
        if readable == true then
            local changed, new_value = imgui.checkbox("r.Lumen.Reflections.Temporal", r_Lumen_Reflections_Temporal == 1)
            if changed then r_Lumen_Reflections_Temporal = new_value and 1 or 0; needs_config_write = true; r_Lumen_Reflections_Temporal_s = true end
        end
        
        local changed, new_value = imgui.combo("Lumen", Lumen + 1, {"Unknown", "Disabled", "Partial", "Enabled"})
        if changed then 
            Lumen = new_value - 1
            needs_config_write = true
            Lumen_s = true
        end

        val, readable = get_cvar_int("r.Nanite")
        if readable == true then
            local changed, new_value = imgui.combo("Nanite", Nanite + 1, {"Unknown", "Disabled", "Partial", "Enabled"})
            if changed then 
                Nanite = new_value - 1
                needs_config_write = true
                Nanite_s = true
            end
        end
	end
    
    if needs_config_write == true then
        functions.log_info("cvars: About to write cvars")
        write_config()
        functions.log_info("cvars: About to apply cvars")
        apply_cvars()
        functions.log_info("cvars: done")
   end
end)

read_config()
apply_cvars()