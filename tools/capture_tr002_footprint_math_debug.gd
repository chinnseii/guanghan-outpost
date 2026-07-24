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
	print("player.size (room space)=", player.size)
	print("_room_scale()=", scene.call("_room_scale"))

	var feet_design := Vector2(652.0, 246.0)
	var room_feet: Vector2 = scene.call("_room_point", feet_design)
	var room_top_left: Vector2 = room_feet - Vector2(player.size.x * 0.5, player.size.y)
	var design_top_left: Vector2 = scene.call("_design_point_from_room", room_top_left)
	print("feet_design=", feet_design, " -> room_feet=", room_feet, " -> room_top_left=", room_top_left, " -> design_top_left=", design_top_left)

	var footprint_rect: Rect2 = scene.call("_footprint_rect", room_top_left)
	var fp_design_tl: Vector2 = scene.call("_design_point_from_room", footprint_rect.position)
	var fp_design_br: Vector2 = scene.call("_design_point_from_room", footprint_rect.end)
	print("footprint rect (design)=", Rect2(fp_design_tl, fp_design_br - fp_design_tl))

	quit()
