# Isekai Leveling shader style guide

Status: isolated shader contribution, not gameplay-integrated.

These shaders support the saved Sanctuary north star: warm, substantial,
anime-adjacent 2.5D forms with selective motion and depth. They deliberately do
not apply a global pastel filter. Saturation stays local to each material,
shadows retain cool color, warm highlights remain controlled, and glow is
reserved for actionable rewards.

All resources target Godot 4.7's `gl_compatibility` renderer. The shader set
uses no compute, screen texture, depth texture, normal/roughness buffer,
refraction, custom post-process, or custom `light()` function.

## Asset set

| Asset | Intended use | Never use for |
| --- | --- | --- |
| `cozy_toon_surface.gdshader` | Opaque procedural or sourced 3D wood, stone, canvas, metal, construction pieces | Illustrated Sprite3D cutouts, transparent foliage, UI |
| `ground_depth_edge.gdshader` | Opaque meadow/path CylinderMesh patches; darkens UV edges and vertical sides | Contact shadows, build ghosts, transparent decals |
| `cozy_water_ripple.gdshader` | Small subdivided pond/pool surface meshes | Whole pond illustration atlases, ocean-scale water, collision geometry |
| `cozy_foliage_sway.gdshader` | Leaf-only low-poly surfaces or explicitly bound cutout cards | Trunks, buildings, collider meshes, an already CPU-swaying whole tree |
| `reward_glow_shell.gdshader` | Duplicate visual-only shell around a pickup marker, cache marker, or capstone sigil | Base reward mesh, hit box, collision shape, large environment meshes |

The `.tres` files are tuned starting presets. Duplicate a preset before changing
per-instance parameters; mutating one shared ShaderMaterial would recolor every
mesh using it.

`shader_preview.tscn` references every shader family. It is a compile/inspection
lab only and is not connected to `main.tscn`.

## Parameter contracts

### Opaque toon surface

- `base_color`: material family color. Start from the existing project palette.
- `albedo_texture`, `use_albedo_texture`: transfer a sourced surface's existing
  albedo texture before replacing its material. Never discard imported texture
  identity accidentally.
- `use_vertex_color`: enable only when the mesh actually authors vertex color.
- `key_light_direction`: world-space art-direction vector. Keep this shared with
  the authored sun direction; it shapes albedo while Godot still applies real
  directional/omni lighting.
- `step_center` / `step_softness`: default `0.52 / 0.12`. Softness below `0.07`
  reads harsh and noisy at the current camera scale.
- `shadow_value` / `light_value`: default `0.72 / 1.04`. Do not push the lit value
  above `1.12`; Compatibility uses lower color precision and broad bright values
  recreate the pastel washout the owner rejected.
- `saturation` / `contrast`: default `1.08 / 1.06`; permitted art range is roughly
  `0.95-1.15 / 0.98-1.12`.
- `rim_strength`: default `0.08`; reserve `>0.14` for interactable silhouettes.

The shader does not define `light()`. Godot can force vertex lighting on mobile,
which skips custom light functions; shaping albedo while leaving the engine's
normal light pass intact is the safer cross-renderer contract.

### Ground depth and edge

- `base_color` / `edge_color`: actual palette colors, not white multipliers.
- `edge_width`: `0.13-0.18` for the existing normalized CylinderMesh UVs.
- `side_depth`: `0.68-0.76`; this gives the thin terrain islands a readable rim.
- `macro_scale`: world-space variation scale. Keep `0.18-0.35` for Sanctuary.
- `macro_variation`: default `0.035-0.045`, hard ceiling `0.07`. More becomes
  procedural camouflage and fights the illustrated buildings.

This shader never moves vertices and never writes alpha. It cannot alter a hit
box, placement footprint, navigation path, or z anchor.

### Water ripple

- `wave_direction_a/b`: two nonparallel world-space wave directions.
- `wave_frequency`: default `1.55`; keep under `2.4` for the Sanctuary pond.
- `wave_speed`: default `0.72`; this is restorative ambience, not rough water.
- `wave_height`: default `0.026 m`, maximum Sanctuary value `0.04 m`.
- `deep_color` / `shallow_color`: teal values with real dark/light separation.
- `foam_start/end`: normalized radial UV range. Tune against the final water-only
  mesh; these values assume centered `0..1` UVs.
- `foam_strength`: keep below `0.65` to avoid a white/pastel ring.

Only upward-facing vertices move. The water collider and interaction point must
remain on their authoritative flat plane; the visual displacement is limited to
a few centimetres and must never be sampled for gameplay height.

### Foliage sway

- `use_uv_anchor = false`: low-poly leaf mesh; `anchor_height/height_span` define
  the fixed base and flexible crown.
- `use_uv_anchor = true`: vertical card/Sprite3D-style mesh; `1 - UV.y` anchors
  the bottom. The actual atlas texture must be bound to `albedo_texture`.
- `wind_direction`, `wind_speed`, `wind_strength`: shared biome wind state.
  Sanctuary target is `0.78 speed / 0.055 m strength`; storm values should still
  stay under `0.12 m` at this camera scale.
- `wind_phase`: optional author offset. World origin already desynchronizes
  instances, so a duplicated material per tree is not required solely for phase.
- `alpha_cutoff`: cutout threshold. The shader uses `discard`, not blended alpha,
  so foliage remains depth-writing and avoids transparent sorting.
- Toon parameters follow the opaque surface limits.

`TIME` continues while a paused SceneTree is displayed. Before final wiring,
pause mode must either freeze the shader materials or use an externally managed
animation-time uniform. Do not ship a pause screen with foliage/water still
moving while every actor is frozen.

### Reward and capstone glow

- `glow_color`: pickup preset is restrained cyan; capstone preset is warm amber.
- `intensity`: `1.08-1.12` default; keep under `1.35` in ordinary play.
- `rim_power`: lower gives a broader shell; `2.2-2.6` is the current target.
- `minimum_fill`: keeps a faint readable core without turning the object white.
- `pulse_speed/depth`: action hierarchy. Pickups can be quicker than capstones.
- `shell_expand`: local-space expansion, default `0.018-0.022 m`. It is visual
  separation only, not an interaction radius.
- `scan_*`: restrained moving accent. Disable by setting `scan_strength = 0` on
  common materials if the scene becomes busy.

This is the only transparent/additive shader in the set. It keeps normal depth
testing, writes no depth, and must be placed on a duplicate child mesh. Cap the
visible set around 24-32 small shells on low-end targets and never glow every
ordinary prop.

## Safe future integration points

No integration is included in this lane. When the active gameplay batch is
stable, wire in this order and capture each step independently:

1. **Ground proof in Sanctuary.** In
   `scripts/sanctuary_style.gd::_create_rounded_patch()`, replace
   `_ground_material()` only for opaque `SoftGroundPatch`,
   `PackedEarthPath`, and `PackedEarthPathEdge` presentation meshes. Use
   duplicated `sanctuary_ground_moss.tres` or
   `sanctuary_ground_path.tres` materials. Keep
   `IllustratedContactShadow`, `ConstructionPlacementPreview`, and grid lines on
   their existing alpha materials.
2. **Opaque 3D material proof.** In
   `scripts/sanctuary_district.gd::_district_material()` and the additive
   construction pieces assembled by `scripts/sanctuary_style.gd`, trial
   `cozy_toon_surface` on wood/stone visual MeshInstance3D nodes. Do not assign it
   to the generated illustrated facility Sprite3D silhouettes; those are already
   authored and intentionally unshaded. For imported glTF surfaces, duplicate
   each source material and transfer its albedo texture rather than applying one
   color-only `material_override` to the whole model.
3. **Water proof.** `scripts/main.gd::_create_pond()` owns the legacy pond's
   `water` MeshInstance3D. The current visible illustrated Sanctuary pond is one
   atlas cell created by `scripts/sanctuary_style.gd::_add_environment_sprite()`;
   never deform that whole sprite because rocks, reeds, flowers, and water share
   the image. Use a separate, water-only subdivided visual mesh aligned over the
   illustrated water region, or first split a water-only atlas layer. Keep the
   existing PondWaterSource interaction and collider untouched.
4. **Foliage proof.** `scripts/main.gd::_create_tree()` currently registers whole
   roots in `sway_nodes`, and `scripts/sanctuary_style.gd::_add_environment_sprite()`
   separately performs CPU scale sway for illustrated trees. Choose exactly one
   motion owner. The shader is safest on leaf-only descendants found after
   `scripts/main.gd::_add_sourced_model()` instantiates a tree; do not combine it
   with the existing whole-root sway or apply it to measured trunks.
5. **Pickup glow proof.** In `scripts/main.gd::_spawn_expedition_pickup()`, after
   the base resource mesh is created under `PickupVisual`, add a collision-free
   duplicate MeshInstance3D child using `expedition_pickup_glow.tres`. The
   ResourcePickup root, pickup position, collection radius, and save ID remain
   authoritative.
6. **Capstone/cache hierarchy.** In
   `scripts/main.gd::_create_whisper_cache()`, shell only `CacheMarker`; toggle it
   from `_refresh_whisperwood_route()` when the chosen cache is actually
   claimable. In `scripts/main.gd::_create_expedition_route_landmarks()`, shell
   only `CapstoneSigil`; toggle it from `_refresh_expedition_routes()` when
   `objective_complete` and not `cache_claimed`. Never glow locked/off-branch
   objectives.

After each step, compare against
`docs/reference/sanctuary-final-look-reference.png` and the deterministic
Sanctuary capture. Shader work must deepen the existing forms; it cannot be used
to excuse underscaled geometry, weak building silhouettes, sparse world detail,
or inaccurate hit boxes.

## Performance and verification

- Five shader programs, no runtime loops, no screen-space sampling, and no
  renderer-exclusive buffers.
- Water uses three sine evaluations per vertex/fragment pair; foliage uses two
  sine evaluations per vertex. Keep water meshes around `16x16` subdivisions
  for a small pond and do not subdivide foliage solely for the shader.
- Ground and toon materials stay opaque and batch-friendly. Foliage is alpha
  cutout. Only reward shells add an extra transparent draw.
- Compatibility cannot rely on modern pipeline precompilation. Before shipping,
  display one instance of each preset for at least one loading frame; the
  included preview scene is suitable for that material warm-up path.

Fast resource-load verification (dummy renderer; catches resource and scene
parse failures, but does not prove GPU compilation):

```sh
HOME=/private/tmp /opt/homebrew/bin/godot --headless --path . \
  --rendering-method gl_compatibility --audio-driver Dummy \
  --log-file /private/tmp/isekai-shader-preview.log \
  --scene res://assets/generated/shaders/shader_preview.tscn --quit-after 8
```

Then inspect the log for shader/compiler errors. The known macOS certificate
lookup warning is unrelated to rendering.

Display-backed Compatibility compilation and three-frame motion capture on the
current macOS toolchain:

```sh
HOME=/private/tmp /opt/homebrew/bin/godot --path . \
  --display-driver macos --rendering-method gl_compatibility \
  --rendering-driver opengl3 --audio-driver Dummy --disable-vsync \
  --log-file /private/tmp/isekai-shader-display.log \
  --write-movie /private/tmp/isekai-shader-preview.png --fixed-fps 30 \
  --scene res://assets/generated/shaders/shader_preview.tscn --quit-after 3
```

Do not combine `--headless` with `--write-movie` on this Godot 4.7 macOS build:
the dummy rendering driver has no texture backend for movie capture.

Godot references:

- [Spatial shader built-ins and transparency behavior](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html)
- [Compatibility renderer feature limits](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- [Shader uniform hints and source-color handling](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html)
