class_name ProdewtyContentRegistry
extends RefCounted

## Immutable content definitions. Runtime state belongs to GameSession; this
## file only answers what a destination or discovery means.

const EXPEDITIONS := {
	"Whisperwood": {"travel_energy": 2, "surface": "dirt", "summary": "A living forest of forage, stone, and hungry things."},
	"Sunlit Beach": {"travel_energy": 3, "surface": "sand", "summary": "Tideglass, driftwood, and a wraith beneath the surf."},
	"Ember Ridge": {"travel_energy": 4, "surface": "dirt", "summary": "Copper veins, basalt, and a golem warmed by the mountain."},
	"Glass Desert": {"travel_energy": 5, "surface": "sand", "summary": "Sunstone, cactus fiber, and a heat that taxes every step."},
	"Sunken Dungeon": {"travel_energy": 0, "entry_coins": 30, "surface": "stone", "summary": "A fixed challenge of relics, veinstone, and an armored dead."},
}

## Wildlife is authored per expedition so each route has a recognizable living
## signature. Positions are local map coordinates; the renderer may animate and
## dress the silhouettes, while GameSession only persists observations.
const WILDLIFE := {
	"forest_rabbit": {"zone_id": "Whisperwood", "species_id": "rabbit", "label": "Meadow Rabbit", "summary": "A soft-footed rabbit that pauses where the fern trail opens.", "positions": [[-6.2, 2.8], [1.5, 4.8]], "wander_radius": 1.7, "move_speed": 0.72, "flee_distance": 1.65, "track_direction": "northwest"},
	"forest_beetle": {"zone_id": "Whisperwood", "species_id": "beetle", "label": "Grove Beetle", "summary": "A jewel-backed beetle that hums beneath the Whisperwood canopy.", "positions": [[-8.4, -1.6], [7.2, 1.0]], "wander_radius": 1.2, "move_speed": 0.34, "flee_distance": 1.25, "track_direction": "east"},
	"beach_crab": {"zone_id": "Sunlit Beach", "species_id": "crab", "label": "Tidepool Crab", "summary": "A bright crab that follows the retreating edge of the tide.", "positions": [[-7.2, -6.0], [5.2, -6.8]], "wander_radius": 1.5, "move_speed": 0.46, "flee_distance": 1.4, "track_direction": "south"},
	"ridge_marmot": {"zone_id": "Ember Ridge", "species_id": "marmot", "label": "Ridge Marmot", "summary": "A mountain marmot watching the quarry from a sun-warmed shelf.", "positions": [[-8.0, 4.5], [6.8, 6.0]], "wander_radius": 1.4, "move_speed": 0.52, "flee_distance": 1.55, "track_direction": "northeast"},
	"desert_lizard": {"zone_id": "Glass Desert", "species_id": "lizard", "label": "Glass Lizard", "summary": "A quick lizard whose scales catch the desert light like old glass.", "positions": [[-1.0, -3.4], [6.3, 1.4]], "wander_radius": 1.9, "move_speed": 0.88, "flee_distance": 1.8, "track_direction": "west"},
}

## Every route has a readable fork. The scene supplies the physical marker and
## blocked trail; GameSession owns which branch was committed and what counts
## as that branch's capstone. Keeping this table immutable makes the authored
## route language consistent across the five maps and safe to save/migrate.
const EXPEDITION_ROUTE_DEFINITIONS := {
	"Whisperwood": {
		"grove": {"label": "Whisperglass Grove", "objective_kind": "discovery", "objective_id": "Whisperglass", "objective_target": 1, "capstone_reward": {"berries": 2, "fiber": 1}, "summary": "Follow the fern trail and recover a living shard."},
		"clearing": {"label": "Guardian Clearing", "objective_kind": "guardian", "objective_id": "forest_slime", "objective_target": 1, "capstone_reward": {"slime_gel": 2}, "summary": "Take the clearing and survive the forest guardian."},
	},
	"Sunlit Beach": {
		"tidepool": {"label": "Tidepool Shelf", "objective_kind": "resource", "objective_id": "shell", "objective_target": 2, "capstone_reward": {"shell": 1}, "summary": "Read the tide and recover two Tideglass shells."},
		"wreck": {"label": "Wreckwater", "objective_kind": "guardian", "objective_id": "tide_wraith", "objective_target": 1, "capstone_reward": {"fish": 2}, "summary": "Push through the wreck and face the Tide Wraith."},
	},
	"Ember Ridge": {
		"quarry": {"label": "Copper Quarry", "objective_kind": "resource", "objective_id": "ore", "objective_target": 3, "capstone_reward": {"ore": 1}, "summary": "Work both exposed copper veins before the ridge shifts."},
		"high_pass": {"label": "Ashfall Pass", "objective_kind": "guardian", "objective_id": "ember_golem", "objective_target": 1, "capstone_reward": {"stone": 2}, "summary": "Climb the hot pass and break the Ember Golem."},
	},
	"Glass Desert": {
		"oasis": {"label": "Hidden Oasis", "objective_kind": "resource", "objective_id": "fiber", "objective_target": 4, "capstone_reward": {"fiber": 2}, "summary": "Harvest both cactus beds and leave before the heat wins."},
		"glassway": {"label": "Singing Glassway", "objective_kind": "guardian", "objective_id": "dune_wisp", "objective_target": 1, "capstone_reward": {"sunstone": 1}, "summary": "Cross the singing shards and disperse the Dune Wisp."},
	},
	"Sunken Dungeon": {
		"vault": {"label": "Aether Vault", "objective_kind": "discovery", "objective_id": "Aether Relic", "objective_target": 1, "capstone_reward": {"relic": 1}, "summary": "Recover the relic before the water closes the vault."},
		"crypt": {"label": "Flooded Crypt", "objective_kind": "guardian", "objective_id": "crypt_knight", "objective_target": 1, "capstone_reward": {"ore": 2}, "summary": "Break the crypt seal by defeating its knight."},
	},
}

const EXPEDITION_BRANCH_ORDER := {
	"Whisperwood": ["grove", "clearing"],
	"Sunlit Beach": ["tidepool", "wreck"],
	"Ember Ridge": ["quarry", "high_pass"],
	"Glass Desert": ["oasis", "glassway"],
	"Sunken Dungeon": ["vault", "crypt"],
}

## Whisperwood is the first expedition where the player should be able to
## remember the route as a set of physical places rather than a collection of
## encounter coordinates. The renderer, interaction tests, and future route
## dressing all read these sockets so the grove and guardian objective cannot
## drift apart as the map becomes richer.
const WHISPERWOOD_LANDMARKS := {
	"arrival": [0.0, 5.2],
	"fork": [0.0, -1.9],
	"grove": [-12.5, -8.6],
	"clearing": [12.5, -8.6],
	"return": [0.0, 8.7],
}

## One authoritative definition for the physical Sanctuary trailheads. The
## world renderer owns presentation, while the session owns placement safety;
## both read these same sockets so player construction cannot seal a road that
## the scene still presents as usable.
const ROUTE_SOCKETS := {
	"whisperwood": {"destination_id": "Whisperwood", "gate_position": [-11.0, -5.7], "path_center": [-7.2, -5.7], "path_size": [9.0, 1.0], "approach_rect": [-13, -7, -9, -3], "spoke_rect": [-12, -6, -2, -5], "traversal_waypoints": [[-3.0, 4.0], [-3.0, -6.8], [-11.0, -5.7]], "accent": "6fb4a1"},
	"sunlit_beach": {"destination_id": "Sunlit Beach", "gate_position": [-11.0, 1.9], "path_center": [-7.2, 1.9], "path_size": [9.0, 1.0], "approach_rect": [-13, 0, -9, 3], "spoke_rect": [-12, 1, -2, 2], "traversal_waypoints": [[-3.0, 4.0], [-3.0, 1.9], [-11.0, 1.9]], "accent": "6bc1d0"},
	"ember_ridge": {"destination_id": "Ember Ridge", "gate_position": [-10.2, 6.0], "path_center": [-6.8, 6.0], "path_size": [8.0, 1.0], "approach_rect": [-12, 4, -8, 7], "spoke_rect": [-11, 5, -2, 6], "traversal_waypoints": [[-3.0, 4.0], [-3.0, 6.0], [-10.2, 6.0]], "accent": "e28c61"},
	"glass_desert": {"destination_id": "Glass Desert", "gate_position": [11.0, -5.4], "path_center": [9.2, -5.4], "path_size": [6.0, 1.0], "approach_rect": [9, -7, 13, -3], "spoke_rect": [6, -6, 13, -5], "traversal_waypoints": [[3.0, 4.0], [3.0, -3.2], [8.2, -3.2], [8.2, -5.4], [11.0, -5.4]], "accent": "edbb6f"},
	"sunken_dungeon": {"destination_id": "Sunken Dungeon", "gate_position": [11.0, 2.0], "path_center": [9.2, 2.0], "path_size": [6.0, 1.0], "approach_rect": [9, 0, 13, 4], "spoke_rect": [6, 1, 13, 2], "traversal_waypoints": [[3.0, 4.0], [3.0, 2.0], [11.0, 2.0]], "accent": "a88ce0"},
}

const ROUTE_RESERVED_RECTS := [
	[-13, -7, -9, -3], [-12, -6, -2, -5],
	[-13, 0, -9, 3], [-12, 1, -2, 2],
	[-12, 4, -8, 7], [-11, 5, -2, 6],
	[9, -7, 13, -3], [6, -6, 13, -5],
	[9, 0, 13, 4], [6, 1, 13, 2],
]

const DISCOVERIES := {
	"Whisperglass": {"blueprint": "Whisperglass Tonic", "grant": "tonic_recipe", "summary": "A resonant forest growth that holds a night's warmth."},
	"Tideglass": {"blueprint": "Tideglass Compass", "grant": "safe_tides", "summary": "A shell that points toward safe water and hidden coves."},
	"Aether Relic": {"blueprint": "Aether Lantern", "grant": "dungeon_lantern", "summary": "A relic core that turns recovered light into a route."},
}

## Research cross-reference links are authored lore hooks, not progression
## teleports. A trained researcher can surface one next lead from a completed
## study, while the expedition still requires the player to physically find it.
const DISCOVERY_LINKS := {
	"Whisperglass": [{"related_id": "Tideglass", "destination_id": "Sunlit Beach", "branch_id": "tidepool", "title": "Tideglass Shelf", "hint": "Salt crystallizes inside the forest shard. The next trace may lie where the tide retreats.", "preparation_hint": "Bring a fishing knife and leave room for shell cargo."}],
	"Tideglass": [{"related_id": "Aether Relic", "destination_id": "Sunken Dungeon", "branch_id": "vault", "title": "Aether Vault", "hint": "The compass needle trembles toward a buried light that does not belong to the sea.", "preparation_hint": "Save 30 Coins for the dungeon entry and follow the vault branch."}],
	"Aether Relic": [{"related_id": "Whisperglass", "destination_id": "Whisperwood", "branch_id": "grove", "title": "Whisperglass Grove", "hint": "The relic's warmth echoes the living resonance of an older forest shard.", "preparation_hint": "Take the fern trail and return with a living shard sample."}],
}

## Expedition inscriptions are physical lore sockets. Each one belongs to a
## route branch so a translation rewards deliberate traversal without granting
## a player access to the other side of a committed expedition. The text is
## authored here, while the scene only supplies the plaque and interaction
## anchor.
const EXPEDITION_INSCRIPTIONS := {
	"whisperwood_root_oath": {
		"zone_id": "Whisperwood", "branch_id": "grove", "title": "Rootkeeper's Oath",
		"surface_text": "KEL  /  RUU  /  VES", "translation": "Leave one living root untouched, and the forest will leave one path open.",
		"summary": "A rootkeeper's promise to travellers who take only what they can carry.", "ancient": false, "base_xp": 8, "base_coins": 4,
	},
	"sunlit_tide_vow": {
		"zone_id": "Sunlit Beach", "branch_id": "tidepool", "title": "Tidewatcher's Vow",
		"surface_text": "SAI  /  MOR  /  NETH", "translation": "Read the water twice: once for what it gives, and once for what it takes back.",
		"summary": "A tidewatcher's warning carved above a shelf of pale shells.", "ancient": false, "base_xp": 8, "base_coins": 5,
	},
	"ember_quarry_mark": {
		"zone_id": "Ember Ridge", "branch_id": "quarry", "title": "Quarrymark of Patience",
		"surface_text": "ORU  /  TAL  /  VEK", "translation": "Strike where the mountain rings clear; haste turns a vein into rubble.",
		"summary": "A miner's mark that separates a living seam from loose stone.", "ancient": false, "base_xp": 9, "base_coins": 5,
	},
	"glass_desert_waymark": {
		"zone_id": "Glass Desert", "branch_id": "oasis", "title": "Waymark of Shade",
		"surface_text": "ASH  /  VEL  /  ORA", "translation": "The shortest road is not the safest road; carry water toward the quiet wind.",
		"summary": "A waymark left by a caravan that learned to travel by shade.", "ancient": false, "base_xp": 10, "base_coins": 6,
	},
	"sunken_vault_verse": {
		"zone_id": "Sunken Dungeon", "branch_id": "vault", "title": "Aether Vault Verse",
		"surface_text": "⟡  RETH  /  OMM  /  ARA  ⟡", "translation": "Light remembers every hand that carries it home. The vault opens for the returning, not the greedy.",
		"summary": "An ancient verse etched into the stone above the buried light.", "ancient": true, "base_xp": 14, "base_coins": 8,
	},
}

## Fishing spots are authored world contracts, not generic interactables. The
## session validates the spot and radius before bait or energy can be charged.
const FISHING_SPOTS := {
	"sanctuary_pond": {"zone_id": "Sanctuary", "anchor": [5.35, 0.0, 5.55], "interaction_radius": 2.35, "bite_delay_min": 0.85, "bite_delay_max": 1.65, "hook_window": 0.72, "reel_required": 1.0, "coastal": false},
	"sunlit_tidepool": {"zone_id": "Sunlit Beach", "anchor": [2.5, 0.0, -6.25], "interaction_radius": 2.35, "bite_delay_min": 0.70, "bite_delay_max": 1.45, "hook_window": 0.64, "reel_required": 1.0, "coastal": true, "uncommon_resource_id": "shell", "uncommon_resource_amount": 1},
}

const GUARDIANS := {
	"forest_slime": {"zone_id": "Whisperwood", "enemy_label": "FOREST SLIME", "reward_id": "slime_gel", "reward_amount": 1, "health": 18, "attack_damage": 5, "behavior_id": "chaser", "move_speed": 1.7, "attack_range": 2.4, "attack_windup": 0.38, "attack_cooldown": 1.35, "attack_recovery": 0.34, "pursuit_radius": 13.0},
	"tide_wraith": {"zone_id": "Sunlit Beach", "enemy_label": "TIDE WRAITH", "reward_id": "shell", "reward_amount": 2, "health": 22, "attack_damage": 6, "behavior_id": "skirmisher", "move_speed": 2.15, "attack_range": 2.25, "attack_windup": 0.52, "attack_cooldown": 1.05, "attack_recovery": 0.24, "pursuit_radius": 14.5},
	"ember_golem": {"zone_id": "Ember Ridge", "enemy_label": "EMBER GOLEM", "reward_id": "ore", "reward_amount": 2, "health": 30, "attack_damage": 8, "behavior_id": "bruiser", "move_speed": 1.05, "attack_range": 2.85, "attack_windup": 0.78, "attack_cooldown": 1.75, "attack_recovery": 0.52, "pursuit_radius": 11.5},
	"dune_wisp": {"zone_id": "Glass Desert", "enemy_label": "DUNE WISP", "reward_id": "sunstone", "reward_amount": 1, "health": 26, "attack_damage": 7, "behavior_id": "skirmisher", "move_speed": 2.55, "attack_range": 2.15, "attack_windup": 0.32, "attack_cooldown": 0.92, "attack_recovery": 0.18, "pursuit_radius": 16.0},
	"crypt_knight": {"zone_id": "Sunken Dungeon", "enemy_label": "CRYPT KNIGHT", "reward_id": "relic", "reward_amount": 1, "health": 42, "attack_damage": 10, "behavior_id": "sentinel", "move_speed": 1.35, "attack_range": 2.70, "attack_windup": 0.64, "attack_cooldown": 1.55, "attack_recovery": 0.44, "pursuit_radius": 10.5},
}

const WORKSHOP_RECIPES := {
	"plank": {"cost": {"wood": 3, "stone": 1}, "hours": 12.0, "output": 4, "summary": "3 Wood + 1 Stone → 4 Planks"},
	"ingot": {"cost": {"ore": 2, "stone": 1}, "hours": 12.0, "output": 2, "requires_capability": "workshop_smelting", "summary": "2 Ore + 1 Stone → 2 Ingots"},
	"bread": {"cost": {"wheat": 1, "water": 1}, "hours": 12.0, "output": 2, "summary": "1 Wheat + 1 Water → 2 Bread"},
	"omelette": {"cost": {"egg": 1, "water": 1}, "hours": 12.0, "output": 2, "summary": "1 Egg + 1 Water → 2 Omelettes"},
	"tonic": {"cost": {"berries": 1, "water": 1, "slime_gel": 1}, "hours": 12.0, "output": 1, "requires_feature": "tonic_recipe", "summary": "1 Berry + 1 Water + 1 Slime Gel → 1 Tonic"},
	"reinforced_hatchet": {"cost": {"plank": 2, "ore": 1}, "hours": 18.0, "output": 1, "output_kind": "tool", "tool_id": "hatchet", "requires_feature": "crafting_quality_work", "summary": "2 Planks + 1 Ore → Reinforced Hatchet"},
	"masterwork_pickaxe": {"cost": {"plank": 3, "ore": 2, "sunstone": 1}, "hours": 24.0, "output": 1, "output_kind": "tool", "tool_id": "pickaxe", "requires_feature": "crafting_masterwork_bench", "summary": "3 Planks + 2 Ore + 1 Sunstone → Masterwork Pickaxe"},
}

## Livestock traits are authored products of repeated care, not free inventory
## flags. The session persists only the trait id and nurture progress, while
## this registry owns the label and production bonus.
const LIVESTOCK_TRAITS := {
	"sunplume": {"label": "Sunplume", "summary": "Clover's warm plumage improves egg quality.", "product_bonus": 1},
}

## Stats are continuous character power, not labels on the HUD. The session
## owns the current values; this table defines the gameplay-facing meaning of
## each point so every stat has one inspectable, testable rule.
const STAT_ORDER := ["Strength", "Agility", "Focus", "Wisdom", "Spirituality", "Perception", "Resilience"]
const STAT_DEFINITIONS := {
	"Strength": {"label": "Strength", "summary": "Increases direct attack impact.", "effect": "attack_damage", "per_point": 2.0, "attack_damage_per_point": 2.0},
	"Agility": {"label": "Agility", "summary": "Improves movement speed and dodge recovery.", "effect": "movement_and_dodge", "per_point": 0.025, "movement_speed_per_point": 0.025, "dodge_cooldown_seconds_per_point": 0.025},
	"Focus": {"label": "Focus", "summary": "Shortens deliberate action wind-up and gathering time.", "effect": "action_timing", "per_point": 0.06, "action_windup_seconds_per_point": 0.006, "attack_cooldown_seconds_per_point": 0.012, "gathering_seconds_per_point": 0.035},
	"Wisdom": {"label": "Wisdom", "summary": "Turns discoveries into research sooner.", "effect": "research_time", "per_point": 0.20, "research_day_threshold": 5},
	"Spirituality": {"label": "Spirituality", "summary": "Makes restorative food and recovery more potent.", "effect": "restoration", "per_point": 0.10, "restoration_multiplier_per_point": 0.10},
	"Perception": {"label": "Perception", "summary": "Extends the distance at which the world can be read and used.", "effect": "interaction_range", "per_point": 0.08, "interaction_range_per_point": 0.08},
	"Resilience": {"label": "Resilience", "summary": "Raises the health floor you can carry into danger.", "effect": "maximum_health", "per_point": 5.0, "max_health_per_point": 5.0},
}

## Authoritative mastery progression. Runtime mastery points and granted
## permissions belong to GameSession; this registry defines the ordered content
## contract that future session/UI integrations consume. Every returned
## definition is duplicated by the helpers below so callers cannot mutate this
## source of truth.
const MASTERY_ORDER := [
	"Farming", "Mining", "Attacking", "Foraging", "Fishing", "Crafting",
	"Livestock", "Language", "Trading", "Hunting", "Surviving", "Research",
]

const MASTERY_TIER_ORDER := ["Bronze", "Silver", "Gold", "Platinum"]

const MASTERY_TIER_THRESHOLDS := {
	"Bronze": 20,
	"Silver": 45,
	"Gold": 70,
	"Platinum": 95,
}

const MASTERY_DEFINITIONS := {
	"Farming": {
		"label": "Farming", "summary": "Grow dependable harvests through careful planting and stewardship.",
		"tiers": [
			{"tier": "Bronze", "threshold": 20, "feature": "farming_seed_saver", "label": "Seed Saver", "summary": "Careful harvesting can preserve seed stock.", "permission": {"rule": "recover_seed_on_harvest", "scope": "crop_harvest"}, "effects": {"seed_refund_chance": 0.10}},
			{"tier": "Silver", "threshold": 45, "feature": "farming_field_rhythm", "label": "Field Rhythm", "summary": "Consistent tending shortens crop cycles.", "permission": {"rule": "accelerate_tended_crops", "scope": "crop_growth"}, "effects": {"growth_time_multiplier": 0.90}},
			{"tier": "Gold", "threshold": 70, "feature": "farming_harvest_pairing", "label": "Harvest Pairing", "summary": "Healthy plots sometimes produce an additional crop.", "permission": {"rule": "roll_bonus_crop", "scope": "crop_harvest"}, "effects": {"bonus_crop_chance": 0.25}},
			{"tier": "Platinum", "threshold": 95, "feature": "farming_verdant_steward", "label": "Verdant Steward", "summary": "Mastered fields resist harsh seasonal conditions.", "permission": {"rule": "mitigate_seasonal_crop_penalties", "scope": "crop_growth"}, "effects": {"season_penalty_multiplier": 0.50}},
		],
	},
	"Mining": {
		"label": "Mining", "summary": "Read stone, work veins efficiently, and return with better ore.",
		"tiers": [
			{"tier": "Bronze", "threshold": 20, "feature": "mining_vein_reader", "label": "Vein Reader", "summary": "Promising mineral nodes remain readable at close range.", "permission": {"rule": "reveal_resource_grade", "scope": "mineral_nodes"}, "effects": {"reveal_radius": 3.0}},
			{"tier": "Silver", "threshold": 45, "feature": "mining_reinforced_swing", "label": "Reinforced Swing", "summary": "Controlled strikes reduce pick wear.", "permission": {"rule": "reduce_pick_durability_cost", "scope": "mining_actions"}, "effects": {"durability_cost_multiplier": 0.75}},
			{"tier": "Gold", "threshold": 70, "feature": "mining_ore_sorting", "label": "Ore Sorting", "summary": "Useful fragments are recovered from worked veins.", "permission": {"rule": "roll_bonus_ore", "scope": "mineral_yield"}, "effects": {"bonus_ore_chance": 0.30}},
			{"tier": "Platinum", "threshold": 95, "feature": "mining_deep_delver", "label": "Deep Delver", "summary": "Rare seams become accessible in expedition mines.", "permission": {"rule": "access_deep_seams", "scope": "mine_routes"}, "effects": {"rare_seam_yield_bonus": 1}},
		],
	},
	"Attacking": {
		"label": "Attacking", "summary": "Turn deliberate timing and positioning into decisive combat.",
		"tiers": [
			{"tier": "Bronze", "threshold": 20, "feature": "combat_training", "label": "Combat Training", "summary": "+2 damage on light attacks.", "permission": {"rule": "increase_light_attack_damage", "scope": "player_attacks"}, "effects": {"light_attack_damage_bonus": 2}},
			{"tier": "Silver", "threshold": 45, "feature": "attacking_guard_break", "label": "Guard Break", "summary": "Heavy hits damage guarded enemies more reliably.", "permission": {"rule": "increase_guard_damage", "scope": "heavy_attacks"}, "effects": {"guard_damage_multiplier": 1.35}},
			{"tier": "Gold", "threshold": 70, "feature": "attacking_relentless_rhythm", "label": "Relentless Rhythm", "summary": "Well-timed chains recover attack stamina.", "permission": {"rule": "refund_stamina_on_combo", "scope": "attack_combos"}, "effects": {"combo_stamina_refund": 2}},
			{"tier": "Platinum", "threshold": 95, "feature": "attacking_vanguard_resolve", "label": "Vanguard Resolve", "summary": "A finishing strike gains power against guardians.", "permission": {"rule": "empower_guardian_finishers", "scope": "guardian_combat"}, "effects": {"finisher_damage_multiplier": 1.50}},
		],
	},
	"Foraging": {
		"label": "Foraging", "summary": "Notice, gather, and preserve the useful details of wild places.",
		"tiers": [
			{"tier": "Bronze", "threshold": 20, "feature": "foraging_trail_eye", "label": "Trail Eye", "summary": "Nearby common forage is easier to notice.", "permission": {"rule": "reveal_common_forage", "scope": "expedition_resources"}, "effects": {"reveal_radius": 3.5}},
			{"tier": "Silver", "threshold": 45, "feature": "foraging_gentle_harvest", "label": "Gentle Harvest", "summary": "Gathering wild plants causes less tool wear.", "permission": {"rule": "reduce_foraging_durability_cost", "scope": "foraging_actions"}, "effects": {"durability_cost_multiplier": 0.75}},
			{"tier": "Gold", "threshold": 70, "feature": "foraging_grove_memory", "label": "Grove Memory", "summary": "Previously found forage returns more predictably.", "permission": {"rule": "accelerate_forage_regrowth", "scope": "resource_respawn"}, "effects": {"respawn_time_multiplier": 0.75}},
			{"tier": "Platinum", "threshold": 95, "feature": "foraging_wildkeeper", "label": "Wildkeeper", "summary": "Rare plants can yield a protected cutting.", "permission": {"rule": "recover_rare_cuttings", "scope": "rare_forage"}, "effects": {"rare_cutting_chance": 0.35}},
		],
	},
	"Fishing": {
		"label": "Fishing", "summary": "Read water, manage a catch, and bring home more than luck.",
		"tiers": [
			{"tier": "Bronze", "threshold": 20, "feature": "fishing_patient_cast", "label": "Patient Cast", "summary": "The first bite window remains open longer.", "permission": {"rule": "extend_bite_window", "scope": "fishing_checks"}, "effects": {"bite_window_bonus_seconds": 0.50}},
			{"tier": "Silver", "threshold": 45, "feature": "fishing_barbed_hook", "label": "Barbed Hook", "summary": "Hooked fish lose less progress during mistakes.", "permission": {"rule": "reduce_fish_escape_progress", "scope": "fishing_checks"}, "effects": {"escape_progress_multiplier": 0.75}},
			{"tier": "Gold", "threshold": 70, "feature": "fishing_tide_reader", "label": "Tide Reader", "summary": "Favorable tide windows reveal uncommon catches.", "permission": {"rule": "unlock_tide_catches", "scope": "coastal_fishing"}, "effects": {"uncommon_catch_weight": 0.20}},
			{"tier": "Platinum", "threshold": 95, "feature": "fishing_master_angler", "label": "Master Angler", "summary": "Perfect catches can return an extra fish.", "permission": {"rule": "roll_bonus_perfect_catch", "scope": "fishing_rewards"}, "effects": {"perfect_catch_bonus_chance": 0.40}},
		],
	},
	"Crafting": {
		"label": "Crafting", "summary": "Build, repair, and refine equipment with less waste.",
		"tiers": [
			{"tier": "Bronze", "threshold": 20, "feature": "field_repair", "label": "Field Repair", "summary": "Repair tools with less Plank.", "permission": {"rule": "reduce_tool_repair_cost", "scope": "tool_repair"}, "effects": {"plank_cost_reduction": 1}},
			{"tier": "Silver", "threshold": 45, "feature": "crafting_efficient_joinery", "label": "Efficient Joinery", "summary": "Workshop jobs consume fewer common materials.", "permission": {"rule": "reduce_common_recipe_cost", "scope": "workshop_recipes"}, "effects": {"common_material_refund_chance": 0.20}},
			{"tier": "Gold", "threshold": 70, "feature": "crafting_quality_work", "label": "Quality Work", "summary": "Crafted tools begin with additional durability.", "permission": {"rule": "increase_crafted_durability", "scope": "crafted_tools"}, "effects": {"durability_multiplier": 1.25}},
			{"tier": "Platinum", "threshold": 95, "feature": "crafting_masterwork_bench", "label": "Masterwork Bench", "summary": "Advanced masterwork recipes become available.", "permission": {"rule": "unlock_masterwork_recipes", "scope": "workshop_recipes"}, "effects": {"masterwork_recipe_tier": 1}},
		],
	},
	"Livestock": {
		"label": "Livestock", "summary": "Raise calm, healthy animals through routine and trust.",
		"tiers": [
			{"tier": "Bronze", "threshold": 20, "feature": "livestock_calm_hands", "label": "Calm Hands", "summary": "Animal care builds trust more quickly.", "permission": {"rule": "increase_animal_trust_gain", "scope": "animal_care"}, "effects": {"trust_gain_multiplier": 1.20}},
			{"tier": "Silver", "threshold": 45, "feature": "livestock_feed_stretch", "label": "Feed Stretch", "summary": "Prepared feed keeps animals satisfied longer.", "permission": {"rule": "extend_feed_duration", "scope": "animal_hunger"}, "effects": {"feed_duration_multiplier": 1.25}},
			{"tier": "Gold", "threshold": 70, "feature": "livestock_herd_bond", "label": "Herd Bond", "summary": "Content animals produce higher-quality goods.", "permission": {"rule": "improve_animal_products", "scope": "animal_products"}, "effects": {"quality_product_chance": 0.30}},
			{"tier": "Platinum", "threshold": 95, "feature": "livestock_sanctuary_breeder", "label": "Sanctuary Breeder", "summary": "Rare animal traits can be nurtured safely.", "permission": {"rule": "unlock_rare_animal_traits", "scope": "animal_breeding"}, "effects": {"trait_progress_per_feed": 25}},
		],
	},
	"Language": {
		"label": "Language", "summary": "Understand people, inscriptions, and cultures beyond the Sanctuary.",
		"tiers": [
			{"tier": "Bronze", "threshold": 20, "feature": "language_phrasebook", "label": "Field Phrasebook", "summary": "Basic foreign dialogue choices become understandable.", "permission": {"rule": "unlock_basic_dialogue", "scope": "foreign_dialogue"}, "effects": {"dialogue_tier": 1}},
			{"tier": "Silver", "threshold": 45, "feature": "language_context_reader", "label": "Context Reader", "summary": "Simple expedition inscriptions can be interpreted.", "permission": {"rule": "translate_route_inscriptions", "scope": "expedition_lore"}, "effects": {"inscription_tier": 2}},
			{"tier": "Gold", "threshold": 70, "feature": "language_diplomats_ear", "label": "Diplomat's Ear", "summary": "Nuanced dialogue opens peaceful quest resolutions.", "permission": {"rule": "unlock_diplomatic_resolutions", "scope": "quest_dialogue"}, "effects": {"reputation_reward_multiplier": 1.25}},
			{"tier": "Platinum", "threshold": 95, "feature": "language_polyglot", "label": "World Polyglot", "summary": "Ancient and regional texts reveal their full meaning.", "permission": {"rule": "translate_ancient_texts", "scope": "ancient_lore"}, "effects": {"lore_reward_multiplier": 1.50}},
		],
	},
	"Trading": {
		"label": "Trading", "summary": "Recognize value, build trust, and move goods wisely.",
		"tiers": [
			{"tier": "Bronze", "threshold": 20, "feature": "market_favor", "label": "Market Favor", "summary": "Earn 25% more Coins from Bazaar offers.", "permission": {"rule": "increase_bazaar_payout", "scope": "trade_offers"}, "effects": {"payout_multiplier": 1.25}},
			{"tier": "Silver", "threshold": 45, "feature": "trading_appraisers_eye", "label": "Appraiser's Eye", "summary": "Offer quality and demand become visible before a trade.", "permission": {"rule": "reveal_offer_quality", "scope": "trade_offers"}, "effects": {"forecast_days": 1}},
			{"tier": "Gold", "threshold": 70, "feature": "trading_caravan_contacts", "label": "Caravan Contacts", "summary": "A rotating specialist offer joins the Bazaar.", "permission": {"rule": "unlock_specialist_offers", "scope": "bazaar_inventory"}, "effects": {"specialist_offer_count": 1}},
			{"tier": "Platinum", "threshold": 95, "feature": "trading_guild_broker", "label": "Guild Broker", "summary": "Bulk contracts pay a premium when fulfilled completely.", "permission": {"rule": "unlock_bulk_contract_bonus", "scope": "trade_contracts"}, "effects": {"contract_payout_multiplier": 1.40}},
		],
	},
	"Hunting": {
		"label": "Hunting", "summary": "Track dangerous creatures and choose encounters on your terms.",
		"tiers": [
			{"tier": "Bronze", "threshold": 20, "feature": "hunting_track_sign", "label": "Track Sign", "summary": "Fresh tracks reveal a creature's direction.", "permission": {"rule": "reveal_fresh_tracks", "scope": "wildlife_tracking"}, "effects": {"track_reveal_radius": 4.0}},
			{"tier": "Silver", "threshold": 45, "feature": "hunting_clean_shot", "label": "Clean Shot", "summary": "Opening hits deal more stagger to unaware prey.", "permission": {"rule": "increase_opening_stagger", "scope": "hunting_combat"}, "effects": {"opening_stagger_multiplier": 1.50}},
			{"tier": "Gold", "threshold": 70, "feature": "hunting_ambush_sense", "label": "Ambush Sense", "summary": "Nearby predator ambushes are warned before they spring.", "permission": {"rule": "warn_predator_ambushes", "scope": "expedition_threats"}, "effects": {"warning_seconds": 1.50}},
			{"tier": "Platinum", "threshold": 95, "feature": "hunting_apex_hunter", "label": "Apex Hunter", "summary": "Named beasts can yield a rare trophy component.", "permission": {"rule": "roll_named_beast_trophies", "scope": "named_beasts"}, "effects": {"trophy_drop_chance": 0.50}},
		],
	},
	"Surviving": {
		"label": "Surviving", "summary": "Prepare for exposure, recover under pressure, and return alive.",
		"tiers": [
			{"tier": "Bronze", "threshold": 20, "feature": "surviving_campcraft", "label": "Campcraft", "summary": "Field camps restore more energy during a rest.", "permission": {"rule": "improve_camp_recovery", "scope": "field_camps"}, "effects": {"camp_energy_bonus": 2}},
			{"tier": "Silver", "threshold": 45, "feature": "surviving_weatherwise", "label": "Weatherwise", "summary": "Weather drains health and energy more slowly.", "permission": {"rule": "mitigate_weather_exposure", "scope": "weather_hazards"}, "effects": {"exposure_drain_multiplier": 0.75}},
			{"tier": "Gold", "threshold": 70, "feature": "surviving_second_wind", "label": "Second Wind", "summary": "Once per expedition, critical health triggers a brief recovery.", "permission": {"rule": "trigger_expedition_second_wind", "scope": "expedition_survival"}, "effects": {"health_restored": 15}},
			{"tier": "Platinum", "threshold": 95, "feature": "surviving_worldwalker", "label": "Worldwalker", "summary": "Extreme-biome travel consumes less energy.", "permission": {"rule": "reduce_extreme_biome_travel_cost", "scope": "expedition_travel"}, "effects": {"travel_energy_reduction": 2}},
		],
	},
	"Research": {
		"label": "Research", "summary": "Turn discoveries into reliable knowledge and practical designs.",
		"tiers": [
			{"tier": "Bronze", "threshold": 20, "feature": "research_margin_notes", "label": "Margin Notes", "summary": "Research jobs complete with less elapsed time.", "permission": {"rule": "accelerate_basic_research", "scope": "archive_jobs"}, "effects": {"research_time_multiplier": 0.90}},
			{"tier": "Silver", "threshold": 45, "feature": "research_cross_reference", "label": "Cross Reference", "summary": "Related discoveries reveal an additional clue.", "permission": {"rule": "reveal_related_discoveries", "scope": "discovery_research"}, "effects": {"bonus_clue_count": 1}},
			{"tier": "Gold", "threshold": 70, "feature": "research_breakthrough", "label": "Practical Breakthrough", "summary": "Completed research can refund part of its material cost.", "permission": {"rule": "refund_research_materials", "scope": "archive_jobs"}, "effects": {"material_refund_chance": 0.30}},
			{"tier": "Platinum", "threshold": 95, "feature": "research_aether_scholar", "label": "Aether Scholar", "summary": "Relic research unlocks advanced aether applications.", "permission": {"rule": "unlock_aether_research", "scope": "relic_research"}, "effects": {"aether_research_tier": 1}},
		],
	},
}

## Compatibility projection consumed by the current GameSession. Keep these
## established Bronze permissions stable until GameSession adopts all tiers.
const MASTERY_PERMISSIONS := {
	"Crafting": {"threshold": 20, "feature": "field_repair", "label": "Field Repair", "summary": "Repair tools with less Plank."},
	"Trading": {"threshold": 20, "feature": "market_favor", "label": "Market Favor", "summary": "Earn 25% more Coins from Bazaar offers."},
	"Attacking": {"threshold": 20, "feature": "combat_training", "label": "Combat Training", "summary": "+2 damage on light attacks."},
}

const TRADE_OFFERS := [
	{"id": "fish_basket", "cost": {"fish": 2, "water": 1}, "payout": 28, "summary": "2 Fish + 1 Water → 28 Coins"},
	{"id": "tideglass_trinket", "cost": {"shell": 1, "plank": 1}, "payout": 38, "summary": "1 Shell + 1 Plank → 38 Coins"},
	{"id": "wheat_bundle", "cost": {"wheat": 3}, "payout": 18, "summary": "3 Wheat → 18 Coins"},
	{"id": "egg_bundle", "cost": {"egg": 2}, "payout": 24, "summary": "2 Eggs → 24 Coins"},
]

## Caravan stock rotates deterministically by day. GameSession owns the
## current day, affordability, and one-trade-per-offer receipt; this table only
## describes the authored specialist goods.
const SPECIALIST_TRADE_OFFERS := [
	{"id": "caravan_ore_lot", "cost": {"ore": 2, "slime_gel": 1}, "payout": 66, "summary": "2 Ore + 1 Slime Gel → 66 Coins", "specialist": "Ore Broker"},
	{"id": "caravan_sunstone_lot", "cost": {"sunstone": 1, "water": 1}, "payout": 58, "summary": "1 Sunstone + 1 Water → 58 Coins", "specialist": "Glasswright"},
	{"id": "caravan_relic_lot", "cost": {"relic": 1, "shell": 1}, "payout": 82, "summary": "1 Relic + 1 Shell → 82 Coins", "specialist": "Relic Appraiser"},
]

const STRUCTURES := {
	# Player-owned structures use the same multi-cell claim that the player sees
	# in build mode. These are deliberately human-scale rather than Stardew-sized
	# thumbnail plots: a one-metre world cell is a real walking/building metre.
	"rain_cistern": {"footprint": [4, 4], "cost": {"wood": 8, "plank": 2}, "hours": 24.0, "unique": true, "requires_blueprint": "Tideglass Compass", "summary": "Collects two extra water at each new day."},
	# Tier-zero bootstrap: the first Workshop is deliberately buildable from
	# gathered raw materials. Planks are produced by the finished Workshop and
	# become the gate for later district upgrades, preventing a fresh-save loop.
	"workshop": {"footprint": [6, 5], "cost": {"wood": 12, "stone": 8}, "hours": 36.0, "unique": true, "summary": "A player-placed workshop for turning raw supplies into useful goods."},
	# The Archive is the first research gate, so it must be reachable before
	# any researched blueprint exists. Its discoveries unlock the later district
	# buildings rather than gating the desk that performs the research.
	"archive": {"footprint": [5, 4], "cost": {"wood": 8, "stone": 8, "plank": 3}, "hours": 30.0, "unique": true, "summary": "A player-placed archive for researching discoveries."},
	"livestock_pen": {"footprint": [7, 5], "cost": {"wood": 10, "fiber": 6, "plank": 2}, "hours": 24.0, "unique": true, "requires_blueprint": "Whisperglass Tonic", "summary": "A player-placed pen that gives livestock a safe home."},
	"storage_shed": {"footprint": [5, 4], "cost": {"wood": 10, "stone": 4, "plank": 3}, "hours": 24.0, "unique": false, "requires_blueprint": "Tideglass Compass", "cargo_bonus": 4, "summary": "A sturdy stockpile that expands expedition satchel capacity by 4."},
}

## Shared fallback geometry for interior rooms. A measured source shell may
## refine this profile at runtime, but the session, preview, and room builder
## all start from this single contract.
const INTERIOR_LAYOUTS := {
	"workshop": {
		"room_size": [8.2, 6.2],
		"room_height": 3.65,
		"door_width": 1.45,
		"cell_size": 1.0,
		"wall_clearance": 0.45,
		"door_clearance_depth": 0.85,
		"door_facing": [0.0, 0.0, 1.0],
	}
}

## Interior fit-out is authored separately from the exterior shell. A Workshop
## can be entered as soon as its shell finishes, but it only grants a capability
## after the player places and supplies the corresponding station. Footprints
## are measured-room cells so the presentation preview and persistent collision
## use the same physical claim.
const INTERIOR_STATIONS := {
	"workbench": {"structure_kind": "workshop", "label": "Crafting Workbench", "footprint": [2, 1], "cost": {"wood": 4, "stone": 2}, "hours": 12.0, "capability": "workshop_crafting", "action": "workshop", "asset_kind": "workbench", "unique": true},
	"furnace_left": {"structure_kind": "workshop", "label": "Smelter Furnace", "footprint": [2, 1], "cost": {"stone": 3, "wood": 2}, "hours": 12.0, "capability": "workshop_smelting", "action": "furnace", "asset_kind": "furnace_left", "unique": true},
	"furnace_right": {"structure_kind": "workshop", "label": "Forge Furnace", "footprint": [2, 1], "cost": {"stone": 3, "wood": 2}, "hours": 12.0, "capability": "workshop_smelting", "action": "furnace", "asset_kind": "furnace_right", "unique": true},
	"anvil": {"structure_kind": "workshop", "label": "Anvil", "footprint": [1, 1], "cost": {"stone": 2, "plank": 1}, "hours": 12.0, "capability": "workshop_metalwork", "action": "anvil", "asset_kind": "anvil", "unique": true},
	"storage": {"structure_kind": "workshop", "label": "Material Storage", "footprint": [2, 1], "cost": {"wood": 3, "stone": 1}, "hours": 8.0, "capability": "workshop_storage", "action": "storage", "asset_kind": "storage", "cargo_bonus": 6, "unique": true},
}

static func expedition_cost(expedition_id: String) -> int:
	return int(EXPEDITIONS.get(expedition_id, {}).get("travel_energy", 0))

static func expedition_entry_coins(expedition_id: String) -> int:
	return int(EXPEDITIONS.get(expedition_id, {}).get("entry_coins", 0))

static func expedition_route_definition(expedition_id: String, branch_id: String) -> Dictionary:
	return EXPEDITION_ROUTE_DEFINITIONS.get(expedition_id, {}).get(branch_id, {}).duplicate(true)

static func expedition_branch_ids(expedition_id: String) -> Array:
	return EXPEDITION_BRANCH_ORDER.get(expedition_id, []).duplicate()

static func whisperwood_landmark(landmark_id: String) -> Vector3:
	var socket: Array = WHISPERWOOD_LANDMARKS.get(landmark_id, [])
	if socket.size() != 2:
		return Vector3.ZERO
	return Vector3(float(socket[0]), 0.0, float(socket[1]))

static func wildlife_definition(wildlife_id: String) -> Dictionary:
	return WILDLIFE.get(wildlife_id, {}).duplicate(true)

static func wildlife_ids_for_zone(zone_id: String) -> Array:
	var ids: Array = []
	for wildlife_id in WILDLIFE:
		if str(WILDLIFE[wildlife_id].get("zone_id", "")) == zone_id:
			ids.append(str(wildlife_id))
	return ids

static func discovery_blueprint(discovery_id: String) -> String:
	return str(DISCOVERIES.get(discovery_id, {}).get("blueprint", ""))

static func discovery_grant(discovery_id: String) -> String:
	return str(DISCOVERIES.get(discovery_id, {}).get("grant", ""))

static func discovery_links(discovery_id: String) -> Array:
	return DISCOVERY_LINKS.get(discovery_id, []).duplicate(true)

static func expedition_inscription_definition(inscription_id: String) -> Dictionary:
	return EXPEDITION_INSCRIPTIONS.get(inscription_id, {}).duplicate(true)

static func expedition_inscription_ids_for_zone(zone_id: String) -> Array:
	var ids: Array = []
	for inscription_id in EXPEDITION_INSCRIPTIONS:
		if str(EXPEDITION_INSCRIPTIONS[inscription_id].get("zone_id", "")) == zone_id:
			ids.append(str(inscription_id))
	return ids

static func fishing_spot_definition(spot_id: String) -> Dictionary:
	return FISHING_SPOTS.get(spot_id, {}).duplicate(true)

static func workshop_recipe(recipe_id: String) -> Dictionary:
	return WORKSHOP_RECIPES.get(recipe_id, {}).duplicate(true)

static func livestock_trait_definition(trait_id: String) -> Dictionary:
	return LIVESTOCK_TRAITS.get(trait_id, {}).duplicate(true)

static func structure_definition(structure_id: String) -> Dictionary:
	return STRUCTURES.get(structure_id, {}).duplicate(true)

static func interior_station_definition(station_kind: String) -> Dictionary:
	return INTERIOR_STATIONS.get(station_kind, {}).duplicate(true)

static func interior_station_footprint(station_kind: String, rotation_quarter_turns := 0) -> Vector2i:
	var definition := interior_station_definition(station_kind)
	var footprint: Array = definition.get("footprint", [])
	if footprint.size() < 2:
		return Vector2i.ZERO
	var base := Vector2i(int(footprint[0]), int(footprint[1]))
	return base if posmod(rotation_quarter_turns, 2) == 0 else Vector2i(base.y, base.x)

static func interior_station_ids_for_structure(structure_kind: String) -> Array:
	var ids: Array = []
	for station_kind in INTERIOR_STATIONS:
		if str(INTERIOR_STATIONS[station_kind].get("structure_kind", "")) == structure_kind:
			ids.append(str(station_kind))
	return ids

static func interior_layout(structure_id: String) -> Dictionary:
	return (INTERIOR_LAYOUTS.get(structure_id, {}) as Dictionary).duplicate(true)

static func guardian_definition(guardian_id: String) -> Dictionary:
	return GUARDIANS.get(guardian_id, {}).duplicate(true)

static func stat_ids() -> Array:
	return STAT_ORDER.duplicate()

static func stat_definition(stat_name: String) -> Dictionary:
	return STAT_DEFINITIONS.get(stat_name, {}).duplicate(true)

static func mastery_ids() -> Array:
	return MASTERY_ORDER.duplicate()

static func mastery_definition(mastery_name: String) -> Dictionary:
	return MASTERY_DEFINITIONS.get(mastery_name, {}).duplicate(true)

static func mastery_tiers(mastery_name: String) -> Array:
	return MASTERY_DEFINITIONS.get(mastery_name, {}).get("tiers", []).duplicate(true)

static func mastery_tier_definition(mastery_name: String, tier_name: String) -> Dictionary:
	for tier in MASTERY_DEFINITIONS.get(mastery_name, {}).get("tiers", []):
		if str(tier.get("tier", "")) == tier_name:
			return tier.duplicate(true)
	return {}

static func mastery_tier_for_points(mastery_name: String, points: int) -> Dictionary:
	var unlocked_tier: Dictionary = {}
	for tier in MASTERY_DEFINITIONS.get(mastery_name, {}).get("tiers", []):
		if points < int(tier.get("threshold", 2147483647)):
			break
		unlocked_tier = tier
	return unlocked_tier.duplicate(true)

static func next_mastery_tier(mastery_name: String, points: int) -> Dictionary:
	for tier in MASTERY_DEFINITIONS.get(mastery_name, {}).get("tiers", []):
		if points < int(tier.get("threshold", 2147483647)):
			return tier.duplicate(true)
	return {}

static func mastery_tier_for_feature(feature_name: String) -> Dictionary:
	if feature_name.is_empty():
		return {}
	for mastery_name in MASTERY_ORDER:
		for tier in MASTERY_DEFINITIONS.get(mastery_name, {}).get("tiers", []):
			if str(tier.get("feature", "")) == feature_name:
				var definition: Dictionary = (tier as Dictionary).duplicate(true)
				definition["mastery"] = str(mastery_name)
				return definition
	return {}

static func mastery_effects_for_feature(feature_name: String) -> Dictionary:
	return mastery_tier_for_feature(feature_name).get("effects", {}).duplicate(true)
