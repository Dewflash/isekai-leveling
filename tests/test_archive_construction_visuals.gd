extends SceneTree

## Runtime proof for Archive's authored construction family. The family is
## deliberately shared across the four phase IDs, but never across camera
## directions: each phase resolves the same direction-specific frame kit and
## the later milestones add a measured hero overlay.

const MainScene := preload("res://main.tscn")
const AssetCatalog := preload("res://scripts/sanctuary_asset_catalog.gd")

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("ARCHIVE_CONSTRUCTION_VISUAL_FAIL: " + message)

func _run() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", "qa_archive_construction_visuals")
	var world := MainScene.instantiate()
	root.add_child(world)
	await _wait_frames(12)
	var style := world.get("sanctuary_style") as Node3D
	var definition := AssetCatalog.structure_definition("archive")
	_check(bool(definition.get("directional_art_required", false)), "Archive must require authored directional construction art")
	var stage_ids := ["blueprint", "frame", "walls", "roof"]
	var stage_paths := {}
	for stage_id in stage_ids:
		stage_paths[stage_id] = {}
		for rotation in [0, 1, 2, 3]:
			var path := AssetCatalog.structure_construction_stage_asset("archive", stage_id, rotation)
			_check(not path.is_empty() and ResourceLoader.exists(path), "Archive %s q%d stage asset must import" % [stage_id, rotation])
			_check(_has_opaque_pixels(path), "Archive %s q%d stage asset must expose a measured alpha envelope" % [stage_id, rotation])
			stage_paths[stage_id][rotation] = path
			_check(path == "res://assets/generated/sanctuary/archive/archive-construction-frame-q%d.png" % rotation, "Archive %s q%d must bind its authored directional frame kit" % [stage_id, rotation])
	for rotation in [0, 1, 2, 3]:
		var cases := [
			["blueprint", "blueprint", 24.0, false],
			["frame", "building", 20.0, false],
			["walls", "building", 12.0, true],
			["roof", "building", 5.0, true],
		]
		for case_value in cases:
			var expected_stage: String = case_value[0]
			var id := "archive_construction_qa_%d_%s" % [rotation, expected_stage]
			var data := {
				"id": id,
				"kind": "archive",
				"cell": [6 + rotation * 8, -8],
				"rotation": rotation,
				"state": str(case_value[1]),
				"remaining_hours": float(case_value[2]),
				"total_hours": 24.0,
				"delivered_materials": {"wood": 8, "stone": 8, "plank": 3},
			}
			world.call("_spawn_structure_visual", id, data)
			await process_frame
			var visual := (world.get("settlement_visuals") as Dictionary).get(id) as Node3D
			var presentation := visual.get_node_or_null("IllustratedStructurePresentation") as Node3D if visual != null else null
			var sprite := presentation.get_node_or_null("IllustratedStateSprite") as Sprite3D if presentation != null else null
			_check(sprite != null, "Archive %s q%d must render its state sprite" % [expected_stage, rotation])
			if sprite == null:
				continue
			_check(str(sprite.get_meta("construction_stage", "")) == expected_stage, "Archive %s q%d must publish its phase identity" % [expected_stage, rotation])
			_check(str(sprite.get_meta("directional_asset_path", "")) == stage_paths[expected_stage][rotation], "Archive %s q%d must bind the correct direction" % [expected_stage, rotation])
			_check(str(visual.get_meta("operational_art_source", "")) == "generated_archive_construction_stage", "Archive %s q%d must not use generic scaffold art" % [expected_stage, rotation])
			_check(not bool(visual.get_meta("visual_art_missing", true)), "Archive %s q%d must not report missing art" % [expected_stage, rotation])
			var measured: Dictionary = visual.get_meta("source_measurement", {})
			var fitted_size: Vector3 = measured.get("fitted_size", Vector3.ZERO)
			var stage_texture := load(stage_paths[expected_stage][rotation]) as Texture2D
			var stage_image := stage_texture.get_image() if stage_texture != null else null
			if style != null and stage_image != null and fitted_size.length_squared() > 0.01:
				var projected_extent: float = style.call("_measured_projected_horizontal_extent", visual, fitted_size)
				var visual_size: Array = sprite.get_meta("visual_size", [])
				_check(visual_size.size() >= 1 and float(visual_size[0]) >= projected_extent * 0.96, "Archive %s q%d alpha width must cover its measured shell" % [expected_stage, rotation])
			var overlay := presentation.get_node_or_null("ArchiveConstructionPhaseOverlay") as Sprite3D
			_check((expected_stage in ["walls", "roof"]) == (overlay != null), "Archive %s q%d must reveal its hero overlay only after wall materials" % [expected_stage, rotation])
			if overlay != null:
				_check(str(overlay.get_meta("construction_phase_overlay", "")) == expected_stage, "Archive %s q%d overlay must identify its authored phase" % [expected_stage, rotation])
				_check(str(overlay.get_meta("directional_asset_path", "")) == str(AssetCatalog.structure_directional_variant("archive", rotation).get("asset_path", "")), "Archive %s q%d overlay must use the same directional hero" % [expected_stage, rotation])
	_finish(world)

func _has_opaque_pixels(path: String) -> bool:
	var texture := load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
	var image := texture.get_image() if texture != null else null
	return image != null and image.get_used_rect().size.x > 0 and image.get_used_rect().size.y > 0

func _wait_frames(count: int) -> void:
	for _index in count:
		await process_frame

func _finish(world: Node) -> void:
	if is_instance_valid(world):
		world.queue_free()
	if failures.is_empty():
		print("ARCHIVE_CONSTRUCTION_VISUAL_PASS checks=%d" % checks)
		quit(0)
	else:
		print("ARCHIVE_CONSTRUCTION_VISUAL_FAIL count=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  " + failure)
		quit(1)
