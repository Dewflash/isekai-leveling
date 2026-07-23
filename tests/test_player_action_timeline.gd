extends SceneTree

const MainScene := preload("res://main.tscn")

const SAVE_SLOT := "qa_player_action_timeline"
const ACTION_SOURCE := "authored_action_timeline_v1"

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("PLAYER_ACTION_TIMELINE_FAIL: " + message)

func _run() -> void:
	ProjectSettings.set_setting("prodewty/save_slot", SAVE_SLOT)
	var world := MainScene.instantiate()
	root.add_child(world)
	await _wait_frames(12)
	var player := world.get("player") as CharacterBody3D
	var visual := player.get_node_or_null("Visual") as Node3D if player != null else null
	var sprite := visual.get_node_or_null("IllustratedCharacter") as Sprite3D if visual != null else null
	var slash := visual.get_node_or_null("CombatSlash") as MeshInstance3D if visual != null else null
	var gather_tool := visual.get_node_or_null("GatherTool") as MeshInstance3D if visual != null else null
	_check(player != null, "Main must expose the player for action timeline binding")
	_check(visual != null and sprite != null, "player must expose the visible authored character layer")
	_check(slash != null and gather_tool != null, "player must expose visible action overlays")
	if player == null or visual == null or sprite == null or slash == null or gather_tool == null:
		_finish(world)
		return

	player.call("play_attack_feedback")
	_check(str(sprite.get_meta("action_animation_state", "")) == "attack", "attack must enter the authored action timeline")
	_check(str(sprite.get_meta("action_animation_source", "")) == ACTION_SOURCE, "attack must publish its authored timeline source")
	_check(str(sprite.get_meta("action_animation_marker", "")) == "windup", "attack must begin in its windup marker")
	_check(not slash.visible, "attack slash must remain hidden before contact")
	await _wait_seconds(0.15)
	_check(int(sprite.get_meta("action_animation_frame", -1)) >= 1, "attack must advance to a contact frame")
	_check(str(sprite.get_meta("action_animation_marker", "")) in ["contact", "followthrough"], "attack must publish a contact or followthrough marker")
	_check(slash.visible, "attack slash must become visible during contact")
	_check(visual.scale.x > 1.0 and visual.scale.y < 1.0, "attack must visibly squash and stretch the authored character")
	await _wait_seconds(0.38)
	_check(str(sprite.get_meta("action_animation_state", "")) == "idle", "attack must cleanly return to idle")
	_check(not slash.visible, "attack slash must be hidden after recovery")
	_check(visual.scale.is_equal_approx(Vector3.ONE), "attack must restore the presentation scale")

	player.call("play_gather_feedback", "stone")
	_check(bool(player.get("gather_active")), "gather start must keep the gathering transaction active")
	_check(str(sprite.get_meta("action_animation_state", "")) == "gather_prepare", "gather must enter its preparation timeline")
	_check(str(sprite.get_meta("action_animation_resource", "")) == "stone", "gather must publish the resource being gathered")
	_check(gather_tool.visible, "gather tool must be visible during preparation")
	await _wait_seconds(0.25)
	_check(str(sprite.get_meta("action_animation_state", "")) == "gather_prepare", "gather preparation must hold while the resource action is active")
	_check(str(sprite.get_meta("action_animation_marker", "")) == "ready", "gather preparation must settle into its ready marker")
	_check(gather_tool.visible, "gather tool must remain visible while waiting for contact")
	player.call("finish_gather_feedback")
	_check(not bool(player.get("gather_active")), "gather finish must close the preparation transaction")
	_check(str(sprite.get_meta("action_animation_state", "")) == "gather_contact", "gather finish must enter its contact timeline")
	await _wait_seconds(0.12)
	_check(str(sprite.get_meta("action_animation_marker", "")) in ["strike", "return"], "gather contact must reach a strike or return marker")
	_check(gather_tool.visible, "gather tool must remain visible through the strike")
	player.call("cancel_gather_feedback")
	_check(str(sprite.get_meta("action_animation_state", "")) == "idle", "gather cancellation must return to idle")
	_check(not gather_tool.visible, "gather cancellation must hide the tool")
	_check(visual.scale.is_equal_approx(Vector3.ONE), "gather cancellation must restore the presentation scale")

	_check(bool(player.call("start_dodge")), "dodge must still start through the player action API")
	_check(str(sprite.get_meta("action_animation_state", "")) == "dodge", "dodge must enter its authored action timeline")
	await _wait_seconds(0.12)
	_check(visual.scale.x > 1.05 and visual.scale.y < 0.95, "dodge must visibly squash and stretch the authored character")
	await _wait_seconds(0.30)
	_check(str(sprite.get_meta("action_animation_state", "")) == "idle", "dodge must cleanly return to idle")

	player.call("take_damage", 1)
	_check(str(sprite.get_meta("action_animation_state", "")) == "hurt", "damage must enter the authored hurt timeline")
	_check(str(sprite.get_meta("action_animation_marker", "")) == "impact", "hurt must begin in its impact marker")
	await _wait_seconds(0.12)
	_check(int(sprite.get_meta("action_animation_frame", -1)) >= 1, "hurt must advance beyond its impact frame")
	await _wait_seconds(0.35)
	_check(str(sprite.get_meta("action_animation_state", "")) == "idle", "hurt must cleanly return to idle")

	_finish(world)

func _wait_frames(count: int) -> void:
	for _index in count:
		await process_frame

func _wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout

func _finish(world: Node) -> void:
	if is_instance_valid(world):
		world.queue_free()
	if failures.is_empty():
		print("PLAYER_ACTION_TIMELINE_PASS checks=%d" % checks)
		quit(0)
	else:
		print("PLAYER_ACTION_TIMELINE_FAIL count=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  " + failure)
		quit(1)
