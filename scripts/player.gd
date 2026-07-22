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
const WORLD_LIMIT_X := 20.0
const WORLD_LIMIT_Z := 15.0

func _ready() -> void:
	visual = get_node_or_null("Visual")

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
	if visual != null:
		var original := visual.scale
		var tween := create_tween()
		tween.tween_property(visual, "scale", Vector3(1.28, 0.72, 1.28), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual, "scale", original, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if world != null and world.has_method("player_moved"):
		world.player_moved(true)
	return true

func take_damage(amount: int) -> void:
	if hurt_time > 0.0 or invulnerable_time > 0.0:
		return
	hurt_time = 0.4
	if world != null and world.has_method("player_took_damage"):
		world.player_took_damage(amount)
	else:
		health = maxi(0, health - amount)

func play_attack_feedback() -> void:
	if visual == null:
		return
	action_pose_time = 0.42
	var original := visual.scale
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector3(1.12, 0.9, 1.12), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "scale", original, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var weapon_rig := visual.get_node_or_null("WeaponRig") as Node3D
	if weapon_rig != null:
		var weapon_tween := weapon_rig.create_tween()
		weapon_tween.tween_property(weapon_rig, "rotation", Vector3(0.0, 0.0, -1.25), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		weapon_tween.tween_property(weapon_rig, "rotation", Vector3(0.0, 0.0, 0.25), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		weapon_tween.tween_property(weapon_rig, "rotation", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	var arm_right := visual.get_node_or_null("ArmRight") as Node3D
	if arm_right != null:
		var arm_tween := arm_right.create_tween()
		arm_tween.tween_property(arm_right, "rotation:x", -0.65, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		arm_tween.tween_property(arm_right, "rotation:x", 0.18, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		arm_tween.tween_property(arm_right, "rotation:x", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	var slash := visual.get_node_or_null("CombatSlash") as MeshInstance3D
	if slash != null:
		slash.visible = true
		slash.scale = Vector3(0.35, 0.35, 0.35)
		slash.rotation = Vector3(-0.30, -0.65, -0.45)
		var slash_tween := slash.create_tween()
		slash_tween.tween_property(slash, "scale", Vector3.ONE, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		slash_tween.tween_property(slash, "rotation", Vector3(-0.18, 0.72, 0.42), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		slash_tween.tween_property(slash, "scale", Vector3(0.25, 0.25, 0.25), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		slash_tween.tween_callback(func() -> void:
			slash.visible = false
		)

func cancel_attack_feedback() -> void:
	if visual == null:
		return
	var slash := visual.get_node_or_null("CombatSlash") as MeshInstance3D
	if slash != null:
		slash.visible = false
		slash.scale = Vector3.ONE
	action_pose_time = 0.0

func play_gather_feedback(resource_id := "wood") -> void:
	if visual == null or gather_active:
		return
	gather_active = true
	action_pose_time = 0.45
	var gather_tool := visual.get_node_or_null("GatherTool") as MeshInstance3D
	if gather_tool != null:
		gather_tool.visible = true
		var tool_color := Color("#a9784e")
		if resource_id in ["stone", "ore", "sunstone"]:
			tool_color = Color("#a9bbc0")
		elif resource_id in ["fiber", "berries", "shell"]:
			tool_color = Color("#d9a86c")
		var tool_material := gather_tool.material_override as StandardMaterial3D
		if tool_material != null:
			tool_material.albedo_color = tool_color
	var weapon_rig := visual.get_node_or_null("WeaponRig") as Node3D
	if weapon_rig != null:
		var tween := weapon_rig.create_tween()
		tween.tween_property(weapon_rig, "rotation", Vector3(-0.28, 0.0, -0.48), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var arm_left := visual.get_node_or_null("ArmLeft") as Node3D
	if arm_left != null:
		arm_left.rotation.x = -0.34

func finish_gather_feedback() -> void:
	if visual == null:
		return
	gather_active = false
	action_pose_time = 0.34
	var weapon_rig := visual.get_node_or_null("WeaponRig") as Node3D
	if weapon_rig != null:
		var tween := weapon_rig.create_tween()
		tween.tween_property(weapon_rig, "rotation", Vector3(0.92, 0.0, -1.02), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(weapon_rig, "rotation", Vector3.ZERO, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var arm_left := visual.get_node_or_null("ArmLeft") as Node3D
	if arm_left != null:
		var arm_tween := arm_left.create_tween()
		arm_tween.tween_property(arm_left, "rotation:x", 0.78, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		arm_tween.tween_property(arm_left, "rotation:x", 0.0, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var gather_tool := visual.get_node_or_null("GatherTool") as MeshInstance3D
	if gather_tool != null:
		var tool_tween := gather_tool.create_tween()
		tool_tween.tween_property(gather_tool, "rotation", Vector3(-1.12, 0.0, -0.72), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tool_tween.tween_property(gather_tool, "rotation", Vector3(-0.48, 0.0, -0.52), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tool_tween.tween_callback(func() -> void: gather_tool.visible = false)

func cancel_gather_feedback() -> void:
	gather_active = false
	action_pose_time = 0.0
	if visual != null:
		var weapon_rig := visual.get_node_or_null("WeaponRig") as Node3D
		if weapon_rig != null:
			weapon_rig.rotation = Vector3.ZERO
		var arm_left := visual.get_node_or_null("ArmLeft") as Node3D
		if arm_left != null:
			arm_left.rotation = Vector3.ZERO
		var gather_tool := visual.get_node_or_null("GatherTool") as MeshInstance3D
		if gather_tool != null:
			gather_tool.visible = false
