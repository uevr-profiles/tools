local api = uevr.api
local vr  = uevr.params.vr

local config_filename = "cinematicszoom.txt"
local config_data = nil

local forward_offset_multiplier = 3.4
local up_offset_multiplier      = 0.3
local current_fov               = 0
local enable_fov_zoom           = true

local force_aim_method          = true
local forced_aim_method_int     = 3
local current_aim_method        = ""

local AIM_METHOD_LABELS = {
    [0] = "Game",
    [1] = "Head/HMD",
    [2] = "Right Controller",
    [3] = "Left Controller",
    [4] = "Two Handed (Right)",
    [5] = "Two Handed (Left)"
}

local function write_config()
    config_data =
        "forward_offset_multiplier=" .. tostring(forward_offset_multiplier) .. "\n" ..
        "up_offset_multiplier="      .. tostring(up_offset_multiplier)      .. "\n" ..
        "enable_fov_zoom="           .. tostring(enable_fov_zoom)           .. "\n" ..
        "force_aim_method="          .. tostring(force_aim_method)          .. "\n" ..
        "forced_aim_method_int="     .. tostring(forced_aim_method_int)     .. "\n"

    fs.write(config_filename, config_data)
end

local function read_config()
    config_data = fs.read(config_filename)
    if not config_data then return end

    for key, value in config_data:gmatch("([^=]+)=([^\n]+)\n?") do
        if key == "forward_offset_multiplier" then
            forward_offset_multiplier = tonumber(value) or forward_offset_multiplier
        elseif key == "up_offset_multiplier" then
            up_offset_multiplier = tonumber(value) or up_offset_multiplier
        elseif key == "enable_fov_zoom" then
            enable_fov_zoom = (value ~= "false")
        elseif key == "force_aim_method" then
            force_aim_method = (value ~= "false")
        elseif key == "forced_aim_method_int" then
            local v = tonumber(value)
            if v ~= nil and v >= 0 and v <= 5 then
                forced_aim_method_int = v
            end
        end
    end
end

uevr.lua.add_script_panel("Cinematics Zoom", function()
    imgui.text("Cinematics Zoom")
    imgui.text(string.format("Current FOV: %.2f", current_fov))
    imgui.separator()

    local needs_save = false
    local changed, new_value

    changed, new_value = imgui.slider_float("Forward Offset Multiplier", forward_offset_multiplier, 0, 5)
    if changed then forward_offset_multiplier = new_value; needs_save = true end

    changed, new_value = imgui.slider_float("Up Offset Multiplier", up_offset_multiplier, 0, 2)
    if changed then up_offset_multiplier = new_value; needs_save = true end

    changed, new_value = imgui.checkbox("Enable Zoom", enable_fov_zoom)
    if changed then enable_fov_zoom = new_value; needs_save = true end

    imgui.separator()
    imgui.text("Aim Method")

    changed, new_value = imgui.checkbox("Force Aim Method", force_aim_method)
    if changed then force_aim_method = new_value; needs_save = true end

    local preview = AIM_METHOD_LABELS[forced_aim_method_int] or ("Unknown (" .. tostring(forced_aim_method_int) .. ")")
    if imgui.begin_combo("Forced Aim Method", preview) then
        for i = 0, 5 do
            local label = AIM_METHOD_LABELS[i] or ("Unknown (" .. tostring(i) .. ")")
            local selected = (forced_aim_method_int == i)
            if imgui.selectable(label, selected) then
                forced_aim_method_int = i
                needs_save = true
            end
        end
        imgui.end_combo()
    end

    imgui.text("Current Aim Method: " .. tostring(current_aim_method))

    if needs_save then write_config() end
end)

read_config()

uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
    local cur = uevr.params.vr.get_aim_method()
    if force_aim_method and cur ~= forced_aim_method_int then
        uevr.params.vr.set_aim_method(forced_aim_method_int)
        cur = forced_aim_method_int
    end
    current_aim_method = AIM_METHOD_LABELS[cur] or ("Unknown (" .. tostring(cur) .. ")")

    local player = uevr.api:get_player_controller(0)
    if not player then return end

    local pawn = uevr.api:get_local_pawn(0)
    if pawn == nil or pawn.Controller == nil then return end

    local cameraManager = pawn.Controller.PlayerCameraManager
    if cameraManager == nil then return end

    current_fov = 0
    if cameraManager.ViewTarget and cameraManager.ViewTarget.POV and cameraManager.ViewTarget.POV.FOV then
        current_fov = cameraManager.ViewTarget.POV.FOV
    end

    if enable_fov_zoom and current_fov > 15 and current_fov < 50 then
        local forward = (50 - current_fov) * forward_offset_multiplier
        if forward > 0 then uevr.params.vr.set_mod_value("VR_CameraForwardOffset", forward) end

        local up = (50 - current_fov)
        if up > 0 then
            up = up * up_offset_multiplier
            uevr.params.vr.set_mod_value("VR_CameraUpOffset", up)
        end
    else
        uevr.params.vr.set_mod_value("VR_CameraForwardOffset", 0)
        uevr.params.vr.set_mod_value("VR_CameraUpOffset", 0)
    end
end)
