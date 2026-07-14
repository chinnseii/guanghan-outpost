extends SceneTree

## P6-02 characterization: pure mapping only. It preloads the UI script but never
## instantiates the scene, so it does not call _show_step() or _save_profile().
const ApplicationFlowSceneScript := preload("res://scripts/application/application_flow_scene.gd")
const STEPS := ["identity", "education", "appearance", "review"]

var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_single_active_mapping()
	_test_forward_navigation_mapping()
	_test_back_navigation_mapping()
	if _failures.is_empty():
		print("P6-02 application step active-state characterization: PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

func _test_single_active_mapping() -> void:
	for current_step in STEPS:
		var active: Array[bool] = []
		for candidate_step in STEPS:
			active.append(ApplicationFlowSceneScript.is_step_active(current_step, candidate_step))
		_ok("%s maps to exactly one active step" % current_step, active.count(true) == 1)
		_ok("%s maps to its matching navigation item" % current_step, active[STEPS.find(current_step)])

func _test_forward_navigation_mapping() -> void:
	for index in range(STEPS.size()):
		var current_step: String = STEPS[index]
		_ok("forward step %d activates only itself" % (index + 1), _active_index(current_step) == index)

func _test_back_navigation_mapping() -> void:
	for index in range(STEPS.size() - 1, -1, -1):
		var current_step: String = STEPS[index]
		_ok("backward step %d restores only itself" % (index + 1), _active_index(current_step) == index)

func _active_index(current_step: String) -> int:
	for index in range(STEPS.size()):
		if ApplicationFlowSceneScript.is_step_active(current_step, STEPS[index]):
			return index
	return -1

func _ok(label: String, condition: bool) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)
