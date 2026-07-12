extends Node
class_name GuanghanStorageManager

const FullSaveOrchestratorScript := preload("res://scripts/systems/full_save_orchestrator.gd")

signal storage_changed

const SAVE_PATH := "user://saves/storage_state.json"
const ItemContainerScript := preload("res://scripts/systems/ItemContainer.gd")
const ItemDatabaseScript := preload("res://scripts/data/ItemDatabase.gd")

const LEVELS := {
	1: {"name": "旧基地储物柜", "slots": 60},
	2: {"name": "整理后的储物区", "slots": 90},
	3: {"name": "标准仓储舱", "slots": 140},
	4: {"name": "扩展仓储舱", "slots": 220},
	5: {"name": "自动分拣仓库", "slots": 320},
	6: {"name": "大型货物舱", "slots": 500},
}

var storage_level: int = 1
var storage_capacity_slots: int = 60
var slots: Array = []
var last_durable_instance_id: String = ""
var _next_durable_instance_number: int = 1

func _ready() -> void:
	load_state()

func reset_to_arrival() -> void:
	storage_level = 1
	storage_capacity_slots = int(LEVELS[storage_level]["slots"])
	slots = ItemContainerScript.empty_slots(storage_capacity_slots)
	last_durable_instance_id = ""
	_next_durable_instance_number = 1
	_save_state()
	storage_changed.emit()

func upgrade_storage() -> bool:
	if storage_level >= LEVELS.size():
		return false
	storage_level += 1
	storage_capacity_slots = int(LEVELS[storage_level]["slots"])
	slots = ItemContainerScript.normalize_slots(slots, storage_capacity_slots)
	_save_state()
	storage_changed.emit()
	return true

func add_item(item_id: String, amount: int = 1) -> Dictionary:
	var result: Dictionary = ItemContainerScript.add_item(slots, item_id, amount, "storage")
	if int(result.get("accepted", 0)) > 0:
		_save_state()
		storage_changed.emit()
	return result

func add_durable_item(item_id: String) -> String:
	var item := ItemDatabaseScript.get_item(item_id)
	if item.is_empty() or not bool(item.get("has_durability", false)):
		return ""
	var instance_id := "st_tool_%04d" % _next_durable_instance_number
	if not ItemContainerScript.add_durable_slot(slots, item_id, instance_id):
		return ""
	_next_durable_instance_number += 1
	last_durable_instance_id = instance_id
	_save_state()
	storage_changed.emit()
	return instance_id

func remove_item(item_id: String, amount: int = 1) -> bool:
	if not ItemContainerScript.remove_item(slots, item_id, amount):
		return false
	_save_state()
	storage_changed.emit()
	return true

func get_item_count(item_id: String) -> int:
	return ItemContainerScript.item_count(slots, item_id)

func sort_inventory() -> void:
	slots = ItemContainerScript.sort_slots(slots)
	_save_state()
	storage_changed.emit()

func transfer_slot_to_backpack(slot_index: int, amount: int = -1) -> Dictionary:
	var backpack_manager := _backpack_manager()
	if backpack_manager == null or not backpack_manager.has_method("add_existing_slot"):
		return {"accepted": 0, "source": "storage", "destination": "backpack", "source_slot_index": slot_index, "requested_amount": amount}
	var taken := ItemContainerScript.take_from_slot(slots, slot_index, amount)
	if taken.is_empty():
		return {"accepted": 0, "source": "storage", "destination": "backpack", "source_slot_index": slot_index, "requested_amount": amount}
	var result: Dictionary = backpack_manager.call("add_existing_slot", taken, amount)
	var rejected: Variant = result.get("rejected_slot", null)
	var returned_to_source := 0
	if rejected is Dictionary:
		returned_to_source = int((rejected as Dictionary).get("quantity", 1))
		ItemContainerScript.add_existing_slot(slots, rejected as Dictionary, "storage")
	result["source"] = "storage"
	result["destination"] = "backpack"
	result["source_slot_index"] = slot_index
	result["requested_amount"] = amount
	result["returned_to_source"] = returned_to_source
	result["rolled_back"] = int(result.get("accepted", 0)) == 0 and returned_to_source > 0
	_save_state()
	storage_changed.emit()
	return result

func add_existing_slot(source_slot: Dictionary, amount: int = -1) -> Dictionary:
	var result: Dictionary = ItemContainerScript.add_existing_slot(slots, source_slot, "storage", amount)
	if int(result.get("accepted", 0)) > 0:
		_save_state()
		storage_changed.emit()
	return result

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

func panel_status_text() -> String:
	var lines: Array[String] = [
		"%s  %d / %d 格" % [String(LEVELS[storage_level]["name"]), ItemContainerScript.used_slots(slots), storage_capacity_slots],
		"系统资源不长期存入仓库；月球冰回基地后转入水系统。",
	]
	lines.append_array(_slot_lines())
	return "\n".join(lines)

func debug_values_text() -> String:
	return panel_status_text()

func debug_add_sample_foods() -> void:
	add_item("FO-CR-001", 12)
	add_item("FO-CR-004", 4)

func debug_add_sample_seeds() -> void:
	add_item("SD-CR-001", 12)
	add_item("SD-CR-004", 6)

func debug_add_sample_materials() -> void:
	add_item("MT-ME-001", 30)
	add_item("MT-EL-001", 20)

func serialize() -> Dictionary:
	return {
		"storage_level": storage_level,
		"storage_capacity_slots": storage_capacity_slots,
		"slots": slots.duplicate(true),
		"last_durable_instance_id": last_durable_instance_id,
		"next_durable_instance_number": _next_durable_instance_number,
	}

func deserialize(data: Dictionary) -> void:
	storage_level = clamp(int(data.get("storage_level", storage_level)), 1, LEVELS.size())
	storage_capacity_slots = int(data.get("storage_capacity_slots", LEVELS[storage_level]["slots"]))
	slots = ItemContainerScript.normalize_slots(data.get("slots", []), storage_capacity_slots)
	last_durable_instance_id = String(data.get("last_durable_instance_id", last_durable_instance_id))
	_next_durable_instance_number = int(data.get("next_durable_instance_number", _next_durable_instance_number))
	storage_changed.emit()

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

func _slot_lines() -> Array[String]:
	var lines: Array[String] = []
	for i in range(slots.size()):
		if not (slots[i] is Dictionary):
			continue
		lines.append("%02d  %s" % [i + 1, ItemContainerScript.slot_label(slots[i])])
	if lines.is_empty():
		lines.append("仓库暂无物品。")
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

func _backpack_manager() -> Node:
	return get_tree().root.get_node_or_null("BackpackManager")

func _time_manager() -> Node:
	return get_tree().root.get_node_or_null("TimeManager")

func _health_manager() -> Node:
	return get_tree().root.get_node_or_null("HealthManager")
