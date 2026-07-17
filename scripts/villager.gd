extends Node3D

## Small, deterministic Sanctuary routine for a villager who belongs to the
## world rather than a static menu. The route follows the saved in-world hour.

var world: Node
var station_id := "guide"
var _route_key := ""
var _route_index := 0
var _route_progress := 0.0
var _bob_phase := 0.0

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
	if distance < 0.22:
		_route_progress += delta
		if _route_progress >= 1.5:
			_route_progress = 0.0
			_route_index = (_route_index + 1) % route.size()
	else:
		_route_progress = 0.0
		var travel := global_position.direction_to(target)
		global_position = global_position.move_toward(target, minf(distance, delta * 0.72))
		if travel.length_squared() > 0.01:
			rotation.y = lerp_angle(rotation.y, atan2(-travel.x, -travel.z), delta * 5.0)
	var visual := get_node_or_null("Visual") as Node3D
	if visual != null:
		visual.position.y = sin(Time.get_ticks_msec() * 0.004 + _bob_phase) * 0.025

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
