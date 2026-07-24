extends SceneTree

## Correctly-converted grid scan (feet point -> top-left, matching
## _footprint_rect()'s own anchoring, and using the CURRENT room_boundary
## model via _rect_outside_all_room_boundaries()) across door_air's real
## target rect, to properly explain why the walk-simulation test stopped
## ~10px short of center this round.

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

	print("--- door_air target rect design=(633.5,205)-(37,82), scanning full rect ---")
	var y := 209.0
	while y <= 281.0:
		var row := ""
		var x := 637.5
		while x <= 666.5:
			var feet_design := Vector2(x, y)
			var room_feet: Vector2 = scene.call("_room_point", feet_design)
			var room_top_left: Vector2 = room_feet - Vector2(player.size.x * 0.5, player.size.y)
			var blocked: bool = scene.call("_footprint_hits_anything", room_top_left, blockers, boundaries)
			row += "#" if blocked else "."
			x += 3.0
		print("y=%6.1f  %s" % [y, row])
		y += 6.0
	quit()
