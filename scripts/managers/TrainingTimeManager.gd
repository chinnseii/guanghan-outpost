extends Node

## Training-only time budget for the ground candidate selection sequence.
## Deliberately isolated from the real TimeManager: training happens on
## Earth before Day 01 06:40, so it must never advance
## TimeManager.total_minutes, the lunar day/night cycle, BaseStatusManager,
## PlantGrowthManager, or any official base resource. See
## docs/handoff/SYSTEMS_REFERENCE_FOR_DESIGN.md for the full boundary list.

const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")
const SAVE_PATH := "user://saves/training_time_state.json"

var archive_limit_minutes: int = 480
var elapsed_minutes: int = 0
var remaining_minutes: int = 480
var training_time_active: bool = false
var training_time_paused: bool = false
var time_log: Array = []

func _ready() -> void:
	load_state()

## -- Lifecycle

func start_training_time(limit_minutes: int = 480) -> void:
	archive_limit_minutes = limit_minutes
	elapsed_minutes = 0
	remaining_minutes = archive_limit_minutes
	training_time_active = true
	training_time_paused = false
	time_log.clear()
	_save_state()

func stop_training_time() -> void:
	training_time_active = false
	_save_state()

func pause_training_time() -> void:
	training_time_paused = true
	_save_state()

func resume_training_time() -> void:
	training_time_paused = false
	_save_state()

## -- Advancing time

func advance_training_time(minutes: int, reason: String = "") -> void:
	if not training_time_active:
		return
	if training_time_paused:
		return
	if minutes <= 0:
		return
	elapsed_minutes += minutes
	remaining_minutes = max(archive_limit_minutes - elapsed_minutes, 0)
	time_log.append({
		"minutes": minutes,
		"reason": reason,
		"elapsed_after": elapsed_minutes,
		"remaining_after": remaining_minutes,
	})
	_save_state()
	check_training_timeout()

## Fails training only when the archive time limit has fully run out AND
## the required modules aren't all done yet -- if the required modules are
## already complete when time hits zero, this is a pass/settlement moment,
## not a failure, so it silently does nothing.
func check_training_timeout() -> void:
	if remaining_minutes > 0:
		return
	if TrainingManagerScript.are_required_modules_completed():
		return
	TrainingManagerScript.fail_training("archive_time_expired")

## -- Display

func get_elapsed_minutes() -> int:
	return elapsed_minutes

func get_remaining_minutes() -> int:
	return remaining_minutes

func get_archive_limit_minutes() -> int:
	return archive_limit_minutes

func get_remaining_time_text() -> String:
	var hours: int = remaining_minutes / 60
	var minutes: int = remaining_minutes % 60
	return "%02d:%02d" % [hours, minutes]

func get_time_log() -> Array:
	return time_log

## -- Debug helpers

func debug_values_text() -> String:
	var lines: Array[String] = [
		"TrainingTimeManager: active=%s paused=%s" % [training_time_active, training_time_paused],
		"archive_limit=%d elapsed=%d remaining=%d (%s)" % [
			archive_limit_minutes, elapsed_minutes, remaining_minutes, get_remaining_time_text(),
		],
		"time_log entries=%d" % time_log.size(),
	]
	return "\n".join(lines)

func debug_advance(minutes: int, reason: String = "debug_advance") -> void:
	advance_training_time(minutes, reason)

func debug_force_timeout() -> void:
	advance_training_time(max(remaining_minutes, 1), "debug_force_timeout")

## -- Persistence (optional per spec -- training doesn't have to survive a
## restart mid-session, but every other manager in this project follows the
## same load/save pattern, so this one does too for consistency).

func serialize() -> Dictionary:
	return {
		"archive_limit_minutes": archive_limit_minutes,
		"elapsed_minutes": elapsed_minutes,
		"remaining_minutes": remaining_minutes,
		"training_time_active": training_time_active,
		"training_time_paused": training_time_paused,
		"time_log": time_log.duplicate(true),
	}

func deserialize(data: Dictionary) -> void:
	archive_limit_minutes = int(data.get("archive_limit_minutes", archive_limit_minutes))
	elapsed_minutes = int(data.get("elapsed_minutes", elapsed_minutes))
	remaining_minutes = int(data.get("remaining_minutes", remaining_minutes))
	training_time_active = bool(data.get("training_time_active", training_time_active))
	training_time_paused = bool(data.get("training_time_paused", training_time_paused))
	var saved_log: Variant = data.get("time_log", [])
	time_log = (saved_log as Array).duplicate(true) if saved_log is Array else []

func load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	deserialize(parsed as Dictionary)

func save_state() -> void:
	_save_state()

func _save_state() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(serialize(), "\t"))
