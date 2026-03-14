local functions = uevr.params.functions

--Preferences

local include_header = true

-- Static variables for headers
local config_filename = "main-config.json"
local title = "Ready Or Not Settings"
local author = "Pande4360"
local profile_name = "Visible Arms Profile"



local json_files = {}
 
 config_table = {
	isUpRecoilActive_c							=		true		,
    hide_arms_c			 						= 		true	    ,
    HapticFeedbackActive_c						=		true	    ,
    HapticFeedback_c							= 		true        ,
    PhysicalLeaning_c	 						= 		false       ,
    DisableUnnecessaryBindings_c				= 					true        ,
    -- if Bindings are disabled 			you can still to    ,
    DisableDpad_c								=	true	    ,
    DisableBButton_c							=	true        ,
    SwapCommandButtonWithX_c						=	true	    ,
    SprintingActivated_c							=	true        ,
    HolstersActive_c								=	true        ,
    WeaponInteractions_c							=	true        ,
    isRoomscale_c									=	true  	    ,
    isLeftHandModeTriggerSwitchOnly_c	 		= 		true        ,
    MeleePower_c									 = 	1500	    ,
    DefaultOffset_c								 =		-21.93      ,
    AutoHeal_c									=		false	    ,
    GripIsReload_c								 =		false       ,
	DebugCollision_c								=false,
	VoiceCommands_c									=true,
    isRhand_c										 = 	true	    
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
 
 
 
 
 
 
 
 --CONFIG SETTINGS-- YOU MAY EDIT THESE
	isUpRecoilActive=							config_table.isUpRecoilActive_c										--RECOIL UP ROTATION
	hide_arms = 								config_table.hide_arms_c			 									--HIDE ARMS (ONLY HANDS)
 	HapticFeedbackActive=						config_table.HapticFeedbackActive_c									--Haptic effects on shooting
  	HapticFeedback = 							config_table.HapticFeedback_c										   --haptic feedback for holsters
	PhysicalLeaning = 							config_table.PhysicalLeaning_c	 									    --Physical Leaning, might cause glitches on some heavy maps, investigating
	DisableUnnecessaryBindings= 				config_table.DisableUnnecessaryBindings_c	 						   --Disables some buttons that are replaced by gestures, e.g. reloading
	-- if Bindings are disabled you can 		config_table.-- if Bindings are disabled 							toggle these on:	
	DisableDpad				=					config_table.DisableDpad_c											-- disables DPAD when not using command menu
	DisableBButton			=					config_table.DisableBButton_c										
	SwapCommandButtonWithX		=				config_table.SwapCommandButtonWithX_c								--swaps command button with X button(B on right controller)
	SprintingActivated=							config_table.SprintingActivated_c									   --turns sprinting system on off
	HolstersActive=								config_table.HolstersActive_c										   --turns Holsters on off
	WeaponInteractions=							config_table.WeaponInteractions_c									   --Weapon interation gestures like reloading
	isRoomscale=								config_table.isRoomscale_c												 --experimental, stand in one default location or things are weird
	isLeftHandModeTriggerSwitchOnly = 			config_table.isLeftHandModeTriggerSwitchOnly_c						   --only swap triggers for left hand
	MeleePower = 								config_table.MeleePower_c											--Default = 1500, strength for melee to trigger
	DefaultOffset =								config_table.DefaultOffset_c											   --Pitch Offset of gun
	AutoHeal	=								config_table.AutoHeal_c												 --Activates Autohealing when not hit for 15s, heals up to 40 percent of Max hp
	GripIsReload =								config_table.GripIsReload_c											   -- Uses Grip For Reloading else uses Trigger
	DebugCollision =							config_table.DebugCollision_c
	VoiceCommands=								config_table.VoiceCommands_c
--Other variables, leave this alone                          isRhand_c							
	isRhand = 							true	 --right hand config
	



local function create_header()
    imgui.text(title)
    imgui.text("By: " .. author)
    imgui.same_line()
    imgui.text("Profile: " .. profile_name)
   -- imgui.same_line()
    --imgui.text("Version: " .. profile_version)

   
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
	

	
	isUpRecoilActive=						create_checkbox("Recoil Active", "isUpRecoilActive_c"					)
	hide_arms = 							create_checkbox("Hide Arms",                "hide_arms_c"	 			)
	HapticFeedbackActive=					create_checkbox("Holster Haptic Feedback"                ,"HapticFeedbackActive_c"               )
	HapticFeedback = 						create_checkbox("Shooting Haptic Feedback"                ,"HapticFeedback_c"			            )
	PhysicalLeaning = 						create_checkbox("Physical Leaning"                ,"PhysicalLeaning_c"	 				)
	DisableUnnecessaryBindings= 			create_checkbox("Disable Not needed Buttons"                ,"DisableUnnecessaryBindings_c"         )
	-- if Bindings are disabled you can 	create_checkbox("                ,"-- if Bindings are disabled 		    )
	DisableDpad				=				create_checkbox("	Including DPAD"               ,"DisableDpad_c"	                    )
	DisableBButton			=				create_checkbox("	Including Buttons"                ,"DisableBButton_c"					    )
	SwapCommandButtonWithX		=			create_checkbox("Swap Command Button to B"               ,"SwapCommandButtonWithX_c"			    )
	SprintingActivated=						create_checkbox("Enable Sprinting"               ,"SprintingActivated_c"		            )
	HolstersActive=							create_checkbox("Enable Holsters"                ,"HolstersActive_c"			            )
	WeaponInteractions=						create_checkbox("Enable WeaponInteractions"                ,"WeaponInteractions_c"				    )
	isRoomscale=							create_checkbox("Enable Roomscale"                ,"isRoomscale_c"			            )
	--isLeftHandModeTriggerSwitchOnly = 		create_checkbox("                ,"isLeftHandModeTriggerSwitchOnly_c"    )
	AutoHeal	=							create_checkbox("Enable AutoHeal"                ,"AutoHeal_c"					        )
	VoiceCommands =							create_checkbox("Enable VoiceAttack Commands(needs game)", "VoiceCommands_c")
	
	GripIsReload =							create_checkbox("Grip is Reload, else it´s Trigger"          ,"GripIsReload_c"						)
	MeleePower = 							create_slider_int("MeleePower", "MeleePower_c", 500,1500)
	DefaultOffset =							create_slider_float("Gun Angle Offset", "DefaultOffset_c", -60.00,20.00)
	 imgui.new_line()
	  imgui.new_line()
	DebugCollision =						create_checkbox("DEBUG: Visible Hand Collision Box"          ,"DebugCollision_c"						)
	
	
	
	
	
	
	
	
	
	
	
	
	
end)