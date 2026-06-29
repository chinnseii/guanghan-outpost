extends Node2D

const TEXTURE_PATHS := {
	"regolith": "res://assets/sprites/collectables/regolith_node.png",
	"ice": "res://assets/sprites/collectables/ice_node.png",
	"meteor": "res://assets/sprites/collectables/meteor_node.png",
	"sample": "res://assets/sprites/collectables/sample_node.png",
	"supply_pod": "res://assets/sprites/collectables/supply_pod.png",
}

var item_data: Dictionary = {}
var highlighted := false
var textures: Dictionary = {}

func _ready() -> void:
	for key: String in TEXTURE_PATHS.keys():
		textures[key] = _load_png_texture(String(TEXTURE_PATHS[key]))

func _load_png_texture(path: String) -> Texture2D:
	if FileAccess.file_exists("%s.import" % path):
		var imported: Resource = ResourceLoader.load(path)
		if imported is Texture2D:
			return imported as Texture2D
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

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
		draw_circle(Vector2.ZERO, 24, Color(1.0, 0.82, 0.25, 0.32))
		draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 28, Color("#e7c66b"), 3)
	if textures.has(item_type) and textures[item_type] != null:
		var size := Vector2(48, 40) if item_type == "supply_pod" else Vector2(32, 32)
		draw_texture_rect(textures[item_type], Rect2(-size * 0.5, size), false)
		_draw_status_badge(item_type)
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
	draw_circle(Vector2(12, -14), 4, badge_color)
