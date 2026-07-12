extends SceneTree

const FullSaveOrchestratorScript := preload("res://scripts/systems/full_save_orchestrator.gd")
const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")

const TEST_LEGACY_SPRINT06_PATH := "user://saves/p3_03d_legacy_sprint06.json"
const TRAINING_PROGRESS_PATH := "user://saves/training_progress.json"

const LEGACY_GLOBAL_KEYS := [
	"TimeState",
	"HealthState",
	"BaseStatusState",
	"AirSystemState",
	"PowerSystemState",
	"WaterSystemState",
	"InventoryState",
	"BackpackState",
	"StorageState",
	"PlantGrowthState",
	"PlayerStateManagerState",
]

var checks := 0
var failed := 0
var file_backups: Dictionary = {}

func _init() -> void:
	await process_frame
	_backup_file(TRAINING_PROGRESS_PATH)
	_remove_test_files()
	_run()
	_cleanup()
	print("[P3-03d] checks=%d passed=%d failed=%d" % [checks, checks - failed, failed])
	if failed > 0:
		quit(1)
	else:
		print("[P3-03d] ALL PASS")
		quit(0)

func _run() -> void:
	_check_static_scope()
	_check_legacy_sprint06_is_read_only()
	_check_training_checkpoint_scope()
	_check_training_checkpoint_save_strips_legacy_globals()

func _check_static_scope() -> void:
	var training_source := FileAccess.get_file_as_string("res://scripts/training/training_manager.gd")
	var full_source := FileAccess.get_file_as_string("res://scripts/systems/full_save_orchestrator.gd")
	_expect(training_source.contains("LegacyGlobalStateFields"), "training legacy globals are exposed as metadata")
	_expect(training_source.contains("TrainingInventoryState"), "training inventory has scoped checkpoint field")
	_expect(training_source.contains("TrainingTimeState"), "training time has scoped checkpoint field")
	_expect(not training_source.contains("data.get(\"PowerSystemState\""), "training checkpoint no longer restores PowerSystemState")
	_expect(not training_source.contains("data.get(\"InventoryState\""), "training checkpoint no longer restores InventoryState")
	_expect(not full_source.contains("FileAccess.file_exists(LEGACY_SPRINT06_SAVE_PATH)"), "Full Save default read has no legacy sprint06 fallback")
	_expect(full_source.contains("Legacy sprint06 checkpoint is read-only"), "legacy sprint06 cannot be formal-restored")

func _check_legacy_sprint06_is_read_only() -> void:
	var before := _snapshot_global()
	_write_json(TEST_LEGACY_SPRINT06_PATH, {
		"BaseEntered": true,
		"PowerSystemState": {"current_energy": 1.0, "battery_capacity": 100.0},
		"SuitState": {"is_suit_worn": true},
	})
	var read_result := FullSaveOrchestratorScript.read_bundle(TEST_LEGACY_SPRINT06_PATH)
	_expect(bool(read_result.get("success", false)), "explicit legacy sprint06 read remains available")
	_expect(bool(read_result.get("legacy_source", false)), "explicit legacy sprint06 read is marked legacy")
	var restore_result := FullSaveOrchestratorScript.restore_full_save(null, TEST_LEGACY_SPRINT06_PATH)
	_expect(not bool(restore_result.get("success", false)), "legacy sprint06 restore is rejected")
	_expect(String(restore_result.get("code", "")) == FullSaveOrchestratorScript.RESULT_RESTORE_FAILED, "legacy sprint06 restore uses restore_failed code")
	_expect(_snapshot_global() == before, "rejected legacy sprint06 restore leaves globals unchanged")

func _check_training_checkpoint_scope() -> void:
	_set_training_owned_live_a()
	var before_global := _snapshot_global()
	var checkpoint := TrainingManagerScript.default_data()
	checkpoint["TrainingStarted"] = true
	checkpoint["CurrentTrainingModule"] = "power_repair"
	checkpoint["SuitState"] = {
		"is_suit_worn": true,
		"suit_storage_state": "worn",
		"suit_power": 77.0,
	}
	checkpoint["TrainingTimeState"] = {
		"archive_limit_minutes": 480,
		"elapsed_minutes": 123,
		"remaining_minutes": 357,
		"training_time_active": true,
		"training_time_paused": false,
		"time_log": [{"minutes": 123, "reason": "p3_03d"}],
	}
	checkpoint["TrainingInventoryState"] = {
		"training_containers": {
			"training_03_parts": {
				"MT-EL-001": 2,
				"MT-FI-001": 1,
			},
		},
	}
	for key in LEGACY_GLOBAL_KEYS:
		checkpoint[key] = {"p3_03d_legacy_global": key}
	_write_json(TRAINING_PROGRESS_PATH, checkpoint)
	var loaded: Dictionary = TrainingManagerScript.load_progress()
	_expect(bool(loaded.get("TrainingStarted", false)), "training flag loads from checkpoint")
	_expect(String(loaded.get("CurrentTrainingModule", "")) == "power_repair", "training module loads from checkpoint")
	_expect(loaded.get("LegacyGlobalStateFields", {}) is Dictionary, "legacy global fields are readable as metadata")
	_expect((loaded.get("LegacyGlobalStateFields", {}) as Dictionary).has("TimeState"), "legacy TimeState is metadata")
	_expect(_snapshot_global() == before_global, "training checkpoint does not restore global manager snapshots")
	_expect(_suit_mirror_matches() and bool(_manager("SuitManager").get("is_suit_worn")), "training suit state restores and syncs mirror")
	_expect(int(_manager("TrainingTimeManager").get("elapsed_minutes")) == 123, "training time state restores")
	_expect(_training_container_count("training_03_parts", "MT-EL-001") == 2, "training inventory container restores")
	_expect((_manager("InventoryManager").call("serialize") as Dictionary) == before_global.get("InventoryManager", {}), "real inventory serialize state remains unchanged")

func _check_training_checkpoint_save_strips_legacy_globals() -> void:
	var data := TrainingManagerScript.read_progress()
	for key in LEGACY_GLOBAL_KEYS:
		data[key] = {"must_not_persist": true}
	TrainingManagerScript.save_progress(data)
	var saved := _read_json(TRAINING_PROGRESS_PATH)
	var leaked := []
	for key in LEGACY_GLOBAL_KEYS:
		if saved.has(key):
			leaked.append(key)
	_expect(leaked.is_empty(), "save_progress strips legacy global fields: %s" % ",".join(leaked))
	_expect(saved.has("SuitState"), "save_progress keeps training suit state")
	_expect(saved.has("TrainingTimeState"), "save_progress keeps training time state")
	_expect(saved.has("TrainingInventoryState"), "save_progress keeps training inventory state")

func _set_training_owned_live_a() -> void:
	var suit_state: Dictionary = _manager("SuitManager").call("serialize")
	suit_state["is_suit_worn"] = false
	suit_state["suit_storage_state"] = "ready"
	suit_state["suit_power"] = 12.0
	_manager("SuitManager").call("deserialize", suit_state)
	_manager("TrainingTimeManager").call("deserialize", {
		"archive_limit_minutes": 480,
		"elapsed_minutes": 1,
		"remaining_minutes": 479,
		"training_time_active": true,
		"training_time_paused": false,
		"time_log": [],
	})
	_manager("InventoryManager").set("training_containers", {
		"training_03_parts": {"MT-EL-001": 1},
	})

func _snapshot_global() -> Dictionary:
	var result := {}
	for name in [
		"TimeManager",
		"HealthManager",
		"BaseStatusManager",
		"PowerSystemManager",
		"WaterSystemManager",
		"AirSystemManager",
		"InventoryManager",
		"BackpackManager",
		"StorageManager",
		"SupplyManager",
	]:
		var manager := _manager(name)
		result[name] = manager.call("serialize") if manager != null and manager.has_method("serialize") else {}
	return result

func _suit_mirror_matches() -> bool:
	return bool(_manager("SuitManager").get("is_suit_worn")) == bool(_manager("PlayerStateManager").get("is_suit_worn"))

func _training_container_count(container_id: String, item_id: String) -> int:
	return int(_manager("InventoryManager").call("get_container_item_count", container_id, item_id))

func _manager(name: String) -> Node:
	return root.get_node_or_null(name)

func _write_json(path: String, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}

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

func _cleanup() -> void:
	_remove_test_files()
	_restore_file(TRAINING_PROGRESS_PATH)

func _remove_test_files() -> void:
	if FileAccess.file_exists(TEST_LEGACY_SPRINT06_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_LEGACY_SPRINT06_PATH))

func _expect(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("[P3-03d] PASS: %s" % label)
	else:
		failed += 1
		push_error("[P3-03d] FAIL: %s" % label)
