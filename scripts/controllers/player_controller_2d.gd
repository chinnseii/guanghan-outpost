extends RefCounted
class_name GuanghanPlayerController2D

const DEFAULT_TIME_STEP_PIXELS := 64.0

var position := Vector2.ZERO
var size := Vector2(32, 48)
var speed := 220.0
var bounds := Rect2(Vector2.ZERO, Vector2(1600, 900))
var uses_center_position := false
var time_step_pixels := DEFAULT_TIME_STEP_PIXELS
var time_action := "move"
var time_manager: Node
## Optional: when set (and it responds to on_player_moved_tiles), movement
## time/multipliers/suit drain are fully delegated to MovementTimeManager
## instead of the flat "1 minute per step" fallback below. terrain_type/
## movement_context are only read by that delegated path.
var movement_time_manager: Node
var terrain_type := "indoor"
var movement_context := "mission"

var _distance_accumulator := 0.0

func configure(start_position: Vector2, player_size: Vector2, move_speed: float, world_bounds: Rect2, use_center: bool = false, manager: Node = null) -> void:
	position = start_position
	size = player_size
	speed = move_speed
	bounds = world_bounds
	uses_center_position = use_center
	time_manager = manager
	_distance_accumulator = 0.0

func set_time_manager(manager: Node) -> void:
	time_manager = manager

func set_movement_time_manager(manager: Node) -> void:
	movement_time_manager = manager

func sync_position(new_position: Vector2) -> void:
	position = _clamped_position(new_position)

func move_with_actions(delta: float, left_action: String, right_action: String, up_action: String, down_action: String) -> Dictionary:
	var direction := Vector2.ZERO
	direction.x = Input.get_axis(left_action, right_action)
	direction.y = Input.get_axis(up_action, down_action)
	return move_in_direction(direction, delta)

func move_in_direction(direction: Vector2, delta: float) -> Dictionary:
	if direction.length() > 1.0:
		direction = direction.normalized()
	var old_position := position
	position = _clamped_position(position + direction * speed * delta)
	var moved_distance := old_position.distance_to(position)
	var advanced_steps := _advance_time_for_distance(moved_distance)
	return {
		"position": position,
		"moved": moved_distance > 0.01,
		"direction": direction,
		"distance": moved_distance,
		"advanced_steps": advanced_steps,
	}

func _clamped_position(candidate: Vector2) -> Vector2:
	var clamped := candidate
	if uses_center_position:
		var half_size := size * 0.5
		clamped.x = clamp(clamped.x, bounds.position.x + half_size.x, bounds.end.x - half_size.x)
		clamped.y = clamp(clamped.y, bounds.position.y + half_size.y, bounds.end.y - half_size.y)
	else:
		clamped.x = clamp(clamped.x, bounds.position.x, bounds.end.x - size.x)
		clamped.y = clamp(clamped.y, bounds.position.y, bounds.end.y - size.y)
	return clamped

func _advance_time_for_distance(moved_distance: float) -> int:
	if moved_distance <= 0.0 or time_step_pixels <= 0.0:
		return 0
	_distance_accumulator += moved_distance
	var steps := int(floor(_distance_accumulator / time_step_pixels))
	if steps <= 0:
		return 0
	_distance_accumulator -= float(steps) * time_step_pixels
	_advance_time_steps(steps)
	return steps

func _advance_time_steps(steps: int) -> void:
	if movement_time_manager != null and movement_time_manager.has_method("on_player_moved_tiles"):
		movement_time_manager.call("on_player_moved_tiles", steps, terrain_type, movement_context)
		return
	# Fallback used only when no MovementTimeManager has been wired in --
	# flat 1-minute-per-step, no health/suit/load/terrain multipliers.
	if time_manager == null or not time_manager.has_method("advance_time"):
		return
	var minutes_per_step := 1
	if time_manager.has_method("action_minutes"):
		minutes_per_step = int(time_manager.call("action_minutes", time_action))
	if minutes_per_step <= 0:
		return
	time_manager.call("advance_time", steps * minutes_per_step, time_action)
