extends SceneTree

const MainScene = preload("res://main.tscn")
const ContentRegistry = preload("res://scripts/content_registry.gd")

var failures: Array[String] = []
var checks := 0

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _waypoint_input(world: Node, target: Vector3) -> Vector2:
	var player := world.get("player") as CharacterBody3D
	var delta := target - player.global_position
	delta.y = 0.0
	var right: Vector3 = world.get("camera_ground_right")
	var forward: Vector3 = world.get("camera_ground_forward")
	return Vector2(delta.dot(right), -delta.dot(forward)).normalized()

func _walk_to(world: Node, target: Vector3, tolerance := 1.0) -> bool:
	var player := world.get("player") as CharacterBody3D
	for _frame in 180:
		if _flat_distance(player.global_position, target) <= tolerance:
			player.call("set_joystick_vector", Vector2.ZERO)
			for _settle_frame in 24:
				await physics_frame
			return true
		player.call("set_joystick_vector", _waypoint_input(world, target))
		await physics_frame
	player.call("set_joystick_vector", Vector2.ZERO)
	for _settle_frame in 24:
		await physics_frame
	return _flat_distance(player.global_position, target) <= tolerance

func _find_gate(destination: String) -> Node3D:
	for candidate in get_nodes_in_group("route_gate"):
		if str(candidate.get_meta("destination_id", "")) == destination:
			return candidate as Node3D
	return null

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", "qa_traversal_contract")
	for save_path in ["user://qa_traversal_contract.json", "user://qa_traversal_contract.backup.json", "user://qa_traversal_contract.tmp.json"]:
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	var world := MainScene.instantiate()
	root.add_child(world)
	await process_frame
	var player := world.get("player") as CharacterBody3D
	_check(player != null, "traversal contract requires a live player body")
	for socket_id in ContentRegistry.ROUTE_SOCKETS:
		world.call("_set_zone", "Sanctuary")
		await physics_frame
		var socket: Dictionary = ContentRegistry.ROUTE_SOCKETS[socket_id]
		var destination := str(socket.get("destination_id", ""))
		var gate := _find_gate(destination)
		_check(gate != null, "%s must have a physical route gate" % destination)
		var waypoints: Array = socket.get("traversal_waypoints", [])
		_check(waypoints.size() >= 2, "%s must publish an authored traversal path" % destination)
		var reached_all := true
		for waypoint_value in waypoints:
			if not waypoint_value is Array or waypoint_value.size() < 2:
				reached_all = false
				continue
			var waypoint := Vector3(float(waypoint_value[0]), 1.0, float(waypoint_value[1]))
			if not await _walk_to(world, waypoint, 0.95):
				reached_all = false
				break
		var final_distance := _flat_distance(player.global_position, gate.global_position) if gate != null else INF
		_check(reached_all, "%s must be reachable through camera-relative joystick movement (end %.2fm from gate)" % [destination, final_distance])
		_check(final_distance <= 2.85, "%s gate must be inside the interaction radius after a real walk (%.2fm)" % [destination, final_distance])
		_check(player.velocity.length() < 0.1, "%s traversal must release joystick without residual drift" % destination)
	world.queue_free()
	if failures.is_empty():
		print("TRAVERSAL_CONTRACT_PASS checks=%d routes=%d" % [checks, ContentRegistry.ROUTE_SOCKETS.size()])
		quit(0)
	else:
		print("TRAVERSAL_CONTRACT_FAIL failures=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  ", failure)
		quit(1)
