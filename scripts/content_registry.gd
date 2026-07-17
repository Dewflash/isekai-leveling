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

## One authoritative definition for the physical Sanctuary trailheads. The
## world renderer owns presentation, while the session owns placement safety;
## both read these same sockets so player construction cannot seal a road that
## the scene still presents as usable.
const ROUTE_SOCKETS := {
	"whisperwood": {"destination_id": "Whisperwood", "gate_position": [-11.0, -5.7], "path_center": [-7.2, -5.7], "path_size": [9.0, 1.0], "approach_rect": [-13, -7, -9, -3], "spoke_rect": [-12, -6, -2, -5], "accent": "6fb4a1"},
	"sunlit_beach": {"destination_id": "Sunlit Beach", "gate_position": [-11.0, 1.9], "path_center": [-7.2, 1.9], "path_size": [9.0, 1.0], "approach_rect": [-13, 0, -9, 3], "spoke_rect": [-12, 1, -2, 2], "accent": "6bc1d0"},
	"ember_ridge": {"destination_id": "Ember Ridge", "gate_position": [-10.2, 6.0], "path_center": [-6.8, 6.0], "path_size": [8.0, 1.0], "approach_rect": [-12, 4, -8, 7], "spoke_rect": [-11, 5, -2, 6], "accent": "e28c61"},
	"glass_desert": {"destination_id": "Glass Desert", "gate_position": [11.0, -5.4], "path_center": [9.2, -5.4], "path_size": [6.0, 1.0], "approach_rect": [9, -7, 13, -3], "spoke_rect": [6, -6, 13, -5], "accent": "edbb6f"},
	"sunken_dungeon": {"destination_id": "Sunken Dungeon", "gate_position": [11.0, 2.0], "path_center": [9.2, 2.0], "path_size": [6.0, 1.0], "approach_rect": [9, 0, 13, 4], "spoke_rect": [6, 1, 13, 2], "accent": "a88ce0"},
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
	"tonic": {"cost": {"berries": 1, "water": 1, "slime_gel": 1}, "hours": 12.0, "output": 1, "requires_feature": "tonic_recipe", "summary": "1 Berry + 1 Water + 1 Slime Gel → 1 Tonic"},
}

const TRADE_OFFERS := [
	{"id": "fish_basket", "cost": {"fish": 2, "water": 1}, "payout": 28, "summary": "2 Fish + 1 Water → 28 Coins"},
	{"id": "tideglass_trinket", "cost": {"shell": 1, "plank": 1}, "payout": 38, "summary": "1 Shell + 1 Plank → 38 Coins"},
	{"id": "wheat_bundle", "cost": {"wheat": 3}, "payout": 18, "summary": "3 Wheat → 18 Coins"},
	{"id": "egg_bundle", "cost": {"egg": 2}, "payout": 24, "summary": "2 Eggs → 24 Coins"},
]

const STRUCTURES := {
	"rain_cistern": {"footprint": [2, 2], "cost": {"wood": 8, "plank": 2}, "hours": 24.0, "summary": "Collects two extra water at each new day."},
	"workshop": {"footprint": [3, 3], "cost": {"wood": 12, "stone": 8, "plank": 4}, "hours": 36.0, "summary": "A player-placed workshop for turning supplies into useful goods."},
	"archive": {"footprint": [3, 2], "cost": {"wood": 8, "stone": 8, "plank": 3}, "hours": 30.0, "summary": "A player-placed archive for researching discoveries."},
	"livestock_pen": {"footprint": [4, 3], "cost": {"wood": 10, "fiber": 6, "plank": 2}, "hours": 24.0, "summary": "A player-placed pen that gives livestock a safe home."},
	"storage_shed": {"footprint": [3, 2], "cost": {"wood": 10, "stone": 4, "plank": 3}, "hours": 24.0, "cargo_bonus": 4, "summary": "A sturdy stockpile that expands expedition satchel capacity by 4."},
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
