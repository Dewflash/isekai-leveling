extends Node

## Small composition-root extension for player-facing actions that must remain
## available in the reference HUD. Keeping this outside the large world script
## lets the action stay testable and prevents an old management-only button
## from being the only path to an expedition extraction.

var world: Node
var extract_button: Button
var feedback_session: Node
var shortcut_gate: StaticBody3D
var last_pickup_signature := ""
var pressure_warning_active := false
var pressure_save_elapsed := 0.0

func _process(delta: float) -> void:
	if not is_instance_valid(world):
		world = get_tree().current_scene
		if world == null:
			world = get_tree().root.get_node_or_null("Prodewty")
	if not is_instance_valid(world) or world.name != "Prodewty":
		return
	_bind_feedback_session()
	_ensure_extract_button()
	_update_extract_button()
	_update_guardian_activation()
	_suppress_legacy_hazard_loop()
	_update_expedition_pressure(delta)
	_ensure_whisperwood_shortcut_gate()
	_update_whisperwood_shortcut_gate()
	_update_whisperwood_endpoint()
	_update_expedition_pickups()
	call_deferred("_restore_resource_contact_labels")

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or event.keycode != KEY_X:
		return
	if not is_instance_valid(world) or world.name != "Prodewty":
		return
	if _extraction_is_available():
		world.call("_return_home")
		get_viewport().set_input_as_handled()

func _ensure_extract_button() -> void:
	if is_instance_valid(extract_button):
		return
	var slot_box := world.get("reference_slot_box") as HBoxContainer
	if slot_box == null:
		return
	extract_button = Button.new()
	extract_button.name = "ReferenceSlot_EXTRACT"
	extract_button.custom_minimum_size = Vector2(86, 50)
	extract_button.tooltip_text = "Extract cargo at the expedition beacon (X)"
	extract_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#7a4c22")
	normal.border_color = Color("#c58d43")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#a96a2f")
	extract_button.add_theme_stylebox_override("normal", normal)
	extract_button.add_theme_stylebox_override("hover", hover)
	extract_button.add_theme_stylebox_override("disabled", normal)
	extract_button.add_theme_color_override("font_color", Color("#f6d891"))
	extract_button.add_theme_color_override("font_disabled_color", Color("#9a8a6c"))
	var key_label := Label.new()
	key_label.name = "SlotIcon"
	key_label.text = "X"
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.position = Vector2(4, 3)
	key_label.size = Vector2(78, 23)
	key_label.add_theme_font_size_override("font_size", 21)
	key_label.add_theme_color_override("font_color", Color("#f6d891"))
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	extract_button.add_child(key_label)
	var caption := Label.new()
	caption.name = "SlotCaption"
	caption.text = "EXTRACT"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.position = Vector2(3, 28)
	caption.size = Vector2(80, 17)
	caption.add_theme_font_size_override("font_size", 8)
	caption.add_theme_color_override("font_color", Color("#ead1a0"))
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	extract_button.add_child(caption)
	extract_button.pressed.connect(_activate_extraction)
	slot_box.add_child(extract_button)

func _update_extract_button() -> void:
	if not is_instance_valid(extract_button):
		return
	var expedition := is_instance_valid(world) and str(world.get("current_zone")) != "Sanctuary"
	extract_button.visible = expedition
	var at_beacon := _extraction_is_available()
	extract_button.disabled = not at_beacon or bool(world.get_tree().paused)
	extract_button.tooltip_text = "Extract cargo (X)" if at_beacon else "Walk to the expedition beacon to extract"

func _extraction_is_available() -> bool:
	if not is_instance_valid(world) or str(world.get("current_zone")) == "Sanctuary":
		return false
	var player := world.get("player") as Node3D
	if player == null:
		return false
	var extraction := Vector3(0.0, 1.0, 7.5)
	return Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(extraction.x, extraction.z)) <= 2.8

func _activate_extraction() -> void:
	if _extraction_is_available():
		world.call("_return_home")

func _bind_feedback_session() -> void:
	var session := world.get("session") as Node
	if session == null or session == feedback_session or not session.has_signal("feedback_requested"):
		return
	feedback_session = session
	session.connect("feedback_requested", Callable(self, "_on_session_feedback"))

func _on_session_feedback(kind: String, payload: Dictionary) -> void:
	if not is_instance_valid(world):
		return
	if kind == "route_checkpoint":
		world.call("_show_toast", "Route beat reached  |  %s" % str(payload.get("checkpoint", "checkpoint")).capitalize(), 2.2)
	elif kind == "route_endpoint":
		world.call("_show_toast", "Endpoint reached  |  %s" % str(payload.get("label", "route objective")), 2.4)

func _update_guardian_activation() -> void:
	if not is_instance_valid(world):
		return
	for guardian in world.get_tree().get_nodes_in_group("guardian"):
		if not is_instance_valid(guardian) or not guardian.has_method("set_active"):
			continue
		var parent := guardian.get_parent()
		var guardian_zone := str(parent.name) if parent != null else ""
		var active_zone := str(world.get("current_zone")).replace(" ", "") == guardian_zone
		guardian.call("set_active", active_zone)

func _suppress_legacy_hazard_loop() -> void:
	## main.gd still contains the legacy timer for compatibility. The durable
	## session clock is authoritative now, so keep the old timer below zero while
	## an expedition is under pressure instead of allowing duplicate losses.
	if not is_instance_valid(world) or not world.has_method("set"):
		return
	var session := world.get("session") as Node
	if session == null or not session.has_method("has_active_expedition") or not bool(session.call("has_active_expedition")):
		return
	var run: Dictionary = session.get("expedition_run") if session.get("expedition_run") is Dictionary else {}
	if bool(run.get("stake_active", false)):
		world.set("hazard_timer", -100000.0)

func _update_expedition_pressure(delta: float) -> void:
	if not is_instance_valid(world) or str(world.get("current_zone")) == "Sanctuary":
		pressure_warning_active = false
		pressure_save_elapsed = 0.0
		return
	var session := world.get("session") as Node
	if session == null or not session.has_method("advance_expedition_pressure") or not bool(session.call("has_active_expedition")):
		pressure_warning_active = false
		pressure_save_elapsed = 0.0
		return
	var run: Dictionary = session.get("expedition_run") if session.get("expedition_run") is Dictionary else {}
	if not bool(run.get("stake_active", false)):
		pressure_warning_active = false
		pressure_save_elapsed = 0.0
		return
	var sheltered := false
	if world.has_method("_is_player_in_route_shelter"):
		sheltered = bool(world.call("_is_player_in_route_shelter"))
	var before_pressure: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	var result: Dictionary = session.call("advance_expedition_pressure", maxf(0.0, delta), sheltered)
	if result.is_empty():
		return
	var warning := bool(result.get("warning", false))
	if warning and not pressure_warning_active:
		world.call("_show_toast", "Pressure rising  |  The route will drain Energy soon.", 2.1)
	pressure_warning_active = warning
	if bool(result.get("triggered", false)):
		pressure_warning_active = false
		var loss := int(result.get("energy_loss", 0))
		var damage := int(result.get("health_loss", 0))
		world.call("_show_toast", "%s  |  -%d Energy" % [str(result.get("message", "The route is demanding a safe return.")), loss], 2.6)
		if damage > 0 and world.has_method("player_took_damage"):
			world.call("player_took_damage", damage)
	pressure_save_elapsed += maxf(0.0, delta)
	var should_save := bool(result.get("triggered", false)) or pressure_save_elapsed >= 1.0
	if not should_save:
		return
	if bool(session.call("save_game")):
		pressure_save_elapsed = 0.0
		return
	if not before_pressure.is_empty() and session.has_method("restore_state"):
		session.call("restore_state", before_pressure)
	world.call("_copy_session_to_runtime")
	pressure_save_elapsed = 0.0
	world.call("_show_toast", "Route pressure could not be secured. The loss was rolled back.", 3.0)

func _ensure_whisperwood_shortcut_gate() -> void:
	if is_instance_valid(shortcut_gate) or not is_instance_valid(world):
		return
	var route := world.get_node_or_null("Whisperwood/WhisperwoodRoute") as Node3D
	if route == null:
		return
	shortcut_gate = StaticBody3D.new()
	shortcut_gate.name = "WhisperwoodRootGate"
	shortcut_gate.position = Vector3(0.0, 0.0, -4.8)
	shortcut_gate.set_meta("shortcut_gate", true)
	route.add_child(shortcut_gate)
	var collision := CollisionShape3D.new()
	collision.name = "RootGateCollision"
	var gate_shape := BoxShape3D.new()
	gate_shape.size = Vector3(7.6, 1.9, 0.68)
	collision.shape = gate_shape
	collision.position.y = 0.95
	shortcut_gate.add_child(collision)
	var gate_material: Material = world.call("_material", Color("#5d3f36"), 0.92) if world.has_method("_material") else null
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.42, 2.25, 0.42)
		post.mesh = post_mesh
		post.material_override = gate_material
		post.position = Vector3(side * 3.35, 1.12, 0.0)
		shortcut_gate.add_child(post)
	var beam := MeshInstance3D.new()
	var beam_mesh := BoxMesh.new()
	beam_mesh.size = Vector3(7.1, 0.34, 0.44)
	beam.mesh = beam_mesh
	beam.material_override = gate_material
	beam.position = Vector3(0.0, 2.05, 0.0)
	shortcut_gate.add_child(beam)
	var root_label := Label3D.new()
	root_label.name = "RootGateLabel"
	root_label.text = "ROOTGATE\nLOCKED"
	root_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root_label.font_size = 28
	root_label.modulate = Color("#f4d79e")
	root_label.position = Vector3(0.0, 2.55, 0.0)
	shortcut_gate.add_child(root_label)

func _update_whisperwood_shortcut_gate() -> void:
	if not is_instance_valid(shortcut_gate) or not is_instance_valid(world):
		return
	var session := world.get("session") as Node
	var active := str(world.get("current_zone")) == "Whisperwood" and session != null and bool(session.call("has_active_expedition"))
	var run: Dictionary = session.get("expedition_run") if active and session.get("expedition_run") is Dictionary else {}
	var open := bool(run.get("shortcut_open", false))
	shortcut_gate.visible = active and not open
	var collision := shortcut_gate.get_node_or_null("RootGateCollision") as CollisionShape3D
	if collision != null:
		collision.disabled = not (active and not open)
	var label := shortcut_gate.get_node_or_null("RootGateLabel") as Label3D
	if label != null:
		label.text = "ROOTGATE\nOPEN" if open else "ROOTGATE\nLOCKED"

func whisperwood_return_route_distance(branch_id := "", shortcut_open := false) -> float:
	## A measurable authored route contract used by QA and route dressing. The
	## root gate is placed at the same corridor boundary as this detour, so the
	## open route is not merely a flag: it shortens the walkable return.
	var endpoint := Vector3(-12.5, 1.0, -8.6) if branch_id == "grove" else Vector3(12.5, 1.0, -8.6)
	var beacon := Vector3(0.0, 1.0, 7.5)
	if shortcut_open:
		return Vector2(endpoint.x, endpoint.z).distance_to(Vector2(beacon.x, beacon.z))
	var detour_x := -4.6 if branch_id == "grove" else 4.6
	var detour_a := Vector3(detour_x, 1.0, -4.05)
	var detour_b := Vector3(detour_x, 1.0, 7.5)
	return endpoint.distance_to(detour_a) + detour_a.distance_to(detour_b) + detour_b.distance_to(beacon)

func _update_expedition_pickups() -> void:
	if not is_instance_valid(world):
		return
	var session := world.get("session") as Node
	if session == null or str(world.get("current_zone")) == "Sanctuary" or not session.has_method("has_active_expedition") or not bool(session.call("has_active_expedition")):
		last_pickup_signature = ""
		return
	var run: Dictionary = session.get("expedition_run") if session.get("expedition_run") is Dictionary else {}
	if str(run.get("biome_id", "")) != str(world.get("current_zone")):
		last_pickup_signature = ""
		return
	var signatures: Array[String] = []
	var pickups: Variant = run.get("pickups", [])
	if pickups is Array:
		for pickup_value in pickups:
			if pickup_value is Dictionary:
				signatures.append("%s:%d" % [str(pickup_value.get("pickup_id", "")), int(pickup_value.get("amount", 0))])
	var signature := "|".join(signatures)
	if signature == last_pickup_signature:
		return
	if world.has_method("_refresh_expedition_pickups"):
		world.call("_refresh_expedition_pickups")
	last_pickup_signature = signature
	_decorate_guardian_pickups(run)

func _decorate_guardian_pickups(run: Dictionary) -> void:
	var pickups: Variant = run.get("pickups", [])
	if not pickups is Array:
		return
	for pickup_value in pickups:
		if not pickup_value is Dictionary or str(pickup_value.get("pickup_kind", "resource")) != "guardian_reward":
			continue
		var pickup_id := str(pickup_value.get("pickup_id", ""))
		var pickup_node := world.get_node_or_null("Whisperwood/FieldPickup_%s" % pickup_id.replace(":", "_"))
		if pickup_node == null:
			continue
		var label := pickup_node.get_node_or_null("PickupLabel") as Label3D
		if label != null:
			label.text = "GUARDIAN REWARD  x%d" % int(pickup_value.get("amount", 0))

func _update_whisperwood_endpoint() -> void:
	if not is_instance_valid(world) or str(world.get("current_zone")) != "Whisperwood":
		return
	var session := world.get("session") as Node
	var player := world.get("player") as Node3D
	if session == null or player == null or not session.has_method("record_expedition_endpoint") or not bool(session.call("has_active_expedition")):
		return
	var run: Dictionary = session.get("expedition_run") if session.get("expedition_run") is Dictionary else {}
	if str(run.get("route_phase", "")) != "branch":
		return
	var branch_id := str(run.get("branch_id", ""))
	var endpoint_name := "FernGrove" if branch_id == "grove" else "GuardianClearing" if branch_id == "clearing" else ""
	if endpoint_name.is_empty():
		return
	var endpoint := world.get_node_or_null("Whisperwood/WhisperwoodRoute/AuthoredTopology/%s/Checkpoint" % endpoint_name) as Area3D
	if endpoint == null:
		return
	var distance := Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(endpoint.global_position.x, endpoint.global_position.z))
	if distance > float(endpoint.get_meta("checkpoint_radius", 3.0)):
		return
	var before_endpoint: Dictionary = session.call("snapshot_state") if session.has_method("snapshot_state") else {}
	if not bool(session.call("record_expedition_endpoint", branch_id)):
		return
	if not bool(session.call("save_game")):
		if not before_endpoint.is_empty() and session.has_method("restore_state"):
			session.call("restore_state", before_endpoint)
		world.call("_copy_session_to_runtime")
		world.call("_show_toast", "The endpoint could not be secured. The objective remains ahead.", 2.6)
		return
	world.call("_refresh_whisperwood_route")

func _restore_resource_contact_labels() -> void:
	if not is_instance_valid(world):
		return
	for resource_node in world.get_tree().get_nodes_in_group("resource_node"):
		if is_instance_valid(resource_node) and resource_node.has_method("_refresh_contact_label"):
			resource_node.call("_refresh_contact_label")
