extends SceneTree

## Verifies the user's LATEST full (untruncated) redrawn collision polygon
## against Godot's actual Geometry2D.intersect_polygons() -- the same
## function _rect_hits_any_polygon_blocker() in training_base_map.gd calls --
## before touching any game code. Design-space points below are the source
## (1520x1040) export halved to the 760x520 design space, exactly as pasted
## by the user, with NO truncation of the corner-hugging tail this time.

const NEW_COLLISION: PackedVector2Array = [
	Vector2(122.5, 95.5), Vector2(349.5, 94), Vector2(374, 62), Vector2(398.5, 62),
	Vector2(428.5, 93.5), Vector2(648, 96.5), Vector2(654.5, 210), Vector2(678, 212.5),
	Vector2(680.5, 263.5), Vector2(660, 288), Vector2(666.5, 408), Vector2(582.5, 406),
	Vector2(580, 424), Vector2(431.5, 427.5), Vector2(406.5, 456.5), Vector2(346.5, 447.5),
	Vector2(330.5, 424), Vector2(174.5, 429.5), Vector2(175.5, 411.5), Vector2(169.5, 405.5),
	Vector2(148, 405.5), Vector2(130, 389.5), Vector2(90, 386.5), Vector2(97.5, 280),
	Vector2(84.5, 252.5), Vector2(94.5, 216), Vector2(109.5, 207.5), Vector2(116.5, 99.5),
	Vector2(68, 106.5), Vector2(36.5, 477.5), Vector2(721.5, 479.5), Vector2(682.5, 25.5),
	Vector2(82.5, 23.5), Vector2(72.5, 98.5),
]

func _rect_poly(center: Vector2, half: float = 6.0) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(-half, -half),
		center + Vector2(half, -half),
		center + Vector2(half, half),
		center + Vector2(-half, half),
	])

func _test(label: String, poly: PackedVector2Array, point: Vector2) -> void:
	var rect := _rect_poly(point)
	var result: Array = Geometry2D.intersect_polygons(rect, poly)
	var blocked: bool = not result.is_empty()
	print("%s @ %s -> blocked=%s" % [label, point, blocked])

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- NEW full redrawn collision polygon (34 pts, untruncated) ---")
	_test("top_wall_clear (expect BLOCKED)", NEW_COLLISION, Vector2(300, 50))
	_test("right_wall_clear (expect BLOCKED)", NEW_COLLISION, Vector2(700, 300))
	_test("bottom_wall_clear (expect BLOCKED)", NEW_COLLISION, Vector2(400, 470))
	_test("floor_center (expect open)", NEW_COLLISION, Vector2(380, 260))
	_test("door_suit_target_center (expect open)", NEW_COLLISION, Vector2(107, 245.25))
	_test("door_power_target_center (expect open)", NEW_COLLISION, Vector2(387.75, 89.5))
	_test("door_air_target_center (expect open)", NEW_COLLISION, Vector2(652, 246))
	_test("door_greenhouse_target_center (expect open)", NEW_COLLISION, Vector2(380.75, 432))
	_test("current_player_start (expect open)", NEW_COLLISION, Vector2(359, 356))
	_test("terminal_area (expect open, separate blocker rect handles it)", NEW_COLLISION, Vector2(383, 232))
	quit()
