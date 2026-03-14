
local api = uevr.api
local params = uevr.params
local callbacks = params.sdk.callbacks
local vr=uevr.params.vr

local function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        error("Cannot find " .. name)
        return nil
    end

    return obj
end
local find_static_class = function(name)
    local c = find_required_object(name)
    return c:get_class_default_object()
end

uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)
	

	
local pawn_c= api:get_local_pawn(0)

if pawn_c.MeleeWeapon~=nil then
	if pawn_c.MeleeWeapon.AttachSocketName:to_string() =="Weapon1Socket" then
		pawn_c.MeleeWeapon:SetRenderInMainPass(true)
	else pawn_c.MeleeWeapon:SetRenderInMainPass(false) end
end
--print(pawn_c.SidearmSkeletal.AttachSocketName)

if  pawn_c.SidearmSkeletal~=nil then	
	if pawn_c.SidearmSkeletal.AttachSocketName:to_string() ~= "Sidearm_Attach" then
		pawn_c.SidearmSkeletal:SetRenderInMainPass(true) 
		pawn_c.SidearmMagazine:SetRenderInMainPass(true)
		pawn_c.SidearmSkeletal:SetVisibility(true) 
		pawn_c.SidearmMagazine:SetVisibility(true)
		pawn_c.SidearmScope:SetRenderInMainPass(false)
		pawn_c.SidearmMuzzle:SetRenderInMainPass(true)
	else pawn_c.SidearmSkeletal:SetRenderInMainPass(false) 
		pawn_c.SidearmMagazine:SetRenderInMainPass(false)
		pawn_c.SidearmScope:SetRenderInMainPass(false)
		pawn_c.SidearmMuzzle:SetRenderInMainPass(false)
	end
end
if pawn_c.LongarmSkeletal~=nil then
	if pawn_c.LongarmSkeletal.AttachSocketName:to_string() ~= "RangedAttach" then
		pawn_c.LongarmSkeletal:SetRenderInMainPass(true) 
		pawn_c.LongarmMagazine:SetRenderInMainPass(true)
		pawn_c.LongarmSkeletal:SetVisibility(true) 
		pawn_c.LongarmMagazine:SetVisibility(true)
		pawn_c.LongarmMuzzle:SetRenderInMainPass(true)
		--if pawn_c.LongarmScope~=nil then
		pawn_c.LongarmScope:SetRenderInMainPass(false)
		--end
	else pawn_c.LongarmSkeletal:SetRenderInMainPass(false)
		pawn_c.LongarmMagazine:SetRenderInMainPass(false)
		pawn_c.LongarmMuzzle:SetRenderInMainPass(false)
		--if pawn_c.LongarmScope~=nil then
		pawn_c.LongarmScope:SetRenderInMainPass(false)
		--end
	end
end
	--print(pawn_c.SidearmScope:get_fname():to_string())
end)