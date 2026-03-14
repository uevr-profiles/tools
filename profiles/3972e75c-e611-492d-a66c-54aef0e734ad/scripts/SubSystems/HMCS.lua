require(".\\Subsystems\\Helper")	
require(".\\Trackers\\Trackers")
local utils=require(".\\libs\\uevr_utils")
require(".\\Config\\CONFIG")
	local api = uevr.api
	
	local params = uevr.params
	local callbacks = params.sdk.callbacks
	local pawn = api:get_local_pawn(0)
	local player= api:get_player_controller(0)
	local vr=uevr.params.vr
	
	
local temp_vec3 = Vector3d.new(0, 0, 0)	
local zero_transform = StructObject.new(ftransform_c)

local color = StructObject.new(flinearColor_c)
color.R = 0
color.G = HudBrightness
color.B = 0
color.A = 0.8
local wanted_mat = uevr.api:find_uobject("MaterialInstanceConstant /Engine/EngineMaterials/Widget3DPassThrough_Translucent.Widget3DPassThrough_Translucent")	
ParMat.bDisableDepthTest = true	
function CreateHMCSComponent(dpawn,hmdAct)
	if dpawn==nil then return end
	if not string.find(dpawn:get_full_name(),"Ship") then return end
	if  hmdAct~=nil and HMCComponent==nil and CinematicTimer>1.0 and isHMCS then --
		local Widget = find_first_of(SpeedName_C,false)
		if  Widget==nil then return end
		HMCComponent = hmdAct:AddComponentByClass(WidgetClass,false,zero_transform,false)	
	
		HMCComponent:SetWidget(Widget)
		HMCComponent:SetDrawSize(utils.vector_2(100, 100))
		HMCComponent:SetVisibility(true,true)
		HMCComponent:SetHiddenInGame(false,false)
		HMCComponent:SetMaterial(0,wanted_mat)
		HMCComponent.BlendMode=2
		color.R = 0
color.G = HudBrightness
color.B = 0
color.A = 0.8
		HMCComponent:SetTintColorAndOpacity(color)
		--Target_:FinishAddComponent(WidgetComponent,false, zero_transform)
		HMCComponent:K2_SetRelativeLocation(temp_vec3:set(5000, -1200, -500), false, reusable_hit_result, false)
		HMCComponent:K2_SetRelativeRotation(temp_vec3:set(0, 180, 0), false, reusable_hit_result, false)
		HMCComponent.RelativeScale3D.X=5
		HMCComponent.RelativeScale3D.Y=5
		HMCComponent.RelativeScale3D.Z=5
		HMCComponent:SetGenerateOverlapEvents(false)
		HMCComponent:SetCollisionEnabled(0)
		--local ok=HMCComponent:OnPaint()
	end
		color.R = HudBrightness
		color.G = HudBrightness
		color.B = HudBrightness
		color.A = 0.8
	if  hmdAct~=nil and HMCShieldComponent==nil and CinematicTimer>1.0 and isHMCS then --
		local Widget = find_first_of(ShieldName_C,false)
		if  Widget==nil then return end
		HMCShieldComponent = hmdAct:AddComponentByClass(WidgetClass,false,zero_transform,false)	
	
		HMCShieldComponent:SetWidget(Widget)
		HMCShieldComponent:SetDrawSize(utils.vector_2(300, 100))
		HMCShieldComponent:SetVisibility(true,true)
		HMCShieldComponent:SetHiddenInGame(false,false)
		HMCShieldComponent:SetMaterial(0,wanted_mat)
		HMCShieldComponent.BlendMode=2
		
		HMCShieldComponent:SetTintColorAndOpacity(color)
		--Target_:FinishAddComponent(WidgetComponent,false, zero_transform)
		HMCShieldComponent:K2_SetRelativeLocation(temp_vec3:set(5000, -1200, 0), false, reusable_hit_result, false)
		HMCShieldComponent:K2_SetRelativeRotation(temp_vec3:set(0, 180, 0), false, reusable_hit_result, false)
		HMCShieldComponent.RelativeScale3D.X=2
		HMCShieldComponent.RelativeScale3D.Y=1
		HMCShieldComponent.RelativeScale3D.Z=2
		HMCShieldComponent:SetGenerateOverlapEvents(false)
		HMCShieldComponent:SetCollisionEnabled(0)
		--local ok=HMCShieldComponent:OnPaint()
	end
	if  hmdAct~=nil and HMCArmorComponent==nil and CinematicTimer>1.0 and isHMCS then --
		local Widget = find_first_of(ArmorName_C,false)
		if  Widget==nil then return end
		HMCArmorComponent = hmdAct:AddComponentByClass(WidgetClass,false,zero_transform,false)	
	
		HMCArmorComponent:SetWidget(Widget)
		HMCArmorComponent:SetDrawSize(utils.vector_2(300, 100))
		HMCArmorComponent:SetVisibility(true,true)
		HMCArmorComponent:SetHiddenInGame(false,false)
		--hud_material_name.BasePropertyOverrides.bOverride_BlendMode = false
		HMCArmorComponent:SetMaterial(0,wanted_mat)
		
		HMCArmorComponent.BlendMode=2
		
		
		HMCArmorComponent:SetTintColorAndOpacity(color)
		--Target_:FinishAddComponent(WidgetComponent,false, zero_transform)
		HMCArmorComponent:K2_SetRelativeLocation(temp_vec3:set(5000, -1200, -50), false, reusable_hit_result, false)
		HMCArmorComponent:K2_SetRelativeRotation(temp_vec3:set(0, 180, 0), false, reusable_hit_result, false)
		HMCArmorComponent.RelativeScale3D.X=2
		HMCArmorComponent.RelativeScale3D.Y=1
		HMCArmorComponent.RelativeScale3D.Z=2
		HMCArmorComponent:SetGenerateOverlapEvents(false)
		HMCArmorComponent:SetCollisionEnabled(0)
		--local ok=HMCArmorComponent:OnPaint()
	end
	if  hmdAct~=nil and HMCHullComponent==nil and CinematicTimer>1.0 and isHMCS then --
		local Widget = find_first_of(HullName_C,false)
		if  Widget==nil then return end
		HMCHullComponent = hmdAct:AddComponentByClass(WidgetClass,false,zero_transform,false)	
	
		HMCHullComponent:SetWidget(Widget)
		HMCHullComponent:SetDrawSize(utils.vector_2(300, 100))
		HMCHullComponent:SetVisibility(true,true)
		HMCHullComponent:SetHiddenInGame(false,false)
		HMCHullComponent:SetMaterial(0,wanted_mat)
		HMCHullComponent.BlendMode=2
		
		HMCHullComponent:SetTintColorAndOpacity(color)
		--Target_:FinishAddComponent(WidgetComponent,false, zero_transform)
		HMCHullComponent:K2_SetRelativeLocation(temp_vec3:set(5000, -1200, -100), false, reusable_hit_result, false)
		HMCHullComponent:K2_SetRelativeRotation(temp_vec3:set(0, 180, 0), false, reusable_hit_result, false)
		HMCHullComponent.RelativeScale3D.X=2
		HMCHullComponent.RelativeScale3D.Y=1
		HMCHullComponent.RelativeScale3D.Z=2
		HMCHullComponent:SetGenerateOverlapEvents(false)
		HMCHullComponent:SetCollisionEnabled(0)
		--local ok=HMCHullComponent:OnPaint()
	end
end

