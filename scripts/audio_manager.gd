extends Node
class_name ShiftAudio

var ambience: AudioStreamPlayer
var music: AudioStreamPlayer
var rain: AudioStreamPlayer
var buzz: AudioStreamPlayer
var effects: Array[AudioStreamPlayer] = []
var enabled: bool = false
var phase: float = 0.0

func _ready() -> void:
	for i in range(7):
		var player = AudioStreamPlayer.new()
		add_child(player)
		effects.append(player)
	ambience = AudioStreamPlayer.new()
	music = AudioStreamPlayer.new()
	add_child(ambience)
	add_child(music)
	rain = AudioStreamPlayer.new()
	buzz = AudioStreamPlayer.new()
	add_child(rain)
	add_child(buzz)

func play(cue: String) -> void:
	if not enabled: return
	if cue == "footsteps": cue = "footstep"
	var path = "res://assets/audio/" + cue + ".wav"
	if not ResourceLoader.exists(path): return
	for player in effects:
		if not player.playing:
			player.stream = load(path)
			player.volume_db = -9.0
			player.play()
			return

func begin() -> void:
	silence()
	phase = 0.0
	music.pitch_scale = 1.0
	enabled = true
	loop_on(ambience, "hum", -20)
	loop_on(music, "music", -24)
	loop_on(rain, "rain", -31)
	loop_on(buzz, "buzz", -35)

func loop_on(player: AudioStreamPlayer, cue: String, db: float) -> void:
	var path = "res://assets/audio/" + cue + ".wav"
	if not ResourceLoader.exists(path): return
	var stream: AudioStreamWAV = load(path).duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	player.stream = stream
	player.volume_db = db
	player.play()

func escalate(value: float, mistakes: int) -> void:
	phase = value
	music.volume_db = -24.0 - value * 16.0
	music.pitch_scale = 1.0 - value * 0.04
	ambience.volume_db = -21.0 + mistakes * 2.0 + value * 4.0
	buzz.volume_db = -35.0 + value * 7.0 + mistakes * 2.0
	if value > 0.7 and mistakes > 0:
		loop_on(music, "tension", -30)

func silence() -> void:
	ambience.stop()
	music.stop()
	rain.stop()
	buzz.stop()
	for player in effects: player.stop()

func set_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.0001)))
	AudioServer.set_bus_mute(0, value <= 0.001)
