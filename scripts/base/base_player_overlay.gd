extends Node2D
class_name BasePlayerOverlay

var source_scene: Node

func _draw() -> void:
	if source_scene == null:
		return
	if String(source_scene.get("scene_kind")) == "airlock":
		return
	var raw_pos: Variant = source_scene.get("player_pos")
	if typeof(raw_pos) != TYPE_VECTOR2:
		return
	var player_pos := Vector2.ZERO
	player_pos = raw_pos
	draw_ellipse(player_pos + Vector2(0, 18), 18, 5, Color("#020305", 0.36))
	draw_rect(Rect2(player_pos + Vector2(-11, -38), Vector2(22, 36)), Color("#d8e0e6"), true)
	draw_rect(Rect2(player_pos + Vector2(-7, -30), Vector2(14, 14)), Color("#7fa7bd"), true)
	draw_circle(player_pos + Vector2(0, -50), 16, Color("#e6eef4"))
	draw_circle(player_pos + Vector2(0, -50), 9, Color("#1b2834"))
	draw_line(player_pos + Vector2(-10, -18), player_pos + Vector2(-18, 4), Color("#d8e0e6"), 4)
	draw_line(player_pos + Vector2(10, -18), player_pos + Vector2(18, 4), Color("#d8e0e6"), 4)
	draw_line(player_pos + Vector2(-5, -2), player_pos + Vector2(-10, 20), Color("#d8e0e6"), 4)
	draw_line(player_pos + Vector2(5, -2), player_pos + Vector2(10, 20), Color("#d8e0e6"), 4)
