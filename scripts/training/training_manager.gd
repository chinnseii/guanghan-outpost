extends Node
class_name TrainingManager

const FullSaveOrchestratorScript := preload("res://scripts/systems/full_save_orchestrator.gd")

const SAVE_PATH := "user://saves/training_progress.json"
const APPLICATION_PROFILE_PATH := "user://saves/application_profile.json"

const START_SCENE := "res://scenes/training/TrainingStartScene.tscn"
## MODULE_01/02/04/05/06 are LEGACY PATH STRINGS ONLY -- the standalone
## per-module scene files they name were deleted (at the user's request)
## once the training small map (TRAINING_BASE_MAP below) replaced them.
## They're kept solely so _remap_legacy_training_scene() can recognize and
## redirect old save files that still store these paths in
## CurrentSceneAfterTraining. Never pass them to change_scene_to_file().
const MODULE_01 := "res://scenes/training/Training_01_SuitControl.tscn"
const MODULE_02 := "res://scenes/training/Training_02_AirlockProcedure.tscn"
## 训练模块 03："月面太阳能板维修" (太阳能阵列训练场) -- the one training module
## that still lives in its own real scene (reached via the airlock's outer
## door in the training small map). Keeps the existing "power_repair"
## module_id/PowerRepairCompleted flag; see training_base_map.gd's file
## header for why it wasn't folded into the hub scene.
const MODULE_03 := "res://scenes/training/SolarArrayTrainingField.tscn"
const MODULE_04 := "res://scenes/training/Training_04_PowerDistribution.tscn"
const MODULE_05 := "res://scenes/training/Training_05_AirSystemControl.tscn"
const MODULE_06 := "res://scenes/training/Training_06_TrainingGreenhouse.tscn"
## Training small map: one persistent hub scene hosting 训练中控室/宇航服整备室/
## 模拟气闸舱/配电房/空气系统控制室/训练温室 as walkable rooms connected by doors,
## instead of each module being its own full scene swap. MODULE_03 (太阳能阵列
## 训练场) deliberately keeps its own separate scene -- see
## training_base_map.gd's file header for why (its entry-gate/repair-
## container/fault-diagnosis logic is complex and already hardened; the
## user's own spec permits keeping it a separate scene reached via the
## airlock's outer door). The superseded standalone Training_0X_*.tscn
## scene files were deleted at the user's request; their paths survive only
## as the legacy-remap constants above.
const TRAINING_BASE_MAP := "res://scenes/training/TrainingBaseMap.tscn"
const FINAL_ASSESSMENT := "res://scenes/training/FinalAssessmentScene.tscn"
const MISSION_NOTICE := "res://scenes/training/MissionAssignmentNoticeScene.tscn"
const BLACK_SCREEN := "res://scenes/training/AssignmentBlackScreenScene.tscn"
const LAUNCH_SEQUENCE := "res://scenes/training/LaunchSequenceScene.tscn"
const ARRIVAL_CINEMATIC := "res://scenes/arrival/ArrivalCinematicScene.tscn"
const BASE_AIRLOCK := "res://scenes/base/BaseAirlockEntryScene.tscn"
const OLD_BASE_INTERIOR := "res://scenes/base/OldBaseInteriorScene.tscn"
const OLD_GREENHOUSE := "res://scenes/base/OldGreenhouseScene.tscn"
const DAY01_END := "res://scenes/base/Day01EndScene.tscn"
const DAY02_START := "res://scenes/base/Day02StartScene.tscn"
const DAY02_END := "res://scenes/base/Day02EndScene.tscn"
const WEEK_ROUTINE_START := "res://scenes/base/WeekRoutineStartScene.tscn"
const WEEK_ROUTINE_END := "res://scenes/base/WeekRoutineEndScene.tscn"
const PHASE02_PLACEHOLDER := "res://scenes/base/Phase02PlaceholderScene.tscn"
const SPRINT06_SAVE_PATH := "user://saves/sprint06_progress.json"

const MODULE_SCENES := {
	"suit_control": TRAINING_BASE_MAP,
	"airlock_procedure": TRAINING_BASE_MAP,
	"power_repair": MODULE_03,
	"power_distribution": TRAINING_BASE_MAP,
	"life_support": TRAINING_BASE_MAP,
	"plant_diagnosis": TRAINING_BASE_MAP,
	"final_assessment": TRAINING_BASE_MAP,
	"mission_assignment": MISSION_NOTICE,
	"assignment_black_screen": BLACK_SCREEN,
}

const TRAINING_CHECKPOINT_KEYS := {
	"TrainingStarted": true,
	"CurrentTrainingModule": true,
	"SuitControlCompleted": true,
	"AirlockProcedureCompleted": true,
	"PowerRepairCompleted": true,
	"PowerDistributionCompleted": true,
	"LifeSupportCompleted": true,
	"PlantDiagnosisCompleted": true,
	"CompletedTrainingModules": true,
	"PowerRepairUnlockToastShown": true,
	"FinalAssessmentCompleted": true,
	"MissionAssignmentAccepted": true,
	"TrainingStatus": true,
	"TrainingFailureReason": true,
	"OpeningFlowStage": true,
	"CurrentSceneAfterTraining": true,
	"SuitState": true,
	"TrainingTimeState": true,
	"TrainingInventoryState": true,
}

const LEGACY_GLOBAL_STATE_KEYS := [
	"TimeState",
	"HealthState",
	"BaseStatusState",
	"AirSystemState",
	"PowerSystemState",
	"WaterSystemState",
	"InventoryState",
	"BackpackState",
	"StorageState",
	"PlantGrowthState",
	"PlayerStateManagerState",
]

static func default_data() -> Dictionary:
	return {
		"TrainingStarted": false,
		"CurrentTrainingModule": "start",
		"SuitControlCompleted": false,
		"AirlockProcedureCompleted": false,
		"PowerRepairCompleted": false,
		"PowerDistributionCompleted": false,
		"LifeSupportCompleted": false,
		"PlantDiagnosisCompleted": false,
		"CompletedTrainingModules": [],
		## One-time flag so the hub's "太阳能阵列基础输出已恢复。请返回基地，进入
		## 配电房。" toast (shown the first time the player is back in the hub
		## after finishing training 03 in its own separate scene) only fires
		## once, not every time the hub scene reloads afterward.
		"PowerRepairUnlockToastShown": false,
		"FinalAssessmentCompleted": false,
		"MissionAssignmentAccepted": false,
		"TrainingStatus": "",
		"TrainingFailureReason": "",
		"OpeningFlowStage": "",
		"CurrentSceneAfterTraining": START_SCENE,
		## Training checkpoint-owned state. Full Save owns formal mission
		## globals; these fields are limited to the training sandbox.
		"SuitState": {},
		"TrainingTimeState": {},
		"TrainingInventoryState": {},
	}

## Reads the raw progress flags (completion booleans, CurrentTrainingModule,
## etc.) merged over default_data(), with NO side effects on live managers.
## Use this (not load_progress()) from anywhere that just needs to read/edit
## flags mid-session -- e.g. set_current_module()/mark_module_completed()
## below. load_progress()'s manager-deserialize step is only correct for a
## genuine restore-from-disk (app launch/resume), since it overwrites
## whatever's currently live with the LAST-SAVED snapshot; calling it mid-session,
## after live managers have already changed since that snapshot (e.g. the
## player wore the EVA suit), would silently discard that change the moment
## save_progress() is next called. (Found while wiring 训练模块 03's suit-worn
## entry gate: SuitManager.is_suit_worn was being reset back to false by
## mark_module_completed() at the end of every prior module, since that
## function's own load_progress() call re-synced from the stale snapshot
## captured when the module started, before the suit was worn.)
static func _read_progress_data() -> Dictionary:
	var data := default_data()
	if not FileAccess.file_exists(SAVE_PATH):
		return data
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return data
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return data
	var saved: Dictionary = parsed
	for key in saved.keys():
		var key_string := String(key)
		if TRAINING_CHECKPOINT_KEYS.has(key_string):
			data[key_string] = saved[key]
	var legacy_global_fields := {}
	for key in LEGACY_GLOBAL_STATE_KEYS:
		if saved.has(key):
			legacy_global_fields[key] = saved[key]
	if not legacy_global_fields.is_empty():
		data["LegacyGlobalStateFields"] = legacy_global_fields
	return data

static func load_progress() -> Dictionary:
	var data := _read_progress_data()
	var suit_manager := _suit_manager()
	if suit_manager != null and suit_manager.has_method("deserialize") and data.get("SuitState", {}) is Dictionary:
		suit_manager.call("deserialize", data.get("SuitState", {}))
	var training_time_manager := _training_time_manager()
	if training_time_manager != null and training_time_manager.has_method("deserialize") and data.get("TrainingTimeState", {}) is Dictionary:
		training_time_manager.call("deserialize", data.get("TrainingTimeState", {}))
	_restore_training_inventory_state(data.get("TrainingInventoryState", {}))
	_finalize_training_checkpoint_restore()
	return data

## Read-only inspection of saved progress (P3-03a). Same merged dict as the internal
## reader, but WITHOUT the live-manager deserialize side effects of load_progress().
## External callers that only need to inspect flags (has-progress, current stage,
## completion checks, menu "continue" gating) must use THIS, never load_progress().
## load_progress() is the state-restoring path, reserved for genuine continue/resume.
## (Naming discipline: read_*/inspect_*/has_* = no side effects; load_*/restore_*/apply_*
## = mutate live state.)
static func read_progress() -> Dictionary:
	return _read_progress_data()

## Restore finalization endpoint (P3-03a). Called once at the end of load_progress()
## AFTER every manager has been deserialized, so that -- regardless of deserialize order
## (e.g. PlayerStateManager is restored AFTER SuitManager above) -- each compatibility
## mirror is re-synchronised FROM its canonical owner and the canonical owner always wins.
## Strictly idempotent and side-effect-free beyond mirror sync: it reloads no files, calls
## no deserialize, advances no clock, consumes no resources, triggers no penalty, and
## writes no save. Uses only existing public sync methods (canonical -> mirror direction),
## so a mirror can never overwrite its canonical owner. Safe to call twice.
static func finalize_restore() -> void:
	# Power canonical (PowerSystemManager) -> BaseStatusManager.power mirror.
	var power_manager := _power_system_manager()
	var base_status_manager := _base_status_manager()
	if power_manager != null and base_status_manager != null \
			and power_manager.has_method("get_power_percent") and base_status_manager.has_method("set_power_percent"):
		base_status_manager.call("set_power_percent", power_manager.call("get_power_percent"))
	# Suit canonical (SuitManager.is_suit_worn) -> PlayerStateManager.is_suit_worn mirror.
	var player_state_manager := _player_state_manager()
	if player_state_manager != null and player_state_manager.has_method("sync_suit_state_from_suit_manager"):
		player_state_manager.call("sync_suit_state_from_suit_manager")

static func save_progress(data: Dictionary) -> void:
	var checkpoint := _checkpoint_data(data)
	var suit_manager := _suit_manager()
	if suit_manager != null and suit_manager.has_method("serialize"):
		checkpoint["SuitState"] = suit_manager.call("serialize")
	var training_time_manager := _training_time_manager()
	if training_time_manager != null and training_time_manager.has_method("serialize"):
		checkpoint["TrainingTimeState"] = training_time_manager.call("serialize")
	checkpoint["TrainingInventoryState"] = _training_inventory_state()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(checkpoint, "\t"))

static func _checkpoint_data(data: Dictionary) -> Dictionary:
	var checkpoint := default_data()
	for key in data.keys():
		var key_string := String(key)
		if TRAINING_CHECKPOINT_KEYS.has(key_string):
			checkpoint[key_string] = data[key]
	return checkpoint

static func _training_inventory_state() -> Dictionary:
	var inventory_manager := _inventory_manager()
	if inventory_manager == null:
		return {}
	var containers: Variant = inventory_manager.get("training_containers")
	if containers is Dictionary:
		return {"training_containers": (containers as Dictionary).duplicate(true)}
	return {}

static func _restore_training_inventory_state(state: Variant) -> void:
	if not (state is Dictionary):
		return
	var inventory_manager := _inventory_manager()
	if inventory_manager == null:
		return
	var containers: Variant = (state as Dictionary).get("training_containers", {})
	if containers is Dictionary:
		inventory_manager.set("training_containers", (containers as Dictionary).duplicate(true))
		inventory_manager.emit_signal("inventory_changed")

static func _finalize_training_checkpoint_restore() -> void:
	var player_state_manager := _player_state_manager()
	if player_state_manager != null and player_state_manager.has_method("sync_suit_state_from_suit_manager"):
		player_state_manager.call("sync_suit_state_from_suit_manager")

static func reset_progress() -> void:
	var manager := _time_manager()
	if manager != null and manager.has_method("reset_to_arrival"):
		manager.call("reset_to_arrival")
	var health_manager := _health_manager()
	if health_manager != null and health_manager.has_method("reset_to_arrival"):
		health_manager.call("reset_to_arrival")
	var base_status_manager := _base_status_manager()
	if base_status_manager != null and base_status_manager.has_method("reset_to_arrival"):
		base_status_manager.call("reset_to_arrival")
	var air_system_manager := _air_system_manager()
	if air_system_manager != null and air_system_manager.has_method("reset_to_arrival"):
		air_system_manager.call("reset_to_arrival")
	var power_system_manager := _power_system_manager()
	if power_system_manager != null and power_system_manager.has_method("reset_to_arrival"):
		power_system_manager.call("reset_to_arrival")
	var water_system_manager := _water_system_manager()
	if water_system_manager != null and water_system_manager.has_method("reset_to_arrival"):
		water_system_manager.call("reset_to_arrival")
	var inventory_manager := _inventory_manager()
	if inventory_manager != null and inventory_manager.has_method("reset_to_arrival"):
		inventory_manager.call("reset_to_arrival")
	var backpack_manager := _backpack_manager()
	if backpack_manager != null and backpack_manager.has_method("reset_to_arrival"):
		backpack_manager.call("reset_to_arrival")
	var storage_manager := _storage_manager()
	if storage_manager != null and storage_manager.has_method("reset_to_arrival"):
		storage_manager.call("reset_to_arrival")
	var plant_growth_manager := _plant_growth_manager()
	if plant_growth_manager != null and plant_growth_manager.has_method("reset_to_arrival"):
		plant_growth_manager.call("reset_to_arrival")
	var suit_manager := _suit_manager()
	if suit_manager != null and suit_manager.has_method("reset_to_arrival"):
		suit_manager.call("reset_to_arrival")
	var player_state_manager := _player_state_manager()
	if player_state_manager != null and player_state_manager.has_method("reset_to_arrival"):
		player_state_manager.call("reset_to_arrival")
	var training_time_manager := _training_time_manager()
	if training_time_manager != null and training_time_manager.has_method("start_training_time"):
		# Fully clears elapsed/remaining/time_log back to defaults, then
		# immediately marks it inactive -- resetting progress shouldn't leave
		# a countdown silently running until start_training() is called again.
		training_time_manager.call("start_training_time")
		training_time_manager.call("stop_training_time")
	save_progress(default_data())

static func start_training() -> void:
	var data := _read_progress_data()
	# Training starts fresh on Earth -- reset the shared SuitManager so a
	# suit left worn/servicing by a previous playthrough can't make the
	# wear-suit step silently fail (wear_suit_training() requires
	# suit_storage_state == "ready"). Found via user report: clicking
	# 确认穿戴 appeared to do nothing because a stale suit_state.json had
	# the suit still worn from an earlier run. Must happen BEFORE
	# save_progress() below, so the SuitState bundle captures the reset
	# state rather than re-pickling the stale one.
	var suit_manager := _suit_manager()
	if suit_manager != null and suit_manager.has_method("reset_to_arrival"):
		suit_manager.call("reset_to_arrival")
	data["TrainingStarted"] = true
	data["CurrentTrainingModule"] = "suit_control"
	data["CurrentSceneAfterTraining"] = TRAINING_BASE_MAP
	save_progress(data)
	update_candidate_file_status("训练序列中")
	var training_time_manager := _training_time_manager()
	if training_time_manager != null and training_time_manager.has_method("start_training_time"):
		training_time_manager.call("start_training_time")

## Dev-only convenience: the training small map derives each room's door
## lock from the same 6 completion flags checked below, so a "Dev Only: jump
## straight to training module NN" button now needs to force every EARLIER
## module's flag true first, or the target room would just show up locked.
## Does not touch module_id's own flag (that module hasn't been done yet --
## the whole point is to test it).
static func dev_force_unlock_up_to(module_id: String) -> void:
	var order := ["suit_control", "airlock_procedure", "power_repair", "power_distribution", "life_support", "plant_diagnosis"]
	var target_index := order.find(module_id)
	if target_index < 0:
		return
	var data := _read_progress_data()
	for i in range(target_index):
		match order[i]:
			"suit_control":
				data["SuitControlCompleted"] = true
			"airlock_procedure":
				data["AirlockProcedureCompleted"] = true
			"power_repair":
				data["PowerRepairCompleted"] = true
				data["PowerRepairUnlockToastShown"] = true
			"power_distribution":
				data["PowerDistributionCompleted"] = true
			"life_support":
				data["LifeSupportCompleted"] = true
	save_progress(data)

static func set_current_module(module_id: String) -> void:
	var data := _read_progress_data()
	data["TrainingStarted"] = true
	data["CurrentTrainingModule"] = module_id
	data["CurrentSceneAfterTraining"] = String(MODULE_SCENES.get(module_id, START_SCENE))
	save_progress(data)

static func mark_module_completed(module_id: String, next_module_id: String) -> void:
	var data := _read_progress_data()
	data["TrainingStarted"] = true
	match module_id:
		"suit_control":
			data["SuitControlCompleted"] = true
		"airlock_procedure":
			data["AirlockProcedureCompleted"] = true
		"power_repair":
			data["PowerRepairCompleted"] = true
		"power_distribution":
			data["PowerDistributionCompleted"] = true
		"life_support":
			data["LifeSupportCompleted"] = true
		"plant_diagnosis":
			data["PlantDiagnosisCompleted"] = true
		"final_assessment":
			data["FinalAssessmentCompleted"] = true
	var completed: Array = data.get("CompletedTrainingModules", [])
	if not completed.has(module_id):
		completed.append(module_id)
	data["CompletedTrainingModules"] = completed
	data["CurrentTrainingModule"] = next_module_id
	data["CurrentSceneAfterTraining"] = String(MODULE_SCENES.get(next_module_id, START_SCENE))
	save_progress(data)
	if module_id == "final_assessment":
		update_candidate_file_status("已通过最终考核")

## Required modules are the six core training stations -- final_assessment
## is the settlement step that happens once these are done, not one of the
## modules the training archive timer is racing against. Used by
## TrainingTimeManager.check_training_timeout() to decide pass vs. fail when
## the archive time limit runs out.
static func are_required_modules_completed() -> bool:
	var data := _read_progress_data()
	return bool(data.get("SuitControlCompleted", false)) \
		and bool(data.get("AirlockProcedureCompleted", false)) \
		and bool(data.get("PowerRepairCompleted", false)) \
		and bool(data.get("PowerDistributionCompleted", false)) \
		and bool(data.get("LifeSupportCompleted", false)) \
		and bool(data.get("PlantDiagnosisCompleted", false))

## Called by TrainingTimeManager.check_training_timeout() when the archive
## time limit expires with required modules still incomplete. This is a
## training-only failure state ("candidate file archived, deployment
## clearance not activated") -- not a death/Game Over, and it must never
## touch the official mission TimeManager/HealthManager/base state.
static func fail_training(reason: String) -> void:
	# P3-03a: use the read-only path, not load_progress(). fail_training() is invoked
	# mid-session by TrainingTimeManager.check_training_timeout() and its own contract
	# (see comment above) says it must NEVER touch live mission managers -- load_progress()
	# would deserialize all 12 of them from the last snapshot, clobbering live state. We
	# only need the progress flags to check/set TrainingStatus; save_progress() below then
	# re-serialises the CURRENT live managers unchanged.
	var data := _read_progress_data()
	if String(data.get("TrainingStatus", "")) == "failed":
		return
	data["TrainingStatus"] = "failed"
	data["TrainingFailureReason"] = reason
	save_progress(data)
	update_candidate_file_status("候选人档案已归档")
	var time_manager := _training_time_manager()
	if time_manager != null and time_manager.has_method("stop_training_time"):
		time_manager.call("stop_training_time")

# P3-03a: these are pure flag reads -- use the no-side-effect reader, not load_progress()
# (which would deserialize all live managers). Currently unreferenced anywhere in the repo;
# kept (not deleted) but made side-effect-free so any future caller is safe.
static func training_status() -> String:
	return String(_read_progress_data().get("TrainingStatus", ""))

static func training_failure_reason() -> String:
	return String(_read_progress_data().get("TrainingFailureReason", ""))

static func accept_assignment(opening_stage := "AssignmentBlackScreen") -> void:
	var data := _read_progress_data()
	var manager := _time_manager()
	if manager != null and manager.has_method("reset_to_arrival"):
		manager.call("reset_to_arrival")
	data["MissionAssignmentAccepted"] = true
	data["OpeningFlowStage"] = opening_stage
	data["CurrentTrainingModule"] = "assignment_black_screen"
	data["CurrentSceneAfterTraining"] = BLACK_SCREEN
	save_progress(data)
	update_candidate_file_status("已接受月面派遣")

static func update_candidate_file_status(status: String) -> void:
	var data: Dictionary = {}
	if FileAccess.file_exists(APPLICATION_PROFILE_PATH):
		var read_file := FileAccess.open(APPLICATION_PROFILE_PATH, FileAccess.READ)
		if read_file != null:
			var parsed: Variant = JSON.parse_string(read_file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				data = parsed as Dictionary
	if data.is_empty():
		data = {
			"PlayerName": "",
			"ApplicationID": "GHO-APP-2068-0421",
			"CandidateFileStatus": status,
			"MissionIdentity": "常驻开拓者候选人",
		}
	else:
		data["CandidateFileStatus"] = status
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var write_file := FileAccess.open(APPLICATION_PROFILE_PATH, FileAccess.WRITE)
	if write_file != null:
		write_file.store_string(JSON.stringify(data, "\t"))

static func set_opening_flow_stage(opening_stage: String, scene_path: String) -> void:
	var data := _read_progress_data()
	data["MissionAssignmentAccepted"] = true
	data["OpeningFlowStage"] = opening_stage
	data["CurrentSceneAfterTraining"] = scene_path
	save_progress(data)

static func continue_scene_path() -> String:
	var base_scene := _base_continue_scene_path()
	if not base_scene.is_empty():
		return base_scene
	var data := _read_progress_data()
	if bool(data.get("MissionAssignmentAccepted", false)):
		var opening_stage := String(data.get("OpeningFlowStage", ""))
		if opening_stage == "AwaitingArrivalCinematic":
			return ARRIVAL_CINEMATIC
		if opening_stage == "AwaitingLaunchSequence":
			return LAUNCH_SEQUENCE
		return BLACK_SCREEN
	if bool(data.get("FinalAssessmentCompleted", false)):
		return MISSION_NOTICE
	if bool(data.get("TrainingStarted", false)):
		return _remap_legacy_training_scene(String(data.get("CurrentSceneAfterTraining", START_SCENE)))
	return "res://scenes/application/ApplicationStartScene.tscn"

## Save files written before the training small map existed can still hold
## a CurrentSceneAfterTraining pointing at one of the old standalone
## per-module scenes -- redirect those into the hub so "继续" never drops the
## player back into the superseded flow. MODULE_03 (solar array) is not in
## this list: it's still the live scene for power_repair.
static func _remap_legacy_training_scene(scene_path: String) -> String:
	if scene_path in [MODULE_01, MODULE_02, MODULE_04, MODULE_05, MODULE_06,
			"res://scenes/training/Training_03_PowerRepair.tscn"]:
		return TRAINING_BASE_MAP
	return scene_path

static func _base_continue_scene_path() -> String:
	return FullSaveOrchestratorScript.continue_scene_path()

static func player_name() -> String:
	var path := "user://saves/application_profile.json"
	if not FileAccess.file_exists(path):
		return "候选人"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "候选人"
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return "候选人"
	var value := String((parsed as Dictionary).get("PlayerName", "")).strip_edges()
	return value if not value.is_empty() else "候选人"

static func _time_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TimeManager")

static func _health_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("HealthManager")

static func _base_status_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("BaseStatusManager")

static func _air_system_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("AirSystemManager")

static func _power_system_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("PowerSystemManager")

static func _water_system_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("WaterSystemManager")

static func _plant_growth_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("PlantGrowthManager")

static func _suit_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("SuitManager")

static func _player_state_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("PlayerStateManager")

static func _inventory_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("InventoryManager")

static func _backpack_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("BackpackManager")

static func _storage_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("StorageManager")

static func _training_time_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TrainingTimeManager")
