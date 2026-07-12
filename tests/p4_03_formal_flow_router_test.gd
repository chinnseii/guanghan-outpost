extends SceneTree

## P4-03 focused verification (headless). Run with:
##   godot --headless --path . --script res://tests/p4_03_formal_flow_router_test.gd
## Exit 0 = pass. File-safe: routing priority is tested via a probe subclass that overrides the
## file-reading predicates, and all injected callbacks are observers, so no real save is written
## or deleted (empty demo paths + non-existent slot paths are injected).

const FormalFlowRouterScript := preload("res://scripts/controllers/formal_flow_router.gd")
const APP_SCENE := "res://scenes/application/ApplicationStartScene.tscn"

## Probe: control the file-reading predicates so we can assert routing PRIORITY deterministically.
class RouterProbe extends FormalFlowRouter:
	var fake_full := false
	var fake_training := false
	var fake_app := false
	var fake_slot := 0
	func full_save_exists() -> bool:
		return fake_full
	func training_has_progress(_progress: Dictionary) -> bool:
		return fake_training
	func application_progress_exists() -> bool:
		return fake_app
	func latest_save_slot() -> int:
		return fake_slot

var _done := false
var _failures: Array[String] = []
var _checks := 0

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	_run_all()
	var passed := _checks - _failures.size()
	print("\n[P4-03] checks=%d passed=%d failed=%d" % [_checks, passed, _failures.size()])
	for failure in _failures:
		print("  FAIL: %s" % failure)
	if _failures.is_empty():
		print("[P4-03] ALL PASS")
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

## Source with whole-line comments removed, so absence-checks scan CODE only (not docstrings
## that legitimately mention the forbidden names).
func _code_only(src: String) -> String:
	var out: Array[String] = []
	for raw in src.split("\n"):
		if String(raw).strip_edges().begins_with("#"):
			continue
		out.append(String(raw))
	return "\n".join(out)

func _make_probe() -> Dictionary:
	var obs := {"scene": "", "legacy_slot": -1, "refreshed": false, "confirm": false, "reset_time": false, "logs": []}
	var probe := RouterProbe.new()
	probe.setup({
		"change_scene": func(p: String): obs["scene"] = p,
		"legacy_continue": func(s: int): obs["legacy_slot"] = s,
		"log": func(t: String): obs["logs"].append(t),
		"refresh_menu": func(): obs["refreshed"] = true,
		"save_slot_path": func(slot: int) -> String: return "user://__p4_03_nonexistent_%d.json" % slot,
		"show_new_game_confirmation": func(): obs["confirm"] = true,
		"reset_time": func(): obs["reset_time"] = true,
		"demo_progress_paths": [],
		"save_slots": 3,
	})
	return {"probe": probe, "obs": obs}

func _run_all() -> void:
	_test_priority_full_save()
	_test_priority_training()
	_test_priority_legacy()
	_test_priority_none()
	_test_new_game_paths()
	_test_read_only()
	_test_static_boundaries()

## A. Full Save has top priority (even with training + legacy present).
func _test_priority_full_save() -> void:
	var h := _make_probe()
	var probe: RouterProbe = h["probe"]
	var obs: Dictionary = h["obs"]
	probe.fake_full = true
	probe.fake_training = true
	probe.fake_slot = 1
	probe.continue_mission()
	# Full Save branch taken: it does NOT fall through to training change_scene or legacy.
	# (With no real full_save.json, restore fails and refresh fires -- still the Full Save branch.)
	_ok("A: Full Save priority -> legacy NOT taken", int(obs["legacy_slot"]) == -1)
	_ok("A: Full Save priority -> training scene NOT taken", not String(obs["scene"]).contains("training") and not String(obs["scene"]).contains("Training"))

## B. Training is next when no Full Save.
func _test_priority_training() -> void:
	var h := _make_probe()
	var probe: RouterProbe = h["probe"]
	var obs: Dictionary = h["obs"]
	probe.fake_full = false
	probe.fake_training = true
	probe.fake_slot = 1
	probe.continue_mission()
	_ok("B: Training branch changes scene (not empty)", String(obs["scene"]) != "")
	_ok("B: Training branch does NOT use legacy fallback", int(obs["legacy_slot"]) == -1)

## C. Legacy sandbox slot only when no Full Save and no training/app.
func _test_priority_legacy() -> void:
	var h := _make_probe()
	var probe: RouterProbe = h["probe"]
	var obs: Dictionary = h["obs"]
	probe.fake_full = false
	probe.fake_training = false
	probe.fake_app = false
	probe.fake_slot = 2
	probe.continue_mission()
	_ok("C: legacy fallback invoked with the latest slot (2)", int(obs["legacy_slot"]) == 2)
	_ok("C: legacy fallback did not change scene", String(obs["scene"]) == "")

## D. No progress -> notice + refresh, no restore/continue.
func _test_priority_none() -> void:
	var h := _make_probe()
	var probe: RouterProbe = h["probe"]
	var obs: Dictionary = h["obs"]
	probe.fake_full = false
	probe.fake_training = false
	probe.fake_app = false
	probe.fake_slot = 0
	probe.continue_mission()
	_ok("D: no-progress -> menu refreshed", bool(obs["refreshed"]))
	_ok("D: no-progress -> no scene change, no legacy", String(obs["scene"]) == "" and int(obs["legacy_slot"]) == -1)
	_ok("D: no-progress -> logged a notice", (obs["logs"] as Array).size() > 0)

## F. Formal new game: no demo -> ApplicationStartScene; demo present -> confirmation dialog.
func _test_new_game_paths() -> void:
	var h1 := _make_probe()
	var probe1: RouterProbe = h1["probe"]
	var obs1: Dictionary = h1["obs"]
	probe1.fake_full = false
	probe1.fake_training = false
	probe1.fake_app = false
	probe1.fake_slot = 0
	probe1.start_application_flow()
	_ok("F: clean new game routes to ApplicationStartScene", String(obs1["scene"]) == APP_SCENE)
	_ok("F: clean new game did NOT enter sandbox/legacy", int(obs1["legacy_slot"]) == -1)
	_ok("F: clean new game reset the formal clock", bool(obs1["reset_time"]))
	_ok("F: clean new game did NOT show new-game confirmation", not bool(obs1["confirm"]))

	var h2 := _make_probe()
	var probe2: RouterProbe = h2["probe"]
	var obs2: Dictionary = h2["obs"]
	probe2.fake_full = true  # has continue -> has demo progress
	probe2.start_application_flow()
	_ok("F: existing progress -> shows new-game confirmation", bool(obs2["confirm"]))
	_ok("F: existing progress -> does NOT immediately change scene", String(obs2["scene"]) == "")

## E. Read-only predicates never call the restoring load_progress path (static + live check).
func _test_read_only() -> void:
	var router_src := _read_text("res://scripts/controllers/formal_flow_router.gd")
	var router_code := _code_only(router_src)
	_ok("E: router uses read_progress() (no side effects)", router_code.contains("TrainingManagerScript.read_progress()"))
	_ok("E: router never calls load_progress()", not router_code.contains("load_progress("))
	_ok("E: router never calls private _read_progress_data()", not router_code.contains("_read_progress_data("))
	# has_continue_mission is read-only: exercising it must not throw / must return a bool.
	var h := _make_probe()
	var probe: RouterProbe = h["probe"]
	probe.fake_full = true
	_ok("E: has_continue_mission returns true when full save present", probe.has_continue_mission() == true)
	probe.fake_full = false
	probe.fake_training = false
	probe.fake_app = false
	probe.fake_slot = 0
	_ok("E: has_continue_mission returns false when nothing present", probe.has_continue_mission() == false)

## G. main.gd delegates; routing implementation + Full Save call live in the router.
func _test_static_boundaries() -> void:
	var main_src := _read_text("res://scripts/main.gd")
	var router_src := _read_text("res://scripts/controllers/formal_flow_router.gd")
	_ok("G: main.gd creates FormalFlowRouter", main_src.contains("FormalFlowRouterScript.new()"))
	_ok("G: routing decision (continue_mission) moved to router", router_src.contains("func continue_mission(") and not main_src.contains("func _continue_mission("))
	_ok("G: new-game entry moved to router", router_src.contains("func start_application_flow(") and not main_src.contains("func _start_application_flow("))
	_ok("G: Full Save restore call lives in the router, not main.gd", router_src.contains("FullSaveOrchestratorScript.restore_full_save()") and not main_src.contains("FullSaveOrchestratorScript.restore_full_save()"))
	_ok("G: priority order preserved in router source (full save -> training -> legacy)", _priority_order_ok(router_src))
	_ok("G: FormalFlowRouter is not an autoload (main creates it as a plain object)", root.get_node_or_null("FormalFlowRouter") == null)
	# Full Save schema / Training API untouched: router only calls existing public statics.
	_ok("G: router does not touch Full Save schema (no schema_version writes)", not router_src.contains("schema_version"))

func _priority_order_ok(src: String) -> bool:
	var i_full := src.find("full_save_exists()")
	var i_train := src.find("training_has_progress(progress)")
	var i_legacy := src.find("latest_save_slot()")
	# within continue_mission the full-save check precedes training precedes legacy fallback
	return i_full != -1 and i_train != -1 and i_legacy != -1 and i_full < i_train and i_train < i_legacy
