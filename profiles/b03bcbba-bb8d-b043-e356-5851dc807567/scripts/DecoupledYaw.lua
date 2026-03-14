require(".\\Shared\\Global")

	local api = uevr.api
	
	local params = uevr.params
	local callbacks = params.sdk.callbacks
	local pawn = api:get_local_pawn(0)
	local CurrentPressAngle =nil
	local StickEuler={x,y,z}
	local ConvertedAngle={1,0,0,0}
	--local e2= vec3.new(e2.x,e2.y,e2.z)
	
	
	
	
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
local kismet_string_library = find_static_class("Class /Script/Engine.KismetStringLibrary")
local kismet_math_library = find_static_class("Class /Script/Engine.KismetMathLibrary")
local kismet_system_library = find_static_class("Class /Script/Engine.KismetSystemLibrary")
local Statics = find_static_class("Class /Script/Engine.GameplayStatics")
local finalQuad={}








--	-----------TEST
--	-----------TEST
--	-----------TEST
--	-----------TEST
--	-----------TEST
--	
--	local game_engine_class = find_required_object("Class /Script/Engine.GameEngine")
--	local actor_c = find_required_object("Class /Script/Engine.Actor")
--	local motion_controller_component_c = find_required_object("Class /Script/HeadMountedDisplay.MotionControllerComponent")
--	local scene_component_c = find_required_object("Class /Script/Engine.SceneComponent")
--	
--	local hmd_actor = nil -- The purpose of the HMD actor is to accurately track the HMD's world transform
--	local left_hand_actor = nil
--	local right_hand_actor = nil
--	local left_hand_component = nil
--	local right_hand_component = nil
--	local hmd_component = nil
--	local last_level = nil
--	
--	local ftransform_c = find_required_object("ScriptStruct /Script/CoreUObject.Transform")
--	local temp_transform = StructObject.new(ftransform_c)
--	
--	local function spawn_actor(world_context, actor_class, location, collision_method, owner)
--		temp_transform.Translation = location
--		temp_transform.Rotation.W = 1.0
--		temp_transform.Scale3D = Vector3f.new(1.0, 1.0, 1.0)
--	
--		local actor = Statics:BeginDeferredActorSpawnFromClass(world_context, actor_class, temp_transform, collision_method, owner)
--	
--		if actor == nil then
--			print("Failed to spawn actor")
--			return nil
--		end
--	
--		Statics:FinishSpawningActor(actor, temp_transform)
--		print("Spawned actor")
--	
--		return actor
--	end
--	
--	local function reset_hand_actors()
--		-- We are using pcall on this because for some reason the actors are not always valid
--		-- even if exists returns true
--		if left_hand_actor ~= nil and UEVR_UObjectHook.exists(left_hand_actor) then
--			pcall(function()
--				if left_hand_actor.K2_DestroyActor ~= nil then
--					left_hand_actor:K2_DestroyActor()
--				end
--			end)
--		end
--	
--		if right_hand_actor ~= nil and UEVR_UObjectHook.exists(right_hand_actor) then
--			pcall(function()
--				if right_hand_actor.K2_DestroyActor ~= nil then
--					right_hand_actor:K2_DestroyActor()
--				end
--			end)
--		end
--	
--		if hmd_actor ~= nil and UEVR_UObjectHook.exists(hmd_actor) then
--			pcall(function()
--				if hmd_actor.K2_DestroyActor ~= nil then
--					hmd_actor:K2_DestroyActor()
--				end
--			end)
--		end
--	
--		left_hand_actor = nil
--		right_hand_actor = nil
--		hmd_actor = nil
--		right_hand_component = nil
--		left_hand_component = nil
--	end
--	
--	local function spawn_hand_actors()
--		local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
--	
--		local viewport = game_engine.GameViewport
--		if viewport == nil then
--			print("Viewport is nil")
--			return
--		end
--	
--		local world = viewport.World
--		if world == nil then
--			print("World is nil")
--			return
--		end
--	
--		reset_hand_actors()
--	
--		local pawn = api:get_local_pawn(0)
--	
--		if pawn == nil then
--			--print("Pawn is nil")
--			return
--		end
--	
--		local pos = pawn:K2_GetActorLocation()
--	
--		left_hand_actor = spawn_actor(world, actor_c, pos, 1, nil)
--	
--		if left_hand_actor == nil then
--			print("Failed to spawn left hand actor")
--			return
--		end
--	
--		right_hand_actor = spawn_actor(world, actor_c, pos, 1, nil)
--	
--		if right_hand_actor == nil then
--			print("Failed to spawn right hand actor")
--			return
--		end
--	
--		hmd_actor = spawn_actor(world, actor_c, pos, 1, nil)
--	
--		if hmd_actor == nil then
--			print("Failed to spawn hmd actor")
--			return
--		end
--	
--		print("Spawned hand actors")
--	
--		-- Add scene components to the hand actors
--		left_hand_component = api:add_component_by_class(left_hand_actor, motion_controller_component_c)
--		right_hand_component = api:add_component_by_class(right_hand_actor, motion_controller_component_c)
--		hmd_component = api:add_component_by_class(hmd_actor, scene_component_c)
--	
--		if left_hand_component == nil then
--			print("Failed to add left hand scene component")
--			return
--		end
--	
--		if right_hand_component == nil then
--			print("Failed to add right hand scene component")
--			return
--		end
--	
--		if hmd_component == nil then
--			print("Failed to add hmd scene component")
--			return
--		end
--	
--		left_hand_component.MotionSource = kismet_string_library:Conv_StringToName("Left")
--		right_hand_component.MotionSource = kismet_string_library:Conv_StringToName("Right")
--	
--		-- Not all engine versions have the Hand property
--		if left_hand_component.Hand ~= nil then
--			left_hand_component.Hand = 0
--			right_hand_component.Hand = 1
--		end
--	
--		print("Added scene components")
--	
--		-- The HMD is the only one we need to add manually as UObjectHook doesn't support motion controller components as the HMD
--		local hmdstate = UEVR_UObjectHook.get_or_add_motion_controller_state(hmd_component)
--	
--		if hmdstate then
--			hmdstate:set_hand(2) -- HMD
--			hmdstate:set_permanent(true)
--		end
--	
--		print(string.format("%x", left_hand_actor:get_address()) .. " " .. string.format("%x", right_hand_actor:get_address()) .. " " .. string.format("%x", hmd_actor:get_address()))
--	end
--	
--	local function reset_hand_actors()
--		-- We are using pcall on this because for some reason the actors are not always valid
--		-- even if exists returns true
--		if left_hand_actor ~= nil and UEVR_UObjectHook.exists(left_hand_actor) then
--			pcall(function()
--				if left_hand_actor.K2_DestroyActor ~= nil then
--					left_hand_actor:K2_DestroyActor()
--				end
--			end)
--		end
--	
--		if right_hand_actor ~= nil and UEVR_UObjectHook.exists(right_hand_actor) then
--			pcall(function()
--				if right_hand_actor.K2_DestroyActor ~= nil then
--					right_hand_actor:K2_DestroyActor()
--				end
--			end)
--		end
--	
--		if hmd_actor ~= nil and UEVR_UObjectHook.exists(hmd_actor) then
--			pcall(function()
--				if hmd_actor.K2_DestroyActor ~= nil then
--					hmd_actor:K2_DestroyActor()
--				end
--			end)
--		end
--	
--		left_hand_actor = nil
--		right_hand_actor = nil
--		hmd_actor = nil
--	end
--	
--	local function reset_hand_actors_if_deleted()
--		if left_hand_actor ~= nil and not UEVR_UObjectHook.exists(left_hand_actor) then
--			left_hand_actor = nil
--			left_hand_component = nil
--		end
--	
--		if right_hand_actor ~= nil and not UEVR_UObjectHook.exists(right_hand_actor) then
--			right_hand_actor = nil
--			right_hand_component = nil
--		end
--	
--		if hmd_actor ~= nil and not UEVR_UObjectHook.exists(hmd_actor) then
--			hmd_actor = nil
--			hmd_component = nil
--		end
--	end
--	
--	local function on_level_changed(new_level)
--		-- All actors can be assumed to be deleted when the level changes
--		print("Level changed")
--		if new_level then
--			print("New level: " .. new_level:get_full_name())
--		end
--		left_hand_actor = nil
--		right_hand_actor = nil
--		left_hand_component = nil
--		right_hand_component = nil
--	end
--	
--	uevr.sdk.callbacks.on_pre_engine_tick(function(engine_voidptr, delta)
--		local engine = game_engine_class:get_first_object_matching(false)
--		if not engine then
--			return
--		end
--	
--		local viewport = engine.GameViewport
--	
--		if viewport then
--			local world = viewport.World
--	
--			if world then
--				local level = world.PersistentLevel
--	
--				if last_level ~= level then
--					on_level_changed(level)
--				end
--	
--				last_level = level
--			end
--		end
--	
--		reset_hand_actors_if_deleted()
--	
--		if left_hand_actor == nil or right_hand_actor == nil then
--			spawn_hand_actors()
--		end
--	end)
--	
--	-- Use Vector3d if this is a UE5 game (double precision)
--	local last_rot = Vector3f.new(0, 0, 0)
--	local last_pos = Vector3f.new(0, 0, 0)
--	
--	uevr.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
--		-- This is the real game render rotation before any VR modifications
--		if view_index == 1 then
--			last_rot = Vector3f.new(rotation.x, rotation.y, rotation.z)
--			last_pos = Vector3f.new(position.x, position.y, position.z)
--		end
--	end)
--	
--	uevr.sdk.callbacks.on_post_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
--		if view_index ~= 1 then
--			return
--		end
--	
--		if hmd_component == nil then
--			return
--		end
--	
--		-- You can opt for a quaternion here if you want using the kismet math library.
--		local hmdrot = hmd_component:K2_GetComponentRotation()
--		local rotdelta = hmdrot - last_rot
--	
--		-- Fix up the rotation delta
--		if rotdelta.x > 180 then
--			rotdelta.x = rotdelta.x - 360
--		elseif rotdelta.x < -180 then
--			rotdelta.x = rotdelta.x + 360
--		end
--	
--		if rotdelta.y > 180 then
--			rotdelta.y = rotdelta.y - 360
--		elseif rotdelta.y < -180 then
--			rotdelta.y = rotdelta.y + 360
--		end
--	
--		if rotdelta.z > 180 then
--			rotdelta.z = rotdelta.z - 360
--		elseif rotdelta.z < -180 then
--			rotdelta.z = rotdelta.z + 360
--		end
--	
--		-- Apply this rotation delta to a camera actor, or a control rotation of some sort
--		
--		-- Recenter view
--		vr.recenter_view()
--	end)
--	
--	uevr.sdk.callbacks.on_script_reset(function()
--		print("Resetting")
--	
--		reset_hand_actors()
--	end)
--	
--	
--	----test----
--	----test----
--	----test----
--	----test----
--	----test----
--	----test----






function PositiveIntegerMask(text)
	return text:gsub("[^%-%d]", "")
end



local rotator_c = api:find_uobject("ScriptStruct /Script/CoreUObject.FVector")
--local testrotato= Vector3f.new(X, Y, Z) 
local DecoupledYawCurrentRot = 0
local RXState=0
local SnapAngle
local SnapTurn=false

local function UpdateSnapTurn()
	if string.sub(uevr.params.vr:get_mod_value("VR_SnapTurn"),1,1) == "f" then
		SnapTurn=false
	elseif string.sub(uevr.params.vr:get_mod_value("VR_SnapTurn"),1,1) == "t" then
		SnapTurn=true
	end
end

uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)


--Read Gamepad stick input for rotation compensation
	local ThumbLX = state.Gamepad.sThumbLX
	local ThumbLY = state.Gamepad.sThumbLY
	local ThumbRX = state.Gamepad.sThumbRX
	local ThumbRY = state.Gamepad.sThumbRY
	--print(ThumbX .." and " .. ThumbY)
	
	--local RotationOffset= math.acos(ThumbX/(math.sqrt(ThumbX^2 + ThumbY^2)))
	
	--if ThumbY >=0 then
	--	CurrentPressAngle = (-RotationOffset*180/math.pi) 
	--	--print(CurrentPressAngle)
	--	
	--else
	--CurrentPressAngle =-(360-RotationOffset*180/math.pi)
	--	--print(CurrentPressAngle)
	--end
	--if string.sub(uevr.params.vr:get_mod_value("VR_SnapturnTurnAngle"),3,3) == " " then
	--		SnapAngle= string.sub(uevr.params.vr:get_mod_value("VR_SnapturnTurnAngle"),1,2)
	--elseif string.sub(uevr.params.vr:get_mod_value("VR_SnapturnTurnAngle"),3,3) ~= " " then
	--		SnapAngle= string.sub(uevr.params.vr:get_mod_value("VR_SnapturnTurnAngle"),1,3)
	--end

	SnapAngle = PositiveIntegerMask(uevr.params.vr:get_mod_value("VR_SnapturnTurnAngle"))
	if SnapTurn then
		if ThumbRX >200 and RXState ==0 then
			DecoupledYawCurrentRot=DecoupledYawCurrentRot + SnapAngle
			RXState=1
		elseif ThumbRX <-200 and RXState ==0 then
			DecoupledYawCurrentRot=DecoupledYawCurrentRot - SnapAngle
			RXState=1
		elseif ThumbRX <= 200 and ThumbRX >=-200 then
			RXState=0
		end
 
	--testrotato.Y= CurrentPressAngle


		--RotationOffset
	--ConvertedAngle= kismet_math_library:Quat_MakeFromEuler(testrotato)
	--print("x: " .. ConvertedAngle.X .. "     y: ".. ConvertedAngle.Y .."     z: ".. ConvertedAngle.Z .. "     w: ".. ConvertedAngle.W)

	else
		
		SmoothTurnRate = PositiveIntegerMask(uevr.params.vr:get_mod_value("VR_SnapturnTurnAngle"))/90
	--print(state.Gamepad.sThumbRX)
	
		local rate = state.Gamepad.sThumbRX/32767
					rate =  rate*rate*rate
		if ThumbRX >2200  then
			DecoupledYawCurrentRot=DecoupledYawCurrentRot + SmoothTurnRate * rate
			
		elseif ThumbRX <-2200  then
			DecoupledYawCurrentRot=DecoupledYawCurrentRot + SmoothTurnRate * rate
		
		end
	end


end)


--	uevr.sdk.callbacks.on_pre_engine_tick(
--	function(engine, delta)
--	
--		pawn = api:get_local_pawn(0)
--	-- Motion Compensation
--		PlayerMesh=pawn.Mesh
--		
	--UEVR_UObjectHook.get_or_add_motion_controller_state(PlayerMesh):set_hand(2)
	--UEVR_UObjectHook.get_or_add_motion_controller_state(PlayerMesh):set_rotation_offset(Vector4f.new(-ConvertedAngle.W,0,ConvertedAngle.Y,0))	
--	end)


local State= 0
--Decoupled yaw


uevr.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
	local prevalueY= rotation.y
	pawn = api:get_local_pawn(0)
	if isDriving==false then	
	
	
		rotation.y = DecoupledYawCurrentRot
		local finalposition= pawn.RootComponent:K2_GetComponentLocation()+ pawn.RootComponent:GetUpVector()*80 --pawn.RootComponent:K2_GetComponentLocation() - pawn.RootComponent:GetRightVector()*45 + pawn.RootComponent:GetUpVector()*120 +pawn.RootComponent:GetForwardVector()*20
		if isMenu==false then
			position.x=finalposition.x
			position.y=finalposition.y
			position.z=finalposition.z
		end
	else
		local RotZ=	pawn.RootComponent:K2_GetComponentRotation().y
		rotation.y = RotZ
		local finalposition= pawn.Mesh:GetSocketLocation("steering_wheel")+ pawn.RootComponent:GetUpVector()*40 -pawn.RootComponent:GetForwardVector()*40--pawn.RootComponent:K2_GetComponentLocation() - pawn.RootComponent:GetRightVector()*45 + pawn.RootComponent:GetUpVector()*120 +pawn.RootComponent:GetForwardVector()*20
		position.x=finalposition.x
		position.y=finalposition.y
		position.z=finalposition.z
	end
end)


--CutsceneScript
uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)

UpdateSnapTurn()
	
	--local params = uevr.params
	--local callbacks = params.sdk.callbacks
	

	
	--print(State)
	-- in menu?
	--print(pawn.PlayerState:GetTickableWhenPaused())
	--testv=uevr.params.vr.get_pose(index, hmd_position, hmd_rotation)
	
	--uevr.params.vr.get_pose()
	--print(hmd_position.z)
end)

--Decoupled Yaw END




