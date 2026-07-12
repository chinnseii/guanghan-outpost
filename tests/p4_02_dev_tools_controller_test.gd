extends SceneTree

## P4-02 focused verification (headless). Run with:
##   godot --headless --path . --script res://tests/p4_02_dev_tools_controller_test.gd
## Exit 0 = pass. Exercises exactly one save-writing debug action (Power energy) and restores
## the affected manager's file to its original bytes, so real saves are unchanged overall.

const DevToolsControllerScript := preload("res://scripts/controllers/dev_tools_controller.gd")

class HostStub extends Node:
	var logs: Array = []
	func add_log(text: String) -> void:
		logs.append(text)
	func _refresh_main_menu() -> void:
		pass

var _done := false
var _failures: Array[String] = []
var _checks := 0

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	_run_all()
	var passed := _checks - _failures.size()
	print("\n[P4-02] checks=%d passed=%d failed=%d" % [_checks, passed, _failures.size()])
	for failure in _failures:
		print("  FAIL: %s" % failure)
	if _failures.is_empty():
		print("[P4-02] ALL PASS")
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

func _count_buttons(node: Node) -> int:
	var count := 0
	if node is Button:
		count += 1
	for child in node.get_children():
		count += _count_buttons(child)
	return count

func _find_button_with_text(node: Node, needle: String) -> bool:
	if node is Button and String((node as Button).text).contains(needle):
		return true
	for child in node.get_children():
		if _find_button_with_text(child, needle):
			return true
	return false

func _run_all() -> void:
	_test_instantiation_and_menu()
	_test_sample_debug_behavior()
	_test_main_static_boundary()

## A + B. Controller instantiates (non-autoload), builds the dev menu, toggle works.
func _test_instantiation_and_menu() -> void:
	_ok("DevToolsController is NOT a formal autoload (/root/DevToolsController absent)", root.get_node_or_null("DevToolsController") == null)

	var host := HostStub.new()
	host.name = "HostStub"
	root.add_child(host)
	var parent := Control.new()
	parent.name = "DevMenuParent"
	root.add_child(parent)

	var dev = DevToolsControllerScript.new()
	root.add_child(dev)
	_ok("controller instantiates without autoload registration", dev != null)
	dev.call("setup", host, parent)
	dev.call("build_menu")

	var panel := parent.get_node_or_null("DevMenu")
	_ok("build_menu creates the DevMenu panel under the injected parent", panel != null)
	if panel != null:
		var button_count := _count_buttons(panel)
		_ok("dev menu has the full button set (>100 buttons): %d" % button_count, button_count > 100)
		# Toggle behaviour.
		dev.call("set_menu_visible", true)
		_ok("set_menu_visible(true) shows panel", panel.visible == true)
		dev.call("toggle_menu")
		_ok("toggle_menu hides panel", panel.visible == false)
		# Sample button types exist (scene jump + read-only status), by label.
		_ok("dev scene-jump button present (Arrival Cinematic)", _find_button_with_text(panel, "Arrival Cinematic"))
		_ok("dev read-only status button present (Supply Show Status)", _find_button_with_text(panel, "Supply Debug: Show Status"))
		_ok("dev legacy-sandbox button present (Start Survival Sandbox)", _find_button_with_text(panel, "Start Survival Sandbox"))

	# Controller owns no canonical game state.
	_ok("controller does not own canonical save state (no current_energy field)", not (dev.get("current_energy") != null))

	dev.free()
	parent.free()
	host.free()

## C. A sampled formal-autoload debug action still works (Power energy), then restore file.
func _test_sample_debug_behavior() -> void:
	var power := root.get_node_or_null("PowerSystemManager")
	if power == null:
		_ok("PowerSystemManager present for sample debug", false)
		return
	var snapshot: Dictionary = power.call("serialize")
	var energy_before := float(power.get("current_energy"))

	var host := HostStub.new()
	root.add_child(host)
	var dev = DevToolsControllerScript.new()
	root.add_child(dev)
	dev.call("setup", host, Control.new())
	# Directly invoke the moved debug action (as the dev button would).
	dev.call("_debug_adjust_power_energy", -20.0)
	var energy_after := float(power.get("current_energy"))
	_ok("Power debug action changed live PowerSystemManager energy (%.1f -> %.1f)" % [energy_before, energy_after], abs(energy_after - energy_before) > 0.001 or energy_before <= 0.0)
	_ok("debug action routed a log to the host", host.logs.size() > 0)

	# Restore the manager (and its file) to original bytes.
	power.call("deserialize", snapshot)
	if power.has_method("save_state"):
		power.call("save_state")
	_ok("PowerSystemManager restored to snapshot energy", abs(float(power.get("current_energy")) - energy_before) < 0.001)

	dev.free()
	host.free()

## D + E. main.gd no longer owns the debug bodies; formal routing/save untouched.
func _test_main_static_boundary() -> void:
	var main_src := _code_only(_read_text("res://scripts/main.gd"))
	# Only the shared _debug_reset_time may remain in main; all other _debug_* moved.
	var debug_defs := 0
	for line in main_src.split("\n"):
		if String(line).begins_with("func _debug_"):
			debug_defs += 1
	_ok("main.gd retains only the shared _debug_reset_time (1 _debug_* def): %d" % debug_defs, debug_defs == 1)
	_ok("main.gd keeps shared _debug_reset_time", main_src.contains("func _debug_reset_time("))
	_ok("main.gd creates DevToolsController", main_src.contains("DevToolsControllerScript.new()"))
	_ok("main.gd dev builder funcs removed", not main_src.contains("func _setup_dev_menu(") and not main_src.contains("func _make_dev_button("))
	# Formal routing was later extracted to FormalFlowRouter in P4-03; main delegates to it.
	# (These assertions are kept but migrated to reflect the current boundary.)
	var router_src := _code_only(_read_text("res://scripts/controllers/formal_flow_router.gd"))
	_ok("formal continue routing lives in FormalFlowRouter (P4-03)", router_src.contains("func continue_mission("))
	_ok("main.gd creates the FormalFlowRouter", main_src.contains("FormalFlowRouterScript.new()"))
	_ok("Full Save restore call lives in the router, not main.gd", router_src.contains("FullSaveOrchestratorScript.restore_full_save()") and not main_src.contains("FullSaveOrchestratorScript.restore_full_save()"))
	_ok("legacy sandbox root _start_new_game stays in main", main_src.contains("func _start_new_game("))
	_ok("sandbox slot save stays in main", main_src.contains("func _save_game(") and main_src.contains("func _load_game("))
