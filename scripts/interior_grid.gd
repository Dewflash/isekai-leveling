class_name ProdewtyInteriorGrid
extends RefCounted

## The Workshop fit-out grid is a physical contract, not a second arbitrary
## coordinate system. A saved station stores the minimum cell of its measured
## footprint; every preview, occupancy check, local position, and collider
## anchor is derived from that same cell rectangle.

const DEFAULT_CELL_SIZE := 1.0
const DEFAULT_WALL_CLEARANCE := 0.45
const DEFAULT_DOOR_CLEARANCE_DEPTH := 0.85

static func rotated_footprint(base_footprint: Vector2i, rotation_quarter_turns: int) -> Vector2i:
	return base_footprint if posmod(rotation_quarter_turns, 2) == 0 else Vector2i(base_footprint.y, base_footprint.x)

static func cells_for(origin: Vector2i, footprint: Vector2i) -> Array:
	var cells: Array = []
	if footprint.x <= 0 or footprint.y <= 0:
		return cells
	for x in range(origin.x, origin.x + footprint.x):
		for z in range(origin.y, origin.y + footprint.y):
			cells.append(Vector2i(x, z))
	return cells

static func usable_cell_bounds(room_size: Vector2, cell_size := DEFAULT_CELL_SIZE, wall_clearance := DEFAULT_WALL_CLEARANCE) -> Rect2i:
	var safe_cell_size := maxf(0.1, cell_size)
	var half_x := room_size.x * 0.5 - wall_clearance
	var half_z := room_size.y * 0.5 - wall_clearance
	var min_x := int(ceil(-half_x / safe_cell_size))
	var max_x := int(floor(half_x / safe_cell_size))
	var min_z := int(ceil(-half_z / safe_cell_size))
	var max_z := int(floor(half_z / safe_cell_size))
	return Rect2i(min_x, min_z, maxi(0, max_x - min_x + 1), maxi(0, max_z - min_z + 1))

static func cell_rect(origin: Vector2i, footprint: Vector2i) -> Rect2i:
	return Rect2i(origin.x, origin.y, footprint.x, footprint.y)

static func cells_overlap(first_origin: Vector2i, first_footprint: Vector2i, second_origin: Vector2i, second_footprint: Vector2i) -> bool:
	return cell_rect(first_origin, first_footprint).intersects(cell_rect(second_origin, second_footprint))

static func cell_to_local(origin: Vector2i, footprint: Vector2i, room_size: Vector2, cell_size := DEFAULT_CELL_SIZE) -> Vector3:
	var safe_cell_size := maxf(0.1, cell_size)
	return Vector3(
		(float(origin.x) + float(footprint.x - 1) * 0.5) * safe_cell_size,
		0.0,
		(float(origin.y) + float(footprint.y - 1) * 0.5) * safe_cell_size
	)

static func local_to_cell(local_position: Vector3, footprint: Vector2i, room_size: Vector2, cell_size := DEFAULT_CELL_SIZE) -> Vector2i:
	var safe_cell_size := maxf(0.1, cell_size)
	return Vector2i(
		int(floor(local_position.x / safe_cell_size - float(footprint.x - 1) * 0.5 + 0.5)),
		int(floor(local_position.z / safe_cell_size - float(footprint.y - 1) * 0.5 + 0.5))
	)

static func doorway_cells(room_size: Vector2, door_width: float, door_facing := Vector3(0.0, 0.0, 1.0), cell_size := DEFAULT_CELL_SIZE, wall_clearance := DEFAULT_WALL_CLEARANCE, door_clearance_depth := DEFAULT_DOOR_CLEARANCE_DEPTH) -> Array:
	var result: Array = []
	var bounds := usable_cell_bounds(room_size, cell_size, wall_clearance)
	var facing := door_facing
	if facing.length_squared() < 0.01:
		facing = Vector3(0.0, 0.0, 1.0)
	facing = facing.normalized()
	var depth := maxf(0.0, door_clearance_depth)
	var facing_extent := room_size.x * 0.5 if absf(facing.x) > absf(facing.z) else room_size.y * 0.5
	for cell_value in cells_for(Vector2i(bounds.position.x, bounds.position.y), Vector2i(bounds.size.x, bounds.size.y)):
		var cell: Vector2i = cell_value
		var center := cell_to_local(cell, Vector2i.ONE, room_size, cell_size)
		var at_door_side := center.dot(facing) >= facing_extent - wall_clearance - depth
		var across_door := absf(center.x) <= door_width * 0.5 + cell_size * 0.5 if absf(facing.z) > absf(facing.x) else absf(center.z) <= door_width * 0.5 + cell_size * 0.5
		if at_door_side and across_door:
			result.append(cell)
	return result

static func can_place(origin: Vector2i, footprint: Vector2i, room_size: Vector2, door_width: float, blocked_cells: Array = [], player_cell := Vector2i(2147483647, 2147483647), door_facing := Vector3(0.0, 0.0, 1.0), cell_size := DEFAULT_CELL_SIZE, wall_clearance := DEFAULT_WALL_CLEARANCE, door_clearance_depth := DEFAULT_DOOR_CLEARANCE_DEPTH, player_footprint := Vector2i.ONE) -> bool:
	if footprint.x <= 0 or footprint.y <= 0:
		return false
	var bounds := usable_cell_bounds(room_size, cell_size, wall_clearance)
	var requested := cell_rect(origin, footprint)
	var bounds_rect := Rect2i(bounds.position, bounds.size)
	if not bounds_rect.encloses(requested):
		return false
	var blocked := {}
	for blocked_value in blocked_cells:
		if blocked_value is Vector2i:
			blocked[blocked_value] = true
		elif blocked_value is Array and blocked_value.size() >= 2:
			blocked[Vector2i(int(blocked_value[0]), int(blocked_value[1]))] = true
	var safe_player_footprint := Vector2i(maxi(1, player_footprint.x), maxi(1, player_footprint.y))
	var player_is_present := player_cell.x < 2147483647 and player_cell.y < 2147483647
	var player_overlap := player_is_present and cells_overlap(origin, footprint, player_cell, safe_player_footprint)
	for cell_value in cells_for(origin, footprint):
		var cell: Vector2i = cell_value
		if blocked.has(cell) or player_overlap:
			return false
	for door_cell_value in doorway_cells(room_size, door_width, door_facing, cell_size, wall_clearance, door_clearance_depth):
		if requested.has_point(door_cell_value):
			return false
	return true
