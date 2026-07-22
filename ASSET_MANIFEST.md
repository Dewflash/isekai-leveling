# Sourced Asset Manifest

Imported by the assistant on 2026-07-18 for the Prodewty game build.

## Codex-generated Sanctuary illustration sheets

- Creator/source: Codex image generation, then locally chroma-key processed
  into runtime atlas sheets
- License/status: Original generated project artwork; no external asset license
  dependency
- Files: `assets/generated/sanctuary/settlement-props-sheet.png` and
  `assets/generated/sanctuary/environment-sheet.png`
- Runtime use: soft 2.5D Sanctuary props, construction stages, woodland
  dressing, fences, rocks, and pond; atlas ownership and collision dimensions
  are defined in `scripts/sanctuary_asset_catalog.gd`

These sheets are presentation assets only. Player-selected building placement,
construction state, material delivery, and hit boxes remain authoritative in
the Godot gameplay/session code.

## Codex-generated Workshop work-yard kit

- Creator/source: Codex image generation, then locally chroma-key processed
  into a transparent RGBA cutout
- License/status: Original generated project artwork; no external asset license
  dependency
- Files: `assets/generated/sanctuary/workshop/workshop-yard-kit-source.png` and
  `assets/generated/sanctuary/workshop/workshop-yard-kit.png`
- Runtime use: presentation-only Workshop bench, tool wall, log rack, anvil,
  crates, lantern, and charcoal dressing, positioned from the Workshop's
  measured footprint and catalogued door/service zones
- Runtime contract: it contributes no physics body or movement blocker; the
  operational Workshop shell remains the sole measured gameplay collision
  authority

## Codex-generated Workshop layered construction kit

- Creator/source: Codex image generation, then locally chroma-key processed
  into a transparent RGBA atlas
- License/status: Original generated project artwork; no external asset license
  dependency
- Files: `assets/generated/sanctuary/workshop/workshop-construction-kit-source.png`
  and `assets/generated/sanctuary/workshop/workshop-construction-kit.png`, plus
  the matching `workshop-construction-kit-q1[-source].png`,
  `workshop-construction-kit-q2[-source].png`, and
  `workshop-construction-kit-q3[-source].png` direction kits
- Runtime use: all four Workshop construction directions use measured
  foundation, timber frame, wall panels, roof, and forge-fitting layers; the
  layers advance from blueprint through the authoritative construction
  milestones
- Runtime contract: each layer is an alpha-measured AtlasTexture region with a
  feet pivot, explicit render order, presentation-only collision metadata, and
  a measured fit to the imported physical envelope. The older complete stage
  PNG family remains in the manifest as audit/reference material, not live
  construction rendering.

## Codex-generated player facility sheet

- Creator/source: Codex image generation guided by the saved Sanctuary
  reference, then locally hard-chroma-key processed and smoke-masked
- License/status: Original generated project artwork; no external asset license
  dependency
- Files: `assets/generated/sanctuary/player-structures-sheet-source.png` and
  `assets/generated/sanctuary/player-structures-sheet.png`
- Runtime use: distinct operational cutouts for the Workshop, Archive, Storage
  Shed, Livestock Pen, Rain Cistern, and a reserved future activity stall
- Runtime contract: the source sheet is a 2 × 3 atlas; each cutout is feet
  anchored and bound to the authoritative structure collision footprint. The
  imported village kit remains instantiated for provenance but does not render
  over these operational silhouettes.

## Codex-generated Sanctuary character sheets

- Creator/source: Codex image generation, then locally chroma-key processed
  into runtime atlas sheets
- License/status: Original generated project artwork; no external asset license
  dependency
- Files: `assets/generated/sanctuary/player-direction-sheet.png` and
  `assets/generated/sanctuary/mira-direction-sheet.png`, plus the separate
  `assets/generated/sanctuary/player-walk-sheet.png` four-by-four walk atlas
- Runtime use: measured four-direction idle art for the player and Mira, and a
  four-frame walk cycle per player direction. Each atlas retains explicit feet
  pivots, per-cell animation metadata, and Sprite3D sorting anchors

The player walk source is generated from the existing character design and
locally chroma-key processed into the transparent runtime atlas. The source is
retained beside the cleaned sheet for provenance.

The generated source sheets are retained beside the cleaned runtime sheets for
provenance; the game loads only the transparent RGBA runtime sheets.

## Original procedural wildlife

The ambient fauna pass does not rely on a third-party animal download. The
silhouettes are generated from original Godot low-poly primitives in
`scripts/main.gd`: Meadow Rabbit and Grove Beetle in Whisperwood, Tidepool Crab
on Sunlit Beach, Ridge Marmot on Ember Ridge, and Glass Lizard in the Glass
Desert. `scripts/wildlife_creature.gd` supplies idle, wander, flee, and observed
animation. Only the observation ID is persisted; deterministic map positions
are rebuilt on load.

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

## Quaternius LowPoly Medieval Village Pack — Sanctuary

- Creator: Quaternius
- Source page: <https://opengameart.org/content/lowpoly-medieval-village-pack>
- Download archive: <https://opengameart.org/sites/default/files/medieval_village_pack_-_dec_2020.zip>
- License: CC0 1.0 Universal, confirmed by the included `License.txt`
- Archive filename: `medieval_village_pack_-_dec_2020.zip`
- Archive SHA-256: `c38d8632c3c883043809a5db9b2f47b7033e298ab4bd073bb5c29ad323df60fc`

This is the Sanctuary presentation kit. The checked-in FBX subset includes
the Inn, House, Blacksmith, Stable, market stands, cart, well, paths, fences,
bonfire, benches, crates, barrels, and farm dressing. The original Blender and
OBJ authoring exports remain available inside the downloaded archive but are
ignored by version control because the runtime uses the imported FBX scenes.
`scripts/sanctuary_district.gd` owns only presentation dressing; placement,
occupancy, collision, and save data remain in the existing Sanctuary model.

## Quaternius Farm Animal Pack

- Creator: Quaternius
- Official source page: <https://quaternius.com/packs/farmanimal.html>
- Author-published mirror used for the downloadable archive: <https://opengameart.org/sites/default/files/Farm%20Animals%20by%20%40Quaternius.zip>
- License: CC0; the archive includes `Farm Animals by @Quaternius/License.txt`
- Archive filename: `Farm-Animals-by-Quaternius.zip`
- Archive SHA-256: `9ff42b7e2445eaf259e4734c08172637db92e4b59a6145909ac56d946152c39b`
- Contents: Cow, Horse, Llama, Pig, Pug, Sheep, and Zebra in FBX, OBJ, and
  Blender formats.

The source family is checked in for the living-world asset pass. Godot 4.7's
built-in FBX importer successfully imports these FBX files as `PackedScene`
resources with their rigs and animation clips available; glTF conversion is not
required. The runtime uses `Cow.fbx` as an ambient paddock resident and starts
its imported `Armature|Walk` clip when present. Clover keeps the procedural
fallback because this pack has no chicken model and the egg-producing resident
must remain consistent with the game rules.

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
