extends SceneTree

const MainScene = preload("res://main.tscn")
const ContentRegistry = preload("res://scripts/content_registry.gd")
const SettlementGrid = preload("res://scripts/settlement_grid.gd")

var failures: Array[String] = []
var checks := 0

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("STRUCTURE_MOVE_VISUAL_FAIL: " + message)

func _find_clear_cell(session: Node, kind: String, rotation := 0, ignored_id := "", avoided := Vector2i(999, 999)) -> Vector2i:
	for x in range(-22, 23):
		for z in range(-18, 19):
			if Vector2i(x, z) == avoided:
				continue
			if bool(session.call("can_place_structure", kind, [x, z], rotation, ignored_id)):
				return Vector2i(x, z)
	return Vector2i(999, 999)

func _finish(world: Node) -> void:
	if is_instance_valid(world):
		world.queue_free()
	if failures.is_empty():
		print("STRUCTURE_MOVE_VISUAL_TESTS_PASS checks=%d" % checks)
		quit(0)
		return
	print("STRUCTURE_MOVE_VISUAL_TESTS_FAIL count=%d checks=%d" % [failures.size(), checks])
	for index in failures.size():
		print("  %02d. %s" % [index + 1, failures[index]])
	quit(1)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := MainScene.instantiate()
	root.add_child(world)
	await process_frame
	var session := world.get("session") as Node
	_check(session != null, "Main must expose the authoritative session")
	if session == null:
		_finish(world)
		return
	var kind := "storage_shed"
	var requirement := str(ContentRegistry.structure_definition(kind).get("requires_blueprint", ""))
	if not requirement.is_empty() and not (session.get("blueprints") as Array).has(requirement):
		(session.get("blueprints") as Array).append(requirement)
	session.set("structures", {})
	var origin := _find_clear_cell(session, kind)
	_check(origin.x != 999, "visual move test must find a clear origin")
	if origin.x == 999:
		_finish(world)
		return
	var placed: Dictionary = session.call("place_structure", kind, [origin.x, origin.y], 0)
	_check(not placed.is_empty(), "visual move test must create a structure through the session")
	if placed.is_empty():
		_finish(world)
		return
	placed["state"] = "operational"
	var instance_id := str(placed.get("id", ""))
	session.get("structures")[instance_id] = placed
	world.call("_spawn_structure_visual", instance_id, placed)
	await process_frame
	var visual := (world.get("settlement_visuals") as Dictionary).get(instance_id) as Node3D
	_check(visual != null and is_instance_valid(visual), "move test must have a registered visual")
	if visual == null:
		_finish(world)
		return
	var body := visual.get_node_or_null("StructureCollisionBody") as StaticBody3D
	_check(body != null, "moved visual must expose its measured collision body")
	_check(body != null and body.collision_layer != 0, "operational structure collision must start enabled")
	var collision_shapes := body.find_children("*", "CollisionShape3D", true, false) if body != null else []
	_check(not collision_shapes.is_empty(), "moved visual must expose measured collision shapes")
	world.call("_begin_structure_move", visual)
	await process_frame
	_check(str(world.get("moving_structure_id")) == instance_id, "move mode must retain the authoritative instance id")
	_check(not visual.visible, "the old building must hide while its measured footprint is previewed")
	_check(body.collision_layer == 0 and body.collision_mask == 0, "the old building must not block the player during move preview")
	for collision_value in collision_shapes:
		_check((collision_value as CollisionShape3D).disabled, "all measured collision shapes must disable during move preview")
	world.call("_cancel_structure_placement", "test cancellation")
	await process_frame
	_check(str(world.get("moving_structure_id")) == "", "cancellation must clear move mode")
	_check(visual.visible, "cancellation must restore the original building visual")
	_check(body.collision_layer != 0 and body.collision_mask != 0, "cancellation must restore the original collision layers")
	for collision_value in collision_shapes:
		_check(not (collision_value as CollisionShape3D).disabled, "cancellation must restore all measured collision shapes")
	var restored: Dictionary = session.get("structures").get(instance_id, {})
	_check(restored.get("cell", []) == [origin.x, origin.y], "cancellation must leave the saved cell unchanged")
	_check(int(restored.get("rotation", -1)) == 0, "cancellation must leave the saved rotation unchanged")
	# Rebuild the visual from the authoritative moved record. The focused session
	# test covers the durable transaction; this contract covers its visual handoff.
	var target := _find_clear_cell(session, kind, 1, instance_id, origin)
	_check(target.x != 999, "confirm path must find a clear rotated destination")
	if target.x != 999:
		var moved: Dictionary = session.call("move_structure", instance_id, [target.x, target.y], 1)
		_check(not moved.is_empty(), "visual handoff must receive an authoritative moved record")
		world.call("_spawn_structure_visual", instance_id, moved)
		await process_frame
		var committed: Dictionary = session.get("structures").get(instance_id, {})
		_check(committed.get("cell", []) == [target.x, target.y], "visual handoff must preserve the new cell")
		_check(int(committed.get("rotation", -1)) == 1, "visual handoff must preserve the new rotation")
		var committed_visual := (world.get("settlement_visuals") as Dictionary).get(instance_id) as Node3D
		_check(committed_visual != null and is_instance_valid(committed_visual), "visual handoff must respawn the same visual instance")
		if committed_visual != null:
			var expected_center := SettlementGrid.footprint_center_to_world(target, Vector2i(4, 5))
			_check(committed_visual.global_position.distance_to(expected_center) <= 0.01, "moved visual must use the rotated measured footprint center")
			var committed_body := committed_visual.get_node_or_null("StructureCollisionBody") as StaticBody3D
			_check(committed_body != null and committed_body.collision_layer != 0, "moved visual must restore measured collision")
	_finish(world)
