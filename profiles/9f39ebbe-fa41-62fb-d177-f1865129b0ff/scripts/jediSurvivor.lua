local VERSION = "1.0.0"
--[[
@title Jedi Survivor Smart Profile: 1P Explorer, 3P Combat
@version 0.9.6

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
- 1.0.0: NavState SDK Alignment.
         All NAV_STATES entries renamed to match the SDK ERsNavState enum (RsGameTechRT_structs.hpp).
         Added all missing NavStates from the SDK (commented out where unused: DebugFly, MARKDEBUGCLIMB).
         New active entries: JumpCancelled, Glide, WallJumpAscend, Slide, Swim, WallRun,
         NavigationTransition, SpeederBike, Quicksand, Vehicle, WallHang, Mounted (base),
         Mounted_Sprint, Mounted_Agitated, VehicleATAT, ConstrainedControl, Glider_Air_Reverse,
         NarrativeConstraints, Boosting, Mounted_Spamel_Air.
- 0.9.12: Cutscene Detection Fix.
         Fix: Cutscene detection dropped after 1-2 ticks, preventing zoom from working.
         Root cause: NavState 19 is Cinematic per SDK (ERsNavState enum), but was incorrectly restricted
         to combat-only. Renamed from CONTEXT_SENSITIVE to CINEMATIC and made unconditionally authoritative,
         matching how Fallen Order treats its equivalent NavState 20. The 1.5s debounce handles any brief
         NavState 19 flashes during non-cinematic gameplay.
- 0.9.11: Cutscene Zoom & Mount Camera Fix.
         Fix: Cutscene zoom (D-Pad Up/Down) now works — zoom offset was only applied in 1P branch of Phase 4, but cutscenes trigger 3P. Zoom now also applies in 3P during cutscenes.
         Fix: Mount camera offsets not restoring after closing 2D map/meditation. active_mode stayed "2D_MODE" after map closed, blocking the entire Phase 4 camera offset evaluation.
- 0.9.10: Montage Identity Oscillation Fix.
         Fix: Cere montage fallback now only matches cutscene montages (Cere_CS_*), not attack montages (Cere_ATT_*).
         The game reuses Cere's attack animations on Cal's pawn even when Cere is dead, causing rapid Cal/Cere identity oscillation and mesh flickering during combat.
- 0.9.9: Havok Cloth Poncho Fix & Full 1P Mesh Hiding.
         Fix: Cal's poncho/robe (Havok cloth) now properly hidden in 1P via HavokClothEntityComponent.SetClothVisibility() — SetHiddenInGame has no effect on Havok cloth meshes.
         Fix: Cal's hair (HairAJK) and beard (FacialHairAJK) now hidden in 1P — were missing from TORSO_MESH_PATTERNS.
         Fix: native_cere_flag_confirmed prevents Cal/Cere identity oscillation from residual montage names overriding IsMarkedPlayingAsCere().
         Fix: Mesh toggle summary now uses log_critical (always prints, not suppressed by smart logger).
         Added: One-time mesh component dump on pawn init for debugging (lists all SkeletalMeshComponents with asset paths).
         Added: Cere cloak state tracking — Load/UnloadCereClothMesh only called on actual state changes, not every frame.
- 0.9.8: Cere T-Pose Fix & Dynamic Character Identity.
         Fix: Dynamic is_cere detection — character identity refreshed every frame via IsMarkedPlayingAsCere(), no longer permanently latched.
         Fix: Removed SkeletalMeshFaceForIKRig false positive (always present on pawn regardless of character).
         Fix: Removed all in_cutscene guards on cross-character mesh force-hiding — dynamic identity makes them redundant.
         Fix: Log file cleared on script reset for clean debugging sessions.
- 0.9.7: Cutscene Detection Overhaul. Added NavState 19 (Context-Sensitive) and CinematicBlendInterp as new cutscene detection signals. Removed broken FOV and non-existent IsControlledByScriptedEvent/AdHocCinematic methods. Fixed smart logging suppressing critical state transitions.
- 0.9.6: Camera Architecture Fix. Cinematic zoom logic no longer bypasses the main view state machine to force 1P camera offsets at the end of cutscenes, preventing characters from clipping under the floor (turning invisible) during 3P sequences like the Vader boss fight.
- 0.9.5: Fixed a bug where Cere would appear in a T-pose overlapping Cal during 3rd person sequences. The script now dynamically checks if the player is actively playing as Cere, and ignores her hidden meshes when playing as Cal.
- 0.9.4: Fixed a bug where hiding player meshes forced attached debug collision spheres to become visible. Modified `SetHiddenInGame` to no longer propagate visibility to child components.
- 0.9.3: Fixed premature cutscene exits. Cutscenes triggered by interactions now properly maintain 3P view until the visual sequence officially ends, rather than dropping early due to interaction state debounce timers.
- 0.9.2: Fixed Cere character mesh hiding (handles her Face, Body, and separately unloads her Havok cloth cloak). Replaced all bare pcall wrappers with project-standard safe_call bindings.
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


local IS_PRODUCTION = false

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
    CUTSCENE_DEBOUNCE_TIME = 1.5,       -- Seconds to wait before switching out of cutscene (covers transient drops)
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

-- Centralized NavState definitions with friendly names and categories
-- Names match SDK: ERsNavState enum (RsGameTechRT_structs.hpp)
-- Each entry defines: id, name, category, and optional config key for auto-switch

local NAV_STATES = {
    -- Ground/Default States (no auto-switch, kept for logging)
    NULL = { id = 0, name = "Null", category = "Ground" },                             -- ERsNavState::null
    GROUND = { id = 1, name = "Ground", category = "Ground" },                         -- ERsNavState::Ground
    JUMP_PRE_ASCEND = { id = 2, name = "Jump Pre-Ascend", category = "Ground" },       -- ERsNavState::JumpPreAscend
    JUMP_ASCEND = { id = 3, name = "Jump Ascend", category = "Ground" },               -- ERsNavState::JumpAscend
    JUMP_CANCELLED = { id = 4, name = "Jump Cancelled", category = "Ground" },         -- ERsNavState::JumpCancelled
    FALL = { id = 5, name = "Fall", category = "Ground", config = CONFIG_KEYS.ENABLE_AUTO_FALLING },  -- ERsNavState::Fall

    -- Traversal States
    GLIDE = { id = 6, name = "Glide", category = "Traversal" },                        -- ERsNavState::Glide
    WALL_JUMP_ASCEND = { id = 7, name = "Wall Jump Ascend", category = "Traversal" },  -- ERsNavState::WallJumpAscend
    SLIDE = { id = 8, name = "Slide", category = "Traversal" },                        -- ERsNavState::Slide
    LEDGE_HANG = { id = 9, name = "Ledge Hang", category = "Climbing", config = CONFIG_KEYS.ENABLE_AUTO_LEDGE },  -- ERsNavState::LedgeHang
    ROPE = { id = 10, name = "Rope", category = "Rope", config = CONFIG_KEYS.ENABLE_AUTO_ROPE },                  -- ERsNavState::Rope
    SWIM = { id = 11, name = "Swim", category = "Traversal" },                         -- ERsNavState::Swim
    MONKEY_BEAM = { id = 12, name = "Monkey Beam", category = "Climbing", config = CONFIG_KEYS.ENABLE_AUTO_CLIMB },  -- ERsNavState::MonkeyBeam
    BALANCE_BEAM = { id = 13, name = "Balance Beam", category = "Balance", config = CONFIG_KEYS.ENABLE_AUTO_BALANCE },  -- ERsNavState::BalanceBeam
    BEAM_TRANSITION = { id = 14, name = "Beam Transition", category = "Climbing", config = CONFIG_KEYS.ENABLE_AUTO_CLIMB },  -- ERsNavState::BeamTransition
    WALL_RUN = { id = 15, name = "Wall Run", category = "Traversal" },                 -- ERsNavState::WallRun
    CLIMB = { id = 16, name = "Climb", category = "Climbing", config = CONFIG_KEYS.ENABLE_AUTO_CLIMB },  -- ERsNavState::Climb
    ZIPLINE = { id = 17, name = "Zipline", category = "Rope", config = CONFIG_KEYS.ENABLE_AUTO_ZIPLINE },  -- ERsNavState::Zipline
    -- DEBUG_FLY = { id = 18, name = "Debug Fly", category = "Debug" },                -- ERsNavState::DebugFly

    -- Cinematic/Special States
    CINEMATIC = { id = 19, name = "Cinematic", category = "Cinematic", config = CONFIG_KEYS.ENABLE_AUTO_CUTSCENE },  -- ERsNavState::Cinematic
    MEDITATION = { id = 20, name = "Meditation", category = "Special", config = CONFIG_KEYS.ENABLE_AUTO_MEDITATION },  -- ERsNavState::Meditation
    DEATH = { id = 21, name = "Death", category = "Special", config = CONFIG_KEYS.ENABLE_AUTO_CUTSCENE },  -- ERsNavState::Death
    NAVIGATION_TRANSITION = { id = 22, name = "Navigation Transition", category = "Special" },  -- ERsNavState::NavigationTransition
    SPEEDER_BIKE = { id = 23, name = "Speeder Bike", category = "Vehicle" },            -- ERsNavState::SpeederBike
    GRAPPLE = { id = 24, name = "Grapple", category = "Grapple", config = CONFIG_KEYS.ENABLE_AUTO_GRAPPLE },  -- ERsNavState::Grapple
    QUICKSAND = { id = 25, name = "Quicksand", category = "Special" },                  -- ERsNavState::Quicksand
    VEHICLE = { id = 26, name = "Vehicle", category = "Vehicle" },                       -- ERsNavState::Vehicle
    WALL_HANG = { id = 27, name = "Wall Hang", category = "Climbing" },                  -- ERsNavState::WallHang
    PHASE_DASH = { id = 28, name = "Phase Dash", category = "Movement" },                -- ERsNavState::PhaseDash

    -- Mount States
    MOUNTED = { id = 29, name = "Mounted", category = "Mount" },                        -- ERsNavState::Mounted (base, not observed in use)
    MOUNTED_GROUND = { id = 30, name = "Mounted Ground", category = "Mount", config = CONFIG_KEYS.ENABLE_AUTO_MOUNTED },  -- ERsNavState::Mounted_Ground
    MOUNTED_SPRINT = { id = 31, name = "Mounted Sprint", category = "Mount", config = CONFIG_KEYS.ENABLE_AUTO_MOUNTED },  -- ERsNavState::Mounted_Sprint
    MOUNTED_PRE_JUMP = { id = 32, name = "Mounted Pre-Jump", category = "Mount", config = CONFIG_KEYS.ENABLE_AUTO_MOUNTED },  -- ERsNavState::Mounted_PreJump
    MOUNTED_JUMP = { id = 33, name = "Mounted Jump", category = "Mount", config = CONFIG_KEYS.ENABLE_AUTO_MOUNTED },  -- ERsNavState::Mounted_Jump
    MOUNTED_FALL = { id = 34, name = "Mounted Fall", category = "Mount", config = CONFIG_KEYS.ENABLE_AUTO_MOUNTED },  -- ERsNavState::Mounted_Fall
    MOUNTED_AGITATED = { id = 35, name = "Mounted Agitated", category = "Mount", config = CONFIG_KEYS.ENABLE_AUTO_MOUNTED },  -- ERsNavState::Mounted_Agitated

    -- Flying/Gliding States
    GLIDER_AIR = { id = 43, name = "Glider Air", category = "Mount", config = CONFIG_KEYS.ENABLE_AUTO_FLYING },  -- ERsNavState::Glider_Air

    -- Spamel (Tall Animal) States
    MOUNTED_SPAMEL_GROUND = { id = 52, name = "Mounted Spamel Ground", category = "Mount", config = CONFIG_KEYS.ENABLE_AUTO_MOUNTED },  -- ERsNavState::Mounted_Spamel_Ground
    -- MARK_DEBUG_CLIMB = { id = 53, name = "Mark Debug Climb", category = "Debug" },   -- ERsNavState::MARKDEBUGCLIMB
    VEHICLE_ATAT = { id = 54, name = "Vehicle AT-AT", category = "Vehicle" },            -- ERsNavState::VehicleATAT
    CLAUSTROPHOBIA = { id = 55, name = "Claustrophobia", category = "Squeeze", config = CONFIG_KEYS.ENABLE_AUTO_SQUEEZE },  -- ERsNavState::Claustrophobia
    CONSTRAINED_CONTROL = { id = 56, name = "Constrained Control", category = "Special" },  -- ERsNavState::ConstrainedControl
    GLIDER_AIR_REVERSE = { id = 57, name = "Glider Air Reverse", category = "Mount", config = CONFIG_KEYS.ENABLE_AUTO_FLYING },  -- ERsNavState::Glider_Air_Reverse
    NARRATIVE_CONSTRAINTS = { id = 58, name = "Narrative Constraints", category = "Special" },  -- ERsNavState::NarrativeConstraints
    BOOSTING = { id = 59, name = "Boosting", category = "Movement" },                    -- ERsNavState::Boosting
    MOUNTED_SPAMEL_AIR = { id = 60, name = "Mounted Spamel Air", category = "Mount", config = CONFIG_KEYS.ENABLE_AUTO_MOUNTED },  -- ERsNavState::Mounted_Spamel_Air
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
    -- Dynamic character identity (refreshed each frame)
    is_cere = false,
    native_cere_flag_confirmed = false, -- Set true once IsMarkedPlayingAsCere returns true
    cached_pawn_address = nil,
    
    -- Cere cloak tracking: only call Load/UnloadCereClothMesh when desired state changes
    cere_cloak_should_be_visible = false,
    
    -- Camera state (UEVR starts in first person)
    is_first_person = true,
    
    -- Input state for D-Pad hold detection
    dpad_down_hold_start = 0,
    dpad_down_held = false,
    
    -- Game state detection
    in_cutscene = false,
    cutscene_exit_time = 0,
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

local LOG_FILE_PATH = "jedi_survivor_log.txt"

-- Write to file
local function log_to_file(msg)
    local f = io.open(LOG_FILE_PATH, "a")
    if f then
        f:write(msg .. "\n")
        f:close()
    end
end

-- Flush queued messages
local function log_flush_queue()
    for _, msg in ipairs(log_queue) do
        print(msg)
        log_to_file(msg)
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
            log_to_file(message)
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
        log_to_file(message)
        state.last_log_message = message
    end
end

-- Critical log: ALWAYS prints and writes to file, NEVER suppressed by smart logging.
-- Use for state transitions ([VIEW], [CAMERA], [STATE]) that must appear in logs for debugging.
local function log_critical(...)
    if not config[CONFIG_KEYS.DEBUG_LOGGING] then return end
    
    local message = table.concat({...}, " ")
    print(message)
    log_to_file(message)
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
    elseif new_mode == "MOUNTED_SPAMEL" then
        setCameraOffset(MOUNTED_TALL_ANIMAL_CAMERA.FORWARD, MOUNTED_TALL_ANIMAL_CAMERA.RIGHT, MOUNTED_TALL_ANIMAL_CAMERA.UP)
        log("[CAMERA] Mode: MOUNTED_SPAMEL (forward=" .. MOUNTED_TALL_ANIMAL_CAMERA.FORWARD .. ", up=" .. MOUNTED_TALL_ANIMAL_CAMERA.UP .. ")")
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
    
    -- Check if we are currently playing as Cere
    -- This uses dynamically-updated state (refreshed each frame via IsMarkedPlayingAsCere)
    local is_cere = state.is_cere
    
    -- Helper function to hide/show a mesh component
    local function toggle_mesh(mesh, name)
        if mesh then
            safe_call("toggle_mesh:" .. name, function()
                -- Use both methods for maximum compatibility:
                -- SetHiddenInGame works for Cal's standard components
                -- SetRenderInMainPass works for Cere's named components and BD-1
                if mesh.SetHiddenInGame then
                    mesh:SetHiddenInGame(hidden, false) -- false = do not unhide children like debug spheres
                end
                if mesh.SetRenderInMainPass then
                    mesh:SetRenderInMainPass(visible)
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

    -- Hide Face mesh in 1st person. Cal's Face is specifically bound to pawn.Face.
    safe_call("hide_face", function()
        if pawn.Face then
            local apply_visible = visible
            local apply_hidden = hidden
            
            if is_cere then
                -- Force Cal's face hidden when playing as Cere
                -- (dynamic is_cere detection ensures this resets when switching back to Cal)
                apply_visible = false
                apply_hidden = true
            end
            
            if pawn.Face.SetHiddenInGame then
                pawn.Face:SetHiddenInGame(apply_hidden, false)
            end
            if pawn.Face.SetRenderInMainPass then
                pawn.Face:SetRenderInMainPass(apply_visible)
            end
            
            count = count + 1
            log("[MESH] Face visibility=" .. tostring(apply_visible))
        end
    end)
    -- Hide body cosmetic meshes (Jacket, Shirt) based on config
    -- Note: Arm meshes are part of Jacket/Shirt, so hiding these also hides arms
    -- See README.md for detailed research on mesh hiding approaches tried
    -- Hide body cosmetic meshes based on config
    -- Supports both Cal (anonymous SkeletalMeshComponent_*) and Cere (named components)
    --
    -- Cal: Jacket, Shirt (torso) + Pants, Holster (lower body) + Hair, FacialHair (head)
    -- Cere: Cere_AJK (body), Cere_Hvk (cloak), SkeletalMeshFaceForIKRig (face)
    safe_call("hide_body_meshes", function()
        if not config[CONFIG_KEYS.HIDE_BODY_MESH] then return end
        
        local TORSO_MESH_PATTERNS = {
            "Jacket",           -- Cal: Hero_Poncho_Hvk_ClothMesh (Havok cloth rendered by HavokClothEntityComponent below)
            "Shirt",            -- Cal: Hero_shirtJFOVersionJ (torso)
            "HairAJK",          -- Cal: Hero_hairDefault (head hair)
            "FacialHairAJK",    -- Cal: Hero_facialHairFullBeard (beard)
            "Cere_AJK",         -- Cere: full body mesh
            -- Note: Cere_Hvk cloak is handled separately via UnloadCereClothMesh()
        }
        
        local LOWER_BODY_MESH_PATTERNS = {
            "Pants",            -- Hero_pantsBoxCover (legs)
            "Holster",          -- Hero_holster (on pants)
        }
        
        local SKIP_COMPONENTS = {
            CameraRig = true,
            CharacterMesh0 = true,
            Face = true,
        }
        
        local skeletal_mesh_class = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")
        if not skeletal_mesh_class or not pawn.K2_GetComponentsByClass then return end
        
        local components = pawn:K2_GetComponentsByClass(skeletal_mesh_class)
        if not components then return end
        
        for i, component in pairs(components) do
            safe_call("check_mesh_component", function()
                if not component then return end
                
                local comp_name = component:get_fname():to_string()
                if not comp_name or SKIP_COMPONENTS[comp_name] then return end
                
                local mesh_asset_path = nil
                if component.SkeletalMesh then
                    local mesh = component.SkeletalMesh
                    if mesh then
                        mesh_asset_path = mesh:get_full_name()
                    end
                end
                
                local should_hide = false
                local match_source = mesh_asset_path or comp_name
                
                for _, pattern in ipairs(TORSO_MESH_PATTERNS) do
                    if match_source:find(pattern) then
                        should_hide = true
                        break
                    end
                end
                
                if not should_hide and config[CONFIG_KEYS.HIDE_LOWER_BODY_MESH] then
                    for _, pattern in ipairs(LOWER_BODY_MESH_PATTERNS) do
                        if match_source:find(pattern) then
                            should_hide = true
                            break
                        end
                    end
                end
                local is_cere_mesh = match_source:find("Cere") ~= nil
                
                if should_hide then
                    -- Default visibility based on 1P (false) vs 3P (true)
                    local apply_visible = visible
                    local apply_hidden = hidden
                    
                    -- Always force-hide the inactive character's meshes to prevent T-pose.
                    -- Dynamic is_cere detection (refreshed each frame) ensures correct 
                    -- character identity even after gameplay transitions.
                    if is_cere_mesh and not is_cere then
                        -- Cal is active: FORCE Cere's meshes hidden even in 3P
                        apply_visible = false
                        apply_hidden = true
                    elseif not is_cere_mesh and is_cere then
                        -- Cere is active: FORCE Cal's meshes hidden even in 3P
                        apply_visible = false
                        apply_hidden = true
                    end
                    
                    if component.SetHiddenInGame then
                        component:SetHiddenInGame(apply_hidden, false) -- false = do not unhide children like debug spheres
                    end
                    if component.SetRenderInMainPass then
                        component:SetRenderInMainPass(apply_visible)
                    end
                    count = count + 1
                    log("[MESH] " .. (mesh_asset_path or comp_name) .. " visibility=" .. tostring(apply_visible))
                end
            end)
        end
    end)
    
    -- Hide Cere's face mesh (separate named component from Cal's pawn.Face)
    safe_call("hide_cere_face", function()
        local skeletal_mesh_class = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")
        if not skeletal_mesh_class or not pawn.K2_GetComponentsByClass then return end
        
        local components = pawn:K2_GetComponentsByClass(skeletal_mesh_class)
        if not components then return end
        
        for i, component in pairs(components) do
            safe_call("check_cere_face", function()
                local comp_name = component:get_fname():to_string()
                if comp_name == "SkeletalMeshFaceForIKRig" then
                    local apply_visible = visible
                    local apply_hidden = hidden
                    
                    -- Force hide Cere's face when playing as Cal
                    if not is_cere then
                        apply_visible = false
                        apply_hidden = true
                    end
                    
                    if component.SetHiddenInGame then
                        component:SetHiddenInGame(apply_hidden, false)
                    end
                    if component.SetRenderInMainPass then
                        component:SetRenderInMainPass(apply_visible)
                    end
                    count = count + 1
                    log("[MESH] Cere face (" .. comp_name .. ") visibility=" .. tostring(apply_visible))
                end
            end)
        end
    end)
    
    -- Handle Cere's Havok cloth cloak separately via game's built-in functions.
    -- Standard visibility methods (SetHiddenInGame, SetVisibility, SetRenderInMainPass)
    -- don't work on this mesh because it uses UHavokClothAsset for cloth simulation,
    -- which bypasses UE's rendering visibility flags.
    -- BP_Hero_C provides LoadCereClothMesh() / UnloadCereClothMesh() for this purpose.
    safe_call("toggle_cere_cloak", function()
        -- Force hide Cere's cloak when playing as Cal
        local apply_visible = visible
        if not is_cere then
            apply_visible = false
        end
        
        if apply_visible then
            if pawn.LoadCereClothMesh then
                pawn:LoadCereClothMesh()
                log("[MESH] Cere cloak loaded (LoadCereClothMesh)")
                count = count + 1
            end
        else
            if pawn.UnloadCereClothMesh then
                pawn:UnloadCereClothMesh()
                log("[MESH] Cere cloak unloaded (UnloadCereClothMesh)")
                count = count + 1
            end
        end
    end)
    
    -- Handle Cal's Havok cloth poncho via HavokClothEntityComponent.
    -- Unlike standard SkeletalMeshComponents, Havok cloth rendering is controlled by
    -- HavokClothEntityComponent (inherits UMeshComponent). The SkeletalMeshComponent
    -- (Hero_Poncho_Hvk_ClothMesh) is just the mesh data — SetHiddenInGame on it has
    -- NO effect because HavokClothEntityComponent drives the actual cloth rendering.
    -- Use the dedicated SetClothVisibility() API on HavokClothEntityComponent instead.
    -- Note: Cere's Havok cloak is handled separately above via Load/UnloadCereClothMesh,
    -- which creates/destroys the HavokClothEntityComponent entirely.
    -- We only run this when playing as Cal — when Cere is active, her cloak lifecycle
    -- is already managed, and Cal's poncho should not be spawned by the customization system.
    safe_call("toggle_havok_cloth_entities", function()
        if not config[CONFIG_KEYS.HIDE_BODY_MESH] then return end
        if is_cere then return end  -- Cere's cloak handled by Load/Unload above
        
        local havok_cloth_class = api:find_uobject("Class /Script/HavokCloth.HavokClothEntityComponent")
        if not havok_cloth_class or not pawn.K2_GetComponentsByClass then return end
        
        local havok_components = pawn:K2_GetComponentsByClass(havok_cloth_class)
        if not havok_components then return end
        
        for i, havok_component in pairs(havok_components) do
            safe_call("toggle_havok_cloth_item", function()
                if not havok_component then return end
                
                -- Use SetClothVisibility on each cloth item within this component.
                -- This is the dedicated Havok Cloth API that properly controls
                -- cloth rendering, unlike SetHiddenInGame which only affects standard meshes.
                local num_cloth_items = 0
                if havok_component.GetNumClothItems then
                    num_cloth_items = havok_component:GetNumClothItems()
                end
                
                for cloth_index = 0, num_cloth_items - 1 do
                    if havok_component.SetClothVisibility then
                        havok_component:SetClothVisibility(cloth_index, 0, visible)
                    end
                end
                
                -- Also set standard visibility flags on the HavokClothEntityComponent
                -- itself (it inherits from UMeshComponent, so these may also take effect).
                if havok_component.SetHiddenInGame then
                    havok_component:SetHiddenInGame(hidden, false)
                end
                if havok_component.SetRenderInMainPass then
                    havok_component:SetRenderInMainPass(visible)
                end
                
                count = count + 1
                log("[MESH] HavokClothEntity cloth_items=" .. num_cloth_items .. " visibility=" .. tostring(visible))
            end)
        end
    end)
    
    if count > 0 then
        log_critical("[MESH] Toggled " .. count .. " mesh(es)/bone(s), visible=" .. tostring(visible))
    else
        log_critical("[MESH] No meshes found to toggle")
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
            log_critical("[CAMERA] Blocked 1P switch - active 3P state:", active_reason)
            return
        end
    end
    
    log_critical("[CAMERA] Switching to First-Person View (Reason:", reason or "manual", ")")
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
    
    log_critical("[CAMERA] Switching to Third-Person View (Reason:", reason or "manual", ")")
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
-- Uses multiple methods since no single approach is fully reliable.
-- Methods verified against SDK dumps in JediSurvivor 2/sdkdump/.
is_in_cutscene = function(hero)
    if not hero then return false end
    
    -- If game is paused (menu open), it's NOT a cutscene - no zoom allowed
    if state.gameplay_statics and state.cached_world then
        local is_paused = state.gameplay_statics:IsGamePaused(state.cached_world)
        if is_paused then return false end
    end
    
    local block_input = false
    local cinematic_mode = false
    local view_target_changed = false
    local detection_reasons = {}
    
    -- Method 1: Check player controller flags (verified in SDK: APlayerController)
    local ctrl = api:get_player_controller()
    if ctrl then
        if ctrl.bBlockInput then
            block_input = true
            table.insert(detection_reasons, "bBlockInput")
        end
        if ctrl.bCinematicMode then
            cinematic_mode = true
            table.insert(detection_reasons, "bCinematicMode")
        end
    end
    
    -- Method 2: Check if camera ViewTarget is not the hero (cinematic cameras)
    local pawn = api:get_local_pawn()
    if pawn and pawn.Controller then
        local camera_mgr = pawn.Controller.PlayerCameraManager
        if camera_mgr and camera_mgr.ViewTarget and camera_mgr.ViewTarget.Target then
            if camera_mgr.ViewTarget.Target ~= pawn then
                view_target_changed = true
            end
        end
    end
    
    -- Method 3: Check for Context-Sensitive (CS_) cinematic montages
    -- The game engine drops bCinematicMode during interactive clashes, but they are absolutely cutscenes
    local cs_montage_playing = false
    safe_call("is_in_cutscene:CSMontage", function()
        if hero.GetCurrentMontage then
            local montage = hero:GetCurrentMontage()
            if montage then
                local montage_name = montage:get_fname():to_string()
                if montage_name and montage_name:find("CS_") then
                    cs_montage_playing = true
                    table.insert(detection_reasons, "CS_montage:" .. montage_name)
                end
            end
        end
    end)
    
    -- Method 4: NavState 19 = Cinematic (authoritative)
    -- SDK: ERsNavState::Cinematic = 19 (verified in RsGameTechRT_structs.hpp)
    -- Same approach as Fallen Order (NavState 20 = CINEMATIC there)
    local is_cinematic_nav_state = false
    safe_call("is_in_cutscene:NavState", function()
        if hero.GetCurrentNavState then
            local nav_state = hero:GetCurrentNavState()
            if nav_state == NAV_STATES.CINEMATIC.id then
                is_cinematic_nav_state = true
                table.insert(detection_reasons, "NavState19(Cinematic)")
            end
        end
    end)
    
    -- Method 5: CinematicBlendInterp - DIAGNOSTIC ONLY (not authoritative)
    -- Resting value is 1.0 during normal gameplay after cutscenes (confirmed in testing),
    -- so it CANNOT be used as a standalone authoritative signal — causes permanent 3P.
    -- SDK: RsCharacter.CinematicBlendInterp (float, Interp) - verified in sdkdump
    safe_call("is_in_cutscene:CinematicBlend", function()
        if hero.CinematicBlendInterp then
            local blend_value = hero.CinematicBlendInterp
            if blend_value and blend_value > 0 then
                table.insert(detection_reasons, "CinematicBlend(diag):" .. string.format("%.2f", blend_value))
            end
        end
    end)
    
    -- Authoritative methods: if any is true, it's a cutscene
    -- bBlockInput, bCinematicMode, CS_ montage, NavState 19 (Cinematic) are core signals.
    local authoritative = block_input or cinematic_mode or cs_montage_playing or is_cinematic_nav_state
    
    -- ViewTarget alone is not enough - also triggers in menus
    -- ViewTarget only counts if at least one other method is also true OR if in interaction.
    -- We use a "sticky" flag so menus don't trigger it, but once an interaction natively
    -- starts a cutscene, we hold onto it even if the interaction debounce timer finishes early.
    if view_target_changed then
        if authoritative or state.is_interacting then
            state.view_target_cutscene_active = true
            table.insert(detection_reasons, "ViewTarget(sticky)")
        end
    else
        state.view_target_cutscene_active = false
    end
    
    local is_cutscene = authoritative or state.view_target_cutscene_active
    
    -- Log detection details on transitions (not every frame)
    if is_cutscene and not state.in_cutscene then
        log_critical("[CUTSCENE] Detected via:", table.concat(detection_reasons, ", "))
    end
    
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
       nav_state == NAV_STATES.MONKEY_BEAM.id or
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
        safe_call("is_in_combat:CheckMontage", function()
            if hero.GetCurrentMontage then
                local montage = hero:GetCurrentMontage()
                if montage then
                    local montage_name = montage:get_fname():to_string()
                    local full_name = montage:get_full_name() or ""
                    
                    -- Combat montage patterns:
                    -- ATT_ = Attack montages (lightsaber swings)
                    -- ForcePush, ForcePull, ForceSlow = Force power montages
                    -- But NOT Sheathe (hero_ATT_Sheathe_Stand_Montage)
                    
                    if montage_name and not montage_name:find("Sheathe") then
                        if montage_name:find("ATT_") then
                            in_combat = true
                        end
                    end
                end
            end
        end)
    end
    
    -- Method 4: Check if executing actions (stops 2-second timeout from dropping mid-clash)
    if not in_combat then
        safe_call("is_in_combat:ExecutingActions", function()
            if hero.IsExecutingActions and hero:IsExecutingActions() then
                in_combat = true
            elseif hero.IsExecutingBufferedAction and hero:IsExecutingBufferedAction() then
                in_combat = true
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

-- Only decides what the zoom offset should be (returns 0 if not active)
local function get_cinematic_zoom_offset()
    if not config[CONFIG_KEYS.ENABLE_CINEMATIC_ZOOM] or not state.in_cutscene then
        -- Reset tracker if we dropped out of cutscene
        if not state.in_cutscene then
            state.zoom_level = 0
        end
        return 0
    end
    return state.zoom_level * CINEMATIC_ZOOM.OFFSET_PER_LEVEL
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
            
            -- Reset active_mode so Phase 4 re-evaluates camera offsets next frame.
            -- Without this, active_mode stays "2D_MODE" and Phase 4 is entirely skipped,
            -- preventing mounted/normal camera offsets from being reapplied.
            camera_offset.active_mode = "NONE"
            
            -- Camera offsets will be restored by Phase 4 next frame
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
        
        -- Reset active_mode so Phase 4 re-evaluates camera offsets next frame.
        camera_offset.active_mode = "NONE"
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
        state.cutscene_exit_time = 0
        return 
    end
    
    local was_in_cutscene = state.in_cutscene
    local now_in_cutscene = is_in_cutscene(hero)
    local now = os.clock()
    
    if now_in_cutscene and not was_in_cutscene then
        -- Just entered cutscene - set flag only
        log_critical("[STATE] Entered cutscene")
        state.in_cutscene = true
        state.cutscene_exit_time = 0
    elseif not now_in_cutscene and was_in_cutscene then
        -- Cutscene ended - handle debounce
        if state.cutscene_exit_time == 0 then
            state.cutscene_exit_time = now
            log_critical("[STATE] Cutscene ended - starting debounce")
        elseif (now - state.cutscene_exit_time) >= TIMING.CUTSCENE_DEBOUNCE_TIME then
            -- Debounce passed - clear flag
            log_critical("[STATE] Cutscene debounce complete")
            state.in_cutscene = false
            state.cutscene_exit_time = 0
        end
    elseif now_in_cutscene then
        -- Still in cutscene - reset debounce
        state.cutscene_exit_time = 0
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
        log_critical("[STATE] Entered combat")
        state.is_in_combat = true
        state.combat_exit_time = 0
    elseif not now_in_combat and was_in_combat then
        -- Combat ended - handle debounce
        -- Saber still drawn extends the debounce
        
        if state.saber_is_active then
            state.combat_exit_time = now
            log_simple("[STATE] Combat paused but saber still drawn")
        elseif state.combat_exit_time == 0 then
            state.combat_exit_time = now
            log_critical("[STATE] Combat ended - starting debounce")
        elseif (now - state.combat_exit_time) >= TIMING.COMBAT_DEBOUNCE_TIME then
            -- Debounce passed - clear flag
            log_critical("[STATE] Combat debounce complete")
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

-- Determines what mounted state the player is in (returns "NONE", "MOUNTED", etc)
local function get_mounted_state(hero)
    if not hero then return "NONE" end
    
    -- Check if mounted (NavState 30, 32, 33, 34, 52 are all mounted-related)
    local nav_state = 0
    safe_call("get_mounted_state", function()
        if hero.GetCurrentNavState then
            nav_state = hero:GetCurrentNavState()
        end
    end)
    
    -- Check for Nekko-type mount (NavState 30, 32, 33, 34)
    local is_nekko_mounted = (nav_state == NAV_STATES.MOUNTED_GROUND.id or
                              nav_state == NAV_STATES.MOUNTED_PRE_JUMP.id or
                              nav_state == NAV_STATES.MOUNTED_JUMP.id or
                              nav_state == NAV_STATES.MOUNTED_FALL.id)
    
    -- Check for Spamel mount (NavState 52)
    local is_mount_spamel = (nav_state == NAV_STATES.MOUNTED_SPAMEL_GROUND.id)

    if is_nekko_mounted then return "MOUNTED" end
    if is_mount_spamel then return "MOUNTED_SPAMEL" end
    
    return "NONE"
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
    
    -- Track pawn changes to reset state
    -- Must use address because UEVR can return different Lua wrapper objects for the same pawn
    local current_pawn_address = hero:get_address()
    if state.cached_pawn_address ~= current_pawn_address then
        state.cached_pawn_address = current_pawn_address
        state.is_cere = false           -- Default to false (Cal) on pawn swap
        state.native_cere_flag_confirmed = false -- Reset native flag tracking
        state.cere_cloak_should_be_visible = false -- Reset cloak tracking
        state.meshes_initialized = false -- Re-evaluate meshes for the new pawn
        log("[STATE] New pawn detected - resetting character identity")
    end
    
    -- Dynamic character identity detection - checked EVERY FRAME, never latched.
    -- The hero pawn can switch between Cal and Cere during gameplay (e.g. Vader fight
    -- transitions to ship cutscene). A permanent latch caused Cere's T-pose body mesh
    -- to remain visible after transitioning back to Cal.
    safe_call("update_character_identity", function()
        local detected_cere = false
        
        -- Method 1: Authoritative native flag (primary, trusted in both directions)
        -- IsMarkedPlayingAsCere() returns the C++ gameplay state directly.
        if hero.IsMarkedPlayingAsCere then
            detected_cere = hero:IsMarkedPlayingAsCere()
            if detected_cere then
                state.native_cere_flag_confirmed = true
            end
        end
        
        -- Method 2: Fallback via CUTSCENE montage naming (supplementary positive signal)
        -- Only used BEFORE IsMarkedPlayingAsCere has ever returned true for this pawn.
        -- Once the native flag has been confirmed initialized (returned true at least once),
        -- we trust it exclusively. This prevents oscillation caused by residual Cere_*
        -- montages still playing after the game has genuinely transitioned back to Cal.
        --
        -- IMPORTANT: Only match Cere_CS_ (cutscene) montages, NOT Cere_ATT_ (attack).
        -- The game reuses Cere's attack animation montages (Cere_ATT_Saber_*) on Cal's
        -- pawn even when Cere is dead/absent (recycled animation assets). Only cutscene
        -- montages reliably indicate you're actually playing as Cere.
        if not detected_cere and not state.native_cere_flag_confirmed and hero.GetCurrentMontage then
            local montage = hero:GetCurrentMontage()
            if montage then
                local montage_name = montage:get_fname():to_string()
                if montage_name and montage_name:find("^Cere_CS_") then
                    detected_cere = true
                    log("[STATE] Cere identity inferred from cutscene montage: " .. montage_name)
                end
            end
        end
        
        -- Note: Method 3 (SkeletalMeshFaceForIKRig component presence) was REMOVED.
        -- That component is always present on the hero pawn regardless of active character,
        -- so it caused a permanent false-positive latch that prevented switching back to Cal.
        
        if detected_cere ~= state.is_cere then
            state.is_cere = detected_cere
            local character_name = detected_cere and "CERE" or "CAL"
            log_critical("[STATE] Character identity changed to " .. character_name)
            
            -- Immediately correct mesh visibility for the new character identity
            if state.meshes_initialized then
                log_critical("[STATE] Correcting mesh visibility for " .. character_name)
                set_player_mesh_visibility(hero, not state.is_first_person)
            end
        end
    end)
    
    -- Initialize meshes on first frame when pawn becomes available
    if not state.meshes_initialized then
        state.meshes_initialized = true
        
        -- One-time dump of ALL skeletal mesh components for debugging visibility issues
        safe_call("dump_all_mesh_components", function()
            local skeletal_mesh_class = api:find_uobject("Class /Script/Engine.SkeletalMeshComponent")
            if skeletal_mesh_class and hero.K2_GetComponentsByClass then
                local components = hero:K2_GetComponentsByClass(skeletal_mesh_class)
                if components then
                    log_critical("[MESH DUMP] === All SkeletalMeshComponents on pawn ===")
                    for i, component in pairs(components) do
                        if component then
                            local comp_name = component:get_fname():to_string()
                            local asset_path = "N/A"
                            pcall(function()
                                if component.SkeletalMesh then
                                    local mesh = component.SkeletalMesh
                                    if mesh then
                                        asset_path = mesh:get_full_name()
                                    end
                                end
                            end)
                            log_critical("[MESH DUMP] [" .. i .. "] name=" .. (comp_name or "nil") .. " asset=" .. asset_path)
                        end
                    end
                    log_critical("[MESH DUMP] === End dump ===")
                end
            end
        end)
        
        if state.is_first_person then
            log("[MESH] First frame - hiding meshes for 1st person")
            set_player_mesh_visibility(hero, false)
        end
    end
    
    -- Track Cere's Havok cloth cloak desired state.
    -- Unlike standard meshes (which persist via SetHiddenInGame), the Havok cloth
    -- cloak can only be controlled via LoadCereClothMesh() / UnloadCereClothMesh().
    -- Only call these expensive functions when the desired state CHANGES.
    local desired_cloak_visible = not state.is_first_person and state.is_cere
    if desired_cloak_visible ~= state.cere_cloak_should_be_visible then
        state.cere_cloak_should_be_visible = desired_cloak_visible
        safe_call("update_cloak_state", function()
            if desired_cloak_visible then
                if hero.LoadCereClothMesh then
                    hero:LoadCereClothMesh()
                    log_critical("[MESH] Cere cloak loaded (state change)")
                end
            else
                if hero.UnloadCereClothMesh then
                    hero:UnloadCereClothMesh()
                    log_critical("[MESH] Cere cloak unloaded (state change)")
                end
            end
        end)
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
        log_critical("[VIEW] Switching to 3P - reason: " .. (reason or "unknown"))
        set_third_person_view(reason)
    elseif not should_3p and not state.is_first_person then
        -- Need to switch to 1P
        log_critical("[VIEW] Switching to 1P - no active 3P states")
        set_first_person_view("no active 3P states", hero, true)  -- force=true since we already checked
    end
    
    -- ========================================
    -- PHASE 4: Camera offset management
    -- ========================================
    -- This is the single source of truth for applying camera offsets.
    -- Wait until map/meditation active modes are complete before reapplying offsets
    if camera_offset.active_mode ~= "2D_MODE" then
        if not state.is_first_person then
            -- 3P is active. Offsets default to 0,0,0 UNLESS in a cutscene with zoom.
            -- Cinematic zoom applies a forward offset during cutscenes to let the user
            -- adjust viewing distance even while in 3P (VR camera offset still works).
            if state.in_cutscene and config[CONFIG_KEYS.ENABLE_CINEMATIC_ZOOM] then
                local zoom_offset = get_cinematic_zoom_offset()
                set_camera_mode("CUTSCENE", zoom_offset)
            else
                setCameraOffset(0, 0, 0)
                camera_offset.active_mode = "THIRD_PERSON"
                -- Reset zoom tracker when leaving cutscene in 3P
                state.zoom_level = 0
            end
        else
            -- 1P is active. Check priorities: Mounted -> Cutscene Zoom -> Normal
            local mount_state = get_mounted_state(hero)
            if mount_state ~= "NONE" then
                set_camera_mode(mount_state)
            elseif state.in_cutscene and config[CONFIG_KEYS.ENABLE_CINEMATIC_ZOOM] then
                local zoom_offset = get_cinematic_zoom_offset()
                set_camera_mode("CUTSCENE", zoom_offset)
            else
                -- Not mounted, not in cutscene (or zoom disabled) -> normal 1P offsets
                set_camera_mode("NORMAL")
                
                -- Reset zoom tracker when not in cutscene
                state.zoom_level = 0
            end
        end
    end
    
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
    -- if not IS_PRODUCTION then
    --     if imgui.button("Dump Hero State##dump", 200, 0) then
    --         local pawn = api:get_local_pawn(0)
    --         if pawn then
    --             print("[DEBUG] Dumping hero state...")
    --             if debugModule then
    --                 debugModule.clearDumpFile()
    --                 debugModule.dump(pawn, false, nil, true)
    --             end
    --             print("[DEBUG] Dump complete - check data/dump_output.txt")
    --         else
    --             print("[DEBUG] No pawn found")
    --         end
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
    -- Clear log file on every script load/reset for a fresh debugging session
    local log_clear_file = io.open(LOG_FILE_PATH, "w")
    if log_clear_file then
        log_clear_file:close()
    end
    
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
