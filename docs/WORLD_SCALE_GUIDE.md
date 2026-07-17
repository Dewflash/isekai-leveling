# Isekai Leveling World Scale Guide

Updated: 2026-07-18

This guide translates the project prompt into a spatial contract. The target is
Last Day on Earth / Green Hell-style readability and traversal weight, filtered
through Isekai Leveling's cozy anime 2.5D language. It is deliberately not a
Stardew-sized character walking between thumbnail buildings.

## Working unit

One Godot world unit is treated as approximately one metre for gameplay
reasoning. The current orthographic camera is 18 units tall, and expedition
floors are 44 × 32 units. The player movement envelope is ±20 units on X and
±15 units on Z; saved expedition anchors use the same limits.

| Element | Current contract | Direction for final scenes |
| --- | ---: | ---: |
| Player collision height | 1.7 m | 1.7–1.9 m |
| Player interaction radius | about 2.35 m | 2.0–2.5 m, contextual |
| Player movement speed | 5.2 m/s | 4.5–5.5 m/s, tuned per biome |
| Route gate approach | 4–5 m pad | readable approach plus sightline |
| Small resource node | 0.5–1.5 m silhouette | hand-sized contact point with clear staging |
| Tree / large prop | 3–5 m silhouette | blocks sightlines and shapes lanes |
| Small building footprint | 2–4 m cells | walkable entrance and service side |
| Expedition traversal | authored topology metadata ≥50 m in Whisperwood | 60–90 seconds including beats and actions |

## Spatial rules

- A building is a spatial claim: the player should see the frame, material piles,
  entrance, utility silhouette, and the route it leaves open.
- A route is a sequence of places, not a rectangular floor with labels. The
  first authored Whisperwood pass therefore exposes Arrival Grove, Old Trail
  Fork, Fern Grove, Guardian Clearing, and Return Footbridge.
- The avatar must remain readable against sourced Quaternius silhouettes. Props
  may be large enough to occlude a lane, but never so large that the player
  loses the character without a deliberate foreground-fade solution.
- Labels explain a discovered landmark; they are not the navigation system.
  The path, collision, lighting, color, sound, and landmarks must communicate
  the next decision first.
- Sanctuary building placement stays player-directed. Fixed shells and route
  reservations protect the playable skeleton, while the player's structures
  provide the changing skyline and utility.

## Evidence status

The scale contract is currently enforced by constants, collision shapes, route
metadata, and deterministic tests. It is not yet visual sign-off: authored
PackedScenes, camera bounds, foreground occlusion, and desktop/mobile screenshot
evidence remain future gates. Never describe the current build as five final
authored maps or a content-complete commercial game.
