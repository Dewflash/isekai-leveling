extends SceneTree

const SessionScript = preload("res://scripts/game_session.gd")
const ContentRegistry = preload("res://scripts/content_registry.gd")

var failures: Array[String] = []
var checks := 0

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("STRUCTURE_MOVE_FAIL: " + message)

func _find_clear_cell(session: Node, kind: String, ignored_id := "", avoided := Vector2i(999, 999)) -> Vector2i:
	for x in range(-22, 23):
		for z in range(-18, 19):
			if Vector2i(x, z) == avoided:
				continue
			if bool(session.call("can_place_structure", kind, [x, z], 0, ignored_id)):
				return Vector2i(x, z)
	return Vector2i(999, 999)

func _find_blocked_cell(session: Node, kind: String) -> Vector2i:
	for x in range(-22, 23):
		for z in range(-18, 19):
			if not bool(session.call("can_place_structure", kind, [x, z], 0)):
				return Vector2i(x, z)
	return Vector2i(999, 999)

func _finish() -> void:
	if failures.is_empty():
		print("STRUCTURE_MOVE_TESTS_PASS checks=%d" % checks)
		quit(0)
		return
	print("STRUCTURE_MOVE_TESTS_FAIL count=%d checks=%d" % [failures.size(), checks])
	for index in failures.size():
		print("  %02d. %s" % [index + 1, failures[index]])
	quit(1)

func _init() -> void:
	var session := SessionScript.new()
	session.save_slot = "qa_structure_move"
	root.add_child(session)
	var shed_definition: Dictionary = ContentRegistry.structure_definition("storage_shed")
	var requirement := str(shed_definition.get("requires_blueprint", ""))
	if not requirement.is_empty() and not (session.get("blueprints") as Array).has(requirement):
		(session.get("blueprints") as Array).append(requirement)
	var origin := _find_clear_cell(session, "storage_shed")
	_check(origin.x != 999, "must find a clear authored origin for the storage shed")
	if origin.x == 999:
		_finish()
		return
	var placed: Dictionary = session.call("place_structure", "storage_shed", [origin.x, origin.y], 0)
	_check(not placed.is_empty(), "initial structure must be placed through the session")
	if placed.is_empty():
		_finish()
		return
	var instance_id := str(placed.get("id", ""))
	var destination := _find_clear_cell(session, "storage_shed", instance_id, origin)
	_check(destination.x != 999 and destination != origin, "move preview must find a distinct clear destination")
	var moved: Dictionary = session.call("move_structure", instance_id, [destination.x, destination.y], 1)
	_check(not moved.is_empty(), "valid relocation must commit")
	_check(Vector2i(int(moved.get("cell", [999, 999])[0]), int(moved.get("cell", [999, 999])[1])) == destination, "relocation must persist the new grid origin")
	_check(int(moved.get("rotation", -1)) == 1, "relocation must persist the requested quarter-turn")
	_check(bool(session.call("can_place_structure", "storage_shed", [origin.x, origin.y], 0, instance_id)), "old origin must become available when the moved instance is ignored")
	var blocked := _find_blocked_cell(session, "storage_shed")
	_check(blocked.x != 999, "test must find an authored blocked cell")
	var rejected: Dictionary = session.call("move_structure", instance_id, [blocked.x, blocked.y], 2)
	_check(rejected.is_empty(), "blocked relocation must be rejected")
	var after_reject: Dictionary = session.get("structures").get(instance_id, {})
	_check(after_reject.get("cell", []) == moved.get("cell", []), "blocked relocation must leave the saved origin unchanged")
	_check(int(after_reject.get("rotation", -1)) == int(moved.get("rotation", -1)), "blocked relocation must leave the saved rotation unchanged")
	session.queue_free()
	_finish()
