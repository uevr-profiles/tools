-- Force bUseControllerRotationYaw = true 

local api = uevr.api
local callbacks = uevr.params.sdk.callbacks

local applied_for_this_pawn = false

callbacks.on_pre_engine_tick(function(engine, delta)
    local pawn = api:get_local_pawn(0)

    -- If we're in menus / pawn not spawned yet, reset state so it reapplies later
    if pawn == nil then
        applied_for_this_pawn = false
        return
    end

    -- Apply once per pawn spawn 
    local ok = pcall(function()
        if pawn.bUseControllerRotationYaw ~= true then
            pawn.bUseControllerRotationYaw = true
        end
    end)

    if ok and not applied_for_this_pawn then
        print("[UEVR] bUseControllerRotationYaw forced ON for local pawn")
        applied_for_this_pawn = true
    end
end)
