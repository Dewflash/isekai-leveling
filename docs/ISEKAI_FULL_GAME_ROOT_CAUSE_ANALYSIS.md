# Isekai Leveling — Full-Game Root-Cause Analysis

Updated: 2026-07-21

This document is an audit of the current repository against the owner’s
requested end state. It is not a completion claim. Implementation decisions
after this checkpoint must use this analysis as a gate.

## Executive finding

The project is not close to a finished full game. It is a real, testable
vertical slice with meaningful persistence and several authored gameplay
loops, plus a partially integrated Sanctuary A+C art pass. That is valuable
technical progress, but it is not the same product as the requested chill
exploration/adventure game with a dense, scalable, Last Day on Earth-like 2.5D
world.

The main problem is not one missing texture, shader, or button. The current
runtime has two different production models in the same scene:

1. A procedural systems prototype: large box floors, primitive props, hard-
   coded coordinates, and direct construction in `scripts/main.gd`.
2. A generated illustration layer: transparent raster cutouts for selected
   characters and facilities, billboarded into the 3D scene by
   `scripts/sanctuary_style.gd`.

The reference images describe a third model: an authored, dense, coherent
world where the ground, buildings, scaffolding, props, characters, lighting,
occlusion, and camera are designed as one readable composition while still
supporting player-controlled placement. The current model can imitate parts of
that appearance, but it cannot robustly produce the reference result by
continuing to add isolated cutouts and palette adjustments.

## What is genuinely working

The repository has a substantial vertical slice, not an empty mockup:

- `project.godot` launches `res://main.tscn`, which instantiates the current
  `scripts/main.gd` composition root.
- `scripts/game_session.gd` owns a versioned local save, inventory, energy,
  health, day progression, expedition cargo, farming, construction, workshop
  jobs, livestock, research, market receipts, combat state, and migrations.
- `scripts/content_registry.gd` contains five expedition identities, authored
  route branches, discoveries, guardians, recipes, wildlife, inscriptions,
  fishing spots, and progression definitions.
- The current automated suite contains 29 Godot test scripts, including
  physical Whisperwood traversal, later-expedition return, save/reload,
  combat, farming, workshop interiors, shaders, hitbox contracts, and the
  Sanctuary visual contract.
- Audio assets, CC0 music, sampled foley, procedural ambience, shader
  resources, generated character sheets, and generated facility art exist in
  the repository.
- The earlier stale-launch problem was real and has been fixed: the A+C
  presentation authority is now enforced on the launch path every frame, and
  the change is committed as `b1dac70`.

These facts prove that the technical foundation is active. They do not prove
that the game is visually final, content-complete, or ready for players.

## Root causes of the current gap

### 1. Scope was treated as a vertical slice while the request remained full-game

The build status explicitly describes a first professional vertical slice.
The charter requires that slice to be completed first, but the owner’s actual
request continued beyond it: multiple authored maps, real-world sourcing and
adventuring, modular user building, interiors, production-quality animation,
audio, shaders, and a scalable final visual language.

The implementation therefore has many systems with a single authored example,
not a finished content pipeline. A green test for one workshop job or one
Whisperwood branch cannot stand in for a complete game loop across a coherent
content set.

### 2. The live Sanctuary is assembled from incompatible visual authorities

`main.gd` still creates the Sanctuary floor, paths, buildings, farm, pen,
workshop, archive, route gates, trees, and expedition zones directly. It also
creates five maps with mostly shared floor/path construction and a small set of
per-map landmarks (`main.gd`, `_build_world`).

`sanctuary_style.gd` then hides portions of that legacy/procedural tree and
adds generated Sprite3D cutouts. The recent authority guard prevents old
geometry from leaking through, but it does not turn the scene into a single
authored world. The live screenshot is consequently a composited runtime
scene, not a complete illustration or modular 2.5D map.

This explains the visible symptoms:

- broad flat green areas instead of the textured, layered ground in the
  reference;
- sparse edges and repeated generic props instead of authored density;
- buildings that read as pasted cards beside primitive terrain;
- seams between lighting/shading models;
- inconsistent depth and occlusion when a character passes near a structure;
- a UI that can be correct as a contract while the world still feels like a
  prototype.

### 3. Generated building images are not building systems

The workshop cutout is a strong illustration asset, but it is a single
pre-rendered silhouette with transparent pixels. A directional family gives
several camera-facing variants, but it is still not a set of physical walls,
roof pieces, floors, doors, scaffolds, materials, and interior stations.

That distinction is the root of the user-placement problem. If the player can
choose where and how to rotate a building, the asset must expose a stable
world footprint, ground pivot, height, occlusion layers, construction stages,
interaction anchors, and collision contributors. A whole-picture card cannot
reliably supply all of those for arbitrary placement.

The current renderer does measure opaque texture bounds and records metadata,
which is a useful safety improvement. It is still estimating a physical
footprint from a 2D alpha envelope and a profile ratio. That is not equivalent
to measuring the actual walkable base of a building. It is why hitboxes can be
technically “derived” and still look wrong to a player.

### 4. Scale is not defined by one authoritative asset contract

There are several competing scale sources:

- player body limits and movement are authored in `player.gd` world units;
- Sanctuary reserved rectangles and structure grids live in the session and
  registry;
- primitive buildings use direct mesh sizes in `main.gd`;
- illustrated structures use `world_size`, opaque texture bounds, and
  `footprint_ratio` in `sanctuary_style.gd`;
- interior stations derive some collisions from visible mesh bounds;
- sourced Quaternius models use per-call scale values.

These systems can pass local tests while disagreeing visually. A building can
have a valid session footprint, a valid measured Sprite3D envelope, and still
be the wrong apparent size relative to the player, path width, or gathered
wood. The missing source of truth is a production asset specification that
defines real dimensions and anchors before rendering or collision is built.

### 5. Animation is mostly state switching and procedural bobbing, not a full animation pipeline

The player and Mira sheets contain idle/walk rows and four directions. Runtime
code switches the atlas region between idle and walk, while the visible motion
is largely bobbing, rotation, and hidden procedural limb pose updates. It does
not cycle through a multi-frame walk animation, and building cutouts cannot
animate their doors, workstations, construction workers, smoke, cloth, or
individual material stages as authored objects.

The world has some motion—water, beacons, tree sway, pickups, fire, and
procedural shader effects—but “animated” in the requested sense requires
action timelines tied to gameplay markers: gathering contact, attack wind-up,
hit frame, dodge, construction delivery, furnace activity, NPC routines, and
interior transitions.

### 6. Shaders are present but are being asked to solve an asset problem

The project has shaders for foliage sway, water, ground edges, toon surfaces,
and reward glow. These improve selected materials. They cannot create missing
geometry, correct a wrong building footprint, make a low-density map feel
authored, or reconcile a painted building card with a lit 3D floor. The shader
agent’s work is therefore a complement to the asset contract, not a substitute
for it.

### 7. The maps are mechanically distinct but visually under-authored

The five expedition IDs and route branches are real. Their current world
construction still follows a shared procedural zone template with a small
number of primitive landmarks and resource nodes. The game has biome data, but
not five production-ready biome presentations with their own terrain language,
prop families, landmarks, traversal rhythm, and audio identity.

This is the reason “wire in other maps” cannot be considered done merely
because five zone nodes exist. A map is done when it is authored, playable,
readable, visually coherent, and has its own reward/pressure story.

### 8. Verification is stronger on contracts than on player feel

The automated tests are a major strength, but most of them verify state
transitions, node metadata, visibility, or deterministic interactions. They do
not establish that:

- a fresh visible launch looks close enough to the accepted A+C target;
- a player can judge scale without debugging overlays;
- joystick direction feels correct at the fixed camera angle;
- every placed building’s visible base agrees with the actual blocking area;
- the art remains coherent after arbitrary player placement;
- the full workshop interior is visually and audibly convincing;
- touch-safe HUD behavior has been captured on the intended device.

The visual gate is still open by design. Passing contract tests must not be
reported as passing the art/feel gate.

### Update after the 2026-07-21 audit

The Archive is the first follow-up slice from this audit: it now has a
dedicated four-direction construction frame family, authored alpha envelopes,
and a runtime phase overlay that reveals its measured hero silhouette at the
walls/roof milestones. `tests/test_archive_construction_visuals.gd` passes 177
focused checks. This proves that one additional facility can use the intended
construction contract; it does not prove that the full Sanctuary, workshop
interior, five expedition maps, or complete game are finished. The broader
visual gate remains open.

## Status against the requested end state

| Area | Evidence-backed status | Why it is not final |
| --- | --- | --- |
| Core save/progression | Strong vertical-slice foundation | Content and failure matrix are not full-game complete |
| Sanctuary placement | Functional shell and previews | Visual asset, scale, rotation, and collision contract are not unified |
| Building stages | Workshop/storage examples exist | Not a reusable modular construction family for all facilities |
| Workshop interior | Runtime shell and station tests exist | It is not yet the final art/audio/interior presentation |
| Camera/movement | Desktop, mouse, joystick contracts exist | Feel and screen-space direction still need live acceptance |
| Hitboxes | Measurement metadata and tests exist | Several sources still infer instead of sharing one authored footprint |
| Character animation | Player now has a measured four-frame walk cycle per direction; Mira still has directional idle/walk state | Action timelines, Mira's multi-frame cycle, and authored NPC/creature animation coverage remain |
| Sanctuary graphics | A+C generated assets are on the launch path | Live scene is still visibly below the target reference |
| Expedition maps | Five mechanical zones exist | They are not five fully authored production biomes |
| Audio | CC0 music/foley plus procedural layers exist | Depth, variation, and final mix are still a production pass |
| UI | Reference-style HUD contract exists | UI is functionally compact but not yet the final visual system |
| Full game content | Not complete | More authored structures, activities, NPC/quest content, items,
  encounters, and map-specific pacing remain |

## Correct execution order after this audit

1. Freeze feature expansion temporarily. Do not add another generic facility
   or biome by copying the current procedural template.
2. Build an evidence matrix from every charter requirement and mark each one
   `proven`, `partial`, or `missing` with a real file/test/runtime artifact.
3. Establish one production asset contract: world dimensions, grid footprint,
   ground pivot, collision contributors, interaction anchors, occlusion layers,
   construction stages, directional views, animation hooks, and provenance.
4. Rebuild one complete Sanctuary gold-standard slice around that contract:
   player, workshop shell, scaffold/material stages, workshop interior with
   furnaces, pond/path/foliage dressing, NPC, lighting, audio, shaders, and
   placement/hitbox debug validation.
5. Validate the gold-standard slice through a fresh launch and a physical
   walk/placement test. The acceptance target is the owner’s A+C reference
   vibe, not merely a passing scene-tree test.
6. Only after that slice holds, replicate the asset/content pipeline into the
   remaining Sanctuary facilities and then the five expedition biomes.
7. Expand the full gameplay/content layer in parallel with the validated
   presentation system: authored route activities, NPC/quest progression,
   crafting/building chains, interior functions, reward pacing, and failure
   recovery.

## Non-negotiable acceptance gates

The next implementation phase is not accepted until all of these are true:

- A cold launch reaches the current A+C Sanctuary without legacy render leaks.
- The player, paths, fences, resource nodes, buildings, and interiors share a
  visible scale language.
- A placed building can rotate and move while its visual base, occupancy,
  interaction area, and measured collision remain aligned.
- Construction visibly progresses from blueprint to frame to walls/roof to
  operational structure, using the same footprint throughout.
- The workshop opens into a readable interior with furnace/station activity,
  occlusion, lighting, audio, and a clear exit transition.
- The player’s joystick direction matches the camera basis on the actual
  target touch layout.
- Character and NPC motion visibly cycles through authored animation frames or
  timelines; procedural bobbing alone is not sufficient.
- Sanctuary density and lighting are close enough to the accepted reference
  that the screenshot reads as the same game, while leaving layout ownership
  with the player.
- The full authored gameplay loop remains durable through save, reload,
  failure, return, and extraction tests.

## Bottom line

The current work is a strong technical foundation, not a final game. The root
cause of the visual and scale complaints is the mismatch between procedural
prototype geometry plus raster cutouts and the requested modular 2.5D world.
The root cause of “there is always something else to do” is that the project
has been advancing vertical-slice systems and art experiments without first
closing a single production-grade asset/world contract.

The next responsible move is investigation and architecture hardening around
that contract. Feature execution should resume only after the gold-standard
Sanctuary slice proves that the chosen representation can actually scale to
the requested game.

## Update after the 2026-07-23 construction-reveal checkpoint

The two remaining Sanctuary facilities without dedicated construction image
families—Livestock Pen and Rain Cistern—now use their measured directional
operational assets as the construction source. A per-instance shader supplies
the blueprint outline and ground-up material reveal, while legacy procedural
construction meshes are hidden only from rendering. Pixel-backed captures and
the Sanctuary, hitbox, shader, interior, and world-loop contracts pass.

This reduces one presentation inconsistency but does not change the executive
finding: the Sanctuary still needs a denser authored world, broader authored
interiors, richer character/NPC animation and audio, and final device evidence
before the A+C graphics gate is accepted. The five expedition maps and the
full-game content pass remain outside the completed scope.

## Update after the 2026-07-23 Workshop fit-out sync checkpoint

The first-entry Workshop transition had a real state-ordering defect: Main
requested the durable interior station sync at the fade midpoint, while the
interior controller still rejected all syncs during its transition lock. The
result was a valid, operational room that showed only its exit until another
session signal or manual sync occurred. `sync_persisted_stations()` now accepts
the entry-midpoint sync only after the room is active; exit-time late syncs
still fail closed. The runtime regression now proves a persisted furnace is
mounted during first entry, and the pixel-backed fit-out capture shows both
furnaces, workbench, anvil, storage, fire/smoke, and the active production
context.

This closes a player-facing interior state bug. It does not make the Workshop
art/audio final, nor does it close the broader Sanctuary density, character
animation, device, expedition, or full-game content gates.

## Update after the 2026-07-23 spatial machine-audio checkpoint

The Workshop audio gap was narrower and more concrete than the earlier visual
state bug: `near_furnace` only drove one global generator, so a room with two
visible furnaces had no measured spatial machine source. The interior now
publishes the active job's exact furnace position and intensity to the
AudioDirector. The director owns bounded `AudioStreamPlayer3D` sources on the
Stations bus and generates a restrained fire/ember bed; it never mutates job
state. When the job becomes READY or the room exits, the source is removed.

The runtime and audio tests prove creation, spatial metadata, active-job
intensity, READY shutdown, and cleanup. This closes one non-negotiable Workshop
gate; it does not establish final audio variation, indoor filtering/reverb,
Sanctuary visual density, character/creature action animation, device evidence,
the five production biomes, or full-game content.

## 2026-07-23 render/hitbox audit update

The latest Sanctuary evidence separated two issues that had previously been
treated as one. The path/shadow failure was caused by presentation geometry
(scaled cylinders and broad rectangles), while the landmark-size failure was a
collision-authority mismatch: generated A+C art was being scaled to a hidden
imported source shell. The fix keeps the source measurement for proportions and
provenance, keeps the generated asset's measured world size, and rebuilds the
blocking shell from the generated contact footprint. Curved ribbon routes and
shader-backed quads remove the flat oval/ slab artifacts without adding
collision or occupancy claims.

The result is verified by a display-backed capture and the updated hitbox,
shader, visual, camera, HUD, activity, directional-family, and world-loop
contracts. This is evidence that the representation is becoming more coherent,
not evidence that the complete game or accepted A+C graphics bar is finished.
