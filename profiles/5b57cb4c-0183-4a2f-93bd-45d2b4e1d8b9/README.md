# UEVR Profile for Clair Obscur: Expedition 33 by markmon

| Property | Value |
| :--- | :--- |
| **Game EXE** | `SandFall-Win64-Shipping` |
| **Source** | [uevr-profiles.com](https://uevr-profiles.com/game/5b57cb4c-0183-4a2f-93bd-45d2b4e1d8b9) |
| **Created** | 2025-05-24T22:00:00Z |
| **Modified** | 2025-05-24T22:00:00Z |
| **Tags** | 3DOF |

## Description

Features:
- Configuration in UEVR menu on the scriptsUI tab. Needs UEVR 1061 or newer.
- Configurable for first person or 3rd person. Default 3rd person.
- Configurable lumen enabled or disabled (default enabled)
- Configurable fog enabled or disabled (default disabled)
- Configurable left dpad to toggle 1st and 3rd person in a pinch
- Configurable right dpad to toggle lumen on and off so you can both compare and see the perf difference. Also, in some scenes, it's more performance hungry than others.
properly fixed up the first person mesh and hiding character.

First person is automatic. It will detect and switch back to 3rd person as needed. But, it is a work in progress. Fixed conversation detection, fight detection, cinematic detection, and grapple detection (possibly fixes other interactions).

Broken: you can only be in 1st person on the character you are using when you load the game. Switching to another party member disables this. Still looking into fixing that.

Note: you must not set the tone mapper gamma slider at all as this will prevent the lumen switcher from adjusting gamma on the fly. Also, the user script included is needed. The lumen options are only added in by the script when enabling lumen. 

This is intended to be an all in one replacement for all the various profiles for this game thus far.

