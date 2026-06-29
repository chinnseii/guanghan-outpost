extends Control

@export var panel_kind := "project"

func _ready() -> void:
	custom_minimum_size = Vector2(520, 260)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#07121c"))
	for i in range(48):
		var x := float((i * 97) % int(max(size.x, 1.0)))
		var y := float((i * 43) % int(max(size.y, 1.0)))
		draw_circle(Vector2(x, y), 1.0, Color("#c9e8ff", 0.18))
	if panel_kind == "education":
		_draw_education()
	else:
		_draw_project()

func _draw_project() -> void:
	var earth := Vector2(size.x * 0.70, size.y * 0.36)
	draw_circle(earth, 58, Color("#1e75b8"))
	draw_circle(earth + Vector2(-16, -10), 17, Color("#e7f6ff", 0.84))
	draw_circle(earth + Vector2(17, 12), 13, Color("#68ca84", 0.86))
	draw_arc(earth, 64, 0.0, TAU, 64, Color("#bfefff", 0.46), 2)
	draw_circle(Vector2(size.x * 0.88, size.y * 0.30), 23, Color("#6b7379"))
	draw_polygon(
		[
			Vector2(0, size.y * 0.78),
			Vector2(size.x * 0.35, size.y * 0.66),
			Vector2(size.x * 0.72, size.y * 0.74),
			Vector2(size.x, size.y * 0.62),
			Vector2(size.x, size.y),
			Vector2(0, size.y),
		],
		[Color("#1a222c")]
	)
	draw_line(Vector2(0, size.y * 0.78), Vector2(size.x, size.y * 0.62), Color("#38485a", 0.65), 2)

func _draw_education() -> void:
	draw_circle(Vector2(size.x * 0.32, size.y * 0.50), 52, Color("#0d2630"))
	draw_arc(Vector2(size.x * 0.32, size.y * 0.50), 68, 0.25, TAU * 0.87, 48, Color("#2e7fa0", 0.52), 3)
	for i in range(5):
		var start := Vector2(size.x * 0.58, size.y * (0.30 + float(i) * 0.10))
		draw_line(start, start + Vector2(112, 0), Color("#65899a", 0.65), 3)
		draw_circle(start - Vector2(20, 0), 5, Color("#d0a84b"))
	draw_line(Vector2(size.x * 0.32, size.y * 0.50), Vector2(size.x * 0.58, size.y * 0.50), Color("#6a8798", 0.45), 2)
