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

	var module_data: Dictionary = scene.get("module_data")
	var player: Control = scene.get("player")
	var boundaries: Array = module_data.get("room_boundary_polygons", [])
	var blockers: Array = module_data.get("blockers", [])

	var pos := Vector2(627, 242)
	var size := Vector2(10, 26)
	var pts := [
		pos, pos + Vector2(size.x, 0), pos + size, pos + Vector2(0, size.y),
		pos + size * 0.5,
	]
	for p in pts:
		var room_feet: Vector2 = scene.call("_room_point", p)
		var room_top_left: Vector2 = room_feet - Vector2(player.size.x * 0.5, player.size.y)
		var blocked: bool = scene.call("_footprint_hits_anything", room_top_left, blockers, boundaries)
		print("point=", p, " blocked=", blocked, " (expect false)")
	quit()
