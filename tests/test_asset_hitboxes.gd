extends SceneTree

const MainScene := preload("res://main.tscn")
const AssetMeasurement := preload("res://scripts/sanctuary_asset_measurement.gd")

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("ASSET_HITBOX_FAIL: " + message)

func _approx(actual: float, expected: float, label: String, tolerance := 0.001) -> void:
	_check(absf(actual - expected) <= tolerance, "%s expected %.5f got %.5f" % [label, expected, actual])

func _vector_matches(actual: Vector3, expected: Vector3, label: String) -> void:
	_approx(actual.x, expected.x, label + ".x")
	_approx(actual.y, expected.y, label + ".y")
	_approx(actual.z, expected.z, label + ".z")

func _first_sourced_child(root_node: Node) -> Node3D:
	for child in root_node.get_children():
		var node := child as Node3D
		if node != null and str(node.name).begins_with("Sourced_"):
			return node
	return null

func _first_visible_mesh(root_node: Node) -> MeshInstance3D:
	for value in root_node.find_children("*", "MeshInstance3D", true, false):
		var mesh := value as MeshInstance3D
		if mesh != null and mesh.visible and mesh.mesh != null:
			return mesh
	return null

func _check_box_from_measurement(collision: CollisionShape3D, visual_root: Node3D, label: String) -> void:
	_check(collision != null and collision.shape is BoxShape3D, label + " must use a measured box shape")
	if collision == null or not collision.shape is BoxShape3D or visual_root == null:
		return
	var measurement := AssetMeasurement.measure_runtime_node(visual_root, [], true)
	_check(bool(measurement.get("valid", false)), label + " visual must expose measurable mesh bounds")
	if not bool(measurement.get("valid", false)):
		return
	var bounds: AABB = measurement.get("bounds", AABB())
	var shape := collision.shape as BoxShape3D
	_vector_matches(shape.size, bounds.size, label + " measured size")
	_vector_matches(collision.position, bounds.position + bounds.size * 0.5, label + " measured center")
	_check(not str(collision.get_meta("measurement_source", "")).is_empty(), label + " must declare its measurement source")

func _check_tree_hitboxes(world: Node) -> void:
	var tree_count := 0
	for value in get_nodes_in_group("resource_node"):
		var tree := value as Node3D
		if tree == null or str(tree.get("resource_id")) != "wood":
			continue
		var collision := tree.get_node_or_null("TreeCollision/TreeHitbox") as CollisionShape3D
		if collision == null:
			continue
		tree_count += 1
		var visual_root := tree.get_node_or_null("Trunk") as Node3D
		var measurement := AssetMeasurement.measure_runtime_node(visual_root, [], true)
		_check(bool(measurement.get("valid", false)), "tree %s must have measurable physical art" % tree.name)
		if not bool(measurement.get("valid", false)):
			continue
		var bounds: AABB = measurement.get("bounds", AABB())
		var cylinder := collision.shape as CylinderShape3D
		_check(cylinder != null, "tree %s must use a cylinder for its measured trunk envelope" % tree.name)
		if cylinder == null:
			continue
		_approx(cylinder.radius, maxf(bounds.size.x, bounds.size.z) * 0.5, "tree %s measured radius" % tree.name)
		_approx(cylinder.height, bounds.size.y, "tree %s measured height" % tree.name)
		_vector_matches(collision.position, bounds.position + bounds.size * 0.5, "tree %s measured center" % tree.name)
		_check(str(tree.get_meta("collision_source", "")).contains("mesh_bounds"), "tree %s must record a mesh-derived collision source" % tree.name)
	_check(tree_count > 0, "world must expose measured tree hitboxes")

func _check_rock_hitboxes() -> void:
	var rock_count := 0
	for value in get_nodes_in_group("resource_node"):
		var rock := value as Node3D
		if rock == null or rock.get_node_or_null("RockCollision/RockHitbox") == null:
			continue
		rock_count += 1
		var collision := rock.get_node("RockCollision/RockHitbox") as CollisionShape3D
		var source := _first_sourced_child(rock)
		var visual_root := source if source != null else _first_visible_mesh(rock)
		_check_box_from_measurement(collision, visual_root, "rock %s" % rock.name)
	_check(rock_count > 0, "world must expose measured rock hitboxes")

func _check_guardian_hitboxes() -> void:
	var guardian_count := 0
	for value in get_nodes_in_group("guardian"):
		var guardian := value as Node3D
		if guardian == null:
			continue
		guardian_count += 1
		var collision := guardian.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var visual := guardian.get_node_or_null("Visual") as Node3D
		_check(collision != null and collision.shape is BoxShape3D, "guardian %s must use a measured box hitbox" % guardian.name)
		if collision == null or visual == null or not collision.shape is BoxShape3D:
			continue
		var measurement := AssetMeasurement.measure_runtime_node(visual)
		var bounds: AABB = measurement.get("bounds", AABB())
		var base_size: Array = collision.get_meta("base_shape_size", [])
		var base_center: Array = collision.get_meta("base_shape_center", [])
		_check(base_size.size() == 3 and base_center.size() == 3, "guardian %s must persist measured base shape metadata" % guardian.name)
		if base_size.size() == 3 and base_center.size() == 3:
			_vector_matches(Vector3(float(base_size[0]), float(base_size[1]), float(base_size[2])), bounds.size, "guardian %s base size" % guardian.name)
			_vector_matches(Vector3(float(base_center[0]), float(base_center[1]), float(base_center[2])), bounds.position + bounds.size * 0.5, "guardian %s base center" % guardian.name)
	_check(guardian_count == 5, "all authored guardians must expose measured hitboxes")

func _check_measured_box_group(group_name: String, collision_path: String, label: String) -> void:
	var asset_count := 0
	for value in get_nodes_in_group(group_name):
		var asset := value as Node3D
		if asset == null:
			continue
		asset_count += 1
		var collision := asset.get_node_or_null(collision_path) as CollisionShape3D
		_check_box_from_measurement(collision, asset, "%s %s" % [label, asset.name])
	_check(asset_count > 0, "world must expose measured %s assets" % label)

func _check_landmark_hitboxes(world: Node) -> void:
	var district := world.get("sanctuary_district") as Node3D
	var style := world.get("sanctuary_style") as Node3D
	_check(district != null and style != null, "Sanctuary landmark measurement roots must exist")
	if district == null or style == null:
		return
	var landmark_root := style.get_node_or_null("CanonicalLandmarks") as Node3D
	for landmark in landmark_root.get_children() if landmark_root != null else []:
		var visual_root := landmark as Node3D
		if visual_root == null:
			continue
		var shell := visual_root.get_meta("collision_node", null) as StaticBody3D
		var sourced := visual_root.get_meta("source_measurement_node", null) as Node3D
		var generated := visual_root.get_node_or_null("GeneratedAPlusCLandmark") as Sprite3D
		_check(shell != null and sourced != null and generated != null, "landmark %s must bind generated art and source measurement to its shell" % visual_root.name)
		if shell == null or sourced == null or generated == null:
			continue
		_check(generated.is_visible_in_tree(), "landmark %s generated presentation must be visible" % visual_root.name)
		var measurement := AssetMeasurement.measure_runtime_node_local(sourced, [], true)
		_check(bool(measurement.get("valid", false)), "landmark %s source must be measurable" % visual_root.name)
		var bounds: AABB = measurement.get("bounds", AABB())
		for shape_value in shell.find_children("*", "CollisionShape3D", true, false):
			var collision := shape_value as CollisionShape3D
			_check(collision != null and collision.shape is BoxShape3D, "landmark %s shell pieces must be boxes" % visual_root.name)
			if collision == null or not collision.shape is BoxShape3D:
				continue
			var box := collision.shape as BoxShape3D
			_check(not str(collision.get_meta("measurement_source", "")).is_empty(), "landmark %s shell piece must declare measurement source" % visual_root.name)
			var rect := Rect2(Vector2(collision.position.x, collision.position.z) - Vector2(box.size.x, box.size.z) * 0.5, Vector2(box.size.x, box.size.z))
			var bounds_rect := Rect2(Vector2(bounds.position.x, bounds.position.z), Vector2(bounds.size.x, bounds.size.z)).grow(0.001)
			_check(bounds_rect.encloses(rect), "landmark %s shell piece must remain inside measured source envelope" % visual_root.name)

func _check_framing_hitboxes(world: Node) -> void:
	var style := world.get("sanctuary_style") as Node3D
	_check(style != null, "Sanctuary style must exist for measured framing hitboxes")
	if style == null:
		return
	var framing_count := 0
	for value in style.find_children("*", "StaticBody3D", true, false):
		var body := value as StaticBody3D
		if body == null or body.name != "MeasuredFramingCollision":
			continue
		framing_count += 1
		var sprite := body.get_parent() as Sprite3D
		var collision := body.get_node_or_null("MeasuredFramingHitbox") as CollisionShape3D
		_check(sprite != null and collision != null and collision.shape is BoxShape3D, "framing collision must remain paired with its Sprite3D")
		if sprite == null or collision == null or not collision.shape is BoxShape3D:
			continue
		var footprint: Variant = sprite.get_meta("visual_footprint", [])
		var visual_size: Variant = sprite.get_meta("visual_size", [])
		_check(footprint is Array and footprint.size() >= 2 and visual_size is Array and visual_size.size() >= 2, "framing sprite must publish measured visual metadata")
		if not (footprint is Array) or footprint.size() < 2 or not (visual_size is Array) or visual_size.size() < 2:
			continue
		var expected_height := maxf(0.08, minf(float(visual_size[1]) * 0.24, float(visual_size[1]) - 0.01))
		var shape := collision.shape as BoxShape3D
		_vector_matches(shape.size, Vector3(float(footprint[0]), expected_height, float(footprint[1])), "framing %s measured size" % sprite.name)
		_approx(body.position.y, expected_height * 0.5, "framing %s measured center" % sprite.name)
		_check(not str(collision.get_meta("measurement_source", "")).is_empty(), "framing %s must declare its measurement source" % sprite.name)
		_check(not str(collision.get_meta("asset_id", "")).is_empty(), "framing %s must declare its source asset" % sprite.name)
	_check(framing_count >= 13, "Sanctuary framing trees and rocks must expose measured hitboxes")

func _run() -> void:
	var world := MainScene.instantiate()
	root.add_child(world)
	await process_frame
	_check_tree_hitboxes(world)
	_check_rock_hitboxes()
	_check_guardian_hitboxes()
	_check_measured_box_group("wildlife_track", "TrackCollision/TrackHitbox", "wildlife track")
	_check_measured_box_group("expedition_inscription", "InscriptionCollision/InscriptionHitbox", "expedition inscription")
	_check_landmark_hitboxes(world)
	_check_framing_hitboxes(world)
	world.queue_free()
	if failures.is_empty():
		print("ASSET_HITBOX_TESTS_PASS checks=%d" % checks)
		quit(0)
	else:
		print("ASSET_HITBOX_TESTS_FAIL failures=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  ", failure)
		quit(1)
