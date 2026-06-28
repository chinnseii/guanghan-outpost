extends Node2D

var task := "idle"
var active := false
var anim_time := 0.0

func setup(new_task: String, is_active: bool) -> void:
	task = new_task
	active = is_active
	queue_redraw()

func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()

func _draw() -> void:
	var body: Color = Color("#d8e0eb") if active else Color("#7d8796")
	var light: Color = Color("#7dff9d") if active else Color("#8792a0")
	var bob: float = sin(anim_time * 5.0) * 2.0 if active else 0.0
	draw_circle(Vector2(0, -8 + bob), 10, Color("#263242"))
	draw_circle(Vector2(0, -8 + bob), 7, body)
	draw_rect(Rect2(Vector2(-15, 0 + bob), Vector2(30, 18)), Color("#2f4059"))
	draw_rect(Rect2(Vector2(-10, 4 + bob), Vector2(20, 10)), body)
	draw_circle(Vector2(-10, 22 + bob), 5, Color("#202833"))
	draw_circle(Vector2(10, 22 + bob), 5, Color("#202833"))
	draw_circle(Vector2(8, -12 + bob), 3, light)
	if task == "haul":
		draw_rect(Rect2(Vector2(18, 4 + bob), Vector2(12, 12)), Color("#d68b52"))
	elif task == "sample":
		draw_line(Vector2(-18, 10 + bob), Vector2(-30, 18 + bob), Color("#e7c66b"), 3)
	elif task == "maintenance":
		draw_line(Vector2(16, 4 + bob), Vector2(28, -8 + bob), Color("#98d5ff"), 3)
