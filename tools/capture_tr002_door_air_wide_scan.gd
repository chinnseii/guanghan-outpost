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

	print("--- door_air wide scan (x:625-685, y:200-290) ---")
	var y := 200.0
	while y <= 290.0:
		var row := ""
		var x := 625.0
		while x <= 685.0:
			var feet_design := Vector2(x, y)
			var room_feet: Vector2 = scene.call("_room_point", feet_design)
			var room_top_left: Vector2 = room_feet - Vector2(player.size.x * 0.5, player.size.y)
			var blocked: bool = scene.call("_footprint_hits_anything", room_top_left, blockers, boundaries)
			row += "#" if blocked else "."
			x += 3.0
		print("y=%6.1f  %s" % [y, row])
		y += 5.0
	quit()
