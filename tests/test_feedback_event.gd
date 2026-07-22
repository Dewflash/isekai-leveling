extends SceneTree

const FeedbackEventScript = preload("res://scripts/feedback_event.gd")

func _init() -> void:
	var impact: Dictionary = FeedbackEventScript.make(
		"attack_hit",
		Vector3(1.0, 2.0, 3.0),
		Vector3(3.0, 1.0, 0.0),
		1.5,
		"metal",
		"player",
		{"guard_break": true},
	)
	assert(impact.get("action") == "attack_hit")
	assert(impact.get("surface") == "metal")
	var impact_direction: Vector3 = impact.get("direction")
	assert(is_equal_approx(impact_direction.length(), 1.0))
	assert(impact.get("audio_kind") == "guard_break")
	assert(is_equal_approx(float(impact.get("camera_shake", 0.0)), 0.11))
	assert(int(impact.get("haptic_duration_ms", 0)) == 30)

	var fallback: Dictionary = FeedbackEventScript.make("step", Vector3.ZERO, Vector3.ZERO, 1.0, "unknown")
	assert(fallback.get("surface") == "grass")
	assert(fallback.get("audio_kind") == "step_grass")
	print("FEEDBACK_EVENT_TESTS_PASS")
	quit()
