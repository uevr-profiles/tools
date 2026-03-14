

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

 local Key_C= find_required_object("ScriptStruct /Script/InputCore.Key")
 TempKey = StructObject.new(Key_C)
 --Temphitresult = StructObject.new(hitresult_c)

local SoldierArr_C = find_required_object("Class /Script/Test_C.IRRTeamComponent")
local SoldierArr= UEVR_UObjectHook.get_objects_by_class(SoldierArr_C,false)

local BaseChar_C = find_required_object("Class /Script/Test_C.IRRBaseCharacter")
local BaseChar = UEVR_UObjectHook.get_objects_by_class(BaseChar_C,false)

local wantedID = nil
for i, comp in ipairs(SoldierArr) do
	if comp:get_outer().Controller~=nil and wantedID ==nil then
			wantedID=i
	
	end
end	  
--player.Tags={}--:AddItem("test")
player.TeamId.TeamId=1
print(SoldierArr[wantedID]:get_outer():get_full_name())
      SoldierArr[wantedID]:get_outer().Controller.TeamId.TeamId=2
     -- SoldierArr[1]:OnCharacterAdded(pawn)
	  local pawnLoc= pawn:K2_GetActorLocation() + Vector3d.new(200,0,10)
	  local pawnLoc2 = pawn:K2_GetActorLocation() + Vector3d.new(-200,0,10)
	  SoldierArr[wantedID]:get_outer():K2_SetActorLocation(pawnLoc,false,{},true)
	  SoldierArr[wantedID]:OnCharacterRemoved(pawn)
	  SoldierArr[wantedID]:OnCharacterAdded(pawn)
	print(SoldierArr[wantedID]:get_outer():ActorHasTag("TargetActor"))
	print(#SoldierArr) 
	  
for i, comp in ipairs(SoldierArr) do
	--if comp.Controller~=nil then
	--comp.Controller.TeamId.TeamId = 0
	--end
	--comp.Role=0
	--print("hey")
	if  comp~= SoldierArr[wantedID] and comp:get_outer()~=pawn and string.find(comp:get_outer():get_full_name(),"Default") then 
		--print("hey")
		--print(SoldierArr[i]:get_outer():get_full_name())
	
	end
end	  

for d, compd in ipairs(BaseChar) do
	if not string.find(compd:get_full_name(), "Default") and compd~=pawn then
		SoldierArr[wantedID]:OnCharacterAdded(compd)
		SoldierArr[wantedID]:get_outer().Controller.TargetTrackerComponent:GetOrCreateTarget(compd,true)
		SoldierArr[wantedID]:get_outer().Controller.BehaviorComponent:TargetTagUpdated(compd,{},true)
	end	
	
end			
--	  SoldierArr[wantedID]:get_outer().Controller.TargetTrackerComponent:GetOrCreateTarget(BaseChar[5],true)
	  
--pcall(function()	  
--local testObj= find_required_object("IRRAITarget /Game/Maps/Gameplay/LVL_Quarry.LVL_Quarry.PersistentLevel.BP_BaseAIController_Patrol_C_2147425686.IRRAITarget_2147423120")

--if 	testObj~=nil then
		local Target = BaseChar[22]
	--SoldierArr[wantedID]:get_outer().Controller.BehaviorComponent.ActiveTarget=Target--
	--	SoldierArr[wantedID]:get_outer().Controller.TargetTrackerComponent:GetOrCreateTarget(Target,true)
	--	SoldierArr[wantedID]:get_outer().FactionTag.TagName = "RedFOR"
		--SoldierArr[wantedID]:get_outer().UPSPatrol:UpdateMovementPatrolPoint(pawn)
	--	local CurrInTarget= SoldierArr[wantedID]:get_outer().Controller.BehaviorComponent:GetCurrentTarget()
	--	local test ={RedFOR}
	--	SoldierArr[wantedID]:get_outer().Controller.BehaviorComponent:TargetTagUpdated(CurrInTarget, test, true)
--		SoldierArr[wantedID]:get_outer().Controller.BehaviorComponent.ActiveBehaviour.TagName = "AI.Stance.Attacking"
		--print(#test)
		--print(testObj.TargetData.GameplayTags)
		--testObj.TargetData.GameplayTags=nil
	--	print(testObj:get_outer().Character:get_full_name())
--		Target:K2_SetActorLocation(pawnLoc2,false,{},true)
		
local Manager_C= find_required_object("BlueprintGeneratedClass /Game/Blueprints/AI/BP_AI_Manager.BP_AI_Manager_C",false)
local ManagerAr= UEVR_UObjectHook.get_objects_by_class(Manager_C,false)
local Manager = ManagerAr[1]
--Manager:RegisterPlayerPawn(SoldierArr[wantedID]:get_outer())
--end

--end)	  
local MontageFP = find_required_object("AnimMontage /Game/Animations/UE5/FP/AK/Arm/PRO_Mag_762x39_30rd/AM_FP_AK74M_PRO_Mag_762x39_30rd_Reload_Tactical_MagOut_UE5.AM_FP_AK74M_PRO_Mag_762x39_30rd_Reload_Tactical_MagOut_UE5")
local WeaponAnim = find_required_object("AnimMontage /Game/Animations/UE5/FP/AK/Weapon/30rnd/AM_WEP_AK74M_30rnd_Mag_Out.AM_WEP_AK74M_30rnd_Mag_Out")
local CharMontage = {}
local Monrage_C = find_required_object("ScriptStruct /Script/Test_C.CharacterMontageSet")
local Monrage = StructObject.new(Monrage_C)

Monrage.FP_Animation= MontageFP
Monrage.TP_Animation= MontageFP
Monrage.Weapon_Animation= WeaponAnim

pawn.BP_MontageComponent:PlayCharacterMontage_MC(pawn.WeaponInHands:get_outer(),"Combat","None",		 Monrage,1.0,true,true ) 
pawn.BP_MontageComponent:PlayCharacterMontage_Networked(pawn.WeaponInHands:get_outer(),"Combat","None",	 Monrage,1.0,true,true ) 
pawn.BP_MontageComponent:PlayCharacterMontage_Server(pawn.WeaponInHands:get_outer(),"Combat","None",	 Monrage,1.0,true,true ) 
--pawn:PlayAnimMontage(MontageFP,1.0,"Start")


uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)
	local dpawn=nil
	dpawn=api:get_local_pawn(0)

end)



local FireTick=0
local CooldownDelta=0

uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)
player= api:get_player_controller(0)
pawn= api:get_local_pawn(0)

--local AimLoc=SoldierArr[wantedID]:get_outer().Controller.AimComponent.AimData.AimLocation
--local TarLoc=SoldierArr[wantedID]:get_outer().Controller.AimComponent.AimData.RealTargetLocation
--
--local Diff = math.sqrt((AimLoc.X-TarLoc.X)^2+ (AimLoc.Y-TarLoc.Y)^2 + (AimLoc.Z-TarLoc.Z^2))
--print(Diff)
pawn.BP_MontageComponent:PlayCharacterMontage_MC(pawn.WeaponInHands:get_outer(),"Combat","None",		 Monrage,1.0,false,false ) 

--if Diff<100 and FireTick<1 then 
--	FireTick=FireTick+1
--	--SoldierArr[wantedID]:get_outer().Controller.AimComponent:StartAiming()
--	SoldierArr[wantedID]:get_outer().WeaponInHands:StartFiringWeapon_Networked()
--elseif CooldownDelta<1 then 
--	CooldownDelta=CooldownDelta+delta
--	
--else
--	CooldownDelta=0
--	FireTick=0
--end	
	

end)