local api = uevr.api
local hidden_components = {}
local frame_counter = 0

local target_labels = {
    "PlayerPartsMeshes0_0",
    "PlayerPartsMeshes0_1",
    "PlayerPartsMeshes0_2",
    "PlayerPartsMeshes0_3",
    "PlayerPartsMeshes0_4",
    "PlayerPartsMeshes0_5"
}

-- Helper function to check if a component has already been processed
local function is_hidden(name)
    return hidden_components[name] == true
end

-- Track if weapons are already bound this session
local last_left_weapon_name = nil
local last_right_weapon_name = nil


uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    frame_counter = frame_counter + 1

    -- Only run every 120 frames (~2 seconds)
    if frame_counter % 120 ~= 0 then return end

    local success, err = pcall(function()
        local SkeletalMeshComponentClass = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")
        if SkeletalMeshComponentClass == nil then
            print("[UEVR] Could not find SkeletalMeshComponent class")
            return
        end

        local all_components = SkeletalMeshComponentClass:get_objects_matching(false)
        if not all_components or #all_components == 0 then
            print("[UEVR] No SkeletalMeshComponents found")
            return
        end

        for i = 1, #all_components do
            local comp = all_components[i]
            local name = comp:get_full_name()

            if not is_hidden(name) then
                for _, label in ipairs(target_labels) do
                    if string.find(name, label) then
                        pcall(function()
                            comp:SetVisibility(false)
                            comp:SetRenderInMainPass(false)
                            hidden_components[name] = true
                            print("[UEVR] Hid: " .. name)
                        end)
                        break
                    end
                end
            end
        end
    end)

    if not success then
        print("[UEVR] ERROR during continuous hide check: " .. tostring(err))
    end

    -- === Outdated bind left and right weapons to controllers ===
    local WeaponMeshComponentClass = api:find_uobject("Class /Script/BBQ.xxWeaponMeshComponent")
    local left_comp = nil
    local right_comp = nil
    if WeaponMeshComponentClass ~= nil then
        local all_components = WeaponMeshComponentClass:get_objects_matching(false)
        for _, comp in ipairs(all_components) do
            local socket = tostring(comp.AttachSocketName)
            if socket:find("Weapon_L") then
                left_comp = comp
            elseif socket:find("Weapon_R") then
                right_comp = comp
            end
        end
    end

    -- Left weapon binding

 local WeaponMeshComponentClass = api:find_uobject("Class /Script/BBQ.xxWeaponMeshComponent")
    local left_comp = nil
    if WeaponMeshComponentClass ~= nil then
        local all_components = WeaponMeshComponentClass:get_objects_matching(false)
        for _, comp in ipairs(all_components) do
            local socket = tostring(comp.AttachSocketName)
            if socket:find("Weapon_L") then
                left_comp = comp
                break
            end
        end
    end

 if left_comp then
        local left_name = left_comp:get_full_name()
        if left_name ~= last_left_weapon_name then
            last_left_weapon_name = left_name
            print("[UEVR] Found new left weapon, binding to left controller: " .. left_name)
            if UEVR_UObjectHook and UEVR_UObjectHook.activate then
                pcall(function() UEVR_UObjectHook.activate() end)
            end
            if UEVR_UObjectHook and UEVR_UObjectHook.get_or_add_motion_controller_state then
                local ok, state = pcall(function()
                    return UEVR_UObjectHook.get_or_add_motion_controller_state(left_comp)
                end)
                if ok and state then
                    pcall(function() state:set_hand(0) end) -- 0 = left
                    pcall(function() state:set_location_offset({0, 50, 50.0}) end)
                    -- Optional: set rotation offset
                    -- pcall(function() state:set_rotation_offset({-1.25, 1, 0}) end)
                    pcall(function() state:set_permanant(true) end)
                    print("[UEVR] Bound left weapon to left controller with Z=50 offset!")
                else
                    print("[UEVR] Failed to get motion controller state for left weapon!")
                end
            else
                print("[UEVR] UEVR_UObjectHook or get_or_add_motion_controller_state not available!")
            end
        end
    end
    -- === End of weapon binding ===

end)