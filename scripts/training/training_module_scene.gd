extends Control

const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")
const PlayerControllerScript := preload("res://scripts/controllers/player_controller_2d.gd")
const InteractionAreaScript := preload("res://scripts/controllers/interaction_area_2d.gd")
const FaultDatabaseScript := preload("res://scripts/data/FaultDatabase.gd")

const TRAINING_03_CONTAINER_ID := "training_03_parts"

# Maps TrainingTargetVisual.kind -> a reusable res://scenes/props/... scene
# (reference_prop.gd based). Kinds without an entry keep drawing procedurally
# via TrainingTargetVisual's own _draw() match, unchanged (HUD-like readouts
# and nav triggers: marker, zone, status_display, life_status, life_core,
# plant_scanner, plant_status -- the last two are already unreachable dead
# kinds since no module config produces them anymore).
const KIND_PROP_SCENES := {
	"tool_station": "res://scenes/props/training/ToolStation.tscn",
	"power_panel": "res://scenes/props/training/TrainingPowerPanel.tscn",
	"power_console": "res://scenes/props/old_base/PowerRestartConsole.tscn",
	"test_light": "res://scenes/props/training/TestLight.tscn",
	"terminal": "res://scenes/props/old_base/CentralConsole.tscn",
	"pressure_console": "res://scenes/props/old_base/CentralConsole.tscn",
	"plant_console": "res://scenes/props/old_base/CentralConsole.tscn",
	"assessment_terminal": "res://scenes/props/old_base/CentralConsole.tscn",
	"door": "res://scenes/props/training/TrainingDoor.tscn",
	"life_console": "res://scenes/props/old_base/LifeSupportConsole.tscn",
	"plant_chamber": "res://scenes/props/greenhouse/CentralPlantChamber.tscn",
	"grow_light": "res://scenes/props/greenhouse/GrowLight.tscn",
	"ventilation": "res://scenes/props/training/Ventilation.tscn",
	"exit": "res://scenes/props/training/TrainingExitDoor.tscn",
}

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
		var power_zone := Rect2(Vector2(92, 108), Vector2(250, 250))
		var life_zone := Rect2(Vector2(size.x * 0.5 - 170, 92), Vector2(340, 284))
		var plant_zone := Rect2(Vector2(size.x - 430, 118), Vector2(300, 260))
		var terminal_zone := Rect2(Vector2(size.x * 0.5 - 160, size.y - 182), Vector2(320, 104))
		_draw_route(power_zone.end - Vector2(0, 125), life_zone.position + Vector2(0, 138))
		_draw_route(life_zone.end - Vector2(0, 138), plant_zone.position + Vector2(0, 130))
		_draw_route(plant_zone.position + Vector2(150, plant_zone.size.y), terminal_zone.position + Vector2(terminal_zone.size.x, 52))
		_draw_route(terminal_zone.position + Vector2(0, 52), power_zone.position + Vector2(power_zone.size.x * 0.5, power_zone.size.y))
		if life_stable:
			draw_rect(life_zone.grow(-10), Color("#9fd7ff", 0.035), true)
		if plant_stable:
			draw_rect(plant_zone.grow(-10), Color("#7dbd75", 0.035), true)
		_draw_assessment_zone(power_zone, Color("#1c2833"), "1 供电区", power_zone.position + Vector2(18, 26))
		_draw_assessment_zone(life_zone, Color("#1a2b38"), "2 生命支持区", life_zone.position + Vector2(18, 26))
		_draw_assessment_zone(plant_zone, Color("#18262e"), "3 植物舱区", plant_zone.position + Vector2(18, 26))
		_draw_assessment_zone(terminal_zone, Color("#1d2832"), "4 考核终端区", terminal_zone.position + Vector2(20, 26))

	func _draw_assessment_zone(zone: Rect2, fill: Color, label: String, label_pos: Vector2) -> void:
		draw_rect(zone, fill, true)
		draw_rect(zone, Color("#5d6f7d", 0.45), false, 2.0)
		draw_string(ThemeDB.fallback_font, label_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#8fa3b2"))

	func _draw_route(from: Vector2, to: Vector2) -> void:
		var delta := to - from
		var length := delta.length()
		if length <= 1.0:
			return
		var dir := delta / length
		var normal := Vector2(-dir.y, dir.x)
		var cursor := 0.0
		while cursor < length:
			var start: Vector2 = from + dir * cursor
			var end: Vector2 = from + dir * min(cursor + 12.0, length)
			draw_line(start, end, Color("#4fb7f0", 0.62), 2.0)
			cursor += 24.0
		var arrow_center := to - dir * 14.0
		draw_line(arrow_center + normal * 5.0, to, Color("#4fb7f0", 0.72), 2.0)
		draw_line(arrow_center - normal * 5.0, to, Color("#4fb7f0", 0.72), 2.0)

class TrainingTargetVisual:
	extends Control

	const LABEL_FONT_SIZE := 12

	var kind := "marker"
	var label_text := ""
	var active := false
	var highlighted := false
	var locked := false
	var show_trigger_debug := false
	var status_text := ""
	var prop_scene_path := ""
	var _prop_node: Node2D = null

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not prop_scene_path.is_empty():
			var packed := load(prop_scene_path) as PackedScene
			if packed != null:
				_prop_node = packed.instantiate()
				_prop_node.position = Vector2.ZERO
				_prop_node.set("prop_size", size)
				if not label_text.is_empty():
					_prop_node.set("prop_label", label_text)
				add_child(_prop_node)

	func _sync_prop_node() -> void:
		if _prop_node == null:
			return
		_prop_node.set("active", active)
		_prop_node.set("damaged", locked)
		_prop_node.set("status_text", status_text)
		_prop_node.queue_redraw()

	func _draw_highlight_ring() -> void:
		if not highlighted:
			return
		draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.12), true)
		draw_rect(Rect2(Vector2(-8, -8), size + Vector2(16, 16)), Color("#f0c766", 0.55), false, 2.0)

	func _draw() -> void:
		if _prop_node != null:
			_draw_highlight_ring()
			_draw_debug_label()
			return
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
			draw_rect(Rect2(Vector2(12, size.y * 0.5 - 14), Vector2(size.x - 24, 22)), Color("#0d1822", 0.72), true)
			draw_string(ThemeDB.fallback_font, Vector2(18, size.y * 0.5 + 4), "锁定", HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_FONT_SIZE, Color("#9fb2c0"))

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
		var font_size := LABEL_FONT_SIZE
		draw_string(font, Vector2(8, -6), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#d8e7f2"))
		if active and kind != "exit":
			draw_string(font, Vector2(8, size.y + 18), "E 交互", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#f0c766"))

class TraineeVisual:
	extends Control

	var pose := "idle"

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := size * 0.5
		var lean := Vector2(0, 3) if pose != "idle" else Vector2.ZERO
		draw_circle(center + Vector2(0, -12), 10, Color("#e6eef4"))
		draw_circle(center + Vector2(0, -12), 7, Color("#1b2834"))
		draw_rect(Rect2(center + Vector2(-9, -3) + lean, Vector2(18, 23)), Color("#d8e0e6"), true)
		draw_rect(Rect2(center + Vector2(-6, 3) + lean, Vector2(12, 8)), Color("#7fa7bd"), true)
		if pose == "repair":
			draw_line(center + Vector2(-11, 1), center + Vector2(-20, 11), Color("#d8e0e6"), 4.0)
			draw_line(center + Vector2(11, 1), center + Vector2(25, 8), Color("#d8e0e6"), 4.0)
			draw_rect(Rect2(center + Vector2(24, 5), Vector2(10, 4)), Color("#f0c766"), true)
		elif pose == "scan":
			draw_line(center + Vector2(-11, 1), center + Vector2(-17, 16), Color("#d8e0e6"), 4.0)
			draw_line(center + Vector2(11, 1), center + Vector2(24, 0), Color("#d8e0e6"), 4.0)
			draw_circle(center + Vector2(28, 0), 4, Color("#89d8ff"))
		else:
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
var diagnosis_modal_scrim: ColorRect
var diagnosis_modal: PanelContainer
var diagnosis_modal_image: TextureRect
var diagnosis_modal_title: Label
var diagnosis_modal_text: Label
var diagnosis_modal_actions: VBoxContainer
var suit_status_scrim: ColorRect
var suit_status_modal: PanelContainer
var suit_status_text_label: Label
var suit_status_panel_visible := false
var footer_buttons: HBoxContainer
var left_panel: PanelContainer
var minimal_hud: PanelContainer
var minimal_title_label: Label
var minimal_objective_label: Label
var minimal_time_label: Label
var briefing_scrim: ColorRect
var briefing_modal: PanelContainer
var pause_panel: PanelContainer
var interaction_panel: PanelContainer
var interaction_label: Label
var interaction_bar: ProgressBar
var target_nodes: Dictionary = {}
var prompt_label: Label
var completed := false
var show_trigger_debug := false
var mission_panel_visible := false
var briefing_visible := true
var pause_visible := false
var interaction_running := false
var interaction_target_id := ""
var wait_timer := 0.0
var player_speed := 280.0
var player_controller: RefCounted
## power_repair (太阳能阵列训练场) only: true when SuitManager reports the
## suit isn't worn on scene entry. Blocks movement/interaction and pins the
## briefing modal open with an error, instead of the normal briefing flow.
var entry_blocked := false

func _ready() -> void:
	_ensure_input_actions()
	_release_stale_movement_input()
	module_data = _module_config(module_id)
	TrainingManagerScript.set_current_module(module_id)
	_sync_completed_state_from_progress()
	if module_id == "power_repair" and not completed:
		var suit_manager := _suit_manager()
		entry_blocked = suit_manager == null or not bool(suit_manager.get("is_suit_worn"))
	_build_screen()
	_update_hud()
	if completed:
		briefing_visible = false
		if briefing_modal != null:
			briefing_modal.visible = false
	elif entry_blocked:
		_show_entry_blocked_dialog()
	elif module_id == "power_repair":
		_setup_training_03_container()
	_sync_overlay_visibility()

func _process(delta: float) -> void:
	if entry_blocked:
		return
	if briefing_visible or pause_visible or interaction_running:
		_update_room_prompt()
		return
	_move_player(delta)
	if not completed:
		_check_wait_step(delta)
		_check_auto_steps()
	_update_room_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if entry_blocked:
		return
	if event.is_action_pressed("mission_panel"):
		_toggle_mission_panel()
	if event.is_action_pressed("interact") and completed and not briefing_visible and not pause_visible and not interaction_running:
		_try_exit_after_completion()
	elif event.is_action_pressed("interact") and not completed and not briefing_visible and not pause_visible and not interaction_running:
		_try_interact()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		show_trigger_debug = not show_trigger_debug
		_update_trigger_debug()
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause_menu()

func _ensure_input_actions() -> void:
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var event := InputEventKey.new()
		event.physical_keycode = KEY_E
		InputMap.action_add_event("interact", event)
	var enter_event := InputEventKey.new()
	enter_event.physical_keycode = KEY_ENTER
	if not InputMap.action_has_event("interact", enter_event):
		InputMap.action_add_event("interact", enter_event)
	if not InputMap.has_action("mission_panel"):
		InputMap.add_action("mission_panel")
		var panel_event := InputEventKey.new()
		panel_event.physical_keycode = KEY_TAB
		InputMap.action_add_event("mission_panel", panel_event)

## Godot's input action state is global, not per-scene -- if the player
## reached this room by pressing Enter/an arrow key on a button in the
## previous screen (e.g. TrainingStartScene's "开始训练" button, or the
## previous training module's exit prompt), that key's "pressed" state can
## still read as true here for a frame or more after change_scene_to_file(),
## since there's no guaranteed "key released" event delivered across the
## scene swap. _move_player() reads ui_up/ui_down/ui_left/ui_right via
## Input.get_axis() every frame, so a stuck action reads as the player
## silently drifting in that direction with no way to counter it (pressing
## the opposite key competes against, but doesn't clear, the phantom
## held state). Clearing every action this room's movement/interaction
## code cares about on entry is a cheap, safe guard against that class of
## bug regardless of exactly which key carried over.
func _release_stale_movement_input() -> void:
	for action in ["ui_up", "ui_down", "ui_left", "ui_right", "interact", "mission_panel", "ui_cancel", "ui_accept"]:
		if InputMap.has_action(action):
			Input.action_release(action)

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

	left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(420, 0)
	left_panel.visible = false
	row.add_child(left_panel)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 12)
	left_panel.add_child(left)

	var title := Label.new()
	title.text = String(module_data.get("title", "训练模块"))
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 24)
	left.add_child(title)

	_add_panel_section_label(left, "当前目标")
	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.modulate = Color("#d8e7f2")
	objective_label.add_theme_font_size_override("font_size", 18)
	left.add_child(objective_label)

	_add_panel_section_label(left, "系统状态")
	hud_label = Label.new()
	hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_label.modulate = Color("#9fb4c4")
	hud_label.add_theme_font_size_override("font_size", 15)
	left.add_child(hud_label)

	_add_panel_section_label(left, "操作步骤")
	hint_label = Label.new()
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.modulate = Color("#86c7ff")
	hint_label.add_theme_font_size_override("font_size", 16)
	left.add_child(hint_label)

	diagnosis_panel = VBoxContainer.new()
	diagnosis_panel.visible = false
	diagnosis_panel.add_theme_constant_override("separation", 8)
	left.add_child(diagnosis_panel)

	_add_panel_section_label(left, "输入提示")
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
	_build_training_overlays()

	var footer := HBoxContainer.new()
	footer_buttons = footer
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.custom_minimum_size = Vector2(0, 48)
	footer.add_theme_constant_override("separation", 12)
	footer.visible = false
	root.add_child(footer)
	_add_button(footer, "保存训练进度", func(): TrainingManagerScript.set_current_module(module_id))
	_add_button(footer, "返回主菜单", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))

func _build_training_overlays() -> void:
	minimal_hud = PanelContainer.new()
	minimal_hud.position = Vector2(60, 84)
	minimal_hud.custom_minimum_size = Vector2(390, 118)
	add_child(minimal_hud)
	var hud_box := VBoxContainer.new()
	hud_box.add_theme_constant_override("separation", 6)
	minimal_hud.add_child(hud_box)
	minimal_title_label = Label.new()
	minimal_title_label.modulate = Color("#eaf4ff")
	minimal_title_label.add_theme_font_size_override("font_size", 17)
	hud_box.add_child(minimal_title_label)
	minimal_objective_label = Label.new()
	minimal_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	minimal_objective_label.modulate = Color("#f0c766")
	minimal_objective_label.add_theme_font_size_override("font_size", 15)
	hud_box.add_child(minimal_objective_label)
	minimal_time_label = Label.new()
	minimal_time_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	minimal_time_label.modulate = Color("#9fb4c4")
	minimal_time_label.add_theme_font_size_override("font_size", 13)
	hud_box.add_child(minimal_time_label)
	var key_hint := Label.new()
	key_hint.text = "Tab 查看任务    Esc 暂停"
	key_hint.modulate = Color("#7f93a3")
	key_hint.add_theme_font_size_override("font_size", 12)
	hud_box.add_child(key_hint)
	_build_briefing_modal()
	_build_pause_panel()
	_build_interaction_panel()
	_build_diagnosis_modal()
	_build_suit_status_panel()

func _build_diagnosis_modal() -> void:
	diagnosis_modal_scrim = ColorRect.new()
	diagnosis_modal_scrim.color = Color("#02070d", 0.78)
	diagnosis_modal_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	diagnosis_modal_scrim.visible = false
	add_child(diagnosis_modal_scrim)

	diagnosis_modal = PanelContainer.new()
	diagnosis_modal.set_anchors_preset(Control.PRESET_CENTER)
	diagnosis_modal.offset_left = -540
	diagnosis_modal.offset_top = -310
	diagnosis_modal.offset_right = 540
	diagnosis_modal.offset_bottom = 310
	diagnosis_modal.visible = false
	add_child(diagnosis_modal)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#06111a", 0.98)
	style.border_color = Color("#496c80", 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 22
	style.content_margin_top = 20
	style.content_margin_right = 22
	style.content_margin_bottom = 20
	diagnosis_modal.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	diagnosis_modal.add_child(row)
	diagnosis_modal_image = TextureRect.new()
	diagnosis_modal_image.custom_minimum_size = Vector2(500, 560)
	diagnosis_modal_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(diagnosis_modal_image)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(500, 0)
	# Fill any horizontal space the image column gives up when it's hidden
	# (confirm dialogs set no texture) -- otherwise the text sat in a
	# 500px band leaving a big empty left area (user-reported).
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 14)
	row.add_child(right)
	# Title is per-dialog now (was hardcoded to the plant-chamber text, which
	# leaked into the wear-suit/solar-array dialogs that share this modal --
	# user-reported). Each _show_* function sets it via _set_diagnosis_modal_title().
	diagnosis_modal_title = Label.new()
	diagnosis_modal_title.text = "植物舱诊断详情\nPLANT CHAMBER DIAGNOSTIC"
	diagnosis_modal_title.modulate = Color("#eaf4ff")
	diagnosis_modal_title.add_theme_font_size_override("font_size", 22)
	right.add_child(diagnosis_modal_title)
	diagnosis_modal_text = Label.new()
	diagnosis_modal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diagnosis_modal_text.modulate = Color("#cfe3f2")
	diagnosis_modal_text.add_theme_font_size_override("font_size", 16)
	right.add_child(diagnosis_modal_text)
	diagnosis_modal_actions = VBoxContainer.new()
	diagnosis_modal_actions.add_theme_constant_override("separation", 10)
	right.add_child(diagnosis_modal_actions)

## Tab (the "mission_panel" action) opens this instead of the normal
## left_panel mission overview while the current step is
## "suit_status_panel" -- see _toggle_mission_panel().
func _build_suit_status_panel() -> void:
	suit_status_scrim = ColorRect.new()
	suit_status_scrim.color = Color("#02070d", 0.78)
	suit_status_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	suit_status_scrim.visible = false
	add_child(suit_status_scrim)

	suit_status_modal = PanelContainer.new()
	suit_status_modal.set_anchors_preset(Control.PRESET_CENTER)
	suit_status_modal.offset_left = -260
	suit_status_modal.offset_top = -190
	suit_status_modal.offset_right = 260
	suit_status_modal.offset_bottom = 190
	suit_status_modal.visible = false
	add_child(suit_status_modal)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#170a1e", 0.97)
	style.border_color = Color("#8a5fa8", 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 22
	style.content_margin_top = 20
	style.content_margin_right = 22
	style.content_margin_bottom = 20
	suit_status_modal.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	suit_status_modal.add_child(box)
	var title := Label.new()
	title.text = "宇航服状态"
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	suit_status_text_label = Label.new()
	suit_status_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	suit_status_text_label.modulate = Color("#e8d9f5")
	suit_status_text_label.add_theme_font_size_override("font_size", 16)
	box.add_child(suit_status_text_label)
	var confirm := Button.new()
	confirm.text = "确认外勤状态" if module_id == "power_repair" else "确认状态"
	confirm.custom_minimum_size = Vector2(0, 42)
	confirm.pressed.connect(_on_confirm_suit_status_pressed)
	box.add_child(confirm)

func _toggle_suit_status_panel() -> void:
	suit_status_panel_visible = not suit_status_panel_visible
	if suit_status_panel_visible:
		_refresh_suit_status_panel()
	if suit_status_scrim != null:
		suit_status_scrim.visible = suit_status_panel_visible
	if suit_status_modal != null:
		suit_status_modal.visible = suit_status_panel_visible
	_sync_overlay_visibility()

func _refresh_suit_status_panel() -> void:
	if suit_status_text_label == null:
		return
	var suit_manager := _suit_manager()
	if suit_manager == null or not suit_manager.has_method("get_suit_status_for_ui"):
		suit_status_text_label.text = "宇航服数据不可用。"
		return
	var data: Dictionary = suit_manager.call("get_suit_status_for_ui")
	var text := "宇航服状态\n\n氧气储备：%.0f%%\n电力储备：%.0f%%\n移动倍率：%.2f" % [
		float(data.get("oxygen", 0.0)), float(data.get("power", 0.0)),
		float(data.get("speed_multiplier", 0.8)),
	]
	# Extra narrative context lines specific to the solar array EVA training
	# room -- kept as a module_id check here rather than a second copy of
	# this whole panel, since every other module just wants the plain
	# oxygen/power/seal/comm/speed readout.
	if module_id == "power_repair":
		text += "\n\n当前环境：真空模拟\n外勤任务：太阳能阵列维修"
	else:
		text += "\n\n初代宇航服会降低行动速度。后续升级可将移动倍率提升至 1.00。"
	suit_status_text_label.text = text

## Only completes the step if the confirm button is pressed while this
## step is genuinely current -- guards against a stray click after the
## panel should already be gone (e.g. double-click, or reopening it later).
func _on_confirm_suit_status_pressed() -> void:
	if String(_current_step().get("type", "")) != "suit_status_panel":
		return
	suit_status_panel_visible = false
	if suit_status_scrim != null:
		suit_status_scrim.visible = false
	if suit_status_modal != null:
		suit_status_modal.visible = false
	_complete_step()

func _suit_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("SuitManager")

func _repair_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("RepairManager")

func _training_inventory_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("InventoryManager")

func _build_briefing_modal() -> void:
	briefing_scrim = ColorRect.new()
	briefing_scrim.color = Color("#02070d", 0.78)
	briefing_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	briefing_scrim.visible = not completed
	add_child(briefing_scrim)

	briefing_modal = PanelContainer.new()
	briefing_modal.set_anchors_preset(Control.PRESET_CENTER)
	briefing_modal.offset_left = -310
	briefing_modal.offset_top = -190
	briefing_modal.offset_right = 310
	briefing_modal.offset_bottom = 190
	briefing_modal.visible = not completed
	add_child(briefing_modal)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	briefing_modal.add_child(box)
	var title := Label.new()
	title.text = String(module_data.get("title", "训练模块"))
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "训练入口简报"
	subtitle.modulate = Color("#86c7ff")
	subtitle.add_theme_font_size_override("font_size", 16)
	box.add_child(subtitle)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = Color("#c6d5df")
	body.add_theme_font_size_override("font_size", 16)
	body.text = "本模块将在模拟训练舱内记录你的操作顺序。\n\n靠近当前目标后，按 E / Enter 交互。\n按 Tab 可随时查看完整任务面板。"
	box.add_child(body)
	var button := Button.new()
	button.text = "确认，开始训练"
	button.custom_minimum_size = Vector2(0, 44)
	button.pressed.connect(func(): _close_briefing())
	box.add_child(button)
	briefing_visible = not completed

func _build_pause_panel() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.offset_left = -210
	pause_panel.offset_top = -150
	pause_panel.offset_right = 210
	pause_panel.offset_bottom = 150
	pause_panel.visible = false
	add_child(pause_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	pause_panel.add_child(box)
	var title := Label.new()
	title.text = "训练暂停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color("#eaf4ff")
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	var resume := Button.new()
	resume.text = "继续训练"
	resume.custom_minimum_size = Vector2(0, 42)
	resume.pressed.connect(func(): _set_pause_visible(false))
	box.add_child(resume)
	var tasks := Button.new()
	tasks.text = "查看任务"
	tasks.custom_minimum_size = Vector2(0, 42)
	tasks.pressed.connect(func():
		_set_pause_visible(false)
		_set_mission_panel_visible(true)
	)
	box.add_child(tasks)
	var main := Button.new()
	main.text = "返回主菜单"
	main.custom_minimum_size = Vector2(0, 42)
	main.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	box.add_child(main)

func _build_interaction_panel() -> void:
	interaction_panel = PanelContainer.new()
	interaction_panel.position = Vector2(520, 720)
	interaction_panel.custom_minimum_size = Vector2(560, 78)
	interaction_panel.visible = false
	add_child(interaction_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	interaction_panel.add_child(box)
	interaction_label = Label.new()
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.modulate = Color("#eaf4ff")
	interaction_label.add_theme_font_size_override("font_size", 16)
	box.add_child(interaction_label)
	interaction_bar = ProgressBar.new()
	interaction_bar.min_value = 0.0
	interaction_bar.max_value = 1.0
	interaction_bar.value = 0.0
	interaction_bar.show_percentage = false
	interaction_bar.custom_minimum_size = Vector2(0, 12)
	box.add_child(interaction_bar)

func _close_briefing() -> void:
	briefing_visible = false
	if briefing_modal != null:
		briefing_modal.visible = false
	_sync_overlay_visibility()

## Tab is bound to the "mission_panel" action for every module; while the
## current step is "suit_status_panel" it opens the suit status modal
## instead of the normal mission overview, per the spec's "按 Tab 查看
## 宇航服状态面板" instruction. Every other step/module keeps the original
## behavior unchanged.
func _toggle_mission_panel() -> void:
	if pause_visible:
		return
	if String(_current_step().get("type", "")) == "suit_status_panel":
		_toggle_suit_status_panel()
		return
	_set_mission_panel_visible(not mission_panel_visible)

func _set_mission_panel_visible(value: bool) -> void:
	mission_panel_visible = value
	if log_label != null:
		log_label.text = "Tab：关闭任务面板\nE / Enter：与当前目标交互\nEsc：暂停"
	_sync_overlay_visibility()

func _toggle_pause_menu() -> void:
	if briefing_visible:
		_close_briefing()
		return
	_set_pause_visible(not pause_visible)

func _set_pause_visible(value: bool) -> void:
	pause_visible = value
	if pause_panel != null:
		pause_panel.visible = value
	_sync_overlay_visibility()

func _sync_overlay_visibility() -> void:
	var diagnosis_panel_open := diagnosis_panel != null and diagnosis_panel.visible
	var diagnosis_open := diagnosis_panel_open or (diagnosis_modal != null and diagnosis_modal.visible)
	var suit_status_open := suit_status_modal != null and suit_status_modal.visible
	if briefing_scrim != null:
		briefing_scrim.visible = briefing_visible
	if briefing_modal != null:
		briefing_modal.visible = briefing_visible
	if left_panel != null:
		left_panel.visible = mission_panel_visible or diagnosis_panel_open
	if minimal_hud != null:
		minimal_hud.visible = not briefing_visible and not mission_panel_visible and not pause_visible and not diagnosis_open and not suit_status_open
	if prompt_label != null and (briefing_visible or mission_panel_visible or pause_visible or diagnosis_open or suit_status_open):
		prompt_label.visible = false

func _build_training_area() -> void:
	target_nodes.clear()
	var floor: Control
	if module_id == "suit_control":
		floor = TrainingRoomBlockout.new()
	elif module_id == "airlock_procedure":
		floor = AirlockRoomBlockout.new()
	elif module_id == "power_repair":
		floor = PowerRepairRoomBlockout.new()
	elif module_id == "power_distribution":
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
		elif module_id == "power_distribution":
			target = _power_distribution_room_target(target)
		elif module_id == "life_support":
			target = _life_support_room_target(target)
		elif module_id == "plant_diagnosis":
			target = _plant_room_target(target)
		elif module_id == "final_assessment":
			target = _assessment_room_target(target)
		var node: Control
		if module_id == "suit_control" or module_id == "airlock_procedure" or module_id == "power_repair" or module_id == "power_distribution" or module_id == "life_support" or module_id == "plant_diagnosis" or module_id == "final_assessment":
			var visual := TrainingTargetVisual.new()
			visual.kind = String(target.get("kind", target.get("id", "target")))
			visual.label_text = String(target.get("label", ""))
			visual.prop_scene_path = String(KIND_PROP_SCENES.get(visual.kind, ""))
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
		if module_id != "suit_control" and module_id != "airlock_procedure" and module_id != "power_repair" and module_id != "power_distribution" and module_id != "life_support" and module_id != "plant_diagnosis" and module_id != "final_assessment":
			var label := Label.new()
			label.text = String(target.get("label", node.name))
			label.position = Vector2(8, 8)
			label.modulate = Color("#eaf4ff")
			label.add_theme_font_size_override("font_size", 13)
			node.add_child(label)

	if module_id == "final_assessment" and not target_nodes.has("exit"):
		var exit_visual := TrainingTargetVisual.new()
		exit_visual.kind = "exit"
		exit_visual.label_text = "考核出口"
		exit_visual.name = "exit"
		exit_visual.position = Vector2(1350, 610)
		exit_visual.size = Vector2(74, 106)
		training_area.add_child(exit_visual)
		target_nodes["exit"] = exit_visual

	if module_id == "suit_control" or module_id == "airlock_procedure" or module_id == "power_repair" or module_id == "power_distribution" or module_id == "life_support" or module_id == "plant_diagnosis" or module_id == "final_assessment":
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
			# 太阳能阵列训练场 (power_repair): the way back is the airlock's
			# outer door, so it sits on the RIGHT edge, vertically centered --
			# mirroring the airlock room, whose outer door is on its left
			# wall (user-requested spatial correspondence). The player also
			# spawns beside it when arriving from the airlock (player_start
			# in _power_config()). This override was previously mis-applied
			# in _airlock_room_target(), which power_repair never routes
			# through -- that's why the exit kept showing mid-room as
			# "训练出口" despite the config saying otherwise.
			if module_id == "power_repair":
				room_target["label"] = "返回气闸外舱门"
				room_target["position"] = Vector2(1340, 320)
				room_target["size"] = Vector2(74, 128)
			else:
				room_target["label"] = "训练出口"
				room_target["position"] = Vector2(684, 388)
				room_target["size"] = Vector2(74, 106)
	return room_target

func _power_distribution_room_target(target: Dictionary) -> Dictionary:
	var room_target := _power_room_target(target)
	match String(target.get("id", "")):
		"panel":
			room_target["label"] = "储能接入面板"
		"console":
			room_target["label"] = "配电控制台"
		"light":
			room_target["label"] = "供电测试灯"
		"exit":
			room_target["label"] = "空气系统控制室入口"
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
		"light_console":
			room_target["kind"] = "plant_console"
			room_target["label"] = "植物控制台"
			room_target["position"] = Vector2(590, 248)
			room_target["size"] = Vector2(138, 94)
		"grow_light":
			room_target["kind"] = "grow_light"
			room_target["label"] = "补光灯"
			room_target["position"] = Vector2(338, 82)
			room_target["size"] = Vector2(134, 82)
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
			room_target["position"] = Vector2(640, 468)
			room_target["size"] = Vector2(190, 76)
		"tools":
			room_target["kind"] = "tool_station"
			room_target["label"] = "工具台"
			room_target["position"] = Vector2(125, 280)
			room_target["size"] = Vector2(130, 82)
		"panel":
			room_target["kind"] = "power_panel"
			room_target["label"] = "故障供电面板"
			room_target["position"] = Vector2(132, 176)
			room_target["size"] = Vector2(138, 92)
		"power_console":
			room_target["kind"] = "power_console"
			room_target["label"] = "供电控制台"
			room_target["position"] = Vector2(268, 282)
			room_target["size"] = Vector2(104, 78)
		"test_light":
			room_target["kind"] = "test_light"
			room_target["label"] = "测试灯"
			room_target["position"] = Vector2(278, 188)
			room_target["size"] = Vector2(48, 62)
		"life_console":
			room_target["kind"] = "life_console"
			room_target["label"] = "生命支持控制台"
			room_target["position"] = Vector2(624, 304)
			room_target["size"] = Vector2(132, 78)
		"oxygen":
			room_target["kind"] = "life_status"
			room_target["label"] = "氧气状态"
			room_target["position"] = Vector2(575, 144)
			room_target["size"] = Vector2(86, 60)
		"water":
			room_target["kind"] = "life_status"
			room_target["label"] = "水循环"
			room_target["position"] = Vector2(740, 144)
			room_target["size"] = Vector2(86, 60)
		"power_display":
			room_target["kind"] = "life_status"
			room_target["label"] = "电力状态"
			room_target["position"] = Vector2(575, 232)
			room_target["size"] = Vector2(86, 60)
		"temperature":
			room_target["kind"] = "life_status"
			room_target["label"] = "温度状态"
			room_target["position"] = Vector2(740, 232)
			room_target["size"] = Vector2(86, 60)
		"life_core":
			room_target["kind"] = "life_core"
			room_target["label"] = "生命支持核心"
			room_target["position"] = Vector2(820, 302)
			room_target["size"] = Vector2(58, 74)
		"plant":
			room_target["kind"] = "plant_chamber"
			room_target["label"] = "植物舱"
			room_target["position"] = Vector2(1110, 216)
			room_target["size"] = Vector2(112, 132)
		"light_console":
			room_target["kind"] = "plant_console"
			room_target["label"] = "植物控制台"
			room_target["position"] = Vector2(1240, 318)
			room_target["size"] = Vector2(94, 76)
		"grow_light":
			room_target["kind"] = "grow_light"
			room_target["label"] = "补光灯"
			room_target["position"] = Vector2(1110, 152)
			room_target["size"] = Vector2(112, 52)
		"exit":
			room_target["kind"] = "exit"
			room_target["label"] = "考核出口"
			room_target["position"] = Vector2(1350, 610)
			room_target["size"] = Vector2(74, 106)
	return room_target

func _move_player(delta: float) -> void:
	var use_wall_margin := module_id == "suit_control" or module_id == "power_repair" or module_id == "power_distribution" or module_id == "life_support" or module_id == "plant_diagnosis" or module_id == "final_assessment"
	var margin := 36.0 if use_wall_margin else 8.0
	var movement_bounds := Rect2(Vector2(margin, margin), training_area.size - Vector2(margin * 2.0, margin * 2.0))
	_ensure_player_controller(movement_bounds)
	player_controller.bounds = movement_bounds
	player_controller.size = player.size
	player_controller.speed = player_speed
	player_controller.set_time_manager(_time_manager())
	# Training rooms are always indoor and must advance TrainingTimeManager,
	# never the real TimeManager -- see TrainingTimeManager.gd for why.
	player_controller.set_movement_time_manager(_movement_time_manager())
	player_controller.terrain_type = "indoor"
	player_controller.movement_context = "training"
	player_controller.sync_position(player.position)
	var result: Dictionary = player_controller.move_with_actions(delta, "ui_left", "ui_right", "ui_up", "ui_down")
	player.position = result.get("position", player.position)
	if module_id == "airlock_procedure":
		var state: Dictionary = module_data.get("state", {})
		if bool(state.get("Module02Completed", false)) or completed:
			player.position.x = max(player.position.x, 540.0)
			player_controller.sync_position(player.position)

func _ensure_player_controller(movement_bounds: Rect2) -> void:
	if player_controller != null:
		return
	player_controller = PlayerControllerScript.new()
	player_controller.configure(player.position, player.size, player_speed, movement_bounds, false, _time_manager())

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
		hint_label.text = "请在诊断弹窗中选择诊断结果。"
		return
	if step_type == "suit_status_panel":
		hint_label.text = "请按 Tab 查看宇航服状态面板。"
		return
	if step_type == "solar_fault_diagnosis":
		hint_label.text = "请在维修方案面板中选择一个排查方向。"
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
	if step_type == "plant_control":
		_show_plant_control_options(step.get("options", []), String(step.get("correct", "")))
		return
	if step_type == "wear_suit_confirm":
		_show_wear_suit_confirm_dialog()
		return
	if step_type == "return_suit_confirm":
		_show_return_suit_confirm_dialog()
		return
	if step_type == "inspect_solar_array_confirm":
		_show_inspect_solar_array_confirm_dialog()
		return
	_begin_step_interaction_feedback(step)

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
	_advance_time_for_step(step)
	_add_log(String(step.get("line", "")))
	step_index += 1
	wait_timer = 0.0
	if String(step.get("type", "")) == "diagnosis" or String(step.get("type", "")) == "plant_control":
		if diagnosis_panel != null:
			diagnosis_panel.visible = false
		_hide_training_diagnosis_modal()
	if step_index >= (module_data.get("steps", []) as Array).size():
		_finish_module()
	else:
		_update_hud()

func _begin_step_interaction_feedback(step: Dictionary) -> void:
	if interaction_running:
		return
	interaction_running = true
	interaction_target_id = String(step.get("target", ""))
	if player != null:
		player.set("pose", _interaction_pose_for_step(step))
		player.queue_redraw()
	var duration := _interaction_duration_for_step(step)
	var start_text := _interaction_start_text(step)
	var done_text := _interaction_done_text(step)
	if interaction_panel != null:
		interaction_panel.visible = true
	if interaction_label != null:
		interaction_label.text = start_text
	if interaction_bar != null:
		interaction_bar.value = 0.0
	var elapsed := 0.0
	while elapsed < duration:
		await get_tree().process_frame
		var delta := get_process_delta_time()
		elapsed += delta
		if interaction_bar != null:
			interaction_bar.value = clamp(elapsed / duration, 0.0, 1.0)
		_update_room_prompt()
	if interaction_label != null:
		interaction_label.text = done_text
	if interaction_bar != null:
		interaction_bar.value = 1.0
	await get_tree().create_timer(0.25).timeout
	if interaction_panel != null:
		interaction_panel.visible = false
	interaction_target_id = ""
	interaction_running = false
	if player != null:
		player.set("pose", "idle")
		player.queue_redraw()
	_complete_step()

## Training runs on its own time budget (TrainingTimeManager), never the
## real TimeManager -- training happens on Earth before Day 01 06:40 and
## must not advance the official mission clock, day/night cycle, or base
## state. _action_minutes() below still reads TimeManager.action_minutes()
## as a duration constant table (read-only, no state mutation), which is
## fine; only the actual time advancement is redirected here.
func _advance_time_for_step(step: Dictionary) -> void:
	var manager := _training_time_manager()
	if manager == null or not manager.has_method("advance_training_time"):
		return
	var minutes := int(step.get("time_minutes", _default_time_minutes_for_step(step)))
	if minutes <= 0:
		return
	manager.call("advance_training_time", minutes, String(step.get("time_reason", _time_reason_for_step(step))))

func _default_time_minutes_for_step(step: Dictionary) -> int:
	var step_type := String(step.get("type", "interact"))
	var objective := String(step.get("objective", ""))
	if step_type == "move" or String(step.get("target", "")) == "exit":
		# Movement time is advanced by GuanghanPlayerController2D distance metering.
		return 0
	if step_type == "diagnosis":
		return _action_minutes("plant_diagnosis", 15)
	if step_type == "plant_control":
		return _action_minutes("repair_light", 30)
	if objective.contains("维修") or objective.contains("恢复") or objective.contains("重启") or objective.contains("启动"):
		return _action_minutes("repair_light", 30)
	if objective.contains("发送"):
		return _action_minutes("send_report", 15)
	if objective.contains("诊断") or objective.contains("扫描"):
		return _action_minutes("plant_diagnosis", 15)
	if objective.contains("检查") or objective.contains("读取") or objective.contains("确认"):
		return _action_minutes("organize_supplies", 30)
	return 0

func _time_reason_for_step(step: Dictionary) -> String:
	var step_type := String(step.get("type", "interact"))
	var objective := String(step.get("objective", ""))
	if step_type == "diagnosis":
		return "plant_diagnosis"
	if step_type == "plant_control":
		return "repair_light"
	if objective.contains("发送"):
		return "send_report"
	if objective.contains("维修") or objective.contains("恢复") or objective.contains("重启") or objective.contains("启动"):
		return "repair_light"
	if objective.contains("诊断") or objective.contains("扫描"):
		return "plant_diagnosis"
	if objective.contains("检查") or objective.contains("读取") or objective.contains("确认"):
		return "organize_supplies"
	return ""

func _action_minutes(action_name: String, fallback: int) -> int:
	var manager := _time_manager()
	if manager == null or not manager.has_method("action_minutes"):
		return fallback
	var value := int(manager.call("action_minutes", action_name))
	return value if value > 0 else fallback

func _time_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TimeManager")

func _training_time_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TrainingTimeManager")

func _movement_time_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("MovementTimeManager")

## Shows the training archive countdown, not the real lunar day/time --
## training happens before Day 01, so surfacing official mission time here
## would be misleading. Naming follows the spec: always "训练归档时限", never
## "教程倒计时"/"考试时间"/"Game Over 倒计时".
func _time_hud_text() -> String:
	var manager := _training_time_manager()
	if manager == null or not manager.has_method("get_remaining_time_text"):
		return ""
	return "训练归档时限：剩余 %s" % String(manager.call("get_remaining_time_text"))

func _health_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("HealthManager")

func _health_hud_text() -> String:
	var manager := _health_manager()
	if manager == null or not manager.has_method("compact_hud_text"):
		return ""
	return String(manager.call("compact_hud_text"))

func _resident_status_hud_text() -> String:
	var lines: Array[String] = []
	var time_text := _time_hud_text()
	var health_text := _health_hud_text()
	if not time_text.is_empty():
		lines.append(time_text)
	if not health_text.is_empty():
		lines.append(health_text)
	return "\n".join(lines)

func _minimal_resident_status_text() -> String:
	var lines: Array[String] = []
	var time_text := _time_hud_text()
	var health_text := _health_hud_text()
	if not time_text.is_empty():
		lines.append(time_text.replace("\n", " · "))
	if not health_text.is_empty():
		lines.append(health_text)
	return "\n".join(lines)

func _interaction_pose_for_step(step: Dictionary) -> String:
	var objective := String(step.get("objective", ""))
	if objective.contains("维修") or objective.contains("恢复") or objective.contains("重启") or objective.contains("启动"):
		return "repair"
	if objective.contains("检查") or objective.contains("诊断") or objective.contains("扫描") or objective.contains("读取"):
		return "scan"
	return "terminal"

func _interaction_duration_for_step(step: Dictionary) -> float:
	var target := String(step.get("target", ""))
	var objective := String(step.get("objective", ""))
	if target == "exit":
		return 0.65
	if objective.contains("维修") or objective.contains("恢复") or objective.contains("重启") or objective.contains("稳定") or objective.contains("启动"):
		return 1.7
	if objective.contains("检查") or objective.contains("读取") or objective.contains("诊断") or objective.contains("扫描") or objective.contains("确认"):
		return 1.15
	return 0.85

func _interaction_start_text(step: Dictionary) -> String:
	var target := String(step.get("target", ""))
	var objective := String(step.get("objective", ""))
	if target == "exit":
		return "正在确认训练出口状态……"
	if target.contains("door"):
		return "正在执行舱门流程……"
	if objective.contains("维修") or objective.contains("恢复") or objective.contains("重启") or objective.contains("启动"):
		return "正在执行手动恢复流程……"
	if objective.contains("诊断") or objective.contains("扫描"):
		return "正在读取传感器数据……"
	if objective.contains("发送"):
		return "正在建立对地通信链路……"
	return "正在读取终端数据……"

func _interaction_done_text(step: Dictionary) -> String:
	var target := String(step.get("target", ""))
	var objective := String(step.get("objective", ""))
	if target == "exit":
		return "出口已解锁。"
	if target.contains("door"):
		return "舱门状态已更新。"
	if objective.contains("维修") or objective.contains("恢复") or objective.contains("重启") or objective.contains("启动"):
		return "操作完成。"
	if objective.contains("诊断") or objective.contains("扫描"):
		return "诊断完成。"
	if objective.contains("发送"):
		return "报告已加入传输队列。"
	return "系统状态已同步。"

func _finish_module() -> void:
	completed = true
	var next_module := String(module_data.get("next_module", "mission_assignment"))
	TrainingManagerScript.mark_module_completed(module_id, next_module)
	if module_id == "power_repair":
		var inventory_manager := _training_inventory_manager()
		if inventory_manager != null and inventory_manager.has_method("clear_container"):
			inventory_manager.call("clear_container", TRAINING_03_CONTAINER_ID)
	if module_id == "final_assessment":
		# Training passed -- stop the archive countdown so it can't still
		# time out and fail an already-completed candidate.
		var training_time_manager := _training_time_manager()
		if training_time_manager != null and training_time_manager.has_method("stop_training_time"):
			training_time_manager.call("stop_training_time")
	hint_label.text = _completed_hint_text()
	_update_hud()

func _try_exit_after_completion() -> void:
	if not target_nodes.has("exit"):
		return
	if not _is_near("exit"):
		hint_label.text = _completed_hint_text()
		_update_hud()
		return
	get_tree().change_scene_to_file(String(module_data.get("next_scene", TrainingManagerScript.START_SCENE)))

func _completed_objective_text() -> String:
	if module_id == "final_assessment":
		return "前往考核出口"
	return "前往训练出口"

func _completed_hint_text() -> String:
	if module_id == "final_assessment":
		return "最终考核记录已完成。请前往出口查看任务派遣通知。"
	return "训练记录已完成。请前往训练出口，进入下一阶段。"

func _show_completed_next_action() -> void:
	if footer_buttons != null:
		_clear_container(footer_buttons)
		_add_button(footer_buttons, String(module_data.get("next_button", "进入下一阶段")), func():
			get_tree().change_scene_to_file(String(module_data.get("next_scene", TrainingManagerScript.START_SCENE)))
		)
		_add_button(footer_buttons, "返回主菜单", func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	if diagnosis_panel == null:
		return
	for child in diagnosis_panel.get_children():
		if child is Button and String(child.text) == String(module_data.get("next_button", "进入下一阶段")):
			return
	var button := Button.new()
	button.text = String(module_data.get("next_button", "进入下一阶段"))
	button.custom_minimum_size = Vector2(0, 42)
	button.pressed.connect(func():
		get_tree().change_scene_to_file(String(module_data.get("next_scene", TrainingManagerScript.START_SCENE)))
	)
	diagnosis_panel.visible = true
	diagnosis_panel.add_child(button)

func _sync_completed_state_from_progress() -> void:
	if module_id != "final_assessment":
		return
	var progress := TrainingManagerScript.load_progress()
	if not bool(progress.get("FinalAssessmentCompleted", false)):
		return
	completed = true
	step_index = (module_data.get("steps", []) as Array).size()
	var state: Dictionary = module_data.get("state", {})
	state["FinalAssessmentCompleted"] = true
	state["PowerRestored"] = true
	state["LifeSupportStable"] = true
	state["PlantStable"] = true
	state["PowerStatus"] = "稳定"
	state["LifeSupportStatus"] = "稳定"
	state["PlantStatus"] = "稳定"
	state["OxygenStatus"] = "稳定"
	state["WaterStatus"] = "稳定"
	state["TemperatureStatus"] = "稳定"
	state["TestLightOn"] = true
	state["GrowLightStatus"] = "稳定"

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
		if target_nodes.has("light_console") and _is_near("light_console") and not bool(state.get("DiagnosisSelected", false)):
			return "请先确认植物异常原因。"
		if target_nodes.has("exit") and _is_near("exit") and not bool(state.get("PlantStable", false)):
			return "训练模块尚未完成。"
	if module_id == "final_assessment":
		if target_nodes.has("life_console") and _is_near("life_console") and not bool(state.get("PowerRestored", false)):
			return "供电尚未恢复。生命支持系统无法进入稳定流程。"
		if target_nodes.has("plant") and _is_near("plant"):
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
	var player_center := InteractionAreaScript.center_point_from_top_left(player.position, player.size)
	var target_rect := Rect2(target.position, target.size)
	return InteractionAreaScript.is_point_near_rect(player_center, target_rect, 95.0)

func _is_inside_target_area(target_id: String) -> bool:
	if not target_nodes.has(target_id):
		return false
	var target: Control = target_nodes[target_id]
	var target_rect := Rect2(target.position, target.size)
	var player_feet := InteractionAreaScript.feet_point_from_top_left(player.position, player.size)
	return InteractionAreaScript.is_point_inside_rect(player_feet, target_rect)

func _update_trigger_debug() -> void:
	for node in target_nodes.values():
		if node is TrainingTargetVisual:
			node.show_trigger_debug = show_trigger_debug and node.kind == "marker"
			node.queue_redraw()

func _update_room_prompt() -> void:
	if prompt_label == null:
		return
	if briefing_visible or mission_panel_visible or pause_visible:
		for node in target_nodes.values():
			if node is TrainingTargetVisual:
				node.highlighted = false
				node.active = false
				node.locked = _target_locked(String(node.name), "")
				node.modulate = Color(0.62, 0.68, 0.74, 0.48)
				node.queue_redraw()
				node._sync_prop_node()
		prompt_label.visible = false
		return
	var step := _current_step()
	var target_id := "exit" if completed else (String(step.get("target", "")) if not step.is_empty() else "")
	for node in target_nodes.values():
		if node is TrainingTargetVisual:
			var node_is_interacting: bool = interaction_running and node.name == interaction_target_id
			node.highlighted = node.name == target_id or node_is_interacting
			node.active = node_is_interacting
			node.locked = _target_locked(String(node.name), target_id)
			node.modulate = Color(1, 1, 1, 1) if node.highlighted else Color(0.64, 0.70, 0.76, 0.56)
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
			node._sync_prop_node()
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
	if target_id.is_empty():
		prompt_label.visible = false
		return
	if not target_nodes.has(target_id):
		prompt_label.visible = false
		return
	var target: Control = target_nodes[target_id]
	var near := _is_near(target_id)
	var prompt_step_type := String(step.get("type", ""))
	if target is TrainingTargetVisual:
		target.active = interaction_running and target.name == interaction_target_id or near and (completed or prompt_step_type == "interact" or prompt_step_type == "plant_control" or prompt_step_type == "return_suit_confirm" or prompt_step_type == "wear_suit_confirm")
		target.queue_redraw()
		target._sync_prop_node()
	if near and (completed or prompt_step_type == "interact" or prompt_step_type == "plant_control" or prompt_step_type == "return_suit_confirm" or prompt_step_type == "wear_suit_confirm"):
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
		return bool(state.get("Module02Completed", false)) or completed or not bool(state.get("PressureStable", false))
	return false

func _interaction_prompt(target_id: String) -> String:
	if module_id == "power_distribution":
		match target_id:
			"panel":
				var state: Dictionary = module_data.get("state", {})
				if bool(state.get("PowerPanelInspected", false)):
					return "E 接入储能模块"
				return "E 查看供电异常"
			"console":
				return "E 重启配电系统"
			"light":
				return "E 确认供电状态"
			"exit":
				return "E 进入空气系统控制室"
	if target_id == "exit":
		if module_id == "final_assessment":
			return "E / Enter 查看任务派遣通知"
		return "E / Enter 进入下一阶段"
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
				return "E 返回气闸舱"
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
				return "E 查看植物状态"
			"light_console":
				return "E 使用植物控制台"
			"exit":
				return "E 进入最终考核"
	if module_id == "final_assessment":
		match target_id:
			"suit_rack":
				return "E 脱下宇航服并归位"
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
				return "E 查看植物状态"
			"light_console":
				return "E 使用植物控制台"
	if target_id == "terminal":
		return "E 使用训练终端"
	return "E 交互"

func _show_diagnosis_options(options: Array, correct: String) -> void:
	if diagnosis_panel != null:
		diagnosis_panel.visible = false
	if diagnosis_modal_scrim != null:
		diagnosis_modal_scrim.visible = true
	if diagnosis_modal != null:
		diagnosis_modal.visible = true
	_set_diagnosis_modal_image(_load_diagnosis_texture("res://assets/art/greenhouse/plant_states/light_low.png"))
	_set_diagnosis_modal_title("植物舱诊断详情\nPLANT CHAMBER DIAGNOSTIC")
	if diagnosis_modal_text != null:
		var professional_hint := _professional_hint_block("training_06_greenhouse_light_low")
		var base_text := "传感器读数\n补光输出：低于维持阈值\n水循环：最低运行\n根区温度：正常\n生命信号：弱\n\n植物状态\n叶片偏淡，植株向补光灯方向倾斜。\n新叶展开缓慢。\n\n原因分析\n补光输出不足，无法支撑最低光合维持。"
		diagnosis_modal_text.text = "%s\n\n%s\n\n请选择诊断结论。" % [base_text, professional_hint] if not professional_hint.is_empty() else "%s\n\n请选择诊断结论。" % base_text
	_clear_container(diagnosis_modal_actions)
	for option in options:
		var button := Button.new()
		button.text = String(option)
		button.custom_minimum_size = Vector2(0, 42)
		button.pressed.connect(func():
			if button.text == correct:
				_hide_training_diagnosis_modal()
				_complete_step()
			else:
				hint_label.text = String(_current_step().get("wrong_hint", "诊断结论不足。请重新核对观察信息。"))
		)
		diagnosis_modal_actions.add_child(button)
	var close := Button.new()
	close.text = "关闭弹窗"
	close.custom_minimum_size = Vector2(0, 42)
	close.pressed.connect(func():
		hint_label.text = "诊断视图已关闭。"
		_hide_training_diagnosis_modal()
	)
	diagnosis_modal_actions.add_child(close)
	_sync_overlay_visibility()

func _show_plant_control_options(options: Array, correct: String) -> void:
	if diagnosis_panel != null:
		diagnosis_panel.visible = false
	if diagnosis_modal_scrim != null:
		diagnosis_modal_scrim.visible = true
	if diagnosis_modal != null:
		diagnosis_modal.visible = true
	_set_diagnosis_modal_image(_load_diagnosis_texture("res://assets/art/greenhouse/plant_states/light_low.png"))
	_set_diagnosis_modal_title("植物控制台\nPLANT CONTROL")
	if diagnosis_modal_text != null:
		diagnosis_modal_text.text = "植物控制台\nPLANT CONTROL\n\n当前维护目标\n根据植物舱诊断结果选择一项维护动作。\n\n传感器摘要\n补光输出：低于维持阈值\n水循环：最低运行\n根区温度：正常\n生命信号：弱\n\n可用操作\n调节温度：用于根区温度异常。\n浇水：用于水分不足。\n补光：用于光照不足。\n\n请选择维护动作。"
	_clear_container(diagnosis_modal_actions)
	for option in options:
		var button := Button.new()
		button.text = String(option)
		button.custom_minimum_size = Vector2(0, 42)
		button.pressed.connect(func():
			if button.text == correct:
				_hide_training_diagnosis_modal()
				_complete_step()
			else:
				hint_label.text = String(_current_step().get("wrong_hint", "维护动作不匹配。请重新核对植物舱诊断结果。"))
		)
		diagnosis_modal_actions.add_child(button)
	var close := Button.new()
	close.text = "关闭弹窗"
	close.custom_minimum_size = Vector2(0, 42)
	close.pressed.connect(func():
		hint_label.text = "植物控制台已关闭。"
		_hide_training_diagnosis_modal()
	)
	diagnosis_modal_actions.add_child(close)
	_sync_overlay_visibility()

## Reuses the same diagnosis-modal infrastructure as _show_plant_control_options()
## for a plain two-button confirm dialog. wear_suit_training() itself advances
## TrainingTimeManager by 15 minutes (not the real TimeManager) and sets the
## shared SuitManager's worn state -- this step deliberately has no
## "time_minutes" of its own so _advance_time_for_step() (called
## unconditionally by _complete_step()) doesn't double-charge the 15 minutes.
func _show_wear_suit_confirm_dialog() -> void:
	if diagnosis_panel != null:
		diagnosis_panel.visible = false
	if diagnosis_modal_scrim != null:
		diagnosis_modal_scrim.visible = true
	if diagnosis_modal != null:
		diagnosis_modal.visible = true
	_set_diagnosis_modal_image(null)
	_set_diagnosis_modal_title("宇航服整备\nSUIT PREPARATION")
	if diagnosis_modal_text != null:
		diagnosis_modal_text.text = "穿戴宇航服\n\n穿戴将消耗训练时间 15 分钟。\n是否确认？"
	_clear_container(diagnosis_modal_actions)
	var confirm := Button.new()
	confirm.text = "确认穿戴"
	confirm.custom_minimum_size = Vector2(0, 42)
	confirm.pressed.connect(func():
		var suit_manager := _suit_manager()
		var success := false
		if suit_manager != null and suit_manager.has_method("wear_suit_training"):
			success = suit_manager.call("wear_suit_training")
		_hide_training_diagnosis_modal()
		if success:
			_complete_step()
		else:
			hint_label.text = "宇航服当前无法穿戴。"
	)
	diagnosis_modal_actions.add_child(confirm)
	var cancel := Button.new()
	cancel.text = "取消"
	cancel.custom_minimum_size = Vector2(0, 42)
	cancel.pressed.connect(func():
		hint_label.text = "已取消穿戴。"
		_hide_training_diagnosis_modal()
	)
	diagnosis_modal_actions.add_child(cancel)
	_sync_overlay_visibility()

## -- Training module 03 (太阳能阵列训练场) -- see FA-TR-SOLAR-001 in
## FaultDatabase.gd for the actual fault/option data this reads.

func _show_return_suit_confirm_dialog() -> void:
	if diagnosis_panel != null:
		diagnosis_panel.visible = false
	if diagnosis_modal_scrim != null:
		diagnosis_modal_scrim.visible = true
	if diagnosis_modal != null:
		diagnosis_modal.visible = true
	_set_diagnosis_modal_image(null)
	_set_diagnosis_modal_title("宇航服归位\nSUIT RETURN")
	if diagnosis_modal_text != null:
		diagnosis_modal_text.text = "宇航服归位\n\n脱下宇航服并放回维护位。\n维护系统将恢复宇航服氧气、电力与状态。\n\n训练模式下无需等待完整维护流程。\n是否确认？"
	_clear_container(diagnosis_modal_actions)
	var confirm := Button.new()
	confirm.text = "确认归位"
	confirm.custom_minimum_size = Vector2(0, 42)
	confirm.pressed.connect(func():
		var suit_manager := _suit_manager()
		var success := false
		if suit_manager != null and suit_manager.has_method("remove_suit_to_service_station_training"):
			success = suit_manager.call("remove_suit_to_service_station_training")
		_hide_training_diagnosis_modal()
		if success:
			_complete_step()
		else:
			hint_label.text = "宇航服当前无法归位。"
	)
	diagnosis_modal_actions.add_child(confirm)
	var cancel := Button.new()
	cancel.text = "取消"
	cancel.custom_minimum_size = Vector2(0, 42)
	cancel.pressed.connect(func():
		hint_label.text = "已取消宇航服归位。"
		_hide_training_diagnosis_modal()
	)
	diagnosis_modal_actions.add_child(cancel)
	_sync_overlay_visibility()

func _show_inspect_solar_array_confirm_dialog() -> void:
	if diagnosis_panel != null:
		diagnosis_panel.visible = false
	if diagnosis_modal_scrim != null:
		diagnosis_modal_scrim.visible = true
	if diagnosis_modal != null:
		diagnosis_modal.visible = true
	_set_diagnosis_modal_image(null)
	_set_diagnosis_modal_title("太阳能阵列检查\nSOLAR ARRAY INSPECTION")
	if diagnosis_modal_text != null:
		diagnosis_modal_text.text = "检查太阳能阵列\n\n预计耗时：15 分钟。\n训练时间将推进。\n宇航服氧气与电力将少量消耗。\n\n是否继续？"
	_clear_container(diagnosis_modal_actions)
	var confirm := Button.new()
	confirm.text = "确认检查"
	confirm.custom_minimum_size = Vector2(0, 42)
	confirm.pressed.connect(func():
		_hide_training_diagnosis_modal()
		_confirm_inspect_solar_array()
	)
	diagnosis_modal_actions.add_child(confirm)
	var cancel := Button.new()
	cancel.text = "取消"
	cancel.custom_minimum_size = Vector2(0, 42)
	cancel.pressed.connect(func():
		hint_label.text = "已取消检查。"
		_hide_training_diagnosis_modal()
	)
	diagnosis_modal_actions.add_child(cancel)
	_sync_overlay_visibility()

## Fixed costs per the design spec (15 min / -2 oxygen / -2 power / -2
## energy) -- hand-applied here rather than going through
## RepairManager.apply_repair_option() because this is a plain inspection
## step, not a repair-option choice; RepairManager's training path is
## reserved for the actual fault_id/option_id flow in
## _execute_solar_repair_option() below.
func _confirm_inspect_solar_array() -> void:
	var training_time_manager := _training_time_manager()
	if training_time_manager != null and training_time_manager.has_method("advance_training_time"):
		training_time_manager.call("advance_training_time", 15, "inspect_solar_array")
	var suit_manager := _suit_manager()
	if suit_manager != null and suit_manager.has_method("consume_suit_resource_fixed"):
		suit_manager.call("consume_suit_resource_fixed", 2.0, 2.0, "inspect_solar_array")
	var health_manager := _health_manager()
	if health_manager != null and health_manager.has_method("consume_energy"):
		health_manager.call("consume_energy", 2.0, "inspect_solar_array")
	_complete_step()

## Auto-shown by _update_hud() whenever the current step is
## "solar_fault_diagnosis" (same pattern as the existing "diagnosis" step
## type) -- rebuilt every time so the option buttons/feedback text always
## reflect the current training_03_parts container contents.
func _show_solar_fault_diagnosis() -> void:
	if diagnosis_panel != null:
		diagnosis_panel.visible = false
	if diagnosis_modal_scrim != null:
		diagnosis_modal_scrim.visible = true
	if diagnosis_modal != null:
		diagnosis_modal.visible = true
	_set_diagnosis_modal_image(null)
	_set_diagnosis_modal_title("太阳能阵列诊断\nSOLAR ARRAY DIAGNOSTIC")
	var fault: Dictionary = FaultDatabaseScript.get_fault("FA-TR-SOLAR-001")
	if diagnosis_modal_text != null:
		diagnosis_modal_text.text = _solar_fault_panel_text()
	_clear_container(diagnosis_modal_actions)
	for option in fault.get("repair_options", []):
		if not (option is Dictionary):
			continue
		var option_data: Dictionary = option
		var option_id := String(option_data.get("option_id", ""))
		var is_high_risk := String(option_data.get("option_type", "")) == "high_risk"
		var button := Button.new()
		button.text = "[%s]" % String(option_data.get("display_name", option_id))
		if is_high_risk:
			button.modulate = Color("#ff6b6b")
		button.custom_minimum_size = Vector2(0, 42)
		button.pressed.connect(func():
			if is_high_risk:
				_show_high_risk_repair_confirm(option_id)
			else:
				_execute_solar_repair_option(option_id)
		)
		diagnosis_modal_actions.add_child(button)
	_sync_overlay_visibility()

## The "强行切换满功率输入" option requires its own second confirmation
## (spec section 13) before actually executing -- reuses the same modal,
## replacing its buttons with confirm/cancel; canceling rebuilds the
## normal option list via _show_solar_fault_diagnosis().
func _show_high_risk_repair_confirm(option_id: String) -> void:
	_set_diagnosis_modal_title("高风险操作确认\nHIGH RISK CONFIRM")
	if diagnosis_modal_text != null:
		diagnosis_modal_text.text = "高风险操作\n\n当前故障原因未确认。\n强行切换满功率输入可能导致接口过载，并消耗额外训练资源。\n\n是否继续？"
	_clear_container(diagnosis_modal_actions)
	var confirm := Button.new()
	confirm.text = "确认执行"
	confirm.modulate = Color("#ff6b6b")
	confirm.custom_minimum_size = Vector2(0, 42)
	confirm.pressed.connect(func(): _execute_solar_repair_option(option_id))
	diagnosis_modal_actions.add_child(confirm)
	var cancel := Button.new()
	cancel.text = "取消"
	cancel.custom_minimum_size = Vector2(0, 42)
	cancel.pressed.connect(func(): _show_solar_fault_diagnosis())
	diagnosis_modal_actions.add_child(cancel)
	_sync_overlay_visibility()

## The one place that actually calls RepairManager.apply_repair_option()
## with context == "training" -- materials come from training_03_parts
## (never StorageManager), time goes to TrainingTimeManager (never the
## real TimeManager), and no real BaseStatusManager/AirSystemManager/
## WaterSystemManager/PowerSystemManager gets touched (the training path
## in RepairManager skips _apply_effects() entirely). Only completes the
## step (advancing past the diagnosis) when fault_fixed is true; wrong
## options update the message/hint in place and leave the panel open for
## another attempt, then check whether training_03_parts has run out of
## the one material the correct option needs.
func _execute_solar_repair_option(option_id: String) -> void:
	var repair_manager := _repair_manager()
	if repair_manager == null or not repair_manager.has_method("apply_repair_option"):
		hint_label.text = "维修系统不可用。"
		return
	var result: Dictionary = repair_manager.call("apply_repair_option", "FA-TR-SOLAR-001", option_id, {
		"context": "training",
		"container_id": TRAINING_03_CONTAINER_ID,
	})
	var message := String(result.get("message", ""))
	if bool(result.get("fault_fixed", false)):
		_hide_training_diagnosis_modal()
		_add_log(message)
		_complete_step()
		return
	if not bool(result.get("success", false)):
		hint_label.text = message
		return
	var new_hint := String(result.get("new_hint", ""))
	if diagnosis_modal_text != null:
		diagnosis_modal_text.text = "%s\n\n%s" % [message, _solar_fault_panel_text()] if new_hint.is_empty() else "%s\n\n%s\n\n%s" % [message, new_hint, _solar_fault_panel_text()]
	_add_log(message)
	_check_solar_parts_depleted()

## Section 18 of the spec: if the one material the correct option needs
## (通用备件/TR-MT-001) has run out and the fault still isn't fixed,
## training fails outright rather than leaving the player stuck with no
## way to ever complete the module.
func _check_solar_parts_depleted() -> void:
	var state: Dictionary = module_data.get("state", {})
	if bool(state.get("SolarArrayRepaired", false)):
		return
	var inventory_manager := _training_inventory_manager()
	if inventory_manager == null or not inventory_manager.has_method("has_item_in_container"):
		return
	if bool(inventory_manager.call("has_item_in_container", TRAINING_03_CONTAINER_ID, "TR-MT-001", 1)):
		return
	hint_label.text = "维修备件不足。\n太阳能阵列无法完成基础修复。"
	TrainingManagerScript.fail_training("training_03_parts_depleted")

func _solar_fault_panel_text() -> String:
	var lines: Array[String] = [
		"太阳能阵列 A：输出异常",
		"",
		"异常现象：",
		"- 阵列角度偏移",
		"- 输出功率低于预期",
		"- 主电缆接口有月尘堆积",
		"- 控制器未报告核心损坏",
	]
	var hint := _professional_hint_block("training_03_solar_array_fault")
	if not hint.is_empty():
		lines.append("")
		lines.append(hint)
	lines.append("")
	lines.append("请选择排查方向：")
	return "\n".join(lines)

## Compatibility fallback for old saves/branches. New training hints go through
## AcademicBackgroundManager and remain info-only: no time/material/stat changes.
func _solar_specialist_hint() -> String:
	match _academic_background():
		"机械工程":
			return "专业判断：\n控制器未出现核心损坏代码。\n输出波动更像接口接触不良。\n建议优先处理主电缆接口，而不是更换控制器。"
		"材料科学":
			return "专业判断：\n接口处月尘附着可能影响接触稳定。\n阵列表面未见明显结构裂纹。"
		"医学":
			return "专业判断：\n当前处于宇航服外勤状态。\n如果继续执行长时间操作，请注意氧气与精力消耗。"
		"植物科学":
			return "本模块无额外专业优势。"
	return ""

func _academic_background() -> String:
	var path := "user://saves/application_profile.json"
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return ""
	var data := parsed as Dictionary
	return String(data.get("EducationBackground", data.get("education_background", "")))

func _academic_background_manager() -> Node:
	return get_tree().root.get_node_or_null("AcademicBackgroundManager")

func _professional_hint(context_id: String) -> String:
	var manager := _academic_background_manager()
	if manager != null and manager.has_method("get_professional_hint"):
		var hint := String(manager.call("get_professional_hint", context_id))
		if not hint.is_empty():
			return hint
	if context_id == "training_03_solar_array_fault":
		return _solar_specialist_hint()
	return ""

func _professional_hint_block(context_id: String) -> String:
	var hint := _professional_hint(context_id)
	if hint.is_empty():
		return ""
	return "专业提示：\n%s" % hint

## Entry gate (spec: player must already be wearing the suit to enter the
## lunar-surface vacuum simulation). Pins the existing briefing modal open
## with an error and a single "返回主菜单" button instead of the normal
## "确认，开始训练" flow; _process()/_unhandled_input() bail out early
## while entry_blocked is true, so no movement/interaction is possible.
func _show_entry_blocked_dialog() -> void:
	briefing_visible = true
	if briefing_scrim != null:
		briefing_scrim.visible = true
	if briefing_modal == null:
		return
	briefing_modal.visible = true
	_clear_container(briefing_modal)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	briefing_modal.add_child(box)
	var title := Label.new()
	title.text = "无法进入训练"
	title.modulate = Color("#ff6b6b")
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = Color("#c6d5df")
	body.add_theme_font_size_override("font_size", 16)
	body.text = "未检测到宇航服穿戴状态。无法进入月面真空模拟环境。\n\n请先完成宇航服穿戴，再进入本训练模块。"
	box.add_child(body)
	var button := Button.new()
	button.text = "返回主菜单"
	button.custom_minimum_size = Vector2(0, 44)
	button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	box.add_child(button)

## Training-only container, kept entirely separate from the real inventory/
## StorageManager (per spec) -- reset every time the module is (re)entered
## so retrying after a failure always starts with the full starting stock.
func _setup_training_03_container() -> void:
	var inventory_manager := _training_inventory_manager()
	if inventory_manager == null:
		return
	if inventory_manager.has_method("create_container"):
		inventory_manager.call("create_container", TRAINING_03_CONTAINER_ID)
	if inventory_manager.has_method("clear_container"):
		inventory_manager.call("clear_container", TRAINING_03_CONTAINER_ID)
	if inventory_manager.has_method("add_item_to_container"):
		inventory_manager.call("add_item_to_container", TRAINING_03_CONTAINER_ID, "TR-MT-001", 2)
		inventory_manager.call("add_item_to_container", TRAINING_03_CONTAINER_ID, "TR-MT-002", 1)

func _set_diagnosis_modal_title(text: String) -> void:
	if diagnosis_modal_title != null:
		diagnosis_modal_title.text = text

## Sets the modal image AND hides the whole image column when there's no
## texture, so confirm dialogs (which pass null) collapse the left half
## instead of showing a big empty band (user-reported). A hidden child in
## the HBoxContainer reserves no space, so the text column fills. The modal
## also shrinks to a text-only width in that case, so the buttons don't
## stretch across the full image+text width.
func _set_diagnosis_modal_image(texture: Texture2D) -> void:
	if diagnosis_modal_image == null:
		return
	diagnosis_modal_image.texture = texture
	diagnosis_modal_image.visible = texture != null
	if diagnosis_modal != null:
		var half_width := 540.0 if texture != null else 300.0
		diagnosis_modal.offset_left = -half_width
		diagnosis_modal.offset_right = half_width

func _hide_training_diagnosis_modal() -> void:
	if diagnosis_modal_scrim != null:
		diagnosis_modal_scrim.visible = false
	if diagnosis_modal != null:
		diagnosis_modal.visible = false
	_sync_overlay_visibility()

func _load_diagnosis_texture(path: String) -> Texture2D:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null:
		return null
	return ImageTexture.create_from_image(image)

func _update_hud() -> void:
	var step := _current_step()
	var objective := String(step.get("objective", "训练流程已完成。")) if not completed else "训练流程已完成。"
	objective_label.text = "当前目标：%s" % objective
	if completed:
		objective = _completed_objective_text()
		objective_label.text = "当前目标：%s" % objective
	if minimal_title_label != null:
		minimal_title_label.text = String(module_data.get("title", "训练模块"))
	if minimal_objective_label != null:
		minimal_objective_label.text = "当前目标：%s" % objective
	if minimal_time_label != null:
		minimal_time_label.text = _minimal_resident_status_text()
	if module_id == "airlock_procedure":
		hud_label.text = _airlock_hud_text()
	elif module_id == "power_repair":
		hud_label.text = _power_hud_text()
	elif module_id == "power_distribution":
		hud_label.text = _power_distribution_hud_text()
	elif module_id == "life_support":
		hud_label.text = _life_support_hud_text()
	elif module_id == "plant_diagnosis":
		hud_label.text = _plant_hud_text()
	elif module_id == "final_assessment":
		hud_label.text = _assessment_hud_text()
	else:
		hud_label.text = String(module_data.get("hud", "氧气模拟值：98%\n电力模拟值：稳定\n生命支持状态：训练环境"))
	var time_text := _resident_status_hud_text()
	if not time_text.is_empty():
		hud_label.text = "%s\n\n%s" % [time_text, hud_label.text]
	if module_id == "suit_control" and not completed:
		hint_label.text = _suit_control_hint(step)
	elif module_id == "airlock_procedure" and not completed:
		hint_label.text = _airlock_hint(step)
	elif module_id == "power_repair" and not completed:
		hint_label.text = _power_hint(step)
	elif module_id == "power_distribution" and not completed:
		hint_label.text = _power_distribution_hint(step)
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
	if String(step.get("type", "")) == "solar_fault_diagnosis":
		_show_solar_fault_diagnosis()
	if completed:
		hint_label.text = _completed_hint_text()
	_sync_overlay_visibility()

## Matches on step type, not target -- wear_suit_confirm/suit_status_panel
## share the same "suit_rack" target but need different instructions.
func _suit_control_hint(step: Dictionary) -> String:
	match String(step.get("type", "")):
		"move":
			return "请移动到宇航服整备架。"
		"wear_suit_confirm":
			return "请靠近宇航服整备架并按 E 穿戴宇航服。"
		"suit_status_panel":
			return "请按 Tab 查看宇航服状态面板。"
		"interact":
			if String(step.get("target", "")) == "exit":
				return "宇航服状态已确认。请前往模拟气闸舱入口并按 E。"
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
	var lines: Array[String] = ["训练供电系统：%s" % _power_status()]
	var warning := _eva_resource_warning()
	if not warning.is_empty():
		lines.append(warning)
	return "\n".join(lines)

## "Critical -> Basic" per the design spec's own wording -- this is a
## training-scene-local flag (module_data["state"]["SolarArrayRepaired"]),
## not a real BaseStatusManager/PowerSystemManager value. Training must
## never touch those.
func _power_status() -> String:
	var state: Dictionary = module_data.get("state", {})
	return "Basic" if bool(state.get("SolarArrayRepaired", false)) else "Critical"

## Low-resource EVA warning (spec section 17). Deliberately does not force
## a scene transition or fail the module immediately -- if the player
## can't recover, the archive time limit running out is what eventually
## fails training (TrainingTimeManager.check_training_timeout() already
## handles that; this room doesn't need its own timeout system).
func _eva_resource_warning() -> String:
	var suit_manager := _suit_manager()
	if suit_manager == null:
		return ""
	var oxygen: float = float(suit_manager.get("suit_oxygen"))
	var power: float = float(suit_manager.get("suit_power"))
	if oxygen < 20.0:
		return "宇航服氧气不足。\n外勤训练必须中止。"
	if power < 20.0:
		return "宇航服电力不足。\n外勤操作受限，请返回气闸。"
	return ""

func _power_visual_status(node_name: String) -> String:
	var state: Dictionary = module_data.get("state", {})
	if node_name == "solar_array_fault":
		if bool(state.get("SolarArrayRepaired", false)):
			return "repaired"
		if bool(state.get("SolarArrayInspected", false)):
			return "inspected"
		return "fault"
	return ""

func _power_hint(step: Dictionary) -> String:
	match String(step.get("type", "")):
		"suit_status_panel":
			return "按 Tab 查看宇航服外勤状态。"
		"move":
			return "请前往太阳能阵列故障点。"
		"inspect_solar_array_confirm":
			return "请靠近太阳能阵列 A 并按 E 检查故障。"
		"solar_fault_diagnosis":
			return "请按 E 打开维修方案面板，选择排查方向。"
		"interact":
			if String(step.get("target", "")) == "exit":
				return "月面太阳能板维修训练已完成。\n请前往训练出口，进入下一训练模块。"
	return "请按太阳能阵列维修流程继续。"

func _power_distribution_hud_text() -> String:
	var state: Dictionary = module_data.get("state", {})
	var input := "已恢复" if bool(state.get("SolarInputDetected", true)) else "待确认"
	var storage := "已接入" if bool(state.get("StorageModuleConnected", false)) else "未接入"
	var output := String(state.get("PowerStatus", "不稳定"))
	var lines: Array[String] = [
		"太阳能输入：%s" % input,
		"储能模块：%s" % storage,
		"配电主线：%s" % output,
		"提示信息：%s" % _power_distribution_hint(_current_step()),
	]
	var professional_hint := _professional_hint_block("training_04_power_storage_fault")
	if not professional_hint.is_empty():
		lines.append("")
		lines.append(professional_hint)
	return "\n".join(lines)

func _power_distribution_hint(step: Dictionary) -> String:
	match String(step.get("target", "")):
		"panel":
			if bool((module_data.get("state", {}) as Dictionary).get("PowerPanelInspected", false)):
				return "请接入储能模块，让配电主线具备稳定缓冲。"
			return "请查看配电房供电异常。"
		"console":
			return "请在配电控制台重启供电系统。"
		"light":
			return "请确认供电测试灯状态。"
		"exit":
			return "请前往空气系统控制室入口。"
	return "请按配电恢复流程继续。"

func _life_support_hud_text() -> String:
	var status := _life_support_status()
	var oxygen := "稳定" if status == "稳定" else "偏低"
	var temperature := "稳定" if status == "稳定" else "偏低"
	var lines: Array[String] = [
		"氧气模拟值：%s" % oxygen,
		"水循环状态：稳定",
		"电力模拟值：稳定",
		"温度模拟值：%s" % temperature,
		"生命支持状态：%s" % status,
		"提示信息：%s" % _life_support_hint(_current_step()),
	]
	var professional_hint := _professional_hint_block("training_05_air_oxygen_low")
	if not professional_hint.is_empty():
		lines.append("")
		lines.append(professional_hint)
	return "\n".join(lines)

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
			return "模块五记录已完成。\n请前往训练出口，进入训练温室。"
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
	return ""

func _plant_hint(step: Dictionary) -> String:
	match String(step.get("target", "")):
		"plant":
			var state: Dictionary = module_data.get("state", {})
			if bool(state.get("PlantStable", false)):
				return "请确认植物状态已经趋于稳定。"
			return "请靠近训练植物，查看植物舱状态。"
		"light_console":
			return "请前往植物控制台并按 E。"
		"exit":
			return "模块六记录已完成。\n请返回宇航服整备室。"
	if String(step.get("type", "")) == "diagnosis":
		return "请根据植物舱状态选择异常原因。"
	if String(step.get("type", "")) == "plant_control":
		return "请在植物控制台选择维护动作。"
	if String(step.get("type", "")) == "wait":
		return "请等待植物状态恢复稳定。"
	return "请按植物诊断流程继续。"

func _assessment_hud_text() -> String:
	var state: Dictionary = module_data.get("state", {})
	if bool(state.get("SuitReturnFlow", false)):
		var suit_state := "returned" if bool(state.get("SuitReturned", false)) else "worn"
		var maintenance_state := "servicing" if bool(state.get("SuitMaintenanceStarted", false)) else "pending"
		var result_state := "complete" if bool(state.get("FinalAssessmentCompleted", false)) else "pending"
		return "Suit Return: active\nSuit: %s\nService Slot: %s\nTraining Result: %s\nHint: %s" % [
			suit_state,
			maintenance_state,
			result_state,
			_assessment_hint(_current_step()),
		]
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
			return "fault"
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
			return "请查看植物舱状态。"
		"light_console":
			return "请使用植物控制台选择维护动作。"
	if String(step.get("type", "")) == "diagnosis":
		return "请根据植物舱状态选择植物异常原因。"
	if String(step.get("type", "")) == "plant_control":
		return "请在植物控制台选择维护动作。"
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

func _add_panel_section_label(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = Color("#86c7ff")
	label.add_theme_font_size_override("font_size", 13)
	parent.add_child(label)

func _add_button(parent: HBoxContainer, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(190, 42)
	# Footer buttons must never hold keyboard focus: Tab doubles as Godot's
	# ui_focus_next (stealing the suit-status-panel toggle) and Enter doubles
	# as the "interact" action (which would trigger the focused button).
	button.focus_mode = Control.FOCUS_NONE
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
		"power_distribution":
			return _power_distribution_config()
		"life_support":
			return _life_support_config()
		"plant_diagnosis":
			return _plant_config()
		"final_assessment":
			return _suit_return_config()
	return _suit_control_config()

func _base_config() -> Dictionary:
	return {
		"state": {},
		"player_start": Vector2(62, 420),
		"hud": "氧气模拟值：98%\n电力模拟值：稳定\n生命支持状态：训练环境\n提示信息：靠近目标后按 E。",
	}

## Room name per design spec: 宇航服整备室 (Spacesuit Preparation Room).
## Still module_id "suit_control" / Training_01_SuitControl.tscn -- kept the
## existing module_id rather than renaming to "spacesuit_preparation" since
## that would require touching TrainingManager.are_required_modules_completed()/
## default_data()/MODULE_SCENES and every save-compat path built around the
## current 5-module scheme, for a rename with no functional benefit.
func _suit_control_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "训练模块一：宇航服整备室",
		"subtitle": "SPACESUIT PREPARATION",
		"next_module": "airlock_procedure",
		"next_scene": TrainingManagerScript.MODULE_02,
		"player_start": Vector2(420, 310),
		"player_size": Vector2(42, 54),
		"targets": [
			{"id": "suit_rack", "kind": "tool_station", "label": "宇航服整备架", "position": Vector2(440, 180), "color": Color("#31536f")},
			{"id": "exit", "label": "模拟气闸舱入口", "position": Vector2(690, 390), "color": Color("#274f43")},
		],
		"steps": [
			{"type": "move", "target": "suit_rack", "objective": "移动到宇航服整备架", "line": "已抵达宇航服整备架。"},
			{"type": "wear_suit_confirm", "target": "suit_rack", "objective": "按 E 穿戴宇航服", "line": "宇航服已穿戴。"},
			{"type": "suit_status_panel", "target": "suit_rack", "objective": "按 Tab 查看宇航服状态面板", "line": "宇航服状态已确认。", "state_updates": {"SuitStatusConfirmed": true, "ExitDoorUnlocked": true}},
			{"type": "interact", "target": "exit", "objective": "进入模拟气闸舱", "line": "宇航服整备室训练完成。", "requires": {"ExitDoorUnlocked": true}, "blocked_hint": "请先确认宇航服状态。"},
		],
	}, true)
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
	}, true)
	return data

## Room name per design spec: 太阳能阵列训练场 (Solar Array Training Field).
## Still module_id "power_repair" / SolarArrayTrainingField.tscn -- see the
## const MODULE_03 comment in training_manager.gd for why the module_id
## wasn't renamed to "training_03_solar_panel_repair" (same reasoning as
## room 1 keeping "suit_control").
func _power_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "训练模块三：月面太阳能板维修",
		"subtitle": "SOLAR ARRAY TRAINING FIELD",
		"next_module": "power_distribution",
		## Returns to the training small map's hub (气闸 -> 太阳能阵列训练场 is the
		## only leg of the training map that's still a real scene transition;
		## see training_base_map.gd's file header) instead of the old
		## standalone Training_04_PowerDistribution.tscn.
		"next_scene": TrainingManagerScript.TRAINING_BASE_MAP,
		"player_start": Vector2(1260, 380),
		"player_size": Vector2(42, 54),
		"hud": "当前环境：月面真空模拟\n宇航服生命支持已接管。",
		"targets": [
			{"id": "solar_array_fault", "kind": "power_console", "label": "太阳能阵列 A", "position": Vector2(420, 260), "color": Color("#4b3f2a")},
			{"id": "exit", "label": "返回气闸外舱门", "position": Vector2(1340, 388), "color": Color("#274f43")},
		],
		"steps": [
			{"type": "suit_status_panel", "target": "solar_array_fault", "objective": "按 Tab 查看宇航服外勤状态", "line": "宇航服外勤状态已确认。", "state_updates": {"EvaSuitStatusConfirmed": true}},
			{"type": "move", "target": "solar_array_fault", "objective": "前往太阳能阵列故障点", "line": "已抵达太阳能阵列故障点。"},
			{"type": "inspect_solar_array_confirm", "target": "solar_array_fault", "objective": "检查太阳能阵列 A", "line": "太阳能阵列检查完成。", "state_updates": {"SolarArrayInspected": true}, "time_minutes": 0},
			{"type": "solar_fault_diagnosis", "target": "solar_array_fault", "objective": "选择维修方案", "line": "太阳能阵列维修完成。", "state_updates": {"SolarArrayRepaired": true, "Module03Completed": true}, "time_minutes": 0},
			{"type": "interact", "target": "exit", "objective": "进入下一训练模块", "line": "月面太阳能板维修训练完成。", "requires": {"SolarArrayRepaired": true}, "blocked_hint": "太阳能阵列尚未恢复基础输出，请先完成维修。"},
		],
	}, true)
	return data

func _power_distribution_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "训练模块四：配电房供电恢复",
		"subtitle": "POWER DISTRIBUTION ROOM",
		"next_module": "life_support",
		"next_scene": TrainingManagerScript.MODULE_05,
		"player_start": Vector2(364, 396),
		"player_size": Vector2(42, 54),
		"hud": "太阳能输入：已恢复\n储能模块：未接入\n配电主线：不稳定\n提示信息：查看供电系统异常。",
		"targets": [
			{"id": "panel", "label": "储能接入面板"},
			{"id": "console", "label": "配电控制台"},
			{"id": "light", "label": "供电测试灯"},
			{"id": "exit", "label": "空气系统控制室入口"},
		],
		"steps": [
			{"type": "interact", "target": "panel", "objective": "查看供电系统异常", "line": "太阳能输入已恢复。\n配电主线电压不稳定。\n储能模块未接入主供电回路。", "state_updates": {"SolarInputDetected": true, "PowerPanelInspected": true, "PowerStatus": "不稳定"}},
			{"type": "interact", "target": "panel", "objective": "接入储能模块", "line": "正在接入储能模块……\n储能模块已接入主供电回路。", "time_minutes": 30, "time_reason": "training_connect_storage_module", "state_updates": {"PowerPanelRepaired": true, "StorageModuleConnected": true, "PowerStatus": "待重启"}, "requires": {"PowerPanelInspected": true}, "blocked_hint": "请先查看供电系统异常。"},
			{"type": "interact", "target": "console", "objective": "重启配电系统", "line": "配电系统正在重启。\n主线电压稳定。\n训练供电状态：Basic -> Stable。", "time_minutes": 30, "time_reason": "training_restart_power_distribution", "state_updates": {"PowerRestored": true, "PowerStatus": "稳定", "TestLightOn": true}, "requires": {"PowerPanelRepaired": true}, "blocked_hint": "储能模块尚未接入。无法重启配电系统。"},
			{"type": "interact", "target": "light", "objective": "确认供电稳定", "line": "测试灯已点亮。\n配电房供电恢复训练完成。", "state_key": "PowerDistributionConfirmed", "requires": {"PowerRestored": true}, "blocked_hint": "供电尚未稳定。"},
			{"type": "interact", "target": "exit", "objective": "进入空气系统控制室", "line": "训练模块四完成。\n空气系统恢复训练即将开始。", "state_key": "Module04Completed", "requires": {"PowerDistributionConfirmed": true}, "blocked_hint": "请先确认供电稳定。"},
		],
	}, true)
	return data

func _life_support_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "训练模块五：训练舱空气恢复",
		"subtitle": "AIR SYSTEM RESTORATION",
		"next_module": "plant_diagnosis",
		"next_scene": TrainingManagerScript.MODULE_06,
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
	}, true)
	return data

func _plant_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "训练模块六：温室植物诊断",
		"subtitle": "PLANT DIAGNOSIS",
		"next_module": "final_assessment",
		"next_scene": TrainingManagerScript.FINAL_ASSESSMENT,
		"player_start": Vector2(360, 402),
		"player_size": Vector2(42, 54),
		"hud": "氧气模拟值：98%\n电力模拟值：稳定\n生命支持状态：稳定\n植物状态：异常\n提示信息：观察，再诊断。",
		"targets": [
			{"id": "plant", "label": "训练植物", "position": Vector2(350, 260), "color": Color("#2d5b3f")},
			{"id": "light_console", "label": "植物控制台", "position": Vector2(620, 260), "color": Color("#31536f")},
			{"id": "grow_light", "label": "生长灯", "position": Vector2(570, 130), "color": Color("#4b4f37")},
			{"id": "exit", "label": "训练出口", "position": Vector2(710, 410), "color": Color("#4d6473")},
		],
		"steps": [
			{"type": "interact", "target": "plant", "objective": "查看训练植物", "line": "植物舱诊断视图已打开。", "state_updates": {"Module05Started": true, "PlantObserved": true, "PlantStatus": "异常"}},
			{"type": "diagnosis", "objective": "选择诊断结果", "line": "诊断确认：光照不足。", "options": ["缺水", "光照不足", "根区温度异常"], "correct": "光照不足", "wrong_hint": "诊断结果不匹配。\n请重新查看植物舱状态。", "state_updates": {"DiagnosisSelected": true, "CorrectDiagnosis": "LightInsufficient"}, "requires": {"PlantObserved": true}, "blocked_hint": "诊断信息不足。请先查看训练植物。"},
			{"type": "plant_control", "target": "light_console", "objective": "调整植物控制台", "line": "补光方案已调整。\n植物状态正在恢复。", "options": ["调节温度", "浇水", "补光"], "correct": "补光", "wrong_hint": "该操作无法解决当前异常。\n请根据植物舱诊断结果选择维护动作。", "state_updates": {"GrowLightAdjusted": true, "PlantStatus": "稳定中", "GrowLightStatus": "正常"}, "requires": {"DiagnosisSelected": true}, "blocked_hint": "请先确认植物异常原因。"},
			{"type": "wait", "target": "plant", "objective": "确认植物状态稳定", "line": "植物状态趋于稳定。\n叶片反应：恢复中。\n补光输出：正常。", "duration": 1.5, "state_updates": {"PlantStable": true, "PlantStatus": "稳定"}},
			{"type": "interact", "target": "exit", "objective": "返回宇航服整备室", "line": "训练模块六完成。\n请返回宇航服整备室，执行宇航服归位与维护。", "state_key": "Module06Completed", "requires": {"PlantStable": true}, "blocked_hint": "训练模块尚未完成。"},
		],
	}, true)
	return data

func _suit_return_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "Training Closeout: Suit Return",
		"subtitle": "SUIT RETURN AND MAINTENANCE",
		"state": {"SuitReturnFlow": true},
		"next_module": "mission_assignment",
		"next_scene": TrainingManagerScript.MISSION_NOTICE,
		"next_button": "查看任务派遣通知",
		"player_start": Vector2(420, 310),
		"player_size": Vector2(42, 54),
		"hud": "Suit Return: pending\nSuit: worn\nService Slot: pending",
		"targets": [
			{"id": "suit_rack", "kind": "tool_station", "label": "Suit Service Slot", "position": Vector2(440, 180), "color": Color("#31536f")},
			{"id": "terminal", "kind": "assessment_terminal", "label": "Training Result Terminal", "position": Vector2(620, 360), "color": Color("#31536f")},
			{"id": "exit", "label": "Mission Assignment Exit", "position": Vector2(690, 390), "color": Color("#274f43")},
		],
		"steps": [
			{"type": "move", "target": "suit_rack", "objective": "返回宇航服整备室", "line": "已返回宇航服整备室。"},
			{"type": "return_suit_confirm", "target": "suit_rack", "objective": "将宇航服脱下并放回维护位", "line": "宇航服已归位。\n维护位已接管宇航服状态恢复。", "state_updates": {"SuitReturned": true, "SuitMaintenanceStarted": true}},
			{"type": "interact", "target": "terminal", "objective": "查看训练结果", "line": "候选人评估完成。\n\n结果：派遣资格已激活。\n\n你已完成基础生命支持、气闸流程、外勤维修、供电恢复、空气恢复与温室诊断训练。", "state_updates": {"FinalAssessmentCompleted": true}, "requires": {"SuitReturned": true}, "blocked_hint": "请先将宇航服脱下并放回维护位。"},
			{"type": "interact", "target": "exit", "objective": "查看任务派遣通知", "line": "训练序列完成。", "requires": {"FinalAssessmentCompleted": true}, "blocked_hint": "请先查看训练结果。"},
		],
	}, true)
	return data

func _assessment_config() -> Dictionary:
	var data := _base_config()
	data.merge({
		"title": "最终考核：综合模拟事故",
		"subtitle": "FINAL ASSESSMENT",
		"next_module": "mission_assignment",
		"next_scene": TrainingManagerScript.MISSION_NOTICE,
		"next_button": "查看任务派遣通知",
		"player_start": Vector2(610, 476),
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
			{"id": "light_console", "label": "植物控制台"},
			{"id": "grow_light", "label": "补光灯"},
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
			{"type": "interact", "target": "plant", "objective": "查看植物舱状态", "line": "植物舱诊断视图已打开。", "state_updates": {"PlantObserved": true, "PlantStatus": "异常"}, "requires": {"LifeSupportStable": true}, "blocked_hint": "生命支持状态尚未稳定。植物舱诊断结果可能不可靠。"},
			{"type": "diagnosis", "objective": "选择植物异常原因", "line": "诊断确认：光照不足。", "options": ["缺水", "光照不足", "根区温度异常"], "correct": "光照不足", "wrong_hint": "诊断结果不匹配。\n请重新查看植物舱状态。", "state_updates": {"CorrectDiagnosis": "LightInsufficient", "DiagnosisSelected": true}, "requires": {"PlantObserved": true}},
			{"type": "plant_control", "target": "light_console", "objective": "使用植物控制台", "line": "补光方案已调整。\n植物状态正在恢复。", "options": ["调节温度", "浇水", "补光"], "correct": "补光", "wrong_hint": "该操作无法解决当前异常。\n请根据植物舱诊断结果选择维护动作。", "state_updates": {"GrowLightAdjusted": true, "GrowLightStatus": "稳定", "PlantStatus": "稳定中"}, "requires": {"CorrectDiagnosis": "LightInsufficient"}, "blocked_hint": "请先确认植物异常原因。"},
			{"type": "wait", "target": "plant", "objective": "等待植物状态稳定", "line": "植物状态：稳定。\n叶片反应：恢复中。\n补光输出：正常。", "duration": 1.4, "state_updates": {"PlantStable": true, "PlantStatus": "稳定"}},
			{"type": "interact", "target": "terminal", "objective": "提交考核结果", "line": "最终考核完成。\n\n供电恢复。\n生命支持稳定。\n植物舱状态稳定。\n\n候选人具备进入月面长期驻留任务后续阶段的基础资格。", "state_key": "FinalAssessmentCompleted", "requires": {"PowerRestored": true, "LifeSupportStable": true, "PlantStable": true}, "blocked_hint": "考核结果不完整。请确认供电、生命支持与植物舱状态。"},
		],
	}, true)
	return data
