extends Node
class_name GuanghanPowerSystemManager

signal power_system_changed

const SAVE_PATH := "user://saves/power_system_state.json"
const APPLICATION_PROFILE_PATH := "user://saves/application_profile.json"

## Independent from BaseStatusManager.SystemStatus by design, same convention
## as AirSystemManager: no hard cross-file dependency, just a matching
## OFFLINE<CRITICAL<BASIC<STABLE ordering.
enum SystemStatus {
	OFFLINE,
	CRITICAL,
	BASIC,
	STABLE,
}

const BATTERY_CAPACITY_PER_MODULE := 60.0
const SOLAR_OUTPUT_PER_PANEL := 0.35
const BASE_MINIMUM_LOAD := 0.03

const STORAGE_EFFICIENCY_TIERS := [1.0, 1.15, 1.30, 1.50, 1.80]
const CHARGING_EFFICIENCY_TIERS := [1.0, 1.15, 1.25, 1.40, 1.60]

## "推荐电力模式" presets (section 11): only the two dials a mode switch can
## reasonably touch (air supply target, greenhouse light level). Thermal/CO2
## filter/circulation stay repair-gated, not mode-switched.
const POWER_MODE_PRESETS := {
	"extreme_saving": {"label": "极限省电", "supply_target": "eco", "light_level": 0},
	"standard": {"label": "标准维持", "supply_target": "standard", "light_level": 0},
	"standard_night_light": {"label": "标准维持+夜间2级补光", "supply_target": "standard", "light_level": 2},
	"high_load_greenhouse": {"label": "高负载温室", "supply_target": "rich", "light_level": 4},
}

var current_energy: float = 50.0
var base_battery_capacity: float = 120.0
var battery_capacity: float = 120.0
var battery_module_count: int = 2
var solar_panel_count: int = 2
var solar_array_status: int = SystemStatus.CRITICAL
var storage_efficiency: float = 1.0
var charging_efficiency: float = 1.0
var current_power_mode: String = "standard"

func _ready() -> void:
	load_state()

func reset_to_arrival() -> void:
	battery_module_count = 2
	storage_efficiency = 1.0
	_recompute_battery_capacity()
	current_energy = 50.0
	solar_panel_count = 2
	solar_array_status = SystemStatus.CRITICAL
	charging_efficiency = 1.0
	current_power_mode = "standard"
	current_energy = clamp(current_energy, 0.0, battery_capacity)
	_save_state()
	_sync_base_status_power()
	power_system_changed.emit()

## "月昼结束电量：200–240 E" target from the design doc's Day 08-21 section.
func set_minimum_stable_state() -> void:
	battery_module_count = 4
	storage_efficiency = 1.0
	_recompute_battery_capacity()
	current_energy = 220.0
	solar_panel_count = 4
	solar_array_status = SystemStatus.STABLE
	charging_efficiency = 1.0
	current_energy = clamp(current_energy, 0.0, battery_capacity)
	_save_state()
	_sync_base_status_power()
	power_system_changed.emit()

func _recompute_battery_capacity() -> void:
	base_battery_capacity = float(battery_module_count) * BATTERY_CAPACITY_PER_MODULE
	battery_capacity = base_battery_capacity * storage_efficiency
	current_energy = clamp(current_energy, 0.0, battery_capacity)

## Called by TimeManager before BaseStatusManager settles, so the freshly
## computed power_percent is what the rest of this tick's systems read.
func advance_power_time(minutes: int) -> void:
	if minutes <= 0:
		return
	var hours := float(minutes) / 60.0
	var is_daylight := _is_daylight()
	var load := _total_power_load()
	var solar := _solar_generation(is_daylight)
	current_energy += (solar - load) * hours
	current_energy = clamp(current_energy, 0.0, battery_capacity)
	_sync_base_status_power()
	_save_state()
	power_system_changed.emit()

## One-time action costs (section 14). Called by TimeManager alongside
## HealthManager.apply_action_cost(), after the hourly settlement above.
func apply_action_cost(action_id: String) -> void:
	var cost := _action_power_cost(action_id)
	if cost <= 0.0:
		return
	current_energy = clamp(current_energy - cost, 0.0, battery_capacity)
	_sync_base_status_power()
	_save_state()
	power_system_changed.emit()

func _action_power_cost(action_id: String) -> float:
	match action_id:
		"send_report", "send_report_positive", "send_report_negative":
			return 0.5
		"entertainment_short":
			return 0.8
		"entertainment_long":
			return 1.5
		"repair_light":
			return 0.3
		"repair_heavy":
			return 0.8
		"organize_supplies":
			return 0.1
		"plant_diagnosis", "plant_diagnosis_positive", "plant_diagnosis_negative":
			return 0.1
		"explore_short":
			return 0.5
		"explore_long":
			return 1.0
	return 0.0

func _total_power_load() -> float:
	return BASE_MINIMUM_LOAD + _air_power_load() + _thermal_power_load() + _greenhouse_light_power_load()

func _solar_generation(is_daylight: bool) -> float:
	if not is_daylight:
		return 0.0
	return float(solar_panel_count) * SOLAR_OUTPUT_PER_PANEL * _solar_array_multiplier() * charging_efficiency

func _solar_array_multiplier() -> float:
	match solar_array_status:
		SystemStatus.OFFLINE:
			return 0.0
		SystemStatus.CRITICAL:
			return 0.35
		SystemStatus.BASIC:
			return 0.70
		SystemStatus.STABLE:
			return 1.00
	return 0.0

func get_power_percent() -> float:
	if battery_capacity <= 0.0:
		return 0.0
	return clamp(current_energy / battery_capacity * 100.0, 0.0, 100.0)

func _sync_base_status_power() -> void:
	var manager := _base_status_manager()
	if manager == null or not manager.has_method("set_power_percent"):
		return
	manager.call("set_power_percent", get_power_percent())

## -- Display labels

func get_power_label() -> String:
	var percent := get_power_percent()
	if percent >= 70.0:
		return "供电稳定"
	if percent >= 40.0:
		return "供电紧张"
	if percent >= 20.0:
		return "低电力"
	if percent >= 5.0:
		return "电力危机"
	return "断电边缘"

func get_solar_array_label() -> String:
	match solar_array_status:
		SystemStatus.OFFLINE:
			return "离线"
		SystemStatus.CRITICAL:
			return "危急"
		SystemStatus.BASIC:
			return "基础运行"
		SystemStatus.STABLE:
			return "稳定运行"
	return "未知"

func get_storage_efficiency_label() -> String:
	match storage_efficiency:
		1.0:
			return "基础储能"
		1.15:
			return "改良电池管理"
		1.30:
			return "高密度储能模块"
		1.50:
			return "月面低温储能优化"
		1.80:
			return "先进储能网络"
	return "自定义"

func get_charging_efficiency_label() -> String:
	match charging_efficiency:
		1.0:
			return "基础充电控制"
		1.15:
			return "太阳能追踪算法"
		1.25:
			return "月尘清洁涂层"
		1.40:
			return "高效功率调节器"
		1.60:
			return "先进太阳能阵列管理"
	return "自定义"

func _format_hours(hours: float) -> String:
	if hours < 0.0:
		return "未知"
	var total_hours := int(ceil(hours))
	var days := int(total_hours / 24)
	var rem_hours := total_hours % 24
	if days > 0:
		return "约 %d 天 %d 小时" % [days, rem_hours]
	return "约 %d 小时" % rem_hours

func _estimate_text(net: float) -> String:
	if net > 0.001 and current_energy < battery_capacity - 0.001:
		return "预计充满：%s" % _format_hours((battery_capacity - current_energy) / net)
	if net < -0.001 and current_energy > 0.001:
		return "预计耗尽：%s" % _format_hours(current_energy / -net)
	if current_energy >= battery_capacity - 0.001:
		return "电量已满"
	return "电量趋于稳定"

func _low_power_warnings() -> Array[String]:
	var warnings: Array[String] = []
	var percent := get_power_percent()
	if percent < 20.0 and _has_high_drain_enabled():
		warnings.append("警告：电量偏低，当前仍在运行应急供氧 / 强温控 / 高等级补光等高耗电设置，建议降低负载。")
	if percent < 5.0:
		warnings.append("建议：电量接近枯竭，建议切换到最低维持模式（关闭高耗电设备）。")
	return warnings

func _has_high_drain_enabled() -> bool:
	var air_manager := _air_system_manager()
	if air_manager != null and String(air_manager.get("supply_target_mode")) == "emergency":
		return true
	var base_manager := _base_status_manager()
	if base_manager != null and int(base_manager.get("thermal_control_status")) == SystemStatus.STABLE:
		return true
	var plant_manager := _plant_growth_manager()
	if plant_manager != null and int(plant_manager.get("greenhouse_light_system_level")) >= 4:
		return true
	return false

func panel_status_text() -> String:
	var is_daylight := _is_daylight()
	var load := _total_power_load()
	var solar := _solar_generation(is_daylight)
	var net := solar - load
	var lines: Array[String] = [
		"广寒前哨电力状态",
		"",
		"当前电量：%.1f E" % current_energy,
		"电池容量：%.0f E" % battery_capacity,
		"当前负载：%.2f E/h" % load,
		"太阳能输入：%.2f E/h" % solar,
		"净变化：%+.2f E/h" % net,
		_estimate_text(net),
		"",
		"太阳能板：%d 块（%s）" % [solar_panel_count, get_solar_array_label()],
		"电池模块：%d 个" % battery_module_count,
		"储能效率：×%.2f（%s）" % [storage_efficiency, get_storage_efficiency_label()],
		"充电效率：×%.2f（%s）" % [charging_efficiency, get_charging_efficiency_label()],
	]
	for warning in _low_power_warnings():
		lines.append("")
		lines.append(warning)
	var hint := get_specialist_hint()
	if not hint.is_empty():
		lines.append("")
		lines.append(hint)
	return "\n".join(lines)

func compact_hud_text() -> String:
	return "电力 %s｜%.0f / %.0f E" % [get_power_label(), current_energy, battery_capacity]

func get_specialist_hint() -> String:
	match _academic_background():
		"机械工程":
			if _is_daylight() and current_energy >= battery_capacity - 0.001:
				return "专业判断：\n白昼发电已经多次溢出，继续增加太阳能板收益有限。建议优先扩展电池容量。"
			if battery_capacity >= 180.0 and solar_array_status != SystemStatus.STABLE:
				return "专业判断：\n电池容量足够，但太阳能输入太低。建议优先修复太阳能阵列。"
		"材料科学":
			if solar_array_status != SystemStatus.STABLE:
				return "专业判断：\n太阳能板输出低于理论值，可能与月尘覆盖或阵列表面老化有关。"
		"医学":
			if get_power_percent() < 40.0:
				return "专业判断：\n继续维持省电模式会降低温控与空气处理能力，预计会增加精力消耗。"
		"植物科学":
			var plant_manager := _plant_growth_manager()
			if plant_manager != null:
				var light_level := int(plant_manager.get("greenhouse_light_system_level"))
				if not _is_daylight() and light_level >= 3:
					var net := _solar_generation(false) - _total_power_load()
					if net < 0.0 and current_energy > 0.0 and (current_energy / -net) < 240.0:
						return "专业判断：\n当前月夜储能不足以长期维持 %d 级补光，小麦和番茄可能进入光照不足。" % light_level
	return ""

## -- Cross-system load reporting (each source manager reports its own draw)

func _air_power_load() -> float:
	var manager := _air_system_manager()
	if manager == null or not manager.has_method("get_air_power_load"):
		return 0.0
	return float(manager.call("get_air_power_load"))

func _thermal_power_load() -> float:
	var manager := _base_status_manager()
	if manager == null or not manager.has_method("get_thermal_power_load"):
		return 0.0
	return float(manager.call("get_thermal_power_load"))

func _greenhouse_light_power_load() -> float:
	var manager := _plant_growth_manager()
	if manager == null or not manager.has_method("get_greenhouse_light_power_load"):
		return 0.0
	return float(manager.call("get_greenhouse_light_power_load"))

## -- Debug helpers

func debug_adjust_energy(delta: float) -> void:
	current_energy = clamp(current_energy + delta, 0.0, battery_capacity)
	_sync_base_status_power()
	_save_state()
	power_system_changed.emit()

func debug_set_battery_module_count(count: int) -> void:
	battery_module_count = max(1, count)
	_recompute_battery_capacity()
	_sync_base_status_power()
	_save_state()
	power_system_changed.emit()

func debug_add_battery_module() -> void:
	debug_set_battery_module_count(battery_module_count + 1)

func debug_set_solar_panel_count(count: int) -> void:
	solar_panel_count = max(0, count)
	_save_state()
	power_system_changed.emit()

func debug_add_solar_panel() -> void:
	debug_set_solar_panel_count(solar_panel_count + 1)

func debug_cycle_solar_array_status() -> void:
	match solar_array_status:
		SystemStatus.CRITICAL:
			solar_array_status = SystemStatus.BASIC
		SystemStatus.BASIC:
			solar_array_status = SystemStatus.STABLE
		_:
			solar_array_status = SystemStatus.CRITICAL
	_save_state()
	power_system_changed.emit()

func debug_cycle_storage_efficiency() -> void:
	var index := STORAGE_EFFICIENCY_TIERS.find(storage_efficiency)
	if index < 0:
		index = 0
	storage_efficiency = STORAGE_EFFICIENCY_TIERS[(index + 1) % STORAGE_EFFICIENCY_TIERS.size()]
	_recompute_battery_capacity()
	_sync_base_status_power()
	_save_state()
	power_system_changed.emit()

func debug_cycle_charging_efficiency() -> void:
	var index := CHARGING_EFFICIENCY_TIERS.find(charging_efficiency)
	if index < 0:
		index = 0
	charging_efficiency = CHARGING_EFFICIENCY_TIERS[(index + 1) % CHARGING_EFFICIENCY_TIERS.size()]
	_save_state()
	power_system_changed.emit()

func debug_set_power_mode(mode_id: String) -> void:
	if not POWER_MODE_PRESETS.has(mode_id):
		return
	var preset: Dictionary = POWER_MODE_PRESETS[mode_id]
	current_power_mode = mode_id
	var air_manager := _air_system_manager()
	if air_manager != null and air_manager.has_method("debug_set_supply_target"):
		air_manager.call("debug_set_supply_target", String(preset.get("supply_target", "standard")))
	var plant_manager := _plant_growth_manager()
	if plant_manager != null and plant_manager.has_method("debug_set_light_system_level"):
		plant_manager.call("debug_set_light_system_level", int(preset.get("light_level", 0)))
	_save_state()
	power_system_changed.emit()

func debug_values_text() -> String:
	return "Energy: %.1f / %.0f (%.1f%%)\nSolarPanels: %d (%s)\nBatteryModules: %d\nStorageEff: x%.2f\nChargingEff: x%.2f\nMode: %s" % [
		current_energy, battery_capacity, get_power_percent(),
		solar_panel_count, get_solar_array_label(),
		battery_module_count,
		storage_efficiency, charging_efficiency,
		current_power_mode,
	]

## -- Persistence

func serialize() -> Dictionary:
	return {
		"current_energy": current_energy,
		"base_battery_capacity": base_battery_capacity,
		"battery_capacity": battery_capacity,
		"battery_module_count": battery_module_count,
		"solar_panel_count": solar_panel_count,
		"solar_array_status": solar_array_status,
		"storage_efficiency": storage_efficiency,
		"charging_efficiency": charging_efficiency,
		"current_power_mode": current_power_mode,
	}

func deserialize(data: Dictionary) -> void:
	battery_module_count = int(data.get("battery_module_count", battery_module_count))
	storage_efficiency = float(data.get("storage_efficiency", storage_efficiency))
	base_battery_capacity = float(data.get("base_battery_capacity", float(battery_module_count) * BATTERY_CAPACITY_PER_MODULE))
	battery_capacity = float(data.get("battery_capacity", base_battery_capacity * storage_efficiency))
	current_energy = float(data.get("current_energy", current_energy))
	solar_panel_count = int(data.get("solar_panel_count", solar_panel_count))
	solar_array_status = int(data.get("solar_array_status", solar_array_status))
	charging_efficiency = float(data.get("charging_efficiency", charging_efficiency))
	current_power_mode = String(data.get("current_power_mode", current_power_mode))
	current_energy = clamp(current_energy, 0.0, battery_capacity)
	power_system_changed.emit()

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

func _is_daylight() -> bool:
	var manager := _time_manager()
	if manager == null:
		return false
	return String(manager.get("lunar_phase")) == "daylight"

func _time_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TimeManager")

func _base_status_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("BaseStatusManager")

func _air_system_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("AirSystemManager")

func _plant_growth_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("PlantGrowthManager")

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
