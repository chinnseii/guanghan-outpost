extends SceneTree

## Definitive re-check: earlier grid scans (capture_tr002_redraw_gap_scan.gd,
## the pre-fix capture_tr002_redraw_door_probe.gd) fed design coordinates
## directly as "top_left" into _footprint_hits_anything(), but that function
## builds its footprint anchored near the BOTTOM of a player.size-tall region
## below that point (see _footprint_rect()) -- i.e. every one of those scans
## was actually testing a point roughly (player.size.y - footprint_height)
## room-px SOUTH of the labeled coordinate, not the coordinate itself. That
## offset bug is the likely reason door_air/door_greenhouse looked like they
## had no wall gap at all. This re-checks all 4 door target centers against
## the RAW collision polygon only (no door_openings exception involved),
## using the corrected feet->top_left conversion, to get real ground truth.

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
	var polygons: Array = module_data.get("collision_polygons", [])
	var targets_by_id := {}
	for t: Dictionary in module_data.get("targets", []):
		targets_by_id[String(t["id"])] = t

	for id in ["door_power", "door_air", "door_greenhouse", "door_suit"]:
		var t: Dictionary = targets_by_id[id]
		var pos: Vector2 = t["position"]
		var size: Vector2 = t["size"]
		print("--- ", id, " target rect design=", Rect2(pos, size), " ---")
		# Sample a grid of feet points covering the whole target rect, not
		# just its center, to see how much of the door's real target area is
		# genuinely open under the raw wall polygon alone.
		var step := 6.0
		var y := pos.y + 4.0
		while y <= pos.y + size.y - 4.0:
			var row := ""
			var x := pos.x + 4.0
			while x <= pos.x + size.x - 4.0:
				var feet_design := Vector2(x, y)
				var room_feet: Vector2 = scene.call("_room_point", feet_design)
				var room_top_left: Vector2 = room_feet - Vector2(player.size.x * 0.5, player.size.y)
				var footprint: Rect2 = scene.call("_footprint_rect", room_top_left)
				var blocked: bool = scene.call("_rect_hits_any_polygon_blocker", footprint, polygons)
				row += "#" if blocked else "."
				x += step
			print("  y=%6.1f  %s" % [y, row])
			y += step

	quit()
