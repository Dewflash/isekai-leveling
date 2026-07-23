class_name ProdewtyPlayer
extends CharacterBody3D

var world: Node
var speed := 5.2
var max_health := 100
var health := 100
var joystick_vector := Vector2.ZERO
var click_move_target := Vector3.ZERO
var click_move_active := false
var click_move_stall_time := 0.0
var click_move_sample_time := 0.0
var click_move_sample_distance := INF
var attack_cooldown := 0.0
var dodge_cooldown := 0.0
var invulnerable_time := 0.0
var last_direction := Vector3(0.0, 0.0, -1.0)
var visual: Node3D
var walk_time := 0.0
var walk_frame_time := 0.0
var hurt_time := 0.0
var gather_active := false
var action_pose_time := 0.0
var action_animation_state := "idle"
var action_animation_elapsed := 0.0
var action_animation_frame := 0
var action_animation_marker := "idle"
var action_animation_resource := ""
const ACTION_ANIMATION_SOURCE := "authored_action_timeline_v1"
const WORLD_LIMIT_X := 20.0
const WORLD_LIMIT_Z := 15.0

func _ready() -> void:
	visual = get_node_or_null("Visual")
	_update_action_metadata()

func _physics_process(delta: float) -> void:
	var previous_position := global_position
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	hurt_time = maxf(0.0, hurt_time - delta)
	action_pose_time = maxf(0.0, action_pose_time - delta)
	var input_vector := Vector2.ZERO
	var input_locked := world != null and world.has_method("is_player_input_locked") and bool(world.call("is_player_input_locked"))
	if input_locked:
		cancel_navigation(true)
		joystick_vector = Vector2.ZERO
	elif InputMap.has_action("move_left") and InputMap.has_action("move_right") and InputMap.has_action("move_up") and InputMap.has_action("move_down"):
		input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	else:
		# Keep the character usable when this script is previewed outside Main,
		# before the world's input map bootstrap has run.
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			input_vector.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			input_vector.x += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			input_vector.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			input_vector.y += 1.0
	var manual_input_active := input_vector.length() > 0.05
	if joystick_vector.length() > 0.05:
		input_vector = joystick_vector
		manual_input_active = true
	if manual_input_active:
		click_move_active = false
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	var direction := Vector3(input_vector.x, 0.0, input_vector.y)
	if click_move_active and not manual_input_active:
		var click_delta := click_move_target - global_position
		click_delta.y = 0.0
		if click_delta.length() > 0.28:
			direction = click_delta.normalized()
		else:
			cancel_navigation(true)
			direction = Vector3.ZERO
	elif world != null and world.has_method("camera_relative_direction"):
		direction = world.camera_relative_direction(input_vector)
	velocity.y = 0.0
	if direction.length() > 0.05:
		walk_time += delta * 10.0
		walk_frame_time += delta
		last_direction = direction.normalized()
		var horizontal_velocity := Vector2(velocity.x, velocity.z)
		var target_horizontal_velocity := Vector2(direction.x, direction.z) * speed
		horizontal_velocity = horizontal_velocity.move_toward(target_horizontal_velocity, 24.0 * delta)
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.y
		if visual != null:
			visual.rotation.y = lerp_angle(visual.rotation.y, atan2(last_direction.x, last_direction.z), delta * 9.0)
			var stride := sin(walk_time)
			visual.position.y = absf(stride) * 0.045
			visual.rotation.z = lerpf(visual.rotation.z, sin(walk_time * 0.5) * 0.028, delta * 10.0)
			visual.scale.y = 1.0 + absf(stride) * 0.025
			if action_pose_time <= 0.0:
				var left_leg := visual.get_node_or_null("LegLeft") as Node3D
				var right_leg := visual.get_node_or_null("LegRight") as Node3D
				var left_arm := visual.get_node_or_null("ArmLeft") as Node3D
				var right_arm := visual.get_node_or_null("ArmRight") as Node3D
				if left_leg != null:
					left_leg.rotation.x = stride * 0.42
				if right_leg != null:
					right_leg.rotation.x = -stride * 0.42
				if left_arm != null:
					left_arm.rotation.x = -stride * 0.20
				if right_arm != null:
					right_arm.rotation.x = stride * 0.20
	else:
		walk_time = 0.0
		walk_frame_time = 0.0
		var horizontal_velocity := Vector2(velocity.x, velocity.z)
		horizontal_velocity = horizontal_velocity.move_toward(Vector2.ZERO, 30.0 * delta)
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.y
		if visual != null:
			visual.scale = Vector3.ONE
			visual.position.y = move_toward(visual.position.y, 0.0, delta * 0.5)
			visual.rotation.z = move_toward(visual.rotation.z, 0.0, delta * 0.8)
			if action_pose_time <= 0.0:
				for limb_name in ["LegLeft", "LegRight", "ArmLeft", "ArmRight"]:
					var limb := visual.get_node_or_null(limb_name) as Node3D
					if limb != null:
						limb.rotation.x = move_toward(limb.rotation.x, 0.0, delta * 4.0)
	_update_action_timeline(delta)
	move_and_slide()
	global_position.x = clampf(global_position.x, -WORLD_LIMIT_X, WORLD_LIMIT_X)
	global_position.z = clampf(global_position.z, -WORLD_LIMIT_Z, WORLD_LIMIT_Z)
	global_position.y = 1.0
	_update_illustrated_character()
	if click_move_active:
		var target_distance := global_position.distance_to(click_move_target)
		click_move_sample_time += delta
		if click_move_sample_time >= 0.24:
			# Compare stable samples rather than raw collision-resolution motion;
			# a body can briefly penetrate and be corrected while still making no
			# meaningful progress toward the chosen point.
			if target_distance < click_move_sample_distance - 0.05:
				click_move_sample_distance = target_distance
				click_move_stall_time = 0.0
			else:
				click_move_stall_time += click_move_sample_time
			click_move_sample_time = 0.0
			if click_move_stall_time >= 0.72:
				cancel_navigation(true)
				if world != null and world.has_method("navigation_target_blocked"):
					world.call("navigation_target_blocked")
	if world != null and world.has_method("player_moved"):
		world.player_moved(global_position.distance_to(previous_position) > 0.002)

func _update_illustrated_character() -> void:
	if visual == null:
		return
	var sprite := visual.get_node_or_null("IllustratedCharacter") as Sprite3D
	if sprite == null:
		return
	var idle_atlas := sprite.get_meta("idle_atlas", null) as AtlasTexture
	var walk_atlas := sprite.get_meta("walk_atlas", null) as AtlasTexture
	if idle_atlas == null or walk_atlas == null:
		return
	var idle_cell_size: Array = sprite.get_meta("idle_cell_size", sprite.get_meta("cell_size", []))
	var walk_cell_size: Array = sprite.get_meta("walk_cell_size", [])
	if idle_cell_size.size() < 2 or walk_cell_size.size() < 2:
		return
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var walking := horizontal_speed > 0.28
	var direction_frame := _character_direction_frame(last_direction)
	var idle_width := float(idle_cell_size[0])
	var idle_height := float(idle_cell_size[1])
	var walk_width := float(walk_cell_size[0])
	var walk_height := float(walk_cell_size[1])
	var idle_gaps: Array = sprite.get_meta("idle_bottom_gaps", [])
	var walk_gaps: Array = sprite.get_meta("walk_bottom_gaps", [])
	if walking:
		var frame_count := maxi(1, int(sprite.get_meta("walk_frame_count", 4)))
		var frame_rate := maxf(1.0, float(sprite.get_meta("walk_frame_rate", 8.0)))
		var walk_frame := posmod(int(floor(walk_frame_time * frame_rate)), frame_count)
		walk_atlas.region = Rect2(float(walk_frame) * walk_width, float(direction_frame) * walk_height, walk_width, walk_height)
		sprite.texture = walk_atlas
		var direction_gaps: Array = walk_gaps[direction_frame] if direction_frame < walk_gaps.size() and walk_gaps[direction_frame] is Array else []
		var bottom_gap := float(direction_gaps[walk_frame]) if walk_frame < direction_gaps.size() else 0.0
		sprite.offset = Vector2(-walk_width * 0.5, -bottom_gap)
		sprite.set_meta("animation_frame", walk_frame)
		sprite.set_meta("animation_frame_rate", frame_rate)
	else:
		idle_atlas.region = Rect2(float(direction_frame) * idle_width, 0.0, idle_width, idle_height)
		sprite.texture = idle_atlas
		var bottom_gap := float(idle_gaps[direction_frame]) if direction_frame < idle_gaps.size() else 0.0
		sprite.offset = Vector2(-idle_width * 0.5, -bottom_gap)
		sprite.set_meta("animation_frame", 0)
		sprite.set_meta("animation_frame_rate", 0.0)
	sprite.set_meta("animation_state", "walk" if walking else "idle")
	sprite.set_meta("direction_frame", direction_frame)

func _character_direction_frame(direction: Vector3) -> int:
	if world != null and world.has_method("camera_screen_direction"):
		var screen_direction: Vector2 = world.call("camera_screen_direction", direction)
		if screen_direction.length_squared() > 0.0001:
			if absf(screen_direction.x) > absf(screen_direction.y):
				return 1 if screen_direction.x > 0.0 else 3
			return 2 if screen_direction.y < 0.0 else 0
	if absf(direction.z) >= absf(direction.x):
		return 2 if direction.z < 0.0 else 0
	return 3 if direction.x < 0.0 else 1

func set_joystick_vector(value: Vector2) -> void:
	joystick_vector = value
	if value.length() > 0.05:
		cancel_navigation(false)

func set_click_move_target(value: Vector3) -> void:
	click_move_target = value
	click_move_target.y = global_position.y
	click_move_active = true
	click_move_stall_time = 0.0
	click_move_sample_time = 0.0
	click_move_sample_distance = global_position.distance_to(click_move_target)

func clear_click_move_target() -> void:
	cancel_navigation(true)

func cancel_navigation(stop_velocity := true) -> void:
	click_move_active = false
	click_move_stall_time = 0.0
	click_move_sample_time = 0.0
	click_move_sample_distance = INF
	if stop_velocity:
		velocity.x = 0.0
		velocity.z = 0.0

func attack() -> void:
	if attack_cooldown > 0.0:
		return
	if world != null and world.has_method("_player_attack"):
		world.call("_player_attack", self)

func can_dodge() -> bool:
	return dodge_cooldown <= 0.0 and last_direction.length_squared() > 0.01

func start_dodge() -> bool:
	if not can_dodge():
		return false
	var session_node: Node = world.get("session") as Node if world != null else null
	dodge_cooldown = float(session_node.call("dodge_cooldown_seconds")) if session_node != null and session_node.has_method("dodge_cooldown_seconds") else 0.8
	invulnerable_time = 0.3
	var travel := last_direction.normalized() * 2.2
	move_and_collide(travel)
	global_position.x = clampf(global_position.x, -WORLD_LIMIT_X, WORLD_LIMIT_X)
	global_position.z = clampf(global_position.z, -WORLD_LIMIT_Z, WORLD_LIMIT_Z)
	_start_action_timeline("dodge")
	if world != null and world.has_method("player_moved"):
		world.player_moved(true)
	return true

func take_damage(amount: int) -> void:
	if hurt_time > 0.0 or invulnerable_time > 0.0:
		return
	hurt_time = 0.4
	_start_action_timeline("hurt")
	if world != null and world.has_method("player_took_damage"):
		world.player_took_damage(amount)
	else:
		health = maxi(0, health - amount)

func play_attack_feedback() -> void:
	_start_action_timeline("attack")

func cancel_attack_feedback() -> void:
	_cancel_action_timeline("attack")

func play_gather_feedback(resource_id := "wood") -> void:
	if visual == null or gather_active:
		return
	gather_active = true
	var gather_tool := visual.get_node_or_null("GatherTool") as MeshInstance3D
	if gather_tool != null:
		var tool_color := Color("#a9784e")
		if resource_id in ["stone", "ore", "sunstone"]:
			tool_color = Color("#a9bbc0")
		elif resource_id in ["fiber", "berries", "shell"]:
			tool_color = Color("#d9a86c")
		var tool_material := gather_tool.material_override as StandardMaterial3D
		if tool_material != null:
			tool_material.albedo_color = tool_color
	_start_action_timeline("gather_prepare", resource_id)

func finish_gather_feedback() -> void:
	gather_active = false
	_start_action_timeline("gather_contact", action_animation_resource)

func cancel_gather_feedback() -> void:
	gather_active = false
	_cancel_action_timeline("gather")

func _timeline_definition(state: String) -> Dictionary:
	match state:
		"attack":
			return {
				"duration": 0.42,
				"frames": [
					{"at": 0.00, "marker": "windup", "scale_x": 1.00, "scale_y": 1.00, "lift": 0.00, "tilt": 0.00, "slash_scale": 0.00, "slash_pitch": -0.30, "slash_yaw": -0.65, "slash_roll": -0.45, "slash_visible": false},
					{"at": 0.12, "marker": "contact", "scale_x": 1.10, "scale_y": 0.90, "lift": 0.02, "tilt": -0.06, "slash_scale": 0.78, "slash_pitch": -0.24, "slash_yaw": 0.15, "slash_roll": 0.18, "slash_visible": true},
					{"at": 0.24, "marker": "followthrough", "scale_x": 1.03, "scale_y": 0.97, "lift": 0.01, "tilt": 0.04, "slash_scale": 1.00, "slash_pitch": -0.18, "slash_yaw": 0.72, "slash_roll": 0.42, "slash_visible": true},
					{"at": 0.42, "marker": "recovery", "scale_x": 1.00, "scale_y": 1.00, "lift": 0.00, "tilt": 0.00, "slash_scale": 0.15, "slash_pitch": -0.18, "slash_yaw": 0.72, "slash_roll": 0.42, "slash_visible": false},
				]
			}
		"gather_prepare":
			return {
				"duration": 0.20,
				"frames": [
					{"at": 0.00, "marker": "prepare", "scale_x": 1.00, "scale_y": 1.00, "lift": 0.00, "tilt": 0.00, "tool_scale": 0.35, "tool_pitch": -0.48, "tool_roll": -0.52, "tool_visible": true},
					{"at": 0.20, "marker": "ready", "scale_x": 1.02, "scale_y": 0.96, "lift": 0.03, "tilt": -0.04, "tool_scale": 0.80, "tool_pitch": -0.68, "tool_roll": -0.64, "tool_visible": true},
				]
			}
		"gather_contact":
			return {
				"duration": 0.34,
				"frames": [
					{"at": 0.00, "marker": "contact", "scale_x": 1.02, "scale_y": 0.96, "lift": 0.03, "tilt": -0.04, "tool_scale": 0.80, "tool_pitch": -0.68, "tool_roll": -0.64, "tool_visible": true},
					{"at": 0.10, "marker": "strike", "scale_x": 1.08, "scale_y": 0.90, "lift": 0.03, "tilt": -0.08, "tool_scale": 1.15, "tool_pitch": -1.12, "tool_roll": -0.72, "tool_visible": true},
					{"at": 0.20, "marker": "return", "scale_x": 1.00, "scale_y": 1.00, "lift": 0.00, "tilt": 0.03, "tool_scale": 0.78, "tool_pitch": -0.48, "tool_roll": -0.52, "tool_visible": true},
					{"at": 0.34, "marker": "done", "scale_x": 1.00, "scale_y": 1.00, "lift": 0.00, "tilt": 0.00, "tool_scale": 0.10, "tool_pitch": -0.48, "tool_roll": -0.52, "tool_visible": false},
				]
			}
		"dodge":
			return {
				"duration": 0.30,
				"frames": [
					{"at": 0.00, "marker": "launch", "scale_x": 1.00, "scale_y": 1.00, "lift": 0.00, "tilt": 0.00},
					{"at": 0.08, "marker": "stride", "scale_x": 1.28, "scale_y": 0.72, "lift": 0.08, "tilt": -0.14},
					{"at": 0.30, "marker": "recover", "scale_x": 1.00, "scale_y": 1.00, "lift": 0.00, "tilt": 0.00},
				]
			}
		"hurt":
			return {
				"duration": 0.40,
				"frames": [
					{"at": 0.00, "marker": "impact", "scale_x": 1.00, "scale_y": 1.00, "lift": 0.00, "tilt": 0.00},
					{"at": 0.05, "marker": "flinch", "scale_x": 0.85, "scale_y": 1.12, "lift": 0.00, "tilt": 0.12},
					{"at": 0.18, "marker": "rebound", "scale_x": 1.08, "scale_y": 0.92, "lift": 0.00, "tilt": -0.08},
					{"at": 0.40, "marker": "recover", "scale_x": 1.00, "scale_y": 1.00, "lift": 0.00, "tilt": 0.00},
				]
			}
	return {"duration": 0.0, "frames": []}

func _start_action_timeline(state: String, resource_id := "") -> void:
	var definition := _timeline_definition(state)
	var frames: Array = definition.get("frames", [])
	if frames.is_empty():
		return
	_reset_action_presentation()
	action_animation_state = state
	action_animation_elapsed = 0.0
	action_animation_frame = 0
	action_animation_marker = str(frames[0].get("marker", state))
	action_animation_resource = resource_id
	action_pose_time = float(definition.get("duration", 0.0))
	_apply_action_timeline_frame(definition)

func _update_action_timeline(delta: float) -> void:
	if action_animation_state == "idle":
		return
	var definition := _timeline_definition(action_animation_state)
	var duration := float(definition.get("duration", 0.0))
	action_animation_elapsed = minf(duration, action_animation_elapsed + delta)
	_apply_action_timeline_frame(definition)
	if action_animation_state == "gather_prepare":
		return
	if action_animation_elapsed >= duration:
		_finish_action_timeline()

func _apply_action_timeline_frame(definition: Dictionary) -> void:
	var frames: Array = definition.get("frames", [])
	if frames.is_empty():
		return
	var frame_index := 0
	for index in frames.size():
		if action_animation_elapsed >= float(frames[index].get("at", 0.0)):
			frame_index = index
	var next_index := mini(frame_index + 1, frames.size() - 1)
	var first: Dictionary = frames[frame_index]
	var second: Dictionary = frames[next_index]
	var first_at := float(first.get("at", 0.0))
	var second_at := float(second.get("at", first_at))
	var blend := 0.0 if next_index == frame_index else clampf((action_animation_elapsed - first_at) / maxf(0.001, second_at - first_at), 0.0, 1.0)
	action_animation_frame = frame_index
	action_animation_marker = str(first.get("marker", action_animation_state))
	if visual != null:
		var scale_x := lerpf(float(first.get("scale_x", 1.0)), float(second.get("scale_x", 1.0)), blend)
		var scale_y := lerpf(float(first.get("scale_y", 1.0)), float(second.get("scale_y", 1.0)), blend)
		visual.scale = Vector3(scale_x, scale_y, scale_x)
		visual.position.y = lerpf(float(first.get("lift", 0.0)), float(second.get("lift", 0.0)), blend)
		visual.rotation.z = lerpf(float(first.get("tilt", 0.0)), float(second.get("tilt", 0.0)), blend)
		var slash := visual.get_node_or_null("CombatSlash") as MeshInstance3D
		if slash != null:
			slash.visible = bool(first.get("slash_visible", false))
			slash.scale = Vector3.ONE * lerpf(float(first.get("slash_scale", 0.0)), float(second.get("slash_scale", 0.0)), blend)
			slash.rotation = Vector3(
				lerpf(float(first.get("slash_pitch", -0.30)), float(second.get("slash_pitch", -0.30)), blend),
				lerpf(float(first.get("slash_yaw", -0.65)), float(second.get("slash_yaw", -0.65)), blend),
				lerpf(float(first.get("slash_roll", -0.45)), float(second.get("slash_roll", -0.45)), blend)
			)
		var gather_tool := visual.get_node_or_null("GatherTool") as MeshInstance3D
		if gather_tool != null:
			gather_tool.visible = bool(first.get("tool_visible", false))
			gather_tool.scale = Vector3.ONE * lerpf(float(first.get("tool_scale", 0.0)), float(second.get("tool_scale", 0.0)), blend)
			gather_tool.rotation = Vector3(
				lerpf(float(first.get("tool_pitch", -0.48)), float(second.get("tool_pitch", -0.48)), blend),
				0.0,
				lerpf(float(first.get("tool_roll", -0.52)), float(second.get("tool_roll", -0.52)), blend)
			)
	_update_action_metadata()

func _finish_action_timeline() -> void:
	_reset_action_presentation()
	action_animation_state = "idle"
	action_animation_elapsed = 0.0
	action_animation_frame = 0
	action_animation_marker = "idle"
	action_animation_resource = ""
	_update_action_metadata()

func _cancel_action_timeline(expected_state: String) -> void:
	if expected_state == "attack" and action_animation_state != "attack":
		return
	if expected_state == "gather" and not action_animation_state.begins_with("gather"):
		return
	_finish_action_timeline()

func _reset_action_presentation() -> void:
	action_pose_time = 0.0
	if visual == null:
		return
	visual.scale = Vector3.ONE
	visual.position.y = 0.0
	visual.rotation.z = 0.0
	var slash := visual.get_node_or_null("CombatSlash") as MeshInstance3D
	if slash != null:
		slash.visible = false
		slash.scale = Vector3.ONE
	var gather_tool := visual.get_node_or_null("GatherTool") as MeshInstance3D
	if gather_tool != null:
		gather_tool.visible = false
		gather_tool.scale = Vector3.ONE
		gather_tool.rotation = Vector3(-0.48, 0.0, -0.52)

func _update_action_metadata() -> void:
	if visual == null:
		return
	visual.set_meta("action_animation_state", action_animation_state)
	visual.set_meta("action_animation_elapsed", action_animation_elapsed)
	visual.set_meta("action_animation_frame", action_animation_frame)
	visual.set_meta("action_animation_marker", action_animation_marker)
	visual.set_meta("action_animation_resource", action_animation_resource)
	visual.set_meta("action_animation_source", ACTION_ANIMATION_SOURCE)
	var sprite := visual.get_node_or_null("IllustratedCharacter") as Sprite3D
	if sprite != null:
		sprite.set_meta("action_animation_state", action_animation_state)
		sprite.set_meta("action_animation_elapsed", action_animation_elapsed)
		sprite.set_meta("action_animation_frame", action_animation_frame)
		sprite.set_meta("action_animation_marker", action_animation_marker)
		sprite.set_meta("action_animation_resource", action_animation_resource)
		sprite.set_meta("action_animation_source", ACTION_ANIMATION_SOURCE)
