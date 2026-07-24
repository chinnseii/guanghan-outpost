extends SceneTree

## Re-verifies the room_boundary model using area comparison via
## intersect_polygons() (already proven reliable all session) instead of
## exclude_polygons() (whose output didn't match a plain A-B subtraction --
## see capture_tr002_exclude_debug.gd). "Blocked" = the footprint's
## intersection with room_boundary covers LESS than the footprint's own area,
## i.e. some part of it pokes outside the floor.

const ROOM_BOUNDARY: PackedVector2Array = [
	Vector2(122.5, 95.5), Vector2(349.5, 94), Vector2(374, 62), Vector2(398.5, 62),
	Vector2(428.5, 93.5), Vector2(648, 96.5), Vector2(654.5, 210), Vector2(678, 212.5),
	Vector2(680.5, 263.5), Vector2(660, 288), Vector2(666.5, 408), Vector2(582.5, 406),
	Vector2(580, 424), Vector2(431.5, 427.5), Vector2(406.5, 456.5), Vector2(346.5, 447.5),
	Vector2(330.5, 424), Vector2(174.5, 429.5), Vector2(175.5, 411.5), Vector2(169.5, 405.5),
	Vector2(148, 405.5), Vector2(130, 389.5), Vector2(90, 386.5), Vector2(97.5, 280),
	Vector2(84.5, 252.5), Vector2(94.5, 216), Vector2(109.5, 207.5), Vector2(116.5, 99.5),
	Vector2(68, 106.5),
]

func _rect_poly(center: Vector2, half: float = 6.0) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(-half, -half),
		center + Vector2(half, -half),
		center + Vector2(half, half),
		center + Vector2(-half, half),
	])

func _polygon_area(poly: PackedVector2Array) -> float:
	var area := 0.0
	var n := poly.size()
	for i in range(n):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % n]
		area += a.x * b.y - b.x * a.y
	return abs(area) * 0.5

func _blocked_by_boundary(point: Vector2) -> bool:
	var rect := _rect_poly(point)
	var rect_area := _polygon_area(rect)
	var pieces: Array = Geometry2D.intersect_polygons(rect, ROOM_BOUNDARY)
	var covered := 0.0
	for p: PackedVector2Array in pieces:
		covered += _polygon_area(p)
	return covered < rect_area - 0.01

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- room_boundary model (area-comparison via intersect_polygons) ---")
	print("floor_center (expect NOT blocked): ", _blocked_by_boundary(Vector2(380, 260)))
	print("wall_corner_top_left (expect BLOCKED): ", _blocked_by_boundary(Vector2(20, 20)))
	print("top_wall_clear (expect BLOCKED): ", _blocked_by_boundary(Vector2(300, 50)))
	print("right_wall_clear (expect BLOCKED): ", _blocked_by_boundary(Vector2(700, 300)))
	print("bottom_wall_clear (expect BLOCKED): ", _blocked_by_boundary(Vector2(400, 470)))
	print("door_air_center (expect NOT blocked): ", _blocked_by_boundary(Vector2(652, 246)))
	print("door_greenhouse_center (expect NOT blocked): ", _blocked_by_boundary(Vector2(380.75, 432)))
	print("door_power_center (expect NOT blocked): ", _blocked_by_boundary(Vector2(387.75, 89.5)))
	print("door_suit_center (expect NOT blocked): ", _blocked_by_boundary(Vector2(107, 245.25)))
	print("player_start (expect NOT blocked): ", _blocked_by_boundary(Vector2(359, 356)))
	print("straddling_boundary_point (west of door_suit recess wall edge, expect BLOCKED): ", _blocked_by_boundary(Vector2(60, 300)))
	quit()
