UEVR_UObjectHook.activate()

local api       = uevr.api
local callbacks = uevr.sdk.callbacks

local pawnClass = api:find_uobject("Class /Script/Engine.Pawn")

-- Fade state
local hudAlpha       = 0.0   -- current opacity (0–1)
local hudTargetAlpha = 0.0   -- desired opacity (0–1)
local FADE_SPEED     = 4.5   -- higher = faster fade

----------------------------------------------------------------
-- Apply HUD visibility + opacity (same pattern as your script)
----------------------------------------------------------------
local function applyHUD(alpha)
    if not pawnClass then return end

    local cls = pawnClass:as_class()
    if not cls then return end

    local pawns = cls:get_objects_matching(false)
    if not pawns then return end

    local visible = alpha > 0.02            -- tiny cutoff
    local vis     = visible and 0 or 1      -- 0 = visible, 1 = invisible

    for _, pawn in ipairs(pawns) do

        -- Main HUD
        local okHUD, hudWidget = pcall(function()
            return pawn:get_property("HUD")
        end)
        if okHUD and hudWidget then
            pcall(function()
                hudWidget:call("SetVisibility", vis)
                hudWidget:call("SetRenderOpacity", alpha)
            end)
        end

        -- HUD Respawn
        local okResp, respawnWidget = pcall(function()
            return pawn:get_property("HUD Respawn")
        end)
        if okResp and respawnWidget then
            pcall(function()
                respawnWidget:call("SetVisibility", vis)
                respawnWidget:call("SetRenderOpacity", alpha)
            end)
        end
    end
end

----------------------------------------------------------------
-- XInput: hold Y to set fade target
----------------------------------------------------------------
callbacks.on_xinput_get_state(function(retval, user_index, state)
    if not state or not state.Gamepad then return end

    local buttons = state.Gamepad.wButtons or 0

    -- Use the exact detection that worked for you before
    local yHeld = (buttons % (XINPUT_GAMEPAD_Y * 2)) >= XINPUT_GAMEPAD_Y

    hudTargetAlpha = yHeld and 1.0 or 0.0
end)

----------------------------------------------------------------
-- Per-tick fade + enforcement (like your safety callback)
----------------------------------------------------------------
callbacks.on_post_engine_tick(function(engine, dt)
    -- dt can come in as non-number sometimes; guard it
    if type(dt) ~= "number" then
        dt = 0.016
    end

    -- Ease alpha toward target
    local diff = hudTargetAlpha - hudAlpha
    if math.abs(diff) > 0.0005 then
        hudAlpha = hudAlpha + diff * FADE_SPEED * dt
        if hudAlpha < 0 then hudAlpha = 0 end
        if hudAlpha > 1 then hudAlpha = 1 end
    end

    -- This replaces the old safety applyHUD(...) call
    applyHUD(hudAlpha)
end)
