extends Node
class_name GuanghanBaseStatusManager

signal base_status_changed

const SAVE_PATH := "user://saves/base_status_state.json"
const APPLICATION_PROFILE_PATH := "user://saves/application_profile.json"

enum SystemStatus {
	OFFLINE,
	CRITICAL,
	BASIC,
	STABLE,
}

const ARRIVAL_POWER := 42.0
const ARRIVAL_PRESSURE := 76.0
const ARRIVAL_TEMPERATURE := 14.0

const COMFORT_TEMPERATURE := 21.0

var power: float = ARRIVAL_POWER
var pressure: float = ARRIVAL_PRESSURE
var temperature: float = ARRIVAL_TEMPERATURE

var power_system_status: int = SystemStatus.CRITICAL
var thermal_control_status: int = SystemStatus.CRITICAL
var seal_status: int = SystemStatus.BASIC

var last_plant_recovered_bonus_active: bool = false

func _ready() -> void:
	load_state()

func reset_to_arrival() -> void:
	power = ARRIVAL_POWER
	pressure = ARRIVAL_PRESSURE
	temperature = ARRIVAL_TEMPERATURE
	power_system_status = SystemStatus.CRITICAL
	thermal_control_status = SystemStatus.CRITICAL
	seal_status = SystemStatus.BASIC
	last_plant_recovered_bonus_active = false
	_save_state()
	base_status_changed.emit()

func set_minimum_stable_state() -> void:
	power = 45.0
	pressure = 76.0
	temperature = 18.5
	power_system_status = SystemStatus.BASIC
	thermal_control_status = SystemStatus.BASIC
	seal_status = SystemStatus.BASIC
	clamp_base_values()
	_save_state()
	base_status_changed.emit()

func clamp_base_values() -> void:
	power = clamp(power, 0.0, 100.0)
	pressure = clamp(pressure, 0.0, 100.0)
	temperature = clamp(temperature, -40.0, 60.0)

## Called by TimeManager after it advances the clock. Does not advance time itself.
## Power is no longer settled here — PowerSystemManager owns it and calls
## set_power_percent() before this runs; pressure/temperature still read the
## resulting `power` value exactly as before.
func advance_base_time(minutes: int) -> void:
	if minutes <= 0:
		return
	var hours := float(minutes) / 60.0
	var is_daylight := _is_daylight_phase()
	_apply_pressure_change(hours)
	_apply_temperature_change(hours, is_daylight)
	clamp_base_values()
	_apply_health_environment_effects(hours)
	_save_state()
	base_status_changed.emit()

## Called by PowerSystemManager after it settles current_energy/battery_capacity,
## so the rest of this tick's systems (temperature multiplier, AirSystemManager,
## HealthManager) see an up-to-date value without needing to change how they read it.
func set_power_percent(value: float) -> void:
	power = clamp(value, 0.0, 100.0)

func _apply_pressure_change(hours: float) -> void:
	var rate := 0.0
	match seal_status:
		SystemStatus.OFFLINE:
			rate = -0.20
		SystemStatus.CRITICAL:
			rate = -0.06
		SystemStatus.BASIC:
			rate = -0.02
		SystemStatus.STABLE:
			rate = 0.0
	pressure += rate * hours

func _apply_temperature_change(hours: float, is_daylight: bool) -> void:
	var power_multiplier := 1.0
	if power >= 70.0:
		power_multiplier = 1.0
	elif power >= 40.0:
		power_multiplier = 0.75
	elif power >= 20.0:
		power_multiplier = 0.4
	else:
		power_multiplier = 0.0
	var delta := 0.0
	if is_daylight:
		match thermal_control_status:
			SystemStatus.OFFLINE:
				delta = 0.20 * power_multiplier * hours
			SystemStatus.CRITICAL:
				delta = 0.05 * power_multiplier * hours
			SystemStatus.BASIC:
				delta = _move_toward_delta(COMFORT_TEMPERATURE, 0.15 * power_multiplier * hours)
			SystemStatus.STABLE:
				delta = _move_toward_delta(COMFORT_TEMPERATURE, 0.25 * power_multiplier * hours)
	else:
		match thermal_control_status:
			SystemStatus.OFFLINE:
				delta = -0.35 * power_multiplier * hours
			SystemStatus.CRITICAL:
				delta = -0.15 * power_multiplier * hours
			SystemStatus.BASIC:
				delta = _move_toward_delta(18.0, 0.10 * power_multiplier * hours)
			SystemStatus.STABLE:
				delta = _move_toward_delta(COMFORT_TEMPERATURE, 0.25 * power_multiplier * hours)
	delta += _pressure_temperature_effect(is_daylight) * hours
	temperature += delta

func _move_toward_delta(target: float, max_step: float) -> float:
	var diff := target - temperature
	if abs(diff) <= max_step:
		return diff
	return max_step if diff > 0.0 else -max_step

func _pressure_temperature_effect(is_daylight: bool) -> float:
	if pressure >= 70.0:
		return 0.0
	if pressure >= 40.0:
		return 0.02 if is_daylight else -0.03
	if pressure >= 20.0:
		return 0.05 if is_daylight else -0.08
	return 0.10 if is_daylight else -0.15

func _apply_health_environment_effects(hours: float) -> void:
	var health_manager := _health_manager()
	if health_manager == null or not health_manager.has_method("adjust_stat"):
		return
	var morale_delta := 0.0
	if power <= 19.0:
		morale_delta -= 0.08 * hours
	elif power < 40.0:
		morale_delta -= 0.03 * hours
	if pressure <= 19.0:
		morale_delta -= 0.10 * hours
	elif pressure < 40.0:
		morale_delta -= 0.05 * hours
	if _temperature_is_dangerous():
		morale_delta -= 0.05 * hours
	if morale_delta != 0.0:
		health_manager.call("adjust_stat", "morale", morale_delta)

## Consulted by HealthManager.get_energy_cost_multiplier(); defaults to 1.0 when
## absent. Oxygen/CO2 no longer factor in here — see AirSystemManager.get_air_energy_multiplier().
func get_temperature_energy_multiplier() -> float:
	if _temperature_comfortable():
		return 1.0
	if _temperature_is_dangerous():
		return 1.25
	return 1.1

func _temperature_comfortable() -> bool:
	return temperature >= 18.0 and temperature <= 26.0

func _temperature_is_dangerous() -> bool:
	return temperature < 10.0 or temperature > 32.0

## Reported to PowerSystemManager for its hourly load total. Device tier
## still only affects temperature *effect* (in _apply_temperature_change),
## per spec's "设备状态影响温控效果，不建议直接改变耗电" — this cost is a
## separate, parallel readout of the same tier.
func get_thermal_power_load() -> float:
	match thermal_control_status:
		SystemStatus.OFFLINE:
			return 0.0
		SystemStatus.CRITICAL:
			return 0.06
		SystemStatus.BASIC:
			return 0.10
		SystemStatus.STABLE:
			return 0.16
	return 0.0

## -- Repair actions: change system status tier and apply a one-time instant delta.
## Time cost is not advanced here; the caller advances TimeManager separately.

func repair_power_light() -> void:
	if power_system_status == SystemStatus.CRITICAL:
		power_system_status = SystemStatus.BASIC
	power += 3.0
	_finish_repair()

func repair_power_heavy() -> void:
	if power_system_status == SystemStatus.BASIC:
		power_system_status = SystemStatus.STABLE
	power += 5.0
	_finish_repair()

func repair_thermal_light() -> void:
	if thermal_control_status == SystemStatus.CRITICAL:
		thermal_control_status = SystemStatus.BASIC
	temperature += _move_toward_delta(18.0, 1.0)
	_finish_repair()

func repair_thermal_heavy() -> void:
	if thermal_control_status == SystemStatus.BASIC:
		thermal_control_status = SystemStatus.STABLE
	temperature += _move_toward_delta(COMFORT_TEMPERATURE, 1.5)
	_finish_repair()

func repair_seal_light() -> void:
	if seal_status == SystemStatus.CRITICAL:
		seal_status = SystemStatus.BASIC
	pressure += 3.0
	_finish_repair()

func repair_seal_heavy() -> void:
	if seal_status == SystemStatus.BASIC:
		seal_status = SystemStatus.STABLE
	pressure += 5.0
	_finish_repair()

func _finish_repair() -> void:
	clamp_base_values()
	_save_state()
	base_status_changed.emit()

## Called once the greenhouse's last plant leaves Critical status.
func set_last_plant_recovered(active: bool) -> void:
	if active and not last_plant_recovered_bonus_active:
		var health_manager := _health_manager()
		if health_manager != null and health_manager.has_method("adjust_stat"):
			health_manager.call("adjust_stat", "morale", 2.0)
	last_plant_recovered_bonus_active = active
	_save_state()

## -- Display labels

func get_power_label() -> String:
	if power >= 70.0:
		return "供电稳定"
	if power >= 40.0:
		return "供电紧张"
	if power >= 20.0:
		return "低电力"
	return "电力危机"

func get_pressure_label() -> String:
	if pressure >= 70.0:
		return "舱压稳定"
	if pressure >= 40.0:
		return "轻微泄压"
	if pressure >= 20.0:
		return "明显泄压"
	return "气密危机"

func get_temperature_label() -> String:
	if temperature >= 18.0 and temperature <= 26.0:
		return "舒适"
	if temperature >= 10.0 and temperature < 18.0:
		return "偏冷"
	if temperature >= 5.0 and temperature < 10.0:
		return "低温危险"
	if temperature < 5.0:
		return "严重低温"
	if temperature > 26.0 and temperature <= 32.0:
		return "偏热"
	if temperature > 32.0 and temperature <= 35.0:
		return "高温危险"
	return "严重高温"

func get_system_status_label(status: int, is_seal: bool = false) -> String:
	match status:
		SystemStatus.OFFLINE:
			return "破损" if is_seal else "离线"
		SystemStatus.CRITICAL:
			return "危急"
		SystemStatus.BASIC:
			return "基础运行" if not is_seal else "基础密封"
		SystemStatus.STABLE:
			return "稳定运行" if not is_seal else "稳定密封"
	return "未知"

func panel_status_text() -> String:
	var lines: Array[String] = [
		"广寒前哨状态",
		"",
		"电力：%s  %d%%" % [get_power_label(), int(round(power))],
		"温度：%s  %d℃" % [get_temperature_label(), int(round(temperature))],
		"舱压：%s  %d%%" % [get_pressure_label(), int(round(pressure))],
		"",
		"系统状态：",
		"供电系统：%s" % get_system_status_label(power_system_status),
		"温控系统：%s" % get_system_status_label(thermal_control_status),
		"密封状态：%s" % get_system_status_label(seal_status, true),
	]
	return "\n".join(lines)

func compact_hud_text() -> String:
	return "基地状态：电力 %s · 舱压 %s" % [get_power_label(), get_pressure_label()]

func get_specialist_hint() -> String:
	match _academic_background():
		"机械工程":
			if power < 70.0 or thermal_control_status != SystemStatus.STABLE:
				return "专业判断：\n当前供电不足会限制温控效率。\n建议优先恢复供电系统。"
		"材料科学":
			if pressure < 80.0 or seal_status != SystemStatus.STABLE:
				return "专业判断：\n舱压暂时可维持，但密封材料存在老化风险。\n建议检查舱门密封圈与舱体接缝。"
		"医学":
			if not _temperature_comfortable() or power <= 19.0:
				return "专业判断：\n低温会增加精力消耗，电力危机会进一步放大这一影响。\n建议避免连续高强度维修，并优先恢复供电与温控。"
		"植物科学":
			if not _temperature_comfortable() or power < 70.0 or not last_plant_recovered_bonus_active:
				return "专业判断：\n当前温度偏低，不利于植物恢复。\n若温控无法稳定，最后一株植物恢复会延迟。"
	return ""

## -- Debug helpers

func adjust_stat(stat_name: String, delta: float) -> void:
	match stat_name:
		"pressure":
			pressure += delta
		"temperature":
			temperature += delta
	clamp_base_values()
	_save_state()
	base_status_changed.emit()

func debug_set_system_status(system_name: String, status_name: String) -> void:
	var status := _status_from_name(status_name)
	match system_name:
		"power_system_status":
			power_system_status = status
		"thermal_control_status":
			thermal_control_status = status
		"seal_status":
			seal_status = status
	_save_state()
	base_status_changed.emit()

func debug_values_text() -> String:
	return "Power: %.0f (%s)\nPressure: %.0f (%s)\nTemperature: %.1f (%s)" % [
		power, get_system_status_label(power_system_status),
		pressure, get_system_status_label(seal_status, true),
		temperature, get_system_status_label(thermal_control_status),
	]

func _status_from_name(status_name: String) -> int:
	match status_name.to_lower():
		"offline":
			return SystemStatus.OFFLINE
		"critical":
			return SystemStatus.CRITICAL
		"basic":
			return SystemStatus.BASIC
		"stable":
			return SystemStatus.STABLE
	return SystemStatus.CRITICAL

## -- Persistence

func serialize() -> Dictionary:
	return {
		"power": power,
		"pressure": pressure,
		"temperature": temperature,
		"power_system_status": power_system_status,
		"thermal_control_status": thermal_control_status,
		"seal_status": seal_status,
		"last_plant_recovered_bonus_active": last_plant_recovered_bonus_active,
	}

func deserialize(data: Dictionary) -> void:
	power = float(data.get("power", power))
	pressure = float(data.get("pressure", pressure))
	temperature = float(data.get("temperature", temperature))
	power_system_status = int(data.get("power_system_status", power_system_status))
	thermal_control_status = int(data.get("thermal_control_status", thermal_control_status))
	seal_status = int(data.get("seal_status", seal_status))
	last_plant_recovered_bonus_active = bool(data.get("last_plant_recovered_bonus_active", last_plant_recovered_bonus_active))
	clamp_base_values()
	base_status_changed.emit()

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

func _save_state() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(serialize(), "\t"))

func _is_daylight_phase() -> bool:
	var manager := _time_manager()
	if manager == null:
		return false
	return String(manager.get("lunar_phase")) == "daylight"

func _time_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TimeManager")

func _health_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("HealthManager")

func _academic_background() -> String:
	if not FileAccess.file_exists(APPLICATION_PROFILE_PATH):
		return ""
	var file := FileAccess.open(APPLICATION_PROFILE_PATH, FileAccess.READ)
	if file == null:
		return ""
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return ""
	var data := parsed as Dictionary
	return String(data.get("EducationBackground", data.get("education_background", "")))
