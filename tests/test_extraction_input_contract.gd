extends SceneTree

## The extraction action must be reachable through the reference gameplay HUD,
## not only through a hidden management panel or a test-only private call.

const MainScene = preload("res://main.tscn")

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("EXTRACTION_INPUT_FAIL: %s" % message)

func _run() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", "qa_extraction_input")
	for suffix in [".json", ".backup.json", ".tmp.json"]:
		var path := "user://qa_extraction_input%s" % suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var world := MainScene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var session: Node = world.get("session")
	_check(session != null, "extraction test requires a live session")
	if session == null:
		quit(1)
		return
	session.get("unlocked_routes").append("Whisperwood")
	session.energy = 24
	session.coins = 100
	_check(bool(session.call("start_expedition", "Whisperwood")), "test expedition starts")
	world.call("_set_zone", "Whisperwood")
	world.player.global_position = Vector3(0.0, 1.0, 0.0)
	await process_frame
	await process_frame
	var extraction_button := world.get_node_or_null("HUD/HudRoot/ReferenceGameplayHUD/ReferenceActionBelt/ActionBeltBox/ReferenceSlotScroll/ReferenceSlotBox/ReferenceSlot_EXTRACT") as Button
	_check(extraction_button != null, "reference action belt exposes an extraction control")
	if extraction_button != null:
		_check(extraction_button.visible, "extraction control is visible during an expedition")
		_check(extraction_button.disabled, "extraction control is gated away from the beacon")
	world.player.global_position = Vector3(0.0, 1.0, 7.5)
	world.call("_update_hud")
	await process_frame
	_check(extraction_button != null and not extraction_button.disabled, "extraction control enables at the beacon")
	if extraction_button != null:
		extraction_button.emit_signal("pressed")
	await process_frame
	_check(str(world.get("current_zone")) == "Sanctuary", "HUD extraction returns to Sanctuary")
	_check(not bool(session.call("has_active_expedition")), "HUD extraction closes the active run")
	world.queue_free()
	if failures > 0:
		print("EXTRACTION_INPUT_TESTS_FAIL failures=%d" % failures)
		quit(1)
		return
	print("EXTRACTION_INPUT_TESTS_PASS checks=8")
	quit(0)
