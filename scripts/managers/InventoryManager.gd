extends Node
class_name GuanghanInventoryManager

signal inventory_changed

const SAVE_PATH := "user://saves/inventory_state.json"
const ItemDatabaseScript := preload("res://scripts/data/ItemDatabase.gd")

## item_id -> quantity (int). Durable items never live here — see durable_items.
var stack_items: Dictionary = {}

## instance_id -> { item_id, current_durability, max_durability, state }.
## One entry per physical tool, since two instances of the same item_id can
## have different durability.
var durable_items: Dictionary = {}

var last_durable_instance_id: String = ""

var _next_durable_instance_number: int = 1

func _ready() -> void:
	load_state()

func reset_to_arrival() -> void:
	stack_items.clear()
	durable_items.clear()
	last_durable_instance_id = ""
	_next_durable_instance_number = 1
	_save_state()
	inventory_changed.emit()

## -- Stackable items

func add_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	var item := ItemDatabaseScript.get_item(item_id)
	if item.is_empty() or bool(item.get("has_durability", false)):
		return false
	stack_items[item_id] = int(stack_items.get(item_id, 0)) + amount
	_save_state()
	inventory_changed.emit()
	return true

func remove_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	var current := int(stack_items.get(item_id, 0))
	if current < amount:
		return false
	var remaining := current - amount
	if remaining <= 0:
		stack_items.erase(item_id)
	else:
		stack_items[item_id] = remaining
	_save_state()
	inventory_changed.emit()
	return true

func has_item(item_id: String, amount: int = 1) -> bool:
	return int(stack_items.get(item_id, 0)) >= amount

func get_item_count(item_id: String) -> int:
	return int(stack_items.get(item_id, 0))

## -- Consumption

## Only for items with can_eat = true. Removes 1, advances time by the
## item's use_time_minutes, applies its effects to HealthManager. Does not
## call HealthManager.apply_action_cost("eat") — that would double-restore.
func eat_item(item_id: String) -> bool:
	var item := ItemDatabaseScript.get_item(item_id)
	if item.is_empty() or not bool(item.get("can_eat", false)):
		return false
	if not has_item(item_id, 1):
		return false
	remove_item(item_id, 1)
	_advance_time(int(item.get("use_time_minutes", 0)), "eat_item")
	_apply_item_effects(item)
	return true

## Generic use for can_use = true, non-durable items (seeds, medkits, etc.).
## Durable tools go through use_durable_item() instead.
func use_item(item_id: String) -> bool:
	var item := ItemDatabaseScript.get_item(item_id)
	if item.is_empty() or not bool(item.get("can_use", false)):
		return false
	if String(item.get("use_model", "none")) == "durable":
		return false
	if not has_item(item_id, 1):
		return false
	if bool(item.get("consumable", false)):
		remove_item(item_id, 1)
	_advance_time(int(item.get("use_time_minutes", 0)), "use_item")
	_apply_item_effects(item)
	return true

func _apply_item_effects(item: Dictionary) -> void:
	var effects: Variant = item.get("effects", {})
	if not (effects is Dictionary) or (effects as Dictionary).is_empty():
		return
	var health_manager := _health_manager()
	if health_manager == null or not health_manager.has_method("apply_item_effects"):
		return
	health_manager.call("apply_item_effects", effects)

func _advance_time(minutes: int, reason: String) -> void:
	if minutes <= 0:
		return
	var manager := _time_manager()
	if manager == null or not manager.has_method("advance_time"):
		return
	manager.call("advance_time", minutes, reason)

## -- Durable items

## Returns the new instance_id, or "" if item_id isn't a durable item.
func add_durable_item(item_id: String) -> String:
	var item := ItemDatabaseScript.get_item(item_id)
	if item.is_empty() or not bool(item.get("has_durability", false)):
		return ""
	var instance_id := "tool_%04d" % _next_durable_instance_number
	_next_durable_instance_number += 1
	var max_durability := float(item.get("max_durability", 0.0))
	durable_items[instance_id] = {
		"item_id": item_id,
		"current_durability": max_durability,
		"max_durability": max_durability,
		"state": "normal",
	}
	last_durable_instance_id = instance_id
	_save_state()
	inventory_changed.emit()
	return instance_id

func use_durable_item(instance_id: String) -> bool:
	if not durable_items.has(instance_id):
		return false
	var instance: Dictionary = durable_items[instance_id]
	if String(instance.get("state", "normal")) == "broken":
		return false
	var item := ItemDatabaseScript.get_item(String(instance.get("item_id", "")))
	if item.is_empty():
		return false
	var loss := float(item.get("durability_loss_per_use", 0.0))
	var current: float = max(0.0, float(instance.get("current_durability", 0.0)) - loss)
	instance["current_durability"] = current
	if current <= 0.0 and bool(item.get("broken_when_zero", false)):
		instance["state"] = "broken"
	durable_items[instance_id] = instance
	_save_state()
	inventory_changed.emit()
	return true

func repair_durable_item(instance_id: String, amount: float) -> void:
	if not durable_items.has(instance_id):
		return
	var instance: Dictionary = durable_items[instance_id]
	var max_durability := float(instance.get("max_durability", 0.0))
	var current: float = clamp(float(instance.get("current_durability", 0.0)) + amount, 0.0, max_durability)
	instance["current_durability"] = current
	if current > 0.0:
		instance["state"] = "normal"
	durable_items[instance_id] = instance
	_save_state()
	inventory_changed.emit()

func get_durable_item_state(instance_id: String) -> Dictionary:
	return durable_items.get(instance_id, {})

## -- Display text

func get_category_label(category: String) -> String:
	match category:
		"food":
			return "食物"
		"seed":
			return "种子"
		"material":
			return "材料"
		"tool":
			return "工具"
		"consumable":
			return "消耗品"
		"component":
			return "部件"
		"specimen":
			return "样本"
		"quest_item":
			return "任务物品"
		"resource":
			return "系统资源"
	return category

func panel_status_text() -> String:
	var lines: Array[String] = ["广寒前哨库存"]
	var categories := ["food", "seed", "consumable", "material"]
	var any_stack := false
	for category in categories:
		var category_lines := _stack_lines_for_category(category)
		if category_lines.is_empty():
			continue
		any_stack = true
		lines.append("")
		lines.append("%s：" % get_category_label(category))
		lines.append_array(category_lines)
	var tool_lines := _durable_lines()
	if not tool_lines.is_empty():
		lines.append("")
		lines.append("工具：")
		lines.append_array(tool_lines)
	if not any_stack and tool_lines.is_empty():
		lines.append("")
		lines.append("暂无物品。")
	return "\n".join(lines)

func _stack_lines_for_category(category: String) -> Array[String]:
	var lines: Array[String] = []
	for item_id in ItemDatabaseScript.item_ids_by_category(category):
		var count := get_item_count(item_id)
		if count <= 0:
			continue
		lines.append("%s ×%d" % [ItemDatabaseScript.colored_display_name(item_id), count])
	return lines

func _durable_lines() -> Array[String]:
	var lines: Array[String] = []
	for instance_id in durable_items.keys():
		var instance: Dictionary = durable_items[instance_id]
		var item_id := String(instance.get("item_id", ""))
		var state_label := "损坏" if String(instance.get("state", "normal")) == "broken" else "正常"
		lines.append("%s：%.0f / %.0f（%s）" % [
			ItemDatabaseScript.colored_display_name(item_id),
			float(instance.get("current_durability", 0.0)),
			float(instance.get("max_durability", 0.0)),
			state_label,
		])
	return lines

func compact_hud_text() -> String:
	var stack_count := 0
	for item_id in stack_items.keys():
		stack_count += int(stack_items[item_id])
	return "库存：%d 件物品 · %d 件工具" % [stack_count, durable_items.size()]

## -- Debug helpers

func debug_add_sample_foods() -> void:
	for item_id in ["FO-CR-001", "FO-CR-002", "FO-CR-003", "FO-CR-004", "FO-CR-005"]:
		add_item(item_id, 1)

func debug_add_sample_seeds() -> void:
	for item_id in ["SD-CR-001", "SD-CR-002", "SD-CR-003", "SD-CR-004", "SD-CR-005"]:
		add_item(item_id, 1)

func debug_add_sample_consumables() -> void:
	for item_id in ["CN-FD-001", "CN-FD-002", "CN-MD-001", "CN-OX-001", "CN-IG-001"]:
		add_item(item_id, 1)

func debug_add_sample_materials() -> void:
	for item_id in ["MT-ME-001", "MT-EL-001", "MT-SE-001", "MT-FI-001", "MT-IN-001", "MT-GL-001"]:
		add_item(item_id, 1)

func debug_add_durable_drill() -> void:
	add_durable_item("TL-EX-002")

func debug_eat_lettuce() -> void:
	eat_item("FO-CR-001")

func debug_eat_nutrition_pack() -> void:
	eat_item("CN-FD-002")

func debug_use_last_durable_item() -> void:
	if not last_durable_instance_id.is_empty():
		use_durable_item(last_durable_instance_id)

func debug_values_text() -> String:
	var lines: Array[String] = ["StackItems: %d types" % stack_items.size()]
	for item_id in stack_items.keys():
		lines.append("  %s x%d" % [item_id, int(stack_items[item_id])])
	lines.append("DurableItems: %d" % durable_items.size())
	for instance_id in durable_items.keys():
		var instance: Dictionary = durable_items[instance_id]
		lines.append("  %s (%s): %.0f/%.0f %s" % [
			instance_id, String(instance.get("item_id", "")),
			float(instance.get("current_durability", 0.0)), float(instance.get("max_durability", 0.0)),
			String(instance.get("state", "normal")),
		])
	return "\n".join(lines)

## -- Persistence

func serialize() -> Dictionary:
	return {
		"stack_items": stack_items.duplicate(true),
		"durable_items": durable_items.duplicate(true),
		"last_durable_instance_id": last_durable_instance_id,
		"next_durable_instance_number": _next_durable_instance_number,
	}

func deserialize(data: Dictionary) -> void:
	var saved_stack: Variant = data.get("stack_items", {})
	stack_items = (saved_stack as Dictionary).duplicate(true) if saved_stack is Dictionary else {}
	var saved_durable: Variant = data.get("durable_items", {})
	durable_items = (saved_durable as Dictionary).duplicate(true) if saved_durable is Dictionary else {}
	last_durable_instance_id = String(data.get("last_durable_instance_id", last_durable_instance_id))
	_next_durable_instance_number = int(data.get("next_durable_instance_number", _next_durable_instance_number))
	inventory_changed.emit()

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
