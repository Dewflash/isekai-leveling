class_name ProdewtySanctuaryStyle
extends Node3D

const SanctuaryAssetCatalog = preload("res://scripts/sanctuary_asset_catalog.gd")

## The Sanctuary presentation layer is intentionally separate from gameplay.
## GameSession and the settlement grid remain authoritative; this node supplies
## the soft illustrated 2.5D language, world-space construction states, and
## ambient motion that the player reads while moving through the map.

const PROP_SHEET_PATH := "res://assets/generated/sanctuary/settlement-props-sheet.png"
const ENVIRONMENT_SHEET_PATH := "res://assets/generated/sanctuary/environment-sheet.png"
const PLAYER_STRUCTURE_SHEET_PATH := "res://assets/generated/sanctuary/player-structures-sheet.png"
const CONSTRUCTION_WORKER_SPRITE_SHEET_PATH := "res://assets/generated/sanctuary/mira-direction-walk-sheet-v2.png"
const GROUND_MOSS_MATERIAL_PATH := "res://assets/generated/shaders/sanctuary_ground_moss.tres"
const GROUND_PATH_MATERIAL_PATH := "res://assets/generated/shaders/sanctuary_ground_path.tres"
const STRUCTURE_SPRITE_MATERIAL_PATH := "res://assets/generated/shaders/sanctuary_toon_sprite.tres"
const OPEN_GROUND_TEXTURE_PATH := "res://assets/generated/sanctuary/sanctuary-open-ground-v1.png"
const OPEN_GROUND_SHADER_PATH := "res://assets/generated/shaders/sanctuary_ground_plate.gdshader"
const OPEN_GROUND_AUTHORED_SIZE := Vector2(80.0, 60.0)
const OPEN_GROUND_PLATE_SIZE := Vector2(80.0, 60.0)
const CELL_SIZE := 512.0
const CELL_INSET := 7.0
const CELL_EXTENT := 498.0
const ENVIRONMENT_CELL_WIDTH := 627.0
const ENVIRONMENT_CELL_HEIGHT := 418.0
const ENVIRONMENT_CELL_INSET := 7.0
const ENVIRONMENT_CELL_WIDTH_INSET := 613.0
const ENVIRONMENT_CELL_HEIGHT_INSET := 404.0
const PLAYER_STRUCTURE_CELL_SIZE := 512.0
const PLAYER_STRUCTURE_CELL_INSET := 7.0
const PLAYER_STRUCTURE_CELL_EXTENT := 498.0
const WALK_SHEET_COLUMNS := 4
const WALK_SHEET_ROWS := 4

# Opaque bounds are measured inside each cropped atlas region. Keeping these
# values beside the asset identifiers makes `world_size` mean visible artwork
# height, not transparent sheet-cell height, and lets every Sprite3D place its
# actual feet/base on its Node3D origin. Footprints are presentation metadata in
# world metres; they never participate in settlement occupancy or collision.
const PROP_ASSET_PROFILES := [
	{"asset_id": "settlement_props/scaffold", "opaque_bounds": Rect2i(31, 17, 440, 452), "footprint_ratio": Vector2(0.86, 0.36)},
	{"asset_id": "settlement_props/workshop", "opaque_bounds": Rect2i(21, 24, 456, 444), "footprint_ratio": Vector2(0.79, 0.38)},
	{"asset_id": "settlement_props/tent", "opaque_bounds": Rect2i(13, 21, 466, 408), "footprint_ratio": Vector2(0.78, 0.38)},
	{"asset_id": "settlement_props/market", "opaque_bounds": Rect2i(33, 44, 432, 386), "footprint_ratio": Vector2(0.82, 0.37)},
	{"asset_id": "settlement_props/garden", "opaque_bounds": Rect2i(11, 51, 468, 369), "footprint_ratio": Vector2(0.83, 0.37)},
	{"asset_id": "settlement_props/well", "opaque_bounds": Rect2i(20, 49, 445, 330), "footprint_ratio": Vector2(0.83, 0.42)},
]
const ENVIRONMENT_ASSET_PROFILES := [
	{"asset_id": "environment/fruit_tree", "opaque_bounds": Rect2i(112, 10, 387, 381), "footprint_ratio": Vector2(0.20, 0.16)},
	{"asset_id": "environment/pine_tree", "opaque_bounds": Rect2i(142, 9, 312, 392), "footprint_ratio": Vector2(0.20, 0.16)},
	{"asset_id": "environment/autumn_tree", "opaque_bounds": Rect2i(131, 9, 348, 377), "footprint_ratio": Vector2(0.20, 0.16)},
	{"asset_id": "environment/rocks", "opaque_bounds": Rect2i(68, 47, 462, 304), "footprint_ratio": Vector2(0.66, 0.30)},
	{"asset_id": "environment/lantern_fence", "opaque_bounds": Rect2i(95, 12, 375, 357), "footprint_ratio": Vector2(0.78, 0.22)},
	{"asset_id": "environment/pond", "opaque_bounds": Rect2i(39, 13, 505, 358), "footprint_ratio": Vector2(0.90, 0.50)},
]
const PLAYER_STRUCTURE_ASSET_PROFILES := {
	# These are measured inside the 498px cropped cell. The lower edge remains
	# the art feet; the presentation binding still replaces visual_footprint with
	# the authoritative local collision envelope for each placed structure.
	"workshop": {"sheet_index": 0, "asset_id": "settlement_props/player_structure/workshop", "opaque_bounds": Rect2i(22, 34, 466, 445), "footprint_ratio": Vector2(0.92, 0.56)},
	"archive": {"sheet_index": 1, "asset_id": "settlement_props/player_structure/archive", "opaque_bounds": Rect2i(24, 43, 463, 432), "footprint_ratio": Vector2(0.92, 0.56)},
	"storage_shed": {"sheet_index": 2, "asset_id": "settlement_props/player_structure/storage_shed", "opaque_bounds": Rect2i(39, 90, 455, 390), "footprint_ratio": Vector2(0.94, 0.58)},
	"livestock_pen": {"sheet_index": 3, "asset_id": "settlement_props/player_structure/livestock_pen", "opaque_bounds": Rect2i(39, 84, 453, 395), "footprint_ratio": Vector2(0.94, 0.62)},
	"rain_cistern": {"sheet_index": 4, "asset_id": "settlement_props/player_structure/rain_cistern", "opaque_bounds": Rect2i(50, 82, 413, 397), "footprint_ratio": Vector2(0.86, 0.62)},
	# The sixth cell is retained as a future shared market/workbench activity
	# prop; it is not currently a player-placeable structure kind.
	"market": {"sheet_index": 5, "asset_id": "settlement_props/player_structure/market", "opaque_bounds": Rect2i(40, 84, 452, 395), "footprint_ratio": Vector2(0.92, 0.58)},
}

# Fixed Sanctuary landmarks are authored by the district's shell bodies, but
# their presentation is owned here. The shell and the visible root therefore
# share an identifier and the same local approach zones; no second set of
# landmark coordinates is allowed in the presentation layer.
const CANONICAL_LANDMARKS := [
	{
		"id": "hearth_lodge",
		"root_name": "HearthLodge",
		"source_name": "HearthLodge",
		"collision_name": "HearthLodgeCollision",
		"asset_id": "sanctuary/landmarks/hearth_lodge",
		"collision_profile_id": "sanctuary_landmark_hearth_lodge_shell_v1",
		"access_zones": [
			{"id": "front_door", "kind": "door", "visible_feature_id": "hearth_lodge_front_door", "center": [0.0, 0.0, 2.18], "size": [1.18, 0.94], "facing": [0.0, 0.0, 1.0], "must_be_visible_in_asset": true},
		],
	},
	{
		"id": "archive_house",
		"root_name": "ArchiveHouse",
		"source_name": "ArchiveHouse",
		"collision_name": "ArchiveHouseCollision",
		"asset_id": "sanctuary/landmarks/archive_house",
		"collision_profile_id": "sanctuary_landmark_archive_house_shell_v1",
		"access_zones": [
			{"id": "front_door", "kind": "door", "visible_feature_id": "archive_house_front_door", "center": [0.0, 0.0, 1.96], "size": [0.96, 0.90], "facing": [0.0, 0.0, 1.0], "must_be_visible_in_asset": true},
		],
	},
	{
		"id": "wanderers_bazaar",
		"root_name": "BazaarHouse",
		"source_name": "BazaarHouse",
		"collision_name": "BazaarHouseCollision",
		"asset_id": "sanctuary/landmarks/wanderers_bazaar",
		"collision_profile_id": "sanctuary_landmark_wanderers_bazaar_shell_v1",
		"access_zones": [
			{"id": "front_door", "kind": "door", "visible_feature_id": "wanderers_bazaar_front_door", "center": [0.0, 0.0, 1.82], "size": [1.00, 0.92], "facing": [0.0, 0.0, 1.0], "must_be_visible_in_asset": true},
		],
	},
]

const PALETTE := {
	# Mid-value, slightly warm moss and earth keep the generated illustration
	# readable without the fluorescent lawn/pale-path split of the prototype.
	"meadow": Color("#71865d"),
	"meadow_light": Color("#83966b"),
	"meadow_shadow": Color("#586d50"),
	"meadow_deep": Color("#455a46"),
	"forest_skirt": Color("#173526"),
	"build_field": Color("#788b63"),
	"path": Color("#b58a65"),
	"path_light": Color("#c09973"),
	"path_shadow": Color("#89634f"),
	"path_edge": Color("#745f4e"),
	"contact_shadow": Color(0.12, 0.16, 0.12, 0.24),
	"grid": Color(0.58, 0.94, 0.81, 0.32),
	"grid_valid": Color(0.32, 0.96, 0.85, 0.82),
	"grid_blocked": Color(0.97, 0.46, 0.48, 0.78),
	"wood": Color("#9d6646"),
	"wood_dark": Color("#5c4035"),
	"water": Color("#62c9c5"),
	"warm": Color("#ffb45d"),
}

var host_world: Node3D
var sanctuary_zone: Node3D
var source_district: Node3D
var prop_sheet: Texture2D
var environment_sheet: Texture2D
var player_structure_sheet: Texture2D
var ground_moss_material: ShaderMaterial
var ground_path_material: ShaderMaterial
var structure_sprite_material: ShaderMaterial
var open_ground_plate: MeshInstance3D
var grid_root: Node3D
var preview_root: Node3D
var preview_fill: MeshInstance3D
var preview_outline: Node3D
var preview_art: Sprite3D
var preview_art_kind := ""
var preview_art_rotation := -1
var placement_active := false
var placement_center := Vector3.ZERO
var placement_footprint := Vector2i.ONE
var placement_rotation := 0
var placement_valid := false
var elapsed := 0.0
var swaying_nodes: Array[Dictionary] = []
var pulsing_nodes: Array[Dictionary] = []
var fire_lights: Array[Dictionary] = []
var activity_motion_nodes: Array[Dictionary] = []
var construction_worker_nodes: Array[Dictionary] = []
var resource_visual_roots: Array[Node3D] = []
var canonical_landmark_roots: Dictionary = {}
var lived_in_activity_root: Node3D
var key_light_direction := Vector3(-0.42, 0.84, 0.34)
var build_sprite_regions := {
	"scaffold": 0,
	"workshop": 1,
	"tent": 2,
	"market": 3,
	"garden": 4,
	"well": 5,
}

func build(parent_world: Node3D, zone: Node3D, district: Node3D, legacy_nodes: Array) -> void:
	if zone == null:
		return
	host_world = parent_world
	sanctuary_zone = zone
	source_district = district
	name = "SanctuaryIllustratedStyle"
	zone.add_child(self)
	prop_sheet = load(PROP_SHEET_PATH) as Texture2D
	environment_sheet = load(ENVIRONMENT_SHEET_PATH) as Texture2D
	player_structure_sheet = load(PLAYER_STRUCTURE_SHEET_PATH) as Texture2D
	ground_moss_material = load(GROUND_MOSS_MATERIAL_PATH) as ShaderMaterial
	ground_path_material = load(GROUND_PATH_MATERIAL_PATH) as ShaderMaterial
	structure_sprite_material = load(STRUCTURE_SPRITE_MATERIAL_PATH) as ShaderMaterial
	_hide_replaced_presentation(legacy_nodes)
	_hide_furnace_presentation()
	if source_district != null:
		# Visibility does not disable the district's shell collisions. The
		# gameplay footprint therefore stays in place while its hard-edged source
		# meshes are replaced by this authored 2.5D layer.
		source_district.visible = false
	_build_open_ground_plate()
	_build_soft_ground()
	_build_forest_backdrop()
	_build_paths()
	_build_open_build_field()
	_build_story_campfire()
	_build_canonical_landmarks()
	_build_environment_framing()
	_build_lived_in_activity()
	_build_route_markers()
	_build_ambient_lights()

func set_key_light_direction(direction: Vector3) -> void:
	if direction.length_squared() < 0.001:
		return
	key_light_direction = direction.normalized()
	if structure_sprite_material != null:
		structure_sprite_material.set_shader_parameter("key_light_direction", key_light_direction)
	for sprite_value in find_children("*", "Sprite3D", true, false):
		var sprite := sprite_value as Sprite3D
		var material := sprite.material_override as ShaderMaterial if sprite != null else null
		if material != null:
			material.set_shader_parameter("key_light_direction", key_light_direction)

func _process(delta: float) -> void:
	elapsed += delta
	_enforce_a_plus_c_authority()
	_enforce_resource_visuals()
	_hide_furnace_presentation()
	for sway_data in swaying_nodes:
		var raw_node: Variant = sway_data.get("node")
		if not is_instance_valid(raw_node):
			continue
		var node := raw_node as Node3D
		if node == null:
			continue
		var phase := float(sway_data.get("phase", 0.0))
		var amplitude := float(sway_data.get("amplitude", 0.025))
		var base_scale: Vector3 = sway_data.get("base_scale", Vector3.ONE)
		node.scale = Vector3(base_scale.x * (1.0 + sin(elapsed * 1.25 + phase) * amplitude), base_scale.y, base_scale.z * (1.0 - sin(elapsed * 1.25 + phase) * amplitude * 0.45))
	for pulse_data in pulsing_nodes:
		var raw_pulse_node: Variant = pulse_data.get("node")
		if not is_instance_valid(raw_pulse_node):
			continue
		var pulse_node := raw_pulse_node as Node3D
		if pulse_node == null:
			continue
		var pulse_phase := float(pulse_data.get("phase", 0.0))
		var pulse_strength := float(pulse_data.get("strength", 0.04))
		var pulse_base: Vector3 = pulse_data.get("base_scale", Vector3.ONE)
		pulse_node.scale = pulse_base * (1.0 + sin(elapsed * 2.4 + pulse_phase) * pulse_strength)
	for fire_data in fire_lights:
		var raw_light: Variant = fire_data.get("node")
		if not is_instance_valid(raw_light):
			continue
		var light := raw_light as OmniLight3D
		if light == null:
			continue
		var light_base := float(fire_data.get("energy", 0.8))
		light.light_energy = light_base + sin(elapsed * 5.0 + float(fire_data.get("phase", 0.0))) * 0.16 + sin(elapsed * 8.1) * 0.08
	for activity_data in activity_motion_nodes:
		var raw_activity_node: Variant = activity_data.get("node")
		if not is_instance_valid(raw_activity_node):
			continue
		var activity_node := raw_activity_node as Node3D
		if activity_node == null:
			continue
		var base_position: Vector3 = activity_data.get("base_position", activity_node.position)
		var phase := float(activity_data.get("phase", 0.0))
		var lift := float(activity_data.get("lift", 0.025))
		activity_node.position = base_position + Vector3(0.0, sin(elapsed * 1.35 + phase) * lift, 0.0)
		activity_node.rotation.y = float(activity_data.get("base_rotation", activity_node.rotation.y)) + sin(elapsed * 0.82 + phase) * 0.035
	for worker_data in construction_worker_nodes:
		var raw_worker: Variant = worker_data.get("node")
		if not is_instance_valid(raw_worker):
			continue
		var worker := raw_worker as Sprite3D
		if worker == null:
			continue
		var worker_sheet := worker.texture as AtlasTexture
		if worker_sheet == null:
			continue
		var frame_count := maxi(1, int(worker.get_meta("walk_frame_count", 4)))
		var frame_rate := maxf(1.0, float(worker.get_meta("walk_frame_rate", 6.0)))
		var frame_time := float(worker_data.get("frame_time", 0.0)) + delta
		worker_data["frame_time"] = frame_time
		var frame := posmod(int(floor(frame_time * frame_rate)), frame_count)
		var cell_size: Array = worker.get_meta("walk_cell_size", [1.0, 1.0])
		var cell_width := float(cell_size[0])
		var cell_height := float(cell_size[1])
		var direction_frame := int(worker.get_meta("direction_frame", 0))
		worker_sheet.region = Rect2(float(frame) * cell_width, float(direction_frame) * cell_height, cell_width, cell_height)
		worker.set_meta("animation_frame", frame)
		var base_position: Vector3 = worker_data.get("base_position", worker.position)
		var phase := float(worker_data.get("phase", 0.0))
		worker.position = base_position + Vector3(0.0, absf(sin(frame_time * 5.2 + phase)) * 0.025, 0.0)

func _hide_replaced_presentation(legacy_nodes: Array) -> void:
	for legacy_node in legacy_nodes:
		var node := legacy_node as Node
		if node != null:
			_hide_render_tree(node)

func _hide_furnace_presentation() -> void:
	# The systems prototype keeps Furnace as a gameplay interaction root outside
	# Sanctuary. Its old BoxMesh is a visible debug cube in the illustrated map;
	# the generated workshop/forge assets supply the authored presentation while
	# the interaction node and distance checks remain intact.
	if host_world == null:
		return
	var furnace := host_world.get("furnace") as Node3D
	if furnace != null:
		_hide_render_tree(furnace)

func _enforce_a_plus_c_authority() -> void:
	# Gameplay refreshes may touch source nodes after a save load, construction
	# tick, or station update. The generated layer remains the only player-facing
	# Sanctuary presentation, so keep the legacy district and landmark sources
	# hidden at the presentation boundary on every frame.
	if source_district != null:
		source_district.visible = false
		_hide_render_tree(source_district)
	for landmark_id in canonical_landmark_roots:
		var root := canonical_landmark_roots[landmark_id] as Node3D
		if root == null or not is_instance_valid(root):
			continue
		var source := root.get_meta("source_measurement_node", null) as Node3D
		if source != null:
			source.visible = false
			_hide_render_tree(source)
		var generated_art := root.get_node_or_null("GeneratedAPlusCLandmark") as Sprite3D
		if generated_art != null:
			generated_art.visible = true
		root.set_meta("presentation_authority", "generated_a_plus_c")

func finalize_legacy_cleanup() -> void:
	# The systems prototype creates a few static meshes before this director is
	# attached. Hide those render trees after creation, while preserving resource
	# nodes, route interaction roots, the floor collision, and the living paddock
	# resident. Player-owned structures are created later and reconciled through
	# apply_structure_visual(), so they are intentionally not touched here.
	if sanctuary_zone == null:
		return
	for child in sanctuary_zone.get_children():
		if child == self or child == source_district:
			continue
		if child.name == "SanctuaryGround":
			# Keep the large floor body for traversal and save compatibility, but
			# replace its prototype-green render material. The illustrated ground
			# islands above it are presentation-only and do not own collision.
			for ground_mesh_value in child.find_children("*", "MeshInstance3D", true, false):
				var ground_mesh := ground_mesh_value as MeshInstance3D
				if ground_mesh == null:
					continue
				var backdrop_material := StandardMaterial3D.new()
				backdrop_material.albedo_color = PALETTE["forest_skirt"]
				backdrop_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				backdrop_material.roughness = 0.98
				ground_mesh.material_override = backdrop_material
				ground_mesh.set_meta("presentation_role", "a_plus_c_collision_backdrop")
			continue
		if child.name == "CloverLivestockPen":
			continue
		if child.is_in_group("resource_node") or child.is_in_group("route_gate"):
			_hide_render_tree(child)
			continue
		_hide_render_tree(child)
		if child is MeshInstance3D:
			(child as MeshInstance3D).visible = false

func replace_resource_tree_visuals(resource_trees: Array) -> void:
	resource_visual_roots.clear()
	var index := 0
	for tree_value in resource_trees:
		var tree := tree_value as Node3D
		if tree == null:
			continue
		resource_visual_roots.append(tree)
		for child in tree.get_children():
			if child is Node3D and not child is StaticBody3D:
				(child as Node3D).visible = false
		_hide_render_tree(tree)
		var sprite_index := index % 3
		var tree_definition := SanctuaryAssetCatalog.tree_definition(sprite_index)
		var sprite := _add_environment_sprite(sprite_index, tree.global_position + Vector3(0.0, 0.1, 0.0), float(tree_definition.get("world_size", 4.25)) * maxf(0.78, tree.scale.x), float(index) * 0.65)
		if sprite != null:
			sprite.name = "IllustratedResourceTree"
			sprite.reparent(tree)
			# Reparenting preserves the global transform and can therefore adjust
			# local scale when a resource root is scaled. Ambient motion must retain
			# that corrected scale instead of restoring its pre-reparent value.
			_refresh_tracked_sprite_base_scale(sprite)
		index += 1
	_enforce_resource_visuals()

func _enforce_resource_visuals() -> void:
	# ResourceNode restores its own child visibility after save/load and after a
	# harvest. The illustrated layer owns presentation, so keep gameplay meshes
	# and imported models hidden while leaving the interaction body and generated
	# sprite alive. This is deliberately scoped to registered Sanctuary roots.
	for tree in resource_visual_roots:
		if not is_instance_valid(tree):
			continue
		for child in tree.get_children():
			if child is Node3D and not child is StaticBody3D and child.name != "IllustratedResourceTree":
				(child as Node3D).visible = false

func _hide_render_tree(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		if child is Node3D and str(child.name).begins_with("Sourced_"):
			(child as Node3D).visible = false
			continue
		if child is MeshInstance3D or child is Label3D or child is GPUParticles3D or child is CPUParticles3D:
			(child as Node3D).visible = false
		_hide_render_tree(child)

func _build_soft_ground() -> void:
	# The authored plate supplies the continuous woodland floor. Keep only a
	# handful of small shader-driven moss overlays for depth and measured style
	# coverage; a giant opaque procedural slab would hide the authored ground and
	# recreate the old smooth-green presentation the art gate rejected.
	_add_rounded_patch(Vector3(-9.8, 0.024, -5.5), Vector2(2.6, 1.8), PALETTE["meadow_shadow"], -12.0)
	_add_rounded_patch(Vector3(9.4, 0.024, 5.0), Vector2(2.7, 1.9), PALETTE["meadow_light"], 14.0)
	_add_rounded_patch(Vector3(-8.0, 0.026, 7.6), Vector2(2.5, 1.5), PALETTE["meadow_light"], 4.0)
	_add_rounded_patch(Vector3(7.0, 0.026, -7.0), Vector2(2.6, 1.5), PALETTE["meadow_shadow"], -8.0)
	for edge_data in [
		[Vector3(-12.9, 0.028, -5.8), Vector2(1.7, 2.3), -16.0, "meadow_deep"],
		[Vector3(-13.2, 0.029, 3.0), Vector2(1.5, 2.0), 9.0, "meadow_shadow"],
		[Vector3(-9.8, 0.029, 10.0), Vector2(2.2, 1.3), -8.0, "meadow_light"],
		[Vector3(-2.8, 0.029, 11.2), Vector2(2.4, 1.1), 5.0, "meadow_shadow"],
		[Vector3(5.4, 0.029, 10.9), Vector2(2.0, 1.1), -11.0, "meadow_light"],
		[Vector3(12.8, 0.029, 6.2), Vector2(1.6, 2.2), 14.0, "meadow_shadow"],
		[Vector3(13.3, 0.029, -2.8), Vector2(1.4, 1.9), -7.0, "meadow_deep"],
		[Vector3(8.2, 0.029, -10.1), Vector2(2.1, 1.4), 10.0, "meadow_light"],
		[Vector3(-1.0, 0.029, -10.5), Vector2(2.6, 1.1), -4.0, "meadow_shadow"],
	]:
		var edge := _add_rounded_patch(edge_data[0], edge_data[1], PALETTE[str(edge_data[3])], float(edge_data[2]))
		edge.name = "IrregularMeadowEdge"

func _build_forest_backdrop() -> void:
	# A+C reads as a settlement carved out of a living forest, not a green
	# platform floating in empty space. These distant cards are intentionally
	# non-interactive framing art: they sit beyond the authored build reserve,
	# never claim settlement cells, and have no physics body. Foreground trees
	# and rocks continue to use the measured framing contract in the catalog.
	var backdrop := [
		[Vector3(-13.8, 0.10, -11.8), 1, 6.0, 0.78],
		[Vector3(-8.5, 0.10, -13.4), 1, 6.2, 0.72],
		[Vector3(-2.6, 0.10, -14.0), 0, 5.8, 0.68],
		[Vector3(3.6, 0.10, -14.0), 1, 5.9, 0.70],
		[Vector3(9.4, 0.10, -12.9), 2, 6.0, 0.74],
		[Vector3(14.2, 0.10, -10.5), 1, 5.7, 0.80],
	]
	for item in backdrop:
		var sprite := _add_environment_sprite(int(item[1]), item[0], float(item[2]), float(item[0].x) * 0.08)
		if sprite == null:
			continue
		sprite.name = "APlusCForestBackdrop"
		sprite.modulate = Color(float(item[3]), float(item[3]) * 1.03, float(item[3]) * 0.92, 1.0)
		sprite.set_meta("presentation_role", "distant_forest_framing")

func _build_open_ground_plate() -> void:
	# This is presentation-only authored ground: it carries no occupancy, pathing,
	# or collision authority. The free build reserve and all hitboxes remain owned
	# by GameSession and the existing district shells. Keeping the plate as a
	# horizontal textured quad lets the player-directed layout remain open while
	# giving Sanctuary the dense woodland floor shown in the A+C target.
	var ground_texture := load(OPEN_GROUND_TEXTURE_PATH) as Texture2D
	if ground_texture == null:
		push_warning("Sanctuary open ground texture could not be loaded: %s" % OPEN_GROUND_TEXTURE_PATH)
		return
	open_ground_plate = MeshInstance3D.new()
	open_ground_plate.name = "SanctuaryOpenGroundPlate"
	var mesh := QuadMesh.new()
	mesh.size = OPEN_GROUND_PLATE_SIZE
	open_ground_plate.mesh = mesh
	open_ground_plate.position = Vector3(0.0, 0.003, 0.7)
	open_ground_plate.rotation_degrees.x = -90.0
	var shader := load(OPEN_GROUND_SHADER_PATH) as Shader
	if shader == null:
		push_warning("Sanctuary open ground shader could not be loaded: %s" % OPEN_GROUND_SHADER_PATH)
		return
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("ground_texture", ground_texture)
	material.set_shader_parameter("authored_size", OPEN_GROUND_AUTHORED_SIZE)
	material.set_shader_parameter("plate_size", OPEN_GROUND_PLATE_SIZE)
	material.set_shader_parameter("forest_skirt_color", PALETTE["forest_skirt"])
	open_ground_plate.material_override = material
	open_ground_plate.set_meta("asset_id", "sanctuary/ground/open_meadow_v1")
	open_ground_plate.set_meta("presentation_only", true)
	open_ground_plate.set_meta("presentation_role", "authored_open_ground_backdrop")
	open_ground_plate.set_meta("collision_authority", "none")
	open_ground_plate.set_meta("occupancy_authority", "GameSession")
	open_ground_plate.set_meta("occupies_build_cells", false)
	open_ground_plate.set_meta("measurement_source", "generated_ground_plate_dimensions")
	open_ground_plate.set_meta("source_texture_path", OPEN_GROUND_TEXTURE_PATH)
	open_ground_plate.set_meta("world_size", [OPEN_GROUND_PLATE_SIZE.x, OPEN_GROUND_PLATE_SIZE.y])
	add_child(open_ground_plate)

func _build_paths() -> void:
	# Two-to-three-metre traversal lanes use a dark packed-earth shoulder, a
	# desaturated core, and small deterministic wear patches. This produces an
	# irregular boundary without adding collision or claiming settlement cells.
	_add_worn_path_segment(Vector3(0.0, 0.052, 2.0), Vector2(3.2, 16.0), 0.0)
	_add_worn_path_segment(Vector3(-4.8, 0.055, 0.3), Vector2(11.0, 2.8), -4.0)
	_add_worn_path_segment(Vector3(5.6, 0.055, 0.4), Vector2(9.5, 2.5), 5.0)
	_add_worn_path_segment(Vector3(-8.3, 0.058, -4.8), Vector2(4.0, 1.9), 0.0, true)
	_add_worn_path_segment(Vector3(8.7, 0.058, 5.0), Vector2(4.0, 1.9), 0.0, true)
	for wear_data in [
		[Vector3(-1.48, 0.059, -3.0), Vector2(0.72, 1.45), -14.0],
		[Vector3(1.47, 0.059, -0.7), Vector2(0.62, 1.20), 11.0],
		[Vector3(-1.42, 0.059, 5.5), Vector2(0.58, 1.30), 8.0],
		[Vector3(-7.4, 0.059, -1.0), Vector2(1.35, 0.55), -8.0],
		[Vector3(-3.4, 0.059, 1.62), Vector2(1.10, 0.50), 12.0],
		[Vector3(4.8, 0.059, -0.93), Vector2(1.20, 0.48), -11.0],
		[Vector3(8.1, 0.059, 1.53), Vector2(1.05, 0.45), 6.0],
	]:
		var wear := _add_rounded_patch(wear_data[0], wear_data[1], PALETTE["path_light"], float(wear_data[2]))
		wear.name = "IrregularPathWear"
	for intrusion_data in [
		[Vector3(-1.42, 0.061, -5.0), Vector2(0.78, 1.10), -8.0],
		[Vector3(1.38, 0.061, 8.0), Vector2(0.70, 1.25), 13.0],
		[Vector3(-8.4, 0.064, -1.02), Vector2(1.25, 0.60), 7.0],
		[Vector3(-7.1, 0.064, 1.52), Vector2(1.00, 0.52), -10.0],
		[Vector3(7.2, 0.064, -0.75), Vector2(1.10, 0.52), 9.0],
		[Vector3(8.6, 0.064, 1.44), Vector2(0.92, 0.48), -7.0],
	]:
		var intrusion := _add_rounded_patch(intrusion_data[0], intrusion_data[1], PALETTE["meadow"], float(intrusion_data[2]))
		intrusion.name = "IrregularGrassIntrusion"
	for stone_data in [
		[Vector3(-1.8, 0.075, 5.8), 0.22], [Vector3(1.9, 0.075, 5.9), 0.25],
		[Vector3(-2.15, 0.075, -4.0), 0.20], [Vector3(2.3, 0.075, -4.0), 0.19],
		[Vector3(-7.0, 0.075, 1.8), 0.23], [Vector3(7.1, 0.075, 2.0), 0.20],
	]:
		_add_environment_sprite(3, stone_data[0], float(stone_data[1]) * 3.0, 0.0)

func _build_open_build_field() -> void:
	# The center is intentionally left open for authoritative player placement.
	# Keep its quiet ground treatment and build-mode-only grid, but do not paint
	# permanent plot discs into the world: even neutral pads imply a prescribed
	# settlement layout before the player has chosen one.
	# The authored ground already carries the clearing. Keep the reserve's
	# presentation as a barely-there tint so it remains discoverable without
	# hiding the woodland texture or dictating an old prototype-style oval.
	var field_edge := _add_rounded_patch(Vector3(0.0, 0.061, 1.65), Vector2(11.0, 8.6), Color(0.20, 0.28, 0.20, 0.18), 0.0)
	field_edge.name = "PlayerDirectedBuildFieldEdge"
	var field := _add_rounded_patch(Vector3(0.0, 0.064, 1.65), Vector2(10.6, 8.2), Color(0.40, 0.52, 0.36, 0.11), 0.0)
	field.name = "PlayerDirectedBuildField"
	grid_root = Node3D.new()
	grid_root.name = "BuildGridOverlay"
	grid_root.visible = false
	add_child(grid_root)
	for x in range(-5, 6):
		_add_grid_line(Vector3(float(x), 0.09, 1.65), Vector3(0.018, 0.026, 8.0))
	for z in range(-2, 7):
		_add_grid_line(Vector3(0.0, 0.09, float(z)), Vector3(10.0, 0.026, 0.018))
	preview_root = Node3D.new()
	preview_root.name = "ConstructionPlacementPreview"
	preview_root.visible = false
	add_child(preview_root)
	# Build mode must show the same rectangular multi-cell claim that
	# GameSession validates. A rounded/circular fill reads as a larger, softer
	# area than the real hitbox and was the source of visible placement drift.
	preview_fill = _soft_box(preview_root, "PreviewFill", Vector3.ONE, Vector3.ZERO, PALETTE["grid_valid"], true)
	preview_outline = Node3D.new()
	preview_outline.name = "PreviewOutline"
	preview_root.add_child(preview_outline)
	for index in 4:
		var edge := _soft_box(preview_outline, "Edge_%d" % index, Vector3.ONE, Vector3.ZERO, PALETTE["grid_valid"], true)
		edge.name = "Edge_%d" % index

func _build_story_campfire() -> void:
	# The center is a shared activity landmark, not a player-owned building. It
	# gives the open reserve a human scale reference and carries the warm focal
	# beat from the saved Sanctuary target without prescribing where future plots
	# must be placed.
	var fire_position := Vector3(0.0, 0.10, 1.35)
	var fire_pad := _add_rounded_patch(fire_position + Vector3(0.0, -0.035, 0.0), Vector2(3.8, 2.45), PALETTE["path_shadow"], -2.0)
	fire_pad.name = "SharedHearthActivityPad"
	var fire := _fire_sprite_from_sheet(fire_position, 2.55)
	if fire != null:
		fire.name = "SharedHearthCampfire"
		pulsing_nodes.append({"node": fire, "phase": 0.3, "strength": 0.028, "base_scale": fire.scale})
	var glow := OmniLight3D.new()
	glow.name = "SharedHearthCampfireLight"
	glow.position = fire_position + Vector3(0.0, 0.9, 0.0)
	glow.light_color = PALETTE["warm"]
	glow.light_energy = 0.75
	glow.omni_range = 4.0
	glow.shadow_enabled = false
	add_child(glow)
	fire_lights.append({"node": glow, "energy": 0.75, "phase": 0.6})

func _add_grid_line(position: Vector3, size: Vector3) -> void:
	var line := _soft_box(grid_root, "GridLine", size, position, PALETTE["grid"], true)
	line.material_override = _soft_material(PALETTE["grid"], true, true)


func _build_canonical_landmarks() -> void:
	# Fixed buildings are canonical shared landmarks, not player-owned plots.
	# Their shell bodies remain in the district for physics compatibility, while
	# each visible root below is instantiated from that body's exact source asset.
	# This keeps the user-controlled building layout completely untouched.
	canonical_landmark_roots.clear()
	var landmark_root := Node3D.new()
	landmark_root.name = "CanonicalLandmarks"
	add_child(landmark_root)
	for landmark_value in CANONICAL_LANDMARKS:
		if landmark_value is Dictionary:
			_bind_canonical_landmark(landmark_root, landmark_value as Dictionary)

	_add_contact_shadow(self, Vector3(6.1, 0.086, 5.7), Vector2(2.5, 1.25), 0.0)
	var hearth := _add_prop_sprite("well", Vector3(6.1, 0.12, 5.6), 3.0, true)
	hearth.name = "HearthWellAndFire"
	var hearth_light := OmniLight3D.new()
	hearth_light.name = "IllustratedHearthLight"
	hearth_light.position = Vector3(6.1, 1.2, 5.6)
	hearth_light.light_color = PALETTE["warm"]
	hearth_light.omni_range = 4.2
	hearth_light.light_energy = 0.9
	add_child(hearth_light)
	fire_lights.append({"node": hearth_light, "energy": 0.9, "phase": 0.0})

func _bind_canonical_landmark(parent: Node3D, definition: Dictionary) -> void:
	if parent == null or source_district == null:
		return
	var source := source_district.get_node_or_null(str(definition.get("source_name", ""))) as Node3D
	var shell := source_district.get_node_or_null(str(definition.get("collision_name", ""))) as StaticBody3D
	if source == null or shell == null:
		return
	var asset_id := str(definition.get("asset_id", ""))
	if asset_id.is_empty():
		return
	var zones: Array = (definition.get("access_zones", []) as Array).duplicate(true)
	var root := Node3D.new()
	root.name = str(definition.get("root_name", definition.get("id", "Landmark")))
	root.add_to_group("canonical_landmark")
	root.set_meta("landmark_id", str(definition.get("id", "")))
	root.set_meta("asset_id", asset_id)
	root.set_meta("collision_asset_id", asset_id)
	root.set_meta("collision_profile_id", str(definition.get("collision_profile_id", "")))
	root.set_meta("access_zones", zones.duplicate(true))
	root.set_meta("ground_pivot", [0.0, 0.0, 0.0])
	# Keep the imported scene available as a hidden provenance/measurement node.
	# The generated A+C cutout owns visible presentation; this node remains the
	# authoritative source envelope used to audit the existing shell collision.
	root.set_meta("source_measurement_node", source)
	root.set_meta("source_render_policy", "hidden_generated_a_plus_c_presentation")
	root.set_meta("collision_node", shell)
	parent.add_child(root)
	# The district shell is authoritative for the landmark transform. This
	# avoids duplicating placement/rotation coordinates in the art layer.
	root.global_transform = shell.global_transform

	shell.set_meta("landmark_id", str(definition.get("id", "")))
	shell.set_meta("asset_id", asset_id)
	shell.set_meta("collision_asset_id", asset_id)
	shell.set_meta("collision_profile_id", str(definition.get("collision_profile_id", "")))
	shell.set_meta("access_zones", zones.duplicate(true))
	shell.set_meta("visible_root", root)
	for child in shell.get_children():
		var collision := child as CollisionShape3D
		if collision == null:
			continue
		collision.set_meta("landmark_id", str(definition.get("id", "")))
		collision.set_meta("landmark_asset_id", asset_id)
		collision.set_meta("asset_id", "%s/collision/%s" % [asset_id, collision.name])
		collision.set_meta("access_zones", zones.duplicate(true))
		collision.set_meta("visible_root", root)

	# The collision shell remains sourced and measured, but the fixed landmark's
	# visible presentation must speak the same A+C language as player-built
	# facilities. Re-instantiating the old Quaternius scene here created the
	# hybrid runtime that made a fresh launch look like the prototype. The
	# generated cutout is presentation-only; the shell remains authoritative for
	# interaction and access.
	var generated_kind := ""
	var generated_world_size := 6.6
	match str(definition.get("id", "")):
		"hearth_lodge":
			generated_kind = "workshop"
			generated_world_size = 8.2
		"archive_house":
			generated_kind = "archive"
			generated_world_size = 7.1
		"wanderers_bazaar":
			generated_kind = "market"
			generated_world_size = 5.8
	var generated_sprite: Sprite3D = null
	if generated_kind in ["workshop", "archive"]:
		generated_sprite = _player_structure_hero_sprite(generated_kind, 0, generated_world_size)
	elif generated_kind == "market":
		generated_sprite = _add_prop_sprite("market", Vector3.ZERO, generated_world_size, false)
	if generated_sprite != null:
		generated_sprite.name = "GeneratedAPlusCLandmark"
		generated_sprite.reparent(root, false)
		generated_sprite.position = Vector3.ZERO
		generated_sprite.rotation = Vector3.ZERO
		generated_sprite.set_meta("canonical_landmark_art", true)
		root.set_meta("presentation_mode", "generated_a_plus_c_cutout")
	else:
		root.set_meta("presentation_mode", "missing_generated_cutout")
	# The original source node stays in the district for world-loop compatibility,
	# but it is never allowed to become a second visible presentation root.
	source.visible = false
	canonical_landmark_roots[str(definition.get("id", ""))] = root

func _build_environment_framing() -> void:
	# The environment sheet gives the scene a consistent illustrated silhouette
	# language instead of mixing flat primitives with imported low-poly trees.
	for obstacle_value in SanctuaryAssetCatalog.FRAMING_OBSTACLES:
		if not (obstacle_value is Dictionary):
			continue
		var obstacle: Dictionary = obstacle_value
		var position_data: Array = obstacle.get("position", [])
		if position_data.size() < 3:
			continue
		var obstacle_position := Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))
		var obstacle_size := float(obstacle.get("world_size", 0.0))
		var sprite_index := int(obstacle.get("sprite_index", 0))
		var obstacle_kind := str(obstacle.get("kind", ""))
		var shadow_size := Vector2(obstacle_size * (0.58 if obstacle_kind == "tree" else 0.60), obstacle_size * (0.22 if obstacle_kind == "tree" else 0.22))
		_add_contact_shadow(self, Vector3(obstacle_position.x, 0.084, obstacle_position.z + (0.12 if obstacle_kind == "tree" else 0.08)), shadow_size, obstacle_position.x * (1.7 if obstacle_kind == "tree" else 0.0) + obstacle_position.z * (0.0 if obstacle_kind == "tree" else 2.0))
		var obstacle_sprite := _add_environment_sprite(sprite_index, obstacle_position, obstacle_size, 0.22 if obstacle_kind == "tree" else 0.1)
		_attach_measured_visual_collision(obstacle_sprite, obstacle_kind)
	_add_contact_shadow(self, Vector3(-11.0, 0.084, 4.9), Vector2(2.2, 0.7), 8.0)
	_add_environment_sprite(4, Vector3(-11.0, 0.10, 4.8), 3.1, 0.35)
	_add_contact_shadow(self, Vector3(10.9, 0.084, 4.3), Vector2(2.1, 0.7), -7.0)
	_add_environment_sprite(4, Vector3(10.9, 0.10, 4.2), 3.0, 0.9)
	_add_contact_shadow(self, Vector3(9.0, 0.083, 0.52), Vector2(3.4, 1.35), 0.0)
	_add_environment_sprite(5, Vector3(9.0, 0.10, 0.4), 4.1, 0.0)

func _build_lived_in_activity() -> void:
	# This ring is the visible bridge between a fresh save and a player-authored
	# settlement. It adds believable work/life beats around the open reserve while
	# keeping the reserve itself empty and freely placeable. Every socket is a
	# presentation root only: no StaticBody3D, occupancy claim, or gameplay id is
	# created here.
	lived_in_activity_root = Node3D.new()
	lived_in_activity_root.name = "LivedInActivityLayer"
	lived_in_activity_root.set_meta("presentation_only", true)
	lived_in_activity_root.set_meta("collision_authority", "none")
	lived_in_activity_root.set_meta("occupancy_authority", "GameSession")
	add_child(lived_in_activity_root)
	for socket_value in SanctuaryAssetCatalog.LIVED_IN_ACTIVITY_SOCKETS:
		if not (socket_value is Dictionary):
			continue
		var socket := socket_value as Dictionary
		var position_data: Array = socket.get("position", [])
		if position_data.size() < 3:
			continue
		var kind := str(socket.get("kind", ""))
		var socket_id := str(socket.get("id", ""))
		var world_size := float(socket.get("world_size", 0.0))
		if kind.is_empty() or socket_id.is_empty() or world_size <= 0.0:
			continue
		var socket_position := Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))
		var sprite := _add_prop_sprite(kind, socket_position, world_size, bool(socket.get("animate", false)))
		if sprite == null:
			continue
		# `_add_prop_sprite` uses the same measured atlas path as all Sanctuary
		# presentation art. Reparenting keeps that exact feet pivot while giving
		# the complete activity ring a stable inspection root.
		sprite.reparent(lived_in_activity_root, false)
		sprite.name = "ActivitySocketArt_%s" % socket_id
		sprite.set_meta("activity_socket_id", socket_id)
		sprite.set_meta("activity_role", str(socket.get("role", "")))
		sprite.set_meta("presentation_only", true)
		sprite.set_meta("collision_layer", 0)
		sprite.set_meta("occupies_build_cells", false)
		var footprint_value: Variant = sprite.get_meta("visual_footprint", [])
		var footprint := Vector2(world_size * 0.62, world_size * 0.30)
		if footprint_value is Array and (footprint_value as Array).size() >= 2:
			var measured_footprint := footprint_value as Array
			footprint = Vector2(maxf(0.1, float(measured_footprint[0])), maxf(0.1, float(measured_footprint[1])))
		var shadow := _add_contact_shadow(
			lived_in_activity_root,
			Vector3(socket_position.x, 0.084, socket_position.z + 0.04),
			footprint * Vector2(1.12, 1.20),
			float(socket.get("ground_rotation_degrees", 0.0))
		)
		shadow.name = "ActivitySocketShadow_%s" % socket_id
		shadow.set_meta("activity_socket_id", socket_id)
		shadow.set_meta("presentation_only", true)
		shadow.set_meta("collision_layer", 0)
		shadow.set_meta("occupies_build_cells", false)

func _build_route_markers() -> void:
	# Route sockets stay legible as authored destinations, but their local
	# presentation now uses the same warm illustrated material language.
	for route_gate in get_tree().get_nodes_in_group("route_gate"):
		var gate := route_gate as Node3D
		if gate == null:
			continue
		var marker := _add_environment_sprite(4, gate.global_position + Vector3(0.0, 0.08, 0.0), 1.65, 0.0)
		marker.name = "RouteSocketLanternMarker"

func _build_ambient_lights() -> void:
	for data in [
		[Vector3(-6.4, 1.1, 2.2), Color("#ffd47a")],
		[Vector3(6.8, 1.1, 1.2), Color("#8edbd5")],
		[Vector3(-6.2, 1.1, 6.4), Color("#ffca76")],
	]:
		var light := OmniLight3D.new()
		light.name = "SanctuarySoftLantern"
		light.position = data[0]
		light.light_color = data[1]
		light.light_energy = 0.26
		light.omni_range = 2.6
		# These are small pools for authored 3D props/landmarks, not a second sun.
		# Their limited range keeps the soft illustrated ground from washing out.
		light.shadow_enabled = true
		add_child(light)

func _add_prop_sprite(kind: String, position: Vector3, world_size: float, animate: bool) -> Sprite3D:
	var sprite := _sprite_from_sheet(prop_sheet, int(build_sprite_regions.get(kind, 0)), position, world_size)
	if sprite == null:
		return null
	sprite.name = "Illustrated_%s" % kind.capitalize()
	if animate:
		pulsing_nodes.append({"node": sprite, "phase": position.x * 0.17 + position.z * 0.11, "strength": 0.018, "base_scale": sprite.scale})
	return sprite

func _add_environment_sprite(index: int, position: Vector3, world_size: float, phase: float) -> Sprite3D:
	var sprite := _sprite_from_sheet(environment_sheet, index, position, world_size)
	if sprite == null:
		return null
	sprite.name = "IllustratedEnvironment_%d" % index
	if index in [0, 1, 2]:
		swaying_nodes.append({"node": sprite, "phase": phase + position.x * 0.21, "amplitude": 0.025, "base_scale": sprite.scale})
	return sprite

func _fire_sprite_from_sheet(position: Vector3, world_size: float) -> Sprite3D:
	if prop_sheet == null:
		return null
	# Bottom-right cell of settlement-props-sheet.png contains the well and a
	# separate fire. Crop the fire half into its own atlas region so the two
	# activities can be placed independently while sharing the same authored
	# illustration language.
	var atlas := AtlasTexture.new()
	atlas.atlas = prop_sheet
	atlas.region = Rect2(760.0, 1031.0, 264.0, 498.0)
	atlas.filter_clip = true
	var opaque_bounds := Rect2i(34, 177, 225, 260)
	var sprite := Sprite3D.new()
	sprite.texture = atlas
	sprite.centered = false
	var transparent_bottom := float(maxi(0, int(atlas.region.size.y) - opaque_bounds.position.y - opaque_bounds.size.y))
	sprite.offset = Vector2(-(float(opaque_bounds.position.x) + float(opaque_bounds.size.x) * 0.5), -transparent_bottom)
	sprite.pixel_size = world_size / float(opaque_bounds.size.y)
	sprite.position = position
	sprite.axis = Vector3.AXIS_Z
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.shaded = true
	sprite.material_override = _structure_sprite_material(atlas)
	sprite.no_depth_test = false
	sprite.sorting_use_aabb_center = false
	sprite.sorting_offset = 0.0
	_set_sprite_contract_metadata(sprite, {"asset_id": "settlement_props/fire", "footprint_ratio": Vector2(0.86, 0.38)}, opaque_bounds, world_size)
	add_child(sprite)
	return sprite

func _player_structure_sprite_from_sheet(kind: String, world_size: float) -> Sprite3D:
	if player_structure_sheet == null or not PLAYER_STRUCTURE_ASSET_PROFILES.has(kind):
		return null
	var profile: Dictionary = PLAYER_STRUCTURE_ASSET_PROFILES.get(kind, {})
	var sheet_index := int(profile.get("sheet_index", -1))
	if sheet_index < 0 or sheet_index > 5:
		return null
	var column := sheet_index % 2
	var row := sheet_index / 2
	var atlas := AtlasTexture.new()
	atlas.atlas = player_structure_sheet
	# The generated sheet has a thin white cell divider. The inset keeps that
	# divider out of the atlas region while retaining the full isolated artwork.
	atlas.region = Rect2(
		float(column) * PLAYER_STRUCTURE_CELL_SIZE + PLAYER_STRUCTURE_CELL_INSET,
		float(row) * PLAYER_STRUCTURE_CELL_SIZE + PLAYER_STRUCTURE_CELL_INSET,
		PLAYER_STRUCTURE_CELL_EXTENT,
		PLAYER_STRUCTURE_CELL_EXTENT
	)
	atlas.filter_clip = true
	var opaque_bounds: Rect2i = profile.get("opaque_bounds", Rect2i(24, 24, 450, 450))
	var opaque_width := maxi(1, opaque_bounds.size.x)
	var opaque_height := maxi(1, opaque_bounds.size.y)
	var sprite := Sprite3D.new()
	sprite.texture = atlas
	sprite.centered = false
	var transparent_bottom := float(maxi(0, int(atlas.region.size.y) - opaque_bounds.position.y - opaque_height))
	sprite.offset = Vector2(
		-(float(opaque_bounds.position.x) + float(opaque_width) * 0.5),
		-transparent_bottom
	)
	sprite.pixel_size = maxf(0.01, world_size) / float(opaque_height)
	sprite.position = Vector3.ZERO
	sprite.axis = Vector3.AXIS_Z
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.shaded = true
	sprite.material_override = _structure_sprite_material(atlas)
	sprite.no_depth_test = false
	sprite.sorting_use_aabb_center = false
	sprite.sorting_offset = 0.0
	_set_sprite_contract_metadata(sprite, profile, opaque_bounds, maxf(0.01, world_size))
	sprite.set_meta("player_structure_art_kind", kind)
	sprite.set_meta("player_structure_sheet_cell", sheet_index)
	add_child(sprite)
	return sprite

func _structure_sprite_material(texture: Texture2D) -> ShaderMaterial:
	if structure_sprite_material == null or texture == null:
		return null
	var material := structure_sprite_material.duplicate() as ShaderMaterial
	material.set_shader_parameter("albedo_texture", texture)
	material.set_shader_parameter("base_color", Color.WHITE)
	return material

func _configure_construction_sprite_shader(sprite: Sprite3D, kind: String, state: String, progress: float) -> void:
	if sprite == null:
		return
	var material := sprite.material_override as ShaderMaterial
	if material == null:
		return
	var is_blueprint := state == "blueprint"
	var outline_color := Color("#72f4d0")
	var fill_color := Color("#d5ddb5")
	if kind == "rain_cistern":
		outline_color = Color("#8de7e6")
		fill_color = Color("#c7e1cf")
	material.set_shader_parameter("construction_mode", 1 if is_blueprint else 2)
	material.set_shader_parameter("construction_progress", 0.0 if is_blueprint else clampf(progress, 0.0, 1.0))
	material.set_shader_parameter("construction_outline_color", outline_color)
	material.set_shader_parameter("construction_fill_color", fill_color)
	material.set_shader_parameter("construction_grid_color", outline_color.lightened(0.08))
	material.set_shader_parameter("construction_outline_strength", 0.92)
	material.set_shader_parameter("construction_grid_scale", 10.0)
	sprite.set_meta("construction_shader_contract", "authored_silhouette_reveal_v1")
	sprite.set_meta("construction_shader_mode", "blueprint" if is_blueprint else "material_reveal")
	sprite.set_meta("construction_shader_progress", 0.0 if is_blueprint else clampf(progress, 0.0, 1.0))

func _player_structure_hero_sprite(kind: String, rotation_quarter_turns: int, world_size: float) -> Sprite3D:
	# Every production facility uses this measured cutout constructor. Directional
	# records resolve through the catalog; no sprite is rotated in metadata and no
	# facility can silently inherit Workshop art.
	var variant := SanctuaryAssetCatalog.structure_directional_variant(kind, rotation_quarter_turns)
	var asset_path := str(variant.get("asset_path", ""))
	if asset_path.is_empty() or not ResourceLoader.exists(asset_path):
		return null
	var texture := load(asset_path) as Texture2D
	if texture == null:
		return null
	var image := texture.get_image()
	if image == null:
		return null
	var opaque_bounds := image.get_used_rect()
	if opaque_bounds.size.x <= 0 or opaque_bounds.size.y <= 0:
		return null
	var opaque_width := maxi(1, opaque_bounds.size.x)
	var opaque_height := maxi(1, opaque_bounds.size.y)
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(0.0, 0.0, float(image.get_width()), float(image.get_height()))
	atlas.filter_clip = true
	var sprite := Sprite3D.new()
	sprite.texture = atlas
	sprite.centered = false
	var transparent_bottom := float(maxi(0, image.get_height() - opaque_bounds.position.y - opaque_height))
	sprite.offset = Vector2(
		-(float(opaque_bounds.position.x) + float(opaque_width) * 0.5),
		-transparent_bottom
	)
	sprite.pixel_size = maxf(0.01, world_size) / float(opaque_height)
	sprite.position = Vector3.ZERO
	sprite.axis = Vector3.AXIS_Z
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.shaded = true
	sprite.material_override = _structure_sprite_material(atlas)
	sprite.no_depth_test = false
	sprite.sorting_use_aabb_center = false
	sprite.sorting_offset = 0.0
	var profile := {
		"asset_id": str(variant.get("asset_id", "sanctuary/player_structures/%s/operational/q%d" % [kind, posmod(rotation_quarter_turns, 4)])),
		"footprint_ratio": Vector2(0.92, 0.56),
		"asset_path": asset_path,
	}
	_set_sprite_contract_metadata(sprite, profile, opaque_bounds, maxf(0.01, world_size))
	sprite.set_meta("player_structure_art_kind", kind)
	sprite.set_meta("directional_asset_path", asset_path)
	sprite.set_meta("directional_quarter_turn", posmod(rotation_quarter_turns, 4))
	sprite.set_meta("directional_family_world_height", maxf(0.01, world_size))
	sprite.set_meta("opaque_measurement_source", "texture_alpha_used_rect")
	add_child(sprite)
	return sprite

func _player_structure_stage_sprite(kind: String, stage_id: String, rotation_quarter_turns: int, world_size: float) -> Sprite3D:
	var asset_path := SanctuaryAssetCatalog.structure_construction_stage_asset(kind, stage_id, rotation_quarter_turns)
	if asset_path.is_empty() or not ResourceLoader.exists(asset_path):
		return null
	var texture := load(asset_path) as Texture2D
	if texture == null:
		return null
	var image := texture.get_image()
	if image == null:
		return null
	var opaque_bounds := image.get_used_rect()
	if opaque_bounds.size.x <= 0 or opaque_bounds.size.y <= 0:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(0.0, 0.0, float(image.get_width()), float(image.get_height()))
	atlas.filter_clip = true
	var sprite := Sprite3D.new()
	sprite.texture = atlas
	sprite.centered = false
	var opaque_width := maxi(1, opaque_bounds.size.x)
	var opaque_height := maxi(1, opaque_bounds.size.y)
	var transparent_bottom := float(maxi(0, image.get_height() - opaque_bounds.position.y - opaque_height))
	sprite.offset = Vector2(-(float(opaque_bounds.position.x) + float(opaque_width) * 0.5), -transparent_bottom)
	sprite.pixel_size = maxf(0.01, world_size) / float(opaque_height)
	sprite.position = Vector3.ZERO
	sprite.axis = Vector3.AXIS_Z
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.shaded = true
	sprite.material_override = _structure_sprite_material(atlas)
	sprite.no_depth_test = false
	sprite.sorting_use_aabb_center = false
	sprite.sorting_offset = 0.0
	var profile := {
		"asset_id": "sanctuary/player_structures/%s/construction/%s" % [kind, stage_id],
		"footprint_ratio": Vector2(0.92, 0.56),
		"asset_path": asset_path,
	}
	_set_sprite_contract_metadata(sprite, profile, opaque_bounds, maxf(0.01, world_size))
	sprite.set_meta("player_structure_art_kind", kind)
	sprite.set_meta("construction_stage", stage_id)
	sprite.set_meta("directional_asset_path", asset_path)
	sprite.set_meta("opaque_measurement_source", "texture_alpha_used_rect")
	sprite.set_meta("directional_family_world_height", maxf(0.01, world_size))
	add_child(sprite)
	return sprite

func _build_layered_workshop_construction(presentation: Node3D, structure: Node3D, state: String, data: Dictionary, footprint: Vector2, progress: float, rotation_quarter_turns: int) -> Sprite3D:
	# The authored construction kit is a real layer source, not a second full
	# building card. Every direction resolves its own kit so the child layers do
	# not inherit a mismatched silhouette from another camera-facing variant.
	if presentation == null or structure == null:
		return null
	var definition := SanctuaryAssetCatalog.structure_definition("workshop")
	var config: Dictionary = definition.get("layered_construction", {})
	var normalized_rotation := posmod(rotation_quarter_turns, 4)
	var directional_asset_paths: Dictionary = config.get("directional_asset_paths", {})
	var asset_path := str(directional_asset_paths.get(normalized_rotation, config.get("asset_path", "")))
	if asset_path.is_empty() or not ResourceLoader.exists(asset_path):
		return null
	var texture := load(asset_path) as Texture2D
	if texture == null:
		return null
	var source_image := texture.get_image()
	if source_image == null:
		return null
	var layers: Dictionary = config.get("layers", {})
	if layers.is_empty():
		return null
	var stage_id := "blueprint" if state == "blueprint" else _construction_stage_for_progress(progress)
	var active_layers: Array[String] = ["foundation"]
	if state == "building":
		if progress >= 0.10:
			active_layers.append("frame")
		if progress >= 0.50:
			active_layers.append("walls")
		if progress >= 0.76:
			active_layers.append("roof")
		if progress >= 0.88:
			active_layers.append("fittings")
	var first_sprite: Sprite3D = null
	var active_layer_ids: Array[String] = []
	var layer_sprites: Array[Sprite3D] = []
	for layer_id in active_layers:
		var layer_value: Variant = layers.get(layer_id, {})
		if not (layer_value is Dictionary):
			continue
		var layer: Dictionary = layer_value
		var region_data: Array = layer.get("region", [])
		if region_data.size() < 4:
			continue
		var region := Rect2i(int(region_data[0]), int(region_data[1]), int(region_data[2]), int(region_data[3]))
		var layer_sprite := _layered_workshop_sprite(source_image, region, layer_id, float(layer.get("world_height", 1.0)), asset_path)
		if layer_sprite == null:
			continue
		var position_data: Array = layer.get("position", [0.0, 0.0, 0.0])
		if position_data.size() >= 3:
			layer_sprite.position = Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))
		layer_sprite.render_priority = int(layer.get("render_priority", active_layer_ids.size()))
		layer_sprite.name = "IllustratedStateSprite" if first_sprite == null else "WorkshopConstructionLayer_%s" % layer_id
		layer_sprite.modulate = Color(0.42, 1.0, 0.94, 0.48) if state == "blueprint" else Color.WHITE
		layer_sprite.set_meta("construction_stage", stage_id)
		layer_sprite.set_meta("construction_layer", layer_id)
		layer_sprite.set_meta("layered_asset_path", asset_path)
		layer_sprite.set_meta("directional_asset_path", asset_path)
		layer_sprite.set_meta("directional_quarter_turns", normalized_rotation)
		layer_sprite.set_meta("opaque_measurement_source", "layer_region_texture_alpha_used_rect")
		layer_sprite.set_meta("presentation_only", true)
		layer_sprite.set_meta("collision_contributor", false)
		layer_sprite.set_meta("collision_presentation_contract", "traversable_construction_layer_until_operational")
		_set_structure_sprite_metadata(layer_sprite, structure, "workshop", state, "state" if first_sprite == null else "construction_layer_%s" % layer_id, footprint)
		presentation.add_child(layer_sprite)
		layer_sprites.append(layer_sprite)
		active_layer_ids.append(layer_id)
		if first_sprite == null:
			first_sprite = layer_sprite
	# Component sheets are authored independently, so their opaque extents can
	# differ by a few pixels between directions. Fit the complete measured layer
	# family to the same imported physical envelope used by the shell audit. This
	# is derived from alpha bounds and the structure measurement; no per-view
	# multiplier is stored in gameplay data.
	var rendered_width := 0.0
	for layer_sprite in layer_sprites:
		var visual_size: Array = layer_sprite.get_meta("visual_size", [])
		if visual_size.size() >= 1:
			rendered_width = maxf(rendered_width, float(visual_size[0]))
	var source_measurement: Dictionary = structure.get_meta("source_measurement", {})
	var fitted_size: Vector3 = source_measurement.get("fitted_size", Vector3.ZERO)
	var target_width := _measured_projected_horizontal_extent(structure, fitted_size) if fitted_size.length_squared() > 0.01 else rendered_width
	var layer_scale := maxf(1.0, target_width / rendered_width) if rendered_width > 0.01 else 1.0
	for layer_sprite in layer_sprites:
		if layer_scale <= 1.0:
			continue
		layer_sprite.position *= layer_scale
		layer_sprite.scale = Vector3.ONE * layer_scale
		var scaled_visual_size: Array = layer_sprite.get_meta("visual_size", [])
		if scaled_visual_size.size() >= 2:
			layer_sprite.set_meta("visual_size", [float(scaled_visual_size[0]) * layer_scale, float(scaled_visual_size[1]) * layer_scale])
	structure.set_meta("construction_art_source", "generated_workshop_layered_kit" if first_sprite != null else "")
	structure.set_meta("construction_art_asset_path", asset_path)
	structure.set_meta("construction_art_rotation", normalized_rotation)
	structure.set_meta("construction_art_scale", layer_scale)
	structure.set_meta("construction_art_stage", stage_id)
	structure.set_meta("construction_art_layers", active_layer_ids)
	return first_sprite

func _layered_workshop_sprite(source_image: Image, region: Rect2i, layer_id: String, world_height: float, asset_path: String) -> Sprite3D:
	if source_image == null or world_height <= 0.0:
		return null
	var clipped := Rect2i(
		clampi(region.position.x, 0, source_image.get_width() - 1),
		clampi(region.position.y, 0, source_image.get_height() - 1),
		clampi(region.size.x, 1, source_image.get_width() - region.position.x),
		clampi(region.size.y, 1, source_image.get_height() - region.position.y)
	)
	var region_image := source_image.get_region(clipped)
	var opaque_bounds := region_image.get_used_rect()
	if opaque_bounds.size.x <= 0 or opaque_bounds.size.y <= 0:
		return null
	var source_texture := ImageTexture.create_from_image(source_image)
	if source_texture == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = source_texture
	atlas.region = Rect2(float(clipped.position.x), float(clipped.position.y), float(clipped.size.x), float(clipped.size.y))
	atlas.filter_clip = true
	var sprite := Sprite3D.new()
	sprite.texture = atlas
	sprite.centered = false
	var transparent_bottom := float(maxi(0, region_image.get_height() - opaque_bounds.position.y - opaque_bounds.size.y))
	sprite.offset = Vector2(-(float(opaque_bounds.position.x) + float(opaque_bounds.size.x) * 0.5), -transparent_bottom)
	sprite.pixel_size = world_height / float(maxi(1, opaque_bounds.size.y))
	sprite.axis = Vector3.AXIS_Z
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.shaded = true
	sprite.material_override = _structure_sprite_material(atlas)
	sprite.no_depth_test = false
	sprite.sorting_use_aabb_center = false
	sprite.sorting_offset = 0.0
	var profile := {
		"asset_id": "sanctuary/player_structures/workshop/construction/layer/%s" % layer_id,
		"footprint_ratio": Vector2(0.92, 0.56),
		"asset_path": asset_path,
	}
	_set_sprite_contract_metadata(sprite, profile, opaque_bounds, world_height)
	sprite.set_meta("layer_id", layer_id)
	sprite.set_meta("layer_texture_size", [region_image.get_width(), region_image.get_height()])
	return sprite

func _refresh_tracked_sprite_base_scale(sprite: Sprite3D) -> void:
	for sway_data in swaying_nodes:
		if sway_data.get("node") == sprite:
			sway_data["base_scale"] = sprite.scale
	for pulse_data in pulsing_nodes:
		if pulse_data.get("node") == sprite:
			pulse_data["base_scale"] = sprite.scale

func _sprite_from_sheet(sheet: Texture2D, index: int, position: Vector3, world_size: float) -> Sprite3D:
	if sheet == null:
		return null
	var profile := _sprite_profile(sheet, index)
	var atlas := AtlasTexture.new()
	var cell_width := CELL_SIZE
	var cell_height := CELL_SIZE
	var cell_inset := CELL_INSET
	var region_width := CELL_EXTENT
	var region_height := CELL_EXTENT
	if sheet == environment_sheet:
		cell_width = ENVIRONMENT_CELL_WIDTH
		cell_height = ENVIRONMENT_CELL_HEIGHT
		cell_inset = ENVIRONMENT_CELL_INSET
		region_width = ENVIRONMENT_CELL_WIDTH_INSET
		region_height = ENVIRONMENT_CELL_HEIGHT_INSET
	var column := index % 2
	var row := index / 2
	atlas.atlas = sheet
	atlas.region = Rect2(float(column) * cell_width + cell_inset, float(row) * cell_height + cell_inset, region_width, region_height)
	atlas.filter_clip = true
	var fallback_bounds := Rect2i(0, 0, maxi(1, int(region_width)), maxi(1, int(region_height)))
	var opaque_bounds: Rect2i = profile.get("opaque_bounds", fallback_bounds)
	var opaque_width := maxi(1, opaque_bounds.size.x)
	var opaque_height := maxi(1, opaque_bounds.size.y)
	var visible_world_height := maxf(0.01, world_size)
	var sprite := Sprite3D.new()
	sprite.texture = atlas
	# SpriteBase3D uses pixel-space offsets. With centering disabled, the draw
	# rectangle begins at `offset`; X recentres the measured opaque artwork and
	# Y removes the transparent pixels below it. The visible base is therefore
	# exactly local Vector3.ZERO while the artwork extends upward from the node.
	sprite.centered = false
	var opaque_center_x := float(opaque_bounds.position.x) + float(opaque_width) * 0.5
	var transparent_bottom := float(maxi(0, int(region_height) - opaque_bounds.position.y - opaque_height))
	sprite.offset = Vector2(-opaque_center_x, -transparent_bottom)
	sprite.pixel_size = visible_world_height / float(opaque_height)
	sprite.position = position
	sprite.axis = Vector3.AXIS_Z
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.shaded = false
	sprite.no_depth_test = false
	# VisualInstance3D position sorting is a supported Godot 4.7 property. Since
	# the node origin is the measured ground pivot, disabling AABB-centre sorting
	# makes overlapping transparent billboards sort from their feet/base.
	sprite.sorting_use_aabb_center = false
	sprite.sorting_offset = 0.0
	_set_sprite_contract_metadata(sprite, profile, opaque_bounds, visible_world_height)
	add_child(sprite)
	return sprite

func _sprite_profile(sheet: Texture2D, index: int) -> Dictionary:
	var profiles: Array = ENVIRONMENT_ASSET_PROFILES if sheet == environment_sheet else PROP_ASSET_PROFILES
	if index >= 0 and index < profiles.size():
		return profiles[index]
	return {
		"asset_id": "environment/unknown_%d" % index if sheet == environment_sheet else "settlement_props/unknown_%d" % index,
		"footprint_ratio": Vector2.ONE,
	}

func _attach_measured_visual_collision(sprite: Sprite3D, visual_kind: String) -> StaticBody3D:
	if sprite == null:
		return null
	var footprint_value: Variant = sprite.get_meta("visual_footprint", [])
	var visual_size_value: Variant = sprite.get_meta("visual_size", [])
	if not (footprint_value is Array) or footprint_value.size() < 2 or not (visual_size_value is Array) or visual_size_value.size() < 2:
		return null
	var footprint_width := float(footprint_value[0])
	var footprint_depth := float(footprint_value[1])
	var visual_height := float(visual_size_value[1])
	if footprint_width <= 0.0 or footprint_depth <= 0.0 or visual_height <= 0.0:
		return null
	# The obstacle is derived from the measured opaque artwork envelope, but only
	# occupies the foot-bearing portion. Canopies remain visual volume and do not
	# become invisible walls above the player's readable traversal height.
	var collision_height := maxf(0.08, minf(visual_height * 0.24, visual_height - 0.01))
	var body := StaticBody3D.new()
	body.name = "MeasuredFramingCollision"
	body.position = Vector3(0.0, collision_height * 0.5, 0.0)
	body.collision_layer = 1
	body.collision_mask = 1
	body.set_meta("asset_id", str(sprite.get_meta("asset_id", "")))
	body.set_meta("measurement_source", "sprite_opaque_bounds_visual_footprint")
	body.set_meta("visual_kind", visual_kind)
	body.set_meta("measured_footprint", [footprint_width, footprint_depth])
	var collision := CollisionShape3D.new()
	collision.name = "MeasuredFramingHitbox"
	var shape := BoxShape3D.new()
	shape.size = Vector3(footprint_width, collision_height, footprint_depth)
	collision.shape = shape
	collision.set_meta("asset_id", str(sprite.get_meta("asset_id", "")))
	collision.set_meta("measurement_source", "sprite_opaque_bounds_visual_footprint")
	collision.set_meta("visual_footprint", [footprint_width, footprint_depth])
	body.add_child(collision)
	sprite.add_child(body)
	return body

func _set_sprite_contract_metadata(sprite: Sprite3D, profile: Dictionary, opaque_bounds: Rect2i, visible_world_height: float) -> void:
	var footprint_ratio: Vector2 = profile.get("footprint_ratio", Vector2.ONE)
	var visual_footprint := Vector2(
		maxf(0.01, visible_world_height * footprint_ratio.x),
		maxf(0.01, visible_world_height * footprint_ratio.y)
	)
	var visible_world_width := float(maxi(1, opaque_bounds.size.x)) * sprite.pixel_size
	sprite.set_meta("asset_id", str(profile.get("asset_id", "unknown")))
	sprite.set_meta("ground_pivot", [0.0, 0.0, 0.0])
	sprite.set_meta("visual_footprint", [visual_footprint.x, visual_footprint.y])
	sprite.set_meta("sorting_anchor", [0.0, 0.0, 0.0])
	# Additional fields make the units and coordinate space unambiguous to
	# capture tools without turning presentation data into gameplay authority.
	sprite.set_meta("sorting_anchor_mode", "feet")
	sprite.set_meta("sorting_anchor_space", "sprite_local")
	sprite.set_meta("visual_size", [visible_world_width, visible_world_height])
	sprite.set_meta("visual_units", "world_meters")
	sprite.set_meta("source_opaque_bounds", [opaque_bounds.position.x, opaque_bounds.position.y, opaque_bounds.size.x, opaque_bounds.size.y])

func set_placement_preview(center: Vector3, footprint: Vector2i, valid: bool, rotation_quarter_turns: int, active: bool, structure_kind := "") -> void:
	placement_active = active
	if grid_root != null:
		grid_root.visible = active
	if preview_root == null:
		return
	preview_root.visible = active
	if not active:
		_clear_placement_preview_art()
		return
	placement_center = center
	placement_footprint = Vector2i(maxi(1, footprint.x), maxi(1, footprint.y))
	placement_rotation = posmod(rotation_quarter_turns, 4)
	placement_valid = valid
	preview_root.position = center + Vector3(0.0, 0.08, 0.0)
	preview_root.rotation.y = float(placement_rotation) * PI * 0.5
	# `footprint` is the world/grid footprint already resolved by Main. The
	# preview root owns the quarter-turn, so its child meshes must stay in the
	# authored local dimensions. The old code used the already-swapped world
	# footprint and then rotated the root again, making 90°/270° previews visibly
	# disagree with the occupied cells and the placed collision shell.
	var local_footprint := placement_footprint
	if placement_rotation % 2 == 1:
		local_footprint = Vector2i(placement_footprint.y, placement_footprint.x)
	var width := float(local_footprint.x)
	var depth := float(local_footprint.y)
	preview_root.set_meta("grid_footprint", [placement_footprint.x, placement_footprint.y])
	preview_root.set_meta("local_footprint", [local_footprint.x, local_footprint.y])
	preview_root.set_meta("rotation_quarter_turns", placement_rotation)
	preview_root.set_meta("presentation_only", true)
	preview_root.set_meta("collision_layer", 0)
	if preview_fill != null:
		var fill_mesh := preview_fill.mesh as BoxMesh
		if fill_mesh != null:
			fill_mesh.size = Vector3(width, 0.035, depth)
		preview_fill.position.y = 0.018
		var fill_color: Color = PALETTE["grid_valid"] if valid else PALETTE["grid_blocked"]
		fill_color.a = 0.12
		preview_fill.material_override = _soft_material(fill_color, true, true)
	if preview_outline != null:
		var edge_specs := [
			[Vector3(0.0, 0.035, -depth * 0.5), Vector3(width, 0.075, 0.075)],
			[Vector3(0.0, 0.035, depth * 0.5), Vector3(width, 0.075, 0.075)],
			[Vector3(-width * 0.5, 0.035, 0.0), Vector3(0.075, 0.075, depth)],
			[Vector3(width * 0.5, 0.035, 0.0), Vector3(0.075, 0.075, depth)],
		]
		for index in mini(4, preview_outline.get_child_count()):
			var edge := preview_outline.get_child(index) as MeshInstance3D
			if edge == null:
				continue
			var edge_mesh := edge.mesh as BoxMesh
			if edge_mesh == null:
				continue
			edge_mesh.size = edge_specs[index][1]
			edge.position = edge_specs[index][0]
			edge.material_override = _soft_material(PALETTE["grid_valid"] if valid else PALETTE["grid_blocked"], true, true)
	_refresh_placement_preview_art(structure_kind)

func _refresh_placement_preview_art(structure_kind: String) -> void:
	if preview_root == null or structure_kind.is_empty():
		_clear_placement_preview_art()
		return
	var normalized_rotation := placement_rotation
	if preview_art != null and is_instance_valid(preview_art) and preview_art_kind == structure_kind and preview_art_rotation == normalized_rotation:
		preview_art.modulate = Color(0.38, 1.0, 0.82, 0.72) if placement_valid else Color(1.0, 0.32, 0.34, 0.68)
		return
	_clear_placement_preview_art()
	var stage_sprite := _player_structure_stage_sprite(structure_kind, "blueprint", normalized_rotation, _structure_world_size(structure_kind))
	var preview_source := "construction_blueprint"
	if stage_sprite == null:
		# Pen and cistern currently have complete operational direction families
		# while their dedicated construction sheets are still being authored. Use
		# their own measured hero silhouette as a translucent blueprint rather than
		# falling back to another building's art or a generic prop card.
		stage_sprite = _player_structure_hero_sprite(structure_kind, normalized_rotation, _structure_world_size(structure_kind))
		preview_source = "operational_silhouette_fallback"
	if stage_sprite == null:
		# A missing authored family must not silently become a generic prop card.
		# The rectangular measured footprint remains visible and the missing-art
		# metadata makes the issue inspectable in QA.
		preview_root.set_meta("preview_art_missing", true)
		return
	stage_sprite.name = "PreviewStructureSilhouette"
	stage_sprite.reparent(preview_root)
	stage_sprite.position = Vector3(0.0, 0.055, 0.0)
	stage_sprite.modulate = Color(0.38, 1.0, 0.82, 0.72) if placement_valid else Color(1.0, 0.32, 0.34, 0.68)
	# The placement ghost is a readability layer, not a final lit asset. Use the
	# Sprite3D's native alpha material here so its authored silhouette remains
	# visible above the translucent footprint fill; placed/building art continues
	# to use the Sanctuary toon shader.
	stage_sprite.material_override = null
	stage_sprite.render_priority = 2
	stage_sprite.set_meta("presentation_only", true)
	stage_sprite.set_meta("collision_layer", 0)
	stage_sprite.set_meta("preview_structure_kind", structure_kind)
	stage_sprite.set_meta("preview_rotation_quarter_turns", normalized_rotation)
	stage_sprite.set_meta("preview_art_source", preview_source)
	preview_art = stage_sprite
	preview_art_kind = structure_kind
	preview_art_rotation = normalized_rotation
	preview_root.set_meta("preview_art_missing", false)

func _clear_placement_preview_art() -> void:
	if preview_art != null and is_instance_valid(preview_art):
		# This is a single presentation child owned by the preview root. Free it
		# immediately so the next quarter-turn can retain the stable node name;
		# queue_free leaves a same-named child alive for the rest of the frame and
		# makes valid rotated captures look like missing art.
		preview_art.free()
	preview_art = null
	preview_art_kind = ""
	preview_art_rotation = -1

func apply_structure_visual(structure: Node3D, kind: String, state: String, data: Dictionary) -> void:
	if structure == null:
		return
	# Refreshes replace the complete presentation layer. Remove motion records
	# for freed presentation children first so repeated save/load or delivery
	# refreshes cannot grow an unbounded animation list.
	for motion_index in range(activity_motion_nodes.size() - 1, -1, -1):
		var motion_node: Variant = activity_motion_nodes[motion_index].get("node")
		if not is_instance_valid(motion_node) or (motion_node as Node3D).get_parent() == null:
			activity_motion_nodes.remove_at(motion_index)
	for worker_index in range(construction_worker_nodes.size() - 1, -1, -1):
		var worker_node: Variant = construction_worker_nodes[worker_index].get("node")
		if not is_instance_valid(worker_node) or (worker_node as Node3D).get_parent() == null:
			construction_worker_nodes.remove_at(worker_index)
	var presentation := structure.get_node_or_null("IllustratedStructurePresentation") as Node3D
	if presentation == null:
		presentation = Node3D.new()
		presentation.name = "IllustratedStructurePresentation"
		structure.add_child(presentation)
	# Refreshes happen synchronously while the authoritative structure state is
	# being reconciled. Free the old layers now instead of queueing them: queued
	# children keep their names reserved for the rest of the frame, which makes
	# Godot auto-rename the replacement to @Sprite3D@N and breaks inspection,
	# animation hooks, and stable hitbox/asset tooling.
	for child in presentation.get_children():
		child.free()
	# StructureUtility contains the systems prototype's free-standing 3D forge,
	# chimney, shelves, trough, crates, and loading frame. Those meshes remain
	# useful gameplay hooks (the main loop can keep animating them), but rendering
	# them over a complete illustrated state sprite produces dark vertical prisms
	# and floating squares whenever the billboard is depth-sorted behind foliage.
	# Hide only that per-structure root's render descendants. The root itself
	# keeps the operational visibility contract used by system/animation hooks.
	# Canonical landmarks such as the authored hearth/well, fire light, pond, and
	# route lanterns live outside the structure and remain visible; collision and
	# interaction bodies are separate nodes and are never traversed here.
	var measured_3d_source := structure.get_node_or_null("FinishedSourceBuilding/ImportedBuilding") as Node3D
	var structure_definition := SanctuaryAssetCatalog.structure_definition(kind)
	var directional_art_required := bool(structure_definition.get("directional_art_required", false))
	var use_measured_3d_art := state == "operational" and str(structure_definition.get("operational_art_mode", "illustrated_2_5d")) == "measured_3d" and bool(structure.get_meta("source_measurement_valid", false)) and measured_3d_source != null
	var use_player_structure_art := state == "operational" and not use_measured_3d_art and player_structure_sheet != null and PLAYER_STRUCTURE_ASSET_PROFILES.has(kind)
	var rotation_quarter_turns := int(structure.get_meta("rotation_quarter_turns", 0))
	var shader_construction := (state == "blueprint" or state == "building") and not directional_art_required and SanctuaryAssetCatalog.structure_construction_stage_asset(kind, "blueprint", rotation_quarter_turns).is_empty()
	var hide_names := [
		"CisternBase",
		"CisternTank",
		"CisternRoof",
		"GabledRoof",
		"TimberFrame",
		"FinishedWalls",
		"FinishedSourceBuilding",
		"ConstructionWalls",
		"ConstructionRoof",
		"ScaffoldFrame",
	]
	if shader_construction:
		# Livestock Pen and Rain Cistern use their own measured directional hero
		# silhouette with the construction shader. Hide only the old procedural
		# render descendants; the authoritative compound collision, material
		# ledger, and interaction roots remain alive for gameplay and QA.
		hide_names.append_array([
			"CisternTank",
			"CisternRoof",
			"AdditiveConstructionComponents",
			"DeliveredLogs",
			"DeliveredStone",
			"DeliveredPlanks",
			"DeliveredFiber",
		])
	for node_name in hide_names:
		# Building states keep their additive foundation/frame/wall/roof/fitting
		# meshes visible; these are the material-driven construction proof. The
		# finished source scene is likewise retained when it is the unique
		# operational asset for this structure kind.
		if state == "building" and not shader_construction and node_name in ["CisternBase", "ConstructionWalls", "ConstructionRoof", "ScaffoldFrame"]:
			continue
		if state == "operational" and node_name == "FinishedSourceBuilding" and not use_player_structure_art:
			continue
		var old_node := structure.get_node_or_null(node_name) as Node3D
		if old_node != null:
			old_node.visible = false
	var utility := structure.get_node_or_null("StructureUtility") as Node3D
	if utility != null:
		utility.visible = state == "operational" and kind != "rain_cistern"
		_hide_render_tree(utility)
		utility.set_meta("illustrated_render_descendants_hidden", true)
	if directional_art_required and (state == "blueprint" or state == "building"):
		# The authored stage cutout is the complete player-facing silhouette. Keep
		# legacy construction roots alive for gameplay/QA metadata, but hide their
		# mesh descendants so beams, slabs, and delivered bundles cannot double-render
		# beneath the directional asset.
		for construction_root_name in ["ScaffoldFrame", "ConstructionWalls", "ConstructionRoof", "AdditiveConstructionComponents", "DeliveredLogs", "DeliveredStone", "DeliveredPlanks", "DeliveredFiber"]:
			var construction_root := structure.get_node_or_null(construction_root_name) as Node3D
			if construction_root == null:
				continue
			_hide_render_tree(construction_root)
			construction_root.set_meta("directional_stage_render_hidden", true)
	var sprite_kind := "scaffold"
	var modulation := Color(0.36, 1.0, 0.94, 0.38)
	var build_progress := _construction_progress(data) if state == "building" else 0.0
	if state == "building":
		sprite_kind = "scaffold"
		# Keep the same ground-pivoted scaffold asset through the full build, but
		# make the phase readable at a glance: raw timber early, framed mint in
		# the middle, and a warm near-finished shell late.
		if build_progress < 0.34:
			modulation = Color("#d08b55")
		elif build_progress < 0.76:
			modulation = Color("#d9e4bd")
		else:
			modulation = Color("#f2d9a0")
	elif state == "operational":
		match kind:
			"workshop": sprite_kind = "workshop"
			"archive": sprite_kind = "workshop"
			"storage_shed": sprite_kind = "tent"
			"livestock_pen": sprite_kind = "garden"
			"rain_cistern": sprite_kind = "well"
		modulation = Color.WHITE
	var structure_footprint := _structure_local_visual_footprint(structure, data, _structure_world_size(kind))
	var cell_index := int(build_sprite_regions.get(sprite_kind, 0))
	var sprite: Sprite3D = null
	var measured_hero_world_size := _measured_hero_world_size(structure, kind, rotation_quarter_turns)
	var directional_stage_art := false
	var layered_construction_art := false
	var construction_hero_overlay := false
	if not use_measured_3d_art:
		if state == "blueprint" or state == "building":
			var stage_id := "blueprint" if state == "blueprint" else _construction_stage_for_progress(build_progress)
			if kind == "workshop":
				sprite = _build_layered_workshop_construction(presentation, structure, state, data, structure_footprint, build_progress, rotation_quarter_turns)
				layered_construction_art = sprite != null
			if not layered_construction_art:
				var stage_asset_path := SanctuaryAssetCatalog.structure_construction_stage_asset(kind, stage_id, rotation_quarter_turns)
				var stage_world_size := _measured_stage_family_world_size(structure, kind, stage_id, measured_hero_world_size)
				sprite = _player_structure_stage_sprite(kind, stage_id, rotation_quarter_turns, stage_world_size)
				directional_stage_art = sprite != null
		if sprite == null and use_player_structure_art and not (directional_art_required and (state == "blueprint" or state == "building")):
			sprite = _player_structure_hero_sprite(kind, rotation_quarter_turns, measured_hero_world_size)
		if sprite == null and (state == "blueprint" or state == "building") and not directional_art_required:
			# Facilities without a dedicated stage family still use their own measured
			# directional silhouette as a low-alpha phase envelope. This is materially
			# different from showing a generic garden/well card: the player can read
			# the actual Pen or Cistern being assembled, while the ledger-driven
			# construction components remain the visible progress authority.
			sprite = _player_structure_hero_sprite(kind, rotation_quarter_turns, measured_hero_world_size)
			construction_hero_overlay = sprite != null
		if sprite == null and not directional_art_required:
			sprite = _player_structure_sprite_from_sheet(kind, _structure_world_size(kind))
		if sprite == null and directional_art_required:
			structure.set_meta("visual_art_missing", true)
		else:
			structure.set_meta("visual_art_missing", false)
		if sprite == null and not directional_art_required:
			sprite = _sprite_from_sheet(prop_sheet, cell_index, Vector3.ZERO, _structure_world_size(kind))
		if sprite != null:
			if not layered_construction_art:
				sprite.name = "IllustratedStateSprite"
			sprite.reparent(presentation)
			sprite.position = Vector3.ZERO
			if not layered_construction_art:
				if construction_hero_overlay:
					if state == "blueprint":
						# Blueprint presentation is still the primary state layer. The
						# shader supplies the ghost/outline treatment without changing
						# the asset contract expected by placement and save/reload QA.
						sprite.modulate = Color(1.0, 1.0, 1.0, 0.34)
						sprite.render_priority = -1
						_set_structure_sprite_metadata(sprite, structure, kind, state, "state", structure_footprint)
					else:
						var phase_alpha := lerpf(0.16, 0.74, clampf(build_progress, 0.0, 1.0))
						sprite.modulate = Color(1.0, 1.0, 1.0, phase_alpha)
						sprite.render_priority = -1
						sprite.set_meta("construction_phase_overlay", true)
						sprite.set_meta("construction_phase_progress", build_progress)
						_set_structure_sprite_metadata(sprite, structure, kind, state, "construction_phase_overlay", structure_footprint)
					_configure_construction_sprite_shader(sprite, kind, state, build_progress)
				else:
					sprite.modulate = Color(1.0, 1.0, 1.0, 0.46) if directional_stage_art and state == "blueprint" else modulation
					_set_structure_sprite_metadata(sprite, structure, kind, state, "state", structure_footprint)
		if layered_construction_art:
			structure.set_meta("operational_art_source", "generated_workshop_layered_construction")
			structure.set_meta("visual_art_missing", false)
		elif directional_stage_art:
			structure.set_meta("operational_art_source", "generated_%s_construction_stage" % kind)
		elif use_player_structure_art and sprite != null:
			# The generated cutout is the single opaque operational silhouette. The
			# imported kit remains instantiated for provenance and future directional
			# replacement, but its render tree is hidden so the art never double-renders.
			structure.set_meta("operational_art_source", "generated_player_structure_directional" if sprite.has_meta("directional_asset_path") else "generated_player_structure")
			structure.set_meta("operational_visual_world_height", measured_hero_world_size)
		elif construction_hero_overlay:
			structure.set_meta("operational_art_source", "generated_construction_hero_overlay")
		elif directional_art_required and sprite == null:
			structure.set_meta("operational_art_source", "missing_required_art")
		elif state == "operational":
			structure.set_meta("operational_art_source", "sourced_or_sheet_fallback")
		else:
			structure.set_meta("operational_art_source", "sourced_or_sheet_fallback")
		# Archive's construction kit intentionally carries the timber frame and
		# blueprint shell in one coherent silhouette. As the authoritative material
		# ledger crosses the wall and roof milestones, reveal the same archive's
		# measured hero art underneath it. This keeps the build readable without
		# pretending that a generic scaffold is the archive, and without changing
		# the collision/occupancy authority.
		if kind == "archive" and state == "building" and directional_stage_art:
			_add_archive_construction_phase_overlay(presentation, structure, rotation_quarter_turns, measured_hero_world_size, build_progress, structure_footprint)
	if use_measured_3d_art:
		# The imported source model is already fitted to the same measured bounds
		# that created the active compound collision shell. Keep it as the single
		# operational silhouette so its actual depth, roofline, and contact shadow
		# are visible instead of hiding geometry behind a billboard.
		measured_3d_source.visible = true
		structure.set_meta("operational_art_source", "measured_3d_source")
	# Required directional families fail closed when a stage asset is missing;
	# never reintroduce a generic prop-sheet layer behind the missing silhouette.
	if state == "building" and not directional_stage_art and not directional_art_required:
		if build_progress >= 0.50:
			var partial_kind := _finished_sprite_kind(kind)
			var partial := _sprite_from_sheet(prop_sheet, int(build_sprite_regions.get(partial_kind, 1)), Vector3.ZERO, _structure_world_size(kind))
			if partial != null:
				partial.name = "IllustratedPartialWalls"
				partial.reparent(presentation)
				partial.position = Vector3.ZERO
				partial.modulate = Color(1.0, 1.0, 1.0, 0.64 if build_progress < 0.76 else 0.82)
				partial.render_priority = -1
				_set_structure_sprite_metadata(partial, structure, kind, state, "partial_walls", structure_footprint)
			if build_progress >= 0.76:
				var roof_ghost := _sprite_from_sheet(prop_sheet, int(build_sprite_regions.get(partial_kind, 1)), Vector3.ZERO, _structure_world_size(kind) * 1.03)
				if roof_ghost != null:
					roof_ghost.name = "IllustratedPartialRoof"
					roof_ghost.reparent(presentation)
					roof_ghost.position = Vector3.ZERO
					roof_ghost.modulate = Color(1.0, 1.0, 1.0, 0.82)
					roof_ghost.render_priority = -2
					_set_structure_sprite_metadata(roof_ghost, structure, kind, state, "partial_roof", structure_footprint)
	var kind_size := _structure_world_size(kind)
	# The collision envelope is the single scale authority. The former
	# world_size fallback made a 5x4m shed receive a workshop-sized visual slab,
	# which read as floating art and made the hitbox/asset relationship look wrong.
	var shadow_size := Vector2(maxf(1.7, structure_footprint.x * 1.04), maxf(1.35, structure_footprint.y * 0.78))
	_add_contact_shadow(presentation, Vector3(0.0, 0.025, 0.10), shadow_size, 0.0)
	var plot_width := maxf(1.6, structure_footprint.x + 0.18)
	var plot_depth := maxf(1.45, structure_footprint.y + 0.16)
	var base := _soft_box(presentation, "IllustratedPlotBase", Vector3(plot_width, 0.04, plot_depth), Vector3(0.0, 0.04, 0.0), Color(0.46, 0.56, 0.38, 0.22), true)
	# Keep the named plot-base hook for construction tooling, but do not leave a
	# translucent square under a finished cutout. The contact shadow above is the
	# only operational ground dressing; the slab remains faintly readable during
	# blueprint/build states where it communicates the player-owned footprint.
	var layered_construction := str(structure.get_meta("construction_art_source", "")) == "generated_workshop_layered_kit"
	var legacy_structure_base := structure.get_node_or_null("CisternBase") as Node3D
	if layered_construction and legacy_structure_base != null:
		# The old procedural base is a rectangular slab. The layered kit already
		# owns the measured foundation silhouette, so keeping both creates the exact
		# square-card read this renderer is replacing.
		legacy_structure_base.visible = false
		_hide_render_tree(legacy_structure_base)
	base.visible = not layered_construction or state == "blueprint"
	base.material_override = _soft_material(Color(0.48, 0.58, 0.41, 0.04 if layered_construction else (0.12 if state != "operational" else 0.0)), true, false)
	_build_structure_activity_dressing(presentation, structure, kind, state, data, structure_footprint)

func _add_archive_construction_phase_overlay(presentation: Node3D, structure: Node3D, rotation_quarter_turns: int, world_size: float, progress: float, footprint: Vector2) -> void:
	if presentation == null or structure == null or progress < 0.50:
		return
	var overlay := _player_structure_hero_sprite("archive", rotation_quarter_turns, world_size)
	if overlay == null:
		return
	overlay.name = "ArchiveConstructionPhaseOverlay"
	overlay.reparent(presentation)
	overlay.position = Vector3(0.0, 0.018, 0.0)
	overlay.render_priority = -1
	var fill_alpha := 0.24 if progress < 0.76 else 0.50
	overlay.modulate = Color(0.86, 0.95, 0.86, fill_alpha)
	_set_structure_sprite_metadata(overlay, structure, "archive", "building", "phase_overlay", footprint)
	overlay.set_meta("construction_phase_overlay", "walls" if progress < 0.76 else "roof")
	overlay.set_meta("construction_phase_progress", progress)

func _build_structure_activity_dressing(presentation: Node3D, structure: Node3D, kind: String, state: String, data: Dictionary, footprint: Vector2) -> void:
	if presentation == null or structure == null:
		return
	var dressing := Node3D.new()
	dressing.name = "StructureActivityDressing"
	dressing.set_meta("presentation_only", true)
	dressing.set_meta("collision_authority", "none")
	presentation.add_child(dressing)
	var front_zone := _structure_access_zone(kind, "front_door", Vector3(0.0, 0.0, footprint.y * 0.54))
	var service_zone := _structure_access_zone(kind, "service", Vector3(footprint.x * 0.54, 0.0, 0.0))
	var side_anchor := Vector3(footprint.x * 0.58, 0.0, -footprint.y * 0.18)
	var rear_anchor := Vector3(-footprint.x * 0.46, 0.0, -footprint.y * 0.54)
	if state != "operational":
		_add_construction_material_dressing(dressing, data, footprint, front_zone, side_anchor, rear_anchor)
		if state == "building":
			_add_construction_worker(dressing, kind, footprint, data)
		return
	match kind:
		"workshop":
			var yard_kit_size := maxf(2.4, footprint.y * 0.72)
			var yard_kit := _authored_cutout_sprite(
				dressing,
				"res://assets/generated/sanctuary/workshop/workshop-yard-kit.png",
				"sanctuary/player_structures/workshop/activity/yard_kit_v1",
				front_zone + Vector3(0.0, 0.02, 0.74),
				yard_kit_size,
				Vector2(0.94, 0.48)
			)
			if yard_kit == null:
				# Keep the deterministic primitive dressing as a safe fallback if an
				# imported/generated activity asset is unavailable on a clean build.
				_add_activity_box(dressing, "WorkshopBench", Vector3(1.28, 0.18, 0.46), front_zone + Vector3(-footprint.x * 0.20, 0.13, 0.32), Color("#8d593e"), Vector3(0.0, 0.0, 0.0))
				_add_activity_box(dressing, "WorkshopBenchTop", Vector3(1.38, 0.08, 0.52), front_zone + Vector3(-footprint.x * 0.20, 0.26, 0.32), Color("#bd8452"), Vector3(0.0, 0.0, 0.0))
				_add_activity_box(dressing, "WorkshopLogRack", Vector3(0.88, 0.62, 0.54), rear_anchor + Vector3(0.0, 0.31, 0.0), Color("#734936"), Vector3(0.0, 0.0, 0.0))
				_add_activity_box(dressing, "WorkshopLogTop", Vector3(0.98, 0.10, 0.60), rear_anchor + Vector3(0.0, 0.66, 0.0), Color("#a76843"), Vector3(0.0, 0.0, 0.0))
				_add_activity_box(dressing, "WorkshopAnvil", Vector3(0.34, 0.38, 0.30), service_zone + Vector3(0.34, 0.19, 0.0), Color("#45505a"), Vector3(0.0, 0.0, 0.0))
				_add_activity_lamp(dressing, "WorkshopForgeLamp", service_zone + Vector3(0.0, 1.05, 0.0), Color("#ffb45d"))
		"archive":
			_add_activity_box(dressing, "ArchiveReadingTable", Vector3(1.18, 0.16, 0.52), front_zone + Vector3(0.0, 0.12, 0.34), Color("#8d593e"), Vector3(0.0, 0.0, 0.0))
			_add_activity_box(dressing, "ArchiveLedgerStack", Vector3(0.34, 0.24, 0.28), front_zone + Vector3(0.18, 0.31, 0.28), Color("#d8b56f"), Vector3(0.0, 0.0, 0.0))
			_add_activity_box(dressing, "ArchiveBookCrate", Vector3(0.62, 0.42, 0.46), service_zone + Vector3(-0.24, 0.21, 0.0), Color("#6f4d3f"), Vector3(0.0, 0.0, 0.0))
			_add_activity_lamp(dressing, "ArchiveLantern", service_zone + Vector3(0.0, 0.92, 0.0), Color("#ffe2a0"))
		"storage_shed":
			_add_activity_box(dressing, "StoragePallet", Vector3(1.24, 0.13, 0.62), service_zone + Vector3(0.28, 0.10, 0.0), Color("#8d593e"), Vector3(0.0, 0.0, 0.0))
			_add_activity_box(dressing, "StorageCrateA", Vector3(0.48, 0.42, 0.48), service_zone + Vector3(-0.08, 0.38, 0.0), Color("#b47448"), Vector3(0.0, 0.0, 0.0))
			_add_activity_box(dressing, "StorageCrateB", Vector3(0.42, 0.34, 0.42), service_zone + Vector3(0.40, 0.34, 0.06), Color("#7b503b"), Vector3(0.0, 0.0, 0.0))
			_add_activity_lamp(dressing, "StorageLantern", front_zone + Vector3(footprint.x * 0.32, 0.78, 0.22), Color("#ffd27d"))
		"livestock_pen":
			_add_activity_box(dressing, "LivestockTrough", Vector3(1.10, 0.24, 0.42), service_zone + Vector3(0.26, 0.18, 0.0), Color("#a96b47"), Vector3(0.0, 0.0, 0.0))
			_add_activity_box(dressing, "LivestockHayBale", Vector3(0.56, 0.46, 0.48), side_anchor + Vector3(0.0, 0.23, 0.0), Color("#d4aa5c"), Vector3(0.0, 0.0, 0.0))
			_add_activity_box(dressing, "LivestockHayBaleTop", Vector3(0.60, 0.08, 0.50), side_anchor + Vector3(0.0, 0.50, 0.0), Color("#edca78"), Vector3(0.0, 0.0, 0.0))
		"rain_cistern":
			_add_activity_box(dressing, "CisternBucket", Vector3(0.42, 0.34, 0.42), front_zone + Vector3(0.48, 0.18, 0.26), Color("#9a6245"), Vector3(0.0, 0.0, 0.0))
			_add_activity_box(dressing, "CisternRopeCoil", Vector3(0.52, 0.12, 0.52), front_zone + Vector3(-0.46, 0.10, 0.26), Color("#d1ad68"), Vector3(0.0, 0.0, 0.0))
			_add_activity_lamp(dressing, "CisternLantern", side_anchor + Vector3(0.0, 0.78, 0.0), Color("#8edbd5"))

func _add_construction_worker(parent: Node3D, kind: String, footprint: Vector2, data: Dictionary) -> void:
	if parent == null or CONSTRUCTION_WORKER_SPRITE_SHEET_PATH.is_empty() or not ResourceLoader.exists(CONSTRUCTION_WORKER_SPRITE_SHEET_PATH):
		return
	var sheet := load(CONSTRUCTION_WORKER_SPRITE_SHEET_PATH) as Texture2D
	if sheet == null:
		return
	var frame_contract := _measure_walk_sheet(sheet)
	var max_opaque_height := float(frame_contract.get("max_opaque_height", 0.0))
	var max_opaque_width := float(frame_contract.get("max_opaque_width", 0.0))
	if max_opaque_height <= 0.0 or max_opaque_width <= 0.0:
		return
	var cell_width := float(sheet.get_width()) / float(WALK_SHEET_COLUMNS)
	var cell_height := float(sheet.get_height()) / float(WALK_SHEET_ROWS)
	var worker_height := _reference_character_world_height()
	var pixel_size := worker_height / max_opaque_height
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(0.0, 0.0, cell_width, cell_height)
	atlas.filter_clip = true
	var worker := Sprite3D.new()
	worker.name = "ConstructionWorker"
	worker.texture = atlas
	worker.centered = false
	var frame_offsets: Array = frame_contract.get("offsets", [])
	var initial_offset: Array = frame_offsets[0][0] if frame_offsets.size() > 0 and frame_offsets[0] is Array and (frame_offsets[0] as Array).size() > 0 else [-cell_width * 0.5, 0.0]
	worker.offset = Vector2(float(initial_offset[0]), float(initial_offset[1]))
	worker.pixel_size = pixel_size
	worker.axis = Vector3.AXIS_Z
	worker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	worker.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	worker.shaded = true
	worker.material_override = _structure_sprite_material(atlas)
	worker.no_depth_test = false
	worker.sorting_use_aabb_center = false
	worker.sorting_offset = 0.0
	var first_bounds := _walk_bounds_rect(frame_contract, 0, 0, cell_width, cell_height)
	var visible_width := max_opaque_width * pixel_size
	var profile := {
		"asset_id": "sanctuary/characters/construction_worker_direction_walk_sheet_v2",
		"footprint_ratio": Vector2(maxf(0.18, visible_width / worker_height * 0.52), 0.22),
		"asset_path": CONSTRUCTION_WORKER_SPRITE_SHEET_PATH,
	}
	_set_sprite_contract_metadata(worker, profile, first_bounds, worker_height)
	worker.set_meta("asset_path", CONSTRUCTION_WORKER_SPRITE_SHEET_PATH)
	worker.set_meta("animation_rows", {"work": "directional_walk_rows"})
	worker.set_meta("direction_frames", WALK_SHEET_ROWS)
	worker.set_meta("walk_frame_count", WALK_SHEET_COLUMNS)
	worker.set_meta("walk_frame_rate", 5.0)
	worker.set_meta("walk_cell_size", [cell_width, cell_height])
	worker.set_meta("walk_frame_offsets", frame_offsets)
	worker.set_meta("walk_frame_bounds", frame_contract.get("bounds", []))
	worker.set_meta("walk_max_visible_size", [max_opaque_width * pixel_size, worker_height])
	worker.set_meta("animation_measurement_source", "per_cell_texture_alpha_used_rect")
	worker.set_meta("presentation_only", true)
	worker.set_meta("collision_layer", 0)
	worker.set_meta("worker_role", "construction_activity")
	worker.set_meta("construction_state", "building")
	worker.set_meta("construction_progress", _construction_progress(data))
	var zone := _construction_activity_zone(kind)
	if zone.is_empty():
		return
	var zone_center := _array_to_vector3(zone.get("center", []), Vector3(0.0, 0.0, footprint.y * 0.54))
	var zone_facing := _array_to_vector3(zone.get("facing", []), Vector3(0.0, 0.0, 1.0))
	zone_facing.y = 0.0
	zone_facing = zone_facing.normalized() if zone_facing.length_squared() > 0.01 else Vector3(0.0, 0.0, 1.0)
	var worker_footprint_value: Array = worker.get_meta("visual_footprint", [0.6, 0.42])
	var worker_depth := maxf(0.2, float(worker_footprint_value[1]))
	var structure_half_extent := absf(zone_facing.x) * footprint.x * 0.5 + absf(zone_facing.z) * footprint.y * 0.5
	var zone_projection := absf(zone_center.x * zone_facing.x + zone_center.z * zone_facing.z)
	var boundary_correction := maxf(0.0, structure_half_extent - zone_projection)
	var zone_size: Array = zone.get("size", [1.0, 1.0])
	var zone_span := float(zone_size[1]) if absf(zone_facing.z) >= absf(zone_facing.x) else float(zone_size[0])
	var approach_gap := maxf(worker_depth * 0.55, maxf(0.12, zone_span * 0.18))
	var worker_position := zone_center + zone_facing * (boundary_correction + approach_gap)
	worker.position = worker_position
	var direction_frame := _walk_direction_frame(-zone_facing)
	worker.set_meta("direction_frame", direction_frame)
	worker.set_meta("activity_zone_id", str(zone.get("id", "")))
	worker.set_meta("activity_zone_facing", [zone_facing.x, zone_facing.y, zone_facing.z])
	worker.set_meta("ground_pivot", [0.0, 0.0, 0.0])
	parent.add_child(worker)
	var shadow := _add_contact_shadow(parent, worker_position + Vector3(0.0, 0.018, 0.0), Vector2(maxf(0.42, visible_width * 0.72), maxf(0.28, worker_depth * 1.55)), 0.0)
	shadow.name = "ConstructionWorkerContactShadow"
	shadow.set_meta("presentation_only", true)
	shadow.set_meta("collision_layer", 0)
	construction_worker_nodes.append({"node": worker, "base_position": worker_position, "phase": worker_position.x * 0.7 + worker_position.z * 0.35, "frame_time": 0.0})

func _construction_activity_zone(kind: String) -> Dictionary:
	var first_zone: Dictionary = {}
	for zone_value in SanctuaryAssetCatalog.structure_access_zones(kind, 0):
		if not (zone_value is Dictionary):
			continue
		var zone := zone_value as Dictionary
		if first_zone.is_empty():
			first_zone = zone
		if str(zone.get("kind", "")) == "service":
			return zone
	return first_zone

func _reference_character_world_height() -> float:
	if host_world != null:
		var guide := host_world.get("guide_npc") as Node3D
		var guide_sprite := guide.get_node_or_null("Visual/IllustratedMira") as Sprite3D if guide != null else null
		if guide_sprite != null:
			var measured := float(guide_sprite.get_meta("visual_height_world_meters", 0.0))
			if measured > 0.01:
				return measured
	return 2.02

func _measure_walk_sheet(sheet: Texture2D) -> Dictionary:
	var image := sheet.get_image() if sheet != null else null
	if image == null:
		return {"max_opaque_height": 0.0, "max_opaque_width": 0.0, "offsets": [], "bounds": []}
	var cell_width := float(image.get_width()) / float(WALK_SHEET_COLUMNS)
	var cell_height := float(image.get_height()) / float(WALK_SHEET_ROWS)
	var offsets: Array = []
	var bounds: Array = []
	var max_opaque_height := 0.0
	var max_opaque_width := 0.0
	for direction in WALK_SHEET_ROWS:
		var direction_offsets: Array = []
		var direction_bounds: Array = []
		for frame in WALK_SHEET_COLUMNS:
			var left := int(round(float(frame) * cell_width))
			var top := int(round(float(direction) * cell_height))
			var right := int(round(float(frame + 1) * cell_width))
			var bottom := int(round(float(direction + 1) * cell_height))
			var cell_rect := Rect2i(left, top, maxi(1, right - left), maxi(1, bottom - top))
			var used := image.get_region(cell_rect).get_used_rect()
			if used.size.x <= 0 or used.size.y <= 0:
				direction_offsets.append([-cell_width * 0.5, 0.0])
				direction_bounds.append([0, 0, 0, 0])
				continue
			max_opaque_height = maxf(max_opaque_height, float(used.size.y))
			max_opaque_width = maxf(max_opaque_width, float(used.size.x))
			var bottom_gap := float(cell_rect.size.y - used.position.y - used.size.y)
			direction_offsets.append([-(float(used.position.x) + float(used.size.x) * 0.5), -bottom_gap])
			direction_bounds.append([used.position.x, used.position.y, used.size.x, used.size.y])
		offsets.append(direction_offsets)
		bounds.append(direction_bounds)
	return {"max_opaque_height": max_opaque_height, "max_opaque_width": max_opaque_width, "offsets": offsets, "bounds": bounds}

func _walk_bounds_rect(contract: Dictionary, direction: int, frame: int, cell_width: float, cell_height: float) -> Rect2i:
	var bounds: Array = contract.get("bounds", [])
	if direction < bounds.size() and bounds[direction] is Array and frame < (bounds[direction] as Array).size():
		var value: Variant = (bounds[direction] as Array)[frame]
		if value is Array and (value as Array).size() >= 4:
			var rect := value as Array
			return Rect2i(int(rect[0]), int(rect[1]), maxi(1, int(rect[2])), maxi(1, int(rect[3])))
	return Rect2i(0, 0, maxi(1, int(cell_width)), maxi(1, int(cell_height)))

func _walk_direction_frame(facing: Vector3) -> int:
	if absf(facing.z) >= absf(facing.x):
		return 2 if facing.z < 0.0 else 0
	return 3 if facing.x < 0.0 else 1

func _array_to_vector3(value: Variant, fallback: Vector3) -> Vector3:
	if value is Array and (value as Array).size() >= 3:
		var array := value as Array
		return Vector3(float(array[0]), float(array[1]), float(array[2]))
	return fallback

func _structure_access_zone(kind: String, zone_id: String, fallback: Vector3) -> Vector3:
	for zone_value in SanctuaryAssetCatalog.structure_access_zones(kind, 0):
		if not (zone_value is Dictionary):
			continue
		var zone := zone_value as Dictionary
		if str(zone.get("id", "")) != zone_id and not (zone_id == "service" and str(zone.get("kind", "")) == "service"):
			continue
		var center: Array = zone.get("center", [])
		if center.size() >= 3:
			return Vector3(float(center[0]), float(center[1]), float(center[2]))
	return fallback

func _add_construction_material_dressing(parent: Node3D, data: Dictionary, footprint: Vector2, front_zone: Vector3, side_anchor: Vector3, rear_anchor: Vector3) -> void:
	var delivered: Dictionary = data.get("delivered_materials", {})
	var wood_count := mini(4, int(delivered.get("wood", 0)))
	var plank_count := mini(4, int(delivered.get("plank", 0)))
	var stone_count := mini(4, int(delivered.get("stone", 0)))
	var fiber_count := mini(4, int(delivered.get("fiber", 0)))
	for index in wood_count:
		_add_activity_box(parent, "DeliveredWood_%d" % index, Vector3(minf(1.18, footprint.x * 0.28), 0.14, 0.20), rear_anchor + Vector3(float(index) * 0.16, 0.16 + float(index % 2) * 0.15, 0.0), Color("#a76843"), Vector3(0.0, float(index) * 0.12, 0.0))
	for index in plank_count:
		_add_activity_box(parent, "DeliveredPlank_%d" % index, Vector3(0.72, 0.09, 0.24), side_anchor + Vector3(0.0, 0.12 + float(index) * 0.11, float(index) * 0.12), Color("#d1a068"), Vector3(0.0, float(index) * 0.08, 0.0))
	for index in stone_count:
		_add_activity_box(parent, "DeliveredStone_%d" % index, Vector3(0.24, 0.20, 0.28), front_zone + Vector3(-footprint.x * 0.42 + float(index % 2) * 0.28, 0.10 + float(index / 2) * 0.16, 0.24), Color("#84939a"), Vector3(0.0, float(index) * 0.16, 0.0))
	for index in fiber_count:
		_add_activity_box(parent, "DeliveredFiber_%d" % index, Vector3(0.28, 0.22, 0.28), side_anchor + Vector3(0.28 + float(index % 2) * 0.18, 0.12 + float(index / 2) * 0.18, 0.18), Color("#c7b86b"), Vector3(0.0, float(index) * 0.1, 0.0))

func _add_activity_box(parent: Node3D, node_name: String, size: Vector3, position: Vector3, color: Color, rotation_degrees: Vector3) -> MeshInstance3D:
	var prop := MeshInstance3D.new()
	prop.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	prop.mesh = mesh
	prop.position = position
	prop.rotation_degrees = rotation_degrees
	prop.material_override = _soft_material(color, false, false)
	prop.set_meta("presentation_only", true)
	prop.set_meta("collision_layer", 0)
	parent.add_child(prop)
	return prop

func _add_activity_lamp(parent: Node3D, node_name: String, position: Vector3, color: Color) -> void:
	var lamp := MeshInstance3D.new()
	lamp.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	mesh.radial_segments = 8
	mesh.rings = 4
	lamp.mesh = mesh
	lamp.position = position
	lamp.material_override = _soft_material(color, false, true)
	lamp.set_meta("presentation_only", true)
	lamp.set_meta("collision_layer", 0)
	parent.add_child(lamp)
	activity_motion_nodes.append({"node": lamp, "base_position": position, "phase": position.x * 0.8 + position.z * 0.4, "lift": 0.015, "base_rotation": 0.0})

func _authored_cutout_sprite(parent: Node3D, asset_path: String, asset_id: String, position: Vector3, world_size: float, footprint_ratio: Vector2) -> Sprite3D:
	if parent == null or asset_path.is_empty() or not ResourceLoader.exists(asset_path):
		return null
	var texture := load(asset_path) as Texture2D
	if texture == null:
		return null
	var image := texture.get_image()
	if image == null:
		return null
	var opaque_bounds := image.get_used_rect()
	if opaque_bounds.size.x <= 0 or opaque_bounds.size.y <= 0:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(0.0, 0.0, float(image.get_width()), float(image.get_height()))
	atlas.filter_clip = true
	var sprite := Sprite3D.new()
	sprite.name = "AuthoredWorkshopYardKit"
	sprite.texture = atlas
	sprite.centered = false
	var transparent_bottom := float(maxi(0, image.get_height() - opaque_bounds.position.y - opaque_bounds.size.y))
	sprite.offset = Vector2(-(float(opaque_bounds.position.x) + float(opaque_bounds.size.x) * 0.5), -transparent_bottom)
	sprite.pixel_size = maxf(0.01, world_size) / float(maxi(1, opaque_bounds.size.y))
	sprite.position = position
	sprite.axis = Vector3.AXIS_Z
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.shaded = true
	sprite.material_override = _structure_sprite_material(atlas)
	sprite.no_depth_test = false
	sprite.sorting_use_aabb_center = false
	sprite.sorting_offset = 0.0
	_set_sprite_contract_metadata(sprite, {"asset_id": asset_id, "footprint_ratio": footprint_ratio}, opaque_bounds, maxf(0.01, world_size))
	sprite.set_meta("presentation_only", true)
	sprite.set_meta("collision_layer", 0)
	sprite.set_meta("activity_asset_path", asset_path)
	parent.add_child(sprite)
	return sprite

func _structure_world_size(kind: String) -> float:
	return float(SanctuaryAssetCatalog.structure_definition(kind).get("world_size", 4.0))

func _finished_sprite_kind(kind: String) -> String:
	return str(SanctuaryAssetCatalog.structure_definition(kind).get("sprite_kind", "workshop"))

func _construction_progress(data: Dictionary) -> float:
	var total_hours := maxf(1.0, float(data.get("total_hours", 24.0)))
	return clampf(1.0 - float(data.get("remaining_hours", total_hours)) / total_hours, 0.0, 1.0)

func _construction_stage_for_progress(progress: float) -> String:
	# Keep the authored directional cutouts synchronized with the authoritative
	# construction milestones: frame/foundation through the first half, walls
	# through the wall-complete threshold, and roof for the finishing interval.
	# The physical material ledger owns these same boundaries; this function only
	# selects the presentation stage and never changes gameplay progress.
	if progress < 0.50:
		return "frame"
	if progress < 0.76:
		return "walls"
	return "roof"

func _measured_hero_world_size(structure: Node3D, kind: String, rotation_quarter_turns: int) -> float:
	var fallback := _structure_world_size(kind)
	if structure == null:
		return fallback
	var definition := SanctuaryAssetCatalog.structure_definition(kind)
	var family_size := fallback
	for variant_value in definition.get("directional_variants", []):
		if not (variant_value is Dictionary):
			continue
		var variant: Dictionary = variant_value
		family_size = maxf(family_size, _measured_cutout_world_size(structure, kind, str(variant.get("asset_path", "")), fallback))
	return family_size

func _measured_stage_family_world_size(structure: Node3D, kind: String, stage_id: String, fallback: float) -> float:
	var definition := SanctuaryAssetCatalog.structure_definition(kind)
	var directional: Dictionary = definition.get("construction_stage_directional_paths", {})
	var stage_paths: Dictionary = directional.get(stage_id, {})
	if stage_paths.is_empty():
		return _measured_cutout_world_size(structure, kind, SanctuaryAssetCatalog.structure_construction_stage_asset(kind, stage_id, 0), fallback)
	var family_size := fallback
	for rotation in [0, 1, 2, 3]:
		family_size = maxf(family_size, _measured_cutout_world_size(structure, kind, str(stage_paths.get(rotation, "")), fallback))
	return family_size

func _measured_cutout_world_size(structure: Node3D, kind: String, asset_path: String, fallback: float) -> float:
	if structure == null or asset_path.is_empty():
		return fallback
	var measurement: Dictionary = structure.get_meta("source_measurement", {})
	var fitted_size: Vector3 = measurement.get("fitted_size", Vector3.ZERO)
	if fitted_size.x <= 0.01 or fitted_size.y <= 0.01:
		return fallback
	var texture := load(asset_path) as Texture2D if not asset_path.is_empty() and ResourceLoader.exists(asset_path) else null
	if texture == null:
		return fallback
	var image := texture.get_image()
	if image == null:
		return fallback
	var opaque_bounds := image.get_used_rect()
	if opaque_bounds.size.x <= 0 or opaque_bounds.size.y <= 0:
		return fallback
	# Fit the visible generated silhouette to the measured physical envelope and
	# the camera-projected horizontal envelope. A 3/4 cutout represents both
	# local X and local Z, so width-only fitting can drift outside the shell.
	var projected_horizontal_extent := _measured_projected_horizontal_extent(structure, fitted_size)
	var width_limit := projected_horizontal_extent * float(opaque_bounds.size.y) / float(opaque_bounds.size.x)
	# Width is the controlling envelope for a 3/4 cutout: the visible silhouette
	# must reach the measured shell's projected horizontal edge or the player will
	# see empty space where the collision already blocks movement. The height is
	# the measured source height; a facility family may grow from the widest
	# directional requirement, but no arbitrary per-view multiplier is allowed.
	var result := maxf(width_limit, fitted_size.y)
	return maxf(1.0, result)

func _measured_projected_horizontal_extent(structure: Node3D, fitted_size: Vector3) -> float:
	var camera := get_viewport().get_camera_3d() if get_viewport() != null else null
	var camera_right := Vector3(1.0, 0.0, 0.0)
	if camera != null:
		camera_right = camera.global_basis.x
		camera_right.y = 0.0
		if camera_right.length_squared() > 0.01:
			camera_right = camera_right.normalized()
	var world_x := structure.global_basis * Vector3.RIGHT
	var world_z := structure.global_basis * Vector3.BACK
	world_x.y = 0.0
	world_z.y = 0.0
	if world_x.length_squared() <= 0.01 or world_z.length_squared() <= 0.01:
		return minf(fitted_size.x, fitted_size.z)
	world_x = world_x.normalized()
	world_z = world_z.normalized()
	return maxf(0.25, absf(world_x.dot(camera_right)) * fitted_size.x + absf(world_z.dot(camera_right)) * fitted_size.z)

func _structure_local_visual_footprint(structure: Node3D, data: Dictionary, fallback_size: float) -> Vector2:
	# Read the already-authored local collision shape when available. This is a
	# one-way presentation measurement: it cannot mutate physics or occupancy and
	# avoids reimplementing the rotation contract in the renderer.
	var local_footprint_value: Variant = structure.get_meta("local_collision_footprint", [])
	if local_footprint_value is Array and (local_footprint_value as Array).size() == 2:
		var local_footprint := local_footprint_value as Array
		return Vector2(maxf(0.01, float(local_footprint[0])), maxf(0.01, float(local_footprint[1])))
	var collision := structure.get_node_or_null("StructureCollisionBody/StructureCollisionShape") as CollisionShape3D
	var box := collision.shape as BoxShape3D if collision != null else null
	if box != null:
		return Vector2(maxf(0.01, box.size.x), maxf(0.01, box.size.z))
	var footprint_value: Variant = structure.get_meta("grid_footprint", [])
	if footprint_value is Array and (footprint_value as Array).size() == 2:
		var footprint := footprint_value as Array
		var width := maxf(0.01, float(footprint[0]))
		var depth := maxf(0.01, float(footprint[1]))
		# The structure root owns the quarter-turn. Convert its world-oriented
		# metadata back to canonical local axes so the child is never double-swapped.
		if posmod(int(data.get("rotation", 0)), 2) == 1:
			return Vector2(depth, width)
		return Vector2(width, depth)
	return Vector2(maxf(1.0, fallback_size * 0.72), maxf(1.0, fallback_size * 0.52))

func _set_structure_sprite_metadata(sprite: Sprite3D, structure: Node3D, kind: String, state: String, layer: String, visual_footprint: Vector2) -> void:
	sprite.set_meta("visual_footprint", [visual_footprint.x, visual_footprint.y])
	sprite.set_meta("structure_asset_id", str(structure.get_meta("asset_id", SanctuaryAssetCatalog.structure_definition(kind).get("asset_id", ""))))
	sprite.set_meta("structure_directional_variant_id", str(structure.get_meta("directional_variant_id", "")))
	sprite.set_meta("structure_directional_asset_id", str(structure.get_meta("directional_asset_id", "")))
	var measured: Dictionary = structure.get_meta("source_measurement", {})
	sprite.set_meta("measurement_source_asset", str(measured.get("source_path", "")))
	sprite.set_meta("measurement_source", "imported_mesh_bounds" if bool(measured.get("valid", false)) else "unavailable")
	sprite.set_meta("measurement_fit_scale", float(measured.get("fit_scale", 0.0)))
	sprite.set_meta("measurement_fitted_size", _vector3_to_array(measured.get("fitted_size", Vector3.ZERO)))
	sprite.set_meta("structure_kind", kind)
	sprite.set_meta("construction_state", state)
	sprite.set_meta("presentation_layer", layer)

func _vector3_to_array(value: Variant) -> Array:
	if value is Vector3:
		var vector := value as Vector3
		return [vector.x, vector.y, vector.z]
	return [0.0, 0.0, 0.0]

func _add_worn_path_segment(position: Vector3, size: Vector2, rotation_degrees: float, darker := false) -> void:
	var edge_color: Color = PALETTE["path_shadow"] if darker else PALETTE["path_edge"]
	var core_color: Color = PALETTE["path_shadow"] if darker else PALETTE["path"]
	var edge := _add_rounded_patch(position + Vector3(0.0, -0.006, 0.0), size + Vector2(0.44, 0.42), edge_color, rotation_degrees, true)
	edge.name = "PackedEarthPathEdge"
	var core := _add_rounded_patch(position, size, core_color, rotation_degrees, true)
	core.name = "PackedEarthPath"

func _add_contact_shadow(parent: Node3D, position: Vector3, size: Vector2, rotation_degrees: float) -> MeshInstance3D:
	# Shallow alpha decals anchor billboard feet and structure bases without
	# adding bodies or participating in placement/occupancy calculations.
	return _create_rounded_patch(parent, "IllustratedContactShadow", position, size, PALETTE["contact_shadow"], rotation_degrees)

func _add_rounded_patch(position: Vector3, size: Vector2, color: Color, rotation_degrees: float, path_material := false) -> MeshInstance3D:
	return _create_rounded_patch(self, "SoftGroundPatch", position, size, color, rotation_degrees, path_material)

func _create_rounded_patch(parent: Node3D, node_name: String, position: Vector3, size: Vector2, color: Color, rotation_degrees: float, path_material := false) -> MeshInstance3D:
	var patch := MeshInstance3D.new()
	patch.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.02
	mesh.height = 0.035
	mesh.radial_segments = 32
	patch.mesh = mesh
	patch.position = position
	patch.rotation_degrees.y = rotation_degrees
	patch.scale = Vector3(size.x * 0.5, 1.0, size.y * 0.5)
	patch.material_override = _ground_material(color, color.a < 0.999, path_material)
	patch.set_meta("shader_role", "ground_path" if path_material and color.a >= 0.999 else ("ground_moss" if color.a >= 0.999 else "transparent_contact"))
	parent.add_child(patch)
	return patch

func _ground_material(color: Color, transparent: bool, path_material := false) -> Material:
	if not transparent:
		var template := ground_path_material if path_material else ground_moss_material
		if template != null:
			var shader_material := template.duplicate() as ShaderMaterial
			shader_material.set_shader_parameter("base_color", Color(color.r, color.g, color.b, 1.0))
			shader_material.set_shader_parameter("edge_color", Color(color.darkened(0.34).r, color.darkened(0.34).g, color.darkened(0.34).b, 1.0))
			return shader_material
	# Ground decals need stable authored values: the prototype's strong world
	# light otherwise turns muted moss into lime and the build reserve into a
	# yellow blob. Unshaded here affects presentation meshes only; day/night,
	# collision, and gameplay lighting remain owned by the world systems.
	var material := _soft_material(color, transparent, false)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

func _soft_box(parent: Node3D, node_name: String, size: Vector3, position: Vector3, color: Color, transparent: bool) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = _soft_material(color, transparent, false)
	parent.add_child(instance)
	return instance

func _soft_material(color: Color, transparent: bool, emissive: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.2
	return material
