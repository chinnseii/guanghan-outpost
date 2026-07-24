extends SceneTree

const SCENE := "res://scenes/training/TrainingBaseMap.tscn"
var _done := false

func _initialize() -> void:
	call_deferred("_run")
	call_deferred("_force_quit_guard")

func _force_quit_guard() -> void:
	await create_timer(45.0).timeout
	if not _done:
		push_error("Verification script exceeded 45s guard; force quitting.")
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
	var target_nodes: Dictionary = scene.get("target_nodes")
	var module_data: Dictionary = scene.get("module_data")
	var areas: Dictionary = scene.get("areas")
	print("areas[suit_prep_room].unlocked=", areas.get("suit_prep_room", {}).get("unlocked", "MISSING"))

	var door_node: Control = target_nodes["door_suit"]
	print("door_suit real target rect (room space)=", Rect2(door_node.position, door_node.size))
	var real_center: Vector2 = door_node.position + door_node.size * 0.5
	print("door_suit real center (room space)=", real_center, " design=", scene.call("_design_point_from_room", real_center))

	var spawn_room: Vector2 = scene.call("_room_point", Vector2(359, 356))
	player.position = spawn_room
	scene.call("_sync_player_visual")
	await process_frame

	var current_area_before: String = scene.get("current_area_id")
	print("current_area_id before walk=", current_area_before)

	for step in range(600):
		if scene.get("current_area_id") != current_area_before:
			print("ROOM SWITCHED at step ", step, " to ", scene.get("current_area_id"))
			break
		var player_center: Vector2 = player.position + player.size * 0.5
		var to_target: Vector2 = real_center - player_center
		if to_target.length() < 4.0:
			print("reached target center without switching (stuck)")
			break
		var dir: Vector2 = to_target.normalized()
		Input.action_press("ui_left", max(0.0, -dir.x))
		Input.action_press("ui_right", max(0.0, dir.x))
		Input.action_press("ui_up", max(0.0, -dir.y))
		Input.action_press("ui_down", max(0.0, dir.y))
		await process_frame
		Input.action_release("ui_left")
		Input.action_release("ui_right")
		Input.action_release("ui_up")
		Input.action_release("ui_down")

	if scene.get("current_area_id") == current_area_before:
		print("FINAL: still in hub, player.position=", player.position, " design=", scene.call("_design_point_from_room", player.position))
	else:
		print("FINAL: switched rooms successfully to ", scene.get("current_area_id"))

	_done = true
	quit()
