extends SceneTree

const MainScene := preload("res://main.tscn")
const MIRA_SHEET_PATH := "res://assets/generated/sanctuary/mira-direction-walk-sheet-v2.png"

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("MIRA_ANIMATION_FAIL: " + message)

func _run() -> void:
	var world := MainScene.instantiate()
	root.add_child(world)
	await _wait_frames(12)
	var mira := world.get_node_or_null("Sanctuary/MiraWayfarer") as Node3D
	var visual := mira.get_node_or_null("Visual") as Node3D if mira != null else null
	var sprite := visual.get_node_or_null("IllustratedMira") as Sprite3D if visual != null else null
	_check(mira != null, "Mira must exist in the Sanctuary")
	_check(sprite != null, "Mira must use an illustrated sprite")
	if sprite != null:
		_check(ResourceLoader.exists(MIRA_SHEET_PATH), "Mira walk sheet must be project-bound")
		_check(str(sprite.get_meta("asset_path", "")) == MIRA_SHEET_PATH, "Mira must use the four-row walk sheet")
		_check(int(sprite.get_meta("walk_frame_count", 0)) == 4, "Mira must expose four authored walk frames")
		_check(int(sprite.get_meta("direction_frames", 0)) == 4, "Mira must expose four directional rows")
		_check(str(sprite.get_meta("animation_measurement_source", "")) == "per_cell_texture_alpha_used_rect", "Mira frame offsets must be alpha-measured")
		var atlas := sprite.texture as AtlasTexture
		_check(atlas != null, "Mira must use an atlas texture")
		var cell_size: Array = sprite.get_meta("walk_cell_size", [])
		_check(cell_size.size() == 2 and float(cell_size[0]) > 0.0 and float(cell_size[1]) > 0.0, "Mira must expose measured cell size")
		if atlas != null and cell_size.size() == 2:
			var villager_script: Script = mira.get_script()
			_check(villager_script != null, "Mira must keep her deterministic routine")
			var travel_by_direction: Array[Vector3] = [Vector3(0.0, 0.0, 1.0), Vector3(1.0, 0.0, 0.0), Vector3(0.0, 0.0, -1.0), Vector3(-1.0, 0.0, 0.0)]
			for direction in 4:
				for frame in 4:
					mira.set("_walk_frame_time", float(frame) / 6.0 + 0.001)
					mira.call("_update_illustrated_mira", true, travel_by_direction[direction])
					_check(int(sprite.get_meta("animation_frame", -1)) == frame, "Mira must advance authored frame %d in direction %d" % [frame, direction])
					_check(int(sprite.get_meta("direction_frame", -1)) >= 0 and int(sprite.get_meta("direction_frame", -1)) < 4, "Mira direction must stay within four authored rows")
					_check(is_equal_approx(atlas.region.size.x, float(cell_size[0])) and is_equal_approx(atlas.region.size.y, float(cell_size[1])), "Mira atlas region must stay on measured cells")
			mira.set("_walk_frame_time", 0.0)
			mira.call("_update_illustrated_mira", false, Vector3(0.0, 0.0, 1.0))
			_check(int(sprite.get_meta("animation_frame", -1)) == 0, "Mira idle must resolve to a stable authored frame")

	world.queue_free()
	if failures.is_empty():
		print("MIRA_ANIMATION_PASS checks=%d" % checks)
		quit(0)
	else:
		print("MIRA_ANIMATION_FAIL failures=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  ", failure)
		quit(1)

func _wait_frames(count: int) -> void:
	for _index in count:
		await process_frame
