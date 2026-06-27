extends Node2D

const TILE := 48

var module_data: Dictionary = {}
var module_def: Dictionary = {}
var highlighted := false

func setup(data: Dictionary, definition: Dictionary, is_highlighted: bool) -> void:
	module_data = data
	module_def = definition
	highlighted = is_highlighted
	queue_redraw()

func _draw() -> void:
	if module_data.is_empty() or module_def.is_empty():
		return
	var size: Vector2i = module_def["size"]
	var rect := Rect2(Vector2.ZERO, Vector2(size.x * TILE - 2, size.y * TILE - 2))
	var fill: Color = module_def["color"]
	if highlighted:
		draw_rect(rect.grow(5), Color("#e7c66b"), false, 3)
	if module_data.get("leaking", false):
		draw_rect(rect.grow(7), Color("#ff5a5a"), false, 4)
	draw_rect(rect, fill)
	draw_rect(rect, Color("#a7b3c5"), false, 2)
	_draw_details(String(module_data["type"]), rect)

func _draw_details(module_type: String, rect: Rect2) -> void:
	if module_type == "greenhouse":
		_draw_greenhouse(rect)
	elif module_type == "solar":
		_draw_solar(rect)
	elif module_type == "battery":
		for i in range(2):
			draw_rect(Rect2(rect.position + Vector2(20 + i * 38, 28), Vector2(24, 42)), Color("#a8c7ff"))
	elif module_type == "hab":
		draw_circle(rect.get_center(), min(rect.size.x, rect.size.y) * 0.35, Color("#717d8f"))
	elif module_type == "life_support":
		draw_circle(rect.get_center() + Vector2(-22, 0), 18, Color("#98d5ff"))
		draw_circle(rect.get_center() + Vector2(22, 0), 18, Color("#b8f0d0"))
	elif module_type == "workshop":
		draw_rect(Rect2(rect.position + Vector2(24, 28), Vector2(48, 34)), Color("#c0a36c"))
	elif module_type == "airlock":
		draw_rect(Rect2(rect.position + Vector2(22, 18), Vector2(52, 58)), Color("#8892a3"), false, 4)
		draw_line(rect.position + Vector2(48, 20), rect.position + Vector2(48, 74), Color("#d8e0eb"), 2)
	elif module_type == "regolith_plant":
		draw_circle(rect.get_center() + Vector2(-26, 0), 18, Color("#b3a18e"))
		draw_line(rect.get_center() + Vector2(-8, 0), rect.get_center() + Vector2(32, -18), Color("#d8e0eb"), 3)
		draw_circle(rect.get_center() + Vector2(36, -20), 8, Color("#98d5ff"))
	elif module_type == "ice_processor":
		draw_circle(rect.get_center() + Vector2(-20, 0), 18, Color("#9fd7ff"))
		draw_rect(Rect2(rect.get_center() + Vector2(8, -18), Vector2(34, 36)), Color("#b8f0ff"), false, 3)
	elif module_type == "supply":
		draw_circle(rect.get_center(), 32, Color("#a76f45"))
		draw_rect(Rect2(rect.position + Vector2(68, 35), Vector2(54, 74)), Color("#d0d6df"), false, 3)

func _draw_greenhouse(rect: Rect2) -> void:
	for i in range(2):
		var bed := Rect2(rect.position + Vector2(22 + i * 72, 28), Vector2(52, 48))
		draw_rect(bed, Color("#223026"))
		draw_rect(bed, Color("#74b77a"), false, 2)
		if String(module_data.get("crop", "")) != "":
			var growth: float = clamp(float(module_data.get("age", 0)) / 4.0, 0.2, 1.0)
			draw_circle(bed.get_center(), 7 + 13 * growth, Color("#71d46f"))

func _draw_solar(rect: Rect2) -> void:
	for i in range(4):
		var panel := Rect2(rect.position + Vector2(14 + i * 40, 18), Vector2(30, 58))
		draw_rect(panel, Color("#365f95"))
		draw_rect(panel, Color("#94bdeb"), false, 1)
