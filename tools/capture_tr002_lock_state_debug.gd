extends SceneTree

const SCENE := "res://scenes/training/TrainingBaseMap.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.3).timeout
	scene.call("_close_briefing")
	await process_frame

	var areas: Dictionary = scene.get("areas")
	for area_id in ["power_distribution_room", "air_system_control_room", "greenhouse_room", "suit_prep_room", "hub"]:
		var area: Dictionary = areas.get(area_id, {})
		print(area_id, " unlocked=", area.get("unlocked", "MISSING"))

	var openings: Array = scene.call("_effective_door_openings")
	print("effective door openings count=", openings.size())

	var module_data: Dictionary = scene.get("module_data")
	print("door_openings config count=", module_data.get("door_openings", []).size())

	quit()
