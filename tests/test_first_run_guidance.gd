extends SceneTree

const SessionScript := preload("res://scripts/game_session.gd")

var failures: Array[String] = []
var checks := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("FIRST_RUN_FAIL: " + message)

func _run() -> void:
	var session := SessionScript.new()
	_check(int(session.get("quest").get("target", 0)) == 2, "fresh first-run contract matches the two-unit field bundle")
	_check(str(session.call("first_run_stage")) == "meet_mira", "fresh session starts with the Mira objective")
	_check(bool(session.call("advance_first_run", "meet_mira")), "meeting Mira advances the first-run journey")
	_check(str(session.call("first_run_stage")) == "reach_gate", "Mira objective points to the Whisperwood gate")
	_check(not bool(session.call("advance_first_run", "choose_trail")), "the trail cannot be chosen before entering Whisperwood")
	_check(bool(session.call("advance_first_run", "enter_whisperwood")), "entering Whisperwood advances the journey")
	_check(str(session.call("first_run_stage")) == "choose_trail", "route entry exposes the trail choice")
	_check(bool(session.call("advance_first_run", "choose_trail")), "choosing a trail advances the journey")
	_check(str(session.call("first_run_stage")) == "gather", "trail choice exposes the gathering objective")
	_check(bool(session.call("advance_first_run", "field_bundle")), "a field bundle advances the journey")
	_check(str(session.call("first_run_stage")) == "collect_bundle", "field bundle exposes the pickup objective")
	_check(bool(session.call("advance_first_run", "resource_collected")), "collecting the bundle advances the journey")
	_check(str(session.call("first_run_stage")) == "extract", "pickup exposes the return objective")
	_check(bool(session.call("advance_first_run", "extract")), "extraction advances the journey")
	_check(str(session.call("first_run_stage")) == "claim_supply", "extraction exposes the contract claim objective")
	_check(bool(session.call("advance_first_run", "claim_supply")), "claiming the supply reward advances the journey")
	_check(str(session.call("first_run_stage")) == "build_workshop", "the reward exposes the Workshop objective")
	_check(bool(session.call("advance_first_run", "workshop_operational")), "an operational Workshop completes the journey")
	_check(str(session.call("first_run_stage")) == "complete", "the first-run journey reaches a durable complete state")
	_check(bool(session.get("quest").get("first_run_completed", false)), "completion is recorded in the quest save payload")
	var payload: Dictionary = session.call("_to_dict")
	_check(bool(session.call("_save_shape_is_supported", payload)), "the extended quest payload remains save-valid")
	var restored := SessionScript.new()
	restored.call("_apply_dict", payload)
	_check(str(restored.call("first_run_stage")) == "complete", "the completed journey survives state reload")
	_check(bool(restored.get("quest").get("first_run_completed", false)), "reload preserves the completion flag")
	if failures.is_empty():
		print("FIRST_RUN_GUIDANCE_PASS checks=%d" % checks)
		quit(0)
	else:
		print("FIRST_RUN_GUIDANCE_FAIL failures=%d checks=%d" % [failures.size(), checks])
		for failure in failures:
			print("  ", failure)
		quit(1)
