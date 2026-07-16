# BallHammer

[![Lua](https://img.shields.io/badge/Lua-5.1-2C2D72?logo=lua&logoColor=white)](https://www.lua.org/)
[![Darktide Mod Framework](https://img.shields.io/badge/Darktide-Mod_Framework-EF4135)](https://github.com/Darktide-Mod-Framework/Darktide-Mod-Framework)
[![Latest commit](https://img.shields.io/github/last-commit/luinbytes/BallHammer)](https://github.com/luinbytes/BallHammer/commits/main)

BallHammer is a [Darktide Mod Framework](https://github.com/Darktide-Mod-Framework/Darktide-Mod-Framework) mod with all-enemy ESP and a configurable normal aimbot.

## Features

- Bone-projected boxes for all enemies, including enemies spawned or respawned after the mod loads
- Distinct special-enemy names, `SPECIAL` flags, distances, outlines, and health bars
- Distance fading and a visibility check that turns visible ESP white
- Compact world-space horde grouping with separate horizontal and elevation limits, buffered off-screen membership, aim-bone dots, and reversible join/split animation
- Normal aimbot that acquires the visible target closest to the crosshair and keeps that target locked
- Immediate target replacement when the lock dies or becomes occluded
- Head or torso aim, configurable distance and field of view, interpolated smoothing, and aim curvature
- Left mouse, right mouse, either mouse button, or a custom keyboard activation key
- Optional timed repeat fire for press-driven, non-automatic weapons whenever mouse one is held
- Optional local weapon recoil and spread suppression without camera compensation
- Weighted Arbites and Skitarii companion orders based on special type, distance, and remaining health without moving the camera; native companion-rescue states override normal weights, retargeting waits for companion damage, and an optional charged Arbites dog EMP fires when the dog connects

Triggerbot and rage modes are not included. BallHammer uses one predictable normal-aim path.

## Configuration

Open Darktide's **Mod Options**, then select **BallHammer**. The menu contains separate **ESP**, **Aimbot**, and **Companion** sections.

ESP can also be toggled by entering `/esp` in the in-game chat or by assigning **Toggle ESP Keybind**. The aimbot remains active only while its configured activation is held. A locked target is retained outside the acquisition field of view while it remains alive and visible; releasing the activation clears the lock.

## Requirements

- [Darktide Mod Loader](https://github.com/Darktide-Mod-Framework/Darktide-Mod-Loader)
- [Darktide Mod Framework](https://github.com/Darktide-Mod-Framework/Darktide-Mod-Framework)

## Installation

1. Install the Darktide Mod Loader and Darktide Mod Framework.
2. Copy this repository into the game's `mods` directory as `BallHammer`.
3. Add `BallHammer` to `mod_load_order.txt`.
4. Restart Darktide after installing or replacing mod files.

Only add `BallHammer` if you want it to be the sole optional mod in the load order. The framework's `base` and `dmf` entries do not need to be listed.

## Development checks

From the repository root:

```sh
for test in tests/*_smoke.lua; do lua "$test" || exit 1; done
find scripts -name '*.lua' -print0 | xargs -0 -n1 luac -p
```
