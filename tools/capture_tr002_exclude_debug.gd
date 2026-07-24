extends SceneTree

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

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var rect := PackedVector2Array([
		Vector2(374, 254), Vector2(386, 254), Vector2(386, 266), Vector2(374, 266),
	])
	print("rect=", rect)
	var intersect: Array = Geometry2D.intersect_polygons(rect, ROOM_BOUNDARY)
	print("intersect_polygons(rect, boundary) count=", intersect.size())
	for p in intersect:
		print("  intersect piece: ", p)
	var exclude_ab: Array = Geometry2D.exclude_polygons(rect, ROOM_BOUNDARY)
	print("exclude_polygons(rect, boundary) count=", exclude_ab.size())
	for p in exclude_ab:
		print("  exclude piece: ", p)
	quit()
