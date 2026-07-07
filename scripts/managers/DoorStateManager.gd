extends Node
class_name GuanghanDoorStateManager

signal doors_changed

const SAVE_PATH := "user://saves/door_state.json"
const DoorTypeDatabaseScript := preload("res://scripts/data/DoorTypeDatabase.gd")
const DoorAssetDatabaseScript := preload("res://scripts/data/DoorAssetDatabase.gd")

var doors: Dictionary = {}
var last_notice: String = ""

func _ready() -> void:
	load_state()

func reset_to_arrival() -> void:
	doors.clear()
	last_notice = ""
	register_door({
		"door_id": "door_ship_to_cargo",
		"door_name": "飞船-对接物资舱舱门",
		"door_type_id": "docking_hatch",
		"door_asset_id": "DOCK-D01",
		"area_a": "ship_survival_module",
		"area_b": "docking_cargo_bay",
		"spawn_from_a_to_b": "spawn_cargo_from_ship",
		"spawn_from_b_to_a": "spawn_ship_from_cargo",
		"is_open": false,
		"is_locked": false,
		"is_powered": true,
		"is_sealed": true,
		"is_docking_connected": true,
	})
	register_door({
		"door_id": "door_cargo_to_control",
		"door_name": "对接物资舱-中控室电梯门",
		"door_type_id": "cargo_elevator_door",
		"door_asset_id": "ELEV-E01",
		"area_a": "docking_cargo_bay",
		"area_b": "control_room",
		"spawn_from_a_to_b": "spawn_control_from_cargo",
		"spawn_from_b_to_a": "spawn_cargo_from_control",
		"is_open": false,
		"is_locked": false,
		"is_powered": true,
		"is_sealed": true,
		"is_docking_connected": true,
	})
	register_door({
		"door_id": "door_control_to_power",
		"door_name": "中控室-配电房舱门",
		"door_type_id": "indoor_sliding_door",
		"door_asset_id": "DOOR-A01",
		"area_a": "control_room",
		"area_b": "power_room",
		"spawn_from_a_to_b": "spawn_power_from_control",
		"spawn_from_b_to_a": "spawn_control_from_power",
		"is_open": false,
		"is_locked": false,
		"is_powered": true,
		"is_sealed": true,
		"is_docking_connected": true,
	})
	register_door({
		"door_id": "door_control_to_air",
		"door_name": "中控室-空气系统室舱门",
		"door_type_id": "airtight_hatch",
		"door_asset_id": "HATCH-B01",
		"area_a": "control_room",
		"area_b": "air_system_room",
		"spawn_from_a_to_b": "spawn_air_from_control",
		"spawn_from_b_to_a": "spawn_control_from_air",
		"is_open": false,
		"is_locked": false,
		"is_powered": true,
		"is_sealed": true,
		"is_docking_connected": true,
	})
	register_door({
		"door_id": "door_control_to_water",
		"door_name": "中控室-水处理室舱门",
		"door_type_id": "airtight_hatch",
		"door_asset_id": "HATCH-B01",
		"area_a": "control_room",
		"area_b": "water_processing_room",
		"spawn_from_a_to_b": "spawn_water_from_control",
		"spawn_from_b_to_a": "spawn_control_from_water",
		"is_open": false,
		"is_locked": false,
		"is_powered": true,
		"is_sealed": true,
		"is_docking_connected": true,
	})
	register_door({
		"door_id": "door_control_to_greenhouse",
		"door_name": "中控室-旧温室舱门",
		"door_type_id": "greenhouse_hatch",
		"door_asset_id": "HATCH-B02",
		"area_a": "control_room",
		"area_b": "old_greenhouse",
		"spawn_from_a_to_b": "spawn_greenhouse_from_control",
		"spawn_from_b_to_a": "spawn_control_from_greenhouse",
		"is_open": false,
		"is_locked": false,
		"is_powered": true,
		"is_sealed": false,
		"is_docking_connected": true,
	})
	register_door({
		"door_id": "door_control_to_rest",
		"door_name": "中控室-旧基地休息室舱门",
		"door_type_id": "indoor_sliding_door",
		"door_asset_id": "DOOR-A01",
		"area_a": "control_room",
		"area_b": "old_base_rest_room",
		"spawn_from_a_to_b": "spawn_rest_from_control",
		"spawn_from_b_to_a": "spawn_control_from_rest",
		"is_open": false,
		"is_locked": false,
		"is_powered": true,
		"is_sealed": true,
		"is_docking_connected": true,
	})
	register_door({
		"door_id": "door_suitroom_to_airlock",
		"door_name": "宇航服整备室-气闸内门",
		"door_type_id": "airlock_inner_door",
		"door_asset_id": "AIRLOCK-C01",
		"area_a": "spacesuit_preparation_room",
		"area_b": "airlock_room",
		"spawn_from_a_to_b": "spawn_airlock_from_suitroom",
		"spawn_from_b_to_a": "spawn_suitroom_from_airlock",
		"is_open": false,
		"is_locked": false,
		"is_powered": true,
		"is_sealed": true,
		"is_docking_connected": true,
		"airlock_group_id": "main_airlock",
		"paired_door_id": "door_airlock_outer",
	})
	register_door({
		"door_id": "door_airlock_outer",
		"door_name": "气闸外门",
		"door_type_id": "airlock_outer_door",
		"door_asset_id": "AIRLOCK-C02",
		"area_a": "airlock_room",
		"area_b": "lunar_surface_near_base",
		"spawn_from_a_to_b": "spawn_lunar_from_airlock",
		"spawn_from_b_to_a": "spawn_airlock_from_lunar",
		"is_open": false,
		"is_locked": true,
		"is_powered": true,
		"is_sealed": true,
		"is_docking_connected": true,
		"airlock_group_id": "main_airlock",
		"paired_door_id": "door_suitroom_to_airlock",
	})
	save_state()
	doors_changed.emit()

func register_door(door_data: Dictionary) -> void:
	var door_id := String(door_data.get("door_id", ""))
	if door_id.is_empty():
		last_notice = "舱门注册失败：缺少 door_id。"
		return
	var door_type_id := String(door_data.get("door_type_id", DoorTypeDatabaseScript.DEFAULT_TYPE_ID))
	if not DoorTypeDatabaseScript.has_type(door_type_id):
		door_type_id = DoorTypeDatabaseScript.DEFAULT_TYPE_ID
	var door_asset_id := String(door_data.get("door_asset_id", ""))
	if door_asset_id.is_empty():
		door_asset_id = DoorTypeDatabaseScript.get_default_asset_id(door_type_id)
	var normalized := {
		"door_id": door_id,
		"door_name": String(door_data.get("door_name", door_id)),
		"door_type_id": door_type_id,
		"door_asset_id": door_asset_id,
		"area_a": String(door_data.get("area_a", "")),
		"area_b": String(door_data.get("area_b", "")),
		"spawn_from_a_to_b": String(door_data.get("spawn_from_a_to_b", "")),
		"spawn_from_b_to_a": String(door_data.get("spawn_from_b_to_a", "")),
		"is_open": bool(door_data.get("is_open", false)),
		"is_locked": bool(door_data.get("is_locked", false)),
		"is_powered": bool(door_data.get("is_powered", true)),
		"is_sealed": bool(door_data.get("is_sealed", DoorTypeDatabaseScript.has_seal(door_type_id))),
		"is_docking_connected": bool(door_data.get("is_docking_connected", true)),
		"airlock_group_id": String(door_data.get("airlock_group_id", "")),
		"paired_door_id": String(door_data.get("paired_door_id", "")),
	}
	doors[door_id] = normalized
	doors_changed.emit()

func has_door(door_id: String) -> bool:
	return doors.has(door_id)

func get_door(door_id: String) -> Dictionary:
	if not doors.has(door_id):
		return {}
	return (doors[door_id] as Dictionary).duplicate(true)

func get_all_doors() -> Dictionary:
	return doors.duplicate(true)

func get_doors_for_area(area_id: String) -> Array:
	var result: Array = []
	for door_id in doors.keys():
		var door: Dictionary = doors[door_id]
		if String(door.get("area_a", "")) == area_id or String(door.get("area_b", "")) == area_id:
			result.append(door.duplicate(true))
	return result

func set_door_open(door_id: String, value: bool) -> bool:
	if not _has_mutable_door(door_id):
		return false
	if value and is_paired_airlock_door_open(door_id):
		last_notice = "气闸互锁启动：请先关闭另一侧舱门。"
		return false
	doors[door_id]["is_open"] = value
	doors_changed.emit()
	return true

func set_door_locked(door_id: String, value: bool) -> bool:
	if not _has_mutable_door(door_id):
		return false
	doors[door_id]["is_locked"] = value
	doors_changed.emit()
	return true

func set_door_powered(door_id: String, value: bool) -> bool:
	if not _has_mutable_door(door_id):
		return false
	doors[door_id]["is_powered"] = value
	doors_changed.emit()
	return true

func set_door_sealed(door_id: String, value: bool) -> bool:
	if not _has_mutable_door(door_id):
		return false
	doors[door_id]["is_sealed"] = value
	doors_changed.emit()
	return true

func set_docking_connected(door_id: String, value: bool) -> bool:
	if not _has_mutable_door(door_id):
		return false
	doors[door_id]["is_docking_connected"] = value
	doors_changed.emit()
	return true

func is_door_open(door_id: String) -> bool:
	return bool(get_door(door_id).get("is_open", false))

func is_door_locked(door_id: String) -> bool:
	return bool(get_door(door_id).get("is_locked", false))

func is_door_powered(door_id: String) -> bool:
	return bool(get_door(door_id).get("is_powered", false))

func is_door_sealed(door_id: String) -> bool:
	return bool(get_door(door_id).get("is_sealed", false))

func is_docking_connected(door_id: String) -> bool:
	return bool(get_door(door_id).get("is_docking_connected", false))

func get_door_type_id(door_id: String) -> String:
	return String(get_door(door_id).get("door_type_id", ""))

func get_door_asset_id(door_id: String) -> String:
	var door: Dictionary = get_door(door_id)
	if door.is_empty():
		return ""
	var asset_id := String(door.get("door_asset_id", ""))
	if asset_id.is_empty():
		asset_id = DoorTypeDatabaseScript.get_default_asset_id(String(door.get("door_type_id", "")))
	return asset_id

func get_door_display_name(door_id: String) -> String:
	return String(get_door(door_id).get("door_name", door_id))

func can_pass_door(door_id: String, from_area_id: String) -> Dictionary:
	var result := _pass_result(false, "", "", "")
	if not doors.has(door_id):
		result["message"] = "舱门不存在。"
		return result
	var door: Dictionary = doors[door_id]
	var area_a := String(door.get("area_a", ""))
	var area_b := String(door.get("area_b", ""))
	var target_area_id := ""
	var target_spawn_id := ""
	if from_area_id == area_a:
		target_area_id = area_b
		target_spawn_id = String(door.get("spawn_from_a_to_b", ""))
	elif from_area_id == area_b:
		target_area_id = area_a
		target_spawn_id = String(door.get("spawn_from_b_to_a", ""))
	else:
		result["message"] = "当前位置不连接该舱门。"
		return result
	if bool(door.get("is_locked", false)):
		result["message"] = "舱门已锁定。"
		return result
	var door_type_id := String(door.get("door_type_id", ""))
	if DoorTypeDatabaseScript.requires_power(door_type_id) and not bool(door.get("is_powered", true)):
		result["message"] = "舱门未通电。"
		return result
	if DoorTypeDatabaseScript.requires_docking_connected(door_type_id) and not bool(door.get("is_docking_connected", true)):
		result["message"] = "对接状态未确认。"
		return result
	if DoorTypeDatabaseScript.requires_suit_to_pass(door_type_id) and not _is_suit_worn():
		result["message"] = "外部为真空环境，请先穿戴宇航服。"
		return result
	if DoorTypeDatabaseScript.is_airlock_door(door_type_id) and is_paired_airlock_door_open(door_id):
		result["message"] = "气闸互锁启动：请先关闭另一侧舱门。"
		return result
	return _pass_result(true, "", target_area_id, target_spawn_id)

func try_pass_door(door_id: String, from_area_id: String) -> Dictionary:
	var result := can_pass_door(door_id, from_area_id)
	if not bool(result.get("success", false)):
		last_notice = String(result.get("message", ""))
		return result
	if not set_door_open(door_id, true):
		return _pass_result(false, last_notice, "", "")
	return result

func close_door_after_pass(door_id: String) -> void:
	set_door_open(door_id, false)

func is_paired_airlock_door_open(door_id: String) -> bool:
	if not doors.has(door_id):
		return false
	var door: Dictionary = doors[door_id]
	var paired_door_id := String(door.get("paired_door_id", ""))
	if paired_door_id.is_empty() or not doors.has(paired_door_id):
		return false
	return bool(doors[paired_door_id].get("is_open", false))

func serialize() -> Dictionary:
	return {
		"doors": doors.duplicate(true),
		"last_notice": last_notice,
	}

func deserialize(data: Dictionary) -> void:
	doors.clear()
	var saved_doors: Dictionary = data.get("doors", {})
	for door_id in saved_doors.keys():
		var door: Dictionary = saved_doors[door_id]
		register_door(door)
	last_notice = String(data.get("last_notice", ""))
	doors_changed.emit()

func save_state() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		last_notice = "舱门状态保存失败。"
		return
	file.store_string(JSON.stringify(serialize(), "\t"))

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

func debug_values_text() -> String:
	var lines: Array[String] = ["舱门状态："]
	for door_id in doors.keys():
		var door: Dictionary = doors[door_id]
		var states: Array[String] = []
		states.append("open" if bool(door.get("is_open", false)) else "closed")
		states.append("locked" if bool(door.get("is_locked", false)) else "unlocked")
		states.append("powered" if bool(door.get("is_powered", false)) else "unpowered")
		states.append("sealed" if bool(door.get("is_sealed", false)) else "seal_fault")
		if DoorTypeDatabaseScript.requires_docking_connected(String(door.get("door_type_id", ""))):
			states.append("docking_connected" if bool(door.get("is_docking_connected", false)) else "docking_disconnected")
		lines.append("- %s [%s / %s] %s" % [
			String(door.get("door_name", door_id)),
			String(door.get("door_type_id", "")),
			get_door_asset_id(String(door_id)),
			_join_strings(states, " "),
		])
	return _join_strings(lines, "\n")

func _has_mutable_door(door_id: String) -> bool:
	if doors.has(door_id):
		return true
	last_notice = "舱门不存在。"
	return false

func _pass_result(success: bool, message: String, target_area_id: String, target_spawn_id: String) -> Dictionary:
	return {
		"success": success,
		"message": message,
		"target_area_id": target_area_id,
		"target_spawn_id": target_spawn_id,
	}

func _is_suit_worn() -> bool:
	var suit_manager := get_node_or_null("/root/SuitManager")
	if suit_manager == null:
		return false
	return bool(suit_manager.get("is_suit_worn"))

func _join_strings(values: Array[String], separator: String) -> String:
	var result := ""
	for index in values.size():
		if index > 0:
			result += separator
		result += values[index]
	return result
