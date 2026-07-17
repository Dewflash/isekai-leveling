class_name ProdewtyGuardian
extends CharacterBody3D

var world: Node
var target: Node3D
var health := 18
var max_health := 18
var attack_damage := 5
var attack_cooldown := 0.0
var attack_windup := 0.0
var zone_active := true
var spawn_position := Vector3.ZERO
var phase := 0.0
var alerted := false
var alert_timer := 0.0
var investigate_position := Vector3.ZERO
var visual: Node3D
var health_label: Label3D
var enemy_label := "FOREST SLIME"
var reward_id := "slime_gel"
var reward_amount := 1
var guardian_id := "forest_slime"

func _ready() -> void:
	phase = global_position.x * 0.17 + global_position.z * 0.11
	spawn_position = global_position
	visual = get_node_or_null("Visual")

func _physics_process(delta: float) -> void:
	if not visible or not is_instance_valid(target):
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	alert_timer = maxf(0.0, alert_timer - delta)
	if alert_timer <= 0.0:
		alerted = false
	if attack_windup > 0.0:
		attack_windup = maxf(0.0, attack_windup - delta)
		velocity = Vector3.ZERO
		if visual != null:
			visual.scale = Vector3.ONE * (1.0 + (0.38 - attack_windup) * 0.28)
		if health_label != null:
			health_label.text = "%s\n!!  %d / %d" % [enemy_label, maxi(0, health), max_health]
		if attack_windup <= 0.0 and world != null:
			attack_cooldown = 1.35
			if world.has_method("guardian_attack"):
				world.guardian_attack(self)
			if visual != null:
				visual.scale = Vector3.ONE
		return
	if visual != null:
		visual.position.y = 0.86 + sin(Time.get_ticks_msec() * 0.006 + phase) * 0.07
	if health_label != null:
		health_label.text = "%s\n%d / %d" % [enemy_label, health, max_health]
	if not alerted:
		velocity = Vector3.ZERO
		return
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if distance < 13.0:
		if distance > 2.4:
			velocity = to_target.normalized() * 1.7
			move_and_slide()
		else:
			velocity = Vector3.ZERO
			if attack_cooldown <= 0.0 and attack_windup <= 0.0:
				attack_windup = 0.38
	else:
		velocity = Vector3.ZERO

func take_damage(amount: int) -> void:
	if health <= 0 or not visible:
		return
	health -= amount
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
	attack_cooldown = 0.0
	attack_windup = 0.0
	alerted = false
	alert_timer = 0.0
	set_active(zone_active)

func hear_noise(position: Vector3, intensity: float = 6.0) -> void:
	if not zone_active or not visible or global_position.distance_to(position) > intensity:
		return
	alerted = true
	alert_timer = 10.0
	investigate_position = position
	if health_label != null:
		health_label.text = "%s\n!  Investigating" % enemy_label

func set_active(active: bool) -> void:
	zone_active = active
	set_physics_process(active and health > 0 and visible)
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision != null:
		collision.disabled = not active or health <= 0 or not visible

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
