extends SceneTree

const MainScene := preload("res://main.tscn")

const SAVE_SLOT := "qa_workshop_interior_runtime"

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("WORKSHOP_INTERIOR_RUNTIME_FAIL: " + message)

func _run() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", SAVE_SLOT)
	var world := MainScene.instantiate()
	root.add_child(world)
	await _wait_frames(12)
	var interior := world.get("building_interior") as Node3D
	var sanctuary := world.get("sanctuary_zone") as Node3D
	var player := world.get("player") as CharacterBody3D
	_check(interior != null, "Main must expose the reusable building interior controller")
	_check(sanctuary != null and sanctuary.visible, "Sanctuary must start visible")
	_check(player != null, "Main must expose the player for interior entry")
	if interior == null or sanctuary == null or player == null:
		_finish(world)
		return
	var session := world.get("session") as Node
	if session != null:
		session.set("interior_stations", {"workshop_qa_001": {
			"furnace_left_001": {"id": "furnace_left_001", "structure_id": "workshop_qa_001", "kind": "furnace_left", "cell": [-2, -2], "rotation": 0, "state": "operational", "remaining_hours": 0.0, "total_hours": 12.0, "delivered_materials": {"stone": 3, "wood": 2}},
		}})
		session.set("station_job", {"kind": "ingot", "structure_id": "workshop_qa_001", "station_id": "furnace_left_001", "remaining_hours": 4.0, "total_hours": 12.0, "output_id": "ingot", "output": 1, "output_kind": "material", "tool_id": "", "quality_multiplier": 1.0, "action_id": "qa", "material_refunded": false})
	var structure_data := {
		"id": "workshop_qa_001",
		"kind": "workshop",
		"cell": [4, -6],
		"rotation": 0,
		"state": "operational",
		"remaining_hours": 0.0,
		"total_hours": 24.0,
		"delivered_materials": {"wood": 12, "stone": 8, "plank": 4},
	}
	if session != null:
		session.set("structures", {"workshop_qa_001": structure_data})
	world.call("_spawn_structure_visual", "workshop_qa_001", structure_data)
	await _wait_frames(4)
	var visuals: Dictionary = world.get("settlement_visuals")
	var structure := visuals.get("workshop_qa_001") as Node3D
	_check(structure != null, "operational workshop must have a visible runtime root")
	if structure == null:
		_finish(world)
		return
	var service_zone: Dictionary = world.call("_world_access_zone", structure, "service")
	var service_world: Vector3 = service_zone.get("world_center", Vector3.ZERO)
	var service_outward: Vector3 = service_zone.get("world_facing", Vector3(1.0, 0.0, 0.0))
	player.global_position = service_world + service_outward * 0.65
	player.global_position.y = 1.0
	world.call("_enter_building_interior", structure)
	await _wait_seconds(0.20)
	_check(not bool(world.get("interior_active")), "service hatch approach must not authorize Workshop entry")
	var door_zone: Dictionary = world.call("_world_access_zone", structure, "door")
	var door_world: Vector3 = door_zone.get("world_center", Vector3.ZERO)
	var door_outward: Vector3 = door_zone.get("world_facing", Vector3(0.0, 0.0, 1.0))
	player.global_position = door_world + door_outward * 0.90
	player.global_position.y = 1.0
	world.call("_contextual_interact")
	_check(bool(world.get("interior_transitioning")), "door interaction must begin an atomic transition")
	_check(bool(world.call("is_player_input_locked")), "player input must lock during the transition")
	player.call("set_joystick_vector", Vector2(1.0, 0.0))
	world.call("_toggle_pause")
	_check(not paused, "pause must not interrupt an in-flight building transition")
	world.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(paused, "focus loss must pause an in-flight building transition")
	await _wait_seconds(0.45)
	_check(bool(world.get("interior_transitioning")), "focus-loss pause must freeze the transition before context commit")
	world.notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	_check(not paused, "focus return must resume the frozen building transition")
	await _wait_seconds(0.85)
	_check(bool(world.get("interior_active")), "operational workshop must enter its playable interior")
	_check(not sanctuary.visible, "exterior Sanctuary presentation must phase out while inside")
	_check(bool(interior.call("is_active")), "interior controller must activate its room")
	_check(str(world.get("interior_instance_id")) == "workshop_qa_001", "interior must retain the persisted Workshop instance identity")
	world.call("_toggle_structure_placement")
	_check(not bool(world.get("placement_mode")), "Sanctuary placement must be forbidden while inside a building")
	world.call("_toggle_utilities")
	_check(not bool(world.get("utilities_open")), "Sanctuary ledger toggle must be forbidden while inside a building")
	_check(int(interior.call("active_station_count")) == 2, "entered workshop must mount its persisted fit-out during the entry transition")
	var entry_facing: Vector3 = player.get("last_direction")
	var expected_entry_facing: Vector3 = interior.call("entry_facing")
	_check(entry_facing.dot(expected_entry_facing) > 0.94, "interior spawn must face inward through the door")
	var reference_slots: Array = world.get("reference_slots")
	for slot_value in reference_slots:
		var slot := slot_value as Button
		if slot == null:
			continue
		var action_label := str(slot.get_meta("action_label", ""))
		if action_label in ["USE", "WATER", "BUILD"]:
			_check(not slot.disabled, "interior %s action must remain available" % action_label)
		else:
			_check(slot.disabled, "interior Sanctuary action slots must be disabled")
	var room := interior.get_node_or_null("WorkshopInteriorRoom") as Node3D
	_check(room != null and room.visible, "entered workshop room must be visible")
	if room != null:
		var active_collision := room.find_child("MeasuredProxy", true, false) as CollisionShape3D
		_check(active_collision != null and not active_collision.disabled, "entered workshop must enable measured station collision")
	# The room must mirror the durable station job rather than leaving a static
	# workstation visually indistinguishable from an active production order.
	await _wait_frames(3)
	var furnace_station := room.find_child("InteriorStation_furnace_left_001", true, false) as Node3D if room != null else null
	var furnace_label := furnace_station.get_node_or_null("StationLabel") as Label3D if furnace_station != null else null
	var job_marker := furnace_station.get_node_or_null("StationJobMarker") as MeshInstance3D if furnace_station != null else null
	_check(furnace_label != null and furnace_label.text.contains("WORKING"), "active furnace job must show a working status label")
	_check(job_marker != null and job_marker.visible, "active furnace job must show a presentation-only station marker")
	if session != null:
		var ready_job: Dictionary = session.get("station_job")
		ready_job["remaining_hours"] = 0.0
		session.set("station_job", ready_job)
	await _wait_frames(3)
	_check(furnace_label != null and furnace_label.text.contains("READY"), "completed furnace job must show a ready-to-claim status label")
	player.global_position = interior.call("exit_position")
	world.call("_contextual_interact")
	await _wait_seconds(0.85)
	_check(not bool(world.get("interior_active")), "workshop exit must restore exterior mode")
	_check(sanctuary.visible, "exiting must restore Sanctuary presentation")
	_check(not bool(interior.call("is_active")), "exiting must deactivate the interior room")
	_check(str(world.get("interior_instance_id")) == "", "exiting must clear only the transient interior pointer")
	_check((player.global_position - door_world).dot(door_outward) > 0.30, "egress must resolve beyond the measured front-door shell")
	_check(player.get("last_direction").dot(door_outward) > 0.94, "egress must preserve the measured outward door facing")
	var blocked_exit := StaticBody3D.new()
	blocked_exit.name = "BlockedEgressProbe"
	var blocked_shape := CollisionShape3D.new()
	var blocked_box := BoxShape3D.new()
	# Span the full probe corridor so the resolver must exhaust its checked
	# capsule candidates instead of simply finding a sixth clear point.
	blocked_box.size = Vector3(20.0, 4.0, 20.0)
	blocked_shape.shape = blocked_box
	blocked_exit.add_child(blocked_shape)
	world.add_child(blocked_exit)
	blocked_exit.global_position = door_world + door_outward * 0.90
	await process_frame
	world.set("interior_active", true)
	world.set("interior_kind", "workshop")
	world.set("interior_instance_id", "workshop_qa_001")
	world.set("interior_return_position", door_world + door_outward * 0.90)
	world.set("interior_return_facing", door_outward)
	interior.call("set_room_active", true, "workshop", "workshop_qa_001")
	sanctuary.visible = false
	world.call("_set_zone_collisions", sanctuary, false)
	world.call("_exit_building_interior")
	await _wait_seconds(0.85)
	_check(bool(world.get("interior_active")), "blocked egress must fail closed and keep the interior active")
	_check(not sanctuary.visible, "blocked egress must keep the exterior presentation disabled")
	_check(bool(interior.call("is_active")), "blocked egress must reopen the measured interior room")
	_check(not bool(world.get("interior_transitioning")), "blocked egress recovery must release the transition lock")
	blocked_exit.queue_free()
	await process_frame
	world.call("_exit_building_interior")
	await _wait_seconds(0.85)
	_check(not bool(world.get("interior_active")), "egress must succeed after the blocking obstacle is removed")
	var persisted_structures: Dictionary = session.get("structures") if session != null else {}
	_check(persisted_structures.has("workshop_qa_001"), "exiting must not mutate the persisted Workshop identity")
	if room != null:
		var inactive_collision := room.find_child("MeasuredProxy", true, false) as CollisionShape3D
		_check(inactive_collision != null and inactive_collision.disabled, "exiting must disable measured station collision")
	for rotation in [1, 2, 3]:
		structure_data["rotation"] = rotation
		if session != null:
			session.set("structures", {"workshop_qa_001": structure_data})
		world.call("_spawn_structure_visual", "workshop_qa_001", structure_data)
		await _wait_frames(3)
		structure = (world.get("settlement_visuals") as Dictionary).get("workshop_qa_001") as Node3D
		_check(structure != null, "rotated Workshop %d must retain its runtime root" % rotation)
		if structure == null:
			continue
		door_zone = world.call("_world_access_zone", structure, "door")
		door_world = door_zone.get("world_center", Vector3.ZERO)
		door_outward = door_zone.get("world_facing", Vector3(0.0, 0.0, 1.0))
		player.global_position = door_world + door_outward * 0.90
		player.global_position.y = 1.0
		world.call("_contextual_interact")
		await _wait_seconds(0.85)
		_check(bool(world.get("interior_active")), "rotation %d door must enter the Workshop" % rotation)
		_check(player.get("last_direction").dot(interior.call("entry_facing")) > 0.94, "rotation %d interior spawn must face inward" % rotation)
		player.global_position = interior.call("exit_position")
		world.call("_contextual_interact")
		await _wait_seconds(0.85)
		_check(not bool(world.get("interior_active")), "rotation %d exit must restore Sanctuary mode" % rotation)
		_check(player.global_position.distance_to(door_world) > 0.55, "rotation %d egress must be outside the door shell" % rotation)
		_check((player.global_position - door_world).dot(door_outward) > 0.30, "rotation %d egress must be on the outward side of the door" % rotation)
		_check(player.get("last_direction").dot(door_outward) > 0.94, "rotation %d egress must preserve outward facing" % rotation)
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
		print("WORKSHOP_INTERIOR_RUNTIME_PASS checks=%d" % checks)
		quit(0)
	else:
		print("WORKSHOP_INTERIOR_RUNTIME_FAIL count=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  " + failure)
		quit(1)
