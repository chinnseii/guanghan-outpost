extends Node
class_name GuanghanWaterSystemManager

signal water_system_changed

const SAVE_PATH := "user://saves/water_system_state.json"
const APPLICATION_PROFILE_PATH := "user://saves/application_profile.json"

const WATER_PER_TANK_MODULE := 40.0
const ICE_PER_STORAGE_MODULE := 60.0
const ICE_TO_WATER_RATIO := 1.0
const ICE_PROCESSING_POWER_PER_UNIT := 0.05

const LIFE_WATER_PER_HOUR := 0.025
const EAT_WATER_COST := 0.10
const NUTRITION_DRINK_WATER_COST := 0.20
const PLANT_WATER_PER_REQUIREMENT_LEVEL := 0.35

## Base recovery rate per recycling tier (0-4); multiplied by
## water_recycling_efficiency and capped at RECYCLING_RATE_CAP.
const RECYCLING_BASE_RATES := [0.0, 0.15, 0.30, 0.45, 0.60]
const RECYCLING_RATE_CAP := 0.80
const RECYCLING_POWER_LOAD := [0.0, 0.02, 0.04, 0.07, 0.11]

var current_water: float = 42.0
var water_capacity: float = 80.0
var current_ice: float = 0.0
var ice_capacity: float = 120.0
var water_tank_module_count: int = 2
var ice_storage_module_count: int = 2
var water_recycling_level: int = 1
var water_recycling_efficiency: float = 1.0
var ice_processing_efficiency: float = 1.0

## Transient — not persisted; recomputed each tick, safe to reset on load.
var _life_water_shortfall_hours: float = 0.0
var _oxygen_water_satisfaction: float = 1.0

func _ready() -> void:
	load_state()

func reset_to_arrival() -> void:
	water_tank_module_count = 2
	ice_storage_module_count = 2
	water_recycling_level = 1
	water_recycling_efficiency = 1.0
	ice_processing_efficiency = 1.0
	_recompute_capacities()
	current_water = 42.0
	current_ice = 0.0
	_life_water_shortfall_hours = 0.0
	_oxygen_water_satisfaction = 1.0
	clamp_water_values()
	_save_state()
	water_system_changed.emit()

## "第一轮月夜基础目标" reference point from the design doc's tank table (3
## modules / 120 W) plus a modest ice buffer and recycling already at BASIC.
func set_minimum_stable_state() -> void:
	water_tank_module_count = 3
	ice_storage_module_count = 3
	water_recycling_level = 2
	_recompute_capacities()
	current_water = 100.0
	current_ice = 60.0
	clamp_water_values()
	_save_state()
	water_system_changed.emit()

func _recompute_capacities() -> void:
	water_capacity = float(water_tank_module_count) * WATER_PER_TANK_MODULE
	ice_capacity = float(ice_storage_module_count) * ICE_PER_STORAGE_MODULE
	clamp_water_values()

func clamp_water_values() -> void:
	current_water = clamp(current_water, 0.0, water_capacity)
	current_ice = clamp(current_ice, 0.0, ice_capacity)

func get_effective_recycling_rate() -> float:
	var base_rate: float = RECYCLING_BASE_RATES[clamp(water_recycling_level, 0, 4)]
	return min(base_rate * water_recycling_efficiency, RECYCLING_RATE_CAP)

## Called by TimeManager before AirSystemManager settles, so this tick's
## oxygen-water satisfaction ratio is ready when AirSystemManager reads it.
func advance_water_time(minutes: int) -> void:
	if minutes <= 0:
		return
	var hours := float(minutes) / 60.0
	_apply_life_water(hours)
	_apply_oxygen_water(hours)
	clamp_water_values()
	_apply_health_environment_effects(hours)
	_save_state()
	water_system_changed.emit()

## Recyclable: the recycling rate discounts the actual reserve draw.
func _apply_life_water(hours: float) -> void:
	var need := LIFE_WATER_PER_HOUR * hours
	var actual_cost := need * (1.0 - get_effective_recycling_rate())
	if current_water >= actual_cost:
		current_water -= actual_cost
		_life_water_shortfall_hours = 0.0
	else:
		current_water = 0.0
		_life_water_shortfall_hours += hours

## Non-recyclable. When water can't cover the full need, only the covered
## fraction is tracked as "satisfaction" for AirSystemManager to throttle its
## O2 generator output by — see get_oxygen_water_satisfaction().
func _apply_oxygen_water(hours: float) -> void:
	var need := _oxygen_water_load() * hours
	if need <= 0.0:
		_oxygen_water_satisfaction = 1.0
		return
	var withdrawn: float = min(current_water, need)
	current_water -= withdrawn
	_oxygen_water_satisfaction = clamp(withdrawn / need, 0.0, 1.0)

func _oxygen_water_load() -> float:
	var manager := _air_system_manager()
	if manager == null or not manager.has_method("get_water_load"):
		return 0.0
	return float(manager.call("get_water_load"))

## Consulted by AirSystemManager._apply_o2_change(); defaults to 1.0 (no
## throttling) when absent, so behavior is unchanged if this manager is missing.
func get_oxygen_water_satisfaction() -> float:
	return _oxygen_water_satisfaction

func _apply_health_environment_effects(hours: float) -> void:
	var health_manager := _health_manager()
	if health_manager == null or not health_manager.has_method("adjust_stat"):
		return
	if _life_water_shortfall_hours >= 24.0:
		health_manager.call("adjust_stat", "morale", -2.0 / 24.0 * hours)

## One-time action costs (eat / nutrition_drink). Called by TimeManager
## alongside HealthManager/PowerSystemManager's own action-cost hooks. Best
## effort / no hard gate on the action itself — see docs for known gaps.
func apply_action_cost(action_id: String) -> void:
	var cost := _action_water_cost(action_id)
	if cost <= 0.0:
		return
	var actual_cost := cost * (1.0 - get_effective_recycling_rate())
	current_water = clamp(current_water - actual_cost, 0.0, water_capacity)
	_save_state()
	water_system_changed.emit()

func _action_water_cost(action_id: String) -> float:
	match action_id:
		"eat":
			return EAT_WATER_COST
		"nutrition_drink":
			return NUTRITION_DRINK_WATER_COST
	return 0.0

## -- Plant supply (called from PlantGrowthManager's own daily settlement)

## Pure peek for UI/scoring display — never mutates state. Checks against the
## *discounted* cost (post-recycling), matching consume_plant_water() below.
func can_supply_plant_water(amount: float) -> bool:
	var actual_cost := amount * (1.0 - get_effective_recycling_rate())
	return current_water >= actual_cost

## The real, once-per-day-per-plant withdrawal. Recyclable.
func consume_plant_water(amount: float) -> bool:
	var actual_cost := amount * (1.0 - get_effective_recycling_rate())
	if current_water < actual_cost:
		return false
	current_water = clamp(current_water - actual_cost, 0.0, water_capacity)
	_save_state()
	water_system_changed.emit()
	return true

## -- Ice collection / processing

## External collection systems (not owned by this manager) call this with
## however much ice the player brought back; only the amount that fits is
## accepted.
func add_ice(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var accepted: float = clamp(amount, 0.0, ice_capacity - current_ice)
	current_ice += accepted
	_save_state()
	water_system_changed.emit()
	return accepted

func add_water(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var accepted: float = clamp(amount, 0.0, water_capacity - current_water)
	current_water += accepted
	_save_state()
	water_system_changed.emit()
	return accepted

## On-demand action (not part of the hourly tick): converts up to
## requested_amount of ice into water at a fixed 1:1 ratio, limited by
## available ice, free tank space, and current power. Returns the amount
## actually processed.
func process_ice(requested_amount: float) -> float:
	if requested_amount <= 0.0:
		return 0.0
	var cost_per_unit: float = ICE_PROCESSING_POWER_PER_UNIT / max(ice_processing_efficiency, 0.0001)
	var power_manager := _power_system_manager()
	var power_available := 0.0
	if power_manager != null:
		power_available = float(power_manager.get("current_energy"))
	var power_afforded: float = (power_available / cost_per_unit) if cost_per_unit > 0.0 else 0.0
	var processable: float = min(requested_amount, current_ice)
	processable = min(processable, water_capacity - current_water)
	processable = min(processable, power_afforded)
	processable = max(0.0, processable)
	if processable <= 0.0:
		return 0.0
	current_ice -= processable
	current_water += processable * ICE_TO_WATER_RATIO
	if power_manager != null and power_manager.has_method("consume_energy"):
		power_manager.call("consume_energy", processable * cost_per_unit)
	clamp_water_values()
	_save_state()
	water_system_changed.emit()
	return processable

## -- Power reporting (consulted by PowerSystemManager._total_power_load())

func get_water_power_load() -> float:
	return RECYCLING_POWER_LOAD[clamp(water_recycling_level, 0, 4)]

## -- Display labels

func get_water_percent() -> float:
	if water_capacity <= 0.0:
		return 0.0
	return clamp(current_water / water_capacity * 100.0, 0.0, 100.0)

func get_water_label() -> String:
	var percent := get_water_percent()
	if percent >= 70.0:
		return "水储备稳定"
	if percent >= 40.0:
		return "水储备紧张"
	if percent >= 20.0:
		return "低水量"
	if percent >= 5.0:
		return "水危机"
	return "水耗尽边缘"

func _format_days(days: float) -> String:
	if days < 0.0:
		return "未知"
	return "约 %d 天" % int(ceil(days))

## Display-only forecast; does not mutate state. Combines the hourly life/
## oxygen costs (x24) with today's plant water demand into one daily figure.
func _daily_water_forecast() -> Dictionary:
	var life_daily := LIFE_WATER_PER_HOUR * 24.0
	var oxygen_daily := _oxygen_water_load() * 24.0
	var plant_daily := _plant_daily_water_need()
	var recyclable := life_daily + plant_daily
	var non_recyclable := oxygen_daily
	var rate := get_effective_recycling_rate()
	var net := recyclable * (1.0 - rate) + non_recyclable
	return {"gross": recyclable + non_recyclable, "net": net}

func _plant_daily_water_need() -> float:
	var manager := _plant_growth_manager()
	if manager == null or not manager.has_method("get_daily_water_demand"):
		return 0.0
	return float(manager.call("get_daily_water_demand"))

func _estimate_days_text(net_per_day: float) -> String:
	if net_per_day <= 0.001:
		return "预计耗尽：无净消耗"
	if current_water <= 0.0:
		return "预计耗尽：已耗尽"
	return "预计耗尽：%s" % _format_days(current_water / net_per_day)

func panel_status_text() -> String:
	var forecast := _daily_water_forecast()
	var lines: Array[String] = [
		"广寒前哨水资源状态",
		"",
		"当前可用水：%.1f W" % current_water,
		"可用水上限：%.0f W" % water_capacity,
		"当前月球冰：%.1f I" % current_ice,
		"冰仓上限：%.0f I" % ice_capacity,
		"",
		"今日预计耗水：%.2f W" % float(forecast.get("gross", 0.0)),
		"水循环等级：%d" % water_recycling_level,
		"水循环回收率：%d%%" % int(round(get_effective_recycling_rate() * 100.0)),
		"预计净耗水：%.2f W / 天" % float(forecast.get("net", 0.0)),
		_estimate_days_text(float(forecast.get("net", 0.0))),
		"冰处理效率：×%.2f" % ice_processing_efficiency,
		"处理 1 I 冰耗电：%.3f E" % (ICE_PROCESSING_POWER_PER_UNIT / max(ice_processing_efficiency, 0.0001)),
	]
	if get_water_percent() < 20.0:
		lines.append("")
		lines.append("警告：水量偏低，充足/应急供氧与高耗水作物供水会持续消耗紧张的储备。")
	if get_water_percent() < 5.0:
		lines.append("建议：切换到节水模式（降低供氧目标、暂缓高耗水作物）。")
	var hint := get_specialist_hint()
	if not hint.is_empty():
		lines.append("")
		lines.append(hint)
	return "\n".join(lines)

func compact_hud_text() -> String:
	return "水 %s｜%.0f / %.0f W" % [get_water_label(), current_water, water_capacity]

func get_specialist_hint() -> String:
	match _academic_background():
		"植物科学":
			if get_water_percent() < 40.0 and _has_high_water_crop_planted():
				return "专业判断：\n当前水储备只适合低水需求作物，不建议继续种番茄。"
			if water_recycling_level <= 1:
				return "专业判断：\n如果维持当前水循环等级，生菜和小麦可以继续生长，但番茄会成为主要耗水点。"
		"机械工程":
			if water_recycling_level >= 3 and _power_percent() < 40.0:
				return "专业判断：\n水循环等级过高，当前电力不足以长期维持。建议月夜降至基础回收。"
			if current_ice > 0.0 and (water_capacity - current_water) > 0.0 and _power_percent() < 20.0:
				return "专业判断：\n当前瓶颈不是水量，而是冰处理耗电。"
		"材料科学":
			if get_water_percent() < 70.0 or (ice_capacity > 0.0 and current_ice / ice_capacity < 0.7):
				return "专业判断：\n水箱模块老化可能导致储水安全裕度下降。冰仓隔热状态会影响处理效率。"
		"医学":
			if get_water_percent() < 40.0:
				return "专业判断：\n水储备不足会影响营养液调配。当前不建议继续进行高消耗外出行动。"
	return ""

func _has_high_water_crop_planted() -> bool:
	var manager := _plant_growth_manager()
	if manager == null or not manager.has_method("get_highest_planted_water_requirement"):
		return false
	return int(manager.call("get_highest_planted_water_requirement")) >= 3

func _power_percent() -> float:
	var manager := _power_system_manager()
	if manager == null or not manager.has_method("get_power_percent"):
		return 100.0
	return float(manager.call("get_power_percent"))

## -- Debug helpers

func debug_adjust_water(delta: float) -> void:
	current_water = clamp(current_water + delta, 0.0, water_capacity)
	_save_state()
	water_system_changed.emit()

func debug_adjust_ice(delta: float) -> void:
	current_ice = clamp(current_ice + delta, 0.0, ice_capacity)
	_save_state()
	water_system_changed.emit()

func debug_set_water_tank_module_count(count: int) -> void:
	water_tank_module_count = max(1, count)
	_recompute_capacities()
	_save_state()
	water_system_changed.emit()

func debug_add_water_tank_module() -> void:
	debug_set_water_tank_module_count(water_tank_module_count + 1)

func debug_set_ice_storage_module_count(count: int) -> void:
	ice_storage_module_count = max(1, count)
	_recompute_capacities()
	_save_state()
	water_system_changed.emit()

func debug_add_ice_storage_module() -> void:
	debug_set_ice_storage_module_count(ice_storage_module_count + 1)

func debug_cycle_recycling_level() -> void:
	water_recycling_level = (water_recycling_level + 1) % 5
	_save_state()
	water_system_changed.emit()

## Matches the design doc's own worked example ("处理 20 I 月球冰").
func debug_process_ice_batch() -> void:
	process_ice(20.0)

func debug_process_all_ice() -> void:
	process_ice(current_ice)

func debug_values_text() -> String:
	return "Water: %.1f / %.0f (%.1f%%)\nIce: %.1f / %.0f\nRecyclingLevel: %d (rate=%.0f%%)\nTankModules: %d\nIceModules: %d\nIceProcessingEff: x%.2f" % [
		current_water, water_capacity, get_water_percent(),
		current_ice, ice_capacity,
		water_recycling_level, get_effective_recycling_rate() * 100.0,
		water_tank_module_count,
		ice_storage_module_count,
		ice_processing_efficiency,
	]

## -- Persistence

func serialize() -> Dictionary:
	return {
		"current_water": current_water,
		"water_capacity": water_capacity,
		"water_tank_module_count": water_tank_module_count,
		"current_ice": current_ice,
		"ice_capacity": ice_capacity,
		"ice_storage_module_count": ice_storage_module_count,
		"water_recycling_level": water_recycling_level,
		"water_recycling_efficiency": water_recycling_efficiency,
		"ice_processing_efficiency": ice_processing_efficiency,
	}

func deserialize(data: Dictionary) -> void:
	water_tank_module_count = int(data.get("water_tank_module_count", water_tank_module_count))
	ice_storage_module_count = int(data.get("ice_storage_module_count", ice_storage_module_count))
	water_capacity = float(data.get("water_capacity", float(water_tank_module_count) * WATER_PER_TANK_MODULE))
	ice_capacity = float(data.get("ice_capacity", float(ice_storage_module_count) * ICE_PER_STORAGE_MODULE))
	current_water = float(data.get("current_water", current_water))
	current_ice = float(data.get("current_ice", current_ice))
	water_recycling_level = int(data.get("water_recycling_level", water_recycling_level))
	water_recycling_efficiency = float(data.get("water_recycling_efficiency", water_recycling_efficiency))
	ice_processing_efficiency = float(data.get("ice_processing_efficiency", ice_processing_efficiency))
	clamp_water_values()
	water_system_changed.emit()

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

func _air_system_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("AirSystemManager")

func _power_system_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("PowerSystemManager")

func _plant_growth_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("PlantGrowthManager")

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
