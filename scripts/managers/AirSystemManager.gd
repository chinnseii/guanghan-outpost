extends Node
class_name GuanghanAirSystemManager

const FullSaveOrchestratorScript := preload("res://scripts/systems/full_save_orchestrator.gd")

signal air_system_changed

const SAVE_PATH := "user://saves/air_system_state.json"
const APPLICATION_PROFILE_PATH := "user://saves/application_profile.json"

## Independent from BaseStatusManager.SystemStatus by design so this file has
## no hard dependency on another manager's script.
enum SystemStatus {
	OFFLINE,
	CRITICAL,
	BASIC,
	STABLE,
}

const ARRIVAL_O2 := 20.4
const ARRIVAL_CO2 := 0.42
const ARRIVAL_INERT_RESERVE := 55.0

const HUMAN_O2_CONSUMPTION := -0.015
const PLANT_O2_BONUS := 0.002
const HUMAN_CO2_PRODUCTION := 0.006
const PLANT_CO2_ABSORPTION := -0.001

## v1-authored placeholder rates for the "reserve auto-repressurizes pressure"
## mechanic; the spec left the exact conversion open ("可以自动补压"). Tune
## freely once a system designer wants different pacing.
const REPRESSURIZE_PRESSURE_RATE := 0.15
const REPRESSURIZE_RESERVE_COST := 0.20

const SUPPLY_TARGETS := {
	"off": {"label": "关闭", "target_o2": 0.0, "power_load": 0.0, "water_load": 0.0},
	"eco": {"label": "节能", "target_o2": 19.8, "power_load": 0.03, "water_load": 0.004},
	"standard": {"label": "标准", "target_o2": 21.0, "power_load": 0.06, "water_load": 0.008},
	"rich": {"label": "充足", "target_o2": 22.5, "power_load": 0.10, "water_load": 0.014},
	"emergency": {"label": "应急", "target_o2": 24.0, "power_load": 0.18, "water_load": 0.030},
}
const SUPPLY_TARGET_ORDER := ["off", "eco", "standard", "rich", "emergency"]

var o2_percent: float = ARRIVAL_O2
var co2_percent: float = ARRIVAL_CO2
var inert_gas_percent: float = 100.0 - ARRIVAL_O2 - ARRIVAL_CO2
var inert_gas_reserve: float = ARRIVAL_INERT_RESERVE

var oxygen_generator_status: int = SystemStatus.CRITICAL
var co2_filter_status: int = SystemStatus.CRITICAL
var air_circulation_status: int = SystemStatus.BASIC

## Drives PowerSystemManager's oxygen-generator power draw (see
## get_air_power_load()); does not change generator O2 output rate — that's
## still governed by oxygen_generator_status. Water coupling still reserved.
var supply_target_mode: String = "standard"

func _ready() -> void:
	load_state()

func reset_to_arrival() -> void:
	o2_percent = ARRIVAL_O2
	co2_percent = ARRIVAL_CO2
	inert_gas_reserve = ARRIVAL_INERT_RESERVE
	oxygen_generator_status = SystemStatus.CRITICAL
	co2_filter_status = SystemStatus.CRITICAL
	air_circulation_status = SystemStatus.BASIC
	supply_target_mode = "standard"
	_recompute_inert_gas_percent()
	_save_state()
	air_system_changed.emit()

func set_minimum_stable_state() -> void:
	o2_percent = 21.0
	co2_percent = 0.30
	inert_gas_reserve = 70.0
	oxygen_generator_status = SystemStatus.BASIC
	co2_filter_status = SystemStatus.BASIC
	air_circulation_status = SystemStatus.BASIC
	_recompute_inert_gas_percent()
	_save_state()
	air_system_changed.emit()

func clamp_air_values() -> void:
	o2_percent = clamp(o2_percent, 0.0, 100.0)
	co2_percent = max(0.0, co2_percent)
	inert_gas_reserve = clamp(inert_gas_reserve, 0.0, 100.0)
	_recompute_inert_gas_percent()

func _recompute_inert_gas_percent() -> void:
	inert_gas_percent = max(0.0, 100.0 - o2_percent - co2_percent)

## Called by TimeManager after BaseStatusManager settles. Does not advance time itself.
func advance_air_time(minutes: int) -> void:
	if minutes <= 0:
		return
	var hours := float(minutes) / 60.0
	_apply_o2_change(hours)
	_apply_co2_change(hours)
	_apply_inert_gas_reserve_change(hours)
	clamp_air_values()
	_apply_health_environment_effects(hours)
	_save_state()
	air_system_changed.emit()

func _power_multiplier(power: float) -> float:
	if power >= 70.0:
		return 1.0
	if power >= 40.0:
		return 0.8
	if power >= 20.0:
		return 0.5
	return 0.0

func _apply_o2_change(hours: float) -> void:
	var generator_rate := 0.0
	match oxygen_generator_status:
		SystemStatus.OFFLINE:
			generator_rate = 0.0
		SystemStatus.CRITICAL:
			generator_rate = 0.010
		SystemStatus.BASIC:
			generator_rate = 0.025
		SystemStatus.STABLE:
			generator_rate = 0.040
	generator_rate *= _power_multiplier(_base_status_power())
	generator_rate *= _water_satisfaction_multiplier()
	var plant_bonus := PLANT_O2_BONUS if _last_plant_recovered() else 0.0
	o2_percent += (HUMAN_O2_CONSUMPTION + generator_rate + plant_bonus) * hours

## Throttles generator *output* only (not baseline human consumption) when
## WaterSystemManager couldn't fully cover this tick's oxygen-generator water
## need — "水不足时，关闭/降低制氧输出，O₂ 不再上升".
func _water_satisfaction_multiplier() -> float:
	var manager := _water_system_manager()
	if manager == null or not manager.has_method("get_oxygen_water_satisfaction"):
		return 1.0
	return float(manager.call("get_oxygen_water_satisfaction"))

func _water_system_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("WaterSystemManager")

func _apply_co2_change(hours: float) -> void:
	var filter_rate := 0.0
	match co2_filter_status:
		SystemStatus.OFFLINE:
			filter_rate = 0.0
		SystemStatus.CRITICAL:
			filter_rate = -0.003
		SystemStatus.BASIC:
			filter_rate = -0.008
		SystemStatus.STABLE:
			filter_rate = -0.014
	filter_rate *= _power_multiplier(_base_status_power())
	filter_rate *= _circulation_multiplier()
	var plant_absorption := PLANT_CO2_ABSORPTION if _last_plant_recovered() else 0.0
	co2_percent += (HUMAN_CO2_PRODUCTION + filter_rate + plant_absorption) * hours

func _circulation_multiplier() -> float:
	match air_circulation_status:
		SystemStatus.OFFLINE:
			return 0.5
		SystemStatus.CRITICAL:
			return 0.75
		SystemStatus.BASIC:
			return 1.0
		SystemStatus.STABLE:
			return 1.15
	return 1.0

## v1 only wires seal-driven reserve drain and the "low pressure draws on the
## reserve" repressurization loop. Airlock loss / accident venting are not
## modeled yet (no interaction currently produces them).
func _apply_inert_gas_reserve_change(hours: float) -> void:
	var seal_status := _base_status_seal_status()
	var drain_rate := 0.0
	match seal_status:
		SystemStatus.OFFLINE:
			drain_rate = -0.12
		SystemStatus.CRITICAL:
			drain_rate = -0.04
		SystemStatus.BASIC:
			drain_rate = -0.01
		SystemStatus.STABLE:
			drain_rate = 0.0
	inert_gas_reserve += drain_rate * hours
	var pressure := _base_status_pressure()
	if pressure < 70.0 and inert_gas_reserve > 0.0:
		var reserve_used: float = min(inert_gas_reserve, REPRESSURIZE_RESERVE_COST * hours)
		if reserve_used > 0.0:
			inert_gas_reserve -= reserve_used
			# Scales down gracefully as the reserve runs low, per spec ("接近 0 时舱压更难恢复").
			var pressure_gain: float = reserve_used * (REPRESSURIZE_PRESSURE_RATE / REPRESSURIZE_RESERVE_COST)
			var base_status_manager := _base_status_manager()
			if base_status_manager != null and base_status_manager.has_method("adjust_stat"):
				base_status_manager.call("adjust_stat", "pressure", pressure_gain)
	inert_gas_reserve = clamp(inert_gas_reserve, 0.0, 100.0)

func _apply_health_environment_effects(hours: float) -> void:
	var health_manager := _health_manager()
	if health_manager == null or not health_manager.has_method("adjust_stat"):
		return
	var morale_delta := 0.0
	if o2_percent < 16.0:
		morale_delta -= 0.10 * hours
	elif o2_percent < 18.0:
		morale_delta -= 0.05 * hours
	elif o2_percent < 19.5:
		morale_delta -= 0.02 * hours
	if co2_percent > 3.00:
		morale_delta -= 0.10 * hours
	elif co2_percent > 1.00:
		morale_delta -= 0.05 * hours
	elif co2_percent > 0.50:
		morale_delta -= 0.02 * hours
	if morale_delta != 0.0:
		_route_environment_morale(health_manager, morale_delta, "environment_oxygen_co2")

## Route an ambient (per-hour) morale drain through the central PenaltyManager
## when present (unifies morale penalties under one dispatcher); silent and
## numerically identical to the old direct adjust_stat call, with a direct
## fallback when PenaltyManager isn't loaded.
func _route_environment_morale(health_manager: Node, delta: float, reason: String) -> void:
	if delta == 0.0:
		return
	var penalty_manager := get_node_or_null("/root/PenaltyManager")
	if penalty_manager != null and penalty_manager.has_method("apply_penalty"):
		penalty_manager.call("apply_penalty", {
			"penalty_id": "ambient_environment_morale",
			"display_name": "环境压力",
			"context": "mission",
			"reason": reason,
			"silent": true,
			"health_deltas": {"morale": delta},
		})
		return
	if health_manager != null and health_manager.has_method("adjust_stat"):
		health_manager.call("adjust_stat", "morale", delta)

## Consulted by HealthManager.get_energy_cost_multiplier(); defaults to 1.0 when absent.
## No high-O2 penalty exists by design: exceeding 22% never raises this multiplier.
func get_air_energy_multiplier() -> float:
	return _o2_energy_multiplier() * _co2_energy_multiplier()

func _o2_energy_multiplier() -> float:
	if o2_percent < 16.0:
		return 1.5
	if o2_percent < 18.0:
		return 1.35
	if o2_percent < 19.5:
		return 1.2
	return 1.0

func _co2_energy_multiplier() -> float:
	if co2_percent > 3.00:
		return 1.4
	if co2_percent > 1.00:
		return 1.2
	if co2_percent > 0.50:
		return 1.1
	return 1.0

## -- Power reporting (consulted by PowerSystemManager._air_power_load())

func get_air_power_load() -> float:
	return _oxygen_generator_power_load() + _co2_filter_power_load() + _air_circulation_power_load()

## Draw is driven by the supply *target* (how hard it's being run), not the
## device tier (its condition) — a throttle setting vs. equipment health.
func _oxygen_generator_power_load() -> float:
	return float(SUPPLY_TARGETS.get(supply_target_mode, {}).get("power_load", 0.0))

## -- Water reporting (consulted by WaterSystemManager._oxygen_water_load())

func get_water_load() -> float:
	return float(SUPPLY_TARGETS.get(supply_target_mode, {}).get("water_load", 0.0))

func _co2_filter_power_load() -> float:
	match co2_filter_status:
		SystemStatus.OFFLINE:
			return 0.0
		SystemStatus.CRITICAL:
			return 0.03
		SystemStatus.BASIC:
			return 0.06
		SystemStatus.STABLE:
			return 0.10
	return 0.0

func _air_circulation_power_load() -> float:
	match air_circulation_status:
		SystemStatus.OFFLINE:
			return 0.0
		SystemStatus.CRITICAL:
			return 0.02
		SystemStatus.BASIC:
			return 0.04
		SystemStatus.STABLE:
			return 0.07
	return 0.0

## -- Repair actions: change device tier and apply a one-time instant delta.
## Time cost is not advanced here; the caller advances TimeManager separately.

func repair_oxygen_generator_light() -> void:
	if oxygen_generator_status == SystemStatus.CRITICAL:
		oxygen_generator_status = SystemStatus.BASIC
	o2_percent += 0.4
	_finish_repair()

func repair_oxygen_generator_heavy() -> void:
	if oxygen_generator_status == SystemStatus.BASIC:
		oxygen_generator_status = SystemStatus.STABLE
	o2_percent += 0.6
	_finish_repair()

func repair_co2_filter_light() -> void:
	if co2_filter_status == SystemStatus.CRITICAL:
		co2_filter_status = SystemStatus.BASIC
	co2_percent = max(0.0, co2_percent - 0.10)
	_finish_repair()

func repair_co2_filter_heavy() -> void:
	if co2_filter_status == SystemStatus.BASIC:
		co2_filter_status = SystemStatus.STABLE
	co2_percent = max(0.0, co2_percent - 0.15)
	_finish_repair()

func repair_air_circulation_light() -> void:
	if air_circulation_status == SystemStatus.CRITICAL:
		air_circulation_status = SystemStatus.BASIC
	_finish_repair()

func repair_air_circulation_heavy() -> void:
	if air_circulation_status == SystemStatus.BASIC:
		air_circulation_status = SystemStatus.STABLE
	_finish_repair()

func _finish_repair() -> void:
	clamp_air_values()
	_save_state()
	air_system_changed.emit()

## -- Display labels

func get_o2_label() -> String:
	if o2_percent > 22.0:
		return "供氧过量"
	if o2_percent >= 20.0:
		return "氧气理想"
	if o2_percent >= 19.5:
		return "氧气偏低"
	if o2_percent >= 18.0:
		return "缺氧"
	if o2_percent >= 16.0:
		return "严重缺氧"
	return "氧气危机"

func get_co2_label() -> String:
	if co2_percent <= 0.30:
		return "空气清洁"
	if co2_percent <= 0.50:
		return "CO₂偏高"
	if co2_percent <= 1.00:
		return "CO₂积累"
	if co2_percent <= 3.00:
		return "CO₂危险"
	if co2_percent <= 4.00:
		return "CO₂紧急"
	return "CO₂危机"

func get_inert_gas_reserve_label() -> String:
	if inert_gas_reserve >= 70.0:
		return "缓冲气体充足"
	if inert_gas_reserve >= 40.0:
		return "缓冲气体紧张"
	if inert_gas_reserve >= 20.0:
		return "缓冲气体不足"
	return "缓冲气体危机"

func get_system_status_label(status: int) -> String:
	match status:
		SystemStatus.OFFLINE:
			return "离线"
		SystemStatus.CRITICAL:
			return "危急"
		SystemStatus.BASIC:
			return "基础运行"
		SystemStatus.STABLE:
			return "稳定运行"
	return "未知"

func get_supply_target_label() -> String:
	return String(SUPPLY_TARGETS.get(supply_target_mode, {}).get("label", "标准"))

func panel_status_text() -> String:
	var lines: Array[String] = [
		"广寒前哨空气状态",
		"",
		"O₂：%s  %.1f%%" % [get_o2_label(), o2_percent],
		"CO₂：%s  %.2f%%" % [get_co2_label(), co2_percent],
		"惰性缓冲气体：%.1f%%" % inert_gas_percent,
		"惰性气体储备：%s  %d%%" % [get_inert_gas_reserve_label(), int(round(inert_gas_reserve))],
		"",
		"供氧目标：%s（耗电 %.2f E/h，尚未接入耗水）" % [get_supply_target_label(), _oxygen_generator_power_load()],
		"",
		"设备状态：",
		"制氧模块：%s" % get_system_status_label(oxygen_generator_status),
		"CO₂过滤模块：%s" % get_system_status_label(co2_filter_status),
		"空气循环系统：%s" % get_system_status_label(air_circulation_status),
	]
	if o2_percent > 22.0:
		lines.append("")
		lines.append("当前供氧高于生活需求，水电消耗增加。")
	if o2_percent < 16.0 or co2_percent > 3.00:
		lines.append("")
		lines.append("警告：空气质量危险，高消耗行动风险显著上升。")
	var hint := get_specialist_hint()
	if not hint.is_empty():
		lines.append("")
		lines.append(hint)
	return "\n".join(lines)

func compact_hud_text() -> String:
	return "空气状态：O₂ %s · CO₂ %s" % [get_o2_label(), get_co2_label()]

## Plant-science background note is always shown (informational baseline, not
## condition-gated) since the point is "plants can't replace the air system"
## regardless of current numbers.
func get_specialist_hint() -> String:
	match _academic_background():
		"医学":
			if co2_percent > 0.50 and o2_percent >= 19.5:
				return "专业判断：\nCO₂已超过安全上限。即使氧气仍在正常范围，睡眠恢复也会受到影响。"
			if o2_percent < 19.5 or co2_percent > 0.50:
				return "专业判断：\n低氧和 CO₂积累都会增加精力消耗，并影响睡眠恢复质量。建议先判断当前该睡觉、补氧，还是处理 CO₂过滤。"
		"机械工程":
			if _base_status_power() < 70.0 and (oxygen_generator_status != SystemStatus.STABLE or co2_filter_status != SystemStatus.STABLE or air_circulation_status != SystemStatus.STABLE):
				return "专业判断：\n当前 CO₂过滤效率下降的主因不是滤芯损坏，而是供电不足。制氧、过滤与空气循环都依赖稳定电力。"
			if oxygen_generator_status != SystemStatus.STABLE or co2_filter_status != SystemStatus.STABLE or air_circulation_status != SystemStatus.STABLE:
				return "专业判断：\n制氧模块、CO₂过滤模块与空气循环系统尚未全部稳定运行，建议逐一恢复。"
		"材料科学":
			if _base_status_pressure() < 80.0 or _base_status_seal_status() != SystemStatus.STABLE or inert_gas_reserve < 70.0:
				return "专业判断：\n当前空气异常可能并非制氧不足，而是密封泄漏导致惰性缓冲气体持续损失。"
		"植物科学":
			return "专业判断：\n当前植物规模只能提供微弱缓冲，不能替代 CO₂过滤模块。"
	return ""

## -- Debug helpers

func adjust_stat(stat_name: String, delta: float) -> void:
	match stat_name:
		"o2_percent":
			o2_percent += delta
		"co2_percent":
			co2_percent += delta
		"inert_gas_reserve":
			inert_gas_reserve += delta
	clamp_air_values()
	_save_state()
	air_system_changed.emit()

func debug_set_system_status(system_name: String, status_name: String) -> void:
	var status := _status_from_name(status_name)
	match system_name:
		"oxygen_generator_status":
			oxygen_generator_status = status
		"co2_filter_status":
			co2_filter_status = status
		"air_circulation_status":
			air_circulation_status = status
	_save_state()
	air_system_changed.emit()

func debug_cycle_supply_target() -> void:
	var index := SUPPLY_TARGET_ORDER.find(supply_target_mode)
	supply_target_mode = SUPPLY_TARGET_ORDER[(index + 1) % SUPPLY_TARGET_ORDER.size()]
	_save_state()
	air_system_changed.emit()

func debug_set_supply_target(mode_id: String) -> void:
	if not SUPPLY_TARGETS.has(mode_id):
		return
	supply_target_mode = mode_id
	_save_state()
	air_system_changed.emit()

func debug_values_text() -> String:
	return "O2: %.2f%% (%s)\nCO2: %.2f%% (%s)\nInertPercent: %.2f%%\nInertReserve: %.0f%% (%s)\nSupplyTarget: %s" % [
		o2_percent, get_system_status_label(oxygen_generator_status),
		co2_percent, get_system_status_label(co2_filter_status),
		inert_gas_percent,
		inert_gas_reserve, get_system_status_label(air_circulation_status),
		get_supply_target_label(),
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
		"o2_percent": o2_percent,
		"co2_percent": co2_percent,
		"inert_gas_reserve": inert_gas_reserve,
		"oxygen_generator_status": oxygen_generator_status,
		"co2_filter_status": co2_filter_status,
		"air_circulation_status": air_circulation_status,
		"supply_target_mode": supply_target_mode,
	}

func deserialize(data: Dictionary) -> void:
	o2_percent = float(data.get("o2_percent", o2_percent))
	co2_percent = float(data.get("co2_percent", co2_percent))
	inert_gas_reserve = float(data.get("inert_gas_reserve", inert_gas_reserve))
	oxygen_generator_status = int(data.get("oxygen_generator_status", oxygen_generator_status))
	co2_filter_status = int(data.get("co2_filter_status", co2_filter_status))
	air_circulation_status = int(data.get("air_circulation_status", air_circulation_status))
	supply_target_mode = String(data.get("supply_target_mode", supply_target_mode))
	clamp_air_values()
	air_system_changed.emit()

func load_state() -> void:
	if FullSaveOrchestratorScript.should_skip_manager_local_restore():
		return
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

func _base_status_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("BaseStatusManager")

func _health_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("HealthManager")

func _base_status_power() -> float:
	var manager := _base_status_manager()
	if manager == null:
		return 100.0
	return float(manager.get("power"))

func _base_status_pressure() -> float:
	var manager := _base_status_manager()
	if manager == null:
		return 100.0
	return float(manager.get("pressure"))

## Reads BaseStatusManager's own SystemStatus enum value as a plain int and
## maps it onto this file's local enum (both share OFFLINE<CRITICAL<BASIC<STABLE
## ordering, so the raw int is compatible without importing the other script).
func _base_status_seal_status() -> int:
	var manager := _base_status_manager()
	if manager == null:
		return SystemStatus.BASIC
	return int(manager.get("seal_status"))

func _last_plant_recovered() -> bool:
	var manager := _base_status_manager()
	if manager == null:
		return false
	return bool(manager.get("last_plant_recovered_bonus_active"))

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
