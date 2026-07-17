# Prodewty Godot Build Charter

Status: Draft 1, pending the owner's answers in **Open decisions**.

This file is the persistent instruction set for Codex while designing and
building the Godot version of Prodewty. It exists so the project keeps one
identity across long implementation sessions and does not drift into a generic
survival game, a Stardew clone, or an unrelated technical demo.

## 1. Authority and source of truth

Use sources in this order:

1. The owner's latest explicit direction.
2. This charter and its decision log.
3. `RPG_ARCHITECTURE.md` and `RPG_PROGRESSION_LATTICE.md` in the existing
   Prodewty repository.
4. The supplied RPG component and building-system overviews.
5. The existing React Native implementation as evidence of current behavior,
   not automatic design truth.

When sources conflict, follow the newer forward-looking design. Ask the owner
only when the conflict changes product identity, progression, data ownership,
platform architecture, or a major player-facing rule. Resolve minor conflicts
creatively and record the choice.

## 1.1. Runtime ownership contract

Before parallel feature work grows, establish one composition root and one
authoritative session state. Scenes render state and submit commands; they do
not directly mutate inventory, energy, progression, jobs, occupancy, or saved
world state.

- `AppRoot` owns service composition and the active `GameSessionState`.
- Validated commands or transactions are the only mutation path for persistent
  gameplay state.
- Domain events carry the result to UI, audio, particles, haptics, animation,
  and analytics-like debug views.
- Content definitions are immutable. Runtime instances carry mutable state and
  stable IDs.
- Avoid a giant node script or an untyped global event bus as the source of
  truth.

Define four clocks explicitly:

- Physics/render clock for movement, collision, animation, and combat frames.
- Game clock for day, season, sleep, crop growth, construction, and processing.
- Wall clock for imported real-life activities and any future offline sync.
- UI clock for toasts, fades, and non-game presentation.

Pause, focus loss, sleep, backgrounding, and `Engine.time_scale` must have an
explicit policy for each clock. Persistent timers use timestamps or a validated
game-clock command, never an unexamined scene `Timer` as authority.

Save files require a schema version, build/content version, typed validation,
atomic temporary-file replacement, previous-good backup, migration fixtures,
corruption recovery, and load-then-swap semantics. Advancing a day is one
idempotent transaction keyed by target day so crops, jobs, animals, resets,
seasons, and recovery loot cannot advance twice after a crash.

The activity bridge uses an idempotent receipt with source ID, timestamp,
timezone, mapping version, import cursor, and awarded components. A temporary
activity logger must already write through this same port rather than becoming
a second progression implementation.

## 2. Codex's role

Act as the game's product designer, systems designer, creative director,
technical director, Godot engineer, asset curator, build engineer, and QA
tester within the approved project scope.

- Build routine project files, scenes, scripts, resources, UI, tools, tests,
  imports, and exports without asking the owner to do them.
- Source and download approved free assets; do not ask the owner to browse,
  download, rename, sort, convert, or import ordinary assets.
- Make coherent creative choices when the design leaves room.
- Present playable work early, then improve it through visible milestones.
- Ask short, intelligent questions only when an answer materially changes the
  game or its architecture.
- Never use "I need more detail" as a substitute for proposing a good default.
- Never silently replace a canon mechanic merely because another one is easier
  to implement.

## 2.1. Multi-agent build and review protocol

The main Codex agent remains the coordinator and owner of the final result.
Sub-agents are allowed and expected when they can materially improve quality.

- Give each sub-agent one bounded responsibility and an explicit write scope.
- Do not let two workers edit the same files at the same time.
- Use research agents for focused questions about Godot, game feel, audio,
  assets, platform constraints, or production practice.
- Use worker agents for disjoint implementation tasks only after the shared
  architecture is clear.
- Always use an independent test agent after a meaningful gameplay or UI pass.
  It must run the project, inspect failure states, and report concrete defects,
  not merely say that the code looks reasonable.
- When available, dispatch a `gpt-5.6-sol` reviewer at `ultra` reasoning effort
  for a deep review of the current implementation and game feel. The reviewer
  should inspect the actual files and running behavior, identify amendments,
  and either make bounded fixes or return precise patch instructions.
- The main coordinator must inspect all returned work, reconcile conflicts,
  run the audit loop, and decide what enters the final branch. Never blindly
  merge an agent's answer.
- Sub-agents must preserve existing user changes and must not use destructive
  repository commands.

The target review loop is:

Plan -> implement -> run -> independent test -> deep review -> amend -> rerun
tests -> visible gameplay check -> record the milestone.

## 2.2. What makes the result feel like a game

Do not judge a game by whether its systems technically exist. Every important
action needs readable anticipation, satisfying contact, consequence, and
recovery. Research and implement the following as a connected feedback system:

- Input has a clear acknowledgement before the result lands.
- Actions have anticipation, active impact, and recovery rather than happening
  as an instantaneous state swap.
- Hits communicate direction, force, damage, and target material through sound,
  animation, particles, camera response, hit stop where appropriate, and world
  state changes.
- The world reacts persistently when the action should matter: chopped trees
  lose a branch or fall, mined rocks crack and shed fragments, soil changes,
  crops grow through distinct stages, fire consumes fuel, and structures show
  construction progress.
- Surface and material response is specific. Wood, stone, metal, soil, sand,
  water, foliage, and cloth should not share one generic effect.
- Impacts leave lightweight, readable traces such as decals, chips, dust,
  scorch marks, footprints, wetness, displaced foliage, or dropped fragments.
  These traces must be bounded and save only when they are meaningful world
  state, not every cosmetic particle.
- Enemies telegraph intent, react to damage, lose interest naturally, and have
  recovery windows. The player should understand why they were hit or missed.
- Rewards arrive with timing and hierarchy: pickup pull, count change, small
  fly-up, mastery progress, discovery reveal, and larger milestone feedback.
- Menus, sounds, camera motion, particles, and animation reinforce the same
  action instead of competing for attention.
- Calm moments have texture too: wind moves trees, water ripples, animals idle,
  NPCs have small routines, light changes, and the Sanctuary feels inhabited
  even when the player is doing nothing.

Use restrained effects. Do not add random screen shake, particle spam, or
constant UI motion. Feedback must explain the action and preserve the cozy
readability of the world.

For every new player action, document the five answers before calling it
polished: what the player intends, what they see before contact, what contacts
the world, what persists afterward, and what sound identifies the result.

Implementation requirement for action feedback:

- Route meaningful actions through a shared `FeedbackEvent` containing action
  kind, world position, direction or normal, strength, surface/material, and
  source. Animation, SFX, particles, camera response, haptics, UI feedback, and
  persistent-state listeners may react independently, but they must agree on
  the same event.
- Define surface profiles for grass, dirt, sand, stone, wood, metal, water, and
  foliage. Each profile can supply footsteps, impacts, debris, decals, and
  attenuation without duplicating interaction logic.
- Persist meaningful reactions by stable object or cell ID: broken props,
  opened paths, altered soil, scorch marks, and discovered changes. Never save
  transient particles or every cosmetic animation frame.
- Enemy attacks must have a readable wind-up, active frame, and recovery. Tie
  hitbox activation and feedback to animation markers or one authoritative
  action state, not unrelated timers.
- Map keyboard, gamepad, and touch to the same actions. Keep mobile primary
  controls touch-sized, visibly pressed, and limited to the current context.
- Provide independent sliders or toggles for music, ambience, effects, screen
  shake, and haptics from the first usable build.

## 3. Product north star

Prodewty is a productivity-driven, cozy survival-adventure RPG. Real-life
activity creates character growth; the game world gives that growth emotional
and spatial meaning through exploration, discovery, gathering, building,
farming, crafting, villagers, combat, research, and Sanctuary expansion.

The intended feeling is:

- Calm enough to return to every day.
- Adventurous enough that leaving home feels meaningful.
- Forgiving, readable, and satisfying rather than punishing or grind-heavy.
- Visibly transformed by the player's real-life effort.
- Discovery-first: biomes, creatures, materials, blueprints, runes, Archive
  knowledge, and Sanctuary growth outrank deep farm-production complexity.

`Last Day on Earth` is a reference for camera, spatial readability, direct
movement, interaction range, and mobile action controls. It is not the target
tone, monetization model, color palette, harshness, or art identity.

## 4. Core law and progression

Every important gate must ultimately be crossable through real-life
productivity. In-game play converts that progress into mastery, resources,
knowledge, and visible world growth; it must not let repetitive grinding make
real-life activity irrelevant.

The primary chain is:

Real-life activity -> XP, health, stats, coins, and Ability Points -> stronger
in-world actions -> exploration and Sanctuary work -> resources, discoveries,
mastery, and blueprints -> buildings, stations, research, and permissions ->
better tools and access -> a richer Sanctuary and harder discoveries.

Rules to preserve:

- Seven stats are continuous power: Strength, Agility, Focus, Wisdom,
  Spirituality, Perception, and Resilience.
- Twelve masteries are discrete permissions: Farming, Mining, Attacking,
  Foraging, Fishing, Crafting, Livestock, Language, Trading, Hunting,
  Surviving, and Research.
- Stats always combine Ability Point allocation and activity-earned gains.
- Mastery uses Bronze, Silver, Gold, and Platinum tiers.
- Discovery means the player has encountered something. Understanding means
  its identity and use are known through Research and the Library.
- Energy is one shared stamina resource. Returning to Sanctuary is free so the
  player cannot become stranded.
- Sleeping advances the day, restores energy, advances crops and animals,
  completes daily resets, and drives seasons.
- Buildings are shells. Their matching placeable stations create functions.
- Blueprints are found through exploration and decoded at the Library before
  their station or recipe becomes available.
- Combat is real-time with direct movement, chase or turret AI, contextual
  attacks, and stat-based outcomes.
- Fainting never destroys equipped tools. Half of unbanked expedition loot is
  left in a recovery backpack until that zone's next daily reset.

## 5. World structure

- **Sanctuary:** safe home and the visual record of progress. Farming,
  building, stations, villagers, ponds, livestock, crafting, the Village
  Hearth, Market, and Library live here.
- **Forest:** first expedition; Whisperwood, forage, rabbits, beetles, and a
  chasing Forest Slime guardian.
- **Beach:** driftwood, crabs, coastal discoveries, and eventually connected
  beach fishing.
- **Mountain:** stone, marmots, turret-like Predator Plants, and procedural
  Mines.
- **Desert:** harsher high-cost expedition with Thornroot, lizards, and
  Predator Plants.
- **Dungeon:** a separate fixed challenge region with coin-gated entry and no
  expedition travel cost.

The Sanctuary must feel worth protecting and improving. Expeditions should be
short, legible adventures that return useful stories and materials home.

## 6. Visual and interaction direction

Use real-time low-poly 3D presented from an angled orthographic or very
low-perspective camera, producing a polished 2.5D impression. Do not use flat
side-view pixel art, a Growtopia-like presentation, or a collection of
unmatched asset packs.

Provisional visual rules, pending the owner's answer:

- Cozy stylized low-poly forms with clean silhouettes and restrained detail.
- Warm, cultivated Sanctuary contrasted with cooler or stranger expedition
  biomes.
- Soft directional light, grounded shadows, modest particles, and selective
  outlines or rim light only when they improve readability.
- A fixed or tightly constrained camera for consistent composition and mobile
  performance.
- Landscape-first play with safe-area-aware mobile controls; keyboard and
  mouse equivalents on desktop.
- Left virtual joystick/WASD movement, contextual Interact, Attack, and one
  active-tool action. UI should stay quiet while moving.
- Grid-aware placement with a world-space ghost preview and valid/invalid
  feedback. The grid should guide construction without making the natural
  world look tiled.
- No close facial cinematics until character art supports them.

Create a project-specific palette, material library, lighting rig, icon style,
and scale guide before broad asset integration. Every imported asset must be
adapted to these rules.

## 7. Technical direction

Known local toolchain:

- Godot `4.7.stable`, standard GDScript build.
- Xcode `26.5` on macOS.
- Existing Prodewty client: React Native/Expo with SQLite.
- Godot export templates are not currently installed; Codex will acquire them
  before the first platform export.
- Blender is not currently installed; Codex will add it only when mesh cleanup,
  conversion, modular assembly, or original low-poly prop work justifies it.

Default Godot choices:

- GDScript unless a proven native requirement justifies another language.
- Mobile-compatible renderer and conservative material/shader complexity.
- Data-driven content through custom Resources or validated JSON, not giant
  scene scripts full of item constants.
- Separate simulation/state from presentation so mechanics can be unit-tested.
- Autoload services only for true cross-scene concerns such as game state,
  saves, content registry, audio, and the eventual activity bridge.
- Reusable scenes for player, interactables, resource nodes, enemies,
  buildings, stations, crops, items, pickups, and HUD controls.
- Stable save identifiers independent of scene paths and display names.
- Versioned save migrations from the first persisted build.
- Git commits at meaningful, verified milestones once the owner authorizes the
  working repository.

Do not lock the permanent save/database bridge until the owner chooses how the
Godot game relates to the existing Expo app.

Godot's supported iOS path exports a standalone Xcode application project.
Embedding a Godot-rendered game view directly inside the existing Expo/React
Native application is a separate custom native-integration effort and must be
treated as a researched architecture phase, not assumed to be an export
checkbox. Keep the first game slice independently runnable so this decision
does not block gameplay or art production.

## 8. First professional vertical slice

The first slice is an opinionated, playable proof of the final game, not a
throwaway prototype. It should include:

1. A small authored Sanctuary with a Hearth landmark, pond, garden area,
   building area, paths, foliage, and visibly expandable edges.
2. A readable player character, responsive movement, camera, collision,
   contextual interaction, tool use, and a light attack.
3. Landscape mobile controls plus desktop equivalents.
4. A Forest expedition reached from the Explorer Tent, with travel cost and a
   free return home.
5. Wood, forage, stone, and at least one rare discovery with pickup feedback.
6. Beetles or rabbits as a non-hostile discovery and one Forest Slime guardian
   with simple, readable chase combat.
7. Energy, HP, day/sleep, inventory, equipment, and a minimal discovery log.
8. One farming plot loop: till, plant, water, sleep, harvest.
9. One timed building shell and one matching station that demonstrates the
   shell -> station -> function rule.
10. One timed craft or processing job with ingredient consumption and claiming.
11. XP, one visible stat effect, relevant mastery gains, and a temporary
    real-life-activity input hook until the final app bridge is selected.
12. Save/load, pause/settings, audio controls, basic haptics hooks, and clean
    empty/error/disabled states.
13. Cohesive environment, character, props, icons, sound effects, ambience,
    particles, and UI rather than silent placeholders.

The slice is complete only when it creates a satisfying loop:

Log effort -> become more capable -> leave Sanctuary -> discover and gather ->
survive a gentle threat -> return -> build/grow/craft -> sleep -> see progress.

## 9. Asset acquisition and art production

The owner does not procure assets. Codex owns the full asset workflow.

1. Search reputable original sources and official creator pages first.
2. Prefer one broad, coherent CC0 low-poly family as the world-art foundation.
   Quaternius is the first candidate; Kenney is the first candidate for UI,
   interaction icons, and sound effects.
3. Use a second source only for a documented gap and only if its style can be
   normalized convincingly.
4. Before importing, record creator, source URL, download date, pack/version,
   license text, attribution requirement, archive checksum, and intended use in
   `ASSET_LICENSES.md` and a machine-readable asset manifest.
5. Keep original downloads separate from derived game-ready files.
6. Normalize units, forward axes, pivots, origins, collision, materials,
   texture filtering, animation names, polygon budgets, and LOD policy.
7. Rebuild materials into the Prodewty palette instead of accepting every
   source pack's colors unchanged.
8. Assemble missing structures from modular licensed parts. Create simple
   missing props procedurally in Godot or Blender when that produces a cleaner
   result than mixing art styles.
9. Use image generation selectively for original 2D art such as portraits,
   loading art, textures, or item illustrations when consistency can be
   maintained. Do not use it as a substitute for gameplay-ready rigged 3D
   characters.
10. Reject ripped franchise assets, unclear uploads, editorial-use-only art,
    noncommercial licenses, share-alike obligations that conflict with the
    distribution plan, and assets whose provenance cannot be documented.

Nothing enters a production scene until its provenance and license are known.
Temporary primitives are allowed during mechanics work but must be tagged and
tracked; the owner must never be asked to replace them manually.

## 9.5. Audio, atmosphere, and living-world direction

Audio is part of the simulation and level design, not a late decoration pass.
The player should be able to understand where they are and what is happening
through sound before opening a menu.

Build one data-driven `AudioDirector` around a single environmental state:

- zone and biome
- indoor/outdoor status
- floor or surface type
- time of day and current season
- weather state
- player movement speed and action
- nearby active machines, NPCs, animals, and threats

Use layered buses with independent volume controls for master, music,
ambience, footsteps, world effects, UI, and voice. Crossfade state changes over
short, intentional durations. Do not restart every loop when the player moves
one cell; use hysteresis and proximity thresholds so the soundscape feels
continuous.

Environmental rules:

- Footsteps choose grass, dirt, sand, stone, wood, and other surface families
  from the authoritative world surface beneath the player.
- Buildings can override the outdoor surface. A sand-floored interior sounds
  like sand, not grass, even if the building sits inside a grassy Sanctuary.
- Sanctuary has soft restorative ambience: grass movement, light birds or
  insects, distant water, and restrained activity sounds.
- Expeditions have distinct wind, foliage, wildlife, and danger signatures.
- Wind intensity changes with biome and weather. Trees and foliage should sway
  with the same wind state through a lightweight animation or shader when
  possible, so sound and motion agree.
- Rain adds a rain layer, surface-specific impacts, puddle or wet-ground cues,
  and corresponding visual particles. Thunder is rare and should not become a
  constant alarm.
- Night shifts the ambience toward crickets, frogs, nocturnal wildlife, and
  softer activity. Daytime can use birds and insects. Seasonal variants are
  optional polish, not a reason to block the core loop.
- Active furnace or other station sounds are spatial and conditional. If the
  player is close enough to an actively smelting Furnace, hear fire, heat, and
  occasional metal-work detail. The sound fades with distance and stops when
  the job is complete or the station is inactive.
- Chopping, mining, tilling, watering, harvesting, crafting completion, pickup,
  combat, damage, fainting, sleeping, and blueprint discovery each get clear
  feedback with variation so repeated actions do not become abrasive.
- Interior spaces use a small amount of filtering, reduced wind, and short
  reverb or room tone. Avoid heavy effects on mobile hardware.

Audio implementation rules:

1. Keep environmental conditions in world state, not hidden inside individual
   audio players.
2. Use reusable loop layers with randomized one-shots and cooldowns instead of
   dozens of permanently playing nodes.
3. Use distance attenuation for machines, animals, guardians, water, and
   weather sources. Do not use distance attenuation for HUD sounds.
4. Keep all sound assets in the license manifest. Prefer coherent CC0 sources;
   allow attribution-required sources only when their terms are recorded.
5. Use placeholder synthesized tones only during mechanics work. Replace them
   before calling a visual slice polished.
6. Expose accessibility controls for master, music, ambience, effects, and
   reduced weather intensity. Never make audio necessary to complete an action.
7. Test headphones and speakers at low volume. The game should feel alive,
   never noisy or exhausting.

The first slice should already include surface-aware footsteps, Sanctuary
ambience, Forest wind, a day/night cue, one weather-ready state, tree sway,
and one distance-based active-station sound. Full seasonal audio variation,
dynamic music, and rich wildlife can expand after the foundation is stable.

## 10. Visible Godot workflow

The editor may remain open while Codex works.

1. Codex creates and changes the project through `project.godot`, `.tscn`,
   `.gd`, Resources, imports, editor scripts, and command-line tools.
2. Launch the editor with `godot --editor --path <project>` so the owner can
   watch files and assets appear and inspect scenes.
3. Let Godot import assets, then run the current milestone in a visible game
   window. Use headless runs for fast parse/tests and visible runs for feel and
   rendering checks.
4. Capture screenshots and logs after material milestones and inspect them for
   framing, missing materials, collisions, UI overlap, and visual inconsistency.
5. Avoid simultaneous edits to the same open scene. If Godot reports an
   external change, reload the file from disk rather than saving a stale editor
   copy over Codex's work.
6. Keep the running preview separate from the editor so the owner can watch the
   actual game, not only node trees and inspector fields.

Codex can launch the editor and game, write and validate files, use Godot's CLI,
read logs, and inspect captured screenshots. Codex does not have unrestricted
human-like control of every Godot inspector gesture; file-based authoring and
small editor tools are the reliable control surface.

## 11. Question protocol

Ask the owner when a choice changes any of these:

- Whether Godot is standalone, the whole app, or embedded in the Expo app.
- Ownership or migration of user/activity/save data.
- Platform priority, orientation, or control model.
- Product identity, tone, camera, or major visual language.
- A central system interaction or progression rule not answered by canon.
- Online services, accounts, social features, monetization, or multiplayer.
- Asset-license obligations or use of generated art.
- A destructive migration, paid purchase, credential, signing action, or
  external account operation.

Do not ask about minor prop placement, colors within the agreed palette,
variable names, folder structure, ordinary implementation choices, small
animation timing, exact starter resource counts, or other reversible details.

Question format:

`Decision: A - recommended choice and one-line impact; B - alternative and one-line impact.`

- Keep each option short.
- Give a recommendation, not a neutral dump of possibilities.
- Ask at most five closely related decisions in one batch.
- For a blocking architectural choice, wait for the answer.
- For a reversible polish choice, state the default, continue, and log it.
- When a new interaction is ambiguous, describe the proposed rule in one
  sentence and ask yes/no.

## 12. Verification and definition of done

For every milestone:

- Run Godot import and GDScript parse checks with no new errors.
- Run unit tests for stateful rules and integration tests for full loops.
- Exercise movement, collision, interaction, combat, placement, inventory,
  timers, day advance, save/load, and scene transitions as applicable.
- Test at desktop and representative iPhone landscape resolutions, including
  notches/safe areas and touch-sized controls.
- Inspect screenshots for blank rendering, camera framing, material failures,
  illegible text, UI overlap, scale mismatches, and mixed art direction.
- Check performance with representative object counts, particles, shadows, and
  enemies; do not approve an empty-scene frame rate as proof.
- Confirm every shipped asset is present in the license manifest and no tracked
  placeholder leaks into the polished path.
- Preserve existing user work and never overwrite unrelated repository changes.

A milestone is not complete because it launches. It is complete when its loop
works, persists correctly, reads clearly, feels intentional, and has been
visually inspected.

## 13. Boundaries and honest limitations

Codex can implement and iterate on the full game, but cannot independently:

- Accept operating-system security dialogs, license agreements, or account
  terms on the owner's behalf.
- Buy paid assets, bypass paywalls, or use assets without clear permission.
- Supply Apple credentials, certificates, legal identity, tax information, or
  final store-account approvals.
- Guarantee App Store acceptance or make signing decisions belonging to the
  account owner.
- Produce bespoke AAA quantities of rigged characters, cinematic animation,
  orchestral music, and voice acting from a text prompt alone.
- Judge play feel as the owner would without the owner's occasional direct
  reaction to a playable build.
- Turn the entire content-complete long-term RPG into a polished commercial
  game in one generation. One comprehensive prompt can start and drive the
  build; professional quality comes from repeated implementation, testing,
  visual review, and refinement against this same brief.

The owner's expected work should be limited to answering material decisions,
approving required downloads or GUI launches, supplying private credentials
only when eventually necessary, and giving short reactions to playable builds.

## 14. Open decisions

These are the only decisions currently needed before the first Godot project is
architected. Recommendations are provisional defaults.

1. **Product architecture:** build an independently runnable Godot game first
   and settle integration after the slice proves itself (recommended), or begin
   with the higher-risk custom Expo/Godot native integration?
2. **Long-term product:** should the final result remain one Prodewty app with a
   Godot game view, or may the RPG be a separate companion app sharing user
   progress?
3. **Activity source for slice one:** use a small in-game test logger that
   mirrors real activity rewards (recommended), or connect to the current
   Prodewty SQLite data immediately?
4. **First-device target:** Mac preview plus iPhone-ready landscape controls
   (recommended), or iPhone device builds from the first milestone?
5. **Orientation:** landscape-only for the polished first slice (recommended),
   or support both landscape and portrait immediately?
6. **Asset licenses:** CC0-only for maximum simplicity (recommended), or allow
   CC-BY assets when they materially improve quality and attribution is logged?
7. **Visual tone:** warm cozy low-poly sanctuary with more mysterious biomes
   (recommended), or a darker survival tone closer to `Last Day on Earth`?
8. **Save scope:** local versioned save for the slice (recommended), or account
   and cloud sync from the start?

## 15. Decision log

Add dated decisions here. Once recorded, do not repeatedly ask the same
question unless the owner reopens it.

- 2026-07-17: Use Godot and a true low-poly 3D world presented as polished
  2.5D; do not pursue a flat Growtopia-like 2D presentation.
- 2026-07-17: Codex owns asset sourcing, downloading, organization, conversion,
  integration, provenance, and license documentation.
- 2026-07-17: Creativity is part of Codex's role; incomplete cosmetic detail is
  permission to design, not a reason to stop.
- 2026-07-17: The owner wants short yes/no or small-choice questions whenever a
  genuinely material interaction or product rule remains unknown.
- 2026-07-17: Keep the Godot editor and visible game previews open when useful
  so the owner can watch and inspect progress.

## 16. Research references and implementation consequences

This is a compact research record for future agents and reviewers. It is not a
substitute for playtesting.

- Godot audio buses and spatial audio: use buses for mix ownership and
  `AudioStreamPlayer3D` plus a player-ground listener for world sources.
  Consequence: the elevated camera must not accidentally become the listener.
  https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html
  https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer3d.html
- Godot animation and navigation: drive non-trivial action timing from
  animation/state contracts, and treat navigation obstacles as a separate
  design decision from physics collision.
  https://docs.godotengine.org/en/4.7/classes/class_animationplayer.html
  https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_introduction_3d.html
- Apple game controls: support the platform's default interactions, keep
  frequent touch controls at least 44x44 points, provide visible/tactile press
  states, honor safe areas, and hide controls that are not contextually useful.
  https://developer.apple.com/design/human-interface-guidelines/game-controls
- Lin, Duan, Wen, and Cai's impact-feedback study identifies hit stop, sound
  coherence, and camera control as especially influential to perceived impact.
  Consequence: impacts are not complete when only a particle effect appears.
  https://arxiv.org/abs/2208.06155
- Pichlmair and Johansen's game-feel survey frames moment-to-moment feel as
  physicality, amplification, and support. Consequence: tune movement/contact,
  amplify important events, and remove friction between intent and result.
  https://arxiv.org/abs/2011.09201
- GDC's Boss Up material emphasizes telegraphing and preemptive animation.
  Consequence: enemies announce intent, expose active frames, and recover in a
  readable way instead of applying hidden timer damage.
  https://media.gdcvault.com/gdc2018/presentations/Keren_Itay_BossUp.pdf
