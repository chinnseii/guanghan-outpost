extends Node

signal time_changed(day: int, hour: int, minute: int)
signal day_changed(day: int)

var day := 1
var hour := 7
var minute := 42
var time_scale := 1.0
var paused := false

func set_time(new_day: int, new_hour: int, new_minute: int) -> void:
	day = max(1, new_day)
	hour = clamp(new_hour, 0, 23)
	minute = clamp(new_minute, 0, 59)
	time_changed.emit(day, hour, minute)

func set_paused(is_paused: bool) -> void:
	paused = is_paused

func set_time_scale(new_scale: float) -> void:
	time_scale = max(0.0, new_scale)

func advance_minutes(amount: int) -> void:
	if paused or amount <= 0:
		return
	var total := hour * 60 + minute + amount
	var added_days := int(total / 1440)
	hour = int(total / 60) % 24
	minute = total % 60
	if added_days > 0:
		day += added_days
		day_changed.emit(day)
	time_changed.emit(day, hour, minute)

func advance_day(start_hour: int = 7, start_minute: int = 42) -> void:
	day += 1
	hour = clamp(start_hour, 0, 23)
	minute = clamp(start_minute, 0, 59)
	day_changed.emit(day)
	time_changed.emit(day, hour, minute)

func serialize() -> Dictionary:
	return {
		"day": day,
		"hour": hour,
		"minute": minute,
		"time_scale": time_scale,
		"paused": paused,
	}

func deserialize(data: Dictionary) -> void:
	day = int(data.get("day", 1))
	hour = int(data.get("hour", 7))
	minute = int(data.get("minute", 42))
	time_scale = float(data.get("time_scale", 1.0))
	paused = bool(data.get("paused", false))
	time_changed.emit(day, hour, minute)

func clock_text() -> String:
	return "D%02d %02d:%02d" % [day, hour, minute]
