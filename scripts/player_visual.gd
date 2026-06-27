extends Node2D

var facing := Vector2.DOWN
var inside := false
var suit_o2 := 100.0

func setup(new_facing: Vector2, new_inside: bool, new_suit_o2: float) -> void:
	facing = new_facing
	inside = new_inside
	suit_o2 = new_suit_o2
	queue_redraw()

func _draw() -> void:
	var visor_color := Color("#7fb8ff") if suit_o2 > 25.0 else Color("#ff8a6b")
	var suit_color := Color("#f2f0da") if inside else Color("#e8edf5")
	var side := Vector2(-facing.y, facing.x)
	draw_circle(-side * 7 + Vector2(0, 2), 5, Color("#303846"))
	draw_circle(side * 7 + Vector2(0, -2), 5, Color("#303846"))
	draw_circle(Vector2.ZERO, 18, Color("#1b222d"))
	draw_circle(Vector2.ZERO, 14, suit_color)
	draw_circle(facing * 6, 5, visor_color)
	draw_line(Vector2.ZERO, facing * 22, Color("#e7c66b"), 2)
	if not inside:
		draw_arc(Vector2.ZERO, 23, -1.2, 1.2, 24, Color("#8fd7ff", 0.35), 2)
