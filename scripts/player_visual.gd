extends Node2D

const AssetCatalog := preload("res://scripts/asset_catalog.gd")
const CharacterAppearanceCatalog := preload("res://scripts/data/character_appearance_catalog.gd")
const SkinToneShader := preload("res://assets/shaders/character_skin_tone.gdshader")

## Skin-tone shader (2026-07-17, user/CHARACTER_SKIN_TONE_HANDOFF.md) is
## applied to a CHILD node (_sprite_layer), not this node directly. A
## CanvasItem material affects every draw_*() call the node issues, but the
## shadow ellipse and the O2/atmosphere rings below are untextured primitives
## with no meaningful mask UV -- materialing the whole node would sample
## skin_mask_texture at arbitrary coordinates for those and could paint
## skin-colored artifacts onto them. Splitting the sprite (materialed) from
## the rings (not) into separate children, added in that order, preserves
## the original draw order (shadow -> sprite -> rings) since Godot draws a
## parent's own _draw() first, then children in sibling order.
class SpriteLayer:
	extends Node2D
	var sprite_texture: Texture2D = null
	var source_rect := Rect2()
	var dest_rect := Rect2()

	func _draw() -> void:
		if sprite_texture != null:
			draw_texture_rect_region(sprite_texture, dest_rect, source_rect)

class RingsLayer:
	extends Node2D
	var suit_o2 := 100.0
	var inside := false

	func _draw() -> void:
		if suit_o2 <= 25.0:
			draw_arc(Vector2(0, -20), 17.0, 0.0, TAU, 24, Color("#ff8a6b"), 3)
		if not inside:
			draw_arc(Vector2(0, -17), 25.0, -1.25, 1.25, 24, Color("#8fd7ff", 0.42), 3)

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

## Suit-up donning animation (2026-07-19, user/SUIT_ANIMATION_DEVELOPER_HANDOFF.md).
## Once is_suit_worn is true, _draw_astronaut_sprite() swaps the appearance
## walk-cycle texture for assets/characters/suits/walk_cycle_<color>.png
## instead -- same 6-frame/4-row (down/left/right/up) contract, just a fixed
## 512x512 native cell, so _direction_row()/display_size scaling need no
## changes. play_suit_up_animation() plays a one-shot transition first: the
## rack is approached from below in the suit-control training room, so the
## player is normally facing up/away when they confirm -- the back
## (helmet-lower) variant is picked whenever facing.y is meaningfully
## negative, otherwise the front (suit-up) variant. Both source atlases are
## 4 cols x 2 rows at 512x512/frame; the back atlas's last cell (frame 06)
## is unused per its manifest. Per-frame durations are the artist's own
## suggested timings, not FRAMES_PER_ROW/WALK_PHASE_PER_FRAME-driven, since
## the donning animation isn't a looping walk cycle.
const SUIT_UP_FRAME_SIZE := Vector2(512, 512)
const SUIT_UP_COLS := 4
const SUIT_UP_FRONT_DURATIONS: Array[float] = [0.24, 0.11, 0.11, 0.11, 0.11, 0.11, 0.15, 0.35]
const SUIT_UP_BACK_DURATIONS: Array[float] = [0.15, 0.13, 0.13, 0.13, 0.13, 0.17, 0.35]

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

## Suit-worn state -- orthogonal to gender/skin/hair_color/hairstyle above.
## suit_marking_color matches PlayerProfileData's SuitMarkingColor
## (red/yellow/blue). is_suit_worn is caller-driven (see setup()), not
## looked up from SuitManager directly, matching how suit_o2/inside are
## already supplied by the caller each frame rather than queried internally.
var suit_marking_color: String = "blue"
var is_suit_worn: bool = false

var _sprite_layer: Node2D = null
var _rings_layer: Node2D = null
var _skin_tone_material: ShaderMaterial = null
## True only while play_suit_up_animation()'s coroutine is manually driving
## _sprite_layer frame-by-frame -- setup() no-ops during this window so the
## next regular per-frame call doesn't stomp the animation's current frame.
var _playing_transition_animation := false
## Godot samplers need SOME texture bound; when a hairstyle has no
## registered mask (shouldn't happen for the 6 currently registered
## hairstyles, but keeps this from erroring if one is ever missing), this
## fully-transparent 1x1 stand-in makes the shader a no-op (mask.a=0 everywhere
## -> output equals the original albedo untouched).
static var _empty_mask_texture: ImageTexture = null

func _ready() -> void:
	_sprite_layer = SpriteLayer.new()
	add_child(_sprite_layer)
	_rings_layer = RingsLayer.new()
	add_child(_rings_layer)
	_skin_tone_material = ShaderMaterial.new()
	_skin_tone_material.shader = SkinToneShader
	_sprite_layer.material = _skin_tone_material
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
## without assembling gender/hair_color/hairstyle by hand. Keeps whatever
## skin_tone is already set -- skin_tone is an orthogonal axis from the
## registry key since Round 13's fix (see CharacterAppearanceCatalog's
## top-of-file note), so cycling through appearance_ids shouldn't reset it.
func set_appearance_by_key(requested_appearance_id: String) -> void:
	var parts := requested_appearance_id.split("_")
	if parts.size() != 3:
		return
	set_character_appearance(parts[0], skin_tone, parts[1], parts[2])

## Independent of set_character_appearance() -- the suit trim color doesn't
## affect the normal (not-suit-worn) appearance sprite at all, so this is a
## separate setter rather than a 5th positional argument on that call.
func set_suit_marking_color(color_id: String) -> void:
	suit_marking_color = color_id

func _apply_appearance() -> void:
	var resolved := CharacterAppearanceCatalog.resolve(gender, hair_color, hairstyle)
	appearance_key = String(resolved["key"])
	appearance_is_fallback = bool(resolved["is_fallback"])
	frame_size = resolved["frame_size"]
	display_size = frame_size * (DISPLAY_HEIGHT / frame_size.y)
	astronaut_texture = AssetCatalog.load_png_texture(String(resolved["path"]))
	_apply_skin_tone()
	queue_redraw()

## Masks are keyed by gender+hairstyle only (see CharacterAppearanceCatalog) --
## face/hand shape doesn't change with hair_color, so the same mask is reused
## across all 3 hair colors for a given hairstyle. The palette color itself
## comes from skin_tone independently.
func _apply_skin_tone() -> void:
	if _skin_tone_material == null:
		return
	var mask_path := CharacterAppearanceCatalog.skin_mask_path(gender, hairstyle)
	var mask_texture: Texture2D = null
	if not mask_path.is_empty():
		mask_texture = AssetCatalog.load_png_texture(mask_path)
	if mask_texture == null:
		mask_texture = _get_empty_mask_texture()
	_skin_tone_material.set_shader_parameter("skin_mask_texture", mask_texture)
	var colors: Dictionary = CharacterAppearanceCatalog.skin_palette_colors(skin_tone)
	_skin_tone_material.set_shader_parameter("skin_shadow_color", colors["shadow"])
	_skin_tone_material.set_shader_parameter("skin_mid_color", colors["midtone"])
	_skin_tone_material.set_shader_parameter("skin_highlight_color", colors["highlight"])

static func _get_empty_mask_texture() -> ImageTexture:
	if _empty_mask_texture == null:
		var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		image.set_pixel(0, 0, Color(0, 0, 0, 0))
		_empty_mask_texture = ImageTexture.create_from_image(image)
	return _empty_mask_texture

func setup(new_facing: Vector2, new_inside: bool, new_suit_o2: float, is_moving: bool = false, new_walk_phase: float = 0.0, new_is_suit_worn: bool = false) -> void:
	if _playing_transition_animation:
		return
	facing = new_facing
	inside = new_inside
	suit_o2 = new_suit_o2
	moving = is_moving
	walk_phase = new_walk_phase
	is_suit_worn = new_is_suit_worn
	queue_redraw()

func _draw() -> void:
	if astronaut_texture != null:
		_draw_astronaut_sprite()
		return
	if _sprite_layer != null:
		_sprite_layer.sprite_texture = null
		_sprite_layer.queue_redraw()
	if _rings_layer != null:
		_rings_layer.suit_o2 = 100.0
		_rings_layer.inside = true
		_rings_layer.queue_redraw()
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
	# When the suit is worn, swap in the suit walk-cycle for the current
	# suit_marking_color instead of the normal appearance texture -- same
	# 6-frame/4-row (down/left/right/up) contract, just a fixed 512x512
	# native cell, so _direction_row()/display_size scaling apply unchanged.
	# Computed locally (not written back to astronaut_texture/frame_size) so
	# taking the suit back off immediately resumes the appearance texture.
	# The skin-tone shader material is also suppressed while suit-worn --
	# it's aligned to the appearance sheet's per-hairstyle hand/face mask,
	# and leaving it bound while sampling the completely different suit
	# sheet bled mask-colored patches through the helmet.
	var active_texture := astronaut_texture
	var active_frame_size := frame_size
	var active_display_size := display_size
	var flip_source := false
	if is_suit_worn:
		active_texture = AssetCatalog.load_png_texture("res://assets/characters/suits/walk_cycle_%s.png" % suit_marking_color)
		active_frame_size = SUIT_UP_FRAME_SIZE
		active_display_size = active_frame_size * (DISPLAY_HEIGHT / active_frame_size.y)
		_sprite_layer.material = null
		# Suit sheet rebuild (2026-07-20, user/suit/rebuild_20260720): left
		# and right are genuinely distinct captures now (confirmed by the
		# delivery manifest), but the User found the two SOURCE VIDEOS
		# themselves had inconsistent gait types -- right reads as a normal
		# walk, left reads more like running -- so playing them side by
		# side looks mismatched even though both are individually valid
		# footage. Per explicit instruction: standardize on right (walk) as
		# the sole side-walking master and derive left by mirroring it
		# (same frame index, spatial flip only, no temporal reversal --
		# unlike the old broken asset, this master is confirmed good
		# footage, so a plain mirror is expected to read correctly).
		if row == 1:
			flip_source = true
	else:
		_sprite_layer.material = _skin_tone_material
	var source_row := 2 if (is_suit_worn and (row == 1 or row == 2)) else row
	# Both manual-Rect2-mirroring attempts hit real Godot rendering issues:
	# a negative-width SOURCE rect made the mirrored sprite flicker/
	# disappear intermittently (likely draw_texture_rect_region()'s
	# clip_uv assuming a normalized source region), and a negative-width
	# DEST rect caused a visible position jump when switching direction,
	# even though the bounding-box math for both was verified correct.
	# Mirroring is now done via _sprite_layer's own `scale.x = -1` instead
	# -- Godot's actual first-class, well-tested 2D mirroring mechanism.
	# User confirmed this is fine specifically because it's scoped to this
	# inner sprite-drawing child only (not the whole player_visual node,
	# so the shadow rect drawn by this script's own _draw() and the O2
	# rings drawn by _rings_layer are unaffected) -- both source and dest
	# rects always stay normalized/unflipped now, at every direction.
	_sprite_layer.scale = Vector2(-1.0, 1.0) if flip_source else Vector2(1.0, 1.0)
	var source := Rect2(Vector2(frame * active_frame_size.x, source_row * active_frame_size.y), active_frame_size)
	var dest := Rect2(Vector2(-active_display_size.x * 0.5, -active_display_size.y + 16), active_display_size)
	_sprite_layer.sprite_texture = active_texture
	_sprite_layer.source_rect = source
	_sprite_layer.dest_rect = dest
	_sprite_layer.queue_redraw()
	_rings_layer.suit_o2 = suit_o2
	_rings_layer.inside = inside
	_rings_layer.queue_redraw()

## One-shot suit-donning transition. Picks the front (facing-camera) or back
## (facing-away) variant based on the CURRENT facing at call time -- the
## suit-control training room's rack sits above the player's spawn point, so
## they're normally facing up/away when they confirm, but this stays
## direction-driven rather than hardcoded so any other call site (a
## different room layout, a future EVA suit-up moment) picks correctly too.
## Blocks setup() from overwriting the manually-driven frame until done, then
## leaves is_suit_worn true and facing/moving as they already were -- the
## normal _draw_astronaut_sprite() path then lands on the exact frame the
## art spec calls for (down row 00 for front, up row 00 for back) with no
## special-casing needed.
func play_suit_up_animation(color_id: String) -> void:
	_playing_transition_animation = true
	var use_back := facing.y < -0.1
	var sheet_path := "res://assets/characters/suits/suit_helmet_lower_back_%s.png" % color_id if use_back else "res://assets/characters/suits/suit_up_%s.png" % color_id
	var durations: Array[float] = SUIT_UP_BACK_DURATIONS if use_back else SUIT_UP_FRONT_DURATIONS
	var texture := AssetCatalog.load_png_texture(sheet_path)
	var dest := Rect2(Vector2(-display_size.x * 0.5, -display_size.y + 16), display_size)
	for frame_index in range(durations.size()):
		var col := frame_index % SUIT_UP_COLS
		var row := frame_index / SUIT_UP_COLS
		_sprite_layer.sprite_texture = texture
		_sprite_layer.source_rect = Rect2(Vector2(col * SUIT_UP_FRAME_SIZE.x, row * SUIT_UP_FRAME_SIZE.y), SUIT_UP_FRAME_SIZE)
		_sprite_layer.dest_rect = dest
		_sprite_layer.queue_redraw()
		await get_tree().create_timer(durations[frame_index]).timeout
	suit_marking_color = color_id
	is_suit_worn = true
	_playing_transition_animation = false
	queue_redraw()

func _direction_row() -> int:
	if abs(facing.x) > abs(facing.y):
		return 2 if facing.x > 0.0 else 1
	if facing.y < 0.0:
		return 3
	return 0
