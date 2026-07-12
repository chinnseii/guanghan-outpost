class_name FormalFlowRouter
extends RefCounted

## FormalFlowRouter (P4-03): the formal new-game / continue routing DECISION extracted from
## main.gd. Pure routing -- it decides WHERE the formal flow goes and calls explicit public
## APIs (FullSaveOrchestrator / TrainingManager statics) plus injected callbacks. It owns NO
## canonical gameplay/save state and writes NO save bundle. Created/held by main.gd, which
## injects the scene-change / logging / menu-refresh / legacy-continue / new-game-confirmation /
## reset-time callbacks and the demo-progress + save-slot config. Continue PRIORITY is preserved
## exactly: Full Save -> Training Checkpoint -> legacy sandbox slot -> menu notice. Read-only
## progress checks use TrainingManager.read_progress() (never load_progress()).

const FullSaveOrchestratorScript := preload("res://scripts/systems/full_save_orchestrator.gd")
const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")

var _change_scene := Callable()               # func(path: String)
var _legacy_continue := Callable()            # func(slot: int)
var _log := Callable()                        # func(text: String)
var _refresh_menu := Callable()               # func()
var _save_slot_path := Callable()             # func(slot: int) -> String
var _show_new_game_confirmation := Callable()  # func()
var _reset_time := Callable()                 # func()
var _demo_progress_paths: Array = []
var _save_slots := 0

func setup(deps: Dictionary) -> void:
	_change_scene = deps.get("change_scene", Callable())
	_legacy_continue = deps.get("legacy_continue", Callable())
	_log = deps.get("log", Callable())
	_refresh_menu = deps.get("refresh_menu", Callable())
	_save_slot_path = deps.get("save_slot_path", Callable())
	_show_new_game_confirmation = deps.get("show_new_game_confirmation", Callable())
	_reset_time = deps.get("reset_time", Callable())
	_demo_progress_paths = deps.get("demo_progress_paths", [])
	_save_slots = int(deps.get("save_slots", 0))

## -- New game entry --

func start_application_flow() -> void:
	if has_demo_progress():
		if _show_new_game_confirmation.is_valid():
			_show_new_game_confirmation.call()
		return
	start_clean_new_stay()

func start_clean_new_stay() -> void:
	clear_demo_progress()
	if _reset_time.is_valid():
		_reset_time.call()
	_do_change_scene("res://scenes/application/ApplicationStartScene.tscn")

## -- Continue (priority: Full Save -> Training -> legacy sandbox slot -> notice) --

func continue_mission() -> void:
	var progress := TrainingManagerScript.read_progress()
	if full_save_exists():
		var restore_result := FullSaveOrchestratorScript.restore_full_save()
		if not bool(restore_result.get("success", false)):
			_emit_log("Full Save restore failed: %s" % String(restore_result.get("message", "")))
			_do_refresh()
			return
		_do_change_scene(FullSaveOrchestratorScript.continue_scene_path())
		return
	if training_has_progress(progress) or application_progress_exists():
		_do_change_scene(TrainingManagerScript.continue_scene_path())
		return
	# Last-resort LEGACY SANDBOX continue -- only when there is NO Full Save, NO training progress,
	# and NO application profile, so the formal continue flow does not depend on it.
	var latest_slot := latest_save_slot()
	if latest_slot > 0:
		if _legacy_continue.is_valid():
			_legacy_continue.call(latest_slot)
		return
	_emit_log("没有可继续的任务档案。")
	_do_refresh()

## -- Progress predicates (read-only; no side effects on live managers) --

func has_continue_mission() -> bool:
	return training_has_progress(TrainingManagerScript.read_progress()) or full_save_exists() or application_progress_exists() or latest_save_slot() > 0

func has_demo_progress() -> bool:
	if has_continue_mission():
		return true
	for path in _demo_progress_paths:
		if FileAccess.file_exists(String(path)):
			return true
	return false

func training_has_progress(progress: Dictionary) -> bool:
	return bool(progress.get("TrainingStarted", false)) or bool(progress.get("FinalAssessmentCompleted", false)) or bool(progress.get("MissionAssignmentAccepted", false))

func full_save_exists() -> bool:
	return FullSaveOrchestratorScript.has_full_save()

func application_progress_exists() -> bool:
	return FileAccess.file_exists("user://saves/application_profile.json")

func latest_save_slot() -> int:
	if not _save_slot_path.is_valid():
		return 0
	for slot in range(1, _save_slots + 1):
		if FileAccess.file_exists(String(_save_slot_path.call(slot))):
			return slot
	return 0

## -- Progress lifecycle (delete demo/local progress; no save bundle is written) --

func clear_demo_progress() -> void:
	FullSaveOrchestratorScript.reset_formal_restore_session()
	for path in _demo_progress_paths:
		if FileAccess.file_exists(String(path)):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(String(path)))
	if _save_slot_path.is_valid():
		for slot in range(1, _save_slots + 1):
			var path := String(_save_slot_path.call(slot))
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_do_refresh()

## -- Injected-callback helpers --

func _emit_log(text: String) -> void:
	if _log.is_valid():
		_log.call(text)

func _do_refresh() -> void:
	if _refresh_menu.is_valid():
		_refresh_menu.call()

func _do_change_scene(path: String) -> void:
	if _change_scene.is_valid():
		_change_scene.call(path)
