local api = uevr.api
local vr = uevr.params.vr

local function disable_object_hooks(state)
    if state ~= obj_hook_disabled then
        obj_hook_disabled = state
        UEVR_UObjectHook.set_disabled(state)
    end
end

-- run this every engine tick, *after* the world has been updated
uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)   	    
    local game_engine       = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
    local player            = uevr.api:get_player_controller(0)
    if player then               
        local currentVT = player:GetViewTarget()                
        if prevViewTarget ~= currentVT then                        
            local view_target = currentVT:get_full_name()
            print(view_target)            

            local objClass = currentVT:get_class()
            print(objClass:get_full_name())

            local is_cinematic = view_target:find("BP_Cinematic",1,true)~=nil
            disable_object_hooks(is_cinematic==true)    
            if is_cinematic == true then
                uevr.params.vr.set_mod_value("VR_AimMethod", "0")
            else
                uevr.params.vr.set_mod_value("VR_AimMethod", "2")
            end

            prevViewTarget = currentVT
        end
    end    
end)

