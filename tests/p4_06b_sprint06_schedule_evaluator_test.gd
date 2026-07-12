extends SceneTree

## P4-06B verification (headless). Run with:
##   godot --headless --path . --script res://tests/p4_06b_sprint06_schedule_evaluator_test.gd
## Exit 0 = pass. Pure-function test: the evaluator is stateless and touches no disk/autoload/save.

const EvalScript := preload("res://scripts/controllers/sprint06_schedule_evaluator.gd")

var _done := false
var _failures: Array[String] = []
var _checks := 0

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	_run_all()
	var passed := _checks - _failures.size()
	print("\n[P4-06B] checks=%d passed=%d failed=%d" % [_checks, passed, _failures.size()])
	for failure in _failures:
		print("  FAIL: %s" % failure)
	if _failures.is_empty():
		print("[P4-06B] ALL PASS")
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

func _code_only(src: String) -> String:
	var out: Array[String] = []
	for raw in src.split("\n"):
		if String(raw).strip_edges().begins_with("#"):
			continue
		out.append(String(raw))
	return "\n".join(out)

func _run_all() -> void:
	_test_current_day()
	_test_required_keys()
	_test_daily_checks_complete()
	_test_day02()
	_test_text()
	_test_purity_and_immutability()
	_test_scene_delegation()

## A. current_day fallbacks.
func _test_current_day() -> void:
	var ev = EvalScript.new()
	_ok("current_day reads CurrentDay", ev.current_day({"CurrentDay": 5}) == 5)
	_ok("current_day falls back to DayNumber", ev.current_day({"DayNumber": 4}) == 4)
	_ok("current_day defaults to 2 when both missing", ev.current_day({}) == 2)
	_ok("current_day prefers CurrentDay over DayNumber", ev.current_day({"CurrentDay": 7, "DayNumber": 3}) == 7)

## B. required_daily_keys per day + unknown fallback + caller cannot poison later calls.
func _test_required_keys() -> void:
	var ev = EvalScript.new()
	_ok("day 3 keys", ev.required_daily_keys(3) == ["DailyConsoleChecked", "DailyPowerChecked", "DailyLifeSupportChecked", "DailyPlantChecked"])
	_ok("day 4 keys", ev.required_daily_keys(4) == ["DailyConsoleChecked", "DailyWaterChecked", "DailySpecialChecked", "DailyPlantChecked"])
	_ok("day 5 keys", ev.required_daily_keys(5) == ["DailyConsoleChecked", "DailyPowerChecked", "DailySpecialChecked", "DailyPlantChecked"])
	_ok("day 6 keys (record update)", ev.required_daily_keys(6) == ["DailyConsoleChecked", "DailySpecialChecked", "DailyPlantChecked", "DailyRecordUpdated"])
	_ok("day 7 keys", ev.required_daily_keys(7) == ["DailyConsoleChecked", "DailyPowerChecked", "DailyLifeSupportChecked", "DailyPlantChecked"])
	_ok("unknown day -> console only", ev.required_daily_keys(99) == ["DailyConsoleChecked"])
	# Mutating a returned array must not affect a later call.
	var a := ev.required_daily_keys(3)
	a.append("Poison")
	_ok("returned array does not poison later calls", ev.required_daily_keys(3) == ["DailyConsoleChecked", "DailyPowerChecked", "DailyLifeSupportChecked", "DailyPlantChecked"])

## C. daily_checks_complete truth table.
func _test_daily_checks_complete() -> void:
	var ev = EvalScript.new()
	_ok("day 3 all false -> incomplete", ev.daily_checks_complete(3, {}) == false)
	_ok("day 3 partial -> incomplete", ev.daily_checks_complete(3, {"DailyConsoleChecked": true, "DailyPowerChecked": true}) == false)
	var full := {"DailyConsoleChecked": true, "DailyPowerChecked": true, "DailyLifeSupportChecked": true, "DailyPlantChecked": true}
	_ok("day 3 all true -> complete", ev.daily_checks_complete(3, full) == true)
	_ok("extra unrelated keys do not break completion", ev.daily_checks_complete(3, {"DailyConsoleChecked": true, "DailyPowerChecked": true, "DailyLifeSupportChecked": true, "DailyPlantChecked": true, "Extra": false}) == true)
	_ok("unknown day needs only console", ev.daily_checks_complete(99, {"DailyConsoleChecked": true}) == true)

## D. day02_inspections_complete.
func _test_day02() -> void:
	var ev = EvalScript.new()
	var full := {"Day02PowerChecked": true, "Day02LifeSupportChecked": true, "Day02WaterChecked": true, "Day02LastPlantChecked": true}
	_ok("day02 all true -> complete", ev.day02_inspections_complete(full) == true)
	var missing := full.duplicate()
	missing.erase("Day02WaterChecked")
	_ok("day02 missing a flag -> incomplete", ev.day02_inspections_complete(missing) == false)
	var one_false := full.duplicate()
	one_false["Day02LastPlantChecked"] = false
	_ok("day02 one flag false -> incomplete", ev.day02_inspections_complete(one_false) == false)
	_ok("day02 extra fields ignored", ev.day02_inspections_complete({"Day02PowerChecked": true, "Day02LifeSupportChecked": true, "Day02WaterChecked": true, "Day02LastPlantChecked": true, "X": 1}) == true)

## E. Text output equivalence (punctuation / newlines / checkmarks / order preserved).
func _test_text() -> void:
	var ev = EvalScript.new()
	_ok("task_line unchecked uses box", ev.task_line("A", "K", {}) == "□ A")
	_ok("task_line checked uses tick", ev.task_line("A", "K", {"K": true}) == "✓ A")
	_ok("day_label zero-pads", ev.day_label(2) == "Day 02" and ev.day_label(7) == "Day 07")
	_ok("daily_report_label day 7 special", ev.daily_report_label(7) == "第一周驻留报告")
	_ok("daily_report_label other day", ev.daily_report_label(3) == "Day 03 对地报告")
	# Full checklist for day 3, all unchecked -> exact 5-line block.
	var expect3 := "□ 查看中央控制台\n□ 检查供电面板\n□ 检查生命支持\n□ 检查最后一株植物\n□ 发送Day 03 对地报告"
	_ok("day 3 checklist text exact", ev.daily_checklist_text(3, {}) == expect3)
	# Day 5, console+power checked -> ticks on those two lines only.
	var st5 := {"DailyConsoleChecked": true, "DailyPowerChecked": true}
	var expect5 := "✓ 查看中央控制台\n✓ 检查供电面板\n□ 检查当前负载\n□ 检查最后一株植物\n□ 发送Day 05 对地报告"
	_ok("day 5 checklist reflects checked flags", ev.daily_checklist_text(5, st5) == expect5)
	# Day 7 uses the week report label in the last line.
	_ok("day 7 checklist last line uses week report label", ev.daily_checklist_text(7, {}).ends_with("□ 发送第一周驻留报告"))
	# Unknown day -> only console line + report line.
	_ok("unknown day checklist = console + report", ev.daily_checklist_text(99, {}) == "□ 查看中央控制台\n□ 发送Day 99 对地报告")

## F. Purity + immutability: evaluator has no fields; never mutates input state.
func _test_purity_and_immutability() -> void:
	var src := _code_only(_read_text("res://scripts/controllers/sprint06_schedule_evaluator.gd"))
	_ok("evaluator has no member vars", not src.contains("\nvar "))
	_ok("evaluator has no Manager/root/save/await/change_scene", not src.contains("/root/") and not src.contains("FullSaveOrchestrator") and not src.contains("await ") and not src.contains("change_scene") and not src.contains("_save_state"))
	# Immutability: run every function against a snapshot and confirm the dict is unchanged.
	var ev = EvalScript.new()
	var state := {"CurrentDay": 5, "DayNumber": 5, "DailyConsoleChecked": true, "DailyPowerChecked": false, "Day02WaterChecked": true, "nested": {"a": 1}, "arr": [1, 2]}
	var before := state.duplicate(true)
	var _a = ev.current_day(state)
	var _b = ev.required_daily_keys(ev.current_day(state))
	var _c = ev.daily_checks_complete(ev.current_day(state), state)
	var _d = ev.day02_inspections_complete(state)
	var _e = ev.task_line("x", "DailyPowerChecked", state)
	var _f = ev.daily_checklist_text(ev.current_day(state), state)
	_ok("evaluator never mutates the passed-in state (deep-equal before/after)", state == before)

## G. Scene keeps thin delegators; mutation/async/save/transition stay in scene.
func _test_scene_delegation() -> void:
	var scene := _code_only(_read_text("res://scripts/base/sprint06_base_scene.gd"))
	_ok("scene creates Sprint06ScheduleEvaluator", scene.contains("Sprint06ScheduleEvaluator.new()"))
	_ok("scene delegates daily checks", scene.contains("_schedule_evaluator.daily_checks_complete("))
	_ok("scene delegates required keys", scene.contains("_schedule_evaluator.required_daily_keys("))
	_ok("scene delegates checklist text", scene.contains("_schedule_evaluator.daily_checklist_text("))
	_ok("scene keeps state mutation (_reset_daily_flags)", scene.contains("func _reset_daily_flags(") and scene.contains("state[\"DailyConsoleChecked\"] = false"))
	_ok("scene keeps finish sequences", scene.contains("func _finish_day_one(") and scene.contains("func _finish_week_day("))
	_ok("scene keeps transition + save", scene.contains("func _transition_to(") and scene.contains("func _save_state(") and scene.contains("func _load_state("))
	_ok("scene keeps equipment interaction + input locks", scene.contains("func _begin_equipment_interaction(") and scene.contains("sequence_running"))
	_ok("evaluator does not own completion/finish", not _read_text("res://scripts/controllers/sprint06_schedule_evaluator.gd").contains("DailyInspectionsComplete") and not _read_text("res://scripts/controllers/sprint06_schedule_evaluator.gd").contains("_finish_day"))
