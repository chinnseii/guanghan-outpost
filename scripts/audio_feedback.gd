extends Node

var audio_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "ActionTonePlayer"
	add_child(audio_player)
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientHumPlayer"
	ambient_player.volume_db = -26.0
	add_child(ambient_player)

func play_event(event_name: String) -> void:
	match event_name:
		"airlock":
			play_tone(220.0, 0.16, 0.08)
		"tool":
			play_tone(720.0, 0.07, 0.07)
		"cargo":
			play_tone(480.0, 0.11, 0.08)
		"robot":
			play_tone(960.0, 0.06, 0.07)
		"step":
			play_tone(180.0, 0.025, 0.025)
		"ambient":
			_play_ambient_hum()
		_:
			play_tone()

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

func _play_ambient_hum() -> void:
	if not is_instance_valid(ambient_player):
		return
	var stream: AudioStreamGenerator = AudioStreamGenerator.new()
	stream.mix_rate = 11025.0
	stream.buffer_length = 0.7
	ambient_player.stream = stream
	ambient_player.play()
	var playback: AudioStreamGeneratorPlayback = ambient_player.get_stream_playback()
	if playback == null:
		return
	var frames: int = int(stream.mix_rate * 0.6)
	var phase: float = 0.0
	var increment: float = TAU * 72.0 / stream.mix_rate
	for i in range(frames):
		var sample: float = sin(phase) * 0.015
		playback.push_frame(Vector2(sample, sample))
		phase += increment
