extends Node

const FullSaveOrchestratorScript := preload("res://scripts/systems/full_save_orchestrator.gd")

signal repair_state_changed
signal repair_notice(text: String)

const SAVE_PATH := "user://saves/repair_state.json"
const DIAGNOSIS_TIME_MINUTES := 15
const FaultDatabaseScript := preload("res://scripts/data/FaultDatabase.gd")

var active_faults: Dictionary = {}
var repair_history: Array = []
var last_notice: String = ""

func _ready() -> void:
	load_state()

func reset_to_arrival() -> void:
	active_faults.clear()
	repair_history.clear()
	last_notice = ""
	_save_state()
	repair_state_changed.emit()

func add_fault(fault_id: String) -> bool:
	if not FaultDatabaseScript.has_fault(fault_id):
		_set_notice("未找到故障：%s" % fault_id)
		return false
	if active_faults.has(fault_id) and bool((active_faults[fault_id] as Dictionary).get("is_active", true)):
		return true
	active_faults[fault_id] = {
		"is_active": true,
		"excluded_options": [],
		"diagnosis_count": 0,
		"attempts": 0,
		"worsening": 0,
		"last_result": "",
	}
	_record_history("fault_added", fault_id, "")
	_save_state()
	repair_state_changed.emit()
	return true

func remove_fault(fault_id: String) -> bool:
	if not active_faults.has(fault_id):
		return false
	active_faults.erase(fault_id)
	_record_history("fault_removed", fault_id, "")
	_save_state()
	repair_state_changed.emit()
	return true

func get_active_faults() -> Array:
	var result: Array = []
	for fault_id in active_faults.keys():
		var runtime: Dictionary = active_faults[fault_id] as Dictionary
		if not bool(runtime.get("is_active", true)):
			continue
		result.append(get_fault_data(String(fault_id)))
	return result

func get_fault_data(fault_id: String) -> Dictionary:
	var fault: Dictionary = FaultDatabaseScript.get_fault(fault_id)
	if fault.is_empty():
		return {}
	var runtime: Dictionary = active_faults.get(fault_id, {}) as Dictionary
	fault["is_active"] = bool(runtime.get("is_active", false))
	fault["excluded_options"] = (runtime.get("excluded_options", []) as Array).duplicate()
	fault["diagnosis_count"] = int(runtime.get("diagnosis_count", 0))
	fault["attempts"] = int(runtime.get("attempts", 0))
	fault["worsening"] = int(runtime.get("worsening", 0))
	fault["last_result"] = String(runtime.get("last_result", ""))
	return fault

func diagnose_fault(fault_id: String) -> Dictionary:
	if not _fault_is_active(fault_id):
		return {"ok": false, "message": "当前故障不存在或已解除。"}

	var fault: Dictionary = FaultDatabaseScript.get_fault(fault_id)
	var excluded_options: Array = _runtime_array(fault_id, "excluded_options")
	var wrong_options: Array = []
	for option in fault.get("repair_options", []):
		if not (option is Dictionary):
			continue
		var option_data: Dictionary = option
		var option_id := String(option_data.get("option_id", ""))
		if not bool(option_data.get("is_correct", false)) and not excluded_options.has(option_id):
			wrong_options.append(option_id)

	var excluded_option_id := ""
	if not wrong_options.is_empty():
		excluded_option_id = String(wrong_options[0])
		excluded_options.append(excluded_option_id)

	var runtime: Dictionary = active_faults[fault_id] as Dictionary
	runtime["excluded_options"] = excluded_options
	runtime["diagnosis_count"] = int(runtime.get("diagnosis_count", 0)) + 1
	active_faults[fault_id] = runtime

	_advance_time(DIAGNOSIS_TIME_MINUTES, "fault_diagnosis")
	var message := "诊断完成：排除一个低可信维修方案。"
	if excluded_option_id == "":
		message = "诊断完成：暂无更多可排除方案。"
	_set_notice(message)
	_record_history("diagnosed", fault_id, excluded_option_id)
	_save_state()
	repair_state_changed.emit()
	return {
		"ok": true,
		"fault_id": fault_id,
		"excluded_option_id": excluded_option_id,
		"message": message,
		"hint": String(fault.get("hidden_hint", "")),
	}

func attempt_repair(fault_id: String, option_id: String) -> bool:
	if not _fault_is_active(fault_id):
		_set_notice("当前故障不存在或已解除。")
		return false

	var fault: Dictionary = FaultDatabaseScript.get_fault(fault_id)
	var option: Dictionary = _find_option(fault, option_id)
	if option.is_empty():
		_set_notice("未找到维修方案：%s" % option_id)
		return false

	if bool(option.get("is_correct", false)):
		return apply_repair_success(fault_id, option_id)
	return apply_repair_failure(fault_id, option_id)

func apply_repair_success(fault_id: String, option_id: String) -> bool:
	var fault: Dictionary = FaultDatabaseScript.get_fault(fault_id)
	var option: Dictionary = _find_option(fault, option_id)
	var required_items: Dictionary = option.get("required_items", {}) as Dictionary
	if not _has_items(required_items):
		_set_notice("维修材料不足。")
		return false
	if not _consume_items(required_items):
		_set_notice("维修材料扣除失败。")
		return false

	_advance_time(int(option.get("time_cost_minutes", 0)), "repair_success")
	_apply_effects(fault.get("on_repair_success", {}))
	var runtime: Dictionary = active_faults.get(fault_id, {}) as Dictionary
	runtime["is_active"] = false
	runtime["attempts"] = int(runtime.get("attempts", 0)) + 1
	runtime["last_result"] = "success"
	active_faults[fault_id] = runtime

	var message := "%s 已完成维修。" % String(fault.get("display_name", fault_id))
	_set_notice(message)
	_record_history("repair_success", fault_id, option_id)
	_save_state()
	repair_state_changed.emit()
	return true

func apply_repair_failure(fault_id: String, option_id: String) -> bool:
	var fault: Dictionary = FaultDatabaseScript.get_fault(fault_id)
	var option: Dictionary = _find_option(fault, option_id)
	var wrong_item_loss: Dictionary = option.get("wrong_item_loss", {}) as Dictionary
	if not _has_items(wrong_item_loss):
		_set_notice("执行该方案所需材料不足。")
		return false
	if not _consume_items(wrong_item_loss):
		_set_notice("材料扣除失败。")
		return false

	_advance_time(int(option.get("wrong_time_cost_minutes", 0)), "repair_failure")
	_apply_effects(option.get("wrong_extra_effect", {}))
	var runtime: Dictionary = active_faults.get(fault_id, {}) as Dictionary
	runtime["attempts"] = int(runtime.get("attempts", 0)) + 1
	runtime["last_result"] = "failure"
	if int(fault.get("severity", 1)) >= 3:
		runtime["worsening"] = int(runtime.get("worsening", 0)) + 1
	active_faults[fault_id] = runtime

	var message := "维修方案未解除故障。"
	if int(fault.get("severity", 1)) >= 3:
		message = "维修方案未解除故障，系统风险上升。"
	_set_notice(message)
	_record_history("repair_failure", fault_id, option_id)
	_save_state()
	repair_state_changed.emit()
	return true

## Training-aware repair entry point, additive alongside attempt_repair()
## (which remains completely unchanged for the real mission). Returns a
## rich result dict {success, fault_fixed, option_type, message, new_hint}
## instead of a bare bool. When context.context == "training", materials
## come from an InventoryManager container (context.container_id) instead
## of the real StorageManager, time goes to TrainingTimeManager instead of
## the real TimeManager, and _apply_effects()/active_faults/
## repair_history/_save_state() are all skipped entirely -- training must
## never touch BaseStatusManager/AirSystemManager/WaterSystemManager/
## PowerSystemManager, and doesn't need this manager's own persistent
## fault-tracking state (the training room tracks its own progress via its
## step engine). For context == "mission" (the default), this just wraps
## attempt_repair() in the same result shape, unconditionally still going
## through the untouched real-system codepath.
func apply_repair_option(fault_id: String, option_id: String, context: Dictionary = {}) -> Dictionary:
	if String(context.get("context", "mission")) != "training":
		return _apply_mission_repair_option(fault_id, option_id)
	return _apply_training_repair_option(fault_id, option_id, context)

func _apply_mission_repair_option(fault_id: String, option_id: String) -> Dictionary:
	var fault: Dictionary = FaultDatabaseScript.get_fault(fault_id)
	var option: Dictionary = _find_option(fault, option_id)
	if option.is_empty():
		return {"success": false, "fault_fixed": false, "message": "未找到维修方案：%s" % option_id}
	var is_correct := bool(option.get("is_correct", false))
	var ok := attempt_repair(fault_id, option_id)
	return {
		"success": ok,
		"fault_fixed": ok and is_correct,
		"option_type": "correct" if is_correct else "wrong",
		"message": last_notice,
	}

func _apply_training_repair_option(fault_id: String, option_id: String, context: Dictionary) -> Dictionary:
	var fault: Dictionary = FaultDatabaseScript.get_fault(fault_id)
	if fault.is_empty():
		return {"success": false, "fault_fixed": false, "message": "未找到故障：%s" % fault_id}
	var option: Dictionary = _find_option(fault, option_id)
	if option.is_empty():
		return {"success": false, "fault_fixed": false, "message": "未找到维修方案：%s" % option_id}

	var container_id := String(context.get("container_id", ""))
	var is_correct := bool(option.get("is_correct", false))
	# Training fault options (raw dict literals in FaultDatabase._faults(),
	# not the shared _option() helper used by mission-only faults) always
	# store their material cost under "required_items", for correct AND
	# wrong choices alike -- there is no separate "wrong_item_loss" key here.
	var items: Dictionary = option.get("required_items", {}) as Dictionary
	var option_type := String(option.get("option_type", "correct" if is_correct else "wrong"))
	var suit_oxygen_cost: float = float(option.get("suit_oxygen_cost", 0.0))
	var suit_power_cost: float = float(option.get("suit_power_cost", 0.0))

	if not _training_suit_can_afford(suit_oxygen_cost, suit_power_cost):
		return {
			"success": false,
			"fault_fixed": false,
			"option_type": option_type,
			"message": "宇航服资源不足，无法执行该维修操作。",
		}
	if not _training_has_items(container_id, items):
		return {
			"success": false,
			"fault_fixed": false,
			"option_type": option_type,
			"message": "维修备件不足，无法执行该操作。",
		}
	if not _training_consume_items(container_id, items):
		return {
			"success": false,
			"fault_fixed": false,
			"option_type": option_type,
			"message": "维修备件扣除失败。",
		}

	var minutes: int = int(option.get("time_cost_minutes", 0))
	_advance_training_time(minutes, "training_%s" % ("repair_success" if is_correct else "repair_failure"))

	var suit_manager := _suit_manager()
	if suit_manager != null and suit_manager.has_method("consume_suit_resource_fixed"):
		suit_manager.call(
			"consume_suit_resource_fixed",
			suit_oxygen_cost,
			suit_power_cost,
			"training_repair_%s" % option_id
		)
	var health_manager := _health_manager()
	if health_manager != null and health_manager.has_method("consume_energy"):
		health_manager.call("consume_energy", float(option.get("energy_cost", 0.0)), "training_repair_%s" % option_id)

	return {
		"success": true,
		"fault_fixed": is_correct,
		"option_type": option_type,
		"message": String(option.get("result_message", "")),
		"new_hint": String(option.get("new_hint", "")),
	}

## Checked against the suit's *current* reserves, not the EVA-start
## MIN_EVA_OXYGEN/MIN_EVA_POWER floor -- a repair option should be refused
## the moment it would require more than what's left, even if the suit is
## still above the general "can start EVA" threshold.
func _training_suit_can_afford(oxygen_cost: float, power_cost: float) -> bool:
	var suit_manager := _suit_manager()
	if suit_manager == null:
		return false
	if not bool(suit_manager.get("is_suit_worn")):
		return false
	return float(suit_manager.get("suit_oxygen")) >= oxygen_cost and float(suit_manager.get("suit_power")) >= power_cost

func _training_has_items(container_id: String, items: Dictionary) -> bool:
	if items.is_empty():
		return true
	var inventory_manager := _inventory_manager()
	if inventory_manager == null or not inventory_manager.has_method("has_item_in_container"):
		return false
	for item_id in items.keys():
		if not bool(inventory_manager.call("has_item_in_container", container_id, String(item_id), int(items[item_id]))):
			return false
	return true

func _training_consume_items(container_id: String, items: Dictionary) -> bool:
	if items.is_empty():
		return true
	if not _training_has_items(container_id, items):
		return false
	var inventory_manager := _inventory_manager()
	if inventory_manager == null or not inventory_manager.has_method("remove_item_from_container"):
		return false
	for item_id in items.keys():
		if not bool(inventory_manager.call("remove_item_from_container", container_id, String(item_id), int(items[item_id]))):
			return false
	return true

func _advance_training_time(minutes: int, reason: String) -> void:
	if minutes <= 0:
		return
	var training_time_manager := _training_time_manager()
	if training_time_manager != null and training_time_manager.has_method("advance_training_time"):
		training_time_manager.call("advance_training_time", minutes, reason)

func get_material_status(required_items: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var storage_manager := _storage_manager()
	for item_id in required_items.keys():
		var need := int(required_items[item_id])
		var have := 0
		if storage_manager != null and storage_manager.has_method("get_item_count"):
			have = int(storage_manager.call("get_item_count", String(item_id)))
		result[String(item_id)] = {"need": need, "have": have, "enough": have >= need}
	return result

func debug_values_text() -> String:
	var lines: Array[String] = [
		"维修模块：%d 个活动故障" % get_active_faults().size(),
		"最近状态：%s" % ("-" if last_notice == "" else last_notice),
	]
	for fault in get_active_faults():
		var fault_data: Dictionary = fault
		lines.append("%s｜%s｜等级 %d｜诊断 %d 次｜失败 %d" % [
			String(fault_data.get("fault_id", "")),
			String(fault_data.get("display_name", "")),
			int(fault_data.get("severity", 1)),
			int(fault_data.get("diagnosis_count", 0)),
			int(fault_data.get("worsening", 0)),
		])
	if get_active_faults().is_empty():
		lines.append("暂无活动故障。")
	return "\n".join(lines)

func debug_add_sample_faults() -> void:
	add_fault("FA-AIR-001")
	add_fault("FA-PO-002")
	add_fault("FA-WATER-001")

func debug_seed_repair_materials() -> void:
	var storage_manager := _storage_manager()
	if storage_manager == null or not storage_manager.has_method("add_item"):
		return
	var materials := {
		"MT-ME-001": 10,
		"MT-EL-001": 10,
		"MT-SE-001": 10,
		"MT-FI-001": 10,
		"MT-IN-001": 10,
		"MT-GL-001": 6,
		"CN-IG-001": 4,
	}
	for item_id in materials.keys():
		storage_manager.call("add_item", String(item_id), int(materials[item_id]))
	_set_notice("维修测试材料已加入仓库。")

func debug_diagnose_first() -> void:
	var fault_id := _first_active_fault_id()
	if fault_id != "":
		diagnose_fault(fault_id)

func debug_attempt_first_correct() -> void:
	var fault_id := _first_active_fault_id()
	if fault_id == "":
		return
	var fault: Dictionary = FaultDatabaseScript.get_fault(fault_id)
	for option in fault.get("repair_options", []):
		if option is Dictionary and bool((option as Dictionary).get("is_correct", false)):
			attempt_repair(fault_id, String((option as Dictionary).get("option_id", "")))
			return

func debug_attempt_first_wrong() -> void:
	var fault_id := _first_active_fault_id()
	if fault_id == "":
		return
	var fault: Dictionary = FaultDatabaseScript.get_fault(fault_id)
	for option in fault.get("repair_options", []):
		if option is Dictionary and not bool((option as Dictionary).get("is_correct", false)):
			attempt_repair(fault_id, String((option as Dictionary).get("option_id", "")))
			return

func serialize() -> Dictionary:
	return {
		"active_faults": active_faults.duplicate(true),
		"repair_history": repair_history.duplicate(true),
		"last_notice": last_notice,
	}

func deserialize(data: Dictionary) -> void:
	active_faults = (data.get("active_faults", {}) as Dictionary).duplicate(true)
	repair_history = (data.get("repair_history", []) as Array).duplicate(true)
	last_notice = String(data.get("last_notice", ""))
	repair_state_changed.emit()

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

func _fault_is_active(fault_id: String) -> bool:
	if not active_faults.has(fault_id):
		return false
	return bool((active_faults[fault_id] as Dictionary).get("is_active", true))

func _runtime_array(fault_id: String, key: String) -> Array:
	var runtime: Dictionary = active_faults.get(fault_id, {}) as Dictionary
	return (runtime.get(key, []) as Array).duplicate()

func _find_option(fault: Dictionary, option_id: String) -> Dictionary:
	for option in fault.get("repair_options", []):
		if not (option is Dictionary):
			continue
		var option_data: Dictionary = option
		if String(option_data.get("option_id", "")) == option_id:
			return option_data
	return {}

func _has_items(items: Dictionary) -> bool:
	if items.is_empty():
		return true
	var storage_manager := _storage_manager()
	if storage_manager == null or not storage_manager.has_method("get_item_count"):
		return false
	for item_id in items.keys():
		if int(storage_manager.call("get_item_count", String(item_id))) < int(items[item_id]):
			return false
	return true

func _consume_items(items: Dictionary) -> bool:
	if items.is_empty():
		return true
	if not _has_items(items):
		return false
	var storage_manager := _storage_manager()
	if storage_manager == null or not storage_manager.has_method("remove_item"):
		return false
	for item_id in items.keys():
		if not bool(storage_manager.call("remove_item", String(item_id), int(items[item_id]))):
			return false
	return true

func _advance_time(minutes: int, reason: String) -> void:
	var time_manager := _time_manager()
	if minutes > 0 and time_manager != null and time_manager.has_method("advance_time"):
		time_manager.call("advance_time", minutes, reason)

func _apply_effects(effects: Dictionary) -> void:
	if effects.is_empty():
		return
	if effects.has("base") and effects["base"] is Dictionary:
		_apply_adjust_stat(_base_status_manager(), effects["base"] as Dictionary)
	if effects.has("air") and effects["air"] is Dictionary:
		_apply_adjust_stat(_air_system_manager(), effects["air"] as Dictionary)
	if effects.has("water") and effects["water"] is Dictionary:
		_apply_water_effects(effects["water"] as Dictionary)
	if effects.has("power") and effects["power"] is Dictionary:
		_apply_power_effects(effects["power"] as Dictionary)

func _apply_adjust_stat(manager: Node, effects: Dictionary) -> void:
	if manager == null or not manager.has_method("adjust_stat"):
		return
	for stat_name in effects.keys():
		manager.call("adjust_stat", String(stat_name), float(effects[stat_name]))

func _apply_water_effects(effects: Dictionary) -> void:
	var manager := _water_system_manager()
	if manager == null:
		return
	if effects.has("water_delta") and manager.has_method("debug_adjust_water"):
		manager.call("debug_adjust_water", float(effects["water_delta"]))

func _apply_power_effects(effects: Dictionary) -> void:
	var manager := _power_system_manager()
	if manager == null:
		return
	if effects.has("energy_delta") and manager.has_method("debug_adjust_energy"):
		manager.call("debug_adjust_energy", float(effects["energy_delta"]))

func _record_history(event_id: String, fault_id: String, option_id: String) -> void:
	repair_history.append({
		"event_id": event_id,
		"fault_id": fault_id,
		"option_id": option_id,
		"notice": last_notice,
	})
	if repair_history.size() > 60:
		repair_history.pop_front()

func _set_notice(text: String) -> void:
	last_notice = text
	repair_notice.emit(text)

func _first_active_fault_id() -> String:
	for fault_id in active_faults.keys():
		if bool((active_faults[fault_id] as Dictionary).get("is_active", true)):
			return String(fault_id)
	return ""

func _storage_manager() -> Node:
	return get_tree().root.get_node_or_null("StorageManager")

func _time_manager() -> Node:
	return get_tree().root.get_node_or_null("TimeManager")

func _base_status_manager() -> Node:
	return get_tree().root.get_node_or_null("BaseStatusManager")

func _air_system_manager() -> Node:
	return get_tree().root.get_node_or_null("AirSystemManager")

func _water_system_manager() -> Node:
	return get_tree().root.get_node_or_null("WaterSystemManager")

func _power_system_manager() -> Node:
	return get_tree().root.get_node_or_null("PowerSystemManager")

func _inventory_manager() -> Node:
	return get_tree().root.get_node_or_null("InventoryManager")

func _training_time_manager() -> Node:
	return get_tree().root.get_node_or_null("TrainingTimeManager")

func _suit_manager() -> Node:
	return get_tree().root.get_node_or_null("SuitManager")

func _health_manager() -> Node:
	return get_tree().root.get_node_or_null("HealthManager")
