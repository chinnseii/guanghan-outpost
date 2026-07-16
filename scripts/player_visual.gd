extends Node2D

const AssetCatalog := preload("res://scripts/asset_catalog.gd")
const CharacterAppearanceCatalog := preload("res://scripts/data/character_appearance_catalog.gd")

## Character appearance system (2026-07-17): the character's look is driven
## by 4 attributes (gender/skin_tone/hair_color/hairstyle) resolved through
## CharacterAppearanceCatalog, NOT a single hand-picked texture. Every
## registered pack shares the same contract (6 cols/frames 00-05 x 4 rows
## down/left/right/up, 8 FPS) but differs in native cell size, so frame_size/
## display_size are resolved per-appearance (see _apply_appearance()) rather
## than fixed consts -- DISPLAY_HEIGHT is the one constant every appearance
## targets, keeping on-screen scale consistent across native resolutions
## without stretching (aspect preserved since only frame_size.y anchors it).
## Most gender/skin/hair_color/hairstyle combinations have no walk-cycle art
## yet (still being generated) -- CharacterAppearanceCatalog.resolve()
## gracefully substitutes a per-gender fallback for those instead of this
## script needing to know which combos exist.
const FRAMES_PER_ROW := 6
## walk_phase advances 10.0/sec (see main.gd); dividing by 1.25 turns that
## into 125ms-per-frame steps, matching every pack's suggested 8 FPS.
const WALK_PHASE_PER_FRAME := 1.25
## Target on-screen height for every appearance, matching TILE in main.gd.
const DISPLAY_HEIGHT := 56.0

var facing := Vector2.DOWN
var inside := false
var suit_o2 := 100.0
var moving := false
var walk_phase := 0.0
var astronaut_texture: Texture2D

var gender: String = "female"
var skin_tone: String = "light"
var hair_color: String = "black"
var hairstyle: String = "long"
## The appearance_id actually resolved to (may differ from the requested
## gender/skin_tone/hair_color/hairstyle if that exact combo isn't
## registered yet -- see appearance_is_fallback).
var appearance_key: String = ""
var appearance_is_fallback: bool = false
var frame_size: Vector2 = Vector2(128, 128)
var display_size: Vector2 = Vector2(128, 128) * (DISPLAY_HEIGHT / 128.0)

func _ready() -> void:
	_apply_appearance()

## Primary entry point: call with the player's actual chosen attributes
## (matches PlayerProfileData's skin_preset/hair_color_preset/hair_preset
## vocabulary, and gender_display converted via
## CharacterAppearanceCatalog.gender_id_from_display()). Safe to call every
## frame; a no-op once these exact attributes are already applied.
func set_character_appearance(new_gender: String, new_skin_tone: String, new_hair_color: String, new_hairstyle: String) -> void:
	if new_gender == gender and new_skin_tone == skin_tone and new_hair_color == hair_color and new_hairstyle == hairstyle and astronaut_texture != null:
		return
	gender = new_gender
	skin_tone = new_skin_tone
	hair_color = new_hair_color
	hairstyle = new_hairstyle
	_apply_appearance()

## Convenience for dev/testing tools that want to select a registered
## appearance_id directly (see CharacterAppearanceCatalog.all_registered_keys())
## without assembling the 4 separate attributes by hand.
func set_appearance_by_key(requested_appearance_id: String) -> void:
	var parts := requested_appearance_id.split("_")
	if parts.size() != 4:
		return
	set_character_appearance(parts[0], parts[1], parts[2], parts[3])

func _apply_appearance() -> void:
	var resolved := CharacterAppearanceCatalog.resolve(gender, skin_tone, hair_color, hairstyle)
	appearance_key = String(resolved["key"])
	appearance_is_fallback = bool(resolved["is_fallback"])
	frame_size = resolved["frame_size"]
	display_size = frame_size * (DISPLAY_HEIGHT / frame_size.y)
	astronaut_texture = AssetCatalog.load_png_texture(String(resolved["path"]))
	queue_redraw()

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
	draw_rect(Rect2(Vector2(-16, 15), Vector2(32, 6)), Color(0, 0, 0, 0.18))
	var frame := 0
	if moving:
		frame = int(floor(walk_phase / WALK_PHASE_PER_FRAME)) % FRAMES_PER_ROW
	var source := Rect2(Vector2(frame * frame_size.x, row * frame_size.y), frame_size)
	var dest := Rect2(Vector2(-display_size.x * 0.5, -display_size.y + 16), display_size)
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
