local api = uevr.api
local vr = uevr.params.vr

local prevViewTarget = nil
local game_engine_class = uevr.api:find_uobject("Class /Script/Engine.GameEngine")

local classCache = {}
function get_class(name, clearCache)
	if clearCache or classCache[name] == nil then
		classCache[name] = uevr.api:find_uobject(name)
	end
    return classCache[name]
end


local config_filename = "TheOuterWorlds2.txt"
local config_data = nil
local config_changed = false
local normal_depth = 1.2
local normal_size = 1.2
local aiming_depth = 10
local aiming_size = 6.5
local conversation_depth = 0.4
local conversation_size = 0.35
local hud_state_far = true
local last_changed = os.clock() 
local forward_offset_multiplier = 3.6
local up_offset_multiplier = 0.2
local fov_max_trigger = 50
local current_fov = 0
local enable_fov_zoom = true
local enable_conv_fix = true
local enable_aim_distances = true
local target = nil
local aim_method = 2
local enable_conv_shadows = true
local conv_shadows_true_percentage = 40
local conv_shadows_false_percentage = 50
local shadows_current_value = 1
local was_conv_distance = false

local function write_config()
	config_data = "normal_depth=" .. tostring(normal_depth) .. "\n"   
    config_data = config_data .. "normal_size=" .. tostring(normal_size) .. "\n"        
    config_data = config_data .. "aiming_depth=" .. tostring(aiming_depth) .. "\n"             
    config_data = config_data .. "aiming_size=" .. tostring(aiming_size) .. "\n"     
    config_data = config_data .. "conversation_depth=" .. tostring(conversation_depth) .. "\n"             
    config_data = config_data .. "conversation_size=" .. tostring(conversation_size) .. "\n"     
    config_data = config_data .. "forward_offset_multiplier=" .. tostring(forward_offset_multiplier) .. "\n"   
    config_data = config_data .. "up_offset_multiplier=" .. tostring(up_offset_multiplier) .. "\n"        
    config_data = config_data .. "enable_fov_zoom=" .. tostring(enable_fov_zoom) .. "\n"             
    config_data = config_data .. "fov_max_trigger=" .. tostring(fov_max_trigger) .. "\n"  
    config_data = config_data .. "aim_method=" .. tostring(aim_method) .. "\n"  
    config_data = config_data .. "enable_conv_fix=" .. tostring(enable_conv_fix) .. "\n"             
    config_data = config_data .. "enable_aim_distances=" .. tostring(enable_aim_distances) .. "\n"             
    config_data = config_data .. "enable_conv_shadows=" .. tostring(enable_conv_shadows) .. "\n"             
    config_data = config_data .. "conv_shadows_true_percentage=" .. tostring(conv_shadows_true_percentage) .. "\n"             
    config_data = config_data .. "conv_shadows_false_percentage=" .. tostring(conv_shadows_false_percentage) .. "\n"             
                  
    fs.write(config_filename, config_data)
end

local function read_config()
    print("reading config")
    config_data = fs.read(config_filename)
    if config_data then -- Check if file was read successfully
        print("config read")
        for key, value in config_data:gmatch("([^=]+)=([^\n]+)\n?") do                       
            if key == "normal_depth" then
                normal_depth = tonumber(value) or 1.2          
            end  
            if key == "normal_size" then
                normal_size = tonumber(value) or 1.2           
            end                   
            if key == "aiming_depth" then
                aiming_depth = tonumber(value) or 10          
            end                   
            if key == "aiming_size" then
                aiming_size = tonumber(value) or 7       
            end       
            if key == "conversation_depth" then
                conversation_depth = tonumber(value) or 0.4           
            end  
            if key == "conversation_size" then
                conversation_size = tonumber(value) or 0.35           
            end                            
            if key == "forward_offset_multiplier" then
                forward_offset_multiplier = tonumber(value) or 3.2            
            end  
            if key == "up_offset_multiplier" then
                up_offset_multiplier = tonumber(value) or 0.8            
            end                   
            if key == "fov_max_trigger" then
                fov_max_trigger = tonumber(value) or 50            
            end   
            if key == "aim_method" then
                aim_method = tonumber(value) or 2
            end                   
            if key == "enable_fov_zoom" then
                if value == "false" then
                    enable_fov_zoom = false
                else
                    enable_fov_zoom = true
                end                    
            end    
            if key == "enable_conv_fix" then
                if value == "false" then
                    enable_conv_fix = false
                else
                    enable_conv_fix = true
                end                    
            end    
            if key == "enable_aim_distances" then
                if value == "false" then
                    enable_aim_distances = false
                else
                    enable_aim_distances = true
                end                    
            end    
            if key == "enable_conv_shadows" then
                if value == "false" then
                    enable_conv_shadows = false
                else
                    enable_conv_shadows = true
                end                    
            end    
            if key == "conv_shadows_true_percentage" then
                conv_shadows_true_percentage = tonumber(value) or 40            
            end   
            if key == "conv_shadows_false_percentage" then
                conv_shadows_false_percentage = tonumber(value) or 50            
            end   
        end
    else
        print("Error: Could not read config file.")
    end
end

uevr.lua.add_script_panel("TheOuterWorlds2", function()    
    local needs_save = false
    local changed, new_value        

    changed, new_value = imgui.checkbox("Enable Rotation Fix", enable_conv_fix)
    if changed then
        needs_save = true
        enable_conv_fix = new_value -- Correctly use new_value                
    end    
    imgui.text("Auto toggles off aim method during conversations and menus to stop unwanted rotation")

    changed, new_value = imgui.combo("Aiming Method", aim_method, { "Head / HMD", "Right Controller"})
    if changed then
        needs_save = true
        aim_method = new_value -- Correctly use new_value                
        uevr.params.vr.set_mod_value("VR_AimMethod",aim_method)   
    end    

    imgui.text("")

    changed, new_value = imgui.checkbox("Enable Conversations Zoom", enable_fov_zoom)
    if changed then
        needs_save = true
        enable_fov_zoom = new_value -- Correctly use new_value                
    end    

    imgui.text("Conversations will closer match the desktop intended framing")        
    imgui.text(string.format("Current FOV: %.2f", current_fov))        
    -- if target then
    --     imgui.text("Current Target: " .. target:get_full_name())    
    -- end
    --imgui.text("")

    changed, new_value = imgui.slider_float("FOV Max Trigger Value", fov_max_trigger, 0, 150)
    if changed then
        needs_save = true
        fov_max_trigger = new_value -- Correctly use new_value                
    end

    changed, new_value = imgui.slider_float("Forward Offset Multiplier", forward_offset_multiplier, 0, 20)
    if changed then
        needs_save = true
        forward_offset_multiplier = new_value -- Correctly use new_value                
    end     

    changed, new_value = imgui.slider_float("Up Offset Multiplier", up_offset_multiplier, 0, 10)
    if changed then
        needs_save = true
        up_offset_multiplier = new_value -- Correctly use new_value                
    end         

    imgui.text("")

    changed, new_value = imgui.checkbox("Enable Auto Aiming Distance Toggle", enable_aim_distances)
    if changed then
        needs_save = true
        enable_aim_distances = new_value -- Correctly use new_value                
    end    

    imgui.text("Sets the UI far away when aiming for accuracy")    
    imgui.text("Sets the UI to normal whenever you press start or back for menus")
    imgui.text("Sets the UI close in conversations in front of characters")

    changed, new_value = imgui.slider_float("Normal Distance", normal_depth, 0, 10)
    if changed then
        needs_save = true
        normal_depth = new_value -- Correctly use new_value                
    end

    changed, new_value = imgui.slider_float("Normal Size", normal_size, 0, 10)
    if changed then
        needs_save = true
        normal_size = new_value -- Correctly use new_value                
    end

    changed, new_value = imgui.slider_float("Aiming Distance", aiming_depth, 0, 10)
    if changed then
        needs_save = true
        aiming_depth = new_value -- Correctly use new_value                
    end

    changed, new_value = imgui.slider_float("Aiming Size", aiming_size, 0, 10)
    if changed then
        needs_save = true
        aiming_size = new_value -- Correctly use new_value                
    end

    changed, new_value = imgui.slider_float("Conversation Distance", conversation_depth, 0, 10)
    if changed then
        needs_save = true
        conversation_depth = new_value -- Correctly use new_value                
    end

    changed, new_value = imgui.slider_float("Conversation Size", conversation_size, 0, 10)
    if changed then
        needs_save = true
        conversation_size = new_value -- Correctly use new_value                
    end    
    
    imgui.text("")

    changed, new_value = imgui.checkbox("Enhance Conversations Shadows", enable_conv_shadows)
    if changed then
        needs_save = true
        enable_conv_shadows = new_value -- Correctly use new_value                
    end 

    imgui.text("During conversations high quality shadows will be used, this will affect performance")     
    -- imgui.text("Set screen percentages, use lower value for shadows to render smoothly")     

    -- changed, new_value = imgui.slider_int("Standard Screen Percentage", conv_shadows_false_percentage, 1, 100)
    -- if changed then
    --     needs_save = true
    --     conv_shadows_false_percentage = new_value -- Correctly use new_value                
    -- end    

    -- changed, new_value = imgui.slider_int("Shadows Screen Percentage", conv_shadows_true_percentage, 1, 100)
    -- if changed then
    --     needs_save = true
    --     conv_shadows_true_percentage = new_value -- Correctly use new_value                
    -- end    

    if needs_save then
        config_changed = true
        write_config()
    end
end)

read_config()


local IsInMenu = false
local LedgerClass = nil
local BackDown = false
local BDown = false
local WasBackDown = false
local WasBDown = false

local function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        return nil
    end

    return obj
end

local function OpenMenu()
    if IsInMenu == true then return end
    IsInMenu = true
    print("Calling open menu set IsInMenu true")
    
    if LedgerClass == nil then
        LedgerClass = find_required_object("Class /Script/Arkansas.IndianaPlayerController")
        if LedgerClass == nil then return end
    end
    
    local instance = LedgerClass:get_first_object_matching(true)
    if instance ~= nil then
        if instance.OpenLedger then
            instance:OpenLedger()
        end
    end
end

local function CloseMenu()
    if IsInMenu == false then return end
    IsInMenu = false
    print("Calling closemenu set IsInMenu false")
    if LedgerClass == nil then
        LedgerClass = find_required_object("Class /Script/Arkansas.IndianaPlayerController")
        if LedgerClass == nil then return end
    end
    
    local instance = LedgerClass:get_first_object_matching(true)
    if instance ~= nil then
        if instance.CloseLedger then
            instance:CloseLedger()
        end
    else
        print("closeledger not exist")
    end

end


uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)    
    if enable_aim_distances then        
        local gamepad = state.Gamepad
        local left_trigger_pressed = false    
        
        if (gamepad.bLeftTrigger > 220) then
            left_trigger_pressed = true
        elseif (gamepad.bLeftTrigger < 10) then
            left_trigger_pressed = false
        end

        local buttons = gamepad.wButtons                
        local menu_pressed = (buttons & XINPUT_GAMEPAD_START) ~= 0 or (buttons & XINPUT_GAMEPAD_BACK) ~= 0        

    end

    if state.Gamepad.wButtons & XINPUT_GAMEPAD_BACK == 0 then
        BackDown = false
    else
        BackDown = true
    end        
    
    if state.Gamepad.wButtons & XINPUT_GAMEPAD_B == 0 then
        BDown = false
    else
        BDown = true
    end        
    
    if IsInMenu == true then
        state.Gamepad.wButtons = state.Gamepad.wButtons & ~(XINPUT_GAMEPAD_BACK)
        
        if (BackDown and not WasBackDown) or (BDown and not WasBDown) then
            IsInMenu = false
            print(string.format("closing menu, setting larger aim size: %.6f", aiming_depth))
            uevr.params.vr.set_mod_value("UI_Distance", string.format("%.6f", aiming_depth))
            uevr.params.vr.set_mod_value("UI_Size", string.format("%.6f", aiming_size))                          
        end
    else
        if (BackDown and not WasBackDown) then        
            IsInMenu = true
            print("opening menu, setting menu aim size.")
            uevr.params.vr.set_mod_value("UI_Distance", string.format("%.6f", normal_depth))
            uevr.params.vr.set_mod_value("UI_Size", string.format("%.6f", normal_size))                    
        end
    end
    WasBackDown = BackDown
    WasBDown = BDown
end)

-- run this every engine tick, *after* the world has been updated
uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)   	    
    local game_engine       = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
    local player            = uevr.api:get_player_controller(0)
    if player then                                               
        local pawn = uevr.api:get_local_pawn(0)
        if pawn then            
            local playerController = pawn.Controller
            if playerController ~= nil then	
                local cameraManager = playerController.PlayerCameraManager                
                if cameraManager ~= nil then
                    target = cameraManager.ViewTarget.Target
                    current_fov = 0
                    if (cameraManager and cameraManager.ViewTarget and cameraManager.ViewTarget.POV and cameraManager.ViewTarget.POV.FOV) then
                        current_fov = cameraManager.ViewTarget.POV.FOV
                    end                                                   
                end
            end
        end
        if current_fov>1 and current_fov<fov_max_trigger then                     
            if enable_aim_distances then
                was_conv_distance = true
                --also set UI to close
                uevr.params.vr.set_mod_value("UI_Distance", conversation_depth)
                uevr.params.vr.set_mod_value("UI_Size", conversation_size)
                last_changed = os.clock()          
            end
            if enable_conv_fix then
                uevr.params.vr.set_mod_value("VR_AimMethod",0)            
            end
            if enable_fov_zoom then
                --exclude terminals
                if current_fov <= 32.99 or current_fov >= 33.01 then
                    if enable_conv_shadows then
                        if shadows_current_value == 1 then
                            uevr.api:dispatch_custom_event("set_cvar", "r.Shadow.Virtual.Enable 0")                        
                            shadows_current_value = 0
                        end
                    end
                    --uevr.api:dispatch_custom_event("set_cvar", "r.ScreenPercentage " .. tostring(conv_shadows_true_percentage))
                    --uevr.api:dispatch_custom_event("set_cvar", "r.ScreenPercentage 33")
                    local forward = (fov_max_trigger-current_fov)*forward_offset_multiplier                            
                    if (forward > 0) then
                        uevr.params.vr.set_mod_value("VR_CameraForwardOffset",forward)
                    end

                    local up = (fov_max_trigger-current_fov)
                    if (up>0) then
                        up=up*up_offset_multiplier                                
                        uevr.params.vr.set_mod_value("VR_CameraUpOffset",up)
                    end
                end
            end
        else                     
            if enable_conv_fix then                
                if IsInMenu then
                    uevr.params.vr.set_mod_value("VR_AimMethod",0) 
                else
                    uevr.params.vr.set_mod_value("VR_AimMethod",aim_method)            
                end
            end
            if enable_fov_zoom then
                if enable_conv_shadows then
                    if shadows_current_value == 0 then
                        uevr.api:dispatch_custom_event("set_cvar", "r.Shadow.Virtual.Enable 1")
                        shadows_current_value = 1
                    end
                end
                --uevr.api:dispatch_custom_event("set_cvar", "r.ScreenPercentage " .. tostring(conv_shadows_false_percentage))
                --uevr.api:dispatch_custom_event("set_cvar", "r.ScreenPercentage 100")
                uevr.params.vr.set_mod_value("VR_CameraForwardOffset",0)
                uevr.params.vr.set_mod_value("VR_CameraUpOffset",0)                        
            end
            if enable_aim_distances and was_conv_distance then                
                uevr.params.vr.set_mod_value("UI_Distance", aiming_depth)
                uevr.params.vr.set_mod_value("UI_Size", aiming_size)                          
                was_conv_distance = false
            end
        end                            
    end        
end)
