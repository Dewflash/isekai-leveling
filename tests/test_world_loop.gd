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
	world.player.global_position = Vector3(0.0, 1.0, 0.0)
	world.call("_route_gate_interact", gate)
	assert(world.get("current_zone") == "Sanctuary")
	world.player.global_position = gate.global_position + Vector3(0.0, 1.0, 0.0)
	world.call("_interact")
	assert(world.get("current_zone") == destination)

func _assert_player_structure_visuals(world: Node, session: Node) -> void:
	var workshop_id := "qa_visual_workshop"
	var storage_id := "qa_visual_storage"
	var workshop_data := {"id": workshop_id, "kind": "workshop", "cell": [20, 20], "state": "operational", "remaining_hours": 0.0, "delivered_materials": {}}
	var storage_data := {"id": storage_id, "kind": "storage_shed", "cell": [24, 20], "state": "operational", "remaining_hours": 0.0, "delivered_materials": {}}
	world.call("_spawn_structure_visual", workshop_id, workshop_data)
	world.call("_spawn_structure_visual", storage_id, storage_data)
	var visuals: Dictionary = world.get("settlement_visuals")
	var workshop_visual := visuals.get(workshop_id) as Node3D
	var storage_visual := visuals.get(storage_id) as Node3D
	assert(workshop_visual != null and storage_visual != null)
	assert(workshop_visual.get_node_or_null("StructureUtility/WorkshopForge/WorkshopChimney") != null)
	assert(workshop_visual.get_node_or_null("StructureUtility/WorkshopHammerPivot") != null)
	assert(storage_visual.get_node_or_null("StructureUtility/StorageCargo/LargeCrate") != null)
	var pulley := storage_visual.get_node_or_null("StructureUtility/StorageLoadingFrame/StoragePulleyWheel") as MeshInstance3D
	assert(pulley != null)
	var workshop_roof := workshop_visual.get_node("CisternRoof") as MeshInstance3D
	var storage_roof := storage_visual.get_node("CisternRoof") as MeshInstance3D
	var workshop_roof_material := workshop_roof.material_override as StandardMaterial3D
	var storage_roof_material := storage_roof.material_override as StandardMaterial3D
	assert(workshop_roof_material.albedo_color != storage_roof_material.albedo_color)
	assert((workshop_visual.get_node("GabledRoof") as Node3D).visible)
	assert((workshop_visual.get_node("TimberFrame") as Node3D).visible)
	var storage_label := storage_visual.get_node("StructureLabel") as Label3D
	assert(storage_label.text.contains("SATCHEL +4"))
	var pulley_rotation := pulley.rotation.z
	world.call("_update_player_structure_motion", 0.25)
	assert(not is_equal_approx(pulley.rotation.z, pulley_rotation))

	var original_job: Dictionary = session.get("station_job").duplicate(true)
	session.set("station_job", {"kind": "plank", "remaining_hours": 12.0, "total_hours": 12.0, "output_id": "plank", "output": 2})
	world.call("_refresh_structure_visual", workshop_id, workshop_data)
	world.call("_update_player_structure_motion", 0.25)
	var smoke := workshop_visual.get_node("StructureUtility/WorkshopSmoke") as Node3D
	var workshop_label := workshop_visual.get_node("StructureLabel") as Label3D
	assert(smoke.visible)
	assert(workshop_label.text.contains("WORKING 12h"))
	session.set("station_job", {"kind": "plank", "remaining_hours": 0.0, "total_hours": 12.0, "output_id": "plank", "output": 2})
	world.call("_refresh_structure_visual", workshop_id, workshop_data)
	world.call("_update_player_structure_motion", 0.0)
	assert(not smoke.visible)
	assert(workshop_label.text.contains("ORDER READY"))
	session.set("station_job", original_job)
	for visual_id in [workshop_id, storage_id]:
		var visual := visuals.get(visual_id) as Node3D
		if visual != null:
			visual.queue_free()
		visuals.erase(visual_id)

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
	session.get("unlocked_routes").clear()
	for route_id in ["Whisperwood", "Sunlit Beach", "Ember Ridge", "Glass Desert", "Sunken Dungeon"]:
		session.get("unlocked_routes").append(route_id)
	session.get("blueprints").append("Tideglass Compass")
	world.call("_copy_session_to_runtime")
	_assert_player_structure_visuals(world, session)
	assert(world.get_node_or_null("Sanctuary/CloverLivestockPen/SourcedPaddockCow") != null)
	for route_zone in ["SunlitBeach", "EmberRidge", "GlassDesert", "SunkenDungeon"]:
		assert(world.get_node_or_null(route_zone + "/MapIdentity") != null)
		var authored_route := world.get_node_or_null(route_zone + "/ExpeditionRoute") as Node3D
		assert(authored_route != null)
		assert(authored_route.get_node_or_null("RoutePressure") != null)
		assert(authored_route.get_node_or_null("RoutePressure/PressureBlocker/PressureCollision") != null)
		assert(authored_route.get_node_or_null("RouteChoiceMarker") != null)
		assert(authored_route.get_node_or_null("RouteBarrier_Tidepool") != null or authored_route.get_node_or_null("RouteBarrier_Quarry") != null or authored_route.get_node_or_null("RouteBarrier_Oasis") != null or authored_route.get_node_or_null("RouteBarrier_Vault") != null)
	assert(world.get_node_or_null("Player/Visual/LegLeft") != null)
	assert(world.get_node_or_null("Player/Visual/ArmRight") != null)
	world.player.call("play_gather_feedback")
	var gather_arm := world.get_node("Player/Visual/ArmLeft") as Node3D
	var gather_pose := gather_arm.rotation.x
	await physics_frame
	await physics_frame
	assert(is_equal_approx(gather_arm.rotation.x, gather_pose))
	world.player.call("cancel_gather_feedback")
	var paddock_cow := world.get_node_or_null("Sanctuary/CloverLivestockPen/SourcedPaddockCow")
	var paddock_animation := paddock_cow.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert(is_equal_approx(float(paddock_cow.scale.x), 0.27))
	assert(paddock_animation != null and (paddock_animation.is_playing() or paddock_animation.current_animation == "Armature|Walk"))
	var paused_day := int(session.get("day"))
	session.inventory["bread"] = 1
	session.inventory["water"] = 1
	session.nutrition = 20
	session.hydration = 20
	var paused_bread := int(session.inventory["bread"])
	var paused_water := int(session.inventory["water"])
	var paused_xp := int(session.get("xp"))
	var paused_strength := int(session.get("stats")["Strength"])
	world.call("_toggle_pause")
	world.call("_eat_best_food")
	world.call("_drink_water")
	world.call("_record_activity")
	world.call("_allocate_best_stat")
	world.call("_toggle_furnace")
	assert(int(session.inventory["bread"]) == paused_bread)
	assert(int(session.inventory["water"]) == paused_water)
	assert(int(session.get("xp")) == paused_xp)
	assert(int(session.get("stats")["Strength"]) == paused_strength)
	assert(not world.get("furnace_active"))
	world.call("_toggle_pause")
	world.call("_toggle_pause")
	world.call("_sleep")
	world.call("_contextual_interact")
	assert(int(session.get("day")) == paused_day)
	world.call("_toggle_pause")
	world.player.global_position = world.furnace.global_position
	var save_failure_day := int(session.get("day"))
	session.save_blocked = true
	world.call("_sleep")
	assert(int(session.get("day")) == save_failure_day)
	session.save_blocked = false
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
	world.call("_contextual_interact")
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
	var beach_marker := world.get_node_or_null("SunlitBeach/ExpeditionRoute/RouteChoiceMarker")
	assert(beach_marker != null)
	world.player.global_position = beach_marker.global_position + Vector3(-0.8, 1.0, 0.0)
	world.call("_interact")
	assert(session.get("expedition_run").get("branch_id") == "tidepool")
	world.player.global_position = shell_node.global_position
	assert(world.call("collect_resource", shell_node))
	assert(int(session.get("expedition_run").get("cargo").get("shell", 0)) == 1)
	assert(int(session.get("inventory").get("shell", 0)) == 0)
	world.player.global_position = Vector3(0.0, 1.0, 7.5)
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
	var branch_marker := world.get_node_or_null("Whisperwood/WhisperwoodRoute/WhisperwoodBranchChoice")
	assert(branch_marker != null)
	var grove_barrier := world.get_node_or_null("Whisperwood/WhisperwoodRoute/WhisperwoodBarrier_Grove") as StaticBody3D
	var clearing_barrier := world.get_node_or_null("Whisperwood/WhisperwoodRoute/WhisperwoodBarrier_Clearing") as StaticBody3D
	assert(grove_barrier != null and clearing_barrier != null)
	assert(not grove_barrier.visible and not clearing_barrier.visible)
	world.player.global_position = branch_marker.global_position + Vector3(0.8, 1.0, 0.0)
	world.call("_interact")
	assert(session.get("expedition_run").get("branch_id") == "clearing")
	assert(grove_barrier.visible)
	assert(not clearing_barrier.visible)
	assert(not (grove_barrier.get_node("BarrierCollision") as CollisionShape3D).disabled)
	world.player.global_position = tree_node.global_position
	var forest_wood_before := int(session.get("expedition_run").get("cargo", {}).get("wood", 0))
	assert(world.call("collect_resource", tree_node))
	assert(int(session.get("expedition_run").get("cargo", {}).get("wood", 0)) == forest_wood_before)
	assert(int(session.get("expedition_run").get("contact_progress", {}).get(str(tree_node.get("node_id")), 0)) == 1)
	assert(world.call("collect_resource", tree_node))
	assert(int(session.get("expedition_run").get("cargo", {}).get("wood", 0)) == forest_wood_before + 2)
	assert(tree_node.get_node_or_null("FelledLogVisual") != null)
	assert((tree_node.get_node("FelledLogVisual") as Node3D).visible)
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
	session.get("expedition_run")["cargo"] = {"wood": int(session.get("cargo_capacity"))}
	forest_guardian.call("take_damage", 999)
	assert(bool(forest_guardian.visible))
	assert(int(forest_guardian.get("health")) == 1)
	session.get("expedition_run")["cargo"] = {}
	session.save_blocked = true
	forest_guardian.call("take_damage", 999)
	assert(bool(forest_guardian.visible))
	assert(int(forest_guardian.get("health")) == 1)
	session.save_blocked = false
	forest_guardian.call("take_damage", 999)
	assert(int(session.get("expedition_run").get("cargo").get("slime_gel", 0)) == 1)
	assert(int(session.get("inventory").get("slime_gel", 0)) == 0)
	world.player.global_position = Vector3(0.0, 1.0, 7.5)
	world.call("_return_home")
	assert(world.get("current_zone") == "Sanctuary")
	# Objective landmarks stay protected until the player commits to their
	# branch; otherwise a pre-fork harvest could permanently soft-lock a run.
	session.energy = 24
	_enter_route(world, "Sunlit Beach")
	var tidepool_shell: Node = null
	for candidate in get_nodes_in_group("resource_node"):
		if candidate.get_parent().name == "SunlitBeach" and str(candidate.get_meta("route_branch", "")) == "tidepool":
			tidepool_shell = candidate
			break
	assert(tidepool_shell != null)
	world.player.global_position = tidepool_shell.global_position
	assert(not world.call("collect_resource", tidepool_shell))
	assert(not world.call("is_resource_depleted", tidepool_shell))
	world.player.global_position = Vector3(0.0, 1.0, 7.5)
	world.call("_return_home")
	assert(world.get("current_zone") == "Sanctuary")
	session.energy = 24
	_enter_route(world, "Ember Ridge")
	assert(world.get("current_zone") == "Ember Ridge")
	world.player.global_position = Vector3(0.0, 1.0, 7.5)
	world.call("_return_home")
	assert(world.get("current_zone") == "Sanctuary")
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
	var dungeon_marker := world.get_node_or_null("SunkenDungeon/ExpeditionRoute/RouteChoiceMarker")
	assert(dungeon_marker != null)
	world.player.global_position = dungeon_marker.global_position + Vector3(-0.8, 1.0, 0.0)
	world.call("_interact")
	assert(session.get("expedition_run").get("branch_id") == "vault")
	assert(world.call("collect_resource", relic_node))
	world.player.global_position = Vector3(0.0, 1.0, 7.5)
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
	# A failed persistence transaction must restore the pre-damage active run,
	# including positive health, instead of leaving a zero-health soft lock.
	session.health = 1
	world.player.set("health", 1)
	var pre_failed_faint_run: Dictionary = session.get("expedition_run").duplicate(true)
	session.save_blocked = true
	world.call("player_took_damage", 9)
	assert(world.get("current_zone") == "Whisperwood")
	assert(bool(session.call("has_active_expedition")))
	assert(int(session.get("health")) == 1)
	assert(int(session.get("expedition_run").get("cargo", {}).get("wood", 0)) == int(pre_failed_faint_run.get("cargo", {}).get("wood", 0)))
	session.save_blocked = false
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
