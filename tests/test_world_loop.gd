extends SceneTree

const MainScene = preload("res://main.tscn")

func _enter_route(world: Node, destination: String) -> void:
	var gate: Node = null
	for candidate in get_nodes_in_group("route_gate"):
		if str(candidate.get_meta("destination_id", "")) == destination:
			gate = candidate
			break
	assert(gate != null)
	world.call("_set_zone", "Sanctuary")
	assert(get_nodes_in_group("route_gate").size() == 5)
	world.player.global_position = gate.global_position + Vector3(0.0, 1.0, 0.0)
	world.call("_interact")
	assert(world.get("current_zone") == destination)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", "qa_world_loop")
	for save_path in ["user://qa_world_loop.json", "user://qa_world_loop.backup.json", "user://qa_world_loop.tmp.json"]:
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	var world := MainScene.instantiate()
	root.add_child(world)
	await process_frame
	var session: Node = world.get("session")
	session.expedition_run = {"status": "none", "run_id": "", "biome_id": "", "cargo": {}, "depleted_ids": [], "camp_used": false, "started_day": 0, "anchor": [0.0, 1.0, 7.5]}
	session.recovery_pack = {}
	session.energy = 24
	session.inventory["shell"] = 0
	session.set("sanctuary_depleted_ids", [])
	for candidate in get_nodes_in_group("resource_node"):
		if candidate.has_method("restore"):
			candidate.call("restore")
	world.call("_set_zone", "Sanctuary")
	var action_node: Node = null
	for candidate in get_nodes_in_group("resource_node"):
		if candidate.get_parent().name == "Sanctuary" and str(candidate.get("resource_id")) == "wood":
			action_node = candidate
			break
	assert(action_node != null)
	world.player.global_position = action_node.global_position
	var wood_before := int(session.inventory.get("wood", 0))
	for contact in 3:
		world.call("begin_resource_action", action_node)
		await create_timer(0.82).timeout
	assert(int(session.inventory.get("wood", 0)) == wood_before + 2)
	# A real Sanctuary placement has a preview/confirm path and creates a
	# persistent visual structure rather than only flipping a label.
	session.set("structures", {})
	session.inventory["wood"] = 8
	session.inventory["plank"] = 2
	world.player.global_position = Vector3(3.0, 1.0, 7.0)
	world.call("_toggle_structure_placement")
	world.call("_update_structure_preview")
	world.call("_place_structure")
	assert(session.get("structures").size() == 1)
	var placed_id := str(session.get("structures").keys()[0])
	var placed_visual: Node3D = world.get("settlement_visuals").get(placed_id)
	assert(placed_visual != null)
	assert(is_equal_approx(placed_visual.position.x, 3.5))
	assert(is_equal_approx(placed_visual.position.z, 4.5))
	assert(str(session.get("structures")[placed_id].get("state")) == "blueprint")
	world.player.global_position = placed_visual.global_position + Vector3(0.0, 1.0, 0.0)
	for delivery in 10:
		world.call("_interact")
	assert(str(session.get("structures")[placed_id].get("state")) == "building")
	assert(int(session.get("inventory").get("wood", -1)) == 0)
	assert(int(session.get("inventory").get("plank", -1)) == 0)
	_enter_route(world, "Sunlit Beach")
	assert(world.get("current_zone") == "Sunlit Beach")
	var shell_node: Node = null
	for candidate in get_nodes_in_group("resource_node"):
		if str(candidate.get("discovery_id")) == "Tideglass":
			shell_node = candidate
			break
	assert(shell_node != null)
	assert(world.call("collect_resource", shell_node))
	assert(int(session.get("expedition_run").get("cargo").get("shell", 0)) == 1)
	assert(int(session.get("inventory").get("shell", 0)) == 0)
	world.call("_return_home")
	assert(world.get("current_zone") == "Sanctuary")
	assert(int(session.get("inventory").get("shell", 0)) == 1)
	session.energy = 24
	_enter_route(world, "Whisperwood")
	var tree_node: Node = null
	for candidate in get_nodes_in_group("resource_node"):
		var tree_body := candidate.get_node_or_null("TreeCollision")
		if candidate.get_parent().name == "Whisperwood" and str(candidate.get("resource_id")) == "wood" and tree_body != null and tree_body.get_child_count() > 0:
			tree_node = candidate
			break
	assert(tree_node != null)
	assert(not bool(tree_node.get_node("TreeCollision").get_child(0).disabled))
	assert(tree_node.get_node_or_null("Sourced_Pine_1") != null)
	assert(world.get_node_or_null("Whisperwood/WhisperwoodRoute") != null)
	assert(world.get_node_or_null("Whisperwood/WhisperwoodRoute/Sourced_Fern_1") != null)
	assert(world.get_node_or_null("Whisperwood/WhisperwoodRoute/Sourced_RockPath_Round_Small_1") != null)
	world.player.global_position = tree_node.global_position
	var forest_wood_before := int(session.get("expedition_run").get("cargo", {}).get("wood", 0))
	assert(world.call("collect_resource", tree_node))
	assert(int(session.get("expedition_run").get("cargo", {}).get("wood", 0)) == forest_wood_before)
	assert(int(session.get("expedition_run").get("contact_progress", {}).get(str(tree_node.get("node_id")), 0)) == 1)
	assert(world.call("collect_resource", tree_node))
	assert(int(session.get("expedition_run").get("cargo", {}).get("wood", 0)) == forest_wood_before + 2)
	var forest_guardian: Node = null
	for candidate in get_nodes_in_group("guardian"):
		if candidate.get_parent().name == "Whisperwood":
			forest_guardian = candidate
			break
	assert(forest_guardian != null)
	world.player.set("last_direction", Vector3(0.0, 0.0, -1.0))
	world.player.global_position = forest_guardian.global_position + Vector3(0.0, 0.0, 2.5)
	var dodge_energy := int(session.get("energy"))
	var dodge_health := int(world.player.get("health"))
	world.call("_player_dodge")
	assert(int(session.get("energy")) == dodge_energy - 1)
	assert(float(world.player.get("invulnerable_time")) > 0.0)
	forest_guardian.call("set", "attack_cooldown", 0.0)
	world.call("guardian_attack", forest_guardian)
	assert(int(world.player.get("health")) == dodge_health)
	forest_guardian.call("take_damage", 999)
	assert(int(session.get("expedition_run").get("cargo").get("slime_gel", 0)) == 1)
	assert(int(session.get("inventory").get("slime_gel", 0)) == 0)
	world.player.global_position = Vector3(0.0, 1.0, 7.5)
	world.call("_return_home")
	session.energy = 24
	_enter_route(world, "Glass Desert")
	assert(world.get("current_zone") == "Glass Desert")
	assert(world.get_node_or_null("GlassDesert/Sourced_DeadTree_2") != null)
	world.call("_camp_interact")
	assert(bool(session.get("expedition_run").get("camp_used", false)))
	var camp_energy := int(session.get("energy"))
	world.call("_camp_interact")
	assert(int(session.get("energy")) == camp_energy)
	world.call("_return_home")
	assert(world.get("current_zone") == "Sanctuary")
	session.energy = 24
	_enter_route(world, "Sunken Dungeon")
	assert(world.get("current_zone") == "Sunken Dungeon")
	assert(world.get_node_or_null("SunkenDungeon/Sourced_DeadTree_3") != null)
	var relic_node: Node = null
	for candidate in get_nodes_in_group("resource_node"):
		if str(candidate.get("discovery_id")) == "Aether Relic":
			relic_node = candidate
			break
	assert(relic_node != null)
	assert(world.call("collect_resource", relic_node))
	world.call("_return_home")
	assert(int(session.get("inventory").get("relic", 0)) == 1)
	# Scene-level faint/recovery: the persisted pack, not the scene node's
	# mutable payload, is the source of truth and can be reclaimed only in its
	# original biome.
	session.energy = 24
	var banked_wood_before_faint := int(session.inventory.get("wood", 0))
	_enter_route(world, "Whisperwood")
	var recovery_tree: Node = null
	for candidate in get_nodes_in_group("resource_node"):
		if candidate.get_parent().name == "Whisperwood" and str(candidate.get("resource_id")) == "wood" and candidate.is_visible_in_tree():
			recovery_tree = candidate
			break
	assert(recovery_tree != null)
	world.player.global_position = recovery_tree.global_position
	assert(world.call("collect_resource", recovery_tree))
	assert(world.call("collect_resource", recovery_tree))
	assert(int(session.get("expedition_run").get("cargo", {}).get("wood", 0)) == 2)
	world.player.set("health", 1)
	world.call("player_fainted")
	assert(world.get("current_zone") == "Sanctuary")
	assert(not session.get("recovery_pack").is_empty())
	var recovery_pack_node: Node = null
	for candidate in get_nodes_in_group("recovery_pack"):
		if candidate.get_parent().name == "Whisperwood":
			recovery_pack_node = candidate
			break
	assert(recovery_pack_node != null)
	session.energy = 24
	_enter_route(world, "Whisperwood")
	world.player.global_position = recovery_pack_node.global_position
	recovery_pack_node.call("interact", world.player)
	assert(session.get("recovery_pack").is_empty())
	assert(int(session.get("expedition_run").get("cargo", {}).get("wood", 0)) == 1)
	world.player.global_position = Vector3(0.0, 1.0, 7.5)
	world.call("_return_home")
	assert(int(session.get("inventory").get("wood", 0)) == banked_wood_before_faint + 2)
	# The Sanctuary has living loops beyond gathering: fish, then trade the
	# catch at the Bazaar for a meaningful return on expedition supplies.
	session.energy = 24
	session.inventory["fiber"] = 1
	session.inventory["fish"] = 0
	session.inventory["water"] = 3
	session.coins = 0
	world.player.global_position = world.fishing_spot.global_position
	world.call("_fishing_interact")
	assert(int(session.inventory.get("fish", 0)) >= 1)
	session.inventory["fish"] = 2
	session.inventory["water"] = 1
	world.player.global_position = world.trade_stall.global_position
	world.call("_bazaar_interact")
	assert(int(session.get("coins")) == 28)
	# An active expedition stores its last world position, not just its biome.
	session.energy = 24
	_enter_route(world, "Whisperwood")
	world.player.global_position = Vector3(4.0, 1.0, -3.0)
	world.call("_sync_expedition_anchor")
	var anchor: Array = session.get("expedition_run").get("anchor")
	assert(is_equal_approx(float(anchor[0]), 4.0))
	assert(is_equal_approx(float(anchor[2]), -3.0))
	assert(session.call("save_game"))
	var resumed := MainScene.instantiate()
	root.add_child(resumed)
	await process_frame
	assert(resumed.get("current_zone") == "Whisperwood")
	assert(is_equal_approx(float(resumed.player.global_position.x), 4.0))
	assert(is_equal_approx(float(resumed.player.global_position.z), -3.0))
	resumed.queue_free()
	await process_frame
	world.call("_return_home")
	assert(world.get("current_zone") == "Whisperwood")
	world.player.global_position = Vector3(0.0, 1.0, 7.5)
	world.call("_return_home")
	print("WORLD_LOOP_TESTS_PASS")
	quit()
