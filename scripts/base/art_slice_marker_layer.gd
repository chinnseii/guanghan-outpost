extends Node2D
class_name ArtSliceMarkerLayer

var source_scene: Node

func _draw() -> void:
	if source_scene == null:
		return
	var rect := Rect2()
	if source_scene.has_method("_objective_highlight_rect"):
		rect = source_scene.call("_objective_highlight_rect")
	if rect.size != Vector2.ZERO:
		draw_rect(rect.grow(8), Color("#f0c766", 0.10), true)
		draw_rect(rect.grow(8), Color("#f0c766", 0.75), false, 2)
		draw_circle(rect.position + Vector2(12, 12), 5, Color("#f0c766", 0.95))
	_draw_completed_checks()

func _draw_completed_checks() -> void:
	var targets: Dictionary = source_scene.get("interior_targets")
	var state: Dictionary = source_scene.get("state")
	var completed := _completed_flags_for_current_flow()
	for key in completed.keys():
		if not targets.has(key):
			continue
		var done := false
		for flag: String in completed[key]:
			done = done or bool(state.get(flag, false))
		if not done:
			continue
		var rect: Rect2 = targets[key]
		var p := rect.position + Vector2(rect.size.x - 14, 12)
		draw_circle(p, 8, Color("#6fa765", 0.85))
		draw_line(p + Vector2(-4, 0), p + Vector2(-1, 4), Color("#0e1712"), 2)
		draw_line(p + Vector2(-1, 4), p + Vector2(5, -5), Color("#0e1712"), 2)

func _completed_flags_for_current_flow() -> Dictionary:
	if source_scene.has_method("_is_week_routine_active") and bool(source_scene.call("_is_week_routine_active")):
		return {
			"console": ["DailyConsoleChecked"],
			"power_panel": ["DailyPowerChecked"],
			"power_console": ["DailySpecialChecked"],
			"life_console": ["DailyLifeSupportChecked"],
			"greenhouse_door": ["DailyPlantChecked"],
			"report_terminal": ["DailyReportSent"],
		}
	if source_scene.has_method("_is_day02_active") and bool(source_scene.call("_is_day02_active")):
		return {
			"console": ["Day02ConsoleChecked"],
			"power_panel": ["Day02PowerChecked"],
			"life_console": ["Day02LifeSupportChecked"],
			"greenhouse_door": ["Day02LastPlantChecked"],
			"report_terminal": ["Day02ReportSent"],
		}
	return {
		"console": ["CentralConsoleChecked"],
		"power_panel": ["PowerPanelChecked"],
		"life_console": ["LifeSupportConsoleChecked"],
		"greenhouse_door": ["GreenhouseUnlocked"],
	}
