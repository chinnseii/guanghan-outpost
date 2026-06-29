extends Node

var locked := false
var locked_position := Vector2.ZERO
var smoothing_speed := 6.0
var min_zoom := 0.7
var max_zoom := 1.6

func configure(camera: Camera2D) -> void:
	if not is_instance_valid(camera):
		return
	camera.enabled = true
	camera.rotation = 0.0
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = smoothing_speed

func lock_to(pos: Vector2) -> void:
	locked = true
	locked_position = pos

func unlock() -> void:
	locked = false

func apply_zoom(camera: Camera2D, zoom_value: float) -> float:
	var clamped: float = clamp(zoom_value, min_zoom, max_zoom)
	if is_instance_valid(camera):
		camera.zoom = Vector2(clamped, clamped)
	return clamped

func update_camera(camera: Camera2D, follow_target: Vector2, zoom_value: float) -> void:
	if not is_instance_valid(camera):
		return
	configure(camera)
	camera.position = locked_position if locked else follow_target
	apply_zoom(camera, zoom_value)

func serialize() -> Dictionary:
	return {
		"locked": locked,
		"locked_position": {"x": locked_position.x, "y": locked_position.y},
	}

func deserialize(data: Dictionary) -> void:
	locked = bool(data.get("locked", false))
	var pos: Dictionary = data.get("locked_position", {"x": 0.0, "y": 0.0})
	locked_position = Vector2(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)))
