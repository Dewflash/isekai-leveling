extends SceneTree

## End-to-end expedition coverage. This deliberately exercises the five real
## route gates, both branch types, a resource/pickup path, and a guardian
## resolution path so a map cannot be considered implemented merely because
## its scene loads.

const MainScene = preload("res://main.tscn")

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _find_gate(destination: String) -> Node:
	for candidate in get_nodes_in_group("route_gate"):
		if str(candidate.get_meta("destination_id", "")) == destination:
			return candidate
	return null

func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	failures += 1
	push_error("EXPEDITION_LOOP_FAIL: %s" % message)
	return false

func _enter_route(world: Node, destination: String) -> bool:
	var gate := _find_gate(destination)
	if not _expect(gate != null, "route gate missing: %s" % destination):
		return false
	world.call("_set_zone", "Sanctuary")
	world.player.global_position = gate.global_position + Vector3(0.0, 1.0, 0.0)
	world.call("_route_gate_interact", gate)
	await process_frame
	var runtime_session: Node = world.get("session")
	var run_summary := str(runtime_session.get("expedition_run")) if runtime_session != null else "<missing session>"
	return _expect(world.get("current_zone") == destination, "failed to enter route: %s current=%s selected=%s run=%s" % [destination, str(world.get("current_zone")), str(world.get("selected_expedition")), run_summary])

func _return_home(world: Node, session: Node) -> bool:
	world.player.global_position = Vector3(0.0, 1.0, 7.5)
	world.call("_return_home")
	await process_frame
	if not _expect(world.get("current_zone") == "Sanctuary", "failed to return home"):
		return false
	return _expect(not bool(session.call("has_active_expedition")), "expedition remained active after extraction")

func _choose_branch(world: Node, branch_index: int) -> bool:
	var zone_node_name := str(world.get("current_zone")).replace(" ", "")
	var route_node_name := "WhisperwoodRoute" if zone_node_name == "Whisperwood" else "ExpeditionRoute"
	var marker_name := "WhisperwoodBranchChoice" if zone_node_name == "Whisperwood" else "RouteChoiceMarker"
	var marker := world.get_node_or_null("%s/%s/%s" % [zone_node_name, route_node_name, marker_name]) as Node3D
	if not _expect(marker != null, "branch marker missing: %s" % zone_node_name):
		return false
	world.player.global_position = marker.global_position + Vector3(-0.8 if branch_index == 0 else 0.8, 1.0, 0.0)
	world.call("_interact")
	await process_frame
	var session: Node = world.get("session")
	return _expect(not str(session.get("expedition_run").get("branch_id", "")).is_empty(), "branch was not committed: %s" % zone_node_name)

func _find_resource(zone_node_name: String, resource_id: String) -> Node:
	for candidate in get_nodes_in_group("resource_node"):
		var parent := candidate.get_parent()
		if parent != null and parent.name == zone_node_name and str(candidate.get("resource_id")) == resource_id and candidate.is_visible_in_tree():
			return candidate
	return null

func _collect_one(world: Node, zone_node_name: String, resource_id: String, contacts: int = 1) -> bool:
	var resource := _find_resource(zone_node_name, resource_id)
	if not _expect(resource != null, "resource missing: %s/%s" % [zone_node_name, resource_id]):
		return false
	for contact in contacts:
		world.player.global_position = resource.global_position
		if not _expect(bool(world.call("collect_resource", resource)), "resource contact failed: %s/%s #%d" % [zone_node_name, resource_id, contact + 1]):
			return false
		await process_frame
	var residue := resource.get_node_or_null("DepletedVisual") as Node3D
	if residue != null and not _expect(residue.visible, "depleted resource residue hidden: %s/%s" % [zone_node_name, resource_id]):
		return false
	var pickup: Node = null
	for candidate in get_nodes_in_group("expedition_pickup"):
		var parent := candidate.get_parent()
		if parent != null and parent.name == zone_node_name:
			pickup = candidate
			break
	if not _expect(pickup != null, "pickup missing after resource completion: %s/%s" % [zone_node_name, resource_id]):
		return false
	world.player.global_position = pickup.global_position
	world.call("_interact")
	await process_frame
	return _expect(not is_instance_valid(pickup), "pickup was not collected: %s/%s" % [zone_node_name, resource_id])

func _defeat_guardian(world: Node, zone_node_name: String) -> bool:
	var guardian: Node = null
	for candidate in get_nodes_in_group("guardian"):
		var parent := candidate.get_parent()
		if parent != null and parent.name == zone_node_name and candidate.is_visible_in_tree():
			guardian = candidate
			break
	if not _expect(guardian != null, "guardian missing: %s" % zone_node_name):
		return false
	var session: Node = world.get("session")
	var reward_id := str(guardian.get("reward_id"))
	var before := int(session.get("expedition_run").get("cargo", {}).get(reward_id, 0))
	guardian.call("take_damage", 999)
	return _expect(int(session.get("expedition_run").get("cargo", {}).get(reward_id, 0)) == before + int(guardian.get("reward_amount")), "guardian reward missing: %s" % zone_node_name)

func _finish() -> void:
	if failures > 0:
		print("EXPEDITION_LOOP_TESTS_FAIL count=%d" % failures)
		quit(1)
		return
	print("EXPEDITION_LOOP_TESTS_PASS destinations=5 resources=5 guardians=5")
	quit(0)

func _run() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", "qa_expedition_loops")
	for save_path in ["user://qa_expedition_loops.json", "user://qa_expedition_loops.backup.json", "user://qa_expedition_loops.tmp.json"]:
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	var world := MainScene.instantiate()
	root.add_child(world)
	await process_frame
	var session: Node = world.get("session")
	if not _expect(session != null, "session missing from main scene"):
		_finish()
		return
	session.get("unlocked_routes").clear()
	for destination in ["Whisperwood", "Sunlit Beach", "Ember Ridge", "Glass Desert", "Sunken Dungeon"]:
		session.get("unlocked_routes").append(destination)
	session.coins = 300
	session.energy = 24

	if not await _enter_route(world, "Whisperwood"):
		_finish()
		return
	if not await _choose_branch(world, 0):
		_finish()
		return
	if not await _collect_one(world, "Whisperwood", "wood", 2):
		_finish()
		return
	if not await _return_home(world, session):
		_finish()
		return

	session.energy = 24
	if not await _enter_route(world, "Sunlit Beach"):
		_finish()
		return
	if not await _choose_branch(world, 0):
		_finish()
		return
	if not await _collect_one(world, "SunlitBeach", "shell"):
		_finish()
		return
	if not await _return_home(world, session):
		_finish()
		return

	session.energy = 24
	if not await _enter_route(world, "Ember Ridge"):
		_finish()
		return
	if not await _choose_branch(world, 0):
		_finish()
		return
	if not await _collect_one(world, "EmberRidge", "ore"):
		_finish()
		return
	if not await _return_home(world, session):
		_finish()
		return

	session.energy = 24
	if not await _enter_route(world, "Glass Desert"):
		_finish()
		return
	if not await _choose_branch(world, 0):
		_finish()
		return
	if not await _collect_one(world, "GlassDesert", "fiber"):
		_finish()
		return
	if not await _return_home(world, session):
		_finish()
		return

	session.energy = 24
	if not await _enter_route(world, "Sunken Dungeon"):
		_finish()
		return
	if not await _choose_branch(world, 0):
		_finish()
		return
	if not await _collect_one(world, "SunkenDungeon", "relic"):
		_finish()
		return
	if not await _return_home(world, session):
		_finish()
		return

	# The second branch of every route is the guardian branch. Resolve each
	# guardian in a fresh run and verify its reward stays at-risk until extraction.
	for destination in ["Whisperwood", "Sunlit Beach", "Ember Ridge", "Glass Desert", "Sunken Dungeon"]:
		session.energy = 24
		if not await _enter_route(world, destination):
			_finish()
			return
		if not await _choose_branch(world, 1):
			_finish()
			return
		if not await _defeat_guardian(world, str(destination).replace(" ", "")):
			_finish()
			return
		if not _expect(bool(session.call("has_active_expedition")), "guardian reward was not held as expedition cargo: %s" % destination):
			_finish()
			return
		if not await _return_home(world, session):
			_finish()
			return

	_finish()
