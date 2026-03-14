# UEVR Profile for Returnal™ by azyraphyle

| Property | Value |
| :--- | :--- |
| **Game EXE** | `Returnal-Win64-Shipping` |
| **Source** | [uevr-profiles.com](https://uevr-profiles.com/game/96e2dfaf-ed0f-4bec-ba51-f198ae88eb99) |
| **Created** | 2024-02-11T23:00:00Z |
| **Modified** | 2024-02-11T23:00:00Z |
| **Tags** | 6DOF, Motion Controls |

## Description

-  Get rid of the helmet that appears right in front of the camera when you're in the ship

To fix daylight shadows for native stereo and to remove sky light rays showing in one eye, create a file called "user_script.txt" in the UEVR profile directory and add these lines:
r.LightShaftQuality 0
r.Shadow.CSM.MaxCascades 0

Most of the other shadows look fine and can be adjusted with the in game settings.

