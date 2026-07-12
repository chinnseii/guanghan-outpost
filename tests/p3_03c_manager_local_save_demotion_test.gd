extends SceneTree

const FullSaveOrchestratorScript := preload("res://scripts/systems/full_save_orchestrator.gd")
const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")

const TEST_SAVE_PATH := "user://saves/p3_03c_test_full_save.json"
const TEST_LOCAL_SAVE_PATH := "user://saves/time_state.json"

const DOWNGRADED_MANAGER_SOURCES := [
	"res://scripts/managers/TimeManager.gd",
	"res://scripts/managers/HealthManager.gd",
	"res://scripts/managers/BaseStatusManager.gd",
	"res://scripts/managers/PowerSystemManager.gd",
	"res://scripts/managers/WaterSystemManager.gd",
	"res://scripts/managers/AirSystemManager.gd",
	"res://scripts/managers/InventoryManager.gd",
	"res://scripts/managers/BackpackManager.gd",
	"res://scripts/managers/StorageManager.gd",
	"res://scripts/managers/SuitManager.gd",
	"res://scripts/managers/SupplyManager.gd",
	"res://scripts/managers/RepairManager.gd",
	"res://scripts/systems/PlantGrowthManager.gd",
]

const DOWNGRADED_MANAGER_NODES := [
	"TimeManager",
	"HealthManager",
	"BaseStatusManager",
	"PowerSystemManager",
	"WaterSystemManager",
	"AirSystemManager",
	"InventoryManager",
	"BackpackManager",
	"StorageManager",
	"SuitManager",
	"SupplyManager",
	"RepairManager",
	"PlantGrowthManager",
]

var checks := 0
var failed := 0
var file_backups: Dictionary = {}

func _init() -> void:
	await process_frame
	_cleanup()
	FullSaveOrchestratorScript.reset_formal_restore_guard_for_tests()
	await _run()
	_cleanup()
	print("[P3-03c] checks=%d passed=%d failed=%d" % [checks, checks - failed, failed])
	if failed > 0:
		quit(1)
	else:
		print("[P3-03c] ALL PASS")
		quit(0)

func _run() -> void:
	_check_static_boundaries()
	_check_no_full_save_fallback_guard()
	await _check_full_save_wins_and_late_loads_skip()
	_check_training_isolation_static()
	_check_save_after_restore_keeps_authority()
	_check_new_game_session_reset()

func _check_static_boundaries() -> void:
	for path in DOWNGRADED_MANAGER_SOURCES:
		var source := FileAccess.get_file_as_string(path)
		_expect(source.contains("FullSaveOrchestratorScript.should_skip_manager_local_restore()"), "manager local restore is guarded: %s" % path)
	# P4-03: formal continue/new-game routing moved from main.gd to FormalFlowRouter.
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var router_source := FileAccess.get_file_as_string("res://scripts/controllers/formal_flow_router.gd")
	_expect(main_source.contains("FormalFlowRouterScript.new()"), "main.gd creates the FormalFlowRouter")
	_expect(router_source.contains("FullSaveOrchestratorScript.restore_full_save()"), "formal continue calls FullSaveOrchestrator.restore_full_save (in router)")
	_expect(router_source.contains("FullSaveOrchestratorScript.reset_formal_restore_session()"), "new game/clear path resets formal restore session (in router)")
	_expect(not router_source.contains("TrainingManagerScript.load_progress()"), "formal continue no longer calls TrainingManager.load_progress")
	_expect(not FileAccess.get_file_as_string("res://scripts/systems/full_save_orchestrator.gd").contains("training_progress.json"), "Full Restore does not read training checkpoint")

func _check_no_full_save_fallback_guard() -> void:
	FullSaveOrchestratorScript.reset_formal_restore_guard_for_tests()
	_expect(not FullSaveOrchestratorScript.should_skip_manager_local_restore(), "manager fallback remains allowed before Full Restore")
	var missing := FullSaveOrchestratorScript.read_bundle(TEST_SAVE_PATH)
	_expect(not bool(missing.get("success", false)) and String(missing.get("code", "")) == FullSaveOrchestratorScript.RESULT_MISSING, "missing temp Full Save reports missing without local-manager restore")
	_expect(not FullSaveOrchestratorScript.should_skip_manager_local_restore(), "missing Full Save does not disable local fallback")

func _check_full_save_wins_and_late_loads_skip() -> void:
	FullSaveOrchestratorScript.reset_formal_restore_guard_for_tests()
	var expected := _set_authoritative_state_b()
	var write_result := FullSaveOrchestratorScript.save_full_save({"BaseEntered": true, "CurrentDay": 5}, {"phase": "p3_03c"}, "res://scenes/base/OldBaseInteriorScene.tscn", TEST_SAVE_PATH)
	_expect(bool(write_result.get("success", false)), "temp Full Save B writes")
	_set_local_like_state_a()
	_expect(_snapshot_core() != expected, "live manager state can differ before restore")
	var restore_result := FullSaveOrchestratorScript.restore_full_save(null, TEST_SAVE_PATH)
	_expect(bool(restore_result.get("success", false)), "Full Restore succeeds")
	_expect(FullSaveOrchestratorScript.is_formal_restore_completed(), "formal restore guard is completed")
	_expect(_snapshot_core() == expected, "Full Save B wins over live/local-like A")
	_call_manager_local_load_helpers()
	await process_frame
	var scene_result := FullSaveOrchestratorScript.read_scene_state(TEST_SAVE_PATH)
	var _checkpoint := TrainingManagerScript.read_progress()
	_expect(bool(scene_result.get("success", false)), "checkpoint and scene queries stay read-only")
	_expect(_snapshot_core() == expected, "late manager load_state/deferred frame/checkpoint query cannot overwrite Full Save B")

func _check_new_game_session_reset() -> void:
	FullSaveOrchestratorScript.reset_formal_restore_session()
	_expect(not FullSaveOrchestratorScript.should_skip_manager_local_restore(), "new game/session reset leaves local fallback enabled")

func _check_training_isolation_static() -> void:
	var training_time_source := FileAccess.get_file_as_string("res://scripts/managers/TrainingTimeManager.gd")
	var training_source := FileAccess.get_file_as_string("res://scripts/training/training_manager.gd")
	_expect(not training_time_source.contains("should_skip_manager_local_restore"), "TrainingTime local restore is not blocked by formal guard")
	_expect(training_source.contains("static func load_progress()"), "TrainingManager restore API remains present")
	_expect(training_source.contains("start_training_time"), "TrainingManager training flow still talks to TrainingTimeManager")

func _check_save_after_restore_keeps_authority() -> void:
	var expected := _snapshot_core()
	_backup_file(TEST_LOCAL_SAVE_PATH)
	_manager("TimeManager").call("save_state")
	_expect(FileAccess.file_exists(TEST_LOCAL_SAVE_PATH), "manager save_state can still write local debug mirror")
	_call_manager_local_load_helpers()
	_expect(_snapshot_core() == expected, "local save/load after Full Restore does not override authoritative state")
	_restore_file(TEST_LOCAL_SAVE_PATH)

func _set_authoritative_state_b() -> Dictionary:
	var time_state: Dictionary = _manager("TimeManager").call("serialize")
	time_state["total_minutes"] = 2222
	time_state["current_day"] = 2
	time_state["hour"] = 19
	time_state["minute"] = 42
	_manager("TimeManager").call("deserialize", time_state)
	var power_state: Dictionary = _manager("PowerSystemManager").call("serialize")
	power_state["current_energy"] = 88.0
	power_state["battery_capacity"] = 120.0
	power_state["base_battery_capacity"] = 120.0
	power_state["charging_efficiency"] = 0.82
	_manager("PowerSystemManager").call("deserialize", power_state)
	var suit_state: Dictionary = _manager("SuitManager").call("serialize")
	suit_state["is_suit_worn"] = true
	suit_state["suit_storage_state"] = "worn"
	suit_state["suit_power"] = 66.0
	_manager("SuitManager").call("deserialize", suit_state)
	return _snapshot_core()

func _set_local_like_state_a() -> void:
	var time_state: Dictionary = _manager("TimeManager").call("serialize")
	time_state["total_minutes"] = 17
	time_state["current_day"] = 1
	time_state["hour"] = 6
	time_state["minute"] = 41
	_manager("TimeManager").call("deserialize", time_state)
	var power_state: Dictionary = _manager("PowerSystemManager").call("serialize")
	power_state["current_energy"] = 9.0
	power_state["battery_capacity"] = 120.0
	power_state["base_battery_capacity"] = 120.0
	power_state["charging_efficiency"] = 0.18
	_manager("PowerSystemManager").call("deserialize", power_state)
	var suit_state: Dictionary = _manager("SuitManager").call("serialize")
	suit_state["is_suit_worn"] = false
	suit_state["suit_storage_state"] = "ready"
	suit_state["suit_power"] = 11.0
	_manager("SuitManager").call("deserialize", suit_state)

func _call_manager_local_load_helpers() -> void:
	for node_name in DOWNGRADED_MANAGER_NODES:
		var manager := _manager(node_name)
		if manager != null and manager.has_method("load_state"):
			manager.call("load_state")

func _snapshot_core() -> Dictionary:
	return {
		"time": _manager("TimeManager").call("serialize"),
		"power": _manager("PowerSystemManager").call("serialize"),
		"suit": _manager("SuitManager").call("serialize"),
		"player_state": _manager("PlayerStateManager").call("serialize"),
	}

func _manager(name: String) -> Node:
	return root.get_node_or_null(name)

func _cleanup() -> void:
	for path in [TEST_SAVE_PATH, TEST_SAVE_PATH + FullSaveOrchestratorScript.TEMP_SUFFIX, TEST_SAVE_PATH + FullSaveOrchestratorScript.BACKUP_SUFFIX]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if file_backups.has(TEST_LOCAL_SAVE_PATH):
		_restore_file(TEST_LOCAL_SAVE_PATH)

func _backup_file(path: String) -> void:
	if file_backups.has(path):
		return
	file_backups[path] = {
		"exists": FileAccess.file_exists(path),
		"text": FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "",
	}

func _restore_file(path: String) -> void:
	if not file_backups.has(path):
		return
	var backup: Dictionary = file_backups[path]
	if bool(backup.get("exists", false)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_string(String(backup.get("text", "")))
	elif FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	file_backups.erase(path)

func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failed += 1
		push_error("[P3-03c] FAIL: %s" % label)
	else:
		print("[P3-03c] PASS: %s" % label)
