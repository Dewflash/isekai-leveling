class_name ProdewtySanctuaryAssetMeasurement
extends RefCounted

## Runtime measurement for imported Sanctuary assets.
##
## A structure's grid claim still comes from ContentRegistry. This helper owns
## only the physical envelope of the imported model: it measures every
## MeshInstance3D in the source scene, fits that measured envelope into the
## claim without distorting the model, and returns the transform/collision
## data used by both presentation and physics. No hand-entered per-asset scale
## or offset is allowed to replace this result.

const ContentRegistry := preload("res://scripts/content_registry.gd")
const AssetCatalog := preload("res://scripts/sanctuary_asset_catalog.gd")
const FIT_MARGIN_METERS := 0.14

static var _raw_cache: Dictionary = {}
static var _fit_cache: Dictionary = {}

static func measure_scene(scene_path: String) -> Dictionary:
	if scene_path.is_empty():
		return _invalid_measurement(scene_path, "empty_source_path")
	if _raw_cache.has(scene_path):
		return (_raw_cache[scene_path] as Dictionary).duplicate(true)
	var scene := load(scene_path) as PackedScene
	if scene == null:
		var missing := _invalid_measurement(scene_path, "scene_load_failed")
		_raw_cache[scene_path] = missing
		return missing.duplicate(true)
	var instance := scene.instantiate() as Node3D
	if instance == null:
		var invalid := _invalid_measurement(scene_path, "scene_instantiate_failed")
		_raw_cache[scene_path] = invalid
		return invalid.duplicate(true)
	var measurement := _measure_node(instance, Transform3D.IDENTITY)
	instance.free()
	if not bool(measurement.get("valid", false)):
		measurement["source_path"] = scene_path
		_raw_cache[scene_path] = measurement.duplicate(true)
		return measurement.duplicate(true)
	measurement["source_path"] = scene_path
	measurement["raw_bounds"] = measurement.get("bounds", AABB())
	measurement.erase("bounds")
	_raw_cache[scene_path] = measurement.duplicate(true)
	return measurement.duplicate(true)

static func structure_measurement(kind: String, footprint: Vector2i) -> Dictionary:
	var definition := AssetCatalog.structure_definition(kind)
	var scene_path := str(definition.get("source_asset", ""))
	var cache_key := "%s|%d|%d" % [scene_path, footprint.x, footprint.y]
	if _fit_cache.has(cache_key):
		return (_fit_cache[cache_key] as Dictionary).duplicate(true)
	var raw := measure_scene(scene_path)
	if not bool(raw.get("valid", false)):
		var invalid := _invalid_measurement(scene_path, str(raw.get("reason", "invalid_source")))
		invalid["kind"] = kind
		invalid["footprint"] = [footprint.x, footprint.y]
		_fit_cache[cache_key] = invalid.duplicate(true)
		return invalid.duplicate(true)
	var raw_bounds: AABB = raw.get("raw_bounds", AABB())
	var raw_size := raw_bounds.size
	# The border is a grid-placement clearance, shared by every measured source;
	# it is not an asset-specific collision dimension.
	var fit_margin := FIT_MARGIN_METERS
	var target_width := maxf(0.25, float(footprint.x) - fit_margin * 2.0)
	var target_depth := maxf(0.25, float(footprint.y) - fit_margin * 2.0)
	var horizontal_scale := minf(target_width / maxf(raw_size.x, 0.001), target_depth / maxf(raw_size.z, 0.001))
	var scale := maxf(horizontal_scale, 0.001)
	var fitted_size := raw_size * scale
	# The translated origin is the measured ground contact and horizontal centre.
	# It is computed from the imported geometry, never hand-authored per asset.
	var fitted_min := raw_bounds.position * scale
	var fitted_max := raw_bounds.end * scale
	var local_offset := Vector3(
		-(fitted_min.x + fitted_max.x) * 0.5,
		-fitted_min.y,
		-(fitted_min.z + fitted_max.z) * 0.5
	)
	var fitted_bounds := AABB(fitted_min + local_offset, fitted_size)
	var result := {
		"valid": true,
		"kind": kind,
		"source_path": scene_path,
		"raw_bounds": raw_bounds,
		"raw_size": raw_size,
		"mesh_count": int(raw.get("mesh_count", 0)),
		"fit_scale": scale,
		"fit_offset": local_offset,
		"fitted_bounds": fitted_bounds,
		"fitted_size": fitted_bounds.size,
		"footprint": [footprint.x, footprint.y],
		"horizontal_fit_ratio": Vector2(fitted_bounds.size.x / target_width, fitted_bounds.size.z / target_depth),
	}
	_fit_cache[cache_key] = result.duplicate(true)
	return result.duplicate(true)

static func structure_collision_components(kind: String, footprint: Vector2i) -> Array:
	var measured := structure_measurement(kind, footprint)
	if not bool(measured.get("valid", false)):
		return []
	var bounds: AABB = measured.get("fitted_bounds", AABB())
	var definition := AssetCatalog.structure_definition(kind)
	var zones: Array = definition.get("access_zones", [])
	var door := _first_zone(zones, "door")
	var service := _first_zone(zones, "service")
	var wall_thickness := clampf(minf(bounds.size.x, bounds.size.z) * 0.035, 0.07, 0.18)
	var floor_height := maxf(bounds.size.y, 0.25)
	var components: Array = []
	# The measured footprint is the outside edge of the source geometry. A shell
	# follows that edge and leaves only the measured semantic access opening open.
	components.append(_box_component("rear_wall", Vector3(
		(bounds.position.x + bounds.end.x) * 0.5,
		floor_height * 0.5,
		bounds.position.z + wall_thickness * 0.5
	), Vector3(bounds.size.x, floor_height, wall_thickness)))
	components.append(_box_component("left_wall", Vector3(
		bounds.position.x + wall_thickness * 0.5,
		floor_height * 0.5,
		(bounds.position.z + bounds.end.z) * 0.5
	), Vector3(wall_thickness, floor_height, maxf(wall_thickness, bounds.size.z - wall_thickness * 2.0))))
	components.append(_box_component("right_wall", Vector3(
		bounds.end.x - wall_thickness * 0.5,
		floor_height * 0.5,
		(bounds.position.z + bounds.end.z) * 0.5
	), Vector3(wall_thickness, floor_height, maxf(wall_thickness, bounds.size.z - wall_thickness * 2.0))))
	var front_segments := _front_segments(bounds, door, wall_thickness, floor_height)
	for segment in front_segments:
		components.append(segment)
	# A side service fixture is not automatically treated as a wall. If the
	# measured model exposes a loading/feeding object, add only its own measured
	# occupied sub-envelope when a semantic descriptor explicitly marks it.
	var service_rect := _zone_rect(service)
	if service_rect.has_area() and service_rect.position.x >= bounds.position.x and service_rect.end.x <= bounds.end.x:
		# Keep the service metadata available for QA without inventing an extra
		# blocker; the shell already encloses the source boundary.
		pass
	return components

## Measure a runtime-created or runtime-instanced visual in its current local
## coordinate space. The result is deliberately based on MeshInstance3D
## geometry, not on a node's authored scale or a duplicate collision constant.
## Hidden fallback art is ignored by default so the collider follows the asset
## the player actually sees.
static func measure_runtime_node(root: Node, name_tokens: Array = [], include_hidden := false) -> Dictionary:
	if root == null:
		return _invalid_measurement("", "null_runtime_root")
	var measurement := _measure_node_filtered(root, Transform3D.IDENTITY, name_tokens, include_hidden)
	if not bool(measurement.get("valid", false)):
		return _invalid_measurement(str(root.name), "runtime_mesh_not_found")
	measurement["source_path"] = str(root.get_meta("source_asset", root.get_meta("asset_id", root.name)))
	measurement["measurement_source"] = "runtime_visible_mesh_bounds"
	return measurement

## Same as measure_runtime_node, but excludes the root's transform. This is
## used when a visible imported scene and its collision body are siblings: both
## receive the same root transform, so the measured child envelope must remain
## in authored local metres.
static func measure_runtime_node_local(root: Node, name_tokens: Array = [], include_hidden := false) -> Dictionary:
	if root == null:
		return _invalid_measurement("", "null_runtime_root")
	var measurement := _measure_node_filtered(root, Transform3D.IDENTITY, name_tokens, include_hidden, true)
	if not bool(measurement.get("valid", false)):
		return _invalid_measurement(str(root.name), "runtime_mesh_not_found")
	measurement["source_path"] = str(root.get_meta("source_asset", root.get_meta("asset_id", root.name)))
	measurement["measurement_source"] = "runtime_visible_mesh_bounds_local"
	return measurement

static func _front_segments(bounds: AABB, door: Dictionary, wall_thickness: float, height: float) -> Array:
	var front_z := bounds.end.z - wall_thickness * 0.5
	var door_rect := _zone_rect(door)
	if not door_rect.has_area():
		return [_box_component("front_wall", Vector3(
			(bounds.position.x + bounds.end.x) * 0.5, height * 0.5, front_z
		), Vector3(bounds.size.x, height, wall_thickness))]
	var door_left := clampf(door_rect.position.x, bounds.position.x, bounds.end.x)
	var door_right := clampf(door_rect.end.x, bounds.position.x, bounds.end.x)
	var result: Array = []
	if door_left > bounds.position.x + wall_thickness:
		result.append(_box_component("front_wall_left", Vector3(
			(bounds.position.x + door_left) * 0.5, height * 0.5, front_z
		), Vector3(door_left - bounds.position.x, height, wall_thickness)))
	if door_right < bounds.end.x - wall_thickness:
		result.append(_box_component("front_wall_right", Vector3(
			(door_right + bounds.end.x) * 0.5, height * 0.5, front_z
		), Vector3(bounds.end.x - door_right, height, wall_thickness)))
	return result

static func _first_zone(zones: Array, kind: String) -> Dictionary:
	for value in zones:
		if value is Dictionary and str((value as Dictionary).get("kind", "")) == kind:
			return (value as Dictionary).duplicate(true)
	return {}

static func _zone_rect(zone: Dictionary) -> Rect2:
	if zone.is_empty():
		return Rect2()
	var center_value: Array = zone.get("center", [0.0, 0.0, 0.0])
	var size_value: Array = zone.get("size", [0.0, 0.0])
	if center_value.size() < 3 or size_value.size() < 2:
		return Rect2()
	return Rect2(
		Vector2(float(center_value[0]), float(center_value[2])) - Vector2(float(size_value[0]), float(size_value[1])) * 0.5,
		Vector2(float(size_value[0]), float(size_value[1])
	))

static func _box_component(id: String, center: Vector3, size: Vector3) -> Dictionary:
	return {
		"id": id,
		"shape": "box",
		"center": [center.x, center.y, center.z],
		"size": [maxf(size.x, 0.01), maxf(size.y, 0.01), maxf(size.z, 0.01)],
		"blocks_movement": true,
		"measurement_source": "imported_mesh_bounds",
	}

static func _measure_node(node: Node, parent_transform: Transform3D) -> Dictionary:
	return _measure_node_filtered(node, parent_transform, [], true)

static func _measure_node_filtered(
	node: Node,
	parent_transform: Transform3D,
	name_tokens: Array,
	include_hidden: bool,
	ignore_node_transform := false,
	name_scope := false
) -> Dictionary:
	if not include_hidden and node is Node3D and not (node as Node3D).visible:
		return {"valid": false, "mesh_count": 0}
	var transform := parent_transform
	if node is Node3D and not ignore_node_transform:
		transform = parent_transform * (node as Node3D).transform
	var result := AABB()
	var has_bounds := false
	var mesh_count := 0
	var node_matches := name_scope or name_tokens.is_empty()
	if not node_matches:
		var lower_name := str(node.name).to_lower()
		for token in name_tokens:
			if lower_name.contains(str(token).to_lower()):
				node_matches = true
				break
	var mesh_bounds := AABB()
	var mesh_has_bounds := false
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var mesh := (node as MeshInstance3D).mesh
		if name_tokens.is_empty() or node_matches:
			# A matching node name selects that mesh as a whole. This keeps a
			# semantic sub-asset such as Trunk deterministic even when its
			# material slots change between imports.
			mesh_bounds = mesh.get_aabb()
			mesh_has_bounds = mesh_bounds.size.x > 0.0 and mesh_bounds.size.y > 0.0 and mesh_bounds.size.z > 0.0
		else:
			# If the node name does not identify the sub-asset, material names are
			# the measured fallback for imported scenes with shared mesh nodes.
			var surface_measurement := _mesh_surface_bounds(mesh, name_tokens)
			mesh_has_bounds = bool(surface_measurement.get("valid", false))
			if mesh_has_bounds:
				mesh_bounds = surface_measurement.get("bounds", AABB())
	if mesh_has_bounds:
		for corner in _aabb_corners(mesh_bounds):
			var point: Vector3 = transform * corner
			if not has_bounds:
				result = AABB(point, Vector3.ZERO)
				has_bounds = true
			else:
				result = result.expand(point)
		mesh_count += 1
	for child in node.get_children():
		var child_result := _measure_node_filtered(child, transform, name_tokens, include_hidden, false, node_matches and not name_tokens.is_empty())
		if bool(child_result.get("valid", false)):
			var child_bounds: AABB = child_result.get("bounds", AABB())
			if not has_bounds:
				result = child_bounds
				has_bounds = true
			else:
				result = result.merge(child_bounds)
			mesh_count += int(child_result.get("mesh_count", 0))
	return {"valid": has_bounds and result.size.x > 0.0 and result.size.y > 0.0 and result.size.z > 0.0, "bounds": result, "mesh_count": mesh_count}

static func _mesh_surface_bounds(mesh: Mesh, name_tokens: Array) -> Dictionary:
	if mesh == null:
		return {"valid": false}
	if name_tokens.is_empty():
		var complete_bounds := mesh.get_aabb()
		return {"valid": complete_bounds.size.x > 0.0 and complete_bounds.size.y > 0.0 and complete_bounds.size.z > 0.0, "bounds": complete_bounds}
	var result := AABB()
	var has_bounds := false
	for surface_index in mesh.get_surface_count():
		var material := mesh.surface_get_material(surface_index)
		var material_name := str(material.resource_name).to_lower() if material != null else ""
		var matches := false
		for token in name_tokens:
			if material_name.contains(str(token).to_lower()):
				matches = true
				break
		if not matches:
			continue
		var arrays := mesh.surface_get_arrays(surface_index)
		if arrays.is_empty() or arrays.size() <= Mesh.ARRAY_VERTEX:
			continue
		var vertices: Variant = arrays[Mesh.ARRAY_VERTEX]
		if not vertices is PackedVector3Array:
			continue
		for vertex in vertices:
			var point := vertex as Vector3
			if not has_bounds:
				result = AABB(point, Vector3.ZERO)
				has_bounds = true
			else:
				result = result.expand(point)
	return {"valid": has_bounds and result.size.x > 0.0 and result.size.y > 0.0 and result.size.z > 0.0, "bounds": result}

static func _aabb_corners(bounds: AABB) -> Array[Vector3]:
	return [
		Vector3(bounds.position.x, bounds.position.y, bounds.position.z),
		Vector3(bounds.end.x, bounds.position.y, bounds.position.z),
		Vector3(bounds.position.x, bounds.end.y, bounds.position.z),
		Vector3(bounds.position.x, bounds.position.y, bounds.end.z),
		Vector3(bounds.end.x, bounds.end.y, bounds.position.z),
		Vector3(bounds.end.x, bounds.position.y, bounds.end.z),
		Vector3(bounds.position.x, bounds.end.y, bounds.end.z),
		Vector3(bounds.end.x, bounds.end.y, bounds.end.z),
	]

static func _invalid_measurement(scene_path: String, reason: String) -> Dictionary:
	return {"valid": false, "source_path": scene_path, "reason": reason, "mesh_count": 0}
