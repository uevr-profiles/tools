local api = uevr.api
local vr = uevr.params.vr
local params = uevr.params
local callbacks = params.sdk.callbacks

-- TRUE TANK CONTROLS VERSION
-- Left Stick:
--   Up/Down = Move Forward/Back
--   Left/Right = Rotate Pawn
-- Right Stick Disabled

local runToggled = false

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    if state == nil then return end

    local pawn = api:get_local_pawn(0)
    if pawn == nil then return end

    local deadzone = 12000

    -- TURN LEFT / RIGHT (Tank Rotation)
    if state.Gamepad.sThumbRX > deadzone then
        turn(pawn, state.Gamepad.sThumbRX / 1000)
    elseif state.Gamepad.sThumbRX < -deadzone then
        turn(pawn, state.Gamepad.sThumbRX / 1000)
    end

    -- MOVE FORWARD / BACK
    if state.Gamepad.sThumbLY > deadzone then
        moveForward(pawn, state.Gamepad.sThumbLY)
    elseif state.Gamepad.sThumbLY < -deadzone then
        moveForward(pawn, state.Gamepad.sThumbLY)
    end

    -- Disable original stick input to prevent double input
    state.Gamepad.sThumbLX = 0
    state.Gamepad.sThumbLY = 0
    state.Gamepad.sThumbRX = 0
    state.Gamepad.sThumbRY = 0
end)

function moveForward(pawn, value)
    if pawn.CharacterMovement ~= nil then
        pawn.CharacterMovement.MaxWalkSpeed = 600
    end

    if value > 0 then
        local direction = pawn:GetActorForwardVector()
        pawn:AddMovementInput(direction, 1)
    else
        local direction = pawn:GetActorForwardVector()
        pawn:AddMovementInput(direction, -1)
    end
end

function turn(pawn, value)
    local turnSpeed = 0.10
    local newRotation = pawn:K2_GetActorRotation()
    newRotation.Yaw = newRotation.Yaw + value * turnSpeed
    pawn:K2_SetActorRotation(newRotation)
end
