extends SceneTree

## Verifies the user's newest room_boundary redraw (2026-07-24, drawn with the
## room_boundary/solid_blocker split tool) before touching any game code.

const NEW_BOUNDARY: PackedVector2Array = [
	Vector2(118.5, 99.5), Vector2(350.0, 101.5), Vector2(369.5, 77.5), Vector2(416.0, 77.0),
	Vector2(430.5, 99.0), Vector2(646.0, 95.5), Vector2(652.0, 226.5), Vector2(665.5, 234.5),
	Vector2(667.5, 261.5), Vector2(654.0, 277.0), Vector2(669.5, 408.5), Vector2(584.5, 408.5),
	Vector2(586.5, 426.5), Vector2(427.5, 431.5), Vector2(410.5, 446.5), Vector2(355.5, 447.5),
	Vector2(338.5, 427.0), Vector2(174.5, 429.5), Vector2(173.5, 406.5), Vector2(142.5, 405.5),
	Vector2(131.5, 390.5), Vector2(88.0, 389.0), Vector2(101.5, 280.5), Vector2(88.0, 261.0),
	Vector2(92.5, 223.5), Vector2(110.5, 215.5),
]

func _rect_poly(center: Vector2, half: float = 6.0) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(-half, -half), center + Vector2(half, -half),
		center + Vector2(half, half), center + Vector2(-half, half),
	])

func _polygon_area(poly: PackedVector2Array) -> float:
	var area := 0.0
	var n := poly.size()
	for i in range(n):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % n]
		area += a.x * b.y - b.x * a.y
	return absf(area) * 0.5

func _blocked(point: Vector2) -> bool:
	var rect := _rect_poly(point)
	var rect_area := _polygon_area(rect)
	var covered := 0.0
	for piece: PackedVector2Array in Geometry2D.intersect_polygons(rect, NEW_BOUNDARY):
		covered += _polygon_area(piece)
	return covered < rect_area - 0.01

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- wall points (expect BLOCKED) ---")
	print("top_wall (300,50): ", _blocked(Vector2(300, 50)))
	print("right_wall (700,300): ", _blocked(Vector2(700, 300)))
	print("bottom_wall (400,470): ", _blocked(Vector2(400, 470)))
	print("left_wall (50,150): ", _blocked(Vector2(50, 150)))

	print("--- floor / doors (expect OPEN) ---")
	print("floor_center (380,260): ", _blocked(Vector2(380, 260)))
	print("door_power_target_center (387.75,89.5): ", _blocked(Vector2(387.75, 89.5)))
	print("door_air_target_center (652,246): ", _blocked(Vector2(652, 246)))
	print("door_greenhouse_target_center (380.75,432): ", _blocked(Vector2(380.75, 432)))
	print("door_suit_target_center (107,245.25): ", _blocked(Vector2(107, 245.25)))
	print("player_start (359,356): ", _blocked(Vector2(359, 356)))
	print("new_door_power_trigger_center (391.25,79): ", _blocked(Vector2(391.25, 79)))
	print("new_door_air_trigger_center (665.75,251.5): ", _blocked(Vector2(665.75, 251.5)))
	print("new_door_greenhouse_trigger_center (385,445.25): ", _blocked(Vector2(385, 445.25)))
	print("new_door_suit_trigger_center (91.25,244): ", _blocked(Vector2(91.25, 244)))
	quit()
