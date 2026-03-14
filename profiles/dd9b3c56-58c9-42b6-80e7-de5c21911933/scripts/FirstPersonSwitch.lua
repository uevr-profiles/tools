-- Global variables
local lastModeName = ""
local isUObjectHookEnabled = true
local timeSinceLastCheck = 0.0
local checkInterval = 0.2

-- Global variable to store the PlayerCameraManager Class once found.
local PlayerCameraManager_Class = nil
local _last_print_PlayerCameraManager_Class_found_status = nil

-- Global variable to store the PlayerCameraManager object once found.
local PlayerCameraManager_Object = nil
local _last_print_PlayerCameraManager_Object_found_status = nil
local _last_print_ActiveCameraModeDefinition_found_status = nil
local _last_print_Data_found_status = nil
local _last_print_ModeName_accessed_status = nil

-- Global variable to store the SkeletalMeshComponent Class once found.
local SkeletalMeshComponent_Class = nil

-- Global variables for finding Cal's Pawn and BD-1's object.
local PlayerController_Class = nil
local _last_print_PlayerController_Class_found_status = nil
local PlayerController_Object = nil
local _last_print_PlayerController_Object_found_status = nil
local HeroPawn_Object = nil
local _last_print_HeroPawn_Object_found_status = nil
local BuddyDroid_Object = nil
local _last_print_BuddyDroid_Object_found_status = nil

-- Global variable to store the last known value of 'canForceSlowdown' for BD-1 detection
local lastCanForceSlowdown = nil

-- Helper functions (get_cal_attachments, hide_skeletal_meshes, unhide_skeletal_meshes)
local function get_cal_attachments(api, uobjectHook)
    if SkeletalMeshComponent_Class == nil then
        SkeletalMeshComponent_Class = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")
        if SkeletalMeshComponent_Class == nil then
            print("ERROR: Could not find SkeletalMeshComponent Class.")
            return nil, nil
        end
        print("DEBUG: Found SkeletalMeshComponent Class:", SkeletalMeshComponent_Class:get_full_name())
    end

    -- Use api:get_local_pawn(0) directly
    local acknowledgedPawn = api:get_local_pawn(0)
    if acknowledgedPawn == nil then
        print("WARNING: Acknowledged Pawn not found.")
        return nil, nil
    end

    local face = acknowledgedPawn.Face
    if face == nil then
        print("WARNING: 'Face' property/component not found on Acknowledged Pawn.")
        return nil, nil
    end

    local attachChildren = face.AttachChildren
    if attachChildren == nil then
        print("WARNING: 'AttachChildren' property/component not found on 'Face'.")
        return nil, nil
    end
    return attachChildren, SkeletalMeshComponent_Class
end

local function hide_skeletal_meshes(api, uobjectHook)
    print("Attempting to hide skeletal meshes...")
    local attachChildren, skelMeshClass = get_cal_attachments(api, uobjectHook)
    if attachChildren == nil or skelMeshClass == nil then return end

    local foundAnyToHide = false
    for i, child_object in ipairs(attachChildren) do
        if child_object ~= nil and child_object:is_a(skelMeshClass) then
            print("Found SkeletalMeshComponent under AttachChildren")
            local success_set_render, result_set_render = pcall(function() child_object:SetRenderInMainPass(false) end)
            if success_set_render then
                print("Hid using SetRenderInMainPass(false).")
                foundAnyToHide = true
            else
                print("Failed to hide " .. child_object:get_full_name() .. " using SetRenderInMainPass(false): " .. tostring(result_set_render))
            end
        end
    end

    if not foundAnyToHide then
        print("No SkeletalMeshComponents found to hide under the specified path.")
    end
end

local function unhide_skeletal_meshes(api, uobjectHook)
    print("Attempting to unhide ALL relevant skeletal meshes...")
    local attachChildren, skelMeshClass = get_cal_attachments(api, uobjectHook)
    if attachChildren == nil or skelMeshClass == nil then return end

    local unhiddenAny = false
    for i, child_object in ipairs(attachChildren) do
        if child_object ~= nil and child_object:is_a(skelMeshClass) then
            local success_unhide, result_unhide = pcall(function() child_object:SetRenderInMainPass(true) end)
            if success_unhide then
                print("Unhid using SetRenderInMainPass(true).")
                unhiddenAny = true
            else
                print("Failed to unhide " .. child_object:get_full_name() .. ": " .. tostring(result_unhide))
            end
        end
    end

    if not unhiddenAny then
        print("No skeletal meshes were found to unhide under the specified path.")
    end
end

-- This function is called every game engine tick.
-- 'engine' and 'delta' are arguments provided by UEVR.
uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
    -- Accumulate delta time
    timeSinceLastCheck = timeSinceLastCheck + delta

    -- Only perform checks every 'checkInterval' seconds
    if timeSinceLastCheck < checkInterval then
        return
    end
    -- Reset the timer after the check
    timeSinceLastCheck = 0.0

    -- --- IMPORTANT: Initialize API, Params, and UObjectHook *inside* the callback ---
    -- This ensures they are available when UEVR has fully initialized them.
    local api = uevr.api
    local params = uevr.params
    local uobjectHook = UEVR_UObjectHook

    -- Check if UEVR core APIs are available. If not, exit this tick's execution.
    if api == nil or params == nil or uobjectHook == nil then
        return -- Exit the function if any essential APIs aren't ready.
    end

    -- Define a table of ModeNames for which UObjectHook should be DISABLED.
    local disabledModeNames = {
        ["Animated"] = true,
		["AnimatedNoCol"] = true,
        ["CameraActor"] = true,
		["BinocularsCam"] = true,
        ["ZiplineAscend"] = true,
        ["ZiplineDescend"] = true,
        ["WorldMap_Follow"] = true,
        ["Handcuffed_Full_Rotation"] = true,
        ["POINormal_Coru_PreSuitCaseScan"] = true,
        ["POINormal_Coru_SuitCaseScan"] = true,
        ["POINormal_Coru_PreElevator"] = true,
        ["POINormal_Coru_PreElevator_pt2"] = true,
        ["POINormal_Coru_PreElevator_pt3"] = true,
        ["POINormal_CoruInElevator_Bode"] = true,
        ["POINormal_CoruInElevator_Trooper"] = true,
        ["POINormal_Coru_BrawlerDroidDrag"] = true,
        ["POINormal_Coru_BrawlerDroidDrag_Wall"] = true,
        ["FishTankCamera"] = true,
        ["DeathCombat"] = true,
    }

    local currentModeName = ""
    local canDetermineModeName = false

    -- --- PlayerController Object Finding ---
    if PlayerController_Class == nil then
        PlayerController_Class = api:find_uobject("Class /Script/Engine.PlayerController")
        local current_status = (PlayerController_Class ~= nil)
        if current_status ~= _last_print_PlayerController_Class_found_status then
            if current_status then
                print("DEBUG: PlayerController Class found.")
            else
                print("DEBUG: PlayerController Class NOT found (still searching).")
            end
            _last_print_PlayerController_Class_found_status = current_status
        end
    end

    PlayerController_Object = nil
    if PlayerController_Class ~= nil then
        PlayerController_Object = uobjectHook.get_first_object_by_class(PlayerController_Class)
        local current_status = (PlayerController_Object ~= nil)
        if current_status ~= _last_print_PlayerController_Object_found_status then
            if current_status then
                print(string.format("DEBUG: Found PlayerController Object: %s", PlayerController_Object:get_full_name()))
            else
                print("DEBUG: PlayerController Object NOT found.")
            end
            _last_print_PlayerController_Object_found_status = current_status
        end
    end

    -- --- Corrected PlayerCameraManager Acquisition via GameplayCameraManager ---
    PlayerCameraManager_Object = nil
    if PlayerController_Object ~= nil then
        local success_pcm, pcm_object = pcall(function() return PlayerController_Object.GameplayCameraManager end)
        local current_status_pcm = success_pcm and (pcm_object ~= nil)

        if current_status_pcm ~= _last_print_PlayerCameraManager_Object_found_status then
            if current_status_pcm then
                print(string.format("DEBUG: PlayerCameraManager Object found via PlayerController.GameplayCameraManager: %s", pcm_object:get_full_name()))
            else
                print("DEBUG: PlayerCameraManager Object NOT found via PlayerController.GameplayCameraManager.")
            end
            _last_print_PlayerCameraManager_Object_found_status = current_status_pcm
        end
        if success_pcm then PlayerCameraManager_Object = pcm_object end
    else
        if _last_print_PlayerCameraManager_Object_found_status == true then
            print("DEBUG: PlayerCameraManager Object is now NOT found (PlayerController missing).")
            _last_print_PlayerCameraManager_Object_found_status = false
        end
    end

    if PlayerCameraManager_Object ~= nil then
        local activeCameraModeDefinitionValue = nil
        local dataValue = nil

        local success_acmd, result_acmd = pcall(function() return PlayerCameraManager_Object.ActiveCameraModeDefinition end)
        local current_status_acmd = success_acmd and (result_acmd ~= nil)
        if current_status_acmd ~= _last_print_ActiveCameraModeDefinition_found_status then
            if current_status_acmd then
                print("DEBUG: ActiveCameraModeDefinition found.")
            else
                print("DEBUG: ActiveCameraModeDefinition NOT found or failed to access: " .. tostring(result_acmd))
            end
            _last_print_ActiveCameraModeDefinition_found_status = current_status_acmd
        end
        if success_acmd then activeCameraModeDefinitionValue = result_acmd end

        if activeCameraModeDefinitionValue ~= nil and type(activeCameraModeDefinitionValue) == "userdata" then
            local success_data, result_data = pcall(function() return activeCameraModeDefinitionValue.Data end)
            local current_status_data = success_data and (result_data ~= nil)
            if current_status_data ~= _last_print_Data_found_status then
                if current_status_data then
                    print("DEBUG: ActiveCameraModeDefinition.Data found.")
                else
                    print("DEBUG: ActiveCameraModeDefinition.Data NOT found or failed to access: " .. tostring(result_data))
                end
                _last_print_Data_found_status = current_status_data
            end
            if success_data then dataValue = result_data end

            if dataValue ~= nil and type(dataValue) == "userdata" then
                local found_mode_name = false
                local temp_mode_name = ""
                local success_prop, modeNameProperty = pcall(function() return dataValue.ModeName end)
                if success_prop and modeNameProperty ~= nil then
                    if type(modeNameProperty) == "userdata" and modeNameProperty.to_string ~= nil then
                        temp_mode_name = modeNameProperty:to_string()
                    else
                        temp_mode_name = tostring(modeNameProperty)
                    end
                    found_mode_name = true
                end

                if not found_mode_name and (temp_mode_name == nil or temp_mode_name == "") then
                    local success_str, result_str = pcall(dataValue.get_property_string, dataValue, "ModeName")
                    if success_str then
                        temp_mode_name = result_str
                        found_mode_name = true
                    end
                end

                local current_status_mode_name = found_mode_name and (temp_mode_name ~= nil and temp_mode_name ~= "")
                if current_status_mode_name ~= _last_print_ModeName_accessed_status then
                    if current_status_mode_name then
                        print("DEBUG: ModeName property accessed: '" .. temp_mode_name .. "'")
                    else
                        print("DEBUG: Failed to access ModeName property via .ModeName or get_property_string.")
                    end
                    _last_print_ModeName_accessed_status = current_status_mode_name
                end
                currentModeName = temp_mode_name
                canDetermineModeName = current_status_mode_name
            end
        end
    end

    -- --- BD-1 Object Finding ---
    HeroPawn_Object = nil
    if PlayerController_Object ~= nil then
        local success, pawn = pcall(function() return PlayerController_Object.AcknowledgedPawn end)
        local current_status = success and (pawn ~= nil)
        if current_status ~= _last_print_HeroPawn_Object_found_status then
            if current_status then
                print(string.format("DEBUG: Found AcknowledgedPawn (Hero): %s", pawn:get_full_name()))
            else
                print("DEBUG: AcknowledgedPawn (Hero) NOT found.")
            end
            _last_print_HeroPawn_Object_found_status = current_status
        end
        if success then HeroPawn_Object = pawn end
    end

    BuddyDroid_Object = nil
    if HeroPawn_Object ~= nil then
        local success, bd1 = pcall(function() return HeroPawn_Object.BuddyDroid end)
        local current_status = success and (bd1 ~= nil)
        if current_status ~= _last_print_BuddyDroid_Object_found_status then
            if current_status then
                print(string.format("DEBUG: Found BuddyDroid Object via AcknowledgedPawn: %s", bd1:get_full_name()))
            else
                print("DEBUG: BuddyDroid Object NOT found.")
            end
            _last_print_BuddyDroid_Object_found_status = current_status
        end
        if success then BuddyDroid_Object = bd1 end
    end
    -- --- END BD-1 Object Finding ---

    -- --- Monitor 'canForceSlowdown' and influence UObjectHook state ---
    local currentCanForceSlowdown = false
    local bd1ConditionMet = false

    if BuddyDroid_Object == nil then
        bd1ConditionMet = true
        lastCanForceSlowdown = nil
    else
        local success, value = pcall(function() return BuddyDroid_Object.canForceSlowdown end)
        if success and type(value) == "boolean" then
            currentCanForceSlowdown = value
        end

        bd1ConditionMet = (currentCanForceSlowdown == false)

        if lastCanForceSlowdown == nil then
            pcall(function() BuddyDroid_Object.canForceSlowdown = false end)
            currentCanForceSlowdown = false
            lastCanForceSlowdown = currentCanForceSlowdown
            print(string.format("Initial BD-1.canForceSlowdown: %s", tostring(currentCanForceSlowdown)))
        end

        if currentCanForceSlowdown ~= lastCanForceSlowdown then
            print(string.format("BD-1.canForceSlowdown CHANGED: %s -> %s",
                                 tostring(lastCanForceSlowdown),
                                 tostring(currentCanForceSlowdown)))
            lastCanForceSlowdown = currentCanForceSlowdown

            if currentCanForceSlowdown == true then
                print("BD-1 DETACHED from Cal!")
            else
                print("BD-1 MOUNTED onto Cal!")
            end
        end
    end
    -- --- END Monitor 'canForceSlowdown' ---

    local targetUObjectHookEnabledState = false

    if canDetermineModeName and
       (disabledModeNames[currentModeName] ~= true) and
       bd1ConditionMet then
        targetUObjectHookEnabledState = true
    else
        targetUObjectHookEnabledState = false
    end

    -- Apply the target state to UObjectHook
    if targetUObjectHookEnabledState ~= isUObjectHookEnabled then
        if isUObjectHookEnabled and not targetUObjectHookEnabledState then
            -- UObjectHook is currently enabled and is about to be disabled
            unhide_skeletal_meshes(api, uobjectHook)
            print("UObjectHook DISABLED because:")
            if not canDetermineModeName then
                print("- Could not determine camera ModeName.")
            end
            if disabledModeNames[currentModeName] == true then
                print(string.format("- Current ModeName ('%s') is in the disabled list.", currentModeName))

                -- *** NEW LOGIC: Force BD-1.canForceSlowdown to false when a disabled ModeName is active ***
                if BuddyDroid_Object ~= nil then
                    local success_set_bd, result_set_bd = pcall(function() BuddyDroid_Object.canForceSlowdown = false end)
                    if success_set_bd then
                        print(string.format("FORCING BD-1.canForceSlowdown to false due to ModeName '%s'.", currentModeName))
                        lastCanForceSlowdown = false -- Update our tracked state
                    else
                        print(string.format("Failed to set BD-1.canForceSlowdown to false for ModeName '%s': %s", currentModeName, tostring(result_set_bd)))
                    end
                else
                    print("BD-1 Object not found, cannot set canForceSlowdown to false.")
                end
                -- ***********************************************************************************
            end
            if not bd1ConditionMet then
                print("- BD-1 is detached.")
            end
        end

        uobjectHook.set_disabled(not targetUObjectHookEnabledState)
        isUObjectHookEnabled = targetUObjectHookEnabledState

        if isUObjectHookEnabled then
            print("UObjectHook ENABLED (ModeName allows and BD-1 mounted/not found yet)")
            hide_skeletal_meshes(api, uobjectHook)
        else
            print("UObjectHook state changed to DISABLED.")
        end
    end

    if currentModeName ~= lastModeName then
        print(string.format("ModeName changed to: %s", currentModeName))
        lastModeName = currentModeName
    end
end)

-- Initial print message for script load.
print("Combined UObjectHook control, component hiding, and BD-1 status detection script initialized.")
print("UObjectHook will be disabled if ModeName is disabled OR BD-1 is detached.")
print("Please test all conditions to confirm functionality and debug output.")