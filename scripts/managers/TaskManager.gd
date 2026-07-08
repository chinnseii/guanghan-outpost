extends Node
class_name GuanghanTaskManager

## Unified task / objective view. A single query entry point for "what is the
## current objective" and "how much is done" across categories, WITHOUT owning
## a second copy of the truth: training task states are DERIVED from
## TrainingManager's progress flags at query time, so there is no dual source
## of truth to drift. (Mission / supply categories get their own authoritative
## sources in phase 2.) Like PlayerStateManager, this is a read/registry layer,
## not a rules engine -- it does not drive the step engines or advance flows.

signal tasks_changed

const TaskDatabaseScript := preload("res://scripts/data/TaskDatabase.gd")
const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")

const STATE_LOCKED := "locked"
const STATE_ACTIVE := "active"
const STATE_COMPLETED := "completed"

## Current objective line for a category: the title of the first (by order)
## not-yet-completed task, or the category's "all done" text.
func get_current_objective(category: String = "training") -> String:
	if category == "supply":
		return _supply_objective()
	for task_id in TaskDatabaseScript.tasks_in_category(category):
		if not _is_task_completed(TaskDatabaseScript.get_task(task_id)):
			return TaskDatabaseScript.get_title(task_id)
	return TaskDatabaseScript.all_complete_text(category)

## Task id of the first not-completed task in a category ("" if all done).
func get_active_task_id(category: String = "training") -> String:
	if category == "supply":
		for entry in _supply_tasks():
			if String(entry.get("state", "")) != STATE_COMPLETED:
				return String(entry.get("task_id", ""))
		return ""
	for task_id in TaskDatabaseScript.tasks_in_category(category):
		if not _is_task_completed(TaskDatabaseScript.get_task(task_id)):
			return task_id
	return ""

func get_task_state(task_id: String) -> String:
	var task := TaskDatabaseScript.get_task(task_id)
	if task.is_empty():
		return STATE_LOCKED
	if _is_task_completed(task):
		return STATE_COMPLETED
	if _prerequisites_met(task):
		return STATE_ACTIVE
	return STATE_LOCKED

func is_completed(task_id: String) -> bool:
	return get_task_state(task_id) == STATE_COMPLETED

## {completed, total, remaining} for a category.
func get_progress(category: String) -> Dictionary:
	if category == "supply":
		var supply_tasks := _supply_tasks()
		var supply_done := 0
		for entry in supply_tasks:
			if String(entry.get("state", "")) == STATE_COMPLETED:
				supply_done += 1
		return {"completed": supply_done, "total": supply_tasks.size(), "remaining": supply_tasks.size() - supply_done}
	var ids := TaskDatabaseScript.tasks_in_category(category)
	var completed := 0
	for task_id in ids:
		if _is_task_completed(TaskDatabaseScript.get_task(task_id)):
			completed += 1
	return {"completed": completed, "total": ids.size(), "remaining": ids.size() - completed}

## Full list for a task panel: [{task_id, title, state, order}] in order.
func get_all_tasks(category: String) -> Array:
	if category == "supply":
		return _supply_tasks()
	var result: Array = []
	for task_id in TaskDatabaseScript.tasks_in_category(category):
		var task := TaskDatabaseScript.get_task(task_id)
		result.append({
			"task_id": task_id,
			"title": String(task.get("title", "")),
			"state": get_task_state(task_id),
			"order": int(task.get("order", 0)),
		})
	return result

## Flows that change the underlying progress can call this after updating the
## authoritative source so a task panel / HUD subscribed to tasks_changed can
## refresh instead of polling. States are still re-derived on the next query.
func notify_progress_changed() -> void:
	tasks_changed.emit()

func debug_values_text() -> String:
	var lines: Array[String] = ["任务状态（训练）："]
	for entry in get_all_tasks("training"):
		lines.append("- [%s] %s" % [String(entry.get("state", "")), String(entry.get("title", ""))])
	var progress := get_progress("training")
	lines.append("进度：%d / %d" % [int(progress.get("completed", 0)), int(progress.get("total", 0))])
	return "\n".join(lines)

func _is_task_completed(task: Dictionary) -> bool:
	if task.is_empty():
		return false
	var source := _progress_for_category(String(task.get("category", "")))
	if source.is_empty():
		return false
	var flag := String(task.get("completion_flag", ""))
	if not flag.is_empty() and bool(source.get(flag, false)):
		return true
	# A task may be considered done when ANY of several flags is set (e.g. the
	# mission's Day02 is done on either Day02Completed or Day02ReportSent).
	for any_flag in task.get("completion_flags_any", []):
		if bool(source.get(String(any_flag), false)):
			return true
	return false

func _prerequisites_met(task: Dictionary) -> bool:
	for prerequisite in task.get("prerequisites", []):
		if not _is_task_completed(TaskDatabaseScript.get_task(String(prerequisite))):
			return false
	return true

## The authoritative progress dict a category's completion is derived from.
func _progress_for_category(category: String) -> Dictionary:
	match category:
		"training":
			return _training_progress()
		"mission":
			return _mission_progress()
	return {}

func _training_progress() -> Dictionary:
	return TrainingManagerScript._read_progress_data()

func _mission_progress() -> Dictionary:
	var path := String(TrainingManagerScript.SPRINT06_SAVE_PATH)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary

## -- Supply: a single DYNAMIC task derived from SupplyManager's current
## supply order (not a static catalogue entry, since it recurs each cycle) --

func _supply_manager() -> Node:
	return get_node_or_null("/root/SupplyManager")

func _supply_objective() -> String:
	var supply := _supply_manager()
	if supply == null or not supply.has_method("get_current_supply"):
		return ""
	var current: Dictionary = supply.call("get_current_supply")
	if current.is_empty():
		return "暂无补给班次。"
	match String(current.get("status", "")):
		"draft":
			return "提交下一班地球补给清单。"
		"confirmed":
			return "补给清单已提交，等待发射窗口。"
		"locked":
			return "补给已锁定，等待到货。"
		"delivered":
			return "补给已送达。"
		"missed":
			return "本班补给已错过，等待下一班。"
	return ""

func _supply_tasks() -> Array:
	var supply := _supply_manager()
	if supply == null or not supply.has_method("get_current_supply"):
		return []
	var current: Dictionary = supply.call("get_current_supply")
	if current.is_empty():
		return []
	var status := String(current.get("status", ""))
	var state := STATE_ACTIVE
	if status == "delivered":
		state = STATE_COMPLETED
	elif status == "missed":
		state = "failed"
	return [{
		"task_id": "supply_current",
		"title": _supply_objective(),
		"state": state,
		"order": 0,
	}]
