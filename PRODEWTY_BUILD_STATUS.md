# Prodewty Build Status

Updated: 2026-07-18, Asia/Singapore

## Current target

- Local checkout: `/Users/kevinyongcj/Programming/isekai-leveling`
- Remote: `https://github.com/Dewflash/isekai-leveling.git`
- Remote state: empty repository, no commits yet
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
- Grid-backed Sanctuary placement: a Rain Cistern can be previewed on a valid
  footprint, paid for once, persisted as scaffolding, completed over sleep, and
  then produces extra water each day
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
  transactions, fixed-world placement, and backup preservation after a
  malformed primary.
- World integration test: passed for sourced-tree presence, Sunlit Beach cargo
  banking, Glass Desert camp use, return-to-home, Ember/Dungeon transitions,
  Sanctuary fishing/trading, interruptible gathering, Sanctuary placement,
  beacon-only extraction, expedition anchor persistence, and zone transitions.
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

1. Make the Whisperwood outing a gold path: a forked route, authored extraction
   pressure, and a more readable guardian encounter. Multi-contact gathering is
   now in the route; the path and encounter still need authored presentation.
2. Replace the remaining desktop-style HUD stack with safe-area contextual
   actions and explicit recipe/food/expedition sheets.
3. Harden the command/state boundary and migrate durable world mutations out of
   presentation code.
4. Replace the temporary manual effort logger with the chosen Prodewty data
   bridge without changing the receipt contract, then do device-specific export
   and hands-on gameplay QA.
