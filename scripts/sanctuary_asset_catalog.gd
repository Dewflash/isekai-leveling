class_name ProdewtySanctuaryAssetCatalog
extends RefCounted

## Sanctuary player-structure asset profiles.
##
## ContentRegistry and GameSession remain the gameplay authority for build costs,
## grid footprints, occupancy, construction state, and persistence. This catalog
## deliberately does not duplicate those rules. It describes how each authored
## structure must be presented and provides semantic access/construction metadata.
##
## `sprite_kind` and `world_size` are presentation fallbacks only. `sprite_kind`
## is only a temporary sheet fallback; `asset_id` and
## every directional variant ID are the unique production-facing identities.
## Imported player structures are measured at runtime by
## sanctuary_asset_measurement.gd; their source bounds, fitted transform, and
## collision shell are never duplicated here.
##
## Coordinate contract for authored metadata:
## - centers and facing vectors are structure-local, with Y up;
## - quarter-turn 0 faces local +Z;
## - positive quarter-turns follow the structure root's positive Y rotation;
## - access-zone `size` is [local_width_x, local_depth_z];
## - measured collision components are emitted in [width_x, height_y, depth_z].

const STRUCTURES := {
	"workshop": {
		"profile_id": "sanctuary_structure_workshop_v1",
		"asset_id": "sanctuary/player_structures/workshop",
		"sprite_kind": "workshop",
		"source_asset": "res://assets/sourced/quaternius-medieval-village/Medieval Village Pack - Dec 2020/Buildings/FBX/Blacksmith.fbx",
		"operational_art_mode": "illustrated_2_5d",
		"world_size": 8.2,
		"directional_variants": [
			{"quarter_turn": 0, "variant_id": "workshop_q0_pos_z", "asset_id": "sanctuary/player_structures/workshop/operational/q0_pos_z", "facing": [0.0, 0.0, 1.0]},
			{"quarter_turn": 1, "variant_id": "workshop_q1_pos_x", "asset_id": "sanctuary/player_structures/workshop/operational/q1_pos_x", "facing": [1.0, 0.0, 0.0]},
			{"quarter_turn": 2, "variant_id": "workshop_q2_neg_z", "asset_id": "sanctuary/player_structures/workshop/operational/q2_neg_z", "facing": [0.0, 0.0, -1.0]},
			{"quarter_turn": 3, "variant_id": "workshop_q3_neg_x", "asset_id": "sanctuary/player_structures/workshop/operational/q3_neg_x", "facing": [-1.0, 0.0, 0.0]},
		],
		"access_zones": [
			{"id": "front_door", "kind": "door", "visible_feature_id": "workshop_double_door", "center": [0.0, 0.0, 2.20], "size": [1.30, 0.80], "facing": [0.0, 0.0, 1.0], "must_be_visible_in_asset": true},
			{"id": "forge_service", "kind": "service", "visible_feature_id": "workshop_forge_hatch", "center": [3.25, 0.0, -1.05], "size": [0.70, 1.30], "facing": [1.0, 0.0, 0.0], "must_be_visible_in_asset": true},
		],
		"collision_profile_id": "workshop_compound_v1",
		"construction_components": [
			{"id": "foundation_stone", "asset_id": "sanctuary/player_structures/workshop/construction/foundation_stone", "phase": "foundation", "material": "stone", "amount": 8, "center": [0.0, 0.10, 0.0], "size": [5.40, 0.20, 4.40]},
			{"id": "frame_timbers", "asset_id": "sanctuary/player_structures/workshop/construction/frame_timbers", "phase": "frame", "material": "wood", "amount": 4, "center": [0.0, 1.92, 0.0], "size": [5.55, 3.90, 4.35]},
			{"id": "wall_panels", "asset_id": "sanctuary/player_structures/workshop/construction/wall_panels", "phase": "walls", "material": "wood", "amount": 4, "center": [0.0, 1.78, 0.0], "size": [5.45, 3.56, 4.25]},
			{"id": "roof_tiles", "asset_id": "sanctuary/player_structures/workshop/construction/roof_tiles", "phase": "roof", "material": "wood", "amount": 2, "center": [0.0, 3.78, 0.0], "size": [5.70, 0.35, 4.55]},
			{"id": "forge_fittings", "asset_id": "sanctuary/player_structures/workshop/construction/forge_fittings", "phase": "fittings", "material": "wood", "amount": 2, "center": [1.90, 1.05, -1.05], "size": [1.20, 1.46, 1.00]},
		],
	},
	"archive": {
		"profile_id": "sanctuary_structure_archive_v1",
		"asset_id": "sanctuary/player_structures/archive",
		# Temporary fallback only; directional archive artwork must use the unique
		# asset IDs above and below once the renderer consumes profile variants.
		"sprite_kind": "workshop",
		"source_asset": "res://assets/sourced/quaternius-medieval-village/Medieval Village Pack - Dec 2020/Buildings/FBX/House_3.fbx",
		"operational_art_mode": "illustrated_2_5d",
		"world_size": 7.1,
		"directional_variants": [
			{"quarter_turn": 0, "variant_id": "archive_q0_pos_z", "asset_id": "sanctuary/player_structures/archive/operational/q0_pos_z", "facing": [0.0, 0.0, 1.0]},
			{"quarter_turn": 1, "variant_id": "archive_q1_pos_x", "asset_id": "sanctuary/player_structures/archive/operational/q1_pos_x", "facing": [1.0, 0.0, 0.0]},
			{"quarter_turn": 2, "variant_id": "archive_q2_neg_z", "asset_id": "sanctuary/player_structures/archive/operational/q2_neg_z", "facing": [0.0, 0.0, -1.0]},
			{"quarter_turn": 3, "variant_id": "archive_q3_neg_x", "asset_id": "sanctuary/player_structures/archive/operational/q3_neg_x", "facing": [-1.0, 0.0, 0.0]},
		],
		"access_zones": [
			{"id": "front_door", "kind": "door", "visible_feature_id": "archive_arched_door", "center": [0.0, 0.0, 1.80], "size": [1.25, 0.70], "facing": [0.0, 0.0, 1.0], "must_be_visible_in_asset": true},
			{"id": "catalogue_window", "kind": "service", "visible_feature_id": "archive_catalogue_window", "center": [-2.75, 0.0, 0.16], "size": [0.70, 1.20], "facing": [-1.0, 0.0, 0.0], "must_be_visible_in_asset": true},
		],
		"collision_profile_id": "archive_compound_v1",
		"construction_components": [
			{"id": "foundation_stone", "asset_id": "sanctuary/player_structures/archive/construction/foundation_stone", "phase": "foundation", "material": "stone", "amount": 8, "center": [0.0, 0.10, 0.0], "size": [4.40, 0.20, 3.40]},
			{"id": "frame_timbers", "asset_id": "sanctuary/player_structures/archive/construction/frame_timbers", "phase": "frame", "material": "wood", "amount": 3, "center": [0.0, 1.65, 0.0], "size": [4.55, 3.35, 3.30]},
			{"id": "wall_panels", "asset_id": "sanctuary/player_structures/archive/construction/wall_panels", "phase": "walls", "material": "wood", "amount": 3, "center": [0.0, 1.56, 0.0], "size": [4.45, 3.06, 3.20]},
			{"id": "roof_tiles", "asset_id": "sanctuary/player_structures/archive/construction/roof_tiles", "phase": "roof", "material": "wood", "amount": 2, "center": [0.0, 3.04, 0.0], "size": [4.75, 0.32, 3.50]},
			{"id": "archive_fittings", "asset_id": "sanctuary/player_structures/archive/construction/archive_fittings", "phase": "fittings", "material": "plank", "amount": 3, "center": [-0.65, 0.82, -0.12], "size": [1.00, 1.12, 0.82]},
		],
	},
	"storage_shed": {
		"profile_id": "sanctuary_structure_storage_shed_v1",
		"asset_id": "sanctuary/player_structures/storage_shed",
		"sprite_kind": "tent",
		"source_asset": "res://assets/sourced/quaternius-medieval-village/Medieval Village Pack - Dec 2020/Buildings/FBX/House_4.fbx",
		"operational_art_mode": "illustrated_2_5d",
		"world_size": 6.8,
		"directional_variants": [
			{"quarter_turn": 0, "variant_id": "storage_shed_q0_pos_z", "asset_id": "sanctuary/player_structures/storage_shed/operational/q0_pos_z", "facing": [0.0, 0.0, 1.0]},
			{"quarter_turn": 1, "variant_id": "storage_shed_q1_pos_x", "asset_id": "sanctuary/player_structures/storage_shed/operational/q1_pos_x", "facing": [1.0, 0.0, 0.0]},
			{"quarter_turn": 2, "variant_id": "storage_shed_q2_neg_z", "asset_id": "sanctuary/player_structures/storage_shed/operational/q2_neg_z", "facing": [0.0, 0.0, -1.0]},
			{"quarter_turn": 3, "variant_id": "storage_shed_q3_neg_x", "asset_id": "sanctuary/player_structures/storage_shed/operational/q3_neg_x", "facing": [-1.0, 0.0, 0.0]},
		],
		"access_zones": [
			{"id": "front_door", "kind": "door", "visible_feature_id": "storage_shed_sliding_door", "center": [0.0, 0.0, 1.80], "size": [1.40, 0.70], "facing": [0.0, 0.0, 1.0], "must_be_visible_in_asset": true},
			{"id": "loading_side", "kind": "service", "visible_feature_id": "storage_shed_loading_hatch", "center": [2.75, 0.0, 0.12], "size": [0.70, 1.28], "facing": [1.0, 0.0, 0.0], "must_be_visible_in_asset": true},
		],
		"collision_profile_id": "storage_shed_compound_v1",
		"construction_components": [
			{"id": "foundation_stone", "asset_id": "sanctuary/player_structures/storage_shed/construction/foundation_stone", "phase": "foundation", "material": "stone", "amount": 4, "center": [0.0, 0.10, 0.0], "size": [4.40, 0.20, 3.40]},
			{"id": "frame_timbers", "asset_id": "sanctuary/player_structures/storage_shed/construction/frame_timbers", "phase": "frame", "material": "wood", "amount": 4, "center": [0.0, 1.45, 0.0], "size": [4.55, 2.95, 3.30]},
			{"id": "wall_panels", "asset_id": "sanctuary/player_structures/storage_shed/construction/wall_panels", "phase": "walls", "material": "wood", "amount": 3, "center": [0.0, 1.36, 0.0], "size": [4.45, 2.72, 3.20]},
			{"id": "roof_tiles", "asset_id": "sanctuary/player_structures/storage_shed/construction/roof_tiles", "phase": "roof", "material": "wood", "amount": 3, "center": [0.0, 2.72, 0.0], "size": [4.75, 0.30, 3.50]},
			{"id": "storage_fittings", "asset_id": "sanctuary/player_structures/storage_shed/construction/storage_fittings", "phase": "fittings", "material": "plank", "amount": 3, "center": [0.62, 0.74, 0.12], "size": [1.00, 1.12, 0.82]},
		],
	},
	"livestock_pen": {
		"profile_id": "sanctuary_structure_livestock_pen_v1",
		"asset_id": "sanctuary/player_structures/livestock_pen",
		# Temporary fallback only; it keeps the current sheet renderer stable while
		# preventing garden art from being treated as the pen's production asset.
		"sprite_kind": "garden",
		"source_asset": "res://assets/sourced/quaternius-medieval-village/Medieval Village Pack - Dec 2020/Buildings/FBX/Stable.fbx",
		"operational_art_mode": "illustrated_2_5d",
		"world_size": 5.9,
		"directional_variants": [
			{"quarter_turn": 0, "variant_id": "livestock_pen_q0_pos_z", "asset_id": "sanctuary/player_structures/livestock_pen/operational/q0_pos_z", "facing": [0.0, 0.0, 1.0]},
			{"quarter_turn": 1, "variant_id": "livestock_pen_q1_pos_x", "asset_id": "sanctuary/player_structures/livestock_pen/operational/q1_pos_x", "facing": [1.0, 0.0, 0.0]},
			{"quarter_turn": 2, "variant_id": "livestock_pen_q2_neg_z", "asset_id": "sanctuary/player_structures/livestock_pen/operational/q2_neg_z", "facing": [0.0, 0.0, -1.0]},
			{"quarter_turn": 3, "variant_id": "livestock_pen_q3_neg_x", "asset_id": "sanctuary/player_structures/livestock_pen/operational/q3_neg_x", "facing": [-1.0, 0.0, 0.0]},
		],
		"access_zones": [
			{"id": "front_gate", "kind": "door", "visible_feature_id": "livestock_pen_latched_gate", "center": [0.0, 0.0, 2.40], "size": [1.60, 0.80], "facing": [0.0, 0.0, 1.0], "must_be_visible_in_asset": true},
			{"id": "feeding_side", "kind": "service", "visible_feature_id": "livestock_pen_feed_trough", "center": [3.75, 0.0, -0.62], "size": [0.80, 1.40], "facing": [1.0, 0.0, 0.0], "must_be_visible_in_asset": true},
		],
		"collision_profile_id": "livestock_pen_compound_v1",
		"construction_components": [
			{"id": "foundation_fiber", "asset_id": "sanctuary/player_structures/livestock_pen/construction/foundation_fiber", "phase": "foundation", "material": "fiber", "amount": 6, "center": [0.0, 0.08, 0.0], "size": [6.40, 0.16, 4.40]},
			{"id": "frame_timbers", "asset_id": "sanctuary/player_structures/livestock_pen/construction/frame_timbers", "phase": "frame", "material": "wood", "amount": 4, "center": [0.0, 1.02, 0.0], "size": [6.50, 2.00, 4.60]},
			{"id": "fence_panels", "asset_id": "sanctuary/player_structures/livestock_pen/construction/fence_panels", "phase": "walls", "material": "wood", "amount": 3, "center": [0.0, 0.92, 0.0], "size": [6.45, 1.76, 4.50]},
			{"id": "shade_roof", "asset_id": "sanctuary/player_structures/livestock_pen/construction/shade_roof", "phase": "roof", "material": "wood", "amount": 3, "center": [0.95, 2.10, -0.30], "size": [2.80, 0.28, 2.20]},
			{"id": "feed_fittings", "asset_id": "sanctuary/player_structures/livestock_pen/construction/feed_fittings", "phase": "fittings", "material": "plank", "amount": 2, "center": [2.35, 0.62, -0.62], "size": [1.00, 1.12, 1.20]},
		],
	},
	"rain_cistern": {
		"profile_id": "sanctuary_structure_rain_cistern_v1",
		"asset_id": "sanctuary/player_structures/rain_cistern",
		"sprite_kind": "well",
		"source_asset": "res://assets/sourced/quaternius-medieval-village/Medieval Village Pack - Dec 2020/Props/FBX/Well.fbx",
		"operational_art_mode": "illustrated_2_5d",
		"world_size": 4.8,
		"directional_variants": [
			{"quarter_turn": 0, "variant_id": "rain_cistern_q0_pos_z", "asset_id": "sanctuary/player_structures/rain_cistern/operational/q0_pos_z", "facing": [0.0, 0.0, 1.0]},
			{"quarter_turn": 1, "variant_id": "rain_cistern_q1_pos_x", "asset_id": "sanctuary/player_structures/rain_cistern/operational/q1_pos_x", "facing": [1.0, 0.0, 0.0]},
			{"quarter_turn": 2, "variant_id": "rain_cistern_q2_neg_z", "asset_id": "sanctuary/player_structures/rain_cistern/operational/q2_neg_z", "facing": [0.0, 0.0, -1.0]},
			{"quarter_turn": 3, "variant_id": "rain_cistern_q3_neg_x", "asset_id": "sanctuary/player_structures/rain_cistern/operational/q3_neg_x", "facing": [-1.0, 0.0, 0.0]},
		],
		"access_zones": [
			{"id": "draw_water", "kind": "service", "visible_feature_id": "rain_cistern_spout", "center": [0.0, 0.0, 2.25], "size": [1.20, 0.70], "facing": [0.0, 0.0, 1.0], "must_be_visible_in_asset": true},
			{"id": "maintenance_hatch", "kind": "service", "visible_feature_id": "rain_cistern_hatch", "center": [-2.25, 0.0, -0.28], "size": [0.80, 1.10], "facing": [-1.0, 0.0, 0.0], "must_be_visible_in_asset": true},
		],
		"collision_profile_id": "rain_cistern_compound_v1",
		"construction_components": [
			{"id": "foundation_pad", "asset_id": "sanctuary/player_structures/rain_cistern/construction/foundation_pad", "phase": "foundation", "material": "wood", "amount": 2, "center": [0.0, 0.08, 0.0], "size": [3.40, 0.16, 3.40]},
			{"id": "frame_posts", "asset_id": "sanctuary/player_structures/rain_cistern/construction/frame_posts", "phase": "frame", "material": "wood", "amount": 2, "center": [0.0, 1.25, 0.0], "size": [3.60, 2.40, 3.20]},
			{"id": "tank_walls", "asset_id": "sanctuary/player_structures/rain_cistern/construction/tank_walls", "phase": "walls", "material": "wood", "amount": 2, "center": [0.0, 1.25, 0.0], "size": [3.00, 2.20, 3.00]},
			{"id": "cistern_roof", "asset_id": "sanctuary/player_structures/rain_cistern/construction/cistern_roof", "phase": "roof", "material": "wood", "amount": 2, "center": [0.0, 2.72, 0.0], "size": [3.50, 0.30, 3.40]},
			{"id": "pump_fittings", "asset_id": "sanctuary/player_structures/rain_cistern/construction/pump_fittings", "phase": "fittings", "material": "plank", "amount": 2, "center": [1.05, 0.92, 1.00], "size": [0.76, 1.60, 0.76]},
		],
	},
}

const RESOURCE_TREES := {
	"fruit_tree": {"asset_id": "environment/fruit_tree", "sprite_index": 0, "world_size": 4.25},
	"pine_tree": {"asset_id": "environment/pine_tree", "sprite_index": 1, "world_size": 4.25},
	"autumn_tree": {"asset_id": "environment/autumn_tree", "sprite_index": 2, "world_size": 4.25},
}

static func structure_definition(kind: String) -> Dictionary:
	return STRUCTURES.get(kind, STRUCTURES["storage_shed"]).duplicate(true)

## Returns the unique directional presentation record for a normalized quarter
## turn. This does not rotate or mutate gameplay occupancy.
static func structure_directional_variant(kind: String, rotation_quarter_turns: int) -> Dictionary:
	var normalized_rotation := posmod(rotation_quarter_turns, 4)
	var definition := structure_definition(kind)
	var variants: Array = definition.get("directional_variants", [])
	for variant_value in variants:
		if not (variant_value is Dictionary):
			continue
		var variant: Dictionary = variant_value
		if int(variant.get("quarter_turn", -1)) == normalized_rotation:
			return variant.duplicate(true)
	return {}

static func structure_variant_asset_id(kind: String, rotation_quarter_turns: int) -> String:
	return str(structure_directional_variant(kind, rotation_quarter_turns).get("asset_id", ""))

## Returns access/service zones transformed into the requested root rotation.
## Consumers may use these for approach markers and interaction anchors, but the
## zones do not authorize placement or change the settlement grid.
static func structure_access_zones(kind: String, rotation_quarter_turns := 0) -> Array:
	var normalized_rotation := posmod(rotation_quarter_turns, 4)
	var definition := structure_definition(kind)
	var variant := structure_directional_variant(kind, normalized_rotation)
	var result: Array = []
	for zone_value in definition.get("access_zones", []):
		if not (zone_value is Dictionary):
			continue
		var zone: Dictionary = zone_value.duplicate(true)
		zone["center"] = _rotate_vector3_array(zone.get("center", []), normalized_rotation)
		zone["facing"] = _rotate_vector3_array(zone.get("facing", []), normalized_rotation)
		zone["size"] = _rotate_planar_size(zone.get("size", []), normalized_rotation)
		zone["quarter_turn"] = normalized_rotation
		zone["variant_id"] = str(variant.get("variant_id", ""))
		result.append(zone)
	return result

static func tree_definition(sprite_index: int) -> Dictionary:
	for tree_id in RESOURCE_TREES:
		var definition: Dictionary = RESOURCE_TREES[tree_id]
		if int(definition.get("sprite_index", -1)) == sprite_index:
			return definition.duplicate(true)
	return RESOURCE_TREES["fruit_tree"].duplicate(true)

static func _rotate_vector3_array(value: Variant, quarter_turns: int) -> Array:
	if not (value is Array) or (value as Array).size() < 3:
		return [0.0, 0.0, 0.0]
	var values := value as Array
	var rotated := _rotate_xz(float(values[0]), float(values[2]), quarter_turns)
	return [rotated.x, float(values[1]), rotated.y]

static func _rotate_planar_size(value: Variant, quarter_turns: int) -> Array:
	if not (value is Array) or (value as Array).size() < 2:
		return [0.0, 0.0]
	var values := value as Array
	if posmod(quarter_turns, 2) == 1:
		return [float(values[1]), float(values[0])]
	return [float(values[0]), float(values[1])]

static func _rotate_xz(x: float, z: float, quarter_turns: int) -> Vector2:
	match posmod(quarter_turns, 4):
		1:
			return Vector2(z, -x)
		2:
			return Vector2(-x, -z)
		3:
			return Vector2(-z, x)
		_:
			return Vector2(x, z)
