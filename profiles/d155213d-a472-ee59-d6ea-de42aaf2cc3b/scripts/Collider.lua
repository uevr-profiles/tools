require(".\\Subsystems\\UEHelper")
local controllers = require('libs/controllers')
local api = uevr.api
local hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
local reusable_hit_result1 = StructObject.new(hitresult_c)


uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)
	local pawn= api:get_local_pawn(0)
local FrontArray={}	
local FrontLeg=pawn.FrontLegPhysicCollider
local Mesh = pawn.m_visual

if pawn~=nil and Mesh~=nil and FrontLeg~=nil and FirstCatMode~= 1 then	
	local hasYTargetFromOverlap=false
	local DistanceToComp = 100
	--FrontLeg:SetCollisionResponseToAllChannels(2)
	--pawn.FrontLegPhysicCollider:GetOverlappingComponents(FrontArray)
	--local FrontLegLoc= FrontLeg:K2_GetComponentLocation()
	--for i, comp in ipairs(FrontArray) do
	--	--print(comp:get_full_name())
	--	if not string.find(comp:get_full_name(),"Interaction") then
	--		print(comp:get_full_name())
	--		hasYTargetFromOverlap=true
	--		local CompLoc= comp:K2_GetComponentLocation()
	--		DistanceToComp = math.sqrt((FrontLegLoc.X-CompLoc.X)^2+(FrontLegLoc.Y-CompLoc.Y)^2+(FrontLegLoc.Z-CompLoc.Z)^2)
	--		print(DistanceToComp)	
	--	end
	--end
	
	
	
	local RightController = controllers.getController(1)
	local TraceStart = KismetMathLibrary:Add_VectorVector(RightController:K2_GetComponentLocation(), RightController:GetForwardVector()*5)
	local TraceEnd = KismetMathLibrary:Add_VectorVector(RightController:K2_GetComponentLocation(),   RightController:GetForwardVector()*100)--RightController:GetForwardVector()*200)
	local bTraceComplex=true
	local bShowTrace=true
	local bPersistent=false
	local HitLoc={}
	local HitNormal={}
	local BoneName={}
	local HitComp ={}	
	local ActorsIgn={pawn}
	local color={}
	

	test=KismetSystemLibrary:LineTraceSingle(world,TraceStart,TraceEnd,24,bTraceComplex,ActorsIgn,bShowTrace,reusable_hit_result1,true, color, color,0)
	
	  local bBlockingHit = 0
      local bInitialOverlap = 0
      local Time = 0
      local Distance = 0
      local Location = {}
      local ImpactPoint = {}
      local Normal = {}
      local ImpactNormal = {}
      local PhysMat = {}
      local HitActor = {}
      local HitComponent = {}
      local HitBoneName = {}
      local HitItem = 0
      local ElementIndex = 0
      local FaceIndex = 0
      --local TraceStart = {}
      --local TraceEnd = {}
	
	
	
	
	local Break = GameplayStDef:BreakHitResult(reusable_hit_result1,  bBlockingHit, bInitialOverlap, Time, Distance, Location, ImpactPoint, Normal, ImpactNormal, PhysMat, HitActor, HitComponent, HitBoneName, HitItem, ElementIndex, FaceIndex, TraceStart, TraceEnd)
	
	
	
	if HitComponent.result~=nil then
		local HitComp= HitComponent.result:get_full_name()
		local Dist = reusable_hit_result1.Distance
		--print(HitComp)
		--print(reusable_hit_result1.Distance)
		--local testmat = find_required_object("MaterialInstanceConstant /Game/Data/Props/Plastic_Can/MI_Plastic_Can_B_Grey.MI_Plastic_Can_B_Grey")
		--testmat.BasePropertyOverrides.BlendMode=0
		if (
		(string.find(  HitComp,"Wood_Collision") 
		or string.find(HitComp,"Pushable")
		or string.find(HitComp,"Door_B2")) 
		
		and Dist < 20) 
		
		or (hasYTargetFromOverlap and DistanceToComp<20)  then
			isYTargetInFront=true
		else
			isYTargetInFront=false
		end
	end
	--print(isYTargetInFront)
	
	
	
end
end)