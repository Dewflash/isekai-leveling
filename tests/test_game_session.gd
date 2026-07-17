extends SceneTree

const SessionScript = preload("res://scripts/game_session.gd")

func _init() -> void:
	var session := SessionScript.new()
	session.save_slot = "qa_session"
	root.add_child(session)
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
	session.construction_job = {"status": "building", "remaining_hours": 12.0}
	session.advance_day(3)
	assert(session.construction_job["status"] == "ready")
	assert(session.claim_construction())
	assert(bool(session.built["workshop"]))
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
	# Expedition cargo is isolated from banked inventory and survives a reload.
	var expedition := SessionScript.new()
	expedition.save_slot = "qa_expedition"
	root.add_child(expedition)
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
	var guardian_reward: Dictionary = pressure.resolve_guardian_defeat("forest_slime")
	assert(guardian_reward["reward_id"] == "slime_gel")
	assert(pressure.expedition_cargo_used() == 2)
	assert(pressure.resolve_guardian_defeat("forest_slime").is_empty())
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
	systems.inventory["wood"] = 4
	systems.inventory["fiber"] = 2
	systems.inventory["wheat"] = 1
	assert(systems.build_livestock_pen())
	assert(systems.feed_livestock("clover"))
	systems.advance_day(systems.day + 1)
	assert(bool(systems.livestock["clover"]["production_ready"]))
	assert(systems.collect_livestock("clover")["egg"] == 1)
	assert(systems.collect_livestock("clover").is_empty())
	# Placement is grid-aware, persists its footprint, and becomes useful only
	# after materials are physically delivered to the blueprint and its frame
	# construction clock completes.
	systems.structures = {}
	systems.inventory["wood"] = 8
	systems.inventory["plank"] = 2
	assert(not systems.can_place_structure("rain_cistern", [0, -4]))
	assert(not systems.can_place_structure("rain_cistern", [5, 3]))
	assert(systems.can_place_structure("rain_cistern", [11, 7]))
	var cistern: Dictionary = systems.place_structure("rain_cistern", [11, 7])
	assert(cistern["state"] == "blueprint")
	assert(int(systems.inventory["wood"]) == 8)
	assert(int(systems.inventory["plank"]) == 2)
	assert(systems.deliver_structure_material(str(cistern["id"]), "wood", 8)["state"] == "blueprint")
	var framed_cistern: Dictionary = systems.deliver_structure_material(str(cistern["id"]), "plank", 2)
	assert(framed_cistern["state"] == "building")
	assert(int(systems.inventory["wood"]) == 0)
	assert(int(systems.inventory["plank"]) == 0)
	assert(not systems.can_place_structure("rain_cistern", [8, 6]))
	systems.advance_day(systems.day + 1)
	assert(str(systems.structures[cistern["id"]]["state"]) == "building")
	systems.advance_day(systems.day + 1)
	assert(str(systems.structures[cistern["id"]]["state"]) == "operational")
	# The Dungeon is a coin-gated fixed challenge and does not consume travel energy.
	var dungeon := SessionScript.new()
	dungeon.save_slot = "qa_dungeon"
	root.add_child(dungeon)
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
