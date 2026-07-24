extends SceneTree

## Full-room, position-based scan (not path-based) using the real
## _footprint_hits_anything(), looking for any isolated blocked pocket
## anywhere in the main open floor (excluding the terminal/crate blockers and
## outside-room_boundary areas, which are expected to be blocked). A real
## "invisible wall" that isn't explained by the resolver's diagonal-edge
## limitation (already fixed) would show up here as a blocked cell
## surrounded on most/all sides by open cells, away from any known blocker.

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

	var step := 8.0
	var grid := {}
	var y := 40.0
	while y <= 480.0:
		var x := 40.0
		while x <= 720.0:
			var feet_design := Vector2(x, y)
			var room_feet: Vector2 = scene.call("_room_point", feet_design)
			var room_top_left: Vector2 = room_feet - Vector2(player.size.x * 0.5, player.size.y)
			var blocked: bool = scene.call("_footprint_hits_anything", room_top_left, blockers, boundaries)
			grid[Vector2i(int(x), int(y))] = blocked
			x += step
		y += step

	# Flag any blocked cell whose 4 direct neighbors (same step) are ALL open
	# -- an isolated blocked island, the signature of a real anomaly.
	var anomalies: Array = []
	for key: Vector2i in grid.keys():
		if not grid[key]:
			continue
		var neighbors := [
			Vector2i(key.x + int(step), key.y), Vector2i(key.x - int(step), key.y),
			Vector2i(key.x, key.y + int(step)), Vector2i(key.x, key.y - int(step)),
		]
		var all_neighbors_open := true
		var has_all_neighbors := true
		for n in neighbors:
			if not grid.has(n):
				has_all_neighbors = false
				break
			if grid[n]:
				all_neighbors_open = false
				break
		if has_all_neighbors and all_neighbors_open:
			anomalies.append(key)

	print("total cells scanned=", grid.size(), " isolated blocked-island anomalies=", anomalies.size())
	for a in anomalies:
		print("  anomaly at design=", a)

	quit()
