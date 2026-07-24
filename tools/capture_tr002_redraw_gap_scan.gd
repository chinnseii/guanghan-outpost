extends SceneTree

## Grid-scans the region around door_air and door_greenhouse under the NEW
## collision polygon to find where their recess actually opened, since their
## old (round-1) target rects no longer align (see
## capture_tr002_redraw_door_probe.gd -- both target centers came back
## blocked). Prints a compact ASCII grid: '#' = blocked, '.' = open.

const SCENE := "res://scenes/training/TrainingBaseMap.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _scan(scene: Node, module_data: Dictionary, label: String, x0: float, x1: float, y0: float, y1: float, step: float) -> void:
	print("--- ", label, " (x:", x0, "-", x1, " y:", y0, "-", y1, " step=", step, ") ---")
	var y := y0
	while y <= y1:
		var row := ""
		var x := x0
		while x <= x1:
			var room_top_left: Vector2 = scene.call("_room_point", Vector2(x, y))
			var blocked: bool = scene.call("_footprint_hits_anything", room_top_left, module_data.get("blockers", []), module_data.get("collision_polygons", []))
			row += "#" if blocked else "."
			x += step
		print("y=%5.1f  %s" % [y, row])
		y += step

func _run() -> void:
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.3).timeout
	scene.call("_close_briefing")
	await process_frame

	var module_data: Dictionary = scene.get("module_data")

	_scan(scene, module_data, "right wall full sweep (door_air search)", 600.0, 700.0, 90.0, 400.0, 8.0)
	_scan(scene, module_data, "bottom wall full sweep (door_greenhouse search)", 60.0, 700.0, 400.0, 465.0, 8.0)

	quit()
