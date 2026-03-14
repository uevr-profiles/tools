# UEVR Profile for The Park by Oziman

| Property | Value |
| :--- | :--- |
| **Game EXE** | `ThePark` |
| **Source** | [uevr-profiles.com](https://uevr-profiles.com/game/9d0c3d3b-b24f-4caa-a84d-4dd55aaf7fa2) |
| **Created** | 2024-01-10T23:00:00Z |
| **Modified** | 2024-01-10T23:00:00Z |
| **Tags** | 6DOF, Motion Controls |

## Description

it is intended to "classic" players who sit, or stand still (without physical turning), that is, who simply use controllers as a gamepad.
Left controller to move, right controller to turn (to select mission objects use right stick up down).

"Shimmering LOD" or the texture of trees in the distance disappearing and appearing at a different angle as we move our head, can be solved:

- Edit "Engine.ini" (that file is located in "%localappdata%\AtlanticIslandPark\Saved\Config\WindowsNoEditor\Engine.ini) and add these lines:

[System Settings]
r.StaticMeshLODDistanceScale=.1
r.SkeletalMeshLODBias=-3
foliage.LODDistanceScale=8

