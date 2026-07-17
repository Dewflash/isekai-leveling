extends Control

signal vector_changed(value: Vector2)

var value := Vector2.ZERO
var active := false
var pointer_id := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not active:
			active = true
			pointer_id = event.index
			_set_from_position(event.position)
		elif not event.pressed and active and event.index == pointer_id:
			_reset()
	elif event is InputEventScreenDrag and active and event.index == pointer_id:
		_set_from_position(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			active = true
			pointer_id = -2
			_set_from_position(event.position)
		elif active and pointer_id == -2:
			_reset()
	elif event is InputEventMouseMotion and active and pointer_id == -2:
		_set_from_position(event.position)

func _set_from_position(point: Vector2) -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34
	value = (point - center) / radius
	if value.length() > 1.0:
		value = value.normalized()
	vector_changed.emit(value)
	queue_redraw()

func _reset() -> void:
	active = false
	pointer_id = -1
	value = Vector2.ZERO
	vector_changed.emit(value)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.42
	draw_circle(center, radius, Color(0.035, 0.07, 0.09, 0.72))
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.72, 0.86, 0.74, 0.72), 3.0)
	var knob := center + value * radius * 0.62
	draw_circle(knob, radius * 0.36, Color(0.82, 0.93, 0.78, 0.88))
	draw_circle(knob, radius * 0.28, Color(0.24, 0.47, 0.38, 0.95))

