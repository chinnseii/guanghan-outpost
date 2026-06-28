extends Node

func can_run_robot(unlocked_techs: Array[String]) -> bool:
	return unlocked_techs.has("robot_assist") or unlocked_techs.has("yutu_robot")

func task_name(task: String) -> String:
	match task:
		"sample":
			return "自动采样"
		"maintenance":
			return "自动巡检"
		"haul":
			return "补给搬运"
		"charging":
			return "返回充电"
		_:
			return "待机"
