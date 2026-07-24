extends SceneTree

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
	Engine.max_fps = 60
	root.size = Vector2i(1600, 900)
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.3).timeout
	scene.call("_close_briefing")
	await process_frame
	await create_timer(0.2).timeout

	var player: Control = scene.get("player")
	print("start player.position(room)=", player.position, " design=", scene.call("_design_point_from_room", player.position))

	for step in range(300):
		if not is_instance_valid(player):
			break
		var player_center: Vector2 = player.position + player.size * 0.5
		var target_room: Vector2 = scene.call("_room_point", Vector2(380.0, 432.0))
		var to_target: Vector2 = target_room - player_center
		if to_target.length() < 4.0:
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
		if step % 20 == 0:
			print("step=", step, " design=", scene.call("_design_point_from_room", player.position))

	print("FINAL design=", scene.call("_design_point_from_room", player.position))
	_done = true
	quit()
