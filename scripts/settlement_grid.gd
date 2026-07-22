class_name ProdewtySettlementGrid
extends RefCounted

## Pure grid helpers shared by placement validation and the world renderer.

const MIN_X := -13
const MAX_X := 13
const MIN_Z := -13
const MAX_Z := 13

static func world_to_cell(position: Vector3) -> Vector2i:
	return Vector2i(roundi(position.x), roundi(position.z))

static func cell_to_world(cell: Vector2i, y := 0.0) -> Vector3:
	return Vector3(float(cell.x), y, float(cell.y))

static func footprint_center_to_world(origin: Vector2i, footprint: Vector2i, y := 0.0) -> Vector3:
	return Vector3(float(origin.x) + float(footprint.x - 1) * 0.5, y, float(origin.y) + float(footprint.y - 1) * 0.5)

static func cells_for(origin: Vector2i, footprint: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in footprint.x:
		for z in footprint.y:
			cells.append(origin + Vector2i(x, z))
	return cells

static func inside_bounds(cells: Array[Vector2i]) -> bool:
	for cell in cells:
		if cell.x < MIN_X or cell.x > MAX_X or cell.y < MIN_Z or cell.y > MAX_Z:
			return false
	return true
