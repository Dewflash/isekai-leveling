extends Node3D

## A small living prop for the Sanctuary pen. Its movement is intentionally
## bounded and deterministic enough to read as a resident, not a physics test.

var world: Node
var animal_id := "clover"
var home := Vector3.ZERO
var target := Vector3.ZERO
var wait_time := 0.0
var phase := 0.0

func _ready() -> void:
	home = global_position
	target = home
	phase = home.x * 0.4 + home.z * 0.27

func _process(delta: float) -> void:
	if world == null or not is_instance_valid(world) or str(world.get("current_zone")) != "Sanctuary":
		return
	var session: Node = world.get("session") as Node
	if session == null or not bool(session.get("built").get("livestock_pen", false)):
		return
	wait_time = maxf(0.0, wait_time - delta)
	if wait_time <= 0.0 and global_position.distance_to(target) < 0.18:
		target = home + Vector3(randf_range(-1.25, 1.25), 0.0, randf_range(-0.75, 0.75))
		wait_time = randf_range(0.4, 2.0)
	var distance := global_position.distance_to(target)
	if distance > 0.16:
		var direction := global_position.direction_to(target)
		global_position = global_position.move_toward(target, minf(distance, delta * 0.44))
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 4.0)
	var visual := get_node_or_null("Visual") as Node3D
	if visual != null:
		visual.position.y = sin(Time.get_ticks_msec() * 0.007 + phase) * 0.035
		if distance > 0.16:
			visual.rotation.z = sin(Time.get_ticks_msec() * 0.012 + phase) * 0.035
