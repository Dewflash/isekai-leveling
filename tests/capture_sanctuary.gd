extends SceneTree

const MainScene := preload("res://main.tscn")

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	# Headless Godot has no root display texture. Render the same game scene into
	# an owned off-screen viewport so visual QA remains reproducible on CI and in
	# Codex rather than silently depending on a desktop window.
	var capture_viewport := SubViewport.new()
	capture_viewport.name = "SanctuaryCaptureViewport"
	capture_viewport.size = Vector2i(1280, 720)
	capture_viewport.own_world_3d = true
	capture_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	capture_viewport.handle_input_locally = false
	root.add_child(capture_viewport)
	var world := MainScene.instantiate()
	capture_viewport.add_child(world)
	# Imported FBX/glTF presentation, the first camera settle, and the HUD all
	# need at least a few rendered frames before the image is useful.
	for _frame in 45:
		await process_frame
	# The startup welcome is useful during play but would obscure the visual
	# checkpoint. Capture the settled Sanctuary without transient boot copy.
	world.set("toast_timer", 0.0)
	var toast := world.get("toast_label") as Label
	if toast != null:
		toast.visible = false
	await process_frame
	if DisplayServer.get_name().to_lower() == "headless":
		print("SANCTUARY_CAPTURE_UNAVAILABLE: headless display driver has no pixel-backed renderer")
		quit()
		return
	var texture := capture_viewport.get_texture()
	if texture == null:
		print("SANCTUARY_CAPTURE_UNAVAILABLE: Godot is using a dummy renderer with no texture storage")
		quit()
		return
	var image := texture.get_image()
	if image == null:
		print("SANCTUARY_CAPTURE_UNAVAILABLE: dummy renderer returned an empty image")
		quit()
		return
	var output_path := OS.get_environment("SANCTUARY_CAPTURE_PATH")
	if output_path.is_empty():
		output_path = "user://sanctuary-capture.png"
	var result := image.save_png(output_path)
	assert(result == OK, "Could not write Sanctuary capture: %s" % output_path)
	print("SANCTUARY_CAPTURE_PASS ", output_path, " ", image.get_width(), "x", image.get_height())
	quit()
