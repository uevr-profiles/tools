--CONFIG
require(".\\Trackers\\Trackers")
-------------------------------------
local function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        error("Cannot find " .. name)
        return nil
    end

    return obj
end

local find_static_class = function(name)
    local c = find_required_object(name)
    return c:get_class_default_object()
end

local api = uevr.api
local vr = uevr.params.vr
local callbacks = uevr.params.sdk.callbacks
local pawn = api:get_local_pawn(0)
local kismet_math_library = find_static_class ("Class /Script/Engine.KismetMathLibrary")
local hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
local empty_hitresult = StructObject.new(hitresult_c)
local is_left_shoulder_pressed = false

callbacks.on_xinput_get_state(function(retval, user_index, state)
    -- Verificação de segurança
    if not state or not state.Gamepad or user_index ~= 0 then
        return
    end

    if (state.Gamepad.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER) ~= 0 then --
        is_left_shoulder_pressed = true
    else
        is_left_shoulder_pressed = false
    end

    state.Gamepad.wButtons = state.Gamepad.wButtons & (~XINPUT_GAMEPAD_LEFT_SHOULDER)


    local trigger_threshold = 200 
    if state.Gamepad.bLeftTrigger > trigger_threshold then --
        state.Gamepad.wButtons = state.Gamepad.wButtons | XINPUT_GAMEPAD_LEFT_SHOULDER
    end
end)


callbacks.on_post_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
    local pawn = api:get_local_pawn(0)
    local attached_actors = {} -- Necessary array considering GetAttachedActors give us two weapon objects

    pawn:GetAttachedActors(attached_actors, true)

for i, act in ipairs(attached_actors) do
    if act and string.find(act:get_full_name(), "BP_RangedWeaponVisuals_") 
    and not string.find(act:get_full_name(), "DESTROYED") then -- Ranged detection while avoiding the detection of previous selected weapons
        local mesh_component = act.SkeletalMesh
        if mesh_component and mesh_component:get_property('bOnlyOwnerSee') == true then -- Property exclusive to first person meshes
           
            root = mesh_component
            weapon_equipped = act 
            
            break 
        end
    end
end

if not root then
    return 
end

--print("Mesh full name: " .. root:get_full_name()) --
--print("Attached actor full name: " .. weapon_equipped:get_full_name()) --
   
    if is_left_shoulder_pressed then
                
        local left_hand_pos = left_hand_component:K2_GetComponentLocation()
        local right_hand_pos = right_hand_component:K2_GetComponentLocation()
        local dir_to_left_hand = (left_hand_pos - right_hand_pos):normalized()
        local weapon_up_vector = root:GetUpVector() --
        local final_rotation = kismet_math_library:MakeRotFromXZ(dir_to_left_hand, weapon_up_vector) 

        local final_position = right_hand_pos
        if final_position and final_rotation then
            root:K2_SetWorldLocationAndRotation(final_position, final_rotation, false, empty_hitresult, false) 
        end
    else
        local right_hand_rot = right_hand_component:K2_GetComponentRotation() -- Resets weapon position and alligns it to your right hand after left grip release
        root:K2_SetWorldRotation(right_hand_rot, false, empty_hitresult, false)
    end
end)