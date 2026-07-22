extends SceneTree

const MainScene := preload("res://main.tscn")

const SAVE_SLOT := "qa_build_catalog"
const EXPECTED_CARDS := ["workshop", "archive", "storage_shed", "livestock_pen", "rain_cistern"]

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", SAVE_SLOT)
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("BUILD_CATALOG_FAIL: " + message)

func _run() -> void:
	var world := MainScene.instantiate()
	root.add_child(world)
	await _wait_frames(12)

	var reference := world.get_node_or_null("HUD/HudRoot/ReferenceGameplayHUD") as Control
	var panel := reference.get_node_or_null("BuildCatalogPanel") as Panel if reference != null else null
	var backdrop := reference.get_node_or_null("BuildCatalogBackdrop") as ColorRect if reference != null else null
	var cards := reference.get_node_or_null("BuildCatalogPanel/BuildCatalogCardScroll/BuildCatalogCards") as HBoxContainer if reference != null else null
	var place_button := reference.get_node_or_null("BuildCatalogPanel/BuildCatalogPlace") as Button if reference != null else null
	var rotate_button := reference.get_node_or_null("BuildCatalogPanel/BuildCatalogRotate") as Button if reference != null else null
	_check(reference != null, "build catalogue must live in the reference gameplay HUD")
	_check(panel != null and not panel.visible, "build catalogue must be hidden during normal play")
	_check(backdrop != null and not backdrop.visible, "build catalogue backdrop must be hidden during normal play")
	_check(cards != null and cards.get_child_count() == EXPECTED_CARDS.size(), "catalogue must expose one card for every player structure")
	_check(place_button != null and rotate_button != null, "catalogue must expose place and rotate controls")

	if cards != null:
		for structure_id in EXPECTED_CARDS:
			var card := cards.get_node_or_null("BuildCatalogCard_%s" % structure_id) as Button
			_check(card != null, "catalogue card must exist for %s" % structure_id)
			if card == null:
				continue
			var art := card.get_node_or_null("ArtFrame/StructureArt") as TextureRect
			var footprint := card.get_node_or_null("Footprint") as Label
			var availability := card.get_node_or_null("Availability") as Label
			_check(art != null and art.texture != null, "%s card must use its authored directional asset" % structure_id)
			_check(footprint != null and footprint.text.contains("m  •  1 cell = 1 m"), "%s card must expose its measured grid scale" % structure_id)
			_check(availability != null and not availability.text.is_empty(), "%s card must expose unlock/cost state" % structure_id)

	world.call("_set_build_catalog_open", true)
	await process_frame
	_check(bool(world.get("build_catalog_open")), "catalogue open state must be authoritative")
	_check(panel != null and panel.visible, "catalogue panel must become visible")
	_check(backdrop != null and backdrop.visible, "catalogue backdrop must become visible")
	_check(bool(world.call("is_player_input_locked")), "catalogue must hold movement while selecting a build")
	_check(place_button != null and place_button.text.contains("BLUEPRINT"), "place control must reflect blueprint state")

	world.call("_select_build_catalog_structure", "workshop")
	_check(str(world.get("placement_structure_id")) == "workshop", "catalogue selection must update the existing placement authority")
	var session := world.get("session") as Node
	var workshop_unlocked := session != null and bool(session.call("has_structure_blueprint", "workshop"))
	_check(place_button == null or place_button.disabled == not workshop_unlocked, "place control must follow the authoritative blueprint unlock")
	if workshop_unlocked:
		world.call("_build_catalog_place_selected")
		_check(bool(world.get("placement_mode")), "placing from the catalogue must enter the existing measured placement mode")
		_check(not bool(world.get("build_catalog_open")), "catalogue must close when placement begins")
		world.call("_toggle_structure_placement")

	world.queue_free()
	if failures.is_empty():
		print("BUILD_CATALOG_TESTS_PASS checks=%d" % checks)
		quit(0)
	else:
		print("BUILD_CATALOG_TESTS_FAIL failures=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  ", failure)
		quit(1)

func _wait_frames(count: int) -> void:
	for _index in count:
		await process_frame
