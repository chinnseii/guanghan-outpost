extends RefCounted
class_name GuanghanItemContainer

const ItemDatabaseScript := preload("res://scripts/data/ItemDatabase.gd")

const SORT_ORDER := {
	"food": 10,
	"consumable": 20,
	"seed": 30,
	"material": 40,
	"tool": 50,
	"component": 60,
	"specimen": 70,
	"quest_item": 80,
	"resource": 90,
	"other": 99,
}

static func empty_slots(capacity: int) -> Array:
	var slots: Array = []
	for _i in range(max(0, capacity)):
		slots.append(null)
	return slots

static func normalize_slots(raw_slots: Variant, capacity: int) -> Array:
	var slots: Array = []
	if raw_slots is Array:
		for raw_slot in raw_slots:
			if raw_slot is Dictionary and _valid_slot(raw_slot as Dictionary):
				slots.append((raw_slot as Dictionary).duplicate(true))
			else:
				slots.append(null)
	while slots.size() < capacity:
		slots.append(null)
	if slots.size() > capacity:
		slots.resize(capacity)
	return slots

static func used_slots(slots: Array) -> int:
	var count := 0
	for slot in slots:
		if slot is Dictionary and _valid_slot(slot as Dictionary):
			count += 1
	return count

static func item_count(slots: Array, item_id: String) -> int:
	var total := 0
	for slot in slots:
		if not (slot is Dictionary):
			continue
		var data := slot as Dictionary
		if String(data.get("item_id", "")) == item_id:
			total += int(data.get("quantity", 0))
	return total

static func add_item(slots: Array, item_id: String, amount: int, container_kind: String) -> Dictionary:
	var result := {"accepted": 0, "rejected": max(0, amount)}
	if amount <= 0 or not allows_item(item_id, container_kind):
		return result
	var item := ItemDatabaseScript.get_item(item_id)
	if item.is_empty() or bool(item.get("has_durability", false)):
		return result
	var max_stack := _max_stack_for_item(item_id, item)
	var remaining := amount
	if _is_stackable_item(item_id, item):
		for i in range(slots.size()):
			if remaining <= 0:
				break
			if not (slots[i] is Dictionary):
				continue
			var slot: Dictionary = slots[i]
			if String(slot.get("item_id", "")) != item_id or not String(slot.get("instance_id", "")).is_empty():
				continue
			var current := int(slot.get("quantity", 0))
			if current >= max_stack:
				continue
			var add_count: int = min(remaining, max_stack - current)
			slot["quantity"] = current + add_count
			slots[i] = slot
			remaining -= add_count
	while remaining > 0:
		var empty_index := first_empty_index(slots)
		if empty_index < 0:
			break
		var add_count: int = min(remaining, max_stack)
		slots[empty_index] = {
			"item_id": item_id,
			"quantity": add_count,
			"instance_id": "",
		}
		remaining -= add_count
	result["accepted"] = amount - remaining
	result["rejected"] = remaining
	return result

static func add_durable_slot(slots: Array, item_id: String, instance_id: String) -> bool:
	if first_empty_index(slots) < 0:
		return false
	var item := ItemDatabaseScript.get_item(item_id)
	if item.is_empty() or not bool(item.get("has_durability", false)):
		return false
	var empty_index := first_empty_index(slots)
	slots[empty_index] = {
		"item_id": item_id,
		"quantity": 1,
		"instance_id": instance_id,
		"current_durability": float(item.get("max_durability", 0.0)),
		"max_durability": float(item.get("max_durability", 0.0)),
		"state": "normal",
	}
	return true

static func add_existing_slot(slots: Array, source_slot: Dictionary, container_kind: String, amount: int = -1) -> Dictionary:
	var rejected: Variant = source_slot.duplicate(true)
	var accepted := 0
	if not _valid_slot(source_slot):
		return {"accepted": 0, "rejected_slot": rejected}
	var item_id := String(source_slot.get("item_id", ""))
	if not allows_item(item_id, container_kind):
		return {"accepted": 0, "rejected_slot": rejected}
	var instance_id := String(source_slot.get("instance_id", ""))
	if not instance_id.is_empty():
		if first_empty_index(slots) < 0:
			return {"accepted": 0, "rejected_slot": rejected}
		var empty_index := first_empty_index(slots)
		slots[empty_index] = source_slot.duplicate(true)
		return {"accepted": 1, "rejected_slot": null}
	var requested := int(source_slot.get("quantity", 0))
	if amount > 0:
		requested = min(requested, amount)
	var result := add_item(slots, item_id, requested, container_kind)
	accepted = int(result.get("accepted", 0))
	var remaining := int(source_slot.get("quantity", 0)) - accepted
	if remaining <= 0:
		rejected = null
	else:
		rejected["quantity"] = remaining
	return {"accepted": accepted, "rejected_slot": rejected}

static func remove_item(slots: Array, item_id: String, amount: int) -> bool:
	if amount <= 0 or item_count(slots, item_id) < amount:
		return false
	var remaining := amount
	for i in range(slots.size()):
		if remaining <= 0:
			break
		if not (slots[i] is Dictionary):
			continue
		var slot: Dictionary = slots[i]
		if String(slot.get("item_id", "")) != item_id or not String(slot.get("instance_id", "")).is_empty():
			continue
		var current := int(slot.get("quantity", 0))
		var take_count: int = min(current, remaining)
		current -= take_count
		remaining -= take_count
		if current <= 0:
			slots[i] = null
		else:
			slot["quantity"] = current
			slots[i] = slot
	return true

static func take_from_slot(slots: Array, slot_index: int, amount: int = -1) -> Dictionary:
	if slot_index < 0 or slot_index >= slots.size() or not (slots[slot_index] is Dictionary):
		return {}
	var slot: Dictionary = (slots[slot_index] as Dictionary).duplicate(true)
	var instance_id := String(slot.get("instance_id", ""))
	if not instance_id.is_empty():
		slots[slot_index] = null
		return slot
	var current := int(slot.get("quantity", 0))
	var take_count: int = current if amount <= 0 else min(current, amount)
	var taken := slot.duplicate(true)
	taken["quantity"] = take_count
	var remaining := current - take_count
	if remaining <= 0:
		slots[slot_index] = null
	else:
		slot["quantity"] = remaining
		slots[slot_index] = slot
	return taken

static func sort_slots(slots: Array) -> Array:
	var items: Array[Dictionary] = []
	for slot in slots:
		if slot is Dictionary and _valid_slot(slot as Dictionary):
			items.append((slot as Dictionary).duplicate(true))
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _slot_sort_less(a, b)
	)
	var compacted: Array = []
	for slot in items:
		var instance_id := String(slot.get("instance_id", ""))
		var item_id := String(slot.get("item_id", ""))
		var item := ItemDatabaseScript.get_item(item_id)
		if instance_id.is_empty() and _is_stackable_item(item_id, item):
			var quantity := int(slot.get("quantity", 0))
			while quantity > 0:
				var add_count: int = min(quantity, _max_stack_for_item(item_id, item))
				compacted.append({"item_id": item_id, "quantity": add_count, "instance_id": ""})
				quantity -= add_count
		else:
			compacted.append(slot)
	while compacted.size() < slots.size():
		compacted.append(null)
	if compacted.size() > slots.size():
		compacted.resize(slots.size())
	return compacted

static func allows_item(item_id: String, container_kind: String) -> bool:
	var item := ItemDatabaseScript.get_item(item_id)
	if item.is_empty():
		return false
	if item_id == "RS-IC-001":
		return container_kind == "backpack"
	if String(item.get("storage_type", "")) == "system":
		return false
	if String(item.get("storage_type", "")) == "default":
		return false
	var category := String(item.get("category", ""))
	match container_kind:
		"backpack":
			return category in ["food", "seed", "material", "tool", "consumable", "specimen", "quest_item", "component"]
		"storage":
			return category in ["food", "seed", "material", "tool", "consumable", "specimen", "quest_item", "component"]
	return false

static func first_empty_index(slots: Array) -> int:
	for i in range(slots.size()):
		if slots[i] == null:
			return i
	return -1

static func slot_label(slot: Dictionary) -> String:
	if not _valid_slot(slot):
		return "Empty"
	var item_id := String(slot.get("item_id", ""))
	var item := ItemDatabaseScript.get_item(item_id)
	var name := String(item.get("display_name", item_id))
	var instance_id := String(slot.get("instance_id", ""))
	if not instance_id.is_empty():
		return "%s %.0f/%.0f %s" % [
			name,
			float(slot.get("current_durability", 0.0)),
			float(slot.get("max_durability", 0.0)),
			String(slot.get("state", "normal")),
		]
	return "%s x%d" % [name, int(slot.get("quantity", 0))]

static func category_label(category: String) -> String:
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

static func _valid_slot(slot: Dictionary) -> bool:
	return not String(slot.get("item_id", "")).is_empty() and int(slot.get("quantity", 0)) > 0

static func _is_stackable_item(item_id: String, item: Dictionary) -> bool:
	if item_id == "RS-IC-001":
		return true
	return bool(item.get("stackable", false)) and not bool(item.get("has_durability", false))

static func _max_stack_for_item(item_id: String, item: Dictionary) -> int:
	if item_id == "RS-IC-001":
		return 99
	return max(1, int(item.get("max_stack", 1)))

static func _slot_sort_less(a: Dictionary, b: Dictionary) -> bool:
	var key_a := _slot_sort_key(a)
	var key_b := _slot_sort_key(b)
	for i in range(key_a.size()):
		if key_a[i] == key_b[i]:
			continue
		return key_a[i] < key_b[i]
	return false

static func _slot_sort_key(slot: Dictionary) -> Array:
	var item_id := String(slot.get("item_id", ""))
	var item := ItemDatabaseScript.get_item(item_id)
	var category := String(item.get("category", "other"))
	var instance_state := String(slot.get("state", "normal"))
	var durability_order := -float(slot.get("current_durability", 0.0))
	return [
		int(SORT_ORDER.get(category, 99)),
		String(item.get("subcategory", "")),
		item_id,
		instance_state,
		durability_order,
	]
