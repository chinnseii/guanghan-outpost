extends Node2D

const TILE := 56
const BED_TEXTURE_PATH := "res://assets/sprites/facilities/bed.png"
const STORAGE_TEXTURE_PATH := "res://assets/sprites/facilities/storage.png"
const CONSOLE_TEXTURE_PATH := "res://assets/sprites/facilities/console.png"
const ROBOT_CHARGER_TEXTURE_PATH := "res://assets/sprites/facilities/robot_charger.png"

var module_data: Dictionary = {}
var module_def: Dictionary = {}
var highlighted := false
var anim_time := 0.0
var bed_texture: Texture2D
var storage_texture: Texture2D
var console_texture: Texture2D
var robot_charger_texture: Texture2D

func _ready() -> void:
	_load_facility_textures()
	set_process(true)

func _load_facility_textures() -> void:
	bed_texture = _load_png_texture(BED_TEXTURE_PATH)
	storage_texture = _load_png_texture(STORAGE_TEXTURE_PATH)
	console_texture = _load_png_texture(CONSOLE_TEXTURE_PATH)
	robot_charger_texture = _load_png_texture(ROBOT_CHARGER_TEXTURE_PATH)

func _load_png_texture(path: String) -> Texture2D:
	var imported: Resource = ResourceLoader.load(path)
	if imported is Texture2D:
		return imported as Texture2D
	var image: Image = Image.load_from_file(path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()

func setup(data: Dictionary, definition: Dictionary, is_highlighted: bool) -> void:
	module_data = data
	module_def = definition
	highlighted = is_highlighted
	queue_redraw()

func _draw() -> void:
	if module_data.is_empty() or module_def.is_empty():
		return
	var size: Vector2i = module_def["size"]
	var rect := Rect2(Vector2.ZERO, Vector2(size.x * TILE - 2, size.y * TILE - 2))
	var fill: Color = module_def["color"]
	if highlighted:
		draw_rect(rect.grow(5), Color("#e7c66b"), false, 3)
	if module_data.get("leaking", false):
		draw_rect(rect.grow(7), Color("#ff5a5a"), false, 4)
	_draw_hull(rect, fill)
	_draw_details(String(module_data["type"]), rect)

func _draw_hull(rect: Rect2, fill: Color) -> void:
	var module_type := String(module_data["type"])
	if module_type in ["solar", "supply", "regolith_plant", "ice_processor"]:
		draw_rect(rect, fill)
		draw_rect(rect, Color("#a7b3c5"), false, 2)
		return
	var inner := rect.grow(-12.0)
	draw_rect(rect, Color("#202833"))
	_draw_pixel_floor(inner, fill.lightened(0.15))
	draw_line(Vector2(rect.position.x + 22, rect.position.y), Vector2(rect.end.x - 22, rect.position.y), Color("#a7b3c5"), 3)
	draw_line(Vector2(rect.position.x + 22, rect.end.y), Vector2(rect.end.x - 22, rect.end.y), Color("#a7b3c5"), 3)
	draw_line(Vector2(rect.position.x, rect.position.y + 22), Vector2(rect.position.x, rect.end.y - 22), Color("#a7b3c5"), 3)
	draw_line(Vector2(rect.end.x, rect.position.y + 22), Vector2(rect.end.x, rect.end.y - 22), Color("#a7b3c5"), 3)
	draw_rect(inner, Color("#d7dee8"), false, 2)
	_draw_door_markers(rect)

func _draw_pixel_floor(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)
	for x in range(0, int(rect.size.x), 16):
		draw_line(rect.position + Vector2(x, 0), rect.position + Vector2(x, rect.size.y), Color(0, 0, 0, 0.08), 1)
	for y in range(0, int(rect.size.y), 16):
		draw_line(rect.position + Vector2(0, y), rect.position + Vector2(rect.size.x, y), Color(1, 1, 1, 0.06), 1)

func _draw_door_markers(rect: Rect2) -> void:
	var center := rect.get_center()
	var door := Color("#e7c66b")
	var doors: Array = module_data.get("doors", [])
	if doors.has("top"):
		draw_line(Vector2(center.x - 18, rect.position.y + 2), Vector2(center.x + 18, rect.position.y + 2), door, 4)
	if doors.has("bottom"):
		draw_line(Vector2(center.x - 18, rect.end.y - 2), Vector2(center.x + 18, rect.end.y - 2), door, 4)
	if doors.has("left"):
		draw_line(Vector2(rect.position.x + 2, center.y - 18), Vector2(rect.position.x + 2, center.y + 18), door, 4)
	if doors.has("right"):
		draw_line(Vector2(rect.end.x - 2, center.y - 18), Vector2(rect.end.x - 2, center.y + 18), door, 4)

func _draw_details(module_type: String, rect: Rect2) -> void:
	if module_type == "greenhouse":
		_draw_greenhouse(rect)
	elif module_type == "solar":
		_draw_solar(rect)
	elif module_type == "battery":
		_draw_battery_bank(rect)
	elif module_type == "hab":
		_draw_hab_interior(rect)
	elif module_type == "life_support":
		_draw_life_support_interior(rect)
	elif module_type == "workshop":
		_draw_workshop_interior(rect)
	elif module_type == "airlock":
		_draw_airlock_interior(rect)
	elif module_type == "regolith_plant":
		draw_circle(rect.get_center() + Vector2(-26, 0), 18, Color("#b3a18e"))
		draw_line(rect.get_center() + Vector2(-8, 0), rect.get_center() + Vector2(32, -18), Color("#d8e0eb"), 3)
		draw_circle(rect.get_center() + Vector2(36, -20), 8, Color("#98d5ff"))
	elif module_type == "ice_processor":
		draw_circle(rect.get_center() + Vector2(-20, 0), 18, Color("#9fd7ff"))
		draw_rect(Rect2(rect.get_center() + Vector2(8, -18), Vector2(34, 36)), Color("#b8f0ff"), false, 3)
	elif module_type == "supply":
		draw_circle(rect.get_center(), 32, Color("#a76f45"))
		draw_rect(Rect2(rect.position + Vector2(68, 35), Vector2(54, 74)), Color("#d0d6df"), false, 3)

func _draw_greenhouse(rect: Rect2) -> void:
	for i in range(2):
		var bed := Rect2(rect.position + Vector2(22 + i * 72, 28), Vector2(52, 48))
		draw_rect(bed, Color("#223026"))
		draw_rect(bed, Color("#74b77a"), false, 2)
		if String(module_data.get("crop", "")) != "":
			var growth: float = clamp(float(module_data.get("age", 0)) / 4.0, 0.2, 1.0)
			draw_circle(bed.get_center(), 7 + 13 * growth, Color("#71d46f"))

func _draw_hab_interior(rect: Rect2) -> void:
	var bed_a := Rect2(rect.position + Vector2(24, 24), Vector2(48, 22))
	var bed_b := Rect2(rect.position + Vector2(24, 58), Vector2(48, 22))
	var storage := Rect2(rect.position + Vector2(rect.size.x - 50, 24), Vector2(30, 44))
	var console := Rect2(rect.position + Vector2(rect.size.x - 58, rect.size.y - 46), Vector2(46, 28))
	_highlight_facility("bed", bed_a.merge(bed_b).grow(4))
	_highlight_facility("storage", storage.grow(5))
	_highlight_facility("console", console.grow(5))
	_draw_bed(bed_a.position)
	_draw_bed(bed_b.position)
	_draw_storage(storage.position)
	_draw_console(console.position, true)
	draw_circle(rect.get_center(), 12, Color("#717d8f"))
	draw_circle(rect.get_center(), 6, Color("#9fb0c5"))

func _draw_life_support_interior(rect: Rect2) -> void:
	_draw_tank(rect.get_center() + Vector2(-34, -4), Color("#98d5ff"))
	_draw_tank(rect.get_center() + Vector2(0, -4), Color("#b8f0d0"))
	_draw_tank(rect.get_center() + Vector2(34, -4), Color("#d8e0eb"))
	var console := Rect2(rect.position + Vector2(22, rect.size.y - 44), Vector2(46, 28))
	_highlight_facility("console", console.grow(5))
	_draw_console(console.position, true)
	draw_line(rect.get_center() + Vector2(-48, 22), rect.get_center() + Vector2(48, 22), Color("#6f7d8f"), 4)

func _draw_workshop_interior(rect: Rect2) -> void:
	var bench := Rect2(rect.position + Vector2(22, 26), Vector2(58, 34))
	var charger := Rect2(rect.position + Vector2(rect.size.x - 58, 24), Vector2(38, 48))
	var storage := Rect2(rect.position + Vector2(24, rect.size.y - 48), Vector2(30, 44))
	_highlight_facility("robot_charger", charger.grow(5))
	_highlight_facility("storage", storage.grow(5))
	draw_rect(bench, Color("#c0a36c"))
	draw_rect(Rect2(rect.position + Vector2(28, 32), Vector2(46, 10)), Color("#6d5b3b"))
	_draw_robot_charger(charger.position)
	_draw_storage(storage.position)

func _draw_airlock_interior(rect: Rect2) -> void:
	var chamber := Rect2(rect.position + Vector2(22, 18), Vector2(52, 58))
	draw_rect(chamber, Color("#8892a3"), false, 4)
	draw_line(rect.position + Vector2(48, 20), rect.position + Vector2(48, 74), Color("#d8e0eb"), 2)
	draw_line(rect.position + Vector2(62, 22), rect.position + Vector2(62, 72), Color("#7fd5ff", 0.8), 2)
	_draw_suit_rack(rect.position + Vector2(rect.size.x - 40, 24))

func _draw_battery_bank(rect: Rect2) -> void:
	for i in range(3):
		var battery := Rect2(rect.position + Vector2(18 + i * 30, 26), Vector2(20, 44))
		draw_rect(battery, Color("#2f4059"))
		draw_rect(battery.grow(-3), Color("#a8c7ff"))
		_draw_status_light(battery.position + Vector2(10, -6), i % 2 == 0)

func _draw_bed(pos: Vector2) -> void:
	var rect := Rect2(pos, Vector2(48, 22))
	if bed_texture != null:
		draw_texture_rect(bed_texture, rect, false)
		return
	draw_rect(rect, Color("#38475e"))
	draw_rect(Rect2(pos + Vector2(4, 4), Vector2(14, 14)), Color("#d8e0eb"))
	draw_rect(Rect2(pos + Vector2(20, 4), Vector2(24, 14)), Color("#6fa0d8"))

func _highlight_facility(name: String, rect: Rect2) -> void:
	if String(module_data.get("active_facility", "")) != name:
		return
	var pulse: float = 0.45 + 0.55 * abs(sin(anim_time * 5.0))
	draw_rect(rect.grow(4), Color(1.0, 0.82, 0.34, pulse), false, 3)

func _draw_storage(pos: Vector2) -> void:
	var rect := Rect2(pos, Vector2(30, 44))
	if storage_texture != null:
		draw_texture_rect(storage_texture, rect, false)
		return
	draw_rect(rect, Color("#3f4b5f"))
	draw_rect(Rect2(pos + Vector2(4, 5), Vector2(22, 12)), Color("#6d7c91"))
	draw_rect(Rect2(pos + Vector2(4, 25), Vector2(22, 12)), Color("#6d7c91"))
	draw_circle(pos + Vector2(24, 22), 2, Color("#e7c66b"))

func _draw_console(pos: Vector2, animated: bool) -> void:
	var rect := Rect2(pos, Vector2(46, 28))
	if console_texture != null:
		draw_texture_rect(console_texture, rect, false)
	else:
		draw_rect(rect, Color("#263242"))
		draw_rect(Rect2(pos + Vector2(5, 5), Vector2(22, 10)), Color("#79b8ff"))
	_draw_status_light(pos + Vector2(35, 9), animated)
	_draw_status_light(pos + Vector2(35, 20), not animated)

func _draw_tank(center: Vector2, color: Color) -> void:
	draw_circle(center, 16, Color("#263242"))
	draw_circle(center, 12, color)
	draw_rect(Rect2(center + Vector2(-8, 13), Vector2(16, 8)), Color("#6f7d8f"))

func _draw_robot_charger(pos: Vector2) -> void:
	var rect := Rect2(pos, Vector2(38, 48))
	if robot_charger_texture != null:
		draw_texture_rect(robot_charger_texture, rect, false)
	else:
		draw_rect(rect, Color("#263242"))
		draw_rect(Rect2(pos + Vector2(7, 8), Vector2(24, 24)), Color("#4d5f75"))
		draw_line(pos + Vector2(12, 40), pos + Vector2(30, 40), Color("#e7c66b"), 3)
	_draw_status_light(pos + Vector2(30, 8), true)

func _draw_suit_rack(pos: Vector2) -> void:
	draw_line(pos + Vector2(10, 0), pos + Vector2(10, 44), Color("#d8e0eb"), 2)
	draw_circle(pos + Vector2(10, 12), 8, Color("#f2f0da"))
	draw_rect(Rect2(pos + Vector2(2, 20), Vector2(16, 18)), Color("#f2f0da"))
	draw_circle(pos + Vector2(10, 12), 4, Color("#7fb8ff"))

func _draw_status_light(pos: Vector2, animated: bool) -> void:
	var blink: float = 0.35 + 0.65 * abs(sin(anim_time * 4.0))
	var color := Color("#7dff9d") if not animated else Color(0.4, 1.0, 0.6, blink)
	draw_circle(pos, 4, color)

func _draw_solar(rect: Rect2) -> void:
	for i in range(4):
		var panel := Rect2(rect.position + Vector2(14 + i * 40, 18), Vector2(30, 58))
		draw_rect(panel, Color("#365f95"))
		draw_rect(panel, Color("#94bdeb"), false, 1)
