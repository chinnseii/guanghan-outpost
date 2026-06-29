extends Node

var backend: Node

func set_backend(node: Node) -> void:
	backend = node

func play_ui(frequency: float = 660.0, duration: float = 0.08, volume: float = 0.08) -> void:
	if is_instance_valid(backend) and backend.has_method("play_tone"):
		backend.call("play_tone", frequency, duration, volume)

func play_event(event_name: String) -> void:
	if is_instance_valid(backend) and backend.has_method("play_event"):
		backend.call("play_event", event_name)

func stop_all() -> void:
	if is_instance_valid(backend):
		if backend.has_method("_exit_tree"):
			backend.call("_exit_tree")
