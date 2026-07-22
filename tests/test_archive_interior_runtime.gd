extends SceneTree

const MainScene := preload("res://main.tscn")

const SAVE_SLOT := "qa_archive_interior_runtime"

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("ARCHIVE_INTERIOR_RUNTIME_FAIL: " + message)

func _run() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", SAVE_SLOT)
	var world := MainScene.instantiate()
	root.add_child(world)
	await _wait_frames(12)
	var interior := world.get("building_interior") as Node3D
	var sanctuary := world.get("sanctuary_zone") as Node3D
	var player := world.get("player") as CharacterBody3D
	var session := world.get("session") as Node
	_check(interior != null, "Main must expose the reusable building interior controller")
	_check(sanctuary != null and sanctuary.visible, "Sanctuary must start visible")
	_check(player != null and session != null, "Archive runtime requires the player and session")
	if interior == null or sanctuary == null or player == null or session == null:
		_finish(world)
		return

	var archive_data := {
		"id": "archive_qa_001",
		"kind": "archive",
		"cell": [4, -6],
		"rotation": 0,
		"state": "operational",
		"remaining_hours": 0.0,
		"total_hours": 30.0,
		"delivered_materials": {"wood": 8, "stone": 8, "plank": 3},
	}
	var structures := {"archive_qa_001": archive_data}
	var built: Dictionary = session.get("built").duplicate(true)
	built["library"] = true
	session.set("structures", structures)
	session.set("built", built)
	world.call("_copy_session_to_runtime")
	world.call("_spawn_structure_visual", "archive_qa_001", archive_data)
	await _wait_frames(4)

	for rotation in [0, 1, 2, 3]:
		archive_data["rotation"] = rotation
		session.set("structures", {"archive_qa_001": archive_data})
		world.call("_copy_session_to_runtime")
		world.call("_spawn_structure_visual", "archive_qa_001", archive_data)
		await _wait_frames(4)
		var visuals: Dictionary = world.get("settlement_visuals")
		var structure := visuals.get("archive_qa_001") as Node3D
		_check(structure != null, "rotation %d must retain a visible Archive runtime root" % rotation)
		if structure == null:
			continue
		var measurement: Dictionary = structure.get_meta("source_measurement", {})
		_check(bool(measurement.get("valid", false)), "rotation %d Archive shell must retain a valid source measurement" % rotation)
		var door_zone: Dictionary = world.call("_world_access_zone", structure, "door", "front_door")
		var door_world: Vector3 = door_zone.get("world_center", Vector3.ZERO)
		var door_outward: Vector3 = door_zone.get("world_facing", Vector3(0.0, 0.0, 1.0))
		_check(str(door_zone.get("kind", "")) == "door", "rotation %d must expose its measured front door" % rotation)
		_check(door_outward.length_squared() > 0.9, "rotation %d door facing must remain normalized" % rotation)
		player.global_position = door_world + door_outward * 0.90
		player.global_position.y = 1.0
		world.call("_contextual_interact")
		await _wait_seconds(0.85)
		_check(bool(world.get("interior_active")), "rotation %d Archive door must enter the interior" % rotation)
		_check(str(world.get("interior_kind")) == "archive", "rotation %d must commit the Archive interior kind" % rotation)
		_check(not sanctuary.visible, "rotation %d must phase out the exterior Sanctuary presentation" % rotation)
		_check(bool(interior.call("is_active")), "rotation %d Archive room must be active" % rotation)
		_check(str(interior.get("active_instance_id")) == "archive_qa_001", "rotation %d must retain the Archive instance identity" % rotation)
		_check(interior.get_node_or_null("ArchiveInteriorRoom") != null, "rotation %d must use the Archive room profile" % rotation)
		_check(int(interior.call("active_station_count")) == 2, "rotation %d Archive room must expose its door and research desk" % rotation)
		var expected_facing: Vector3 = interior.call("entry_facing")
		_check(player.get("last_direction").dot(expected_facing) > 0.94, "rotation %d interior spawn must face inward through the measured door" % rotation)

		var room := interior.get_node_or_null("ArchiveInteriorRoom") as Node3D
		var desk := interior.get_node_or_null("ArchiveInteriorRoom/InteriorStation_archive_desk") as Node3D
		_check(room != null and room.visible, "rotation %d Archive room must be visible" % rotation)
		_check(desk != null, "rotation %d Archive room must contain its research desk" % rotation)
		if room != null:
			var active_collision := room.find_child("MeasuredProxy", true, false) as CollisionShape3D
			_check(active_collision != null and not active_collision.disabled, "rotation %d Archive room must enable measured collision" % rotation)
		if desk != null:
			_check(str(desk.get_meta("interior_action", "")) == "archive", "rotation %d research desk must invoke Archive research" % rotation)
			_check(bool(desk.get_meta("measurement_valid", false)), "rotation %d research desk must have a measured visible envelope" % rotation)
			var desk_collision := desk.get_node_or_null("VisibleAssetCollision/MeasuredProxy") as CollisionShape3D
			_check(desk_collision != null and not desk_collision.disabled, "rotation %d research desk hitbox must be active and measured" % rotation)
			player.global_position = desk.global_position + Vector3(0.0, 0.0, 1.0)
			player.global_position.y = 1.0
			world.call("_contextual_interact")
			await _wait_frames(2)
			_check(not bool(world.get("interior_station_placement_mode")), "Archive desk interaction must not enter Workshop fit-out mode")

		player.global_position = interior.call("exit_position")
		world.call("_contextual_interact")
		await _wait_seconds(0.85)
		_check(not bool(world.get("interior_active")), "rotation %d Archive exit must restore exterior mode" % rotation)
		_check(sanctuary.visible, "rotation %d Archive exit must restore Sanctuary presentation" % rotation)
		_check(not bool(interior.call("is_active")), "rotation %d Archive exit must deactivate the room" % rotation)
		_check(player.get("last_direction").dot(door_outward) > 0.94, "rotation %d Archive egress must preserve measured outward facing" % rotation)

	_finish(world)

func _wait_frames(count: int) -> void:
	for _index in count:
		await process_frame

func _wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout

func _finish(world: Node) -> void:
	if is_instance_valid(world):
		world.queue_free()
	if failures.is_empty():
		print("ARCHIVE_INTERIOR_RUNTIME_PASS checks=%d" % checks)
		quit(0)
	else:
		print("ARCHIVE_INTERIOR_RUNTIME_FAIL count=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  " + failure)
		quit(1)
