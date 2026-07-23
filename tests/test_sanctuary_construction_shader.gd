extends SceneTree

const MainScene := preload("res://main.tscn")

const SAVE_SLOT := "qa_sanctuary_construction_shader"
const SHADER_CONTRACT := "authored_silhouette_reveal_v1"

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("SANCTUARY_CONSTRUCTION_SHADER_FAIL: " + message)

func _run() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", SAVE_SLOT)
	var world := MainScene.instantiate()
	root.add_child(world)
	await _wait_frames(12)
	var session := world.get("session") as Node
	var visuals: Dictionary = world.get("settlement_visuals")
	_check(session != null, "construction shader test requires the authoritative session")
	_check(visuals != null, "construction shader test requires the settlement visual registry")
	if session == null or visuals == null:
		_finish(world)
		return

	for kind in ["livestock_pen", "rain_cistern"]:
		for rotation in 4:
			var blueprint_id := "%s_blueprint_%d" % [kind, rotation]
			var blueprint := _structure_data(blueprint_id, kind, rotation, "blueprint", 24.0)
			session.set("structures", {blueprint_id: blueprint})
			world.call("_spawn_structure_visual", blueprint_id, blueprint)
			await _wait_frames(2)
			var blueprint_sprite := _find_state_sprite(visuals, blueprint_id)
			_check(blueprint_sprite != null, "%s q%d blueprint must bind its authored directional silhouette" % [kind, rotation])
			if blueprint_sprite == null:
				continue
			_check(str(blueprint_sprite.get_meta("construction_shader_contract", "")) == SHADER_CONTRACT, "%s q%d blueprint must publish the construction shader contract" % [kind, rotation])
			_check(str(blueprint_sprite.get_meta("construction_shader_mode", "")) == "blueprint", "%s q%d blueprint must use blueprint shader mode" % [kind, rotation])
			_check(ResourceLoader.exists(str(blueprint_sprite.get_meta("directional_asset_path", ""))), "%s q%d blueprint must retain a real directional asset" % [kind, rotation])
			var blueprint_material := blueprint_sprite.material_override as ShaderMaterial
			_check(blueprint_material != null, "%s q%d blueprint must use a per-instance shader material" % [kind, rotation])
			if blueprint_material != null:
				_check(int(blueprint_material.get_shader_parameter("construction_mode")) == 1, "%s q%d blueprint shader mode must be 1" % [kind, rotation])
				_check(is_equal_approx(float(blueprint_material.get_shader_parameter("construction_progress")), 0.0), "%s q%d blueprint progress must be zero" % [kind, rotation])

			var building_id := "%s_building_%d" % [kind, rotation]
			var building := _structure_data(building_id, kind, rotation, "building", 10.0)
			session.set("structures", {building_id: building})
			world.call("_spawn_structure_visual", building_id, building)
			await _wait_frames(2)
			var building_sprite := _find_state_sprite(visuals, building_id)
			_check(building_sprite != null, "%s q%d building must retain its authored directional silhouette" % [kind, rotation])
			if building_sprite == null:
				continue
			_check(str(building_sprite.get_meta("construction_shader_contract", "")) == SHADER_CONTRACT, "%s q%d building must publish the construction shader contract" % [kind, rotation])
			_check(str(building_sprite.get_meta("construction_shader_mode", "")) == "material_reveal", "%s q%d building must use material-reveal shader mode" % [kind, rotation])
			_check(is_equal_approx(float(building_sprite.get_meta("construction_shader_progress", -1.0)), 0.5), "%s q%d building must publish measured progress" % [kind, rotation])
			var building_material := building_sprite.material_override as ShaderMaterial
			_check(building_material != null, "%s q%d building must use a per-instance shader material" % [kind, rotation])
			if building_material != null:
				_check(int(building_material.get_shader_parameter("construction_mode")) == 2, "%s q%d building shader mode must be 2" % [kind, rotation])
				_check(is_equal_approx(float(building_material.get_shader_parameter("construction_progress")), 0.5), "%s q%d building shader progress must be 0.5" % [kind, rotation])
			_check(str((visuals.get(building_id) as Node3D).get_meta("visual_art_missing", "")) == "false", "%s q%d building must not fall back to a missing-art state" % [kind, rotation])

	_finish(world)

func _structure_data(instance_id: String, kind: String, rotation: int, state: String, remaining_hours: float) -> Dictionary:
	return {
		"id": instance_id,
		"kind": kind,
		"cell": [rotation * 4, -6],
		"rotation": rotation,
		"state": state,
		"remaining_hours": remaining_hours,
		"total_hours": 20.0,
		"delivered_materials": {"wood": 10, "stone": 8, "fiber": 6, "plank": 2},
	}

func _find_state_sprite(visuals: Dictionary, instance_id: String) -> Sprite3D:
	var structure := visuals.get(instance_id) as Node3D
	if structure == null:
		return null
	var presentation := structure.get_node_or_null("IllustratedStructurePresentation") as Node3D
	if presentation == null:
		return null
	return presentation.get_node_or_null("IllustratedStateSprite") as Sprite3D

func _wait_frames(count: int) -> void:
	for _index in count:
		await process_frame

func _finish(world: Node) -> void:
	if is_instance_valid(world):
		world.queue_free()
	if failures.is_empty():
		print("SANCTUARY_CONSTRUCTION_SHADER_PASS checks=%d" % checks)
		quit(0)
	else:
		print("SANCTUARY_CONSTRUCTION_SHADER_FAIL count=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  " + failure)
		quit(1)
