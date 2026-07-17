class_name ProdewtyAudioDirector
extends Node

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
var sampled_cursor := 0
var music_streams: Dictionary = {}
var current_music := ""

func _ready() -> void:
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
		"step": load("res://assets/sourced/kenney-rpg-audio/Audio/footstep00.ogg"),
		"gather_wood": load("res://assets/sourced/kenney-rpg-audio/Audio/chop.ogg"),
		"hit": load("res://assets/sourced/kenney-rpg-audio/Audio/knifeSlice.ogg"),
		"discovery": load("res://assets/sourced/kenney-rpg-audio/Audio/bookOpen.ogg"),
		"quest": load("res://assets/sourced/kenney-rpg-audio/Audio/handleCoins.ogg"),
		"craft": load("res://assets/sourced/kenney-rpg-audio/Audio/metalPot1.ogg"),
		"ui": load("res://assets/sourced/kenney-interface-sounds/Audio/click_001.ogg"),
	}
	for index in 4:
		var player := AudioStreamPlayer.new()
		player.name = "SampledEffect%d" % index
		player.bus = "Effects"
		add_child(player)
		sampled_players.append(player)
	ui_player = AudioStreamPlayer.new()
	ui_player.name = "UISampledPlayer"
	ui_player.bus = "UI"
	add_child(ui_player)

func _ensure_buses() -> void:
	for bus_name in ["Music", "Ambience", "Weather", "Stations", "Effects", "UI"]:
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			AudioServer.add_bus()
			bus_index = AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(bus_index, bus_name)
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
	if music_player != null and music_key != current_music:
		var stream = music_streams.get(music_key)
		if stream is AudioStream:
			music_player.stream = stream
			music_player.play()
			current_music = music_key

func play_action(kind: String) -> void:
	sfx_kind = kind
	sfx_time = 0.24 if kind == "hit" else (0.28 if kind in ["discovery", "quest", "camp"] else (0.18 if kind.begins_with("step") else 0.16))
	phases["sfx"] = 0.0
	var sampled_key := kind
	if kind.begins_with("step"):
		sampled_key = "step"
	elif kind.begins_with("gather_") and not sampled_streams.has(kind):
		sampled_key = "gather_wood" if kind == "gather_wood" else "ui"
	elif kind in ["repair", "collect", "eat", "drink", "camp"]:
		sampled_key = "craft"
	var sampled = sampled_streams.get(sampled_key)
	if sampled is AudioStream and not sampled_players.is_empty():
		var player: AudioStreamPlayer = sampled_players[sampled_cursor % sampled_players.size()]
		sampled_cursor += 1
		player.stream = sampled
		player.volume_db = -12.0 if sampled_key == "step" else -8.0
		player.play()
		sfx_time = 0.0

func play_ui(kind := "ui") -> void:
	if ui_player == null:
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

func _process(delta: float) -> void:
	if not audio_enabled:
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

func _exit_tree() -> void:
	for player in [music_player, ambience_player, weather_player, station_player, sfx_player, ui_player]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	for player in sampled_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
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
		if not environment["near_furnace"]:
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
