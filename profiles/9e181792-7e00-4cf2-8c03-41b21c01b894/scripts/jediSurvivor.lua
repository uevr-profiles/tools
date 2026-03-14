local VERSION = "0.9.1"
--[[
@title Jedi Survivor Smart Profile: 1P Explorer, 3P Combat
@version 0.9.1

Goal of this profile is to stay in 1P when exploring, and 3P for combat & cutscenes.

@features
- Auto-Switch to 3rd Person: 
    - Combat
    - Cutscenes
    - Traversal (climb/wallrun/grapple/etc)
    - Interactions
    - Flying/Gliding
- Mounted Camera: 1st/3rd person (configurable)
- Map/Meditation 2D Mode: Auto-switches to 2D screen mode when HoloMap or meditation is active
- Mesh Visibility: Hides player face/body in 1st person, shows in 3rd person
- Most settings are configurable at bottom of UEVR menu under Jedi Survivor (remember to click save)

@controls
- Toggle 1P/3P view: Hold D-Pad Down (0.5s)
- Cutscenes Zoom:
    - D-Pad Up/Down: Zoom in/out (during cutscenes)
    - D-Pad Left/Right: Reset zoom (during cutscenes)

@installation
Place in: C:\Users\[YourUsername]\AppData\Roaming\UnrealVRMod\JediSurvivor\scripts\

@changelog
- 0.9.1: New option: Hide Lower Body/Legs in 1st Person
         Fix: Mounted camera now properly restores after exiting map
- 0.9: Universal pause detection using GameplayStatics:IsGamePaused()
       Fix: Zoom controls now properly disabled in menus (not just cutscenes)
       Fix: Phase dash no longer triggers false 3P switch (movement montage blacklist)
       Fix: Cal's body hiding (jacket/shirt) now works correctly in 1P
       Fix: Blocking/holding saber as light source stays in 1P
       Ledge hang timer - quick grab & jump stays in 1P (like Fallen Order)
       BD-1 hiding improved - hides all mesh components when on Cal's back
- 0.6: Centralized view state decision (cleaner architecture)
       Saber detection option (stay in 3P while saber drawn)
       Tall animal mount camera support (Spamel, etc.)
       Config persistence to file
- 0.5: Map 2D mode, Cutscene zoom (3 levels), Dynamic mesh visibility
- 0.4: Traversal auto-switch, Combat debounce, Interaction detection
- 0.3: Cutscene detection, Smart logging system
- 0.2: Manual toggle via D-Pad, Config UI
- 0.1: Initial release
--]]

-- ============================================================================
-- CONSTANTS & CONFIGURATION
-- ============================================================================


-- API References
local api = uevr.api
local sdk = uevr.sdk
local vr_params = uevr.params.vr

-- Debug module for object dumping
-- local debugModule = require("libs/uevr_debug")

-- Config file for persistent settings
local CONFIG_FILE = "jedi_survivor_config.txt"

-- ============================================================================
-- SAFE CALL WRAPPER
-- ============================================================================
-- Wraps pcall to log errors instead of silently swallowing them
-- This makes debugging much easier when game APIs fail

local function safe_call(context, fn)
    local success, result = pcall(fn)
    if not success then
        print("[ERROR " .. context .. "] " .. tostring(result))
        return false, nil
    end
    return true, result
end

-- Input Button Masks (only D-Pad used)
local XINPUT_BUTTONS = {
    DPAD_UP = 0x0001,
    DPAD_DOWN = 0x0002,
    DPAD_LEFT = 0x0004,
    DPAD_RIGHT = 0x0008,
}

-- Timing Constants
local TIMING = {
    DPAD_HOLD_DURATION = 0.5,          -- Seconds to hold D-Pad Down to toggle
    LOG_QUEUE_TIMEOUT = 1.5,            -- Seconds before flushing queue
    COMBAT_DEBOUNCE_TIME = 2.0,         -- Seconds to wait before switching out of combat
    TRAVERSAL_DEBOUNCE_TIME = 1.0,      -- Seconds to wait before switching out of traversal (covers climb jumps)
    INTERACTION_DEBOUNCE_TIME = 0.3,    -- Seconds to wait before switching out of interaction (300ms)
    LEDGE_HANG_THRESHOLD = 1.6,         -- Seconds before ledge hang auto-switches to 3P (allows quick grab & jump)
}

-- Cinematic Zoom Settings (3 levels: zoomed in, default, zoomed out)
-- D-Pad Up = zoom in, D-Pad Down = zoom out, D-Pad Left/Right = reset to default
local CINEMATIC_ZOOM = {
    OFFSET_PER_LEVEL = 50,  -- Forward offset per zoom level (positive = closer)
}

-- Camera Offsets per State (explicit, not save/restore)
-- Normal camera offset when ENABLE_NORMAL_CAMERA_FORWARD_OFFSET is toggled on
local NORMAL_FORWARD_OFFSET = 0  -- Forward offset for normal 1st person (when enabled)
local NORMAL_UP_OFFSET = -20      -- Up offset for normal 1st person (when enabled)
-- local NORMAL_FORWARD_OFFSET = 20  -- Forward offset for normal 1st person (when enabled)
-- local NORMAL_UP_OFFSET = -10      -- Up offset for normal 1st person (when enabled)

local NORMAL_CAMERA = {
    FORWARD = 0,   -- Normal 1st person: base forward offset (0 when disabled)
    RIGHT = 0,     -- Normal 1st person: no right offset
    UP = 0,        -- Normal 1st person: no up offset
}

local MOUNTED_CAMERA = {
    FORWARD = 35.0,   -- Nekko: camera forward offset
    RIGHT = 0,        -- Nekko: no right offset
    UP = 106,         -- Nekko: camera up offset
}

-- Tall animal mount (NavState 52) - e.g. Spamel
local MOUNTED_TALL_ANIMAL_CAMERA = {
    FORWARD = 61.0,   -- Tall animal: camera forward offset
    RIGHT = -0.5,     -- Tall animal: slight right offset
    UP = 390,         -- Tall animal: high camera up offset
}

local CONFIG_KEYS = {
    DEBUG_LOGGING = "debug_logging",
    ENABLE_AUTO_CUTSCENE = "enable_auto_cutscene",
    ENABLE_AUTO_MELEE = "enable_auto_melee",
    ENABLE_SABER_DETECTION = "enable_saber_detection",  -- Stay in 3P while saber is drawn
    -- Individual traversal toggles
    ENABLE_AUTO_WALLRUN = "enable_auto_wallrun",
    ENABLE_AUTO_CLIMB = "enable_auto_climb",
    ENABLE_AUTO_LEDGE = "enable_auto_ledge",
    ENABLE_LEDGE_HANG_ALWAYS = "enable_ledge_hang_always",  -- Always 3P on ledge hang (no delay)
    ENABLE_AUTO_GRAPPLE = "enable_auto_grapple",
    ENABLE_AUTO_SQUEEZE = "enable_auto_squeeze",  -- Gap squeeze (claustrophobia)
    ENABLE_AUTO_MEDITATION = "enable_auto_meditation",  -- Meditation (SavePoint)
    ENABLE_AUTO_ROPE = "enable_auto_rope",  -- Rope swing traversal
    ENABLE_AUTO_ZIPLINE = "enable_auto_zipline",  -- Zipline traversal
    ENABLE_AUTO_BALANCE = "enable_auto_balance",  -- Balance beam
    ENABLE_AUTO_FALLING = "enable_auto_falling",  -- Falling
    ENABLE_AUTO_FLYING = "enable_auto_flying",  -- Creature flying/gliding
    ENABLE_AUTO_MOUNTED = "enable_auto_mounted",  -- Mounted on creature
    ENABLE_AUTO_INTERACTION = "enable_auto_interaction",  -- Chest/box/sense echo interactions
    -- Cinematic zoom
    ENABLE_CINEMATIC_ZOOM = "enable_cinematic_zoom",  -- Camera forward offset during cutscenes
    ENABLE_MAP_2D_MODE = "enable_map_2d_mode",  -- Switch to 2D screen mode when map/menu is open
    ENABLE_MEDITATION_2D_MODE = "enable_meditation_2d_mode",  -- Switch to 2D screen mode when meditating
    -- Camera offsets
    ENABLE_NORMAL_CAMERA_FORWARD_OFFSET = "enable_normal_offset",  -- Apply forward offset in normal 1st person
    -- Mesh visibility
    HIDE_BODY_MESH = "hide_body_mesh",  -- Hide body mesh (including arms) in 1st person
    HIDE_LOWER_BODY_MESH = "hide_lower_body_mesh",  -- Hide lower body/legs in 1st person
    HIDE_BUDDY_DROID = "hide_buddy_droid",  -- Hide BD-1 when attached to Cal's back
    SHOW_BODY_STANDING = "show_body_standing",  -- Show body in 1P when standing still
    SHOW_BODY_WALKING = "show_body_walking",  -- Show body in 1P when walking slowly
}

local function get_default_config()
    return {
        [CONFIG_KEYS.DEBUG_LOGGING] = false,  -- Logging disabled by default
        -- Cinematic zoom (reads camera offsets from cameras.txt)
        [CONFIG_KEYS.ENABLE_CINEMATIC_ZOOM] = true,  -- Camera zoom during cutscenes
        [CONFIG_KEYS.ENABLE_AUTO_CUTSCENE] = true,
        -- Combat
        [CONFIG_KEYS.ENABLE_AUTO_MELEE] = true,
        [CONFIG_KEYS.ENABLE_SABER_DETECTION] = false,  -- Stay in 3P while saber is drawn (off by default)
        -- Map/Menu 2D mode
        [CONFIG_KEYS.ENABLE_MAP_2D_MODE] = true,  -- Switch to 2D screen when map/menu is open
        [CONFIG_KEYS.ENABLE_MEDITATION_2D_MODE] = true,  -- Switch to 2D screen when meditating
        -- Traversal defaults (most on, balance off)
        [CONFIG_KEYS.ENABLE_AUTO_INTERACTION] = true,  -- Chest/box interactions
        [CONFIG_KEYS.ENABLE_AUTO_MOUNTED] = false,  -- Mounted on creature
        [CONFIG_KEYS.ENABLE_AUTO_FLYING] = true,  -- Creature flying/gliding
        [CONFIG_KEYS.ENABLE_AUTO_WALLRUN] = true,
        [CONFIG_KEYS.ENABLE_AUTO_CLIMB] = true,
        [CONFIG_KEYS.ENABLE_AUTO_LEDGE] = true,
        [CONFIG_KEYS.ENABLE_LEDGE_HANG_ALWAYS] = false,  -- Use timer delay for ledge hang (like Fallen Order)
        [CONFIG_KEYS.ENABLE_AUTO_GRAPPLE] = true,
        [CONFIG_KEYS.ENABLE_AUTO_SQUEEZE] = true,
        [CONFIG_KEYS.ENABLE_AUTO_MEDITATION] = true,
        [CONFIG_KEYS.ENABLE_AUTO_ROPE] = true,
        [CONFIG_KEYS.ENABLE_AUTO_ZIPLINE] = false,
        [CONFIG_KEYS.ENABLE_AUTO_BALANCE] = false,
        [CONFIG_KEYS.ENABLE_AUTO_FALLING] = false,
        -- Camera offsets
        [CONFIG_KEYS.ENABLE_NORMAL_CAMERA_FORWARD_OFFSET] = true,  -- Normal forward offset
        -- Mesh visibility
        [CONFIG_KEYS.HIDE_BODY_MESH] = true,  -- Hide body & arms in 1st person
        [CONFIG_KEYS.HIDE_LOWER_BODY_MESH] = true,  -- Hide lower body/legs in 1st person
        [CONFIG_KEYS.HIDE_BUDDY_DROID] = true,  -- Hide BD-1 when on back
        [CONFIG_KEYS.SHOW_BODY_STANDING] = false,  -- Show body when standing still in 1P
        [CONFIG_KEYS.SHOW_BODY_WALKING] = false,  -- Show body when walking slowly in 1P
    }
end

-- Configuration (must be before NAV_STATES helper functions)
local config = get_default_config()

-- UI Configuration Options (data-driven checkbox definitions)
-- Each group has a header and items with { key, label }
local UI_CONFIG_OPTIONS = {
    { header = "Settings:", items = {
        { key = CONFIG_KEYS.ENABLE_AUTO_CUTSCENE, label = "Cutscenes" },
        { key = CONFIG_KEYS.ENABLE_AUTO_MELEE, label = "Combat (melee)" },
        { key = CONFIG_KEYS.ENABLE_SABER_DETECTION, label = "Saber Drawn (stay 3P)" },
    }},
    { header = "Traversal:", items = {
        { key = CONFIG_KEYS.ENABLE_AUTO_WALLRUN, label = "Wall Running" },
        { key = CONFIG_KEYS.ENABLE_AUTO_CLIMB, label = "Climbing" },
        { key = CONFIG_KEYS.ENABLE_AUTO_LEDGE, label = "Ledge Grabbing" },
        { key = CONFIG_KEYS.ENABLE_LEDGE_HANG_ALWAYS, label = "Ledge Hang on Quick Grabs (instant 3P)" },
        { key = CONFIG_KEYS.ENABLE_AUTO_GRAPPLE, label = "Grappling" },
        { key = CONFIG_KEYS.ENABLE_AUTO_SQUEEZE, label = "Gap Squeeze" },
        { key = CONFIG_KEYS.ENABLE_AUTO_ROPE, label = "Rope Swing" },
        { key = CONFIG_KEYS.ENABLE_AUTO_ZIPLINE, label = "Zipline" },
        { key = CONFIG_KEYS.ENABLE_AUTO_BALANCE, label = "Balance Beam" },
        { key = CONFIG_KEYS.ENABLE_AUTO_FALLING, label = "Falling" },
        { key = CONFIG_KEYS.ENABLE_AUTO_FLYING, label = "Creature Flying" },
        { key = CONFIG_KEYS.ENABLE_AUTO_MOUNTED, label = "Creature Mounted" },
        { key = CONFIG_KEYS.ENABLE_AUTO_INTERACTION, label = "Interactions (Chest/Meditation)" },
    }},
    { header = "Cinematic Zoom:", items = {
        { key = CONFIG_KEYS.ENABLE_CINEMATIC_ZOOM, label = "Cinematic Zoom" },
    }},
    { header = "Map/Menu 2D Mode:", items = {
        { key = CONFIG_KEYS.ENABLE_MAP_2D_MODE, label = "2D Mode Map" },
        { key = CONFIG_KEYS.ENABLE_MEDITATION_2D_MODE, label = "2D Mode Meditation" },
    }},
    { header = "Mesh Settings:", items = {
        { key = CONFIG_KEYS.HIDE_BODY_MESH, label = "Hide Body & Arms (1st Person)" },
        { key = CONFIG_KEYS.HIDE_LOWER_BODY_MESH, label = "Hide Legs & Pants (1st Person)" },
        { key = CONFIG_KEYS.HIDE_BUDDY_DROID, label = "Hide BD-1 on Back (1st Person)" },
        { key = CONFIG_KEYS.SHOW_BODY_STANDING, label = "Show Body in 1P (Standing Still)" },
        { key = CONFIG_KEYS.SHOW_BODY_WALKING, label = "Show Body in 1P (Walking Slowly)" },
    }},
    { header = "Camera Offsets:", items = {
        { key = CONFIG_KEYS.ENABLE_NORMAL_CAMERA_FORWARD_OFFSET, label = "Use Camera Forward Offset" },
    }},
    { header = "Debug:", items = {
        { key = CONFIG_KEYS.DEBUG_LOGGING, label = "Enable Debug Logging" },
    }},
}

-- ============================================================================
-- CONFIGURATION PERSISTENCE
-- ============================================================================

local function save_config()
    local lines = {}
    for key, value in pairs(config) do
        table.insert(lines, key .. "=" .. tostring(value))
    end
    
    local file = io.open(CONFIG_FILE, "w")
    if file then
        file:write(table.concat(lines, "\n"))
        file:close()
        print("[CONFIG] Saved to " .. CONFIG_FILE)
    else
        print("[CONFIG] Failed to save config file")
    end
end

local function load_config()
    local file = io.open(CONFIG_FILE, "r")
    if not file then 
        print("[CONFIG] No config file found, using defaults")
        return 
    end
    
    local loaded_count = 0
    for line in file:lines() do
        local key, value = line:match("([^=]+)=(.*)")
        if key and value then
            key = key:match("^%s*(.-)%s*$")  -- trim whitespace
            value = value:match("^%s*(.-)%s*$")
            if config[key] ~= nil then
                -- Parse booleans and numbers
                if value == "true" then
                    config[key] = true
                    loaded_count = loaded_count + 1
                elseif value == "false" then
                    config[key] = false
                    loaded_count = loaded_count + 1
                else
                    local num = tonumber(value)
                    if num then
                        config[key] = num
                        loaded_count = loaded_count + 1
                    end
                end
            end
        end
    end
    file:close()
    print("[CONFIG] Loaded " .. loaded_count .. " settings from " .. CONFIG_FILE)
end

local function reset_config_to_defaults()
    for key, value in pairs(get_default_config()) do
        config[key] = value
    end
    save_config()
    print("[CONFIG] Reset to defaults")
end

-- ============================================================================
-- NAV STATE DEFINITIONS
-- ============================================================================
-- Centralized NavState definitions with friendly names and categories
-- Each entry defines: id, name, category, and optional config key for auto-switch

local NAV_STATES = {
    -- Ground/Default States (no auto-switch, kept for logging)
    TRANSITION = { id = 0, name = "Transition", category = "Ground" },
    GROUND = { id = 1, name = "Ground", category = "Ground" },
    JUMP_START = { id = 2, name = "Jump Start", category = "Ground" },
    JUMPING = { id = 3, name = "Jumping", category = "Ground" },
    -- States that trigger 3P (with config keys)
    FALLING = { id = 5, name = "Falling", category = "Ground", config = CONFIG_KEYS.ENABLE_AUTO_FALLING },
    
    -- Movement abilities (excluded from interaction detection)
    PHASE_DASH = { id = 28, name = "Phase Dash", category = "Movement" },
    DEATH = { id = 21, name = "Death", category = "Special", config = CONFIG_KEYS.ENABLE_AUTO_CUTSCENE },
    
    -- Climbing States
    LEDGE_HANG = { id = 9, name = "Ledge Hang", category = "Climbing", config = CONFIG_KEYS.ENABLE_AUTO_LEDGE },
    BEAM_HANG = { id = 12, name = "Beam Hang", category = "Climbing", config = CONFIG_KEYS.ENABLE_AUTO_CLIMB },
    BEAM_TRANSITION = { id = 14, name = "Beam Transition", category = "Climbing", config = CONFIG_KEYS.ENABLE_AUTO_CLIMB },  -- Transition between beam states (drop/climb)
    CLIMBING = { id = 16, name = "Climbing", category = "Climbing", config = CONFIG_KEYS.ENABLE_AUTO_CLIMB },
    
    -- Balance States
    BALANCE_BEAM = { id = 13, name = "Balance Beam", category = "Balance", config = CONFIG_KEYS.ENABLE_AUTO_BALANCE },
    
    -- Rope/Zipline States
    ROPE_SWING = { id = 10, name = "Rope Swing", category = "Rope", config = CONFIG_KEYS.ENABLE_AUTO_ROPE },
    ROPE_SLIDE = { id = 17, name = "Zipline", category = "Rope", config = CONFIG_KEYS.ENABLE_AUTO_ZIPLINE },
    
    -- Special States
    MEDITATION = { id = 20, name = "Meditation", category = "Special", config = CONFIG_KEYS.ENABLE_AUTO_MEDITATION },
    GRAPPLE = { id = 24, name = "Grapple", category = "Grapple", config = CONFIG_KEYS.ENABLE_AUTO_GRAPPLE },
    MOUNTED = { id = 30, name = "Mounted", category = "Mount", config = CONFIG_KEYS.ENABLE_AUTO_MOUNTED },
    MOUNTED_JUMP_32 = { id = 32, name = "Mounted Jump", category = "Mount", config = CONFIG_KEYS.ENABLE_AUTO_MOUNTED },
    MOUNTED_JUMP_33 = { id = 33, name = "Mounted Jump", category = "Mount", config = CONFIG_KEYS.ENABLE_AUTO_MOUNTED },
    MOUNTED_JUMP_34 = { id = 34, name = "Mounted Jump", category = "Mount", config = CONFIG_KEYS.ENABLE_AUTO_MOUNTED },
    CREATURE_FLYING = { id = 43, name = "Creature Flying", category = "Mount", config = CONFIG_KEYS.ENABLE_AUTO_FLYING },
    MOUNTED_52 = { id = 52, name = "Tall Animal", category = "Mount", config = CONFIG_KEYS.ENABLE_AUTO_MOUNTED },
    GAP_SQUEEZE = { id = 55, name = "Gap Squeeze", category = "Squeeze", config = CONFIG_KEYS.ENABLE_AUTO_SQUEEZE },
}

-- Build reverse lookup table: id -> NavState definition
local NAV_STATE_BY_ID = {}
for _, def in pairs(NAV_STATES) do
    NAV_STATE_BY_ID[def.id] = def
end

-- Get full NavState info string for logging
local function get_nav_state_info(nav_id)
    local def = NAV_STATE_BY_ID[nav_id]
    if def then
        return string.format("%s (%d)", def.name, nav_id)
    end
    return string.format("Unknown (%d)", nav_id)
end

-- Traversal Component Checks (data-driven approach)
-- Each entry defines: component property name, methods to check, config key, display name
-- Methods can be: { method = "MethodName" } for boolean methods, or { property = "PropName" } for boolean properties
local TRAVERSAL_COMPONENT_CHECKS = {
    -- WallRun component
    { component = "HC_WallRun", config = CONFIG_KEYS.ENABLE_AUTO_WALLRUN, name = "WallRun", checks = {
        { method = "IsWallRunning" },
        { method = "GetWallRunState", non_zero = true },
    }},
    -- Climb component (multiple methods)
    { component = "HC_Climb", config = CONFIG_KEYS.ENABLE_AUTO_CLIMB, name = "Climb", checks = {
        { method = "IsAttached" },
        { method = "IsWallClimb" },
        { method = "IsCeilingClimb" },
        { method = "IsClimbMoving" },
    }},
    -- NOTE: LedgeGrab component removed - ledge hang now uses NavState timer logic
    -- to allow quick grab & jump without switching to 3P (like Fallen Order)
    -- Grapple component
    { component = "HC_Grapple", config = CONFIG_KEYS.ENABLE_AUTO_GRAPPLE, name = "Grapple", checks = {
        { method = "IsGrappling" },
    }},
    -- WallHang component (wall hang, chimney, wall slide)
    { component = "HC_WallHang", config = CONFIG_KEYS.ENABLE_AUTO_WALLRUN, name = "WallHang", checks = {
        { method = "IsWallHanging" },
        { method = "IsInChimney", name = "Chimney" },
        { method = "IsForcedWallSlide", name = "WallSlide" },
        { method = "GetCurrentWallHangState", non_zero = true },
    }},
    -- Slide component (ground sliding) - no config, always check
    { component = "HC_Slide", name = "Slide", checks = {
        { property = "isSliding" },
    }},
    -- Swim component - no config, always check
    { component = "HC_Swim", name = "Swim", checks = {
        { property = "IsUnderwater" },
    }},
}

-- Game State
local state = {
    -- Camera state (UEVR starts in first person)
    is_first_person = true,
    
    -- Input state for D-Pad hold detection
    dpad_down_hold_start = 0,
    dpad_down_held = false,
    
    -- Game state detection
    in_cutscene = false,
    is_in_combat = false,
    saber_is_active = false,            -- Saber drawn (used to extend combat 3P, not start it)
    
    -- Combat debounce
    combat_exit_time = 0,
    
    -- Traversal state
    is_traversing = false,
    traversal_exit_time = 0,
    
    -- Interaction state (chest/box/sense echo via transient montages)
    is_interacting = false,
    interaction_exit_time = 0,
    
    -- Cinematic zoom state (D-Pad controlled, only forward offset)
    zoom_level = 0,                      -- Current zoom level: -1=out, 0=default, +1=in
    -- D-Pad input tracking for zoom
    dpad_up_pressed = false,             -- Track D-Pad Up press
    dpad_down_pressed = false,           -- Track D-Pad Down press
    dpad_left_pressed = false,           -- Track D-Pad Left press
    dpad_right_pressed = false,          -- Track D-Pad Right press
    
    -- Map/Menu 2D screen mode state
    is_paused = false,                  -- Game is paused (map/menu open)
    in_2d_mode = false,                 -- Currently in 2D screen mode
    
    -- Ledge hang timer (for delayed 3P switch like Fallen Order)
    ledge_hang_start_time = 0,          -- When ledge hang started (0 = not hanging)
    
    -- Manual override (user toggled, don't auto-switch until auto-state triggers)
    manual_override = false,            -- True = respect user's manual toggle
    
    -- Body visibility in 1P (TEST: show when stationary)
    body_visible_1p = false,            -- Current body visibility state in 1P
    
    -- Logging state
    last_log_message = "",
    last_pawn_montage = nil,  -- Track pawn montage changes
    last_real_montage = nil,  -- Last non-transient montage name (for blacklist checking)
    
    -- Cached class lookups (expensive to find, cache once)
    hologram_class = nil,       -- SwWorldMapHologramBase class
    rs_game_state_class = nil,  -- RsGameState class
    gameplay_statics = nil,     -- GameplayStatics Default instance for IsGamePaused
    cached_world = nil,         -- Cached World for IsGamePaused
}

-- Unified Camera Offset State (clean state machine)
local camera_offset = {
    active_mode = "NORMAL",              -- Current mode: NORMAL or MOUNTED
}
-- ============================================================================
-- SMART LOGGING SYSTEM
-- ============================================================================
-- Pattern-based logging to avoid flooding the log with repeated messages

local log_pattern = {}         -- Established pattern
local log_state = "BUILDING"   -- BUILDING, ESTABLISHED, TENTATIVE
local log_queue = {}           -- Messages queued during TENTATIVE
local log_queue_time = 0       -- When queue started

-- Helper to check if message is in array
local function log_contains(arr, msg)
    for _, m in ipairs(arr) do
        if m == msg then return true end
    end
    return false
end

-- Flush queued messages
local function log_flush_queue()
    for _, msg in ipairs(log_queue) do
        print(msg)
        if not log_contains(log_pattern, msg) then
            table.insert(log_pattern, msg)
        end
    end
    log_queue = {}
end

---------------------------------------------------------------------------------------------------
-- Smart Logging Function
---------------------------------------------------------------------------------------------------
-- PURPOSE:
--   Prevents log flooding by detecting and suppressing repetitive message patterns,
--   while ensuring genuinely new messages are always printed.
--
-- HOW IT WORKS (State Machine):
--   1. BUILDING: Every unique message is printed. When repeat seen, go to ESTABLISHED.
--   2. ESTABLISHED: Messages in pattern are skipped. New message -> TENTATIVE.
--   3. TENTATIVE: Queue new messages. If truly new, flush queue and return to BUILDING.
---------------------------------------------------------------------------------------------------
local function log(...)
    if not config[CONFIG_KEYS.DEBUG_LOGGING] then return end
    
    local message = table.concat({...}, " ")
    local now = os.clock()
    
    -- Timeout: flush queue if waiting too long
    if log_state == "TENTATIVE" and #log_queue > 0 and (now - log_queue_time) > TIMING.LOG_QUEUE_TIMEOUT then
        log_flush_queue()
        log_state = "ESTABLISHED"
    end
    
    local in_pattern = log_contains(log_pattern, message)
    local in_queue = log_contains(log_queue, message)
    
    if log_state == "BUILDING" then
        if in_pattern then
            -- Message repeats - pattern established
            log_state = "ESTABLISHED"
            return
        end
        table.insert(log_pattern, message)
        print(message)
        
    elseif log_state == "ESTABLISHED" then
        if in_pattern then
            return  -- Skip repeating pattern
        end
        -- Not in pattern - enter tentative state
        log_state = "TENTATIVE"
        log_queue = {message}
        log_queue_time = now
        
    elseif log_state == "TENTATIVE" then
        -- Reset timeout on every message
        log_queue_time = now
        
        if in_queue then
            return  -- Already in queue - skip
        elseif in_pattern then
            table.insert(log_queue, message)
        else
            -- Not in queue AND not in pattern - truly NEW!
            log_flush_queue()
            print(message)
            table.insert(log_pattern, message)
            log_state = "BUILDING"
        end
    end
end

-- DO NOT REMOVE:
-- Simple log that only prevents immediate duplicates
local function log_simple(...)
    if not config[CONFIG_KEYS.DEBUG_LOGGING] then return end
    
    local message = table.concat({...}, " ")
    if message ~= state.last_log_message then
        print(message)
        state.last_log_message = message
    end
end

-- ============================================================================
-- CAMERA OFFSET MODE MANAGEMENT
-- ============================================================================
-- Single function to switch camera offset modes. Applies explicit offsets per state.
-- Priority: MOUNTED > CUTSCENE > NORMAL

-- Track last camera offset values to avoid redundant updates
local last_camera_offset = { forward = nil, right = nil, up = nil }

-- Helper function to set camera offsets (only updates and logs when values change)
local function setCameraOffset(forward, right, up)
    -- Only update if values actually changed
    if last_camera_offset.forward == forward and 
       last_camera_offset.right == right and 
       last_camera_offset.up == up then
        return  -- No change, skip
    end
    
    vr_params.set_mod_value("VR_CameraForwardOffset", tostring(forward))
    vr_params.set_mod_value("VR_CameraRightOffset", tostring(right))
    vr_params.set_mod_value("VR_CameraUpOffset", tostring(up))
    
    last_camera_offset.forward = forward
    last_camera_offset.right = right
    last_camera_offset.up = up
    
    -- Removed print() to avoid log spam - values change legitimately during gameplay
end

local function set_camera_mode(new_mode, zoom_offset)
    -- zoom_offset is optional, only used for CUTSCENE mode
    zoom_offset = zoom_offset or 0
    
    -- Only skip if already in MOUNTED mode (prevents re-applying every frame)
    -- NORMAL and CUTSCENE always apply to ensure offset changes take effect
    if camera_offset.active_mode == new_mode and new_mode == "MOUNTED" then 
        return 
    end
    
    if new_mode == "MOUNTED" then
        setCameraOffset(MOUNTED_CAMERA.FORWARD, MOUNTED_CAMERA.RIGHT, MOUNTED_CAMERA.UP)
        log("[CAMERA] Mode: MOUNTED (forward=" .. MOUNTED_CAMERA.FORWARD .. ", up=" .. MOUNTED_CAMERA.UP .. ")")
    elseif new_mode == "MOUNTED_52" then
        setCameraOffset(MOUNTED_TALL_ANIMAL_CAMERA.FORWARD, MOUNTED_TALL_ANIMAL_CAMERA.RIGHT, MOUNTED_TALL_ANIMAL_CAMERA.UP)
        log("[CAMERA] Mode: TALL_ANIMAL (forward=" .. MOUNTED_TALL_ANIMAL_CAMERA.FORWARD .. ", up=" .. MOUNTED_TALL_ANIMAL_CAMERA.UP .. ")")
    elseif new_mode == "CUTSCENE" then
        -- Cutscene camera: base 0 + zoom offset
        setCameraOffset(zoom_offset, 0, 0)
        log("[CAMERA] Mode: CUTSCENE (forward=" .. zoom_offset .. ")")
    else  -- NORMAL
        -- Apply normal forward/up offset if enabled in config (adds to base)
        local forward = NORMAL_CAMERA.FORWARD
        local up = NORMAL_CAMERA.UP
        if config[CONFIG_KEYS.ENABLE_NORMAL_CAMERA_FORWARD_OFFSET] then
            forward = forward + NORMAL_FORWARD_OFFSET
            up = up + NORMAL_UP_OFFSET
        end
        setCameraOffset(forward, NORMAL_CAMERA.RIGHT, up)
        log("[CAMERA] Mode: NORMAL (forward=" .. forward .. ", up=" .. up .. ")")
    end
    
    camera_offset.active_mode = new_mode
end

-- ============================================================================
-- FORWARD DECLARATIONS
-- ============================================================================
-- These functions are defined later but called from camera management
local is_in_cutscene
local is_in_traversal
local is_in_combat

-- ============================================================================
-- CENTRALIZED VIEW STATE DECISION (Pattern from Fallen Order)
-- ============================================================================
-- ONE place decides if we should be in 3P based on ALL detection functions.
-- Handlers only track state flags, they do NOT call view switching functions.

-- Returns: should_3p (bool), reason (string or nil)
local function should_be_in_3p(hero)
    -- Check detection functions (current state) OR state flags (debounce period)
    if (is_in_combat and is_in_combat(hero)) or state.is_in_combat then 
        state.manual_override = false  -- Auto-state clears manual override
        return true, "combat" 
    end
    if (is_in_cutscene and is_in_cutscene(hero)) or state.in_cutscene then 
        state.manual_override = false
        return true, "cutscene" 
    end
    if (is_in_traversal and is_in_traversal(hero)) or state.is_traversing then 
        state.manual_override = false
        return true, "traversal" 
    end
    if state.is_interacting then 
        state.manual_override = false
        return true, "interaction" 
    end
    
    -- Manual override: user toggled, respect their choice until auto-state triggers
    if state.manual_override then
        return not state.is_first_person, "manual"
    end
    
    return false, nil
end

-- ============================================================================
-- CAMERA MANAGEMENT
-- ============================================================================

-- Hide/show player body meshes for first/third person view
-- Based on working pawn.lua pattern: uses direct property access and BOTH SetVisibility AND SetHiddenInGame
local function set_player_mesh_visibility(pawn, visible)
    if not pawn then return end
    
    local hidden = not visible
    local count = 0
    
    -- Helper function to hide/show a mesh component
    local function toggle_mesh(mesh, name)
        if mesh then
            safe_call("toggle_mesh:" .. name, function()
                -- ONLY use SetHiddenInGame - SetVisibility with propagate reveals debug components
                -- (collision capsules, forward arrows, etc)
                if mesh.SetHiddenInGame then
                    mesh:SetHiddenInGame(hidden, true)
                end
                count = count + 1
                log("[MESH] " .. name .. " visibility=" .. tostring(visible))
            end)
        end
    end
    
    -- DO NOT REMOVE:
    -- Access meshes directly by property name (from BP_Hero_C SDK dump)
    -- Experimental, not working, we are hiding wrong parts
    -- pcall(function()
    --     -- Face mesh - always hide in 1st person
    --     if pawn.Face then
    --         toggle_mesh(pawn.Face, "Face")
    --     end
        
    --     -- Handcuffs mesh (if present) - always hide in 1st person
    --     if pawn.Handcuffs then
    --         toggle_mesh(pawn.Handcuffs, "Handcuffs")
    --     end
        
    --     -- Body meshes - optional, controlled by config
    --     -- Hide only first 2 anonymous SkeletalMeshComponent_XXXX (vest and top body)
    --     if config[CONFIG_KEYS.HIDE_BODY_MESH] then
    --         local skeletal_mesh_class = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")
    --         if skeletal_mesh_class and pawn.K2_GetComponentsByClass then
    --             local components = pawn:K2_GetComponentsByClass(skeletal_mesh_class)
    --             if components then
    --                 local anonymous_count = 0
    --                 for i, component in pairs(components) do
    --                     if component then
    --                         local comp_name = component:get_fname():to_string()
    --                         -- Only hide first 2 anonymous components (vest and top body)
    --                         if comp_name and comp_name:find("^SkeletalMeshComponent_") then
    --                             anonymous_count = anonymous_count + 1
    --                             if anonymous_count <= 2 then
    --                                 if component.SetVisibility then
    --                                     component:SetVisibility(visible, true)
    --                                 end
    --                                 if component.SetHiddenInGame then
    --                                     component:SetHiddenInGame(hidden, true)
    --                                 end
    --                                 count = count + 1
    --                                 log("[MESH] " .. comp_name .. " visibility=" .. tostring(visible))
    --                             end
    --                         end
    --                     end
    --                 end
    --             end
    --         end
    --     end
    -- end)

    -- Instead, use original code for now:
    
    -- Hide Face mesh in 1st person
    pcall(function()
        if pawn.Face then
            -- DEBUG: Log Face mesh info
            log("[DEBUG] Face mesh class: " .. tostring(pawn.Face:get_class():get_full_name()))
            
            -- Check if Face has attached children that might be debug components
            if pawn.Face.GetNumChildrenComponents then
                local num_children = pawn.Face:GetNumChildrenComponents()
                log("[DEBUG] Face has " .. tostring(num_children) .. " children")
            end
            
            toggle_mesh(pawn.Face, "Face")
        end
    end)
    
    -- Hide body cosmetic meshes (Jacket, Shirt) based on config
    -- Note: Arm meshes are part of Jacket/Shirt, so hiding these also hides arms
    -- See README.md for detailed research on mesh hiding approaches tried
    pcall(function()
        
        -- Hide specific cosmetic meshes based on SkeletalMesh asset path
        -- Torso meshes to hide: Jacket, Shirt
        -- Keep visible: Hair, Pants, FacialHair, Holster (on pants)
        --
        -- All discovered mesh asset paths (for reference):
        --   Customization/HairAJK/Hero_hairDefault - Hair (KEEP)
        --   Customization/Holster/Hero_holster - Holster on pants (KEEP)
        --   Customization/Pants/Hero_pantsBoxCover - Pants (KEEP)
        --   Customization/FacialHairAJK/Hero_facialHairFullBeard - Beard (KEEP)
        --   Customization/Jacket/Hero_jacketBoxCover - Jacket (HIDE)
        --   Customization/Shirt/Hero_shirtJFOVersionB - Shirt (HIDE)
        --
        -- Only hide body meshes if the config option is enabled
        if config[CONFIG_KEYS.HIDE_BODY_MESH] then
            local TORSO_MESH_PATTERNS = {
                "Jacket",       -- Hero_jacketBoxCover (torso)
                "Shirt",        -- Hero_shirtJFOVersionB (torso)
            }
            
            -- Lower body patterns (only if HIDE_LOWER_BODY_MESH is enabled)
            local LOWER_BODY_MESH_PATTERNS = {
                "Pants",        -- Hero_pantsBoxCover (legs)
                "Holster",      -- Hero_holster (on pants)
            }
        
        local skeletal_mesh_class = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")
        if skeletal_mesh_class and pawn.K2_GetComponentsByClass then
            pcall(function()
                local components = pawn:K2_GetComponentsByClass(skeletal_mesh_class)
                if components then
                    for i, component in pairs(components) do
                        if component then
                            local comp_name = nil
                            pcall(function()
                                comp_name = component:get_fname():to_string()
                            end)
                            
                            -- Only process anonymous components
                            if comp_name and comp_name:find("^SkeletalMeshComponent_") then
                                -- Get the SkeletalMesh asset path
                                local mesh_asset_path = nil
                                pcall(function()
                                    if component.SkeletalMesh then
                                        local mesh = component.SkeletalMesh
                                        if mesh then
                                            mesh_asset_path = mesh:get_full_name()
                                        end
                                    end
                                end)
                                
                                -- Check if this is a torso mesh we should hide
                                local should_hide = false
                                if mesh_asset_path then
                                    -- Check torso patterns (HIDE_BODY_MESH)
                                    for _, pattern in ipairs(TORSO_MESH_PATTERNS) do
                                        if mesh_asset_path:find(pattern) then
                                            should_hide = true
                                            break
                                        end
                                    end
                                    
                                    -- Check lower body patterns (HIDE_LOWER_BODY_MESH)
                                    if not should_hide and config[CONFIG_KEYS.HIDE_LOWER_BODY_MESH] then
                                        for _, pattern in ipairs(LOWER_BODY_MESH_PATTERNS) do
                                            if mesh_asset_path:find(pattern) then
                                                should_hide = true
                                                break
                                            end
                                        end
                                    end
                                end
                                
                                if should_hide then
                                    pcall(function()
                                        -- ONLY use SetHiddenInGame - SetVisibility reveals debug components
                                        if component.SetHiddenInGame then
                                            component:SetHiddenInGame(hidden, true)
                                        end
                                        count = count + 1
                                        log("[MESH] " .. (mesh_asset_path or comp_name) .. " visibility=" .. tostring(visible))
                                    end)
                                end
                            end
                        end
                    end
                end
            end)
        end
        end  -- end if config[CONFIG_KEYS.HIDE_BODY_MESH]
    end)
    
    if count > 0 then
        log("[MESH] Toggled " .. count .. " mesh(es)/bone(s), visible=" .. tostring(visible))
    else
        log("[MESH] No meshes found to toggle")
    end
end

-- BD-1 Component Analysis Summary (from debug investigation):
-- BD-1 (BP_BuddyDroid_C) has 28 components including:
--   - 9 SkeletalMeshComponents (main mesh + accessories)
--   - CapsuleComponent (collision/debug wireframe)
--   - Various lights, particles, audio components
-- To hide BD-1 properly, must use SetRenderInMainPass on ALL SkeletalMeshComponents
-- SetHiddenInGame/SetVisibility cause debug wireframe issues

-- Set buddy droid (BD-1) visibility based on attach state
-- When in 1st person: hide if attached to Cal's back, show if detached
-- When in 3rd person: always show
local function set_buddy_droid_visibility(visible, pawn)
    if not pawn then return end
    if not config[CONFIG_KEYS.HIDE_BUDDY_DROID] then return end
    
    local buddy = nil
    local attach_point = nil
    local method_used = nil
    
    -- Get buddy actor
    safe_call("buddy_get", function()
        if pawn.GetBuddyDroidActor then
            buddy = pawn:GetBuddyDroidActor()
            method_used = "GetBuddyDroidActor"
        elseif pawn.BuddyDroid then
            buddy = pawn.BuddyDroid
            method_used = "BuddyDroid"
        end
    end)
    
    if not buddy then
        log("[BUDDY] Could not find BD-1 actor")
        return
    end
    
    -- Get attach point
    safe_call("buddy_attach", function()
        if buddy.GetCurrentAttachPoint then
            attach_point = buddy:GetCurrentAttachPoint()
        elseif buddy.Mesh and buddy.Mesh.AnimScriptInstance and buddy.Mesh.AnimScriptInstance.CurrentAttachPoint ~= nil then
            attach_point = buddy.Mesh.AnimScriptInstance.CurrentAttachPoint
        end
    end)
    
    -- 0 = Detached, anything else = attached to Cal
    local is_attached = attach_point ~= nil and attach_point ~= 0
    local should_render = visible or (not is_attached)
    
    -- Hide ALL SkeletalMeshComponents on BD-1, not just the main Mesh
    -- BD-1 has 8 SkeletalMeshComponents: CharacterMesh0, BD1_Health_Canister_rig, and 6 anonymous ones
    local mesh_count = 0
    safe_call("buddy_all_meshes", function()
        local skeletal_mesh_class = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")
        if skeletal_mesh_class and buddy.K2_GetComponentsByClass then
            local components = buddy:K2_GetComponentsByClass(skeletal_mesh_class)
            if components then
                for i, comp in pairs(components) do
                    if comp and comp.SetRenderInMainPass then
                        comp:SetRenderInMainPass(should_render)
                        mesh_count = mesh_count + 1
                    end
                end
            end
        end
    end)
    
    -- Also hide the CollisionCylinder (RsActorRootComponent) - the debug capsule wireframe
    safe_call("buddy_capsule", function()
        if buddy.CapsuleComponent and buddy.CapsuleComponent.SetRenderInMainPass then
            buddy.CapsuleComponent:SetRenderInMainPass(should_render)
        end
    end)
    
    log("[BUDDY] BD-1 render=" .. tostring(should_render) .. " via " .. (method_used or "unknown") .. 
        " (attachPoint=" .. tostring(attach_point) .. ", meshes=" .. mesh_count .. ")")
end

local function set_first_person_view(reason, hero, force)
    if state.is_first_person then return end
    
    -- CENTRALIZED CHECK: Block 1P switch if should_be_in_3p (unless forced)
    if not force and hero then
        local should_3p, active_reason = should_be_in_3p(hero)
        if should_3p then
            log("[CAMERA] Blocked 1P switch - active 3P state:", active_reason)
            return
        end
    end
    
    log("[CAMERA] Switching to First-Person View (Reason:", reason or "manual", ")")
    state.is_first_person = true
    
    if UEVR_UObjectHook then
        UEVR_UObjectHook.set_disabled(false)
    end
    
    -- Apply camera offset for current mode (NORMAL unless mounted)
    set_camera_mode("NORMAL")
    
    -- Hide player body meshes in first person
    local pawn = api:get_local_pawn(0)
    set_player_mesh_visibility(pawn, false)
    set_buddy_droid_visibility(false, pawn)
end

local function set_third_person_view(reason)
    if not state.is_first_person then return end
    
    log("[CAMERA] Switching to Third-Person View (Reason:", reason or "manual", ")")
    state.is_first_person = false
    
    if UEVR_UObjectHook then
        log("[CAMERA] Calling UEVR_UObjectHook.set_disabled(true)")
        UEVR_UObjectHook.set_disabled(true)
    else
        log("[CAMERA] WARNING: UEVR_UObjectHook not available!")
    end
    
    -- Reset camera offset to 0,0,0 for third person
    setCameraOffset(0, 0, 0)
    log("[CAMERA] Mode: THIRD_PERSON (offset reset to 0,0,0)")
    
    -- Show player body meshes in third person
    local pawn = api:get_local_pawn(0)
    set_player_mesh_visibility(pawn, true)
    set_buddy_droid_visibility(true, pawn)
end

local function toggle_view()
    -- Set manual override to prevent auto-switching from immediately reversing toggle
    -- Override clears when any auto-state (combat, cutscene, traversal, interaction) triggers
    state.manual_override = true
    log("[VIEW] Manual toggle by user (override set)")
    
    if state.is_first_person then
        set_third_person_view("manual toggle")
    else
        set_first_person_view("manual toggle", nil, true)  -- force=true for manual
    end
end

-- ============================================================================
-- GAME STATE DETECTION
-- ============================================================================

-- Get the hero pawn (Cal Kestis)
local function get_hero()
    local pawn = api:get_local_pawn(0)
    if not pawn then return nil end
    
    -- Log the pawn class on first discovery
    local class_name = ""
    pcall(function()
        class_name = pawn:get_class():get_full_name()
    end)
    log("[HERO] Pawn class:", class_name)
    
    return pawn
end

-- Detect if in cutscene
-- Try multiple approaches since exact property names may vary
-- Detect if in cutscene
-- Try multiple approaches since exact property names may vary
is_in_cutscene = function(hero)
    if not hero then return false end
    
    -- If game is paused (menu open), it's NOT a cutscene - no zoom allowed
    if state.gameplay_statics and state.cached_world then
        local is_paused = state.gameplay_statics:IsGamePaused(state.cached_world)
        if is_paused then return false end
    end
    
    local scripted_event = false
    local adhoc_cinematic = false
    local block_input = false
    local cinematic_mode = false
    local view_target_changed = false
    
    -- Method 1: Check for scripted event control
    if hero.IsControlledByScriptedEvent then
        scripted_event = hero:IsControlledByScriptedEvent() or false
    end
    
    -- Method 2: Check for ad-hoc cinematic
    if hero.IsControlledByAdHocCinematic then
        adhoc_cinematic = hero:IsControlledByAdHocCinematic() or false
    end
    
    -- Method 3 & 4: Check player controller flags
    local ctrl = api:get_player_controller()
    if ctrl then
        if ctrl.bBlockInput then
            block_input = true
        end
        if ctrl.bCinematicMode then
            cinematic_mode = true
        end
    end
    
    -- Method 5: Check if camera ViewTarget is not the hero (cinematic cameras)
    local pawn = api:get_local_pawn()
    if pawn and pawn.Controller then
        local camera_mgr = pawn.Controller.PlayerCameraManager
        if camera_mgr and camera_mgr.ViewTarget and camera_mgr.ViewTarget.Target then
            if camera_mgr.ViewTarget.Target ~= pawn then
                view_target_changed = true
            end
        end
    end
    
    -- Methods 1-4 are authoritative - if any is true, it's a cutscene
    -- Method 5 (ViewTarget) alone is not enough - also triggers in menus
    -- ViewTarget only counts if at least one other method is also true OR if in interaction
    local authoritative = scripted_event or adhoc_cinematic or block_input or cinematic_mode
    local is_cutscene = authoritative or (view_target_changed and state.is_interacting)
    
    return is_cutscene
end

-- Get current animation montage name
local function get_current_montage_name(hero)
    if not hero then return nil end
    
    local montage_name = nil
    pcall(function()
        local mesh = hero.Mesh
        if not mesh then return end
        
        local anim_instance = mesh:GetAnimInstance()
        if not anim_instance then return end
        
        local montage = anim_instance:GetCurrentActiveMontage()
        if montage then
            montage_name = montage:get_fname():to_string()
        end
    end)
    
    return montage_name
end

-- Check for traversal via hero's navigation components
-- Uses TRAVERSAL_COMPONENT_CHECKS table for data-driven checks
local function check_hero_traversal_state(hero)
    if not hero then return false, nil end
    
    local is_traversing = false
    local traversal_type = nil
    
    -- Data-driven component checks (for climbing, wall run, grapple, etc.)
    -- Note: Ledge hang is now handled directly in is_in_traversal with timer logic
    for _, comp_def in ipairs(TRAVERSAL_COMPONENT_CHECKS) do
        if is_traversing then break end
        
        -- Skip if config exists and is disabled
        if comp_def.config and not config[comp_def.config] then
            goto continue
        end
        
        -- Get component from hero
        local comp = hero[comp_def.component]
        if not comp then goto continue end
        
        -- Check each method/property for this component
        for _, check in ipairs(comp_def.checks) do
            if is_traversing then break end
            
            pcall(function()
                if check.method then
                    -- Method check
                    local method = comp[check.method]
                    if method then
                        local result = comp[check.method](comp)
                        if check.non_zero then
                            -- non_zero: check result is not 0/nil
                            if result and result ~= 0 then
                                is_traversing = true
                                local display_name = check.name or comp_def.name
                                traversal_type = display_name .. " (" .. check.method .. "=" .. tostring(result) .. ")"
                            end
                        elseif result then
                            -- Boolean method: just check truthiness
                            is_traversing = true
                            local display_name = check.name or comp_def.name
                            traversal_type = display_name .. " (" .. check.method .. ")"
                        end
                    end
                elseif check.property then
                    -- Property check (direct boolean property)
                    local val = comp[check.property]
                    if val then
                        is_traversing = true
                        traversal_type = comp_def.name .. " (" .. check.property .. ")"
                    end
                end
            end)
        end
        
        ::continue::
    end
    
    -- Note: NavState-based traversal (including ledge hang timer) is now handled
    -- directly in is_in_traversal, so we don't need a fallback here.
    
    -- Debug: Log component existence
    pcall(function()
        local components = {}
        for _, comp_def in ipairs(TRAVERSAL_COMPONENT_CHECKS) do
            if hero[comp_def.component] then
                table.insert(components, comp_def.name)
            end
        end
        if #components > 0 then
            log("[COMPONENTS] Available: " .. table.concat(components, ", "))
        end
    end)
    
    return is_traversing, traversal_type
end

-- Movement montage patterns that should NOT trigger interaction detection
-- These montages use transient follow-up animations that would falsely trigger 3P
local MOVEMENT_MONTAGE_BLACKLIST = {
    "hero_NAV_PhaseDash",   -- Phase dash (air dash ability)
    "NAV_PhaseDash",        -- Alternate pattern
}

-- Check if montage name matches any blacklist pattern
local function is_blacklisted_movement_montage(montage_name)
    if not montage_name then return false end
    for _, pattern in ipairs(MOVEMENT_MONTAGE_BLACKLIST) do
        if montage_name:find(pattern) then
            return true
        end
    end
    return false
end

-- Detect interaction state (chest/box/treasure/sense echo/meditation) via montage patterns
-- 1. Transient montages use /Engine/Transient path (chest boxes, meditation)
-- 2. World_Interacts montages (treasure pickups, collectibles)
-- NOTE: Balance beam turn-around also uses transient montages, so exclude NavState 13
-- NOTE: Movement abilities (phase dash, dodge) use transient follow-up montages, check blacklist
local function is_in_interaction(hero)
    if not hero then return false end
    if not config[CONFIG_KEYS.ENABLE_AUTO_INTERACTION] then return false end
    
    -- First check current montage against blacklist (most reliable check)
    local montage_name = nil
    safe_call("is_in_interaction:GetCurrentMontage", function()
        if hero.GetCurrentMontage then
            local montage = hero:GetCurrentMontage()
            if montage then
                montage_name = montage:get_full_name()
            end
        end
    end)
    
    -- If current montage is blacklisted movement, never treat as interaction
    if montage_name and is_blacklisted_movement_montage(montage_name) then
        state.last_real_montage = montage_name
        return false
    end
    
    -- Exclude balance beam - turn animations use transient montages
    local nav_state = 0
    safe_call("is_in_interaction:GetCurrentNavState", function()
        if hero.GetCurrentNavState then
            nav_state = hero:GetCurrentNavState()
        end
    end)
    -- Exclude balance beam and beam hang - turn/drop/climb animations use transient montages
    -- Also exclude beam transition state (climbing up/dropping down from beam)
    -- Also exclude phase dash - uses transient montages for dash animation
    if nav_state == NAV_STATES.BALANCE_BEAM.id or 
       nav_state == NAV_STATES.BEAM_HANG.id or
       nav_state == NAV_STATES.BEAM_TRANSITION.id or
       nav_state == NAV_STATES.PHASE_DASH.id then
        return false
    end
    
    local in_interaction = false
    
    -- Check montage patterns for interaction detection
    if montage_name then
        -- Pattern 1: Transient montages (chest/box/meditation interactions)
        if montage_name:find("/Engine/Transient") then
            -- Check if last real montage was a blacklisted movement montage
            if not is_blacklisted_movement_montage(state.last_real_montage) then
                in_interaction = true
            end
        -- Pattern 2: World_Interacts montages (treasure, collectibles)
        elseif montage_name:find("World_Interacts") then
            in_interaction = true
        else
            -- Track non-transient montages for blacklist checking
            state.last_real_montage = montage_name
        end
    else
        -- No montage playing - clear last real montage so future interactions work
        state.last_real_montage = nil
    end
    
    return in_interaction
end

-- Log current animation montage for research purposes
local function log_current_animation(hero)
    local montage_name = get_current_montage_name(hero)
    if montage_name then
        log("[ANIM] Current montage:", montage_name)
    end
    
    -- Also check if ANY montage is playing (might be on different slot/layer)
    pcall(function()
        if hero and hero.Mesh then
            local mesh = hero.Mesh
            local anim_instance = mesh:GetAnimInstance()
            if anim_instance and anim_instance.IsAnyMontagePlaying then
                local any_playing = anim_instance:IsAnyMontagePlaying()
                if any_playing and not montage_name then
                    log("[ANIM] IsAnyMontagePlaying: true (but no active montage name)")
                end
            end
        end
    end)
    
    -- Log current NavState with friendly name
    pcall(function()
        if hero.GetCurrentNavState then
            local nav_state = hero:GetCurrentNavState()
            if nav_state then
                log("[NAVSTATE]", get_nav_state_info(nav_state))
            end
        end
    end)
    
    -- NEW: Use pawn:GetCurrentMontage() directly (from uevrlib approach)
    -- This is more reliable than AnimInstance:GetCurrentActiveMontage()
    pcall(function()
        if hero.GetCurrentMontage then
            local montage = hero:GetCurrentMontage()
            if montage then
                local short_name = montage:get_fname():to_string()
                local full_name = montage:get_full_name()
                -- Track montage changes
                if state.last_pawn_montage ~= short_name then
                    log("[PAWN MONTAGE] Playing:", short_name)
                    log("[PAWN MONTAGE] Full class:", full_name)
                    state.last_pawn_montage = short_name
                end
            elseif state.last_pawn_montage ~= nil then
                log("[PAWN MONTAGE] Ended (was:", state.last_pawn_montage .. ")")
                state.last_pawn_montage = nil
            end
        end
    end)
    
    -- Log IsExecutingActions for interaction detection (RsHero)
    pcall(function()
        if hero.IsExecutingActions then
            local executing = hero:IsExecutingActions()
            if executing then
                log("[HERO] IsExecutingActions: true")
            end
        end
        if hero.IsExecutingBufferedAction then
            local buffered = hero:IsExecutingBufferedAction()
            if buffered then
                log("[HERO] IsExecutingBufferedAction: true")
            end
        end
    end)
    
    -- Log meditation state (from RsGameState.IsInMeditationTraining)
    pcall(function()
        -- Try to get game state via multiple methods
        local is_meditating = false
        local method_used = nil
        
        -- Method 1: Try via World.GetGameState (more performant)
        local pawn = api:get_local_pawn()
        if pawn and pawn.GetWorld then
            local world = pawn:GetWorld()
            if world and world.GetGameState then
                local gs = world:GetGameState()
                if gs and gs.IsInMeditationTraining then
                    is_meditating = gs:IsInMeditationTraining()
                    method_used = "World"
                end
            end
        end
        
        -- Method 2: Fallback - search for RsGameState class and get instance (cached)
        if not method_used and UEVR_UObjectHook and UEVR_UObjectHook.find_class then
            -- Cache the class lookup for performance
            if not state.rs_game_state_class then
                state.rs_game_state_class = UEVR_UObjectHook.find_class("RsGameState")
            end
            if state.rs_game_state_class then
                local game_state = UEVR_UObjectHook.get_first_object_by_class(state.rs_game_state_class)
                if game_state and game_state.IsInMeditationTraining then
                    is_meditating = game_state:IsInMeditationTraining()
                    method_used = "UObjectHook"
                end
            end
        end
        
        if method_used then
            log(string.format("[MEDITATION] %s (via %s)", tostring(is_meditating), method_used))
        end
    end)
end

-- Montage pattern to config key mapping (replaces old TRAVERSAL_PATTERNS)
-- Traversal pattern to config key mapping
-- Patterns will only trigger if their config is enabled
local PATTERN_CONFIG_MAP = {
    -- Grapple patterns (controlled by ENABLE_AUTO_GRAPPLE)
    ["NAV_Grapple"] = CONFIG_KEYS.ENABLE_AUTO_GRAPPLE,
    ["Grapple"] = CONFIG_KEYS.ENABLE_AUTO_GRAPPLE,
    -- Climb patterns (controlled by ENABLE_AUTO_CLIMB)
    ["NAV_Climb"] = CONFIG_KEYS.ENABLE_AUTO_CLIMB,
    ["Climb"] = CONFIG_KEYS.ENABLE_AUTO_CLIMB,
    ["NAV_Ledge"] = CONFIG_KEYS.ENABLE_AUTO_CLIMB,
    ["_Ledge_"] = CONFIG_KEYS.ENABLE_AUTO_CLIMB,
    ["LedgeGrab"] = CONFIG_KEYS.ENABLE_AUTO_CLIMB,
    ["NAV_Mantle"] = CONFIG_KEYS.ENABLE_AUTO_CLIMB,
    -- Wall run patterns (controlled by ENABLE_AUTO_WALLRUN)
    ["NAV_WallRun"] = CONFIG_KEYS.ENABLE_AUTO_WALLRUN,
    ["WallRun"] = CONFIG_KEYS.ENABLE_AUTO_WALLRUN,
    ["NAV_WallHang"] = CONFIG_KEYS.ENABLE_AUTO_WALLRUN,
    ["WallHang"] = CONFIG_KEYS.ENABLE_AUTO_WALLRUN,
    ["WallJump"] = CONFIG_KEYS.ENABLE_AUTO_WALLRUN,
    -- Rope/Zipline patterns (controlled by ENABLE_AUTO_ROPE)
    ["NAV_Zipline"] = CONFIG_KEYS.ENABLE_AUTO_ROPE,
    ["NAV_Rope"] = CONFIG_KEYS.ENABLE_AUTO_ROPE,
    ["Zipline"] = CONFIG_KEYS.ENABLE_AUTO_ROPE,
    ["Rope_"] = CONFIG_KEYS.ENABLE_AUTO_ROPE,
    -- Balance patterns (controlled by ENABLE_AUTO_BALANCE - off by default)
    ["NAV_Balance"] = CONFIG_KEYS.ENABLE_AUTO_BALANCE,
    ["BalanceBeam"] = CONFIG_KEYS.ENABLE_AUTO_BALANCE,
    -- Squeeze patterns (controlled by ENABLE_AUTO_SQUEEZE)
    ["NAV_Slide"] = CONFIG_KEYS.ENABLE_AUTO_SQUEEZE,
    ["Slide_"] = CONFIG_KEYS.ENABLE_AUTO_SQUEEZE,
    -- Other traversal (controlled by ENABLE_AUTO_CLIMB as general traversal)
    ["NAV_Swim"] = CONFIG_KEYS.ENABLE_AUTO_CLIMB,
    ["Swim_"] = CONFIG_KEYS.ENABLE_AUTO_CLIMB,
    ["NAV_Vault"] = CONFIG_KEYS.ENABLE_AUTO_CLIMB,
}

-- Detect if currently in traversal based on NavState, animation montage, or hero components
-- This function includes ledge hang timer logic directly (like Fallen Order's is_climbing)
is_in_traversal = function(hero)
    if not hero then return false end
    
    -- Get current NavState
    local nav_state = nil
    pcall(function()
        if hero.GetCurrentNavState then
            nav_state = hero:GetCurrentNavState()
        end
    end)
    
    -- LEDGE_HANG - Special: Timer-based logic for extended hangs (like Fallen Order)
    -- This allows quick grab & jump without switching to 3P
    if nav_state == NAV_STATES.LEDGE_HANG.id then
        -- Check if ledge hang detection is enabled
        if not config[CONFIG_KEYS.ENABLE_AUTO_LEDGE] then
            state.ledge_hang_start_time = 0
            return false
        end
        
        local now = os.clock()
        
        -- "Always 3P" option takes priority - immediate switch
        if config[CONFIG_KEYS.ENABLE_LEDGE_HANG_ALWAYS] then
            log("[TRAVERSAL] Ledge Hang - always 3P enabled")
            return true
        end
        
        -- Already in 3P - stay there (don't flicker back to 1P)
        if not state.is_first_person then
            log("[TRAVERSAL] Ledge Hang - already in 3P, staying")
            return true
        end
        
        -- Start timer if not already started
        if state.ledge_hang_start_time == 0 then
            state.ledge_hang_start_time = now
            log("[TRAVERSAL] Ledge Hang started - timer begun")
        end
        
        -- Check if hanging for more than threshold
        local hang_duration = now - state.ledge_hang_start_time
        if hang_duration >= TIMING.LEDGE_HANG_THRESHOLD then
            log("[TRAVERSAL] Ledge Hang sustained for " .. string.format("%.1f", hang_duration) .. " sec - switching to 3P")
            return true
        else
            -- Still in delay period
            -- BUT if we were just traversing (debounce active), stay in 3P to prevent flicker
            if state.is_traversing then
                log("[TRAVERSAL] Ledge Hang in delay, but traversal debounce active - staying in 3P")
                return true
            end
            -- Otherwise stay in 1P during delay (allows quick grab & jump)
            return false
        end
    else
        -- Not in ledge hang - reset timer
        if state.ledge_hang_start_time ~= 0 then
            state.ledge_hang_start_time = 0
        end
    end
    
    -- Check other NavStates (excluding LEDGE_HANG which is handled above)
    if nav_state then
        local def = NAV_STATE_BY_ID[nav_state]
        if def and def.config and def.config ~= CONFIG_KEYS.ENABLE_AUTO_LEDGE then
            if config[def.config] then
                log("[TRAVERSAL] NavState:", def.name)
                return true
            end
        end
    end
    
    -- Check montage patterns (with config awareness)
    local montage_name = get_current_montage_name(hero)
    if montage_name then
        for pattern, config_key in pairs(PATTERN_CONFIG_MAP) do
            if config[config_key] and montage_name:find(pattern) then
                log("[TRAVERSAL] Detected via montage pattern:", pattern, "in", montage_name)
                return true
            end
        end
    end
    
    -- Check traversal components (climb, wallrun, grapple, etc.)
    local is_trav, trav_type = check_hero_traversal_state(hero)
    if is_trav then
        log("[TRAVERSAL] Detected via state:", trav_type)
        return true
    end
    
    return false
end

-- Checks both hero.IsInCombat property AND attack montage patterns AND saber state
is_in_combat = function(hero)
    if not hero then return false end
    
    local in_combat = false
    local saber_in_hand = false
    local saber_unsheathed = false
    
    -- Method 1: Check IsInCombat property (works for dual-wield, force powers)
    pcall(function()
        if hero.IsInCombat ~= nil then
            in_combat = hero.IsInCombat
        end
    end)
    
    -- Method 2: Check AnimBlueprint saber state properties
    -- These are on the AnimInstance, not the pawn directly
    pcall(function()
        local mesh = hero.Mesh
        if mesh then
            local anim_instance = mesh:GetAnimInstance()
            if anim_instance then
                -- SL_SaberInHand: true when lightsaber is in hand (best indicator)
                if anim_instance.SL_SaberInHand ~= nil then
                    saber_in_hand = anim_instance.SL_SaberInHand
                end
                
                -- StMaIsLightsaberUnsheathed: state machine saber state
                if anim_instance.StMaIsLightsaberUnsheathed ~= nil then
                    saber_unsheathed = anim_instance.StMaIsLightsaberUnsheathed
                end
            end
        end
    end)
    
    -- Log saber state for debugging
    if saber_in_hand or saber_unsheathed then
        log(string.format("[SABER] InHand=%s, Unsheathed=%s, InCombat=%s",
            tostring(saber_in_hand), tostring(saber_unsheathed), tostring(in_combat)))
    end
    
    -- Method 3: Check for combat montages (catches 1-hand attacks that don't set IsInCombat)
    if not in_combat and not saber_in_hand then
        pcall(function()
            if hero.GetCurrentMontage then
                local montage = hero:GetCurrentMontage()
                if montage then
                    local montage_name = montage:get_fname():to_string()
                    -- Combat montage patterns:
                    -- ATT_ = Attack montages (lightsaber swings)
                    -- ForcePush, ForcePull, ForceSlow = Force power montages
                    -- But NOT Sheathe (hero_ATT_Sheathe_Stand_Montage)
                    if montage_name and montage_name:find("ATT_") and not montage_name:find("Sheathe") then
                        in_combat = true
                    end
                end
            end
        end)
    end
    
    -- Final result: Only actual combat (IsInCombat property or attack montages) triggers 3P
    -- Saber drawn state is stored for debounce logic (extends 3P while saber is out)
    -- This allows using the lightsaber as a flashlight without switching views
    local result = in_combat
    
    -- Store saber state for debounce logic (to extend 3P while saber is still out)
    -- This is checked separately in handle_combat_auto_switch
    if config[CONFIG_KEYS.ENABLE_SABER_DETECTION] then
        state.saber_is_active = saber_in_hand or saber_unsheathed
    else
        state.saber_is_active = false
    end
    
    return result
end

-- ============================================================================
-- INPUT HANDLING
-- ============================================================================

local function handle_dpad_hold_toggle(gamepad)
    local dpad_down = (gamepad.wButtons & XINPUT_BUTTONS.DPAD_DOWN) ~= 0
    local now = os.clock()
    
    -- BLOCK toggle during cutscenes or 2D mode (menus) - user should not switch 1P/3P during these
    if state.in_cutscene or state.in_2d_mode then
        -- Still track hold state for proper release detection
        if dpad_down then
            if not state.dpad_down_held then
                state.dpad_down_held = true
                state.dpad_down_hold_start = now
            end
        else
            state.dpad_down_held = false
        end
        return  -- Don't process toggle
    end
    
    if dpad_down then
        if not state.dpad_down_held then
            -- Just started holding
            state.dpad_down_held = true
            state.dpad_down_hold_start = now
            log("[INPUT] D-Pad Down pressed, starting hold timer")
        else
            -- Continue holding - check if threshold reached
            local hold_duration = now - state.dpad_down_hold_start
            if hold_duration >= TIMING.DPAD_HOLD_DURATION then
                -- Threshold reached - toggle!
                log("[INPUT] D-Pad Down held for " .. string.format("%.1f", hold_duration) .. " seconds - TOGGLING!")
                toggle_view()
                -- Reset to prevent repeated toggles
                state.dpad_down_hold_start = now + 1000  -- Far in the future
            end
        end
    else
        if state.dpad_down_held then
            state.dpad_down_held = false
            log("[INPUT] D-Pad Down released")
        end
    end
end

-- Handle D-Pad zoom controls (3 levels: zoomed in, default, zoomed out)
-- ONLY ACTIVE DURING CUTSCENES - D-Pad Up = zoom in, D-Pad Down = zoom out, D-Pad Left/Right = reset
local function handle_dpad_zoom_control(gamepad)
    -- Zoom controls only work during cutscenes (like Fallen Order)
    if not config[CONFIG_KEYS.ENABLE_CINEMATIC_ZOOM] then return false end
    if not state.in_cutscene then return false end
    
    local buttons = gamepad.wButtons
    local old_level = state.zoom_level
    
    -- Helper: Run action only on initial button press (not while held)
    local function on_button_press(flag, state_key, action)
        local pressed = (buttons & flag) ~= 0
        if pressed and not state[state_key] then
            state[state_key] = true
            action()
        elseif not pressed then
            state[state_key] = false
        end
    end
    
    -- D-Pad Up: Zoom IN (increase level, max +1)
    on_button_press(XINPUT_BUTTONS.DPAD_UP, "dpad_up_pressed", function()
        if state.zoom_level < 1 then state.zoom_level = state.zoom_level + 1 end
    end)
    
    -- D-Pad Down: Zoom OUT (decrease level, min -1)
    on_button_press(XINPUT_BUTTONS.DPAD_DOWN, "dpad_down_pressed", function()
        if state.zoom_level > -1 then state.zoom_level = state.zoom_level - 1 end
    end)
    
    -- D-Pad Left or Right: Reset to DEFAULT (level 0)
    on_button_press(XINPUT_BUTTONS.DPAD_LEFT, "dpad_left_pressed", function()
        state.zoom_level = 0
    end)
    on_button_press(XINPUT_BUTTONS.DPAD_RIGHT, "dpad_right_pressed", function()
        state.zoom_level = 0
    end)
    
    -- Log level change
    if state.zoom_level ~= old_level then
        local level_names = { [-1] = "ZOOMED OUT (-50)", [0] = "DEFAULT (0)", [1] = "ZOOMED IN (+50)" }
        log("[ZOOM] Level changed:", old_level, "->", state.zoom_level, "(", level_names[state.zoom_level], ")")
        return true
    end
    return false
end

-- Handle cinematic zoom - applies camera offset based on current zoom level
-- Uses set_camera_mode to properly integrate with camera offset state machine
local function handle_cinematic_zoom()
    -- Check if zoom feature is enabled
    if not config[CONFIG_KEYS.ENABLE_CINEMATIC_ZOOM] then
        return
    end
    
    -- Skip if mounted camera mode is active (mounted takes priority)
    if camera_offset.active_mode == "MOUNTED" or camera_offset.active_mode == "MOUNTED_52" then
        return
    end
    
    -- Apply zoom during cutscenes via state machine
    if state.in_cutscene then
        -- Calculate the zoom offset
        local zoom_offset = state.zoom_level * CINEMATIC_ZOOM.OFFSET_PER_LEVEL
        set_camera_mode("CUTSCENE", zoom_offset)
    else
        -- Not in cutscene - if we were in CUTSCENE mode, switch to NORMAL
        if camera_offset.active_mode == "CUTSCENE" then
            state.zoom_level = 0  -- Reset zoom level when exiting cutscene
            set_camera_mode("NORMAL")
        end
    end
end

-- ============================================================================
-- MAP/MENU 2D SCREEN MODE
-- ============================================================================
-- Switches to 2D screen mode when the game is paused (map/menu open)

local function handle_map_2d_mode()
    if not config[CONFIG_KEYS.ENABLE_MAP_2D_MODE] then 
        -- If feature is disabled but we're still in 2D mode, restore VR mode
        if state.in_2d_mode and not state.in_meditation_2d then
            vr_params.set_mod_value("VR_2DScreenMode", "false")
            vr_params.set_mod_value("VR_DecoupledPitch", "true")
            state.in_2d_mode = false
            log("[MAP2D] Feature disabled - restored VR mode")
        end
        return 
    end
    
    -- Get the world to check pause state
    local pawn = api:get_local_pawn()
    if not pawn then return end
    
    local is_in_map = false
    local debug_info = "checking"
    
    -- Detect HoloMap by checking the bIsWorldMapOpen property on the hologram instance
    -- (Instance always exists, so we must check the property value)
    safe_call("handle_map_2d_mode", function()
        -- Cache the hologram class lookup for performance
        if not state.hologram_class then
            state.hologram_class = api:find_uobject("Class /Script/SwGame.SwWorldMapHologramBase")
        end
        
        if state.hologram_class then
            local hologram = UEVR_UObjectHook.get_first_object_by_class(state.hologram_class)
            if hologram and UEVR_UObjectHook.exists(hologram) then
                -- Check the bIsWorldMapOpen property
                if hologram.bIsWorldMapOpen then
                    is_in_map = hologram.bIsWorldMapOpen
                    debug_info = "isOpen=" .. tostring(is_in_map)
                else
                    debug_info = "no bIsWorldMapOpen property"
                end
            else
                debug_info = "no hologram instance"
            end
        else
            debug_info = "no hologram class"
        end
    end)
    
    -- Log once per second for debugging (uses throttled log)
    log("[MAP2D DEBUG] " .. debug_info)
    
    -- State changed?
    if is_in_map ~= state.is_paused then
        state.is_paused = is_in_map
        
        if is_in_map then
            -- Map opened - switch to 2D mode
            log("[MAP2D] Map opened - switching to 2D screen mode")
            
            -- CRITICAL: Reset camera offsets to 0 for cursor alignment
            setCameraOffset(0, 0, 0)
            -- Reset active_mode so mounted camera restores properly when map closes
            camera_offset.active_mode = "2D_MODE"
            
            -- Recenter view before entering 2D mode
            vr_params:recenter_view()
            
            -- Set 2D mode VR parameters
            vr_params.set_mod_value("VR_2DScreenMode", "true")
            vr_params.set_mod_value("VR_DecoupledPitch", "false")
            -- vr_params.set_mod_value("UI_FollowView", "false")  -- TODO: test if needed
            state.in_2d_mode = true
        else
            -- Map closed - switch back to VR mode
            log("[MAP2D] Map closed - switching back to VR mode")
            vr_params.set_mod_value("VR_2DScreenMode", "false")
            vr_params.set_mod_value("VR_DecoupledPitch", "true")
            -- vr_params.set_mod_value("UI_FollowView", "true")  -- TODO: test if needed
            state.in_2d_mode = false
            
            -- Camera offsets will be restored by handle_mounted_camera_offset
        end
    end
    
    -- CRITICAL: Apply DecoupledPitch EVERY FRAME while in 2D mode
    -- This ensures the view stays level in menus
    if state.is_paused then
        vr_params.set_mod_value("VR_DecoupledPitch", "false")
    end
end

-- Handle meditation 2D mode - switches to 2D screen when meditating
local function handle_meditation_2d_mode(hero)
    if not config[CONFIG_KEYS.ENABLE_MEDITATION_2D_MODE] then 
        -- If disabled but still in meditation 2D, restore
        if state.in_meditation_2d then
            vr_params.set_mod_value("VR_2DScreenMode", "false")
            vr_params.set_mod_value("VR_DecoupledPitch", "true")
            state.in_meditation_2d = false
            state.in_2d_mode = false
        end
        return 
    end
    if not hero then return end
    
    -- Check if in meditation (NavState 20)
    local nav_state = 0
    safe_call("handle_meditation_2d_mode", function()
        if hero.GetCurrentNavState then
            nav_state = hero:GetCurrentNavState()
        end
    end)
    
    local is_meditating = (nav_state == NAV_STATES.MEDITATION.id)
    
    -- Don't interfere with map 2D mode
    if state.is_paused then return end
    
    if is_meditating and not state.in_meditation_2d then
        -- Started meditating - switch to 2D mode
        log("[MEDITATION2D] Started meditating - switching to 2D screen mode")
        
        -- CRITICAL: Reset camera offsets to 0 for cursor alignment
        setCameraOffset(0, 0, 0)
        -- Reset active_mode so mounted camera restores properly when meditation ends
        camera_offset.active_mode = "2D_MODE"
        
        -- Recenter view before entering 2D mode
        vr_params:recenter_view()
        
        -- Set 2D mode VR parameters
        vr_params.set_mod_value("VR_2DScreenMode", "true")
        vr_params.set_mod_value("VR_DecoupledPitch", "false")
        -- vr_params.set_mod_value("UI_FollowView", "false")  -- TODO: test if needed
        state.in_meditation_2d = true
        state.in_2d_mode = true
    elseif not is_meditating and state.in_meditation_2d then
        -- Stopped meditating - switch back to VR mode
        log("[MEDITATION2D] Stopped meditating - switching back to VR mode")
        vr_params.set_mod_value("VR_2DScreenMode", "false")
        vr_params.set_mod_value("VR_DecoupledPitch", "true")
        -- vr_params.set_mod_value("UI_FollowView", "true")  -- TODO: test if needed
        state.in_meditation_2d = false
        state.in_2d_mode = false
        
        -- Camera offsets will be restored by handle_mounted_camera_offset
    end
    
    -- CRITICAL: Apply DecoupledPitch EVERY FRAME while in meditation 2D
    if state.in_meditation_2d then
        vr_params.set_mod_value("VR_DecoupledPitch", "false")
    end
end

-- ============================================================================
-- AUTO-SWITCH LOGIC
-- ============================================================================

-- Handlers now ONLY update state flags.
-- The centralized view decision in on_pre_engine_tick handles all view switching.

local function handle_cutscene_auto_switch(hero)
    if not config[CONFIG_KEYS.ENABLE_AUTO_CUTSCENE] then 
        state.in_cutscene = false
        return 
    end
    
    local was_in_cutscene = state.in_cutscene
    state.in_cutscene = is_in_cutscene(hero)
    
    -- Only log state changes, do NOT call view switching
    if state.in_cutscene and not was_in_cutscene then
        log("[STATE] Entered cutscene")
    elseif not state.in_cutscene and was_in_cutscene then
        log("[STATE] Exited cutscene")
    end
end

local function handle_combat_auto_switch(hero)
    if not config[CONFIG_KEYS.ENABLE_AUTO_MELEE] then 
        state.is_in_combat = false
        state.combat_exit_time = 0
        return 
    end
    
    local was_in_combat = state.is_in_combat
    local now_in_combat = is_in_combat(hero)
    local now = os.clock()
    
    if now_in_combat and not was_in_combat then
        -- Just entered combat - set flag only
        log("[STATE] Entered combat")
        state.is_in_combat = true
        state.combat_exit_time = 0
    elseif not now_in_combat and was_in_combat then
        -- Combat ended - handle debounce
        -- Saber still drawn extends the debounce
        if state.saber_is_active then
            state.combat_exit_time = now
            log("[STATE] Combat paused but saber still drawn")
        elseif state.combat_exit_time == 0 then
            state.combat_exit_time = now
            log("[STATE] Combat ended - starting debounce")
        elseif (now - state.combat_exit_time) >= TIMING.COMBAT_DEBOUNCE_TIME then
            -- Debounce passed - clear flag
            log("[STATE] Combat debounce complete")
            state.is_in_combat = false
            state.combat_exit_time = 0
        end
    elseif now_in_combat then
        -- Still in combat - reset debounce
        state.combat_exit_time = 0
    end
end

local function handle_traversal_auto_switch(hero)
    -- Detection already respects individual config toggles
    -- This handler only manages state flags
    
    local was_traversing = state.is_traversing
    local now_traversing = is_in_traversal(hero)
    local now = os.clock()
    
    -- Get current NavState for debounce safety check
    local nav_state = nil
    pcall(function()
        if hero and hero.GetCurrentNavState then
            nav_state = hero:GetCurrentNavState()
        end
    end)
    
    -- Check if we're in a known "safe" ground state (OK to exit 3P)
    -- ONLY Ground (1) is safe - Jumping (3) appears briefly during wall->ledge transitions
    -- Also consider Balance Beam (13) safe IF balance beam auto-3P is DISABLED (meaning user wants 1P)
    local is_safe_ground_state = nav_state and (
        nav_state == 1 or 
        (nav_state == NAV_STATES.BALANCE_BEAM.id and not config[CONFIG_KEYS.ENABLE_AUTO_BALANCE])
    )
    
    if now_traversing and not was_traversing then
        -- Just entered traversal - set flag only
        log("[STATE] Entered traversal")
        state.is_traversing = true
        state.traversal_exit_time = 0
    elseif not now_traversing and was_traversing then
        -- Traversal ended - handle debounce
        if state.traversal_exit_time == 0 then
            state.traversal_exit_time = now
            log("[STATE] Traversal ended - starting debounce")
        end
        
        -- Check if we can complete debounce
        if is_safe_ground_state then
            -- In a safe state - complete debounce immediately
            log("[STATE] Traversal debounce complete - safe state (NavState=" .. tostring(nav_state) .. ")")
            state.is_traversing = false
            state.traversal_exit_time = 0
        elseif (now - state.traversal_exit_time) >= TIMING.TRAVERSAL_DEBOUNCE_TIME then
            -- Debounce time passed but not in safe state - extend debounce
            log("[STATE] Debounce extended - unknown NavState " .. tostring(nav_state))
            state.traversal_exit_time = now
        end
    elseif now_traversing then
        -- Still traversing - reset debounce
        state.traversal_exit_time = 0
    end
end

local function handle_interaction_auto_switch(hero)
    if not config[CONFIG_KEYS.ENABLE_AUTO_INTERACTION] then 
        state.is_interacting = false
        state.interaction_exit_time = 0
        return 
    end
    
    -- Skip interaction detection when traversal is active
    -- (climbing/grapple/etc also use transient montages, would cause false triggers)
    if state.is_traversing then
        if state.is_interacting then
            log("[STATE] Clearing interaction - traversal active")
            state.is_interacting = false
            state.interaction_exit_time = 0
        end
        return
    end
    
    local was_interacting = state.is_interacting
    local now_interacting = is_in_interaction(hero)
    local now = os.clock()
    
    if now_interacting and not was_interacting then
        -- Just started interaction - set flag only
        log("[STATE] Started interaction")
        state.is_interacting = true
        state.interaction_exit_time = 0
    elseif not now_interacting and was_interacting then
        -- Interaction ended - handle debounce
        if state.interaction_exit_time == 0 then
            state.interaction_exit_time = now
            log("[STATE] Interaction ended - starting debounce")
        elseif (now - state.interaction_exit_time) >= TIMING.INTERACTION_DEBOUNCE_TIME then
            log("[STATE] Interaction debounce complete")
            state.is_interacting = false
            state.interaction_exit_time = 0
        end
    elseif now_interacting then
        -- Still interacting - reset debounce
        state.interaction_exit_time = 0
    end
end

-- Handle camera offset for mounted creature riding (1st person only)
local function handle_mounted_camera_offset(hero)
    if not hero then return end
    
    -- Check if mounted (NavState 30, 32, 33, 34, 52 are all mounted-related)
    local nav_state = 0
    safe_call("handle_mounted_camera_offset", function()
        if hero.GetCurrentNavState then
            nav_state = hero:GetCurrentNavState()
        end
    end)
    
    -- Check for Nekko-type mount (NavState 30, 32, 33, 34)
    local is_nekko_mounted = (nav_state == NAV_STATES.MOUNTED.id or
                              nav_state == NAV_STATES.MOUNTED_JUMP_32.id or
                              nav_state == NAV_STATES.MOUNTED_JUMP_33.id or
                              nav_state == NAV_STATES.MOUNTED_JUMP_34.id)
    
    -- Check for Type 2 mount (NavState 52)
    local is_mount_52 = (nav_state == NAV_STATES.MOUNTED_52.id)
    
    -- Only manage camera offsets when in 1st person
    -- (3rd person sets its own offset to 0,0,0 and shouldn't be overridden)
    if not state.is_first_person then
        return
    end
    
    if is_nekko_mounted then
        set_camera_mode("MOUNTED")
    elseif is_mount_52 then
        set_camera_mode("MOUNTED_52")
    else
        set_camera_mode("NORMAL")
    end
end

-- ============================================================================
-- MAIN ENGINE TICK - STATE DETECTION & CENTRALIZED VIEW DECISION
-- ============================================================================
-- This runs every frame BEFORE engine processing.
-- All state detection and view switching happens here.
-- on_xinput_get_state only handles input.

local function on_pre_engine_tick(engine, delta)
    local hero = get_hero()
    if not hero then return end
    
    -- Initialize meshes on first frame when pawn becomes available
    if not state.meshes_initialized then
        state.meshes_initialized = true
        if state.is_first_person then
            log("[MESH] First frame - hiding meshes for 1st person")
            set_player_mesh_visibility(hero, false)
        end
    end
    
    -- ========================================
    -- PHASE 1: Update all state flags
    -- ========================================
    -- Handlers only set flags, they do NOT call view switching
    
    handle_cutscene_auto_switch(hero)
    handle_combat_auto_switch(hero)
    handle_traversal_auto_switch(hero)
    handle_interaction_auto_switch(hero)
    
    -- ========================================
    -- PHASE 2: Handle 2D mode (map/meditation)
    -- ========================================
    -- These set their own VR mode flags
    
    handle_map_2d_mode()
    handle_meditation_2d_mode(hero)
    
    -- ========================================
    -- PHASE 3: CENTRALIZED VIEW DECISION
    -- ========================================
    -- ONE place decides 1P vs 3P based on ALL state flags
    
    local should_3p, reason = should_be_in_3p(hero)
    
    if should_3p and state.is_first_person then
        -- Need to switch to 3P
        log("[VIEW] Switching to 3P - reason: " .. (reason or "unknown"))
        set_third_person_view(reason)
    elseif not should_3p and not state.is_first_person then
        -- Need to switch to 1P
        log("[VIEW] Switching to 1P - no active 3P states")
        set_first_person_view("no active 3P states", hero, true)  -- force=true since we already checked
    end
    
    -- ========================================
    -- PHASE 4: Camera offset management
    -- ========================================
    -- Handle mounted camera offset (only in 1st person)
    handle_mounted_camera_offset(hero)
    
    -- Handle cinematic zoom (during cutscenes)
    handle_cinematic_zoom()
    
    -- ========================================
    -- PHASE 4b: Buddy visibility (continuous)
    -- ========================================
    -- BD-1 visibility depends on attach state, not just view mode
    -- In 1P: hide if on back, show if on ground
    -- In 3P: always show
    local pawn = api:get_local_pawn(0)
    if pawn and state.is_first_person then
        -- Continuously update buddy visibility based on attach state
        set_buddy_droid_visibility(false, pawn)  -- false = 1P mode, function checks attach state
        
        -- TEST: Show body (NOT face) when not running in 1P
        local velocity_magnitude = 0
        pcall(function()
            local velocity = pawn:GetVelocity()
            if velocity then
                -- Calculate magnitude (horizontal only, ignore vertical)
                velocity_magnitude = math.sqrt(velocity.X * velocity.X + velocity.Y * velocity.Y)
            end
        end)
        
        -- Velocity thresholds: standing < 10, walking ~180-220
        local is_standing = velocity_magnitude < 10
        local is_walking = velocity_magnitude >= 10 and velocity_magnitude < 300
        
        -- Show body based on config options
        local should_show_body = false
        if is_standing and config[CONFIG_KEYS.SHOW_BODY_STANDING] then
            should_show_body = true
        elseif is_walking and config[CONFIG_KEYS.SHOW_BODY_WALKING] then
            should_show_body = true
        end
        
        -- Only update if state changed
        if state.body_visible_1p ~= should_show_body then
            state.body_visible_1p = should_show_body
            
            -- Only toggle body meshes (Jacket, Shirt), NOT face
            local hidden = not should_show_body
            local toggled_count = 0
            pcall(function()
                local TORSO_MESH_PATTERNS = { "Jacket", "Shirt" }
                local skeletal_mesh_class = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")
                if skeletal_mesh_class and pawn.K2_GetComponentsByClass then
                    local components = pawn:K2_GetComponentsByClass(skeletal_mesh_class)
                    if components then
                        for i, component in pairs(components) do
                            if component then
                                -- Use property access like original code, not method call
                                local mesh_asset_path = nil
                                pcall(function()
                                    if component.SkeletalMesh then
                                        local mesh = component.SkeletalMesh
                                        if mesh then
                                            mesh_asset_path = mesh:get_full_name()
                                        end
                                    end
                                end)
                                
                                if mesh_asset_path then
                                    for _, pattern in ipairs(TORSO_MESH_PATTERNS) do
                                        if mesh_asset_path:find(pattern) then
                                            if component.SetHiddenInGame then
                                                component:SetHiddenInGame(hidden, true)
                                                toggled_count = toggled_count + 1
                                            end
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            
            log("[TEST] Body visibility in 1P: " .. tostring(should_show_body) .. " (velocity=" .. string.format("%.1f", velocity_magnitude) .. ", toggled=" .. toggled_count .. ")")
        end
    end
    
    -- ========================================
    -- PHASE 5: Debug logging
    -- ========================================
    log_current_animation(hero)
end

-- ============================================================================
-- INPUT HANDLER - ONLY HANDLES USER INPUT
-- ============================================================================
-- This only fires when controller input is received.
-- State detection happens in on_pre_engine_tick.

local function on_xinput_get_state(_, _, xinput_state)
    local gamepad = xinput_state.Gamepad
    
    -- Handle D-Pad Down hold to toggle view
    handle_dpad_hold_toggle(gamepad)
    
    -- Handle D-Pad zoom controls (Up=in, Down=out, Left/Right=reset)
    handle_dpad_zoom_control(gamepad)
end

-- ============================================================================
-- UI (ImGui)
-- ============================================================================

local function draw_imgui_menu()
    imgui.text("Jedi Survivor VR View Switcher v" .. VERSION)
    imgui.separator()
    
    -- Current state display
    imgui.text("Current View: " .. (state.is_first_person and "First Person" or "Third Person"))
    imgui.text("In Cutscene: " .. (state.in_cutscene and "Yes" or "No"))
    imgui.text("In Combat: " .. (state.is_in_combat and "Yes" or "No"))
    imgui.text("In Traversal: " .. (state.is_traversing and "Yes" or "No"))
    imgui.text("In Interaction: " .. (state.is_interacting and "Yes" or "No"))
    
    imgui.separator()
    imgui.text("Controls:")
    imgui.text("  Toggle 1P/3P: D-Pad Down (hold " .. TIMING.DPAD_HOLD_DURATION .. "s)")
    imgui.text("  Cutscene Controls: D-Pad Up/Down=Zoom, Left/Right=Reset")
    
    imgui.separator()
    if imgui.button("Save Config##save", 95, 0) then
        save_config()
    end
    imgui.same_line()
    if imgui.button("Reset Defaults##reset", 95, 0) then
        reset_config_to_defaults()
    end
    
    imgui.separator()
    
    -- Render all config option groups using data-driven approach
    for _, group in ipairs(UI_CONFIG_OPTIONS) do
        imgui.text(group.header)
        for _, item in ipairs(group.items) do
            local changed, new_val = imgui.checkbox(item.label .. "##" .. item.key, config[item.key])
            if changed then config[item.key] = new_val end
        end
        
        -- Special displays after certain groups
        if group.header == "Cinematic Zoom:" then
            local zoom_level_names = { [-1] = "ZOOMED OUT", [0] = "DEFAULT", [1] = "ZOOMED IN" }
            local zoom_name = zoom_level_names[state.zoom_level] or "UNKNOWN"
            local zoom_offset = state.zoom_level * CINEMATIC_ZOOM.OFFSET_PER_LEVEL
            imgui.text("  Level: " .. zoom_name .. " (" .. tostring(zoom_offset) .. ")")
            imgui.text("  D-Pad: Up=in, Down=out, Left/Right=reset")
        elseif group.header == "Map/Menu 2D Mode:" then
            local pause_status = state.is_paused and "PAUSED (2D)" or "playing (VR)"
            imgui.text("  Game: " .. pause_status)
        elseif group.header == "Debug:" then
            if config[CONFIG_KEYS.DEBUG_LOGGING] then
                imgui.text_colored(0xFF00FF00, "Logging ENABLED - check log.txt")
            end
        end
        
        imgui.separator()
    end

    -- DO NOT REMOVE:
    -- Dump Hero State button for debugging
    -- if imgui.button("Dump Hero State##dump", 200, 0) then
    --     local pawn = api:get_local_pawn(0)
    --     if pawn then
    --         print("[DEBUG] Dumping hero state...")
    --         debugModule.clearDumpFile()
    --         debugModule.dump(pawn, false, nil, true)
    --         print("[DEBUG] Dump complete - check data/dump_output.txt")
    --     else
    --         print("[DEBUG] No pawn found")
    --     end
    -- end
    
    imgui.separator()
    if imgui.button("Toggle View Now##toggle", 200, 0) then
        toggle_view()
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function initialize()
    print("==============================================")
    print("Jedi Survivor VR View Switcher v" .. VERSION)
    print("==============================================")
    print("Hold D-Pad Down for " .. TIMING.DPAD_HOLD_DURATION .. " seconds to toggle first/third person")
    print("")
    
    -- Load saved configuration
    load_config()
    
    -- Activate UObject hook
    if UEVR_UObjectHook then
        UEVR_UObjectHook.activate()
    end
    
    -- Cache GameplayStatics DEFAULT INSTANCE for IsGamePaused checks (once at startup)
    -- IMPORTANT: Must use Default__GameplayStatics, not the class
    state.gameplay_statics = api:find_uobject("GameplayStatics /Script/Engine.Default__GameplayStatics")
    
    -- Cache World for IsGamePaused (once at startup)
    local game_engine_class = api:find_uobject("Class /Script/Engine.GameEngine")
    if game_engine_class then
        local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
        if game_engine and game_engine.GameViewport then
            state.cached_world = game_engine.GameViewport.World
        end
    end
    
    -- Register UI and callbacks
    uevr.lua.add_script_panel("Jedi Survivor", draw_imgui_menu)
    
    -- Register engine tick for state detection & view switching (runs every frame)
    sdk.callbacks.on_pre_engine_tick(on_pre_engine_tick)
    
    -- Register input handler for user input only
    sdk.callbacks.on_xinput_get_state(on_xinput_get_state)
    
    -- Start in first person (UEVR default)
    if UEVR_UObjectHook then
        UEVR_UObjectHook.set_disabled(false)
    end
    state.is_first_person = true
    
    -- Ensure 2D screen mode is off (VR mode active)
    vr_params.set_mod_value("VR_2DScreenMode", "false")
    state.in_2d_mode = false
    
    -- Reset camera offset to NORMAL on startup (clean start)
    state.zoom_level = 0
    setCameraOffset(NORMAL_CAMERA.FORWARD, NORMAL_CAMERA.RIGHT, NORMAL_CAMERA.UP)
    camera_offset.active_mode = "NORMAL"
    
    -- Mark meshes as needing initialization (pawn not available yet at startup)
    state.meshes_initialized = false
    
    print("View Switcher loaded successfully!")
end

-- Start the script
initialize()
