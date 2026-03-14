![Demonologist](https://cdn.discordapp.com/attachments/1091369378307637249/1091369378630606888/1e3b5d149edd6acdb8e113e11cfb96fe7167_1232xr706_Q100.jpg?ex=69b57170&is=69b41ff0&hm=0fefc5178a5f48b7b9dce208d9f27b1d1a7ba93a33d7824549b10a12900629c2&)

# UEVR Profile for Demonologist by sinful_rose_

| Property | Value |
| :--- | :--- |
| **Game EXE** | `Shivers-Win64-Shipping` |
| **Source** | [discord.gg/flat2vr](https://discord.com/channels/747967102895390741/1091369378307637249/1243579531982405806) |
| **Created** | 2024-05-24T15:01:05Z |
| **Tags** | 6DOF, Motion Controls |

## Description

Ok, so... I managed to get 6DOF with motion controllers support and roomscale. Works with OpenVR, OpenXR and Oculus runtimes
- Tools attached to right controller
- Flashlight attached to left controller (when not equipped, when equipped it's attached to right controller)

BINDINGS:
A button -> E key (interaction)
B button -> Esc key
X button -> F key (flashlight on/off)
Y button -> J key (tablet)
Left Grip -> G key (drop/place items)
Right Grip -> Mouse scroll down (rotate items before placement / cycle through items)
Left Trigger -> Left mouse click
Right Trigger -> Right mouse click (unused in game)
Left Stick -> move
Right Stick -> mouse movement / turn
Left Thumbstick -> Left Shift key (run)
Right Thumbstick -> Left Ctrl (crouch)

HOW TO:
- Import the profile in UEVR
- Download FreePIE v.1.2 (important, v 1.2, NOT v. 1.22) from this link:
https://github.com/Ofisare/VRCompanion/releases
- Unzip in a folder of your wish
- Put the Demonologist.py file in scripts\user_profiles folder
- Run FreePIE.exe
- Go to Setting->OpenVR and choose your runtime (OpenVR, OpenXR, Oculus)
- Go to File->Open->vr_companion.py
- Go to Script-> Run script
- A little launcher will appear -> Choose Demonologist profile -> Start
- Start game
- Inject UEVR
- Enjoy!

ADDITIONAL INFO:
- Above bindings are valid if you didn't change the default controls settings in game. If you did, restore them with the in-game feature
- It seems to work fine, except when you drop/place your last item: it'll remain attached to the right controller untill a new item is picked up, then the last item you dropped will automatically go where you dropped/placed it (if you always keep the flashlight with you you won't have this problem)
- You can easily change the binding as you wish in the Demonologist.py file (open it with notepad)
- I didn't test it in multiplayer. I don't know how it behave (for example player skeletal mesh is hidden)
- I didn't test it at all (made just some walk around the fisrt map)

