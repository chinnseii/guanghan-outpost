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

	print("--- west-of-door_air scan (x:560-630, y:200-300) to find where normal floor begins ---")
	var y := 200.0
	while y <= 300.0:
		var row := ""
		var x := 560.0
		while x <= 630.0:
			var feet_design := Vector2(x, y)
			var room_feet: Vector2 = scene.call("_room_point", feet_design)
			var room_top_left: Vector2 = room_feet - Vector2(player.size.x * 0.5, player.size.y)
			var blocked: bool = scene.call("_footprint_hits_anything", room_top_left, blockers, boundaries)
			row += "#" if blocked else "."
			x += 5.0
		print("y=%6.1f  %s" % [y, row])
		y += 10.0
	quit()
