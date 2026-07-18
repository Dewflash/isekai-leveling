# Prodewty Codex Snapshot

Updated: 2026-07-18, Asia/Singapore

## Runtime

- Godot editor: open on `/Users/kevinyongcj/Programming/isekai-leveling`
- Play session: running from that same checkout
- Godot editor import: passed
- Headless smoke test: passed; no script errors, runtime errors, or ObjectDB/audio leaks

## Git

- Remote: `https://github.com/Dewflash/isekai-leveling.git`
- Remote code checkpoint is `b806060` on `codex/visual-workshop-storage-operating`.
- Current local additions: `.gitignore`, `project.godot`, `main.tscn`,
  `default_bus_layout.tres`, `scripts/`, `PRODEWTY_BUILD_STATUS.md`,
  `PRODEWTY_GODOT_BUILD_CHARTER.md`, and the sourced CC0 asset subset plus
  manifest.
- The latest placement checkpoint is committed and pushed; the working tree is
  clean after verification.

## Agents and research

- Newton: progression and game-feel review returned.
- Godel: independent QA returned; its concrete persistence/collision findings
  were fixed.
- Bernoulli: second failure-oriented QA returned and its main findings are now
  represented by session/world-loop tests.
- A fresh architecture review returned a candid production gap list: typed
  registries, command-driven state mutation, and a wider migration matrix are
  still future hardening work.
- Sol ultra returned a candid game-feel review. It confirms the persistence and
  expedition foundations, while requiring a stronger authored Whisperwood gold
  path, extraction pressure, multi-contact gathering, combat recovery states,
  and a contextual mobile HUD before this can be called a finished game.
- Official Quaternius CC0 and Godot scene-import documentation were researched;
  the validated Quaternius nature archive is now checked in as a glTF subset,
  with its license and checksum documented in `ASSET_LICENSES.md` and
  `ASSET_MANIFEST.md`.

## Current milestone

- Built an authored expedition vertical slice: choose among five destinations,
  pay travel energy, gather or fight for at-risk cargo, use a one-use camp,
  survive biome hazards, return to bank loot, research discoveries overnight,
  claim contracts, then build/farm/craft/sleep in Sanctuary.
- Added a versioned `GameSession` with local save, previous-good backup,
  corrupt-save fallback, idempotent receipts, and target-day transactions.
- Added garden and Workshop content with persistent visual state.
- Added expedition-vs-banked loot accounting with active-run save/resume,
  stable depleted nodes, biome-specific recovery packs, dead-guardian cleanup,
  camps, landmarks, routed NPC guide, fishing/trading, recurring contracts, and
  staged research.
- Added durable tool wear, interruptible gathering contact, food/hydration,
  explicit food/recipe selection, Clover livestock production, grid-backed Rain
  Cistern placement/construction, beacon-only extraction, and persistent active-
  run guardian defeat IDs.
- Added persistent expedition field bundles: harvest effort depletes the node,
  the bundle is saved at the source, pickup settles cargo/discovery/route
  progress, and a full satchel leaves a clearly communicated remainder.
- Whisperwood trees now require two interruptible contacts; partial contact
  progress is saved inside the active run and restores after reload.
- Downloaded and wired CC0 Kenney RPG/interface samples; checked in licensed
  Quaternius farm-animal and Kenney UI/mobile source packages with checksums.
- Added original procedural art/audio, movement/attack tweens, material-specific
  sounds, dynamic water/beacons/light, and the asset provenance ledger.

## Next build pass

The next pass is the gameplay-quality gate: make Whisperwood a real authored
journey, deepen contact/recovery for gathering and combat, rebuild the HUD as a
safe-area contextual action surface, and then continue command-based hardening
and the external activity bridge. The current project is an authored,
interconnected vertical slice with a real source/asset ledger; it is not a claim
of a content-complete commercial game. Desktop capture is unavailable in the
current Codex session, so the latest visual evidence is the rendered audit frame
plus headless/runtime checks.
