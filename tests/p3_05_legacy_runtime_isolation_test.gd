extends SceneTree

## P3-05 focused verification (headless). Run with:
##   godot --headless --path . --script res://tests/p3_05_legacy_runtime_isolation_test.gd
## Exit code 0 = all pass, 1 = failure. Does not write or read any real save file: it only
## reads project source text and exercises the two standalone legacy manager scripts in memory.

const LegacyTimeManagerScript := preload("res://scripts/time_manager.gd")
const LegacyGameStateManagerScript := preload("res://scripts/game_state_manager.gd")

var _done := false
var _failures: Array[String] = []
var _checks := 0

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	_run_all()
	var passed := _checks - _failures.size()
	print("\n[P3-05] checks=%d passed=%d failed=%d" % [_checks, passed, _failures.size()])
	for failure in _failures:
		print("  FAIL: %s" % failure)
	if _failures.is_empty():
		print("[P3-05] ALL PASS")
	quit(0 if _failures.is_empty() else 1)
	return true

func _ok(label: String, condition: bool) -> void:
	_checks += 1
	if condition:
		print("  ok: %s" % label)
	else:
		_failures.append(label)

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

## Return source with whole-line comments removed, so absence-checks scan CODE only and are
## not tripped by explanatory comments that legitimately mention isolated names/paths.
func _code_only(src: String) -> String:
	var out: Array[String] = []
	for raw in src.split("\n"):
		if String(raw).strip_edges().begins_with("#"):
			continue
		out.append(String(raw))
	return "\n".join(out)

func _run_all() -> void:
	var main_src := _read_text("res://scripts/main.gd")
	var arrival_src := _read_text("res://scripts/arrival/arrival_landing_scene.gd")
	var orch_src := _read_text("res://scripts/systems/full_save_orchestrator.gd")
	_ok("source files readable", main_src != "" and arrival_src != "" and orch_src != "")

	_test_local_manager_naming(_code_only(main_src), _code_only(arrival_src))
	_test_formal_continue_isolation(_code_only(main_src))
	_test_legacy_save_isolation(_code_only(main_src), _code_only(arrival_src), _code_only(orch_src))
	_test_legacy_runtime_still_works()

## D. Local legacy manager node names are no longer confusable with formal autoloads.
func _test_local_manager_naming(main_src: String, arrival_src: String) -> void:
	# Formal autoload still present and is the formal action-based clock.
	var formal_time := root.get_node_or_null("TimeManager")
	_ok("formal /root/TimeManager autoload present", formal_time != null)
	if formal_time != null:
		_ok("formal TimeManager is action-based (has advance_time)", formal_time.has_method("advance_time"))

	# Sandbox (main.gd): renamed, no bare collision, no name-based lookup.
	_ok("main.gd renames local clock node to SandboxTimeManager", main_src.contains("\"SandboxTimeManager\""))
	_ok("main.gd renames local state node to SandboxGameStateManager", main_src.contains("\"SandboxGameStateManager\""))
	_ok("main.gd no longer names a local node \"TimeManager\"", not main_src.contains("name = \"TimeManager\""))
	_ok("main.gd no longer names a local node \"GameStateManager\"", not main_src.contains("name = \"GameStateManager\""))
	_ok("main.gd never looks up local managers by node name (get_node)", not main_src.contains("get_node(\"TimeManager\"") and not main_src.contains("get_node_or_null(\"TimeManager\""))
	_ok("main.gd never uses $TimeManager / %TimeManager", not main_src.contains("$TimeManager") and not main_src.contains("%TimeManager"))
	_ok("main.gd still accesses the FORMAL autoload via /root/TimeManager", main_src.contains("/root/TimeManager"))

	# Arrival prototype: renamed, no bare collision, no name-based lookup.
	_ok("arrival renames local clock node to ArrivalPrototypeTimeManager", arrival_src.contains("\"ArrivalPrototypeTimeManager\""))
	_ok("arrival renames local state node to ArrivalPrototypeGameStateManager", arrival_src.contains("\"ArrivalPrototypeGameStateManager\""))
	_ok("arrival no longer names a local node \"TimeManager\"", not arrival_src.contains("name = \"TimeManager\""))
	_ok("arrival never looks up managers by node name or /root", not arrival_src.contains("get_node(\"TimeManager\"") and not arrival_src.contains("/root/TimeManager"))

## A. Formal continue routes through Full Save; training through TrainingManager.
func _test_formal_continue_isolation(main_src: String) -> void:
	_ok("formal continue uses FullSaveOrchestrator.restore_full_save()", main_src.contains("FullSaveOrchestratorScript.restore_full_save()"))
	_ok("formal continue scene comes from FullSaveOrchestrator.continue_scene_path()", main_src.contains("FullSaveOrchestratorScript.continue_scene_path()"))
	_ok("training continue uses TrainingManager.continue_scene_path()", main_src.contains("TrainingManagerScript.continue_scene_path()"))
	# Progress inspection uses the read-only API, not the restoring load_progress().
	_ok("has-progress checks use TrainingManager.read_progress() (no side effects)", main_src.contains("TrainingManagerScript.read_progress()"))
	_ok("main.gd does not call TrainingManager.load_progress()", not main_src.contains("TrainingManagerScript.load_progress("))

## C. Legacy save files are a separate namespace and never enter formal Full Save.
func _test_legacy_save_isolation(main_src: String, arrival_src: String, orch_src: String) -> void:
	# Distinct file namespaces.
	_ok("sandbox uses slot_N.json namespace", main_src.contains("slot_%d.json"))
	_ok("arrival uses arrival_prototype_save.json namespace", arrival_src.contains("arrival_prototype_save.json"))
	_ok("Full Save orchestrator owns full_save.json", orch_src.contains("full_save.json"))
	# Full Save never reads legacy sandbox/arrival files.
	_ok("FullSaveOrchestrator does not read arrival_prototype_save", not orch_src.contains("arrival_prototype_save"))
	_ok("FullSaveOrchestrator does not read sandbox slot_ files", not orch_src.contains("slot_"))
	# Legacy sprint06 is read-only best-effort, rejected by formal restore.
	_ok("formal restore rejects legacy sprint06 sources", orch_src.contains("legacy_source") and orch_src.contains("read-only"))
	# Legacy save writers never write full_save.json.
	_ok("sandbox save/load never writes full_save.json", not main_src.contains("full_save.json\", FileAccess.WRITE") and not main_src.contains("\"user://saves/full_save.json\", FileAccess.WRITE"))
	_ok("arrival save never writes full_save.json", not arrival_src.contains("full_save.json"))

## E. Legacy local managers remain runnable in isolation.
func _test_legacy_runtime_still_works() -> void:
	var clock: Node = LegacyTimeManagerScript.new()
	clock.call("set_time", 2, 10, 30)
	clock.call("advance_minutes", 90)
	var h := int(clock.get("hour"))
	var m := int(clock.get("minute"))
	var d := int(clock.get("day"))
	_ok("legacy sandbox clock advances (10:30 +90m -> 12:00, day 2)", h == 12 and m == 0 and d == 2)
	_ok("legacy sandbox clock_text works", String(clock.call("clock_text")) == "D02 12:00")
	clock.free()

	var state: Node = LegacyGameStateManagerScript.new()
	state.call("change_state", LegacyGameStateManagerScript.MOON_SURFACE)
	_ok("legacy sandbox game state transitions", bool(state.call("is_state", LegacyGameStateManagerScript.MOON_SURFACE)))
	state.free()

	# Legacy scene scripts still parse/load.
	_ok("legacy main.gd script loads", load("res://scripts/main.gd") != null)
	_ok("legacy arrival scene script loads", load("res://scripts/arrival/arrival_landing_scene.gd") != null)
