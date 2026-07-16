extends Node2D
class_name ReferenceProp

@export var prop_kind := "console"
@export var prop_size := Vector2(160, 90)
@export var prop_label := ""
@export var active := false
@export var damaged := false
@export var status_text := ""

## TR-002 训练中控室 real art (replaces the procedural placeholder for these
## 3 kinds only -- every other kind above is untouched and still draws via
## its own _draw_x() primitive function).
const HubDoorHorizontalTexture := preload("res://assets/art/training_hub/props/door_frame_horizontal.png")
const HubDoorVerticalTexture := preload("res://assets/art/training_hub/props/door_frame_vertical.png")
const LunarBaseAtlasScript := preload("res://scripts/data/lunar_base_atlas.gd")

var _hub_console_texture: AtlasTexture

func _ready() -> void:
	# Pixel-art-sourced hub textures should sample Nearest, not the engine's
	# default Linear -- only affects draw_texture_rect() calls (the many
	# draw_rect()/draw_line() primitive kinds above don't sample a texture,
	# so this is a no-op for them).
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hub_console_texture = LunarBaseAtlasScript.region("console_command_center")

func _draw() -> void:
	match prop_kind:
		"old_floor_tile":
			_draw_old_floor_tile()
		"old_wall_module":
			_draw_old_wall_module()
		"old_wall_frame":
			_draw_wall_frame()
		"floor_tiles":
			_draw_floor_tiles()
		"console":
			_draw_console()
		"power_panel":
			_draw_power_panel()
		"greenhouse_door":
			_draw_door()
		"storage_locker":
			_draw_locker()
		"maintenance_note":
			_draw_note()
		"log_marker":
			_draw_log_marker()
		"wall_light":
			_draw_wall_light()
		"dust_marks":
			_draw_dust()
		"hydro_rack":
			_draw_hydro_rack()
		"plant_chamber":
			_draw_plant_chamber()
		"last_plant":
			_draw_last_plant()
		"plant_monitor":
			_draw_monitor()
		"grow_light":
			_draw_grow_light()
		"water_panel":
			_draw_power_panel()
		"solar_panel":
			_draw_solar_panel()
		"cable":
			_draw_cable()
		"support_frame":
			_draw_support_frame()
		"repair_marker":
			_draw_repair_marker()
		"lunar_rock":
			_draw_lunar_rock()
		"footprint_decal":
			_draw_footprint_decal()
		"earth":
			_draw_earth()
		"distant_base":
			_draw_distant_base()
		"tool_station":
			_draw_tool_station()
		"test_light":
			_draw_test_light()
		"ventilation":
			_draw_ventilation()
		"training_exit":
			_draw_training_exit()
		"hub_door_horizontal":
			_draw_textured_prop(HubDoorHorizontalTexture)
		"hub_door_vertical":
			_draw_textured_prop(HubDoorVerticalTexture)
		"hub_console":
			_draw_textured_prop(_hub_console_texture)
		_:
			_draw_console()

func _label(pos: Vector2, color: Color = Color("#c8d8e2"), font_size: int = 14) -> void:
	if prop_label.is_empty():
		return
	draw_string(ThemeDB.fallback_font, pos, prop_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

## Draws `texture` "contain"-fit within prop_size (scaled to fit fully inside,
## centered, preserving the art's own aspect ratio) rather than stretching it
## to match whichever interaction-zone box this prop happens to occupy --
## avoids distorting real art to fit a placeholder-era hitbox size.
##
## No state-tint/border is drawn here (a first pass added one; User feedback
## was that an always-on colored box around every prop read as a debug
## collision outline, not in-world art). Highlight/lock-dim/interact-prompt
## feedback stays entirely on the existing TrainingTargetVisual-level system
## (`node.modulate` dimming + `_draw_highlight_ring()` + `prompt_label`),
## unchanged from before this class existed.
func _draw_textured_prop(texture: Texture2D) -> void:
	var tex_size := texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0 or prop_size.x <= 0.0 or prop_size.y <= 0.0:
		return
	var fit_scale: float = min(prop_size.x / tex_size.x, prop_size.y / tex_size.y)
	var draw_size := tex_size * fit_scale
	var draw_pos := (prop_size - draw_size) * 0.5
	draw_texture_rect(texture, Rect2(draw_pos, draw_size), false)

func _draw_wall_frame() -> void:
	var r := Rect2(Vector2.ZERO, prop_size)
	draw_rect(r, Color("#0b1117"), true)
	draw_rect(r.grow(-26), Color("#20272b"), true)
	draw_rect(r, Color("#72818a", 0.56), false, 8)
	draw_rect(r.grow(-26), Color("#39464e", 0.72), false, 4)
	for x in range(48, int(prop_size.x), 96):
		draw_line(Vector2(x, 0), Vector2(x, 28), Color("#54636b", 0.55), 3)
		draw_line(Vector2(x, prop_size.y - 28), Vector2(x, prop_size.y), Color("#54636b", 0.55), 3)

func _draw_floor_tiles() -> void:
	var r := Rect2(Vector2.ZERO, prop_size)
	draw_rect(r, Color("#1b2021"), true)
	for x in range(0, int(prop_size.x), 64):
		draw_line(Vector2(x, 0), Vector2(x, prop_size.y), Color("#343c3e", 0.46), 1)
	for y in range(0, int(prop_size.y), 64):
		draw_line(Vector2(0, y), Vector2(prop_size.x, y), Color("#343c3e", 0.46), 1)
	for i in range(10):
		draw_circle(Vector2(34 + i * 83, prop_size.y - 58 + sin(float(i)) * 18), 3, Color("#8b7a62", 0.18))

func _draw_old_floor_tile() -> void:
	var r := Rect2(Vector2.ZERO, prop_size)
	draw_rect(r, Color("#1b2021"), true)
	draw_rect(r, Color("#384044", 0.45), false, 1)
	draw_line(Vector2(0, prop_size.y), Vector2(prop_size.x, 0), Color("#2a3134", 0.35), 1)
	draw_circle(prop_size * Vector2(0.28, 0.72), 2, Color("#8b7a62", 0.18))

func _draw_old_wall_module() -> void:
	var r := Rect2(Vector2.ZERO, prop_size)
	draw_rect(r, Color("#252c30"), true)
	draw_rect(r.grow(-8), Color("#151c20"), true)
	draw_rect(r, Color("#6b7a82", 0.45), false, 3)
	draw_line(Vector2(18, prop_size.y * 0.5), Vector2(prop_size.x - 18, prop_size.y * 0.5), Color("#4d5a61", 0.5), 2)
	_label(Vector2(8, prop_size.y + 18), Color("#8fa3b2"))

func _draw_console() -> void:
	var r := Rect2(Vector2.ZERO, prop_size)
	draw_rect(r, Color("#313b42"), true)
	draw_rect(r.grow(-12), Color("#101820"), true)
	if status_text.is_empty():
		var screen := Color("#2f82b6", 0.85) if active else Color("#41505a", 0.44)
		draw_rect(Rect2(Vector2(24, 20), Vector2(prop_size.x - 48, 30)), screen, true)
		draw_rect(Rect2(Vector2(26, prop_size.y - 28), Vector2(prop_size.x - 52, 6)), Color("#e2bf63", 0.35 if active else 0.14), true)
	else:
		# Terminal state feedback: standby / active / fault / completed.
		var screen_color := Color("#41505a", 0.44)
		var bar_alpha := 0.14
		match status_text:
			"active", "restored", "on", "open", "ready":
				screen_color = Color("#2f82b6", 0.85)
				bar_alpha = 0.35
			"stabilizing":
				screen_color = Color("#e2bf63", 0.72)
				bar_alpha = 0.4
			"fault":
				screen_color = Color("#d66a4f", 0.75)
				bar_alpha = 0.4
			"completed", "complete", "stable":
				screen_color = Color("#7dbd75", 0.8)
				bar_alpha = 0.3
		draw_rect(Rect2(Vector2(24, 20), Vector2(prop_size.x - 48, 30)), screen_color, true)
		draw_rect(Rect2(Vector2(26, prop_size.y - 28), Vector2(prop_size.x - 52, 6)), Color("#e2bf63", bar_alpha), true)
	_label(Vector2(6, -8))

func _draw_power_panel() -> void:
	var r := Rect2(Vector2.ZERO, prop_size)
	draw_rect(r, Color("#2b3337"), true)
	draw_rect(r.grow(-10), Color("#111820"), true)
	if status_text.is_empty():
		var warn := Color("#d66a4f", 0.62 if damaged else 0.12)
		draw_rect(r, warn, false, 3)
		for i in range(4):
			draw_line(Vector2(22 + i * 24, 38), Vector2(30 + i * 24, prop_size.y - 34), Color("#b45a56", 0.58 if damaged else 0.12), 2)
		draw_circle(Vector2(prop_size.x - 20, 22), 6, Color("#d66a4f", 0.78 if damaged else 0.16))
	else:
		# Power panel state feedback: repairing (warning blink) / restored / fault.
		match status_text:
			"repairing":
				draw_rect(r, Color("#e2bf63", 0.55), false, 3)
				for i in range(4):
					draw_line(Vector2(22 + i * 24, 38), Vector2(30 + i * 24, prop_size.y - 34), Color("#e2bf63", 0.42), 2)
				draw_circle(Vector2(prop_size.x - 20, 22), 6, Color("#e2bf63", 0.68))
			"restored", "on", "repaired":
				draw_rect(r, Color("#4fb7f0", 0.22), false, 3)
				draw_circle(Vector2(prop_size.x - 20, 22), 6, Color("#7dbd75", 0.78))
			"fault", "damaged":
				draw_rect(r, Color("#d66a4f", 0.62), false, 3)
				for i in range(4):
					draw_line(Vector2(22 + i * 24, 38), Vector2(30 + i * 24, prop_size.y - 34), Color("#b45a56", 0.58), 2)
				draw_circle(Vector2(prop_size.x - 20, 22), 6, Color("#d66a4f", 0.78))
			_:
				draw_rect(r, Color("#d66a4f", 0.12), false, 3)
				draw_circle(Vector2(prop_size.x - 20, 22), 6, Color("#d66a4f", 0.16))
	_label(Vector2(6, -8))

func _draw_door() -> void:
	var r := Rect2(Vector2.ZERO, prop_size)
	draw_rect(r, Color("#2c3740"), true)
	draw_rect(r.grow(-12), Color("#141c24"), true)
	if status_text.is_empty():
		draw_rect(r, Color("#9fb2c0", 0.56 if active else 0.28), false, 3)
		draw_line(Vector2(prop_size.x * 0.5, 16), Vector2(prop_size.x * 0.5, prop_size.y - 16), Color("#d8e7f2", 0.34), 2)
	else:
		# Airlock state feedback: locked / unlocking / opened / emergency.
		match status_text:
			"locked":
				draw_rect(r, Color("#d66a4f", 0.5), false, 3)
				draw_line(Vector2(prop_size.x * 0.5, 16), Vector2(prop_size.x * 0.5, prop_size.y - 16), Color("#d8e7f2", 0.34), 2)
			"unlocking":
				draw_rect(r, Color("#e2bf63", 0.55), false, 3)
				draw_line(Vector2(prop_size.x * 0.5, 16), Vector2(prop_size.x * 0.5, prop_size.y - 16), Color("#e2bf63", 0.4), 2)
			"opened":
				draw_rect(r, Color("#4fb7f0", 0.6), false, 3)
			"emergency":
				draw_rect(r, Color("#d66a4f", 0.85), false, 4)
				draw_line(Vector2(prop_size.x * 0.5, 16), Vector2(prop_size.x * 0.5, prop_size.y - 16), Color("#d66a4f", 0.7), 3)
			_:
				draw_rect(r, Color("#9fb2c0", 0.28), false, 3)
				draw_line(Vector2(prop_size.x * 0.5, 16), Vector2(prop_size.x * 0.5, prop_size.y - 16), Color("#d8e7f2", 0.34), 2)
	if damaged:
		# `damaged` doubles as a generic "locked" flag for doors without an
		# explicit status_text state (e.g. training airlock doors).
		draw_rect(Rect2(Vector2(12, prop_size.y * 0.5 - 14), Vector2(prop_size.x - 24, 22)), Color("#0d1822", 0.72), true)
		draw_string(ThemeDB.fallback_font, Vector2(18, prop_size.y * 0.5 + 4), "锁定", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#9fb2c0"))
	_label(Vector2(-6, -8))

func _draw_locker() -> void:
	var r := Rect2(Vector2.ZERO, prop_size)
	draw_rect(r, Color("#303941"), true)
	for i in range(2):
		var bay := Rect2(Vector2(16 + i * (prop_size.x * 0.45), 24), Vector2(prop_size.x * 0.34, prop_size.y - 48))
		draw_rect(bay, Color("#1d2630"), true)
		draw_rect(bay, Color("#5e6c76", 0.35), false, 1)
	_label(Vector2(0, prop_size.y + 24), Color("#8fa3b2"))

func _draw_note() -> void:
	var r := Rect2(Vector2.ZERO, prop_size)
	draw_rect(r, Color("#252c32"), true)
	draw_rect(r, Color("#b7a878", 0.25), false, 1)
	_label(Vector2(14, prop_size.y * 0.58), Color("#b7a878"))

func _draw_log_marker() -> void:
	var r := Rect2(Vector2.ZERO, prop_size)
	draw_rect(r, Color("#202830"), true)
	draw_rect(r, Color("#2f82b6", 0.16), false, 1)
	_label(Vector2(16, prop_size.y * 0.62), Color("#8fa3b2"), 15)

func _draw_wall_light() -> void:
	var c := Color("#f0c766", 0.55 if active else 0.16)
	draw_rect(Rect2(Vector2.ZERO, prop_size), Color("#2d353a"), true)
	draw_rect(Rect2(Vector2(10, 5), prop_size - Vector2(20, 10)), c, true)
	if active:
		draw_circle(prop_size * 0.5, prop_size.x * 0.7, Color("#f0c766", 0.055))

func _draw_dust() -> void:
	for i in range(18):
		draw_circle(Vector2(10 + i * 34, 18 + sin(float(i) * 0.7) * 14), 3, Color("#8b7a62", 0.22))
	for i in range(6):
		var p := Vector2(42 + i * 48, 56 + sin(float(i)) * 8)
		draw_ellipse(p, 10, 4, Color("#766b5b", 0.22))

func _draw_hydro_rack() -> void:
	var r := Rect2(Vector2.ZERO, prop_size)
	draw_rect(r, Color("#26332e"), true)
	draw_rect(r, Color("#56685d", 0.45), false, 2)
	for row in range(3):
		var y := 44 + row * 62
		draw_rect(Rect2(Vector2(12, y), Vector2(prop_size.x - 24, 20)), Color("#171f1b"), true)
		draw_line(Vector2(24, y + 8), Vector2(prop_size.x - 24, y + 20), Color("#766d55", 0.56 if damaged else 0.32), 4)
		if damaged:
			draw_circle(Vector2(34 + row * 28, y - 10), 9, Color("#4b5136", 0.36))
		elif active:
			draw_circle(Vector2(42 + row * 32, y - 10), 8, Color("#6fa765", 0.42))

func _draw_plant_chamber() -> void:
	var r := Rect2(Vector2.ZERO, prop_size)
	if status_text.is_empty():
		var frame := Color("#3a4446") if active else Color("#333b3e")
		draw_rect(r, frame, true)
		draw_rect(r.grow(-18), Color("#111a18", 0.78), true)
		draw_rect(r.grow(-18), Color("#b8d8ce", 0.22), false, 2)
		draw_rect(Rect2(Vector2(prop_size.x - 54, 20), Vector2(34, prop_size.y - 40)), Color("#1a2224"), true)
		var plant_color := Color("#77b86d") if active else Color("#7b7540")
		draw_line(Vector2(prop_size.x * 0.46, prop_size.y - 58), Vector2(prop_size.x * 0.46, prop_size.y * (0.38 if active else 0.48)), plant_color, 5)
		draw_circle(Vector2(prop_size.x * 0.39, prop_size.y * (0.42 if active else 0.52)), 16, plant_color)
		draw_circle(Vector2(prop_size.x * 0.54, prop_size.y * (0.48 if active else 0.58)), 14, plant_color.darkened(0.1))
		if not active:
			draw_line(Vector2(prop_size.x * 0.39, prop_size.y * 0.52), Vector2(prop_size.x * 0.31, prop_size.y * 0.64), plant_color, 3)
	else:
		# Plant chamber state feedback: abnormal / stabilizing / stable.
		var stable_state := status_text == "stable"
		var stabilizing_state := status_text == "stabilizing"
		draw_rect(r, Color("#3a4446") if stable_state else Color("#333b3e"), true)
		draw_rect(r.grow(-18), Color("#111a18", 0.78), true)
		draw_rect(r.grow(-18), Color("#b8d8ce", 0.22), false, 2)
		draw_rect(Rect2(Vector2(prop_size.x - 54, 20), Vector2(34, prop_size.y - 40)), Color("#1a2224"), true)
		var plant_color := Color("#7dbd75", 0.92) if stable_state else Color("#6f8f62", 0.72 if stabilizing_state else 0.55)
		draw_line(Vector2(prop_size.x * 0.46, prop_size.y - 58), Vector2(prop_size.x * 0.46, prop_size.y * (0.38 if stable_state else 0.48)), plant_color, 5)
		draw_circle(Vector2(prop_size.x * 0.39, prop_size.y * (0.42 if stable_state else 0.52)), 16, plant_color)
		draw_circle(Vector2(prop_size.x * 0.54, prop_size.y * (0.48 if stable_state else 0.58)), 14, plant_color.darkened(0.1))
		if not stable_state:
			draw_line(Vector2(prop_size.x * 0.39, prop_size.y * 0.52), Vector2(prop_size.x * 0.31, prop_size.y * 0.64), plant_color, 3)
	_label(Vector2(10, -8))

func _draw_last_plant() -> void:
	var stem_x := prop_size.x * 0.5
	var root_y := prop_size.y - 14
	var critical := damaged or status_text.to_lower() == "critical"
	var recovering := status_text.to_lower() == "recovering"
	var plant_color := Color("#77b86d") if active else Color("#7b7540")
	if recovering:
		plant_color = Color("#8eaa62")
	if critical:
		plant_color = Color("#6d693a")
	var top_y := prop_size.y * (0.28 if active else 0.42)
	draw_line(Vector2(stem_x, root_y), Vector2(stem_x, top_y), plant_color, 5)
	var droop := 18 if critical else 4
	draw_circle(Vector2(stem_x - 18, top_y + droop), 13, plant_color)
	draw_circle(Vector2(stem_x + 18, top_y + droop * 0.6), 12, plant_color.darkened(0.08))
	draw_circle(Vector2(stem_x, top_y - (8 if active else 0)), 10, plant_color.lightened(0.06))
	draw_rect(Rect2(Vector2(stem_x - 36, root_y + 4), Vector2(72, 8)), Color("#213029"), true)

func _draw_monitor() -> void:
	_draw_console()
	var c := Color("#7dbd75") if active else Color("#d66a4f")
	var text := "Stable" if active else "Critical"
	draw_string(ThemeDB.fallback_font, Vector2(26, prop_size.y - 24), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, c)
	draw_rect(Rect2(Vector2(24, prop_size.y - 18), Vector2(prop_size.x - 48, 5)), c, true)

func _draw_grow_light() -> void:
	var on := (status_text == "on" or status_text == "stable") if not status_text.is_empty() else active
	var c := Color("#f0d28c", 0.76) if on else Color("#6f8493", 0.18)
	draw_rect(Rect2(Vector2.ZERO, prop_size), Color("#2d353a"), true)
	draw_rect(Rect2(Vector2(16, 12), prop_size - Vector2(32, 24)), c, true)
	if on:
		draw_circle(Vector2(prop_size.x * 0.5, prop_size.y + 135), 180, Color("#f0d28c", 0.08))
	_label(Vector2(8, -8))

func _draw_solar_panel() -> void:
	var r := Rect2(Vector2.ZERO, prop_size)
	var body := Color("#1d3342") if not damaged else Color("#24303a")
	draw_rect(r, body, true)
	draw_rect(r, Color("#81929d", 0.55), false, 3)
	for x in range(20, int(prop_size.x), 42):
		draw_line(Vector2(x, 8), Vector2(x, prop_size.y - 8), Color("#c0a965", 0.32), 1)
	for y in range(18, int(prop_size.y), 30):
		draw_line(Vector2(8, y), Vector2(prop_size.x - 8, y), Color("#c0a965", 0.25), 1)
	if damaged:
		draw_line(Vector2(prop_size.x * 0.18, prop_size.y * 0.22), Vector2(prop_size.x * 0.62, prop_size.y * 0.72), Color("#d9d0b0", 0.55), 2)
		draw_rect(r, Color("#b5b0a0", 0.14), true)

func _draw_cable() -> void:
	draw_line(Vector2.ZERO, prop_size, Color("#111820", 0.9), 8)
	draw_line(Vector2.ZERO, prop_size * 0.48, Color("#c96f55", 0.85), 3)
	draw_circle(prop_size * 0.52, 8, Color("#d66a4f", 0.8))

func _draw_support_frame() -> void:
	var c := Color("#7e8585", 0.62)
	draw_line(Vector2(0, prop_size.y), Vector2(prop_size.x * 0.5, 0), c, 5)
	draw_line(Vector2(prop_size.x, prop_size.y), Vector2(prop_size.x * 0.5, 0), c, 5)
	draw_line(Vector2(10, prop_size.y * 0.68), Vector2(prop_size.x - 10, prop_size.y * 0.68), c, 4)

func _draw_repair_marker() -> void:
	draw_circle(prop_size * 0.5, min(prop_size.x, prop_size.y) * 0.45, Color("#f0c766", 0.12))
	draw_circle(prop_size * 0.5, min(prop_size.x, prop_size.y) * 0.32, Color("#f0c766", 0.65))
	_label(Vector2(0, prop_size.y + 18), Color("#f0c766"))

func _draw_lunar_rock() -> void:
	draw_ellipse(prop_size * 0.5, prop_size.x * 0.45, prop_size.y * 0.34, Color("#5f6464"))
	draw_ellipse(prop_size * 0.45, prop_size.x * 0.2, prop_size.y * 0.18, Color("#8a8e8d", 0.28))

func _draw_footprint_decal() -> void:
	for i in range(5):
		var p := Vector2(16 + i * 28, 20 + sin(float(i) * 0.8) * 8)
		draw_ellipse(p, 8, 3, Color("#d7d1c2", 0.18))
		draw_ellipse(p + Vector2(10, 14), 8, 3, Color("#d7d1c2", 0.14))

func _draw_earth() -> void:
	draw_circle(prop_size * 0.5, min(prop_size.x, prop_size.y) * 0.36, Color("#4faee8", 0.82))
	draw_circle(prop_size * 0.5 + Vector2(-6, -4), min(prop_size.x, prop_size.y) * 0.42, Color("#4faee8", 0.08))
	draw_circle(prop_size * 0.5 + Vector2(8, -4), 8, Color("#d8e7f2", 0.38))

func _draw_distant_base() -> void:
	draw_rect(Rect2(Vector2(0, prop_size.y * 0.35), prop_size * Vector2(1, 0.45)), Color("#252c32"), true)
	for i in range(4):
		draw_rect(Rect2(Vector2(20 + i * 34, prop_size.y * 0.55), Vector2(14, 5)), Color("#f0c766", 0.72), true)
	_label(Vector2(0, -8), Color("#8fa3b2"))

func _draw_tool_station() -> void:
	draw_rect(Rect2(Vector2(6, 34), Vector2(prop_size.x - 12, prop_size.y - 40)), Color("#303d47"), true)
	draw_rect(Rect2(Vector2(0, 24), Vector2(prop_size.x, 16)), Color("#52616c"), true)
	draw_rect(Rect2(Vector2(18, 8), Vector2(26, 18)), Color("#7d8b94"), true)
	draw_rect(Rect2(Vector2(58, 10), Vector2(46, 8)), Color("#f0c766", 0.7), true)
	draw_line(Vector2(64, 18), Vector2(96, 30), Color("#d8e7f2", 0.65), 3.0)
	draw_rect(Rect2(Vector2(22, 54), Vector2(18, 18)), Color("#1a2b38"), true)
	draw_rect(Rect2(Vector2(52, 54), Vector2(18, 18)), Color("#1a2b38"), true)
	_label(Vector2(6, -8))

func _draw_test_light() -> void:
	var on := status_text == "on"
	var center := prop_size * 0.5
	draw_rect(Rect2(Vector2(8, prop_size.y - 18), Vector2(prop_size.x - 16, 12)), Color("#303b44"), true)
	draw_line(Vector2(center.x, 8), Vector2(center.x, prop_size.y - 22), Color("#5d6f7d"), 4.0)
	var glow := Color("#f0c766", 0.85) if on else Color("#5d6f7d", 0.35)
	draw_circle(center + Vector2(0, -6), 18, Color(glow.r, glow.g, glow.b, 0.22 if on else 0.1))
	draw_circle(center + Vector2(0, -6), 10, glow)
	if on:
		draw_circle(center + Vector2(0, -6), 28, Color("#f0c766", 0.08))

func _draw_ventilation() -> void:
	var active_state := status_text == "stable" or status_text == "stabilizing"
	draw_rect(Rect2(Vector2.ZERO, prop_size), Color("#303d47"), true)
	draw_rect(Rect2(Vector2(10, 10), prop_size - Vector2(20, 20)), Color("#101d28"), true)
	var air_color := Color("#9fd7ff", 0.65) if active_state else Color("#5d6f7d", 0.35)
	for i in range(5):
		var y := 18 + i * 10
		draw_line(Vector2(18, y), Vector2(prop_size.x - 18, y), air_color, 2.0)
	if active_state:
		draw_rect(Rect2(Vector2(18, prop_size.y - 18), Vector2(prop_size.x - 36, 4)), Color("#9fd7ff", 0.5), true)

func _draw_training_exit() -> void:
	var locked := not active
	var edge := Color("#89d8ff", 0.28) if locked else Color("#f0c766", 0.7)
	draw_rect(Rect2(Vector2(14, 0), Vector2(prop_size.x - 28, prop_size.y)), Color("#34414c"), true)
	draw_rect(Rect2(Vector2(24, 10), Vector2(prop_size.x - 48, prop_size.y - 20)), Color("#1d2832"), true)
	draw_line(Vector2(prop_size.x * 0.5, 12), Vector2(prop_size.x * 0.5, prop_size.y - 12), Color("#d8e7f2", 0.55), 2.0)
	draw_rect(Rect2(Vector2(4, 18), Vector2(10, prop_size.y - 36)), edge, true)
	draw_rect(Rect2(Vector2(prop_size.x - 14, 18), Vector2(10, prop_size.y - 36)), edge, true)
	draw_rect(Rect2(Vector2(28, prop_size.y - 20), Vector2(prop_size.x - 56, 4)), Color("#f0c766", 0.18 if locked else 0.55), true)
	if locked:
		draw_string(ThemeDB.fallback_font, Vector2(28, prop_size.y * 0.5), "锁定", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#8fa3b2"))
