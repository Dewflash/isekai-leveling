# Prodewty Build Status

Updated: 2026-07-22, Asia/Singapore

## Current target

- Local checkout: `/Users/kevinyongcj/Programming/isekai-leveling`
- Remote: `https://github.com/Dewflash/isekai-leveling.git`
- Remote code checkpoint: latest pushed commit on
  `codex/visual-workshop-storage-operating`
- Staging project: `/Users/kevinyongcj/Documents/Codex/2026-07-17/wha/work/isekai-leveling`
- Godot: `4.7.stable.official.5b4e0cb0f`
- Xcode: `26.5`
- Active Sanctuary art authority: `assets/generated/reference/sanctuary-a-plus-c-target.png`
- Latest live A+C capture: `/private/tmp/isekai-a-plus-c-live-v2.png`
- Latest display-backed stage proof: `/private/tmp/isekai-a-plus-c-live-stages-v4/`
- Persisted A+C evidence set: `docs/evidence/sanctuary-a-plus-c-v27/`
- Launch note: restart any Godot editor or export opened before the A+C
  authority checkpoint; stale/committed builds cannot render the new assets.

## What exists (current checkpoint)

- Godot project bootstrap and main scene
- Procedural low-poly Sanctuary plus five wired expedition maps: Whisperwood,
  Sunlit Beach, Ember Ridge, Glass Desert, and Sunken Dungeon
- Orthographic 2.5D camera and player movement
- Keyboard, mouse, and virtual joystick movement input
- Resource gathering, banked inventory, at-risk expedition cargo, energy, XP,
  sleep/day advance, safe camps, heat hazard, and biome-specific recovery packs
- Progression unlocks now have authored gameplay consequences beyond the HUD:
  Emberfall/Frostveil crop pressure is mitigated by Verdant Steward, Vein Reader
  reveals nearby mineral grades, and the Sunken Dungeon contains a Deep
  Veinstone seam that is closed until Deep Delver and pays its bonus in the
  authoritative harvest transaction.
- The Bazaar is now a deterministic daily sourcing loop: demand varies by day,
  Appraiser's Eye reveals the quality signal, Caravan Contacts adds one rotating
  specialist lot, each offer has a persisted one-trade receipt, and the market
  resets only through the normal dawn transaction. Guild Broker now adds one
  deterministic bulk contract per day with doubled sourcing cost, premium
  payout, Trading mastery, and a persisted one-settlement receipt; save
  migration was introduced at version 20; the current save schema is version 25.
- Sunlit Beach now has an authored tidepool fishing station. Coastal casts are
  bound to an active expedition; Tide Reader resolves a deterministic favorable
  tide into an uncommon shell catch, and the shell is paid atomically with the
  persisted fishing claim. Save migration is now at version 25, with Workshop
  tool recipes included in the same durable job contract.
- Crafting Quality Work and Masterwork Bench now resolve real Workshop tool
  jobs: Reinforced Hatchet and Masterwork Pickaxe consume expedition materials,
  advance over authored hours, restore tool durability at claim, and reject
  forged tool outputs at the save boundary.
- Sanctuary Breeder now resolves repeated feed → sleep → collect care cycles:
  Clover's persisted nurture progress unlocks the authored Sunplume trait,
  which adds a quality egg at collection; unknown trait ids are rejected at the
  save boundary.
- Expedition lore is now physical and branch-bound: five authored plaques live
  on route maps, Context Reader translates regional inscriptions, World Polyglot
  unlocks the ancient vault verse with its reward multiplier, and translated
  receipts migrate/save atomically.
- Hunting now has physical and combat-facing progression: route track markers
  create persisted Track Sign notes, Clean Shot amplifies the first unaware hit,
  and Ambush Sense warns before a guardian wind-up.
- Five guardian variants with distinct movement/telegraph/recovery profiles and
  reward-specific loot
- Combat now has authoritative guarded-hit reduction, permission-backed heavy
  guard breaks, and a persisted-run-safe stagger/recovery state so a guardian
  cannot chain attacks through its own telegraph or resume a stale wind-up after
  a zone transition. Guard, break, impact, audio, camera, and haptic feedback
  share the resolved hit result.
- The latest action-boundary pass now keeps guardian guarding true through the
  full telegraph, cancels gathering on damage/dodge/attack interruption, rejects
  no-energy attacks before they wake enemies, pauses simulation on application
  focus loss until focus returns, closes settings cleanly from the pause control,
  and rolls failed fishing reel saves back to the pre-action snapshot.
- Save commits now verify the exact serialized payload that was atomically
  renamed, avoiding false failures from parsed Dictionary equality while still
  rejecting malformed or partial final files.
- Player attacks now run through an explicit wind-up → active contact → recovery
  state. The active frame queries a measured physics hit shape against named
  guardian collision bodies, falls back only to that same collision profile when
  a just-teleported body has not published its broadphase transform, and shows a
  visible slash/tool prop instead of resolving damage at button press.
- Guardian behavior IDs now drive distinct runtime combat movement: chasers
  pursue directly, bruisers commit with a slower close, skirmishers orbit/space
  and retreat after a committed strike, and sentinels remain dormant until a
  real alert. Retreat and spacing are readable in-world and reset on route
  transitions; `tests/test_guardian_behaviors.gd` covers the roster and motion
  contracts.
- Furnace state and proximity-aware audio context
- Procedural original audio layers for ambience, rain, fire, footsteps,
  gathering, and impact feedback
- Authoritative `GameSession` with versioned local JSON saves, backup recovery,
  idempotent real-life effort receipts, stats, levels, mastery values, and
  target-day transactions
- The temporary local effort bridge now requires an in-process monotonic
  25-minute timer and capability-bound receipt; unfinished timers are cleared
  on disk reload, forged elapsed metadata is rejected, and gameplay XP no
  longer mints Ability Points. Ability Points remain an activity milestone.
- Autosave failures now remain visible through a retry state, unreadable saves
  suppress background overwrite and require an explicit two-step replacement,
  and future-schema saves remain read-only with a coherent startup warning.
- Sanctuary garden loop: till, plant, water, sleep, harvest, and visual crop
  stages
- Persisted Workshop construction/station loop: pay the shell, sleep to finish
  the build, start planks, advance the day, and claim output
- Expedition runs persist their biome, run ID, cargo, depleted node IDs, and
  anchor; reload resumes the run instead of silently returning home
- Expedition harvesting now leaves a persisted, visible field bundle at the
  source. Walking to it pays cargo, discovery progress, route quota, XP, and
  mastery; partial pickup is explicit when the satchel is full, and extraction
  clearly leaves uncollected ground drops behind.
- Fainting banks the kept half of odd/even cargo and drops the lost half in the
  biome where the run ended; packs expire on that run's next daily reset
- One-use expedition camps restore energy; Glass Desert drains energy over time
- Notice Board contract loop, Mira wayfarer NPC with hour-based Sanctuary
  routines, Archive discoveries with overnight research, and recurring daily
  contracts
- Sanctuary fishing loop (fiber bait → fish) and Bazaar loop (fish, shell
  trinkets, or wheat → coins), plus Workshop bread/plank recipes
- Connected survival layer: durable hatchet/pickaxe/knife state, interruptible
  gathering wind-up with movement cancellation, food/hydration choices, explicit
  recipe selection, and a day-based Clover livestock loop (feed → sleep → egg)
- Food and water controls remain available during an active expedition, so
  field survival choices affect the run instead of being Sanctuary-only UI.
- Grid-backed Sanctuary placement: a Rain Cistern can be previewed on a valid
  footprint, persisted as a player-authored blueprint, supplied with visible
  Wood/Plank deliveries, completed as a scaffold over sleep, and then produces
  extra water each day
- Tier-zero Workshop bootstrap is loop-safe: the first player-owned Workshop
  consumes gathered Wood and Stone only; Planks are produced after it becomes
  operational and feed later district upgrades.
- The same authoritative staged construction registry now covers Workshop,
  Archive, Livestock Pen, and Storage Shed blueprints; material delivery is
  visible on site, operational walls/utilities appear only after the build,
  and permanent starter shells yield to player-placed operational buildings
- Player-owned Workshop and Storage Shed visuals now have distinct timber
  framing, gabled roofs, working forge/hammer/smoke or loading-crane/pulley
  motion, and operational labels that appear contextually instead of covering
  the whole Sanctuary. The sourced paddock cow is normalized to human-world
  scale and idles when stationary.
- All five player-placeable facility kinds now have distinct Codex-generated
  operational cutouts tuned to the saved Sanctuary reference. The imported
  village kit remains available as provenance/future directional source data,
  but only one illustrated operational silhouette renders at a time; the
  corrected alpha sheet is reimported and smoke-fringe checked in the
  display-backed stage capture.
- Archive construction now has a dedicated authored four-direction frame kit
  for blueprint/frame/walls/roof stages. The same measured, ground-pivoted
  silhouette remains tied to the authoritative construction footprint, and the
  walls/roof milestones reveal the matching directional hero overlay instead of
  falling back to generic scaffold art. Focused runtime proof passes with 177
  checks; this closes the Archive-family gap only and is not the full Sanctuary
  art gate.
- The player-owned Archive now has a measured interior transition: its room
  envelope is derived from the placed House_3 source measurement, the entry
  and egress retain the authored door facing for all four rotations, and the
  interior exposes a research desk plus a real exit station. The desk uses a
  visible-envelope-derived collision proxy and routes into the existing
  research transaction; focused runtime proof passes with 95 checks, while the
  Workshop interior and persistence contracts remain green. This is a systems
  checkpoint, not the final Sanctuary visual pass: an exterior screenshot will
  remain materially unchanged until the authored Sanctuary density/building
  family pass is implemented.
- Fixed Sanctuary landmarks now use the same generated A+C presentation path:
  Hearth, Archive, and Bazaar retain their measured imported source scenes only
  as hidden provenance/measurement nodes while their visible roots render the
  generated cutouts. Their authoritative shell collisions and access zones are
  unchanged.
- The A+C presentation director now reasserts its authority every frame. The
  legacy district, sourced landmark nodes, and legacy facility silhouettes stay
  hidden after save/load and construction refreshes while interaction roots and
  measured collision shells remain intact.
- The A+C live presentation pass now darkens the prototype collision-floor
  backdrop and adds distant woodland framing without claiming build cells or
  adding interactive blockers.
- Sanctuary placement now supports authoritative ninety-degree blueprint
  rotation with rotated footprint collision checks; Storage Sheds are
  explicitly repeatable while progression buildings remain unique.
- Storage Shed operation is now a real progression consequence: each
  operational shed adds four satchel slots, and the finished capacity survives
  save/load. Workshop tonic remains research-gated in the authoritative job
  command, not only in the recipe picker.
- Mastery thresholds now grant persistent permissions with gameplay effects:
  Crafting 20 unlocks cheaper Field Repair, Trading 20 unlocks 25% Market Favor,
  and Attacking 20 unlocks +2 Combat Training light-attack damage. Unlocks are
  emitted as feedback and reconstructed from saved mastery values.
- Five physical Sanctuary route gates now identify and approach-gate the five
  expedition maps; the destination selector is no longer a global teleport
- Five route gates, paths, approach pads, and build reservations share one
  immutable route-socket definition; all five destinations are tested through
  actual interaction and out-of-range entry is rejected
- Whisperwood now has a real first-route decision: the physical trail marker
  commits the player to Grove or Clearing, only the matching capstone completes
  the objective, and one branch cache spends Energy and opens a shortcut. The
  branch, capstone, cache, and shortcut state persist with the expedition run.
- Whisperwood now has an authored topology layer with Arrival Grove, Old Trail
  Fork, Fern Grove, Guardian Clearing, Return Footbridge, collision-backed
-  bramble edges, shared landmark sockets for the actual grove/guardian
  objectives and caches, physical endpoint checkpoints, and a measured
  traversal contract instead of only the generic arena grammar.
- Whisperwood route scale now tightens the expedition camera to a local
  2.5D framing, moves the living objectives onto their authored endpoints,
  and persists the route phase only after the committed endpoint is physically
  reached.
- The first expedition now has a complete scene-level acceptance loop: the
  player physically reaches the fork and endpoint, harvests a discovery into a
  ground drop, collects it into at-risk cargo, opens the cache, survives a
  pressure tick across a scene reload, crosses the Return Footbridge, and
  extracts into banked Sanctuary inventory. Cached Whisperwood runs cannot
  bypass that return landmark by pressing Extract at the beacon.
- Sanctuary route sockets now publish authored traversal waypoints. Their
  connector paths render in-world, and the five-gate traversal contract drives
  the real camera-relative joystick through physics bodies instead of teleport
  assertions.
- The first-save objective chain is now persistent and visible in the reference
  HUD: Mira → gate → trail → field bundle → extraction → notice-board claim →
  Workshop. It is save-validated and reload-tested rather than represented by
  generic cargo text alone.
- Gathering contacts now leave visible chop/crack marks and stage labels,
  resolve resource mutation on the tool's strike frame, emit spatial noise on
  every field contact and footstep, and leave authored rubble or cut-fiber
  residues where a resource profile provides them.
- Guardian noise now enters an investigate state before chase, uses grounded
  distance for hearing, and preserves an attack telegraph through a guarded
  light hit; only a guard break cancels the wind-up. Investigation now resolves
  at the measured attack/contact envelope instead of sticking against the
  player's physics body.
- Expedition maps now carry a living signature: procedural Meadow Rabbits and
  Grove Beetles in Whisperwood, Tidepool Crabs on Sunlit Beach, Ridge Marmots
  on Ember Ridge, and Glass Lizards in the Glass Desert. They idle, wander,
  flee, can be observed from the contextual interaction rail, and persist only
  their field-journal observation so map dressing remains deterministic.
- Return pressure now affects the first forest route as well as later biomes;
  biome intervals are tuned to create a meaningful return leg, and the Glass
  Desert has a physical oasis shade volume that pauses heat pressure.
- Fresh-save blueprint reachability is tested end-to-end at the session layer:
  Workshop bootstrap, Archive construction, discovery research, and later
  Livestock Pen permission no longer form a circular deadlock.
- Keyboard, gamepad buttons, left-stick motion, touch joystick, and contextual
  actions share the same runtime input-map path; stack-sized construction
  deliveries keep the physical delivery feedback without requiring one press per
  raw unit.
- Desktop mouse now has a real camera-projected click-to-move path with a
  world-space destination marker. Keyboard, gamepad, and touch input take
  priority and cancel the click target, while zone changes clear it safely.
  Arrival, placement, focus loss, sustained no-progress, and blocked shell
  approaches now clear navigation without residual momentum; movement/audio
  feedback is based on actual displacement.
- The angled camera now follows the player at a fixed authored yaw/pitch. A
  held joystick keeps one stable screen direction while the player moves,
  instead of inheriting transient follow drift; translated-viewport touch input
  is covered by the camera-control regression suite.
- Persisted Settings now expose independent master/music/ambience/weather/
  effects/interface mix controls plus screen-shake and touch-haptics toggles.
  Settings migrate through save version 11 and apply to Godot audio buses.
- Saved sanctuary reference image and acceptance notes now distinguish visual
  direction from player-owned building layout
- Sanctuary has received a density/material pass toward the reference: a soft
  woodland perimeter, meadow islands, flowers/rocks, decorative crop beds,
  material yards, stable/market overflow, and a procedural warm Hearth ring
  layered around the sourced village kit while preserving the player build
  reserve.
- Sanctuary now has a dedicated illustrated 2.5D presentation layer with
  Codex-generated atlas sheets, player-directed placement previews, visible
  blueprint/scaffold/partial/operational construction stages, and an explicit
  sprite-to-hit-box asset contract. The visual target is the saved reference;
  the player's building layout remains authoritative and free-form.
- The Sanctuary art pass now uses a mid-value moss/olive ground, narrower warm
  paths, irregular meadow edges, wear, contact shadows, a softer cozy HUD card,
  and a more readable illustrated player silhouette. A deterministic motion
  proof covers traversal, tree sway, hearth pulse, light flicker, player
  visibility, Mira's articulated stride, and legacy/debug geometry suppression.
- Sanctuary now has a shared illustrated campfire activity focal point at human
  scale. Its cropped atlas region, pulse/light motion, and presentation-only
  footprint are contract-checked without consuming player placement cells.
- Generated Sanctuary billboards now anchor to measured opaque bounds with
  explicit asset IDs, ground pivots, visual footprints, source bounds, and
  feet-based sorting metadata. Authoritative structure collision extents and
  rotated footprints are checked against those presentation contracts.
- Two player-authored layout captures are proven through the real
  `can_place_structure → place_structure → deliver_structure_material →
  advance_day` path, with 42 occupied-cell difference and 65%+ render
  difference. Obsolete operational utility descendants that read as stray dark
  geometry are suppressed while their gameplay roots and animation hooks stay
  active.
- The HUD now has a logical device-safe-area conversion, responsive status and
  management cards, a contextual action dock, touch-safe joystick/hints, and a
  responsive settings panel.
- The gameplay HUD now follows the saved mobile reference hierarchy: compact
  hero portrait/status bars, a left stat rail, a contextual interact action,
  quick resource counts, nine context-gated action slots, and cargo/XP feedback. The
  full ledger remains an on-demand surface so normal Sanctuary traversal keeps
  the world readable. The action belt now uses the sourced warm panel/button
  textures with large icon and caption treatments instead of a flat dark slab.
- The first-save cargo target now matches the authored two-unit field bundle;
  the reference action belt also exposes one authored EXTRACT action that is
  disabled until the beacon/checkpoint contract is satisfied, with the same
  authoritative extraction command available from the keyboard X bridge.
- Whisperwood guardians are dormant until the player commits their branch;
  route entry cannot wake or damage the player before the clearing encounter is
  actually owned. Blocked investigation lines now recover into pursuit instead
  of pushing against a route collider indefinitely.
- Framing trees and rocks now receive measured foot-bearing colliders derived
  from the same published visual footprint metadata as their Sprite3D artwork;
  canopy volume remains non-blocking so the player is not trapped by invisible
  overhead walls.
- Expedition extraction now requires returning to the entry beacon; defeated
  guardian IDs persist inside active runs so reloads cannot duplicate rewards
- Whisperwood trees now take two interruptible contacts; partial contact
  progress is stored in the active expedition and restores after a reload
- Sampled CC0 Kenney foley is wired alongside procedural weather/ambience; the
  Quaternius farm-animal and Kenney UI/mobile source packages are checked in with
  licenses and archive checksums
- A small immutable content registry for expedition costs, surfaces, and
  discovery blueprints to prevent UI/session content drift
- Grid placement rejects authored Sanctuary footprints (Hearth, paths, pond,
  farm, stations, and livestock) as well as overlapping player structures
- Readable attack wind-up, player movement bounce, impact camera response,
  material-aware procedural action tones, and touch-sized action controls
- Sourced Quaternius Stylized Nature MegaKit CC0 glTF family imported into
  Sanctuary and expedition maps; exact mirror, license, archive checksum, and
  extracted files are recorded in `ASSET_LICENSES.md` and `ASSET_MANIFEST.md`
- Wind-driven tree sway, rain toggle, day/night cricket layer, surface labels
- Quaternius Cow FBX is runtime-instantiated as an animated paddock resident;
  Kenney foley maps separate surface footsteps and material/action samples
  instead of flattening every action to one click or pot sound
- Touch Interact is contextual (including Confirm placement), Pause is exposed
  in the action rail, and attack/sleep/extract controls are hidden or disabled
  outside their valid spatial contexts
- Build charter and this status brief copied into the target repo
- Current art is a deliberate hybrid: procedural low-poly buildings, player,
  guardian, UI, animation, effects, and sound with a sourced CC0 environment
  family for stronger silhouettes. It is a connected, playable vertical slice
  with persistent loops; it is not being represented as a content-complete
  commercial game while the full village, animation, and device QA passes are
  still outstanding.

## Verification

- Godot editor import from the target checkout: passed.
- Headless smoke from the target checkout: passed for 8 seconds with no
  script/runtime errors; the only output is Godot's macOS certificate warning.
- Focused session tests: passed for receipt idempotency, level/AP math,
  target-day idempotency, crop/job advancement, save/load restoration,
  expedition cargo, odd-quantity fainting, stale recovery protection, future
  save fallback, malformed save rejection, staged research, quest state,
  durable tools, survival, livestock, grid placement, dungeon coin entry, and
  guardian defeat persistence, multi-contact expedition progress, atomic tool
  transactions, mastery permissions and permission save/load, fixed-world placement, and backup preservation after a
  malformed primary, future-content blocking, impossible-day rejection, and
  unrecoverable-save diagnostics, capability-bound activity timers, and
  scene-level sleep rollback after a forced save failure.
- World integration test: passed for sourced-tree and animated-cow presence, Sunlit Beach cargo
  banking, Glass Desert camp use, return-to-home, Ember/Dungeon transitions,
  Sanctuary fishing/trading, interruptible gathering, Sanctuary placement and
  material delivery, five route gates, all destinations, out-of-range
  rejection, beacon-only extraction, expedition
  anchor persistence, Whisperwood branch commitment, and zone transitions.
- Progression runtime: passed 291 checks, including release-path rejection of
  unverified manual UI receipts, forged timer capabilities, monotonic timer
  completion, the gameplay-XP/real-life-AP boundary, harsh-season crop
  pressure, mineral-grade guidance, Deep Delver access/yield, persisted daily
  market receipts, Guild Broker bulk settlement, receipt migration, and
  malformed contract-receipt rejection, Tide Reader coastal fishing, and
  forged fishing-bonus rejection, Quality Work/Masterwork tool jobs, forged
  crafted-tool rejection, livestock trait nurture, trait persistence, physical
  language inscriptions, Track Sign/World Polyglot gates, Clean Shot combat,
  and forged progression-state rejection.
  The registry passes 1,248 checks.
- Autosave integration: passed failure surfacing and explicit retry coverage in
  the world loop; `git diff --check` remains clean.
- World integration test: passed for ten map-fauna instances, procedural
  silhouette presence, contextual observation, and failed-save rollback; the
  camera/joystick control suite also passes after the fauna pass.
- Physical-drop coverage: passed for persisted/reloaded bundles, partial
  satchel pickup, Tideglass discovery plus shell-quota settlement, and the
  field-to-extraction handoff.
- Visible game launch from the target checkout: headless smoke is clean apart
  from Godot's macOS certificate warning; deterministic OpenGL captures are
  available for the full Sanctuary and all seven construction stages.
- Sanctuary visual contract now passes 5,127 checks across all five structure
  kinds and all four rotations, including player-safe access zones, placement
  separation, authored-layout freedom, generated pivots/opaque bounds,
  construction states, staged materials, presentation replacement stability,
  asset-fit hitbox metadata, and NPC motion.
- Measured hitbox contract: `tests/test_asset_hitboxes.gd` passes 612 checks,
  including the foot-bearing colliders paired to Sanctuary framing trees and
  rocks. `tests/test_traversal_contract.gd` passes 26 checks across all five
  gates using real joystick vectors and physics movement.
- Whisperwood route-state contract: `tests/test_whisperwood_route_state.gd`
  passes 35 checks for ordered checkpoint persistence, authoritative endpoint
  transition, save/reload, malformed
  checkpoint rejection, and fail-closed in-memory state.
- Whisperwood physical journey: `tests/test_whisperwood_physical_journey.gd`
  passes 32 checks across camera-relative joystick traversal, pre-commit
  guardian dormancy, both branch endpoints, and branch collision activation.
- Full Whisperwood loop: `tests/test_whisperwood_full_loop.gd` passes 77
  scene-level checks covering physical route movement, discovery harvest/contact,
  persisted ground pickup, cache/capstone pressure, reload, authoritative
  Return Footbridge extraction, premature-extraction refusal, shortcut distance,
  live player-hit guardian defeat/reward state, damaged-guardian health and
  position surviving a scene reload before the decisive hit, and rollback when
  a nonfatal combat save is deliberately blocked.
- Extraction input contract: `tests/test_extraction_input_contract.gd` passes
  8 checks for the reference HUD action, beacon gating, and Sanctuary banking.
- Current captures: `/private/tmp/isekai-sanctuary-final-v18.png`,
  `/private/tmp/isekai-sanctuary-stages-v16/`, including seven construction
  stages, four motion-proof PNGs, and two player-authored layout proofs.
- Full gameplay regression after the return-contract change: pass — session,
  physical Whisperwood journey, full expedition loops, route state, pressure
  rewards, camera/input, progression, guardians, world loop, hitboxes,
  Workshop interior, shaders, Sanctuary visual contract, directional facility
  families, Storage Shed, and construction-stage suites.
- Later-expedition physical return acceptance: pass — `LATER_EXPEDITION_RETURN_PASS`
  with 101 checks across Sunlit Beach, Ember Ridge, Glass Desert, and Sunken
  Dungeon, including branch harvest, pickups, capstones, return causeways, and
  final extraction.

## Agent and research record

- Newton returned a progression/game-feel review; its recommendations are
  reflected in the expedition, Archive, contract, and Sanctuary additions.
- Godel returned an independent failure-oriented QA pass; its P1 findings were
  fixed in resource collision, recovery, persistence, and pause behavior.
- Bernoulli returned a second QA pass; the current cargo/save/recovery tests
  cover its main state-boundary concerns.
- A fresh architecture reviewer flagged the remaining production-scale gaps:
  a fully command-driven domain boundary, typed content registries, and a
  larger migration/failure-test matrix. Those are recorded as the next
  hardening phase rather than being misrepresented as complete.
- Sol ultra returned a candid game-feel review. Its central finding remains:
  the build is a persistence-heavy vertical slice, and the new physical-drop
  pass is functional but still needs stronger loot feedback, a fuller authored
  Forest journey, contextual mobile HUD, and deeper combat/gathering contact
  polish. Those are the next quality gates, not claims of completion.
- Carson (gpt-5.6-sol ultra) and Ampere completed the latest read-only review.
  Their findings drove the save-commit, focus-pause, action-interruption, and
  active-frame collision fixes; both agreed the full game and Sanctuary art bar
  remain open.
- Raman (gpt-5.6-sol ultra) and Aquinas completed the latest activity/save QA
  review. Their findings drove the monotonic timer capability, explicit
  corrupt/future startup states, autosave failure surfacing, semantic activity
  ledger validation, and gameplay-XP/real-life-AP separation. The chosen
  external Prodewty activity provider remains intentionally open.
- Curie (gpt-5.6-sol ultra) and Maxwell completed a failure-oriented review of
  the Whisperwood route and action boundaries. Their findings drove the shared
  endpoint sockets/checkpoints, spatial investigate behavior, strike-timed
  gathering, grounded noise radius, and guarded-telegraph regression.
- Wegener (gpt-5.6-terra) audited the current route topology and identified the
  missing continuous walk/reload acceptance coverage. Leibniz (gpt-5.6-sol
  ultra) independently rejected a premature “complete” verdict; the extraction
  action, branch-gated guardian, tutorial target, and physical Whisperwood
  contracts were implemented in response, while pressure, mid-combat reload,
  full-satchel recovery, and final Sanctuary graphics remain open.
- Web research checked official Quaternius CC0 character, nature, and monster
  packs, the author-published nature mirror, and Godot's scene-import pipeline;
  the validated nature archive is now actually imported and documented.
- Gibbs implemented the fail-closed Sanctuary visual contract; the stage worker
  added a deterministic seven-state capture harness; Ramanujan completed the
  requested gpt-5.6-sol ultra visual gate review against the saved reference.
- Nash delivered the ground/material grounding pass, Kierkegaard delivered the
  traversal/occlusion/motion harness, Popper delivered the feet-pivot/sorting
  pass, Boole delivered the two-layout proof, Plato removed stray utility
  geometry, Laplace delivered the safe-area HUD, and Banach expanded the visual
  contract to 3,005 checks. The Sanctuary art gate remains open for the final
  authored-density/building-variation/device-QA bar; other biome visuals remain
  frozen until that bar is accepted.
- Bacon removed fixed full-size ambient building/activity proxies so player
  placement owns the built layout. Hegel added five unique structure profiles,
  four directional variants each, access zones, compound collision descriptors,
  and construction-component metadata. Lorentz expanded the visual gate for
  those contracts. Maxwell's gpt-5.6-sol ultra review remains open pending
  stronger lived-in density, unique operational silhouettes, and touch-device
  capture.
- Aristotle independently confirmed that the highest-value graphics gap was the
  generic operational player-structure layer. Erdos audited the paired
  collision/feet/directional invariants; the resulting generated facility sheet
  is now wired to the authoritative footprints and verified in the display-backed
  stage capture.
- Kierkegaard's independent ultra-depth persistence review is checking the latest
  guardian-state transaction for migration, rollback, route ownership, and runtime
  restore; it is not being treated as a rubber-stamp.
- The reference-HUD verification pass now covers the gameplay/header/rail/belt
  hierarchy, sourced panel texture, icon/caption slots, and first-run objective;
  the old prototype panels yield to the new HUD in normal play while
  ledger/settings remain reachable. The deep traversal review is complete for
  the default layout; two saved player layouts and touch-device capture remain
  open.

## 2026-07-22 bounded Workshop gameplay checkpoint

- Committed baseline before this slice: `1c5838f` (`Advance Workshop interior presentation`).
- The Workshop fit-out now exposes all five authored station kinds through the
  measured interior grid. `B` toggles placement, `C` cycles unplaced station
  types, `X` rotates, and `E` confirms; the reference action belt uses the same
  context-aware command when the player is inside.
- Workbench crafting remains authoritative. Furnaces now run a persisted
  `2 Ore + 1 Stone → 2 Ingots` job, the Anvil repairs the selected damaged tool
  through the station capability boundary, and operational Material Storage
  adds six expedition satchel slots. Save-shape validation binds a job to the
  capability of its actual station rather than assuming every job is a
  Workbench job.
- The Godot headless editor/import scan passes. Runtime tests and visual
  captures remain blocked by the current macOS Godot SPIR-V→MSL crash before
  the test script starts; this checkpoint is therefore code/static-verified,
  not renderer-verified.
- The full game, final Sanctuary art gate, interior visual capture, and five
  production expedition presentations remain open.

## 2026-07-22 shared action-feedback checkpoint

- The gameplay feedback contract is now explicit in
  `scripts/feedback_event.gd`. A resolved action carries its action kind,
  world position, flattened direction, clamped strength, surface, source,
  audio mapping, camera response, haptic response, and metadata in one
  transient event. Persistent state remains in `GameSession`.
- `main.gd` now routes footsteps, gathering preparation/contact/harvest,
  expedition pickups, construction deliveries, fishing phases, discovery,
  dodge, combat impacts, and player damage through that event path. The
  `AudioDirector` consumes the same event, and the main loop records the last
  sequence for later particle/UI/analytics consumers instead of reimplementing
  action-specific routing.
- Duplicate direct audio, camera-shake, and haptic calls were removed from
  those paths so one resolved action does not produce stacked feedback. A
  focused contract test was added at `tests/test_feedback_event.gd`.
- The editor/import scan parses the new global class and touched scripts. The
  focused runtime test still hits the existing macOS Godot SPIR-V→MSL signal
  11 before the test script starts, so this checkpoint is static-verified and
  not runtime-verified. No renderer-backed visual claim is being made.

## 2026-07-22 expedition route-state checkpoint

- The later expeditions now use the same registry-owned physical route grammar
  as Whisperwood: arrival, fork, branch endpoint, capstone, and return causeway
  sockets are published in `ContentRegistry` and instantiated by the scene.
- `GameSession` now owns one exact route-state contract across all five maps.
  Branches require the fork, objectives require the physical endpoint, capstones
  require a completed objective, and cached returns require the durable return
  checkpoint. The former duplicate autoload endpoint writer was removed.
- Save schema v26 migrates active v25 route runs by deriving only the traversal
  prefix implied by their existing phase. It does not invent cargo, rewards,
  objective progress, or unlocks. The new route contract test covers every
  later expedition, mismatched endpoint rejection, reload, and v25 migration.
- The editor/import scan passes. The focused runtime test remains blocked by
  the known macOS Godot SPIR-V→MSL signal 11 before the script starts, so this
  checkpoint is static-verified and not runtime-verified.

## 2026-07-22 layered Workshop graphics checkpoint

- Workshop q0–q3 construction now uses four Codex-generated, chroma-cleaned
  atlas kits assembled as measured foundation, timber frame, walls, roof, and
  forge fitting layers. Blueprint, early frame, wall, and roof states are
  visibly additive instead of one flattened construction card.
- The old procedural rectangular base is hidden during layered construction.
  Construction remains traversable until operational state, where the imported
  source-measured compound shell becomes the sole active structure collision.
- Verification: `test_workshop_stage_visuals.gd` passes 215 checks across all
  four directions;
  `test_sanctuary_visual_contract.gd` passes 5,473 checks;
  `test_sanctuary_shader_integration.gd` passes 160 checks;
  `test_asset_hitboxes.gd` passes 612 checks; the display-backed capture at
  `/private/tmp/isekai-sanctuary-layered-v4/` passes all stage, motion,
  occlusion, and player-layout checks.
- This is a bounded graphics milestone, not a finished Sanctuary or full-game
  claim. The new q1–q3 pixel-backed capture stalled before Godot created its
  output directory, so only the q0 capture remains renderer-backed evidence;
  final Sanctuary density, all facility layered families, touch-device capture,
  and five production expedition presentations remain open.

## 2026-07-22 authored player-animation checkpoint

- Added a Codex-generated, chroma-cleaned four-by-four walk atlas at
  `assets/generated/sanctuary/player-walk-sheet.png`. Rows are the four
  camera-facing directions and columns are four authored walk frames; the
  keyed source is retained beside it for provenance.
- The runtime measures each idle and walk cell's alpha envelope, derives the
  visible height and feet gap, and binds the same measured atlas regions to the
  player Sprite3D. Movement advances the walk atlas at 8 FPS and idle returns
  to the directional idle atlas without changing the collision body's ground
  pivot.
- Verification: `test_player_animation_contract.gd` passes 29 checks. The
  world-loop contract also passes after its fork tests were corrected to walk
  the authored arrival and fork checkpoints; the new `_interact` ordering
  resolves a checkpoint on the same frame as a route-marker press.
- This closes one animation pipeline gap only. Mira's authored action frames,
  combat/harvest timelines, creature animation coverage, final Sanctuary
  presentation, and the full-game content pass remain open.

## 2026-07-22 measured Workshop fit-out checkpoint

- The transient station placement preview now receives the selected station
  kind and quarter-turn from the gameplay controller. Its frame footprint,
  validity tint, rotation metadata, and provenance are derived from the same
  `ContentRegistry` footprint consumed by `GameSession`, instead of always
  drawing a Workbench-sized frame. Preview teardown is immediate so rapid
  cycle/rotate input cannot leave stale same-named frames in the room.
- The generated furnace sprites were measured against their visible alpha
  envelopes. Both furnace variants now claim a three-by-three physical grid
  footprint, preserving their authored scale while keeping placement,
  collision, and persistence aligned. The interior contract now checks all five
  station kinds across all four rotations and verifies measured colliders fit
  within their claimed cells.
- Verification: `WORKSHOP_INTERIOR_CONTRACT_PASS checks=311`,
  `WORKSHOP_FITOUT_TESTS_PASS`, `PLAYER_ANIMATION_CONTRACT_PASS checks=29`,
  `SANCTUARY_SHADER_INTEGRATION_PASS checks=160`,
  `ASSET_HITBOX_TESTS_PASS checks=612`, and
  `REFERENCE_HUD_TESTS_PASS checks=19`. The Godot macOS certificate warning
  remains environmental; isolated runs use a writable temporary Godot home.
- This is a correctness/scale milestone inside the gold-standard Workshop
  slice, not a final Sanctuary or full-game claim. Final authored density,
  broader facility interiors, production biome art, richer action animation,
  device capture, and full audio/content completion remain open.

## 2026-07-22 physical later-route endpoint checkpoint

- Beach tidepool shells and the Dungeon vault relic now sit inside their
  registry-owned branch endpoint spaces. The player must physically cross the
  selected endpoint before harvesting or discovering the objective; the
  objective nodes no longer sit on an unrelated central approach.
- The later-route acceptance test now uses a measured inner approach tolerance
  for the two compact endpoint maps and asserts endpoint-before-harvest. It
  passes `LATER_EXPEDITION_RETURN_PASS checks=108 routes=4`.
- The route-contract fixture now models the ordered unlock chain required by
  the save validator. v25 migration now derives the traversal prefix from the
  saved route phase when an older active run has no checkpoint list, and the
  contract passes `EXPEDITION_ROUTE_CONTRACT_TESTS_PASS checks=79`.
- The broader serial regression sweep passed session, progression, guidance,
  feedback, guardian, Workshop, storage, player, world-loop, expedition,
  camera/input, hitbox, reference-HUD, Sanctuary visual, and shader contracts.
  `test_sanctuary_directional_families.gd` remains blocked by the known Godot
  macOS SPIR-V-to-MSL signal 11 before the script starts; this is an execution
  environment failure, not a green visual claim.

This is a durable route-correctness checkpoint, not a final Sanctuary or
full-game claim. Production Sanctuary density, all facility art families,
five production expedition presentations, richer action animation, device
capture, deeper audio, and the complete content pass remain open.

## Next actions (the project is not being called finished)

1. Keep the Sanctuary gate active: strengthen lived-in activity density,
   building-specific silhouettes, directional character variants, and real
   touch-device capture before calling the reference bar accepted.
2. Continue the expedition pass with renderer-backed traversal, public-action
   coverage, and failure-injection tests once the Godot runtime crash is
   removed. The generalized route state is static-verified, not runtime-green.
3. Repeat the physical walk from Hearth through every Sanctuary route in both
   saved player layouts, then capture the avatar/roof occlusion and touch-safe
   HUD on a real device while preserving the shared collision model.
4. Finish the Sanctuary production art/audio pass: deepen spatial ambience and
   footstep variation without freezing player-selected building layout.
5. Harden the command/state boundary and expand export/device QA; current
   desktop/headless evidence is strong but not a completeness claim.
6. Replace the temporary manual effort logger with the chosen Prodewty data
   bridge without changing the receipt contract.

## 2026-07-23 authored Workshop hero wiring checkpoint

- The visible quarter-turn-zero Workshop hero now resolves to the authored
  `workshop-cozy-v2.png` RGBA cutout: a readable front door, forge, chimney,
  covered work yard, anvil, logs, and lanterns in the agreed cozy illustrated
  direction. The catalog keeps the stable `workshop_q0_pos_z` identity, so
  saved rotation and interaction records do not change when art is iterated.
- Presentation still measures the cutout alpha envelope at runtime, fits it to
  the imported physical Workshop measurement, anchors it at the feet, and
  leaves occupancy, compound collision, access zones, and construction phases
  under their existing authoritative systems. No hitbox was copied from the
  bitmap.
- Verification: `WORKSHOP_STAGE_VISUAL_PASS checks=217`,
  `WORLD_LOOP_TESTS_PASS`, `SANCTUARY_VISUAL_CONTRACT_PASS checks=5473`,
  `SANCTUARY_SHADER_INTEGRATION_PASS checks=160`,
  `ASSET_HITBOX_TESTS_PASS checks=612`, and
  `SANCTUARY_DIRECTIONAL_FAMILY_PASS checks=99 facilities=3`.
- This is a player-facing visual checkpoint, not the final graphics gate:
  Workshop q1–q3 still use the existing directional family until coherent
  authored quarter-turns are available, and pixel-backed macOS capture was
  unavailable in the current environment. The final Sanctuary density,
  broader facility art/interiors, richer action animation, audio depth,
  production expedition visuals, and full content pass remain open.
