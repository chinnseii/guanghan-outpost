extends SceneTree

## Same correctly-converted (feet -> top-left via player.size, matching
## _footprint_rect()'s own anchoring) grid scan as
## capture_tr002_door_air_grid_scan.gd, run across all 4 door target rects
## with the CURRENT room_boundary_polygons + blockers, using the real
## _footprint_hits_anything(). This is the authoritative check -- unlike a
## quick idealized-point sanity test, it reproduces exactly what the game's
## own resolver sees.

const SCENE := "res://scenes/training/TrainingBaseMap.tscn"

func _initialize() -> void:
	call_deferred("_run")

func _scan(scene: Node, player: Control, blockers: Array, boundaries: Array, label: String, rect: Rect2) -> void:
	print("--- ", label, " design=", rect, " ---")
	var y := rect.position.y + 4.0
	while y <= rect.position.y + rect.size.y - 4.0:
		var row := ""
		var x := rect.position.x + 4.0
		while x <= rect.position.x + rect.size.x - 4.0:
			var feet_design := Vector2(x, y)
			var room_feet: Vector2 = scene.call("_room_point", feet_design)
			var room_top_left: Vector2 = room_feet - Vector2(player.size.x * 0.5, player.size.y)
			var blocked: bool = scene.call("_footprint_hits_anything", room_top_left, blockers, boundaries)
			row += "#" if blocked else "."
			x += 4.0
		print("  y=%6.1f  %s" % [y, row])
		y += 6.0

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
	var targets_by_id := {}
	for t: Dictionary in module_data.get("targets", []):
		targets_by_id[String(t["id"])] = t

	for id in ["door_power", "door_air", "door_greenhouse", "door_suit"]:
		var t: Dictionary = targets_by_id[id]
		_scan(scene, player, blockers, boundaries, id, Rect2(t["position"], t["size"]))

	quit()
