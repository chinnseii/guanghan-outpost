extends Node
class_name GuanghanBackpackManager

const FullSaveOrchestratorScript := preload("res://scripts/systems/full_save_orchestrator.gd")

signal backpack_changed

const SAVE_PATH := "user://saves/backpack_state.json"
const ItemContainerScript := preload("res://scripts/systems/ItemContainer.gd")
const ItemDatabaseScript := preload("res://scripts/data/ItemDatabase.gd")

const LEVELS := {
	1: {"name": "应急收纳包", "slots": 12},
	2: {"name": "小型采集包", "slots": 16},
	3: {"name": "标准外勤包", "slots": 24},
	4: {"name": "扩展外勤包", "slots": 32},
	5: {"name": "重型采集包", "slots": 40},
	6: {"name": "工程外勤包", "slots": 48},
}

var backpack_level: int = 1
var backpack_capacity_slots: int = 12
var slots: Array = []
var last_durable_instance_id: String = ""
var _next_durable_instance_number: int = 1
var current_carry_weight: float = 0.0
var max_carry_weight: float = 50.0
var load_percent: float = 0.0
var load_level: int = 1

func _ready() -> void:
	load_state()

func reset_to_arrival() -> void:
	backpack_level = 1
	backpack_capacity_slots = int(LEVELS[backpack_level]["slots"])
	slots = ItemContainerScript.empty_slots(backpack_capacity_slots)
	last_durable_instance_id = ""
	_next_durable_instance_number = 1
	_save_state()
	backpack_changed.emit()

func upgrade_backpack() -> bool:
	if backpack_level >= LEVELS.size():
		return false
	backpack_level += 1
	backpack_capacity_slots = int(LEVELS[backpack_level]["slots"])
	slots = ItemContainerScript.normalize_slots(slots, backpack_capacity_slots)
	_save_state()
	backpack_changed.emit()
	return true

func add_item(item_id: String, amount: int = 1) -> Dictionary:
	var result: Dictionary = ItemContainerScript.add_item(slots, item_id, amount, "backpack")
	if int(result.get("accepted", 0)) > 0:
		_save_state()
		backpack_changed.emit()
	return result

func add_durable_item(item_id: String) -> String:
	var item := ItemDatabaseScript.get_item(item_id)
	if item.is_empty() or not bool(item.get("has_durability", false)):
		return ""
	var instance_id := "bp_tool_%04d" % _next_durable_instance_number
	if not ItemContainerScript.add_durable_slot(slots, item_id, instance_id):
		return ""
	_next_durable_instance_number += 1
	last_durable_instance_id = instance_id
	_save_state()
	backpack_changed.emit()
	return instance_id

func remove_item(item_id: String, amount: int = 1) -> bool:
	if not ItemContainerScript.remove_item(slots, item_id, amount):
		return false
	_save_state()
	backpack_changed.emit()
	return true

func get_item_count(item_id: String) -> int:
	return ItemContainerScript.item_count(slots, item_id)

func get_current_carry_weight() -> float:
	refresh_load_state()
	return current_carry_weight

func get_max_carry_weight() -> float:
	refresh_load_state()
	return max_carry_weight

func get_load_percent() -> float:
	refresh_load_state()
	return load_percent

func get_load_level() -> int:
	refresh_load_state()
	return load_level

func refresh_load_state() -> void:
	current_carry_weight = _calculate_current_carry_weight()
	max_carry_weight = max(_effective_carry_capacity(), 1.0)
	load_percent = current_carry_weight / max_carry_weight * 100.0
	load_level = _load_level_from_percent(load_percent)

func sort_inventory() -> void:
	slots = ItemContainerScript.sort_slots(slots)
	_save_state()
	backpack_changed.emit()

func transfer_slot_to_storage(slot_index: int, amount: int = -1) -> Dictionary:
	var storage_manager := _storage_manager()
	if storage_manager == null or not storage_manager.has_method("add_existing_slot"):
		return {"accepted": 0}
	var taken := ItemContainerScript.take_from_slot(slots, slot_index, amount)
	if taken.is_empty():
		return {"accepted": 0}
	var result: Dictionary = storage_manager.call("add_existing_slot", taken, amount)
	var rejected: Variant = result.get("rejected_slot", null)
	if rejected is Dictionary:
		ItemContainerScript.add_existing_slot(slots, rejected as Dictionary, "backpack")
	_save_state()
	backpack_changed.emit()
	return result

func deposit_all_to_storage() -> Dictionary:
	var accepted_total := 0
	for i in range(slots.size()):
		if slots[i] == null:
			continue
		var result := transfer_slot_to_storage(i)
		accepted_total += int(result.get("accepted", 0))
	return {"accepted": accepted_total}

func deposit_ice_to_water_system() -> Dictionary:
	var amount := get_item_count("RS-IC-001")
	if amount <= 0:
		return {"accepted": 0, "remaining": 0}
	var water_manager := _water_system_manager()
	if water_manager == null or not water_manager.has_method("add_ice"):
		return {"accepted": 0, "remaining": amount}
	var before := 0.0
	if water_manager.has_method("get"):
		before = float(water_manager.get("current_ice"))
	water_manager.call("add_ice", amount)
	var after := float(water_manager.get("current_ice"))
	var accepted := int(max(0.0, round(after - before)))
	if accepted > 0:
		remove_item("RS-IC-001", min(accepted, amount))
	return {"accepted": accepted, "remaining": get_item_count("RS-IC-001")}

func eat_item(item_id: String) -> bool:
	return _consume_item_from_self(item_id)

func eat_first_food() -> bool:
	for slot in slots:
		if not (slot is Dictionary):
			continue
		var item_id := String((slot as Dictionary).get("item_id", ""))
		var item := ItemDatabaseScript.get_item(item_id)
		if bool(item.get("can_eat", false)):
			return eat_item(item_id)
	return false

func add_existing_slot(source_slot: Dictionary, amount: int = -1) -> Dictionary:
	var result: Dictionary = ItemContainerScript.add_existing_slot(slots, source_slot, "backpack", amount)
	if int(result.get("accepted", 0)) > 0:
		_save_state()
		backpack_changed.emit()
	return result

func panel_status_text() -> String:
	refresh_load_state()
	return _panel_status_with_load_text()
	var lines: Array[String] = [
		"%s  %d / %d 格" % [String(LEVELS[backpack_level]["name"]), ItemContainerScript.used_slots(slots), backpack_capacity_slots],
		"重量字段已保留，本版不参与限制。",
	]
	lines.append_array(_slot_lines())
	return "\n".join(lines)

func debug_values_text() -> String:
	return panel_status_text()

func debug_add_sample_materials() -> void:
	add_item("MT-ME-001", 18)
	add_item("MT-EL-001", 9)
	add_item("MT-SE-001", 5)

func debug_add_sample_foods() -> void:
	add_item("FO-CR-001", 8)
	add_item("CN-FD-001", 3)

func debug_add_lunar_ice() -> void:
	add_item("RS-IC-001", 12)

func serialize() -> Dictionary:
	return {
		"backpack_level": backpack_level,
		"backpack_capacity_slots": backpack_capacity_slots,
		"slots": slots.duplicate(true),
		"last_durable_instance_id": last_durable_instance_id,
		"next_durable_instance_number": _next_durable_instance_number,
	}

func deserialize(data: Dictionary) -> void:
	backpack_level = clamp(int(data.get("backpack_level", backpack_level)), 1, LEVELS.size())
	backpack_capacity_slots = int(data.get("backpack_capacity_slots", LEVELS[backpack_level]["slots"]))
	slots = ItemContainerScript.normalize_slots(data.get("slots", []), backpack_capacity_slots)
	last_durable_instance_id = String(data.get("last_durable_instance_id", last_durable_instance_id))
	_next_durable_instance_number = int(data.get("next_durable_instance_number", _next_durable_instance_number))
	refresh_load_state()
	backpack_changed.emit()

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
	refresh_load_state()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(serialize(), "\t"))

func _slot_lines() -> Array[String]:
	var lines: Array[String] = []
	for i in range(slots.size()):
		if not (slots[i] is Dictionary):
			continue
		lines.append("%02d  %s" % [i + 1, ItemContainerScript.slot_label(slots[i])])
	if lines.is_empty():
		lines.append("暂无随身物品。")
	return lines

func _consume_item_from_self(item_id: String) -> bool:
	var item := ItemDatabaseScript.get_item(item_id)
	if item.is_empty() or not bool(item.get("can_eat", false)):
		return false
	if not remove_item(item_id, 1):
		return false
	_advance_time(int(item.get("use_time_minutes", 0)), "eat_item")
	_apply_item_effects(item)
	return true

func _panel_status_with_load_text() -> String:
	var lines: Array[String] = [
		"%s  %d / %d slots" % [String(LEVELS[backpack_level]["name"]), ItemContainerScript.used_slots(slots), backpack_capacity_slots],
		"Carry %.1f / %.1f CU  %.0f%%  Load Lv.%d %s" % [
			current_carry_weight,
			max_carry_weight,
			load_percent,
			load_level,
			_load_level_label(load_level),
		],
	]
	lines.append_array(_slot_lines())
	return "\n".join(lines)

func _calculate_current_carry_weight() -> float:
	var total := 0.0
	for slot in slots:
		if not (slot is Dictionary):
			continue
		var data := slot as Dictionary
		var item_id := String(data.get("item_id", ""))
		var item: Dictionary = ItemDatabaseScript.get_item(item_id)
		if item.is_empty():
			continue
		var quantity := int(data.get("quantity", 1))
		total += float(item.get("weight", 0.0)) * float(max(quantity, 1))
	return total

func _effective_carry_capacity() -> float:
	var health_manager := _health_manager()
	if health_manager != null and health_manager.has_method("get_effective_carry_capacity"):
		return float(health_manager.call("get_effective_carry_capacity"))
	return 50.0

func _load_level_from_percent(percent: float) -> int:
	if percent < 50.0:
		return 1
	if percent < 75.0:
		return 2
	if percent < 100.0:
		return 3
	return 4

func _load_level_label(level: int) -> String:
	match level:
		1:
			return "Light"
		2:
			return "Loaded"
		3:
			return "Heavy"
		4:
			return "Overloaded"
	return "Unknown"

func _advance_time(minutes: int, reason: String) -> void:
	var manager := _time_manager()
	if minutes > 0 and manager != null and manager.has_method("advance_time"):
		manager.call("advance_time", minutes, reason)

func _apply_item_effects(item: Dictionary) -> void:
	var effects: Variant = item.get("effects", {})
	if not (effects is Dictionary) or (effects as Dictionary).is_empty():
		return
	var health_manager := _health_manager()
	if health_manager != null and health_manager.has_method("apply_item_effects"):
		health_manager.call("apply_item_effects", effects)

func _storage_manager() -> Node:
	return get_tree().root.get_node_or_null("StorageManager")

func _time_manager() -> Node:
	return get_tree().root.get_node_or_null("TimeManager")

func _health_manager() -> Node:
	return get_tree().root.get_node_or_null("HealthManager")

func _water_system_manager() -> Node:
	return get_tree().root.get_node_or_null("WaterSystemManager")
