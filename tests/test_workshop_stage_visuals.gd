extends SceneTree

const MainScene := preload("res://main.tscn")
const AssetCatalog := preload("res://scripts/sanctuary_asset_catalog.gd")

const SAVE_SLOT := "qa_workshop_stage_visuals"

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("WORKSHOP_STAGE_VISUAL_FAIL: " + message)

func _run() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", SAVE_SLOT)
	var world := MainScene.instantiate()
	root.add_child(world)
	await _wait_frames(12)
	var style := world.get("sanctuary_style") as Node3D
	_check(style != null, "Sanctuary style must expose projected cutout measurement")
	var stage_paths: Dictionary = AssetCatalog.structure_definition("workshop").get("construction_stage_paths", {})
	var layered_construction: Dictionary = AssetCatalog.structure_definition("workshop").get("layered_construction", {})
	var layered_asset_paths: Dictionary = layered_construction.get("directional_asset_paths", {})
	_check(layered_asset_paths.size() == 4, "Workshop layered construction must declare all four directional kits")
	_check_no_live_green_fringe("res://assets/generated/sanctuary/workshop/workshop-stage-roof-q2.png", Rect2i(520, 0, 210, 220), "roof q2 chimney smoke")
	_check_no_live_green_fringe("res://assets/generated/sanctuary/workshop/workshop-stage-walls-q3.png", Rect2i(1075, 220, 155, 130), "walls q3 upper rafters")
	for stage_id in ["blueprint", "frame", "walls", "roof"]:
		var path := str(stage_paths.get(stage_id, ""))
		_check(not path.is_empty() and ResourceLoader.exists(path), "Workshop %s stage asset must be importable" % stage_id)
		for rotation in [0, 1, 2, 3]:
			var directional_path := AssetCatalog.structure_construction_stage_asset("workshop", stage_id, rotation)
			_check(not directional_path.is_empty() and ResourceLoader.exists(directional_path), "Workshop %s rotation %d stage asset must be importable" % [stage_id, rotation])
	var stage_cases := [
		["blueprint", "blueprint", 24.0, 0.46],
		["frame", "building", 20.0, 1.0],
		["walls", "building", 12.0, 1.0],
		["roof", "building", 5.0, 1.0],
	]
	for rotation in [0, 1, 2, 3]:
		for case_value in stage_cases:
			var expected_stage := str(case_value[0])
			var data := {
				"id": "workshop_stage_qa",
				"kind": "workshop",
				"cell": [4, -6],
				"rotation": rotation,
				"state": str(case_value[1]),
				"remaining_hours": float(case_value[2]),
				"total_hours": 24.0,
				"delivered_materials": {"wood": 12, "stone": 8},
			}
			world.call("_spawn_structure_visual", "workshop_stage_qa", data)
			await process_frame
			var visual := (world.get("settlement_visuals") as Dictionary).get("workshop_stage_qa") as Node3D
			var sprite := visual.get_node_or_null("IllustratedStructurePresentation/IllustratedStateSprite") as Sprite3D if visual != null else null
			_check(sprite != null, "%s Workshop rotation %d stage must render a state sprite" % [expected_stage, rotation])
			if sprite == null:
				continue
			_check(str(sprite.get_meta("construction_stage", "")) == expected_stage, "%s Workshop rotation %d stage must bind its generated stage identity" % [expected_stage, rotation])
			var expected_path := AssetCatalog.structure_construction_stage_asset("workshop", expected_stage, rotation)
			var layered_path := str(layered_asset_paths.get(rotation, ""))
			_check(not layered_path.is_empty() and ResourceLoader.exists(layered_path), "%s Workshop rotation %d layered kit must be importable" % [expected_stage, rotation])
			_check(str(sprite.get_meta("layered_asset_path", "")) == layered_path, "%s Workshop rotation %d must bind its measured layered kit" % [expected_stage, rotation])
			_check(str(sprite.get_meta("directional_asset_path", "")) == layered_path, "%s Workshop rotation %d must expose its directional layered asset path" % [expected_stage, rotation])
			var active_layers: Array = visual.get_meta("construction_art_layers", []) if visual != null else []
			_check(active_layers.size() >= 1, "%s Workshop rotation %d must expose at least one active measured construction layer" % [expected_stage, rotation])
			_check(str(visual.get_meta("construction_art_source", "")) == "generated_workshop_layered_kit", "%s Workshop rotation %d must use the layered renderer" % [expected_stage, rotation])
			_check(visual.get_node_or_null("IllustratedStructurePresentation/WorkshopConstructionLayer_frame") != null or expected_stage == "blueprint", "%s Workshop rotation %d must expose the authored frame layer once building begins" % [expected_stage, rotation])
			var stage_texture := load(expected_path) as Texture2D
			var stage_image := stage_texture.get_image() if stage_texture != null else null
			var stage_bounds := stage_image.get_used_rect() if stage_image != null else Rect2i()
			var measured: Dictionary = visual.get_meta("source_measurement", {}) if visual != null else {}
			var fitted_size: Vector3 = measured.get("fitted_size", Vector3.ZERO)
			if stage_bounds.size.x > 0 and fitted_size.length_squared() > 0.01:
				var projected_extent: float = style.call("_measured_projected_horizontal_extent", visual, fitted_size) if style != null else 0.0
				var rendered_width := 0.0
				var presentation := visual.get_node_or_null("IllustratedStructurePresentation") as Node3D if visual != null else null
				if presentation != null:
					for child in presentation.get_children():
						var layer_sprite := child as Sprite3D
						if layer_sprite == null:
							continue
						var visual_size: Array = layer_sprite.get_meta("visual_size", [])
						if visual_size.size() >= 1:
							rendered_width = maxf(rendered_width, float(visual_size[0]))
				if rendered_width <= 0.0:
					rendered_width = float(stage_bounds.size.x) * sprite.pixel_size
				_check(rendered_width >= projected_extent * 0.96, "%s Workshop rotation %d stage alpha width must cover its measured projected shell (rendered=%.2f projected=%.2f)" % [expected_stage, rotation, rendered_width, projected_extent])
			_check(sprite.modulate.a >= float(case_value[3]) - 0.01, "%s Workshop rotation %d stage must preserve intended readability alpha" % [expected_stage, rotation])
			_check((sprite.get_meta("visual_footprint", []) as Array).size() == 2, "%s Workshop rotation %d stage must retain the measured structure footprint binding" % [expected_stage, rotation])
	var operational := {
		"id": "workshop_stage_qa",
		"kind": "workshop",
		"cell": [4, -6],
		"rotation": 0,
		"state": "operational",
		"remaining_hours": 0.0,
		"total_hours": 24.0,
		"delivered_materials": {"wood": 12, "stone": 8},
	}
	world.call("_spawn_structure_visual", "workshop_stage_qa", operational)
	await process_frame
	var operational_visual := (world.get("settlement_visuals") as Dictionary).get("workshop_stage_qa") as Node3D
	var operational_sprite := operational_visual.get_node_or_null("IllustratedStructurePresentation/IllustratedStateSprite") as Sprite3D if operational_visual != null else null
	_check(operational_sprite != null, "operational Workshop must retain a state sprite")
	if operational_sprite != null:
		_check(str(operational_sprite.get_meta("directional_asset_path", "")) == "res://assets/generated/sanctuary/workshop/workshop-q0.png", "operational Workshop must bind the canonical directional hero asset")
		_check(str(operational_visual.get_meta("operational_art_source", "")) == "generated_player_structure_directional", "operational Workshop must identify the directional hero renderer")
	for rotation in [1, 2, 3]:
		var rotated_id := "workshop_stage_qa_rotated_%d" % rotation
		var rotated_data := operational.duplicate(true)
		rotated_data["id"] = rotated_id
		rotated_data["rotation"] = rotation
		world.call("_spawn_structure_visual", rotated_id, rotated_data)
		await process_frame
		var rotated_visual := (world.get("settlement_visuals") as Dictionary).get(rotated_id) as Node3D
		var rotated_sprite := rotated_visual.get_node_or_null("IllustratedStructurePresentation/IllustratedStateSprite") as Sprite3D if rotated_visual != null else null
		_check(rotated_sprite != null, "operational Workshop rotation %d must retain a directional hero sprite" % rotation)
		if rotated_sprite != null:
			var expected_operational_path := str(AssetCatalog.structure_directional_variant("workshop", rotation).get("asset_path", ""))
			_check(str(rotated_sprite.get_meta("directional_asset_path", "")) == expected_operational_path, "operational Workshop rotation %d must bind its authored directional hero asset" % rotation)
			var operational_texture := load(expected_operational_path) as Texture2D
			var operational_image := operational_texture.get_image() if operational_texture != null else null
			var operational_bounds := operational_image.get_used_rect() if operational_image != null else Rect2i()
			var operational_measurement: Dictionary = rotated_visual.get_meta("source_measurement", {})
			var operational_fitted: Vector3 = operational_measurement.get("fitted_size", Vector3.ZERO)
			if operational_bounds.size.x > 0 and operational_fitted.length_squared() > 0.01:
				var operational_extent: float = style.call("_measured_projected_horizontal_extent", rotated_visual, operational_fitted) if style != null else 0.0
				_check(float(operational_bounds.size.x) * rotated_sprite.pixel_size >= operational_extent * 0.96, "operational Workshop rotation %d alpha width must cover its measured projected shell" % rotation)
			_check(str(rotated_visual.get_meta("operational_art_source", "")) == "generated_player_structure_directional", "operational Workshop rotation %d must not fall back to a generic sheet" % rotation)
	_finish(world)

func _check_no_live_green_fringe(path: String, region: Rect2i, label: String) -> void:
	var texture := load(path) as Texture2D
	var image := texture.get_image() if texture != null else null
	_check(image != null, "%s must remain readable for chroma QA" % label)
	if image == null:
		return
	var end_x := mini(image.get_width(), region.end.x)
	var end_y := mini(image.get_height(), region.end.y)
	for y in range(maxi(0, region.position.y), end_y):
		for x in range(maxi(0, region.position.x), end_x):
			var color := image.get_pixel(x, y)
			var saturated_green := color.g > color.r * 1.25 and color.g > color.b * 1.35 and color.g > 0.47
			var yellow_green := color.r > 0.35 and color.g > color.r * 0.98 and color.b < 0.20
			if color.a > 0.05 and (saturated_green or yellow_green):
				_check(false, "%s must not contain an opaque chroma-green pixel at %d,%d" % [label, x, y])
				return

func _wait_frames(count: int) -> void:
	for _index in count:
		await process_frame

func _finish(world: Node) -> void:
	if is_instance_valid(world):
		world.queue_free()
	if failures.is_empty():
		print("WORKSHOP_STAGE_VISUAL_PASS checks=%d" % checks)
		quit(0)
	else:
		print("WORKSHOP_STAGE_VISUAL_FAIL count=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  " + failure)
		quit(1)
