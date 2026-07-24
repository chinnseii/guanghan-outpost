extends SceneTree

## TR-002 follow-up (2026-07-24), third attempt: User clarified they are NOT
## trying to enter door_power (they know it's locked) -- they expect to be
## able to walk visually right up to the top wall near 配电房 and stop
## close to it, but instead stop well short, "还有很大的距离". The prior
## test (capture_tr002_door_power_straight_up_check.gd) walked directly
## under the terminal's x-column (326-433) and got blocked BY THE TERMINAL
## at y=270 -- this test instead walks up OFF to the side of the terminal
## (clear of its x-range), where nothing should be in the way except the
## wall itself, to see if the player can actually reach y=96 (the wall's
## real inner edge) there.
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
	var module_data: Dictionary = scene.get("module_data")
	var blockers: Array = module_data.get("blockers", [])

	for start_x in [200.0, 550.0]:
		var start_design := Vector2(start_x, 356.0)
		player.position = scene.call("_room_point", start_design)
		scene.call("_sync_player_visual")
		await process_frame
		for step in range(300):
			Input.action_press("ui_up", 1.0)
			await process_frame
			Input.action_release("ui_up")
		var final_design: Vector2 = scene.call("_design_point_from_room", player.position)
		var final_design_end: Vector2 = scene.call("_design_point_from_room", player.position + player.size)
		var final_rect := Rect2(final_design, final_design_end - final_design)
		print("start_x=", start_x, " FINAL player rect (design)=", final_rect, " top.y=", final_rect.position.y, " (wall inner edge is y=96)")
		for b: Rect2 in blockers:
			if final_rect.grow(6.0).intersects(b):
				print("  near/touching static blocker: ", b)

	_done = true
	quit()
