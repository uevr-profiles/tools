UEVR_UObjectHook.activate()

local api = uevr.api
local callbacks = uevr.sdk.callbacks

local ATHENA_CLASS = "BlueprintGeneratedClass /Game/NPCManager/Blueprints/Characters/NPC/Talos2/Pyramid/BP_NPC_Athena.BP_NPC_Athena_C"
local ATHENA_PACKAGE = "/Game/NPCManager/Blueprints/Characters/NPC/Talos2/Pyramid/BP_NPC_Athena"

local total_time = 0.0
local next_try = 3.0

callbacks.on_pre_engine_tick(function(engine, delta)
    total_time = total_time + delta

    if total_time < next_try then
        return
    end

    next_try = total_time + 1.5

    local athena_class = api:find_uobject(ATHENA_CLASS)

    if athena_class ~= nil then
        print("[AthenaResidentLua] Athena class is resident")
        return
    end

    print("[AthenaResidentLua] nudging package load")
    api:execute_command("LoadPackage " .. ATHENA_PACKAGE)
end)