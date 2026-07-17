extends SceneTree

const SessionScript = preload("res://scripts/game_session.gd")

func _init() -> void:
	var qa_dir := DirAccess.open("user://")
	if qa_dir != null:
		for filename in qa_dir.get_files():
			if filename.begins_with("qa_") and filename.ends_with(".json"):
				qa_dir.remove(filename)
	var session := SessionScript.new()
	session.save_slot = "qa_session"
	root.add_child(session)
	var all_routes := ["Whisperwood", "Sunlit Beach", "Ember Ridge", "Glass Desert", "Sunken Dungeon"]
	# Isolate the test from any user:// save left by an earlier run.
	session.day = 1
	session.xp = 0
	session.level = 1
	session.ability_points = 2
	session.energy = 24
	session.activity_receipts = []
	session.last_day_transaction = 0
	# The real-life receipt is idempotent: the same source event cannot pay twice.
	var first := session.record_activity("qa-receipt-001", 25)
	var second := session.record_activity("qa-receipt-001", 25)
	assert(first)
	assert(not second)
	assert(session.xp == 2)
	assert(session.energy == 24)
	assert(session.activity_events.size() == 1)
	assert(session.activity_events[0]["event_id"] == "qa-receipt-001")
	# Level thresholds award exactly one ability point per crossed level.
	session.award_xp(198)
	assert(session.level == 3)
	assert(session.ability_points == 4)
	# The daily transaction grows only watered crops and never repeats on retry.
	session.farm_plot = {"state": "planted", "crop": "wheat", "growth": 0, "watered": true}
	session.station_job = {"kind": "plank", "remaining_hours": 12.0, "output_id": "plank", "output": 4}
	session.advance_day(2)
	assert(session.day == 2)
	assert(session.farm_plot["growth"] == 1)
	assert(session.station_job["remaining_hours"] == 0.0)
	var current_growth := int(session.farm_plot["growth"])
	session.advance_day(2)
	assert(session.farm_plot["growth"] == current_growth)
	session.advance_day(3)
	assert(session.day == 3)
	# Sleeping is the only daily transaction; callers cannot skip days and
	# accidentally apply one crop/job tick to a multi-day jump.
	session.advance_day(5)
	assert(session.day == 3)
	# Save/load preserves a meaningful runtime state.
	session.add_item("ore", 7)
	assert(session.save_game())
	var loaded := SessionScript.new()
	loaded.save_slot = "qa_session"
	root.add_child(loaded)
	assert(loaded.load_game())
	assert(loaded.inventory["ore"] == 7)
	assert(loaded.day == 3)
	session.add_item("ore", 5)
	assert(session.save_game())
	var corrupt := FileAccess.open("user://qa_session.json", FileAccess.WRITE)
	corrupt.store_string("{broken json")
	corrupt.close()
	var recovered := SessionScript.new()
	recovered.save_slot = "qa_session"
	root.add_child(recovered)
	assert(recovered.load_game())
	assert(recovered.inventory["ore"] == 7)
	var midnight := SessionScript.new()
	midnight.save_slot = "qa_midnight"
	root.add_child(midnight)
	midnight.hour = 23.999
	assert(midnight.save_game())
	var midnight_loaded := SessionScript.new()
	midnight_loaded.save_slot = "qa_midnight"
	root.add_child(midnight_loaded)
	assert(midnight_loaded.load_game())
	assert(float(midnight_loaded.hour) > 23.99)
	var duplicate_structures := SessionScript.new()
	duplicate_structures.save_slot = "qa_duplicate_structures"
	root.add_child(duplicate_structures)
	duplicate_structures.structures = {
		"rain_cistern_legacy_a": {"id": "rain_cistern_legacy_a", "kind": "rain_cistern", "cell": [11, 8], "state": "operational", "remaining_hours": 0.0, "total_hours": 24.0, "delivered_materials": {"wood": 8, "plank": 2}},
		"rain_cistern_legacy_b": {"id": "rain_cistern_legacy_b", "kind": "rain_cistern", "cell": [8, 8], "state": "operational", "remaining_hours": 0.0, "total_hours": 24.0, "delivered_materials": {"wood": 8, "plank": 2}},
	}
	assert(duplicate_structures.save_game())
	var duplicate_loaded := SessionScript.new()
	duplicate_loaded.save_slot = "qa_duplicate_structures"
	root.add_child(duplicate_loaded)
	assert(duplicate_loaded.load_game())
	assert(duplicate_loaded.structures.size() == 2)
	# Expedition cargo is isolated from banked inventory and survives a reload.
	var expedition := SessionScript.new()
	expedition.save_slot = "qa_expedition"
	root.add_child(expedition)
	expedition.get("unlocked_routes").clear()
	for route_id in all_routes:
		expedition.get("unlocked_routes").append(route_id)
	expedition.energy = 24
	expedition.expedition_run = {"status": "none", "run_id": "", "biome_id": "", "cargo": {}, "depleted_ids": [], "camp_used": false, "started_day": 0, "anchor": [0.0, 1.0, 7.5]}
	expedition.recovery_pack = {}
	expedition.inventory = {"wood": 0, "stone": 0, "fiber": 0, "slime_gel": 0, "ore": 0, "sunstone": 0, "berries": 0, "shell": 0, "wheat": 2, "flour": 0, "bread": 0, "plank": 0, "water": 3}
	expedition.quest = {"id": "first_supply_run", "title": "FIRST SUPPLY RUN", "description": "Return from an expedition with 5 cargo.", "progress": 0, "target": 5, "claimed": false}
	assert(expedition.start_expedition("Sunlit Beach"))
	assert(expedition.collect_expedition_resource("SunlitBeach:TideglassShell", "shell", 1))
	assert(expedition.inventory["shell"] == 0)
	assert(expedition.save_game())
	var expedition_loaded := SessionScript.new()
	expedition_loaded.save_slot = "qa_expedition"
	root.add_child(expedition_loaded)
	assert(expedition_loaded.load_game())
	assert(expedition_loaded.has_active_expedition())
	assert(expedition_loaded.expedition_run["biome_id"] == "Sunlit Beach")
	assert(expedition_loaded.expedition_run["cargo"]["shell"] == 1)
	assert(not expedition_loaded.collect_expedition_resource("SunlitBeach:TideglassShell", "shell", 1))
	assert(expedition_loaded.finish_expedition()["shell"] == 1)
	assert(expedition_loaded.inventory["shell"] == 1)
	assert(expedition_loaded.quest["progress"] == 1)
	# Survival choices remain available in the field through the same
	# authoritative inventory commands; they are not Sanctuary-only decoration.
	expedition_loaded.inventory["bread"] = 1
	expedition_loaded.energy = 8
	expedition_loaded.nutrition = 20
	assert(expedition_loaded.consume_food("bread"))
	assert(expedition_loaded.energy == 17)
	assert(expedition_loaded.nutrition == 42)
	# Expedition cargo is a real constraint: a failed collection is side-effect
	# free, and guardian rewards use the same satchel budget atomically.
	var pressure := SessionScript.new()
	pressure.save_slot = "qa_pressure"
	root.add_child(pressure)
	pressure.energy = 24
	pressure.coins = 100
	pressure.cargo_capacity = 2
	assert(pressure.start_expedition("Whisperwood"))
	assert(pressure.collect_expedition_resource("Whisperwood:small", "wood", 1))
	var energy_before_full := pressure.energy
	assert(not pressure.collect_expedition_resource("Whisperwood:large", "wood", 2))
	assert(pressure.energy == energy_before_full)
	assert(pressure.commit_expedition_branch("clearing"))
	var guardian_reward: Dictionary = pressure.resolve_guardian_defeat("forest_slime")
	assert(guardian_reward["reward_id"] == "slime_gel")
	assert(pressure.expedition_cargo_used() == 2)
	assert(pressure.resolve_guardian_defeat("forest_slime").is_empty())
	var stake := SessionScript.new()
	stake.save_slot = "qa_stake"
	root.add_child(stake)
	assert(stake.start_expedition("Whisperwood"))
	assert(stake.commit_expedition_branch("clearing"))
	assert(not stake.resolve_guardian_defeat("forest_slime").is_empty())
	assert(not stake.open_expedition_cache().is_empty())
	var stake_energy := stake.energy
	var stake_tick: Dictionary = stake.apply_expedition_stake_tick()
	assert(stake_tick["ticks"] == 1)
	assert(stake.energy == stake_energy - 1)
	# Farm and workshop mutations are session commands, so the scene cannot
	# spend an item or energy and then fail to persist the resulting state.
	var economy := SessionScript.new()
	economy.save_slot = "qa_economy"
	root.add_child(economy)
	economy.energy = 12
	economy.inventory["wood"] = 10
	economy.inventory["fiber"] = 4
	economy.inventory["wheat"] = 2
	economy.inventory["water"] = 2
	assert(economy.interact_farm()["action"] == "tilled")
	assert(economy.interact_farm()["action"] == "planted")
	economy.built["workshop"] = true
	economy.inventory["stone"] = 2
	var started_job: Dictionary = economy.start_workshop_job("plank")
	assert(started_job["remaining_hours"] == 12.0)
	assert(economy.inventory["wood"] == 6)
	# Odd cargo keeps the remainder and drops only floor(quantity / 2) into
	# a pack belonging to the biome where the run ended.
	expedition_loaded.energy = 24
	assert(expedition_loaded.start_expedition("Glass Desert"))
	assert(expedition_loaded.collect_expedition_resource("GlassDesert:Sunstone", "sunstone", 5))
	var faint_pack: Dictionary = expedition_loaded.fail_expedition(Vector3(2.0, 1.0, 3.0))
	assert(expedition_loaded.inventory["sunstone"] == 3)
	assert(faint_pack["zone_id"] == "Glass Desert")
	assert(faint_pack["loot"]["sunstone"] == 2)
	var recovery_id := str(expedition_loaded.recovery_pack.get("pack_id", ""))
	assert(not recovery_id.is_empty())
	assert(expedition_loaded.claim_recovery_pack(recovery_id, "Sunlit Beach").is_empty())
	var recovered_loot: Dictionary = expedition_loaded.claim_recovery_pack(recovery_id, "Glass Desert")
	assert(recovered_loot["sunstone"] == 2)
	assert(expedition_loaded.claim_recovery_pack(recovery_id, "Glass Desert").is_empty())
	assert(not expedition_loaded.has_active_expedition())
	# A faint that drops no new loot must not move or duplicate the existing pack.
	var original_pack := expedition_loaded.recovery_pack.duplicate(true)
	expedition_loaded.energy = 24
	assert(expedition_loaded.start_expedition("Sunlit Beach"))
	assert(expedition_loaded.collect_expedition_resource("SunlitBeach:SmallShell", "shell", 1))
	var no_new_pack: Dictionary = expedition_loaded.fail_expedition(Vector3(9.0, 1.0, 9.0))
	assert(no_new_pack.is_empty())
	assert(expedition_loaded.recovery_pack == original_pack)
	# A future primary save may still fall back to a compatible backup.
	var future_writer := SessionScript.new()
	future_writer.save_slot = "qa_future"
	root.add_child(future_writer)
	future_writer.coins = 777
	assert(future_writer.save_game())
	future_writer.coins = 888
	assert(future_writer.save_game())
	var future_primary := FileAccess.open("user://qa_future.json", FileAccess.WRITE)
	future_primary.store_string(JSON.stringify({"save_version": 99}))
	future_primary.close()
	var future_loaded := SessionScript.new()
	future_loaded.save_slot = "qa_future"
	root.add_child(future_loaded)
	assert(future_loaded.load_game())
	assert(not future_loaded.save_blocked)
	assert(future_loaded.coins == 777)
	# Malformed nested data is rejected without mutating the live session.
	var malformed := SessionScript.new()
	malformed.save_slot = "qa_malformed"
	root.add_child(malformed)
	malformed.coins = 321
	var malformed_file := FileAccess.open("user://qa_malformed.json", FileAccess.WRITE)
	malformed_file.store_string(JSON.stringify({"save_version": 4, "stats": []}))
	malformed_file.close()
	assert(not malformed.load_game())
	assert(malformed.coins == 321)
	# Type-correct but impossible scalar state is rejected before it can create
	# an invalid live session or soft-lock future day transactions.
	var semantic_file := FileAccess.open("user://qa_semantic.json", FileAccess.WRITE)
	semantic_file.store_string(JSON.stringify({"save_version": 5, "day": 1, "last_day_transaction": 999, "max_health": 0, "health": 0}))
	semantic_file.close()
	var semantic := SessionScript.new()
	semantic.save_slot = "qa_semantic"
	root.add_child(semantic)
	assert(not semantic.load_game())
	assert(semantic.max_health == 100)
	assert(semantic.health == 100)
	# A runtime state that would be rejected on load must never be committed by
	# save_game in the first place.
	var invalid_save := SessionScript.new()
	invalid_save.save_slot = "qa_invalid_save"
	root.add_child(invalid_save)
	invalid_save.health = 0
	assert(not invalid_save.save_game())
	assert(not FileAccess.file_exists("user://qa_invalid_save.json"))
	# A malformed primary must not overwrite the last known-good backup on the
	# next save after recovery.
	var backup_guard := SessionScript.new()
	backup_guard.save_slot = "qa_backup_guard"
	root.add_child(backup_guard)
	backup_guard.coins = 444
	assert(backup_guard.save_game())
	backup_guard.coins = 555
	assert(backup_guard.save_game())
	var broken_backup_primary := FileAccess.open("user://qa_backup_guard.json", FileAccess.WRITE)
	broken_backup_primary.store_string("{broken json")
	broken_backup_primary.close()
	var backup_recovered := SessionScript.new()
	backup_recovered.save_slot = "qa_backup_guard"
	root.add_child(backup_recovered)
	assert(backup_recovered.load_game())
	assert(backup_recovered.coins == 444)
	backup_recovered.coins = 666
	assert(backup_recovered.save_game())
	var preserved_backup := FileAccess.open("user://qa_backup_guard.backup.json", FileAccess.READ)
	assert(preserved_backup != null)
	var preserved_backup_data: Variant = JSON.parse_string(preserved_backup.get_as_text())
	preserved_backup.close()
	assert(preserved_backup_data is Dictionary)
	assert(int(preserved_backup_data.get("coins", 0)) == 444)
	# A type-correct but malformed primary save must fall back to a valid backup
	# before any nested scalar reaches _apply_dict().
	var typed_backup_writer := SessionScript.new()
	typed_backup_writer.save_slot = "qa_typed_backup"
	root.add_child(typed_backup_writer)
	typed_backup_writer.coins = 123
	assert(typed_backup_writer.save_game())
	typed_backup_writer.coins = 234
	assert(typed_backup_writer.save_game())
	var malformed_typed_primary := FileAccess.open("user://qa_typed_backup.json", FileAccess.WRITE)
	malformed_typed_primary.store_string(JSON.stringify({"save_version": 7, "content_version": 1, "construction_progress": {}, "expedition_run": {"status": "active", "biome_id": "Whisperwood", "cargo": {}, "anchor": [{}, 1, 0]}}))
	malformed_typed_primary.close()
	var typed_backup_recovered := SessionScript.new()
	typed_backup_recovered.save_slot = "qa_typed_backup"
	root.add_child(typed_backup_recovered)
	assert(typed_backup_recovered.load_game())
	assert(typed_backup_recovered.coins == 123)
	# A future content schema must not be silently rewritten as the current
	# content version, and a day receipt ahead of its day must be rejected before
	# it can soft-lock the next sleep transaction.
	var future_content_file := FileAccess.open("user://qa_future_content.json", FileAccess.WRITE)
	future_content_file.store_string(JSON.stringify({"save_version": 7, "content_version": 2}))
	future_content_file.close()
	var future_content := SessionScript.new()
	future_content.save_slot = "qa_future_content"
	root.add_child(future_content)
	assert(not future_content.load_game())
	assert(future_content.save_blocked)
	# Legacy paid construction records used to arrive as a fully supplied
	# blueprint. Migration must move them into a finishable frame state rather
	# than leaving an invisible, permanently pending job.
	var legacy_writer := SessionScript.new()
	legacy_writer.save_slot = "qa_legacy_blueprint"
	root.add_child(legacy_writer)
	var legacy_payload: Dictionary = legacy_writer.call("_to_dict")
	legacy_payload["save_version"] = 6
	legacy_payload["structures"] = {"legacy_archive": {"id": "legacy_archive", "kind": "archive", "cell": [6, 8], "state": "blueprint", "remaining_hours": 0.0}}
	var legacy_file := FileAccess.open("user://qa_legacy_blueprint.json", FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(legacy_payload))
	legacy_file.close()
	var legacy_loaded := SessionScript.new()
	legacy_loaded.save_slot = "qa_legacy_blueprint"
	root.add_child(legacy_loaded)
	assert(legacy_loaded.load_game())
	assert(str(legacy_loaded.structures["legacy_archive"]["state"]) == "building")
	assert(float(legacy_loaded.structures["legacy_archive"]["remaining_hours"]) > 0.0)
	# Fresh saves form a route arc instead of exposing the final Dungeon at the
	# first click; successful extraction is the authoritative unlock event.
	var route_chain := SessionScript.new()
	route_chain.save_slot = "qa_route_chain"
	root.add_child(route_chain)
	assert(not route_chain.start_expedition("Sunlit Beach"))
	assert(route_chain.start_expedition("Whisperwood"))
	assert(route_chain.commit_expedition_branch("grove"))
	assert(route_chain.complete_expedition_resource("Whisperglass:chain", "berries", 1, 1))
	assert(not route_chain.open_expedition_capstone().is_empty())
	assert(route_chain.finish_expedition().get("berries", 0) == 3)
	assert(route_chain.route_is_unlocked("Sunlit Beach"))
	var wide_anchor := SessionScript.new()
	wide_anchor.save_slot = "qa_wide_anchor"
	root.add_child(wide_anchor)
	assert(wide_anchor.start_expedition("Whisperwood"))
	var wide_run_id := str(wide_anchor.expedition_run.get("run_id", ""))
	assert(wide_anchor.update_expedition_anchor(wide_run_id, [19.0, 1.0, 14.0]))
	assert(is_equal_approx(float(wide_anchor.expedition_run["anchor"][0]), 19.0))
	assert(is_equal_approx(float(wide_anchor.expedition_run["anchor"][2]), 14.0))
	route_chain.energy = 24
	assert(route_chain.start_expedition("Sunlit Beach"))
	assert(route_chain.commit_expedition_branch("tidepool"))
	assert(route_chain.collect_expedition_resource("SunlitBeach:TideglassShell", "shell", 1))
	assert(not bool(route_chain.expedition_run.get("objective_complete", false)))
	assert(route_chain.collect_expedition_resource("SunlitBeach:TideglassShell:pool", "shell", 1))
	assert(bool(route_chain.expedition_run.get("objective_complete", false)))
	assert(not route_chain.open_expedition_capstone().is_empty())
	assert(route_chain.finish_expedition().get("shell", 0) == 3)
	assert(route_chain.route_is_unlocked("Ember Ridge"))
	route_chain.energy = 24
	assert(route_chain.start_expedition("Ember Ridge"))
	assert(route_chain.commit_expedition_branch("quarry"))
	assert(route_chain.collect_expedition_resource("EmberRidge:quarry", "ore", 1))
	assert(route_chain.collect_expedition_resource("EmberRidge:quarry:2", "ore", 1))
	assert(route_chain.collect_expedition_resource("EmberRidge:quarry:3", "ore", 1))
	assert(not route_chain.open_expedition_capstone().is_empty())
	assert(route_chain.finish_expedition().get("ore", 0) == 4)
	assert(route_chain.route_is_unlocked("Ember Ridge"))
	assert(route_chain.route_is_unlocked("Glass Desert"))
	route_chain.energy = 24
	assert(route_chain.start_expedition("Glass Desert"))
	assert(route_chain.commit_expedition_branch("oasis"))
	for index in 4:
		assert(route_chain.collect_expedition_resource("GlassDesert:oasis:%d" % index, "fiber", 1))
	assert(bool(route_chain.expedition_run.get("objective_complete", false)))
	assert(not route_chain.open_expedition_capstone().is_empty())
	assert(route_chain.finish_expedition().get("fiber", 0) >= 3)
	assert(route_chain.route_is_unlocked("Sunken Dungeon"))
	var bypass_route := SessionScript.new()
	bypass_route.save_slot = "qa_route_bypass"
	root.add_child(bypass_route)
	assert(bypass_route.start_expedition("Whisperwood"))
	assert(bypass_route.collect_expedition_resource("Whisperwood:uncommitted", "wood", 1))
	assert(bypass_route.finish_expedition().get("wood", 0) == 1)
	assert(not bypass_route.route_is_unlocked("Sunlit Beach"))
	# Each authored map exposes the same route contract: a committed branch,
	# an objective owned by that branch, and a capstone reward before extraction.
	var authored_routes := SessionScript.new()
	authored_routes.save_slot = "qa_authored_routes"
	root.add_child(authored_routes)
	authored_routes.get("unlocked_routes").clear()
	for route_id in all_routes:
		authored_routes.get("unlocked_routes").append(route_id)
	assert(authored_routes.start_expedition("Sunlit Beach"))
	assert(authored_routes.commit_expedition_branch("tidepool"))
	assert(authored_routes.collect_expedition_resource("SunlitBeach:tidepool:1", "shell", 1))
	assert(not bool(authored_routes.expedition_run.get("objective_complete", false)))
	assert(authored_routes.save_game())
	var partial_objective_loaded := SessionScript.new()
	partial_objective_loaded.save_slot = "qa_authored_routes"
	root.add_child(partial_objective_loaded)
	assert(partial_objective_loaded.load_game())
	assert(partial_objective_loaded.expedition_run["route_phase"] == "objective")
	assert(partial_objective_loaded.expedition_run["objective_progress"] == 1)
	assert(authored_routes.collect_expedition_resource("SunlitBeach:tidepool:2", "shell", 1))
	assert(authored_routes.expedition_route_snapshot().get("branch_definition", {}).get("objective_id") == "shell")
	assert(authored_routes.open_expedition_capstone().get("loot", {}).get("shell", 0) == 1)
	assert(authored_routes.finish_expedition().get("shell", 0) >= 1)
	authored_routes.energy = 24
	assert(authored_routes.start_expedition("Ember Ridge"))
	assert(authored_routes.commit_expedition_branch("quarry"))
	assert(authored_routes.collect_expedition_resource("EmberRidge:quarry", "ore", 1))
	assert(authored_routes.collect_expedition_resource("EmberRidge:quarry:2", "ore", 1))
	assert(authored_routes.collect_expedition_resource("EmberRidge:quarry:3", "ore", 1))
	assert(bool(authored_routes.expedition_run.get("objective_complete", false)))
	assert(not authored_routes.open_expedition_capstone().is_empty())
	assert(authored_routes.finish_expedition().get("ore", 0) >= 1)
	authored_routes.energy = 24
	assert(authored_routes.start_expedition("Glass Desert"))
	assert(authored_routes.commit_expedition_branch("oasis"))
	for index in 4:
		assert(authored_routes.collect_expedition_resource("GlassDesert:oasis:%d" % index, "fiber", 1))
	assert(not authored_routes.open_expedition_capstone().is_empty())
	assert(authored_routes.finish_expedition().get("fiber", 0) >= 1)
	authored_routes.energy = 24
	assert(authored_routes.start_expedition("Sunken Dungeon"))
	assert(authored_routes.commit_expedition_branch("vault"))
	assert(authored_routes.record_discovery("Aether Relic"))
	assert(not authored_routes.open_expedition_capstone().is_empty())
	assert(authored_routes.finish_expedition().get("relic", 0) >= 1)
	var impossible_day_file := FileAccess.open("user://qa_impossible_day.json", FileAccess.WRITE)
	impossible_day_file.store_string(JSON.stringify({"save_version": 7, "content_version": 1, "day": 5, "last_day_transaction": 6}))
	impossible_day_file.close()
	var impossible_day := SessionScript.new()
	impossible_day.save_slot = "qa_impossible_day"
	root.add_child(impossible_day)
	assert(not impossible_day.load_game())
	# Research is persistent and only available after a discovery is recorded.
	var built_state: Dictionary = expedition_loaded.built
	built_state["library"] = true
	expedition_loaded.built = built_state
	assert(expedition_loaded.record_discovery("Tideglass"))
	assert(expedition_loaded.research_discovery("Tideglass"))
	assert(not expedition_loaded.researched.has("Tideglass"))
	expedition_loaded.advance_day(expedition_loaded.day + 1)
	assert(expedition_loaded.research_job["status"] == "ready")
	assert(expedition_loaded.claim_research())
	assert(expedition_loaded.researched.has("Tideglass"))
	# Guardian defeat IDs are part of the active run, preventing reward replay
	# after a reload just like depleted resource IDs.
	expedition_loaded.energy = 24
	assert(expedition_loaded.start_expedition("Whisperwood"))
	assert(expedition_loaded.mark_guardian_defeated("FORESTSLIME"))
	assert(expedition_loaded.save_game())
	var guardian_loaded := SessionScript.new()
	guardian_loaded.save_slot = "qa_expedition"
	root.add_child(guardian_loaded)
	assert(guardian_loaded.load_game())
	assert(guardian_loaded.expedition_run["defeated_guardian_ids"].has("FORESTSLIME"))
	assert(not guardian_loaded.mark_guardian_defeated("FORESTSLIME"))
	# Multi-contact expedition resources keep their progress inside the active
	# run and finalize without charging the finishing contact twice.
	var contact_run := SessionScript.new()
	contact_run.save_slot = "qa_contact_run"
	root.add_child(contact_run)
	contact_run.energy = 24
	assert(contact_run.start_expedition("Whisperwood"))
	assert(contact_run.record_expedition_contact("Whisperwood:wood:tree", 1))
	assert(contact_run.save_game())
	var contact_loaded := SessionScript.new()
	contact_loaded.save_slot = "qa_contact_run"
	root.add_child(contact_loaded)
	assert(contact_loaded.load_game())
	assert(int(contact_loaded.expedition_run["contact_progress"].get("Whisperwood:wood:tree", 0)) == 1)
	assert(not contact_loaded.complete_expedition_resource("Whisperwood:wood:other", "wood", 2, 2))
	assert(contact_loaded.complete_expedition_resource("Whisperwood:wood:tree", "wood", 2, 2))
	assert(int(contact_loaded.expedition_run["cargo"].get("wood", 0)) == 2)
	assert(not contact_loaded.expedition_run["contact_progress"].has("Whisperwood:wood:tree"))
	var atomic_run := SessionScript.new()
	atomic_run.save_slot = "qa_atomic_run"
	root.add_child(atomic_run)
	atomic_run.energy = 24
	assert(atomic_run.start_expedition("Whisperwood"))
	atomic_run.equipment["hatchet"]["durability"] = 0
	var atomic_energy := atomic_run.energy
	assert(not atomic_run.collect_expedition_resource_with_tool("Whisperwood:wood:tree", "wood", 2))
	assert(atomic_run.energy == atomic_energy)
	assert(atomic_run.expedition_run["cargo"].is_empty())
	assert(atomic_run.expedition_run["depleted_ids"].is_empty())
	# Tools are durable equipment, not expedition cargo: a broken tool blocks the
	# action without silently charging another resource.
	var systems := SessionScript.new()
	systems.save_slot = "qa_systems"
	root.add_child(systems)
	systems.equipment["hatchet"]["durability"] = 2
	var energy_before_tools := systems.energy
	assert(systems.use_tool_for_resource("wood"))
	assert(int(systems.equipment["hatchet"]["durability"]) == 1)
	assert(systems.use_tool_for_resource("wood"))
	assert(int(systems.equipment["hatchet"]["durability"]) == 0)
	assert(not systems.use_tool_for_resource("wood"))
	assert(systems.energy == energy_before_tools)
	# Food and hydration are bounded, persistent survival choices.
	systems.inventory["bread"] = 1
	systems.energy = 10
	systems.nutrition = 10
	assert(systems.consume_food("bread"))
	assert(systems.inventory["bread"] == 0)
	assert(systems.energy == 19)
	assert(systems.nutrition == 32)
	systems.inventory["water"] = 1
	systems.hydration = 70
	assert(systems.drink_water())
	assert(systems.hydration == 100)
	# Settlement livestock is a day-based loop: build, feed, sleep, collect.
	systems.structures["qa_livestock_pen"] = {"id": "qa_livestock_pen", "kind": "livestock_pen", "cell": [2, 0], "state": "operational", "remaining_hours": 0.0, "total_hours": 24.0, "delivered_materials": {"wood": 10, "fiber": 6, "plank": 2}}
	systems.call("_activate_structure_kind", "livestock_pen")
	systems.inventory["wheat"] = 1
	assert(bool(systems.built["livestock_pen"]))
	assert(systems.feed_livestock("clover"))
	systems.advance_day(systems.day + 1)
	assert(bool(systems.livestock["clover"]["production_ready"]))
	assert(systems.collect_livestock("clover")["egg"] == 1)
	assert(systems.collect_livestock("clover").is_empty())
	# Placement is grid-aware, persists its footprint, and becomes useful only
	# after materials are physically delivered to the blueprint and its frame
	# construction clock completes.
	systems.structures = {}
	systems.blueprints.append("Tideglass Compass")
	systems.inventory["wood"] = 8
	systems.inventory["plank"] = 2
	assert(not systems.can_place_structure("rain_cistern", [0, -4]))
	assert(not systems.can_place_structure("rain_cistern", [5, 3]))
	assert(not systems.can_place_structure("rain_cistern", [-12, -6]))
	assert(not systems.can_place_structure("rain_cistern", [11, 7]))
	assert(systems.can_place_structure("rain_cistern", [11, 8]))
	var cistern: Dictionary = systems.place_structure("rain_cistern", [11, 8])
	assert(cistern["state"] == "blueprint")
	assert(int(systems.inventory["wood"]) == 8)
	assert(int(systems.inventory["plank"]) == 2)
	assert(systems.deliver_structure_material(str(cistern["id"]), "wood", 8)["state"] == "blueprint")
	var framed_cistern: Dictionary = systems.deliver_structure_material(str(cistern["id"]), "plank", 2)
	assert(framed_cistern["state"] == "building")
	assert(int(systems.inventory["wood"]) == 0)
	assert(int(systems.inventory["plank"]) == 0)
	assert(not systems.can_place_structure("rain_cistern", [8, 6]))
	assert(systems.place_structure("rain_cistern", [8, 8]).is_empty())
	systems.advance_day(systems.day + 1)
	assert(str(systems.structures[cistern["id"]]["state"]) == "building")
	systems.advance_day(systems.day + 1)
	assert(str(systems.structures[cistern["id"]]["state"]) == "operational")
	# The same staged pipeline applies to a player-placed utility building, and
	# completing it unlocks the connected station capability from authoritative
	# state rather than from a presentation label.
	var placed_builder := SessionScript.new()
	placed_builder.save_slot = "qa_placed_builder"
	root.add_child(placed_builder)
	placed_builder.inventory["wood"] = 12
	placed_builder.inventory["stone"] = 8
	var workshop_blueprint: Dictionary = placed_builder.place_structure("workshop", [2, 0])
	assert(workshop_blueprint["state"] == "blueprint")
	assert(placed_builder.deliver_structure_material(str(workshop_blueprint["id"]), "wood", 12)["state"] == "blueprint")
	# A fresh player can reach the first Workshop without pre-existing Planks;
	# Planks are a downstream product of this operational station.
	assert(placed_builder.deliver_structure_material(str(workshop_blueprint["id"]), "stone", 8)["state"] == "building")
	for build_day in 3:
		placed_builder.advance_day(placed_builder.day + 1)
	assert(str(placed_builder.structures[workshop_blueprint["id"]]["state"]) == "operational")
	assert(bool(placed_builder.built["workshop"]))
	# Fresh-save progression must not deadlock at the first research building:
	# the Archive is the bootstrap research desk, while discoveries gate later
	# buildings such as the livestock pen.
	var bootstrap_graph := SessionScript.new()
	bootstrap_graph.save_slot = "qa_bootstrap_graph"
	root.add_child(bootstrap_graph)
	assert(bootstrap_graph.blueprints.is_empty())
	assert(bootstrap_graph.has_structure_blueprint("archive"))
	assert(not bootstrap_graph.has_structure_blueprint("livestock_pen"))
	bootstrap_graph.inventory["wood"] = 8
	bootstrap_graph.inventory["stone"] = 8
	bootstrap_graph.inventory["plank"] = 3
	var archive_blueprint: Dictionary = bootstrap_graph.place_structure("archive", [6, 8])
	assert(archive_blueprint["state"] == "blueprint")
	for material_id in {"wood": 8, "stone": 8, "plank": 3}:
		var archive_frame: Dictionary = bootstrap_graph.deliver_structure_material(str(archive_blueprint["id"]), str(material_id), int({"wood": 8, "stone": 8, "plank": 3}[material_id]))
		assert(not archive_frame.is_empty())
	assert(str(bootstrap_graph.structures[archive_blueprint["id"]]["state"]) == "building")
	for archive_day in 3:
		bootstrap_graph.advance_day(bootstrap_graph.day + 1)
	assert(str(bootstrap_graph.structures[archive_blueprint["id"]]["state"]) == "operational")
	assert(bool(bootstrap_graph.built["library"]))
	assert(bootstrap_graph.record_discovery("Whisperglass"))
	assert(bootstrap_graph.research_discovery("Whisperglass"))
	bootstrap_graph.advance_day(bootstrap_graph.day + 1)
	assert(bootstrap_graph.claim_research())
	assert(bootstrap_graph.blueprints.has("Whisperglass Tonic"))
	assert(bootstrap_graph.has_structure_blueprint("livestock_pen"))
	# A finished Storage Shed is a real expedition upgrade, not a decorative
	# prop: it expands the satchel and lets the player bring a longer outing home.
	var storage_session := SessionScript.new()
	storage_session.save_slot = "qa_storage_shed"
	root.add_child(storage_session)
	assert(not storage_session.can_place_structure("storage_shed", [2, 0]))
	storage_session.blueprints.append("Tideglass Compass")
	storage_session.inventory["wood"] = 10
	storage_session.inventory["stone"] = 4
	storage_session.inventory["plank"] = 3
	var storage_blueprint: Dictionary = storage_session.place_structure("storage_shed", [2, 0])
	assert(storage_blueprint["state"] == "blueprint")
	assert(storage_session.deliver_structure_material(str(storage_blueprint["id"]), "wood", 10)["state"] == "blueprint")
	assert(storage_session.deliver_structure_material(str(storage_blueprint["id"]), "stone", 4)["state"] == "blueprint")
	assert(storage_session.deliver_structure_material(str(storage_blueprint["id"]), "plank", 3)["state"] == "building")
	storage_session.advance_day(storage_session.day + 1)
	assert(str(storage_session.structures[storage_blueprint["id"]]["state"]) == "building")
	storage_session.advance_day(storage_session.day + 1)
	assert(str(storage_session.structures[storage_blueprint["id"]]["state"]) == "operational")
	assert(storage_session.cargo_capacity == 16)
	assert(storage_session.start_expedition("Whisperwood"))
	for cargo_index in 16:
		assert(storage_session.collect_expedition_resource("storage-cargo-%d" % cargo_index, "wood", 1))
	assert(not storage_session.collect_expedition_resource("storage-cargo-overflow", "wood", 1))
	# Research is the authority for the tonic recipe; hiding the button alone is
	# not enough because commands can be called by other input paths.
	var locked_recipe := SessionScript.new()
	locked_recipe.save_slot = "qa_locked_recipe"
	root.add_child(locked_recipe)
	locked_recipe.built["workshop"] = true
	locked_recipe.inventory["berries"] = 1
	locked_recipe.inventory["water"] = 1
	locked_recipe.inventory["slime_gel"] = 1
	assert(locked_recipe.start_workshop_job("tonic").is_empty())
	locked_recipe.unlocked_features.append("tonic_recipe")
	assert(not locked_recipe.start_workshop_job("tonic").is_empty())
	# Mastery crosses into permissions that change authoritative rules, rather
	# than remaining a display-only number.
	var permissions := SessionScript.new()
	permissions.save_slot = "qa_mastery_permissions"
	root.add_child(permissions)
	var unlocks: Array[Dictionary] = []
	permissions.feedback_requested.connect(func(kind: String, payload: Dictionary) -> void:
		if kind == "mastery_unlock":
			unlocks.append(payload)
		)
	permissions.unlocked_features = []
	permissions.equipment["hatchet"]["max_durability"] = 19
	permissions.equipment["hatchet"]["durability"] = 0
	permissions.inventory["plank"] = 4
	permissions.masteries["Crafting"] = 0
	assert(permissions.repair_tool("hatchet"))
	assert(not permissions.has_permission("field_repair"))
	permissions.equipment["hatchet"]["durability"] = 0
	permissions.masteries["Crafting"] = 19
	permissions.award_mastery("Crafting", 1)
	assert(permissions.has_permission("field_repair"))
	assert(unlocks.size() == 1)
	assert(permissions.unlocked_features.has("field_repair"))
	permissions.inventory["plank"] = 3
	permissions.equipment["hatchet"]["durability"] = 0
	assert(permissions.repair_tool("hatchet"))
	assert(permissions.inventory["plank"] == 0)
	permissions.masteries["Trading"] = 19
	permissions.award_mastery("Trading", 1)
	assert(permissions.has_permission("market_favor"))
	permissions.inventory["fish"] = 2
	permissions.inventory["water"] = 1
	var favored_trade: Dictionary = permissions.resolve_trade_offer("fish_basket")
	assert(favored_trade["payout"] == 35)
	permissions.masteries["Attacking"] = 19
	permissions.award_mastery("Attacking", 1)
	assert(permissions.has_permission("combat_training"))
	assert(permissions.resolve_attack_damage(9) == 11)
	assert(permissions.save_game())
	var permissions_loaded := SessionScript.new()
	permissions_loaded.save_slot = "qa_mastery_permissions"
	root.add_child(permissions_loaded)
	assert(permissions_loaded.load_game())
	assert(int(permissions_loaded.equipment["hatchet"]["max_durability"]) == 19)
	assert(permissions_loaded.has_permission("field_repair"))
	assert(permissions_loaded.has_permission("market_favor"))
	assert(permissions_loaded.has_permission("combat_training"))
	# Whisperwood now has an authoritative fork/capstone/cache arc. The branch
	# is committed once, the matching objective opens one cache, and the route
	# state survives a reload.
	var grove_route := SessionScript.new()
	grove_route.save_slot = "qa_grove_route"
	root.add_child(grove_route)
	grove_route.energy = 24
	grove_route.expedition_run = {"status": "none"}
	assert(grove_route.start_expedition("Whisperwood"))
	assert(not grove_route.commit_expedition_branch("bogus"))
	assert(grove_route.commit_expedition_branch("grove"))
	assert(not grove_route.commit_expedition_branch("clearing"))
	assert(grove_route.complete_expedition_resource("Whisperglass:route-capstone", "berries", 1, 1))
	assert(grove_route.record_discovery("Whisperglass"))
	assert(bool(grove_route.expedition_run["objective_complete"]))
	var grove_cache: Dictionary = grove_route.open_expedition_cache()
	assert(grove_cache["loot"]["berries"] == 2)
	assert(grove_cache["loot"]["fiber"] == 1)
	assert(bool(grove_route.expedition_run["shortcut_open"]))
	assert(grove_route.save_game())
	var grove_loaded := SessionScript.new()
	grove_loaded.save_slot = "qa_grove_route"
	root.add_child(grove_loaded)
	assert(grove_loaded.load_game())
	assert(grove_loaded.expedition_run["branch_id"] == "grove")
	assert(bool(grove_loaded.expedition_run["cache_claimed"]))
	assert(grove_loaded.open_expedition_cache().is_empty())
	var clearing_route := SessionScript.new()
	clearing_route.save_slot = "qa_clearing_route"
	root.add_child(clearing_route)
	clearing_route.energy = 24
	clearing_route.expedition_run = {"status": "none"}
	assert(clearing_route.start_expedition("Whisperwood"))
	assert(clearing_route.commit_expedition_branch("clearing"))
	assert(not clearing_route.expedition_run["objective_complete"])
	assert(not clearing_route.resolve_guardian_defeat("forest_slime").is_empty())
	assert(bool(clearing_route.expedition_run["objective_complete"]))
	# The Dungeon is a coin-gated fixed challenge and does not consume travel energy.
	var dungeon := SessionScript.new()
	dungeon.save_slot = "qa_dungeon"
	root.add_child(dungeon)
	dungeon.get("unlocked_routes").clear()
	for route_id in all_routes:
		dungeon.get("unlocked_routes").append(route_id)
	dungeon.energy = 24
	dungeon.coins = 50
	assert(dungeon.start_expedition("Sunken Dungeon"))
	assert(dungeon.energy == 24)
	assert(dungeon.coins == 20)
	assert(dungeon.finish_expedition().is_empty())
	# Sanctuary depletion survives a restart and resets only through the daily
	# Sanctuary reset, not through saving or loading.
	var sanctuary := SessionScript.new()
	sanctuary.save_slot = "qa_sanctuary"
	root.add_child(sanctuary)
	assert(sanctuary.mark_sanctuary_depleted("Sanctuary:wood:stable"))
	assert(sanctuary.save_game())
	var sanctuary_loaded := SessionScript.new()
	sanctuary_loaded.save_slot = "qa_sanctuary"
	root.add_child(sanctuary_loaded)
	assert(sanctuary_loaded.load_game())
	assert(sanctuary_loaded.is_sanctuary_depleted("Sanctuary:wood:stable"))
	assert(sanctuary_loaded.record_sanctuary_contact("Sanctuary:wood:partial", 1))
	sanctuary_loaded.advance_day(sanctuary_loaded.day + 1)
	assert(not sanctuary_loaded.is_sanctuary_depleted("Sanctuary:wood:stable"))
	assert(not sanctuary_loaded.sanctuary_contact_progress.has("Sanctuary:wood:partial"))
	var reset_day := sanctuary_loaded.day
	sanctuary_loaded.advance_day(reset_day)
	assert(sanctuary_loaded.day == reset_day)
	sanctuary_loaded.restore_sanctuary_resources()
	assert(not sanctuary_loaded.is_sanctuary_depleted("Sanctuary:wood:stable"))
	assert(sanctuary_loaded.record_sanctuary_contact("Sanctuary:TestTree", 2))
	assert(sanctuary_loaded.save_game())
	var sanctuary_progress_loaded := SessionScript.new()
	sanctuary_progress_loaded.save_slot = "qa_sanctuary"
	root.add_child(sanctuary_progress_loaded)
	assert(sanctuary_progress_loaded.load_game())
	assert(int(sanctuary_progress_loaded.sanctuary_contact_progress.get("Sanctuary:TestTree", 0)) == 2)
	print("SESSION_TESTS_PASS")
	quit()
