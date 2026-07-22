extends SceneTree

## Display-backed proof for the Workshop's visual progression. Every frame is
## produced by Main's real entry path and the persisted interior layout; this
## script does not build a second mock room or substitute hitboxes.

const MainScene := preload("res://main.tscn")
const ContentRegistry := preload("res://scripts/content_registry.gd")
const CAPTURE_SIZE := Vector2i(1280, 720)
const SAVE_SLOT := "qa_workshop_fitout_stages_capture"
const STRUCTURE_ID := "capture_workshop_fitout_001"

var viewport: SubViewport
var world: Node
var output_dir := ""

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", SAVE_SLOT)
	output_dir = OS.get_environment("WORKSHOP_FITOUT_CAPTURE_DIR")
	if output_dir.is_empty():
		output_dir = "user://workshop-fitout-stage-captures"
	DirAccess.make_dir_recursive_absolute(output_dir)
	viewport = SubViewport.new()
	viewport.name = "WorkshopFitoutCaptureViewport"
	viewport.size = CAPTURE_SIZE
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	root.add_child(viewport)
	world = MainScene.instantiate()
	viewport.add_child(world)
	await _wait_frames(45)
	var session := world.get("session") as Node
	var player := world.get("player") as CharacterBody3D
	if session == null or player == null:
		push_error("WORKSHOP_FITOUT_CAPTURE_FAIL: Main did not expose session/player")
		quit(1)
		return
	var structure_data := {
		"id": STRUCTURE_ID,
		"kind": "workshop",
		"cell": [4, -6],
		"rotation": 0,
		"state": "operational",
		"remaining_hours": 0.0,
		"total_hours": 24.0,
		"delivered_materials": {"wood": 12, "stone": 8, "plank": 4},
	}
	session.set("structures", {STRUCTURE_ID: structure_data})
	world.call("_spawn_structure_visual", STRUCTURE_ID, structure_data)
	await _wait_frames(8)
	var visuals: Dictionary = world.get("settlement_visuals")
	var structure := visuals.get(STRUCTURE_ID) as Node3D
	if structure == null:
		push_error("WORKSHOP_FITOUT_CAPTURE_FAIL: workshop visual missing")
		quit(1)
		return
	# Use the measured front-door access zone rather than assuming the Workshop's
	# authored origin or rotation. This keeps the capture proof aligned with the
	# same entry contract used by gameplay and the runtime tests.
	var door_zone: Dictionary = world.call("_world_access_zone", structure, "door")
	var door_world: Vector3 = door_zone.get("world_center", Vector3.ZERO)
	var door_outward: Vector3 = door_zone.get("world_facing", Vector3(0.0, 0.0, 1.0))
	player.global_position = door_world + door_outward * 0.90
	player.global_position.y = 1.0
	session.set("interior_stations", {STRUCTURE_ID: {}})
	world.call("_enter_building_interior", structure)
	await _wait_seconds(0.90)
	var toast := world.get("toast_label") as Label
	if toast != null:
		toast.visible = false
	await _wait_frames(8)
	if DisplayServer.get_name().to_lower() == "headless" or viewport.get_texture() == null:
		print("WORKSHOP_FITOUT_CAPTURE_UNAVAILABLE: use --display-driver macos for a pixel-backed capture")
		quit()
		return
	await _save_stage("01_empty_shell")
	var interior := world.get("building_interior") as Node3D
	if interior == null:
		push_error("WORKSHOP_FITOUT_CAPTURE_FAIL: interior controller missing")
		quit(1)
		return
	var blueprint_stations := _place_legal_stations(session)
	if blueprint_stations.is_empty():
		push_error("WORKSHOP_FITOUT_CAPTURE_FAIL: legal station placement produced no records")
		quit(1)
		return
	interior.call("sync_persisted_stations", blueprint_stations)
	await _wait_seconds(0.30)
	await _save_stage("02_legal_blueprints")
	if not _deliver_all_station_materials(session, blueprint_stations):
		push_error("WORKSHOP_FITOUT_CAPTURE_FAIL: legal material delivery failed")
		quit(1)
		return
	var building_stations: Dictionary = session.get("interior_stations").get(STRUCTURE_ID, {})
	interior.call("sync_persisted_stations", building_stations)
	await _wait_seconds(0.30)
	await _save_stage("03_materials_and_scaffolds")
	if not bool(session.call("advance_day")):
		push_error("WORKSHOP_FITOUT_CAPTURE_FAIL: legal construction advance failed")
		quit(1)
		return
	var operational_stations: Dictionary = session.get("interior_stations").get(STRUCTURE_ID, {})
	interior.call("sync_persisted_stations", operational_stations)
	await _wait_seconds(0.70)
	await _save_stage("04_operational_fitout")
	print("WORKSHOP_FITOUT_CAPTURE_PASS ", output_dir)
	quit()

func _place_legal_stations(session: Node) -> Dictionary:
	session.set("interior_stations", {STRUCTURE_ID: {}})
	# The interior is fitted from the placed Workshop's measured exterior, so its
	# usable cell rectangle is not guaranteed to match the fallback 8.2x6.2 room.
	# Query the same GameSession validator used by the live placement cursor and
	# choose the first legal cell for each required station. This keeps the proof
	# valid as authored building proportions evolve and prevents a stale capture
	# coordinate from masquerading as a gameplay failure.
	for station_kind in ["furnace_left", "furnace_right", "workbench", "anvil", "storage"]:
		var placed := false
		for x in range(-12, 13):
			for z in range(-12, 13):
				if not bool(session.call("can_place_interior_station", STRUCTURE_ID, station_kind, [x, z], 0, [])):
					continue
				var record: Dictionary = session.call("place_interior_station", STRUCTURE_ID, station_kind, [x, z], 0, [])
				if record.is_empty():
					continue
				placed = true
				break
			if placed:
				break
		if not placed:
			push_error("WORKSHOP_FITOUT_CAPTURE_FAIL: no legal measured-room placement for %s" % station_kind)
			return {}
	return session.get("interior_stations").get(STRUCTURE_ID, {}).duplicate(true)

func _deliver_all_station_materials(session: Node, blueprint_stations: Dictionary) -> bool:
	var inventory: Dictionary = session.get("inventory")
	for material_id in ["wood", "stone", "plank"]:
		inventory[material_id] = maxi(50, int(inventory.get(material_id, 0)))
	session.set("inventory", inventory)
	for station_id in blueprint_stations:
		var record: Dictionary = blueprint_stations.get(station_id, {})
		var definition := ContentRegistry.interior_station_definition(str(record.get("kind", "")))
		for material_id in definition.get("cost", {}):
			var cost := int(definition["cost"][material_id])
			var updated: Dictionary = session.call("deliver_interior_station_material", STRUCTURE_ID, str(station_id), str(material_id), cost)
			if updated.is_empty():
				return false
	return true

func _save_stage(stage_id: String) -> void:
	var image := viewport.get_texture().get_image()
	var path := output_dir.path_join(stage_id + ".png")
	var result := image.save_png(path)
	if result != OK:
		push_error("WORKSHOP_FITOUT_CAPTURE_FAIL: could not write " + path)
		quit(1)
	return
	print("WORKSHOP_FITOUT_STAGE_PASS ", stage_id, " ", path, " ", image.get_width(), "x", image.get_height())

func _wait_frames(count: int) -> void:
	for _index in count:
		await process_frame

func _wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout
