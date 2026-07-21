extends SceneTree

const MainScene := preload("res://main.tscn")
const AssetCatalog := preload("res://scripts/sanctuary_asset_catalog.gd")

const SAVE_SLOT := "qa_storage_shed_visuals"

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("STORAGE_SHED_VISUAL_FAIL: " + message)

func _run() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", SAVE_SLOT)
	var world := MainScene.instantiate()
	root.add_child(world)
	await _wait_frames(12)
	var style := world.get("sanctuary_style") as Node3D
	_check(style != null, "Sanctuary style must expose measured cutout projection")
	var definition := AssetCatalog.structure_definition("storage_shed")
	_check(bool(definition.get("directional_art_required", false)), "Storage Shed must require authored directional art")
	var variants: Array = definition.get("directional_variants", [])
	_check(variants.size() == 4, "Storage Shed must declare four operational directional variants")
	var expected_visible_features := [
		["front_door", "loading_side"],
		["front_door"],
		[],
		["loading_side"],
	]
	for rotation in [0, 1, 2, 3]:
		var variant_features: Array = variants[rotation].get("visible_feature_ids", [])
		_check(variant_features == expected_visible_features[rotation], "Storage Shed q%d must declare the features actually visible in its art" % rotation)
	var operational_heights: Array[float] = []
	var stage_ids := ["blueprint", "frame", "walls", "roof"]
	for stage_id in stage_ids:
		for rotation in [0, 1, 2, 3]:
			var path := AssetCatalog.structure_construction_stage_asset("storage_shed", stage_id, rotation)
			_check(not path.is_empty() and ResourceLoader.exists(path), "Storage Shed %s q%d stage asset must be importable" % [stage_id, rotation])
			_check(_has_opaque_pixels(path), "Storage Shed %s q%d stage asset must have a measured alpha envelope" % [stage_id, rotation])
	for rotation in [0, 1, 2, 3]:
		var operational_id := "storage_shed_visual_qa_%d" % rotation
		var operational_data := {
			"id": operational_id,
			"kind": "storage_shed",
			"cell": [4 + rotation, -6],
			"rotation": rotation,
			"state": "operational",
			"remaining_hours": 0.0,
			"total_hours": 24.0,
			"delivered_materials": {"wood": 12, "stone": 8},
		}
		world.call("_spawn_structure_visual", operational_id, operational_data)
		await process_frame
		var visual := (world.get("settlement_visuals") as Dictionary).get(operational_id) as Node3D
		var sprite := visual.get_node_or_null("IllustratedStructurePresentation/IllustratedStateSprite") as Sprite3D if visual != null else null
		var expected_path := str(AssetCatalog.structure_directional_variant("storage_shed", rotation).get("asset_path", ""))
		_check(sprite != null, "Storage Shed q%d operational sprite must render" % rotation)
		_check(sprite != null and str(sprite.get_meta("directional_asset_path", "")) == expected_path, "Storage Shed q%d operational sprite must bind its authored direction" % rotation)
		_check(sprite != null and str(visual.get_meta("operational_art_source", "")) == "generated_player_structure_directional", "Storage Shed q%d must not fall back to a generic sheet" % rotation)
		_check(visual != null and not bool(visual.get_meta("visual_art_missing", true)), "Storage Shed q%d must not report missing art" % rotation)
		var measurement: Dictionary = visual.get_meta("source_measurement", {}) if visual != null else {}
		var fit_ratio: Vector2 = measurement.get("horizontal_fit_ratio", Vector2.ZERO)
		_check(fit_ratio.x >= 0.90 and fit_ratio.y >= 0.90, "Storage Shed q%d source envelope must materially fill its claimed footprint" % rotation)
		var visual_size: Array = sprite.get_meta("visual_size", []) if sprite != null else []
		_check(visual_size.size() >= 2 and float(visual_size[1]) > 0.0, "Storage Shed q%d must publish a measured visible height" % rotation)
		if visual_size.size() >= 2:
			operational_heights.append(float(visual_size[1]))
		_check(_alpha_covers_projected_shell(style, visual, sprite, expected_path), "Storage Shed q%d operational alpha must cover its measured projected shell" % rotation)
		for stage_id in stage_ids:
			var stage_id_key := "storage_shed_visual_qa_%d_%s" % [rotation, stage_id]
			var stage_data := operational_data.duplicate(true)
			stage_data["id"] = stage_id_key
			stage_data["state"] = "blueprint" if stage_id == "blueprint" else "building"
			stage_data["remaining_hours"] = 24.0 if stage_id == "frame" else (12.0 if stage_id == "walls" else (5.0 if stage_id == "roof" else 24.0))
			world.call("_spawn_structure_visual", stage_id_key, stage_data)
			await process_frame
			var stage_visual := (world.get("settlement_visuals") as Dictionary).get(stage_id_key) as Node3D
			var stage_sprite := stage_visual.get_node_or_null("IllustratedStructurePresentation/IllustratedStateSprite") as Sprite3D if stage_visual != null else null
			var stage_path := AssetCatalog.structure_construction_stage_asset("storage_shed", stage_id, rotation)
			_check(stage_sprite != null, "Storage Shed q%d %s stage must render" % [rotation, stage_id])
			_check(stage_sprite != null and str(stage_sprite.get_meta("construction_stage", "")) == stage_id, "Storage Shed q%d %s must bind its stage identity" % [rotation, stage_id])
			_check(stage_sprite != null and str(stage_sprite.get_meta("directional_asset_path", "")) == stage_path, "Storage Shed q%d %s must bind its authored stage direction" % [rotation, stage_id])
			_check(stage_visual != null and not bool(stage_visual.get_meta("visual_art_missing", true)), "Storage Shed q%d %s must not report missing art" % [rotation, stage_id])
			_check(_alpha_covers_projected_shell(style, stage_visual, stage_sprite, stage_path), "Storage Shed q%d %s alpha must cover its measured projected shell" % [rotation, stage_id])
	if operational_heights.size() == 4:
		var minimum_height: float = float(operational_heights.min())
		var maximum_height: float = float(operational_heights.max())
		_check(maximum_height - minimum_height <= maxf(0.04, minimum_height * 0.03), "Storage Shed directional views must share one calibrated visible height")
	_finish(world)

func _has_opaque_pixels(path: String) -> bool:
	var texture := load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
	var image := texture.get_image() if texture != null else null
	return image != null and image.get_used_rect().size.x > 0 and image.get_used_rect().size.y > 0

func _alpha_covers_projected_shell(style: Node3D, visual: Node3D, sprite: Sprite3D, path: String) -> bool:
	if style == null or visual == null or sprite == null or path.is_empty():
		return false
	var texture := load(path) as Texture2D
	var image := texture.get_image() if texture != null else null
	if image == null:
		return false
	var bounds := image.get_used_rect()
	var measured: Dictionary = visual.get_meta("source_measurement", {})
	var fitted_size: Vector3 = measured.get("fitted_size", Vector3.ZERO)
	if bounds.size.x <= 0 or fitted_size.length_squared() <= 0.01:
		return false
	var projected_extent: float = style.call("_measured_projected_horizontal_extent", visual, fitted_size)
	return float(bounds.size.x) * sprite.pixel_size >= projected_extent * 0.96

func _wait_frames(count: int) -> void:
	for _index in count:
		await process_frame

func _finish(world: Node) -> void:
	if is_instance_valid(world):
		world.queue_free()
	if failures.is_empty():
		print("STORAGE_SHED_VISUAL_PASS checks=%d" % checks)
		quit(0)
	else:
		print("STORAGE_SHED_VISUAL_FAIL count=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  " + failure)
		quit(1)
