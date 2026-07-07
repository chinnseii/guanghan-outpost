extends Node

signal academic_background_changed(background_id: String)

const PROFILE_PATH := "user://saves/application_profile.json"

const BACKGROUND_ORDER: Array[String] = [
	"plant_science",
	"mechanical_engineering",
	"materials_science",
	"medical",
]

var selected_background_id := ""
var selected_background_name := ""
var selected_background_tags: Array[String] = []

var academic_backgrounds: Dictionary = {
	"plant_science": {
		"id": "plant_science",
		"name": "植物科学",
		"core_risk": "生命会不会生长",
		"tags": ["plant", "greenhouse", "growth", "water", "light", "temperature"],
		"description": "熟悉植物状态、水 / 光 / 温度对植物的影响、温室环境风险、植物恢复周期与作物生长问题。",
		"advantage_scenes": ["植物诊断", "旧温室", "作物生长系统", "水循环与植物供水", "补光与温度对植物的影响"],
		"feature": "在植物诊断、旧温室、作物生长、水循环与植物供水、补光与温度判断中获得额外专业提示。",
	},
	"mechanical_engineering": {
		"id": "mechanical_engineering",
		"name": "机械工程",
		"core_risk": "系统会不会运转",
		"tags": ["mechanical", "power", "repair", "solar", "oxygen_generator", "thermal", "pump"],
		"description": "熟悉电力系统、太阳能阵列、制氧模块、温控设备、水泵与设备故障链。",
		"advantage_scenes": ["太阳能板维修", "供电恢复", "制氧模块维修", "温控系统维修", "水循环设备维修"],
		"feature": "在太阳能板维修、供电恢复、制氧模块维修、温控系统维修、水循环设备维修中获得额外专业提示。",
	},
	"materials_science": {
		"id": "materials_science",
		"name": "材料科学",
		"core_risk": "基地会不会漏",
		"tags": ["materials", "seal", "pressure", "structure", "dust", "aging", "leak"],
		"description": "熟悉舱压、密封材料、结构老化、舱体接缝、气闸 / 对接口微漏、月尘磨蚀、辐射与温差损伤。",
		"advantage_scenes": ["气闸密封", "飞船对接口检查", "旧基地舱压异常", "密封圈老化", "结构裂纹判断"],
		"feature": "在气闸密封、飞船对接口检查、旧基地舱压异常、密封圈老化、结构裂纹判断中获得额外专业提示。",
	},
	"medical": {
		"id": "medical",
		"name": "医学",
		"core_risk": "人会不会撑不住",
		"tags": ["medical", "health", "oxygen", "temperature", "fatigue", "nutrition", "morale"],
		"description": "熟悉精力、饱腹、营养、心理、氧气不足对人体的影响、低温 / 高温风险与长期单人驻留风险。",
		"advantage_scenes": ["健康状态判断", "恢复顺序建议", "低氧 / 低温环境风险", "高强度维修前提醒", "睡眠恢复效率判断"],
		"feature": "在健康状态判断、恢复顺序建议、低氧 / 低温环境风险、高强度维修前提醒、睡眠恢复效率判断中获得额外专业提示。",
	},
}

func _ready() -> void:
	load_from_profile()

func get_all_backgrounds() -> Array:
	var result: Array = []
	for background_id in BACKGROUND_ORDER:
		result.append(academic_backgrounds[background_id])
	return result

func set_background(background_id: String, persist := true) -> bool:
	var normalized := normalize_background_id(background_id)
	if not academic_backgrounds.has(normalized):
		return false
	var data: Dictionary = academic_backgrounds[normalized]
	selected_background_id = String(data.get("id", ""))
	selected_background_name = String(data.get("name", ""))
	selected_background_tags.clear()
	for tag in data.get("tags", []):
		selected_background_tags.append(String(tag))
	if persist:
		save_to_profile()
	academic_background_changed.emit(selected_background_id)
	return true

func get_selected_background_id() -> String:
	return selected_background_id

func get_selected_background_name() -> String:
	return selected_background_name

func has_background_selected() -> bool:
	return not selected_background_id.is_empty()

func has_background_tag(tag: String) -> bool:
	return selected_background_tags.has(tag)

func get_selected_background_data() -> Dictionary:
	if selected_background_id.is_empty() or not academic_backgrounds.has(selected_background_id):
		return {}
	return academic_backgrounds[selected_background_id]

func normalize_background_id(value: String) -> String:
	var stripped := value.strip_edges()
	if academic_backgrounds.has(stripped):
		return stripped
	for background_id in academic_backgrounds.keys():
		var data: Dictionary = academic_backgrounds[background_id]
		if String(data.get("name", "")) == stripped:
			return String(background_id)
	match stripped:
		"农业工程", "生命支持工程":
			return ""
	return ""

func get_professional_hint(context_id: String) -> String:
	if not has_background_selected():
		return ""
	match context_id:
		"training_03_solar_array_fault":
			return _training_03_solar_hint()
		"training_04_power_storage_fault":
			return _training_04_power_hint()
		"training_05_air_oxygen_low":
			return _training_05_air_hint()
		"training_06_greenhouse_light_low":
			return _training_06_greenhouse_hint()
		_:
			return ""

func load_from_profile() -> void:
	var data := _read_profile_dictionary()
	if data.is_empty():
		return
	var saved_id := String(data.get("selected_academic_background_id", data.get("SelectedAcademicBackgroundId", "")))
	if saved_id.is_empty():
		saved_id = String(data.get("EducationBackground", data.get("education_background", "")))
	set_background(saved_id, false)

func save_to_profile() -> void:
	var data := _read_profile_dictionary()
	data["selected_academic_background_id"] = selected_background_id
	data["SelectedAcademicBackgroundId"] = selected_background_id
	data["EducationBackground"] = selected_background_name
	data["education_background"] = selected_background_name
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://saves"))
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

func _read_profile_dictionary() -> Dictionary:
	if not FileAccess.file_exists(PROFILE_PATH):
		return {}
	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary

func _training_03_solar_hint() -> String:
	match selected_background_id:
		"plant_science":
			return "本模块无额外专业优势。"
		"mechanical_engineering":
			return "专业判断：\n控制器未出现核心损坏代码。\n输出波动更像接口接触不良。\n建议优先处理主电缆接口，而不是更换控制器。"
		"materials_science":
			return "专业判断：\n接口处月尘附着可能影响接触稳定。\n阵列表面未见明显结构裂纹。"
		"medical":
			return "专业判断：\n当前处于宇航服外勤状态。\n如果继续执行长时间操作，请注意氧气与精力消耗。"
	return ""

func _training_04_power_hint() -> String:
	match selected_background_id:
		"plant_science":
			return "专业判断：\n温室补光系统依赖稳定供电。\n如果供电未恢复，后续植物状态无法稳定改善。"
		"mechanical_engineering":
			return "专业判断：\n太阳能输入已经恢复，但供电仍不稳定。\n问题更可能出在储能模块与主供电回路的接入状态，而不是太阳能阵列本体。"
		"materials_science":
			return "专业判断：\n当前异常不像结构损伤，更像连接或接入流程问题。\n优先检查储能模块接口状态。"
		"medical":
			return "专业判断：\n供电不稳定会影响后续生命支持系统恢复。\n请优先保证制氧与空气循环系统获得稳定供电。"
	return ""

func _training_05_air_hint() -> String:
	match selected_background_id:
		"plant_science":
			return "专业判断：\n空气系统恢复后，温室环境才具备继续诊断植物状态的基础条件。"
		"mechanical_engineering":
			return "专业判断：\n制氧装置处于待启动状态。\n供电恢复后，可以重新接入运行。"
		"materials_science":
			return "专业判断：\n当前舱压稳定，暂时不像舱体破损导致的泄漏。\n优先处理氧气生成不足。"
		"medical":
			return "专业判断：\n氧气浓度偏低会影响判断力与行动能力。\n应尽快启动制氧装置，使氧气回升到安全水平。"
	return ""

func _training_06_greenhouse_hint() -> String:
	match selected_background_id:
		"plant_science":
			return "专业判断：\n水分和温度正常，但光照不足。\n植物生长缓慢的主因应优先判断为光照不足。\n继续增加供水不会改善当前生长问题。"
		"mechanical_engineering":
			return "专业判断：\n补光系统需要稳定电力支持。\n当前供电已恢复，可以启动补光设备。"
		"materials_science":
			return "专业判断：\n当前异常不表现为结构或设备损坏，更像环境参数不足。"
		"medical":
			return "专业判断：\n温室恢复有助于长期食物与氧气循环，但当前问题主要不是人体生命支持风险。"
	return ""
