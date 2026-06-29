extends Node

signal event_triggered(event_name: String, payload: Dictionary)

var fired_events := {}

func trigger(event_name: String, payload: Dictionary = {}, once: bool = false) -> void:
	if event_name.is_empty():
		return
	if once and bool(fired_events.get(event_name, false)):
		return
	fired_events[event_name] = true
	event_triggered.emit(event_name, payload)

func has_fired(event_name: String) -> bool:
	return bool(fired_events.get(event_name, false))

func clear_event(event_name: String) -> void:
	fired_events.erase(event_name)

func serialize() -> Dictionary:
	return fired_events.duplicate(true)

func deserialize(data: Dictionary) -> void:
	fired_events = data.duplicate(true)

func debug_text() -> String:
	return "Events %d" % fired_events.size()
