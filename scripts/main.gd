extends Node3D

const ResourceNodeScript = preload("res://scripts/resource_node.gd")
const GuardianScript = preload("res://scripts/guardian.gd")
const PlayerScript = preload("res://scripts/player.gd")
const AudioDirectorScript = preload("res://scripts/audio_director.gd")
const JoystickScript = preload("res://scripts/virtual_joystick.gd")
const RecoveryPackScript = preload("res://scripts/recovery_pack.gd")
const ResourcePickupScript = preload("res://scripts/resource_pickup.gd")
const SessionScript = preload("res://scripts/game_session.gd")
const SanctuaryDistrictScript = preload("res://scripts/sanctuary_district.gd")
const FarmPlotScript = preload("res://scripts/farm_plot.gd")
const StationScript = preload("res://scripts/crafting_station.gd")
const VillagerScript = preload("res://scripts/villager.gd")
const LivestockAnimalScript = preload("res://scripts/livestock_animal.gd")
const WildlifeCreatureScript = preload("res://scripts/wildlife_creature.gd")
const ContentRegistry = preload("res://scripts/content_registry.gd")
const SettlementGrid = preload("res://scripts/settlement_grid.gd")
const SanctuaryStyleScript = preload("res://scripts/sanctuary_style.gd")
const SanctuaryAssetCatalog = preload("res://scripts/sanctuary_asset_catalog.gd")
const SanctuaryAssetMeasurement = preload("res://scripts/sanctuary_asset_measurement.gd")
const BuildingInteriorScript = preload("res://scripts/building_interior.gd")
const InteriorGrid = preload("res://scripts/interior_grid.gd")
const FeedbackEventScript = preload("res://scripts/feedback_event.gd")

const SOURCED_TREE_ASSETS := {
	"Sanctuary": "res://assets/quaternius-stylized-nature/glTF/CommonTree_2.gltf",
	"Whisperwood": "res://assets/quaternius-stylized-nature/glTF/Pine_1.gltf",
	"SunlitBeach": "res://assets/quaternius-stylized-nature/glTF/CommonTree_3.gltf",
	"EmberRidge": "res://assets/quaternius-stylized-nature/glTF/DeadTree_1.gltf",
	"GlassDesert": "res://assets/quaternius-stylized-nature/glTF/DeadTree_2.gltf",
	"SunkenDungeon": "res://assets/quaternius-stylized-nature/glTF/DeadTree_3.gltf",
}
const SOURCED_ROCK_ASSET := "res://assets/quaternius-stylized-nature/glTF/Rock_Medium_1.gltf"
const SOURCED_MUSHROOM_ASSET := "res://assets/quaternius-stylized-nature/glTF/Mushroom_Common.gltf"
const KENNEY_PANEL_TEXTURE := "res://assets/sourced/kenney-ui-adventure/PNG/Default/panel_brown_dark.png"
const KENNEY_BUTTON_TEXTURE := "res://assets/sourced/kenney-ui-adventure/PNG/Default/button_brown.png"
const KENNEY_BUTTON_HOVER_TEXTURE := "res://assets/sourced/kenney-ui-adventure/PNG/Default/button_grey.png"
const SANCTUARY_PACK_ROOT := "res://assets/sourced/quaternius-medieval-village/Medieval Village Pack - Dec 2020/"
const PLAYER_SPRITE_SHEET_PATH := "res://assets/generated/sanctuary/player-direction-sheet.png"
const MIRA_SPRITE_SHEET_PATH := "res://assets/generated/sanctuary/mira-direction-sheet.png"
## The reference and LDOE-style base view need a clearly readable ground plane
## without flattening the building facades. Keep the diagonal southeast yaw but
## use a genuinely elevated 43.3° pitch; this also makes the screen-space
## joystick frame agree with the visible path directions.
const CAMERA_OFFSET := Vector3(13.5, 18.0, 13.5)
const CAMERA_LOOK_OFFSET := Vector3(0.0, 0.2, 0.0)
const SANCTUARY_CAMERA_SIZE := 14.5
const EXPEDITION_CAMERA_SIZE := 15.2
const PLAYER_ART_WORLD_HEIGHT := 2.0
const MIRA_ART_WORLD_HEIGHT := 2.02
const WORLD_HALF_EXTENTS := Vector2(30.0, 24.0)
const CAMERA_FOCUS_MARGIN := Vector2(10.5, 8.5)

var session: Node
var sanctuary_zone: Node3D
var forest_zone: Node3D
var beach_zone: Node3D
var mountain_zone: Node3D
var desert_zone: Node3D
var dungeon_zone: Node3D
var sanctuary_district: Node3D
var sanctuary_style: Node3D
var building_interior: Node3D
var interior_active := false
var interior_transitioning := false
var interior_kind := ""
var interior_instance_id := ""
var interior_return_position := Vector3.ZERO
var interior_return_facing := Vector3(0.0, 0.0, 1.0)
var interior_station_placement_mode := false
var selected_interior_station_kind := "workbench"
var interior_station_rotation := 0
var interior_station_preview_cell := Vector2i.ZERO
var interior_station_preview_valid := false
var world_zones: Array[Node3D] = []
var wildlife_nodes: Array[Node3D] = []
var player: CharacterBody3D
var camera: Camera3D
var camera_anchor := Vector3.ZERO
var camera_anchor_initialized := false
var camera_ground_forward := Vector3(-0.7071068, 0.0, -0.7071068)
var camera_ground_right := Vector3(0.7071068, 0.0, -0.7071068)
var audio_director: Node
var furnace: Node3D
var farm_plot: Node3D
var workshop: Node3D
var library_station: Node3D
var notice_board: Node3D
var guide_npc: Node3D
var fishing_spot: Node3D
var fishing_bobber: MeshInstance3D
var coastal_fishing_spot: Node3D
var coastal_fishing_bobber: MeshInstance3D
var recovery_pack_visual: Node3D
var trade_stall: Node3D
var livestock_pen: Node3D
var build_marker: Node3D
var furnace_active := false
var current_zone := "Sanctuary"
var selected_expedition := "Whisperwood"
var route_gate_unlock_signature := ""
var day := 1
var hour := 10.0
var weather := "clear"
var energy := 24
var max_energy := 24
var coins := 120
var xp := 0
var health := 100
var max_health := 100
var cargo_capacity := 12
var nutrition := 72
var hydration := 76
var selected_food := "bread"
var selected_recipe := "plank"
var strength := 1
var attack_cooldown := 0.0
var footstep_timer := 0.0
var toast_timer := 0.0
var feedback_event_sequence := 0
var last_feedback_event: Dictionary = {}
var toast_label: Label
var hud_title_label: Label
var zone_label: Label
var day_label: Label
var energy_bar: ProgressBar
var health_bar: ProgressBar
var inventory_label: Label
var status_label: Label
var weather_label: Label
var action_hint: Label
var explore_button: Button
var destination_button: Button
var return_button: Button
var interact_button: Button
var attack_button: Button
var sleep_button: Button
var pause_button: Button
var smelt_button: Button
var sanctuary_nodes: Array[Node3D] = []
var forest_nodes: Array[Node3D] = []
var sway_nodes: Array[Dictionary] = []
var sourced_model_scenes: Dictionary = {}
var recovery_loot: Dictionary = {}
var expedition_loot: Dictionary = {}
var expedition_pickup_visuals := {}
var inventory := {"wood": 0, "stone": 0, "fiber": 0, "slime_gel": 0, "ore": 0, "shell": 0}
var build_progress := 0.0
var activity_streak := 0
var suppress_activity_feedback := false
var selected_stat := "Strength"
var ui_panel: Control
var hud_root: Control
var hud_top_panel: Panel
var hud_top_box: VBoxContainer
var hud_bag_panel: Panel
var hud_quest_panel: Panel
var hud_right_panel: Panel
var hud_right_scroll: ScrollContainer
var hud_right_box: VBoxContainer
var hud_action_panel: Panel
var hud_action_scroll: ScrollContainer
var hud_action_box: VBoxContainer
var hud_joystick: Control
var reference_hud: Control
var reference_top_panel: Panel
var reference_portrait: TextureRect
var reference_name_label: Label
var reference_level_label: Label
var reference_health_bar: ProgressBar
var reference_energy_bar: ProgressBar
var reference_zone_label: Label
var reference_objective_label: Label
var reference_stat_box: VBoxContainer
var reference_stat_labels: Dictionary = {}
var reference_bottom_panel: Panel
var reference_slot_box: HBoxContainer
var reference_context_button: Button
var reference_cargo_bar: ProgressBar
var reference_cargo_label: Label
var reference_cargo_text: Label
var reference_quick_labels: Dictionary = {}
var reference_top_buttons: Array[Button] = []
var reference_slots: Array[Button] = []
var hud_safe_rect := Rect2()
var hud_layout_signature := ""
var mastery_label: Label
var quest_label: Label
var save_button: Button
var activity_button: Button
var build_button: Button
var farm_button: Button
var food_button: Button
var water_button: Button
var livestock_button: Button
var repair_button: Button
var structure_button: Button
var blueprint_button: Button
var rotate_button: Button
var stat_button: Button
var stat_cycle_button: Button
var recipe_button: Button
var dodge_button: Button
var utilities_button: Button
var settings_button: Button
var settings_panel: Panel
var settings_sliders: Dictionary = {}
var settings_value_labels: Dictionary = {}
var screen_shake_toggle: CheckButton
var haptics_toggle: CheckButton
var utilities_open := false
var settings_open := false
var screen_shake_enabled := true
var haptics_enabled := true
var focus_paused := false
var last_autosave := 0.0
var autosave_failed := false
var autosave_failure_notified := false
var save_replacement_armed := false
var camera_shake := 0.0
var last_farm_signature := ""
var interaction_marker: MeshInstance3D
var move_target_marker: MeshInstance3D
var sun_light: DirectionalLight3D
var hearth_fill: OmniLight3D
var animated_water: Array[MeshInstance3D] = []
var animated_beacons: Array[MeshInstance3D] = []
var hazard_timer := 0.0
var hazard_shelter_active := false
var anchor_timer := 0.0
var resource_action_node: Node = null
var resource_action_elapsed := 0.0
var resource_action_duration := 0.58
var resource_contact_node: Node = null
var resource_contact_elapsed := 0.0
var pending_attack_target: Node = null
var attack_action_elapsed := 0.0
var attack_action_phase := "idle"
var player_attack_shape: SphereShape3D
var attack_combo_count := 0
var attack_combo_timer := 0.0
const ATTACK_COMBO_WINDOW := 1.15
const PLAYER_ATTACK_ACTIVE_SECONDS := 0.10
const PLAYER_ATTACK_RECOVERY_SECONDS := 0.22
var placement_mode := false
var placement_structure_id := "rain_cistern"
var placement_rotation_quarter_turns := 0
var settlement_visuals := {}

var palette := {
	"ink": Color("#18282b"),
	"panel": Color(0.055, 0.10, 0.105, 0.94),
	"panel_light": Color(0.12, 0.20, 0.18, 0.94),
	"cream": Color("#fff4d4"),
	"muted": Color("#b8c6b0"),
	"leaf": Color("#78a66a"),
	"leaf_dark": Color("#3e654e"),
	"grass": Color("#587d5b"),
	"grass_dark": Color("#345b4c"),
	"sand": Color("#b58a5f"),
	"wood": Color("#9b6e4e"),
	"wood_dark": Color("#573e32"),
	"stone": Color("#766f63"),
	"water": Color("#3f8993"),
	"violet": Color("#8d79b5"),
	"ember": Color("#ef8b4d"),
	"danger": Color("#d86b6b"),
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	session = SessionScript.new()
	session.name = "GameSession"
	var configured_save_slot := str(ProjectSettings.get_setting("prodewty/save_slot", ""))
	if configured_save_slot.is_empty():
		configured_save_slot = OS.get_environment("PRODEWTY_SAVE_SLOT")
	if not configured_save_slot.is_empty():
		session.save_slot = configured_save_slot
	add_child(session)
	_ensure_input_actions()
	_copy_session_to_runtime()
	session.state_changed.connect(_on_session_changed)
	session.feedback_requested.connect(_on_session_feedback)
	_build_lighting()
	_build_world()
	_build_building_interior()
	_build_player()
	_build_audio()
	_apply_player_settings()
	_build_hud()
	var load_state := str(session.get("load_status")) if session != null else "fresh"
	if load_state == "rejected":
		_show_toast("Save not loaded safely. Autosave is paused; open the Ledger and press Replace Save twice only if you accept a new checkpoint.", 6.0)
	elif load_state == "future":
		_show_toast("A newer save belongs to another build. This session is read-only until that build is available.", 6.0)
	elif load_state == "recovered":
		_show_toast("Recovered the last safe checkpoint from backup. Save Progress when you are ready to continue.", 4.5)
	var starting_zone := "Sanctuary"
	if session != null and session.has_method("has_active_expedition") and session.call("has_active_expedition"):
		starting_zone = str(session.get("expedition_run").get("biome_id", "Sanctuary"))
	_set_zone(starting_zone)
	_restore_active_expedition_nodes()
	_restore_recovery_pack()
	_restore_structures()
	_refresh_station_visual()
	_refresh_livestock_visual()
	_refresh_structure_visuals()
	if load_state == "fresh":
		_show_toast("A quiet world is waiting. Gather, build, and make it yours.", 4.0)

func _process(delta: float) -> void:
	if get_tree().paused:
		_update_hud()
		return
	if interior_transitioning and building_interior != null and not bool(building_interior.call("is_transitioning")):
		interior_transitioning = false
	_copy_session_to_runtime()
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	attack_combo_timer = maxf(0.0, attack_combo_timer - delta)
	if attack_combo_timer <= 0.0:
		attack_combo_count = 0
	footstep_timer = maxf(0.0, footstep_timer - delta)
	toast_timer = maxf(0.0, toast_timer - delta)
	if toast_label != null:
		toast_label.visible = toast_timer > 0.0
	if player != null and camera != null:
		var shake := Vector3.ZERO
		if screen_shake_enabled and camera_shake > 0.0:
			camera_shake = maxf(0.0, camera_shake - delta)
			shake = Vector3(randf_range(-0.08, 0.08), randf_range(-0.04, 0.04), randf_range(-0.08, 0.08)) * camera_shake * 12.0
		var sanctuary_focus_offset := Vector3(0.0, 0.0, -2.4) if current_zone == "Sanctuary" and not interior_active else Vector3.ZERO
		var camera_focus := _clamped_camera_focus(player.global_position + sanctuary_focus_offset)
		if interior_active and building_interior != null and building_interior.has_method("camera_focus_position"):
			camera_focus = building_interior.call("camera_focus_position")
		# The camera is fixed-angle by contract. Smooth a separate anchor, then
		# apply the authored offset to both the camera and its look target. This
		# keeps translation soft without letting follow lag change the yaw/pitch.
		var follow_rate := minf(1.0, delta * 7.5)
		if not camera_anchor_initialized:
			camera_anchor = camera_focus
			camera_anchor_initialized = true
		else:
			camera_anchor = camera_anchor.lerp(camera_focus, follow_rate)
		var desired_camera_position := camera_anchor + CAMERA_OFFSET + shake
		camera.global_position = desired_camera_position
		camera.look_at(camera_anchor + CAMERA_LOOK_OFFSET, Vector3.UP)
		_update_camera_motion_basis(camera_focus, camera_focus + CAMERA_OFFSET)
	_update_time(delta)
	_update_fishing_action(delta)
	_update_tree_sway()
	_update_world_motion(delta)
	_update_player_structure_motion(delta)
	_update_resource_action(delta)
	_update_whisperwood_route_progress()
	_update_expedition_route_progress()
	_update_attack_action(delta)
	_update_structure_preview()
	_update_interior_station_preview()
	_update_lighting()
	_update_audio_context()
	_update_interaction_marker(delta)
	_update_move_target_marker()
	_update_hud()
	anchor_timer += delta
	if anchor_timer >= 0.35:
		anchor_timer = 0.0
		_sync_expedition_anchor()
	last_autosave += delta
	if last_autosave >= 20.0 and session != null:
		last_autosave = 0.0
		var load_state := str(session.get("load_status"))
		var save_ok := false
		if load_state not in ["rejected", "future"] and not bool(session.get("save_blocked")):
			save_ok = bool(session.call("save_game"))
		if not save_ok:
			autosave_failed = true
			if not autosave_failure_notified:
				_show_toast("Autosave unavailable. Your current run is still active; open the Ledger and save explicitly.", 4.0)
				autosave_failure_notified = true
		else:
			autosave_failed = false
			autosave_failure_notified = false
	_update_expedition_hazard(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if interior_transitioning:
		return
	if event.is_action_pressed("pause"):
		if settings_open:
			_toggle_settings()
		else:
			_toggle_pause()
		return
	if get_tree().paused and not event.is_action_pressed("pause"):
		return
	if interior_active:
		if event.is_action_pressed("build") or event.is_action_pressed("blueprint"):
			_toggle_interior_station_placement()
			return
		if event.is_action_pressed("station"):
			_cycle_interior_station_kind()
			return
		if event.is_action_pressed("rotate_build"):
			_rotate_interior_station_placement()
			return
		if event.is_action_pressed("interact"):
			if interior_station_placement_mode:
				_confirm_interior_station_placement()
			else:
				_contextual_interact()
		return
	if is_player_input_locked() and not event.is_action_pressed("interact"):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Godot can mirror a touch press as a left-mouse event. The joystick has
		# already consumed the touch; do not also create a world click target.
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if placement_mode:
			_place_structure()
		else:
			_set_mouse_move_target(event.position)
		return
	if event.is_action_pressed("interact"):
		_contextual_interact()
	elif event.is_action_pressed("attack"):
		_player_attack(player)
	elif event.is_action_pressed("dodge"):
		_player_dodge()
	elif event.is_action_pressed("sleep"):
		_sleep()
	elif event.is_action_pressed("weather"):
		_toggle_weather()
	elif event.is_action_pressed("farm"):
		farm_plot_interact(farm_plot)
	elif event.is_action_pressed("eat"):
		_eat_best_food()
	elif event.is_action_pressed("drink"):
		_drink_water()
	elif event.is_action_pressed("cycle_food"):
		_cycle_food_selection()
	elif event.is_action_pressed("cycle_recipe"):
		_cycle_recipe_selection()
	elif event.is_action_pressed("repair"):
		_repair_tools()
	elif event.is_action_pressed("build"):
		_toggle_structure_placement()
	elif event.is_action_pressed("rotate_build"):
		_rotate_structure_placement()
	elif event.is_action_pressed("cycle_structure"):
		_cycle_structure_selection()
	elif event.is_action_pressed("station"):
		station_interact(workshop)
	elif event.is_action_pressed("stats"):
		_allocate_best_stat()
	elif event.is_action_pressed("activity"):
		_record_activity()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		# The root Control also emits resized, but deferring here catches mobile
		# safe-area changes that arrive with the window notification before the
		# viewport's logical size has settled.
		call_deferred("_layout_hud")
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and player != null and player.has_method("cancel_navigation"):
		player.call("cancel_navigation", true)
		player.call("set_joystick_vector", Vector2.ZERO)
		if hud_joystick != null and hud_joystick.has_method("reset_input"):
			hud_joystick.call("reset_input")
		# Mobile suspends and desktop focus changes must not let the in-world
		# clock, expedition pressure, or an action timer advance behind the
		# player's back. Remember only pauses created by this notification so a
		# user-initiated pause remains untouched on focus return.
		if not get_tree().paused:
			focus_paused = true
			get_tree().paused = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and focus_paused:
		focus_paused = false
		get_tree().paused = false

func _ensure_input_actions() -> void:
	# Input actions keep keyboard, controller, and future accessibility bindings
	# on the same path. The virtual joystick still overrides this vector on touch.
	var key_actions := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E],
		"attack": [KEY_SPACE],
		"dodge": [KEY_SHIFT],
		"sleep": [KEY_R],
		"weather": [KEY_T],
		"farm": [KEY_F],
		"eat": [KEY_G],
		"drink": [KEY_H],
		"cycle_food": [KEY_Y],
		"cycle_recipe": [KEY_Q],
		"repair": [KEY_V],
		"build": [KEY_B],
		"rotate_build": [KEY_X],
		"cycle_structure": [KEY_N],
		"station": [KEY_C],
		"stats": [KEY_L],
		"cycle_stat": [KEY_O],
		"activity": [KEY_P],
		"pause": [KEY_ESCAPE],
	}
	var joy_actions := {
		"interact": [JOY_BUTTON_A],
		"attack": [JOY_BUTTON_X],
		"dodge": [JOY_BUTTON_B],
		"cycle_food": [JOY_BUTTON_LEFT_SHOULDER],
		"cycle_recipe": [JOY_BUTTON_RIGHT_SHOULDER],
		"build": [JOY_BUTTON_Y],
		"rotate_build": [JOY_BUTTON_RIGHT_STICK],
		"pause": [JOY_BUTTON_START],
	}
	var joy_motion_actions := {
		"move_left": {"axis": JOY_AXIS_LEFT_X, "value": -1.0},
		"move_right": {"axis": JOY_AXIS_LEFT_X, "value": 1.0},
		"move_up": {"axis": JOY_AXIS_LEFT_Y, "value": -1.0},
		"move_down": {"axis": JOY_AXIS_LEFT_Y, "value": 1.0},
	}
	for action in key_actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for keycode in key_actions[action]:
			var key_event := InputEventKey.new()
			key_event.physical_keycode = int(keycode)
			if not _input_map_has_key(action, int(keycode)):
				InputMap.action_add_event(action, key_event)
		for button in joy_actions.get(action, []):
			var joy_event := InputEventJoypadButton.new()
			joy_event.button_index = int(button)
			if not _input_map_has_joy_button(action, int(button)):
				InputMap.action_add_event(action, joy_event)
		for motion in [joy_motion_actions.get(action, {})]:
			if motion.is_empty():
				continue
			var motion_event := InputEventJoypadMotion.new()
			motion_event.axis = int(motion.get("axis", 0))
			motion_event.axis_value = float(motion.get("value", 0.0))
			if not _input_map_has_joy_motion(action, motion_event.axis, motion_event.axis_value):
				InputMap.action_add_event(action, motion_event)

func _input_map_has_key(action: String, keycode: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and int(event.physical_keycode) == keycode:
			return true
	return false

func _input_map_has_joy_button(action: String, button_index: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and int(event.button_index) == button_index:
			return true
	return false

func _input_map_has_joy_motion(action: String, axis: int, axis_value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and int(event.axis) == axis and is_equal_approx(float(event.axis_value), axis_value):
			return true
	return false

func _build_lighting() -> void:
	var environment_node := WorldEnvironment.new()
	environment_node.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#496e68")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	# A cooler moss fill keeps the 2.5D art readable while leaving enough value
	# range for the warm sun/fire contrast on sourced 3D props and landmarks.
	environment.ambient_light_color = Color("#94aa98")
	environment.ambient_light_energy = 0.34
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	add_child(environment_node)
	sun_light = DirectionalLight3D.new()
	sun_light.name = "Sun"
	sun_light.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun_light.light_color = Color("#ffd6a4")
	sun_light.light_energy = 0.92
	sun_light.shadow_enabled = true
	add_child(sun_light)
	var sanctuary_sky_fill := OmniLight3D.new()
	sanctuary_sky_fill.name = "SanctuarySkyFill"
	sanctuary_sky_fill.position = Vector3(-8.0, 7.0, -6.0)
	sanctuary_sky_fill.light_color = Color("#8eb9c5")
	sanctuary_sky_fill.light_energy = 0.42
	sanctuary_sky_fill.omni_range = 24.0
	sanctuary_sky_fill.shadow_enabled = false
	add_child(sanctuary_sky_fill)
	hearth_fill = OmniLight3D.new()
	hearth_fill.name = "HearthFill"
	hearth_fill.position = Vector3(0.0, 2.4, 1.05)
	hearth_fill.omni_range = 7.0
	hearth_fill.light_color = Color("#ff9c5a")
	hearth_fill.light_energy = 2.2
	add_child(hearth_fill)

func _build_world() -> void:
	sanctuary_zone = Node3D.new()
	sanctuary_zone.name = "Sanctuary"
	add_child(sanctuary_zone)
	_create_floor(sanctuary_zone, Vector3(0.0, -0.25, 0.0), Vector2(80.0, 60.0), palette["grass"], "SanctuaryGround")
	_create_sanctuary_ground_story(sanctuary_zone)
	# The sourced district owns the readable tile paths. The old full-width
	# strips were useful for a systems prototype but created white rectangles
	# and a duplicate path layer in the actual scene.
	for route_id in ContentRegistry.ROUTE_SOCKETS:
		var route_socket: Dictionary = ContentRegistry.ROUTE_SOCKETS[route_id]
		var path_center: Array = route_socket.get("path_center", [0.0, 0.0])
		var path_size: Array = route_socket.get("path_size", [1.0, 1.0])
		_create_path(sanctuary_zone, Vector3(float(path_center[0]), 0.015, float(path_center[1])), Vector3(float(path_size[0]), 0.045, float(path_size[1])), palette["sand"].darkened(0.14))
	_create_authored_sanctuary_route_paths(sanctuary_zone)
	_create_building(sanctuary_zone, Vector3(0.0, 0.0, -4.0), "Hearth", palette["wood"], palette["wood_dark"], "wood")
	_create_guide_npc(sanctuary_zone, Vector3(2.7, 0.0, -2.3))
	_create_building(sanctuary_zone, Vector3(-7.5, 0.0, -1.5), "Wanderer's Bazaar", palette["sand"], palette["wood_dark"], "sand")
	_create_trade_stall(sanctuary_zone, Vector3(-6.0, 0.0, -0.1))
	_create_notice_board(sanctuary_zone, Vector3(-8.2, 0.0, 1.5))
	_create_pond(sanctuary_zone, Vector3(7.0, 0.08, 5.0))
	for route_id in ContentRegistry.ROUTE_SOCKETS:
		var route_socket: Dictionary = ContentRegistry.ROUTE_SOCKETS[route_id]
		var gate_position: Array = route_socket.get("gate_position", [0.0, 0.0])
		_create_route_gate(sanctuary_zone, route_id, str(route_socket.get("destination_id", "Unknown")), Vector3(float(gate_position[0]), 0.0, float(gate_position[1])), Color("#" + str(route_socket.get("accent", "ffffff"))))
	_create_farm_plot(sanctuary_zone, Vector3(-5.5, 0.0, 4.0))
	_create_livestock_pen(sanctuary_zone, Vector3(-0.2, 0.0, 7.0))
	_create_workshop(sanctuary_zone, Vector3(6.2, 0.0, -5.6))
	_create_building(sanctuary_zone, Vector3(-7.0, 0.0, -7.8), "Archive", palette["stone"], palette["wood_dark"], "stone")
	_create_library_station(sanctuary_zone, Vector3(-5.4, 0.0, -7.0))
	var legacy_sanctuary_buildings: Array[Node3D] = []
	for legacy_name in ["Hearth", "Wanderer'sBazaar", "Archive"]:
		var legacy_building := sanctuary_zone.get_node_or_null(legacy_name) as Node3D
		if legacy_building != null:
			legacy_sanctuary_buildings.append(legacy_building)
	if trade_stall != null:
		legacy_sanctuary_buildings.append(trade_stall)
	if livestock_pen != null:
		legacy_sanctuary_buildings.append(livestock_pen)
	sanctuary_district = SanctuaryDistrictScript.new() as Node3D
	sanctuary_district.build(sanctuary_zone, legacy_sanctuary_buildings)
	var stylized_legacy_nodes: Array = []
	for legacy_node in legacy_sanctuary_buildings:
		stylized_legacy_nodes.append(legacy_node)
	for legacy_node in [farm_plot, workshop, library_station, notice_board, fishing_spot, sanctuary_zone.get_node_or_null("Pond")]:
		if legacy_node != null and not stylized_legacy_nodes.has(legacy_node):
			stylized_legacy_nodes.append(legacy_node)
	sanctuary_style = SanctuaryStyleScript.new() as Node3D
	sanctuary_style.build(self, sanctuary_zone, sanctuary_district, stylized_legacy_nodes)
	var sanctuary_tree_positions := [
		Vector3(-16, 0, -12), Vector3(-12, 0, -14), Vector3(-5, 0, -14), Vector3(4, 0, -14), Vector3(13, 0, -12),
		Vector3(17, 0, -7), Vector3(17, 0, 0), Vector3(17, 0, 8), Vector3(12, 0, 13), Vector3(4, 0, 14),
		Vector3(-5, 0, 14), Vector3(-14, 0, 12), Vector3(-17, 0, 6), Vector3(-17, 0, -2),
		Vector3(-11, 0, 7), Vector3(11, 0, 7)
	]
	for index in sanctuary_tree_positions.size():
		_create_tree(sanctuary_zone, sanctuary_tree_positions[index], 0.95 + float(index % 4) * 0.12, "wood", 2)
	for position in [Vector3(-5, 0, 5), Vector3(4, 0, 6), Vector3(9, 0, 1), Vector3(-10, 0, -5)]:
		_create_flower_patch(sanctuary_zone, position, palette["leaf"])
	if sanctuary_style == null:
		_dress_sanctuary_edges(sanctuary_zone)
	_create_fiber_patch(sanctuary_zone, Vector3(-4.0, 0.0, 6.0))
	if sanctuary_style != null:
		sanctuary_style.call("finalize_legacy_cleanup")
		sanctuary_style.call("replace_resource_tree_visuals", sanctuary_nodes)
	forest_zone = Node3D.new()
	forest_zone.name = "Whisperwood"
	add_child(forest_zone)
	_create_floor(forest_zone, Vector3(0.0, -0.25, 0.0), Vector2(44.0, 32.0), palette["grass_dark"], "WhisperwoodGround")
	_create_path(forest_zone, Vector3(0.0, 0.02, 0.0), Vector3(3.0, 0.08, 24.0), palette["wood"])
	for position in [Vector3(-10, 0, -8), Vector3(-7, 0, 7), Vector3(10, 0, 7), Vector3(11, 0, -5), Vector3(-12, 0, 0), Vector3(5, 0, -8), Vector3(-3, 0, 8)]:
		_create_tree(forest_zone, position, 1.15, "wood", 2)
	for position in [Vector3(-5, 0, -3), Vector3(3, 0, 5), Vector3(8, 0, -1), Vector3(-9, 0, 4)]:
		_create_rock(forest_zone, position, "stone", 2)
	for position in [Vector3(-3, 0, -7), Vector3(5, 0, 2), Vector3(8, 0, 6)]:
		_create_flower_patch(forest_zone, position, palette["leaf_dark"])
	var grove_socket := ContentRegistry.whisperwood_landmark("grove")
	var clearing_socket := ContentRegistry.whisperwood_landmark("clearing")
	_create_mushroom(forest_zone, Vector3(-6.5, 0.0, 0.5))
	_create_mushroom(forest_zone, grove_socket + Vector3(-0.6, 0.0, 0.1), "Whisperwood:FernGroveMushroom")
	_create_expedition_inscription(forest_zone, grove_socket + Vector3(-1.8, 0.0, 0.85), "whisperwood_root_oath")
	_create_rock(forest_zone, Vector3(5.2, 0.0, -2.6), "stone", 2, "Trail Stone")
	_create_whisperwood_landmarks(forest_zone)
	_create_guardian(forest_zone, clearing_socket + Vector3(0.0, 0.9, 0.0), "forest_slime", Color("#c66b85"))
	_create_camp_site(forest_zone, Vector3(-9.0, 0.0, -1.0), "WOODLAND CAMP")
	_create_wildlife_for_zone(forest_zone, "Whisperwood")
	world_zones = [sanctuary_zone, forest_zone]
	beach_zone = _create_expedition_zone("Sunlit Beach", Color("#c79c67"), Color("#8f6b4c"), Color("#4b9ea6"))
	_create_tree(beach_zone, Vector3(-10, 0, -7), 0.82, "wood", 2)
	_create_tree(beach_zone, Vector3(10, 0, 5), 0.72, "wood", 2)
	_create_rock(beach_zone, Vector3(-5, 0, 2), "stone", 1)
	_create_rock(beach_zone, Vector3(6, 0, -4), "shell", 1, "Shell Fragment")
	_create_shell_discovery(beach_zone, Vector3(4.0, 0.0, 2.5))
	_create_shell_discovery(beach_zone, Vector3(-7.0, 0.0, -4.4), "SunlitBeach:TideglassShell:pool")
	_create_tidepool_fishing_spot(beach_zone, Vector3(2.5, 0.0, -6.25))
	_create_expedition_inscription(beach_zone, Vector3(4.9, 0.0, -5.0), "sunlit_tide_vow")
	_create_guardian(beach_zone, Vector3(-6.0, 0.9, -4.0), "tide_wraith", Color("#5eb6bd"))
	_create_camp_site(beach_zone, Vector3(9.0, 0.0, -6.0), "TIDE CAMP")
	_create_wildlife_for_zone(beach_zone, "Sunlit Beach")
	world_zones.append(beach_zone)
	mountain_zone = _create_expedition_zone("Ember Ridge", Color("#596367"), Color("#7f8d8c"), Color("#e19a62"))
	_create_rock(mountain_zone, Vector3(-8, 0, -6), "ore", 2, "Copper Ore")
	# Both quarry veins belong to the left-hand quarry lane. Keeping the
	# objective resources on the committed side means the player never has to
	# cross the physical high-pass barricade to finish a route they chose.
	_create_rock(mountain_zone, Vector3(-5.0, 0, -2.0), "ore", 2, "Copper Ore")
	_create_rock(mountain_zone, Vector3(-4, 0, 6), "stone", 2)
	_create_expedition_inscription(mountain_zone, Vector3(-6.0, 0.0, -4.5), "ember_quarry_mark")
	_create_tree(mountain_zone, Vector3(10, 0, 7), 0.76, "wood", 1)
	_create_guardian(mountain_zone, Vector3(5.0, 0.9, -5.0), "ember_golem", Color("#d97952"))
	_create_camp_site(mountain_zone, Vector3(-9.0, 0.0, 5.5), "RIDGE CAMP")
	_create_wildlife_for_zone(mountain_zone, "Ember Ridge")
	world_zones.append(mountain_zone)
	desert_zone = _create_expedition_zone("Glass Desert", Color("#c58b62"), Color("#9b674f"), Color("#d66f57"))
	_create_cactus(desert_zone, Vector3(-8, 0, -6))
	_create_cactus(desert_zone, Vector3(7, 0, 3))
	_create_rock(desert_zone, Vector3(-2, 0, 6), "sunstone", 1, "Sunstone")
	_create_rock(desert_zone, Vector3(9, 0, -7), "stone", 1)
	_create_expedition_inscription(desert_zone, Vector3(-8.3, 0.0, -4.0), "glass_desert_waymark")
	_create_guardian(desert_zone, Vector3(-5.0, 0.9, 4.5), "dune_wisp", Color("#e6ad61"))
	_create_camp_site(desert_zone, Vector3(8.0, 0.0, -5.5), "DUNE CAMP")
	_create_wildlife_for_zone(desert_zone, "Glass Desert")
	world_zones.append(desert_zone)
	dungeon_zone = _create_expedition_zone("Sunken Dungeon", Color("#29353e"), Color("#4a5360"), Color("#a88ce0"))
	# Keep the deep seam off the vault capstone approach. The landmark remains
	# reachable from the dungeon, while its measured interaction envelope cannot
	# steal focus from the completed vault objective.
	_create_rock(dungeon_zone, Vector3(-11.0, 0.0, 6.0), "ore", 3, "Deep Veinstone", "deep")
	_create_rock(dungeon_zone, Vector3(8.0, 0.0, 4.5), "ore", 3, "Veinstone")
	_create_relic_discovery(dungeon_zone, Vector3(4.0, 0.0, -3.0))
	_create_expedition_inscription(dungeon_zone, Vector3(4.8, 0.0, -4.8), "sunken_vault_verse")
	_create_guardian(dungeon_zone, Vector3(-4.0, 0.9, 4.0), "crypt_knight", Color("#a88ce0"))
	_create_camp_site(dungeon_zone, Vector3(9.0, 0.0, -6.5), "DUNGEON CAMP")
	world_zones.append(dungeon_zone)
	for zone in world_zones:
		zone.visible = zone == sanctuary_zone
	if session != null and session.has_method("enable_resource_contract"):
		session.call("enable_resource_contract")

func _build_building_interior() -> void:
	building_interior = BuildingInteriorScript.new() as Node3D
	if building_interior == null:
		return
	building_interior.name = "BuildingInteriorController"
	building_interior.call("build", self)

func _create_wildlife_for_zone(parent: Node3D, zone_id: String) -> void:
	var observed: Array = session.get("observed_wildlife") if session != null else []
	for wildlife_id in ContentRegistry.wildlife_ids_for_zone(zone_id):
		var definition := ContentRegistry.wildlife_definition(str(wildlife_id))
		var positions: Array = definition.get("positions", [])
		if not positions.is_empty() and positions[0] is Array and (positions[0] as Array).size() >= 2:
			var track_origin: Array = positions[0]
			_create_wildlife_track(parent, Vector3(float(track_origin[0]) + 0.95, 0.0, float(track_origin[1]) + 0.65), str(wildlife_id))
		for index in positions.size():
			var raw_position: Variant = positions[index]
			if not (raw_position is Array) or raw_position.size() < 2:
				continue
			var creature := WildlifeCreatureScript.new() as Node3D
			creature.name = "Wildlife_%s_%02d" % [str(wildlife_id), index]
			creature.set("world", self)
			creature.set("wildlife_id", str(wildlife_id))
			creature.set("species_id", str(definition.get("species_id", "wildlife")))
			creature.set("species_label", str(definition.get("label", "Wildlife")))
			creature.set("zone_id", zone_id)
			creature.set("wander_radius", float(definition.get("wander_radius", 1.5)))
			creature.set("move_speed", float(definition.get("move_speed", 0.6)))
			creature.set("flee_distance", float(definition.get("flee_distance", 2.2)))
			creature.set("phase_offset", float(index) * 2.37)
			creature.position = Vector3(float(raw_position[0]), 0.08, float(raw_position[1]))
			parent.add_child(creature)
			_build_wildlife_visual(creature, definition)
			creature.call("set_observed", observed.has(str(wildlife_id)))
			wildlife_nodes.append(creature)

func _create_wildlife_track(parent: Node3D, position: Vector3, wildlife_id: String) -> void:
	var definition := ContentRegistry.wildlife_definition(wildlife_id)
	if definition.is_empty():
		return
	var track := StationScript.new() as Node3D
	track.name = "Track_%s" % wildlife_id
	track.set("world", self)
	track.set("station_id", "wildlife_track")
	track.set_meta("wildlife_id", wildlife_id)
	track.add_to_group("interactable")
	track.add_to_group("wildlife_track")
	track.position = position
	parent.add_child(track)
	for index in 3:
		var print_mark := MeshInstance3D.new()
		print_mark.name = "TrackMark_%d" % index
		print_mark.mesh = _sphere_mesh(0.12, 0.035, 7, 3)
		print_mark.material_override = _material(palette["wood_dark"].lightened(0.10), 0.86)
		print_mark.position = Vector3((float(index) - 1.0) * 0.27, 0.035, sin(float(index) * 1.8) * 0.18)
		track.add_child(print_mark)
	var label := _label3d("FRESH TRACKS\n%s" % str(definition.get("label", "WILDLIFE")).to_upper(), 0.12, palette["cream"])
	label.name = "TrackLabel"
	label.position.y = 0.78
	track.add_child(label)
	_attach_measured_box_collision(track, track, "TrackCollision", "TrackHitbox")

func _build_wildlife_visual(creature: Node3D, definition: Dictionary) -> void:
	var species_id := str(definition.get("species_id", "wildlife"))
	var visual := Node3D.new()
	visual.name = "Visual"
	creature.add_child(visual)
	creature.set("visual_root", visual)
	var body_color := Color("#a98468")
	var dark_color := Color("#4e403d")
	match species_id:
		"rabbit":
			body_color = Color("#d0a477")
			dark_color = Color("#6a4b43")
			_wildlife_part(visual, "Body", _sphere_mesh(0.27, 0.58, 9, 5), Vector3(0.0, 0.30, 0.0), body_color, Vector3(1.0, 0.9, 1.2))
			_wildlife_part(visual, "Head", _sphere_mesh(0.20, 0.42, 9, 5), Vector3(0.12, 0.52, 0.18), body_color)
			_wildlife_part(visual, "EarLeft", _box_mesh(Vector3(0.10, 0.42, 0.10)), Vector3(0.03, 0.86, 0.17), dark_color, Vector3.ONE, Vector3(-8.0, 0.0, -7.0))
			_wildlife_part(visual, "EarRight", _box_mesh(Vector3(0.10, 0.42, 0.10)), Vector3(0.20, 0.86, 0.17), dark_color, Vector3.ONE, Vector3(7.0, 0.0, 8.0))
			_wildlife_part(visual, "Tail", _sphere_mesh(0.13, 0.26, 8, 4), Vector3(-0.22, 0.34, -0.28), Color("#f0d0a1"))
		"beetle":
			body_color = Color("#4e7773")
			dark_color = Color("#263d42")
			_wildlife_part(visual, "Shell", _sphere_mesh(0.23, 0.36, 9, 5), Vector3(0.0, 0.23, 0.0), body_color, Vector3(1.2, 0.58, 1.55))
			_wildlife_part(visual, "Head", _sphere_mesh(0.12, 0.20, 8, 4), Vector3(0.0, 0.21, 0.22), dark_color)
			for leg_index in 3:
				var z_offset := -0.18 + float(leg_index) * 0.18
				_wildlife_part(visual, "LegL%d" % leg_index, _box_mesh(Vector3(0.34, 0.035, 0.045)), Vector3(-0.20, 0.12, z_offset), dark_color, Vector3.ONE, Vector3(0.0, 0.0, -12.0))
				_wildlife_part(visual, "LegR%d" % leg_index, _box_mesh(Vector3(0.34, 0.035, 0.045)), Vector3(0.20, 0.12, z_offset), dark_color, Vector3.ONE, Vector3(0.0, 0.0, 12.0))
		"crab":
			body_color = Color("#d96c5d")
			dark_color = Color("#713e43")
			_wildlife_part(visual, "Body", _sphere_mesh(0.29, 0.34, 9, 5), Vector3(0.0, 0.25, 0.0), body_color, Vector3(1.35, 0.62, 1.0))
			_wildlife_part(visual, "EyeStemL", _box_mesh(Vector3(0.04, 0.24, 0.04)), Vector3(-0.12, 0.50, 0.16), dark_color)
			_wildlife_part(visual, "EyeStemR", _box_mesh(Vector3(0.04, 0.24, 0.04)), Vector3(0.12, 0.50, 0.16), dark_color)
			_wildlife_part(visual, "ClawL", _sphere_mesh(0.12, 0.22, 8, 4), Vector3(-0.43, 0.28, 0.17), body_color, Vector3(1.0, 0.8, 1.2))
			_wildlife_part(visual, "ClawR", _sphere_mesh(0.12, 0.22, 8, 4), Vector3(0.43, 0.28, 0.17), body_color, Vector3(1.0, 0.8, 1.2))
			for leg_index in 3:
				var z_offset := -0.20 + float(leg_index) * 0.20
				_wildlife_part(visual, "LegL%d" % leg_index, _box_mesh(Vector3(0.38, 0.04, 0.05)), Vector3(-0.34, 0.13, z_offset), dark_color, Vector3.ONE, Vector3(0.0, 0.0, -18.0))
				_wildlife_part(visual, "LegR%d" % leg_index, _box_mesh(Vector3(0.38, 0.04, 0.05)), Vector3(0.34, 0.13, z_offset), dark_color, Vector3.ONE, Vector3(0.0, 0.0, 18.0))
		"marmot":
			body_color = Color("#9a7659")
			dark_color = Color("#593f39")
			_wildlife_part(visual, "Body", _sphere_mesh(0.31, 0.65, 9, 5), Vector3(0.0, 0.36, 0.0), body_color, Vector3(1.1, 0.9, 1.0))
			_wildlife_part(visual, "Head", _sphere_mesh(0.22, 0.44, 9, 5), Vector3(0.0, 0.68, 0.16), body_color)
			_wildlife_part(visual, "EarLeft", _sphere_mesh(0.07, 0.13, 7, 4), Vector3(-0.13, 0.86, 0.14), dark_color)
			_wildlife_part(visual, "EarRight", _sphere_mesh(0.07, 0.13, 7, 4), Vector3(0.13, 0.86, 0.14), dark_color)
		"lizard":
			body_color = Color("#8ca271")
			dark_color = Color("#51644d")
			_wildlife_part(visual, "Body", _sphere_mesh(0.20, 0.42, 9, 5), Vector3(0.0, 0.19, 0.0), body_color, Vector3(0.85, 0.5, 2.7))
			_wildlife_part(visual, "Head", _sphere_mesh(0.18, 0.34, 8, 4), Vector3(0.0, 0.22, 0.38), body_color, Vector3(1.0, 0.72, 1.35))
			_wildlife_part(visual, "Tail", _sphere_mesh(0.12, 0.24, 8, 4), Vector3(0.0, 0.16, -0.54), dark_color, Vector3(0.8, 0.5, 1.8))
			for side in [-1.0, 1.0]:
				_wildlife_part(visual, "FrontLeg%s" % side, _box_mesh(Vector3(0.32, 0.045, 0.06)), Vector3(side * 0.19, 0.10, 0.24), dark_color, Vector3.ONE, Vector3(0.0, 0.0, side * 22.0))
				_wildlife_part(visual, "BackLeg%s" % side, _box_mesh(Vector3(0.36, 0.045, 0.06)), Vector3(side * 0.19, 0.10, -0.20), dark_color, Vector3.ONE, Vector3(0.0, 0.0, side * 22.0))
		_:
			_wildlife_part(visual, "Body", _sphere_mesh(0.25, 0.5, 8, 4), Vector3(0.0, 0.28, 0.0), body_color)
	var label := _label3d(str(definition.get("label", "Wildlife")), 0.12, palette["cream"])
	label.name = "WildlifeLabel"
	label.position.y = 1.15
	creature.add_child(label)
	creature.set("label_node", label)

func _wildlife_part(parent: Node3D, node_name: String, mesh: Mesh, local_position: Vector3, color: Color, local_scale := Vector3.ONE, rotation_degrees := Vector3.ZERO) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = node_name
	part.mesh = mesh
	part.material_override = _material(color, 0.86)
	part.position = local_position
	part.scale = local_scale
	part.rotation_degrees = rotation_degrees
	parent.add_child(part)
	return part

func _box_mesh(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh

func _create_expedition_zone(zone_name: String, ground_color: Color, path_color: Color, accent: Color) -> Node3D:
	var zone := Node3D.new()
	zone.name = zone_name.replace(" ", "")
	add_child(zone)
	_create_floor(zone, Vector3(0.0, -0.25, 0.0), Vector2(44.0, 32.0), ground_color, zone_name + "Ground")
	_create_path(zone, Vector3(0.0, 0.02, 0.0), Vector3(3.0, 0.08, 24.0), path_color)
	var banner := _label3d(zone_name.to_upper(), 0.26, palette["cream"])
	banner.position = Vector3(0.0, 3.0, -8.5)
	zone.add_child(banner)
	var marker := MeshInstance3D.new()
	marker.mesh = _sphere_mesh(0.28, 0.56, 8, 4)
	marker.material_override = _material(accent, 0.72, false, true)
	marker.position = Vector3(0.0, 0.5, 7.2)
	zone.add_child(marker)
	animated_beacons.append(marker)
	match zone_name:
		"Sunlit Beach": _create_beach_landmarks(zone)
		"Ember Ridge": _create_ridge_landmarks(zone)
		"Glass Desert": _create_desert_landmarks(zone)
		"Sunken Dungeon": _create_dungeon_landmarks(zone)
	_create_map_identity(zone, zone_name, accent)
	_dress_expedition_edges(zone, zone_name)
	_create_expedition_route_landmarks(zone, zone_name, accent)
	return zone

func _create_whisperwood_landmarks(parent: Node3D) -> void:
	var route := Node3D.new()
	route.name = "WhisperwoodRoute"
	route.set_meta("authored_traversal_length", 52.0)
	route.set_meta("authored_beats", 5)
	parent.add_child(route)
	_create_whisperwood_topology(route)
	# The straight entry path breaks at the old trail marker, then opens onto
	# two readable approaches: the fern-covered left grove and the guardian's
	# right-hand clearing. These are visual landmarks, not invisible triggers.
	var fork_socket := ContentRegistry.whisperwood_landmark("fork")
	var grove_socket := ContentRegistry.whisperwood_landmark("grove")
	var clearing_socket := ContentRegistry.whisperwood_landmark("clearing")
	_create_path(route, fork_socket + Vector3(0.0, 0.045, 0.0), Vector3(3.4, 0.07, 1.0), palette["wood"])
	_create_path(route, Vector3(-3.4, 0.045, -2.7), Vector3(5.6, 0.07, 1.0), palette["wood"])
	_create_path(route, Vector3(3.5, 0.045, -2.7), Vector3(5.6, 0.07, 1.0), palette["wood"])
	var fork_marker := _label3d("OLD TRAIL MARKER\nLEFT: WHISPERGLASS GROVE   RIGHT: GUARDIAN CLEARING", 0.14, palette["cream"])
	fork_marker.name = "ForkMarkerLabel"
	fork_marker.position = Vector3(0.0, 1.9, -2.25)
	route.add_child(fork_marker)
	var clearing := MeshInstance3D.new()
	clearing.name = "GuardianClearing"
	var clearing_mesh := CylinderMesh.new()
	clearing_mesh.top_radius = 2.45
	clearing_mesh.bottom_radius = 2.45
	clearing_mesh.height = 0.05
	clearing_mesh.radial_segments = 24
	clearing.mesh = clearing_mesh
	clearing.material_override = _material(palette["leaf_dark"].lightened(0.08), 1.0)
	clearing.position = clearing_socket + Vector3(0.0, 0.035, 0.0)
	route.add_child(clearing)
	var clearing_label := _label3d("GUARDIAN CLEARING", 0.16, palette["cream"])
	clearing_label.position = clearing_socket + Vector3(0.0, 0.22, -2.45)
	route.add_child(clearing_label)
	var branch_marker := StationScript.new() as Node3D
	branch_marker.name = "WhisperwoodBranchChoice"
	branch_marker.set("world", self)
	branch_marker.set("station_id", "whisper_branch")
	branch_marker.add_to_group("interactable")
	branch_marker.set_meta("route_branch_choice", true)
	branch_marker.position = fork_socket
	route.add_child(branch_marker)
	for side in [-1.0, 1.0]:
		_structure_box(branch_marker, "BranchPost_%s" % side, Vector3(0.16, 1.55, 0.16), Vector3(side * 1.25, 0.78, 0.0), palette["wood_dark"])
	_structure_box(branch_marker, "BranchBeam", Vector3(2.7, 0.16, 0.16), Vector3(0.0, 1.48, 0.0), palette["wood_dark"])
	var branch_label := _label3d("OLD TRAIL MARKER\nCHOOSE A BRANCH", 0.15, palette["cream"])
	branch_label.name = "BranchChoiceLabel"
	branch_label.position = Vector3(0.0, 1.92, 0.0)
	branch_marker.add_child(branch_label)
	_create_route_barrier(route, Vector3(-3.35, 0.0, -2.72), "grove", Color("#6f8f71"))
	_create_route_barrier(route, Vector3(3.45, 0.0, -2.72), "clearing", Color("#956c61"))
	_create_whisper_cache(route, grove_socket + Vector3(0.0, 0.0, 1.8), "grove", "FERN GROVE CACHE", Color("#8fcf9a"))
	_create_whisper_cache(route, clearing_socket + Vector3(0.0, 0.0, 1.8), "clearing", "GUARDIAN CACHE", Color("#d58b9c"))
	var shortcut := Node3D.new()
	shortcut.name = "WhisperwoodShortcut"
	shortcut.visible = false
	route.add_child(shortcut)
	_create_path(shortcut, Vector3(0.0, 0.05, -5.7), Vector3(2.0, 0.08, 4.6), Color("#b7a073"))
	var shortcut_label := _label3d("SHORTCUT OPEN", 0.15, palette["cream"])
	shortcut_label.position = Vector3(0.0, 1.1, -5.7)
	shortcut.add_child(shortcut_label)
	for index in 7:
		var stone_position := Vector3(-7.2 + float(index) * 2.0, 0.1, 1.4 + sin(float(index) * 0.8) * 0.25)
		_add_sourced_model(route, "res://assets/quaternius-stylized-nature/glTF/RockPath_Round_Small_1.gltf", 0.24, stone_position)
	for position in [Vector3(-5.9, 0.08, -2.1), Vector3(-4.3, 0.08, -3.2), Vector3(-7.3, 0.08, -3.4), Vector3(-6.6, 0.08, 0.5)]:
		_add_sourced_model(route, "res://assets/quaternius-stylized-nature/glTF/Fern_1.gltf", 0.38, position)
	for position in [Vector3(-2.7, 0.08, -1.0), Vector3(1.9, 0.08, -2.7), Vector3(7.0, 0.08, -2.3), Vector3(7.8, 0.08, -5.5)]:
		_add_sourced_model(route, "res://assets/quaternius-stylized-nature/glTF/Grass_Common_Tall.gltf", 0.34, position)
	_add_sourced_model(route, "res://assets/quaternius-stylized-nature/glTF/Pine_3.gltf", 0.62, Vector3(-12.0, 0.08, -6.0))
	_add_sourced_model(route, "res://assets/quaternius-stylized-nature/glTF/Pine_3.gltf", 0.54, Vector3(11.5, 0.08, 1.5))

func _create_whisperwood_topology(parent: Node3D) -> void:
	# The forest route is intentionally authored as a sequence of readable
	# spaces. These are broad natural lanes rather than a visible grid: the
	# player enters through a calm clearing, commits at the old marker, then
	# navigates a distinct grove or guardian clearing before the return bridge.
	var topology := Node3D.new()
	topology.name = "AuthoredTopology"
	parent.add_child(topology)
	var beats := [
		{"id": "ArrivalGrove", "socket": "arrival", "label": "ARRIVAL GROVE", "position": ContentRegistry.whisperwood_landmark("arrival") + Vector3(0.0, 0.04, 0.0), "radius": 3.4, "color": Color("#52785d")},
		{"id": "OldTrailFork", "socket": "fork", "label": "OLD TRAIL FORK", "position": ContentRegistry.whisperwood_landmark("fork") + Vector3(0.0, 0.04, 0.0), "radius": 2.4, "color": Color("#6d805f")},
		{"id": "FernGrove", "socket": "grove", "label": "FERN GROVE", "position": ContentRegistry.whisperwood_landmark("grove") + Vector3(0.0, 0.04, 0.0), "radius": 3.1, "color": Color("#6f9a73")},
		{"id": "GuardianClearing", "socket": "clearing", "label": "GUARDIAN CLEARING", "position": ContentRegistry.whisperwood_landmark("clearing") + Vector3(0.0, 0.04, 0.0), "radius": 3.4, "color": Color("#856b68")},
		{"id": "ReturnFootbridge", "socket": "return", "label": "RETURN FOOTBRIDGE", "position": ContentRegistry.whisperwood_landmark("return") + Vector3(0.0, 0.04, 0.0), "radius": 2.6, "color": Color("#7e7058")},
	]
	for beat_data in beats:
		var beat := Node3D.new()
		beat.name = str(beat_data["id"])
		beat.set_meta("route_beat", beat.name)
		beat.set_meta("route_socket", str(beat_data["socket"]))
		beat.position = beat_data["position"]
		topology.add_child(beat)
		var checkpoint := Area3D.new()
		checkpoint.name = "Checkpoint"
		checkpoint.set_meta("route_socket", str(beat_data["socket"]))
		checkpoint.set_meta("checkpoint_radius", float(beat_data["radius"]))
		var checkpoint_shape := CollisionShape3D.new()
		checkpoint_shape.name = "CheckpointCollision"
		var checkpoint_sphere := SphereShape3D.new()
		checkpoint_sphere.radius = float(beat_data["radius"])
		checkpoint_shape.shape = checkpoint_sphere
		checkpoint.add_child(checkpoint_shape)
		beat.add_child(checkpoint)
		var clearing := MeshInstance3D.new()
		clearing.name = "ClearingFloor"
		var clearing_mesh := CylinderMesh.new()
		clearing_mesh.top_radius = float(beat_data["radius"])
		clearing_mesh.bottom_radius = float(beat_data["radius"])
		clearing_mesh.height = 0.06
		clearing_mesh.radial_segments = 28
		clearing.mesh = clearing_mesh
		clearing.material_override = _material(beat_data["color"], 0.92)
		beat.add_child(clearing)
		var beat_label := _label3d(str(beat_data["label"]), 0.14, palette["cream"])
		beat_label.name = "BeatLabel"
		beat_label.position.y = 0.36
		beat.add_child(beat_label)
	# Uneven lanes make the journey read as a route instead of a single arena.
	var arrival_socket := ContentRegistry.whisperwood_landmark("arrival")
	var fork_socket := ContentRegistry.whisperwood_landmark("fork")
	var grove_socket := ContentRegistry.whisperwood_landmark("grove")
	var clearing_socket := ContentRegistry.whisperwood_landmark("clearing")
	var return_socket := ContentRegistry.whisperwood_landmark("return")
	_create_path(topology, Vector3(0.0, 0.08, (arrival_socket.z + fork_socket.z) * 0.5), Vector3(2.35, 0.10, absf(arrival_socket.z - fork_socket.z)), Color("#80694f"))
	_create_path(topology, Vector3(-3.8, 0.08, -4.1), Vector3(7.5, 0.10, 1.2), Color("#80694f"))
	_create_path(topology, Vector3(3.8, 0.08, -4.1), Vector3(7.5, 0.10, 1.2), Color("#80694f"))
	_create_path(topology, Vector3((fork_socket.x + grove_socket.x) * 0.5, 0.08, (fork_socket.z + grove_socket.z) * 0.5), Vector3(absf(fork_socket.x - grove_socket.x), 0.10, 1.1), Color("#80694f"))
	_create_path(topology, Vector3((fork_socket.x + clearing_socket.x) * 0.5, 0.08, (fork_socket.z + clearing_socket.z) * 0.5), Vector3(absf(fork_socket.x - clearing_socket.x), 0.10, 1.1), Color("#80694f"))
	_create_path(topology, Vector3(0.0, 0.08, (return_socket.z + arrival_socket.z) * 0.5), Vector3(2.0, 0.10, absf(return_socket.z - arrival_socket.z)), Color("#a58b62"))
	# The edges are collision-backed so the player reads the lanes by movement,
	# not only by labels. Gaps remain wide enough for a natural dodge and return.
	_create_forest_bramble(topology, Vector3(-4.2, 0.0, -6.0), Vector3(3.4, 1.2, 0.55), Color("#345b4c"))
	_create_forest_bramble(topology, Vector3(4.2, 0.0, -6.0), Vector3(3.4, 1.2, 0.55), Color("#345b4c"))
	_create_forest_bramble(topology, Vector3(-15.2, 0.0, -7.2), Vector3(0.65, 1.3, 4.4), Color("#41634e"))
	_create_forest_bramble(topology, Vector3(15.2, 0.0, -7.2), Vector3(0.65, 1.3, 4.4), Color("#604e50"))
	for position in [Vector3(-2.7, 0.08, 3.8), Vector3(2.8, 0.08, 2.7), Vector3(-7.0, 0.08, -5.2), Vector3(7.0, 0.08, -5.2), Vector3(-10.0, 0.08, -10.5), Vector3(10.0, 0.08, -10.5)]:
		_add_sourced_model(topology, "res://assets/quaternius-stylized-nature/glTF/Fern_1.gltf", 0.42, position)

func _create_forest_bramble(parent: Node3D, position: Vector3, size: Vector3, color: Color) -> void:
	var bramble := StaticBody3D.new()
	bramble.name = "BrambleEdge"
	bramble.set_meta("route_edge", true)
	bramble.position = position
	var wall := MeshInstance3D.new()
	wall.name = "BrambleVisual"
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = size
	wall.mesh = wall_mesh
	wall.material_override = _material(color, 0.88)
	wall.position.y = size.y * 0.5
	bramble.add_child(wall)
	var collision := CollisionShape3D.new()
	collision.name = "BrambleCollision"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position.y = size.y * 0.5
	bramble.add_child(collision)
	parent.add_child(bramble)

func _create_route_barrier(parent: Node3D, position: Vector3, blocked_branch: String, accent: Color) -> void:
	var barrier := StaticBody3D.new()
	barrier.name = "WhisperwoodBarrier_" + blocked_branch.capitalize()
	barrier.set_meta("blocked_branch", blocked_branch)
	barrier.position = position
	barrier.visible = false
	var wall := MeshInstance3D.new()
	wall.name = "BarrierWall"
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(5.05, 1.9, 0.38)
	wall.mesh = wall_mesh
	wall.material_override = _material(accent, 0.9)
	wall.position.y = 0.95
	barrier.add_child(wall)
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.name = "BarrierPost_%s" % side
		var post_mesh := CylinderMesh.new()
		post_mesh.top_radius = 0.13
		post_mesh.bottom_radius = 0.18
		post_mesh.height = 2.25
		post_mesh.radial_segments = 7
		post.mesh = post_mesh
		post.material_override = _material(palette["wood_dark"], 0.96)
		post.position = Vector3(side * 2.15, 1.12, 0.0)
		barrier.add_child(post)
	var vine := MeshInstance3D.new()
	vine.name = "BarrierVine"
	vine.mesh = _sphere_mesh(0.22, 0.9, 8, 5)
	vine.material_override = _material(accent.lightened(0.15), 0.82, false, true)
	vine.position = Vector3(0.0, 1.22, -0.2)
	vine.scale = Vector3(4.4, 0.55, 0.45)
	barrier.add_child(vine)
	var collision := CollisionShape3D.new()
	collision.name = "BarrierCollision"
	var shape := BoxShape3D.new()
	shape.size = Vector3(5.05, 1.9, 0.38)
	collision.shape = shape
	collision.position.y = 0.95
	barrier.add_child(collision)
	parent.add_child(barrier)

func _create_whisper_cache(parent: Node3D, position: Vector3, branch_id: String, label_text: String, accent: Color) -> void:
	var cache := StationScript.new() as Node3D
	cache.name = "WhisperCache_" + branch_id.capitalize()
	cache.set("world", self)
	cache.set("station_id", "whisper_cache")
	cache.add_to_group("interactable")
	cache.set_meta("route_branch", branch_id)
	cache.position = position
	parent.add_child(cache)
	_structure_box(cache, "CacheChest", Vector3(1.05, 0.56, 0.68), Vector3(0.0, 0.38, 0.0), palette["wood_dark"])
	_structure_box(cache, "CacheLid", Vector3(1.12, 0.10, 0.73), Vector3(0.0, 0.70, 0.0), accent)
	_structure_box(cache, "CacheBand", Vector3(0.10, 0.68, 0.76), Vector3(0.0, 0.40, 0.0), accent)
	var marker := MeshInstance3D.new()
	marker.name = "CacheMarker"
	marker.mesh = _sphere_mesh(0.14, 0.28, 7, 4)
	marker.material_override = _material(accent, 0.38, false, true)
	marker.position = Vector3(0.0, 1.1, 0.0)
	cache.add_child(marker)
	var label := _label3d(label_text + "\nLOCKED", 0.15, palette["cream"])
	label.name = "CacheLabel"
	label.position = Vector3(0.0, 1.42, 0.0)
	cache.add_child(label)

func _refresh_whisperwood_route() -> void:
	if forest_zone == null or session == null:
		return
	var route := forest_zone.get_node_or_null("WhisperwoodRoute") as Node3D
	if route == null:
		return
	var run: Dictionary = session.get("expedition_run")
	var active := str(run.get("status", "none")) == "active" and str(run.get("biome_id", "")) == "Whisperwood"
	var branch_id := str(run.get("branch_id", ""))
	var objective_complete := bool(run.get("objective_complete", false))
	var shortcut_open := bool(run.get("shortcut_open", false))
	var branch_marker := route.get_node_or_null("WhisperwoodBranchChoice") as Node3D
	if branch_marker != null:
		branch_marker.visible = active and branch_id.is_empty()
		var branch_label := branch_marker.get_node_or_null("BranchChoiceLabel") as Label3D
		if branch_label != null:
			branch_label.text = "OLD TRAIL MARKER\nCHOOSE A BRANCH" if branch_id.is_empty() else ("GROVE CHOSEN" if branch_id == "grove" else "CLEARING CHOSEN")
	for barrier_node in route.get_children():
		var barrier := barrier_node as StaticBody3D
		if barrier == null or not barrier.has_meta("blocked_branch"):
			continue
		var blocked_branch := str(barrier.get_meta("blocked_branch", ""))
		var blocked := active and not branch_id.is_empty() and blocked_branch != branch_id
		barrier.visible = blocked
		var collision := barrier.get_node_or_null("BarrierCollision") as CollisionShape3D
		if collision != null:
			collision.disabled = not blocked
	for cache_node in route.get_children():
		var cache := cache_node as Node3D
		if cache == null or str(cache.get("station_id")) != "whisper_cache":
			continue
		var cache_branch := str(cache.get_meta("route_branch", ""))
		var cache_label := cache.get_node_or_null("CacheLabel") as Label3D
		var available := active and objective_complete and not bool(run.get("cache_claimed", false)) and cache_branch == branch_id
		cache.visible = not active or cache_branch == branch_id or available
		if cache_label != null:
			cache_label.text = ("FERN GROVE CACHE" if cache_branch == "grove" else "GUARDIAN CACHE") + ("\nOPEN CACHE" if available else ("\nCLAIMED" if bool(run.get("cache_claimed", false)) and cache_branch == branch_id else "\nLOCKED"))
	var shortcut := route.get_node_or_null("WhisperwoodShortcut") as Node3D
	if shortcut != null:
		shortcut.visible = active and shortcut_open

func _record_whisperwood_checkpoint(node_name: String, checkpoint_id: String) -> bool:
	if session == null or player == null or not session.has_method("record_route_checkpoint"):
		return false
	var checkpoint := get_node_or_null("Whisperwood/WhisperwoodRoute/AuthoredTopology/%s/Checkpoint" % node_name) as Area3D
	if checkpoint == null:
		return false
	var flat_distance := Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(checkpoint.global_position.x, checkpoint.global_position.z))
	if flat_distance > float(checkpoint.get_meta("checkpoint_radius", 2.5)):
		return false
	var before_checkpoint: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	if not bool(session.call("record_route_checkpoint", checkpoint_id)):
		return false
	if not bool(session.call("save_game")):
		if not before_checkpoint.is_empty() and session.has_method("restore_state"):
			session.call("restore_state", before_checkpoint)
		_copy_session_to_runtime()
		_refresh_whisperwood_route()
		_show_toast("The route checkpoint could not be secured. Keep moving; the beat remains ahead.", 2.6)
		return false
	_refresh_whisperwood_route()
	return true

func _update_whisperwood_route_progress() -> void:
	if current_zone != "Whisperwood" or session == null or player == null or not session.call("has_active_expedition"):
		return
	var run: Dictionary = session.get("expedition_run")
	if str(run.get("biome_id", "")) != "Whisperwood":
		return
	var route_phase := str(run.get("route_phase", "approach"))
	# The first two route beats are physical traversal state. They are written
	# through GameSession so a reload cannot silently skip the forest's entry or
	# fork even if the player closes the game between interactions.
	if route_phase == "approach":
		_record_whisperwood_checkpoint("ArrivalGrove", "arrival")
		return
	if route_phase == "arrival":
		_record_whisperwood_checkpoint("OldTrailFork", "fork")
		return
	if route_phase == "shortcut":
		_record_whisperwood_checkpoint("ReturnFootbridge", "return")
		return
	var branch_id := str(run.get("branch_id", ""))
	if branch_id.is_empty() or route_phase != "branch":
		return
	var endpoint_name := "FernGrove" if branch_id == "grove" else "GuardianClearing"
	var endpoint := get_node_or_null("Whisperwood/WhisperwoodRoute/AuthoredTopology/%s/Checkpoint" % endpoint_name) as Area3D
	if endpoint == null:
		return
	var flat_distance := Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(endpoint.global_position.x, endpoint.global_position.z))
	if flat_distance > float(endpoint.get_meta("checkpoint_radius", 2.5)):
		return
	# The route state moves from the fork to the objective only when the player
	# physically reaches the committed endpoint. The resource/guardian systems
	# remain authoritative for objective completion and rewards.
	var previous_phase := str(run.get("route_phase", "branch"))
	run["route_phase"] = "objective"
	if not bool(session.call("save_game")):
		run["route_phase"] = previous_phase
		return
	_refresh_whisperwood_route()

func _update_expedition_route_progress() -> void:
	if current_zone in ["Sanctuary", "Whisperwood"] or session == null or player == null or not session.has_method("record_expedition_return_checkpoint") or not bool(session.call("has_active_expedition")):
		return
	var run: Dictionary = session.get("expedition_run")
	if str(run.get("biome_id", "")) != current_zone or str(run.get("route_phase", "")) != "shortcut":
		return
	var route := get_node_or_null("%s/ExpeditionRoute" % current_zone.replace(" ", "")) as Node3D
	var causeway := route.get_node_or_null("ReturnCauseway") as Node3D if route != null else null
	if causeway == null:
		return
	var causeway_radius := float(causeway.get_meta("checkpoint_radius", 2.8))
	if _ground_distance(player.global_position, causeway.global_position) > causeway_radius:
		return
	var before_checkpoint: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	if not bool(session.call("record_expedition_return_checkpoint", [player.global_position.x, 1.0, player.global_position.z])):
		return
	if not bool(session.call("save_game")):
		if not before_checkpoint.is_empty() and session.has_method("restore_state"):
			session.call("restore_state", before_checkpoint)
		_copy_session_to_runtime()
		_refresh_expedition_routes()
		_show_toast("The return causeway could not be secured. Keep moving; the route remains open.", 2.6)
		return
	_refresh_expedition_routes()
	_show_toast("Return causeway crossed  |  The beacon is safe to reach.", 2.4)

func _create_beach_landmarks(parent: Node3D) -> void:
	var sea := Node3D.new()
	sea.name = "TideLine"
	sea.position = Vector3(0.0, 0.02, -8.5)
	parent.add_child(sea)
	for index in 5:
		var wave := MeshInstance3D.new()
		var wave_mesh := CylinderMesh.new()
		wave_mesh.top_radius = 1.6
		wave_mesh.bottom_radius = 1.6
		wave_mesh.height = 0.06
		wave_mesh.radial_segments = 32
		wave.mesh = wave_mesh
		wave.material_override = _material(Color("#68c4c7"), 0.18)
		wave.position = Vector3(-9.0 + float(index) * 4.5, 0.08, float(index % 2) * 0.32)
		sea.add_child(wave)
		animated_water.append(wave)
	for position in [Vector3(-7.0, 0.0, -4.5), Vector3(2.0, 0.0, -6.0), Vector3(8.0, 0.0, -2.0)]:
		var driftwood := MeshInstance3D.new()
		var log_mesh := CylinderMesh.new()
		log_mesh.top_radius = 0.16
		log_mesh.bottom_radius = 0.2
		log_mesh.height = 1.8
		log_mesh.radial_segments = 7
		driftwood.mesh = log_mesh
		driftwood.material_override = _material(palette["wood_dark"], 0.96)
		driftwood.position = position + Vector3(0.0, 0.2, 0.0)
		driftwood.rotation_degrees = Vector3(0.0, float(position.x * 9.0), 68.0)
		parent.add_child(driftwood)

func _create_ridge_landmarks(parent: Node3D) -> void:
	for index in 5:
		var pillar := MeshInstance3D.new()
		var pillar_mesh := CylinderMesh.new()
		pillar_mesh.top_radius = 0.35 + float(index % 2) * 0.16
		pillar_mesh.bottom_radius = 0.58 + float(index % 3) * 0.12
		pillar_mesh.height = 2.2 + float(index % 2) * 0.85
		pillar_mesh.radial_segments = 6
		pillar.mesh = pillar_mesh
		pillar.material_override = _material(Color("#404b50"), 0.92)
		pillar.position = Vector3(-11.0 + float(index) * 5.0, pillar_mesh.height * 0.5 - 0.08, -7.0 + float(index % 2) * 1.5)
		pillar.rotation_degrees.z = float(index - 2) * 4.0
		parent.add_child(pillar)
	for position in [Vector3(-1.0, 0.0, -6.0), Vector3(7.0, 0.0, 5.5)]:
		var crystal := MeshInstance3D.new()
		var crystal_mesh := PrismMesh.new()
		crystal_mesh.size = Vector3(0.55, 1.8, 0.55)
		crystal.mesh = crystal_mesh
		crystal.material_override = _material(Color("#f19b61"), 0.32, false, true)
		crystal.position = position + Vector3(0.0, 0.9, 0.0)
		crystal.rotation_degrees.y = 18.0
		parent.add_child(crystal)

func _create_desert_landmarks(parent: Node3D) -> void:
	_add_sourced_model(parent, _tree_asset_path(parent.name), 0.64, Vector3(-10.0, 0.08, -2.0))
	_add_sourced_model(parent, _tree_asset_path(parent.name), 0.52, Vector3(11.0, 0.08, 5.5))
	for index in 6:
		var dune := MeshInstance3D.new()
		dune.mesh = _sphere_mesh(1.7, 1.15, 12, 6)
		dune.material_override = _material(Color("#d9a16b"), 1.0)
		dune.scale = Vector3(1.8, 0.45, 0.85)
		dune.position = Vector3(-11.0 + float(index % 3) * 10.0, 0.35, -6.5 + float(index / 3) * 10.0)
		parent.add_child(dune)
	for position in [Vector3(3.0, 0.0, -5.0), Vector3(-7.0, 0.0, 6.5), Vector3(10.0, 0.0, 6.0)]:
		var shard := MeshInstance3D.new()
		var shard_mesh := PrismMesh.new()
		shard_mesh.size = Vector3(0.38, 1.4, 0.38)
		shard.mesh = shard_mesh
		shard.material_override = _material(Color("#e78372"), 0.26, false, true)
		shard.position = position + Vector3(0.0, 0.7, 0.0)
		shard.rotation_degrees = Vector3(0.0, 28.0, -12.0)
		parent.add_child(shard)

func _create_dungeon_landmarks(parent: Node3D) -> void:
	_add_sourced_model(parent, _tree_asset_path(parent.name), 0.58, Vector3(-8.5, 0.08, 2.0))
	_add_sourced_model(parent, _tree_asset_path(parent.name), 0.48, Vector3(8.5, 0.08, -1.0))
	for position in [Vector3(-11.0, 0.0, -7.0), Vector3(11.0, 0.0, -7.0), Vector3(-11.0, 0.0, 7.0), Vector3(11.0, 0.0, 7.0)]:
		var pillar := MeshInstance3D.new()
		var pillar_mesh := BoxMesh.new()
		pillar_mesh.size = Vector3(0.7, 3.3, 0.7)
		pillar.mesh = pillar_mesh
		pillar.material_override = _material(Color("#4b5660"), 0.96)
		pillar.position = position + Vector3(0.0, 1.65, 0.0)
		parent.add_child(pillar)
		var torch := MeshInstance3D.new()
		torch.mesh = _sphere_mesh(0.22, 0.58, 8, 5)
		torch.material_override = _material(Color("#f0a467"), 0.38, false, true)
		torch.position = position + Vector3(0.0, 3.35, 0.0)
		parent.add_child(torch)
		animated_beacons.append(torch)
	var altar := MeshInstance3D.new()
	var altar_mesh := BoxMesh.new()
	altar_mesh.size = Vector3(3.0, 0.45, 2.2)
	altar.mesh = altar_mesh
	altar.material_override = _material(Color("#5d4d76"), 0.82)
	altar.position = Vector3(0.0, 0.24, -6.0)
	parent.add_child(altar)

func _dress_expedition_edges(parent: Node3D, route_id: String) -> void:
	var edge_positions := [
		Vector3(-18.0, 0.08, -12.0), Vector3(-11.0, 0.08, -14.0),
		Vector3(0.0, 0.08, -14.0), Vector3(11.0, 0.08, -14.0),
		Vector3(18.0, 0.08, -10.0), Vector3(18.0, 0.08, 10.0),
		Vector3(9.0, 0.08, 14.0), Vector3(-4.0, 0.08, 14.0),
		Vector3(-16.0, 0.08, 11.0), Vector3(-19.0, 0.08, 1.0),
	]
	var asset := "res://assets/quaternius-stylized-nature/glTF/RockPath_Round_Wide.gltf"
	var scale_value := 0.34
	match route_id:
		"Sunlit Beach":
			asset = "res://assets/quaternius-stylized-nature/glTF/RockPath_Round_Wide.gltf"
			scale_value = 0.3
		"Ember Ridge":
			asset = "res://assets/quaternius-stylized-nature/glTF/Rock_Medium_2.gltf"
			scale_value = 0.42
		"Glass Desert":
			asset = "res://assets/quaternius-stylized-nature/glTF/DeadTree_5.gltf"
			scale_value = 0.46
		"Sunken Dungeon":
			asset = "res://assets/quaternius-stylized-nature/glTF/DeadTree_5.gltf"
			scale_value = 0.42
	for index in edge_positions.size():
		_add_sourced_model(parent, asset, scale_value + float(index % 2) * 0.06, edge_positions[index])

func _create_map_identity(parent: Node3D, route_id: String, accent: Color) -> void:
	# These authored silhouettes make each destination readable before the HUD
	# tells the player where they are. They are deliberately assembled from the
	# licensed CC0 nature kit plus simple toon geometry, so the map can keep its
	# cozy anime language without becoming a wall of debug labels.
	var identity := Node3D.new()
	identity.name = "MapIdentity"
	identity.set_meta("route_id", route_id)
	parent.add_child(identity)
	var title := _label3d("", 0.17, palette["cream"])
	title.name = "IdentityTitle"
	title.position = Vector3(0.0, 1.15, 6.0)
	identity.add_child(title)
	match route_id:
		"Sunlit Beach":
			title.text = "TIDE LINE\nREAD THE WATER"
			_create_path(identity, Vector3(0.0, 0.055, -8.0), Vector3(29.0, 0.06, 4.5), Color("#3eabb4"))
			for index in 7:
				var foam := MeshInstance3D.new()
				foam.name = "TideFoam_%d" % index
				foam.mesh = _sphere_mesh(1.25, 0.05, 12, 4)
				foam.material_override = _material(Color("#d9f3df"), 0.25, false, true)
				foam.scale = Vector3(1.6, 1.0, 0.32)
				foam.position = Vector3(-11.5 + float(index) * 3.8, 0.12, -6.9 + sin(float(index)) * 0.25)
				identity.add_child(foam)
				animated_water.append(foam)
			for position in [Vector3(-10.8, 0.08, -5.6), Vector3(-4.6, 0.08, -6.2), Vector3(5.8, 0.08, -5.8), Vector3(10.4, 0.08, -6.4)]:
				_add_sourced_model(identity, "res://assets/quaternius-stylized-nature/glTF/RockPath_Round_Wide.gltf", 0.28, position)
			for position in [Vector3(-8.6, 0.08, -4.6), Vector3(7.6, 0.08, -4.9)]:
				_add_sourced_model(identity, "res://assets/quaternius-stylized-nature/glTF/Flower_4_Group.gltf", 0.34, position)
		"Ember Ridge":
			title.text = "EMBER RIDGE\nFOLLOW THE HOT STONE"
			for index in 5:
				var cliff := Node3D.new()
				cliff.name = "RidgeOutcrop_%d" % index
				cliff.position = Vector3(-12.0 + float(index) * 6.0, 0.0, -7.5 + float(index % 2) * 14.0)
				identity.add_child(cliff)
				_add_sourced_model(cliff, "res://assets/quaternius-stylized-nature/glTF/Rock_Medium_%d.gltf" % (2 + index % 2), 0.52 + float(index % 2) * 0.12, Vector3.ZERO)
			var heat_marker := _label3d("ASHFALL\nSTAY MOVING", 0.14, Color("#ffd39e"))
			heat_marker.position = Vector3(0.0, 0.58, -6.4)
			identity.add_child(heat_marker)
			for position in [Vector3(-1.6, 0.08, -6.5), Vector3(7.2, 0.08, 5.4)]:
				_add_sourced_model(identity, "res://assets/quaternius-stylized-nature/glTF/Rock_Medium_3.gltf", 0.34, position)
		"Glass Desert":
			title.text = "GLASS DESERT\nCHASE THE SHADE"
			_create_desert_shade_shelter(identity)
			for position in [Vector3(-10.0, 0.08, -2.0), Vector3(11.0, 0.08, 5.5), Vector3(0.0, 0.08, 7.0)]:
				_add_sourced_model(identity, "res://assets/quaternius-stylized-nature/glTF/DeadTree_4.gltf", 0.52, position)
			for index in 5:
				var heat := MeshInstance3D.new()
				heat.name = "HeatShimmer_%d" % index
				heat.mesh = _sphere_mesh(0.42, 1.6, 8, 5)
				heat.material_override = _material(Color("#ffd08c"), 0.38, false, true)
				heat.position = Vector3(-8.0 + float(index) * 4.0, 0.8, 5.6 - float(index % 2) * 8.0)
				heat.scale = Vector3(0.35, 1.0, 0.35)
				identity.add_child(heat)
				animated_beacons.append(heat)
			for position in [Vector3(-4.6, 0.08, -4.8), Vector3(5.4, 0.08, -4.4), Vector3(8.8, 0.08, 2.7)]:
				_add_sourced_model(identity, "res://assets/quaternius-stylized-nature/glTF/RockPath_Round_Thin.gltf", 0.42, position)
		"Sunken Dungeon":
			title.text = "SUNKEN DUNGEON\nKEEP THE TORCHES LIT"
			_create_path(identity, Vector3(0.0, 0.055, -7.9), Vector3(25.0, 0.06, 3.8), Color("#344452"))
			for index in 6:
				var torch := MeshInstance3D.new()
				torch.name = "DungeonTorch_%d" % index
				torch.mesh = _sphere_mesh(0.18, 0.48, 8, 5)
				torch.material_override = _material(Color("#ffc07d"), 0.3, false, true)
				torch.position = Vector3(-10.0 + float(index) * 4.0, 1.65, -7.1)
				identity.add_child(torch)
				animated_beacons.append(torch)
			for position in [Vector3(-10.5, 0.08, 0.8), Vector3(10.5, 0.08, -0.8), Vector3(-6.2, 0.08, 6.2), Vector3(6.2, 0.08, 6.2)]:
				_add_sourced_model(identity, "res://assets/quaternius-stylized-nature/glTF/RockPath_Round_Wide.gltf", 0.38, position)

func _create_desert_shade_shelter(parent: Node3D) -> void:
	# A shelter is a navigable place, not a status-effect label. Its Area3D is
	# also used by the hazard loop, so the player can read the relief spatially
	# and use it as a real pause point while deciding whether to push on.
	var shade := Area3D.new()
	shade.name = "ShadeVolume"
	shade.position = Vector3(-1.5, 0.0, 2.8)
	shade.set_meta("shelter_kind", "desert_shade")
	shade.set_meta("radius", 3.2)
	parent.add_child(shade)
	var collision := CollisionShape3D.new()
	collision.name = "ShadeCollision"
	var shade_shape := BoxShape3D.new()
	shade_shape.size = Vector3(5.8, 2.8, 4.6)
	collision.shape = shade_shape
	collision.position.y = 1.35
	shade.add_child(collision)
	var canopy := MeshInstance3D.new()
	canopy.name = "CanvasCanopy"
	var canopy_mesh := BoxMesh.new()
	canopy_mesh.size = Vector3(5.8, 0.18, 4.6)
	canopy.mesh = canopy_mesh
	canopy.material_override = _material(Color("#6d5b55"), 0.9)
	canopy.position.y = 2.55
	shade.add_child(canopy)
	for side in [-1.0, 1.0]:
		for depth in [-1.0, 1.0]:
			var post := MeshInstance3D.new()
			post.name = "ShadePost_%s_%s" % [side, depth]
			var post_mesh := CylinderMesh.new()
			post_mesh.top_radius = 0.10
			post_mesh.bottom_radius = 0.14
			post_mesh.height = 2.45
			post_mesh.radial_segments = 7
			post.mesh = post_mesh
			post.material_override = _material(palette["wood_dark"], 0.96)
			post.position = Vector3(side * 2.55, 1.22, depth * 1.95)
			shade.add_child(post)
	var shade_label := _label3d("OASIS SHADE\nHEAT PRESSURE PAUSED", 0.15, palette["cream"])
	shade_label.name = "ShadeLabel"
	shade_label.position = Vector3(0.0, 3.05, 0.0)
	shade.add_child(shade_label)

func _create_route_pressure_visual(parent: Node3D, route_id: String, accent: Color) -> void:
	var pressure := Node3D.new()
	pressure.name = "RoutePressure"
	pressure.visible = false
	parent.add_child(pressure)
	var ring := MeshInstance3D.new()
	ring.name = "PressureRing"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.62
	ring_mesh.outer_radius = 0.78
	ring.mesh = ring_mesh
	ring.material_override = _material(accent.lightened(0.18), 0.25, false, true)
	ring.position = Vector3(0.0, 0.12, 0.0)
	pressure.add_child(ring)
	var label := _label3d("", 0.14, palette["cream"])
	label.name = "PressureLabel"
	label.position = Vector3(0.0, 0.95, 0.0)
	pressure.add_child(label)
	var blocker := StaticBody3D.new()
	blocker.name = "PressureBlocker"
	blocker.position = Vector3(0.0, 0.62, 5.9)
	blocker.visible = false
	var blocker_mesh := BoxMesh.new()
	var blocker_color := accent.darkened(0.18)
	match route_id:
		"Sunlit Beach":
			blocker_mesh.size = Vector3(3.8, 1.0, 0.72)
			blocker_color = Color("#4babb4")
		"Ember Ridge":
			blocker_mesh.size = Vector3(3.3, 1.6, 0.9)
			blocker_color = Color("#6d6262")
		"Glass Desert":
			blocker_mesh.size = Vector3(3.6, 1.1, 0.62)
			blocker_color = Color("#c98f63")
		"Sunken Dungeon":
			blocker_mesh.size = Vector3(4.0, 1.3, 0.9)
			blocker_color = Color("#456477")
	var blocker_visual := MeshInstance3D.new()
	blocker_visual.name = "PressureBarrierVisual"
	blocker_visual.mesh = blocker_mesh
	blocker_visual.material_override = _material(blocker_color, 0.62, false, true)
	blocker_visual.position.y = 0.0
	blocker.add_child(blocker_visual)
	var blocker_collision := CollisionShape3D.new()
	blocker_collision.name = "PressureCollision"
	var blocker_shape := BoxShape3D.new()
	blocker_shape.size = blocker_mesh.size
	blocker_collision.shape = blocker_shape
	blocker_collision.disabled = true
	blocker.add_child(blocker_collision)
	pressure.add_child(blocker)
	pressure.set_meta("route_id", route_id)

func _create_expedition_route_landmarks(parent: Node3D, route_id: String, accent: Color) -> void:
	# Every non-forest expedition gets the same readable spatial language as the
	# Whisperwood fork: an entry marker, two visible approaches, a physical
	# blocker, and a branch capstone. The content table decides what the branch
	# means; this function only authors the player-facing space.
	var route := Node3D.new()
	route.name = "ExpeditionRoute"
	route.set_meta("route_id", route_id)
	parent.add_child(route)
	_create_route_pressure_visual(route, route_id, accent)
	_create_expedition_return_causeway(route, accent)
	_create_path(route, Vector3(0.0, 0.045, -1.9), Vector3(3.4, 0.07, 1.0), accent.darkened(0.18))
	_create_path(route, Vector3(-3.5, 0.045, -2.85), Vector3(5.8, 0.07, 1.0), accent.darkened(0.26))
	_create_path(route, Vector3(3.5, 0.045, -2.85), Vector3(5.8, 0.07, 1.0), accent.darkened(0.26))
	var options: Array = ContentRegistry.expedition_branch_ids(route_id)
	if options.size() < 2:
		return
	var marker := StationScript.new() as Node3D
	marker.name = "RouteChoiceMarker"
	marker.set("world", self)
	marker.set("station_id", "map_branch")
	marker.set_meta("route_id", route_id)
	marker.add_to_group("interactable")
	marker.position = Vector3(0.0, 0.0, -1.9)
	route.add_child(marker)
	for side in [-1.0, 1.0]:
		_structure_box(marker, "ChoicePost_%s" % side, Vector3(0.16, 1.55, 0.16), Vector3(side * 1.25, 0.78, 0.0), accent.darkened(0.4))
	_structure_box(marker, "ChoiceBeam", Vector3(2.7, 0.16, 0.16), Vector3(0.0, 1.48, 0.0), accent.darkened(0.4))
	var marker_label := _label3d("ROUTE FORK\nCHOOSE A TRAIL", 0.15, palette["cream"])
	marker_label.name = "RouteChoiceLabel"
	marker_label.position = Vector3(0.0, 1.92, 0.0)
	marker.add_child(marker_label)
	for index in 2:
		var branch_id := str(options[index])
		var definition: Dictionary = ContentRegistry.expedition_route_definition(route_id, branch_id)
		var side := -1.0 if index == 0 else 1.0
		_create_route_barrier(route, Vector3(side * 3.45, 0.0, -2.85), branch_id, accent if index == 0 else accent.lightened(0.16))
		var barrier := route.get_node_or_null("WhisperwoodBarrier_" + branch_id.capitalize()) as StaticBody3D
		if barrier != null:
			barrier.name = "RouteBarrier_" + branch_id.capitalize()
		var capstone := StationScript.new() as Node3D
		capstone.name = "RouteCapstone_" + branch_id.capitalize()
		capstone.set("world", self)
		capstone.set("station_id", "map_capstone")
		capstone.set_meta("route_id", route_id)
		capstone.set_meta("route_branch", branch_id)
		capstone.add_to_group("interactable")
		capstone.position = Vector3(side * 8.1, 0.0, -4.8)
		route.add_child(capstone)
		_structure_box(capstone, "CapstoneStone", Vector3(1.2, 0.45, 1.0), Vector3(0.0, 0.24, 0.0), palette["stone"])
		_structure_box(capstone, "CapstoneSigil", Vector3(0.55, 0.10, 0.18), Vector3(0.0, 0.62, 0.0), accent)
		var capstone_label := _label3d(str(definition.get("label", branch_id.to_upper())) + "\nOBJECTIVE", 0.15, palette["cream"])
		capstone_label.name = "CapstoneLabel"
		capstone_label.position = Vector3(0.0, 1.18, 0.0)
		capstone.add_child(capstone_label)
	var route_title := _label3d(route_id.to_upper() + "\nTWO TRAILS, ONE RETURN", 0.14, palette["cream"])
	route_title.name = "RouteTitle"
	route_title.position = Vector3(0.0, 1.8, -0.8)
	route.add_child(route_title)

func _create_expedition_return_causeway(route: Node3D, accent: Color) -> void:
	# Every later expedition has a physical return beat. It remains inert until
	# the branch capstone opens the shortcut, then the same world-space marker is
	# used by the route progress command and the extraction contract.
	var causeway := Node3D.new()
	causeway.name = "ReturnCauseway"
	causeway.position = Vector3(0.0, 0.0, 8.7)
	causeway.set_meta("checkpoint_radius", 2.8)
	route.add_child(causeway)
	_create_path(causeway, Vector3(0.0, 0.045, 0.0), Vector3(3.0, 0.08, 3.2), accent.darkened(0.12))
	for side in [-1.0, 1.0]:
		_structure_box(causeway, "CausewayPost_%s" % side, Vector3(0.16, 1.35, 0.16), Vector3(side * 1.15, 0.70, 0.0), accent.darkened(0.34))
		_structure_box(causeway, "CausewayRail_%s" % side, Vector3(0.12, 0.12, 2.55), Vector3(side * 1.15, 1.22, 0.0), accent.darkened(0.28))
	for plank_index in 5:
		var plank_z := -1.0 + float(plank_index) * 0.5
		_structure_box(causeway, "CausewayPlank_%02d" % plank_index, Vector3(2.15, 0.10, 0.28), Vector3(0.0, 0.13, plank_z), palette["wood_dark"], Vector3(0.0, float(plank_index % 2) * 2.0, 0.0))
	var trigger := Area3D.new()
	trigger.name = "ReturnCausewayTrigger"
	trigger.collision_layer = 0
	trigger.collision_mask = 0
	var trigger_shape := CollisionShape3D.new()
	var trigger_cylinder := CylinderShape3D.new()
	trigger_cylinder.radius = 2.8
	trigger_cylinder.height = 0.2
	trigger_shape.shape = trigger_cylinder
	trigger_shape.position.y = 0.1
	trigger.add_child(trigger_shape)
	causeway.add_child(trigger)
	var label := _label3d("RETURN CAUSEWAY", 0.14, palette["cream"])
	label.name = "ReturnCausewayLabel"
	label.position = Vector3(0.0, 1.72, 0.0)
	causeway.add_child(label)

func _refresh_expedition_routes() -> void:
	if session == null:
		return
	for zone in [beach_zone, mountain_zone, desert_zone, dungeon_zone]:
		if zone == null:
			continue
		var route := zone.get_node_or_null("ExpeditionRoute") as Node3D
		if route == null:
			continue
		var route_id := str(route.get_meta("route_id", ""))
		var run: Dictionary = session.get("expedition_run")
		var active := str(run.get("status", "none")) == "active" and str(run.get("biome_id", "")) == route_id
		var branch_id := str(run.get("branch_id", ""))
		var objective_complete := bool(run.get("objective_complete", false))
		var objective_progress := int(run.get("objective_progress", 0))
		var objective_target := int(run.get("objective_target", 0))
		var objective_counter := "%d/%d" % [objective_progress, objective_target] if objective_target > 0 else "—"
		var route_title := route.get_node_or_null("RouteTitle") as Label3D
		if route_title != null:
			route_title.text = route_id.to_upper() + ("\nCHOOSE A TRAIL" if active and branch_id.is_empty() else ("\nCAPSTONE READY %s" % objective_counter if active and objective_complete else ("\nOBJECTIVE %s" % objective_counter if active else "\nTWO TRAILS, ONE RETURN")))
		var return_causeway := route.get_node_or_null("ReturnCauseway") as Node3D
		if return_causeway != null:
			return_causeway.visible = not active or bool(run.get("shortcut_open", false))
			var return_label := return_causeway.get_node_or_null("ReturnCausewayLabel") as Label3D
			if return_label != null:
				return_label.text = "RETURN CAUSEWAY\nCROSSED" if bool(run.get("return_checkpoint_crossed", false)) else "RETURN CAUSEWAY\nCROSS AFTER CAPSTONE"
		var pressure := route.get_node_or_null("RoutePressure") as Node3D
		if pressure != null:
			var pressure_active := active and bool(run.get("stake_active", false))
			pressure.visible = pressure_active
			var pressure_blocker := pressure.get_node_or_null("PressureBlocker") as StaticBody3D
			if pressure_blocker != null:
				pressure_blocker.visible = pressure_active
				var pressure_collision := pressure_blocker.get_node_or_null("PressureCollision") as CollisionShape3D
				if pressure_collision != null:
					pressure_collision.disabled = not pressure_active
			var pressure_label := pressure.get_node_or_null("PressureLabel") as Label3D
			if pressure_label != null:
				var pressure_copy := {
					"Sunlit Beach": "TIDE RISING  |  RETURN",
					"Ember Ridge": "ASHFALL  |  RETURN",
					"Glass Desert": "HEAT BUILDING  |  RETURN",
					"Sunken Dungeon": "WATER RISING  |  RETURN",
				}
				pressure_label.text = str(pressure_copy.get(route_id, "THE ROUTE IS SHIFTING  |  RETURN"))
		var choice_marker := route.get_node_or_null("RouteChoiceMarker") as Node3D
		if choice_marker != null:
			choice_marker.visible = active and branch_id.is_empty()
			var choice_label := choice_marker.get_node_or_null("RouteChoiceLabel") as Label3D
			if choice_label != null:
				choice_label.text = "ROUTE FORK\nCHOOSE A TRAIL" if branch_id.is_empty() else "ROUTE COMMITTED\n" + branch_id.to_upper()
		for child in route.get_children():
			var barrier := child as StaticBody3D
			if barrier != null and barrier.has_meta("blocked_branch"):
				var blocked_branch := str(barrier.get_meta("blocked_branch", ""))
				var blocked := active and not branch_id.is_empty() and blocked_branch != branch_id
				barrier.visible = blocked
				var collision := barrier.get_node_or_null("BarrierCollision") as CollisionShape3D
				if collision != null:
					collision.disabled = not blocked
			var capstone := child as Node3D
			if capstone == null or str(capstone.get("station_id")) != "map_capstone":
				continue
			var capstone_branch := str(capstone.get_meta("route_branch", ""))
			capstone.visible = active and (branch_id.is_empty() or capstone_branch == branch_id)
			var capstone_label := capstone.get_node_or_null("CapstoneLabel") as Label3D
			if capstone_label != null:
				var definition := ContentRegistry.expedition_route_definition(route_id, capstone_branch)
				capstone_label.text = str(definition.get("label", capstone_branch.to_upper())) + ("\nCLAIM CAPSTONE" if objective_complete and capstone_branch == branch_id and not bool(run.get("cache_claimed", false)) else ("\nSECURED" if bool(run.get("cache_claimed", false)) and capstone_branch == branch_id else ("\nOBJECTIVE %s" % objective_counter)))

func _build_player() -> void:
	player = PlayerScript.new() as CharacterBody3D
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.name = "Player"
	player.set("world", self)
	player.position = Vector3(0.0, 1.0, 4.0)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.7
	collision.shape = capsule
	player.add_child(collision)
	player_attack_shape = SphereShape3D.new()
	# The query is centered just ahead of the player's feet pivot; this radius
	# covers the illustrated blade reach while still requiring the facing cone
	# below, so a side/back contact cannot be silently counted as a hit.
	player_attack_shape.radius = 1.45
	var visual := Node3D.new()
	visual.name = "Visual"
	player.add_child(visual)
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.34
	body_mesh.height = 1.12
	body_mesh.radial_segments = 10
	body_mesh.rings = 4
	body.mesh = body_mesh
	body.material_override = _material(Color("#d98467"), 0.82)
	body.position.y = 1.02
	visual.add_child(body)
	var head := MeshInstance3D.new()
	head.mesh = _sphere_mesh(0.42, 0.84, 12, 8)
	head.material_override = _material(Color("#f0bd8e"), 0.9)
	head.position.y = 1.66
	visual.add_child(head)
	var hair := MeshInstance3D.new()
	hair.name = "SoftHairCap"
	hair.mesh = _sphere_mesh(0.43, 0.74, 12, 7)
	hair.material_override = _material(Color("#4d4050"), 0.88)
	hair.position = Vector3(0.0, 2.00, 0.03)
	hair.scale = Vector3(1.02, 0.42, 0.96)
	visual.add_child(hair)
	for eye_data in [["EyeLeft", -0.14], ["EyeRight", 0.14]]:
		var eye := MeshInstance3D.new()
		eye.name = str(eye_data[0])
		eye.mesh = _sphere_mesh(0.055, 0.11, 8, 4)
		eye.material_override = _material(Color("#332f3d"), 0.96, false, true)
		eye.position = Vector3(float(eye_data[1]), 1.72, 0.365)
		visual.add_child(eye)
	var scarf := MeshInstance3D.new()
	scarf.name = "SoftScarf"
	scarf.mesh = _box_mesh(Vector3(0.66, 0.14, 0.42))
	scarf.material_override = _material(Color("#e39a78"), 0.88)
	scarf.position = Vector3(0.0, 1.38, 0.02)
	visual.add_child(scarf)
	var satchel := MeshInstance3D.new()
	satchel.name = "TravelSatchel"
	satchel.mesh = _sphere_mesh(0.22, 0.42, 9, 5)
	satchel.material_override = _material(Color("#8c6049"), 0.92)
	satchel.position = Vector3(-0.32, 1.10, -0.30)
	satchel.scale = Vector3(0.82, 1.0, 0.55)
	visual.add_child(satchel)
	var hat := MeshInstance3D.new()
	var hat_mesh := CylinderMesh.new()
	hat_mesh.top_radius = 0.12
	hat_mesh.bottom_radius = 0.47
	hat_mesh.height = 0.34
	hat_mesh.radial_segments = 8
	hat.mesh = hat_mesh
	hat.material_override = _material(Color("#345b4c"), 0.72)
	hat.position.y = 2.12
	visual.add_child(hat)
	var cloak := MeshInstance3D.new()
	var cloak_mesh := PrismMesh.new()
	cloak_mesh.size = Vector3(0.78, 1.15, 0.32)
	cloak.mesh = cloak_mesh
	cloak.material_override = _material(Color("#425d72"), 0.88)
	cloak.position = Vector3(0.0, 1.03, 0.35)
	visual.add_child(cloak)
	for limb_data in [["LegLeft", -0.18, Color("#496579")], ["LegRight", 0.18, Color("#496579")]]:
		var leg := Node3D.new()
		leg.name = str(limb_data[0])
		leg.position = Vector3(float(limb_data[1]), 0.58, 0.0)
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.12
		leg_mesh.height = 0.68
		leg_mesh.radial_segments = 8
		leg_mesh.rings = 3
		var leg_visual := MeshInstance3D.new()
		leg_visual.mesh = leg_mesh
		leg_visual.material_override = _material(limb_data[2], 0.86)
		leg_visual.position.y = -0.12
		leg.add_child(leg_visual)
		var boot := MeshInstance3D.new()
		boot.mesh = _sphere_mesh(0.15, 0.22, 8, 4)
		boot.material_override = _material(palette["wood_dark"], 0.9)
		boot.position = Vector3(0.0, -0.43, -0.08)
		leg.add_child(boot)
		visual.add_child(leg)
	for limb_data in [["ArmLeft", -0.42, Color("#d98467")], ["ArmRight", 0.42, Color("#d98467")]]:
		var arm := Node3D.new()
		arm.name = str(limb_data[0])
		arm.position = Vector3(float(limb_data[1]), 1.38, 0.0)
		var arm_mesh := CapsuleMesh.new()
		arm_mesh.radius = 0.105
		arm_mesh.height = 0.65
		arm_mesh.radial_segments = 8
		arm_mesh.rings = 3
		var arm_visual := MeshInstance3D.new()
		arm_visual.mesh = arm_mesh
		arm_visual.material_override = _material(limb_data[2], 0.84)
		arm_visual.position.y = -0.28
		arm.add_child(arm_visual)
		visual.add_child(arm)
	var weapon_rig := Node3D.new()
	weapon_rig.name = "WeaponRig"
	weapon_rig.position = Vector3(0.58, 1.17, -0.12)
	visual.add_child(weapon_rig)
	var weapon := MeshInstance3D.new()
	weapon.name = "StarterBlade"
	var weapon_mesh := BoxMesh.new()
	weapon_mesh.size = Vector3(0.12, 0.85, 0.16)
	weapon.mesh = weapon_mesh
	weapon.material_override = _material(Color("#c9d8d0"), 0.25, false, true)
	weapon.position = Vector3(0.0, -0.27, -0.22)
	weapon.rotation_degrees.x = -22.0
	weapon_rig.add_child(weapon)
	var grip := MeshInstance3D.new()
	grip.mesh = _sphere_mesh(0.12, 0.24, 7, 4)
	grip.material_override = _material(palette["wood_dark"], 0.95)
	grip.position = Vector3(0.0, 0.2, 0.02)
	weapon_rig.add_child(grip)
	var shadow := MeshInstance3D.new()
	shadow.name = "LegacyContactShadow"
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.62
	shadow_mesh.bottom_radius = 0.62
	shadow_mesh.height = 0.018
	shadow_mesh.radial_segments = 24
	shadow.mesh = shadow_mesh
	shadow.material_override = _material(Color(0.03, 0.06, 0.05, 0.32), 1.0, true)
	shadow.position.y = 0.02
	visual.add_child(shadow)
	_add_illustrated_player_sprite(visual)
	var combat_slash := MeshInstance3D.new()
	combat_slash.name = "CombatSlash"
	combat_slash.mesh = _box_mesh(Vector3(0.12, 0.08, 1.45))
	combat_slash.material_override = _material(Color("#ffe0a6"), 0.24, true, true)
	combat_slash.position = Vector3(0.0, 1.10, -0.80)
	combat_slash.rotation_degrees.x = -18.0
	combat_slash.visible = false
	combat_slash.set_meta("visual_anchor", "player_attack_hand")
	visual.add_child(combat_slash)
	var gather_tool := MeshInstance3D.new()
	gather_tool.name = "GatherTool"
	gather_tool.mesh = _box_mesh(Vector3(0.14, 0.12, 1.02))
	gather_tool.material_override = _material(palette["wood_dark"], 0.82)
	gather_tool.position = Vector3(0.50, 1.10, -0.34)
	gather_tool.rotation_degrees = Vector3(-28.0, 0.0, -28.0)
	gather_tool.visible = false
	gather_tool.set_meta("visual_anchor", "player_gather_hand")
	visual.add_child(gather_tool)
	add_child(player)
	for guardian_node in get_tree().get_nodes_in_group("guardian"):
		var guardian := guardian_node as CharacterBody3D
		if guardian != null:
			guardian.set("target", player)
	var listener := AudioListener3D.new()
	listener.name = "PlayerAudioListener"
	listener.position = Vector3(0.0, 1.0, 0.0)
	player.add_child(listener)
	listener.current = true
	camera = Camera3D.new()
	camera.name = "IsometricCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = SANCTUARY_CAMERA_SIZE
	camera.set_meta("camera_contract", {
		"yaw": "diagonal_southeast",
		"pitch_degrees": 43.301,
		"sanctuary_size": SANCTUARY_CAMERA_SIZE,
	})
	camera.current = true
	add_child(camera)
	interaction_marker = MeshInstance3D.new()
	interaction_marker.name = "InteractionMarker"
	var marker_mesh := TorusMesh.new()
	marker_mesh.inner_radius = 0.78
	marker_mesh.outer_radius = 0.88
	marker_mesh.rings = 12
	marker_mesh.ring_segments = 32
	interaction_marker.mesh = marker_mesh
	interaction_marker.material_override = _material(palette["cream"], 0.72, true, true)
	interaction_marker.position.y = 0.05
	interaction_marker.visible = false
	add_child(interaction_marker)
	move_target_marker = MeshInstance3D.new()
	move_target_marker.name = "MoveTargetMarker"
	var move_marker_mesh := TorusMesh.new()
	move_marker_mesh.inner_radius = 0.18
	move_marker_mesh.outer_radius = 0.27
	move_marker_mesh.rings = 8
	move_marker_mesh.ring_segments = 20
	move_target_marker.mesh = move_marker_mesh
	move_target_marker.material_override = _material(palette["leaf"], 0.55, true, true)
	move_target_marker.position.y = 0.045
	move_target_marker.visible = false
	add_child(move_target_marker)

func _add_illustrated_player_sprite(visual: Node3D) -> Sprite3D:
	if visual == null:
		return null
	var sheet := load(PLAYER_SPRITE_SHEET_PATH) as Texture2D
	if sheet == null:
		return null
	var sprite := Sprite3D.new()
	sprite.name = "IllustratedCharacter"
	var cell_width := float(sheet.get_width()) / 4.0
	var cell_height := float(sheet.get_height()) / 2.0
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(0.0, 0.0, cell_width, cell_height)
	atlas.filter_clip = true
	sprite.texture = atlas
	# The generated cells contain measured transparent padding below the boots.
	# Keep the artwork's feet at the player body's ground pivot and let the
	# CharacterBody3D remain the collision/interaction authority.
	sprite.centered = false
	sprite.offset = Vector2(-cell_width * 0.5, -18.0)
	sprite.pixel_size = PLAYER_ART_WORLD_HEIGHT / 392.0
	sprite.set_meta("visual_height_world_meters", PLAYER_ART_WORLD_HEIGHT)
	sprite.axis = Vector3.AXIS_Z
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.shaded = false
	sprite.no_depth_test = false
	sprite.sorting_use_aabb_center = false
	sprite.sorting_offset = 0.0
	sprite.set_meta("asset_id", "sanctuary/characters/wayfarer_direction_sheet")
	sprite.set_meta("animation_rows", {"idle": 0, "walk": 1})
	sprite.set_meta("direction_frames", 4)
	sprite.set_meta("cell_size", [cell_width, cell_height])
	sprite.set_meta("ground_pivot", [0.0, 0.0, 0.0])
	sprite.set_meta("sorting_anchor_mode", "feet")
	sprite.set_meta("sorting_anchor_space", "sprite_local")
	visual.add_child(sprite)
	# Keep the old procedural rig nodes alive for action/collision tests and
	# gameplay pose hooks, but remove their visible geometry so the authored
	# character sheet is the single Sanctuary-facing silhouette.
	for child in visual.get_children():
		if child == sprite:
			continue
		var child_node := child as Node3D
		if child_node != null:
			child_node.visible = false
	var contact_shadow := MeshInstance3D.new()
	contact_shadow.name = "IllustratedCharacterShadow"
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.56
	shadow_mesh.bottom_radius = 0.56
	shadow_mesh.height = 0.018
	shadow_mesh.radial_segments = 24
	contact_shadow.mesh = shadow_mesh
	contact_shadow.material_override = _material(Color(0.10, 0.15, 0.11, 0.28), 1.0, true)
	contact_shadow.position = Vector3(0.0, 0.02, 0.0)
	player.add_child(contact_shadow)
	return sprite

func _build_audio() -> void:
	audio_director = AudioDirectorScript.new() as Node
	audio_director.name = "AudioDirector"
	add_child(audio_director)

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)
	var root := Control.new()
	hud_root = root
	root.name = "HudRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	# Leave empty world space available to the desktop click-to-move path while
	# keeping the actual buttons/panels as normal mouse targets.
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.resized.connect(_layout_hud)
	canvas.add_child(root)
	hud_top_panel = _panel(Vector2(24, 22), Vector2(360, 190), palette["panel"])
	var top_panel := hud_top_panel
	root.add_child(top_panel)
	var top_box := VBoxContainer.new()
	hud_top_box = top_box
	top_box.position = Vector2(18, 14)
	top_box.size = Vector2(324, 162)
	top_box.add_theme_constant_override("separation", 5)
	top_panel.add_child(top_box)
	hud_title_label = _label("SANCTUARY", 24, palette["cream"])
	var title := hud_title_label
	top_box.add_child(title)
	zone_label = _label("Sanctuary", 16, palette["leaf"])
	top_box.add_child(zone_label)
	day_label = _label("Day 1  |  10:00", 14, palette["muted"])
	top_box.add_child(day_label)
	energy_bar = _bar(palette["leaf"], 24)
	top_box.add_child(energy_bar)
	health_bar = _bar(palette["danger"], 100)
	top_box.add_child(health_bar)
	status_label = _label("Gather close to nodes. Press E to interact.", 13, palette["muted"])
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top_box.add_child(status_label)
	weather_label = _label("Clear skies", 12, palette["muted"])
	top_box.add_child(weather_label)
	hud_bag_panel = _panel(Vector2(24, 232), Vector2(360, 306), palette["panel"])
	var bag_panel := hud_bag_panel
	root.add_child(bag_panel)
	inventory_label = _label("BANKED\nWood 0  Stone 0  Fiber 0\nCARGO  —", 12, palette["cream"])
	inventory_label.position = Vector2(18, 14)
	inventory_label.size = Vector2(324, 204)
	bag_panel.add_child(inventory_label)
	mastery_label = _label("LEVEL 1  |  AP 2\nFORAGING 0   FARMING 0   CRAFTING 0", 11, palette["muted"])
	mastery_label.position = Vector2(18, 222)
	mastery_label.size = Vector2(324, 68)
	bag_panel.add_child(mastery_label)
	hud_quest_panel = _panel(Vector2(400, 540), Vector2(360, 98), palette["panel"])
	var quest_panel := hud_quest_panel
	root.add_child(quest_panel)
	quest_label = _label("NOTICE BOARD\nReturn from an expedition with cargo.", 12, palette["cream"])
	quest_label.position = Vector2(18, 14)
	quest_label.size = Vector2(324, 74)
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_panel.add_child(quest_label)
	hud_right_panel = _panel(Vector2(990, 22), Vector2(266, 620), palette["panel"])
	var right_panel := hud_right_panel
	root.add_child(right_panel)
	hud_right_scroll = ScrollContainer.new()
	hud_right_scroll.position = Vector2(10, 10)
	hud_right_scroll.size = Vector2(246, 600)
	hud_right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_panel.add_child(hud_right_scroll)
	hud_right_box = VBoxContainer.new()
	var right_box := hud_right_box
	right_box.custom_minimum_size = Vector2(238, 0)
	right_box.add_theme_constant_override("separation", 4)
	hud_right_scroll.add_child(right_box)
	hud_action_panel = _panel(Vector2(990, 478), Vector2(266, 164), palette["panel"])
	hud_action_panel.name = "ContextActionPanel"
	root.add_child(hud_action_panel)
	hud_action_scroll = ScrollContainer.new()
	hud_action_scroll.position = Vector2(10, 10)
	hud_action_scroll.size = Vector2(246, 144)
	hud_action_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hud_action_panel.add_child(hud_action_scroll)
	hud_action_box = VBoxContainer.new()
	hud_action_box.custom_minimum_size = Vector2(238, 0)
	hud_action_box.add_theme_constant_override("separation", 4)
	hud_action_scroll.add_child(hud_action_box)
	pause_button = _button("Pause", _toggle_pause)
	right_box.add_child(pause_button)
	settings_button = _button("Settings", _toggle_settings)
	right_box.add_child(settings_button)
	destination_button = _button("Destination: Whisperwood", _cycle_expedition)
	hud_action_box.add_child(destination_button)
	explore_button = _button("Explore Whisperwood", _enter_selected_expedition)
	hud_action_box.add_child(explore_button)
	return_button = _button("Return to Sanctuary", _return_home)
	hud_action_box.add_child(return_button)
	interact_button = _button("Interact", _contextual_interact)
	hud_action_box.add_child(interact_button)
	attack_button = _button("Attack  [Space]", func() -> void: _player_attack(player))
	hud_action_box.add_child(attack_button)
	dodge_button = _button("Dodge  [Shift]", _player_dodge)
	hud_action_box.add_child(dodge_button)
	sleep_button = _button("Sleep / Advance Day  [R]", _sleep)
	hud_action_box.add_child(sleep_button)
	smelt_button = _button("Start Furnace", _toggle_furnace)
	hud_action_box.add_child(smelt_button)
	farm_button = _button("Garden Plot  [F]", func() -> void: farm_plot_interact(farm_plot))
	hud_action_box.add_child(farm_button)
	food_button = _button("Eat Bread  [G]", _eat_best_food)
	hud_action_box.add_child(food_button)
	water_button = _button("Drink Water  [H]", _drink_water)
	hud_action_box.add_child(water_button)
	livestock_button = _button("Livestock Pen", _livestock_contextual_action)
	hud_action_box.add_child(livestock_button)
	repair_button = _button("Repair Tools  [V]", _repair_tools)
	hud_action_box.add_child(repair_button)
	recipe_button = _button("Recipe: Plank  [Q]", _cycle_recipe_selection)
	hud_action_box.add_child(recipe_button)
	structure_button = _button("Place Rain Cistern  [B]", _toggle_structure_placement)
	hud_action_box.add_child(structure_button)
	blueprint_button = _button("Blueprint: Rain Cistern  [N]", _cycle_structure_selection)
	hud_action_box.add_child(blueprint_button)
	rotate_button = _button("Rotate Blueprint  [X]", _rotate_structure_placement)
	hud_action_box.add_child(rotate_button)
	build_button = _button("Build Workshop", _workshop_contextual_action)
	hud_action_box.add_child(build_button)
	utilities_button = _button("Open Ledger", _toggle_utilities)
	right_box.add_child(utilities_button)
	activity_button = _button("Log 25m Effort  [P]", _record_activity)
	right_box.add_child(activity_button)
	save_button = _button("Save Progress", _save_game)
	right_box.add_child(save_button)
	stat_button = _button("Spend Ability Point  [L]", _allocate_best_stat)
	right_box.add_child(stat_button)
	stat_cycle_button = _button("Stat: Strength  [O]", _cycle_stat_selection)
	right_box.add_child(stat_cycle_button)
	action_hint = _label("WASD / arrows move  |  E interact  |  Space attack  |  Shift dodge  |  G eat  |  Y food  |  Q recipe  |  B place\nChoose an expedition, bring discoveries home, then use the Archive to understand them.", 13, palette["muted"])
	action_hint.position = Vector2(24, 650)
	action_hint.size = Vector2(900, 50)
	root.add_child(action_hint)
	toast_label = _label("", 17, palette["cream"])
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.position = Vector2(350, 28)
	toast_label.size = Vector2(580, 48)
	toast_label.visible = false
	root.add_child(toast_label)
	var joystick := Control.new()
	hud_joystick = joystick
	joystick.name = "VirtualJoystick"
	joystick.set_script(JoystickScript)
	joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.position = Vector2(26, 526)
	joystick.size = Vector2(156, 156)
	joystick.visible = DisplayServer.is_touchscreen_available()
	root.add_child(joystick)
	joystick.vector_changed.connect(Callable(self, "_on_joystick_vector_changed"))
	_build_settings_panel(root)
	_build_reference_hud(root)
	_layout_hud()
	_apply_cozy_hud_theme()

func _build_reference_hud(root: Control) -> void:
	# The reference HUD is intentionally a gameplay layer, not a replacement for
	# the ledger. It keeps the world readable while exposing the four actions a
	# player repeats most often: interact, strike, dodge, and use supplies.
	reference_hud = Control.new()
	reference_hud.name = "ReferenceGameplayHUD"
	reference_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reference_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(reference_hud)

	reference_top_panel = _reference_panel(Color(0.055, 0.045, 0.045, 0.94), Color("#c39b5d"), 16)
	reference_top_panel.name = "ReferenceTopStatus"
	reference_hud.add_child(reference_top_panel)
	var top_row := HBoxContainer.new()
	top_row.name = "StatusHeaderRow"
	top_row.position = Vector2(12, 10)
	top_row.size = Vector2(680, 76)
	top_row.add_theme_constant_override("separation", 9)
	reference_top_panel.add_child(top_row)
	reference_portrait = TextureRect.new()
	reference_portrait.name = "ReferencePortrait"
	reference_portrait.custom_minimum_size = Vector2(68, 68)
	reference_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reference_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reference_portrait.texture = _reference_player_portrait_texture()
	top_row.add_child(reference_portrait)
	var identity_box := VBoxContainer.new()
	identity_box.name = "ReferenceIdentity"
	identity_box.custom_minimum_size = Vector2(210, 0)
	identity_box.add_theme_constant_override("separation", 2)
	top_row.add_child(identity_box)
	reference_name_label = _label("PRODEWTY", 19, Color("#fff0c6"))
	identity_box.add_child(reference_name_label)
	reference_level_label = _label("LV. 1  •  DAY 1", 11, Color("#d8bd82"))
	identity_box.add_child(reference_level_label)
	reference_zone_label = _label("SANCTUARY", 11, Color("#a8c68a"))
	identity_box.add_child(reference_zone_label)
	reference_objective_label = _label("NEXT  •  Notice Board", 10, Color("#f0c879"))
	reference_objective_label.name = "ReferenceObjective"
	reference_objective_label.clip_text = true
	identity_box.add_child(reference_objective_label)
	reference_health_bar = _reference_bar(Color("#c85b4f"), 100)
	identity_box.add_child(reference_health_bar)
	reference_energy_bar = _reference_bar(Color("#3e9ec6"), 24)
	identity_box.add_child(reference_energy_bar)
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_spacer)
	for button_data in [["✦", "Ledger", Callable(self, "_toggle_utilities")], ["⌂", "Map / routes", Callable(self, "_toggle_utilities")], ["Ⅱ", "Pause", Callable(self, "_toggle_pause")], ["×", "Settings", Callable(self, "_toggle_settings")]]:
		var top_button := _reference_icon_button(str(button_data[0]), str(button_data[1]), button_data[2] as Callable)
		reference_top_buttons.append(top_button)
		top_row.add_child(top_button)

	reference_stat_box = VBoxContainer.new()
	reference_stat_box.name = "ReferenceStatRail"
	reference_stat_box.add_theme_constant_override("separation", 7)
	reference_hud.add_child(reference_stat_box)
	for stat_data in [["Strength", "STR", "⚔"], ["Focus", "FOC", "✦"], ["health", "HP", "♥"], ["hydration", "H2O", "♦"], ["level", "LV", "★"]]:
		var pill := Panel.new()
		pill.custom_minimum_size = Vector2(124, 42)
		pill.add_theme_stylebox_override("panel", _reference_style(Color(0.07, 0.055, 0.05, 0.92), Color("#9c774d"), 14, 1))
		reference_stat_box.add_child(pill)
		var pill_row := HBoxContainer.new()
		pill_row.position = Vector2(9, 5)
		pill_row.size = Vector2(106, 32)
		pill_row.add_theme_constant_override("separation", 7)
		pill.add_child(pill_row)
		var icon_label := _label(str(stat_data[2]), 18, Color("#f0c879"))
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.custom_minimum_size = Vector2(26, 30)
		pill_row.add_child(icon_label)
		var stat_label := _label("%s  0" % str(stat_data[1]), 12, Color("#f5e7c5"))
		stat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		stat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pill_row.add_child(stat_label)
		reference_stat_labels[str(stat_data[0])] = stat_label

	reference_bottom_panel = _reference_panel(Color(0.055, 0.042, 0.038, 0.95), Color("#c39b5d"), 18)
	reference_bottom_panel.name = "ReferenceActionBelt"
	reference_hud.add_child(reference_bottom_panel)
	var bottom_box := VBoxContainer.new()
	bottom_box.name = "ActionBeltBox"
	bottom_box.position = Vector2(12, 9)
	bottom_box.size = Vector2(760, 118)
	bottom_box.add_theme_constant_override("separation", 6)
	reference_bottom_panel.add_child(bottom_box)
	var quick_row := HBoxContainer.new()
	quick_row.name = "QuickResourceRow"
	quick_row.custom_minimum_size = Vector2(0, 24)
	quick_row.add_theme_constant_override("separation", 10)
	bottom_box.add_child(quick_row)
	reference_context_button = _reference_action_button("INTERACT  [E]", Callable(self, "_contextual_interact"), 178)
	reference_context_button.name = "ReferenceContextButton"
	quick_row.add_child(reference_context_button)
	for quick_data in [["wood", "WOOD"], ["fiber", "FIBER"], ["stone", "STONE"], ["slime_gel", "GEL"]]:
		var quick_label := _label("%s  0" % str(quick_data[1]), 11, Color("#e7d3a3"))
		quick_label.custom_minimum_size = Vector2(78, 22)
		quick_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		quick_row.add_child(quick_label)
		reference_quick_labels[str(quick_data[0])] = quick_label
	var quick_spacer := Control.new()
	quick_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quick_row.add_child(quick_spacer)
	reference_cargo_text = _label("CARGO 0 / 12", 11, Color("#e7d3a3"))
	quick_row.add_child(reference_cargo_text)
	reference_slot_box = HBoxContainer.new()
	reference_slot_box.name = "ReferenceSlotBox"
	reference_slot_box.add_theme_constant_override("separation", 6)
	var slot_scroll := ScrollContainer.new()
	slot_scroll.name = "ReferenceSlotScroll"
	slot_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	slot_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	slot_scroll.custom_minimum_size = Vector2(0, 54)
	slot_scroll.add_child(reference_slot_box)
	bottom_box.add_child(slot_scroll)
	var slot_data := [
		["E", "USE", Callable(self, "_contextual_interact")],
		["⚔", "ATTACK", func() -> void: _player_attack(player)],
		["⇢", "DODGE", Callable(self, "_player_dodge")],
		["G", "FOOD", Callable(self, "_eat_best_food")],
		["H", "WATER", Callable(self, "_drink_water")],
		["F", "FARM", func() -> void: farm_plot_interact(farm_plot)],
		["B", "BUILD", Callable(self, "_toggle_build_context")],
		["✦", "LEDGER", Callable(self, "_toggle_utilities")],
	]
	for slot_value in slot_data:
		var slot := _reference_slot_button(str(slot_value[0]), str(slot_value[1]), slot_value[2] as Callable)
		reference_slots.append(slot)
		reference_slot_box.add_child(slot)
	var cargo_row := HBoxContainer.new()
	cargo_row.name = "CargoProgressRow"
	cargo_row.add_theme_constant_override("separation", 8)
	bottom_box.add_child(cargo_row)
	reference_cargo_bar = _reference_bar(Color("#74b858"), 100)
	reference_cargo_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reference_cargo_bar.custom_minimum_size = Vector2(300, 10)
	cargo_row.add_child(reference_cargo_bar)
	reference_cargo_label = _label("XP 0 / 100", 11, Color("#ead9b6"))
	reference_cargo_label.custom_minimum_size = Vector2(98, 20)
	reference_cargo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cargo_row.add_child(reference_cargo_label)

func _reference_player_portrait_texture() -> Texture2D:
	var sheet := load(PLAYER_SPRITE_SHEET_PATH) as Texture2D
	if sheet == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(0.0, 0.0, float(sheet.get_width()) / 4.0, float(sheet.get_height()) / 2.0)
	atlas.filter_clip = true
	return atlas

func _reference_style(background: Color, border: Color, radius: int, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0.0, 2.0)
	return style

func _reference_panel(background: Color, border: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", _reference_style(background, border, radius, 2))
	var sourced_texture := _load_sourced_texture(KENNEY_PANEL_TEXTURE)
	if sourced_texture != null:
		var textured_style := StyleBoxTexture.new()
		textured_style.texture = sourced_texture
		textured_style.texture_margin_left = 12.0
		textured_style.texture_margin_top = 12.0
		textured_style.texture_margin_right = 12.0
		textured_style.texture_margin_bottom = 12.0
		# Keep the texture warm and legible without making the full world opaque.
		textured_style.modulate_color = Color(0.50, 0.31, 0.16, 0.90)
		panel.add_theme_stylebox_override("panel", textured_style)
	return panel

func _reference_bar(color: Color, maximum: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = maximum
	bar.value = maximum
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(184, 7)
	bar.add_theme_stylebox_override("background", _reference_style(Color(0.015, 0.02, 0.022, 0.92), Color(0.0, 0.0, 0.0, 0.0), 5, 0))
	bar.add_theme_stylebox_override("fill", _reference_style(color, color.lightened(0.18), 5, 1))
	return bar

func _reference_objective_text() -> String:
	if session == null:
		return "NEXT  •  Notice Board"
	var first_run_stage := str(session.call("first_run_stage")) if session.has_method("first_run_stage") else "complete"
	if first_run_stage != "complete":
		match first_run_stage:
			"meet_mira": return "START  •  Speak with Mira"
			"reach_gate": return "LEAVE  •  Reach the Whisperwood gate"
			"choose_trail": return "TRAIL  •  Choose a Whisperwood path"
			"gather": return "GATHER  •  Make a field bundle"
			"collect_bundle": return "PICKUP  •  Collect the field bundle"
			"extract": return "RETURN  •  Reach the expedition beacon"
			"claim_supply": return "CLAIM  •  Notice Board reward"
			"build_workshop": return "BUILD  •  Finish the Workshop"
	if current_zone == "Sanctuary":
		var current_quest: Dictionary = session.get("quest") if session.get("quest") is Dictionary else {}
		var quest_progress := int(current_quest.get("progress", 0))
		var quest_target := maxi(1, int(current_quest.get("target", 5)))
		if bool(current_quest.get("claimed", false)):
			return "NEXT  •  New supply run"
		if quest_progress >= quest_target:
			return "CLAIM  •  Notice Board reward"
		return "QUEST  •  Cargo %d/%d" % [quest_progress, quest_target]
	if not session.has_method("has_active_expedition") or not bool(session.call("has_active_expedition")):
		return "FOLLOW  •  Route beacon"
	if not session.has_method("expedition_route_snapshot"):
		return "RETURN  •  Extract at beacon"
	var route_state: Dictionary = session.call("expedition_route_snapshot")
	if str(route_state.get("branch_id", "")).is_empty():
		return "TRAIL  •  Choose a route"
	if bool(route_state.get("objective_complete", false)):
		return "READY  •  Extract at beacon"
	var objective_progress := int(route_state.get("objective_progress", 0))
	var objective_target := int(route_state.get("objective_target", 0))
	var route_definition: Dictionary = route_state.get("branch_definition", {})
	var objective_label := str(route_definition.get("label", "Route objective"))
	if objective_target > 0:
		return "OBJECTIVE  •  %d/%d %s" % [objective_progress, objective_target, objective_label]
	return "OBJECTIVE  •  %s" % objective_label

func _reference_icon_button(icon: String, tooltip: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = icon
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(42, 54)
	button.add_theme_font_size_override("font_size", 25)
	_apply_reference_button_texture(button, Color(0.53, 0.34, 0.18, 0.96), Color(0.78, 0.55, 0.28, 1.0))
	button.add_theme_color_override("font_color", Color("#f8ddb0"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.pressed.connect(callback)
	return button

func _reference_action_button(text_value: String, callback: Callable, width: float) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(width, 24)
	button.add_theme_font_size_override("font_size", 11)
	_apply_reference_button_texture(button, Color(0.57, 0.36, 0.18, 0.98), Color(0.82, 0.58, 0.30, 1.0))
	button.add_theme_color_override("font_color", Color("#fff1c7"))
	button.pressed.connect(callback)
	return button

func _reference_slot_button(key_text: String, label_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = "ReferenceSlot_%s" % label_text
	button.set_meta("action_key", key_text)
	button.set_meta("action_label", label_text)
	button.text = ""
	button.custom_minimum_size = Vector2(78, 50)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_reference_button_texture(button, Color(0.41, 0.24, 0.12, 1.0), Color(0.72, 0.46, 0.21, 1.0))
	button.add_theme_color_override("font_color", Color("#f4dfb0"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var icon_label := _label(key_text, 22, Color("#f6d891"))
	icon_label.name = "SlotIcon"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.position = Vector2(4, 3)
	icon_label.size = Vector2(70, 25)
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon_label)
	var caption := _label(label_text, 8, Color("#ead1a0"))
	caption.name = "SlotCaption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.position = Vector2(3, 29)
	caption.size = Vector2(72, 15)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(caption)
	button.pressed.connect(callback)
	return button

func _apply_reference_button_texture(button: Button, normal_tint: Color, hover_tint: Color) -> void:
	var normal_texture := _load_sourced_texture(KENNEY_BUTTON_TEXTURE)
	var hover_texture := _load_sourced_texture(KENNEY_BUTTON_HOVER_TEXTURE)
	if normal_texture == null or hover_texture == null:
		button.add_theme_stylebox_override("normal", _reference_style(Color(0.16, 0.09, 0.04, 0.98), Color("#b98b51"), 8, 1))
		button.add_theme_stylebox_override("hover", _reference_style(Color(0.34, 0.19, 0.08, 1.0), Color("#f0ce7c"), 8, 2))
		button.add_theme_stylebox_override("pressed", _reference_style(Color(0.45, 0.25, 0.10, 1.0), Color("#fff0b4"), 8, 2))
		return
	var normal_style := StyleBoxTexture.new()
	normal_style.texture = normal_texture
	normal_style.texture_margin_left = 10.0
	normal_style.texture_margin_top = 8.0
	normal_style.texture_margin_right = 10.0
	normal_style.texture_margin_bottom = 8.0
	normal_style.modulate_color = normal_tint
	button.add_theme_stylebox_override("normal", normal_style)
	var hover_style := StyleBoxTexture.new()
	hover_style.texture = hover_texture
	hover_style.texture_margin_left = 10.0
	hover_style.texture_margin_top = 8.0
	hover_style.texture_margin_right = 10.0
	hover_style.texture_margin_bottom = 8.0
	hover_style.modulate_color = hover_tint
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)

func _apply_cozy_hud_theme() -> void:
	# Keep the existing contextual action logic, but remove the black desktop
	# prototype treatment from the illustrated Sanctuary presentation. The same
	# warm card language remains usable when the ledger expands or an expedition
	# opens the full action rail.
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.16, 0.21, 0.16, 0.94)
	card_style.border_color = Color(0.94, 0.80, 0.55, 0.54)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(14)
	for panel in [hud_top_panel, hud_bag_panel, hud_quest_panel, hud_right_panel, hud_action_panel, settings_panel]:
		if panel != null:
			panel.add_theme_stylebox_override("panel", card_style)
	if zone_label != null:
		zone_label.add_theme_color_override("font_color", Color("#c6d8ac"))
	if day_label != null:
		day_label.add_theme_color_override("font_color", Color("#e5d6b1"))
	if status_label != null:
		status_label.add_theme_color_override("font_color", Color("#d4dfc2"))
	if weather_label != null:
		weather_label.add_theme_color_override("font_color", Color("#c0cfb4"))
	for button_box in [hud_right_box, hud_action_box]:
		if button_box == null:
			continue
		for child in button_box.get_children():
			var button := child as Button
			if button == null:
				continue
			_apply_cozy_button_theme(button)
	if settings_panel != null:
		for descendant in settings_panel.find_children("*", "Button", true, false):
			var settings_button_node := descendant as Button
			if settings_button_node != null:
				_apply_cozy_button_theme(settings_button_node)

func _apply_cozy_button_theme(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.50, 0.45, 0.32, 0.90)
	normal.border_color = Color(0.95, 0.82, 0.58, 0.52)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.66, 0.56, 0.36, 0.96)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", Color("#fff4d4"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)

func _build_settings_panel(root: Control) -> void:
	settings_panel = _panel(Vector2.ZERO, Vector2(520, 430), Color(0.035, 0.07, 0.075, 0.98))
	settings_panel.name = "SettingsPanel"
	settings_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_panel.visible = false
	root.add_child(settings_panel)
	var title := _label("SETTINGS", 24, palette["cream"])
	title.position = Vector2(28, 22)
	title.size = Vector2(300, 34)
	settings_panel.add_child(title)
	var subtitle := _label("Sound and comfort changes apply immediately and are saved with your world.", 12, palette["muted"])
	subtitle.position = Vector2(28, 58)
	subtitle.size = Vector2(450, 30)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	settings_panel.add_child(subtitle)
	var slider_rows := [
		["master", "Master"],
		["music", "Music"],
		["ambience", "Ambience"],
		["weather", "Weather"],
		["effects", "Effects"],
		["ui", "Interface"],
	]
	var stored_settings: Dictionary = session.get("settings") if session != null and session.get("settings") is Dictionary else {}
	for index in slider_rows.size():
		var setting_id := str(slider_rows[index][0])
		var label_text := str(slider_rows[index][1])
		var y := 98.0 + float(index) * 38.0
		var label := _label(label_text, 13, palette["cream"])
		label.position = Vector2(28, y)
		label.size = Vector2(105, 26)
		settings_panel.add_child(label)
		var slider := HSlider.new()
		slider.name = "%sVolume" % setting_id.capitalize()
		slider.position = Vector2(138, y + 1.0)
		slider.size = Vector2(278, 24)
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = float(stored_settings.get(setting_id, 0.8))
		settings_panel.add_child(slider)
		settings_sliders[setting_id] = slider
		var value_label := _label("%d%%" % roundi(slider.value * 100.0), 12, palette["muted"])
		value_label.position = Vector2(428, y)
		value_label.size = Vector2(58, 26)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		settings_panel.add_child(value_label)
		settings_value_labels[setting_id] = value_label
		var captured_setting_id := setting_id
		slider.value_changed.connect(func(value: float) -> void: _on_setting_slider_changed(captured_setting_id, value))
	screen_shake_toggle = CheckButton.new()
	screen_shake_toggle.name = "ScreenShakeToggle"
	screen_shake_toggle.text = "Screen shake"
	screen_shake_toggle.position = Vector2(28, 334)
	screen_shake_toggle.size = Vector2(210, 34)
	screen_shake_toggle.button_pressed = bool(stored_settings.get("screen_shake", true))
	settings_panel.add_child(screen_shake_toggle)
	screen_shake_toggle.toggled.connect(_on_screen_shake_toggled)
	haptics_toggle = CheckButton.new()
	haptics_toggle.name = "HapticsToggle"
	haptics_toggle.text = "Touch haptics"
	haptics_toggle.position = Vector2(250, 334)
	haptics_toggle.size = Vector2(210, 34)
	haptics_toggle.button_pressed = bool(stored_settings.get("haptics", true))
	settings_panel.add_child(haptics_toggle)
	haptics_toggle.toggled.connect(_on_haptics_toggled)
	var close_button := _button("Close Settings", _toggle_settings)
	close_button.position = Vector2(28, 382)
	close_button.size = Vector2(432, 34)
	settings_panel.add_child(close_button)

func _on_setting_slider_changed(setting_id: String, value: float) -> void:
	if session == null or not session.has_method("set_setting"):
		return
	var previous_value := float(session.get("settings").get(setting_id, value))
	if bool(session.call("set_setting", setting_id, value)):
		if not _persist_setting_change(setting_id, previous_value):
			if settings_sliders.has(setting_id):
				(settings_sliders[setting_id] as HSlider).set_value_no_signal(previous_value)
			if settings_value_labels.has(setting_id):
				(settings_value_labels[setting_id] as Label).text = "%d%%" % roundi(previous_value * 100.0)
			return
		if settings_value_labels.has(setting_id):
			(settings_value_labels[setting_id] as Label).text = "%d%%" % roundi(value * 100.0)
		_apply_player_settings()

func _on_screen_shake_toggled(value: bool) -> void:
	if session == null or not session.has_method("set_setting"):
		return
	var previous_value := bool(session.get("settings").get("screen_shake", not value))
	if bool(session.call("set_setting", "screen_shake", value)) and not _persist_setting_change("screen_shake", previous_value):
		screen_shake_toggle.set_pressed_no_signal(previous_value)

func _on_haptics_toggled(value: bool) -> void:
	if session == null or not session.has_method("set_setting"):
		return
	var previous_value := bool(session.get("settings").get("haptics", not value))
	if bool(session.call("set_setting", "haptics", value)) and not _persist_setting_change("haptics", previous_value):
		haptics_toggle.set_pressed_no_signal(previous_value)

func _persist_setting_change(setting_id: String, previous_value: Variant) -> bool:
	_apply_player_settings()
	if session == null or not session.has_method("save_game") or bool(session.call("save_game")):
		return true
	# A setting is still gameplay state: a failed durable write must not leave the
	# live mixer and toggles disagreeing with the next reload.
	if session.has_method("set_setting"):
		session.call("set_setting", setting_id, previous_value)
	_apply_player_settings()
	_show_toast("Settings could not be saved. The previous value was restored.", 2.4)
	return false

func _apply_player_settings() -> void:
	if session == null:
		return
	var stored_settings: Dictionary = session.get("settings") if session.get("settings") is Dictionary else {}
	screen_shake_enabled = bool(stored_settings.get("screen_shake", true))
	haptics_enabled = bool(stored_settings.get("haptics", true))
	if not screen_shake_enabled:
		camera_shake = 0.0
	if audio_director != null and audio_director.has_method("apply_settings"):
		audio_director.call("apply_settings", stored_settings)

func _toggle_settings() -> void:
	if interior_transitioning:
		return
	settings_open = not settings_open
	if settings_panel != null:
		settings_panel.visible = settings_open
	if settings_open:
		_reset_manual_input()
		get_tree().paused = true
		_show_toast("Settings open", 1.2)
	else:
		get_tree().paused = false
		_show_toast("Settings saved", 1.2)

func _device_safe_rect_in_hud(viewport_size: Vector2) -> Rect2:
	var full_rect := Rect2(Vector2.ZERO, viewport_size)
	# Desktop windows use the complete logical viewport. Mobile safe areas are
	# reported in native screen pixels, so only apply them on touch devices and
	# explicitly convert them into this CanvasLayer's logical coordinate space.
	if not DisplayServer.is_touchscreen_available():
		return full_rect
	var native_safe := DisplayServer.get_display_safe_area()
	var native_window_size := DisplayServer.window_get_size()
	if native_safe.size.x <= 0 or native_safe.size.y <= 0 or native_window_size.x <= 0 or native_window_size.y <= 0:
		return full_rect
	var native_window_position := DisplayServer.window_get_position()
	var native_window_rect := Rect2(
		Vector2(float(native_window_position.x), float(native_window_position.y)),
		Vector2(float(native_window_size.x), float(native_window_size.y))
	)
	var clipped_native_safe := Rect2(
		Vector2(float(native_safe.position.x), float(native_safe.position.y)),
		Vector2(float(native_safe.size.x), float(native_safe.size.y))
	).intersection(native_window_rect)
	if not clipped_native_safe.has_area():
		return full_rect
	var local_native_start := clipped_native_safe.position - native_window_rect.position
	var local_native_end := clipped_native_safe.position + clipped_native_safe.size - native_window_rect.position
	var screen_transform := hud_root.get_viewport().get_screen_transform()
	var mapped_start := Vector2.ZERO
	var mapped_end := Vector2.ZERO
	if not is_zero_approx(screen_transform.determinant()):
		var screen_to_hud := screen_transform.affine_inverse()
		mapped_start = screen_to_hud * local_native_start
		mapped_end = screen_to_hud * local_native_end
	else:
		var native_to_hud := Vector2(viewport_size.x / float(native_window_size.x), viewport_size.y / float(native_window_size.y))
		mapped_start = local_native_start * native_to_hud
		mapped_end = local_native_end * native_to_hud
	var mapped_min := Vector2(minf(mapped_start.x, mapped_end.x), minf(mapped_start.y, mapped_end.y))
	var mapped_max := Vector2(maxf(mapped_start.x, mapped_end.x), maxf(mapped_start.y, mapped_end.y))
	var mapped_rect := Rect2(mapped_min, mapped_max - mapped_min).intersection(full_rect)
	# A malformed platform rectangle must never collapse the controls into an
	# unusable sliver. Real phone/tablet safe areas retain most of the viewport.
	if mapped_rect.size.x < viewport_size.x * 0.5 or mapped_rect.size.y < viewport_size.y * 0.5:
		return full_rect
	return mapped_rect

func _visible_hud_button_count(button_box: VBoxContainer) -> int:
	if button_box == null:
		return 0
	var count := 0
	for child in button_box.get_children():
		if child is Button and (child as Button).visible:
			count += 1
	return count

func _hud_button_panel_height(button_box: VBoxContainer, maximum_height: float) -> float:
	var visible_count := _visible_hud_button_count(button_box)
	if visible_count <= 0:
		return 0.0
	var content_height := float(visible_count) * 44.0 + float(maxi(0, visible_count - 1)) * 4.0
	return minf(maximum_height, content_height + 20.0)

func _current_hud_layout_signature() -> String:
	if hud_root == null:
		return ""
	var safe_rect := _device_safe_rect_in_hud(hud_root.size)
	var parts: Array[String] = [
		"%d,%d" % [roundi(hud_root.size.x), roundi(hud_root.size.y)],
		"%d,%d,%d,%d" % [roundi(safe_rect.position.x), roundi(safe_rect.position.y), roundi(safe_rect.size.x), roundi(safe_rect.size.y)],
		str(roundi(hud_top_panel.size.y)) if hud_top_panel != null else "0",
		"1" if hud_joystick != null and hud_joystick.visible else "0",
		"1" if action_hint != null and action_hint.visible else "0",
	]
	for button_box in [hud_right_box, hud_action_box]:
		if button_box == null:
			continue
		for child in button_box.get_children():
			if child is Button:
				parts.append("1" if (child as Button).visible else "0")
	return ":".join(parts)

func _refresh_hud_layout_if_needed() -> void:
	var next_signature := _current_hud_layout_signature()
	if next_signature == hud_layout_signature:
		return
	_layout_hud()

func _layout_hud() -> void:
	if hud_root == null:
		return
	var viewport_size := hud_root.size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	hud_safe_rect = _device_safe_rect_in_hud(viewport_size)
	var margin := clampf(minf(hud_safe_rect.size.x, hud_safe_rect.size.y) * 0.025, 14.0, 22.0)
	var content_position := hud_safe_rect.position + Vector2.ONE * margin
	var content_size := Vector2(
		maxf(1.0, hud_safe_rect.size.x - margin * 2.0),
		maxf(1.0, hud_safe_rect.size.y - margin * 2.0)
	)
	var content_end := content_position + content_size
	var right_width := clampf(content_size.x * 0.24, 210.0, 266.0)
	right_width = minf(right_width, maxf(176.0, content_size.x * 0.42))
	var column_gap := maxf(12.0, margin * 0.75)
	var maximum_left_width := maxf(180.0, content_size.x - right_width - column_gap)
	var left_width := minf(minf(360.0, maxf(240.0, content_size.x * 0.31)), maximum_left_width)
	var right_x := content_end.x - right_width
	if hud_top_panel != null:
		hud_top_panel.position = content_position
		hud_top_panel.size.x = left_width
	if hud_top_box != null:
		var top_inner_width := maxf(160.0, left_width - 36.0)
		hud_top_box.size.x = top_inner_width
		energy_bar.custom_minimum_size.x = top_inner_width
		health_bar.custom_minimum_size.x = top_inner_width
	if hud_bag_panel != null:
		var bag_y := content_position.y + (hud_top_panel.size.y if hud_top_panel != null else 190.0) + 16.0
		hud_bag_panel.position = Vector2(content_position.x, bag_y)
		hud_bag_panel.size.x = left_width
		if inventory_label != null:
			inventory_label.size.x = maxf(160.0, left_width - 36.0)
		if mastery_label != null:
			mastery_label.size.x = maxf(160.0, left_width - 36.0)
	var joystick_size := minf(156.0, maxf(120.0, content_size.y * 0.24))
	var joystick_position := Vector2(content_position.x, content_end.y - joystick_size)
	if hud_joystick != null:
		hud_joystick.size = Vector2.ONE * joystick_size
		hud_joystick.position = joystick_position
	var hint_height := 50.0
	var hint_y := content_end.y - hint_height
	if hud_joystick != null and hud_joystick.visible:
		hint_y = joystick_position.y - hint_height - 10.0
	var main_column_width := maxf(180.0, right_x - column_gap - content_position.x)
	if hud_quest_panel != null:
		var quest_width := minf(360.0, maxf(250.0, main_column_width * 0.42))
		quest_width = minf(quest_width, main_column_width)
		hud_quest_panel.size.x = quest_width
		hud_quest_panel.position = Vector2(content_position.x + maxf(0.0, (main_column_width - quest_width) * 0.5), maxf(content_position.y, hint_y - hud_quest_panel.size.y - 10.0))
		if quest_label != null:
			quest_label.size.x = maxf(160.0, quest_width - 36.0)
	var controls_height := 0.0
	if hud_right_panel != null:
		controls_height = _hud_button_panel_height(hud_right_box, maxf(64.0, content_size.y * 0.48))
		hud_right_panel.position = Vector2(right_x, content_position.y)
		hud_right_panel.size = Vector2(right_width, maxf(64.0, controls_height))
	if hud_right_scroll != null:
		hud_right_scroll.size = Vector2(maxf(1.0, hud_right_panel.size.x - 20.0), maxf(1.0, hud_right_panel.size.y - 20.0))
	if hud_right_box != null:
		var right_inner_width := maxf(148.0, right_width - 28.0)
		hud_right_box.custom_minimum_size.x = right_inner_width
		for child in hud_right_box.get_children():
			if child is Button:
				(child as Button).custom_minimum_size.x = right_inner_width
	var action_count := _visible_hud_button_count(hud_action_box)
	if hud_action_panel != null:
		var action_top_limit := content_position.y + maxf(64.0, controls_height) + column_gap
		var available_action_height := maxf(64.0, content_end.y - action_top_limit)
		var action_height := _hud_button_panel_height(hud_action_box, available_action_height)
		hud_action_panel.visible = action_count > 0 and (reference_hud == null or not reference_hud.visible)
		hud_action_panel.size = Vector2(right_width, maxf(64.0, action_height))
		hud_action_panel.position = Vector2(right_x, content_end.y - hud_action_panel.size.y)
	if hud_action_scroll != null and hud_action_panel != null:
		hud_action_scroll.size = Vector2(maxf(1.0, hud_action_panel.size.x - 20.0), maxf(1.0, hud_action_panel.size.y - 20.0))
	if hud_action_box != null:
		var action_inner_width := maxf(148.0, right_width - 28.0)
		hud_action_box.custom_minimum_size.x = action_inner_width
		for child in hud_action_box.get_children():
			if child is Button:
				(child as Button).custom_minimum_size.x = action_inner_width
	if action_hint != null:
		action_hint.position = Vector2(content_position.x, hint_y)
		action_hint.size = Vector2(main_column_width, hint_height)
	if toast_label != null:
		var toast_left := content_position.x + left_width + column_gap
		var toast_available_width := right_x - column_gap - toast_left
		if toast_available_width >= 260.0:
			toast_label.position = Vector2(toast_left, content_position.y)
			toast_label.size.x = minf(580.0, toast_available_width)
		else:
			var fallback_toast_width := minf(580.0, main_column_width)
			toast_label.position = Vector2(content_position.x + (main_column_width - fallback_toast_width) * 0.5, content_position.y + (hud_top_panel.size.y if hud_top_panel != null else 146.0) + 8.0)
			toast_label.size.x = fallback_toast_width
	if action_hint != null and hud_joystick != null:
		action_hint.visible = hud_joystick.visible or current_zone != "Sanctuary"
	if settings_panel != null:
		var settings_size := settings_panel.size
		var settings_scale := minf(1.0, minf(content_size.x / settings_size.x, content_size.y / settings_size.y))
		settings_panel.scale = Vector2.ONE * settings_scale
		var scaled_settings_size := settings_size * settings_scale
		settings_panel.position = content_position + (content_size - scaled_settings_size) * 0.5
	if reference_hud != null:
		var reference_visible := not utilities_open and not settings_open
		reference_hud.visible = reference_visible
		var top_width := minf(780.0, maxf(360.0, content_size.x * 0.68))
		var top_height := 98.0
		reference_top_panel.position = content_position
		reference_top_panel.size = Vector2(minf(top_width, content_size.x), top_height)
		var top_row := reference_top_panel.get_child(0) as HBoxContainer
		if top_row != null:
			top_row.size = Vector2(maxf(300.0, reference_top_panel.size.x - 24.0), top_height - 20.0)
		var compact_top := reference_top_panel.size.x < 600.0
		for index in reference_top_buttons.size():
			var top_button := reference_top_buttons[index]
			top_button.visible = not compact_top or index in [0, 2]
		var stat_top := content_position.y + top_height + 12.0
		reference_stat_box.position = Vector2(content_position.x, stat_top)
		reference_stat_box.size = Vector2(132.0, maxf(210.0, content_end.y - stat_top - 12.0))
		var belt_width := minf(820.0, maxf(310.0, content_size.x * 0.72))
		var belt_height := 142.0
		var belt_x := content_position.x + maxf(0.0, (content_size.x - belt_width) * 0.5)
		if hud_joystick != null and hud_joystick.visible:
			# Touch layouts use the full-width reference belt. Move the joystick
			# above it so the two thumbs never compete for the same hit target.
			belt_x = content_position.x
			belt_width = content_size.x
		reference_bottom_panel.position = Vector2(belt_x, content_end.y - belt_height)
		reference_bottom_panel.size = Vector2(belt_width, belt_height)
		if hud_joystick != null and hud_joystick.visible:
			hud_joystick.position = Vector2(content_position.x, reference_bottom_panel.position.y - hud_joystick.size.y - 12.0)
		var bottom_box := reference_bottom_panel.get_child(0) as VBoxContainer
		if bottom_box != null:
			bottom_box.position = Vector2(12.0, 9.0)
			bottom_box.size = Vector2(maxf(260.0, belt_width - 24.0), belt_height - 18.0)
	hud_layout_signature = _current_hud_layout_signature()

func _create_floor(parent: Node3D, position: Vector3, size: Vector2, color: Color, node_name: String) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, 0.5, size.y)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color, 1.0)
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, 0.5, size.y)
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)

func _create_path(parent: Node3D, position: Vector3, size: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color, 1.0)
	mesh_instance.position = position
	parent.add_child(mesh_instance)

func _create_authored_sanctuary_route_paths(parent: Node3D) -> void:
	# The gate sockets own the walkable intent. Drawing their measured waypoint
	# segments makes the route a readable physical invitation instead of a
	# destination marker floating beside the buildings. These are presentation
	# meshes only; the player still uses the same real physics bodies and direct
	# camera-relative input used everywhere else.
	for route_id in ContentRegistry.ROUTE_SOCKETS:
		var socket: Dictionary = ContentRegistry.ROUTE_SOCKETS[route_id]
		var waypoints: Array = socket.get("traversal_waypoints", [])
		if waypoints.size() < 2:
			continue
		var accent := Color("#" + str(socket.get("accent", "b58a5f")))
		var route_color: Color = palette["sand"].darkened(0.11).lerp(accent, 0.16)
		for index in range(waypoints.size() - 1):
			var start_value: Variant = waypoints[index]
			var end_value: Variant = waypoints[index + 1]
			if not start_value is Array or not end_value is Array:
				continue
			var start_array: Array = start_value
			var end_array: Array = end_value
			if start_array.size() < 2 or end_array.size() < 2:
				continue
			var start := Vector3(float(start_array[0]), 0.035, float(start_array[1]))
			var end := Vector3(float(end_array[0]), 0.035, float(end_array[1]))
			_create_route_segment(parent, start, end, route_color, "%s_%02d" % [route_id, index])

func _create_route_segment(parent: Node3D, start: Vector3, end: Vector3, color: Color, segment_id: String) -> void:
	var delta := end - start
	delta.y = 0.0
	var length := delta.length()
	if length <= 0.05:
		return
	var segment := MeshInstance3D.new()
	segment.name = "SanctuaryRoutePath_%s" % segment_id
	segment.add_to_group("sanctuary_route_path")
	var mesh := BoxMesh.new()
	mesh.size = Vector3(length, 0.055, 1.34)
	segment.mesh = mesh
	segment.material_override = _material(color, 0.92)
	segment.position = (start + end) * 0.5
	segment.rotation.y = atan2(-delta.z, delta.x)
	parent.add_child(segment)

func _create_sanctuary_ground_story(parent: Node3D) -> void:
	# Low, irregular ground washes break up the test-floor read without
	# changing traversal height or the authoritative placement grid.
	for patch_data in [
		[Vector3(0.0, 0.006, 1.8), Vector2(7.2, 5.0), Color(0.34, 0.27, 0.20, 0.34), 12.0],
		[Vector3(-6.5, 0.006, -0.6), Vector2(5.4, 4.2), Color(0.38, 0.29, 0.20, 0.26), -8.0],
		[Vector3(-6.0, 0.006, 4.4), Vector2(5.0, 3.8), Color(0.40, 0.30, 0.20, 0.32), 7.0],
		[Vector3(-0.2, 0.006, 7.0), Vector2(5.0, 3.6), Color(0.29, 0.25, 0.19, 0.28), -5.0],
		[Vector3(7.4, 0.006, 5.0), Vector2(6.0, 4.4), Color(0.30, 0.27, 0.20, 0.22), 16.0],
		[Vector3(10.0, 0.006, -2.0), Vector2(5.0, 3.2), Color(0.32, 0.25, 0.19, 0.20), -12.0],
	]:
		_create_ground_patch(parent, patch_data[0], patch_data[1], patch_data[2], float(patch_data[3]))

func _create_ground_patch(parent: Node3D, position: Vector3, size: Vector2, color: Color, rotation_degrees: float) -> void:
	var patch := MeshInstance3D.new()
	patch.name = "SanctuaryGroundWash"
	var patch_mesh := CylinderMesh.new()
	patch_mesh.top_radius = 1.0
	patch_mesh.bottom_radius = 1.0
	patch_mesh.height = 0.025
	patch_mesh.radial_segments = 12
	patch.mesh = patch_mesh
	patch.material_override = _material(color, 1.0, true)
	patch.position = position
	patch.rotation_degrees.y = rotation_degrees
	patch.scale = Vector3(size.x * 0.5, 1.0, size.y * 0.5)
	parent.add_child(patch)

func _dress_sanctuary_edges(parent: Node3D) -> void:
	# Break the rectangular path edges with sourced CC0 ground cover while
	# keeping the walkable centre open for readable Last-Day-on-Earth scale.
	for position in [Vector3(-9.5, 0.02, -5.0), Vector3(-6.8, 0.02, 6.2), Vector3(5.2, 0.02, 6.5), Vector3(10.0, 0.02, 2.4), Vector3(-10.4, 0.02, 1.0), Vector3(2.9, 0.02, 7.0)]:
		_add_sourced_model(parent, "res://assets/quaternius-stylized-nature/glTF/Grass_Common_Short.gltf", 0.28, position)
	for position in [Vector3(-9.0, 0.02, -5.6), Vector3(-7.9, 0.02, 5.7), Vector3(5.8, 0.02, 6.0), Vector3(10.4, 0.02, 1.3)]:
		_add_sourced_model(parent, "res://assets/quaternius-stylized-nature/glTF/Fern_1.gltf", 0.34, position)
	for position in [Vector3(-6.0, 0.02, 2.3), Vector3(4.2, 0.02, 2.6), Vector3(8.7, 0.02, 6.2), Vector3(-10.5, 0.02, -2.0)]:
		_add_sourced_model(parent, "res://assets/quaternius-stylized-nature/glTF/Bush_Common_Flowers.gltf", 0.42, position)
	for index in 8:
		var stone_position := Vector3(-10.0 + float(index) * 2.6, 0.06, 2.25 + sin(float(index) * 0.8) * 0.22)
		_add_sourced_model(parent, "res://assets/quaternius-stylized-nature/glTF/RockPath_Round_Small_2.gltf", 0.22, stone_position)

func _add_sourced_model(parent: Node3D, asset_path: String, scale_value: float, local_position := Vector3.ZERO) -> bool:
	if asset_path.is_empty():
		return false
	if asset_path.get_extension().to_lower() == "fbx":
		var packed_scene := ResourceLoader.load(asset_path) as PackedScene
		if packed_scene == null:
			return false
		var imported_instance := packed_scene.instantiate()
		if imported_instance == null:
			return false
		imported_instance.name = "Sourced_" + asset_path.get_file().get_basename()
		imported_instance.position = local_position
		imported_instance.scale = Vector3.ONE * scale_value
		parent.add_child(imported_instance)
		return true
	# Runtime builds may not have completed editor-side .gltf imports yet.
	# Parse the CC0 glTF directly so the sourced asset works on a clean launch.
	var cached_scene := sourced_model_scenes.get(asset_path) as PackedScene
	if cached_scene != null:
		var cached_instance := cached_scene.instantiate() as Node3D
		if cached_instance == null:
			return false
		cached_instance.name = "Sourced_" + asset_path.get_file().get_basename()
		cached_instance.position = local_position
		cached_instance.scale = Vector3.ONE * scale_value
		parent.add_child(cached_instance)
		return true
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	if document.append_from_file(asset_path, state) != OK:
		return false
	var generated_instance := document.generate_scene(state) as Node3D
	if generated_instance == null:
		return false
	var packed_scene := PackedScene.new()
	var pack_result := packed_scene.pack(generated_instance)
	var instance: Node3D
	if pack_result == OK:
		generated_instance.free()
		sourced_model_scenes[asset_path] = packed_scene
		instance = packed_scene.instantiate() as Node3D
	else:
		instance = generated_instance
	if instance == null:
		return false
	instance.name = "Sourced_" + asset_path.get_file().get_basename()
	instance.position = local_position
	instance.scale = Vector3.ONE * scale_value
	parent.add_child(instance)
	return true

func _find_sourced_model(parent: Node3D) -> Node3D:
	if parent == null:
		return null
	for child in parent.get_children():
		var candidate := child as Node3D
		if candidate != null and str(candidate.name).begins_with("Sourced_"):
			return candidate
	return null

func _runtime_asset_measurement(root: Node3D, name_tokens: Array = [], include_hidden := false) -> Dictionary:
	if root == null:
		return {"valid": false, "reason": "null_visual_root"}
	var measurement := SanctuaryAssetMeasurement.measure_runtime_node(root, name_tokens, include_hidden)
	if not bool(measurement.get("valid", false)) and not name_tokens.is_empty():
		# A source asset may use a different mesh label in a future import. A
		# complete visible envelope is still safer than silently keeping a guessed
		# collision size; the fallback is recorded in metadata for QA.
		measurement = SanctuaryAssetMeasurement.measure_runtime_node(root, [], include_hidden)
		measurement["measurement_fallback"] = "visible_mesh_envelope"
	return measurement

func _attach_measured_box_collision(parent: Node3D, visual_root: Node3D, body_name: String, shape_name: String, name_tokens: Array = []) -> CollisionShape3D:
	var body := StaticBody3D.new()
	body.name = body_name
	body.collision_layer = 1
	body.collision_mask = 1
	var collision := CollisionShape3D.new()
	collision.name = shape_name
	var measurement := _runtime_asset_measurement(visual_root, name_tokens)
	if bool(measurement.get("valid", false)):
		var bounds: AABB = measurement.get("bounds", AABB())
		var box := BoxShape3D.new()
		box.size = bounds.size
		collision.shape = box
		collision.position = bounds.position + bounds.size * 0.5
		_set_measured_collision_metadata(collision, measurement, bounds)
		_set_measured_collision_metadata(body, measurement, bounds)
	else:
		push_error("Asset '%s' has no visible mesh bounds; refusing to create an unmeasured box hitbox." % str(visual_root.name if visual_root != null else "<null>"))
		collision.disabled = true
	body.add_child(collision)
	parent.add_child(body)
	return collision

func _attach_measured_cylinder_collision(parent: Node3D, visual_root: Node3D, body_name: String, shape_name: String, name_tokens: Array = [], include_hidden := false) -> CollisionShape3D:
	var body := StaticBody3D.new()
	body.name = body_name
	body.collision_layer = 1
	body.collision_mask = 1
	var collision := CollisionShape3D.new()
	collision.name = shape_name
	var measurement := _runtime_asset_measurement(visual_root, name_tokens, include_hidden)
	if bool(measurement.get("valid", false)):
		var bounds: AABB = measurement.get("bounds", AABB())
		var cylinder := CylinderShape3D.new()
		cylinder.radius = maxf(bounds.size.x, bounds.size.z) * 0.5
		cylinder.height = bounds.size.y
		collision.shape = cylinder
		collision.position = bounds.position + bounds.size * 0.5
		_set_measured_collision_metadata(collision, measurement, bounds)
		_set_measured_collision_metadata(body, measurement, bounds)
	else:
		push_error("Asset '%s' has no visible mesh bounds; refusing to create an unmeasured cylinder hitbox." % str(visual_root.name if visual_root != null else "<null>"))
		collision.disabled = true
	body.add_child(collision)
	parent.add_child(body)
	return collision

func _set_measured_collision_metadata(node: Node, measurement: Dictionary, bounds: AABB) -> void:
	if node == null:
		return
	node.set_meta("measurement_source", str(measurement.get("measurement_source", "runtime_visible_mesh_bounds")))
	node.set_meta("measurement_asset", str(measurement.get("source_path", "")))
	node.set_meta("measured_bounds", [
		bounds.position.x, bounds.position.y, bounds.position.z,
		bounds.size.x, bounds.size.y, bounds.size.z,
	])
	if measurement.has("measurement_fallback"):
		node.set_meta("measurement_fallback", str(measurement.get("measurement_fallback", "")))

func _tree_asset_path(zone_name: String) -> String:
	return str(SOURCED_TREE_ASSETS.get(zone_name, ""))

func _create_building(parent: Node3D, position: Vector3, title: String, floor_color: Color, wall_color: Color, floor_id: String) -> void:
	var building := Node3D.new()
	building.name = title.replace(" ", "")
	building.position = position
	parent.add_child(building)
	var floor := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(5.2, 0.16, 4.0)
	floor.mesh = floor_mesh
	floor.material_override = _material(floor_color, 0.98)
	floor.position.y = 0.08
	building.add_child(floor)
	for wall_position in [Vector3(-2.5, 1.05, 0), Vector3(2.5, 1.05, 0), Vector3(0, 1.05, -1.9)]:
		var wall := MeshInstance3D.new()
		var wall_mesh := BoxMesh.new()
		wall_mesh.size = Vector3(0.35, 2.1, 4.0) if absf(wall_position.x) > 2.0 else Vector3(5.2, 2.1, 0.35)
		wall.mesh = wall_mesh
		wall.material_override = _material(wall_color, 0.86)
		wall.position = wall_position
		building.add_child(wall)
		var wall_body := StaticBody3D.new()
		wall_body.name = "WallCollision"
		wall_body.position = wall_position
		var wall_shape := CollisionShape3D.new()
		var wall_box := BoxShape3D.new()
		wall_box.size = wall_mesh.size
		wall_shape.shape = wall_box
		wall_body.add_child(wall_shape)
		building.add_child(wall_body)
	var roof := MeshInstance3D.new()
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(5.8, 0.3, 4.5)
	roof.mesh = roof_mesh
	roof.material_override = _material(palette["wood_dark"], 0.84)
	roof.position = Vector3(0, 2.35, 0)
	roof.rotation_degrees.z = -2.0
	roof.visible = false
	building.add_child(roof)
	var gabled_roof := Node3D.new()
	gabled_roof.name = "GabledRoof"
	building.add_child(gabled_roof)
	_structure_box(gabled_roof, "RoofPanelLeft", Vector3(5.9, 0.18, 2.5), Vector3(0.0, 2.58, -0.82), palette["wood_dark"], Vector3(-26.0, 0.0, 0.0))
	_structure_box(gabled_roof, "RoofPanelRight", Vector3(5.9, 0.18, 2.5), Vector3(0.0, 2.58, 0.82), palette["wood_dark"], Vector3(26.0, 0.0, 0.0))
	_structure_box(gabled_roof, "Ridge", Vector3(5.95, 0.2, 0.2), Vector3(0.0, 3.18, 0.0), palette["wood"])
	for side in [-1.0, 1.0]:
		_structure_box(building, "TimberPost_%s" % side, Vector3(0.14, 2.0, 0.14), Vector3(side * 2.25, 1.08, 1.72), palette["wood_dark"])
	_structure_box(building, "TimberBeam", Vector3(4.6, 0.14, 0.14), Vector3(0.0, 1.92, 1.72), palette["wood_dark"])
	var door := MeshInstance3D.new()
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(0.9, 1.9, 0.12)
	door.mesh = door_mesh
	door.material_override = _material(palette["wood_dark"], 0.9)
	door.position = Vector3(0.0, 0.95, 1.91)
	building.add_child(door)
	for window_x in [-1.45, 1.45]:
		var window := MeshInstance3D.new()
		var window_mesh := BoxMesh.new()
		window_mesh.size = Vector3(0.7, 0.52, 0.08)
		window.mesh = window_mesh
		window.material_override = _material(Color("#f4c56f"), 0.25, false, true)
		window.position = Vector3(window_x, 1.25, 1.87)
		building.add_child(window)
	var sign := _label3d(title, 0.24, palette["cream"])
	sign.position = Vector3(0, 2.55, -2.12)
	building.add_child(sign)
	if title == "Hearth":
		furnace = Node3D.new()
		furnace.name = "Furnace"
		furnace.position = position + Vector3(1.35, 0.0, -0.15)
		add_child(furnace)
		var base := MeshInstance3D.new()
		var base_mesh := BoxMesh.new()
		base_mesh.size = Vector3(0.95, 1.0, 0.85)
		base.mesh = base_mesh
		base.material_override = _material(palette["stone"], 0.96)
		base.position.y = 0.58
		furnace.add_child(base)
		var fire := MeshInstance3D.new()
		fire.name = "Fire"
		fire.mesh = _sphere_mesh(0.24, 0.58, 8, 5)
		fire.material_override = _material(palette["ember"], 0.48, false, true)
		fire.position = Vector3(0, 1.18, -0.38)
		furnace.add_child(fire)

func _create_pond(parent: Node3D, position: Vector3) -> void:
	var pond := Node3D.new()
	pond.name = "Pond"
	pond.position = position
	parent.add_child(pond)
	var water := MeshInstance3D.new()
	var water_mesh := CylinderMesh.new()
	water_mesh.top_radius = 2.3
	water_mesh.bottom_radius = 2.3
	water_mesh.height = 0.12
	water_mesh.radial_segments = 32
	water.mesh = water_mesh
	water.material_override = _material(palette["water"], 0.22)
	pond.add_child(water)
	for angle in [0.0, 1.57, 3.14, 4.71]:
		var reed := MeshInstance3D.new()
		var reed_mesh := CylinderMesh.new()
		reed_mesh.top_radius = 0.035
		reed_mesh.bottom_radius = 0.07
		reed_mesh.height = 0.8
		reed_mesh.radial_segments = 5
		reed.mesh = reed_mesh
		reed.material_override = _material(palette["leaf_dark"], 0.96)
		reed.position = Vector3(cos(angle) * 2.0, 0.45, sin(angle) * 2.0)
		pond.add_child(reed)
	var water_source := ResourceNodeScript.new() as Node3D
	water_source.name = "PondWaterSource"
	water_source.set("world", self)
	water_source.set("resource_id", "water")
	water_source.set("resource_amount", 2)
	water_source.set("resource_label", "Pond Water")
	water_source.set("node_id", "Sanctuary:PondWaterSource")
	water_source.position = Vector3(1.5, 0.0, 0.0)
	water_source.add_to_group("resource_node")
	water_source.add_to_group("interactable")
	pond.add_child(water_source)
	_register_resource_node(water_source)
	var water_marker := _label3d("REFILL", 0.15, palette["cream"])
	water_marker.position.y = 0.9
	water_source.add_child(water_marker)
	fishing_spot = StationScript.new() as Node3D
	fishing_spot.name = "PondFishingSpot"
	fishing_spot.set("world", self)
	fishing_spot.set("station_id", "fishing")
	fishing_spot.add_to_group("interactable")
	fishing_spot.position = Vector3(-1.65, 0.0, 0.55)
	pond.add_child(fishing_spot)
	var fishing_post := MeshInstance3D.new()
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.07
	post_mesh.bottom_radius = 0.1
	post_mesh.height = 1.0
	post_mesh.radial_segments = 6
	fishing_post.mesh = post_mesh
	fishing_post.material_override = _material(palette["wood_dark"], 0.92)
	fishing_post.position.y = 0.5
	fishing_spot.add_child(fishing_post)
	var fishing_line := MeshInstance3D.new()
	var line_mesh := CylinderMesh.new()
	line_mesh.top_radius = 0.02
	line_mesh.bottom_radius = 0.02
	line_mesh.height = 1.25
	line_mesh.radial_segments = 5
	fishing_line.mesh = line_mesh
	fishing_line.material_override = _material(palette["cream"], 0.55)
	fishing_line.position = Vector3(0.28, 0.34, -0.32)
	fishing_line.rotation_degrees.z = -22.0
	fishing_spot.add_child(fishing_line)
	fishing_bobber = MeshInstance3D.new()
	fishing_bobber.name = "FishingBobber"
	fishing_bobber.mesh = _sphere_mesh(0.075, 0.15, 8, 5)
	fishing_bobber.material_override = _material(palette["ember"], 0.98)
	fishing_bobber.position = Vector3(0.28, 0.08, -0.32)
	fishing_spot.add_child(fishing_bobber)
	var fishing_label := _label3d("FISHING SPOT", 0.15, palette["cream"])
	fishing_label.position = Vector3(0.0, 1.15, 0.0)
	fishing_spot.add_child(fishing_label)
	fishing_spot.set_meta("fishing_spot_id", "sanctuary_pond")

func _create_tidepool_fishing_spot(parent: Node3D, position: Vector3) -> void:
	coastal_fishing_spot = StationScript.new() as Node3D
	coastal_fishing_spot.name = "TidepoolFishingSpot"
	coastal_fishing_spot.set("world", self)
	coastal_fishing_spot.set("station_id", "fishing")
	coastal_fishing_spot.set_meta("fishing_spot_id", "sunlit_tidepool")
	coastal_fishing_spot.add_to_group("interactable")
	coastal_fishing_spot.position = position
	parent.add_child(coastal_fishing_spot)
	var post := MeshInstance3D.new()
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.08
	post_mesh.bottom_radius = 0.11
	post_mesh.height = 1.15
	post_mesh.radial_segments = 6
	post.mesh = post_mesh
	post.material_override = _material(palette["wood_dark"], 0.94)
	post.position = Vector3(-0.35, 0.58, 0.18)
	coastal_fishing_spot.add_child(post)
	var pennant := MeshInstance3D.new()
	var pennant_mesh := BoxMesh.new()
	pennant_mesh.size = Vector3(0.48, 0.26, 0.035)
	pennant.mesh = pennant_mesh
	pennant.material_override = _material(palette["water"], 0.96)
	pennant.position = Vector3(-0.08, 0.98, 0.18)
	coastal_fishing_spot.add_child(pennant)
	var line := MeshInstance3D.new()
	var line_mesh := CylinderMesh.new()
	line_mesh.top_radius = 0.02
	line_mesh.bottom_radius = 0.02
	line_mesh.height = 1.35
	line_mesh.radial_segments = 5
	line.mesh = line_mesh
	line.material_override = _material(palette["cream"], 0.58)
	line.position = Vector3(0.42, 0.42, -0.42)
	line.rotation_degrees.z = -23.0
	coastal_fishing_spot.add_child(line)
	coastal_fishing_bobber = MeshInstance3D.new()
	coastal_fishing_bobber.name = "TidepoolFishingBobber"
	coastal_fishing_bobber.mesh = _sphere_mesh(0.08, 0.16, 8, 5)
	coastal_fishing_bobber.material_override = _material(palette["cream"], 0.98)
	coastal_fishing_bobber.position = Vector3(0.42, 0.08, -0.42)
	coastal_fishing_spot.add_child(coastal_fishing_bobber)
	var label := _label3d("TIDEPOOL\nFISHING", 0.15, palette["cream"])
	label.position = Vector3(0.0, 1.35, 0.0)
	coastal_fishing_spot.add_child(label)

func _create_trade_stall(parent: Node3D, position: Vector3) -> void:
	trade_stall = StationScript.new() as Node3D
	trade_stall.name = "BazaarTradeStall"
	trade_stall.set("world", self)
	trade_stall.set("station_id", "bazaar")
	trade_stall.add_to_group("interactable")
	trade_stall.position = position
	parent.add_child(trade_stall)
	var counter := MeshInstance3D.new()
	var counter_mesh := BoxMesh.new()
	counter_mesh.size = Vector3(2.0, 0.7, 0.75)
	counter.mesh = counter_mesh
	counter.material_override = _material(palette["wood"], 0.92)
	counter.position.y = 0.35
	trade_stall.add_child(counter)
	var canopy := MeshInstance3D.new()
	var canopy_mesh := PrismMesh.new()
	canopy_mesh.size = Vector3(2.25, 1.3, 0.95)
	canopy.mesh = canopy_mesh
	canopy.material_override = _material(palette["sand"], 0.82)
	canopy.position = Vector3(0.0, 1.28, 0.0)
	trade_stall.add_child(canopy)
	var label := _label3d("BAZAAR\nTRADE", 0.16, palette["cream"])
	label.position = Vector3(0.0, 2.1, 0.0)
	trade_stall.add_child(label)

func _create_explorer_tent(parent: Node3D, position: Vector3) -> void:
	var tent := Node3D.new()
	tent.name = "ExplorerTent"
	tent.position = position
	parent.add_child(tent)
	var canopy := MeshInstance3D.new()
	var canopy_mesh := PrismMesh.new()
	canopy_mesh.size = Vector3(3.0, 2.6, 2.4)
	canopy.mesh = canopy_mesh
	canopy.material_override = _material(palette["leaf_dark"], 0.86)
	canopy.position.y = 1.3
	canopy.rotation_degrees.y = 45.0
	tent.add_child(canopy)
	var sign := _label3d("FOREST GATE", 0.22, palette["cream"])
	sign.position = Vector3(0, 2.8, 0)
	tent.add_child(sign)

func _create_route_gate(parent: Node3D, route_id: String, destination: String, position: Vector3, accent: Color) -> void:
	var gate := StationScript.new() as Node3D
	gate.name = destination.replace(" ", "") + "RouteGate"
	gate.set("world", self)
	gate.set("station_id", "route")
	gate.add_to_group("interactable")
	gate.add_to_group("route_gate")
	gate.set_meta("route_id", route_id)
	gate.set_meta("destination_id", destination)
	gate.set_meta("route_accent", accent)
	gate.position = position
	parent.add_child(gate)
	for post_position in [Vector3(-0.9, 1.15, 0.0), Vector3(0.9, 1.15, 0.0)]:
		var post := MeshInstance3D.new()
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.24, 2.3, 0.24)
		post.mesh = post_mesh
		post.material_override = _material(palette["wood_dark"], 0.96)
		post.position = post_position
		gate.add_child(post)
	var lintel := MeshInstance3D.new()
	var lintel_mesh := BoxMesh.new()
	lintel_mesh.size = Vector3(2.15, 0.26, 0.3)
	lintel.mesh = lintel_mesh
	lintel.material_override = _material(palette["wood"], 0.96)
	lintel.position.y = 2.22
	gate.add_child(lintel)
	var route_marker := MeshInstance3D.new()
	route_marker.name = "RouteMarker"
	route_marker.mesh = _sphere_mesh(0.24, 0.48, 8, 5)
	route_marker.material_override = _material(accent, 0.35, false, true)
	route_marker.position = Vector3(0.0, 1.75, -0.16)
	gate.add_child(route_marker)
	animated_beacons.append(route_marker)
	var portal_pad := MeshInstance3D.new()
	portal_pad.name = "PortalGroundPad"
	var portal_pad_mesh := CylinderMesh.new()
	portal_pad_mesh.top_radius = 1.38
	portal_pad_mesh.bottom_radius = 1.50
	portal_pad_mesh.height = 0.045
	portal_pad_mesh.radial_segments = 16
	portal_pad.mesh = portal_pad_mesh
	portal_pad.material_override = _material(accent.darkened(0.48), 0.94)
	portal_pad.position.y = 0.025
	gate.add_child(portal_pad)
	var portal_ring := MeshInstance3D.new()
	portal_ring.name = "PortalRing"
	var portal_ring_mesh := TorusMesh.new()
	portal_ring_mesh.inner_radius = 0.72
	portal_ring_mesh.outer_radius = 0.82
	portal_ring_mesh.rings = 10
	portal_ring_mesh.ring_segments = 20
	portal_ring.mesh = portal_ring_mesh
	portal_ring.material_override = _material(accent, 0.34, false, true)
	portal_ring.position = Vector3(0.0, 1.28, -0.18)
	portal_ring.rotation_degrees.x = 90.0
	gate.add_child(portal_ring)
	animated_beacons.append(portal_ring)
	for side in [-1.0, 1.0]:
		var gate_lantern := MeshInstance3D.new()
		gate_lantern.name = "GateLantern_%s" % side
		gate_lantern.mesh = _sphere_mesh(0.10, 0.22, 7, 4)
		gate_lantern.material_override = _material(accent.lightened(0.12), 0.42, false, true)
		gate_lantern.position = Vector3(side * 0.78, 1.52, -0.24)
		gate.add_child(gate_lantern)
	var route_label := _label3d(destination.to_upper() + "\nROUTE", 0.15, palette["cream"])
	route_label.name = "RouteLabel"
	route_label.position.y = 2.75
	gate.add_child(route_label)
	match destination:
		"Whisperwood":
			for side in [-1.0, 1.0]:
				var root := MeshInstance3D.new()
				var root_mesh := BoxMesh.new()
				root_mesh.size = Vector3(0.2, 1.45, 0.22)
				root.mesh = root_mesh
				root.material_override = _material(palette["leaf_dark"], 0.95)
				root.position = Vector3(side * 0.58, 0.72, 0.18)
				root.rotation_degrees.z = side * 28.0
				gate.add_child(root)
		"Sunlit Beach":
			var mast := MeshInstance3D.new()
			var mast_mesh := CylinderMesh.new()
			mast_mesh.top_radius = 0.06
			mast_mesh.bottom_radius = 0.09
			mast_mesh.height = 2.8
			mast_mesh.radial_segments = 7
			mast.mesh = mast_mesh
			mast.material_override = _material(palette["wood"], 0.95)
			mast.position = Vector3(0.0, 1.35, 0.22)
			gate.add_child(mast)
			var sail := MeshInstance3D.new()
			var sail_mesh := PrismMesh.new()
			sail_mesh.size = Vector3(0.85, 0.72, 0.08)
			sail.mesh = sail_mesh
			sail.material_override = _material(accent, 0.82)
			sail.position = Vector3(0.34, 1.85, 0.22)
			gate.add_child(sail)
		"Ember Ridge":
			for index in 3:
				var basalt := MeshInstance3D.new()
				var basalt_mesh := CylinderMesh.new()
				basalt_mesh.top_radius = 0.26
				basalt_mesh.bottom_radius = 0.42
				basalt_mesh.height = 0.72 + float(index) * 0.18
				basalt_mesh.radial_segments = 6
				basalt.mesh = basalt_mesh
				basalt.material_override = _material(Color("#4d4b55"), 0.96)
				basalt.position = Vector3(-0.5 + float(index) * 0.5, basalt_mesh.height * 0.5, 0.25)
				basalt.rotation_degrees.z = float(index - 1) * 7.0
				gate.add_child(basalt)
		"Glass Desert":
			var shade := MeshInstance3D.new()
			var shade_mesh := PrismMesh.new()
			shade_mesh.size = Vector3(2.1, 0.18, 1.15)
			shade.mesh = shade_mesh
			shade.material_override = _material(palette["sand"], 0.78)
			shade.position = Vector3(0.0, 2.0, 0.3)
			shade.rotation_degrees.z = -9.0
			gate.add_child(shade)
			var sun_disk := MeshInstance3D.new()
			sun_disk.mesh = _sphere_mesh(0.24, 0.48, 8, 5)
			sun_disk.material_override = _material(accent, 0.32, false, true)
			sun_disk.position = Vector3(0.0, 2.25, 0.16)
			gate.add_child(sun_disk)
		"Sunken Dungeon":
			for side in [-1.0, 1.0]:
				var stone_portal := MeshInstance3D.new()
				var portal_mesh := BoxMesh.new()
				portal_mesh.size = Vector3(0.42, 2.0, 0.46)
				stone_portal.mesh = portal_mesh
				stone_portal.material_override = _material(Color("#59606b"), 0.98)
				stone_portal.position = Vector3(side * 0.68, 1.0, 0.32)
				gate.add_child(stone_portal)
			var rune := MeshInstance3D.new()
			var rune_mesh := TorusMesh.new()
			rune_mesh.inner_radius = 0.3
			rune_mesh.outer_radius = 0.38
			rune.mesh = rune_mesh
			rune.material_override = _material(accent, 0.42, false, true)
			rune.position = Vector3(0.0, 1.42, 0.2)
			rune.rotation_degrees.x = 90.0
			gate.add_child(rune)

func _refresh_route_gate_visuals() -> void:
	if session == null or not session.has_method("route_is_unlocked"):
		return
	var signature_parts: Array[String] = []
	for gate_node in get_tree().get_nodes_in_group("route_gate"):
		var gate_for_signature := gate_node as Node3D
		if gate_for_signature == null:
			continue
		var destination_for_signature := str(gate_for_signature.get_meta("destination_id", ""))
		signature_parts.append(destination_for_signature + ":" + str(session.call("route_is_unlocked", destination_for_signature)))
	var signature := "|".join(signature_parts)
	if signature == route_gate_unlock_signature:
		return
	route_gate_unlock_signature = signature
	for gate_node in get_tree().get_nodes_in_group("route_gate"):
		var gate := gate_node as Node3D
		if gate == null:
			continue
		var destination := str(gate.get_meta("destination_id", ""))
		var unlocked := bool(session.call("route_is_unlocked", destination))
		gate.set_meta("route_locked", not unlocked)
		var route_label := gate.get_node_or_null("RouteLabel") as Label3D
		if route_label != null:
			route_label.text = destination.to_upper() + ("\nROUTE" if unlocked else "\nLOCKED")
		var marker := gate.get_node_or_null("RouteMarker") as MeshInstance3D
		if marker != null:
			var accent_variant: Variant = gate.get_meta("route_accent", palette["muted"])
			var accent: Color = accent_variant as Color if accent_variant is Color else palette["muted"]
			marker.material_override = _material(accent if unlocked else palette["muted"], 0.35 if unlocked else 0.68, false, unlocked)

func _resource_zone_id(parent: Node3D) -> String:
	if parent == sanctuary_zone or (parent != null and parent.name == "Sanctuary"):
		return "Sanctuary"
	match parent.name if parent != null else "":
		"Whisperwood": return "Whisperwood"
		"SunlitBeach": return "Sunlit Beach"
		"EmberRidge": return "Ember Ridge"
		"GlassDesert": return "Glass Desert"
		"SunkenDungeon": return "Sunken Dungeon"
	return str(parent.name) if parent != null else ""

func _register_resource_node(node: Node) -> void:
	if session == null or node == null or not session.has_method("register_resource_node"):
		return
	var parent := node.get_parent() as Node3D
	session.call("register_resource_node", str(node.get("node_id")), _resource_zone_id(parent), str(node.get("resource_id")), int(node.get("resource_amount")), int(node.get("required_contacts")), str(node.get("discovery_id")), node, str(node.get_meta("resource_grade", "standard")))

func _create_tree(parent: Node3D, position: Vector3, size: float, resource_id: String, amount: int) -> Node3D:
	var tree := ResourceNodeScript.new() as Node3D
	tree.name = "WhisperwoodTree"
	tree.set("world", self)
	tree.set("resource_id", resource_id)
	tree.set("resource_amount", amount)
	tree.set("resource_label", "Wood")
	tree.set("required_contacts", 3 if parent == sanctuary_zone else (2 if parent == forest_zone else 1))
	tree.set("node_id", "%s:%s:%d" % [parent.name, resource_id, parent.get_child_count()])
	tree.position = position
	tree.scale = Vector3.ONE * size
	tree.set_meta("asset_id", _tree_asset_path(parent.name))
	tree.set_meta("ground_pivot", [0.0, 0.0, 0.0])
	tree.set_meta("visual_scale", size)
	tree.add_to_group("resource_node")
	tree.add_to_group("interactable")
	parent.add_child(tree)
	_register_resource_node(tree)
	var trunk := MeshInstance3D.new()
	trunk.name = "Trunk"
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.25
	trunk_mesh.bottom_radius = 0.36
	trunk_mesh.height = 2.25
	trunk_mesh.radial_segments = 7
	trunk.mesh = trunk_mesh
	trunk.material_override = _material(palette["wood_dark"], 0.92)
	trunk.position.y = 1.12
	tree.add_child(trunk)
	var canopy := MeshInstance3D.new()
	canopy.mesh = _sphere_mesh(1.1, 2.2, 10, 6)
	canopy.material_override = _material(palette["leaf"], 0.92)
	canopy.position = Vector3(0, 2.55, 0)
	tree.add_child(canopy)
	var crown := MeshInstance3D.new()
	crown.mesh = _sphere_mesh(0.72, 1.45, 9, 5)
	crown.material_override = _material(palette["leaf_dark"], 0.94)
	crown.position = Vector3(0.6, 3.05, 0.15)
	tree.add_child(crown)
	var stage := _label3d("WOOD", 0.14, palette["cream"])
	stage.name = "ResourceStage"
	stage.position = Vector3(0.0, 3.85, 0.0)
	tree.add_child(stage)
	var contact_marks := Node3D.new()
	contact_marks.name = "ContactMarks"
	for index in 3:
		var mark := MeshInstance3D.new()
		mark.name = "ChopMark_%d" % index
		var mark_mesh := BoxMesh.new()
		mark_mesh.size = Vector3(0.15, 0.11, 0.045)
		mark.mesh = mark_mesh
		mark.material_override = _material(palette["wood"].lightened(0.22), 0.86, false, true)
		mark.position = Vector3(-0.22 + float(index) * 0.22, 1.18 + float(index % 2) * 0.14, -0.36)
		mark.rotation_degrees.z = -18.0 + float(index) * 17.0
		contact_marks.add_child(mark)
	tree.add_child(contact_marks)
	var sourced_model := _add_sourced_model(tree, _tree_asset_path(parent.name), 0.52, Vector3(0.0, 0.12, 0.0))
	trunk.visible = not sourced_model
	canopy.visible = not sourced_model
	crown.visible = not sourced_model
	# The trunk is the tree's physical contact sub-asset. It is measured from the
	# same generated geometry that supplies the foot-bearing obstacle; imported
	# bark/branches and the illustrated canopy remain presentation-only so they
	# cannot become an invisible wall around the player.
	var tree_shape := _attach_measured_cylinder_collision(tree, trunk, "TreeCollision", "TreeHitbox", [], true)
	var tree_measurement_source := "trunk_mesh_bounds"
	tree.set_meta("collision_source", tree_measurement_source)
	if tree_shape.shape is CylinderShape3D:
		var measured_cylinder := tree_shape.shape as CylinderShape3D
		tree.set_meta("collision_center", [tree_shape.position.x, tree_shape.position.y, tree_shape.position.z])
		tree.set_meta("collision_radius", measured_cylinder.radius)
		tree.set_meta("measured_collision_height", measured_cylinder.height)
	tree.call("_refresh_contact_visual")
	sway_nodes.append({"node": tree, "phase": float(sway_nodes.size()) * 0.73})
	if parent == sanctuary_zone:
		sanctuary_nodes.append(tree)
	else:
		forest_nodes.append(tree)
	return tree

func _create_rock(parent: Node3D, position: Vector3, resource_id: String, amount: int, resource_label := "", resource_grade := "standard") -> Node3D:
	var rock := ResourceNodeScript.new() as Node3D
	rock.name = "StoneNode"
	rock.set("world", self)
	rock.set("resource_id", resource_id)
	rock.set("resource_amount", amount)
	rock.set("resource_label", "Stone" if resource_label.is_empty() else resource_label)
	rock.set("required_contacts", 2 if parent == forest_zone and resource_id == "stone" else 1)
	rock.set("node_id", "%s:%s:%d" % [parent.name, resource_id, parent.get_child_count()])
	rock.set_meta("resource_grade", resource_grade)
	if parent.name == "EmberRidge" and resource_id == "ore":
		rock.set_meta("route_branch", "quarry")
	rock.position = position
	rock.add_to_group("interactable")
	rock.add_to_group("resource_node")
	parent.add_child(rock)
	_register_resource_node(rock)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _sphere_mesh(0.7, 0.9, 7, 4)
	mesh_instance.material_override = _material(Color("#c77b4e") if resource_id in ["ore", "sunstone"] else palette["stone"], 0.98)
	mesh_instance.scale = Vector3(1.25, 0.72, 0.92)
	mesh_instance.position.y = 0.42
	rock.add_child(mesh_instance)
	var stage := _label3d(rock.get("resource_label").to_upper(), 0.14, palette["cream"])
	stage.name = "ResourceStage"
	stage.position = Vector3(0.0, 1.18, 0.0)
	rock.add_child(stage)
	var contact_marks := Node3D.new()
	contact_marks.name = "ContactMarks"
	for index in 3:
		var mark := MeshInstance3D.new()
		mark.name = "CrackMark_%d" % index
		var mark_mesh := BoxMesh.new()
		mark_mesh.size = Vector3(0.14, 0.045, 0.035)
		mark.mesh = mark_mesh
		mark.material_override = _material(palette["stone"].darkened(0.28), 0.92)
		mark.position = Vector3(-0.22 + float(index) * 0.22, 0.55 + float(index % 2) * 0.08, -0.64)
		mark.rotation_degrees.z = -25.0 + float(index) * 24.0
		contact_marks.add_child(mark)
	rock.add_child(contact_marks)
	var depleted_rubble := Node3D.new()
	depleted_rubble.name = "DepletedVisual"
	for index in 3:
		var rubble := MeshInstance3D.new()
		rubble.name = "Rubble_%d" % index
		rubble.mesh = _sphere_mesh(0.16 + float(index) * 0.03, 0.24 + float(index) * 0.04, 6, 3)
		rubble.material_override = _material(palette["stone"].darkened(0.12), 0.96)
		rubble.position = Vector3(-0.32 + float(index) * 0.30, 0.13, 0.12 * float(index % 2))
		depleted_rubble.add_child(rubble)
	depleted_rubble.visible = false
	rock.add_child(depleted_rubble)
	var sourced_model := false
	if resource_id != "ore":
		sourced_model = _add_sourced_model(rock, SOURCED_ROCK_ASSET, 0.55, Vector3(0.0, 0.14, 0.0))
	var sourced_root := _find_sourced_model(rock)
	mesh_instance.visible = not sourced_model
	var collision_root := sourced_root if sourced_root != null else mesh_instance
	var rock_hitbox := _attach_measured_box_collision(rock, collision_root, "RockCollision", "RockHitbox")
	rock.set_meta("collision_source", str(rock_hitbox.get_meta("measurement_source", "runtime_visible_mesh_bounds")))
	rock.call("_refresh_contact_visual")
	forest_nodes.append(rock)
	return rock

func _create_flower_patch(parent: Node3D, position: Vector3, color: Color) -> void:
	var patch := Node3D.new()
	patch.name = "Wildflowers"
	patch.position = position
	parent.add_child(patch)
	for index in 5:
		var flower := MeshInstance3D.new()
		flower.mesh = _sphere_mesh(0.11, 0.18, 6, 3)
		flower.material_override = _material(color.lightened(0.16 + float(index) * 0.03), 0.9)
		flower.position = Vector3((float(index) - 2.0) * 0.24, 0.16, sin(float(index) * 2.0) * 0.22)
		patch.add_child(flower)

func _create_fiber_patch(parent: Node3D, position: Vector3) -> void:
	var patch := ResourceNodeScript.new() as Node3D
	patch.name = "ReedFiberPatch"
	patch.set("world", self)
	patch.set("resource_id", "fiber")
	patch.set("resource_amount", 2)
	patch.set("resource_label", "Fiber")
	patch.set("node_id", "%s:FiberPatch:%d" % [parent.name, parent.get_child_count()])
	patch.position = position
	patch.add_to_group("resource_node")
	patch.add_to_group("interactable")
	parent.add_child(patch)
	_register_resource_node(patch)
	for index in 6:
		var blade := MeshInstance3D.new()
		blade.mesh = _sphere_mesh(0.07, 0.62, 5, 3)
		blade.material_override = _material(palette["leaf"], 0.9)
		blade.position = Vector3((float(index) - 2.5) * 0.18, 0.34, sin(float(index) * 1.6) * 0.18)
		patch.add_child(blade)
	var depleted_bundle := Node3D.new()
	depleted_bundle.name = "DepletedVisual"
	var bundle_mesh := BoxMesh.new()
	bundle_mesh.size = Vector3(0.72, 0.16, 0.30)
	var bundle := MeshInstance3D.new()
	bundle.name = "CutFiberBundle"
	bundle.mesh = bundle_mesh
	bundle.material_override = _material(palette["leaf_dark"], 0.92)
	bundle.position = Vector3(0.0, 0.10, 0.0)
	depleted_bundle.add_child(bundle)
	depleted_bundle.visible = false
	patch.add_child(depleted_bundle)
	var marker := _label3d("FIBER", 0.15, palette["cream"])
	marker.position.y = 0.95
	patch.add_child(marker)

func _create_mushroom(parent: Node3D, position: Vector3, stable_id := "Whisperwood:WhisperglassMushroom") -> void:
	var mushroom := ResourceNodeScript.new() as Node3D
	mushroom.name = "WhisperglassMushroom"
	mushroom.set("world", self)
	mushroom.set("resource_id", "berries")
	mushroom.set("resource_amount", 1)
	mushroom.set("resource_label", "Whisperglass")
	mushroom.set("discovery_id", "Whisperglass")
	mushroom.set("node_id", stable_id)
	mushroom.set_meta("route_branch", "grove")
	mushroom.position = position
	mushroom.add_to_group("resource_node")
	mushroom.add_to_group("interactable")
	parent.add_child(mushroom)
	_register_resource_node(mushroom)
	var stem := MeshInstance3D.new()
	stem.mesh = _sphere_mesh(0.09, 0.38, 6, 3)
	stem.material_override = _material(palette["cream"], 0.9)
	stem.position.y = 0.2
	mushroom.add_child(stem)
	var cap := MeshInstance3D.new()
	cap.mesh = _sphere_mesh(0.28, 0.24, 8, 4)
	cap.material_override = _material(Color("#b86da9"), 0.78, false, true)
	cap.scale = Vector3(1.0, 0.6, 1.0)
	cap.position.y = 0.45
	mushroom.add_child(cap)
	var sourced_model := _add_sourced_model(mushroom, SOURCED_MUSHROOM_ASSET, 1.3, Vector3(0.0, 0.02, 0.0))
	stem.visible = not sourced_model
	cap.visible = not sourced_model
	var marker := _label3d("DISCOVERY", 0.16, palette["cream"])
	marker.position.y = 0.9
	mushroom.add_child(marker)
	forest_nodes.append(mushroom)

func _create_shell_discovery(parent: Node3D, position: Vector3, stable_id := "") -> void:
	var shell := ResourceNodeScript.new() as Node3D
	shell.name = "TideglassShell"
	shell.set("world", self)
	shell.set("resource_id", "shell")
	shell.set("resource_amount", 1)
	shell.set("resource_label", "Tideglass Shell")
	shell.set("discovery_id", "Tideglass")
	shell.set("node_id", stable_id if not stable_id.is_empty() else "%s:TideglassShell" % parent.name)
	shell.set_meta("route_branch", "tidepool")
	shell.position = position
	shell.add_to_group("resource_node")
	shell.add_to_group("interactable")
	parent.add_child(shell)
	_register_resource_node(shell)
	var shell_mesh := MeshInstance3D.new()
	shell_mesh.mesh = _sphere_mesh(0.34, 0.18, 10, 4)
	shell_mesh.material_override = _material(Color("#e8c9b2"), 0.7, false, true)
	shell_mesh.scale = Vector3(1.0, 0.55, 0.78)
	shell_mesh.position.y = 0.16
	shell.add_child(shell_mesh)
	var marker := _label3d("DISCOVERY", 0.16, palette["cream"])
	marker.position.y = 0.65
	shell.add_child(marker)

func _create_relic_discovery(parent: Node3D, position: Vector3) -> void:
	var relic := ResourceNodeScript.new() as Node3D
	relic.name = "AetherRelic"
	relic.set("world", self)
	relic.set("resource_id", "relic")
	relic.set("resource_amount", 1)
	relic.set("resource_label", "Aether Relic")
	relic.set("discovery_id", "Aether Relic")
	relic.set("node_id", "%s:AetherRelic" % parent.name)
	relic.set_meta("route_branch", "vault")
	relic.position = position
	relic.add_to_group("resource_node")
	relic.add_to_group("interactable")
	parent.add_child(relic)
	_register_resource_node(relic)
	var core := MeshInstance3D.new()
	var core_mesh := PrismMesh.new()
	core_mesh.size = Vector3(0.5, 1.1, 0.5)
	core.mesh = core_mesh
	core.material_override = _material(Color("#bda6ff"), 0.22, false, true)
	core.position.y = 0.62
	relic.add_child(core)
	var halo := MeshInstance3D.new()
	var halo_mesh := TorusMesh.new()
	halo_mesh.inner_radius = 0.48
	halo_mesh.outer_radius = 0.56
	halo.mesh = halo_mesh
	halo.material_override = _material(Color("#d6c7ff"), 0.2, false, true)
	halo.position.y = 0.62
	relic.add_child(halo)
	animated_beacons.append(halo)
	var marker := _label3d("DISCOVERY", 0.16, palette["cream"])
	marker.position.y = 1.45
	relic.add_child(marker)

func _create_expedition_inscription(parent: Node3D, position: Vector3, inscription_id: String) -> void:
	var definition := ContentRegistry.expedition_inscription_definition(inscription_id)
	if definition.is_empty():
		return
	var inscription := StationScript.new() as Node3D
	inscription.name = "Inscription_%s" % inscription_id
	inscription.set("world", self)
	inscription.set("station_id", "lore_inscription")
	inscription.set_meta("inscription_id", inscription_id)
	inscription.set_meta("route_branch", str(definition.get("branch_id", "")))
	inscription.add_to_group("interactable")
	inscription.add_to_group("expedition_inscription")
	inscription.position = position
	parent.add_child(inscription)
	var post := MeshInstance3D.new()
	post.name = "InscriptionPost"
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.22, 1.55, 0.22)
	post.mesh = post_mesh
	post.material_override = _material(palette["wood_dark"], 0.96)
	post.position.y = 0.78
	inscription.add_child(post)
	var plaque := MeshInstance3D.new()
	plaque.name = "InscriptionPlaque"
	var plaque_mesh := BoxMesh.new()
	plaque_mesh.size = Vector3(1.25, 0.92, 0.16)
	plaque.mesh = plaque_mesh
	plaque.material_override = _material(palette["stone"].lightened(0.12), 0.96)
	plaque.position = Vector3(0.0, 1.15, -0.03)
	inscription.add_child(plaque)
	var glyph_lines := Node3D.new()
	glyph_lines.name = "InscriptionGlyphs"
	for index in 3:
		var glyph := MeshInstance3D.new()
		glyph.name = "Glyph_%d" % index
		var glyph_mesh := BoxMesh.new()
		glyph_mesh.size = Vector3(0.60 - float(index) * 0.11, 0.055, 0.025)
		glyph.mesh = glyph_mesh
		glyph.material_override = _material(palette["violet"].darkened(0.16), 0.88, false, true)
		glyph.position = Vector3(0.0, 1.36 - float(index) * 0.18, -0.125)
		glyph_lines.add_child(glyph)
	inscription.add_child(glyph_lines)
	var label := _label3d("INSCRIPTION\n%s" % str(definition.get("title", "LORE")), 0.13, palette["cream"])
	label.name = "InscriptionLabel"
	label.position = Vector3(0.0, 2.02, 0.0)
	inscription.add_child(label)
	_attach_measured_box_collision(inscription, inscription, "InscriptionCollision", "InscriptionHitbox")

func _create_cactus(parent: Node3D, position: Vector3) -> void:
	var cactus := ResourceNodeScript.new() as Node3D
	cactus.name = "DesertCactus"
	cactus.set("world", self)
	cactus.set("resource_id", "fiber")
	cactus.set("resource_amount", 2)
	cactus.set("resource_label", "Cactus Fiber")
	cactus.set("node_id", "%s:Cactus:%d" % [parent.name, parent.get_child_count()])
	cactus.set_meta("route_branch", "oasis")
	cactus.position = position
	cactus.add_to_group("resource_node")
	cactus.add_to_group("interactable")
	parent.add_child(cactus)
	_register_resource_node(cactus)
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.16
	trunk_mesh.bottom_radius = 0.22
	trunk_mesh.height = 1.45
	trunk_mesh.radial_segments = 7
	trunk.mesh = trunk_mesh
	trunk.material_override = _material(Color("#6d9b69"), 0.88)
	trunk.position.y = 0.74
	cactus.add_child(trunk)
	var arm := MeshInstance3D.new()
	var arm_mesh := CylinderMesh.new()
	arm_mesh.top_radius = 0.11
	arm_mesh.bottom_radius = 0.14
	arm_mesh.height = 0.72
	arm_mesh.radial_segments = 7
	arm.mesh = arm_mesh
	arm.material_override = trunk.material_override
	arm.position = Vector3(0.42, 0.82, 0.0)
	arm.rotation_degrees.z = -58.0
	cactus.add_child(arm)
	var marker := _label3d("FIBER", 0.15, palette["cream"])
	marker.position.y = 1.75
	cactus.add_child(marker)

func _create_guardian(parent: Node3D, position: Vector3, guardian_id := "forest_slime", enemy_color := Color("#c66b85")) -> Node3D:
	var definition := ContentRegistry.guardian_definition(guardian_id)
	if definition.is_empty():
		return null
	var guardian := GuardianScript.new() as CharacterBody3D
	guardian.process_mode = Node.PROCESS_MODE_PAUSABLE
	guardian.name = guardian_id
	guardian.set("world", self)
	guardian.set("target", player)
	guardian.set("guardian_id", guardian_id)
	guardian.set("enemy_label", str(definition.get("enemy_label", guardian_id.to_upper())))
	guardian.set("reward_id", str(definition.get("reward_id", "")))
	guardian.set("reward_amount", int(definition.get("reward_amount", 1)))
	guardian.set("attack_damage", int(definition.get("attack_damage", 5)))
	guardian.set("health", int(definition.get("health", 18)))
	guardian.set("max_health", int(definition.get("health", 18)))
	guardian.set("behavior_id", str(definition.get("behavior_id", "chaser")))
	guardian.set("move_speed", float(definition.get("move_speed", 1.7)))
	guardian.set("attack_range", float(definition.get("attack_range", 2.4)))
	guardian.set("attack_windup_duration", float(definition.get("attack_windup", 0.38)))
	guardian.set("attack_cooldown_duration", float(definition.get("attack_cooldown", 1.35)))
	guardian.set("attack_recovery_duration", float(definition.get("attack_recovery", 0.34)))
	guardian.set("pursuit_radius", float(definition.get("pursuit_radius", 13.0)))
	guardian.position = position
	guardian.add_to_group("guardian")
	parent.add_child(guardian)
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	# The visible creature is centered on the guardian root and bobs from that
	# local pivot. The shape is assigned from the finished visual envelope below;
	# guardian.gd mirrors animation scale and bob onto it every frame.
	collision.set_meta("visual_anchor", "Visual")
	collision.set_meta("anchor_mode", "animated_visual_pivot")
	guardian.add_child(collision)
	var visual := Node3D.new()
	visual.name = "Visual"
	guardian.add_child(visual)
	var slime := MeshInstance3D.new()
	slime.mesh = _sphere_mesh(0.9, 1.45, 14, 8)
	slime.material_override = _material(enemy_color, 0.62, false, true)
	slime.scale = Vector3(1.18, 0.82, 1.18)
	visual.add_child(slime)
	var eye_left := MeshInstance3D.new()
	eye_left.mesh = _sphere_mesh(0.095, 0.19, 8, 4)
	eye_left.material_override = _material(palette["cream"], 0.5)
	eye_left.position = Vector3(-0.27, 0.18, -0.72)
	visual.add_child(eye_left)
	var eye_right: MeshInstance3D = eye_left.duplicate() as MeshInstance3D
	eye_right.position.x = 0.27
	visual.add_child(eye_right)
	var label := _label3d(str(definition.get("enemy_label", guardian_id.to_upper())), 0.18, palette["cream"])
	guardian.set("health_label", label)
	label.position = Vector3(0, 1.7, 0)
	visual.add_child(label)
	var guardian_measurement := _runtime_asset_measurement(visual)
	if bool(guardian_measurement.get("valid", false)):
		var guardian_bounds: AABB = guardian_measurement.get("bounds", AABB())
		var guardian_box := BoxShape3D.new()
		guardian_box.size = guardian_bounds.size
		collision.shape = guardian_box
		collision.position = guardian_bounds.position + guardian_bounds.size * 0.5
		_set_measured_collision_metadata(collision, guardian_measurement, guardian_bounds)
		collision.set_meta("base_shape_size", [guardian_bounds.size.x, guardian_bounds.size.y, guardian_bounds.size.z])
		collision.set_meta("base_shape_center", [collision.position.x, collision.position.y, collision.position.z])
	else:
		push_error("Guardian '%s' has no visible mesh bounds; refusing to create an unmeasured hitbox." % guardian_id)
		collision.disabled = true
	return guardian

func _create_farm_plot(parent: Node3D, position: Vector3) -> void:
	farm_plot = FarmPlotScript.new() as Node3D
	farm_plot.name = "SanctuaryFarmPlot"
	farm_plot.set("world", self)
	farm_plot.position = position
	farm_plot.add_to_group("interactable")
	parent.add_child(farm_plot)
	var soil := MeshInstance3D.new()
	soil.name = "Soil"
	var soil_mesh := BoxMesh.new()
	soil_mesh.size = Vector3(4.0, 0.18, 2.8)
	soil.mesh = soil_mesh
	soil.material_override = _material(palette["wood_dark"], 1.0)
	soil.position.y = 0.12
	farm_plot.add_child(soil)
	for row in 3:
		var furrow := MeshInstance3D.new()
		var furrow_mesh := BoxMesh.new()
		furrow_mesh.size = Vector3(3.4, 0.04, 0.05)
		furrow.mesh = furrow_mesh
		furrow.material_override = _material(palette["sand"].darkened(0.18), 1.0)
		furrow.position = Vector3(0.0, 0.23, -0.8 + float(row) * 0.8)
		soil.add_child(furrow)
	var label := _label3d("GARDEN PLOT", 0.2, palette["cream"])
	label.name = "FarmState"
	label.position = Vector3(0.0, 1.15, 0.0)
	farm_plot.add_child(label)
	_refresh_farm_plot()

func _create_livestock_pen(parent: Node3D, position: Vector3) -> void:
	livestock_pen = StationScript.new() as Node3D
	livestock_pen.name = "CloverLivestockPen"
	livestock_pen.set("world", self)
	livestock_pen.set("station_id", "livestock")
	livestock_pen.add_to_group("interactable")
	livestock_pen.position = position
	parent.add_child(livestock_pen)
	var ground := MeshInstance3D.new()
	var ground_mesh := BoxMesh.new()
	ground_mesh.size = Vector3(4.1, 0.14, 2.75)
	ground.mesh = ground_mesh
	ground.material_override = _material(palette["sand"].darkened(0.16), 1.0)
	ground.position.y = 0.08
	livestock_pen.add_child(ground)
	for post_position in [Vector3(-1.85, 0.72, -1.15), Vector3(1.85, 0.72, -1.15), Vector3(-1.85, 0.72, 1.15), Vector3(1.85, 0.72, 1.15)]:
		var post := MeshInstance3D.new()
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.16, 1.35, 0.16)
		post.mesh = post_mesh
		post.material_override = _material(palette["wood_dark"], 0.92)
		post.position = post_position
		livestock_pen.add_child(post)
	for fence_data in [[Vector3(0.0, 0.48, -1.15), Vector3(3.7, 0.55, 0.12)], [Vector3(0.0, 0.48, 1.15), Vector3(3.7, 0.55, 0.12)], [Vector3(-1.85, 0.48, 0.0), Vector3(0.12, 0.55, 2.3)], [Vector3(1.85, 0.48, 0.0), Vector3(0.12, 0.55, 2.3)]]:
		var rail := MeshInstance3D.new()
		var rail_mesh := BoxMesh.new()
		rail_mesh.size = fence_data[1]
		rail.mesh = rail_mesh
		rail.material_override = _material(palette["wood"], 0.9)
		rail.position = fence_data[0]
		livestock_pen.add_child(rail)
	var trough := MeshInstance3D.new()
	var trough_mesh := BoxMesh.new()
	trough_mesh.size = Vector3(1.0, 0.28, 0.42)
	trough.mesh = trough_mesh
	trough.material_override = _material(palette["wood_dark"], 0.96)
	trough.position = Vector3(0.0, 0.24, -0.62)
	livestock_pen.add_child(trough)
	var label := _label3d("LIVESTOCK PEN\nSHELL", 0.18, palette["cream"])
	label.name = "LivestockLabel"
	label.position = Vector3(0.0, 1.85, 0.0)
	livestock_pen.add_child(label)
	var animal := LivestockAnimalScript.new() as Node3D
	animal.process_mode = Node.PROCESS_MODE_PAUSABLE
	animal.name = "Clover"
	animal.set("world", self)
	animal.set("animal_id", "clover")
	animal.position = Vector3(0.0, 0.0, 0.2)
	livestock_pen.add_child(animal)
	var cow_scene := load("res://assets/sourced/quaternius-farm-animals/Farm Animals by @Quaternius/FBX/Cow.fbx") as PackedScene
	if cow_scene != null:
		var sourced_cow := cow_scene.instantiate() as Node3D
		if sourced_cow != null:
			sourced_cow.process_mode = Node.PROCESS_MODE_PAUSABLE
			sourced_cow.name = "SourcedPaddockCow"
			sourced_cow.position = Vector3(1.05, 0.02, 0.28)
			# The FBX source is authored much larger than the player-facing paddock
			# scale. Keep the actor human-world sized instead of letting it read as
			# a giant mascot walking through a toy pen.
			sourced_cow.scale = Vector3.ONE * 0.27
			livestock_pen.add_child(sourced_cow)
			var cow_animation := sourced_cow.find_child("AnimationPlayer", true, false) as AnimationPlayer
			if cow_animation != null:
				var preferred_clip := ""
				for candidate_clip in ["Idle", "Armature|Idle", "Walk", "Armature|Walk"]:
					if cow_animation.has_animation(candidate_clip):
						preferred_clip = candidate_clip
						break
				if not preferred_clip.is_empty():
					cow_animation.play(preferred_clip)
	var visual := Node3D.new()
	visual.name = "Visual"
	animal.add_child(visual)
	var body := MeshInstance3D.new()
	body.mesh = _sphere_mesh(0.42, 0.72, 10, 6)
	body.material_override = _material(Color("#f0eee2"), 0.95)
	body.scale = Vector3(1.0, 0.78, 1.18)
	body.position.y = 0.54
	visual.add_child(body)
	for leg_position in [Vector3(-0.22, 0.25, -0.18), Vector3(0.22, 0.25, -0.18), Vector3(-0.22, 0.25, 0.18), Vector3(0.22, 0.25, 0.18)]:
		var leg := MeshInstance3D.new()
		var leg_mesh := CylinderMesh.new()
		leg_mesh.top_radius = 0.055
		leg_mesh.bottom_radius = 0.07
		leg_mesh.height = 0.34
		leg_mesh.radial_segments = 6
		leg.mesh = leg_mesh
		leg.material_override = _material(palette["wood_dark"], 0.92)
		leg.position = leg_position
		visual.add_child(leg)
	var head := MeshInstance3D.new()
	head.mesh = _sphere_mesh(0.27, 0.5, 9, 5)
	head.material_override = _material(Color("#f0eee2"), 0.95)
	head.position = Vector3(0.0, 0.74, -0.48)
	visual.add_child(head)
	var comb := MeshInstance3D.new()
	comb.mesh = _sphere_mesh(0.08, 0.16, 6, 3)
	comb.material_override = _material(palette["danger"], 0.7, false, true)
	comb.position = Vector3(0.0, 1.02, -0.49)
	visual.add_child(comb)

func _create_workshop(parent: Node3D, position: Vector3) -> void:
	workshop = StationScript.new() as Node3D
	workshop.name = "WorkshopStation"
	workshop.set("world", self)
	workshop.set("station_id", "workshop")
	workshop.add_to_group("interactable")
	workshop.position = position
	parent.add_child(workshop)
	var platform := MeshInstance3D.new()
	var platform_mesh := BoxMesh.new()
	platform_mesh.size = Vector3(3.2, 0.22, 2.2)
	platform.mesh = platform_mesh
	platform.material_override = _material(palette["sand"], 0.96)
	platform.position.y = 0.12
	workshop.add_child(platform)
	for offset in [Vector3(-0.9, 0.75, -0.45), Vector3(0.0, 0.75, -0.45), Vector3(0.9, 0.75, -0.45)]:
		var post := MeshInstance3D.new()
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.18, 1.35, 0.18)
		post.mesh = post_mesh
		post.material_override = _material(palette["wood_dark"], 0.92)
		post.position = offset
		workshop.add_child(post)
	var awning := MeshInstance3D.new()
	var awning_mesh := BoxMesh.new()
	awning_mesh.size = Vector3(3.5, 0.18, 1.3)
	awning.mesh = awning_mesh
	awning.material_override = _material(palette["leaf_dark"], 0.88)
	awning.position = Vector3(0.0, 1.52, -0.32)
	awning.rotation_degrees.z = -4.0
	workshop.add_child(awning)
	var label := _label3d("WORKSHOP", 0.2, palette["cream"])
	label.name = "StationLabel"
	label.position = Vector3(0.0, 2.0, 0.0)
	workshop.add_child(label)

func _create_library_station(parent: Node3D, position: Vector3) -> void:
	library_station = StationScript.new() as Node3D
	library_station.name = "ArchiveStation"
	library_station.set("world", self)
	library_station.set("station_id", "library")
	library_station.add_to_group("interactable")
	library_station.position = position
	parent.add_child(library_station)
	var desk := MeshInstance3D.new()
	var desk_mesh := BoxMesh.new()
	desk_mesh.size = Vector3(1.8, 0.45, 1.1)
	desk.mesh = desk_mesh
	desk.material_override = _material(palette["wood_dark"], 0.94)
	desk.position.y = 0.35
	library_station.add_child(desk)
	var book := MeshInstance3D.new()
	book.mesh = _sphere_mesh(0.26, 0.12, 6, 3)
	book.material_override = _material(palette["cream"], 0.88)
	book.position = Vector3(0.0, 0.63, 0.0)
	book.scale = Vector3(1.2, 0.35, 0.75)
	library_station.add_child(book)
	var label := _label3d("ARCHIVE\nSHELL", 0.18, palette["cream"])
	label.name = "LibraryLabel"
	label.position = Vector3(0.0, 1.45, 0.0)
	library_station.add_child(label)

func _create_notice_board(parent: Node3D, position: Vector3) -> void:
	notice_board = StationScript.new() as Node3D
	notice_board.name = "NoticeBoard"
	notice_board.set("world", self)
	notice_board.set("station_id", "notice")
	notice_board.add_to_group("interactable")
	notice_board.position = position
	parent.add_child(notice_board)
	var post := MeshInstance3D.new()
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.22, 1.8, 0.22)
	post.mesh = post_mesh
	post.material_override = _material(palette["wood_dark"], 0.9)
	post.position.y = 0.9
	notice_board.add_child(post)
	var board := MeshInstance3D.new()
	var board_mesh := BoxMesh.new()
	board_mesh.size = Vector3(2.1, 1.25, 0.18)
	board.mesh = board_mesh
	board.material_override = _material(palette["wood"], 0.95)
	board.position = Vector3(0.0, 1.75, 0.0)
	notice_board.add_child(board)
	var pin := MeshInstance3D.new()
	pin.mesh = _sphere_mesh(0.12, 0.24, 8, 4)
	pin.material_override = _material(palette["ember"], 0.5, false, true)
	pin.position = Vector3(0.0, 1.85, -0.13)
	notice_board.add_child(pin)
	var label := _label3d("NOTICE BOARD", 0.17, palette["cream"])
	label.position = Vector3(0.0, 2.65, 0.0)
	notice_board.add_child(label)

func _create_camp_site(parent: Node3D, position: Vector3, title: String) -> void:
	var camp := StationScript.new() as Node3D
	camp.name = title.replace(" ", "")
	camp.set("world", self)
	camp.set("station_id", "camp")
	camp.add_to_group("interactable")
	camp.position = position
	parent.add_child(camp)
	var ring := MeshInstance3D.new()
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 1.05
	ring_mesh.bottom_radius = 1.05
	ring_mesh.height = 0.1
	ring_mesh.radial_segments = 16
	ring.mesh = ring_mesh
	ring.material_override = _material(palette["stone"], 0.95)
	ring.position.y = 0.05
	camp.add_child(ring)
	for index in 5:
		var stone := MeshInstance3D.new()
		stone.mesh = _sphere_mesh(0.22, 0.32, 7, 4)
		stone.material_override = _material(palette["stone"].darkened(0.12), 1.0)
		stone.position = Vector3(cos(float(index) * TAU / 5.0) * 0.78, 0.2, sin(float(index) * TAU / 5.0) * 0.78)
		camp.add_child(stone)
	var fire := MeshInstance3D.new()
	fire.mesh = _sphere_mesh(0.26, 0.72, 8, 5)
	fire.material_override = _material(palette["ember"], 0.38, false, true)
	fire.position.y = 0.58
	camp.add_child(fire)
	var label := _label3d(title + "\n+6 ENERGY", 0.16, palette["cream"])
	label.position.y = 1.45
	camp.add_child(label)

func _create_guide_npc(parent: Node3D, position: Vector3) -> void:
	guide_npc = VillagerScript.new() as Node3D
	guide_npc.name = "MiraWayfarer"
	guide_npc.set("world", self)
	guide_npc.set("station_id", "guide")
	guide_npc.add_to_group("interactable")
	guide_npc.position = position
	parent.add_child(guide_npc)
	var visual := Node3D.new()
	visual.name = "Visual"
	guide_npc.add_child(visual)
	var body := MeshInstance3D.new()
	body.mesh = _sphere_mesh(0.45, 1.2, 10, 6)
	body.material_override = _material(Color("#b26c54"), 0.86)
	body.position.y = 0.72
	visual.add_child(body)
	var head := MeshInstance3D.new()
	head.mesh = _sphere_mesh(0.34, 0.68, 10, 6)
	head.material_override = _material(Color("#d99b72"), 0.9)
	head.position.y = 1.55
	visual.add_child(head)
	var hair := MeshInstance3D.new()
	hair.name = "SoftHairCap"
	hair.mesh = _sphere_mesh(0.35, 0.66, 10, 6)
	hair.material_override = _material(Color("#594354"), 0.88)
	hair.position = Vector3(0.0, 1.82, 0.02)
	hair.scale = Vector3(1.02, 0.42, 0.96)
	visual.add_child(hair)
	for eye_data in [["EyeLeft", -0.11], ["EyeRight", 0.11]]:
		var eye := MeshInstance3D.new()
		eye.name = str(eye_data[0])
		eye.mesh = _sphere_mesh(0.04, 0.08, 8, 4)
		eye.material_override = _material(Color("#332f3d"), 0.96, false, true)
		eye.position = Vector3(float(eye_data[1]), 1.58, 0.285)
		visual.add_child(eye)
	var scarf := MeshInstance3D.new()
	var scarf_mesh := TorusMesh.new()
	scarf_mesh.inner_radius = 0.28
	scarf_mesh.outer_radius = 0.37
	scarf.mesh = scarf_mesh
	scarf.material_override = _material(Color("#6d9ca5"), 0.74)
	scarf.position.y = 1.3
	visual.add_child(scarf)
	for limb_data in [["LegLeft", -0.15, Color("#485d78")], ["LegRight", 0.15, Color("#485d78")]]:
		var leg := Node3D.new()
		leg.name = str(limb_data[0])
		leg.position = Vector3(float(limb_data[1]), 0.42, 0.0)
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.09
		leg_mesh.height = 0.48
		leg_mesh.radial_segments = 8
		leg_mesh.rings = 3
		var leg_visual := MeshInstance3D.new()
		leg_visual.mesh = leg_mesh
		leg_visual.material_override = _material(limb_data[2], 0.88)
		leg_visual.position.y = -0.12
		leg.add_child(leg_visual)
		visual.add_child(leg)
	for limb_data in [["ArmLeft", -0.37, Color("#d99b72")], ["ArmRight", 0.37, Color("#d99b72")]]:
		var arm := Node3D.new()
		arm.name = str(limb_data[0])
		arm.position = Vector3(float(limb_data[1]), 1.05, 0.0)
		var arm_mesh := CapsuleMesh.new()
		arm_mesh.radius = 0.08
		arm_mesh.height = 0.48
		arm_mesh.radial_segments = 8
		arm_mesh.rings = 3
		var arm_visual := MeshInstance3D.new()
		arm_visual.mesh = arm_mesh
		arm_visual.material_override = _material(limb_data[2], 0.86)
		arm_visual.position.y = -0.20
		arm.add_child(arm_visual)
		visual.add_child(arm)
	var satchel := MeshInstance3D.new()
	var satchel_mesh := BoxMesh.new()
	satchel_mesh.size = Vector3(0.42, 0.48, 0.2)
	satchel.mesh = satchel_mesh
	satchel.material_override = _material(palette["wood_dark"], 0.9)
	satchel.position = Vector3(0.38, 0.7, 0.25)
	visual.add_child(satchel)
	var label := _label3d("MIRA\nWAYFARER", 0.17, palette["cream"])
	label.position.y = 2.35
	visual.add_child(label)
	_add_illustrated_mira_sprite(visual)

func _add_illustrated_mira_sprite(visual: Node3D) -> Sprite3D:
	if visual == null:
		return null
	var sheet := load(MIRA_SPRITE_SHEET_PATH) as Texture2D
	if sheet == null:
		return null
	var sprite := Sprite3D.new()
	sprite.name = "IllustratedMira"
	var cell_width := float(sheet.get_width()) / 4.0
	var cell_height := float(sheet.get_height()) / 2.0
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(0.0, 0.0, cell_width, cell_height)
	atlas.filter_clip = true
	sprite.texture = atlas
	sprite.centered = false
	sprite.offset = Vector2(-cell_width * 0.5, -22.0)
	sprite.pixel_size = MIRA_ART_WORLD_HEIGHT / 468.0
	sprite.set_meta("visual_height_world_meters", MIRA_ART_WORLD_HEIGHT)
	sprite.axis = Vector3.AXIS_Z
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.shaded = false
	sprite.no_depth_test = false
	sprite.sorting_use_aabb_center = false
	sprite.sorting_offset = 0.0
	sprite.set_meta("asset_id", "sanctuary/characters/mira_direction_sheet")
	sprite.set_meta("animation_rows", {"idle": 0, "walk": 1})
	sprite.set_meta("direction_frames", 4)
	sprite.set_meta("cell_size", [cell_width, cell_height])
	sprite.set_meta("ground_pivot", [0.0, 0.0, 0.0])
	sprite.set_meta("sorting_anchor_mode", "feet")
	sprite.set_meta("sorting_anchor_space", "sprite_local")
	visual.add_child(sprite)
	for child in visual.get_children():
		if child == sprite:
			continue
		var child_node := child as Node3D
		if child_node != null:
			child_node.visible = false
	var contact_shadow := MeshInstance3D.new()
	contact_shadow.name = "MiraContactShadow"
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.48
	shadow_mesh.bottom_radius = 0.48
	shadow_mesh.height = 0.018
	shadow_mesh.radial_segments = 24
	contact_shadow.mesh = shadow_mesh
	contact_shadow.material_override = _material(Color(0.10, 0.15, 0.11, 0.26), 1.0, true)
	contact_shadow.position = Vector3(0.0, 0.02, 0.0)
	guide_npc.add_child(contact_shadow)
	return sprite

func _sphere_mesh(radius: float, height: float, radial_segments: int, rings: int) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = radial_segments
	mesh.rings = rings
	return mesh

func _material(color: Color, roughness: float, transparent := false, emissive := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.8
	return material

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _label3d(text: String, font_size: float, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = int(font_size * 100.0)
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.add_to_group("world_label")
	label.visible = false
	return label

func _panel(position: Vector2, size: Vector2, color: Color) -> Panel:
	var panel := Panel.new()
	panel.position = position
	panel.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.62, 0.78, 0.64, 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)
	var sourced_texture := _load_sourced_texture(KENNEY_PANEL_TEXTURE)
	if sourced_texture != null:
		var sourced_style := StyleBoxTexture.new()
		sourced_style.texture = sourced_texture
		sourced_style.texture_margin_left = 12.0
		sourced_style.texture_margin_top = 12.0
		sourced_style.texture_margin_right = 12.0
		sourced_style.texture_margin_bottom = 12.0
		sourced_style.modulate_color = color
		panel.add_theme_stylebox_override("panel", sourced_style)
	return panel

func _bar(color: Color, maximum: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = maximum
	bar.value = maximum
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(324, 13)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.03, 0.06, 0.06, 0.88)
	background.set_corner_radius_all(6)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(238, 44)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", palette["cream"])
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = palette["panel_light"]
	normal.set_corner_radius_all(8)
	normal.set_border_width_all(1)
	normal.border_color = Color(0.55, 0.75, 0.59, 0.5)
	var hover := normal.duplicate()
	hover.bg_color = Color("#31584e")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	var sourced_normal := _load_sourced_texture(KENNEY_BUTTON_TEXTURE)
	var sourced_hover := _load_sourced_texture(KENNEY_BUTTON_HOVER_TEXTURE)
	if sourced_normal != null:
		var normal_texture := StyleBoxTexture.new()
		normal_texture.texture = sourced_normal
		normal_texture.texture_margin_left = 10.0
		normal_texture.texture_margin_top = 10.0
		normal_texture.texture_margin_right = 10.0
		normal_texture.texture_margin_bottom = 10.0
		normal_texture.modulate_color = Color(0.48, 0.58, 0.50, 1.0)
		button.add_theme_stylebox_override("normal", normal_texture)
	if sourced_hover != null:
		var hover_texture := StyleBoxTexture.new()
		hover_texture.texture = sourced_hover
		hover_texture.texture_margin_left = 10.0
		hover_texture.texture_margin_top = 10.0
		hover_texture.texture_margin_right = 10.0
		hover_texture.texture_margin_bottom = 10.0
		hover_texture.modulate_color = Color(0.65, 0.78, 0.66, 1.0)
		button.add_theme_stylebox_override("hover", hover_texture)
		button.add_theme_stylebox_override("pressed", hover_texture)
	button.pressed.connect(callback)
	button.pressed.connect(func() -> void:
		if audio_director != null:
			audio_director.call("play_ui", "ui")
	)
	return button

func _load_sourced_texture(path: String) -> Texture2D:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var bytes := file.get_buffer(file.get_length())
	file.close()
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		return null
	return ImageTexture.create_from_image(image)

func _copy_session_to_runtime() -> void:
	if session == null:
		return
	day = int(session.get("day"))
	hour = float(session.get("hour"))
	weather = str(session.get("weather"))
	energy = int(session.get("energy"))
	max_energy = int(session.get("max_energy"))
	coins = int(session.get("coins"))
	xp = int(session.get("xp"))
	build_progress = float(session.get("construction_progress"))
	strength = int(session.get("stats").get("Strength", 1))
	max_health = int(session.get("max_health"))
	cargo_capacity = int(session.get("cargo_capacity"))
	health = int(session.get("health"))
	nutrition = int(session.get("nutrition"))
	hydration = int(session.get("hydration"))
	inventory = session.get("inventory").duplicate(true)
	var stored_settings: Variant = session.get("settings")
	if stored_settings is Dictionary:
		screen_shake_enabled = bool(stored_settings.get("screen_shake", true))
		haptics_enabled = bool(stored_settings.get("haptics", true))
	_sync_expedition_cargo()
	_refresh_whisperwood_route()
	_refresh_expedition_routes()
	_refresh_expedition_inscription_visuals()
	_refresh_wildlife_track_visuals()
	_refresh_route_gate_visuals()
	if player != null:
		player.set("health", health)
		if session.has_method("movement_speed"):
			player.set("speed", float(session.call("movement_speed", 5.2)))
		if session.has_method("stat_value"):
			player.set("max_health", int(session.get("max_health")))
	if farm_plot != null:
		var plot_data: Dictionary = session.get("farm_plot")
		var signature := "%s:%s:%s" % [plot_data.get("state", "empty"), plot_data.get("growth", 0), plot_data.get("watered", false)]
		farm_plot.call("sync_from_session", plot_data)
		if signature != last_farm_signature:
			last_farm_signature = signature
			_refresh_farm_plot()
	_refresh_livestock_visual()

func _on_session_changed() -> void:
	_copy_session_to_runtime()
	_refresh_structure_visuals()
	if interior_active and building_interior != null and session != null:
		var persisted: Dictionary = session.get("interior_stations").get(interior_instance_id, {})
		building_interior.call("sync_persisted_stations", persisted)

func _on_session_feedback(kind: String, payload: Dictionary) -> void:
	if suppress_activity_feedback and kind in ["activity", "mastery_unlock"]:
		return
	if kind == "activity":
		_show_toast("Effort logged  |  +%d XP  +%d Coins  +%d AP  |  %s +%d" % [int(payload.get("xp", 0)), int(payload.get("coins", 0)), int(payload.get("ability_points", 0)), str(payload.get("stat_id", "Focus")), int(payload.get("stat_gain", 0))], 3.6)
	elif kind == "mastery_unlock":
		_show_toast("Permission unlocked: %s  |  %s" % [str(payload.get("label", "Mastery")), str(payload.get("summary", "New capability available."))], 3.6)
	elif kind == "route_unlock":
		_show_toast("New route opened: %s  |  %s" % [str(payload.get("route", "Unknown")), str(payload.get("requirement", "The road is ready."))], 4.0)
	elif kind == "route_capstone":
		_show_toast("Capstone reached: %s  |  Secure it, then return to the beacon." % str(payload.get("label", "Route objective")), 3.2)
	# checkpoint feedback insertion
	elif kind == "wildlife":
		_show_toast("Field journal updated: %s." % str(payload.get("label", "Wildlife")), 2.4)
	elif kind == "inscription":
		_show_toast("Translation secured: %s." % str(payload.get("title", "expedition lore")), 2.6)
	elif kind == "research_ready":
		_show_toast("Finding ready: %s  |  Return to the Archive to claim it." % str(payload.get("discovery_id", "your study")), 3.2)
	elif kind == "research_clue":
		_show_toast("Field briefing: %s  |  %s" % [str(payload.get("title", payload.get("related_id", "new lead"))), str(payload.get("preparation_hint", payload.get("hint", "A related lead surfaced.")))], 4.0)
	elif kind == "onboarding":
		var onboarding_stage := str(payload.get("stage", ""))
		_show_toast("First Return complete  |  The Sanctuary loop is yours." if onboarding_stage == "complete" else "New objective  |  %s" % _reference_objective_text(), 2.8)

func _record_activity() -> void:
	if get_tree().paused or session == null:
		return
	if not session.has_method("manual_activity_status"):
		_show_toast("The effort bridge is unavailable in this build.", 2.4)
		return
	var status: Dictionary = session.call("manual_activity_status")
	if str(status.get("status", "idle")) != "active":
		if session.call("start_manual_activity", "focused_work"):
			_show_toast("25-minute effort started. Keep this session open; the receipt unlocks when the timer completes.", 3.4)
		else:
			var cooldown_remaining := int(session.call("manual_activity_cooldown_remaining")) if session.has_method("manual_activity_cooldown_remaining") else 0
			_show_toast("Your last effort receipt is still cooling down. %d minutes remain." % int(ceil(float(cooldown_remaining) / 60.0)), 2.4)
		return
	if not bool(status.get("complete", false)):
		var remaining := int(status.get("remaining_seconds", 0))
		_show_toast("Effort in progress. %02d:%02d remains before the receipt can be claimed." % [int(remaining / 60), remaining % 60], 2.8)
		return
	var before_activity: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var before_features: Array = session.get("unlocked_features").duplicate() if session.get("unlocked_features") is Array else []
	suppress_activity_feedback = true
	var receipt_result: Dictionary = session.call("complete_manual_activity")
	suppress_activity_feedback = false
	if receipt_result.is_empty():
		_show_toast("The effort receipt could not be verified. The timer remains available to retry.", 2.8)
		return
	if not bool(session.call("save_game")):
		if not before_activity.is_empty() and session.has_method("restore_state"):
			session.call("restore_state", before_activity)
		_copy_session_to_runtime()
		autosave_failed = true
		_show_toast("The effort receipt could not be secured. Nothing was awarded; the timer remains active.", 3.4)
		return
	activity_streak += 1
	_show_toast("25 minutes confirmed. Your real-life effort powers this world.", 3.0)
	var after_features: Variant = session.get("unlocked_features")
	if after_features is Array:
		for feature in after_features:
			if not before_features.has(feature):
				_show_toast("Permission unlocked: %s" % str(feature).replace("_", " ").capitalize(), 2.8)

func _allocate_best_stat() -> void:
	if get_tree().paused:
		return
	if session == null:
		return
	var before_stat: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	if session.call("allocate_stat", selected_stat):
		if not bool(session.call("save_game")):
			if not before_stat.is_empty() and session.has_method("restore_state"):
				session.call("restore_state", before_stat)
			_copy_session_to_runtime()
			_show_toast("The stat allocation could not be secured. Your point was returned.", 2.8)
			return
		strength = int(session.get("stats").get("Strength", strength))
		_show_toast("%s increased. %s" % [selected_stat, str(session.call("stat_effect_summary", selected_stat))], 2.4)
	else:
		_show_toast("No Ability Points available. Log real-life effort to earn one.", 2.4)

func _cycle_stat_selection() -> void:
	if get_tree().paused or session == null:
		return
	var stat_ids: Array = session.call("stat_ids") if session.has_method("stat_ids") else ["Strength"]
	var index := stat_ids.find(selected_stat)
	selected_stat = str(stat_ids[(index + 1) % stat_ids.size()])
	_show_toast("Stat selected: %s  |  %s" % [selected_stat, str(session.call("stat_effect_summary", selected_stat))], 2.0)

func _toggle_pause() -> void:
	if interior_transitioning:
		return
	if settings_open:
		# The HUD pause button is reachable while the settings modal is open.
		# Close the modal first so the button cannot leave an invisible settings
		# layer intercepting touches after it resumes the simulation.
		_toggle_settings()
		return
	var entering_pause := not get_tree().paused
	if entering_pause:
		_reset_manual_input()
	get_tree().paused = not get_tree().paused
	_show_toast("Paused" if get_tree().paused else "Welcome back", 1.5)
	if toast_label != null:
		toast_label.visible = true

func _reset_manual_input() -> void:
	if player != null:
		if player.has_method("cancel_navigation"):
			player.call("cancel_navigation", true)
		if player.has_method("set_joystick_vector"):
			player.call("set_joystick_vector", Vector2.ZERO)
	if hud_joystick != null and hud_joystick.has_method("reset_input"):
		hud_joystick.call("reset_input")

func _on_joystick_vector_changed(value: Vector2) -> void:
	if interior_transitioning:
		if player != null:
			player.call("set_joystick_vector", Vector2.ZERO)
		return
	if player != null:
		player.call("set_joystick_vector", value)

func _toggle_utilities() -> void:
	if get_tree().paused or is_player_input_locked() or interior_active:
		return
	utilities_open = not utilities_open
	_show_toast("Ledger opened: effort, save, and ability points." if utilities_open else "Ledger closed.", 1.4)

func _save_game() -> void:
	_sync_expedition_anchor()
	var load_state := str(session.get("load_status")) if session != null else "fresh"
	if load_state == "future" or (session != null and bool(session.get("save_blocked"))):
		_show_toast("This save belongs to a newer build and remains read-only here.", 3.0)
		return
	if load_state == "rejected" and not save_replacement_armed:
		save_replacement_armed = true
		_show_toast("The old save is unreadable. Press Replace Save again to create a new checkpoint from this session.", 3.6)
		return
	if session != null and session.call("save_game"):
		save_replacement_armed = false
		autosave_failed = false
		autosave_failure_notified = false
		_show_toast("Progress saved safely.", 1.7)
	else:
		autosave_failed = true
		save_replacement_armed = false
		_show_toast("Save unavailable. Your current run is still active.", 2.2)

func _update_time(delta: float) -> void:
	if session == null:
		return
	# The in-world clock is deliberately slow; sleep remains the daily reset
	# transaction. Midnight only wraps the display and never duplicates crops or jobs.
	var next_hour := float(session.get("hour")) + delta * 0.025
	var elapsed := next_hour - float(session.get("hour"))
	if elapsed > 0.0 and session.has_method("advance_game_clock"):
		session.call("advance_game_clock", elapsed)

func _update_tree_sway() -> void:
	var now := Time.get_ticks_msec() * 0.001
	for entry in sway_nodes:
		var node: Node3D = entry["node"]
		if is_instance_valid(node) and node.is_visible_in_tree():
			var phase: float = entry["phase"]
			node.rotation.z = sin(now * (0.65 if weather == "clear" else 1.15) + phase) * (0.018 if weather == "clear" else 0.04)
			node.rotation.x = cos(now * 0.47 + phase) * 0.012

func _update_world_motion(delta: float) -> void:
	var now := Time.get_ticks_msec() * 0.001
	for index in animated_water.size():
		var water := animated_water[index]
		if is_instance_valid(water) and water.is_visible_in_tree():
			water.position.y = 0.08 + sin(now * 1.4 + float(index) * 0.8) * 0.035
			water.scale = Vector3.ONE * (1.0 + sin(now * 0.9 + float(index)) * 0.035)
	for index in animated_beacons.size():
		var beacon := animated_beacons[index]
		if is_instance_valid(beacon) and beacon.is_visible_in_tree():
			beacon.rotation.y += delta * (0.8 + float(index % 2) * 0.35)
			beacon.scale = Vector3.ONE * (1.0 + sin(now * 2.0 + float(index)) * 0.08)
	for pickup_node in get_tree().get_nodes_in_group("expedition_pickup"):
		var pickup := pickup_node as Node3D
		if pickup == null or not pickup.is_visible_in_tree():
			continue
		var base_y := float(pickup.get_meta("base_y", pickup.position.y))
		pickup.position.y = base_y + sin(now * 2.2 + float(pickup.get_instance_id() % 11)) * 0.06
		pickup.rotation.y += delta * 0.7

func is_player_input_locked() -> bool:
	return interior_transitioning or (session != null and session.has_method("has_active_fishing") and bool(session.call("has_active_fishing")))

func _fishing_visual_spot(spot_id: String = "") -> Node3D:
	if spot_id.is_empty() and session != null:
		var state: Dictionary = session.call("fishing_status") if session.has_method("fishing_status") else {}
		spot_id = str(state.get("spot_id", ""))
	if spot_id == "sunlit_tidepool":
		return coastal_fishing_spot
	return fishing_spot

func _fishing_visual_bobber(spot_id: String = "") -> MeshInstance3D:
	if spot_id.is_empty() and session != null:
		var state: Dictionary = session.call("fishing_status") if session.has_method("fishing_status") else {}
		spot_id = str(state.get("spot_id", ""))
	if spot_id == "sunlit_tidepool":
		return coastal_fishing_bobber
	return fishing_bobber

func _update_fishing_visual() -> void:
	if session == null or not session.has_method("fishing_status"):
		return
	var fishing_state: Dictionary = session.call("fishing_status")
	var status := str(fishing_state.get("status", "idle"))
	if fishing_bobber != null:
		fishing_bobber.visible = false
	if coastal_fishing_bobber != null:
		coastal_fishing_bobber.visible = false
	if status == "idle":
		return
	var bobber := _fishing_visual_bobber(str(fishing_state.get("spot_id", "")))
	if bobber == null:
		return
	bobber.visible = true
	var phase := str(fishing_state.get("phase", "idle"))
	var now := Time.get_ticks_msec() * 0.001
	var base_position := Vector3(0.42, 0.08, -0.42) if str(fishing_state.get("spot_id", "")) == "sunlit_tidepool" else Vector3(0.28, 0.08, -0.32)
	if phase == "waiting":
		bobber.position = base_position + Vector3(0.0, sin(now * 1.8) * 0.025, 0.0)
		bobber.scale = Vector3.ONE
	elif phase == "bite":
		bobber.position = base_position + Vector3(0.0, -0.11 + sin(now * 15.0) * 0.035, 0.0)
		bobber.scale = Vector3.ONE * 1.18
	elif phase == "reeling":
		var tension := float(fishing_state.get("tension", 0.0))
		bobber.position = base_position + Vector3(0.0, -0.06 + sin(now * 7.0) * 0.02, 0.0)
		bobber.scale = Vector3.ONE * (1.0 + tension * 0.35)
	else:
		bobber.position = base_position + Vector3(0.0, 0.18, 0.0)
		bobber.scale = Vector3.ONE * 1.15

func _update_fishing_action(delta: float) -> void:
	_update_fishing_visual()
	if not is_player_input_locked() or session == null:
		return
	if player != null:
		player.call("cancel_navigation", true)
		player.call("set_joystick_vector", Vector2.ZERO)
	var active_spot := _fishing_visual_spot()
	var before_fishing_tick: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var result: Dictionary = session.call("advance_fishing", delta, Input.is_action_pressed("interact"))
	if result.is_empty():
		return
	var phase := str(result.get("phase", ""))
	if phase == "bite":
		if active_spot != null:
			_emit_feedback_event("fishing", active_spot.global_position, Vector3.ZERO, 0.8, "water", "fishing", {"audio_kind": "fishing_bite"})
		_show_toast("BITE! Press Interact inside the hook window.", 1.0)
	elif phase == "reeling" and str(result.get("status", "")) == "active":
		if bool(result.get("perfect_hook", false)) and active_spot != null:
			_emit_feedback_event("fishing", active_spot.global_position, Vector3.ZERO, 0.9, "water", "fishing", {"audio_kind": "fishing_hook", "perfect": true})
		_show_toast("Hooked. Tap or hold Interact to reel; release before the line snaps.", 1.5)
	elif str(result.get("status", "")) == "failed":
		if active_spot != null:
			_emit_feedback_event("fishing", active_spot.global_position, Vector3.ZERO, 0.7, "water", "fishing", {"audio_kind": "fishing_escape"})
		session.call("cancel_fishing")
		if not bool(session.call("save_game")):
			if not before_fishing_tick.is_empty():
				session.call("restore_state", before_fishing_tick)
			_show_toast("The escape could not be secured. The line remains in hand.", 2.2)
		else:
			_show_toast("The fish escaped. The pond keeps its secrets.", 1.8)
	elif str(result.get("status", "")) == "landed":
		var landed_snapshot: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
		if not bool(session.call("save_game")):
			if not landed_snapshot.is_empty():
				session.call("restore_state", landed_snapshot)
			_show_toast("The catch could not be secured. The line remains in hand.", 2.4)
			return
		var catch_result: Dictionary = session.call("claim_fishing")
		if catch_result.is_empty() or not bool(session.call("save_game")):
			if not landed_snapshot.is_empty():
				session.call("restore_state", landed_snapshot)
			_show_toast("The catch could not be secured. The fish remains claimable.", 2.4)
			return
		if active_spot != null:
			_emit_feedback_event("fishing", active_spot.global_position, Vector3.ZERO, 1.0, "water", "fishing", {"audio_kind": "fishing_catch", "amount": int(catch_result.get("amount", 0))})
		var uncommon_text := "  |  +%d Shell from the tide" % int(catch_result.get("bonus_resource_amount", 0)) if bool(catch_result.get("uncommon_catch", false)) else ""
		_show_toast("Catch landed  |  +%d Fish  |  Fishing mastery +8%s%s" % [int(catch_result.get("amount", 0)), "  |  Perfect" if bool(catch_result.get("perfect", false)) else "", uncommon_text], 2.8)

func _fishing_action() -> void:
	if session == null or not is_player_input_locked():
		return
	var active_spot := _fishing_visual_spot()
	var before_action: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var result: Dictionary = session.call("press_fishing_action", str(session.get("fishing_attempt").get("attempt_id", "")))
	if result.is_empty():
		return
	if str(result.get("phase", "")) == "reeling" and active_spot != null:
		_emit_feedback_event("fishing", active_spot.global_position, Vector3.ZERO, 0.55, "water", "fishing", {"audio_kind": "fishing_reel"})
	if str(result.get("status", "")) == "failed":
		session.call("cancel_fishing")
		if not session.has_method("save_game") or not bool(session.call("save_game")):
			if not before_action.is_empty():
				session.call("restore_state", before_action)
			_show_toast("The escape could not be secured. The line remains in hand.", 2.2)
		else:
			_show_toast("The fish escaped. The pond keeps its secrets.", 1.8)
		return
	if session.has_method("save_game") and not bool(session.call("save_game")):
		if not before_action.is_empty():
			session.call("restore_state", before_action)
		_show_toast("The reel action could not be secured. The line remains in hand.", 2.2)

func _update_lighting() -> void:
	if sun_light == null:
		return
	var daylight := clampf(sin((hour - 6.0) / 14.0 * PI), 0.12, 1.0)
	sun_light.light_energy = 0.22 + daylight * 0.62
	sun_light.light_color = Color("#ffd39d").lerp(Color("#7890b7"), 1.0 - daylight)
	var key_direction := (-sun_light.global_basis.z).normalized()
	if sanctuary_style != null and sanctuary_style.has_method("set_key_light_direction"):
		sanctuary_style.call("set_key_light_direction", key_direction)
	if building_interior != null and building_interior.has_method("set_key_light_direction"):
		building_interior.call("set_key_light_direction", key_direction)
	if hearth_fill != null:
		hearth_fill.visible = current_zone == "Sanctuary" and not interior_active
		hearth_fill.light_energy = 2.2 if current_zone == "Sanctuary" and not interior_active else 0.0
	var sanctuary_sky_fill := get_node_or_null("SanctuarySkyFill") as OmniLight3D
	if sanctuary_sky_fill != null:
		sanctuary_sky_fill.visible = current_zone == "Sanctuary" and not interior_active
		sanctuary_sky_fill.light_energy = 0.42 if current_zone == "Sanctuary" else 0.0

func _update_expedition_hazard(delta: float) -> void:
	if current_zone == "Sanctuary" or session == null or not session.call("has_active_expedition"):
		hazard_timer = 0.0
		hazard_shelter_active = false
		return
	var run: Dictionary = session.get("expedition_run")
	if not bool(run.get("stake_active", false)):
		hazard_timer = 0.0
		hazard_shelter_active = false
		return
	var tick_interval := 18.0
	match current_zone:
		"Whisperwood": tick_interval = 5.5
		"Sunlit Beach": tick_interval = 5.0
		"Ember Ridge": tick_interval = 4.5
		"Glass Desert": tick_interval = 4.0
		"Sunken Dungeon": tick_interval = 3.5
	if _is_player_in_route_shelter():
		hazard_timer = 0.0
		if not hazard_shelter_active:
			_show_toast("Shade found. Heat pressure is paused while you plan your next move.", 2.6)
		hazard_shelter_active = true
		return
	if hazard_shelter_active:
		_show_toast("Back into the heat. Keep the shade in sight.", 1.8)
		hazard_shelter_active = false
	hazard_timer += delta
	if hazard_timer < tick_interval:
		return
	hazard_timer -= tick_interval
	var before_stake: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var result: Dictionary = session.call("apply_expedition_stake_tick") if session.has_method("apply_expedition_stake_tick") else {}
	if result.is_empty():
		return
	var loss := int(result.get("energy_loss", 0))
	var damage := int(result.get("health_loss", 0))
	_show_toast("%s  |  -%d Energy" % [str(result.get("message", "The route is demanding a safe return.")), loss], 2.6)
	if damage > 0:
		player_took_damage(damage)
	# Persist the stake and the resulting health together. Saving before damage
	# would leave a reload with the energy loss but the old health value.
	if not bool(session.call("save_game")):
		if not before_stake.is_empty():
			session.call("restore_state", before_stake)
		_copy_session_to_runtime()
		return

func _is_player_in_route_shelter() -> bool:
	if current_zone != "Glass Desert" or player == null or desert_zone == null:
		return false
	var shade := desert_zone.get_node_or_null("MapIdentity/ShadeVolume") as Area3D
	if shade == null or not shade.is_visible_in_tree():
		return false
	for body in shade.get_overlapping_bodies():
		if body == player:
			return true
	var player_flat := Vector2(player.global_position.x, player.global_position.z)
	var shade_flat := Vector2(shade.global_position.x, shade.global_position.z)
	return player_flat.distance_to(shade_flat) <= float(shade.get_meta("radius", 3.2))

func _update_audio_context() -> void:
	if audio_director == null or player == null:
		return
	var surface := "wood" if interior_active else _current_surface()
	var indoor := interior_active or (current_zone == "Sanctuary" and absf(player.position.x) < 2.15 and player.position.z < -2.0 and player.position.z > -5.8)
	var near_furnace := furnace_active and current_zone == "Sanctuary" and _ground_distance(player.global_position, furnace.global_position) < 6.0
	if interior_active and building_interior != null and building_interior.has_method("has_operational_furnace"):
		near_furnace = bool(building_interior.call("has_operational_furnace"))
	audio_director.call("set_environment", current_zone, surface, hour, weather, indoor, near_furnace)
	if furnace != null:
		var fire: Node3D = furnace.get_node_or_null("Fire")
		if fire != null:
			fire.visible = furnace_active

func camera_relative_direction(input_vector: Vector2) -> Vector3:
	if input_vector.length() <= 0.05:
		return Vector3.ZERO
	var clamped_input := input_vector.limit_length(1.0)
	if camera == null:
		return Vector3(clamped_input.x, 0.0, clamped_input.y)
	# Input.get_vector() and the virtual stick both use screen-space Y:
	# up/W is negative Y. Use the fixed camera frame rather than the rendered
	# camera's transient transform so follow/shake never changes the travel
	# direction under a held stick. Do not normalize the result: analog
	# magnitude is the intended speed.
	return camera_ground_right * clamped_input.x + camera_ground_forward * -clamped_input.y

func camera_screen_direction(world_direction: Vector3) -> Vector2:
	var flat_direction := world_direction
	flat_direction.y = 0.0
	if flat_direction.length_squared() <= 0.0001:
		return Vector2.ZERO
	flat_direction = flat_direction.normalized()
	return Vector2(flat_direction.dot(camera_ground_right), -flat_direction.dot(camera_ground_forward))

func _clamped_camera_focus(raw_focus: Vector3) -> Vector3:
	var focus := raw_focus
	var allowed_x := maxf(0.0, WORLD_HALF_EXTENTS.x - CAMERA_FOCUS_MARGIN.x)
	var allowed_z := maxf(0.0, WORLD_HALF_EXTENTS.y - CAMERA_FOCUS_MARGIN.y)
	focus.x = clampf(focus.x, -allowed_x, allowed_x)
	focus.z = clampf(focus.z, -allowed_z, allowed_z)
	return focus

func _update_camera_motion_basis(camera_focus: Vector3, authored_camera_position: Vector3) -> void:
	var forward := camera_focus - authored_camera_position
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		return
	camera_ground_forward = forward.normalized()
	camera_ground_right = Vector3(-camera_ground_forward.z, 0.0, camera_ground_forward.x).normalized()

func _current_surface() -> String:
	if current_zone == "Whisperwood" or current_zone == "Ember Ridge":
		return "dirt"
	if current_zone == "Sunlit Beach" or current_zone == "Glass Desert":
		return "sand"
	if current_zone == "Sunken Dungeon":
		return "stone"
	if absf(player.position.x) < 2.15 and player.position.z < -2.0 and player.position.z > -5.8:
		return "wood"
	if absf(player.position.x + 7.5) < 2.15 and player.position.z < 0.7 and player.position.z > -3.4:
		return "sand"
	if absf(player.position.x) < 1.5 or absf(player.position.z - 1.0) < 1.1:
		return "stone"
	return "grass"

func _update_hud() -> void:
	if zone_label == null:
		return
	zone_label.text = current_zone
	if hud_title_label != null:
		hud_title_label.text = "WORKSHOP" if interior_active else ("SANCTUARY" if current_zone == "Sanctuary" else "PRODEWTY")
	var total_minutes := int(hour * 60.0)
	var display_hour := int(hour) % 24
	var minute := total_minutes % 60
	day_label.text = "Day %d  |  %02d:%02d" % [day, display_hour, minute]
	energy_bar.value = energy
	health_bar.value = int(player.get("health"))
	if reference_name_label != null:
		reference_name_label.text = "PRODEWTY" if current_zone != "Sanctuary" else "WAYFARER"
		reference_level_label.text = "LV. %d  •  DAY %d  •  %02d:%02d" % [int(session.get("level")) if session != null else 1, day, display_hour, minute]
		reference_zone_label.text = "WORKSHOP" if interior_active else current_zone.to_upper()
		reference_objective_label.text = _reference_objective_text()
		reference_health_bar.value = int(player.get("health"))
		reference_energy_bar.value = energy
	var reference_stats: Dictionary = session.get("stats") if session != null and session.get("stats") is Dictionary else {}
	if reference_stat_labels.has("Strength"):
		(reference_stat_labels["Strength"] as Label).text = "STR  %d" % int(reference_stats.get("Strength", 1))
	if reference_stat_labels.has("Focus"):
		(reference_stat_labels["Focus"] as Label).text = "FOC  %d" % int(reference_stats.get("Focus", 1))
	if reference_stat_labels.has("health"):
		(reference_stat_labels["health"] as Label).text = "HP   %d" % int(player.get("health"))
	if reference_stat_labels.has("hydration"):
		(reference_stat_labels["hydration"] as Label).text = "H2O  %d" % hydration
	if reference_stat_labels.has("level"):
		(reference_stat_labels["level"] as Label).text = "LV   %d" % (int(session.get("level")) if session != null else 1)
	weather_label.text = ("Rain  |  surface: %s" % _current_surface()) if weather == "rain" else ("Clear  |  surface: %s" % _current_surface())
	var cargo: Dictionary = expedition_loot
	var cargo_text := "—"
	if not cargo.is_empty():
		var cargo_parts: Array[String] = []
		for cargo_id in cargo:
			cargo_parts.append("%s %d" % [str(cargo_id).replace("_", " ").capitalize(), int(cargo[cargo_id])])
		cargo_text = ", ".join(cargo_parts)
	var tools: Dictionary = session.get("equipment") if session != null else {}
	var hatchet_state: Dictionary = tools.get("hatchet", {})
	var pickaxe_state: Dictionary = tools.get("pickaxe", {})
	var cargo_used := 0
	if session != null and session.has_method("expedition_cargo_used"):
		cargo_used = int(session.call("expedition_cargo_used"))
	inventory_label.text = "BANKED\nWood %d  Stone %d  Fiber %d\nOre %d  Shell %d  Gel %d\nFish %d  Wheat %d  Bread %d\nEgg %d  Omelette %d  Tonic %d\nPlank %d  Ingot %d  Sun %d  Relic %d\nTOOLS H %d/%d  P %d/%d\nNUTRITION %d  WATER %d\nSATCHEL %d/%d  %s\nCoins %d  XP %d" % [inventory.get("wood", 0), inventory.get("stone", 0), inventory.get("fiber", 0), inventory.get("ore", 0), inventory.get("shell", 0), inventory.get("slime_gel", 0), inventory.get("fish", 0), inventory.get("wheat", 0), inventory.get("bread", 0), inventory.get("egg", 0), inventory.get("omelette", 0), inventory.get("tonic", 0), inventory.get("plank", 0), inventory.get("ingot", 0), inventory.get("sunstone", 0), inventory.get("relic", 0), hatchet_state.get("durability", 0), hatchet_state.get("max_durability", 0), pickaxe_state.get("durability", 0), pickaxe_state.get("max_durability", 0), nutrition, hydration, cargo_used, cargo_capacity, cargo_text, coins, xp]
	if session != null and current_zone != "Sanctuary" and session.has_method("has_active_expedition") and bool(session.call("has_active_expedition")):
		var field_pickups: Variant = session.get("expedition_run").get("pickups", [])
		if field_pickups is Array and not field_pickups.is_empty():
			inventory_label.text += "\nGROUND DROPS %d  |  Pick up before extraction" % field_pickups.size()
	if reference_quick_labels != null:
		for quick_id in reference_quick_labels:
			var quick_label := reference_quick_labels[quick_id] as Label
			if quick_label != null:
				quick_label.text = "%s  %d" % [str(quick_id).to_upper(), int(inventory.get(quick_id, 0))]
	if reference_cargo_text != null:
		reference_cargo_text.text = "CARGO %d / %d" % [cargo_used, cargo_capacity]
	if reference_cargo_bar != null:
		reference_cargo_bar.max_value = 100
		reference_cargo_bar.value = posmod(xp, 100)
	if reference_cargo_label != null:
		reference_cargo_label.text = "XP %d / %d" % [posmod(xp, 100), 100]
	if mastery_label != null and session != null:
		var stats: Dictionary = session.get("stats")
		var mastery: Dictionary = session.get("masteries")
		mastery_label.text = "LEVEL %d  |  AP %d  |  DISC %d/%d\nSTR %d  AGI %d  FOC %d  WIS %d\nSPI %d  PER %d  RES %d" % [int(session.get("level")), int(session.get("ability_points")), session.get("researched").size(), session.get("discovered").size(), int(stats.get("Strength", 1)), int(stats.get("Agility", 1)), int(stats.get("Focus", 1)), int(stats.get("Wisdom", 1)), int(stats.get("Spirituality", 1)), int(stats.get("Perception", 1)), int(stats.get("Resilience", 1))]
	if quest_label != null and session != null:
		var current_quest: Dictionary = session.get("quest")
		var quest_state := "CLAIM AT NOTICE BOARD" if int(current_quest.get("progress", 0)) >= int(current_quest.get("target", 5)) and not bool(current_quest.get("claimed", false)) else ("COMPLETE" if bool(current_quest.get("claimed", false)) else "IN PROGRESS")
		quest_label.text = "%s  [%s]\n%s\nProgress %d / %d" % [str(current_quest.get("title", "NOTICE BOARD")), quest_state, str(current_quest.get("description", "")), int(current_quest.get("progress", 0)), int(current_quest.get("target", 5))]
	if status_label != null:
		var nearest := _nearest_interactable()
		if nearest != null:
			var label_value = nearest.get("resource_label")
			var nearby_name := "Recovery Pack"
			if nearest == farm_plot:
				nearby_name = "Garden Plot"
			elif nearest == workshop:
				nearby_name = "Workshop"
			elif nearest == library_station:
				nearby_name = "Archive"
			elif nearest == notice_board:
				nearby_name = "Notice Board"
			elif nearest == guide_npc:
				nearby_name = "Mira, Wayfarer"
			elif nearest == fishing_spot:
				nearby_name = "Sanctuary Fishing Pond"
			elif nearest == coastal_fishing_spot:
				nearby_name = "Sunlit Tidepool"
			elif nearest == trade_stall:
				nearby_name = "Bazaar Trade Stall"
			elif nearest == livestock_pen:
				nearby_name = "Clover's Livestock Pen"
			elif str(nearest.get("station_id")) == "camp":
				nearby_name = "Expedition Camp"
			elif nearest.has_meta("destination_id"):
				nearby_name = "%s Route Gate" % str(nearest.get_meta("destination_id"))
			elif nearest.is_in_group("expedition_pickup"):
				nearby_name = "%s x%d" % [str(nearest.get("resource_label")), int(nearest.get("amount"))]
			elif nearest.is_in_group("wildlife_creature"):
				nearby_name = str(nearest.get("species_label"))
			elif nearest.is_in_group("expedition_inscription"):
				nearby_name = "Expedition Inscription"
			elif nearest.is_in_group("wildlife_track"):
				nearby_name = "Fresh Wildlife Tracks"
			elif nearest.is_in_group("building_interior_station"):
				nearby_name = str(nearest.get_meta("interior_station_id", "Workshop Station")).replace("_", " ").capitalize()
			elif label_value != null:
				nearby_name = str(label_value)
			status_label.text = "Nearby: %s  |  Press E" % nearby_name
		elif _is_player_in_route_shelter():
			status_label.text = "Shade shelter: heat pressure paused  |  Plan your return"
		else:
			status_label.text = "Gather close to nodes. Press E to interact."
	if hud_bag_panel != null:
		hud_bag_panel.visible = utilities_open
	if hud_quest_panel != null:
		hud_quest_panel.visible = utilities_open
	var sanctuary_showcase_hud := current_zone == "Sanctuary" and not utilities_open and not interior_active
	var reference_gameplay_hud := not utilities_open and not settings_open
	if reference_hud != null:
		reference_hud.visible = reference_gameplay_hud
	if hud_top_panel != null:
		# Keep the world-facing HUD as a small status card during Sanctuary
		# traversal. The ledger remains available on demand instead of occupying
		# the buildable meadow with inventory and progression text.
		hud_top_panel.size.y = 146.0 if sanctuary_showcase_hud else 190.0
		hud_top_panel.modulate = Color.WHITE
		hud_top_panel.visible = not reference_gameplay_hud
	if status_label != null:
		status_label.visible = not reference_gameplay_hud
	if weather_label != null:
		weather_label.visible = not reference_gameplay_hud
	if action_hint != null and hud_joystick != null:
		action_hint.visible = not reference_gameplay_hud and (hud_joystick.visible or current_zone != "Sanctuary")
	var fishing_locked := is_player_input_locked()
	if interact_button != null:
		var fishing_active := fishing_locked
		var fishing_phase := str(session.get("fishing_attempt").get("phase", "idle")) if fishing_active and session != null else ""
		interact_button.text = ("Hook / Reel" if fishing_phase in ["bite", "reeling"] else "Wait for Bite") if fishing_active else ("Confirm placement" if placement_mode else "Interact")
		interact_button.disabled = get_tree().paused or interior_transitioning
	if pause_button != null:
		pause_button.text = "Resume" if get_tree().paused else "Pause"
		pause_button.disabled = interior_transitioning
	if smelt_button != null:
		smelt_button.text = "Stop Furnace" if furnace_active else "Start Furnace"
	var context_node := _nearest_interactable()
	_update_world_label_visibility(context_node)
	if interact_button != null and not placement_mode and context_node != null and context_node.is_in_group("wildlife_creature"):
		interact_button.text = "Observe"
	elif interact_button != null and not placement_mode and context_node != null and context_node.is_in_group("wildlife_track"):
		interact_button.text = "Read Tracks"
	if interact_button != null and not placement_mode and interior_active and context_node != null and context_node.is_in_group("building_interior_station"):
		interact_button.text = _interior_station_action_text(context_node)
	if reference_context_button != null:
		var reference_action_text := "INTERACT"
		if interact_button != null:
			reference_action_text = str(interact_button.text).replace("  [E]", "")
		reference_context_button.text = "%s  [E]" % reference_action_text
		reference_context_button.disabled = get_tree().paused or interior_transitioning
	# Management controls remain top-right. Context-sensitive gameplay buttons
	# occupy their own bottom-right dock so touch movement and actions stay on
	# opposite thumbs without covering the Sanctuary composition.
	if hud_right_panel != null:
		hud_right_panel.visible = not reference_gameplay_hud
	if hud_action_panel != null:
		hud_action_panel.visible = not reference_gameplay_hud and _visible_hud_button_count(hud_action_box) > 0
	if explore_button != null:
		var nearby_route: bool = context_node != null and context_node.has_meta("destination_id")
		explore_button.visible = current_zone == "Sanctuary" and not interior_active and nearby_route
		var nearby_destination := str(context_node.get_meta("destination_id")) if nearby_route else ""
		var nearby_unlocked := nearby_route and session != null and session.has_method("route_is_unlocked") and bool(session.call("route_is_unlocked", nearby_destination))
		explore_button.text = ("Enter %s" % nearby_destination) if nearby_unlocked else ("Route locked: %s" % nearby_destination if nearby_route else "Walk to a route gate")
	if destination_button != null:
		destination_button.visible = false
	if return_button != null:
		return_button.visible = current_zone != "Sanctuary"
		var extraction_point := Vector3(0.0, 1.0, 7.5)
		var at_extraction := current_zone != "Sanctuary" and player != null and _ground_distance(player.global_position, extraction_point) <= 2.8
		var return_route_blocked := session != null and session.has_method("expedition_return_checkpoint_required") and bool(session.call("expedition_return_checkpoint_required"))
		var return_landmark_label := "Return Footbridge" if current_zone == "Whisperwood" else "Return Causeway"
		return_button.disabled = not at_extraction or return_route_blocked
		return_button.text = "Cross %s" % return_landmark_label if return_route_blocked and at_extraction else ("Extract cargo" if at_extraction else "Reach extraction beacon")
	if attack_button != null:
		var near_guardian := false
		if current_zone != "Sanctuary" and player != null:
			for guardian_node in get_tree().get_nodes_in_group("guardian"):
				if is_instance_valid(guardian_node) and guardian_node.is_visible_in_tree() and _ground_distance(player.global_position, guardian_node.global_position) <= 3.8:
					near_guardian = true
					break
		attack_button.visible = near_guardian
	if sleep_button != null:
		var at_hearth := current_zone == "Sanctuary" and furnace != null and player != null and _ground_distance(player.global_position, furnace.global_position) <= 7.0
		sleep_button.visible = at_hearth and not interior_active and not is_player_input_locked()
		sleep_button.disabled = not at_hearth
	if dodge_button != null:
		dodge_button.visible = current_zone != "Sanctuary"
	if farm_button != null:
		farm_button.visible = not fishing_locked and not interior_active and current_zone == "Sanctuary" and context_node == farm_plot
	var field_supplies_available: bool = session != null and session.has_method("has_active_expedition") and bool(session.call("has_active_expedition"))
	if food_button != null:
		food_button.visible = not fishing_locked and (utilities_open or current_zone != "Sanctuary" and field_supplies_available)
		food_button.text = "Eat %s  [G]  (%d)" % [selected_food.capitalize(), int(inventory.get(selected_food, 0))]
	if water_button != null:
		water_button.visible = not fishing_locked and (utilities_open or current_zone != "Sanctuary" and field_supplies_available)
		water_button.text = "Drink Water  [H]  (%d)" % int(inventory.get("water", 0))
	if livestock_button != null:
		var livestock_context := not interior_active and current_zone == "Sanctuary" and (context_node == livestock_pen or _is_player_structure_kind(context_node, "livestock_pen"))
		livestock_button.visible = not fishing_locked and livestock_context
		var pen_built := session != null and bool(session.get("built").get("livestock_pen", false))
		livestock_button.text = "Collect / Feed Clover" if pen_built else "Place Livestock Pen Blueprint"
	if repair_button != null:
		repair_button.visible = not fishing_locked and not interior_active and current_zone == "Sanctuary" and (context_node == workshop or _is_player_structure_kind(context_node, "workshop"))
	if recipe_button != null:
		recipe_button.visible = not fishing_locked and not interior_active and current_zone == "Sanctuary" and (context_node == workshop or _is_player_structure_kind(context_node, "workshop")) and session != null and bool(session.get("built").get("workshop", false))
		recipe_button.text = "Recipe: %s  [Q]" % selected_recipe.capitalize()
	if structure_button != null:
		structure_button.visible = not fishing_locked and not interior_active and current_zone == "Sanctuary" and (utilities_open or context_node != null)
		structure_button.text = "Cancel Placement  [B]" if placement_mode else "Place %s  [B]" % _structure_display_name(placement_structure_id)
	if blueprint_button != null:
		blueprint_button.visible = not fishing_locked and not interior_active and current_zone == "Sanctuary" and (utilities_open or context_node != null)
		blueprint_button.text = "Blueprint: %s  [N]" % _structure_display_name(placement_structure_id)
	if rotate_button != null:
		rotate_button.visible = not fishing_locked and not interior_active and current_zone == "Sanctuary" and placement_mode
		rotate_button.text = "Rotate Blueprint  [X]  %d°" % (placement_rotation_quarter_turns * 90)
	if build_button != null:
		var workshop_context := (interior_active and interior_kind == "workshop") or (not interior_active and current_zone == "Sanctuary" and (context_node == workshop or _is_player_structure_kind(context_node, "workshop")))
		build_button.visible = not fishing_locked and workshop_context
		var construction_state := "none"
		if session != null:
			construction_state = str(session.get("construction_job").get("status", "none"))
		if interior_active:
			build_button.text = "Confirm %s  [E]" % _interior_station_label(selected_interior_station_kind) if interior_station_placement_mode else "Place %s  [B]" % _interior_station_label(selected_interior_station_kind)
		elif _is_player_structure_kind(context_node, "workshop"):
			var placed_state: Dictionary = session.get("structures").get(str(context_node.get_meta("construction_id")), {}) if session != null else {}
			build_button.text = "Use Workshop" if str(placed_state.get("state", "")) == "operational" else ("Deliver Workshop Materials" if str(placed_state.get("state", "")) == "blueprint" else "Workshop frame in progress")
		else:
			build_button.text = "Workshop Built" if session != null and bool(session.get("built").get("workshop", false)) else ("Finish Workshop" if construction_state == "ready" else ("Building... Sleep to advance" if construction_state == "building" else "Place Workshop Blueprint"))
	if smelt_button != null:
		smelt_button.visible = not fishing_locked and not interior_active and current_zone == "Sanctuary" and furnace != null and _ground_distance(player.global_position, furnace.global_position) < 5.0
	if utilities_button != null:
		utilities_button.visible = not fishing_locked and not interior_active
		utilities_button.text = "Close Ledger" if utilities_open else "Open Ledger"
	if activity_button != null:
		activity_button.visible = not fishing_locked and utilities_open
		if session != null and session.has_method("manual_activity_status"):
			var activity_state: Dictionary = session.call("manual_activity_status")
			if str(activity_state.get("status", "idle")) == "active":
				if bool(activity_state.get("complete", false)):
					activity_button.text = "Claim 25m Effort Receipt  [P]"
				else:
					var remaining_seconds := int(activity_state.get("remaining_seconds", 0))
					activity_button.text = "Effort in progress  %02d:%02d  [P]" % [int(remaining_seconds / 60), remaining_seconds % 60]
			else:
				activity_button.text = "Start 25m Effort  [P]"
	if save_button != null:
		save_button.visible = not fishing_locked and utilities_open
		var load_state_for_save := str(session.get("load_status")) if session != null else "fresh"
		if load_state_for_save == "future" or (session != null and bool(session.get("save_blocked"))):
			save_button.text = "Read-only: newer save"
		elif load_state_for_save == "rejected":
			save_button.text = "Replace unreadable save  [again]" if save_replacement_armed else "Replace unreadable save"
		elif autosave_failed:
			save_button.text = "Retry Save Progress"
		else:
			save_button.text = "Save Progress"
	if stat_button != null:
		stat_button.visible = not fishing_locked and utilities_open
		stat_button.text = "Spend AP: %s  [L]" % selected_stat
	if stat_cycle_button != null:
		stat_cycle_button.visible = not fishing_locked and utilities_open
		stat_cycle_button.text = "Stat: %s  [O]" % selected_stat
	if action_hint != null:
		if interior_active:
			action_hint.text = "Workshop interior  |  Move between stations  |  Interact at the door to leave"
		elif placement_mode:
			action_hint.text = "Blueprint mode  |  Move to a clear footprint  |  Rotate [X]  |  Confirm placement or cancel"
		elif current_zone == "Sanctuary":
			action_hint.text = "WASD / joystick to move  |  Walk to a route gate, resource, villager, or build site to reveal the next action"
		else:
			var expedition_hint := "Follow the beacon  |  Cargo is at risk until extraction  |  Gather, camp once, and choose your fights"
			if session != null and session.has_method("expedition_route_snapshot") and bool(session.call("has_active_expedition")):
				var route_state: Dictionary = session.call("expedition_route_snapshot")
				var route_definition: Dictionary = route_state.get("branch_definition", {})
				var branch_text := str(route_definition.get("label", "Choose a trail")) if not str(route_state.get("branch_id", "")).is_empty() else "Choose a trail at the route fork"
				var objective_target := int(route_state.get("objective_target", 0))
				var objective_progress := int(route_state.get("objective_progress", 0))
				var objective_text := "CAPSTONE READY" if bool(route_state.get("objective_complete", false)) else ("OBJECTIVE %d/%d  |  %s" % [objective_progress, objective_target, str(route_definition.get("summary", "Gather supplies and read the terrain."))] if objective_target > 0 else str(route_definition.get("summary", "Gather supplies and read the terrain.")))
				var return_hint := ("Cross the Return Footbridge, then extract" if current_zone == "Whisperwood" else "Cross the Return Causeway, then extract") if bool(route_state.get("shortcut_open", false)) and str(route_state.get("route_phase", "")) == "shortcut" else "Extract at the beacon"
				expedition_hint = "%s  |  %s  |  %s" % [branch_text, objective_text, return_hint]
				if _is_player_in_route_shelter():
					expedition_hint += "  |  Shade pauses heat pressure"
			action_hint.text = expedition_hint
	for button_box in [hud_right_box, hud_action_box]:
		if button_box == null:
			continue
		for child in button_box.get_children():
			if child is Button and child != pause_button and child != interact_button:
				(child as Button).disabled = get_tree().paused or interior_transitioning or interior_active
	for slot in reference_slots:
		if slot != null:
			var interior_safe := str(slot.get_meta("action_label", "")) == "USE"
			slot.disabled = get_tree().paused or interior_transitioning or (interior_active and not interior_safe)
	_refresh_hud_layout_if_needed()

func _update_interaction_marker(delta: float) -> void:
	if interaction_marker == null or player == null:
		return
	var nearest := _nearest_interactable()
	if nearest == null:
		interaction_marker.visible = false
		return
	var target := nearest as Node3D
	if target == null:
		interaction_marker.visible = false
		return
	interaction_marker.visible = true
	interaction_marker.global_position = _interaction_anchor_position(target) + Vector3(0.0, 0.05, 0.0)
	interaction_marker.rotation.y += delta * 1.8
	interaction_marker.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.06)

func _screen_to_ground(screen_position: Vector2) -> Variant:
	if camera == null:
		return null
	var ray_origin := camera.project_ray_origin(screen_position)
	var ray_direction := camera.project_ray_normal(screen_position)
	if absf(ray_direction.y) <= 0.0001:
		return null
	var distance := -ray_origin.y / ray_direction.y
	if distance < 0.0:
		return null
	var hit := ray_origin + ray_direction * distance
	hit.y = 0.0
	return hit

func _set_mouse_move_target(screen_position: Vector2) -> void:
	if player == null or not is_instance_valid(player):
		return
	var target: Variant = _screen_to_ground(screen_position)
	if not (target is Vector3):
		return
	var clamped_target: Vector3 = target
	clamped_target.x = clampf(clamped_target.x, -19.5, 19.5)
	clamped_target.z = clampf(clamped_target.z, -14.5, 14.5)
	player.call("set_click_move_target", clamped_target)
	if move_target_marker != null:
		move_target_marker.global_position = Vector3(clamped_target.x, 0.045, clamped_target.z)
		move_target_marker.visible = true
		move_target_marker.scale = Vector3.ONE
	if audio_director != null:
		audio_director.call("play_action", "ui")

func _update_move_target_marker() -> void:
	if move_target_marker == null or player == null:
		return
	var active := bool(player.get("click_move_active"))
	move_target_marker.visible = active
	if active:
		var target: Vector3 = player.get("click_move_target")
		move_target_marker.global_position = Vector3(target.x, 0.045, target.z)
		move_target_marker.rotation.y += get_process_delta_time() * 2.4
		move_target_marker.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.008) * 0.08)

func _show_toast(message: String, duration := 2.4) -> void:
	if toast_label == null:
		return
	toast_label.text = message
	toast_timer = duration

func _emit_feedback_event(action_kind: String, world_position: Vector3, direction: Vector3 = Vector3.ZERO, strength: float = 1.0, surface: String = "grass", source: String = "world", metadata: Dictionary = {}) -> Dictionary:
	var event: Dictionary = FeedbackEventScript.make(action_kind, world_position, direction, strength, surface, source, metadata)
	feedback_event_sequence += 1
	event["sequence"] = feedback_event_sequence
	last_feedback_event = event
	if audio_director != null and audio_director.has_method("play_feedback"):
		audio_director.call("play_feedback", event)
	if screen_shake_enabled:
		camera_shake = maxf(camera_shake, float(event.get("camera_shake", 0.0)))
	var haptic_duration := int(event.get("haptic_duration_ms", 0))
	if haptic_duration > 0:
		_try_haptic(haptic_duration, float(event.get("haptic_amplitude", 0.0)))
	return event

func _resource_feedback_surface(resource_id: String) -> String:
	match resource_id:
		"wood", "fiber", "berries": return "foliage"
		"stone", "ore", "sunstone": return "stone"
		"shell": return "sand"
		"fish", "water": return "water"
	return "grass"

func _player_feedback_direction() -> Vector3:
	if player == null:
		return Vector3.ZERO
	var direction: Vector3 = player.get("last_direction")
	return direction

func feedback_event_snapshot() -> Dictionary:
	return last_feedback_event.duplicate(true)

func _consume_energy(cost: int) -> bool:
	if session != null:
		if not session.call("spend_energy", cost):
			_show_toast("You need more energy. Sleep in the Sanctuary to recover.", 2.8)
			return false
		return true
	if energy < cost:
		_show_toast("You need more energy. Sleep in the Sanctuary to recover.", 2.8)
		return false
	energy -= cost
	return true

func _nearest_interactable() -> Node:
	var nearest: Node = null
	var nearest_distance := _interaction_range()
	var nearest_priority := -1
	for candidate in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(candidate) or not candidate.is_visible_in_tree():
			continue
		var resource_node := candidate as Node3D
		if resource_node == null:
			continue
		var distance := _interaction_distance(resource_node)
		if distance > _interaction_range():
			continue
		var priority := _interaction_priority(candidate)
		if priority > nearest_priority or (priority == nearest_priority and distance < nearest_distance):
			nearest = candidate
			nearest_distance = distance
			nearest_priority = priority
	return nearest

func _interaction_priority(candidate: Node) -> int:
	# Proximity remains the tie-breaker, but a live objective must not be
	# shadowed by optional flavour interactions that happen to be closer. This
	# is a gameplay focus rule, not a collision-radius expansion: every candidate
	# still has to be inside its measured interaction range.
	if session != null and session.has_method("has_active_expedition") and bool(session.call("has_active_expedition")):
		var run: Dictionary = session.get("expedition_run")
		var branch_id := str(run.get("branch_id", ""))
		var route_id := str(run.get("biome_id", ""))
		if candidate.is_in_group("expedition_pickup"):
			return 30
		if str(candidate.get("station_id")) == "map_capstone" and str(candidate.get_meta("route_branch", "")) == branch_id and str(current_zone) == route_id and bool(run.get("objective_complete", false)):
			return 25
		if candidate.is_in_group("resource_node") and str(candidate.get_meta("route_branch", "")) == branch_id and str(current_zone) == route_id:
			return 20
		if candidate.is_in_group("wildlife_track"):
			return 0
	return 10

func _interaction_range(base_range: float = 2.35, grace: float = 0.0) -> float:
	var range_value := base_range
	if session != null and session.has_method("interaction_range"):
		range_value = float(session.call("interaction_range", base_range))
	return range_value + maxf(0.0, grace)

func _interaction_anchor_position(node: Node3D) -> Vector3:
	if node == null:
		return Vector3.ZERO
	var zones: Variant = node.get_meta("access_zones", [])
	if zones is Array and not (zones as Array).is_empty() and player != null:
		if node.has_meta("construction_id"):
			var door_zone := _first_access_zone(zones as Array, "door")
			var door_center: Array = door_zone.get("center", [])
			if door_center.size() >= 3:
				return node.to_global(Vector3(float(door_center[0]), 0.0, float(door_center[2])))
		var nearest := node.global_position
		var nearest_distance := INF
		for zone_value in zones:
			if not (zone_value is Dictionary):
				continue
			var zone: Dictionary = zone_value
			var center: Array = zone.get("center", [])
			if center.size() < 3:
				continue
			var candidate := node.to_global(Vector3(float(center[0]), 0.0, float(center[2])))
			var distance := _ground_distance(player.global_position, candidate)
			if distance < nearest_distance:
				nearest = candidate
				nearest_distance = distance
		return nearest
	return node.global_position

func _first_access_zone(zones: Array, zone_kind: String) -> Dictionary:
	for zone_value in zones:
		if zone_value is Dictionary and str((zone_value as Dictionary).get("kind", "")) == zone_kind:
			return (zone_value as Dictionary).duplicate(true)
	return {}

func _access_zone_by_id(zones: Array, zone_id: String) -> Dictionary:
	if zone_id.is_empty():
		return {}
	for zone_value in zones:
		if zone_value is Dictionary and str((zone_value as Dictionary).get("id", "")) == zone_id:
			return (zone_value as Dictionary).duplicate(true)
	return {}

func _world_access_zone(structure_node: Node3D, zone_kind: String, zone_id := "") -> Dictionary:
	if structure_node == null:
		return {}
	var zones: Variant = structure_node.get_meta("access_zones", [])
	if not zones is Array:
		return {}
	var zone := _access_zone_by_id(zones as Array, zone_id) if not zone_id.is_empty() else _first_access_zone(zones as Array, zone_kind)
	if zone.is_empty():
		return {}
	var center: Array = zone.get("center", [])
	var facing: Array = zone.get("facing", [])
	if center.size() < 3 or facing.size() < 3:
		return {}
	var local_center := Vector3(float(center[0]), 0.0, float(center[2]))
	var local_facing := Vector3(float(facing[0]), 0.0, float(facing[2])).normalized()
	zone["world_center"] = structure_node.to_global(local_center)
	zone["world_facing"] = (structure_node.global_basis * local_facing).normalized()
	return zone

func _ground_distance(first: Vector3, second: Vector3) -> float:
	return Vector2(first.x - second.x, first.z - second.z).length()

func _interaction_distance(node: Node3D) -> float:
	if player == null or node == null:
		return INF
	return _ground_distance(player.global_position, _interaction_anchor_position(node))

func _world_label_anchor(label: Label3D) -> Node3D:
	var cursor: Node = label.get_parent()
	while cursor != null:
		var candidate := cursor as Node3D
		if candidate != null and candidate.is_in_group("interactable"):
			return candidate
		cursor = cursor.get_parent()
	return label.get_parent() as Node3D

func _update_world_label_visibility(focus: Node) -> void:
	if player == null:
		return
	for label_node in get_tree().get_nodes_in_group("world_label"):
		var label := label_node as Label3D
		if label == null:
			continue
		var anchor := _world_label_anchor(label)
		if anchor == null or not anchor.is_visible_in_tree():
			label.visible = false
			continue
		var distance := _ground_distance(player.global_position, _interaction_anchor_position(anchor))
		var label_radius := 3.6
		if anchor.is_in_group("resource_node") and session != null and session.has_method("resource_node_guidance"):
			var guidance: Dictionary = session.call("resource_node_guidance", str(anchor.get("node_id")), distance)
			if not guidance.is_empty():
				label_radius = maxf(1.6, float(guidance.get("label_radius", 1.6)))
				var stage := anchor.get_node_or_null("ResourceStage") as Label3D
				if stage != null:
					var base_label := str(anchor.get("resource_label") if anchor.get("resource_label") != null else "RESOURCE").to_upper()
					if bool(guidance.get("grade_known", false)):
						stage.text = "%s\nVEIN: %s" % [base_label, str(guidance.get("resource_grade", "standard")).to_upper()]
					elif str(guidance.get("resource_grade", "standard")) == "deep" and distance <= 3.6:
						stage.text = "%s\nDEEP SEAM" % base_label
					else:
						stage.text = base_label
		var nearby := distance <= label_radius
		label.visible = anchor == focus or nearby

func _interact() -> void:
	if get_tree().paused:
		return
	if player != null and player.has_method("cancel_navigation"):
		player.call("cancel_navigation", true)
	if interior_active:
		_interior_interact()
		return
	var nearest := _nearest_interactable()
	if nearest == null:
		_show_toast("Nothing close enough to interact with.", 1.8)
		return
	if nearest.has_meta("construction_id"):
		_construction_interact(nearest as Node3D)
		return
	if nearest.has_method("interact"):
		nearest.call("interact", player)

func observe_wildlife(creature: Node3D) -> void:
	if get_tree().paused or session == null or player == null or creature == null or not is_instance_valid(creature):
		return
	var wildlife_id := str(creature.get("wildlife_id"))
	var zone_id := str(creature.get("zone_id"))
	var observation_delta := creature.global_position - player.global_position
	observation_delta.y = 0.0
	var observation_range := 2.35
	if session.has_method("interaction_range"):
		observation_range = float(session.call("interaction_range", observation_range))
	if wildlife_id.is_empty() or zone_id != current_zone or not creature.is_visible_in_tree() or observation_delta.length() > observation_range:
		_show_toast("Move closer to observe that creature.", 1.8)
		return
	var observed: Array = session.get("observed_wildlife")
	if observed.has(wildlife_id):
		_show_toast("Your field journal already has this observation.", 1.8)
		return
	var before_observation: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	if not bool(session.call("observe_wildlife", wildlife_id)):
		_show_toast("The creature slips back into the route.", 1.8)
		return
	if not bool(session.call("save_game")):
		if not before_observation.is_empty():
			session.call("restore_state", before_observation)
		_copy_session_to_runtime()
		_show_toast("Observation not saved. The journal remains unchanged.", 2.2)
		return
	creature.call("reveal_observation")
	for candidate in get_tree().get_nodes_in_group("wildlife_creature"):
		if is_instance_valid(candidate) and str(candidate.get("wildlife_id")) == wildlife_id:
			candidate.call("set_observed", true)
	if audio_director != null:
		audio_director.call("play_action", "discovery")
	_show_toast("Observed %s  |  Field journal updated" % str(creature.get("species_label")), 2.4)

func _is_player_structure_kind(node: Node, kind: String) -> bool:
	return node != null and node.has_meta("construction_id") and str(node.get_meta("structure_kind", "")) == kind

func _workshop_contextual_action() -> void:
	if get_tree().paused:
		return
	if interior_active:
		_toggle_interior_station_placement()
		return
	var context_node := _nearest_interactable()
	if _is_player_structure_kind(context_node, "workshop"):
		_construction_interact(context_node as Node3D)
	else:
		_build_workshop()

func _livestock_contextual_action() -> void:
	if get_tree().paused:
		return
	var context_node := _nearest_interactable()
	_livestock_interact(context_node if context_node != null else livestock_pen)

func _contextual_interact() -> void:
	if get_tree().paused or interior_transitioning:
		return
	if interior_active and interior_station_placement_mode:
		_confirm_interior_station_placement()
		return
	if is_player_input_locked():
		_fishing_action()
		return
	if placement_mode:
		_place_structure()
	else:
		_interact()

func _toggle_build_context() -> void:
	if interior_active:
		_toggle_interior_station_placement()
	else:
		_toggle_structure_placement()

func _construction_interact(structure_node: Node3D) -> void:
	if structure_node == null or session == null or not structure_node.has_meta("construction_id"):
		return
	var instance_id := str(structure_node.get_meta("construction_id"))
	var structure: Dictionary = session.get("structures").get(instance_id, {})
	var state := str(structure.get("state", "removed"))
	var kind := str(structure.get("kind", ""))
	if state == "operational":
		if kind == "workshop":
			_enter_building_interior(structure_node)
			return
		if kind == "archive":
			_library_interact(structure_node)
			return
		if kind == "livestock_pen":
			_livestock_interact(structure_node)
			return
		if kind == "storage_shed":
			_show_toast("Storage Shed operational. Expedition satchel capacity: %d." % int(session.get("cargo_capacity")), 2.8)
			return
		_show_toast("%s operational. %s" % [_structure_display_name(kind), str(ContentRegistry.structure_definition(kind).get("summary", "The building is ready."))], 2.8)
		return
	if state == "building":
		_show_toast("The %s frame is complete. Sleep to finish the build (%dh remaining)." % [_structure_display_name(kind), int(structure.get("remaining_hours", 0.0))], 2.6)
		return
	var definition := ContentRegistry.structure_definition(kind)
	var cost: Dictionary = definition.get("cost", {})
	var delivered: Dictionary = structure.get("delivered_materials", {})
	for material_id in cost:
		var required := int(cost[material_id])
		var supplied := int(delivered.get(str(material_id), 0))
		if supplied >= required:
			continue
		var inventory_amount := int(session.get("inventory").get(str(material_id), 0))
		if inventory_amount <= 0:
			_show_toast("Bring %d %s to the scaffold (%d / %d delivered)." % [required - supplied, str(material_id).capitalize(), supplied, required], 2.6)
			return
		var before_delivery: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
		# One interaction carries the available stack to the site. The world still
		# shows a physical delivery tween, but a 12-log frame is not twelve UI
		# chores; the remaining material order is the next meaningful decision.
		var delivery_amount := mini(required - supplied, inventory_amount)
		var delivered_structure: Dictionary = session.call("deliver_structure_material", instance_id, str(material_id), delivery_amount)
		if delivered_structure.is_empty():
			_show_toast("That material could not be delivered.", 2.0)
			return
		var new_state := str(delivered_structure.get("state", "blueprint"))
		_refresh_structure_visual(instance_id, delivered_structure)
		if not bool(session.call("save_game")):
			if not before_delivery.is_empty():
				session.call("restore_state", before_delivery)
			_copy_session_to_runtime()
			_refresh_structure_visuals()
			_show_toast("The material delivery could not be secured. Nothing was consumed.", 3.0)
			return
		_emit_feedback_event("build_delivery", structure_node.global_position, _player_feedback_direction(), 0.6, _resource_feedback_surface(str(material_id)), "construction", {"structure": kind, "material_id": str(material_id), "amount": delivery_amount})
		_spawn_material_delivery_feedback(str(material_id), structure_node)
		if new_state == "building":
			_show_toast("Scaffold complete. Sleep to finish the %s frame." % _structure_display_name(kind), 3.0)
		else:
			_show_toast("Delivered %d %s. The scaffold now shows the material on site." % [delivery_amount, str(material_id).capitalize()], 2.0)
		return

func _enter_building_interior(structure_node: Node3D) -> void:
	if get_tree().paused or interior_active or interior_transitioning or structure_node == null or building_interior == null or player == null:
		return
	if not structure_node.has_meta("construction_id") or str(structure_node.get_meta("structure_kind", "")) != "workshop":
		return
	var interior_profile: Dictionary = SanctuaryAssetCatalog.structure_definition("workshop").get("interior_profile", {})
	var entry_zone_id := str(interior_profile.get("entry_zone_id", ""))
	var door_zone := _world_access_zone(structure_node, "door", entry_zone_id)
	var has_door := not door_zone.is_empty() and door_zone.has("world_center")
	var door_world: Vector3 = door_zone.get("world_center", Vector3.ZERO)
	var door_outward: Vector3 = door_zone.get("world_facing", Vector3(0.0, 0.0, 1.0))
	if not has_door or str(door_zone.get("kind", "")) != "door" or door_outward.length_squared() < 0.01:
		_show_toast("This Workshop has no measured front door.", 2.2)
		return
	if _ground_distance(player.global_position, door_world) > _interaction_range(2.35, 0.15):
		_show_toast("Approach the Workshop's front door to enter.", 2.2)
		return
	var instance_id := str(structure_node.get_meta("construction_id", ""))
	var structure: Dictionary = session.get("structures").get(instance_id, {}) if session != null else {}
	if str(structure.get("state", "")) != "operational":
		return
	var measurement: Dictionary = structure_node.get_meta("source_measurement", {})
	var access_zones: Array = SanctuaryAssetCatalog.structure_access_zones("workshop", 0)
	if not building_interior.call("configure_for_structure", "workshop", measurement, access_zones, interior_profile):
		_show_toast("The Workshop interior is unavailable until its measured shell is valid.", 2.6)
		return
	var measured_interior_layout: Dictionary = building_interior.call("room_layout")
	if not bool(session.call("set_interior_layout", instance_id, measured_interior_layout)):
		_show_toast("The measured Workshop layout could not be secured.", 2.6)
		return
	var old_interior_kind := interior_kind
	var old_interior_instance_id := interior_instance_id
	var old_return_position := interior_return_position
	var old_return_facing := interior_return_facing
	var old_transitioning := interior_transitioning
	var old_placement_mode := placement_mode
	var old_utilities_open := utilities_open
	var old_marker_visible := build_marker != null and build_marker.visible
	_reset_manual_input()
	placement_mode = false
	utilities_open = false
	if build_marker != null:
		build_marker.visible = false
	interior_kind = "workshop"
	interior_instance_id = instance_id
	interior_return_position = _measured_door_egress_position(structure_node, measurement, door_zone, interior_profile)
	interior_return_facing = door_outward
	interior_transitioning = true
	var started := bool(building_interior.call("transition_to", true, interior_kind, interior_instance_id, Callable(self, "_finish_enter_building_interior")))
	if not started:
		# Entry is a transaction: a failed fade/room activation must not leave
		# identity, camera return data, placement state, or HUD state half-mutated.
		interior_kind = old_interior_kind
		interior_instance_id = old_interior_instance_id
		interior_return_position = old_return_position
		interior_return_facing = old_return_facing
		interior_transitioning = old_transitioning
		placement_mode = old_placement_mode
		utilities_open = old_utilities_open
		if build_marker != null:
			build_marker.visible = old_marker_visible

func _measured_door_egress_position(structure_node: Node3D, measurement: Dictionary, door_zone: Dictionary, interior_profile: Dictionary) -> Vector3:
	var fitted_bounds: AABB = measurement.get("fitted_bounds", AABB())
	var local_center := Vector3.ZERO
	var center_value: Array = door_zone.get("center", [])
	if center_value.size() >= 3:
		local_center = Vector3(float(center_value[0]), 0.0, float(center_value[2]))
	var local_facing := Vector3(0.0, 0.0, 1.0)
	var facing_value: Array = door_zone.get("facing", [])
	if facing_value.size() >= 3:
		local_facing = Vector3(float(facing_value[0]), 0.0, float(facing_value[2])).normalized()
	var support := local_center
	if absf(local_facing.x) > absf(local_facing.z):
		support.x = fitted_bounds.end.x if local_facing.x >= 0.0 else fitted_bounds.position.x
		support.z = clampf(support.z, fitted_bounds.position.z, fitted_bounds.end.z)
	else:
		support.z = fitted_bounds.end.z if local_facing.z >= 0.0 else fitted_bounds.position.z
		support.x = clampf(support.x, fitted_bounds.position.x, fitted_bounds.end.x)
	var horizontal_extent := minf(fitted_bounds.size.x, fitted_bounds.size.z)
	var egress_ratio := clampf(float(interior_profile.get("egress_clearance_ratio", 0.18)), 0.10, 0.30)
	var egress_clearance := clampf(horizontal_extent * egress_ratio, 0.70, 1.30)
	var outward_world := (structure_node.global_basis * local_facing).normalized()
	var egress := structure_node.to_global(support) + outward_world * egress_clearance
	egress.y = 1.0
	return egress

func _finish_enter_building_interior() -> void:
	if player == null or building_interior == null:
		interior_transitioning = false
		return
	if sanctuary_zone != null:
		sanctuary_zone.visible = false
		_set_zone_collisions(sanctuary_zone, false)
	if sanctuary_style != null:
		sanctuary_style.visible = false
	if sanctuary_district != null:
		sanctuary_district.visible = false
	var environment_node := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if environment_node != null and environment_node.environment != null:
		# Interior presentation owns the background tone while the Sanctuary is
		# hidden. This keeps the authored room card readable at its measured scale
		# instead of exposing the outdoor teal clear color around its edges.
		environment_node.environment.background_color = Color("#162127")
	interior_active = true
	var persisted_stations: Dictionary = session.get("interior_stations").get(interior_instance_id, {}) if session != null else {}
	building_interior.call("sync_persisted_stations", persisted_stations)
	player.global_position = building_interior.call("entry_position")
	player.set("last_direction", building_interior.call("entry_facing"))
	player.call("cancel_navigation", true)
	player.call("set_joystick_vector", Vector2.ZERO)
	if camera != null:
		var room_dimensions: Vector3 = building_interior.call("room_dimensions")
		camera.size = maxf(8.8, room_dimensions.z * 1.78)
	camera_anchor_initialized = false
	_show_toast("Workshop entered  |  B places fit-out, C cycles stations, X rotates.", 3.0) if persisted_stations.is_empty() else _show_toast("Workshop entered  |  B places fit-out, C cycles stations, X rotates.", 2.8)

func _exit_building_interior() -> void:
	if get_tree().paused or not interior_active or interior_transitioning or building_interior == null:
		return
	_reset_manual_input()
	interior_station_placement_mode = false
	if building_interior != null:
		building_interior.call("clear_station_preview")
	interior_transitioning = true
	var started := bool(building_interior.call("transition_to", false, "", "", Callable(self, "_finish_exit_building_interior")))
	if not started:
		interior_transitioning = false

func _finish_exit_building_interior() -> void:
	interior_active = false
	interior_station_placement_mode = false
	if building_interior != null:
		building_interior.call("clear_station_preview")
	var environment_node := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if environment_node != null and environment_node.environment != null:
		environment_node.environment.background_color = _zone_background(current_zone)
	# The normal fade already deactivates the room before this callback. Keep the
	# callback idempotent as well so a failed-exit recovery or a direct runtime
	# harness cannot leave station colliders active in the Sanctuary.
	if building_interior != null:
		building_interior.call("set_room_active", false)
	if sanctuary_zone != null:
		sanctuary_zone.visible = true
		_set_zone_collisions(sanctuary_zone, true)
	if sanctuary_style != null:
		sanctuary_style.visible = true
	if sanctuary_district != null:
		sanctuary_district.visible = false
	if player != null:
		var egress_result: Dictionary = _resolve_egress_position(interior_return_position, interior_return_facing)
		if not bool(egress_result.get("valid", false)):
			# Never leave the player inside an unverified obstacle. Re-open the room
			# and keep the exterior hidden until a later exit attempt can find a
			# complete capsule-sized clearance.
			interior_active = true
			if sanctuary_zone != null:
				sanctuary_zone.visible = false
				_set_zone_collisions(sanctuary_zone, false)
			if sanctuary_style != null:
				sanctuary_style.visible = false
			if building_interior != null:
				building_interior.call("set_room_active", true, interior_kind, interior_instance_id)
			_show_toast("The doorway is blocked. Clear the entrance and try again.", 2.6)
			return
		interior_return_position = egress_result.get("position", interior_return_position)
		player.global_position = interior_return_position
		player.set("last_direction", interior_return_facing)
		player.call("cancel_navigation", true)
		player.call("set_joystick_vector", Vector2.ZERO)
	if camera != null:
		camera.size = SANCTUARY_CAMERA_SIZE
	camera_anchor_initialized = false
	interior_kind = ""
	interior_instance_id = ""
	_show_toast("Back in the Sanctuary.", 1.8)

func _resolve_egress_position(candidate: Vector3, outward: Vector3) -> Dictionary:
	if get_world_3d() == null or player == null:
		return {"valid": false, "reason": "missing_world_or_player"}
	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		return {"valid": false, "reason": "missing_space_state"}
	# Match the actual player collider instead of probing a small ground sphere.
	# This catches low walls, doorway posts, and any obstacle that would overlap
	# the player's full standing capsule after the fade completes.
	var player_collision := _player_movement_collision()
	var player_capsule := player_collision.shape as CapsuleShape3D if player_collision != null else null
	if player_collision == null or player_capsule == null:
		return {"valid": false, "reason": "player_capsule_unavailable"}
	var probe := player_capsule.duplicate() as CapsuleShape3D
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = probe
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	var direction := outward.normalized() if outward.length_squared() > 0.01 else Vector3(0.0, 0.0, 1.0)
	var resolved := candidate
	for step in 10:
		query.transform = Transform3D(Basis.IDENTITY, resolved) * player_collision.transform
		var hits := space_state.intersect_shape(query, 8)
		if hits.is_empty():
			return {"valid": true, "position": resolved, "steps": step}
		resolved += direction * 0.42
	return {"valid": false, "reason": "no_capsule_clearance", "attempts": 10}

func _player_movement_collision() -> CollisionShape3D:
	if player == null:
		return null
	for value in player.find_children("*", "CollisionShape3D", true, false):
		var collision := value as CollisionShape3D
		if collision != null and collision.shape is CapsuleShape3D:
			return collision
	return null

func _interior_interact() -> void:
	if not interior_active or interior_transitioning or building_interior == null:
		return
	var nearest := _nearest_interactable()
	if nearest == null:
		_show_toast("Move closer to a workshop station.", 1.8)
		return
	var action := str(nearest.get_meta("interior_action", ""))
	match action:
		"exit":
			_exit_building_interior()
		"storage", "workshop", "furnace", "anvil":
			var station_state := str(nearest.get_meta("installation_state", "blueprint"))
			if station_state != "operational":
				_deliver_interior_station_material(nearest)
			elif action == "anvil":
				_anvil_use(nearest)
			elif action == "storage":
				_storage_use(nearest)
			else:
				_workshop_use(nearest)
		_:
			_show_toast("This station is not operational yet.", 1.8)

func _interior_station_action_text(station_node: Node3D) -> String:
	if station_node == null:
		return "INTERACT"
	var state := str(station_node.get_meta("installation_state", "blueprint"))
	if state != "operational":
		return "DELIVER MATERIALS"
	match str(station_node.get_meta("interior_action", "")):
		"workshop": return "CRAFT %s" % selected_recipe.to_upper()
		"furnace": return "SMELT ORE"
		"anvil": return "REPAIR TOOLS"
		"storage": return "OPEN STORAGE"
	return "INTERACT"

func _interior_station_label(station_kind: String) -> String:
	var definition := ContentRegistry.interior_station_definition(station_kind)
	return str(definition.get("label", station_kind.replace("_", " ").capitalize()))

func _update_interior_station_preview() -> void:
	if not interior_active or not interior_station_placement_mode or building_interior == null or session == null or player == null:
		if building_interior != null and not interior_station_placement_mode:
			building_interior.call("clear_station_preview")
		return
	var player_local: Vector3 = building_interior.call("world_to_room_local", player.global_position)
	var facing: Vector3 = player.get("last_direction") if player.get("last_direction") is Vector3 else Vector3(0.0, 0.0, -1.0)
	if facing.length_squared() < 0.01:
		facing = Vector3(0.0, 0.0, -1.0)
	var footprint := ContentRegistry.interior_station_footprint(selected_interior_station_kind, interior_station_rotation)
	var target_local := player_local + facing.normalized() * 1.45
	var layout: Dictionary = session.call("interior_layout_for_structure", interior_instance_id)
	var layout_size_value: Variant = layout.get("room_size", [8.2, 6.2])
	var layout_size := Vector2(8.2, 6.2)
	if layout_size_value is Array and (layout_size_value as Array).size() >= 2:
		layout_size = Vector2(float((layout_size_value as Array)[0]), float((layout_size_value as Array)[1]))
	var layout_cell_size := float(layout.get("cell_size", 1.0))
	var candidate_cell := InteriorGrid.local_to_cell(target_local, footprint, layout_size, layout_cell_size)
	var player_cell := InteriorGrid.local_to_cell(player_local, Vector2i.ONE, layout_size, layout_cell_size)
	var valid := bool(session.call("can_place_interior_station", interior_instance_id, selected_interior_station_kind, [candidate_cell.x, candidate_cell.y], interior_station_rotation, [player_cell.x, player_cell.y]))
	interior_station_preview_cell = candidate_cell
	interior_station_preview_valid = valid
	building_interior.call("set_station_preview", candidate_cell, interior_station_rotation, valid)

func _toggle_interior_station_placement() -> void:
	if not interior_active or interior_transitioning:
		return
	interior_station_placement_mode = not interior_station_placement_mode
	if not interior_station_placement_mode:
		building_interior.call("clear_station_preview")
		_show_toast("Fit-out placement cancelled.", 1.6)
	else:
		_show_toast("Place %s  |  C cycles stations, X rotates, E confirms." % _interior_station_label(selected_interior_station_kind), 3.0)

func _cycle_interior_station_kind() -> void:
	if not interior_active or interior_transitioning or interior_station_placement_mode:
		return
	var options := ["workbench", "furnace_left", "furnace_right", "anvil", "storage"]
	var current_index := options.find(selected_interior_station_kind)
	var persisted: Dictionary = session.get("interior_stations").get(interior_instance_id, {}) if session != null else {}
	for step in options.size():
		var candidate := str(options[(current_index + step + 1) % options.size()])
		var already_placed := false
		for station_id in persisted:
			var record: Variant = persisted.get(station_id, {})
			if record is Dictionary and str(record.get("kind", "")) == candidate:
				already_placed = true
				break
		if not already_placed:
			selected_interior_station_kind = candidate
			_show_toast("Fit-out station: %s  |  Press B to place." % _interior_station_label(selected_interior_station_kind), 2.0)
			return
	_show_toast("All Workshop fit-out stations are already placed.", 2.0)

func _rotate_interior_station_placement() -> void:
	if not interior_active or not interior_station_placement_mode:
		return
	interior_station_rotation = posmod(interior_station_rotation + 1, 4)
	_show_toast("%s rotation: %d°" % [_interior_station_label(selected_interior_station_kind), interior_station_rotation * 90], 1.5)

func _confirm_interior_station_placement() -> void:
	if not interior_active or not interior_station_placement_mode or not interior_station_preview_valid or session == null:
		_show_toast("The %s footprint is blocked. Move to a clear wall-side cell." % _interior_station_label(selected_interior_station_kind), 2.2)
		return
	var before: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var placed: Dictionary = session.call("place_interior_station", interior_instance_id, selected_interior_station_kind, [interior_station_preview_cell.x, interior_station_preview_cell.y], interior_station_rotation, [])
	if placed.is_empty():
		_show_toast("That %s cannot be placed there." % _interior_station_label(selected_interior_station_kind), 2.2)
		return
	if not bool(session.call("save_game")):
		if not before.is_empty():
			session.call("restore_state", before)
		_copy_session_to_runtime()
		building_interior.call("sync_persisted_stations", session.get("interior_stations").get(interior_instance_id, {}))
		_show_toast("The fit-out could not be secured. Nothing was placed.", 2.8)
		return
	interior_station_placement_mode = false
	building_interior.call("clear_station_preview")
	_show_toast("%s blueprint placed. Bring its listed materials to assemble it." % _interior_station_label(selected_interior_station_kind), 3.0)

func _deliver_interior_station_material(station_node: Node3D) -> void:
	if session == null or station_node == null:
		return
	var station_id := str(station_node.get_meta("interior_station_id", ""))
	var parent_id := str(station_node.get_meta("interior_structure_id", interior_instance_id))
	var record: Dictionary = session.call("interior_station_status", parent_id, station_id)
	if record.is_empty():
		_show_toast("This station identity is no longer valid. Re-enter the Workshop.", 2.2)
		return
	var state := str(record.get("state", "blueprint"))
	if state == "building":
		_show_toast("The station is assembling. Sleep to advance its work.", 2.4)
		return
	if state == "operational":
		return
	var definition := ContentRegistry.interior_station_definition(str(record.get("kind", "")))
	var delivered: Dictionary = record.get("delivered_materials", {})
	for material_id in definition.get("cost", {}):
		var remaining := int(definition["cost"][material_id]) - int(delivered.get(str(material_id), 0))
		var available := int(session.get("inventory").get(str(material_id), 0))
		if remaining <= 0:
			continue
		if available <= 0:
			_show_toast("Bring %d %s to the blueprint." % [remaining, str(material_id).capitalize()], 2.4)
			return
		var before: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
		var amount := mini(remaining, available)
		var updated: Dictionary = session.call("deliver_interior_station_material", parent_id, station_id, str(material_id), amount)
		if updated.is_empty():
			_show_toast("That material could not be delivered.", 2.2)
			return
		if not bool(session.call("save_game")):
			if not before.is_empty():
				session.call("restore_state", before)
			_copy_session_to_runtime()
			building_interior.call("sync_persisted_stations", session.get("interior_stations").get(interior_instance_id, {}))
			_show_toast("The delivery could not be secured. Nothing was consumed.", 2.8)
			return
		building_interior.call("sync_persisted_stations", session.get("interior_stations").get(interior_instance_id, {}))
		_show_toast("Delivered %d %s to the station." % [amount, str(material_id).capitalize()], 2.2)
		return

func _is_live_resource_node(node: Node) -> bool:
	if node == null or not is_instance_valid(node) or not node.is_in_group("resource_node") or not node.is_visible_in_tree():
		return false
	var node_3d := node as Node3D
	if node_3d == null or player == null or _zone_for_node(node) != current_zone.replace(" ", ""):
		return false
	if session != null and session.has_method("resource_node_is_registered_instance") and not bool(session.call("resource_node_is_registered_instance", node)):
		return false
	return _interaction_distance(node_3d) <= _interaction_range()

func collect_resource(node: Node) -> bool:
	if not _is_live_resource_node(node):
		return false
	var id: String = str(node.get("resource_id"))
	var amount: int = int(node.get("resource_amount"))
	var resource_label: String = str(node.get("resource_label"))
	var discovery_id: String = str(node.get("discovery_id"))
	var collected := false
	var harvested_pickup: Dictionary = {}
	var before_harvest: Dictionary = session.call("snapshot_state") if session != null and session.has_method("snapshot_state") else {}
	var previous_contacts := int(node.get("contacts"))
	if not _route_resource_is_available(node):
		return false
	if current_zone != "Sanctuary" and not discovery_id.is_empty() and session != null and session.has_method("can_record_expedition_discovery") and not bool(session.call("can_record_expedition_discovery", discovery_id)):
		_show_toast("That discovery lies on the closed trail. Your committed route cannot reach it.", 2.5)
		return false
	if session != null and session.has_method("can_access_resource_node") and not bool(session.call("can_access_resource_node", str(node.get("node_id")))):
		_show_toast("The seam is too deep. Earn Mining mastery: Deep Delver.", 2.8)
		return false
	if session != null and not session.call("can_use_tool_for_resource", id):
		var tool_name := "a tool"
		if id == "wood":
			tool_name = "a hatchet"
		elif id in ["stone", "ore", "sunstone"]:
			tool_name = "a pickaxe"
		elif id == "shell":
			tool_name = "a fishing knife"
		_show_toast("Your %s needs repair. Use Planks at the Workshop." % tool_name, 2.8)
		return false
	if current_zone == "Sanctuary":
		var contact_complete := true
		if node.has_method("apply_contact"):
			contact_complete = node.call("apply_contact")
		if not contact_complete:
			if node.has_method("play_contact_feedback"):
				node.call("play_contact_feedback")
			if session != null:
				if not session.call("spend_resource_contact", id) or not session.call("record_sanctuary_contact", str(node.get("node_id")), int(node.get("contacts"))):
					if not before_harvest.is_empty():
						session.call("restore_state", before_harvest)
					if node.has_method("restore"):
						node.call("restore")
						if node.has_method("set_contact_progress"):
							node.call("set_contact_progress", previous_contacts)
					return false
			else:
				if not _consume_energy(1):
					return false
			if session != null and not bool(session.call("save_game")):
				if not before_harvest.is_empty():
					session.call("restore_state", before_harvest)
				if node.has_method("restore"):
					node.call("restore")
					if node.has_method("set_contact_progress"):
						node.call("set_contact_progress", previous_contacts)
				_copy_session_to_runtime()
				_show_toast("The gathering effort could not be secured. Nothing was consumed.", 2.8)
				return false
			_show_toast("Contact %d / %d  |  Keep your footing." % [int(node.get("contacts")), int(node.get("required_contacts"))], 1.5)
			_emit_feedback_event("gather_contact", node.global_position, Vector3.ZERO, 0.7, _resource_feedback_surface(id), "resource", {"resource_id": id, "contact": true})
			if current_zone != "Sanctuary":
				player_made_noise(node.global_position, 5.0)
			return true
		if session != null:
			var harvest_result: Dictionary = session.call("resolve_sanctuary_harvest", str(node.get("node_id")), id, amount, int(node.get("contacts")), int(node.get("required_contacts")))
			if harvest_result.is_empty():
				if node.has_method("restore"):
					node.call("restore")
					if node.has_method("set_contact_progress"):
						node.call("set_contact_progress", previous_contacts)
				return false
			collected = true
		else:
			if not _consume_energy(1):
				return false
			inventory[id] = int(inventory.get(id, 0)) + amount
			collected = true
	else:
		var node_id := str(node.get("node_id"))
		var required_contacts := int(node.get("required_contacts"))
		if required_contacts > 1:
			if session == null or not session.call("spend_resource_contact", id):
				return false
			var contact_complete := true
			if node.has_method("apply_contact"):
				contact_complete = node.call("apply_contact")
			if not contact_complete:
				if node.has_method("play_contact_feedback"):
					node.call("play_contact_feedback")
				if session != null:
					if not bool(session.call("record_expedition_contact", node_id, int(node.get("contacts")))):
						session.call("restore_state", before_harvest)
						if node.has_method("set_contact_progress"):
							node.call("set_contact_progress", previous_contacts)
						_copy_session_to_runtime()
						_show_toast("The gathering contact could not be secured. Nothing was consumed.", 2.8)
						return false
				if not bool(session.call("save_game")):
					session.call("restore_state", before_harvest)
					if node.has_method("set_contact_progress"):
						node.call("set_contact_progress", previous_contacts)
					_copy_session_to_runtime()
					_show_toast("The gathering effort could not be secured. Nothing was consumed.", 2.8)
					return false
				_show_toast("Contact %d / %d  |  The forest is listening." % [int(node.get("contacts")), required_contacts], 1.5)
				_emit_feedback_event("gather_contact", node.global_position, Vector3.ZERO, 0.7, _resource_feedback_surface(id), "resource", {"resource_id": id, "contact": true})
				player_made_noise(node.global_position, 5.0)
				return true
			harvested_pickup = session.call("harvest_expedition_resource", node_id, id, amount, required_contacts, [node.global_position.x, node.global_position.y, node.global_position.z], discovery_id, true) if session != null and session.has_method("harvest_expedition_resource") else {}
			collected = not harvested_pickup.is_empty()
		else:
			harvested_pickup = session.call("harvest_expedition_resource", node_id, id, amount, 1, [node.global_position.x, node.global_position.y, node.global_position.z], discovery_id) if session != null and session.has_method("harvest_expedition_resource") else {}
			if harvested_pickup.is_empty():
				return false
			collected = true
		if not collected:
			return false
	if not collected:
		return false
	if current_zone != "Sanctuary" and not harvested_pickup.is_empty():
		return _commit_expedition_harvest(node, harvested_pickup, before_harvest, id, amount, resource_label)
	if node.has_method("complete_depletion"):
		node.call("complete_depletion")
	var mastery_name := "Mining" if id in ["stone", "ore", "sunstone"] else "Foraging"
	var new_discovery := false
	_sync_expedition_cargo()
	if session != null:
		if not discovery_id.is_empty() and session.call("record_discovery", discovery_id):
			new_discovery = true
		if not bool(session.call("save_game")):
			session.call("restore_state", before_harvest)
			if node.has_method("restore"):
				node.call("restore")
				if node.has_method("set_contact_progress"):
					node.call("set_contact_progress", previous_contacts)
			_copy_session_to_runtime()
			_show_toast("The gathering effort could not be secured. Nothing was taken.", 3.0)
			return false
	_emit_feedback_event("gather_contact", node.global_position, Vector3.ZERO, 1.0, _resource_feedback_surface(id), "resource", {"resource_id": id, "contact": false})
	_spawn_feedback_burst(node.global_position, palette["leaf"] if mastery_name == "Foraging" else palette["stone"])
	if new_discovery:
		_show_toast("Discovery: %s  |  Return to the Archive to understand it." % discovery_id, 3.2)
	else:
		_show_toast("+%d %s  |  %s mastery +%d" % [amount, resource_label, mastery_name, amount * 3], 2.2)
	if current_zone != "Sanctuary":
		player_made_noise(node.global_position, 7.0 if id in ["ore", "stone"] else 5.0)
	return true

func _commit_expedition_harvest(node: Node, pickup: Dictionary, before_harvest: Dictionary, resource_id: String, amount: int, resource_label: String) -> bool:
	var node_3d := node as Node3D
	if session == null or pickup.is_empty() or node_3d == null:
		return false
	var pickup_id := str(pickup.get("pickup_id", ""))
	if pickup_id.is_empty():
		return false
	_spawn_expedition_pickup(pickup)
	var harvest_saved := bool(session.call("save_game"))
	if not harvest_saved:
		if not before_harvest.is_empty():
			session.call("restore_state", before_harvest)
		_clear_expedition_pickup_visuals()
		_copy_session_to_runtime()
		_refresh_expedition_pickups()
		if node != null and node.has_method("restore"):
			node.call("restore")
			var restored_run: Variant = before_harvest.get("expedition_run", {})
			if restored_run is Dictionary:
				var restored_contacts: Variant = restored_run.get("contact_progress", {})
				var restored_contacts_done := int(restored_contacts.get(str(node.get("node_id")), 0)) if restored_contacts is Dictionary else 0
				if node.get("contacts") != null and restored_contacts_done > 0:
					node.set("contacts", restored_contacts_done)
		_show_toast("The harvest could not be secured. Nothing was taken from the route.", 3.0)
		return false
	if node != null and node.has_method("complete_depletion"):
		node.call("complete_depletion")
	_emit_feedback_event("gather_contact", node_3d.global_position, Vector3.ZERO, 1.0, _resource_feedback_surface(resource_id), "resource", {"resource_id": resource_id, "contact": false, "expedition": true})
	_spawn_feedback_burst(node_3d.global_position, palette["leaf"] if resource_id not in ["stone", "ore", "sunstone"] else palette["stone"])
	player_made_noise(node_3d.global_position, 7.0 if resource_id in ["ore", "stone"] else 5.0)
	_show_toast("Harvested %d %s. The bundle is on the ground; pick it up before you leave." % [amount, resource_label], 3.0)
	return not pickup_id.is_empty()

func collect_expedition_pickup(pickup_node: Node) -> bool:
	if pickup_node == null or session == null or current_zone == "Sanctuary":
		return false
	var pickup_id := str(pickup_node.get("pickup_id"))
	if not pickup_node.is_in_group("expedition_pickup") or not pickup_node.is_visible_in_tree() or _zone_for_node(pickup_node) != current_zone.replace(" ", ""):
		return false
	if expedition_pickup_visuals.get(pickup_id) != pickup_node:
		return false
	var pickup_3d := pickup_node as Node3D
	if pickup_3d == null or player == null or _interaction_distance(pickup_3d) > _interaction_range(2.0):
		return false
	var before_pickup: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var already_discovered := false
	var discovery_id := str(pickup_node.get("discovery_id"))
	if not discovery_id.is_empty():
		already_discovered = session.get("discovered").has(discovery_id)
	var resolution: Dictionary = session.call("collect_expedition_pickup", pickup_id) if session.has_method("collect_expedition_pickup") else {}
	if resolution.is_empty():
		var stranded_amount := maxi(1, int(pickup_node.get("amount")))
		_show_toast("Your satchel is full. %d bundle item%s stay on the ground; extraction ends this run." % [stranded_amount, "" if stranded_amount == 1 else "s"], 3.0)
		return false
	var resource_id := str(resolution.get("resource_id", ""))
	var amount := int(resolution.get("amount", 0))
	var mastery_name := "Mining" if resource_id in ["stone", "ore", "sunstone"] else "Foraging"
	if not bool(session.call("save_game")):
		if not before_pickup.is_empty():
			session.call("restore_state", before_pickup)
		_copy_session_to_runtime()
		_sync_expedition_cargo()
		_refresh_expedition_pickups()
		_show_toast("The pickup could not be secured. The bundle remains on the route.", 3.0)
		return false
	_copy_session_to_runtime()
	_sync_expedition_cargo()
	var remaining := int(resolution.get("remaining", 0))
	if remaining <= 0:
		expedition_pickup_visuals.erase(pickup_id)
		pickup_node.queue_free()
	else:
		pickup_node.call("set_amount", remaining)
	if not discovery_id.is_empty() and not already_discovered:
		_show_toast("Discovery: %s  |  Return to the Archive to understand it." % discovery_id, 3.2)
	else:
		_show_toast("+%d %s  |  %s mastery +%d" % [amount, str(resolution.get("resource_label", resource_id.capitalize())), mastery_name, amount * 3], 2.2)
	_emit_feedback_event("pickup", pickup_node.global_position, Vector3.ZERO, 0.6, _resource_feedback_surface(resource_id), "pickup", {"resource_id": resource_id})
	return true

func _route_resource_is_available(node: Node) -> bool:
	if node == null or current_zone == "Sanctuary" or session == null or not session.has_method("has_active_expedition") or not session.call("has_active_expedition"):
		return true
	var route_branch := str(node.get_meta("route_branch", ""))
	if route_branch.is_empty():
		return true
	var run: Dictionary = session.get("expedition_run")
	var branch_id := str(run.get("branch_id", ""))
	if branch_id.is_empty():
		_show_toast("Choose a trail at the route fork before harvesting this landmark.", 2.5)
		return false
	if branch_id != route_branch:
		_show_toast("That landmark lies on the closed trail.", 2.2)
		return false
	return true

func is_resource_depleted(node: Node) -> bool:
	if session == null:
		return false
	if current_zone == "Sanctuary":
		return session.has_method("is_sanctuary_depleted") and session.call("is_sanctuary_depleted", str(node.get("node_id")))
	if not session.has_method("has_active_expedition"):
		return false
	if not session.call("has_active_expedition"):
		return false
	var run: Dictionary = session.get("expedition_run")
	return str(run.get("biome_id", "")) == current_zone and run.get("depleted_ids", []).has(str(node.get("node_id")))

func begin_resource_action(node: Node) -> void:
	if resource_action_node != null or resource_contact_node != null or pending_attack_target != null or node == null or not is_instance_valid(node):
		return
	if not _route_resource_is_available(node):
		return
	var gather_range := float(session.call("interaction_range", 2.35)) if session != null and session.has_method("interaction_range") else 2.35
	if current_zone == "Sanctuary" and _interaction_distance(node as Node3D) > gather_range:
		_show_toast("Move closer before gathering.", 1.5)
		return
	var resource_id := str(node.get("resource_id"))
	if session != null and not session.call("can_use_tool_for_resource", resource_id):
		var tool_name := "your tool"
		if resource_id == "wood":
			tool_name = "your hatchet"
		elif resource_id in ["stone", "ore", "sunstone"]:
			tool_name = "your pickaxe"
		_show_toast("%s is worn out. Repair it at the Workshop." % tool_name.capitalize(), 2.4)
		return
	resource_action_node = node
	resource_action_elapsed = 0.0
	resource_action_duration = float(session.call("gathering_duration_seconds", 0.58)) if session != null and session.has_method("gathering_duration_seconds") else 0.58
	var resource_label := str(node.get("resource_label"))
	_show_toast("Gathering %s... hold your ground." % (resource_label if not resource_label.is_empty() else resource_id), 0.8)
	if player != null and player.has_method("play_gather_feedback"):
		player.call("play_gather_feedback", resource_id)
	_emit_feedback_event("gather_prepare", node.global_position, Vector3.ZERO, 0.35, _resource_feedback_surface(resource_id), "resource", {"resource_id": resource_id})

func _update_resource_action(delta: float) -> void:
	if resource_contact_node != null:
		if not is_instance_valid(resource_contact_node):
			resource_contact_node = null
			resource_contact_elapsed = 0.0
			return
		resource_contact_elapsed += delta
		if resource_contact_elapsed < 0.10:
			return
		var contact_node := resource_contact_node
		resource_contact_node = null
		resource_contact_elapsed = 0.0
		collect_resource(contact_node)
		return
	if resource_action_node == null:
		return
	if not is_instance_valid(resource_action_node) or not resource_action_node.is_visible_in_tree():
		_cancel_resource_action()
		return
	if _interaction_distance(resource_action_node as Node3D) > _interaction_range(2.35, 0.25):
		_cancel_resource_action()
		_show_toast("Gathering interrupted.", 1.4)
		return
	resource_action_elapsed += delta
	if resource_action_elapsed < resource_action_duration:
		return
	var completed_node := resource_action_node
	resource_action_node = null
	resource_action_elapsed = 0.0
	resource_contact_node = completed_node
	resource_contact_elapsed = 0.0
	if player != null and player.has_method("finish_gather_feedback"):
		player.call("finish_gather_feedback")

func _cancel_resource_action() -> void:
	resource_action_node = null
	resource_action_elapsed = 0.0
	resource_contact_node = null
	resource_contact_elapsed = 0.0
	if player != null and player.has_method("cancel_gather_feedback"):
		player.call("cancel_gather_feedback")

func farm_plot_interact(plot: Node) -> void:
	if current_zone != "Sanctuary" or plot == null:
		return
	if _interaction_distance(plot as Node3D) > _interaction_range():
		_show_toast("Move closer to the Garden Plot first.", 1.8)
		return
	if session == null or not session.has_method("interact_farm"):
		return
	var before_farm: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var result: Dictionary = session.call("interact_farm")
	if not bool(result.get("ok", false)):
		match str(result.get("reason", "")):
			"bed_cost": _show_toast("Garden bed needs 1 Wood + 2 Fiber, plus energy.", 2.3)
			"seed": _show_toast("You need a wheat seed and enough energy.", 2.2)
			"water": _show_toast("The pond can refill your water pouch.", 2.2)
			"energy": _show_toast("You are too tired to work the garden.", 2.0)
			_: _show_toast("The crop is growing. Water once, then give it time.", 2.0)
		return
	if not bool(session.call("save_game")):
		if not before_farm.is_empty() and session.has_method("restore_state"):
			session.call("restore_state", before_farm)
		_copy_session_to_runtime()
		_refresh_farm_plot()
		_show_toast("The garden change could not be secured. Nothing was consumed or harvested.", 3.0)
		return
	_copy_session_to_runtime()
	match str(result.get("action", "")):
		"tilled": _show_toast("The soil is ready. Press E again to plant wheat.", 2.4)
		"planted": _show_toast("Wheat planted. Water it, then sleep to grow it.", 2.5)
		"harvested": _show_toast("Harvested %d Wheat%s  |  Farming mastery +12" % [int(result.get("amount", 0)), "  |  Seed saved" if bool(result.get("seed_saved", false)) else ""], 2.8)
		"watered": _show_toast("Watered. The next sleep will move the crop forward.", 2.5)
	_refresh_farm_plot()

func station_interact(station: Node) -> void:
	if station == null:
		return
	if session == null:
		return
	var station_id := str(station.get("station_id"))
	if station_id not in ["camp", "whisper_branch", "whisper_cache", "map_branch", "map_capstone", "fishing", "lore_inscription", "wildlife_track"] and current_zone != "Sanctuary":
		return
	if _interaction_distance(station as Node3D) > _interaction_range():
		var station_name := "the Workshop"
		if station_id == "library":
			station_name = "the Archive"
		elif station_id == "notice":
			station_name = "the Notice Board"
		elif station_id == "camp":
			station_name = "the Expedition Camp"
		elif station_id == "guide":
			station_name = "Mira"
		elif station_id == "livestock":
			station_name = "Clover's Pen"
		elif station_id == "whisper_branch":
			station_name = "the Old Trail Marker"
		elif station_id == "whisper_cache":
			station_name = "the route cache"
		elif station_id == "map_branch":
			station_name = "the route fork"
		elif station_id == "map_capstone":
			station_name = "the route capstone"
		elif station_id == "fishing":
			station_name = "the tidepool" if str(station.get_meta("fishing_spot_id", "")) == "sunlit_tidepool" else "the fishing pond"
		elif station_id == "lore_inscription":
			station_name = "the expedition inscription"
		elif station_id == "wildlife_track":
			station_name = "the fresh tracks"
		_show_toast("Move closer to %s first." % station_name, 1.8)
		return
	if station_id == "notice":
		_notice_board_interact()
		return
	if station_id == "route":
		_route_gate_interact(station)
		return
	if station_id == "camp":
		_camp_interact()
		return
	if station_id == "whisper_branch":
		_whisper_branch_interact(station)
		return
	if station_id == "whisper_cache":
		_whisper_cache_interact(station)
		return
	if station_id == "map_branch":
		_map_branch_interact(station)
		return
	if station_id == "map_capstone":
		_map_capstone_interact(station)
		return
	if station_id == "lore_inscription":
		_expedition_inscription_interact(station)
		return
	if station_id == "wildlife_track":
		_wildlife_track_interact(station)
		return
	if station_id == "guide":
		_guide_interact()
		return
	if station_id == "fishing":
		_fishing_interact(station)
		return
	if station_id == "bazaar":
		_bazaar_interact()
		return
	if station_id == "livestock":
		_livestock_interact(station)
		return
	if station_id == "library":
		_library_interact(station)
		return
	_workshop_use(station)

func _has_operational_player_structure(kind: String) -> bool:
	if session == null:
		return false
	for structure_id in session.get("structures"):
		var structure: Dictionary = session.get("structures").get(structure_id, {})
		if str(structure.get("kind", "")) == kind and str(structure.get("state", "")) == "operational":
			return true
	return false

func _workshop_use(source: Node3D = null) -> void:
	if session == null:
		return
	var station_id := ""
	var station_parent_id := ""
	var station_action := "workshop"
	var station_capability := "workshop_crafting"
	if source != null and source.is_in_group("building_interior_station"):
		station_id = str(source.get_meta("interior_station_id", ""))
		station_parent_id = str(source.get_meta("interior_structure_id", interior_instance_id))
		station_action = str(source.get_meta("interior_action", "workshop"))
		var station_definition := ContentRegistry.interior_station_definition(str(source.get_meta("interior_station_kind", "")))
		station_capability = str(station_definition.get("capability", "workshop_crafting"))
		if str(source.get_meta("installation_state", "blueprint")) != "operational":
			_deliver_interior_station_material(source)
			return
		if not bool(session.call("has_station_capability", station_parent_id, station_capability, station_id)):
			_show_toast("This station is not operational yet.", 2.2)
			return
	if source == workshop and _has_operational_player_structure("workshop"):
		_show_toast("This is the old workshop shell. Use the Workshop you placed in the Sanctuary.", 2.6)
		return
	if station_id.is_empty() and not bool(session.get("built").get("workshop", false)):
		_show_toast("This is a shell. Place and finish a Workshop blueprint first.", 2.5)
		return
	var job: Dictionary = session.get("station_job")
	if str(job.get("kind", "none")) != "none":
		if not station_id.is_empty() and (str(job.get("structure_id", "")) != station_parent_id or str(job.get("station_id", "")) != station_id):
			_show_toast("Another station is already working. Finish that job first.", 2.4)
			return
		if float(job.get("remaining_hours", 0.0)) > 0.0:
			_show_toast("The station is working. Sleep to finish the job.", 2.2)
			return
		var before_claim: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
		var claimed: Dictionary = session.call("claim_workshop_job")
		if not claimed.is_empty():
			if not bool(session.call("save_game")):
				if not before_claim.is_empty():
					session.call("restore_state", before_claim)
				_copy_session_to_runtime()
				_refresh_station_visual()
				_show_toast("The completed craft could not be secured. Nothing was claimed.", 2.8)
				return
			_refresh_station_visual()
			if str(claimed.get("output_kind", "material")) == "tool":
				_show_toast("Workshop complete  |  %s restored to %d durability" % [str(claimed.get("tool_id", "")).replace("_", " ").capitalize(), int(claimed.get("max_durability", 0))], 2.8)
			else:
				_show_toast("Workshop complete  |  +%d %s" % [int(claimed.get("output", 0)), str(claimed.get("output_id", "")).capitalize()], 2.6)
			return
	else:
		var recipe_id := "ingot" if station_action == "furnace" else selected_recipe
		var recipe: Dictionary = ContentRegistry.workshop_recipe(recipe_id)
		var recipe_text := str(recipe.get("summary", "The recipe is incomplete."))
		var before_start: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
		var started: Dictionary = session.call("start_workshop_job", recipe_id, station_id, station_parent_id)
		if started.is_empty():
			_show_toast("Workshop recipe: %s." % recipe_text, 2.5)
			return
		if not bool(session.call("save_game")):
			if not before_start.is_empty():
				session.call("restore_state", before_start)
				_copy_session_to_runtime()
				_refresh_station_visual()
				_show_toast("The workshop order could not be secured. Materials were returned.", 2.8)
			return
		_show_toast("%s job started. Sleep once, then claim it here." % recipe_id.capitalize(), 2.5)
	_refresh_station_visual()

func _anvil_use(source: Node3D) -> void:
	if session == null or source == null:
		return
	var station_id := str(source.get_meta("interior_station_id", ""))
	var structure_id := str(source.get_meta("interior_structure_id", interior_instance_id))
	var before: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var repaired := ""
	for tool_id in ["hatchet", "pickaxe", "fishing_knife"]:
		if bool(session.call("repair_tool_at_station", tool_id, station_id, structure_id)):
			repaired = tool_id
			break
	if repaired.is_empty():
		_show_toast("Anvil ready  |  Tools are repaired, or you need Planks.", 2.4)
		return
	if not bool(session.call("save_game")):
		if not before.is_empty() and session.has_method("restore_state"):
			session.call("restore_state", before)
		_copy_session_to_runtime()
		_show_toast("The repair could not be secured. Planks were returned.", 2.8)
		return
	_copy_session_to_runtime()
	_show_toast("Anvil repaired %s  |  Planks consumed." % repaired.replace("_", " ").capitalize(), 2.4)
	if audio_director != null:
		audio_director.call("play_action", "repair")

func _storage_use(source: Node3D) -> void:
	if session == null or source == null:
		return
	var station_id := str(source.get_meta("interior_station_id", ""))
	var structure_id := str(source.get_meta("interior_structure_id", interior_instance_id))
	if not bool(session.call("has_station_capability", structure_id, "workshop_storage", station_id)):
		_show_toast("Material Storage is not operational yet.", 2.2)
		return
	_show_toast("Material Storage open  |  Satchel capacity %d. Banked materials remain safe here." % int(session.get("cargo_capacity")), 2.8)

func _food_count() -> int:
	return int(inventory.get("tonic", 0)) + int(inventory.get("omelette", 0)) + int(inventory.get("bread", 0)) + int(inventory.get("fish", 0)) + int(inventory.get("berries", 0))

func _cycle_food_selection() -> void:
	var options := ["tonic", "omelette", "bread", "fish", "berries"]
	var start := options.find(selected_food)
	for step in options.size():
		var candidate: String = options[(start + step + 1) % options.size()]
		if int(inventory.get(candidate, 0)) > 0:
			selected_food = candidate
			_show_toast("Food selected: %s" % selected_food.capitalize(), 1.5)
			return
	_show_toast("No prepared food. Fish, harvest, or cook at the Workshop.", 2.2)

func _eat_best_food() -> void:
	if get_tree().paused or is_player_input_locked() or session == null or (current_zone != "Sanctuary" and not session.call("has_active_expedition")):
		return
	var food_id := selected_food if int(inventory.get(selected_food, 0)) > 0 else ""
	if food_id.is_empty():
		_cycle_food_selection()
		food_id = selected_food if int(inventory.get(selected_food, 0)) > 0 else ""
	if food_id.is_empty():
		_show_toast("You have no ready food. Fish, harvest, or cook at the Workshop.", 2.6)
		return
	var before_food: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	if not bool(session.call("consume_food", food_id)):
		_show_toast("You have no ready food. Fish, harvest, or cook at the Workshop.", 2.6)
		return
	if not bool(session.call("save_game")):
		if not before_food.is_empty() and session.has_method("restore_state"):
			session.call("restore_state", before_food)
		_copy_session_to_runtime()
		_show_toast("That meal could not be secured. Nothing was consumed.", 2.8)
		return
	_copy_session_to_runtime()
	_show_toast("Ate %s  |  Energy and nutrition restored." % food_id.capitalize(), 2.2)
	if audio_director != null:
		audio_director.call("play_action", "eat")

func _cycle_recipe_selection() -> void:
	if get_tree().paused or session == null:
		return
	var options := ["plank", "bread", "omelette"]
	if session.get("unlocked_features").has("tonic_recipe"):
		options.append("tonic")
	if session.get("unlocked_features").has("crafting_quality_work"):
		options.append("reinforced_hatchet")
	if session.get("unlocked_features").has("crafting_masterwork_bench"):
		options.append("masterwork_pickaxe")
	var start := options.find(selected_recipe)
	selected_recipe = options[(start + 1) % options.size()]
	_show_toast("Workshop recipe selected: %s" % selected_recipe.capitalize(), 1.6)

func _drink_water() -> void:
	if get_tree().paused or is_player_input_locked() or session == null or (current_zone != "Sanctuary" and not session.call("has_active_expedition")):
		return
	var before_water: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	if not bool(session.call("drink_water")):
		_show_toast("Your water pouch is empty, or you are already hydrated.", 2.3)
		return
	if not bool(session.call("save_game")):
		if not before_water.is_empty() and session.has_method("restore_state"):
			session.call("restore_state", before_water)
		_copy_session_to_runtime()
		_show_toast("That drink could not be secured. Nothing was consumed.", 2.8)
		return
	_copy_session_to_runtime()
	_show_toast("Drank from your water pouch  |  Hydration restored.", 2.0)
	if audio_director != null:
		audio_director.call("play_action", "drink")

func _repair_tools() -> void:
	if get_tree().paused or is_player_input_locked() or current_zone != "Sanctuary" or session == null:
		return
	var before_repair: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var repaired := ""
	for tool_id in ["hatchet", "pickaxe", "fishing_knife"]:
		if session.call("repair_tool", tool_id):
			repaired = tool_id
			break
	if repaired.is_empty():
		_show_toast("Tools are ready, or you need Planks to repair them.", 2.3)
		return
	if not bool(session.call("save_game")):
		if not before_repair.is_empty() and session.has_method("restore_state"):
			session.call("restore_state", before_repair)
		_copy_session_to_runtime()
		_show_toast("The repair could not be secured. Planks were returned.", 2.8)
		return
	_copy_session_to_runtime()
	_show_toast("Repaired %s  |  Planks consumed." % repaired.replace("_", " ").capitalize(), 2.3)
	if audio_director != null:
		audio_director.call("play_action", "repair")

func _livestock_interact(station: Node) -> void:
	if current_zone != "Sanctuary" or session == null or station == null:
		return
	if _interaction_distance(station as Node3D) > _interaction_range():
		_show_toast("Move closer to Clover's pen first.", 1.8)
		return
	if station == livestock_pen and _has_operational_player_structure("livestock_pen"):
		_show_toast("This is the old pen shell. Use the Livestock Pen you placed in the Sanctuary.", 2.6)
		return
	var built_state: Dictionary = session.get("built")
	if not bool(built_state.get("livestock_pen", false)):
		placement_structure_id = "livestock_pen"
		_toggle_structure_placement()
		_show_toast("Choose a clear place for Clover's pen. Deliver 10 Wood, 6 Fiber, and 2 Planks at the blueprint.", 3.2)
		return
	var before_collect: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var collected: Dictionary = session.call("collect_livestock", "clover")
	if not collected.is_empty():
		if not bool(session.call("save_game")):
			if not before_collect.is_empty() and session.has_method("restore_state"):
				session.call("restore_state", before_collect)
			_copy_session_to_runtime()
			_refresh_livestock_visual()
			_show_toast("Clover's collection could not be secured. Nothing was collected.", 2.8)
			return
		_copy_session_to_runtime()
		var trait_text := "  |  %s trait +%d" % [str(collected.get("trait_id", "")).capitalize(), int(collected.get("trait_bonus", 0))] if not str(collected.get("trait_id", "")).is_empty() else ""
		_show_toast("Collected %d Egg  |  Livestock mastery +8%s" % [int(collected.get("egg", 0)), trait_text], 2.5)
		if audio_director != null:
			audio_director.call("play_action", "collect")
		_refresh_livestock_visual()
		return
	var before_feed: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	if session.call("feed_livestock", "clover"):
		if not bool(session.call("save_game")):
			if not before_feed.is_empty() and session.has_method("restore_state"):
				session.call("restore_state", before_feed)
			_copy_session_to_runtime()
			_refresh_livestock_visual()
			_show_toast("Clover's feeding could not be secured. Wheat was returned.", 2.8)
			return
		_copy_session_to_runtime()
		_show_toast("Fed Clover  |  Sleep to let the pen produce.", 2.4)
		_refresh_livestock_visual()
	else:
		_show_toast("Clover is either full or needs 1 Wheat. Check back after sleep.", 2.4)

func _refresh_livestock_visual() -> void:
	if livestock_pen == null or session == null:
		return
	var marker := livestock_pen.get_node_or_null("LivestockLabel") as Label3D
	if marker == null:
		return
	var pen_built := bool(session.get("built").get("livestock_pen", false))
	if not pen_built:
		marker.text = "LIVESTOCK PEN\nSHELL"
		return
	var animal: Dictionary = session.get("livestock").get("clover", {})
	var state := "READY" if bool(animal.get("production_ready", false)) else "HUNGER %d" % int(animal.get("hunger", 0))
	var trait_id := str(animal.get("trait_id", ""))
	var trait_line := "\nTRAIT: %s" % str(ContentRegistry.livestock_trait_definition(trait_id).get("label", trait_id)) if not trait_id.is_empty() else ("\nNURTURE %d%%" % int(animal.get("trait_progress", 0)) if session.call("has_permission", "livestock_sanctuary_breeder") else "")
	marker.text = "CLOVER\n" + state + trait_line

func _fishing_interact(station: Node = null) -> void:
	if session == null or is_player_input_locked():
		return
	var spot_id := "sanctuary_pond"
	var zone_id := "Sanctuary"
	var visual_spot := fishing_spot
	if station != null and station.has_meta("fishing_spot_id"):
		spot_id = str(station.get_meta("fishing_spot_id"))
		zone_id = str(ContentRegistry.fishing_spot_definition(spot_id).get("zone_id", ""))
		visual_spot = station as Node3D
	if current_zone != zone_id or visual_spot == null:
		return
	var fishing_state: Dictionary = session.call("fishing_status") if session.has_method("fishing_status") else {}
	var fishing_status := str(fishing_state.get("status", "idle"))
	if fishing_status == "landed":
		var before_claim: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
		var catch_result: Dictionary = session.call("claim_fishing") if session.has_method("claim_fishing") else {}
		if catch_result.is_empty() or not bool(session.call("save_game")):
			if not before_claim.is_empty() and session.has_method("restore_state"):
				session.call("restore_state", before_claim)
			_show_toast("The landed catch could not be secured. It is still waiting at the pond.", 2.8)
			return
		_copy_session_to_runtime()
		_emit_feedback_event("fishing", visual_spot.global_position, Vector3.ZERO, 1.0, "water", "fishing", {"audio_kind": "fishing_catch", "amount": int(catch_result.get("amount", 0))})
		var uncommon_text := "  |  +%d Shell from the tide" % int(catch_result.get("bonus_resource_amount", 0)) if bool(catch_result.get("uncommon_catch", false)) else ""
		_show_toast("Catch claimed  |  +%d Fish  |  Fishing mastery +8%s" % [int(catch_result.get("amount", 0)), uncommon_text], 2.6)
		return
	if fishing_status == "failed":
		var before_failed_reset: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
		session.call("cancel_fishing")
		if not bool(session.call("save_game")):
			if not before_failed_reset.is_empty() and session.has_method("restore_state"):
				session.call("restore_state", before_failed_reset)
			_show_toast("The escaped line could not be cleared from storage yet.", 2.6)
			return
		_copy_session_to_runtime()
		_show_toast("The old line is cleared. Cast again when you are ready.", 2.0)
		return
	if not session.call("has_items", {"fiber": 1}):
		_show_toast("Fishing needs 1 Fiber for bait. Gather reeds or cactus fiber first.", 2.4)
		return
	var before_fishing: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var fishing_result: Dictionary = session.call("begin_fishing", spot_id, zone_id, [player.global_position.x, player.global_position.y, player.global_position.z]) if session.has_method("begin_fishing") else {}
	if fishing_result.is_empty():
		_show_toast("You need 2 Energy and 1 Fiber to fish.", 2.4)
		return
	if player != null:
		player.call("cancel_navigation", true)
		player.call("set_joystick_vector", Vector2.ZERO)
	if not bool(session.call("save_game")):
		if not before_fishing.is_empty() and session.has_method("restore_state"):
			session.call("restore_state", before_fishing)
		_copy_session_to_runtime()
		_show_toast("The catch could not be secured. Bait and energy were returned.", 3.0)
		return
	_copy_session_to_runtime()
	_emit_feedback_event("fishing", visual_spot.global_position, Vector3.ZERO, 0.45, "water", "fishing", {"audio_kind": "fishing_cast"})
	var tide_hint := "  |  Tide Reader sees uncommon shell catches" if spot_id == "sunlit_tidepool" and session.call("has_permission", "fishing_tide_reader") else ""
	_show_toast("Cast. Watch the bobber, then press Interact when it dips.%s" % tide_hint, 2.4)

func _bazaar_interact() -> void:
	if current_zone != "Sanctuary" or session == null:
		return
	var selected_offer: Dictionary = {}
	var market_offers: Array = session.call("market_offers") if session.has_method("market_offers") else []
	var guild_contract: Dictionary = session.call("market_contract") if session.has_method("market_contract") else {}
	if not guild_contract.is_empty() and bool(guild_contract.get("available", false)) and bool(guild_contract.get("affordable", false)):
		var before_contract: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
		var contract_result: Dictionary = session.call("resolve_trade_contract", str(guild_contract.get("contract_id", "")))
		if not contract_result.is_empty():
			if not bool(session.call("save_game")):
				if not before_contract.is_empty() and session.has_method("restore_state"):
					session.call("restore_state", before_contract)
				_copy_session_to_runtime()
				_show_toast("The Guild contract could not be secured. Your goods were returned.", 3.0)
				return
			_copy_session_to_runtime()
			var contract_demand := "Demand unknown"
			if bool(contract_result.get("demand_known", false)):
				contract_demand = str(contract_result.get("demand", "STEADY")).capitalize()
			_show_toast("Guild Broker contract fulfilled  |  +%d Coins  |  %s  |  Trading mastery +16" % [int(contract_result.get("payout", 0)), contract_demand], 3.4)
			return
	for offer_value in market_offers:
		if not (offer_value is Dictionary):
			continue
		var offer: Dictionary = offer_value
		var offer_cost: Dictionary = offer.get("cost", {})
		if bool(offer.get("available", false)) and bool(offer.get("affordable", false)) and session.call("has_items", offer_cost):
			selected_offer = offer
			break
	if selected_offer.is_empty():
		_show_toast("Today's Bazaar offers are unavailable or you lack the requested goods. Check back after the next dawn.", 2.8)
		return
	var trade_name := str(selected_offer.get("offer_id", "trade")).replace("_", " ")
	var before_trade: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var result: Dictionary = session.call("resolve_trade_offer", str(selected_offer.get("offer_id", "")))
	if result.is_empty():
		return
	var payout := int(result.get("payout", 0))
	if not bool(session.call("save_game")):
		if not before_trade.is_empty() and session.has_method("restore_state"):
			session.call("restore_state", before_trade)
		_copy_session_to_runtime()
		_show_toast("The trade could not be secured. Your goods were returned.", 3.0)
		return
	_copy_session_to_runtime()
	var demand_text := "Demand unknown"
	if bool(result.get("demand_known", false)):
		demand_text = str(result.get("demand", "STEADY")).capitalize()
	var specialist_text := ""
	if not str(result.get("specialist", "")).is_empty():
		specialist_text = "  |  %s" % str(result.get("specialist", ""))
	_show_toast("Traded %s%s  |  +%d Coins  |  %s  |  Trading mastery +8" % [trade_name, specialist_text, payout, demand_text], 3.0)

func _library_interact(source: Node3D = null) -> void:
	if source == library_station and _has_operational_player_structure("archive"):
		_show_toast("This is the old archive shell. Use the Archive you placed in the Sanctuary.", 2.6)
		return
	var built: Dictionary = session.get("built")
	if not bool(built.get("library", false)):
		placement_structure_id = "archive"
		_toggle_structure_placement()
		_show_toast("Choose a clear place for the Archive. Deliver 8 Wood, 8 Stone, and 3 Planks at the blueprint.", 3.2)
		return
	var next_discovery := ""
	for discovery_id in session.get("discovered"):
		if not session.get("researched").has(discovery_id):
			next_discovery = str(discovery_id)
			break
	if next_discovery.is_empty():
		var clue_values: Variant = session.get("research_clues")
		if clue_values is Array and not clue_values.is_empty():
			var latest_clue: Dictionary = clue_values.back()
			_show_toast("Cross-reference: %s  |  %s" % [str(latest_clue.get("related_id", "unknown lead")), str(latest_clue.get("hint", "A new lead waits beyond the known paths."))], 4.0)
		else:
			_show_toast("The Archive is quiet. Discover something new on an expedition.", 2.4)
		return
	var research_job: Dictionary = session.get("research_job")
	if str(research_job.get("status", "idle")) == "researching":
		_show_toast("The Archive is studying %s. %.1f in-world hours remain." % [str(research_job.get("discovery_id", next_discovery)), float(research_job.get("remaining_hours", 0.0))], 2.8)
		return
	if str(research_job.get("status", "idle")) == "ready":
		var understood_id := str(research_job.get("discovery_id", next_discovery))
		var before_claim: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
		var clues_before: Array = session.get("research_clues") if session.get("research_clues") is Array else []
		if not bool(session.call("claim_research")):
			return
		if not bool(session.call("save_game")):
			if not before_claim.is_empty() and session.has_method("restore_state"):
				session.call("restore_state", before_claim)
			_copy_session_to_runtime()
			_refresh_station_visual()
			_show_toast("The research claim could not be secured. Nothing was learned.", 3.0)
			return
		_copy_session_to_runtime()
		_refresh_station_visual()
		var research_anchor: Node3D = source if source != null else library_station
		if research_anchor != null:
			_emit_feedback_event("discovery", research_anchor.global_position, Vector3.ZERO, 0.55, "wood", "archive")
		var clue_suffix := ""
		var clues_after: Variant = session.get("research_clues")
		if clues_after is Array and clues_after.size() > clues_before.size():
			var clue: Dictionary = clues_after.back()
			clue_suffix = "  |  Clue: %s" % str(clue.get("hint", "A related lead surfaced."))
		_show_toast("Understood: %s  |  %s added.%s" % [understood_id, ContentRegistry.discovery_blueprint(understood_id), clue_suffix], 4.0)
		return
	var before_research: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	if not bool(session.call("research_discovery", next_discovery)):
		if not before_research.is_empty() and session.has_method("restore_state"):
			session.call("restore_state", before_research)
		_copy_session_to_runtime()
		_refresh_station_visual()
		_show_toast("The Archive needs 1 Water and a discovered lead to begin.", 3.0)
		return
	if not bool(session.call("save_game")):
		if not before_research.is_empty() and session.has_method("restore_state"):
			session.call("restore_state", before_research)
		_copy_session_to_runtime()
		_refresh_station_visual()
		_show_toast("The research start could not be secured. Water was returned.", 3.0)
		return
	_copy_session_to_runtime()
	_refresh_station_visual()
	if audio_director != null:
		audio_director.call("play_action", "discovery")
	var research_state: Dictionary = session.get("research_job")
	_show_toast("Research ready: %s  |  Claim it at the Archive." % next_discovery if str(research_state.get("status", "")) == "ready" else "Research started: %s  |  %.1f in-world hours." % [next_discovery, float(research_state.get("total_hours", 0.0))], 3.0)

func _notice_board_interact() -> void:
	if session == null:
		return
	var current_quest: Dictionary = session.get("quest")
	var progress := int(current_quest.get("progress", 0))
	var target := int(current_quest.get("target", 5))
	if bool(current_quest.get("claimed", false)):
		_show_toast("The board is quiet. A new contract will arrive tomorrow.", 2.2)
		return
	if progress >= target:
		var before_claim: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
		if not session.call("claim_quest"):
			_show_toast("The contract is not ready to claim yet.", 2.2)
			return
		if not bool(session.call("save_game")):
			if not before_claim.is_empty():
				session.call("restore_state", before_claim)
			_copy_session_to_runtime()
			_show_toast("The contract could not be secured. The reward remains available.", 3.0)
			return
		if audio_director != null:
			audio_director.call("play_action", "quest")
		_show_toast("Contract complete  |  +45 Coins  |  +25 XP", 2.8)
	else:
		_show_toast("Contract: return from an expedition with %d more cargo." % maxi(0, target - progress), 2.4)

func _camp_interact() -> void:
	if session == null or current_zone == "Sanctuary":
		return
	var before_camp: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	if session.call("use_expedition_camp"):
		if not bool(session.call("save_game")):
			if not before_camp.is_empty():
				session.call("restore_state", before_camp)
			_copy_session_to_runtime()
			_show_toast("Camp could not be secured. The fire remains available.", 2.8)
			return
		if audio_director != null:
			audio_director.call("play_action", "camp")
		_show_toast("You make camp and recover 6 Energy. The fire can only save this run once.", 3.0)
	else:
		_show_toast("This camp has already been used for the current expedition.", 2.2)

func _whisper_branch_interact(_station: Node) -> void:
	if current_zone != "Whisperwood" or session == null or not session.call("has_active_expedition"):
		return
	var run: Dictionary = session.get("expedition_run")
	if not str(run.get("branch_id", "")).is_empty():
		_show_toast("This route is committed to the %s." % ("Grove" if str(run.get("branch_id")) == "grove" else "Clearing"), 2.3)
		return
	# Spatial choice: stand to the left of the marker for the fern grove or to
	# the right for the guardian clearing. The decision is stored in the run.
	var branch_id := "grove" if player.global_position.x <= 0.0 else "clearing"
	var before_branch: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	# Interaction is the safety net for a low-frame-rate or freshly reloaded
	# client; the normal per-frame route tracker records the same beat while the
	# player walks into the fork.
	if str(run.get("route_phase", "approach")) == "arrival":
		session.call("record_route_checkpoint", "fork")
	if session.call("commit_expedition_branch", branch_id):
		if not bool(session.call("save_game")):
			if not before_branch.is_empty():
				session.call("restore_state", before_branch)
			_copy_session_to_runtime()
			_show_toast("The route commitment could not be secured. The fork remains open.", 3.0)
			return
		_refresh_whisperwood_route()
		_show_toast("Route committed: %s. The other trail will wait." % ("Whisperglass Grove" if branch_id == "grove" else "Guardian Clearing"), 3.0)

func _whisper_cache_interact(station: Node) -> void:
	if current_zone != "Whisperwood" or session == null or not session.call("has_active_expedition"):
		return
	var run: Dictionary = session.get("expedition_run")
	var cache_branch := str(station.get_meta("route_branch", "")) if station != null else ""
	if cache_branch != str(run.get("branch_id", "")):
		_show_toast("That cache belongs to the other trail.", 2.2)
		return
	if not bool(run.get("objective_complete", false)):
		_show_toast("Finish this trail's capstone before opening its cache.", 2.5)
		return
	var before_cache: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var loot: Dictionary = session.call("open_expedition_cache")
	if loot.is_empty():
		_show_toast("The cache needs 2 Energy and enough satchel space.", 2.4)
		return
	var loot_text: Array[String] = []
	for resource_id in loot.get("loot", {}):
		loot_text.append("+%d %s" % [int(loot["loot"][resource_id]), str(resource_id).replace("_", " ").capitalize()])
		_sync_expedition_cargo()
		_refresh_whisperwood_route()
	_refresh_expedition_pickups()
	_refresh_expedition_routes()
	if not bool(session.call("save_game")):
		if not before_cache.is_empty():
			session.call("restore_state", before_cache)
		_copy_session_to_runtime()
		_show_toast("The cache opening could not be secured. Nothing was claimed.", 3.0)
		return
	_show_toast("Cache opened  |  %s  |  shortcut open" % ", ".join(loot_text), 3.0)

func _map_branch_interact(station: Node) -> void:
	if session == null or current_zone == "Sanctuary" or not session.call("has_active_expedition"):
		return
	var run: Dictionary = session.get("expedition_run")
	if str(run.get("biome_id", "")) != current_zone or not str(run.get("branch_id", "")).is_empty():
		_show_toast("This route is already committed. The other trail is closed for this run.", 2.4)
		return
	var options: Array = session.call("expedition_branch_options", current_zone)
	if options.size() < 2:
		return
	var selected_index := 0 if player.global_position.x <= 0.0 else 1
	var branch_id := str(options[selected_index])
	var before_branch: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var committed := bool(session.call("commit_expedition_branch", branch_id))
	if committed:
		var branch_saved := bool(session.call("save_game"))
		if not branch_saved:
			if not before_branch.is_empty():
				session.call("restore_state", before_branch)
			_copy_session_to_runtime()
			_show_toast("The route commitment could not be secured. The fork remains open.", 3.0)
			return
		_refresh_expedition_routes()
		var definition: Dictionary = ContentRegistry.expedition_route_definition(current_zone, branch_id)
		_show_toast("Route committed: %s  |  %s" % [str(definition.get("label", branch_id)), str(definition.get("summary", "The trail is yours."))], 3.2)

func _map_capstone_interact(station: Node) -> void:
	if session == null or current_zone == "Sanctuary" or not session.call("has_active_expedition"):
		return
	var run: Dictionary = session.get("expedition_run")
	var branch_id := str(station.get_meta("route_branch", "")) if station != null else ""
	if branch_id != str(run.get("branch_id", "")):
		_show_toast("That capstone belongs to the other trail.", 2.2)
		return
	var definition: Dictionary = ContentRegistry.expedition_route_definition(current_zone, branch_id)
	if not bool(run.get("objective_complete", false)):
		_show_toast(str(definition.get("summary", "Complete the route objective first.")), 2.8)
		return
	var before_capstone: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var loot: Dictionary = session.call("open_expedition_capstone")
	if loot.is_empty():
		_show_toast("The capstone needs 2 Energy and enough satchel space, or it has already been claimed.", 2.8)
		return
	var loot_text: Array[String] = []
	for resource_id in loot.get("loot", {}):
		loot_text.append("+%d %s" % [int(loot["loot"][resource_id]), str(resource_id).replace("_", " ").capitalize()])
	_sync_expedition_cargo()
	_refresh_expedition_routes()
	if not bool(session.call("save_game")):
		if not before_capstone.is_empty():
			session.call("restore_state", before_capstone)
		_copy_session_to_runtime()
		_show_toast("The capstone could not be secured. Nothing was claimed.", 3.0)
		return
	_show_toast("Capstone secured  |  %s  |  return to the beacon" % ", ".join(loot_text), 3.0)

func _expedition_inscription_interact(station: Node) -> void:
	if session == null or current_zone == "Sanctuary" or station == null:
		return
	var inscription_id := str(station.get_meta("inscription_id", ""))
	var status: Dictionary = session.call("expedition_inscription_status", inscription_id) if session.has_method("expedition_inscription_status") else {}
	if not bool(status.get("ready", false)):
		match str(status.get("reason", "locked")):
			"no_expedition": _show_toast("This inscription belongs to a live expedition. Follow the route first.", 2.4)
			"choose_branch": _show_toast("Commit to a trail before interpreting this inscription.", 2.4)
			"off_branch": _show_toast("The inscription lies on the other trail. This run has already been committed.", 2.4)
			"translated": _show_toast("Your field journal already holds this translation.", 2.2)
			"language_locked": _show_toast("The script is still unreadable. Earn %s in Language mastery." % ("World Polyglot" if bool(status.get("ancient", false)) else "Context Reader"), 2.8)
			_: _show_toast("The inscription cannot be read from this route.", 2.2)
		return
	var before_read: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var result: Dictionary = session.call("read_expedition_inscription", inscription_id)
	if result.is_empty():
		_show_toast("The inscription resisted interpretation. Nothing was changed.", 2.4)
		return
	if not bool(session.call("save_game")):
		if not before_read.is_empty():
			session.call("restore_state", before_read)
		_copy_session_to_runtime()
		_show_toast("The translation could not be secured. Nothing was claimed.", 2.8)
		return
	_refresh_expedition_inscription_visuals()
	if audio_director != null:
		audio_director.call("play_action", "discovery")
	_show_toast("%s\n%s  |  +%d XP  +%d Coins  |  Language mastery +%d" % [str(result.get("title", "Translation")), str(result.get("translation", "")), int(result.get("xp", 0)), int(result.get("coins", 0)), int(result.get("mastery", 0))], 5.0)

func _wildlife_track_interact(station: Node) -> void:
	if session == null or current_zone == "Sanctuary" or station == null:
		return
	var wildlife_id := str(station.get_meta("wildlife_id", ""))
	var status: Dictionary = session.call("wildlife_track_status", wildlife_id) if session.has_method("wildlife_track_status") else {}
	if not bool(status.get("ready", false)):
		match str(status.get("reason", "locked")):
			"no_expedition": _show_toast("These tracks belong to an expedition route. Follow the beacon first.", 2.4)
			"hunting_locked": _show_toast("The spoor is fresh, but you need Hunting mastery: Track Sign.", 2.8)
			"tracked": _show_toast("Your field journal already has this track reading.", 2.2)
			_: _show_toast("The tracks have gone cold on this route.", 2.2)
		return
	var before_track: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var result: Dictionary = session.call("inspect_wildlife_track", wildlife_id)
	if result.is_empty():
		_show_toast("The track reading could not be secured. Nothing was changed.", 2.4)
		return
	if not bool(session.call("save_game")):
		if not before_track.is_empty():
			session.call("restore_state", before_track)
		_copy_session_to_runtime()
		_show_toast("The track reading could not be saved. Nothing was claimed.", 2.8)
		return
	_refresh_wildlife_track_visuals()
	if audio_director != null:
		audio_director.call("play_action", "discovery")
	_show_toast("Track Sign  |  %s moving %s  |  +%d XP  |  Hunting mastery +%d" % [str(result.get("label", "Wildlife")), str(result.get("direction", "unknown")).capitalize(), int(result.get("xp", 0)), int(result.get("mastery", 0))], 3.2)

func _guide_interact() -> void:
	if session == null:
		return
	var built: Dictionary = session.get("built")
	if not bool(built.get("workshop", false)):
		_show_toast("Mira: gather 12 Wood and 8 Stone, then raise the Workshop. Every expedition starts at the route board.", 4.0)
	elif not bool(built.get("library", false)):
		_show_toast("Mira: bring a new discovery home, then open the Archive beside the Hearth. Knowledge is a resource too.", 4.0)
	else:
		_show_toast("Mira: cargo is only yours after you return. Use a camp once, watch your energy, and never fight on autopilot.", 4.0)
	if session.has_method("first_run_stage") and str(session.call("first_run_stage")) == "meet_mira":
		var before_guidance: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
		if bool(session.call("advance_first_run", "meet_mira")) and not bool(session.call("save_game")):
			if not before_guidance.is_empty() and session.has_method("restore_state"):
				session.call("restore_state", before_guidance)
				_copy_session_to_runtime()

func _build_workshop() -> void:
	if session == null or current_zone != "Sanctuary":
		return
	if _has_operational_player_structure("workshop"):
		_show_toast("The Workshop is ready. Press C beside it to craft.", 2.2)
		return
	placement_structure_id = "workshop"
	_toggle_structure_placement()
	_show_toast("Choose a clear place for the Workshop. Deliver 12 Wood and 8 Stone at the blueprint.", 3.2)

func _refresh_farm_plot() -> void:
	if farm_plot == null:
		return
	var soil := farm_plot.get_node_or_null("Soil") as MeshInstance3D
	var state := str(farm_plot.get("state"))
	if soil != null:
		soil.material_override = _material(palette["wood_dark"] if state != "empty" else palette["sand"], 1.0)
	var crop_visual := farm_plot.get_node_or_null("CropVisual") as Node3D
	if crop_visual != null:
		crop_visual.queue_free()
	if state == "planted":
		crop_visual = Node3D.new()
		crop_visual.name = "CropVisual"
		farm_plot.add_child(crop_visual)
		var crop_growth := int(farm_plot.get("growth"))
		for index in 6:
			var stalk := MeshInstance3D.new()
			stalk.mesh = _sphere_mesh(0.08 + crop_growth * 0.025, 0.25 + crop_growth * 0.15, 6, 3)
			stalk.material_override = _material(palette["leaf"].lightened(0.08), 0.9)
			stalk.position = Vector3(-1.25 + float(index % 3) * 1.25, 0.35 + crop_growth * 0.1, -0.8 + float(index / 3) * 0.9)
			crop_visual.add_child(stalk)
	var marker := farm_plot.get_node_or_null("FarmState") as Label3D
	if marker != null:
		marker.text = "GARDEN PLOT\n" + ("RIPE" if state == "planted" and int(farm_plot.get("growth")) >= 3 else state.to_upper())

func _refresh_expedition_inscription_visuals() -> void:
	if session == null:
		return
	for node_value in get_tree().get_nodes_in_group("expedition_inscription"):
		var node := node_value as Node3D
		if node == null or not is_instance_valid(node):
			continue
		var label := node.get_node_or_null("InscriptionLabel") as Label3D
		if label == null:
			continue
		var inscription_id := str(node.get_meta("inscription_id", ""))
		var definition := ContentRegistry.expedition_inscription_definition(inscription_id)
		var status: Dictionary = session.call("expedition_inscription_status", inscription_id) if session.has_method("expedition_inscription_status") else {}
		if session.get("translated_inscriptions") is Array and session.get("translated_inscriptions").has(inscription_id):
			label.text = "INSCRIPTION\nTRANSLATED"
		elif bool(status.get("ready", false)):
			label.text = "INSCRIPTION\nREADY TO READ"
		elif str(status.get("reason", "")) == "language_locked":
			label.text = "INSCRIPTION\nUNTRANSLATED"
		else:
			label.text = "INSCRIPTION\n%s" % str(definition.get("title", "LORE"))

func _refresh_wildlife_track_visuals() -> void:
	if session == null:
		return
	for node_value in get_tree().get_nodes_in_group("wildlife_track"):
		var node := node_value as Node3D
		if node == null or not is_instance_valid(node):
			continue
		var label := node.get_node_or_null("TrackLabel") as Label3D
		if label == null:
			continue
		var wildlife_id := str(node.get_meta("wildlife_id", ""))
		var status: Dictionary = session.call("wildlife_track_status", wildlife_id) if session.has_method("wildlife_track_status") else {}
		if session.get("tracked_wildlife") is Array and session.get("tracked_wildlife").has(wildlife_id):
			label.text = "TRACKS\nREAD"
		elif str(status.get("reason", "")) == "hunting_locked":
			label.text = "FRESH TRACKS\nUNREAD"
		else:
			label.text = "FRESH TRACKS\n%s" % str(status.get("label", "WILDLIFE")).to_upper()

func _refresh_station_visual() -> void:
	if session == null:
		return
	if workshop != null:
		var marker := workshop.get_node_or_null("StationLabel") as Label3D
		if marker != null:
			if _has_operational_player_structure("workshop"):
				marker.text = "WORKSHOP\nSTARTER PAD"
			elif not bool(session.get("built").get("workshop", false)):
				marker.text = "WORKSHOP\nSHELL"
			else:
				var job: Dictionary = session.get("station_job")
				marker.text = "WORKSHOP\n" + ("READY" if str(job.get("kind", "none")) == "none" else ("WORKING  %dh" % int(job.get("remaining_hours", 0.0))))
	if library_station != null:
		var library_marker := library_station.get_node_or_null("LibraryLabel") as Label3D
		if library_marker != null:
			var research_state: Dictionary = session.get("research_job")
			var archive_status := "SHELL"
			if _has_operational_player_structure("archive"):
				archive_status = "STARTER PAD"
			elif bool(session.get("built").get("library", false)):
				archive_status = "OPEN"
			if str(research_state.get("status", "idle")) == "researching":
				archive_status = "STUDY %.1fh" % float(research_state.get("remaining_hours", 0.0))
			elif str(research_state.get("status", "idle")) == "ready":
				archive_status = "FINDING READY"
			else:
				var archive_clues: Variant = session.get("research_clues")
				if archive_clues is Array and not archive_clues.is_empty():
					var latest_archive_clue: Dictionary = archive_clues.back()
					archive_status = "LEAD: %s" % str(latest_archive_clue.get("title", latest_archive_clue.get("related_id", "NEW LEAD")))
			library_marker.text = "ARCHIVE\n" + archive_status

func _structure_display_name(structure_id: String) -> String:
	match structure_id:
		"rain_cistern": return "Rain Cistern"
		"workshop": return "Workshop"
		"archive": return "Archive"
		"livestock_pen": return "Livestock Pen"
		"storage_shed": return "Storage Shed"
	return structure_id.replace("_", " ").capitalize()

func _cycle_structure_selection() -> void:
	if is_player_input_locked() or interior_active or current_zone != "Sanctuary" or placement_mode:
		if placement_mode:
			_show_toast("Cancel the current placement before changing its blueprint.", 2.0)
		return
	var structure_ids: Array = []
	for candidate_id in ContentRegistry.STRUCTURES.keys():
		if session == null or not session.has_method("has_structure_blueprint") or bool(session.call("has_structure_blueprint", str(candidate_id))):
			structure_ids.append(candidate_id)
	if structure_ids.is_empty():
		_show_toast("No building blueprints are decoded yet. Bring a discovery home first.", 2.4)
		return
	var current_index := structure_ids.find(placement_structure_id)
	placement_structure_id = str(structure_ids[(current_index + 1) % structure_ids.size()])
	var definition := ContentRegistry.structure_definition(placement_structure_id)
	var cost: Dictionary = definition.get("cost", {})
	var cost_parts: Array[String] = []
	for material_id in cost:
		cost_parts.append("%d %s" % [int(cost[material_id]), str(material_id).capitalize()])
	_show_toast("Blueprint selected: %s  |  %s" % [_structure_display_name(placement_structure_id), " + ".join(cost_parts)], 2.8)

func _toggle_structure_placement() -> void:
	if get_tree().paused or is_player_input_locked() or interior_active or current_zone != "Sanctuary" or session == null:
		return
	if placement_mode:
		placement_mode = false
		placement_rotation_quarter_turns = 0
		if build_marker != null:
			build_marker.visible = false
		_show_toast("Placement cancelled.", 1.4)
		return
	if not session.has_method("has_structure_blueprint") or not bool(session.call("has_structure_blueprint", placement_structure_id)):
		var requirement := str(session.call("structure_blueprint_requirement", placement_structure_id)) if session.has_method("structure_blueprint_requirement") else "a new discovery"
		_show_toast("Blueprint locked. Decode %s at the Archive first." % requirement, 2.8)
		return
	var unique_structure := true
	if session.has_method("structure_is_unique"):
		unique_structure = bool(session.call("structure_is_unique", placement_structure_id))
	if unique_structure:
		for existing_id in session.get("structures"):
			var existing: Dictionary = session.get("structures").get(existing_id, {})
			if str(existing.get("kind", "")) == placement_structure_id and str(existing.get("state", "")) != "removed":
				_show_toast("A %s is already part of this Sanctuary." % _structure_display_name(placement_structure_id), 2.0)
				return
	placement_rotation_quarter_turns = 0
	placement_mode = true
	if player != null and player.has_method("cancel_navigation"):
		player.call("cancel_navigation", true)
	_update_structure_preview()
	_show_toast("Place the %s blueprint on a clear grid cell. Press E to confirm or B to cancel." % _structure_display_name(placement_structure_id), 3.0)

func _rotate_structure_placement() -> void:
	if get_tree().paused or is_player_input_locked() or interior_active or not placement_mode:
		return
	placement_rotation_quarter_turns = posmod(placement_rotation_quarter_turns + 1, 4)
	_update_structure_preview()
	_show_toast("Blueprint rotated to %d°. Press E to place." % (placement_rotation_quarter_turns * 90), 1.2)

func _preview_structure_cell() -> Vector2i:
	var direction := player.get("last_direction") as Vector3
	if direction.length_squared() < 0.01:
		direction = Vector3(0.0, 0.0, -1.0)
	var footprint := _preview_structure_footprint()
	# The preview is measured from the player's near edge, not from the
	# footprint origin. Larger player-authored buildings therefore keep the
	# same readable personal-space gap instead of appearing under the avatar.
	var footprint_clearance := maxf(0.0, float(maxi(footprint.x, footprint.y) - 2))
	var preview_distance := 3.0 + footprint_clearance
	return SettlementGrid.world_to_cell(player.global_position + direction.normalized() * preview_distance)

func _preview_structure_footprint() -> Vector2i:
	var footprint_data: Array = ContentRegistry.structure_definition(placement_structure_id).get("footprint", [1, 1])
	var footprint := Vector2i(int(footprint_data[0]), int(footprint_data[1]))
	return Vector2i(footprint.y, footprint.x) if posmod(placement_rotation_quarter_turns, 2) == 1 else footprint

func _unrotated_structure_footprint(structure_id: String) -> Vector2i:
	var footprint_data: Array = ContentRegistry.structure_definition(structure_id).get("footprint", [1, 1])
	return Vector2i(int(footprint_data[0]), int(footprint_data[1]))

func _structure_preview_valid(cell: Vector2i) -> bool:
	if session == null or not session.call("can_place_structure", placement_structure_id, [cell.x, cell.y], placement_rotation_quarter_turns):
		return false
	var footprint := _preview_structure_footprint()
	for occupied_cell in SettlementGrid.cells_for(cell, footprint):
		if SettlementGrid.cell_to_world(occupied_cell).distance_to(player.global_position) < 1.5:
			return false
	return true

func _update_structure_preview() -> void:
	if not placement_mode or current_zone != "Sanctuary" or player == null:
		if build_marker != null:
			build_marker.visible = false
		if sanctuary_style != null and sanctuary_style.has_method("set_placement_preview"):
			sanctuary_style.call("set_placement_preview", Vector3.ZERO, Vector2i.ONE, false, 0, false)
		return
	if build_marker == null:
		build_marker = Node3D.new()
		build_marker.name = "StructurePlacementGhost"
		var ghost := MeshInstance3D.new()
		ghost.name = "GhostFootprint"
		var ghost_mesh := BoxMesh.new()
		ghost.mesh = ghost_mesh
		ghost.position.y = 0.05
		build_marker.add_child(ghost)
		var ghost_label := _label3d("PLACE", 0.16, palette["cream"])
		ghost_label.name = "GhostLabel"
		ghost_label.position.y = 0.55
		build_marker.add_child(ghost_label)
		add_child(build_marker)
	var cell := _preview_structure_cell()
	var footprint := _preview_structure_footprint()
	var ghost_mesh := build_marker.get_node_or_null("GhostFootprint") as MeshInstance3D
	if ghost_mesh != null:
		ghost_mesh.visible = sanctuary_style == null
		var footprint_box := ghost_mesh.mesh as BoxMesh
		if footprint_box != null:
			var authored_footprint := _unrotated_structure_footprint(placement_structure_id)
			footprint_box.size = Vector3(float(authored_footprint.x), 0.08, float(authored_footprint.y))
	build_marker.visible = true
	build_marker.global_position = SettlementGrid.footprint_center_to_world(cell, footprint)
	build_marker.rotation.y = float(placement_rotation_quarter_turns) * PI * 0.5
	var valid := _structure_preview_valid(cell)
	if ghost_mesh != null:
		ghost_mesh.material_override = _material(palette["leaf"] if valid else palette["danger"], 0.3, true, true)
	var ghost_label := build_marker.get_node_or_null("GhostLabel") as Label3D
	if ghost_label != null:
		ghost_label.text = "PLACE" if valid else "BLOCKED"
	if sanctuary_style != null and sanctuary_style.has_method("set_placement_preview"):
		sanctuary_style.call("set_placement_preview", build_marker.global_position, footprint, valid, placement_rotation_quarter_turns, true)

func _place_structure() -> void:
	if get_tree().paused or is_player_input_locked() or interior_active or not placement_mode or session == null or current_zone != "Sanctuary":
		return
	var cell := _preview_structure_cell()
	if not _structure_preview_valid(cell):
		_show_toast("That footprint is blocked. Find a clear patch of Sanctuary.", 2.0)
		return
	var before_placement: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var placed: Dictionary = session.call("place_structure", placement_structure_id, [cell.x, cell.y], placement_rotation_quarter_turns)
	if placed.is_empty():
		_show_toast("That blueprint cannot be placed on this footprint.", 2.5)
		return
	var instance_id := str(placed.get("id", ""))
	if not instance_id.is_empty():
		_spawn_structure_visual(instance_id, placed)
	placement_mode = false
	if build_marker != null:
		build_marker.visible = false
	var definition := ContentRegistry.structure_definition(placement_structure_id)
	var cost_parts: Array[String] = []
	for material_id in definition.get("cost", {}):
		cost_parts.append("%d %s" % [int(definition["cost"][material_id]), str(material_id).capitalize()])
	if not bool(session.call("save_game")):
		if not before_placement.is_empty():
			session.call("restore_state", before_placement)
		if not instance_id.is_empty() and settlement_visuals.has(instance_id):
			var failed_visual := settlement_visuals.get(instance_id) as Node3D
			if failed_visual != null:
				failed_visual.queue_free()
			settlement_visuals.erase(instance_id)
		_copy_session_to_runtime()
		placement_mode = true
		_update_structure_preview()
		_show_toast("The blueprint could not be secured. Try placing it again.", 3.0)
		return
	_show_toast("%s blueprint placed. Deliver %s at the site, then sleep to finish the frame." % [_structure_display_name(placement_structure_id), " + ".join(cost_parts)], 3.4)

func _spawn_structure_visual(instance_id: String, data: Dictionary) -> void:
	if instance_id.is_empty() or sanctuary_zone == null:
		return
	if settlement_visuals.has(instance_id) and is_instance_valid(settlement_visuals[instance_id]):
		settlement_visuals[instance_id].queue_free()
	var cell_data: Array = data.get("cell", [0, 0])
	if cell_data.size() < 2:
		return
	var structure := Node3D.new()
	structure.name = instance_id
	structure.add_to_group("interactable")
	structure.set_meta("construction_id", instance_id)
	var kind := str(data.get("kind", "rain_cistern"))
	structure.set_meta("structure_kind", kind)
	var authored_footprint := _unrotated_structure_footprint(kind)
	var footprint := authored_footprint
	var rotation_quarter_turns := posmod(int(data.get("rotation", 0)), 4)
	if rotation_quarter_turns % 2 == 1:
		footprint = Vector2i(footprint.y, footprint.x)
	# Geometry is measured from the imported source model in canonical local
	# orientation. The structure root carries the quarter-turn, so deriving the
	# local shape from the already rotated footprint would double-swap the hitbox
	# at 90°/270°. The grid claim is still authoritative; the measured source
	# envelope is the physical/art boundary inside it.
	var asset_measurement := SanctuaryAssetMeasurement.structure_measurement(kind, authored_footprint)
	var measurement_valid := bool(asset_measurement.get("valid", false))
	var local_collision_size: Vector3 = asset_measurement.get("fitted_size", Vector3.ZERO)
	var compound_components: Array = SanctuaryAssetMeasurement.structure_collision_components(kind, authored_footprint)
	if not measurement_valid or local_collision_size.x <= 0.0 or local_collision_size.y <= 0.0 or local_collision_size.z <= 0.0 or compound_components.is_empty():
		push_error("Sanctuary structure '%s' has no valid measured source collision envelope; refusing to spawn an unmeasured hitbox." % kind)
		return
	var world_collision_size := local_collision_size
	if rotation_quarter_turns % 2 == 1:
		world_collision_size = Vector3(local_collision_size.z, local_collision_size.y, local_collision_size.x)
	var footprint_width := local_collision_size.x
	var footprint_depth := local_collision_size.z
	var structure_height := local_collision_size.y - 0.22
	structure.position = SettlementGrid.footprint_center_to_world(Vector2i(int(cell_data[0]), int(cell_data[1])), footprint)
	structure.rotation.y = float(rotation_quarter_turns) * PI * 0.5
	structure.set_meta("asset_id", str(SanctuaryAssetCatalog.structure_definition(kind).get("asset_id", "")))
	structure.set_meta("rotation_quarter_turns", rotation_quarter_turns)
	var directional_variant := SanctuaryAssetCatalog.structure_directional_variant(kind, rotation_quarter_turns)
	structure.set_meta("directional_variant_id", str(directional_variant.get("variant_id", "")))
	structure.set_meta("directional_asset_id", str(directional_variant.get("asset_id", "")))
	# Access metadata stays in canonical local space; the structure root applies
	# the quarter-turn exactly once when _interaction_anchor_position() calls
	# to_global(). The catalog still exposes transformed zones for contract tests.
	structure.set_meta("access_zones", SanctuaryAssetCatalog.structure_access_zones(kind, 0))
	structure.set_meta("access_zone_rotation", rotation_quarter_turns)
	structure.set_meta("grid_footprint", [footprint.x, footprint.y])
	structure.set_meta("collision_footprint", [world_collision_size.x, world_collision_size.z])
	structure.set_meta("ground_pivot", [0.0, 0.0, 0.0])
	structure.set_meta("source_measurement_valid", measurement_valid)
	structure.set_meta("source_measurement", asset_measurement.duplicate(true))
	structure.set_meta("source_mesh_count", int(asset_measurement.get("mesh_count", 0)))
	sanctuary_zone.add_child(structure)
	var blueprint_stakes := Node3D.new()
	blueprint_stakes.name = "BlueprintStakes"
	structure.add_child(blueprint_stakes)
	for offset in [Vector3(-footprint_width * 0.42, 0.22, -footprint_depth * 0.42), Vector3(footprint_width * 0.42, 0.22, -footprint_depth * 0.42), Vector3(-footprint_width * 0.42, 0.22, footprint_depth * 0.42), Vector3(footprint_width * 0.42, 0.22, footprint_depth * 0.42)]:
		var stake := MeshInstance3D.new()
		stake.name = "Stake"
		var stake_mesh := BoxMesh.new()
		stake_mesh.size = Vector3(0.08, 0.42, 0.08)
		stake.mesh = stake_mesh
		stake.material_override = _material(palette["wood"], 0.86)
		stake.position = offset
		blueprint_stakes.add_child(stake)
	_structure_box(blueprint_stakes, "BlueprintRopeFront", Vector3(footprint_width * 0.82, 0.045, 0.045), Vector3(0.0, 0.30, footprint_depth * 0.42), palette["sand"], Vector3.ZERO)
	_structure_box(blueprint_stakes, "BlueprintRopeBack", Vector3(footprint_width * 0.82, 0.045, 0.045), Vector3(0.0, 0.30, -footprint_depth * 0.42), palette["sand"], Vector3.ZERO)
	var base := MeshInstance3D.new()
	base.name = "CisternBase"
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(footprint_width, 0.22, footprint_depth)
	base.mesh = base_mesh
	base.material_override = _material(_structure_base_color(kind), 0.96)
	base.position.y = 0.11
	structure.add_child(base)
	var scaffold := Node3D.new()
	scaffold.name = "ScaffoldFrame"
	structure.add_child(scaffold)
	for offset in [Vector3(-footprint_width * 0.42, structure_height * 0.5, -footprint_depth * 0.42), Vector3(footprint_width * 0.42, structure_height * 0.5, -footprint_depth * 0.42), Vector3(-footprint_width * 0.42, structure_height * 0.5, footprint_depth * 0.42), Vector3(footprint_width * 0.42, structure_height * 0.5, footprint_depth * 0.42)]:
		var post := MeshInstance3D.new()
		post.name = "StructurePost"
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.14, structure_height, 0.14)
		post.mesh = post_mesh
		post.material_override = _material(palette["wood_dark"], 0.9)
		post.position = offset
		scaffold.add_child(post)
	var scaffold_beams := Node3D.new()
	scaffold_beams.name = "ScaffoldBeams"
	scaffold.add_child(scaffold_beams)
	_structure_box(scaffold_beams, "BeamFront", Vector3(footprint_width * 0.88, 0.14, 0.14), Vector3(0.0, structure_height * 0.62, footprint_depth * 0.42), palette["wood_dark"])
	_structure_box(scaffold_beams, "BeamBack", Vector3(footprint_width * 0.88, 0.14, 0.14), Vector3(0.0, structure_height * 0.62, -footprint_depth * 0.42), palette["wood_dark"])
	_structure_box(scaffold_beams, "BeamLeft", Vector3(0.14, 0.14, footprint_depth * 0.84), Vector3(-footprint_width * 0.42, structure_height * 0.62, 0.0), palette["wood_dark"])
	_structure_box(scaffold_beams, "BeamRight", Vector3(0.14, 0.14, footprint_depth * 0.84), Vector3(footprint_width * 0.42, structure_height * 0.62, 0.0), palette["wood_dark"])
	var delivered_logs := Node3D.new()
	delivered_logs.name = "DeliveredLogs"
	for index in 3:
		var log := MeshInstance3D.new()
		log.name = "Log_%d" % index
		var log_mesh := BoxMesh.new()
		log_mesh.size = Vector3(minf(footprint_width * 0.68, 2.2), 0.16, 0.18)
		log.mesh = log_mesh
		log.material_override = _material(palette["wood"], 0.92)
		log.position = Vector3(-footprint_width * 0.34 + float(index) * 0.18, 0.22 + float(index) * 0.18, footprint_depth * 0.48)
		delivered_logs.add_child(log)
	structure.add_child(delivered_logs)
	var delivered_planks := Node3D.new()
	delivered_planks.name = "DeliveredPlanks"
	for index in 2:
		var plank := MeshInstance3D.new()
		plank.name = "Plank_%d" % index
		var plank_mesh := BoxMesh.new()
		plank_mesh.size = Vector3(minf(footprint_width * 0.6, 2.0), 0.08, 0.24)
		plank.mesh = plank_mesh
		plank.material_override = _material(palette["wood"].lightened(0.12), 0.92)
		plank.position = Vector3(footprint_width * 0.48, 0.22 + float(index) * 0.12, -footprint_depth * 0.3 + float(index) * 0.24)
		delivered_planks.add_child(plank)
	structure.add_child(delivered_planks)
	var delivered_stone := Node3D.new()
	delivered_stone.name = "DeliveredStone"
	for index in 5:
		var stone := MeshInstance3D.new()
		stone.name = "Stone_%d" % index
		stone.mesh = _sphere_mesh(0.16 + float(index % 2) * 0.04, 0.30 + float(index % 3) * 0.05, 7, 4)
		stone.material_override = _material(palette["stone"].darkened(0.1), 0.94)
		stone.position = Vector3(-footprint_width * 0.42 + float(index % 3) * 0.24, 0.18 + float(index / 3) * 0.16, -footprint_depth * 0.38 + float(index % 2) * 0.18)
		delivered_stone.add_child(stone)
	structure.add_child(delivered_stone)
	var delivered_fiber := Node3D.new()
	delivered_fiber.name = "DeliveredFiber"
	for index in 4:
		var bundle := MeshInstance3D.new()
		bundle.name = "FiberBundle_%d" % index
		bundle.mesh = _sphere_mesh(0.10, 0.42, 6, 3)
		bundle.material_override = _material(palette["leaf"], 0.9)
		bundle.position = Vector3(footprint_width * 0.34 + float(index % 2) * 0.16, 0.3 + float(index / 2) * 0.20, footprint_depth * 0.32 + float(index % 2) * 0.16)
		bundle.rotation_degrees.z = -18.0 + float(index) * 9.0
		delivered_fiber.add_child(bundle)
	structure.add_child(delivered_fiber)
	var additive_components := Node3D.new()
	additive_components.name = "AdditiveConstructionComponents"
	additive_components.visible = false
	for component_value in SanctuaryAssetCatalog.structure_definition(kind).get("construction_components", []):
		if not (component_value is Dictionary):
			continue
		var component := component_value as Dictionary
		var component_node := Node3D.new()
		var component_id := str(component.get("id", "component"))
		component_node.name = "ConstructionPart_%s" % component_id
		component_node.set_meta("component_id", component_id)
		component_node.set_meta("asset_id", str(component.get("asset_id", "")))
		component_node.set_meta("phase", str(component.get("phase", "")))
		component_node.set_meta("material", str(component.get("material", "")))
		var component_size: Array = component.get("size", [0.5, 0.5, 0.5])
		var component_center: Array = component.get("center", [0.0, 0.0, 0.0])
		component_node.position = Vector3(float(component_center[0]), float(component_center[1]), float(component_center[2]))
		_populate_construction_component(component_node, kind, component_id, str(component.get("phase", "")), Vector3(float(component_size[0]), float(component_size[1]), float(component_size[2])), _construction_material_color(str(component.get("material", "wood"))))
		additive_components.add_child(component_node)
	structure.add_child(additive_components)
	var tank := MeshInstance3D.new()
	tank.name = "CisternTank"
	tank.mesh = _sphere_mesh(0.62, 1.1, 10, 6)
	tank.material_override = _material(palette["water"], 0.32, false, true)
	tank.position.y = 0.68
	structure.add_child(tank)
	var roof := MeshInstance3D.new()
	roof.name = "CisternRoof"
	var roof_mesh := PrismMesh.new()
	roof_mesh.size = Vector3(footprint_width + 0.2, 0.22, footprint_depth + 0.2)
	roof.mesh = roof_mesh
	roof.material_override = _material(_structure_roof_color(kind), 0.86)
	roof.position.y = structure_height + 0.28
	structure.add_child(roof)
	var gabled_roof := Node3D.new()
	gabled_roof.name = "GabledRoof"
	gabled_roof.visible = false
	structure.add_child(gabled_roof)
	if kind in ["workshop", "storage_shed", "archive"]:
		var roof_panel_size := Vector3(footprint_width + 0.28, 0.16, footprint_depth * 0.60)
		var roof_y := structure_height + 0.48
		_structure_box(gabled_roof, "RoofPanelLeft", roof_panel_size, Vector3(0.0, roof_y, -footprint_depth * 0.22), _structure_roof_color(kind), Vector3(-27.0, 0.0, 0.0))
		_structure_box(gabled_roof, "RoofPanelRight", roof_panel_size, Vector3(0.0, roof_y, footprint_depth * 0.22), _structure_roof_color(kind), Vector3(27.0, 0.0, 0.0))
		_structure_box(gabled_roof, "RoofRidge", Vector3(footprint_width + 0.34, 0.18, 0.20), Vector3(0.0, structure_height + 0.82, 0.0), palette["wood_dark"])
	var construction_roof := Node3D.new()
	construction_roof.name = "ConstructionRoof"
	construction_roof.visible = false
	structure.add_child(construction_roof)
	if kind in ["workshop", "storage_shed", "archive"]:
		_structure_box(construction_roof, "ConstructionRoofPanel", Vector3(footprint_width + 0.18, 0.13, footprint_depth * 0.52), Vector3(0.0, structure_height + 0.38, 0.0), _structure_roof_color(kind), Vector3(-8.0, 0.0, 0.0))
	var timber_frame := Node3D.new()
	timber_frame.name = "TimberFrame"
	timber_frame.visible = false
	structure.add_child(timber_frame)
	if kind in ["workshop", "storage_shed", "archive"]:
		for corner in [-1.0, 1.0]:
			_structure_box(timber_frame, "FrontPost_%s" % corner, Vector3(0.14, structure_height, 0.14), Vector3(corner * footprint_width * 0.40, 0.11 + structure_height * 0.5, footprint_depth * 0.43), palette["wood_dark"])
			_structure_box(timber_frame, "BackPost_%s" % corner, Vector3(0.14, structure_height, 0.14), Vector3(corner * footprint_width * 0.40, 0.11 + structure_height * 0.5, -footprint_depth * 0.43), palette["wood_dark"])
		_structure_box(timber_frame, "FrontBeam", Vector3(footprint_width * 0.82, 0.14, 0.14), Vector3(0.0, 0.11 + structure_height * 0.88, footprint_depth * 0.43), palette["wood_dark"])
	var label := _label3d(_structure_display_name(kind).to_upper(), 0.17, palette["cream"])
	label.name = "StructureLabel"
	label.position.y = structure_height + (0.92 if kind == "workshop" else 0.68)
	structure.add_child(label)
	var finished_walls := Node3D.new()
	finished_walls.name = "FinishedWalls"
	var wall_color := _structure_wall_color(kind)
	for wall_data in [
		[Vector3(0.0, 0.11 + structure_height * 0.5, -footprint_depth * 0.46), Vector3(footprint_width * 0.86, structure_height, 0.12)],
		[Vector3(-footprint_width * 0.43, 0.11 + structure_height * 0.5, 0.0), Vector3(0.12, structure_height, footprint_depth * 0.86)],
		[Vector3(footprint_width * 0.43, 0.11 + structure_height * 0.5, 0.0), Vector3(0.12, structure_height, footprint_depth * 0.86)],
	]:
		var wall := MeshInstance3D.new()
		var wall_mesh := BoxMesh.new()
		wall_mesh.size = wall_data[1]
		wall.mesh = wall_mesh
		wall.material_override = _material(wall_color, 0.94)
		wall.position = wall_data[0]
		finished_walls.add_child(wall)
	structure.add_child(finished_walls)
	var construction_walls := Node3D.new()
	construction_walls.name = "ConstructionWalls"
	construction_walls.visible = false
	structure.add_child(construction_walls)
	if kind in ["workshop", "storage_shed", "archive"]:
		_structure_box(construction_walls, "ConstructionWallFront", Vector3(footprint_width * 0.76, structure_height * 0.48, 0.10), Vector3(0.0, 0.11 + structure_height * 0.24, footprint_depth * 0.44), wall_color)
		_structure_box(construction_walls, "ConstructionWallSide", Vector3(0.10, structure_height * 0.72, footprint_depth * 0.66), Vector3(-footprint_width * 0.43, 0.11 + structure_height * 0.36, 0.0), wall_color)
	var finished_source_building := Node3D.new()
	finished_source_building.name = "FinishedSourceBuilding"
	finished_source_building.visible = false
	structure.add_child(finished_source_building)
	if measurement_valid:
		_add_measured_source_scene(finished_source_building, kind, asset_measurement)
	var utility := Node3D.new()
	utility.name = "StructureUtility"
	structure.add_child(utility)
	_create_structure_utility_visual(utility, kind, footprint_width, footprint_depth, structure_height)
	var body := StaticBody3D.new()
	body.name = "StructureCollisionBody"
	body.set_meta("collision_profile_id", str(SanctuaryAssetCatalog.structure_definition(kind).get("collision_profile_id", "")))
	for component_value in compound_components:
		if not (component_value is Dictionary):
			continue
		var component := component_value as Dictionary
		var component_shape := CollisionShape3D.new()
		var component_id := str(component.get("id", "component"))
		component_shape.name = "Compound_%s" % component_id
		component_shape.set_meta("component_id", component_id)
		component_shape.set_meta("asset_id", str(component.get("asset_id", "")))
		component_shape.set_meta("measurement_source", str(component.get("measurement_source", "")))
		component_shape.set_meta("blocks_movement", bool(component.get("blocks_movement", true)))
		var shape_kind := str(component.get("shape", "box"))
		if shape_kind == "cylinder":
			var cylinder_shape := CylinderShape3D.new()
			cylinder_shape.radius = float(component.get("radius", 0.5))
			cylinder_shape.height = float(component.get("height", 1.0))
			component_shape.shape = cylinder_shape
		else:
			var box_shape := BoxShape3D.new()
			var component_size: Array = component.get("size", [0.5, 0.5, 0.5])
			box_shape.size = Vector3(float(component_size[0]), float(component_size[1]), float(component_size[2]))
			component_shape.shape = box_shape
		var component_center: Array = component.get("center", [0.0, 0.0, 0.0])
		component_shape.position = Vector3(float(component_center[0]), float(component_center[1]), float(component_center[2]))
		body.add_child(component_shape)
	# Collision components are authored in canonical local metres and the root
	# owns quarter-turn rotation. The old implementation rescaled the body from
	# the rotated world footprint, which double-swapped non-square buildings at
	# 90°/270° and left the actual component walls smaller than the art. Keep the
	# component envelope at authored size; root rotation supplies the world swap.
	body.scale = Vector3.ONE
	structure.set_meta("collision_fit_scale", [body.scale.x, body.scale.y, body.scale.z])
	structure.set_meta("compound_collision_component_count", body.get_child_count())
	structure.set_meta("local_collision_footprint", [local_collision_size.x, local_collision_size.z])
	structure.add_child(body)
	settlement_visuals[instance_id] = structure
	_refresh_structure_visual(instance_id, data)

func _structure_base_color(kind: String) -> Color:
	match kind:
		"workshop": return Color("#737d78")
		"storage_shed": return Color("#9d9b83")
	return palette["stone"]

func _construction_material_color(material_id: String) -> Color:
	match material_id:
		"stone": return Color("#84939a")
		"plank": return Color("#d3a36b")
		"fiber": return Color("#c7b86b")
	return Color("#a66b45")

func _populate_construction_component(parent: Node3D, kind: String, component_id: String, phase: String, size: Vector3, color: Color) -> void:
	# Construction components are intentionally authored as readable pieces, not
	# opaque proxy volumes. Their metadata remains one component per required
	# asset, while the child meshes show how a player actually assembles it.
	var width := maxf(size.x, 0.24)
	var height := maxf(size.y, 0.16)
	var depth := maxf(size.z, 0.24)
	var dark := color.darkened(0.24)
	match phase:
		"foundation":
			_structure_box(parent, "FoundationPad", Vector3(width, minf(height, 0.16), depth), Vector3.ZERO, color)
			for corner in [Vector3(-width * 0.38, 0.12, -depth * 0.38), Vector3(width * 0.38, 0.12, -depth * 0.38), Vector3(-width * 0.38, 0.12, depth * 0.38), Vector3(width * 0.38, 0.12, depth * 0.38)]:
				_structure_box(parent, "FoundationMarker", Vector3(0.16, 0.08, 0.16), corner, dark)
		"frame":
			var post_height := maxf(height * 0.90, 0.72)
			var post_size := Vector3(0.14, post_height, 0.14)
			for corner in [Vector3(-width * 0.40, post_height * 0.5, -depth * 0.40), Vector3(width * 0.40, post_height * 0.5, -depth * 0.40), Vector3(-width * 0.40, post_height * 0.5, depth * 0.40), Vector3(width * 0.40, post_height * 0.5, depth * 0.40)]:
				_structure_box(parent, "FramePost", post_size, corner, dark)
			_structure_box(parent, "FrameBeamFront", Vector3(width * 0.84, 0.14, 0.14), Vector3(0.0, post_height * 0.86, depth * 0.40), color)
			_structure_box(parent, "FrameBeamBack", Vector3(width * 0.84, 0.14, 0.14), Vector3(0.0, post_height * 0.86, -depth * 0.40), color)
			_structure_box(parent, "FrameBeamLeft", Vector3(0.14, 0.14, depth * 0.80), Vector3(-width * 0.40, post_height * 0.86, 0.0), color)
			_structure_box(parent, "FrameBeamRight", Vector3(0.14, 0.14, depth * 0.80), Vector3(width * 0.40, post_height * 0.86, 0.0), color)
		"walls":
			var wall_height := maxf(height * 0.80, 0.58)
			var wall_y := wall_height * 0.5
			var panel_thickness := 0.10
			_structure_box(parent, "WallPanelBack", Vector3(width * 0.84, wall_height, panel_thickness), Vector3(0.0, wall_y, -depth * 0.42), color)
			_structure_box(parent, "WallPanelLeft", Vector3(panel_thickness, wall_height, depth * 0.76), Vector3(-width * 0.42, wall_y, 0.0), color)
			_structure_box(parent, "WallPanelRight", Vector3(panel_thickness, wall_height, depth * 0.76), Vector3(width * 0.42, wall_y, 0.0), color)
			var opening_width := minf(width * 0.28, 0.80)
			var side_panel_width := maxf((width * 0.84 - opening_width) * 0.5, 0.18)
			_structure_box(parent, "WallPanelFrontLeft", Vector3(side_panel_width, wall_height, panel_thickness), Vector3(-(opening_width + side_panel_width) * 0.5, wall_y, depth * 0.42), color)
			_structure_box(parent, "WallPanelFrontRight", Vector3(side_panel_width, wall_height, panel_thickness), Vector3((opening_width + side_panel_width) * 0.5, wall_y, depth * 0.42), color)
		"roof":
			var roof_half_depth := depth * 0.30
			_structure_box(parent, "RoofSectionLeft", Vector3(width * 0.90, 0.14, roof_half_depth), Vector3(0.0, height * 0.72, -depth * 0.18), color, Vector3(-24.0, 0.0, 0.0))
			_structure_box(parent, "RoofSectionRight", Vector3(width * 0.90, 0.14, roof_half_depth), Vector3(0.0, height * 0.72, depth * 0.18), color, Vector3(24.0, 0.0, 0.0))
			_structure_box(parent, "RoofRidge", Vector3(width * 0.92, 0.12, 0.14), Vector3(0.0, height * 0.92, 0.0), dark)
		"fittings":
			_structure_box(parent, "FittingBench", Vector3(minf(width * 0.34, 0.76), 0.16, minf(depth * 0.28, 0.62)), Vector3(0.0, height * 0.28, depth * 0.18), color)
			_structure_box(parent, "FittingPost", Vector3(0.12, maxf(height * 0.46, 0.42), 0.12), Vector3(0.0, height * 0.48, depth * 0.18), dark)
			if "cistern" in component_id or "pump" in component_id:
				_structure_cylinder(parent, "FittingPump", 0.12, maxf(height * 0.58, 0.46), Vector3(0.28, height * 0.34, 0.24), color)
			else:
				_structure_box(parent, "FittingCrate", Vector3(0.28, 0.24, 0.28), Vector3(0.32, height * 0.20, 0.18), dark)

func _add_measured_source_scene(parent: Node3D, kind: String, measurement: Dictionary) -> Node3D:
	if parent == null or not bool(measurement.get("valid", false)):
		return null
	var scene_path := str(measurement.get("source_path", ""))
	var scene := load(scene_path) as PackedScene
	if scene == null:
		return null
	var instance := scene.instantiate() as Node3D
	if instance == null:
		return null
	instance.name = "ImportedBuilding"
	instance.scale = Vector3.ONE * float(measurement.get("fit_scale", 1.0))
	instance.position = measurement.get("fit_offset", Vector3.ZERO)
	instance.set_meta("source_asset", scene_path)
	instance.set_meta("structure_kind", kind)
	instance.set_meta("measurement_source", "imported_mesh_bounds")
	instance.set_meta("measured_bounds", measurement.get("fitted_bounds", AABB()))
	parent.add_child(instance)
	return instance

func _structure_wall_color(kind: String) -> Color:
	match kind:
		"archive": return palette["stone"]
		"workshop": return Color("#745846")
		"storage_shed": return Color("#b18052")
	return palette["wood"]

func _structure_roof_color(kind: String) -> Color:
	match kind:
		"workshop": return Color("#456b69")
		"storage_shed": return Color("#788452")
		"archive": return Color("#6c7772")
	return palette["wood"]

func _structure_box(parent: Node3D, node_name: String, size: Vector3, local_position: Vector3, color: Color, local_rotation_degrees := Vector3.ZERO, emissive := false) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = _material(color, 0.9, false, emissive)
	mesh_instance.position = local_position
	mesh_instance.rotation_degrees = local_rotation_degrees
	parent.add_child(mesh_instance)
	return mesh_instance

func _structure_cylinder(parent: Node3D, node_name: String, radius: float, height: float, local_position: Vector3, color: Color, radial_segments := 8) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var cylinder_mesh := CylinderMesh.new()
	cylinder_mesh.top_radius = radius
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.height = height
	cylinder_mesh.radial_segments = radial_segments
	mesh_instance.mesh = cylinder_mesh
	mesh_instance.material_override = _material(color, 0.88)
	mesh_instance.position = local_position
	parent.add_child(mesh_instance)
	return mesh_instance

func _create_structure_utility_visual(parent: Node3D, kind: String, width: float, depth: float, height: float) -> void:
	match kind:
		"workshop":
			_create_player_workshop_visual(parent, width, depth, height)
		"archive":
			for side in [-1.0, 1.0]:
				var shelf := MeshInstance3D.new()
				var shelf_mesh := BoxMesh.new()
				shelf_mesh.size = Vector3(0.22, 1.15, depth * 0.68)
				shelf.mesh = shelf_mesh
				shelf.material_override = _material(palette["wood_dark"], 0.96)
				shelf.position = Vector3(side * width * 0.32, 0.72, 0.0)
				parent.add_child(shelf)
			var table := MeshInstance3D.new()
			var table_mesh := BoxMesh.new()
			table_mesh.size = Vector3(width * 0.46, 0.12, depth * 0.35)
			table.mesh = table_mesh
			table.material_override = _material(palette["wood"], 0.92)
			table.position.y = 0.62
			parent.add_child(table)
		"livestock_pen":
			var trough := MeshInstance3D.new()
			var trough_mesh := BoxMesh.new()
			trough_mesh.size = Vector3(width * 0.42, 0.26, 0.42)
			trough.mesh = trough_mesh
			trough.material_override = _material(palette["wood_dark"], 0.96)
			trough.position = Vector3(0.0, 0.34, -depth * 0.18)
			parent.add_child(trough)
		"storage_shed":
			_create_storage_shed_visual(parent, width, depth, height)

func _create_player_workshop_visual(parent: Node3D, width: float, depth: float, height: float) -> void:
	var bench := Node3D.new()
	bench.name = "WorkshopBench"
	parent.add_child(bench)
	_structure_box(bench, "BenchTop", Vector3(width * 0.52, 0.18, 0.56), Vector3(-width * 0.12, 0.68, depth * 0.14), palette["wood_dark"])
	for side in [-1.0, 1.0]:
		_structure_box(bench, "BenchLeg_%s" % str(side), Vector3(0.12, 0.58, 0.12), Vector3(-width * 0.12 + side * width * 0.2, 0.34, depth * 0.14), palette["wood"])

	var anvil := Node3D.new()
	anvil.name = "WorkshopAnvil"
	parent.add_child(anvil)
	var anvil_x := -width * 0.24
	var anvil_z := depth * 0.12
	_structure_box(anvil, "AnvilFoot", Vector3(0.34, 0.12, 0.34), Vector3(anvil_x, 0.32, anvil_z), Color("#4e5a5d"))
	_structure_box(anvil, "AnvilWaist", Vector3(0.20, 0.34, 0.22), Vector3(anvil_x, 0.52, anvil_z), Color("#617074"))
	_structure_box(anvil, "AnvilTop", Vector3(0.58, 0.18, 0.28), Vector3(anvil_x - 0.05, 0.77, anvil_z), Color("#6f8082"))

	var hammer_pivot := Node3D.new()
	hammer_pivot.name = "WorkshopHammerPivot"
	hammer_pivot.position = Vector3(anvil_x + 0.06, 0.82, anvil_z)
	hammer_pivot.rotation_degrees.z = -28.0
	parent.add_child(hammer_pivot)
	_structure_box(hammer_pivot, "HammerHandle", Vector3(0.07, 0.62, 0.07), Vector3(0.0, 0.29, 0.0), Color("#c09158"))
	_structure_box(hammer_pivot, "HammerHead", Vector3(0.38, 0.17, 0.18), Vector3(0.0, 0.62, 0.0), Color("#4a565b"))

	var forge := Node3D.new()
	forge.name = "WorkshopForge"
	parent.add_child(forge)
	var forge_x := width * 0.25
	var forge_z := -depth * 0.15
	_structure_box(forge, "ForgeBody", Vector3(0.82, 0.62, 0.68), Vector3(forge_x, 0.43, forge_z), Color("#59635f"))
	_structure_box(forge, "ForgeRim", Vector3(0.92, 0.14, 0.76), Vector3(forge_x, 0.77, forge_z), Color("#3e4b4b"))
	var forge_glow := MeshInstance3D.new()
	forge_glow.name = "WorkshopForgeGlow"
	forge_glow.mesh = _sphere_mesh(0.22, 0.20, 8, 4)
	forge_glow.material_override = _material(palette["ember"], 0.34, false, true)
	forge_glow.position = Vector3(forge_x, 0.88, forge_z)
	forge.add_child(forge_glow)
	_structure_cylinder(forge, "WorkshopChimney", 0.16, 2.0, Vector3(forge_x + 0.13, 1.78, forge_z - 0.12), Color("#4d5a58"), 8)
	_structure_cylinder(forge, "WorkshopChimneyCap", 0.23, 0.12, Vector3(forge_x + 0.13, 2.82, forge_z - 0.12), Color("#394646"), 8)

	var smoke := Node3D.new()
	smoke.name = "WorkshopSmoke"
	smoke.visible = false
	parent.add_child(smoke)
	for index in 3:
		var puff := MeshInstance3D.new()
		puff.name = "SmokePuff_%d" % index
		puff.mesh = _sphere_mesh(0.18 + float(index) * 0.025, 0.28 + float(index) * 0.04, 7, 4)
		puff.material_override = _material(Color(0.72, 0.78, 0.74, 0.34), 1.0, true)
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var puff_position := Vector3(forge_x + 0.13, 2.96 + float(index) * 0.18, forge_z - 0.12)
		puff.position = puff_position
		puff.set_meta("base_position", puff_position)
		puff.set_meta("phase", float(index) / 3.0)
		smoke.add_child(puff)

	var drive_wheel := MeshInstance3D.new()
	drive_wheel.name = "WorkshopDriveWheel"
	var wheel_mesh := TorusMesh.new()
	wheel_mesh.inner_radius = 0.26
	wheel_mesh.outer_radius = 0.36
	drive_wheel.mesh = wheel_mesh
	drive_wheel.material_override = _material(Color("#d39a54"), 0.78)
	drive_wheel.position = Vector3(width * 0.30, 1.28, depth * 0.34)
	drive_wheel.rotation_degrees.x = 90.0
	parent.add_child(drive_wheel)
	for spoke_rotation in [0.0, 45.0, 90.0, 135.0]:
		_structure_box(drive_wheel, "DriveSpoke_%d" % int(spoke_rotation), Vector3(0.06, 0.62, 0.06), Vector3.ZERO, Color("#d39a54"), Vector3(0.0, 0.0, spoke_rotation))

	var status_lamp := MeshInstance3D.new()
	status_lamp.name = "WorkshopStatusLamp"
	status_lamp.mesh = _sphere_mesh(0.11, 0.19, 7, 4)
	status_lamp.material_override = _material(palette["wood_dark"], 0.82)
	status_lamp.position = Vector3(-width * 0.34, height * 0.72, depth * 0.42)
	parent.add_child(status_lamp)

func _add_storage_crate(parent: Node3D, node_name: String, size: Vector3, local_position: Vector3) -> Node3D:
	var crate := Node3D.new()
	crate.name = node_name
	crate.position = local_position
	parent.add_child(crate)
	_structure_box(crate, "CrateBody", size, Vector3.ZERO, Color("#b9824f"))
	for side in [-1.0, 1.0]:
		_structure_box(crate, "CrateBand_%s" % str(side), Vector3(0.08, size.y * 1.03, size.z * 1.04), Vector3(side * size.x * 0.34, 0.0, 0.0), Color("#6a4a36"))
	_structure_box(crate, "CrateBraceA", Vector3(0.065, size.y * 0.92, 0.05), Vector3(0.0, 0.0, size.z * 0.52), Color("#6a4a36"), Vector3(0.0, 0.0, 36.0))
	_structure_box(crate, "CrateBraceB", Vector3(0.065, size.y * 0.92, 0.05), Vector3(0.0, 0.0, size.z * 0.52), Color("#6a4a36"), Vector3(0.0, 0.0, -36.0))
	return crate

func _create_storage_shed_visual(parent: Node3D, width: float, depth: float, height: float) -> void:
	var cargo := Node3D.new()
	cargo.name = "StorageCargo"
	parent.add_child(cargo)
	_add_storage_crate(cargo, "LargeCrate", Vector3(0.78, 0.58, 0.58), Vector3(-width * 0.21, 0.40, -depth * 0.05))
	_add_storage_crate(cargo, "SmallCrate", Vector3(0.62, 0.46, 0.50), Vector3(width * 0.20, 0.34, depth * 0.05))
	_add_storage_crate(cargo, "TopCrate", Vector3(0.56, 0.42, 0.46), Vector3(-width * 0.21, 0.92, -depth * 0.05))
	_structure_cylinder(cargo, "SupplyBarrel", 0.25, 0.76, Vector3(width * 0.33, 0.49, -depth * 0.22), Color("#8d603d"), 10)
	_structure_box(cargo, "BarrelBandTop", Vector3(0.53, 0.07, 0.53), Vector3(width * 0.33, 0.70, -depth * 0.22), Color("#4d5957"))
	_structure_box(cargo, "BarrelBandBottom", Vector3(0.53, 0.07, 0.53), Vector3(width * 0.33, 0.27, -depth * 0.22), Color("#4d5957"))

	var door := Node3D.new()
	door.name = "StorageDoor"
	parent.add_child(door)
	_structure_box(door, "DoorSlab", Vector3(width * 0.58, height * 0.72, 0.08), Vector3(0.0, height * 0.43, -depth * 0.42), Color("#795239"))
	_structure_box(door, "DoorBraceA", Vector3(0.10, height * 0.64, 0.06), Vector3(0.0, height * 0.43, -depth * 0.36), Color("#c0925b"), Vector3(0.0, 0.0, 42.0))
	_structure_box(door, "DoorBraceB", Vector3(0.10, height * 0.64, 0.06), Vector3(0.0, height * 0.43, -depth * 0.36), Color("#c0925b"), Vector3(0.0, 0.0, -42.0))

	var loading_frame := Node3D.new()
	loading_frame.name = "StorageLoadingFrame"
	parent.add_child(loading_frame)
	var loading_z := depth * 0.43
	for side in [-1.0, 1.0]:
		_structure_box(loading_frame, "LoadingPost_%s" % str(side), Vector3(0.13, height * 0.86, 0.13), Vector3(side * width * 0.35, height * 0.48, loading_z), palette["wood_dark"])
	_structure_box(loading_frame, "LoadingBeam", Vector3(width * 0.82, 0.16, 0.16), Vector3(0.0, height * 0.91, loading_z), palette["wood_dark"])
	var awning := MeshInstance3D.new()
	awning.name = "StorageAwning"
	var awning_mesh := PrismMesh.new()
	awning_mesh.size = Vector3(width * 0.88, 0.42, depth * 0.56)
	awning.mesh = awning_mesh
	awning.material_override = _material(Color("#98a76b"), 0.88)
	awning.position = Vector3(0.0, height + 0.02, loading_z - depth * 0.04)
	loading_frame.add_child(awning)

	var pulley := MeshInstance3D.new()
	pulley.name = "StoragePulleyWheel"
	var pulley_mesh := TorusMesh.new()
	pulley_mesh.inner_radius = 0.15
	pulley_mesh.outer_radius = 0.23
	pulley.mesh = pulley_mesh
	pulley.material_override = _material(Color("#d4ad67"), 0.74)
	pulley.position = Vector3(0.0, height * 0.84, loading_z + 0.08)
	pulley.rotation_degrees.x = 90.0
	loading_frame.add_child(pulley)
	for spoke_rotation in [0.0, 60.0, 120.0]:
		_structure_box(pulley, "PulleySpoke_%d" % int(spoke_rotation), Vector3(0.045, 0.36, 0.045), Vector3.ZERO, Color("#d4ad67"), Vector3(0.0, 0.0, spoke_rotation))

	_structure_cylinder(loading_frame, "StoragePulleyRope", 0.018, height * 0.48, Vector3(0.0, height * 0.56, loading_z + 0.08), Color("#d7c69b"), 5)
	var cargo_sack := MeshInstance3D.new()
	cargo_sack.name = "StorageCargoSack"
	cargo_sack.mesh = _sphere_mesh(0.20, 0.44, 8, 5)
	cargo_sack.material_override = _material(Color("#d8bd80"), 0.96)
	var sack_position := Vector3(0.0, height * 0.27, loading_z + 0.08)
	cargo_sack.position = sack_position
	cargo_sack.set_meta("base_position", sack_position)
	loading_frame.add_child(cargo_sack)

	var lantern := MeshInstance3D.new()
	lantern.name = "StorageLanternGlow"
	lantern.mesh = _sphere_mesh(0.10, 0.24, 7, 4)
	lantern.material_override = _material(Color("#ffd27a"), 0.32, false, true)
	lantern.position = Vector3(width * 0.31, height * 0.72, loading_z + 0.10)
	loading_frame.add_child(lantern)

func _workshop_job_phase() -> String:
	if session == null:
		return "idle"
	var job_value: Variant = session.get("station_job")
	if not (job_value is Dictionary):
		return "idle"
	var job: Dictionary = job_value
	if str(job.get("kind", "none")) == "none":
		return "idle"
	return "working" if float(job.get("remaining_hours", 0.0)) > 0.0 else "ready"

func _operational_structure_label(kind: String, display_name: String, definition: Dictionary) -> String:
	match kind:
		"workshop":
			match _workshop_job_phase():
				"working":
					var job: Dictionary = session.get("station_job")
					return "%s\nWORKING %dh" % [display_name, int(ceil(float(job.get("remaining_hours", 0.0))))]
				"ready": return "%s\nORDER READY" % display_name
			return "%s\nTOOLS READY" % display_name
		"storage_shed":
			return "%s\nSATCHEL +%d" % [display_name, int(definition.get("cargo_bonus", 0))]
	return "%s\nOPERATIONAL" % display_name

func _update_player_structure_motion(delta: float) -> void:
	var now := Time.get_ticks_msec() * 0.001
	var workshop_phase := _workshop_job_phase()
	for instance_id in settlement_visuals:
		var structure: Node3D = settlement_visuals.get(instance_id)
		if not is_instance_valid(structure) or not structure.is_visible_in_tree() or not bool(structure.get_meta("operational", false)):
			continue
		match str(structure.get_meta("structure_kind", "")):
			"workshop":
				var working := workshop_phase == "working"
				var hammer := structure.get_node_or_null("StructureUtility/WorkshopHammerPivot") as Node3D
				if hammer != null:
					hammer.rotation.z = deg_to_rad(-28.0 + sin(now * 5.4) * 24.0) if working else lerpf(hammer.rotation.z, deg_to_rad(-28.0), minf(1.0, delta * 7.0))
				var drive_wheel := structure.get_node_or_null("StructureUtility/WorkshopDriveWheel") as MeshInstance3D
				if drive_wheel != null and working:
					drive_wheel.rotation.z = fmod(drive_wheel.rotation.z + delta * 3.4, TAU)
				var forge_glow := structure.get_node_or_null("StructureUtility/WorkshopForge/WorkshopForgeGlow") as MeshInstance3D
				if forge_glow != null:
					var glow_scale := 1.0 + sin(now * (5.8 if working else 2.2)) * (0.10 if working else 0.035)
					forge_glow.scale = Vector3.ONE * glow_scale
				var smoke := structure.get_node_or_null("StructureUtility/WorkshopSmoke") as Node3D
				if smoke != null:
					smoke.visible = working
					if working:
						for puff_node in smoke.get_children():
							var puff := puff_node as MeshInstance3D
							if puff == null:
								continue
							var phase_offset := float(puff.get_meta("phase", 0.0))
							var travel := fmod(now * 0.34 + phase_offset, 1.0)
							var base_position: Vector3 = puff.get_meta("base_position", puff.position)
							puff.position = base_position + Vector3(sin(now * 1.7 + phase_offset * TAU) * 0.09, travel * 0.72, cos(now * 1.3 + phase_offset * TAU) * 0.04)
							puff.scale = Vector3.ONE * (0.68 + travel * 0.52)
			"storage_shed":
				var pulley := structure.get_node_or_null("StructureUtility/StorageLoadingFrame/StoragePulleyWheel") as MeshInstance3D
				if pulley != null:
					pulley.rotation.z = fmod(pulley.rotation.z + delta * 1.15, TAU)
				var sack := structure.get_node_or_null("StructureUtility/StorageLoadingFrame/StorageCargoSack") as MeshInstance3D
				if sack != null:
					var sack_base: Vector3 = sack.get_meta("base_position", sack.position)
					sack.position = sack_base + Vector3(0.0, sin(now * 1.15) * 0.055, 0.0)
					sack.rotation.z = sin(now * 0.78) * 0.035
				var lantern := structure.get_node_or_null("StructureUtility/StorageLoadingFrame/StorageLanternGlow") as MeshInstance3D
				if lantern != null:
					lantern.scale = Vector3.ONE * (1.0 + sin(now * 2.1) * 0.055)

func _refresh_structure_visual(instance_id: String, data: Dictionary) -> void:
	var structure: Node3D = settlement_visuals.get(instance_id)
	if not is_instance_valid(structure):
		return
	var kind := str(data.get("kind", "rain_cistern"))
	var display_name := _structure_display_name(kind).to_upper()
	var state := str(data.get("state", "building"))
	var definition := ContentRegistry.structure_definition(kind)
	# A generated directional family is the sole operational silhouette. Keep
	# gameplay utility roots alive, but never let their legacy walls/roofs become
	# a second visible building after a save refresh.
	var generated_operational_presentation := state == "operational" \
		and str(definition.get("operational_art_mode", "")) == "illustrated_2_5d" \
		and not SanctuaryAssetCatalog.structure_directional_variant(kind, 0).is_empty()
	var cost: Dictionary = definition.get("cost", {})
	var delivered: Dictionary = data.get("delivered_materials", {})
	var wood_delivered := int(delivered.get("wood", 0))
	var plank_delivered := int(delivered.get("plank", 0))
	var label := structure.get_node_or_null("StructureLabel") as Label3D
	if label != null:
		if state == "operational":
			label.text = _operational_structure_label(kind, display_name, definition)
		elif state == "building":
			label.text = "%s\nFRAME %dh" % [display_name, int(data.get("remaining_hours", 0.0))]
		else:
			var material_parts: Array[String] = []
			for material_id in cost:
				material_parts.append("%s %d/%d" % [str(material_id).to_upper(), int(delivered.get(str(material_id), 0)), int(cost[material_id])])
			label.text = "%s BLUEPRINT\n%s" % [display_name, "  ".join(material_parts)]
	var tank := structure.get_node_or_null("CisternTank") as MeshInstance3D
	if tank != null:
		tank.visible = kind == "rain_cistern" and state == "operational"
	var roof := structure.get_node_or_null("CisternRoof") as MeshInstance3D
	if roof != null:
		roof.visible = state == "operational" and not kind in ["workshop", "storage_shed", "archive"]
	var gabled_roof := structure.get_node_or_null("GabledRoof") as Node3D
	if gabled_roof != null:
		gabled_roof.visible = state == "operational" and kind in ["workshop", "storage_shed", "archive"] and not generated_operational_presentation
	var timber_frame := structure.get_node_or_null("TimberFrame") as Node3D
	if timber_frame != null:
		timber_frame.visible = state == "operational" and kind in ["workshop", "storage_shed", "archive"] and not generated_operational_presentation
	var utility := structure.get_node_or_null("StructureUtility") as Node3D
	if utility != null:
		utility.visible = kind != "rain_cistern" and state == "operational"
	structure.set_meta("operational", state == "operational")
	var workshop_smoke := structure.get_node_or_null("StructureUtility/WorkshopSmoke") as Node3D
	if workshop_smoke != null:
		workshop_smoke.visible = state == "operational" and _workshop_job_phase() == "working"
	var workshop_status_lamp := structure.get_node_or_null("StructureUtility/WorkshopStatusLamp") as MeshInstance3D
	if workshop_status_lamp != null:
		var workshop_phase := _workshop_job_phase()
		var lamp_color: Color = palette["wood_dark"]
		if workshop_phase == "working":
			lamp_color = palette["ember"]
		elif workshop_phase == "ready":
			lamp_color = palette["leaf"]
		workshop_status_lamp.material_override = _material(lamp_color, 0.45, false, workshop_phase != "idle")
	var finished_walls := structure.get_node_or_null("FinishedWalls") as Node3D
	var finished_source_building := structure.get_node_or_null("FinishedSourceBuilding") as Node3D
	var has_finished_source := finished_source_building != null and finished_source_building.get_child_count() > 0
	if finished_source_building != null:
		finished_source_building.visible = state == "operational" and has_finished_source and not generated_operational_presentation
	if finished_walls != null:
		finished_walls.visible = state == "operational" and not has_finished_source and not generated_operational_presentation
	var blueprint_stakes := structure.get_node_or_null("BlueprintStakes") as Node3D
	if blueprint_stakes != null:
		blueprint_stakes.visible = state == "blueprint"
	var construction_walls := structure.get_node_or_null("ConstructionWalls") as Node3D
	if construction_walls != null:
		construction_walls.visible = false
	var construction_roof := structure.get_node_or_null("ConstructionRoof") as Node3D
	if construction_roof != null:
		construction_roof.visible = false
	var additive_components := structure.get_node_or_null("AdditiveConstructionComponents") as Node3D
	if additive_components != null:
		additive_components.visible = state == "building"
		if state != "building":
			for component_node in additive_components.get_children():
				var component := component_node as Node3D
				if component != null:
					component.visible = false
	var scaffold := structure.get_node_or_null("ScaffoldFrame") as Node3D
	if scaffold != null:
		scaffold.visible = state == "building" or (state == "blueprint" and wood_delivered > 0)
		var total_materials := 0
		var delivered_total := 0
		for material_id in cost:
			total_materials += int(cost[material_id])
			delivered_total += int(delivered.get(str(material_id), 0))
		var material_progress := float(delivered_total) / float(maxi(1, total_materials))
		if state == "building":
			var time_progress := 1.0 - clampf(float(data.get("remaining_hours", 0.0)) / maxf(1.0, float(data.get("total_hours", 24.0))), 0.0, 1.0)
			# A stage can advance only as far as both the elapsed build time and
			# delivered materials allow. This keeps an early scaffold readable even
			# when the player front-loads every required resource.
			material_progress = minf(material_progress, time_progress)
		var scaffold_beams := structure.get_node_or_null("ScaffoldFrame/ScaffoldBeams") as Node3D
		if scaffold_beams != null:
			scaffold_beams.visible = state == "building" and material_progress >= 0.34
		if construction_walls != null:
			construction_walls.visible = state == "building" and material_progress >= 0.50
		if construction_roof != null:
			construction_roof.visible = state == "building" and material_progress >= 0.76
		if additive_components != null:
			additive_components.visible = state == "building"
			var phase_thresholds := {"foundation": 0.0, "frame": 0.18, "walls": 0.50, "roof": 0.76, "fittings": 0.92}
			for component_node in additive_components.get_children():
				var component := component_node as Node3D
				if component == null:
					continue
				var phase := str(component.get_meta("phase", "foundation"))
				component.visible = state == "building" and material_progress >= float(phase_thresholds.get(phase, 1.0))
		for index in mini(scaffold.get_child_count(), 4):
			var post := scaffold.get_child(index) as Node3D
			if post != null:
				post.visible = (state == "building" and (index == 0 or material_progress >= 0.18 + float(index) * 0.18)) or (state == "blueprint" and wood_delivered > 0 and index == 0)
	var delivered_logs := structure.get_node_or_null("DeliveredLogs") as Node3D
	if delivered_logs != null:
		delivered_logs.visible = state != "operational" and wood_delivered > 0
		delivered_logs.scale = Vector3.ONE * (0.55 + clampf(float(wood_delivered) / float(maxi(1, int(cost.get("wood", 1)))), 0.0, 1.0) * 0.45)
	var delivered_planks := structure.get_node_or_null("DeliveredPlanks") as Node3D
	if delivered_planks != null:
		delivered_planks.visible = state != "operational" and plank_delivered > 0
		delivered_planks.scale = Vector3.ONE * (0.55 + clampf(float(plank_delivered) / float(maxi(1, int(cost.get("plank", 1)))), 0.0, 1.0) * 0.45)
	var delivered_stone := structure.get_node_or_null("DeliveredStone") as Node3D
	if delivered_stone != null:
		var stone_delivered := int(delivered.get("stone", 0))
		delivered_stone.visible = state != "operational" and stone_delivered > 0
		delivered_stone.scale = Vector3.ONE * (0.55 + clampf(float(stone_delivered) / float(maxi(1, int(cost.get("stone", 1)))), 0.0, 1.0) * 0.45)
	var delivered_fiber := structure.get_node_or_null("DeliveredFiber") as Node3D
	if delivered_fiber != null:
		var fiber_delivered := int(delivered.get("fiber", 0))
		delivered_fiber.visible = state != "operational" and fiber_delivered > 0
		delivered_fiber.scale = Vector3.ONE * (0.55 + clampf(float(fiber_delivered) / float(maxi(1, int(cost.get("fiber", 1)))), 0.0, 1.0) * 0.45)
	var base := structure.get_node_or_null("CisternBase") as MeshInstance3D
	if base != null:
		base.material_override = _material(_structure_base_color(kind) if state != "blueprint" else palette["violet"], 0.96 if state != "blueprint" else 0.48, state == "blueprint", state == "blueprint")
	if sanctuary_style != null and sanctuary_style.has_method("apply_structure_visual"):
		sanctuary_style.call("apply_structure_visual", structure, kind, state, data)

func _refresh_structure_visuals() -> void:
	if session == null:
		return
	for instance_id in session.get("structures"):
		_refresh_structure_visual(str(instance_id), session.get("structures").get(instance_id, {}))

func _restore_structures() -> void:
	if session == null:
		return
	for instance_id in session.get("structures"):
		_spawn_structure_visual(str(instance_id), session.get("structures").get(instance_id, {}))

func _enter_forest() -> void:
	selected_expedition = "Whisperwood"
	_enter_selected_expedition()

func _cycle_expedition() -> void:
	if current_zone != "Sanctuary":
		return
	var destinations: Array = ContentRegistry.EXPEDITIONS.keys()
	var index := destinations.find(selected_expedition)
	selected_expedition = destinations[(index + 1) % destinations.size()]
	var entry_cost := ContentRegistry.expedition_entry_coins(selected_expedition)
	var coin_text := "  |  Entry %d coins" % entry_cost if entry_cost > 0 else ""
	_show_toast("Destination set: %s  |  Travel cost %d energy%s" % [selected_expedition, _expedition_cost(selected_expedition), coin_text], 2.2)

func _expedition_cost(destination: String) -> int:
	return ContentRegistry.expedition_cost(destination)

func _nearest_route_gate() -> Node:
	var nearest: Node = null
	var nearest_distance := _interaction_range()
	for candidate in get_tree().get_nodes_in_group("route_gate"):
		if not is_instance_valid(candidate) or not candidate.is_visible_in_tree():
			continue
		var gate := candidate as Node3D
		if gate == null or player == null:
			continue
		var distance := _interaction_distance(gate)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest

func _route_gate_interact(station: Node) -> void:
	if current_zone != "Sanctuary" or station == null:
		return
	if player == null or _interaction_distance(station as Node3D) > _interaction_range():
		_show_toast("Walk up to the route gate before leaving the Sanctuary.", 2.2)
		return
	_enter_selected_expedition(station)

func _enter_selected_expedition(route_gate: Node = null) -> void:
	if get_tree().paused or current_zone != "Sanctuary":
		return
	var gate := route_gate if route_gate != null else _nearest_route_gate()
	if gate == null or not gate.has_meta("destination_id"):
		_show_toast("Choose a destination by walking to one of the five route gates.", 2.8)
		return
	selected_expedition = str(gate.get_meta("destination_id"))
	if session == null or not session.has_method("route_is_unlocked") or not bool(session.call("route_is_unlocked", selected_expedition)):
		var requirement := str(session.call("route_unlock_requirement", selected_expedition)) if session != null and session.has_method("route_unlock_requirement") else "Complete the previous route first."
		_show_toast("%s is locked. %s" % [selected_expedition, requirement], 3.2)
		return
	var before_start: Dictionary = session.call("snapshot_state") if session != null and session.has_method("snapshot_state") else {}
	if session == null or not session.call("start_expedition", selected_expedition):
		var entry_cost := ContentRegistry.expedition_entry_coins(selected_expedition)
		_show_toast("You need %d coins and enough energy for this route. Rest or trade before leaving." % entry_cost if entry_cost > 0 else "You need a full breath before another expedition. Rest at the Hearth.", 2.8)
		return
	expedition_loot = {}
	_set_zone(selected_expedition)
	_restore_active_expedition_nodes()
	_sync_expedition_anchor()
	if not bool(session.call("save_game")):
		if not before_start.is_empty():
			session.call("restore_state", before_start)
		_set_zone("Sanctuary")
		_copy_session_to_runtime()
		_show_toast("The route could not be secured to disk. You remain at the Sanctuary gate.", 3.0)
		return
	var flavor: String = "%s  |  %s" % [selected_expedition, str(ContentRegistry.EXPEDITIONS.get(selected_expedition, {}).get("summary", "The road opens."))]
	_show_toast(flavor, 3.0)

func _return_home() -> void:
	if get_tree().paused or current_zone == "Sanctuary":
		return
	var extraction_point := Vector3(0.0, 1.0, 7.5)
	if player == null or _ground_distance(player.global_position, extraction_point) > 2.8:
		_show_toast("Reach the expedition beacon before extracting your cargo.", 2.5)
		return
	if session != null and session.has_method("expedition_return_checkpoint_required") and bool(session.call("expedition_return_checkpoint_required")):
		var return_landmark_label := "Return Footbridge" if current_zone == "Whisperwood" else "Return Causeway"
		_show_toast("Cross the %s before the beacon. The shortcut is open, but the route is not yet safe." % return_landmark_label, 3.0)
		return
	_sync_expedition_anchor()
	var before_extract: Dictionary = session.call("snapshot_state") if session != null and session.has_method("snapshot_state") else {}
	_sync_expedition_anchor()
	var stranded_pickups := 0
	if session != null and session.has_method("finish_expedition"):
		var active_run_before_finish: Dictionary = session.get("expedition_run") if session.get("expedition_run") is Dictionary else {}
		var pending_drops: Variant = active_run_before_finish.get("pickups", [])
		if pending_drops is Array:
			for pending_drop in pending_drops:
				if pending_drop is Dictionary and int(pending_drop.get("amount", 0)) > 0:
					stranded_pickups += 1
		var extracted_cargo: Dictionary = session.call("finish_expedition", current_zone, [player.global_position.x, player.global_position.y, player.global_position.z])
		if extracted_cargo.is_empty() and bool(session.call("has_active_expedition")):
			_show_toast("The beacon did not accept this extraction. Your cargo remains in the run.", 2.8)
			return
		if not bool(session.call("save_game")):
			if not before_extract.is_empty():
				session.call("restore_state", before_extract)
			_copy_session_to_runtime()
			_show_toast("Extraction could not be secured to disk. Your cargo remains in the run.", 3.0)
			return
	_set_zone("Sanctuary")
	_copy_session_to_runtime()
	expedition_loot = {}
	var extraction_message := "The Sanctuary is safe. Expedition cargo is banked."
	if stranded_pickups > 0:
		extraction_message += " %d ground drop%s left behind." % [stranded_pickups, "" if stranded_pickups == 1 else "s"]
	_show_toast(extraction_message, 3.0)

func _set_zone_collisions(root: Node, active: bool) -> void:
	if root == null:
		return
	for child in root.get_children():
		if child is CollisionShape3D and not (child as CollisionShape3D).has_meta("legacy_hidden_collision"):
			child.disabled = not active
		_set_zone_collisions(child, active)

func _set_zone(zone: String) -> void:
	current_zone = zone
	if camera != null:
		# Sanctuary is a planning diorama; expeditions use a tighter 2.5D
		# framing so the player reads the next landmark, not the entire map at
		# once. Movement and camera orientation remain unchanged.
		camera.size = SANCTUARY_CAMERA_SIZE if zone == "Sanctuary" else EXPEDITION_CAMERA_SIZE
	camera_anchor_initialized = false
	if player != null and player.has_method("cancel_navigation"):
		player.call("cancel_navigation", true)
	if move_target_marker != null:
		move_target_marker.visible = false
	for world_zone in world_zones:
		world_zone.visible = world_zone.name == zone.replace(" ", "")
		_set_zone_collisions(world_zone, world_zone.name == zone.replace(" ", ""))
	for resource_node in get_tree().get_nodes_in_group("resource_node"):
		if resource_node.has_method("set_zone_active"):
			resource_node.call("set_zone_active", _zone_for_node(resource_node) == zone.replace(" ", ""))
	for guardian_node in get_tree().get_nodes_in_group("guardian"):
		var guardian := guardian_node as CharacterBody3D
		if guardian != null:
			guardian.call("set_active", _zone_for_node(guardian) == zone.replace(" ", ""))
	if zone == "Sanctuary":
		player.global_position = Vector3(0.0, 1.0, 4.0)
	else:
		player.global_position = Vector3(0.0, 1.0, 7.5)
		if session != null and session.has_method("has_active_expedition") and session.call("has_active_expedition"):
			var anchor = session.get("expedition_run").get("anchor", [])
			if anchor is Array and anchor.size() >= 3:
				player.global_position = Vector3(float(anchor[0]), float(anchor[1]), float(anchor[2]))
	var environment_node := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if environment_node != null:
		environment_node.environment.background_color = _zone_background(zone)
	_sync_expedition_cargo()
	_refresh_whisperwood_route()
	_refresh_expedition_pickups()

func _restore_active_expedition_nodes() -> void:
	if session == null:
		return
	var depleted: Array = []
	var defeated_guardians: Array = []
	var guardian_states: Dictionary = {}
	var expedition_contact_progress: Dictionary = {}
	if session.has_method("has_active_expedition") and session.call("has_active_expedition"):
		var run: Dictionary = session.get("expedition_run")
		depleted = run.get("depleted_ids", [])
		defeated_guardians = run.get("defeated_guardian_ids", [])
		var stored_guardian_states: Variant = run.get("guardian_states", {})
		if stored_guardian_states is Dictionary:
			guardian_states = stored_guardian_states
		var stored_progress: Variant = run.get("contact_progress", {})
		if stored_progress is Dictionary:
			expedition_contact_progress = stored_progress
	var sanctuary_depleted: Array = session.get("sanctuary_depleted_ids") if session.get("sanctuary_depleted_ids") is Array else []
	for resource_node in get_tree().get_nodes_in_group("resource_node"):
		if resource_node.has_method("set_depleted_from_save"):
			var node_id := str(resource_node.get("node_id"))
			var is_sanctuary_node := _zone_for_node(resource_node) == "Sanctuary"
			resource_node.call("set_depleted_from_save", sanctuary_depleted.has(node_id) if is_sanctuary_node else depleted.has(node_id))
			if is_sanctuary_node and resource_node.has_method("set_contact_progress"):
				var sanctuary_contact_progress: Variant = session.get("sanctuary_contact_progress")
				if sanctuary_contact_progress is Dictionary:
					resource_node.call("set_contact_progress", int(sanctuary_contact_progress.get(node_id, 0)))
			elif not is_sanctuary_node and resource_node.has_method("set_contact_progress"):
				resource_node.call("set_contact_progress", int(expedition_contact_progress.get(node_id, 0)))
	for guardian_node in get_tree().get_nodes_in_group("guardian"):
		if guardian_node.has_method("set_defeated_from_save"):
			var guardian_id := str(guardian_node.get("guardian_id"))
			if defeated_guardians.has(guardian_id):
				guardian_node.call("set_defeated_from_save", true)
			elif guardian_states.has(guardian_id) and guardian_node.has_method("restore_from_saved_state"):
				guardian_node.call("restore_from_saved_state", guardian_states[guardian_id])
			else:
				guardian_node.call("set_defeated_from_save", false)
	_refresh_whisperwood_route()
	_refresh_expedition_pickups()

func _clear_expedition_pickup_visuals() -> void:
	for pickup_id in expedition_pickup_visuals:
		var pickup := expedition_pickup_visuals[pickup_id] as Node3D
		if pickup != null and is_instance_valid(pickup):
			pickup.visible = false
			pickup.remove_from_group("interactable")
			pickup.queue_free()
	expedition_pickup_visuals.clear()

func _pickup_material(resource_id: String) -> Color:
	match resource_id:
		"wood": return palette["wood"]
		"stone", "ore": return palette["stone"] if resource_id == "stone" else palette["ember"]
		"fiber": return palette["leaf"]
		"berries": return Color("#b86da9")
		"shell": return Color("#e8c9b2")
		"sunstone": return Color("#f0ba68")
		"relic": return Color("#bda6ff")
	return palette["cream"]

func _spawn_expedition_pickup(data: Dictionary) -> void:
	var pickup_id := str(data.get("pickup_id", ""))
	if pickup_id.is_empty() or expedition_pickup_visuals.has(pickup_id):
		return
	var zone_id := str(session.get("expedition_run").get("biome_id", current_zone)) if session != null else current_zone
	if current_zone != zone_id:
		return
	var parent_zone: Node3D = null
	for candidate in world_zones:
		if candidate.name == zone_id.replace(" ", ""):
			parent_zone = candidate
			break
	if parent_zone == null:
		return
	var position_data: Variant = data.get("position", [0.0, 1.0, 0.0])
	if not (position_data is Array) or position_data.size() < 3:
		return
	var pickup := ResourcePickupScript.new() as Node3D
	pickup.name = "FieldPickup_%s" % pickup_id.replace(":", "_")
	pickup.set("world", self)
	pickup.set("pickup_id", pickup_id)
	pickup.set("node_id", str(data.get("node_id", "")))
	pickup.set("resource_id", str(data.get("resource_id", "wood")))
	var pickup_label := str(data.get("resource_label", data.get("resource_id", "Material")))
	pickup.set("resource_label", pickup_label.capitalize())
	pickup.set("discovery_id", str(data.get("discovery_id", "")))
	pickup.set("amount", int(data.get("amount", 1)))
	pickup.position = Vector3(float(position_data[0]), 0.92, float(position_data[2]))
	pickup.set_meta("base_y", pickup.position.y)
	pickup.add_to_group("interactable")
	pickup.add_to_group("expedition_pickup")
	parent_zone.add_child(pickup)
	expedition_pickup_visuals[pickup_id] = pickup
	var resource_id := str(data.get("resource_id", "wood"))
	var visual := Node3D.new()
	visual.name = "PickupVisual"
	pickup.add_child(visual)
	var material := _material(_pickup_material(resource_id), 0.9, resource_id in ["berries", "shell", "sunstone", "relic"], resource_id in ["berries", "shell", "sunstone", "relic"])
	if resource_id == "wood":
		for index in 2:
			var log := MeshInstance3D.new()
			var log_mesh := BoxMesh.new()
			log_mesh.size = Vector3(1.25, 0.18, 0.22)
			log.mesh = log_mesh
			log.material_override = material
			log.position = Vector3(0.0, 0.22 + float(index) * 0.12, float(index) * 0.16 - 0.08)
			log.rotation.y = float(index) * 0.18
			visual.add_child(log)
	elif resource_id in ["stone", "ore", "sunstone"]:
		var stone := MeshInstance3D.new()
		stone.mesh = _sphere_mesh(0.28, 0.6, 7, 4)
		stone.material_override = material
		stone.position.y = 0.28
		visual.add_child(stone)
	else:
		var bundle := MeshInstance3D.new()
		var bundle_mesh := CylinderMesh.new()
		bundle_mesh.top_radius = 0.16
		bundle_mesh.bottom_radius = 0.22
		bundle_mesh.height = 0.52
		bundle_mesh.radial_segments = 7
		bundle.mesh = bundle_mesh
		bundle.material_override = material
		bundle.position.y = 0.28
		bundle.rotation_degrees.z = 18.0
		visual.add_child(bundle)
	var label := _label3d("", 0.15, palette["cream"])
	label.name = "PickupLabel"
	label.position.y = 1.15
	pickup.add_child(label)
	pickup.call("set_amount", int(data.get("amount", 1)))

func _refresh_expedition_pickups() -> void:
	_clear_expedition_pickup_visuals()
	if session == null or current_zone == "Sanctuary" or not session.has_method("has_active_expedition") or not bool(session.call("has_active_expedition")):
		return
	var run: Dictionary = session.get("expedition_run")
	if str(run.get("biome_id", "")) != current_zone:
		return
	var pickups: Variant = run.get("pickups", [])
	if pickups is Array:
		for pickup_value in pickups:
			if pickup_value is Dictionary:
				_spawn_expedition_pickup(pickup_value)

func _sync_expedition_cargo() -> void:
	if session == null or not session.has_method("has_active_expedition"):
		expedition_loot = {}
		return
	var run: Dictionary = session.get("expedition_run")
	expedition_loot = run.get("cargo", {}).duplicate(true) if str(run.get("status", "none")) == "active" else {}

func _sync_expedition_anchor() -> void:
	if session == null or player == null or not session.has_method("has_active_expedition") or not session.call("has_active_expedition"):
		return
	var run: Dictionary = session.get("expedition_run")
	session.call("update_expedition_anchor", str(run.get("run_id", "")), [player.global_position.x, player.global_position.y, player.global_position.z])

func _zone_for_node(node: Node) -> String:
	for world_zone in world_zones:
		if world_zone.is_ancestor_of(node):
			return world_zone.name
	return ""

func _zone_background(zone: String) -> Color:
	match zone:
		"Sanctuary": return Color("#6f918b")
		"Whisperwood": return Color("#365e63")
		"Sunlit Beach": return Color("#65aab0")
		"Ember Ridge": return Color("#5f626c")
		"Glass Desert": return Color("#aa7b66")
		"Sunken Dungeon": return Color("#1d2430")
	return Color("#8fc1bf")

func _sleep() -> void:
	if get_tree().paused:
		return
	if current_zone != "Sanctuary":
		_show_toast("You need to be home before you can sleep.", 2.0)
		return
	if furnace != null and _ground_distance(player.global_position, furnace.global_position) > 7.0:
		_show_toast("Rest at the Hearth to advance the day.", 2.2)
		return
	var before_sleep: Dictionary = session.call("snapshot_state") if session != null and session.has_method("snapshot_state") else {}
	if session == null or not bool(session.call("advance_day", day + 1)):
		_show_toast("The Hearth cannot advance the day from this saved state. Save or reload before trying again.", 2.8)
		return
	_copy_session_to_runtime()
	for node in get_tree().get_nodes_in_group("resource_node"):
		if is_instance_valid(node) and node.has_method("restore"):
			node.restore()
	for guardian_node in get_tree().get_nodes_in_group("guardian"):
		if is_instance_valid(guardian_node) and guardian_node.has_method("restore"):
			guardian_node.call("restore")
	for pack in get_tree().get_nodes_in_group("recovery_pack"):
		if is_instance_valid(pack):
			pack.queue_free()
	recovery_loot = {}
	_restore_recovery_pack()
	_refresh_farm_plot()
	_refresh_station_visual()
	_refresh_structure_visuals()
	if not bool(session.call("save_game")):
		if not before_sleep.is_empty():
			session.call("restore_state", before_sleep)
		_copy_session_to_runtime()
		_refresh_farm_plot()
		_refresh_station_visual()
		_refresh_structure_visuals()
		_restore_active_expedition_nodes()
		for pack in get_tree().get_nodes_in_group("recovery_pack"):
			if is_instance_valid(pack):
				pack.queue_free()
		recovery_loot = {}
		_restore_recovery_pack()
		_show_toast("The day could not be secured to disk. Nothing was consumed; try sleeping again.", 3.0)
		return
	_show_toast("Day %d begins softly. Crops, jobs, and the forest have refreshed." % day, 3.0)

func _spawn_material_delivery_feedback(material_id: String, target: Node3D) -> void:
	if player == null or target == null:
		return
	var bundle := MeshInstance3D.new()
	bundle.name = "CarriedMaterialFeedback"
	if material_id in ["wood", "plank"]:
		var log_mesh := BoxMesh.new()
		log_mesh.size = Vector3(1.35 if material_id == "wood" else 1.05, 0.18, 0.26)
		bundle.mesh = log_mesh
	else:
		bundle.mesh = _sphere_mesh(0.28, 0.56, 8, 5)
	bundle.material_override = _material(palette["wood"] if material_id in ["wood", "plank"] else palette["stone"], 0.96)
	add_child(bundle)
	bundle.global_position = player.global_position + Vector3(0.0, 1.15, -0.35)
	var tween := bundle.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(bundle, "global_position", target.global_position + Vector3(0.0, 0.42, 0.0), 0.34)
	tween.parallel().tween_property(bundle, "rotation", Vector3(0.0, PI * 0.75, 0.0), 0.34)
	tween.tween_callback(bundle.queue_free)

func _toggle_furnace() -> void:
	if get_tree().paused:
		return
	if current_zone != "Sanctuary":
		_show_toast("The furnace is back at the Hearth.", 2.0)
		return
	furnace_active = not furnace_active
	_show_toast("Furnace smelting started." if furnace_active else "Furnace banked for now.", 2.0)

func _toggle_weather() -> void:
	var forecast := "rain" if day % 4 == 0 else "clear"
	_show_toast("The weather follows the day cycle: %s. Prepare supplies before leaving." % forecast.capitalize(), 2.6)

func _player_dodge() -> void:
	if get_tree().paused or current_zone == "Sanctuary" or player == null:
		return
	if resource_action_node != null or resource_contact_node != null:
		_cancel_resource_action()
		_show_toast("Gathering interrupted.", 1.0)
	if not bool(player.call("can_dodge")):
		_show_toast("Dodge is still recovering.", 1.0)
		return
	if session != null and not session.call("spend_energy", 1):
		_show_toast("You need 1 Energy to dodge. Find a camp or return home.", 2.0)
		return
	if bool(player.call("start_dodge")):
		_emit_feedback_event("dodge", player.global_position, _player_feedback_direction(), 0.7, _current_surface(), "player")
		_show_toast("Dodge", 0.55)

func _player_attack(_actor: Node) -> void:
	if get_tree().paused or attack_cooldown > 0.0 or pending_attack_target != null:
		return
	if resource_action_node != null or resource_contact_node != null:
		_cancel_resource_action()
		_show_toast("Gathering interrupted.", 1.0)
		return
	if current_zone != "Sanctuary" and session != null and session.has_method("has_active_expedition") and session.call("has_active_expedition"):
		var run: Dictionary = session.get("expedition_run")
		if str(run.get("branch_id", "")).is_empty():
			_show_toast("Choose a trail before engaging the guardian.", 2.4)
			return
	var target: Node = null
	var distance := 3.6
	for candidate in get_tree().get_nodes_in_group("guardian"):
		if not is_instance_valid(candidate) or not candidate.is_visible_in_tree():
			continue
		var candidate_body := candidate as Node3D
		if candidate_body == null:
			continue
		var candidate_distance := _ground_distance(player.global_position, candidate_body.global_position)
		var to_candidate: Vector3 = (candidate_body.global_position - player.global_position).normalized()
		var facing := float(player.get("last_direction").dot(to_candidate))
		if candidate_distance < distance and facing > 0.15:
			target = candidate
			distance = candidate_distance
	if target == null:
		_show_toast("Your attack cuts the air. Move closer to a threat.", 1.4)
		return
	if session != null and int(session.get("energy")) <= 0:
		_show_toast("You need 1 Energy to attack. Prepare, eat, or return to camp.", 1.8)
		return
	attack_cooldown = float(session.call("attack_cooldown_seconds")) if session != null and session.has_method("attack_cooldown_seconds") else 0.42
	pending_attack_target = target
	attack_action_elapsed = 0.0
	attack_action_phase = "windup"
	if player != null and player.has_method("play_attack_feedback"):
		player.call("play_attack_feedback")

func _update_attack_action(delta: float) -> void:
	if pending_attack_target == null or attack_action_phase == "idle":
		return
	attack_action_elapsed += delta
	var attack_windup := float(session.call("action_windup_seconds", 0.12)) if session != null and session.has_method("action_windup_seconds") else 0.12
	match attack_action_phase:
		"windup":
			if attack_action_elapsed < attack_windup:
				return
			attack_action_phase = "active"
			attack_action_elapsed = 0.0
			_resolve_player_attack_hit()
		"active":
			if attack_action_elapsed >= PLAYER_ATTACK_ACTIVE_SECONDS:
				attack_action_phase = "recovery"
				attack_action_elapsed = 0.0
		"recovery":
			if attack_action_elapsed >= PLAYER_ATTACK_RECOVERY_SECONDS:
				pending_attack_target = null
				attack_action_phase = "idle"
				attack_action_elapsed = 0.0

func _find_player_attack_contact() -> Node:
	if player == null or player_attack_shape == null or get_world_3d() == null:
		return null
	var facing: Vector3 = player.get("last_direction")
	facing.y = 0.0
	if facing.length_squared() < 0.0001:
		return null
	facing = facing.normalized()
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = player_attack_shape
	query.transform = Transform3D(Basis.IDENTITY, player.global_position + facing * 0.92)
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	var results := get_world_3d().direct_space_state.intersect_shape(query, 16)
	var closest: Node = null
	var closest_distance := INF
	for result in results:
		var collider := result.get("collider") as Node
		if collider == null:
			continue
		var candidate: Node = collider if collider.is_in_group("guardian") else collider.get_parent()
		if candidate == null or not candidate.is_in_group("guardian") or not candidate.is_visible_in_tree():
			continue
		if _zone_for_node(candidate) != current_zone.replace(" ", ""):
			continue
		var candidate_body := candidate as Node3D
		if candidate_body == null:
			continue
		var to_candidate := candidate_body.global_position - player.global_position
		to_candidate.y = 0.0
		var distance := to_candidate.length()
		if distance > 2.55 or distance < 0.01:
			continue
		if facing.dot(to_candidate.normalized()) < 0.18:
			continue
		if distance < closest_distance:
			closest = candidate
			closest_distance = distance
	if closest != null:
		return closest
	# PhysicsShapeQuery is the primary contact path. Keep a deterministic
	# collision-profile fallback for display/headless frames where a freshly
	# teleported CharacterBody3D has not published its broadphase transform yet.
	# This still reads the live guardian CollisionShape3D, never the initial
	# target selection or an arbitrary damage distance.
	var hitbox_center := player.global_position + facing * 0.92
	for candidate_node in get_tree().get_nodes_in_group("guardian"):
		var candidate := candidate_node as Node3D
		if candidate == null or not candidate.is_visible_in_tree() or _zone_for_node(candidate) != current_zone.replace(" ", ""):
			continue
		var candidate_shape := candidate.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if candidate_shape == null or candidate_shape.disabled or candidate_shape.shape == null:
			continue
		var profile_distance := hitbox_center.distance_to(candidate.global_position + candidate_shape.position)
		var candidate_radius := 0.0
		if candidate_shape.shape is SphereShape3D:
			candidate_radius = (candidate_shape.shape as SphereShape3D).radius
		elif candidate_shape.shape is BoxShape3D:
			var candidate_size := (candidate_shape.shape as BoxShape3D).size
			candidate_radius = maxf(candidate_size.x, candidate_size.z) * 0.5
		if candidate_radius > 0.0 and profile_distance <= player_attack_shape.radius + candidate_radius and facing.dot((candidate.global_position - player.global_position).normalized()) >= 0.18:
			return candidate
	return closest

func _persist_guardian_combat_state(guardian: Node) -> bool:
	if session == null or guardian == null or not session.has_method("record_guardian_combat_state") or not session.has_method("save_game"):
		return false
	var guardian_id := str(guardian.get("guardian_id"))
	var guardian_position := guardian as Node3D
	if guardian_position == null or int(guardian.get("health")) <= 0 or not guardian.is_visible_in_tree():
		return false
	var position := [guardian_position.global_position.x, 1.0, guardian_position.global_position.z]
	if not bool(session.call("record_guardian_combat_state", guardian_id, int(guardian.get("health")), position)):
		return false
	return bool(session.call("save_game"))

func _resolve_player_attack_hit() -> void:
	var target := _find_player_attack_contact()
	if target == null:
		_show_toast("Whiff  |  The blade cuts the air", 0.8)
		if audio_director != null:
			audio_director.call("play_action", "ui_error")
		return
	player_made_noise(player.global_position, 5.0)
	var combo_step := attack_combo_count + 1
	var target_health := int(target.get("health"))
	var before_attack: Dictionary = session.call("snapshot_state") if session != null and session.has_method("snapshot_state") else {}
	var before_target: Dictionary = target.call("capture_combat_state") if target.has_method("capture_combat_state") else {}
	var target_unaware := not bool(target.get("alerted")) and float(target.get("attack_windup")) <= 0.0
	var damage := 7 + strength * 2
	var attack_resolution: Dictionary = {}
	if session != null and session.has_method("resolve_attack"):
		attack_resolution = session.call("resolve_attack", 7, combo_step, target_health, bool(target.get("guarding")), target_unaware)
		if attack_resolution.is_empty():
			attack_cooldown = 0.0
			_show_toast("You need 1 Energy to attack. Prepare, eat, or return to camp.", 1.8)
			return
		damage = int(attack_resolution.get("damage", damage))
	elif session != null and session.has_method("calculate_attack_damage"):
		damage = int(session.call("calculate_attack_damage", 7))
	elif session != null and session.has_method("resolve_attack_damage"):
		damage = int(session.call("resolve_attack_damage", damage))
	target.call("take_damage", damage, attack_resolution)
	# Non-fatal guardian damage is a durable expedition fact. If the save cannot
	# secure it, roll back the resource spend and the runtime combat mutation so
	# a reload can never grant free damage or silently heal a half-finished fight.
	if target.is_visible_in_tree() and int(target.get("health")) > 0:
		if not _persist_guardian_combat_state(target):
			if session != null and not before_attack.is_empty():
				session.call("restore_state", before_attack)
			if target.has_method("restore_combat_state"):
				target.call("restore_combat_state", before_target)
			_copy_session_to_runtime()
			_show_toast("The strike could not be secured. No damage was committed.", 2.2)
			return
	attack_combo_count = combo_step if combo_step < 3 else 0
	attack_combo_timer = ATTACK_COMBO_WINDOW if attack_combo_count > 0 else 0.0
	var attack_surface := "metal" if bool(attack_resolution.get("guarded", false)) or bool(attack_resolution.get("guard_break", false)) else "grass"
	_emit_feedback_event("attack_hit", target.global_position, _player_feedback_direction(), 1.0, attack_surface, "player", {
		"guarded": bool(attack_resolution.get("guarded", false)),
		"guard_break": bool(attack_resolution.get("guard_break", false)),
		"heavy_attack": bool(attack_resolution.get("heavy_attack", false)),
	})
	if bool(attack_resolution.get("heavy_attack", false)):
		_show_toast("Heavy rhythm  |  %d damage" % damage, 0.9)
	if bool(attack_resolution.get("guarded", false)):
		_show_toast("Guarded  |  %d damage  |  Wait for the opening" % damage, 1.0)
	if bool(attack_resolution.get("guard_break", false)):
		_show_toast("Guard broken  |  The guardian is staggered", 1.15)
	if bool(attack_resolution.get("vanguard_resolve", false)):
		_show_toast("Vanguard Resolve  |  Finisher empowered", 1.2)
	if bool(attack_resolution.get("clean_shot", false)):
		_show_toast("Clean Shot  |  Opening stagger amplified", 1.15)

func _cancel_player_attack() -> void:
	pending_attack_target = null
	attack_action_phase = "idle"
	attack_action_elapsed = 0.0
	if player != null and player.has_method("cancel_attack_feedback"):
		player.call("cancel_attack_feedback")

func combat_feedback(target: Node, amount: int) -> void:
	# Combat mastery is awarded once the authoritative guardian reward settles.
	# Keeping hit feedback presentation-only prevents a rejected final blow (full
	# cargo or failed persistence) from becoming a repeatable mastery exploit.
	var target_body := target as Node3D
	if target_body != null:
		_spawn_feedback_burst(target_body.global_position, palette["danger"])
	_show_toast("Impact  |  %s -%d HP" % [str(target.get("enemy_label")), amount], 1.0)

func guardian_ambush_warning(guardian: Node) -> void:
	if guardian == null or session == null or not session.has_method("has_permission") or not bool(session.call("has_permission", "hunting_ambush_sense")):
		return
	var warning_seconds := 1.5
	if session.has_method("permission_effect"):
		warning_seconds = float(session.call("permission_effect", "hunting_ambush_sense", "warning_seconds", 1.50))
	var guardian_label := str(guardian.get("enemy_label"))
	if guardian_label.is_empty():
		guardian_label = "The predator"
	_show_toast("Ambush Sense  |  %s attacks in %.1fs" % [guardian_label, warning_seconds], minf(1.3, warning_seconds))

func guardian_attack(guardian: Node) -> void:
	var guardian_body := guardian as Node3D
	var attack_range := 2.4
	if guardian != null:
		attack_range = float(guardian.get("attack_range"))
	if guardian_body == null or _ground_distance(player.global_position, guardian_body.global_position) > attack_range + 0.25:
		return
	if float(player.get("invulnerable_time")) > 0.0:
		_emit_feedback_event("dodge", player.global_position, _player_feedback_direction(), 0.8, _current_surface(), "guardian")
		_show_toast("Clean dodge", 0.9)
		return
	player.call("take_damage", maxi(1, int(guardian.get("attack_damage"))))

func guardian_defeated(guardian: Node) -> bool:
	var guardian_id := str(guardian.get("guardian_id"))
	var reward_id := str(guardian.get("reward_id"))
	var reward_amount := int(guardian.get("reward_amount"))
	var enemy_name := str(guardian.get("enemy_label"))
	var deferred_reward := false
	var before_guardian: Dictionary = session.call("snapshot_state") if session != null and session.has_method("snapshot_state") else {}
	if session != null and current_zone != "Sanctuary" and session.has_method("resolve_guardian_defeat"):
		var resolution: Dictionary = session.call("resolve_guardian_defeat", guardian_id)
		if resolution.is_empty():
			var remaining := int(session.call("expedition_cargo_remaining"))
			var capacity_message := "Your cargo is full. Extract before taking another reward." if remaining <= 0 else "Only %d satchel space remains; this reward needs %d. Return to make room." % [remaining, reward_amount]
			_show_toast(capacity_message, 2.4)
			return false
		reward_id = str(resolution.get("reward_id", reward_id))
		reward_amount = int(resolution.get("reward_amount", reward_amount))
		deferred_reward = bool(resolution.get("deferred_pickup", false))
	else:
		if not inventory.has(reward_id):
			inventory[reward_id] = 0
		inventory[reward_id] += reward_amount
	if session != null:
		_sync_expedition_cargo()
		if not bool(session.call("save_game")):
			if not before_guardian.is_empty():
				session.call("restore_state", before_guardian)
			_copy_session_to_runtime()
			_show_toast("The guardian reward could not be secured. The encounter remains open.", 3.0)
			return false
	if deferred_reward:
		_show_toast("%s defeated  |  Reward dropped nearby: %d %s  |  Combat mastery +12" % [enemy_name, reward_amount, reward_id.replace("_", " ").capitalize()], 3.0)
	else:
		_show_toast("%s defeated  |  +%d %s  |  Combat mastery +12" % [enemy_name, reward_amount, reward_id.replace("_", " ").capitalize()], 3.0)
	return true

func player_took_damage(amount: int) -> void:
	if session == null or player == null or not session.has_method("apply_player_damage"):
		return
	if resource_action_node != null or resource_contact_node != null:
		_cancel_resource_action()
		_show_toast("Gathering interrupted by impact.", 1.0)
	if pending_attack_target != null:
		_cancel_player_attack()
		_show_toast("Attack interrupted by impact.", 1.0)
	var hit_position := player.global_position
	var hit_surface := _current_surface()
	var before_damage: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var result: Dictionary = session.call("apply_player_damage", amount)
	player.set("health", int(result.get("health", player.get("health"))))
	if bool(result.get("fainted", false)):
		if current_zone == "Sanctuary":
			session.call("reset_player_health")
			player.set("health", int(session.get("health")))
		else:
			player_fainted(before_damage)
	_emit_feedback_event("player_hit", hit_position, Vector3.ZERO, clampf(float(amount) / 12.0, 0.2, 1.5), hit_surface, "guardian", {"damage": amount})
	if bool(result.get("second_wind", false)):
		_show_toast("Second Wind  |  Your resolve kept the expedition alive.", 2.4)
	else:
		_show_toast("You took %d damage. Read the guardian's movement before engaging." % amount, 1.8)

func _try_haptic(duration_ms: int, amplitude: float) -> void:
	if not haptics_enabled or not DisplayServer.is_touchscreen_available():
		return
	Input.vibrate_handheld(duration_ms, clampf(amplitude, 0.0, 1.0))

func player_fainted(before_damage: Dictionary = {}) -> void:
	if session == null or player == null or not session.has_method("fail_expedition"):
		return
	var before_faint: Dictionary = before_damage if not before_damage.is_empty() else (session.call("snapshot_state") if session.has_method("snapshot_state") else {})
	var before_zone := current_zone
	var before_position := player.global_position
	var pack: Dictionary = session.call("fail_expedition", player.global_position)
	session.call("reset_player_health")
	if not bool(session.call("save_game")):
		if not before_faint.is_empty():
			session.call("restore_state", before_faint)
		_copy_session_to_runtime()
		current_zone = before_zone
		player.global_position = before_position
		_show_toast("The faint could not be secured. Your run remains active.", 3.2)
		return
	recovery_loot = pack.get("loot", {}) if pack is Dictionary else {}
	expedition_loot = {}
	if not recovery_loot.is_empty():
		_clear_recovery_nodes()
		_spawn_recovery_pack(recovery_loot, player.global_position, str(pack.get("zone_id", before_zone)))
	player.set("health", max_health)
	_set_zone("Sanctuary")
	_show_toast("You fainted. Half of unbanked expedition loot is waiting in a recovery pack.", 3.5)

func _clear_recovery_nodes() -> void:
	for pack in get_tree().get_nodes_in_group("recovery_pack"):
		if is_instance_valid(pack):
			pack.queue_free()
	recovery_pack_visual = null

func player_moved(moving: bool) -> void:
	if moving and resource_action_node != null:
		_cancel_resource_action()
		_show_toast("Gathering interrupted.", 1.4)
	if not moving or footstep_timer > 0.0:
		return
	footstep_timer = 0.27
	_emit_feedback_event("step", player.global_position, _player_feedback_direction(), 0.35, _current_surface(), "player")
	player_made_noise(player.global_position, 2.6)

func navigation_target_blocked() -> void:
	if move_target_marker != null:
		move_target_marker.visible = false
	_show_toast("That spot is blocked. Choose an open patch of ground.", 1.8)

func player_made_noise(position: Vector3, intensity: float) -> void:
	if current_zone == "Sanctuary":
		return
	for guardian_node in get_tree().get_nodes_in_group("guardian"):
		if not is_instance_valid(guardian_node) or not guardian_node.is_visible_in_tree():
			continue
		if _zone_for_node(guardian_node) == current_zone.replace(" ", "") and guardian_node.has_method("hear_noise"):
			guardian_node.call("hear_noise", position, intensity)

func recover_loot(pack_id: String, pack_node: Node3D = null) -> bool:
	if session == null or pack_id.is_empty() or pack_node == null or not is_instance_valid(pack_node) or not pack_node.is_in_group("recovery_pack") or not pack_node.is_visible_in_tree() or pack_node != recovery_pack_visual or _zone_for_node(pack_node) != current_zone.replace(" ", "") or player == null or _interaction_distance(pack_node) > _interaction_range():
		return false
	var before_recovery: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var loot: Dictionary = {}
	if session.has_method("claim_recovery_pack_to_expedition") and session.call("has_active_expedition"):
		loot = session.call("claim_recovery_pack_to_expedition", pack_id, current_zone)
	else:
		loot = session.call("claim_recovery_pack", pack_id, current_zone)
	if loot.is_empty():
		_show_toast("That recovery pack is expired, too heavy, or not from this route.", 2.4)
		return false
	recovery_loot = {}
	_sync_expedition_cargo()
	if not bool(session.call("save_game")):
		if not before_recovery.is_empty():
			session.call("restore_state", before_recovery)
		_copy_session_to_runtime()
		_sync_expedition_cargo()
		_clear_recovery_nodes()
		_restore_recovery_pack()
		_show_toast("The recovery pack could not be secured. Nothing was taken.", 3.0)
		return false
	_show_toast("Recovery pack opened. The recovered cargo is still at risk until extraction.", 2.8)
	return true

func _spawn_recovery_pack(loot: Dictionary, position: Vector3, zone_id := "Whisperwood", pack_id := "") -> void:
	var pack := RecoveryPackScript.new() as Node3D
	pack.name = "RecoveryPack"
	pack.set("world", self)
	pack.set("loot", loot.duplicate(true))
	pack.set("pack_id", pack_id if not pack_id.is_empty() else str(session.get("recovery_pack").get("pack_id", "") if session != null else ""))
	pack.set("zone_id", zone_id)
	pack.position = position
	pack.add_to_group("interactable")
	pack.add_to_group("recovery_pack")
	var parent_zone: Node3D = forest_zone
	for candidate in world_zones:
		if candidate.name == zone_id.replace(" ", ""):
			parent_zone = candidate
			break
	parent_zone.add_child(pack)
	recovery_pack_visual = pack
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.8, 0.55, 0.62)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(palette["sand"], 0.85)
	mesh_instance.position.y = 0.32
	pack.add_child(mesh_instance)
	var marker := _label3d("RECOVERY", 0.18, palette["cream"])
	marker.position.y = 1.15
	pack.add_child(marker)

func _restore_recovery_pack() -> void:
	if session == null:
		return
	var data: Dictionary = session.get("recovery_pack")
	if data.is_empty():
		return
	if int(data.get("expires_day", day + 1)) <= day:
		session.call("clear_expired_recovery_pack")
		return
	var position_data = data.get("position", [])
	if position_data is Array and position_data.size() >= 3:
		_spawn_recovery_pack(data.get("loot", {}), Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2])), str(data.get("zone_id", "Whisperwood")), str(data.get("pack_id", "")))

func _spawn_feedback_burst(position: Vector3, color: Color) -> void:
	var burst := Node3D.new()
	burst.name = "FeedbackBurst"
	burst.position = position + Vector3(0.0, 0.7, 0.0)
	add_child(burst)
	for index in 4:
		var shard := MeshInstance3D.new()
		shard.mesh = _sphere_mesh(0.08, 0.16, 6, 3)
		shard.material_override = _material(color.lightened(0.18), 0.8)
		shard.position = Vector3((float(index) - 1.5) * 0.12, 0.0, 0.0)
		burst.add_child(shard)
		var destination := shard.position + Vector3((float(index) - 1.5) * 0.25, 0.8 + float(index % 2) * 0.18, sin(float(index)) * 0.18)
		var tween := shard.create_tween()
		tween.set_parallel(true)
		tween.tween_property(shard, "position", destination, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(shard, "scale", Vector3.ZERO, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var cleanup := get_tree().create_timer(0.48)
	cleanup.timeout.connect(burst.queue_free)
