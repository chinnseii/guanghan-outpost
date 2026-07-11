extends RefCounted
class_name FullSaveOrchestrator

const SCHEMA_VERSION := 1
const SAVE_KIND := "full_save"
const FULL_SAVE_PATH := "user://saves/full_save.json"
const TEMP_SUFFIX := ".tmp"
const BACKUP_SUFFIX := ".bak"
const LEGACY_SPRINT06_SAVE_PATH := "user://saves/sprint06_progress.json"

const RESULT_OK := "ok"
const RESULT_MISSING := "missing"
const RESULT_INVALID_JSON := "invalid_json"
const RESULT_UNSUPPORTED_SCHEMA := "unsupported_schema"
const RESULT_INVALID_SCHEMA := "invalid_schema"
const RESULT_INVALID_SCENE := "invalid_scene"
const RESULT_WRITE_FAILED := "write_failed"
const RESULT_RESTORE_FAILED := "restore_failed"

const SCENE_MANAGER_KEYS := {
	"TimeState": true,
	"HealthState": true,
	"BaseStatusState": true,
	"AirSystemState": true,
	"PowerSystemState": true,
	"WaterSystemState": true,
	"InventoryState": true,
	"BackpackState": true,
	"StorageState": true,
	"PlantGrowthState": true,
	"SuitState": true,
	"PlayerStateManagerState": true,
	"SupplyState": true,
	"RepairState": true,
}

const CONTINUE_SCENE_FALLBACK := "res://scenes/base/OldBaseInteriorScene.tscn"
const DAY01_END := "res://scenes/base/Day01EndScene.tscn"
const DAY02_START := "res://scenes/base/Day02StartScene.tscn"
const DAY02_END := "res://scenes/base/Day02EndScene.tscn"
const WEEK_ROUTINE_START := "res://scenes/base/WeekRoutineStartScene.tscn"
const WEEK_ROUTINE_END := "res://scenes/base/WeekRoutineEndScene.tscn"
const OLD_BASE_INTERIOR := "res://scenes/base/OldBaseInteriorScene.tscn"
const OLD_GREENHOUSE := "res://scenes/base/OldGreenhouseScene.tscn"
const PHASE02_PLACEHOLDER := "res://scenes/base/Phase02PlaceholderScene.tscn"

static func provider_specs() -> Array[Dictionary]:
	return [
		{"id": "player_state", "node": "PlayerStateManager", "required": true, "order": 10, "finalize": true},
		{"id": "time", "node": "TimeManager", "required": true, "order": 20, "finalize": false},
		{"id": "health", "node": "HealthManager", "required": true, "order": 30, "finalize": false},
		{"id": "base_status", "node": "BaseStatusManager", "required": true, "order": 40, "finalize": true},
		{"id": "air", "node": "AirSystemManager", "required": true, "order": 50, "finalize": false},
		{"id": "power", "node": "PowerSystemManager", "required": true, "order": 60, "finalize": true},
		{"id": "water", "node": "WaterSystemManager", "required": true, "order": 70, "finalize": false},
		{"id": "inventory", "node": "InventoryManager", "required": true, "order": 80, "finalize": false},
		{"id": "backpack", "node": "BackpackManager", "required": true, "order": 90, "finalize": false},
		{"id": "storage", "node": "StorageManager", "required": true, "order": 100, "finalize": false},
		{"id": "plant_growth", "node": "PlantGrowthManager", "required": false, "order": 110, "finalize": false},
		{"id": "suit", "node": "SuitManager", "required": true, "order": 120, "finalize": true},
		{"id": "supply", "node": "SupplyManager", "required": false, "order": 130, "finalize": false},
		{"id": "repair", "node": "RepairManager", "required": false, "order": 140, "finalize": false},
	]

static func save_full_save(scene_state: Dictionary = {}, player_context: Dictionary = {}, target_scene: String = "", save_path: String = FULL_SAVE_PATH) -> Dictionary:
	var bundle := build_bundle(scene_state, player_context, target_scene)
	var validation := validate_bundle(bundle, false)
	if not bool(validation.get("success", false)):
		return validation
	return write_bundle(bundle, save_path)

static func build_bundle(scene_state: Dictionary = {}, player_context: Dictionary = {}, target_scene: String = "") -> Dictionary:
	var now := Time.get_datetime_string_from_system(false, true)
	return {
		"schema_version": SCHEMA_VERSION,
		"save_kind": SAVE_KIND,
		"saved_at": now,
		"created_at": now,
		"game_version": ProjectSettings.get_setting("application/config/version", "dev"),
		"target_scene": target_scene,
		"metadata": {
			"orchestrator": "FullSaveOrchestrator",
			"authority": "full_save_bundle",
		},
		"canonical_state": collect_canonical_state(),
		"scene_state": _clean_scene_state(scene_state),
		"player_context": player_context.duplicate(true),
	}

static func collect_canonical_state() -> Dictionary:
	var result: Dictionary = {}
	for spec in provider_specs():
		var manager := _manager(String(spec.get("node", "")))
		if manager != null and manager.has_method("serialize"):
			result[String(spec.get("id", ""))] = manager.call("serialize")
	return result

static func restore_full_save(scene_node: Node = null, save_path: String = FULL_SAVE_PATH) -> Dictionary:
	var read_result := read_bundle(save_path)
	if not bool(read_result.get("success", false)):
		return read_result
	var bundle: Dictionary = read_result.get("bundle", {}) as Dictionary
	var validation := validate_bundle(bundle, true)
	if not bool(validation.get("success", false)):
		return validation
	var canonical: Dictionary = bundle.get("canonical_state", {}) as Dictionary
	for spec in provider_specs():
		var provider_id := String(spec.get("id", ""))
		if not canonical.has(provider_id):
			continue
		var manager := _manager(String(spec.get("node", "")))
		if manager == null or not manager.has_method("deserialize"):
			if bool(spec.get("required", false)):
				return _result(false, RESULT_RESTORE_FAILED, "Missing provider node or deserialize: %s" % provider_id)
			continue
		manager.call("deserialize", canonical.get(provider_id, {}))
	finalize_restore()
	var result := _result(true, RESULT_OK, "")
	result["bundle"] = bundle
	result["scene_state"] = (bundle.get("scene_state", {}) as Dictionary).duplicate(true)
	result["player_context"] = (bundle.get("player_context", {}) as Dictionary).duplicate(true)
	result["target_scene"] = String(bundle.get("target_scene", ""))
	result["legacy_source"] = bool(read_result.get("legacy_source", false))
	if scene_node != null and scene_node.has_method("_on_full_save_restore_complete"):
		scene_node.call("_on_full_save_restore_complete", result)
	return result

static func finalize_restore() -> void:
	var power_manager := _manager("PowerSystemManager")
	var base_status_manager := _manager("BaseStatusManager")
	if power_manager != null and base_status_manager != null \
			and power_manager.has_method("get_power_percent") and base_status_manager.has_method("set_power_percent"):
		base_status_manager.call("set_power_percent", power_manager.call("get_power_percent"))
	var player_state_manager := _manager("PlayerStateManager")
	if player_state_manager != null and player_state_manager.has_method("sync_suit_state_from_suit_manager"):
		player_state_manager.call("sync_suit_state_from_suit_manager")

static func read_bundle(save_path: String = FULL_SAVE_PATH) -> Dictionary:
	if FileAccess.file_exists(save_path):
		return _read_bundle_from_path(save_path, save_path != FULL_SAVE_PATH)
	if save_path == FULL_SAVE_PATH and FileAccess.file_exists(LEGACY_SPRINT06_SAVE_PATH):
		return _read_bundle_from_path(LEGACY_SPRINT06_SAVE_PATH, true)
	return _result(false, RESULT_MISSING, "Full Save file is missing.")

static func read_scene_state(save_path: String = FULL_SAVE_PATH) -> Dictionary:
	var read_result := read_bundle(save_path)
	if not bool(read_result.get("success", false)):
		return read_result
	var bundle: Dictionary = read_result.get("bundle", {}) as Dictionary
	read_result["scene_state"] = (bundle.get("scene_state", {}) as Dictionary).duplicate(true)
	read_result["target_scene"] = String(bundle.get("target_scene", ""))
	return read_result

static func has_full_save(save_path: String = FULL_SAVE_PATH) -> bool:
	return bool(read_bundle(save_path).get("success", false))

static func continue_scene_path(save_path: String = FULL_SAVE_PATH) -> String:
	var state_result := read_scene_state(save_path)
	if not bool(state_result.get("success", false)):
		return ""
	var target_scene := String(state_result.get("target_scene", ""))
	if not target_scene.is_empty() and ResourceLoader.exists(target_scene):
		return target_scene
	return infer_base_continue_scene_path(state_result.get("scene_state", {}) as Dictionary)

static func infer_base_continue_scene_path(data: Dictionary) -> String:
	if bool(data.get("WeekOneCompleted", false)):
		return PHASE02_PLACEHOLDER
	var current_day := int(data.get("CurrentDay", data.get("DayNumber", 2)))
	if current_day >= 3 and current_day <= 7:
		if bool(data.get("DailyReportSent", false)) or bool(data.get("DayCompleted", false)):
			return WEEK_ROUTINE_END
		if bool(data.get("DayStarted", false)):
			return OLD_BASE_INTERIOR
		return WEEK_ROUTINE_START
	if bool(data.get("Day02Completed", false)) or bool(data.get("Day02ReportSent", false)):
		return DAY02_END
	if bool(data.get("Day02Started", false)):
		return OLD_BASE_INTERIOR
	if bool(data.get("Day01Completed", false)):
		return DAY02_START
	if bool(data.get("LastPlantStable", false)):
		return DAY01_END
	if bool(data.get("GreenhouseUnlocked", false)) or bool(data.get("LastPlantDiscovered", false)) or bool(data.get("LastPlantDiagnosed", false)):
		return OLD_GREENHOUSE
	if bool(data.get("BaseEntered", false)):
		return OLD_BASE_INTERIOR
	return CONTINUE_SCENE_FALLBACK if not data.is_empty() else ""

static func validate_bundle(bundle: Dictionary, require_scene_path: bool = false) -> Dictionary:
	if not bundle.has("schema_version"):
		return _result(false, RESULT_INVALID_SCHEMA, "Missing schema_version.")
	var schema_value: Variant = bundle.get("schema_version")
	if not _is_integer_schema_value(schema_value):
		return _result(false, RESULT_INVALID_SCHEMA, "schema_version must be an integer.")
	var version := int(schema_value)
	bundle["schema_version"] = version
	if version > SCHEMA_VERSION:
		return _result(false, RESULT_UNSUPPORTED_SCHEMA, "Unsupported future schema_version: %d." % version)
	if version != SCHEMA_VERSION:
		return _result(false, RESULT_INVALID_SCHEMA, "Unsupported schema_version: %d." % version)
	if String(bundle.get("save_kind", "")) != SAVE_KIND:
		return _result(false, RESULT_INVALID_SCHEMA, "save_kind must be full_save.")
	if not (bundle.get("canonical_state", {}) is Dictionary):
		return _result(false, RESULT_INVALID_SCHEMA, "canonical_state must be a Dictionary.")
	if not (bundle.get("scene_state", {}) is Dictionary):
		return _result(false, RESULT_INVALID_SCHEMA, "scene_state must be a Dictionary.")
	if not (bundle.get("player_context", {}) is Dictionary):
		return _result(false, RESULT_INVALID_SCHEMA, "player_context must be a Dictionary.")
	var canonical: Dictionary = bundle.get("canonical_state", {}) as Dictionary
	for spec in provider_specs():
		if not bool(spec.get("required", false)):
			continue
		var provider_id := String(spec.get("id", ""))
		if not canonical.has(provider_id):
			return _result(false, RESULT_INVALID_SCHEMA, "Missing required canonical provider: %s." % provider_id)
		if not (canonical.get(provider_id, {}) is Dictionary):
			return _result(false, RESULT_INVALID_SCHEMA, "Provider state must be a Dictionary: %s." % provider_id)
	if require_scene_path:
		var target_scene := String(bundle.get("target_scene", ""))
		if not target_scene.is_empty() and not ResourceLoader.exists(target_scene):
			return _result(false, RESULT_INVALID_SCENE, "Invalid target_scene: %s." % target_scene)
	return _result(true, RESULT_OK, "")

static func write_bundle(bundle: Dictionary, save_path: String = FULL_SAVE_PATH) -> Dictionary:
	var dir_path := save_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	var temp_path := save_path + TEMP_SUFFIX
	var backup_path := save_path + BACKUP_SUFFIX
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return _result(false, RESULT_WRITE_FAILED, "Could not open temporary Full Save file.")
	file.store_string(JSON.stringify(bundle, "\t"))
	file = null
	var temp_absolute := ProjectSettings.globalize_path(temp_path)
	var save_absolute := ProjectSettings.globalize_path(save_path)
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_absolute)
	if FileAccess.file_exists(save_path):
		var backup_error := DirAccess.rename_absolute(save_absolute, backup_absolute)
		if backup_error != OK:
			DirAccess.remove_absolute(temp_absolute)
			return _result(false, RESULT_WRITE_FAILED, "Could not preserve existing Full Save before replace.")
	var rename_error := DirAccess.rename_absolute(temp_absolute, save_absolute)
	if rename_error != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_absolute, save_absolute)
		DirAccess.remove_absolute(temp_absolute)
		return _result(false, RESULT_WRITE_FAILED, "Could not promote temporary Full Save.")
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_absolute)
	var result := _result(true, RESULT_OK, "")
	result["path"] = save_path
	return result

static func _read_bundle_from_path(path: String, allow_legacy: bool) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _result(false, RESULT_MISSING, "Could not open Full Save file.")
	var text := file.get_as_text()
	if text.strip_edges().is_empty():
		return _result(false, RESULT_INVALID_JSON, "Full Save file is empty.")
	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		return _result(false, RESULT_INVALID_JSON, "Full Save file is not valid JSON object.")
	var parsed: Variant = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return _result(false, RESULT_INVALID_JSON, "Full Save file is not valid JSON object.")
	var data: Dictionary = parsed as Dictionary
	if not data.has("schema_version"):
		if allow_legacy or _looks_like_legacy_sprint06(data):
			return _legacy_sprint06_to_v1(data, path)
		return _result(false, RESULT_INVALID_SCHEMA, "Unversioned file is not recognized as legacy sprint06 bundle.")
	var validation := validate_bundle(data, false)
	if not bool(validation.get("success", false)):
		return validation
	validation["bundle"] = data
	validation["legacy_source"] = false
	validation["path"] = path
	return validation

static func _legacy_sprint06_to_v1(data: Dictionary, path: String) -> Dictionary:
	if not _looks_like_legacy_sprint06(data):
		return _result(false, RESULT_INVALID_SCHEMA, "Legacy sprint06 structure is not close enough for best-effort read.")
	var scene_state := _clean_scene_state(data)
	var canonical := collect_canonical_state()
	_put_legacy_provider(canonical, "time", data, "TimeState")
	_put_legacy_provider(canonical, "health", data, "HealthState")
	_put_legacy_provider(canonical, "base_status", data, "BaseStatusState")
	_put_legacy_provider(canonical, "air", data, "AirSystemState")
	_put_legacy_provider(canonical, "power", data, "PowerSystemState")
	_put_legacy_provider(canonical, "water", data, "WaterSystemState")
	_put_legacy_provider(canonical, "inventory", data, "InventoryState")
	_put_legacy_provider(canonical, "backpack", data, "BackpackState")
	_put_legacy_provider(canonical, "storage", data, "StorageState")
	_put_legacy_provider(canonical, "plant_growth", data, "PlantGrowthState")
	_put_legacy_provider(canonical, "suit", data, "SuitState")
	_put_legacy_provider(canonical, "player_state", data, "PlayerStateManagerState")
	var target_scene := infer_base_continue_scene_path(scene_state)
	var bundle := {
		"schema_version": SCHEMA_VERSION,
		"save_kind": SAVE_KIND,
		"saved_at": "",
		"created_at": "",
		"game_version": ProjectSettings.get_setting("application/config/version", "dev"),
		"target_scene": target_scene,
		"metadata": {
			"orchestrator": "FullSaveOrchestrator",
			"authority": "full_save_bundle",
			"legacy_source_path": path,
			"legacy_format": "sprint06_unversioned",
		},
		"canonical_state": canonical,
		"scene_state": scene_state,
		"player_context": {},
	}
	var validation := validate_bundle(bundle, false)
	if not bool(validation.get("success", false)):
		return validation
	validation["bundle"] = bundle
	validation["legacy_source"] = true
	validation["path"] = path
	return validation

static func _put_legacy_provider(canonical: Dictionary, provider_id: String, legacy: Dictionary, legacy_key: String) -> void:
	if legacy.get(legacy_key, {}) is Dictionary:
		canonical[provider_id] = (legacy.get(legacy_key, {}) as Dictionary).duplicate(true)

static func _looks_like_legacy_sprint06(data: Dictionary) -> bool:
	if data.has("schema_version"):
		return false
	return data.has("BaseEntered") or data.has("Day01Completed") or data.has("TimeState") or data.has("PowerSystemState")

static func _clean_scene_state(scene_state: Dictionary) -> Dictionary:
	var cleaned := {}
	for key in scene_state.keys():
		var key_string := String(key)
		if SCENE_MANAGER_KEYS.has(key_string):
			continue
		cleaned[key_string] = scene_state[key]
	return cleaned

static func _is_integer_schema_value(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) == TYPE_FLOAT:
		return abs(float(value) - float(int(value))) < 0.000001
	return false

static func _manager(node_name: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)

static func _result(success: bool, code: String, message: String) -> Dictionary:
	return {
		"success": success,
		"code": code,
		"message": message,
	}
