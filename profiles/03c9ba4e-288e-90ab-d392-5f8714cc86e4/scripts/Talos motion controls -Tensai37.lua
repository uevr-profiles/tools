UEVR_UObjectHook.activate()

local api = uevr.api
local vr = uevr.params.vr
local callbacks = uevr.sdk.callbacks

local LEFT_HAND = 0
local RIGHT_HAND = 1

local HAND_MAT_ID = 0
local ARM_MAT_ID = 1
local EXTRA_MAT_ID = 2

local AIM_METHOD_GAME = 0
local AIM_METHOD_ARM = 2

local ENTER_TILT_DEG = 30.0
local EXIT_TILT_DEG = 15.0
local ENTER_FRAMES = 45
local EXIT_FRAMES = 60
local STARTUP_DELAY_SEC = 1.0

local LEFT_SOCKET = "LeftHandSocket"
local RIGHT_SOCKET = "RightHandSocket"

local created = false
local arm_t = 0.0

local mesh1p = nil
local owner = nil
local athena_mesharms = nil
local arms_asset = nil

local clone_l = nil
local clone_r = nil

local left_mc_pivot = nil
local right_mc_pivot = nil

local l_pivot = nil
local r_pivot = nil

local vec_c = api:find_uobject("ScriptStruct /Script/CoreUObject.Vector")

local armed = false
local startup_t = 0.0

local in_gravity = false
local enter_count = 0
local exit_count = 0

local arms_visible_state = nil

local ATHENA_LEFT_UNHIDE = {
    "clavicle_l",
    "upperarm_l",
    "lowerarm_l",
    "hand_l",
    "index_01_l","index_02_l","index_03_l",
    "middle_01_l","middle_02_l","middle_03_l",
    "pinky_01_l","pinky_02_l","pinky_03_l",
    "ring_01_l","ring_02_l","ring_03_l",
    "thumb_01_l","thumb_02_l","thumb_03_l",
    "lowerarm_twist_01_l",
    "upperarm_twist_01_l",
    "ik_hand_l"
}

local ATHENA_RIGHT_UNHIDE = {
    "clavicle_r",
    "upperarm_r",
    "lowerarm_r",
    "hand_r",
    "index_01_r","index_02_r","index_03_r",
    "middle_01_r","middle_02_r","middle_03_r",
    "pinky_01_r","pinky_02_r","pinky_03_r",
    "ring_01_r","ring_02_r","ring_03_r",
    "thumb_01_r","thumb_02_r","thumb_03_r",
    "lowerarm_twist_01_r",
    "upperarm_twist_01_r",
    "ik_hand_r"
}

local function vec(x, y, z)
    local v = StructObject.new(vec_c)
    v.X, v.Y, v.Z = x, y, z
    return v
end

local function abs(x)
    return (x < 0) and -x or x
end

local function safe_fullname(o)
    local ok, v = pcall(function()
        return o:get_full_name()
    end)

    if ok and v then
        return tostring(v)
    end

    return ""
end

local function get_smc_objects()
    local smc_class = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")
    if smc_class == nil then
        return nil
    end

    return UEVR_UObjectHook.get_objects_by_class(smc_class, false)
end

local function get_root_component(actor)
    if actor == nil then
        return nil
    end

    local root = nil
    pcall(function() root = actor.RootComponent end)
    if root == nil then pcall(function() root = actor.Root end) end
    return root
end

local function try_register_component(c)
    if c == nil then
        return
    end

    pcall(function() c:RegisterComponent() end)
    pcall(function() c:SetHiddenInGame(false) end)
end

local function attach_component(child, parent)
    if child == nil or parent == nil then
        return false
    end

    local ok = false

    pcall(function()
        child:SetupAttachment(parent)
        ok = true
    end)
    if ok then return true end

    pcall(function()
        child:SetupAttachment(parent, "")
        ok = true
    end)
    if ok then return true end

    pcall(function()
        child:K2_AttachToComponent(parent, "", 0, 0, 0, false)
        ok = true
    end)
    if ok then return true end

    pcall(function()
        child:K2_AttachToComponent(parent, nil, 0, 0, 0, false)
        ok = true
    end)
    if ok then return true end

    return false
end

local function find_mesh1p()
    local arr = get_smc_objects()
    if arr == nil then
        return nil
    end

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

local function find_athena_mesharms()
    local arr = get_smc_objects()
    if arr == nil then
        return nil
    end

    for i = 1, #arr do
        local o = arr[i]
        if o ~= nil then
            local n = safe_fullname(o)
            if n:find("BP_NPC_Athena_C_") and n:find("MeshArms") then
                return o
            end
        end
    end

    return nil
end

local function show_component(c)
    if c == nil then
        return
    end

    pcall(function() c:SetHiddenInGame(false) end)
    pcall(function() c:SetVisibility(true, true) end)
    pcall(function() c.bOwnerNoSee = false end)
    pcall(function() c.bOnlyOwnerSee = false end)
    pcall(function() c.BoundsScale = 10.0 end)
end

local function hide_component(c)
    if c == nil then
        return
    end

    pcall(function() c:SetHiddenInGame(true) end)
    pcall(function() c:SetVisibility(false, true) end)
end

local function set_permanent_flag(st, v)
    if st == nil then
        return
    end

    if st.set_permanant ~= nil then
        st:set_permanant(v)
    elseif st.set_permanent ~= nil then
        st:set_permanent(v)
    end
end

local function bind_hand(component, hand_index)
    local st = UEVR_UObjectHook.get_or_add_motion_controller_state(component)
    if st == nil then
        return false
    end

    st:set_hand(hand_index)
    set_permanent_flag(st, true)
    return true
end

local function hide_mesh1p_both_arms(m)
    if m == nil then
        return
    end

    pcall(function() m:HideBoneByName("L_UpperArm", 0) end)
    pcall(function() m:HideBoneByName("R_UpperArm", 0) end)
end

local function hide_arm_sections(mesh)
    if mesh == nil then
        return
    end

    for lod = 0, 3 do
        pcall(function() mesh:ShowAllMaterialSections(lod) end)

        for section = 0, 5 do
            pcall(function() mesh:ShowMaterialSection(HAND_MAT_ID, section, true, lod) end)
            pcall(function() mesh:ShowMaterialSection(ARM_MAT_ID, section, false, lod) end)
            pcall(function() mesh:ShowMaterialSection(EXTRA_MAT_ID, section, false, lod) end)
        end
    end
end

local function force_left_only(mesh)
    if mesh == nil then
        return
    end

    for i = 1, #ATHENA_LEFT_UNHIDE do
        pcall(function() mesh:UnHideBoneByName(ATHENA_LEFT_UNHIDE[i]) end)
    end

    pcall(function() mesh:HideBoneByName("clavicle_r", 0) end)
    hide_arm_sections(mesh)
end

local function force_right_only(mesh)
    if mesh == nil then
        return
    end

    for i = 1, #ATHENA_RIGHT_UNHIDE do
        pcall(function() mesh:UnHideBoneByName(ATHENA_RIGHT_UNHIDE[i]) end)
    end

    pcall(function() mesh:HideBoneByName("clavicle_l", 0) end)
    hide_arm_sections(mesh)
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
    return math.sqrt((v.X * v.X) + (v.Y * v.Y) + (v.Z * v.Z))
end

local function compute_pivot_offset(clone, socket_name)
    for _, space in ipairs({2, 3, 1, 0}) do
        local ok, tr = pcall(function()
            return clone:GetSocketTransform(socket_name, space)
        end)

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
    if arr == nil then
        return
    end

    for i = 1, #arr do
        local c = arr[i]
        if c ~= nil and c ~= mesh1p and c ~= athena_mesharms then
            local c_owner = nil
            pcall(function() c_owner = c:GetOwner() end)

            if c_owner == owner then
                local a = nil
                pcall(function() a = c:GetSkeletalMeshAsset() end)

                if a ~= nil and arms_asset ~= nil and a == arms_asset then
                    pcall(function() c:DestroyComponent() end)
                end
            end
        end
    end
end

local function get_rot_pr(rot)
    if rot == nil then
        return nil, nil
    end

    local p = rot.Pitch or rot.pitch or rot.p
    local r = rot.Roll or rot.roll or rot.r

    if p == nil or r == nil then
        return nil, nil
    end

    return p, r
end

local function try_call(obj, fn_name)
    if obj == nil then
        return nil
    end

    local ok, result = pcall(function()
        local fn = obj[fn_name]
        if fn == nil then
            return nil
        end
        return fn(obj)
    end)

    if ok then
        return result
    end

    return nil
end

local function get_best_tilt_deg()
    local pawn = api:get_local_pawn(0)
    if pawn == nil then
        return nil
    end

    local best = nil

    local pawn_rot = try_call(pawn, "GetActorRotation")
    do
        local p, r = get_rot_pr(pawn_rot)
        if p ~= nil and r ~= nil then
            local t = abs(p)
            if abs(r) > t then
                t = abs(r)
            end
            best = t
        end
    end

    local root = nil
    pcall(function() root = pawn.RootComponent end)
    if root ~= nil then
        local root_rot = try_call(root, "GetComponentRotation") or try_call(root, "K2_GetComponentRotation")
        local p, r = get_rot_pr(root_rot)
        if p ~= nil and r ~= nil then
            local t = abs(p)
            if abs(r) > t then
                t = abs(r)
            end
            if best == nil or t > best then
                best = t
            end
        end
    end

    local capsule = nil
    pcall(function() capsule = pawn.CapsuleComponent end)
    if capsule == nil then
        pcall(function() capsule = pawn.CapsuleComp end)
    end
    if capsule ~= nil then
        local cap_rot = try_call(capsule, "GetComponentRotation") or try_call(capsule, "K2_GetComponentRotation")
        local p, r = get_rot_pr(cap_rot)
        if p ~= nil and r ~= nil then
            local t = abs(p)
            if abs(r) > t then
                t = abs(r)
            end
            if best == nil or t > best then
                best = t
            end
        end
    end

    local mesh = nil
    pcall(function() mesh = pawn.Mesh end)
    if mesh ~= nil then
        local mesh_rot = try_call(mesh, "GetComponentRotation") or try_call(mesh, "K2_GetComponentRotation")
        local p, r = get_rot_pr(mesh_rot)
        if p ~= nil and r ~= nil then
            local t = abs(p)
            if abs(r) > t then
                t = abs(r)
            end
            if best == nil or t > best then
                best = t
            end
        end
    end

    return best
end

local function apply_gravity_mode()
    pcall(function() vr.set_aim_method(AIM_METHOD_GAME) end)
    pcall(function() vr.set_decoupled_pitch_enabled(false) end)
end

local function apply_normal_mode()
    pcall(function() vr.set_aim_method(AIM_METHOD_ARM) end)
    pcall(function() vr.set_decoupled_pitch_enabled(true) end)
end

local function setup_arms()
    mesh1p = find_mesh1p()
    if mesh1p == nil then
        return false
    end

    athena_mesharms = find_athena_mesharms()
    if athena_mesharms == nil then
        return false
    end

    pcall(function() owner = mesh1p:GetOwner() end)
    if owner == nil then
        return false
    end

    pcall(function() arms_asset = athena_mesharms:GetSkeletalMeshAsset() end)
    if arms_asset == nil then
        return false
    end

    kill_old_arm_clones()

    local smc_c = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")
    local scene_c = api:find_uobject("Class /Script/Engine.SceneComponent")
    if smc_c == nil or scene_c == nil then
        return false
    end

    local root_comp = get_root_component(owner)
    if root_comp == nil then
        root_comp = mesh1p
    end
    if root_comp == nil then
        return false
    end

    left_mc_pivot = api:add_component_by_class(owner, scene_c, false)
    right_mc_pivot = api:add_component_by_class(owner, scene_c, false)
    clone_l = api:add_component_by_class(owner, smc_c, false)
    clone_r = api:add_component_by_class(owner, smc_c, false)

    if left_mc_pivot == nil or right_mc_pivot == nil or clone_l == nil or clone_r == nil then
        return false
    end

    try_register_component(left_mc_pivot)
    try_register_component(right_mc_pivot)
    try_register_component(clone_l)
    try_register_component(clone_r)

    attach_component(left_mc_pivot, root_comp)
    attach_component(right_mc_pivot, root_comp)
    attach_component(clone_l, left_mc_pivot)
    attach_component(clone_r, right_mc_pivot)

    pcall(function() clone_l:SetSkeletalMeshAsset(arms_asset) end)
    pcall(function() clone_r:SetSkeletalMeshAsset(arms_asset) end)

    show_component(clone_l)
    show_component(clone_r)

    force_left_only(clone_l)
    force_right_only(clone_r)

    l_pivot = compute_pivot_offset(clone_l, LEFT_SOCKET)
    r_pivot = compute_pivot_offset(clone_r, RIGHT_SOCKET)

    pcall(function() clone_l:SetRelativeLocation(l_pivot) end)
    pcall(function() clone_r:SetRelativeLocation(r_pivot) end)

    pcall(function() clone_l:SetRelativeRotation({Pitch = 0.0, Yaw = 0.0, Roll = 0.0}) end)
    pcall(function() clone_r:SetRelativeRotation({Pitch = 0.0, Yaw = 0.0, Roll = 0.0}) end)

    bind_hand(left_mc_pivot, LEFT_HAND)
    bind_hand(right_mc_pivot, RIGHT_HAND)

    hide_mesh1p_both_arms(mesh1p)
    apply_normal_mode()
    arms_visible_state = true

    return true
end

callbacks.on_pre_engine_tick(function(engine, delta)
    local dt = delta or 0.0

    if not created then
        arm_t = arm_t + dt
        if arm_t >= 0.45 then
            arm_t = 0.0
            created = setup_arms()
        end
    end

    startup_t = startup_t + dt

    if not armed and startup_t >= STARTUP_DELAY_SEC then
        armed = true
    end

    if armed then
        local tilt = get_best_tilt_deg()

        if tilt ~= nil then
            if not in_gravity then
                if tilt >= ENTER_TILT_DEG then
                    enter_count = enter_count + 1
                else
                    enter_count = 0
                end

                if enter_count >= ENTER_FRAMES then
                    in_gravity = true
                    enter_count = 0
                    exit_count = 0
                    apply_gravity_mode()
                end
            else
                if tilt <= EXIT_TILT_DEG then
                    exit_count = exit_count + 1
                else
                    exit_count = 0
                end

                if exit_count >= EXIT_FRAMES then
                    in_gravity = false
                    enter_count = 0
                    exit_count = 0
                    apply_normal_mode()
                end
            end
        end
    end

    if mesh1p ~= nil then
        hide_mesh1p_both_arms(mesh1p)
    end

    if left_mc_pivot ~= nil then
        bind_hand(left_mc_pivot, LEFT_HAND)
    end

    if right_mc_pivot ~= nil then
        bind_hand(right_mc_pivot, RIGHT_HAND)
    end

    if in_gravity then
        if arms_visible_state ~= false then
            hide_component(clone_l)
            hide_component(clone_r)
            arms_visible_state = false
        end
    else
        if arms_visible_state ~= true then
            show_component(clone_l)
            show_component(clone_r)
            arms_visible_state = true
        end

        if clone_l ~= nil then
            force_left_only(clone_l)
            if l_pivot ~= nil then
                pcall(function() clone_l:SetRelativeLocation(l_pivot) end)
            end
        end

        if clone_r ~= nil then
            force_right_only(clone_r)
            if r_pivot ~= nil then
                pcall(function() clone_r:SetRelativeLocation(r_pivot) end)
            end
        end
    end
end)