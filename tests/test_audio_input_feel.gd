extends SceneTree

const AudioDirectorScript = preload("res://scripts/audio_director.gd")
const JoystickScript = preload("res://scripts/virtual_joystick.gd")

var joystick_signal_count := 0
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	failures += 1
	push_error("AUDIO_INPUT_FEEL_FAIL: %s" % message)
	return false

func _run() -> void:
	var audio := AudioDirectorScript.new()
	root.add_child(audio)
	await process_frame

	# The director must create every named child bus and route it to Master. The
	# test also exercises a second ensure pass so it cannot duplicate buses.
	audio.call("_ensure_buses")
	var expected_buses := ["Music", "Ambience", "Weather", "Stations", "Effects", "UI"]
	for bus_name in expected_buses:
		var bus_index := AudioServer.get_bus_index(bus_name)
		_expect(bus_index >= 0, "missing audio bus: %s" % bus_name)
		if bus_index >= 0:
			_expect(AudioServer.get_bus_send(bus_index) == "Master", "audio bus not routed to Master: %s" % bus_name)
	var bus_count := AudioServer.get_bus_count()
	audio.call("_ensure_buses")
	_expect(AudioServer.get_bus_count() == bus_count, "audio bus ensure duplicated buses")

	# Headless tests do not create output players, but public action calls still
	# exercise the pause/focus gate and the duplicate-action limiter.
	paused = false
	audio.set("audio_focus_lost", false)
	audio.set("last_action_times", {})
	audio.set("audio_enabled", true)
	audio.call("play_action", "hit")
	var first_sfx_time := float(audio.get("sfx_time"))
	_expect(first_sfx_time > 0.0, "first action did not start an SFX envelope")
	audio.call("play_action", "hit")
	_expect(is_equal_approx(float(audio.get("sfx_time")), first_sfx_time), "duplicate action bypassed cooldown")
	paused = true
	audio.call("_process", 0.016)
	_expect(bool(audio.get("playback_paused")), "audio did not pause with the game")
	audio.call("play_action", "quest")
	_expect(is_equal_approx(float(audio.get("sfx_time")), first_sfx_time), "paused audio accepted an action")
	paused = false
	audio.call("_process", 0.016)
	_expect(not bool(audio.get("playback_paused")), "audio did not resume with the game")
	var sfx_before_focus := float(audio.get("sfx_time"))
	audio.call("_notification", NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(bool(audio.get("audio_focus_lost")), "focus loss was not recorded")
	_expect(bool(audio.get("playback_paused")), "audio did not pause on focus loss")
	audio.call("play_action", "discovery")
	_expect(is_equal_approx(float(audio.get("sfx_time")), sfx_before_focus), "focus-lost audio accepted an action")
	audio.call("_notification", NOTIFICATION_APPLICATION_FOCUS_IN)
	_expect(not bool(audio.get("audio_focus_lost")), "focus regain was not recorded")

	var joystick: Control = JoystickScript.new()
	joystick.size = Vector2(156.0, 156.0)
	root.add_child(joystick)
	joystick.connect("vector_changed", Callable(self, "_on_joystick_vector_changed"))
	await process_frame

	var center := joystick.size * 0.5
	var input_radius := minf(joystick.size.x, joystick.size.y) * 0.42
	joystick.call("_set_from_position", center + Vector2(input_radius * 0.10, 0.0))
	_expect(joystick.get("value") == Vector2.ZERO, "dead zone did not suppress small input")
	joystick.call("_set_from_position", center + Vector2(input_radius * 0.60, 0.0))
	var remapped_value: Vector2 = joystick.get("value")
	_expect(remapped_value.x > 0.45 and remapped_value.x < 0.60, "dead-zone remap was outside expected range")
	joystick.call("_set_from_position", center + Vector2(input_radius * 1.4, 0.0))
	_expect(is_equal_approx(float((joystick.get("value") as Vector2).length()), 1.0), "joystick did not clamp to unit length")
	joystick.size = Vector2.ZERO
	joystick.call("_set_from_position", Vector2.ZERO)
	_expect(joystick.get("value") == Vector2.ZERO, "zero-sized joystick produced non-zero input")
	joystick.size = Vector2(156.0, 156.0)

	# A touch release from another pointer must not release the active pointer;
	# the matching release and focus loss must both clear it.
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 7
	touch_down.pressed = true
	touch_down.position = center + Vector2(input_radius, 0.0)
	joystick.call("_gui_input", touch_down)
	_expect(bool(joystick.get("active")), "touch down did not activate joystick")
	var wrong_touch_up := InputEventScreenTouch.new()
	wrong_touch_up.index = 8
	wrong_touch_up.pressed = false
	joystick.call("_gui_input", wrong_touch_up)
	_expect(bool(joystick.get("active")), "wrong touch release cleared active pointer")
	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 7
	touch_up.pressed = false
	joystick.call("_gui_input", touch_up)
	_expect(not bool(joystick.get("active")), "matching touch release did not clear joystick")
	var signal_count_after_touch_up := joystick_signal_count
	joystick.call("reset_input")
	_expect(joystick_signal_count == signal_count_after_touch_up, "idempotent reset emitted a duplicate signal")

	var mouse_down := InputEventMouseButton.new()
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.pressed = true
	mouse_down.position = center + Vector2(input_radius, 0.0)
	joystick.call("_gui_input", mouse_down)
	_expect(bool(joystick.get("active")), "mouse down did not activate joystick")
	var emulated_mouse_down := mouse_down.duplicate()
	emulated_mouse_down.device = InputEvent.DEVICE_ID_EMULATION
	joystick.call("_gui_input", emulated_mouse_down)
	_expect(int(joystick.get("pointer_id")) == -2, "emulated mouse changed pointer ownership")
	var mouse_up := InputEventMouseButton.new()
	mouse_up.button_index = MOUSE_BUTTON_LEFT
	mouse_up.pressed = false
	joystick.call("_gui_input", mouse_up)
	_expect(not bool(joystick.get("active")), "mouse release did not clear joystick")

	joystick.call("_set_from_position", center + Vector2(input_radius, 0.0))
	joystick.set("active", true)
	paused = true
	var paused_motion := InputEventMouseMotion.new()
	paused_motion.position = center + Vector2(-input_radius, 0.0)
	joystick.call("_gui_input", paused_motion)
	_expect(joystick.get("value") == Vector2.ZERO, "paused motion changed joystick value")
	_expect(not bool(joystick.get("active")), "paused motion left joystick active")
	paused = false
	joystick.call("_set_from_position", Vector2.ZERO)
	joystick.call("_notification", NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(joystick.get("value") == Vector2.ZERO, "focus loss left joystick input latched")

	# Station sources are published independently of platform output so the
	# gameplay/runtime contract can be tested headlessly. Real output creates an
	# AudioStreamPlayer3D on the Stations bus; headless output still retains the
	# measured source metadata for inspection.
	audio.set("audio_enabled", false)
	audio.call("set_station_sources", [{
		"id": "workshop_qa_001:furnace_left_001",
		"kind": "furnace_left",
		"position": Vector3(2.0, 1.0, -1.0),
		"intensity": 1.25,
		"max_distance": 10.5,
	}])
	var source_contract: Dictionary = audio.call("get_station_source_contract")
	_expect(source_contract.size() == 1, "station source contract did not retain the active machine")
	if source_contract.size() == 1:
		var source: Dictionary = source_contract.values()[0]
		_expect(source.get("position", Vector3.ZERO) == Vector3(2.0, 1.0, -1.0), "station source did not retain its measured world position")
		_expect(bool(source.get("spatial", false)), "station source did not declare spatial attenuation")
		_expect(str(source.get("bus", "")) == "Stations", "station source did not route to the Stations bus")
	audio.call("set_station_sources", [])
	_expect((audio.call("get_station_source_contract") as Dictionary).is_empty(), "clearing station sources left stale machine audio")
	audio.set("audio_enabled", true)
	audio.call("_ensure_buses")
	audio.call("set_station_sources", [{
		"id": "workshop_qa_001:furnace_left_001",
		"kind": "furnace_left",
		"position": Vector3(2.0, 1.0, -1.0),
		"intensity": 1.25,
		"max_distance": 10.5,
	}])
	var live_source_players: Dictionary = audio.get("station_source_players")
	_expect(live_source_players.size() == 1, "audio director did not create a spatial station player")
	audio.call("_process", 0.016)
	audio.call("set_station_sources", [])
	_expect((audio.get("station_source_players") as Dictionary).is_empty(), "audio director did not dispose the spatial station player")

	joystick.queue_free()
	audio.queue_free()
	await process_frame
	if failures > 0:
		print("AUDIO_INPUT_FEEL_TESTS_FAIL count=%d" % failures)
		quit(1)
		return
	print("AUDIO_INPUT_FEEL_TESTS_PASS")
	quit(0)

func _on_joystick_vector_changed(_value: Vector2) -> void:
	joystick_signal_count += 1
