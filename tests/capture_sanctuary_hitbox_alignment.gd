extends SceneTree

## Display-backed hitbox evidence for the Sanctuary's measured player structures.
## Cyan is the imported-source fitted envelope; red is the live operational
## collision shell. This deliberately renders the same scene and structure
## presentation path used by play, rather than drawing a second mock map.

const MainScene := preload("res://main.tscn")
const CAPTURE_SIZE := Vector2i(1280, 720)
const STRUCTURES := [
	{"id": "qa_workshop_q0", "kind": "workshop", "cell": [-7, 5], "rotation": 0},
	{"id": "qa_storage_q1", "kind": "storage_shed", "cell": [5, 5], "rotation": 1},
	{"id": "qa_archive_q2", "kind": "archive", "cell": [-7, -7], "rotation": 2},
	{"id": "qa_cistern_q3", "kind": "rain_cistern", "cell": [6, -7], "rotation": 3},
]

var viewport: SubViewport
var world: Node
var output_path := ""
var checks := 0
var failures := 0

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	output_path = OS.get_environment("SANCTUARY_HITBOX_CAPTURE_PATH")
	if output_path.is_empty():
		output_path = "user://sanctuary-hitbox-alignment.png"
	viewport = SubViewport.new()
	viewport.name = "SanctuaryHitboxAlignmentViewport"
	viewport.size = CAPTURE_SIZE
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	root.add_child(viewport)
	world = MainScene.instantiate()
	viewport.add_child(world)
	await _wait_frames(45)
	var toast := world.get("toast_label") as Label
	if toast != null:
		toast.visible = false
	var hud := world.get_node_or_null("HUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	for value in STRUCTURES:
		var structure_data: Dictionary = value
		var data := {
			"id": str(structure_data["id"]),
			"kind": str(structure_data["kind"]),
			"cell": structure_data["cell"],
			"rotation": int(structure_data["rotation"]),
			"state": "operational",
			"remaining_hours": 0.0,
			"total_hours": 24.0,
			"delivered_materials": {"wood": 40, "stone": 40, "fiber": 20, "plank": 20},
		}
		world.call("_spawn_structure_visual", str(structure_data["id"]), data)
	await _wait_frames(12)
	var visuals: Dictionary = world.get("settlement_visuals")
	for value in STRUCTURES:
		var structure_data: Dictionary = value
		var structure := visuals.get(str(structure_data["id"])) as Node3D
		_check(structure != null, "live structure exists: %s" % str(structure_data["id"]))
		if structure != null:
			_draw_alignment(structure)
	await _wait_frames(2)
	if DisplayServer.get_name().to_lower() == "headless" or viewport.get_texture() == null:
		print("SANCTUARY_HITBOX_ALIGNMENT_UNAVAILABLE: use --display-driver macos")
		quit(1)
		return
	var image := viewport.get_texture().get_image()
	if image == null or image.save_png(output_path) != OK:
		print("SANCTUARY_HITBOX_ALIGNMENT_FAIL: could not save capture")
		quit(1)
		return
	if failures == 0:
		print("SANCTUARY_HITBOX_ALIGNMENT_PASS structures=%d checks=%d file=%s" % [STRUCTURES.size(), checks, output_path])
		quit(0)
	else:
		print("SANCTUARY_HITBOX_ALIGNMENT_FAIL failures=%d checks=%d" % [failures, checks])
		quit(1)

func _draw_alignment(structure: Node3D) -> void:
	var measured: Dictionary = structure.get_meta("source_measurement", {})
	var fitted_bounds: AABB = measured.get("fitted_bounds", AABB())
	_check(bool(measured.get("valid", false)), "%s has valid source measurement" % structure.name)
	_check(fitted_bounds.size.x > 0.01 and fitted_bounds.size.y > 0.01 and fitted_bounds.size.z > 0.01, "%s has non-empty fitted bounds" % structure.name)
	if fitted_bounds.size.length_squared() > 0.01:
		_add_wire_box(structure, "MeasuredSourceEnvelope", fitted_bounds.position + fitted_bounds.size * 0.5, fitted_bounds.size, Color(0.25, 1.0, 0.92, 0.95))
	var body := structure.get_node_or_null("StructureCollisionBody") as StaticBody3D
	_check(body != null, "%s has a collision body" % structure.name)
	if body == null:
		return
	var component_count := 0
	for value in body.find_children("Compound_*", "CollisionShape3D", false, false):
		var collision := value as CollisionShape3D
		var box := collision.shape as BoxShape3D if collision != null else null
		if box == null:
			continue
		component_count += 1
		var component_center := collision.position
		var component_size := box.size
		var component_bounds := AABB(component_center - component_size * 0.5, component_size)
		_check(_contains_with_tolerance(fitted_bounds, component_bounds, 0.025), "%s collision component stays inside measured envelope: %s" % [structure.name, collision.name])
		_add_wire_box(structure, "Collision_%s" % collision.name, component_center, component_size, Color(1.0, 0.25, 0.28, 0.96))
	_check(component_count >= 4, "%s exposes the measured shell components" % structure.name)

func _contains_with_tolerance(container: AABB, candidate: AABB, tolerance: float) -> bool:
	var container_min := container.position - Vector3.ONE * tolerance
	var container_max := container.end + Vector3.ONE * tolerance
	return candidate.position.x >= container_min.x and candidate.position.y >= container_min.y and candidate.position.z >= container_min.z \
		and candidate.end.x <= container_max.x and candidate.end.y <= container_max.y and candidate.end.z <= container_max.z

func _add_wire_box(parent: Node3D, node_name: String, center: Vector3, size: Vector3, color: Color) -> void:
	var mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.no_depth_test = true
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	var x := size.x * 0.5
	var y := size.y * 0.5
	var z := size.z * 0.5
	var corners := [
		center + Vector3(-x, -y, -z), center + Vector3(x, -y, -z),
		center + Vector3(x, -y, z), center + Vector3(-x, -y, z),
		center + Vector3(-x, y, -z), center + Vector3(x, y, -z),
		center + Vector3(x, y, z), center + Vector3(-x, y, z),
	]
	for edge in [[0, 1], [1, 2], [2, 3], [3, 0], [4, 5], [5, 6], [6, 7], [7, 4], [0, 4], [1, 5], [2, 6], [3, 7]]:
		mesh.surface_add_vertex(corners[edge[0]])
		mesh.surface_add_vertex(corners[edge[1]])
	mesh.surface_end()
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.set_meta("presentation_only", true)
	instance.set_meta("collision_authority", "none")
	parent.add_child(instance)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("SANCTUARY_HITBOX_ALIGNMENT_FAIL: " + message)

func _wait_frames(count: int) -> void:
	for _index in count:
		await process_frame
