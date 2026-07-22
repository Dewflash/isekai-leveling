extends SceneTree

const SessionScript = preload("res://scripts/game_session.gd")
const ContentRegistry = preload("res://scripts/content_registry.gd")

var failures := 0
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("EXPEDITION_ROUTE_CONTRACT_FAIL: %s" % message)

func _clear_slot(slot: String) -> void:
	for suffix in [".json", ".backup.json", ".tmp.json"]:
		var path := "user://%s%s" % [slot, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _new_session(slot: String, route_id: String) -> Node:
	_clear_slot(slot)
	var session := SessionScript.new()
	session.save_slot = slot
	root.add_child(session)
	session.energy = 24
	session.coins = 200
	session.get("unlocked_routes").clear()
	var route_order := ["Whisperwood", "Sunlit Beach", "Ember Ridge", "Glass Desert", "Sunken Dungeon"]
	var route_index := route_order.find(route_id)
	for index in range(route_index + 1):
		session.get("unlocked_routes").append(route_order[index])
	session.expedition_run = {"status": "none"}
	return session

func _run() -> void:
	var last_session: Node = null
	var route_cases := [
		{"id": "Sunlit Beach", "branch": "tidepool", "objective_kind": "resource", "objective_id": "shell", "target": 2},
		{"id": "Ember Ridge", "branch": "quarry", "objective_kind": "resource", "objective_id": "ore", "target": 3},
		{"id": "Glass Desert", "branch": "oasis", "objective_kind": "resource", "objective_id": "fiber", "target": 4},
		{"id": "Sunken Dungeon", "branch": "vault", "objective_kind": "discovery", "objective_id": "Aether Relic", "target": 1},
	]
	for route_case in route_cases:
		var route_id := str(route_case["id"])
		var session := _new_session("qa_route_contract_%s" % route_id.replace(" ", "_"), route_id)
		last_session = session
		var arrival := ContentRegistry.expedition_route_socket(route_id, "arrival")
		var fork := ContentRegistry.expedition_route_socket(route_id, "fork")
		var endpoint := ContentRegistry.expedition_route_socket(route_id, str(route_case["branch"]))
		var return_socket := ContentRegistry.expedition_route_socket(route_id, "return")
		_check(arrival != Vector3.ZERO and fork != Vector3.ZERO and endpoint != Vector3.ZERO and return_socket != Vector3.ZERO, "%s publishes all route sockets" % route_id)
		_check(session.start_expedition(route_id), "%s starts" % route_id)
		_check(not session.commit_expedition_branch(str(route_case["branch"])), "%s cannot commit before its fork" % route_id)
		_check(session.record_route_checkpoint("arrival"), "%s records arrival" % route_id)
		_check(session.record_route_checkpoint("fork"), "%s records fork" % route_id)
		_check(session.commit_expedition_branch(str(route_case["branch"])), "%s commits its authored branch" % route_id)
		_check(not session.record_expedition_endpoint("other_branch"), "%s rejects a mismatched endpoint" % route_id)
		_check(session.record_expedition_endpoint(str(route_case["branch"])), "%s records its physical endpoint" % route_id)
		_check(str(session.expedition_run.get("route_phase", "")) == "objective", "%s opens objective only after endpoint" % route_id)
		_check(session.call("_advance_expedition_objective", str(route_case["objective_kind"]), str(route_case["objective_id"]), int(route_case["target"])), "%s advances its branch objective" % route_id)
		_check(bool(session.expedition_run.get("objective_complete", false)), "%s completes objective" % route_id)
		_check(not session.open_expedition_capstone().is_empty(), "%s opens capstone" % route_id)
		_check(session.record_route_checkpoint("return"), "%s records return after capstone" % route_id)
		_check(session.expedition_run.get("route_checkpoints", []) == ["arrival", "fork", "return"], "%s preserves ordered checkpoints" % route_id)
		_check(str(session.expedition_run.get("route_phase", "")) == "return", "%s reaches return phase" % route_id)
		_check(session.save_game(), "%s saves its route contract" % route_id)
		var loaded := SessionScript.new()
		loaded.save_slot = session.save_slot
		root.add_child(loaded)
		_check(loaded.load_game(), "%s reloads its route contract" % route_id)
		_check(loaded.expedition_run.get("route_checkpoints", []) == ["arrival", "fork", "return"], "%s reload preserves checkpoints" % route_id)
		_check(not loaded.expedition_return_checkpoint_required(), "%s does not require a second return crossing" % route_id)

	var legacy_payload: Dictionary = last_session.call("_to_dict")
	legacy_payload["save_version"] = 25
	var legacy_run: Dictionary = legacy_payload["expedition_run"].duplicate(true)
	legacy_run["route_phase"] = "objective"
	legacy_run["route_checkpoints"] = []
	legacy_run["objective_progress"] = 0
	legacy_run["objective_complete"] = false
	legacy_run["shortcut_open"] = false
	legacy_run["cache_claimed"] = false
	legacy_run["stake_active"] = false
	legacy_run["return_checkpoint_crossed"] = false
	legacy_payload["expedition_run"] = legacy_run
	var migrated: Dictionary = last_session.call("_migrate_payload", legacy_payload)
	_check(int(migrated.get("save_version", 0)) == 26, "v25 route saves migrate to v26")
	_check(migrated.get("expedition_run", {}).get("route_checkpoints", []) == ["arrival", "fork"], "v25 objective routes gain only their traversal prefix")
	_check(bool(last_session.call("_save_shape_is_supported", migrated)), "migrated objective route remains save-valid")

	if failures > 0:
		print("EXPEDITION_ROUTE_CONTRACT_TESTS_FAIL failures=%d checks=%d" % [failures, checks])
		quit(1)
		return
	print("EXPEDITION_ROUTE_CONTRACT_TESTS_PASS checks=%d" % checks)
	quit(0)
