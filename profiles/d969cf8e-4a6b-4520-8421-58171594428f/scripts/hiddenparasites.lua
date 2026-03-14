local api = uevr.api
local uevrUtils = require("libs/uevr_utils")

local hiddenParasites = {}
local CHECK_INTERVAL = 1.0
local lastCheckTime = 0

local function findAndHideParasites()
    print("[ParasiteHider] Checking...")
    
    local pawn = api:get_local_pawn()
    if not pawn then 
        print("[ParasiteHider] No pawn")
        return 
    end
    
    print("[ParasiteHider] Pawn found: " .. pawn:get_full_name())
    
    local children = pawn.Children
    if not children then 
        print("[ParasiteHider] No Children property")
        
        -- Try OwnedComponents instead
        local owned = pawn.OwnedComponents
        if owned then
            print("[ParasiteHider] Trying OwnedComponents...")
            for i, comp in ipairs(owned) do
                if comp then
                    local name = comp:get_full_name()
                    if name:find("Parasite") then
                        print("[ParasiteHider] Found: " .. name)
                        local owner = comp:GetOwner()
                        if owner and owner ~= pawn then
                            owner:SetActorHiddenInGame(true)
                            print("[ParasiteHider] Hidden actor")
                        end
                    end
                end
            end
        end
        return 
    end
    
    print("[ParasiteHider] Children found, iterating...")
    for i, childActor in ipairs(children) do
        if childActor then
            local name = childActor:get_full_name()
            print("[ParasiteHider] Child: " .. name)
            if name:find("Parasite") then
                childActor:SetActorHiddenInGame(true)
                print("[ParasiteHider] Hidden: " .. name)
            end
        end
    end
end

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    lastCheckTime = lastCheckTime + delta
    if lastCheckTime < CHECK_INTERVAL then return end
    lastCheckTime = 0
    findAndHideParasites()
end)

print("[ParasiteHider] Loaded - using on_pre_engine_tick")