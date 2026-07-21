extends SceneTree

## Domain contract for the pressure clock and the full-satchel guardian drop.
## These are deliberately session-level checks: the scene may animate the
## warning or respawn the bundle, but it cannot mint, erase, or duplicate the
## durable state.

const SessionScript = preload("res://scripts/game_session.gd")

var failures := 0
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("WHISPERWOOD_PRESSURE_REWARD_FAIL: %s" % message)

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

func _reach_endpoint(session: Node, branch_id: String) -> void:
	_check(bool(session.call("record_route_checkpoint", "arrival")), "route records arrival before branch")
	_check(bool(session.call("record_route_checkpoint", "fork")), "route records fork before branch")
	_check(bool(session.call("commit_expedition_branch", branch_id)), "route commits at the fork")
	_check(bool(session.call("record_expedition_endpoint", branch_id)), "route records the physical endpoint")

func _prepare_cache_run(session: Node) -> void:
	_check(bool(session.call("start_expedition", "Whisperwood")), "pressure run starts")
	_reach_endpoint(session, "clearing")
	session.expedition_run["objective_progress"] = int(session.expedition_run.get("objective_target", 1))
	session.expedition_run["objective_complete"] = true
	session.expedition_run["route_phase"] = "capstone"
	_check(not bool(session.expedition_run.get("stake_active", false)), "pressure stays off before cache")
	_check(not session.call("open_expedition_cache").is_empty(), "cache opens after capstone")

func _run() -> void:
	var pressure := _new_session("qa_whisperwood_pressure")
	_prepare_cache_run(pressure)
	var interval := float(pressure.call("expedition_pressure_interval"))
	_check(is_equal_approx(interval, 5.5), "Whisperwood interval is authored")
	var warning: Dictionary = pressure.call("advance_expedition_pressure", interval - 0.7)
	_check(bool(warning.get("warning", false)), "pressure warning appears before loss")
	_check(int(warning.get("tick_count", 0)) == 0, "warning does not drain early")
	_check(float(pressure.expedition_run.get("pressure_elapsed_seconds", 0.0)) > 4.0, "pressure elapsed is durable in memory")
	_check(bool(pressure.call("save_game")), "warning state saves")
	var pressure_reload := SessionScript.new()
	pressure_reload.save_slot = "qa_whisperwood_pressure"
	root.add_child(pressure_reload)
	_check(bool(pressure_reload.call("load_game")), "warning state reloads")
	_check(float(pressure_reload.expedition_run.get("pressure_elapsed_seconds", 0.0)) > 4.0, "warning pressure survives reload")
	var tick: Dictionary = pressure_reload.call("advance_expedition_pressure", 1.0)
	_check(bool(tick.get("triggered", false)), "pressure tick triggers after reload")
	_check(int(tick.get("tick_count", 0)) == 1, "one pressure tick is resolved")
	_check(int(pressure_reload.expedition_run.get("stake_ticks", 0)) == 1, "stake tick count persists")
	_check(int(tick.get("energy_loss", 0)) == 1, "pressure drains one Energy")
	var sheltered: Dictionary = pressure_reload.call("advance_expedition_pressure", 30.0, true)
	_check(bool(sheltered.get("sheltered", false)), "shelter response is explicit")
	_check(float(pressure_reload.expedition_run.get("pressure_elapsed_seconds", -1.0)) == 0.0, "shelter resets pressure clock")
	_check(pressure_reload.call("advance_expedition_pressure", -1.0).is_empty(), "negative pressure delta fails closed")

	var guardian := _new_session("qa_whisperwood_guardian_drop")
	_check(bool(guardian.call("start_expedition", "Whisperwood")), "guardian run starts")
	_reach_endpoint(guardian, "clearing")
	guardian.expedition_run["cargo"] = {"wood": int(guardian.get("cargo_capacity"))}
	var dropped: Dictionary = guardian.call("resolve_guardian_defeat", "forest_slime")
	_check(bool(dropped.get("deferred_pickup", false)), "full satchel defers guardian reward")
	_check(not str(dropped.get("pickup_id", "")).is_empty(), "deferred reward has stable pickup id")
	_check(guardian.expedition_run.get("pickups", []).size() == 1, "deferred reward is a physical pickup")
	_check(guardian.expedition_run.get("defeated_guardian_ids", []).has("forest_slime"), "guardian defeat is durable before pickup")
	_check(bool(guardian.call("save_game")), "deferred reward saves")
	var guardian_reload := SessionScript.new()
	guardian_reload.save_slot = "qa_whisperwood_guardian_drop"
	root.add_child(guardian_reload)
	_check(bool(guardian_reload.call("load_game")), "deferred reward reloads")
	_check(guardian_reload.expedition_run.get("pickups", []).size() == 1, "deferred reward survives reload")
	var pickup_id := str(guardian_reload.expedition_run.get("pickups", [])[0].get("pickup_id", ""))
	_check(guardian_reload.call("collect_expedition_pickup", pickup_id).is_empty(), "full satchel cannot collect reward")
	guardian_reload.expedition_run["cargo"] = {"wood": int(guardian_reload.get("cargo_capacity")) - 1}
	var collected: Dictionary = guardian_reload.call("collect_expedition_pickup", pickup_id)
	_check(int(collected.get("amount", 0)) == 1, "reward collects once space exists")
	_check(guardian_reload.expedition_run.get("pickups", []).is_empty(), "physical reward clears after collection")
	_check(int(guardian_reload.expedition_run.get("cargo", {}).get("slime_gel", 0)) == 1, "guardian reward enters expedition cargo")
	_check(guardian_reload.call("resolve_guardian_defeat", "forest_slime").is_empty(), "guardian cannot mint a second reward")

	if failures > 0:
		print("WHISPERWOOD_PRESSURE_REWARD_TESTS_FAIL failures=%d checks=%d" % [failures, checks])
		quit(1)
		return
	print("WHISPERWOOD_PRESSURE_REWARD_TESTS_PASS checks=%d" % checks)
	quit(0)
