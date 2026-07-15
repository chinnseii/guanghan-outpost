extends SceneTree

const ApplicationFlowSceneScript := preload("res://scripts/application/application_flow_scene.gd")

var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_case("GH-2068-0421-A7F392", "GHC-A7F392")
	_case("gh 2068 a7f392", "GHC-A7F392")
	_case("Gh-1a2B3c", "GHC-1A2B3C")
	_case("ABC", "GHC-ABC")
	_case("", "待生成")
	_case("---  ", "待生成")
	_state("", "", 0, 0, "待完成", false)
	_state("甲", "", 0, 1, "待完成", false)
	_state("甲", "男", 0, 2, "待完成", false)
	_state("甲", "男", 2000, 3, "已完成", true)
	_state("   ", "男", 2000, 2, "待完成", false)
	_state("甲", "未知", 2000, 2, "需检查", false)
	_state("甲", "女", 1900, 2, "需检查", false)
	var source := "GH-2068-0421-A7F392"
	_ok("deterministic", ApplicationFlowSceneScript.derive_candidate_display_id(source) == ApplicationFlowSceneScript.derive_candidate_display_id(source))
	_ok("input is unchanged", source == "GH-2068-0421-A7F392")
	if _failures.is_empty():
		print("AUI-03-01 candidate display id: PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

func _case(input: String, expected: String) -> void:
	_ok("%s derives correctly" % input, ApplicationFlowSceneScript.derive_candidate_display_id(input) == expected)

func _state(name: String, gender: String, birth: int, completed: int, validation: String, next_enabled: bool) -> void:
	var state := ApplicationFlowSceneScript.basic_information_state(name, gender, birth)
	_ok("completion state", int(state["completed"]) == completed)
	_ok("validation state", String(state["validation"]) == validation)
	_ok("next enabled state", bool(state["valid"]) == next_enabled)

func _ok(label: String, condition: bool) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)
