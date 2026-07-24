extends SceneTree

## Direct probe (2026-07-24): bypasses movement simulation entirely and asks
## the game's own _resolve_blockers()/_footprint_hits_anything() whether a
## specific design-space position (x=380, various y) is blocked, to find the
## TRUE boundary without any confound from player_controller's per-frame
## speed/delta interacting with the resolver's all-or-nothing candidate
## acceptance.
const SCENE := "res://scenes/training/TrainingBaseMap.tscn"
var _done := false

func _initialize() -> void:
	call_deferred("_run")
	call_deferred("_force_quit_guard")

func _force_quit_guard() -> void:
	await create_timer(30.0).timeout
	if not _done:
		push_error("Verification script exceeded 30s guard; force quitting.")
		quit(1)

func _run() -> void:
	root.size = Vector2i(1600, 900)
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.3).timeout
	scene.call("_close_briefing")
	await process_frame
	await create_timer(0.2).timeout

	var player: Control = scene.get("player")
	var module_data: Dictionary = scene.get("module_data")
	var blockers: Array = module_data.get("blockers", [])
	var polygons: Array = module_data.get("collision_polygons", [])

	print("player.size (room space)=", player.size)
	print("--- door_greenhouse approach (x=365.3, varying y) ---")
	for y in range(350, 470, 5):
		var design_top_left := Vector2(365.3, float(y))
		var room_top_left: Vector2 = scene.call("_room_point", design_top_left)
		var blocked: bool = scene.call("_footprint_hits_anything", room_top_left, blockers, polygons)
		print("design y=", y, " (top-left, x=365.3) blocked=", blocked)

	print("--- door_air approach (y=246, varying x) ---")
	for x in range(560, 680, 5):
		var design_top_left2 := Vector2(float(x), 219.0)
		var room_top_left2: Vector2 = scene.call("_room_point", design_top_left2)
		var blocked2: bool = scene.call("_footprint_hits_anything", room_top_left2, blockers, polygons)
		print("design x=", x, " (top-left, y=219) blocked=", blocked2)

	_done = true
	quit()
