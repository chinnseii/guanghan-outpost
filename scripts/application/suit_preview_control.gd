extends Control

@export var front := true
@export var suit_id := "GH-2068-0421"
@export var patch_id := "GH-01"
@export var marking_color := Color("#d6a83e")

func _ready() -> void:
	custom_minimum_size = Vector2(210, 250)
	queue_redraw()

func _draw() -> void:
	var center := Vector2(size.x * 0.5, 116)
	draw_ellipse(center + Vector2(0, 118), 48, 10, Color("#020406", 0.32))
	draw_line(center + Vector2(-34, 48), center + Vector2(-58, 105), Color("#c5ced6"), 13)
	draw_line(center + Vector2(34, 48), center + Vector2(58, 105), Color("#c5ced6"), 13)
	draw_line(center + Vector2(-18, 106), center + Vector2(-30, 178), Color("#c5ced6"), 15)
	draw_line(center + Vector2(18, 106), center + Vector2(30, 178), Color("#c5ced6"), 15)
	draw_rect(Rect2(center + Vector2(-36, 28), Vector2(72, 92)), Color("#d0d7dd"))
	draw_rect(Rect2(center + Vector2(-27, 34), Vector2(54, 34)), Color("#aeb8c1"))
	draw_circle(center + Vector2(0, -3), 32, Color("#e1e8ed"))
	if front:
		draw_rect(Rect2(center + Vector2(-22, -14), Vector2(44, 24)), Color("#101d2a"))
		draw_circle(center + Vector2(-24, 63), 7, marking_color)
		draw_rect(Rect2(center + Vector2(10, 78), Vector2(20, 8)), marking_color)
	else:
		draw_rect(Rect2(center + Vector2(-28, 44), Vector2(56, 68)), Color("#9fa8af"))
		draw_rect(Rect2(center + Vector2(-24, 78), Vector2(48, 12)), Color("#27313a"))
	draw_string(ThemeDB.fallback_font, Vector2(38, 224), suit_id if not front else patch_id, HORIZONTAL_ALIGNMENT_LEFT, 140, 13, Color("#d8e7f2"))
