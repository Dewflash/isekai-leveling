# Sanctuary graphics checkpoint

Updated: 2026-07-20

Sanctuary is the current art gate for Isekai Leveling. The other biome
presentations remain frozen until this scene reaches the saved reference's
visual bar. The layout of player-owned buildings is not fixed: the reference
sets the visual language, while the authoritative grid/save model owns where
the player builds.

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
- Added Codex-generated four-direction idle/walk atlases for the player and
  Mira, with runtime direction-frame switching and feet-anchored sorting.
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
  eight wired action slots, and cargo/XP feedback. The action belt now uses the
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
- Removed the remaining visible debug furnace presentation from the Sanctuary
  capture while preserving its gameplay root and interaction logic.
- Added a deterministic seven-stage capture harness so visual review can compare
  the same scene states every time.
- Added measured foot-bearing colliders to the illustrated framing trees and
  rocks. Their canopy pixels remain visual-only, while the blocked footprint is
  sourced from the published visual measurement metadata and verified as a
  Sprite3D/body pair.

## Evidence currently available

- Full Sanctuary capture:
  `docs/evidence/sanctuary-scale-v24/07_operational_structure.png`
- Stage captures:
  `docs/evidence/sanctuary-scale-v24/01_clean_daylight.png` through
  `07_operational_structure.png`
- Motion/occlusion proof:
  `docs/evidence/sanctuary-scale-v24/08_motion_occlusion_00.png` through
  `08_motion_occlusion_03.png`
- Player-authored layout proofs:
  `docs/evidence/sanctuary-scale-v24/09_player_layout_east_courtyard.png`
  and `10_player_layout_split_workyard.png`
- Saved visual target:
  `docs/reference/sanctuary-final-look-reference.png`

## Verification

- `tests/test_sanctuary_visual_contract.gd`: pass, 4,999 checks across all five
  structure kinds and all four rotations, including authored layouts, generated
  pivots/opaque bounds, player-safe access zones, source-measured runtime
  collision centers/sizes, construction metadata, and Mira motion
- `tests/capture_sanctuary_stages.gd`: pass, seven 1280 × 720 stage captures,
  four motion/occlusion captures, and two player-authored layout captures
- Motion proof: pass, 4.16 m traversal; tree sway, hearth pulse, light flicker,
  rendered-player pixels, Mira articulation, and legacy-geometry checks all passed
- `tests/test_game_session.gd`: pass
- `tests/test_world_loop.gd`: pass
- `tests/test_asset_hitboxes.gd`: pass, 609 checks covering tree trunks, rocks,
  guardians, route/inscription assets, and measured landmark shells
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
- Full current regression run: pass — audio feel, camera controls, progression
  registry, expedition loops, progression runtime, session, world loop, and
  Sanctuary visual contract (4,999 checks)
- `git diff --check`: pass on the last completed verification run

Headless Godot still prints the known macOS certificate warning. It is an
environment warning; the focused tests and captures complete successfully.

## Visual gate still open

The Sanctuary is now a real, inspectable playable presentation checkpoint and
the main prototype artifacts are gone, but it is not being called final or
reference-complete. The latest evidence is strongest on scale, construction
states, authored layout freedom, measured source hitboxes, motion, and
contextual HUD safety. The remaining bar is visual production quality: more
authored lived-in activity density and variation, more building-specific
silhouettes and directional character animation, and device capture on a real
touch-safe-area target. The five operational facility identities are distinct,
but the current facility atlas is still one camera-facing cutout per kind;
four-direction facility raster variants and stronger 3D operational models
remain before the directional-art requirement is complete. Other biome visual
development remains frozen until this Sanctuary bar is explicitly accepted.

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
  the measured imported-mesh envelope now drives the runtime shell, and the
  focused contract covers 4,999 checks.
