extends SceneTree

## Verifies the proposed room_boundary/solid_blocker model before wiring it
## into game code: room_boundary is the room's own floor outline (inside =
## walkable), tested via Geometry2D.exclude_polygons(footprint, boundary) --
## non-empty leftover means part of the footprint pokes outside the floor,
## i.e. blocked. This is the same 29-point interior trace already confirmed
## (via Python winding-number + self-intersection checks) to be a clean,
## unambiguous simple polygon -- no border-hugging "keyhole" tail needed at
## all, which is the whole point: this shape means the same thing under any
## fill rule.

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

func _blocked_by_boundary(point: Vector2) -> bool:
	var rect := _rect_poly(point)
	var leftover: Array = Geometry2D.exclude_polygons(rect, ROOM_BOUNDARY)
	return not leftover.is_empty()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- room_boundary model (exclude_polygons-based, inside=floor) ---")
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
	quit()
