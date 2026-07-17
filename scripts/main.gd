extends Node3D

const ResourceNodeScript = preload("res://scripts/resource_node.gd")
const GuardianScript = preload("res://scripts/guardian.gd")
const PlayerScript = preload("res://scripts/player.gd")
const AudioDirectorScript = preload("res://scripts/audio_director.gd")
const JoystickScript = preload("res://scripts/virtual_joystick.gd")
const RecoveryPackScript = preload("res://scripts/recovery_pack.gd")
const SessionScript = preload("res://scripts/game_session.gd")
const FarmPlotScript = preload("res://scripts/farm_plot.gd")
const StationScript = preload("res://scripts/crafting_station.gd")
const VillagerScript = preload("res://scripts/villager.gd")
const LivestockAnimalScript = preload("res://scripts/livestock_animal.gd")
const ContentRegistry = preload("res://scripts/content_registry.gd")
const SettlementGrid = preload("res://scripts/settlement_grid.gd")

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

var session: Node
var sanctuary_zone: Node3D
var forest_zone: Node3D
var beach_zone: Node3D
var mountain_zone: Node3D
var desert_zone: Node3D
var dungeon_zone: Node3D
var world_zones: Array[Node3D] = []
var player: CharacterBody3D
var camera: Camera3D
var audio_director: Node
var furnace: Node3D
var farm_plot: Node3D
var workshop: Node3D
var library_station: Node3D
var notice_board: Node3D
var guide_npc: Node3D
var fishing_spot: Node3D
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
var toast_label: Label
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
var recovery_loot: Dictionary = {}
var expedition_loot: Dictionary = {}
var inventory := {"wood": 0, "stone": 0, "fiber": 0, "slime_gel": 0, "ore": 0, "shell": 0}
var build_progress := 0.0
var activity_streak := 0
var ui_panel: Control
var hud_root: Control
var hud_top_panel: Panel
var hud_bag_panel: Panel
var hud_quest_panel: Panel
var hud_right_panel: Panel
var hud_right_scroll: ScrollContainer
var hud_right_box: VBoxContainer
var hud_joystick: Control
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
var stat_button: Button
var recipe_button: Button
var dodge_button: Button
var utilities_button: Button
var utilities_open := false
var last_autosave := 0.0
var camera_shake := 0.0
var last_farm_signature := ""
var interaction_marker: MeshInstance3D
var sun_light: DirectionalLight3D
var animated_water: Array[MeshInstance3D] = []
var animated_beacons: Array[MeshInstance3D] = []
var hazard_timer := 0.0
var hazard_shelter_active := false
var anchor_timer := 0.0
var resource_action_node: Node = null
var resource_action_elapsed := 0.0
var resource_action_duration := 0.58
var pending_attack_target: Node = null
var attack_action_elapsed := 0.0
var placement_mode := false
var placement_structure_id := "rain_cistern"
var settlement_visuals := {}

var palette := {
	"ink": Color("#18282b"),
	"panel": Color(0.055, 0.10, 0.105, 0.94),
	"panel_light": Color(0.12, 0.20, 0.18, 0.94),
	"cream": Color("#fff4d4"),
	"muted": Color("#b8c6b0"),
	"leaf": Color("#78a66a"),
	"leaf_dark": Color("#3e654e"),
	"grass": Color("#5f9464"),
	"grass_dark": Color("#345b4c"),
	"sand": Color("#d7b77a"),
	"wood": Color("#9b6e4e"),
	"wood_dark": Color("#573e32"),
	"stone": Color("#9ba89c"),
	"water": Color("#4d99a4"),
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
	_build_player()
	_build_audio()
	_build_hud()
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
	_show_toast("A quiet world is waiting. Gather, build, and make it yours.", 4.0)

func _process(delta: float) -> void:
	if get_tree().paused:
		_update_hud()
		return
	_copy_session_to_runtime()
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	footstep_timer = maxf(0.0, footstep_timer - delta)
	toast_timer = maxf(0.0, toast_timer - delta)
	if toast_label != null:
		toast_label.visible = toast_timer > 0.0
	if player != null and camera != null:
		var shake := Vector3.ZERO
		if camera_shake > 0.0:
			camera_shake = maxf(0.0, camera_shake - delta)
			shake = Vector3(randf_range(-0.08, 0.08), randf_range(-0.04, 0.04), randf_range(-0.08, 0.08)) * camera_shake * 12.0
		camera.global_position = player.global_position + Vector3(13.5, 17.5, 13.5) + shake
		camera.look_at(player.global_position + Vector3(0.0, 0.2, 0.0), Vector3.UP)
	_update_time(delta)
	_update_tree_sway()
	_update_world_motion(delta)
	_update_player_structure_motion(delta)
	_update_resource_action(delta)
	_update_attack_action(delta)
	_update_structure_preview()
	_update_lighting()
	_update_audio_context()
	_update_interaction_marker(delta)
	_update_hud()
	anchor_timer += delta
	if anchor_timer >= 0.35:
		anchor_timer = 0.0
		_sync_expedition_anchor()
	last_autosave += delta
	if last_autosave >= 20.0 and session != null:
		last_autosave = 0.0
		session.call("save_game")
	_update_expedition_hazard(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if get_tree().paused and not event.is_action_pressed("pause"):
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
	elif event.is_action_pressed("cycle_structure"):
		_cycle_structure_selection()
	elif event.is_action_pressed("station"):
		station_interact(workshop)
	elif event.is_action_pressed("stats"):
		_allocate_best_stat()
	elif event.is_action_pressed("activity"):
		_record_activity()
	elif event.is_action_pressed("pause"):
		_toggle_pause()

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
		"cycle_structure": [KEY_N],
		"station": [KEY_C],
		"stats": [KEY_L],
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
	environment.background_color = Color("#8fc1bf")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#d7ead5")
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	add_child(environment_node)
	sun_light = DirectionalLight3D.new()
	sun_light.name = "Sun"
	sun_light.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun_light.light_color = Color("#ffe4b5")
	sun_light.light_energy = 1.15
	sun_light.shadow_enabled = true
	add_child(sun_light)
	var fill := OmniLight3D.new()
	fill.name = "HearthFill"
	fill.position = Vector3(-1.5, 3.0, 1.0)
	fill.omni_range = 8.0
	fill.light_color = Color("#ff9c5a")
	fill.light_energy = 0.0
	add_child(fill)

func _build_world() -> void:
	sanctuary_zone = Node3D.new()
	sanctuary_zone.name = "Sanctuary"
	add_child(sanctuary_zone)
	_create_floor(sanctuary_zone, Vector3(0.0, -0.25, 0.0), Vector2(40.0, 30.0), palette["grass"], "SanctuaryGround")
	_create_path(sanctuary_zone, Vector3(0.0, 0.02, 1.0), Vector3(3.0, 0.08, 24.0), palette["stone"])
	_create_path(sanctuary_zone, Vector3(5.5, 0.02, -1.5), Vector3(12.0, 0.08, 2.2), palette["stone"])
	for route_id in ContentRegistry.ROUTE_SOCKETS:
		var route_socket: Dictionary = ContentRegistry.ROUTE_SOCKETS[route_id]
		var path_center: Array = route_socket.get("path_center", [0.0, 0.0])
		var path_size: Array = route_socket.get("path_size", [1.0, 1.0])
		_create_path(sanctuary_zone, Vector3(float(path_center[0]), 0.02, float(path_center[1])), Vector3(float(path_size[0]), 0.08, float(path_size[1])), palette["stone"])
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
	var sanctuary_tree_positions := [Vector3(-11, 0, -8), Vector3(-8, 0, 7), Vector3(12, 0, 7), Vector3(11, 0, -2), Vector3(-12, 0, 2), Vector3(3, 0, 8)]
	for index in sanctuary_tree_positions.size():
		_create_tree(sanctuary_zone, sanctuary_tree_positions[index], 1.0 + float(index % 3) * 0.12, "wood", 2)
	for position in [Vector3(-5, 0, 5), Vector3(4, 0, 6), Vector3(9, 0, 1), Vector3(-10, 0, -5)]:
		_create_flower_patch(sanctuary_zone, position, palette["leaf"])
	_dress_sanctuary_edges(sanctuary_zone)
	_create_fiber_patch(sanctuary_zone, Vector3(-4.0, 0.0, 6.0))
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
	_create_mushroom(forest_zone, Vector3(-6.5, 0.0, 0.5))
	_create_mushroom(forest_zone, Vector3(-7.4, 0.0, -3.8), "Whisperwood:FernGroveMushroom")
	_create_rock(forest_zone, Vector3(5.2, 0.0, -2.6), "stone", 2, "Trail Stone")
	_create_whisperwood_landmarks(forest_zone)
	_create_guardian(forest_zone, Vector3(5.0, 0.9, -4.0), "forest_slime", Color("#c66b85"))
	_create_camp_site(forest_zone, Vector3(-9.0, 0.0, -1.0), "WOODLAND CAMP")
	world_zones = [sanctuary_zone, forest_zone]
	beach_zone = _create_expedition_zone("Sunlit Beach", Color("#c79c67"), Color("#8f6b4c"), Color("#4b9ea6"))
	_create_tree(beach_zone, Vector3(-10, 0, -7), 0.82, "wood", 2)
	_create_tree(beach_zone, Vector3(10, 0, 5), 0.72, "wood", 2)
	_create_rock(beach_zone, Vector3(-5, 0, 2), "stone", 1)
	_create_rock(beach_zone, Vector3(6, 0, -4), "shell", 1, "Shell Fragment")
	_create_shell_discovery(beach_zone, Vector3(4.0, 0.0, 2.5))
	_create_shell_discovery(beach_zone, Vector3(-7.0, 0.0, -4.4), "SunlitBeach:TideglassShell:pool")
	_create_guardian(beach_zone, Vector3(-6.0, 0.9, -4.0), "tide_wraith", Color("#5eb6bd"))
	_create_camp_site(beach_zone, Vector3(9.0, 0.0, -6.0), "TIDE CAMP")
	world_zones.append(beach_zone)
	mountain_zone = _create_expedition_zone("Ember Ridge", Color("#596367"), Color("#7f8d8c"), Color("#e19a62"))
	_create_rock(mountain_zone, Vector3(-8, 0, -6), "ore", 2, "Copper Ore")
	_create_rock(mountain_zone, Vector3(8, 0, -2), "ore", 2, "Copper Ore")
	_create_rock(mountain_zone, Vector3(-4, 0, 6), "stone", 2)
	_create_tree(mountain_zone, Vector3(10, 0, 7), 0.76, "wood", 1)
	_create_guardian(mountain_zone, Vector3(5.0, 0.9, -5.0), "ember_golem", Color("#d97952"))
	_create_camp_site(mountain_zone, Vector3(-9.0, 0.0, 5.5), "RIDGE CAMP")
	world_zones.append(mountain_zone)
	desert_zone = _create_expedition_zone("Glass Desert", Color("#c58b62"), Color("#9b674f"), Color("#d66f57"))
	_create_cactus(desert_zone, Vector3(-8, 0, -6))
	_create_cactus(desert_zone, Vector3(7, 0, 3))
	_create_rock(desert_zone, Vector3(-2, 0, 6), "sunstone", 1, "Sunstone")
	_create_rock(desert_zone, Vector3(9, 0, -7), "stone", 1)
	_create_guardian(desert_zone, Vector3(-5.0, 0.9, 4.5), "dune_wisp", Color("#e6ad61"))
	_create_camp_site(desert_zone, Vector3(8.0, 0.0, -5.5), "DUNE CAMP")
	world_zones.append(desert_zone)
	dungeon_zone = _create_expedition_zone("Sunken Dungeon", Color("#29353e"), Color("#4a5360"), Color("#a88ce0"))
	_create_rock(dungeon_zone, Vector3(-7.0, 0.0, -4.0), "ore", 3, "Veinstone")
	_create_rock(dungeon_zone, Vector3(8.0, 0.0, 4.5), "ore", 3, "Veinstone")
	_create_relic_discovery(dungeon_zone, Vector3(4.0, 0.0, -3.0))
	_create_guardian(dungeon_zone, Vector3(-4.0, 0.9, 4.0), "crypt_knight", Color("#a88ce0"))
	_create_camp_site(dungeon_zone, Vector3(9.0, 0.0, -6.5), "DUNGEON CAMP")
	world_zones.append(dungeon_zone)
	for zone in world_zones:
		zone.visible = zone == sanctuary_zone

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
	_create_path(route, Vector3(0.0, 0.045, -1.9), Vector3(3.4, 0.07, 1.0), palette["wood"])
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
	clearing.position = Vector3(5.0, 0.035, -4.0)
	route.add_child(clearing)
	var clearing_label := _label3d("GUARDIAN CLEARING", 0.16, palette["cream"])
	clearing_label.position = Vector3(5.0, 0.22, -6.45)
	route.add_child(clearing_label)
	var branch_marker := StationScript.new() as Node3D
	branch_marker.name = "WhisperwoodBranchChoice"
	branch_marker.set("world", self)
	branch_marker.set("station_id", "whisper_branch")
	branch_marker.add_to_group("interactable")
	branch_marker.set_meta("route_branch_choice", true)
	branch_marker.position = Vector3(0.0, 0.0, -1.9)
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
	_create_whisper_cache(route, Vector3(-8.2, 0.0, -4.8), "grove", "FERN GROVE CACHE", Color("#8fcf9a"))
	_create_whisper_cache(route, Vector3(8.0, 0.0, -5.0), "clearing", "GUARDIAN CACHE", Color("#d58b9c"))
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
		{"id": "ArrivalGrove", "label": "ARRIVAL GROVE", "position": Vector3(0.0, 0.04, 5.2), "radius": 3.4, "color": Color("#52785d")},
		{"id": "OldTrailFork", "label": "OLD TRAIL FORK", "position": Vector3(0.0, 0.04, -1.9), "radius": 2.4, "color": Color("#6d805f")},
		{"id": "FernGrove", "label": "FERN GROVE", "position": Vector3(-12.5, 0.04, -8.6), "radius": 3.1, "color": Color("#6f9a73")},
		{"id": "GuardianClearing", "label": "GUARDIAN CLEARING", "position": Vector3(12.5, 0.04, -8.6), "radius": 3.4, "color": Color("#856b68")},
		{"id": "ReturnFootbridge", "label": "RETURN FOOTBRIDGE", "position": Vector3(0.0, 0.04, 8.7), "radius": 2.6, "color": Color("#7e7058")},
	]
	for beat_data in beats:
		var beat := Node3D.new()
		beat.name = str(beat_data["id"])
		beat.set_meta("route_beat", beat.name)
		beat.position = beat_data["position"]
		topology.add_child(beat)
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
	_create_path(topology, Vector3(0.0, 0.08, 2.1), Vector3(2.35, 0.10, 6.4), Color("#80694f"))
	_create_path(topology, Vector3(-3.8, 0.08, -4.1), Vector3(7.5, 0.10, 1.2), Color("#80694f"))
	_create_path(topology, Vector3(3.8, 0.08, -4.1), Vector3(7.5, 0.10, 1.2), Color("#80694f"))
	_create_path(topology, Vector3(-8.8, 0.08, -6.4), Vector3(7.2, 0.10, 1.1), Color("#80694f"))
	_create_path(topology, Vector3(8.8, 0.08, -6.4), Vector3(7.2, 0.10, 1.1), Color("#80694f"))
	_create_path(topology, Vector3(0.0, 0.08, 7.0), Vector3(2.0, 0.10, 3.5), Color("#a58b62"))
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
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.62
	shadow_mesh.bottom_radius = 0.62
	shadow_mesh.height = 0.018
	shadow_mesh.radial_segments = 24
	shadow.mesh = shadow_mesh
	shadow.material_override = _material(Color(0.03, 0.06, 0.05, 0.32), 1.0, true)
	shadow.position.y = 0.02
	visual.add_child(shadow)
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
	camera.size = 18.0
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
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.resized.connect(_layout_hud)
	canvas.add_child(root)
	hud_top_panel = _panel(Vector2(24, 22), Vector2(360, 190), palette["panel"])
	var top_panel := hud_top_panel
	root.add_child(top_panel)
	var top_box := VBoxContainer.new()
	top_box.position = Vector2(18, 14)
	top_box.size = Vector2(324, 162)
	top_box.add_theme_constant_override("separation", 5)
	top_panel.add_child(top_box)
	var title := _label("PRODEWTY", 24, palette["cream"])
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
	hud_bag_panel = _panel(Vector2(24, 232), Vector2(360, 286), palette["panel"])
	var bag_panel := hud_bag_panel
	root.add_child(bag_panel)
	inventory_label = _label("BANKED\nWood 0  Stone 0  Fiber 0\nCARGO  —", 12, palette["cream"])
	inventory_label.position = Vector2(18, 14)
	inventory_label.size = Vector2(324, 204)
	bag_panel.add_child(inventory_label)
	mastery_label = _label("LEVEL 1  |  AP 2\nFORAGING 0   FARMING 0   CRAFTING 0", 11, palette["muted"])
	mastery_label.position = Vector2(18, 222)
	mastery_label.size = Vector2(324, 48)
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
	pause_button = _button("Pause", _toggle_pause)
	right_box.add_child(pause_button)
	destination_button = _button("Destination: Whisperwood", _cycle_expedition)
	right_box.add_child(destination_button)
	explore_button = _button("Explore Whisperwood", _enter_selected_expedition)
	right_box.add_child(explore_button)
	return_button = _button("Return to Sanctuary", _return_home)
	right_box.add_child(return_button)
	interact_button = _button("Interact", _contextual_interact)
	right_box.add_child(interact_button)
	attack_button = _button("Attack  [Space]", func() -> void: _player_attack(player))
	right_box.add_child(attack_button)
	dodge_button = _button("Dodge  [Shift]", _player_dodge)
	right_box.add_child(dodge_button)
	sleep_button = _button("Sleep / Advance Day  [R]", _sleep)
	right_box.add_child(sleep_button)
	smelt_button = _button("Start Furnace", _toggle_furnace)
	right_box.add_child(smelt_button)
	farm_button = _button("Garden Plot  [F]", func() -> void: farm_plot_interact(farm_plot))
	right_box.add_child(farm_button)
	food_button = _button("Eat Bread  [G]", _eat_best_food)
	right_box.add_child(food_button)
	water_button = _button("Drink Water  [H]", _drink_water)
	right_box.add_child(water_button)
	livestock_button = _button("Livestock Pen", _livestock_contextual_action)
	right_box.add_child(livestock_button)
	repair_button = _button("Repair Tools  [V]", _repair_tools)
	right_box.add_child(repair_button)
	recipe_button = _button("Recipe: Plank  [Q]", _cycle_recipe_selection)
	right_box.add_child(recipe_button)
	structure_button = _button("Place Rain Cistern  [B]", _toggle_structure_placement)
	right_box.add_child(structure_button)
	blueprint_button = _button("Blueprint: Rain Cistern  [N]", _cycle_structure_selection)
	right_box.add_child(blueprint_button)
	build_button = _button("Build Workshop", _workshop_contextual_action)
	right_box.add_child(build_button)
	utilities_button = _button("Open Ledger", _toggle_utilities)
	right_box.add_child(utilities_button)
	activity_button = _button("Log 25m Effort  [P]", _record_activity)
	right_box.add_child(activity_button)
	save_button = _button("Save Progress", _save_game)
	right_box.add_child(save_button)
	stat_button = _button("Spend Ability Point  [L]", _allocate_best_stat)
	right_box.add_child(stat_button)
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
	root.add_child(joystick)
	joystick.vector_changed.connect(Callable(player, "set_joystick_vector"))
	_layout_hud()

func _layout_hud() -> void:
	if hud_root == null:
		return
	var viewport_size := hud_root.size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	# Keep controls away from rounded corners, camera cutouts, and the edge of
	# a touch device while retaining the authored 1280x720 composition on
	# desktop.
	var margin := maxf(14.0, minf(viewport_size.x, viewport_size.y) * 0.025)
	var left_width := minf(360.0, maxf(286.0, viewport_size.x * 0.31))
	var right_width := minf(266.0, maxf(220.0, viewport_size.x * 0.24))
	if hud_top_panel != null:
		hud_top_panel.position = Vector2(margin, margin)
		hud_top_panel.size.x = left_width
	if hud_bag_panel != null:
		hud_bag_panel.position = Vector2(margin, margin + 210.0)
		hud_bag_panel.size.x = left_width
	if hud_quest_panel != null:
		hud_quest_panel.position = Vector2(maxf(margin, viewport_size.x * 0.31), maxf(margin + 430.0, viewport_size.y - 120.0))
		hud_quest_panel.size.x = minf(360.0, maxf(250.0, viewport_size.x * 0.29))
	if hud_right_panel != null:
		hud_right_panel.position = Vector2(viewport_size.x - right_width - margin, margin)
		hud_right_panel.size = Vector2(right_width, maxf(260.0, viewport_size.y - margin * 2.0))
	if hud_right_scroll != null:
		hud_right_scroll.size = hud_right_panel.size - Vector2(20.0, 20.0)
	if hud_right_box != null:
		hud_right_box.custom_minimum_size.x = maxf(196.0, right_width - 28.0)
	if action_hint != null:
		action_hint.position = Vector2(margin, viewport_size.y - 70.0)
		action_hint.size.x = maxf(420.0, viewport_size.x - right_width - margin * 3.0)
	if toast_label != null:
		toast_label.position = Vector2(maxf(margin + 300.0, viewport_size.x * 0.28), margin)
		toast_label.size.x = maxf(260.0, minf(580.0, viewport_size.x * 0.44))
	if hud_joystick != null:
		hud_joystick.position = Vector2(margin, viewport_size.y - 172.0)

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
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	if document.append_from_file(asset_path, state) != OK:
		return false
	var instance := document.generate_scene(state)
	if instance == null:
		return false
	instance.name = "Sourced_" + asset_path.get_file().get_basename()
	instance.position = local_position
	instance.scale = Vector3.ONE * scale_value
	parent.add_child(instance)
	return true

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
	var fishing_label := _label3d("FISHING SPOT", 0.15, palette["cream"])
	fishing_label.position = Vector3(0.0, 1.15, 0.0)
	fishing_spot.add_child(fishing_label)

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
	tree.add_to_group("resource_node")
	tree.add_to_group("interactable")
	parent.add_child(tree)
	var trunk := MeshInstance3D.new()
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
	var tree_body := StaticBody3D.new()
	tree_body.name = "TreeCollision"
	var tree_shape := CollisionShape3D.new()
	var tree_capsule := CapsuleShape3D.new()
	tree_capsule.radius = 0.42
	tree_capsule.height = 2.2
	tree_shape.shape = tree_capsule
	tree_shape.position.y = 1.1
	tree_body.add_child(tree_shape)
	tree.add_child(tree_body)
	var sourced_model := _add_sourced_model(tree, _tree_asset_path(parent.name), 0.52, Vector3(0.0, 0.12, 0.0))
	trunk.visible = not sourced_model
	canopy.visible = not sourced_model
	crown.visible = not sourced_model
	sway_nodes.append({"node": tree, "phase": float(sway_nodes.size()) * 0.73})
	if parent == sanctuary_zone:
		sanctuary_nodes.append(tree)
	else:
		forest_nodes.append(tree)
	return tree

func _create_rock(parent: Node3D, position: Vector3, resource_id: String, amount: int, resource_label := "") -> Node3D:
	var rock := ResourceNodeScript.new() as Node3D
	rock.name = "StoneNode"
	rock.set("world", self)
	rock.set("resource_id", resource_id)
	rock.set("resource_amount", amount)
	rock.set("resource_label", "Stone" if resource_label.is_empty() else resource_label)
	rock.set("node_id", "%s:%s:%d" % [parent.name, resource_id, parent.get_child_count()])
	if parent.name == "EmberRidge" and resource_id == "ore":
		rock.set_meta("route_branch", "quarry")
	rock.position = position
	rock.add_to_group("interactable")
	parent.add_child(rock)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _sphere_mesh(0.7, 0.9, 7, 4)
	mesh_instance.material_override = _material(Color("#c77b4e") if resource_id in ["ore", "sunstone"] else palette["stone"], 0.98)
	mesh_instance.scale = Vector3(1.25, 0.72, 0.92)
	mesh_instance.position.y = 0.42
	rock.add_child(mesh_instance)
	var rock_body := StaticBody3D.new()
	rock_body.name = "RockCollision"
	var rock_shape := CollisionShape3D.new()
	var rock_sphere := SphereShape3D.new()
	rock_sphere.radius = 0.72
	rock_shape.shape = rock_sphere
	rock_shape.position.y = 0.42
	rock_body.add_child(rock_shape)
	rock.add_child(rock_body)
	var sourced_model := false
	if resource_id != "ore":
		sourced_model = _add_sourced_model(rock, SOURCED_ROCK_ASSET, 0.55, Vector3(0.0, 0.14, 0.0))
	mesh_instance.visible = not sourced_model
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
	for index in 6:
		var blade := MeshInstance3D.new()
		blade.mesh = _sphere_mesh(0.07, 0.62, 5, 3)
		blade.material_override = _material(palette["leaf"], 0.9)
		blade.position = Vector3((float(index) - 2.5) * 0.18, 0.34, sin(float(index) * 1.6) * 0.18)
		patch.add_child(blade)
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
	guardian.position = position
	guardian.add_to_group("guardian")
	parent.add_child(guardian)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.9
	collision.shape = shape
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
	var scarf := MeshInstance3D.new()
	var scarf_mesh := TorusMesh.new()
	scarf_mesh.inner_radius = 0.28
	scarf_mesh.outer_radius = 0.37
	scarf.mesh = scarf_mesh
	scarf.material_override = _material(Color("#6d9ca5"), 0.74)
	scarf.position.y = 1.3
	visual.add_child(scarf)
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
	_sync_expedition_cargo()
	_refresh_whisperwood_route()
	_refresh_expedition_routes()
	_refresh_route_gate_visuals()
	if player != null:
		player.set("health", health)
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

func _on_session_feedback(kind: String, payload: Dictionary) -> void:
	if kind == "activity":
		_show_toast("Effort logged  |  +%d Activity XP  |  +%d energy" % [int(payload.get("xp", 0)), mini(6, int(payload.get("xp", 0)))], 3.0)
	elif kind == "mastery_unlock":
		_show_toast("Permission unlocked: %s  |  %s" % [str(payload.get("label", "Mastery")), str(payload.get("summary", "New capability available."))], 3.6)
	elif kind == "route_unlock":
		_show_toast("New route opened: %s  |  %s" % [str(payload.get("route", "Unknown")), str(payload.get("requirement", "The road is ready."))], 4.0)
	elif kind == "route_capstone":
		_show_toast("Capstone reached: %s  |  Secure it, then return to the beacon." % str(payload.get("label", "Route objective")), 3.2)

func _record_activity() -> void:
	if get_tree().paused or session == null:
		return
	var receipt := "manual-%d-%d" % [day, Time.get_ticks_msec()]
	var metadata := {"source_id": "manual_ui", "event_id": receipt, "occurred_at": Time.get_datetime_string_from_system(true), "timezone": "local", "mapping_version": 1}
	if session.call("record_activity", receipt, 25, metadata):
		activity_streak += 1
		_show_toast("25 minutes logged. Your real-life effort powers this world.", 3.0)
	else:
		_show_toast("That effort receipt was already claimed.", 2.0)
	session.call("save_game")

func _allocate_best_stat() -> void:
	if get_tree().paused:
		return
	if session != null and session.call("allocate_stat", "Strength"):
		strength = int(session.get("stats").get("Strength", strength))
		_show_toast("Strength increased. Your light attack now hits harder.", 2.4)
		session.call("save_game")
	else:
		_show_toast("No Ability Points available. Log real-life effort to earn one.", 2.4)

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	_show_toast("Paused" if get_tree().paused else "Welcome back", 1.5)
	if toast_label != null:
		toast_label.visible = true

func _toggle_utilities() -> void:
	if get_tree().paused:
		return
	utilities_open = not utilities_open
	_show_toast("Ledger opened: effort, save, and ability points." if utilities_open else "Ledger closed.", 1.4)

func _save_game() -> void:
	_sync_expedition_anchor()
	if session != null and session.call("save_game"):
		_show_toast("Progress saved safely.", 1.7)
	else:
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

func _update_lighting() -> void:
	if sun_light == null:
		return
	var daylight := clampf(sin((hour - 6.0) / 14.0 * PI), 0.12, 1.0)
	sun_light.light_energy = 0.35 + daylight * 0.9
	sun_light.light_color = Color("#ffe8c4").lerp(Color("#8ea6d0"), 1.0 - daylight)

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
	var surface := _current_surface()
	var indoor := current_zone == "Sanctuary" and absf(player.position.x) < 2.15 and player.position.z < -2.0 and player.position.z > -5.8
	var near_furnace := furnace_active and current_zone == "Sanctuary" and player.global_position.distance_to(furnace.global_position) < 6.0
	audio_director.call("set_environment", current_zone, surface, hour, weather, indoor, near_furnace)
	if furnace != null:
		var fire: Node3D = furnace.get_node_or_null("Fire")
		if fire != null:
			fire.visible = furnace_active

func camera_relative_direction(input_vector: Vector2) -> Vector3:
	if camera == null or input_vector.length() <= 0.05:
		return Vector3(input_vector.x, 0.0, input_vector.y)
	var forward := -camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := camera.global_basis.x
	right.y = 0.0
	right = right.normalized()
	return (right * input_vector.x + forward * input_vector.y).normalized()

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
	var total_minutes := int(hour * 60.0)
	var display_hour := int(hour) % 24
	var minute := total_minutes % 60
	day_label.text = "Day %d  |  %02d:%02d" % [day, display_hour, minute]
	energy_bar.value = energy
	health_bar.value = int(player.get("health"))
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
	inventory_label.text = "BANKED\nWood %d  Stone %d  Fiber %d\nOre %d  Shell %d  Gel %d\nFish %d  Wheat %d  Bread %d\nEgg %d  Omelette %d  Tonic %d\nPlank %d  Sun %d  Relic %d\nTOOLS H %d/%d  P %d/%d\nNUTRITION %d  WATER %d\nSATCHEL %d/%d  %s\nCoins %d  XP %d" % [inventory.get("wood", 0), inventory.get("stone", 0), inventory.get("fiber", 0), inventory.get("ore", 0), inventory.get("shell", 0), inventory.get("slime_gel", 0), inventory.get("fish", 0), inventory.get("wheat", 0), inventory.get("bread", 0), inventory.get("egg", 0), inventory.get("omelette", 0), inventory.get("tonic", 0), inventory.get("plank", 0), inventory.get("sunstone", 0), inventory.get("relic", 0), hatchet_state.get("durability", 0), hatchet_state.get("max_durability", 0), pickaxe_state.get("durability", 0), pickaxe_state.get("max_durability", 0), nutrition, hydration, cargo_used, cargo_capacity, cargo_text, coins, xp]
	if mastery_label != null and session != null:
		var stats: Dictionary = session.get("stats")
		var mastery: Dictionary = session.get("masteries")
		mastery_label.text = "LEVEL %d  |  AP %d  |  STR %d  |  DISC %d/%d\nFORAGE %d  FARM %d  CRAFT %d  RESEARCH %d" % [int(session.get("level")), int(session.get("ability_points")), int(stats.get("Strength", 1)), session.get("researched").size(), session.get("discovered").size(), int(mastery.get("Foraging", 0)), int(mastery.get("Farming", 0)), int(mastery.get("Crafting", 0)), int(mastery.get("Research", 0))]
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
				nearby_name = "Fishing Spot"
			elif nearest == trade_stall:
				nearby_name = "Bazaar Trade Stall"
			elif nearest == livestock_pen:
				nearby_name = "Clover's Livestock Pen"
			elif str(nearest.get("station_id")) == "camp":
				nearby_name = "Expedition Camp"
			elif nearest.has_meta("destination_id"):
				nearby_name = "%s Route Gate" % str(nearest.get_meta("destination_id"))
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
		hud_quest_panel.visible = utilities_open or current_zone != "Sanctuary"
	if interact_button != null:
		interact_button.text = "Confirm placement" if placement_mode else "Interact"
		interact_button.disabled = get_tree().paused
	if pause_button != null:
		pause_button.text = "Resume" if get_tree().paused else "Pause"
	if smelt_button != null:
		smelt_button.text = "Stop Furnace" if furnace_active else "Start Furnace"
	var context_node := _nearest_interactable()
	_update_world_label_visibility(context_node)
	var compact_rail := not utilities_open and current_zone == "Sanctuary" and context_node == null
	if hud_right_panel != null:
		hud_right_panel.size.y = 118.0 if compact_rail else maxf(260.0, hud_root.size.y - 28.0)
		hud_right_panel.visible = true
	if hud_right_scroll != null and hud_right_panel != null:
		hud_right_scroll.size = hud_right_panel.size - Vector2(20.0, 20.0)
	if explore_button != null:
		var nearby_route: bool = context_node != null and context_node.has_meta("destination_id")
		explore_button.visible = current_zone == "Sanctuary" and nearby_route
		var nearby_destination := str(context_node.get_meta("destination_id")) if nearby_route else ""
		var nearby_unlocked := nearby_route and session != null and session.has_method("route_is_unlocked") and bool(session.call("route_is_unlocked", nearby_destination))
		explore_button.text = ("Enter %s" % nearby_destination) if nearby_unlocked else ("Route locked: %s" % nearby_destination if nearby_route else "Walk to a route gate")
	if destination_button != null:
		destination_button.visible = false
	if return_button != null:
		return_button.visible = current_zone != "Sanctuary"
		var extraction_point := Vector3(0.0, 1.0, 7.5)
		var at_extraction := current_zone != "Sanctuary" and player != null and player.global_position.distance_to(extraction_point) <= 2.8
		return_button.disabled = not at_extraction
		return_button.text = "Extract cargo" if at_extraction else "Reach extraction beacon"
	if attack_button != null:
		var near_guardian := false
		if current_zone != "Sanctuary" and player != null:
			for guardian_node in get_tree().get_nodes_in_group("guardian"):
				if is_instance_valid(guardian_node) and guardian_node.is_visible_in_tree() and player.global_position.distance_to(guardian_node.global_position) <= 3.8:
					near_guardian = true
					break
		attack_button.visible = near_guardian
	if sleep_button != null:
		var at_hearth := current_zone == "Sanctuary" and furnace != null and player != null and player.global_position.distance_to(furnace.global_position) <= 7.0
		sleep_button.visible = at_hearth
		sleep_button.disabled = not at_hearth
	if dodge_button != null:
		dodge_button.visible = current_zone != "Sanctuary"
	if farm_button != null:
		farm_button.visible = current_zone == "Sanctuary" and context_node == farm_plot
	var field_supplies_available: bool = session != null and session.has_method("has_active_expedition") and bool(session.call("has_active_expedition"))
	if food_button != null:
		food_button.visible = utilities_open or current_zone != "Sanctuary" and field_supplies_available
		food_button.text = "Eat %s  [G]  (%d)" % [selected_food.capitalize(), int(inventory.get(selected_food, 0))]
	if water_button != null:
		water_button.visible = utilities_open or current_zone != "Sanctuary" and field_supplies_available
		water_button.text = "Drink Water  [H]  (%d)" % int(inventory.get("water", 0))
	if livestock_button != null:
		var livestock_context := current_zone == "Sanctuary" and (context_node == livestock_pen or _is_player_structure_kind(context_node, "livestock_pen"))
		livestock_button.visible = livestock_context
		var pen_built := session != null and bool(session.get("built").get("livestock_pen", false))
		livestock_button.text = "Collect / Feed Clover" if pen_built else "Place Livestock Pen Blueprint"
	if repair_button != null:
		repair_button.visible = current_zone == "Sanctuary" and (context_node == workshop or _is_player_structure_kind(context_node, "workshop"))
	if recipe_button != null:
		recipe_button.visible = current_zone == "Sanctuary" and (context_node == workshop or _is_player_structure_kind(context_node, "workshop")) and session != null and bool(session.get("built").get("workshop", false))
		recipe_button.text = "Recipe: %s  [Q]" % selected_recipe.capitalize()
	if structure_button != null:
		structure_button.visible = current_zone == "Sanctuary" and (utilities_open or context_node != null)
		structure_button.text = "Cancel Placement  [B]" if placement_mode else "Place %s  [B]" % _structure_display_name(placement_structure_id)
	if blueprint_button != null:
		blueprint_button.visible = current_zone == "Sanctuary" and (utilities_open or context_node != null)
		blueprint_button.text = "Blueprint: %s  [N]" % _structure_display_name(placement_structure_id)
	if build_button != null:
		var workshop_context := current_zone == "Sanctuary" and (context_node == workshop or _is_player_structure_kind(context_node, "workshop"))
		build_button.visible = workshop_context
		var construction_state := "none"
		if session != null:
			construction_state = str(session.get("construction_job").get("status", "none"))
		if _is_player_structure_kind(context_node, "workshop"):
			var placed_state: Dictionary = session.get("structures").get(str(context_node.get_meta("construction_id")), {}) if session != null else {}
			build_button.text = "Use Workshop" if str(placed_state.get("state", "")) == "operational" else ("Deliver Workshop Materials" if str(placed_state.get("state", "")) == "blueprint" else "Workshop frame in progress")
		else:
			build_button.text = "Workshop Built" if session != null and bool(session.get("built").get("workshop", false)) else ("Finish Workshop" if construction_state == "ready" else ("Building... Sleep to advance" if construction_state == "building" else "Place Workshop Blueprint"))
	if smelt_button != null:
		smelt_button.visible = current_zone == "Sanctuary" and furnace != null and player.global_position.distance_to(furnace.global_position) < 5.0
	if utilities_button != null:
		utilities_button.visible = true
		utilities_button.text = "Close Ledger" if utilities_open else "Open Ledger"
	if activity_button != null:
		activity_button.visible = utilities_open
	if save_button != null:
		save_button.visible = utilities_open
	if stat_button != null:
		stat_button.visible = utilities_open
	if action_hint != null:
		if placement_mode:
			action_hint.text = "Blueprint mode  |  Move to a clear footprint  |  Confirm placement or cancel"
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
				expedition_hint = "%s  |  %s  |  Extract at the beacon" % [branch_text, objective_text]
				if _is_player_in_route_shelter():
					expedition_hint += "  |  Shade pauses heat pressure"
			action_hint.text = expedition_hint
	if hud_right_box != null:
		for child in hud_right_box.get_children():
			if child is Button and child != pause_button:
				(child as Button).disabled = get_tree().paused

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
	interaction_marker.global_position = target.global_position + Vector3(0.0, 0.05, 0.0)
	interaction_marker.rotation.y += delta * 1.8
	interaction_marker.scale = Vector3.ONE * (1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.06)

func _show_toast(message: String, duration := 2.4) -> void:
	if toast_label == null:
		return
	toast_label.text = message
	toast_timer = duration

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
	var nearest_distance := 2.35
	for candidate in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(candidate) or not candidate.is_visible_in_tree():
			continue
		var resource_node := candidate as Node3D
		if resource_node == null:
			continue
		var distance := player.global_position.distance_to(resource_node.global_position)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest

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
		var nearby := player.global_position.distance_to(anchor.global_position) <= 3.6
		label.visible = anchor == focus or nearby

func _interact() -> void:
	if get_tree().paused:
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

func _is_player_structure_kind(node: Node, kind: String) -> bool:
	return node != null and node.has_meta("construction_id") and str(node.get_meta("structure_kind", "")) == kind

func _workshop_contextual_action() -> void:
	if get_tree().paused:
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
	if get_tree().paused:
		return
	if placement_mode:
		_place_structure()
	else:
		_interact()

func _construction_interact(structure_node: Node3D) -> void:
	if structure_node == null or session == null or not structure_node.has_meta("construction_id"):
		return
	var instance_id := str(structure_node.get_meta("construction_id"))
	var structure: Dictionary = session.get("structures").get(instance_id, {})
	var state := str(structure.get("state", "removed"))
	var kind := str(structure.get("kind", ""))
	if state == "operational":
		if kind == "workshop":
			_workshop_use(structure_node)
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
		if audio_director != null:
			audio_director.call("play_action_at", "build", structure_node.global_position)
		_spawn_material_delivery_feedback(str(material_id), structure_node)
		var new_state := str(delivered_structure.get("state", "blueprint"))
		_refresh_structure_visual(instance_id, delivered_structure)
		if not bool(session.call("save_game")):
			if not before_delivery.is_empty():
				session.call("restore_state", before_delivery)
			_copy_session_to_runtime()
			_refresh_structure_visuals()
			_show_toast("The material delivery could not be secured. Nothing was consumed.", 3.0)
			return
		if new_state == "building":
			_show_toast("Scaffold complete. Sleep to finish the %s frame." % _structure_display_name(kind), 3.0)
		else:
			_show_toast("Delivered %d %s. The scaffold now shows the material on site." % [delivery_amount, str(material_id).capitalize()], 2.0)
		return

func collect_resource(node: Node) -> bool:
	var id: String = str(node.get("resource_id"))
	var amount: int = int(node.get("resource_amount"))
	var resource_label: String = str(node.get("resource_label"))
	var discovery_id: String = str(node.get("discovery_id"))
	var collected := false
	if not _route_resource_is_available(node):
		return false
	if current_zone != "Sanctuary" and not discovery_id.is_empty() and session != null and session.has_method("can_record_expedition_discovery") and not bool(session.call("can_record_expedition_discovery", discovery_id)):
		_show_toast("That discovery lies on the closed trail. Your committed route cannot reach it.", 2.5)
		return false
	if current_zone != "Sanctuary" and session != null and session.has_method("can_carry_expedition_amount") and not session.call("can_carry_expedition_amount", amount):
		_show_toast("Your expedition satchel is full. Return to the beacon or leave something behind.", 2.6)
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
		if session != null:
			if not session.call("spend_resource_contact", id):
				return false
		elif not _consume_energy(1):
			return false
		var contact_complete := true
		if node.has_method("apply_contact"):
			contact_complete = node.call("apply_contact")
		if not contact_complete:
			_show_toast("Contact %d / %d  |  Keep your footing." % [int(node.get("contacts")), int(node.get("required_contacts"))], 1.5)
			if audio_director != null:
				audio_director.call("play_action_at", "gather_wood", node.global_position)
			if session != null:
				session.call("record_sanctuary_contact", str(node.get("node_id")), int(node.get("contacts")))
				session.call("award_mastery", "Foraging", 1)
				session.call("save_game")
			return true
		if session != null:
			session.call("add_item", id, amount)
			session.call("mark_sanctuary_depleted", str(node.get("node_id")))
		else:
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
				_show_toast("Contact %d / %d  |  The forest is listening." % [int(node.get("contacts")), required_contacts], 1.5)
				if audio_director != null:
					audio_director.call("play_action_at", "gather_wood", node.global_position)
				if session != null:
					session.call("record_expedition_contact", node_id, int(node.get("contacts")))
					session.call("award_mastery", "Foraging", 1)
					session.call("save_game")
				return true
			collected = session != null and session.call("complete_expedition_resource", node_id, id, amount, required_contacts)
		else:
			if session == null or node_id.is_empty() or not session.call("collect_expedition_resource_with_tool", node_id, id, amount):
				return false
			collected = true
		if not collected:
			return false
	if not collected:
		return false
	if node.has_method("complete_depletion"):
		node.call("complete_depletion")
	var mastery_name := "Mining" if id in ["stone", "ore", "sunstone"] else "Foraging"
	var new_discovery := false
	_sync_expedition_cargo()
	if session != null:
		session.call("award_xp", amount * 2)
		session.call("award_mastery", mastery_name, amount * 3)
		if not discovery_id.is_empty() and session.call("record_discovery", discovery_id):
			new_discovery = true
			_show_toast("Discovery: %s  |  Return to the Archive to understand it." % discovery_id, 3.2)
	if audio_director != null:
		audio_director.call("play_action_at", "gather_" + id, node.global_position)
	_spawn_feedback_burst(node.global_position, palette["leaf"] if mastery_name == "Foraging" else palette["stone"])
	if not new_discovery:
		_show_toast("+%d %s  |  %s mastery +%d" % [amount, resource_label, mastery_name, amount * 3], 2.2)
	if current_zone != "Sanctuary":
		player_made_noise(node.global_position, 7.0 if id in ["ore", "stone"] else 5.0)
	if session != null:
		session.call("save_game")
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
	if resource_action_node != null or node == null or not is_instance_valid(node):
		return
	if not _route_resource_is_available(node):
		return
	if current_zone == "Sanctuary" and player.global_position.distance_to(node.global_position) > 2.35:
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
	var resource_label := str(node.get("resource_label"))
	_show_toast("Gathering %s... hold your ground." % (resource_label if not resource_label.is_empty() else resource_id), 0.8)
	if player != null and player.has_method("play_gather_feedback"):
		player.call("play_gather_feedback")
	if audio_director != null:
			audio_director.call("play_action_at", "gather_prepare", node.global_position)

func _update_resource_action(delta: float) -> void:
	if resource_action_node == null:
		return
	if not is_instance_valid(resource_action_node) or not resource_action_node.is_visible_in_tree():
		_cancel_resource_action()
		return
	if player.global_position.distance_to((resource_action_node as Node3D).global_position) > 2.55:
		_cancel_resource_action()
		_show_toast("Gathering interrupted.", 1.4)
		return
	resource_action_elapsed += delta
	if resource_action_elapsed < resource_action_duration:
		return
	var completed_node := resource_action_node
	resource_action_node = null
	resource_action_elapsed = 0.0
	if player != null and player.has_method("finish_gather_feedback"):
		player.call("finish_gather_feedback")
	collect_resource(completed_node)

func _cancel_resource_action() -> void:
	resource_action_node = null
	resource_action_elapsed = 0.0
	if player != null and player.has_method("cancel_gather_feedback"):
		player.call("cancel_gather_feedback")

func farm_plot_interact(plot: Node) -> void:
	if current_zone != "Sanctuary" or plot == null:
		return
	if player.global_position.distance_to(plot.global_position) > 2.35:
		_show_toast("Move closer to the Garden Plot first.", 1.8)
		return
	if session == null or not session.has_method("interact_farm"):
		return
	var result: Dictionary = session.call("interact_farm")
	if not bool(result.get("ok", false)):
		match str(result.get("reason", "")):
			"bed_cost": _show_toast("Garden bed needs 1 Wood + 2 Fiber, plus energy.", 2.3)
			"seed": _show_toast("You need a wheat seed and enough energy.", 2.2)
			"water": _show_toast("The pond can refill your water pouch.", 2.2)
			"energy": _show_toast("You are too tired to work the garden.", 2.0)
			_: _show_toast("The crop is growing. Water once, then give it time.", 2.0)
		return
	_copy_session_to_runtime()
	match str(result.get("action", "")):
		"tilled": _show_toast("The soil is ready. Press E again to plant wheat.", 2.4)
		"planted": _show_toast("Wheat planted. Water it, then sleep to grow it.", 2.5)
		"harvested": _show_toast("Harvested 3 Wheat  |  Farming mastery +12", 2.8)
		"watered": _show_toast("Watered. The next sleep will move the crop forward.", 2.5)
	session.call("save_game")
	_refresh_farm_plot()

func station_interact(station: Node) -> void:
	if station == null:
		return
	if session == null:
		return
	var station_id := str(station.get("station_id"))
	if station_id not in ["camp", "whisper_branch", "whisper_cache", "map_branch", "map_capstone"] and current_zone != "Sanctuary":
		return
	if player.global_position.distance_to(station.global_position) > 2.35:
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
	if station_id == "guide":
		_guide_interact()
		return
	if station_id == "fishing":
		_fishing_interact()
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
	if source == workshop and _has_operational_player_structure("workshop"):
		_show_toast("This is the old workshop shell. Use the Workshop you placed in the Sanctuary.", 2.6)
		return
	if not bool(session.get("built").get("workshop", false)):
		_show_toast("This is a shell. Place and finish a Workshop blueprint first.", 2.5)
		return
	var job: Dictionary = session.get("station_job")
	if str(job.get("kind", "none")) != "none":
		if float(job.get("remaining_hours", 0.0)) > 0.0:
			_show_toast("Workshop is working. Sleep to finish the job.", 2.2)
			return
		var claimed: Dictionary = session.call("claim_workshop_job")
		if not claimed.is_empty():
			_show_toast("Workshop complete  |  +%d %s" % [int(claimed.get("output", 0)), str(claimed.get("output_id", "")).capitalize()], 2.6)
	else:
		var recipe_id := selected_recipe
		var recipe: Dictionary = ContentRegistry.workshop_recipe(recipe_id)
		var recipe_text := str(recipe.get("summary", "The recipe is incomplete."))
		var started: Dictionary = session.call("start_workshop_job", recipe_id)
		if started.is_empty():
			_show_toast("Workshop recipe: %s." % recipe_text, 2.5)
			return
		_show_toast("%s job started. Sleep once, then claim it here." % recipe_id.capitalize(), 2.5)
	session.call("save_game")
	_refresh_station_visual()

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
	if get_tree().paused or session == null or (current_zone != "Sanctuary" and not session.call("has_active_expedition")):
		return
	var food_id := selected_food if int(inventory.get(selected_food, 0)) > 0 else ""
	if food_id.is_empty():
		_cycle_food_selection()
		food_id = selected_food if int(inventory.get(selected_food, 0)) > 0 else ""
	if food_id.is_empty() or not session.call("consume_food", food_id):
		_show_toast("You have no ready food. Fish, harvest, or cook at the Workshop.", 2.6)
		return
	_show_toast("Ate %s  |  Energy and nutrition restored." % food_id.capitalize(), 2.2)
	if audio_director != null:
		audio_director.call("play_action", "eat")
	session.call("save_game")

func _cycle_recipe_selection() -> void:
	if get_tree().paused or session == null:
		return
	var options := ["plank", "bread", "omelette"]
	if session.get("unlocked_features").has("tonic_recipe"):
		options.append("tonic")
	var start := options.find(selected_recipe)
	selected_recipe = options[(start + 1) % options.size()]
	_show_toast("Workshop recipe selected: %s" % selected_recipe.capitalize(), 1.6)

func _drink_water() -> void:
	if get_tree().paused or session == null or (current_zone != "Sanctuary" and not session.call("has_active_expedition")):
		return
	if not session.call("drink_water"):
		_show_toast("Your water pouch is empty, or you are already hydrated.", 2.3)
		return
	_show_toast("Drank from your water pouch  |  Hydration restored.", 2.0)
	if audio_director != null:
		audio_director.call("play_action", "drink")
	session.call("save_game")

func _repair_tools() -> void:
	if get_tree().paused or current_zone != "Sanctuary" or session == null:
		return
	var repaired := ""
	for tool_id in ["hatchet", "pickaxe", "fishing_knife"]:
		if session.call("repair_tool", tool_id):
			repaired = tool_id
			break
	if repaired.is_empty():
		_show_toast("Tools are ready, or you need Planks to repair them.", 2.3)
		return
	_show_toast("Repaired %s  |  Planks consumed." % repaired.replace("_", " ").capitalize(), 2.3)
	if audio_director != null:
		audio_director.call("play_action", "repair")
	session.call("save_game")

func _livestock_interact(station: Node) -> void:
	if current_zone != "Sanctuary" or session == null or station == null:
		return
	if player.global_position.distance_to(station.global_position) > 2.35:
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
	var collected: Dictionary = session.call("collect_livestock", "clover")
	if not collected.is_empty():
		_show_toast("Collected %d Egg  |  Livestock mastery +8" % int(collected.get("egg", 0)), 2.5)
		if audio_director != null:
			audio_director.call("play_action", "collect")
		_refresh_livestock_visual()
		session.call("save_game")
		return
	if session.call("feed_livestock", "clover"):
		_show_toast("Fed Clover  |  Sleep to let the pen produce.", 2.4)
		_refresh_livestock_visual()
		session.call("save_game")
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
	marker.text = "CLOVER\n" + state

func _fishing_interact() -> void:
	if current_zone != "Sanctuary" or session == null:
		return
	if not session.call("has_items", {"fiber": 1}):
		_show_toast("Fishing needs 1 Fiber for bait. Gather reeds or cactus fiber first.", 2.4)
		return
	if not _consume_energy(2):
		return
	if not session.call("remove_item", "fiber", 1):
		return
	var catch_amount := 2 if weather == "rain" else 1
	session.call("add_item", "fish", catch_amount)
	session.call("award_xp", 8 + catch_amount * 2)
	session.call("award_mastery", "Fishing", 8)
	if audio_director != null:
		audio_director.call("play_action", "gather_water")
	_show_toast("Fishing catch  |  +%d Fish  |  Fishing mastery +8" % catch_amount, 2.8)
	session.call("save_game")

func _bazaar_interact() -> void:
	if current_zone != "Sanctuary" or session == null:
		return
	var selected_offer: Dictionary = {}
	for offer in ContentRegistry.TRADE_OFFERS:
		var offer_cost: Dictionary = offer.get("cost", {})
		if session.call("has_items", offer_cost):
			selected_offer = offer
			break
	if selected_offer.is_empty():
		_show_toast("Bazaar wants 2 Fish + 1 Water, 1 Shell + 1 Plank, or 3 Wheat.", 2.8)
		return
	var trade_name := str(selected_offer.get("id", "trade")).replace("_", " ")
	var result: Dictionary = session.call("resolve_trade_offer", str(selected_offer.get("id", "")))
	if result.is_empty():
		return
	var payout := int(result.get("payout", 0))
	_show_toast("Traded %s  |  +%d Coins  |  Trading mastery +8" % [trade_name, payout], 2.8)
	session.call("save_game")

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
		_show_toast("The Archive is quiet. Discover something new on an expedition.", 2.4)
		return
	var research_job: Dictionary = session.get("research_job")
	if str(research_job.get("status", "idle")) == "researching":
		_show_toast("The Archive is studying %s. Sleep once to finish the research." % str(research_job.get("discovery_id", next_discovery)), 2.5)
		return
	if str(research_job.get("status", "idle")) == "ready":
		var understood_id := str(research_job.get("discovery_id", next_discovery))
		if session.call("claim_research"):
			if audio_director != null:
				var research_anchor: Node3D = source if source != null else library_station
				if research_anchor != null:
					audio_director.call("play_action_at", "discovery", research_anchor.global_position)
			_show_toast("Understood: %s  |  %s added." % [understood_id, ContentRegistry.discovery_blueprint(understood_id)], 3.0)
			session.call("save_game")
			_refresh_station_visual()
		return
	if not _consume_energy(1):
		return
	if session.call("research_discovery", next_discovery):
		if audio_director != null:
			audio_director.call("play_action", "discovery")
		_show_toast("Research started: %s  |  Sleep once to complete it." % next_discovery, 3.0)
		session.call("save_game")
		_refresh_station_visual()

func _notice_board_interact() -> void:
	if session == null:
		return
	var current_quest: Dictionary = session.get("quest")
	var progress := int(current_quest.get("progress", 0))
	var target := int(current_quest.get("target", 5))
	if bool(current_quest.get("claimed", false)):
		_show_toast("The board is quiet. A new contract will arrive tomorrow.", 2.2)
		return
	if progress >= target and session.call("claim_quest"):
		if audio_director != null:
			audio_director.call("play_action", "quest")
		_show_toast("Contract complete  |  +45 Coins  |  +25 XP", 2.8)
		session.call("save_game")
	else:
		_show_toast("Contract: return from an expedition with %d more cargo." % maxi(0, target - progress), 2.4)

func _camp_interact() -> void:
	if session == null or current_zone == "Sanctuary":
		return
	if session.call("use_expedition_camp"):
		if audio_director != null:
			audio_director.call("play_action", "camp")
		_show_toast("You make camp and recover 6 Energy. The fire can only save this run once.", 3.0)
		session.call("save_game")
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
	if session.call("commit_expedition_branch", branch_id):
		if not bool(session.call("save_game")):
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
			library_marker.text = "ARCHIVE\n" + ("STARTER PAD" if _has_operational_player_structure("archive") else ("OPEN" if bool(session.get("built").get("library", false)) else "SHELL"))

func _structure_display_name(structure_id: String) -> String:
	match structure_id:
		"rain_cistern": return "Rain Cistern"
		"workshop": return "Workshop"
		"archive": return "Archive"
		"livestock_pen": return "Livestock Pen"
		"storage_shed": return "Storage Shed"
	return structure_id.replace("_", " ").capitalize()

func _cycle_structure_selection() -> void:
	if current_zone != "Sanctuary" or placement_mode:
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
	if get_tree().paused or current_zone != "Sanctuary" or session == null:
		return
	if placement_mode:
		placement_mode = false
		if build_marker != null:
			build_marker.visible = false
		_show_toast("Placement cancelled.", 1.4)
		return
	if not session.has_method("has_structure_blueprint") or not bool(session.call("has_structure_blueprint", placement_structure_id)):
		var requirement := str(session.call("structure_blueprint_requirement", placement_structure_id)) if session.has_method("structure_blueprint_requirement") else "a new discovery"
		_show_toast("Blueprint locked. Decode %s at the Archive first." % requirement, 2.8)
		return
	for existing_id in session.get("structures"):
		var existing: Dictionary = session.get("structures").get(existing_id, {})
		if str(existing.get("kind", "")) == placement_structure_id and str(existing.get("state", "")) != "removed":
			_show_toast("A %s is already part of this Sanctuary." % _structure_display_name(placement_structure_id), 2.0)
			return
	placement_mode = true
	_update_structure_preview()
	_show_toast("Place the %s blueprint on a clear grid cell. Press E to confirm or B to cancel." % _structure_display_name(placement_structure_id), 3.0)

func _preview_structure_cell() -> Vector2i:
	var direction := player.get("last_direction") as Vector3
	if direction.length_squared() < 0.01:
		direction = Vector3(0.0, 0.0, -1.0)
	return SettlementGrid.world_to_cell(player.global_position + direction.normalized() * 3.0)

func _structure_preview_valid(cell: Vector2i) -> bool:
	if session == null or not session.call("can_place_structure", placement_structure_id, [cell.x, cell.y]):
		return false
	var footprint_data: Array = ContentRegistry.structure_definition(placement_structure_id).get("footprint", [1, 1])
	var footprint := Vector2i(int(footprint_data[0]), int(footprint_data[1]))
	for occupied_cell in SettlementGrid.cells_for(cell, footprint):
		if SettlementGrid.cell_to_world(occupied_cell).distance_to(player.global_position) < 1.5:
			return false
	return true

func _update_structure_preview() -> void:
	if not placement_mode or current_zone != "Sanctuary" or player == null:
		if build_marker != null:
			build_marker.visible = false
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
	var footprint_data: Array = ContentRegistry.structure_definition(placement_structure_id).get("footprint", [1, 1])
	var footprint := Vector2i(int(footprint_data[0]), int(footprint_data[1]))
	var ghost_mesh := build_marker.get_node_or_null("GhostFootprint") as MeshInstance3D
	if ghost_mesh != null:
		var footprint_box := ghost_mesh.mesh as BoxMesh
		if footprint_box != null:
			footprint_box.size = Vector3(float(footprint.x), 0.08, float(footprint.y))
	build_marker.visible = true
	build_marker.global_position = SettlementGrid.footprint_center_to_world(cell, footprint)
	var valid := _structure_preview_valid(cell)
	if ghost_mesh != null:
		ghost_mesh.material_override = _material(palette["leaf"] if valid else palette["danger"], 0.3, true, true)
	var ghost_label := build_marker.get_node_or_null("GhostLabel") as Label3D
	if ghost_label != null:
		ghost_label.text = "PLACE" if valid else "BLOCKED"

func _place_structure() -> void:
	if get_tree().paused or not placement_mode or session == null or current_zone != "Sanctuary":
		return
	var cell := _preview_structure_cell()
	if not _structure_preview_valid(cell):
		_show_toast("That footprint is blocked. Find a clear patch of Sanctuary.", 2.0)
		return
	var before_placement: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var placed: Dictionary = session.call("place_structure", placement_structure_id, [cell.x, cell.y])
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
	var footprint_data: Array = ContentRegistry.structure_definition(kind).get("footprint", [1, 1])
	var footprint := Vector2i(int(footprint_data[0]), int(footprint_data[1]))
	var footprint_width := maxf(1.8, float(footprint.x) - 0.2)
	var footprint_depth := maxf(1.8, float(footprint.y) - 0.2)
	var structure_height := 2.05
	if kind in ["rain_cistern", "livestock_pen"]:
		structure_height = 1.65
	elif kind == "workshop":
		structure_height = 2.18
	elif kind == "storage_shed":
		structure_height = 1.78
	structure.position = SettlementGrid.footprint_center_to_world(Vector2i(int(cell_data[0]), int(cell_data[1])), footprint)
	sanctuary_zone.add_child(structure)
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
	var utility := Node3D.new()
	utility.name = "StructureUtility"
	structure.add_child(utility)
	_create_structure_utility_visual(utility, kind, footprint_width, footprint_depth, structure_height)
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(footprint_width, structure_height + 0.22, footprint_depth)
	collision.shape = shape
	collision.position.y = 0.11 + (structure_height + 0.22) * 0.5
	body.add_child(collision)
	structure.add_child(body)
	settlement_visuals[instance_id] = structure
	_refresh_structure_visual(instance_id, data)

func _structure_base_color(kind: String) -> Color:
	match kind:
		"workshop": return Color("#737d78")
		"storage_shed": return Color("#9d9b83")
	return palette["stone"]

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
		gabled_roof.visible = state == "operational" and kind in ["workshop", "storage_shed", "archive"]
	var timber_frame := structure.get_node_or_null("TimberFrame") as Node3D
	if timber_frame != null:
		timber_frame.visible = state == "operational" and kind in ["workshop", "storage_shed", "archive"]
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
	if finished_walls != null:
		finished_walls.visible = state == "operational"
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
			material_progress = maxf(material_progress, 1.0 - clampf(float(data.get("remaining_hours", 0.0)) / maxf(1.0, float(data.get("total_hours", 24.0))), 0.0, 1.0))
		for index in scaffold.get_child_count():
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
	var nearest_distance := 2.35
	for candidate in get_tree().get_nodes_in_group("route_gate"):
		if not is_instance_valid(candidate) or not candidate.is_visible_in_tree():
			continue
		var gate := candidate as Node3D
		if gate == null or player == null:
			continue
		var distance := player.global_position.distance_to(gate.global_position)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest

func _route_gate_interact(station: Node) -> void:
	if current_zone != "Sanctuary" or station == null:
		return
	if player == null or player.global_position.distance_to(station.global_position) > 2.35:
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
	if player == null or player.global_position.distance_to(extraction_point) > 2.8:
		_show_toast("Reach the expedition beacon before extracting your cargo.", 2.5)
		return
	_sync_expedition_anchor()
	var before_extract: Dictionary = session.call("snapshot_state") if session != null and session.has_method("snapshot_state") else {}
	if session != null and session.has_method("finish_expedition"):
		session.call("finish_expedition")
		if not bool(session.call("save_game")):
			if not before_extract.is_empty():
				session.call("restore_state", before_extract)
			_copy_session_to_runtime()
			_show_toast("Extraction could not be secured to disk. Your cargo remains in the run.", 3.0)
			return
	_set_zone("Sanctuary")
	_copy_session_to_runtime()
	expedition_loot = {}
	_show_toast("The Sanctuary is safe. Expedition cargo is banked.", 2.5)

func _set_zone_collisions(root: Node, active: bool) -> void:
	if root == null:
		return
	for child in root.get_children():
		if child is CollisionShape3D:
			child.disabled = not active
		_set_zone_collisions(child, active)

func _set_zone(zone: String) -> void:
	current_zone = zone
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

func _restore_active_expedition_nodes() -> void:
	if session == null:
		return
	var depleted: Array = []
	var defeated_guardians: Array = []
	var expedition_contact_progress: Dictionary = {}
	if session.has_method("has_active_expedition") and session.call("has_active_expedition"):
		var run: Dictionary = session.get("expedition_run")
		depleted = run.get("depleted_ids", [])
		defeated_guardians = run.get("defeated_guardian_ids", [])
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
			guardian_node.call("set_defeated_from_save", defeated_guardians.has(str(guardian_node.get("guardian_id"))))
	_refresh_whisperwood_route()

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
		"Sanctuary": return Color("#8fc1bf")
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
	if furnace != null and player.global_position.distance_to(furnace.global_position) > 7.0:
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
	if not bool(player.call("can_dodge")):
		_show_toast("Dodge is still recovering.", 1.0)
		return
	if session != null and not session.call("spend_energy", 1):
		_show_toast("You need 1 Energy to dodge. Find a camp or return home.", 2.0)
		return
	if bool(player.call("start_dodge")):
		camera_shake = 0.04
		if audio_director != null:
			audio_director.call("play_action", "dodge")
		_show_toast("Dodge", 0.55)

func _player_attack(_actor: Node) -> void:
	if get_tree().paused or attack_cooldown > 0.0 or pending_attack_target != null:
		return
	if current_zone != "Sanctuary" and session != null and session.has_method("has_active_expedition") and session.call("has_active_expedition"):
		var run: Dictionary = session.get("expedition_run")
		if str(run.get("branch_id", "")).is_empty():
			_show_toast("Choose a trail before engaging the guardian.", 2.4)
			return
	attack_cooldown = 0.42
	var target: Node = null
	var distance := 3.6
	for candidate in get_tree().get_nodes_in_group("guardian"):
		if not is_instance_valid(candidate) or not candidate.is_visible_in_tree():
			continue
		var candidate_body := candidate as Node3D
		if candidate_body == null:
			continue
		var candidate_distance := player.global_position.distance_to(candidate_body.global_position)
		var to_candidate: Vector3 = (candidate_body.global_position - player.global_position).normalized()
		var facing := float(player.get("last_direction").dot(to_candidate))
		if candidate_distance < distance and facing > 0.15:
			target = candidate
			distance = candidate_distance
	if target == null:
		_show_toast("Your attack cuts the air. Move closer to a threat.", 1.4)
		return
	pending_attack_target = target
	attack_action_elapsed = 0.0
	if player != null and player.has_method("play_attack_feedback"):
		player.call("play_attack_feedback")

func _update_attack_action(delta: float) -> void:
	if pending_attack_target == null:
		return
	attack_action_elapsed += delta
	if attack_action_elapsed < 0.12:
		return
	var target := pending_attack_target
	pending_attack_target = null
	attack_action_elapsed = 0.0
	if not is_instance_valid(target) or not target.is_visible_in_tree():
		return
	player_made_noise(player.global_position, 5.0)
	var damage := 7 + strength * 2
	if session != null and session.has_method("resolve_attack_damage"):
		damage = int(session.call("resolve_attack_damage", damage))
	target.call("take_damage", damage)
	camera_shake = 0.06
	if audio_director != null:
		audio_director.call("play_action_at", "hit", target.global_position)

func combat_feedback(target: Node, amount: int) -> void:
	# Combat mastery is awarded once the authoritative guardian reward settles.
	# Keeping hit feedback presentation-only prevents a rejected final blow (full
	# cargo or failed persistence) from becoming a repeatable mastery exploit.
	camera_shake = 0.08
	_show_toast("Impact  |  %s -%d HP" % [str(target.get("enemy_label")), amount], 1.0)

func guardian_attack(guardian: Node) -> void:
	var guardian_body := guardian as Node3D
	if guardian_body == null or player.global_position.distance_to(guardian_body.global_position) > 2.7:
		return
	if float(player.get("invulnerable_time")) > 0.0:
		if audio_director != null:
			audio_director.call("play_action", "dodge")
		_show_toast("Clean dodge", 0.9)
		return
	player.call("take_damage", maxi(1, int(guardian.get("attack_damage"))))
	if audio_director != null:
		audio_director.call("play_action_at", "hit", guardian_body.global_position)

func guardian_defeated(guardian: Node) -> bool:
	var guardian_id := str(guardian.get("guardian_id"))
	var reward_id := str(guardian.get("reward_id"))
	var reward_amount := int(guardian.get("reward_amount"))
	var enemy_name := str(guardian.get("enemy_label"))
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
	_show_toast("%s defeated  |  +%d %s  |  Combat mastery +12" % [enemy_name, reward_amount, reward_id.replace("_", " ").capitalize()], 3.0)
	return true

func player_took_damage(amount: int) -> void:
	if session != null and player != null and session.has_method("apply_player_damage"):
		var before_damage: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
		var result: Dictionary = session.call("apply_player_damage", amount)
		player.set("health", int(result.get("health", player.get("health"))))
		if bool(result.get("fainted", false)):
			if current_zone == "Sanctuary":
				session.call("reset_player_health")
				player.set("health", int(session.get("health")))
			else:
				player_fainted(before_damage)
	_show_toast("You took %d damage. Read the guardian's movement before engaging." % amount, 1.8)

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

func player_moved(moving: bool) -> void:
	if moving and resource_action_node != null:
		_cancel_resource_action()
		_show_toast("Gathering interrupted.", 1.4)
	if not moving or footstep_timer > 0.0 or audio_director == null:
		return
	footstep_timer = 0.27
	audio_director.call("play_action_at", "step_" + _current_surface(), player.global_position)

func player_made_noise(position: Vector3, intensity: float) -> void:
	if current_zone == "Sanctuary":
		return
	for guardian_node in get_tree().get_nodes_in_group("guardian"):
		if not is_instance_valid(guardian_node) or not guardian_node.is_visible_in_tree():
			continue
		if _zone_for_node(guardian_node) == current_zone.replace(" ", "") and guardian_node.has_method("hear_noise"):
			guardian_node.call("hear_noise", position, intensity)

func recover_loot(pack_id: String) -> bool:
	if session == null or pack_id.is_empty():
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
