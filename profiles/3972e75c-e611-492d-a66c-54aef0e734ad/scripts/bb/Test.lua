local utils=require(".\\libs\\uevr_utils")
require(".\\Trackers\\Trackers")
utils.initUEVR(uevr)



local api = uevr.api
	
	local params = uevr.params
	local callbacks = params.sdk.callbacks
	local pawn = api:get_local_pawn(0)
	local player= api:get_player_controller(0)
	local vr=uevr.params.vr



function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        error("Cannot find " .. name)
        return nil
    end

    return obj
end
function find_static_class(name)
    local c = find_required_object(name)
    return c:get_class_default_object()
end

function find_first_of(className, includeDefault)
	if includeDefault == nil then includeDefault = false end
	local class =  find_required_object(className)
	if class ~= nil then
		return UEVR_UObjectHook.get_first_object_by_class(class, includeDefault)
	end
	return nil
end

function find_required_object_no_cache(class, full_name)


    local matches = class:get_objects_matching(false)


    for i, obj in ipairs(matches) do


        if obj ~= nil and obj:get_full_name() == full_name then


            return obj


        end


    end


    return nil


end

function SearchSubObjectArrayForObject(ObjArray, string_partial)
local FoundItem= nil
	for i, InvItems in ipairs(ObjArray) do
				if string.find(InvItems:get_fname():to_string(), string_partial) then
				--	print("found")
					FoundItem=InvItems
					--return FoundItem
				break
				end
	end
return	FoundItem
end

local KismetTextLib= find_static_class("Class /Script/Engine.KismetTextLibrary")
local KismetMathLibrary=find_static_class("Class /Script/Engine.KismetMathLibrary")
local SlateLibary= find_static_class("Class /Script/UMG.SlateBlueprintLibrary")

local hud_material_name = "MaterialInstanceConstant /Engine/EngineMaterials/Widget3DPassThrough_Translucent.Widget3DPassThrough_Translucent"
local   ftransform_c = find_required_object("ScriptStruct /Script/CoreUObject.Transform")
local PaintCont_C= find_required_object("ScriptStruct /Script/UMG.PaintContext")
local  hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
local PointEvent_C= find_required_object("ScriptStruct /Script/SlateCore.PointerEvent")
local PointEve1 = StructObject.new(PointEvent_C)
local  geo_c = find_required_object("ScriptStruct /Script/SlateCore.Geometry")
local Geo= StructObject.new(geo_c)
local Vec2d_C = find_required_object("ScriptStruct /Script/CoreUObject.Vector2D")
local TempVec2D= StructObject.new(Vec2d_C)
local TempVec2D1= StructObject.new(Vec2d_C)
local TempVec2D2= StructObject.new(Vec2d_C)
TempVec2D.X=5
TempVec2D.Y=5
local ParMat= uevr.api:find_uobject("Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough")
local MarkerBG_C = find_required_object("WidgetBlueprintGeneratedClass /Game/Blueprints/UI/HUD/WG_HUD_Marker_BG.WG_HUD_Marker_BG_C")

local PaintCont1 = StructObject.new(PaintCont_C)
local Markericon_C = find_required_object("WidgetBlueprintGeneratedClass /Game/Blueprints/UI/HUD/WG_MarkerDetails_Icon.WG_MarkerDetails_Icon_C")
local MouseCursor_C= find_required_object("WidgetBlueprintGeneratedClass /Game/Blueprints/UI/WG_Menu_Cursor.WG_Menu_Cursor_C")
local MouseCursor= UEVR_UObjectHook.get_objects_by_class(MouseCursor_C,false)
local DetFadeAnim_C= find_required_object("WidgetAnimation /Game/Blueprints/UI/HUD/WG_HUD_Marker_Default.WG_HUD_Marker_Default_C.DetailsFadeIn_INST")
local DetailsAnim_C= find_required_object("WidgetAnimation /Game/Blueprints/UI/HUD/WG_HUD_Marker_Default.WG_HUD_Marker_Default_C.AnimationSpottedOnScreen_INST")
local Crosshair_C = find_required_object("WidgetBlueprintGeneratedClass /Game/Blueprints/UI/HUD/WG_Crosshair.WG_Crosshair_C")

Crosshair=UEVR_UObjectHook.get_objects_by_class(Crosshair_C,false)
TarActorsWidget_C= find_required_object("WidgetBlueprintGeneratedClass /Game/Blueprints/UI/HUD/WG_MarkerDetails.WG_MarkerDetails_C")
MarkWidget_C = find_required_object("WidgetBlueprintGeneratedClass /Game/Blueprints/UI/HUD/WG_HUD_Marker_Default.WG_HUD_Marker_Default_C")
Widget_C= find_required_object("Class /Script/UMG.Widget")
MarkerBGs= UEVR_UObjectHook.get_objects_by_class(MarkerBG_C,false)
Markericons= UEVR_UObjectHook.get_objects_by_class(Markericon_C,false)
MarkWidgets= UEVR_UObjectHook.get_objects_by_class(MarkWidget_C,false)
TarActorsWidget=UEVR_UObjectHook.get_objects_by_class(TarActorsWidget_C,false)
local flinearColor_c = find_required_object("ScriptStruct /Script/CoreUObject.LinearColor")
local WidgetClass= find_required_object("Class /Script/UMG.WidgetComponent")
local reusable_hit_result = StructObject.new(hitresult_c)
local zero_transform = StructObject.new(ftransform_c)
--if not zero_transform then return false end
  zero_transform.Rotation.W = 1.0
  zero_transform.Scale3D = temp_vec3:set(1.5, 1.5, 1.5)
local color = StructObject.new(flinearColor_c)
color.R = 100
color.G = 100
color.B = 0
color.A = 0.9

local temp_vec3 = Vector3d.new(0, 0, 0)
local LocVec = Vector3d.new(0, 0, 0)

local game_engine_class = find_required_object("Class /Script/Engine.GameEngine")
local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
local viewport = game_engine.GameViewport
local world = viewport.World
local wanted_mat = uevr.api:find_uobject("MaterialInstanceConstant /Engine/EngineMaterials/Widget3DPassThrough_Translucent.Widget3DPassThrough_Translucent")
		 ParMat:set_property("BlendMode", 0)
		 ParMat.bDisableDepthTest = true

local WidgetArray={}
local WidgetCompArray={}
--local Test=false
local MouseWidget=nil
for i, comp in ipairs(MouseCursor) do
		if string.find(comp:get_full_name(), "_C_" ) then
			MouseWidget=comp
		end
end


local function UpdateHud(dWidgetComponent,Widget)
	--WidgetComponent = Target_:AddComponentByClass(WidgetClass,false,zero_transform,false)
	

	--Widget:RemoveFromViewport()
	Widget:SetVisibility(0)
	--Widget:AddToViewport(0)
	--Widget.Slot:SetPosition(TempVec2D)
	--right_hand_component:SetMaterial(0,hud_material_name)
	dWidgetComponent:SetWidget(Widget)
	dWidgetComponent:SetDrawSize(utils.vector_2(2000, 500))
	dWidgetComponent:SetVisibility(true,true)
	dWidgetComponent:SetHiddenInGame(false,false)
	dWidgetComponent:SetMaterial(0,wanted_mat)
	dWidgetComponent.BlendMode=2
	dWidgetComponent:SetTintColorAndOpacity(color)
	--Target_:FinishAddComponent(WidgetComponent,false, zero_transform)
	dWidgetComponent:K2_SetRelativeLocation(LocVec:set(0, 0, 0), false, reusable_hit_result, false)
	dWidgetComponent:K2_SetRelativeRotation(LocVec:set(0, 180, 0), false, reusable_hit_result, false)
	dWidgetComponent.RelativeScale3D.X=100
	dWidgetComponent.RelativeScale3D.Y=100
	dWidgetComponent.RelativeScale3D.Z=100
	dWidgetComponent:SetGenerateOverlapEvents(false)
	--local ok=dWidgetComponent:OnPaint()
	table.insert(WidgetArray,Widget)
	table.insert(WidgetCompArray,dWidgetComponent)
end



local Updated=false
local GeomToScreen={}
if pawn~=nil then
	Updated=true
	for i, comp in ipairs(MarkWidgets) do
				--print(comp:get_full_name())
			if comp.Visibility==0 then	
				--print(comp:get_full_name())
				--comp:SetVisibility(0)
				--comp:RemoveExtension(comp.DetailsFadeIn)
				--local Target =nil 
				--comp:OnFirstShown()
				local Geom= comp:GetCachedGeometry(Geo)
				SlateLibary:LocalToViewport(world,Geom,TempVec2D2,TempVec2D1,TempVec2D2)
				table.insert(GeomToScreen, Geom)
				--print(TempVec2D2.X .. "   Y: " .. TempVec2D2.Y)
				--comp:OnInitialized()
				--comp:OnPaint(PaintCont1)
				if comp.OwningActor~=nil then
				local WidgetComponent = pawn:AddComponentByClass(WidgetClass,false,zero_transform,false)
				--if comp.OwningActor then
					if comp.OwningActor.PawnMeshes~=nil then
						--Target=comp.OwningActor
						if WidgetComponent~=nil then
							UpdateHud(WidgetComponent, comp)
						end
					end	
				end
			end	
				--pawn:FinishAddComponent(WidgetComponent,false, zero_transform)
	end
	
	
	--hook_function(Widget_C,"OnFocusLost",true,function() print("hey") return false end,function() print("hey") return false end,true)
	--hook_function(Widget_C,"OnMouseLeave",true,function() print("hey") return false end,function() print("hey") return false end,true)
	--hook_function(Widget_C,"SetVisibility",true,function() print("hey") return false end,function() print("hey") return false end,true)
	
	for i, comp in ipairs(TarActorsWidget) do
		--  local class_fn = comp:find_function("Set Visibility")
		
	end
end
local Geom3= nil
local Scanned=false
local UpdDelta=0
uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)

 pawn = api:get_local_pawn(0)
 player= api:get_player_controller(0)
--if not Scanned then
--	for x=0, 1900,10 do
--		for y=0, 1000,10 do
--			player:SetMouseLocation(x,y)
--		end
--	end
--	Scanned=true
--end
local CrossHairWidget=nil
for i, comp in ipairs(Crosshair) do
	if comp.Visibility==3 or comp.Visibility==1 then
			CrossHairWidget=comp
	end
end

 
 --player:SetMouseLocation(100,200)
 UpdDelta=UpdDelta+delta
 for i, comp in ipairs(WidgetCompArray) do
			--comp:SetVisibility(0)
			--comp:SetGenerateOverlapEvents(false)
			--comp:SetCollisionEnabled(0)
			--comp.bSelectable=false
			--comp:SetFocus()
			--comp:PlayAnimation(DetFadeAnim_C,1,1,0,0.5,false)
			--comp:OnFirstShown()
			--local Target= comp.Widget.OwningActor
			local Vec1=pawn.PawnMeshes[1]:K2_GetComponentLocation()
			if hmd_component~= nil then
				Vec1= hmd_component:K2_GetComponentLocation()
			end
			
			--pawn.PawnMeshes[1]:K2_GetComponentLocation()
			local Vec2= comp.Widget.OwningActor:K2_GetActorLocation()
			local TempVec3 = KismetMathLibrary:Normal(KismetMathLibrary:Subtract_VectorVector(Vec1,Vec2),10)
			local FinalVec = KismetMathLibrary:Add_VectorVector(Vec1,TempVec3*-10000)
			local RotFinal = KismetMathLibrary:Conv_VectorToRotator(TempVec3)
			comp:K2_SetWorldRotation(RotFinal,false,reusable_hit_result,true)
			comp:K2_SetWorldLocation(FinalVec,false,reusable_hit_result,true)
			
			--player:ClientSetRotation(RotFinal,false)
			--local CurDistance= pawn:GetDistanceTo(Target)
			comp.RelativeScale3D.X=4
			comp.RelativeScale3D.Y=4
			comp.RelativeScale3D.Z=4
		
--end
end

local Geom2 = WidgetArray[1]:GetCachedGeometry(Geo)
	SlateLibary:LocalToViewport(world,Geom2,TempVec2D,TempVec2D1,TempVec2D2)
		--print(TempVec2D1.X .. "   Y: " .. TempVec2D1.Y)
--if UpdDelta>5 then
	UpdDelta=0
--	player:SetMouseLocation(TempVec2D1.X, TempVec2D1.Y)
	
--else player:SetMouseLocation(960	, 540)
--end




 for i, comp in ipairs(WidgetArray) do
	--comp.Slot:SetPosition(TempVec2D)
	comp.BoxInteract:SetVisibility(0)
	comp.BoxLocationInfo.Slot:SetPosition(TempVec2D)
	
	comp.RenderOpacity=1
			--comp:SetVisibility(0)
			--comp:SetGenerateOverlapEvents(false)
			--comp:SetCollisionEnabled(0)
			--comp.bSelectable=false
			--comp:SetFocus()
			--comp:PlayAnimation(DetFadeAnim_C,1,1,0,0.5,false)
			--comp:OnFirstShown()
			--local Target= comp.Widget.OwningActor
			
			--local CurDistance= pawn:GetDistanceTo(Target)
			
--end
end
 	for i, comp in ipairs(TarActorsWidget) do
		comp:SetVisibility(0)
		if comp.TxtName~=nil then
			--comp.TxtName:SetVisibility(0)
			--comp:OnAnimationStarted(DetailsFadeIn)
			--comp.IconType:OnAnimationStarted(DetailsFadeIn)
			--comp.IconElite:OnAnimationStarted(DetailsFadeIn)
			--comp.IconLevel:OnAnimationStarted(DetailsFadeIn)
		--print(comp:GetAlignmentInViewport().X)
		
			--comp.TxtName:GetAccessibleText()
		--	comp.TxtPrefix:SetVisibility(0)
			--comp.TxtName:SetUserFocus(player)
		end
	end
	for i, comp in ipairs(MarkerBGs) do
		--comp:SetVisibility(0)
		comp:OnAnimationStarted(DetailsFadeIn)
	end
	for i, comp in ipairs(Markericons) do
		--comp:SetVisibility(0)
		comp:OnAnimationStarted(DetailsFadeIn)
	end
 --if pawn~=nil and UpdDelta>10 and Updated then
	
	MarkerBGs= UEVR_UObjectHook.get_objects_by_class(MarkerBG_C,false)
Markericons= UEVR_UObjectHook.get_objects_by_class(Markericon_C,false)
MarkWidgets= UEVR_UObjectHook.get_objects_by_class(MarkWidget_C,false)
TarActorsWidget=UEVR_UObjectHook.get_objects_by_class(TarActorsWidget_C,false)
--	if WidgetCompArray[1]~=nil then
		for i, comp in ipairs(MarkWidgets) do
			--comp:PlayAnimation(DetailsAnim_C)
			comp:SetAnimationCurrentTime(comp.DetailsFadeIn,0.5)
			--comp:PauseAnimation()
			Geom3= comp:GetCachedGeometry(Geo)
			comp:OnMouseEnter(Geom3,PointEve1)
			--comp:StopAllAnimations()
			--comp:SetVisibility(0)
			--comp:SetFocus()
		--	comp.Slot:SetPosition(TempVec2D)
			--comp:OnFirstShown()
		--	local Geom=	comp:GetCachedGeometry(Geo)
		--	comp:Tick(Geom,delta)
		--	comp:OnAnimationStarted(DetailsFadeIn)
			if comp.Visibility==0 then
			--	comp:SetRenderTranslation(TempVec2D)
				--
			end
			--comp:SetIsEnabled(false)
			--comp:UnregisterInputComponent()
			--if comp.OverlayConditions~=nil then
			--	comp.OverlayConditions:SetCursor(0)
			--	comp.OverlayIcons:SetCursor(0)
			--end
			--comp:SetInputActionBlocking(true)
			
				--comp:StopConditionNameAnimations()
			--comp:StopListeningForAllInputActions()
			--comp:RemoveInteractWidget()
--			local Target= comp.Widget.OwningActor
--				
--			local CurDistance= pawn:GetDistanceTo(Target)
--			comp.RelativeScale3D.X=1000
--			comp.RelativeScale3D.Y=1000
--			comp.RelativeScale3D.Z=1000
		end
	for i, comp in ipairs(TarActorsWidget) do
		--comp:SetVisibility(0)
		comp:SetRenderOpacity(1)
		Geom3= comp:GetCachedGeometry(Geo)
		comp:OnMouseEnter(Geom3,PointEve1)
		MouseWidget:OnMouseEnter(Geom3,PointEve1)
		if comp.TxtName~=nil then
		comp.TxtName:SetVisibility(0)
			--print(comp.TxtName:GetText())
			--comp.TxtName:SetText(KismetTextLib:Conv_StringToText("Hithere"))
		--	comp.TxtPrefix:SetVisibility(0)
			--comp.TxtName:SetUserFocus(player)
		end
	end
	for i, comp in ipairs(MarkerBGs) do
		comp:SetVisibility(0)
	end
	for i, comp in ipairs(Markericons) do
		comp:SetVisibility(0)
		
	end
	-- local DefaultOffset= uevr.params.vr:get_mod_value("VR_ControllerPitchOffset")
	-- print(DefaultOffset)
--end	


end)

uevr.sdk.callbacks.on_post_engine_tick(
function(engine, delta)
--if UpdDelta>10 then

end)

local PreRotY
local PreRotX
local DiffRot
local DecoupledYawCurrentRotLast=0
uevr.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
PreRotY=rotation.y
PreRotX=rotation.x
end)





uevr.sdk.callbacks.on_post_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
	--print(DecoupledYawCurrentRot)
local pawn=api:get_local_pawn(0)
local player =api:get_player_controller(0)

local Geom2 = WidgetArray[1]:GetCachedGeometry(Geo)
	SlateLibary:LocalToViewport(world,Geom2,TempVec2D,TempVec2D1,TempVec2D2)
		print(TempVec2D1.X .. "   Y: " .. TempVec2D1.Y)
--if UpdDelta>5 then
	UpdDelta=0
	player:SetMouseLocation(TempVec2D1.X, TempVec2D1.Y)
	--DecoupledYawCurrentRotLast=rotation.y	
-- if ConditionChagned then
	--print("ok2")
	-- ConditionChagned=false
	---- vr.recenter_view()
	-- rotation.y=DecoupledYawCurrentRotLast	
	--end

end)