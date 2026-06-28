extends Node

const SAVE_DIR := "user://saves"
const SAVE_SLOTS := 3

func save_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, clamp(slot, 1, SAVE_SLOTS)]

func ensure_save_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))

func slot_summary(slot: int) -> String:
	var path: String = save_path(slot)
	if not FileAccess.file_exists(path):
		return "空槽"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "无法读取"
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return "损坏"
	var data: Dictionary = parsed
	var saved_resources: Dictionary = data.get("resources", {})
	return "第 %d 天 | 氧 %.0f | 食 %.0f" % [
		int(data.get("day", 1)),
		float(saved_resources.get("oxygen", 0.0)),
		float(saved_resources.get("food", 0.0)),
	]
