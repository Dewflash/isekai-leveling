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

const DISCOVERIES := {
	"Whisperglass": {"blueprint": "Whisperglass Tonic", "grant": "tonic_recipe", "summary": "A resonant forest growth that holds a night's warmth."},
	"Tideglass": {"blueprint": "Tideglass Compass", "grant": "safe_tides", "summary": "A shell that points toward safe water and hidden coves."},
	"Aether Relic": {"blueprint": "Aether Lantern", "grant": "dungeon_lantern", "summary": "A relic core that turns recovered light into a route."},
}

const GUARDIANS := {
	"forest_slime": {"zone_id": "Whisperwood", "enemy_label": "FOREST SLIME", "reward_id": "slime_gel", "reward_amount": 1, "health": 18, "attack_damage": 5},
	"tide_wraith": {"zone_id": "Sunlit Beach", "enemy_label": "TIDE WRAITH", "reward_id": "shell", "reward_amount": 2, "health": 22, "attack_damage": 6},
	"ember_golem": {"zone_id": "Ember Ridge", "enemy_label": "EMBER GOLEM", "reward_id": "ore", "reward_amount": 2, "health": 30, "attack_damage": 8},
	"dune_wisp": {"zone_id": "Glass Desert", "enemy_label": "DUNE WISP", "reward_id": "sunstone", "reward_amount": 1, "health": 26, "attack_damage": 7},
	"crypt_knight": {"zone_id": "Sunken Dungeon", "enemy_label": "CRYPT KNIGHT", "reward_id": "relic", "reward_amount": 1, "health": 42, "attack_damage": 10},
}

const WORKSHOP_RECIPES := {
	"plank": {"cost": {"wood": 3, "stone": 1}, "hours": 12.0, "output": 4, "summary": "3 Wood + 1 Stone → 4 Planks"},
	"bread": {"cost": {"wheat": 1, "water": 1}, "hours": 12.0, "output": 2, "summary": "1 Wheat + 1 Water → 2 Bread"},
	"omelette": {"cost": {"egg": 1, "water": 1}, "hours": 12.0, "output": 2, "summary": "1 Egg + 1 Water → 2 Omelettes"},
	"tonic": {"cost": {"berries": 1, "water": 1, "slime_gel": 1}, "hours": 12.0, "output": 1, "summary": "1 Berry + 1 Water + 1 Slime Gel → 1 Tonic"},
}

const TRADE_OFFERS := [
	{"id": "fish_basket", "cost": {"fish": 2, "water": 1}, "payout": 28, "summary": "2 Fish + 1 Water → 28 Coins"},
	{"id": "tideglass_trinket", "cost": {"shell": 1, "plank": 1}, "payout": 38, "summary": "1 Shell + 1 Plank → 38 Coins"},
	{"id": "wheat_bundle", "cost": {"wheat": 3}, "payout": 18, "summary": "3 Wheat → 18 Coins"},
	{"id": "egg_bundle", "cost": {"egg": 2}, "payout": 24, "summary": "2 Eggs → 24 Coins"},
]

const STRUCTURES := {
	"rain_cistern": {"footprint": [2, 2], "cost": {"wood": 8, "plank": 2}, "hours": 24.0, "summary": "Collects two extra water at each new day."},
}

static func expedition_cost(expedition_id: String) -> int:
	return int(EXPEDITIONS.get(expedition_id, {}).get("travel_energy", 0))

static func expedition_entry_coins(expedition_id: String) -> int:
	return int(EXPEDITIONS.get(expedition_id, {}).get("entry_coins", 0))

static func discovery_blueprint(discovery_id: String) -> String:
	return str(DISCOVERIES.get(discovery_id, {}).get("blueprint", ""))

static func discovery_grant(discovery_id: String) -> String:
	return str(DISCOVERIES.get(discovery_id, {}).get("grant", ""))

static func workshop_recipe(recipe_id: String) -> Dictionary:
	return WORKSHOP_RECIPES.get(recipe_id, {}).duplicate(true)

static func structure_definition(structure_id: String) -> Dictionary:
	return STRUCTURES.get(structure_id, {}).duplicate(true)

static func guardian_definition(guardian_id: String) -> Dictionary:
	return GUARDIANS.get(guardian_id, {}).duplicate(true)
