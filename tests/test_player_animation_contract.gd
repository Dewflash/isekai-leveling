extends SceneTree

const MainScene := preload("res://main.tscn")

const SAVE_SLOT := "qa_player_animation_contract"

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("PLAYER_ANIMATION_CONTRACT_FAIL: " + message)

func _run() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", SAVE_SLOT)
	var world := MainScene.instantiate()
	root.add_child(world)
	await _wait_frames(12)
	var player := world.get("player") as CharacterBody3D
	var sprite := player.get_node_or_null("Visual/IllustratedCharacter") as Sprite3D if player != null else null
	_check(player != null, "Main must expose the player for animation binding")
	_check(sprite != null, "player must expose the authored illustrated character sprite")
	if sprite == null:
		_finish(world)
		return
	var walk_path := str(sprite.get_meta("walk_asset_path", ""))
	var idle_path := str(sprite.get_meta("idle_asset_path", ""))
	_check(walk_path == "res://assets/generated/sanctuary/player-walk-sheet.png", "player must bind the authored multi-frame walk sheet")
	_check(idle_path == "res://assets/generated/sanctuary/player-direction-sheet.png", "player must preserve the authored idle sheet")
	_check(ResourceLoader.exists(walk_path), "authored walk sheet must be importable")
	var walk_sheet := load(walk_path) as Texture2D
	var idle_sheet := load(idle_path) as Texture2D
	_check(walk_sheet != null and walk_sheet.get_width() > 0 and walk_sheet.get_height() > 0, "walk sheet must be readable")
	_check(idle_sheet != null and idle_sheet.get_width() > 0 and idle_sheet.get_height() > 0, "idle sheet must be readable")
	_check(int(sprite.get_meta("direction_frames", 0)) == 4, "player must retain four authored direction rows")
	_check(int(sprite.get_meta("walk_frame_count", 0)) == 4, "player must expose four authored walk frames")
	_check(float(sprite.get_meta("walk_frame_rate", 0.0)) > 0.0, "player must expose a positive authored walk frame rate")
	var walk_gaps: Array = sprite.get_meta("walk_bottom_gaps", [])
	_check(walk_gaps.size() == 4, "walk alpha measurement must retain one bottom-pivot row per direction")
	for direction in walk_gaps:
		_check(direction is Array and (direction as Array).size() == 4, "walk alpha measurement must retain four per-frame feet offsets")
	var idle_gaps: Array = sprite.get_meta("idle_bottom_gaps", [])
	_check(idle_gaps.size() == 4, "idle alpha measurement must retain one feet offset per direction")
	_check(sprite.pixel_size > 0.0, "player animation must use a positive measured world scale")
	var idle_atlas := sprite.get_meta("idle_atlas", null) as AtlasTexture
	var walk_atlas := sprite.get_meta("walk_atlas", null) as AtlasTexture
	_check(idle_atlas != null and idle_atlas.atlas == idle_sheet, "idle animation must use the idle source atlas")
	_check(walk_atlas != null and walk_atlas.atlas == walk_sheet, "walk animation must use the walk source atlas")
	_check(sprite.texture == idle_atlas, "player must begin on the idle atlas")

	if player != null:
		player.call("set_joystick_vector", Vector2(1.0, 0.0))
	var frames_seen: Array[int] = []
	for _index in 6:
		await _wait_seconds(0.18)
		var frame := int(sprite.get_meta("animation_frame", -1))
		if not frames_seen.has(frame):
			frames_seen.append(frame)
	_check(str(sprite.get_meta("animation_state", "")) == "walk", "moving player must enter the authored walk animation state")
	_check(sprite.texture == walk_atlas, "moving player must switch to the walk atlas")
	_check(frames_seen.size() >= 2, "moving player must advance through multiple authored walk frames")
	_check(int(sprite.get_meta("animation_frame", -1)) >= 0 and int(sprite.get_meta("animation_frame", -1)) < 4, "walk frame index must stay inside the authored frame range")
	_check(sprite.offset.y <= 0.0, "walk animation must retain its measured feet pivot")

	if player != null:
		player.call("set_joystick_vector", Vector2.ZERO)
	await _wait_seconds(0.75)
	_check(str(sprite.get_meta("animation_state", "")) == "idle", "released player must return to idle animation")
	_check(sprite.texture == idle_atlas, "idle player must return to the idle atlas")
	_check(int(sprite.get_meta("animation_frame", -1)) == 0, "idle animation must use its stable authored frame")
	_check(int(sprite.get_meta("direction_frame", -1)) >= 0 and int(sprite.get_meta("direction_frame", -1)) < 4, "direction frame must remain bounded")
	_finish(world)

func _wait_frames(count: int) -> void:
	for _index in count:
		await process_frame

func _wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout

func _finish(world: Node) -> void:
	if is_instance_valid(world):
		world.queue_free()
	if failures.is_empty():
		print("PLAYER_ANIMATION_CONTRACT_PASS checks=%d" % checks)
		quit(0)
	else:
		print("PLAYER_ANIMATION_CONTRACT_FAIL count=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  " + failure)
		quit(1)
