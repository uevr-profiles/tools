local vr  = uevr.params.vr
local api = uevr.api
local cb  = uevr.sdk.callbacks

-- =========================
-- CONFIG
-- =========================
-- Nur rechter Controller
local PULSE_DURATION  = 0.05
local PULSE_FREQUENCY = 135.0
local PULSE_AMPLITUDE = 0.90
local MIN_INTERVAL_MS = 80   -- Fullauto: verhindert Dauerbrummen

-- =========================
-- STATE
-- =========================
local last_pulse_ms = 0
local last_weapon   = nil
local last_ammo     = nil

local function now_ms()
    return math.floor(os.clock() * 1000.0)
end

local function rumble_right()
    if not vr.is_runtime_ready() then return end
    local src = vr.get_right_joystick_source()
    if src == nil or src == 0 then return end
    pcall(function()
        vr.trigger_haptic_vibration(0.0, PULSE_DURATION, PULSE_FREQUENCY, PULSE_AMPLITUDE, src)
    end)
end

-- Pfad: PlayerState -> WeaponInventory -> EquippedWeapon -> AmmoAmount
local function get_playerstate()
    local pawn = api:get_local_pawn(0)
    if pawn and pawn["PlayerState"] then return pawn["PlayerState"] end

    local pc = api:get_player_controller(0)
    if pc and pc["PlayerState"] then return pc["PlayerState"] end

    return nil
end

cb.on_pre_engine_tick(function(engine, dt)
    local ps, inv, weap, ammo

    local ok = pcall(function()
        ps   = get_playerstate()
        inv  = ps and ps["WeaponInventory"] or nil
        weap = inv and inv["EquippedWeapon"] or nil
        ammo = weap and weap["AmmoAmount"] or nil
    end)

    if not ok or weap == nil or ammo == nil then
        last_weapon = nil
        last_ammo   = nil
        return
    end

    -- Waffenwechsel -> Reset
    if last_weapon ~= nil and weap ~= last_weapon then
        last_ammo = ammo
    end
    last_weapon = weap

    -- Schuss: Ammo sinkt
    if last_ammo ~= nil and ammo < last_ammo then
        local t = now_ms()
        if (t - last_pulse_ms) >= MIN_INTERVAL_MS then
            rumble_right()
            last_pulse_ms = t
        end
    end

    last_ammo = ammo
end)