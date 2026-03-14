print("talos2_two_cosmetic_arms_bind_clones.lua init")

UEVR_UObjectHook.activate()
local api = uevr.api

local created = false
local t = 0.0

local LEFT_HAND = 0
local RIGHT_HAND = 1

local mesh1p = nil
local owner = nil
local arms_asset = nil

local clone_l = nil
local clone_r = nil

local l_pivot = nil
local r_pivot = nil

local vec_c = api:find_uobject("ScriptStruct /Script/CoreUObject.Vector")
local rot_c = api:find_uobject("ScriptStruct /Script/CoreUObject.Rotator")

local function vec(x, y, z)
    local v = StructObject.new(vec_c)
    v.X, v.Y, v.Z = x, y, z
    return v
end

local function safe_fullname(o)
    local ok, v = pcall(function() return o:get_full_name() end)
    if ok and v then return v end
    return ""
end

local function get_smc_objects()
    local smc_class = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")
    if smc_class == nil then return nil end
    return UEVR_UObjectHook.get_objects_by_class(smc_class, false)
end

local function find_mesh1p()
    local arr = get_smc_objects()
    if arr == nil then return nil end
    for i = 1, #arr do
        local o = arr[i]
        if o ~= nil then
            local n = safe_fullname(o)
            if n:find("BP_TalosCharacter_C_") and n:find("Mesh1P") then
                return o
            end
        end
    end
    return nil
end

local function show_component(c)
    pcall(function() c:SetHiddenInGame(false) end)
    pcall(function() c:SetVisibility(true, true) end)
    pcall(function() c.bOwnerNoSee = false end)
    pcall(function() c.bOnlyOwnerSee = false end)
    pcall(function() c.BoundsScale = 10.0 end)
end

local function set_permanent_flag(st, v)
    if st == nil then return end
    if st.set_permanant ~= nil then
        st:set_permanant(v)
    elseif st.set_permanent ~= nil then
        st:set_permanent(v)
    end
end

local function bind_hand(component, hand_index)
    local st = UEVR_UObjectHook.get_or_add_motion_controller_state(component)
    if st == nil then return false end
    st:set_hand(hand_index)
    set_permanent_flag(st, true)
    return true
end

local LEFT_UNHIDE = {
    "L_UpperArm","L_LowerArm","L_Wrist_Heading",
    "L_Thumb_01","L_Thumb_02","L_Thumb_03",
    "L_Index_H","L_Index_01","L_Index_02","L_Index_03",
    "L_Middle_H","L_Middle_01","L_Middle_02","L_Middle_03",
    "L_Marriage_H","L_Marriage_01","L_Marriage_02","L_Marriage_03",
    "L_Baby_H","L_Baby_01","L_Baby_02","L_Baby_03"
}

local RIGHT_UNHIDE = {
    "R_UpperArm","R_LowerArm","R_Wrist_Heading",
    "R_Thumb_01","R_Thumb_02","R_Thumb_03",
    "R_Index_H","R_Index_01","R_Index_02","R_Index_03",
    "R_Middle_H","R_Middle_01","R_Middle_02","R_Middle_03",
    "R_Marriage_H","R_Marriage_01","R_Marriage_02","R_Marriage_03",
    "R_Baby_H","R_Baby_01","R_Baby_02","R_Baby_03"
}

local function force_left_only(mesh)
    for i = 1, #LEFT_UNHIDE do
        pcall(function() mesh:UnHideBoneByName(LEFT_UNHIDE[i]) end)
    end
    pcall(function() mesh:HideBoneByName("R_UpperArm", 0) end)
end

local function force_right_only(mesh)
    for i = 1, #RIGHT_UNHIDE do
        pcall(function() mesh:UnHideBoneByName(RIGHT_UNHIDE[i]) end)
    end
    pcall(function() mesh:HideBoneByName("L_UpperArm", 0) end)
end

local function hide_mesh1p_both_arms(m)
    pcall(function() m:HideBoneByName("L_UpperArm", 0) end)
    pcall(function() m:HideBoneByName("R_UpperArm", 0) end)
end

local function read_translation(tr)
    local v = nil
    pcall(function() v = tr.Translation end)
    if v == nil then pcall(function() v = tr.translation end) end
    if v == nil then pcall(function() v = tr.Location end) end
    if v == nil then pcall(function() v = tr.location end) end
    if v == nil then return nil end
    if v.X == nil or v.Y == nil or v.Z == nil then return nil end
    return v
end

local function mag(v)
    return math.sqrt((v.X*v.X) + (v.Y*v.Y) + (v.Z*v.Z))
end

local function compute_pivot_offset(clone, socket_name)
    for _, space in ipairs({2, 3, 1, 0}) do
        local ok, tr = pcall(function() return clone:GetSocketTransform(socket_name, space) end)
        if ok and tr ~= nil then
            local v = read_translation(tr)
            if v ~= nil and mag(v) > 0.01 then
                return vec(-v.X, -v.Y, -v.Z)
            end
        end
    end
    return vec(0.0, 0.0, 0.0)
end

local function kill_old_arm_clones()
    local arr = get_smc_objects()
    if arr == nil then return end
    for i = 1, #arr do
        local c = arr[i]
        if c ~= nil and c ~= mesh1p then
            local c_owner = nil
            pcall(function() c_owner = c:GetOwner() end)
            if c_owner == owner then
                local a = nil
                pcall(function() a = c:GetSkeletalMeshAsset() end)
                if a ~= nil and a == arms_asset then
                    pcall(function() c:DestroyComponent() end)
                end
            end
        end
    end
end

local function setup()
    mesh1p = find_mesh1p()
    if mesh1p == nil then
        print("ERR Mesh1P not found")
        return false
    end

    pcall(function() owner = mesh1p:GetOwner() end)
    if owner == nil then
        print("ERR Mesh1P owner nil")
        return false
    end

    pcall(function() arms_asset = mesh1p:GetSkeletalMeshAsset() end)
    if arms_asset == nil then
        print("ERR arms_asset nil")
        return false
    end

    kill_old_arm_clones()

    local smc_c = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")
    if smc_c == nil then
        print("ERR SkeletalMeshComponent class nil")
        return false
    end

    clone_l = api:add_component_by_class(owner, smc_c, false)
    clone_r = api:add_component_by_class(owner, smc_c, false)
    if clone_l == nil or clone_r == nil then
        print("ERR clone create failed")
        return false
    end

    pcall(function() clone_l:SetSkeletalMeshAsset(arms_asset) end)
    pcall(function() clone_r:SetSkeletalMeshAsset(arms_asset) end)

    show_component(clone_l)
    show_component(clone_r)

    force_left_only(clone_l)
    force_right_only(clone_r)

    l_pivot = compute_pivot_offset(clone_l, "L_Wrist_Heading")
    r_pivot = compute_pivot_offset(clone_r, "R_Wrist_Heading")

    pcall(function() clone_l:SetRelativeLocation(l_pivot) end)
    pcall(function() clone_r:SetRelativeLocation(r_pivot) end)

    bind_hand(clone_l, LEFT_HAND)
    bind_hand(clone_r, RIGHT_HAND)

    hide_mesh1p_both_arms(mesh1p)

    print("talos2_two_cosmetic_arms_bind_clones.lua done")
    return true
end

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, dt)
    t = t + dt

    if not created then
        if t < 0.45 then return end
        t = 0.0
        created = setup()
        return
    end

    if mesh1p ~= nil then
        hide_mesh1p_both_arms(mesh1p)
    end

    if clone_l ~= nil then
        show_component(clone_l)
        force_left_only(clone_l)
        if l_pivot ~= nil then pcall(function() clone_l:SetRelativeLocation(l_pivot) end) end
    end

    if clone_r ~= nil then
        show_component(clone_r)
        force_right_only(clone_r)
        if r_pivot ~= nil then pcall(function() clone_r:SetRelativeLocation(r_pivot) end) end
    end
end)

