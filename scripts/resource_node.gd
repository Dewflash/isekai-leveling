class_name ProdewtyResourceNode
extends Node3D

var world: Node
var resource_id := "wood"
var resource_amount := 2
var resource_label := "Wood"
var discovery_id := ""
var node_id := ""
var depleted := false
var zone_active := true
var required_contacts := 1
var contacts := 0

func interact(_actor: Node) -> void:
	if depleted or not visible:
		return
	if world != null and world.has_method("is_resource_depleted") and world.is_resource_depleted(self):
		depleted = true
		visible = false
		_set_collision_enabled(false)
		return
	if world != null and world.has_method("begin_resource_action"):
		world.begin_resource_action(self)
		return
	if world != null and world.has_method("collect_resource"):
		var collected: bool = world.collect_resource(self)
		if collected:
			depleted = true
			visible = false
			_set_collision_enabled(false)

func restore() -> void:
	depleted = false
	contacts = 0
	_refresh_contact_visual()
	visible = zone_active
	_set_depleted_visual(false)
	_set_collision_enabled(zone_active)
	if not is_in_group("interactable"):
		add_to_group("interactable")

func set_zone_active(active: bool) -> void:
	zone_active = active
	visible = active
	_set_depleted_visual(depleted)
	_set_collision_enabled(active and not depleted)

func set_depleted_from_save(value: bool) -> void:
	depleted = value
	contacts = required_contacts if value else 0
	_refresh_contact_visual()
	visible = zone_active
	_set_depleted_visual(depleted)
	_set_collision_enabled(zone_active and not depleted)
	if depleted:
		remove_from_group("interactable")
	elif not is_in_group("interactable"):
		add_to_group("interactable")

func set_contact_progress(value: int) -> void:
	if depleted:
		return
	contacts = clampi(value, 0, required_contacts)
	_refresh_contact_visual()

func apply_contact() -> bool:
	if depleted:
		return false
	contacts = mini(required_contacts, contacts + 1)
	_refresh_contact_visual()
	return contacts >= required_contacts

func play_contact_feedback() -> void:
	var marks := get_node_or_null("ContactMarks") as Node3D
	if marks == null:
		return
	var resting_scale := marks.scale
	marks.scale = resting_scale * 1.22
	var tween := create_tween()
	tween.tween_property(marks, "scale", resting_scale, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _refresh_contact_label() -> void:
	var stage := get_node_or_null("ResourceStage") as Label3D
	if stage != null and required_contacts > 1:
		stage.text = "%s\n%d / %d" % [resource_label.to_upper(), contacts, required_contacts]

func _refresh_contact_visual() -> void:
	_refresh_contact_label()
	var marks := get_node_or_null("ContactMarks") as Node3D
	if marks == null:
		return
	for index in marks.get_child_count():
		var mark := marks.get_child(index) as Node3D
		if mark != null:
			mark.visible = not depleted and index < contacts

func complete_depletion() -> void:
	depleted = true
	contacts = required_contacts
	_refresh_contact_visual()
	visible = zone_active
	_set_depleted_visual(true)
	_set_collision_enabled(false)
	remove_from_group("interactable")

func _set_depleted_visual(show_log: bool) -> void:
	var log_visual := get_node_or_null("FelledLogVisual") as Node3D
	if resource_id != "wood":
		# A profiled node may provide a small physical remainder (rubble, a
		# bundled cutting, or another authored residue). Keep that remainder in
		# the world while removing the original interactable presentation; nodes
		# without a remainder still disappear rather than becoming a ghost.
		var depleted_visual := get_node_or_null("DepletedVisual") as Node3D
		if show_log and depleted_visual != null:
			visible = zone_active
			for child in get_children():
				if child is Node3D:
					child.visible = child == depleted_visual
			depleted_visual.visible = zone_active
		elif show_log:
			visible = false
		elif zone_active:
			visible = true
			for child in get_children():
				if child is Node3D and child != depleted_visual:
					child.visible = true
			if depleted_visual != null:
				depleted_visual.visible = false
		return
	if log_visual == null and show_log:
		log_visual = Node3D.new()
		log_visual.name = "FelledLogVisual"
		var log_mesh := BoxMesh.new()
		log_mesh.size = Vector3(1.9, 0.22, 0.3)
		var log := MeshInstance3D.new()
		log.name = "FelledLog"
		log.mesh = log_mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#8c6047")
		material.roughness = 0.92
		log.material_override = material
		log.position = Vector3(0.0, 0.14, 0.0)
		log_visual.add_child(log)
		add_child(log_visual)
	if log_visual != null:
		log_visual.visible = show_log
	for child in get_children():
		if child != log_visual:
			child.visible = not show_log

func _set_collision_enabled(enabled: bool) -> void:
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = not enabled
		if child is StaticBody3D:
			child.collision_layer = 1 if enabled else 0
			child.collision_mask = 1 if enabled else 0
			for shape in child.get_children():
				if shape is CollisionShape3D:
					shape.disabled = not enabled
