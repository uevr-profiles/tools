require(".\\Subsystems\\Helper")
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

local SpeedVec= StructObject.new(Vec3d_C)


--needed Classes


	

--global variables

--HitWidgetComps={}	
	
--global Functions



local function CalculateDistanceToTarget(dpawn)
	if dpawn==nil then return end
	if CurrentTargetInHud==nil then return end
	local DIst=	dpawn:GetDistanceTo(CurrentTargetInHud)
	return DIst
end

local function GetPlayerSpeedVec(dpawn)
	if dpawn==nil then return end
	local Speed= dpawn.PawnLinearVelocity
	SpeedVec.X= Speed.X 
	SpeedVec.Y= Speed.Y
	SpeedVec.Z= Speed.Z
	return SpeedVec
end

local function GetTargetSpeedVector(dCurrentTrackedTarget)
	if dpawn==nil then return end
	local Speed= dCurrentTrackedTarget.PawnLinearVelocity
	
	SpeedVec.x= Speed.X 
	SpeedVec.y= Speed.Y
	SpeedVec.z= Speed.Z
	return SpeedVec
end

local function GetWeaponSpeed(dpawn)
	if dpawn==nil then return 500000 end
	local pawnForwardVector = dpawn:GetActorForwardVector()
	if dpawn.PrimaryWeapons ==nil then return 500000 end
	local WeaponINstance = dpawn.PrimaryWeapons:GetFirstEquippedWeaponInstance()
	print(WeaponINstance:get_full_name())
	local WeaponConfig = WeaponINstance.WeaponConfig
	local WeaponItem = WeaponConfig.WeaponItem
	
	local Attribute = WeaponItem:GetAttribute(KismetStringLibrary:Conv_StringToName("weapon_velocity"))
	--local Vel= WeaponINstance:GetVelocity()
	--local Velabs= math.sqrt(Vel.X^2+ Vel.Y^2+ Vel.Z^2)
	--print(Velabs)
	if Attribute == nil then return 1500000 end
	local Speed = WeaponItem:GetAttribute(KismetStringLibrary:Conv_StringToName("weapon_velocity")).Value.BaseValue
	--local SpeedVec = (pawnForwardVector * Speed)
	return Speed
end

local function GetDeltaTimeTillHit(dpawn, dTargLoc, dTargVel,dCurrentTrackedTarget)
	if dpawn==nil then return end
	local pawnLoc = dpawn:K2_GetActorLocation()
	local WSpeed= GetWeaponSpeed(dpawn)
	--local TopDiff= 			dTargLoc.X - pawnLoc.X	--(KismetMathLibrary:Subtract_VectorVector(pawnLoc,dTargLoc))
	--local ActDiff=			(KismetMathLibrary:Subtract_VectorVector(pawnLoc,dTargLoc))
	--local ActDiffLength= 		math.sqrt(ActDiff.X^2+ ActDiff.Y^2+ ActDiff.Z^2)
	local Dist2= dpawn:GetDistanceTo(dCurrentTrackedTarget)
	--print("Distance   " .. Dist2)
	local Time= Dist2 / WSpeed
	--print("Time1   " .. Time)
	--local ExtraLocation= KismetMathLibrary:Add_VectorVector(dTargLoc, dTargVel*Time)
	--local ExtraDiff= (KismetMathLibrary:Subtract_VectorVector(pawnLoc,ExtraLocation))
	--local FinalTime = math.sqrt(ExtraDiff.X^2+ ExtraDiff.Y^2+ ExtraDiff.Z^2) /  WSpeed
	
	return Time
end

function GetPredictedTargetLocation(dpawn, dCurrentTrackedTarget)
	if dpawn==nil then return nil end
	if dCurrentTrackedTarget~=nil then
		if dCurrentTrackedTarget.PawnLinearVelocity==nil then return nil end
		--local Dist2= dpawn:GetDistanceTo(dCurrentTrackedTarget)
		--print("Distance   " .. Dist2)
		local TargLoc= dCurrentTrackedTarget:K2_GetActorLocation()
		
		local TarVelocity= dCurrentTrackedTarget.PawnLinearVelocity
		local Time = GetDeltaTimeTillHit(dpawn,TargLoc,TarVelocity,dCurrentTrackedTarget)
		--print("Time2    " .. Time)
		local FinalLocation= KismetMathLibrary:Add_VectorVector(TargLoc, TarVelocity * Time)
		return FinalLocation
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
					
				
										
				end
				last_level1 = level
			end
		end
end		




uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)
--local pawn= api:get_local_pawn(0)
--if pawn.PrimaryWeapons~=nil then
	--local CurrLockedTarget = pawn.PrimaryWeapons:GetLockedTarget()
--	if CurrLockedTarget~=nil and CurrLockedTarget.PrimaryWeapons~=nil then
		--Loc=GetPredictedTargetLocation(pawn, CurrLockedTarget)
	--end
--end

end)

