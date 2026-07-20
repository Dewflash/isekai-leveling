extends SceneTree

## Deterministic Sanctuary visual-proof harness.
##
## This script intentionally drives Main through its existing presentation and
## session APIs. It does not add gameplay rules, change placement validation, or
## replace any runtime visual. A capture run uses a scratch save slot and keeps
## all state in memory after Main has loaded.

const MainScene := preload("res://main.tscn")
const SettlementGrid := preload("res://scripts/settlement_grid.gd")
const ContentRegistry := preload("res://scripts/content_registry.gd")

const CAPTURE_SIZE := Vector2i(1280, 720)
const INITIAL_SETTLE_FRAMES := 45
const STATE_SETTLE_FRAMES := 6
const MOTION_SAMPLE_COUNT := 4
const MOTION_FRAMES_PER_SAMPLE := 18
const MOTION_CAPTURE_PREFIX := "08_motion_occlusion_"
const MOTION_TREE_TARGET := Vector3(10.5, 0.0, 10.3)
const MIN_TRAVERSAL_DISTANCE := 2.0
const MIN_TREE_SWAY_DELTA := 0.0005
const MIN_FIRE_PULSE_DELTA := 0.0005
const MIN_LIGHT_FLICKER_DELTA := 0.01
const MIN_PLAYER_CHANGED_PIXELS := 18
const MIN_PLAYER_VISIBILITY_RATIO := 0.40
const MIN_LAYOUT_OCCUPIED_CELL_DIFFERENCE := 12
const MIN_LAYOUT_CHANGED_SAMPLE_RATIO := 0.08
const MIN_LAYOUT_MEAN_COLOR_DELTA := 0.02
const LAYOUT_PIXEL_SAMPLE_STEP := 4
const SCRATCH_SAVE_SLOT := "qa_sanctuary_stage_capture"
const STAGE_INSTANCE_ID := "qa_sanctuary_stage_workshop"
const STAGE_KIND := "workshop"
const CAMERA_OFFSET := Vector3(13.5, 18.0, 13.5)
const CAMERA_LOOK_OFFSET := Vector3(0.0, 0.2, 0.0)
const PLAYER_LAYOUT_A := [
	{"kind": "workshop", "cell": Vector2i(-13, 8), "rotation": 0},
	{"kind": "archive", "cell": Vector2i(4, 8), "rotation": 0},
	{"kind": "rain_cistern", "cell": Vector2i(10, -13), "rotation": 0},
	{"kind": "storage_shed", "cell": Vector2i(2, -13), "rotation": 0},
]
const PLAYER_LAYOUT_B := [
	{"kind": "workshop", "cell": Vector2i(4, 8), "rotation": 0},
	{"kind": "archive", "cell": Vector2i(-13, 8), "rotation": 0},
	{"kind": "rain_cistern", "cell": Vector2i(10, -13), "rotation": 0},
	{"kind": "storage_shed", "cell": Vector2i(2, -13), "rotation": 0},
]

var capture_viewport: SubViewport
var world: Node
var output_directory := ""
var stage_origin := Vector2i(2, 0)

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	output_directory = _resolve_output_directory()
	if not _ensure_output_directory():
		_abort("Could not create SANCTUARY_STAGE_CAPTURE_DIR: %s" % output_directory)
		return

	# Never read or overwrite the player's normal save during a visual proof.
	# Main still performs its normal load path, but the fixed scratch slot makes
	# that path isolated and the in-memory reset below makes the render stable.
	ProjectSettings.set_setting("prodewty/save_slot", SCRATCH_SAVE_SLOT)

	capture_viewport = SubViewport.new()
	capture_viewport.name = "SanctuaryStageCaptureViewport"
	capture_viewport.size = CAPTURE_SIZE
	capture_viewport.own_world_3d = true
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	capture_viewport.handle_input_locally = false
	root.add_child(capture_viewport)

	world = MainScene.instantiate()
	if world == null:
		_abort("Main scene could not be instantiated")
		return
	capture_viewport.add_child(world)

	# Imported scenes, authored Sprite3D sheets, the first camera settle, and the
	# HUD layout all need a real frame budget before a capture is meaningful.
	await _wait_frames(INITIAL_SETTLE_FRAMES)
	if _display_is_headless():
		_unavailable("headless display driver has no pixel-backed renderer")
		return
	if capture_viewport.get_texture() == null:
		_unavailable("Godot is using a dummy renderer with no texture storage")
		return

	if not await _prepare_capture_world():
		return
	print("SANCTUARY_STAGE_CAPTURE_ASSUMPTION HUD hidden for world-proof PNGs")
	print("SANCTUARY_STAGE_CAPTURE_ASSUMPTION stage is a player-placeable workshop at origin ", stage_origin, " with rotation 0")
	print("SANCTUARY_STAGE_CAPTURE_ASSUMPTION camera uses Main's authored orthographic offset ", CAMERA_OFFSET)

	# The captures are world-proof images rather than UI screenshots. The HUD is
	# still constructed by Main, but hiding it keeps the construction silhouette,
	# ground pivot, camera angle, and material scale inspectable in every PNG.
	_set_hud_visible(false)
	paused = true

	if not await _capture_clean_daylight():
		return
	if not await _capture_placement_preview():
		return
	if not await _capture_structure_stage("03_blueprint.png", "blueprint", 0.0, {"wood": 0, "stone": 0}):
		return
	if not await _capture_structure_stage("04_early_scaffold.png", "building", 30.0, {"wood": 3, "stone": 2}):
		return
	if not await _capture_structure_stage("05_mid_construction.png", "building", 18.0, {"wood": 8, "stone": 5}):
		return
	if not await _capture_structure_stage("06_late_construction.png", "building", 6.0, {"wood": 12, "stone": 8}):
		return
	if not await _capture_structure_stage("07_operational_structure.png", "operational", 0.0, {"wood": 12, "stone": 8}):
		return
	if not await _capture_motion_occlusion_proof():
		return
	var courtyard_layout := await _capture_player_authored_layout(
		"east_courtyard",
		"09_player_layout_east_courtyard.png",
		PLAYER_LAYOUT_A
	)
	if courtyard_layout.is_empty():
		return
	var split_workyard_layout := await _capture_player_authored_layout(
		"split_workyard",
		"10_player_layout_split_workyard.png",
		PLAYER_LAYOUT_B
	)
	if split_workyard_layout.is_empty():
		return
	if not _validate_player_layout_difference(courtyard_layout, split_workyard_layout):
		return

	paused = false
	print("SANCTUARY_STAGE_CAPTURE_PASS ", output_directory)
	quit()

func _prepare_capture_world() -> bool:
	if world == null:
		_abort("Capture world is missing")
		return false
	var session := world.get("session") as Node
	var player := world.get("player") as CharacterBody3D
	if session == null or player == null:
		_abort("Main did not expose a session and player after startup")
		return false

	# Keep the scene in the authored daylight state regardless of any prior
	# scratch-slot contents. No gameplay command is called here.
	session.set("save_blocked", true)
	session.set("day", 1)
	session.set("hour", 10.0)
	session.set("weather", "clear")
	session.set("structures", {})
	session.set("blueprints", [])
	session.set("station_job", {"kind": "none", "remaining_hours": 0.0, "output_id": "plank", "output": 0})
	session.set("research_job", {"status": "idle", "discovery_id": "", "ready_day": 0})
	session.set("expedition_run", {"status": "none", "run_id": "", "biome_id": "", "cargo": {}, "depleted_ids": [], "contact_progress": {}, "defeated_guardian_ids": [], "started_day": 0, "anchor": [0.0, 1.0, 7.5]})
	session.set("recovery_pack", {})
	session.set("sanctuary_depleted_ids", [])
	session.set("sanctuary_contact_progress", {})

	world.call("_set_zone", "Sanctuary")
	_clear_structure_visuals()
	world.set("placement_mode", false)
	world.set("placement_rotation_quarter_turns", 0)
	if world.has_method("_copy_session_to_runtime"):
		world.call("_copy_session_to_runtime")
	if world.has_method("_update_lighting"):
		world.call("_update_lighting")
	if player.has_method("cancel_navigation"):
		player.call("cancel_navigation", true)
	player.set("last_direction", Vector3(0.0, 0.0, -1.0))
	player.global_position = Vector3(0.0, 1.0, 4.0)

	stage_origin = _find_valid_stage_origin(session)
	if not bool(session.call("can_place_structure", STAGE_KIND, [stage_origin.x, stage_origin.y], 0)):
		_abort("Could not find a valid deterministic %s capture origin" % STAGE_KIND)
		return false

	# Let Main settle once more after the in-memory reset before freezing the
	# camera. Queue-free operations from an existing scratch save are also
	# complete by this point.
	paused = false
	await _wait_frames(STATE_SETTLE_FRAMES)
	return true

func _capture_clean_daylight() -> bool:
	await _begin_state()
	var player := world.get("player") as CharacterBody3D
	if player == null:
		_abort("Player disappeared before clean daylight capture")
		return false
	player.global_position = Vector3(0.0, 1.0, 4.0)
	player.set("last_direction", Vector3(0.0, 0.0, -1.0))
	_set_camera_focus(Vector3(0.0, 0.0, 1.6))
	world.call("_update_structure_preview")
	await _settle_and_pause()
	_set_camera_focus(Vector3(0.0, 0.0, 1.6))
	await process_frame
	return _save_capture("01_clean_daylight.png")

func _capture_placement_preview() -> bool:
	await _begin_state()
	var session := world.get("session") as Node
	var player := world.get("player") as CharacterBody3D
	var style := world.get("sanctuary_style") as Node
	if session == null or player == null:
		_abort("Session or player disappeared before placement preview capture")
		return false

	# _preview_structure_cell() treats the player's facing direction as the
	# placement ray. Put the player three metres behind the candidate origin so
	# the preview is a valid, readable, non-overlapping workshop footprint.
	world.set("placement_structure_id", STAGE_KIND)
	world.set("placement_rotation_quarter_turns", 0)
	world.set("placement_mode", true)
	var preview_footprint_data: Array = ContentRegistry.structure_definition(STAGE_KIND).get("footprint", [1, 1])
	var preview_footprint := Vector2i(int(preview_footprint_data[0]), int(preview_footprint_data[1]))
	var preview_distance := 3.0 + float(maxi(preview_footprint.x, preview_footprint.y) - 2)
	player.global_position = Vector3(float(stage_origin.x), 1.0, float(stage_origin.y) - preview_distance)
	player.set("last_direction", Vector3(0.0, 0.0, 1.0))
	if player.has_method("cancel_navigation"):
		player.call("cancel_navigation", true)
	world.call("_update_structure_preview")
	await _settle_and_pause()
	var preview_center := SettlementGrid.footprint_center_to_world(stage_origin, preview_footprint)
	_set_camera_focus(preview_center)
	await process_frame

	var preview_valid := bool(world.call("_structure_preview_valid", stage_origin))
	var preview_active := style != null and bool(style.get("placement_active"))
	var preview_fill := style.get_node_or_null("ConstructionPlacementPreview/PreviewFill") as MeshInstance3D if style != null else null
	var preview_mesh := preview_fill.mesh as BoxMesh if preview_fill != null else null
	var preview_shape_matches := preview_mesh != null and is_equal_approx(preview_mesh.size.x, float(preview_footprint.x)) and is_equal_approx(preview_mesh.size.z, float(preview_footprint.y))
	if not preview_valid or not preview_active or not preview_shape_matches:
		_abort("Placement preview did not resolve to a valid active footprint")
		return false
	return _save_capture("02_placement_preview_active.png")

func _capture_structure_stage(file_name: String, state: String, remaining_hours: float, delivered: Dictionary) -> bool:
	await _begin_state()
	var player := world.get("player") as CharacterBody3D
	if player == null:
		_abort("Player disappeared before %s" % file_name)
		return false

	world.set("placement_mode", false)
	world.call("_update_structure_preview")
	_clear_structure_visuals()
	var stage_data := {
		"id": STAGE_INSTANCE_ID,
		"kind": STAGE_KIND,
		"cell": [stage_origin.x, stage_origin.y],
		"rotation": 0,
		"state": state,
		"remaining_hours": remaining_hours,
		"total_hours": 36.0,
		"delivered_materials": delivered.duplicate(true),
	}
	world.call("_spawn_structure_visual", STAGE_INSTANCE_ID, stage_data)
	var footprint_data: Array = ContentRegistry.structure_definition(STAGE_KIND).get("footprint", [1, 1])
	var footprint := Vector2i(int(footprint_data[0]), int(footprint_data[1]))
	var stage_distance := 3.0 + float(maxi(footprint.x, footprint.y) - 2)
	player.global_position = Vector3(float(stage_origin.x), 1.0, float(stage_origin.y) - stage_distance)
	player.set("last_direction", Vector3(0.0, 0.0, 1.0))
	if player.has_method("cancel_navigation"):
		player.call("cancel_navigation", true)
	var structure_center := SettlementGrid.footprint_center_to_world(stage_origin, footprint)
	_set_camera_focus(structure_center)
	await _settle_and_pause()
	_set_camera_focus(structure_center)
	await process_frame
	return _save_capture(file_name)

func _capture_motion_occlusion_proof() -> bool:
	await _begin_state()
	var player := world.get("player") as CharacterBody3D
	var style := world.get("sanctuary_style") as Node3D
	if player == null or style == null:
		_abort("Player or illustrated Sanctuary style disappeared before motion proof")
		return false

	world.set("placement_mode", false)
	world.call("_update_structure_preview")
	_clear_structure_visuals()
	if player.has_method("cancel_navigation"):
		player.call("cancel_navigation", true)
	player.set("joystick_vector", Vector2.ZERO)

	var proof_tree := _find_motion_proof_tree(style)
	var proof_fire := _find_motion_proof_fire(style)
	var proof_light := _find_motion_proof_light(style)
	if proof_tree == null or proof_fire == null or proof_light == null:
		_abort("Motion proof requires an illustrated swaying tree, hearth pulse, and fire light")
		return false

	# Traverse past the side of a framing tree. The path crosses from the camera-
	# near side to the camera-far side while remaining clear of the trunk, making
	# each frame useful for checking sprite depth/occlusion without bypassing the
	# real CharacterBody3D movement code.
	var tree_base := Vector3(proof_tree.global_position.x, 0.0, proof_tree.global_position.z)
	var hearth_base := Vector3(proof_fire.global_position.x, 0.0, proof_fire.global_position.z)
	var focus := tree_base.lerp(hearth_base, 0.35)
	var camera_near := Vector3(CAMERA_OFFSET.x, 0.0, CAMERA_OFFSET.z).normalized()
	var camera_side := Vector3(-camera_near.z, 0.0, camera_near.x)
	var start_position := tree_base + camera_near * 2.2 + camera_side * 2.2 + Vector3.UP
	var target_position := tree_base - camera_near * 2.2 + camera_side * 2.2 + Vector3.UP
	var travel_direction := (target_position - start_position).normalized()
	player.global_position = start_position
	player.velocity = Vector3.ZERO
	player.set("last_direction", travel_direction)
	_set_camera_focus(focus)
	await _wait_frames(STATE_SETTLE_FRAMES)
	paused = true
	_set_camera_focus(focus)
	await process_frame
	if not _motion_subject_is_in_capture(proof_tree, "swaying tree"):
		return false
	if not _motion_subject_is_in_capture(proof_fire, "hearth/fire"):
		return false

	var starting_player_position := player.global_position
	var initial_tree_scale := proof_tree.scale
	var initial_fire_scale := proof_fire.scale
	var initial_light_energy := proof_light.light_energy
	var max_tree_delta := 0.0
	var max_fire_delta := 0.0
	var max_light_delta := 0.0
	var baseline_player_pixels := 0
	var minimum_player_visibility_ratio := 1.0
	var previous_max_fps := Engine.max_fps
	# Capping this standalone proof makes frame-counted movement and animation
	# deltas stable on machines that otherwise render an uncapped SubViewport.
	Engine.max_fps = 60

	for sample_index in MOTION_SAMPLE_COUNT:
		if sample_index > 0:
			paused = false
			if sample_index == 1:
				player.call("set_click_move_target", target_position)
			await _wait_physics_frames(MOTION_FRAMES_PER_SAMPLE)
			paused = true
			_set_camera_focus(focus)
			await process_frame

		max_tree_delta = maxf(max_tree_delta, (proof_tree.scale - initial_tree_scale).length())
		max_fire_delta = maxf(max_fire_delta, (proof_fire.scale - initial_fire_scale).length())
		max_light_delta = maxf(max_light_delta, absf(proof_light.light_energy - initial_light_energy))

		if not _legacy_debug_geometry_is_hidden(style):
			Engine.max_fps = previous_max_fps
			return false
		var image := _current_render_image("motion sample %d" % sample_index)
		if image == null:
			Engine.max_fps = previous_max_fps
			return false
		if not _render_image_is_meaningful(image, "motion sample %d" % sample_index):
			Engine.max_fps = previous_max_fps
			return false
		var changed_pixels := await _player_rendered_pixel_count(image, player, sample_index)
		if changed_pixels < 0:
			Engine.max_fps = previous_max_fps
			return false
		var file_name := "%s%02d.png" % [MOTION_CAPTURE_PREFIX, sample_index]
		if not _save_image_capture(image, file_name):
			Engine.max_fps = previous_max_fps
			return false
		if sample_index == 0:
			baseline_player_pixels = changed_pixels
		else:
			var visibility_ratio := float(changed_pixels) / float(baseline_player_pixels)
			minimum_player_visibility_ratio = minf(minimum_player_visibility_ratio, visibility_ratio)
			if visibility_ratio < MIN_PLAYER_VISIBILITY_RATIO:
				Engine.max_fps = previous_max_fps
				_abort(
					"Player became mostly occluded in motion sample %d: %.3f of baseline rendered pixels (minimum %.3f)"
					% [sample_index, visibility_ratio, MIN_PLAYER_VISIBILITY_RATIO]
				)
				return false
		print(
			"SANCTUARY_MOTION_SAMPLE_PASS index=", sample_index,
			" player=", player.global_position,
			" rendered_player_pixels=", changed_pixels,
			" legacy_debug=hidden"
		)

	Engine.max_fps = previous_max_fps
	if player.has_method("cancel_navigation"):
		player.call("cancel_navigation", true)
	var traversal_distance := player.global_position.distance_to(starting_player_position)
	if traversal_distance < MIN_TRAVERSAL_DISTANCE:
		_abort("Motion proof traversal moved only %.3f m; expected at least %.3f m" % [traversal_distance, MIN_TRAVERSAL_DISTANCE])
		return false
	if max_tree_delta < MIN_TREE_SWAY_DELTA:
		_abort("Illustrated tree did not visibly sway: scale delta %.6f" % max_tree_delta)
		return false
	if max_fire_delta < MIN_FIRE_PULSE_DELTA:
		_abort("Illustrated hearth/fire did not pulse: scale delta %.6f" % max_fire_delta)
		return false
	if max_light_delta < MIN_LIGHT_FLICKER_DELTA:
		_abort("Illustrated fire light did not flicker: energy delta %.6f" % max_light_delta)
		return false

	print(
		"SANCTUARY_MOTION_CHECK_PASS samples=", MOTION_SAMPLE_COUNT,
		" traversal_m=", snappedf(traversal_distance, 0.001),
		" tree_sway_delta=", snappedf(max_tree_delta, 0.000001),
		" fire_pulse_delta=", snappedf(max_fire_delta, 0.000001),
		" light_flicker_delta=", snappedf(max_light_delta, 0.000001),
		" min_player_visibility_ratio=", snappedf(minimum_player_visibility_ratio, 0.001),
		" player_rendered=all_samples legacy_debug=hidden"
	)
	return true

func _capture_player_authored_layout(layout_id: String, file_name: String, layout: Array) -> Dictionary:
	await _begin_state()
	var session := world.get("session") as Node
	var player := world.get("player") as CharacterBody3D
	if session == null or player == null:
		_abort("Session or player disappeared before player-authored layout %s" % layout_id)
		return {}
	if layout.size() < 3:
		_abort("Player-authored layout %s must contain at least three structures" % layout_id)
		return {}

	world.set("placement_mode", false)
	world.call("_update_structure_preview")
	_clear_structure_visuals()
	# Let queued visuals from the previous proof leave the tree before Main
	# creates deterministic instance names for this layout.
	await _wait_frames(1)
	_reset_layout_session_baseline(session, layout)

	var placed_instance_ids: Array[String] = []
	for spec_value in layout:
		if not (spec_value is Dictionary):
			_abort("Player-authored layout %s contains a non-dictionary placement" % layout_id)
			return {}
		var spec: Dictionary = spec_value
		var kind := str(spec.get("kind", ""))
		var cell: Vector2i = spec.get("cell", Vector2i(9999, 9999))
		var rotation := posmod(int(spec.get("rotation", 0)), 4)
		if kind.is_empty() or not ContentRegistry.STRUCTURES.has(kind):
			_abort("Player-authored layout %s contains unknown structure kind %s" % [layout_id, kind])
			return {}
		if not bool(session.call("can_place_structure", kind, [cell.x, cell.y], rotation)):
			_abort("Authoritative grid rejected %s at %s rotation %d in layout %s" % [kind, cell, rotation, layout_id])
			return {}

		# This is the same authoritative placement transaction used by Main. The
		# scratch session—not the capture harness—owns occupancy and instance IDs.
		var placed: Dictionary = session.call("place_structure", kind, [cell.x, cell.y], rotation)
		if placed.is_empty():
			_abort("Authoritative placement returned no %s at %s in layout %s" % [kind, cell, layout_id])
			return {}
		var instance_id := str(placed.get("id", ""))
		if instance_id.is_empty():
			_abort("Authoritative placement omitted an instance ID for %s in layout %s" % [kind, layout_id])
			return {}
		var placed_cell_data: Array = placed.get("cell", [])
		if placed_cell_data.size() < 2:
			_abort("Authoritative placement omitted the grid origin for %s in layout %s" % [kind, layout_id])
			return {}
		var placed_cell := Vector2i(int(placed_cell_data[0]), int(placed_cell_data[1]))
		if str(placed.get("kind", "")) != kind or placed_cell != cell or int(placed.get("rotation", -1)) != rotation:
			_abort("Authoritative placement changed the requested transform for %s in layout %s" % [kind, layout_id])
			return {}
		placed_instance_ids.append(instance_id)

		# Deliver through GameSession as a player would. This proves that every
		# operational building grew from a valid, occupied blueprint rather than
		# being injected directly into the presentation layer.
		var definition: Dictionary = ContentRegistry.structure_definition(kind)
		var cost: Dictionary = definition.get("cost", {})
		for material_value in cost:
			var material_id := str(material_value)
			var delivered: Dictionary = session.call(
				"deliver_structure_material",
				instance_id,
				material_id,
				int(cost.get(material_value, 0))
			)
			if delivered.is_empty():
				_abort("Authoritative delivery failed for %s on %s in layout %s" % [material_id, instance_id, layout_id])
				return {}
		var after_delivery: Dictionary = session.get("structures").get(instance_id, {})
		if str(after_delivery.get("state", "")) != "building":
			_abort("Fully supplied %s did not enter building state in layout %s" % [instance_id, layout_id])
			return {}

	# Three normal day transactions complete the longest current structure (the
	# 36-hour Workshop) while preserving the game's construction state machine.
	for target_day in [2, 3, 4]:
		if not bool(session.call("advance_day", target_day)):
			_abort("Authoritative day transaction %d failed in layout %s" % [target_day, layout_id])
			return {}

	var structures: Dictionary = session.get("structures")
	if structures.size() != layout.size():
		_abort("Layout %s retained %d authoritative structures; expected %d" % [layout_id, structures.size(), layout.size()])
		return {}
	for instance_id in placed_instance_ids:
		var structure: Dictionary = structures.get(instance_id, {})
		if str(structure.get("state", "")) != "operational" or float(structure.get("remaining_hours", -1.0)) != 0.0:
			_abort("Authoritative construction did not finish %s in layout %s" % [instance_id, layout_id])
			return {}
		world.call("_spawn_structure_visual", instance_id, structure)

	# Construction progression advances the scratch calendar. Restore only the
	# authored capture lighting; structure state and occupancy remain untouched.
	session.set("day", 1)
	session.set("hour", 10.0)
	session.set("season", "Verdant")
	session.set("weather", "clear")
	if world.has_method("_update_lighting"):
		world.call("_update_lighting")
	if player.has_method("cancel_navigation"):
		player.call("cancel_navigation", true)
	player.velocity = Vector3.ZERO
	player.set("last_direction", Vector3(0.0, 0.0, -1.0))

	var occupied_result := _authoritative_occupied_cells(structures, layout_id)
	if occupied_result.is_empty():
		return {}
	var occupied_cells: Array[String] = occupied_result.get("cells", [])
	var focus: Vector3 = occupied_result.get("focus", Vector3.ZERO)
	# A proof of a user-authored layout must show the full spatial claim, not
	# crop an edge building because the play camera is intentionally tighter for
	# moment-to-moment traversal. The runtime camera contract remains 14.5; this
	# evidence-only framing is a deliberate whole-layout inspection mode.
	var camera := world.get("camera") as Camera3D
	var previous_camera_size := camera.size if camera != null else 14.5
	if camera != null:
		camera.size = 20.0
	player.global_position = _layout_player_position(focus, occupied_cells)
	_set_camera_focus(focus)
	await _settle_and_pause()
	_set_camera_focus(focus)
	await process_frame
	if not _layout_visuals_are_visible(placed_instance_ids, layout_id):
		return {}
	var image := _current_render_image("player-authored layout %s" % layout_id)
	if image == null or not _render_image_is_meaningful(image, "player-authored layout %s" % layout_id):
		return {}
	if not _save_image_capture(image, file_name):
		if camera != null:
			camera.size = previous_camera_size
		return {}
	if camera != null:
		camera.size = previous_camera_size

	var signature := _authoritative_layout_signature(structures)
	print(
		"SANCTUARY_PLAYER_LAYOUT_PASS id=", layout_id,
		" file=", output_directory.path_join(file_name),
		" structures=", structures.size(),
		" occupied_cells=", occupied_cells.size(),
		" signature=", signature,
		" path=GameSession.can_place_structure/place_structure/deliver_structure_material/advance_day"
	)
	return {
		"id": layout_id,
		"file_name": file_name,
		"image": image,
		"signature": signature,
		"occupied_cells": occupied_cells.duplicate(),
		"structure_count": structures.size(),
	}

func _reset_layout_session_baseline(session: Node, layout: Array) -> void:
	session.set("day", 1)
	session.set("hour", 10.0)
	session.set("season", "Verdant")
	session.set("weather", "clear")
	session.set("last_day_transaction", 0)
	var built: Dictionary = session.get("built")
	for built_kind in built:
		built[built_kind] = false
	var inventory: Dictionary = session.get("inventory")
	var blueprints: Array = session.get("blueprints")
	blueprints.clear()
	for spec_value in layout:
		if not (spec_value is Dictionary):
			continue
		var kind := str(spec_value.get("kind", ""))
		var definition: Dictionary = ContentRegistry.structure_definition(kind)
		var requirement := str(definition.get("requires_blueprint", ""))
		if not requirement.is_empty() and not blueprints.has(requirement):
			blueprints.append(requirement)
		var cost: Dictionary = definition.get("cost", {})
		for material_value in cost:
			inventory[str(material_value)] = maxi(int(inventory.get(str(material_value), 0)), int(cost.get(material_value, 0)) * layout.size())
	session.set("blueprints", blueprints)

func _authoritative_occupied_cells(structures: Dictionary, layout_id: String) -> Dictionary:
	var occupied_lookup := {}
	var minimum_x := SettlementGrid.MAX_X + 1
	var maximum_x := SettlementGrid.MIN_X - 1
	var minimum_z := SettlementGrid.MAX_Z + 1
	var maximum_z := SettlementGrid.MIN_Z - 1
	for instance_id in structures:
		var structure: Dictionary = structures.get(instance_id, {})
		var kind := str(structure.get("kind", ""))
		var cell_data: Array = structure.get("cell", [])
		if cell_data.size() < 2:
			_abort("Authoritative structure %s has no grid origin in layout %s" % [instance_id, layout_id])
			return {}
		var origin := Vector2i(int(cell_data[0]), int(cell_data[1]))
		var footprint_data: Array = ContentRegistry.structure_definition(kind).get("footprint", [1, 1])
		var footprint := Vector2i(int(footprint_data[0]), int(footprint_data[1]))
		if posmod(int(structure.get("rotation", 0)), 4) % 2 == 1:
			footprint = Vector2i(footprint.y, footprint.x)
		var cells := SettlementGrid.cells_for(origin, footprint)
		if not SettlementGrid.inside_bounds(cells):
			_abort("Authoritative structure %s escaped grid bounds in layout %s" % [instance_id, layout_id])
			return {}
		for cell in cells:
			var key := "%d,%d" % [cell.x, cell.y]
			if occupied_lookup.has(key):
				_abort("Authoritative occupancy overlaps at %s in layout %s" % [key, layout_id])
				return {}
			occupied_lookup[key] = true
			minimum_x = mini(minimum_x, cell.x)
			maximum_x = maxi(maximum_x, cell.x)
			minimum_z = mini(minimum_z, cell.y)
			maximum_z = maxi(maximum_z, cell.y)
	var occupied_cells: Array[String] = []
	for key in occupied_lookup:
		occupied_cells.append(str(key))
	occupied_cells.sort()
	return {
		"cells": occupied_cells,
		"focus": Vector3((float(minimum_x) + float(maximum_x)) * 0.5, 0.0, (float(minimum_z) + float(maximum_z)) * 0.5),
	}

func _layout_player_position(focus: Vector3, occupied_cells: Array[String]) -> Vector3:
	# Pick the closest unoccupied grid cell to the layout focus so the avatar
	# remains a trustworthy scale reference without standing inside a building.
	var occupied_lookup := {}
	for key in occupied_cells:
		occupied_lookup[key] = true
	var focus_cell: Vector2i = SettlementGrid.world_to_cell(focus)
	for radius in range(1, 9):
		var candidate_offsets: Array[Vector2i] = [Vector2i(-radius, radius), Vector2i(0, radius), Vector2i(radius, radius), Vector2i(-radius, 0), Vector2i(radius, 0), Vector2i(-radius, -radius), Vector2i(0, -radius), Vector2i(radius, -radius)]
		for offset in candidate_offsets:
			var candidate: Vector2i = focus_cell + offset
			var key := "%d,%d" % [candidate.x, candidate.y]
			if candidate.x < SettlementGrid.MIN_X or candidate.x > SettlementGrid.MAX_X or candidate.y < SettlementGrid.MIN_Z or candidate.y > SettlementGrid.MAX_Z:
				continue
			if not occupied_lookup.has(key):
				return SettlementGrid.cell_to_world(candidate, 1.0)
	# This should be unreachable for the sparse proof layouts, but returning far
	# outside the frame would make the subsequent visibility checks fail closed.
	return SettlementGrid.cell_to_world(focus_cell, 1.0)

func _layout_visuals_are_visible(instance_ids: Array[String], layout_id: String) -> bool:
	var camera := world.get("camera") as Camera3D
	var visuals: Dictionary = world.get("settlement_visuals")
	if camera == null or visuals.size() != instance_ids.size():
		_abort("Layout %s has %d runtime visuals for %d authoritative structures" % [layout_id, visuals.size(), instance_ids.size()])
		return false
	for instance_id in instance_ids:
		var visual := visuals.get(instance_id) as Node3D
		if visual == null or not is_instance_valid(visual) or not visual.is_visible_in_tree():
			_abort("Layout %s did not render authoritative structure %s" % [layout_id, instance_id])
			return false
		var render_point := visual.global_position + Vector3(0.0, 1.0, 0.0)
		if camera.is_position_behind(render_point):
			_abort("Layout %s placed %s behind the capture camera" % [layout_id, instance_id])
			return false
		var projected := camera.unproject_position(render_point)
		if projected.x < 24.0 or projected.y < 24.0 or projected.x >= CAPTURE_SIZE.x - 24.0 or projected.y >= CAPTURE_SIZE.y - 24.0:
			_abort("Layout %s projected %s outside the safe capture frame at %s" % [layout_id, instance_id, projected])
			return false
	return true

func _authoritative_layout_signature(structures: Dictionary) -> String:
	var entries: Array[String] = []
	for instance_id in structures:
		var structure: Dictionary = structures.get(instance_id, {})
		var cell_data: Array = structure.get("cell", [9999, 9999])
		entries.append(
			"%s@%d,%d:r%d:%s"
			% [
				str(structure.get("kind", "")),
				int(cell_data[0]),
				int(cell_data[1]),
				posmod(int(structure.get("rotation", 0)), 4),
				str(structure.get("state", "")),
			]
		)
	entries.sort()
	return "|".join(entries)

func _validate_player_layout_difference(first: Dictionary, second: Dictionary) -> bool:
	var first_signature := str(first.get("signature", ""))
	var second_signature := str(second.get("signature", ""))
	if first_signature.is_empty() or second_signature.is_empty() or first_signature == second_signature:
		_abort("Player-authored layout signatures are missing or identical")
		return false
	var first_cells: Array = first.get("occupied_cells", [])
	var second_cells: Array = second.get("occupied_cells", [])
	var first_lookup := {}
	var second_lookup := {}
	for key in first_cells:
		first_lookup[str(key)] = true
	for key in second_cells:
		second_lookup[str(key)] = true
	var symmetric_cell_difference := 0
	for key in first_lookup:
		if not second_lookup.has(key):
			symmetric_cell_difference += 1
	for key in second_lookup:
		if not first_lookup.has(key):
			symmetric_cell_difference += 1
	if symmetric_cell_difference < MIN_LAYOUT_OCCUPIED_CELL_DIFFERENCE:
		_abort(
			"Player-authored layouts differ by only %d occupied cells; expected at least %d"
			% [symmetric_cell_difference, MIN_LAYOUT_OCCUPIED_CELL_DIFFERENCE]
		)
		return false

	var first_image := first.get("image") as Image
	var second_image := second.get("image") as Image
	if first_image == null or second_image == null or first_image.get_size() != second_image.get_size():
		_abort("Player-authored layout images are missing or use different dimensions")
		return false
	var changed_samples := 0
	var sampled_pixels := 0
	var accumulated_delta := 0.0
	for y in range(0, first_image.get_height(), LAYOUT_PIXEL_SAMPLE_STEP):
		for x in range(0, first_image.get_width(), LAYOUT_PIXEL_SAMPLE_STEP):
			var first_color := first_image.get_pixel(x, y)
			var second_color := second_image.get_pixel(x, y)
			var color_delta := (
				absf(first_color.r - second_color.r)
				+ absf(first_color.g - second_color.g)
				+ absf(first_color.b - second_color.b)
			) / 3.0
			accumulated_delta += color_delta
			sampled_pixels += 1
			if color_delta >= 0.06:
				changed_samples += 1
	var changed_ratio := float(changed_samples) / float(maxi(1, sampled_pixels))
	var mean_color_delta := accumulated_delta / float(maxi(1, sampled_pixels))
	if changed_ratio < MIN_LAYOUT_CHANGED_SAMPLE_RATIO or mean_color_delta < MIN_LAYOUT_MEAN_COLOR_DELTA:
		_abort(
			"Player-authored layout renders are insufficiently distinct: changed_ratio=%.4f mean_delta=%.4f"
			% [changed_ratio, mean_color_delta]
		)
		return false
	print(
		"SANCTUARY_PLAYER_LAYOUT_DIFFERENCE_PASS first=", str(first.get("file_name", "")),
		" second=", str(second.get("file_name", "")),
		" occupied_cell_symmetric_difference=", symmetric_cell_difference,
		" changed_samples=", changed_samples, "/", sampled_pixels,
		" changed_ratio=", snappedf(changed_ratio, 0.0001),
		" mean_color_delta=", snappedf(mean_color_delta, 0.0001)
	)
	return true

func _find_motion_proof_tree(style: Node3D) -> Node3D:
	var entries: Array = style.get("swaying_nodes")
	var closest: Node3D
	var closest_distance := INF
	for entry_value in entries:
		var entry: Dictionary = entry_value
		var node_value: Variant = entry.get("node")
		if not is_instance_valid(node_value):
			continue
		var node := node_value as Node3D
		if node == null or not node.is_visible_in_tree():
			continue
		var flat_position := Vector3(node.global_position.x, 0.0, node.global_position.z)
		var distance := flat_position.distance_to(MOTION_TREE_TARGET)
		if distance < closest_distance:
			closest = node
			closest_distance = distance
	return closest

func _find_motion_proof_fire(style: Node3D) -> Node3D:
	var entries: Array = style.get("pulsing_nodes")
	for entry_value in entries:
		var entry: Dictionary = entry_value
		var node_value: Variant = entry.get("node")
		if not is_instance_valid(node_value):
			continue
		var node := node_value as Node3D
		if node != null and str(node.name) == "HearthWellAndFire" and node.is_visible_in_tree():
			return node
	return null

func _find_motion_proof_light(style: Node3D) -> OmniLight3D:
	var entries: Array = style.get("fire_lights")
	for entry_value in entries:
		var entry: Dictionary = entry_value
		var node_value: Variant = entry.get("node")
		if is_instance_valid(node_value) and node_value is OmniLight3D:
			var light := node_value as OmniLight3D
			if light != null and light.is_visible_in_tree():
				return light
	return null

func _motion_subject_is_in_capture(subject: Node3D, label: String) -> bool:
	var camera := world.get("camera") as Camera3D
	if camera == null or subject == null or not subject.is_visible_in_tree():
		_abort("Motion subject is not scene-visible: %s" % label)
		return false
	if camera.is_position_behind(subject.global_position):
		_abort("Motion subject is behind the proof camera: %s" % label)
		return false
	var projected := camera.unproject_position(subject.global_position)
	if projected.x < 0.0 or projected.y < 0.0 or projected.x >= CAPTURE_SIZE.x or projected.y >= CAPTURE_SIZE.y:
		_abort("Motion subject projected outside the proof frame: %s at %s" % [label, projected])
		return false
	return true

func _legacy_debug_geometry_is_hidden(style: Node3D) -> bool:
	var source_district := style.get("source_district") as Node3D
	if source_district != null and source_district.is_visible_in_tree():
		_abort("Legacy sourced Sanctuary district became visible during traversal")
		return false

	var legacy_roots: Array = [
		["Furnace", world.get("furnace")],
		["FarmPlot", world.get("farm_plot")],
		["Workshop", world.get("workshop")],
		["LibraryStation", world.get("library_station")],
		["NoticeBoard", world.get("notice_board")],
		["FishingSpot", world.get("fishing_spot")],
		["TradeStall", world.get("trade_stall")],
		["LivestockPen", world.get("livestock_pen")],
		["BuildMarker", world.get("build_marker")],
	]
	var sanctuary_zone := world.get("sanctuary_zone") as Node3D
	if sanctuary_zone != null:
		for legacy_name in ["Hearth", "Wanderer'sBazaar", "Archive", "Pond"]:
			legacy_roots.append([legacy_name, sanctuary_zone.get_node_or_null(legacy_name)])

	for root_data in legacy_roots:
		var legacy_root := root_data[1] as Node
		if legacy_root == null:
			continue
		var visible_paths: Array[String] = []
		_collect_visible_render_paths(legacy_root, visible_paths)
		if not visible_paths.is_empty():
			_abort("Legacy/debug render geometry visible in %s: %s" % [str(root_data[0]), ", ".join(visible_paths.slice(0, 4))])
			return false

	# Fail closed for newly introduced Sanctuary roots as well as the named
	# legacy roots above. Ground collision/presentation and the living paddock
	# resident are explicit exceptions; resources are checked separately below.
	if sanctuary_zone != null:
		for child in sanctuary_zone.get_children():
			if child == style or str(child.name) in ["SanctuaryGround", "CloverLivestockPen", "MiraWayfarer"] or child.is_in_group("resource_node"):
				continue
			var visible_paths: Array[String] = []
			_collect_visible_render_paths(child, visible_paths)
			if not visible_paths.is_empty():
				_abort("Unexpected legacy/debug Sanctuary render root became visible: %s" % ", ".join(visible_paths.slice(0, 4)))
				return false

	# Resource trees keep their interaction bodies, but only the generated
	# IllustratedResourceTree may render. This catches old low-poly meshes being
	# restored by harvesting or save-state refresh during the traversal proof.
	var resource_roots: Array = style.get("resource_visual_roots")
	for resource_value in resource_roots:
		var resource_root := resource_value as Node
		if resource_root == null:
			continue
		for child in resource_root.get_children():
			if str(child.name) == "IllustratedResourceTree":
				continue
			var visible_paths: Array[String] = []
			_collect_visible_render_paths(child, visible_paths)
			if not visible_paths.is_empty():
				_abort("Legacy resource-tree geometry became visible: %s" % ", ".join(visible_paths.slice(0, 4)))
				return false
	return true

func _collect_visible_render_paths(node: Node, output: Array[String]) -> void:
	if node == null:
		return
	if (node is GeometryInstance3D or node is Label3D or node is GPUParticles3D or node is CPUParticles3D) and node.is_visible_in_tree():
		output.append(str(node.get_path()))
	for child in node.get_children():
		_collect_visible_render_paths(child, output)

func _current_render_image(label: String) -> Image:
	if capture_viewport == null:
		_abort("Capture viewport disappeared before %s" % label)
		return null
	var texture := capture_viewport.get_texture()
	if texture == null:
		_unavailable("viewport texture became unavailable during %s" % label)
		return null
	var image := texture.get_image()
	if image == null or image.is_empty():
		_unavailable("renderer returned an empty image during %s" % label)
		return null
	return image

func _render_image_is_meaningful(image: Image, label: String) -> bool:
	if image.get_width() != CAPTURE_SIZE.x or image.get_height() != CAPTURE_SIZE.y:
		_abort("%s rendered at %dx%d instead of %dx%d" % [label, image.get_width(), image.get_height(), CAPTURE_SIZE.x, CAPTURE_SIZE.y])
		return false
	var minimum_luminance := 1.0
	var maximum_luminance := 0.0
	var opaque_samples := 0
	var color_buckets := {}
	for y in range(16, image.get_height(), 48):
		for x in range(16, image.get_width(), 48):
			var color := image.get_pixel(x, y)
			if color.a < 0.95:
				continue
			opaque_samples += 1
			var luminance := color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
			minimum_luminance = minf(minimum_luminance, luminance)
			maximum_luminance = maxf(maximum_luminance, luminance)
			var bucket := "%d:%d:%d" % [int(color.r * 7.0), int(color.g * 7.0), int(color.b * 7.0)]
			color_buckets[bucket] = true
	if opaque_samples < 100 or color_buckets.size() < 12 or maximum_luminance - minimum_luminance < 0.12:
		_abort(
			"%s is blank/degenerate: opaque=%d colors=%d luminance_range=%.4f"
			% [label, opaque_samples, color_buckets.size(), maximum_luminance - minimum_luminance]
		)
		return false
	return true

func _player_rendered_pixel_count(visible_image: Image, player: CharacterBody3D, sample_index: int) -> int:
	var camera := world.get("camera") as Camera3D
	var visual := player.get_node_or_null("Visual") as Node3D
	if camera == null or visual == null or not visual.is_visible_in_tree():
		_abort("Player visual or camera is unavailable in motion sample %d" % sample_index)
		return -1
	var visible_mesh_count := 0
	for render_value in visual.find_children("*", "GeometryInstance3D", true, false):
		var render_instance := render_value as GeometryInstance3D
		if render_instance != null and render_instance.is_visible_in_tree():
			visible_mesh_count += 1
	if visible_mesh_count == 0:
		_abort("Player has no visible render meshes in motion sample %d" % sample_index)
		return -1

	var player_render_point := player.global_position + Vector3(0.0, 1.2, 0.0)
	if camera.is_position_behind(player_render_point):
		_abort("Player moved behind the camera in motion sample %d" % sample_index)
		return -1
	var projected := camera.unproject_position(player_render_point)
	if projected.x < 0.0 or projected.y < 0.0 or projected.x >= CAPTURE_SIZE.x or projected.y >= CAPTURE_SIZE.y:
		_abort("Player projected outside the capture in motion sample %d: %s" % [sample_index, projected])
		return -1

	# Render the exact same paused frame once with the player hidden. A pixel
	# difference proves the avatar is present in the actual image, not merely
	# enabled in the scene tree or nominally inside the camera frustum.
	visual.visible = false
	# The Sanctuary now carries a real sun plus bounded lantern shadows. Give the
	# display-backed SubViewport two render frames to retire the previous shadow
	# map before sampling the hidden comparison; a single process frame can still
	# return the old shadowed image on Metal.
	await _wait_frames(2)
	var hidden_image := _current_render_image("hidden-player comparison %d" % sample_index)
	visual.visible = true
	await _wait_frames(2)
	if hidden_image == null:
		return -1

	var half_width := 46
	var half_height := 48
	var minimum_x := maxi(0, int(projected.x) - half_width)
	var maximum_x := mini(visible_image.get_width() - 1, int(projected.x) + half_width)
	var minimum_y := maxi(0, int(projected.y) - half_height)
	var maximum_y := mini(visible_image.get_height() - 1, int(projected.y) + half_height)
	var changed_pixels := 0
	for y in range(minimum_y, maximum_y + 1, 2):
		for x in range(minimum_x, maximum_x + 1, 2):
			var visible_color := visible_image.get_pixel(x, y)
			var hidden_color := hidden_image.get_pixel(x, y)
			var color_delta := (
				absf(visible_color.r - hidden_color.r)
				+ absf(visible_color.g - hidden_color.g)
				+ absf(visible_color.b - hidden_color.b)
			)
			if color_delta >= 0.06:
				changed_pixels += 1
	if changed_pixels < MIN_PLAYER_CHANGED_PIXELS:
		_abort(
			"Player is scene-visible but not sufficiently rendered in motion sample %d: %d changed pixels"
			% [sample_index, changed_pixels]
		)
		return -1
	return changed_pixels

func _save_image_capture(image: Image, file_name: String) -> bool:
	var output_path := output_directory.path_join(file_name)
	var result := image.save_png(output_path)
	if result != OK:
		_abort("Could not write %s: error %d" % [output_path, result])
		return false
	print("SANCTUARY_STAGE_CAPTURE_PASS ", output_path, " ", image.get_width(), "x", image.get_height())
	return true

func _begin_state() -> void:
	paused = false
	await _wait_frames(1)

func _settle_and_pause() -> void:
	await _wait_frames(STATE_SETTLE_FRAMES)
	paused = true
	# One extra frame lets the SubViewport receive the final paused transform and
	# ensures queue_free changes from the previous stage are no longer visible.
	await process_frame

func _clear_structure_visuals() -> void:
	if world == null:
		return
	var visuals: Dictionary = world.get("settlement_visuals")
	for instance_id in visuals.keys():
		var visual := visuals.get(instance_id) as Node3D
		if visual != null and is_instance_valid(visual):
			visual.queue_free()
	visuals.clear()
	var session := world.get("session") as Node
	if session != null:
		var structures: Dictionary = session.get("structures")
		structures.clear()

func _find_valid_stage_origin(session: Node) -> Vector2i:
	# Prefer the open central build field so the camera can show the player and
	# the full footprint at the same 1-unit-per-metre scale. Fall back to the
	# complete authoritative bounds rather than guessing around fixed landmarks.
	for candidate in [Vector2i(2, 0), Vector2i(2, 3), Vector2i(3, -1), Vector2i(-4, 0), Vector2i(4, -1)]:
		if bool(session.call("can_place_structure", STAGE_KIND, [candidate.x, candidate.y], 0)):
			return candidate
	for z in range(SettlementGrid.MIN_Z, SettlementGrid.MAX_Z + 1):
		for x in range(SettlementGrid.MIN_X, SettlementGrid.MAX_X + 1):
			var candidate := Vector2i(x, z)
			if bool(session.call("can_place_structure", STAGE_KIND, [x, z], 0)):
				return candidate
	return Vector2i(9999, 9999)

func _set_camera_focus(focus: Vector3) -> void:
	var camera := world.get("camera") as Camera3D
	if camera == null:
		return
	world.set("camera_anchor", focus)
	world.set("camera_anchor_initialized", true)
	camera.global_position = focus + CAMERA_OFFSET
	camera.look_at(focus + CAMERA_LOOK_OFFSET, Vector3.UP)

func _set_hud_visible(visible: bool) -> void:
	var hud := world.get("hud_root") as Control
	if hud != null:
		hud.visible = visible

func _save_capture(file_name: String) -> bool:
	if capture_viewport == null:
		_abort("Capture viewport disappeared before %s" % file_name)
		return false
	var texture := capture_viewport.get_texture()
	if texture == null:
		_unavailable("viewport texture became unavailable while writing %s" % file_name)
		return false
	var image := texture.get_image()
	if image == null or image.is_empty():
		_unavailable("renderer returned an empty image while writing %s" % file_name)
		return false
	var output_path := output_directory.path_join(file_name)
	var result := image.save_png(output_path)
	if result != OK:
		_abort("Could not write %s: error %d" % [output_path, result])
		return false
	print("SANCTUARY_STAGE_CAPTURE_PASS ", output_path, " ", image.get_width(), "x", image.get_height())
	return true

func _wait_frames(frame_count: int) -> void:
	for _frame in frame_count:
		await process_frame

func _wait_physics_frames(frame_count: int) -> void:
	for _frame in frame_count:
		await physics_frame
	await process_frame

func _resolve_output_directory() -> String:
	var configured := OS.get_environment("SANCTUARY_STAGE_CAPTURE_DIR")
	if configured.is_empty():
		configured = "user://sanctuary-stage-captures"
		print("SANCTUARY_STAGE_CAPTURE_ASSUMPTION default output directory: ", configured)
	return ProjectSettings.globalize_path(configured)

func _ensure_output_directory() -> bool:
	return DirAccess.make_dir_recursive_absolute(output_directory) == OK or DirAccess.dir_exists_absolute(output_directory)

func _display_is_headless() -> bool:
	return DisplayServer.get_name().to_lower() == "headless"

func _unavailable(reason: String) -> void:
	# Keep the existing capture harness contract so CI and local tooling treat
	# headless/dummy rendering as an expected unavailable result.
	print("SANCTUARY_CAPTURE_UNAVAILABLE: ", reason)
	paused = false
	quit()

func _abort(reason: String) -> void:
	print("SANCTUARY_STAGE_CAPTURE_FAIL: ", reason)
	paused = false
	quit(1)
