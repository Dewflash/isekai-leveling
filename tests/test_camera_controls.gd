extends SceneTree

const MainScene = preload("res://main.tscn")
const JoystickScript = preload("res://scripts/virtual_joystick.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", "qa_camera_controls")
	var world := MainScene.instantiate()
	root.add_child(world)
	# Let Main finish its ready work and establish the fixed camera frame before
	# deriving the expected screen axes from the live camera basis.
	await process_frame
	await process_frame
	await process_frame
	var camera := world.get("camera") as Camera3D
	assert(camera != null)
	var player := world.get("player") as CharacterBody3D
	assert(player != null)
	var forward := -camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := camera.global_basis.x
	right.y = 0.0
	right = right.normalized()
	# The live camera must match the authored elevated diagonal promised by the
	# Sanctuary scale guide; deriving both vectors only from the camera would let
	# a consistently-wrong angle pass.
	assert(forward.dot(Vector3(-0.7071068, 0.0, -0.7071068)) > 0.99)
	assert(right.dot(Vector3(0.7071068, 0.0, -0.7071068)) > 0.99)
	var camera_pitch_degrees := rad_to_deg(asin(clampf(-camera.global_basis.z.y, -1.0, 1.0)))
	assert(absf(absf(camera_pitch_degrees) - 43.301) < 0.8)
	assert(is_equal_approx(camera.size, 14.5))
	var camera_contract: Dictionary = camera.get_meta("camera_contract", {})
	assert(str(camera_contract.get("yaw", "")) == "diagonal_southeast")
	assert(absf(float(camera_contract.get("pitch_degrees", 0.0)) - 43.301) < 0.01)
	var ground_point: Variant = world.call("_screen_to_ground", Vector2(640.0, 360.0))
	assert(ground_point is Vector3)
	assert(is_equal_approx((ground_point as Vector3).y, 0.0))

	# W / stick-up is negative screen-space Y and must travel along camera
	# forward; S / stick-down must travel back toward the camera.
	var move_up: Vector3 = world.call("camera_relative_direction", Vector2(0.0, -1.0))
	var move_down: Vector3 = world.call("camera_relative_direction", Vector2(0.0, 1.0))
	var move_right: Vector3 = world.call("camera_relative_direction", Vector2(1.0, 0.0))
	var move_left: Vector3 = world.call("camera_relative_direction", Vector2(-1.0, 0.0))
	assert(move_up.dot(forward) > 0.99)
	assert(move_down.dot(forward) < -0.99)
	assert(move_right.dot(right) > 0.99)
	assert(move_left.dot(right) < -0.99)
	assert(is_equal_approx(move_up.length(), 1.0))
	var quarter_move_up: Vector3 = world.call("camera_relative_direction", Vector2(0.0, -0.25))
	assert(absf(quarter_move_up.length() - 0.25) < 0.001)
	var diagonal_input := Vector2(0.7, -0.7)
	var diagonal_move: Vector3 = world.call("camera_relative_direction", diagonal_input)
	assert(absf(diagonal_move.length() - diagonal_input.length()) < 0.001)
	var initial_move_up := move_up
	player.global_position += Vector3(6.0, 0.0, 3.0)
	await process_frame
	await process_frame
	var moved_camera := world.get("camera") as Camera3D
	var moved_camera_forward := -moved_camera.global_basis.z
	moved_camera_forward.y = 0.0
	moved_camera_forward = moved_camera_forward.normalized()
	var moved_camera_right := moved_camera.global_basis.x
	moved_camera_right.y = 0.0
	moved_camera_right = moved_camera_right.normalized()
	var moved_input_up: Vector3 = world.call("camera_relative_direction", Vector2(0.0, -1.0))
	var moved_input_right: Vector3 = world.call("camera_relative_direction", Vector2(1.0, 0.0))
	assert(moved_camera_forward.dot(forward) > 0.99)
	assert(moved_camera_right.dot(right) > 0.99)
	assert(moved_input_up.dot(initial_move_up) > 0.99)
	assert(moved_input_right.dot(move_right) > 0.99)

	# Exercise the real Control input path in a translated viewport. Screen
	# touch coordinates must become local joystick coordinates before they are
	# turned into a vector; a regression here makes every touch direction feel
	# offset even when the 3D camera basis is correct.
	var touch_viewport := SubViewport.new()
	touch_viewport.size = Vector2i(420, 300)
	touch_viewport.gui_disable_input = false
	touch_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(touch_viewport)
	var touch_joystick := Control.new()
	touch_joystick.set_script(JoystickScript)
	touch_joystick.position = Vector2(110.0, 70.0)
	touch_joystick.size = Vector2(156.0, 156.0)
	touch_joystick.visible = true
	touch_viewport.add_child(touch_joystick)
	await process_frame
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 4
	touch_down.pressed = true
	touch_down.position = touch_joystick.position + touch_joystick.size * 0.5 + Vector2(0.0, -touch_joystick.size.y * 0.40)
	touch_viewport.push_input(touch_down)
	await process_frame
	var touch_vector: Vector2 = touch_joystick.get("value")
	assert(touch_vector.y < -0.70)
	assert(absf(touch_vector.x) < 0.12)
	var touch_drag := InputEventScreenDrag.new()
	touch_drag.index = 4
	touch_drag.position = touch_joystick.position + touch_joystick.size * 0.5 + Vector2(touch_joystick.size.x * 0.40, 0.0)
	touch_viewport.push_input(touch_drag)
	await process_frame
	var dragged_vector: Vector2 = touch_joystick.get("value")
	assert(dragged_vector.x > 0.70)
	assert(absf(dragged_vector.y) < 0.12)
	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 4
	touch_up.pressed = false
	touch_up.position = touch_drag.position
	touch_viewport.push_input(touch_up)
	await process_frame
	assert(touch_joystick.get("value") == Vector2.ZERO)
	touch_viewport.queue_free()

	# Exercise the same override path used by the on-screen stick, rather than
	# only calling the shared mapper directly.
	player.call("set_joystick_vector", Vector2(0.0, -1.0))
	await physics_frame
	await physics_frame
	var joystick_up_direction: Vector3 = player.get("last_direction")
	assert(joystick_up_direction.dot(forward) > 0.99)
	var direction_sprite := player.get_node_or_null("Visual/IllustratedCharacter") as Sprite3D
	assert(direction_sprite != null)
	assert(int(direction_sprite.get_meta("direction_frame", -1)) == 2)
	player.call("set_joystick_vector", Vector2(1.0, 0.0))
	await physics_frame
	assert(int(direction_sprite.get_meta("direction_frame", -1)) == 1)
	player.call("set_joystick_vector", Vector2(-1.0, 0.0))
	await physics_frame
	assert(int(direction_sprite.get_meta("direction_frame", -1)) == 3)
	player.call("set_joystick_vector", Vector2(0.0, 1.0))
	await physics_frame
	assert(int(direction_sprite.get_meta("direction_frame", -1)) == 0)
	player.call("set_joystick_vector", Vector2.ZERO)
	player.velocity = Vector3.ZERO
	player.call("set_joystick_vector", Vector2(0.0, -0.25))
	for _frame in 12:
		await physics_frame
	var quarter_speed := Vector2(player.velocity.x, player.velocity.z).length()
	assert(quarter_speed > 1.05)
	assert(quarter_speed < 1.55)
	player.call("set_joystick_vector", Vector2.ZERO)
	# Keep the acceleration probe in the open meadow. The framing assets now
	# expose their real foot colliders, so using the old corner probe would test
	# rock/tree contact resolution instead of analog speed invariance.
	player.global_position = Vector3(4.0, 1.0, 10.0)
	player.velocity = Vector3.ZERO
	player.call("set_joystick_vector", Vector2(1.0, 0.0))
	await physics_frame
	var cardinal_acceleration_speed := Vector2(player.velocity.x, player.velocity.z).length()
	player.call("set_joystick_vector", Vector2.ZERO)
	player.global_position = Vector3(4.0, 1.0, 10.0)
	player.velocity = Vector3.ZERO
	player.call("set_joystick_vector", Vector2(0.7071068, -0.7071068))
	await physics_frame
	var diagonal_acceleration_speed := Vector2(player.velocity.x, player.velocity.z).length()
	assert(absf(cardinal_acceleration_speed - diagonal_acceleration_speed) < 0.08)
	player.call("set_joystick_vector", Vector2.ZERO)

	# Desktop click-to-move uses a world-space target but still shares the same
	# physics controller. Manual input must cancel the target rather than fight
	# it, and reaching the target must stop without residual velocity.
	var click_target := player.global_position + forward * 3.0
	player.call("set_click_move_target", click_target)
	await physics_frame
	await physics_frame
	var click_direction: Vector3 = player.get("last_direction")
	assert(click_direction.dot(forward) > 0.99)
	assert(bool(player.get("click_move_active")))
	player.call("set_joystick_vector", Vector2(1.0, 0.0))
	assert(not bool(player.get("click_move_active")))
	player.call("set_joystick_vector", Vector2.ZERO)
	player.call("set_click_move_target", player.global_position + forward * 2.0)
	assert(bool(player.get("click_move_active")))
	world.call("_interact")
	assert(not bool(player.get("click_move_active")))

	# Route a real mouse-button event through Main's input entry point. The HUD
	# root ignores empty space, so this should create a world-space destination.
	var mouse_event := InputEventMouseButton.new()
	mouse_event.button_index = MOUSE_BUTTON_LEFT
	mouse_event.pressed = true
	mouse_event.position = Vector2(700.0, 390.0)
	world.call("_unhandled_input", mouse_event)
	assert(bool(player.get("click_move_active")))
	var emulated_mouse := InputEventMouseButton.new()
	emulated_mouse.device = InputEvent.DEVICE_ID_EMULATION
	emulated_mouse.button_index = MOUSE_BUTTON_LEFT
	emulated_mouse.pressed = true
	emulated_mouse.position = Vector2(720.0, 390.0)
	var click_target_before_emulated: Vector3 = player.get("click_move_target")
	world.call("_unhandled_input", emulated_mouse)
	assert(bool(player.get("click_move_active")))
	assert((player.get("click_move_target") as Vector3).distance_to(click_target_before_emulated) < 0.001)

	# Arrival must clear both navigation state and residual velocity.
	player.call("set_click_move_target", player.global_position + forward * 0.1)
	player.velocity = forward * 5.2
	await physics_frame
	assert(not bool(player.get("click_move_active")))
	assert(player.velocity.length() < 0.01)

	# A target behind the Hearth's shell must fail closed instead of pushing
	# forever. The lodge has a doorway, so test the blocked side of the shell.
	player.global_position = Vector3(0.0, 1.0, 4.0)
	player.call("set_click_move_target", Vector3(0.0, 1.0, -8.0))
	for _frame in 220:
		await physics_frame
	assert(not bool(player.get("click_move_active")))
	assert(player.global_position.z > -7.5)

	# Zone transitions are teleports and must not carry desktop-navigation
	# momentum into the new map.
	player.velocity = Vector3(4.0, 0.0, 0.0)
	world.call("_set_zone", "Whisperwood")
	assert(player.velocity.length() < 0.01)

	# A focus loss must clear both autonomous navigation and a held touch stick;
	# the corresponding touch-up event is not guaranteed by the OS.
	player.call("set_joystick_vector", Vector2(1.0, 0.0))
	player.velocity = Vector3(4.0, 0.0, 0.0)
	world.call("_notification", NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(player.get("joystick_vector") == Vector2.ZERO)
	assert(player.velocity.length() < 0.01)
	assert(paused)
	world.call("_notification", NOTIFICATION_APPLICATION_FOCUS_IN)
	assert(not paused)

	# Entering a modal pause must clear a held stick and its residual velocity;
	# releasing the physical control while paused must not revive movement.
	player.call("set_joystick_vector", Vector2(1.0, 0.0))
	player.velocity = Vector3(4.0, 0.0, 0.0)
	world.call("_toggle_pause")
	assert(paused)
	assert(player.get("joystick_vector") == Vector2.ZERO)
	assert(player.velocity.length() < 0.01)
	player.call("set_joystick_vector", Vector2.ZERO)
	world.call("_toggle_pause")
	assert(not paused)
	player.call("set_joystick_vector", Vector2(-1.0, 0.0))
	world.call("_toggle_settings")
	assert(paused)
	assert(player.get("joystick_vector") == Vector2.ZERO)
	world.call("_toggle_settings")
	assert(not paused)

	world.queue_free()
	await process_frame
	print("CAMERA_CONTROL_TESTS_PASS")
	quit()
