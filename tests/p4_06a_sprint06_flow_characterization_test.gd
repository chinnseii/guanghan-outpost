extends SceneTree

## P4-06A characterization (headless, source-analysis). Run with:
##   godot --headless --path . --script res://tests/p4_06a_sprint06_flow_characterization_test.gd
## Exit 0 = pass. Locks the CURRENT sprint06 schedule/mission-flow behavior via source structure,
## WITHOUT instantiating the base scene (booting it would autosave). Reads no save files.

const SCENE_PATH := "res://scripts/base/sprint06_base_scene.gd"

var _done := false
var _failures: Array[String] = []
var _checks := 0
var _src := ""

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	_src = _read_text(SCENE_PATH)
	_run_all()
	var passed := _checks - _failures.size()
	print("\n[P4-06A] checks=%d passed=%d failed=%d" % [_checks, passed, _failures.size()])
	for failure in _failures:
		print("  FAIL: %s" % failure)
	if _failures.is_empty():
		print("[P4-06A] ALL PASS")
	quit(0 if _failures.is_empty() else 1)
	return true

func _ok(label: String, condition: bool) -> void:
	_checks += 1
	if condition:
		print("  ok: %s" % label)
	else:
		_failures.append(label)

func _read_text(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	return "" if f == null else f.get_as_text()

## Body of a top-level function (from its `func <name>(` line to the next top-level `func `).
func _method_body(name: String) -> String:
	var start := _src.find("func %s(" % name)
	if start == -1:
		return ""
	var next := _src.find("\nfunc ", start + 1)
	if next == -1:
		next = _src.length()
	return _src.substr(start, next - start)

## Assert a < b < ... (all substrings present and in ascending source order) within `body`.
func _in_order(body: String, parts: Array) -> bool:
	var last := -1
	for p in parts:
		var idx := body.find(String(p))
		if idx == -1 or idx <= last:
			return false
		last = idx
	return true

func _run_all() -> void:
	_ok("sprint06 source loaded", _src != "")
	_test_execution_order()
	_test_schedule_conditions()
	_test_completion_boundary()
	_test_manager_boundary()

## A. Execution order locks.
func _test_execution_order() -> void:
	var interact := _method_body("_interact")
	_ok("A: _interact guards sequence_running before dispatch", _in_order(interact, ["if sequence_running:", "return", "scene_kind"]))

	var finish1 := _method_body("_finish_day_one")
	_ok("A: _finish_day_one writes completion -> saves -> changes scene (in order)",
		_in_order(finish1, ["state[\"Day01Completed\"] = true", "_save_state()", "change_scene_to_file"]))

	var finishw := _method_body("_finish_week_day")
	_ok("A: _finish_week_day advances time before saving before transitioning",
		_in_order(finishw, ["_advance_action_time(", "_save_state()", "change_scene_to_file"]))

	var cdc := _method_body("_complete_daily_check")
	_ok("A: daily check gates on console before starting the equipment interaction",
		_in_order(cdc, ["DailyConsoleChecked", "_begin_equipment_interaction("]))
	_ok("A: DailyInspectionsComplete is set inside the post-interaction callback (after _begin_equipment_interaction)",
		cdc.find("_begin_equipment_interaction(") != -1 and cdc.find("DailyInspectionsComplete") > cdc.find("_begin_equipment_interaction("))

## B. Schedule day->required-keys table is preserved exactly.
func _test_schedule_conditions() -> void:
	var keys := _method_body("_daily_required_keys")
	_ok("B: day 3 required keys", keys.contains("3:") and keys.contains("[\"DailyConsoleChecked\", \"DailyPowerChecked\", \"DailyLifeSupportChecked\", \"DailyPlantChecked\"]"))
	_ok("B: day 4 required keys", keys.contains("4:") and keys.contains("[\"DailyConsoleChecked\", \"DailyWaterChecked\", \"DailySpecialChecked\", \"DailyPlantChecked\"]"))
	_ok("B: day 6 required keys (record update)", keys.contains("6:") and keys.contains("[\"DailyConsoleChecked\", \"DailySpecialChecked\", \"DailyPlantChecked\", \"DailyRecordUpdated\"]"))
	_ok("B: default required keys = console only", keys.contains("return [\"DailyConsoleChecked\"]"))
	# Day02 inspection predicate reads exactly the 4 Day02 flags.
	var d02 := _method_body("_day02_inspections_complete")
	_ok("B: day02 inspections require the 4 Day02 flags", d02.contains("Day02PowerChecked") and d02.contains("Day02LifeSupportChecked") and d02.contains("Day02WaterChecked") and d02.contains("Day02LastPlantChecked"))

## C. Completion predicate is pure over the required keys; current_day is pure over state.
func _test_completion_boundary() -> void:
	var complete := _method_body("_daily_checks_complete")
	_ok("C: _daily_checks_complete iterates _daily_required_keys and reads state (no writes)",
		complete.contains("_daily_required_keys()") and complete.contains("state.get(") and not complete.contains("state[") and not complete.contains("_save_state"))
	var cur := _method_body("_current_day")
	_ok("C: _current_day is a pure read of state (CurrentDay/DayNumber)",
		cur.contains("state.get(\"CurrentDay\"") and not cur.contains("state["))
	# The candidate evaluator methods must not write managers or save.
	for m in ["_daily_required_keys", "_daily_checks_complete", "_day02_inspections_complete", "_daily_checklist_text", "_day_label"]:
		var body := _method_body(m)
		_ok("C: pure predicate has no save/manager write: %s" % m,
			not body.contains("_save_state") and not body.contains("_advance_action_time") and not body.contains("change_scene_to_file"))

## D. Manager / save / responsibility boundary stays put.
func _test_manager_boundary() -> void:
	_ok("D: _save_state routes through FullSaveOrchestrator.save_full_save", _method_body("_save_state").contains("FullSaveOrchestratorScript.save_full_save"))
	_ok("D: _load_state routes through FullSaveOrchestrator.restore_full_save", _method_body("_load_state").contains("FullSaveOrchestratorScript.restore_full_save"))
	_ok("D: scene keeps the transition helper", _src.contains("func _transition_to("))
	_ok("D: scene keeps the finish sequences", _src.contains("func _finish_day_one(") and _src.contains("func _finish_week_day("))
	# Task flow is NOT owned by the extracted controllers.
	var nav := _read_text("res://scripts/controllers/base_navigation_controller.gd")
	var hud := _read_text("res://scripts/controllers/base_hud_panel_presenter.gd")
	var router := _read_text("res://scripts/controllers/formal_flow_router.gd")
	_ok("D: navigation controller has no daily/mission flow", not nav.contains("_daily") and not nav.contains("_finish") and not nav.contains("save_full_save"))
	_ok("D: HUD presenter has no daily/mission flow", not hud.contains("_daily") and not hud.contains("_finish") and not hud.contains("_complete_daily"))
	_ok("D: FormalFlowRouter does not own sprint06 daily flow", not router.contains("DailyConsoleChecked") and not router.contains("_finish_day"))
	# sprint06 mission state is scene-local (Full Save scene_state), not TaskManager-canonical.
	_ok("D: sprint06 stores day flags in scene `state` (not a Manager)", _src.contains("state[\"Day01Completed\"]") and _src.contains("save_full_save(state"))
