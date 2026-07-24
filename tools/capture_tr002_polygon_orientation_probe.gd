extends SceneTree

## Diagnostic: settle whether the "inside=wall" classification discrepancy
## found between the Round-1 collision polygon (implemented, verified working
## in-game) and the user's freshly re-traced polygon is real, by testing with
## the ACTUAL function the game uses (Geometry2D.intersect_polygons() via a
## small footprint rect), not a hand-written point-in-polygon reimplementation.
## A "spike" edge (out to a far point and back near-identically) has zero
## area and may be silently ignored by area-based intersection even though it
## flips a point-membership test -- this script checks whether that's what
## makes Round-1 "work" despite carrying the same corner-jump tail pattern.

const ROUND1: PackedVector2Array = [
	Vector2(127, 93), Vector2(343, 96), Vector2(345, 64), Vector2(434, 66),
	Vector2(439, 87), Vector2(634, 95), Vector2(654, 96), Vector2(661, 199),
	Vector2(680, 193), Vector2(680, 279), Vector2(669, 306), Vector2(675, 410),
	Vector2(637, 408), Vector2(589, 404), Vector2(578, 424), Vector2(437, 424),
	Vector2(439, 465), Vector2(322, 464), Vector2(319, 436), Vector2(299, 424),
	Vector2(186, 424), Vector2(177, 400), Vector2(143, 397), Vector2(107, 382),
	Vector2(99, 308), Vector2(63, 275), Vector2(78, 190), Vector2(13, 187),
	Vector2(13, 510), Vector2(737, 502), Vector2(722, 16), Vector2(7, 13),
	Vector2(8, 168), Vector2(109, 182),
]

const NEW_TRUNCATED: PackedVector2Array = [
	Vector2(127, 93), Vector2(343, 96), Vector2(345, 64), Vector2(434, 66),
	Vector2(439, 87), Vector2(634, 95), Vector2(654, 96), Vector2(661, 199),
	Vector2(680, 193), Vector2(680, 279), Vector2(669, 306), Vector2(675, 410),
	Vector2(637, 408), Vector2(589, 404), Vector2(578, 424), Vector2(437, 424),
	Vector2(439, 465), Vector2(322, 464), Vector2(319, 436), Vector2(299, 424),
	Vector2(186, 424), Vector2(177, 400), Vector2(143, 397), Vector2(107, 382),
	Vector2(99, 308), Vector2(63, 275), Vector2(78, 190), Vector2(13, 187),
	Vector2(13, 510),
]

func _initialize() -> void:
	call_deferred("_run")

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
	print("%s @ %s -> intersect_polygons blocked=%s" % [label, point, blocked])

func _run() -> void:
	print("--- ROUND1 (34 pts, currently implemented, verified working) ---")
	_test("floor_center", ROUND1, Vector2(380, 260))
	_test("wall_corner_top_left", ROUND1, Vector2(20, 20))
	_test("door_spawn_90_300", ROUND1, Vector2(90, 300))
	_test("mid_interior_wall_point", ROUND1, Vector2(400, 90))

	print("--- NEW_TRUNCATED (29 pts, dropped corner-jump tail) ---")
	_test("floor_center", NEW_TRUNCATED, Vector2(380, 260))
	_test("wall_corner_top_left", NEW_TRUNCATED, Vector2(20, 20))
	_test("door_spawn_90_300", NEW_TRUNCATED, Vector2(90, 300))
	_test("mid_interior_wall_point", NEW_TRUNCATED, Vector2(400, 90))

	quit()
