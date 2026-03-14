---@diagnostic disable: undefined-global, undefined-field

UEVR_UObjectHook.activate()

local api       = uevr.api
local callbacks = uevr.sdk.callbacks

------------------------------------------
-- User tuning
------------------------------------------
local TRIGGER_THRESHOLD = 15
local THROW_BLOCK_TIME  = 0.25 -- seconds ADS stays blocked after holding item ends

local adsLocked         = false
local throwCooldown     = 0.0


------------------------------------------
-- Helpers
------------------------------------------
local function getPawn()
    local pcClass = api:find_uobject("Class /Script/Engine.PlayerController")
    if not pcClass then return nil end
    local list = pcClass:as_class():get_objects_matching(false)
    if not list then return nil end
    for _, pc in ipairs(list) do
        local ok, pawn = pcall(function()
            return pc:get_property("AcknowledgedPawn")
        end)
        if ok and pawn then return pawn end
    end
    return nil
end


local function applyADS(state)
    local pawn = getPawn()
    if not pawn then return end
    pcall(function() pawn:set_property("ADSButtonPressed", state) end)
    pcall(function() pawn:set_property("ADSEnabled",      state) end)
end


local function getIsHolding()
    local pawn = getPawn()
    if not pawn then return false end
    local ok, val = pcall(function()
        return pawn:get_property("IsHoldingItem")
    end)
    if ok and val ~= nil then return val end
    return false
end


------------------------------------------
-- Input Detection
------------------------------------------
callbacks.on_xinput_get_state(function(retval, idx, state)
    if not state or not state.Gamepad then return end

    local gp      = state.Gamepad
    local buttons = gp.wButtons or 0
    local rt      = gp.bRightTrigger or 0
    local lt      = gp.bLeftTrigger  or 0

    local pawnHolding = getIsHolding()

    ----------------------------------------------------
    -- If holding item → ADS disabled + cooldown
    ----------------------------------------------------
    if pawnHolding == true then
        adsLocked     = false
        throwCooldown = THROW_BLOCK_TIME
        applyADS(false)
        return
    end

    ----------------------------------------------------
    -- Cooldown prevents re-engage
    ----------------------------------------------------
    if throwCooldown > 0 then
        adsLocked = false
        applyADS(false)
        return
    end

    ----------------------------------------------------
    -- Engage ADS on press (first-shot safe)
    ----------------------------------------------------
    if rt > TRIGGER_THRESHOLD and not adsLocked then
        adsLocked = true
        applyADS(true)  -- immediate, guarantees first-shot ADS
    end

    ----------------------------------------------------
    -- Cancel ADS on specific buttons
    ----------------------------------------------------
    local cancel =
           (lt > 10)
        or ((buttons & 0x0100) ~= 0)   -- Left Grip
        or ((buttons & 0x1000) ~= 0)   -- A button
        or ((buttons & 0x0040) ~= 0)   -- LStick Click
        or ((buttons & 0x0080) ~= 0)   -- RStick Click
        or ((buttons & 0x0004) ~= 0)   -- DPAD Down
        or ((buttons & 0x0002) ~= 0)   -- DPAD Right
        or ((buttons & 0x0008) ~= 0)   -- DPAD Left
        or ((buttons & 0x0010) ~= 0)   -- Start
        or ((buttons & 0x0020) ~= 0)   -- Back/Menu

    if cancel then
        adsLocked = false
        applyADS(false)
        return
    end
end)


------------------------------------------
-- Tick enforcement
------------------------------------------
callbacks.on_post_engine_tick(function(engine, dt)
    if type(dt) ~= "number" then dt = 0.016 end

    if throwCooldown > 0 then
        throwCooldown = throwCooldown - dt
        if throwCooldown < 0 then throwCooldown = 0 end
    end

    applyADS(adsLocked)
end)
