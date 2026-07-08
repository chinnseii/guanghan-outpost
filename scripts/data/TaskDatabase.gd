extends RefCounted

## Task catalog. Pure data (preload, no autoload) -- same style as
## PenaltyDatabase / DoorTypeDatabase. TaskManager reads this to present a
## unified "current objective / progress" view; it does NOT own the underlying
## truth. Each task records HOW its completion is known:
##   completion_flag : a key in TrainingManager's progress data (training tasks)
## Phase 1 catalogues the training modules only; mission/supply come in phase 2.
##
## Task fields:
##   title          : player-facing objective line
##   category       : "training" / "mission" / "supply"
##   order          : sort order within a category (ascending)
##   prerequisites  : [task_id] that must be completed first
##   completion_flag: (training) the TrainingManager progress flag that marks it done

const ALL_COMPLETE_TEXT := {
	"training": "训练科目已全部完成。",
	"mission": "第一周驻留已完成。",
	"supply": "",
}

const TASKS := {
	"training_suit_control": {
		"title": "前往宇航服整备室，穿戴宇航服。",
		"category": "training",
		"order": 10,
		"prerequisites": [],
		"completion_flag": "SuitControlCompleted",
	},
	"training_airlock_procedure": {
		"title": "前往模拟气闸舱，执行气闸流程。",
		"category": "training",
		"order": 20,
		"prerequisites": ["training_suit_control"],
		"completion_flag": "AirlockProcedureCompleted",
	},
	"training_power_repair": {
		"title": "通过气闸前往太阳能阵列训练场，完成维修。",
		"category": "training",
		"order": 30,
		"prerequisites": ["training_airlock_procedure"],
		"completion_flag": "PowerRepairCompleted",
	},
	"training_power_distribution": {
		"title": "前往配电房，恢复供电。",
		"category": "training",
		"order": 40,
		"prerequisites": ["training_power_repair"],
		"completion_flag": "PowerDistributionCompleted",
	},
	"training_life_support": {
		"title": "前往空气系统控制室，恢复训练仓空气。",
		"category": "training",
		"order": 50,
		"prerequisites": ["training_power_distribution"],
		"completion_flag": "LifeSupportCompleted",
	},
	"training_plant_diagnosis": {
		"title": "前往训练温室，完成植物诊断。",
		"category": "training",
		"order": 60,
		"prerequisites": ["training_life_support"],
		"completion_flag": "PlantDiagnosisCompleted",
	},

	# -- Mission (正式任务): coarse day/arc tasks. Completion is derived from
	# sprint06 progress flags; the fine per-day checklist stays in
	# sprint06_base_scene, the same way training steps stay in the scene.
	"mission_day_01": {
		"title": "Day 01：进入旧基地，恢复供电与生命支持，诊断最后一株植物。",
		"category": "mission",
		"order": 110,
		"prerequisites": [],
		"completion_flag": "Day01Completed",
	},
	"mission_day_02": {
		"title": "Day 02：完成今日巡检并发送对地报告。",
		"category": "mission",
		"order": 120,
		"prerequisites": ["mission_day_01"],
		"completion_flags_any": ["Day02Completed", "Day02ReportSent"],
	},
	"mission_week_one": {
		"title": "第一周日常驻留：完成 Day 03–07 的巡检与周报。",
		"category": "mission",
		"order": 130,
		"prerequisites": ["mission_day_02"],
		"completion_flag": "WeekOneCompleted",
	},
}

static func has_task(task_id: String) -> bool:
	return TASKS.has(task_id)

static func get_task(task_id: String) -> Dictionary:
	if not TASKS.has(task_id):
		return {}
	var data: Dictionary = (TASKS[task_id] as Dictionary).duplicate(true)
	data["task_id"] = task_id
	return data

static func get_title(task_id: String) -> String:
	return String(get_task(task_id).get("title", ""))

## Task ids in a category, sorted by their `order` field (ascending).
static func tasks_in_category(category: String) -> Array:
	var matched: Array = []
	for task_id in TASKS.keys():
		if String((TASKS[task_id] as Dictionary).get("category", "")) == category:
			matched.append(task_id)
	matched.sort_custom(func(a, b): return int((TASKS[a] as Dictionary).get("order", 0)) < int((TASKS[b] as Dictionary).get("order", 0)))
	return matched

static func all_complete_text(category: String) -> String:
	return String(ALL_COMPLETE_TEXT.get(category, ""))
