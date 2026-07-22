extends SceneTree

const MainScene = preload("res://main.tscn")

var failures := 0

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("GUARDIAN_BEHAVIOR_FAIL " + message)

func _distance_to_player(world: Node, guardian: Node3D) -> float:
	var player := world.get("player") as Node3D
	if player == null:
		return INF
	return Vector2(player.global_position.x - guardian.global_position.x, player.global_position.z - guardian.global_position.z).length()

func _reach_endpoint(session: Node, branch_id: String) -> void:
	session.call("record_route_checkpoint", "arrival")
	session.call("record_route_checkpoint", "fork")
	session.call("commit_expedition_branch", branch_id)
	session.call("record_expedition_endpoint", branch_id)

func _run() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", "qa_guardian_behaviors")
	for save_path in ["user://qa_guardian_behaviors.json", "user://qa_guardian_behaviors.backup.json", "user://qa_guardian_behaviors.tmp.json"]:
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	var world := MainScene.instantiate()
	root.add_child(world)
	await process_frame
	var session: Node = world.get("session")
	if session != null:
		session.get("unlocked_routes").clear()
		for route_id in ["Whisperwood", "Sunlit Beach", "Ember Ridge", "Glass Desert", "Sunken Dungeon"]:
			session.get("unlocked_routes").append(route_id)
		session.energy = 24
		session.coins = 300
	# The movement checks intentionally exercise the active route. Keeping the
	# Sanctuary framing layer active would make a forest guardian collide with
	# an unrelated map's measured tree footprint at the same world coordinates.
	if session != null:
		session.expedition_run = {"status": "none"}
		session.call("start_expedition", "Whisperwood")
		_reach_endpoint(session, "clearing")
	world.call("_set_zone", "Whisperwood")
	await physics_frame
	var player := world.get("player") as Node3D
	var expected := {
		"forest_slime": {"zone": "Whisperwood", "behavior": "chaser"},
		"tide_wraith": {"zone": "SunlitBeach", "behavior": "skirmisher"},
		"ember_golem": {"zone": "EmberRidge", "behavior": "bruiser"},
		"dune_wisp": {"zone": "GlassDesert", "behavior": "skirmisher"},
		"crypt_knight": {"zone": "SunkenDungeon", "behavior": "sentinel"},
	}
	var guardians := {}
	for candidate in get_nodes_in_group("guardian"):
		var guardian := candidate as Node3D
		if guardian == null:
			continue
		var guardian_id := str(guardian.get("guardian_id"))
		guardians[guardian_id] = guardian
		var definition: Dictionary = expected.get(guardian_id, {})
		_expect(not definition.is_empty(), "%s must have a behavior contract" % guardian_id)
		if definition.is_empty():
			continue
		_expect(guardian.get_parent().name == str(definition.get("zone", "")), "%s must live in its authored zone" % guardian_id)
		_expect(str(guardian.get("behavior_id")) == str(definition.get("behavior", "")), "%s must preserve its authored behavior id" % guardian_id)
		guardian.call("set_active", true)

	var chaser := guardians.get("forest_slime") as Node3D
	if chaser != null and player != null:
		chaser.call("restore")
		player.global_position = chaser.global_position + Vector3(0.0, 1.0, 5.0)
		chaser.call("hear_noise", player.global_position, 20.0)
		var chaser_before := _distance_to_player(world, chaser)
		for _step in 360:
			await physics_frame
		_expect(str(chaser.get("behavior_state")) in ["chase", "retreat", "spacing"], "chaser enters pursuit after reaching the heard alert")
		_expect(_distance_to_player(world, chaser) < chaser_before, "chaser closes distance during pursuit")

	var bruiser := guardians.get("ember_golem") as Node3D
	if bruiser != null and player != null:
		if session != null:
			session.expedition_run = {"status": "none"}
			session.energy = 24
			session.call("start_expedition", "Ember Ridge")
			_reach_endpoint(session, "quarry")
		world.call("_set_zone", "Ember Ridge")
		await physics_frame
		bruiser.call("set_active", true)
		bruiser.call("restore")
		player.global_position = bruiser.global_position + Vector3(0.0, 1.0, 5.0)
		bruiser.call("hear_noise", player.global_position, 20.0)
		var bruiser_before := _distance_to_player(world, bruiser)
		for _step in 360:
			await physics_frame
		_expect(str(bruiser.get("behavior_state")) in ["chase", "retreat", "spacing"], "bruiser enters pursuit after reaching the heard alert")
		_expect(_distance_to_player(world, bruiser) < bruiser_before, "bruiser closes distance while preserving its slower profile")

	var skirmisher := guardians.get("tide_wraith") as Node3D
	if skirmisher != null and player != null:
		if session != null:
			session.expedition_run = {"status": "none"}
			session.energy = 24
			session.call("start_expedition", "Sunlit Beach")
			_reach_endpoint(session, "tidepool")
		world.call("_set_zone", "Sunlit Beach")
		await physics_frame
		skirmisher.call("set_active", true)
		skirmisher.call("restore")
		player.global_position = skirmisher.global_position + Vector3(0.0, 1.0, 2.0)
		skirmisher.call("hear_noise", player.global_position, 20.0)
		skirmisher.set("attack_windup", 0.01)
		skirmisher.set("attack_recovery", 0.0)
		skirmisher.set("guarding", true)
		skirmisher.call("_physics_process", 0.02)
		# The active attack frame starts its recovery; release it here so the
		# behavior-specific retreat can be observed without waiting on a timer.
		skirmisher.set("attack_recovery", 0.0)
		var retreat_before := _distance_to_player(world, skirmisher)
		skirmisher.call("_physics_process", 0.10)
		_expect(str(skirmisher.get("behavior_state")) == "retreat", "skirmisher retreats after its committed strike")
		_expect(_distance_to_player(world, skirmisher) > retreat_before, "skirmisher creates space after attacking")

	var sentinel := guardians.get("crypt_knight") as Node3D
	if sentinel != null and player != null:
		if session != null:
			session.expedition_run = {"status": "none"}
			session.energy = 24
			session.call("start_expedition", "Sunken Dungeon")
			_reach_endpoint(session, "vault")
		world.call("_set_zone", "Sunken Dungeon")
		await physics_frame
		sentinel.call("set_active", true)
		sentinel.call("restore")
		player.global_position = sentinel.global_position + Vector3(0.0, 1.0, 4.0)
		var sentinel_before := sentinel.global_position
		sentinel.call("_physics_process", 0.20)
		_expect(str(sentinel.get("behavior_state")) == "idle", "sentinel stays dormant without an alert")
		_expect(sentinel.global_position.distance_to(sentinel_before) < 0.001, "sentinel does not pursue an unalerted player")

	world.queue_free()
	if failures > 0:
		print("GUARDIAN_BEHAVIOR_TESTS_FAIL count=%d" % failures)
		quit(1)
		return
	print("GUARDIAN_BEHAVIOR_TESTS_PASS guardians=%d" % guardians.size())
	quit(0)

func _init() -> void:
	call_deferred("_run")
