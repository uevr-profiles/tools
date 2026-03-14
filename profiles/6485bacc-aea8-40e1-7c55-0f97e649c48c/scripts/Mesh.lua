local uevrUtils = require('libs/uevr_utils')
require(".\\Config\\CONFIG")
local ParMat = uevrUtils.find_required_object("Material /Game/Character/Cat/Material/M_cat_SSS_Dither.M_cat_SSS_Dither")
local ParMat2 = uevrUtils.find_required_object("Material /Game/Data/Materials/Instance/Base/Base_Textures.Base_Textures")
if FirstCatMode~=1 then
	ParMat.BlendMode=0
	ParMat2.BlendMode=0
end
--function on_level_change(level)

local api = uevr.api
uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)
	local pawn= api:get_local_pawn(0)
	
if pawn~=nil then	
	if FirstCatMode~=1 then
		ParMat.BlendMode=0
		ParMat2.BlendMode=0
		if isCinematic then
			pawn.m_visual:SetVisibility(true, false)
		else pawn.m_visual:SetVisibility(false, false)
		end
	elseif FirstCatMode==1 then
		pawn.m_visual:SetVisibility(true, false)
	end
end
end)