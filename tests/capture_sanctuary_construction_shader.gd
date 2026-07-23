extends SceneTree

## Pixel-backed proof for facilities that use the authored-silhouette construction
## shader. This capture deliberately uses Main's real Sanctuary scene and the
## persisted structure presentation path; it is not a mock preview scene.

const MainScene := preload("res://main.tscn")
const CAPTURE_SIZE := Vector2i(1280, 720)
const SAVE_SLOT := "qa_sanctuary_construction_shader_capture"

var viewport: SubViewport
var world: Node
var output_dir := ""

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", SAVE_SLOT)
	output_dir = OS.get_environment("SANCTUARY_CONSTRUCTION_CAPTURE_DIR")
	if output_dir.is_empty():
		output_dir = "user://sanctuary-construction-shader-captures"
	DirAccess.make_dir_recursive_absolute(output_dir)
	viewport = SubViewport.new()
	viewport.name = "SanctuaryConstructionShaderCaptureViewport"
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
		push_error("SANCTUARY_CONSTRUCTION_CAPTURE_FAIL: Main did not expose session/player")
		quit(1)
		return
	session.set("save_blocked", true)
	session.set("day", 1)
	session.set("hour", 10.0)
	session.set("weather", "clear")
	player.global_position = Vector3(0.0, 1.0, 4.0)
	player.set("last_direction", Vector3(0.0, 0.0, -1.0))
	if player.has_method("cancel_navigation"):
		player.call("cancel_navigation", true)
	var toast := world.get("toast_label") as Label
	if toast != null:
		toast.visible = false
	for kind in ["livestock_pen", "rain_cistern"]:
		for stage in [["blueprint", 24.0], ["building", 10.0]]:
			_clear_structure_visuals()
			var instance_id := "%s_%s_capture" % [kind, str(stage[0])]
			var data := {
				"id": instance_id,
				"kind": kind,
				"cell": [-2, -2],
				"rotation": 0,
				"state": str(stage[0]),
				"remaining_hours": float(stage[1]),
				"total_hours": 20.0,
				"delivered_materials": {"wood": 10, "stone": 8, "fiber": 6, "plank": 2},
			}
			session.set("structures", {instance_id: data})
			world.call("_spawn_structure_visual", instance_id, data)
			await _wait_frames(12)
			if not await _save_capture("%s_%s.png" % [kind, str(stage[0])]):
				quit(1)
				return
	print("SANCTUARY_CONSTRUCTION_CAPTURE_PASS ", output_dir)
	quit(0)

func _clear_structure_visuals() -> void:
	var visuals: Dictionary = world.get("settlement_visuals") if world != null else {}
	for value in visuals.values():
		var structure := value as Node3D
		if structure != null and is_instance_valid(structure):
			structure.queue_free()
	visuals.clear()
	await process_frame

func _save_capture(file_name: String) -> bool:
	if DisplayServer.get_name().to_lower() == "headless" or viewport.get_texture() == null:
		print("SANCTUARY_CONSTRUCTION_CAPTURE_UNAVAILABLE: use --display-driver macos")
		return false
	var image := viewport.get_texture().get_image()
	if image == null:
		push_error("SANCTUARY_CONSTRUCTION_CAPTURE_FAIL: viewport returned no image")
		return false
	var path := output_dir.path_join(file_name)
	var result := image.save_png(path)
	if result != OK:
		push_error("SANCTUARY_CONSTRUCTION_CAPTURE_FAIL: could not save %s" % path)
		return false
	print("SANCTUARY_CONSTRUCTION_CAPTURE_PASS ", path, " ", image.get_width(), "x", image.get_height())
	return true

func _wait_frames(count: int) -> void:
	for _index in count:
		await process_frame
