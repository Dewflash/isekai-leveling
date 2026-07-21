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
	_check(int(interior.call("active_station_count")) == 1, "an un-fitted Workshop must expose only its measured exit")
	var room := interior.get_node_or_null("WorkshopInteriorRoom") as Node3D
	_check(room != null, "workshop room root must exist")
	_check(room != null and not room.visible, "workshop room must be hidden outside entry")
	_check(bool(interior.get("room_measurements_valid")), "workshop room must pass its measured collision validation")
	var floor_panel := room.get_node_or_null("WorkshopRoomShell/RegisteredWorkshopFloorPanel") as MeshInstance3D if room != null else null
	_check(floor_panel != null, "Workshop must expose a room-local registered floor panel")
	if floor_panel != null:
		_check((floor_panel.get_meta("registered_world_size", []) as Array).size() == 2, "registered floor panel must retain measured world bounds")
		_check(str(floor_panel.get_meta("asset_path", "")) == "res://assets/generated/sanctuary/workshop/workshop-floor-panel-v2.png", "registered floor panel must bind its authored texture")
		var floor_mesh := floor_panel.mesh as QuadMesh
		var measured_room := interior.call("room_dimensions") as Vector3
		_check(floor_mesh != null and is_equal_approx(floor_mesh.size.x, measured_room.x) and is_equal_approx(floor_mesh.size.y, measured_room.z), "registered floor panel must exactly cover the measured room envelope")
		var floor_material := floor_panel.material_override as ShaderMaterial
		_check(floor_material != null and floor_material.get_shader_parameter("albedo_texture") != null, "registered floor panel must use an authored shader texture")
	for wall_id in ["RegisteredBackWallPanel", "RegisteredLeftWallPanel", "RegisteredRightWallPanel", "RegisteredFrontCutawayLeft", "RegisteredFrontCutawayRight"]:
		var wall_panel := room.get_node_or_null("WorkshopRoomShell/" + wall_id) as MeshInstance3D if room != null else null
		_check(wall_panel != null, "Workshop must expose room-local %s" % wall_id)
		if wall_panel != null:
			_check(bool(wall_panel.get_meta("presentation_only", false)), "%s must remain presentation-only" % wall_id)
			_check((wall_panel.get_meta("registered_world_size", []) as Array).size() == 2, "%s must retain measured world bounds" % wall_id)
			_check(str(wall_panel.get_meta("asset_path", "")) == "res://assets/generated/sanctuary/workshop/workshop-wall-panel-v1.png", "%s must bind the authored wall texture" % wall_id)
			_check(wall_panel.material_override is ShaderMaterial, "%s must use the authored toon surface shader" % wall_id)
	var empty_station_ids: Array = interior.call("station_ids")
	_check(empty_station_ids.has("exit") and empty_station_ids.size() == 1, "empty Workshop must not auto-install functional stations")
	var persisted_stations := {
		"furnace_left_001": {"id": "furnace_left_001", "structure_id": "qa_workshop_001", "kind": "furnace_left", "cell": [-3, -2], "rotation": 0, "state": "operational", "remaining_hours": 0.0, "total_hours": 12.0, "delivered_materials": {"stone": 3, "wood": 2}},
		"furnace_right_001": {"id": "furnace_right_001", "structure_id": "qa_workshop_001", "kind": "furnace_right", "cell": [1, -2], "rotation": 0, "state": "building", "remaining_hours": 6.0, "total_hours": 12.0, "delivered_materials": {"stone": 3, "wood": 2}},
		"workbench_001": {"id": "workbench_001", "structure_id": "qa_workshop_001", "kind": "workbench", "cell": [-2, 0], "rotation": 0, "state": "blueprint", "remaining_hours": 0.0, "total_hours": 12.0, "delivered_materials": {"wood": 0, "stone": 0}},
		"anvil_001": {"id": "anvil_001", "structure_id": "qa_workshop_001", "kind": "anvil", "cell": [1, 0], "rotation": 0, "state": "operational", "remaining_hours": 0.0, "total_hours": 12.0, "delivered_materials": {"stone": 2, "plank": 1}},
		"storage_001": {"id": "storage_001", "structure_id": "qa_workshop_001", "kind": "storage", "cell": [2, 1], "rotation": 0, "state": "operational", "remaining_hours": 0.0, "total_hours": 8.0, "delivered_materials": {"wood": 3, "stone": 1}},
	}
	interior.call("sync_persisted_stations", persisted_stations)
	_check(int(interior.call("active_station_count")) == 6, "persisted Workshop fit-out must expose installed stations plus exit")
	_check(bool(interior.call("has_operational_furnace")), "operational interior furnaces must expose the station audio context")
	var station_ids: Array = interior.call("station_ids")
	for expected_id in ["furnace_left_001", "furnace_right_001", "workbench_001", "anvil_001", "storage_001", "exit"]:
		_check(station_ids.has(expected_id), "workshop must expose persisted station %s" % expected_id)
	for construction_id in ["furnace_right_001", "workbench_001"]:
		var construction_station := room.get_node_or_null("InteriorStation_" + construction_id) as Node3D if room != null else null
		var construction_frame := construction_station.get_node_or_null("ConstructionFrame") as Node3D if construction_station != null else null
		var construction_materials := construction_station.get_node_or_null("ConstructionMaterials") as Node3D if construction_station != null else null
		_check(construction_frame != null, "%s must expose scaffold geometry during construction" % construction_id)
		_check(construction_materials != null, "%s must expose delivered-material geometry during construction" % construction_id)
		if construction_frame != null:
			for frame_mesh_value in construction_frame.find_children("*", "MeshInstance3D", true, false):
				var frame_mesh := frame_mesh_value as MeshInstance3D
				if frame_mesh != null:
					_check(not bool(frame_mesh.get_meta("collision_contributor", true)), "%s scaffold mesh must not expand the measured hitbox" % construction_id)
		if construction_materials != null:
			_check(construction_materials.visible == (construction_id == "furnace_right_001"), "%s material visibility must follow its persisted construction state" % construction_id)
	_check(not bool(interior.call("configure_for_structure", "archive", workshop_measurement, AssetCatalog.structure_access_zones("workshop", 0), {})), "Workshop controller must reject unsupported interior kinds")
	var invalid_host := Node3D.new()
	invalid_host.name = "InvalidMeasurementHost"
	host.add_child(invalid_host)
	var invalid_interior := InteriorScript.new() as Node3D
	invalid_interior.call("build", invalid_host)
	_check(bool(invalid_interior.call("configure_for_structure", "workshop", workshop_measurement, AssetCatalog.structure_access_zones("workshop", 0), workshop_definition.get("interior_profile", {}))), "adversarial Workshop must configure before invalidation")
	invalid_interior.call("sync_persisted_stations", persisted_stations)
	var invalid_room := invalid_interior.get_node_or_null("WorkshopInteriorRoom") as Node3D
	var invalid_station := invalid_room.get_node_or_null("InteriorStation_anvil_001") as Node3D if invalid_room != null else null
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
