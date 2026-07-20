extends SceneTree

## Physical acceptance pass for the first authored route. The player is only
## placed at the expedition entry during setup; every route beat after that is
## reached through the same camera-relative joystick contract as gameplay.

const MainScene = preload("res://main.tscn")

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("WHISPERWOOD_PHYSICAL_FAIL: %s" % message)

func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _waypoint_input(world: Node, target: Vector3) -> Vector2:
	var player := world.get("player") as CharacterBody3D
	var delta := target - player.global_position
	delta.y = 0.0
	var right: Vector3 = world.get("camera_ground_right")
	var forward: Vector3 = world.get("camera_ground_forward")
	return Vector2(delta.dot(right), -delta.dot(forward)).normalized()

func _walk_to(world: Node, target: Vector3, tolerance := 1.05) -> bool:
	var player := world.get("player") as CharacterBody3D
	for _frame in 240:
		if _flat_distance(player.global_position, target) <= tolerance:
			player.call("set_joystick_vector", Vector2.ZERO)
			for _settle in 12:
				await physics_frame
			return true
		player.call("set_joystick_vector", _waypoint_input(world, target))
		await physics_frame
	player.call("set_joystick_vector", Vector2.ZERO)
	return _flat_distance(player.global_position, target) <= tolerance

func _prepare_run(world: Node, session: Node) -> void:
	session.expedition_run = {"status": "none"}
	session.energy = 24
	_check(bool(session.call("start_expedition", "Whisperwood")), "Whisperwood run starts")
	world.call("_set_zone", "Whisperwood")
	await physics_frame
	await physics_frame

func _reach_arrival_and_fork(world: Node, session: Node) -> bool:
	var player := world.get("player") as CharacterBody3D
	_check(await _walk_to(world, Vector3(0.0, 1.0, 5.2)), "joystick reaches Arrival Grove")
	_check(str(session.expedition_run.get("route_phase")) == "arrival", "Arrival Grove commits the arrival checkpoint")
	_check(session.expedition_run.get("route_checkpoints", []).has("arrival"), "arrival checkpoint persists in the active run")
	_check(await _walk_to(world, Vector3(0.0, 1.0, -1.9)), "joystick reaches Old Trail Fork")
	_check(str(session.expedition_run.get("route_phase")) == "fork", "Old Trail Fork commits the fork checkpoint")
	_check(session.expedition_run.get("route_checkpoints", []) == ["arrival", "fork"], "arrival and fork remain ordered")
	return player != null

func _choose_branch(world: Node, branch_id: String) -> void:
	var marker := world.get_node_or_null("Whisperwood/WhisperwoodRoute/WhisperwoodBranchChoice") as Node3D
	if marker == null:
		_check(false, "Whisperwood branch marker exists")
		return
	var side := -0.8 if branch_id == "grove" else 0.8
	_check(await _walk_to(world, marker.global_position + Vector3(side, 1.0, 0.0), 1.0), "%s branch side is reachable" % branch_id)
	world.call("_interact")
	await process_frame
	var session: Node = world.get("session")
	_check(str(session.expedition_run.get("branch_id")) == branch_id, "%s branch commits through the nearby interaction" % branch_id)

func _run() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", "qa_whisperwood_physical")
	for suffix in [".json", ".backup.json", ".tmp.json"]:
		var path := "user://qa_whisperwood_physical%s" % suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var world := MainScene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var session: Node = world.get("session")
	_check(session != null, "physical journey requires a live session")
	if session == null:
		quit(1)
		return
	session.get("unlocked_routes").clear()
	session.get("unlocked_routes").append("Whisperwood")
	session.coins = 100

	await _prepare_run(world, session)
	var guardian: Node = null
	for candidate in get_nodes_in_group("guardian"):
		if candidate.get_parent() != null and candidate.get_parent().name == "Whisperwood":
			guardian = candidate
			break
	_check(guardian != null, "Whisperwood guardian exists")
	_check(await _reach_arrival_and_fork(world, session), "arrival and fork traversal has a player body")
	# The uncommitted route can be walked into the clearing, but its guardian is
	# intentionally dormant until the player owns that branch.
	_check(await _walk_to(world, Vector3(12.5, 1.0, -8.6)), "pre-commit clearing remains physically reachable")
	if guardian != null:
		_check((guardian.get_node("CollisionShape3D") as CollisionShape3D).disabled, "guardian collision is dormant before branch commitment")
	_check(await _walk_to(world, Vector3(0.0, 1.0, -1.9)), "player can return to the fork before committing")
	await _choose_branch(world, "grove")
	_check(await _walk_to(world, Vector3(-3.8, 1.0, -4.1)), "grove approach is reachable")
	_check(await _walk_to(world, Vector3(-12.5, 1.0, -8.6)), "Fern Grove endpoint is reachable")
	_check(str(session.expedition_run.get("route_phase")) == "objective", "Fern Grove endpoint opens the grove objective")
	_check(session.expedition_run.get("route_checkpoints", []) == ["arrival", "fork"], "endpoint traversal does not reorder route checkpoints")

	await _prepare_run(world, session)
	await _reach_arrival_and_fork(world, session)
	await _choose_branch(world, "clearing")
	_check(await _walk_to(world, Vector3(3.8, 1.0, -4.1)), "clearing approach is reachable")
	# Stop at the authored clearing envelope rather than walking into the
	# guardian's measured hurtbox at its exact center.
	_check(await _walk_to(world, Vector3(10.5, 1.0, -7.2)), "Guardian Clearing endpoint is reachable")
	_check(str(session.expedition_run.get("route_phase")) == "objective", "Guardian Clearing endpoint opens the guardian objective")
	if guardian != null:
		await process_frame
		_check(not (guardian.get_node("CollisionShape3D") as CollisionShape3D).disabled, "guardian collision activates after clearing commitment")

	world.queue_free()
	if failures.is_empty():
		print("WHISPERWOOD_PHYSICAL_JOURNEY_PASS checks=%d" % checks)
		quit(0)
	else:
		print("WHISPERWOOD_PHYSICAL_JOURNEY_FAIL failures=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  ", failure)
		quit(1)
