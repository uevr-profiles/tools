--[[
    Granny: Escape Together VR Hands Setup
    
    SETUP INSTRUCTIONS:
    1. Copy the entire 'libs' folder from the Atomic Heart mod into this scripts folder
       (so you have GrannyEscapeTogether_VR/scripts/libs/...)
    2. Place this entire GrannyEscapeTogether_VR folder into your UEVR profiles directory
       Usually: %APPDATA%\UnrealVRMod\GrannyEscapeTogether\scripts\
    3. Launch the game with UEVR
    4. Open the UEVR overlay (usually Insert key) and look for "Hand Config" panel
    5. Follow the wizard steps to configure hands
]]--

local uevrUtils = require("libs/uevr_utils")
local hands = require("libs/hands")

uevrUtils.initUEVR(uevr)

-- Set log level for debugging (change to LogLevel.Error for less output)
uevrUtils.setLogLevel(LogLevel.Info)
hands.setLogLevel(LogLevel.Info)

-- Enable the hands configuration wizard in the UEVR overlay
hands.enableConfigurationTool()

print("[Granny VR] ========================================")
print("[Granny VR] Hands configuration tool enabled!")
print("[Granny VR] Open UEVR overlay -> Hand Config panel")
print("[Granny VR] ========================================")
