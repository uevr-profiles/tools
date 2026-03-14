require(".\\Subsystems\\MeleePower")
require(".\\Subsystems\\WeaponAttHandler")
require(".\\Trackers\\Trackers")
require(".\\Subsystems\\UEHelper")
require(".\\Config\\CONFIG")

local IsDebug =false
local DebugCollision=false
local DebugMeleePower=false
local DebugDamage=false
local DebugEnemyMontages=false

--local UnlimitedSuperHotMode=true

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
local RWeaponMesh=nil
local function UpdateWeaponMeshLink(dpawn)
	if dpawn==nil then return end
		RWeaponMesh= dpawn.Gun
end

--local Grunts_C= find_required_object("BlueprintGeneratedClass /Game/Core/Enemies/BP_AI-BaseEnemyCharacter.BP_AI-BaseEnemyCharacter_C")
--local ToDamageActors= UEVR_UObjectHook.get_objects_by_class(Grunts_C,false)
--local DmgTypeClass= find_required_object("Class /Script/Engine.DamageType")
local GameplayStDef= find_required_object("GameplayStatics /Script/Engine.Default__GameplayStatics")
local kismetStringLib= find_static_class("Class /Script/Engine.KismetStringLibrary")
local kismet_system_library= find_static_class("Class /Script/Engine.KismetSystemLibrary")
local kismet_Text_Library= find_static_class("Class /Script/Engine.KismetTextLibrary")
local KismetMathLibrary=find_static_class("Class /Script/Engine.KismetMathLibrary")
--local BoneName=kismetStringLib:Conv_StringToName("Head")
local hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
local reusable_hit_result = StructObject.new(hitresult_c)
--local TextProp = find_required_object("Class /Script/CoreUObject.TextProperty")
local TempVec_C= find_required_object("ScriptStruct /Script/CoreUObject.Vector")
local TempVec = StructObject.new(TempVec_C)
local TempVec2 = StructObject.new(TempVec_C)
TempVec2.X=0
TempVec2.Y=0
TempVec2.Z=0
local TempVec3 = StructObject.new(TempVec_C)
TempVec3.X=1
TempVec3.Y=1
TempVec3.Z=1
local TempVec4 = StructObject.new(TempVec_C)

--TempVec.X=10
--TempVec.Y=20

--local TextObj=StructObject.new(TextProp)

local KillAraray={}
local game_engine_class = find_required_object("Class /Script/Engine.GameEngine")
local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
local viewport = game_engine.GameViewport
local world = viewport.World

local ignore2_actors = {}
local color_c = find_required_object("ScriptStruct /Script/CoreUObject.LinearColor")
local    actor_c = find_required_object("Class /Script/Engine.Actor")
local zero_color = StructObject.new(color_c)
local DamageTaken_C= find_required_object("BPI_DamageTaken_C /Game/Core/Blueprints/BPI_DamageTaken.Default__BPI_DamageTaken_C")

--Classes for melee
--Hitbox
local VHitBoxClass= find_required_object("Class /Script/Engine.BoxComponent")
--Animatoins
local AnimHighRight_Med_C = find_required_object("AnimMontage /Game/Art/Animations/AM_HitHighRight_Med.AM_HitHighRight_Med")
local AnimHighRight_Strong_C = find_required_object("AnimMontage /Game/Art/Animations/AM_HitHighLeft_Left.AM_HitHighLeft_Left")
local AnimHighLeft_weak_C = find_required_object("AnimMontage /Game/Art/Animations/AM_HitHighLeft_Weak.AM_HitHighLeft_Weak")
local AnimHighLeft_Med_C =  find_required_object("AnimMontage /Game/Art/Animations/AM_HitHighLeft_Med.AM_HitHighLeft_Med")
local AnimHighLeft_Strong_C = find_required_object("AnimMontage /Game/Art/Animations/AM_HitHighRight_Right.AM_HitHighRight_Right")
local AnimCenter_weak_c  = find_required_object("AnimMontage /Game/Art/Animations/AM_HitFront_Weak.AM_HitFront_Weak")
local AnimCenter_med_c   = find_required_object("AnimMontage /Game/Art/Animations/AM_HitMidFront_Med.AM_HitMidFront_Med")
local AnimCenter_strong_c= find_required_object("AnimMontage /Game/Art/Animations/AM_HitFront_Hard.AM_HitFront_Hard")

local AnimExec1_c= find_required_object("AnimMontage /Game/Art/Animations/AM_GunExecute-1_VIC.AM_GunExecute-1_VIC")
local AnimExec2_c= find_required_object("AnimMontage /Game/Art/Animations/AM_GunExecute-2_VIC.AM_GunExecute-2_VIC")
local AnimExec3_c= find_required_object("AnimMontage /Game/Art/Animations/AM_GunExecute-3_VIC.AM_GunExecute-3_VIC")
local AnimExecArray= 
{ AnimExec1_c,
	AnimExec2_c,
  AnimExec3_c
}
--Particles
local EmTempl= find_required_object("ParticleSystem /Game/FXVillesBloodVFXPack/Particles/PS_Blood_BulletHit.PS_Blood_BulletHit") --BlootEmitter
--Sounds
local AttenuationSetting= find_required_object("SoundAttenuation /Game/Packs/BallisticsVFX/SFX/Attentuations/ImpactsAttenuation.ImpactsAttenuation")
local AttenuationSettingPlayer= find_required_object("SoundAttenuation /Game/SoundMusic/PlayerSoundAttenuation.PlayerSoundAttenuation")
local SounDConcurrency= find_required_object("SoundConcurrency /Script/Engine.Default__SoundConcurrency")
	 SoundFileSwing1= find_required_object("SoundWave /Game/ProSoundCollection_v1_3/Whooshes/Wavs/whoosh_slow_deep_09.whoosh_slow_deep_09")
	 SoundFileSwing2= find_required_object("SoundWave /Game/ProSoundCollection_v1_3/Whooshes/Wavs/whoosh_swish_med_04.whoosh_swish_med_04")
	 SoundFileSwing3= find_required_object("SoundWave /Game/ProSoundCollection_v1_3/Whooshes/Wavs/whoosh_swish_small_harsh_03.whoosh_swish_small_harsh_03")
	 SoundFileSwing4= find_required_object("SoundWave /Game/ProSoundCollection_v1_3/Whooshes/Wavs/whoosh_swish_small_harsh_01.whoosh_swish_small_harsh_01")
	 SoundFileSwing5= find_required_object("SoundWave /Game/ProSoundCollection_v1_3/Whooshes/Wavs/whoosh_swish_small_harsh_02.whoosh_swish_small_harsh_02")
	 SoundFileSwing6= find_required_object("SoundWave /Game/ProSoundCollection_v1_3/Whooshes/Wavs/whoosh_swish_small_harsh_04.whoosh_swish_small_harsh_04")
	 SoundFileSwing7= find_required_object("SoundWave /Game/ProSoundCollection_v1_3/Whooshes/Wavs/whoosh_swish_small_harsh_05.whoosh_swish_small_harsh_05")

local SoundFileSwingsArray=
{
	 SoundFileSwing1,
	 SoundFileSwing2,
	 SoundFileSwing3,
	 SoundFileSwing4,
	 SoundFileSwing5,
	 SoundFileSwing6,
	 SoundFileSwing7
}
SoundFileFlesh1= find_required_object("SoundWave /Game/Packs/BallisticsVFX/SFX/Impacts/Flesh/Flesh_01.Flesh_01")
	 SoundFileFlesh2= find_required_object("SoundWave /Game/Packs/BallisticsVFX/SFX/Impacts/Flesh/Flesh_02.Flesh_02")
	 SoundFileFlesh3= find_required_object("SoundWave /Game/Packs/BallisticsVFX/SFX/Impacts/Flesh/Flesh_03.Flesh_03")
	 SoundFileFlesh4= find_required_object("SoundWave /Game/Packs/BallisticsVFX/SFX/Impacts/Flesh/Flesh_04.Flesh_04")
	 SoundFileFlesh5= find_required_object("SoundWave /Game/Packs/BallisticsVFX/SFX/Impacts/Flesh/Flesh_05.Flesh_05")

local SoundFileHitArrayFlesh=
{
	 SoundFileFlesh1,
	 SoundFileFlesh2,
	 SoundFileFlesh3,
	 SoundFileFlesh4,
	 SoundFileFlesh5
}
 SoundFilePunchHit1 = find_required_object("SoundWave /Game/SoundMusic/Punch_Blunt_Soft_01.Punch_Blunt_Soft_01")
	 SoundFilePunchHit2 = find_required_object("SoundWave /Game/SoundMusic/Punch_Blunt_Soft_02.Punch_Blunt_Soft_02")
	 SoundFilePunchHit3 = find_required_object("SoundWave /Game/SoundMusic/Punch_Blunt_Soft_03.Punch_Blunt_Soft_03")
	 SoundFilePunchHit4 = find_required_object("SoundWave /Game/SoundMusic/Punch_Bright_Medium_01.Punch_Bright_Medium_01")
	 SoundFilePunchHit5 = find_required_object("SoundWave /Game/SoundMusic/Punch_Bright_Medium_02.Punch_Bright_Medium_02")
	 SoundFilePunchHit6 = find_required_object("SoundWave /Game/SoundMusic/Punch_Bright_Medium_03.Punch_Bright_Medium_03")
	 SoundFilePunchHit7 = find_required_object("SoundWave /Game/SoundMusic/Punch_Bright_Soft_01.Punch_Bright_Soft_01")
	 SoundFilePunchHit8 = find_required_object("SoundWave /Game/SoundMusic/Punch_Bright_Soft_02.Punch_Bright_Soft_02")
local SoundFileHitArrayPunch =
{
	 SoundFilePunchHit1,
	 SoundFilePunchHit2,
	 SoundFilePunchHit3,
	 SoundFilePunchHit4,
	 SoundFilePunchHit5,
	 SoundFilePunchHit6,
	 SoundFilePunchHit7,
	 SoundFilePunchHit8
}
SoundFileKatanaSwing= find_required_object("SoundWave /Game/CLazyAnimpack/Demo/Sound/Wave/Blade_Swing_1.Blade_Swing_1")

SoundFileKatanaHit1= find_required_object("SoundWave /Game/ProSoundCollection_v1_3/Guns_Weapons/Knife_Sword_Pick/Wavs/sword_impact_body.sword_impact_body")
SoundFileKatanaHit2= find_required_object("SoundWave /Game/SoundMusic/Stabs/PM_BB_DESIGNED_CINEMATIC_CHOPS_19.PM_BB_DESIGNED_CINEMATIC_CHOPS_19")
SoundFileKatanaUnsheth= find_required_object("SoundWave /Game/ProSoundCollection_v1_3/Guns_Weapons/Knife_Sword_Pick/Wavs/unsheathe_sword_with_ringout.unsheathe_sword_with_ringout")
SoundFileBatHit1 = find_required_object("SoundWave /Game/ProSoundCollection_v1_3/Punches/Wavs/punch_head_weapon_bat_impact_02.punch_head_weapon_bat_impact_02")
	 SoundFileBatHit2 = find_required_object("SoundWave /Game/ProSoundCollection_v1_3/Punches/Wavs/punch_head_weapon_bat_impact_03.punch_head_weapon_bat_impact_03")
	 SoundFileBatHit3 = find_required_object("SoundWave /Game/ProSoundCollection_v1_3/Punches/Wavs/punch_head_weapon_bat_impact_04.punch_head_weapon_bat_impact_04")
	 SoundFileBatHit4 = find_required_object("SoundWave /Game/ProSoundCollection_v1_3/Punches/Wavs/punch_head_weapon_bat_impact_05.punch_head_weapon_bat_impact_05")
local SoundFileHitArrayBat =
{
	 SoundFileBatHit1,
	 SoundFileBatHit2,
	 SoundFileBatHit3,
	 SoundFileBatHit4
}
	
-- VARS for melee
local BoxCompRH= nil-- api:add_component_by_class(left_hand_actor,VHitBoxClass)		
local BoxCompLH= nil	
local BoxCompGun=nil	
		
		
		
		
		
local StagTimer=0
local Ended=false
local _StaggeringEnemies={}
local _StaggerTimers= {}
local _CurrOverlapsRW= {}
local _CurrOverlapsRH= {}
local _CurrOverlapsLH= {}
local CanHitRW=true
local CanHitRH=true
local CanHitLH=true
local _ToRemoveTimers = {}

local last_level=nil

local function SpawnHitboxes(dpawn)
	if dpawn==nil then return end
	
	if right_hand_actor~=nil   then
		BoxCompLH= api:add_component_by_class(left_hand_actor,VHitBoxClass)
		BoxCompRH= api:add_component_by_class(right_hand_actor,VHitBoxClass)
		
		BoxCompRH:SetGenerateOverlapEvents(true)
		BoxCompRH:SetCollisionResponseToAllChannels(1)
		BoxCompRH:SetCollisionObjectType(1)
		BoxCompRH:SetCollisionEnabled(1) 
		BoxCompRH.RelativeScale3D.X=0.5
		BoxCompRH.RelativeScale3D.Y=0.3
		BoxCompRH.RelativeScale3D.Z=0.3
			BoxCompRH.RelativeLocation.X=4
			BoxCompRH.RelativeLocation.Y=-4
			BoxCompRH.RelativeLocation.Z=-1
		BoxCompLH:SetGenerateOverlapEvents(true)
		BoxCompLH:SetCollisionResponseToAllChannels(1)
		BoxCompLH:SetCollisionObjectType(1)
		BoxCompLH:SetCollisionEnabled(1) 
		BoxCompLH.RelativeScale3D.X=0.5
		BoxCompLH.RelativeScale3D.Y=0.3
		BoxCompLH.RelativeScale3D.Z=0.3
			BoxCompLH.RelativeLocation.X=4
			BoxCompLH.RelativeLocation.Y=-4
			BoxCompLH.RelativeLocation.Z=-1
		
		BoxCompGun= api:add_component_by_class(right_hand_actor,VHitBoxClass)
		BoxCompGun:SetGenerateOverlapEvents(true)
		BoxCompGun:SetCollisionResponseToAllChannels(1)
		BoxCompGun:SetCollisionObjectType(1)
		BoxCompGun:SetCollisionEnabled(1) 
		BoxCompGun.RelativeScale3D.X=0.05
		BoxCompGun.RelativeScale3D.Y=0.05
		BoxCompGun.RelativeScale3D.Z=0.2
		BoxCompGun.RelativeLocation.X=0
		BoxCompGun.RelativeLocation.Y=0
		BoxCompGun.RelativeLocation.Z=0	
		
			
	end
end
local TempEmitter1=nil
local TempEmitter2=nil
local TempEmitter3=nil
local function SpawnEmitter(dpawn)
		TempEmitter1=GameplayStDef:SpawnEmitterAtLocation(world,EmTempl,TempVec2,dpawn:K2_GetActorRotation(),TempVec3,false,2,true)
		TempEmitter1:SetActive(false,false)
		--TempEmitter1:Deactivate()
		TempEmitter2=GameplayStDef:SpawnEmitterAtLocation(world,EmTempl,TempVec2,dpawn:K2_GetActorRotation(),TempVec3,false,2,true)
		TempEmitter2:SetActive(false,false)
		--TempEmitter2:Deactivate()
		TempEmitter3=GameplayStDef:SpawnEmitterAtLocation(world,EmTempl,TempVec2,dpawn:K2_GetActorRotation(),TempVec3,false,2,true)
		TempEmitter3:SetActive(false,false)
		--TempEmitter3:Deactivate()
end
local EmitterState=1
local TempEmitTimer1=0
local TempEmitTimer2=0
local TempEmitTimer3=0
local Temp2Active=false
local Temp3Active=false
local Temp1Active=false
local function SpawnBlood(TargetActor)
	if EmitterState==1 then
		TempEmitter1:K2_SetWorldLocation(TargetActor:K2_GetActorLocation(),false,reusable_hit_result,true)
		TempEmitter1:SetActive(true,true)
		--TempEmitter1:Activate()
		TempEmitTimer1=0
		Temp1Active=true
		EmitterState=2
	elseif EmitterState==2 then
		TempEmitter2:K2_SetWorldLocation(TargetActor:K2_GetActorLocation(),false,reusable_hit_result,true)
		TempEmitter2:SetActive(true,true)
		--TempEmitter2:Activate()
		TempEmitTimer2=0
		Temp2Active=true
		
		EmitterState=3
	elseif EmitterState==3 then
		TempEmitter2:K2_SetWorldLocation(TargetActor:K2_GetActorLocation(),false,reusable_hit_result,true)
		TempEmitter2:SetActive(true,true)
		--TempEmitter2:Activate()
		TempEmitTimer3=0
		Temp3Active=true
		EmitterState=1
	end
end

local function UpdateEMitterTimer(delta)
	if Temp1Active then
		TempEmitTimer1=TempEmitTimer1+delta
	end
	if Temp2Active then
		TempEmitTimer2=TempEmitTimer2+delta
	end
	if Temp3Active then
		TempEmitTimer3=TempEmitTimer3+delta
	end
	
	if TempEmitTimer1>1.5 then
		Temp1Active=false
		TempEmitter1:SetActive(false,false)
		TempEmitter1:Deactivate()
	end
	if TempEmitTimer2>1.5 then
		Temp2Active=false
		TempEmitter2:SetActive(false,false)
		TempEmitter2:Deactivate()
	end
	if TempEmitTimer3>1.5 then
		Temp3Active=false
		TempEmitter3:SetActive(false,false)
		TempEmitter3:Deactivate()
	end
end

local function ResetHitboxOnLevelChanged(dpawn)
	local engine = game_engine_class:get_first_object_matching(false)
		if not engine then
			return
		end
	
		local viewport = engine.GameViewport
	
		if viewport then
			local world = viewport.World
	
			if world then
				local level = world.PersistentLevel
	
				
					
				if last_level ~= level then
					
					if dpawn~=nil then
						if BoxCompRH~=nil then
							BoxCompLH:K2_DestroyComponent()
							BoxCompRH:K2_DestroyComponent()
							BoxCompGun:K2_DestroyComponent()
						end
						if TempEmitter1~=nil then
							TempEmitter1:K2_DestroyComponent()
						    TempEmitter2:K2_DestroyComponent()
						    TempEmitter3:K2_DestroyComponent()
						end
						SpawnHitboxes(dpawn)
						SpawnEmitter(dpawn)
					end
					
					
				end
	
				last_level = level
			end
		end
end


local function GetRandomArrayElement(Array)
	local Result = Array[math.random(#Array)]
	return Result
end


--local WeaponModifier=2
local function GetWeaponModifier(dpawn)
	local WeaponModifier=1.5
	--local WeaponSlot= dpawn.SecondaryWeapon
	if dpawn.SecondaryWeapon==nil then
		WeaponModifier=1.5--:get_full_name() 
		return WeaponModifier
	end
	if string.find(dpawn.SecondaryWeapon:get_full_name() , "Bat") then
		WeaponModifier=2.2
		return WeaponModifier
	elseif string.find(dpawn.SecondaryWeapon:get_full_name() , "Katana") then
		WeaponModifier=3.5
		return WeaponModifier
	else 
		WeaponModifier=1.5
		return WeaponModifier
	end
end



local function GetHitVector(dpawn,Enemy)
	--if dpawn == nil then return end
	
	local MeshLocation1 = RWeaponMesh:K2_GetComponentLocation()
	if dpawn.SecondaryWeapon~=nil and not dpawn.PrimaryEquipped then
		MeshLocation1 = RWeaponMesh:K2_GetComponentLocation() + RWeaponMesh:GetUpVector()*40
	end
	local endPos1= Enemy:K2_GetActorLocation()
	TempVec.X = (endPos1.X-MeshLocation1.X)
	TempVec.Y = (endPos1.Y-MeshLocation1.Y)
	local NormFac= math.sqrt(TempVec.X^2+TempVec.Y^2)
	TempVec.X = TempVec.X/NormFac * PosDiffWeaponHand
	TempVec.Y = TempVec.Y/NormFac * PosDiffWeaponHand
	return TempVec
end

local function GetHitVectorLH(dpawn,Enemy)
	--if dpawn == nil then return end
	local MeshLocation1 = left_hand_component:K2_GetComponentLocation()
	local endPos1= Enemy:K2_GetActorLocation()
	TempVec.X = (endPos1.X-MeshLocation1.X) 
	TempVec.Y = (endPos1.Y-MeshLocation1.Y)
	local NormFac= math.sqrt(TempVec.X^2+TempVec.Y^2)
	TempVec.X = TempVec.X/NormFac * PosDiffSecondaryHand
	TempVec.Y = TempVec.Y/NormFac * PosDiffSecondaryHand
	
	
	return TempVec
end

local function GetRotEnemyHitLocation(dpawn,Enemy,Handindex)
	local EnemyTransform= Enemy:GetTransform()
	local HitVector = TempVec4
	if Handindex==1 then
		if dpawn.SecondaryWeapon==nil or dpawn.PrimaryEquipped then
			HitVector= KismetMathLibrary:Subtract_VectorVector(right_hand_component:K2_GetComponentLocation(), Enemy:K2_GetActorLocation())
		elseif dpawn.SecondaryWeapon~=nil and not dpawn.PrimaryEquipped then
			HitVector= KismetMathLibrary:Subtract_VectorVector(right_hand_component:K2_GetComponentLocation()+right_hand_component:GetUpVector()*40, Enemy:K2_GetActorLocation())
		end
	elseif Handindex==2 then
		HitVector= KismetMathLibrary:Subtract_VectorVector(left_hand_component:K2_GetComponentLocation(), Enemy:K2_GetActorLocation())
	end
	local HitDirection= KismetMathLibrary:Conv_VectorToRotator(HitVector)
	local ReturnRotation = KismetMathLibrary:InverseTransformRotation(EnemyTransform, HitDirection).Yaw
	return ReturnRotation
end

local function EnableMeleeCollisionOnWeapons(WMesh)
	if WMesh ==nil then return end
	--Weapon
	WMesh:SetCollisionEnabled(1)
	WMesh:SetGenerateOverlapEvents(true)
	WMesh:SetCollisionResponseToAllChannels(1)
	
	--Hands
	
end

local DebugEnemy= nil

local RWeaponHolstered=false

local VecLCLast  = TempVec
local VecRCLast  = TempVec
local VecHCLast  = TempVec

local function GetMoveRotatorL()
	TempVec4  =KismetMathLibrary:Subtract_VectorVector(VecLCLast,left_hand_component:K2_GetComponentLocation())
	local RotLC  =KismetMathLibrary:Conv_VectorToRotator(TempVec4)
	return RotLC
end
local function GetMoveRotatorR()
	TempVec4  =KismetMathLibrary:Subtract_VectorVector(VecRCLast,right_hand_component:K2_GetComponentLocation())	
	local RotRC  =KismetMathLibrary:Conv_VectorToRotator(TempVec4)
	return RotRC
end
local function GetMoveRotatorH()	
	TempVec4 =KismetMathLibrary:Subtract_VectorVector(hmd_component:K2_GetComponentLocation()		,VecHCLast)
	local RotHC  =KismetMathLibrary:Conv_VectorToRotator(TempVec4)
	return RotHC
end

	
local VecTick=0
local function UpdLastVector()
	VecTick=VecTick+1
	if VecTick >10 then
		VecLCLast= left_hand_component:K2_GetComponentLocation()
        VecRCLast= right_hand_component:K2_GetComponentLocation()
        VecHCLast= hmd_component:K2_GetComponentLocation()
		VecTick=0
	end
end	


		
local function GetHitAnimation(Handindex,dEnemy,dpawn)--0=head, 1=rightHand, 2=left Hand
	local HitDeltaAngle=0
	local Str= 0
	HitDeltaAngle= GetRotEnemyHitLocation(dpawn,dEnemy,Handindex)
	
	if Handindex==1 then
		
							
		Str= PosDiffWeaponHand
	elseif Handindex==2 then
		
		Str=PosDiffSecondaryHand
	end
	
	local AnimMontage=AnimHighRight_Med_C
	
	if HitDeltaAngle>20 then
		if Str<35 then
			AnimMontage=AnimHighLeft_weak_C
		elseif Str < 70 and Str>=35 then
			AnimMontage=AnimHighRight_Med_C
		else AnimMontage=AnimHighLeft_Strong_C
		end
		print(HitDeltaAngle)
		print(AnimMontage:get_full_name())
		return AnimMontage
	elseif HitDeltaAngle<20 and HitDeltaAngle>-20 then
		if Str<35 then
			AnimMontage=AnimCenter_weak_c
		elseif Str < 70 and Str>=35 then
			AnimMontage=AnimCenter_med_c
		else AnimMontage=AnimCenter_strong_c
		end
		print(HitDeltaAngle)
		print(AnimMontage:get_full_name())
		return AnimMontage
	elseif HitDeltaAngle<-20 then
		if Str<35 then
			AnimMontage=AnimHighRight_Med_C
		else AnimMontage=AnimHighRight_Strong_C
		end
		print(HitDeltaAngle)
		print(AnimMontage:get_full_name())
		return AnimMontage
	end
	
end	
local CanSwingL=true
local CanSwingR=true


local function PlaySwingSound(dpawn)
	if dpawn==nil then return end
	
	if PosDiffSecondaryHand>50 and CanSwingL then
		CanSwingL=false
		GameplayStDef:PlaySoundAtLocation(world,GetRandomArrayElement(SoundFileSwingsArray),dpawn:K2_GetActorLocation(),dpawn:K2_GetActorRotation(),(3),2,0,AttenuationSettingPlayer,SounDConcurrency,dpawn)
	end
	if PosDiffWeaponHand>50 and CanSwingR then
		CanSwingR=false
		if dpawn.SecondaryWeapon~=nil then
			if not string.find(dpawn.SecondaryWeapon:get_full_name() , "Katana") then
				GameplayStDef:PlaySoundAtLocation(world,GetRandomArrayElement(SoundFileSwingsArray),dpawn:K2_GetActorLocation(),dpawn:K2_GetActorRotation(),(3),2,0,AttenuationSettingPlayer,SounDConcurrency,dpawn)
				
			elseif  not dpawn.PrimaryEquipped and string.find(dpawn.SecondaryWeapon:get_full_name() , "Katana") then
				GameplayStDef:PlaySoundAtLocation(world,SoundFileKatanaUnsheth,dpawn:K2_GetActorLocation(),dpawn:K2_GetActorRotation(),3,2,0,AttenuationSetting,SounDConcurrency,dpawn)
				GameplayStDef:PlaySoundAtLocation(world,SoundFileKatanaSwing,dpawn:K2_GetActorLocation(),dpawn:K2_GetActorRotation(),2.5,2,0,AttenuationSettingPlayer,SounDConcurrency,dpawn)
			end
		end
	end
	
	if not CanSwingL and PosDiffSecondaryHand< 10 then
		CanSwingL=true
	end
	if not CanSwingR and PosDiffWeaponHand< 10 then
		CanSwingR=true
	end
end

local CanThrow=false
local MaxThrowIntensity=0
local ThrowInteinsityToUse=0	
local IsThrowPrep=false
local IsThrow=false

local function ThrowWeapon(Dpawn)
	if Dpawn==nil then return end
	
	if Dpawn.SecondaryWeapon~=nil and not Dpawn.PrimaryEquipped and (string.find(Dpawn.SecondaryWeapon:get_full_name(),"Katana") or string.find(Dpawn.SecondaryWeapon:get_full_name(),"Bat")) then
		
		CanThrow = true
	else CanThrow=false
	end
	if CanThrow and RTrigger>100 then	
		IsThrowPrep=true
	end
	if IsThrowPrep then
		if PosDiffWeaponHand/150 > MaxThrowIntensity then
			MaxThrowIntensity= PosDiffWeaponHand/150 
		end
	end
	if IsThrowPrep and RTrigger==0 then
		ThrowInteinsityToUse=MaxThrowIntensity
		MaxThrowIntensity=0
		IsThrowPrep=false
		IsThrow=true
	end
	if IsThrow and PosDiffWeaponHand< 15 then
		--ThrowDelta=ThrowDelta+delta
		Dpawn:call("Throw Held Object", 11111)
		ThrowInteinsityToUse=0
		IsThrow=false
		
	end
end
local BTReset=true
local TimeDilation=0.01
local TimeDilationW=0.01
local function UpdateSuperHotMode(Dpawn,DWorld,DDelta)
	if Dpawn==nil or not SuperHotSlowMotion then return end
	if UnlimitedSuperHotMode then
		Dpawn.CurrentStamina=100
	end
	local IsBulletTime= Dpawn.BulletTimeActive
	
	local MaxDilation = math.max(PosDiffWeaponHand, PosDiffSecondaryHand)/28
	if IsBulletTime then
		BTReset=false
		if TimeDilationW ~= MaxDilation then
			if TimeDilationW < MaxDilation then
				TimeDilationW=TimeDilationW+DDelta*3
			elseif TimeDilationW >= MaxDilation then
				TimeDilationW=TimeDilationW-DDelta*2
			end
		end
		--TimeDilation= MaxDilation
		if TimeDilation>2 then
			TimeDilation=2
		end
		if TimeDilationW>1 then
			TimeDilationW=1
		end
		if TimeDilation < 0.05 then
			TimeDilation=0.05
		end
		if TimeDilationW< 0.05 then
			TimeDilationW=0.05
		end
		Dpawn.CustomTimeDilation=2
		GameplayStDef:SetGlobalTimeDilation(DWorld,TimeDilationW)
		
	else 
		if BTReset==false then		
			Dpawn.CustomTimeDilation=1
			GameplayStDef:SetGlobalTimeDilation(DWorld,1)
			BTReset=true
		end
	end
	if Dpawn.CurrentStamina<5 then
		GameplayStDef:SetGlobalTimeDilation(DWorld,1)
		Dpawn.CustomTimeDilation=1
	end
	--print(MaxDilation)
	--print(TimeDilation)
	--print("  ")	print("  ")print("  ")	print("  ")	print("  ")
end
	


local IsExecuting=false
local ExecutedEnemy=nil
local DidShootWhileExecuting=false

local function ApplyDamageToActor(Dpawn)
	if Dpawn == nil  then return end
	--RightHandWeapon
	CanGrabEnemyR=false
	CanGrabEnemyL=false
	if not RWeaponHolstered then
		local _LastHitCompRW = {}
		local DidHitRW = false
		_CurrOverlapsRW= {}
		RWeaponMesh:GetOverlappingComponents(_CurrOverlapsRW) 
		
			for i, comp in ipairs(_CurrOverlapsRW) do
				--print(comp:get_full_name())
				if string.find(comp:GetOwner():get_full_name(),"AI") then
					CanGrabEnemyR=true
					table.insert(_LastHitCompRW,comp)
					--print(comp:GetOwner():get_full_name())
					local Damage1 = PosDiffWeaponHand/100*GetWeaponModifier(Dpawn)
					--print(PosDiffWeaponHand/100)
					local Enemy = comp:GetOwner()
					if Enemy.Health>0 and CanHitRW and  PosDiffWeaponHand>20 and not IsGrabbingR  then
						if DebugEnemy==nil and DebugEnemyMontages then
							DebugEnemy=Enemy
						end
						local PreHealth= Enemy.Health
						if DebugDamage then
							print(comp:GetOwner():get_full_name())
							print("RW   "..  Damage1)
						end	
						Enemy.Health= PreHealth - Damage1
						 SpawnBlood(Enemy)
						--if Enemy.Health>0 then
							local CurMontage= Enemy:GetCurrentMontage()
							--print(CurMontage:get_full_name())
							if CurMontage~= nil then
								if not string.find(CurMontage:get_full_name(), "Block") then
									Enemy:StopAnimMontage(CurMontage)
									Enemy:PlayAnimMontage(GetHitAnimation(1,Enemy,Dpawn),1.0,kismetStringLib:Conv_StringToName("Start"))
								elseif string.find(CurMontage:get_full_name(), "Block") and Dpawn.SecondaryWeapon~=nil and not Dpawn.PrimaryEquipped then
									Enemy:StopAnimMontage(CurMontage)
									Enemy:PlayAnimMontage(GetHitAnimation(1,Enemy,Dpawn),1.0,kismetStringLib:Conv_StringToName("Start"))
								 
								end
							else 
								Enemy:PlayAnimMontage(GetHitAnimation(1,Enemy,Dpawn),1.0,kismetStringLib:Conv_StringToName("Start"))
							end
							--if PosDiffWeaponHand*5<8 then
								
							if Dpawn.SecondaryWeapon~=nil then
								if string.find(Dpawn.SecondaryWeapon:get_full_name() , "Bat") and not Dpawn.PrimaryEquipped then
								GameplayStDef:PlaySoundAtLocation(world,GetRandomArrayElement(SoundFileHitArrayBat),Dpawn:K2_GetActorLocation(),Dpawn:K2_GetActorRotation(),3,2,0,AttenuationSetting,SounDConcurrency,Dpawn)
								
								elseif string.find(Dpawn.SecondaryWeapon:get_full_name() , "Katana") and not Dpawn.PrimaryEquipped  then
								--GameplayStDef:PlaySoundAtLocation(world,SoundFileKatanaUnsheth,Dpawn:K2_GetActorLocation(),Dpawn:K2_GetActorRotation(),3,2,0,AttenuationSetting,SounDConcurrency,Dpawn)
								GameplayStDef:PlaySoundAtLocation(world,GetRandomArrayElement(SoundFileHitArrayFlesh),Dpawn:K2_GetActorLocation(),Dpawn:K2_GetActorRotation(),3,2,0,AttenuationSetting,SounDConcurrency,Dpawn)
								GameplayStDef:PlaySoundAtLocation(world,SoundFileKatanaHit2,Dpawn:K2_GetActorLocation(),Dpawn:K2_GetActorRotation(),math.random(2,3),2,0,AttenuationSetting,SounDConcurrency,Dpawn)
								else GameplayStDef:PlaySoundAtLocation(world,GetRandomArrayElement(SoundFileHitArrayFlesh),Dpawn:K2_GetActorLocation(),Dpawn:K2_GetActorRotation(),3,2,0,AttenuationSetting,SounDConcurrency,Dpawn)
								end
							else GameplayStDef:PlaySoundAtLocation(world,GetRandomArrayElement(SoundFileHitArrayPunch),Dpawn:K2_GetActorLocation(),Dpawn:K2_GetActorRotation(),3,2,0,AttenuationSetting,SounDConcurrency,Dpawn)
								GameplayStDef:PlaySoundAtLocation(world,GetRandomArrayElement(SoundFileHitArrayFlesh),Dpawn:K2_GetActorLocation(),Dpawn:K2_GetActorRotation(),3,2,0,AttenuationSetting,SounDConcurrency,Dpawn)
							end
								--PhysicalStagger(GetHitVectorLH(Dpawn,Enemy))
							--elseif PosDiffWeaponHand <15 then
							--
							--	Enemy:PlayAnimMontage(AnimHighRight_weak_C,1.0,kismetStringLib:Conv_StringToName("Start"))
							--else Enemy:PlayAnimMontage(AnimHighRight_Strong_C,1.0,kismetStringLib:Conv_StringToName("Start"))
							--end
						--end				
						--table.insert(_StaggeringEnemies, Enemy)
						--table.insert(_StaggerTimers, 1.5)
						--CanHit=false
						DidHitRW=true
					elseif IsGrabbingR and PosDiffWeaponHand>50 and Enemy.Health<3 then 
						Enemy:StopAnimMontage(CurMontage)
						Enemy:PlayAnimMontage(GetRandomArrayElement(AnimExecArray),1.0,kismetStringLib:Conv_StringToName("Start"))
					end
					if Enemy.Health<=0 then
						Enemy:EnemyDeath(GetHitVector(Dpawn,Enemy),false,var)
					--else Enemy:PhysicalStagger(GetHitVector(Dpawn,Enemy))
					end
				end
			end
		if #_LastHitCompRW == 0  then
			CanHitRW=true
		elseif DidHitRW then
			CanHitRW=false
		end
	--RightHand
	elseif RWeaponHolstered then
		if BoxCompRH~=nil then
			local _LastHitCompRH = {}
			local DidHitRH=false
			_CurrOverlapsRH= {}
			BoxCompRH:GetOverlappingComponents(_CurrOverlapsRH) 
			
				for i, comp in ipairs(_CurrOverlapsRH) do
					--print(comp:get_full_name())
					if string.find(comp:GetOwner():get_full_name(),"AI") then
						CanGrabEnemyR=true
						table.insert(_LastHitCompRH,comp)
						--print(comp:GetOwner():get_full_name())
						local Damage1 = PosDiffWeaponHand/100*1.5
						--print(PosDiffWeaponHand/100)
						local Enemy = comp:GetOwner()
						if Enemy.Health>0 and CanHitRH and PosDiffWeaponHand>20  and not IsGrabbingR then
							
							if DebugDamage then
								print(comp:GetOwner():get_full_name())
								print("RH   "..  Damage1)
							end	
							local PreHealth= Enemy.Health
							
							Enemy.Health= PreHealth - Damage1
							 SpawnBlood(Enemy)
							--if Enemy.Health>0 then
								local CurMontage= Enemy:GetCurrentMontage()
							--print(CurMontage:get_full_name())
							if CurMontage~= nil then
								if not string.find(CurMontage:get_full_name(), "Block") then
									Enemy:StopAnimMontage(CurMontage)
									Enemy:PlayAnimMontage(GetHitAnimation(1,Enemy,Dpawn),1.0,kismetStringLib:Conv_StringToName("Start"))
								
								end
							end
							
								--PhysicalStagger(GetHitVectorLH(Dpawn,Enemy))
								GameplayStDef:PlaySoundAtLocation(world,GetRandomArrayElement(SoundFileHitArrayPunch),Dpawn:K2_GetActorLocation(),Dpawn:K2_GetActorRotation(),3,2,0,AttenuationSetting,SounDConcurrency,Dpawn)
								GameplayStDef:PlaySoundAtLocation(world,GetRandomArrayElement(SoundFileHitArrayFlesh),Dpawn:K2_GetActorLocation(),Dpawn:K2_GetActorRotation(),3,2,0,AttenuationSetting,SounDConcurrency,Dpawn)
							--	Enemy:PhysicalStagger(GetHitVectorLH(Dpawn,Enemy))				
							--end				
							--table.insert(_StaggeringEnemies, Enemy)
							--table.insert(_StaggerTimers, 1.5)
							--CanHit=false
							DidHitRH=true
						end
						if Enemy.Health<=0 then
							Enemy:EnemyDeath(GetHitVector(Dpawn,Enemy),false,var)
						--else Enemy:PhysicalStagger(GetHitVector(Dpawn,Enemy))
						end
					end
				end
			if #_LastHitCompRH == 0  then
				CanHitRH=true
			elseif DidHitRH then
				CanHitRH=false
			end
		end
	end
	--LeftHand
	if BoxCompLH~=nil then
		local _LastHitCompLH = {}
		local DidHitLH= false
		CanReload=false
		_CurrOverlapsLH= {}
		BoxCompLH:GetOverlappingComponents(_CurrOverlapsLH) 
		
			for i, comp in ipairs(_CurrOverlapsLH) do
				--print(comp:get_full_name())
				if comp==BoxCompGun and not IsGrabbingL and not lShoulder and not IsExecuting then
					CanReload=true
				end
				if string.find(comp:GetOwner():get_full_name(),"AI") then
					if not IsExecuting then
						CanGrabEnemyL=true
					end
					table.insert(_LastHitCompLH,comp)
					--print(comp:GetOwner():get_full_name())
					local Damage1 = PosDiffSecondaryHand/100*1.5
					--print(PosDiffSecondaryHand/100)
					local Enemy = comp:GetOwner()
					if Enemy.Health>0 and CanHitLH and PosDiffSecondaryHand>20 and not IsGrabbingL  then
						local PreHealth= Enemy.Health
						if DebugDamage then
							print(comp:GetOwner():get_full_name())
							print("LH   "..  Damage1)
						end
						Enemy.Health= PreHealth - Damage1
						 SpawnBlood(Enemy)
						--if Enemy.Health>0 then
						local CurMontage= Enemy:GetCurrentMontage()
							--print(CurMontage:get_full_name())
						if CurMontage~= nil then
								if not string.find(CurMontage:get_full_name(), "Block") then
									Enemy:StopAnimMontage(CurMontage)
								end
						end
						--if PosDiffSecondaryHand*5<5 then
								Enemy:PlayAnimMontage(GetHitAnimation(2,Enemy,Dpawn),1.0,kismetStringLib:Conv_StringToName("Start"))
								GameplayStDef:PlaySoundAtLocation(world,GetRandomArrayElement(SoundFileHitArrayPunch),Dpawn:K2_GetActorLocation(),Dpawn:K2_GetActorRotation(),3,2,0,AttenuationSetting,SounDConcurrency,Dpawn)
								GameplayStDef:PlaySoundAtLocation(world,GetRandomArrayElement(SoundFileHitArrayFlesh),Dpawn:K2_GetActorLocation(),Dpawn:K2_GetActorRotation(),3,2,0,AttenuationSetting,SounDConcurrency,Dpawn)
								
								--PhysicalStagger(GetHitVectorLH(Dpawn,Enemy))
						--elseif PosDiffSecondaryHand <10 then
							
						--	Enemy:PlayAnimMontage(AnimHighLeft_Med_C,1.0,kismetStringLib:Conv_StringToName("Start"))
						--else Enemy:PlayAnimMontage(AnimHighLeft_Strong_C,1.0,kismetStringLib:Conv_StringToName("Start"))
						--end
							--Enemy:PhysicalStagger(GetHitVectorLH(Dpawn,Enemy))				
						--end
						--table.insert(_StaggeringEnemies, Enemy)
						--table.insert(_StaggerTimers, 1.5)
						--CanHit=false
						DidHitLH=true
					elseif LTrigger>0 and Enemy:GetCurrentMontage() ~=nil and not string.find(Enemy:GetCurrentMontage():get_full_name(),"Block" ) then
						IsCounter=true
					elseif IsGrabbingL and PosDiffSecondaryHand>40 and Enemy.Health<3 then 
						CanGrabEnemyL=false
						IsExecuting=true
						Enemy:StopAnimMontage(CurMontage)
						Enemy:PlayAnimMontage(GetRandomArrayElement(AnimExecArray),1.0,kismetStringLib:Conv_StringToName("Start"))	
						
						ExecutedEnemy=Enemy
						
					end
					if Enemy.Health<=0 then
						Enemy:EnemyDeath(GetHitVectorLH(Dpawn,Enemy),false,var)
					
					end
				end
			end
		if #_LastHitCompLH == 0 then
			CanHitLH=true
		elseif DidHitLH then
			CanHitLH=false
		end
	end
	if IsExecuting then
		if RTrigger>100 then
			DidShootWhileExecuting=true
		end
		if ExecutedEnemy~=nil then
			if not ExecutedEnemy.IsDead then	
				if ExecutedEnemy:GetCurrentMontage() ~=nil then
					if not string.find(ExecutedEnemy:GetCurrentMontage():get_full_name(),"Execute")  then
						IsExecuting=false
						--ExecutedEnemy=nil
						if DidShootWhileExecuting then
							Dpawn:call("Add Ammo",1)
							DidShootWhileExecuting=false
						end
					end
				else
					IsExecuting=false	
					if DidShootWhileExecuting then
								Dpawn:call("Add Ammo",1)
					DidShootWhileExecuting=false
					end
				end
			end	
		end	
	end
end



	
local function UpdateStaggerTimers(pawn,delta)
	if pawn==nil then return end
	
	if #_StaggeringEnemies > 0 then
		for i, StagComp in ipairs(_StaggeringEnemies) do
			_StaggerTimers[i]= _StaggerTimers[i]-delta
			if _StaggerTimers[i]<=0 then
				StagComp:EndStagger()
				table.insert(_ToRemoveTimers,i)
			end
		end
		for j,RemoveComp in ipairs(_ToRemoveTimers) do
			table.remove(_StaggeringEnemies, RemoveComp)
			table.remove(_StaggerTimers, RemoveComp)
		end
	end
	
end	




	if DebugMeleePower then
		print(PosDiffWeaponHand*10)
	end
	if DebugCollision and BoxCompLH~=nil then
				BoxCompRH.bHiddenInGame=false
				BoxCompLH.bHiddenInGame=false
				
	elseif not DebugCollision and BoxCompLH~=nil then
				BoxCompRH.bHiddenInGame=true
				BoxCompLH.bHiddenInGame=true
	end


--GameplayStDef:PlaySoundAtLocation(world,GetRandomArrayElement(SoundFileSwingsArray),pawn:K2_GetActorLocation(),pawn:K2_GetActorRotation(),5,2,0,AttenuationSettingPlayer,SounDConcurrency,pawn)

uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)
if IsDebug then
	if DebugMeleePower then
			print(PosDiffWeaponHand)
	end
	if DebugCollision and BoxCompLH~=nil then
					BoxCompRH.bHiddenInGame=false
					BoxCompLH.bHiddenInGame=false
					
		elseif not DebugCollision and BoxCompLH~=nil  and BoxCompRH~=nil then
					BoxCompRH.bHiddenInGame=true
					BoxCompLH.bHiddenInGame=true
	end
	if DebugEnemy~=nil then
		if DebugEnemy:GetCurrentMontage()~=nil then
			print(DebugEnemy:GetCurrentMontage():get_full_name())
		end
	end
end

--print(KismetMathLibrary:InverseTransformRotation
--		(	hmd_component:K2_GetComponentToWorld(),KismetMathLibrary:Conv_VectorToRotator
--			(	KismetMathLibrary:Subtract_VectorVector
--				(	right_hand_component:K2_GetComponentLocation(),hmd_component:K2_GetComponentLocation()
--				)
--			)
--		).Yaw
--	)



pawn= api:get_local_pawn(0)
UpdLastVector()
UpdateWeaponMeshLink(pawn)

ResetHitboxOnLevelChanged(pawn)

if pawn~=nil then
EnableMeleeCollisionOnWeapons(RWeaponMesh)
ApplyDamageToActor(pawn)
UpdateStaggerTimers(pawn,delta)
end
ThrowWeapon(pawn)
UpdateEMitterTimer(delta)
PlaySwingSound(pawn)
UpdateSuperHotMode(pawn,world,delta)
end)


--AnimMontages for Stagger:
--AnimMontage /Game/Art/Animations/AM_HitHighRight_Med.AM_HitHighRight_Med