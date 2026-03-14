
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

local ftransform_c = find_required_object("ScriptStruct /Script/CoreUObject.Transform")
	local temp_transform = StructObject.new(ftransform_c)
local Grunts_C= find_required_object("BlueprintGeneratedClass /Game/Core/Enemies/BP_AI-BaseEnemyCharacter.BP_AI-BaseEnemyCharacter_C")
local ToDamageActors= UEVR_UObjectHook.get_objects_by_class(Grunts_C,false)
local DmgTypeClass= find_required_object("Class /Script/Engine.DamageType")
local GameplayStDef= find_required_object("GameplayStatics /Script/Engine.Default__GameplayStatics")
local kismetStringLib= find_static_class("Class /Script/Engine.KismetStringLibrary")
local kismet_system_library= find_static_class("Class /Script/Engine.KismetSystemLibrary")
local kismet_Text_Library= find_static_class("Class /Script/Engine.KismetTextLibrary")
local BoneName=kismetStringLib:Conv_StringToName("Head")
local hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
local reusable_hit_result = StructObject.new(hitresult_c)
local TextProp = find_required_object("Class /Script/CoreUObject.TextProperty")
local TempVec_C= find_required_object("ScriptStruct /Script/CoreUObject.Vector")
local TempVec = StructObject.new(TempVec_C)
TempVec.X=10
TempVec.Y=20
local TempVec2 = StructObject.new(TempVec_C)
TempVec2.X=0
TempVec2.Y=0
TempVec2.Z=0
local TempVec3 = StructObject.new(TempVec_C)
TempVec3.X=10
TempVec3.Y=10
TempVec3.Z=10


--local TextObj=StructObject.new(TextProp)
local KillAraray={}
local game_engine_class = find_required_object("Class /Script/Engine.GameEngine")
local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
		local viewport = game_engine.GameViewport
		local world = viewport.World
local MeshLocation1 = pawn.Gun:K2_GetComponentLocation()
local endPos1= MeshLocation1 + pawn.Gun:GetForwardVector()*8051
local ignore2_actors = {}
local color_c = find_required_object("ScriptStruct /Script/CoreUObject.LinearColor")
local    actor_c = find_required_object("Class /Script/Engine.Actor")
local zero_color = StructObject.new(color_c)
local DamageTaken_C= find_required_object("BPI_DamageTaken_C /Game/Core/Blueprints/BPI_DamageTaken.Default__BPI_DamageTaken_C")
local EmTempl= find_required_object("ParticleSystem /Game/FXVillesBloodVFXPack/Particles/PS_Blood_BulletHit.PS_Blood_BulletHit")
local Txt=kismet_Text_Library:Conv_StringToText("Bullets")
local SoundFileSwing= find_required_object("SoundWave /Game/CLazyAnimpack/Demo/Sound/Wave/Blade_Swing_1.Blade_Swing_1")
local SoundFileFlesh= find_required_object("SoundWave /Game/ProSoundCollection_v1_3/Whooshes/Wavs/whoosh_swish_small_harsh_03.whoosh_swish_small_harsh_03")
local AttenuationSetting= find_required_object("SoundAttenuation /Game/Packs/BallisticsVFX/SFX/Attentuations/ImpactsAttenuation.ImpactsAttenuation")
local SounDConcurrency= find_required_object("SoundConcurrency /Script/Engine.Default__SoundConcurrency")

print(Txt)
local DeathMontage= find_required_object("AnimMontage /Game/Art/Animations/AM_KatanaExecute-1_VIC.AM_KatanaExecute-1_VIC")
--pawn:DamageActor(15, Vector3d.new(0,0,0), Vector3d.new(140000,140000.2,100000.3), Vector3d.new(140000,140000,140000),false,pawn,true,BoneName,1,Txt,nil,pawn.TakenDamageStruct.HitResult_36_01452866434402B11B4130B5152EB7A0)
local DmGTaken= pawn.TakenDamageStruct.KillArray_40_E62CFA65450242A77F6D3B83256ADDA6
local BLoodSplatter_C= find_required_object("ParticleSystem /Game/Packs/BallisticsVFX/Particles/Impacts/DynamicImpacts/Flesh/Blood_cloud_Dyn.Blood_cloud_Dyn")
	local hit1 = kismet_system_library:LineTraceSingle(world, MeshLocation1, endPos1, 0, true, ignore2_actors, 0, reusable_hit_result, true, zero_color, zero_color, 10.0)

		for i, comp in ipairs(ToDamageActors) do
			--if not string.find(comp:get_full_name(),"Default") then
					--GameplayStDef:ApplyDamage(comp,0,pawn,pawn,DmgTypeClass,var1)
					--comp:EnemyDeath(TempVec,true,var)
				--	comp.StaggerTimeline:Play()
					--comp:PhysicalStagger(TempVec)
					--comp:EnemyDamaged__DelegateSignature()
					pawn.SecondaryWeapon:WeaponHitEnemy(comp, true)
					--comp:ReceiveAnyDamage(1,DmgTypeClass,nil,nil)
					--comp:SpawnBloodPool(1.1)
				--		comp:OnHit()
					--comp:CanInstaExecute(true)	
			--		pawn:AttemptGunExecute(comp)
					--comp:PlayAnimMontage(DeathMontage,1.0,kismetStringLib:Conv_StringToName("Start"))
			--comp:AddComponent(kismetStringLib:Conv_StringToName("ParticleSystem /Game/FXVillesBloodVFXPack/Particles/PS_Blood_BulletHit.PS_Blood_BulletHit"),false, temp_transform,nil,false)
		--	endpawn:K2_GetActorLocation(
		end
		--Check=GameplayStDef:SpawnEmitterAtLocation(world,EmTempl,pawn:K2_GetActorLocation(),pawn:K2_GetActorRotation(),TempVec3,false,2,true)
		--Check:SetActive(true,true)
		--Check:Activate()
		GameplayStDef:PlaySoundAtLocation(world,SoundFileFlesh,pawn:K2_GetActorLocation(),pawn:K2_GetActorRotation(),5,2,0,AttenuationSetting,SounDConcurrency,pawn)
		--			print(Check:get_full_name())
local StagTimer=0
local Ended=false


--GameplayStDef:ApplyDamage(pawn,1,nil,nil,DmgTypeClass,var1)	
uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)

--Check:ReceiveTick()
--Check:SetActive(true,true)
		--Check:Activate()

StagTimer=StagTimer+delta
if StagTimer >=1 and Ended== false then
for i, comp in ipairs(ToDamageActors) do
			--if not string.find(comp:get_full_name(),"Default") then
					--GameplayStDef:ApplyDamage(comp,10.0001,pawn,pawn,DmgTypeClass,var1)
					--comp:EnemyDeath(TempVec,true,var)
					if StagTimer<=1 then
				--	comp:StaggerTimeline__UpdateFunc()
					end
					
						comp:EndStagger()
						Ended=true
					
end
end
--local DmGTaken= pawn.TakenDamageStruct.		--HitResult_36_01452866434402B11B4130B5152EB7A0  --_40_E62CFA65450242A77F6D3B83256ADDA6
--local Txt= DmGTaken[5]--.DamageSource_30_72F62D6047FFDF3234AD6D9925B9DF4B
--print(DmGTaken)
--player:AddBodyRecoil(5)
end)