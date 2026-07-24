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

	var player: Control = scene.get("player")
	var module_data: Dictionary = scene.get("module_data")
	var blockers: Array = module_data.get("blockers", [])
	var boundaries: Array = module_data.get("room_boundary_polygons", [])

	var old_feet_design := Vector2(639, 265)
	var candidate_feet_design := Vector2(645, 271)
	var old_top_left: Vector2 = scene.call("_room_point", old_feet_design) - Vector2(player.size.x * 0.5, player.size.y)
	var candidate_top_left: Vector2 = scene.call("_room_point", candidate_feet_design) - Vector2(player.size.x * 0.5, player.size.y)
	var delta: Vector2 = candidate_top_left - old_top_left

	for fraction in [1.0, 0.5, 0.25, 0.1, 0.05]:
		var partial: Vector2 = old_top_left + delta * fraction
		var blocked: bool = scene.call("_footprint_hits_anything", partial, blockers, boundaries)
		var partial_feet_room: Vector2 = partial + Vector2(player.size.x * 0.5, player.size.y)
		var partial_feet_design: Vector2 = scene.call("_design_point_from_room", partial_feet_room)
		print("fraction=", fraction, " feet_design=", partial_feet_design, " blocked=", blocked)

	print("x_only blocked=", scene.call("_footprint_hits_anything", Vector2(candidate_top_left.x, old_top_left.y), blockers, boundaries))
	print("y_only blocked=", scene.call("_footprint_hits_anything", Vector2(old_top_left.x, candidate_top_left.y), blockers, boundaries))
	quit()
