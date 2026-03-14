---@diagnostic disable: undefined-global, undefined-field
UEVR_UObjectHook.activate()

local api       = uevr.api
local callbacks = uevr.sdk.callbacks

-- Cache last pawn just for debug / sanity
local last_pawn = nil

-- Resolve the current player pawn in the simplest / most robust way
local function get_player_pawn()
    local pawn = nil

    -- Preferred: UEVR's own helper
    local ok, result = pcall(function()
        return api:get_local_pawn()
    end)

    if ok and result then
        pawn = result
    end

    -- If that ever fails, just return nil rather than guessing
    return pawn
end

callbacks.on_post_engine_tick(function()
    local pawn = get_player_pawn()
    if not pawn then
        return
    end

    -- Detect respawn or pawn swap
    if pawn ~= last_pawn then
        print("[PLAYER_FLAGS] New pawn detected (respawn / level change)")
        last_pawn = pawn
    end

    -- Re-apply flags every tick so they survive death, cutscenes, etc.
    pcall(function() pawn:set_property("UnlimitedStamina", true) end)
end)
