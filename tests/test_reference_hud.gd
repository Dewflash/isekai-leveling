extends SceneTree

const MainScene := preload("res://main.tscn")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("REFERENCE_HUD_FAIL: " + message)

func _run() -> void:
	var world := MainScene.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	world.call("_update_hud")
	var reference := world.get_node_or_null("HUD/HudRoot/ReferenceGameplayHUD") as Control
	_check(reference != null, "reference gameplay HUD must be present")
	if reference == null:
		quit(1)
		return
	_check(reference.visible, "reference gameplay HUD is visible during normal play")
	var top := reference.get_node_or_null("ReferenceTopStatus") as Panel
	var portrait := reference.get_node_or_null("ReferenceTopStatus/StatusHeaderRow/ReferencePortrait") as TextureRect
	var objective := reference.get_node_or_null("ReferenceTopStatus/StatusHeaderRow/ReferenceIdentity/ReferenceObjective") as Label
	var stat_rail := reference.get_node_or_null("ReferenceStatRail") as VBoxContainer
	var belt := reference.get_node_or_null("ReferenceActionBelt") as Panel
	var slots := reference.get_node_or_null("ReferenceActionBelt/ActionBeltBox/ReferenceSlotScroll/ReferenceSlotBox") as HBoxContainer
	var context_button := reference.get_node_or_null("ReferenceActionBelt/ActionBeltBox/QuickResourceRow/ReferenceContextButton") as Button
	_check(top != null, "top status header must exist")
	_check(portrait != null and portrait.texture != null, "top status header must use the authored player portrait")
	_check(objective != null and not objective.text.is_empty(), "top status header must expose the current objective")
	_check(objective != null and objective.text.begins_with("START"), "fresh gameplay must begin with a clear first-run objective")
	_check(stat_rail != null and stat_rail.get_child_count() == 5, "stat rail must expose five compact status pills")
	_check(belt != null, "bottom action belt must exist")
	_check(slots != null and slots.get_child_count() >= 8, "bottom action belt must expose the repeatable action slots")
	_check(slots != null and slots.get_node_or_null("ReferenceSlot_EXTRACT") is Button, "bottom action belt must expose the extraction action")
	var belt_style := belt.get_theme_stylebox("panel") if belt != null else null
	_check(belt_style is StyleBoxTexture, "bottom action belt must use the sourced warm panel texture")
	var first_slot := slots.get_child(0) as Button if slots != null and slots.get_child_count() > 0 else null
	_check(first_slot != null and first_slot.get_node_or_null("SlotIcon") is Label and first_slot.get_node_or_null("SlotCaption") is Label, "action slots must expose a readable icon/caption treatment")
	_check(context_button != null, "bottom action belt must expose a contextual interaction button")
	_check(not bool((world.get("hud_top_panel") as Panel).visible), "prototype top panel must yield to the reference header")
	_check(not bool((world.get("hud_action_panel") as Panel).visible), "prototype context panel must yield to the action belt")
	_check(not bool((world.get("hud_right_panel") as Panel).visible), "prototype management panel must yield to the compact header")
	world.call("_toggle_utilities")
	world.call("_update_hud")
	_check(not reference.visible, "reference gameplay HUD hides while the ledger is open")
	_check(bool((world.get("hud_bag_panel") as Panel).visible), "ledger remains available as an expanded management view")
	world.call("_toggle_utilities")
	world.call("_update_hud")
	_check(reference.visible, "reference gameplay HUD returns after closing the ledger")
	world.queue_free()
	if failures.is_empty():
		print("REFERENCE_HUD_TESTS_PASS checks=19")
		quit(0)
	else:
		print("REFERENCE_HUD_TESTS_FAIL failures=%d" % failures.size())
		for failure in failures:
			print("  ", failure)
		quit(1)
