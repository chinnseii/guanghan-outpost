extends Node
class_name GuanghanTimeManager

signal time_advanced(minutes: int, reason: String)
signal time_changed(day: int, hour: int, minute: int)
signal lunar_phase_changed(phase: String)

enum LunarPhase {
	NIGHT_LATE,
	DAYLIGHT,
	NIGHT,
}

const SAVE_PATH := "user://saves/time_state.json"

const TIME_MOVE_ONE_TILE := 1
const TIME_SLEEP_STANDARD := 360
const TIME_EAT := 30
const TIME_NUTRITION_DRINK := 15
const TIME_ENTERTAINMENT_SHORT := 60
const TIME_ENTERTAINMENT_LONG := 120
const TIME_REPAIR_LIGHT := 30
const TIME_REPAIR_HEAVY := 60
const TIME_EXPLORE_SHORT := 120
const TIME_EXPLORE_LONG := 240
const TIME_PLANT_DIAGNOSIS := 15
const TIME_ORGANIZE_SUPPLIES := 30
const TIME_SEND_REPORT := 15

const START_DAY := 1
const START_HOUR := 6
const START_MINUTE := 40
const MINUTES_PER_DAY := 24 * 60
const DAYLIGHT_START_MINUTE := 7 * MINUTES_PER_DAY
const NIGHT_START_MINUTE := 21 * MINUTES_PER_DAY
const FULL_LUNAR_CYCLE_MINUTES := 42 * MINUTES_PER_DAY

var total_minutes: int = 0
var current_day: int = START_DAY
var hour: int = START_HOUR
var minute: int = START_MINUTE
var lunar_phase: String = "night_late"
var minutes_until_phase_change: int = DAYLIGHT_START_MINUTE
var last_phase_notice := ""

func _ready() -> void:
	load_state()

func reset_to_arrival() -> void:
	total_minutes = 0
	current_day = START_DAY
	hour = START_HOUR
	minute = START_MINUTE
	lunar_phase = "night_late"
	minutes_until_phase_change = DAYLIGHT_START_MINUTE
	last_phase_notice = ""
	_save_state()
	time_changed.emit(current_day, hour, minute)
	lunar_phase_changed.emit(lunar_phase)

func advance_time(minutes_to_add: int, reason: String = "") -> void:
	if minutes_to_add <= 0:
		return
	total_minutes += minutes_to_add
	_update_clock()
	_update_lunar_phase()
	_save_state()
	time_advanced.emit(minutes_to_add, reason)
	time_changed.emit(current_day, hour, minute)

func action_minutes(action_name: String) -> int:
	match action_name:
		"move":
			return TIME_MOVE_ONE_TILE
		"sleep_standard":
			return TIME_SLEEP_STANDARD
		"eat":
			return TIME_EAT
		"nutrition_drink":
			return TIME_NUTRITION_DRINK
		"entertainment_short":
			return TIME_ENTERTAINMENT_SHORT
		"entertainment_long":
			return TIME_ENTERTAINMENT_LONG
		"repair_light":
			return TIME_REPAIR_LIGHT
		"repair_heavy":
			return TIME_REPAIR_HEAVY
		"explore_short":
			return TIME_EXPLORE_SHORT
		"explore_long":
			return TIME_EXPLORE_LONG
		"plant_diagnosis":
			return TIME_PLANT_DIAGNOSIS
		"organize_supplies":
			return TIME_ORGANIZE_SUPPLIES
		"send_report":
			return TIME_SEND_REPORT
	return 0

func advance_to_daylight_start() -> void:
	if total_minutes < DAYLIGHT_START_MINUTE:
		advance_time(DAYLIGHT_START_MINUTE - total_minutes, "debug_jump_to_daylight")

func advance_to_night_start() -> void:
	if total_minutes < NIGHT_START_MINUTE:
		advance_time(NIGHT_START_MINUTE - total_minutes, "debug_jump_to_night")
	else:
		var cycle_minutes := _cycle_minutes()
		var next_night := total_minutes + ((NIGHT_START_MINUTE - cycle_minutes + FULL_LUNAR_CYCLE_MINUTES) % FULL_LUNAR_CYCLE_MINUTES)
		if next_night == total_minutes:
			return
		advance_time(next_night - total_minutes, "debug_jump_to_night")

func serialize() -> Dictionary:
	return {
		"total_minutes": total_minutes,
		"current_day": current_day,
		"hour": hour,
		"minute": minute,
		"lunar_phase": lunar_phase,
		"minutes_until_phase_change": minutes_until_phase_change,
	}

func deserialize(data: Dictionary) -> void:
	total_minutes = max(0, int(data.get("total_minutes", total_minutes)))
	current_day = max(1, int(data.get("current_day", current_day)))
	hour = clamp(int(data.get("hour", hour)), 0, 23)
	minute = clamp(int(data.get("minute", minute)), 0, 59)
	lunar_phase = String(data.get("lunar_phase", lunar_phase))
	minutes_until_phase_change = max(0, int(data.get("minutes_until_phase_change", minutes_until_phase_change)))
	_update_clock()
	_update_lunar_phase(false)
	time_changed.emit(current_day, hour, minute)

func load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		reset_to_arrival()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		reset_to_arrival()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		reset_to_arrival()
		return
	deserialize(parsed as Dictionary)

func save_state() -> void:
	_save_state()

func consume_phase_notice() -> String:
	var text := last_phase_notice
	last_phase_notice = ""
	return text

func compact_hud_text() -> String:
	return "%s  %02d:%02d\n月面状态：%s\n%s：%s" % [
		day_text(),
		hour,
		minute,
		phase_display_name(),
		next_phase_label(),
		format_duration(minutes_until_phase_change),
	]

func day_text() -> String:
	return "Day %02d" % current_day

func phase_display_name() -> String:
	match lunar_phase:
		"night_late":
			return "月夜末期"
		"daylight":
			return "月昼作业期"
		"night":
			return "月夜期"
	return "未知"

func next_phase_label() -> String:
	match lunar_phase:
		"night_late":
			return "距月昼"
		"daylight":
			return "距月夜"
		"night":
			return "距月昼"
	return "距阶段切换"

func format_duration(minutes_value: int) -> String:
	var safe_minutes: int = max(0, minutes_value)
	var days: int = int(safe_minutes / MINUTES_PER_DAY)
	var hours: int = int((safe_minutes % MINUTES_PER_DAY) / 60)
	if days > 0:
		return "%d天 %d小时" % [days, hours]
	return "%d小时" % hours

func _update_clock() -> void:
	var total_from_start := START_HOUR * 60 + START_MINUTE + total_minutes
	current_day = START_DAY + int(total_from_start / MINUTES_PER_DAY)
	hour = int(total_from_start / 60) % 24
	minute = total_from_start % 60

func _update_lunar_phase(emit_notice := true) -> void:
	var previous_phase := lunar_phase
	var cycle_minutes := _cycle_minutes()
	if cycle_minutes < DAYLIGHT_START_MINUTE:
		lunar_phase = "night_late"
		minutes_until_phase_change = DAYLIGHT_START_MINUTE - cycle_minutes
	elif cycle_minutes < NIGHT_START_MINUTE:
		lunar_phase = "daylight"
		minutes_until_phase_change = NIGHT_START_MINUTE - cycle_minutes
	else:
		lunar_phase = "night"
		minutes_until_phase_change = FULL_LUNAR_CYCLE_MINUTES - cycle_minutes + DAYLIGHT_START_MINUTE
	if emit_notice and previous_phase != lunar_phase:
		last_phase_notice = _phase_notice_text(lunar_phase)
		lunar_phase_changed.emit(lunar_phase)

func _cycle_minutes() -> int:
	return total_minutes % FULL_LUNAR_CYCLE_MINUTES

func _phase_notice_text(phase: String) -> String:
	match phase:
		"daylight":
			return "月面日出确认。\n太阳高度角上升。\n太阳能阵列输入恢复。\n外部作业窗口开启。\n广寒前哨进入月昼作业期。"
		"night":
			return "月面日落确认。\n太阳能输入下降。\n外部作业风险上升。\n基地进入月夜节能准备。\n请确认电力、水、氧气与食物储备。"
	return ""

func _save_state() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(serialize(), "\t"))
