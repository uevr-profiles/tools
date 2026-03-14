require(".\\Subsystems\\Helper")
require(".\\Subsystems\\ControlHelper")
require(".\\Trackers\\Trackers")
local api = uevr.api	
	local params = uevr.params
	local callbacks = params.sdk.callbacks
	local pawn = api:get_local_pawn(0)
	local player= api:get_player_controller(0)
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

local zero_transform1 = StructObject.new(ftransform_c)




--needed Classes
local CapsComp_C = find_required_object("Class /Script/Engine.BoxComponent")



	

--global variables
TraceComponent=nil

--HitWidgetComps={}	
	
--global Functions
function GetWidgetsFromArray(WArray)
	local RetWArray={}
	for i, comp in ipairs(WArray) do
		if string.find(comp:get_full_name(), "WidgetComp") then
			table.insert(RetWArray,comp)
		end
	end
	return RetWArray
end
	

function CreateTraceComponent(hmdAct)
	
	if hmdAct~=nil and TraceComponent==nil and CinematicTimer>1.0 then
		
		TraceComponent = hmdAct:AddComponentByClass(CapsComp_C,false,zero_transform1,false)
	
		TraceComponent.bHiddenInGame=false
		TraceComponent:SetGenerateOverlapEvents(true)
	--	TraceComponent:SetCollisionResponseToAllChannels(1)
	--	TraceComponent:SetCollisionObjectType(1)
		TraceComponent:SetCollisionEnabled(1) 
		--TraceComponent:SetCollisionResponseToAllChannels(0)
		--TraceComponent:SetCollisionResponseToChannel(33,1)
		--TraceComponent:SetCollisionObjectType(33)
		TraceComponent.RelativeScale3D.X=10
		TraceComponent.RelativeScale3D.Y=0.4
		TraceComponent.RelativeScale3D.Z=0.4
			TraceComponent.RelativeLocation.X=5000
			TraceComponent.RelativeLocation.Y=0
			TraceComponent.RelativeLocation.Z=0			
	end
	if TraceComponent~=nil and isCinematic then
		TraceComponent:SetCollisionEnabled(0) 
		TraceComponent:SetGenerateOverlapEvents(false)
		TraceComponent.RelativeLocation.X=0
		TraceComponent.bHiddenInGame=true
	elseif TraceComponent~=nil and CinematicTimer>1.0 then
		TraceComponent:SetGenerateOverlapEvents(true)
		TraceComponent:SetCollisionEnabled(1) 
		TraceComponent.bHiddenInGame=false
		TraceComponent.RelativeLocation.X=5000
	--	TraceComponent:SetCollisionResponseToChannel(33,1)
	--	TraceComponent:SetCollisionObjectType(33)
	end
	
end

	--l
function GetWidgetCompsOnHover(dpawn)
	if dpawn==nil then return end
	local HitWidgetComps={}
	if TraceComponent~=nil then		
		local HitComps={}
		TraceComponent:GetOverlappingComponents(HitComps)
		HitWidgetComps= GetWidgetsFromArray(HitComps)	
	end
	return HitWidgetComps
end	


--local functions
local function GetClosesetWidgetCompFromArray(DTracer, DWidgetArray)
	local DTracerPos= DTracer:K2_GetComponentLocation()
	local CurrMaxDist= 100000
	local CurrNearestWidget=nil
	for i, comp in ipairs(DWidgetArray) do
		local WidgetPos= comp:K2_GetComponentLocation()
		local WidgetDiffVec=KismetMathLibrary:Subtract_VectorVector(DTracerPos, WidgetPos)
		local WDist= math.sqrt(WidgetDiffVec.x^2+ WidgetDiffVec.y^2+ WidgetDiffVec.z^2)
		if WDist<CurrMaxDist then
			CurrMaxDist=WDist
			CurrNearestWidget=comp
		end
	end
	return CurrNearestWidget
end
local function UntrackTargets()
	local player = api:get_player_controller(0)
	if player==nil then return end
	
	if rThumbLong then
		rThumbLong=false
		player:UnlockTarget()
	end
end	
local function SetTargetLockOnTarget(dpawn,dCurrentTargetInHud)
	
	if dpawn==nil then return end
	
	--print("locked")
	CurrentTrackedTarget = dCurrentTargetInHud
	if  rThumbShort then
		if dpawn.PrimaryWeapons~=nil or dpawn.SecondaryWeapons~=nil then
			dpawn.PrimaryWeapons:SetLockedTarget(CurrentTrackedTarget)
		
			dpawn.SecondaryWeapons:SetLockedTarget(CurrentTrackedTarget)
		end
		rThumbShort=false
	end
	return true
end
local function UpdateWidgetVisibilityOnHover(dpawn)
	if dpawn==nil then return end
	local tempWidgetComps = GetWidgetCompsOnHover(dpawn)
	if #tempWidgetComps > 0 then
		local ClosestWidgetComp = GetClosesetWidgetCompFromArray(TraceComponent, tempWidgetComps)
		if ClosestWidgetComp:GetWidget().OwningActor~=nil  then
			CurrentTargetInHud= ClosestWidgetComp:GetWidget().OwningActor
			SetTargetLockOnTarget(dpawn,CurrentTargetInHud)
			UntrackTargets()
		end
		local Widget= ClosestWidgetComp:GetWidget()
			Widget:SetVisibility(0)
			Widget:SetAnimationCurrentTime(Widget.DetailsFadeIn,0.5)
			if Widget.MarkerDetails~=nil then
				Widget.MarkerDetails:SetVisibility(0)
				if Widget.MarkerDetails.TxtName~=nil then
					Widget.MarkerDetails.TxtName:SetVisibility(0)
				end
			end
	else CurrentTargetInHud=nil 
	end
end	


local function UpdateWidgetVisibilityOnTracked(dpawn)
	if dpawn==nil then return end
	if CurrentTrackedTarget ~=nil then
		local Widget=CurrentTrackedTarget.HUDMarker		
		Widget:SetVisibility(0)
		Widget:SetAnimationCurrentTime(Widget.DetailsFadeIn,0.5)
		Widget.MarkerDetails:SetVisibility(0)
		if Widget.MarkerDetails.TxtName~=nil then
			Widget.MarkerDetails.TxtName:SetVisibility(0)
		end
	end
end




local last_level1
local function ResetHitboxOnLevelChanged()
	local engine = game_engine_class:get_first_object_matching(false)
		if not engine then
			return
		end	
		local viewport = engine.GameViewport	
		if viewport then
			local world = viewport.World			
			if world then
				local level = world.PersistentLevel					
				if last_level1 ~= level then
					
					print("resetted Tracer")
					pcall(function()
						TraceComponent:K2_DestroyComponent()
							
					end)
					TraceComponent	= nil
					CurrentTrackedTarget=nil	
					CurrentTargetInHud=nil
				end
				last_level1 = level
			end
		end
end		




uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)
local pawn= api:get_local_pawn(0)


ResetHitboxOnLevelChanged()
UpdateWidgetVisibilityOnHover(pawn)
CreateTraceComponent(hmd_actor)	
if TraceComponent~=nil  then
	local Overlap_={}
	TraceComponent:GetOverlappingComponents(Overlap_)
	if #Overlap_ > 0 then
		--print(Overlap_[1]:get_full_name())
	end
end
end)

