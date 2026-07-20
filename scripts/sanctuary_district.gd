class_name ProdewtySanctuaryDistrict
extends Node3D

## Presentation-only Sanctuary dressing. GameSession remains the authority for
## placement and construction; this node only rebuilds the visual layer from
## known coordinates and imported CC0 source scenes.

const PACK_ROOT := "res://assets/sourced/quaternius-medieval-village/Medieval Village Pack - Dec 2020/"
const NATURE_ROOT := "res://assets/quaternius-stylized-nature/glTF/"
const AssetMeasurement := preload("res://scripts/sanctuary_asset_measurement.gd")

var source_instances: Array[Node3D] = []
var source_failures: Array[String] = []
var meadow_patch_count := 0
var decorative_crop_bed_count := 0
var log_pile_count := 0
var nature_source_count := 0
var organic_path_count := 0
var lantern_count := 0
var builder_yard_count := 0

func build(parent: Node3D, legacy_buildings: Array[Node3D]) -> void:
	if parent == null:
		return
	name = "SanctuaryHeroDistrict"
	parent.add_child(self)
	for legacy_building in legacy_buildings:
		if legacy_building.name == "CloverLivestockPen":
			_hide_legacy_shell_render_nodes(legacy_building)
		else:
			_hide_legacy_render_nodes(legacy_building)
	_build_fixed_buildings()
	_build_market_and_camp()
	_build_ground_story()
	_build_walkway_ground()
	_build_farm_edges()
	_build_working_stories()
	_build_perimeter_landmarks()
	_build_meadow_mosaic()
	_build_hearth_campfire()
	_build_lived_in_yard()
	_build_lantern_walks()

func _build_fixed_buildings() -> void:
	var hearth := _add_source("Buildings/FBX/Inn.fbx", "HearthLodge", Vector3(0.0, 0.0, -4.0), 1.0, 0.0)
	_add_fixed_shell_collision("HearthLodgeCollision", hearth)
	var archive := _add_source("Buildings/FBX/House_1.fbx", "ArchiveHouse", Vector3(-7.0, 0.0, -7.8), 1.35, 0.0)
	_add_fixed_shell_collision("ArchiveHouseCollision", archive)
	var bazaar := _add_source("Buildings/FBX/House_3.fbx", "BazaarHouse", Vector3(-7.5, 0.0, -1.5), 1.6, PI * 0.5)
	_add_fixed_shell_collision("BazaarHouseCollision", bazaar)
	_add_source("Buildings/FBX/Stable.fbx", "StarterStable", Vector3(-0.2, 0.0, 7.0), 0.74, 0.0)
	_add_label("HEARTH LODGE", Vector3(0.0, 3.9, -6.1))
	_add_label("ARCHIVE", Vector3(-7.0, 3.0, -9.45))
	_add_label("WANDERER'S BAZAAR", Vector3(-7.5, 3.35, -3.3))

func _build_market_and_camp() -> void:
	_add_source("Props/FBX/MarketStand_1.fbx", "MarketStandNorth", Vector3(-5.7, 0.0, -0.5), 2.05, -0.16)
	_add_source("Props/FBX/MarketStand_2.fbx", "MarketStandSouth", Vector3(-8.4, 0.0, 0.45), 2.4, PI * 0.14)
	_add_source("Props/FBX/Cart.fbx", "BazaarCart", Vector3(-9.5, 0.0, -2.6), 2.25, -0.2)
	_add_source("Props/FBX/Barrel.fbx", "BazaarBarrelA", Vector3(-5.0, 0.0, -2.05), 3.3, 0.0)
	_add_source("Props/FBX/Barrel.fbx", "BazaarBarrelB", Vector3(-5.45, 0.0, -2.05), 3.3, 0.0)
	_add_source("Props/FBX/Crate.fbx", "BazaarCrate", Vector3(-9.0, 0.0, -1.4), 3.5, 0.12)
	_add_source("Props/FBX/Bonfire_Lit.fbx", "SanctuaryBonfire", Vector3(0.0, 0.0, 1.05), 3.2, 0.0)
	_add_source("Props/FBX/Bench_1.fbx", "HearthBenchLeft", Vector3(-1.65, 0.0, 1.65), 2.45, 0.0)
	_add_source("Props/FBX/Bench_1.fbx", "HearthBenchRight", Vector3(1.65, 0.0, 1.65), 2.45, PI)
	_add_source("Props/FBX/Well.fbx", "SanctuaryWell", Vector3(8.0, 0.0, 4.45), 2.6, 0.0)
	_add_label("HEARTH", Vector3(0.0, 1.55, 1.05))

func _build_ground_story() -> void:
	# These stone pieces reinforce the main approach without closing the
	# player-built centre. Their logical occupancy remains empty by design.
	for index in 8:
		var z := 7.1 - float(index) * 1.55
		_add_source("Props/FBX/Path_Straight.fbx", "MainPath_%d" % index, Vector3(-0.75, 0.04, z), 3.15, 0.0)
		_add_source("Props/FBX/Path_Straight.fbx", "MainPath_%d_B" % index, Vector3(0.75, 0.04, z), 3.15, 0.0)
	for index in 5:
		var x := -4.6 + float(index) * 2.3
		_add_source("Props/FBX/Path_Square.fbx", "HearthCircle_%d" % index, Vector3(x, 0.045, 1.2 + sin(float(index) * 0.8) * 0.2), 3.0, 0.0)
	# Short branch walks make the buildings read as part of one settlement while
	# keeping the central build grid open for the player's own layout.
	for index in 4:
		_add_source("Props/FBX/Path_Straight.fbx", "BazaarApproach_%d" % index, Vector3(-3.3 - float(index) * 1.55, 0.045, -1.0), 2.7, PI * 0.5)
	for index in 3:
		_add_source("Props/FBX/Path_Straight.fbx", "ArchiveApproach_%d" % index, Vector3(-4.9, 0.045, -4.1 - float(index) * 1.55), 2.7, 0.0)

func _build_walkway_ground() -> void:
	# The source kit's paving is intentionally retained as the readable center
	# line, but warm organic dirt underneath it prevents the settlement from
	# reading as gray tiles dropped on a green plane. These meshes have no
	# collision and do not reserve any construction cells.
	for ribbon_data in [
		[Vector3(0.0, 0.014, 1.7), Vector2(3.0, 12.0), Color("#a48661"), 0.0],
		[Vector3(0.0, 0.014, 1.25), Vector2(9.4, 3.45), Color("#ad8c65"), 0.0],
		[Vector3(-5.55, 0.014, -1.0), Vector2(6.8, 2.9), Color("#a17e59"), -2.0],
		[Vector3(-4.9, 0.014, -5.7), Vector2(2.7, 5.0), Color("#a88661"), 0.0],
		[Vector3(-2.3, 0.014, 6.15), Vector2(6.2, 3.7), Color("#9f7c56"), 3.0],
		[Vector3(9.0, 0.014, 0.35), Vector2(5.8, 3.1), Color("#a98761"), 0.0],
	]:
		_add_organic_ribbon(ribbon_data[0], ribbon_data[1], ribbon_data[2], float(ribbon_data[3]))
	for stone_data in [
		[Vector3(-2.45, 0.045, 2.65), 0.26], [Vector3(2.55, 0.045, 2.65), 0.24],
		[Vector3(-3.45, 0.045, -2.75), 0.21], [Vector3(-3.45, 0.045, -4.1), 0.25],
		[Vector3(3.15, 0.045, 1.15), 0.22], [Vector3(-8.1, 0.045, -0.2), 0.24],
	]:
		_add_source("Props/FBX/Rock_1.fbx", "WalkwayStone", stone_data[0], float(stone_data[1]), 0.0)

func _add_organic_ribbon(position: Vector3, size: Vector2, color: Color, rotation_degrees: float) -> void:
	var ribbon := Node3D.new()
	ribbon.name = "OrganicDirtRibbon"
	ribbon.position = position
	ribbon.rotation_degrees.y = rotation_degrees
	add_child(ribbon)
	var lobes := [
		[0.0, 0.0, 0.58, 0.50], [-0.28, 0.16, 0.44, 0.34],
		[0.30, -0.14, 0.48, 0.37], [-0.08, 0.30, 0.34, 0.28],
	]
	for lobe_data in lobes:
		var patch := MeshInstance3D.new()
		patch.name = "DirtLobe"
		var patch_mesh := CylinderMesh.new()
		patch_mesh.top_radius = 1.0
		patch_mesh.bottom_radius = 1.0
		patch_mesh.height = 0.035
		patch_mesh.radial_segments = 12
		patch.mesh = patch_mesh
		patch.material_override = _district_material(color, 0.98)
		patch.position = Vector3(float(lobe_data[0]) * size.x, 0.0, float(lobe_data[1]) * size.y)
		patch.scale = Vector3(size.x * float(lobe_data[2]), 1.0, size.y * float(lobe_data[3]))
		ribbon.add_child(patch)
	organic_path_count += 1

func _build_farm_edges() -> void:
	for fence_data in [
		[Vector3(-7.3, 0.0, 3.0), 0.0],
		[Vector3(-5.6, 0.0, 5.35), 0.0],
		[Vector3(-2.0, 0.0, 7.45), 0.0],
		[Vector3(1.4, 0.0, 7.45), 0.0],
		[Vector3(-9.0, 0.0, 5.35), PI * 0.5],
		[Vector3(-0.2, 0.0, 5.75), PI * 0.5],
	]:
		_add_source("Props/FBX/Fence.fbx", "SanctuaryFence", fence_data[0], 2.5, float(fence_data[1]))
	_add_source("Props/FBX/Hay.fbx", "FarmHayA", Vector3(-2.1, 0.0, 5.7), 4.0, 0.0)
	_add_source("Props/FBX/Hay.fbx", "FarmHayB", Vector3(-1.35, 0.0, 6.0), 4.0, 0.2)
	_add_source("Props/FBX/Crate.fbx", "FarmCrate", Vector3(-4.1, 0.0, 5.85), 3.4, 0.0)

func _build_working_stories() -> void:
	# Functional clusters are deliberately grouped around the fixed landmarks;
	# they carry the lived-in feeling of the reference without reserving player
	# construction cells.
	_add_source("Props/FBX/Cauldron.fbx", "HearthCauldron", Vector3(1.2, 0.0, 0.55), 2.1, 0.1)
	_add_source("Props/FBX/Bag_Open.fbx", "BazaarOpenBag", Vector3(-5.2, 0.0, -0.75), 2.6, -0.22)
	_add_source("Props/FBX/Bags.fbx", "BazaarBags", Vector3(-6.1, 0.0, -2.25), 2.5, 0.0)
	_add_source("Props/FBX/Package_1.fbx", "BazaarPackageA", Vector3(-8.0, 0.0, -1.0), 3.0, 0.18)
	_add_source("Props/FBX/Package_2.fbx", "BazaarPackageB", Vector3(-8.55, 0.0, -1.2), 3.0, -0.12)
	_add_source("Props/FBX/Stairs.fbx", "ArchiveSteps", Vector3(-7.0, 0.0, -5.35), 2.2, 0.0)
	_add_source("Props/FBX/Barrel.fbx", "ArchiveBarrel", Vector3(-5.15, 0.0, -6.1), 3.1, 0.0)
	_add_source("Props/FBX/Crate.fbx", "ArchiveCrate", Vector3(-4.65, 0.0, -6.25), 3.0, -0.18)
	_add_source("Props/FBX/Gazebo.fbx", "SanctuaryShelter", Vector3(4.8, 0.0, -0.8), 2.1, 0.2)

func _build_perimeter_landmarks() -> void:
	# Tall silhouettes frame the playable floor and keep the camera from reading
	# the Sanctuary as an isolated test rectangle.
	_add_source("Buildings/FBX/Bell_Tower.fbx", "SanctuaryBellTower", Vector3(14.0, 0.0, -10.0), 0.78, 0.0)
	_add_source("Buildings/FBX/Sawmill.fbx", "SanctuarySawmill", Vector3(11.0, 0.0, 9.0), 0.82, PI * 0.5)
	_add_source("Props/FBX/Cart.fbx", "SawmillCart", Vector3(8.8, 0.0, 8.5), 2.0, -0.32)
	_add_source("Props/FBX/Hay.fbx", "SawmillHay", Vector3(12.7, 0.0, 8.25), 4.0, 0.1)
	_add_source("Props/FBX/Rock_1.fbx", "PerimeterRockA", Vector3(14.5, 0.0, 4.8), 2.2, 0.0)
	_add_source("Props/FBX/Rock_2.fbx", "PerimeterRockB", Vector3(-13.7, 0.0, 9.0), 2.5, 0.18)
	_add_source("Props/FBX/Rock_3.fbx", "PerimeterRockC", Vector3(-14.2, 0.0, -9.2), 2.3, -0.2)
	# The boundary is intentionally a soft woodland edge rather than a hard
	# rectangular map border. These are presentation-only trees and undergrowth;
	# the gameplay trees remain owned by Main/GameSession.
	for tree_data in [
		[Vector3(-18.0, 0.0, -11.0), 0.86, "Pine_2.gltf"],
		[Vector3(-16.4, 0.0, -8.7), 0.72, "CommonTree_4.gltf"],
		[Vector3(-17.7, 0.0, 5.8), 0.82, "Pine_3.gltf"],
		[Vector3(-15.7, 0.0, 10.8), 0.74, "CommonTree_5.gltf"],
		[Vector3(15.8, 0.0, -11.1), 0.82, "Pine_4.gltf"],
		[Vector3(17.5, 0.0, -7.7), 0.72, "CommonTree_1.gltf"],
		[Vector3(17.6, 0.0, 5.5), 0.86, "Pine_5.gltf"],
		[Vector3(15.8, 0.0, 10.8), 0.76, "CommonTree_4.gltf"],
		[Vector3(-11.8, 0.0, -13.2), 0.72, "Pine_1.gltf"],
		[Vector3(-3.2, 0.0, -14.0), 0.68, "CommonTree_2.gltf"],
		[Vector3(5.2, 0.0, -13.4), 0.72, "Pine_3.gltf"],
		[Vector3(12.0, 0.0, -13.0), 0.66, "CommonTree_3.gltf"],
	]:
		_add_nature_source(str(tree_data[2]), float(tree_data[1]), tree_data[0])
	for position in [
		Vector3(-16.7, 0.02, -5.8), Vector3(-15.8, 0.02, 3.7), Vector3(-13.8, 0.02, 7.7),
		Vector3(14.8, 0.02, -5.8), Vector3(15.4, 0.02, 2.6), Vector3(13.8, 0.02, 7.0),
		Vector3(-11.6, 0.02, -11.0), Vector3(8.8, 0.02, -11.2), Vector3(11.5, 0.02, 11.0),
	]:
		_add_nature_source("Bush_Common_Flowers.gltf", 0.42, position)
	for position in [
		Vector3(-15.3, 0.02, -4.2), Vector3(-14.8, 0.02, 1.4), Vector3(-13.2, 0.02, 5.0),
		Vector3(14.2, 0.02, -3.7), Vector3(14.5, 0.02, 1.2), Vector3(13.1, 0.02, 5.1),
		Vector3(-10.8, 0.02, -10.5), Vector3(8.2, 0.02, -10.7), Vector3(10.7, 0.02, 10.4),
	]:
		_add_nature_source("Grass_Wispy_Tall.gltf", 0.34, position)

func _build_meadow_mosaic() -> void:
	# A small palette of opaque, low-profile meadow islands prevents the sourced
	# kit from reading as props dropped onto one green rectangle. They sit above
	# the floor but below all walkable/interactive content.
	for patch_data in [
		[Vector3(-14.0, 0.008, -6.4), Vector2(5.8, 3.8), Color("#6e8d59"), -12.0],
		[Vector3(-12.2, 0.008, 2.1), Vector2(4.4, 3.4), Color("#78975d"), 18.0],
		[Vector3(-9.5, 0.008, 9.1), Vector2(7.0, 3.0), Color("#6b8957"), -8.0],
		[Vector3(10.7, 0.008, -7.0), Vector2(6.5, 3.4), Color("#7a965c"), 11.0],
		[Vector3(13.0, 0.008, 2.2), Vector2(5.8, 4.4), Color("#688653"), -18.0],
		[Vector3(10.2, 0.008, 10.0), Vector2(6.4, 3.1), Color("#738f57"), 9.0],
		[Vector3(-3.0, 0.008, -10.5), Vector2(4.8, 2.8), Color("#7d955b"), 5.0],
		[Vector3(4.4, 0.008, -10.2), Vector2(4.0, 3.0), Color("#6a8753"), -14.0],
	]:
		_add_meadow_patch(patch_data[0], patch_data[1], patch_data[2], float(patch_data[3]))
	for position in [
		Vector3(-13.4, 0.03, -7.4), Vector3(-11.8, 0.03, 3.7), Vector3(-8.8, 0.03, 8.6),
		Vector3(10.0, 0.03, -8.0), Vector3(12.3, 0.03, 3.8), Vector3(9.1, 0.03, 9.1),
		Vector3(-4.8, 0.03, -10.7), Vector3(5.2, 0.03, -10.8),
	]:
		_add_nature_source("Flower_3_Group.gltf", 0.30, position)
	for position in [
		Vector3(-12.9, 0.04, -8.1), Vector3(-10.7, 0.04, 4.8), Vector3(-7.7, 0.04, 9.4),
		Vector3(9.4, 0.04, -8.4), Vector3(11.4, 0.04, 5.2), Vector3(8.6, 0.04, 9.8),
		Vector3(-5.2, 0.04, -11.4), Vector3(5.8, 0.04, -11.3),
	]:
		_add_nature_source("Rock_Medium_2.gltf", 0.28, position)

func _build_hearth_campfire() -> void:
	# The sourced bonfire remains the hero asset; this low-poly ring and ember
	# core guarantee a readable warm centre even when an imported material is
	# subtle at the elevated camera distance.
	var campfire := Node3D.new()
	campfire.name = "HearthCampfireStory"
	campfire.position = Vector3(0.0, 0.0, 1.05)
	add_child(campfire)
	for index in 10:
		var angle := float(index) / 10.0 * TAU
		var stone := MeshInstance3D.new()
		var stone_mesh := CylinderMesh.new()
		stone_mesh.top_radius = 0.22
		stone_mesh.bottom_radius = 0.28
		stone_mesh.height = 0.28
		stone_mesh.radial_segments = 7
		stone.mesh = stone_mesh
		stone.material_override = _district_material(Color("#7a6f61"), 0.96)
		stone.position = Vector3(cos(angle) * 1.08, 0.15, sin(angle) * 1.08)
		stone.rotation_degrees = Vector3(0.0, rad_to_deg(angle), sin(angle * 2.0) * 8.0)
		campfire.add_child(stone)
	for index in 3:
		var log := MeshInstance3D.new()
		var log_mesh := CylinderMesh.new()
		log_mesh.top_radius = 0.13
		log_mesh.bottom_radius = 0.17
		log_mesh.height = 1.55
		log_mesh.radial_segments = 7
		log.mesh = log_mesh
		log.material_override = _district_material(Color("#6f4935"), 0.92)
		log.position = Vector3(0.0, 0.34 + float(index) * 0.08, 0.0)
		log.rotation_degrees = Vector3(0.0, float(index) * 60.0, 78.0)
		campfire.add_child(log)
	var flame := MeshInstance3D.new()
	flame.name = "HearthFlameCore"
	flame.mesh = _district_sphere(0.36, 0.86, 9, 5)
	flame.material_override = _district_material(Color("#f39b45"), 0.42, false, true)
	flame.position = Vector3(0.0, 1.05, 0.0)
	flame.scale = Vector3(0.75, 1.0, 0.62)
	campfire.add_child(flame)
	var glow := OmniLight3D.new()
	glow.name = "HearthCampfireGlow"
	glow.light_color = Color("#ff9a4e")
	glow.light_energy = 1.35
	glow.omni_range = 5.2
	glow.position = Vector3(0.0, 1.1, 0.0)
	campfire.add_child(glow)

func _build_lived_in_yard() -> void:
	# These props are decorative atmosphere around the fixed functional anchors;
	# the central build reserve stays open so player placement remains authored by
	# the user rather than silently pre-filled by presentation dressing.
	_add_log_pile(Vector3(-10.6, 0.0, -5.9), 0.0, 5)
	_add_log_pile(Vector3(-9.3, 0.0, -6.5), 0.22, 3)
	_add_log_pile(Vector3(7.9, 0.0, -7.3), -0.18, 3)
	for position in [Vector3(-3.9, 0.0, 5.1), Vector3(-2.8, 0.0, 5.3), Vector3(-1.7, 0.0, 5.1), Vector3(-0.6, 0.0, 5.4)]:
		_add_source("Props/FBX/Crate.fbx", "GardenCrate", position, 2.2, 0.0)
	for position in [Vector3(-4.9, 0.0, 3.25), Vector3(-3.4, 0.0, 3.45), Vector3(-1.9, 0.0, 3.25), Vector3(-0.4, 0.0, 3.4)]:
		_add_crop_bed(position)
	_add_source("Props/FBX/Cart.fbx", "HearthSupplyCart", Vector3(3.6, 0.0, 2.2), 1.8, 0.18)
	_add_source("Props/FBX/Barrel.fbx", "HearthWaterBarrel", Vector3(4.6, 0.0, 2.7), 2.45, 0.0)
	_add_source("Props/FBX/Bench_2.fbx", "HearthBenchBack", Vector3(3.4, 0.0, 2.8), 2.0, PI * 0.5)
	_add_source("Props/FBX/MarketStand_1.fbx", "OuterMarketStand", Vector3(-11.8, 0.0, 0.2), 1.55, PI * 0.5)
	_add_source("Props/FBX/MarketStand_2.fbx", "OuterMarketStandB", Vector3(-12.2, 0.0, 1.8), 1.65, PI * 0.5)
	_add_source("Props/FBX/Hay.fbx", "StableHayA", Vector3(-3.0, 0.0, 8.6), 3.3, 0.0)
	_add_source("Props/FBX/Hay.fbx", "StableHayB", Vector3(-1.8, 0.0, 8.7), 3.0, 0.12)
	_add_source("Props/FBX/Barrel.fbx", "StableBarrel", Vector3(1.8, 0.0, 8.3), 2.4, 0.0)
	for fence_data in [
		[Vector3(-4.8, 0.0, 7.9), 0.0], [Vector3(-2.0, 0.0, 9.0), 0.0],
		[Vector3(2.1, 0.0, 8.9), 0.0], [Vector3(3.0, 0.0, 7.4), PI * 0.5],
	]:
		_add_source("Props/FBX/Fence.fbx", "StableFence", fence_data[0], 1.8, float(fence_data[1]))
	_build_builder_yard()

func _build_builder_yard() -> void:
	# A communal material yard demonstrates the intended large-piece building
	# language without placing a player-owned structure or consuming grid cells.
	var yard := Node3D.new()
	yard.name = "ConstructionMaterialYard"
	yard.position = Vector3(7.0, 0.0, -1.7)
	add_child(yard)
	builder_yard_count += 1
	for index in 4:
		var log := MeshInstance3D.new()
		log.name = "YardLog_%d" % index
		var log_mesh := CylinderMesh.new()
		log_mesh.top_radius = 0.16
		log_mesh.bottom_radius = 0.21
		log_mesh.height = 2.7
		log_mesh.radial_segments = 8
		log.mesh = log_mesh
		log.material_override = _district_material(Color("#765039"), 0.93)
		log.position = Vector3(-0.92 + float(index % 2) * 0.22, 0.22 + float(index / 2) * 0.30, 0.42 + float(index % 2) * 0.20)
		log.rotation_degrees = Vector3(0.0, 90.0, 90.0)
		yard.add_child(log)
	for index in 3:
		var plank := MeshInstance3D.new()
		plank.name = "YardPlank_%d" % index
		var plank_mesh := BoxMesh.new()
		plank_mesh.size = Vector3(2.2, 0.10, 0.28)
		plank.mesh = plank_mesh
		plank.material_override = _district_material(Color("#bd8a56"), 0.91)
		plank.position = Vector3(0.65, 0.22 + float(index) * 0.14, 0.38)
		plank.rotation_degrees.y = -8.0 + float(index) * 5.0
		yard.add_child(plank)
	var frame := Node3D.new()
	frame.name = "YardAssemblyFrame"
	yard.add_child(frame)
	for side in [-1.0, 1.0]:
		_district_box(frame, "YardPost_%s" % side, Vector3(0.16, 2.15, 0.16), Vector3(side * 1.18, 1.08, -0.42), Color("#5f4433"))
	_district_box(frame, "YardHeader", Vector3(2.55, 0.18, 0.18), Vector3(0.0, 2.04, -0.42), Color("#5f4433"))
	_district_box(frame, "YardBrace", Vector3(0.11, 1.75, 0.11), Vector3(0.0, 1.08, -0.43), Color("#8f6644"), Vector3(0.0, 0.0, 30.0))
	var yard_lamp := _district_sphere(0.10, 0.22, 7, 4)
	var lamp := MeshInstance3D.new()
	lamp.name = "YardWorkLamp"
	lamp.mesh = yard_lamp
	lamp.material_override = _district_material(Color("#ffd17a"), 0.45, false, true)
	lamp.position = Vector3(0.0, 1.65, -0.56)
	frame.add_child(lamp)

func _build_lantern_walks() -> void:
	# Small warm lights make the route decisions readable at dusk without
	# turning the Sanctuary into a bright UI overlay.
	for lantern_data in [
		[Vector3(-2.25, 0.0, -0.65), Color("#ffbf70")],
		[Vector3(2.25, 0.0, -0.65), Color("#ffbf70")],
		[Vector3(-2.25, 0.0, 3.0), Color("#ffbf70")],
		[Vector3(2.25, 0.0, 3.0), Color("#ffbf70")],
		[Vector3(-9.1, 0.0, -5.2), Color("#79c6b4")],
		[Vector3(-9.1, 0.0, 2.5), Color("#74c3d0")],
		[Vector3(-8.4, 0.0, 5.4), Color("#e6a16b")],
		[Vector3(9.1, 0.0, -4.7), Color("#e8bc70")],
		[Vector3(9.1, 0.0, 2.8), Color("#a98fe1")],
	]:
		_add_lantern_post(lantern_data[0], lantern_data[1])

func _add_lantern_post(position: Vector3, accent: Color) -> void:
	var post := Node3D.new()
	post.name = "SanctuaryLanternPost"
	post.position = position
	add_child(post)
	lantern_count += 1
	_district_cylinder(post, "LanternPost", 0.07, 1.35, Vector3(0.0, 0.68, 0.0), Color("#5a4434"), 7)
	_district_box(post, "LanternArm", Vector3(0.55, 0.08, 0.08), Vector3(0.18, 1.30, 0.0), Color("#6c4d37"))
	var lantern := MeshInstance3D.new()
	lantern.name = "LanternGlow"
	lantern.mesh = _district_sphere(0.12, 0.24, 7, 4)
	lantern.material_override = _district_material(accent, 0.45, false, true)
	lantern.position = Vector3(0.42, 1.18, 0.0)
	post.add_child(lantern)
	var light := OmniLight3D.new()
	light.name = "LanternLight"
	light.light_color = accent
	light.light_energy = 0.34
	light.omni_range = 2.8
	light.shadow_enabled = false
	light.position = Vector3(0.42, 1.18, 0.0)
	post.add_child(light)

func _add_log_pile(position: Vector3, rotation_y: float, count: int) -> void:
	var pile := Node3D.new()
	pile.name = "SanctuaryLogPile"
	pile.position = position
	pile.rotation.y = rotation_y
	add_child(pile)
	log_pile_count += 1
	for index in count:
		var log := MeshInstance3D.new()
		var log_mesh := CylinderMesh.new()
		log_mesh.top_radius = 0.16
		log_mesh.bottom_radius = 0.20
		log_mesh.height = 1.65
		log_mesh.radial_segments = 7
		log.mesh = log_mesh
		log.material_override = _district_material(Color("#76503a"), 0.93)
		log.position = Vector3(float(index % 2) * 0.22, 0.18 + float(index / 2) * 0.27, float(index / 2) * 0.13)
		log.rotation_degrees = Vector3(0.0, 90.0, 90.0)
		pile.add_child(log)

func _add_crop_bed(position: Vector3) -> void:
	var bed := Node3D.new()
	bed.name = "DecorativeCropBed"
	bed.position = position
	add_child(bed)
	decorative_crop_bed_count += 1
	var soil := MeshInstance3D.new()
	var soil_mesh := BoxMesh.new()
	soil_mesh.size = Vector3(1.15, 0.08, 1.55)
	soil.mesh = soil_mesh
	soil.material_override = _district_material(Color("#7d5c3d"), 1.0)
	soil.position.y = 0.05
	bed.add_child(soil)
	for row in 3:
		for column in 2:
			var crop := MeshInstance3D.new()
			crop.mesh = _district_sphere(0.07, 0.22, 6, 3)
			crop.material_override = _district_material(Color("#739d54" if (row + column) % 2 == 0 else "#9bbd5f"), 0.9)
			crop.position = Vector3(-0.3 + float(column) * 0.6, 0.16, -0.45 + float(row) * 0.45)
			bed.add_child(crop)

func _add_meadow_patch(position: Vector3, size: Vector2, color: Color, rotation_degrees: float) -> void:
	var patch := MeshInstance3D.new()
	patch.name = "MeadowIsland"
	var patch_mesh := CylinderMesh.new()
	patch_mesh.top_radius = 1.0
	patch_mesh.bottom_radius = 1.0
	patch_mesh.height = 0.025
	patch_mesh.radial_segments = 16
	patch.mesh = patch_mesh
	patch.material_override = _district_material(color, 1.0)
	patch.position = position
	patch.rotation_degrees.y = rotation_degrees
	patch.scale = Vector3(size.x * 0.5, 1.0, size.y * 0.5)
	add_child(patch)
	meadow_patch_count += 1

func _add_nature_source(file_name: String, scale_value: float, position: Vector3) -> bool:
	var world := get_parent().get_parent() if get_parent() != null else null
	if world != null and world.has_method("_add_sourced_model"):
		var loaded := bool(world.call("_add_sourced_model", self, NATURE_ROOT + file_name, scale_value, position))
		if loaded:
			nature_source_count += 1
		return loaded
	return false

func _district_material(color: Color, roughness: float, transparent := false, emissive := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.0
	return material

func _district_box(parent: Node3D, node_name: String, size: Vector3, local_position: Vector3, color: Color, local_rotation_degrees := Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _district_material(color, 0.9)
	mesh_instance.position = local_position
	mesh_instance.rotation_degrees = local_rotation_degrees
	parent.add_child(mesh_instance)
	return mesh_instance

func _district_cylinder(parent: Node3D, node_name: String, radius: float, height: float, local_position: Vector3, color: Color, segments: int) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.08
	mesh.height = height
	mesh.radial_segments = segments
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _district_material(color, 0.9)
	mesh_instance.position = local_position
	parent.add_child(mesh_instance)
	return mesh_instance

func _district_sphere(radius: float, height: float, radial_segments: int, rings: int) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = radial_segments
	mesh.rings = rings
	return mesh

func _add_source(relative_path: String, node_name: String, world_position: Vector3, scale_value: float, rotation_y: float) -> Node3D:
	var scene := load(PACK_ROOT + relative_path) as PackedScene
	if scene == null:
		source_failures.append(relative_path)
		return null
	var instance := scene.instantiate() as Node3D
	if instance == null:
		source_failures.append(relative_path)
		return null
	instance.name = node_name
	instance.position = world_position
	instance.rotation.y = rotation_y
	instance.scale = Vector3.ONE * scale_value
	instance.set_meta("source_asset", PACK_ROOT + relative_path)
	add_child(instance)
	source_instances.append(instance)
	return instance

func _add_fixed_shell_collision(node_name: String, source_instance: Node3D) -> void:
	if source_instance == null:
		push_error("Fixed Sanctuary landmark '%s' has no source asset; refusing to create an unmeasured shell." % node_name)
		return
	var measurement := AssetMeasurement.measure_runtime_node_local(source_instance)
	if not bool(measurement.get("valid", false)):
		push_error("Fixed Sanctuary landmark '%s' has no measurable source geometry; refusing to create an unmeasured shell." % node_name)
		return
	var bounds: AABB = measurement.get("bounds", AABB())
	var width := bounds.size.x
	var depth := bounds.size.z
	var height := bounds.size.y
	var wall_thickness := clampf(minf(width, depth) * 0.035, 0.07, 0.18)
	var body := StaticBody3D.new()
	body.name = node_name
	body.transform = source_instance.transform
	body.set_meta("measurement_source", str(measurement.get("measurement_source", "runtime_visible_mesh_bounds_local")))
	body.set_meta("measurement_asset", str(measurement.get("source_path", "")))
	body.set_meta("visible_root", source_instance)
	body.set_meta("asset_id", str(source_instance.get_meta("source_asset", source_instance.name)))
	body.set_meta("measured_bounds", [
		bounds.position.x, bounds.position.y, bounds.position.z,
		bounds.size.x, bounds.size.y, bounds.size.z,
	])
	for wall_data in [
		[Vector3((bounds.position.x + bounds.end.x) * 0.5, bounds.position.y + height * 0.5, bounds.position.z + wall_thickness * 0.5), Vector3(width, height, wall_thickness)],
		[Vector3(bounds.position.x + wall_thickness * 0.5, bounds.position.y + height * 0.5, (bounds.position.z + bounds.end.z) * 0.5), Vector3(wall_thickness, height, maxf(wall_thickness, depth - wall_thickness * 2.0))],
		[Vector3(bounds.end.x - wall_thickness * 0.5, bounds.position.y + height * 0.5, (bounds.position.z + bounds.end.z) * 0.5), Vector3(wall_thickness, height, maxf(wall_thickness, depth - wall_thickness * 2.0))],
	]:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = wall_data[1]
		collision.shape = shape
		collision.position = wall_data[0]
		collision.set_meta("landmark_asset_id", str(source_instance.get_meta("source_asset", source_instance.name)))
		collision.set_meta("visible_root", source_instance)
		collision.set_meta("measurement_source", str(measurement.get("measurement_source", "runtime_visible_mesh_bounds_local")))
		collision.set_meta("measured_bounds", [
			bounds.position.x, bounds.position.y, bounds.position.z,
			bounds.size.x, bounds.size.y, bounds.size.z,
		])
		body.add_child(collision)
	add_child(body)

func _add_label(text_value: String, world_position: Vector3) -> void:
	var label := Label3D.new()
	label.text = text_value
	label.font_size = 28
	label.modulate = Color("#fff0c8")
	label.outline_size = 8
	label.outline_modulate = Color(0.08, 0.12, 0.10, 0.88)
	label.position = world_position
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.visible = false
	add_child(label)

func _hide_legacy_render_nodes(node: Node) -> void:
	if node == null:
		return
	for collision_node in node.find_children("*", "CollisionShape3D", true, false):
		var collision := collision_node as CollisionShape3D
		collision.disabled = true
		collision.set_meta("legacy_hidden_collision", true)
	for child in node.get_children():
		if child is MeshInstance3D or child is Label3D:
			(child as Node3D).visible = false
		_hide_legacy_render_nodes(child)

func _hide_legacy_shell_render_nodes(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		# The resident and its sourced animal are gameplay-owned visual roots;
		# preserve them while replacing only the starter shell's geometry.
		if child.name in ["Clover", "SourcedPaddockCow"]:
			continue
		if child is MeshInstance3D or child is Label3D:
			(child as Node3D).visible = false
		_hide_legacy_shell_render_nodes(child)
