# Sanctuary graphics checkpoint

Updated: 2026-07-23

Sanctuary is the current art gate for Isekai Leveling. The other biome
presentations remain frozen until this scene reaches the saved reference's
visual bar. The layout of player-owned buildings is not fixed: the reference
sets the visual language, while the authoritative grid/save model owns where
the player builds.

The active A+C visual authority is
`assets/generated/reference/sanctuary-a-plus-c-target.png`. It is a
composition/style target rather than a fixed background: the player remains
free to choose the actual building layout.

## Current visible checkpoint: authored Sanctuary ground

The live scene now mounts
`assets/generated/sanctuary/sanctuary-open-ground-v1.png` as a presentation-only
world plate. It supplies the dense meadow/forest texture, scattered flowers and
stones, and pond treatment that was missing from the smooth prototype floor.
The coverage skirt is shader-driven and has no collision, occupancy, pathing, or
building-layout authority. `GameSession`, the measured shells, and the build
grid remain the only gameplay authorities.

The display-backed proof is saved at
`docs/evidence/sanctuary-open-ground-v1/`. It includes a clean Sanctuary view,
an operational structure focus, and two different player-authored layouts.
This is a real visual improvement, but it is not the final Sanctuary art gate:
the remaining gaps are seamless boundary treatment in every extreme camera
focus, denser hand-authored props/activity coverage, full action animation/audio
polish, and the other biome presentations.

## Implemented in this pass

- Added a dedicated 2.5D presentation layer in `scripts/sanctuary_style.gd`.
  It keeps gameplay state, grid occupancy, material delivery, and collisions
  authoritative in the existing world/session code.
- Added original Codex-generated illustrated prop, environment, player, and
  Mira sheets for scaffold, workshop, tent, market, garden, well/fire, trees,
  rocks, fences, and pond. Their runtime atlas cells are recorded in
  `scripts/sanctuary_asset_catalog.gd`.
- Added a Codex-generated, reference-guided player-facility sheet for Workshop,
  Archive, Storage Shed, Livestock Pen, Rain Cistern, and a future activity
  stall. The runtime uses a hard chroma-keyed RGBA cutout with the generated
  smoke fringe removed; the source sheet remains beside it for provenance.
- Replaced the old low-poly Sanctuary dressing with a soft, warm,
  cartoon/anime-adjacent woodland meadow: rounded terrain islands, organic
  paths, woodland framing, route markers, a pond, fences, material yards, and
  an intentionally open player build reserve. Fixed full-size building and
  activity proxies were removed so the player owns the built layout.
- Added visible construction progression for player structures: placement
  grid/footprint preview, blueprint, early scaffold, mid construction, late
  construction, and operational building. Delivered materials remain visible
  while the structure advances; additive components now render posts, beams,
  separated wall panels with a doorway gap, roof sections, and fittings.
- Added five unique structure profiles with four directional variants each,
  explicit door/service zones, compound runtime collision shapes, and
  construction-component asset IDs. Operational player structures now use one
  distinct illustrated facility silhouette per kind; the imported kit remains
  instantiated for provenance but is hidden from rendering so silhouettes never
  double-render.
- Added Codex-generated four-direction idle art for the player and Mira, plus a
  dedicated four-by-four player walk atlas. Runtime now advances four authored
  walk frames per direction, measures every cell's alpha feet offset, and
  switches back to the stable idle atlas when movement stops.
- Added an asset/collision contract. Canonical authored geometry, quarter-turn
  root rotation, world footprint metadata, and collision extents are tested
  together so a sprite cannot visually drift away from its hit box.
- Added runtime source-geometry measurement in
  `scripts/sanctuary_asset_measurement.gd`. Each player structure recursively
  measures its imported mesh bounds, derives one uniform fit scale and ground
  pivot, and emits its collision shell from those same fitted bounds. The
  catalog no longer carries duplicate per-building collision sizes or wall
  boxes. Resource-tree contact is likewise derived from the actual trunk mesh
  bounds; the canopy remains visual volume rather than an oversized blocker.
- Extended that measured-envelope contract to the remaining collidable asset
  classes: sourced/generated rocks, guardian bodies, route tracks, expedition
  inscriptions, and fixed landmark shells. A missing measurement fails closed
  instead of silently creating a guessed collider; metadata records the source
  asset and measured bounds for QA.
- Tuned the Sanctuary lighting read around a warm directional sun, cool moss
  fill, and localized lantern/hearth pools. Generated illustrated cutouts stay
  unshaded so their authored color remains stable, while sourced 3D geometry
  and contact surfaces receive the world lighting.
- Enlarged the player-owned claims to real 4×4–7×5 metre structures. Compound
  collision components now remain at authored local scale while the root rotates,
  and the build ghost is a rectangular BoxMesh whose dimensions are asserted
  against the same authoritative footprint.
- Locked generated billboard artwork to measured opaque bounds: visible feet,
  ground pivots, visual footprints, source bounds, and feet-based transparent
  sorting are explicit runtime metadata.
- Added two player-authored layout proofs driven through the real placement,
  material delivery, and day-advance path. Layouts differ by 42 occupied cells
  and by more than 65% of sampled rendered pixels.
- Added Mira's walk bob/limb stride proof and removed obsolete operational
  utility descendants that were reading as stray dark prototype geometry.
- Added a safe-area-aware contextual HUD: responsive status/management cards,
  a separate action dock, touch-safe joystick placement, and responsive settings.
- Added a reference-guided gameplay HUD pass: a compact hero/status header,
  vertical stat rail, contextual interact button, quick resource readouts,
  nine context-gated action slots, and cargo/XP feedback. The action belt now uses the
  sourced warm Kenney panel/button textures with large icon/caption treatments,
  while the expanded ledger and settings surfaces remain available on demand
  so the Sanctuary composition is not covered during ordinary traversal.
- Added a save-backed first-return objective chain that drives the reference
  HUD from Mira to the gate, trail, field bundle, extraction, notice-board
  claim, and Workshop. The player-facing objective is now a real progression
  state rather than generic cargo copy.
- Added authored traversal waypoints to every Sanctuary route socket and draw
  their connector paths into the world. A dedicated contract walks all five
  gates through camera-relative joystick input and live physics, with no
  teleporting assertions.
- Added a shared illustrated campfire activity landmark at human scale in the
  player-directed reserve. It is a presentation-only focal point with its own
  cropped fire atlas asset, pulse/light motion, and no occupancy claim, so it
  strengthens the lived-in reference read without deciding the player's build
  layout.
- Added an authored Workshop interior cutaway shell behind live station meshes.
  The stations retain their own measured visible-asset collision proxies, while
  the architecture carries the richer teal timber / stone-floor reference
  language and animated forge lighting. The latest interior pass uses an
  original authored station sheet for the two furnaces, workbench, anvil, and
  storage crate; its opaque alpha bounds are measured at runtime and calibrated
  against the imported station envelope for visual scale and collision depth.
  The custom toon shader now preserves Sprite3D billboarding explicitly, so the
  cutaway remains correctly oriented instead of becoming a skewed card.
- Interior entry now holds a deliberate room-centered camera composition while
  the player moves inside it. The exit doorway is part of the illustrated room
  shell, while the live egress capsule and doorway clearance remain measured
  gameplay geometry.
- Workshop entry/exit now validates the player's full capsule at every egress
  candidate and fails closed if no clear position is available. Construction
  stage sizing uses the selected directional asset's alpha envelope, and the
  flagged pale-green stage fringe is neutralized in the processed PNGs.
- Removed the remaining visible debug furnace presentation from the Sanctuary
  capture while preserving its gameplay root and interaction logic.
- Added a deterministic seven-stage capture harness so visual review can compare
  the same scene states every time.
- Added the first non-Workshop production facility family: Storage Shed now has
  four authored directional operational views, four authored construction-stage
  families for blueprint/frame/walls/roof, declared visible feature sockets, and
  fail-closed missing-art behavior. Its legacy scaffold meshes remain available
  for gameplay/QA metadata but cannot double-render beneath the authored cutout.
- Added authored four-view operational families for Archive, Livestock Pen, and
  Rain Cistern. Each view is a unique chroma-cleaned alpha cutout with measured
  runtime bounds, directional identity, and the same camera-facing/lighting
  contract as Workshop and Storage Shed. Their construction-stage families are
  intentionally still tracked separately rather than being falsely implied by
  the operational art.
- Rebound fixed Hearth, Archive, and Bazaar landmarks onto the same generated
  A+C presentation path. Their imported scenes remain hidden provenance and
  measurement sources; the measured shell collision, access zones, and source
  identity remain authoritative.
- Added a runtime presentation-authority guard so legacy district and facility
  render descendants cannot reappear after save/load or construction refresh;
  interaction roots and measured collision shells remain available to gameplay.
- Darkened the remaining prototype collision-floor backdrop and added a denser
  distant woodland frame so fresh Sanctuary startup no longer presents the old
  bright green prototype plane as its visual base.
- Mounted an original reference-guided open-ground plate and dedicated coverage
  shader. The plate preserves player-directed building freedom while replacing
  the broad smooth-green wash with dense illustrated meadow texture; its
  presentation-only, non-occupying contract is asserted at runtime.
- Synchronized the directional construction presentation with the authoritative
  material milestones: frame through 50% progress, walls through 76%, then roof
  to completion. The renderer derives each cutout's placement from its measured
  alpha envelope and the source-measured projected shell.
- Added the directional-complete layered Workshop construction renderer. q0–q3
  each resolve an authored, alpha-measured AtlasTexture kit into separate
  foundation, timber-frame, wall, roof, and forge-fitting contributors. The
  blueprint/build path no longer uses a single full-building construction card;
  the older complete stage PNG family is retained only for audit/reference.
- Disabled the legacy rectangular procedural base and finished-source shell
  during layered construction. Non-operational construction remains traversable
  and the measured operational shell is the only active structure collision,
  preventing invisible finished walls from disagreeing with the visible build.
- Added renderer-backed Workshop layer evidence at
  `/private/tmp/isekai-sanctuary-layered-v4/`, including blueprint, early frame,
  wall, roof, operational, motion/occlusion, and two player-authored layouts.
- Added a fresh live display-backed Storage Shed evidence set at
  `docs/evidence/sanctuary-scale-v26/`, including the placement preview,
  construction phases, operation, motion/occlusion, and two genuinely different
  player-authored layouts.
- Added measured foot-bearing colliders to the illustrated framing trees and
  rocks. Their canopy pixels remain visual-only, while the blocked footprint is
  sourced from the published visual measurement metadata and verified as a
  Sprite3D/body pair.

## Evidence currently available

- Full Sanctuary capture:
  `docs/evidence/sanctuary-scale-v26/07_operational_structure.png`
- Latest live A+C startup capture:
  `/private/tmp/isekai-a-plus-c-live-v2.png`
- Latest display-backed A+C stage proof:
  `/private/tmp/isekai-a-plus-c-live-stages-v4/01_clean_daylight.png` through
  `10_player_layout_split_workyard.png`
- Persisted A+C evidence set:
  `docs/evidence/sanctuary-a-plus-c-v27/`
- Stage captures:
  `docs/evidence/sanctuary-scale-v26/01_clean_daylight.png` through
  `07_operational_structure.png`
- Motion/occlusion proof:
  `docs/evidence/sanctuary-scale-v26/08_motion_occlusion_00.png` through
  `08_motion_occlusion_03.png`
- Player-authored layout proofs:
  `docs/evidence/sanctuary-scale-v26/09_player_layout_east_courtyard.png`
  and `10_player_layout_split_workyard.png`
- Workshop interior proof:
  `docs/evidence/sanctuary-scale-v26/workshop-interior-authored-stations.png`
- New operational facility assets:
  `assets/generated/sanctuary/archive/archive-q0.png`,
  `assets/generated/sanctuary/livestock_pen/livestock-pen-q0.png`, and
  `assets/generated/sanctuary/rain_cistern/rain-cistern-q0.png` (q1–q3 sit
  beside each q0 asset).
- Saved visual target:
  `assets/generated/reference/sanctuary-a-plus-c-target.png`
- Authored open-ground visual proof:
  `docs/evidence/sanctuary-open-ground-v1/`

## Verification

- `tests/test_sanctuary_visual_contract.gd`: pass, 5,473 checks across all five
  structure kinds and all four rotations, including authored layouts, generated
  pivots/opaque bounds, player-safe access zones, source-measured runtime
  collision centers/sizes, construction metadata, and Mira motion
- `tests/test_sanctuary_directional_families.gd`: pass, 99 checks across Archive,
  Livestock Pen, and Rain Cistern; every operational quarter-turn imports,
  renders, binds its unique authored texture, and publishes measured bounds
- `tests/capture_sanctuary_stages.gd`: pass, seven 1280 × 720 stage captures,
  four motion/occlusion captures, and two player-authored layout captures
- Motion proof: pass, 4.16 m traversal; tree sway, hearth pulse, light flicker,
  rendered-player pixels, Mira articulation, and legacy-geometry checks all passed
- `tests/test_game_session.gd`: pass
- `tests/test_world_loop.gd`: pass
- `tests/test_asset_hitboxes.gd`: pass, 612 checks covering tree trunks, rocks,
  guardians, route/inscription assets, and measured landmark shells
- `tests/test_storage_shed_visuals.gd`: pass, 148 checks covering all four
  directional operational views, all sixteen construction-stage views, visible
  feature declarations, alpha-envelope coverage, and fail-closed metadata
- `tests/test_sanctuary_shader_integration.gd`: pass, 206 checks covering the
  authored ground plate/coverage shader, live moss/path/facility bindings,
  Sprite3D modulation preservation, and the billboarding/light-direction
  shader contract
- Latest display-backed ground proof: pass, full stage harness with motion and
  two player-authored layouts; both layout runs still resolve through the live
  placement/delivery/day-advance path after the ground plate is mounted
- `tests/test_workshop_interior_contract.gd`: pass, 87 checks covering room
  composition, measured station alpha bounds, station collision calibration,
  and the authored shell
- `tests/test_workshop_interior_runtime.gd`: pass, 63 checks covering entry,
  room-centered interior movement, interaction, egress clearance, and exit
- `tests/test_workshop_stage_visuals.gd`: pass, 215 checks covering four
  directional layered Workshop construction families, measured alpha coverage,
  and motion
- `tests/test_camera_controls.gd`: pass
- `tests/test_reference_hud.gd`: pass, 18 checks covering gameplay visibility,
  portrait/status content, first-run objective, sourced belt texture,
  icon/caption slots, wired action slots, context action, and ledger visibility
  switching
- `tests/test_first_run_guidance.gd`: pass, 22 checks covering the ordered
  save-backed first-return chain and reload shape validation
- `tests/test_traversal_contract.gd`: pass, 26 checks across all five gates with
  camera-relative joystick movement and physics release settling
- `tests/probe_sanctuary_assets.gd`: pass for the Sanctuary asset subset
- Godot editor/script checks: pass
- Focused current regression run: pass — session, world loop, Storage Shed,
  shaders, Sanctuary visual contract (5,127 checks), directional facility
  families (99 checks), Workshop interior, hitboxes (612 checks), traversal, and
  Workshop stages. Godot headless scripts
  all exited successfully.
- `git diff --check`: pass on the last completed verification run

Headless Godot still prints the known macOS certificate warning. It is an
environment warning; the focused tests and captures complete successfully.

## 2026-07-22 directional Workshop construction follow-up

- Added and alpha-cleaned q1, q2, and q3 Workshop construction kits. The runtime
  resolves one kit per quarter-turn and applies a fit factor derived from the
  kit's opaque bounds and the imported structure measurement, so visual width
  does not silently drift away from the measured shell.
- `test_workshop_stage_visuals.gd` now passes 215 checks across four directions
  and four construction milestones. This proves the live scene graph and asset
  contracts, but not a finished full-game graphics gate.
- A fresh macOS pixel-backed capture was attempted for the four directions, but
  Godot stalled before creating its capture directory with the current display
  service. The two stalled processes were stopped; no renderer-backed q1–q3
  claim is being made until that environment issue is resolved.

## Visual gate still open

The Sanctuary is now a real, inspectable playable presentation checkpoint and
the main prototype artifacts are gone, but it is not being called final or
reference-complete. The latest evidence is strongest on scale, construction
states, authored layout freedom, measured source hitboxes, motion, and
contextual HUD safety. The remaining bar is visual production quality: more
authored lived-in activity density and variation, more building-specific
construction-stage silhouettes and directional character animation, and device
capture on a real touch-safe-area target. The Workshop now has four authored
operational views and four authored construction-stage views per phase, while
Archive, Livestock Pen, and Rain Cistern have their first authored operational
families. The interior also has an authored cutaway shell behind separately
measured station meshes. The whole Sanctuary gate remains open for the remaining
construction families, exterior sprite lighting device verification, and the
density/occlusion bar against the A+C reference on a real display. Other biome
visual development remains frozen until this Sanctuary bar is explicitly
accepted.

## Agent review record

- Newton reviewed the camera direction and joystick stability.
- Gibbs implemented the fail-closed Sanctuary visual contract, including
  rotation, construction-state, collision, and placement-separation checks.
- The stage-capture worker added the deterministic seven-state visual harness.
- Nash refined the meadow/path palette, irregular edges, wear, and contact
  shadows in the presentation layer.
- Kierkegaard extended the stage harness with traversal, occlusion, motion, and
  legacy-geometry checks.
- Ramanujan completed the requested gpt-5.6-sol ultra visual gate review
  against the saved reference and current captures. Its strict verdict is that
  the direction is correct but the visual gate still fails, so other biomes
  remain frozen.
- Popper completed the gpt-5.6-sol ultra pivot/sorting pass; Boole completed the
  gpt-5.6-sol ultra two-layout proof; Plato removed the obsolete utility render
  descendants; Laplace implemented the safe-area contextual HUD; and Banach
  expanded the deterministic visual contract to 3,005 checks.
- Bacon removed fixed full-size ambient building/activity proxies and restored
  player ownership of the open build reserve. Hegel authored five unique
  structure profiles, directional variants, access zones, and collision
  descriptors. Lorentz expanded the contract for those profiles and additive
  construction metadata. Maxwell's gpt-5.6-sol ultra gate review remains the
  controlling verdict: direction is improving, but the visual gate is still
  open for production density, authored variation, and touch-device evidence.
- Aristotle independently reviewed the player-facility gap and confirmed the
  highest-value slice was replacing the hidden-by-source generic silhouettes
  with distinct illustrated operational assets.
- Erdos audited the same slice's collision, feet, and directional invariants;
-  the measured imported-mesh envelope now drives the runtime shell, and the
  focused visual contract covers 5,127 checks.
- The shader specialist caught and drove the world/view light-space correction,
  mipmap sampler correction, depth-prepass policy, and explicit Sprite3D
  billboard transform. The Workshop interior specialist independently measured
  the skewed-card failure and verified the corrected room-centered cutaway.
