local api = uevr.api

local function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        error("Cannot find " .. name)
        return nil
    end

    return obj
end

local temp_vec3f = Vector3f.new(0, 0, 0)

local function get_equipped_items(slot)
    local BP_EquippedItem_C = find_required_object("BlueprintGeneratedClass /Game/Blueprints/Items/BaseBlueprints/BP_EquippedItem.BP_EquippedItem_C")
    local items = BP_EquippedItem_C:get_objects_matching(false)
    
    if items == nil or #items == 0 then
        return nil
    end

    for _, item in ipairs(items) do
        local root_component = item.RootComponent
        if root_component == nil then
            return nil
        end

        if (root_component.AttachSocketName:to_string()) == slot then
            return root_component
        end
    end

    return nil
end

local function get_watervolumes()
    local pawn = api:get_local_pawn()

    if pawn == nil then
        return
    end
    
    local WaterVolumes = pawn.WaterVolumes
    if WaterVolumes == nil then
        return nil
    end

    for _, WaterVolume in ipairs(WaterVolumes) do
        local UnderWaterPostProcessing = WaterVolume.NativePostProcessUnderWater
        UnderWaterPostProcessing.bEnabled = false
    end
end

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    local pawn = api:get_local_pawn()

    if pawn == nil then
        return
    end

    get_watervolumes()

end)

uevr.sdk.callbacks.on_post_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
    local pawn = api:get_local_pawn()

    if pawn == nil then
        return
    end

    local current_left_weapon = get_equipped_items("L_Weapon_Socket")
    local current_right_weapon = get_equipped_items("R_Weapon_Socket")


    -- Store previous weapon states to detect changes
    local previous_left_weapon = nil
    local previous_right_weapon = nil

    local left_attach = nil
    local right_attach = nil

    if current_left_weapon ~= previous_left_weapon then
        if previous_left_weapon then -- Remove old attachment if it existed
            UEVR_UObjectHook.remove_motion_controller_state(previous_left_weapon)
            left_attach = nil
        end

        if current_left_weapon then -- Attach new weapon if it exists
            left_attach = UEVR_UObjectHook.get_or_add_motion_controller_state(current_left_weapon)
            left_attach:set_hand(0)
            left_attach:set_permanent(false)
            left_attach:set_rotation_offset(temp_vec3f:set(1.000, -0.500, 0))
        end

        previous_left_weapon = current_left_weapon -- Update previous weapon
    end

    -- Check for changes in right weapon (same logic as left)
    if current_right_weapon ~= previous_right_weapon then
        if previous_right_weapon then
            UEVR_UObjectHook.remove_motion_controller_state(previous_right_weapon)
            right_attach = nil
        end

        if current_right_weapon then
            right_attach = UEVR_UObjectHook.get_or_add_motion_controller_state(current_right_weapon)
            right_attach:set_hand(1)
            right_attach:set_permanent(true)
            right_attach:set_rotation_offset(temp_vec3f:set(1.000, -0.500, 0))
        end

        previous_right_weapon = current_right_weapon
    end
end)