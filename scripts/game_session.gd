class_name ProdewtyGameSession
extends Node

const ContentRegistry = preload("res://scripts/content_registry.gd")
const SettlementGrid = preload("res://scripts/settlement_grid.gd")

## The authoritative, serializable gameplay state for the expedition loop.
## Presentation nodes submit commands here through main.gd and receive signals.

signal state_changed
signal feedback_requested(kind: String, payload: Dictionary)

const SAVE_VERSION := 7
const CONTENT_VERSION := 1
const SAVE_PATH := "user://prodewty_save.json"
const BACKUP_PATH := "user://prodewty_save.backup.json"
const TEMP_PATH := "user://prodewty_save.tmp.json"
const BASE_CARGO_CAPACITY := 12

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
var inventory := {"wood": 0, "stone": 0, "fiber": 0, "slime_gel": 0, "ore": 0, "sunstone": 0, "relic": 0, "berries": 0, "shell": 0, "fish": 0, "wheat": 2, "flour": 0, "bread": 0, "omelette": 0, "tonic": 0, "egg": 0, "plank": 0, "water": 3}
var discovered: Array[String] = []
var researched: Array[String] = []
var blueprints: Array[String] = []
var research_job := {"status": "idle", "discovery_id": "", "ready_day": 0}
var built := {"workshop": false, "library": false, "livestock_pen": false}
var farm_plot := {"state": "empty", "crop": "wheat", "growth": 0, "watered": false}
var station_job := {"kind": "none", "remaining_hours": 0.0, "output_id": "plank", "output": 0}
var equipment := {
	"hatchet": {"durability": 18, "max_durability": 18},
	"pickaxe": {"durability": 18, "max_durability": 18},
	"fishing_knife": {"durability": 12, "max_durability": 12},
}
var nutrition := 72
var hydration := 76
var max_nutrition := 100
var max_hydration := 100
var livestock := {
	"clover": {"species": "chicken", "name": "Clover", "hunger": 65, "health": 100, "last_fed_day": 0, "production_ready": false, "product_id": "egg", "product_amount": 1},
}
var unlocked_features: Array[String] = []
var unlocked_routes: Array[String] = ["Whisperwood"]
var sanctuary_depleted_ids: Array[String] = []
var sanctuary_contact_progress := {}
var structures := {}
var activity_receipts: Array[String] = []
var activity_events: Array[Dictionary] = []
var activity_cursor := ""
var activity_mapping_version := 1
var last_day_transaction := 0
var construction_progress := 0.0
var construction_job := {"status": "none", "remaining_hours": 0.0}
var recovery_pack := {}
var quest := {"id": "first_supply_run", "title": "FIRST SUPPLY RUN", "description": "Return from an expedition with 5 cargo.", "progress": 0, "target": 5, "claimed": false}
var expedition_run := {
	"status": "none",
	"run_id": "",
	"biome_id": "",
	"cargo": {},
	"depleted_ids": [],
	"contact_progress": {},
	"defeated_guardian_ids": [],
	"started_day": 0,
	"anchor": [0.0, 1.0, 7.5],
}
var save_slot := ""
var save_blocked := false

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

func add_item(id: String, amount: int) -> void:
	if amount <= 0:
		return
	if not inventory.has(id):
		inventory[id] = 0
	inventory[id] = int(inventory[id]) + amount
	state_changed.emit()

func remove_item(id: String, amount: int) -> bool:
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

func pay_items(cost: Dictionary) -> bool:
	if not has_items(cost):
		return false
	for id in cost:
		inventory[id] = int(inventory[id]) - int(cost[id])
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
		ability_points += next_level - previous_level
	state_changed.emit()

func award_mastery(name: String, amount: int) -> void:
	if not masteries.has(name) or amount <= 0:
		return
	masteries[name] = mini(100, int(masteries[name]) + amount)
	for permission in _sync_mastery_permissions():
		feedback_requested.emit("mastery_unlock", permission)
	state_changed.emit()

func _sync_mastery_permissions() -> Array[Dictionary]:
	var newly_unlocked: Array[Dictionary] = []
	for mastery_name in ContentRegistry.MASTERY_PERMISSIONS:
		var definition: Dictionary = ContentRegistry.MASTERY_PERMISSIONS.get(mastery_name, {})
		var feature := str(definition.get("feature", ""))
		if feature.is_empty() or int(masteries.get(str(mastery_name), 0)) < int(definition.get("threshold", 100)) or unlocked_features.has(feature):
			continue
		unlocked_features.append(feature)
		newly_unlocked.append({"mastery": str(mastery_name), "feature": feature, "label": str(definition.get("label", feature)), "summary": str(definition.get("summary", "Permission unlocked."))})
	return newly_unlocked

func has_permission(feature: String) -> bool:
	return not feature.is_empty() and unlocked_features.has(feature)

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
	if hours <= 0.0:
		return false
	hour = fmod(hour + hours, 24.0)
	return true

func _tool_for_resource(resource_id: String) -> String:
	match resource_id:
		"wood": return "hatchet"
		"stone", "ore", "sunstone": return "pickaxe"
		"shell": return "fishing_knife"
	return ""

func use_tool_for_resource(resource_id: String) -> bool:
	if not _consume_tool_durability(resource_id):
		return false
	state_changed.emit()
	return true

func spend_resource_contact(resource_id: String) -> bool:
	if energy <= 0 or not can_use_tool_for_resource(resource_id):
		return false
	energy -= 1
	if not _consume_tool_durability(resource_id):
		energy += 1
		return false
	state_changed.emit()
	return true

func _consume_tool_durability(resource_id: String) -> bool:
	var tool_id := _tool_for_resource(resource_id)
	if tool_id.is_empty():
		return true
	var tool: Dictionary = equipment.get(tool_id, {})
	if int(tool.get("durability", 0)) <= 0:
		return false
	tool["durability"] = maxi(0, int(tool.get("durability", 0)) - 1)
	equipment[tool_id] = tool
	return true

func can_use_tool_for_resource(resource_id: String) -> bool:
	var tool_id := _tool_for_resource(resource_id)
	if tool_id.is_empty():
		return true
	return int(equipment.get(tool_id, {}).get("durability", 0)) > 0

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
	if not pay_items(cost):
		return false
	tool["durability"] = maximum
	equipment[tool_id] = tool
	award_mastery("Crafting", 4)
	state_changed.emit()
	return true

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
			health = mini(max_health, health + 18)
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

func apply_player_damage(amount: int) -> Dictionary:
	if amount <= 0:
		return {"ok": false, "health": health, "fainted": false}
	health = maxi(0, health - amount)
	state_changed.emit()
	return {"ok": true, "health": health, "fainted": health <= 0}

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
		add_item("wheat", 3)
		farm_plot["state"] = "tilled"
		farm_plot["growth"] = 0
		farm_plot["watered"] = false
		award_mastery("Farming", 12)
		return {"ok": true, "action": "harvested", "amount": 3}
	if state == "planted" and not bool(farm_plot.get("watered", false)):
		if int(inventory.get("water", 0)) < 1 or energy < 1:
			return {"ok": false, "reason": "water"}
		spend_energy(1)
		remove_item("water", 1)
		farm_plot["watered"] = true
		state_changed.emit()
		return {"ok": true, "action": "watered"}
	return {"ok": false, "reason": "growing"}

func start_workshop_job(recipe_id: String) -> Dictionary:
	if not bool(built.get("workshop", false)):
		return {}
	if str(station_job.get("kind", "none")) != "none":
		return {}
	var recipe := ContentRegistry.workshop_recipe(recipe_id)
	var required_feature := str(recipe.get("requires_feature", ""))
	if not required_feature.is_empty() and not unlocked_features.has(required_feature):
		return {}
	if recipe.is_empty() or not pay_items(recipe.get("cost", {})):
		return {}
	station_job = {"kind": recipe_id, "remaining_hours": float(recipe.get("hours", 12.0)), "total_hours": float(recipe.get("hours", 12.0)), "output_id": recipe_id, "output": int(recipe.get("output", 0))}
	state_changed.emit()
	return station_job.duplicate(true)

func resolve_trade_offer(offer_id: String) -> Dictionary:
	for offer in ContentRegistry.TRADE_OFFERS:
		if str(offer.get("id", "")) != offer_id:
			continue
		var cost: Dictionary = offer.get("cost", {})
		if not has_items(cost):
			return {}
		for item_id in cost:
			inventory[str(item_id)] = int(inventory.get(str(item_id), 0)) - int(cost[item_id])
		var base_payout := int(offer.get("payout", 0))
		var payout := base_payout
		if has_permission("market_favor"):
			payout = int(ceil(float(base_payout) * 1.25))
		coins += payout
		award_mastery("Trading", 8)
		award_xp(10)
		state_changed.emit()
		return {"offer_id": offer_id, "payout": payout, "base_payout": base_payout, "market_favor": has_permission("market_favor")}
	return {}

func resolve_attack_damage(base_damage: int) -> int:
	if base_damage <= 0:
		return 0
	return base_damage + (2 if has_permission("combat_training") else 0)

func claim_workshop_job() -> Dictionary:
	if str(station_job.get("kind", "none")) == "none" or float(station_job.get("remaining_hours", 0.0)) > 0.0:
		return {}
	var output_id := str(station_job.get("output_id", ""))
	var output := int(station_job.get("output", 0))
	if output_id.is_empty() or output <= 0:
		return {}
	add_item(output_id, output)
	station_job = {"kind": "none", "remaining_hours": 0.0, "total_hours": 0.0, "output_id": output_id, "output": 0}
	award_mastery("Crafting", 10)
	return {"output_id": output_id, "output": output}

func start_workshop_construction() -> bool:
	if bool(built.get("workshop", false)) or str(construction_job.get("status", "none")) != "none":
		return false
	if not pay_items({"wood": 6, "stone": 4}):
		return false
	construction_progress = 0.0
	construction_job = {"status": "building", "remaining_hours": 12.0, "total_hours": 12.0}
	state_changed.emit()
	return true

func drink_water() -> bool:
	if int(inventory.get("water", 0)) <= 0 or hydration >= max_hydration:
		return false
	inventory["water"] = int(inventory.get("water", 0)) - 1
	hydration = mini(max_hydration, hydration + 34)
	energy = mini(max_energy, energy + 1)
	award_mastery("Surviving", 2)
	state_changed.emit()
	return true

func build_livestock_pen() -> bool:
	if bool(built.get("livestock_pen", false)):
		return false
	if not pay_items({"wood": 4, "fiber": 2}):
		return false
	built["livestock_pen"] = true
	award_mastery("Livestock", 5)
	state_changed.emit()
	return true

func build_library() -> bool:
	if bool(built.get("library", false)):
		return false
	if not pay_items({"wood": 4, "stone": 4}):
		return false
	built["library"] = true
	award_mastery("Research", 5)
	state_changed.emit()
	return true

func feed_livestock(animal_id := "clover") -> bool:
	if not bool(built.get("livestock_pen", false)) or not livestock.has(animal_id):
		return false
	var animal: Dictionary = livestock.get(animal_id, {})
	if int(animal.get("hunger", 0)) >= 90 or not remove_item("wheat", 1):
		return false
	animal["hunger"] = mini(100, int(animal.get("hunger", 0)) + 35)
	animal["last_fed_day"] = day
	animal["health"] = mini(100, int(animal.get("health", 0)) + 5)
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
	add_item(product_id, amount)
	animal["production_ready"] = false
	livestock[animal_id] = animal
	award_mastery("Livestock", 8)
	award_xp(8)
	state_changed.emit()
	return {product_id: amount}

func allocate_stat(name: String) -> bool:
	if ability_points <= 0 or not stats.has(name):
		return false
	ability_points -= 1
	stats[name] = int(stats[name]) + 1
	state_changed.emit()
	return true

func record_activity(receipt_id: String, minutes: int, metadata: Dictionary = {}) -> bool:
	if receipt_id.is_empty() or activity_receipts.has(receipt_id) or minutes <= 0:
		return false
	activity_receipts.append(receipt_id)
	var event := {
		"receipt_id": receipt_id,
		"event_id": str(metadata.get("event_id", receipt_id)),
		"source_id": str(metadata.get("source_id", "manual_ui")),
		"occurred_at": str(metadata.get("occurred_at", "")),
		"timezone": str(metadata.get("timezone", "")),
		"payload_hash": str(metadata.get("payload_hash", "")),
		"mapping_version": maxi(1, int(metadata.get("mapping_version", activity_mapping_version))),
		"minutes": minutes,
	}
	activity_events.append(event)
	activity_cursor = receipt_id
	var reward := clampi(int(minutes / 10), 1, 20)
	award_xp(reward)
	energy = mini(max_energy, energy + mini(6, reward))
	state_changed.emit()
	feedback_requested.emit("activity", {"minutes": minutes, "xp": reward})
	return true

func record_discovery(discovery_id: String) -> bool:
	if discovery_id.is_empty():
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

func research_discovery(discovery_id: String) -> bool:
	if not ContentRegistry.DISCOVERIES.has(discovery_id) or not bool(built.get("library", false)) or not discovered.has(discovery_id) or researched.has(discovery_id) or str(research_job.get("status", "idle")) != "idle":
		return false
	research_job = {"status": "researching", "discovery_id": discovery_id, "ready_day": day + 1}
	state_changed.emit()
	return true

func claim_research() -> bool:
	if str(research_job.get("status", "idle")) != "ready":
		return false
	var discovery_id := str(research_job.get("discovery_id", ""))
	if discovery_id.is_empty() or not ContentRegistry.DISCOVERIES.has(discovery_id) or not discovered.has(discovery_id) or researched.has(discovery_id):
		research_job = {"status": "idle", "discovery_id": "", "ready_day": 0}
		return false
	researched.append(discovery_id)
	var blueprint := ContentRegistry.discovery_blueprint(discovery_id)
	if not blueprints.has(blueprint):
		blueprints.append(blueprint)
		var grant := ContentRegistry.discovery_grant(discovery_id)
		if not grant.is_empty() and not unlocked_features.has(grant):
			unlocked_features.append(grant)
		award_mastery("Research", 16)
	research_job = {"status": "idle", "discovery_id": "", "ready_day": 0}
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
		"run_id": "%s-%d-%d" % [biome_id.to_lower().replace(" ", "-"), day, Time.get_ticks_msec()],
		"biome_id": biome_id,
		"cargo": {},
		"depleted_ids": [],
		"contact_progress": {},
		"defeated_guardian_ids": [],
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
		"stake_active": false,
		"stake_ticks": 0,
	}
	state_changed.emit()
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
	if not has_active_expedition() or str(expedition_run.get("objective_id", "")) != objective_id or bool(expedition_run.get("objective_complete", false)):
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
	if amount <= 0 or not has_active_expedition() or bool(expedition_run.get("objective_complete", false)):
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
	if not has_active_expedition() or not ContentRegistry.EXPEDITION_ROUTE_DEFINITIONS.has(str(expedition_run.get("biome_id", ""))) or ContentRegistry.expedition_route_definition(str(expedition_run.get("biome_id", "")), branch_id).is_empty():
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
	state_changed.emit()
	return true

func expedition_route_snapshot() -> Dictionary:
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
		"branch_options": expedition_branch_options(),
		"branch_definition": expedition_route_definition(),
	}

func open_expedition_cache() -> Dictionary:
	if not has_active_expedition() or str(expedition_run.get("biome_id", "")) != "Whisperwood":
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
	award_xp(8)
	state_changed.emit()
	return {"branch_id": branch_id, "loot": reward.duplicate(true), "energy_cost": 2}

func open_expedition_capstone() -> Dictionary:
	if not has_active_expedition():
		return {}
	if str(expedition_run.get("biome_id", "")) == "Whisperwood":
		return open_expedition_cache()
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
	award_xp(8)
	state_changed.emit()
	return {"branch_id": branch_id, "loot": reward.duplicate(true), "energy_cost": 2}

func apply_expedition_stake_tick() -> Dictionary:
	if not has_active_expedition() or not bool(expedition_run.get("stake_active", false)):
		return {}
	var biome_id := str(expedition_run.get("biome_id", ""))
	var energy_loss := 1
	var message := "The route is demanding a safe return."
	match biome_id:
		"Sunlit Beach": message = "The tide turns. Keep moving toward the beacon."
		"Ember Ridge": message = "The ridge shudders. Ash and loose stone drain your pace."
		"Glass Desert": message = "The glass desert takes its toll. Find shade before the next flare."
		"Sunken Dungeon": message = "Floodwater rises around the old causeway."
		_: energy_loss = 0
	if energy_loss <= 0:
		return {}
	var health_loss := 0
	if energy < energy_loss:
		health_loss = 4
		energy = 0
	else:
		energy -= energy_loss
	expedition_run["stake_ticks"] = int(expedition_run.get("stake_ticks", 0)) + 1
	state_changed.emit()
	return {"energy_loss": energy_loss, "health_loss": health_loss, "message": message, "ticks": int(expedition_run.get("stake_ticks", 0))}

func collect_expedition_resource(node_id: String, resource_id: String, amount: int) -> bool:
	return collect_expedition_resource_with_tool(node_id, resource_id, amount)

func collect_expedition_resource_with_tool(node_id: String, resource_id: String, amount: int) -> bool:
	if not has_active_expedition() or node_id.is_empty() or resource_id.is_empty() or amount <= 0:
		return false
	if _route_objective_is_off_branch("resource", resource_id):
		return false
	for discovery_id in ContentRegistry.DISCOVERIES:
		if node_id.to_lower().contains(str(discovery_id).to_lower().replace(" ", "")) and _route_objective_is_off_branch("discovery", str(discovery_id)):
			return false
	if not can_carry_expedition_amount(amount):
		return false
	var depleted: Array = expedition_run.get("depleted_ids", [])
	if depleted.has(node_id) or energy <= 0 or not can_use_tool_for_resource(resource_id):
		return false
	energy -= 1
	if not _consume_tool_durability(resource_id):
		energy += 1
		return false
	var cargo: Dictionary = expedition_run.get("cargo", {})
	cargo[resource_id] = int(cargo.get(resource_id, 0)) + amount
	depleted.append(node_id)
	var contact_progress: Dictionary = expedition_run.get("contact_progress", {})
	contact_progress.erase(node_id)
	expedition_run["cargo"] = cargo
	expedition_run["depleted_ids"] = depleted
	expedition_run["contact_progress"] = contact_progress
	_advance_expedition_objective("resource", resource_id, amount)
	state_changed.emit()
	return true

func record_expedition_contact(node_id: String, contacts_done: int) -> bool:
	if not has_active_expedition() or node_id.is_empty() or contacts_done <= 0:
		return false
	var depleted: Array = expedition_run.get("depleted_ids", [])
	if depleted.has(node_id):
		return false
	var contact_progress: Dictionary = expedition_run.get("contact_progress", {})
	var previous := int(contact_progress.get(node_id, 0))
	if contacts_done <= previous:
		return false
	contact_progress[node_id] = contacts_done
	expedition_run["contact_progress"] = contact_progress
	state_changed.emit()
	return true

func complete_expedition_resource(node_id: String, resource_id: String, amount: int, required_contacts: int = 1) -> bool:
	if not has_active_expedition() or node_id.is_empty() or resource_id.is_empty() or amount <= 0:
		return false
	if _route_objective_is_off_branch("resource", resource_id):
		return false
	for discovery_id in ContentRegistry.DISCOVERIES:
		if node_id.to_lower().contains(str(discovery_id).to_lower().replace(" ", "")) and _route_objective_is_off_branch("discovery", str(discovery_id)):
			return false
	if not can_carry_expedition_amount(amount):
		return false
	var depleted: Array = expedition_run.get("depleted_ids", [])
	if depleted.has(node_id):
		return false
	var contact_progress: Dictionary = expedition_run.get("contact_progress", {})
	if required_contacts > 1 and int(contact_progress.get(node_id, 0)) < required_contacts - 1:
		return false
	var cargo: Dictionary = expedition_run.get("cargo", {})
	cargo[resource_id] = int(cargo.get(resource_id, 0)) + amount
	depleted.append(node_id)
	contact_progress.erase(node_id)
	expedition_run["cargo"] = cargo
	expedition_run["depleted_ids"] = depleted
	expedition_run["contact_progress"] = contact_progress
	if resource_id == "berries" and str(expedition_run.get("biome_id", "")) == "Whisperwood" and str(expedition_run.get("branch_id", "")) == "grove" and node_id.to_lower().contains("whisperglass"):
		_advance_expedition_objective("discovery", "Whisperglass", 1)
	else:
		_advance_expedition_objective("resource", resource_id, amount)
	state_changed.emit()
	return true

func mark_sanctuary_depleted(node_id: String) -> bool:
	if node_id.is_empty() or sanctuary_depleted_ids.has(node_id):
		return false
	sanctuary_depleted_ids.append(node_id)
	sanctuary_contact_progress.erase(node_id)
	state_changed.emit()
	return true

func is_sanctuary_depleted(node_id: String) -> bool:
	return not node_id.is_empty() and sanctuary_depleted_ids.has(node_id)

func record_sanctuary_contact(node_id: String, contacts_done: int) -> bool:
	if node_id.is_empty() or contacts_done <= 0 or sanctuary_depleted_ids.has(node_id):
		return false
	sanctuary_contact_progress[node_id] = contacts_done
	state_changed.emit()
	return true

func restore_sanctuary_resources() -> void:
	if sanctuary_depleted_ids.is_empty():
		return
	sanctuary_depleted_ids.clear()
	sanctuary_contact_progress.clear()
	state_changed.emit()

func _structure_cells(structure_id: String, origin: Vector2i) -> Array[Vector2i]:
	var definition := ContentRegistry.structure_definition(structure_id)
	var footprint_data: Array = definition.get("footprint", [1, 1])
	return SettlementGrid.cells_for(origin, Vector2i(int(footprint_data[0]), int(footprint_data[1])))

func structure_blueprint_requirement(structure_id: String) -> String:
	return str(ContentRegistry.structure_definition(structure_id).get("requires_blueprint", ""))

func has_structure_blueprint(structure_id: String) -> bool:
	if not ContentRegistry.STRUCTURES.has(structure_id):
		return false
	var requirement := structure_blueprint_requirement(structure_id)
	return requirement.is_empty() or blueprints.has(requirement)

func can_place_structure(structure_id: String, cell: Array) -> bool:
	if not ContentRegistry.STRUCTURES.has(structure_id) or cell.size() < 2:
		return false
	if not has_structure_blueprint(structure_id):
		return false
	var origin := Vector2i(int(cell[0]), int(cell[1]))
	var candidate_cells := _structure_cells(structure_id, origin)
	if not SettlementGrid.inside_bounds(candidate_cells):
		return false
	for candidate_cell in candidate_cells:
		if _fixed_cell_occupied(candidate_cell):
			return false
	for existing_id in structures:
		var existing: Dictionary = structures.get(existing_id, {})
		if str(existing.get("state", "removed")) == "removed":
			continue
		if str(existing.get("kind", "")) == structure_id:
			return false
		var existing_origin_data: Array = existing.get("cell", [])
		if existing_origin_data.size() < 2:
			continue
		var existing_cells := _structure_cells(str(existing.get("kind", "")), Vector2i(int(existing_origin_data[0]), int(existing_origin_data[1])))
		for candidate_cell in candidate_cells:
			if existing_cells.has(candidate_cell):
				return false
	return true

func _fixed_cell_occupied(cell: Vector2i) -> bool:
	for rect in FIXED_RESERVED_RECTS:
		if cell.x >= int(rect[0]) and cell.x <= int(rect[2]) and cell.y >= int(rect[1]) and cell.y <= int(rect[3]):
			return true
	for rect in ContentRegistry.ROUTE_RESERVED_RECTS:
		if cell.x >= int(rect[0]) and cell.x <= int(rect[2]) and cell.y >= int(rect[1]) and cell.y <= int(rect[3]):
			return true
	return false

func place_structure(structure_id: String, cell: Array) -> Dictionary:
	if not can_place_structure(structure_id, cell):
		return {}
	var definition := ContentRegistry.structure_definition(structure_id)
	var cost: Dictionary = definition.get("cost", {})
	var structure_id_instance := "%s_%03d" % [structure_id, structures.size() + 1]
	var delivered_materials := {}
	for material_id in cost:
		delivered_materials[str(material_id)] = 0
	structures[structure_id_instance] = {"id": structure_id_instance, "kind": structure_id, "cell": [int(cell[0]), int(cell[1])], "state": "blueprint", "remaining_hours": 0.0, "total_hours": float(definition.get("hours", 24.0)), "delivered_materials": delivered_materials}
	state_changed.emit()
	return structures[structure_id_instance].duplicate(true)

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
		award_mastery("Crafting", 8)
	structures[instance_id] = structure
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

func mark_guardian_defeated(guardian_id: String) -> bool:
	if not has_active_expedition() or guardian_id.is_empty():
		return false
	var defeated: Array = expedition_run.get("defeated_guardian_ids", [])
	if defeated.has(guardian_id):
		return false
	defeated.append(guardian_id)
	expedition_run["defeated_guardian_ids"] = defeated
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
	if reward_id.is_empty() or reward_amount <= 0 or not can_carry_expedition_amount(reward_amount):
		return {}
	defeated.append(guardian_id)
	var cargo: Dictionary = expedition_run.get("cargo", {})
	cargo[reward_id] = int(cargo.get(reward_id, 0)) + reward_amount
	expedition_run["defeated_guardian_ids"] = defeated
	expedition_run["cargo"] = cargo
	var route_definition := expedition_route_definition()
	if str(route_definition.get("objective_kind", "")) == "guardian" and str(route_definition.get("objective_id", "")) == guardian_id:
		_advance_expedition_objective("guardian", guardian_id, 1)
	award_xp(18)
	award_mastery("Attacking", 12)
	state_changed.emit()
	return {"guardian_id": guardian_id, "reward_id": reward_id, "reward_amount": reward_amount}

func use_expedition_camp() -> bool:
	if not has_active_expedition() or bool(expedition_run.get("camp_used", false)):
		return false
	expedition_run["camp_used"] = true
	energy = mini(max_energy, energy + 6)
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
	state_changed.emit()
	return true

func claim_construction() -> bool:
	if bool(built.get("workshop", false)) or str(construction_job.get("status", "none")) != "ready":
		return false
	built["workshop"] = true
	construction_job = {"status": "none", "remaining_hours": 0.0}
	construction_progress = 0.0
	state_changed.emit()
	return true

func finish_expedition() -> Dictionary:
	if not has_active_expedition():
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
	var anchor := [clampf(float(position[0]), -14.0, 14.0), 1.0, clampf(float(position[2]), -10.0, 10.0)]
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
	if not (loot is Dictionary):
		return {}
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
	if not (loot is Dictionary):
		return {}
	var total := 0
	for resource_id in loot:
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
	hour = 7.0
	energy = max_energy
	health = max_health
	nutrition = maxi(0, nutrition - 14)
	hydration = maxi(0, hydration - 18)
	if nutrition < 20 or hydration < 20:
		health = maxi(1, health - 8)
	if farm_plot["state"] == "planted":
		if farm_plot["watered"]:
			farm_plot["growth"] = mini(3, int(farm_plot["growth"]) + 1)
		farm_plot["watered"] = false
	if station_job["kind"] != "none":
		station_job["remaining_hours"] = maxf(0.0, float(station_job["remaining_hours"]) - 12.0)
		if float(station_job["remaining_hours"]) <= 0.0:
			station_job["output"] = maxi(1, int(station_job["output"]))
	if str(research_job.get("status", "idle")) == "researching" and int(research_job.get("ready_day", day + 1)) <= day:
		research_job["status"] = "ready"
	if str(construction_job.get("status", "none")) == "building":
		construction_job["remaining_hours"] = maxf(0.0, float(construction_job.get("remaining_hours", 0.0)) - 12.0)
		var construction_total := maxf(1.0, float(construction_job.get("total_hours", 12.0)))
		construction_progress = 1.0 - clampf(float(construction_job["remaining_hours"]) / construction_total, 0.0, 1.0)
		if float(construction_job["remaining_hours"]) <= 0.0:
			construction_job["status"] = "ready"
	for animal_id in livestock:
		var animal: Dictionary = livestock.get(animal_id, {})
		animal["hunger"] = maxi(0, int(animal.get("hunger", 0)) - 16)
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
	if bool(quest.get("claimed", false)):
		quest = {"id": "supply_run_%d" % day, "title": "NEXT SUPPLY RUN", "description": "Return from an expedition with 5 cargo.", "progress": 0, "target": 5, "claimed": false}
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
		"workshop": built["workshop"] = true
		"archive": built["library"] = true
		"livestock_pen": built["livestock_pen"] = true
	_recalculate_structure_effects()

func _recalculate_structure_effects() -> void:
	var derived_capacity := BASE_CARGO_CAPACITY
	for structure_id in structures:
		var structure: Dictionary = structures.get(structure_id, {})
		if str(structure.get("state", "")) != "operational":
			continue
		var definition := ContentRegistry.structure_definition(str(structure.get("kind", "")))
		derived_capacity += int(definition.get("cargo_bonus", 0))
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
	file.store_string(JSON.stringify(payload))
	file.flush()
	file.close()
	var candidate := _read_json(temp_path)
	if candidate.is_empty() or int(candidate.get("save_version", 0)) != SAVE_VERSION:
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
				return false
			backup_file.store_string(JSON.stringify(previous_payload))
			backup_file.flush()
			backup_file.close()
	var rename_result := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(save_path))
	# On macOS Godot can report an error after the rename has already happened.
	# Only use the compatibility fallback while the candidate still exists.
	if rename_result != OK and FileAccess.file_exists(temp_path):
		var final_file := FileAccess.open(save_path, FileAccess.WRITE)
		if final_file == null:
			return false
		final_file.store_string(JSON.stringify(payload))
		final_file.flush()
		final_file.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
	var result: bool = not FileAccess.file_exists(temp_path) and not _read_json(save_path).is_empty()
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
	_apply_dict(snapshot)
	state_changed.emit()

func load_game() -> bool:
	var primary := _read_json(_save_path())
	var backup := _read_json(_backup_path())
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
		var primary_future := not primary.is_empty() and (int(primary.get("save_version", 0)) > SAVE_VERSION or int(primary.get("content_version", 0)) > CONTENT_VERSION)
		var backup_future := not backup.is_empty() and (int(backup.get("save_version", 0)) > SAVE_VERSION or int(backup.get("content_version", 0)) > CONTENT_VERSION)
		if primary_future and (backup.is_empty() or backup_future):
			save_blocked = true
		return false
	# Older saves intentionally fill new fields from the current defaults;
	# loading never replays old rewards or transactions.
	_apply_dict(payload)
	state_changed.emit()
	return true

func _migrate_payload(raw: Dictionary) -> Dictionary:
	if raw.is_empty():
		return {}
	var version := int(raw.get("save_version", 0))
	if version <= 0 or version > SAVE_VERSION:
		return {}
	var data := raw.duplicate(true)
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
				if not old_structure.has("total_hours"):
					old_structure["total_hours"] = float(old_structure.get("remaining_hours", old_definition.get("hours", 24.0)))
				if str(old_structure.get("state", "")) == "operational":
					old_structure["remaining_hours"] = 0.0
				old_structures[old_id] = old_structure
			data["structures"] = old_structures
	if not data.has("unlocked_routes"):
		# Saves from before route gating already exposed every expedition. Preserve
		# that player's access; only a truly new session starts at Whisperwood.
		data["unlocked_routes"] = EXPEDITION_COSTS.keys()
	data["save_version"] = SAVE_VERSION
	if not data.has("content_version"):
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
	for key in ["stats", "masteries", "inventory", "built", "farm_plot", "station_job", "equipment", "livestock", "structures", "sanctuary_contact_progress", "research_job", "construction_job", "recovery_pack", "expedition_run", "quest"]:
		if data.has(key) and not (data[key] is Dictionary):
			return false
	for key in ["discovered", "researched", "blueprints", "activity_receipts", "activity_events", "unlocked_features", "unlocked_routes", "sanctuary_depleted_ids"]:
		if data.has(key) and not (data[key] is Array):
			return false
	if data.has("unlocked_routes"):
		for route_id in data["unlocked_routes"]:
			if not (route_id is String) or not EXPEDITION_COSTS.has(str(route_id)):
				return false
	var saved_max_energy := int(data.get("max_energy", max_energy))
	var saved_max_health := int(data.get("max_health", max_health))
	var saved_day := int(data.get("day", day))
	if data.has("cargo_capacity") and not _valid_integer(data["cargo_capacity"], 1, 1000):
		return false
	if data.has("content_version") and not _valid_integer(data["content_version"], 1, CONTENT_VERSION):
		return false
	if not _valid_integer(data.get("max_energy", max_energy), 1, 1000) or not _valid_integer(data.get("max_health", max_health), 1, 1000):
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
	var stats_data: Variant = data.get("stats", {})
	if stats_data is Dictionary:
		for stat_id in stats_data:
			if not _valid_integer(stats_data[stat_id], 1, 1000):
				return false
	var mastery_data: Variant = data.get("masteries", {})
	if mastery_data is Dictionary:
		for mastery_id in mastery_data:
			if not _valid_integer(mastery_data[mastery_id], 0, 100):
				return false
	var inventory_data: Variant = data.get("inventory", {})
	if inventory_data is Dictionary:
		for item_id in inventory_data:
			if not _valid_integer(inventory_data[item_id], 0, 2147483647):
				return false
	var equipment_data: Variant = data.get("equipment", {})
	if equipment_data is Dictionary:
		for tool_id in equipment_data:
			var tool: Variant = equipment_data[tool_id]
			if not (tool is Dictionary) or not _valid_integer(tool.get("max_durability", 1), 1, 1000) or not _valid_integer(tool.get("durability", 0), 0, int(tool.get("max_durability", 1))):
				return false
	var farm: Variant = data.get("farm_plot", {})
	if farm is Dictionary:
		if str(farm.get("state", "empty")) not in ["empty", "tilled", "planted"] or not _valid_integer(farm.get("growth", 0), 0, 3) or not (farm.get("watered", false) is bool):
			return false
	var station: Variant = data.get("station_job", {})
	if station is Dictionary:
		var station_kind := str(station.get("kind", "none"))
		if station_kind != "none" and not ContentRegistry.WORKSHOP_RECIPES.has(station_kind):
			return false
		if not _valid_integer(station.get("remaining_hours", 0), 0, 100000):
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
			if not _valid_integer(recovery["loot"][recovery_id], 1, 2147483647):
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
		if research_status != "idle":
			var research_id := str(research.get("discovery_id", ""))
			var discovered_data: Variant = data.get("discovered", [])
			if not ContentRegistry.DISCOVERIES.has(research_id) or not (discovered_data is Array) or not discovered_data.has(research_id) or not _valid_integer(research.get("ready_day", 0), 0, 2147483647):
				return false
	var structures_data: Variant = data.get("structures", {})
	var occupied_saved_cells := {}
	if structures_data is Dictionary:
		for structure_id in structures_data:
			var structure: Variant = structures_data.get(structure_id, {})
			if not (structure is Dictionary):
				return false
			var kind := str(structure.get("kind", ""))
			var structure_cell: Variant = structure.get("cell", [])
			var structure_state := str(structure.get("state", ""))
			if not ContentRegistry.STRUCTURES.has(kind) or not (structure_cell is Array) or structure_cell.size() != 2 or structure_state not in ["blueprint", "building", "operational"]:
				return false
			if not _valid_integer(structure_cell[0], SettlementGrid.MIN_X, SettlementGrid.MAX_X) or not _valid_integer(structure_cell[1], SettlementGrid.MIN_Z, SettlementGrid.MAX_Z):
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
			var footprint_data: Array = ContentRegistry.structure_definition(kind).get("footprint", [1, 1])
			var cells := SettlementGrid.cells_for(Vector2i(int(structure_cell[0]), int(structure_cell[1])), Vector2i(int(footprint_data[0]), int(footprint_data[1])))
			if not SettlementGrid.inside_bounds(cells):
				return false
			for cell in cells:
				if _fixed_cell_occupied(cell):
					return false
				var cell_key := "%d:%d" % [cell.x, cell.y]
				if occupied_saved_cells.has(cell_key):
					return false
				occupied_saved_cells[cell_key] = true
	var expedition: Variant = data.get("expedition_run", {})
	if expedition is Dictionary:
		var expedition_status := str(expedition.get("status", "none"))
		if expedition_status not in ["none", "active"]:
			return false
		if expedition_status == "active" and not EXPEDITION_COSTS.has(str(expedition.get("biome_id", ""))):
			return false
		var expedition_biome := str(expedition.get("biome_id", ""))
		var branch_id := str(expedition.get("branch_id", ""))
		if not branch_id.is_empty() and ContentRegistry.expedition_route_definition(expedition_biome, branch_id).is_empty():
			return false
		if expedition.has("objective_id") and not str(expedition.get("objective_id", "")).is_empty():
			var objective_definition := ContentRegistry.expedition_route_definition(expedition_biome, branch_id)
			if branch_id.is_empty() or str(objective_definition.get("objective_id", "")) != str(expedition.get("objective_id", "")):
				return false
		if expedition.has("route_phase") and str(expedition.get("route_phase", "approach")) not in ["none", "approach", "branch", "objective", "capstone", "shortcut"]:
			return false
		for route_flag in ["objective_complete", "shortcut_open", "cache_claimed"]:
			if expedition.has(route_flag) and not (expedition[route_flag] is bool):
				return false
		if expedition.has("stake_active") and not (expedition["stake_active"] is bool):
			return false
		if expedition.has("stake_ticks") and not _valid_integer(expedition.get("stake_ticks", 0), 0, 100000):
			return false
		if expedition.has("objective_kind") and str(expedition.get("objective_kind", "")) not in ["", "resource", "discovery", "guardian"]:
			return false
		if expedition.has("objective_progress") and not _valid_integer(expedition.get("objective_progress", 0), 0, 100000):
			return false
		if expedition.has("objective_target") and not _valid_integer(expedition.get("objective_target", 0), 0, 100000):
			return false
		if int(expedition.get("objective_progress", 0)) > int(expedition.get("objective_target", 0)) and int(expedition.get("objective_target", 0)) > 0:
			return false
		if bool(expedition.get("objective_complete", false)) and int(expedition.get("objective_target", 0)) > 0 and int(expedition.get("objective_progress", 0)) < int(expedition.get("objective_target", 0)):
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
			if not _valid_integer(cargo[cargo_id], 0, 2147483647):
				return false
			cargo_total += int(cargo[cargo_id])
		if cargo_total > int(data.get("cargo_capacity", cargo_capacity)):
			return false
		var contact_progress: Variant = expedition.get("contact_progress", {})
		if not (contact_progress is Dictionary):
			return false
		for node_id in contact_progress:
			if not _valid_integer(contact_progress[node_id], 0, 100):
				return false
		if expedition.has("depleted_ids") and not (expedition["depleted_ids"] is Array):
			return false
		if expedition.has("defeated_guardian_ids") and not (expedition["defeated_guardian_ids"] is Array):
			return false
		if expedition.has("anchor"):
			var anchor: Variant = expedition["anchor"]
			if not (anchor is Array) or anchor.size() < 3:
				return false
			for anchor_value in anchor.slice(0, 3):
				if not _valid_number(anchor_value, -100000.0, 100000.0):
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

func _to_dict() -> Dictionary:
	return {"save_version": SAVE_VERSION, "content_version": CONTENT_VERSION, "day": day, "hour": hour, "season": season, "weather": weather, "energy": energy, "max_energy": max_energy, "max_health": max_health, "health": health, "cargo_capacity": cargo_capacity, "coins": coins, "xp": xp, "level": level, "ability_points": ability_points, "stats": stats, "masteries": masteries, "inventory": inventory, "discovered": discovered, "researched": researched, "blueprints": blueprints, "research_job": research_job, "built": built, "farm_plot": farm_plot, "station_job": station_job, "equipment": equipment, "nutrition": nutrition, "hydration": hydration, "livestock": livestock, "structures": structures, "unlocked_features": unlocked_features, "unlocked_routes": unlocked_routes, "sanctuary_depleted_ids": sanctuary_depleted_ids, "sanctuary_contact_progress": sanctuary_contact_progress, "activity_receipts": activity_receipts, "activity_events": activity_events, "activity_cursor": activity_cursor, "activity_mapping_version": activity_mapping_version, "last_day_transaction": last_day_transaction, "construction_progress": construction_progress, "construction_job": construction_job, "recovery_pack": recovery_pack, "expedition_run": expedition_run, "quest": quest}

func _apply_dict(data: Dictionary) -> void:
	day = maxi(1, int(data.get("day", day)))
	hour = clampf(float(data.get("hour", hour)), 0.0, 23.999999)
	season = str(data.get("season", season))
	weather = str(data.get("weather", weather))
	max_energy = maxi(1, int(data.get("max_energy", max_energy)))
	max_health = maxi(1, int(data.get("max_health", max_health)))
	cargo_capacity = maxi(1, int(data.get("cargo_capacity", cargo_capacity)))
	energy = clampi(int(data.get("energy", energy)), 0, max_energy)
	health = clampi(int(data.get("health", health)), 1, max_health)
	coins = maxi(0, int(data.get("coins", coins)))
	xp = maxi(0, int(data.get("xp", xp)))
	level = maxi(1, int(data.get("level", level)))
	ability_points = maxi(0, int(data.get("ability_points", ability_points)))
	for key in stats:
		stats[key] = maxi(1, int(data.get("stats", {}).get(key, stats[key])))
	for key in masteries:
		masteries[key] = clampi(int(data.get("masteries", {}).get(key, masteries[key])), 0, 100)
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
	nutrition = clampi(int(data.get("nutrition", nutrition)), 0, max_nutrition)
	hydration = clampi(int(data.get("hydration", hydration)), 0, max_hydration)
	discovered = []
	for entry in data.get("discovered", []):
		if entry is String and not discovered.has(str(entry)):
			discovered.append(str(entry))
	researched = []
	for entry in data.get("researched", []):
		if entry is String and not researched.has(str(entry)):
			researched.append(str(entry))
	blueprints = []
	for entry in data.get("blueprints", []):
		if entry is String and not blueprints.has(str(entry)):
			blueprints.append(str(entry))
	research_job = data.get("research_job", research_job) if data.get("research_job", research_job) is Dictionary else research_job
	for key in built:
		built[key] = bool(data.get("built", {}).get(key, built[key]))
	var stored_livestock: Variant = data.get("livestock", {})
	if stored_livestock is Dictionary:
		for animal_id in livestock:
			var animal: Dictionary = stored_livestock.get(animal_id, livestock[animal_id])
			if animal is Dictionary:
				livestock[animal_id] = animal.duplicate(true)
	var stored_structures: Variant = data.get("structures", {})
	if stored_structures is Dictionary:
		structures = {}
		for structure_id in stored_structures:
			var structure: Variant = stored_structures.get(structure_id, {})
			if structure is Dictionary and str(structure.get("kind", "")).is_empty() == false:
				structures[str(structure_id)] = structure.duplicate(true)
				if str(structure.get("state", "")) == "operational":
					_activate_structure_kind(str(structure.get("kind", "")))
	var stored_features: Variant = data.get("unlocked_features", [])
	if stored_features is Array:
		unlocked_features = []
		for feature in stored_features:
			if feature is String and not unlocked_features.has(str(feature)):
				unlocked_features.append(str(feature))
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
	activity_receipts = []
	for receipt in data.get("activity_receipts", []):
		activity_receipts.append(str(receipt))
	activity_events = []
	for event in data.get("activity_events", []):
		if event is Dictionary and not str(event.get("receipt_id", "")).is_empty():
			activity_events.append(event.duplicate(true))
	activity_cursor = str(data.get("activity_cursor", activity_receipts.back() if not activity_receipts.is_empty() else ""))
	activity_mapping_version = maxi(1, int(data.get("activity_mapping_version", activity_mapping_version)))
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
		var stored_expedition_contact_progress: Variant = expedition_run.get("contact_progress", {})
		expedition_run["contact_progress"] = stored_expedition_contact_progress if stored_expedition_contact_progress is Dictionary else {}
		expedition_run["route_phase"] = str(expedition_run.get("route_phase", "approach"))
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
		expedition_run["stake_active"] = bool(expedition_run.get("stake_active", false))
		expedition_run["stake_ticks"] = maxi(0, int(expedition_run.get("stake_ticks", 0)))
	quest = data.get("quest", quest) if data.get("quest", quest) is Dictionary else quest
	_sync_mastery_permissions()

func _empty_expedition_run() -> Dictionary:
	return {"status": "none", "run_id": "", "biome_id": "", "cargo": {}, "depleted_ids": [], "contact_progress": {}, "defeated_guardian_ids": [], "camp_used": false, "started_day": 0, "route_phase": "none", "branch_id": "", "objective_id": "", "objective_kind": "", "objective_progress": 0, "objective_target": 0, "objective_complete": false, "shortcut_open": false, "cache_claimed": false, "stake_active": false, "stake_ticks": 0, "anchor": [0.0, 1.0, 7.5]}
