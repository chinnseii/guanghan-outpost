extends Node

func can_run_robot(unlocked_techs: Array[String]) -> bool:
	return unlocked_techs.has("robot_assist") or unlocked_techs.has("yutu_robot")

func task_name(task: String) -> String:
	match task:
		"sample":
			return "玉兔采样"
		"maintenance":
			return "维护巡检"
		"haul":
			return "搬运补给"
		"charging":
			return "返回充电"
		_:
			return "待机"

func task_robot_type(task: String) -> String:
	match task:
		"sample":
			return "玉兔采样车"
		"maintenance":
			return "维护机器人"
		"haul":
			return "搬运机器人"
		"charging":
			return "充电桩"
		_:
			return "机器人"
