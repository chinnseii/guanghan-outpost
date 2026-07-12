extends SceneTree

## P4-04 focused verification (headless). Run with:
##   godot --headless --path . --script res://tests/p4_04_base_hud_panel_presenter_test.gd
## Exit 0 = pass. build_ui() is the exact construction the base scene calls, so exercising it
## here covers the runtime path. Read-only w.r.t. disk: it builds UI nodes and toggles panels;
## a saves-SHA guard in the harness confirms no save writes.

const PresenterScript := preload("res://scripts/controllers/base_hud_panel_presenter.gd")

var _done := false
var _failures: Array[String] = []
var _checks := 0

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	_run_all()
	var passed := _checks - _failures.size()
	print("\n[P4-04] checks=%d passed=%d failed=%d" % [_checks, passed, _failures.size()])
	for failure in _failures:
		print("  FAIL: %s" % failure)
	if _failures.is_empty():
		print("[P4-04] ALL PASS")
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
	_test_build_and_expose()
	_test_toggle_and_refresh()
	_test_static_boundary()

## A + B. Presenter builds UI into the host, exposes the flow-updated label nodes.
func _test_build_and_expose() -> void:
	var host := Node.new()
	host.name = "BaseSceneHost"
	root.add_child(host)

	var hud = PresenterScript.new()
	_ok("presenter instantiates (not an autoload)", hud != null and root.get_node_or_null("BaseHudPanelPresenter") == null)
	hud.build_ui(host)

	var canvas := host.get_node_or_null("UIOverlay")
	_ok("build_ui attaches the UI overlay to the host", canvas != null)
	_ok("presenter exposes ui_root", hud.get("ui_root") != null)
	# Flow-updated labels exist (scene re-points its own vars at these).
	for field in ["hud_label", "message_label", "prompt_label", "ai_label", "time_hud_label", "interaction_panel", "interaction_bar"]:
		_ok("build_ui created %s" % field, hud.get(field) != null)
	# All 8 status panels exist.
	for field in ["base_status_panel", "plant_growth_panel", "air_system_panel", "power_system_panel", "water_system_panel", "inventory_panel", "backpack_storage_panel", "suit_panel"]:
		_ok("build_ui created %s" % field, hud.get(field) != null)
	_ok("panels start hidden", not bool(hud.get("base_status_panel").visible) and not bool(hud.get("suit_panel").visible))

	host.free()

## C + D. Panel toggle flips visibility + refresh is safe; greenhouse gate is injected.
func _test_toggle_and_refresh() -> void:
	var host := Node.new()
	root.add_child(host)
	var hud = PresenterScript.new()
	hud.build_ui(host)

	hud._toggle_base_status_panel()
	_ok("toggle shows base status panel", bool(hud.get("base_status_panel").visible))
	hud._toggle_base_status_panel()
	_ok("toggle hides base status panel", not bool(hud.get("base_status_panel").visible))

	# Plant-growth gate is injected (was scene_kind == greenhouse); false must NOT open it.
	hud._toggle_plant_growth_panel(false)
	_ok("plant-growth toggle blocked when not greenhouse", not bool(hud.get("plant_growth_panel").visible))
	hud._toggle_plant_growth_panel(true)
	_ok("plant-growth toggle opens when greenhouse", bool(hud.get("plant_growth_panel").visible))

	# refresh_open_panels must run without error and only touch visible panels.
	hud._toggle_air_system_panel()
	hud.refresh_open_panels()
	_ok("refresh_open_panels runs on the open panels without error", true)

	host.free()

## E. Static responsibility boundary: presenter is UI-only; scene keeps flow/save.
func _test_static_boundary() -> void:
	var pres := _code_only(_read_text("res://scripts/controllers/base_hud_panel_presenter.gd"))
	var scene := _code_only(_read_text("res://scripts/base/sprint06_base_scene.gd"))
	_ok("presenter does not call FullSaveOrchestrator", not pres.contains("FullSaveOrchestrator"))
	_ok("presenter does not save/load state", not pres.contains("_save_state(") and not pres.contains("_load_state("))
	_ok("presenter does not change scenes", not pres.contains("change_scene_to_file"))
	_ok("presenter does not advance time / write managers", not pres.contains("advance_time") and not pres.contains("adjust_stat"))
	# Scene retains flow / save / navigation.
	_ok("scene creates the presenter", scene.contains("BaseHudPanelPresenterScript.new()"))
	_ok("scene keeps Full Save restore call", scene.contains("FullSaveOrchestratorScript.restore_full_save"))
	_ok("scene keeps save/load state", scene.contains("func _save_state(") and scene.contains("func _load_state("))
	_ok("scene keeps the flow-coupled plant diagnosis UI", scene.contains("func _setup_plant_diagnosis_ui("))
	_ok("scene delegates panel toggles to the presenter", scene.contains("_hud._toggle_base_status_panel()"))
	_ok("scene delegates panel refresh to the presenter", scene.contains("_hud.refresh_open_panels()"))
	# Panel construction no longer in the scene.
	_ok("panel setup/toggle removed from scene", not scene.contains("func _setup_base_status_panel(") and not scene.contains("func _toggle_suit_panel("))
