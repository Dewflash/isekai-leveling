extends SceneTree

const InteriorScript = preload("res://scripts/building_interior.gd")
const AssetCatalog = preload("res://scripts/sanctuary_asset_catalog.gd")
const AssetMeasurement = preload("res://scripts/sanctuary_asset_measurement.gd")

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("WORKSHOP_INTERIOR_FAIL: " + message)

func _run() -> void:
	var host := Node3D.new()
	host.name = "InteriorContractHost"
	root.add_child(host)
	var interior := InteriorScript.new() as Node3D
	_check(interior != null, "interior controller must instantiate")
	if interior == null:
		_finish(host)
		return
	interior.call("build", host)
	await process_frame
	var unconfigured := InteriorScript.new() as Node3D
	unconfigured.call("build", host)
	_check(not bool(unconfigured.call("transition_to", true, "workshop", "unconfigured")), "unconfigured room must reject entry")
	unconfigured.queue_free()
	var workshop_definition: Dictionary = AssetCatalog.structure_definition("workshop")
	var workshop_measurement: Dictionary = AssetMeasurement.structure_measurement("workshop", Vector2i(6, 5))
	_check(bool(interior.call("configure_for_structure", "workshop", workshop_measurement, AssetCatalog.structure_access_zones("workshop", 0), workshop_definition.get("interior_profile", {}))), "workshop must configure from its measured exterior profile")
	await process_frame
	_check(not bool(interior.call("is_active")), "interior must start inactive")
	_check(int(interior.call("active_station_count")) == 6, "workshop must expose two furnaces, bench, anvil, storage and exit")
	var room := interior.get_node_or_null("WorkshopInteriorRoom") as Node3D
	_check(room != null, "workshop room root must exist")
	_check(room != null and not room.visible, "workshop room must be hidden outside entry")
	_check(bool(interior.get("room_measurements_valid")), "workshop room must pass its measured collision validation")
	var station_ids: Array = interior.call("station_ids")
	for expected_id in ["furnace_left", "furnace_right", "workbench", "anvil", "storage", "exit"]:
		_check(station_ids.has(expected_id), "workshop must expose station %s" % expected_id)
	_check(not bool(interior.call("configure_for_structure", "archive", workshop_measurement, AssetCatalog.structure_access_zones("workshop", 0), {})), "Workshop controller must reject unsupported interior kinds")
	var invalid_host := Node3D.new()
	invalid_host.name = "InvalidMeasurementHost"
	host.add_child(invalid_host)
	var invalid_interior := InteriorScript.new() as Node3D
	invalid_interior.call("build", invalid_host)
	_check(bool(invalid_interior.call("configure_for_structure", "workshop", workshop_measurement, AssetCatalog.structure_access_zones("workshop", 0), workshop_definition.get("interior_profile", {}))), "adversarial Workshop must configure before invalidation")
	var invalid_room := invalid_interior.get_node_or_null("WorkshopInteriorRoom") as Node3D
	var invalid_station := invalid_room.get_node_or_null("InteriorStation_anvil") as Node3D if invalid_room != null else null
	if invalid_station != null:
		invalid_interior.call("_disable_station_collision", invalid_station, "qa_invalid_visible_mesh")
	invalid_interior.set("room_measurements_valid", bool(invalid_interior.call("_validate_room_measurements")))
	_check(not bool(invalid_interior.call("configure_for_structure", "workshop", workshop_measurement, AssetCatalog.structure_access_zones("workshop", 0), workshop_definition.get("interior_profile", {}))), "invalid room configuration must report failure, not only block activation")
	_check(not bool(invalid_interior.call("transition_to", true, "workshop", "invalid_measurement")), "room activation must fail closed when a measured station collider is invalid")
	_check(invalid_room == null or not bool(invalid_interior.call("is_active")), "invalid room must remain inactive")
	invalid_interior.queue_free()
	invalid_host.queue_free()
	var stations := interior.get_node_or_null("WorkshopInteriorRoom")
	if stations != null:
		for station_value in stations.get_children():
			var station := station_value as Node3D
			if station == null or not station.is_in_group("building_interior_station"):
				continue
			var station_collision_source := str(station.get_meta("collision_source", ""))
			_check(station_collision_source in ["visible_mesh_aabb", "generated_texture_alpha_calibrated_by_measured_mesh_aspect"], "%s must declare measured visible-asset collision provenance" % station.name)
			_check((station.get_meta("visible_mesh_bounds", []) as Array).size() == 6, "%s must retain measured visible mesh bounds" % station.name)
			for mesh_value in station.find_children("*", "MeshInstance3D", true, false):
				var source_mesh := mesh_value as MeshInstance3D
				if source_mesh == null or source_mesh.mesh == null or not source_mesh.visible:
					continue
				if bool(source_mesh.get_meta("physical_asset_mesh", false)):
					_check(bool(source_mesh.get_meta("collision_contributor", false)), "%s physical visible mesh must remain a collision contributor" % source_mesh.name)
			var footprint: Array = station.get_meta("visual_footprint", [])
			_check(footprint.size() == 2 and float(footprint[0]) > 0.0 and float(footprint[1]) > 0.0, "%s must have a positive visible footprint" % station.name)
			var body := station.get_node_or_null("VisibleAssetCollision") as StaticBody3D
			var shape_node := body.get_node_or_null("MeasuredProxy") as CollisionShape3D if body != null else null
			var box := shape_node.shape as BoxShape3D if shape_node != null else null
			_check(body != null and shape_node != null and box != null, "%s must have a measured box proxy" % station.name)
			if body != null:
				_check(str(body.get_meta("measurement_source", "")) in ["visible_mesh_aabb", "generated_texture_alpha_calibrated_by_measured_mesh_aspect"], "%s collision must be measured from visible asset bounds" % station.name)
			if box != null and footprint.size() == 2:
				_check(is_equal_approx(box.size.x, float(footprint[0])) and is_equal_approx(box.size.z, float(footprint[1])), "%s collision footprint must match visible footprint" % station.name)
				var independently_measured := _independent_station_bounds(station)
				_check(independently_measured.size.x > 0.0 and independently_measured.size.z > 0.0, "%s must have independently measurable physical visual bounds" % station.name)
				_check(is_equal_approx(box.size.x, independently_measured.size.x) and is_equal_approx(box.size.z, independently_measured.size.z), "%s collider X/Z must match independently measured bounds" % station.name)
				if shape_node != null:
					var expected_center := Vector3(independently_measured.position.x + independently_measured.size.x * 0.5, shape_node.position.y, independently_measured.position.z + independently_measured.size.z * 0.5)
					_check(is_equal_approx(shape_node.position.x, expected_center.x) and is_equal_approx(shape_node.position.z, expected_center.z), "%s collider center must match independently measured bounds" % station.name)
			if shape_node != null:
				_check(shape_node.disabled, "%s collision must be disabled while the interior is inactive" % station.name)
	var transitioned := bool(interior.call("transition_to", true, "workshop", "qa_workshop_001"))
	_check(transitioned, "workshop transition must start")
	await _wait_transition(interior)
	_check(bool(interior.call("is_active")), "workshop must become active after transition")
	_check(room != null and room.visible, "workshop room must be visible after transition")
	if room != null:
		var active_shape := room.find_child("MeasuredProxy", true, false) as CollisionShape3D
		_check(active_shape != null and not active_shape.disabled, "interior collision must enable on entry")
	var exited := bool(interior.call("transition_to", false))
	_check(exited, "workshop exit transition must start")
	await _wait_transition(interior)
	_check(not bool(interior.call("is_active")), "workshop must become inactive after exit")
	_check(room != null and not room.visible, "workshop room must hide after exit")
	if room != null:
		var inactive_shape := room.find_child("MeasuredProxy", true, false) as CollisionShape3D
		_check(inactive_shape != null and inactive_shape.disabled, "interior collision must disable after exit")
	_finish(host)

func _wait_transition(interior: Node) -> void:
	await create_timer(0.85).timeout

func _independent_station_bounds(station: Node3D) -> AABB:
	var generated_sprite := station.get_node_or_null("GeneratedStationSprite") as Sprite3D
	if generated_sprite != null:
		var visual_size: Array = generated_sprite.get_meta("visual_world_size", [])
		var source_bounds: Array = station.get_meta("visible_mesh_bounds", [])
		if visual_size.size() == 2 and source_bounds.size() == 6:
			var width := float(visual_size[0])
			var depth := width * float(source_bounds[5]) / maxf(0.01, float(source_bounds[3]))
			return AABB(Vector3(-width * 0.5, 0.0, -depth * 0.5), Vector3(width, float(visual_size[1]), depth))
	var result := AABB()
	var found := false
	for value in station.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := value as MeshInstance3D
		if mesh_node == null or mesh_node.mesh == null or not mesh_node.visible:
			continue
		# This audit intentionally uses the source-asset declaration rather than
		# production's collision_contributor flag. It catches a solid visible mesh
		# that was accidentally marked presentation-only for the collider.
		if not mesh_node.has_meta("physical_asset_mesh"):
			failures.append("%s must declare physical_asset_mesh for independent audit" % mesh_node.name)
			continue
		if not bool(mesh_node.get_meta("physical_asset_mesh", false)):
			continue
		var source := mesh_node.get_aabb()
		var transform := station.global_transform.affine_inverse() * mesh_node.global_transform
		for corner in [
			Vector3(source.position.x, source.position.y, source.position.z),
			Vector3(source.end.x, source.position.y, source.position.z),
			Vector3(source.position.x, source.end.y, source.position.z),
			Vector3(source.position.x, source.position.y, source.end.z),
			Vector3(source.end.x, source.end.y, source.position.z),
			Vector3(source.end.x, source.position.y, source.end.z),
			Vector3(source.position.x, source.end.y, source.end.z),
			Vector3(source.end.x, source.end.y, source.end.z),
		]:
			var local_corner: Vector3 = transform * corner
			if not found:
				result = AABB(local_corner, Vector3.ZERO)
				found = true
			else:
				result = result.expand(local_corner)
	if not found:
		var declared_bounds: Array = station.get_meta("visible_mesh_bounds", [])
		if declared_bounds.size() == 6:
			return AABB(
				Vector3(float(declared_bounds[0]), float(declared_bounds[1]), float(declared_bounds[2])),
				Vector3(float(declared_bounds[3]), float(declared_bounds[4]), float(declared_bounds[5]))
			)
	return result

func _finish(host: Node) -> void:
	if is_instance_valid(host):
		host.queue_free()
	if failures.is_empty():
		print("WORKSHOP_INTERIOR_CONTRACT_PASS checks=%d" % checks)
		quit(0)
	else:
		print("WORKSHOP_INTERIOR_CONTRACT_FAIL count=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  " + failure)
		quit(1)
