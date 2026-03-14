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


--Global Vars
WidgetArray={}
WidgetCompArray={}
world =nil
CurrentTargetInHud= nil
CurrentTrackedTarget=nil
HMCComponent=nil
HMCHullComponent=nil
HMCArmorComponent=nil
HMCShieldComponent=nil

--KISMET LIBS
KismetStringLibrary = find_static_class("Class /Script/Engine.KismetStringLibrary")
KismetTextLib= find_static_class("Class /Script/Engine.KismetTextLibrary")
KismetMathLibrary=find_static_class("Class /Script/Engine.KismetMathLibrary")
SlateLibary= find_static_class("Class /Script/UMG.SlateBlueprintLibrary")

--STRUCT CLASSES
 flinearColor_c = find_required_object("ScriptStruct /Script/CoreUObject.LinearColor")
 WidgetClass= find_required_object("Class /Script/UMG.WidgetComponent")
 hud_material_name = "MaterialInstanceConstant /Engine/EngineMaterials/Widget3DPassThrough_Translucent.Widget3DPassThrough_Translucent"
 ftransform_c = find_required_object("ScriptStruct /Script/CoreUObject.Transform")
 PaintCont_C= find_required_object("ScriptStruct /Script/UMG.PaintContext")
 hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
 PointEvent_C= find_required_object("ScriptStruct /Script/SlateCore.PointerEvent")
 geo_c = find_required_object("ScriptStruct /Script/SlateCore.Geometry")
 Vec2d_C = find_required_object("ScriptStruct /Script/CoreUObject.Vector2D")
 Vec3d_C = find_required_object("ScriptStruct /Script/CoreUObject.Vector")
 Widget_C= find_required_object("Class /Script/UMG.Widget")
 game_engine_class = find_required_object("Class /Script/Engine.GameEngine")
 game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
 CameraMAnager_C= find_required_object("Class /Script/Engine.PlayerCameraManager")
 CameraManager= UEVR_UObjectHook.get_first_object_by_class(CameraMAnager_C)
 
 
 
 
 --WIDGETS Classes
 ParMat= uevr.api:find_uobject("Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough")
 
 MarkerBG_C = find_required_object("WidgetBlueprintGeneratedClass /Game/Blueprints/UI/HUD/WG_HUD_Marker_BG.WG_HUD_Marker_BG_C")
 Markericon_C = find_required_object("WidgetBlueprintGeneratedClass /Game/Blueprints/UI/HUD/WG_MarkerDetails_Icon.WG_MarkerDetails_Icon_C")
 MouseCursor_C= find_required_object("WidgetBlueprintGeneratedClass /Game/Blueprints/UI/WG_Menu_Cursor.WG_Menu_Cursor_C") 
 Crosshair_C = find_required_object("WidgetBlueprintGeneratedClass /Game/Blueprints/UI/HUD/WG_Crosshair.WG_Crosshair_C")
 MarkerDetails_C= find_required_object("WidgetBlueprintGeneratedClass /Game/Blueprints/UI/HUD/WG_MarkerDetails.WG_MarkerDetails_C")
 MarkWidget_C = find_required_object("WidgetBlueprintGeneratedClass /Game/Blueprints/UI/HUD/WG_HUD_Marker_Default.WG_HUD_Marker_Default_C")
 TargetAssistCursor_C = find_required_object("WidgetBlueprintGeneratedClass /Game/Blueprints/UI/HUD/WG_Aim_Assist.WG_Aim_Assist_C")
 
 -- Widget Class names
 
 SpeedName_C= "WidgetBlueprintGeneratedClass /Game/Blueprints/UI/Cockpit/WG_Cockpit_Speed.WG_Cockpit_Speed_C"
 ShieldName_C = "WidgetBlueprintGeneratedClass /Game/Blueprints/UI/Cockpit/WG_Cockpit_Shield.WG_Cockpit_Shield_C"
 ArmorName_C = "WidgetBlueprintGeneratedClass /Game/Blueprints/UI/Cockpit/WG_Cockpit_Armor.WG_Cockpit_Armor_C"
 HullName_C ="WidgetBlueprintGeneratedClass /Game/Blueprints/UI/Cockpit/WG_Cockpit_Hull.WG_Cockpit_Hull_C"
 
 
 --MissionIndicator_C = find_required_object("WG_Interact_Confirm_C /Engine/Transient.GameEngine_2147482467.BP_GameInstance_C_2147482353.WG_Interact_Confirm_C_2147270026")
 
 --WIDGET ANIMS
 DetFadeAnim_C= find_required_object("WidgetAnimation /Game/Blueprints/UI/HUD/WG_HUD_Marker_Default.WG_HUD_Marker_Default_C.DetailsFadeIn_INST")
 DetailsAnim_C= find_required_object("WidgetAnimation /Game/Blueprints/UI/HUD/WG_HUD_Marker_Default.WG_HUD_Marker_Default_C.AnimationSpottedOnScreen_INST")


--Debug

--Debug_C = UEVR_UObjectHook.get_objects_by_class(MissionIndicator_C,false)
--for i, comp in ipairs(Debug_C) do
--	if comp.Visibility~=1 then
--					print(comp:get_full_name())
--					comp:SetVisibility(1)
--	end
--end
--print(MissionIndicator_C:GetParent():get_full_name())