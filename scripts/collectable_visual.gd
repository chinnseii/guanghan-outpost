extends Node2D

const AssetCatalog := preload("res://scripts/asset_catalog.gd")

var item_data: Dictionary = {}
var highlighted := false
var textures: Dictionary = {}

func _ready() -> void:
	for key: String in AssetCatalog.COLLECTABLE_TEXTURE_PATHS.keys():
		textures[key] = AssetCatalog.load_png_texture(AssetCatalog.collectable_texture_path(key))

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
		draw_circle(Vector2.ZERO, 31, Color(1.0, 0.82, 0.25, 0.22))
		draw_arc(Vector2.ZERO, 32.0, 0.0, TAU, 32, Color("#e7c66b"), 4)
	draw_rect(Rect2(Vector2(-20, 15), Vector2(40, 7)), Color(0, 0, 0, 0.22))
	if textures.has(item_type) and textures[item_type] != null:
		var size := Vector2(66, 54) if item_type == "supply_pod" else Vector2(44, 44)
		draw_texture_rect(textures[item_type], Rect2(-size * 0.5, size), false)
		_draw_status_badge(item_type)
		_draw_resource_marker(item_type)
		return
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
	_draw_status_badge(item_type)
	_draw_resource_marker(item_type)

func _draw_status_badge(item_type: String) -> void:
	var badge_color := Color("#b8b2a2")
	match item_type:
		"ice":
			badge_color = Color("#9fd7ff")
		"meteor":
			badge_color = Color("#d1a15b")
		"sample":
			badge_color = Color("#7dff9d")
		"supply_pod":
			badge_color = Color("#e7c66b")
	draw_circle(Vector2(16, -18), 6, Color("#202833"))
	draw_circle(Vector2(16, -18), 4, badge_color)

func _draw_resource_marker(item_type: String) -> void:
	if item_type == "supply_pod":
		draw_line(Vector2(0, -30), Vector2(0, -48), Color("#e7c66b"), 3)
		draw_circle(Vector2(0, -52), 5, Color("#e7c66b"))
		return
	var marker_color := Color("#b8b2a2")
	if item_type == "ice":
		marker_color = Color("#9fd7ff")
	elif item_type == "meteor":
		marker_color = Color("#d1a15b")
	elif item_type == "sample":
		marker_color = Color("#7dff9d")
	draw_line(Vector2(-14, 20), Vector2(14, 20), marker_color, 3)
