print("Initializing VR Crouch Script")

UEVR_UObjectHook.activate()

-- Hysteresis thresholds
local crouch = {
    crouchThreshold = -0.30,  -- physical crouch ON when HMD Y <= this
    standThreshold  = -0.25,  -- physical crouch OFF when HMD Y > this

    eyeLowThreshold  = -0.29, -- set CrouchedEyeHeight = 80 when below this
    eyeHighThreshold = -0.24, -- set CrouchedEyeHeight = 50 when above this

    isCrouching = false,
    lastEyeHeight = nil
}

-- Target eye height values
local EYE_HEIGHT_LOW  = 80.0
local EYE_HEIGHT_HIGH = 50.0

-- Cached pawn and movement component
local current_pawn = nil
local movement_component = nil

-- Find the FPSCharacterMovementComponent class UObject
local fps_movement_class = uevr.api:find_uobject("Class /Script/FPSController.FPSCharacterMovementComponent")
if fps_movement_class == nil then
    print("[CROUCH DEBUG] ERROR: Could not find FPSCharacterMovementComponent class")
end

-- Helper: get movement component for a pawn
local function find_movement_component(pawn)
    if pawn and fps_movement_class then
        local comp = pawn:GetComponentByClass(fps_movement_class)
        if comp then
            print("[CROUCH DEBUG] Found new FPSCharacterMovementComponent on pawn")
            return comp
        end
    end
    return nil
end

-- Pre-engine tick callback
uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    -- Get HMD position
    local hmd_index = uevr.params.vr.get_hmd_index()
    if hmd_index == -1 then return end
    local pos = UEVR_Vector3f.new()
    local rot = UEVR_Quaternionf.new()
    uevr.params.vr.get_pose(hmd_index, pos, rot)
    local y = pos.y

    -- Get GameEngine and GameInstance
    local game_engine_class = uevr.api:find_uobject("Class /Script/Engine.GameEngine")
    local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
    if not game_engine or not game_engine.GameInstance then return end

    -- Get local player pawn
    local local_players = game_engine.GameInstance.LocalPlayers
    if not local_players or #local_players == 0 then return end
    local player = local_players[1]
    local pawn = player.PlayerController.Pawn
    if not pawn then return end

    -- Detect pawn change
    if pawn ~= current_pawn then
        current_pawn = pawn
        movement_component = find_movement_component(pawn)
        crouch.lastEyeHeight = nil -- reset cached value on pawn change
        if not movement_component then
            print("[CROUCH DEBUG] FPSCharacterMovementComponent not found yet, awaiting component")
            return
        end
    end

    -- Check if movement component is valid
    if not movement_component or movement_component.bWantsToCrouch == nil then
        movement_component = find_movement_component(pawn)
        if not movement_component then return end
    end

    -- =========================
    -- HYBRID CROUCHED EYE HEIGHT LOGIC (HYSTERESIS)
    -- =========================

    local target_eye_height = crouch.lastEyeHeight

    if y <= crouch.eyeLowThreshold then
        target_eye_height = EYE_HEIGHT_LOW
    elseif y >= crouch.eyeHighThreshold then
        target_eye_height = EYE_HEIGHT_HIGH
    end

    -- Apply only if changed
    if target_eye_height ~= nil and target_eye_height ~= crouch.lastEyeHeight then
        if pawn.CrouchedEyeHeight ~= nil then
            pawn.CrouchedEyeHeight = target_eye_height
            crouch.lastEyeHeight = target_eye_height
            -- Uncomment for debug:
            -- print("[CROUCH DEBUG] CrouchedEyeHeight -> " .. target_eye_height)
        end
    end

    -- =========================
    -- PHYSICAL CROUCH LOGIC (HYSTERESIS)
    -- =========================

    if y <= crouch.crouchThreshold and not crouch.isCrouching then
        movement_component.bWantsToCrouch = true
        crouch.isCrouching = true
        print("[CROUCH DEBUG] bWantsToCrouch = true (Physical Crouch ON)")
    elseif y > crouch.standThreshold and crouch.isCrouching then
        movement_component.bWantsToCrouch = false
        crouch.isCrouching = false
        print("[CROUCH DEBUG] bWantsToCrouch = false (Physical Crouch OFF)")
    end
end)
