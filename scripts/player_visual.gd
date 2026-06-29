extends Node2D

const AssetCatalog := preload("res://scripts/asset_catalog.gd")
const FRAME_SIZE := Vector2(40, 56)

var facing := Vector2.DOWN
var inside := false
var suit_o2 := 100.0
var moving := false
var walk_phase := 0.0
var astronaut_texture: Texture2D

func _ready() -> void:
	astronaut_texture = AssetCatalog.load_png_texture(AssetCatalog.player_texture_path("astronaut_walk"))

func setup(new_facing: Vector2, new_inside: bool, new_suit_o2: float, is_moving: bool = false, new_walk_phase: float = 0.0) -> void:
	facing = new_facing
	inside = new_inside
	suit_o2 = new_suit_o2
	moving = is_moving
	walk_phase = new_walk_phase
	queue_redraw()

func _draw() -> void:
	if astronaut_texture != null:
		_draw_astronaut_sprite()
		return
	var visor_color := Color("#7fb8ff") if suit_o2 > 25.0 else Color("#ff8a6b")
	var suit_color := Color("#f2f0da") if inside else Color("#e8edf5")
	var side := Vector2(-facing.y, facing.x)
	draw_rect(Rect2(Vector2(-18, 15), Vector2(36, 7)), Color(0, 0, 0, 0.18))
	draw_circle(-side * 8 + Vector2(0, 5), 6, Color("#303846"))
	draw_circle(side * 8 + Vector2(0, 1), 6, Color("#303846"))
	draw_circle(Vector2.ZERO, 21, Color("#1b222d"))
	draw_circle(Vector2.ZERO, 16, suit_color)
	draw_rect(Rect2(Vector2(-10, 10), Vector2(20, 8)), Color("#9faabb"))
	draw_circle(facing * 7, 6, visor_color)
	draw_line(Vector2.ZERO, facing * 26, Color("#e7c66b"), 3)
	if not inside:
		draw_arc(Vector2.ZERO, 27, -1.2, 1.2, 24, Color("#8fd7ff", 0.45), 3)
		draw_rect(Rect2(Vector2(-7, 17), Vector2(14, 8)), Color("#6f7d8f"))

func _draw_astronaut_sprite() -> void:
	var row := _direction_row()
	var frame := 0
	if moving:
		frame = int(floor(walk_phase / 4.0)) % 2
	var source := Rect2(Vector2(frame * FRAME_SIZE.x, row * FRAME_SIZE.y), FRAME_SIZE)
	var dest := Rect2(Vector2(-FRAME_SIZE.x * 0.5, -FRAME_SIZE.y + 16), FRAME_SIZE)
	draw_rect(Rect2(Vector2(-16, 15), Vector2(32, 6)), Color(0, 0, 0, 0.18))
	draw_texture_rect_region(astronaut_texture, dest, source)
	if suit_o2 <= 25.0:
		draw_arc(Vector2(0, -20), 17.0, 0.0, TAU, 24, Color("#ff8a6b"), 3)
	if not inside:
		draw_arc(Vector2(0, -17), 25.0, -1.25, 1.25, 24, Color("#8fd7ff", 0.42), 3)

func _direction_row() -> int:
	if abs(facing.x) > abs(facing.y):
		return 2 if facing.x > 0.0 else 1
	if facing.y < 0.0:
		return 3
	return 0
