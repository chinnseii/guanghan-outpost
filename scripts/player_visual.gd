extends Node2D

const AssetCatalog := preload("res://scripts/asset_catalog.gd")

## Character appearance system (2026-07-17): three complete walk-cycle packs
## exist -- female_light_black_longhair (the designer's confirmed official
## default; explicitly reconfirmed after a same-day mixup with a different,
## superseded "V3" longhair package that must NOT be used), _ponytail, and
## _shorthair. All three share the same contract (6 cols/frames 00-05 x 4
## rows down/left/right/up, 8 FPS) but differ in native cell size -- frame
## sizing is looked up per-appearance via AssetCatalog rather than a fixed
## const, and DISPLAY_SIZE is derived from whichever frame_size that returns
## (still targeting this character's usual ~56px on-screen height, matching
## TILE in main.gd, aspect-preserving since it scales by frame_size.y).
## The longhair pack's "astronaut_walk.png" is itself an offline
## LANCZOS-prescaled 128x128/cell copy of its 512x512 native art -- drawing
## the 512px source directly at ~56px on-screen is a ~9x GPU minification
## with no mipmaps, which produced a dark/aliased smudge in a live test (see
## ACTIVE_TASKS.md PLAYER-VISUAL-01 Round 3). Ponytail/shorthair are used at
## their native 256x256 (a safe ~4.6x downscale ratio, no prescale needed).
const FRAMES_PER_ROW := 6
## walk_phase advances 10.0/sec (see main.gd); dividing by 1.25 turns that
## into 125ms-per-frame steps, matching every pack's suggested 8 FPS.
const WALK_PHASE_PER_FRAME := 1.25
## Target on-screen height for all appearances, matching TILE in main.gd.
const DISPLAY_HEIGHT := 56.0

var facing := Vector2.DOWN
var inside := false
var suit_o2 := 100.0
var moving := false
var walk_phase := 0.0
var astronaut_texture: Texture2D
var appearance_id: String = AssetCatalog.DEFAULT_PLAYER_APPEARANCE
var frame_size: Vector2 = Vector2(128, 128)
var display_size: Vector2 = Vector2(128, 128) * (DISPLAY_HEIGHT / 128.0)

func _ready() -> void:
	_load_appearance(appearance_id)

## Switches the whole character sheet (body + hair together -- never mix
## pieces from different appearances, per the designer's handoff). Safe to
## call every frame; it's a no-op once the requested appearance is already
## loaded.
func set_appearance(new_appearance_id: String) -> void:
	if new_appearance_id == appearance_id and astronaut_texture != null:
		return
	_load_appearance(new_appearance_id)

func _load_appearance(new_appearance_id: String) -> void:
	appearance_id = new_appearance_id
	frame_size = AssetCatalog.player_appearance_frame_size(appearance_id)
	display_size = frame_size * (DISPLAY_HEIGHT / frame_size.y)
	astronaut_texture = AssetCatalog.load_png_texture(AssetCatalog.player_appearance_texture_path(appearance_id))
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
