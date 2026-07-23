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
	_check(slots != null and slots.get_child_count() >= 9, "bottom action belt must expose the repeatable action slots")
	var extract_slot := slots.get_node_or_null("ReferenceSlot_EXTRACT") as Button if slots != null else null
	_check(extract_slot != null, "bottom action belt must expose the extraction action")
	_check(extract_slot != null and extract_slot.disabled, "extraction must be disabled until the player reaches a valid expedition beacon")
	var attack_slot := slots.get_node_or_null("ReferenceSlot_ATTACK") as Button if slots != null else null
	var dodge_slot := slots.get_node_or_null("ReferenceSlot_DODGE") as Button if slots != null else null
	var water_slot := slots.get_node_or_null("ReferenceSlot_WATER") as Button if slots != null else null
	_check(attack_slot != null and attack_slot.disabled, "attack must be disabled outside guardian range")
	_check(dodge_slot != null and dodge_slot.disabled, "dodge must be disabled in the Sanctuary")
	_check(water_slot != null and not water_slot.disabled, "water must remain available in the Sanctuary when the pouch can be used")
	var belt_style := belt.get_theme_stylebox("panel") if belt != null else null
	_check(belt_style is StyleBoxTexture, "bottom action belt must use the sourced warm panel texture")
	var first_slot := slots.get_child(0) as Button if slots != null and slots.get_child_count() > 0 else null
	var first_slot_icon := first_slot.get_node_or_null("SlotIcon") if first_slot != null else null
	_check(first_slot != null and first_slot_icon is Control and first_slot.get_node_or_null("SlotCaption") is Label, "action slots must expose a readable icon/caption treatment")
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
	var session := world.get("session") as Node
	var started_expedition := session != null and bool(session.call("start_expedition", "Whisperwood"))
	_check(started_expedition, "HUD state test must be able to start a disposable expedition")
	if started_expedition:
		world.call("_set_zone", "Whisperwood")
		var player := world.get("player") as Node3D
		player.global_position = Vector3(0.0, 1.0, 7.5)
		world.call("_update_hud")
		_check(not bool(extract_slot.disabled), "extraction must enable at the expedition beacon before a route checkpoint is required")
		var route_definition: Dictionary = session.call("expedition_route_definition", "grove")
		var expedition_run: Dictionary = session.get("expedition_run").duplicate(true)
		expedition_run["branch_id"] = "grove"
		expedition_run["objective_id"] = str(route_definition.get("objective_id", ""))
		expedition_run["objective_kind"] = str(route_definition.get("objective_kind", ""))
		expedition_run["objective_progress"] = int(route_definition.get("objective_target", 1))
		expedition_run["objective_target"] = int(route_definition.get("objective_target", 1))
		expedition_run["objective_complete"] = true
		expedition_run["shortcut_open"] = true
		expedition_run["cache_claimed"] = true
		expedition_run["route_checkpoints"] = ["arrival", "fork"]
		expedition_run["route_phase"] = "shortcut"
		session.set("expedition_run", expedition_run)
		world.call("_update_hud")
		_check(bool(extract_slot.disabled), "extraction must remain disabled while the return checkpoint is required")
		expedition_run["route_phase"] = "return"
		expedition_run["return_checkpoint_crossed"] = true
		expedition_run["route_checkpoints"] = ["arrival", "fork", "return"]
		session.set("expedition_run", expedition_run)
		world.call("_update_hud")
		_check(not bool(extract_slot.disabled), "extraction must re-enable after the return checkpoint is crossed")
	world.queue_free()
	if failures.is_empty():
		print("REFERENCE_HUD_TESTS_PASS checks=27")
		quit(0)
	else:
		print("REFERENCE_HUD_TESTS_FAIL failures=%d" % failures.size())
		for failure in failures:
			print("  ", failure)
		quit(1)
