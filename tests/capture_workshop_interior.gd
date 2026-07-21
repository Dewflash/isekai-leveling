extends SceneTree

## Display-backed proof for the first playable interior slice. The room is
## entered through Main's real transition path; no mock camera or duplicate
## station layout is used.

const MainScene := preload("res://main.tscn")
const CAPTURE_SIZE := Vector2i(1280, 720)
const SAVE_SLOT := "qa_workshop_interior_capture"

var viewport: SubViewport
var world: Node

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", SAVE_SLOT)
	viewport = SubViewport.new()
	viewport.name = "WorkshopInteriorCaptureViewport"
	viewport.size = CAPTURE_SIZE
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	root.add_child(viewport)
	world = MainScene.instantiate()
	viewport.add_child(world)
	await _wait_frames(45)
	var session := world.get("session") as Node
	var player := world.get("player") as CharacterBody3D
	if session == null or player == null:
		push_error("WORKSHOP_INTERIOR_CAPTURE_FAIL: Main did not expose session/player")
		quit(1)
		return
	var structure_data := {
		"id": "capture_workshop_001",
		"kind": "workshop",
		"cell": [4, -6],
		"rotation": 0,
		"state": "operational",
		"remaining_hours": 0.0,
		"total_hours": 24.0,
		"delivered_materials": {"wood": 12, "stone": 8, "plank": 4},
	}
	session.set("structures", {"capture_workshop_001": structure_data})
	world.call("_spawn_structure_visual", "capture_workshop_001", structure_data)
	await _wait_frames(8)
	var visuals: Dictionary = world.get("settlement_visuals")
	var structure := visuals.get("capture_workshop_001") as Node3D
	if structure == null:
		push_error("WORKSHOP_INTERIOR_CAPTURE_FAIL: workshop visual missing")
		quit(1)
		return
	player.global_position = structure.global_position + Vector3(0.0, 1.0, 3.3)
	world.call("_enter_building_interior", structure)
	await _wait_seconds(0.90)
	var toast := world.get("toast_label") as Label
	if toast != null:
		toast.visible = false
	await _wait_frames(8)
	if DisplayServer.get_name().to_lower() == "headless" or viewport.get_texture() == null:
		print("WORKSHOP_INTERIOR_CAPTURE_UNAVAILABLE: use --display-driver macos for a pixel-backed capture")
		quit()
		return
	var output_path := OS.get_environment("WORKSHOP_INTERIOR_CAPTURE_PATH")
	if output_path.is_empty():
		output_path = "user://workshop-interior-capture.png"
	var image := viewport.get_texture().get_image()
	var result := image.save_png(output_path)
	if result != OK:
		push_error("WORKSHOP_INTERIOR_CAPTURE_FAIL: could not write image")
		quit(1)
		return
	print("WORKSHOP_INTERIOR_CAPTURE_PASS ", output_path, " ", image.get_width(), "x", image.get_height())
	quit()

func _wait_frames(count: int) -> void:
	for _index in count:
		await process_frame

func _wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout
