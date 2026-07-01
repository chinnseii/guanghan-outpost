extends Node2D
class_name BasePlayerOverlay

var source_scene: Node
var art_texture: Texture2D

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
	var pose := String(source_scene.get("player_pose"))
	if bool(source_scene.get("use_art_slice")):
		if art_texture == null:
			var image := Image.load_from_file(ProjectSettings.globalize_path("res://assets/art/player/astronaut_idle_down.png"))
			if image != null:
				art_texture = ImageTexture.create_from_image(image)
		if art_texture != null:
			texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var size := art_texture.get_size() * 1.45
			var offset := Vector2(size.x * 0.5, size.y - 12)
			if pose != "idle":
				draw_rect(Rect2(player_pos + Vector2(18, -56), Vector2(10, 34)), Color("#89d8ff", 0.22), true)
				draw_circle(player_pos + Vector2(24, -60), 5, Color("#f0c766") if pose == "repair" else Color("#89d8ff"))
			draw_texture_rect(art_texture, Rect2(player_pos - offset + (Vector2(0, 3) if pose != "idle" else Vector2.ZERO), size), false)
			return
	draw_ellipse(player_pos + Vector2(0, 18), 18, 5, Color("#020305", 0.36))
	var lean := Vector2(0, 4) if pose != "idle" else Vector2.ZERO
	draw_rect(Rect2(player_pos + Vector2(-11, -38) + lean, Vector2(22, 36)), Color("#d8e0e6"), true)
	draw_rect(Rect2(player_pos + Vector2(-7, -30) + lean, Vector2(14, 14)), Color("#7fa7bd"), true)
	draw_circle(player_pos + Vector2(0, -50), 16, Color("#e6eef4"))
	draw_circle(player_pos + Vector2(0, -50), 9, Color("#1b2834"))
	if pose == "repair":
		draw_line(player_pos + Vector2(-10, -18), player_pos + Vector2(-20, -2), Color("#d8e0e6"), 4)
		draw_line(player_pos + Vector2(10, -18), player_pos + Vector2(27, -8), Color("#d8e0e6"), 4)
		draw_rect(Rect2(player_pos + Vector2(26, -11), Vector2(12, 5)), Color("#f0c766"), true)
	elif pose == "scan":
		draw_line(player_pos + Vector2(-10, -18), player_pos + Vector2(-18, 4), Color("#d8e0e6"), 4)
		draw_line(player_pos + Vector2(10, -18), player_pos + Vector2(28, -20), Color("#d8e0e6"), 4)
		draw_circle(player_pos + Vector2(33, -20), 5, Color("#89d8ff"))
	else:
		draw_line(player_pos + Vector2(-10, -18), player_pos + Vector2(-18, 4), Color("#d8e0e6"), 4)
		draw_line(player_pos + Vector2(10, -18), player_pos + Vector2(18, 4), Color("#d8e0e6"), 4)
	draw_line(player_pos + Vector2(-5, -2), player_pos + Vector2(-10, 20), Color("#d8e0e6"), 4)
	draw_line(player_pos + Vector2(5, -2), player_pos + Vector2(10, 20), Color("#d8e0e6"), 4)
