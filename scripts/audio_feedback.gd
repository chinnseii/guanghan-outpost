extends Node

var audio_player: AudioStreamPlayer

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "ActionTonePlayer"
	add_child(audio_player)

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
