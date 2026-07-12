class_name Sprint06ScheduleEvaluator
extends RefCounted

## Sprint06ScheduleEvaluator (P4-06B): stateless, side-effect-free schedule/daily-check predicates
## and schedule text generation extracted from sprint06_base_scene.gd (per the P4-06A audit,
## conclusion A). Pure functions over (day, state): no member state, no host/scene, no scene-tree
## or /root access, no Manager calls, no file I/O, no signals, no await. It NEVER mutates the
## passed-in `state` Dictionary. All state mutation, async equipment/finish sequences, save/restore,
## transitions, and input locks stay in the scene. Logic here mirrors the previous scene methods
## exactly (same day->key table, same iteration order, same strings/punctuation/newlines).

func current_day(state: Dictionary) -> int:
	return int(state.get("CurrentDay", state.get("DayNumber", 2)))

func required_daily_keys(day: int) -> Array[String]:
	match day:
		3:
			return ["DailyConsoleChecked", "DailyPowerChecked", "DailyLifeSupportChecked", "DailyPlantChecked"]
		4:
			return ["DailyConsoleChecked", "DailyWaterChecked", "DailySpecialChecked", "DailyPlantChecked"]
		5:
			return ["DailyConsoleChecked", "DailyPowerChecked", "DailySpecialChecked", "DailyPlantChecked"]
		6:
			return ["DailyConsoleChecked", "DailySpecialChecked", "DailyPlantChecked", "DailyRecordUpdated"]
		7:
			return ["DailyConsoleChecked", "DailyPowerChecked", "DailyLifeSupportChecked", "DailyPlantChecked"]
	return ["DailyConsoleChecked"]

func daily_checks_complete(day: int, state: Dictionary) -> bool:
	for key: String in required_daily_keys(day):
		if not bool(state.get(key, false)):
			return false
	return true

func day02_inspections_complete(state: Dictionary) -> bool:
	return bool(state.get("Day02PowerChecked", false)) \
		and bool(state.get("Day02LifeSupportChecked", false)) \
		and bool(state.get("Day02WaterChecked", false)) \
		and bool(state.get("Day02LastPlantChecked", false))

func task_line(label: String, key: String, state: Dictionary) -> String:
	return "✓ %s" % label if bool(state.get(key, false)) else "□ %s" % label

func day_label(day: int) -> String:
	return "Day %02d" % day

func daily_report_label(day: int) -> String:
	return "第一周驻留报告" if day == 7 else "%s 对地报告" % day_label(day)

func daily_checklist_text(day: int, state: Dictionary) -> String:
	var text := task_line("查看中央控制台", "DailyConsoleChecked", state)
	match day:
		3:
			text += "\n" + task_line("检查供电面板", "DailyPowerChecked", state)
			text += "\n" + task_line("检查生命支持", "DailyLifeSupportChecked", state)
			text += "\n" + task_line("检查最后一株植物", "DailyPlantChecked", state)
		4:
			text += "\n" + task_line("检查水循环状态", "DailyWaterChecked", state)
			text += "\n" + task_line("检查温室供水", "DailySpecialChecked", state)
			text += "\n" + task_line("检查最后一株植物", "DailyPlantChecked", state)
		5:
			text += "\n" + task_line("检查供电面板", "DailyPowerChecked", state)
			text += "\n" + task_line("检查当前负载", "DailySpecialChecked", state)
			text += "\n" + task_line("检查最后一株植物", "DailyPlantChecked", state)
		6:
			text += "\n" + task_line("进入旧温室", "DailySpecialChecked", state)
			text += "\n" + task_line("近距观察最后一株植物", "DailyPlantChecked", state)
			text += "\n" + task_line("更新植物状态记录", "DailyRecordUpdated", state)
		7:
			text += "\n" + task_line("复核供电状态", "DailyPowerChecked", state)
			text += "\n" + task_line("复核生命支持状态", "DailyLifeSupportChecked", state)
			text += "\n" + task_line("复核温室生命信号", "DailyPlantChecked", state)
	text += "\n" + task_line("发送%s" % daily_report_label(day), "DailyReportSent", state)
	return text
