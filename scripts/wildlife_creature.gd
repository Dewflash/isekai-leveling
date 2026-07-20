class_name ProdewtyWildlifeCreature
extends Node3D

## Small, non-hostile ambient creatures. Their positions are intentionally not
## persisted: map dressing is deterministic and only the player observation is
## part of the authoritative save.

var world: Node
var wildlife_id := ""
var species_id := ""
var species_label := "Wildlife"
var zone_id := ""
var wander_radius := 1.5
var move_speed := 0.6
var flee_distance := 2.2
var phase_offset := 0.0
var observed := false
var visual_root: Node3D
var label_node: Label3D
var home_position := Vector3.ZERO
var target_position := Vector3.ZERO
var phase := 0.0
var wander_timer := 0.0
var flee_timer := 0.0
var state := "idle"

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("wildlife_creature")
	process_mode = Node.PROCESS_MODE_PAUSABLE
	phase = float(abs(wildlife_id.hash() % 1000)) * 0.01 + phase_offset
	home_position = position
	target_position = position
	wander_timer = 0.8 + fmod(phase, 1.5)

func interact(_actor: Node) -> void:
	if world != null and world.has_method("observe_wildlife"):
		world.call("observe_wildlife", self)

func set_observed(value: bool) -> void:
	observed = value
	_update_label()

func reveal_observation() -> void:
	set_observed(true)
	flee_timer = 0.7
	state = "fleeing"
	_choose_flee_target()

func _process(delta: float) -> void:
	if world == null or not is_visible_in_tree() or str(world.get("current_zone")) != zone_id:
		return
	var player: Node3D = world.get("player") as Node3D
	if player != null and flee_timer <= 0.0:
		var flat_delta := global_position - player.global_position
		flat_delta.y = 0.0
		if flat_delta.length() <= flee_distance:
			_choose_flee_target()
			flee_timer = 1.25
			state = "fleeing"
	if flee_timer > 0.0:
		flee_timer = maxf(0.0, flee_timer - delta)
		_move_toward_target(delta, move_speed * 1.65)
		if flee_timer <= 0.0:
			state = "idle"
	else:
		wander_timer -= delta
		if wander_timer <= 0.0 or position.distance_to(target_position) <= 0.12:
			_choose_wander_target()
		_move_toward_target(delta, move_speed)
	_animate()

func _choose_wander_target() -> void:
	phase += 1.37
	var angle := phase
	var radius := wander_radius * (0.45 + fmod(abs(sin(phase * 1.17)), 0.55))
	target_position = home_position + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	target_position.y = home_position.y
	wander_timer = 1.0 + fmod(abs(cos(phase * 0.81)), 1.8)
	state = "wandering"

func _choose_flee_target() -> void:
	var player: Node3D = world.get("player") as Node3D if world != null else null
	if player == null:
		_choose_wander_target()
		return
	var away := global_position - player.global_position
	away.y = 0.0
	if away.length_squared() < 0.01:
		away = Vector3.FORWARD
	var target_global := global_position + away.normalized() * (wander_radius + 1.4)
	target_global.y = global_position.y
	var parent_node := get_parent() as Node3D
	target_position = parent_node.to_local(target_global) if parent_node != null else target_global
	target_position.y = home_position.y

func _move_toward_target(delta: float, speed: float) -> void:
	if _path_is_blocked():
		_choose_wander_target()
		return
	var previous := position
	position = position.move_toward(target_position, speed * delta)
	var direction := position - previous
	direction.y = 0.0
	if direction.length_squared() > 0.0001:
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), minf(1.0, delta * 8.0))

func _path_is_blocked() -> bool:
	var world_3d := get_world_3d()
	if world_3d == null:
		return false
	var target_global := to_global(target_position)
	var from := global_position + Vector3.UP * 0.16
	var to := target_global + Vector3.UP * 0.16
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	query.exclude = [self]
	var hit := world_3d.direct_space_state.intersect_ray(query)
	return not hit.is_empty()

func _animate() -> void:
	if visual_root == null:
		return
	var now := Time.get_ticks_msec() * 0.001
	var bob_amount := 0.025 if species_id != "beetle" else 0.012
	visual_root.position.y = sin(now * (5.0 if state == "fleeing" else 2.4) + phase) * bob_amount
	var pulse := 1.0 + sin(now * 2.1 + phase) * 0.025
	visual_root.scale = Vector3.ONE * pulse

func _update_label() -> void:
	if label_node == null:
		return
	label_node.text = species_label + ("\nOBSERVED" if observed else "")
