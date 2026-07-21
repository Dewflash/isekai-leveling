class_name ProdewtyGameSession
extends Node

const ContentRegistry = preload("res://scripts/content_registry.gd")
const SettlementGrid = preload("res://scripts/settlement_grid.gd")
const SanctuaryAssetCatalog = preload("res://scripts/sanctuary_asset_catalog.gd")
const InteriorGrid = preload("res://scripts/interior_grid.gd")

## The authoritative, serializable gameplay state for the expedition loop.
## Presentation nodes submit commands here through main.gd and receive signals.

signal state_changed
signal feedback_requested(kind: String, payload: Dictionary)

const SAVE_VERSION := 26
const CONTENT_VERSION := 1
const CHANCE_ROLL_VERSION := 1
const DEFAULT_WORLD_SEED := "isekai-leveling-sanctuary-v1"
const MAX_CHANCE_ROLLS := 2048
const SAVE_PATH := "user://prodewty_save.json"
const BACKUP_PATH := "user://prodewty_save.backup.json"
const TEMP_PATH := "user://prodewty_save.tmp.json"
const BASE_CARGO_CAPACITY := 12
const EXPEDITION_ANCHOR_LIMIT_X := 20.0
const EXPEDITION_ANCHOR_LIMIT_Z := 15.0
const ACTIVITY_MAX_MINUTES := 1440
const ACTIVITY_MAX_REWARD_XP := 120
const ACTIVITY_MAX_REWARD_COINS := 96
const ACTIVITY_MAX_REWARD_HEALTH := 24
const MANUAL_ACTIVITY_MIN_INTERVAL_SECONDS := 1500
const MANUAL_ACTIVITY_DURATION_SECONDS := 1500
const INVENTORY_IDS := [
	"wood", "stone", "fiber", "slime_gel", "ore", "sunstone", "relic", "berries", "shell", "fish",
	"wheat", "flour", "bread", "omelette", "tonic", "egg", "plank", "ingot", "water",
]
const EXPEDITION_ROUTE_CHECKPOINTS := ["arrival", "fork", "return"]
## Compatibility alias retained for older tests and migrated callers. The
## ordered contract now applies to every expedition, not only Whisperwood.
const WHISPERWOOD_ROUTE_CHECKPOINTS := EXPEDITION_ROUTE_CHECKPOINTS
const EXPEDITION_ROUTE_PHASES := ["none", "approach", "arrival", "fork", "branch", "objective", "capstone", "shortcut", "return"]

var day := 1
var hour := 10.0
var season := "Verdant"
var weather := "clear"
var energy := 24
var max_energy := 24
var health := 100
var max_health := 100
var cargo_capacity := 12
var coins := 120
var xp := 0
var level := 1
var ability_points := 2
var stats := {"Strength": 1, "Agility": 1, "Focus": 1, "Wisdom": 1, "Spirituality": 1, "Perception": 1, "Resilience": 1}
var masteries := {"Farming": 0, "Mining": 0, "Attacking": 0, "Foraging": 0, "Fishing": 0, "Crafting": 0, "Livestock": 0, "Language": 0, "Trading": 0, "Hunting": 0, "Surviving": 0, "Research": 0}
var inventory := {"wood": 0, "stone": 0, "fiber": 0, "slime_gel": 0, "ore": 0, "sunstone": 0, "relic": 0, "berries": 0, "shell": 0, "fish": 0, "wheat": 2, "flour": 0, "bread": 0, "omelette": 0, "tonic": 0, "egg": 0, "plank": 0, "ingot": 0, "water": 3}
var discovered: Array[String] = []
var observed_wildlife: Array[String] = []
var translated_inscriptions: Array[String] = []
var tracked_wildlife: Array[String] = []
var researched: Array[String] = []
var blueprints: Array[String] = []
var research_job := {"status": "idle", "discovery_id": "", "ready_day": 0, "remaining_hours": 0.0, "total_hours": 0.0, "action_id": "", "material_refunded": false}
var research_clues: Array[Dictionary] = []
var fishing_attempt := {"status": "idle", "phase": "idle", "attempt_id": "", "spot_id": "", "zone_id": "", "elapsed": 0.0, "bite_at": 0.0, "hook_deadline": 0.0, "reel_progress": 0.0, "tension": 0.0, "mistakes": 0, "perfect_hook": false, "catch_amount": 0, "bonus_fish": false, "uncommon_catch": false, "bonus_resource_id": "", "bonus_resource_amount": 0, "seed": 0, "reel_pulse": false}
var built := {"workshop": false, "library": false, "livestock_pen": false}
var farm_plot := {"state": "empty", "crop": "wheat", "growth": 0, "watered": false}
var station_job := {"kind": "none", "structure_id": "", "station_id": "", "remaining_hours": 0.0, "total_hours": 0.0, "output_id": "plank", "output": 0, "output_kind": "material", "tool_id": "", "quality_multiplier": 1.0, "action_id": "", "material_refunded": false}
var equipment := {
		"hatchet": {"durability": 18, "max_durability": 18, "wear_remainder": 0.0},
		"pickaxe": {"durability": 18, "max_durability": 18, "wear_remainder": 0.0},
		"fishing_knife": {"durability": 12, "max_durability": 12, "wear_remainder": 0.0},
}
var nutrition := 72
var hydration := 76
var max_nutrition := 100
var max_hydration := 100
var livestock := {
	"clover": {"species": "chicken", "name": "Clover", "hunger": 65, "health": 100, "last_fed_day": 0, "production_ready": false, "product_id": "egg", "product_amount": 1, "trait_id": "", "trait_progress": 0},
}
var unlocked_features: Array[String] = []
var unlocked_routes: Array[String] = ["Whisperwood"]
var sanctuary_depleted_ids: Array[String] = []
var sanctuary_contact_progress := {}
## Runtime-only world contract populated by the composition root. Save files do
## not own this table; the scene must re-register the authored resource nodes
## on boot before a command can resolve their identity or quantity.
var resource_node_catalog := {}
var resource_contract_required := false
var structures := {}
## structure_id -> station_instance_id -> fit-out record. A completed shell is
## enterable, but no crafting capability exists until this map contains an
## operational station. This is the save authority for interior placement.
var interior_stations := {}
var activity_receipts: Array[String] = []
var activity_events: Array[Dictionary] = []
var activity_cursor := ""
var activity_mapping_version := 1
var activity_minutes_total := 0
var activity_stat_gains := {"Strength": 0, "Agility": 0, "Focus": 0, "Wisdom": 0, "Spirituality": 0, "Perception": 0, "Resilience": 0}
var activity_stat_minutes := {"Strength": 0, "Agility": 0, "Focus": 0, "Wisdom": 0, "Spirituality": 0, "Perception": 0, "Resilience": 0}
var activity_last_manual_epoch := 0
var activity_last_manual_ticks_msec := 0
## The temporary local activity bridge uses a real elapsed-time session before
## it can submit a receipt. It is runtime state because a half-completed timer
## must never mint a reward after a reload; completed rewards still enter through
## record_activity(), the single authoritative receipt port.
var manual_activity_session := {"status": "idle", "receipt_id": "", "category": "focused_work", "started_epoch": 0, "duration_seconds": MANUAL_ACTIVITY_DURATION_SECONDS}
var manual_activity_started_ticks_msec := 0
var manual_activity_capability := ""
var world_seed := DEFAULT_WORLD_SEED
var action_sequence := 0
var chance_rolls := {}
var settings := {
	"master": 0.85,
	"music": 0.70,
	"ambience": 0.65,
	"weather": 0.65,
	"effects": 0.80,
	"ui": 0.80,
	"screen_shake": true,
	"haptics": true,
}
var last_day_transaction := 0
var construction_progress := 0.0
var construction_job := {"status": "none", "remaining_hours": 0.0}
var recovery_pack := {}
const FIRST_RUN_STAGES := ["meet_mira", "reach_gate", "choose_trail", "gather", "collect_bundle", "extract", "claim_supply", "build_workshop", "complete"]
var quest := {"id": "first_supply_run", "title": "FIRST SUPPLY RUN", "description": "Return from an expedition with 2 cargo.", "progress": 0, "target": 2, "claimed": false, "first_run_stage": "meet_mira", "first_run_completed": false}
## The market is deterministic per world/day, while completed offers are
## explicit receipts so a reload cannot duplicate a trade.
var market_day := 1
var market_trades := {}
var market_contract_claimed_day := 0
var expedition_run := {
	"status": "none",
	"run_id": "",
	"biome_id": "",
	"cargo": {},
	"depleted_ids": [],
	"contact_progress": {},
	"defeated_guardian_ids": [],
	"guardian_states": {},
	"started_day": 0,
	"anchor": [0.0, 1.0, 7.5],
	"route_checkpoints": [],
}
var save_slot := ""
var save_blocked := false
## Startup state is presentation-facing diagnostics, not gameplay authority.
## "rejected" means candidates existed but neither was safe to apply; the
## composition root must warn the player and suppress background overwrites.
var load_status := "uninitialized"
var load_error := ""

const EXPEDITION_COSTS := ContentRegistry.EXPEDITIONS
const FIXED_RESERVED_RECTS := [
	[-3, -6, 3, -2], # Hearth
	[-10, -4, -5, 0], # Bazaar
	[-9, 1, -8, 2], # Notice board
	[5, 3, 9, 7], # Pond
	[-8, 2, -3, 6], # Garden plot
	[-2, 5, 2, 9], # Livestock pen
	[4, -8, 9, -4], # Workshop
	[-9, -9, -5, -7], # Archive starter shell, clear of the Whisperwood road
	[-1, -9, 1, 9], # Main path
	[0, -3, 13, -2], # Bazaar path
	[-11, -8, -11, -8], # Sanctuary tree
	[-8, 7, -8, 7], # Sanctuary tree
	[12, 7, 12, 7], # Sanctuary tree
	[11, -2, 11, -2], # Sanctuary tree
	[-12, 2, -12, 2], # Sanctuary tree
	[3, 8, 3, 8], # Sanctuary tree
	[-4, 6, -4, 6], # Fiber patch
]

func _ready() -> void:
	load_game()
	_recalculate_stat_derived_state()

func add_item(id: String, amount: int) -> void:
	if amount <= 0 or not INVENTORY_IDS.has(id):
		return
	inventory[id] = int(inventory.get(id, 0)) + amount
	state_changed.emit()

func remove_item(id: String, amount: int) -> bool:
	if not INVENTORY_IDS.has(id):
		return false
	if amount <= 0:
		return true
	if int(inventory.get(id, 0)) < amount:
		return false
	inventory[id] = int(inventory[id]) - amount
	state_changed.emit()
	return true

func award_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	state_changed.emit()

func has_items(cost: Dictionary) -> bool:
	for id in cost:
		if int(inventory.get(id, 0)) < int(cost[id]):
			return false
	return true

func _pay_items_without_signal(cost: Dictionary) -> bool:
	if not has_items(cost):
		return false
	for id in cost:
		inventory[id] = int(inventory.get(id, 0)) - int(cost[id])
	return true

func pay_items(cost: Dictionary) -> bool:
	if not _pay_items_without_signal(cost):
		return false
	state_changed.emit()
	return true

func award_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	var previous_level := level
	var next_level := 1 + int(xp / 100)
	if next_level > previous_level:
		level = next_level
		# Ability Points are the real-life progression currency. Gameplay XP can
		# still show level growth, but cannot mint the same power resource the
		# activity bridge awards.
	state_changed.emit()

func stat_value(stat_name: String) -> int:
	return maxi(1, int(stats.get(stat_name, 1)))

func stat_ids() -> Array:
	return ContentRegistry.stat_ids()

func stat_definition(stat_name: String) -> Dictionary:
	return ContentRegistry.stat_definition(stat_name)

func _stat_effect_float(stat_name: String, effect_name: String, fallback: float) -> float:
	return float(stat_definition(stat_name).get(effect_name, fallback))

func _stat_above_base(stat_name: String) -> int:
	return maxi(0, stat_value(stat_name) - 1)

func _recalculate_stat_derived_state() -> void:
	var target_max_health := 100 + int(round(float(_stat_above_base("Resilience")) * _stat_effect_float("Resilience", "max_health_per_point", 5.0)))
	if target_max_health > max_health:
		health += target_max_health - max_health
	max_health = target_max_health
	health = clampi(health, 1, max_health)

func calculate_attack_damage(base_damage: int) -> int:
	if base_damage <= 0:
		return 0
	return base_damage + int(round(float(_stat_above_base("Strength")) * _stat_effect_float("Strength", "attack_damage_per_point", 2.0))) + (2 if has_permission("combat_training") else 0)

func movement_speed(base_speed: float = 5.2) -> float:
	return base_speed * (1.0 + minf(0.60, float(_stat_above_base("Agility")) * _stat_effect_float("Agility", "movement_speed_per_point", 0.025)))

func dodge_cooldown_seconds() -> float:
	return maxf(0.32, 0.8 - float(_stat_above_base("Agility")) * _stat_effect_float("Agility", "dodge_cooldown_seconds_per_point", 0.025))

func action_windup_seconds(base_seconds: float = 0.12) -> float:
	return maxf(0.055, base_seconds - float(_stat_above_base("Focus")) * _stat_effect_float("Focus", "action_windup_seconds_per_point", 0.006))

func attack_cooldown_seconds() -> float:
	return maxf(0.24, 0.42 - float(_stat_above_base("Focus")) * _stat_effect_float("Focus", "attack_cooldown_seconds_per_point", 0.012))

func gathering_duration_seconds(base_seconds: float = 0.58) -> float:
	return maxf(0.30, base_seconds - float(_stat_above_base("Focus")) * _stat_effect_float("Focus", "gathering_seconds_per_point", 0.035))

func research_duration_hours() -> float:
	## Research is a real elapsed-time job. Wisdom improves the lead time
	## continuously; Bronze research notes are a further multiplier, not an
	## all-or-nothing instant-complete switch.
	var base_hours := 18.0
	var wisdom_factor := 1.0 - minf(0.45, float(_stat_above_base("Wisdom")) * 0.04)
	var duration := base_hours * wisdom_factor
	if has_permission("research_margin_notes"):
		duration *= clampf(permission_effect("research_margin_notes", "research_time_multiplier", 0.90), 0.50, 1.0)
	return maxf(2.0, snapped(duration, 0.1))

func research_duration_days() -> int:
	## Compatibility helper for callers that still describe research in days.
	return maxi(1, int(ceil(research_duration_hours() / 24.0)))

func interaction_range(base_range: float = 2.35) -> float:
	return base_range + minf(1.6, float(_stat_above_base("Perception")) * _stat_effect_float("Perception", "interaction_range_per_point", 0.08))

func food_health_gain(base_gain: int) -> int:
	var multiplier := 1.0 + minf(1.0, float(_stat_above_base("Spirituality")) * _stat_effect_float("Spirituality", "restoration_multiplier_per_point", 0.10))
	return maxi(0, int(round(float(base_gain) * multiplier)))

func stat_effect_summary(stat_name: String) -> String:
	var definition := ContentRegistry.stat_definition(stat_name)
	return str(definition.get("summary", ""))

func set_setting(setting_id: String, value: Variant) -> bool:
	if not settings.has(setting_id):
		return false
	if setting_id in ["screen_shake", "haptics"]:
		if not (value is bool):
			return false
		settings[setting_id] = value
	else:
		if not (value is int or value is float) or not is_finite(float(value)):
			return false
		if float(value) < 0.0 or float(value) > 1.0:
			return false
		settings[setting_id] = float(value)
	state_changed.emit()
	return true

func get_settings() -> Dictionary:
	return settings.duplicate(true)

func award_mastery(name: String, amount: int) -> void:
	if not masteries.has(name) or amount <= 0:
		return
	masteries[name] = mini(100, int(masteries[name]) + amount)
	for permission in _sync_mastery_permissions():
		feedback_requested.emit("mastery_unlock", permission)
	state_changed.emit()

func _is_mastery_feature(feature: String) -> bool:
	return not ContentRegistry.mastery_tier_for_feature(feature).is_empty()

func _is_known_content_grant(feature: String) -> bool:
	if feature.is_empty() or _is_mastery_feature(feature):
		return false
	for discovery_id in ContentRegistry.DISCOVERIES:
		if str(ContentRegistry.DISCOVERIES[discovery_id].get("grant", "")) == feature:
			return true
	return false

func _sync_mastery_permissions() -> Array[Dictionary]:
	var newly_unlocked: Array[Dictionary] = []
	for mastery_name in ContentRegistry.mastery_ids():
		var points := int(masteries.get(str(mastery_name), 0))
		for tier in ContentRegistry.mastery_tiers(str(mastery_name)):
			var feature := str(tier.get("feature", ""))
			if feature.is_empty():
				continue
			var threshold := int(tier.get("threshold", 100))
			var unlocked := unlocked_features.has(feature)
			if points >= threshold and not unlocked:
				unlocked_features.append(feature)
				newly_unlocked.append({"mastery": str(mastery_name), "tier": str(tier.get("tier", "")), "feature": feature, "label": str(tier.get("label", feature)), "summary": str(tier.get("summary", "Permission unlocked.")), "effects": tier.get("effects", {}).duplicate(true)})
			elif points < threshold and unlocked:
				unlocked_features.erase(feature)
	return newly_unlocked

func mastery_tier(name: String) -> Dictionary:
	return ContentRegistry.mastery_tier_for_points(name, int(masteries.get(name, 0)))

func next_mastery_tier(name: String) -> Dictionary:
	return ContentRegistry.next_mastery_tier(name, int(masteries.get(name, 0)))

func has_permission(feature: String) -> bool:
	if feature.is_empty() or not unlocked_features.has(feature):
		return false
	var definition := ContentRegistry.mastery_tier_for_feature(feature)
	if definition.is_empty():
		return true
	return int(masteries.get(str(definition.get("mastery", "")), 0)) >= int(definition.get("threshold", 100))

func permission_effect(feature: String, effect_name: String, fallback: float = 0.0) -> float:
	if not has_permission(feature):
		return fallback
	var effects := ContentRegistry.mastery_effects_for_feature(feature)
	return float(effects.get(effect_name, fallback))

func permission_effect_int(feature: String, effect_name: String, fallback: int = 0) -> int:
	return int(round(permission_effect(feature, effect_name, float(fallback))))

func _next_action_id(kind: String) -> String:
	var normalized_kind := kind.strip_edges().to_lower()
	if normalized_kind.is_empty():
		normalized_kind = "action"
	action_sequence = 1 if action_sequence >= 2147483646 else action_sequence + 1
	return "%s:%d:%d" % [normalized_kind, day, action_sequence]

func _chance_roll_key(feature: String, effect_name: String, action_id: String) -> String:
	return "%s|%s|%s" % [feature.strip_edges(), effect_name.strip_edges(), action_id.strip_edges()]

func _deterministic_chance_result(feature: String, effect_name: String, action_id: String, chance: float) -> bool:
	var key := _chance_roll_key(feature, effect_name, action_id)
	var digest := ("%s|%s|%d" % [world_seed, key, CHANCE_ROLL_VERSION]).hash()
	var unit_roll := float(posmod(digest, 1000000)) / 1000000.0
	return unit_roll < chance

func resolve_mastery_chance(feature: String, effect_name: String, action_id: String) -> bool:
	## Mastery effects that describe a chance are rolled once per authoritative
	## action. The result is persisted so a save/load or scene retry cannot
	## reroll the same harvest, job, or collection.
	var normalized_action_id := action_id.strip_edges()
	if normalized_action_id.is_empty() or normalized_action_id.length() > 160 or normalized_action_id.contains("|") or not has_permission(feature):
		return false
	var chance := clampf(permission_effect(feature, effect_name, 0.0), 0.0, 1.0)
	if chance <= 0.0:
		return false
	var key := _chance_roll_key(feature, effect_name, normalized_action_id)
	if chance_rolls.has(key) and chance_rolls[key] is bool:
		return bool(chance_rolls[key])
	var succeeded := true if chance >= 1.0 else _deterministic_chance_result(feature, effect_name, normalized_action_id, chance)
	chance_rolls[key] = succeeded
	while chance_rolls.size() > MAX_CHANCE_ROLLS:
		var oldest_key: Variant = chance_rolls.keys()[0]
		chance_rolls.erase(oldest_key)
	return succeeded

func _expedition_yield_amount(resource_id: String, amount: int, action_id: String = "", resource_grade: String = "standard") -> int:
	var adjusted := maxi(0, amount)
	var resolved_action_id := action_id.strip_edges()
	if resolved_action_id.is_empty():
		resolved_action_id = _next_action_id("expedition_yield")
	if resource_grade == "deep" and has_permission("mining_deep_delver"):
		adjusted += permission_effect_int("mining_deep_delver", "rare_seam_yield_bonus", 0)
	if resource_id in ["ore", "sunstone"] and has_permission("mining_ore_sorting"):
		if resolve_mastery_chance("mining_ore_sorting", "bonus_ore_chance", resolved_action_id):
			adjusted += 1
	if resource_id == "fiber" and has_permission("foraging_wildkeeper"):
		if resolve_mastery_chance("foraging_wildkeeper", "rare_cutting_chance", resolved_action_id):
			# The protected cutting is represented as one additional usable fiber
			# until the dedicated rare-plant item set is authored.
			adjusted += 1
	return adjusted

func spend_energy(cost: int) -> bool:
	if cost <= 0:
		return true
	if energy < cost:
		return false
	energy -= cost
	state_changed.emit()
	return true

func expedition_cargo_used() -> int:
	if not has_active_expedition():
		return 0
	var used := 0
	var cargo: Dictionary = expedition_run.get("cargo", {})
	for resource_id in cargo:
		used += maxi(0, int(cargo[resource_id]))
	return used

func expedition_cargo_remaining() -> int:
	return maxi(0, cargo_capacity - expedition_cargo_used())

func can_carry_expedition_amount(amount: int) -> bool:
	return has_active_expedition() and amount > 0 and amount <= expedition_cargo_remaining()

func advance_game_clock(hours: float) -> bool:
	if not is_finite(hours) or hours <= 0.0:
		return false
	hour = fmod(hour + hours, 24.0)
	_advance_research_hours(hours)
	return true

func _advance_research_hours(hours: float) -> void:
	if not is_finite(hours) or hours <= 0.0 or str(research_job.get("status", "idle")) != "researching":
		return
	var remaining := maxf(0.0, float(research_job.get("remaining_hours", research_job.get("total_hours", 24.0))) - hours)
	research_job["remaining_hours"] = remaining
	if remaining <= 0.0001:
		research_job["remaining_hours"] = 0.0
		research_job["status"] = "ready"
		feedback_requested.emit("research_ready", {"discovery_id": str(research_job.get("discovery_id", "")), "action_id": str(research_job.get("action_id", ""))})

func _tool_for_resource(resource_id: String) -> String:
	match resource_id:
		"wood": return "hatchet"
		"stone", "ore", "sunstone": return "pickaxe"
		"fiber", "shell": return "fishing_knife"
	return ""

func use_tool_for_resource(resource_id: String, action_id: String = "") -> bool:
	if not _consume_tool_durability(resource_id, action_id):
		return false
	state_changed.emit()
	return true

func spend_resource_contact(resource_id: String, action_id: String = "") -> bool:
	if energy <= 0 or not can_use_tool_for_resource(resource_id):
		return false
	energy -= 1
	if not _consume_tool_durability(resource_id, action_id):
		energy += 1
		return false
	state_changed.emit()
	return true

func _consume_tool_durability(resource_id: String, action_id: String = "") -> bool:
	var tool_id := _tool_for_resource(resource_id)
	if tool_id.is_empty():
		return true
	var tool: Dictionary = equipment.get(tool_id, {})
	if int(tool.get("durability", 0)) <= 0:
		return false
	var wear_multiplier := 1.0
	if resource_id in ["stone", "ore", "sunstone"] and has_permission("mining_reinforced_swing"):
		wear_multiplier = clampf(permission_effect("mining_reinforced_swing", "durability_cost_multiplier", 1.0), 0.0, 1.0)
	elif resource_id == "fiber" and has_permission("foraging_gentle_harvest"):
		wear_multiplier = clampf(permission_effect("foraging_gentle_harvest", "durability_cost_multiplier", 1.0), 0.0, 1.0)
	var wear_units := 1
	if wear_multiplier < 1.0:
		var wear_budget := clampf(float(tool.get("wear_remainder", 0.0)), 0.0, 0.999999) + wear_multiplier
		wear_units = int(floor(wear_budget + 0.000001))
		tool["wear_remainder"] = fmod(wear_budget, 1.0)
	else:
		tool["wear_remainder"] = 0.0
	if wear_units <= 0:
		equipment[tool_id] = tool
		return true
	tool["durability"] = maxi(0, int(tool.get("durability", 0)) - wear_units)
	equipment[tool_id] = tool
	return true

func can_use_tool_for_resource(resource_id: String) -> bool:
	var tool_id := _tool_for_resource(resource_id)
	if tool_id.is_empty():
		return true
	return int(equipment.get(tool_id, {}).get("durability", 0)) > 0

func register_resource_node(node_id: String, zone_id: String, resource_id: String, amount: int, required_contacts: int = 1, discovery_id: String = "", runtime_instance: Node = null, resource_grade: String = "standard") -> bool:
	if node_id.strip_edges().is_empty() or zone_id.strip_edges().is_empty() or not INVENTORY_IDS.has(resource_id) or amount <= 0 or amount > 32 or required_contacts <= 0 or required_contacts > 16 or resource_grade not in ["standard", "deep"]:
		return false
	var descriptor := {"zone_id": zone_id, "resource_id": resource_id, "amount": amount, "required_contacts": required_contacts, "discovery_id": discovery_id, "resource_grade": resource_grade, "runtime_instance": runtime_instance}
	if resource_node_catalog.has(node_id):
		var existing: Dictionary = resource_node_catalog[node_id]
		for descriptor_key in ["zone_id", "resource_id", "amount", "required_contacts", "discovery_id", "resource_grade"]:
			if existing.get(descriptor_key) != descriptor.get(descriptor_key):
				return false
		if runtime_instance != null and existing.get("runtime_instance", null) != null and existing.get("runtime_instance") != runtime_instance:
			return false
	resource_node_catalog[node_id] = descriptor
	return true

func enable_resource_contract() -> void:
	## The composition root enables this after every live resource node has been
	## registered. Legacy domain fixtures stay permissive until then, but the
	## running game requires a scene-authored descriptor for every harvest.
	resource_contract_required = true
	_reconcile_resource_contract_state()

func _reconcile_resource_contract_state() -> void:
	## Save files load before the composition root has registered scene nodes.
	## Reconcile identity-bound progress and physical drops once that catalog is
	## available; forged IDs must not become valid merely because they were saved.
	var changed := false
	for node_id in sanctuary_contact_progress.keys():
		var descriptor: Dictionary = resource_node_catalog.get(str(node_id), {})
		if descriptor.is_empty() or str(descriptor.get("zone_id", "")) != "Sanctuary" or sanctuary_depleted_ids.has(str(node_id)):
			sanctuary_contact_progress.erase(node_id)
			changed = true
			continue
		var maximum_progress := maxi(0, int(descriptor.get("required_contacts", 1)) - 1)
		var normalized_progress := clampi(int(sanctuary_contact_progress[node_id]), 0, maximum_progress)
		if normalized_progress != int(sanctuary_contact_progress[node_id]):
			sanctuary_contact_progress[node_id] = normalized_progress
			changed = true
	if has_active_expedition():
		var expedition_zone := str(expedition_run.get("biome_id", ""))
		var expedition_contacts: Dictionary = expedition_run.get("contact_progress", {})
		for node_id in expedition_contacts.keys():
			var descriptor: Dictionary = resource_node_catalog.get(str(node_id), {})
			if descriptor.is_empty() or str(descriptor.get("zone_id", "")) != expedition_zone:
				expedition_contacts.erase(node_id)
				changed = true
				continue
			var maximum_progress := maxi(0, int(descriptor.get("required_contacts", 1)) - 1)
			var normalized_progress := clampi(int(expedition_contacts[node_id]), 0, maximum_progress)
			if normalized_progress != int(expedition_contacts[node_id]):
				expedition_contacts[node_id] = normalized_progress
				changed = true
		expedition_run["contact_progress"] = expedition_contacts
		var normalized_pickups: Array = []
		for pickup_value in expedition_run.get("pickups", []):
			if not (pickup_value is Dictionary):
				changed = true
				continue
			var pickup: Dictionary = pickup_value
			var pickup_kind := str(pickup.get("pickup_kind", "resource"))
			var pickup_node_id := str(pickup.get("node_id", ""))
			var pickup_resource_id := str(pickup.get("resource_id", ""))
			var maximum_pickup := 0
			if pickup_kind == "guardian_reward":
				var guardian_definition := ContentRegistry.guardian_definition(pickup_node_id)
				var defeated_guardians: Array = expedition_run.get("defeated_guardian_ids", [])
				maximum_pickup = int(guardian_definition.get("reward_amount", 0)) + 1
				if guardian_definition.is_empty() or str(guardian_definition.get("zone_id", "")) != expedition_zone or str(guardian_definition.get("reward_id", "")) != pickup_resource_id or not defeated_guardians.has(pickup_node_id):
					changed = true
					continue
			else:
				var descriptor: Dictionary = resource_node_catalog.get(pickup_node_id, {})
				maximum_pickup = int(descriptor.get("amount", 0)) + 1
				if descriptor.is_empty() or str(descriptor.get("zone_id", "")) != expedition_zone or str(descriptor.get("resource_id", "")) != pickup_resource_id or maximum_pickup <= 0:
					changed = true
					continue
			if pickup_kind not in ["resource", "guardian_reward"]:
				changed = true
				continue
			if not pickup.has("pickup_kind"):
				pickup["pickup_kind"] = pickup_kind
				changed = true
			var pickup_amount := clampi(int(pickup.get("amount", 0)), 1, maximum_pickup)
			if pickup_amount != int(pickup.get("amount", 0)):
				pickup["amount"] = pickup_amount
				changed = true
			normalized_pickups.append(pickup)
		expedition_run["pickups"] = normalized_pickups
	if changed:
		state_changed.emit()

func _resource_node_matches(node_id: String, resource_id: String, amount: int, required_contacts: int, zone_id: String) -> bool:
	if not INVENTORY_IDS.has(resource_id) or amount <= 0 or required_contacts <= 0:
		return false
	if not resource_node_catalog.has(node_id):
		# Direct domain tests and legacy save fixtures predate the runtime catalog.
		# The live composition root opts into strict mode once all scene nodes are
		# registered, so an un-authored resource cannot mint a runtime reward.
		return not resource_contract_required and amount <= 32 and required_contacts <= 16
	var descriptor: Dictionary = resource_node_catalog.get(node_id, {})
	if not can_access_resource_node(node_id):
		return false
	return str(descriptor.get("zone_id", "")) == zone_id and str(descriptor.get("resource_id", "")) == resource_id and int(descriptor.get("amount", 0)) == amount and int(descriptor.get("required_contacts", 0)) == required_contacts

func resource_node_is_registered_instance(node: Node) -> bool:
	if not resource_contract_required or node == null or not is_instance_valid(node):
		return false
	var node_id := str(node.get("node_id"))
	var descriptor: Dictionary = resource_node_catalog.get(node_id, {})
	return not descriptor.is_empty() and descriptor.get("runtime_instance", null) == node

func can_access_resource_node(node_id: String) -> bool:
	var descriptor: Dictionary = resource_node_catalog.get(node_id, {})
	if descriptor.is_empty():
		return not resource_contract_required
	return str(descriptor.get("resource_grade", "standard")) != "deep" or has_permission("mining_deep_delver")

func resource_node_guidance(node_id: String, ground_distance: float) -> Dictionary:
	## Presentation may ask for readable hints, but the session remains the
	## authority for what a mastery has actually revealed or unlocked.
	var descriptor: Dictionary = resource_node_catalog.get(node_id, {})
	if descriptor.is_empty() or not is_finite(ground_distance) or ground_distance < 0.0:
		return {}
	var resource_id := str(descriptor.get("resource_id", ""))
	var guidance := {
		"resource_id": resource_id,
		"resource_grade": str(descriptor.get("resource_grade", "standard")),
		"accessible": can_access_resource_node(node_id),
		"grade_known": false,
		"label_radius": 1.6,
	}
	if resource_id in ["stone", "ore", "sunstone"] and has_permission("mining_vein_reader"):
		var reveal_radius := permission_effect("mining_vein_reader", "reveal_radius", 0.0)
		guidance["grade_known"] = ground_distance <= reveal_radius
	if resource_id in ["fiber", "berries"] and has_permission("foraging_trail_eye"):
		guidance["label_radius"] = permission_effect("foraging_trail_eye", "reveal_radius", 1.6)
	return guidance

func repair_tool(tool_id: String) -> bool:
	if not equipment.has(tool_id):
		return false
	var tool: Dictionary = equipment.get(tool_id, {})
	var maximum := maxi(1, int(tool.get("max_durability", 1)))
	var missing := maximum - int(tool.get("durability", 0))
	if missing <= 0:
		return false
	var divisor := 8.0 if has_permission("field_repair") else 6.0
	var cost := {"plank": maxi(1, int(ceil(float(missing) / divisor)))}
	if not _pay_items_without_signal(cost):
		return false
	tool["durability"] = maximum
	equipment[tool_id] = tool
	award_mastery("Crafting", 4)
	state_changed.emit()
	return true

func repair_tool_at_station(tool_id: String, station_id := "", structure_id := "") -> bool:
	var binding := station_binding_for_capability("workshop_metalwork", station_id, structure_id)
	if binding.is_empty():
		return false
	return repair_tool(tool_id)

func consume_food(food_id := "") -> bool:
	if food_id.is_empty():
		for candidate in ["tonic", "omelette", "bread", "fish", "berries"]:
			if int(inventory.get(candidate, 0)) > 0:
				food_id = candidate
				break
	if food_id.is_empty() or int(inventory.get(food_id, 0)) <= 0:
		return false
	var energy_gain := 0
	var nutrition_gain := 0
	match food_id:
		"tonic":
			energy_gain = 14
			nutrition_gain = 12
			health = mini(max_health, health + food_health_gain(18))
		"omelette":
			energy_gain = 12
			nutrition_gain = 28
		"bread":
			energy_gain = 9
			nutrition_gain = 22
		"fish":
			energy_gain = 7
			nutrition_gain = 16
		"berries":
			energy_gain = 4
			nutrition_gain = 10
		_:
			return false
	inventory[food_id] = int(inventory.get(food_id, 0)) - 1
	energy = mini(max_energy, energy + energy_gain)
	nutrition = mini(max_nutrition, nutrition + nutrition_gain)
	award_mastery("Surviving", 3)
	state_changed.emit()
	return true

func resolve_fishing() -> Dictionary:
	## Compatibility stub. Fishing rewards may only be resolved through the
	## authored cast/bite/hook/reel/claim state machine below; this legacy
	## instant resolver intentionally cannot mint bait, fish, XP, or mastery.
	return {}

func _reset_fishing_attempt() -> void:
	fishing_attempt = {"status": "idle", "phase": "idle", "attempt_id": "", "spot_id": "", "zone_id": "", "elapsed": 0.0, "bite_at": 0.0, "hook_deadline": 0.0, "reel_progress": 0.0, "tension": 0.0, "mistakes": 0, "perfect_hook": false, "catch_amount": 0, "bonus_fish": false, "uncommon_catch": false, "bonus_resource_id": "", "bonus_resource_amount": 0, "seed": 0, "reel_pulse": false}

func _fishing_position_is_valid(position: Array, expected_anchor: Array, radius: float) -> bool:
	if position.size() < 3 or expected_anchor.size() < 3:
		return false
	for value in position.slice(0, 3):
		if not (value is int or value is float) or not is_finite(float(value)):
			return false
	var player_position := Vector2(float(position[0]), float(position[2]))
	var anchor := Vector2(float(expected_anchor[0]), float(expected_anchor[2]))
	return player_position.distance_to(anchor) <= radius

func has_active_fishing() -> bool:
	return str(fishing_attempt.get("status", "idle")) == "active"

func fishing_status() -> Dictionary:
	return fishing_attempt.duplicate(true)

func begin_fishing(spot_id: String, zone_id: String, position: Array) -> Dictionary:
	var spot := ContentRegistry.fishing_spot_definition(spot_id)
	if spot.is_empty() or str(spot.get("zone_id", "")) != zone_id or str(fishing_attempt.get("status", "idle")) != "idle":
		return {}
	if zone_id != "Sanctuary":
		var active_run: Dictionary = expedition_run if expedition_run is Dictionary else {}
		if not has_active_expedition() or str(active_run.get("biome_id", "")) != zone_id:
			return {}
	if not _fishing_position_is_valid(position, spot.get("anchor", []), float(spot.get("interaction_radius", 2.35)) + 0.25):
		return {}
	if int(inventory.get("fiber", 0)) < 1 or energy < 2:
		return {}
	var attempt_id := _next_action_id("fishing")
	var seed: int = posmod(abs(int(attempt_id.hash())), 2147483647)
	var delay_fraction := float(posmod(seed, 1000)) / 1000.0
	var bite_at := lerpf(float(spot.get("bite_delay_min", 0.85)), float(spot.get("bite_delay_max", 1.65)), delay_fraction)
	var hook_window := float(spot.get("hook_window", 0.72))
	if has_permission("fishing_patient_cast"):
		hook_window += permission_effect("fishing_patient_cast", "bite_window_bonus_seconds", 0.50)
	energy -= 2
	inventory["fiber"] = int(inventory.get("fiber", 0)) - 1
	fishing_attempt = {"status": "active", "phase": "waiting", "attempt_id": attempt_id, "spot_id": spot_id, "zone_id": zone_id, "elapsed": 0.0, "bite_at": bite_at, "hook_deadline": bite_at + hook_window, "reel_progress": 0.0, "tension": 0.0, "mistakes": 0, "perfect_hook": false, "catch_amount": 0, "bonus_fish": false, "uncommon_catch": false, "bonus_resource_id": "", "bonus_resource_amount": 0, "seed": seed, "reel_pulse": false}
	feedback_requested.emit("fishing", {"event": "cast", "attempt_id": attempt_id})
	state_changed.emit()
	return {"status": "active", "phase": "waiting", "attempt_id": attempt_id, "bite_at": bite_at, "hook_deadline": bite_at + hook_window}

func _fishing_fail(reason: String) -> Dictionary:
	fishing_attempt["status"] = "failed"
	fishing_attempt["phase"] = "escaped"
	fishing_attempt["reel_pulse"] = false
	feedback_requested.emit("fishing", {"event": "escaped", "reason": reason, "attempt_id": str(fishing_attempt.get("attempt_id", ""))})
	state_changed.emit()
	return {"status": "failed", "phase": "escaped", "reason": reason}

func press_fishing_action(attempt_id: String = "") -> Dictionary:
	if not has_active_fishing() or (not attempt_id.is_empty() and attempt_id != str(fishing_attempt.get("attempt_id", ""))):
		return {}
	var phase := str(fishing_attempt.get("phase", "idle"))
	var elapsed := float(fishing_attempt.get("elapsed", 0.0))
	if phase == "waiting":
		return _fishing_fail("early_hook")
	if phase == "bite":
		if elapsed > float(fishing_attempt.get("hook_deadline", 0.0)):
			return _fishing_fail("late_hook")
		var hook_window := maxf(0.1, float(fishing_attempt.get("hook_deadline", 0.0)) - float(fishing_attempt.get("bite_at", 0.0)))
		var hook_center := float(fishing_attempt.get("bite_at", 0.0)) + hook_window * 0.5
		fishing_attempt["perfect_hook"] = absf(elapsed - hook_center) <= minf(0.20, hook_window * 0.28)
		fishing_attempt["phase"] = "reeling"
		fishing_attempt["tension"] = 0.18
		feedback_requested.emit("fishing", {"event": "hooked", "perfect_hook": bool(fishing_attempt.get("perfect_hook", false))})
		state_changed.emit()
		return {"status": "active", "phase": "reeling", "perfect_hook": bool(fishing_attempt.get("perfect_hook", false))}
	if phase == "reeling":
		fishing_attempt["reel_pulse"] = true
		return {"status": "active", "phase": "reeling", "reel_pulse": true}
	return {}

func _land_fishing() -> Dictionary:
	var perfect := bool(fishing_attempt.get("perfect_hook", false)) and int(fishing_attempt.get("mistakes", 0)) == 0
	var catch_amount := 2 if weather == "rain" else 1
	var bonus_fish := perfect and resolve_mastery_chance("fishing_master_angler", "perfect_catch_bonus_chance", str(fishing_attempt.get("attempt_id", "")))
	if bonus_fish:
		catch_amount += 1
	var spot := ContentRegistry.fishing_spot_definition(str(fishing_attempt.get("spot_id", "")))
	var uncommon_catch := false
	var bonus_resource_id := ""
	var bonus_resource_amount := 0
	if bool(spot.get("coastal", false)) and has_permission("fishing_tide_reader"):
		uncommon_catch = resolve_mastery_chance("fishing_tide_reader", "uncommon_catch_weight", str(fishing_attempt.get("attempt_id", "")))
		if uncommon_catch:
			bonus_resource_id = str(spot.get("uncommon_resource_id", ""))
			bonus_resource_amount = maxi(0, int(spot.get("uncommon_resource_amount", 0)))
	fishing_attempt["status"] = "landed"
	fishing_attempt["phase"] = "landed"
	fishing_attempt["catch_amount"] = catch_amount
	fishing_attempt["bonus_fish"] = bonus_fish
	fishing_attempt["uncommon_catch"] = uncommon_catch
	fishing_attempt["bonus_resource_id"] = bonus_resource_id
	fishing_attempt["bonus_resource_amount"] = bonus_resource_amount
	fishing_attempt["reel_pulse"] = false
	feedback_requested.emit("fishing", {"event": "landed", "amount": catch_amount, "perfect": perfect, "bonus_fish": bonus_fish, "uncommon_catch": uncommon_catch, "bonus_resource_id": bonus_resource_id, "bonus_resource_amount": bonus_resource_amount})
	state_changed.emit()
	return {"status": "landed", "phase": "landed", "amount": catch_amount, "perfect": perfect, "bonus_fish": bonus_fish, "uncommon_catch": uncommon_catch, "bonus_resource_id": bonus_resource_id, "bonus_resource_amount": bonus_resource_amount}

func advance_fishing(delta: float, reel_held: bool = false) -> Dictionary:
	if not has_active_fishing() or not is_finite(delta) or delta <= 0.0 or delta > 0.5:
		return {}
	fishing_attempt["elapsed"] = float(fishing_attempt.get("elapsed", 0.0)) + delta
	var phase := str(fishing_attempt.get("phase", "idle"))
	if phase == "waiting" and float(fishing_attempt["elapsed"]) >= float(fishing_attempt.get("bite_at", 0.0)):
		fishing_attempt["phase"] = "bite"
		feedback_requested.emit("fishing", {"event": "bite"})
		state_changed.emit()
		return {"status": "active", "phase": "bite"}
	if phase == "bite":
		if float(fishing_attempt["elapsed"]) > float(fishing_attempt.get("hook_deadline", 0.0)):
			return _fishing_fail("late_hook")
		return {"status": "active", "phase": "bite"}
	if phase != "reeling":
		return {"status": "active", "phase": phase}
	var pulse := bool(fishing_attempt.get("reel_pulse", false))
	fishing_attempt["reel_pulse"] = false
	var controlling := reel_held or pulse
	var progress := float(fishing_attempt.get("reel_progress", 0.0))
	var tension := float(fishing_attempt.get("tension", 0.0))
	if controlling:
		progress += delta * (0.52 if reel_held else 0.30)
		tension += delta * (0.58 if reel_held else 0.22)
	else:
		var loss_multiplier := permission_effect("fishing_barbed_hook", "escape_progress_multiplier", 1.0) if has_permission("fishing_barbed_hook") else 1.0
		progress = maxf(0.0, progress - delta * 0.12 * loss_multiplier)
		tension = maxf(0.0, tension - delta * 0.95)
	if tension >= 0.82 and not controlling:
		fishing_attempt["mistakes"] = int(fishing_attempt.get("mistakes", 0)) + 1
	fishing_attempt["reel_progress"] = clampf(progress, 0.0, 1.0)
	fishing_attempt["tension"] = clampf(tension, 0.0, 1.0)
	if tension >= 1.0 or int(fishing_attempt.get("mistakes", 0)) >= 3:
		return _fishing_fail("line_break")
	if progress >= 1.0:
		return _land_fishing()
	return {"status": "active", "phase": "reeling", "progress": progress, "tension": tension}

func claim_fishing() -> Dictionary:
	if str(fishing_attempt.get("status", "idle")) != "landed":
		return {}
	var amount := int(fishing_attempt.get("catch_amount", 0))
	if amount <= 0:
		_reset_fishing_attempt()
		return {}
	var bonus_resource_id := str(fishing_attempt.get("bonus_resource_id", ""))
	var bonus_resource_amount := maxi(0, int(fishing_attempt.get("bonus_resource_amount", 0)))
	if bonus_resource_amount > 0 and not INVENTORY_IDS.has(bonus_resource_id):
		return {}
	var result := {"resource_id": "fish", "amount": amount, "perfect": bool(fishing_attempt.get("perfect_hook", false)) and int(fishing_attempt.get("mistakes", 0)) == 0, "bonus_fish": bool(fishing_attempt.get("bonus_fish", false)), "uncommon_catch": bool(fishing_attempt.get("uncommon_catch", false)), "bonus_resource_id": bonus_resource_id, "bonus_resource_amount": bonus_resource_amount}
	inventory["fish"] = int(inventory.get("fish", 0)) + amount
	if bonus_resource_amount > 0:
		inventory[bonus_resource_id] = int(inventory.get(bonus_resource_id, 0)) + bonus_resource_amount
	award_xp(8 + amount * 2 + bonus_resource_amount * 2)
	award_mastery("Fishing", 8)
	_reset_fishing_attempt()
	state_changed.emit()
	return result

func cancel_fishing() -> bool:
	if str(fishing_attempt.get("status", "idle")) == "idle":
		return false
	_reset_fishing_attempt()
	state_changed.emit()
	return true

func apply_player_damage(amount: int) -> Dictionary:
	if amount <= 0:
		return {"ok": false, "health": health, "fainted": false, "second_wind": false}
	health = maxi(0, health - amount)
	var second_wind := false
	if health <= 20 and has_active_expedition() and has_permission("surviving_second_wind") and not bool(expedition_run.get("second_wind_used", false)):
		health = mini(max_health, health + permission_effect_int("surviving_second_wind", "health_restored", 15))
		expedition_run["second_wind_used"] = true
		second_wind = true
	state_changed.emit()
	return {"ok": true, "health": health, "fainted": health <= 0, "second_wind": second_wind}

func reset_player_health() -> void:
	health = max_health
	state_changed.emit()

func interact_farm() -> Dictionary:
	var state := str(farm_plot.get("state", "empty"))
	var growth := int(farm_plot.get("growth", 0))
	if state == "empty":
		if not has_items({"fiber": 2, "wood": 1}) or energy < 1:
			return {"ok": false, "reason": "bed_cost"}
		spend_energy(1)
		pay_items({"fiber": 2, "wood": 1})
		farm_plot["state"] = "tilled"
		farm_plot["growth"] = 0
		farm_plot["watered"] = false
		state_changed.emit()
		return {"ok": true, "action": "tilled"}
	if state == "tilled":
		if int(inventory.get("wheat", 0)) < 1 or energy < 1:
			return {"ok": false, "reason": "seed"}
		spend_energy(1)
		remove_item("wheat", 1)
		farm_plot["state"] = "planted"
		farm_plot["growth"] = 0
		farm_plot["watered"] = false
		state_changed.emit()
		return {"ok": true, "action": "planted"}
	if state == "planted" and growth >= 3:
		if not spend_energy(1):
			return {"ok": false, "reason": "energy"}
		var harvest_amount := 3
		var harvest_action_id := _next_action_id("farm_harvest")
		var paired_crop := resolve_mastery_chance("farming_harvest_pairing", "bonus_crop_chance", harvest_action_id)
		if paired_crop:
			harvest_amount += 1
		add_item("wheat", harvest_amount)
		var seed_saved := resolve_mastery_chance("farming_seed_saver", "seed_refund_chance", harvest_action_id)
		if seed_saved:
			add_item("wheat", 1)
		farm_plot["state"] = "tilled"
		farm_plot["growth"] = 0
		farm_plot["watered"] = false
		award_mastery("Farming", 12)
		return {"ok": true, "action": "harvested", "amount": harvest_amount, "seed_saved": seed_saved, "paired": paired_crop}
	if state == "planted" and not bool(farm_plot.get("watered", false)):
		if int(inventory.get("water", 0)) < 1 or energy < 1:
			return {"ok": false, "reason": "water"}
		spend_energy(1)
		remove_item("water", 1)
		farm_plot["watered"] = true
		state_changed.emit()
		return {"ok": true, "action": "watered"}
	return {"ok": false, "reason": "growing"}

func start_workshop_job(recipe_id: String, station_id := "", structure_id := "") -> Dictionary:
	# A station id is only meaningful within its parent structure. Callers that
	# identify a station must therefore provide both halves of the identity;
	# leaving both blank resolves the recipe's required capability automatically.
	if not station_id.is_empty() and structure_id.is_empty():
		return {}
	var recipe := ContentRegistry.workshop_recipe(recipe_id)
	if recipe.is_empty():
		return {}
	var required_capability := str(recipe.get("requires_capability", "workshop_crafting"))
	var binding := station_binding_for_capability(required_capability, station_id, structure_id)
	if binding.is_empty():
		return {}
	var selected_structure_id := str(binding.get("structure_id", ""))
	var selected_station_id := str(binding.get("station_id", ""))
	if str(station_job.get("kind", "none")) != "none":
		return {}
	var required_feature := str(recipe.get("requires_feature", ""))
	if not required_feature.is_empty() and not unlocked_features.has(required_feature):
		return {}
	var output_kind := str(recipe.get("output_kind", "material"))
	var tool_id := str(recipe.get("tool_id", ""))
	if output_kind not in ["material", "tool"] or (output_kind == "tool" and (tool_id.is_empty() or not equipment.has(tool_id))):
		return {}
	if not _pay_items_without_signal(recipe.get("cost", {})):
		return {}
	var job_action_id := _next_action_id("workshop_job")
	var material_refunded := resolve_mastery_chance("crafting_efficient_joinery", "common_material_refund_chance", job_action_id)
	if material_refunded:
		var common_cost: Dictionary = recipe.get("cost", {})
		for material_id in ["wood", "stone", "fiber"]:
			if int(common_cost.get(material_id, 0)) > 0:
				inventory[material_id] = int(inventory.get(material_id, 0)) + 1
				break
	station_job = {"kind": recipe_id, "structure_id": selected_structure_id, "station_id": selected_station_id, "remaining_hours": float(recipe.get("hours", 12.0)), "total_hours": float(recipe.get("hours", 12.0)), "output_id": recipe_id, "output": int(recipe.get("output", 0)), "output_kind": output_kind, "tool_id": tool_id, "quality_multiplier": float(permission_effect("crafting_quality_work", "durability_multiplier", 1.0)) if output_kind == "tool" else 1.0, "action_id": job_action_id, "material_refunded": material_refunded}
	state_changed.emit()
	return station_job.duplicate(true)

func _synchronize_market_day() -> void:
	if market_day == day:
		return
	market_day = day
	market_trades.clear()
	market_contract_claimed_day = 0
	state_changed.emit()

func _market_trade_key(offer_id: String) -> String:
	return "%d:%s" % [day, offer_id]

func _market_offer_id_is_known(offer_id: String) -> bool:
	for definition in ContentRegistry.TRADE_OFFERS:
		if str(definition.get("id", "")) == offer_id:
			return true
	for definition in ContentRegistry.SPECIALIST_TRADE_OFFERS:
		if str(definition.get("id", "")) == offer_id:
			return true
	return false

func _market_demand_for_offer(offer_id: String) -> Dictionary:
	var digest := ("%s|market|%d|%s" % [world_seed, day, offer_id]).hash()
	var bucket := posmod(digest, 3)
	return [
		{"label": "SURPLUS", "multiplier": 0.86},
		{"label": "STEADY", "multiplier": 1.0},
		{"label": "SCARCE", "multiplier": 1.16},
	][bucket]

func market_offers() -> Array:
	## The offer list is derived from the authored registry and the current day;
	## only completed receipts are mutable state. Appraiser's Eye controls how
	## much of the demand signal the player can actually read.
	_synchronize_market_day()
	var definitions: Array = ContentRegistry.TRADE_OFFERS.duplicate(true)
	if has_permission("trading_caravan_contacts") and not ContentRegistry.SPECIALIST_TRADE_OFFERS.is_empty():
		var specialist_index := posmod(day + world_seed.hash(), ContentRegistry.SPECIALIST_TRADE_OFFERS.size())
		definitions.append(ContentRegistry.SPECIALIST_TRADE_OFFERS[specialist_index].duplicate(true))
	var offers: Array = []
	for definition_value in definitions:
		if not (definition_value is Dictionary):
			continue
		var definition: Dictionary = definition_value
		var offer_id := str(definition.get("id", ""))
		if offer_id.is_empty():
			continue
		var demand := _market_demand_for_offer(offer_id)
		var base_payout := int(definition.get("payout", 0))
		var payout := int(ceil(float(base_payout) * float(demand.get("multiplier", 1.0))))
		if has_permission("market_favor"):
			payout = int(ceil(float(payout) * permission_effect("market_favor", "payout_multiplier", 1.0)))
		var quality_known := has_permission("trading_appraisers_eye")
		offers.append({
			"offer_id": offer_id,
			"cost": definition.get("cost", {}).duplicate(true),
			"base_payout": base_payout,
			"payout": payout,
			"summary": str(definition.get("summary", "")),
			"specialist": str(definition.get("specialist", "")),
			"demand": str(demand.get("label", "UNKNOWN")) if quality_known else "UNKNOWN",
			"demand_known": quality_known,
			"available": not market_trades.has(_market_trade_key(offer_id)),
			"affordable": has_items(definition.get("cost", {})),
		})
	return offers

func market_contract() -> Dictionary:
	## Guild Broker turns one rotating daily lot into a larger, deliberate
	## sourcing contract. The selected lot is derived from the same market list,
	## so appraisal and caravan stock cannot drift between the UI and settlement.
	if not has_permission("trading_guild_broker"):
		return {}
	var offers := market_offers()
	if offers.is_empty():
		return {}
	var contract_index := posmod(day + world_seed.hash() + 1, offers.size())
	var selected: Dictionary = offers[contract_index]
	var contract_cost: Dictionary = {}
	var source_cost: Dictionary = selected.get("cost", {})
	for item_id in source_cost:
		var required := int(source_cost[item_id])
		if required <= 0:
			return {}
		contract_cost[str(item_id)] = required * 2
	var contract_id := "%d:bulk:%s" % [day, str(selected.get("offer_id", ""))]
	var contract_payout := int(ceil(float(selected.get("payout", 0)) * 2.0 * permission_effect("trading_guild_broker", "contract_payout_multiplier", 1.40)))
	return {
		"contract_id": contract_id,
		"offer_id": str(selected.get("offer_id", "")),
		"cost": contract_cost,
		"payout": contract_payout,
		"summary": "Bulk contract  |  %s" % str(selected.get("summary", "")),
		"specialist": str(selected.get("specialist", "")),
		"demand": str(selected.get("demand", "UNKNOWN")),
		"demand_known": bool(selected.get("demand_known", false)),
		"available": market_contract_claimed_day != day,
		"affordable": has_items(contract_cost),
	}

func resolve_trade_contract(contract_id: String) -> Dictionary:
	var contract := market_contract()
	if contract.is_empty() or contract_id.strip_edges().is_empty() or str(contract.get("contract_id", "")) != contract_id or not bool(contract.get("available", false)) or not bool(contract.get("affordable", false)):
		return {}
	var cost: Dictionary = contract.get("cost", {})
	for item_id in cost:
		if int(inventory.get(str(item_id), 0)) < int(cost[item_id]):
			return {}
	for item_id in cost:
		inventory[str(item_id)] = int(inventory.get(str(item_id), 0)) - int(cost[item_id])
	market_contract_claimed_day = day
	var payout := int(contract.get("payout", 0))
	coins += payout
	award_mastery("Trading", 16)
	award_xp(20)
	state_changed.emit()
	return contract.merged({"market_day": day})

func resolve_trade_offer(offer_id: String) -> Dictionary:
	if offer_id.strip_edges().is_empty():
		return {}
	for offer_value in market_offers():
		if str(offer_value.get("offer_id", "")) != offer_id:
			continue
		if not bool(offer_value.get("available", false)):
			return {}
		var cost: Dictionary = offer_value.get("cost", {})
		if not has_items(cost):
			return {}
		for item_id in cost:
			inventory[str(item_id)] = int(inventory.get(str(item_id), 0)) - int(cost[item_id])
		for item_id in cost:
			if int(inventory.get(str(item_id), 0)) < 0:
				return {}
		market_trades[_market_trade_key(offer_id)] = true
		var payout := int(offer_value.get("payout", 0))
		coins += payout
		award_mastery("Trading", 8)
		award_xp(10)
		state_changed.emit()
		return offer_value.merged({"market_day": day, "market_favor": has_permission("market_favor")})
	return {}

func resolve_attack_damage(base_damage: int) -> int:
	return calculate_attack_damage(base_damage)

func resolve_attack(base_damage: int, combo_step: int = 1, target_health: int = 0, target_guarding: bool = false, target_unaware: bool = false) -> Dictionary:
	## Resolve the combat rule set in one place. The scene supplies only the
	## transient combo step and the target's observed health; damage, stamina
	## refunds, and mastery multipliers settle here before the hit is presented.
	if base_damage <= 0:
		return {}
	if energy < 1:
		return {}
	energy -= 1
	var step := clampi(combo_step, 1, 3)
	var damage := calculate_attack_damage(base_damage)
	var heavy_attack := step == 3
	var guard_break := heavy_attack and target_guarding and has_permission("attacking_guard_break")
	var guarded := target_guarding and not guard_break
	var guard_multiplier := 1.0
	if guarded:
		# A telegraphed guard reduces damage without becoming immunity. The
		# player can wait out the opening or commit a permission-backed heavy
		# attack to break it.
		guard_multiplier = 0.55
		damage = maxi(1, int(floor(float(damage) * guard_multiplier)))
	if guard_break:
		damage = maxi(damage + 1, int(round(float(damage) * permission_effect("attacking_guard_break", "guard_damage_multiplier", 1.35))))
	var finisher := target_health > 0 and target_health <= damage
	var vanguard_resolve := target_health > 0 and target_health <= int(ceil(float(damage) * 1.50)) and has_permission("attacking_vanguard_resolve")
	if vanguard_resolve:
		damage = maxi(damage + 1, int(round(float(damage) * permission_effect("attacking_vanguard_resolve", "finisher_damage_multiplier", 1.50))))
	var opening_stagger_multiplier := 1.0
	var clean_shot := target_unaware and not target_guarding and has_permission("hunting_clean_shot")
	if clean_shot:
		opening_stagger_multiplier = clampf(permission_effect("hunting_clean_shot", "opening_stagger_multiplier", 1.50), 1.0, 3.0)
	var stamina_refunded := 0
	if heavy_attack and has_permission("attacking_relentless_rhythm"):
		var energy_before_refund := energy
		energy = mini(max_energy, energy + permission_effect_int("attacking_relentless_rhythm", "combo_stamina_refund", 2))
		stamina_refunded = maxi(0, energy - energy_before_refund)
	state_changed.emit()
	return {
		"damage": damage,
		"combo_step": step,
		"heavy_attack": heavy_attack,
		"guarded": guarded,
		"guard_multiplier": guard_multiplier,
		"guard_break": guard_break,
		"finisher": finisher,
		"vanguard_resolve": vanguard_resolve,
		"clean_shot": clean_shot,
		"opening_stagger_multiplier": opening_stagger_multiplier,
		"stamina_refunded": stamina_refunded,
	}

func claim_workshop_job() -> Dictionary:
	if str(station_job.get("kind", "none")) == "none" or float(station_job.get("remaining_hours", 0.0)) > 0.0:
		return {}
	var job_structure_id := str(station_job.get("structure_id", ""))
	var job_station_id := str(station_job.get("station_id", ""))
	var recipe_id_for_binding := str(station_job.get("output_id", station_job.get("kind", "")))
	var recipe_for_binding := ContentRegistry.workshop_recipe(recipe_id_for_binding)
	var required_capability := str(recipe_for_binding.get("requires_capability", "workshop_crafting"))
	var bound_station := station_binding_for_capability(required_capability, job_station_id, job_structure_id)
	if job_structure_id.is_empty() or str(bound_station.get("structure_id", "")) != job_structure_id or str(bound_station.get("station_id", "")) != job_station_id:
		return {}
	var output_id := str(station_job.get("output_id", ""))
	var output := int(station_job.get("output", 0))
	if output_id.is_empty() or output_id != str(station_job.get("kind", "")) or output <= 0 or not ContentRegistry.WORKSHOP_RECIPES.has(output_id):
		return {}
	var recipe: Dictionary = ContentRegistry.workshop_recipe(output_id)
	var output_kind := str(station_job.get("output_kind", recipe.get("output_kind", "material")))
	var expected_output := int(recipe.get("output", 0))
	var expected_hours := float(recipe.get("hours", 0.0))
	if output_kind not in ["material", "tool"] or output_kind != str(recipe.get("output_kind", "material")) or output != expected_output or float(station_job.get("total_hours", 0.0)) != expected_hours:
		return {}
	if output_kind == "tool":
		var tool_id := str(station_job.get("tool_id", recipe.get("tool_id", "")))
		if not equipment.has(tool_id):
			return {}
		var quality_multiplier := maxf(1.0, float(station_job.get("quality_multiplier", 1.0)))
		var tool: Dictionary = equipment.get(tool_id, {}).duplicate(true)
		var crafted_max := clampi(int(ceil(float(tool.get("max_durability", 1)) * quality_multiplier)), 1, 1000)
		tool["max_durability"] = crafted_max
		tool["durability"] = crafted_max
		tool["wear_remainder"] = 0.0
		equipment[tool_id] = tool
		station_job = {"kind": "none", "structure_id": "", "station_id": "", "remaining_hours": 0.0, "total_hours": 0.0, "output_id": output_id, "output": 0, "output_kind": "material", "tool_id": "", "quality_multiplier": 1.0, "action_id": "", "material_refunded": false}
		award_mastery("Crafting", 12)
		return {"output_id": output_id, "output": output, "output_kind": "tool", "tool_id": tool_id, "max_durability": crafted_max}
	inventory[output_id] = int(inventory.get(output_id, 0)) + output
	station_job = {"kind": "none", "structure_id": "", "station_id": "", "remaining_hours": 0.0, "total_hours": 0.0, "output_id": output_id, "output": 0, "output_kind": "material", "tool_id": "", "quality_multiplier": 1.0, "action_id": "", "material_refunded": false}
	award_mastery("Crafting", 10)
	return {"output_id": output_id, "output": output}

func drink_water() -> bool:
	if int(inventory.get("water", 0)) <= 0 or hydration >= max_hydration:
		return false
	inventory["water"] = int(inventory.get("water", 0)) - 1
	hydration = mini(max_hydration, hydration + 34)
	energy = mini(max_energy, energy + 1)
	award_mastery("Surviving", 2)
	state_changed.emit()
	return true

func feed_livestock(animal_id := "clover") -> bool:
	if not bool(built.get("livestock_pen", false)) or not livestock.has(animal_id):
		return false
	var animal: Dictionary = livestock.get(animal_id, {})
	if int(animal.get("hunger", 0)) >= 90 or not remove_item("wheat", 1):
		return false
	var hunger_gain := 35
	if has_permission("livestock_calm_hands"):
		hunger_gain = int(round(float(hunger_gain) * permission_effect("livestock_calm_hands", "trust_gain_multiplier", 1.0)))
	animal["hunger"] = mini(100, int(animal.get("hunger", 0)) + hunger_gain)
	animal["last_fed_day"] = day
	animal["health"] = mini(100, int(animal.get("health", 0)) + 5)
	if has_permission("livestock_sanctuary_breeder") and str(animal.get("trait_id", "")).is_empty():
		var trait_step := maxi(1, permission_effect_int("livestock_sanctuary_breeder", "trait_progress_per_feed", 25))
		var trait_progress := mini(100, int(animal.get("trait_progress", 0)) + trait_step)
		animal["trait_progress"] = trait_progress
		if trait_progress >= 100:
			# The first authored trait is a deliberate care milestone. Future trait
			# tables can add deterministic branching without changing this boundary.
			animal["trait_id"] = "sunplume"
			animal["trait_progress"] = 100
	livestock[animal_id] = animal
	award_mastery("Livestock", 6)
	state_changed.emit()
	return true

func collect_livestock(animal_id := "clover") -> Dictionary:
	if not bool(built.get("livestock_pen", false)) or not livestock.has(animal_id):
		return {}
	var animal: Dictionary = livestock.get(animal_id, {})
	if not bool(animal.get("production_ready", false)):
		return {}
	var product_id := str(animal.get("product_id", "egg"))
	var amount := maxi(1, int(animal.get("product_amount", 1)))
	var trait_id := str(animal.get("trait_id", ""))
	var trait_definition := ContentRegistry.livestock_trait_definition(trait_id)
	var trait_bonus := maxi(0, int(trait_definition.get("product_bonus", 0)))
	amount += trait_bonus
	var collection_action_id := _next_action_id("livestock_collect")
	if resolve_mastery_chance("livestock_herd_bond", "quality_product_chance", collection_action_id):
		amount += 1
	add_item(product_id, amount)
	animal["production_ready"] = false
	livestock[animal_id] = animal
	award_mastery("Livestock", 8)
	award_xp(8)
	state_changed.emit()
	return {product_id: amount, "product_id": product_id, "amount": amount, "trait_id": trait_id, "trait_bonus": trait_bonus}

func allocate_stat(name: String) -> bool:
	if ability_points <= 0 or not stats.has(name):
		return false
	ability_points -= 1
	stats[name] = int(stats[name]) + 1
	_recalculate_stat_derived_state()
	state_changed.emit()
	return true

func _activity_event_key(source_id: String, event_id: String) -> String:
	return source_id.strip_edges().to_lower() + "::" + event_id.strip_edges()

func _activity_stat_for_metadata(metadata: Dictionary) -> String:
	# The caller may provide a UI hint, but the persisted reward mapping is
	# policy-owned. Never allow an arbitrary receipt to redirect a reward into a
	# different stat by supplying stat_id directly.
	match str(metadata.get("category", "focused_work")).to_lower():
		"exercise", "movement": return "Agility"
		"learning", "study": return "Wisdom"
		"creative": return "Spirituality"
		"social", "communication": return "Perception"
		"recovery", "rest": return "Resilience"
		"planning", "analysis": return "Focus"
	return "Focus"

func _activity_mastery_for_metadata(metadata: Dictionary) -> String:
	# Mastery routing is likewise derived from the versioned category policy;
	# mastery_id is descriptive input, never an authority boundary.
	match str(metadata.get("category", "focused_work")).to_lower():
		"exercise", "movement", "recovery", "rest": return "Surviving"
		"learning", "study": return "Research"
		"creative": return "Crafting"
		"social", "communication": return "Language"
		"planning", "analysis": return "Research"
	return "Research"

func record_activity(receipt_id: String, minutes: int, metadata: Dictionary = {}) -> bool:
	# This is the single temporary activity bridge. Empty optional metadata is
	# normalized into a complete local receipt for older callers; all persisted
	# events still carry source, event, wall-clock, timezone, mapping, and hash.
	receipt_id = receipt_id.strip_edges()
	if receipt_id.is_empty() or receipt_id.length() > 128 or activity_receipts.has(receipt_id) or minutes <= 0 or minutes > ACTIVITY_MAX_MINUTES:
		return false
	var source_id := str(metadata.get("source_id", "manual_ui")).strip_edges()
	var event_id := str(metadata.get("event_id", receipt_id)).strip_edges()
	# The release path has one local adapter: the capability is minted by
	# start_manual_activity() and consumed by the matching in-process timer.
	# manual_ui remains available only to debug regression fixtures, never to the
	# game UI or a production build.
	if source_id not in ["manual_ui", "manual_timer"] or event_id.is_empty() or event_id.length() > 128:
		return false
	if source_id == "manual_ui" and (not OS.is_debug_build() or str(metadata.get("debug_adapter", "")) != "activity_test_v1"):
		return false
	var current_epoch := int(Time.get_unix_time_from_system())
	if source_id in ["manual_ui", "manual_timer"] and manual_activity_cooldown_remaining() > 0:
		return false
	if source_id == "manual_timer":
		if str(metadata.get("verification", "")) != "elapsed_timer_v1":
			return false
		if manual_activity_capability.is_empty() or str(metadata.get("verification_token", "")) != manual_activity_capability:
			return false
		if str(manual_activity_session.get("status", "idle")) != "active" or str(manual_activity_session.get("receipt_id", "")) != receipt_id or event_id != receipt_id:
			return false
		var timer_status := manual_activity_status()
		if not bool(timer_status.get("complete", false)):
			return false
		var started_epoch := int(metadata.get("started_epoch", 0))
		var duration_seconds := int(metadata.get("duration_seconds", MANUAL_ACTIVITY_DURATION_SECONDS))
		if started_epoch != int(manual_activity_session.get("started_epoch", 0)) or started_epoch <= 0 or duration_seconds != MANUAL_ACTIVITY_DURATION_SECONDS or current_epoch + 300 < started_epoch:
			return false
	var event_key := _activity_event_key(source_id, event_id)
	for prior_event in activity_events:
		if prior_event is Dictionary and _activity_event_key(str(prior_event.get("source_id", "manual_ui")), str(prior_event.get("event_id", prior_event.get("receipt_id", "")))) == event_key:
			return false
	var occurred_at := str(metadata.get("occurred_at", "")).strip_edges()
	if occurred_at.is_empty():
		occurred_at = Time.get_datetime_string_from_system(true)
	if occurred_at.length() > 64:
		return false
	var occurred_epoch := Time.get_unix_time_from_datetime_string(occurred_at)
	if occurred_epoch <= 0 or occurred_epoch > current_epoch + 300 or occurred_epoch < current_epoch - 31 * 86400:
		return false
	var timezone := str(metadata.get("timezone", "UTC")).strip_edges()
	if timezone.is_empty() or timezone.length() > 64:
		return false
	var mapping_version := int(metadata.get("mapping_version", activity_mapping_version))
	if mapping_version != activity_mapping_version:
		return false
	var payload_hash := str(metadata.get("payload_hash", "")).strip_edges()
	if payload_hash.is_empty():
		payload_hash = "%s:%s:%d:%d" % [source_id, event_id, minutes, mapping_version]
	if payload_hash.length() > 256:
		return false
	if source_id == "manual_timer" and payload_hash != "manual_timer_v1:%s:%d" % [receipt_id, int(manual_activity_session.get("started_epoch", 0))]:
		return false
	var stat_id := _activity_stat_for_metadata(metadata)
	var mastery_id := _activity_mastery_for_metadata(metadata)
	var previous_minutes := activity_minutes_total
	activity_minutes_total += minutes
	var reward_xp := clampi(int(minutes / 10), 1, ACTIVITY_MAX_REWARD_XP)
	var reward_coins := clampi(int(minutes / 15), 1, ACTIVITY_MAX_REWARD_COINS)
	var reward_health := clampi(int(minutes / 30), 1, ACTIVITY_MAX_REWARD_HEALTH)
	var previous_ap_milestone := int(previous_minutes / 60)
	var current_ap_milestone := int(activity_minutes_total / 60)
	var reward_ap := maxi(0, current_ap_milestone - previous_ap_milestone)
	var previous_stat_minutes := int(activity_stat_minutes.get(stat_id, 0))
	activity_stat_minutes[stat_id] = previous_stat_minutes + minutes
	var previous_stat_milestone := int(previous_stat_minutes / 30)
	var current_stat_milestone := int(activity_stat_minutes[stat_id] / 30)
	var reward_stat := maxi(0, current_stat_milestone - previous_stat_milestone)
	var previous_xp := xp
	var previous_coins := coins
	var previous_health := health
	var previous_ability_points := ability_points
	var previous_mastery := int(masteries.get(mastery_id, 0))
	var requested_mastery_gain := maxi(1, int(minutes / 10))
	activity_receipts.append(receipt_id)
	if source_id in ["manual_ui", "manual_timer"]:
		activity_last_manual_epoch = current_epoch
		activity_last_manual_ticks_msec = Time.get_ticks_msec()
	activity_stat_gains[stat_id] = int(activity_stat_gains.get(stat_id, 0)) + reward_stat
	stats[stat_id] = int(stats.get(stat_id, 1)) + reward_stat
	ability_points += reward_ap
	coins += reward_coins
	health = mini(max_health, health + reward_health)
	award_xp(reward_xp)
	award_mastery(mastery_id, requested_mastery_gain)
	_recalculate_stat_derived_state()
	var actual_xp := xp - previous_xp
	var actual_coins := coins - previous_coins
	var actual_health := health - previous_health
	var actual_ability_points := ability_points - previous_ability_points
	var actual_mastery := int(masteries.get(mastery_id, 0)) - previous_mastery
	var event := {
		"receipt_id": receipt_id,
		"event_id": event_id,
		"source_id": source_id,
		"occurred_at": occurred_at,
		"timezone": timezone,
		"payload_hash": payload_hash,
		"mapping_version": mapping_version,
		"category": str(metadata.get("category", "focused_work")),
		"stat_id": stat_id,
		"mastery_id": mastery_id,
		"minutes": minutes,
		"awards": {"xp": actual_xp, "health": actual_health, "coins": actual_coins, "ability_points": actual_ability_points, "stat": {stat_id: reward_stat}, "mastery": {mastery_id: actual_mastery}},
	}
	if source_id == "manual_timer":
		event["verification"] = "elapsed_timer_v1"
		event["started_epoch"] = int(manual_activity_session.get("started_epoch", 0))
	activity_events.append(event)
	activity_cursor = receipt_id
	state_changed.emit()
	feedback_requested.emit("activity", {"minutes": minutes, "xp": actual_xp, "health": actual_health, "coins": actual_coins, "ability_points": actual_ability_points, "stat_id": stat_id, "stat_gain": reward_stat, "mastery_id": mastery_id, "mastery_gain": actual_mastery})
	return true

func manual_activity_cooldown_remaining() -> int:
	if activity_last_manual_epoch <= 0:
		return 0
	var elapsed := 0
	if activity_last_manual_ticks_msec != 0:
		elapsed = maxi(0, int((Time.get_ticks_msec() - activity_last_manual_ticks_msec) / 1000))
	else:
		# A reload cannot restore a monotonic clock origin. The persisted epoch is
		# retained as a conservative best-effort fallback until a signed provider
		# replaces this local bridge.
		elapsed = maxi(0, int(Time.get_unix_time_from_system()) - activity_last_manual_epoch)
	return maxi(0, MANUAL_ACTIVITY_MIN_INTERVAL_SECONDS - elapsed)

func manual_activity_status() -> Dictionary:
	var status: Dictionary = manual_activity_session.duplicate(true)
	var is_active := str(status.get("status", "idle")) == "active"
	if not is_active:
		status["elapsed_seconds"] = 0
		status["remaining_seconds"] = 0
		status["complete"] = false
		return status
	var duration_seconds := maxi(1, int(status.get("duration_seconds", MANUAL_ACTIVITY_DURATION_SECONDS)))
	var elapsed := 0
	if manual_activity_started_ticks_msec != 0:
		elapsed = maxi(0, int((Time.get_ticks_msec() - manual_activity_started_ticks_msec) / 1000))
	status["elapsed_seconds"] = mini(duration_seconds, elapsed)
	status["remaining_seconds"] = maxi(0, duration_seconds - elapsed)
	status["complete"] = elapsed >= duration_seconds
	return status

func start_manual_activity(category := "focused_work") -> bool:
	if str(manual_activity_session.get("status", "idle")) == "active" or manual_activity_cooldown_remaining() > 0:
		return false
	var now := int(Time.get_unix_time_from_system())
	var receipt := "manual-timer-%d-%d" % [now, action_sequence + 1]
	manual_activity_session = {"status": "active", "receipt_id": receipt, "category": category.strip_edges().to_lower() if not category.strip_edges().is_empty() else "focused_work", "started_epoch": now, "duration_seconds": MANUAL_ACTIVITY_DURATION_SECONDS}
	manual_activity_started_ticks_msec = Time.get_ticks_msec()
	manual_activity_capability = "%s:%d:%d" % [receipt, now, manual_activity_started_ticks_msec]
	state_changed.emit()
	return true

func cancel_manual_activity() -> bool:
	if str(manual_activity_session.get("status", "idle")) != "active":
		return false
	manual_activity_session = {"status": "idle", "receipt_id": "", "category": "focused_work", "started_epoch": 0, "duration_seconds": MANUAL_ACTIVITY_DURATION_SECONDS}
	manual_activity_started_ticks_msec = 0
	manual_activity_capability = ""
	state_changed.emit()
	return true

func complete_manual_activity() -> Dictionary:
	var status := manual_activity_status()
	if str(status.get("status", "idle")) != "active" or not bool(status.get("complete", false)):
		return {}
	var receipt_id := str(status.get("receipt_id", ""))
	var started_epoch := int(status.get("started_epoch", 0))
	var category := str(status.get("category", "focused_work"))
	var metadata := {
		"source_id": "manual_timer",
		"event_id": receipt_id,
		"occurred_at": Time.get_datetime_string_from_unix_time(started_epoch, true),
		"timezone": "local",
		"payload_hash": "manual_timer_v1:%s:%d" % [receipt_id, started_epoch],
		"mapping_version": activity_mapping_version,
		"category": category,
		"verification": "elapsed_timer_v1",
		"verification_token": manual_activity_capability,
		"started_epoch": started_epoch,
		"duration_seconds": MANUAL_ACTIVITY_DURATION_SECONDS,
	}
	if not record_activity(receipt_id, int(MANUAL_ACTIVITY_DURATION_SECONDS / 60), metadata):
		return {}
	manual_activity_session = {"status": "idle", "receipt_id": "", "category": "focused_work", "started_epoch": 0, "duration_seconds": MANUAL_ACTIVITY_DURATION_SECONDS}
	manual_activity_started_ticks_msec = 0
	manual_activity_capability = ""
	state_changed.emit()
	return {"receipt_id": receipt_id, "minutes": int(MANUAL_ACTIVITY_DURATION_SECONDS / 60), "category": category}

func record_discovery(discovery_id: String) -> bool:
	if discovery_id.is_empty() or not can_record_expedition_discovery(discovery_id):
		return false
	var objective_progressed := false
	var route_definition := expedition_route_definition()
	if str(route_definition.get("objective_kind", "")) == "discovery" and str(route_definition.get("objective_id", "")) == discovery_id:
		objective_progressed = _advance_expedition_objective("discovery", discovery_id, 1)
	if discovered.has(discovery_id):
		return objective_progressed
	discovered.append(discovery_id)
	award_mastery("Research", 4)
	feedback_requested.emit("discovery", {"id": discovery_id})
	state_changed.emit()
	return true

func observe_wildlife(wildlife_id: String) -> bool:
	if not ContentRegistry.WILDLIFE.has(wildlife_id) or observed_wildlife.has(wildlife_id):
		return false
	observed_wildlife.append(wildlife_id)
	award_xp(4)
	award_mastery("Foraging", 2)
	feedback_requested.emit("wildlife", {"id": wildlife_id, "label": str(ContentRegistry.WILDLIFE[wildlife_id].get("label", "Wildlife"))})
	state_changed.emit()
	return true

func wildlife_track_status(wildlife_id: String) -> Dictionary:
	var definition := ContentRegistry.wildlife_definition(wildlife_id)
	if definition.is_empty():
		return {"ready": false, "reason": "unknown", "wildlife_id": wildlife_id}
	var status := {"ready": false, "reason": "locked", "wildlife_id": wildlife_id, "label": str(definition.get("label", "Wildlife")), "zone_id": str(definition.get("zone_id", "")), "direction": str(definition.get("track_direction", "unknown"))}
	if not has_active_expedition():
		status["reason"] = "no_expedition"
		return status
	if str(expedition_run.get("biome_id", "")) != str(definition.get("zone_id", "")):
		status["reason"] = "wrong_zone"
		return status
	if not has_permission("hunting_track_sign"):
		status["reason"] = "hunting_locked"
		return status
	if tracked_wildlife.has(wildlife_id):
		status["reason"] = "tracked"
		return status
	status["ready"] = true
	status["reason"] = "ready"
	return status

func inspect_wildlife_track(wildlife_id: String) -> Dictionary:
	var status := wildlife_track_status(wildlife_id)
	if not bool(status.get("ready", false)):
		return {}
	var reveal_radius := clampf(permission_effect("hunting_track_sign", "track_reveal_radius", 4.0), 1.0, 12.0)
	tracked_wildlife.append(wildlife_id)
	award_xp(3)
	award_mastery("Hunting", 3)
	var result := {"wildlife_id": wildlife_id, "label": str(status.get("label", "Wildlife")), "direction": str(status.get("direction", "unknown")), "reveal_radius": reveal_radius, "xp": 3, "mastery": 3}
	feedback_requested.emit("wildlife_track", result.duplicate(true))
	state_changed.emit()
	return result

func expedition_inscription_status(inscription_id: String) -> Dictionary:
	var definition := ContentRegistry.expedition_inscription_definition(inscription_id)
	if definition.is_empty():
		return {"ready": false, "reason": "unknown", "inscription_id": inscription_id}
	var status := {
		"ready": false,
		"reason": "locked",
		"inscription_id": inscription_id,
		"title": str(definition.get("title", "Expedition Inscription")),
		"zone_id": str(definition.get("zone_id", "")),
		"branch_id": str(definition.get("branch_id", "")),
		"ancient": bool(definition.get("ancient", false)),
	}
	if not has_active_expedition():
		status["reason"] = "no_expedition"
		return status
	if str(expedition_run.get("biome_id", "")) != str(definition.get("zone_id", "")):
		status["reason"] = "wrong_zone"
		return status
	var committed_branch := str(expedition_run.get("branch_id", ""))
	if committed_branch.is_empty():
		status["reason"] = "choose_branch"
		return status
	if committed_branch != str(definition.get("branch_id", "")):
		status["reason"] = "off_branch"
		return status
	if translated_inscriptions.has(inscription_id):
		status["reason"] = "translated"
		return status
	var required_feature := "language_polyglot" if bool(definition.get("ancient", false)) else "language_context_reader"
	status["required_feature"] = required_feature
	if not has_permission(required_feature):
		status["reason"] = "language_locked"
		return status
	status["ready"] = true
	status["reason"] = "ready"
	return status

func read_expedition_inscription(inscription_id: String) -> Dictionary:
	var status := expedition_inscription_status(inscription_id)
	if not bool(status.get("ready", false)):
		return {}
	var definition := ContentRegistry.expedition_inscription_definition(inscription_id)
	var reward_multiplier := 1.0
	if bool(definition.get("ancient", false)):
		reward_multiplier = clampf(permission_effect("language_polyglot", "lore_reward_multiplier", 1.0), 1.0, 3.0)
	var reward_xp := maxi(1, int(round(float(definition.get("base_xp", 1)) * reward_multiplier)))
	var reward_coins := maxi(1, int(round(float(definition.get("base_coins", 1)) * reward_multiplier)))
	translated_inscriptions.append(inscription_id)
	award_xp(reward_xp)
	coins += reward_coins
	award_mastery("Language", 8 if not bool(definition.get("ancient", false)) else 12)
	var result := {
		"inscription_id": inscription_id,
		"title": str(definition.get("title", "Expedition Inscription")),
		"translation": str(definition.get("translation", "")),
		"summary": str(definition.get("summary", "")),
		"ancient": bool(definition.get("ancient", false)),
		"xp": reward_xp,
		"coins": reward_coins,
		"mastery": 12 if bool(definition.get("ancient", false)) else 8,
		"reward_multiplier": reward_multiplier,
	}
	feedback_requested.emit("inscription", result.duplicate(true))
	state_changed.emit()
	return result

func _reveal_research_clue(source_id: String, action_id: String) -> Dictionary:
	if not has_permission("research_cross_reference"):
		return {}
	var links := ContentRegistry.discovery_links(source_id)
	var clue_limit := maxi(1, permission_effect_int("research_cross_reference", "bonus_clue_count", 1))
	var revealed := 0
	for link_value in links:
		if revealed >= clue_limit or not (link_value is Dictionary):
			break
		var link: Dictionary = link_value
		var related_id := str(link.get("related_id", ""))
		if related_id.is_empty() or not ContentRegistry.DISCOVERIES.has(related_id) or researched.has(related_id):
			continue
		var clue_id := "%s:%s" % [source_id, related_id]
		var duplicate := false
		for existing_value in research_clues:
			if existing_value is Dictionary and str(existing_value.get("clue_id", "")) == clue_id:
				duplicate = true
				break
		if duplicate:
			continue
		var clue := {"clue_id": clue_id, "source_id": source_id, "related_id": related_id, "destination_id": str(link.get("destination_id", "")), "branch_id": str(link.get("branch_id", "")), "title": str(link.get("title", related_id)), "hint": str(link.get("hint", "A related lead surfaced in the margins.")), "preparation_hint": str(link.get("preparation_hint", "Prepare before following the lead.")), "revealed_day": day, "action_id": action_id}
		research_clues.append(clue)
		revealed += 1
		feedback_requested.emit("research_clue", clue.duplicate(true))
	return research_clues.back().duplicate(true) if revealed > 0 else {}

func research_discovery(discovery_id: String) -> bool:
	if not ContentRegistry.DISCOVERIES.has(discovery_id) or not bool(built.get("library", false)) or not discovered.has(discovery_id) or researched.has(discovery_id) or str(research_job.get("status", "idle")) != "idle" or not has_items({"water": 1}):
		return false
	if not _pay_items_without_signal({"water": 1}):
		return false
	var duration_hours := research_duration_hours()
	var research_action_id := _next_action_id("research")
	research_job = {"status": "researching", "discovery_id": discovery_id, "ready_day": day + int(ceil(duration_hours / 24.0)), "remaining_hours": duration_hours, "total_hours": duration_hours, "action_id": research_action_id, "material_refunded": false}
	state_changed.emit()
	return true

func claim_research() -> bool:
	if str(research_job.get("status", "idle")) != "ready":
		return false
	var discovery_id := str(research_job.get("discovery_id", ""))
	if discovery_id.is_empty() or not ContentRegistry.DISCOVERIES.has(discovery_id) or not discovered.has(discovery_id) or researched.has(discovery_id):
		research_job = {"status": "idle", "discovery_id": "", "ready_day": 0, "remaining_hours": 0.0, "total_hours": 0.0, "action_id": "", "material_refunded": false}
		return false
	researched.append(discovery_id)
	var blueprint := ContentRegistry.discovery_blueprint(discovery_id)
	if not blueprints.has(blueprint):
		blueprints.append(blueprint)
		var grant := ContentRegistry.discovery_grant(discovery_id)
		if not grant.is_empty() and not unlocked_features.has(grant):
			unlocked_features.append(grant)
		award_mastery("Research", 20)
	_reveal_research_clue(discovery_id, str(research_job.get("action_id", "research:%s:%d" % [discovery_id, day])))
	var material_refunded := resolve_mastery_chance("research_breakthrough", "material_refund_chance", str(research_job.get("action_id", "research:%s:%d" % [discovery_id, day])))
	if material_refunded:
		inventory["water"] = int(inventory.get("water", 0)) + 1
	research_job = {"status": "idle", "discovery_id": "", "ready_day": 0, "remaining_hours": 0.0, "total_hours": 0.0, "action_id": "", "material_refunded": material_refunded}
	state_changed.emit()
	return true

func start_expedition(biome_id: String) -> bool:
	if not EXPEDITION_COSTS.has(biome_id):
		return false
	if not unlocked_routes.has(biome_id):
		return false
	if str(expedition_run.get("status", "none")) != "none":
		return false
	var cost := ContentRegistry.expedition_cost(biome_id)
	if biome_id == "Sunlit Beach" and unlocked_features.has("safe_tides"):
		cost = maxi(1, cost - 1)
	if biome_id in ["Glass Desert", "Sunken Dungeon"] and has_permission("surviving_worldwalker"):
		cost = maxi(0, cost - permission_effect_int("surviving_worldwalker", "travel_energy_reduction", 2))
	var entry_coins := ContentRegistry.expedition_entry_coins(biome_id)
	if biome_id == "Sunken Dungeon" and unlocked_features.has("dungeon_lantern"):
		entry_coins = maxi(0, entry_coins - 15)
	if coins < entry_coins:
		return false
	if not spend_energy(cost):
		return false
	coins -= entry_coins
	expedition_run = {
		"status": "active",
		"run_id": _next_action_id("expedition"),
		"biome_id": biome_id,
		"cargo": {},
		"pickups": [],
		"depleted_ids": [],
		"contact_progress": {},
		"defeated_guardian_ids": [],
		"guardian_states": {},
		"camp_used": false,
		"started_day": day,
		"anchor": [0.0, 1.0, 7.5],
		"route_phase": "approach",
		"branch_id": "",
		"objective_id": "",
		"objective_kind": "",
		"objective_progress": 0,
		"objective_target": 0,
		"objective_complete": false,
		"shortcut_open": false,
		"cache_claimed": false,
		"return_checkpoint_crossed": false,
		"stake_active": false,
		"stake_ticks": 0,
		"pressure_elapsed_seconds": 0.0,
		"second_wind_used": false,
		"route_checkpoints": [],
	}
	state_changed.emit()
	if biome_id == "Whisperwood":
		advance_first_run("enter_whisperwood")
	return true

func has_active_expedition() -> bool:
	return str(expedition_run.get("status", "none")) == "active"

func route_is_unlocked(biome_id: String) -> bool:
	return EXPEDITION_COSTS.has(biome_id) and unlocked_routes.has(biome_id)

func route_unlock_requirement(biome_id: String) -> String:
	match biome_id:
		"Whisperwood": return "Available from the start."
		"Sunlit Beach": return "Complete a Whisperwood branch capstone, then extract safely."
		"Ember Ridge": return "Complete a Beach route objective and capstone, then extract safely."
		"Glass Desert": return "Complete a Ridge route objective and capstone, then extract safely."
		"Sunken Dungeon": return "Complete a Desert route objective and capstone, then extract safely."
	return "This route is not on the current map."

func expedition_route_definition(branch_id: String = "") -> Dictionary:
	var route_id := str(expedition_run.get("biome_id", ""))
	var selected_branch := branch_id if not branch_id.is_empty() else str(expedition_run.get("branch_id", ""))
	return ContentRegistry.expedition_route_definition(route_id, selected_branch)

func expedition_branch_options(biome_id: String = "") -> Array:
	var route_id := biome_id if not biome_id.is_empty() else str(expedition_run.get("biome_id", ""))
	return ContentRegistry.expedition_branch_ids(route_id)

func _complete_route_objective(objective_id: String) -> bool:
	if not has_active_expedition() or str(expedition_run.get("route_phase", "")) != "objective" or str(expedition_run.get("objective_id", "")) != objective_id or bool(expedition_run.get("objective_complete", false)):
		return false
	expedition_run["objective_progress"] = int(expedition_run.get("objective_target", 1))
	expedition_run["objective_complete"] = true
	expedition_run["route_phase"] = "capstone"
	feedback_requested.emit("route_capstone", {"route": str(expedition_run.get("biome_id", "")), "branch": str(expedition_run.get("branch_id", "")), "label": str(expedition_route_definition().get("label", "Capstone"))})
	state_changed.emit()
	return true

func _maybe_complete_resource_objective(resource_id: String) -> void:
	_advance_expedition_objective("resource", resource_id, 1)

func _advance_expedition_objective(objective_kind: String, objective_id: String, amount: int) -> bool:
	if amount <= 0 or not has_active_expedition() or str(expedition_run.get("route_phase", "")) != "objective" or bool(expedition_run.get("objective_complete", false)):
		return false
	if str(expedition_run.get("objective_kind", "")) != objective_kind or str(expedition_run.get("objective_id", "")) != objective_id:
		return false
	var target := maxi(1, int(expedition_run.get("objective_target", 1)))
	var previous := clampi(int(expedition_run.get("objective_progress", 0)), 0, target)
	var next := mini(target, previous + amount)
	if next == previous:
		return false
	expedition_run["objective_progress"] = next
	if next >= target:
		_complete_route_objective(objective_id)
	else:
		expedition_run["route_phase"] = "objective"
		state_changed.emit()
	return true

func _route_objective_branch(objective_kind: String, objective_id: String) -> String:
	var route_id := str(expedition_run.get("biome_id", ""))
	for branch_id in ContentRegistry.EXPEDITION_ROUTE_DEFINITIONS.get(route_id, {}):
		var definition: Dictionary = ContentRegistry.expedition_route_definition(route_id, str(branch_id))
		if str(definition.get("objective_kind", "")) == objective_kind and str(definition.get("objective_id", "")) == objective_id:
			return str(branch_id)
	return ""

func _route_objective_is_off_branch(objective_kind: String, objective_id: String) -> bool:
	if not has_active_expedition() or str(expedition_run.get("branch_id", "")).is_empty():
		return false
	var objective_branch := _route_objective_branch(objective_kind, objective_id)
	return not objective_branch.is_empty() and objective_branch != str(expedition_run.get("branch_id", ""))

func _expedition_route_state_is_supported(run: Dictionary, allow_active: bool = false) -> bool:
	## The route is a small state machine. Keeping this validator beside the
	## command methods means a save, reload, or direct caller cannot create a
	## phase that the authored map could never produce.
	var status := str(run.get("status", "none"))
	if status == "none":
		return str(run.get("route_phase", "none")) == "none" and str(run.get("biome_id", "")).is_empty() and str(run.get("branch_id", "")).is_empty() and str(run.get("objective_id", "")).is_empty() and str(run.get("objective_kind", "")).is_empty() and int(run.get("objective_progress", 0)) == 0 and int(run.get("objective_target", 0)) == 0 and not bool(run.get("objective_complete", false)) and not bool(run.get("shortcut_open", false)) and not bool(run.get("cache_claimed", false)) and not bool(run.get("return_checkpoint_crossed", false)) and (run.get("route_checkpoints", []) is Array and (run.get("route_checkpoints", []) as Array).is_empty())
	if status != "active" or not allow_active:
		return false
	var route_id := str(run.get("biome_id", ""))
	if not ContentRegistry.EXPEDITION_ROUTE_DEFINITIONS.has(route_id):
		return false
	var phase := str(run.get("route_phase", ""))
	if not EXPEDITION_ROUTE_PHASES.has(phase) or phase == "none":
		return false
	var checkpoints_value: Variant = run.get("route_checkpoints", [])
	if not (checkpoints_value is Array):
		return false
	var checkpoints: Array = checkpoints_value
	var expected_checkpoints: Array = []
	match phase:
		"arrival": expected_checkpoints = ["arrival"]
		"fork", "branch", "objective", "capstone", "shortcut": expected_checkpoints = ["arrival", "fork"]
		"return": expected_checkpoints = ["arrival", "fork", "return"]
		"approach": expected_checkpoints = []
		_: return false
	if checkpoints != expected_checkpoints:
		return false
	var branch_id := str(run.get("branch_id", ""))
	var objective_id := str(run.get("objective_id", ""))
	var objective_kind := str(run.get("objective_kind", ""))
	var objective_progress := int(run.get("objective_progress", 0))
	var objective_target := int(run.get("objective_target", 0))
	var objective_complete := bool(run.get("objective_complete", false))
	var shortcut_open := bool(run.get("shortcut_open", false))
	var cache_claimed := bool(run.get("cache_claimed", false))
	var return_crossed := bool(run.get("return_checkpoint_crossed", false))
	if cache_claimed != shortcut_open or return_crossed != (phase == "return"):
		return false
	if phase in ["approach", "arrival", "fork"]:
		return branch_id.is_empty() and objective_id.is_empty() and objective_kind.is_empty() and objective_progress == 0 and objective_target == 0 and not objective_complete and not shortcut_open and not cache_claimed
	if branch_id.is_empty():
		return false
	var definition := ContentRegistry.expedition_route_definition(route_id, branch_id)
	if definition.is_empty() or objective_id != str(definition.get("objective_id", "")) or objective_kind != str(definition.get("objective_kind", "")):
		return false
	var expected_target := maxi(1, int(definition.get("objective_target", 1)))
	if objective_target != expected_target or objective_progress < 0 or objective_progress > objective_target:
		return false
	if phase in ["branch", "objective"]:
		return not objective_complete and not shortcut_open and not cache_claimed and (phase == "branch" or objective_progress < objective_target)
	if phase == "capstone":
		return objective_complete and objective_progress == objective_target and not shortcut_open and not cache_claimed
	if phase == "shortcut":
		return objective_complete and objective_progress == objective_target and shortcut_open and cache_claimed
	if phase == "return":
		return objective_complete and objective_progress == objective_target and shortcut_open and cache_claimed
	return false

func can_record_expedition_discovery(discovery_id: String) -> bool:
	return not _route_objective_is_off_branch("discovery", discovery_id)

func _unlock_route(biome_id: String) -> bool:
	if not EXPEDITION_COSTS.has(biome_id) or unlocked_routes.has(biome_id):
		return false
	unlocked_routes.append(biome_id)
	feedback_requested.emit("route_unlock", {"route": biome_id, "requirement": route_unlock_requirement(biome_id)})
	state_changed.emit()
	return true

func _unlock_route_after_extraction(run: Dictionary, cargo: Dictionary) -> void:
	var biome_id := str(run.get("biome_id", ""))
	if str(run.get("branch_id", "")).is_empty() or not bool(run.get("objective_complete", false)) or not bool(run.get("cache_claimed", false)):
		return
	var next_route := ""
	match biome_id:
		"Whisperwood":
			next_route = "Sunlit Beach"
		"Sunlit Beach":
			next_route = "Ember Ridge"
		"Ember Ridge":
			next_route = "Glass Desert"
		"Glass Desert":
			next_route = "Sunken Dungeon"
	if not next_route.is_empty():
		_unlock_route(next_route)

func commit_expedition_branch(branch_id: String) -> bool:
	if not has_active_expedition() or str(expedition_run.get("route_phase", "")) != "fork" or not _expedition_route_state_is_supported(expedition_run, true) or not ContentRegistry.EXPEDITION_ROUTE_DEFINITIONS.has(str(expedition_run.get("biome_id", ""))) or ContentRegistry.expedition_route_definition(str(expedition_run.get("biome_id", "")), branch_id).is_empty():
		return false
	if not str(expedition_run.get("branch_id", "")).is_empty():
		return false
	expedition_run["branch_id"] = branch_id
	var branch_definition := ContentRegistry.expedition_route_definition(str(expedition_run.get("biome_id", "")), branch_id)
	expedition_run["objective_id"] = str(branch_definition.get("objective_id", ""))
	expedition_run["objective_kind"] = str(branch_definition.get("objective_kind", ""))
	expedition_run["objective_progress"] = 0
	expedition_run["objective_target"] = maxi(1, int(branch_definition.get("objective_target", 1)))
	expedition_run["route_phase"] = "branch"
	if str(expedition_run.get("biome_id", "")) == "Whisperwood":
		advance_first_run("choose_trail")
	state_changed.emit()
	return true

func record_route_checkpoint(checkpoint_id: String) -> bool:
	## Route landmarks are durable traversal state, not presentation-only labels.
	## The renderer can detect proximity, but only this method advances the
	## ordered expedition journey and emits a save-visible checkpoint event.
	var route_id := str(expedition_run.get("biome_id", ""))
	if not has_active_expedition() or not ContentRegistry.EXPEDITION_ROUTE_DEFINITIONS.has(route_id) or not _expedition_route_state_is_supported(expedition_run, true):
		return false
	if not EXPEDITION_ROUTE_CHECKPOINTS.has(checkpoint_id):
		return false
	var stored_checkpoints: Variant = expedition_run.get("route_checkpoints", [])
	if not (stored_checkpoints is Array):
		return false
	var checkpoints: Array = stored_checkpoints
	if checkpoints.has(checkpoint_id):
		return false
	var phase := str(expedition_run.get("route_phase", "approach"))
	var expected_checkpoint := ""
	match phase:
		"approach": expected_checkpoint = "arrival"
		"arrival": expected_checkpoint = "fork"
		"shortcut": expected_checkpoint = "return"
		_: return false
	if checkpoint_id != expected_checkpoint:
		return false
	var expected_prefix: Array = []
	match checkpoint_id:
		"arrival": expected_prefix = []
		"fork": expected_prefix = ["arrival"]
		"return": expected_prefix = ["arrival", "fork"]
	if checkpoints != expected_prefix:
		return false
	checkpoints.append(checkpoint_id)
	expedition_run["route_checkpoints"] = checkpoints
	match checkpoint_id:
		"arrival": expedition_run["route_phase"] = "arrival"
		"fork": expedition_run["route_phase"] = "fork"
		"return":
			expedition_run["route_phase"] = "return"
			expedition_run["return_checkpoint_crossed"] = true
	feedback_requested.emit("route_checkpoint", {"route": route_id, "checkpoint": checkpoint_id, "phase": str(expedition_run.get("route_phase", ""))})
	state_changed.emit()
	return true

func record_expedition_return_checkpoint(position: Array) -> bool:
	if not has_active_expedition() or position.size() < 3:
		return false
	var biome_id := str(expedition_run.get("biome_id", ""))
	if not bool(expedition_run.get("cache_claimed", false)) or not bool(expedition_run.get("shortcut_open", false)) or str(expedition_run.get("route_phase", "")) != "shortcut":
		return false
	for coordinate in position.slice(0, 3):
		if not _valid_number(coordinate, -100000.0, 100000.0):
			return false
	var return_socket := ContentRegistry.expedition_route_socket(biome_id, "return")
	if return_socket == Vector3.ZERO or Vector2(float(position[0]), float(position[2])).distance_to(Vector2(return_socket.x, return_socket.z)) > 2.8:
		return false
	return record_route_checkpoint("return")

func expedition_return_checkpoint_required() -> bool:
	## Once a Whisperwood capstone opens the shortcut, the return is an authored
	## physical beat rather than a UI-only promise. Ordinary runs can still
	## extract early, but a cached run must cross the Return Footbridge before
	## its pressure-bearing cargo can be banked.
	if not has_active_expedition():
		return false
	if not _expedition_route_state_is_supported(expedition_run, true):
		return true
	return str(expedition_run.get("route_phase", "")) == "shortcut"

func record_expedition_endpoint(branch_id: String) -> bool:
	## Endpoint arrival is a durable domain transition. The scene may detect
	## proximity, but it cannot complete the branch by changing route_phase
	## directly.
	var route_id := str(expedition_run.get("biome_id", ""))
	if not has_active_expedition() or not ContentRegistry.EXPEDITION_ROUTE_DEFINITIONS.has(route_id) or not _expedition_route_state_is_supported(expedition_run, true):
		return false
	if str(expedition_run.get("route_phase", "")) != "branch" or str(expedition_run.get("branch_id", "")) != branch_id:
		return false
	var definition := ContentRegistry.expedition_route_definition(route_id, branch_id)
	if definition.is_empty():
		return false
	expedition_run["route_phase"] = "objective"
	feedback_requested.emit("route_endpoint", {"route": route_id, "branch": branch_id, "label": str(definition.get("label", branch_id))})
	state_changed.emit()
	return true

func expedition_route_snapshot() -> Dictionary:
	var stored_checkpoints: Variant = expedition_run.get("route_checkpoints", [])
	var checkpoints: Array = stored_checkpoints if stored_checkpoints is Array else []
	var next_checkpoint := ""
	match str(expedition_run.get("route_phase", "approach")):
		"approach": next_checkpoint = "arrival"
		"arrival": next_checkpoint = "fork"
		"shortcut": next_checkpoint = "return"
	return {
		"route_phase": str(expedition_run.get("route_phase", "approach")),
		"branch_id": str(expedition_run.get("branch_id", "")),
		"objective_id": str(expedition_run.get("objective_id", "")),
		"objective_kind": str(expedition_run.get("objective_kind", "")),
		"objective_progress": int(expedition_run.get("objective_progress", 0)),
		"objective_target": int(expedition_run.get("objective_target", 0)),
		"objective_complete": bool(expedition_run.get("objective_complete", false)),
		"shortcut_open": bool(expedition_run.get("shortcut_open", false)),
		"cache_claimed": bool(expedition_run.get("cache_claimed", false)),
		"return_checkpoint_crossed": bool(expedition_run.get("return_checkpoint_crossed", false)),
		"route_checkpoints": checkpoints.duplicate(true),
		"next_checkpoint": next_checkpoint,
		"branch_options": expedition_branch_options(),
		"branch_definition": expedition_route_definition(),
	}

func open_expedition_cache() -> Dictionary:
	if not has_active_expedition() or str(expedition_run.get("biome_id", "")) != "Whisperwood" or str(expedition_run.get("route_phase", "")) != "capstone" or not _expedition_route_state_is_supported(expedition_run, true):
		return {}
	var branch_id := str(expedition_run.get("branch_id", ""))
	if branch_id.is_empty() or not bool(expedition_run.get("objective_complete", false)) or bool(expedition_run.get("cache_claimed", false)):
		return {}
	var reward: Dictionary = expedition_route_definition().get("capstone_reward", {})
	if reward.is_empty():
		return {}
	var reward_total := 0
	for resource_id in reward:
		reward_total += int(reward[resource_id])
	if energy < 2 or not can_carry_expedition_amount(reward_total):
		return {}
	energy -= 2
	var cargo: Dictionary = expedition_run.get("cargo", {})
	for resource_id in reward:
		cargo[str(resource_id)] = int(cargo.get(str(resource_id), 0)) + int(reward[resource_id])
	expedition_run["cargo"] = cargo
	expedition_run["cache_claimed"] = true
	expedition_run["shortcut_open"] = true
	expedition_run["route_phase"] = "shortcut"
	expedition_run["stake_active"] = true
	expedition_run["stake_ticks"] = 0
	expedition_run["pressure_elapsed_seconds"] = 0.0
	award_xp(8)
	state_changed.emit()
	return {"branch_id": branch_id, "loot": reward.duplicate(true), "energy_cost": 2}

func open_expedition_capstone() -> Dictionary:
	if not has_active_expedition():
		return {}
	if str(expedition_run.get("biome_id", "")) == "Whisperwood":
		return open_expedition_cache()
	var branch_id := str(expedition_run.get("branch_id", ""))
	if branch_id.is_empty() or str(expedition_run.get("route_phase", "")) != "capstone" or not _expedition_route_state_is_supported(expedition_run, true) or not bool(expedition_run.get("objective_complete", false)) or bool(expedition_run.get("cache_claimed", false)):
		return {}
	var reward: Dictionary = expedition_route_definition().get("capstone_reward", {})
	if reward.is_empty():
		return {}
	var reward_total := 0
	for resource_id in reward:
		reward_total += int(reward[resource_id])
	if energy < 2 or not can_carry_expedition_amount(reward_total):
		return {}
	energy -= 2
	var cargo: Dictionary = expedition_run.get("cargo", {})
	for resource_id in reward:
		cargo[str(resource_id)] = int(cargo.get(str(resource_id), 0)) + int(reward[resource_id])
	expedition_run["cargo"] = cargo
	expedition_run["cache_claimed"] = true
	expedition_run["shortcut_open"] = true
	expedition_run["route_phase"] = "shortcut"
	expedition_run["stake_active"] = true
	expedition_run["stake_ticks"] = 0
	expedition_run["pressure_elapsed_seconds"] = 0.0
	award_xp(8)
	state_changed.emit()
	return {"branch_id": branch_id, "loot": reward.duplicate(true), "energy_cost": 2}

func apply_expedition_stake_tick() -> Dictionary:
	if not has_active_expedition() or not bool(expedition_run.get("stake_active", false)):
		return {}
	var biome_id := str(expedition_run.get("biome_id", ""))
	var stake_tick := int(expedition_run.get("stake_ticks", 0)) + 1
	var energy_loss := 1
	var message := "The route is demanding a safe return."
	match biome_id:
		"Whisperwood": message = "The old trail wakes. Keep the beacon in sight on the way home."
		"Sunlit Beach": message = "The tide turns. Keep moving toward the beacon."
		"Ember Ridge": message = "The ridge shudders. Ash and loose stone drain your pace."
		"Glass Desert": message = "The glass desert takes its toll. Find shade before the next flare."
		"Sunken Dungeon": message = "Floodwater rises around the old causeway."
		_: energy_loss = 0
	if has_permission("surviving_weatherwise") and posmod(stake_tick, 4) == 0:
		energy_loss = 0
	if energy_loss <= 0:
		expedition_run["stake_ticks"] = stake_tick
		state_changed.emit()
		return {"energy_loss": 0, "health_loss": 0, "message": message, "ticks": stake_tick}
	var health_loss := 0
	if energy < energy_loss:
		health_loss = 3 if has_permission("surviving_weatherwise") else 4
		energy = 0
	else:
		energy -= energy_loss
	expedition_run["stake_ticks"] = stake_tick
	state_changed.emit()
	return {"energy_loss": energy_loss, "health_loss": health_loss, "message": message, "ticks": int(expedition_run.get("stake_ticks", 0))}

func expedition_pressure_interval(biome_id: String = "") -> float:
	var route_id := biome_id if not biome_id.is_empty() else str(expedition_run.get("biome_id", ""))
	match route_id:
		"Whisperwood": return 5.5
		"Sunlit Beach": return 5.0
		"Ember Ridge": return 4.5
		"Glass Desert": return 4.0
		"Sunken Dungeon": return 3.5
	return 18.0

func advance_expedition_pressure(delta_seconds: float, sheltered := false) -> Dictionary:
	## Pressure is durable expedition state. The scene may schedule this method
	## once per frame, but only this method decides when a loss happens, which
	## makes reloads and save failures preserve the same clock.
	if not has_active_expedition() or not bool(expedition_run.get("stake_active", false)):
		return {}
	if not is_finite(delta_seconds) or delta_seconds < 0.0:
		return {}
	var interval := expedition_pressure_interval()
	var elapsed := clampf(float(expedition_run.get("pressure_elapsed_seconds", 0.0)), 0.0, interval * 2.0)
	if sheltered:
		if elapsed != 0.0:
			expedition_run["pressure_elapsed_seconds"] = 0.0
			state_changed.emit()
		return {"sheltered": true, "triggered": false, "tick_count": 0, "warning": false, "seconds_until_tick": interval, "pressure_elapsed_seconds": 0.0}
	if delta_seconds > 0.0:
		elapsed += delta_seconds
	var tick_count := 0
	var total_energy_loss := 0
	var total_health_loss := 0
	var last_message := "The route is demanding a safe return."
	var last_result: Dictionary = {}
	while elapsed >= interval and tick_count < 32:
		elapsed -= interval
		last_result = apply_expedition_stake_tick()
		if last_result.is_empty():
			break
		tick_count += 1
		total_energy_loss += int(last_result.get("energy_loss", 0))
		total_health_loss += int(last_result.get("health_loss", 0))
		last_message = str(last_result.get("message", last_message))
	if tick_count >= 32 and elapsed >= interval:
		elapsed = fmod(elapsed, interval)
	expedition_run["pressure_elapsed_seconds"] = clampf(elapsed, 0.0, interval)
	if delta_seconds > 0.0 and tick_count == 0:
		state_changed.emit()
	var warning := tick_count == 0 and elapsed >= maxf(0.0, interval - 1.0)
	return {
		"sheltered": false,
		"triggered": tick_count > 0,
		"tick_count": tick_count,
		"warning": warning,
		"seconds_until_tick": maxf(0.0, interval - elapsed),
		"pressure_elapsed_seconds": elapsed,
		"energy_loss": total_energy_loss,
		"health_loss": total_health_loss,
		"message": last_message,
		"ticks": int(last_result.get("ticks", expedition_run.get("stake_ticks", 0))) if not last_result.is_empty() else int(expedition_run.get("stake_ticks", 0)),
	}

func collect_expedition_resource(node_id: String, resource_id: String, amount: int, required_contacts: int = 1) -> bool:
	return collect_expedition_resource_with_tool(node_id, resource_id, amount, required_contacts)

func collect_expedition_resource_with_tool(node_id: String, resource_id: String, amount: int, required_contacts: int = 1) -> bool:
	if not has_active_expedition() or node_id.is_empty() or resource_id.is_empty() or amount <= 0:
		return false
	if not _resource_node_matches(node_id, resource_id, amount, required_contacts, str(expedition_run.get("biome_id", ""))):
		return false
	if not can_carry_expedition_amount(amount):
		return false
	if _route_objective_is_off_branch("resource", resource_id):
		return false
	for discovery_id in ContentRegistry.DISCOVERIES:
		if node_id.to_lower().contains(str(discovery_id).to_lower().replace(" ", "")) and _route_objective_is_off_branch("discovery", str(discovery_id)):
			return false
	var depleted: Array = expedition_run.get("depleted_ids", [])
	if depleted.has(node_id) or energy <= 0 or not can_use_tool_for_resource(resource_id):
		return false
	var action_id := "expedition:%s:%s:%s" % [str(expedition_run.get("run_id", "")), node_id, resource_id]
	var resource_grade := str(resource_node_catalog.get(node_id, {}).get("resource_grade", "standard"))
	var carried_amount := _expedition_yield_amount(resource_id, amount, action_id, resource_grade)
	# Bonus mastery yield is optional. Keep the authored base collection valid
	# when only the bonus would exceed the remaining satchel space.
	carried_amount = mini(carried_amount, expedition_cargo_remaining())
	energy -= 1
	if not _consume_tool_durability(resource_id, action_id):
		energy += 1
		return false
	var cargo: Dictionary = expedition_run.get("cargo", {})
	cargo[resource_id] = int(cargo.get(resource_id, 0)) + carried_amount
	depleted.append(node_id)
	var contact_progress: Dictionary = expedition_run.get("contact_progress", {})
	contact_progress.erase(node_id)
	expedition_run["cargo"] = cargo
	expedition_run["depleted_ids"] = depleted
	expedition_run["contact_progress"] = contact_progress
	_advance_expedition_objective("resource", resource_id, carried_amount)
	advance_first_run("resource_collected")
	state_changed.emit()
	return true

func harvest_expedition_resource(node_id: String, resource_id: String, amount: int, required_contacts: int = 1, position: Array = [], discovery_id := "", effort_already_spent := false) -> Dictionary:
	## Spend the field effort and leave a physical drop in the world. Cargo is
	## intentionally unchanged until collect_expedition_pickup is called.
	if not has_active_expedition() or node_id.is_empty() or resource_id.is_empty() or amount <= 0:
		return {}
	if not _resource_node_matches(node_id, resource_id, amount, required_contacts, str(expedition_run.get("biome_id", ""))):
		return {}
	if _route_objective_is_off_branch("resource", resource_id):
		return {}
	for known_discovery_id in ContentRegistry.DISCOVERIES:
		if node_id.to_lower().contains(str(known_discovery_id).to_lower().replace(" ", "")) and _route_objective_is_off_branch("discovery", str(known_discovery_id)):
			return {}
	if amount > cargo_capacity:
		return {}
	var depleted: Array = expedition_run.get("depleted_ids", [])
	if depleted.has(node_id) or energy <= 0 or (not effort_already_spent and not can_use_tool_for_resource(resource_id)):
		return {}
	var contact_progress: Dictionary = expedition_run.get("contact_progress", {})
	if required_contacts > 1 and int(contact_progress.get(node_id, 0)) < required_contacts - 1:
		return {}
	var pickups: Array = expedition_run.get("pickups", [])
	var pickup_id := "%s:drop" % node_id
	for existing_pickup in pickups:
		if existing_pickup is Dictionary and str(existing_pickup.get("pickup_id", "")) == pickup_id:
			return {}
	var action_id := "expedition:%s:%s:%s" % [str(expedition_run.get("run_id", "")), node_id, resource_id]
	var resource_grade := str(resource_node_catalog.get(node_id, {}).get("resource_grade", "standard"))
	var pickup_amount := mini(_expedition_yield_amount(resource_id, amount, action_id, resource_grade), cargo_capacity)
	var pickup_position := [0.0, 1.0, 0.0]
	if position.size() >= 3:
		for value in position.slice(0, 3):
			if not (value is int or value is float) or not is_finite(float(value)):
				return {}
		pickup_position = [clampf(float(position[0]), -EXPEDITION_ANCHOR_LIMIT_X, EXPEDITION_ANCHOR_LIMIT_X), 1.0, clampf(float(position[2]), -EXPEDITION_ANCHOR_LIMIT_Z, EXPEDITION_ANCHOR_LIMIT_Z)]
	if not effort_already_spent and not spend_resource_contact(resource_id, action_id):
		return {}
	pickups.append({"pickup_id": pickup_id, "pickup_kind": "resource", "node_id": node_id, "resource_id": resource_id, "resource_label": resource_id.replace("_", " ").capitalize(), "discovery_id": discovery_id, "amount": pickup_amount, "position": pickup_position})
	depleted.append(node_id)
	contact_progress.erase(node_id)
	expedition_run["pickups"] = pickups
	expedition_run["depleted_ids"] = depleted
	expedition_run["contact_progress"] = contact_progress
	advance_first_run("field_bundle")
	state_changed.emit()
	return pickups.back().duplicate(true)

func collect_expedition_pickup(pickup_id: String) -> Dictionary:
	if not has_active_expedition() or pickup_id.is_empty():
		return {}
	var pickups: Array = expedition_run.get("pickups", [])
	for index in pickups.size():
		var pickup: Variant = pickups[index]
		if not (pickup is Dictionary) or str(pickup.get("pickup_id", "")) != pickup_id:
			continue
		var resource_id := str(pickup.get("resource_id", ""))
		var pickup_kind := str(pickup.get("pickup_kind", "resource"))
		var remaining_amount := maxi(0, int(pickup.get("amount", 0)))
		var carry_amount := mini(remaining_amount, expedition_cargo_remaining())
		if resource_id.is_empty() or carry_amount <= 0:
			return {}
		if pickup_kind == "guardian_reward":
			var guardian_id := str(pickup.get("node_id", ""))
			var guardian_definition := ContentRegistry.guardian_definition(guardian_id)
			var defeated_guardians: Array = expedition_run.get("defeated_guardian_ids", [])
			if guardian_definition.is_empty() or not defeated_guardians.has(guardian_id) or str(guardian_definition.get("reward_id", "")) != resource_id:
				return {}
		var cargo: Dictionary = expedition_run.get("cargo", {})
		cargo[resource_id] = int(cargo.get(resource_id, 0)) + carry_amount
		expedition_run["cargo"] = cargo
		remaining_amount -= carry_amount
		if remaining_amount <= 0:
			pickups.remove_at(index)
		else:
			pickup["amount"] = remaining_amount
			pickups[index] = pickup
		expedition_run["pickups"] = pickups
		var discovery_id := str(pickup.get("discovery_id", ""))
		if pickup_kind == "guardian_reward":
			state_changed.emit()
			return {"pickup_id": pickup_id, "pickup_kind": pickup_kind, "resource_id": resource_id, "resource_label": str(pickup.get("resource_label", resource_id.capitalize())), "amount": carry_amount, "remaining": remaining_amount, "discovery_id": discovery_id}
		if not discovery_id.is_empty():
			record_discovery(discovery_id)
		# Discovery-tagged resources still count toward their normal route quota.
		_advance_expedition_objective("resource", resource_id, carry_amount)
		# Pickup resolution is the authoritative reward boundary. The scene may
		# animate the bundle and display the result, but it cannot mint XP or
		# mastery after the durable cargo mutation has been accepted.
		award_xp(carry_amount * 2)
		award_mastery("Mining" if resource_id in ["stone", "ore", "sunstone"] else "Foraging", carry_amount * 3)
		advance_first_run("resource_collected")
		state_changed.emit()
		return {"pickup_id": pickup_id, "resource_id": resource_id, "resource_label": str(pickup.get("resource_label", resource_id.capitalize())), "amount": carry_amount, "remaining": remaining_amount, "discovery_id": discovery_id}
	return {}

func record_expedition_contact(node_id: String, contacts_done: int) -> bool:
	if not has_active_expedition() or node_id.is_empty() or contacts_done <= 0 or contacts_done > 100:
		return false
	var descriptor: Dictionary = resource_node_catalog.get(node_id, {})
	if resource_contract_required and (descriptor.is_empty() or str(descriptor.get("zone_id", "")) != str(expedition_run.get("biome_id", "")) or contacts_done >= int(descriptor.get("required_contacts", 1))):
		return false
	var depleted: Array = expedition_run.get("depleted_ids", [])
	if depleted.has(node_id):
		return false
	var contact_progress: Dictionary = expedition_run.get("contact_progress", {})
	var previous := int(contact_progress.get(node_id, 0))
	if (resource_contract_required and contacts_done != previous + 1) or (not resource_contract_required and contacts_done <= previous):
		return false
	contact_progress[node_id] = contacts_done
	expedition_run["contact_progress"] = contact_progress
	award_mastery("Foraging", 1)
	state_changed.emit()
	return true

func complete_expedition_resource(node_id: String, resource_id: String, amount: int, required_contacts: int = 1) -> bool:
	var is_whisperglass_capstone := resource_id == "berries" and node_id.to_lower().contains("whisperglass")
	var pickup := harvest_expedition_resource(node_id, resource_id, amount, required_contacts)
	if pickup.is_empty():
		return false
	var collected := not collect_expedition_pickup(str(pickup.get("pickup_id", ""))).is_empty()
	if collected and is_whisperglass_capstone:
		_advance_expedition_objective("discovery", "Whisperglass", 1)
	return collected

func mark_sanctuary_depleted(node_id: String) -> bool:
	if node_id.is_empty() or sanctuary_depleted_ids.has(node_id):
		return false
	sanctuary_depleted_ids.append(node_id)
	sanctuary_contact_progress.erase(node_id)
	state_changed.emit()
	return true

func resolve_sanctuary_harvest(node_id: String, resource_id: String, amount: int, contacts_done: int = 1, required_contacts: int = 1) -> Dictionary:
	## Resolve the final contact as one domain transaction. Resource-node visuals
	## can show anticipation and depletion, but inventory, tool wear, energy, XP,
	## and mastery all settle here so a scene cannot award a second copy.
	if node_id.is_empty() or resource_id.is_empty() or amount <= 0 or contacts_done <= 0 or required_contacts <= 0 or contacts_done < required_contacts:
		return {}
	if not _resource_node_matches(node_id, resource_id, amount, required_contacts, "Sanctuary"):
		return {}
	if is_sanctuary_depleted(node_id) or energy <= 0 or not can_use_tool_for_resource(resource_id):
		return {}
	var previous_contacts := int(sanctuary_contact_progress.get(node_id, 0))
	if contacts_done > 1 and previous_contacts != contacts_done - 1:
		return {}
	var action_id := "sanctuary:%d:%s:%s" % [day, node_id, resource_id]
	energy -= 1
	if not _consume_tool_durability(resource_id, action_id):
		energy += 1
		return {}
	if not mark_sanctuary_depleted(node_id):
		energy += 1
		return {}
	sanctuary_contact_progress.erase(node_id)
	inventory[resource_id] = int(inventory.get(resource_id, 0)) + amount
	var mastery_name := "Mining" if resource_id in ["stone", "ore", "sunstone"] else "Foraging"
	award_xp(amount * 2)
	award_mastery(mastery_name, amount * 3)
	state_changed.emit()
	return {"node_id": node_id, "resource_id": resource_id, "amount": amount, "mastery_id": mastery_name, "mastery_gain": amount * 3}

func is_sanctuary_depleted(node_id: String) -> bool:
	return not node_id.is_empty() and sanctuary_depleted_ids.has(node_id)

func record_sanctuary_contact(node_id: String, contacts_done: int) -> bool:
	if node_id.is_empty() or contacts_done <= 0 or contacts_done > 100 or sanctuary_depleted_ids.has(node_id):
		return false
	var descriptor: Dictionary = resource_node_catalog.get(node_id, {})
	if resource_contract_required and (descriptor.is_empty() or str(descriptor.get("zone_id", "")) != "Sanctuary" or contacts_done >= int(descriptor.get("required_contacts", 1))):
		return false
	var previous := int(sanctuary_contact_progress.get(node_id, 0))
	if (resource_contract_required and contacts_done != previous + 1) or (not resource_contract_required and contacts_done <= previous):
		return false
	sanctuary_contact_progress[node_id] = contacts_done
	award_mastery("Foraging", 1)
	state_changed.emit()
	return true

func restore_sanctuary_resources() -> void:
	if sanctuary_depleted_ids.is_empty():
		return
	sanctuary_depleted_ids.clear()
	sanctuary_contact_progress.clear()
	state_changed.emit()

func _structure_is_unique(structure_id: String) -> bool:
	return bool(ContentRegistry.structure_definition(structure_id).get("unique", true))

func structure_is_unique(structure_id: String) -> bool:
	return ContentRegistry.STRUCTURES.has(structure_id) and _structure_is_unique(structure_id)

func _structure_footprint(structure_id: String, rotation_quarter_turns := 0) -> Vector2i:
	var definition := ContentRegistry.structure_definition(structure_id)
	var footprint_data: Array = definition.get("footprint", [1, 1])
	var footprint := Vector2i(int(footprint_data[0]), int(footprint_data[1]))
	return Vector2i(footprint.y, footprint.x) if posmod(rotation_quarter_turns, 2) == 1 else footprint

func _structure_cells(structure_id: String, origin: Vector2i, rotation_quarter_turns := 0) -> Array[Vector2i]:
	return SettlementGrid.cells_for(origin, _structure_footprint(structure_id, rotation_quarter_turns))

func structure_blueprint_requirement(structure_id: String) -> String:
	return str(ContentRegistry.structure_definition(structure_id).get("requires_blueprint", ""))

func has_structure_blueprint(structure_id: String) -> bool:
	if not ContentRegistry.STRUCTURES.has(structure_id):
		return false
	var requirement := structure_blueprint_requirement(structure_id)
	return requirement.is_empty() or blueprints.has(requirement)

func can_place_structure(structure_id: String, cell: Array, rotation_quarter_turns := 0) -> bool:
	if not ContentRegistry.STRUCTURES.has(structure_id) or cell.size() < 2:
		return false
	if not _valid_integer(cell[0], SettlementGrid.MIN_X, SettlementGrid.MAX_X) or not _valid_integer(cell[1], SettlementGrid.MIN_Z, SettlementGrid.MAX_Z):
		return false
	if not has_structure_blueprint(structure_id):
		return false
	var origin := Vector2i(int(cell[0]), int(cell[1]))
	var normalized_rotation := posmod(rotation_quarter_turns, 4)
	var candidate_cells := _structure_cells(structure_id, origin, normalized_rotation)
	if not SettlementGrid.inside_bounds(candidate_cells):
		return false
	var candidate_access_cells := _structure_access_cells(structure_id, origin, normalized_rotation)
	for access_cell in candidate_access_cells:
		if _fixed_cell_occupied(access_cell):
			return false
	for candidate_cell in candidate_cells:
		if _fixed_cell_occupied(candidate_cell):
			return false
	for existing_id in structures:
		var existing: Dictionary = structures.get(existing_id, {})
		if str(existing.get("state", "removed")) == "removed":
			continue
		if str(existing.get("kind", "")) == structure_id and _structure_is_unique(structure_id):
			return false
		var existing_origin_data: Array = existing.get("cell", [])
		if existing_origin_data.size() < 2:
			continue
		var existing_kind := str(existing.get("kind", ""))
		var existing_origin := Vector2i(int(existing_origin_data[0]), int(existing_origin_data[1]))
		var existing_rotation := int(existing.get("rotation", 0))
		var existing_cells := _structure_cells(existing_kind, existing_origin, existing_rotation)
		var existing_access_cells := _structure_access_cells(existing_kind, existing_origin, existing_rotation)
		for candidate_cell in candidate_cells:
			if existing_cells.has(candidate_cell):
				return false
			if existing_access_cells.has(candidate_cell):
				return false
		for candidate_access_cell in candidate_access_cells:
			if existing_cells.has(candidate_access_cell):
				return false
	return true

func _fixed_cell_occupied(cell: Vector2i) -> bool:
	for rect in FIXED_RESERVED_RECTS:
		if cell.x >= int(rect[0]) and cell.x <= int(rect[2]) and cell.y >= int(rect[1]) and cell.y <= int(rect[3]):
			return true
	for rect in ContentRegistry.ROUTE_RESERVED_RECTS:
		if cell.x >= int(rect[0]) and cell.x <= int(rect[2]) and cell.y >= int(rect[1]) and cell.y <= int(rect[3]):
			return true
	# Illustrated framing obstacles publish the same world transforms consumed by
	# SanctuaryStyle. A claimed one-metre grid cell is rejected when its physical
	# square intersects an authored build-clearance envelope; this prevents a
	# player structure from being accepted underneath a tree/rock that the live
	# camera will visibly occlude.
	var candidate_rect := Rect2(Vector2(float(cell.x) - 0.5, float(cell.y) - 0.5), Vector2.ONE)
	for obstacle_value in SanctuaryAssetCatalog.framing_placement_rects():
		if not (obstacle_value is Dictionary):
			continue
		var obstacle: Dictionary = obstacle_value
		var obstacle_rect: Rect2 = obstacle.get("rect", Rect2())
		if candidate_rect.intersects(obstacle_rect):
			return true
	return false

func _structure_access_cells(structure_id: String, origin: Vector2i, rotation_quarter_turns := 0) -> Array[Vector2i]:
	var access_cells: Array[Vector2i] = []
	var footprint := _structure_footprint(structure_id, rotation_quarter_turns)
	var center := SettlementGrid.footprint_center_to_world(origin, footprint)
	for zone_value in SanctuaryAssetCatalog.structure_access_zones(structure_id, rotation_quarter_turns):
		if not (zone_value is Dictionary):
			continue
		var zone: Dictionary = zone_value
		var zone_center: Array = zone.get("center", [])
		if zone_center.size() < 3:
			continue
		access_cells.append(SettlementGrid.world_to_cell(center + Vector3(float(zone_center[0]), 0.0, float(zone_center[2]))))
	return access_cells

func place_structure(structure_id: String, cell: Array, rotation_quarter_turns := 0) -> Dictionary:
	if not can_place_structure(structure_id, cell, rotation_quarter_turns):
		return {}
	var definition := ContentRegistry.structure_definition(structure_id)
	var cost: Dictionary = definition.get("cost", {})
	var instance_number := structures.size() + 1
	var structure_id_instance := "%s_%03d" % [structure_id, instance_number]
	while structures.has(structure_id_instance):
		instance_number += 1
		structure_id_instance = "%s_%03d" % [structure_id, instance_number]
	var delivered_materials := {}
	for material_id in cost:
		delivered_materials[str(material_id)] = 0
	var structure_record := {"id": structure_id_instance, "kind": structure_id, "cell": [int(cell[0]), int(cell[1])], "rotation": posmod(rotation_quarter_turns, 4), "state": "blueprint", "remaining_hours": 0.0, "total_hours": float(definition.get("hours", 24.0)), "delivered_materials": delivered_materials}
	if structure_id == "workshop":
		structure_record["interior_layout"] = ContentRegistry.interior_layout(structure_id)
	structures[structure_id_instance] = structure_record
	state_changed.emit()
	return structures[structure_id_instance].duplicate(true)

func _workshop_shell_ready(structure_id: String) -> bool:
	if structure_id.is_empty() or not structures.has(structure_id):
		return false
	var structure: Dictionary = structures.get(structure_id, {})
	return str(structure.get("kind", "")) == "workshop" and str(structure.get("state", "")) == "operational"

func can_place_interior_station(structure_id: String, station_kind: String, local_cell: Array, rotation_quarter_turns := 0, player_cell := []) -> bool:
	if not _workshop_shell_ready(structure_id) or not ContentRegistry.INTERIOR_STATIONS.has(station_kind):
		return false
	if local_cell.size() < 2:
		return false
	for component in local_cell.slice(0, 2):
		if not _valid_integer(component, -32, 32):
			return false
	if not _valid_integer(rotation_quarter_turns, 0, 3):
		return false
	var origin := Vector2i(int(local_cell[0]), int(local_cell[1]))
	var rotation := int(rotation_quarter_turns)
	var definition := ContentRegistry.interior_station_definition(station_kind)
	if str(definition.get("structure_kind", "")) != "workshop":
		return false
	var footprint := ContentRegistry.interior_station_footprint(station_kind, rotation)
	if footprint == Vector2i.ZERO:
		return false
	var existing: Dictionary = interior_stations.get(structure_id, {})
	var blocked: Array = []
	for existing_id in existing:
		var existing_record: Variant = existing.get(existing_id, {})
		if not (existing_record is Dictionary):
			return false
		var existing_cell_value: Variant = existing_record.get("cell", [])
		if not (existing_cell_value is Array):
			return false
		var existing_cell: Array = existing_cell_value
		if existing_cell.size() < 2:
			return false
		var existing_kind := str(existing_record.get("kind", ""))
		var existing_footprint := ContentRegistry.interior_station_footprint(existing_kind, int(existing_record.get("rotation", 0)))
		if existing_footprint == Vector2i.ZERO:
			return false
		if bool(definition.get("unique", true)) and existing_kind == station_kind:
			return false
		for cell_value in InteriorGrid.cells_for(Vector2i(int(existing_cell[0]), int(existing_cell[1])), existing_footprint):
			blocked.append(cell_value)
	var requested_player_cell := Vector2i(2147483647, 2147483647)
	if player_cell is Array and player_cell.size() >= 2:
		requested_player_cell = Vector2i(int(player_cell[0]), int(player_cell[1]))
	var layout := _interior_layout_for_structure(structure_id)
	return InteriorGrid.can_place(origin, footprint, _layout_room_size(layout), _layout_float(layout, "door_width", 1.45), blocked, requested_player_cell, _layout_door_facing(layout), _layout_float(layout, "cell_size", 1.0), _layout_float(layout, "wall_clearance", 0.45), _layout_float(layout, "door_clearance_depth", 0.85))

func set_interior_layout(structure_id: String, layout: Dictionary) -> bool:
	if not _workshop_shell_ready(structure_id) or not _interior_layout_is_supported(layout):
		return false
	var structure: Dictionary = structures.get(structure_id, {}).duplicate(true)
	structure["interior_layout"] = layout.duplicate(true)
	structures[structure_id] = structure
	state_changed.emit()
	return true

func interior_layout_for_structure(structure_id: String) -> Dictionary:
	return _interior_layout_for_structure(structure_id).duplicate(true)

func _interior_layout_for_structure(structure_id: String) -> Dictionary:
	var structure: Dictionary = structures.get(structure_id, {})
	return _interior_layout_from_structure(structure)

func _interior_layout_from_structure(structure: Dictionary) -> Dictionary:
	var saved_layout: Variant = structure.get("interior_layout", {})
	if saved_layout is Dictionary and _interior_layout_is_supported(saved_layout):
		return saved_layout.duplicate(true)
	return ContentRegistry.interior_layout("workshop")

func _interior_layout_is_supported(layout: Dictionary) -> bool:
	var room_value: Variant = layout.get("room_size", [])
	if not (room_value is Array) or (room_value as Array).size() < 2:
		return false
	return _valid_number(room_value[0], 3.4, 64.0) and _valid_number(room_value[1], 3.0, 64.0) and _valid_number(layout.get("door_width", 1.45), 0.95, 63.0) and _valid_number(layout.get("cell_size", 1.0), 0.1, 4.0) and _valid_number(layout.get("wall_clearance", 0.45), 0.0, 4.0) and _valid_number(layout.get("door_clearance_depth", 0.85), 0.0, 8.0)

func _layout_room_size(layout: Dictionary) -> Vector2:
	var room_value: Array = layout.get("room_size", [8.2, 6.2])
	return Vector2(float(room_value[0]), float(room_value[1]))

func _layout_float(layout: Dictionary, key: String, fallback: float) -> float:
	return float(layout.get(key, fallback))

func _layout_door_facing(layout: Dictionary) -> Vector3:
	var facing_value: Variant = layout.get("door_facing", [0.0, 0.0, 1.0])
	if facing_value is Array and (facing_value as Array).size() >= 3:
		var facing := Vector3(float(facing_value[0]), float(facing_value[1]), float(facing_value[2]))
		if facing.length_squared() > 0.01:
			return facing.normalized()
	return Vector3(0.0, 0.0, 1.0)

func place_interior_station(structure_id: String, station_kind: String, local_cell: Array, rotation_quarter_turns := 0, player_cell := []) -> Dictionary:
	if not can_place_interior_station(structure_id, station_kind, local_cell, rotation_quarter_turns, player_cell):
		return {}
	var existing: Dictionary = interior_stations.get(structure_id, {}).duplicate(true)
	var serial := existing.size() + 1
	var station_id := "%s_%03d" % [station_kind, serial]
	while existing.has(station_id):
		serial += 1
		station_id = "%s_%03d" % [station_kind, serial]
	var definition := ContentRegistry.interior_station_definition(station_kind)
	var delivered := {}
	for material_id in definition.get("cost", {}):
		delivered[str(material_id)] = 0
	existing[station_id] = {"id": station_id, "structure_id": structure_id, "kind": station_kind, "cell": [int(local_cell[0]), int(local_cell[1])], "rotation": posmod(rotation_quarter_turns, 4), "state": "blueprint", "remaining_hours": 0.0, "total_hours": float(definition.get("hours", 12.0)), "delivered_materials": delivered}
	interior_stations[structure_id] = existing
	state_changed.emit()
	return existing[station_id].duplicate(true)

func interior_station_status(structure_id: String, station_id: String) -> Dictionary:
	var station: Variant = interior_stations.get(structure_id, {}).get(station_id, {})
	return station.duplicate(true) if station is Dictionary else {}

func deliver_interior_station_material(structure_id: String, station_id: String, material_id: String, amount: int = 1) -> Dictionary:
	if not _workshop_shell_ready(structure_id) or station_id.is_empty() or material_id.is_empty() or amount <= 0:
		return {}
	var stations_for_structure: Dictionary = interior_stations.get(structure_id, {})
	var station: Variant = stations_for_structure.get(station_id, {})
	if not (station is Dictionary) or str(station.get("state", "")) != "blueprint":
		return {}
	var kind := str(station.get("kind", ""))
	var definition := ContentRegistry.interior_station_definition(kind)
	var cost: Dictionary = definition.get("cost", {})
	if definition.is_empty() or not cost.has(material_id):
		return {}
	var delivered: Dictionary = station.get("delivered_materials", {}).duplicate(true)
	var required := int(cost.get(material_id, 0))
	var already_delivered := int(delivered.get(material_id, 0))
	var delivered_amount := mini(amount, maxi(0, required - already_delivered))
	if delivered_amount <= 0 or int(inventory.get(material_id, 0)) < delivered_amount:
		return {}
	inventory[material_id] = int(inventory.get(material_id, 0)) - delivered_amount
	delivered[material_id] = already_delivered + delivered_amount
	station["delivered_materials"] = delivered
	var complete := true
	for required_material in cost:
		if int(delivered.get(str(required_material), 0)) < int(cost[required_material]):
			complete = false
			break
	if complete:
		station["state"] = "building"
		station["remaining_hours"] = float(definition.get("hours", 12.0))
		station["total_hours"] = float(definition.get("hours", 12.0))
	stations_for_structure[station_id] = station
	interior_stations[structure_id] = stations_for_structure
	state_changed.emit()
	return station.duplicate(true)

func has_station_capability(structure_id := "", capability_id := "", station_id := "") -> bool:
	for parent_id in interior_stations:
		if not structure_id.is_empty() and str(parent_id) != structure_id:
			continue
		if not _workshop_shell_ready(str(parent_id)):
			continue
		var stations_for_structure: Dictionary = interior_stations.get(parent_id, {})
		for candidate_id in stations_for_structure:
			if not station_id.is_empty() and str(candidate_id) != station_id:
				continue
			var station: Variant = stations_for_structure.get(candidate_id, {})
			if station is Dictionary and str(station.get("state", "")) == "operational":
				var definition := ContentRegistry.interior_station_definition(str(station.get("kind", "")))
				if capability_id.is_empty() or str(definition.get("capability", "")) == capability_id:
					return true
	return false

func station_binding_for_capability(capability_id: String, requested_station_id := "", requested_structure_id := "") -> Dictionary:
	if capability_id.is_empty() or (not requested_station_id.is_empty() and requested_structure_id.is_empty()):
		return {}
	for parent_id in interior_stations:
		if not requested_structure_id.is_empty() and str(parent_id) != requested_structure_id:
			continue
		if not _workshop_shell_ready(str(parent_id)):
			continue
		for candidate_id in interior_stations.get(parent_id, {}):
			if not requested_station_id.is_empty() and str(candidate_id) != requested_station_id:
				continue
			var station: Variant = interior_stations[parent_id].get(candidate_id, {})
			if not (station is Dictionary) or str(station.get("state", "")) != "operational":
				continue
			var definition := ContentRegistry.interior_station_definition(str(station.get("kind", "")))
			if str(definition.get("capability", "")) == capability_id:
				return {"structure_id": str(parent_id), "station_id": str(candidate_id)}
	return {}

func workshop_station_id() -> String:
	return str(workshop_station_binding().get("station_id", ""))

func workshop_station_binding(requested_station_id := "", requested_structure_id := "") -> Dictionary:
	return station_binding_for_capability("workshop_crafting", requested_station_id, requested_structure_id)

func deliver_structure_material(instance_id: String, material_id: String, amount: int = 1) -> Dictionary:
	if instance_id.is_empty() or material_id.is_empty() or amount <= 0 or not structures.has(instance_id):
		return {}
	var structure: Dictionary = structures.get(instance_id, {})
	if str(structure.get("state", "removed")) != "blueprint":
		return {}
	var kind := str(structure.get("kind", ""))
	var definition := ContentRegistry.structure_definition(kind)
	var cost: Dictionary = definition.get("cost", {})
	if not cost.has(material_id):
		return {}
	var delivered: Dictionary = structure.get("delivered_materials", {}).duplicate(true)
	var required := int(cost.get(material_id, 0))
	var already_delivered := int(delivered.get(material_id, 0))
	var remaining := maxi(0, required - already_delivered)
	var delivered_amount := mini(amount, remaining)
	if delivered_amount <= 0 or int(inventory.get(material_id, 0)) < delivered_amount:
		return {}
	# Remove and record the same amount in one authoritative transaction.
	inventory[material_id] = int(inventory.get(material_id, 0)) - delivered_amount
	delivered[material_id] = already_delivered + delivered_amount
	structure["delivered_materials"] = delivered
	var complete := true
	for required_material in cost:
		if int(delivered.get(str(required_material), 0)) < int(cost[required_material]):
			complete = false
			break
	if complete:
		structure["state"] = "building"
		structure["remaining_hours"] = float(definition.get("hours", 24.0))
		structure["total_hours"] = float(definition.get("hours", 24.0))
	structures[instance_id] = structure
	if complete:
		# Publish only after the delivered frame is visible to all observers.
		award_mastery("Crafting", 8)
	else:
		state_changed.emit()
	return structure.duplicate(true)

func award_expedition_loot(resource_id: String, amount: int) -> bool:
	if not has_active_expedition() or resource_id.is_empty() or amount <= 0:
		return false
	if not can_carry_expedition_amount(amount):
		return false
	var cargo: Dictionary = expedition_run.get("cargo", {})
	cargo[resource_id] = int(cargo.get(resource_id, 0)) + amount
	expedition_run["cargo"] = cargo
	state_changed.emit()
	return true

func first_run_stage() -> String:
	if bool(quest.get("first_run_completed", false)):
		return "complete"
	var stage := str(quest.get("first_run_stage", "meet_mira"))
	if not FIRST_RUN_STAGES.has(stage):
		stage = "meet_mira"
		quest["first_run_stage"] = stage
	return stage

func advance_first_run(event_id: String) -> bool:
	var stage := first_run_stage()
	if stage == "complete":
		return false
	var next_stage := ""
	match stage:
		"meet_mira":
			if event_id == "meet_mira":
				next_stage = "reach_gate"
		"reach_gate":
			if event_id == "enter_whisperwood":
				next_stage = "choose_trail"
		"choose_trail":
			if event_id == "choose_trail":
				next_stage = "gather"
		"gather":
			if event_id == "field_bundle" or event_id == "resource_collected":
				next_stage = "collect_bundle"
		"collect_bundle":
			if event_id == "resource_collected":
				next_stage = "extract"
		"extract":
			if event_id == "extract":
				next_stage = "claim_supply"
		"claim_supply":
			if event_id == "claim_supply":
				next_stage = "build_workshop"
		"build_workshop":
			if event_id == "workshop_operational":
				next_stage = "complete"
	if next_stage.is_empty():
		return false
	quest["first_run_stage"] = next_stage
	quest["first_run_completed"] = next_stage == "complete"
	feedback_requested.emit("onboarding", {"stage": next_stage, "event": event_id})
	state_changed.emit()
	return true

func mark_guardian_defeated(guardian_id: String) -> bool:
	if not has_active_expedition() or guardian_id.is_empty():
		return false
	var defeated: Array = expedition_run.get("defeated_guardian_ids", [])
	if defeated.has(guardian_id):
		return false
	defeated.append(guardian_id)
	expedition_run["defeated_guardian_ids"] = defeated
	var guardian_states: Dictionary = expedition_run.get("guardian_states", {}) if expedition_run.get("guardian_states", {}) is Dictionary else {}
	guardian_states.erase(guardian_id)
	expedition_run["guardian_states"] = guardian_states
	state_changed.emit()
	return true

func record_guardian_combat_state(guardian_id: String, health_value: int, position: Array) -> bool:
	if not has_active_expedition() or guardian_id.is_empty() or position.size() < 3:
		return false
	var expedition_biome := str(expedition_run.get("biome_id", ""))
	var definition := ContentRegistry.guardian_definition(guardian_id)
	if definition.is_empty() or str(definition.get("zone_id", "")) != expedition_biome:
		return false
	var expedition_branch := str(expedition_run.get("branch_id", ""))
	if expedition_branch.is_empty() or _route_objective_is_off_branch("guardian", guardian_id):
		return false
	var defeated: Variant = expedition_run.get("defeated_guardian_ids", [])
	if defeated is Array and defeated.has(guardian_id):
		return false
	var max_guardian_health := maxi(1, int(definition.get("health", 1)))
	if health_value < 1 or health_value > max_guardian_health:
		return false
	for coordinate in position.slice(0, 3):
		if not _valid_number(coordinate, -100000.0, 100000.0):
			return false
	var guardian_states: Dictionary = expedition_run.get("guardian_states", {}) if expedition_run.get("guardian_states", {}) is Dictionary else {}
	guardian_states[guardian_id] = {
		"health": health_value,
		"position": [clampf(float(position[0]), -EXPEDITION_ANCHOR_LIMIT_X, EXPEDITION_ANCHOR_LIMIT_X), 1.0, clampf(float(position[2]), -EXPEDITION_ANCHOR_LIMIT_Z, EXPEDITION_ANCHOR_LIMIT_Z)],
	}
	expedition_run["guardian_states"] = guardian_states
	state_changed.emit()
	return true

func resolve_guardian_defeat(guardian_id: String) -> Dictionary:
	if not has_active_expedition() or guardian_id.is_empty():
		return {}
	# Authored guardians belong to a committed trail. Resolving one before the
	# fork would consume the encounter without assigning its objective progress.
	var route_id := str(expedition_run.get("biome_id", ""))
	if not ContentRegistry.expedition_branch_ids(route_id).is_empty() and str(expedition_run.get("branch_id", "")).is_empty():
		return {}
	if _route_objective_is_off_branch("guardian", guardian_id):
		return {}
	var definition := ContentRegistry.guardian_definition(guardian_id)
	if definition.is_empty() or str(definition.get("zone_id", "")) != str(expedition_run.get("biome_id", "")):
		return {}
	var defeated: Array = expedition_run.get("defeated_guardian_ids", [])
	if defeated.has(guardian_id):
		return {}
	var reward_id := str(definition.get("reward_id", ""))
	var reward_amount := int(definition.get("reward_amount", 0))
	if reward_id.is_empty() or reward_amount <= 0:
		return {}
	var hunt_action_id := "guardian:%s:%s" % [str(expedition_run.get("run_id", "")), guardian_id]
	var can_carry_reward := can_carry_expedition_amount(reward_amount)
	var trophy_drop := false
	if can_carry_reward:
		trophy_drop = resolve_mastery_chance("hunting_apex_hunter", "trophy_drop_chance", hunt_action_id)
		if trophy_drop and can_carry_expedition_amount(reward_amount + 1):
			reward_amount += 1
		else:
			# A lucky bonus is optional; it must never invalidate the base guardian
			# reward when the satchel has room for the authored drop but not the trophy.
			trophy_drop = false
	defeated.append(guardian_id)
	var cargo: Dictionary = expedition_run.get("cargo", {})
	expedition_run["defeated_guardian_ids"] = defeated
	var guardian_states: Dictionary = expedition_run.get("guardian_states", {}) if expedition_run.get("guardian_states", {}) is Dictionary else {}
	guardian_states.erase(guardian_id)
	expedition_run["guardian_states"] = guardian_states
	var deferred_pickup := false
	var pickup_id := "guardian:%s:%s:reward" % [str(expedition_run.get("run_id", "")), guardian_id]
	if can_carry_reward:
		cargo[reward_id] = int(cargo.get(reward_id, 0)) + reward_amount
		expedition_run["cargo"] = cargo
	else:
		# A guardian must never vanish because the satchel is full. Defeat is
		# durable, while the authored reward becomes a physical, recoverable drop
		# at the latest persisted expedition anchor.
		var pickups: Array = expedition_run.get("pickups", [])
		var anchor: Variant = expedition_run.get("anchor", [0.0, 1.0, 0.0])
		var drop_position := [0.0, 1.0, 0.0]
		if anchor is Array and anchor.size() >= 3:
			drop_position = [float(anchor[0]), 1.0, float(anchor[2])]
		pickups.append({"pickup_id": pickup_id, "pickup_kind": "guardian_reward", "node_id": guardian_id, "resource_id": reward_id, "resource_label": reward_id.replace("_", " ").capitalize(), "discovery_id": "", "amount": reward_amount, "position": drop_position})
		expedition_run["pickups"] = pickups
		deferred_pickup = true
	var route_definition := expedition_route_definition()
	if str(route_definition.get("objective_kind", "")) == "guardian" and str(route_definition.get("objective_id", "")) == guardian_id:
		_advance_expedition_objective("guardian", guardian_id, 1)
	award_xp(18)
	award_mastery("Attacking", 12)
	award_mastery("Hunting", 8)
	state_changed.emit()
	return {"guardian_id": guardian_id, "reward_id": reward_id, "reward_amount": reward_amount, "trophy_drop": trophy_drop, "deferred_pickup": deferred_pickup, "pickup_id": pickup_id if deferred_pickup else ""}

func use_expedition_camp() -> bool:
	if not has_active_expedition() or bool(expedition_run.get("camp_used", false)):
		return false
	expedition_run["camp_used"] = true
	energy = mini(max_energy, energy + 6 + permission_effect_int("surviving_campcraft", "camp_energy_bonus", 0))
	state_changed.emit()
	return true

func progress_quest(amount: int) -> void:
	if amount <= 0 or bool(quest.get("claimed", false)):
		return
	quest["progress"] = mini(int(quest.get("target", 5)), int(quest.get("progress", 0)) + amount)
	state_changed.emit()

func claim_quest() -> bool:
	if bool(quest.get("claimed", false)) or int(quest.get("progress", 0)) < int(quest.get("target", 5)):
		return false
	quest["claimed"] = true
	coins += 45
	award_xp(25)
	advance_first_run("claim_supply")
	state_changed.emit()
	return true

func finish_expedition(extraction_zone_id: String = "", extraction_position: Array = []) -> Dictionary:
	if not has_active_expedition():
		return {}
	if expedition_return_checkpoint_required():
		return {}
	if resource_contract_required:
		var expedition_zone := str(expedition_run.get("biome_id", ""))
		if extraction_zone_id != expedition_zone or extraction_position.size() < 3:
			return {}
		for value in extraction_position.slice(0, 3):
			if not (value is int or value is float) or not is_finite(float(value)):
				return {}
		if Vector2(float(extraction_position[0]), float(extraction_position[2])).distance_to(Vector2(0.0, 7.5)) > 2.8:
			return {}
	var cargo: Dictionary = expedition_run.get("cargo", {}).duplicate(true)
	var completed_run: Dictionary = expedition_run.duplicate(true)
	var cargo_count := 0
	for resource_id in cargo:
		var amount := int(cargo[resource_id])
		if amount > 0:
			inventory[str(resource_id)] = int(inventory.get(str(resource_id), 0)) + amount
			cargo_count += amount
	if cargo_count > 0 and not bool(quest.get("claimed", false)):
		quest["progress"] = mini(int(quest.get("target", 5)), int(quest.get("progress", 0)) + cargo_count)
	if str(completed_run.get("biome_id", "")) == "Whisperwood":
		advance_first_run("extract")
	_unlock_route_after_extraction(completed_run, cargo)
	expedition_run = _empty_expedition_run()
	state_changed.emit()
	return cargo

func update_expedition_anchor(run_id: String, position: Array) -> bool:
	if not has_active_expedition() or str(expedition_run.get("run_id", "")) != run_id or position.size() < 3:
		return false
	for value in position.slice(0, 3):
		if not (value is int or value is float) or not is_finite(float(value)):
			return false
	var anchor := [clampf(float(position[0]), -EXPEDITION_ANCHOR_LIMIT_X, EXPEDITION_ANCHOR_LIMIT_X), 1.0, clampf(float(position[2]), -EXPEDITION_ANCHOR_LIMIT_Z, EXPEDITION_ANCHOR_LIMIT_Z)]
	expedition_run["anchor"] = anchor
	state_changed.emit()
	return true

func fail_expedition(position: Vector3) -> Dictionary:
	if not has_active_expedition():
		return {}
	var cargo: Dictionary = expedition_run.get("cargo", {}).duplicate(true)
	var run_id := str(expedition_run.get("run_id", "run"))
	var lost: Dictionary = {}
	for resource_id in cargo:
		var amount := int(cargo[resource_id])
		var lost_amount := int(amount / 2)
		var kept_amount := amount - lost_amount
		if kept_amount > 0:
			add_item(str(resource_id), kept_amount)
		if lost_amount > 0:
			lost[resource_id] = lost_amount
	var biome_id := str(expedition_run.get("biome_id", "Whisperwood"))
	var new_recovery_pack := {}
	if not lost.is_empty():
		recovery_pack = {"pack_id": "recovery_%s" % run_id, "zone_id": biome_id, "loot": lost, "position": [position.x, position.y, position.z], "expires_day": day + 1}
		new_recovery_pack = recovery_pack.duplicate(true)
	expedition_run = _empty_expedition_run()
	health = max_health
	state_changed.emit()
	return new_recovery_pack

func claim_recovery_pack(pack_id: String, zone_id: String) -> Dictionary:
	if pack_id.is_empty() or recovery_pack.is_empty():
		return {}
	if str(recovery_pack.get("pack_id", "")) != pack_id or str(recovery_pack.get("zone_id", "")) != zone_id:
		return {}
	if int(recovery_pack.get("expires_day", day + 1)) <= day:
		recovery_pack = {}
		state_changed.emit()
		return {}
	var loot: Variant = recovery_pack.get("loot", {})
	if not (loot is Dictionary) or loot.is_empty():
		return {}
	for resource_id in loot:
		if str(resource_id).is_empty() or not _valid_integer(loot[resource_id], 1, 2147483647):
			return {}
	for resource_id in loot:
		inventory[str(resource_id)] = int(inventory.get(str(resource_id), 0)) + int(loot[resource_id])
	recovery_pack = {}
	state_changed.emit()
	return loot.duplicate(true)

func claim_recovery_pack_to_expedition(pack_id: String, zone_id: String) -> Dictionary:
	if not has_active_expedition() or str(expedition_run.get("biome_id", "")) != zone_id:
		return {}
	if pack_id.is_empty() or recovery_pack.is_empty() or str(recovery_pack.get("pack_id", "")) != pack_id or str(recovery_pack.get("zone_id", "")) != zone_id:
		return {}
	if int(recovery_pack.get("expires_day", day + 1)) <= day:
		recovery_pack = {}
		state_changed.emit()
		return {}
	var loot: Variant = recovery_pack.get("loot", {})
	if not (loot is Dictionary) or loot.is_empty():
		return {}
	var total := 0
	for resource_id in loot:
		if str(resource_id).is_empty() or not _valid_integer(loot[resource_id], 1, 2147483647):
			return {}
		var amount := int(loot[resource_id])
		if amount <= 0:
			return {}
		total += amount
	if not can_carry_expedition_amount(total):
		return {}
	var cargo: Dictionary = expedition_run.get("cargo", {})
	for resource_id in loot:
		cargo[str(resource_id)] = int(cargo.get(str(resource_id), 0)) + int(loot[resource_id])
	expedition_run["cargo"] = cargo
	recovery_pack = {}
	state_changed.emit()
	return loot.duplicate(true)

func clear_expired_recovery_pack() -> bool:
	if recovery_pack.is_empty() or int(recovery_pack.get("expires_day", day + 1)) > day:
		return false
	recovery_pack = {}
	state_changed.emit()
	return true

func advance_day(target_day: int = -1) -> bool:
	# The target day is an idempotency key. Repeated calls in the same frame can
	# never grow crops or finish a job twice.
	if target_day < 0:
		target_day = day + 1
	if target_day != day + 1 or last_day_transaction >= target_day:
		return false
	last_day_transaction = target_day
	var previous_day := day
	day = target_day
	market_day = day
	market_trades.clear()
	market_contract_claimed_day = 0
	hour = 7.0
	energy = max_energy
	health = max_health
	nutrition = maxi(0, nutrition - 14)
	hydration = maxi(0, hydration - 18)
	if nutrition < 20 or hydration < 20:
		health = maxi(1, health - 8)
	if farm_plot["state"] == "planted":
		if farm_plot["watered"]:
			var growth_step := 1
			if has_permission("farming_field_rhythm"):
				growth_step += 1
			# Emberfall and Frostveil are a real seasonal pressure, not just HUD
			# flavor. Verdant Steward removes the penalty through the same
			# permission effect declared in ContentRegistry.
			if season in ["Emberfall", "Frostveil"]:
				var penalty_multiplier := 1.0
				if has_permission("farming_verdant_steward"):
					penalty_multiplier = clampf(permission_effect("farming_verdant_steward", "season_penalty_multiplier", 1.0), 0.0, 1.0)
				var seasonal_loss := int(floor(float(growth_step) * penalty_multiplier))
				growth_step = maxi(0, growth_step - seasonal_loss)
			farm_plot["growth"] = mini(3, int(farm_plot["growth"]) + growth_step)
		farm_plot["watered"] = false
	if station_job["kind"] != "none":
		station_job["remaining_hours"] = maxf(0.0, float(station_job["remaining_hours"]) - 12.0)
		if float(station_job["remaining_hours"]) <= 0.0:
			station_job["output"] = maxi(1, int(station_job["output"]))
	if str(research_job.get("status", "idle")) == "researching":
		# Sleep advances the overnight interval as one authoritative transaction;
		# the realtime clock handles the smaller intervals while the player is
		# awake.
		_advance_research_hours(24.0)
	if str(construction_job.get("status", "none")) == "building":
		construction_job["remaining_hours"] = maxf(0.0, float(construction_job.get("remaining_hours", 0.0)) - 12.0)
		var construction_total := maxf(1.0, float(construction_job.get("total_hours", 12.0)))
		construction_progress = 1.0 - clampf(float(construction_job["remaining_hours"]) / construction_total, 0.0, 1.0)
		if float(construction_job["remaining_hours"]) <= 0.0:
			construction_job["status"] = "ready"
	for animal_id in livestock:
		var animal: Dictionary = livestock.get(animal_id, {})
		var hunger_drain := 16
		if has_permission("livestock_feed_stretch"):
			hunger_drain = maxi(1, int(ceil(float(hunger_drain) / 1.25)))
		animal["hunger"] = maxi(0, int(animal.get("hunger", 0)) - hunger_drain)
		animal["production_ready"] = int(animal.get("last_fed_day", 0)) == previous_day and int(animal.get("hunger", 0)) >= 45
		if int(animal.get("hunger", 0)) <= 15:
			animal["health"] = maxi(1, int(animal.get("health", 0)) - 8)
		livestock[animal_id] = animal
	for structure_id in structures:
		var structure: Dictionary = structures.get(structure_id, {})
		if str(structure.get("state", "removed")) == "building":
			structure["remaining_hours"] = maxf(0.0, float(structure.get("remaining_hours", 0.0)) - 12.0)
			if float(structure.get("remaining_hours", 0.0)) <= 0.0:
				structure["state"] = "operational"
				_activate_structure_kind(str(structure.get("kind", "")))
		elif str(structure.get("state", "removed")) == "operational" and str(structure.get("kind", "")) == "rain_cistern":
			inventory["water"] = int(inventory.get("water", 0)) + 2
		structures[structure_id] = structure
	var workbench_became_operational := false
	for parent_id in interior_stations:
		var stations_for_structure: Dictionary = interior_stations.get(parent_id, {})
		for station_id in stations_for_structure:
			var station: Variant = stations_for_structure.get(station_id, {})
			if not (station is Dictionary) or str(station.get("state", "")) != "building":
				continue
			station["remaining_hours"] = maxf(0.0, float(station.get("remaining_hours", 0.0)) - 12.0)
			if float(station.get("remaining_hours", 0.0)) <= 0.0:
				station["state"] = "operational"
				if str(station.get("kind", "")) == "workbench":
					workbench_became_operational = true
			stations_for_structure[station_id] = station
		interior_stations[parent_id] = stations_for_structure
	_recalculate_structure_effects()
	if workbench_became_operational:
		advance_first_run("workshop_operational")
	var saved_first_run_stage := first_run_stage()
	if bool(quest.get("claimed", false)):
		quest = {"id": "supply_run_%d" % day, "title": "NEXT SUPPLY RUN", "description": "Return from an expedition with 5 cargo.", "progress": 0, "target": 5, "claimed": false, "first_run_stage": saved_first_run_stage, "first_run_completed": saved_first_run_stage == "complete"}
	season = ["Verdant", "Suncrest", "Emberfall", "Frostveil"][int((day - 1) / 7) % 4]
	weather = "rain" if day % 4 == 0 else "clear"
	if not recovery_pack.is_empty() and int(recovery_pack.get("expires_day", day + 1)) <= day:
		recovery_pack = {}
	# Sanctuary resources reset as part of the idempotent daily transaction,
	# not as a second presentation-side mutation.
	sanctuary_depleted_ids.clear()
	sanctuary_contact_progress.clear()
	state_changed.emit()
	return true

func _activate_structure_kind(kind: String) -> void:
	match kind:
		"archive": built["library"] = true
		"livestock_pen": built["livestock_pen"] = true
	_recalculate_structure_effects()

func _recalculate_structure_effects() -> void:
	var derived_capacity := BASE_CARGO_CAPACITY
	var has_workbench := false
	var has_archive := false
	var has_livestock_pen := false
	for structure_id in structures:
		var structure: Dictionary = structures.get(structure_id, {})
		if str(structure.get("state", "")) != "operational":
			continue
		var structure_kind := str(structure.get("kind", ""))
		if structure_kind == "workshop":
			has_workbench = has_workbench or has_station_capability(str(structure_id), "workshop_crafting")
		elif structure_kind == "archive":
			has_archive = true
		elif structure_kind == "livestock_pen":
			has_livestock_pen = true
		var definition := ContentRegistry.structure_definition(structure_kind)
		derived_capacity += int(definition.get("cargo_bonus", 0))
		if structure_kind == "workshop":
			var fitout: Dictionary = interior_stations.get(str(structure_id), {})
			for station_id in fitout:
				var station: Variant = fitout.get(station_id, {})
				if not (station is Dictionary) or str(station.get("state", "")) != "operational":
					continue
				var station_definition := ContentRegistry.interior_station_definition(str(station.get("kind", "")))
				derived_capacity += int(station_definition.get("cargo_bonus", 0))
	# Workshop capability is derived exclusively from a placed operational shell
	# with an operational Workbench.  A stale boolean must never create an
	# invisible crafting station.
	built["workshop"] = has_workbench
	if has_archive:
		built["library"] = true
	if has_livestock_pen:
		built["livestock_pen"] = true
	# Capacity has no downgrade path yet; retaining a larger loaded value keeps
	# old saves and in-progress expeditions safe while derived upgrades apply.
	cargo_capacity = maxi(cargo_capacity, derived_capacity)

func save_game() -> bool:
	if save_blocked:
		return false
	var payload := _to_dict()
	var user_dir := ProjectSettings.globalize_path("user://")
	DirAccess.make_dir_recursive_absolute(user_dir)
	var temp_path := _temp_path()
	var save_path := _save_path()
	var backup_path := _backup_path()
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	var payload_text := JSON.stringify(payload)
	file.store_string(payload_text)
	file.flush()
	file.close()
	var candidate := _read_json(temp_path)
	if candidate.is_empty() or int(candidate.get("save_version", 0)) != SAVE_VERSION or not _save_shape_is_supported(candidate):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		return false
	if FileAccess.file_exists(save_path):
		var previous_payload := _read_json(save_path)
		if previous_payload.is_empty() or int(previous_payload.get("save_version", 0)) > SAVE_VERSION or not _save_shape_is_supported(previous_payload):
			previous_payload = {}
		if previous_payload.is_empty():
			# Preserve an existing backup when the primary is malformed. A failed
			# or interrupted save must not destroy the last known-good checkpoint.
			pass
		else:
			var backup_file := FileAccess.open(backup_path, FileAccess.WRITE)
			if backup_file == null:
				DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
				return false
			backup_file.store_string(JSON.stringify(previous_payload))
			backup_file.flush()
			backup_file.close()
	var rename_result := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(save_path))
	# On macOS Godot can report an error after the rename has already happened.
	# Accept that case only when the temp path disappeared and the final file is
	# exactly the validated candidate. Never truncate the primary save as a
	# fallback: a partial write must be reported so the caller can roll back.
	var final_payload := _read_json(save_path)
	var final_file := FileAccess.open(save_path, FileAccess.READ)
	var final_text := final_file.get_as_text() if final_file != null else ""
	if final_file != null:
		final_file.close()
	# Parsed Dictionary equality is not a safe commit proof here: Godot can
	# normalize numeric JSON values differently after a successful rename even
	# though the bytes on disk are exactly the bytes we validated in the temp
	# file. Compare the serialized payload and revalidate its shape instead.
	var result: bool = not FileAccess.file_exists(temp_path) and final_text == payload_text and not final_payload.is_empty() and int(final_payload.get("save_version", 0)) == SAVE_VERSION and _save_shape_is_supported(final_payload)
	if not result and FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
	if result:
		state_changed.emit()
	return result

## Used by scene-level transactions that must be all-or-nothing when durable
## storage is unavailable. The returned dictionary is detached from live state.
func snapshot_state() -> Dictionary:
	return _to_dict().duplicate(true)

func restore_state(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	# Rollback snapshots are in-process transaction state. Unlike a disk load,
	# they may restore an active local timer so a failed durable commit does not
	# erase the player's real-life session.
	_apply_dict(snapshot, true)
	state_changed.emit()

func load_game() -> bool:
	var primary := _read_json(_save_path())
	var backup := _read_json(_backup_path())
	var has_primary_candidate := FileAccess.file_exists(_save_path())
	var has_backup_candidate := FileAccess.file_exists(_backup_path())
	var primary_future := not primary.is_empty() and (int(primary.get("save_version", 0)) > SAVE_VERSION or int(primary.get("content_version", 0)) > CONTENT_VERSION)
	# A compatible backup may be used for recovery, but an older build must not
	# overwrite a primary file written by a newer schema on its next autosave.
	# Keep this session read-only until the user explicitly chooses a migration
	# or a new slot.
	if primary_future:
		save_blocked = true
	var payload := {}
	var migrated_primary := _migrate_payload(primary)
	var migrated_backup := _migrate_payload(backup)
	if not migrated_primary.is_empty() and _save_shape_is_supported(migrated_primary):
		payload = migrated_primary
	elif not migrated_backup.is_empty() and _save_shape_is_supported(migrated_backup):
		# A valid backup is still usable when the primary is corrupt or was
		# written by a newer build we cannot safely interpret.
		payload = migrated_backup
	if payload.is_empty():
		var backup_future := not backup.is_empty() and (int(backup.get("save_version", 0)) > SAVE_VERSION or int(backup.get("content_version", 0)) > CONTENT_VERSION)
		if primary_future and (backup.is_empty() or backup_future):
			save_blocked = true
			load_status = "future"
			load_error = "A newer save schema is present and this build cannot safely interpret it."
		else:
			load_status = "rejected" if has_primary_candidate or has_backup_candidate else "fresh"
			load_error = "The save candidates were present but failed validation." if load_status == "rejected" else ""
		return false
	# Older saves intentionally fill new fields from the current defaults;
	# loading never replays old rewards or transactions.
	_apply_dict(payload)
	load_status = "loaded" if not migrated_primary.is_empty() and _save_shape_is_supported(migrated_primary) else "recovered"
	load_error = "" if load_status == "loaded" else "The primary save was unavailable; a validated backup was restored."
	state_changed.emit()
	return true

func _migrate_payload(raw: Dictionary) -> Dictionary:
	if raw.is_empty():
		return {}
	var version := int(raw.get("save_version", 0))
	if version <= 0 or version > SAVE_VERSION:
		return {}
	var data := raw.duplicate(true)
	# This marker is intentionally transient. It lets validation distinguish a
	# genuinely current save (which must contain every current-state field) from
	# a legacy payload that is being filled by the migration layer.
	data["_source_save_version"] = version
	# Versions 1–5 predate the current explicit run-contact and recovery-pack
	# fields. They remain readable, but are normalized before validation and
	# before any live state is applied.
	if version < 6:
		if not data.has("sanctuary_contact_progress"):
			data["sanctuary_contact_progress"] = {}
		var old_expedition: Variant = data.get("expedition_run", {})
		if old_expedition is Dictionary and not old_expedition.has("contact_progress"):
			old_expedition["contact_progress"] = {}
			data["expedition_run"] = old_expedition
		var old_recovery: Variant = data.get("recovery_pack", {})
		if old_recovery is Dictionary and not old_recovery.is_empty() and str(old_recovery.get("pack_id", "")).is_empty():
			old_recovery["pack_id"] = "recovery_legacy_%d" % int(data.get("day", 1))
		if old_recovery is Dictionary and not old_recovery.is_empty():
			if not old_recovery.has("zone_id"):
				old_recovery["zone_id"] = "Whisperwood"
			if not old_recovery.has("expires_day"):
				old_recovery["expires_day"] = int(data.get("day", 1)) + 1
			if not old_recovery.has("position"):
				old_recovery["position"] = [0.0, 1.0, 0.0]
			data["recovery_pack"] = old_recovery
	if version < 7:
		var old_structures: Variant = data.get("structures", {})
		if old_structures is Dictionary:
			for old_id in old_structures:
				var old_structure: Variant = old_structures.get(old_id, {})
				if not (old_structure is Dictionary):
					continue
				var old_kind := str(old_structure.get("kind", ""))
				var old_definition := ContentRegistry.structure_definition(old_kind)
				if old_definition.is_empty():
					continue
				var old_cost: Dictionary = old_definition.get("cost", {})
				if not old_structure.has("delivered_materials"):
					var assumed_delivered := {}
					for material_id in old_cost:
						assumed_delivered[str(material_id)] = int(old_cost[material_id])
					old_structure["delivered_materials"] = assumed_delivered
					# Before v7, a paid construction job could be serialized as a
					# blueprint even though its materials were already consumed. Move
					# that legacy state into the timed frame stage so it can finish.
					if str(old_structure.get("state", "")) == "blueprint":
						old_structure["state"] = "building"
						old_structure["remaining_hours"] = float(old_definition.get("hours", 24.0))
				if not old_structure.has("total_hours"):
					old_structure["total_hours"] = float(old_structure.get("remaining_hours", old_definition.get("hours", 24.0)))
				if str(old_structure.get("state", "")) == "operational":
					old_structure["remaining_hours"] = 0.0
				old_structures[old_id] = old_structure
			data["structures"] = old_structures
	if version < 8:
		var rotation_structures: Variant = data.get("structures", {})
		if rotation_structures is Dictionary:
			for structure_id in rotation_structures:
				var structure: Variant = rotation_structures.get(structure_id, {})
				if structure is Dictionary and not structure.has("rotation"):
					structure["rotation"] = 0
				rotation_structures[structure_id] = structure
			data["structures"] = rotation_structures
	if version < 9:
		var pickup_expedition: Variant = data.get("expedition_run", {})
		if pickup_expedition is Dictionary and str(pickup_expedition.get("status", "none")) == "active" and not pickup_expedition.has("pickups"):
			pickup_expedition["pickups"] = []
			data["expedition_run"] = pickup_expedition
	if version < SAVE_VERSION and not data.has("settings"):
		data["settings"] = settings.duplicate(true)
	if version < SAVE_VERSION and not data.has("observed_wildlife"):
		data["observed_wildlife"] = []
	if version < SAVE_VERSION and not data.has("translated_inscriptions"):
		data["translated_inscriptions"] = []
	if version < SAVE_VERSION and not data.has("tracked_wildlife"):
		data["tracked_wildlife"] = []
	if version < SAVE_VERSION and not data.has("unlocked_routes"):
		# Saves from before route gating already exposed every expedition. Preserve
		# that player's access; only a truly new session starts at Whisperwood.
		data["unlocked_routes"] = EXPEDITION_COSTS.keys()
	var activity_events_data: Variant = data.get("activity_events", [])
	if version < SAVE_VERSION and activity_events_data is Array:
		for activity_value in activity_events_data:
			if not (activity_value is Dictionary):
				continue
			var legacy_event: Dictionary = activity_value
			var legacy_receipt := str(legacy_event.get("receipt_id", ""))
			var legacy_minutes := maxi(0, int(legacy_event.get("minutes", 0)))
			if not legacy_event.has("source_id"):
				legacy_event["source_id"] = "legacy_import"
			if not legacy_event.has("event_id"):
				legacy_event["event_id"] = legacy_receipt
			if not legacy_event.has("occurred_at"):
				legacy_event["occurred_at"] = "legacy"
			if not legacy_event.has("timezone"):
				legacy_event["timezone"] = "UTC"
			if str(legacy_event.get("payload_hash", "")).strip_edges().is_empty():
				legacy_event["payload_hash"] = "legacy:%s:%d" % [legacy_receipt, legacy_minutes]
			if not legacy_event.has("mapping_version"):
				legacy_event["mapping_version"] = 1
			if not legacy_event.has("category"):
				legacy_event["category"] = "focused_work"
			if not legacy_event.has("stat_id"):
				legacy_event["stat_id"] = "Focus"
			if not legacy_event.has("mastery_id"):
				legacy_event["mastery_id"] = "Research"
			if not legacy_event.has("awards"):
				legacy_event["awards"] = {"xp": clampi(int(legacy_minutes / 10), 1, ACTIVITY_MAX_REWARD_XP), "health": clampi(int(legacy_minutes / 30), 1, ACTIVITY_MAX_REWARD_HEALTH), "coins": clampi(int(legacy_minutes / 15), 1, ACTIVITY_MAX_REWARD_COINS), "ability_points": 0, "stat": {"Focus": 0}, "mastery": {"Research": maxi(1, int(legacy_minutes / 10))}}
		data["activity_events"] = activity_events_data
	if version < SAVE_VERSION and not data.has("activity_receipts"):
		var migrated_receipts: Array[String] = []
		var receipt_events: Variant = data.get("activity_events", [])
		if receipt_events is Array:
			for event_value in receipt_events:
				if event_value is Dictionary:
					var receipt_id := str(event_value.get("receipt_id", ""))
					if not receipt_id.is_empty() and not migrated_receipts.has(receipt_id):
						migrated_receipts.append(receipt_id)
		data["activity_receipts"] = migrated_receipts
	if version < SAVE_VERSION and not data.has("activity_cursor"):
		var cursor_receipts: Variant = data.get("activity_receipts", [])
		data["activity_cursor"] = str(cursor_receipts.back()) if cursor_receipts is Array and not cursor_receipts.is_empty() else ""
	if version < SAVE_VERSION and not data.has("activity_minutes_total"):
		var migrated_minutes := 0
		var migrated_events: Variant = data.get("activity_events", [])
		if migrated_events is Array:
			for migrated_event in migrated_events:
				if migrated_event is Dictionary:
					migrated_minutes += maxi(0, int(migrated_event.get("minutes", 0)))
		data["activity_minutes_total"] = migrated_minutes
	if version < SAVE_VERSION and not data.has("activity_stat_gains"):
		data["activity_stat_gains"] = {"Strength": 0, "Agility": 0, "Focus": 0, "Wisdom": 0, "Spirituality": 0, "Perception": 0, "Resilience": 0}
	if version < SAVE_VERSION and not data.has("activity_stat_minutes"):
		var migrated_stat_minutes := {"Strength": 0, "Agility": 0, "Focus": 0, "Wisdom": 0, "Spirituality": 0, "Perception": 0, "Resilience": 0}
		var stat_minute_events: Variant = data.get("activity_events", [])
		if stat_minute_events is Array:
			for stat_event_value in stat_minute_events:
				if stat_event_value is Dictionary:
					var event_stat_id := str(stat_event_value.get("stat_id", "Focus"))
					if migrated_stat_minutes.has(event_stat_id):
						migrated_stat_minutes[event_stat_id] += maxi(0, int(stat_event_value.get("minutes", 0)))
		data["activity_stat_minutes"] = migrated_stat_minutes
	if version < SAVE_VERSION and not data.has("activity_last_manual_epoch"):
		data["activity_last_manual_epoch"] = 0
	if version < 14:
		var migrated_expedition: Variant = data.get("expedition_run", {})
		if migrated_expedition is Dictionary and not migrated_expedition.has("second_wind_used"):
			migrated_expedition["second_wind_used"] = false
			data["expedition_run"] = migrated_expedition
	if version < 15:
		var migrated_research: Variant = data.get("research_job", {})
		if migrated_research is Dictionary:
			var migrated_research_status := str(migrated_research.get("status", "idle"))
			if migrated_research_status == "researching":
				var legacy_days_remaining := maxi(1, int(migrated_research.get("ready_day", int(data.get("day", 1)) + 1)) - int(data.get("day", 1)))
				var legacy_hours := float(legacy_days_remaining * 24)
				migrated_research["total_hours"] = maxf(2.0, float(migrated_research.get("total_hours", legacy_hours)))
				migrated_research["remaining_hours"] = clampf(float(migrated_research.get("remaining_hours", migrated_research["total_hours"])), 0.0, migrated_research["total_hours"])
			elif migrated_research_status == "ready":
				migrated_research["total_hours"] = maxf(2.0, float(migrated_research.get("total_hours", 2.0)))
				migrated_research["remaining_hours"] = 0.0
			else:
				migrated_research["total_hours"] = 0.0
				migrated_research["remaining_hours"] = 0.0
			if not migrated_research.has("action_id"):
				migrated_research["action_id"] = "legacy-research:%d" % int(data.get("day", 1))
			if not migrated_research.has("material_refunded"):
				migrated_research["material_refunded"] = false
			data["research_job"] = migrated_research
	if version < 16:
		# Fishing was previously a one-call reward. Never resume that legacy
		# presentation state as an active challenge; a fresh attempt must pay its
		# own bait and energy under the v16 contract.
		data["fishing_attempt"] = {"status": "idle", "phase": "idle", "attempt_id": "", "spot_id": "", "zone_id": "", "elapsed": 0.0, "bite_at": 0.0, "hook_deadline": 0.0, "reel_progress": 0.0, "tension": 0.0, "mistakes": 0, "perfect_hook": false, "catch_amount": 0, "bonus_fish": false, "uncommon_catch": false, "bonus_resource_id": "", "bonus_resource_amount": 0, "seed": 0, "reel_pulse": false}
	if version < 17 and not data.has("research_clues"):
		data["research_clues"] = []
	if version < 18:
		data["market_day"] = int(data.get("day", 1))
		data["market_trades"] = {}
	if version < 19:
		data["market_contract_claimed_day"] = 0
	if version < 20:
		var migrated_fishing_attempt: Variant = data.get("fishing_attempt", {})
		if migrated_fishing_attempt is Dictionary:
			migrated_fishing_attempt["uncommon_catch"] = bool(migrated_fishing_attempt.get("uncommon_catch", false))
			migrated_fishing_attempt["bonus_resource_id"] = str(migrated_fishing_attempt.get("bonus_resource_id", ""))
			migrated_fishing_attempt["bonus_resource_amount"] = maxi(0, int(migrated_fishing_attempt.get("bonus_resource_amount", 0)))
			data["fishing_attempt"] = migrated_fishing_attempt
	if version < 21:
		var migrated_station_job: Variant = data.get("station_job", {})
		if migrated_station_job is Dictionary:
			migrated_station_job["output_kind"] = str(migrated_station_job.get("output_kind", "material"))
			migrated_station_job["tool_id"] = str(migrated_station_job.get("tool_id", ""))
			migrated_station_job["quality_multiplier"] = maxf(1.0, float(migrated_station_job.get("quality_multiplier", 1.0)))
			data["station_job"] = migrated_station_job
	if version < 22:
		var migrated_livestock: Variant = data.get("livestock", {})
		if migrated_livestock is Dictionary:
			for migrated_animal_id in migrated_livestock:
				var migrated_animal: Variant = migrated_livestock.get(migrated_animal_id, {})
				if migrated_animal is Dictionary:
					migrated_animal["trait_id"] = str(migrated_animal.get("trait_id", ""))
					migrated_animal["trait_progress"] = clampi(int(migrated_animal.get("trait_progress", 0)), 0, 100)
					migrated_livestock[migrated_animal_id] = migrated_animal
			data["livestock"] = migrated_livestock
	if version < 25:
		# v25 separates an enterable exterior shell from the stations that make it
		# functional. Existing operational Workshops must not lose crafting on
		# migration, so install one deterministic legacy Workbench in the measured
		# back-left cell. Fresh saves never receive this record.
		var migrated_interiors: Variant = data.get("interior_stations", {})
		if not (migrated_interiors is Dictionary):
			migrated_interiors = {}
		var migrated_structures: Variant = data.get("structures", {})
		if migrated_structures is Dictionary:
			for migrated_structure_id in migrated_structures:
				var migrated_structure: Variant = migrated_structures.get(migrated_structure_id, {})
				if not (migrated_structure is Dictionary) or str(migrated_structure.get("kind", "")) != "workshop" or str(migrated_structure.get("state", "")) != "operational":
					continue
				var parent_id := str(migrated_structure_id)
				var parent_stations: Variant = migrated_interiors.get(parent_id, {})
				if not (parent_stations is Dictionary):
					parent_stations = {}
				var has_legacy_workbench := false
				for legacy_station_id in parent_stations:
					var legacy_station: Variant = parent_stations.get(legacy_station_id, {})
					if legacy_station is Dictionary and str(legacy_station.get("kind", "")) == "workbench":
						has_legacy_workbench = true
						break
				if not has_legacy_workbench:
					parent_stations["workbench_legacy"] = {"id": "workbench_legacy", "structure_id": parent_id, "kind": "workbench", "cell": [-2, -1], "rotation": 0, "state": "operational", "remaining_hours": 0.0, "total_hours": 12.0, "delivered_materials": {"wood": 4, "stone": 2}, "legacy": true}
				migrated_interiors[parent_id] = parent_stations
		data["interior_stations"] = migrated_interiors
		var migrated_job: Variant = data.get("station_job", {})
		if migrated_job is Dictionary:
			var bound_parent_id := ""
			var bound_station_id := ""
			if str(migrated_job.get("kind", "none")) != "none":
				for candidate_parent_id in migrated_interiors:
					for candidate_station_id in migrated_interiors.get(candidate_parent_id, {}):
						var candidate_station: Variant = migrated_interiors[candidate_parent_id].get(candidate_station_id, {})
						if candidate_station is Dictionary and str(candidate_station.get("kind", "")) == "workbench" and str(candidate_station.get("state", "")) == "operational":
							bound_parent_id = str(candidate_parent_id)
							bound_station_id = str(candidate_station_id)
							break
					if not bound_parent_id.is_empty():
						break
			if str(migrated_job.get("kind", "none")) != "none" and not bound_parent_id.is_empty():
				migrated_job["structure_id"] = bound_parent_id
				migrated_job["station_id"] = bound_station_id
			else:
				migrated_job = {"kind": "none", "structure_id": "", "station_id": "", "remaining_hours": 0.0, "total_hours": 0.0, "output_id": "plank", "output": 0, "output_kind": "material", "tool_id": "", "quality_multiplier": 1.0, "action_id": "", "material_refunded": false}
			data["station_job"] = migrated_job
	if version < 26:
		# v26 makes physical expedition route beats durable on every map. Older
		# saves could contain a valid branch/objective without those checkpoints;
		# migrate only the traversal prefix implied by the already-owned phase.
		# No cargo, objective progress, reward, or unlock is created here.
		var route_migration: Variant = data.get("expedition_run", {})
		if route_migration is Dictionary:
			var migrated_route: Dictionary = route_migration
			var migrated_status := str(migrated_route.get("status", "none"))
			if migrated_status == "none":
				migrated_route["route_phase"] = "none"
				migrated_route["biome_id"] = ""
				migrated_route["branch_id"] = ""
				migrated_route["objective_id"] = ""
				migrated_route["objective_kind"] = ""
				migrated_route["objective_progress"] = 0
				migrated_route["objective_target"] = 0
				migrated_route["objective_complete"] = false
				migrated_route["shortcut_open"] = false
				migrated_route["cache_claimed"] = false
				migrated_route["return_checkpoint_crossed"] = false
				migrated_route["route_checkpoints"] = []
			elif migrated_status == "active":
				var migrated_phase := str(migrated_route.get("route_phase", "approach"))
				var existing_checkpoints: Variant = migrated_route.get("route_checkpoints", [])
				var valid_existing_prefix := existing_checkpoints is Array and (existing_checkpoints as Array) in [[], ["arrival"], ["arrival", "fork"], ["arrival", "fork", "return"]]
				var migrated_checkpoints: Array = existing_checkpoints.duplicate(true) if valid_existing_prefix else []
				if not valid_existing_prefix:
					match migrated_phase:
						"arrival": migrated_checkpoints = ["arrival"]
						"fork", "branch", "objective", "capstone", "shortcut": migrated_checkpoints = ["arrival", "fork"]
						"return": migrated_checkpoints = ["arrival", "fork", "return"]
						_: migrated_checkpoints = []
				if bool(migrated_route.get("return_checkpoint_crossed", false)):
					migrated_checkpoints = ["arrival", "fork", "return"]
					migrated_phase = "return"
				migrated_route["route_checkpoints"] = migrated_checkpoints
				migrated_route["route_phase"] = migrated_phase if EXPEDITION_ROUTE_PHASES.has(migrated_phase) and migrated_phase != "none" else "approach"
				migrated_route["branch_id"] = str(migrated_route.get("branch_id", ""))
				migrated_route["objective_id"] = str(migrated_route.get("objective_id", ""))
				migrated_route["objective_kind"] = str(migrated_route.get("objective_kind", ""))
				migrated_route["objective_progress"] = maxi(0, int(migrated_route.get("objective_progress", 0)))
				migrated_route["objective_target"] = maxi(0, int(migrated_route.get("objective_target", 0)))
				migrated_route["objective_complete"] = bool(migrated_route.get("objective_complete", false))
				migrated_route["shortcut_open"] = bool(migrated_route.get("shortcut_open", false))
				migrated_route["cache_claimed"] = bool(migrated_route.get("cache_claimed", false))
				migrated_route["return_checkpoint_crossed"] = bool(migrated_route.get("return_checkpoint_crossed", false)) or migrated_route["route_phase"] == "return"
			data["expedition_run"] = migrated_route
	if version < SAVE_VERSION:
		if not data.has("world_seed") or not (data["world_seed"] is String) or str(data["world_seed"]).strip_edges().is_empty():
			data["world_seed"] = DEFAULT_WORLD_SEED
		if not data.has("action_sequence"):
			data["action_sequence"] = 0
		if not data.has("chance_rolls"):
			data["chance_rolls"] = {}
	data["save_version"] = SAVE_VERSION
	if version < SAVE_VERSION and not data.has("content_version"):
		data["content_version"] = CONTENT_VERSION
	return data

func _valid_integer(value: Variant, minimum: int, maximum: int) -> bool:
	if not (value is int or value is float):
		return false
	var numeric := float(value)
	return is_finite(numeric) and numeric >= float(minimum) and numeric <= float(maximum) and numeric == floor(numeric)

func _valid_number(value: Variant, minimum: float, maximum: float) -> bool:
	if not (value is int or value is float):
		return false
	var numeric := float(value)
	return is_finite(numeric) and numeric >= minimum and numeric <= maximum

func _save_shape_is_supported(data: Dictionary) -> bool:
	var source_version := int(data.get("_source_save_version", data.get("save_version", 0)))
	if source_version == SAVE_VERSION:
		for required_key in ["save_version", "content_version", "day", "hour", "season", "weather", "energy", "max_energy", "health", "max_health", "cargo_capacity", "coins", "xp", "level", "ability_points", "stats", "masteries", "inventory", "discovered", "observed_wildlife", "translated_inscriptions", "tracked_wildlife", "researched", "blueprints", "research_job", "research_clues", "fishing_attempt", "built", "farm_plot", "station_job", "equipment", "nutrition", "hydration", "livestock", "structures", "interior_stations", "unlocked_features", "unlocked_routes", "sanctuary_depleted_ids", "sanctuary_contact_progress", "activity_receipts", "activity_events", "activity_cursor", "activity_mapping_version", "activity_minutes_total", "activity_stat_gains", "activity_stat_minutes", "activity_last_manual_epoch", "world_seed", "action_sequence", "chance_rolls", "settings", "last_day_transaction", "construction_progress", "construction_job", "recovery_pack", "market_day", "market_trades", "market_contract_claimed_day", "expedition_run", "quest"]:
			if not data.has(required_key):
				return false
	for key in ["stats", "masteries", "inventory", "built", "farm_plot", "station_job", "equipment", "livestock", "structures", "interior_stations", "sanctuary_contact_progress", "research_job", "fishing_attempt", "construction_job", "recovery_pack", "market_trades", "expedition_run", "quest"]:
		if data.has(key) and not (data[key] is Dictionary):
			return false
	for key in ["discovered", "observed_wildlife", "translated_inscriptions", "tracked_wildlife", "researched", "blueprints", "activity_receipts", "activity_events", "unlocked_features", "unlocked_routes", "sanctuary_depleted_ids", "research_clues"]:
		if data.has(key) and not (data[key] is Array):
			return false
	if data.has("world_seed") and (not (data["world_seed"] is String) or str(data["world_seed"]).is_empty() or str(data["world_seed"]).length() > 128):
		return false
	if data.has("action_sequence") and not _valid_integer(data["action_sequence"], 0, 2147483646):
		return false
	var saved_chance_rolls: Variant = data.get("chance_rolls", {})
	if not (saved_chance_rolls is Dictionary):
		return false
	for roll_key in saved_chance_rolls:
		var roll_parts := str(roll_key).split("|")
		if not (roll_key is String) or str(roll_key).length() > 256 or roll_parts.size() != 3 or roll_parts[0].is_empty() or roll_parts[1].is_empty() or roll_parts[2].is_empty() or not _is_mastery_feature(roll_parts[0]) or not ContentRegistry.mastery_effects_for_feature(roll_parts[0]).has(roll_parts[1]) or not (saved_chance_rolls[roll_key] is bool):
			return false
	if saved_chance_rolls.size() > MAX_CHANCE_ROLLS:
		return false
	if data.has("activity_minutes_total") and not _valid_integer(data["activity_minutes_total"], 0, 2147483647):
		return false
	var activity_gains: Variant = data.get("activity_stat_gains", {})
	if not (activity_gains is Dictionary):
		return false
	for stat_id in ContentRegistry.STAT_ORDER:
		if not activity_gains.has(stat_id) or not _valid_integer(activity_gains[stat_id], 0, 2147483647):
			return false
	for stat_id in activity_gains:
		if not ContentRegistry.STAT_ORDER.has(str(stat_id)):
			return false
	var activity_stat_minutes_data: Variant = data.get("activity_stat_minutes", {})
	if not (activity_stat_minutes_data is Dictionary):
		return false
	for stat_id in ContentRegistry.STAT_ORDER:
		if not activity_stat_minutes_data.has(stat_id) or not _valid_integer(activity_stat_minutes_data[stat_id], 0, 2147483647):
			return false
	for stat_id in activity_stat_minutes_data:
		if not ContentRegistry.STAT_ORDER.has(str(stat_id)):
			return false
	if data.has("activity_last_manual_epoch") and not _valid_integer(data["activity_last_manual_epoch"], 0, 2147483647):
		return false
	if data.has("manual_activity_session"):
		var manual_session: Variant = data.get("manual_activity_session")
		if not (manual_session is Dictionary):
			return false
		var manual_status := str(manual_session.get("status", "idle"))
		if manual_status not in ["idle", "active"]:
			return false
		var manual_receipt := str(manual_session.get("receipt_id", ""))
		var manual_category := str(manual_session.get("category", "focused_work"))
		var manual_started: Variant = manual_session.get("started_epoch", 0)
		var manual_duration: Variant = manual_session.get("duration_seconds", MANUAL_ACTIVITY_DURATION_SECONDS)
		if manual_category.is_empty() or manual_category.length() > 64 or not _valid_integer(manual_started, 0, 2147483647) or int(manual_duration) != MANUAL_ACTIVITY_DURATION_SECONDS:
			return false
		if manual_status == "idle" and not manual_receipt.is_empty():
			return false
		if manual_status == "active" and (manual_receipt.is_empty() or manual_receipt.length() > 128 or int(manual_started) <= 0):
			return false
	var activity_receipt_values: Variant = data.get("activity_receipts", [])
	var activity_event_values: Variant = data.get("activity_events", [])
	if not (activity_receipt_values is Array) or not (activity_event_values is Array):
		return false
	var receipt_set := {}
	for receipt_value in activity_receipt_values:
		if not (receipt_value is String):
			return false
		var receipt_id := str(receipt_value)
		if receipt_id.is_empty() or receipt_id.length() > 128 or receipt_set.has(receipt_id):
			return false
		receipt_set[receipt_id] = true
	var seen_activity_keys := {}
	var seen_activity_receipts := {}
	var activity_total := 0
	var computed_activity_gains := {}
	var computed_activity_minutes := {}
	var running_activity_minutes := 0
	var running_stat_minutes := {}
	var final_activity_receipt := ""
	for stat_id in ContentRegistry.STAT_ORDER:
		computed_activity_gains[stat_id] = 0
		computed_activity_minutes[stat_id] = 0
		running_stat_minutes[stat_id] = 0
	for activity_value in activity_event_values:
		if not (activity_value is Dictionary):
			return false
		var activity_event: Dictionary = activity_value
		for required_key in ["receipt_id", "event_id", "source_id", "occurred_at", "timezone", "payload_hash", "category", "stat_id", "mastery_id"]:
			if not activity_event.has(required_key) or not (activity_event[required_key] is String) or str(activity_event[required_key]).strip_edges().is_empty():
				return false
		var activity_receipt := str(activity_event.get("receipt_id", ""))
		var activity_source := str(activity_event.get("source_id", ""))
		var activity_event_id := str(activity_event.get("event_id", ""))
		if activity_receipt.length() > 128 or activity_source.length() > 64 or activity_event_id.length() > 128 or str(activity_event.get("occurred_at", "")).length() > 128 or str(activity_event.get("timezone", "")).length() > 64 or str(activity_event.get("payload_hash", "")).length() > 256 or str(activity_event.get("category", "")).length() > 64:
			return false
		if activity_source not in ["manual_timer", "manual_ui", "legacy_import"]:
			return false
		if activity_source == "manual_ui" and source_version >= SAVE_VERSION and not OS.is_debug_build():
			return false
		if int(activity_event.get("mapping_version", -1)) != int(data.get("activity_mapping_version", activity_mapping_version)):
			return false
		if not receipt_set.has(activity_receipt) or not _valid_integer(activity_event.get("minutes", 0), 1, ACTIVITY_MAX_MINUTES):
			return false
		if seen_activity_receipts.has(activity_receipt):
			return false
		seen_activity_receipts[activity_receipt] = true
		var activity_key := _activity_event_key(activity_source, activity_event_id)
		if seen_activity_keys.has(activity_key):
			return false
		seen_activity_keys[activity_key] = true
		var stat_id := str(activity_event.get("stat_id", ""))
		var mastery_id := str(activity_event.get("mastery_id", ""))
		if not ContentRegistry.STAT_ORDER.has(stat_id) or not ContentRegistry.MASTERY_ORDER.has(mastery_id):
			return false
		var activity_category := str(activity_event.get("category", "focused_work"))
		if activity_source != "legacy_import":
			if _activity_stat_for_metadata({"category": activity_category}) != stat_id or _activity_mastery_for_metadata({"category": activity_category}) != mastery_id:
				return false
		if activity_source == "manual_timer":
			if str(activity_event.get("verification", "")) != "elapsed_timer_v1" or not _valid_integer(activity_event.get("started_epoch", 0), 1, 2147483647):
				return false
			if str(activity_event.get("payload_hash", "")) != "manual_timer_v1:%s:%d" % [activity_receipt, int(activity_event.get("started_epoch", 0))]:
				return false
		var awards: Variant = activity_event.get("awards", {})
		if not (awards is Dictionary):
			return false
		for award_key in ["xp", "health", "coins", "ability_points"]:
			if not _valid_integer(awards.get(award_key, -1), 0, 2147483647):
				return false
		var stat_awards: Variant = awards.get("stat", {})
		var mastery_awards: Variant = awards.get("mastery", {})
		if not (stat_awards is Dictionary) or not (mastery_awards is Dictionary) or stat_awards.size() != 1 or mastery_awards.size() != 1 or not stat_awards.has(stat_id) or not mastery_awards.has(mastery_id):
			return false
		if not _valid_integer(stat_awards[stat_id], 0, 2147483647) or not _valid_integer(mastery_awards[mastery_id], 0, 100):
			return false
		var activity_minutes := int(activity_event.get("minutes", 0))
		var expected_xp := clampi(int(activity_minutes / 10), 1, ACTIVITY_MAX_REWARD_XP)
		var expected_coins := clampi(int(activity_minutes / 15), 1, ACTIVITY_MAX_REWARD_COINS)
		var expected_ap := int((running_activity_minutes + activity_minutes) / 60) - int(running_activity_minutes / 60)
		var expected_stat := int((int(running_stat_minutes.get(stat_id, 0)) + activity_minutes) / 30) - int(int(running_stat_minutes.get(stat_id, 0)) / 30)
		if activity_source != "legacy_import":
			if int(awards.get("xp", -1)) != expected_xp or int(awards.get("coins", -1)) != expected_coins or int(awards.get("ability_points", -1)) != expected_ap or int(stat_awards.get(stat_id, -1)) != expected_stat:
				return false
		computed_activity_gains[stat_id] += int(stat_awards[stat_id])
		computed_activity_minutes[stat_id] += activity_minutes
		running_stat_minutes[stat_id] = int(running_stat_minutes.get(stat_id, 0)) + activity_minutes
		running_activity_minutes += activity_minutes
		activity_total += activity_minutes
		final_activity_receipt = activity_receipt
	if receipt_set.size() != activity_event_values.size() or seen_activity_receipts.size() != receipt_set.size() or activity_total != int(data.get("activity_minutes_total", 0)):
		return false
	for stat_id in ContentRegistry.STAT_ORDER:
		# JSON round-trips numeric dictionary values as floats. Compare the
		# validated integer values rather than relying on Variant dictionary
		# equality, which treats an int and an equivalent float as different.
		if int(computed_activity_gains.get(stat_id, -1)) != int(activity_gains.get(stat_id, -2)):
			return false
		if int(computed_activity_minutes.get(stat_id, -1)) != int(activity_stat_minutes_data.get(stat_id, -2)):
			return false
	var activity_cursor := str(data.get("activity_cursor", ""))
	if activity_event_values.is_empty():
		if not activity_cursor.is_empty():
			return false
	elif activity_cursor != final_activity_receipt:
		return false
	if data.has("observed_wildlife"):
		for wildlife_id in data["observed_wildlife"]:
			if not (wildlife_id is String) or str(wildlife_id).is_empty() or not ContentRegistry.WILDLIFE.has(str(wildlife_id)):
				return false
	if data.has("translated_inscriptions"):
		var inscription_values: Variant = data["translated_inscriptions"]
		if not (inscription_values is Array) or inscription_values.size() > ContentRegistry.EXPEDITION_INSCRIPTIONS.size():
			return false
		var seen_inscriptions := {}
		for inscription_id in inscription_values:
			if not (inscription_id is String) or str(inscription_id).is_empty() or not ContentRegistry.EXPEDITION_INSCRIPTIONS.has(str(inscription_id)) or seen_inscriptions.has(str(inscription_id)):
				return false
			seen_inscriptions[str(inscription_id)] = true
	if data.has("tracked_wildlife"):
		var tracked_values: Variant = data["tracked_wildlife"]
		if not (tracked_values is Array) or tracked_values.size() > ContentRegistry.WILDLIFE.size():
			return false
		var seen_tracks := {}
		for wildlife_id in tracked_values:
			if not (wildlife_id is String) or str(wildlife_id).is_empty() or not ContentRegistry.WILDLIFE.has(str(wildlife_id)) or seen_tracks.has(str(wildlife_id)):
				return false
			seen_tracks[str(wildlife_id)] = true
	if data.has("discovered"):
		for discovery_id in data["discovered"]:
			if not (discovery_id is String) or not ContentRegistry.DISCOVERIES.has(str(discovery_id)):
				return false
	if data.has("researched"):
		for discovery_id in data["researched"]:
			if not (discovery_id is String) or not ContentRegistry.DISCOVERIES.has(str(discovery_id)) or not data.get("discovered", []).has(discovery_id):
				return false
	if data.has("blueprints"):
		var known_blueprints := {}
		for discovery_id in ContentRegistry.DISCOVERIES:
			known_blueprints[ContentRegistry.discovery_blueprint(str(discovery_id))] = true
		for blueprint in data["blueprints"]:
			if not (blueprint is String) or not known_blueprints.has(str(blueprint)):
				return false
	if data.has("research_clues"):
		var clue_values: Variant = data["research_clues"]
		if not (clue_values is Array) or clue_values.size() > 256:
			return false
		var seen_clues := {}
		var clue_day_limit := int(data.get("day", day))
		for clue_value in clue_values:
			if not (clue_value is Dictionary):
				return false
			var clue: Dictionary = clue_value
			for field_name in ["clue_id", "source_id", "related_id", "destination_id", "branch_id", "title", "hint", "preparation_hint", "action_id"]:
				if not clue.has(field_name) or not (clue[field_name] is String) or str(clue[field_name]).strip_edges().is_empty():
					return false
			var source_id := str(clue.get("source_id", ""))
			var related_id := str(clue.get("related_id", ""))
			var clue_identity := "%s:%s" % [source_id, related_id]
			var matching_link: Dictionary = {}
			for link_value in ContentRegistry.discovery_links(source_id):
				if link_value is Dictionary and str(link_value.get("related_id", "")) == related_id:
					matching_link = link_value.duplicate(true)
					break
			if not ContentRegistry.DISCOVERIES.has(source_id) or not ContentRegistry.DISCOVERIES.has(related_id) or matching_link.is_empty() or str(clue.get("clue_id", "")) != clue_identity or seen_clues.has(clue_identity) or str(clue.get("destination_id", "")) != str(matching_link.get("destination_id", "")) or str(clue.get("branch_id", "")) != str(matching_link.get("branch_id", "")) or str(clue.get("title", "")) != str(matching_link.get("title", "")) or str(clue.get("hint", "")).length() > 256 or str(clue.get("preparation_hint", "")).length() > 256 or str(clue.get("action_id", "")).length() > 128 or not _valid_integer(clue.get("revealed_day", 0), 1, clue_day_limit):
				return false
			seen_clues[clue_identity] = true
	if data.has("unlocked_features"):
		for feature in data["unlocked_features"]:
			if not (feature is String) or (not _is_mastery_feature(str(feature)) and not _is_known_content_grant(str(feature))):
				return false
	if data.has("unlocked_routes"):
		var route_order := ["Whisperwood", "Sunlit Beach", "Ember Ridge", "Glass Desert", "Sunken Dungeon"]
		var highest_route_index := -1
		for route_id in data["unlocked_routes"]:
			if not (route_id is String) or not EXPEDITION_COSTS.has(str(route_id)):
				return false
			highest_route_index = maxi(highest_route_index, route_order.find(str(route_id)))
		for route_index in range(highest_route_index + 1):
			if not data["unlocked_routes"].has(route_order[route_index]):
				return false
	if data.has("settings"):
		var settings_data: Variant = data["settings"]
		if not (settings_data is Dictionary):
			return false
		for setting_id in ["master", "music", "ambience", "weather", "effects", "ui"]:
			if source_version == SAVE_VERSION and not settings_data.has(setting_id):
				return false
			if settings_data.has(setting_id) and not _valid_number(settings_data[setting_id], 0.0, 1.0):
				return false
		for setting_id in ["screen_shake", "haptics"]:
			if source_version == SAVE_VERSION and not settings_data.has(setting_id):
				return false
			if settings_data.has(setting_id) and not (settings_data[setting_id] is bool):
				return false
	var built_data: Variant = data.get("built", {})
	if built_data is Dictionary:
		for feature_id in built_data:
			if not (feature_id in ["workshop", "library", "livestock_pen"]) or not (built_data[feature_id] is bool):
				return false
		if source_version == SAVE_VERSION:
			for required_built_key in ["workshop", "library", "livestock_pen"]:
				if not built_data.has(required_built_key):
					return false
	var saved_max_energy := int(data.get("max_energy", max_energy))
	var saved_max_health := int(data.get("max_health", max_health))
	var saved_day := int(data.get("day", day))
	var saved_market_day := int(data.get("market_day", saved_day))
	if not _valid_integer(saved_market_day, 1, saved_day):
		return false
	var saved_market_contract_day := int(data.get("market_contract_claimed_day", 0))
	if not _valid_integer(saved_market_contract_day, 0, saved_day) or (saved_market_contract_day != 0 and saved_market_contract_day != saved_market_day):
		return false
	var market_trades_data: Variant = data.get("market_trades", {})
	if not (market_trades_data is Dictionary) or market_trades_data.size() > 64:
		return false
	for trade_key in market_trades_data:
		if not (trade_key is String) or not (market_trades_data[trade_key] is bool) or not bool(market_trades_data[trade_key]):
			return false
		var trade_parts := str(trade_key).split(":")
		if trade_parts.size() != 2 or int(trade_parts[0]) != saved_market_day or not _market_offer_id_is_known(str(trade_parts[1])):
			return false
	if data.has("cargo_capacity") and not _valid_integer(data["cargo_capacity"], 1, 1000):
		return false
	if data.has("content_version") and not _valid_integer(data["content_version"], 1, CONTENT_VERSION):
		return false
	if not _valid_integer(data.get("max_energy", max_energy), 1, 1000) or not _valid_integer(data.get("max_health", max_health), 1, 1000):
		return false
	var saved_xp := int(data.get("xp", xp))
	var saved_level := int(data.get("level", level))
	if saved_level != 1 + int(saved_xp / 100):
		return false
	if not _valid_integer(data.get("day", day), 1, 2147483647) or (data.has("hour") and (not _valid_number(data["hour"], 0.0, 24.0) or float(data["hour"]) >= 24.0)):
		return false
	if data.has("construction_progress") and not _valid_number(data["construction_progress"], 0.0, 1.0):
		return false
	if not _valid_integer(data.get("energy", energy), 0, saved_max_energy) or not _valid_integer(data.get("health", health), 1, saved_max_health):
		return false
	for key in ["day", "level", "ability_points", "coins", "xp", "last_day_transaction", "activity_mapping_version"]:
		if data.has(key) and not _valid_integer(data[key], 0, 2147483647):
			return false
	if data.has("last_day_transaction") and int(data["last_day_transaction"]) > saved_day:
		return false
	for key in ["nutrition", "hydration"]:
		if data.has(key) and not _valid_integer(data[key], 0, 100):
			return false
	var livestock_data: Variant = data.get("livestock", {})
	if livestock_data is Dictionary:
		for animal_id in livestock_data:
			var animal: Variant = livestock_data[animal_id]
			if not (animal_id is String) or str(animal_id).is_empty() or not (animal is Dictionary):
				return false
			if not _valid_integer(animal.get("hunger", 0), 0, 100) or not _valid_integer(animal.get("health", 1), 1, 100) or not _valid_integer(animal.get("last_fed_day", 0), 0, saved_day) or not (animal.get("production_ready", false) is bool):
				return false
			if str(animal.get("product_id", "")).is_empty() or not _valid_integer(animal.get("product_amount", 1), 1, 1000):
				return false
			var trait_id := str(animal.get("trait_id", ""))
			var trait_progress_value: Variant = animal.get("trait_progress", 0)
			if not _valid_integer(trait_progress_value, 0, 100) or (not trait_id.is_empty() and not ContentRegistry.LIVESTOCK_TRAITS.has(trait_id)) or (not trait_id.is_empty() and int(trait_progress_value) < 100):
				return false
	var stats_data: Variant = data.get("stats", {})
	if stats_data is Dictionary:
		if source_version == SAVE_VERSION:
			for required_stat_id in ContentRegistry.STAT_ORDER:
				if not stats_data.has(required_stat_id):
					return false
		for stat_id in stats_data:
			if not _valid_integer(stats_data[stat_id], 1, 1000):
				return false
		if not stats_data.has("Resilience"):
			return false
		var expected_max_health := 100 + int(round(float(maxi(0, int(stats_data.get("Resilience", 1)) - 1)) * _stat_effect_float("Resilience", "max_health_per_point", 5.0)))
		if saved_max_health != expected_max_health:
			return false
	var mastery_data: Variant = data.get("masteries", {})
	if mastery_data is Dictionary:
		if source_version == SAVE_VERSION:
			for required_mastery_id in ContentRegistry.MASTERY_ORDER:
				if not mastery_data.has(required_mastery_id):
					return false
		for mastery_id in mastery_data:
			if not _valid_integer(mastery_data[mastery_id], 0, 100):
				return false
	var inventory_data: Variant = data.get("inventory", {})
	if inventory_data is Dictionary:
		for item_id in inventory_data:
			if not INVENTORY_IDS.has(str(item_id)) or not _valid_integer(inventory_data[item_id], 0, 2147483647):
				return false
	var equipment_data: Variant = data.get("equipment", {})
	if equipment_data is Dictionary:
		for tool_id in equipment_data:
			var tool: Variant = equipment_data[tool_id]
			if not (tool is Dictionary) or not _valid_integer(tool.get("max_durability", 1), 1, 1000) or not _valid_integer(tool.get("durability", 0), 0, int(tool.get("max_durability", 1))) or not _valid_number(tool.get("wear_remainder", 0.0), 0.0, 0.999999):
				return false
	var farm: Variant = data.get("farm_plot", {})
	if farm is Dictionary:
		if str(farm.get("state", "empty")) not in ["empty", "tilled", "planted"] or not _valid_integer(farm.get("growth", 0), 0, 3) or not (farm.get("watered", false) is bool):
			return false
	var station: Variant = data.get("station_job", {})
	if station is Dictionary:
		var station_kind := str(station.get("kind", "none"))
		var station_parent_id := str(station.get("structure_id", ""))
		var station_instance_id := str(station.get("station_id", ""))
		if station_kind != "none" and not ContentRegistry.WORKSHOP_RECIPES.has(station_kind):
			return false
		if station_kind == "none" and (not station_parent_id.is_empty() or not station_instance_id.is_empty()):
			return false
		if station_kind != "none" and (station_parent_id.is_empty() or station_instance_id.is_empty()):
			return false
		var output_kind := str(station.get("output_kind", "material"))
		var tool_id := str(station.get("tool_id", ""))
		if output_kind not in ["material", "tool"] or not _valid_number(station.get("quality_multiplier", 1.0), 1.0, 10.0) or (output_kind == "tool" and not equipment.has(tool_id)):
			return false
		if not _valid_integer(station.get("remaining_hours", 0), 0, 100000) or not _valid_number(station.get("total_hours", 0), 0.0, 100000.0) or float(station.get("remaining_hours", 0.0)) > float(station.get("total_hours", 0.0)) + 0.0001 or not _valid_integer(station.get("output", 0), 0, 2147483647):
			return false
		if station_kind != "none":
			var station_recipe := ContentRegistry.workshop_recipe(station_kind)
			if str(station.get("output_id", "")) != station_kind or int(station.get("output", 0)) != int(station_recipe.get("output", 0)) or float(station.get("total_hours", 0.0)) != float(station_recipe.get("hours", 0.0)) or output_kind != str(station_recipe.get("output_kind", "material")) or (output_kind == "tool" and str(station_recipe.get("tool_id", "")) != tool_id):
				return false
		if station_kind == "none" and (float(station.get("remaining_hours", 0.0)) != 0.0 or float(station.get("total_hours", 0.0)) != 0.0 or int(station.get("output", 0)) != 0):
			return false
	var construction: Variant = data.get("construction_job", {})
	if construction is Dictionary:
		if str(construction.get("status", "none")) not in ["none", "building", "ready"] or not _valid_integer(construction.get("remaining_hours", 0), 0, 100000):
			return false
	var recovery: Variant = data.get("recovery_pack", {})
	if recovery is Dictionary and not recovery.is_empty():
		if str(recovery.get("pack_id", "")).is_empty() or not EXPEDITION_COSTS.has(str(recovery.get("zone_id", ""))):
			return false
		if not _valid_integer(recovery.get("expires_day", saved_day + 1), 0, 2147483647) or not (recovery.get("loot", {}) is Dictionary):
			return false
		for recovery_id in recovery.get("loot", {}):
			if not (recovery_id is String) or not INVENTORY_IDS.has(str(recovery_id)) or str(recovery_id).is_empty() or not _valid_integer(recovery["loot"][recovery_id], 1, 2147483647):
				return false
		var recovery_position: Variant = recovery.get("position", [])
		if not (recovery_position is Array) or recovery_position.size() < 3:
			return false
		for value in recovery_position.slice(0, 3):
			if not (value is int or value is float) or not is_finite(float(value)):
				return false
	var research: Variant = data.get("research_job", {})
	if research is Dictionary:
		var research_status := str(research.get("status", "idle"))
		if research_status not in ["idle", "researching", "ready"]:
			return false
		if not _valid_number(research.get("remaining_hours", 0.0), 0.0, 100000.0) or not _valid_number(research.get("total_hours", 0.0), 0.0, 100000.0) or float(research.get("remaining_hours", 0.0)) > float(research.get("total_hours", 0.0)) + 0.0001 or not (research.get("material_refunded", false) is bool):
			return false
		if research_status == "idle" and (float(research.get("remaining_hours", 0.0)) > 0.0001 or float(research.get("total_hours", 0.0)) > 0.0001):
			return false
		if research_status == "ready" and float(research.get("remaining_hours", 0.0)) > 0.0001:
			return false
		if research_status != "idle":
			var research_id := str(research.get("discovery_id", ""))
			var discovered_data: Variant = data.get("discovered", [])
			if not ContentRegistry.DISCOVERIES.has(research_id) or not (discovered_data is Array) or not discovered_data.has(research_id) or not _valid_integer(research.get("ready_day", 0), 0, 2147483647):
				return false
			if float(research.get("total_hours", 0.0)) <= 0.0 or not (research.get("action_id", "") is String) or str(research.get("action_id", "")).is_empty():
				return false
	var fishing: Variant = data.get("fishing_attempt", {})
	if fishing is Dictionary:
		var fishing_status := str(fishing.get("status", "idle"))
		var fishing_phase := str(fishing.get("phase", "idle"))
		var bonus_resource_id := str(fishing.get("bonus_resource_id", ""))
		var bonus_resource_amount_value: Variant = fishing.get("bonus_resource_amount", 0)
		var bonus_resource_amount := int(bonus_resource_amount_value) if (bonus_resource_amount_value is int or bonus_resource_amount_value is float) else -1
		if fishing_status not in ["idle", "active", "landed", "failed"] or not _valid_number(fishing.get("elapsed", 0.0), 0.0, 30.0) or not _valid_number(fishing.get("bite_at", 0.0), 0.0, 30.0) or not _valid_number(fishing.get("hook_deadline", 0.0), 0.0, 30.0) or not _valid_number(fishing.get("reel_progress", 0.0), 0.0, 1.0) or not _valid_number(fishing.get("tension", 0.0), 0.0, 1.0) or not _valid_integer(fishing.get("mistakes", 0), 0, 3) or not _valid_integer(fishing.get("catch_amount", 0), 0, 32) or not _valid_integer(fishing.get("seed", 0), 0, 2147483647) or not _valid_integer(bonus_resource_amount_value, 0, 32) or not (fishing.get("perfect_hook", false) is bool) or not (fishing.get("bonus_fish", false) is bool) or not (fishing.get("uncommon_catch", false) is bool) or not (fishing.get("reel_pulse", false) is bool) or (bonus_resource_amount > 0 and not INVENTORY_IDS.has(bonus_resource_id)) or (bonus_resource_amount > 0 and bonus_resource_id.is_empty()):
			return false
		if fishing_status == "idle":
			if fishing_phase != "idle" or not str(fishing.get("attempt_id", "")).is_empty() or int(fishing.get("catch_amount", 0)) != 0 or bool(fishing.get("uncommon_catch", false)) or bonus_resource_amount != 0 or not bonus_resource_id.is_empty():
				return false
		else:
			if str(fishing.get("attempt_id", "")).is_empty() or str(fishing.get("attempt_id", "")).length() > 128 or not ContentRegistry.FISHING_SPOTS.has(str(fishing.get("spot_id", ""))) or str(fishing.get("zone_id", "")) != str(ContentRegistry.fishing_spot_definition(str(fishing.get("spot_id", ""))).get("zone_id", "")):
				return false
			if fishing_status == "active" and fishing_phase not in ["waiting", "bite", "reeling"]:
				return false
			if fishing_status == "landed" and (fishing_phase != "landed" or int(fishing.get("catch_amount", 0)) <= 0 or float(fishing.get("reel_progress", 0.0)) < 0.999 or (bool(fishing.get("uncommon_catch", false)) and bonus_resource_amount <= 0)):
				return false
			if fishing_status == "failed" and fishing_phase != "escaped":
				return false
	var quest_data: Variant = data.get("quest", {})
	if data.has("quest") and quest_data is Dictionary:
		if str(quest_data.get("id", "")).is_empty() or not _valid_integer(quest_data.get("progress", 0), 0, 2147483647) or not _valid_integer(quest_data.get("target", 1), 1, 2147483647) or not (quest_data.get("claimed", false) is bool):
			return false
		if int(quest_data.get("progress", 0)) > int(quest_data.get("target", 1)):
			return false
		if quest_data.has("first_run_stage") and not FIRST_RUN_STAGES.has(str(quest_data.get("first_run_stage", ""))):
			return false
		if quest_data.has("first_run_completed") and not (quest_data.get("first_run_completed", false) is bool):
			return false
	var structures_data: Variant = data.get("structures", {})
	var occupied_saved_cells := {}
	var unique_saved_kinds := {}
	if structures_data is Dictionary:
		for structure_id in structures_data:
			var structure: Variant = structures_data.get(structure_id, {})
			if not (structure is Dictionary):
				return false
			if structure.has("interior_layout") and not _interior_layout_is_supported(structure.get("interior_layout", {})):
				return false
			var kind := str(structure.get("kind", ""))
			var structure_cell: Variant = structure.get("cell", [])
			var structure_state := str(structure.get("state", ""))
			if not ContentRegistry.STRUCTURES.has(kind) or not (structure_cell is Array) or structure_cell.size() != 2 or structure_state not in ["blueprint", "building", "operational"]:
				return false
			if _structure_is_unique(kind):
				if unique_saved_kinds.has(kind):
					return false
				unique_saved_kinds[kind] = true
			if not _valid_integer(structure_cell[0], SettlementGrid.MIN_X, SettlementGrid.MAX_X) or not _valid_integer(structure_cell[1], SettlementGrid.MIN_Z, SettlementGrid.MAX_Z):
				return false
			if structure.has("rotation") and not _valid_integer(structure.get("rotation", 0), 0, 3):
				return false
			if not _valid_integer(structure.get("remaining_hours", 0), 0, 100000):
				return false
			var structure_definition := ContentRegistry.structure_definition(kind)
			var structure_cost: Dictionary = structure_definition.get("cost", {})
			var delivered_materials: Variant = structure.get("delivered_materials", {})
			if not (delivered_materials is Dictionary):
				return false
			for material_id in structure_cost:
				if not _valid_integer(delivered_materials.get(str(material_id), 0), 0, int(structure_cost[material_id])):
					return false
			if structure_state == "blueprint" and float(structure.get("remaining_hours", 0.0)) != 0.0:
				return false
			if structure_state in ["building", "operational"]:
				for material_id in structure_cost:
					if int(delivered_materials.get(str(material_id), 0)) != int(structure_cost[material_id]):
						return false
			var cells := _structure_cells(kind, Vector2i(int(structure_cell[0]), int(structure_cell[1])), int(structure.get("rotation", 0)))
			if not SettlementGrid.inside_bounds(cells):
				return false
			for cell in cells:
				if _fixed_cell_occupied(cell):
					return false
				var cell_key := "%d:%d" % [cell.x, cell.y]
				if occupied_saved_cells.has(cell_key):
					return false
				occupied_saved_cells[cell_key] = true
	var interior_data: Variant = data.get("interior_stations", {})
	if not (interior_data is Dictionary):
		return false
	for parent_id in interior_data:
		if not (parent_id is String) or not (structures_data is Dictionary) or not structures_data.has(str(parent_id)):
			return false
		var parent_structure: Variant = structures_data.get(str(parent_id), {})
		if not (parent_structure is Dictionary) or str(parent_structure.get("kind", "")) != "workshop" or str(parent_structure.get("state", "")) != "operational":
			return false
		var station_values: Variant = interior_data.get(parent_id, {})
		if not (station_values is Dictionary) or station_values.size() > 32:
			return false
		var occupied_interior_cells: Array = []
		var unique_station_kinds := {}
		for station_id in station_values:
			var station_value: Variant = station_values.get(station_id, {})
			if not (station_id is String) or str(station_id).is_empty() or not (station_value is Dictionary):
				return false
			var interior_station: Dictionary = station_value
			var station_kind := str(interior_station.get("kind", ""))
			var station_definition := ContentRegistry.interior_station_definition(station_kind)
			var station_cell: Variant = interior_station.get("cell", [])
			var station_state := str(interior_station.get("state", ""))
			if station_definition.is_empty() or str(station_definition.get("structure_kind", "")) != "workshop" or not (station_cell is Array) or station_cell.size() != 2 or station_state not in ["blueprint", "building", "operational"]:
				return false
			if bool(station_definition.get("unique", true)):
				if unique_station_kinds.has(station_kind):
					return false
				unique_station_kinds[station_kind] = true
			if str(interior_station.get("id", station_id)) != str(station_id) or str(interior_station.get("structure_id", parent_id)) != str(parent_id):
				return false
			if not _valid_integer(station_cell[0], -32, 32) or not _valid_integer(station_cell[1], -32, 32) or not _valid_integer(interior_station.get("rotation", 0), 0, 3):
				return false
			if not _valid_number(interior_station.get("remaining_hours", 0.0), 0.0, 100000.0) or not _valid_number(interior_station.get("total_hours", 0.0), 0.0, 100000.0):
				return false
			var station_cost: Dictionary = station_definition.get("cost", {})
			var station_delivered: Variant = interior_station.get("delivered_materials", {})
			if not (station_delivered is Dictionary):
				return false
			for delivered_material_id in station_delivered:
				if not station_cost.has(str(delivered_material_id)):
					return false
			var station_total_hours := float(interior_station.get("total_hours", 0.0))
			var station_remaining_hours := float(interior_station.get("remaining_hours", 0.0))
			if not is_equal_approx(station_total_hours, float(station_definition.get("hours", 12.0))) or station_remaining_hours > station_total_hours + 0.0001:
				return false
			var station_fully_delivered := true
			for material_id in station_cost:
				if not _valid_integer(station_delivered.get(str(material_id), 0), 0, int(station_cost[material_id])):
					return false
				if int(station_delivered.get(str(material_id), 0)) < int(station_cost[material_id]):
					station_fully_delivered = false
			if station_state == "blueprint" and (station_remaining_hours != 0.0 or station_fully_delivered):
				return false
			if station_state == "building" and (not station_fully_delivered or station_remaining_hours <= 0.0):
				return false
			if station_state == "operational" and (not station_fully_delivered or station_remaining_hours != 0.0):
				return false
			var station_footprint := ContentRegistry.interior_station_footprint(station_kind, int(interior_station.get("rotation", 0)))
			var interior_layout := _interior_layout_from_structure(parent_structure)
			if not InteriorGrid.can_place(Vector2i(int(station_cell[0]), int(station_cell[1])), station_footprint, _layout_room_size(interior_layout), _layout_float(interior_layout, "door_width", 1.45), occupied_interior_cells, Vector2i(2147483647, 2147483647), _layout_door_facing(interior_layout), _layout_float(interior_layout, "cell_size", 1.0), _layout_float(interior_layout, "wall_clearance", 0.45), _layout_float(interior_layout, "door_clearance_depth", 0.85)):
				return false
			for cell_value in InteriorGrid.cells_for(Vector2i(int(station_cell[0]), int(station_cell[1])), station_footprint):
				occupied_interior_cells.append(cell_value)
	var saved_job: Variant = data.get("station_job", {})
	if saved_job is Dictionary and str(saved_job.get("kind", "none")) != "none":
		var saved_job_parent := str(saved_job.get("structure_id", ""))
		var saved_job_station := str(saved_job.get("station_id", ""))
		var saved_job_parent_data: Variant = interior_data.get(saved_job_parent, {})
		var saved_job_station_data: Variant = saved_job_parent_data.get(saved_job_station, {}) if saved_job_parent_data is Dictionary else {}
		var saved_job_recipe := ContentRegistry.workshop_recipe(str(saved_job.get("kind", "")))
		var saved_job_capability := str(saved_job_recipe.get("requires_capability", "workshop_crafting"))
		var saved_job_station_definition := ContentRegistry.interior_station_definition(str(saved_job_station_data.get("kind", ""))) if saved_job_station_data is Dictionary else {}
		if not (saved_job_station_data is Dictionary) or str(saved_job_station_data.get("state", "")) != "operational" or str(saved_job_station_definition.get("capability", "")) != saved_job_capability:
			return false
	var expected_workshop_capability := false
	if structures_data is Dictionary and interior_data is Dictionary:
		for saved_structure_id in structures_data:
			var saved_structure: Variant = structures_data.get(saved_structure_id, {})
			if saved_structure is Dictionary and str(saved_structure.get("kind", "")) == "workshop" and str(saved_structure.get("state", "")) == "operational":
				var saved_stations: Variant = interior_data.get(str(saved_structure_id), {})
				if saved_stations is Dictionary:
					for saved_station_id in saved_stations:
						var saved_station: Variant = saved_stations.get(saved_station_id, {})
						if saved_station is Dictionary and str(saved_station.get("kind", "")) == "workbench" and str(saved_station.get("state", "")) == "operational":
							expected_workshop_capability = true
							break
			if expected_workshop_capability:
					break
	if bool(data.get("built", {}).get("workshop", false)) != expected_workshop_capability:
		return false
	var expedition: Variant = data.get("expedition_run", {})
	if expedition is Dictionary:
		var expedition_status := str(expedition.get("status", "none"))
		if expedition_status not in ["none", "active"]:
			return false
		if expedition_status == "active" and not EXPEDITION_COSTS.has(str(expedition.get("biome_id", ""))):
			return false
		if expedition_status == "active" and source_version == SAVE_VERSION and not expedition.has("second_wind_used"):
			return false
		if expedition.has("second_wind_used") and not (expedition["second_wind_used"] is bool):
			return false
		if not _expedition_route_state_is_supported(expedition, expedition_status == "active"):
			return false
		var expedition_biome := str(expedition.get("biome_id", ""))
		var branch_id := str(expedition.get("branch_id", ""))
		if not branch_id.is_empty() and ContentRegistry.expedition_route_definition(expedition_biome, branch_id).is_empty():
			return false
		if expedition.has("objective_id") and not str(expedition.get("objective_id", "")).is_empty():
			var objective_definition := ContentRegistry.expedition_route_definition(expedition_biome, branch_id)
			if branch_id.is_empty() or str(objective_definition.get("objective_id", "")) != str(expedition.get("objective_id", "")):
				return false
		for route_flag in ["objective_complete", "shortcut_open", "cache_claimed", "return_checkpoint_crossed"]:
			if expedition.has(route_flag) and not (expedition[route_flag] is bool):
				return false
		if expedition.has("stake_active") and not (expedition["stake_active"] is bool):
			return false
		if expedition.has("stake_ticks") and not _valid_integer(expedition.get("stake_ticks", 0), 0, 100000):
			return false
		if expedition.has("pressure_elapsed_seconds") and not _valid_number(expedition.get("pressure_elapsed_seconds", 0.0), 0.0, 3600.0):
			return false
		if expedition.has("objective_kind") and str(expedition.get("objective_kind", "")) not in ["", "resource", "discovery", "guardian"]:
			return false
		if expedition.has("objective_progress") and not _valid_integer(expedition.get("objective_progress", 0), 0, 100000):
			return false
		if expedition.has("objective_target") and not _valid_integer(expedition.get("objective_target", 0), 0, 100000):
			return false
		if int(expedition.get("objective_progress", 0)) > int(expedition.get("objective_target", 0)) and int(expedition.get("objective_target", 0)) > 0:
			return false
		if bool(expedition.get("objective_complete", false)) and (int(expedition.get("objective_target", 0)) <= 0 or int(expedition.get("objective_progress", 0)) < int(expedition.get("objective_target", 0))):
			return false
		if bool(expedition.get("cache_claimed", false)) and not bool(expedition.get("objective_complete", false)):
			return false
		if bool(expedition.get("stake_active", false)) and not bool(expedition.get("cache_claimed", false)):
			return false
		var cargo: Variant = expedition.get("cargo", {})
		if not (cargo is Dictionary):
			return false
		var cargo_total := 0
		for cargo_id in cargo:
			if not (cargo_id is String) or not INVENTORY_IDS.has(str(cargo_id)) or str(cargo_id).is_empty() or not _valid_integer(cargo[cargo_id], 0, 2147483647):
				return false
			cargo_total += int(cargo[cargo_id])
		if cargo_total > int(data.get("cargo_capacity", cargo_capacity)):
			return false
		var contact_progress: Variant = expedition.get("contact_progress", {})
		if not (contact_progress is Dictionary):
			return false
		for node_id in contact_progress:
			if not (node_id is String) or str(node_id).is_empty() or not _valid_integer(contact_progress[node_id], 0, 100):
				return false
		var pickups: Variant = expedition.get("pickups", [])
		if not (pickups is Array):
			return false
		var pickup_ids := {}
		var saved_cargo_capacity := maxi(1, int(data.get("cargo_capacity", cargo_capacity)))
		for pickup_value in pickups:
			if not (pickup_value is Dictionary):
				return false
			var pickup_id := str(pickup_value.get("pickup_id", ""))
			var pickup_resource := str(pickup_value.get("resource_id", ""))
			var pickup_kind := str(pickup_value.get("pickup_kind", "resource"))
			var pickup_node_id := str(pickup_value.get("node_id", ""))
			var pickup_amount: Variant = pickup_value.get("amount", 0)
			var pickup_position: Variant = pickup_value.get("position", [])
			if pickup_kind not in ["resource", "guardian_reward"]:
				return false
			if pickup_kind == "guardian_reward":
				var guardian_definition := ContentRegistry.guardian_definition(pickup_node_id)
				var defeated_guardians: Variant = expedition.get("defeated_guardian_ids", [])
				if guardian_definition.is_empty() or not (defeated_guardians is Array) or not defeated_guardians.has(pickup_node_id) or str(guardian_definition.get("zone_id", "")) != expedition_biome or str(guardian_definition.get("reward_id", "")) != pickup_resource:
					return false
			else:
				var resource_descriptor: Dictionary = resource_node_catalog.get(pickup_node_id, {})
				if resource_contract_required and resource_descriptor.is_empty():
					return false
			if pickup_id.is_empty() or pickup_ids.has(pickup_id) or not INVENTORY_IDS.has(pickup_resource) or pickup_resource.is_empty() or not _valid_integer(pickup_amount, 1, saved_cargo_capacity) or not (pickup_position is Array) or pickup_position.size() < 3:
				return false
			for pickup_coordinate in pickup_position.slice(0, 3):
				if not _valid_number(pickup_coordinate, -100000.0, 100000.0):
					return false
			pickup_ids[pickup_id] = true
		if expedition_status == "none" and (not cargo.is_empty() or not pickups.is_empty()):
			return false
		if expedition.has("depleted_ids") and not (expedition["depleted_ids"] is Array):
			return false
		if expedition.has("defeated_guardian_ids") and not (expedition["defeated_guardian_ids"] is Array):
			return false
		for id_list_key in ["depleted_ids", "defeated_guardian_ids"]:
			var id_list: Variant = expedition.get(id_list_key, [])
			if id_list is Array:
				var seen_ids := {}
				for entry in id_list:
					if not (entry is String) or str(entry).is_empty() or seen_ids.has(str(entry)):
						return false
					seen_ids[str(entry)] = true
		var guardian_states: Variant = expedition.get("guardian_states", {})
		if not (guardian_states is Dictionary) or guardian_states.size() > ContentRegistry.GUARDIANS.size():
			return false
		var defeated_guardian_ids: Array = expedition.get("defeated_guardian_ids", []) if expedition.get("defeated_guardian_ids", []) is Array else []
		for guardian_id in guardian_states:
			if not (guardian_id is String) or str(guardian_id).is_empty() or defeated_guardian_ids.has(str(guardian_id)):
				return false
			var guardian_definition := ContentRegistry.guardian_definition(str(guardian_id))
			if guardian_definition.is_empty() or str(guardian_definition.get("zone_id", "")) != expedition_biome:
				return false
			var guardian_state: Variant = guardian_states[guardian_id]
			if not (guardian_state is Dictionary) or not _valid_integer(guardian_state.get("health", 0), 1, maxi(1, int(guardian_definition.get("health", 1)))):
				return false
			var guardian_position: Variant = guardian_state.get("position", [])
			if not (guardian_position is Array) or guardian_position.size() < 3:
				return false
			if not _valid_number(guardian_position[0], -EXPEDITION_ANCHOR_LIMIT_X, EXPEDITION_ANCHOR_LIMIT_X) or not _valid_number(guardian_position[1], -100000.0, 100000.0) or not _valid_number(guardian_position[2], -EXPEDITION_ANCHOR_LIMIT_Z, EXPEDITION_ANCHOR_LIMIT_Z):
				return false
		if expedition_status == "none" and not guardian_states.is_empty():
			return false
		if expedition.has("anchor"):
			var anchor: Variant = expedition["anchor"]
			if not (anchor is Array) or anchor.size() < 3:
				return false
			if not _valid_number(anchor[0], -EXPEDITION_ANCHOR_LIMIT_X, EXPEDITION_ANCHOR_LIMIT_X) or not _valid_number(anchor[1], -100000.0, 100000.0) or not _valid_number(anchor[2], -EXPEDITION_ANCHOR_LIMIT_Z, EXPEDITION_ANCHOR_LIMIT_Z):
				return false
	return true

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	var parse_result: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_result != OK or not (parser.data is Dictionary):
		return {}
	return parser.data

func _save_path() -> String:
	return SAVE_PATH if save_slot.is_empty() else "user://%s.json" % save_slot

func _backup_path() -> String:
	return BACKUP_PATH if save_slot.is_empty() else "user://%s.backup.json" % save_slot

func _temp_path() -> String:
	return TEMP_PATH if save_slot.is_empty() else "user://%s.tmp.json" % save_slot

func _content_grants_for_save() -> Array[String]:
	var grants: Array[String] = []
	for feature in unlocked_features:
		var feature_id := str(feature)
		if _is_known_content_grant(feature_id) and not grants.has(feature_id):
			grants.append(feature_id)
	return grants

func _to_dict() -> Dictionary:
	return {"save_version": SAVE_VERSION, "content_version": CONTENT_VERSION, "day": day, "hour": hour, "season": season, "weather": weather, "energy": energy, "max_energy": max_energy, "max_health": max_health, "health": health, "cargo_capacity": cargo_capacity, "coins": coins, "xp": xp, "level": level, "ability_points": ability_points, "stats": stats, "masteries": masteries, "inventory": inventory, "discovered": discovered, "observed_wildlife": observed_wildlife, "translated_inscriptions": translated_inscriptions, "tracked_wildlife": tracked_wildlife, "researched": researched, "blueprints": blueprints, "research_job": research_job, "research_clues": research_clues, "fishing_attempt": fishing_attempt, "built": built, "farm_plot": farm_plot, "station_job": station_job, "equipment": equipment, "nutrition": nutrition, "hydration": hydration, "livestock": livestock, "structures": structures, "interior_stations": interior_stations, "unlocked_features": _content_grants_for_save(), "unlocked_routes": unlocked_routes, "sanctuary_depleted_ids": sanctuary_depleted_ids, "sanctuary_contact_progress": sanctuary_contact_progress, "activity_receipts": activity_receipts, "activity_events": activity_events, "activity_cursor": activity_cursor, "activity_mapping_version": activity_mapping_version, "activity_minutes_total": activity_minutes_total, "activity_stat_gains": activity_stat_gains, "activity_stat_minutes": activity_stat_minutes, "activity_last_manual_epoch": activity_last_manual_epoch, "manual_activity_session": manual_activity_session, "world_seed": world_seed, "action_sequence": action_sequence, "chance_rolls": chance_rolls, "settings": settings, "last_day_transaction": last_day_transaction, "construction_progress": construction_progress, "construction_job": construction_job, "recovery_pack": recovery_pack, "market_day": market_day, "market_trades": market_trades, "market_contract_claimed_day": market_contract_claimed_day, "expedition_run": expedition_run, "quest": quest}

func _apply_dict(data: Dictionary, allow_incomplete_activity := false) -> void:
	day = maxi(1, int(data.get("day", day)))
	hour = clampf(float(data.get("hour", hour)), 0.0, 23.999999)
	season = str(data.get("season", season))
	weather = str(data.get("weather", weather))
	market_day = clampi(int(data.get("market_day", day)), 1, day)
	market_trades = {}
	market_contract_claimed_day = clampi(int(data.get("market_contract_claimed_day", 0)), 0, day)
	var stored_market_trades: Variant = data.get("market_trades", {})
	if market_day == day and stored_market_trades is Dictionary:
		for trade_key in stored_market_trades:
			if trade_key is String and stored_market_trades[trade_key] is bool and bool(stored_market_trades[trade_key]) and _market_offer_id_is_known(str(trade_key).get_slice(":", 1)):
				market_trades[str(trade_key)] = true
	if market_day != day:
		market_contract_claimed_day = 0
	max_energy = maxi(1, int(data.get("max_energy", max_energy)))
	max_health = maxi(1, int(data.get("max_health", max_health)))
	cargo_capacity = maxi(1, int(data.get("cargo_capacity", cargo_capacity)))
	energy = clampi(int(data.get("energy", energy)), 0, max_energy)
	health = clampi(int(data.get("health", health)), 1, max_health)
	coins = maxi(0, int(data.get("coins", coins)))
	xp = maxi(0, int(data.get("xp", xp)))
	level = 1 + int(xp / 100)
	ability_points = maxi(0, int(data.get("ability_points", ability_points)))
	for key in stats:
		stats[key] = maxi(1, int(data.get("stats", {}).get(key, stats[key])))
	for key in masteries:
		masteries[key] = clampi(int(data.get("masteries", {}).get(key, masteries[key])), 0, 100)
	activity_minutes_total = maxi(0, int(data.get("activity_minutes_total", activity_minutes_total)))
	var stored_activity_gains: Variant = data.get("activity_stat_gains", {})
	if stored_activity_gains is Dictionary:
		for stat_id in ContentRegistry.STAT_ORDER:
			activity_stat_gains[stat_id] = maxi(0, int(stored_activity_gains.get(stat_id, activity_stat_gains.get(stat_id, 0))))
	var stored_activity_stat_minutes: Variant = data.get("activity_stat_minutes", {})
	if stored_activity_stat_minutes is Dictionary:
		for stat_id in ContentRegistry.STAT_ORDER:
			activity_stat_minutes[stat_id] = maxi(0, int(stored_activity_stat_minutes.get(stat_id, activity_stat_minutes.get(stat_id, 0))))
	activity_last_manual_epoch = maxi(0, int(data.get("activity_last_manual_epoch", activity_last_manual_epoch)))
	activity_last_manual_ticks_msec = 0
	manual_activity_capability = ""
	if allow_incomplete_activity and activity_last_manual_epoch > 0:
		var restored_cooldown_elapsed := maxi(0, int(Time.get_unix_time_from_system()) - activity_last_manual_epoch)
		activity_last_manual_ticks_msec = Time.get_ticks_msec() - restored_cooldown_elapsed * 1000
	var stored_manual_activity: Variant = data.get("manual_activity_session", {})
	if allow_incomplete_activity and stored_manual_activity is Dictionary and str(stored_manual_activity.get("status", "idle")) == "active":
		manual_activity_session = {"status": "active", "receipt_id": str(stored_manual_activity.get("receipt_id", "")), "category": str(stored_manual_activity.get("category", "focused_work")), "started_epoch": maxi(0, int(stored_manual_activity.get("started_epoch", 0))), "duration_seconds": MANUAL_ACTIVITY_DURATION_SECONDS}
		# Re-anchor the monotonic timer when restoring an in-process rollback
		# snapshot. Disk loads deliberately take the safer idle path below.
		var restored_elapsed := maxi(0, int(Time.get_unix_time_from_system()) - int(manual_activity_session.get("started_epoch", 0)))
		manual_activity_started_ticks_msec = Time.get_ticks_msec() - restored_elapsed * 1000
		manual_activity_capability = "%s:%d:restored" % [str(manual_activity_session.get("receipt_id", "")), int(manual_activity_session.get("started_epoch", 0))]
	else:
		manual_activity_session = {"status": "idle", "receipt_id": "", "category": "focused_work", "started_epoch": 0, "duration_seconds": MANUAL_ACTIVITY_DURATION_SECONDS}
		manual_activity_started_ticks_msec = 0
	world_seed = str(data.get("world_seed", DEFAULT_WORLD_SEED)).strip_edges()
	if world_seed.is_empty() or world_seed.length() > 128:
		world_seed = DEFAULT_WORLD_SEED
	action_sequence = clampi(int(data.get("action_sequence", action_sequence)), 0, 2147483646)
	chance_rolls = {}
	var stored_chance_rolls: Variant = data.get("chance_rolls", {})
	if stored_chance_rolls is Dictionary:
		for roll_key in stored_chance_rolls:
			if roll_key is String and str(roll_key).split("|").size() == 3 and stored_chance_rolls[roll_key] is bool:
				chance_rolls[str(roll_key)] = bool(stored_chance_rolls[roll_key])
	for key in inventory:
		inventory[key] = maxi(0, int(data.get("inventory", {}).get(key, inventory[key])))
	var stored_equipment: Variant = data.get("equipment", {})
	if stored_equipment is Dictionary:
		for tool_id in equipment:
			var tool: Dictionary = stored_equipment.get(tool_id, equipment[tool_id])
			if tool is Dictionary:
				var max_durability := clampi(int(tool.get("max_durability", equipment[tool_id]["max_durability"])), 1, 1000)
				equipment[tool_id]["max_durability"] = max_durability
				equipment[tool_id]["durability"] = clampi(int(tool.get("durability", equipment[tool_id]["durability"])), 0, max_durability)
				equipment[tool_id]["wear_remainder"] = clampf(float(tool.get("wear_remainder", equipment[tool_id].get("wear_remainder", 0.0))), 0.0, 0.999999)
	nutrition = clampi(int(data.get("nutrition", nutrition)), 0, max_nutrition)
	hydration = clampi(int(data.get("hydration", hydration)), 0, max_hydration)
	discovered = []
	for entry in data.get("discovered", []):
		if entry is String and not discovered.has(str(entry)):
			discovered.append(str(entry))
	observed_wildlife = []
	for entry in data.get("observed_wildlife", []):
		if entry is String and ContentRegistry.WILDLIFE.has(str(entry)) and not observed_wildlife.has(str(entry)):
			observed_wildlife.append(str(entry))
	translated_inscriptions = []
	for entry in data.get("translated_inscriptions", []):
		if entry is String and ContentRegistry.EXPEDITION_INSCRIPTIONS.has(str(entry)) and not translated_inscriptions.has(str(entry)):
			translated_inscriptions.append(str(entry))
	tracked_wildlife = []
	for entry in data.get("tracked_wildlife", []):
		if entry is String and ContentRegistry.WILDLIFE.has(str(entry)) and not tracked_wildlife.has(str(entry)):
			tracked_wildlife.append(str(entry))
	researched = []
	for entry in data.get("researched", []):
		if entry is String and not researched.has(str(entry)):
			researched.append(str(entry))
	blueprints = []
	for entry in data.get("blueprints", []):
		if entry is String and not blueprints.has(str(entry)):
			blueprints.append(str(entry))
	research_job = data.get("research_job", research_job) if data.get("research_job", research_job) is Dictionary else research_job
	research_clues = []
	var stored_research_clues: Variant = data.get("research_clues", [])
	if stored_research_clues is Array:
		for clue_value in stored_research_clues:
			if not (clue_value is Dictionary):
				continue
			var clue: Dictionary = clue_value
			var source_id := str(clue.get("source_id", ""))
			var related_id := str(clue.get("related_id", ""))
			var clue_identity := "%s:%s" % [source_id, related_id]
			var link: Dictionary = {}
			for link_value in ContentRegistry.discovery_links(source_id):
				if link_value is Dictionary and str(link_value.get("related_id", "")) == related_id:
					link = link_value.duplicate(true)
					break
			var duplicate := false
			for existing_value in research_clues:
				if str(existing_value.get("clue_id", "")) == clue_identity:
					duplicate = true
					break
			if source_id.is_empty() or related_id.is_empty() or str(clue.get("clue_id", "")) != clue_identity or not ContentRegistry.DISCOVERIES.has(source_id) or not ContentRegistry.DISCOVERIES.has(related_id) or link.is_empty() or duplicate:
				continue
			research_clues.append({"clue_id": clue_identity, "source_id": source_id, "related_id": related_id, "destination_id": str(clue.get("destination_id", link.get("destination_id", ""))), "branch_id": str(clue.get("branch_id", link.get("branch_id", ""))), "title": str(clue.get("title", link.get("title", related_id))), "hint": str(clue.get("hint", link.get("hint", ""))), "preparation_hint": str(clue.get("preparation_hint", link.get("preparation_hint", ""))), "revealed_day": maxi(1, int(clue.get("revealed_day", day))), "action_id": str(clue.get("action_id", ""))})
	var stored_fishing_attempt: Variant = data.get("fishing_attempt", fishing_attempt)
	if stored_fishing_attempt is Dictionary:
		fishing_attempt = stored_fishing_attempt.duplicate(true)
		fishing_attempt["uncommon_catch"] = bool(fishing_attempt.get("uncommon_catch", false))
		fishing_attempt["bonus_resource_id"] = str(fishing_attempt.get("bonus_resource_id", ""))
		fishing_attempt["bonus_resource_amount"] = maxi(0, int(fishing_attempt.get("bonus_resource_amount", 0)))
		# Button state is transient and must never remain held after a reload.
		fishing_attempt["reel_pulse"] = false
	for key in built:
		built[key] = bool(data.get("built", {}).get(key, built[key]))
	var stored_livestock: Variant = data.get("livestock", {})
	if stored_livestock is Dictionary:
		for animal_id in livestock:
			var animal: Dictionary = stored_livestock.get(animal_id, livestock[animal_id])
			if animal is Dictionary:
				var restored_animal := animal.duplicate(true)
				restored_animal["trait_id"] = str(restored_animal.get("trait_id", ""))
				restored_animal["trait_progress"] = clampi(int(restored_animal.get("trait_progress", 0)), 0, 100)
				livestock[animal_id] = restored_animal
	var stored_structures: Variant = data.get("structures", {})
	if stored_structures is Dictionary:
		structures = {}
		for structure_id in stored_structures:
			var structure: Variant = stored_structures.get(structure_id, {})
			if structure is Dictionary and str(structure.get("kind", "")).is_empty() == false:
				structures[str(structure_id)] = structure.duplicate(true)
	interior_stations = {}
	var stored_interior_stations: Variant = data.get("interior_stations", {})
	if stored_interior_stations is Dictionary:
		for parent_id in stored_interior_stations:
			var parent_stations: Variant = stored_interior_stations.get(parent_id, {})
			if parent_stations is Dictionary:
				interior_stations[str(parent_id)] = parent_stations.duplicate(true)
	var stored_features: Variant = data.get("unlocked_features", [])
	if stored_features is Array:
		unlocked_features = []
		for feature in stored_features:
			var feature_id := str(feature)
			if feature is String and _is_known_content_grant(feature_id) and not unlocked_features.has(feature_id):
				unlocked_features.append(feature_id)
	var stored_routes: Variant = data.get("unlocked_routes", unlocked_routes)
	if stored_routes is Array:
		unlocked_routes = []
		for route_id in stored_routes:
			if route_id is String and EXPEDITION_COSTS.has(str(route_id)) and not unlocked_routes.has(str(route_id)):
				unlocked_routes.append(str(route_id))
		if unlocked_routes.is_empty():
			unlocked_routes = ["Whisperwood"]
	var stored_sanctuary_depleted: Variant = data.get("sanctuary_depleted_ids", [])
	if stored_sanctuary_depleted is Array:
		sanctuary_depleted_ids = []
		for node_id in stored_sanctuary_depleted:
			if node_id is String and not sanctuary_depleted_ids.has(str(node_id)):
				sanctuary_depleted_ids.append(str(node_id))
	var stored_contact_progress: Variant = data.get("sanctuary_contact_progress", {})
	if stored_contact_progress is Dictionary:
		sanctuary_contact_progress = {}
		for node_id in stored_contact_progress:
			if node_id is String and not sanctuary_depleted_ids.has(str(node_id)):
				sanctuary_contact_progress[str(node_id)] = maxi(0, int(stored_contact_progress[node_id]))
	for key in farm_plot:
		farm_plot[key] = data.get("farm_plot", {}).get(key, farm_plot[key])
	for key in station_job:
		station_job[key] = data.get("station_job", {}).get(key, station_job[key])
	_recalculate_structure_effects()
	activity_receipts = []
	for receipt in data.get("activity_receipts", []):
		activity_receipts.append(str(receipt))
	activity_events = []
	for event in data.get("activity_events", []):
		if event is Dictionary and not str(event.get("receipt_id", "")).is_empty():
			activity_events.append(event.duplicate(true))
	activity_cursor = str(data.get("activity_cursor", activity_receipts.back() if not activity_receipts.is_empty() else ""))
	activity_mapping_version = maxi(1, int(data.get("activity_mapping_version", activity_mapping_version)))
	settings = {
		"master": 0.85,
		"music": 0.70,
		"ambience": 0.65,
		"weather": 0.65,
		"effects": 0.80,
		"ui": 0.80,
		"screen_shake": true,
		"haptics": true,
	}
	var stored_settings: Variant = data.get("settings", {})
	if stored_settings is Dictionary:
		for setting_id in settings:
			if not stored_settings.has(setting_id):
				continue
			var stored_value: Variant = stored_settings[setting_id]
			if setting_id in ["screen_shake", "haptics"]:
				if stored_value is bool:
					settings[setting_id] = stored_value
			elif stored_value is int or stored_value is float:
				if is_finite(float(stored_value)):
					settings[setting_id] = clampf(float(stored_value), 0.0, 1.0)
	last_day_transaction = maxi(0, int(data.get("last_day_transaction", last_day_transaction)))
	construction_progress = clampf(float(data.get("construction_progress", construction_progress)), 0.0, 1.0)
	construction_job = data.get("construction_job", construction_job) if data.get("construction_job", construction_job) is Dictionary else construction_job
	recovery_pack = data.get("recovery_pack", {}) if data.get("recovery_pack", {}) is Dictionary else {}
	if not recovery_pack.is_empty() and str(recovery_pack.get("pack_id", "")).is_empty():
		recovery_pack["pack_id"] = "recovery_legacy_%d" % day
	expedition_run = data.get("expedition_run", expedition_run) if data.get("expedition_run", expedition_run) is Dictionary else expedition_run
	if str(expedition_run.get("status", "none")) != "active":
		expedition_run = _empty_expedition_run()
	else:
		var stored_expedition_cargo: Variant = expedition_run.get("cargo", {})
		var normalized_cargo: Dictionary = {}
		if stored_expedition_cargo is Dictionary:
			for resource_id in stored_expedition_cargo:
				if INVENTORY_IDS.has(str(resource_id)):
					normalized_cargo[str(resource_id)] = maxi(0, int(stored_expedition_cargo[resource_id]))
		expedition_run["cargo"] = normalized_cargo
		var stored_expedition_contact_progress: Variant = expedition_run.get("contact_progress", {})
		expedition_run["contact_progress"] = stored_expedition_contact_progress if stored_expedition_contact_progress is Dictionary else {}
		var stored_guardian_states: Variant = expedition_run.get("guardian_states", {})
		var normalized_guardian_states: Dictionary = {}
		var stored_defeated_guardians: Variant = expedition_run.get("defeated_guardian_ids", [])
		if stored_guardian_states is Dictionary:
			for guardian_id_value in stored_guardian_states:
				var guardian_id := str(guardian_id_value)
				var guardian_definition := ContentRegistry.guardian_definition(guardian_id)
				var guardian_state: Variant = stored_guardian_states[guardian_id_value]
				if guardian_definition.is_empty() or str(guardian_definition.get("zone_id", "")) != str(expedition_run.get("biome_id", "")) or (stored_defeated_guardians is Array and stored_defeated_guardians.has(guardian_id)) or not (guardian_state is Dictionary):
					continue
				var stored_guardian_health: Variant = guardian_state.get("health", 0)
				var stored_guardian_position: Variant = guardian_state.get("position", [])
				if not _valid_integer(stored_guardian_health, 1, maxi(1, int(guardian_definition.get("health", 1)))) or not (stored_guardian_position is Array) or stored_guardian_position.size() < 3:
					continue
				if not _valid_number(stored_guardian_position[0], -EXPEDITION_ANCHOR_LIMIT_X, EXPEDITION_ANCHOR_LIMIT_X) or not _valid_number(stored_guardian_position[1], -100000.0, 100000.0) or not _valid_number(stored_guardian_position[2], -EXPEDITION_ANCHOR_LIMIT_Z, EXPEDITION_ANCHOR_LIMIT_Z):
					continue
				normalized_guardian_states[guardian_id] = {
					"health": int(stored_guardian_health),
					"position": [float(stored_guardian_position[0]), 1.0, float(stored_guardian_position[2])],
				}
		expedition_run["guardian_states"] = normalized_guardian_states
		var stored_pickups: Variant = expedition_run.get("pickups", [])
		var normalized_pickups: Array = []
		if stored_pickups is Array:
			for pickup_value in stored_pickups:
				if pickup_value is Dictionary and not str(pickup_value.get("pickup_id", "")).is_empty():
					if not INVENTORY_IDS.has(str(pickup_value.get("resource_id", ""))):
						continue
					var pickup: Dictionary = pickup_value.duplicate(true)
					var pickup_kind := str(pickup.get("pickup_kind", "resource"))
					if pickup_kind not in ["resource", "guardian_reward"]:
						continue
					pickup["pickup_kind"] = pickup_kind
					pickup["amount"] = maxi(1, int(pickup.get("amount", 1)))
					var pickup_position: Variant = pickup.get("position", [0.0, 1.0, 0.0])
					if not (pickup_position is Array) or pickup_position.size() < 3:
						pickup_position = [0.0, 1.0, 0.0]
					pickup["position"] = [clampf(float(pickup_position[0]), -EXPEDITION_ANCHOR_LIMIT_X, EXPEDITION_ANCHOR_LIMIT_X), 1.0, clampf(float(pickup_position[2]), -EXPEDITION_ANCHOR_LIMIT_Z, EXPEDITION_ANCHOR_LIMIT_Z)]
					normalized_pickups.append(pickup)
		expedition_run["pickups"] = normalized_pickups
		var stored_anchor: Variant = expedition_run.get("anchor", [0.0, 1.0, 7.5])
		if stored_anchor is Array and stored_anchor.size() >= 3 and _valid_number(stored_anchor[0], -EXPEDITION_ANCHOR_LIMIT_X, EXPEDITION_ANCHOR_LIMIT_X) and _valid_number(stored_anchor[2], -EXPEDITION_ANCHOR_LIMIT_Z, EXPEDITION_ANCHOR_LIMIT_Z):
			expedition_run["anchor"] = [float(stored_anchor[0]), 1.0, float(stored_anchor[2])]
		else:
			expedition_run["anchor"] = [0.0, 1.0, 7.5]
		expedition_run["route_phase"] = str(expedition_run.get("route_phase", "approach"))
		var stored_route_checkpoints: Variant = expedition_run.get("route_checkpoints", [])
		var normalized_route_checkpoints: Array = []
		if stored_route_checkpoints is Array:
			for checkpoint_value in stored_route_checkpoints:
				var checkpoint_id := str(checkpoint_value)
				if checkpoint_value is String and EXPEDITION_ROUTE_CHECKPOINTS.has(checkpoint_id) and not normalized_route_checkpoints.has(checkpoint_id):
					normalized_route_checkpoints.append(checkpoint_id)
		expedition_run["route_checkpoints"] = normalized_route_checkpoints
		expedition_run["branch_id"] = str(expedition_run.get("branch_id", ""))
		expedition_run["objective_id"] = str(expedition_run.get("objective_id", ""))
		var stored_route_definition := ContentRegistry.expedition_route_definition(str(expedition_run.get("biome_id", "")), str(expedition_run.get("branch_id", "")))
		if not stored_route_definition.is_empty():
			var stored_objective_kind := str(expedition_run.get("objective_kind", ""))
			var stored_objective_id := str(expedition_run.get("objective_id", ""))
			var stored_objective_target := int(expedition_run.get("objective_target", 0))
			expedition_run["objective_kind"] = stored_objective_kind if not stored_objective_kind.is_empty() else str(stored_route_definition.get("objective_kind", ""))
			expedition_run["objective_id"] = stored_objective_id if not stored_objective_id.is_empty() else str(stored_route_definition.get("objective_id", ""))
			expedition_run["objective_target"] = maxi(1, stored_objective_target if stored_objective_target > 0 else int(stored_route_definition.get("objective_target", 1)))
			expedition_run["objective_progress"] = clampi(int(expedition_run.get("objective_progress", 0)), 0, int(expedition_run.get("objective_target", 1)))
		else:
			expedition_run["objective_kind"] = str(expedition_run.get("objective_kind", ""))
			expedition_run["objective_target"] = maxi(0, int(expedition_run.get("objective_target", 0)))
			expedition_run["objective_progress"] = maxi(0, int(expedition_run.get("objective_progress", 0)))
		expedition_run["objective_complete"] = bool(expedition_run.get("objective_complete", false))
		expedition_run["shortcut_open"] = bool(expedition_run.get("shortcut_open", false))
		expedition_run["cache_claimed"] = bool(expedition_run.get("cache_claimed", false))
		expedition_run["return_checkpoint_crossed"] = bool(expedition_run.get("return_checkpoint_crossed", false)) or str(expedition_run.get("route_phase", "")) == "return"
		expedition_run["stake_active"] = bool(expedition_run.get("stake_active", false))
		expedition_run["stake_ticks"] = maxi(0, int(expedition_run.get("stake_ticks", 0)))
		var stored_pressure_elapsed: Variant = expedition_run.get("pressure_elapsed_seconds", 0.0)
		expedition_run["pressure_elapsed_seconds"] = clampf(float(stored_pressure_elapsed), 0.0, 3600.0) if _valid_number(stored_pressure_elapsed, 0.0, 3600.0) else 0.0
		expedition_run["second_wind_used"] = bool(expedition_run.get("second_wind_used", false))
	quest = data.get("quest", quest) if data.get("quest", quest) is Dictionary else quest
	var loaded_first_run_stage := str(quest.get("first_run_stage", "meet_mira"))
	if not FIRST_RUN_STAGES.has(loaded_first_run_stage):
		loaded_first_run_stage = "meet_mira"
	quest["first_run_stage"] = loaded_first_run_stage
	quest["first_run_completed"] = bool(quest.get("first_run_completed", loaded_first_run_stage == "complete")) or loaded_first_run_stage == "complete"
	_recalculate_stat_derived_state()
	_sync_mastery_permissions()

func _empty_expedition_run() -> Dictionary:
	return {"status": "none", "run_id": "", "biome_id": "", "cargo": {}, "pickups": [], "depleted_ids": [], "contact_progress": {}, "defeated_guardian_ids": [], "guardian_states": {}, "camp_used": false, "started_day": 0, "route_phase": "none", "branch_id": "", "objective_id": "", "objective_kind": "", "objective_progress": 0, "objective_target": 0, "objective_complete": false, "shortcut_open": false, "cache_claimed": false, "return_checkpoint_crossed": false, "stake_active": false, "stake_ticks": 0, "pressure_elapsed_seconds": 0.0, "second_wind_used": false, "route_checkpoints": [], "anchor": [0.0, 1.0, 7.5]}
