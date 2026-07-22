extends SceneTree

const ASSET_ROOT := "res://assets/sourced/quaternius-medieval-village/Medieval Village Pack - Dec 2020/"
const PROBES := [
	"Buildings/FBX/House_1.fbx",
	"Buildings/FBX/House_2.fbx",
	"Buildings/FBX/House_3.fbx",
	"Buildings/FBX/House_4.fbx",
	"Buildings/FBX/Blacksmith.fbx",
	"Buildings/FBX/Inn.fbx",
	"Buildings/FBX/Stable.fbx",
	"Buildings/FBX/Bell_Tower.fbx",
	"Buildings/FBX/Sawmill.fbx",
	"Props/FBX/Well.fbx",
	"Props/FBX/MarketStand_1.fbx",
	"Props/FBX/MarketStand_2.fbx",
	"Props/FBX/Bonfire_Lit.fbx",
	"Props/FBX/Fence.fbx",
	"Props/FBX/Path_Straight.fbx",
	"Props/FBX/Path_Square.fbx",
	"Props/FBX/Cart.fbx",
	"Props/FBX/Barrel.fbx",
	"Props/FBX/Crate.fbx",
	"Props/FBX/Bench_1.fbx",
	"Props/FBX/Hay.fbx",
	"Props/FBX/Cauldron.fbx",
	"Props/FBX/Bag_Open.fbx",
	"Props/FBX/Bags.fbx",
	"Props/FBX/Package_1.fbx",
	"Props/FBX/Package_2.fbx",
	"Props/FBX/Stairs.fbx",
	"Props/FBX/Gazebo.fbx",
	"Props/FBX/Rock_1.fbx",
	"Props/FBX/Rock_2.fbx",
	"Props/FBX/Rock_3.fbx",
]

func _init() -> void:
	for relative_path in PROBES:
		var scene := load(ASSET_ROOT + relative_path) as PackedScene
		assert(scene != null, "Failed to load %s" % relative_path)
		var instance := scene.instantiate()
		assert(instance != null, "Failed to instantiate %s" % relative_path)
		var bounds := _bounds(instance, Transform3D.IDENTITY)
		print("ASSET_SIZE %s min=%s size=%s" % [relative_path, bounds.position, bounds.size])
		instance.free()
	print("SANCTUARY_ASSET_PROBE_PASS")
	quit()

func _bounds(node: Node, parent_transform: Transform3D) -> AABB:
	var transform := parent_transform
	if node is Node3D:
		transform = parent_transform * (node as Node3D).transform
	var result := AABB()
	var has_bounds := false
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var mesh_bounds := (node as MeshInstance3D).mesh.get_aabb()
		for corner in [
			Vector3(mesh_bounds.position.x, mesh_bounds.position.y, mesh_bounds.position.z),
			Vector3(mesh_bounds.end.x, mesh_bounds.position.y, mesh_bounds.position.z),
			Vector3(mesh_bounds.position.x, mesh_bounds.end.y, mesh_bounds.position.z),
			Vector3(mesh_bounds.position.x, mesh_bounds.position.y, mesh_bounds.end.z),
			Vector3(mesh_bounds.end.x, mesh_bounds.end.y, mesh_bounds.position.z),
			Vector3(mesh_bounds.end.x, mesh_bounds.position.y, mesh_bounds.end.z),
			Vector3(mesh_bounds.position.x, mesh_bounds.end.y, mesh_bounds.end.z),
			Vector3(mesh_bounds.end.x, mesh_bounds.end.y, mesh_bounds.end.z),
		]:
			var point: Vector3 = transform * corner
			if not has_bounds:
				result = AABB(point, Vector3.ZERO)
				has_bounds = true
			else:
				result = result.expand(point)
	for child in node.get_children():
		var child_bounds := _bounds(child, transform)
		if child_bounds.size != Vector3.ZERO or child_bounds.position != Vector3.ZERO:
			if not has_bounds:
				result = child_bounds
				has_bounds = true
			else:
				result = result.merge(child_bounds)
	return result
