extends SceneTree

## Physical acceptance for the four later expedition return legs. These routes
## share the authored capstone contract, but each still has to be navigable by
## the real camera-relative joystick and must not be extractable at the beacon
## until the return causeway has been crossed.

const MainScene = preload("res://main.tscn")

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("LATER_EXPEDITION_RETURN_FAIL: %s" % message)

func _clear_slot(slot: String) -> void:
	for suffix in [".json", ".backup.json", ".tmp.json"]:
		var path := "user://%s%s" % [slot, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _waypoint_input(world: Node, target: Vector3) -> Vector2:
	var player := world.get("player") as CharacterBody3D
	var delta := target - player.global_position
	delta.y = 0.0
	var right: Vector3 = world.get("camera_ground_right")
	var forward: Vector3 = world.get("camera_ground_forward")
	return Vector2(delta.dot(right), -delta.dot(forward)).normalized()

func _walk_to(world: Node, target: Vector3, tolerance := 1.05, max_frames := 520) -> bool:
	var player := world.get("player") as CharacterBody3D
	for _frame in max_frames:
		if _flat_distance(player.global_position, target) <= tolerance:
			player.call("set_joystick_vector", Vector2.ZERO)
			for _settle in 12:
				await physics_frame
			return true
		player.call("set_joystick_vector", _waypoint_input(world, target))
		await physics_frame
	player.call("set_joystick_vector", Vector2.ZERO)
	return _flat_distance(player.global_position, target) <= tolerance

func _interact_and_settle(world: Node, frames := 90) -> void:
	world.call("_interact")
	for _frame in frames:
		await physics_frame

func _find_route_resource(world: Node, zone_name: String, branch_id: String, resource_id: String) -> Node:
	for candidate in world.get_tree().get_nodes_in_group("resource_node"):
		if not is_instance_valid(candidate) or not candidate.is_visible_in_tree() or not candidate.is_in_group("interactable"):
			continue
		var parent := candidate.get_parent()
		if parent == null or parent.name != zone_name:
			continue
		if str(candidate.get("resource_id")) != resource_id or str(candidate.get_meta("route_branch", "")) != branch_id:
			continue
		return candidate
	return null

func _find_pickup_near(world: Node, position: Vector3) -> Node:
	var closest: Node = null
	var closest_distance := 2.2
	for candidate in world.get_tree().get_nodes_in_group("expedition_pickup"):
		if not is_instance_valid(candidate) or not candidate.is_visible_in_tree():
			continue
		var candidate_body := candidate as Node3D
		if candidate_body == null:
			continue
		var distance := _flat_distance(candidate_body.global_position, position)
		if distance < closest_distance:
			closest_distance = distance
			closest = candidate
	return closest

func _collect_resource_objective(world: Node, session: Node, zone_name: String, branch_id: String, resource_id: String) -> void:
	for _resource_pass in 8:
		if bool(session.expedition_run.get("objective_complete", false)):
			return
		var resource := _find_route_resource(world, zone_name, branch_id, resource_id)
		_check(resource != null, "%s resource remains physically discoverable" % zone_name)
		if resource == null:
			return
		var resource_position := (resource as Node3D).global_position
		_check(await _walk_to(world, resource_position, 1.55), "%s movement reaches %s" % [zone_name, resource_id])
		await _interact_and_settle(world)
		var pickup := _find_pickup_near(world, resource_position)
		_check(pickup != null, "%s harvesting creates a physical %s pickup" % [zone_name, resource_id])
		if pickup != null:
			_check(await _walk_to(world, (pickup as Node3D).global_position, 1.55), "%s movement reaches the %s pickup" % [zone_name, resource_id])
			await _interact_and_settle(world, 35)
	_check(bool(session.expedition_run.get("objective_complete", false)), "%s resource objective completes through physical collection" % zone_name)

func _run_route(world: Node, session: Node, destination: String, branch_id: String, resource_id: String) -> void:
	session.expedition_run = {"status": "none"}
	session.energy = 24
	session.coins = 300
	_check(bool(session.call("start_expedition", destination)), "%s expedition starts" % destination)
	world.call("_set_zone", destination)
	world.call("_restore_active_expedition_nodes")
	await physics_frame
	await physics_frame
	var zone_name := destination.replace(" ", "")
	var route := world.get_node_or_null("%s/ExpeditionRoute" % zone_name) as Node3D
	_check(route != null, "%s authored route exists" % destination)
	if route == null:
		return
	var marker := route.get_node_or_null("RouteChoiceMarker") as Node3D
	_check(marker != null, "%s route fork exists" % destination)
	if marker == null:
		return
	var branch_side := -0.8 if branch_id == str(session.call("expedition_branch_options", destination)[0]) else 0.8
	_check(await _walk_to(world, marker.global_position + Vector3(branch_side, 1.0, 0.0), 1.0), "%s movement reaches its route fork" % destination)
	world.call("_interact")
	await process_frame
	_check(str(session.expedition_run.get("branch_id", "")) == branch_id, "%s branch commits through physical interaction" % destination)
	if str(session.expedition_run.get("branch_id", "")) != branch_id:
		return
	await _collect_resource_objective(world, session, zone_name, branch_id, resource_id)
	var capstone := route.get_node_or_null("RouteCapstone_%s" % branch_id.capitalize()) as Node3D
	_check(capstone != null, "%s capstone exists for %s" % [destination, branch_id])
	if capstone == null:
		return
	var capstone_reached := await _walk_to(world, capstone.global_position, 1.55)
	_check(capstone_reached, "%s movement reaches its capstone" % destination)
	await _interact_and_settle(world, 25)
	_check(bool(session.expedition_run.get("shortcut_open", false)), "%s capstone opens its physical return shortcut" % destination)
	_check(bool(session.call("expedition_return_checkpoint_required")), "%s requires the return causeway after capstone" % destination)
	var player := world.get("player") as CharacterBody3D
	player.global_position = Vector3(2.7, 1.0, 7.5)
	world.call("_return_home")
	await process_frame
	_check(str(world.get("current_zone")) == destination, "%s premature beacon extraction is refused" % destination)
	_check(bool(session.call("has_active_expedition")), "%s premature extraction leaves the run active" % destination)
	var causeway := route.get_node_or_null("ReturnCauseway") as Node3D
	_check(causeway != null and causeway.visible, "%s return causeway is visible after capstone" % destination)
	if causeway == null:
		return
	_check(await _walk_to(world, causeway.global_position, 1.45), "%s movement crosses the return causeway" % destination)
	for _settle in 10:
		await physics_frame
	_check(not bool(session.call("expedition_return_checkpoint_required")), "%s causeway clears the extraction gate" % destination)
	_check(str(session.expedition_run.get("route_phase", "")) == "return", "%s causeway records the return phase" % destination)
	_check(await _walk_to(world, Vector3(0.0, 1.0, 7.5), 1.45), "%s movement reaches the beacon after causeway" % destination)
	world.call("_return_home")
	await process_frame
	_check(str(world.get("current_zone")) == "Sanctuary", "%s extracts after the physical return" % destination)
	_check(not bool(session.call("has_active_expedition")), "%s expedition closes after extraction" % destination)

func _run() -> void:
	var slot := "qa_later_expedition_return"
	_clear_slot(slot)
	ProjectSettings.set_setting("prodewty/save_slot", slot)
	var world := MainScene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var session: Node = world.get("session")
	_check(session != null, "later expedition test has a live session")
	if session == null:
		quit(1)
		return
	session.get("unlocked_routes").clear()
	for destination in ["Whisperwood", "Sunlit Beach", "Ember Ridge", "Glass Desert", "Sunken Dungeon"]:
		session.get("unlocked_routes").append(destination)
	await _run_route(world, session, "Sunlit Beach", "tidepool", "shell")
	await _run_route(world, session, "Ember Ridge", "quarry", "ore")
	await _run_route(world, session, "Glass Desert", "oasis", "fiber")
	await _run_route(world, session, "Sunken Dungeon", "vault", "relic")
	if is_instance_valid(world):
		world.queue_free()
	if failures.is_empty():
		print("LATER_EXPEDITION_RETURN_PASS checks=%d routes=4" % checks)
		quit(0)
	else:
		print("LATER_EXPEDITION_RETURN_FAIL failures=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  ", failure)
		quit(1)
