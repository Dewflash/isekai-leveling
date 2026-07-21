class_name ProdewtyBuildingInterior
extends Node3D

const AssetMeasurement := preload("res://scripts/sanctuary_asset_measurement.gd")
const ContentRegistry := preload("res://scripts/content_registry.gd")
const InteriorGrid := preload("res://scripts/interior_grid.gd")

## Playable building interiors are presentation/runtime rooms, not a second
## gameplay save. The GameSession still owns ownership, upgrades, queues, and
## inventory; this node owns the visible room, its measured interaction proxies,
## and the short transition used to enter and leave it.

const FLOOR_Y := 0.0
const TOON_WOOD_MATERIAL_PATH := "res://assets/generated/shaders/sanctuary_toon_wood.tres"
const TOON_SPRITE_MATERIAL_PATH := "res://assets/generated/shaders/sanctuary_toon_sprite.tres"
const ILLUSTRATED_SHELL_TEXTURE_PATH := "res://assets/generated/sanctuary/workshop/workshop-interior-shell.png"
const WORKSHOP_STATION_SHEET_PATH := "res://assets/generated/sanctuary/workshop/workshop-station-sheet.png"

var host_world: Node3D
var room_root: Node3D
var room_shell: Node3D
var stations: Dictionary = {}
var animated_fire: Array[Dictionary] = []
var animated_smoke: Array[Dictionary] = []
var animated_wheel: Node3D
var elapsed := 0.0
var active := false
var transitioning := false
var active_kind := ""
var active_instance_id := ""
var room_size := Vector2.ZERO
var room_height := 0.0
var door_width := 0.0
var cell_size := 1.0
var wall_clearance := 0.45
var door_clearance_depth := 0.85
var door_facing := Vector3(0.0, 0.0, 1.0)
var configured_profile_id := ""
var room_measurements_valid := false
var illustrated_shell_width_ratio := 1.0
var toon_wood_material: ShaderMaterial
var toon_sprite_material: ShaderMaterial
var illustrated_shell: Sprite3D
var workshop_station_sheet: Texture2D
var station_preview: Node3D
var fade_layer: CanvasLayer
var fade_rect: ColorRect

func build(world: Node3D) -> void:
	if world == null or room_root != null:
		return
	host_world = world
	name = "BuildingInteriorController"
	process_mode = Node.PROCESS_MODE_PAUSABLE
	world.add_child(self)
	_apply_layout(ContentRegistry.interior_layout("workshop"))
	toon_wood_material = load(TOON_WOOD_MATERIAL_PATH) as ShaderMaterial
	toon_sprite_material = load(TOON_SPRITE_MATERIAL_PATH) as ShaderMaterial
	workshop_station_sheet = load(WORKSHOP_STATION_SHEET_PATH) as Texture2D
	_build_transition_overlay()
	_build_workshop_room()
	room_root.visible = false
	room_measurements_valid = _validate_room_measurements()
	_set_room_collisions(false)

func configure_for_structure(kind: String, measurement: Dictionary, access_zones: Array, interior_profile: Dictionary = {}) -> bool:
	# Room dimensions come from the same measured exterior envelope that owns the
	# placed building's collision. The small inset is derived as a shared interior
	# clearance; no Workshop-specific room rectangle is allowed to drift from the
	# exterior claim.
	if kind != "workshop" or not bool(measurement.get("valid", false)):
		return false
	var fitted_size: Vector3 = measurement.get("fitted_size", Vector3.ZERO)
	if fitted_size.x <= 0.01 or fitted_size.y <= 0.01 or fitted_size.z <= 0.01:
		return false
	var entry_zone_id := str(interior_profile.get("entry_zone_id", ""))
	var door_zone := _access_zone_by_id(access_zones, entry_zone_id) if not entry_zone_id.is_empty() else _first_access_zone(access_zones, "door")
	if door_zone.is_empty():
		return false
	if str(door_zone.get("kind", "")) != "door":
		return false
	var authored_door_size: Array = door_zone.get("size", [])
	if authored_door_size.size() < 2:
		return false
	var next_room_size := Vector2(fitted_size.x - 0.34, fitted_size.z - 0.34)
	if next_room_size.x < 3.4 or next_room_size.y < 3.0:
		return false
	var ceiling_ratio := clampf(float(interior_profile.get("ceiling_height_ratio", 0.82)), 0.60, 0.94)
	var next_illustrated_shell_width_ratio := clampf(float(interior_profile.get("illustrated_shell_width_ratio", 1.0)), 0.90, 1.80)
	var next_room_height := minf(fitted_size.y - 0.24, fitted_size.y * ceiling_ratio)
	if next_room_height < 2.75:
		return false
	var next_door_width := clampf(float(authored_door_size[0]), 0.95, next_room_size.x - 0.70)
	var next_door_facing := _array_to_vector3(door_zone.get("facing", [0.0, 0.0, 1.0]))
	if next_door_facing.length_squared() < 0.01:
		next_door_facing = Vector3(0.0, 0.0, 1.0)
	else:
		next_door_facing = next_door_facing.normalized()
	var next_profile_id := "%s|%s|%.3f|%.3f|%.3f|%.3f|%.3f" % [kind, str(measurement.get("source_path", "")), next_room_size.x, next_room_size.y, next_room_height, next_door_width, next_illustrated_shell_width_ratio]
	if next_profile_id == configured_profile_id:
		return room_measurements_valid
	if active or transitioning:
		return false
	room_size = next_room_size
	room_height = next_room_height
	door_width = next_door_width
	illustrated_shell_width_ratio = next_illustrated_shell_width_ratio
	door_facing = next_door_facing
	configured_profile_id = next_profile_id
	_clear_room()
	_build_workshop_room()
	room_root.visible = false
	room_measurements_valid = _validate_room_measurements()
	_set_room_collisions(false)
	room_root.set_meta("measured_exterior_size_m", [fitted_size.x, fitted_size.y, fitted_size.z])
	room_root.set_meta("door_width_m", door_width)
	room_root.set_meta("grid_cell_size_m", cell_size)
	room_root.set_meta("grid_wall_clearance_m", wall_clearance)
	room_root.set_meta("measurement_source", str(measurement.get("source_path", "")))
	return room_measurements_valid

func supports_kind(kind: String) -> bool:
	return kind == "workshop"

func room_dimensions() -> Vector3:
	return Vector3(room_size.x, room_height, room_size.y)

func room_layout() -> Dictionary:
	return {
		"room_size": [room_size.x, room_size.y],
		"room_height": room_height,
		"door_width": door_width,
		"cell_size": cell_size,
		"wall_clearance": wall_clearance,
		"door_clearance_depth": door_clearance_depth,
		"door_facing": [door_facing.x, door_facing.y, door_facing.z],
	}

func _apply_layout(layout: Dictionary) -> void:
	var size_value: Variant = layout.get("room_size", [8.2, 6.2])
	if size_value is Array and (size_value as Array).size() >= 2:
		room_size = Vector2(maxf(0.1, float(size_value[0])), maxf(0.1, float(size_value[1])))
	room_height = maxf(0.1, float(layout.get("room_height", 3.65)))
	door_width = maxf(0.1, float(layout.get("door_width", 1.45)))
	cell_size = maxf(0.1, float(layout.get("cell_size", 1.0)))
	wall_clearance = maxf(0.0, float(layout.get("wall_clearance", 0.45)))
	door_clearance_depth = maxf(0.0, float(layout.get("door_clearance_depth", 0.85)))
	var next_facing := _array_to_vector3(layout.get("door_facing", [0.0, 0.0, 1.0]))
	if next_facing.length_squared() > 0.01:
		door_facing = next_facing.normalized()

func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	for fire_data in animated_fire:
		var fire := fire_data.get("node") as MeshInstance3D
		if fire == null or not is_instance_valid(fire):
			continue
		var phase := float(fire_data.get("phase", 0.0))
		var base_scale: Vector3 = fire_data.get("base_scale", Vector3.ONE)
		var pulse := 1.0 + sin(elapsed * 6.2 + phase) * 0.12 + sin(elapsed * 10.7 + phase * 0.7) * 0.05
		fire.scale = base_scale * pulse
		var light := fire_data.get("light") as OmniLight3D
		if light != null and is_instance_valid(light):
			light.light_energy = float(fire_data.get("energy", 1.5)) + sin(elapsed * 7.0 + phase) * 0.18
	for smoke_data in animated_smoke:
		var puff := smoke_data.get("node") as Node3D
		if puff == null or not is_instance_valid(puff):
			continue
		var base_position: Vector3 = smoke_data.get("base_position", puff.position)
		var phase := float(smoke_data.get("phase", 0.0))
		puff.position = base_position + Vector3(sin(elapsed * 0.55 + phase) * 0.08, fmod(elapsed * 0.16 + phase * 0.18, 0.42), 0.0)
		puff.scale = Vector3.ONE * (1.0 + fmod(elapsed * 0.18 + phase, 0.5) * 0.35)
	if animated_wheel != null and is_instance_valid(animated_wheel):
		animated_wheel.rotation.z = fmod(animated_wheel.rotation.z + delta * 0.75, TAU)

func is_active() -> bool:
	return active

func is_transitioning() -> bool:
	return transitioning

func set_key_light_direction(direction: Vector3) -> void:
	if direction.length_squared() < 0.001:
		return
	var normalized_direction := direction.normalized()
	for sprite_value in find_children("*", "Sprite3D", true, false):
		var sprite := sprite_value as Sprite3D
		var material := sprite.material_override as ShaderMaterial if sprite != null else null
		if material != null:
			material.set_shader_parameter("key_light_direction", normalized_direction)

func entry_position() -> Vector3:
	return Vector3(0.0, 1.0, room_size.y * 0.5 - 0.48)

func exit_position() -> Vector3:
	return Vector3(0.0, 1.0, room_size.y * 0.5 + 0.42)

func entry_facing() -> Vector3:
	return -door_facing

func camera_focus_position() -> Vector3:
	# Keep the authored cutaway composition centered while the player walks. The
	# interior camera is a room presentation camera, not a second free-follow
	# camera; station hitboxes and player movement remain fully world-authored.
	return room_root.global_position + Vector3(0.0, 1.0, 0.0) if room_root != null else Vector3(0.0, 1.0, 0.0)

func active_station_count() -> int:
	return stations.size()

func world_to_room_local(world_position: Vector3) -> Vector3:
	return room_root.to_local(world_position) if room_root != null else world_position

func sync_persisted_stations(persisted_stations: Dictionary) -> void:
	if room_root == null or transitioning:
		return
	clear_station_preview()
	var was_active := active
	_clear_dynamic_stations()
	for station_id in persisted_stations:
		var record: Variant = persisted_stations.get(station_id, {})
		if not (record is Dictionary):
			continue
		_create_persisted_station(str(station_id), record)
	room_measurements_valid = _validate_room_measurements()
	_set_room_collisions(was_active)

func set_station_preview(local_cell: Vector2i, rotation_quarter_turns: int, valid: bool) -> void:
	clear_station_preview()
	if room_root == null or not active:
		return
	var footprint := ContentRegistry.interior_station_footprint("workbench", rotation_quarter_turns)
	if footprint == Vector2i.ZERO:
		return
	station_preview = Node3D.new()
	station_preview.name = "InteriorStationPlacementPreview"
	station_preview.position = InteriorGrid.cell_to_local(local_cell, footprint, room_size, cell_size)
	station_preview.rotation.y = float(rotation_quarter_turns) * PI * 0.5
	station_preview.modulate = Color(0.38, 0.95, 0.72, 0.88) if valid else Color(0.95, 0.30, 0.28, 0.88)
	room_root.add_child(station_preview)
	_add_construction_frame(station_preview, footprint)

func clear_station_preview() -> void:
	if station_preview != null and is_instance_valid(station_preview):
		station_preview.queue_free()
	station_preview = null

func station_ids() -> Array[String]:
	var result: Array[String] = []
	for station_id in stations:
		result.append(str(station_id))
	return result

func set_room_active(value: bool, kind := "workshop", instance_id := "") -> void:
	if value and not room_measurements_valid:
		active = false
		active_kind = ""
		active_instance_id = ""
		_set_room_collisions(false)
		return
	active = value
	active_kind = kind if value else ""
	active_instance_id = instance_id if value else ""
	if room_root != null:
		room_root.visible = value
	_set_room_collisions(value)
	for station_value in stations.values():
		var station := station_value as Node3D
		if station != null:
			station.visible = value

func transition_to(value: bool, kind := "workshop", instance_id := "", finished := Callable()) -> bool:
	if transitioning or room_root == null:
		return false
	if value and (not supports_kind(kind) or configured_profile_id.is_empty() or not room_measurements_valid):
		return false
	transitioning = true
	if fade_rect == null:
		set_room_active(value, kind, instance_id)
		transitioning = false
		if finished.is_valid():
			finished.call()
		return true
	fade_rect.visible = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_rect.modulate.a = 0.0
	var tween := create_tween()
	# The fade is bound to this pausable controller. Focus-loss pause therefore
	# freezes the visual transition before the midpoint can commit the context
	# swap; it cannot complete behind the player's back.
	tween.set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		set_room_active(value, kind, instance_id)
		if finished.is_valid():
			finished.call()
	)
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		transitioning = false
		fade_rect.visible = false
	)
	return true

func _build_transition_overlay() -> void:
	fade_layer = CanvasLayer.new()
	fade_layer.name = "InteriorTransitionLayer"
	fade_layer.layer = 120
	add_child(fade_layer)
	fade_rect = ColorRect.new()
	fade_rect.name = "InteriorFade"
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color("#11181a")
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.visible = false
	fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	fade_layer.add_child(fade_rect)

func _clear_room() -> void:
	if room_root != null and is_instance_valid(room_root):
		room_root.free()
	room_root = null
	room_shell = null
	stations.clear()
	animated_fire.clear()
	animated_smoke.clear()
	animated_wheel = null

func _first_access_zone(access_zones: Array, kind: String) -> Dictionary:
	for zone_value in access_zones:
		if zone_value is Dictionary and str((zone_value as Dictionary).get("kind", "")) == kind:
			return (zone_value as Dictionary).duplicate(true)
	return {}

func _access_zone_by_id(access_zones: Array, zone_id: String) -> Dictionary:
	if zone_id.is_empty():
		return {}
	for zone_value in access_zones:
		if zone_value is Dictionary and str((zone_value as Dictionary).get("id", "")) == zone_id:
			return (zone_value as Dictionary).duplicate(true)
	return {}

func _array_to_vector3(value: Variant) -> Vector3:
	if not value is Array or (value as Array).size() < 3:
		return Vector3.ZERO
	var values := value as Array
	return Vector3(float(values[0]), float(values[1]), float(values[2]))

func _build_workshop_room() -> void:
	room_root = Node3D.new()
	room_root.name = "WorkshopInteriorRoom"
	room_root.set_meta("interior_id", "workshop_v1")
	room_root.set_meta("world_size_m", [room_size.x, room_height, room_size.y])
	add_child(room_root)
	room_shell = Node3D.new()
	room_shell.name = "WorkshopRoomShell"
	room_root.add_child(room_shell)
	_create_floor()
	_create_walls()
	_create_workshop_stations()
	_create_dressing()
	_create_illustrated_shell()

func _create_illustrated_shell() -> void:
	# The room architecture is an authored cutaway card behind the live station
	# meshes. The stations remain real, separately measured assets in front of it;
	# this improves the reference silhouette without making their hitboxes depend
	# on the cutaway texture's rectangular quad.
	var texture := load(ILLUSTRATED_SHELL_TEXTURE_PATH) as Texture2D
	if texture == null:
		return
	var image := texture.get_image()
	if image == null:
		return
	var opaque_bounds := image.get_used_rect()
	if opaque_bounds.size.x <= 0 or opaque_bounds.size.y <= 0:
		return
	for mesh_value in room_shell.find_children("*", "MeshInstance3D", true, false):
		var mesh := mesh_value as MeshInstance3D
		if mesh != null:
			mesh.visible = false
	illustrated_shell = Sprite3D.new()
	illustrated_shell.name = "IllustratedWorkshopInteriorShell"
	illustrated_shell.texture = texture
	# The generated card is a complete room composition, so its measured opaque
	# bounds are centered as a single background layer. A top-left/bottom pivot
	# on a Sprite3D is camera-dependent and made the card drift diagonally out of
	# the room when the fixed 3/4 camera followed the player.
	illustrated_shell.centered = true
	illustrated_shell.offset = Vector2.ZERO
	illustrated_shell.pixel_size = room_size.x * illustrated_shell_width_ratio / float(maxi(1, opaque_bounds.size.x))
	# Lift the measured card's visual center by half the authored room height so
	# its floor lands around the live room floor while the roof remains in frame.
	# This is derived from room_height, not a fixed pixel or screen offset.
	var camera := host_world.get("camera") as Camera3D if host_world != null else null
	var camera_offset := camera.global_position - room_root.global_position if camera != null else Vector3(13.5, 18.0, 13.5)
	var camera_direction := camera_offset.normalized() if camera_offset.length_squared() > 0.001 else Vector3(0.60, 0.0, 0.60).normalized()
	var backdrop_distance := maxf(room_size.x, room_size.y) * 1.40 + room_height
	illustrated_shell.position = Vector3(0.0, FLOOR_Y + room_height * 0.52, 0.0) - camera_direction * backdrop_distance
	illustrated_shell.axis = Vector3.AXIS_Z
	illustrated_shell.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	illustrated_shell.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	illustrated_shell.shaded = true
	if toon_sprite_material != null:
		var material := toon_sprite_material.duplicate() as ShaderMaterial
		material.set_shader_parameter("albedo_texture", texture)
		material.set_shader_parameter("base_color", Color.WHITE)
		illustrated_shell.material_override = material
	# Keep the card behind the live room by placing it along the camera's actual
	# authored view direction. Unlike a no-depth-test overlay, this preserves
	# ordinary 2.5D occlusion and lets stations remain in front without relying on
	# transparent draw-order luck.
	illustrated_shell.no_depth_test = false
	illustrated_shell.sorting_use_aabb_center = false
	illustrated_shell.sorting_offset = -0.35
	illustrated_shell.set_meta("asset_id", "interior/workshop/illustrated_shell")
	illustrated_shell.set_meta("asset_path", ILLUSTRATED_SHELL_TEXTURE_PATH)
	illustrated_shell.set_meta("opaque_measurement_source", "texture_alpha_used_rect")
	illustrated_shell.set_meta("visual_world_size", [room_size.x * illustrated_shell_width_ratio, room_size.x * illustrated_shell_width_ratio * float(opaque_bounds.size.y) / float(maxi(1, opaque_bounds.size.x))])
	illustrated_shell.set_meta("visual_width_ratio", illustrated_shell_width_ratio)
	room_root.add_child(illustrated_shell)

func _create_floor() -> void:
	var floor := _box(room_shell, "WorkshopFloorVisible", Vector3(room_size.x, 0.12, room_size.y), Vector3(0.0, -0.06, 0.0), Color("#70695d"))
	floor.set_meta("visible_asset_id", "interior/workshop/floor_tiles")
	var body := _collision_body(room_shell, "WorkshopFloorCollision", Vector3(room_size.x, 0.12, room_size.y), Vector3(0.0, -0.06, 0.0), "interior/workshop/floor_tiles")
	_bind_collision_to_visible_mesh(floor, body)
	body.set_meta("blocks_movement", true)
	for x in range(-4, 5):
		for z in range(-3, 4):
			if (x + z) % 2 != 0:
				continue
			var tile := _box(room_shell, "FloorInset_%d_%d" % [x, z], Vector3(0.93, 0.014, 0.93), Vector3(float(x) * 0.98, 0.008, float(z) * 0.96), Color("#827867"), false, false, false)
			tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _create_walls() -> void:
	var wall_color := Color("#6f5a4b")
	var timber := Color("#483833")
	# The upper walls are intentionally visible while the roof is omitted: the
	# player reads a real room without losing the fixed 3/4 camera or station
	# silhouettes.
	_create_wall_segment("WorkshopBackWall", Vector3(room_size.x, room_height, 0.18), Vector3(0.0, room_height * 0.5, -room_size.y * 0.5), wall_color, "interior/workshop/back_wall")
	_create_wall_segment("WorkshopLeftWall", Vector3(0.18, room_height, room_size.y), Vector3(-room_size.x * 0.5, room_height * 0.5, 0.0), wall_color, "interior/workshop/left_wall")
	_create_wall_segment("WorkshopRightWall", Vector3(0.18, room_height, room_size.y), Vector3(room_size.x * 0.5, room_height * 0.5, 0.0), wall_color, "interior/workshop/right_wall")
	var front_side_width := (room_size.x - door_width) * 0.5
	_create_wall_segment("WorkshopFrontWallLeft", Vector3(front_side_width, room_height, 0.18), Vector3(-((room_size.x + door_width) * 0.25), room_height * 0.5, room_size.y * 0.5), wall_color, "interior/workshop/front_wall_left")
	_create_wall_segment("WorkshopFrontWallRight", Vector3(front_side_width, room_height, 0.18), Vector3(((room_size.x + door_width) * 0.25), room_height * 0.5, room_size.y * 0.5), wall_color, "interior/workshop/front_wall_right")
	for side in [-1.0, 1.0]:
		_box(room_shell, "DoorPost_%s" % side, Vector3(0.18, 2.18, 0.22), Vector3(side * door_width * 0.5, 1.09, room_size.y * 0.5), timber, false, false, false)
	_box(room_shell, "DoorLintel", Vector3(door_width + 0.34, 0.20, 0.22), Vector3(0.0, 2.18, room_size.y * 0.5), timber, false, false, false)
	var door_glow := _box(room_shell, "DoorwayCoolLight", Vector3(door_width * 0.78, 1.72, 0.025), Vector3(0.0, 0.88, room_size.y * 0.5 - 0.08), Color(0.40, 0.70, 0.72, 0.18), false, true, false)
	door_glow.set_meta("presentation_only", true)

func _create_wall_segment(node_name: String, size: Vector3, position: Vector3, color: Color, asset_id: String) -> void:
	var visual := _box(room_shell, node_name + "Visible", size, position, color)
	visual.set_meta("visible_asset_id", asset_id)
	var body := _collision_body(room_shell, node_name + "Collision", size, position, asset_id)
	_bind_collision_to_visible_mesh(visual, body)
	for z_offset in [-size.z * 0.34, 0.0, size.z * 0.34]:
		if size.x > size.z:
			_box(room_shell, node_name + "Timber_%s" % z_offset, Vector3(0.12, size.y * 0.92, 0.12), position + Vector3(z_offset, 0.0, -size.z * 0.52), Color("#4a3831"), false, false, false)
		else:
			_box(room_shell, node_name + "Timber_%s" % z_offset, Vector3(0.12, size.y * 0.92, 0.12), position + Vector3(-size.x * 0.52, 0.0, z_offset), Color("#4a3831"), false, false, false)

func _create_workshop_stations() -> void:
	var exit := _create_station("exit", "Workshop Door", Vector3(0.0, 0.0, room_size.y * 0.5 + 0.08), Vector2(door_width, 0.42), "exit", "interior/workshop/door")
	_box(exit, "DoorPanel", Vector3(1.12, 1.95, 0.10), Vector3(0.0, 0.98, -0.04), Color("#7b503b"))
	_box(exit, "DoorHandle", Vector3(0.07, 0.13, 0.10), Vector3(0.30, 0.95, -0.11), Color("#d7a45e"), false, true)
	var exit_label := exit.get_node_or_null("StationLabel") as Label3D
	if exit_label != null:
		exit_label.text = "EXIT\nE"
	_sync_station_collision_to_visible_asset(exit)
	# The authored cutaway already contains the real threshold/door silhouette.
	# Keep the exit station and its measured collider, but remove the old flat box
	# panel so it cannot sit in front of the player as a prototype rectangle.
	for door_mesh_name in ["DoorPanel", "DoorHandle"]:
		var door_mesh := exit.get_node_or_null(door_mesh_name) as MeshInstance3D
		if door_mesh != null:
			door_mesh.visible = false
	exit.set_meta("presentation_source", "illustrated_shell_doorway")

func _create_furnace(station_id: String, label_text: String, position: Vector3, body_color: Color, phase: float, asset_kind := "") -> void:
	var station := _create_station(station_id, label_text, position, Vector2(1.34, 1.02), "workshop", "interior/workshop/%s" % station_id, asset_kind)
	_box(station, "FurnaceBody", Vector3(1.18, 1.12, 0.92), Vector3(0.0, 0.56, 0.0), body_color)
	_box(station, "FurnaceCap", Vector3(1.28, 0.15, 1.02), Vector3(0.0, 1.16, 0.0), Color("#493d3d"))
	var fire := _box(station, "FurnaceFire", Vector3(0.42, 0.34, 0.06), Vector3(0.0, 0.62, 0.48), Color("#ffb55e"), false, true, false)
	var light := OmniLight3D.new()
	light.name = "FurnaceLight"
	light.position = Vector3(0.0, 0.92, 0.48)
	light.light_color = Color("#ff9a56")
	light.light_energy = 1.35
	light.omni_range = 3.0
	light.shadow_enabled = true
	station.add_child(light)
	animated_fire.append({"node": fire, "light": light, "phase": phase, "base_scale": fire.scale, "energy": 1.35})
	var chimney := _cylinder(station, "Chimney", 0.19, 1.35, Vector3(0.0, 1.82, -0.16), Color("#4d474a"))
	chimney.set_meta("visible_asset_id", "interior/workshop/chimney")
	var smoke_root := Node3D.new()
	smoke_root.name = "Smoke"
	station.add_child(smoke_root)
	for index in 3:
		var puff := _sphere(smoke_root, "SmokePuff_%d" % index, 0.16 + float(index) * 0.035, Vector3(0.0, 2.52 + float(index) * 0.18, -0.16), Color(0.72, 0.76, 0.72, 0.24), true)
		animated_smoke.append({"node": puff, "phase": phase + float(index) * 0.7, "base_position": puff.position})
	_sync_station_collision_to_visible_asset(station)
	_add_generated_station_sprite(station, station_id)

func _create_workbench(station_id: String, label_text: String, position: Vector3, asset_kind := "") -> void:
	var station := _create_station(station_id, label_text, position, Vector2(1.75, 0.86), "workshop", "interior/workshop/workbench", asset_kind)
	_box(station, "BenchTop", Vector3(1.72, 0.18, 0.78), Vector3(0.0, 0.82, 0.0), Color("#9a6745"))
	for side in [-1.0, 1.0]:
		_box(station, "BenchLeg_%s" % side, Vector3(0.12, 0.74, 0.12), Vector3(side * 0.68, 0.38, 0.0), Color("#5b4034"))
	_box(station, "ToolTray", Vector3(0.58, 0.10, 0.32), Vector3(-0.34, 0.98, 0.08), Color("#4d4541"))
	for index in 3:
		_box_rotated(station, "Tool_%d" % index, Vector3(0.06, 0.42, 0.06), Vector3(-0.12 + float(index) * 0.16, 1.07, 0.08), Color("#d3a35e"), Vector3(0.0, 0.0, -22.0 + float(index) * 16.0))
	_sync_station_collision_to_visible_asset(station)
	_add_generated_station_sprite(station, station_id)

func _create_anvil(station_id: String, label_text: String, position: Vector3, asset_kind := "") -> void:
	var station := _create_station(station_id, label_text, position, Vector2(0.86, 0.78), "workshop", "interior/workshop/anvil", asset_kind)
	_box(station, "AnvilFoot", Vector3(0.58, 0.16, 0.52), Vector3(0.0, 0.08, 0.0), Color("#4c5658"))
	_box(station, "AnvilStem", Vector3(0.32, 0.52, 0.28), Vector3(0.0, 0.40, 0.0), Color("#657278"))
	_box(station, "AnvilTop", Vector3(0.72, 0.18, 0.34), Vector3(-0.05, 0.75, 0.0), Color("#819096"))
	var hammer := Node3D.new()
	hammer.name = "HammerPivot"
	hammer.position = Vector3(0.24, 0.86, 0.04)
	station.add_child(hammer)
	# The hammer is a presentation animation, not a solid part of the anvil's
	# interaction footprint. Excluding both pivoted meshes keeps the measured
	# collider stable while the hammer rotates during play.
	_box_rotated(hammer, "Handle", Vector3(0.07, 0.62, 0.07), Vector3(0.0, 0.30, 0.0), Color("#c09158"), Vector3(0.0, 0.0, -28.0), false, false, false)
	_box(hammer, "Head", Vector3(0.36, 0.16, 0.18), Vector3(0.0, 0.61, 0.0), Color("#4b5559"), false, false, false)
	animated_wheel = hammer
	_sync_station_collision_to_visible_asset(station)
	_add_generated_station_sprite(station, station_id)

func _create_storage(station_id: String, label_text: String, position: Vector3, asset_kind := "") -> void:
	var station := _create_station(station_id, label_text, position, Vector2(1.25, 1.10), "storage", "interior/workshop/storage", asset_kind)
	_box(station, "Crate", Vector3(1.10, 0.74, 0.92), Vector3(0.0, 0.37, 0.0), Color("#a8734b"))
	for side in [-1.0, 1.0]:
		_box(station, "CrateBand_%s" % side, Vector3(0.08, 0.79, 0.96), Vector3(side * 0.36, 0.37, 0.0), Color("#5b4034"))
	_box(station, "CrateLid", Vector3(1.16, 0.10, 0.98), Vector3(0.0, 0.78, 0.0), Color("#b78451"))
	_box(station, "StorageTag", Vector3(0.36, 0.22, 0.04), Vector3(0.0, 0.58, 0.48), Color("#e6c87d"))
	_sync_station_collision_to_visible_asset(station)
	_add_generated_station_sprite(station, station_id)

func _clear_dynamic_stations() -> void:
	var dynamic_ids: Array = []
	for station_id in stations:
		if str(station_id) != "exit":
			dynamic_ids.append(str(station_id))
	for station_id in dynamic_ids:
		var station := stations.get(station_id) as Node3D
		if station != null and is_instance_valid(station):
			station.queue_free()
		stations.erase(station_id)
	animated_fire.clear()
	animated_smoke.clear()
	animated_wheel = null

func _create_persisted_station(station_id: String, record: Dictionary) -> void:
	var station_kind := str(record.get("kind", ""))
	var definition := ContentRegistry.interior_station_definition(station_kind)
	if definition.is_empty():
		return
	var cell_value: Array = record.get("cell", [])
	if cell_value.size() < 2:
		return
	var rotation := int(record.get("rotation", 0))
	var footprint := ContentRegistry.interior_station_footprint(station_kind, rotation)
	var local_position := InteriorGrid.cell_to_local(Vector2i(int(cell_value[0]), int(cell_value[1])), footprint, room_size, cell_size)
	var label_text := str(definition.get("label", station_kind))
	match station_kind:
		"furnace_left":
			_create_furnace(station_id, label_text, local_position, Color("#7a5546"), 0.0, station_kind)
		"furnace_right":
			_create_furnace(station_id, label_text, local_position, Color("#69545a"), 0.8, station_kind)
		"workbench":
			_create_workbench(station_id, label_text, local_position, station_kind)
		"anvil":
			_create_anvil(station_id, label_text, local_position, station_kind)
		"storage":
			_create_storage(station_id, label_text, local_position, station_kind)
		_:
			return
	var station := stations.get(station_id) as Node3D
	if station == null:
		return
	station.rotation.y = float(rotation) * PI * 0.5
	station.set_meta("interior_station_kind", station_kind)
	station.set_meta("interior_structure_id", str(record.get("structure_id", active_instance_id)))
	station.set_meta("installation_state", str(record.get("state", "blueprint")))
	_add_construction_frame(station, footprint)
	_apply_station_state(station, record)

func _apply_station_state(station: Node3D, record: Dictionary) -> void:
	if station == null:
		return
	var state := str(record.get("state", "blueprint"))
	station.set_meta("installation_state", state)
	var sprite := station.get_node_or_null("GeneratedStationSprite") as Sprite3D
	var state_color := Color(1.0, 1.0, 1.0, 1.0)
	if state == "blueprint":
		state_color = Color(0.40, 0.92, 1.0, 0.42)
	elif state == "building":
		state_color = Color(1.0, 0.78, 0.35, 0.72)
	if sprite != null:
		sprite.modulate = state_color
	var fire := station.get_node_or_null("FurnaceFire") as MeshInstance3D
	if fire != null:
		fire.visible = state != "blueprint"
	var label := station.get_node_or_null("StationLabel") as Label3D
	if label != null:
		var base_label := str(ContentRegistry.interior_station_definition(str(record.get("kind", ""))).get("label", label.text))
		label.text = base_label if state == "operational" else "%s\n%s" % [base_label, "BLUEPRINT" if state == "blueprint" else "ASSEMBLING"]
	var frame := station.get_node_or_null("ConstructionFrame") as Node3D
	if frame != null:
		frame.visible = state != "operational"
	_set_station_collision_active(station, state == "operational")

func _set_station_collision_active(station: Node3D, value: bool) -> void:
	if station == null:
		return
	var body := station.get_node_or_null("VisibleAssetCollision") as StaticBody3D
	if body == null:
		return
	body.set_meta("installation_operational", value)
	for collision_value in body.find_children("*", "CollisionShape3D", true, false):
		var collision := collision_value as CollisionShape3D
		if collision != null:
			collision.set_meta("installation_operational", value)
			collision.disabled = not active or not value or not bool(collision.get_meta("measurement_valid", false))

func _add_construction_frame(station: Node3D, footprint: Vector2i) -> void:
	if station == null or footprint == Vector2i.ZERO:
		return
	var frame := Node3D.new()
	frame.name = "ConstructionFrame"
	station.add_child(frame)
	var width := maxf(0.6, float(footprint.x) * cell_size * 0.90)
	var depth := maxf(0.6, float(footprint.y) * cell_size * 0.90)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.32, 0.88, 0.92, 0.78)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for edge in [Vector3(0.0, 0.05, -depth * 0.5), Vector3(0.0, 0.05, depth * 0.5)]:
		var bar := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(width, 0.045, 0.045)
		bar.mesh = mesh
		bar.position = edge
		bar.material_override = material
		frame.add_child(bar)
	for edge in [Vector3(-width * 0.5, 0.05, 0.0), Vector3(width * 0.5, 0.05, 0.0)]:
		var bar := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.045, 0.045, depth)
		bar.mesh = mesh
		bar.position = edge
		bar.material_override = material
		frame.add_child(bar)

func _create_dressing() -> void:
	var shelf := Node3D.new()
	shelf.name = "WorkshopShelf"
	shelf.position = Vector3(-room_size.x * 0.44, 0.0, room_size.y * 0.15)
	room_shell.add_child(shelf)
	_box(shelf, "ShelfBack", Vector3(0.14, 2.25, 1.32), Vector3(0.0, 1.12, 0.0), Color("#5e463a"), false, false, false)
	for y in [0.34, 1.02, 1.70]:
		_box(shelf, "ShelfBoard_%s" % y, Vector3(0.28, 0.10, 1.46), Vector3(0.0, y, 0.0), Color("#956346"), false, false, false)
	for index in 5:
		_box(shelf, "ShelfItem_%d" % index, Vector3(0.16, 0.22 + float(index % 2) * 0.08, 0.20), Vector3(0.05, 0.48 + float(index % 3) * 0.55, -0.40 + float(index % 2) * 0.52), Color("#c99153" if index % 2 == 0 else "#78916b"), false, false, false)
	var hanging_lamp := _sphere(room_shell, "WorkshopHangingLamp", 0.12, Vector3(0.0, room_height * 0.84, room_size.y * 0.06), Color("#ffd178"), false, true)
	var lamp_light := OmniLight3D.new()
	lamp_light.name = "WorkshopLampLight"
	lamp_light.position = hanging_lamp.position
	lamp_light.light_color = Color("#ffd18a")
	lamp_light.light_energy = 0.7
	lamp_light.omni_range = maxf(2.6, room_size.length() * 0.48)
	room_shell.add_child(lamp_light)
	_box(room_shell, "LampCord", Vector3(0.025, room_height * 0.20, 0.025), Vector3(0.0, room_height * 0.92, room_size.y * 0.06), Color("#3d3837"), false, false, false)

func _set_room_collisions(value: bool) -> void:
	if room_root == null:
		return
	for collision_value in room_root.find_children("*", "CollisionShape3D", true, false):
		var collision := collision_value as CollisionShape3D
		if collision != null:
			collision.disabled = not value or not bool(collision.get_meta("measurement_valid", false)) or not bool(collision.get_meta("installation_operational", true))

func _add_generated_station_sprite(station: Node3D, station_id: String) -> void:
	# The generated station sheet is presentation-only. Its opaque alpha envelope
	# is measured at runtime, while the existing collision proxy remains derived
	# from the station's visible authored mesh envelope. This keeps the interaction
	# contract stable while replacing prototype boxes with authored cutouts.
	if station == null or workshop_station_sheet == null:
		return
	var asset_kind := str(station.get_meta("interior_station_kind", station_id))
	var cell_index: int = int({
		"furnace_left": 0,
		"furnace_right": 1,
		"workbench": 2,
		"anvil": 3,
		"storage": 4,
	}.get(asset_kind, -1))
	if cell_index < 0:
		return
	var source_image := workshop_station_sheet.get_image()
	if source_image == null or source_image.is_empty():
		return
	var columns := 3
	var rows := 2
	var cell_width := maxi(1, int(source_image.get_width() / columns))
	var cell_height := maxi(1, int(source_image.get_height() / rows))
	var cell_x := (int(cell_index) % columns) * cell_width
	var cell_y := (int(cell_index) / columns) * cell_height
	var cell_rect := Rect2i(cell_x, cell_y, cell_width, cell_height)
	var cell_image := source_image.get_region(cell_rect)
	var opaque_bounds := cell_image.get_used_rect()
	if opaque_bounds.size.x <= 0 or opaque_bounds.size.y <= 0:
		return
	var bounds_data: Array = station.get_meta("visible_mesh_bounds", [])
	if bounds_data.size() < 6:
		return
	var measured_height := float(bounds_data[4])
	if measured_height <= 0.01:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = workshop_station_sheet
	atlas.region = Rect2(cell_rect)
	atlas.filter_clip = true
	var sprite := Sprite3D.new()
	sprite.name = "GeneratedStationSprite"
	sprite.texture = atlas
	sprite.centered = true
	sprite.pixel_size = measured_height / float(maxi(1, opaque_bounds.size.y))
	sprite.position = Vector3(0.0, measured_height * 0.5, 0.0)
	sprite.axis = Vector3.AXIS_Z
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	sprite.shaded = false
	sprite.no_depth_test = false
	sprite.sorting_use_aabb_center = false
	sprite.sorting_offset = 0.12
	sprite.set_meta("generated_station_id", station_id)
	sprite.set_meta("asset_id", "interior/workshop/station/%s" % asset_kind)
	sprite.set_meta("asset_path", WORKSHOP_STATION_SHEET_PATH)
	sprite.set_meta("opaque_measurement_source", "texture_alpha_used_rect")
	sprite.set_meta("alpha_bounds", [opaque_bounds.position.x, opaque_bounds.position.y, opaque_bounds.size.x, opaque_bounds.size.y])
	var generated_width := float(opaque_bounds.size.x) * sprite.pixel_size
	var source_width := float(bounds_data[3])
	var source_depth := float(bounds_data[5])
	var generated_depth := generated_width * source_depth / maxf(0.01, source_width)
	sprite.set_meta("visual_world_size", [generated_width, measured_height])
	sprite.set_meta("collision_world_footprint", [generated_width, generated_depth])
	for mesh_value in station.find_children("*", "MeshInstance3D", true, false):
		var prototype_mesh := mesh_value as MeshInstance3D
		if prototype_mesh == null:
			continue
		# Retain the small animated fire accent; the generated furnace already owns
		# the body, cap, chimney and coal-basket silhouette.
		if prototype_mesh.name == "FurnaceFire":
			continue
		prototype_mesh.visible = false
	station.add_child(sprite)
	var body := station.get_node_or_null("VisibleAssetCollision") as StaticBody3D
	var shape_node := body.get_node_or_null("MeasuredProxy") as CollisionShape3D if body != null else null
	var box := shape_node.shape as BoxShape3D if shape_node != null else null
	if body != null and shape_node != null and box != null:
		box.size = Vector3(generated_width, box.size.y, generated_depth)
		shape_node.position = Vector3(0.0, box.size.y * 0.5, 0.0)
		station.set_meta("visual_footprint", [generated_width, generated_depth])
		station.set_meta("collision_source", "generated_texture_alpha_calibrated_by_measured_mesh_aspect")
		body.set_meta("measurement_source", "generated_texture_alpha_calibrated_by_measured_mesh_aspect")
		body.set_meta("measurement_valid", true)
		shape_node.set_meta("measurement_source", "generated_texture_alpha_calibrated_by_measured_mesh_aspect")
		shape_node.set_meta("measurement_valid", true)
		shape_node.set_meta("measured_size", [box.size.x, box.size.y, box.size.z])
		shape_node.set_meta("measured_center", [shape_node.position.x, shape_node.position.y, shape_node.position.z])

func _validate_room_measurements() -> bool:
	if room_root == null:
		return false
	var collision_shapes := room_root.find_children("*", "CollisionShape3D", true, false)
	if collision_shapes.is_empty():
		return false
	for collision_value in collision_shapes:
		var collision := collision_value as CollisionShape3D
		if collision == null or collision.shape == null or not bool(collision.get_meta("measurement_valid", false)):
			return false
	for station_value in stations.values():
		var station := station_value as Node3D
		if station == null or not bool(station.get_meta("measurement_valid", false)):
			return false
	return true

func _sync_station_collision_to_visible_asset(station: Node3D) -> void:
	if station == null:
		return
	var bounds := _measure_visible_mesh_bounds(station)
	var body := station.get_node_or_null("VisibleAssetCollision") as StaticBody3D
	var shape_node := body.get_node_or_null("MeasuredProxy") as CollisionShape3D if body != null else null
	var box := shape_node.shape as BoxShape3D if shape_node != null else null
	if bounds.size.x <= 0.001 or bounds.size.z <= 0.001 or body == null or shape_node == null or box == null:
		_disable_station_collision(station, "visible_mesh_measurement_invalid")
		return
	var collision_height := clampf(bounds.position.y + bounds.size.y, 0.12, 1.85)
	box.size = Vector3(bounds.size.x, collision_height, bounds.size.z)
	body.position = Vector3.ZERO
	shape_node.position = Vector3(bounds.position.x + bounds.size.x * 0.5, collision_height * 0.5, bounds.position.z + bounds.size.z * 0.5)
	shape_node.disabled = false
	station.set_meta("visual_footprint", [bounds.size.x, bounds.size.z])
	station.set_meta("visible_mesh_bounds", [bounds.position.x, bounds.position.y, bounds.position.z, bounds.size.x, bounds.size.y, bounds.size.z])
	station.set_meta("measurement_valid", true)
	station.set_meta("measurement_source", "visible_mesh_aabb")
	station.set_meta("collision_source", "visible_mesh_aabb")
	body.set_meta("visual_footprint", [bounds.size.x, bounds.size.z])
	body.set_meta("measurement_source", "visible_mesh_aabb")
	body.set_meta("measurement_valid", true)
	shape_node.set_meta("measurement_source", "visible_mesh_aabb")
	shape_node.set_meta("measurement_valid", true)
	shape_node.set_meta("measured_size", [box.size.x, box.size.y, box.size.z])
	shape_node.set_meta("measured_center", [shape_node.position.x, shape_node.position.y, shape_node.position.z])

func _disable_station_collision(station: Node3D, reason: String) -> void:
	station.set_meta("measurement_valid", false)
	station.set_meta("measurement_source", reason)
	var body := station.get_node_or_null("VisibleAssetCollision") as StaticBody3D
	if body == null:
		return
	for collision_value in body.find_children("*", "CollisionShape3D", true, false):
		var collision := collision_value as CollisionShape3D
		if collision != null:
			collision.disabled = true
			collision.set_meta("measurement_valid", false)
	if body != null:
		body.set_meta("measurement_valid", false)

func _measure_visible_mesh_bounds(root_node: Node3D) -> AABB:
	var measured := AssetMeasurement.measure_runtime_meshes_by_meta(root_node, "collision_contributor", true)
	return measured.get("bounds", AABB()) if bool(measured.get("valid", false)) else AABB()

func _bind_collision_to_visible_mesh(visual: MeshInstance3D, body: StaticBody3D) -> bool:
	if visual == null or body == null or visual.mesh == null:
		return false
	var shape_node := body.get_node_or_null("MeasuredProxy") as CollisionShape3D
	var box := shape_node.shape as BoxShape3D if shape_node != null else null
	if shape_node == null or box == null:
		if body != null:
			body.set_meta("measurement_valid", false)
		if shape_node != null:
			shape_node.set_meta("measurement_valid", false)
		return false
	var bounds := visual.get_aabb()
	if bounds.size.x <= 0.001 or bounds.size.y <= 0.001 or bounds.size.z <= 0.001:
		body.set_meta("measurement_valid", false)
		shape_node.set_meta("measurement_valid", false)
		shape_node.disabled = true
		return false
	box.size = bounds.size
	body.position = visual.position + bounds.position + bounds.size * 0.5
	shape_node.position = Vector3.ZERO
	body.set_meta("measurement_source", "visible_mesh_aabb")
	body.set_meta("measurement_valid", true)
	shape_node.set_meta("measurement_source", "visible_mesh_aabb")
	shape_node.set_meta("measurement_valid", true)
	shape_node.set_meta("measured_size", [box.size.x, box.size.y, box.size.z])
	shape_node.set_meta("measured_center", [body.position.x, body.position.y, body.position.z])
	return true

func _create_station(station_id: String, label_text: String, position: Vector3, footprint: Vector2, action: String, asset_id: String, station_kind := "") -> Node3D:
	var station := Node3D.new()
	station.name = "InteriorStation_%s" % station_id
	station.position = position
	station.add_to_group("interactable")
	station.add_to_group("building_interior_station")
	station.set_meta("interior_station_id", station_id)
	if not station_kind.is_empty():
		station.set_meta("interior_station_kind", station_kind)
	station.set_meta("interior_action", action)
	station.set_meta("visible_asset_id", asset_id)
	station.set_meta("visual_footprint", [footprint.x, footprint.y])
	station.set_meta("collision_source", "visible_mesh_aabb_pending")
	room_root.add_child(station)
	var body := _collision_body(station, "VisibleAssetCollision", Vector3(footprint.x, 1.85, footprint.y), Vector3(0.0, 0.92, 0.0), asset_id)
	body.get_node("MeasuredProxy").disabled = true
	body.set_meta("visible_asset_id", asset_id)
	body.set_meta("measurement_source", "visible_mesh_aabb_pending")
	var label := Label3D.new()
	label.name = "StationLabel"
	label.text = label_text
	label.font_size = 32
	label.pixel_size = 0.0028
	label.modulate = Color("#f6e1b0")
	label.outline_size = 8
	label.outline_modulate = Color(0.10, 0.13, 0.13, 0.92)
	label.position = Vector3(0.0, 2.05, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.add_to_group("world_label")
	station.add_child(label)
	stations[station_id] = station
	return station

func _collision_body(parent: Node3D, node_name: String, size: Vector3, position: Vector3, asset_id: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	body.set_meta("collision_source", "visible_asset_authored_proxy")
	body.set_meta("measurement_valid", false)
	body.set_meta("visible_asset_id", asset_id)
	var shape_node := CollisionShape3D.new()
	shape_node.name = "MeasuredProxy"
	var shape := BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	shape_node.set_meta("collision_source", "visible_asset_authored_proxy")
	shape_node.set_meta("measurement_valid", false)
	shape_node.set_meta("visible_asset_id", asset_id)
	shape_node.set_meta("measured_size", [size.x, size.y, size.z])
	body.add_child(shape_node)
	parent.add_child(body)
	return body

func _box(parent: Node3D, node_name: String, size: Vector3, position: Vector3, color: Color, transparent := false, emissive := false, physical_asset_mesh := true) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.position = position
	mesh_node.material_override = _material(color, transparent, emissive)
	var surface_profile := "toon_wood" if not transparent and not emissive else "accent"
	if toon_wood_material != null and surface_profile == "toon_wood":
		var toon_material := toon_wood_material.duplicate() as ShaderMaterial
		toon_material.set_shader_parameter("base_color", color)
		mesh_node.material_override = toon_material
	mesh_node.set_meta("visible_asset_size", [size.x, size.y, size.z])
	mesh_node.set_meta("physical_asset_mesh", physical_asset_mesh)
	mesh_node.set_meta("collision_contributor", physical_asset_mesh)
	mesh_node.set_meta("surface_profile", surface_profile)
	parent.add_child(mesh_node)
	return mesh_node

func _box_rotated(parent: Node3D, node_name: String, size: Vector3, position: Vector3, color: Color, rotation_degrees: Vector3, transparent := false, emissive := false, physical_asset_mesh := true) -> MeshInstance3D:
	var mesh_node := _box(parent, node_name, size, position, color, transparent, emissive, physical_asset_mesh)
	mesh_node.rotation_degrees = rotation_degrees
	return mesh_node

func _sphere(parent: Node3D, node_name: String, radius: float, position: Vector3, color: Color, transparent := false, emissive := false) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 6
	mesh_node.mesh = mesh
	mesh_node.position = position
	mesh_node.material_override = _material(color, transparent, emissive)
	mesh_node.set_meta("visible_asset_size", [radius * 2.0, radius * 2.0, radius * 2.0])
	mesh_node.set_meta("physical_asset_mesh", false)
	mesh_node.set_meta("collision_contributor", false)
	mesh_node.set_meta("surface_profile", "accent")
	parent.add_child(mesh_node)
	return mesh_node

func _cylinder(parent: Node3D, node_name: String, radius: float, height: float, position: Vector3, color: Color) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh_node.mesh = mesh
	mesh_node.position = position
	mesh_node.material_override = _material(color)
	if toon_wood_material != null:
		var toon_material := toon_wood_material.duplicate() as ShaderMaterial
		toon_material.set_shader_parameter("base_color", color)
		mesh_node.material_override = toon_material
	mesh_node.set_meta("visible_asset_size", [radius * 2.0, height, radius * 2.0])
	mesh_node.set_meta("physical_asset_mesh", true)
	mesh_node.set_meta("collision_contributor", true)
	mesh_node.set_meta("surface_profile", "toon_wood")
	parent.add_child(mesh_node)
	return mesh_node

func _material(color: Color, transparent := false, emissive := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	material.metallic = 0.02
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		material.no_depth_test = false
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.8
	return material
