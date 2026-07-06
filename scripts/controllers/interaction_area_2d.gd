extends Area2D
class_name GuanghanInteractionArea2D

@export var target_id := ""
@export var target_kind := "interact"
@export var label := ""
@export var prompt := ""
@export var near_radius := 95.0

static func is_point_near_rect(point: Vector2, rect: Rect2, radius: float = 95.0) -> bool:
	var nearest := Vector2(
		clamp(point.x, rect.position.x, rect.end.x),
		clamp(point.y, rect.position.y, rect.end.y)
	)
	return point.distance_to(nearest) <= radius

static func is_point_inside_rect(point: Vector2, rect: Rect2) -> bool:
	return rect.has_point(point)

static func feet_point_from_top_left(top_left: Vector2, size: Vector2) -> Vector2:
	return top_left + Vector2(size.x * 0.5, size.y)

static func center_point_from_top_left(top_left: Vector2, size: Vector2) -> Vector2:
	return top_left + size * 0.5
