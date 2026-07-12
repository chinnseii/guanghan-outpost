extends SceneTree

## P4-05 focused verification (headless). Run with:
##   godot --headless --path . --script res://tests/p4_05_base_navigation_controller_test.gd
## Exit 0 = pass. Pure-computation test: the controller is stateless and touches no autoload/save,
## so this reads/writes nothing on disk. Does NOT boot a base scene (that would autosave).

const NavScript := preload("res://scripts/controllers/base_navigation_controller.gd")

var _done := false
var _failures: Array[String] = []
var _checks := 0

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	_run_all()
	var passed := _checks - _failures.size()
	print("\n[P4-05] checks=%d passed=%d failed=%d" % [_checks, passed, _failures.size()])
	for failure in _failures:
		print("  FAIL: %s" % failure)
	if _failures.is_empty():
		print("[P4-05] ALL PASS")
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
	_test_terrain()
	_test_is_near()
	_test_compute_target()
	_test_static_boundary()

## B. Terrain mapping preserved.
func _test_terrain() -> void:
	var nav = NavScript.new()
	_ok("controller is not an autoload", root.get_node_or_null("BaseNavigationController") == null)
	_ok("terrain: solar_array -> lunar_flat", String(nav.terrain_type_for("solar_array")) == "lunar_flat")
	_ok("terrain: interior -> indoor", String(nav.terrain_type_for("interior")) == "indoor")
	_ok("terrain: greenhouse -> indoor (default)", String(nav.terrain_type_for("greenhouse")) == "indoor")

## C. Proximity: within the 44px margin -> near; far -> not.
func _test_is_near() -> void:
	var nav = NavScript.new()
	var rect := Rect2(Vector2(100, 100), Vector2(50, 50))
	_ok("is_near: point inside rect", bool(nav.is_near(Vector2(120, 120), rect)))
	_ok("is_near: point within margin", bool(nav.is_near(Vector2(170, 120), rect)))  # 20px past right edge < 44
	_ok("is_near: point far away", not bool(nav.is_near(Vector2(600, 600), rect)))

## A. compute_current_target mirrors the old _update_target exactly.
func _test_compute_target() -> void:
	var nav = NavScript.new()
	var interior := {"console": Rect2(Vector2(100, 100), Vector2(50, 50)), "power_panel": Rect2(Vector2(700, 100), Vector2(50, 50))}
	var greenhouse := {"last_plant": Rect2(Vector2(300, 300), Vector2(40, 40))}

	_ok("interior: near console -> 'console'", String(nav.compute_current_target(Vector2(120, 120), "interior", interior, greenhouse)) == "console")
	_ok("interior: near power_panel -> 'power_panel'", String(nav.compute_current_target(Vector2(720, 120), "interior", interior, greenhouse)) == "power_panel")
	_ok("interior: near nothing -> ''", String(nav.compute_current_target(Vector2(1400, 800), "interior", interior, greenhouse)) == "")
	# First-match-wins (insertion order) when two overlap the player.
	var both := {"a": Rect2(Vector2(100, 100), Vector2(60, 60)), "b": Rect2(Vector2(110, 110), Vector2(60, 60))}
	_ok("interior: first matching key wins (order preserved)", String(nav.compute_current_target(Vector2(130, 130), "interior", both, greenhouse)) == "a")
	# Greenhouse map is used only in greenhouse scenes.
	_ok("greenhouse: near last_plant -> 'last_plant'", String(nav.compute_current_target(Vector2(320, 320), "greenhouse", interior, greenhouse)) == "last_plant")
	_ok("interior scene ignores greenhouse map", String(nav.compute_current_target(Vector2(320, 320), "interior", interior, greenhouse)) == "")
	# Sleep target near (760,570) within 96px, for the *_end scenes only.
	_ok("day_end near sleep spot -> 'sleep'", String(nav.compute_current_target(Vector2(760, 570), "day_end", interior, greenhouse)) == "sleep")
	_ok("day02_end near sleep spot -> 'sleep'", String(nav.compute_current_target(Vector2(800, 600), "day02_end", interior, greenhouse)) == "sleep")
	_ok("week_end far from sleep spot -> ''", String(nav.compute_current_target(Vector2(760, 700), "week_end", interior, greenhouse)) == "")
	_ok("unknown scene kind -> ''", String(nav.compute_current_target(Vector2(760, 570), "solar_array", interior, greenhouse)) == "")

## D + E. Static responsibility boundary: controller is nav-only; scene keeps flow/save.
func _test_static_boundary() -> void:
	var nav := _code_only(_read_text("res://scripts/controllers/base_navigation_controller.gd"))
	var scene := _code_only(_read_text("res://scripts/base/sprint06_base_scene.gd"))
	# Controller owns no gameplay/save/transition responsibility.
	_ok("controller does not call FullSaveOrchestrator", not nav.contains("FullSaveOrchestrator"))
	_ok("controller does not save/load or change scene", not nav.contains("_save_state") and not nav.contains("_load_state") and not nav.contains("change_scene_to_file"))
	_ok("controller does not advance time / write managers", not nav.contains("advance_time") and not nav.contains("adjust_stat"))
	_ok("controller does not hold task/schedule state (no state.get / _daily_)", not nav.contains("state.get(") and not nav.contains("_daily_"))
	_ok("controller does not depend on the HUD presenter", not nav.contains("BaseHudPanelPresenter"))
	# Scene creates the controller and delegates the pure computation.
	_ok("scene creates BaseNavigationController", scene.contains("BaseNavigationController.new()"))
	_ok("scene delegates target computation", scene.contains("_nav.compute_current_target("))
	_ok("scene delegates terrain type", scene.contains("_nav.terrain_type_for("))
	# Flow / transition / save remain in the scene.
	_ok("scene keeps scene-transition helper", scene.contains("func _transition_to("))
	_ok("scene keeps flow-coupled interaction target rect", scene.contains("func _interaction_target_rect("))
	_ok("scene keeps Full Save restore", scene.contains("FullSaveOrchestratorScript.restore_full_save"))
	_ok("scene keeps current_target consumers (interaction flow)", scene.contains("match current_target:"))
	_ok("scene keeps the movement main loop", scene.contains("func _move_player("))
