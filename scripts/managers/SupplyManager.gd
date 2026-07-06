extends Node
class_name GuanghanSupplyManager

signal supply_changed
signal supply_deadline_passed(supply_id: String, status: String)
signal supply_delivered(supply_id: String)

const SAVE_PATH := "user://saves/supply_state.json"
const ItemDatabaseScript := preload("res://scripts/data/ItemDatabase.gd")

const SUPPLY_INTERVAL_MINUTES := 7 * 24 * 60
const SUPPLY_LOCK_BEFORE_MINUTES := 3 * 24 * 60
const DEFAULT_SUPPLY_WEIGHT_LIMIT := 300.0
const FORCED_ITEM_WEIGHT_RATIO := 1.0 / 3.0
const FIRST_FORCED_ITEM_ID := "QI-VE-001"

const SUPPLY_ALLOWED_ITEM_IDS := [
	"CN-FD-001",
	"CN-FD-002",
	"SD-CR-001",
	"SD-CR-002",
	"SD-CR-003",
	"SD-CR-004",
	"SD-CR-005",
	"MT-ME-001",
	"MT-EL-001",
	"MT-SE-001",
	"MT-FI-001",
	"MT-IN-001",
	"CN-MD-001",
	"CN-OX-001",
	"CN-IG-001",
]

var supply_index: int = 0
var supplies: Array = []
var supply_weight_limit: float = DEFAULT_SUPPLY_WEIGHT_LIMIT
var forced_supply_items: Dictionary = {}
var unlocked_special_items: Dictionary = {}
var pending_supply_items: Dictionary = {}
var last_notice: String = ""

func _ready() -> void:
	load_state()

func reset_to_arrival() -> void:
	supply_index = 0
	supplies = []
	supply_weight_limit = DEFAULT_SUPPLY_WEIGHT_LIMIT
	forced_supply_items = {}
	unlocked_special_items = {}
	pending_supply_items = {}
	last_notice = ""
	create_next_supply_schedule()
	_save_state()
	supply_changed.emit()

func create_next_supply_schedule() -> void:
	if _has_active_supply():
		return
	supply_index += 1
	var arrival_time := supply_index * SUPPLY_INTERVAL_MINUTES
	var forced_items := _forced_items_for_supply(supply_index)
	var reserved_weight := 0.0
	if not forced_items.is_empty():
		reserved_weight = supply_weight_limit * FORCED_ITEM_WEIGHT_RATIO
		var per_item_weight := reserved_weight / float(forced_items.size())
		for forced in forced_items:
			forced["reserved_weight"] = per_item_weight
	var supply := {
		"supply_id": "supply_%03d" % supply_index,
		"supply_index": supply_index,
		"arrival_time_minutes": arrival_time,
		"deadline_time_minutes": arrival_time - SUPPLY_LOCK_BEFORE_MINUTES,
		"status": "draft",
		"weight_limit": supply_weight_limit,
		"reserved_weight": reserved_weight,
		"free_weight_limit": supply_weight_limit - reserved_weight,
		"forced_items": forced_items,
		"selected_items": {},
		"confirmed": false,
	}
	supplies.append(supply)
	_save_state()
	supply_changed.emit()

func get_current_supply() -> Dictionary:
	for supply in supplies:
		if not (supply is Dictionary):
			continue
		var status := String((supply as Dictionary).get("status", ""))
		if status in ["draft", "confirmed", "locked"]:
			return supply as Dictionary
	if supplies.is_empty():
		create_next_supply_schedule()
		return get_current_supply()
	return {}

func update_supply_draft(item_id: String, amount: int) -> bool:
	var supply := get_current_supply()
	if supply.is_empty() or not _is_editable(supply):
		return false
	if not is_item_supply_allowed(item_id):
		return false
	var selected: Dictionary = supply.get("selected_items", {})
	var old_amount := int(selected.get(item_id, 0))
	if amount <= 0:
		selected.erase(item_id)
	else:
		selected[item_id] = amount
	supply["selected_items"] = selected
	if get_selected_weight(supply) > float(supply.get("free_weight_limit", 0.0)):
		if old_amount <= 0:
			selected.erase(item_id)
		else:
			selected[item_id] = old_amount
		supply["selected_items"] = selected
		return false
	supply["status"] = "draft"
	supply["confirmed"] = false
	_save_state()
	supply_changed.emit()
	return true

func clear_supply_draft() -> void:
	var supply := get_current_supply()
	if supply.is_empty() or not _is_editable(supply):
		return
	supply["selected_items"] = {}
	supply["status"] = "draft"
	supply["confirmed"] = false
	_save_state()
	supply_changed.emit()

func confirm_supply_order() -> bool:
	var supply := get_current_supply()
	if supply.is_empty() or not _is_editable(supply):
		return false
	if _current_time_minutes() >= int(supply.get("deadline_time_minutes", 0)):
		return false
	if get_selected_weight(supply) > float(supply.get("free_weight_limit", 0.0)):
		return false
	supply["confirmed"] = true
	supply["status"] = "confirmed"
	_save_state()
	supply_changed.emit()
	return true

func set_forced_supply_item(target_supply_index: int, item_id: String) -> void:
	if target_supply_index <= 0 or item_id.is_empty():
		return
	var key := str(target_supply_index)
	var items: Array = forced_supply_items.get(key, [])
	if not item_id in items:
		items.append(item_id)
	forced_supply_items[key] = items
	_save_state()

func get_selected_weight(supply: Dictionary = {}) -> float:
	var target := supply if not supply.is_empty() else get_current_supply()
	if target.is_empty():
		return 0.0
	var selected: Dictionary = target.get("selected_items", {})
	var total := 0.0
	for item_id in selected.keys():
		total += get_item_supply_weight(String(item_id)) * float(int(selected[item_id]))
	return total

func get_reserved_weight(supply: Dictionary = {}) -> float:
	var target := supply if not supply.is_empty() else get_current_supply()
	return float(target.get("reserved_weight", 0.0)) if not target.is_empty() else 0.0

func get_free_weight_limit(supply: Dictionary = {}) -> float:
	var target := supply if not supply.is_empty() else get_current_supply()
	return float(target.get("free_weight_limit", 0.0)) if not target.is_empty() else 0.0

func get_remaining_weight(supply: Dictionary = {}) -> float:
	var target := supply if not supply.is_empty() else get_current_supply()
	if target.is_empty():
		return 0.0
	return max(0.0, get_free_weight_limit(target) - get_selected_weight(target))

func get_item_supply_weight(item_id: String) -> float:
	var item := ItemDatabaseScript.get_item(item_id)
	if item.is_empty():
		return 0.0
	if item.has("supply_weight"):
		return float(item["supply_weight"])
	return float(item.get("weight", 0.0))

func is_item_supply_allowed(item_id: String) -> bool:
	var item := ItemDatabaseScript.get_item(item_id)
	if item.is_empty():
		return false
	if bool(item.get("supply_allowed", false)):
		return true
	return item_id in SUPPLY_ALLOWED_ITEM_IDS

func check_supply_events(previous_minutes: int, current_minutes: int) -> void:
	var changed := false
	for supply in supplies:
		if not (supply is Dictionary):
			continue
		var data := supply as Dictionary
		if String(data.get("status", "")) in ["delivered", "missed"]:
			continue
		var deadline := int(data.get("deadline_time_minutes", 0))
		var arrival := int(data.get("arrival_time_minutes", 0))
		if previous_minutes < deadline and deadline <= current_minutes:
			handle_supply_deadline(data)
			changed = true
		if previous_minutes < arrival and arrival <= current_minutes:
			handle_supply_arrival(data)
			changed = true
	if changed:
		_save_state()
		supply_changed.emit()

func handle_supply_deadline(supply: Dictionary) -> void:
	if String(supply.get("status", "")) in ["delivered", "missed", "locked"]:
		return
	if bool(supply.get("confirmed", false)):
		supply["status"] = "locked"
		last_notice = "补给清单已锁定，等待地球发射窗口。"
	else:
		supply["status"] = "missed"
		supply["confirmed"] = false
		last_notice = "本次补给清单未在截止时间前提交。\n地球发射窗口已关闭。\n本次补给机会已失效。"
	supply_deadline_passed.emit(String(supply.get("supply_id", "")), String(supply.get("status", "")))

func handle_supply_arrival(supply: Dictionary) -> void:
	var status := String(supply.get("status", ""))
	if status == "locked":
		deliver_supply(supply)
		supply["status"] = "delivered"
		last_notice = "补给已到达，物资已送入仓库。"
		supply_delivered.emit(String(supply.get("supply_id", "")))
		create_next_supply_schedule()
	elif status == "missed":
		create_next_supply_schedule()

func deliver_supply(supply: Dictionary) -> void:
	var forced_items: Array = supply.get("forced_items", [])
	for forced in forced_items:
		if forced is Dictionary:
			deliver_supply_item(String((forced as Dictionary).get("item_id", "")), int((forced as Dictionary).get("amount", 1)), true)
	var selected: Dictionary = supply.get("selected_items", {})
	for item_id in selected.keys():
		deliver_supply_item(String(item_id), int(selected[item_id]), false)
	_save_state()

func deliver_supply_item(item_id: String, amount: int, is_forced: bool = false) -> void:
	if item_id.is_empty() or amount <= 0:
		return
	if is_forced or _is_special_supply_item(item_id):
		unlocked_special_items[item_id] = true
		if item_id == FIRST_FORCED_ITEM_ID:
			unlocked_special_items["has_lunar_rover"] = true
		return
	var item := ItemDatabaseScript.get_item(item_id)
	if item.is_empty():
		_add_pending_supply_item(item_id, amount)
		return
	if _deliver_to_resource_system(item_id, amount):
		return
	var storage_manager := _storage_manager()
	if storage_manager == null:
		_add_pending_supply_item(item_id, amount)
		return
	var rejected := amount
	if bool(item.get("has_durability", false)) and storage_manager.has_method("add_durable_item"):
		rejected = _deliver_durable_to_storage(storage_manager, item_id, amount)
	elif storage_manager.has_method("add_item"):
		var result: Dictionary = storage_manager.call("add_item", item_id, amount)
		rejected = int(result.get("rejected", 0))
	if rejected > 0:
		_add_pending_supply_item(item_id, rejected)

func panel_status_text() -> String:
	var supply := get_current_supply()
	if supply.is_empty():
		return "暂无补给排期。"
	var lines: Array[String] = [
		"地球补给：%s" % String(supply.get("supply_id", "")),
		"到达：%s" % _format_time(int(supply.get("arrival_time_minutes", 0))),
		"截止：%s" % _format_time(int(supply.get("deadline_time_minutes", 0))),
		"状态：%s" % _status_label(String(supply.get("status", ""))),
		"总重量：%.0f CU" % float(supply.get("weight_limit", 0.0)),
		"强制占用：%.0f CU" % get_reserved_weight(supply),
		"可选重量：%.0f CU" % get_free_weight_limit(supply),
		"已选：%.0f CU / 剩余：%.0f CU" % [get_selected_weight(supply), get_remaining_weight(supply)],
	]
	var forced: Array = supply.get("forced_items", [])
	if not forced.is_empty():
		lines.append("强制货物：")
		for entry in forced:
			if entry is Dictionary:
				lines.append("- %s x%d  %.0f CU" % [
					_item_display_name(String((entry as Dictionary).get("item_id", ""))),
					int((entry as Dictionary).get("amount", 1)),
					float((entry as Dictionary).get("reserved_weight", 0.0)),
				])
	var selected: Dictionary = supply.get("selected_items", {})
	if not selected.is_empty():
		lines.append("自由补给：")
		for item_id in selected.keys():
			lines.append("- %s x%d" % [_item_display_name(String(item_id)), int(selected[item_id])])
	if not pending_supply_items.is_empty():
		lines.append("待领取：%s" % str(pending_supply_items))
	return "\n".join(lines)

func debug_values_text() -> String:
	return panel_status_text()

func debug_select_starter_supply() -> void:
	update_supply_draft("CN-FD-001", 10)
	update_supply_draft("CN-FD-002", 5)
	update_supply_draft("MT-EL-001", 8)
	update_supply_draft("MT-SE-001", 5)

func debug_jump_to_deadline() -> void:
	var supply := get_current_supply()
	if supply.is_empty():
		return
	var target := int(supply.get("deadline_time_minutes", 0))
	_advance_time_to(target)

func debug_jump_to_arrival() -> void:
	var supply := get_current_supply()
	if supply.is_empty():
		return
	var target := int(supply.get("arrival_time_minutes", 0))
	_advance_time_to(target)

func consume_notice() -> String:
	var text := last_notice
	last_notice = ""
	return text

func serialize() -> Dictionary:
	return {
		"supply_index": supply_index,
		"supplies": supplies.duplicate(true),
		"supply_weight_limit": supply_weight_limit,
		"forced_supply_items": forced_supply_items.duplicate(true),
		"unlocked_special_items": unlocked_special_items.duplicate(true),
		"pending_supply_items": pending_supply_items.duplicate(true),
		"last_notice": last_notice,
	}

func deserialize(data: Dictionary) -> void:
	supply_index = int(data.get("supply_index", supply_index))
	supplies = _normalize_supplies(data.get("supplies", []))
	supply_weight_limit = float(data.get("supply_weight_limit", supply_weight_limit))
	forced_supply_items = data.get("forced_supply_items", {}).duplicate(true) if data.get("forced_supply_items", {}) is Dictionary else {}
	unlocked_special_items = data.get("unlocked_special_items", {}).duplicate(true) if data.get("unlocked_special_items", {}) is Dictionary else {}
	pending_supply_items = data.get("pending_supply_items", {}).duplicate(true) if data.get("pending_supply_items", {}) is Dictionary else {}
	last_notice = String(data.get("last_notice", last_notice))
	if supplies.is_empty():
		create_next_supply_schedule()
	supply_changed.emit()

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

func _forced_items_for_supply(target_supply_index: int) -> Array:
	var ids: Array = []
	if target_supply_index == 1:
		ids.append(FIRST_FORCED_ITEM_ID)
	var custom: Variant = forced_supply_items.get(str(target_supply_index), [])
	if custom is Array:
		for item_id in custom:
			var custom_id := String(item_id)
			if not ids.has(custom_id):
				ids.append(custom_id)
	var result: Array = []
	for item_id in ids:
		result.append({
			"item_id": String(item_id),
			"amount": 1,
			"reserved_weight": 0.0,
		})
	return result

func _has_active_supply() -> bool:
	for supply in supplies:
		if not (supply is Dictionary):
			continue
		if String((supply as Dictionary).get("status", "")) in ["draft", "confirmed", "locked"]:
			return true
	return false

func _is_editable(supply: Dictionary) -> bool:
	return String(supply.get("status", "")) in ["draft", "confirmed"] and _current_time_minutes() < int(supply.get("deadline_time_minutes", 0))

func _current_time_minutes() -> int:
	var manager := _time_manager()
	if manager == null:
		return 0
	return int(manager.get("total_minutes"))

func _advance_time_to(target_minutes: int) -> void:
	var manager := _time_manager()
	if manager == null or not manager.has_method("advance_time"):
		return
	var current := int(manager.get("total_minutes"))
	if target_minutes > current:
		manager.call("advance_time", target_minutes - current, "debug_jump_supply")

func _deliver_durable_to_storage(storage_manager: Node, item_id: String, amount: int) -> int:
	var rejected := 0
	for _i in range(amount):
		var instance_id := String(storage_manager.call("add_durable_item", item_id))
		if instance_id.is_empty():
			rejected += 1
	return rejected

func _deliver_to_resource_system(item_id: String, amount: int) -> bool:
	match item_id:
		"RS-WA-001":
			var water := _water_system_manager()
			if water != null and water.has_method("add_water"):
				water.call("add_water", float(amount))
				return true
		"RS-IC-001":
			var water := _water_system_manager()
			if water != null and water.has_method("add_ice"):
				water.call("add_ice", float(amount))
				return true
		"RS-IG-001":
			return _adjust_air_stat("inert_gas_reserve", float(amount))
		"RS-OX-001":
			return _adjust_air_stat("o2_percent", float(amount))
	return false

func _adjust_air_stat(stat_name: String, amount: float) -> bool:
	var air := _air_system_manager()
	if air != null and air.has_method("adjust_stat"):
		air.call("adjust_stat", stat_name, amount)
		return true
	return false

func _add_pending_supply_item(item_id: String, amount: int) -> void:
	if amount <= 0:
		return
	pending_supply_items[item_id] = int(pending_supply_items.get(item_id, 0)) + amount

func _is_special_supply_item(item_id: String) -> bool:
	return item_id.begins_with("QI-") or item_id == FIRST_FORCED_ITEM_ID

func _normalize_supplies(raw_supplies: Variant) -> Array:
	var result: Array = []
	if not (raw_supplies is Array):
		return result
	for raw_supply in raw_supplies:
		if raw_supply is Dictionary:
			var supply := (raw_supply as Dictionary).duplicate(true)
			if not supply.has("selected_items") or not (supply["selected_items"] is Dictionary):
				supply["selected_items"] = {}
			if not supply.has("forced_items") or not (supply["forced_items"] is Array):
				supply["forced_items"] = []
			result.append(supply)
	return result

func _format_time(minutes_value: int) -> String:
	var start_hour := 6
	var start_minute := 40
	var minutes_per_day := 24 * 60
	var total_from_start: int = start_hour * 60 + start_minute + max(0, minutes_value)
	var day := 1 + int(total_from_start / minutes_per_day)
	var hour := int(total_from_start / 60) % 24
	var minute: int = total_from_start % 60
	return "Day %02d %02d:%02d" % [day, hour, minute]

func _status_label(status: String) -> String:
	match status:
		"draft":
			return "草稿"
		"confirmed":
			return "已确认"
		"locked":
			return "已锁定"
		"missed":
			return "已错过"
		"delivered":
			return "已送达"
	return status

func _item_display_name(item_id: String) -> String:
	if item_id == FIRST_FORCED_ITEM_ID:
		return "月球车"
	var item := ItemDatabaseScript.get_item(item_id)
	return String(item.get("display_name", item_id)) if not item.is_empty() else item_id

func _time_manager() -> Node:
	return get_tree().root.get_node_or_null("TimeManager")

func _storage_manager() -> Node:
	return get_tree().root.get_node_or_null("StorageManager")

func _water_system_manager() -> Node:
	return get_tree().root.get_node_or_null("WaterSystemManager")

func _air_system_manager() -> Node:
	return get_tree().root.get_node_or_null("AirSystemManager")
