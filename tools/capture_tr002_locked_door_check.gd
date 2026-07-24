extends SceneTree

## Confirms door_openings' "only counts while unlocked" gating actually
## holds: in a completely fresh scene (no progress), air_system_control_room
## and greenhouse_room are locked by default (_compute_unlocked()), so their
## target centers should stay BLOCKED -- same as before this fix -- rather
## than being permanently open regardless of lock state.

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
	var targets_by_id := {}
	for t: Dictionary in module_data.get("targets", []):
		targets_by_id[String(t["id"])] = t

	var areas: Dictionary = scene.get("areas")
	print("air locked?", not bool((areas.get("air_system_control_room", {}) as Dictionary).get("unlocked", false)))
	print("greenhouse locked?", not bool((areas.get("greenhouse_room", {}) as Dictionary).get("unlocked", false)))
	var openings: Array = scene.call("_effective_door_openings")
	print("effective_door_openings count right before test=", openings.size())

	for id in ["door_air", "door_greenhouse"]:
		var t: Dictionary = targets_by_id[id]
		var center: Vector2 = Vector2(t["position"]) + Vector2(t["size"]) * 0.5
		var room_feet: Vector2 = scene.call("_room_point", center)
		var room_top_left: Vector2 = room_feet - Vector2(player.size.x * 0.5, player.size.y)
		var footprint: Rect2 = scene.call("_footprint_rect", room_top_left)
		var polygons: Array = module_data.get("collision_polygons", [])
		var wall_only_blocked: bool = scene.call("_rect_hits_any_polygon_blocker", footprint, polygons)
		var opening_hit: bool = scene.call("_rect_hits_any_polygon_blocker", footprint, openings)
		var blocked: bool = scene.call("_footprint_hits_anything", room_top_left, module_data.get("blockers", []), module_data.get("collision_polygons", []))
		print(id, " center=", center, " wall_only_blocked=", wall_only_blocked, " opening_hit=", opening_hit, " final_blocked=", blocked, " -- expect true (locked)")

	quit()
