extends SceneTree

const MainScene := preload("res://main.tscn")

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("SANCTUARY_SHADER_INTEGRATION_FAIL: " + message)

func _run() -> void:
	var shader_source := FileAccess.get_file_as_string("res://assets/generated/shaders/cozy_toon_sprite.gdshader")
	_check(shader_source.contains("* COLOR"), "toon sprite shader must preserve Sprite3D modulate in its lit output")
	_check(shader_source.contains("key_light_direction_view"), "toon sprite shader must convert its world light direction into fragment view space")
	_check(shader_source.contains("MODELVIEW_MATRIX") and shader_source.contains("INV_VIEW_MATRIX"), "toon sprite shader must preserve Sprite3D billboarding when used as a material override")
	_check(shader_source.contains("depth_prepass_alpha"), "toon sprite shader must depth-prepass alpha silhouettes for scalable 2.5D overlap")
	_check(shader_source.contains("filter_linear") and not shader_source.contains("filter_linear_mipmap"), "toon sprite shader sampler must match runtime art without mipmaps")
	var world := MainScene.instantiate()
	root.add_child(world)
	for _index in 12:
		await process_frame
	var style := world.get("sanctuary_style") as Node3D
	_check(style != null, "Sanctuary style must exist")
	if style != null:
		var moss_count := 0
		var path_count := 0
		var contact_count := 0
		for value in style.find_children("*", "MeshInstance3D", true, false):
			var mesh_instance := value as MeshInstance3D
			if mesh_instance == null:
				continue
			var shader_role := str(mesh_instance.get_meta("shader_role", ""))
			if shader_role in ["ground_moss", "ground_path"]:
				var material := mesh_instance.material_override as ShaderMaterial
				_check(material != null and material.shader != null, "%s must use a live ground shader" % mesh_instance.name)
				_check(mesh_instance.mesh is CylinderMesh, "%s shader must be on an opaque ground patch" % mesh_instance.name)
				_check(mesh_instance.get_child_count() == 0, "%s ground patch must not own collision children" % mesh_instance.name)
				if shader_role == "ground_moss":
					moss_count += 1
				else:
					path_count += 1
			elif shader_role == "transparent_contact":
				contact_count += 1
				_check(not (mesh_instance.material_override is ShaderMaterial), "%s transparent contact shadow must not use the opaque ground shader" % mesh_instance.name)
		_check(moss_count > 0, "live Sanctuary must activate moss ground shader patches")
		_check(path_count > 0, "live Sanctuary must activate packed-earth path shader patches")
		_check(contact_count > 0, "live Sanctuary must retain presentation-only contact shadows")
	var building_interior := world.get("building_interior") as Node3D
	_check(building_interior != null, "shader integration must not remove the interior runtime root")
	if building_interior != null:
		var furnace := building_interior.find_child("FurnaceBody", true, false) as MeshInstance3D
		_check(furnace != null and furnace.material_override is ShaderMaterial and (furnace.material_override as ShaderMaterial).shader != null, "Workshop solid furnace must use the toon surface shader")
		_check(furnace != null and str(furnace.get_meta("surface_profile", "")) == "toon_wood", "Workshop surface profile must remain separate from collision contribution")
		_check(furnace != null and bool(furnace.get_meta("collision_contributor", false)), "Workshop furnace body must declare collision contribution independently")
		var fire := building_interior.find_child("FurnaceFire", true, false) as MeshInstance3D
		_check(fire != null and not (fire.material_override is ShaderMaterial), "animated furnace fire must not inherit the opaque toon wood shader")
		_check(fire != null and not bool(fire.get_meta("collision_contributor", true)), "animated furnace fire must remain presentation-only")
		var shell := building_interior.find_child("IllustratedWorkshopInteriorShell", true, false) as Sprite3D
		_check(shell != null, "Workshop interior must include the authored cutaway shell")
		_check(shell != null and shell.material_override is ShaderMaterial and (shell.material_override as ShaderMaterial).shader != null, "Workshop cutaway shell must use the live toon lighting shader")
		_check(shell != null and shell.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "Workshop cutaway shell must remain camera-facing under its custom material")
		_check(shell != null and str(shell.get_meta("opaque_measurement_source", "")) == "texture_alpha_used_rect", "Workshop cutaway shell must retain alpha-envelope measurement metadata")
		var station_sheet := building_interior.find_child("GeneratedStationSprite", true, false) as Sprite3D
		_check(station_sheet != null and station_sheet.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "authored Workshop stations must remain camera-facing")
		_check(station_sheet != null and str(station_sheet.get_meta("opaque_measurement_source", "")) == "texture_alpha_used_rect", "authored Workshop stations must retain runtime alpha measurement metadata")
	var workshop_data := {
		"id": "shader_workshop_qa",
		"kind": "workshop",
		"cell": [4, -6],
		"rotation": 0,
		"state": "operational",
		"remaining_hours": 0.0,
		"total_hours": 24.0,
		"delivered_materials": {"wood": 12, "stone": 8},
	}
	world.call("_spawn_structure_visual", "shader_workshop_qa", workshop_data)
	await process_frame
	var workshop_visual := (world.get("settlement_visuals") as Dictionary).get("shader_workshop_qa") as Node3D
	var workshop_sprite := workshop_visual.get_node_or_null("IllustratedStructurePresentation/IllustratedStateSprite") as Sprite3D if workshop_visual != null else null
	_check(workshop_sprite != null and workshop_sprite.material_override is ShaderMaterial and (workshop_sprite.material_override as ShaderMaterial).shader != null, "operational Workshop cutout must participate in the live toon lighting shader")
	_check(workshop_sprite != null and str(workshop_sprite.get_meta("opaque_measurement_source", "")) == "texture_alpha_used_rect", "operational Workshop shader must preserve alpha-envelope measurement metadata")
	if is_instance_valid(world):
		world.queue_free()
	if failures.is_empty():
		print("SANCTUARY_SHADER_INTEGRATION_PASS checks=%d" % checks)
		quit(0)
	else:
		print("SANCTUARY_SHADER_INTEGRATION_FAIL count=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  " + failure)
		quit(1)
