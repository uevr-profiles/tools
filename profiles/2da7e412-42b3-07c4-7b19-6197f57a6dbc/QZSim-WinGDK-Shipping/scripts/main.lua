local uevrUtils = require("libs/uevr_utils")
local hands = require("libs/hands")
local interaction = require("libs/interaction")

-- Init
uevrUtils.initUEVR(uevr)
uevrUtils.setLogLevel(LogLevel.Info)
hands.setLogLevel(LogLevel.Info)

hands.enableConfigurationTool()

-- Interaction: initialisée mais désactivée (ne crée rien tant que None)
interaction.init(false, LogLevel.Info)
interaction.setInteractionType(interaction.InteractionType.None)
interaction.showInteractionLaser(false)
interaction.setAllowMouseUpdate(false)

-- Toggle sur D-Pad Up
local XINPUT_GAMEPAD_DPAD_UP = 0x0001
local pointerEnabled = false
local wasPressed = false

local function enablePointer()
    -- Active seulement quand tu le demandes
    interaction.setInteractionType(interaction.InteractionType.MeshAndWidget)
    interaction.showInteractionLaser(true)
    interaction.setAllowMouseUpdate(true)
end

local function disablePointer()
    interaction.showInteractionLaser(false)
    interaction.setAllowMouseUpdate(false)
    -- Important: repasse à None pour détruire proprement les composants
    interaction.setInteractionType(interaction.InteractionType.None)
end

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)
    local pressed = uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_DPAD_UP)

    -- Toggle sur front montant
    if pressed and not wasPressed then
        pointerEnabled = not pointerEnabled
        if pointerEnabled then
            enablePointer()
        else
            disablePointer()
        end
    end

    -- Bloque la flèche haut pour éviter action du jeu
    if pressed then
        uevrUtils.unpressButton(state, XINPUT_GAMEPAD_DPAD_UP)
    end

    wasPressed = pressed
end)
