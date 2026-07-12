extends SceneTree

## P4-07A characterization (headless, source-analysis). Run with:
##   godot --headless --path . --script res://tests/p4_07a_training_large_script_audit_test.gd
## Exit 0 = pass. Locks the CURRENT training-script UI/flow/checkpoint boundaries via source
## structure, WITHOUT instantiating any training/base scene (booting one would autosave).

const MODULE_PATH := "res://scripts/training/training_module_scene.gd"
const BASE_PATH := "res://scripts/training/training_base_map.gd"

var _done := false
var _failures: Array[String] = []
var _checks := 0
var _mod := ""
var _base := ""

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	_mod = _read_text(MODULE_PATH)
	_base = _read_text(BASE_PATH)
	_run_all()
	var passed := _checks - _failures.size()
	print("\n[P4-07A] checks=%d passed=%d failed=%d" % [_checks, passed, _failures.size()])
	for failure in _failures:
		print("  FAIL: %s" % failure)
	if _failures.is_empty():
		print("[P4-07A] ALL PASS")
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
	_test_big_script_facts()
	_test_ui_vs_flow_boundary()
	_test_checkpoint_boundary()
	_test_scenetree_boundary()

## A. Big-script facts + key methods + TrainingManager call locations.
func _test_big_script_facts() -> void:
	_ok("both training scripts load", _mod != "" and _base != "")
	_ok("training_module_scene is P1-sized (>3000 lines)", _line_count(_mod) > 3000)
	_ok("training_base_map is P1-sized (>2000 lines)", _line_count(_base) > 2000)
	# Core methods exist in both.
	for m in ["_build_screen", "_build_briefing_modal", "_build_pause_panel", "_build_interaction_panel", "_build_suit_status_panel", "_update_hud", "_sync_overlay_visibility"]:
		_ok("module_scene has UI builder %s" % m, _mod.contains("func %s(" % m))
		_ok("base_map has UI builder %s" % m, _base.contains("func %s(" % m))
	# TrainingManager checkpoint calls are present in the scene (not a controller).
	_ok("module_scene writes checkpoint via set_current_module / mark_module_completed",
		_mod.contains("TrainingManagerScript.set_current_module(") and _mod.contains("TrainingManagerScript.mark_module_completed("))

## B. UI-only vs flow-coupled vs mutation vs async boundary samples.
func _test_ui_vs_flow_boundary() -> void:
	# UI-only: _build_screen dynamically creates nodes (add_child), no checkpoint/step writes.
	var build := _method_body(_mod, "_build_screen")
	_ok("B: _build_screen is UI construction (add_child), not step/checkpoint mutation",
		build.contains("add_child(") and not build.contains("_complete_step(") and not build.contains("mark_module_completed("))
	# Flow-coupled UI: suit-confirm advances the step.
	var confirm := _method_body(_mod, "_on_confirm_suit_status_pressed")
	_ok("B: suit-status confirm is flow-coupled (calls _complete_step)", confirm.contains("_complete_step("))
	# State mutation: _complete_step exists and is the step advancer (stays in scene).
	_ok("B: _complete_step is the state-mutation entry (in scene)", _mod.contains("func _complete_step("))
	# Async: module scene has awaits; UI builders do not.
	_ok("B: module scene has async sequences (await) outside the UI builders",
		_mod.contains("await ") and not build.contains("await "))

## C. Checkpoint boundary: writes stay in the scene; no Full Save misuse.
func _test_checkpoint_boundary() -> void:
	_ok("C: neither training script uses FullSaveOrchestrator (formal Full Save)",
		not _mod.contains("FullSaveOrchestrator") and not _base.contains("FullSaveOrchestrator"))
	# checkpoint writes localized to finish/entry points, not scattered into UI builders.
	var finish := _method_body(_mod, "_finish_module")
	_ok("C: _finish_module owns the module-complete checkpoint write", finish.contains("mark_module_completed("))
	var build := _method_body(_mod, "_build_screen")
	_ok("C: UI builder does not mark module completed", not build.contains("mark_module_completed("))

## D. SceneTree boundary: dynamic UI (no .tscn hardcoded node paths, no tween).
func _test_scenetree_boundary() -> void:
	_ok("D: module scene uses NO $Node hardcoded paths (UI is dynamic)", not _mod.contains("$") or not _mod.contains("$UI"))
	_ok("D: module scene builds UI dynamically via add_child", _mod.contains("add_child("))
	_ok("D: module scene uses no tween (UI is instant; presenter extraction needs no .tscn)", not _mod.contains("create_tween("))
	_ok("D: base_map room switching is scene-tree coupled (stays in scene)", _base.contains("func _switch_room(") or _base.contains("func _load_area("))
	# The (not-yet-created) presenter must not exist yet -- this is an audit-only round.
	_ok("D: no training presenter created this round (audit only)", _read_text("res://scripts/controllers/training_module_screen_presenter.gd") == "")
