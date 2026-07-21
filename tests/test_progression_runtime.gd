extends SceneTree

const SessionScript = preload("res://scripts/game_session.gd")
const ContentRegistry = preload("res://scripts/content_registry.gd")

var failures: Array[String] = []
var checks_run := 0
var unique_save_slot := ""

func _init() -> void:
	unique_save_slot = "qa_progression_runtime_%d_%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_msec()]
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	checks_run += 1
	if condition:
		return true
	failures.append(message)
	push_error("PROGRESSION_RUNTIME_FAIL: " + message)
	return false

func _fresh_session() -> Node:
	var session: Node = SessionScript.new()
	session.save_slot = unique_save_slot
	root.add_child(session)
	return session

func _install_operational_workshop(session: Node) -> void:
	var structure_id := "workshop_001"
	session.structures[structure_id] = {"id": structure_id, "kind": "workshop", "cell": [3, 9], "rotation": 0, "state": "operational", "remaining_hours": 0.0, "total_hours": 36.0, "delivered_materials": {"wood": 12, "stone": 8}}
	session.interior_stations[structure_id] = {"workbench_legacy": {"id": "workbench_legacy", "structure_id": structure_id, "kind": "workbench", "cell": [-2, -1], "rotation": 0, "state": "operational", "remaining_hours": 0.0, "total_hours": 12.0, "delivered_materials": {"wood": 4, "stone": 2}}}
	session.call("_recalculate_structure_effects")

func _reset_progression_state(session: Node) -> void:
	session.day = 1
	session.hour = 10.0
	session.energy = session.max_energy
	session.health = 50
	session.max_health = 100
	session.coins = 0
	session.xp = 0
	session.level = 1
	session.ability_points = 0
	session.stats = {
		"Strength": 1,
		"Agility": 1,
		"Focus": 1,
		"Wisdom": 1,
		"Spirituality": 1,
		"Perception": 1,
		"Resilience": 1,
	}
	session.activity_minutes_total = 0
	session.activity_stat_gains = {
		"Strength": 0,
		"Agility": 0,
		"Focus": 0,
		"Wisdom": 0,
		"Spirituality": 0,
		"Perception": 0,
		"Resilience": 0,
	}
	session.activity_receipts.clear()
	session.activity_events.clear()
	session.activity_cursor = ""
	session.activity_last_manual_epoch = 0
	session.unlocked_features.clear()
	session.translated_inscriptions.clear()
	session.tracked_wildlife.clear()
	for mastery_name in ContentRegistry.mastery_ids():
		session.masteries[mastery_name] = 0
	session.call("_recalculate_stat_derived_state")

func _test_activity_progression(session: Node) -> void:
	_check(not session.record_activity("", 25), "blank activity receipts are rejected")
	_check(not session.record_activity("qa-invalid-zero", 0), "zero-minute activity is rejected")
	_check(not session.record_activity("qa-invalid-overflow", 1441), "activity above the daily limit is rejected")
	_check(not session.record_activity("qa-invalid-source", 10, {"source_id": "", "event_id": "invalid", "timezone": "UTC"}), "empty activity source is rejected")
	_check(not session.record_activity("qa-invalid-provider", 10, {"source_id": "calendar_sync", "event_id": "provider-event", "timezone": "UTC", "payload_hash": "provider-hash", "category": "planning"}), "untrusted external activity providers are rejected")
	_check(not session.record_activity("qa-forged-ui", 25, {"source_id": "manual_ui", "event_id": "forged-ui", "timezone": "UTC", "payload_hash": "forged", "category": "planning"}), "release activity rejects an unverified UI receipt")
	_check(session.activity_events.is_empty(), "rejected activities do not create events")

	var first_metadata := {
		"source_id": "manual_ui",
		"event_id": "focus-001",
		"occurred_at": "2026-07-19T10:00:00Z",
		"timezone": "Asia/Singapore",
		"mapping_version": 1,
		"payload_hash": "qa-hash-focus-001",
		"category": "planning",
		"debug_adapter": "activity_test_v1",
	}
	_check(session.record_activity("qa-activity-receipt-001", 25, first_metadata), "first valid activity is accepted")
	_check(session.activity_minutes_total == 25, "accepted activity advances total minutes")
	_check(session.xp == 2, "25 minutes award the bounded XP reward")
	_check(session.coins == 1, "25 minutes award the bounded coin reward")
	_check(session.health == 51, "25 minutes award the bounded health reward")
	_check(session.ability_points == 0, "activity below the first AP milestone awards no AP")
	_check(session.activity_events.size() == 1, "accepted activity creates exactly one event")
	if session.activity_events.size() == 1:
		var first_event: Dictionary = session.activity_events[0]
		_check(str(first_event.get("event_id", "")) == "focus-001", "activity event keeps the source event identity")
		_check(str(first_event.get("timezone", "")) == "Asia/Singapore", "activity event keeps the supplied timezone")
		_check(str(first_event.get("stat_id", "")) == "Focus", "planning activity maps to Focus")
		_check(str(first_event.get("mastery_id", "")) == "Research", "planning activity maps to Research mastery")
		var first_awards: Dictionary = first_event.get("awards", {})
		_check(int(first_awards.get("xp", -1)) == 2, "activity event persists its XP award")
		_check(int(first_awards.get("coins", -1)) == 1, "activity event persists its coin award")

	var duplicate_receipt_metadata := first_metadata.duplicate(true)
	duplicate_receipt_metadata["event_id"] = "focus-002"
	_check(not session.record_activity("qa-activity-receipt-001", 25, duplicate_receipt_metadata), "a reused receipt cannot pay a second time")
	var duplicate_event_metadata := first_metadata.duplicate(true)
	_check(not session.record_activity("qa-activity-receipt-002", 25, duplicate_event_metadata), "a reused source event cannot pay through a new receipt")
	_check(session.activity_minutes_total == 25 and session.activity_events.size() == 1, "deduplication is side-effect free")

	var second_metadata := {
		"source_id": "manual_ui",
		"event_id": "focus-002",
		"occurred_at": "2026-07-19T10:25:00Z",
		"timezone": "Asia/Singapore",
		"mapping_version": 1,
		"payload_hash": "qa-hash-focus-002",
		"category": "planning",
		"debug_adapter": "activity_test_v1",
	}
	session.activity_last_manual_epoch = 0
	_check(session.record_activity("qa-activity-receipt-002", 35, second_metadata), "second distinct activity is accepted")
	_check(session.activity_minutes_total == 60, "activity total accumulates accepted minutes only")
	_check(session.xp == 5, "activity XP rewards accumulate exactly")
	_check(session.coins == 3, "activity coin rewards accumulate exactly")
	_check(session.health == 52, "activity health rewards accumulate exactly")
	_check(session.ability_points == 1, "crossing 60 minutes grants exactly one AP")
	_check(int(session.activity_stat_gains.get("Focus", -1)) == 2, "crossing 30 and 60 minutes grants two Focus gains")
	_check(int(session.stats.get("Focus", -1)) == 3, "activity stat gains update the authoritative stat value")
	_check(int(session.masteries.get("Research", -1)) == 5, "activity mastery rewards accumulate exactly")
	_check(session.activity_events.size() == 2, "only distinct activities remain persisted")
	if session.activity_events.size() == 2:
		var second_event: Dictionary = session.activity_events[1]
		var second_awards: Dictionary = second_event.get("awards", {})
		_check(int(second_awards.get("ability_points", -1)) == 1, "milestone AP is persisted in the event award bundle")
		var stat_awards: Dictionary = second_awards.get("stat", {})
		_check(int(stat_awards.get("Focus", -1)) == 2, "milestone stat gains are persisted in the event award bundle")

	var manual_metadata := first_metadata.duplicate(true)
	manual_metadata["source_id"] = "manual_ui"
	manual_metadata["event_id"] = "manual-focus-001"
	session.activity_last_manual_epoch = 0
	_check(session.record_activity("qa-manual-receipt-001", 25, manual_metadata), "the manual activity bridge accepts its first receipt")
	_check(session.manual_activity_cooldown_remaining() > 0, "manual activity exposes its persisted cooldown")
	manual_metadata["event_id"] = "manual-focus-002"
	_check(not session.record_activity("qa-manual-receipt-002", 25, manual_metadata), "manual activity is rate-limited across distinct receipts")

	# The release bridge owns both the receipt capability and monotonic elapsed
	# time. A caller-supplied elapsed_seconds/token cannot mint a timer receipt.
	session.activity_last_manual_epoch = 0
	session.set("activity_last_manual_ticks_msec", 0)
	_check(session.start_manual_activity("focused_work"), "local effort timer starts once the cooldown is clear")
	var timer_state: Dictionary = session.manual_activity_status()
	var timer_receipt := str(timer_state.get("receipt_id", ""))
	var forged_timer := {"source_id": "manual_timer", "event_id": timer_receipt, "occurred_at": Time.get_datetime_string_from_system(true), "timezone": "local", "payload_hash": "manual_timer_v1:%s:%d" % [timer_receipt, int(timer_state.get("started_epoch", 0))], "mapping_version": 1, "category": "focused_work", "verification": "elapsed_timer_v1", "verification_token": "forged", "started_epoch": int(timer_state.get("started_epoch", 0)), "elapsed_seconds": 1500, "duration_seconds": 1500}
	_check(not session.record_activity(timer_receipt, 25, forged_timer), "forged timer capability is rejected")
	session.set("manual_activity_started_ticks_msec", Time.get_ticks_msec() - 1500001)
	var completed_timer: Dictionary = session.complete_manual_activity()
	_check(not completed_timer.is_empty(), "monotonic timer completion produces the verified receipt")

func _test_stat_effects(session: Node) -> void:
	session.stats = {
		"Strength": 1,
		"Agility": 1,
		"Focus": 1,
		"Wisdom": 1,
		"Spirituality": 1,
		"Perception": 1,
		"Resilience": 1,
	}
	session.max_health = 100
	session.health = 100
	session.call("_recalculate_stat_derived_state")
	var base_attack: int = int(session.calculate_attack_damage(10))
	var base_speed: float = float(session.movement_speed(5.2))
	var base_dodge: float = float(session.dodge_cooldown_seconds())
	var base_windup: float = float(session.action_windup_seconds(0.12))
	var base_attack_cooldown: float = float(session.attack_cooldown_seconds())
	var base_gathering: float = float(session.gathering_duration_seconds(0.58))
	var base_range: float = float(session.interaction_range(2.35))
	var base_food: int = int(session.food_health_gain(18))
	var base_health: int = int(session.max_health)

	session.stats = {
		"Strength": 5,
		"Agility": 5,
		"Focus": 5,
		"Wisdom": 5,
		"Spirituality": 5,
		"Perception": 5,
		"Resilience": 5,
	}
	session.call("_recalculate_stat_derived_state")
	_check(session.calculate_attack_damage(10) > base_attack, "Strength increases attack damage")
	_check(session.movement_speed(5.2) > base_speed, "Agility increases movement speed")
	_check(session.dodge_cooldown_seconds() < base_dodge, "Agility reduces dodge cooldown")
	_check(session.action_windup_seconds(0.12) < base_windup, "Focus reduces action wind-up")
	_check(session.attack_cooldown_seconds() < base_attack_cooldown, "Focus reduces attack cooldown")
	_check(session.gathering_duration_seconds(0.58) < base_gathering, "Focus reduces gathering duration")
	_check(session.research_duration_hours() < 18.0, "Wisdom continuously shortens research elapsed hours")
	_check(session.food_health_gain(18) > base_food, "Spirituality increases restorative food gain")
	_check(session.interaction_range(2.35) > base_range, "Perception increases interaction range")
	_check(session.max_health > base_health and session.max_health == 120, "Resilience increases maximum health by five per point above base")
	_check(session.health == session.max_health, "Resilience recalculation preserves the gained health capacity")

func _test_research_briefing() -> void:
	var research_session := _fresh_session()
	_reset_progression_state(research_session)
	research_session.built["library"] = true
	research_session.inventory["water"] = 3
	for discovery_id in ["Whisperglass", "Tideglass", "Aether Relic"]:
		research_session.discovered.append(discovery_id)
		research_session.award_mastery("Research", 4)
		_check(research_session.research_discovery(discovery_id), "Archive accepts the discovered %s lead" % discovery_id)
		research_session.advance_game_clock(24.0)
		_check(str(research_session.research_job.get("status", "")) == "ready", "%s research becomes ready on elapsed hours" % discovery_id)
		_check(research_session.claim_research(), "%s research can be claimed" % discovery_id)
	var research_points := int(research_session.masteries.get("Research", 0))
	_check(research_points == 72, "completed studies follow the 24/48/72 Research mastery curve")
	_check(research_session.has_permission("research_margin_notes"), "first research tier is active")
	_check(research_session.has_permission("research_cross_reference"), "Cross Reference unlocks before the final discovery")
	_check(research_session.has_permission("research_breakthrough"), "Practical Breakthrough unlocks at the third study")
	_check(research_session.research_clues.size() == 1, "Cross Reference reveals one unresolved field briefing")
	if research_session.research_clues.size() == 1:
		_check(str(research_session.research_clues[0].get("destination_id", "")) == "Sunken Dungeon", "field briefing names its destination")
		_check(str(research_session.research_clues[0].get("branch_id", "")) == "vault", "field briefing names its authored route branch")

func _test_legacy_activity_migration(session: Node) -> void:
	var legacy_payload: Dictionary = session.call("_to_dict")
	legacy_payload["save_version"] = 9
	legacy_payload["activity_events"] = [{
			"receipt_id": "legacy-receipt-001",
			"event_id": "legacy-event-001",
			"source_id": "manual_ui",
			"occurred_at": "legacy",
			"timezone": "UTC",
			"payload_hash": "",
			"mapping_version": 1,
			"minutes": 25,
	}]
	for legacy_key in ["activity_receipts", "activity_cursor", "activity_minutes_total", "activity_stat_gains", "activity_stat_minutes", "activity_last_manual_epoch"]:
		legacy_payload.erase(legacy_key)
	var migrated: Dictionary = session.call("_migrate_payload", legacy_payload)
	_check(str(migrated.get("save_version", "")) == "25", "legacy activity migration upgrades the save version")
	var migrated_events: Array = migrated.get("activity_events", [])
	if migrated_events.size() == 1:
		_check(not str((migrated_events[0] as Dictionary).get("payload_hash", "")).is_empty(), "legacy empty payload hashes are normalized")
	_check(bool(session.call("_save_shape_is_supported", migrated)), "a representative v9 activity save remains loadable")

func _test_mastery_permissions(session: Node) -> void:
	for mastery_name in ContentRegistry.mastery_ids():
		session.masteries[mastery_name] = 100
	session.unlocked_features.clear()
	var newly_unlocked: Array = session.call("_sync_mastery_permissions")
	_check(newly_unlocked.size() == 48, "all 48 mastery tiers grant permissions at the cap")
	_check(session.unlocked_features.size() == 48, "all 48 mastery features are present exactly once")
	var seen_features: Dictionary = {}
	for mastery_name in ContentRegistry.mastery_ids():
		var tiers: Array = ContentRegistry.mastery_tiers(mastery_name)
		_check(tiers.size() == 4, "%s contributes four mastery permissions" % mastery_name)
		for tier_value in tiers:
			var tier: Dictionary = tier_value
			var feature := str(tier.get("feature", ""))
			_check(not seen_features.has(feature), "mastery permission features remain globally unique: %s" % feature)
			seen_features[feature] = true
			_check(session.has_permission(feature), "unlocked mastery feature is authoritative: %s" % feature)
	_check(seen_features.size() == 48, "the runtime integration covers exactly 48 unique features")
	_check(str(session.mastery_tier("Farming").get("tier", "")) == "Platinum", "Farming resolves to Platinum at 100 points")
	_check(session.call("_sync_mastery_permissions").is_empty(), "mastery synchronization is idempotent")

func _test_deterministic_chance_rolls(session: Node) -> void:
	var action_id := "qa-chance-action-001"
	var first_result: bool = session.resolve_mastery_chance("farming_seed_saver", "seed_refund_chance", action_id)
	_check(first_result == session.resolve_mastery_chance("farming_seed_saver", "seed_refund_chance", action_id), "a chance effect is idempotent within one action")
	_check(session.chance_rolls.size() == 1, "one authoritative chance action persists one roll")
	var snapshot: Dictionary = session.call("_to_dict")
	var incomplete_current: Dictionary = snapshot.duplicate(true)
	incomplete_current.erase("chance_rolls")
	_check(not session.call("_save_shape_is_supported", incomplete_current), "current-version saves cannot omit chance history")
	var reloaded: Node = SessionScript.new()
	reloaded.call("_apply_dict", snapshot)
	_check(reloaded.resolve_mastery_chance("farming_seed_saver", "seed_refund_chance", action_id) == first_result, "a chance result survives save/load")
	_check(reloaded.chance_rolls.size() == session.chance_rolls.size(), "chance roll history survives save/load")
	_check(not session.resolve_mastery_chance("farming_seed_saver", "seed_refund_chance", ""), "blank chance action ids cannot mint a roll")
	_check(not session.resolve_mastery_chance("unknown_feature", "seed_refund_chance", "qa-unknown"), "unknown chance permissions cannot mint a roll")

func _test_playable_mastery_effects() -> void:
	# Seasonal pressure is evaluated from the previous day state before the
	# calendar rolls forward. Without Steward, a watered crop loses its entire
	# growth step in the two harsh seasons; with the permission, it still grows.
	var plain_farm: Node = SessionScript.new()
	root.add_child(plain_farm)
	plain_farm.day = 1
	plain_farm.last_day_transaction = 0
	plain_farm.season = "Frostveil"
	plain_farm.farm_plot = {"state": "planted", "crop": "wheat", "growth": 0, "watered": true}
	_check(plain_farm.advance_day(2), "a harsh-season day advances once")
	_check(int(plain_farm.farm_plot.get("growth", -1)) == 0, "harsh-season crop pressure is authoritative before Steward")

	var steward_farm: Node = SessionScript.new()
	root.add_child(steward_farm)
	steward_farm.day = 1
	steward_farm.last_day_transaction = 0
	steward_farm.season = "Frostveil"
	steward_farm.farm_plot = {"state": "planted", "crop": "wheat", "growth": 0, "watered": true}
	steward_farm.masteries["Farming"] = 95
	steward_farm.call("_sync_mastery_permissions")
	_check(steward_farm.has_permission("farming_verdant_steward"), "Verdant Steward unlocks at the Platinum threshold")
	_check(steward_farm.advance_day(2), "Steward farm advances once")
	_check(int(steward_farm.farm_plot.get("growth", -1)) == 1, "Verdant Steward preserves a harsh-season crop growth step")

	# Deep seams are authored runtime instances. Collection rejects the seam
	# before the permission, then resolves the extra unit in the same harvest
	# transaction after Deep Delver is earned.
	var mine: Node = SessionScript.new()
	root.add_child(mine)
	mine.day = 1
	mine.energy = mine.max_energy
	mine.coins = 1000
	var mine_routes: Array = mine.get("unlocked_routes")
	mine_routes.clear()
	for route_id in ["Whisperwood", "Sunlit Beach", "Ember Ridge", "Glass Desert", "Sunken Dungeon"]:
		mine_routes.append(route_id)
	_check(mine.register_resource_node("qa-deep-seam", "Sunken Dungeon", "ore", 2, 1, "", null, "deep"), "authored deep seam registers with its grade")
	_check(not mine.can_access_resource_node("qa-deep-seam"), "deep seam remains closed before Deep Delver")
	var unknown_guidance: Dictionary = mine.resource_node_guidance("qa-deep-seam", 2.0)
	_check(not bool(unknown_guidance.get("grade_known", false)), "Vein Reader keeps an unearned seam grade unknown")
	_check(mine.start_expedition("Sunken Dungeon"), "test mine expedition starts")
	_check(not mine.collect_expedition_resource("qa-deep-seam", "ore", 2), "closed deep seam cannot mint ore")
	mine.masteries["Mining"] = 95
	mine.call("_sync_mastery_permissions")
	_check(mine.has_permission("mining_deep_delver"), "Deep Delver unlocks at the Platinum threshold")
	_check(mine.has_permission("mining_vein_reader"), "Vein Reader unlocks with the same mining mastery")
	var known_guidance: Dictionary = mine.resource_node_guidance("qa-deep-seam", 2.0)
	_check(bool(known_guidance.get("grade_known", false)) and str(known_guidance.get("resource_grade", "")) == "deep", "Vein Reader reveals a nearby deep grade")
	_check(mine.collect_expedition_resource("qa-deep-seam", "ore", 2), "Deep Delver opens the authored seam")
	_check(int(mine.expedition_run.get("cargo", {}).get("ore", 0)) >= 3, "Deep Delver resolves its rare-seam bonus in the harvest transaction")

	# Tide Reader is a real expedition fishing loop. The coastal spot remains
	# route-bound, while the permission converts a favorable tide roll into a
	# persisted uncommon shell that is paid only on claim.
	var coastal: Node = SessionScript.new()
	root.add_child(coastal)
	coastal.coins = 1000
	coastal.energy = coastal.max_energy
	coastal.inventory["fiber"] = 1
	coastal.unlocked_routes.append("Sunlit Beach")
	_check(coastal.start_expedition("Sunlit Beach"), "Sunlit Beach opens the coastal fishing run")
	_check(coastal.begin_fishing("sunlit_tidepool", "Sunlit Beach", [-2.0, 1.0, -6.25]).is_empty(), "coastal fishing rejects an out-of-radius cast")
	coastal.masteries["Fishing"] = 70
	coastal.call("_sync_mastery_permissions")
	_check(coastal.has_permission("fishing_tide_reader"), "Tide Reader unlocks the coastal catch signal")
	var coastal_start: Dictionary = coastal.begin_fishing("sunlit_tidepool", "Sunlit Beach", [2.5, 1.0, -6.25])
	_check(str(coastal_start.get("phase", "")) == "waiting", "the tidepool consumes bait through the authored cast phase")
	var coastal_attempt_id := str(coastal.fishing_attempt.get("attempt_id", ""))
	coastal.chance_rolls["fishing_tide_reader|uncommon_catch_weight|%s" % coastal_attempt_id] = true
	var coastal_ticks := 0
	while str(coastal.fishing_attempt.get("phase", "")) == "waiting" and coastal_ticks < 30:
		coastal.advance_fishing(0.1, false)
		coastal_ticks += 1
	_check(str(coastal.fishing_attempt.get("phase", "")) == "bite", "the coastal tidepool exposes its bite window")
	coastal.press_fishing_action(coastal_attempt_id)
	var coastal_reel_ticks := 0
	while coastal.has_active_fishing() and coastal_reel_ticks < 40:
		coastal.advance_fishing(0.15, coastal_reel_ticks % 2 == 0)
		coastal_reel_ticks += 1
	_check(str(coastal.fishing_attempt.get("status", "")) == "landed", "the coastal catch reaches a claimable landing")
	var shell_before_tide := int(coastal.inventory.get("shell", 0))
	var coastal_claim: Dictionary = coastal.claim_fishing()
	_check(int(coastal_claim.get("amount", 0)) >= 1, "the coastal fishing claim pays fish")
	_check(bool(coastal_claim.get("uncommon_catch", false)) and int(coastal_claim.get("bonus_resource_amount", 0)) == 1, "Tide Reader turns the favorable roll into one uncommon shell")
	_check(int(coastal.inventory.get("shell", 0)) == shell_before_tide + 1, "the uncommon shell is paid atomically with the fishing claim")

	# Crafting tiers now change a real Workshop output. Quality Work restores a
	# reinforced hatchet above its old durability, while Masterwork Bench exposes
	# a separate pickaxe recipe and keeps the same elapsed job/claim boundary.
	var crafter: Node = SessionScript.new()
	root.add_child(crafter)
	_install_operational_workshop(crafter)
	crafter.masteries["Crafting"] = 70
	crafter.call("_sync_mastery_permissions")
	crafter.inventory["plank"] = 2
	crafter.inventory["ore"] = 1
	var hatchet_before := int(crafter.equipment["hatchet"].get("max_durability", 0))
	_check(crafter.start_workshop_job("masterwork_pickaxe").is_empty(), "Masterwork recipes stay closed before the Platinum tier")
	var reinforced_job: Dictionary = crafter.start_workshop_job("reinforced_hatchet")
	_check(str(reinforced_job.get("output_kind", "")) == "tool" and str(reinforced_job.get("tool_id", "")) == "hatchet", "Quality Work starts an authored reinforced tool job")
	_check(crafter.advance_day(2), "the reinforced tool advances through its first workshop day")
	_check(crafter.advance_day(3), "the reinforced tool advances through its second workshop day")
	var reinforced_claim: Dictionary = crafter.claim_workshop_job()
	_check(str(reinforced_claim.get("tool_id", "")) == "hatchet" and int(reinforced_claim.get("max_durability", 0)) > hatchet_before, "Quality Work claims a higher-durability hatchet")
	crafter.masteries["Crafting"] = 95
	crafter.call("_sync_mastery_permissions")
	crafter.inventory["plank"] = 3
	crafter.inventory["ore"] = 2
	crafter.inventory["sunstone"] = 1
	var masterwork_job: Dictionary = crafter.start_workshop_job("masterwork_pickaxe")
	_check(str(masterwork_job.get("tool_id", "")) == "pickaxe", "Masterwork Bench exposes the pickaxe job")
	_check(crafter.advance_day(4), "the masterwork job advances through its first day")
	_check(crafter.advance_day(5), "the masterwork job advances through its second day")
	var masterwork_claim: Dictionary = crafter.claim_workshop_job()
	_check(str(masterwork_claim.get("output_kind", "")) == "tool" and int(masterwork_claim.get("max_durability", 0)) >= 22, "Masterwork Bench claims the upgraded pickaxe")
	var forged_station_payload: Dictionary = crafter.call("_to_dict")
	var forged_station: Dictionary = forged_station_payload.get("station_job", {}).duplicate(true)
	forged_station["kind"] = "reinforced_hatchet"
	forged_station["output_id"] = "reinforced_hatchet"
	forged_station["output"] = 1
	forged_station["output_kind"] = "tool"
	forged_station["tool_id"] = "forged_tool"
	forged_station["remaining_hours"] = 0
	forged_station["total_hours"] = 18
	forged_station_payload["station_job"] = forged_station
	_check(not crafter.call("_save_shape_is_supported", forged_station_payload), "unknown crafted tools cannot enter a save")

	# Sanctuary Breeder is a care loop, not an instant trait flag. Four feed/
	# sleep cycles nurture Clover's authored Sunplume trait, which then pays one
	# extra egg in the same collection transaction.
	var breeder: Node = SessionScript.new()
	root.add_child(breeder)
	breeder.built["livestock_pen"] = true
	breeder.masteries["Livestock"] = 95
	breeder.call("_sync_mastery_permissions")
	breeder.inventory["wheat"] = 4
	breeder.livestock["clover"]["hunger"] = 65
	_check(breeder.has_permission("livestock_sanctuary_breeder"), "Sanctuary Breeder unlocks the trait nurture loop")
	for cycle in 4:
		_check(breeder.feed_livestock("clover"), "Clover accepts a safe breeder feed cycle %d" % (cycle + 1))
		_check(breeder.advance_day(breeder.day + 1), "Clover's feed cycle advances through dawn %d" % (cycle + 1))
	var bred_animal: Dictionary = breeder.livestock["clover"]
	_check(str(bred_animal.get("trait_id", "")) == "sunplume" and int(bred_animal.get("trait_progress", 0)) == 100, "four safe feeds nurture Clover's Sunplume trait")
	_check(bool(bred_animal.get("production_ready", false)), "the trait-ready animal produces after its dawn cycle")
	var eggs_before_trait := int(breeder.inventory.get("egg", 0))
	var trait_collection: Dictionary = breeder.collect_livestock("clover")
	_check(int(trait_collection.get("egg", 0)) >= 2 and int(breeder.inventory.get("egg", 0)) == eggs_before_trait + int(trait_collection.get("egg", 0)), "Sunplume pays its extra egg atomically")
	var breeder_reload := SessionScript.new()
	breeder_reload.call("_apply_dict", breeder.call("_to_dict"))
	_check(str(breeder_reload.livestock["clover"].get("trait_id", "")) == "sunplume", "livestock traits survive state reload")
	var forged_livestock_payload: Dictionary = breeder.call("_to_dict")
	var forged_animal: Dictionary = forged_livestock_payload.get("livestock", {}).get("clover", {}).duplicate(true)
	forged_animal["trait_id"] = "forged_trait"
	forged_animal["trait_progress"] = 100
	forged_livestock_payload["livestock"]["clover"] = forged_animal
	_check(not breeder.call("_save_shape_is_supported", forged_livestock_payload), "unknown livestock traits cannot enter a save")

	# Language is a physical expedition loop. The authored plaque stays in the
	# route, branch selection is required, and Context Reader/World Polyglot
	# determine which inscriptions can be translated. A translation is a
	# one-time persisted reward rather than a repeatable menu payout.
	var translator: Node = SessionScript.new()
	root.add_child(translator)
	translator.coins = 1000
	translator.energy = translator.max_energy
	_check(translator.start_expedition("Whisperwood"), "a translator can enter the authored forest route")
	_check(translator.commit_expedition_branch("grove"), "a translator can commit the inscription's branch")
	_check(translator.expedition_inscription_status("whisperwood_root_oath").get("reason", "") == "language_locked", "an untranslated plaque stays locked before Context Reader")
	_check(translator.read_expedition_inscription("whisperwood_root_oath").is_empty(), "a language-locked inscription cannot mint rewards")
	translator.masteries["Language"] = 45
	translator.call("_sync_mastery_permissions")
	var root_translation: Dictionary = translator.read_expedition_inscription("whisperwood_root_oath")
	_check(not root_translation.is_empty() and str(root_translation.get("translation", "")).contains("living root"), "Context Reader translates a physical route inscription")
	_check(translator.read_expedition_inscription("whisperwood_root_oath").is_empty(), "a translated inscription cannot pay twice")
	_check(translator.read_expedition_inscription("sunlit_tide_vow").is_empty(), "an inscription on another expedition cannot be read in the current route")
	var translated_save: Dictionary = translator.call("_to_dict")
	var translated_reload: Node = SessionScript.new()
	translated_reload.call("_apply_dict", translated_save)
	_check(translated_reload.translated_inscriptions.has("whisperwood_root_oath"), "translated lore survives state reload")
	var forged_translation_payload: Dictionary = translator.call("_to_dict")
	forged_translation_payload["translated_inscriptions"] = ["forged_inscription"]
	_check(not translator.call("_save_shape_is_supported", forged_translation_payload), "unknown translated lore cannot enter a save")

	var polyglot: Node = SessionScript.new()
	root.add_child(polyglot)
	polyglot.coins = 1000
	polyglot.energy = polyglot.max_energy
	polyglot.unlocked_routes.append("Sunken Dungeon")
	_check(polyglot.start_expedition("Sunken Dungeon"), "a polyglot can enter the authored dungeon route")
	_check(polyglot.commit_expedition_branch("vault"), "a polyglot can commit the ancient inscription's branch")
	polyglot.masteries["Language"] = 45
	polyglot.call("_sync_mastery_permissions")
	_check(polyglot.read_expedition_inscription("sunken_vault_verse").is_empty(), "ancient lore stays closed before World Polyglot")
	polyglot.masteries["Language"] = 95
	polyglot.call("_sync_mastery_permissions")
	var ancient_translation: Dictionary = polyglot.read_expedition_inscription("sunken_vault_verse")
	_check(int(ancient_translation.get("xp", 0)) == 21 and int(ancient_translation.get("coins", 0)) == 12, "World Polyglot applies the authored ancient-lore reward multiplier")

	var hunter: Node = SessionScript.new()
	root.add_child(hunter)
	hunter.coins = 1000
	hunter.energy = hunter.max_energy
	_check(hunter.start_expedition("Whisperwood"), "a hunter can enter the wildlife route")
	_check(hunter.wildlife_track_status("forest_rabbit").get("reason", "") == "hunting_locked", "fresh tracks stay unreadable before Track Sign")
	_check(hunter.inspect_wildlife_track("forest_rabbit").is_empty(), "untrained tracking cannot mint a field note")
	hunter.masteries["Hunting"] = 20
	hunter.call("_sync_mastery_permissions")
	var track_note: Dictionary = hunter.inspect_wildlife_track("forest_rabbit")
	_check(str(track_note.get("direction", "")) == "northwest" and int(track_note.get("reveal_radius", 0)) == 4, "Track Sign reveals the authored wildlife direction and radius")
	_check(hunter.inspect_wildlife_track("forest_rabbit").is_empty(), "a tracked species cannot pay twice")
	hunter.masteries["Hunting"] = 70
	hunter.call("_sync_mastery_permissions")
	_check(is_equal_approx(float(hunter.permission_effect("hunting_ambush_sense", "warning_seconds", 0.0)), 1.5), "Ambush Sense exposes its authored warning window")
	var hunter_save: Dictionary = hunter.call("_to_dict")
	var hunter_reload: Node = SessionScript.new()
	hunter_reload.call("_apply_dict", hunter_save)
	_check(hunter_reload.tracked_wildlife.has("forest_rabbit"), "track notes survive state reload")
	var forged_track_payload: Dictionary = hunter.call("_to_dict")
	forged_track_payload["tracked_wildlife"] = ["forged_wildlife"]
	_check(not hunter.call("_save_shape_is_supported", forged_track_payload), "unknown track notes cannot enter a save")
	var untrained_combat: Node = SessionScript.new()
	root.add_child(untrained_combat)
	untrained_combat.energy = untrained_combat.max_energy
	var untrained_attack: Dictionary = untrained_combat.resolve_attack(7, 1, 18, false, true)
	var trained_combat: Node = SessionScript.new()
	root.add_child(trained_combat)
	trained_combat.energy = trained_combat.max_energy
	trained_combat.masteries["Hunting"] = 45
	trained_combat.call("_sync_mastery_permissions")
	var trained_attack: Dictionary = trained_combat.resolve_attack(7, 1, 18, false, true)
	_check(not bool(untrained_attack.get("clean_shot", false)) and bool(trained_attack.get("clean_shot", false)) and is_equal_approx(float(trained_attack.get("opening_stagger_multiplier", 1.0)), 1.5), "Clean Shot only amplifies the first unaware hit after the Silver tier")

	# Bazaar offers are a daily sourcing loop rather than an infinite fixed
	# payout. Appraisal and caravan permissions change what is readable and what
	# is available, while a persisted receipt prevents a duplicate trade.
	var market: Node = SessionScript.new()
	root.add_child(market)
	market.save_slot = unique_save_slot
	var offers: Array = market.market_offers()
	_check(offers.size() == 4, "a fresh Bazaar exposes the four core daily offers")
	if not offers.is_empty():
		var first_offer: Dictionary = offers[0]
		var first_id := str(first_offer.get("offer_id", ""))
		var first_cost: Dictionary = first_offer.get("cost", {})
		var market_inventory: Dictionary = market.get("inventory")
		for item_id in first_cost:
			market_inventory[str(item_id)] = int(first_cost[item_id])
		_check(not bool(first_offer.get("demand_known", false)), "offer demand stays unreadable before Appraiser's Eye")
		var first_trade: Dictionary = market.resolve_trade_offer(first_id)
		_check(not first_trade.is_empty(), "an affordable daily offer resolves")
		_check(market.resolve_trade_offer(first_id).is_empty(), "a completed offer cannot be traded twice on the same day")
		market.masteries["Trading"] = 45
		market.call("_sync_mastery_permissions")
		var appraised_offers: Array = market.market_offers()
		_check(bool(appraised_offers[0].get("demand_known", false)), "Appraiser's Eye reveals daily demand")
		market.masteries["Trading"] = 70
		market.call("_sync_mastery_permissions")
		var caravan_offers: Array = market.market_offers()
		var specialist_count := 0
		for caravan_offer_value in caravan_offers:
			if caravan_offer_value is Dictionary and not str((caravan_offer_value as Dictionary).get("specialist", "")).is_empty():
				specialist_count += 1
		_check(caravan_offers.size() == 5 and specialist_count == 1, "Caravan Contacts adds one rotating specialist offer")
		market.masteries["Trading"] = 95
		market.call("_sync_mastery_permissions")
		var guild_contract: Dictionary = market.market_contract()
		_check(not guild_contract.is_empty(), "Guild Broker exposes a daily bulk contract")
		if not guild_contract.is_empty():
			var contract_cost: Dictionary = guild_contract.get("cost", {})
			for item_id in contract_cost:
				market_inventory[str(item_id)] = int(contract_cost[item_id])
			var contract_result: Dictionary = market.resolve_trade_contract(str(guild_contract.get("contract_id", "")))
			_check(not contract_result.is_empty(), "Guild Broker settles a fully supplied bulk contract")
			_check(market.resolve_trade_contract(str(guild_contract.get("contract_id", ""))).is_empty(), "a Guild contract cannot be claimed twice in one day")
		var forged_market_payload: Dictionary = market.call("_to_dict")
		forged_market_payload["market_trades"] = {"1:forged_offer": true}
		_check(not market.call("_save_shape_is_supported", forged_market_payload), "unknown market receipts cannot enter a save")
		forged_market_payload = market.call("_to_dict")
		forged_market_payload["market_contract_claimed_day"] = 99
		_check(not market.call("_save_shape_is_supported", forged_market_payload), "impossible Guild contract receipts cannot enter a save")
		var forged_fishing_payload: Dictionary = market.call("_to_dict")
		var forged_fishing_attempt: Dictionary = forged_fishing_payload.get("fishing_attempt", {}).duplicate(true)
		forged_fishing_attempt["bonus_resource_id"] = "forged_resource"
		forged_fishing_attempt["bonus_resource_amount"] = 1
		forged_fishing_payload["fishing_attempt"] = forged_fishing_attempt
		_check(not market.call("_save_shape_is_supported", forged_fishing_payload), "unknown fishing bonus resources cannot enter a save")
		_check(market.save_game(), "daily market receipts save atomically")
		var market_loaded: Node = SessionScript.new()
		market_loaded.save_slot = unique_save_slot
		root.add_child(market_loaded)
		_check(market_loaded.load_game(), "daily market receipts reload")
		_check(market_loaded.resolve_trade_offer(first_id).is_empty(), "reloaded market receipts still block duplicate sale")
		_check(market_loaded.resolve_trade_contract(str(guild_contract.get("contract_id", ""))).is_empty(), "reloaded Guild contract receipts still block duplicate settlement")
		_check(market_loaded.advance_day(2), "market day advances through the normal sleep transaction")
		var reloaded_inventory: Dictionary = market_loaded.get("inventory")
		for item_id in first_cost:
			reloaded_inventory[str(item_id)] = int(first_cost[item_id])
		_check(not market_loaded.resolve_trade_offer(first_id).is_empty(), "the next dawn opens a fresh offer receipt")

func _remove_unique_save() -> void:
	for suffix in [".json", ".backup.json", ".tmp.json"]:
		var path := "user://%s%s" % [unique_save_slot, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _test_save_reload(session: Node) -> void:
	_check(session.save_game(), "progression state saves to a unique slot")
	var reloaded: Node = SessionScript.new()
	reloaded.save_slot = unique_save_slot
	root.add_child(reloaded)
	_check(reloaded.load_game(), "unique progression slot reloads successfully")
	_check(reloaded.activity_minutes_total == session.activity_minutes_total, "activity minute total survives reload")
	_check(reloaded.activity_stat_gains == session.activity_stat_gains, "activity stat gains survive reload")
	_check(reloaded.activity_events.size() == session.activity_events.size(), "activity event history survives reload")
	_check(int(reloaded.stats.get("Focus", -1)) == int(session.stats.get("Focus", -2)), "runtime stat values survive reload")
	_check(reloaded.max_health == session.max_health and reloaded.health == session.health, "derived health state survives reload")
	_check(reloaded.ability_points == session.ability_points and reloaded.coins == session.coins, "activity rewards survive reload")
	_check(reloaded.masteries == session.masteries, "mastery points survive reload")
	_check(reloaded.unlocked_features.size() == 48, "mastery permissions survive reload")
	_check(str(reloaded.mastery_tier("Farming").get("tier", "")) == "Platinum", "mastery tier resolution survives reload")
	if reloaded.activity_events.size() >= 2:
		var reloaded_event: Dictionary = reloaded.activity_events[1]
		var reloaded_awards: Dictionary = reloaded_event.get("awards", {})
		_check(int(reloaded_awards.get("ability_points", -1)) == 1, "event reward bundle survives reload")
	_remove_unique_save()

func _finish() -> void:
	_remove_unique_save()
	if failures.is_empty():
		print("PROGRESSION_RUNTIME_PASS checks=%d slot=%s" % [checks_run, unique_save_slot])
		quit(0)
		return
	print("PROGRESSION_RUNTIME_FAIL count=%d checks=%d" % [failures.size(), checks_run])
	for index in failures.size():
		print("  %02d. %s" % [index + 1, failures[index]])
	quit(1)

func _run() -> void:
	var session := _fresh_session()
	_reset_progression_state(session)
	_test_activity_progression(session)
	_test_stat_effects(session)
	_test_research_briefing()
	_test_legacy_activity_migration(session)
	_test_mastery_permissions(session)
	_test_deterministic_chance_rolls(session)
	_test_playable_mastery_effects()
	_test_save_reload(session)
	_finish()
