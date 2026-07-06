extends Node
class_name GuanghanHealthManager

signal health_changed(energy: float, fullness: float, nutrition: float, morale: float)

const SAVE_PATH := "user://saves/health_state.json"
const APPLICATION_PROFILE_PATH := "user://saves/application_profile.json"

const ARRIVAL_ENERGY := 80.0
const ARRIVAL_FULLNESS := 80.0
const ARRIVAL_NUTRITION := 85.0
const ARRIVAL_MORALE := 75.0

var energy: float = ARRIVAL_ENERGY
var fullness: float = ARRIVAL_FULLNESS
var nutrition: float = ARRIVAL_NUTRITION
var morale: float = ARRIVAL_MORALE
var base_carry_capacity: float = 50.0
var effective_carry_capacity: float = 50.0
var carry_health_score: float = 100.0
var carry_health_multiplier: float = 1.0

func _ready() -> void:
	load_state()

func reset_to_arrival() -> void:
	energy = ARRIVAL_ENERGY
	fullness = ARRIVAL_FULLNESS
	nutrition = ARRIVAL_NUTRITION
	morale = ARRIVAL_MORALE
	base_carry_capacity = 50.0
	get_effective_carry_capacity()
	_save_state()
	_emit_changed()

func clamp_health_values() -> void:
	energy = clamp(energy, 0.0, 100.0)
	fullness = clamp(fullness, 0.0, 100.0)
	nutrition = clamp(nutrition, 0.0, 100.0)
	morale = clamp(morale, 0.0, 100.0)

func apply_action_cost(action_id: String) -> void:
	match _normalized_action_id(action_id):
		"sleep_standard":
			apply_sleep_standard()
		"eat":
			apply_eat()
		"nutrition_drink":
			apply_nutrition_drink()
		"entertainment_short":
			apply_entertainment_short()
		"entertainment_long":
			apply_entertainment_long()
		"plant_diagnosis_positive":
			apply_plant_diagnosis(true)
		"plant_diagnosis_negative":
			apply_plant_diagnosis(false)
		"plant_diagnosis":
			apply_plant_diagnosis(false)
		"organize_supplies":
			apply_organize_supplies()
		"send_report_positive":
			apply_send_report(true)
		"send_report_negative":
			apply_send_report(false)
		"send_report":
			apply_send_report(true)
		"repair_light":
			apply_repair_light()
		"repair_heavy":
			apply_repair_heavy()
		"explore_short":
			apply_explore_short()
		"explore_long":
			apply_explore_long()
		_:
			return
	_finish_action_change()

func apply_sleep_standard() -> void:
	var recovery := 70.0 * get_nutrition_sleep_multiplier() * get_morale_sleep_multiplier()
	energy += recovery
	fullness -= 15.0
	nutrition -= 5.0
	morale += 5.0

func apply_eat() -> void:
	# TODO: deduct food resource once the inventory/food system exists.
	energy -= 1.0
	fullness += 45.0
	nutrition -= 2.0
	morale += 2.0

func apply_nutrition_drink() -> void:
	# TODO: deduct nutrition drink resource once supplies are modeled.
	fullness += 5.0
	nutrition += 25.0
	morale -= 1.0

func apply_entertainment_short() -> void:
	energy += 5.0
	fullness -= 5.0
	nutrition -= 2.0
	morale += 20.0

func apply_entertainment_long() -> void:
	energy += 10.0
	fullness -= 10.0
	nutrition -= 3.0
	morale += 35.0

func apply_plant_diagnosis(positive: bool) -> void:
	_apply_delta(-2.0, -1.0, 0.0, 1.0 if positive else -2.0)

func apply_organize_supplies() -> void:
	_apply_delta(-4.0, -3.0, 0.0, 0.0)

func apply_send_report(positive: bool) -> void:
	_apply_delta(-1.0, -1.0, 0.0, 2.0 if positive else -2.0)

func apply_repair_light() -> void:
	_apply_delta(-8.0, -4.0, -1.0, -2.0)

func apply_repair_heavy() -> void:
	_apply_delta(-16.0, -8.0, -2.0, -5.0)

func apply_explore_short() -> void:
	_apply_delta(-25.0, -15.0, -3.0, -5.0)

func apply_explore_long() -> void:
	_apply_delta(-45.0, -30.0, -6.0, -10.0)

func get_action_time_multiplier(action_id: String) -> float:
	var normalized := _normalized_action_id(action_id)
	if not normalized in ["repair_light", "repair_heavy", "explore_short", "explore_long", "organize_supplies", "plant_diagnosis", "plant_diagnosis_positive", "plant_diagnosis_negative"]:
		return 1.0
	if energy >= 40.0:
		return 1.0
	if energy >= 20.0:
		return 1.25
	return 1.5

func adjusted_action_minutes(base_minutes: int, action_id: String) -> int:
	if base_minutes <= 0:
		return base_minutes
	return int(ceil(float(base_minutes) * get_action_time_multiplier(action_id)))

func get_carry_health_multiplier() -> float:
	carry_health_score = min(energy, min(fullness, nutrition))
	if carry_health_score >= 70.0:
		return 1.0
	if carry_health_score >= 40.0:
		return 0.9
	if carry_health_score >= 20.0:
		return 0.75
	return 0.6

func get_effective_carry_capacity() -> float:
	carry_health_score = min(energy, min(fullness, nutrition))
	carry_health_multiplier = get_carry_health_multiplier()
	effective_carry_capacity = base_carry_capacity * carry_health_multiplier
	return effective_carry_capacity

func get_energy_cost_multiplier() -> float:
	var fullness_multiplier := 1.0
	if fullness >= 70.0:
		fullness_multiplier = 1.0
	elif fullness >= 40.0:
		fullness_multiplier = 1.2
	elif fullness >= 20.0:
		fullness_multiplier = 1.4
	else:
		fullness_multiplier = 1.6
	return fullness_multiplier * _temperature_energy_multiplier() * _air_energy_multiplier()

func _temperature_energy_multiplier() -> float:
	var manager := _base_status_manager()
	if manager == null or not manager.has_method("get_temperature_energy_multiplier"):
		return 1.0
	return float(manager.call("get_temperature_energy_multiplier"))

func _air_energy_multiplier() -> float:
	var manager := _air_system_manager()
	if manager == null or not manager.has_method("get_air_energy_multiplier"):
		return 1.0
	return float(manager.call("get_air_energy_multiplier"))

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

func get_nutrition_sleep_multiplier() -> float:
	if nutrition >= 70.0:
		return 1.0
	if nutrition >= 40.0:
		return 0.8
	if nutrition >= 20.0:
		return 0.6
	return 0.4

func get_morale_sleep_multiplier() -> float:
	if morale >= 40.0:
		return 1.0
	if morale >= 20.0:
		return 0.8
	return 0.6

func get_energy_label() -> String:
	if energy >= 70.0:
		return "良好"
	if energy >= 40.0:
		return "疲惫"
	if energy >= 20.0:
		return "严重疲惫"
	return "危险疲惫"

func get_fullness_label() -> String:
	if fullness >= 70.0:
		return "正常"
	if fullness >= 40.0:
		return "有些饿"
	if fullness >= 20.0:
		return "饥饿"
	return "严重饥饿"

func get_nutrition_label() -> String:
	if nutrition >= 70.0:
		return "良好"
	if nutrition >= 40.0:
		return "偏低"
	if nutrition >= 20.0:
		return "不足"
	return "严重不足"

func get_morale_label() -> String:
	if morale >= 70.0:
		return "稳定"
	if morale >= 40.0:
		return "低压"
	if morale >= 20.0:
		return "低落"
	return "危险"

func compact_hud_text() -> String:
	return "驻留者状态：精力 %s / 饱腹 %s" % [get_energy_label(), get_fullness_label()]

func detail_text(show_values := false) -> String:
	var lines: Array[String] = [
		"驻留者状态",
		"精力：%s%s" % [get_energy_label(), _value_suffix(energy, show_values)],
		"饱腹：%s%s" % [get_fullness_label(), _value_suffix(fullness, show_values)],
		"营养：%s%s" % [get_nutrition_label(), _value_suffix(nutrition, show_values)],
		"心理：%s%s" % [get_morale_label(), _value_suffix(morale, show_values)],
	]
	var advice := get_medical_advice()
	if not advice.is_empty():
		lines.append("")
		lines.append(advice)
	return "\n".join(lines)

func debug_values_text() -> String:
	return "Energy: %.0f\nFullness: %.0f\nNutrition: %.0f\nMorale: %.0f" % [energy, fullness, nutrition, morale]

func get_medical_advice() -> String:
	if not _has_medical_background():
		return ""
	if energy < 40.0 and nutrition < 70.0 and morale < 40.0:
		return "专业判断：当前恢复瓶颈不是睡眠时间，而是营养与心理状态。建议先补充营养液，并进行短暂娱乐，再进入休息周期。"
	if energy < 40.0:
		return "专业判断：当前主要问题是精力不足。建议进入标准睡眠周期，避免继续执行高消耗任务。"
	if fullness < 40.0:
		return "专业判断：当前饱腹偏低会增加精力消耗。不建议直接执行外出采集或维修，建议先完成进食。"
	if nutrition < 70.0:
		return "专业判断：营养偏低会降低睡眠恢复质量。如计划休息，建议先补充营养液。"
	if morale < 40.0:
		return "专业判断：心理状态低落会影响睡眠质量。建议先进行短暂娱乐，再进入休息周期。"
	return "专业判断：当前身体状态可维持基础工作。建议继续保持固定作息。"

func adjust_stat(stat_name: String, delta: float) -> void:
	match stat_name:
		"energy":
			energy += delta
		"fullness":
			fullness += delta
		"nutrition":
			nutrition += delta
		"morale":
			morale += delta
	clamp_health_values()
	_save_state()
	_emit_changed()

## Called by InventoryManager when a food/consumable item is eaten or used.
## Keys are stat names matching adjust_stat(); unknown keys are ignored via
## adjust_stat()'s own match. Goes through adjust_stat() so clamping/saving/
## signal emission stay centralized — never bypasses it.
func apply_item_effects(effects: Dictionary) -> void:
	for stat_name in effects.keys():
		adjust_stat(String(stat_name), float(effects[stat_name]))

func set_danger_state() -> void:
	energy = 18.0
	fullness = 18.0
	nutrition = 25.0
	morale = 18.0
	_save_state()
	_emit_changed()

func serialize() -> Dictionary:
	return {
		"energy": energy,
		"fullness": fullness,
		"nutrition": nutrition,
		"morale": morale,
		"base_carry_capacity": base_carry_capacity,
	}

func deserialize(data: Dictionary) -> void:
	energy = float(data.get("energy", energy))
	fullness = float(data.get("fullness", fullness))
	nutrition = float(data.get("nutrition", nutrition))
	morale = float(data.get("morale", morale))
	base_carry_capacity = float(data.get("base_carry_capacity", base_carry_capacity))
	clamp_health_values()
	get_effective_carry_capacity()
	_emit_changed()

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

func _apply_delta(energy_delta: float, fullness_delta: float, nutrition_delta: float, morale_delta: float) -> void:
	if energy_delta < 0.0:
		energy_delta *= get_energy_cost_multiplier()
	energy += energy_delta
	fullness += fullness_delta
	nutrition += nutrition_delta
	morale += morale_delta

func _finish_action_change() -> void:
	clamp_health_values()
	_save_state()
	_emit_changed()

func _emit_changed() -> void:
	health_changed.emit(energy, fullness, nutrition, morale)

func _save_state() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(serialize(), "\t"))

func _normalized_action_id(action_id: String) -> String:
	match action_id:
		"debug_sleep":
			return "sleep_standard"
		"debug_eat":
			return "eat"
		"debug_nutrition_drink":
			return "nutrition_drink"
		"debug_entertainment_short":
			return "entertainment_short"
		"debug_repair_light":
			return "repair_light"
		"debug_explore_short":
			return "explore_short"
	return action_id

func _value_suffix(value: float, show_values: bool) -> String:
	if not show_values:
		return ""
	return "（%.0f）" % value

func _has_medical_background() -> bool:
	var background := _academic_background()
	return background == "医学" or background.to_lower() == "medicine"

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
