require(".\\Subsystems\\UEHelper")
local controllers = require('libs/controllers')
local api = uevr.api
local hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
local reusable_hit_result1 = StructObject.new(hitresult_c)
uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)
	local pawn= api:get_local_pawn(0)
local FrontArray={}	
if pawn~=nil then	
	local FrontLeg=pawn.FrontLegPhysicCollider
	--pawn.FrontLegPhysicCollider:GetOverlappingComponents(FrontArray)
	--FrontLeg:SetCollisionResponseToAllChannels(2)
	local RightController = controllers.getController(1)
	local TraceStart = FrontLeg:K2_GetComponentLocation()
	local TraceEnd = KismetMathLibrary:Add_VectorVector(FrontLeg:K2_GetComponentLocation(), RightController:GetForwardVector()*200)
	local bTraceComplex=true
	local bShowTrace=false
	local bPersistent=false
	local HitLoc={}
	local HitNormal={}
	local BoneName={}
	local HitComp ={}	
	local ActorsIgn={pawn}
	local color={}
	

	test=KismetSystemLibrary:LineTraceSingle(world,TraceStart,TraceEnd,0,bTraceComplex,ActorsIgn,bShowTrace,reusable_hit_result1,true, color, color,0)
	
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
	
	--for i, comp in ipairs(FrontArray) do
	--	print(comp:get_full_name())
	--end
	if HitComponent.result~=nil then
		print(HitComponent.result:get_full_name())
	end
	
end
end)