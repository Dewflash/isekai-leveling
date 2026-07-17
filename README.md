# Prodewty: Isekai Leveling

An original low-poly productivity-driven survival-adventure game slice built in
Godot 4.7. The game loop is intentionally concrete:

`real-life effort → capability → expedition → risky cargo → Sanctuary → building, farming, research → deeper expedition`

## Run

Open the project in Godot 4.7 and run `main.tscn`, or from this directory:

```sh
godot --path .
```

## Controls

- `WASD` / arrow keys: move
- `E`: interact with the nearest highlighted object
- `Space`: attack
- `R`: sleep and advance the day from the Sanctuary Hearth
- `F`: work the Garden Plot
- `C`: use the Workshop
- `P`: record a 25-minute real-life effort receipt
- `L`: spend an Ability Point on Strength
- `T`: toggle rain
- `Esc`: pause

Walk to the pond fishing spot or the Bazaar trade stall and press `E`; both
are contextual interactions rather than extra UI clutter.

## What to play

1. Speak to Mira and read the Notice Board.
2. Walk to one of the five physical route gates around the Sanctuary and press
   `E` (or the contextual touch action) to enter Whisperwood, Sunlit Beach,
   Ember Ridge, Glass Desert, or the Sunken Dungeon. Destination choice is
   made at the world gate rather than through a global teleport button.
3. Gather, fight, and watch the `CARGO` line: expedition loot is not banked
   until you return. Whisperwood trees take two grounded contacts, so moving
   away between chops leaves the partial route state intact rather than paying
   out cargo early.
4. Use the one-use camp when energy is low. In the Glass Desert, heat also
   drains energy over time.
5. Return home before fainting. If you faint, the kept half is banked and the
   lost half becomes a recovery pack in the biome where you fell.
6. Bring discoveries to the Archive, start research, sleep once, then return
   to claim the typed blueprint.
7. Build the Workshop, grow wheat, turn wheat and water into bread, fish with
   fiber bait, trade at the Bazaar, and claim contracts.

The current movement/attack animation, sound layers, particles, buildings,
characters, and most gameplay props are authored procedurally, with sourced CC0
trees, rocks, and mushrooms integrated into the maps; see
[`ASSET_LICENSES.md`](ASSET_LICENSES.md) and [`ASSET_MANIFEST.md`](ASSET_MANIFEST.md)
for provenance.

## Verification

```sh
HOME=/private/tmp/godot-home godot --headless --audio-driver Dummy \
  --rendering-method gl_compatibility --rendering-driver opengl3 \
  --path . --script res://tests/test_game_session.gd

HOME=/private/tmp/godot-home godot --headless --audio-driver Dummy \
  --rendering-method gl_compatibility --rendering-driver opengl3 \
  --path . --script res://tests/test_world_loop.gd
```

Both scripts are deterministic gameplay checks; the macOS CA certificate
warning printed by Godot in headless mode is environmental and does not fail
the tests.
