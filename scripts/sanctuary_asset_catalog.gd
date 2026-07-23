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
		# Workshop has a complete four-view construction family as well as its
		# operational hero art. Fail closed to that authored family instead of
		# letting the legacy scaffold reappear during a state refresh.
		"directional_art_required": true,
		"directional_art_revision": "workshop_cozy_v2",
		"world_size": 8.2,
		"interior_profile": {
			"interior_id": "workshop_v1",
			"entry_zone_id": "front_door",
			"ceiling_height_ratio": 0.82,
			"egress_clearance_ratio": 0.18,
			# Keep the authored cutaway registered to the measured interior envelope.
			# A larger presentation bleed made the painted floor/walls disagree with
			# the persisted metre grid, station footprints, and exit marker.
			"illustrated_shell_width_ratio": 1.0,
		},
		"construction_stage_paths": {
			"blueprint": "res://assets/generated/sanctuary/workshop/workshop-stage-blueprint.png",
			"frame": "res://assets/generated/sanctuary/workshop/workshop-stage-frame.png",
			"walls": "res://assets/generated/sanctuary/workshop/workshop-stage-walls.png",
			"roof": "res://assets/generated/sanctuary/workshop/workshop-stage-roof.png",
		},
		"construction_stage_directional_paths": {
			"blueprint": {0: "res://assets/generated/sanctuary/workshop/workshop-stage-blueprint.png", 1: "res://assets/generated/sanctuary/workshop/workshop-stage-blueprint-q1.png", 2: "res://assets/generated/sanctuary/workshop/workshop-stage-blueprint-q2.png", 3: "res://assets/generated/sanctuary/workshop/workshop-stage-blueprint-q3.png"},
			"frame": {0: "res://assets/generated/sanctuary/workshop/workshop-stage-frame.png", 1: "res://assets/generated/sanctuary/workshop/workshop-stage-frame-q1.png", 2: "res://assets/generated/sanctuary/workshop/workshop-stage-frame-q2.png", 3: "res://assets/generated/sanctuary/workshop/workshop-stage-frame-q3.png"},
			"walls": {0: "res://assets/generated/sanctuary/workshop/workshop-stage-walls.png", 1: "res://assets/generated/sanctuary/workshop/workshop-stage-walls-q1.png", 2: "res://assets/generated/sanctuary/workshop/workshop-stage-walls-q2.png", 3: "res://assets/generated/sanctuary/workshop/workshop-stage-walls-q3.png"},
			"roof": {0: "res://assets/generated/sanctuary/workshop/workshop-stage-roof.png", 1: "res://assets/generated/sanctuary/workshop/workshop-stage-roof-q1.png", 2: "res://assets/generated/sanctuary/workshop/workshop-stage-roof-q2.png", 3: "res://assets/generated/sanctuary/workshop/workshop-stage-roof-q3.png"},
		},
		# Every Workshop build direction is assembled from measured regions of its
		# own authored kit. Each region is a visible contributor; the old complete
		# stage PNGs remain in the catalog as audit/reference assets only.
		# `world_height` and `position` are presentation anchors, not gameplay or
		# collision dimensions.
		"layered_construction": {
			"asset_path": "res://assets/generated/sanctuary/workshop/workshop-construction-kit.png",
			"directional_asset_paths": {
				0: "res://assets/generated/sanctuary/workshop/workshop-construction-kit.png",
				1: "res://assets/generated/sanctuary/workshop/workshop-construction-kit-q1.png",
				2: "res://assets/generated/sanctuary/workshop/workshop-construction-kit-q2.png",
				3: "res://assets/generated/sanctuary/workshop/workshop-construction-kit-q3.png",
			},
			"source_size": [1254, 1254],
			"layers": {
				"foundation": {"region": [0, 118, 640, 366], "world_height": 4.02, "position": [0.0, 0.0, 0.0], "render_priority": 1},
				"frame": {"region": [630, 0, 624, 500], "world_height": 5.42, "position": [0.02, 0.15, -0.05], "render_priority": 2},
				"walls": {"region": [0, 470, 620, 450], "world_height": 5.30, "position": [0.0, 0.13, 0.02], "render_priority": 3},
				"roof": {"region": [600, 470, 654, 470], "world_height": 5.30, "position": [0.02, 2.55, -0.08], "render_priority": 4},
				"fittings": {"region": [50, 880, 760, 374], "world_height": 2.34, "position": [0.05, 0.10, 0.60], "render_priority": 5},
			},
		},
		"directional_variants": [
			# Keep the semantic variant IDs stable so saved rotations and interaction
			# metadata do not change when art is iterated; only the presentation
			# sources move as one authored family.
			{"quarter_turn": 0, "variant_id": "workshop_q0_pos_z", "asset_id": "sanctuary/player_structures/workshop/operational/q0_pos_z", "asset_path": "res://assets/generated/sanctuary/workshop/workshop-cozy-v2.png", "facing": [0.0, 0.0, 1.0], "art_revision": "workshop_cozy_v2"},
			{"quarter_turn": 1, "variant_id": "workshop_q1_pos_x", "asset_id": "sanctuary/player_structures/workshop/operational/q1_pos_x", "asset_path": "res://assets/generated/sanctuary/workshop/workshop-cozy-v2-q1.png", "facing": [1.0, 0.0, 0.0], "art_revision": "workshop_cozy_v2"},
			{"quarter_turn": 2, "variant_id": "workshop_q2_neg_z", "asset_id": "sanctuary/player_structures/workshop/operational/q2_neg_z", "asset_path": "res://assets/generated/sanctuary/workshop/workshop-cozy-v2-q2.png", "facing": [0.0, 0.0, -1.0], "art_revision": "workshop_cozy_v2"},
			{"quarter_turn": 3, "variant_id": "workshop_q3_neg_x", "asset_id": "sanctuary/player_structures/workshop/operational/q3_neg_x", "asset_path": "res://assets/generated/sanctuary/workshop/workshop-cozy-v2-q3-mirrored.png", "facing": [-1.0, 0.0, 0.0], "art_revision": "workshop_cozy_v2"},
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
		# Archive now has its own four-view construction family. The source is a
		# frame-with-blueprint-shell kit: the renderer uses the same physically
		# measured silhouette through the build, then fades in the authored hero
		# envelope as walls and roof materials are delivered. It must never fall back
		# to the generic scaffold or Workshop's construction art.
		"sprite_kind": "workshop",
		"source_asset": "res://assets/sourced/quaternius-medieval-village/Medieval Village Pack - Dec 2020/Buildings/FBX/House_3.fbx",
		"operational_art_mode": "illustrated_2_5d",
		"directional_art_required": true,
		"world_size": 7.1,
		"interior_profile": {
			"interior_id": "archive_v1",
			"entry_zone_id": "front_door",
			"ceiling_height_ratio": 0.80,
			"egress_clearance_ratio": 0.18,
			"illustrated_shell_width_ratio": 1.0,
		},
		"construction_stage_directional_paths": {
			"blueprint": {0: "res://assets/generated/sanctuary/archive/archive-construction-frame-q0.png", 1: "res://assets/generated/sanctuary/archive/archive-construction-frame-q1.png", 2: "res://assets/generated/sanctuary/archive/archive-construction-frame-q2.png", 3: "res://assets/generated/sanctuary/archive/archive-construction-frame-q3.png"},
			"frame": {0: "res://assets/generated/sanctuary/archive/archive-construction-frame-q0.png", 1: "res://assets/generated/sanctuary/archive/archive-construction-frame-q1.png", 2: "res://assets/generated/sanctuary/archive/archive-construction-frame-q2.png", 3: "res://assets/generated/sanctuary/archive/archive-construction-frame-q3.png"},
			"walls": {0: "res://assets/generated/sanctuary/archive/archive-construction-frame-q0.png", 1: "res://assets/generated/sanctuary/archive/archive-construction-frame-q1.png", 2: "res://assets/generated/sanctuary/archive/archive-construction-frame-q2.png", 3: "res://assets/generated/sanctuary/archive/archive-construction-frame-q3.png"},
			"roof": {0: "res://assets/generated/sanctuary/archive/archive-construction-frame-q0.png", 1: "res://assets/generated/sanctuary/archive/archive-construction-frame-q1.png", 2: "res://assets/generated/sanctuary/archive/archive-construction-frame-q2.png", 3: "res://assets/generated/sanctuary/archive/archive-construction-frame-q3.png"},
		},
		"directional_variants": [
			{"quarter_turn": 0, "variant_id": "archive_q0_pos_z", "asset_id": "sanctuary/player_structures/archive/operational/q0_pos_z", "asset_path": "res://assets/generated/sanctuary/archive/archive-q0.png", "facing": [0.0, 0.0, 1.0]},
			{"quarter_turn": 1, "variant_id": "archive_q1_pos_x", "asset_id": "sanctuary/player_structures/archive/operational/q1_pos_x", "asset_path": "res://assets/generated/sanctuary/archive/archive-q1.png", "facing": [1.0, 0.0, 0.0]},
			{"quarter_turn": 2, "variant_id": "archive_q2_neg_z", "asset_id": "sanctuary/player_structures/archive/operational/q2_neg_z", "asset_path": "res://assets/generated/sanctuary/archive/archive-q2.png", "facing": [0.0, 0.0, -1.0]},
			{"quarter_turn": 3, "variant_id": "archive_q3_neg_x", "asset_id": "sanctuary/player_structures/archive/operational/q3_neg_x", "asset_path": "res://assets/generated/sanctuary/archive/archive-q3.png", "facing": [-1.0, 0.0, 0.0]},
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
		# House_4 is a narrow decorative prop (its measured envelope underfills the
		# 5x4 m claim). Sawmill is the sourced shed-scale proxy: its measured
		# 4.40x2.86x3.28 m envelope fits at least 94% of the horizontal claim after
		# uniform measurement-based fitting, without inventing a per-building
		# collider dimension.
		"source_asset": "res://assets/sourced/quaternius-medieval-village/Medieval Village Pack - Dec 2020/Buildings/FBX/Sawmill.fbx",
		"operational_art_mode": "illustrated_2_5d",
		"directional_art_required": true,
		"require_measured_claim_fill": true,
		"world_size": 6.8,
		"construction_stage_directional_paths": {
			"blueprint": {0: "res://assets/generated/sanctuary/storage_shed/storage_shed-stage-blueprint.png", 1: "res://assets/generated/sanctuary/storage_shed/storage_shed-stage-blueprint-q1.png", 2: "res://assets/generated/sanctuary/storage_shed/storage_shed-stage-blueprint-q2.png", 3: "res://assets/generated/sanctuary/storage_shed/storage_shed-stage-blueprint-q3.png"},
			"frame": {0: "res://assets/generated/sanctuary/storage_shed/storage_shed-stage-frame.png", 1: "res://assets/generated/sanctuary/storage_shed/storage_shed-stage-frame-q1.png", 2: "res://assets/generated/sanctuary/storage_shed/storage_shed-stage-frame-q2.png", 3: "res://assets/generated/sanctuary/storage_shed/storage_shed-stage-frame-q3.png"},
			"walls": {0: "res://assets/generated/sanctuary/storage_shed/storage_shed-stage-walls.png", 1: "res://assets/generated/sanctuary/storage_shed/storage_shed-stage-walls-q1.png", 2: "res://assets/generated/sanctuary/storage_shed/storage_shed-stage-walls-q2.png", 3: "res://assets/generated/sanctuary/storage_shed/storage_shed-stage-walls-q3.png"},
			"roof": {0: "res://assets/generated/sanctuary/storage_shed/storage_shed-stage-roof.png", 1: "res://assets/generated/sanctuary/storage_shed/storage_shed-stage-roof-q1.png", 2: "res://assets/generated/sanctuary/storage_shed/storage_shed-stage-roof-q2.png", 3: "res://assets/generated/sanctuary/storage_shed/storage_shed-stage-roof-q3.png"},
		},
		"directional_variants": [
			{"quarter_turn": 0, "variant_id": "storage_shed_q0_pos_z", "asset_id": "sanctuary/player_structures/storage_shed/operational/q0_pos_z", "asset_path": "res://assets/generated/sanctuary/storage_shed/storage_shed-q0.png", "visible_feature_ids": ["front_door", "loading_side"], "facing": [0.0, 0.0, 1.0]},
			{"quarter_turn": 1, "variant_id": "storage_shed_q1_pos_x", "asset_id": "sanctuary/player_structures/storage_shed/operational/q1_pos_x", "asset_path": "res://assets/generated/sanctuary/storage_shed/storage_shed-q1.png", "visible_feature_ids": ["front_door"], "facing": [1.0, 0.0, 0.0]},
			{"quarter_turn": 2, "variant_id": "storage_shed_q2_neg_z", "asset_id": "sanctuary/player_structures/storage_shed/operational/q2_neg_z", "asset_path": "res://assets/generated/sanctuary/storage_shed/storage_shed-q2.png", "visible_feature_ids": [], "facing": [0.0, 0.0, -1.0]},
			{"quarter_turn": 3, "variant_id": "storage_shed_q3_neg_x", "asset_id": "sanctuary/player_structures/storage_shed/operational/q3_neg_x", "asset_path": "res://assets/generated/sanctuary/storage_shed/storage_shed-q3.png", "visible_feature_ids": ["loading_side"], "facing": [-1.0, 0.0, 0.0]},
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
		# Operational art is a dedicated four-view authored enclosure family. The
		# shared garden cell remains only as a construction-stage fallback until the
		# matching pen scaffold/frame/walls/roof family is authored.
		"sprite_kind": "garden",
		"source_asset": "res://assets/sourced/quaternius-medieval-village/Medieval Village Pack - Dec 2020/Buildings/FBX/Stable.fbx",
		"operational_art_mode": "illustrated_2_5d",
		"world_size": 5.9,
		"directional_variants": [
			{"quarter_turn": 0, "variant_id": "livestock_pen_q0_pos_z", "asset_id": "sanctuary/player_structures/livestock_pen/operational/q0_pos_z", "asset_path": "res://assets/generated/sanctuary/livestock_pen/livestock-pen-q0.png", "facing": [0.0, 0.0, 1.0]},
			{"quarter_turn": 1, "variant_id": "livestock_pen_q1_pos_x", "asset_id": "sanctuary/player_structures/livestock_pen/operational/q1_pos_x", "asset_path": "res://assets/generated/sanctuary/livestock_pen/livestock-pen-q1.png", "facing": [1.0, 0.0, 0.0]},
			{"quarter_turn": 2, "variant_id": "livestock_pen_q2_neg_z", "asset_id": "sanctuary/player_structures/livestock_pen/operational/q2_neg_z", "asset_path": "res://assets/generated/sanctuary/livestock_pen/livestock-pen-q2.png", "facing": [0.0, 0.0, -1.0]},
			{"quarter_turn": 3, "variant_id": "livestock_pen_q3_neg_x", "asset_id": "sanctuary/player_structures/livestock_pen/operational/q3_neg_x", "asset_path": "res://assets/generated/sanctuary/livestock_pen/livestock-pen-q3.png", "facing": [-1.0, 0.0, 0.0]},
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
		# Operational art is a dedicated four-view authored cistern family; its
		# tank, roof, pipes, platform, and water basin are one measured silhouette.
		"source_asset": "res://assets/sourced/quaternius-medieval-village/Medieval Village Pack - Dec 2020/Props/FBX/Well.fbx",
		"operational_art_mode": "illustrated_2_5d",
		"world_size": 4.8,
		"directional_variants": [
			{"quarter_turn": 0, "variant_id": "rain_cistern_q0_pos_z", "asset_id": "sanctuary/player_structures/rain_cistern/operational/q0_pos_z", "asset_path": "res://assets/generated/sanctuary/rain_cistern/rain-cistern-q0.png", "facing": [0.0, 0.0, 1.0]},
			{"quarter_turn": 1, "variant_id": "rain_cistern_q1_pos_x", "asset_id": "sanctuary/player_structures/rain_cistern/operational/q1_pos_x", "asset_path": "res://assets/generated/sanctuary/rain_cistern/rain-cistern-q1.png", "facing": [1.0, 0.0, 0.0]},
			{"quarter_turn": 2, "variant_id": "rain_cistern_q2_neg_z", "asset_id": "sanctuary/player_structures/rain_cistern/operational/q2_neg_z", "asset_path": "res://assets/generated/sanctuary/rain_cistern/rain-cistern-q2.png", "facing": [0.0, 0.0, -1.0]},
			{"quarter_turn": 3, "variant_id": "rain_cistern_q3_neg_x", "asset_id": "sanctuary/player_structures/rain_cistern/operational/q3_neg_x", "asset_path": "res://assets/generated/sanctuary/rain_cistern/rain-cistern-q3.png", "facing": [-1.0, 0.0, 0.0]},
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

## Static illustrated obstacles are one shared presentation/placement contract.
## SanctuaryStyle consumes these exact transforms for the visible framing art;
## GameSession consumes the derived placement rectangles so a player cannot
## legally claim a grid cell that the live foliage/rock envelope already occupies.
## `placement_clearance_ratio` is an authored build-clearance envelope, distinct
## from the smaller foot-bearing physics hitbox used by the sprite itself.
const FRAMING_OBSTACLES := [
	{"id": "framing_tree_fruit_0", "kind": "tree", "sprite_index": 0, "position": [-12.5, 0.10, -8.6], "world_size": 5.5, "placement_clearance_ratio": [0.32, 0.24]},
	{"id": "framing_tree_pine_1", "kind": "tree", "sprite_index": 1, "position": [-7.7, 0.10, -10.0], "world_size": 5.0, "placement_clearance_ratio": [0.32, 0.24]},
	{"id": "framing_tree_pine_2", "kind": "tree", "sprite_index": 1, "position": [0.0, 0.10, -10.4], "world_size": 5.4, "placement_clearance_ratio": [0.32, 0.24]},
	{"id": "framing_tree_autumn_3", "kind": "tree", "sprite_index": 2, "position": [7.2, 0.10, -9.4], "world_size": 5.0, "placement_clearance_ratio": [0.32, 0.24]},
	{"id": "framing_tree_fruit_4", "kind": "tree", "sprite_index": 0, "position": [12.0, 0.10, -7.4], "world_size": 5.0, "placement_clearance_ratio": [0.32, 0.24]},
	{"id": "framing_tree_autumn_5", "kind": "tree", "sprite_index": 2, "position": [-12.1, 0.10, 6.9], "world_size": 4.3, "placement_clearance_ratio": [0.32, 0.24]},
	{"id": "framing_tree_pine_6", "kind": "tree", "sprite_index": 1, "position": [12.2, 0.10, 7.4], "world_size": 4.8, "placement_clearance_ratio": [0.32, 0.24]},
	{"id": "framing_tree_fruit_7", "kind": "tree", "sprite_index": 0, "position": [-11.7, 0.10, 10.0], "world_size": 4.6, "placement_clearance_ratio": [0.32, 0.24]},
	{"id": "framing_tree_autumn_8", "kind": "tree", "sprite_index": 2, "position": [10.5, 0.10, 10.3], "world_size": 4.2, "placement_clearance_ratio": [0.32, 0.24]},
	{"id": "framing_rock_0", "kind": "rock", "sprite_index": 3, "position": [-11.5, 0.10, -3.9], "world_size": 3.2, "placement_clearance_ratio": [0.66, 0.30]},
	{"id": "framing_rock_1", "kind": "rock", "sprite_index": 3, "position": [11.6, 0.10, -2.6], "world_size": 2.8, "placement_clearance_ratio": [0.66, 0.30]},
	{"id": "framing_rock_2", "kind": "rock", "sprite_index": 3, "position": [-10.8, 0.10, 8.3], "world_size": 2.7, "placement_clearance_ratio": [0.66, 0.30]},
	{"id": "framing_rock_3", "kind": "rock", "sprite_index": 3, "position": [10.8, 0.10, 8.8], "world_size": 2.5, "placement_clearance_ratio": [0.66, 0.30]},
]

## Presentation-only activity sockets keep a fresh Sanctuary from reading as an
## empty editor grid before the player has chosen a layout. These are communal
## work areas and temporary settlement life, not player-owned structures: they
## deliberately carry no occupancy, collision, costs, or interaction authority.
## Their positions live in the content catalog so the art layer does not grow a
## second scattered set of magic coordinates. The player-directed build field,
## canonical landmarks, route gates, and measured framing obstacles remain the
## authorities for placement and traversal.
const LIVED_IN_ACTIVITY_SOCKETS := [
	{
		"id": "west_kitchen_garden",
		"kind": "garden",
		"role": "shared_food_plot",
		"position": [-6.9, 0.10, 8.3],
		"world_size": 3.4,
		"ground_rotation_degrees": -7.0,
		"animate": true,
	},
	{
		"id": "north_wayfarer_tent",
		"kind": "tent",
		"role": "temporary_shelter",
		"position": [3.8, 0.10, -10.7],
		"world_size": 3.8,
		"ground_rotation_degrees": 9.0,
		"animate": true,
	},
	{
		"id": "north_timber_yard",
		"kind": "scaffold",
		"role": "shared_material_yard",
		"position": [-3.6, 0.10, -10.7],
		"world_size": 3.4,
		"ground_rotation_degrees": -12.0,
		"animate": true,
	},
	{
		"id": "west_common_well",
		"kind": "well",
		"role": "shared_water_point",
		"position": [4.9, 0.10, 8.7],
		"world_size": 2.5,
		"ground_rotation_degrees": 4.0,
		"animate": true,
	},
	{
		"id": "east_trade_cart",
		"kind": "market",
		"role": "shared_trade_prep",
		"position": [6.45, 0.10, -1.55],
		"world_size": 2.65,
		"ground_rotation_degrees": 8.0,
		"animate": true,
	},
	{
		"id": "south_seed_bed",
		"kind": "garden",
		"role": "shared_seed_bed",
		"position": [-3.65, 0.10, 7.35],
		"world_size": 2.85,
		"ground_rotation_degrees": -10.0,
		"animate": true,
	},
	{
		"id": "west_timber_stacks",
		"kind": "scaffold",
		"role": "shared_material_yard",
		"position": [-6.55, 0.10, -3.20],
		"world_size": 2.75,
		"ground_rotation_degrees": -6.0,
		"animate": true,
	},
	{
		"id": "east_wayfarer_tent",
		"kind": "tent",
		"role": "temporary_shelter",
		"position": [4.85, 0.10, -7.75],
		"world_size": 3.05,
		"ground_rotation_degrees": 12.0,
		"animate": true,
	},
]

static func framing_placement_rects() -> Array:
	var result: Array = []
	for obstacle_value in FRAMING_OBSTACLES:
		if not (obstacle_value is Dictionary):
			continue
		var obstacle: Dictionary = obstacle_value
		var position: Array = obstacle.get("position", [])
		var ratio: Array = obstacle.get("placement_clearance_ratio", [0.0, 0.0])
		if position.size() < 3 or ratio.size() < 2:
			continue
		var world_size := float(obstacle.get("world_size", 0.0))
		var size := Vector2(world_size * float(ratio[0]), world_size * float(ratio[1]))
		if size.x <= 0.0 or size.y <= 0.0:
			continue
		result.append({
			"id": str(obstacle.get("id", "")),
			"rect": Rect2(Vector2(float(position[0]), float(position[2])) - size * 0.5, size),
		})
	return result

static func structure_definition(kind: String) -> Dictionary:
	if not STRUCTURES.has(kind):
		# Unknown persisted/content kinds must fail closed. Inheriting a complete
		# Storage Shed profile would fabricate the wrong art, footprint, access
		# zones, and collision profile for corrupted or future data.
		return {}
	return STRUCTURES[kind].duplicate(true)

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

static func structure_construction_stage_asset(kind: String, stage_id: String, rotation_quarter_turns: int) -> String:
	var definition := structure_definition(kind)
	var directional: Dictionary = definition.get("construction_stage_directional_paths", {})
	var stage_paths: Dictionary = directional.get(stage_id, {})
	var normalized_rotation := posmod(rotation_quarter_turns, 4)
	if directional.has(stage_id):
		# A declared directional family is a completeness contract. Missing turns
		# fail closed instead of silently reusing q0 art.
		return str(stage_paths.get(normalized_rotation, ""))
	return str(definition.get("construction_stage_paths", {}).get(stage_id, ""))

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
