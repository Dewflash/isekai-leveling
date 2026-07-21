class_name ProdewtyGuardian
extends CharacterBody3D

var world: Node
var target: Node3D
var health := 18
var max_health := 18
var attack_damage := 5
var attack_cooldown := 0.0
var attack_windup := 0.0
var attack_recovery := 0.0
var stagger_time := 0.0
var behavior_id := "chaser"
var move_speed := 1.7
var attack_range := 2.4
var attack_windup_duration := 0.38
var attack_cooldown_duration := 1.35
var attack_recovery_duration := 0.34
var pursuit_radius := 13.0
var guarding := false
var zone_active := true
var spawn_position := Vector3.ZERO
var phase := 0.0
var alerted := false
var alert_timer := 0.0
var investigate_position := Vector3.ZERO
var behavior_state := "idle"
var visual: Node3D
var health_label: Label3D
var enemy_label := "FOREST SLIME"
var reward_id := "slime_gel"
var reward_amount := 1
var guardian_id := "forest_slime"
var orbit_phase := 0.0
var retreat_time := 0.0

func _ready() -> void:
	phase = global_position.x * 0.17 + global_position.z * 0.11
	orbit_phase = phase + float(guardian_id.hash() % 17) * 0.17
	spawn_position = global_position
	visual = get_node_or_null("Visual")

func _physics_process(delta: float) -> void:
	if not visible or not is_instance_valid(target):
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	attack_recovery = maxf(0.0, attack_recovery - delta)
	stagger_time = maxf(0.0, stagger_time - delta)
	retreat_time = maxf(0.0, retreat_time - delta)
	alert_timer = maxf(0.0, alert_timer - delta)
	if alert_timer <= 0.0:
		alerted = false
		behavior_state = "idle"
	# The visual and hurtbox share the same grounded local pivot. Keep the
	# contact shape on the animated body rather than letting a bobbing creature
	# leave an invisible hitbox floating above or below its art.
	var bob_offset := sin(Time.get_ticks_msec() * 0.006 + phase) * 0.07
	if visual != null:
		visual.position.y = bob_offset
	_sync_collision_to_visual()
	if attack_windup > 0.0:
		guarding = true
		attack_windup = maxf(0.0, attack_windup - delta)
		velocity = Vector3.ZERO
		if visual != null:
			visual.scale = Vector3.ONE * (1.0 + (0.38 - attack_windup) * 0.28)
		_sync_collision_to_visual()
		if health_label != null:
			health_label.text = "%s\n!!  %d / %d" % [enemy_label, maxi(0, health), max_health]
		if attack_windup <= 0.0 and world != null:
			attack_cooldown = attack_cooldown_duration
			attack_recovery = attack_recovery_duration
			if behavior_id == "skirmisher":
				# A skirmisher commits to the strike, then creates a readable gap
				# instead of standing inside the player's hitbox. The retreat is a
				# movement state only; damage still resolves through guardian_attack.
				retreat_time = 0.46
			guarding = false
			if world.has_method("guardian_attack"):
				world.guardian_attack(self)
			if visual != null:
				visual.scale = Vector3.ONE
			_sync_collision_to_visual()
			return
		# Keep the guard active for every intermediate wind-up frame. A light
		# hit must be able to read this state and bounce/reduce damage; only the
		# active attack frame or a guard-breaking impact should clear it.
	if health_label != null:
		health_label.text = "%s\n%d / %d" % [enemy_label, health, max_health]
	if attack_recovery > 0.0 or stagger_time > 0.0:
		guarding = false
		velocity = Vector3.ZERO
		return
	if not alerted:
		velocity = Vector3.ZERO
		return
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if behavior_id == "skirmisher" and retreat_time > 0.0 and distance > 0.01:
		var away := -to_target.normalized()
		var tangent := Vector3(-away.z, 0.0, away.x)
		var orbit_sign := -1.0 if sin(Time.get_ticks_msec() * 0.001 + orbit_phase) < 0.0 else 1.0
		var retreat_direction := (away + tangent * 0.42 * orbit_sign).normalized()
		velocity = retreat_direction * move_speed * 1.18
		behavior_state = "retreat"
		move_and_slide()
		if health_label != null:
			health_label.text = "%s\n↤  RETREATING" % enemy_label
		return
	if behavior_state == "investigate":
		var to_noise := investigate_position - global_position
		to_noise.y = 0.0
		# A CharacterBody3D cannot occupy the exact player/noise point: its own
		# measured hurtbox and the player's body stop it first. Use a readable
		# arrival envelope derived from this guardian's authored attack reach, or
		# an investigate state can remain stuck forever at the contact boundary.
		var investigate_arrival_radius := maxf(0.80, attack_range * 0.82)
		if to_noise.length() > investigate_arrival_radius:
			velocity = to_noise.normalized() * move_speed * 0.72
			var investigate_before_move := global_position
			move_and_slide()
			if global_position.distance_to(investigate_before_move) < 0.01 and global_position.distance_to(target.global_position) <= pursuit_radius:
				# A route prop may legitimately block the straight investigation
				# line. Do not let the guardian push against one collider forever;
				# switch to pursuit and let the target-facing movement recover.
				behavior_state = "chase"
			if health_label != null:
				health_label.text = "%s\n!  INVESTIGATING" % enemy_label
			return
		# A guardian only commits to pursuit after it has physically reached the
		# sound. This keeps footsteps readable as a world event rather than an
		# invisible instant aggro switch.
		var target_distance := global_position.distance_to(target.global_position)
		if target_distance <= pursuit_radius:
			behavior_state = "chase"
		else:
			alerted = false
			behavior_state = "idle"
			velocity = Vector3.ZERO
			return
	if distance < pursuit_radius:
		behavior_state = "chase"
		if behavior_id == "skirmisher" and distance <= attack_range and distance < maxf(1.35, attack_range * 0.78):
			# Stay just outside the most comfortable player swing range when the
			# skirmisher's attack is cooling down. It will re-enter for a strike
			# once its cooldown has elapsed.
			var away := -to_target.normalized()
			var tangent := Vector3(-away.z, 0.0, away.x)
			var orbit_sign := -1.0 if sin(Time.get_ticks_msec() * 0.001 + orbit_phase) < 0.0 else 1.0
			velocity = (away + tangent * 0.58 * orbit_sign).normalized() * move_speed * 0.82
			behavior_state = "spacing"
			move_and_slide()
			if health_label != null:
				health_label.text = "%s\n↔  SPACING" % enemy_label
		elif distance > attack_range:
			var chase_multiplier := 0.92 if behavior_id == "bruiser" else 1.0
			velocity = to_target.normalized() * move_speed * chase_multiplier
			move_and_slide()
		else:
			velocity = Vector3.ZERO
			if attack_cooldown <= 0.0 and attack_windup <= 0.0:
				if world != null and world.has_method("guardian_ambush_warning"):
					world.call("guardian_ambush_warning", self)
				attack_windup = attack_windup_duration
	else:
		# Stop at the edge of the territory, but remember the player's last
		# position as a physical investigation point instead of silently snapping
		# back to idle.
		behavior_state = "investigate"
		investigate_position = target.global_position
		velocity = Vector3.ZERO

func take_damage(amount: int, impact: Dictionary = {}) -> void:
	if not _encounter_is_ready() or health <= 0 or not visible:
		return
	var was_guarding := guarding or attack_windup > 0.0
	var guard_break := bool(impact.get("guard_break", false))
	health -= amount
	if guard_break or not was_guarding:
		attack_windup = 0.0
		guarding = false
	else:
		# A guarded light hit is reduced and staggered, but does not erase the
		# readable attack telegraph. Only a guard break cancels the wind-up.
		guarding = true
	alerted = true
	alert_timer = 10.0
	behavior_state = "chase"
	var stagger_multiplier := clampf(float(impact.get("opening_stagger_multiplier", 1.0)), 1.0, 3.0)
	stagger_time = maxf(stagger_time, (0.28 if guard_break else (0.14 if was_guarding else 0.08)) * stagger_multiplier)
	attack_recovery = maxf(attack_recovery, 0.16)
	if visual != null:
		var hit_tween := visual.create_tween()
		hit_tween.tween_property(visual, "scale", Vector3(1.16, 0.82, 1.16) if guard_break else Vector3(1.08, 0.92, 1.08), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		hit_tween.tween_property(visual, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if health_label != null:
		health_label.text = "%s\n%d / %d" % [enemy_label, maxi(0, health), max_health]
	if world != null and world.has_method("combat_feedback"):
		world.combat_feedback(self, amount)
	if health <= 0:
		var reward_resolved := true
		if world != null and world.has_method("guardian_defeated"):
			reward_resolved = bool(world.call("guardian_defeated", self))
		if reward_resolved:
			visible = false
			set_physics_process(false)
			var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
			if collision != null:
				collision.disabled = true
		else:
			# A full satchel is a recoverable tactical state, not a silently
			# deleted guardian reward. Leave the enemy standing at one HP so the
			# player can extract, make room, and finish the encounter.
			health = 1
			attack_cooldown = 1.0
			alerted = false

func restore() -> void:
	health = max_health
	visible = true
	global_position = spawn_position
	velocity = Vector3.ZERO
	if visual != null:
		visual.position.y = 0.0
		visual.scale = Vector3.ONE
	_sync_collision_to_visual()
	attack_cooldown = 0.0
	attack_windup = 0.0
	attack_recovery = 0.0
	stagger_time = 0.0
	retreat_time = 0.0
	guarding = false
	alerted = false
	alert_timer = 0.0
	behavior_state = "idle"
	set_active(zone_active)

func hear_noise(position: Vector3, intensity: float = 6.0) -> void:
	var flat_noise_distance := global_position - position
	flat_noise_distance.y = 0.0
	if not _encounter_is_ready() or not zone_active or not visible or flat_noise_distance.length() > intensity:
		return
	alerted = true
	alert_timer = 10.0
	investigate_position = position
	behavior_state = "investigate"
	if health_label != null:
		health_label.text = "%s\n!  Investigating" % enemy_label

func set_active(active: bool) -> void:
	zone_active = active and _encounter_is_ready()
	if not zone_active:
		# Zone transitions pause the physics clock. Clear transient combat state
		# so a guardian cannot resume halfway through an old wind-up or recovery
		# after the player returns to the map.
		attack_windup = 0.0
		attack_recovery = 0.0
		stagger_time = 0.0
		retreat_time = 0.0
		guarding = false
		behavior_state = "idle"
	set_physics_process(zone_active and health > 0 and visible)
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision != null:
		collision.disabled = not zone_active or health <= 0 or not visible

func _encounter_is_ready() -> bool:
	## A route guardian is a committed-trail encounter, not a punishment for
	## merely walking near the fork. Keep it dormant until the authoritative run
	## has selected the branch that owns this guardian.
	if world == null or not is_instance_valid(world):
		return false
	var session := world.get("session") as Node
	if session == null or not session.has_method("has_active_expedition") or not bool(session.call("has_active_expedition")):
		return false
	var run: Dictionary = session.get("expedition_run") if session.get("expedition_run") is Dictionary else {}
	if str(run.get("biome_id", "")).replace(" ", "") != str(get_parent().name if get_parent() != null else ""):
		return false
	return not str(run.get("branch_id", "")).is_empty()

func _sync_collision_to_visual() -> void:
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null or collision.shape == null or visual == null:
		return
	var base_size_value: Variant = collision.get_meta("base_shape_size", [])
	var base_center_value: Variant = collision.get_meta("base_shape_center", [])
	if not base_size_value is Array or (base_size_value as Array).size() < 3:
		return
	if not base_center_value is Array or (base_center_value as Array).size() < 3:
		return
	var base_size := base_size_value as Array
	var base_center := base_center_value as Array
	var visual_scale := visual.scale.abs()
	if collision.shape is BoxShape3D:
		var box := collision.shape as BoxShape3D
		box.size = Vector3(
			maxf(0.01, float(base_size[0]) * visual_scale.x),
			maxf(0.01, float(base_size[1]) * visual_scale.y),
			maxf(0.01, float(base_size[2]) * visual_scale.z)
		)
	elif collision.shape is CylinderShape3D:
		var cylinder := collision.shape as CylinderShape3D
		cylinder.radius = maxf(0.01, float(collision.get_meta("base_shape_radius", cylinder.radius)) * maxf(visual_scale.x, visual_scale.z))
		cylinder.height = maxf(0.01, float(collision.get_meta("base_shape_height", cylinder.height)) * visual_scale.y)
	collision.position = Vector3(
		float(base_center[0]) * visual_scale.x,
		float(base_center[1]) * visual_scale.y + visual.position.y,
		float(base_center[2]) * visual_scale.z
	)

func set_defeated_from_save(value: bool) -> void:
	if value:
		health = 0
		visible = false
		velocity = Vector3.ZERO
		set_active(false)
	else:
		# Only defeated IDs are persisted. A failed full-satchel reward can leave
		# the encounter at one HP for this run, but a later run respawns it whole.
		health = max_health
		visible = true
		set_active(zone_active)

func restore_from_saved_state(state: Dictionary) -> void:
	var saved_health: Variant = state.get("health", 0)
	var saved_position: Variant = state.get("position", [])
	if not (saved_health is int or saved_health is float) or not (saved_position is Array) or saved_position.size() < 3:
		set_defeated_from_save(false)
		return
	health = clampi(int(saved_health), 1, max_health)
	global_position = Vector3(float(saved_position[0]), 1.0, float(saved_position[2]))
	velocity = Vector3.ZERO
	attack_cooldown = 0.0
	attack_windup = 0.0
	attack_recovery = 0.0
	stagger_time = 0.0
	retreat_time = 0.0
	guarding = false
	alerted = false
	alert_timer = 0.0
	behavior_state = "idle"
	visible = true
	if visual != null:
		visual.position.y = 0.0
		visual.scale = Vector3.ONE
	_sync_collision_to_visual()
	set_active(zone_active)

func capture_combat_state() -> Dictionary:
	return {
		"health": health,
		"position": global_position,
		"velocity": velocity,
		"attack_cooldown": attack_cooldown,
		"attack_windup": attack_windup,
		"attack_recovery": attack_recovery,
		"stagger_time": stagger_time,
		"retreat_time": retreat_time,
		"guarding": guarding,
		"alerted": alerted,
		"alert_timer": alert_timer,
		"behavior_state": behavior_state,
		"visible": visible,
	}

func restore_combat_state(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	health = clampi(int(snapshot.get("health", max_health)), 0, max_health)
	var saved_position: Variant = snapshot.get("position", global_position)
	if saved_position is Vector3:
		global_position = saved_position
	var saved_velocity: Variant = snapshot.get("velocity", Vector3.ZERO)
	velocity = saved_velocity if saved_velocity is Vector3 else Vector3.ZERO
	attack_cooldown = maxf(0.0, float(snapshot.get("attack_cooldown", 0.0)))
	attack_windup = maxf(0.0, float(snapshot.get("attack_windup", 0.0)))
	attack_recovery = maxf(0.0, float(snapshot.get("attack_recovery", 0.0)))
	stagger_time = maxf(0.0, float(snapshot.get("stagger_time", 0.0)))
	retreat_time = maxf(0.0, float(snapshot.get("retreat_time", 0.0)))
	guarding = bool(snapshot.get("guarding", false))
	alerted = bool(snapshot.get("alerted", false))
	alert_timer = maxf(0.0, float(snapshot.get("alert_timer", 0.0)))
	behavior_state = str(snapshot.get("behavior_state", "idle"))
	visible = bool(snapshot.get("visible", true)) and health > 0
	if visual != null:
		visual.scale = Vector3.ONE
		visual.position.y = 0.0
	_sync_collision_to_visual()
	set_active(zone_active)
