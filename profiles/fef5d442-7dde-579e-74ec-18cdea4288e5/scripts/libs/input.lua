-- Decoupled Yaw code courtesy of Pande4360

local uevrUtils = require("libs/uevr_utils")
local controllers = require("libs/controllers")
local configui = require("libs/configui")

local M = {}

M.AimMethod =
{
    GAME = 0,
    CONTROLLER = 1,
}

local decoupledYaw = 0
local bodyOffset = 0

local rxState = 0
local snapTurnDeadZone = 8000

--local playerHeight = 80
local currentOffset = uevrUtils.vector(0,0,80)
local useSnapTurn = false
local smoothTurnSpeed = 100
local snapAngle = 30
local handed = Handed.Right

local currentAimMethod = M.AimMethod.GAME

local configWidgets = {
	{
		widgetType = "checkbox",
		id = "useSnapTurn",
		label = "Use Snap Turn",
		initialValue = useSnapTurn
	},
	{
		widgetType = "slider_int",
		id = "snapAngle",
		label = "Snap Turn Angle",
		speed = 1.0,
		range = {2, 180},
		initialValue = snapAngle
	},
	{
		widgetType = "slider_int",
		id = "smoothTurnSpeed",
		label = "Smooth Turn Speed",
		speed = 1.0,
		range = {1, 100},
		initialValue = smoothTurnSpeed
	},
	{
		widgetType = "drag_float3",
		id = "headOffset",
		label = "Head Offset",
		speed = .1,
		range = {-200, 200},
		initialValue = {0.0, 0.0, 80.0}
	},
	{
		widgetType = "slider_int",
		id = "alignThreshhold",
		label = "Align Threshhold",
		speed = 0.1,
		range = {0, 100},
		initialValue = 80
	},
	{
		widgetType = "slider_int",
		id = "minAngularDeviation",
		label = "Min Angular Deviation",
		speed = 1.0,
		range = {1, 90},
		initialValue = 15
	},
	{
		widgetType = "slider_int",
		id = "alignConfidenceThreshhold",
		label = "Align Confidence Threshhold",
		speed = 0.1,
		range = {0, 100},
		initialValue = 50
	},
	{
		widgetType = "checkbox",
		id = "invertX",
		label = "Invert X",
		initialValue = false
	},
	{
		widgetType = "checkbox",
		id = "invertY",
		label = "Invert Y",
		initialValue = false
	},
	{
		widgetType = "checkbox",
		id = "invertZ",
		label = "Invert Z",
		initialValue = false
	},
	{
		widgetType = "checkbox",
		id = "invertW",
		label = "Invert W",
		initialValue = false
	},

}

configui.onUpdate("headOffset", function(value)
	M.setPlayerOffset(value)
end)

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[input] " .. text, logLevel)
	end
end

function M.getConfigWidgets()
	return configWidgets
end

function M.setAimMethod(aimMethod)
	currentAimMethod = aimMethod
end

function M.setUseSnapTurn(val)
	useSnapTurn = val
end

function M.setSmoothTurnSpeed(val)
	smoothTurnSpeed = val
end

function M.setSnapAngle(val)
	snapAngle = val
end

function M.setHandedness(val)
	handed = val
end

function M.setPlayerOffset(...)
	currentOffset = uevrUtils.vector(table.unpack({...}))
end

local function clampAngle180(angle)
    angle = angle % 360
    if angle > 180 then
        angle = angle - 360
    end
    return angle
end

local function updateDecoupledYaw(state)
	local yawChange = 0
	if decoupledYaw ~= nil then
		local thumbLX = state.Gamepad.sThumbLX
		local thumbLY = state.Gamepad.sThumbLY
		local thumbRX = state.Gamepad.sThumbRX
		local thumbRY = state.Gamepad.sThumbRY
		
		if handed == Handed.Left then
			thumbLX = state.Gamepad.sThumbRX
			thumbLY = state.Gamepad.sThumbRY
			thumbRX = state.Gamepad.sThumbLX
			thumbRY = state.Gamepad.sThumbLY
		end
		
		if useSnapTurn then
			if thumbRX > snapTurnDeadZone and rxState == 0 then
				yawChange = snapAngle
				rxState=1
			elseif thumbRX < -snapTurnDeadZone and rxState == 0 then
				yawChange = -snapAngle
				rxState=1
			elseif thumbRX <= snapTurnDeadZone and thumbRX >=-snapTurnDeadZone then
				rxState=0
			end
		else 
			local smoothTurnRate = smoothTurnSpeed / 12.5
			local rate = thumbRX/32767
			rate =  rate*rate*rate*rate
			if thumbRX > 2200 then
				yawChange = (rate * smoothTurnRate)
			end
			if thumbRX < -2200 then
				yawChange =  -(rate * smoothTurnRate)
			end
		end	
		
		--keep the decoupled yaw in the range of -180 to 180
		decoupledYaw = clampAngle180(decoupledYaw + yawChange)
	end
	return yawChange
end

local function normalize2D(v)
    local mag = math.sqrt(v.X * v.X + v.Y * v.Y)
    if mag == 0 then return {X = 1, Y = 0} end
    return {X = v.X / mag, Y = v.Y / mag}
end

local function dot2D(a, b)
    return a.X * b.X + a.Y * b.Y
end

local function cross2D(a, b)
    return a.X * b.Y - a.Y * b.X
end

local function midpoint(a, b)
    return {
        X = (a.X + b.X) * 0.5,
        Y = (a.Y + b.Y) * 0.5,
        Z = (a.Z + b.Z) * 0.5
    }
end

local function radiansToDegrees(rad)
    return rad * (180 / math.pi)
end

local function computeRelativeYaw(headPos, headForward, leftHand, rightHand)
    if not headPos or not headForward or not leftHand or not rightHand then
        return nil -- Safe fallback
    end

    local handMid = midpoint(leftHand, rightHand)
    local handDir = {
        X = handMid.X - headPos.X,
        Y = handMid.Y - headPos.Y
    }

    local fwd = normalize2D(headForward)
    local handVec = normalize2D(handDir)

    local dot = dot2D(fwd, handVec)
    local cross = cross2D(fwd, handVec)

    local angleRad = math.atan(cross, dot) -- Relative angle
    return -radiansToDegrees(angleRad)
end

local function shortestYawDelta(currentYaw, targetYaw)
    local delta = targetYaw - currentYaw
    delta = (delta + 180) % 360 - 180
    return delta
end

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
	if currentAimMethod == M.AimMethod.CONTROLLER then
		if decoupledYaw == nil then
			if uevrUtils.getValid(pawn,{"RootComponent"}) ~= nil and pawn.RootComponent.K2_GetComponentRotation ~= nil then
				local rotator = pawn.RootComponent:K2_GetComponentRotation()
				decoupledYaw = rotator.Yaw
			end
		end

		local yawChange = updateDecoupledYaw(state)
		
		if yawChange~= 0 and decoupledYaw~= nil and uevrUtils.getValid(pawn,{"RootComponent"}) ~= nil and pawn.RootComponent.K2_SetWorldRotation ~= nil then
			pawn.RootComponent:K2_SetWorldRotation(uevrUtils.rotator(0,decoupledYaw+bodyOffset,0),false,reusable_hit_result,false)
		end
	end
end)
local currentHeadYaw = 0
local deltaX = 0
local deltaY = 0
local lastPosition = nil


uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
--print("Pre engine")
	if currentAimMethod == M.AimMethod.CONTROLLER then
		local rotation = controllers.getControllerRotation(handed)
		if uevrUtils.getValid(pawn) ~= nil and pawn.Controller ~= nil and pawn.Controller.SetControlRotation ~= nil and rotation ~= nil then			
			--disassociates the rotation of the pawn from the rotation set by pawn.Controller:SetControlRotation()
			pawn.bUseControllerRotationPitch = false
			pawn.bUseControllerRotationYaw = false
			pawn.bUseControllerRotationRoll = false
			
			pawn.Controller:SetControlRotation(rotation)
		end
	end
	
	-- -- local rootComponent = uevrUtils.getValid(pawn,{"RootComponent"})
	-- -- if lastPosition ~= nil and rootComponent ~= nil and rootComponent.K2_GetComponentLocation ~= nil and rootComponent.K2_GetComponentRotation ~= nil then
		-- -- local pawnPos = rootComponent:K2_GetComponentLocation()	
		-- -- rootComponent:K2_SetWorldLocation(uevrUtils.vector(pawnPos.X+deltaX,pawnPos.Y+deltaY,pawnPos.Z),true,reusable_hit_result,false)
	-- -- end
	-- uevr.params.vr.get_standing_origin(temp_vec3f)
	-- --print("Standing",temp_vec3f.X*100,temp_vec3f.Y*100,temp_vec3f.Z*100)
	-- local origin = {X=temp_vec3f.X,Y=temp_vec3f.Y,Z=temp_vec3f.Z}
	-- uevr.params.vr.get_pose(uevr.params.vr.get_hmd_index(), temp_vec3f, temp_quatf)
	-- --print("Pose",temp_vec3f.X*100,temp_vec3f.Y*100,temp_vec3f.Z*100)
	-- local delta = {X=(temp_vec3f.X-origin.X)*100, Y=(temp_vec3f.Y-origin.Y)*100, Z=(temp_vec3f.Z-origin.Z)*100}
	-- --print("Delta1", delta.X, delta.Y, delta.Z)
	
	-- --local rotator = kismet_math_library:Quat_Rotator(uevrUtils.quat(temp_quatf.Z, temp_quatf.X, temp_quatf.Y, temp_quatf.W))
	-- --print("Rotator", rotator.Pitch, rotator.Yaw, rotator.Roll)
	-- -- --temp_vec3f:set(delta.X, delta.Z, delta.Y) -- the vector representing the offset adjustment
	-- --temp_vec3:set(0, 0, 1) --the axis to rotate around
	-- --local forwardVector = kismet_math_library:RotateAngleAxis( uevrUtils.vector(delta.X, delta.Z, delta.Y),  rotator.Yaw, uevrUtils.vector(0,0,1))

	-- -- delta = kismet_math_library:Quat_RotateVector(uevrUtils.quat(configui.getValue("invertZ") and -temp_quatf.Z or temp_quatf.Z, configui.getValue("invertX") and -temp_quatf.X or temp_quatf.X, configui.getValue("invertY") and -temp_quatf.Y or temp_quatf.Y, configui.getValue("invertW") and -temp_quatf.W or temp_quatf.W, true), uevrUtils.vector(delta))
	-- -- print("Delta2", delta.X, delta.Y, delta.Z)
	-- -- print("Quat", configui.getValue("invertX") and -temp_quatf.X or temp_quatf.X, configui.getValue("invertY") and -temp_quatf.Y or temp_quatf.Y, configui.getValue("invertZ") and -temp_quatf.Z or temp_quatf.Z, configui.getValue("invertW") and -temp_quatf.W or temp_quatf.W)

	-- --print("Final", forwardVector.X, forwardVector.Y, forwardVector.Z)

	-- local rootComponent = uevrUtils.getValid(pawn,{"RootComponent"})
	-- if rootComponent ~= nil and rootComponent.K2_GetComponentLocation ~= nil and rootComponent.K2_GetComponentRotation ~= nil then
		-- local pawnPos = rootComponent:K2_GetComponentLocation()	
		-- local pawnRot = rootComponent:K2_GetComponentRotation()	
		-- local baseRotationOffsetRotator = kismet_math_library:Quat_Rotator(pawn.BaseRotationOffset)	
		
		-- --pawn.BaseRotationOffset is 13.5. See if this accounts for the odd movement of the body when turning the head
		
-- --print(baseRotationOffsetRotator.Pitch,baseRotationOffsetRotator.Yaw,baseRotationOffsetRotator.Roll)		
		-- local forwardVector = kismet_math_library:RotateAngleAxis( uevrUtils.vector(delta.X, delta.Z, delta.Y),  pawnRot.Yaw - baseRotationOffsetRotator.Yaw, uevrUtils.vector(0,0,1))
		-- rootComponent:K2_SetWorldLocation(uevrUtils.vector(pawnPos.X+forwardVector.X,pawnPos.Y+forwardVector.Y,pawnPos.Z),true,reusable_hit_result,false)
		-- --rootComponent:K2_SetWorldLocation(uevrUtils.vector(pawnPos.X+delta.X,pawnPos.Y+delta.Z,pawnPos.Z),true,reusable_hit_result,false)
	-- end

	-- uevr.params.vr.set_standing_origin(temp_vec3f)
	
-- Standing        28.422448039055 -0.22106512915343       20.465998351574
-- Pose    -0.43557286262512       -0.08405881235376       16.509829461575
-- Delta   28.85802090168  -0.13700631679967       3.9561688899994

end)
-- Delta1  -0.56256353855133       -0.051021203398705      -22.181102633476
-- Delta2  -1.3375777006149        1.9254531860352 -22.064086914062
-- Quat    0.042667765170336       0.019363788887858       -0.044471692293882      0.99791121482849

-- Delta1  2.557173371315  0.081774592399597       -20.825165323913
-- Delta2  20.611698150635 1.4305515289307 3.6530609130859
-- Quat    -0.071966342628002      0.72209304571152        0.013292455114424       -0.68791419267654

-- uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
	-- if currentAimMethod == M.AimMethod.CONTROLLER then
		-- --local yaw = computeRelativeYaw(controllers.getControllerLocation(2),controllers.getControllerDirection(2), controllers.getControllerLocation(0), controllers.getControllerLocation(1))
		-- --print("Relative", yaw)


	-- end
-- end)
--local storedYaw = 0

uevr.params.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)	
--print("Early Stereo")
	local rootComponent = uevrUtils.getValid(pawn,{"RootComponent"})
	if rootComponent ~= nil and rootComponent.K2_GetComponentLocation ~= nil and rootComponent.K2_GetComponentRotation ~= nil then
		-- local pawnPos = rootComponent:K2_GetComponentLocation()	
		-- rootComponent:K2_SetWorldLocation(uevrUtils.vector(lastPosition.X,lastPosition.Y,pawnPos.Z),true,reusable_hit_result,false)
		local pawnPos = rootComponent:K2_GetComponentLocation()	
-- print("PAWN",pawnPos.X, pawnPos.Y, pawnPos.Z)		
-- print("EYE",position.X, position.Y, position.Z)		
--print("Early",view_index, position.X - pawnPos.X, position.Y - pawnPos.Y)
		local pawnRot = rootComponent:K2_GetComponentRotation()					
		pawnRot.Yaw = pawnRot.Yaw - bodyOffset
		
		temp_vec3f:set(currentOffset.X, currentOffset.Y, currentOffset.Z) -- the vector representing the offset adjustment
		temp_vec3:set(0, 0, 1) --the axis to rotate around
		local forwardVector = kismet_math_library:RotateAngleAxis(temp_vec3f, pawnRot.Yaw, temp_vec3)
		--local pawnPos = mountPawn.RootComponent:K2_GetComponentLocation()					
		position.x = pawnPos.x + forwardVector.X
		position.y = pawnPos.y + forwardVector.Y
		position.z = pawnPos.z + forwardVector.Z

		-- position.x = pawnPos.x 
		-- position.y = pawnPos.y 
		-- position.z = pawnPos.z + 80
		rotation.Pitch = 0--pawnRot.Pitch 
		rotation.Yaw = pawnRot.Yaw
		rotation.Roll = 0--pawnRot.Roll 
		
	end
end)

-- uevr.sdk.callbacks.on_pre_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
	-- --print("Pre Stereo")
	-- local rootComponent = uevrUtils.getValid(pawn,{"RootComponent"})
	-- if rootComponent ~= nil and rootComponent.K2_GetComponentLocation ~= nil and rootComponent.K2_GetComponentRotation ~= nil then
		-- local pawnPos = rootComponent:K2_GetComponentLocation()	
-- --print("Pre",view_index, position.X - pawnPos.X, position.Y - pawnPos.Y)
	-- end

-- end)

uevr.sdk.callbacks.on_post_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
--print("Post Stereo")
	-- local minYawDelta = configui.getValue("minYawDelta")
	-- local maxYawDelta = configui.getValue("maxYawDelta")
	-- local bodyYawThreshhold = configui.getValue("bodyYawThreshhold")
-- print("EYE2",position.X, position.Y, position.Z)		
	
	currentHeadYaw = rotation.Yaw
	
	-- local rootComponent = uevrUtils.getValid(pawn,{"RootComponent"})
	-- if rootComponent ~= nil and rootComponent.K2_GetComponentLocation ~= nil then
		-- local pawnPos = rootComponent:K2_GetComponentLocation()	
	
		-- if lastPosition == nil then
			-- lastPosition = {X = position.X, Y = position.Y, Z = position.Z}
		-- end
		-- deltaX = position.X - pawnPos.X
		-- deltaY = position.Y - pawnPos.Y
		-- --print("Post ",view_index,deltaX,deltaY)
		
		-- lastPosition.X = position.X
		-- lastPosition.Y = position.Y
		-- lastPosition.Z = position.Z
	-- end
	
	-- local rootComponent = uevrUtils.getValid(pawn,{"RootComponent"})
	-- if rootComponent ~= nil then
		-- --local pawnLocation = rootComponent:K2_GetComponentLocation()
		
		-- --rootComponent:K2_SetWorldLocation(uevrUtils.vector(position.X,position.Y,0),true,reusable_hit_result,false)
		-- --position.X = pawnLocation.X
		-- --position.Y = pawnLocation.Y
		-- --transform = rootComponent:K2_GetComponentToWorld()
	-- end

	-- local postYaw = clampAngle180(rotation.Yaw - decoupledYaw)
	-- local yawDelta = clampAngle180(postYaw - bodyOffset)
	-- local offset = 0--yawDelta
	-- print(yawDelta)
	-- if yawDelta < - 40 then
		-- targetYaw = postYaw
	-- end
	
	--offset = postYaw - bodyOffset
	-- local bodyRelativeYaw = computeRelativeYaw(controllers.getControllerLocation(2),controllers.getControllerDirection(2), controllers.getControllerLocation(0), controllers.getControllerLocation(1))
	-- if math.abs(yawDelta - bodyRelativeYaw) > 10 then
		-- --offset = yawDelta
		-- --storedYaw = storedYaw + yawDelta
		-- storedYaw =  yawDelta
	-- end
-- print(bodyRelativeYaw, yawDelta, yawDelta - bodyRelativeYaw, storedYaw)
	-- if storedYaw > 0.1 then
		-- offset = yawDelta - storedYaw
		-- storedYaw = storedYaw - 0.1
	-- elseif storedYaw < 0.1 then
		-- offset = yawDelta + storedYaw
		-- storedYaw = storedYaw + 0.1
	-- else
		-- storedYaw = 0
	-- end
--offset = yawDelta - bodyRelativeYaw
	-- if yawDelta > minYawDelta then 
		-- local bodyRelativeYaw = computeRelativeYaw(controllers.getControllerLocation(2),controllers.getControllerDirection(2), controllers.getControllerLocation(0), controllers.getControllerLocation(1))
		-- print("YAW 1",bodyRelativeYaw) 
		-- if yawDelta > maxYawDelta then
			-- --offset = 15.0 --set it to controller rotation yaw
			-- offset = rotation.Yaw - bodyOffset
		-- elseif (bodyRelativeYaw > -bodyYawThreshhold and bodyRelativeYaw < bodyYawThreshhold) then
			-- offset = 0.2 
		-- end
	-- end
	
	-- if yawDelta < -minYawDelta then 
		-- local bodyRelativeYaw = computeRelativeYaw(controllers.getControllerLocation(2),controllers.getControllerDirection(2), controllers.getControllerLocation(0), controllers.getControllerLocation(1))
		-- print("YAW 2",bodyRelativeYaw) 
		-- if yawDelta < -maxYawDelta then
			-- --offset = -15.0
			-- offset = rotation.Yaw - bodyOffset
		-- elseif (bodyRelativeYaw > -bodyYawThreshhold and bodyRelativeYaw < bodyYawThreshhold) then
			-- offset = -0.2 
		-- end
	-- end
	
	-- if offset ~= 0 then
		-- --print(yawDelta,decoupledYaw, postYaw, bodyOffset, offset)
		-- bodyOffset = clampAngle180(bodyOffset + offset)

		-- --decoupledYaw = rotation.Yaw
		-- if decoupledYaw~= nil and uevrUtils.getValid(pawn,{"RootComponent"}) ~= nil and pawn.RootComponent.K2_SetWorldRotation ~= nil then
			-- pawn.RootComponent:K2_SetWorldRotation(uevrUtils.rotator(0,decoupledYaw+bodyOffset,0),false,reusable_hit_result,false)
		-- end
	-- end

end)

-- local MAX_DEVIATION     = 40      -- degrees to trigger lerp
-- local ALIGN_THRESHOLD   = 0.5     -- degrees to stop lerping
-- local BASE_LERP_SPEED   = 10      -- minimum lerp speed
-- local MAX_LERP_SPEED    = 150     -- maximum lerp speed
-- local SPEED_SCALE       = 5       -- multiplier for head velocity

-- -- Persistent state
-- local lerping = false
-- local prevHeadsetYaw = nil

-- local function normalizeYaw(yaw)
    -- yaw = yaw % 360
    -- if yaw > 180 then yaw = yaw - 360 end
    -- return yaw
-- end

-- local function angularDifference(a, b)
    -- return normalizeYaw(b - a)
-- end

-- local function lerpAngle(current, target, alpha)
    -- local diff = angularDifference(current, target)
    -- return normalizeYaw(current + diff * alpha)
-- end

-- function UpdateBodyYaw(bodyYaw, headsetYaw, deltaTime)
    -- bodyYaw = normalizeYaw(bodyYaw)
    -- headsetYaw = normalizeYaw(headsetYaw)

    -- -- Estimate headset angular velocity
    -- local headVelocity = 0
    -- if prevHeadsetYaw then
        -- headVelocity = math.abs(angularDifference(prevHeadsetYaw, headsetYaw)) / deltaTime
    -- end
    -- prevHeadsetYaw = headsetYaw

    -- -- Compute dynamic lerp speed
    -- local dynamicSpeed = math.min(MAX_LERP_SPEED, BASE_LERP_SPEED + headVelocity * SPEED_SCALE)

    -- local diff = angularDifference(bodyYaw, headsetYaw)
    -- local absDiff = math.abs(diff)

    -- if lerping then
        -- if absDiff <= ALIGN_THRESHOLD then
            -- lerping = false
            -- return headsetYaw
        -- else
            -- local alpha = math.min(1, (dynamicSpeed * deltaTime) / absDiff)
            -- return lerpAngle(bodyYaw, headsetYaw, alpha)
        -- end
    -- elseif absDiff >= MAX_DEVIATION then
        -- lerping = true
        -- local alpha = math.min(1, (dynamicSpeed * deltaTime) / absDiff)
        -- return lerpAngle(bodyYaw, headsetYaw, alpha)
    -- else
        -- return bodyYaw
    -- end
-- end

	-- ALIGN_CONFIDENCE_THRESHOLD = configui.getValue("alignConfidenceThreshhold") / 100
	-- ALIGN_THRESHOLD = configui.getValue("alignThreshhold") / 100

-- Configurable parameters
-- ALIGN_CONFIDENCE_THRESHOLD is the minimum confidence value required to trigger body yaw alignment. It acts as a gatekeeper for gesture 
-- intent ensuring that the body only begins rotating when the hands are clearly aligned with the head’s facing direction.
-- What It Measures
-- Confidence is calculated using the dot product between:
-- - The vector from left hand to right hand (projected onto the XY plane, Unreal-style)
-- - The head’s forward vector (also projected onto the XY plane)
-- This dot product ranges from -1 to 1, where:
-- 	1.0 Hand span is strongly aligned with head yaw
-- 	0.0 Hand span is orthogonal to head yaw
-- 	-1.0 Hand span is opposite to head yaw
local ALIGN_CONFIDENCE_THRESHOLD = 0.8   -- Dot product threshold for alignment
local MIN_ANGULAR_DEVIATION = 15         -- Minimum yaw difference to trigger rotation
-- ALIGN_THRESHOLD is the snap-to-stop threshold for body yaw alignment. It defines how close the body yaw must be to the headset
-- yaw before the system considers the alignment “good enough” and stops lerping.
-- Why It Matters
-- When the body is rotating to match the headset, you don’t want it to endlessly chase tiny differences—like 0.1° of drift. That would cause:
-- • 	Visual jitter
-- • 	Unnecessary micro-adjustments
-- • 	Wasted computation
-- So  sets a dead zone: once the body yaw is within, say, 0.5° of the headset yaw, the system snaps to the target and stops smoothing.
local ALIGN_THRESHOLD = 0.5              -- Degrees to stop lerping
local BASE_LERP_SPEED = 10               -- Minimum lerp speed
local MAX_LERP_SPEED = 150               -- Maximum lerp speed
local SPEED_SCALE = 5                    -- Multiplier for head angular velocity

-- Persistent state
local prevHeadsetYaw = nil
local lerping = false

-- Utility functions
local function normalizeYaw(yaw)
    yaw = yaw % 360
    if yaw > 180 then yaw = yaw - 360 end
    return yaw
end

local function angularDifference(a, b)
    return normalizeYaw(b - a)
end

local function lerpAngle(current, target, alpha)
    local diff = angularDifference(current, target)
    return normalizeYaw(current + diff * alpha)
end

local function normalize2D(v)
    local mag = math.sqrt(v.x^2 + v.y^2)
    if mag == 0 then return {x=0, y=0} end
    return { x = v.x / mag, y = v.y / mag }
end

local function dot2D(a, b)
    return a.x * b.x + a.y * b.y
end

-- Yaw-only confidence using Unreal's XY plane
local function yawAlignmentConfidence(leftHandPos, rightHandPos, headForward)
    local handSpan2D = {
        x = rightHandPos.x - leftHandPos.x,
        y = rightHandPos.y - leftHandPos.y
    }

    local headForward2D = {
        x = headForward.x,
        y = headForward.y
    }

    local nSpan = normalize2D(handSpan2D)
    local nForward = normalize2D(headForward2D)

    return dot2D(nSpan, nForward)
end

function UpdateBodyYaw(bodyYaw, headsetYaw, leftHandPos, rightHandPos, headForward, deltaTime)
	ALIGN_CONFIDENCE_THRESHOLD = configui.getValue("alignConfidenceThreshhold") / 100
	ALIGN_THRESHOLD = configui.getValue("alignThreshhold") / 100
	MIN_ANGULAR_DEVIATION = configui.getValue("minAngularDeviation")
	
    bodyYaw = normalizeYaw(bodyYaw)
    headsetYaw = normalizeYaw(headsetYaw)

    -- Estimate headset angular velocity
    local headAngularVelocity = 0
    if prevHeadsetYaw then
        headAngularVelocity = math.abs(angularDifference(prevHeadsetYaw, headsetYaw)) / deltaTime
    end
    prevHeadsetYaw = headsetYaw

    -- Compute dynamic lerp speed
    local dynamicSpeed = math.min(MAX_LERP_SPEED, BASE_LERP_SPEED + headAngularVelocity * SPEED_SCALE)

    -- Compute yaw-based alignment confidence
    local confidence = yawAlignmentConfidence(leftHandPos, rightHandPos, headForward)
	--print(confidence)

    local diff = angularDifference(bodyYaw, headsetYaw)
    local absDiff = math.abs(diff)

    local shouldRotate = confidence >= ALIGN_CONFIDENCE_THRESHOLD and absDiff >= MIN_ANGULAR_DEVIATION

    if lerping then
        if absDiff <= ALIGN_THRESHOLD then
            lerping = false
            return headsetYaw
        else
            local alpha = math.min(1, (dynamicSpeed * deltaTime) / math.max(absDiff, MIN_ANGULAR_DEVIATION))
            return lerpAngle(bodyYaw, headsetYaw, alpha)
        end
    elseif shouldRotate then
        lerping = true
        local alpha = math.min(1, (dynamicSpeed * deltaTime) / math.max(absDiff, MIN_ANGULAR_DEVIATION))
        return lerpAngle(bodyYaw, headsetYaw, alpha)
    else
        return bodyYaw
    end
end

uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
--print("Post engine")
-- --print(bodyOffset, currentHeadYaw, delta)
	-- local hmdDirection = controllers.getControllerDirection(2)
	-- local hmdRightVector = controllers.getControllerRightVector(2)
	-- local hmdRotation = controllers.getControllerRotation(2)
	-- -- local rotator = uevrUtils.rotator(0,0,1)
	-- -- local vector = kismet_math_library:GetRightVector(rotator)
	-- print("Forward",hmdDirection.X,hmdDirection.Y, hmdDirection.Z)
	-- print("Right",hmdRightVector.X,hmdRightVector.Y, hmdRightVector.Z)
	-- --print(hmdRotationn.Pitch,hmdRotationn.Yaw, hmdRotationn.Roll)
	-- --hmdRightVector.Z * something -- 0 when not tilted -1 when titled all the way right
	-- --pawn.Mesh.RelativeLocation.Y = hmdRightVector.Z * 7
	-- --print(hmdDirection.X)
	-- --pawn.Mesh.RelativeLocation.X = -(1-hmdDirection.X) * 10
	-- --pawn.Mesh.RelativeLocation.Y = -hmdDirection.Y * 10
	-- --pawn.Mesh.RelativeLocation.Z = hmdDirection.Z * 7
	-- bodyOffset = UpdateBodyYaw(bodyOffset, currentHeadYaw - decoupledYaw, controllers.getControllerLocation(2),  controllers.getControllerLocation(1), hmdDirection, delta)
	-- ---bodyOffset = UpdateBodyYaw(bodyOffset, currentHeadYaw - decoupledYaw, delta)
	-- if decoupledYaw~= nil and uevrUtils.getValid(pawn,{"RootComponent"}) ~= nil and pawn.RootComponent.K2_SetWorldRotation ~= nil then
		-- pawn.RootComponent:K2_SetWorldRotation(uevrUtils.rotator(0,decoupledYaw+bodyOffset,0),false,reusable_hit_result,false)
	-- end

	-- local rootComponent = uevrUtils.getValid(pawn,{"RootComponent"})
	-- if rootComponent ~= nil then
	-- --print("Here")
		-- -- rootComponent.RelativeLocation.X = lastPosition.X
		-- -- rootComponent.RelativeLocation.Y = lastPosition.Y
		-- -- rootComponent.RelativeLocation.Z = lastPosition.Z
		-- -- rootComponent.RelativeLocation.X = rootComponent.RelativeLocation.X + deltaX
		-- -- rootComponent.RelativeLocation.Y = rootComponent.RelativeLocation.Y + deltaY
		-- rootComponent.K2_SetWorldLocation(uevrUtilsvector(lastPosition),false,reusable_hit_result,false)
	-- end
	-- local rootComponent = uevrUtils.getValid(pawn,{"RootComponent"})
	-- if rootComponent ~= nil then
		-- rootComponent:K2_AddWorldOffset(uevrUtils.vector(deltaX,deltaY,0), true, reusable_hit_result, false)
		-- deltaX = 0
		-- deltaY = 0
	-- end

end)

uevrUtils.setInterval(1000, function()
	local val = configui.getValue("useSnapTurn")
	if val ~= nil then useSnapTurn = val end
	val = configui.getValue("smoothTurnSpeed")
	if val ~= nil then smoothTurnSpeed = val end
	val = configui.getValue("snapAngle")
	if val ~= nil then snapAngle = val end
end)

-- register_key_bind("F1", function()
    -- print("F1 pressed\n")
	-- --pawn:StartBulletTime(0.0, 50.0, false, 1.0, 0.4, 2.0)
	-- --rootComponent:K2_SetWorldLocation(uevrUtilsvector(lastPosition),false,reusable_hit_result,false)
	-- local rootComponent = uevrUtils.getValid(pawn,{"RootComponent"})
	-- if rootComponent ~= nil then
		-- rootComponent:K2_AddWorldOffset(uevrUtils.vector(deltaX,deltaY,0), true, reusable_hit_result, false);
	-- end
-- end)

return M