# BallHammer

[![Lua](https://img.shields.io/badge/Lua-5.1-2C2D72?logo=lua&logoColor=white)](https://www.lua.org/)
[![Darktide Mod Framework](https://img.shields.io/badge/Darktide-Mod_Framework-EF4135)](https://github.com/Darktide-Mod-Framework/Darktide-Mod-Framework)
[![Latest commit](https://img.shields.io/github/last-commit/luinbytes/BallHammer)](https://github.com/luinbytes/BallHammer/commits/main)

BallHammer is a [Darktide Mod Framework](https://github.com/Darktide-Mod-Framework/Darktide-Mod-Framework) mod with all-enemy and pickup ESP plus configurable aim modes.

## Features

- Bone-projected boxes for all enemies, including enemies spawned or respawned after the mod loads
- Distinct special-enemy names, `SPECIAL` flags, distances, outlines, and health bars
- Distance fading and a visibility check that turns visible ESP white
- Compact world-space horde grouping with separate horizontal and elevation limits, buffered off-screen membership, aim-bone dots, and reversible join/split animation
- Normal aimbot and triggerbot keep an in-FOV target locked, then replace it when it leaves the FOV, dies, or becomes occluded
- Head or torso aim, configurable distance and field of view, interpolated smoothing, and aim curvature
- Distance-scaled target preview follows the armor-aware or configured aim bone nearest the crosshair and becomes the activation target
- Left mouse, right mouse, either mouse button, or a custom keyboard activation key
- Configurable magnet triggerbot with aim radius, fire radius, and smoothing
- Rage mode that selects visible on-screen targets using danger, range, and crosshair weighting
- Melee-aware aim range limits mouse-one targeting to enemies inside the current weapon sweep reach
- Optional timed repeat fire for press-driven, non-automatic weapons whenever mouse one is held
- Optional local weapon recoil and spread suppression without camera compensation
- Collision-spaced pickup cards with compact stacking, fixed screen sizing, category accents, distance fading, category presets, custom per-pickup filters, and distinct Med, Concentration, Combat, and Celerity Stimm labels
- Weighted Arbites and Skitarii companion orders based on special type, distance, and remaining health without moving the camera; native companion-rescue states override normal weights, retargeting waits for companion damage, and an optional charged Arbites dog EMP sends its press, hold, and release through Darktide's networked input frames when the dog connects
- Armor and Weakspot Director ranks visible hit zones using the current weapon damage profile, live armor overrides, shields, and weakspot finesse; triggerbot skips invulnerable shots and rage mode can choose another target
- Threat Interceptor marks committed hound, trapper, mutant, rager, sniper, flamer, grenade, and verified overhead attacks while a HUD shows the planned reaction and reaction-window countdown
- Native tactical HUD combines a live system/keybind panel, a camera-relative horizontal threat compass, and compact squad health, toughness, ammo, grenade, class, distance, disable, and objective states in one pooled HUD element
- Opt-in defensive reactions use bounded safe-window timing, preserve held attacks until the final dodge window, keep the player's movement direction, and dodge committed specialist, rager, and overhead attacks
- Opt-in Guard Brain preserves a configurable stamina reserve and pushes only when at least three nearby melee threats cover the available retreat directions
- Opt-in Warp and Heat Governor predicts the next resource increase, stops unsafe generated shots, and can use the current weapon's native quell or non-damaging vent input when no nearby threat exists
- Diagnostic logging records threat timing and reaction decisions for live compatibility checks without changing the safe defaults

## Configuration

Open Darktide's **Mod Options**, then select **BallHammer**. Settings are grouped under **Visuals and HUD**, **Aim Assistance**, **Defense and Survival**, and **Weapon and Companion**, with the existing feature sections nested inside them.

ESP can also be toggled by entering `/esp` in the in-game chat or by assigning **Toggle ESP Keybind**. Aimbot and triggerbot retain a target only while it stays inside their FOV; rage mode retains any visible on-screen target. Releasing the activation clears the lock.

Pickup ESP defaults to all pickups and can show only supplies, stimms, crafting materials, mission items, or a custom per-item selection.

Threat markers and armor-aware hit-zone selection are enabled by default. Automatic threat reactions, Guard Brain, resource governing, automatic quell or safe vent, emergency physical-input override, and diagnostic logging are all opt-in. Diagnostic logging records decisions but does not gate automatic reactions. Unknown or changed game states remain marker-only rather than guessing an input.

The Tactical HUD section independently controls the system panel, horizontal threat compass, compass range, squad list, and shared opacity. Darktide's native HUD scale also applies to the complete element.

## Requirements

- [Darktide Mod Loader](https://github.com/Darktide-Mod-Framework/Darktide-Mod-Loader)
- [Darktide Mod Framework](https://github.com/Darktide-Mod-Framework/Darktide-Mod-Framework)

## Installation

1. Install the Darktide Mod Loader and Darktide Mod Framework.
2. Copy this repository into the game's `mods` directory as `BallHammer`.
3. Add `BallHammer` to `mod_load_order.txt`.
4. Restart Darktide after installing or replacing mod files.

Keep your existing optional mod entries and add `BallHammer` once. The framework's `base` and `dmf` entries do not need to be listed.

## Development checks

From the repository root:

```sh
for test in tests/*_smoke.lua; do lua "$test" || exit 1; done
bash tests/runtime_compile_smoke.sh
find scripts -name '*.lua' -print0 | xargs -0 -n1 luac -p
```
