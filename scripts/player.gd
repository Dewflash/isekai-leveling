class_name ProdewtyPlayer
extends CharacterBody3D

var world: Node
var speed := 5.2
var max_health := 100
var health := 100
var joystick_vector := Vector2.ZERO
var attack_cooldown := 0.0
var dodge_cooldown := 0.0
var invulnerable_time := 0.0
var last_direction := Vector3(0.0, 0.0, -1.0)
var visual: Node3D
var walk_time := 0.0
var hurt_time := 0.0
var gather_active := false
var action_pose_time := 0.0
const WORLD_LIMIT_X := 20.0
const WORLD_LIMIT_Z := 15.0

func _ready() -> void:
	visual = get_node_or_null("Visual")

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	hurt_time = maxf(0.0, hurt_time - delta)
	action_pose_time = maxf(0.0, action_pose_time - delta)
	var keyboard := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		keyboard.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		keyboard.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		keyboard.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		keyboard.y += 1.0
	var input_vector := keyboard
	if joystick_vector.length() > 0.05:
		input_vector = joystick_vector
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	var direction := Vector3(input_vector.x, 0.0, input_vector.y)
	if world != null and world.has_method("camera_relative_direction"):
		direction = world.camera_relative_direction(input_vector)
	velocity.y = 0.0
	if direction.length() > 0.05:
		walk_time += delta * 10.0
		last_direction = direction.normalized()
		velocity.x = move_toward(velocity.x, direction.x * speed, 24.0 * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, 24.0 * delta)
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
		velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)
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
	if world != null and world.has_method("player_moved"):
		world.player_moved(direction.length() > 0.05)

func set_joystick_vector(value: Vector2) -> void:
	joystick_vector = value

func attack() -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = 0.42
	if world != null and world.has_method("_player_attack"):
		world.call("_player_attack", self)

func can_dodge() -> bool:
	return dodge_cooldown <= 0.0 and last_direction.length_squared() > 0.01

func start_dodge() -> bool:
	if not can_dodge():
		return false
	dodge_cooldown = 0.8
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

func play_gather_feedback() -> void:
	if visual == null or gather_active:
		return
	gather_active = true
	action_pose_time = 0.45
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
