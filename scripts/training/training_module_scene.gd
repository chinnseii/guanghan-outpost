extends Control

const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")

class TrainingRoomBlockout:
	extends Control

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color("#07111b"), true)
		var room := Rect2(Vector2(24, 24), size - Vector2(48, 48))
		draw_rect(room, Color("#18232e"), true)
		for x in range(int(room.position.x), int(room.end.x), 48):
			draw_line(Vector2(x, room.position.y), Vector2(x, room.end.y), Color("#2f3f4c", 0.55), 1.0)
		for y in range(int(room.position.y), int(room.end.y), 48):
			draw_line(Vector2(room.position.x, y), Vector2(room.end.x, y), Color("#2f3f4c", 0.55), 1.0)
		draw_rect(room, Color("#5d6f7d"), false, 4.0)
		draw_rect(Rect2(room.position + Vector2(10, 10), room.size - Vector2(20, 20)), Color("#2a3844"), false, 2.0)
		draw_rect(Rect2(Vector2(room.position.x, room.position.y), Vector2(room.size.x, 26)), Color("#25313c"), true)
		draw_rect(Rect2(Vector2(room.position.x, room.end.y - 26), Vector2(room.size.x, 26)), Color("#25313c"), true)
		draw_rect(Rect2(Vector2(room.position.x, room.position.y), Vector2(26, room.size.y)), Color("#25313c"), true)
		draw_rect(Rect2(Vector2(room.end.x - 26, room.position.y), Vector2(26, room.size.y)), Color("#25313c"), true)
		for light_x in [150, size.x * 0.5, size.x - 210]:
			var light_rect := Rect2(Vector2(light_x, room.position.y + 14), Vector2(96, 8))
			draw_rect(light_rect, Color("#87d9ff", 0.45), true)
			draw_rect(light_rect.grow(4), Color("#87d9ff", 0.12), true)
		var panel_color := Color("#344653")
		draw_rect(Rect2(Vector2(room.position.x + 64, room.end.y - 72), Vector2(96, 34)), panel_color, true)
		draw_rect(Rect2(Vector2(room.end.x - 180, room.position.y + 72), Vector2(94, 42)), panel_color, true)
		draw_rect(Rect2(Vector2(room.end.x - 182, room.position.y + 74), Vector2(90, 6)), Color("#67b7e8", 0.55), true)

class AirlockRoomBlockout:
	extends Control

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color("#07111b"), true)
		var room := Rect2(Vector2(24, 24), size - Vector2(48, 48))
		draw_rect(room, Color("#17212b"), true)
		for x in range(int(room.position.x), int(room.end.x), 48):
			draw_line(Vector2(x, room.position.y), Vector2(x, room.end.y), Color("#2f3f4c", 0.52), 1.0)
		for y in range(int(room.position.y), int(room.end.y), 48):
			draw_line(Vector2(room.position.x, y), Vector2(room.end.x, y), Color("#2f3f4c", 0.52), 1.0)
		var interior := Rect2(Vector2(44, 68), Vector2(220, size.y - 136))
		var chamber := Rect2(Vector2(286, 86), Vector2(204, size.y - 172))
		var exterior := Rect2(Vector2(512, 68), Vector2(size.x - 572, size.y - 136))
		draw_rect(interior, Color("#1c2833"), true)
		draw_rect(chamber, Color("#243541"), true)
		draw_rect(exterior, Color("#121b24"), true)
		draw_rect(interior, Color("#5d6f7d"), false, 3.0)
		draw_rect(chamber, Color("#9aa8b4"), false, 4.0)
		draw_rect(chamber.grow(-12), Color("#587083", 0.3), false, 2.0)
		draw_rect(exterior, Color("#5b7180"), false, 3.0)
		draw_rect(Rect2(Vector2(268, room.position.y + 42), Vector2(14, room.size.y - 84)), Color("#405261"), true)
		draw_rect(Rect2(Vector2(494, room.position.y + 42), Vector2(14, room.size.y - 84)), Color("#405261"), true)
		draw_rect(Rect2(Vector2(272, 210), Vector2(10, 138)), Color("#89d8ff", 0.2), true)
		draw_rect(Rect2(Vector2(494, 210), Vector2(10, 138)), Color("#89d8ff", 0.2), true)
		for mark in [Vector2(548, 260), Vector2(620, 340), Vector2(700, 210)]:
			draw_arc(mark, 14.0, 0.2, 4.8, 18, Color("#6f8493", 0.35), 1.0)
			draw_line(mark + Vector2(-18, 16), mark + Vector2(22, 9), Color("#6f8493", 0.28), 1.0)
		draw_rect(Rect2(Vector2(574, 420), Vector2(34, 8)), Color("#6f8493", 0.24), true)
		draw_rect(Rect2(Vector2(664, 148), Vector2(22, 6)), Color("#6f8493", 0.22), true)
		for light_x in [100, 340, 590]:
			var light_rect := Rect2(Vector2(light_x, room.position.y + 16), Vector2(86, 8))
			draw_rect(light_rect, Color("#87d9ff", 0.38), true)
			draw_rect(light_rect.grow(4), Color("#87d9ff", 0.1), true)
		draw_string(ThemeDB.fallback_font, interior.position + Vector2(16, 24), "训练室内部", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#8fa3b2"))
		draw_string(ThemeDB.fallback_font, chamber.position + Vector2(16, 24), "气闸舱", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#8fa3b2"))
		draw_string(ThemeDB.fallback_font, exterior.position + Vector2(16, 24), "外部模拟区", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#8fa3b2"))

class PowerRepairRoomBlockout:
	extends Control

	var power_on := false

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color("#07111b"), true)
		var room := Rect2(Vector2(24, 24), size - Vector2(48, 48))
		draw_rect(room, Color("#17222c"), true)
		for x in range(int(room.position.x), int(room.end.x), 48):
			draw_line(Vector2(x, room.position.y), Vector2(x, room.end.y), Color("#31414d", 0.55), 1.0)
		for y in range(int(room.position.y), int(room.end.y), 48):
			draw_line(Vector2(room.position.x, y), Vector2(room.end.x, y), Color("#31414d", 0.55), 1.0)
		draw_rect(room, Color("#5d6f7d"), false, 4.0)
		draw_rect(room.grow(-10), Color("#2a3844"), false, 2.0)
		draw_rect(Rect2(room.position, Vector2(room.size.x, 28)), Color("#25313c"), true)
		draw_rect(Rect2(Vector2(room.position.x, room.end.y - 28), Vector2(room.size.x, 28)), Color("#25313c"), true)
		draw_rect(Rect2(room.position, Vector2(28, room.size.y)), Color("#25313c"), true)
		draw_rect(Rect2(Vector2(room.end.x - 28, room.position.y), Vector2(28, room.size.y)), Color("#25313c"), true)
		var light_color := Color("#f0c766", 0.58) if power_on else Color("#4f6473", 0.22)
		for light_x in [138, size.x * 0.5 - 42, size.x - 242]:
			var light_rect := Rect2(Vector2(light_x, room.position.y + 16), Vector2(96, 8))
			draw_rect(light_rect, light_color, true)
			draw_rect(light_rect.grow(5), Color(light_color.r, light_color.g, light_color.b, 0.18 if power_on else 0.12), true)
		if power_on:
			draw_rect(room.grow(-42), Color("#f0c766", 0.055), true)
		draw_rect(Rect2(Vector2(room.position.x + 72, room.end.y - 78), Vector2(132, 36)), Color("#344653"), true)
		draw_rect(Rect2(Vector2(room.position.x + 82, room.end.y - 70), Vector2(34, 8)), Color("#8fa3b2", 0.55), true)
		draw_rect(Rect2(Vector2(room.end.x - 210, room.position.y + 78), Vector2(126, 44)), Color("#344653"), true)
		draw_rect(Rect2(Vector2(room.end.x - 198, room.position.y + 88), Vector2(42, 6)), Color("#67b7e8", 0.45), true)
		draw_line(Vector2(room.position.x + 250, room.position.y + 120), Vector2(room.end.x - 235, room.position.y + 120), Color("#4f6473", 0.5), 3.0)
		draw_line(Vector2(room.position.x + 250, room.position.y + 132), Vector2(room.end.x - 235, room.position.y + 132), Color("#4f6473", 0.25), 2.0)

class LifeSupportRoomBlockout:
	extends Control

	var stable := false
	var stabilizing := false

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color("#07111b"), true)
		var room := Rect2(Vector2(24, 24), size - Vector2(48, 48))
		draw_rect(room, Color("#17222c"), true)
		for x in range(int(room.position.x), int(room.end.x), 48):
			draw_line(Vector2(x, room.position.y), Vector2(x, room.end.y), Color("#31414d", 0.54), 1.0)
		for y in range(int(room.position.y), int(room.end.y), 48):
			draw_line(Vector2(room.position.x, y), Vector2(room.end.x, y), Color("#31414d", 0.54), 1.0)
		draw_rect(room, Color("#5d6f7d"), false, 4.0)
		draw_rect(room.grow(-10), Color("#2a3844"), false, 2.0)
		draw_rect(Rect2(room.position, Vector2(room.size.x, 28)), Color("#25313c"), true)
		draw_rect(Rect2(Vector2(room.position.x, room.end.y - 28), Vector2(room.size.x, 28)), Color("#25313c"), true)
		draw_rect(Rect2(room.position, Vector2(28, room.size.y)), Color("#25313c"), true)
		draw_rect(Rect2(Vector2(room.end.x - 28, room.position.y), Vector2(28, room.size.y)), Color("#25313c"), true)
		var air_color := Color("#9fd7ff", 0.42) if stable else Color("#67b7e8", 0.24 if stabilizing else 0.16)
		for vent_x in [92, 278, 464, 650]:
			var vent := Rect2(Vector2(vent_x, room.position.y + 18), Vector2(92, 12))
			draw_rect(vent, Color("#344653"), true)
			for i in range(5):
				draw_line(vent.position + Vector2(10 + i * 15, 2), vent.position + Vector2(10 + i * 15, 10), air_color, 2.0)
			draw_rect(vent.grow(5), Color(air_color.r, air_color.g, air_color.b, 0.08 if stable else 0.04), true)
		if stable:
			draw_rect(room.grow(-44), Color("#9fd7ff", 0.035), true)
		draw_rect(Rect2(Vector2(room.position.x + 58, room.end.y - 78), Vector2(144, 34)), Color("#344653"), true)
		draw_rect(Rect2(Vector2(room.end.x - 216, room.position.y + 78), Vector2(132, 44)), Color("#344653"), true)
		draw_line(Vector2(room.position.x + 230, room.position.y + 124), Vector2(room.end.x - 220, room.position.y + 124), Color("#4f6473", 0.45), 3.0)
		draw_line(Vector2(room.position.x + 230, room.position.y + 138), Vector2(room.end.x - 220, room.position.y + 138), Color("#4f6473", 0.25), 2.0)

class PlantDiagnosisRoomBlockout:
	extends Control

	var plant_stable := false
	var grow_light_on := false

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color("#07111b"), true)
		var room := Rect2(Vector2(24, 24), size - Vector2(48, 48))
		draw_rect(room, Color("#17222c"), true)
		for x in range(int(room.position.x), int(room.end.x), 48):
			draw_line(Vector2(x, room.position.y), Vector2(x, room.end.y), Color("#31414d", 0.54), 1.0)
		for y in range(int(room.position.y), int(room.end.y), 48):
			draw_line(Vector2(room.position.x, y), Vector2(room.end.x, y), Color("#31414d", 0.54), 1.0)
		draw_rect(room, Color("#5d6f7d"), false, 4.0)
		draw_rect(room.grow(-10), Color("#2a3844"), false, 2.0)
		draw_rect(Rect2(room.position, Vector2(room.size.x, 28)), Color("#25313c"), true)
		draw_rect(Rect2(Vector2(room.position.x, room.end.y - 28), Vector2(room.size.x, 28)), Color("#25313c"), true)
		draw_rect(Rect2(room.position, Vector2(28, room.size.y)), Color("#25313c"), true)
		draw_rect(Rect2(Vector2(room.end.x - 28, room.position.y), Vector2(28, room.size.y)), Color("#25313c"), true)
		var light_color := Color("#f0c766", 0.48) if grow_light_on else Color("#4f6473", 0.18)
		var light_rect := Rect2(Vector2(size.x * 0.5 - 70, room.position.y + 16), Vector2(140, 10))
		draw_rect(light_rect, light_color, true)
		draw_rect(light_rect.grow(8), Color(light_color.r, light_color.g, light_color.b, 0.11 if grow_light_on else 0.04), true)
		if plant_stable:
			draw_rect(room.grow(-46), Color("#7dbd75", 0.035), true)
		draw_rect(Rect2(Vector2(room.position.x + 72, room.end.y - 80), Vector2(126, 36)), Color("#344653"), true)
		draw_rect(Rect2(Vector2(room.end.x - 210, room.position.y + 80), Vector2(128, 44)), Color("#344653"), true)
		draw_line(Vector2(room.position.x + 238, room.position.y + 122), Vector2(room.end.x - 238, room.position.y + 122), Color("#4f6473", 0.42), 3.0)
		draw_line(Vector2(room.position.x + 238, room.position.y + 138), Vector2(room.end.x - 238, room.position.y + 138), Color("#4f6473", 0.24), 2.0)

class FinalAssessmentRoomBlockout:
	extends Control

	var power_on := false
	var life_stable := false
	var plant_stable := false

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color("#07111b"), true)
		var room := Rect2(Vector2(24, 24), size - Vector2(48, 48))
		draw_rect(room, Color("#17222c"), true)
		for x in range(int(room.position.x), int(room.end.x), 48):
			draw_line(Vector2(x, room.position.y), Vector2(x, room.end.y), Color("#31414d", 0.52), 1.0)
		for y in range(int(room.position.y), int(room.end.y), 48):
			draw_line(Vector2(room.position.x, y), Vector2(room.end.x, y), Color("#31414d", 0.52), 1.0)
		draw_rect(room, Color("#5d6f7d"), false, 4.0)
		draw_rect(room.grow(-10), Color("#2a3844"), false, 2.0)
		draw_rect(Rect2(room.position, Vector2(room.size.x, 28)), Color("#25313c"), true)
		draw_rect(Rect2(Vector2(room.position.x, room.end.y - 28), Vector2(room.size.x, 28)), Color("#25313c"), true)
		draw_rect(Rect2(room.position, Vector2(28, room.size.y)), Color("#25313c"), true)
		draw_rect(Rect2(Vector2(room.end.x - 28, room.position.y), Vector2(28, room.size.y)), Color("#25313c"), true)
		var light_color := Color("#f0c766", 0.5) if power_on else Color("#4f6473", 0.18)
		for light_x in [116, 334, 552]:
			var light_rect := Rect2(Vector2(light_x, room.position.y + 16), Vector2(106, 8))
			draw_rect(light_rect, light_color, true)
			draw_rect(light_rect.grow(5), Color(light_color.r, light_color.g, light_color.b, 0.14 if power_on else 0.05), true)
		if life_stable:
			draw_rect(Rect2(Vector2(250, 94), Vector2(244, 236)), Color("#9fd7ff", 0.035), true)
		if plant_stable:
			draw_rect(Rect2(Vector2(532, 92), Vector2(206, 262)), Color("#7dbd75", 0.035), true)
		draw_rect(Rect2(Vector2(42, 72), Vector2(190, 250)), Color("#1c2833"), true)
		draw_rect(Rect2(Vector2(250, 72), Vector2(246, 286)), Color("#1a2b38"), true)
		draw_rect(Rect2(Vector2(520, 72), Vector2(222, 306)), Color("#18262e"), true)
		draw_rect(Rect2(Vector2(288, 386), Vector2(236, 86)), Color("#1d2832"), true)
		draw_rect(Rect2(Vector2(42, 72), Vector2(190, 250)), Color("#5d6f7d", 0.45), false, 2.0)
		draw_rect(Rect2(Vector2(250, 72), Vector2(246, 286)), Color("#5d6f7d", 0.45), false, 2.0)
		draw_rect(Rect2(Vector2(520, 72), Vector2(222, 306)), Color("#5d6f7d", 0.45), false, 2.0)
		draw_rect(Rect2(Vector2(288, 386), Vector2(236, 86)), Color("#5d6f7d", 0.45), false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(58, 96), "供电区", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#8fa3b2"))
		draw_string(ThemeDB.fallback_font, Vector2(266, 96), "生命支持区", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#8fa3b2"))
		draw_string(ThemeDB.fallback_font, Vector2(536, 96), "植物舱区", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#8fa3b2"))
		draw_string(ThemeDB.fallback_font, Vector2(306, 410), "考核终端区", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#8fa3b2"))

class TrainingTargetVisual:
	extends Control

	var kind := "marker"
	var label_text := ""
	var active := false
	var highlighted := false
	var locked := false
	var show_trigger_debug := false
	var status_text := ""

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		match kind:
			"marker":
				_draw_marker()
			"zone":
				_draw_zone()
			"terminal":
				_draw_terminal()
			"pressure_console":
				_draw_terminal()
			"door":
				_draw_door()
			"status_display":
				_draw_status_display()
			"tool_station":
				_draw_tool_station()
			"power_panel":
				_draw_power_panel()
			"power_console":
				_draw_power_console()
			"test_light":
				_draw_test_light()
			"life_console":
				_draw_life_console()
			"life_status":
				_draw_life_status_display()
			"life_core":
				_draw_life_core()
			"ventilation":
				_draw_ventilation_unit()
			"plant_chamber":
				_draw_plant_chamber()
			"plant_scanner":
				_draw_plant_scanner()
			"plant_console":
				_draw_plant_console()
			"grow_light":
				_draw_grow_light()
			"plant_status":
				_draw_plant_status_display()
			"assessment_terminal":
				_draw_assessment_terminal()
			"exit":
				_draw_exit()
			_:
				_draw_generic()
		_draw_debug_label()

	func _draw_marker() -> void:
		var c := Color("#f0c766") if highlighted else Color("#4fb7f0")
		var fill_alpha := 0.28 if highlighted else 0.12
		draw_rect(Rect2(Vector2.ZERO, size), Color("#12324a", fill_alpha), true)
		if show_trigger_debug:
			draw_rect(Rect2(Vector2.ZERO, size), Color("#f0c766", 0.08), true)
			draw_rect(Rect2(Vector2.ZERO, size), Color("#f0c766", 0.9), false, 1.0)
		for x in range(0, int(size.x), 14):
			draw_line(Vector2(x, 0), Vector2(min(x + 7, size.x), 0), c, 2.0)
			draw_line(Vector2(x, size.y), Vector2(min(x + 7, size.x), size.y), c, 2.0)
		for y in range(0, int(size.y), 14):
			draw_line(Vector2(0, y), Vector2(0, min(y + 7, size.y)), c, 2.0)
			draw_line(Vector2(size.x, y), Vector2(size.x, min(y + 7, size.y)), c, 2.0)
		draw_arc(size * 0.5, 22.0, 0.0, TAU, 32, Color("#8fd8ff", 0.8), 2.0)
		draw_line(size * 0.5 + Vector2(-16, 0), size * 0.5 + Vector2(16, 0), Color("#8fd8ff", 0.7), 1.0)
		draw_line(size * 0.5 + Vector2(0, -16), size * 0.5 + Vector2(0, 16), Color("#8fd8ff", 0.7), 1.0)

	func _draw_terminal() -> void:
		if highlighted:
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.12), true)
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.55), false, 2.0)
		draw_rect(Rect2(Vector2(12, 30), Vector2(size.x - 24, size.y - 38)), Color("#2c3740"), true)
		draw_rect(Rect2(Vector2(22, 8), Vector2(size.x - 44, 36)), Color("#1a2b38"), true)
		draw_rect(Rect2(Vector2(28, 14), Vector2(size.x - 56, 22)), Color("#236fa8"), true)
		draw_rect(Rect2(Vector2(34, 19), Vector2(size.x - 68, 3)), Color("#89d8ff", 0.8), true)
		draw_rect(Rect2(Vector2(34, 27), Vector2(size.x - 82, 3)), Color("#89d8ff", 0.55), true)
		draw_rect(Rect2(Vector2(30, 54), Vector2(18, 10)), Color("#f0c766"), true)
		draw_rect(Rect2(Vector2(56, 54), Vector2(18, 10)), Color("#6fa7c8"), true)
		draw_rect(Rect2(Vector2(82, 54), Vector2(18, 10)), Color("#8fa3b2"), true)

	func _draw_zone() -> void:
		var c := Color("#f0c766") if highlighted else Color("#4fb7f0")
		draw_rect(Rect2(Vector2.ZERO, size), Color("#12324a", 0.2 if highlighted else 0.09), true)
		draw_rect(Rect2(Vector2.ZERO, size), c, false, 2.0)
		for x in range(12, int(size.x), 28):
			draw_line(Vector2(x, 8), Vector2(x + 10, 8), c, 1.5)
			draw_line(Vector2(x, size.y - 8), Vector2(x + 10, size.y - 8), c, 1.5)

	func _draw_door() -> void:
		var edge := Color("#f0c766", 0.7) if highlighted and not locked else Color("#89d8ff", 0.3)
		draw_rect(Rect2(Vector2(0, 0), size), Color("#2c3740"), true)
		draw_rect(Rect2(Vector2(8, 8), size - Vector2(16, 16)), Color("#18232e"), true)
		draw_line(Vector2(size.x * 0.5, 10), Vector2(size.x * 0.5, size.y - 10), Color("#d8e7f2", 0.45), 2.0)
		draw_rect(Rect2(Vector2(0, 12), Vector2(6, size.y - 24)), edge, true)
		draw_rect(Rect2(Vector2(size.x - 6, 12), Vector2(6, size.y - 24)), edge, true)
		if locked:
			draw_string(ThemeDB.fallback_font, Vector2(12, size.y * 0.5), "锁定", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#8fa3b2"))

	func _draw_status_display() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#1a2b38"), true)
		draw_rect(Rect2(Vector2(6, 6), size - Vector2(12, 12)), Color("#0d1822"), true)
		draw_rect(Rect2(Vector2(12, 14), Vector2(size.x - 24, 5)), Color("#89d8ff", 0.65), true)
		draw_rect(Rect2(Vector2(12, 30), Vector2(size.x - 42, 4)), Color("#d8e7f2", 0.45), true)
		draw_rect(Rect2(Vector2(12, 44), Vector2(size.x - 62, 4)), Color("#f0c766", 0.35), true)
		var text := status_text if not status_text.is_empty() else "舱压：未启动"
		draw_string(ThemeDB.fallback_font, Vector2(12, size.y - 12), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#d8e7f2"))

	func _draw_tool_station() -> void:
		if highlighted:
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.12), true)
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.55), false, 2.0)
		draw_rect(Rect2(Vector2(6, 34), Vector2(size.x - 12, size.y - 40)), Color("#303d47"), true)
		draw_rect(Rect2(Vector2(0, 24), Vector2(size.x, 16)), Color("#52616c"), true)
		draw_rect(Rect2(Vector2(18, 8), Vector2(26, 18)), Color("#7d8b94"), true)
		draw_rect(Rect2(Vector2(58, 10), Vector2(46, 8)), Color("#f0c766", 0.7), true)
		draw_line(Vector2(64, 18), Vector2(96, 30), Color("#d8e7f2", 0.65), 3.0)
		draw_rect(Rect2(Vector2(22, 54), Vector2(18, 18)), Color("#1a2b38"), true)
		draw_rect(Rect2(Vector2(52, 54), Vector2(18, 18)), Color("#1a2b38"), true)

	func _draw_power_panel() -> void:
		var warn := highlighted or status_text == "repairing"
		var restored := status_text == "repaired" or status_text == "restored"
		draw_rect(Rect2(Vector2.ZERO, size), Color("#2f343a"), true)
		draw_rect(Rect2(Vector2(8, 8), size - Vector2(16, 16)), Color("#161f27"), true)
		var edge := Color("#f0c766", 0.72) if warn else Color("#b45a56", 0.55)
		if restored:
			edge = Color("#d8e7f2", 0.65)
		draw_rect(Rect2(Vector2.ZERO, size), edge, false, 3.0)
		draw_rect(Rect2(Vector2(18, 14), Vector2(size.x - 36, 14)), Color("#0d1822"), true)
		draw_rect(Rect2(Vector2(24, 19), Vector2(size.x - 58, 3)), Color("#5d6f7d", 0.3 if restored else 0.12), true)
		if not restored:
			draw_circle(Vector2(size.x - 20, 21), 5.0, Color("#d66a4f", 0.85))
			draw_circle(Vector2(size.x - 20, 21), 10.0, Color("#d66a4f", 0.12))
		for i in range(4):
			var x := 18 + i * 28
			draw_rect(Rect2(Vector2(x, 20), Vector2(16, 42)), Color("#344653"), true)
			draw_line(Vector2(x + 4, 28), Vector2(x + 12, 52), Color("#b45a56", 0.72 if not restored else 0.12), 2.0)
			if not restored:
				draw_line(Vector2(x + 12, 30), Vector2(x + 5, 44), Color("#f0c766", 0.35), 1.4)
		draw_rect(Rect2(Vector2(18, size.y - 26), Vector2(size.x - 36, 6)), Color("#f0c766", 0.62 if warn and not restored else 0.12), true)

	func _draw_power_console() -> void:
		if highlighted:
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.12), true)
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.55), false, 2.0)
		draw_rect(Rect2(Vector2(10, 32), Vector2(size.x - 20, size.y - 38)), Color("#303b44"), true)
		draw_rect(Rect2(Vector2(22, 8), Vector2(size.x - 44, 38)), Color("#101d28"), true)
		var screen := Color("#f0c766", 0.78) if status_text == "restored" else Color("#236fa8")
		draw_rect(Rect2(Vector2(30, 16), Vector2(size.x - 60, 20)), screen, true)
		draw_rect(Rect2(Vector2(32, 58), Vector2(18, 10)), Color("#f0c766", 0.8), true)
		draw_rect(Rect2(Vector2(60, 58), Vector2(18, 10)), Color("#6fa7c8"), true)
		draw_rect(Rect2(Vector2(88, 58), Vector2(18, 10)), Color("#8fa3b2"), true)

	func _draw_test_light() -> void:
		var on := status_text == "on"
		if highlighted:
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.1), true)
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.45), false, 2.0)
		var center := size * 0.5
		draw_rect(Rect2(Vector2(8, size.y - 18), Vector2(size.x - 16, 12)), Color("#303b44"), true)
		draw_line(Vector2(center.x, 8), Vector2(center.x, size.y - 22), Color("#5d6f7d"), 4.0)
		var glow := Color("#f0c766", 0.85) if on else Color("#5d6f7d", 0.35)
		draw_circle(center + Vector2(0, -6), 18, Color(glow.r, glow.g, glow.b, 0.22 if on else 0.1))
		draw_circle(center + Vector2(0, -6), 10, glow)
		if on:
			draw_circle(center + Vector2(0, -6), 28, Color("#f0c766", 0.08))

	func _draw_life_console() -> void:
		if highlighted:
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.12), true)
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.55), false, 2.0)
		draw_rect(Rect2(Vector2(10, 32), Vector2(size.x - 20, size.y - 38)), Color("#303b44"), true)
		draw_rect(Rect2(Vector2(22, 8), Vector2(size.x - 44, 38)), Color("#101d28"), true)
		var screen := Color("#9fd7ff", 0.62)
		if status_text == "stabilizing":
			screen = Color("#f0c766", 0.58)
		elif status_text == "stable":
			screen = Color("#d8e7f2", 0.72)
		draw_rect(Rect2(Vector2(30, 16), Vector2(size.x - 60, 20)), screen, true)
		draw_rect(Rect2(Vector2(32, 58), Vector2(18, 10)), Color("#6fa7c8"), true)
		draw_rect(Rect2(Vector2(60, 58), Vector2(18, 10)), Color("#f0c766", 0.75), true)
		draw_rect(Rect2(Vector2(88, 58), Vector2(18, 10)), Color("#8fa3b2"), true)

	func _draw_life_status_display() -> void:
		var abnormal := status_text == "low"
		var stabilizing_state := status_text == "stabilizing"
		var stable_state := status_text == "stable"
		var border := Color("#d66a4f", 0.72) if abnormal else Color("#6fa7c8", 0.55)
		if stabilizing_state:
			border = Color("#f0c766", 0.7)
		elif stable_state:
			border = Color("#d8e7f2", 0.7)
		if highlighted:
			draw_rect(Rect2(Vector2(-6, -6), size + Vector2(12, 12)), Color("#f0c766", 0.1), true)
			draw_rect(Rect2(Vector2(-6, -6), size + Vector2(12, 12)), Color("#f0c766", 0.45), false, 2.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color("#1a2b38"), true)
		draw_rect(Rect2(Vector2(8, 8), size - Vector2(16, 16)), Color("#0d1822"), true)
		draw_rect(Rect2(Vector2.ZERO, size), border, false, 2.0)
		draw_rect(Rect2(Vector2(14, 18), Vector2(size.x - 28, 6)), border, true)
		draw_rect(Rect2(Vector2(14, 36), Vector2(size.x - 42, 4)), Color("#8fa3b2", 0.45), true)
		draw_rect(Rect2(Vector2(14, 50), Vector2(size.x - 58, 4)), Color("#8fa3b2", 0.3), true)
		if abnormal:
			draw_circle(Vector2(size.x - 18, 18), 5.0, Color("#d66a4f", 0.9))
		elif stable_state:
			draw_circle(Vector2(size.x - 18, 18), 5.0, Color("#d8e7f2", 0.8))

	func _draw_life_core() -> void:
		var stable_state := status_text == "stable"
		var stabilizing_state := status_text == "stabilizing"
		if highlighted:
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.1), true)
		draw_rect(Rect2(Vector2(18, 8), Vector2(size.x - 36, size.y - 16)), Color("#303d47"), true)
		draw_rect(Rect2(Vector2(30, 18), Vector2(size.x - 60, size.y - 36)), Color("#13212c"), true)
		var core_color := Color("#9fd7ff", 0.78) if stable_state else Color("#f0c766", 0.55 if stabilizing_state else 0.28)
		draw_circle(size * 0.5, 18.0, Color(core_color.r, core_color.g, core_color.b, 0.2))
		draw_circle(size * 0.5, 10.0, core_color)
		draw_line(Vector2(18, size.y - 20), Vector2(size.x - 18, size.y - 20), Color("#5d6f7d", 0.6), 3.0)

	func _draw_ventilation_unit() -> void:
		var active_state := status_text == "stable" or status_text == "stabilizing"
		if highlighted:
			draw_rect(Rect2(Vector2(-6, -6), size + Vector2(12, 12)), Color("#f0c766", 0.1), true)
		draw_rect(Rect2(Vector2.ZERO, size), Color("#303d47"), true)
		draw_rect(Rect2(Vector2(10, 10), size - Vector2(20, 20)), Color("#101d28"), true)
		var air_color := Color("#9fd7ff", 0.65) if active_state else Color("#5d6f7d", 0.35)
		for i in range(5):
			var y := 18 + i * 10
			draw_line(Vector2(18, y), Vector2(size.x - 18, y), air_color, 2.0)
		if active_state:
			draw_rect(Rect2(Vector2(18, size.y - 18), Vector2(size.x - 36, 4)), Color("#9fd7ff", 0.5), true)

	func _draw_plant_chamber() -> void:
		var stable_state := status_text == "stable"
		var stabilizing_state := status_text == "stabilizing"
		if highlighted:
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.12), true)
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.55), false, 2.0)
		draw_rect(Rect2(Vector2(10, 18), Vector2(size.x - 20, size.y - 30)), Color("#162631", 0.9), true)
		draw_rect(Rect2(Vector2(10, 18), Vector2(size.x - 20, size.y - 30)), Color("#9fd7ff", 0.32), false, 2.0)
		draw_rect(Rect2(Vector2(24, size.y - 28), Vector2(size.x - 48, 12)), Color("#303d47"), true)
		var plant_color := Color("#7dbd75", 0.92) if stable_state else Color("#6f8f62", 0.72 if stabilizing_state else 0.55)
		var stem_base := Vector2(size.x * 0.5, size.y - 36)
		draw_line(stem_base, stem_base + Vector2(0, -48), plant_color, 4.0)
		draw_circle(stem_base + Vector2(-16, -34), 12.0, plant_color)
		draw_circle(stem_base + Vector2(15, -43), 11.0, plant_color)
		draw_circle(stem_base + Vector2(-8, -58), 9.0, plant_color)
		if not stable_state:
			draw_line(stem_base + Vector2(14, -42), stem_base + Vector2(24, -34), Color("#d0b56f", 0.45), 2.0)

	func _draw_plant_scanner() -> void:
		if highlighted:
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.12), true)
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.55), false, 2.0)
		draw_rect(Rect2(Vector2(12, 30), Vector2(size.x - 24, size.y - 36)), Color("#303b44"), true)
		draw_rect(Rect2(Vector2(24, 8), Vector2(size.x - 48, 34)), Color("#101d28"), true)
		draw_rect(Rect2(Vector2(32, 16), Vector2(size.x - 64, 18)), Color("#236fa8"), true)
		draw_line(Vector2(size.x * 0.5, 46), Vector2(size.x * 0.5, size.y - 10), Color("#89d8ff", 0.62), 3.0)
		draw_arc(Vector2(size.x * 0.5, size.y - 18), 22.0, PI, TAU, 18, Color("#89d8ff", 0.55), 2.0)

	func _draw_plant_console() -> void:
		if highlighted:
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.12), true)
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.55), false, 2.0)
		draw_rect(Rect2(Vector2(10, 32), Vector2(size.x - 20, size.y - 38)), Color("#303b44"), true)
		draw_rect(Rect2(Vector2(22, 8), Vector2(size.x - 44, 38)), Color("#101d28"), true)
		var screen := Color("#f0c766", 0.62) if highlighted else Color("#236fa8", 0.75)
		if status_text == "stable":
			screen = Color("#7dbd75", 0.58)
		draw_rect(Rect2(Vector2(30, 16), Vector2(size.x - 60, 20)), screen, true)
		draw_rect(Rect2(Vector2(32, 58), Vector2(18, 10)), Color("#f0c766", 0.82), true)
		draw_rect(Rect2(Vector2(60, 58), Vector2(18, 10)), Color("#6fa7c8"), true)
		draw_rect(Rect2(Vector2(88, 58), Vector2(18, 10)), Color("#8fa3b2"), true)

	func _draw_grow_light() -> void:
		var on := status_text == "on" or status_text == "stable"
		if highlighted:
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.12), true)
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.45), false, 2.0)
		draw_rect(Rect2(Vector2(8, 10), Vector2(size.x - 16, 16)), Color("#303b44"), true)
		var glow := Color("#f0c766", 0.78) if on else Color("#5d6f7d", 0.32)
		draw_rect(Rect2(Vector2(20, 18), Vector2(size.x - 40, 8)), glow, true)
		draw_rect(Rect2(Vector2(18, 30), Vector2(size.x - 36, size.y - 38)), Color(glow.r, glow.g, glow.b, 0.11 if on else 0.03), true)

	func _draw_plant_status_display() -> void:
		var stable_state := status_text == "stable"
		var stabilizing_state := status_text == "stabilizing"
		var border := Color("#d66a4f", 0.72)
		if stabilizing_state:
			border = Color("#f0c766", 0.7)
		elif stable_state:
			border = Color("#7dbd75", 0.7)
		if highlighted:
			draw_rect(Rect2(Vector2(-6, -6), size + Vector2(12, 12)), Color("#f0c766", 0.1), true)
		draw_rect(Rect2(Vector2.ZERO, size), Color("#1a2b38"), true)
		draw_rect(Rect2(Vector2(8, 8), size - Vector2(16, 16)), Color("#0d1822"), true)
		draw_rect(Rect2(Vector2.ZERO, size), border, false, 2.0)
		draw_rect(Rect2(Vector2(14, 18), Vector2(size.x - 28, 6)), border, true)
		draw_rect(Rect2(Vector2(14, 36), Vector2(size.x - 42, 4)), Color("#8fa3b2", 0.45), true)
		draw_rect(Rect2(Vector2(14, 50), Vector2(size.x - 58, 4)), Color("#8fa3b2", 0.3), true)
		draw_circle(Vector2(size.x - 18, 18), 5.0, Color("#7dbd75", 0.85) if stable_state else Color("#d66a4f", 0.85))

	func _draw_assessment_terminal() -> void:
		if highlighted:
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.12), true)
			draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.55), false, 2.0)
		draw_rect(Rect2(Vector2(8, 28), Vector2(size.x - 16, size.y - 34)), Color("#303b44"), true)
		draw_rect(Rect2(Vector2(18, 8), Vector2(size.x - 36, 42)), Color("#101d28"), true)
		var screen := Color("#236fa8", 0.78)
		if status_text == "ready":
			screen = Color("#f0c766", 0.7)
		elif status_text == "complete":
			screen = Color("#d8e7f2", 0.78)
		draw_rect(Rect2(Vector2(26, 16), Vector2(size.x - 52, 24)), screen, true)
		draw_rect(Rect2(Vector2(24, 60), Vector2(size.x - 48, 6)), Color("#8fa3b2", 0.45), true)
		draw_rect(Rect2(Vector2(24, 74), Vector2(size.x - 72, 5)), Color("#f0c766", 0.45), true)
		draw_rect(Rect2(Vector2(24, 88), Vector2(size.x - 92, 5)), Color("#6fa7c8", 0.42), true)

	func _draw_exit() -> void:
		var edge := Color("#f0c766", 0.7) if highlighted and not locked else Color("#89d8ff", 0.28)
		draw_rect(Rect2(Vector2(14, 0), Vector2(size.x - 28, size.y)), Color("#34414c"), true)
		draw_rect(Rect2(Vector2(24, 10), Vector2(size.x - 48, size.y - 20)), Color("#1d2832"), true)
		draw_line(Vector2(size.x * 0.5, 12), Vector2(size.x * 0.5, size.y - 12), Color("#d8e7f2", 0.55), 2.0)
		draw_rect(Rect2(Vector2(4, 18), Vector2(10, size.y - 36)), edge, true)
		draw_rect(Rect2(Vector2(size.x - 14, 18), Vector2(10, size.y - 36)), edge, true)
		draw_rect(Rect2(Vector2(28, size.y - 20), Vector2(size.x - 56, 4)), Color("#f0c766", 0.55 if highlighted and not locked else 0.18), true)
		if locked:
			draw_string(ThemeDB.fallback_font, Vector2(28, size.y * 0.5), "锁定", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#8fa3b2"))

	func _draw_generic() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#2a3a45"), true)
		draw_rect(Rect2(Vector2.ZERO, size), Color("#6f8493"), false, 2.0)

	func _draw_debug_label() -> void:
		if label_text.is_empty():
			return
		var font := ThemeDB.fallback_font
		var font_size := 13
		draw_string(font, Vector2(8, -6), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#d8e7f2"))
		if active:
			draw_string(font, Vector2(8, size.y + 18), "E 交互", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#f0c766"))

class TraineeVisual:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := size * 0.5
		draw_circle(center + Vector2(0, -12), 10, Color("#e6eef4"))
		draw_circle(center + Vector2(0, -12), 7, Color("#1b2834"))
		draw_rect(Rect2(center + Vector2(-9, -3), Vector2(18, 23)), Color("#d8e0e6"), true)
		draw_rect(Rect2(center + Vector2(-6, 3), Vector2(12, 8)), Color("#7fa7bd"), true)
		draw_line(center + Vector2(-11, 1), center + Vector2(-18, 17), Color("#d8e0e6"), 4.0)
		draw_line(center + Vector2(11, 1), center + Vector2(18, 17), Color("#d8e0e6"), 4.0)
		draw_line(center + Vector2(-5, 20), center + Vector2(-8, 32), Color("#d8e0e6"), 4.0)
		draw_line(center + Vector2(5, 20), center + Vector2(8, 32), Color("#d8e0e6"), 4.0)
		draw_rect(Rect2(center + Vector2(-15, 4), Vector2(5, 12)), Color("#9aa8b4"), true)

@export var module_id := "suit_control"

var module_data: Dictionary = {}
var step_index := 0
var player: Control
var training_area: Control
var floor_node: Control
var objective_label: Label
var hud_label: Label
var hint_label: Label
var log_label: Label
var diagnosis_panel: VBoxContainer
var target_nodes: Dictionary = {}
var prompt_label: Label
var completed := false
var show_trigger_debug := false
var wait_timer := 0.0
var player_speed := 280.0

func _ready() -> void:
	_ensure_input_actions()
	module_data = _module_config(module_id)
	TrainingManagerScript.set_current_module(module_id)
	_build_screen()
	_update_hud()

func _process(delta: float) -> void:
	_move_player(delta)
	if not completed:
		_check_wait_step(delta)
		_check_auto_steps()
	_update_room_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not completed:
		_try_interact()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		show_trigger_debug = not show_trigger_debug
		_update_trigger_debug()
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _ensure_input_actions() -> void:
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var event := InputEventKey.new()
		event.physical_keycode = KEY_E
		InputMap.action_add_event("interact", event)

func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = Color("#06101a")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 36
	root.offset_top = 24
	root.offset_right = -36
	root.offset_bottom = -32
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	root.add_child(header)
	_add_header_label(header, "国家深空生命科学中心训练控制系统", Vector2(620, 46), 24, Color("#eaf4ff"))
	_add_header_label(header, String(module_data.get("subtitle", "TRAINING MODULE")), Vector2(420, 46), 13, Color("#6f8493"))
	_add_header_label(header, "训练编号  GHT-2068-0421", Vector2(280, 46), 14, Color("#8fa3b2"))

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	root.add_child(row)

	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(420, 0)
	row.add_child(left_panel)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 12)
	left_panel.add_child(left)

	var title := Label.new()
	title.text = String(module_data.get("title", "训练模块"))
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 24)
	left.add_child(title)

	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.modulate = Color("#d8e7f2")
	objective_label.add_theme_font_size_override("font_size", 18)
	left.add_child(objective_label)

	hud_label = Label.new()
	hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_label.modulate = Color("#9fb4c4")
	hud_label.add_theme_font_size_override("font_size", 15)
	left.add_child(hud_label)

	hint_label = Label.new()
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.modulate = Color("#86c7ff")
	hint_label.add_theme_font_size_override("font_size", 16)
	left.add_child(hint_label)

	diagnosis_panel = VBoxContainer.new()
	diagnosis_panel.visible = false
	diagnosis_panel.add_theme_constant_override("separation", 8)
	left.add_child(diagnosis_panel)

	log_label = Label.new()
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.modulate = Color("#d8e7f2")
	log_label.add_theme_font_size_override("font_size", 15)
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(log_label)

	var area_panel := PanelContainer.new()
	area_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(area_panel)
	training_area = Control.new()
	training_area.custom_minimum_size = Vector2(760, 520)
	area_panel.add_child(training_area)
	_build_training_area()

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.custom_minimum_size = Vector2(0, 48)
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)
	_add_button(footer, "保存训练进度", func(): TrainingManagerScript.set_current_module(module_id))
	_add_button(footer, "返回主菜单", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))

func _build_training_area() -> void:
	target_nodes.clear()
	var floor: Control
	if module_id == "suit_control":
		floor = TrainingRoomBlockout.new()
	elif module_id == "airlock_procedure":
		floor = AirlockRoomBlockout.new()
	elif module_id == "power_repair":
		floor = PowerRepairRoomBlockout.new()
	elif module_id == "life_support":
		floor = LifeSupportRoomBlockout.new()
	elif module_id == "plant_diagnosis":
		floor = PlantDiagnosisRoomBlockout.new()
	elif module_id == "final_assessment":
		floor = FinalAssessmentRoomBlockout.new()
	else:
		var flat_floor := ColorRect.new()
		flat_floor.color = Color("#0b1721")
		floor = flat_floor
	floor.set_anchors_preset(Control.PRESET_FULL_RECT)
	training_area.add_child(floor)
	floor_node = floor

	for target: Dictionary in module_data.get("targets", []):
		if module_id == "suit_control":
			target = _suit_room_target(target)
		elif module_id == "airlock_procedure":
			target = _airlock_room_target(target)
		elif module_id == "power_repair":
			target = _power_room_target(target)
		elif module_id == "life_support":
			target = _life_support_room_target(target)
		elif module_id == "plant_diagnosis":
			target = _plant_room_target(target)
		elif module_id == "final_assessment":
			target = _assessment_room_target(target)
		var node: Control
		if module_id == "suit_control" or module_id == "airlock_procedure" or module_id == "power_repair" or module_id == "life_support" or module_id == "plant_diagnosis" or module_id == "final_assessment":
			var visual := TrainingTargetVisual.new()
			visual.kind = String(target.get("kind", target.get("id", "target")))
			visual.label_text = String(target.get("label", ""))
			node = visual
		else:
			var block := ColorRect.new()
			block.color = target.get("color", Color("#23455f"))
			node = block
		node.name = String(target.get("id", "target"))
		node.position = target.get("position", Vector2(100, 100))
		node.size = target.get("size", Vector2(108, 70))
		training_area.add_child(node)
		target_nodes[node.name] = node
		if module_id != "suit_control" and module_id != "airlock_procedure" and module_id != "power_repair" and module_id != "life_support" and module_id != "plant_diagnosis" and module_id != "final_assessment":
			var label := Label.new()
			label.text = String(target.get("label", node.name))
			label.position = Vector2(8, 8)
			label.modulate = Color("#eaf4ff")
			label.add_theme_font_size_override("font_size", 13)
			node.add_child(label)

	if module_id == "suit_control" or module_id == "airlock_procedure" or module_id == "power_repair" or module_id == "life_support" or module_id == "plant_diagnosis" or module_id == "final_assessment":
		player = TraineeVisual.new()
	else:
		var player_block := ColorRect.new()
		player_block.color = Color("#d8e7f2")
		player = player_block
	player.name = "Candidate"
	player.position = module_data.get("player_start", Vector2(62, 420))
	player.size = module_data.get("player_size", Vector2(26, 34))
	training_area.add_child(player)

	prompt_label = Label.new()
	prompt_label.modulate = Color("#f0c766")
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.visible = false
	training_area.add_child(prompt_label)

func _suit_room_target(target: Dictionary) -> Dictionary:
	var id := String(target.get("id", ""))
	var room_target := target.duplicate()
	match id:
		"marker":
			room_target["kind"] = "marker"
			room_target["label"] = "标记区域"
			room_target["position"] = Vector2(146, 340)
			room_target["size"] = Vector2(112, 92)
		"terminal":
			room_target["kind"] = "terminal"
			room_target["label"] = "训练终端"
			room_target["position"] = Vector2(330, 92)
			room_target["size"] = Vector2(118, 88)
		"exit":
			room_target["kind"] = "exit"
			room_target["label"] = "训练出口"
			room_target["position"] = Vector2(660, 270)
			room_target["size"] = Vector2(96, 150)
	return room_target

func _airlock_room_target(target: Dictionary) -> Dictionary:
	var id := String(target.get("id", ""))
	var room_target := target.duplicate()
	match id:
		"chamber":
			room_target["kind"] = "zone"
			room_target["label"] = "气闸室"
			room_target["position"] = Vector2(300, 170)
			room_target["size"] = Vector2(176, 214)
		"inner_door":
			room_target["kind"] = "door"
			room_target["label"] = "内舱门"
			room_target["position"] = Vector2(254, 220)
			room_target["size"] = Vector2(54, 116)
		"console":
			room_target["kind"] = "pressure_console"
			room_target["label"] = "舱压控制台"
			room_target["position"] = Vector2(326, 92)
			room_target["size"] = Vector2(126, 88)
		"pressure_display":
			room_target["kind"] = "status_display"
			room_target["label"] = "舱压状态"
			room_target["position"] = Vector2(504, 96)
			room_target["size"] = Vector2(132, 72)
		"outer_door":
			room_target["kind"] = "door"
			room_target["label"] = "外舱门"
			room_target["position"] = Vector2(482, 220)
			room_target["size"] = Vector2(54, 116)
		"exterior":
			room_target["kind"] = "zone"
			room_target["label"] = "外部模拟区"
			room_target["position"] = Vector2(554, 190)
			room_target["size"] = Vector2(160, 190)
		"exit":
			room_target["kind"] = "exit"
			room_target["label"] = "训练出口"
			room_target["position"] = Vector2(684, 388)
			room_target["size"] = Vector2(74, 106)
	return room_target

func _power_room_target(target: Dictionary) -> Dictionary:
	var id := String(target.get("id", ""))
	var room_target := target.duplicate()
	match id:
		"tools":
			room_target["kind"] = "tool_station"
			room_target["label"] = "工具台"
			room_target["position"] = Vector2(92, 348)
			room_target["size"] = Vector2(132, 92)
		"panel":
			room_target["kind"] = "power_panel"
			room_target["label"] = "故障供电面板"
			room_target["position"] = Vector2(326, 116)
			room_target["size"] = Vector2(140, 104)
		"console":
			room_target["kind"] = "power_console"
			room_target["label"] = "供电控制台"
			room_target["position"] = Vector2(586, 194)
			room_target["size"] = Vector2(136, 92)
		"light":
			room_target["kind"] = "test_light"
			room_target["label"] = "测试灯"
			room_target["position"] = Vector2(434, 312)
			room_target["size"] = Vector2(86, 92)
		"exit":
			room_target["kind"] = "exit"
			room_target["label"] = "训练出口"
			room_target["position"] = Vector2(684, 388)
			room_target["size"] = Vector2(74, 106)
	return room_target

func _life_support_room_target(target: Dictionary) -> Dictionary:
	var id := String(target.get("id", ""))
	var room_target := target.duplicate()
	match id:
		"console":
			room_target["kind"] = "life_console"
			room_target["label"] = "生命支持控制台"
			room_target["position"] = Vector2(88, 220)
			room_target["size"] = Vector2(140, 96)
		"oxygen":
			room_target["kind"] = "life_status"
			room_target["label"] = "氧气状态"
			room_target["position"] = Vector2(292, 118)
			room_target["size"] = Vector2(118, 78)
		"water":
			room_target["kind"] = "life_status"
			room_target["label"] = "水循环状态"
			room_target["position"] = Vector2(430, 118)
			room_target["size"] = Vector2(118, 78)
		"power":
			room_target["kind"] = "life_status"
			room_target["label"] = "电力状态"
			room_target["position"] = Vector2(292, 224)
			room_target["size"] = Vector2(118, 78)
		"temperature":
			room_target["kind"] = "life_status"
			room_target["label"] = "温度状态"
			room_target["position"] = Vector2(430, 224)
			room_target["size"] = Vector2(118, 78)
		"core":
			room_target["kind"] = "life_core"
			room_target["label"] = "生命支持核心"
			room_target["position"] = Vector2(610, 130)
			room_target["size"] = Vector2(118, 132)
		"vent":
			room_target["kind"] = "ventilation"
			room_target["label"] = "通风单元"
			room_target["position"] = Vector2(606, 310)
			room_target["size"] = Vector2(124, 72)
		"exit":
			room_target["kind"] = "exit"
			room_target["label"] = "训练出口"
			room_target["position"] = Vector2(684, 388)
			room_target["size"] = Vector2(74, 106)
	return room_target

func _plant_room_target(target: Dictionary) -> Dictionary:
	var id := String(target.get("id", ""))
	var room_target := target.duplicate()
	match id:
		"plant":
			room_target["kind"] = "plant_chamber"
			room_target["label"] = "训练植物舱"
			room_target["position"] = Vector2(330, 168)
			room_target["size"] = Vector2(150, 170)
		"scanner":
			room_target["kind"] = "plant_scanner"
			room_target["label"] = "植物扫描器"
			room_target["position"] = Vector2(92, 286)
			room_target["size"] = Vector2(132, 108)
		"light_console":
			room_target["kind"] = "plant_console"
			room_target["label"] = "补光控制台"
			room_target["position"] = Vector2(590, 248)
			room_target["size"] = Vector2(138, 94)
		"grow_light":
			room_target["kind"] = "grow_light"
			room_target["label"] = "补光灯"
			room_target["position"] = Vector2(338, 82)
			room_target["size"] = Vector2(134, 82)
		"plant_status":
			room_target["kind"] = "plant_status"
			room_target["label"] = "植物状态"
			room_target["position"] = Vector2(558, 104)
			room_target["size"] = Vector2(154, 82)
		"exit":
			room_target["kind"] = "exit"
			room_target["label"] = "训练出口"
			room_target["position"] = Vector2(684, 388)
			room_target["size"] = Vector2(74, 106)
	return room_target

func _assessment_room_target(target: Dictionary) -> Dictionary:
	var id := String(target.get("id", ""))
	var room_target := target.duplicate()
	match id:
		"terminal":
			room_target["kind"] = "assessment_terminal"
			room_target["label"] = "考核终端"
			room_target["position"] = Vector2(336, 384)
			room_target["size"] = Vector2(146, 96)
		"tools":
			room_target["kind"] = "tool_station"
			room_target["label"] = "工具台"
			room_target["position"] = Vector2(74, 226)
			room_target["size"] = Vector2(118, 84)
		"panel":
			room_target["kind"] = "power_panel"
			room_target["label"] = "故障供电面板"
			room_target["position"] = Vector2(82, 112)
			room_target["size"] = Vector2(132, 94)
		"power_console":
			room_target["kind"] = "power_console"
			room_target["label"] = "供电控制台"
			room_target["position"] = Vector2(82, 334)
			room_target["size"] = Vector2(132, 88)
		"test_light":
			room_target["kind"] = "test_light"
			room_target["label"] = "测试灯"
			room_target["position"] = Vector2(188, 118)
			room_target["size"] = Vector2(72, 76)
		"life_console":
			room_target["kind"] = "life_console"
			room_target["label"] = "生命支持控制台"
			room_target["position"] = Vector2(302, 250)
			room_target["size"] = Vector2(132, 88)
		"oxygen":
			room_target["kind"] = "life_status"
			room_target["label"] = "氧气状态"
			room_target["position"] = Vector2(276, 112)
			room_target["size"] = Vector2(96, 66)
		"water":
			room_target["kind"] = "life_status"
			room_target["label"] = "水循环"
			room_target["position"] = Vector2(388, 112)
			room_target["size"] = Vector2(96, 66)
		"power_display":
			room_target["kind"] = "life_status"
			room_target["label"] = "电力状态"
			room_target["position"] = Vector2(276, 188)
			room_target["size"] = Vector2(96, 66)
		"temperature":
			room_target["kind"] = "life_status"
			room_target["label"] = "温度状态"
			room_target["position"] = Vector2(388, 188)
			room_target["size"] = Vector2(96, 66)
		"life_core":
			room_target["kind"] = "life_core"
			room_target["label"] = "生命支持核心"
			room_target["position"] = Vector2(418, 252)
			room_target["size"] = Vector2(72, 88)
		"plant":
			room_target["kind"] = "plant_chamber"
			room_target["label"] = "植物舱"
			room_target["position"] = Vector2(542, 154)
			room_target["size"] = Vector2(116, 142)
		"scanner":
			room_target["kind"] = "plant_scanner"
			room_target["label"] = "植物扫描器"
			room_target["position"] = Vector2(670, 128)
			room_target["size"] = Vector2(82, 88)
		"light_console":
			room_target["kind"] = "plant_console"
			room_target["label"] = "补光控制台"
			room_target["position"] = Vector2(662, 254)
			room_target["size"] = Vector2(100, 82)
		"grow_light":
			room_target["kind"] = "grow_light"
			room_target["label"] = "补光灯"
			room_target["position"] = Vector2(542, 102)
			room_target["size"] = Vector2(116, 60)
		"plant_status":
			room_target["kind"] = "plant_status"
			room_target["label"] = "植物状态"
			room_target["position"] = Vector2(546, 304)
			room_target["size"] = Vector2(108, 66)
	return room_target

func _move_player(delta: float) -> void:
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	if direction.length() > 1.0:
		direction = direction.normalized()
	player.position += direction * player_speed * delta
	var use_wall_margin := module_id == "suit_control" or module_id == "power_repair" or module_id == "life_support" or module_id == "plant_diagnosis" or module_id == "final_assessment"
	var margin := 36.0 if use_wall_margin else 8.0
	player.position.x = clamp(player.position.x, margin, max(margin, training_area.size.x - player.size.x - margin))
	player.position.y = clamp(player.position.y, margin, max(margin, training_area.size.y - player.size.y - margin))

func _check_auto_steps() -> void:
	var step := _current_step()
	if step.is_empty() or String(step.get("type", "")) != "move":
		return
	if _is_inside_target_area(String(step.get("target", ""))):
		_complete_step()

func _check_wait_step(delta: float) -> void:
	var step := _current_step()
	if step.is_empty() or String(step.get("type", "")) != "wait":
		return
	wait_timer += delta
	if wait_timer >= float(step.get("duration", 1.5)):
		wait_timer = 0.0
		_complete_step()

func _try_interact() -> void:
	var step := _current_step()
	if step.is_empty():
		return
	var step_type := String(step.get("type", "interact"))
	if step_type == "diagnosis":
		hint_label.text = "请在左侧选择诊断结果。"
		return
	var target := String(step.get("target", ""))
	if step_type == "move":
		if _is_inside_target_area(target):
			_complete_step()
		else:
			hint_label.text = String(step.get("hint", "请移动至目标区域。"))
		return
	if not _is_near(target):
		var wrong_order_hint := _wrong_order_hint()
		if not wrong_order_hint.is_empty():
			hint_label.text = wrong_order_hint
			return
		hint_label.text = "请先移动至目标区域。"
		return
	if _blocked_by_order(step):
		hint_label.text = String(step.get("blocked_hint", "流程顺序错误。请按当前目标执行。"))
		return
	_complete_step()

func _current_step() -> Dictionary:
	var steps: Array = module_data.get("steps", [])
	if step_index >= steps.size():
		return {}
	return steps[step_index]

func _complete_step() -> void:
	var step := _current_step()
	if step.is_empty():
		return
	if step.has("state_key"):
		module_data["state"][String(step["state_key"])] = step.get("state_value", true)
	if step.has("state_updates"):
		var updates: Dictionary = step.get("state_updates", {})
		for key in updates.keys():
			module_data["state"][String(key)] = updates[key]
	_add_log(String(step.get("line", "")))
	step_index += 1
	wait_timer = 0.0
	if String(step.get("type", "")) == "diagnosis":
		diagnosis_panel.visible = false
	if step_index >= (module_data.get("steps", []) as Array).size():
		_finish_module()
	else:
		_update_hud()

func _finish_module() -> void:
	completed = true
	var next_module := String(module_data.get("next_module", "mission_assignment"))
	TrainingManagerScript.mark_module_completed(module_id, next_module)
	if module_id == "suit_control":
		get_tree().change_scene_to_file(String(module_data.get("next_scene", TrainingManagerScript.START_SCENE)))
		return
	hint_label.text = "模块完成。"
	_update_hud()
	var button := Button.new()
	button.text = String(module_data.get("next_button", "进入下一阶段"))
	button.custom_minimum_size = Vector2(0, 42)
	button.pressed.connect(func():
		get_tree().change_scene_to_file(String(module_data.get("next_scene", TrainingManagerScript.START_SCENE)))
	)
	diagnosis_panel.visible = true
	diagnosis_panel.add_child(button)

func _blocked_by_order(step: Dictionary) -> bool:
	var requires: Dictionary = step.get("requires", {})
	var state: Dictionary = module_data.get("state", {})
	for key in requires.keys():
		if state.get(key, null) != requires[key]:
			return true
	return false

func _wrong_order_hint() -> String:
	var state: Dictionary = module_data.get("state", {})
	if module_id == "airlock_procedure":
		if target_nodes.has("outer_door") and _is_near("outer_door"):
			if not bool(state.get("InnerDoorClosed", false)):
				return "流程顺序错误。请先关闭内舱门。"
			if not bool(state.get("PressureStable", false)):
				return "舱压尚未稳定。外舱门保持锁定。"
		if target_nodes.has("console") and _is_near("console") and not bool(state.get("InnerDoorClosed", false)):
			return "流程顺序错误。请先关闭内舱门。"
		if target_nodes.has("inner_door") and _is_near("inner_door") and bool(state.get("InnerDoorClosed", false)):
			return "内舱门已关闭。请继续舱压流程。"
	if module_id == "power_repair":
		if target_nodes.has("panel") and _is_near("panel") and not bool(state.get("HasRepairTool", false)):
			return "未检测到维修工具。请先前往工具台。"
		if target_nodes.has("console") and _is_near("console"):
			if not bool(state.get("PowerPanelRepaired", false)):
				return "供电面板尚未修复。无法重启供电。"
		if target_nodes.has("exit") and _is_near("exit") and not bool(state.get("TestLightOn", false)):
			return "训练模块尚未完成。"
	if module_id == "life_support":
		for display_id in ["oxygen", "water", "power", "temperature"]:
			if target_nodes.has(display_id) and _is_near(display_id) and not bool(state.get("LifeSupportConsoleOpened", false)):
				return "请先打开生命支持控制台。"
		if target_nodes.has("console") and _is_near("console"):
			if bool(state.get("LifeSupportConsoleOpened", false)) and not bool(state.get("LifeSupportStatusRead", false)):
				return "请先读取当前生命支持状态。"
		if target_nodes.has("exit") and _is_near("exit") and not bool(state.get("LifeSupportConfirmed", false)):
			return "生命支持状态尚未稳定。训练模块未完成。"
	if module_id == "plant_diagnosis":
		if target_nodes.has("scanner") and _is_near("scanner") and not bool(state.get("PlantObserved", false)):
			return "请先靠近植物舱进行观察。"
		if target_nodes.has("light_console") and _is_near("light_console") and not bool(state.get("DiagnosisSelected", false)):
			return "请先确认植物异常原因。"
		if target_nodes.has("exit") and _is_near("exit") and not bool(state.get("PlantStable", false)):
			return "训练模块尚未完成。"
	if module_id == "final_assessment":
		if target_nodes.has("life_console") and _is_near("life_console") and not bool(state.get("PowerRestored", false)):
			return "供电尚未恢复。生命支持系统无法进入稳定流程。"
		if (target_nodes.has("plant") and _is_near("plant")) or (target_nodes.has("scanner") and _is_near("scanner")):
			if not bool(state.get("LifeSupportStable", false)):
				return "生命支持状态尚未稳定。植物舱诊断结果可能不可靠。"
		if target_nodes.has("light_console") and _is_near("light_console") and String(state.get("CorrectDiagnosis", "")) != "LightInsufficient":
			return "请先确认植物异常原因。"
		if target_nodes.has("terminal") and _is_near("terminal") and bool(state.get("AssessmentBriefingRead", false)):
			if not (bool(state.get("PowerRestored", false)) and bool(state.get("LifeSupportStable", false)) and bool(state.get("PlantStable", false))):
				return "考核结果不完整。请确认供电、生命支持与植物舱状态。"
	return ""

func _is_near(target_id: String) -> bool:
	if not target_nodes.has(target_id):
		return false
	var target: Control = target_nodes[target_id]
	var player_center := player.position + player.size * 0.5
	var target_center := target.position + target.size * 0.5
	return player_center.distance_to(target_center) <= 95.0

func _is_inside_target_area(target_id: String) -> bool:
	if not target_nodes.has(target_id):
		return false
	var target: Control = target_nodes[target_id]
	var target_rect := Rect2(target.position, target.size)
	var player_feet := player.position + Vector2(player.size.x * 0.5, player.size.y)
	return target_rect.has_point(player_feet)

func _update_trigger_debug() -> void:
	for node in target_nodes.values():
		if node is TrainingTargetVisual:
			node.show_trigger_debug = show_trigger_debug and node.kind == "marker"
			node.queue_redraw()

func _update_room_prompt() -> void:
	if prompt_label == null:
		return
	var step := _current_step()
	var target_id := String(step.get("target", "")) if not step.is_empty() else ""
	for node in target_nodes.values():
		if node is TrainingTargetVisual:
			node.highlighted = node.name == target_id
			node.active = false
			node.locked = _target_locked(String(node.name), target_id)
			node.modulate = Color(1, 1, 1, 1) if node.highlighted else Color(0.72, 0.78, 0.84, 0.72)
			node.show_trigger_debug = show_trigger_debug and node.kind == "marker"
			if module_id == "power_repair":
				node.status_text = _power_visual_status(String(node.name))
			if module_id == "life_support":
				node.status_text = _life_support_visual_status(String(node.name))
			if module_id == "plant_diagnosis":
				node.status_text = _plant_visual_status(String(node.name))
			if module_id == "final_assessment":
				node.status_text = _assessment_visual_status(String(node.name))
			if module_id == "airlock_procedure" and node.name == "pressure_display":
				node.status_text = "舱压：%s" % _airlock_pressure_status()
			node.queue_redraw()
	if module_id == "power_repair" and floor_node != null:
		var state: Dictionary = module_data.get("state", {})
		floor_node.set("power_on", bool(state.get("PowerRestored", false)))
		floor_node.queue_redraw()
	if module_id == "life_support" and floor_node != null:
		var state: Dictionary = module_data.get("state", {})
		floor_node.set("stable", bool(state.get("LifeSupportStable", false)))
		floor_node.set("stabilizing", bool(state.get("StabilizationStarted", false)) and not bool(state.get("LifeSupportStable", false)))
		floor_node.queue_redraw()
	if module_id == "plant_diagnosis" and floor_node != null:
		var state: Dictionary = module_data.get("state", {})
		floor_node.set("plant_stable", bool(state.get("PlantStable", false)))
		floor_node.set("grow_light_on", bool(state.get("GrowLightAdjusted", false)))
		floor_node.queue_redraw()
	if module_id == "final_assessment" and floor_node != null:
		var state: Dictionary = module_data.get("state", {})
		floor_node.set("power_on", bool(state.get("PowerRestored", false)))
		floor_node.set("life_stable", bool(state.get("LifeSupportStable", false)))
		floor_node.set("plant_stable", bool(state.get("PlantStable", false)))
		floor_node.queue_redraw()
	if completed or step.is_empty():
		prompt_label.visible = false
		return
	if not target_nodes.has(target_id):
		prompt_label.visible = false
		return
	var target: Control = target_nodes[target_id]
	var near := _is_near(target_id)
	if target is TrainingTargetVisual:
		target.active = near and String(step.get("type", "")) == "interact"
		target.queue_redraw()
	if near and String(step.get("type", "")) == "interact":
		prompt_label.text = _interaction_prompt(target_id)
		prompt_label.position = target.position + Vector2(8, target.size.y + 20)
		prompt_label.visible = true
	else:
		prompt_label.visible = false

func _target_locked(node_name: String, target_id: String) -> bool:
	if node_name == "exit":
		return target_id != "exit"
	if module_id == "airlock_procedure" and node_name == "outer_door":
		var state: Dictionary = module_data.get("state", {})
		return not bool(state.get("PressureStable", false))
	return false

func _interaction_prompt(target_id: String) -> String:
	if module_id == "airlock_procedure":
		match target_id:
			"inner_door":
				return "E 关闭内舱门"
			"console":
				return "E 使用舱压控制台"
			"outer_door":
				return "E 打开外舱门"
			"exit":
				return "E 进入下一模块"
	if module_id == "power_repair":
		match target_id:
			"tools":
				return "E 取用维修工具"
			"panel":
				var state: Dictionary = module_data.get("state", {})
				if bool(state.get("PowerPanelInspected", false)):
					return "E 维修供电面板"
				return "E 检查供电面板"
			"console":
				return "E 重启供电"
			"exit":
				return "E 进入下一模块"
	if module_id == "life_support":
		match target_id:
			"console":
				var state: Dictionary = module_data.get("state", {})
				if bool(state.get("LifeSupportStatusRead", false)):
					return "E 启动稳定程序"
				return "E 打开生命支持控制台"
			"oxygen", "water", "power", "temperature":
				return "E 确认状态"
			"exit":
				return "E 进入下一模块"
	if module_id == "plant_diagnosis":
		match target_id:
			"plant":
				return "E 观察植物"
			"scanner":
				return "E 使用扫描器"
			"light_console":
				return "E 调整补光"
			"exit":
				return "E 进入最终考核"
	if module_id == "final_assessment":
		match target_id:
			"terminal":
				var state: Dictionary = module_data.get("state", {})
				if bool(state.get("PowerRestored", false)) and bool(state.get("LifeSupportStable", false)) and bool(state.get("PlantStable", false)):
					return "E 提交考核结果"
				return "E 读取考核终端"
			"tools":
				return "E 取用维修工具"
			"panel":
				var state: Dictionary = module_data.get("state", {})
				if bool(state.get("PowerPanelInspected", false)):
					return "E 维修供电面板"
				return "E 检查供电面板"
			"power_console":
				return "E 重启供电"
			"life_console":
				var state: Dictionary = module_data.get("state", {})
				if bool(state.get("LifeSupportConsoleOpened", false)):
					return "E 启动稳定程序"
				return "E 打开生命支持控制台"
			"plant":
				return "E 观察植物"
			"scanner":
				return "E 使用扫描器"
			"light_console":
				return "E 调整补光"
	if target_id == "terminal":
		return "E 使用训练终端"
	return "E 交互"

func _show_diagnosis_options(options: Array, correct: String) -> void:
	diagnosis_panel.visible = true
	_clear_container(diagnosis_panel)
	for option in options:
		var button := Button.new()
		button.text = String(option)
		button.custom_minimum_size = Vector2(0, 38)
		button.pressed.connect(func():
			if button.text == correct:
				_complete_step()
			else:
				hint_label.text = String(_current_step().get("wrong_hint", "诊断结论不足。请重新核对观察信息。"))
		)
		diagnosis_panel.add_child(button)

func _update_hud() -> void:
	var step := _current_step()
	var objective := String(step.get("objective", "训练流程已完成。")) if not completed else "训练流程已完成。"
	objective_label.text = "当前目标：%s" % objective
	if module_id == "airlock_procedure":
		hud_label.text = _airlock_hud_text()
	elif module_id == "power_repair":
		hud_label.text = _power_hud_text()
	elif module_id == "life_support":
		hud_label.text = _life_support_hud_text()
	elif module_id == "plant_diagnosis":
		hud_label.text = _plant_hud_text()
	elif module_id == "final_assessment":
		hud_label.text = _assessment_hud_text()
	else:
		hud_label.text = String(module_data.get("hud", "氧气模拟值：98%\n电力模拟值：稳定\n生命支持状态：训练环境"))
	if module_id == "suit_control" and not completed:
		hint_label.text = _suit_control_hint(step)
	elif module_id == "airlock_procedure" and not completed:
		hint_label.text = _airlock_hint(step)
	elif module_id == "power_repair" and not completed:
		hint_label.text = _power_hint(step)
	elif module_id == "life_support" and not completed:
		hint_label.text = _life_support_hint(step)
	elif module_id == "plant_diagnosis" and not completed:
		hint_label.text = _plant_hint(step)
	elif module_id == "final_assessment" and not completed:
		hint_label.text = _assessment_hint(step)
	else:
		hint_label.text = String(step.get("hint", "移动至目标区域，按 E 交互。")) if not completed else "训练记录已保存。"
	if String(step.get("type", "")) == "diagnosis":
		_show_diagnosis_options(step.get("options", []), String(step.get("correct", "")))

func _suit_control_hint(step: Dictionary) -> String:
	match String(step.get("target", "")):
		"marker":
			return "请移动至蓝色标记区域。"
		"terminal":
			return "请靠近训练终端并按 E。"
		"exit":
			return "训练记录完成。请前往训练出口并按 E。"
	return "请按当前目标执行训练流程。"

func _airlock_hud_text() -> String:
	var pressure_status := _airlock_pressure_status()
	return "氧气模拟值：98%%\n电力模拟值：稳定\n舱压状态：%s\n提示信息：按当前流程执行。" % pressure_status

func _airlock_pressure_status() -> String:
	var state: Dictionary = module_data.get("state", {})
	if bool(state.get("PressureStable", false)):
		return "稳定"
	if bool(state.get("PressureSimulationStarted", false)):
		return "稳定中"
	return "未启动"

func _airlock_hint(step: Dictionary) -> String:
	match String(step.get("target", "")):
		"chamber":
			return "请移动至气闸室内部。"
		"inner_door":
			return "请靠近内舱门控制面板并按 E。"
		"console":
			return "请使用舱压控制台。"
		"outer_door":
			return "请靠近外舱门并按 E。"
		"exterior":
			return "请移动至外部模拟区。"
	if String(step.get("type", "")) == "wait":
		return "请等待舱压状态稳定。"
	return "请按气闸流程继续。"

func _power_hud_text() -> String:
	return "氧气模拟值：98%%\n电力模拟值：%s\n生命支持状态：训练环境\n提示信息：%s" % [_power_status(), _power_hint(_current_step())]

func _power_status() -> String:
	var state: Dictionary = module_data.get("state", {})
	if bool(state.get("PowerRestored", false)) or bool(state.get("TestLightOn", false)):
		return "稳定"
	if bool(state.get("PowerPanelRepaired", false)) or bool(state.get("PowerPanelInspected", false)):
		return "维修中"
	return "故障"

func _power_visual_status(node_name: String) -> String:
	var state: Dictionary = module_data.get("state", {})
	match node_name:
		"panel":
			if bool(state.get("PowerPanelRepaired", false)):
				return "repaired"
			if bool(state.get("PowerPanelInspected", false)):
				return "repairing"
		"console":
			if bool(state.get("PowerRestored", false)):
				return "restored"
		"light":
			if bool(state.get("TestLightOn", false)) or bool(state.get("PowerRestored", false)):
				return "on"
	return ""

func _power_hint(step: Dictionary) -> String:
	var state: Dictionary = module_data.get("state", {})
	match String(step.get("target", "")):
		"tools":
			return "请前往工具台，取用维修工具。"
		"panel":
			if bool(state.get("PowerPanelInspected", false)):
				return "请使用维修工具修复供电面板。"
			return "请靠近故障供电面板并按 E。"
		"console":
			return "请前往供电控制台，重启训练舱供电。"
		"light":
			return "请确认测试灯已亮起。"
		"exit":
			return "模块三记录已完成。\n请前往训练出口，进入下一训练模块。"
	if String(step.get("type", "")) == "wait":
		return "请观察测试灯恢复。"
	return "请按供电维修流程继续。"

func _life_support_hud_text() -> String:
	var status := _life_support_status()
	var oxygen := "稳定" if status == "稳定" else "偏低"
	var temperature := "稳定" if status == "稳定" else "偏低"
	return "氧气模拟值：%s\n水循环状态：稳定\n电力模拟值：稳定\n温度模拟值：%s\n生命支持状态：%s\n提示信息：%s" % [oxygen, temperature, status, _life_support_hint(_current_step())]

func _life_support_status() -> String:
	var state: Dictionary = module_data.get("state", {})
	if bool(state.get("LifeSupportStable", false)):
		return "稳定"
	if bool(state.get("StabilizationStarted", false)):
		return "稳定中"
	return "未稳定"

func _life_support_visual_status(node_name: String) -> String:
	var state: Dictionary = module_data.get("state", {})
	if node_name == "console":
		if bool(state.get("LifeSupportStable", false)):
			return "stable"
		if bool(state.get("StabilizationStarted", false)):
			return "stabilizing"
		return "open" if bool(state.get("LifeSupportConsoleOpened", false)) else ""
	if node_name == "oxygen" or node_name == "temperature":
		if bool(state.get("LifeSupportStable", false)):
			return "stable"
		if bool(state.get("StabilizationStarted", false)):
			return "stabilizing"
		return "low"
	if node_name == "water" or node_name == "power":
		return "stable"
	if node_name == "core" or node_name == "vent":
		if bool(state.get("LifeSupportStable", false)):
			return "stable"
		if bool(state.get("StabilizationStarted", false)):
			return "stabilizing"
	return ""

func _life_support_hint(step: Dictionary) -> String:
	match String(step.get("target", "")):
		"console":
			var state: Dictionary = module_data.get("state", {})
			if bool(state.get("LifeSupportStatusRead", false)):
				return "请在生命支持控制台启动稳定程序。"
			return "请靠近生命支持控制台并按 E。"
		"oxygen", "water", "power", "temperature":
			return "请查看氧气、水、电力与温度状态。"
		"core":
			return "请等待生命支持系统完成稳定流程。"
		"vent":
			return "请确认四项状态均已稳定。"
		"exit":
			return "模块四记录已完成。\n请前往训练出口，进入下一训练模块。"
	if String(step.get("type", "")) == "wait":
		return "请等待生命支持系统完成稳定流程。"
	return "请按生命支持训练流程继续。"

func _plant_hud_text() -> String:
	return "氧气模拟值：98%%\n电力模拟值：稳定\n生命支持状态：稳定\n植物状态：%s\n提示信息：%s" % [_plant_status(), _plant_hint(_current_step())]

func _plant_status() -> String:
	var state: Dictionary = module_data.get("state", {})
	if bool(state.get("PlantStable", false)):
		return "稳定"
	if bool(state.get("GrowLightAdjusted", false)):
		return "稳定中"
	return "异常"

func _plant_visual_status(node_name: String) -> String:
	var state: Dictionary = module_data.get("state", {})
	match node_name:
		"plant", "plant_status":
			if bool(state.get("PlantStable", false)):
				return "stable"
			if bool(state.get("GrowLightAdjusted", false)):
				return "stabilizing"
			return "abnormal"
		"grow_light":
			if bool(state.get("GrowLightAdjusted", false)):
				return "on"
		"light_console":
			if bool(state.get("PlantStable", false)):
				return "stable"
		"scanner":
			if bool(state.get("PlantScanned", false)):
				return "scanned"
	return ""

func _plant_hint(step: Dictionary) -> String:
	match String(step.get("target", "")):
		"plant":
			var state: Dictionary = module_data.get("state", {})
			if bool(state.get("PlantStable", false)):
				return "请确认植物状态已经趋于稳定。"
			return "请靠近训练植物舱进行观察。"
		"scanner":
			return "请前往植物扫描器并按 E。"
		"light_console":
			return "请前往补光控制台并按 E。"
		"plant_status":
			return "请等待植物状态恢复稳定。"
		"exit":
			return "模块五记录已完成。\n请前往训练出口，进入最终考核。"
	if String(step.get("type", "")) == "diagnosis":
		return "请根据观察与扫描结果选择异常原因。"
	if String(step.get("type", "")) == "wait":
		return "请等待植物状态恢复稳定。"
	return "请按植物诊断流程继续。"

func _assessment_hud_text() -> String:
	return "供电状态：%s\n生命支持状态：%s\n植物舱状态：%s\n氧气模拟值：%s\n电力模拟值：%s\n提示信息：%s" % [
		_assessment_power_status(),
		_assessment_life_status(),
		_assessment_plant_status(),
		String((module_data.get("state", {}) as Dictionary).get("OxygenStatus", "偏低")),
		String((module_data.get("state", {}) as Dictionary).get("PowerStatus", "故障")),
		_assessment_hint(_current_step()),
	]

func _assessment_power_status() -> String:
	var state: Dictionary = module_data.get("state", {})
	if bool(state.get("PowerRestored", false)):
		return "稳定"
	if bool(state.get("PowerPanelRepaired", false)):
		return "待重启"
	if bool(state.get("PowerPanelInspected", false)):
		return "维修中"
	return "故障"

func _assessment_life_status() -> String:
	var state: Dictionary = module_data.get("state", {})
	if bool(state.get("LifeSupportStable", false)):
		return "稳定"
	if bool(state.get("StabilizationStarted", false)):
		return "稳定中"
	return "未稳定"

func _assessment_plant_status() -> String:
	var state: Dictionary = module_data.get("state", {})
	if bool(state.get("PlantStable", false)):
		return "稳定"
	if bool(state.get("GrowLightAdjusted", false)):
		return "稳定中"
	return "异常"

func _assessment_visual_status(node_name: String) -> String:
	var state: Dictionary = module_data.get("state", {})
	match node_name:
		"terminal":
			if bool(state.get("FinalAssessmentCompleted", false)):
				return "complete"
			if bool(state.get("PowerRestored", false)) and bool(state.get("LifeSupportStable", false)) and bool(state.get("PlantStable", false)):
				return "ready"
		"panel":
			if bool(state.get("PowerPanelRepaired", false)):
				return "repaired"
			if bool(state.get("PowerPanelInspected", false)):
				return "repairing"
		"power_console":
			if bool(state.get("PowerRestored", false)):
				return "restored"
		"test_light":
			if bool(state.get("TestLightOn", false)) or bool(state.get("PowerRestored", false)):
				return "on"
		"life_console":
			if bool(state.get("LifeSupportStable", false)):
				return "stable"
			if bool(state.get("StabilizationStarted", false)):
				return "stabilizing"
			return "open" if bool(state.get("LifeSupportConsoleOpened", false)) else ""
		"oxygen", "temperature":
			if bool(state.get("LifeSupportStable", false)):
				return "stable"
			if bool(state.get("StabilizationStarted", false)):
				return "stabilizing"
			return "low"
		"water", "power_display":
			return "stable"
		"life_core":
			if bool(state.get("LifeSupportStable", false)):
				return "stable"
			if bool(state.get("StabilizationStarted", false)):
				return "stabilizing"
		"plant", "plant_status":
			if bool(state.get("PlantStable", false)):
				return "stable"
			if bool(state.get("GrowLightAdjusted", false)):
				return "stabilizing"
			return "abnormal"
		"scanner":
			if bool(state.get("PlantScanned", false)):
				return "scanned"
		"grow_light":
			if bool(state.get("GrowLightAdjusted", false)):
				return "on"
		"light_console":
			if bool(state.get("PlantStable", false)):
				return "stable"
	return ""

func _assessment_hint(step: Dictionary) -> String:
	match String(step.get("target", "")):
		"terminal":
			var state: Dictionary = module_data.get("state", {})
			if bool(state.get("PowerRestored", false)) and bool(state.get("LifeSupportStable", false)) and bool(state.get("PlantStable", false)):
				return "请回到考核终端提交结果。"
			return "请先读取考核终端，确认模拟事故。"
		"tools":
			return "请先取得维修工具。"
		"panel":
			var state: Dictionary = module_data.get("state", {})
			if bool(state.get("PowerPanelInspected", false)):
				return "请维修故障供电面板。"
			return "请检查故障供电面板。"
		"power_console":
			return "请重启训练舱供电。"
		"life_console":
			var state: Dictionary = module_data.get("state", {})
			if bool(state.get("LifeSupportConsoleOpened", false)):
				return "请启动生命支持稳定程序。"
			return "请打开生命支持控制台。"
		"life_core":
			return "请等待生命支持系统稳定。"
		"plant":
			return "请观察植物舱状态。"
		"scanner":
			return "请使用植物扫描器。"
		"light_console":
			return "请调整补光方案。"
		"plant_status":
			return "请等待植物舱状态稳定。"
	if String(step.get("type", "")) == "diagnosis":
		return "请根据扫描结果选择植物异常原因。"
	if String(step.get("type", "")) == "wait":
		return "请等待模拟状态稳定。"
	return "请按最终考核流程处理模拟事故。"

func _add_log(line: String) -> void:
	if line.is_empty():
		return
	log_label.text += line + "\n"

func _add_header_label(parent: HBoxContainer, text: String, min_size: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = min_size
	label.modulate = color
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)

func _add_button(parent: HBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(190, 42)
	button.pressed.connect(callback)
	parent.add_child(button)

func _clear_container(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _module_config(id: String) -> Dictionary:
	match id:
		"suit_control":
			return _suit_control_config()
		"airlock_procedure":
			return _airlock_config()
		"power_repair":
			return _power_config()
		"life_support":
			return _life_support_config()
		"plant_diagnosis":
			return _plant_config()
		"final_assessment":
			return _assessment_config()
	return _suit_control_config()

func _base_config() -> Dictionary:
	return {
		"state": {},
		"player_start": Vector2(62, 420),
		"hud": "氧气模拟值：98%\n电力模拟值：稳定\n生命支持状态：训练环境\n提示信息：靠近目标后按 E。",
	}

func _suit_control_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "训练模块一：宇航服基础控制",
		"subtitle": "SUIT CONTROL",
		"next_module": "airlock_procedure",
		"next_scene": TrainingManagerScript.MODULE_02,
		"player_start": Vector2(420, 310),
		"player_size": Vector2(42, 54),
		"targets": [
			{"id": "marker", "label": "标记区域", "position": Vector2(150, 330), "color": Color("#244563")},
			{"id": "terminal", "label": "训练终端", "position": Vector2(440, 180), "color": Color("#31536f")},
			{"id": "exit", "label": "训练出口", "position": Vector2(690, 390), "color": Color("#274f43")},
		],
		"steps": [
			{"type": "move", "target": "marker", "objective": "移动至标记区域", "line": "请移动至标记区域。"},
			{"type": "interact", "target": "terminal", "objective": "与训练终端交互", "line": "请与训练终端交互。"},
			{"type": "interact", "target": "terminal", "objective": "查看宇航服状态", "line": "正在读取宇航服状态。\n状态稳定。"},
			{"type": "interact", "target": "exit", "objective": "返回训练出口", "line": "模块完成。"},
		],
	})
	return data

func _airlock_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "训练模块二：气闸流程",
		"subtitle": "AIRLOCK PROCEDURE",
		"next_module": "power_repair",
		"next_scene": TrainingManagerScript.MODULE_03,
		"player_start": Vector2(112, 310),
		"player_size": Vector2(42, 54),
		"targets": [
			{"id": "chamber", "label": "气闸室", "position": Vector2(210, 250), "color": Color("#223d52")},
			{"id": "inner_door", "label": "内舱门", "position": Vector2(80, 250), "color": Color("#3d4e62")},
			{"id": "console", "label": "舱压控制台", "position": Vector2(410, 150), "color": Color("#31536f")},
			{"id": "pressure_display", "label": "舱压状态", "position": Vector2(500, 100), "color": Color("#244563")},
			{"id": "outer_door", "label": "外舱门", "position": Vector2(610, 250), "color": Color("#3d4e62")},
			{"id": "exterior", "label": "外部模拟区", "position": Vector2(560, 240), "color": Color("#244563")},
			{"id": "exit", "label": "训练出口", "position": Vector2(710, 410), "color": Color("#4d6473")},
		],
		"steps": [
			{"type": "move", "target": "chamber", "objective": "进入气闸室", "line": "进入气闸室。", "state_key": "PlayerInsideAirlock"},
			{"type": "interact", "target": "inner_door", "objective": "关闭内舱门", "line": "内舱门已关闭。", "state_key": "InnerDoorClosed"},
			{"type": "interact", "target": "console", "objective": "启动舱压模拟", "line": "舱压模拟开始。", "state_key": "PressureSimulationStarted", "requires": {"InnerDoorClosed": true}},
			{"type": "wait", "target": "pressure_display", "objective": "等待舱压稳定", "line": "舱压稳定。\n外舱门已解锁。", "duration": 1.6, "state_updates": {"PressureStable": true, "OuterDoorUnlocked": true}},
			{"type": "interact", "target": "outer_door", "objective": "打开外舱门", "line": "外舱门已打开。", "state_key": "OuterDoorOpen", "requires": {"InnerDoorClosed": true, "PressureStable": true}, "blocked_hint": "舱压尚未稳定。外舱门保持锁定。"},
			{"type": "move", "target": "exterior", "objective": "进入外部模拟区", "line": "气闸流程完成。", "state_key": "Module02Completed"},
		],
	})
	return data

func _power_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "训练模块三：供电维修",
		"subtitle": "POWER REPAIR",
		"next_module": "life_support",
		"next_scene": TrainingManagerScript.MODULE_04,
		"player_start": Vector2(372, 396),
		"player_size": Vector2(42, 54),
		"hud": "氧气模拟值：97%\n电力模拟值：下降\n生命支持状态：待供电恢复\n提示信息：先取得工具。",
		"targets": [
			{"id": "tools", "label": "工具台", "position": Vector2(110, 350), "color": Color("#4b4f37")},
			{"id": "panel", "label": "故障供电面板", "position": Vector2(390, 170), "color": Color("#5b3c3c")},
			{"id": "console", "label": "供电控制台", "position": Vector2(620, 220), "color": Color("#31536f")},
			{"id": "light", "label": "测试灯", "position": Vector2(660, 410), "color": Color("#413f31")},
			{"id": "exit", "label": "训练出口", "position": Vector2(710, 410), "color": Color("#4d6473")},
		],
		"steps": [
			{"type": "interact", "target": "tools", "objective": "获取维修工具", "line": "维修工具已取用。", "state_updates": {"Module03Started": true, "HasRepairTool": true}},
			{"type": "interact", "target": "panel", "objective": "检查供电面板", "line": "检测到供电面板故障。\n主供电回路未闭合。", "state_key": "PowerPanelInspected", "requires": {"HasRepairTool": true}, "blocked_hint": "未检测到维修工具。请先前往工具台。"},
			{"type": "interact", "target": "panel", "objective": "维修供电面板", "line": "维修中……\n供电面板维修完成。", "state_key": "PowerPanelRepaired", "requires": {"HasRepairTool": true, "PowerPanelInspected": true}, "blocked_hint": "请先检查故障供电面板。"},
			{"type": "interact", "target": "console", "objective": "重启供电", "line": "供电重启中……\n供电恢复。", "state_key": "PowerRestored", "requires": {"PowerPanelRepaired": true}, "blocked_hint": "供电面板尚未修复。无法重启供电。"},
			{"type": "wait", "target": "light", "objective": "确认灯光恢复", "line": "测试灯已亮起。\n训练舱供电状态：稳定。", "duration": 1.2, "state_key": "TestLightOn", "requires": {"PowerRestored": true}},
			{"type": "interact", "target": "exit", "objective": "进入下一训练模块", "line": "供电维修训练完成。", "state_key": "Module03Completed", "requires": {"TestLightOn": true}, "blocked_hint": "训练模块尚未完成。"},
		],
	})
	return data

func _life_support_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "训练模块四：生命支持系统",
		"subtitle": "LIFE SUPPORT",
		"next_module": "plant_diagnosis",
		"next_scene": TrainingManagerScript.MODULE_05,
		"player_start": Vector2(364, 396),
		"player_size": Vector2(42, 54),
		"hud": "氧气模拟值：偏低\n水循环状态：稳定\n电力模拟值：稳定\n温度模拟值：偏低\n生命支持状态：未稳定",
		"targets": [
			{"id": "console", "label": "生命支持控制台", "position": Vector2(340, 180), "color": Color("#31536f")},
			{"id": "power", "label": "电力显示", "position": Vector2(560, 260), "color": Color("#244563")},
			{"id": "oxygen", "label": "氧气状态", "position": Vector2(130, 130), "color": Color("#244563")},
			{"id": "water", "label": "水循环状态", "position": Vector2(130, 260), "color": Color("#244563")},
			{"id": "temperature", "label": "温度状态", "position": Vector2(560, 130), "color": Color("#244563")},
			{"id": "core", "label": "生命支持核心", "position": Vector2(620, 260), "color": Color("#31536f")},
			{"id": "vent", "label": "通风单元", "position": Vector2(560, 380), "color": Color("#31536f")},
			{"id": "exit", "label": "训练出口", "position": Vector2(710, 410), "color": Color("#4d6473")},
		],
		"steps": [
			{"type": "interact", "target": "console", "objective": "打开生命支持控制台", "line": "生命支持控制台已打开。", "state_updates": {"Module04Started": true, "LifeSupportConsoleOpened": true}},
			{"type": "interact", "target": "oxygen", "objective": "读取生命支持状态", "line": "检测到氧气偏低。\n检测到温度偏低。\n电力与水循环状态稳定。", "state_updates": {"LifeSupportStatusRead": true, "OxygenStatus": "偏低", "WaterStatus": "稳定", "PowerStatus": "稳定", "TemperatureStatus": "偏低", "LifeSupportStatus": "未稳定"}, "requires": {"LifeSupportConsoleOpened": true}, "blocked_hint": "请先打开生命支持控制台。"},
			{"type": "interact", "target": "console", "objective": "启动稳定程序", "line": "稳定程序启动。\n正在调整氧气输出与温控系统。", "state_updates": {"StabilizationStarted": true, "LifeSupportStatus": "稳定中"}, "requires": {"LifeSupportStatusRead": true}, "blocked_hint": "请先读取当前生命支持状态。"},
			{"type": "wait", "target": "core", "objective": "等待系统稳定", "line": "生命支持状态：稳定。", "duration": 1.6, "state_updates": {"LifeSupportStable": true, "OxygenStatus": "稳定", "WaterStatus": "稳定", "PowerStatus": "稳定", "TemperatureStatus": "稳定", "LifeSupportStatus": "稳定"}},
			{"type": "interact", "target": "vent", "objective": "确认生命支持稳定", "line": "氧气、水、电力与温度均已稳定。\n训练环境具备基础生命支持条件。", "state_key": "LifeSupportConfirmed", "requires": {"LifeSupportStable": true}},
			{"type": "interact", "target": "exit", "objective": "进入下一训练模块", "line": "生命支持训练完成。", "state_key": "Module04Completed", "requires": {"LifeSupportConfirmed": true}, "blocked_hint": "生命支持状态尚未稳定。训练模块未完成。"},
		],
	})
	return data

func _plant_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "训练模块五：植物状态诊断",
		"subtitle": "PLANT DIAGNOSIS",
		"next_module": "final_assessment",
		"next_scene": TrainingManagerScript.FINAL_ASSESSMENT,
		"player_start": Vector2(360, 402),
		"player_size": Vector2(42, 54),
		"hud": "氧气模拟值：98%\n电力模拟值：稳定\n生命支持状态：稳定\n植物状态：异常\n提示信息：观察，再诊断。",
		"targets": [
			{"id": "plant", "label": "训练植物", "position": Vector2(350, 260), "color": Color("#2d5b3f")},
			{"id": "scanner", "label": "植物扫描器", "position": Vector2(160, 350), "color": Color("#31536f")},
			{"id": "light_console", "label": "补光控制台", "position": Vector2(620, 260), "color": Color("#31536f")},
			{"id": "grow_light", "label": "生长灯", "position": Vector2(570, 130), "color": Color("#4b4f37")},
			{"id": "plant_status", "label": "植物状态显示", "position": Vector2(560, 150), "color": Color("#244563")},
			{"id": "exit", "label": "训练出口", "position": Vector2(710, 410), "color": Color("#4d6473")},
		],
		"steps": [
			{"type": "interact", "target": "plant", "objective": "观察训练植物", "line": "叶片颜色偏浅。\n植株姿态轻微下垂。\n\n植物不会主动报警。\n你需要先观察。", "state_updates": {"Module05Started": true, "PlantObserved": true, "PlantStatus": "异常"}},
			{"type": "interact", "target": "scanner", "objective": "使用植物扫描器", "line": "扫描完成。\n叶绿素反应偏低。\n根区温度正常。\n水分状态正常。", "state_updates": {"PlantScanned": true, "ScannerResult": "叶绿素反应偏低；根区温度正常；水分状态正常"}, "requires": {"PlantObserved": true}, "blocked_hint": "请先靠近植物舱进行观察。"},
			{"type": "diagnosis", "objective": "选择诊断结果", "line": "诊断确认：光照不足。", "options": ["缺水", "光照不足", "根区温度异常"], "correct": "光照不足", "wrong_hint": "诊断结果不匹配。\n请重新查看扫描信息。", "state_updates": {"DiagnosisSelected": true, "CorrectDiagnosis": "LightInsufficient"}, "requires": {"PlantScanned": true}, "blocked_hint": "诊断信息不足。请先使用植物扫描器。"},
			{"type": "interact", "target": "light_console", "objective": "调整补光方案", "line": "补光方案已调整。\n植物状态正在恢复。", "state_updates": {"GrowLightAdjusted": true, "PlantStatus": "稳定中", "GrowLightStatus": "正常"}, "requires": {"DiagnosisSelected": true}, "blocked_hint": "请先确认植物异常原因。"},
			{"type": "wait", "target": "plant_status", "objective": "确认植物状态稳定", "line": "植物状态趋于稳定。\n叶片反应：恢复中。\n补光输出：正常。", "duration": 1.5, "state_updates": {"PlantStable": true, "PlantStatus": "稳定"}},
			{"type": "interact", "target": "exit", "objective": "进入最终考核", "line": "植物状态诊断训练完成。", "state_key": "Module05Completed", "requires": {"PlantStable": true}, "blocked_hint": "训练模块尚未完成。"},
		],
	})
	return data

func _assessment_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "最终考核：综合模拟事故",
		"subtitle": "FINAL ASSESSMENT",
		"next_module": "mission_assignment",
		"next_scene": TrainingManagerScript.MISSION_NOTICE,
		"next_button": "查看任务派遣通知",
		"player_start": Vector2(382, 430),
		"player_size": Vector2(42, 54),
		"hud": "供电状态：故障\n生命支持状态：未稳定\n植物舱状态：异常\n提示信息：读取考核终端。",
		"targets": [
			{"id": "terminal", "label": "考核终端"},
			{"id": "tools", "label": "工具台"},
			{"id": "panel", "label": "故障供电面板"},
			{"id": "power_console", "label": "供电控制台"},
			{"id": "test_light", "label": "测试灯"},
			{"id": "life_console", "label": "生命支持控制台"},
			{"id": "oxygen", "label": "氧气状态"},
			{"id": "water", "label": "水循环"},
			{"id": "power_display", "label": "电力状态"},
			{"id": "temperature", "label": "温度状态"},
			{"id": "life_core", "label": "生命支持核心"},
			{"id": "plant", "label": "植物舱"},
			{"id": "scanner", "label": "植物扫描器"},
			{"id": "light_console", "label": "补光控制台"},
			{"id": "grow_light", "label": "补光灯"},
			{"id": "plant_status", "label": "植物状态"},
		],
		"steps": [
			{"type": "interact", "target": "terminal", "objective": "读取考核终端", "line": "最终考核开始。\n\n模拟事故：\n供电下降。\n生命支持不稳定。\n植物舱状态异常。\n\n考核目标：\n恢复供电。\n稳定生命支持。\n处理植物舱异常。\n提交考核结果。", "state_updates": {"FinalAssessmentStarted": true, "AssessmentBriefingRead": true, "PowerStatus": "故障", "LifeSupportStatus": "未稳定", "PlantStatus": "异常", "OxygenStatus": "偏低", "WaterStatus": "稳定", "TemperatureStatus": "偏低", "TestLightOn": false, "GrowLightStatus": "偏低"}},
			{"type": "interact", "target": "tools", "objective": "获取维修工具", "line": "维修工具已取用。", "state_key": "HasRepairTool"},
			{"type": "interact", "target": "panel", "objective": "检查故障供电面板", "line": "检测到主供电回路未闭合。\n生命支持系统供电不足。", "state_key": "PowerPanelInspected", "requires": {"HasRepairTool": true}, "blocked_hint": "未检测到维修工具。请先前往工具台。"},
			{"type": "interact", "target": "panel", "objective": "维修供电面板", "line": "维修中……\n供电面板维修完成。", "state_updates": {"PowerPanelRepaired": true, "PowerStatus": "待重启"}, "requires": {"HasRepairTool": true, "PowerPanelInspected": true}, "blocked_hint": "请先检查故障供电面板。"},
			{"type": "interact", "target": "power_console", "objective": "重启供电", "line": "供电恢复。\n生命支持系统可进入稳定流程。", "state_updates": {"PowerRestored": true, "PowerStatus": "稳定", "TestLightOn": true}, "requires": {"PowerPanelRepaired": true}, "blocked_hint": "供电面板尚未修复。无法重启供电。"},
			{"type": "interact", "target": "life_console", "objective": "打开生命支持控制台", "line": "检测到氧气偏低。\n检测到温度偏低。\n水循环与电力状态稳定。", "state_updates": {"LifeSupportConsoleOpened": true, "LifeSupportStatusRead": true, "LifeSupportStatus": "未稳定", "OxygenStatus": "偏低", "WaterStatus": "稳定", "TemperatureStatus": "偏低"}, "requires": {"PowerRestored": true}, "blocked_hint": "供电尚未恢复。生命支持系统无法进入稳定流程。"},
			{"type": "interact", "target": "life_console", "objective": "启动生命支持稳定程序", "line": "稳定程序启动。\n正在调整氧气输出与温控系统。", "state_updates": {"StabilizationStarted": true, "LifeSupportStatus": "稳定中"}, "requires": {"PowerRestored": true, "LifeSupportConsoleOpened": true}, "blocked_hint": "供电尚未恢复。生命支持系统无法进入稳定流程。"},
			{"type": "wait", "target": "life_core", "objective": "等待生命支持稳定", "line": "氧气状态：稳定。\n水循环状态：稳定。\n电力状态：稳定。\n温度状态：稳定。\n生命支持状态：稳定。", "duration": 1.4, "state_updates": {"LifeSupportStable": true, "LifeSupportStatus": "稳定", "OxygenStatus": "稳定", "WaterStatus": "稳定", "TemperatureStatus": "稳定"}},
			{"type": "interact", "target": "plant", "objective": "观察植物舱", "line": "叶片颜色偏浅。\n植株姿态轻微下垂。\n\n植物舱仍处于异常状态。\n请进行诊断。", "state_updates": {"PlantObserved": true, "PlantStatus": "异常"}, "requires": {"LifeSupportStable": true}, "blocked_hint": "生命支持状态尚未稳定。植物舱诊断结果可能不可靠。"},
			{"type": "interact", "target": "scanner", "objective": "扫描训练植物", "line": "扫描完成。\n叶绿素反应偏低。\n根区温度正常。\n水分状态正常。", "state_updates": {"PlantScanned": true, "ScannerResult": "叶绿素反应偏低；根区温度正常；水分状态正常"}, "requires": {"PlantObserved": true, "LifeSupportStable": true}, "blocked_hint": "生命支持状态尚未稳定。植物舱诊断结果可能不可靠。"},
			{"type": "diagnosis", "objective": "选择植物异常原因", "line": "诊断确认：光照不足。", "options": ["缺水", "光照不足", "根区温度异常"], "correct": "光照不足", "wrong_hint": "诊断结果不匹配。\n请重新查看扫描信息。", "state_updates": {"CorrectDiagnosis": "LightInsufficient", "DiagnosisSelected": true}, "requires": {"PlantScanned": true}},
			{"type": "interact", "target": "light_console", "objective": "调整补光方案", "line": "补光方案已调整。\n植物状态正在恢复。", "state_updates": {"GrowLightAdjusted": true, "GrowLightStatus": "稳定", "PlantStatus": "稳定中"}, "requires": {"CorrectDiagnosis": "LightInsufficient"}, "blocked_hint": "请先确认植物异常原因。"},
			{"type": "wait", "target": "plant_status", "objective": "等待植物状态稳定", "line": "植物状态：稳定。\n叶片反应：恢复中。\n补光输出：正常。", "duration": 1.4, "state_updates": {"PlantStable": true, "PlantStatus": "稳定"}},
			{"type": "interact", "target": "terminal", "objective": "提交考核结果", "line": "最终考核完成。\n\n供电恢复。\n生命支持稳定。\n植物舱状态稳定。\n\n候选人具备进入月面长期驻留任务后续阶段的基础资格。", "state_key": "FinalAssessmentCompleted", "requires": {"PowerRestored": true, "LifeSupportStable": true, "PlantStable": true}, "blocked_hint": "考核结果不完整。请确认供电、生命支持与植物舱状态。"},
		],
	})
	return data

