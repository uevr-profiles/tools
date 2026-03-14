
	
local utils=require(".\\libs\\uevr_utils")
require(".\\Trackers\\Trackers")
require(".\\Subsystems\\Helper")
require(".\\Subsystems\\HudTrace")
require(".\\Subsystems\\ControlHelper")
require(".\\Subsystems\\TargetingWidget")
require(".\\Subsystems\\HMCS")
utils.initUEVR(uevr)



local api = uevr.api
local params = uevr.params
local callbacks = params.sdk.callbacks
local pawn = api:get_local_pawn(0)
local player= api:get_player_controller(0)
local vr=uevr.params.vr

local PointEve1 = StructObject.new(PointEvent_C) 
local Geo= StructObject.new(geo_c) 
local TempVec2D= StructObject.new(Vec2d_C)
local TempVec2D1= StructObject.new(Vec2d_C)
local TempVec2D2= StructObject.new(Vec2d_C)
	TempVec2D.X=5
	TempVec2D.Y=5
local MouseCursor= UEVR_UObjectHook.get_objects_by_class(MouseCursor_C,false)
local PaintCont1 = StructObject.new(PaintCont_C)
local reusable_hit_result = StructObject.new(hitresult_c)
local zero_transform = StructObject.new(ftransform_c)
--if not zero_transform then return false end
  zero_transform.Rotation.W = 1.0
  zero_transform.Scale3D = temp_vec3:set(1.5, 1.5, 1.5)
local color = StructObject.new(flinearColor_c)
color.R = 1
color.G = 1
color.B = 1
color.A = 1
local temp_vec3 = Vector3d.new(0, 0, 0)
local LocVec = Vector3d.new(0, 0, 0)


Crosshair=UEVR_UObjectHook.get_objects_by_class(Crosshair_C,false)
MarkerBGs= UEVR_UObjectHook.get_objects_by_class(MarkerBG_C,false)
Markericons= UEVR_UObjectHook.get_objects_by_class(Markericon_C,false)
MarkWidgets= UEVR_UObjectHook.get_objects_by_class(MarkWidget_C,false)
MissionIndicator = UEVR_UObjectHook.get_objects_by_class(MissionIndicator_C,false)
MarkerDetails = UEVR_UObjectHook.get_objects_by_class(MarkerDetails_C,false)
TargetCursors = UEVR_UObjectHook.get_objects_by_class(TargetAssistCursor_C,false)

local wanted_mat = uevr.api:find_uobject("MaterialInstanceConstant /Engine/EngineMaterials/Widget3DPassThrough_Translucent.Widget3DPassThrough_Translucent")
		 --ParMat:set_property("BlendMode", 0)
		-- ParMat.bDisableDepthTest = true


--local Test=false
local MouseWidget=nil
for i, comp in ipairs(MouseCursor) do
		if string.find(comp:get_full_name(), "_C_" ) then
			MouseWidget=comp
		end
end


local function CheckIfInArray(DComp,DArray)
	local Result=false
	for i, comp in ipairs(DArray) do
		if DComp == comp then
			Result=true
		end
	end
	return Result
end

local MarkerTickIndex=1
local function AddTickAndUpdateMarkerArray()

	if MarkerTickIndex < #MarkWidgets then
		MarkerTickIndex=MarkerTickIndex+1
		--print(MarkerTickIndex)
	else
		MarkerTickIndex=1		
		--Marker_C = find_required_object("Class /Script/Engine.MarkerComponent")
		MarkWidgets = UEVR_UObjectHook.get_objects_by_class(MarkWidget_C,false)
		--print("Ok")
	end
end



local function UpdateWidgetCompPos(dpawn, dWidgetCompArray)
if dpawn ==nil then return end
	local ToRemove ={}
	
	--print(#dWidgetCompArray)
			
	if #dWidgetCompArray>0 then
		if isCinematic  then
			print("true")
			for i, comp in ipairs(dWidgetCompArray) do
					--comp:SetVisibility(1)
					--comp:GetWidget():AddToViewport()
					--comp:K2_DestroyComponent()
					comp:SetGenerateOverlapEvents(false)
					comp:SetCollisionEnabled(0)
					comp:SetCollisionResponseToAllChannels(0)
					--table.remove(dWidgetCompArray, i)
					comp:SetCollisionObjectType(33)
			end
			
		
		elseif CinematicTimer>1.0 then
			for i, comp in ipairs(dWidgetCompArray) do
				if comp~=nil then
					--comp:SetVisibility(0)
					comp:SetGenerateOverlapEvents(true)
					comp:SetCollisionEnabled(1)
					--if CinematicTimer>9 then 
					--	comp:SetCollisionEnabled(1)
					--end
					comp:SetCollisionResponseToAllChannels(1)
					--comp:SetCollisionResponseToChannel(33,1)
					comp:SetCollisionObjectType(33)
					--comp:SetFocus()
					--comp:PlayAnimation(DetFadeAnim_C,1,1,0,0.5,false)
					--comp:OnFirstShown()
					--local Target= comp.Widget.OwningActor
					
					local Vec1 = dpawn:K2_GetActorLocation()
					if dpawn.PawnMeshes  then 
						Vec1 = dpawn.PawnMeshes[1]:K2_GetComponentLocation()
					end
					if hmd_component~= nil then
						Vec1= hmd_component:K2_GetComponentLocation()
					end
					--print(comp:get_full_name())
					--pawn.PawnMeshes[1]:K2_GetComponentLocation()
					local Widget=comp:GetWidget()
					if Widget.Visibility == 1 then
						comp:SetVisibility(false,true)
					else
						comp:SetVisibility(true,true)
					end
					if Widget~=nil and Widget.OwningActor~=nil then
						local Vec2= Widget.OwningActor:K2_GetActorLocation()
						local TempVec3 = KismetMathLibrary:Normal(KismetMathLibrary:Subtract_VectorVector(Vec1,Vec2),1)
						local FinalVec = KismetMathLibrary:Add_VectorVector(Vec1,TempVec3*-5000)
						--TempVec3.Z= hmd_component:K2_GetComponentRotation().Z
						local RotFinal = KismetMathLibrary:Conv_VectorToRotator(TempVec3)
						RotFinal.Z=-hmd_component:K2_GetComponentRotation().Z
						comp:K2_SetWorldRotation(RotFinal,false,reusable_hit_result,true)
						comp:K2_SetWorldLocation(FinalVec,false,reusable_hit_result,true)
						
						--player:ClientSetRotation(RotFinal,false)
						--local CurDistance= pawn:GetDistanceTo(Target)
						comp.RelativeScale3D.X=4
						comp.RelativeScale3D.Y=4
						comp.RelativeScale3D.Z=4
						if Widget.OwningActor.Health~=nil then
							if Widget.OwningActor.Health:GetCurrentHitpoints() <=0 then
								comp:SetVisibility(false,true)
							end
						end
					else 
						dWidgetCompArray[i]:SetVisibility(false,true)
						--dWidgetCompArray[i]:K2_DestroyComponent()
						if comp:GetWidget().OwningActor ==nil and comp.bVisible==false then
							dWidgetCompArray[i]:K2_DestroyComponent()
							table.remove(dWidgetCompArray, i)
						end
					end
				else
					dWidgetCompArray[i]:SetVisibility(false,true)
				--	table.insert(ToRemove, i)	
					--dWidgetCompArray[i]:K2_DestroyComponent()
					if comp:GetWidget().OwningActor ==nil then
							dWidgetCompArray[i]:K2_DestroyComponent()
							table.remove(dWidgetCompArray, i)
					end
					
				end		
			end
		end
	--	for i, comp in ipairs(ToRemove) do
			
	--	end
	end
end
local function UpdateTargetWidgetCompPos(dpawn, dWidgetComponent)
	if dpawn==nil then return end
		if dWidgetComponent~=nil then
			if isCinematic  then
				dWidgetComponent:SetCollisionEnabled(0)
				dWidgetComponent:SetGenerateOverlapEvents(false)
			elseif CinematicTimer>1.0 then
				local Widget=dWidgetComponent:GetWidget()
				Widget:RemoveFromViewport()
				local Vec1 = dpawn:K2_GetActorLocation()
				if dpawn.PawnMeshes  then 
						Vec1 = dpawn.PawnMeshes[1]:K2_GetComponentLocation()
				end
				if hmd_component~= nil then
						Vec1= hmd_component:K2_GetComponentLocation()
				end
				
				local PrimWeapons= dpawn.PrimaryWeapons
				if PrimWeapons==nil then return end
				local CurrLockedTarget = dpawn.PrimaryWeapons:GetLockedTarget()
				if CurrLockedTarget~=nil then
					local Vec2= CurrLockedTarget:K2_GetActorLocation()
					if dpawn.PrimaryWeapons~=nil then
						if  CurrLockedTarget.PrimaryWeapons~=nil then
							Vec2=GetPredictedTargetLocation(dpawn, CurrLockedTarget)
						end
					end		
					--
					local TempVec3 = KismetMathLibrary:Normal(KismetMathLibrary:Subtract_VectorVector(Vec1,Vec2),1)
					local FinalVec = KismetMathLibrary:Add_VectorVector(Vec1,TempVec3*-5000)
					--TempVec3.Roll= dpawn.PawnMeshes[1]:K2_GetComponentRotation().Roll
					local RotFinal = KismetMathLibrary:Conv_VectorToRotator(TempVec3)
					RotFinal.Z=-hmd_component:K2_GetComponentRotation().Z
					dWidgetComponent:K2_SetWorldRotation(RotFinal,false,reusable_hit_result,true)
					dWidgetComponent:K2_SetWorldLocation(FinalVec,false,reusable_hit_result,true)
					
					--player:ClientSetRotation(RotFinal,false)
					--local CurDistance= pawn:GetDistanceTo(Target)
					dWidgetComponent.RelativeScale3D.X=4
					dWidgetComponent.RelativeScale3D.Y=4
					dWidgetComponent.RelativeScale3D.Z=4
				end
			end
		end
	
end	

local function CreateWidgetComp(dWidgetComponent,Widget)
	--WidgetComponent = Target_:AddComponentByClass(WidgetClass,false,zero_transform,false)
	Widget:RemoveFromViewport()
	--Widget:SetVisibility(0)
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
	dWidgetComponent:SetCollisionEnabled(0)
	--local ok=dWidgetComponent:OnPaint()
	
	table.insert(WidgetCompArray,dWidgetComponent)
end
local function CreateTargetWidgetComp(dWidgetComponent,Widget)
	--WidgetComponent = Target_:AddComponentByClass(WidgetClass,false,zero_transform,false)
	Widget:RemoveFromViewport()
	--Widget:SetVisibility(0)
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
	dWidgetComponent:SetCollisionEnabled(0)
	--local ok=dWidgetComponent:OnPaint()
	
	
end




local Updated=false
local GeomToScreen={}
local function CheckForActiveWidgets(dpawn, dworld , dMarkWidgets)
	if dpawn~=nil and  CinematicTimer>1.0 then 
		AddTickAndUpdateMarkerArray()
		Updated=true
		--for i, comp in ipairs(dMarkWidgets) do
				local comp= dMarkWidgets[MarkerTickIndex]
			if UEVR_UObjectHook.exists(comp) then
				--	print(comp:get_full_name())
				if  comp.Visibility~=1 then	
					
					--comp:SetVisibility(1)
					
					if comp.OwningActor~=nil then
						if not CheckIfInArray(comp, WidgetArray) then
							table.insert(WidgetArray,comp)
							local WidgetComponent = dpawn:AddComponentByClass(WidgetClass,false,zero_transform,false)
						--if comp.OwningActor then
							if comp.OwningActor.RootComponent ~=nil then
								--Target=comp.OwningActor
								if WidgetComponent~=nil then
									CreateWidgetComp(WidgetComponent, comp)
								end
							end	
						end	
					end
				end	
					--pawn:FinishAddComponent(WidgetComponent,false, zero_transform)
			end
	end
end

local TargetCursorPrimaryWidget=nil
local TargetCursorPrimaryWidgetComp=nil
local function CreateTargetingAssistWidgets(dpawn,dMarkWidgets)
	if dpawn~=nil then
		if CinematicTimer>1.0 then
			if TargetCursorPrimaryWidget==nil then
				for i, comp in ipairs(dMarkWidgets) do
					if string.find(comp:get_full_name(), "AimAssistLock") and string.find(comp:get_full_name(), "_C_")   then
						TargetCursorPrimaryWidget= comp
					end
				end
				if TargetCursorPrimaryWidget~=nil then
					local WidgetComponent = dpawn:AddComponentByClass(WidgetClass,false,zero_transform,false)	
					--TargetCursorPrimaryWidgetComp=WidgetComponent
					CreateTargetWidgetComp(WidgetComponent, TargetCursorPrimaryWidget)
					TargetCursorPrimaryWidgetComp=WidgetComponent	
				end
			end
		elseif TargetCursorPrimaryWidgetComp~=nil then
			TargetCursorPrimaryWidgetComp:K2_DestroyComponent()
			TargetCursorPrimaryWidgetComp=nil
		end	
	end
end
				

local function RemoveUnusedWidgetFromArray(DArray)
	if pawn == nil then return end
	
	for i, comp in ipairs(DArray) do
		if not comp then 
			table.remove(DArray, i)
		end
	end
end
	
		
local function ResetOnLevelChange()
		local engine = game_engine_class:get_first_object_matching(false)
		if not engine then
			return
		end	
		local viewport = engine.GameViewport	
		if viewport then
			 world = viewport.World			
			if world then
				local level = world.PersistentLevel					
				if last_level ~= level then
					TargetCursorPrimaryWidget=nil
					TargetCursorPrimaryWidgetComp=nil
					WidgetArray={}
					WidgetCompArray={}
					CinematicTimer=0
					print("resetted arrays")					
					CameraManager= UEVR_UObjectHook.get_first_object_by_class(CameraMAnager_C)	
					TargetCursors =  UEVR_UObjectHook.get_objects_by_class(TargetAssistCursor_C,false)
					HMCComponent=nil
					HMCHullComponent=nil
					HMCArmorComponent=nil
					HMCShieldComponent=nil
				end
				last_level = level
			end
		end
end



uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)
ResetOnLevelChange()
local pawn= api:get_local_pawn(0)

if pawn~=nil then
--if pawn.PrimaryWeapons:GetLockedTarget() ~=nil then
--	print(GetPredictedTargetLocation(pawn,pawn.PrimaryWeapons:GetLockedTarget()).X)
--end
	--MarkWidgets= UEVR_UObjectHook.get_objects_by_class(MarkWidget_C,false)
	if CinematicTimer>1.0 then
		CheckForActiveWidgets(pawn, world, MarkWidgets)
		if isHMCS then
			CreateHMCSComponent(pawn,hmd_actor )
		end
		--if HMCShieldComponent==nil then
		--	CreateHMCSComponent(pawn,pawn,ShieldName_C,HMCShieldComponent )
		--end
		--if HMCArmorComponent ==nil then
		--	CreateHMCSComponent(pawn,pawn,ArmorName_C ,HMCArmorComponent )
		--end
		--if 
		--	CreateHMCSComponent(pawn,pawn,HullName_C  ,HMCHullComponent )
	end
	CreateTargetingAssistWidgets(pawn, TargetCursors)
	UpdateWidgetCompPos(pawn, WidgetCompArray)
	UpdateTargetWidgetCompPos(pawn, TargetCursorPrimaryWidgetComp)
	if TargetCursorPrimaryWidget~=nil then
		--print(TargetCursorPrimaryWidget:get_full_name())
	end
end
--print(pawn.PrimaryWeapons:GetFirstEquippedWeaponInstance().WeaponConfig.WeaponItem:GetAttribute(KismetStringLibrary:Conv_StringToName("weapon_velocity")).Value.BaseValue)--:get_full_name())
--for i, comp in ipairs(WidgetCompArray) do
--		print(comp:get_full_name())
--	end
end)