extends SceneTree

const FullSaveOrchestratorScript := preload("res://scripts/systems/full_save_orchestrator.gd")
const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")

const TEST_SAVE_PATH := "user://saves/p3_03b_test_full_save.json"
const TEST_LEGACY_PATH := "user://saves/p3_03b_test_legacy_sprint06.json"

var checks := 0
var failed := 0

func _init() -> void:
	await process_frame
	_cleanup()
	_run()
	_cleanup()
	print("[P3-03b] checks=%d passed=%d failed=%d" % [checks, checks - failed, failed])
	if failed > 0:
		quit(1)
	else:
		print("[P3-03b] ALL PASS")
		quit(0)

func _run() -> void:
	_check_provider_manifest()
	_check_schema_validation()
	_check_full_save_round_trip()
	_check_restart_simulation()
	_check_legacy_best_effort()
	_check_atomic_write_temp_cleanup()
	_check_training_isolation_static()

func _check_provider_manifest() -> void:
	var providers := FullSaveOrchestratorScript.provider_specs()
	_expect(providers.size() == 14, "provider count is explicit")
	var ids := []
	for spec in providers:
		ids.append(String(spec.get("id", "")))
	for required_id in ["time", "health", "base_status", "power", "water", "air", "suit", "player_state", "backpack", "storage", "inventory", "supply", "repair"]:
		_expect(required_id in ids, "provider listed: %s" % required_id)
	_expect(not ("door" in ids), "door is not included while formal base is not connected")
	_expect(not ("training_time" in ids), "TrainingTime is not core Full Save time")

func _check_schema_validation() -> void:
	var bundle := FullSaveOrchestratorScript.build_bundle({"BaseEntered": true}, {}, "res://scenes/base/OldBaseCore_ArtSlice.tscn")
	var ok := FullSaveOrchestratorScript.validate_bundle(bundle, true)
	_expect(bool(ok.get("success", false)), "schema v1 validates")
	_expect(int(bundle.get("schema_version", 0)) == 1, "schema_version is integer v1")
	_expect(bundle.get("canonical_state", {}) is Dictionary, "canonical_state exists")
	_expect(bundle.get("scene_state", {}) is Dictionary, "scene_state exists")
	_expect(bundle.get("player_context", {}) is Dictionary, "player_context exists")
	var future := bundle.duplicate(true)
	future["schema_version"] = 999
	var future_result := FullSaveOrchestratorScript.validate_bundle(future, false)
	_expect(not bool(future_result.get("success", false)) and String(future_result.get("code", "")) == FullSaveOrchestratorScript.RESULT_UNSUPPORTED_SCHEMA, "future schema rejected")
	var missing := bundle.duplicate(true)
	(missing["canonical_state"] as Dictionary).erase("power")
	var missing_result := FullSaveOrchestratorScript.validate_bundle(missing, false)
	_expect(not bool(missing_result.get("success", false)), "missing critical provider rejected")
	var optional_missing := bundle.duplicate(true)
	(optional_missing["canonical_state"] as Dictionary).erase("plant_growth")
	var optional_result := FullSaveOrchestratorScript.validate_bundle(optional_missing, false)
	_expect(bool(optional_result.get("success", false)), "missing optional provider accepted")
	var invalid_scene := bundle.duplicate(true)
	invalid_scene["target_scene"] = "res://scenes/nope/DefinitelyMissing.tscn"
	var invalid_scene_result := FullSaveOrchestratorScript.validate_bundle(invalid_scene, true)
	_expect(not bool(invalid_scene_result.get("success", false)) and String(invalid_scene_result.get("code", "")) == FullSaveOrchestratorScript.RESULT_INVALID_SCENE, "invalid scene path rejected")

func _check_full_save_round_trip() -> void:
	var before := _set_known_manager_state()
	var write_result := FullSaveOrchestratorScript.save_full_save({"BaseEntered": true, "Day01Completed": true}, {"test": "round_trip"}, "res://scenes/base/OldBaseCore_ArtSlice.tscn", TEST_SAVE_PATH)
	_expect(bool(write_result.get("success", false)), "write full save succeeds")
	_disrupt_manager_state()
	var restore_result := FullSaveOrchestratorScript.restore_full_save(null, TEST_SAVE_PATH)
	_expect(bool(restore_result.get("success", false)), "restore full save succeeds")
	var after := _snapshot_core()
	_expect(after == before, "canonical state round-trips")
	_expect(_power_mirror_matches(), "Power mirror finalized after restore")
	_expect(_suit_mirror_matches(), "Suit mirror finalized after restore")

func _check_restart_simulation() -> void:
	_set_known_manager_state()
	var write_result := FullSaveOrchestratorScript.save_full_save({"BaseEntered": true, "CurrentDay": 4, "DayStarted": true}, {}, "res://scenes/base/OldBaseCore_ArtSlice.tscn", TEST_SAVE_PATH)
	_expect(bool(write_result.get("success", false)), "restart simulation write succeeds")
	_disrupt_manager_state()
	var restore_result := FullSaveOrchestratorScript.restore_full_save(null, TEST_SAVE_PATH)
	_expect(bool(restore_result.get("success", false)), "restart simulation restore succeeds")
	var scene_result := FullSaveOrchestratorScript.read_scene_state(TEST_SAVE_PATH)
	_expect(bool(scene_result.get("success", false)) and int((scene_result.get("scene_state", {}) as Dictionary).get("CurrentDay", 0)) == 4, "scene state reloads from bundle")
	_expect(_power_mirror_matches(), "restart Power mirror finalized")
	_expect(_suit_mirror_matches(), "restart Suit mirror finalized")

func _check_legacy_best_effort() -> void:
	var legacy := {
		"BaseEntered": true,
		"GreenhouseUnlocked": true,
		"PowerSystemState": _manager("PowerSystemManager").call("serialize"),
		"SuitState": _manager("SuitManager").call("serialize"),
	}
	_write_json(TEST_LEGACY_PATH, legacy)
	var result := FullSaveOrchestratorScript.read_bundle(TEST_LEGACY_PATH)
	_expect(bool(result.get("success", false)), "legacy unversioned sprint06 best-effort accepted")
	_expect(bool(result.get("legacy_source", false)), "legacy source is marked")
	var bundle: Dictionary = result.get("bundle", {}) as Dictionary
	_expect(int(bundle.get("schema_version", 0)) == 1, "legacy converted in memory to schema v1")
	_expect(bool((bundle.get("scene_state", {}) as Dictionary).get("GreenhouseUnlocked", false)), "legacy scene flags preserved")
	_write_text(TEST_SAVE_PATH, "{not json")
	var invalid := FullSaveOrchestratorScript.read_bundle(TEST_SAVE_PATH)
	_expect(not bool(invalid.get("success", false)) and String(invalid.get("code", "")) == FullSaveOrchestratorScript.RESULT_INVALID_JSON, "invalid JSON rejected")
	var future := FullSaveOrchestratorScript.build_bundle({}, {}, "")
	future["schema_version"] = 99
	_write_json(TEST_SAVE_PATH, future)
	var future_result := FullSaveOrchestratorScript.read_bundle(TEST_SAVE_PATH)
	_expect(not bool(future_result.get("success", false)) and String(future_result.get("code", "")) == FullSaveOrchestratorScript.RESULT_UNSUPPORTED_SCHEMA, "unknown higher schema rejected on read")

func _check_atomic_write_temp_cleanup() -> void:
	var first := FullSaveOrchestratorScript.save_full_save({"BaseEntered": true}, {}, "", TEST_SAVE_PATH)
	_expect(bool(first.get("success", false)), "atomic write first pass succeeds")
	var second := FullSaveOrchestratorScript.save_full_save({"BaseEntered": true, "Day01Completed": true}, {}, "", TEST_SAVE_PATH)
	_expect(bool(second.get("success", false)), "atomic replace succeeds")
	_expect(not FileAccess.file_exists(TEST_SAVE_PATH + FullSaveOrchestratorScript.TEMP_SUFFIX), "temporary file cleaned")
	_expect(not FileAccess.file_exists(TEST_SAVE_PATH + FullSaveOrchestratorScript.BACKUP_SUFFIX), "replacement backup cleaned")
	var read_result := FullSaveOrchestratorScript.read_scene_state(TEST_SAVE_PATH)
	_expect(bool(read_result.get("success", false)) and bool((read_result.get("scene_state", {}) as Dictionary).get("Day01Completed", false)), "new authoritative file present after replace")

func _check_training_isolation_static() -> void:
	var full_save_source := FileAccess.get_file_as_string("res://scripts/systems/full_save_orchestrator.gd")
	var training_source := FileAccess.get_file_as_string("res://scripts/training/training_manager.gd")
	_expect(not full_save_source.contains("training_progress.json"), "Full Restore does not read training_progress")
	_expect(not full_save_source.contains("load_progress("), "Full Restore does not call TrainingManager.load_progress")
	_expect(training_source.contains("SAVE_PATH := \"user://saves/training_progress.json\""), "training checkpoint keeps separate path")
	_expect(training_source.contains("FullSaveOrchestratorScript.continue_scene_path()"), "training continue queries full save without restoring training")

func _set_known_manager_state() -> Dictionary:
	var power_state: Dictionary = _manager("PowerSystemManager").call("serialize")
	power_state["current_energy"] = 72.0
	power_state["battery_capacity"] = 100.0
	power_state["charging_efficiency"] = 0.64
	_manager("PowerSystemManager").call("deserialize", power_state)
	var suit_state: Dictionary = _manager("SuitManager").call("serialize")
	suit_state["is_suit_worn"] = true
	suit_state["suit_storage_state"] = "worn"
	_manager("SuitManager").call("deserialize", suit_state)
	return _snapshot_core()

func _disrupt_manager_state() -> void:
	var power_state: Dictionary = _manager("PowerSystemManager").call("serialize")
	power_state["current_energy"] = 12.0
	power_state["battery_capacity"] = 100.0
	power_state["charging_efficiency"] = 0.2
	_manager("PowerSystemManager").call("deserialize", power_state)
	var suit_state: Dictionary = _manager("SuitManager").call("serialize")
	suit_state["is_suit_worn"] = false
	suit_state["suit_storage_state"] = "ready"
	_manager("SuitManager").call("deserialize", suit_state)

func _snapshot_core() -> Dictionary:
	return {
		"power": _manager("PowerSystemManager").call("serialize"),
		"suit": _manager("SuitManager").call("serialize"),
		"player_state": _manager("PlayerStateManager").call("serialize"),
	}

func _power_mirror_matches() -> bool:
	return abs(float(_manager("PowerSystemManager").call("get_power_percent")) - float(_manager("BaseStatusManager").get("power"))) < 0.01

func _suit_mirror_matches() -> bool:
	return bool(_manager("SuitManager").get("is_suit_worn")) == bool(_manager("PlayerStateManager").get("is_suit_worn"))

func _manager(name: String) -> Node:
	return root.get_node_or_null(name)

func _write_json(path: String, data: Dictionary) -> void:
	_write_text(path, JSON.stringify(data, "\t"))

func _write_text(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(text)

func _cleanup() -> void:
	for path in [TEST_SAVE_PATH, TEST_SAVE_PATH + FullSaveOrchestratorScript.TEMP_SUFFIX, TEST_SAVE_PATH + FullSaveOrchestratorScript.BACKUP_SUFFIX, TEST_LEGACY_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failed += 1
		push_error("[P3-03b] FAIL: %s" % label)
	else:
		print("[P3-03b] PASS: %s" % label)
