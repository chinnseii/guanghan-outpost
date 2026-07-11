extends SceneTree

## P3-03a focused verification (headless). Run with:
##   godot --headless --path . --script res://tests/p3_03a_restore_consistency_test.gd
## Exit code 0 = all pass, 1 = failure.

const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")

var _done := false
var _failures: Array[String] = []
var _checks := 0

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	_run_all()
	var passed := _checks - _failures.size()
	print("\n[P3-03a] checks=%d passed=%d failed=%d" % [_checks, passed, _failures.size()])
	for failure in _failures:
		print("  FAIL: %s" % failure)
	if _failures.is_empty():
		print("[P3-03a] ALL PASS")
	quit(0 if _failures.is_empty() else 1)
	return true

func _ok(label: String, condition: bool) -> void:
	_checks += 1
	if condition:
		print("  ok: %s" % label)
	else:
		_failures.append(label)

func _node(name: String) -> Node:
	return root.get_node_or_null(name)

func _run_all() -> void:
	var required := [
		"TimeManager",
		"TrainingTimeManager",
		"HealthManager",
		"BaseStatusManager",
		"PowerSystemManager",
		"WaterSystemManager",
		"AirSystemManager",
		"SuitManager",
		"PlayerStateManager",
		"BackpackManager",
		"StorageManager",
		"SupplyManager",
		"TaskManager",
	]
	for name in required:
		_ok("autoload present: %s" % name, _node(name) != null)
	if not _failures.is_empty():
		return

	_test_power_restore_mirror()
	_test_suit_restore_mirror()
	_test_public_read_only_api()
	_test_static_call_points()
	_test_restore_operation()
	_test_finalize_idempotent_and_pure()

func _test_power_restore_mirror() -> void:
	var power := _node("PowerSystemManager")
	var base_status := _node("BaseStatusManager")
	base_status.set("power", 3.0)
	var observed := {"called": false, "canonical": -1.0, "mirror": -2.0}
	power.power_system_changed.connect(func():
		observed["called"] = true
		observed["canonical"] = power.call("get_power_percent")
		observed["mirror"] = float(base_status.get("power"))
	, CONNECT_ONE_SHOT)
	var data: Dictionary = power.call("serialize")
	data["current_energy"] = 40.0
	data["battery_capacity"] = 120.0
	data["base_battery_capacity"] = 120.0
	data["battery_module_count"] = 2
	data["storage_efficiency"] = 1.0
	power.call("deserialize", data)
	var canonical: float = power.call("get_power_percent")
	var mirror := float(base_status.get("power"))
	_ok("Power canonical restored (energy=40 -> ~33.3%%)", abs(canonical - 33.333) < 0.5)
	_ok("BaseStatus.power mirror == canonical after Power deserialize", abs(mirror - canonical) < 0.001)
	_ok("Power signal listener fired", bool(observed["called"]))
	_ok("Power signal listener sees synced mirror", abs(float(observed["mirror"]) - float(observed["canonical"])) < 0.001)

func _test_suit_restore_mirror() -> void:
	var suit := _node("SuitManager")
	var player_state := _node("PlayerStateManager")
	player_state.set("is_suit_worn", false)
	var observed := {"called": false, "canonical": false, "mirror": true}
	suit.suit_changed.connect(func():
		observed["called"] = true
		observed["canonical"] = bool(suit.get("is_suit_worn"))
		observed["mirror"] = bool(player_state.get("is_suit_worn"))
	, CONNECT_ONE_SHOT)
	var data: Dictionary = suit.call("serialize")
	data["is_suit_worn"] = true
	suit.call("deserialize", data)
	_ok("Suit canonical worn=true after deserialize", bool(suit.get("is_suit_worn")) == true)
	_ok("PlayerState.is_suit_worn mirror == canonical after Suit deserialize", bool(player_state.get("is_suit_worn")) == true)
	_ok("Suit signal listener fired", bool(observed["called"]))
	_ok("Suit signal listener sees synced mirror", bool(observed["mirror"]) == bool(observed["canonical"]))
	player_state.set("is_suit_worn", true)
	data["is_suit_worn"] = false
	suit.call("deserialize", data)
	_ok("Suit mirror follows canonical to worn=false", bool(player_state.get("is_suit_worn")) == false)

func _test_public_read_only_api() -> void:
	var before := _full_snapshot()
	var progress: Dictionary = TrainingManagerScript.read_progress()
	var _status := TrainingManagerScript.training_status()
	var _reason := TrainingManagerScript.training_failure_reason()
	var _scene := TrainingManagerScript.continue_scene_path()
	var task := _node("TaskManager")
	if task != null:
		var _objective: String = task.call("get_current_objective", "training")
		var _training_summary: Dictionary = task.call("get_progress", "training")
	var main_script_text := _read_text("res://scripts/main.gd")
	var scene_a_text := _read_text("res://scripts/training/mission_assignment_notice_scene.gd")
	var scene_b_text := _read_text("res://scripts/training/assignment_black_screen_scene.gd")
	var scene_c_text := _read_text("res://scripts/training/training_module_scene.gd")
	_ok("read_progress returns a Dictionary", progress is Dictionary)
	_ok("main.gd uses read_progress for pure continue checks", main_script_text.contains("TrainingManagerScript.read_progress()"))
	_ok("mission notice uses read_progress", scene_a_text.contains("TrainingManagerScript.read_progress()"))
	_ok("assignment black screen uses read_progress", scene_b_text.contains("TrainingManagerScript.read_progress()"))
	_ok("training module completion sync uses read_progress", scene_c_text.contains("TrainingManagerScript.read_progress()"))
	var after := _full_snapshot()
	_ok("public read-only APIs leave live managers unchanged", before == after)

func _test_static_call_points() -> void:
	var script_paths := _script_paths("res://scripts")
	var external_private_calls: Array[String] = []
	var load_progress_calls: Array[String] = []
	for path in script_paths:
		var text := _read_text(path)
		var lines := text.split("\n")
		for i in range(lines.size()):
			var line := String(lines[i])
			var stripped := line.strip_edges()
			if stripped.begins_with("#"):
				continue
			if path != "res://scripts/training/training_manager.gd" and line.contains("_read_progress_data("):
				external_private_calls.append("%s:%d" % [path, i + 1])
			if line.contains("load_progress("):
				if path == "res://scripts/main.gd":
					load_progress_calls.append("%s:%d" % [path, i + 1])
				elif path != "res://scripts/training/training_manager.gd":
					load_progress_calls.append("UNEXPECTED %s:%d" % [path, i + 1])
	_ok("no external script calls TrainingManager._read_progress_data()", external_private_calls.is_empty())
	_ok("only main.gd keeps an external real restore load_progress call", load_progress_calls.size() == 1 and not String(load_progress_calls[0]).begins_with("UNEXPECTED"))

func _test_restore_operation() -> void:
	var power := _node("PowerSystemManager")
	var base_status := _node("BaseStatusManager")
	var before := _full_snapshot()
	base_status.set("power", 1.0)
	var data: Dictionary = TrainingManagerScript.load_progress()
	_ok("load_progress returns a Dictionary", data is Dictionary)
	var canonical: float = power.call("get_power_percent")
	var mirror := float(base_status.get("power"))
	_ok("after load_progress, Power mirror finalized-consistent", abs(mirror - canonical) < 0.001)
	_ok("load_progress remains a restoring path when saved data differs or finalization repairs mirror", before != _full_snapshot() or abs(mirror - 1.0) > 0.001)

func _test_finalize_idempotent_and_pure() -> void:
	var power := _node("PowerSystemManager")
	var base_status := _node("BaseStatusManager")
	var suit := _node("SuitManager")
	var player_state := _node("PlayerStateManager")
	var before := _full_snapshot()
	var energy_before := float(power.get("current_energy"))
	base_status.set("power", 7.0)
	player_state.set("is_suit_worn", not bool(suit.get("is_suit_worn")))
	TrainingManagerScript.finalize_restore()
	var mirror_once := float(base_status.get("power"))
	var suit_once := bool(player_state.get("is_suit_worn"))
	TrainingManagerScript.finalize_restore()
	var mirror_twice := float(base_status.get("power"))
	var suit_twice := bool(player_state.get("is_suit_worn"))
	var canonical: float = power.call("get_power_percent")
	var after := _full_snapshot()
	var expected_after: Dictionary = before.duplicate(true)
	var expected_base: Dictionary = expected_after.get("BaseStatusManager", {})
	expected_base["power"] = canonical
	expected_after["BaseStatusManager"] = expected_base
	var expected_player: Dictionary = expected_after.get("PlayerStateManager", {})
	expected_player["is_suit_worn"] = bool(suit.get("is_suit_worn"))
	expected_after["PlayerStateManager"] = expected_player
	_ok("finalize syncs Power mirror to canonical", abs(mirror_once - canonical) < 0.001)
	_ok("finalize syncs Suit mirror to canonical", suit_once == bool(suit.get("is_suit_worn")))
	_ok("finalize idempotent for Power mirror", abs(mirror_once - mirror_twice) < 0.001)
	_ok("finalize idempotent for Suit mirror", suit_once == suit_twice)
	_ok("finalize advances no time / consumes no resources / triggers no persistent state beyond mirrors %s" % _snapshot_delta(expected_after, after), expected_after == after)
	_ok("finalize consumes no canonical power energy", abs(energy_before - float(power.get("current_energy"))) < 0.001)

func _full_snapshot() -> Dictionary:
	var result := {}
	for name in [
		"TimeManager",
		"TrainingTimeManager",
		"HealthManager",
		"BaseStatusManager",
		"PowerSystemManager",
		"WaterSystemManager",
		"AirSystemManager",
		"SuitManager",
		"PlayerStateManager",
		"BackpackManager",
		"StorageManager",
		"SupplyManager",
	]:
		var manager := _node(name)
		result[name] = manager.call("serialize") if manager != null and manager.has_method("serialize") else {}
	var task := _node("TaskManager")
	if task != null:
		result["TaskManager"] = {
			"training": task.call("get_progress", "training"),
			"mission": task.call("get_progress", "mission"),
			"supply": task.call("get_progress", "supply"),
			"objective": task.call("get_current_objective", "training"),
		}
	else:
		result["TaskManager"] = {}
	return result

func _snapshot_delta(expected: Dictionary, actual: Dictionary) -> String:
	var changed: Array[String] = []
	for key in expected.keys():
		if not actual.has(key):
			changed.append("%s missing" % key)
		elif expected[key] != actual[key]:
			changed.append(String(key))
	for key in actual.keys():
		if not expected.has(key):
			changed.append("%s unexpected" % key)
	if changed.is_empty():
		return ""
	return "changed=%s" % ",".join(changed)

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

func _script_paths(path: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(path)
	if dir == null:
		return result
	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry.is_empty():
			break
		if entry.begins_with("."):
			continue
		var child := "%s/%s" % [path, entry]
		if dir.current_is_dir():
			result.append_array(_script_paths(child))
		elif entry.ends_with(".gd"):
			result.append(child)
	dir.list_dir_end()
	return result
