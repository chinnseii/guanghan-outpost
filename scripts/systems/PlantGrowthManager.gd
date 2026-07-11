extends Node
class_name GuanghanPlantGrowthManager

const FullSaveOrchestratorScript := preload("res://scripts/systems/full_save_orchestrator.gd")

signal plant_growth_changed

const SAVE_PATH := "user://saves/plant_growth_state.json"
const APPLICATION_PROFILE_PATH := "user://saves/application_profile.json"
const MINUTES_PER_DAY := 1440
const PlantCropDataScript := preload("res://scripts/data/PlantCropData.gd")

## Independent v1 abstractions (0-4). Not yet wired to any water/light
## infrastructure elsewhere in the project; adjustable via debug menu.
var water_cycle_level: int = 1
var greenhouse_light_system_level: int = 1

## Reserved for future greenhouse expansion; multiplies the night light power
## draw once more than one zone exists. Not adjustable yet (no expansion UI).
var greenhouse_zone_count: int = 1

var accumulated_growth_minutes: int = 0
var last_sown_slot_id: String = ""

## slot_id -> { crop_id, growth_progress_days, stress, stage, health_state,
##              extra_harvests_used, is_reharvest_cycle, total_harvest_count, last_score }
var plants: Dictionary = {}

func _ready() -> void:
	load_state()

func reset_to_arrival() -> void:
	plants.clear()
	accumulated_growth_minutes = 0
	water_cycle_level = 1
	greenhouse_light_system_level = 1
	greenhouse_zone_count = 1
	last_sown_slot_id = ""
	_save_state()
	plant_growth_changed.emit()

## Called by TimeManager after it advances the clock. Does not advance time itself.
func advance_plant_time(minutes: int) -> void:
	if minutes <= 0:
		return
	accumulated_growth_minutes += minutes
	while accumulated_growth_minutes >= MINUTES_PER_DAY:
		accumulated_growth_minutes -= MINUTES_PER_DAY
		_process_daily_growth()
	_save_state()

func _process_daily_growth() -> void:
	for slot_id in plants.keys():
		_process_daily_growth_for_slot(slot_id)
	_save_state()
	plant_growth_changed.emit()

func _process_daily_growth_for_slot(slot_id: String) -> void:
	var plant: Dictionary = plants[slot_id]
	if String(plant.get("health_state", "Healthy")) == "Dead":
		return
	if String(plant.get("stage", "Seed")) == "Harvested":
		return
	var crop := PlantCropDataScript.get_crop(String(plant.get("crop_id", "")))
	if crop.is_empty():
		return
	var score := 0
	if _consume_daily_plant_water(crop):
		score += 1
	if _light_ok(crop):
		score += 1
	if _temperature_ok(crop):
		score += 1
	var stress := int(plant.get("stress", 0))
	var progress := float(plant.get("growth_progress_days", 0.0))
	match score:
		3:
			progress += 1.0
			stress -= 1
		2:
			progress += 0.5
		1:
			stress += 1
		_:
			stress += 2
	stress = max(0, stress)
	plant["stress"] = stress
	plant["growth_progress_days"] = progress
	plant["last_score"] = score
	plant["health_state"] = _health_state_for_stress(stress)
	if plant["health_state"] == "Dead":
		plant["stage"] = "Dead"
		plants[slot_id] = plant
		return
	var target := _growth_target(plant, crop)
	if progress >= target:
		plant["stage"] = "Mature"
	else:
		plant["stage"] = _stage_for_progress(progress, target)
	plants[slot_id] = plant

func _health_state_for_stress(stress: int) -> String:
	if stress <= 1:
		return "Healthy"
	if stress <= 3:
		return "Stressed"
	if stress <= 5:
		return "Withering"
	return "Dead"

func _growth_target(plant: Dictionary, crop: Dictionary) -> float:
	if bool(plant.get("is_reharvest_cycle", false)):
		return float(crop.get("reharvest_interval_days", crop.get("growth_days", 1.0)))
	return float(crop.get("growth_days", 1.0))

func _stage_for_progress(progress: float, target: float) -> String:
	if target <= 0.0 or progress <= 0.0:
		return "Seed"
	if progress / target < 0.25:
		return "Sprout"
	return "Growing"

## Pure peek for display (panel text / specialist hint) — never consumes
## water. `water_cycle_level` is kept only as a fallback for when
## WaterSystemManager is absent; it no longer gates plant water on its own
## (see docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md — this field is now
## decorative, like BaseStatusManager.power_system_status).
func _water_ok(crop: Dictionary) -> bool:
	var manager := _water_system_manager()
	if manager == null or not manager.has_method("can_supply_plant_water"):
		return water_cycle_level >= int(crop.get("water_requirement", 0))
	return bool(manager.call("can_supply_plant_water", _plant_daily_water_amount(crop)))

## The real, once-per-day-per-plant withdrawal, called only from the daily
## settlement loop. Returns whether the plant's water condition is met.
func _consume_daily_plant_water(crop: Dictionary) -> bool:
	var manager := _water_system_manager()
	if manager == null or not manager.has_method("consume_plant_water"):
		return water_cycle_level >= int(crop.get("water_requirement", 0))
	return bool(manager.call("consume_plant_water", _plant_daily_water_amount(crop)))

func _plant_daily_water_amount(crop: Dictionary) -> float:
	return float(crop.get("water_requirement", 0)) * 0.35

func _light_ok(crop: Dictionary) -> bool:
	return _effective_light_level() >= int(crop.get("light_requirement", 0))

func _temperature_ok(crop: Dictionary) -> bool:
	var temp := _base_status_temperature()
	return temp >= float(crop.get("min_temperature", -999.0)) and temp <= float(crop.get("max_temperature", 999.0))

## Daylight always yields full natural light at zero power cost; night light
## comes from the greenhouse's own supplemental lighting tier, degraded when
## BaseStatusManager.power is low.
func _effective_light_level() -> int:
	if _is_daylight():
		return 4
	var power := _base_status_power()
	var level := greenhouse_light_system_level
	if power >= 70.0:
		pass
	elif power >= 40.0:
		level -= 1
	elif power >= 20.0:
		level -= 2
	else:
		level = min(level, 1)
	return clamp(level, 0, 4)

## Reported to PowerSystemManager for its hourly load total. Daylight is free
## (natural light); night draw is based on the *raw* dial setting
## (greenhouse_light_system_level), not the power-degraded effective level —
## the system is drawing power trying to reach that level even if it can't.
func get_greenhouse_light_power_load() -> float:
	if _is_daylight():
		return 0.0
	var per_zone_cost := 0.0
	match greenhouse_light_system_level:
		0:
			per_zone_cost = 0.0
		1:
			per_zone_cost = 0.04
		2:
			per_zone_cost = 0.08
		3:
			per_zone_cost = 0.14
		4:
			per_zone_cost = 0.22
	return per_zone_cost * float(greenhouse_zone_count)

## -- Water reporting (consulted by WaterSystemManager for its daily forecast
## display, and by its "植物科学" specialist hint)

## Display-only estimate of today's total plant water demand across all
## living, unharvested plants. Does not consume anything.
func get_daily_water_demand() -> float:
	var total := 0.0
	for slot_id in plants.keys():
		var plant: Dictionary = plants[slot_id]
		if String(plant.get("health_state", "Healthy")) == "Dead":
			continue
		if String(plant.get("stage", "Seed")) == "Harvested":
			continue
		var crop := PlantCropDataScript.get_crop(String(plant.get("crop_id", "")))
		if crop.is_empty():
			continue
		total += _plant_daily_water_amount(crop)
	return total

## Highest water_requirement level among currently planted (living,
## unharvested) crops; used by WaterSystemManager's specialist hint to judge
## whether a high-water crop like tomato is still in play.
func get_highest_planted_water_requirement() -> int:
	var highest := 0
	for slot_id in plants.keys():
		var plant: Dictionary = plants[slot_id]
		if String(plant.get("health_state", "Healthy")) == "Dead":
			continue
		if String(plant.get("stage", "Seed")) == "Harvested":
			continue
		var crop := PlantCropDataScript.get_crop(String(plant.get("crop_id", "")))
		if crop.is_empty():
			continue
		highest = max(highest, int(crop.get("water_requirement", 0)))
	return highest

## -- Sowing / harvesting

func sow(slot_id: String, crop_id: String) -> bool:
	if slot_id.is_empty() or not PlantCropDataScript.has_crop(crop_id):
		return false
	plants[slot_id] = {
		"crop_id": crop_id,
		"growth_progress_days": 0.0,
		"stress": 0,
		"stage": "Seed",
		"health_state": "Healthy",
		"extra_harvests_used": 0,
		"is_reharvest_cycle": false,
		"total_harvest_count": 0,
		"last_score": -1,
	}
	last_sown_slot_id = slot_id
	_save_state()
	plant_growth_changed.emit()
	return true

func harvest(slot_id: String) -> bool:
	if not plants.has(slot_id):
		return false
	var plant: Dictionary = plants[slot_id]
	if String(plant.get("stage", "")) != "Mature":
		return false
	var crop := PlantCropDataScript.get_crop(String(plant.get("crop_id", "")))
	if crop.is_empty():
		return false
	# Harvesting only produces the item now — health is restored when the
	# player eats it (InventoryManager.eat_item()), not on harvest itself.
	var harvest_item_id := String(crop.get("harvest_item_id", ""))
	if not harvest_item_id.is_empty() and not _store_harvest_item(harvest_item_id):
		return false
	plant["total_harvest_count"] = int(plant.get("total_harvest_count", 0)) + 1
	if bool(crop.get("repeat_harvest", false)) and int(plant.get("extra_harvests_used", 0)) < int(crop.get("max_extra_harvests", 0)):
		plant["extra_harvests_used"] = int(plant.get("extra_harvests_used", 0)) + 1
		plant["is_reharvest_cycle"] = true
		plant["growth_progress_days"] = 0.0
		plant["stage"] = "Seed"
	else:
		plant["stage"] = "Harvested"
	plants[slot_id] = plant
	_save_state()
	plant_growth_changed.emit()
	return true

func get_plant(slot_id: String) -> Dictionary:
	return plants.get(slot_id, {})

## -- Display text

func panel_text_for_slot(slot_id: String = "") -> String:
	var target_slot := slot_id if not slot_id.is_empty() else last_sown_slot_id
	if target_slot.is_empty() or not plants.has(target_slot):
		return "温室暂无作物。"
	var plant: Dictionary = plants[target_slot]
	var crop := PlantCropDataScript.get_crop(String(plant.get("crop_id", "")))
	if crop.is_empty():
		return "作物数据缺失。"
	var lines: Array[String] = [
		"作物：%s" % String(crop.get("display_name", "")),
		"阶段：%s" % _stage_label(String(plant.get("stage", ""))),
		"健康：%s" % String(plant.get("health_state", "")),
		"距离成熟：%s" % _maturity_eta_text(plant, crop),
		"",
		"环境检查：",
		"水分：%s" % ("满足" if _water_ok(crop) else "不足"),
		"光照：%s（%s）" % [_light_display_label(), "满足" if _light_ok(crop) else "不足"],
		"耗电：%s" % ("0" if _is_daylight() else "来自电力系统"),
		"温度：%s" % _temperature_status_text(crop),
	]
	var hint := get_specialist_hint(target_slot)
	if not hint.is_empty():
		lines.append("")
		lines.append(hint)
	return "\n".join(lines)

func _stage_label(stage: String) -> String:
	match stage:
		"Seed":
			return "种子"
		"Sprout":
			return "幼苗"
		"Growing":
			return "生长期"
		"Mature":
			return "成熟可收获"
		"Harvested":
			return "已收获"
		"Dead":
			return "枯死"
	return stage

func _light_display_label() -> String:
	if _is_daylight():
		return "满级自然光"
	match _effective_light_level():
		0:
			return "补光离线"
		1:
			return "弱光"
		2:
			return "基础补光"
		3:
			return "稳定补光"
		4:
			return "强化补光"
	return "未知"

func _temperature_status_text(crop: Dictionary) -> String:
	var temp := _base_status_temperature()
	if temp < float(crop.get("min_temperature", -999.0)):
		return "偏低"
	if temp > float(crop.get("max_temperature", 999.0)):
		return "偏高"
	return "满足"

func _maturity_eta_text(plant: Dictionary, crop: Dictionary) -> String:
	var stage := String(plant.get("stage", ""))
	if stage == "Mature":
		return "已成熟"
	if stage == "Harvested":
		return "已收获"
	if stage == "Dead":
		return "已枯死"
	var target := _growth_target(plant, crop)
	var remaining := target - float(plant.get("growth_progress_days", 0.0))
	if remaining <= 0.0:
		return "即将成熟"
	var rate := _daily_rate_for_score(int(plant.get("last_score", -1)))
	if rate <= 0.0:
		return "当前环境下生长停滞，无法预计"
	return "约 %d 天" % int(ceil(remaining / rate))

func _daily_rate_for_score(score: int) -> float:
	match score:
		3:
			return 1.0
		2:
			return 0.5
		-1:
			return 1.0
	return 0.0

## Plant-science background only shows more specific diagnostic text, never a
## numeric bonus. Light exceeding the crop's requirement is always reported
## as safe, per spec: no "too much light" penalty exists in this system.
func get_specialist_hint(slot_id: String = "") -> String:
	if _academic_background() != "植物科学":
		return ""
	var target_slot := slot_id if not slot_id.is_empty() else last_sown_slot_id
	if target_slot.is_empty() or not plants.has(target_slot):
		return ""
	var plant: Dictionary = plants[target_slot]
	var crop := PlantCropDataScript.get_crop(String(plant.get("crop_id", "")))
	if crop.is_empty():
		return ""
	var water_ok := _water_ok(crop)
	var light_ok := _light_ok(crop)
	var temp_ok := _temperature_ok(crop)
	var light_exceeds := _effective_light_level() > int(crop.get("light_requirement", 0))
	var lines: Array[String] = ["专业判断："]
	if water_ok and light_ok and temp_ok:
		lines.append("水循环、光照与温度均满足当前作物需求。")
		if light_exceeds:
			lines.append("当前光照等级高于作物需求，不会造成额外风险。")
		return "\n".join(lines)
	if light_exceeds:
		lines.append("当前光照等级高于作物需求，不会造成额外风险。")
		lines.append("主要限制来自%s。" % _limiting_factor_text(water_ok, temp_ok))
		return "\n".join(lines)
	var satisfied: Array[String] = []
	if water_ok:
		satisfied.append("水循环满足需求")
	if temp_ok:
		satisfied.append("温度也在适宜区间")
	if not satisfied.is_empty():
		lines.append("、".join(satisfied) + "。")
	if not light_ok:
		lines.append("当前问题来自光照不足。")
		var eta := _maturity_eta_text(plant, crop)
		if eta.begins_with("约"):
			lines.append("若恢复到稳定补光，预计%s内成熟。" % eta.trim_prefix("约 "))
	elif not water_ok:
		lines.append("当前问题来自水循环不足。")
	elif not temp_ok:
		lines.append("当前问题来自温度不在适宜区间。")
	return "\n".join(lines)

func _limiting_factor_text(water_ok: bool, temp_ok: bool) -> String:
	if not water_ok and not temp_ok:
		return "水循环与温度"
	if not water_ok:
		return "水循环"
	if not temp_ok:
		return "温度偏低" if _base_status_temperature() < 18.0 else "温度偏高"
	return "环境条件"

## -- Debug helpers

func debug_sow(crop_id: String) -> void:
	sow(crop_id, crop_id)

func debug_harvest_current() -> void:
	if not last_sown_slot_id.is_empty():
		harvest(last_sown_slot_id)

func debug_force_mature_current() -> void:
	if last_sown_slot_id.is_empty() or not plants.has(last_sown_slot_id):
		return
	var plant: Dictionary = plants[last_sown_slot_id]
	if String(plant.get("stage", "")) == "Harvested":
		return
	var crop := PlantCropDataScript.get_crop(String(plant.get("crop_id", "")))
	if crop.is_empty():
		return
	plant["growth_progress_days"] = _growth_target(plant, crop)
	plant["stress"] = 0
	plant["health_state"] = "Healthy"
	plant["stage"] = "Mature"
	plants[last_sown_slot_id] = plant
	_save_state()
	plant_growth_changed.emit()

func clear_all_plants() -> void:
	plants.clear()
	last_sown_slot_id = ""
	_save_state()
	plant_growth_changed.emit()

func debug_set_water_level(level: int) -> void:
	water_cycle_level = clamp(level, 0, 4)
	_save_state()
	plant_growth_changed.emit()

func debug_cycle_water_level() -> void:
	debug_set_water_level((water_cycle_level + 1) % 5)

func debug_set_light_system_level(level: int) -> void:
	greenhouse_light_system_level = clamp(level, 0, 4)
	_save_state()
	plant_growth_changed.emit()

func debug_cycle_light_system_level() -> void:
	debug_set_light_system_level((greenhouse_light_system_level + 1) % 5)

func debug_values_text() -> String:
	var lines: Array[String] = [
		"WaterCycleLevel: %d" % water_cycle_level,
		"GreenhouseLightSystemLevel: %d" % greenhouse_light_system_level,
		"EffectiveLight: %d (daylight=%s)" % [_effective_light_level(), str(_is_daylight())],
		"AccumulatedMinutes: %d" % accumulated_growth_minutes,
		"Plants: %d" % plants.size(),
	]
	if not last_sown_slot_id.is_empty() and plants.has(last_sown_slot_id):
		var plant: Dictionary = plants[last_sown_slot_id]
		lines.append("Current (%s): stage=%s health=%s stress=%d progress=%.1f" % [
			last_sown_slot_id, String(plant.get("stage", "")), String(plant.get("health_state", "")),
			int(plant.get("stress", 0)), float(plant.get("growth_progress_days", 0.0)),
		])
	return "\n".join(lines)

## -- Persistence

func serialize() -> Dictionary:
	return {
		"accumulated_growth_minutes": accumulated_growth_minutes,
		"water_cycle_level": water_cycle_level,
		"greenhouse_light_system_level": greenhouse_light_system_level,
		"greenhouse_zone_count": greenhouse_zone_count,
		"last_sown_slot_id": last_sown_slot_id,
		"plants": plants.duplicate(true),
	}

func deserialize(data: Dictionary) -> void:
	accumulated_growth_minutes = int(data.get("accumulated_growth_minutes", accumulated_growth_minutes))
	water_cycle_level = clamp(int(data.get("water_cycle_level", water_cycle_level)), 0, 4)
	greenhouse_light_system_level = clamp(int(data.get("greenhouse_light_system_level", greenhouse_light_system_level)), 0, 4)
	greenhouse_zone_count = max(1, int(data.get("greenhouse_zone_count", greenhouse_zone_count)))
	last_sown_slot_id = String(data.get("last_sown_slot_id", last_sown_slot_id))
	var saved_plants: Variant = data.get("plants", {})
	if saved_plants is Dictionary:
		plants = (saved_plants as Dictionary).duplicate(true)
	plant_growth_changed.emit()

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

func _inventory_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("InventoryManager")

func _storage_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("StorageManager")

func _store_harvest_item(harvest_item_id: String) -> bool:
	var storage_manager := _storage_manager()
	if storage_manager != null and storage_manager.has_method("add_item"):
		var result: Variant = storage_manager.call("add_item", harvest_item_id, 1)
		if result is Dictionary:
			return int((result as Dictionary).get("accepted", 0)) >= 1
		return bool(result)
	var inventory_manager := _inventory_manager()
	if inventory_manager != null and inventory_manager.has_method("add_item"):
		return bool(inventory_manager.call("add_item", harvest_item_id, 1))
	return false

func _water_system_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("WaterSystemManager")

func _base_status_power() -> float:
	var manager := _base_status_manager()
	if manager == null:
		return 100.0
	return float(manager.get("power"))

func _base_status_temperature() -> float:
	var manager := _base_status_manager()
	if manager == null:
		return 21.0
	return float(manager.get("temperature"))

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
