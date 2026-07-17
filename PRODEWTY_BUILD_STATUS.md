# Prodewty Build Status

Updated: 2026-07-18, Asia/Singapore

## Current target

- Local checkout: `/Users/kevinyongcj/Programming/isekai-leveling`
- Remote: `https://github.com/Dewflash/isekai-leveling.git`
- Remote state: pushed through `da4037d` on `codex/visual-workshop-storage-operating`
- Staging project: `/Users/kevinyongcj/Documents/Codex/2026-07-17/wha/work/isekai-leveling`
- Godot: `4.7.stable.official.5b4e0cb0f`
- Xcode: `26.5`

## What exists (current checkpoint)

- Godot project bootstrap and main scene
- Procedural low-poly Sanctuary plus five wired expedition maps: Whisperwood,
  Sunlit Beach, Ember Ridge, Glass Desert, and Sunken Dungeon
- Orthographic 2.5D camera and player movement
- Keyboard, mouse, and virtual joystick movement input
- Resource gathering, banked inventory, at-risk expedition cargo, energy, XP,
  sleep/day advance, safe camps, heat hazard, and biome-specific recovery packs
- Four guardian variants with readable wind-up combat and reward-specific loot
- Furnace state and proximity-aware audio context
- Procedural original audio layers for ambience, rain, fire, footsteps,
  gathering, and impact feedback
- Authoritative `GameSession` with versioned local JSON saves, backup recovery,
  idempotent real-life effort receipts, stats, levels, mastery values, and
  target-day transactions
- Sanctuary garden loop: till, plant, water, sleep, harvest, and visual crop
  stages
- Persisted Workshop construction/station loop: pay the shell, sleep to finish
  the build, start planks, advance the day, and claim output
- Expedition runs persist their biome, run ID, cargo, depleted node IDs, and
  anchor; reload resumes the run instead of silently returning home
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
  bramble edges, and a measured traversal contract instead of only the generic
  arena grammar.
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
- Saved sanctuary reference image and acceptance notes now distinguish visual
  direction from player-owned building layout
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
  scene-level sleep rollback after a forced save failure.
- World integration test: passed for sourced-tree and animated-cow presence, Sunlit Beach cargo
  banking, Glass Desert camp use, return-to-home, Ember/Dungeon transitions,
  Sanctuary fishing/trading, interruptible gathering, Sanctuary placement and
  material delivery, five route gates, all destinations, out-of-range
  rejection, beacon-only extraction, expedition
  anchor persistence, Whisperwood branch commitment, and zone transitions.
- Visible game launch from the target checkout: headless smoke is clean apart
  from Godot's macOS certificate warning; desktop screenshot capture is not
  available in the current Codex session.
- Desktop screenshot capture is unavailable in the current Codex session, so
  visual inspection is through the open Godot/game windows and runtime checks.

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
- Sol ultra returned a candid game-feel review. Its central finding is retained:
  the build is a persistence-heavy vertical slice, but moment-to-moment play
  still needs a stronger authored Forest journey, contextual mobile HUD,
  physical pickups, and a deeper combat/gathering contact loop. Those are the
  next quality gates, not claims of completion.
- Web research checked official Quaternius CC0 character, nature, and monster
  packs, the author-published nature mirror, and Godot's scene-import pipeline;
  the validated nature archive is now actually imported and documented.

## Next actions (the project is not being called finished)

1. Continue the authored Sanctuary pass: retire the remaining fixed-shell
   authority, add sourced modular props/foliage around the player-owned
   district, and validate a physical walk from Hearth through every route.
2. Replace the remaining desktop-style HUD stack with safe-area contextual
   actions and explicit recipe/food/expedition sheets.
3. Finish the production art pass: replace generic procedural walls/gates with
   curated CC0 modular building pieces, animate the player and Mira, and add
   spatial ambient audio/footstep variation.
4. Harden the command/state boundary and expand export/device QA; current
   desktop/headless evidence is strong but not a completeness claim.
5. Replace the temporary manual effort logger with the chosen Prodewty data
   bridge without changing the receipt contract.
