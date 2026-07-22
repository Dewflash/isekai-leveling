extends SceneTree

## Runtime proof for the authored operational facility families that replaced
## the shared prop-sheet fallback. Construction-stage families remain separate
## contracts; this test only accepts a real, measured four-view operational set.

const MainScene := preload("res://main.tscn")
const AssetCatalog := preload("res://scripts/sanctuary_asset_catalog.gd")

const FACILITY_KINDS := ["archive", "livestock_pen", "rain_cistern"]

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("SANCTUARY_DIRECTIONAL_FAMILY_FAIL: " + message)

func _run() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", "qa_sanctuary_directional_families")
	var world := MainScene.instantiate()
	root.add_child(world)
	await _wait_frames(12)
	for kind_index in FACILITY_KINDS.size():
		var kind: String = FACILITY_KINDS[kind_index]
		var definition := AssetCatalog.structure_definition(kind)
		var variants: Array = definition.get("directional_variants", [])
		_check(variants.size() == 4, "%s must expose four operational views" % kind)
		var paths := {}
		for rotation in 4:
			var variant := AssetCatalog.structure_directional_variant(kind, rotation)
			var path := str(variant.get("asset_path", ""))
			_check(not path.is_empty() and ResourceLoader.exists(path), "%s q%d operational asset must import" % [kind, rotation])
			_check(_has_opaque_pixels(path), "%s q%d operational asset must have measured alpha" % [kind, rotation])
			_check(not paths.has(path), "%s q%d must use a unique directional texture" % [kind, rotation])
			paths[path] = true
			var instance_id := "directional_family_%s_%d" % [kind, rotation]
			var data := {
				"id": instance_id,
				"kind": kind,
				"cell": [18 + rotation * 7, 6 + kind_index * 8],
				"rotation": rotation,
				"state": "operational",
				"remaining_hours": 0.0,
				"total_hours": 24.0,
				"delivered_materials": {"wood": 16, "stone": 12, "fiber": 6, "plank": 6},
			}
			world.call("_spawn_structure_visual", instance_id, data)
			await process_frame
			var visual := (world.get("settlement_visuals") as Dictionary).get(instance_id) as Node3D
			var sprite := visual.get_node_or_null("IllustratedStructurePresentation/IllustratedStateSprite") as Sprite3D if visual != null else null
			_check(sprite != null, "%s q%d operational sprite must render" % [kind, rotation])
			_check(visual != null and str(visual.get_meta("operational_art_source", "")) == "generated_player_structure_directional", "%s q%d must not fall back to the shared prop sheet" % [kind, rotation])
			_check(sprite != null and str(sprite.get_meta("directional_asset_path", "")) == path, "%s q%d must bind its authored direction" % [kind, rotation])
			_check(sprite != null and str(sprite.get_meta("opaque_measurement_source", "")) == "texture_alpha_used_rect", "%s q%d must retain alpha-envelope provenance" % [kind, rotation])
			var visual_size: Array = sprite.get_meta("visual_size", []) if sprite != null else []
			_check(visual_size.size() >= 2 and float(visual_size[0]) > 0.0 and float(visual_size[1]) > 0.0, "%s q%d must publish a positive measured visible size" % [kind, rotation])
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
		print("SANCTUARY_DIRECTIONAL_FAMILY_PASS checks=%d facilities=%d" % [checks, FACILITY_KINDS.size()])
		quit(0)
	else:
		print("SANCTUARY_DIRECTIONAL_FAMILY_FAIL count=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  " + failure)
		quit(1)
