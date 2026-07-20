extends SceneTree

## Durable route-beat contract for the authored Whisperwood traversal.
## This keeps the route checkpoints in GameSession rather than trusting scene
## labels, so a reload cannot erase the player's physical progress.

const SessionScript = preload("res://scripts/game_session.gd")

var failures := 0
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("WHISPERWOOD_ROUTE_STATE_FAIL: %s" % message)

func _clear_slot(slot: String) -> void:
	for suffix in [".json", ".backup.json", ".tmp.json"]:
		var path := "user://%s%s" % [slot, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _new_session(slot: String) -> Node:
	_clear_slot(slot)
	var session := SessionScript.new()
	session.save_slot = slot
	root.add_child(session)
	session.energy = 24
	session.coins = 100
	session.get("unlocked_routes").clear()
	session.get("unlocked_routes").append("Whisperwood")
	session.expedition_run = {"status": "none"}
	return session

func _run() -> void:
	var route := _new_session("qa_whisperwood_route_state")
	_check(bool(route.call("start_expedition", "Whisperwood")), "Whisperwood run starts")
	_check(str(route.expedition_run.get("route_phase")) == "approach", "run starts at approach phase")
	_check(route.expedition_run.get("route_checkpoints", []).is_empty(), "run starts with no route checkpoints")
	_check(bool(route.call("record_route_checkpoint", "arrival")), "arrival checkpoint records")
	_check(str(route.expedition_run.get("route_phase")) == "arrival", "arrival advances phase")
	_check(route.expedition_run.get("route_checkpoints", []) == ["arrival"], "arrival is durable route state")
	_check(not bool(route.call("record_route_checkpoint", "arrival")), "duplicate arrival is rejected")
	_check(not bool(route.call("record_route_checkpoint", "return")), "return cannot skip the fork and capstone")
	_check(bool(route.call("record_route_checkpoint", "fork")), "fork checkpoint records")
	_check(str(route.expedition_run.get("route_phase")) == "fork", "fork advances phase")
	_check(bool(route.call("commit_expedition_branch", "grove")), "branch commits after fork")
	_check(str(route.expedition_run.get("route_phase")) == "branch", "branch commit owns branch phase")
	_check(bool(route.call("record_expedition_endpoint", "grove")), "grove endpoint is an authoritative session transition")
	_check(str(route.expedition_run.get("route_phase")) == "objective", "endpoint transition opens the objective phase")
	_check(bool(route.call("save_game")), "checkpointed branch saves")

	var loaded := SessionScript.new()
	loaded.save_slot = "qa_whisperwood_route_state"
	root.add_child(loaded)
	_check(bool(loaded.call("load_game")), "checkpointed branch reloads")
	_check(loaded.expedition_run.get("route_checkpoints", []) == ["arrival", "fork"], "reload preserves ordered checkpoints")
	_check(str(loaded.expedition_run.get("branch_id")) == "grove", "reload preserves selected branch")
	_check(str(loaded.expedition_run.get("route_phase")) == "objective", "reload preserves endpoint objective phase")
	var snapshot: Dictionary = loaded.call("expedition_route_snapshot")
	_check(snapshot.get("next_checkpoint", "") == "", "branch phase has no skipped checkpoint")

	loaded.expedition_run["route_phase"] = "shortcut"
	loaded.expedition_run["objective_progress"] = int(loaded.expedition_run.get("objective_target", 1))
	loaded.expedition_run["objective_complete"] = true
	loaded.expedition_run["shortcut_open"] = true
	loaded.expedition_run["cache_claimed"] = true
	_check(bool(loaded.call("record_route_checkpoint", "return")), "return checkpoint records after shortcut")
	_check(loaded.expedition_run.get("route_checkpoints", []) == ["arrival", "fork", "return"], "return completes the ordered route")
	_check(str(loaded.expedition_run.get("route_phase")) == "return", "return advances phase")
	_check(bool(loaded.call("save_game")), "completed route saves")

	var reloaded := SessionScript.new()
	reloaded.save_slot = "qa_whisperwood_route_state"
	root.add_child(reloaded)
	_check(bool(reloaded.call("load_game")), "completed route reloads")
	_check(reloaded.expedition_run.get("route_checkpoints", []) == ["arrival", "fork", "return"], "completed route survives reload")

	var invalid_payload: Dictionary = reloaded.call("_to_dict")
	var invalid_run: Dictionary = invalid_payload.get("expedition_run", {}).duplicate(true)
	invalid_run["route_checkpoints"] = ["fork", "arrival"]
	invalid_payload["expedition_run"] = invalid_run
	_check(not bool(reloaded.call("_save_shape_is_supported", invalid_payload)), "out-of-order checkpoints are rejected")
	invalid_run["route_checkpoints"] = ["arrival", "arrival"]
	_check(not bool(reloaded.call("_save_shape_is_supported", invalid_payload)), "duplicate checkpoints are rejected")
	invalid_run["route_checkpoints"] = ["arrival"]
	invalid_run["biome_id"] = "Sunlit Beach"
	_check(not bool(reloaded.call("_save_shape_is_supported", invalid_payload)), "Whisperwood checkpoints cannot leak into another biome")

	reloaded.expedition_run["route_checkpoints"] = "corrupt"
	_check(not bool(reloaded.call("record_route_checkpoint", "return")), "corrupt checkpoint state fails closed")
	_check(reloaded.call("expedition_route_snapshot").get("route_checkpoints", []).is_empty(), "snapshot fails closed for corrupt checkpoint state")

	if failures > 0:
		print("WHISPERWOOD_ROUTE_STATE_TESTS_FAIL failures=%d checks=%d" % [failures, checks])
		quit(1)
		return
	print("WHISPERWOOD_ROUTE_STATE_TESTS_PASS checks=%d" % checks)
	quit(0)
