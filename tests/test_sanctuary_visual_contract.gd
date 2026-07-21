extends SceneTree

const MainScene = preload("res://main.tscn")
const AssetCatalog = preload("res://scripts/sanctuary_asset_catalog.gd")
const AssetMeasurement = preload("res://scripts/sanctuary_asset_measurement.gd")
const ContentRegistry = preload("res://scripts/content_registry.gd")
const SettlementGrid = preload("res://scripts/settlement_grid.gd")

const SAVE_SLOT := "qa_sanctuary_visual_contract"
const TEST_KIND := "storage_shed"
const STRUCTURE_KINDS := ["rain_cistern", "workshop", "archive", "livestock_pen", "storage_shed"]
const TEST_ID := "qa_sanctuary_visual_contract"
const PHYSICS_ID := "qa_sanctuary_collision_separation"
const PHYSICS_ORIGIN := Vector2i(28, 20)
const MIN_LAYOUT_OCCUPIED_CELL_DIFFERENCE := 12
const CARDINAL_FACINGS := ["north", "east", "south", "west"]
const REQUIRED_CONSTRUCTION_PHASES := ["foundation", "frame", "walls", "roof", "fittings"]
const PLAYER_LAYOUT_A := [
	{"kind": "workshop", "cell": Vector2i(3, 9), "rotation": 0},
	{"kind": "archive", "cell": Vector2i(-7, 8), "rotation": 0},
	{"kind": "rain_cistern", "cell": Vector2i(-12, -13), "rotation": 0},
	{"kind": "storage_shed", "cell": Vector2i(9, -13), "rotation": 0},
]
const PLAYER_LAYOUT_B := [
	{"kind": "workshop", "cell": Vector2i(-9, 8), "rotation": 0},
	{"kind": "archive", "cell": Vector2i(2, -13), "rotation": 3},
	{"kind": "rain_cistern", "cell": Vector2i(10, -13), "rotation": 0},
	{"kind": "storage_shed", "cell": Vector2i(4, 8), "rotation": 0},
]

var failures: Array[String] = []
var checks_run := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	checks_run += 1
	if condition:
		return true
	failures.append(message)
	push_error("SANCTUARY_VISUAL_CONTRACT_FAIL: " + message)
	return false

func _finish(world: Node) -> void:
	if is_instance_valid(world):
		world.queue_free()
	if failures.is_empty():
		print("SANCTUARY_VISUAL_CONTRACT_PASS checks=%d" % checks_run)
		quit(0)
		return
	print("SANCTUARY_VISUAL_CONTRACT_FAIL count=%d checks=%d" % [failures.size(), checks_run])
	for index in failures.size():
		print("  %02d. %s" % [index + 1, failures[index]])
	quit(1)

func _clear_test_saves() -> void:
	for path in [
		"user://%s.json" % SAVE_SLOT,
		"user://%s.backup.json" % SAVE_SLOT,
		"user://%s.tmp.json" % SAVE_SLOT,
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _approx(actual: float, expected: float, label: String, tolerance := 0.001) -> bool:
	return _check(absf(actual - expected) <= tolerance, "%s: expected %.4f, got %.4f" % [label, expected, actual])

func _array_pair_matches(value: Variant, expected: Vector2i, label: String) -> bool:
	if not value is Array or (value as Array).size() != 2:
		return _check(false, "%s must be a two-element Array, got %s" % [label, str(value)])
	var actual := value as Array
	return _check(
		int(actual[0]) == expected.x and int(actual[1]) == expected.y,
		"%s: expected [%d, %d], got %s" % [label, expected.x, expected.y, str(actual)]
	)

func _array_float_pair_matches(value: Variant, expected: Vector2, label: String) -> bool:
	if not value is Array or (value as Array).size() != 2:
		return _check(false, "%s must be a two-element Array, got %s" % [label, str(value)])
	var actual := value as Array
	return _check(
		absf(float(actual[0]) - expected.x) <= 0.001 and absf(float(actual[1]) - expected.y) <= 0.001,
		"%s: expected [%.4f, %.4f], got %s" % [label, expected.x, expected.y, str(actual)]
	)

func _array_triplet_matches(value: Variant, expected: Vector3, label: String) -> bool:
	if not value is Array or (value as Array).size() != 3:
		return _check(false, "%s must be a three-element Array, got %s" % [label, str(value)])
	var actual := value as Array
	return _check(
		absf(float(actual[0]) - expected.x) <= 0.001
			and absf(float(actual[1]) - expected.y) <= 0.001
			and absf(float(actual[2]) - expected.z) <= 0.001,
		"%s: expected %s, got %s" % [label, str(expected), str(actual)]
	)

func _positive_metadata_pair(value: Variant, label: String) -> Vector2:
	if not value is Array or (value as Array).size() != 2:
		_check(false, "%s must be a two-element Array, got %s" % [label, str(value)])
		return Vector2.ZERO
	var actual := value as Array
	var pair := Vector2(float(actual[0]), float(actual[1]))
	_check(pair.x > 0.0 and pair.y > 0.0, "%s must be positive, got %s" % [label, str(actual)])
	return pair

func _check_generated_sprite_contract(sprite: Sprite3D, label: String) -> Vector2:
	if sprite == null:
		return Vector2.ZERO
	_check(not str(sprite.get_meta("asset_id", "")).is_empty(), "%s must declare its generated asset id" % label)
	_array_triplet_matches(sprite.get_meta("ground_pivot", []), Vector3.ZERO, "%s ground pivot" % label)
	var visual_footprint := _positive_metadata_pair(sprite.get_meta("visual_footprint", []), "%s visual footprint" % label)
	_array_triplet_matches(sprite.get_meta("sorting_anchor", []), Vector3.ZERO, "%s sorting anchor" % label)
	_check(str(sprite.get_meta("sorting_anchor_mode", "")) == "feet", "%s must sort from its feet" % label)
	_check(str(sprite.get_meta("sorting_anchor_space", "")) == "sprite_local", "%s sorting space must be explicit" % label)
	_check(str(sprite.get_meta("visual_units", "")) == "world_meters", "%s visual units must be world metres" % label)
	var visual_size := _positive_metadata_pair(sprite.get_meta("visual_size", []), "%s visual size" % label)
	var opaque_value: Variant = sprite.get_meta("source_opaque_bounds", [])
	var opaque_bounds := Rect2()
	if _check(opaque_value is Array and (opaque_value as Array).size() == 4, "%s source opaque bounds metadata is required" % label):
		var opaque := opaque_value as Array
		opaque_bounds = Rect2(float(opaque[0]), float(opaque[1]), float(opaque[2]), float(opaque[3]))
		_check(
			opaque_bounds.position.x >= 0.0
				and opaque_bounds.position.y >= 0.0
				and opaque_bounds.size.x > 0.0
				and opaque_bounds.size.y > 0.0,
			"%s opaque bounds must be non-negative with positive size, got %s" % [label, str(opaque)]
		)
	_check(not sprite.centered, "%s must anchor its draw rectangle from an explicit feet offset" % label)
	_check(not sprite.sorting_use_aabb_center, "%s must not depth-sort from its transparent AABB centre" % label)
	_approx(sprite.sorting_offset, 0.0, "%s sorting offset" % label)
	_check(sprite.axis == Vector3.AXIS_Z, "%s must use the authored upright Sprite3D axis" % label)
	_check(sprite.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "%s must face the fixed 2.5D camera" % label)
	_check(not sprite.no_depth_test, "%s must participate in world occlusion" % label)
	var atlas := sprite.texture as AtlasTexture
	if _check(atlas != null, "%s must use an atlas region from the generated sheet" % label) and opaque_bounds.size.x > 0.0 and opaque_bounds.size.y > 0.0:
		var transparent_bottom := maxf(0.0, atlas.region.size.y - opaque_bounds.position.y - opaque_bounds.size.y)
		_approx(sprite.offset.x, -(opaque_bounds.position.x + opaque_bounds.size.x * 0.5), "%s feet offset x" % label)
		_approx(sprite.offset.y, -transparent_bottom, "%s feet offset y" % label)
		_approx(visual_size.x, opaque_bounds.size.x * sprite.pixel_size, "%s visible world width" % label)
		_approx(visual_size.y, opaque_bounds.size.y * sprite.pixel_size, "%s visible world height" % label)
	return visual_footprint

func _get_visual(world: Node, instance_id: String) -> Node3D:
	var visuals: Dictionary = world.get("settlement_visuals")
	var visual := visuals.get(instance_id) as Node3D
	if not _check(visual != null and is_instance_valid(visual), "renderer did not register visual '%s'" % instance_id):
		return null
	return visual

func _check_visibility(visual: Node3D, path: NodePath, expected_visible: bool, label: String) -> Node3D:
	if visual == null:
		return null
	var node := visual.get_node_or_null(path) as Node3D
	if not _check(node != null, "%s node is missing at %s" % [label, str(path)]):
		return null
	_check(node.is_visible_in_tree() == expected_visible, "%s must be %s" % [label, "visible" if expected_visible else "hidden"])
	return node

func _presentation_role_nodes(visual: Node3D, role_prefix: String) -> Array[Node3D]:
	var matches: Array[Node3D] = []
	if visual == null:
		return matches
	var presentation := visual.get_node_or_null("IllustratedStructurePresentation") as Node3D
	if not _check(presentation != null, "IllustratedStructurePresentation is missing"):
		return matches
	for child in presentation.get_children():
		var node := child as Node3D
		if node != null and not node.is_queued_for_deletion() and str(node.name).begins_with(role_prefix):
			matches.append(node)
	return matches

func _presentation_child_names(visual: Node3D) -> Array[String]:
	var names: Array[String] = []
	if visual == null:
		return names
	var presentation := visual.get_node_or_null("IllustratedStructurePresentation") as Node3D
	if presentation == null:
		return names
	for child in presentation.get_children():
		if not child.is_queued_for_deletion():
			names.append(str(child.name))
	return names

func _check_role_count(visual: Node3D, role_prefix: String, expected_count: int, label: String) -> Node3D:
	var nodes := _presentation_role_nodes(visual, role_prefix)
	_check(
		nodes.size() == expected_count,
		"%s expected %d illustrated layer(s), got %d; presentation children=%s" % [label, expected_count, nodes.size(), str(_presentation_child_names(visual))]
	)
	for node in nodes:
		_check(node.visible, "%s layer %s must be visible" % [label, node.name])
	return nodes[0] if not nodes.is_empty() else null

func _check_state_sprite(visual: Node3D, label: String) -> Sprite3D:
	var role := _check_role_count(visual, "IllustratedStateSprite", 1, "%s state sprite" % label)
	if role == null:
		return null
	var sprite := role as Sprite3D
	if not _check(sprite != null, "%s state layer must be a Sprite3D" % label):
		return null
	_check(sprite.texture != null, "%s state sprite must carry an illustrated texture" % label)
	_check_generated_sprite_contract(sprite, "%s state sprite" % label)
	return sprite

func _check_operational_art(visual: Node3D, label: String) -> Node3D:
	if str(visual.get_meta("operational_art_source", "")) == "measured_3d_source":
		var source := visual.get_node_or_null("FinishedSourceBuilding/ImportedBuilding") as Node3D
		if not _check(source != null and source.visible, "%s measured 3D source must be visible" % label):
			return null
		_check(str(source.get_meta("measurement_source", "")) == "imported_mesh_bounds", "%s must expose imported mesh measurement provenance" % label)
		var measurement: Dictionary = visual.get_meta("source_measurement", {})
		_check(bool(measurement.get("valid", false)), "%s must retain its valid source measurement" % label)
		var expected_scale := float(measurement.get("fit_scale", 0.0))
		_approx(source.scale.x, expected_scale, "%s measured source scale" % label)
		_approx(source.scale.y, expected_scale, "%s measured source scale y" % label)
		_approx(source.scale.z, expected_scale, "%s measured source scale z" % label)
		return source
	var sprite := _check_state_sprite(visual, label)
	_check(str(sprite.get_meta("measurement_source", "")) == "imported_mesh_bounds", "%s fallback art must retain measured source provenance" % label)
	_check(not str(sprite.get_meta("measurement_source_asset", "")).is_empty(), "%s fallback art must retain measured source identity" % label)
	_check_structure_sprite_binding(visual, sprite, str(visual.get_meta("structure_kind", "")), "operational", "state", "%s fallback sprite" % label)
	return sprite

func _check_activity_dressing_contract(visual: Node3D, label: String) -> void:
	if visual == null:
		return
	var presentation := visual.get_node_or_null("IllustratedStructurePresentation") as Node3D
	if not _check(presentation != null, "%s requires an illustrated presentation root" % label):
		return
	var dressing := presentation.get_node_or_null("StructureActivityDressing") as Node3D
	if not _check(dressing != null, "%s requires measured structure activity dressing" % label):
		return
	_check(bool(dressing.get_meta("presentation_only", false)), "%s activity dressing must be presentation-only" % label)
	_check(str(dressing.get_meta("collision_authority", "")) == "none", "%s activity dressing must not own collision" % label)
	_check(dressing.find_children("*", "StaticBody3D", true, false).is_empty(), "%s activity dressing must not contain physics bodies" % label)
	var mesh_count := 0
	for mesh_value in dressing.find_children("*", "MeshInstance3D", true, false):
		var mesh := mesh_value as MeshInstance3D
		if mesh == null:
			continue
		mesh_count += 1
		_check(bool(mesh.get_meta("presentation_only", false)), "%s activity mesh %s must be presentation-only" % [label, mesh.name])
		_check(int(mesh.get_meta("collision_layer", 0)) == 0, "%s activity mesh %s must declare collision layer 0" % [label, mesh.name])
	_check(mesh_count > 0, "%s activity dressing must expose at least one authored activity prop" % label)

func _atlas_region(sprite: Sprite3D) -> Rect2:
	if sprite == null:
		return Rect2()
	var atlas := sprite.texture as AtlasTexture
	return atlas.region if atlas != null else Rect2()

func _world_horizontal_size(collision: CollisionShape3D, shape: BoxShape3D) -> Vector2:
	var basis := collision.global_transform.basis
	var world_x := absf(basis.x.x) * shape.size.x + absf(basis.y.x) * shape.size.y + absf(basis.z.x) * shape.size.z
	var world_z := absf(basis.x.z) * shape.size.x + absf(basis.y.z) * shape.size.y + absf(basis.z.z) * shape.size.z
	return Vector2(world_x, world_z)

func _collision_size_from_authored_footprint(asset_definition: Dictionary, footprint: Vector2i, kind := "", rotation := 0) -> Vector3:
	if str(kind).is_empty():
		_check(false, "collision expectations must identify the measured structure kind")
		return Vector3.ZERO
	var authored_value: Array = ContentRegistry.structure_definition(kind).get("footprint", [footprint.x, footprint.y])
	var authored_footprint := Vector2i(int(authored_value[0]), int(authored_value[1]))
	var measured := AssetMeasurement.structure_measurement(kind, authored_footprint)
	if not bool(measured.get("valid", false)):
		_check(false, "%s collision expectation requires a valid imported source measurement" % kind)
		return Vector3.ZERO
	var size: Vector3 = measured.get("fitted_size", Vector3.ONE)
	if rotation % 2 == 1:
		return Vector3(size.z, size.y, size.x)
	return size

func _check_runtime_measured_collision_shapes(body: StaticBody3D, components: Array, label: String) -> void:
	if not _check(body != null, "%s collision body is required" % label):
		return
	var shapes := body.find_children("Compound_*", "CollisionShape3D", false, false)
	if not _check(shapes.size() == components.size(), "%s runtime shape count must equal measured component count" % label):
		return
	for index in components.size():
		var component := components[index] as Dictionary
		var collision := shapes[index] as CollisionShape3D
		if not _check(collision != null, "%s measured component %d must instantiate a CollisionShape3D" % [label, index]):
			continue
		_check(str(collision.get_meta("measurement_source", "")) == "imported_mesh_bounds", "%s component %d must declare imported mesh measurement provenance" % [label, index])
		var center_data: Array = component.get("center", [])
		var size_data: Array = component.get("size", [])
		var expected_center := Vector3(float(center_data[0]), float(center_data[1]), float(center_data[2]))
		var expected_size := Vector3(float(size_data[0]), float(size_data[1]), float(size_data[2]))
		_array_triplet_matches([collision.position.x, collision.position.y, collision.position.z], expected_center, "%s component %d measured center" % [label, index])
		var box := collision.shape as BoxShape3D
		if not _check(box != null, "%s component %d must use the measured box shell" % [label, index]):
			continue
		_array_triplet_matches([box.size.x, box.size.y, box.size.z], expected_size, "%s component %d measured size" % [label, index])

func _descriptor_rect(descriptor: Dictionary, label: String) -> Rect2:
	var center_value: Variant = descriptor.get("center", [])
	var size_value: Variant = descriptor.get("size", [])
	var center_valid := _check(
		center_value is Array and ((center_value as Array).size() == 2 or (center_value as Array).size() == 3),
		"%s center must be local [x, z] or [x, y, z], got %s" % [label, str(center_value)]
	)
	var size_valid := _check(
		size_value is Array and ((size_value as Array).size() == 2 or (size_value as Array).size() == 3),
		"%s size must be [width, depth] or [width, height, depth], got %s" % [label, str(size_value)]
	)
	if not center_valid or not size_valid:
		return Rect2()
	var center_data := center_value as Array
	var size_data := size_value as Array
	var center := Vector2(float(center_data[0]), float(center_data[2] if center_data.size() == 3 else center_data[1]))
	var size := Vector2(float(size_data[0]), float(size_data[2] if size_data.size() == 3 else size_data[1]))
	if not _check(size.x > 0.0 and size.y > 0.0, "%s size must be positive, got %s" % [label, str(size_data)]):
		return Rect2()
	return Rect2(center - size * 0.5, size)

func _rect_inside_authored_footprint(rect: Rect2, footprint: Vector2i) -> bool:
	var half_size := Vector2(float(footprint.x), float(footprint.y)) * 0.5
	return (
		rect.position.x >= -half_size.x - 0.001
		and rect.position.y >= -half_size.y - 0.001
		and rect.end.x <= half_size.x + 0.001
		and rect.end.y <= half_size.y + 0.001
	)

func _rect_touches_facing_edge(rect: Rect2, footprint: Vector2i, facing: String) -> bool:
	var half_size := Vector2(float(footprint.x), float(footprint.y)) * 0.5
	match facing:
		"north":
			return rect.position.y <= -half_size.y + 0.001 and rect.end.y >= -half_size.y - 0.001
		"east":
			return rect.position.x <= half_size.x + 0.001 and rect.end.x >= half_size.x - 0.001
		"south":
			return rect.position.y <= half_size.y + 0.001 and rect.end.y >= half_size.y - 0.001
		"west":
			return rect.position.x <= -half_size.x + 0.001 and rect.end.x >= -half_size.x - 0.001
	return false

func _cardinal_facing_name(value: Variant, label: String) -> String:
	if not _check(value is Array and (value as Array).size() == 3, "%s facing must be a local [x, y, z] vector" % label):
		return ""
	var data := value as Array
	var facing := Vector3(float(data[0]), float(data[1]), float(data[2]))
	_check(absf(facing.y) <= 0.001, "%s facing must stay on the authored ground plane" % label)
	if facing.distance_to(Vector3(0.0, 0.0, -1.0)) <= 0.001:
		return "north"
	if facing.distance_to(Vector3(1.0, 0.0, 0.0)) <= 0.001:
		return "east"
	if facing.distance_to(Vector3(0.0, 0.0, 1.0)) <= 0.001:
		return "south"
	if facing.distance_to(Vector3(-1.0, 0.0, 0.0)) <= 0.001:
		return "west"
	_check(false, "%s facing must be a unit cardinal vector, got %s" % [label, str(data)])
	return ""

func _expected_quarter_facing(quarter_turn: int) -> Vector3:
	match posmod(quarter_turn, 4):
		0:
			return Vector3(0.0, 0.0, 1.0)
		1:
			return Vector3(1.0, 0.0, 0.0)
		2:
			return Vector3(0.0, 0.0, -1.0)
	return Vector3(-1.0, 0.0, 0.0)

func _check_authored_zone(
	asset_definition: Dictionary,
	zone_kind: String,
	footprint: Vector2i,
	kind: String,
	required := true
) -> Dictionary:
	var value: Variant = asset_definition.get("access_zones", [])
	if not _check(value is Array, "%s access_zones must be an Array" % kind):
		return {}
	var matches: Array[Dictionary] = []
	for zone_value in value as Array:
		if zone_value is Dictionary and str((zone_value as Dictionary).get("kind", "")) == zone_kind:
			matches.append(zone_value as Dictionary)
	if matches.is_empty():
		if required:
			_check(false, "%s must define an explicit %s access zone in authored local space" % [kind, zone_kind])
		return {}
	_check(true, "%s exposes an explicit %s access zone" % [kind, zone_kind])
	var descriptor := matches[0]
	var zone_id := str(descriptor.get("id", ""))
	_check(not zone_id.is_empty(), "%s %s access zone must have a stable id" % [kind, zone_kind])
	_check(not str(descriptor.get("visible_feature_id", "")).is_empty(), "%s %s access zone must name its visible asset feature" % [kind, zone_kind])
	_check(bool(descriptor.get("must_be_visible_in_asset", false)), "%s %s access zone must require a visible authored feature" % [kind, zone_kind])
	var facing := _cardinal_facing_name(descriptor.get("facing", []), "%s %s access zone" % [kind, zone_kind])
	var rect := _descriptor_rect(descriptor, "%s %s access zone" % [kind, zone_kind])
	if rect.has_area() and CARDINAL_FACINGS.has(facing):
		var footprint_rect := Rect2(
			-Vector2(float(footprint.x), float(footprint.y)) * 0.5,
			Vector2(float(footprint.x), float(footprint.y))
		)
		_check(rect.intersects(footprint_rect, true), "%s %s access zone must meet its authored footprint" % [kind, zone_kind])
		_check(
			_rect_touches_facing_edge(rect, footprint, facing),
			"%s %s access zone must cross its declared %s footprint edge" % [kind, zone_kind, facing]
		)
	for quarter_turn in 4:
		var transformed_zones: Array = AssetCatalog.structure_access_zones(kind, quarter_turn)
		var transformed := {}
		for transformed_value in transformed_zones:
			if transformed_value is Dictionary and str((transformed_value as Dictionary).get("id", "")) == zone_id:
				transformed = transformed_value as Dictionary
				break
		if not _check(not transformed.is_empty(), "%s %s access zone must survive quarter-turn %d" % [kind, zone_kind, quarter_turn]):
			continue
		_check(int(transformed.get("quarter_turn", -1)) == quarter_turn, "%s %s access zone must declare transformed quarter-turn %d" % [kind, zone_kind, quarter_turn])
		var expected_variant := AssetCatalog.structure_directional_variant(kind, quarter_turn)
		_check(str(transformed.get("variant_id", "")) == str(expected_variant.get("variant_id", "")), "%s %s access zone must bind quarter-turn %d variant" % [kind, zone_kind, quarter_turn])
		var transformed_facing := _cardinal_facing_name(transformed.get("facing", []), "%s %s quarter-turn %d" % [kind, zone_kind, quarter_turn])
		var base_facing_index := CARDINAL_FACINGS.find(facing)
		if base_facing_index >= 0:
			var expected_facing := str(CARDINAL_FACINGS[posmod(base_facing_index - quarter_turn, 4)])
			_check(transformed_facing == expected_facing, "%s %s quarter-turn %d facing must rotate to %s" % [kind, zone_kind, quarter_turn, expected_facing])
	return {"id": zone_id, "facing": facing, "rect": rect}

func _check_quarter_turn_variants(
	asset_definition: Dictionary,
	kind: String,
	base_asset_id: String,
	global_variant_ids: Dictionary
) -> void:
	var value: Variant = asset_definition.get("directional_variants", [])
	if not _check(
		value is Array and (value as Array).size() == 4,
		"%s must define exactly four directional quarter-turn variants" % kind
	):
		return
	var variants := value as Array
	var local_asset_ids := {}
	var local_asset_paths := {}
	var local_variant_ids := {}
	var facings := {}
	for quarter_turn in 4:
		var variant_value: Variant = variants[quarter_turn]
		if not _check(variant_value is Dictionary, "%s quarter-turn %d variant must be a Dictionary" % [kind, quarter_turn]):
			continue
		var variant := variant_value as Dictionary
		_check(
			int(variant.get("quarter_turn", -1)) == quarter_turn,
			"%s variant index %d must declare quarter_turn=%d" % [kind, quarter_turn, quarter_turn]
		)
		var variant_asset_id := str(variant.get("asset_id", ""))
		if _check(not variant_asset_id.is_empty(), "%s quarter-turn %d needs a directional asset id" % [kind, quarter_turn]):
			_check(
				not local_asset_ids.has(variant_asset_id),
				"%s quarter-turn %d reuses directional asset '%s'" % [kind, quarter_turn, variant_asset_id]
			)
			_check(
				not global_variant_ids.has(variant_asset_id),
				"%s quarter-turn %d shares directional asset '%s' with %s" % [kind, quarter_turn, variant_asset_id, str(global_variant_ids.get(variant_asset_id, "another structure"))]
			)
			local_asset_ids[variant_asset_id] = true
			global_variant_ids[variant_asset_id] = "%s r%d" % [kind, quarter_turn]
			_check(variant_asset_id.begins_with(base_asset_id + "/"), "%s quarter-turn %d asset must live under its unique base asset namespace" % [kind, quarter_turn])
		var variant_asset_path := str(variant.get("asset_path", ""))
		if _check(not variant_asset_path.is_empty(), "%s quarter-turn %d needs a production asset path" % [kind, quarter_turn]):
			_check(ResourceLoader.exists(variant_asset_path), "%s quarter-turn %d production asset path must resolve" % [kind, quarter_turn])
			_check(not local_asset_paths.has(variant_asset_path), "%s quarter-turn %d must not reuse its directional texture" % [kind, quarter_turn])
			local_asset_paths[variant_asset_path] = true
		var variant_id := str(variant.get("variant_id", ""))
		if _check(not variant_id.is_empty(), "%s quarter-turn %d needs a stable variant id" % [kind, quarter_turn]):
			_check(not local_variant_ids.has(variant_id), "%s quarter-turn variant id '%s' must be unique" % [kind, variant_id])
			local_variant_ids[variant_id] = true
		var expected_facing := _expected_quarter_facing(quarter_turn)
		_array_triplet_matches(variant.get("facing", []), expected_facing, "%s quarter-turn %d facing" % [kind, quarter_turn])
		facings[str(expected_facing)] = true
		var catalog_variant := AssetCatalog.structure_directional_variant(kind, quarter_turn)
		_check(catalog_variant == variant, "%s quarter-turn %d catalog lookup must return the authored variant" % [kind, quarter_turn])
		_check(AssetCatalog.structure_variant_asset_id(kind, quarter_turn) == variant_asset_id, "%s quarter-turn %d asset lookup must preserve identity" % [kind, quarter_turn])
	_check(local_asset_ids.size() == 4, "%s must use four distinct directional assets" % kind)
	_check(local_asset_paths.size() == 4, "%s must use four distinct directional textures" % kind)
	_check(local_variant_ids.size() == 4, "%s must use four distinct directional variant ids" % kind)
	_check(facings.size() == 4, "%s directional variants must cover all four quarter-turn facings" % kind)

func _check_compound_collision_components(
	asset_definition: Dictionary,
	kind: String,
	footprint: Vector2i,
	door_zone: Dictionary,
	service_zone: Dictionary
) -> void:
	_check(not str(asset_definition.get("collision_profile_id", "")).is_empty(), "%s must define a stable compound collision profile id" % kind)
	var measurement := AssetMeasurement.structure_measurement(kind, footprint)
	if not _check(bool(measurement.get("valid", false)), "%s must be measured from an imported source scene" % kind):
		return
	var value := AssetMeasurement.structure_collision_components(kind, footprint)
	if not _check(value.size() >= 2, "%s measured source must produce at least two compound collision components" % kind):
		return
	var component_ids := {}
	var door_rect: Rect2 = door_zone.get("rect", Rect2())
	var service_rect: Rect2 = service_zone.get("rect", Rect2())
	var door_clearance := door_rect.grow(-minf(door_rect.size.x, door_rect.size.y) * 0.12) if door_rect.has_area() else Rect2()
	var service_clearance := service_rect.grow(-minf(service_rect.size.x, service_rect.size.y) * 0.12) if service_rect.has_area() else Rect2()
	for index in value.size():
		var component_value: Variant = value[index]
		if not _check(component_value is Dictionary, "%s collision component %d must be a Dictionary" % [kind, index]):
			continue
		var component := component_value as Dictionary
		var component_id := str(component.get("id", ""))
		if _check(not component_id.is_empty(), "%s collision component %d needs a stable id" % [kind, index]):
			_check(not component_ids.has(component_id), "%s collision component id '%s' must be unique" % [kind, component_id])
			component_ids[component_id] = true
		var shape_type := str(component.get("shape", ""))
		_check(["box", "cylinder"].has(shape_type), "%s collision component %d shape must be box or cylinder" % [kind, index])
		_check(bool(component.get("blocks_movement", false)), "%s collision component %d must explicitly block movement" % [kind, index])
		var center_value: Variant = component.get("center", [])
		var center_valid := _check(center_value is Array and (center_value as Array).size() == 3, "%s collision component %d center must be [x, y, z]" % [kind, index])
		var center := Vector3.ZERO
		if center_valid:
			var center_data := center_value as Array
			center = Vector3(float(center_data[0]), float(center_data[1]), float(center_data[2]))
		var rect := Rect2()
		var component_height := 0.0
		if shape_type == "box":
			var size_value: Variant = component.get("size", [])
			if _check(size_value is Array and (size_value as Array).size() == 3, "%s box collision component %d size must be [width, height, depth]" % [kind, index]):
				var size_data := size_value as Array
				var size := Vector3(float(size_data[0]), float(size_data[1]), float(size_data[2]))
				if _check(size.x > 0.0 and size.y > 0.0 and size.z > 0.0, "%s box collision component %d size must be positive" % [kind, index]):
					component_height = size.y
					rect = Rect2(Vector2(center.x, center.z) - Vector2(size.x, size.z) * 0.5, Vector2(size.x, size.z))
		elif shape_type == "cylinder":
			var radius := float(component.get("radius", 0.0))
			component_height = float(component.get("height", 0.0))
			_check(radius > 0.0, "%s cylinder collision component %d radius must be positive" % [kind, index])
			_check(component_height > 0.0, "%s cylinder collision component %d height must be positive" % [kind, index])
			_check(str(component.get("axis", "")) == "y", "%s cylinder collision component %d must use the authored Y axis" % [kind, index])
			if radius > 0.0 and component_height > 0.0:
				rect = Rect2(Vector2(center.x, center.z) - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
		if center_valid and component_height > 0.0:
			_approx(center.y - component_height * 0.5, 0.0, "%s collision component %d ground base" % [kind, index])
		if not rect.has_area():
			continue
		_check(
			_rect_inside_authored_footprint(rect, footprint),
			"%s collision component %d %s must fit authored footprint %s" % [kind, index, str(rect), str(footprint)]
		)
		if door_clearance.has_area():
			_check(
				rect.intersection(door_clearance).get_area() <= 0.001,
				"%s collision component %d must leave the authored door clearance open" % [kind, index]
			)
		if service_clearance.has_area():
			_check(
				rect.intersection(service_clearance).get_area() <= 0.001,
				"%s collision component %d must leave the authored service zone accessible" % [kind, index]
			)
	for quarter_turn in 4:
		var requested := Vector2i(footprint.y, footprint.x) if quarter_turn % 2 == 1 else footprint
		var transformed_size := measurement.get("fitted_size", Vector3.ZERO) as Vector3
		if quarter_turn % 2 == 1:
			transformed_size = Vector3(transformed_size.z, transformed_size.y, transformed_size.x)
		_check(transformed_size.x > 0.0 and transformed_size.z > 0.0, "%s quarter-turn %d must preserve measured dimensions" % [kind, quarter_turn])
		_check(requested.x > 0 and requested.y > 0, "%s quarter-turn %d must preserve its grid claim" % [kind, quarter_turn])

func _check_construction_components(asset_definition: Dictionary, kind: String, footprint: Vector2i, cost: Dictionary) -> void:
	var value: Variant = asset_definition.get("construction_components", [])
	if not _check(
		value is Array and (value as Array).size() >= REQUIRED_CONSTRUCTION_PHASES.size(),
		"%s must define additive construction component metadata for foundation, frame, walls, roof, and fittings" % kind
	):
		return
	var component_ids := {}
	var construction_asset_ids := {}
	var phases := {}
	var material_totals := {}
	for index in (value as Array).size():
		var component_value: Variant = (value as Array)[index]
		if not _check(component_value is Dictionary, "%s construction component %d must be a Dictionary" % [kind, index]):
			continue
		var component := component_value as Dictionary
		var component_id := str(component.get("id", ""))
		if _check(not component_id.is_empty(), "%s construction component %d needs a stable id" % [kind, index]):
			_check(not component_ids.has(component_id), "%s construction component id '%s' must be unique" % [kind, component_id])
			component_ids[component_id] = true
		var component_asset_id := str(component.get("asset_id", ""))
		if _check(not component_asset_id.is_empty(), "%s construction component %d needs its own asset id" % [kind, index]):
			_check(not construction_asset_ids.has(component_asset_id), "%s construction asset '%s' must identify one additive part" % [kind, component_asset_id])
			construction_asset_ids[component_asset_id] = true
		var phase := str(component.get("phase", ""))
		if _check(REQUIRED_CONSTRUCTION_PHASES.has(phase), "%s construction component %d has unsupported phase '%s'" % [kind, index, phase]):
			phases[phase] = true
		var material := str(component.get("material", ""))
		var amount := int(component.get("amount", 0))
		if _check(cost.has(material), "%s construction component %d material '%s' must exist in its gameplay recipe" % [kind, index, material]):
			_check(amount > 0, "%s construction component %d material amount must be positive" % [kind, index])
			material_totals[material] = int(material_totals.get(material, 0)) + amount
		var rect := _descriptor_rect(component, "%s construction component %d" % [kind, index])
		if rect.has_area():
			_check(
				_rect_inside_authored_footprint(rect, footprint),
				"%s construction component %d %s must fit authored footprint %s" % [kind, index, str(rect), str(footprint)]
			)
	for phase_value in REQUIRED_CONSTRUCTION_PHASES:
		var phase := str(phase_value)
		_check(phases.has(phase), "%s construction metadata must include the %s phase" % [kind, phase])
	for material_value in cost:
		var material := str(material_value)
		_check(
			int(material_totals.get(material, 0)) == int(cost[material]),
			"%s construction parts must allocate all %s: expected %d, got %d" % [kind, material, int(cost[material]), int(material_totals.get(material, 0))]
		)

func _check_player_structure_authoring_gate() -> void:
	# Renderer-independent authoring contract. Every descriptor lives in the
	# unrotated footprint's local x/z space; quarter-turn metadata identifies the
	# four directional illustrations, while the structure root remains the sole
	# owner of world rotation. This makes art, access, collision, construction,
	# and grid occupancy independently inspectable before a frame is rendered.
	var base_asset_owners := {}
	var global_variant_ids := {}
	for kind_value in STRUCTURE_KINDS:
		var kind := str(kind_value)
		var content_definition: Dictionary = ContentRegistry.structure_definition(kind)
		var authored_data: Array = content_definition.get("footprint", [1, 1])
		var authored_footprint := Vector2i(int(authored_data[0]), int(authored_data[1]))
		var asset_definition := AssetCatalog.structure_definition(kind)
		var asset_id := str(asset_definition.get("asset_id", ""))
		if _check(not asset_id.is_empty(), "%s must define a stable operational asset id" % kind):
			_check(
				not base_asset_owners.has(asset_id),
				"%s must not reuse operational asset '%s' owned by %s" % [kind, asset_id, str(base_asset_owners.get(asset_id, "another structure"))]
			)
			base_asset_owners[asset_id] = kind
		# Cisterns expose service/maintenance access but have no human doorway;
		# enclosed buildings must describe both a traversable door and service side.
		var door_zone := _check_authored_zone(asset_definition, "door", authored_footprint, kind, kind != "rain_cistern")
		var service_zone := _check_authored_zone(asset_definition, "service", authored_footprint, kind)
		if not door_zone.is_empty() and not service_zone.is_empty():
			_check(str(door_zone.get("id", "")) != str(service_zone.get("id", "")), "%s door and service zones need distinct ids" % kind)
		_check_quarter_turn_variants(asset_definition, kind, asset_id, global_variant_ids)
		_check_compound_collision_components(asset_definition, kind, authored_footprint, door_zone, service_zone)
		_check_construction_components(asset_definition, kind, authored_footprint, content_definition.get("cost", {}))

func _check_structure_sprite_binding(
	visual: Node3D,
	sprite: Sprite3D,
	kind: String,
	state: String,
	layer: String,
	label: String
) -> void:
	if visual == null or sprite == null:
		return
	var local_footprint: Array = visual.get_meta("local_collision_footprint", [])
	if not _check(local_footprint.size() == 2, "%s needs the authored compound footprint before presentation is bound" % label):
		return
	var visual_footprint := _positive_metadata_pair(sprite.get_meta("visual_footprint", []), "%s visual footprint binding" % label)
	_approx(visual_footprint.x, float(local_footprint[0]), "%s visual footprint local x" % label)
	_approx(visual_footprint.y, float(local_footprint[1]), "%s visual footprint local z" % label)
	_check(str(sprite.get_meta("structure_asset_id", "")) == str(visual.get_meta("asset_id", "")), "%s must inherit the structure asset id" % label)
	var expected_variant := AssetCatalog.structure_directional_variant(kind, int(visual.get_meta("rotation_quarter_turns", 0)))
	_check(str(sprite.get_meta("structure_directional_variant_id", "")) == str(expected_variant.get("variant_id", "")), "%s must bind the catalog directional variant" % label)
	_check(str(sprite.get_meta("structure_directional_asset_id", "")) == str(expected_variant.get("asset_id", "")), "%s must bind the catalog directional asset" % label)
	_check(str(sprite.get_meta("structure_kind", "")) == kind, "%s must identify structure kind %s" % [label, kind])
	_check(str(sprite.get_meta("construction_state", "")) == state, "%s must identify construction state %s" % [label, state])
	_check(str(sprite.get_meta("presentation_layer", "")) == layer, "%s must identify presentation layer %s" % [label, layer])
	_check(sprite.position.distance_to(Vector3.ZERO) <= 0.001, "%s feet origin must stay at the structure-local origin" % label)
	_approx(sprite.global_position.x, visual.global_position.x, "%s world feet x" % label)
	_approx(sprite.global_position.z, visual.global_position.z, "%s world feet z" % label)

func _check_rotation_and_collision_contract(world: Node, session: Node, origin: Vector2i, rotation: int) -> Node3D:
	var instance_id := "%s_rotation_%d" % [TEST_ID, rotation]
	var data := {
		"id": instance_id,
		"kind": TEST_KIND,
		"cell": [origin.x, origin.y],
		"rotation": rotation,
		"state": "operational",
		"remaining_hours": 0.0,
		"total_hours": 24.0,
		"delivered_materials": {"wood": 10, "stone": 4, "plank": 3},
	}
	world.call("_spawn_structure_visual", instance_id, data)
	await process_frame
	var visual := _get_visual(world, instance_id)
	if visual == null:
		return null

	var authored_data: Array = ContentRegistry.structure_definition(TEST_KIND).get("footprint", [1, 1])
	var authored_footprint := Vector2i(int(authored_data[0]), int(authored_data[1]))
	var requested_footprint := Vector2i(authored_footprint.y, authored_footprint.x) if rotation % 2 == 1 else authored_footprint
	var session_footprint: Vector2i = session.call("_structure_footprint", TEST_KIND, rotation)
	_check(session_footprint == requested_footprint, "rotation %d session footprint must preserve requested quarter-turn" % rotation)

	# The structure root owns rotation. Local geometry therefore stays in the
	# authored orientation; its transformed world extents follow the rotated
	# grid footprint. Checking both sides catches a double-swap at 90/270 degrees.
	var asset_definition := AssetCatalog.structure_definition(TEST_KIND)
	var expected_local_collision := _collision_size_from_authored_footprint(asset_definition, authored_footprint, TEST_KIND)
	var expected_world_collision := _collision_size_from_authored_footprint(asset_definition, requested_footprint, TEST_KIND, rotation)
	var measured := AssetMeasurement.structure_measurement(TEST_KIND, authored_footprint)
	_check(bool(measured.get("valid", false)), "rotation %d must use a measured source asset" % rotation)
	var measured_size: Vector3 = measured.get("fitted_size", Vector3.ZERO)
	_approx(measured_size.x, expected_local_collision.x, "rotation %d measured authored x" % rotation)
	_approx(measured_size.y, expected_local_collision.y, "rotation %d measured authored y" % rotation)
	_approx(measured_size.z, expected_local_collision.z, "rotation %d measured authored z" % rotation)
	_array_pair_matches(visual.get_meta("grid_footprint", []), requested_footprint, "rotation %d grid_footprint" % rotation)
	_array_float_pair_matches(
		visual.get_meta("collision_footprint", []),
		Vector2(expected_world_collision.x, expected_world_collision.z),
		"rotation %d collision_footprint metadata" % rotation
	)
	_array_triplet_matches(visual.get_meta("ground_pivot", []), Vector3.ZERO, "rotation %d ground_pivot" % rotation)
	var expected_asset_id := str(asset_definition.get("asset_id", ""))
	_check(not expected_asset_id.is_empty(), "asset catalog must define an asset_id for %s" % TEST_KIND)
	_check(str(visual.get_meta("asset_id", "")) == expected_asset_id, "rotation %d asset_id must come from the asset catalog" % rotation)

	var expected_position := SettlementGrid.footprint_center_to_world(origin, requested_footprint)
	_approx(visual.position.x, expected_position.x, "rotation %d footprint-center x" % rotation)
	_approx(visual.position.z, expected_position.z, "rotation %d footprint-center z" % rotation)
	_approx(sin(visual.rotation.y), sin(float(rotation) * PI * 0.5), "rotation %d visual angle sin" % rotation)
	_approx(cos(visual.rotation.y), cos(float(rotation) * PI * 0.5), "rotation %d visual angle cos" % rotation)

	var body := visual.get_node_or_null("StructureCollisionBody") as StaticBody3D
	var compound_shapes := body.find_children("Compound_*", "CollisionShape3D", false, false) if body != null else []
	if not _check(body != null and compound_shapes.size() > 0, "rotation %d active compound collision body is required" % rotation):
		return visual
	_check(int(visual.get_meta("compound_collision_component_count", 0)) == compound_shapes.size(), "rotation %d compound collision metadata must match runtime shapes" % rotation)
	_check(str(body.get_meta("collision_profile_id", "")) == str(asset_definition.get("collision_profile_id", "")), "rotation %d compound profile id must match catalog" % rotation)
	var local_footprint: Array = visual.get_meta("local_collision_footprint", [])
	_array_float_pair_matches(local_footprint, Vector2(expected_local_collision.x, expected_local_collision.z), "rotation %d local compound footprint" % rotation)
	_array_triplet_matches(visual.get_meta("collision_fit_scale", []), Vector3.ONE, "rotation %d collision components must not be rescaled after root rotation" % rotation)
	_check_runtime_measured_collision_shapes(body, AssetMeasurement.structure_collision_components(TEST_KIND, authored_footprint), "rotation %d" % rotation)
	_check_operational_art(visual, "rotation %d operational" % rotation)
	_check_activity_dressing_contract(visual, "rotation %d" % rotation)
	return visual

func _check_all_asset_collision_contract(world: Node) -> void:
	# Storage Shed rotation QA above exercises the complete gameplay path. This
	# second pass proves every authored player structure consumes the same catalog
	# entry for sprite identity, canonical collision shape, and rotated world
	# footprint; a future building cannot silently fall back to a mismatched box.
	for kind_value in STRUCTURE_KINDS:
		var kind := str(kind_value)
		var content_definition: Dictionary = ContentRegistry.structure_definition(kind)
		var authored_data: Array = content_definition.get("footprint", [1, 1])
		var authored_footprint := Vector2i(int(authored_data[0]), int(authored_data[1]))
		var asset_definition := AssetCatalog.structure_definition(kind)
		var expected_asset_id := str(asset_definition.get("asset_id", ""))
		_check(not expected_asset_id.is_empty(), "%s must define an illustrated asset id" % kind)
		var measured_asset := AssetMeasurement.structure_measurement(kind, authored_footprint)
		_check(bool(measured_asset.get("valid", false)), "%s must have a valid measured source asset" % kind)
		for rotation in 4:
			var instance_id := "qa_asset_contract_%s_%d" % [kind, rotation]
			var requested_footprint := Vector2i(authored_footprint.y, authored_footprint.x) if rotation % 2 == 1 else authored_footprint
			var data := {
				"id": instance_id,
				"kind": kind,
				"cell": [0, 0],
				"rotation": rotation,
				"state": "operational",
				"remaining_hours": 0.0,
				"total_hours": 24.0,
				"delivered_materials": content_definition.get("cost", {}).duplicate(true),
			}
			world.call("_spawn_structure_visual", instance_id, data)
			await process_frame
			var visuals: Dictionary = world.get("settlement_visuals")
			var visual := visuals.get(instance_id) as Node3D
			if not _check(visual != null and is_instance_valid(visual), "%s rotation %d must spawn" % [kind, rotation]):
				continue
			var local_expected := _collision_size_from_authored_footprint(asset_definition, authored_footprint, kind)
			var world_expected := _collision_size_from_authored_footprint(asset_definition, requested_footprint, kind, rotation)
			var measured_size: Vector3 = measured_asset.get("fitted_size", Vector3.ZERO)
			_approx(measured_size.x, local_expected.x, "%s rotation %d measured authored x" % [kind, rotation])
			_approx(measured_size.y, local_expected.y, "%s rotation %d measured authored y" % [kind, rotation])
			_approx(measured_size.z, local_expected.z, "%s rotation %d measured authored z" % [kind, rotation])
			_array_pair_matches(visual.get_meta("grid_footprint", []), requested_footprint, "%s rotation %d grid footprint" % [kind, rotation])
			_array_float_pair_matches(visual.get_meta("collision_footprint", []), Vector2(world_expected.x, world_expected.z), "%s rotation %d collision metadata" % [kind, rotation])
			_check(str(visual.get_meta("asset_id", "")) == expected_asset_id, "%s rotation %d asset id must match catalog" % [kind, rotation])
			var body := visual.get_node_or_null("StructureCollisionBody") as StaticBody3D
			var compound_shapes := body.find_children("Compound_*", "CollisionShape3D", false, false) if body != null else []
			var measured_components := AssetMeasurement.structure_collision_components(kind, authored_footprint)
			_check(compound_shapes.size() == measured_components.size(), "%s rotation %d must instantiate every measured collision component" % [kind, rotation])
			_check(int(visual.get_meta("compound_collision_component_count", 0)) == compound_shapes.size(), "%s rotation %d compound count must match metadata" % [kind, rotation])
			_array_float_pair_matches(visual.get_meta("local_collision_footprint", []), Vector2(local_expected.x, local_expected.z), "%s rotation %d local compound footprint" % [kind, rotation])
			_check_runtime_measured_collision_shapes(body, measured_components, "%s rotation %d" % [kind, rotation])
			_check_operational_art(visual, "%s rotation %d operational" % [kind, rotation])
			visual.queue_free()
			visuals.erase(instance_id)
			await process_frame

func _check_generated_asset_metadata(world: Node) -> void:
	var style := world.get("sanctuary_style") as Node3D
	if not _check(style != null and is_instance_valid(style), "Sanctuary generated-style root must exist for metadata QA"):
		return
	var generated_count := 0
	var environment_count := 0
	var prop_count := 0
	for node in style.find_children("*", "Sprite3D", true, false):
		var sprite := node as Sprite3D
		if sprite == null:
			continue
		var asset_id := str(sprite.get_meta("asset_id", ""))
		if not asset_id.begins_with("environment/") and not asset_id.begins_with("settlement_props/"):
			continue
		generated_count += 1
		if asset_id.begins_with("environment/"):
			environment_count += 1
		else:
			prop_count += 1
		_check_generated_sprite_contract(sprite, "generated visual %s (%s)" % [sprite.name, asset_id])
	_check(generated_count > 0, "Sanctuary must expose generated sprites to the headless contract")
	_check(environment_count > 0, "Sanctuary must expose at least one generated environment visual")
	_check(prop_count > 0, "Sanctuary must expose at least one generated settlement-prop visual")

func _check_canonical_landmark_contract(world: Node) -> void:
	var style := world.get("sanctuary_style") as Node3D
	var district := world.get("sanctuary_district") as Node3D
	if not _check(style != null and district != null, "Sanctuary landmark layers require style and district roots"):
		return
	_check(style.visible, "Sanctuary illustrated style must be the visible presentation root")
	_check(not district.is_visible_in_tree(), "legacy Sanctuary district must stay hidden behind A+C art")
	for legacy_name in ["WorkshopStation", "ArchiveStation", "SanctuaryFarmPlot", "CloverLivestockPen"]:
		var legacy_root := world.get_node_or_null("Sanctuary/%s" % legacy_name) as Node3D
		if legacy_root != null:
			var visible_legacy_render := false
			for mesh_value in legacy_root.find_children("*", "MeshInstance3D", true, false):
				var mesh := mesh_value as MeshInstance3D
				if mesh == null or not mesh.is_visible_in_tree():
					continue
				# Clover's resident and sourced cow are gameplay actors, not the
				# replaced paddock shell presentation.
				var path := str(mesh.get_path())
				if legacy_name == "CloverLivestockPen" and (path.contains("/Clover/") or path.contains("/SourcedPaddockCow/")):
					continue
				visible_legacy_render = true
				break
			_check(not visible_legacy_render, "%s legacy render geometry must stay hidden behind A+C art" % legacy_name)
	var landmark_root := style.get_node_or_null("CanonicalLandmarks") as Node3D
	if not _check(landmark_root != null, "Sanctuary must expose a canonical landmark root"):
		return
	var expected := {
		"hearth_lodge": ["HearthLodge", "HearthLodgeCollision"],
		"archive_house": ["ArchiveHouse", "ArchiveHouseCollision"],
		"wanderers_bazaar": ["BazaarHouse", "BazaarHouseCollision"],
	}
	for landmark_id in expected:
		var names: Array = expected[landmark_id]
		var visual_root := landmark_root.get_node_or_null(str(names[0])) as Node3D
		var shell := district.get_node_or_null(str(names[1])) as StaticBody3D
		if not _check(visual_root != null and visual_root.is_visible_in_tree(), "%s must have a visible landmark root" % landmark_id):
			continue
		if not _check(shell != null, "%s must retain its authoritative shell collision" % landmark_id):
			continue
		_check(visual_root.global_position.distance_to(shell.global_position) <= 0.001, "%s visual root must share the shell transform" % landmark_id)
		_check(visual_root.global_rotation.distance_to(shell.global_rotation) <= 0.001, "%s visual root must share the shell rotation" % landmark_id)
		_check(str(visual_root.get_meta("asset_id", "")).begins_with("sanctuary/landmarks/"), "%s visual root must declare a landmark asset id" % landmark_id)
		_check(str(shell.get_meta("asset_id", "")) == str(visual_root.get_meta("asset_id", "")), "%s shell and visible root must share the asset id" % landmark_id)
		_check(shell.get_meta("visible_root", null) == visual_root, "%s shell must point to its visible root" % landmark_id)
		_check(shell.get_meta("access_zones", []) == visual_root.get_meta("access_zones", []), "%s shell and visible root must share access zones" % landmark_id)
		var sourced_asset := visual_root.get_meta("source_measurement_node", null) as Node3D
		_check(sourced_asset != null, "%s must retain its sourced measurement asset" % landmark_id)
		if sourced_asset != null:
			_check(not sourced_asset.is_visible_in_tree(), "%s sourced asset must stay hidden behind generated A+C art" % landmark_id)
		var generated_art := visual_root.get_node_or_null("GeneratedAPlusCLandmark") as Sprite3D
		_check(generated_art != null and generated_art.is_visible_in_tree(), "%s must expose its generated A+C presentation" % landmark_id)
		_check(str(visual_root.get_meta("presentation_authority", "")) == "generated_a_plus_c", "%s must declare generated A+C as presentation authority" % landmark_id)
		if generated_art != null:
			_check(bool(generated_art.get_meta("canonical_landmark_art", false)), "%s generated presentation must be canonical landmark art" % landmark_id)
			_check(generated_art.get_meta("visual_size", []).size() >= 2, "%s generated presentation must expose measured visual size" % landmark_id)
		var collision_shapes := shell.find_children("*", "CollisionShape3D", true, false)
		_check(not collision_shapes.is_empty(), "%s shell must expose collision shapes" % landmark_id)
		for collision_value in collision_shapes:
			var collision := collision_value as CollisionShape3D
			if collision == null:
				continue
			_check(str(collision.get_meta("landmark_asset_id", "")) == str(visual_root.get_meta("asset_id", "")), "%s collision shape must bind to the visible landmark asset" % landmark_id)
			_check(collision.get_meta("visible_root", null) == visual_root, "%s collision shape must point to the visible root" % landmark_id)

func _ensure_layout_blueprints(session: Node, layout: Array) -> void:
	var blueprints: Array = session.get("blueprints")
	for spec_value in layout:
		if not spec_value is Dictionary:
			continue
		var kind := str((spec_value as Dictionary).get("kind", ""))
		var requirement := str(ContentRegistry.structure_definition(kind).get("requires_blueprint", ""))
		if not requirement.is_empty() and not blueprints.has(requirement):
			blueprints.append(requirement)

func _exercise_player_authored_layout(world: Node, session: Node, layout_id: String, layout: Array) -> Dictionary:
	session.set("structures", {})
	_ensure_layout_blueprints(session, layout)
	var occupied := {}
	var instance_ids: Array[String] = []
	var signature_parts: Array[String] = []
	for spec_value in layout:
		if not _check(spec_value is Dictionary, "%s must contain dictionary placement specs" % layout_id):
			continue
		var spec := spec_value as Dictionary
		var kind := str(spec.get("kind", ""))
		var cell: Vector2i = spec.get("cell", Vector2i(9999, 9999))
		var rotation := posmod(int(spec.get("rotation", 0)), 4)
		if not _check(ContentRegistry.STRUCTURES.has(kind), "%s contains known structure kind %s" % [layout_id, kind]):
			continue
		if not _check(bool(session.call("can_place_structure", kind, [cell.x, cell.y], rotation)), "%s authoritative grid must accept %s at %s r%d" % [layout_id, kind, cell, rotation]):
			continue
		var placed: Dictionary = session.call("place_structure", kind, [cell.x, cell.y], rotation)
		if not _check(not placed.is_empty(), "%s must place %s through GameSession" % [layout_id, kind]):
			continue
		var instance_id := str(placed.get("id", ""))
		if not _check(not instance_id.is_empty(), "%s placed %s must receive an authoritative instance id" % [layout_id, kind]):
			continue
		instance_ids.append(instance_id)
		var placed_cell_data: Array = placed.get("cell", [])
		if not _check(placed_cell_data.size() == 2, "%s %s must retain its authored origin" % [layout_id, kind]):
			continue
		var placed_cell := Vector2i(int(placed_cell_data[0]), int(placed_cell_data[1]))
		_check(placed_cell == cell, "%s %s origin must remain player-authored" % [layout_id, kind])
		_check(int(placed.get("rotation", -1)) == rotation, "%s %s rotation must remain player-authored" % [layout_id, kind])
		var authored_data: Array = ContentRegistry.structure_definition(kind).get("footprint", [1, 1])
		var authored_footprint := Vector2i(int(authored_data[0]), int(authored_data[1]))
		var expected_footprint := Vector2i(authored_footprint.y, authored_footprint.x) if rotation % 2 == 1 else authored_footprint
		var session_footprint: Vector2i = session.call("_structure_footprint", kind, rotation)
		_check(session_footprint == expected_footprint, "%s %s occupancy must derive from its authored footprint" % [layout_id, kind])
		var cells: Array[Vector2i] = SettlementGrid.cells_for(cell, expected_footprint)
		_check(SettlementGrid.inside_bounds(cells), "%s %s footprint must remain inside the Sanctuary grid" % [layout_id, kind])
		for occupied_cell in cells:
			var key := "%d,%d" % [occupied_cell.x, occupied_cell.y]
			_check(not occupied.has(key), "%s must not overlap authored cell %s" % [layout_id, key])
			occupied[key] = true
		signature_parts.append("%s@%d,%d:r%d" % [kind, cell.x, cell.y, rotation])

		world.call("_spawn_structure_visual", instance_id, placed)
		await process_frame
		var visual := _get_visual(world, instance_id)
		if visual == null:
			continue
		_array_pair_matches(visual.get_meta("grid_footprint", []), expected_footprint, "%s %s visual grid footprint" % [layout_id, kind])
		var expected_center := SettlementGrid.footprint_center_to_world(cell, expected_footprint)
		_approx(visual.position.x, expected_center.x, "%s %s visual center x" % [layout_id, kind])
		_approx(visual.position.z, expected_center.z, "%s %s visual center z" % [layout_id, kind])
		var asset_definition := AssetCatalog.structure_definition(kind)
		var world_collision := _collision_size_from_authored_footprint(asset_definition, authored_footprint, kind, rotation)
		_array_float_pair_matches(visual.get_meta("collision_footprint", []), Vector2(world_collision.x, world_collision.z), "%s %s collision footprint" % [layout_id, kind])
		var state_sprite := _check_state_sprite(visual, "%s %s blueprint" % [layout_id, kind])
		_check_structure_sprite_binding(visual, state_sprite, kind, "blueprint", "state", "%s %s blueprint sprite" % [layout_id, kind])

	_check((session.get("structures") as Dictionary).size() == layout.size(), "%s must retain every player-authored placement" % layout_id)
	signature_parts.sort()
	var occupied_cells: Array[String] = []
	for key in occupied:
		occupied_cells.append(str(key))
	occupied_cells.sort()
	var visuals: Dictionary = world.get("settlement_visuals")
	for instance_id in instance_ids:
		var visual := visuals.get(instance_id) as Node3D
		if visual != null and is_instance_valid(visual):
			visual.queue_free()
		visuals.erase(instance_id)
	await process_frame
	session.set("structures", {})
	return {
		"signature": "|".join(signature_parts),
		"occupied_cells": occupied_cells,
	}

func _check_player_authored_layout_contract(world: Node, session: Node) -> void:
	var first: Dictionary = await _exercise_player_authored_layout(world, session, "layout A", PLAYER_LAYOUT_A)
	var second: Dictionary = await _exercise_player_authored_layout(world, session, "layout B", PLAYER_LAYOUT_B)
	var first_signature := str(first.get("signature", ""))
	var second_signature := str(second.get("signature", ""))
	_check(not first_signature.is_empty() and not second_signature.is_empty(), "player-authored layout signatures must be populated")
	_check(first_signature != second_signature, "two player-authored layouts must preserve distinct transforms")
	var first_lookup := {}
	var second_lookup := {}
	for key in first.get("occupied_cells", []):
		first_lookup[str(key)] = true
	for key in second.get("occupied_cells", []):
		second_lookup[str(key)] = true
	var symmetric_difference := 0
	for key in first_lookup:
		if not second_lookup.has(key):
			symmetric_difference += 1
	for key in second_lookup:
		if not first_lookup.has(key):
			symmetric_difference += 1
	_check(
		symmetric_difference >= MIN_LAYOUT_OCCUPIED_CELL_DIFFERENCE,
		"player-authored layouts must differ by at least %d occupied cells, got %d" % [MIN_LAYOUT_OCCUPIED_CELL_DIFFERENCE, symmetric_difference]
	)

func _check_delivery_scale(visual: Node3D, node_name: String, delivered: int, required: int, label: String) -> void:
	if visual == null:
		return
	var node := visual.get_node_or_null(node_name) as Node3D
	if not _check(node != null and node.visible, "%s material staging must be visible" % label):
		return
	var expected_scale := 0.55 + clampf(float(delivered) / float(maxi(1, required)), 0.0, 1.0) * 0.45
	_approx(node.scale.x, expected_scale, "%s staged scale" % label)
	_approx(node.scale.y, expected_scale, "%s staged scale y" % label)
	_approx(node.scale.z, expected_scale, "%s staged scale z" % label)

func _check_stage_presentation(visual: Node3D, label: String, expected_state: String, wall_layers: int, roof_layers: int) -> Sprite3D:
	var body := visual.get_node_or_null("StructureCollisionBody") as StaticBody3D if visual != null else null
	if _check(body != null, "%s measured structure collision body is required" % label):
		_check(str(body.get_meta("active_construction_state", "")) == expected_state, "%s collision state must match presentation state" % label)
		var collisions := body.find_children("Compound_*", "CollisionShape3D", false, false)
		for collision_value in collisions:
			var collision := collision_value as CollisionShape3D
			if collision == null:
				continue
			_check(collision.disabled == (expected_state != "operational"), "%s finished shell collision must be %s during %s" % [label, "disabled" if expected_state != "operational" else "active", expected_state])
	if expected_state == "operational" and str(visual.get_meta("operational_art_source", "")) == "measured_3d_source":
		_check_operational_art(visual, label)
		_check_role_count(visual, "IllustratedPlotBase", 1, "%s plot base" % label)
		return null
	var state_sprite := _check_state_sprite(visual, label)
	_check_structure_sprite_binding(visual, state_sprite, TEST_KIND, expected_state, "state", "%s state sprite" % label)
	_check_role_count(visual, "IllustratedPlotBase", 1, "%s plot base" % label)
	var structure_kind := str(visual.get_meta("structure_kind", TEST_KIND))
	var directional_art_required := bool(AssetCatalog.structure_definition(structure_kind).get("directional_art_required", false))
	if directional_art_required:
		# A production directional family owns the complete construction silhouette
		# in its state sprite. Reintroducing the legacy sheet-based partial layers
		# would double-render the shed and make the stage drift from its measured
		# alpha envelope.
		_check_role_count(visual, "IllustratedPartialWalls", 0, "%s directional partial walls" % label)
		_check_role_count(visual, "IllustratedPartialRoof", 0, "%s directional partial roof" % label)
		_check(state_sprite != null and not str(state_sprite.get_meta("directional_asset_path", "")).is_empty(), "%s directional family must expose its authored state asset" % label)
		return state_sprite
	var wall_node := _check_role_count(visual, "IllustratedPartialWalls", wall_layers, "%s partial walls" % label)
	if wall_node != null:
		var wall_sprite := wall_node as Sprite3D
		if _check(wall_sprite != null, "%s partial walls must be a generated Sprite3D" % label):
			_check_generated_sprite_contract(wall_sprite, "%s partial walls" % label)
			_check_structure_sprite_binding(visual, wall_sprite, TEST_KIND, expected_state, "partial_walls", "%s partial walls" % label)
	var roof_node := _check_role_count(visual, "IllustratedPartialRoof", roof_layers, "%s partial roof" % label)
	if roof_node != null:
		var roof_sprite := roof_node as Sprite3D
		if _check(roof_sprite != null, "%s partial roof must be a generated Sprite3D" % label):
			_check_generated_sprite_contract(roof_sprite, "%s partial roof" % label)
			_check_structure_sprite_binding(visual, roof_sprite, TEST_KIND, expected_state, "partial_roof", "%s partial roof" % label)
	return state_sprite

func _check_construction_layers(visual: Node3D, label: String, visible_phases: Array[String]) -> void:
	# The old named layers remain as compatibility hooks, while the additive
	# component meshes are the source of truth for the staged build silhouette.
	var expected_legacy := {
		"ScaffoldFrame": not visible_phases.is_empty(),
		"ConstructionWalls": "walls" in visible_phases,
		"ConstructionRoof": "roof" in visible_phases,
	}
	for node_name in expected_legacy:
		_check_visibility(visual, node_name, bool(expected_legacy[node_name]), "%s %s" % [label, node_name])
	var additive := visual.get_node_or_null("AdditiveConstructionComponents") as Node3D
	if not _check(additive != null, "%s additive construction components are required" % label):
		return
	_check_visibility(visual, "AdditiveConstructionComponents", not visible_phases.is_empty(), "%s additive construction root" % label)
	var phase_thresholds := {"foundation": 0, "frame": 1, "walls": 2, "roof": 3, "fittings": 4}
	for component in additive.get_children():
		var phase := str(component.get_meta("phase", ""))
		var should_be_visible := false
		for expected_phase in visible_phases:
			if int(phase_thresholds.get(phase, 99)) <= int(phase_thresholds.get(expected_phase, -1)):
				should_be_visible = true
		_check(bool(component.visible) == should_be_visible, "%s %s phase visibility" % [label, phase])

func _check_stage_nodes(world: Node, origin: Vector2i) -> void:
	var definition: Dictionary = ContentRegistry.structure_definition(TEST_KIND)
	var cost: Dictionary = definition.get("cost", {})
	var blueprint_data := {
		"id": TEST_ID,
		"kind": TEST_KIND,
		"cell": [origin.x, origin.y],
		"rotation": 0,
		"state": "blueprint",
		"remaining_hours": 24.0,
		"total_hours": 24.0,
		"delivered_materials": {"wood": 0, "stone": 0, "plank": 0},
	}
	world.call("_spawn_structure_visual", TEST_ID, blueprint_data)
	await process_frame
	var visual := _get_visual(world, TEST_ID)
	if visual == null:
		return
	_check_visibility(visual, "BlueprintStakes", true, "blueprint stakes")
	_check_construction_layers(visual, "blueprint", [])
	_check_visibility(visual, "FinishedWalls", false, "blueprint finished walls")
	var blueprint_sprite := _check_stage_presentation(visual, "blueprint", "blueprint", 0, 0)
	if blueprint_sprite != null:
		_check(blueprint_sprite.modulate.a < 0.5, "blueprint illustration must read as a translucent outline")
	var blueprint_region := _atlas_region(blueprint_sprite)

	# Staging covers every material used by this structure and leaves unrelated
	# materials hidden. The scale is tied to delivered/required counts.
	var partial_delivered := {"wood": 2, "stone": 1, "plank": 1}
	var partial_data: Dictionary = blueprint_data.duplicate(true)
	partial_data["delivered_materials"] = partial_delivered
	world.call("_refresh_structure_visual", TEST_ID, partial_data)
	await process_frame
	await process_frame
	visual = _get_visual(world, TEST_ID)
	if visual == null:
		return
	_check_visibility(visual, "BlueprintStakes", true, "partial-material blueprint stakes")
	_check_construction_layers(visual, "partial-material blueprint", [])
	var partial_sprite := _check_stage_presentation(visual, "partial-material blueprint", "blueprint", 0, 0)
	if partial_sprite != null:
		_check(_atlas_region(partial_sprite) == blueprint_region, "partial delivery must preserve the blueprint scaffold illustration")
	_check_delivery_scale(visual, "DeliveredLogs", 2, int(cost.get("wood", 0)), "wood")
	_check_delivery_scale(visual, "DeliveredStone", 1, int(cost.get("stone", 0)), "stone")
	_check_delivery_scale(visual, "DeliveredPlanks", 1, int(cost.get("plank", 0)), "plank")
	_check_visibility(visual, "DeliveredFiber", false, "undelivered fiber")
	var blueprint_label := visual.get_node_or_null("StructureLabel") as Label3D
	if _check(blueprint_label != null, "blueprint material label is required"):
		_check(blueprint_label.text.contains("WOOD 2/%d" % int(cost.get("wood", 0))), "blueprint label must report staged wood")
		_check(blueprint_label.text.contains("STONE 1/%d" % int(cost.get("stone", 0))), "blueprint label must report staged stone")
		_check(blueprint_label.text.contains("PLANK 1/%d" % int(cost.get("plank", 0))), "blueprint label must report staged planks")

	var fully_delivered := {
		"wood": int(cost.get("wood", 0)),
		"stone": int(cost.get("stone", 0)),
		"plank": int(cost.get("plank", 0)),
	}
	var early_data: Dictionary = blueprint_data.duplicate(true)
	early_data["state"] = "building"
	early_data["remaining_hours"] = 20.0
	early_data["delivered_materials"] = fully_delivered
	world.call("_refresh_structure_visual", TEST_ID, early_data)
	await process_frame
	await process_frame
	visual = _get_visual(world, TEST_ID)
	if visual == null:
		return
	_check_visibility(visual, "BlueprintStakes", false, "early blueprint stakes")
	_check_construction_layers(visual, "early", ["foundation"])
	var early_sprite := _check_stage_presentation(visual, "early", "building", 0, 0)
	if early_sprite != null:
		_check(early_sprite.modulate.a > 0.99, "early construction illustration must be opaque")
	_check_delivery_scale(visual, "DeliveredLogs", int(cost.get("wood", 0)), int(cost.get("wood", 0)), "early wood")
	_check_delivery_scale(visual, "DeliveredStone", int(cost.get("stone", 0)), int(cost.get("stone", 0)), "early stone")
	_check_delivery_scale(visual, "DeliveredPlanks", int(cost.get("plank", 0)), int(cost.get("plank", 0)), "early plank")

	var mid_data: Dictionary = early_data.duplicate(true)
	mid_data["remaining_hours"] = 12.0
	world.call("_refresh_structure_visual", TEST_ID, mid_data)
	await process_frame
	await process_frame
	visual = _get_visual(world, TEST_ID)
	if visual == null:
		return
	_check_construction_layers(visual, "mid", ["foundation", "frame", "walls"])
	_check_stage_presentation(visual, "mid", "building", 1, 0)

	var late_data: Dictionary = mid_data.duplicate(true)
	late_data["remaining_hours"] = 5.0
	world.call("_refresh_structure_visual", TEST_ID, late_data)
	await process_frame
	await process_frame
	visual = _get_visual(world, TEST_ID)
	if visual == null:
		return
	_check_construction_layers(visual, "late", ["foundation", "frame", "walls", "roof"])
	_check_stage_presentation(visual, "late", "building", 1, 1)

	var operational_data: Dictionary = late_data.duplicate(true)
	operational_data["state"] = "operational"
	operational_data["remaining_hours"] = 0.0
	world.call("_refresh_structure_visual", TEST_ID, operational_data)
	await process_frame
	await process_frame
	visual = _get_visual(world, TEST_ID)
	if visual == null:
		return
	_check_visibility(visual, "BlueprintStakes", false, "operational blueprint stakes")
	_check_construction_layers(visual, "operational", [])
	var operational_sprite := _check_stage_presentation(visual, "operational", "operational", 0, 0)
	if operational_sprite != null:
		_check(_atlas_region(operational_sprite) != blueprint_region, "operational structure must replace the scaffold with its finished asset")
	_check_visibility(visual, "StructureUtility", true, "operational utility visuals")
	_check_visibility(visual, "DeliveredLogs", false, "operational delivered logs")
	_check_visibility(visual, "DeliveredStone", false, "operational delivered stone")
	_check_visibility(visual, "DeliveredPlanks", false, "operational delivered planks")
	_check(bool(visual.get_meta("operational", false)), "operational state metadata must be true")
	var operational_label := visual.get_node_or_null("StructureLabel") as Label3D
	if _check(operational_label != null, "operational label is required"):
		_check(operational_label.text.contains("SATCHEL +4"), "storage shed operational label must expose its gameplay effect")

func _find_valid_origin(session: Node, rotation: int) -> Vector2i:
	for z in range(SettlementGrid.MIN_Z, SettlementGrid.MAX_Z + 1):
		for x in range(SettlementGrid.MIN_X, SettlementGrid.MAX_X + 1):
			if bool(session.call("can_place_structure", TEST_KIND, [x, z], rotation)):
				return Vector2i(x, z)
	return Vector2i(9999, 9999)

func _check_player_placement_separation(world: Node, session: Node, player: CharacterBody3D) -> void:
	session.set("structures", {})
	var blueprints: Array = session.get("blueprints")
	if not blueprints.has("Tideglass Compass"):
		blueprints.append("Tideglass Compass")
	var rotation := 1
	var candidate := _find_valid_origin(session, rotation)
	if not _check(candidate.x != 9999, "a clear rotated footprint is required for player-separation QA"):
		return
	var footprint: Vector2i = session.call("_structure_footprint", TEST_KIND, rotation)
	var occupied_cells: Array[Vector2i] = SettlementGrid.cells_for(candidate, footprint)
	_check(not occupied_cells.is_empty(), "candidate footprint must contain occupied cells")
	if occupied_cells.is_empty():
		return
	world.set("placement_structure_id", TEST_KIND)
	world.set("placement_rotation_quarter_turns", rotation)
	world.set("placement_mode", true)
	_check(bool(session.call("can_place_structure", TEST_KIND, [candidate.x, candidate.y], rotation)), "candidate should be clear to the authoritative settlement grid")
	player.global_position = SettlementGrid.cell_to_world(occupied_cells[0], 1.0)
	_check(not bool(world.call("_structure_preview_valid", candidate)), "placement must reject every footprint cell reached by the player's body")
	player.global_position = Vector3(20.0, 1.0, 15.0)
	_check(bool(world.call("_structure_preview_valid", candidate)), "the same clear footprint must become valid when the player moves away")
	world.set("placement_mode", false)

func _check_player_building_physics(world: Node, player: CharacterBody3D) -> void:
	var data := {
		"id": PHYSICS_ID,
		"kind": TEST_KIND,
		"cell": [PHYSICS_ORIGIN.x, PHYSICS_ORIGIN.y],
		"rotation": 0,
		"state": "operational",
		"remaining_hours": 0.0,
		"total_hours": 24.0,
		"delivered_materials": {"wood": 10, "stone": 4, "plank": 3},
	}
	world.call("_spawn_structure_visual", PHYSICS_ID, data)
	await process_frame
	await physics_frame
	var visual := _get_visual(world, PHYSICS_ID)
	if visual == null:
		return
	var body := visual.get_node_or_null("StructureCollisionBody") as StaticBody3D
	var collision := body.get_node_or_null("Compound_left_wall") as CollisionShape3D if body != null else null
	var shape := collision.shape as BoxShape3D if collision != null else null
	if not _check(body != null and collision != null and shape != null and not collision.disabled, "operational building must expose active compound wall collision"):
		return
	var player_shapes := player.find_children("*", "CollisionShape3D", true, false)
	if not _check(player_shapes.size() == 1, "player must expose exactly one authoritative collision shape"):
		return
	var player_collision := player_shapes[0] as CollisionShape3D
	var capsule := player_collision.shape as CapsuleShape3D if player_collision != null else null
	if not _check(capsule != null and not player_collision.disabled, "player collision must be an active CapsuleShape3D"):
		return
	_check((player.collision_mask & body.collision_layer) != 0, "player mask must include building collision layer")
	_check((body.collision_mask & player.collision_layer) != 0, "building mask must include player collision layer")

	var horizontal_size := _world_horizontal_size(collision, shape)
	var left_face := collision.global_position.x - horizontal_size.x * 0.5
	var start_x := left_face - capsule.radius - 0.55
	player.global_position = Vector3(start_x, 1.0, collision.global_position.z)
	player.velocity = Vector3.ZERO
	await physics_frame
	_check(player.global_position.x + capsule.radius < left_face, "player must start physically separated from the building")
	var motion := Vector3(horizontal_size.x + capsule.radius * 2.0 + 1.1, 0.0, 0.0)
	_check(player.test_move(player.global_transform, motion), "player motion through the building must predict a collision")
	var hit := player.move_and_collide(motion)
	if not _check(hit != null, "player motion through the building must be physically blocked"):
		return
	_check(hit.get_collider() == body, "player must be blocked by the structure collision body, got %s" % str(hit.get_collider()))
	_check(player.global_position.x <= left_face - capsule.radius + 0.03, "collision resolution must leave the player outside the building footprint")

func _check_sanctuary_motion_contract(world: Node) -> void:
	var guide := world.get("guide_npc") as Node3D
	if not _check(guide != null and is_instance_valid(guide), "Sanctuary must expose Mira as a live NPC root"):
		return
	var visual := guide.get_node_or_null("Visual") as Node3D
	if not _check(visual != null, "Mira must expose a visual rig"):
		return
	for limb_name in ["LegLeft", "LegRight", "ArmLeft", "ArmRight"]:
		_check(visual.get_node_or_null(limb_name) != null, "Mira visual rig must expose %s" % limb_name)
	var left_leg := visual.get_node_or_null("LegLeft") as Node3D
	var right_leg := visual.get_node_or_null("LegRight") as Node3D
	var left_arm := visual.get_node_or_null("ArmLeft") as Node3D
	var right_arm := visual.get_node_or_null("ArmRight") as Node3D
	var initial_position := guide.global_position
	var initial_leg_rotation := left_leg.rotation.x if left_leg != null else 0.0
	var initial_right_leg_rotation := right_leg.rotation.x if right_leg != null else 0.0
	var initial_arm_rotation := left_arm.rotation.x if left_arm != null else 0.0
	var initial_right_arm_rotation := right_arm.rotation.x if right_arm != null else 0.0
	for _frame in 12:
		await process_frame
	var moved := guide.global_position.distance_to(initial_position) > 0.001
	var left_leg_animated := left_leg != null and absf(left_leg.rotation.x - initial_leg_rotation) > 0.001
	var right_leg_animated := right_leg != null and absf(right_leg.rotation.x - initial_right_leg_rotation) > 0.001
	var left_arm_animated := left_arm != null and absf(left_arm.rotation.x - initial_arm_rotation) > 0.001
	var right_arm_animated := right_arm != null and absf(right_arm.rotation.x - initial_right_arm_rotation) > 0.001
	_check(moved, "Mira must translate along her Sanctuary routine")
	_check(left_leg_animated and right_leg_animated, "Mira must articulate both legs while walking")
	_check(left_arm_animated and right_arm_animated, "Mira must articulate both arms while walking")
	if left_leg != null and right_leg != null:
		_approx(left_leg.rotation.x, -right_leg.rotation.x, "Mira opposing leg stride", 0.01)
	if left_arm != null and right_arm != null:
		_approx(left_arm.rotation.x, -right_arm.rotation.x, "Mira opposing arm stride", 0.01)

func _run() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", SAVE_SLOT)
	_clear_test_saves()
	var section_failures := failures.size()
	_check_player_structure_authoring_gate()
	print("SANCTUARY_VISUAL_CONTRACT_SECTION structure_authoring=%s" % ("OK" if failures.size() == section_failures else "FAIL"))

	var world := MainScene.instantiate() as Node
	if not _check(world != null, "Main scene must instantiate for Sanctuary visual contract"):
		_finish(world)
		return
	root.add_child(world)
	await process_frame
	await physics_frame
	var session := world.get("session") as Node
	var player := world.get("player") as CharacterBody3D
	if not _check(session != null, "Main scene must expose the real GameSession"):
		_finish(world)
		return
	if not _check(player != null, "Main scene must expose the real CharacterBody3D player"):
		_finish(world)
		return
	# Stop autonomous movement without removing the CharacterBody3D from its
	# physics space; the separation gate below exercises the real body.
	player.set_physics_process(false)
	session.set("structures", {})
	var blueprints: Array = session.get("blueprints")
	if not blueprints.has("Tideglass Compass"):
		blueprints.append("Tideglass Compass")
	if not _check(world.get("sanctuary_style") != null, "Sanctuary style director must be attached"):
		_finish(world)
		return

	var rotation_origin := _find_valid_origin(session, 0)
	if not _check(rotation_origin.x != 9999, "a clear grid origin is required for rotation QA"):
		_finish(world)
		return
	section_failures = failures.size()
	for rotation in 4:
		var visual: Node3D = await _check_rotation_and_collision_contract(world, session, rotation_origin, rotation)
		if visual != null:
			var instance_id := "%s_rotation_%d" % [TEST_ID, rotation]
			var visuals: Dictionary = world.get("settlement_visuals")
			visual.queue_free()
			visuals.erase(instance_id)
			await process_frame
	print("SANCTUARY_VISUAL_CONTRACT_SECTION rotations=%s" % ("OK" if failures.size() == section_failures else "FAIL"))

	section_failures = failures.size()
	await _check_all_asset_collision_contract(world)
	print("SANCTUARY_VISUAL_CONTRACT_SECTION asset_collision=%s" % ("OK" if failures.size() == section_failures else "FAIL"))

	section_failures = failures.size()
	_check_generated_asset_metadata(world)
	print("SANCTUARY_VISUAL_CONTRACT_SECTION generated_pivots=%s" % ("OK" if failures.size() == section_failures else "FAIL"))

	section_failures = failures.size()
	_check_canonical_landmark_contract(world)
	print("SANCTUARY_VISUAL_CONTRACT_SECTION canonical_landmarks=%s" % ("OK" if failures.size() == section_failures else "FAIL"))

	section_failures = failures.size()
	await _check_player_authored_layout_contract(world, session)
	print("SANCTUARY_VISUAL_CONTRACT_SECTION authored_layouts=%s" % ("OK" if failures.size() == section_failures else "FAIL"))

	section_failures = failures.size()
	await _check_stage_nodes(world, rotation_origin)
	print("SANCTUARY_VISUAL_CONTRACT_SECTION construction=%s" % ("OK" if failures.size() == section_failures else "FAIL"))

	section_failures = failures.size()
	_check_player_placement_separation(world, session, player)
	await _check_player_building_physics(world, player)
	print("SANCTUARY_VISUAL_CONTRACT_SECTION separation=%s" % ("OK" if failures.size() == section_failures else "FAIL"))

	section_failures = failures.size()
	await _check_sanctuary_motion_contract(world)
	print("SANCTUARY_VISUAL_CONTRACT_SECTION npc_motion=%s" % ("OK" if failures.size() == section_failures else "FAIL"))
	_finish(world)
