print("Initializing VR Flashlight gesture script")

UEVR_UObjectHook.activate()
local api = uevr.api

-- CONFIG -------------------------
local DISTANCE_THRESHOLD = 0.18   -- meters
local COOLDOWN_SECONDS   = 0.5    -- seconds
----------------------------------

local was_inside_zone = false
local last_trigger_time = 0.0

local function get_player_controller()
    return api:get_player_controller(0)
end

local function toggle_flashlight(pc)
    if not pc then return end

    if pc.ToggleFlashlight then
        pc:ToggleFlashlight()
        print("[FLASHLIGHT] Toggled via PlayerController")
        return
    end

    local pawn = pc.Pawn
    if pawn and pawn.ToggleFlashlight then
        pawn:ToggleFlashlight()
        print("[FLASHLIGHT] Toggled via Pawn")
        return
    end

    print("[FLASHLIGHT] ToggleFlashlight not found")
end

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    -- Get HMD pose
    local hmd_index = uevr.params.vr.get_hmd_index()
    if hmd_index == -1 then return end

    local hmd_pos = UEVR_Vector3f.new()
    local hmd_rot = UEVR_Quaternionf.new()
    uevr.params.vr.get_pose(hmd_index, hmd_pos, hmd_rot)

    -- Get LEFT controller pose
    local left_index = uevr.params.vr.get_left_controller_index()
    if left_index == -1 then return end

    local left_pos = UEVR_Vector3f.new()
    local left_rot = UEVR_Quaternionf.new()
    uevr.params.vr.get_pose(left_index, left_pos, left_rot)

    -- Distance check
    local dx = left_pos.x - hmd_pos.x
    local dy = left_pos.y - hmd_pos.y
    local dz = left_pos.z - hmd_pos.z
    local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

    local inside_zone = dist < DISTANCE_THRESHOLD

    -- Current time (seconds)
    local now = os.clock()

    -- EDGE DETECTION + COOLDOWN 👇
    if inside_zone and not was_inside_zone then
        if (now - last_trigger_time) >= COOLDOWN_SECONDS then
            local pc = get_player_controller()
            toggle_flashlight(pc)
            last_trigger_time = now
        else
            print("[FLASHLIGHT] Trigger blocked by cooldown")
        end
    end

    was_inside_zone = inside_zone
end)
