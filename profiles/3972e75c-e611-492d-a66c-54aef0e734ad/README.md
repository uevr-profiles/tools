# UEVR Profile for EVERSPACE™ 2 by Pande4360

| Property | Value |
| :--- | :--- |
| **Game EXE** | `ES2-Win64-Shipping` |
| **Source** | [uevr-profiles.com](https://uevr-profiles.com/game/3972e75c-e611-492d-a66c-54aef0e734ad) |
| **Created** | 2026-01-04T23:00:00Z |
| **Modified** | 2026-01-04T23:00:00Z |
| **Tags** | 3DOF |

## Description

Alpha Release V0.16
Disclaimer: this is just an early test build, expect issues. Only tested few missions thus far, but feel free to 

Latest Changes:
- Added back in R3 for roll, pls DELETE Targeting on R3 in game input settings!

Setup special buttons (HOTAS or keyboard):
- If you use an xbox controller or vr controllers this is optional, if you wanna use anything else you should at least bind the targeting key.
    - Go to profile folder scripts/Config/ and open Keys.lua:
        - Targeting button for HMCS:  replace the entry after TargetKey= with the name of your Input device´s button you wanna use for manual targeting, e.g. TargetKey="yourKey"
        - You can, first bind something ingame
        - Then check the input.ini in appdata/local/ES2/Config/Windows/ for the button´s name (the text after "Key1="), e.g. if it´s Key1=Joy1_button3, Copy "Joy1_button3" into the Keys.lua so it reads TargetKey="Joy1_button3"
        - Then unbind it ingame again
    - Do this for all other buttons(everyething aside the TargetKey is optional)
    - Create a backup of the Keys.lua file to not lose your config in a further update

ScriptUI Config options: UEVR ingame menu /ScriptUI
- HMCS HUD
    - Toggle on / off everything
    - Toggle on / off specific elements
    - Brightness
 
VR Controls:
- HMCS Targeting button: R3 or As configured in "Setup special buttons"
    - Lock Target: Look at target (red square on target) + Press Targeting button
    - Unlock Target: Hold Targeting button for longer than 1 sec
- "Setup special buttons" allows for more control bindings as found in Keys.lua
    - HMCS HUD On/Off button: HMCSKey(Default: Numpad 1)
    - HMCS HUD Brightness: BrUpKey(Default: Numpad 3), BrDownKey(Default: Numpad 2)

Done:
- Script for putting most widgets into world space Sphere around player (might be even all who knows)
- Helmet Mounted Cueing System(HMCS): Targeting and HUD options
- Works fine with HOTAS
- Warp Fix
- Some menu optimization
- Lead PiP

Known Issues:
- I only played a few missions so probably a lot to expect(not much issues till here tho)
- Names of widgets arent as easily figured out until target locked or being nearby.
- Needs downgrade to pre Wrath DLC , therefore Wrath DLC will not work. I have not tested with Titans but probably works

Install:
- DELETE Targeting on R3 in game input settings if you play with gamepad or vr controllers

