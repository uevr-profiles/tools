![SPRAWL](https://cdn.discordapp.com/attachments/1144003903143288883/1144003903529173002/header.jpg?ex=69b51ae9&is=69b3c969&hm=eb8f5f41951bd2ce3e323aeead5e098df8d1ec88c1308e99edd8cff74c355889&)

# UEVR Profile for SPRAWL by deterministicj

| Property | Value |
| :--- | :--- |
| **Game EXE** | `Sprawl-Win64-Shipping` |
| **Source** | [discord.gg/flat2vr](https://discord.com/channels/747967102895390741/1144003903143288883/1195662796210319491) |
| **Created** | 2024-01-13T09:37:04Z |
| **Tags** | 6DOF, Motion Controls |

## Description

I was able to find the component without the random ID. Had to avoid all parents and children because they all had random ID...

I did nothing else besides save 6DOF to right controller and align in between guns (not well).

This is going to require some work for alignment because ~~both arms and guns are one mesh~~ can probably realign better once you get the 1 handed weapons. ~~I found the best area was between the 2 guns, but they were still pretty badly misaligned.~~ The guns were always well below where I was holding them. Will probably require re-positioning of the mesh itself in UEVR UEObject to raise it up. 

If we're not able to make it look good, it works great just hiding the guns.

For those working on profiles that might be interested on the route to get to it: 

Common Objects > Acknowledged Pawn > Components > PlayerInventoryComponent Player Inverntory > Properties > EquippedWeapon > Components > SkeletalMeshComponent Mesh 🙃 

tldr:found 6dof, needs aligned, might need to raise the guns up or hide them if you can't

WIP 6DOF

