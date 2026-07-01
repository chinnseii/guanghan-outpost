extends SceneTree

const TILE_DIR := "res://assets/art/old_base/tiles"
const PROP_DIR := "res://assets/art/old_base/props"
const LIGHT_DIR := "res://assets/art/old_base/lighting"
const PLAYER_DIR := "res://assets/art/player"
const OUT_CONTACT := "res://docs/screenshots/sprint08_5_acceptance/10_asset_overview_contact_sheet.png"

func _initialize() -> void:
	_generate()
	quit()

func _generate() -> void:
	for dir in [TILE_DIR, PROP_DIR, LIGHT_DIR, PLAYER_DIR, "res://docs/screenshots/sprint08_5_acceptance"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	_tiles()
	_props()
	_player()
	_lighting()
	_contact_sheet()

func _img(w: int, h: int, color: Color) -> Image:
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return image

func _save(image: Image, path: String) -> void:
	var err := image.save_png(path)
	if err != OK:
		push_error("failed to save %s err=%d" % [path, err])

func _rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)

func _line_h(image: Image, y: int, x0: int, x1: int, color: Color) -> void:
	for x in range(x0, x1 + 1):
		if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
			image.set_pixel(x, y, color)

func _line_v(image: Image, x: int, y0: int, y1: int, color: Color) -> void:
	for y in range(y0, y1 + 1):
		if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
			image.set_pixel(x, y, color)

func _border(image: Image, color: Color) -> void:
	_line_h(image, 0, 0, image.get_width() - 1, color)
	_line_h(image, image.get_height() - 1, 0, image.get_width() - 1, color)
	_line_v(image, 0, 0, image.get_height() - 1, color)
	_line_v(image, image.get_width() - 1, 0, image.get_height() - 1, color)

func _tiles() -> void:
	var base := _img(32, 32, Color("#20282d"))
	_border(base, Color("#334148"))
	_line_h(base, 15, 2, 29, Color("#151b1f"))
	_line_v(base, 15, 2, 29, Color("#2a343a"))
	_save(base, "%s/metal_floor_base.png" % TILE_DIR)

	var seam := _img(32, 32, Color("#20282d"))
	_line_h(seam, 15, 0, 31, Color("#4a555a"))
	_line_h(seam, 16, 0, 31, Color("#11171b"))
	_save(seam, "%s/metal_floor_seam.png" % TILE_DIR)

	var worn := _img(32, 32, Color("#1c2428"))
	_border(worn, Color("#2f3a40"))
	for i in range(10):
		_rect(worn, Rect2i(4 + i * 2, 8 + (i % 4) * 4, 2, 1), Color("#69706b"))
	_save(worn, "%s/metal_floor_worn.png" % TILE_DIR)

	var scuff := _img(32, 32, Color("#20282d"))
	for i in range(8):
		_line_h(scuff, 9 + i * 2, 7, 18 + i, Color("#6d675c"))
	_save(scuff, "%s/metal_floor_scuff.png" % TILE_DIR)

	var cable := _img(32, 32, Color(0, 0, 0, 0))
	_line_h(cable, 17, 0, 31, Color("#101417"))
	_line_h(cable, 18, 0, 31, Color("#6b4f44"))
	_save(cable, "%s/floor_cable_overlay.png" % TILE_DIR)

	var hatch := _img(32, 32, Color("#20282d"))
	_rect(hatch, Rect2i(5, 5, 22, 22), Color("#141a1e"))
	_border(hatch, Color("#59656b"))
	_line_h(hatch, 16, 7, 25, Color("#49555b"))
	_save(hatch, "%s/maintenance_hatch.png" % TILE_DIR)

	var wall := _img(32, 32, Color("#161d22"))
	_border(wall, Color("#3d4a50"))
	_save(wall, "%s/dark_metal_wall.png" % TILE_DIR)

	var wall_seam := _img(32, 32, Color("#171f25"))
	_line_v(wall_seam, 15, 0, 31, Color("#56636a"))
	_line_v(wall_seam, 16, 0, 31, Color("#090d10"))
	_save(wall_seam, "%s/wall_panel_seam.png" % TILE_DIR)

	var frame := _img(32, 32, Color("#12191e"))
	_rect(frame, Rect2i(0, 0, 32, 6), Color("#66737a"))
	_rect(frame, Rect2i(0, 26, 32, 6), Color("#29343a"))
	_save(frame, "%s/reinforced_wall_frame.png" % TILE_DIR)

	var pipe := _img(32, 32, Color(0, 0, 0, 0))
	_line_h(pipe, 12, 0, 31, Color("#637077"))
	_line_h(pipe, 14, 0, 31, Color("#252e34"))
	_save(pipe, "%s/pipe_strip.png" % TILE_DIR)

	var stripe := _img(32, 32, Color("#20282d"))
	for x in range(-16, 32, 8):
		for i in range(5):
			_line_v(stripe, x + i, 0, 31, Color("#b59241"))
	_save(stripe, "%s/warning_stripe.png" % TILE_DIR)

	var door_frame := _img(32, 32, Color("#141b20"))
	_rect(door_frame, Rect2i(0, 0, 6, 32), Color("#647178"))
	_rect(door_frame, Rect2i(26, 0, 6, 32), Color("#647178"))
	_save(door_frame, "%s/door_frame.png" % TILE_DIR)

	var shadow := _img(32, 32, Color(0, 0, 0, 0))
	_rect(shadow, Rect2i(0, 20, 32, 12), Color("#020406", 0.55))
	_save(shadow, "%s/wall_base_shadow.png" % TILE_DIR)

	var boundary := _img(32, 32, Color("#20282d"))
	_rect(boundary, Rect2i(0, 0, 32, 8), Color("#0f1519"))
	_line_h(boundary, 8, 0, 31, Color("#647178"))
	_save(boundary, "%s/floor_wall_boundary.png" % TILE_DIR)

	var threshold := _img(32, 32, Color("#222b30"))
	_rect(threshold, Rect2i(0, 12, 32, 8), Color("#748189"))
	_save(threshold, "%s/door_threshold.png" % TILE_DIR)

	var corner := _img(32, 32, Color("#161d22"))
	_rect(corner, Rect2i(0, 0, 10, 32), Color("#5a6870"))
	_rect(corner, Rect2i(0, 0, 32, 10), Color("#5a6870"))
	_save(corner, "%s/corner_reinforcement.png" % TILE_DIR)

func _props() -> void:
	_save(_console(96, 64, Color("#2b78a2"), "console"), "%s/central_console.png" % PROP_DIR)
	_save(_panel(64, 96, true), "%s/old_power_panel.png" % PROP_DIR)
	_save(_console(88, 64, Color("#357fa4"), "life"), "%s/life_support_console.png" % PROP_DIR)
	_save(_locker(), "%s/storage_cabinet.png" % PROP_DIR)
	_save(_door(), "%s/greenhouse_door.png" % PROP_DIR)
	_save(_conduit(), "%s/wall_conduit.png" % PROP_DIR)
	_save(_ceiling_light(), "%s/ceiling_light.png" % PROP_DIR)
	_save(_note(), "%s/maintenance_note.png" % PROP_DIR)
	_save(_floor_cable(), "%s/floor_cable.png" % PROP_DIR)
	_save(_dust(1), "%s/dust_patch_01.png" % PROP_DIR)
	_save(_dust(2), "%s/dust_patch_02.png" % PROP_DIR)
	_save(_log_marker(), "%s/old_log_marker.png" % PROP_DIR)

func _console(w: int, h: int, screen: Color, _name: String) -> Image:
	var image := _img(w, h, Color(0, 0, 0, 0))
	_rect(image, Rect2i(0, 14, w, h - 14), Color("#303a40"))
	_rect(image, Rect2i(8, 22, w - 16, h - 30), Color("#121a20"))
	_rect(image, Rect2i(18, 28, w - 36, 16), screen)
	_rect(image, Rect2i(20, h - 13, w - 40, 4), Color("#bda24c"))
	_border(image, Color("#53636c"))
	return image

func _panel(w: int, h: int, damaged: bool) -> Image:
	var image := _img(w, h, Color(0, 0, 0, 0))
	_rect(image, Rect2i(0, 0, w, h), Color("#2b3338"))
	_rect(image, Rect2i(8, 10, w - 16, h - 20), Color("#101820"))
	var warn := Color("#b75b47") if damaged else Color("#405c4b")
	_border(image, warn)
	for i in range(4):
		_line_v(image, 18 + i * 10, 28, h - 28, Color("#8d4748"))
	_rect(image, Rect2i(w - 14, 10, 6, 6), Color("#d66a4f"))
	return image

func _locker() -> Image:
	var image := _img(64, 112, Color(0, 0, 0, 0))
	_rect(image, Rect2i(0, 0, 64, 112), Color("#303941"))
	_rect(image, Rect2i(8, 12, 20, 88), Color("#182229"))
	_rect(image, Rect2i(36, 12, 20, 88), Color("#182229"))
	_border(image, Color("#65737c"))
	return image

func _door() -> Image:
	var image := _img(72, 128, Color(0, 0, 0, 0))
	_rect(image, Rect2i(0, 0, 72, 128), Color("#2b3740"))
	_rect(image, Rect2i(8, 10, 56, 108), Color("#121b23"))
	_line_v(image, 36, 20, 108, Color("#8fa3b2"))
	_rect(image, Rect2i(4, 0, 64, 8), Color("#5f6f78"))
	_border(image, Color("#899aa4"))
	return image

func _conduit() -> Image:
	var image := _img(128, 24, Color(0, 0, 0, 0))
	_rect(image, Rect2i(0, 8, 128, 8), Color("#4f5c63"))
	_rect(image, Rect2i(18, 4, 10, 16), Color("#2b343a"))
	_rect(image, Rect2i(78, 4, 10, 16), Color("#2b343a"))
	return image

func _ceiling_light() -> Image:
	var image := _img(96, 16, Color(0, 0, 0, 0))
	_rect(image, Rect2i(0, 0, 96, 16), Color("#2d353a"))
	_rect(image, Rect2i(8, 5, 80, 5), Color("#d5b869"))
	return image

func _note() -> Image:
	var image := _img(80, 32, Color(0, 0, 0, 0))
	_rect(image, Rect2i(0, 0, 80, 32), Color("#343338"))
	_rect(image, Rect2i(6, 6, 68, 20), Color("#9b8e62"))
	_line_h(image, 14, 14, 62, Color("#493f2d"))
	return image

func _floor_cable() -> Image:
	var image := _img(128, 32, Color(0, 0, 0, 0))
	for i in range(128):
		var y := 12 + int(sin(float(i) * 0.12) * 5.0)
		_rect(image, Rect2i(i, y, 1, 4), Color("#0e1316"))
		_rect(image, Rect2i(i, y + 4, 1, 2), Color("#8a604d"))
	return image

func _dust(seed: int) -> Image:
	var image := _img(96, 48, Color(0, 0, 0, 0))
	for i in range(18):
		var x := (i * 23 + seed * 11) % 88 + 4
		var y := (i * 13 + seed * 7) % 38 + 5
		_rect(image, Rect2i(x, y, 5, 2), Color("#746b5f", 0.42))
	return image

func _log_marker() -> Image:
	var image := _img(64, 40, Color(0, 0, 0, 0))
	_rect(image, Rect2i(0, 0, 64, 40), Color("#202830"))
	_border(image, Color("#3f85a7"))
	_rect(image, Rect2i(10, 18, 44, 4), Color("#8fa3b2"))
	return image

func _player() -> void:
	for name in ["down", "up", "left", "right"]:
		_save(_astronaut(name, 0), "%s/astronaut_idle_%s.png" % [PLAYER_DIR, name])
	for name in ["down", "up", "left", "right"]:
		_save(_astronaut(name, 1), "%s/astronaut_walk_%s_01.png" % [PLAYER_DIR, name])
		_save(_astronaut(name, 2), "%s/astronaut_walk_%s_02.png" % [PLAYER_DIR, name])

func _astronaut(facing: String, frame: int) -> Image:
	var image := _img(48, 64, Color(0, 0, 0, 0))
	var suit := Color("#d8e0e6")
	var shadow := Color("#9fb2c0")
	_rect(image, Rect2i(17, 24, 14, 24), suit)
	_rect(image, Rect2i(20, 30, 8, 9), Color("#7fa7bd"))
	_rect(image, Rect2i(13, 8, 22, 22), suit)
	_rect(image, Rect2i(17, 13, 14, 10), Color("#152434"))
	if facing == "up":
		_rect(image, Rect2i(18, 10, 12, 16), Color("#b9c5ca"))
	elif facing == "left":
		_rect(image, Rect2i(13, 15, 8, 8), Color("#152434"))
	elif facing == "right":
		_rect(image, Rect2i(27, 15, 8, 8), Color("#152434"))
	_rect(image, Rect2i(14, 27, 4, 18), shadow)
	_rect(image, Rect2i(30, 27, 4, 18), shadow)
	var step := -2 if frame == 1 else 2 if frame == 2 else 0
	_rect(image, Rect2i(18, 47, 5, 12 + step), suit)
	_rect(image, Rect2i(26, 47, 5, 12 - step), suit)
	_rect(image, Rect2i(15, 58 + step, 9, 4), Color("#e8edf0"))
	_rect(image, Rect2i(25, 58 - step, 9, 4), Color("#e8edf0"))
	_rect(image, Rect2i(32, 27, 6, 16), Color("#6f8493"))
	return image

func _lighting() -> void:
	var pool := _img(160, 120, Color(0, 0, 0, 0))
	for y in range(pool.get_height()):
		for x in range(pool.get_width()):
			var d: float = Vector2(x - 80, y - 20).length() / 95.0
			var a: float = clamp(0.22 * (1.0 - d), 0.0, 0.22)
			pool.set_pixel(x, y, Color("#f0c766", a))
	_save(pool, "%s/warm_light_pool.png" % LIGHT_DIR)
	var green := _img(96, 96, Color(0, 0, 0, 0))
	for y in range(96):
		for x in range(96):
			var d: float = Vector2(x - 48, y - 48).length() / 48.0
			var a: float = clamp(0.18 * (1.0 - d), 0.0, 0.18)
			green.set_pixel(x, y, Color("#75b978", a))
	_save(green, "%s/greenhouse_signal_glow.png" % LIGHT_DIR)

func _contact_sheet() -> void:
	var sheet := _img(640, 360, Color("#071019"))
	var files := [
		"%s/metal_floor_base.png" % TILE_DIR, "%s/metal_floor_worn.png" % TILE_DIR,
		"%s/dark_metal_wall.png" % TILE_DIR, "%s/reinforced_wall_frame.png" % TILE_DIR,
		"%s/central_console.png" % PROP_DIR, "%s/old_power_panel.png" % PROP_DIR,
		"%s/life_support_console.png" % PROP_DIR, "%s/storage_cabinet.png" % PROP_DIR,
		"%s/greenhouse_door.png" % PROP_DIR, "%s/maintenance_note.png" % PROP_DIR,
		"%s/old_log_marker.png" % PROP_DIR, "%s/astronaut_idle_down.png" % PLAYER_DIR,
		"%s/astronaut_idle_up.png" % PLAYER_DIR, "%s/astronaut_idle_left.png" % PLAYER_DIR,
		"%s/astronaut_idle_right.png" % PLAYER_DIR,
	]
	var x := 24
	var y := 24
	for path in files:
		var item := Image.load_from_file(ProjectSettings.globalize_path(path))
		if item != null:
			sheet.blit_rect(item, Rect2i(Vector2i.ZERO, item.get_size()), Vector2i(x, y))
		x += 120
		if x > 560:
			x = 24
			y += 100
	_save(sheet, OUT_CONTACT)
