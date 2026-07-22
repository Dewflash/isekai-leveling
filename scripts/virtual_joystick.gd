extends Control

signal vector_changed(value: Vector2)

const INPUT_DEAD_ZONE := 0.14
const INPUT_RADIUS_SCALE := 0.42
const KNOB_TRAVEL_SCALE := 0.80
const MOUSE_POINTER_ID := -2

var value := Vector2.ZERO
var active := false
var pointer_id := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if get_tree().paused:
		reset_input()
		return
	if event is InputEventScreenTouch:
		if event.pressed and not active:
			active = true
			pointer_id = event.index
			_set_from_position(event.position)
		elif not event.pressed and active and event.index == pointer_id:
			_reset()
	elif event is InputEventScreenDrag and active and event.index == pointer_id:
		_set_from_position(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event.pressed:
			if active:
				return
			active = true
			pointer_id = MOUSE_POINTER_ID
			_set_from_position(event.position)
		elif active and pointer_id == MOUSE_POINTER_ID:
			_reset()
	elif event is InputEventMouseMotion and active and pointer_id == MOUSE_POINTER_ID:
		_set_from_position(event.position)

func _set_from_position(point: Vector2) -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * INPUT_RADIUS_SCALE
	if radius <= 0.0:
		_set_value(Vector2.ZERO)
		return
	var offset := point - center
	var magnitude := minf(offset.length() / radius, 1.0)
	if magnitude <= INPUT_DEAD_ZONE:
		_set_value(Vector2.ZERO)
		return
	var remapped_magnitude := inverse_lerp(INPUT_DEAD_ZONE, 1.0, magnitude)
	_set_value(offset.normalized() * remapped_magnitude)

func _set_value(next_value: Vector2) -> void:
	if value.distance_squared_to(next_value) <= 0.000001:
		return
	value = next_value
	vector_changed.emit(value)
	queue_redraw()

func _reset() -> void:
	var should_emit := value.length_squared() > 0.000001
	var changed := active or pointer_id != -1 or should_emit
	active = false
	pointer_id = -1
	value = Vector2.ZERO
	if should_emit:
		vector_changed.emit(value)
	if changed:
		queue_redraw()

func reset_input() -> void:
	# Focus can be lost without delivering the matching touch-up event. Expose
	# an explicit reset so returning to the game can never inherit stale motion.
	_reset()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		reset_input()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.42
	draw_circle(center, radius, Color(0.035, 0.07, 0.09, 0.72))
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.72, 0.86, 0.74, 0.72), 3.0)
	var knob := center + value * radius * KNOB_TRAVEL_SCALE
	draw_circle(knob, radius * 0.36, Color(0.82, 0.93, 0.78, 0.88))
	draw_circle(knob, radius * 0.28, Color(0.24, 0.47, 0.38, 0.95))
