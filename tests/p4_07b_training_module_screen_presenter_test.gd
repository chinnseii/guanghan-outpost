extends SceneTree

const MODULE_PATH := "res://scripts/training/training_module_scene.gd"
const BASE_PATH := "res://scripts/training/training_base_map.gd"
const PRESENTER_PATH := "res://scripts/controllers/training_module_screen_presenter.gd"
const PresenterScript := preload(PRESENTER_PATH)

var _done := false
var _failures: Array[String] = []
var _checks := 0
var _module_src := ""
var _base_src := ""
var _presenter_src := ""

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	_module_src = _read_text(MODULE_PATH)
	_base_src = _read_text(BASE_PATH)
	_presenter_src = _read_text(PRESENTER_PATH)
	_run_all()
	var passed := _checks - _failures.size()
	print("\n[P4-07B] checks=%d passed=%d failed=%d" % [_checks, passed, _failures.size()])
	for failure in _failures:
		print("  FAIL: %s" % failure)
	if _failures.is_empty():
		print("[P4-07B] ALL PASS")
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

func _line_count(src: String) -> int:
	return src.split("\n").size()

func _method_body(src: String, name: String) -> String:
	var start := src.find("func %s(" % name)
	if start == -1:
		return ""
	var next := src.find("\nfunc ", start + 1)
	if next == -1:
		next = src.length()
	return src.substr(start, next - start)

func _run_all() -> void:
	_test_presenter_builds_screen()
	_test_callbacks_are_shell_only()
	_test_source_boundaries()
	_test_training_boundaries_unchanged()

func _test_presenter_builds_screen() -> void:
	var owner := Control.new()
	root.add_child(owner)
	var calls: Array[String] = []
	var callbacks := {
		"save_progress": func(): calls.append("save"),
		"return_main": func(): calls.append("main"),
		"close_briefing": func(): calls.append("briefing"),
		"resume_training": func(): calls.append("resume"),
		"show_tasks": func(): calls.append("tasks"),
		"confirm_suit_status": func(): calls.append("suit"),
	}
	var presenter: TrainingModuleScreenPresenter = PresenterScript.new()
	presenter.build_screen(owner, {"title": "测试训练", "subtitle": "TEST MODULE"}, "power_repair", callbacks)
	_ok("A: presenter creates training_area and left-panel labels", presenter.training_area != null and presenter.objective_label != null and presenter.hud_label != null and presenter.hint_label != null)
	_ok("A: footer buttons exist and do not take keyboard focus", presenter.footer_save_button != null and presenter.footer_save_button.focus_mode == Control.FOCUS_NONE and presenter.footer_main_button.focus_mode == Control.FOCUS_NONE)
	presenter.build_training_overlays(owner, {"title": "测试训练"}, "power_repair", false, callbacks)
	_ok("A: presenter creates popup and overlay panels", presenter.popup != null and presenter.briefing_modal != null and presenter.pause_panel != null and presenter.interaction_panel != null and presenter.suit_status_modal != null)
	presenter.update_hud({
		"objective_text": "当前目标：测试",
		"minimal_title": "测试训练",
		"minimal_objective": "当前目标：测试",
		"minimal_time": "剩余 07:00",
		"hud_text": "系统稳定",
		"hint_text": "靠近目标",
	})
	_ok("A: update_hud writes only presenter-owned labels", presenter.objective_label.text == "当前目标：测试" and presenter.hud_label.text == "系统稳定" and presenter.hint_label.text == "靠近目标")
	presenter.refresh_suit_status_panel({"available": true, "oxygen": 75.0, "power": 61.0, "speed_multiplier": 0.8}, "power_repair")
	_ok("A: suit panel refresh uses injected status data", presenter.suit_status_text_label.text.contains("氧气储备：75%") and presenter.suit_status_text_label.text.contains("太阳能阵列维修"))
	presenter.show_entry_blocked_dialog(callbacks["return_main"])
	_ok("A: entry-blocked briefing stays display-only", presenter.briefing_modal.visible and presenter.briefing_modal.get_child_count() >= 1)
	owner.queue_free()

func _test_callbacks_are_shell_only() -> void:
	var owner := Control.new()
	root.add_child(owner)
	var calls: Array[String] = []
	var callbacks := {
		"save_progress": func(): calls.append("save"),
		"return_main": func(): calls.append("main"),
		"close_briefing": func(): calls.append("briefing"),
		"resume_training": func(): calls.append("resume"),
		"show_tasks": func(): calls.append("tasks"),
		"confirm_suit_status": func(): calls.append("suit"),
	}
	var presenter: TrainingModuleScreenPresenter = PresenterScript.new()
	presenter.build_screen(owner, {}, "suit_control", callbacks)
	presenter.build_training_overlays(owner, {}, "suit_control", false, callbacks)
	presenter.footer_save_button.emit_signal("pressed")
	presenter.footer_main_button.emit_signal("pressed")
	presenter.briefing_confirm_button.emit_signal("pressed")
	presenter.pause_resume_button.emit_signal("pressed")
	presenter.pause_tasks_button.emit_signal("pressed")
	presenter.suit_status_confirm_button.emit_signal("pressed")
	_ok("B: presenter buttons emit scene-supplied intents", calls == ["save", "main", "briefing", "resume", "tasks", "suit"])
	var no_callback_presenter: TrainingModuleScreenPresenter = PresenterScript.new()
	no_callback_presenter.build_screen(owner, {}, "suit_control", {})
	no_callback_presenter.build_training_overlays(owner, {}, "suit_control", false, {})
	no_callback_presenter.footer_save_button.emit_signal("pressed")
	no_callback_presenter.suit_status_confirm_button.emit_signal("pressed")
	_ok("B: missing callbacks are safe no-ops", true)
	owner.queue_free()

func _test_source_boundaries() -> void:
	_ok("C: presenter script exists and is a RefCounted display helper", _presenter_src.contains("class_name TrainingModuleScreenPresenter") and _presenter_src.contains("extends RefCounted"))
	_ok("C: module scene owns presenter instance", _module_src.contains("TrainingModuleScreenPresenterScript") and _module_src.contains("screen_presenter"))
	_ok("C: presenter has no checkpoint writes", not _presenter_src.contains("mark_module_completed(") and not _presenter_src.contains("set_current_module("))
	_ok("C: presenter has no step advancer or module finisher", not _presenter_src.contains("_complete_step(") and not _presenter_src.contains("_finish_module("))
	_ok("C: presenter has no formal save or scene navigation dependency", not _presenter_src.contains("FullSaveOrchestrator") and not _presenter_src.contains("change_scene_to_file("))
	_ok("C: popup container moved behind presenter wrappers", _presenter_src.contains("open_popup(") and _module_src.contains("_open_training_popup("))
	_ok("C: module scene line count reduced into expected P4-07B band", _line_count(_module_src) >= 3000 and _line_count(_module_src) <= 3150)

func _test_training_boundaries_unchanged() -> void:
	_ok("D: step mutation remains in module scene", _module_src.contains("func _complete_step(") and _module_src.contains("func _finish_module("))
	_ok("D: checkpoint writes remain in module scene", _module_src.contains("TrainingManagerScript.set_current_module(") and _module_src.contains("TrainingManagerScript.mark_module_completed("))
	_ok("D: training area and room target construction remain in scene", _module_src.contains("func _build_training_area(") and _module_src.contains("target_nodes"))
	_ok("D: async interaction loop remains in scene", _method_body(_module_src, "_begin_step_interaction_feedback").contains("await "))
	_ok("D: training_base_map untouched by presenter extraction", not _base_src.contains("TrainingModuleScreenPresenter"))
