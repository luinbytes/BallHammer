# Horizontal compass UI research

Research snapshot: 2026-07-26. Visual claims below come from first-party gameplay footage or publisher game pages, not UI write-ups. Footage is a useful layout reference, not proof of hidden game rules.

## Existing BallHammer constraint

The threat compass is already a 520 px, 42 px-high top-centre rail with a fixed `^` forward heading and four camera-relative entries. It ranks the committed threat first, then nearby specials by distance; each entry carries a red pip, full name, distance, and optional vertical `^`/`v` suffix. It also actively spaces labels horizontally. See [`BallHammerThreatHud.lua`](../../scripts/mods/BallHammer/BallHammerThreatHud.lua) lines 10-15, 66-71, 137-152, 228-253, 430-480, and 497-560.

## Pattern comparison

| Reference | What the official capture shows | Useful rule for BallHammer | Do not copy |
| --- | --- | --- | --- |
| [Skyrim, official Bethesda manual (pp. 3-4)](https://assets.ctfassets.net/rporu91m20dc/46SNPirCFGI0eC6w84UI8w/0f5b441e255a26b9371608ee71b73af3/manual_skyrim-le_x360_en-int.pdf) | The labelled game-screen and compass diagram show a narrow, top-centre strip with the current direction fixed at centre, an `N` heading, and distinct location, quest, and red-enemy markers. It is visibly ornament-framed with end caps. | Keep the fixed centre reference and make marker shape/colour convey type before text. | Its fantasy ornament, end caps, and open-world marker density. |
| [Horizon Forbidden West, official PS5 gameplay capture](https://www.guerrilla-games.com/read/15-minutes-of-new-gameplay-for-horizon-forbidden-west) | The selected official capture keeps combat information compact at the lower right. It does **not** establish a horizontal top compass or centre-heading pattern. | Treat Horizon as a low-clutter contrast: the threat compass must not compete with the crosshair or combat HUD. | Claiming that Horizon validates a horizontal compass. It does not in this capture. |
| [Call of Duty: Modern Warfare III, official multiplayer guide](https://www.callofduty.com/guides/training/call-of-duty-modern-warfare-III-training-multiplayer-how-to-play?SaMl7yIwS4y9UU=2PIb25xTvPInZI6) | The official guide places the compass at the top of the screen and the current-location name beneath it. It does not document enemy markers on that compass. | A top rail can carry orientation while a subordinate line carries context. | Treating a red enemy mark on the mini-map or Tac Map as evidence for a compass threat icon. |

### Cross-reference findings

- **Layout and hierarchy:** Skyrim and the Call of Duty guide place the compass at the top. Horizon is a counterexample that supports keeping the rest of the combat HUD sparse.
- **Threat marker treatment:** Skyrim proves distinct marker shapes and colour, including a red enemy dot. It does not prove Darktide's urgency treatment, so stronger committed-threat emphasis is a design recommendation.
- **Heading:** Skyrim visibly centres the active direction and shows `N`; Call of Duty supplies a location line beneath its compass. Use the fixed centre cue, not a moving heading label.
- **Background and borders:** Skyrim is deliberately ornament-framed. BallHammer's borderless ribbon is an intentional genre fit, not a Bethesda imitation.
- **Label overlap:** no selected primary source demonstrates a usable collision rule. Keep BallHammer's existing horizontal spacing as a product constraint, but collapse text before moving a marker away from its bearing.
- **Behind-player behaviour:** no selected primary source establishes a reusable rear-marker convention. BallHammer must define and test it explicitly, because the `atan2` mapping has a left/right seam at directly behind.

## Concrete recommendation for the Darktide threat compass

Restyle the existing rail as a **threat bearing strip**, not a mini list:

1. Keep the 520 px top-centre placement and the current camera-relative bearing calculation. Retain the fixed centred `^` heading supported by Darktide's HUD font. Keep the shallow translucent backing and no frame strokes.
2. Render every selected threat as a compact vertical pip or diamond on its actual bearing. Keep `^`/`v` as a small glyph above or below the pip, rather than suffixing the enemy name.
3. Give only the committed threat a full callout. When no reaction is committed, use the nearest threat as the focus. Nearby specials remain visible as true-bearing pips while the summary reports the total count.
4. Keep the focused callout on its true bearing. Do not spread labels away from their markers; suppress passive text instead.
5. Treat rear threats as an explicit end-cap state: clamp them to the left or right end, show a rear-facing caret, and hold that side through a small directly-behind hysteresis band so it cannot flicker across the `-pi`/`pi` seam. A rear **committed** threat still gets the full callout; passive rear threats stay marker-only.
6. Use muted red pips and text for nearby specials, then the existing yellow active tone for the committed reaction. Colour communicates urgency without turning every label into an alarm.

This is the smallest visual change that preserves BallHammer's tested threat selection, range, vertical-awareness, and collision behaviour while making direction and urgency legible at a glance.

## Source notes

- The Bethesda manual is the visual source for Skyrim's compass construction and marker legend. The [Bethesda trailer page](https://elderscrolls.bethesda.net/en-US/news/1dcGD5lk0Ss06Q4Eeaa2Mk/skyrim-special-edition-gameplay-trailer-2) is official but its published trailer is not the UI proof used here.
- Guerrilla states that the Horizon footage is fifteen minutes of gameplay captured directly on PlayStation 5. The comparison deliberately records the absence of a horizontal compass in that material.
- Call of Duty's guide is authoritative for top-of-screen placement and the subordinate location name only; it is not visual proof of a compass enemy marker.
