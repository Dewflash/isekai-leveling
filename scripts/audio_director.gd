class_name ProdewtyAudioDirector
extends Node3D

var ambience_player: AudioStreamPlayer
var weather_player: AudioStreamPlayer
var station_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var ambience_playback
var weather_playback
var station_playback
var sfx_playback
var environment := {
	"zone": "Sanctuary",
	"surface": "grass",
	"hour": 10.0,
	"weather": "clear",
	"indoor": false,
	"near_furnace": false,
}
var phases := {"ambience": 0.0, "weather": 0.0, "station": 0.0, "sfx": 0.0}
var sfx_kind := "none"
var sfx_time := 0.0
var audio_enabled := true
var sampled_streams: Dictionary = {}
var sampled_players: Array[AudioStreamPlayer] = []
var spatial_players: Array[AudioStreamPlayer3D] = []
var sampled_cursor := 0
var spatial_cursor := 0
var music_streams: Dictionary = {}
var current_music := ""
var music_transition: Tween
var audio_focus_lost := false
var playback_paused := false
var last_action_times: Dictionary = {}
var station_sources: Dictionary = {}
var station_source_players: Dictionary = {}
var station_source_playbacks: Dictionary = {}
var station_source_phases: Dictionary = {}
var station_source_contract: Dictionary = {}

const RPG_AUDIO_ROOT := "res://assets/sourced/kenney-rpg-audio/Audio/"
const AUDIO_BUSES := ["Music", "Ambience", "Weather", "Stations", "Effects", "UI"]
const STATION_SAMPLE_RATE := 22050.0

func _ready() -> void:
	# Audio must continue receiving pause/focus notifications so it can stop
	# streams explicitly even while the gameplay tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless":
		audio_enabled = false
		return
	_ensure_buses()
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	music_player.volume_db = -18.0
	add_child(music_player)
	ambience_player = _make_generator_player("Ambience", -18.0)
	weather_player = _make_generator_player("Weather", -22.0)
	station_player = _make_generator_player("Stations", -16.0)
	sfx_player = _make_generator_player("Effects", -10.0)
	ambience_playback = ambience_player.get_stream_playback()
	weather_playback = weather_player.get_stream_playback()
	station_playback = station_player.get_stream_playback()
	sfx_playback = sfx_player.get_stream_playback()
	_load_sampled_assets()
	_load_music_assets()

func _load_music_assets() -> void:
	music_streams = {
		"Sanctuary": load("res://assets/sourced/cc0-music/sanctuary-loop.ogg"),
		"Expedition": load("res://assets/sourced/cc0-music/expedition-loop.ogg"),
	}
	for stream in music_streams.values():
		if stream is AudioStreamOggVorbis:
			stream.loop = true

func _load_sampled_assets() -> void:
	# Kenney's CC0 recordings provide recognizable foley while the procedural
	# layers continue to carry weather, wind, and dynamic world tone.
	sampled_streams = {
		"step_grass": load(RPG_AUDIO_ROOT + "footstep01.ogg"),
		"step_dirt": load(RPG_AUDIO_ROOT + "footstep03.ogg"),
		"step_sand": load(RPG_AUDIO_ROOT + "footstep05.ogg"),
		"step_stone": load(RPG_AUDIO_ROOT + "footstep07.ogg"),
		"step_wood": load(RPG_AUDIO_ROOT + "footstep09.ogg"),
		"step": load(RPG_AUDIO_ROOT + "footstep00.ogg"),
		"gather_wood": load(RPG_AUDIO_ROOT + "chop.ogg"),
		"gather_stone": load(RPG_AUDIO_ROOT + "metalClick.ogg"),
		"gather_ore": load(RPG_AUDIO_ROOT + "metalPot2.ogg"),
		"gather_fiber": load(RPG_AUDIO_ROOT + "cloth1.ogg"),
		"gather_shell": load(RPG_AUDIO_ROOT + "handleSmallLeather.ogg"),
		"gather_sunstone": load(RPG_AUDIO_ROOT + "metalPot3.ogg"),
		"gather_water": load(RPG_AUDIO_ROOT + "handleSmallLeather2.ogg"),
		"fishing_cast": load(RPG_AUDIO_ROOT + "handleSmallLeather2.ogg"),
		"fishing_bite": load(RPG_AUDIO_ROOT + "handleCoins.ogg"),
		"fishing_hook": load(RPG_AUDIO_ROOT + "cloth1.ogg"),
		"fishing_reel": load(RPG_AUDIO_ROOT + "metalClick.ogg"),
		"fishing_catch": load(RPG_AUDIO_ROOT + "handleCoins.ogg"),
		"fishing_escape": load(RPG_AUDIO_ROOT + "clothBelt.ogg"),
		"hit": load(RPG_AUDIO_ROOT + "knifeSlice.ogg"),
		"guard": load(RPG_AUDIO_ROOT + "metalClick.ogg"),
		"guard_break": load(RPG_AUDIO_ROOT + "metalPot1.ogg"),
		"discovery": load(RPG_AUDIO_ROOT + "bookOpen.ogg"),
		"quest": load(RPG_AUDIO_ROOT + "handleCoins.ogg"),
		"craft": load(RPG_AUDIO_ROOT + "metalPot1.ogg"),
		"build": load(RPG_AUDIO_ROOT + "creak1.ogg"),
		"repair": load(RPG_AUDIO_ROOT + "metalClick.ogg"),
		"collect": load(RPG_AUDIO_ROOT + "handleSmallLeather2.ogg"),
		"pickup": load(RPG_AUDIO_ROOT + "handleSmallLeather2.ogg"),
		"eat": load(RPG_AUDIO_ROOT + "metalPot3.ogg"),
		"drink": load(RPG_AUDIO_ROOT + "metalPot2.ogg"),
		"dodge": load(RPG_AUDIO_ROOT + "clothBelt.ogg"),
		"ui": load("res://assets/sourced/kenney-interface-sounds/Audio/click_001.ogg"),
	}
	for index in 4:
		var player := AudioStreamPlayer.new()
		player.name = "SampledEffect%d" % index
		player.bus = "Effects"
		add_child(player)
		sampled_players.append(player)
	for index in 6:
		var spatial_player := AudioStreamPlayer3D.new()
		spatial_player.name = "SpatialEffect%d" % index
		spatial_player.bus = "Effects"
		spatial_player.max_distance = 18.0
		spatial_player.unit_size = 3.0
		spatial_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(spatial_player)
		spatial_players.append(spatial_player)
	ui_player = AudioStreamPlayer.new()
	ui_player.name = "UISampledPlayer"
	ui_player.bus = "UI"
	add_child(ui_player)

func _ensure_buses() -> void:
	var master_index := AudioServer.get_bus_index("Master")
	if master_index < 0:
		AudioServer.add_bus()
		master_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(master_index, "Master")
	for bus_name in AUDIO_BUSES:
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			AudioServer.add_bus()
			bus_index = AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(bus_index, bus_name)
		if bus_index != master_index:
			AudioServer.set_bus_send(bus_index, "Master")

func _make_generator_player(label: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = label
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = 0.25
	player.stream = stream
	player.volume_db = volume_db
	player.bus = label
	add_child(player)
	player.play()
	return player

func set_environment(zone: String, surface: String, hour: float, weather: String, indoor: bool, near_furnace: bool) -> void:
	environment = {"zone": zone, "surface": surface, "hour": hour, "weather": weather, "indoor": indoor, "near_furnace": near_furnace}
	var music_key := "Sanctuary" if zone == "Sanctuary" else "Expedition"
	if music_player != null and music_key != current_music and _can_play_audio():
		var stream = music_streams.get(music_key)
		if stream is AudioStream:
			if music_transition != null and music_transition.is_valid():
				music_transition.kill()
			music_transition = create_tween()
			music_transition.tween_property(music_player, "volume_db", -60.0, 0.16)
			music_transition.tween_callback(func() -> void:
				music_player.stream = stream
				music_player.play()
			)
			music_transition.tween_property(music_player, "volume_db", -18.0, 0.34)
			current_music = music_key

func set_station_sources(sources: Array) -> void:
	# Machine audio is a presentation mirror of authoritative station records.
	# Main supplies measured world positions from the active room; this director
	# owns only the spatial players and never creates or advances a job.
	var desired: Dictionary = {}
	for source_value in sources:
		if not (source_value is Dictionary):
			continue
		var source := source_value as Dictionary
		var source_id := str(source.get("id", ""))
		var source_kind := str(source.get("kind", ""))
		var source_position: Variant = source.get("position", Vector3.ZERO)
		if source_id.is_empty() or source_kind.is_empty() or not (source_position is Vector3):
			continue
		var normalized := {
			"id": source_id,
			"kind": source_kind,
			"position": source_position,
			"intensity": clampf(float(source.get("intensity", 1.0)), 0.0, 2.0),
			"max_distance": clampf(float(source.get("max_distance", 11.0)), 3.0, 24.0),
			"spatial": true,
			"bus": "Stations",
		}
		desired[source_id] = normalized
	station_sources = desired
	station_source_contract = desired.duplicate(true)
	if audio_enabled:
		_sync_station_source_players()
	else:
		_clear_station_source_players()

func get_station_source_contract() -> Dictionary:
	return station_source_contract.duplicate(true)

func _sync_station_source_players() -> void:
	var stale_ids: Array[String] = []
	for source_id in station_source_players:
		if not station_sources.has(source_id):
			stale_ids.append(str(source_id))
	for source_id in stale_ids:
		_remove_station_source_player(source_id)
	for source_id in station_sources:
		var source: Dictionary = station_sources.get(source_id, {})
		var player := station_source_players.get(source_id) as AudioStreamPlayer3D
		if player == null or not is_instance_valid(player):
			player = _create_station_source_player(str(source_id), source)
			if player == null:
				continue
		var source_position: Vector3 = source.get("position", Vector3.ZERO)
		player.global_position = source_position
		player.max_distance = float(source.get("max_distance", 11.0))
		player.volume_db = linear_to_db(clampf(float(source.get("intensity", 1.0)) * 0.42, 0.02, 0.84))

func _create_station_source_player(source_id: String, source: Dictionary) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.name = "StationSource_%s" % source_id.replace(":", "_")
	player.bus = "Stations"
	player.max_distance = float(source.get("max_distance", 11.0))
	player.unit_size = 1.8
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = STATION_SAMPLE_RATE
	generator.buffer_length = 0.30
	player.stream = generator
	add_child(player)
	player.global_position = source.get("position", Vector3.ZERO)
	player.play()
	station_source_players[source_id] = player
	station_source_playbacks[source_id] = player.get_stream_playback()
	station_source_phases[source_id] = 0.0
	return player

func _remove_station_source_player(source_id: String) -> void:
	var player := station_source_players.get(source_id) as AudioStreamPlayer3D
	if player != null and is_instance_valid(player):
		player.stop()
		player.queue_free()
	station_source_players.erase(source_id)
	station_source_playbacks.erase(source_id)
	station_source_phases.erase(source_id)

func _clear_station_source_players() -> void:
	var source_ids: Array[String] = []
	for source_id in station_source_players:
		source_ids.append(str(source_id))
	for source_id in source_ids:
		_remove_station_source_player(source_id)

func play_action(kind: String) -> void:
	if not _can_play_audio() or not _allow_action(kind):
		return
	sfx_kind = kind
	sfx_time = 0.24 if kind == "hit" else (0.28 if kind in ["discovery", "quest", "camp"] else (0.18 if kind.begins_with("step") else 0.16))
	phases["sfx"] = 0.0
	var sampled_key := _sampled_key_for(kind)
	var sampled = sampled_streams.get(sampled_key)
	if sampled is AudioStream and not sampled_players.is_empty():
		var player: AudioStreamPlayer = sampled_players[sampled_cursor % sampled_players.size()]
		sampled_cursor += 1
		player.stream = sampled
		player.volume_db = -12.0 if sampled_key == "step" else -8.0
		player.play()
		sfx_time = 0.0

func play_action_at(kind: String, world_position: Vector3) -> void:
	if not _can_play_audio():
		return
	if spatial_players.is_empty():
		play_action(kind)
		return
	var sampled_key := _sampled_key_for(kind)
	var sampled = sampled_streams.get(sampled_key)
	if not sampled is AudioStream:
		play_action(kind)
		return
	if not _allow_action(kind):
		return
	sfx_kind = kind
	sfx_time = 0.24 if kind == "hit" else (0.28 if kind in ["discovery", "quest", "camp"] else (0.18 if kind.begins_with("step") else 0.16))
	phases["sfx"] = 0.0
	var player: AudioStreamPlayer3D = spatial_players[spatial_cursor % spatial_players.size()]
	spatial_cursor += 1
	player.global_position = world_position
	player.stream = sampled
	player.volume_db = -12.0 if sampled_key == "step" else -8.0
	player.play()

func play_feedback(event: Dictionary) -> void:
	if event.is_empty():
		return
	var kind := str(event.get("audio_kind", event.get("action", "ui")))
	var position: Variant = event.get("position", Vector3.ZERO)
	if bool(event.get("spatial", true)) and position is Vector3:
		play_action_at(kind, position)
	else:
		play_action(kind)

func play_ui(kind := "ui") -> void:
	if ui_player == null or not _can_play_audio() or not _allow_action(kind):
		return
	var sampled = sampled_streams.get(kind, sampled_streams.get("ui"))
	if sampled is AudioStream:
		ui_player.stream = sampled
		ui_player.volume_db = -8.0
		ui_player.play()

func set_mix(bus_name: String, volume_db: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, clampf(volume_db, -60.0, 6.0))

func apply_settings(values: Dictionary) -> void:
	# Settings are stored as normalized values so the same save works across
	# desktop, controller, and touch builds. Convert only at the audio boundary.
	var bus_names := {"master": ["Master"], "music": ["Music"], "ambience": ["Ambience"], "weather": ["Weather"], "effects": ["Effects", "Stations"], "ui": ["UI"]}
	for setting_id in ["master", "music", "ambience", "weather", "effects", "ui"]:
		var value := clampf(float(values.get(setting_id, 1.0)), 0.0, 1.0)
		var volume_db := -60.0 if value <= 0.001 else linear_to_db(value)
		for bus_name_value in bus_names[setting_id]:
			set_mix(str(bus_name_value), volume_db)

func _process(delta: float) -> void:
	if not audio_enabled:
		return
	var should_pause := audio_focus_lost or get_tree().paused
	if should_pause != playback_paused:
		_set_playback_paused(should_pause)
	if should_pause:
		return
	phases["ambience"] += delta
	phases["weather"] += delta
	phases["station"] += delta
	phases["sfx"] += delta
	sfx_time = maxf(0.0, sfx_time - delta)
	_fill(ambience_playback, "ambience", 0.0)
	_fill(weather_playback, "weather", 0.0)
	_fill(station_playback, "station", 0.0)
	_fill(sfx_playback, "sfx", 0.0)
	_fill_station_sources()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		audio_focus_lost = true
		_set_playback_paused(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		audio_focus_lost = false
		_set_playback_paused(get_tree().paused)

func _can_play_audio() -> bool:
	return audio_enabled and not audio_focus_lost and not get_tree().paused

func _set_playback_paused(paused: bool) -> void:
	playback_paused = paused
	for player in [music_player, ambience_player, weather_player, station_player, sfx_player, ui_player]:
		if is_instance_valid(player):
			player.stream_paused = paused
	for player in sampled_players:
		if is_instance_valid(player):
			player.stream_paused = paused
	for player in spatial_players:
		if is_instance_valid(player):
			player.stream_paused = paused
	for player in station_source_players.values():
		if is_instance_valid(player):
			(player as AudioStreamPlayer3D).stream_paused = paused
	if music_transition != null and music_transition.is_valid():
		if paused:
			music_transition.pause()
		else:
			music_transition.play()

func _sampled_key_for(kind: String) -> String:
	if kind.begins_with("step") and not sampled_streams.has(kind):
		return "step"
	if kind.begins_with("gather_") and not sampled_streams.has(kind):
		return "gather_wood"
	if kind in ["camp", "gather_prepare"]:
		return "craft"
	return kind

func _action_cooldown_key(kind: String) -> String:
	if kind.begins_with("step"):
		return "step"
	if kind.begins_with("gather_"):
		return "gather"
	if kind == "ui":
		return "ui"
	return kind

func _allow_action(kind: String) -> bool:
	var key := _action_cooldown_key(kind)
	var interval := 0.12 if key == "step" else (0.08 if key == "gather" else (0.06 if key == "ui" else 0.04))
	var now := float(Time.get_ticks_usec()) / 1000000.0
	var previous := float(last_action_times.get(key, -INF))
	if now - previous < interval:
		return false
	last_action_times[key] = now
	return true

func _exit_tree() -> void:
	for player in [music_player, ambience_player, weather_player, station_player, sfx_player, ui_player]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	for player in sampled_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	for player in spatial_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	_clear_station_source_players()
	ambience_playback = null
	weather_playback = null
	station_playback = null
	sfx_playback = null

func _fill(playback, layer: String, _delta: float) -> void:
	if playback == null:
		return
	var frames: int = playback.get_frames_available()
	var sample_rate := 22050.0
	for index in frames:
		var t: float = float(phases[layer]) + float(index) / sample_rate
		var sample := _sample(layer, t)
		playback.push_frame(Vector2(sample, sample))

func _sample(layer: String, t: float) -> float:
	if layer == "ambience":
		var night := 1.0 if float(environment["hour"]) < 6.0 or float(environment["hour"]) >= 20.0 else 0.0
		var wind_frequency := 132.0 if environment["zone"] == "Whisperwood" else 108.0
		var wind_motion := 0.45 + 0.55 * sin(t * TAU * 0.12)
		var wind := 0.0028 * sin(t * TAU * wind_frequency) * wind_motion
		var cricket_pulse := 0.55 + 0.45 * sin(t * TAU * 0.31)
		var crickets := night * 0.0035 * sin(t * TAU * 2500.0) * cricket_pulse
		return wind + crickets
	if layer == "weather":
		if environment["weather"] != "rain":
			return 0.0
		var rain := sin(t * TAU * 720.0) * 0.0012 + sin(t * TAU * 1180.0) * 0.0008
		return rain
	if layer == "station":
		# Once measured spatial sources exist, the global generator must not
		# duplicate them across the whole room. It remains the fallback for legacy
		# Sanctuary furnace presentation and headless contract tests.
		if not environment["near_furnace"] or not station_sources.is_empty():
			return 0.0
		var fire := 0.0035 * sin(t * TAU * 145.0) + 0.002 * sin(t * TAU * 265.0)
		return fire
	if layer == "sfx":
		if sfx_time <= 0.0:
			return 0.0
		var envelope := minf(1.0, sfx_time * 16.0) * minf(1.0, (0.24 - sfx_time) * 22.0 + 0.25)
		if sfx_kind == "hit":
			return sin(t * TAU * 92.0) * 0.07 * envelope
		if sfx_kind == "gather_wood":
			return (sin(t * TAU * 180.0) + sin(t * TAU * 640.0) * 0.4) * 0.045 * envelope
		if sfx_kind == "gather_stone":
			return (sin(t * TAU * 480.0) + sin(t * TAU * 1120.0) * 0.35) * 0.05 * envelope
		if sfx_kind == "gather_fiber":
			return sin(t * TAU * 820.0) * 0.035 * envelope
		if sfx_kind == "gather_ore":
			return (sin(t * TAU * 360.0) + sin(t * TAU * 980.0) * 0.5) * 0.055 * envelope
		if sfx_kind == "gather_shell":
			return sin(t * TAU * 620.0) * 0.032 * envelope
		if sfx_kind == "gather_sunstone":
			return (sin(t * TAU * 520.0) + sin(t * TAU * 1240.0) * 0.4) * 0.05 * envelope
		if sfx_kind == "discovery":
			return (sin(t * TAU * 740.0) + sin(t * TAU * 1110.0)) * 0.035 * envelope
		if sfx_kind == "quest":
			return (sin(t * TAU * 330.0) + sin(t * TAU * 660.0)) * 0.04 * envelope
		if sfx_kind == "camp":
			return (sin(t * TAU * 180.0) + sin(t * TAU * 250.0)) * 0.04 * envelope
		if sfx_kind.begins_with("step_sand"):
			return sin(t * TAU * 150.0) * 0.025 * envelope
		if sfx_kind.begins_with("step_stone"):
			return sin(t * TAU * 410.0) * 0.035 * envelope
		if sfx_kind.begins_with("step_dirt"):
			return sin(t * TAU * 280.0) * 0.028 * envelope
		if sfx_kind.begins_with("step_wood"):
			return sin(t * TAU * 220.0) * 0.03 * envelope
		return sin(t * TAU * 380.0) * 0.04 * envelope
	return 0.0

func _fill_station_sources() -> void:
	for source_id in station_source_playbacks:
		var playback = station_source_playbacks.get(source_id)
		if playback == null or not is_instance_valid(playback):
			continue
		var source: Dictionary = station_sources.get(source_id, {})
		var frames: int = playback.get_frames_available()
		var phase := float(station_source_phases.get(source_id, 0.0))
		var intensity := float(source.get("intensity", 1.0))
		var kind := str(source.get("kind", "furnace"))
		for index in frames:
			var t := phase + float(index) / STATION_SAMPLE_RATE
			var sample := _station_source_sample(kind, t, intensity)
			playback.push_frame(Vector2(sample, sample))
		station_source_phases[source_id] = phase + float(frames) / STATION_SAMPLE_RATE

func _station_source_sample(kind: String, time_seconds: float, intensity: float) -> float:
	if not kind.begins_with("furnace") and kind != "furnace":
		return 0.0
	# A quiet generated fire bed plus deterministic ember crackle keeps the
	# source self-contained and mobile-safe. The spatial player supplies the
	# distance/pan; the station job supplies only the intensity.
	var bed := sin(time_seconds * TAU * 74.0) * 0.0024 + sin(time_seconds * TAU * 131.0) * 0.0015
	var ember_wave := maxf(0.0, sin(time_seconds * TAU * 5.7 + 0.8))
	var crackle := pow(ember_wave, 12.0) * sin(time_seconds * TAU * 620.0) * 0.018
	return (bed + crackle) * clampf(intensity, 0.0, 2.0)
