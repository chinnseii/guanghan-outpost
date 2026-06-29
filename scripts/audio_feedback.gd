extends Node

var audio_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var ambient_phase := 0.0
var ambient_enabled := false

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "ActionTonePlayer"
	add_child(audio_player)
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientHumPlayer"
	ambient_player.volume_db = -26.0
	add_child(ambient_player)
	set_process(true)

func play_event(event_name: String) -> void:
	match event_name:
		"airlock":
			play_pattern([220.0, 330.0, 190.0], 0.055, 0.07)
		"tool":
			play_pattern([720.0, 860.0], 0.035, 0.055)
		"cargo":
			play_pattern([360.0, 420.0, 300.0], 0.045, 0.07)
		"robot":
			play_pattern([960.0, 1280.0], 0.03, 0.055)
		"step":
			play_tone(180.0, 0.025, 0.025)
		"ambient":
			_start_ambient_hum()
		_:
			play_tone()

func _process(_delta: float) -> void:
	if ambient_enabled:
		_fill_ambient_hum()

func _exit_tree() -> void:
	ambient_enabled = false
	if is_instance_valid(ambient_player):
		ambient_player.stop()
		ambient_player.stream = null
	if is_instance_valid(audio_player):
		audio_player.stop()
		audio_player.stream = null

func play_tone(frequency: float = 660.0, duration: float = 0.08, volume: float = 0.08) -> void:
	if not is_instance_valid(audio_player):
		return
	var stream: AudioStreamGenerator = AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = max(0.05, duration + 0.03)
	audio_player.stream = stream
	audio_player.play()
	var playback: AudioStreamGeneratorPlayback = audio_player.get_stream_playback()
	if playback == null:
		return
	var frames: int = int(stream.mix_rate * duration)
	var phase: float = 0.0
	var increment: float = TAU * frequency / stream.mix_rate
	for i in range(frames):
		var fade: float = 1.0 - float(i) / float(max(1, frames))
		var sample: float = sin(phase) * volume * fade
		playback.push_frame(Vector2(sample, sample))
		phase += increment
	playback = null

func play_pattern(frequencies: Array[float], note_duration: float, volume: float) -> void:
	if not is_instance_valid(audio_player):
		return
	var stream: AudioStreamGenerator = AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = max(0.08, note_duration * float(frequencies.size()) + 0.04)
	audio_player.stream = stream
	audio_player.play()
	var playback: AudioStreamGeneratorPlayback = audio_player.get_stream_playback()
	if playback == null:
		return
	var frames_per_note: int = int(stream.mix_rate * note_duration)
	for frequency: float in frequencies:
		var phase: float = 0.0
		var increment: float = TAU * frequency / stream.mix_rate
		for i in range(frames_per_note):
			var fade: float = 1.0 - float(i) / float(max(1, frames_per_note))
			var sample: float = sin(phase) * volume * fade
			playback.push_frame(Vector2(sample, sample))
			phase += increment
	playback = null

func _start_ambient_hum() -> void:
	if not is_instance_valid(ambient_player):
		return
	if ambient_enabled:
		return
	var stream: AudioStreamGenerator = AudioStreamGenerator.new()
	stream.mix_rate = 11025.0
	stream.buffer_length = 0.8
	ambient_player.stream = stream
	ambient_player.play()
	var playback: AudioStreamGeneratorPlayback = ambient_player.get_stream_playback()
	ambient_enabled = playback != null
	playback = null
	_fill_ambient_hum()

func _fill_ambient_hum() -> void:
	if not is_instance_valid(ambient_player):
		return
	var playback: AudioStreamGeneratorPlayback = ambient_player.get_stream_playback()
	if playback == null:
		return
	var frames: int = playback.get_frames_available()
	var increment: float = TAU * 72.0 / 11025.0
	for i in range(frames):
		var overtone: float = sin(ambient_phase * 0.5) * 0.004
		var sample: float = sin(ambient_phase) * 0.012 + overtone
		playback.push_frame(Vector2(sample, sample))
		ambient_phase += increment
	playback = null
