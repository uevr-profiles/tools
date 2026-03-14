local api = uevr.api
local frame_counter = 0

-- This will hide every xxNiagaraComponent (add more unique parts if you want to be more selective)
local SPELL_EFFECT_KEYWORDS = {
    "xxNiagaraComponent"
}

local function is_spell_effect(name)
    for _, keyword in ipairs(SPELL_EFFECT_KEYWORDS) do
        if string.find(name, keyword) then
            return true
        end
    end
    return false
end

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    frame_counter = frame_counter + 1
    if frame_counter % 300 ~= 0 then return end  -- Every ~1 second

    local NiagaraClass = api:find_uobject("Class /Script/Niagara.NiagaraComponent")
    if NiagaraClass ~= nil then
        local all_components = NiagaraClass:get_objects_matching(false)
        for _, comp in ipairs(all_components) do
            local name = comp:get_full_name()
            if is_spell_effect(name) then
                pcall(function() comp:SetVisibility(false) end)
                pcall(function() comp:SetHiddenInGame(true) end)
                pcall(function() comp:SetRenderInMainPass(false) end)
            end
        end
    end
end)
