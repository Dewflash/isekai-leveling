extends SceneTree

## Physical acceptance pass for the complete first expedition loop. This is
## intentionally broader than a session test: movement, route landmarks,
## interaction timing, physical drops, a capstone, pressure, reload, combat,
## and extraction must all agree before the loop is considered playable.

const MainScene = preload("res://main.tscn")

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("WHISPERWOOD_FULL_LOOP_FAIL: %s" % message)

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

func _walk_to(world: Node, target: Vector3, tolerance := 1.05, max_frames := 420) -> bool:
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

func _prepare_run(world: Node, session: Node) -> void:
	session.expedition_run = {"status": "none"}
	session.energy = 24
	_check(bool(session.call("start_expedition", "Whisperwood")), "Whisperwood run starts")
	world.call("_set_zone", "Whisperwood")
	world.call("_restore_active_expedition_nodes")
	await physics_frame
	await physics_frame

func _reach_fork(world: Node, session: Node) -> void:
	_check(await _walk_to(world, Vector3(0.0, 1.0, 5.2)), "movement reaches the Arrival Grove")
	_check(str(session.expedition_run.get("route_phase", "")) == "arrival", "arrival checkpoint is earned physically")
	_check(await _walk_to(world, Vector3(0.0, 1.0, -1.9)), "movement reaches the Old Trail Fork")
	_check(str(session.expedition_run.get("route_phase", "")) == "fork", "fork checkpoint is earned physically")
	_check(session.expedition_run.get("route_checkpoints", []) == ["arrival", "fork"], "route checkpoints remain ordered")

func _choose_branch(world: Node, branch_id: String) -> void:
	var marker := world.get_node_or_null("Whisperwood/WhisperwoodRoute/WhisperwoodBranchChoice") as Node3D
	_check(marker != null, "branch marker exists")
	if marker == null:
		return
	var side := -0.8 if branch_id == "grove" else 0.8
	_check(await _walk_to(world, marker.global_position + Vector3(side, 1.0, 0.0), 1.0), "%s branch side is reachable" % branch_id)
	world.call("_interact")
	await process_frame
	var session: Node = world.get("session")
	_check(str(session.expedition_run.get("branch_id", "")) == branch_id, "%s branch commits through interaction" % branch_id)

func _find_resource(world: Node, stable_id: String) -> Node:
	for candidate in world.get_tree().get_nodes_in_group("resource_node"):
		if is_instance_valid(candidate) and str(candidate.get("node_id")) == stable_id and candidate.is_visible_in_tree():
			return candidate
	return null

func _find_pickup(world: Node, pickup_id: String) -> Node:
	for candidate in world.get_tree().get_nodes_in_group("expedition_pickup"):
		if is_instance_valid(candidate) and str(candidate.get("pickup_id")) == pickup_id and candidate.is_visible_in_tree():
			return candidate
	return null

func _interact_and_settle(world: Node, frames := 90) -> void:
	world.call("_interact")
	for _frame in frames:
		await physics_frame

func _run_grove_loop(world: Node, session: Node) -> void:
	await _prepare_run(world, session)
	await _reach_fork(world, session)
	await _choose_branch(world, "grove")
	_check(await _walk_to(world, Vector3(-12.5, 1.0, -8.6)), "movement reaches the Whisperglass Grove endpoint")
	_check(str(session.expedition_run.get("route_phase", "")) == "objective", "grove endpoint opens the objective")

	var mushroom := _find_resource(world, "Whisperwood:FernGroveMushroom")
	_check(mushroom != null, "grove discovery resource exists")
	if mushroom == null:
		return
	_check(await _walk_to(world, mushroom.global_position, 1.55), "movement reaches the grove resource")
	await _interact_and_settle(world)
	var pickup_id := "Whisperwood:FernGroveMushroom:drop"
	var pickup := _find_pickup(world, pickup_id)
	_check(pickup != null, "harvesting creates a physical grove drop")
	if pickup == null:
		return
	_check(await _walk_to(world, pickup.global_position, 1.55), "movement reaches the grove drop")
	await _interact_and_settle(world, 30)
	_check(_find_pickup(world, pickup_id) == null, "physical grove drop is collected")
	_check(int(session.expedition_run.get("cargo", {}).get("berries", 0)) == 1, "collected discovery enters at-risk cargo")
	_check(bool(session.expedition_run.get("objective_complete", false)), "discovery pickup completes the grove objective")

	var cache := world.get_node_or_null("Whisperwood/WhisperwoodRoute/WhisperCache_Grove") as Node3D
	_check(cache != null, "grove cache exists")
	if cache == null:
		return
	_check(await _walk_to(world, cache.global_position, 1.65), "movement reaches the grove cache")
	await _interact_and_settle(world, 20)
	_check(bool(session.expedition_run.get("shortcut_open", false)), "cache opens the physical return shortcut")
	_check(bool(session.expedition_run.get("stake_active", false)), "cache starts return pressure")
	_check(bool(session.call("expedition_return_checkpoint_required")), "cached run requires the return landmark")
	_check(bool(session.call("save_game")), "cached run saves before reload")

func _reload_world(slot: String) -> Node:
	var old_world: Node = root.get_node_or_null("Prodewty")
	if old_world != null:
		old_world.queue_free()
		await process_frame
	var reloaded: Node = MainScene.instantiate()
	root.add_child(reloaded)
	await process_frame
	await process_frame
	return reloaded

func _run_return_after_reload(world: Node, session: Node) -> void:
	_check(bool(session.call("has_active_expedition")), "reload keeps the expedition active")
	_check(str(session.expedition_run.get("route_phase", "")) == "shortcut", "reload keeps the shortcut phase")
	_check(bool(session.call("expedition_return_checkpoint_required")), "reload keeps the physical return requirement")
	var pressure_interval := float(session.call("expedition_pressure_interval"))
	var pressure: Dictionary = session.call("advance_expedition_pressure", pressure_interval)
	_check(bool(pressure.get("triggered", false)), "return pressure resolves after reload")
	_check(int(pressure.get("energy_loss", 0)) == 1, "pressure drains one authored Energy")
	var gameplay_extensions: Node = root.get_node_or_null("GameplayExtensions")
	if gameplay_extensions != null and gameplay_extensions.has_method("whisperwood_return_route_distance"):
		var open_distance := float(gameplay_extensions.call("whisperwood_return_route_distance", "grove", true))
		var closed_distance := float(gameplay_extensions.call("whisperwood_return_route_distance", "grove", false))
		_check(open_distance < closed_distance, "opening the shortcut materially shortens the authored return route")

	var player := world.get("player") as CharacterBody3D
	var cargo_before: Dictionary = session.expedition_run.get("cargo", {}).duplicate(true)
	var inventory_before: Dictionary = session.get("inventory").duplicate(true)
	# This is deliberately inside the beacon radius but outside the Return
	# Footbridge envelope. The world command and the authoritative session
	# command must both refuse to bank the run here.
	player.global_position = Vector3(2.7, 1.0, 7.5)
	world.call("_return_home")
	await process_frame
	_check(str(world.get("current_zone")) == "Whisperwood", "premature cached extraction stays in the expedition")
	_check(bool(session.call("has_active_expedition")), "premature extraction leaves the run active")
	_check(session.expedition_run.get("cargo", {}) == cargo_before, "premature extraction does not mutate at-risk cargo")
	_check(session.get("inventory") == inventory_before, "premature extraction does not bank inventory")
	_check(session.call("finish_expedition", "Whisperwood", [0.0, 1.0, 7.5]).is_empty(), "session extraction also fails before Return Footbridge")

	_check(await _walk_to(world, Vector3(0.0, 1.0, 8.7)), "movement crosses the Return Footbridge after reload")
	_check(str(session.expedition_run.get("route_phase", "")) == "return", "Return Footbridge is authoritative")
	_check(not bool(session.call("expedition_return_checkpoint_required")), "return landmark clears the extraction requirement")
	_check(await _walk_to(world, Vector3(0.0, 1.0, 7.5)), "movement reaches the expedition beacon")
	world.call("_return_home")
	await process_frame
	_check(str(world.get("current_zone")) == "Sanctuary", "cached cargo extracts back to Sanctuary")
	_check(not bool(session.call("has_active_expedition")), "cached expedition closes on extraction")
	_check(int(session.get("inventory").get("berries", 0)) >= 3, "banked cargo includes the gathered and cache berries")
	_check(int(session.get("inventory").get("fiber", 0)) >= 1, "banked cargo includes the cache fiber")

func _run_clearing_combat(world: Node, session: Node) -> void:
	await _prepare_run(world, session)
	await _reach_fork(world, session)
	await _choose_branch(world, "clearing")
	_check(await _walk_to(world, Vector3(10.5, 1.0, -7.2)), "movement reaches the Guardian Clearing")
	_check(str(session.expedition_run.get("route_phase", "")) == "objective", "clearing endpoint opens the combat objective")
	var guardian: Node3D = null
	for candidate in world.get_tree().get_nodes_in_group("guardian"):
		if candidate.get_parent() != null and candidate.get_parent().name == "Whisperwood" and candidate.is_visible_in_tree():
			guardian = candidate as Node3D
			break
	_check(guardian != null, "forest guardian exists after branch commitment")
	if guardian == null:
		return
	var player := world.get("player") as CharacterBody3D
	player.global_position = guardian.global_position + Vector3(0.0, 0.0, 2.0)
	var facing := guardian.global_position - player.global_position
	facing.y = 0.0
	player.set("last_direction", facing.normalized())
	# The guardian's chase/telegraph behavior is covered by its dedicated QA
	# suite. Freeze only its movement here so this acceptance pass isolates the
	# live player hit query and durable reward boundary.
	guardian.set_physics_process(false)
	world.call("_resolve_player_attack_hit")
	await physics_frame
	var damaged_health := int(guardian.get("health"))
	_check(damaged_health > 0 and damaged_health < int(guardian.get("max_health")), "a live guardian can be damaged without being defeated")
	var saved_guardian_states: Dictionary = session.expedition_run.get("guardian_states", {})
	_check(saved_guardian_states.has("forest_slime"), "nonfatal guardian damage enters the expedition save")
	_check(bool(session.call("save_game")), "nonfatal guardian damage saves before reload")
	world = await _reload_world("qa_whisperwood_full_loop")
	session = world.get("session")
	world.call("_set_zone", "Whisperwood")
	world.call("_restore_active_expedition_nodes")
	await physics_frame
	await physics_frame
	var restored_guardian: Node3D = null
	for candidate in world.get_tree().get_nodes_in_group("guardian"):
		if str(candidate.get("guardian_id")) == "forest_slime" and candidate.is_visible_in_tree():
			restored_guardian = candidate as Node3D
			break
	_check(restored_guardian != null, "damaged guardian survives the scene reload")
	if restored_guardian == null:
		return
	guardian = restored_guardian
	_check(int(guardian.get("health")) == damaged_health, "guardian health survives the scene reload")
	_check(_flat_distance(guardian.global_position, Vector3(float(saved_guardian_states["forest_slime"].get("position", [0.0, 1.0, 0.0])[0]), 1.0, float(saved_guardian_states["forest_slime"].get("position", [0.0, 1.0, 0.0])[2]))) < 0.05, "guardian position survives the scene reload")
	player = world.get("player") as CharacterBody3D
	player.global_position = guardian.global_position + Vector3(0.0, 0.0, 2.0)
	facing = guardian.global_position - player.global_position
	facing.y = 0.0
	player.set("last_direction", facing.normalized())
	await physics_frame
	await physics_frame
	var health_before_failed_commit := int(guardian.get("health"))
	var energy_before_failed_commit := int(session.get("energy"))
	session.save_blocked = true
	world.call("_resolve_player_attack_hit")
	await physics_frame
	session.save_blocked = false
	_check(int(guardian.get("health")) == health_before_failed_commit, "failed combat save rolls back guardian damage")
	_check(int(session.get("energy")) == energy_before_failed_commit, "failed combat save rolls back attack energy")
	_check(int(session.expedition_run.get("guardian_states", {}).get("forest_slime", {}).get("health", -1)) == health_before_failed_commit, "failed combat save preserves the prior guardian state")
	# Fill the satchel before the decisive hit. The guardian must still resolve
	# its defeat, but its reward must become a physical, persisted recovery drop
	# rather than disappearing or being silently denied.
	guardian.set_physics_process(false)
	session.expedition_run["cargo"] = {"wood": int(session.get("cargo_capacity"))}
	for _strike in 5:
		world.call("_resolve_player_attack_hit")
		await physics_frame
		if not guardian.is_visible_in_tree():
			break
	_check(not guardian.is_visible_in_tree(), "live player attack query defeats the guardian")
	_check(bool(session.expedition_run.get("objective_complete", false)), "guardian defeat completes the clearing objective")
	_check(session.expedition_run.get("pickups", []).size() == 1, "full satchel creates a physical guardian recovery drop")
	_check(bool(session.call("save_game")), "full satchel guardian drop saves")
	world = await _reload_world("qa_whisperwood_full_loop")
	session = world.get("session")
	_check(session != null and bool(session.call("has_active_expedition")), "guardian recovery run reloads active")
	var persisted_guardian_drop: Node = null
	for candidate in world.get_tree().get_nodes_in_group("expedition_pickup"):
		if is_instance_valid(candidate) and str(candidate.get("pickup_id")).contains(":forest_slime:reward"):
			persisted_guardian_drop = candidate
			break
	_check(persisted_guardian_drop != null, "guardian recovery drop survives scene reload")
	if persisted_guardian_drop == null or session == null:
		return
	session.expedition_run["cargo"] = {"wood": int(session.get("cargo_capacity")) - 1}
	_check(await _walk_to(world, (persisted_guardian_drop as Node3D).global_position, 1.55), "movement reaches the recovered guardian reward")
	await _interact_and_settle(world, 30)
	_check(not is_instance_valid(persisted_guardian_drop), "recovered guardian reward is collected once space exists")
	_check(int(session.expedition_run.get("cargo", {}).get("slime_gel", 0)) == 1, "recovered guardian reward enters at-risk cargo")
	var reloaded_player := world.get("player") as CharacterBody3D
	reloaded_player.global_position = Vector3(0.0, 1.0, 7.5)
	world.call("_return_home")
	await process_frame
	_check(str(world.get("current_zone")) == "Sanctuary", "unfinished combat run can still extract safely")
	_check(int(session.get("inventory").get("slime_gel", 0)) == 1, "recovered guardian reward banks on extraction")

func _run() -> void:
	var slot := "qa_whisperwood_full_loop"
	_clear_slot(slot)
	ProjectSettings.set_setting("prodewty/save_slot", slot)
	var world := MainScene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var session: Node = world.get("session")
	_check(session != null, "full loop has a live session")
	if session == null:
		quit(1)
		return
	session.get("unlocked_routes").clear()
	session.get("unlocked_routes").append("Whisperwood")
	session.coins = 100
	await _run_grove_loop(world, session)
	world = await _reload_world(slot)
	session = world.get("session")
	_check(session != null, "reloaded full loop has a live session")
	if session != null:
		await _run_return_after_reload(world, session)
		await _run_clearing_combat(world, session)
	if is_instance_valid(world):
		world.queue_free()
	if failures.is_empty():
		print("WHISPERWOOD_FULL_LOOP_PASS checks=%d" % checks)
		quit(0)
	else:
		print("WHISPERWOOD_FULL_LOOP_FAIL failures=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  ", failure)
		quit(1)
