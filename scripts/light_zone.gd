extends Area2D
class_name LightZone

@export var zone_id := ""
@export var light_color := Color("#ffd28a")
@export var enabled := true

func set_enabled(value: bool) -> void:
	enabled = value
	visible = enabled
