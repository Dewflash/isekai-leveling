extends SceneTree

const ContentRegistry = preload("res://scripts/content_registry.gd")

const EXPECTED_MASTERIES := [
	"Farming", "Mining", "Attacking", "Foraging", "Fishing", "Crafting",
	"Livestock", "Language", "Trading", "Hunting", "Surviving", "Research",
]
const EXPECTED_TIERS := ["Bronze", "Silver", "Gold", "Platinum"]
const EXPECTED_THRESHOLDS := [20, 45, 70, 95]
const LEGACY_BRONZE_PERMISSIONS := ["Crafting", "Trading", "Attacking"]

var failures: Array[String] = []
var checks_run := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> bool:
	checks_run += 1
	if condition:
		return true
	failures.append(message)
	push_error("PROGRESSION_REGISTRY_FAIL: " + message)
	return false

func _run() -> void:
	var mastery_ids := ContentRegistry.mastery_ids()
	_check(mastery_ids == EXPECTED_MASTERIES, "mastery_ids returns the authoritative ordered set of 12 masteries")
	_check(ContentRegistry.MASTERY_DEFINITIONS.size() == EXPECTED_MASTERIES.size(), "registry defines exactly 12 masteries")
	_check(ContentRegistry.MASTERY_TIER_ORDER == EXPECTED_TIERS, "tier order is Bronze, Silver, Gold, Platinum")

	# The helper result is a copy; mutating it cannot alter later lookups.
	mastery_ids.append("Injected")
	_check(ContentRegistry.mastery_ids() == EXPECTED_MASTERIES, "mastery_ids returns a stable copy")

	var seen_labels: Dictionary = {}
	var seen_features: Dictionary = {}
	for mastery_name in EXPECTED_MASTERIES:
		_check(ContentRegistry.MASTERY_DEFINITIONS.has(mastery_name), "%s has an authoritative definition" % mastery_name)
		var definition := ContentRegistry.mastery_definition(mastery_name)
		_check(not definition.is_empty(), "%s lookup is not empty" % mastery_name)
		_check(str(definition.get("label", "")).strip_edges() != "", "%s has a display label" % mastery_name)
		_check(str(definition.get("summary", "")).strip_edges() != "", "%s has a summary" % mastery_name)

		var tiers := ContentRegistry.mastery_tiers(mastery_name)
		if not _check(tiers.size() == EXPECTED_TIERS.size(), "%s has exactly four tiers" % mastery_name):
			continue

		var previous_threshold := -1
		for tier_index in EXPECTED_TIERS.size():
			var tier: Dictionary = tiers[tier_index]
			var tier_name := str(tier.get("tier", ""))
			var threshold := int(tier.get("threshold", -1))
			var label := str(tier.get("label", "")).strip_edges()
			var feature := str(tier.get("feature", "")).strip_edges()
			var permission: Variant = tier.get("permission", {})
			var effects: Variant = tier.get("effects", {})

			_check(tier_name == EXPECTED_TIERS[tier_index], "%s tier %d is %s" % [mastery_name, tier_index, EXPECTED_TIERS[tier_index]])
			_check(threshold == EXPECTED_THRESHOLDS[tier_index], "%s %s threshold is %d" % [mastery_name, tier_name, EXPECTED_THRESHOLDS[tier_index]])
			_check(int(ContentRegistry.MASTERY_TIER_THRESHOLDS.get(tier_name, -1)) == threshold, "%s %s matches the shared threshold table" % [mastery_name, tier_name])
			_check(threshold > previous_threshold, "%s %s threshold is strictly ordered" % [mastery_name, tier_name])
			previous_threshold = threshold

			_check(not label.is_empty(), "%s %s has a non-empty label" % [mastery_name, tier_name])
			_check(not seen_labels.has(label), "%s %s label is globally unique: %s" % [mastery_name, tier_name, label])
			seen_labels[label] = true
			_check(not feature.is_empty(), "%s %s has a non-empty feature" % [mastery_name, tier_name])
			_check(not seen_features.has(feature), "%s %s feature is globally unique: %s" % [mastery_name, tier_name, feature])
			seen_features[feature] = true
			_check(str(tier.get("summary", "")).strip_edges() != "", "%s %s has a meaningful summary" % [mastery_name, tier_name])

			if _check(permission is Dictionary and not (permission as Dictionary).is_empty(), "%s %s has permission metadata" % [mastery_name, tier_name]):
				var permission_data := permission as Dictionary
				_check(str(permission_data.get("rule", "")).strip_edges() != "", "%s %s permission names an authoritative rule" % [mastery_name, tier_name])
				_check(str(permission_data.get("scope", "")).strip_edges() != "", "%s %s permission names its scope" % [mastery_name, tier_name])
			if _check(effects is Dictionary and not (effects as Dictionary).is_empty(), "%s %s has concrete effect metadata" % [mastery_name, tier_name]):
				for effect_key in (effects as Dictionary):
					_check(str(effect_key).strip_edges() != "", "%s %s effect key is non-empty" % [mastery_name, tier_name])
					var effect_value: Variant = (effects as Dictionary)[effect_key]
					_check(effect_value is int or effect_value is float, "%s %s effect %s is numeric and directly consumable" % [mastery_name, tier_name, str(effect_key)])
					if effect_value is int or effect_value is float:
						_check(is_finite(float(effect_value)) and not is_zero_approx(float(effect_value)), "%s %s effect %s is finite and non-zero" % [mastery_name, tier_name, str(effect_key)])

			var named_lookup := ContentRegistry.mastery_tier_definition(mastery_name, tier_name)
			_check(named_lookup == tier, "%s %s named lookup is stable" % [mastery_name, tier_name])
			_check(ContentRegistry.mastery_tier_for_points(mastery_name, threshold) == tier, "%s %s unlocks exactly at its threshold" % [mastery_name, tier_name])
			_check(ContentRegistry.next_mastery_tier(mastery_name, threshold - 1) == tier, "%s %s is next immediately below its threshold" % [mastery_name, tier_name])

			var expected_before: Dictionary = {} if tier_index == 0 else tiers[tier_index - 1]
			_check(ContentRegistry.mastery_tier_for_points(mastery_name, threshold - 1) == expected_before, "%s points below %s resolve to the previous tier" % [mastery_name, tier_name])
			var expected_next: Dictionary = {} if tier_index == EXPECTED_TIERS.size() - 1 else tiers[tier_index + 1]
			_check(ContentRegistry.next_mastery_tier(mastery_name, threshold) == expected_next, "%s points at %s resolve the following tier" % [mastery_name, tier_name])

		_check(ContentRegistry.mastery_tier_for_points(mastery_name, -1).is_empty(), "%s has no tier below Bronze" % mastery_name)
		_check(str(ContentRegistry.mastery_tier_for_points(mastery_name, 100).get("tier", "")) == "Platinum", "%s remains Platinum at the mastery cap" % mastery_name)
		_check(str(ContentRegistry.mastery_tier_for_points(mastery_name, 1000).get("tier", "")) == "Platinum", "%s lookup is stable above the mastery cap" % mastery_name)
		_check(ContentRegistry.next_mastery_tier(mastery_name, 100).is_empty(), "%s has no tier after Platinum" % mastery_name)

	_check(seen_labels.size() == EXPECTED_MASTERIES.size() * EXPECTED_TIERS.size(), "all 48 tier labels are globally unique")
	_check(seen_features.size() == EXPECTED_MASTERIES.size() * EXPECTED_TIERS.size(), "all 48 tier features are globally unique")

	# Existing GameSession consumers still receive the original Bronze contract.
	for mastery_name in LEGACY_BRONZE_PERMISSIONS:
		var legacy: Dictionary = ContentRegistry.MASTERY_PERMISSIONS.get(mastery_name, {})
		var bronze := ContentRegistry.mastery_tier_definition(mastery_name, "Bronze")
		for key in ["threshold", "feature", "label", "summary"]:
			_check(legacy.get(key) == bronze.get(key), "%s legacy %s matches its Bronze definition" % [mastery_name, key])

	# Deep-copy guarantees cover nested tier, permission, and effect dictionaries.
	var mutated_definition := ContentRegistry.mastery_definition("Farming")
	var mutated_tiers: Array = mutated_definition["tiers"]
	var mutated_bronze: Dictionary = mutated_tiers[0]
	mutated_bronze["label"] = "Mutated Label"
	(mutated_bronze["permission"] as Dictionary)["rule"] = "mutated_rule"
	(mutated_bronze["effects"] as Dictionary)["seed_refund_chance"] = 99.0
	var fresh_bronze := ContentRegistry.mastery_tier_definition("Farming", "Bronze")
	_check(str(fresh_bronze.get("label", "")) == "Seed Saver", "definition lookup protects nested tier labels")
	_check(str((fresh_bronze.get("permission", {}) as Dictionary).get("rule", "")) == "recover_seed_on_harvest", "definition lookup protects nested permission metadata")
	_check(is_equal_approx(float((fresh_bronze.get("effects", {}) as Dictionary).get("seed_refund_chance", 0.0)), 0.10), "definition lookup protects nested effect metadata")

	var mutated_named_lookup := ContentRegistry.mastery_tier_definition("Mining", "Bronze")
	mutated_named_lookup["feature"] = "injected_feature"
	_check(str(ContentRegistry.mastery_tier_definition("Mining", "Bronze").get("feature", "")) == "mining_vein_reader", "named tier lookup returns a fresh copy")
	var mutated_tier_list := ContentRegistry.mastery_tiers("Fishing")
	(mutated_tier_list[0] as Dictionary)["threshold"] = 999
	_check(int(ContentRegistry.mastery_tiers("Fishing")[0].get("threshold", -1)) == 20, "tier-list lookup returns a deep copy")

	_check(ContentRegistry.mastery_definition("Unknown").is_empty(), "unknown mastery definition is empty")
	_check(ContentRegistry.mastery_tiers("Unknown").is_empty(), "unknown mastery tiers are empty")
	_check(ContentRegistry.mastery_tier_definition("Farming", "Diamond").is_empty(), "unknown tier definition is empty")
	_check(ContentRegistry.mastery_tier_for_points("Unknown", 100).is_empty(), "unknown mastery point lookup is empty")
	_check(ContentRegistry.next_mastery_tier("Unknown", 0).is_empty(), "unknown mastery next-tier lookup is empty")

	var seen_research_links: Dictionary = {}
	for source_id in ContentRegistry.DISCOVERIES:
		var links: Array = ContentRegistry.discovery_links(str(source_id))
		_check(links.size() <= 1, "%s has at most one deterministic Cross Reference lead" % str(source_id))
		for link_value in links:
			var link: Dictionary = link_value
			var related_id := str(link.get("related_id", ""))
			var destination_id := str(link.get("destination_id", ""))
			var branch_id := str(link.get("branch_id", ""))
			var link_key := "%s:%s" % [str(source_id), related_id]
			_check(ContentRegistry.DISCOVERIES.has(related_id) and related_id != str(source_id), "%s Cross Reference points to a distinct known discovery" % str(source_id))
			_check(not seen_research_links.has(link_key), "%s Cross Reference link is unique" % link_key)
			seen_research_links[link_key] = true
			_check(ContentRegistry.EXPEDITIONS.has(destination_id), "%s Cross Reference names a real destination" % link_key)
			_check(ContentRegistry.expedition_branch_ids(destination_id).has(branch_id), "%s Cross Reference names an authored branch" % link_key)
			for field_name in ["title", "hint", "preparation_hint"]:
				_check(not str(link.get(field_name, "")).strip_edges().is_empty(), "%s Cross Reference has %s" % [link_key, field_name])
	var copied_links := ContentRegistry.discovery_links("Tideglass")
	if not copied_links.is_empty():
		(copied_links[0] as Dictionary)["title"] = "Mutated"
		_check(str(ContentRegistry.discovery_links("Tideglass")[0].get("title", "")) != "Mutated", "discovery link lookup returns a deep copy")

	# Guardian behavior is content, not a renderer-side recolor. Every roster
	# entry must provide the timing, reach, pursuit, and reward contract that the
	# live Guardian node consumes.
	var guardian_behaviors: Dictionary = {}
	for guardian_id in ContentRegistry.GUARDIANS:
		var guardian_definition: Dictionary = ContentRegistry.guardian_definition(str(guardian_id))
		_check(not guardian_definition.is_empty(), "%s has an authoritative guardian definition" % str(guardian_id))
		for field_name in ["zone_id", "enemy_label", "reward_id", "behavior_id"]:
			_check(not str(guardian_definition.get(field_name, "")).strip_edges().is_empty(), "%s guardian field %s is non-empty" % [str(guardian_id), field_name])
		for field_name in ["reward_amount", "health", "attack_damage"]:
			_check(int(guardian_definition.get(field_name, 0)) > 0, "%s guardian field %s is positive" % [str(guardian_id), field_name])
		for field_name in ["move_speed", "attack_range", "attack_windup", "attack_cooldown", "attack_recovery", "pursuit_radius"]:
			_check(float(guardian_definition.get(field_name, 0.0)) > 0.0, "%s guardian field %s is positive" % [str(guardian_id), field_name])
		_check(float(guardian_definition.get("pursuit_radius", 0.0)) > float(guardian_definition.get("attack_range", 0.0)), "%s guardian pursuit exceeds attack reach" % str(guardian_id))
		guardian_behaviors[str(guardian_definition.get("behavior_id", ""))] = true
	_check(guardian_behaviors.has("chaser"), "guardian roster includes a chaser behavior")
	_check(guardian_behaviors.has("skirmisher"), "guardian roster includes a skirmisher behavior")
	_check(guardian_behaviors.has("bruiser"), "guardian roster includes a bruiser behavior")
	_check(guardian_behaviors.has("sentinel"), "guardian roster includes a sentinel behavior")

	if failures.is_empty():
		print("PROGRESSION_REGISTRY_PASS checks=%d masteries=%d tiers=%d" % [checks_run, EXPECTED_MASTERIES.size(), seen_features.size()])
		quit(0)
		return
	print("PROGRESSION_REGISTRY_FAIL count=%d checks=%d" % [failures.size(), checks_run])
	for index in failures.size():
		print("  %02d. %s" % [index + 1, failures[index]])
	quit(1)
