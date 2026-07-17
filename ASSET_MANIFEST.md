# Sourced Asset Manifest

Imported by the assistant on 2026-07-18 for the Prodewty game build.

## Quaternius Stylized Nature MegaKit — Standard

- Creator: Quaternius
- Primary source: <https://quaternius.com/packs/stylizednaturemegakit.html>
- Download page: <https://quaternius.itch.io/stylized-nature-megakit>
- Author-published mirror used for the archive: <https://opengameart.org/content/stylized-nature-megakit>
- License: CC0 1.0 Universal, confirmed by the pack page and the included `License_Standard.txt`
- Archive filename: `Quaternius-Stylized-Nature-MegaKit-Standard.zip`
- Archive SHA-256: `298f6732b872e4cf7b30e6e7abf9641c7f6dc6b326df37ac089533ed7e3d58c9`

The archive was checked with `unzip -t` before extraction. The build keeps the
`glTF/` subset and the license file under
`assets/quaternius-stylized-nature/`. `scripts/main.gd` uses Godot’s
`GLTFDocument` to parse the checked-in `.gltf` sources at runtime, with the
procedural meshes remaining as readable fallbacks if an asset cannot load.

Models currently used in the game include `CommonTree_2`, `CommonTree_3`,
`Pine_1`, `DeadTree_1`, `DeadTree_2`, `DeadTree_3`, `Rock_Medium_1`, and
`Mushroom_Common`. The dead-tree variants are landmark dressing in Glass
Desert and Sunken Dungeon; the other listed trees and rocks are resource or
environment dressing. The Whisperwood route also instantiates `Fern_1`,
`Grass_Common_Tall`, `RockPath_Round_Small_1`, and `Pine_3` as its fork and
clearing dressing.

## Quaternius Farm Animal Pack

- Creator: Quaternius
- Official source page: <https://quaternius.com/packs/farmanimal.html>
- Author-published mirror used for the downloadable archive: <https://opengameart.org/sites/default/files/Farm%20Animals%20by%20%40Quaternius.zip>
- License: CC0; the archive includes `Farm Animals by @Quaternius/License.txt`
- Archive filename: `Farm-Animals-by-Quaternius.zip`
- Archive SHA-256: `9ff42b7e2445eaf259e4734c08172637db92e4b59a6145909ac56d946152c39b`
- Contents: Cow, Horse, Llama, Pig, Pug, Sheep, and Zebra in FBX, OBJ, and
  Blender formats.

The source family is checked in for the living-world asset pass. The current
resident keeps a procedural fallback because the freely mirrored pack is OBJ/
FBX/Blend rather than glTF; this is recorded explicitly instead of pretending
that an unsupported runtime import is active.

## Kenney RPG Audio

- Creator: Kenney
- Official source page: <https://kenney.nl/assets/rpg-audio>
- License: CC0; included `License.txt`
- Archive filename: `kenney_rpg-audio.zip`
- Archive SHA-256: `6dbeaf8544da958d8f2adcb4a4a4b76c1ade34a05f8ab9edccd327da7375f38b`
- Runtime use: footsteps, chopping, knife impacts, book/discovery, coin/quest,
  and metal craft samples routed through the Effects bus.

## Kenney Interface Sounds

- Creator: Kenney
- Official source page: <https://kenney.nl/assets/interface-sounds>
- License: CC0
- Archive filename: `kenney_interface-sounds.zip`
- Archive SHA-256: `f2193d072726d6758a5f7871b2dcc54dcce0d5c35c6f0a62f92549b327c81232`
- Runtime use: sampled UI click feedback.

## CC0 Music Loops

- Source: [Two Simple Game Music Loops](https://opengameart.org/content/two-simple-game-music-loops)
- License: CC0 as published by the author on OpenGameArt
- Files: `assets/sourced/cc0-music/sanctuary-loop.ogg` and
  `assets/sourced/cc0-music/expedition-loop.ogg`
- SHA-256: `3028433d60fa198ac919a934aef07256e1bf81eeb585f25426fd57f2a76cee7d`
  and `5323dfe7f172e6b85870790f60027a533bd87bfd233e6c99cab0caf923f68f3f`
- Local source note: `assets/sourced/cc0-music/SOURCE.txt`
- Runtime use: looped Sanctuary/expedition music through the independent Music
  bus; weather and action foley remain separate layers.

## Kenney UI Pack Adventure and Mobile Controls

- Creator: Kenney
- Official sources: <https://kenney.nl/assets/ui-pack-adventure> and
  <https://kenney.nl/assets/mobile-controls>
- License: CC0
- Archives: `kenney_ui-pack-adventure.zip` and `mobile-controls-1.zip`
- SHA-256: `982e8ab66842509ee9214f9c2038e594cbe029f19d1dc177fecaad3b41a67ed3`
  and `7331c648651858fb3186a8c76e0e360e4d3ea71cfec9b502eb5cbb04a02e192b`
- Use: checked-in UI and touch-control source libraries for the safe-area and
  touch theme pass; the current HUD keeps a procedural fallback theme.
