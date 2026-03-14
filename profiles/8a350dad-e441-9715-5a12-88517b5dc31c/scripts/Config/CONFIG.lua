local functions = uevr.params.functions

--Preferences
local check_uevr_version = true
local include_header = true

-- Static variables for headers
local config_filename = "main-config.json"
local title = "AltLo UEVR Settings"
local author = "Pande4360"
local profile_name = "Exfil"

local required_uevr_commit_count = nil
local uevr_version = nil

if check_uevr_version then
    required_uevr_commit_count = 1343
    uevr_version = functions.get_tag_long() .. "+" .. functions.get_commit_hash()
end

local json_files = {}

-- Initial config setup
config_table = {
		MotionMovement_C = true,
		MotionMovementStrength_C = 30,
		GripIsReload_C=false,
		NaloMin_C = 0.01,
		NaloRhWt_C= 1,
		NaloLhWt_C= 1,
		NaloHWt_C = 4,
		NaloSprintTreshhold_C=1.2
		
		--isRhand = true	
}

json_files = fs.glob(config_filename)

--Check if config exists and create it if not
if #json_files == 0 then
    json.dump_file(config_filename, config_table, 4)
end

local re_read_table = json.load_file(config_filename)

for _, key in ipairs(config_table) do
    assert(re_read_table[key] == config_table[key], key .. "is not the same")
end

for key, value in pairs(re_read_table) do
    config_table[key] = value
end

--Assign config variables



MotionMovement = config_table.MotionMovement_C
MotionMovementStrength = config_table.MotionMovementStrength_C
NaloMin = config_table.NaloMin_C
NaloRhWt = config_table.NaloRhWt_C
NaloLhWt = config_table.NaloLhWt_C
NaloHWt = config_table.NaloHWt_C
NaloSprintTreshhold= config_table.NaloSprintTreshhold_C
GripIsReload = config_table.GripIsReload_C
UIFollow = config_table.UIFollow_C
Snapturn = config_table.Snapturn_C
--isRhand = config_table.isRhand


local function uevr_version_check()
    imgui.text("UEVR Version Check: ")
    imgui.same_line()
    if functions.get_total_commits() == required_uevr_commit_count then
        imgui.text_colored("Success", 0xFF00FF00)
    elseif functions.get_total_commits() > required_uevr_commit_count then
        imgui.text_colored("Newer", 0xFF00FF00)
        imgui.text("UEVR Version: " .. uevr_version)
        imgui.same_line()
        imgui.text("UEVR Build Date: " .. functions.get_build_date())
    elseif functions.get_total_commits() < required_uevr_commit_count then
        imgui.text_colored("Failed - Older", 0xFF0000FF)
        imgui.text("UEVR Version: " .. uevr_version)
        imgui.same_line()
        imgui.text("UEVR Build Date: " .. functions.get_build_date())
    end
end

local function create_header()
    imgui.text(title)
    imgui.text("By: " .. author)
    imgui.same_line()
    imgui.text("Profile: " .. profile_name)
   -- imgui.same_line()
    --imgui.text("Version: " .. profile_version)

    if check_uevr_version then
        uevr_version_check()
    end
    imgui.new_line()
end

local function create_dropdown(label_name, key_name, values)
    local changed, new_value = imgui.combo(label_name, config_table[key_name], values)

    if changed then
        config_table[key_name] = new_value
        json.dump_file(config_filename, config_table, 4)
        return new_value
    else
        return config_table[key_name]
    end
end

local function create_checkbox(label_name, key_name)
    local changed, new_value = imgui.checkbox(label_name, config_table[key_name])

    if changed then
        config_table[key_name] = new_value
        json.dump_file(config_filename, config_table, 4)
        return new_value
    else
        return config_table[key_name]
    end
end

local function create_slider_int(label_name, key_name, min, max)
    local changed, new_value = imgui.slider_int(label_name, config_table[key_name], min, max)

    if changed then
        config_table[key_name] = new_value
        json.dump_file(config_filename, config_table, 4)
        return new_value
    else
        return config_table[key_name]
    end
end

local function create_slider_float(label_name, key_name, min, max)
    local changed, new_value = imgui.slider_float(label_name, config_table[key_name], min, max)

    if changed then
        config_table[key_name] = new_value
        json.dump_file(config_filename, config_table, 4)
        return new_value
    else
        return config_table[key_name]
    end
end

uevr.sdk.callbacks.on_draw_ui(function()
    if include_header then
        create_header()
    end

    for _, file in ipairs(json_files) do
        imgui.text(file)
    end
    
  

    
    imgui.new_line()

    imgui.text("Features")
	
	--UIFollowsView = create_checkbox("UI Follows View", "UI_Follows_View")
	MotionMovement= create_checkbox("Motion based movement", "MotionMovement_C")	
	MotionMovementStrength =   create_slider_float("Nalo: Motion Dampening", "MotionMovementStrength_C", 1.00,30.00)
	NaloMin =   create_slider_float("AltLo: Min Stick Value", "NaloMin_C", 0.00,1.00)
	NaloMin =   create_slider_float("AltLo: SprintFactor Treshhold", "NaloSprintTreshhold_C", 1.00,2.00)
	NaloHWt = create_slider_float(  "AltLo: HeadInfluence Factor", "NaloHWt_C", 0.00,10.00)
	NaloRhWt = create_slider_float( "AltLo: RightHand Influence Factor", "NaloRhWt_C", 0.00,10.00)
	NaloLhWt = create_slider_float( "AltLo: LeftHand Influence Factor", "NaloLhWt_C", 0.00,10.00)
	GripIsReload = create_checkbox( "Grip For Reloading else Trigger", "GripIsReload_C")
	UIFollow = create_checkbox("UI follows view", "UIFollow_C")
	Snapturn = create_checkbox("Enable Snapturn", "Snapturn_C")
end)


	--DEBUG VALUES, to test to fix some potnetial issues:
	--1. Collision Capsule: try increase Half Height first. If you start floating before solving the issue, go back and increase capsRad, CapsRad is important to kept low as possible for melee to work as intended. 
	--CapsuleHalfHeightWhenMoving= 97  --Vanilla=90 , when not moving it´s 90
	--CapsuleRadWhenMoving= 30.480	   --Vanilla=30, when not moving it´s 7.93
	--
	--
	--
	----not functional:
	--isRhand = true	
	--isLeftHandModeTriggerSwitchOnly = true
	