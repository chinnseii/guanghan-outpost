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
	for task_id in TaskDatabaseScript.tasks_in_category(category):
		if not _is_task_completed(TaskDatabaseScript.get_task(task_id)):
			return TaskDatabaseScript.get_title(task_id)
	return TaskDatabaseScript.all_complete_text(category)

## Task id of the first not-completed task in a category ("" if all done).
func get_active_task_id(category: String = "training") -> String:
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
	var ids := TaskDatabaseScript.tasks_in_category(category)
	var completed := 0
	for task_id in ids:
		if _is_task_completed(TaskDatabaseScript.get_task(task_id)):
			completed += 1
	return {"completed": completed, "total": ids.size(), "remaining": ids.size() - completed}

## Full list for a task panel: [{task_id, title, state, order}] in order.
func get_all_tasks(category: String) -> Array:
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
	var category := String(task.get("category", ""))
	var flag := String(task.get("completion_flag", ""))
	if category == "training" and not flag.is_empty():
		return bool(_training_progress().get(flag, false))
	# Mission / supply completion sources are wired in phase 2.
	return false

func _prerequisites_met(task: Dictionary) -> bool:
	for prerequisite in task.get("prerequisites", []):
		if not _is_task_completed(TaskDatabaseScript.get_task(String(prerequisite))):
			return false
	return true

func _training_progress() -> Dictionary:
	return TrainingManagerScript._read_progress_data()
