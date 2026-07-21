class_name ProdewtyFeedbackEvent
extends RefCounted

## Transient action feedback contract. Persistent gameplay state stays in
## GameSession; this record is the shared language for audio, haptics, camera
## response, particles, and UI reaction to one resolved action.

const SURFACES := ["grass", "dirt", "sand", "stone", "wood", "metal", "water", "foliage"]

static func make(action_kind: String, world_position: Vector3 = Vector3.ZERO, direction: Vector3 = Vector3.ZERO, strength: float = 1.0, surface: String = "grass", source: String = "world", metadata: Dictionary = {}) -> Dictionary:
	var clean_direction := direction
	clean_direction.y = 0.0
	if clean_direction.length_squared() > 0.0001:
		clean_direction = clean_direction.normalized()
	var clean_surface := surface if surface in SURFACES else "grass"
	var event := {
		"action": action_kind,
		"position": world_position,
		"direction": clean_direction,
		"strength": clampf(strength, 0.0, 2.0),
		"surface": clean_surface,
		"source": source,
		"audio_kind": _audio_kind(action_kind, clean_surface, metadata),
		"spatial": true,
		"camera_shake": _camera_shake(action_kind, strength, metadata),
		"haptic_duration_ms": _haptic_duration(action_kind, metadata),
		"haptic_amplitude": _haptic_amplitude(action_kind, strength, metadata),
		"metadata": metadata.duplicate(true),
	}
	return event

static func _audio_kind(action_kind: String, surface: String, metadata: Dictionary) -> String:
	var explicit_audio := str(metadata.get("audio_kind", ""))
	if not explicit_audio.is_empty():
		return explicit_audio
	match action_kind:
		"step": return "step_%s" % surface
		"gather_prepare": return "gather_prepare"
		"gather_contact": return "gather_%s" % str(metadata.get("resource_id", "wood"))
		"attack_hit":
			if bool(metadata.get("guard_break", false)):
				return "guard_break"
			if bool(metadata.get("guarded", false)):
				return "guard"
			return "hit"
		"player_hit": return "hit"
		"dodge": return "dodge"
		"build_delivery": return "build"
		"pickup": return "pickup"
	return action_kind

static func _camera_shake(action_kind: String, strength: float, metadata: Dictionary) -> float:
	if metadata.has("camera_shake"):
		return clampf(float(metadata.get("camera_shake", 0.0)), 0.0, 0.25)
	match action_kind:
		"attack_hit":
			return 0.11 if bool(metadata.get("guard_break", false)) else (0.035 if bool(metadata.get("guarded", false)) else 0.06)
		"player_hit": return 0.08
		"dodge": return 0.04
		"gather_contact": return clampf(strength * 0.02, 0.0, 0.04)
	return 0.0

static func _haptic_duration(action_kind: String, metadata: Dictionary) -> int:
	if metadata.has("haptic_duration_ms"):
		return maxi(0, int(metadata.get("haptic_duration_ms", 0)))
	match action_kind:
		"attack_hit": return 30
		"player_hit": return 52
		"dodge": return 28
		"gather_contact": return 16
	return 0

static func _haptic_amplitude(action_kind: String, strength: float, metadata: Dictionary) -> float:
	if metadata.has("haptic_amplitude"):
		return clampf(float(metadata.get("haptic_amplitude", 0.0)), 0.0, 1.0)
	match action_kind:
		"attack_hit": return clampf(0.18 * strength, 0.0, 1.0)
		"player_hit": return 0.35
		"dodge": return 0.18
		"gather_contact": return 0.10
	return 0.0
