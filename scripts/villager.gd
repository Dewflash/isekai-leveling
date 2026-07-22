extends Node3D

## Small, deterministic Sanctuary routine for a villager who belongs to the
## world rather than a static menu. The route follows the saved in-world hour.

var world: Node
var station_id := "guide"
var _route_key := ""
var _route_index := 0
var _route_progress := 0.0
var _bob_phase := 0.0
var _walk_phase := 0.0

func _ready() -> void:
	_bob_phase = randf_range(0.0, TAU)

func _process(delta: float) -> void:
	if world == null or not is_instance_valid(world) or str(world.get("current_zone")) != "Sanctuary":
		return
	var session: Node = world.get("session") as Node
	if session == null:
		return
	var route := _route_for_hour(float(session.get("hour")))
	var target := route[_route_index % route.size()]
	var distance := global_position.distance_to(target)
	var walking := distance >= 0.22
	var travel := Vector3.ZERO
	if distance < 0.22:
		_route_progress += delta
		if _route_progress >= 1.5:
			_route_progress = 0.0
			_route_index = (_route_index + 1) % route.size()
	else:
		_route_progress = 0.0
		travel = global_position.direction_to(target)
		global_position = global_position.move_toward(target, minf(distance, delta * 0.72))
		if travel.length_squared() > 0.01:
			rotation.y = lerp_angle(rotation.y, atan2(-travel.x, -travel.z), delta * 5.0)
	var visual := get_node_or_null("Visual") as Node3D
	if visual != null:
		var now := Time.get_ticks_msec() * 0.001
		if walking:
			_walk_phase += delta * 8.4
			var stride := sin(_walk_phase)
			visual.position.y = absf(stride) * 0.038 + sin(now * 2.6 + _bob_phase) * 0.018
			visual.rotation.z = lerpf(visual.rotation.z, sin(_walk_phase * 0.5) * 0.032, delta * 8.0)
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
			_walk_phase = move_toward(_walk_phase, 0.0, delta * 3.0)
			visual.position.y = sin(now * 2.0 + _bob_phase) * 0.018
			visual.rotation.z = move_toward(visual.rotation.z, 0.0, delta * 0.8)
			for limb_name in ["LegLeft", "LegRight", "ArmLeft", "ArmRight"]:
				var limb := visual.get_node_or_null(limb_name) as Node3D
				if limb != null:
					limb.rotation.x = move_toward(limb.rotation.x, 0.0, delta * 4.0)
	_update_illustrated_mira(walking, travel)

func _update_illustrated_mira(walking: bool, travel: Vector3) -> void:
	var visual := get_node_or_null("Visual") as Node3D
	if visual == null:
		return
	var sprite := visual.get_node_or_null("IllustratedMira") as Sprite3D
	if sprite == null:
		return
	var atlas := sprite.texture as AtlasTexture
	if atlas == null:
		return
	var cell_size_value: Variant = sprite.get_meta("cell_size", [384.0, 512.0])
	if not (cell_size_value is Array) or (cell_size_value as Array).size() < 2:
		return
	var cell_size := cell_size_value as Array
	var cell_width := float(cell_size[0])
	var cell_height := float(cell_size[1])
	var facing := travel if travel.length_squared() > 0.01 else Vector3(sin(rotation.y), 0.0, cos(rotation.y))
	var frame := 0
	if absf(facing.z) >= absf(facing.x):
		frame = 2 if facing.z < 0.0 else 0
	else:
		frame = 3 if facing.x < 0.0 else 1
	atlas.region = Rect2(float(frame) * cell_width, (1.0 if walking else 0.0) * cell_height, cell_width, cell_height)
	sprite.set_meta("animation_state", "walk" if walking else "idle")
	sprite.set_meta("direction_frame", frame)

func _route_for_hour(hour: float) -> Array[Vector3]:
	var route_key := "morning"
	var route: Array[Vector3] = [Vector3(0.0, 0.0, -4.0), Vector3(-8.2, 0.0, 1.5), Vector3(2.7, 0.0, -2.3)]
	if hour >= 9.0 and hour < 15.0:
		route_key = "day"
		route = [Vector3(-5.5, 0.0, 4.0), Vector3(7.0, 0.0, 5.0), Vector3(6.2, 0.0, -5.6)]
	elif hour >= 15.0 and hour < 20.0:
		route_key = "evening"
		route = [Vector3(-5.4, 0.0, -5.2), Vector3(-8.2, 0.0, 1.5), Vector3(0.0, 0.0, -4.0)]
	elif hour >= 20.0:
		route_key = "night"
		route = [Vector3(0.0, 0.0, -4.0)]
	if route_key != _route_key:
		_route_key = route_key
		_route_index = 0
		_route_progress = 0.0
	return route
