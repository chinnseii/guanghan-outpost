extends Control

## Two-figure appearance preview: one WITHOUT the EVA suit (plain jumpsuit,
## visible head) and one WITH it (helmet + visor + marking). `suited`
## selects which one this control draws. Layout keeps the whole figure in
## the upper region with a caption at the very bottom, clear of the legs, so
## nothing overlaps the id/label text (user-reported: legs covered the
## GH-01 / GH-2068-0421 labels).

@export var suited := true
@export var suit_id := "GH-2068-0421"
@export var patch_id := "GH-01"
@export var marking_color := Color("#d6a83e")

const CAPTION_FONT_SIZE := 15

func _ready() -> void:
	custom_minimum_size = Vector2(210, 300)
	queue_redraw()

func _draw() -> void:
	# Figure sits in the upper ~250px; caption goes in the bottom band.
	var center := Vector2(size.x * 0.5, 92)
	draw_ellipse(center + Vector2(0, 150), 46, 9, Color("#020406", 0.30))
	if suited:
		_draw_suited(center)
	else:
		_draw_unsuited(center)
	var top_caption := "任务宇航服" if suited else "未穿宇航服"
	var bottom_caption := suit_id if suited else patch_id
	draw_string(ThemeDB.fallback_font, Vector2(6, 22), top_caption,
		HORIZONTAL_ALIGNMENT_CENTER, size.x - 12, CAPTION_FONT_SIZE, Color("#8fb4d6"))
	draw_string(ThemeDB.fallback_font, Vector2(6, size.y - 12), bottom_caption,
		HORIZONTAL_ALIGNMENT_CENTER, size.x - 12, 13, Color("#d8e7f2"))

## Plain body: slimmer, visible head, no helmet/visor. A small collar badge
## carries the marking color so both figures still read as "the same person".
func _draw_unsuited(center: Vector2) -> void:
	var body := Color("#c3ccd4")
	draw_line(center + Vector2(-12, 96), center + Vector2(-18, 158), body, 13)
	draw_line(center + Vector2(12, 96), center + Vector2(18, 158), body, 13)
	draw_line(center + Vector2(-25, 40), center + Vector2(-39, 94), body, 11)
	draw_line(center + Vector2(25, 40), center + Vector2(39, 94), body, 11)
	draw_rect(Rect2(center + Vector2(-25, 24), Vector2(50, 74)), Color("#cfd6dd"))
	draw_rect(Rect2(center + Vector2(-7, 26), Vector2(14, 10)), marking_color)
	draw_rect(Rect2(center + Vector2(-7, 8), Vector2(14, 18)), Color("#d7dee4"))
	draw_circle(center + Vector2(0, -8), 25, Color("#e2e8ed"))
	draw_rect(Rect2(center + Vector2(-11, -12), Vector2(22, 4)), Color("#9aa6b0"))

## EVA suit: bulkier torso/limbs, helmet with dark visor, chest panel, plus
## the marking dot + stripe.
func _draw_suited(center: Vector2) -> void:
	var suit := Color("#d0d7dd")
	draw_line(center + Vector2(-16, 100), center + Vector2(-26, 162), Color("#c5ced6"), 15)
	draw_line(center + Vector2(16, 100), center + Vector2(26, 162), Color("#c5ced6"), 15)
	draw_line(center + Vector2(-32, 44), center + Vector2(-52, 100), Color("#c5ced6"), 14)
	draw_line(center + Vector2(32, 44), center + Vector2(52, 100), Color("#c5ced6"), 14)
	draw_rect(Rect2(center + Vector2(-34, 24), Vector2(68, 84)), suit)
	draw_rect(Rect2(center + Vector2(-25, 30), Vector2(50, 30)), Color("#aeb8c1"))
	draw_circle(center + Vector2(0, -6), 30, Color("#e1e8ed"))
	draw_rect(Rect2(center + Vector2(-20, -16), Vector2(40, 22)), Color("#101d2a"))
	draw_circle(center + Vector2(-22, 58), 7, marking_color)
	draw_rect(Rect2(center + Vector2(8, 72), Vector2(20, 8)), marking_color)
