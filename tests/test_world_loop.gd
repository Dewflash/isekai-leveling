extends SceneTree

const MainScene = preload("res://main.tscn")
const AssetMeasurement = preload("res://scripts/sanctuary_asset_measurement.gd")

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
	var storage_data := {"id": storage_id, "kind": "storage_shed", "cell": [24, 20], "rotation": 1, "state": "operational", "remaining_hours": 0.0, "delivered_materials": {}}
	world.call("_spawn_structure_visual", workshop_id, workshop_data)
	world.call("_spawn_structure_visual", storage_id, storage_data)
	var visuals: Dictionary = world.get("settlement_visuals")
	var workshop_visual := visuals.get(workshop_id) as Node3D
	var storage_visual := visuals.get(storage_id) as Node3D
	assert(workshop_visual != null and storage_visual != null)
	assert(is_equal_approx(storage_visual.rotation.y, PI * 0.5))
	var storage_base := storage_visual.get_node("CisternBase") as MeshInstance3D
	assert(storage_base != null)
	var storage_base_mesh := storage_base.mesh as BoxMesh
	# The visual root carries the 90° turn; local authored geometry and its
	# collision shape remain in canonical orientation so world extents rotate
	# together instead of double-swapping.
	var storage_measurement := AssetMeasurement.structure_measurement("storage_shed", Vector2i(5, 4))
	var storage_collision_size: Vector3 = storage_measurement.get("fitted_size", Vector3.ZERO)
	assert(storage_base_mesh != null and is_equal_approx(storage_base_mesh.size.x, storage_collision_size.x) and is_equal_approx(storage_base_mesh.size.z, storage_collision_size.z))
	var storage_collision_body := storage_visual.get_node("StructureCollisionBody") as StaticBody3D
	var storage_collision_shapes := storage_collision_body.find_children("Compound_*", "CollisionShape3D", false, false)
	assert(storage_collision_body != null and storage_collision_shapes.size() >= 5)
	assert(int(storage_visual.get_meta("compound_collision_component_count", 0)) == storage_collision_shapes.size())
	assert(workshop_visual.get_node_or_null("StructureUtility/WorkshopForge/WorkshopChimney") != null)
	assert(workshop_visual.get_node_or_null("StructureUtility/WorkshopHammerPivot") != null)
	assert(storage_visual.get_node_or_null("StructureUtility/StorageCargo/LargeCrate") != null)
	assert(workshop_visual.get_node_or_null("FinishedSourceBuilding/ImportedBuilding") != null)
	assert(storage_visual.get_node_or_null("FinishedSourceBuilding/ImportedBuilding") != null)
	# The measured source remains the physical/scale authority, while the richer
	# generated 2.5D asset is the player-facing operational silhouette.
	assert(not (workshop_visual.get_node("FinishedSourceBuilding") as Node3D).visible)
	assert(not (storage_visual.get_node("FinishedSourceBuilding") as Node3D).visible)
	assert(str(workshop_visual.get_meta("operational_art_source", "")) == "generated_player_structure_directional")
	assert(str(storage_visual.get_meta("operational_art_source", "")) == "generated_player_structure_directional")
	assert(not (workshop_visual.get_node("FinishedWalls") as Node3D).visible)
	var operational_art := workshop_visual.get_node_or_null("IllustratedStructurePresentation/IllustratedStateSprite") as Sprite3D
	assert(operational_art != null and operational_art.visible)
	assert(str(operational_art.get_meta("asset_id", "")).begins_with("sanctuary/player_structures/workshop/operational/"))
	assert(operational_art.get_meta("directional_asset_path", "") == "res://assets/generated/sanctuary/workshop/workshop-q0.png")
	var staged_id := "qa_construction_stages"
	var blueprint_data := {"id": staged_id, "kind": "storage_shed", "cell": [28, 20], "state": "blueprint", "remaining_hours": 24.0, "total_hours": 24.0, "delivered_materials": {}}
	world.call("_spawn_structure_visual", staged_id, blueprint_data)
	var staged_visual := visuals.get(staged_id) as Node3D
	assert(staged_visual != null)
	assert((staged_visual.get_node("BlueprintStakes") as Node3D).visible)
	assert(not (staged_visual.get_node("ScaffoldFrame") as Node3D).visible)
	var building_data := blueprint_data.duplicate(true)
	building_data["state"] = "building"
	building_data["remaining_hours"] = 14.0
	building_data["delivered_materials"] = {"wood": 6, "stone": 2}
	world.call("_spawn_structure_visual", staged_id, building_data)
	staged_visual = visuals.get(staged_id) as Node3D
	assert(staged_visual.get_node_or_null("IllustratedStructurePresentation/IllustratedStateSprite") != null)
	assert((staged_visual.get_node("DeliveredLogs") as Node3D).visible)
	assert(not (staged_visual.get_node("ConstructionWalls") as Node3D).visible)
	building_data["remaining_hours"] = 10.0
	world.call("_spawn_structure_visual", staged_id, building_data)
	staged_visual = visuals.get(staged_id) as Node3D
	assert(staged_visual.get_node_or_null("IllustratedStructurePresentation/IllustratedStateSprite") != null)
	assert(staged_visual.get_node_or_null("IllustratedStructurePresentation/IllustratedPartialWalls") == null)
	building_data["remaining_hours"] = 4.0
	world.call("_spawn_structure_visual", staged_id, building_data)
	staged_visual = visuals.get(staged_id) as Node3D
	assert(staged_visual.get_node_or_null("IllustratedStructurePresentation/IllustratedStateSprite") != null)
	assert(staged_visual.get_node_or_null("IllustratedStructurePresentation/IllustratedPartialRoof") == null)
	var pulley := storage_visual.get_node_or_null("StructureUtility/StorageLoadingFrame/StoragePulleyWheel") as MeshInstance3D
	assert(pulley != null)
	var workshop_roof := workshop_visual.get_node("CisternRoof") as MeshInstance3D
	var storage_roof := storage_visual.get_node("CisternRoof") as MeshInstance3D
	var workshop_roof_material := workshop_roof.material_override as StandardMaterial3D
	var storage_roof_material := storage_roof.material_override as StandardMaterial3D
	assert(workshop_roof_material.albedo_color != storage_roof_material.albedo_color)
	assert(not (workshop_visual.get_node("GabledRoof") as Node3D).visible)
	assert(not (workshop_visual.get_node("TimberFrame") as Node3D).visible)
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
	for visual_id in [workshop_id, storage_id, staged_id]:
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
	var settings_panel := world.get("settings_panel") as Panel
	assert(settings_panel != null)
	world.call("_toggle_settings")
	assert(bool(world.get("settings_open")) and settings_panel.visible and paused)
	world.call("_on_setting_slider_changed", "music", 0.4)
	assert(is_equal_approx(float(session.get("settings").get("music", 0.0)), 0.4))
	world.call("_toggle_settings")
	assert(not bool(world.get("settings_open")) and not paused)
	session.call("set_setting", "music", 0.7)
	var sanctuary_district := world.get("sanctuary_district") as Node3D
	assert(sanctuary_district != null)
	assert((sanctuary_district.get("source_failures") as Array).is_empty())
	var sanctuary_ground := world.get_node("Sanctuary/SanctuaryGround") as StaticBody3D
	var sanctuary_ground_instance := sanctuary_ground.find_child("*", true, false) as MeshInstance3D
	var sanctuary_ground_mesh := sanctuary_ground_instance.mesh as BoxMesh
	assert(is_equal_approx(sanctuary_ground_mesh.size.x, 80.0) and is_equal_approx(sanctuary_ground_mesh.size.z, 60.0))
	assert(is_equal_approx((world.get("camera") as Camera3D).size, 14.5))
	assert(float((world.get("hearth_fill") as OmniLight3D).light_energy) > 0.0)
	assert(sanctuary_district.get_node_or_null("HearthLodge") != null)
	assert(sanctuary_district.get_node_or_null("ArchiveHouse") != null)
	assert(sanctuary_district.get_node_or_null("BazaarHouse") != null)
	assert(sanctuary_district.get_node_or_null("StarterStable") != null)
	assert(sanctuary_district.get_node_or_null("HearthLodgeCollision") != null)
	assert(sanctuary_district.get_node_or_null("ArchiveHouseCollision") != null)
	assert(sanctuary_district.get_node_or_null("BazaarHouseCollision") != null)
	assert(sanctuary_district.get_node_or_null("HearthCampfireStory/HearthFlameCore") != null)
	assert(int(sanctuary_district.get("meadow_patch_count")) >= 8)
	assert(int(sanctuary_district.get("decorative_crop_bed_count")) >= 4)
	assert(int(sanctuary_district.get("log_pile_count")) >= 3)
	assert(int(sanctuary_district.get("nature_source_count")) >= 1)
	var legacy_hearth_collision := (world.get_node("Sanctuary/Hearth") as Node).find_child("CollisionShape3D", true, false) as CollisionShape3D
	var legacy_hearth_collisions := (world.get_node("Sanctuary/Hearth") as Node).find_children("*", "CollisionShape3D", true, false)
	assert(not legacy_hearth_collisions.is_empty())
	legacy_hearth_collision = legacy_hearth_collisions[0] as CollisionShape3D
	assert(legacy_hearth_collision != null and legacy_hearth_collision.disabled)
	session.get("unlocked_routes").clear()
	for route_id in ["Whisperwood", "Sunlit Beach", "Ember Ridge", "Glass Desert", "Sunken Dungeon"]:
		session.get("unlocked_routes").append(route_id)
	session.get("blueprints").append("Tideglass Compass")
	world.call("_copy_session_to_runtime")
	_assert_player_structure_visuals(world, session)
	assert(world.get_node_or_null("Sanctuary/CloverLivestockPen/SourcedPaddockCow") != null)
	var forest_route := world.get_node_or_null("Whisperwood/WhisperwoodRoute") as Node3D
	assert(forest_route != null)
	assert(float(forest_route.get_meta("authored_traversal_length", 0.0)) >= 50.0)
	assert(int(forest_route.get_meta("authored_beats", 0)) >= 5)
	assert(forest_route.get_node_or_null("AuthoredTopology/ArrivalGrove") != null)
	assert(forest_route.get_node_or_null("AuthoredTopology/FernGrove") != null)
	assert(forest_route.get_node_or_null("AuthoredTopology/GuardianClearing") != null)
	for route_zone in ["SunlitBeach", "EmberRidge", "GlassDesert", "SunkenDungeon"]:
		assert(world.get_node_or_null(route_zone + "/MapIdentity") != null)
		var authored_route := world.get_node_or_null(route_zone + "/ExpeditionRoute") as Node3D
		assert(authored_route != null)
		assert(authored_route.get_node_or_null("RoutePressure") != null)
		assert(authored_route.get_node_or_null("RoutePressure/PressureBlocker/PressureCollision") != null)
		assert(authored_route.get_node_or_null("RouteChoiceMarker") != null)
		assert(authored_route.get_node_or_null("RouteBarrier_Tidepool") != null or authored_route.get_node_or_null("RouteBarrier_Quarry") != null or authored_route.get_node_or_null("RouteBarrier_Oasis") != null or authored_route.get_node_or_null("RouteBarrier_Vault") != null)
	for action in ["move_left", "move_right", "move_up", "move_down", "interact", "attack", "dodge", "rotate_build", "pause"]:
		assert(InputMap.has_action(action))
	var left_stick_bound := false
	for input_event in InputMap.action_get_events("move_left"):
		if input_event is InputEventJoypadMotion:
			left_stick_bound = true
	assert(left_stick_bound)
	var shade := world.get_node_or_null("GlassDesert/MapIdentity/ShadeVolume") as Area3D
	assert(shade != null)
	assert(shade.get_node_or_null("ShadeCollision") != null)
	session.expedition_run = {"status": "active", "run_id": "qa_shade", "biome_id": "Glass Desert", "cargo": {}, "depleted_ids": [], "camp_used": false, "started_day": 1, "anchor": [0.0, 1.0, 7.5], "stake_active": true}
	world.call("_set_zone", "Glass Desert")
	world.player.global_position = shade.global_position + Vector3(0.0, 1.0, 0.0)
	world.set("hazard_timer", 0.0)
	world.call("_update_expedition_hazard", 20.0)
	assert(is_equal_approx(float(world.get("hazard_timer")), 0.0))
	# Recovery is transactional too: a disk failure must leave both the cargo
	# and the physical pack available for another attempt.
	session.recovery_pack = {"pack_id": "qa_pack", "zone_id": "Glass Desert", "loot": {"wood": 1}, "position": [0.0, 1.0, 0.0], "expires_day": 99}
	world.call("_spawn_recovery_pack", {"wood": 1}, Vector3(0.0, 1.0, 0.0), "Glass Desert", "qa_pack")
	session.save_blocked = true
	assert(not bool(world.call("recover_loot", "qa_pack")))
	assert(not session.recovery_pack.is_empty())
	assert(session.expedition_run.get("cargo", {}).is_empty())
	session.save_blocked = false
	session.recovery_pack = {}
	world.call("_clear_recovery_nodes")
	session.expedition_run = {"status": "none", "run_id": "", "biome_id": "", "cargo": {}, "depleted_ids": [], "camp_used": false, "started_day": 0, "anchor": [0.0, 1.0, 7.5]}
	world.call("_set_zone", "Sanctuary")
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
	world.set("last_autosave", 20.0)
	world.call("_process", 0.0)
	assert(bool(world.get("autosave_failed")))
	session.save_blocked = false
	world.set("last_autosave", 20.0)
	world.call("_process", 0.0)
	assert(not bool(world.get("autosave_failed")))
	# The activity UI is a two-phase command: an uncommitted receipt must remain
	# active when its durable commit fails, with no reward or event left behind.
	session.activity_last_manual_epoch = 0
	session.set("activity_last_manual_ticks_msec", 0)
	world.call("_record_activity")
	var activity_before_failed_claim: int = session.activity_events.size()
	session.set("manual_activity_started_ticks_msec", Time.get_ticks_msec() - 1500001)
	session.save_blocked = true
	world.call("_record_activity")
	assert(session.activity_events.size() == activity_before_failed_claim)
	assert(str(session.manual_activity_status().get("status", "idle")) == "active")
	session.save_blocked = false
	session.cancel_manual_activity()
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
	# Stand beside the node rather than teleporting into its collision; the
	# runtime now reports real displacement and correctly interrupts actions
	# when physics pushes the player out of an occupied footprint.
	world.player.global_position = action_node.global_position + Vector3(1.0, 1.0, 0.0)
	var wood_before := int(session.inventory.get("wood", 0))
	world.call("begin_resource_action", action_node)
	assert(world.get("resource_action_node") == action_node)
	world.call("player_took_damage", 1)
	assert(world.get("resource_action_node") == null)
	for contact in 3:
		world.call("begin_resource_action", action_node)
		await create_timer(0.82).timeout
	assert(int(session.inventory.get("wood", 0)) == wood_before + 2)
	# A real Sanctuary placement has a preview/confirm path and creates a
	# persistent visual structure rather than only flipping a label.
	session.set("structures", {})
	session.inventory["wood"] = 8
	session.inventory["plank"] = 2
	world.player.global_position = Vector3(2.0, 1.0, -8.0)
	world.player.last_direction = Vector3(0.0, 0.0, -1.0)
	world.call("_toggle_structure_placement")
	world.call("_update_structure_preview")
	world.call("_contextual_interact")
	assert(session.get("structures").size() == 1)
	var placed_id := str(session.get("structures").keys()[0])
	var placed_visual: Node3D = world.get("settlement_visuals").get(placed_id)
	assert(placed_visual != null)
	assert(is_equal_approx(placed_visual.position.x, 3.5))
	assert(is_equal_approx(placed_visual.position.z, -11.5))
	assert(str(session.get("structures")[placed_id].get("state")) == "blueprint")
	world.player.global_position = placed_visual.global_position + Vector3(0.0, 1.0, 0.0)
	for delivery in 10:
		world.call("_interact")
	assert(str(session.get("structures")[placed_id].get("state")) == "building")
	assert(int(session.get("inventory").get("wood", -1)) == 0)
	assert(int(session.get("inventory").get("plank", -1)) == 0)
	# Workshop orders are durable commands: a failed save must roll back both
	# ingredient debit and completed-output claim.
	var fitout_structure_id := "workshop_fitout_001"
	session.get("structures")[fitout_structure_id] = {"id": fitout_structure_id, "kind": "workshop", "cell": [3, 9], "rotation": 0, "state": "operational", "remaining_hours": 0.0, "total_hours": 36.0, "delivered_materials": {"wood": 12, "stone": 8}}
	session.get("interior_stations")[fitout_structure_id] = {"workbench_001": {"id": "workbench_001", "structure_id": fitout_structure_id, "kind": "workbench", "cell": [-2, -1], "rotation": 0, "state": "operational", "remaining_hours": 0.0, "total_hours": 12.0, "delivered_materials": {"wood": 4, "stone": 2}}}
	session.call("_recalculate_structure_effects")
	var fitout_station := Node3D.new()
	fitout_station.add_to_group("building_interior_station")
	fitout_station.set_meta("interior_station_id", "workbench_001")
	fitout_station.set_meta("interior_structure_id", fitout_structure_id)
	fitout_station.set_meta("installation_state", "operational")
	world.add_child(fitout_station)
	var before_workshop: Dictionary = session.call("snapshot_state")
	session.get("inventory")["wood"] = 3
	session.get("inventory")["stone"] = 1
	session.get("inventory")["plank"] = 0
	world.set("selected_recipe", "plank")
	session.save_blocked = true
	world.call("_workshop_use", fitout_station)
	assert(str(session.get("station_job").get("kind", "none")) == "none")
	assert(int(session.get("inventory").get("wood", 0)) == 3)
	session.save_blocked = false
	world.call("_workshop_use", fitout_station)
	assert(str(session.get("station_job").get("kind", "none")) == "plank")
	assert(int(session.get("inventory").get("wood", 0)) == 0)
	session.get("station_job")["remaining_hours"] = 0.0
	session.save_blocked = true
	world.call("_workshop_use", fitout_station)
	assert(str(session.get("station_job").get("kind", "none")) == "plank")
	assert(int(session.get("inventory").get("plank", 0)) == 0)
	session.save_blocked = false
	world.call("_workshop_use", fitout_station)
	assert(str(session.get("station_job").get("kind", "none")) == "none")
	assert(int(session.get("inventory").get("plank", 0)) == 4)
	session.call("restore_state", before_workshop)
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
	assert(int(session.get("expedition_run").get("cargo").get("shell", 0)) == 0)
	assert(session.get("expedition_run").get("pickups").size() == 1)
	world.call("_interact")
	assert(int(session.get("expedition_run").get("cargo").get("shell", 0)) == 1)
	assert(int(session.get("inventory").get("shell", 0)) == 0)
	world.player.global_position = Vector3(0.0, 1.0, 7.5)
	world.call("_return_home")
	assert(world.get("current_zone") == "Sanctuary")
	assert(int(session.get("inventory").get("shell", 0)) == 1)
	session.energy = 24
	_enter_route(world, "Whisperwood")
	assert(is_equal_approx((world.get("camera") as Camera3D).size, 15.2))
	var forest_wildlife := get_nodes_in_group("wildlife_creature")
	assert(forest_wildlife.size() == 10)
	var wildlife_tracks := get_nodes_in_group("wildlife_track")
	assert(wildlife_tracks.size() == 5)
	for track_node in wildlife_tracks:
		assert(track_node.get_node_or_null("TrackCollision/TrackHitbox") != null)
	var expedition_inscriptions := get_nodes_in_group("expedition_inscription")
	assert(expedition_inscriptions.size() == 5)
	for inscription_node in expedition_inscriptions:
		assert(inscription_node.get_node_or_null("InscriptionCollision/InscriptionHitbox") != null)
	var forest_rabbit: Node = null
	var forest_beetle: Node = null
	for wildlife_node in forest_wildlife:
		if wildlife_node.get_parent().name != "Whisperwood":
			continue
		if str(wildlife_node.get("wildlife_id")) == "forest_rabbit" and forest_rabbit == null:
			forest_rabbit = wildlife_node
		if str(wildlife_node.get("wildlife_id")) == "forest_beetle" and forest_beetle == null:
			forest_beetle = wildlife_node
	assert(forest_rabbit != null and forest_beetle != null)
	assert(forest_rabbit.get_node_or_null("Visual/Body") != null)
	world.player.global_position = forest_rabbit.global_position + Vector3(0.0, 1.0, 0.0)
	world.call("_interact")
	assert(session.get("observed_wildlife").has("forest_rabbit"))
	assert(bool(forest_rabbit.get("observed")))
	var wildlife_before_failed_observation: Array = session.get("observed_wildlife").duplicate()
	session.save_blocked = true
	world.player.global_position = forest_beetle.global_position + Vector3(0.0, 1.0, 0.0)
	world.call("observe_wildlife", forest_beetle)
	assert(session.get("observed_wildlife") == wildlife_before_failed_observation)
	session.save_blocked = false
	var tree_node: Node = null
	for candidate in get_nodes_in_group("resource_node"):
		var tree_body := candidate.get_node_or_null("TreeCollision")
		if candidate.get_parent().name == "Whisperwood" and str(candidate.get("resource_id")) == "wood" and tree_body != null and tree_body.get_child_count() > 0:
			tree_node = candidate
			break
	assert(tree_node != null)
	var measured_tree_shape := tree_node.get_node("TreeCollision").get_child(0) as CollisionShape3D
	var measured_tree_trunk := tree_node.get_node("Trunk") as MeshInstance3D
	assert(measured_tree_shape != null and measured_tree_trunk != null)
	var trunk_measurement := AssetMeasurement.measure_runtime_node(measured_tree_trunk, [], true)
	var measured_tree_bounds: AABB = trunk_measurement.get("bounds", AABB())
	var measured_tree_cylinder := measured_tree_shape.shape as CylinderShape3D
	assert(measured_tree_cylinder != null)
	assert(is_equal_approx(measured_tree_cylinder.radius, maxf(measured_tree_bounds.size.x, measured_tree_bounds.size.z) * 0.5))
	assert(is_equal_approx(measured_tree_cylinder.height, measured_tree_bounds.size.y))
	assert(measured_tree_shape.position.is_equal_approx(measured_tree_bounds.position + measured_tree_bounds.size * 0.5))
	assert(not measured_tree_shape.disabled)
	assert(str(tree_node.get_meta("collision_source", "")).contains("mesh_bounds"))
	var first_chop_mark := tree_node.get_node("ContactMarks/ChopMark_0") as Node3D
	assert(first_chop_mark != null and not first_chop_mark.visible)
	assert(tree_node.get_node_or_null("Sourced_Pine_1") != null)
	assert(world.get_node_or_null("Whisperwood/WhisperwoodRoute") != null)
	assert(world.get_node_or_null("Whisperwood/WhisperwoodRoute/Sourced_Fern_1") != null)
	assert(world.get_node_or_null("Whisperwood/WhisperwoodRoute/Sourced_RockPath_Round_Small_1") != null)
	var forest_topology := world.get_node("Whisperwood/WhisperwoodRoute/AuthoredTopology") as Node3D
	assert(forest_topology != null)
	assert(forest_topology.get_node_or_null("FernGrove/Checkpoint/CheckpointCollision") != null)
	assert(forest_topology.get_node_or_null("GuardianClearing/Checkpoint/CheckpointCollision") != null)
	assert((forest_topology.get_node("FernGrove") as Node3D).global_position.distance_to(Vector3(-12.5, 0.04, -8.6)) < 0.01)
	assert((forest_topology.get_node("GuardianClearing") as Node3D).global_position.distance_to(Vector3(12.5, 0.04, -8.6)) < 0.01)
	var grove_mushroom: Node = null
	for candidate in get_nodes_in_group("resource_node"):
		if str(candidate.get("node_id")) == "Whisperwood:FernGroveMushroom":
			grove_mushroom = candidate
			break
	assert(grove_mushroom != null)
	assert(grove_mushroom.global_position.distance_to(Vector3(-13.1, 0.0, -8.5)) < 0.01)
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
	world.player.global_position = (forest_topology.get_node("GuardianClearing") as Node3D).global_position + Vector3(0.0, 0.96, 0.0)
	world.call("_update_whisperwood_route_progress")
	assert(str(session.get("expedition_run").get("route_phase")) == "objective")
	world.player.global_position = tree_node.global_position
	var forest_wood_before := int(session.get("expedition_run").get("cargo", {}).get("wood", 0))
	assert(world.call("collect_resource", tree_node))
	assert(int(session.get("expedition_run").get("cargo", {}).get("wood", 0)) == forest_wood_before)
	assert(int(session.get("expedition_run").get("contact_progress", {}).get(str(tree_node.get("node_id")), 0)) == 1)
	assert(first_chop_mark.visible)
	assert(world.call("collect_resource", tree_node))
	assert(int(session.get("expedition_run").get("cargo", {}).get("wood", 0)) == forest_wood_before)
	assert(session.get("expedition_run").get("pickups").size() == 1)
	world.call("_interact")
	assert(int(session.get("expedition_run").get("cargo", {}).get("wood", 0)) == forest_wood_before + 2)
	assert(tree_node.get_node_or_null("FelledLogVisual") != null)
	assert((tree_node.get_node("FelledLogVisual") as Node3D).visible)
	var forest_guardian: Node = null
	for candidate in get_nodes_in_group("guardian"):
		if candidate.get_parent().name == "Whisperwood":
			forest_guardian = candidate
			break
	assert(forest_guardian != null)
	forest_guardian.call("restore")
	var guardian_home: Vector3 = (forest_guardian as Node3D).global_position
	var noise_position: Vector3 = guardian_home + Vector3(2.0, 0.0, 0.0)
	forest_guardian.call("hear_noise", noise_position, 6.0)
	assert(str(forest_guardian.get("behavior_state")) == "idle")
	assert((forest_guardian.get_node("CollisionShape3D") as CollisionShape3D).disabled)
	session.get("expedition_run")["branch_id"] = "clearing"
	await process_frame
	await process_frame
	forest_guardian.call("restore")
	forest_guardian.call("hear_noise", noise_position, 6.0)
	assert(str(forest_guardian.get("behavior_state")) == "investigate")
	var investigate_distance_before: float = (forest_guardian as Node3D).global_position.distance_to(noise_position)
	forest_guardian.call("_physics_process", 0.25)
	assert((forest_guardian as Node3D).global_position.distance_to(noise_position) < investigate_distance_before)
	forest_guardian.call("restore")
	world.player.global_position = forest_guardian.global_position + Vector3(2.5, 0.1, 0.0)
	world.set("footstep_timer", 0.0)
	world.call("player_moved", true)
	assert(str(forest_guardian.get("behavior_state")) == "investigate")
	forest_guardian.call("restore")
	assert(forest_guardian.get_node_or_null("CollisionShape3D") != null)
	assert(not (forest_guardian.get_node("CollisionShape3D") as CollisionShape3D).disabled)
	world.player.global_position = forest_guardian.global_position + Vector3(0.0, 0.0, 1.8)
	world.player.set("last_direction", Vector3(0.0, 0.0, -1.0))
	await physics_frame
	var guardian_health_before_contact := int(forest_guardian.get("health"))
	world.call("_player_attack", world.player)
	assert(str(world.get("attack_action_phase")) == "windup")
	world.call("_update_attack_action", 1.0)
	assert(str(world.get("attack_action_phase")) == "active")
	assert(int(forest_guardian.get("health")) < guardian_health_before_contact)
	world.call("_update_attack_action", 0.12)
	assert(str(world.get("attack_action_phase")) == "recovery")
	world.call("_update_attack_action", 0.24)
	assert(str(world.get("attack_action_phase")) == "idle")
	forest_guardian.set("attack_windup", 0.2)
	forest_guardian.set("guarding", false)
	forest_guardian.set("attack_recovery", 0.0)
	forest_guardian.set("stagger_time", 0.0)
	forest_guardian.call("_physics_process", 0.01)
	assert(bool(forest_guardian.get("guarding")))
	forest_guardian.set("attack_windup", 0.0)
	forest_guardian.set("guarding", false)
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
	forest_guardian.set("attack_windup", 0.2)
	forest_guardian.set("guarding", true)
	forest_guardian.call("take_damage", 1, {"guard_break": false})
	assert(float(forest_guardian.get("stagger_time")) > 0.0)
	assert(is_equal_approx(float(forest_guardian.get("attack_windup")), 0.2))
	forest_guardian.set("attack_windup", 0.2)
	forest_guardian.set("guarding", true)
	forest_guardian.call("take_damage", 1, {"guard_break": true})
	assert(is_equal_approx(float(forest_guardian.get("attack_windup")), 0.0))
	forest_guardian.call("set_active", false)
	assert(is_equal_approx(float(forest_guardian.get("stagger_time")), 0.0))
	forest_guardian.call("set_active", true)
	session.get("expedition_run")["cargo"] = {"wood": int(session.get("cargo_capacity"))}
	forest_guardian.call("take_damage", 999)
	assert(not bool(forest_guardian.visible))
	assert(session.get("expedition_run").get("pickups", []).size() == 1)
	session.get("expedition_run")["cargo"] = {}
	forest_guardian.call("restore")
	session.get("expedition_run").get("defeated_guardian_ids").erase("forest_slime")
	session.get("expedition_run")["pickups"] = []
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
	world.player.global_position = relic_node.global_position
	assert(world.call("collect_resource", relic_node))
	var relic_pickup: Node = null
	for candidate in get_nodes_in_group("expedition_pickup"):
		if candidate.get_parent().name == "SunkenDungeon":
			relic_pickup = candidate
			break
	assert(relic_pickup != null)
	world.player.global_position = relic_pickup.global_position
	world.call("_interact")
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
	var recovery_pickup: Node = null
	for candidate in get_nodes_in_group("expedition_pickup"):
		if candidate.get_parent().name == "Whisperwood":
			recovery_pickup = candidate
			break
	assert(recovery_pickup != null)
	recovery_pickup = world.get("expedition_pickup_visuals").get(str(recovery_pickup.get("pickup_id")))
	world.player.global_position = recovery_pickup.global_position
	assert(world.call("collect_expedition_pickup", recovery_pickup))
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
	assert(bool(session.call("has_active_fishing")))
	var fishing_attempt: Dictionary = session.call("fishing_status")
	var fishing_id := str(fishing_attempt.get("attempt_id", ""))
	assert(not fishing_id.is_empty())
	var fishing_guard := 0
	while str(session.call("fishing_status").get("phase", "")) == "waiting" and fishing_guard < 30:
		session.call("advance_fishing", 0.1, false)
		fishing_guard += 1
	assert(str(session.call("fishing_status").get("phase", "")) == "bite")
	world.call("_fishing_action")
	assert(str(session.call("fishing_status").get("phase", "")) == "reeling")
	var reel_guard := 0
	while bool(session.call("has_active_fishing")) and reel_guard < 40:
		session.call("advance_fishing", 0.15, reel_guard % 2 == 0)
		reel_guard += 1
	assert(str(session.call("fishing_status").get("status", "")) == "landed")
	var landed_fish: Dictionary = session.call("claim_fishing")
	assert(int(landed_fish.get("amount", 0)) >= 1)
	assert(int(session.inventory.get("fish", 0)) >= 1)
	session.inventory["fish"] = 2
	session.inventory["water"] = 1
	world.player.global_position = world.trade_stall.global_position
	world.call("_bazaar_interact")
	assert(int(session.get("coins")) == 28)
	# The same cast/reel/claim loop is authored into Sunlit Beach. Tide Reader's
	# uncommon result is secured through the scene station, not a Sanctuary-only
	# shortcut, and the active expedition remains required by the domain.
	session.energy = 24
	session.inventory["fiber"] = 1
	session.masteries["Fishing"] = 70
	session.call("_sync_mastery_permissions")
	_enter_route(world, "Sunlit Beach")
	var coastal_spot := world.get("coastal_fishing_spot") as Node3D
	assert(coastal_spot != null and coastal_spot.is_visible_in_tree())
	world.player.global_position = coastal_spot.global_position
	world.call("_fishing_interact", coastal_spot)
	assert(bool(session.call("has_active_fishing")))
	var coastal_fishing_id := str(session.get("fishing_attempt").get("attempt_id", ""))
	session.get("chance_rolls")["fishing_tide_reader|uncommon_catch_weight|%s" % coastal_fishing_id] = true
	var coastal_fishing_guard := 0
	while str(session.call("fishing_status").get("phase", "")) == "waiting" and coastal_fishing_guard < 30:
		session.call("advance_fishing", 0.1, false)
		coastal_fishing_guard += 1
	assert(str(session.call("fishing_status").get("phase", "")) == "bite")
	world.call("_fishing_action")
	var coastal_reel_guard := 0
	while bool(session.call("has_active_fishing")) and coastal_reel_guard < 40:
		session.call("advance_fishing", 0.15, coastal_reel_guard % 2 == 0)
		coastal_reel_guard += 1
	assert(str(session.call("fishing_status").get("status", "")) == "landed")
	world.call("_fishing_interact", coastal_spot)
	assert(str(session.get("fishing_attempt").get("status", "")) == "idle")
	assert(int(session.inventory.get("shell", 0)) >= 1)
	world.player.global_position = Vector3(0.0, 1.0, 7.5)
	world.call("_return_home")
	assert(world.get("current_zone") == "Sanctuary")
	# An active expedition stores its last world position, not just its biome.
	session.energy = 24
	_enter_route(world, "Whisperwood")
	# Keep the persistence probe on the authored trail, outside the measured
	# envelope of the nearby Trail Stone. The new collider is intentionally
	# large enough to match the imported rock, so an overlapping teleport would
	# test physics depenetration rather than save/restore.
	world.player.global_position = Vector3(1.5, 1.0, -3.0)
	world.call("_sync_expedition_anchor")
	var anchor: Array = session.get("expedition_run").get("anchor")
	assert(is_equal_approx(float(anchor[0]), 1.5))
	assert(is_equal_approx(float(anchor[2]), -3.0))
	assert(session.call("save_game"))
	var resumed := MainScene.instantiate()
	root.add_child(resumed)
	await process_frame
	assert(resumed.get("current_zone") == "Whisperwood")
	assert(is_equal_approx(float(resumed.player.global_position.x), 1.5))
	assert(is_equal_approx(float(resumed.player.global_position.z), -3.0))
	resumed.queue_free()
	await process_frame
	world.call("_return_home")
	assert(world.get("current_zone") == "Whisperwood")
	world.player.global_position = Vector3(0.0, 1.0, 7.5)
	world.call("_return_home")
	print("WORLD_LOOP_TESTS_PASS")
	quit()
