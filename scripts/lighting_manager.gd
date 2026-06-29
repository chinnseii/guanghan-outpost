extends Node

var global_light: CanvasModulate
var registered_lights: Dictionary = {}

func bind_global_light(light: CanvasModulate) -> void:
	global_light = light

func set_global_color(color: Color) -> void:
	if is_instance_valid(global_light):
		global_light.color = color

func register_light(light_id: String, light: Node) -> void:
	if light_id.is_empty():
		return
	registered_lights[light_id] = light

func set_light_enabled(light_id: String, enabled: bool) -> void:
	var light: Node = registered_lights.get(light_id)
	if light == null:
		return
	if light is Light2D:
		light.set("enabled", enabled)
	elif light is CanvasItem:
		(light as CanvasItem).visible = enabled

func serialize() -> Dictionary:
	var states: Dictionary = {}
	for key: String in registered_lights.keys():
		var light: Node = registered_lights[key]
		if light is Light2D:
			states[key] = bool(light.get("enabled"))
		elif light is CanvasItem:
			states[key] = (light as CanvasItem).visible
	return states

func deserialize(data: Dictionary) -> void:
	for key: String in data.keys():
		set_light_enabled(key, bool(data[key]))
