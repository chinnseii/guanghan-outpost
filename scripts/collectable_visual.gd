extends Node2D

var item_data: Dictionary = {}
var highlighted := false

func setup(data: Dictionary, is_highlighted: bool) -> void:
	item_data = data
	highlighted = is_highlighted
	visible = not bool(item_data.get("depleted", false))
	queue_redraw()

func _draw() -> void:
	if item_data.is_empty() or bool(item_data.get("depleted", false)):
		return
	var item_type := String(item_data.get("type", "regolith"))
	if highlighted:
		draw_circle(Vector2.ZERO, 22, Color("#e7c66b"))
	var color := Color("#b8b2a2")
	if item_type == "ice":
		color = Color("#9fd7ff")
	elif item_type == "meteor":
		color = Color("#d1a15b")
	elif item_type == "sample":
		color = Color("#c9c3a5")
	elif item_type == "supply_pod":
		color = Color("#d68b52")
		draw_circle(Vector2.ZERO, 24, Color("#6b3928"))
		draw_rect(Rect2(Vector2(-18, -12), Vector2(36, 24)), color)
		draw_line(Vector2(-22, 18), Vector2(22, 18), Color("#d0d6df"), 3)
		return
	draw_circle(Vector2.ZERO, 13, color)
	draw_circle(Vector2(-4, -4), 4, Color(1, 1, 1, 0.28))
