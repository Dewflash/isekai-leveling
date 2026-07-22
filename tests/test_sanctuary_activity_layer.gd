extends SceneTree

const MainScene := preload("res://main.tscn")
const AssetCatalog := preload("res://scripts/sanctuary_asset_catalog.gd")
const ContentRegistry := preload("res://scripts/content_registry.gd")

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("SANCTUARY_ACTIVITY_FAIL: " + message)

func _run() -> void:
	var ids := {}
	for socket_value in AssetCatalog.LIVED_IN_ACTIVITY_SOCKETS:
		_check(socket_value is Dictionary, "activity socket must be a Dictionary")
		if not socket_value is Dictionary:
			continue
		var socket := socket_value as Dictionary
		var socket_id := str(socket.get("id", ""))
		var kind := str(socket.get("kind", ""))
		var position: Array = socket.get("position", [])
		_check(not socket_id.is_empty(), "activity socket id is required")
		_check(not ids.has(socket_id), "activity socket ids must be unique: %s" % socket_id)
		ids[socket_id] = true
		_check(kind in ["scaffold", "workshop", "tent", "market", "garden", "well"], "activity socket %s uses an authored prop kind" % socket_id)
		_check(position.size() == 3, "activity socket %s needs a world position" % socket_id)
		_check(float(socket.get("world_size", 0.0)) > 0.0, "activity socket %s needs a measured presentation size" % socket_id)
		_check(bool(socket.get("animate", false)), "activity socket %s must carry ambient motion" % socket_id)

	var world := MainScene.instantiate()
	root.add_child(world)
	await _wait_frames(12)
	var style := world.get_node_or_null("Sanctuary/SanctuaryIllustratedStyle") as Node3D
	var activity := style.get_node_or_null("LivedInActivityLayer") as Node3D if style != null else null
	var build_field := style.get_node_or_null("PlayerDirectedBuildField") as MeshInstance3D if style != null else null
	_check(style != null, "Sanctuary presentation style must exist")
	_check(activity != null and activity.visible, "lived-in activity layer must be visible on a fresh Sanctuary")
	_check(build_field != null, "player-directed build field must remain visible")
	var field_rect := Rect2()
	if build_field != null:
		# Derive the live reserve envelope from the presentation node itself so the
		# test follows the same authored dimensions as the running scene.
		field_rect = Rect2(
			Vector2(build_field.global_position.x - build_field.scale.x, build_field.global_position.z - build_field.scale.z),
			Vector2(build_field.scale.x * 2.0, build_field.scale.z * 2.0)
		)
	var framing_rects: Array = AssetCatalog.framing_placement_rects()
	if activity != null:
		var art_count := 0
		var shadow_count := 0
		for child_value in activity.get_children():
			var child := child_value as Node3D
			if child == null:
				continue
			_check(not child is StaticBody3D, "activity layer must never create a physics body")
			_check(bool(child.get_meta("presentation_only", false)), "activity child %s must be presentation-only" % child.name)
			_check(int(child.get_meta("collision_layer", 0)) == 0, "activity child %s must declare collision layer 0" % child.name)
			_check(not bool(child.get_meta("occupies_build_cells", false)), "activity child %s must not claim build cells" % child.name)
			if str(child.name).begins_with("ActivitySocketArt_"):
				art_count += 1
				_check(child is Sprite3D, "activity art %s must use measured Sprite3D presentation" % child.name)
				_check(not str(child.get_meta("asset_id", "")).is_empty(), "activity art %s must expose an asset id" % child.name)
				var footprint_value: Variant = child.get_meta("visual_footprint", [])
				if footprint_value is Array and (footprint_value as Array).size() >= 2:
					var footprint := footprint_value as Array
					var activity_rect := Rect2(
						Vector2(child.global_position.x - float(footprint[0]) * 0.5, child.global_position.z - float(footprint[1]) * 0.5),
						Vector2(float(footprint[0]), float(footprint[1]))
					)
					_check(not field_rect.grow(0.02).intersects(activity_rect), "%s must not overlap the player-directed build field" % child.name)
					for framing_value in framing_rects:
						if framing_value is Dictionary:
							var framing_rect: Rect2 = (framing_value as Dictionary).get("rect", Rect2())
							_check(not framing_rect.grow(0.02).intersects(activity_rect), "%s must clear measured framing obstacle %s" % [child.name, str((framing_value as Dictionary).get("id", ""))])
					for route_value in ContentRegistry.ROUTE_RESERVED_RECTS:
						if route_value is Array and (route_value as Array).size() >= 4:
							var route := route_value as Array
							var route_rect := Rect2(
								Vector2(float(route[0]), float(route[1])),
								Vector2(float(route[2]) - float(route[0]), float(route[3]) - float(route[1]))
							)
							_check(not route_rect.grow(0.02).intersects(activity_rect), "%s must clear route reservation %s" % [child.name, str(route_rect)])
			if str(child.name).begins_with("ActivitySocketShadow_"):
				shadow_count += 1
		_check(art_count == AssetCatalog.LIVED_IN_ACTIVITY_SOCKETS.size(), "every activity socket must produce one visible art root")
		_check(shadow_count == art_count, "every activity socket art root must have one contact shadow")

	world.queue_free()
	if failures.is_empty():
		print("SANCTUARY_ACTIVITY_LAYER_PASS checks=%d sockets=%d" % [checks, AssetCatalog.LIVED_IN_ACTIVITY_SOCKETS.size()])
		quit(0)
	else:
		print("SANCTUARY_ACTIVITY_LAYER_FAIL failures=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  ", failure)
		quit(1)

func _wait_frames(count: int) -> void:
	for _index in count:
		await process_frame
