extends SceneTree

## Confirms the widened door_suit gap tolerance (2026-07-22): approaches
## from a y that would have missed the OLD 232-328 gap (e.g. design y=220,
## just outside it) and checks crossing still succeeds now that both the
## wall gap AND the door's own target rect extend 212-348. Loop condition
## uses the same "feet point" (bottom-center, not center) the real crossing
## check (_is_inside_target_area) uses, to avoid the test's own aim logic
## silently diverging from what actually gets checked.
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
	var current_area_before: String = scene.get("current_area_id")

	for design_y in [220.0, 340.0]:
		player.position = scene.call("_room_point", Vector2(200, design_y))
		scene.call("_sync_player_visual")
		await process_frame
		var target_room: Vector2 = scene.call("_room_point", Vector2(50, design_y))
		var switched := false
		for step in range(600):
			if scene.get("current_area_id") != current_area_before:
				switched = true
				break
			if bool(scene.call("_is_inside_target_area", "door_suit")):
				switched = true
				break
			var player_feet: Vector2 = player.position + Vector2(player.size.x * 0.5, player.size.y)
			var to_target: Vector2 = target_room - player_feet
			var dir: Vector2 = to_target.normalized() if to_target.length() > 0.001 else Vector2.ZERO
			Input.action_press("ui_left", max(0.0, -dir.x))
			Input.action_press("ui_right", max(0.0, dir.x))
			Input.action_press("ui_up", max(0.0, -dir.y))
			Input.action_press("ui_down", max(0.0, dir.y))
			await process_frame
			Input.action_release("ui_left")
			Input.action_release("ui_right")
			Input.action_release("ui_up")
			Input.action_release("ui_down")
		print("approach at design_y=", design_y, " (west, off old-center) -> reached_target_or_switched=", switched, " current_area_id=", scene.get("current_area_id"), " final player.position=", player.position)
		if scene.get("current_area_id") != current_area_before:
			break

	_done = true
	quit()
