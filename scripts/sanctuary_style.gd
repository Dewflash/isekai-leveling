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
var grid_root: Node3D
var preview_root: Node3D
var preview_fill: MeshInstance3D
var preview_outline: Node3D
var placement_active := false
var placement_center := Vector3.ZERO
var placement_footprint := Vector2i.ONE
var placement_rotation := 0
var placement_valid := false
var elapsed := 0.0
var swaying_nodes: Array[Dictionary] = []
var pulsing_nodes: Array[Dictionary] = []
var fire_lights: Array[Dictionary] = []
var resource_visual_roots: Array[Node3D] = []
var canonical_landmark_roots: Dictionary = {}
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
	_hide_replaced_presentation(legacy_nodes)
	_hide_furnace_presentation()
	if source_district != null:
		# Visibility does not disable the district's shell collisions. The
		# gameplay footprint therefore stays in place while its hard-edged source
		# meshes are replaced by this authored 2.5D layer.
		source_district.visible = false
	_build_soft_ground()
	_build_paths()
	_build_open_build_field()
	_build_story_campfire()
	_build_canonical_landmarks()
	_build_environment_framing()
	_build_route_markers()
	_build_ambient_lights()

func _process(delta: float) -> void:
	elapsed += delta
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
		if child.name == "SanctuaryGround" or child.name == "CloverLivestockPen":
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
	# Layered moss islands sit above the legacy collision plane. Low-contrast
	# tonal shifts and perimeter scallops break the synthetic lime oval while
	# leaving the central player-authored reserve completely untouched.
	_add_rounded_patch(Vector3(0.0, 0.018, 0.8), Vector2(27.5, 22.0), PALETTE["meadow"], 0.0)
	_add_rounded_patch(Vector3(-8.8, 0.024, -5.5), Vector2(8.5, 7.0), PALETTE["meadow_shadow"], -12.0)
	_add_rounded_patch(Vector3(9.0, 0.024, 5.0), Vector2(9.0, 6.5), PALETTE["meadow_light"], 14.0)
	_add_rounded_patch(Vector3(-8.0, 0.026, 7.6), Vector2(9.0, 4.8), PALETTE["meadow_light"], 4.0)
	_add_rounded_patch(Vector3(7.0, 0.026, -7.0), Vector2(9.0, 4.8), PALETTE["meadow_shadow"], -8.0)
	for edge_data in [
		[Vector3(-12.9, 0.028, -5.8), Vector2(3.0, 4.2), -16.0, "meadow_deep"],
		[Vector3(-13.2, 0.029, 3.0), Vector2(2.4, 3.4), 9.0, "meadow_shadow"],
		[Vector3(-9.8, 0.029, 10.0), Vector2(4.2, 2.3), -8.0, "meadow_light"],
		[Vector3(-2.8, 0.029, 11.2), Vector2(4.6, 1.8), 5.0, "meadow_shadow"],
		[Vector3(5.4, 0.029, 10.9), Vector2(3.6, 2.0), -11.0, "meadow_light"],
		[Vector3(12.8, 0.029, 6.2), Vector2(2.8, 4.0), 14.0, "meadow_shadow"],
		[Vector3(13.3, 0.029, -2.8), Vector2(2.2, 3.2), -7.0, "meadow_deep"],
		[Vector3(8.2, 0.029, -10.1), Vector2(4.0, 2.5), 10.0, "meadow_light"],
		[Vector3(-1.0, 0.029, -10.5), Vector2(4.8, 2.0), -4.0, "meadow_shadow"],
	]:
		var edge := _add_rounded_patch(edge_data[0], edge_data[1], PALETTE[str(edge_data[3])], float(edge_data[2]))
		edge.name = "IrregularMeadowEdge"

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
	var field_edge := _add_rounded_patch(Vector3(0.0, 0.061, 1.65), Vector2(11.0, 8.6), PALETTE["meadow_shadow"], 0.0)
	field_edge.name = "PlayerDirectedBuildFieldEdge"
	var field := _add_rounded_patch(Vector3(0.0, 0.064, 1.65), Vector2(10.6, 8.2), PALETTE["build_field"], 0.0)
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

	var source_asset_path := str(source.get_meta("source_asset", ""))
	root.set_meta("source_asset", source_asset_path)
	var source_scene := load(source_asset_path) as PackedScene if not source_asset_path.is_empty() else null
	if source_scene != null:
		var visual := source_scene.instantiate() as Node3D
		if visual != null:
			visual.name = "SourcedLandmarkAsset"
			root.add_child(visual)
			# Preserve only the imported asset's authored local scale/orientation.
			# The shell remains authoritative for the world-space origin and rotation,
			# so later district placement changes cannot separate art from collision.
			var source_relative := shell.global_transform.affine_inverse() * source.global_transform
			source_relative.origin = Vector3.ZERO
			visual.transform = source_relative
			visual.visible = true
	# The original source node stays in the district for world-loop compatibility,
	# but it is never allowed to become a second visible presentation root.
	source.visible = false
	canonical_landmark_roots[str(definition.get("id", ""))] = root

func _build_environment_framing() -> void:
	# The environment sheet gives the scene a consistent illustrated silhouette
	# language instead of mixing flat primitives with imported low-poly trees.
	for tree_data in [
		[0, Vector3(-12.5, 0.10, -8.6), 5.5], [1, Vector3(-7.7, 0.10, -10.0), 5.0],
		[1, Vector3(0.0, 0.10, -10.4), 5.4], [2, Vector3(7.2, 0.10, -9.4), 5.0],
		[0, Vector3(12.0, 0.10, -7.4), 5.0], [2, Vector3(-12.1, 0.10, 6.9), 4.3],
		[1, Vector3(12.2, 0.10, 7.4), 4.8], [0, Vector3(-11.7, 0.10, 10.0), 4.6],
		[2, Vector3(10.5, 0.10, 10.3), 4.2],
	]:
		var tree_size := float(tree_data[2])
		var tree_position: Vector3 = tree_data[1]
		_add_contact_shadow(self, Vector3(tree_position.x, 0.084, tree_position.z + 0.12), Vector2(tree_size * 0.58, tree_size * 0.22), tree_position.x * 1.7)
		var tree_sprite := _add_environment_sprite(int(tree_data[0]), tree_position, tree_size, 0.22)
		_attach_measured_visual_collision(tree_sprite, "tree")
	for rock_data in [
		[Vector3(-11.5, 0.10, -3.9), 3.2], [Vector3(11.6, 0.10, -2.6), 2.8],
		[Vector3(-10.8, 0.10, 8.3), 2.7], [Vector3(10.8, 0.10, 8.8), 2.5],
	]:
		var rock_size := float(rock_data[1])
		var rock_position: Vector3 = rock_data[0]
		_add_contact_shadow(self, Vector3(rock_position.x, 0.084, rock_position.z + 0.08), Vector2(rock_size * 0.60, rock_size * 0.22), rock_position.z * 2.0)
		var rock_sprite := _add_environment_sprite(3, rock_position, rock_size, 0.1)
		_attach_measured_visual_collision(rock_sprite, "rock")
	_add_contact_shadow(self, Vector3(-11.0, 0.084, 4.9), Vector2(2.2, 0.7), 8.0)
	_add_environment_sprite(4, Vector3(-11.0, 0.10, 4.8), 3.1, 0.35)
	_add_contact_shadow(self, Vector3(10.9, 0.084, 4.3), Vector2(2.1, 0.7), -7.0)
	_add_environment_sprite(4, Vector3(10.9, 0.10, 4.2), 3.0, 0.9)
	_add_contact_shadow(self, Vector3(9.0, 0.083, 0.52), Vector2(3.4, 1.35), 0.0)
	_add_environment_sprite(5, Vector3(9.0, 0.10, 0.4), 4.1, 0.0)

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
	sprite.shaded = false
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
	sprite.shaded = false
	sprite.no_depth_test = false
	sprite.sorting_use_aabb_center = false
	sprite.sorting_offset = 0.0
	_set_sprite_contract_metadata(sprite, profile, opaque_bounds, maxf(0.01, world_size))
	sprite.set_meta("player_structure_art_kind", kind)
	sprite.set_meta("player_structure_sheet_cell", sheet_index)
	add_child(sprite)
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

func set_placement_preview(center: Vector3, footprint: Vector2i, valid: bool, rotation_quarter_turns: int, active: bool) -> void:
	placement_active = active
	if grid_root != null:
		grid_root.visible = active
	if preview_root == null:
		return
	preview_root.visible = active
	if not active:
		return
	placement_center = center
	placement_footprint = Vector2i(maxi(1, footprint.x), maxi(1, footprint.y))
	placement_rotation = posmod(rotation_quarter_turns, 4)
	placement_valid = valid
	preview_root.position = center + Vector3(0.0, 0.08, 0.0)
	preview_root.rotation.y = float(placement_rotation) * PI * 0.5
	var width := float(placement_footprint.x)
	var depth := float(placement_footprint.y)
	if preview_fill != null:
		var fill_mesh := preview_fill.mesh as BoxMesh
		if fill_mesh != null:
			fill_mesh.size = Vector3(width, 0.035, depth)
		preview_fill.position.y = 0.018
		preview_fill.material_override = _soft_material(PALETTE["grid_valid"] if valid else PALETTE["grid_blocked"], true, true)
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

func apply_structure_visual(structure: Node3D, kind: String, state: String, data: Dictionary) -> void:
	if structure == null:
		return
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
	var use_measured_3d_art := state == "operational" and str(structure_definition.get("operational_art_mode", "illustrated_2_5d")) == "measured_3d" and bool(structure.get_meta("source_measurement_valid", false)) and measured_3d_source != null
	var use_player_structure_art := state == "operational" and not use_measured_3d_art and player_structure_sheet != null and PLAYER_STRUCTURE_ASSET_PROFILES.has(kind)
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
	for node_name in hide_names:
		# Building states keep their additive foundation/frame/wall/roof/fitting
		# meshes visible; these are the material-driven construction proof. The
		# finished source scene is likewise retained when it is the unique
		# operational asset for this structure kind.
		if state == "building" and node_name in ["CisternBase", "ConstructionWalls", "ConstructionRoof", "ScaffoldFrame"]:
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
	if not use_measured_3d_art:
		sprite = _player_structure_sprite_from_sheet(kind, _structure_world_size(kind)) if use_player_structure_art else _sprite_from_sheet(prop_sheet, cell_index, Vector3.ZERO, _structure_world_size(kind))
	if sprite != null:
		sprite.name = "IllustratedStateSprite"
		sprite.reparent(presentation)
		sprite.position = Vector3.ZERO
		sprite.modulate = modulation
		_set_structure_sprite_metadata(sprite, structure, kind, state, "state", structure_footprint)
		if use_player_structure_art:
			# The generated cutout is the single opaque operational silhouette. The
			# imported kit remains instantiated for provenance and future directional
			# replacement, but its render tree is hidden so the art never double-renders.
			structure.set_meta("operational_art_source", "generated_player_structure")
		elif state == "operational":
			structure.set_meta("operational_art_source", "sourced_or_sheet_fallback")
		else:
			structure.set_meta("operational_art_source", "sourced_or_sheet_fallback")
	if use_measured_3d_art:
		# The imported source model is already fitted to the same measured bounds
		# that created the active compound collision shell. Keep it as the single
		# operational silhouette so its actual depth, roofline, and contact shadow
		# are visible instead of hiding geometry behind a billboard.
		measured_3d_source.visible = true
		structure.set_meta("operational_art_source", "measured_3d_source")
	if state == "building":
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
	_add_contact_shadow(presentation, Vector3(0.0, 0.025, 0.10), Vector2(maxf(1.7, kind_size * 0.76), maxf(1.5, kind_size * 0.43)), 0.0)
	var base := _soft_box(presentation, "IllustratedPlotBase", Vector3(maxf(1.6, kind_size * 0.72), 0.04, maxf(1.6, kind_size * 0.58)), Vector3(0.0, 0.04, 0.0), Color(0.46, 0.56, 0.38, 0.22), true)
	# Keep the named plot-base hook for construction tooling, but do not leave a
	# translucent square under a finished cutout. The contact shadow above is the
	# only operational ground dressing; the slab remains faintly readable during
	# blueprint/build states where it communicates the player-owned footprint.
	base.material_override = _soft_material(Color(0.48, 0.58, 0.41, 0.12 if state != "operational" else 0.0), true, false)

func _structure_world_size(kind: String) -> float:
	return float(SanctuaryAssetCatalog.structure_definition(kind).get("world_size", 4.0))

func _finished_sprite_kind(kind: String) -> String:
	return str(SanctuaryAssetCatalog.structure_definition(kind).get("sprite_kind", "workshop"))

func _construction_progress(data: Dictionary) -> float:
	var total_hours := maxf(1.0, float(data.get("total_hours", 24.0)))
	return clampf(1.0 - float(data.get("remaining_hours", total_hours)) / total_hours, 0.0, 1.0)

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
	var edge := _add_rounded_patch(position + Vector3(0.0, -0.006, 0.0), size + Vector2(0.44, 0.42), edge_color, rotation_degrees)
	edge.name = "PackedEarthPathEdge"
	var core := _add_rounded_patch(position, size, core_color, rotation_degrees)
	core.name = "PackedEarthPath"

func _add_contact_shadow(parent: Node3D, position: Vector3, size: Vector2, rotation_degrees: float) -> MeshInstance3D:
	# Shallow alpha decals anchor billboard feet and structure bases without
	# adding bodies or participating in placement/occupancy calculations.
	return _create_rounded_patch(parent, "IllustratedContactShadow", position, size, PALETTE["contact_shadow"], rotation_degrees)

func _add_rounded_patch(position: Vector3, size: Vector2, color: Color, rotation_degrees: float) -> MeshInstance3D:
	return _create_rounded_patch(self, "SoftGroundPatch", position, size, color, rotation_degrees)

func _create_rounded_patch(parent: Node3D, node_name: String, position: Vector3, size: Vector2, color: Color, rotation_degrees: float) -> MeshInstance3D:
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
	patch.material_override = _ground_material(color, color.a < 0.999)
	parent.add_child(patch)
	return patch

func _ground_material(color: Color, transparent: bool) -> StandardMaterial3D:
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
