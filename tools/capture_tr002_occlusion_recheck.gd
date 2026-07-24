extends SceneTree

## The precise-layers comprehensive test's "north approach" occlusion case
## used a hardcoded offset (terminal_blocker.position.y + 10) calibrated
## against the OLD building_front rect (y 185.5-211.5). The new, re-traced
## building_front is a smaller polygon (y roughly 186.5-200.5), so that old
## offset (y=212) now falls entirely outside it. Re-testing with a point
## actually inside the new polygon's own bounds.

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

	# Point well inside the new building_front polygon (design space):
	# roughly the middle of (343.5,194)-(348,186.5)-(424,189.5)-(430.5,200)-(336,200.5).
	var inside_building_front := Vector2(385.0, 193.0)
	player.position = scene.call("_room_point", inside_building_front) - Vector2(player.size.x * 0.5, player.size.y)
	scene.call("_sync_player_visual")
	await process_frame
	await process_frame
	scene.call("_sync_terminal_occlusion")
	await process_frame
	_print_state(scene, "feet inside building_front (expect terminal in front)")

	# Point well inside player_front (design space rect 326.5,222.5 - 110x42).
	var inside_player_front := Vector2(380.0, 240.0)
	player.position = scene.call("_room_point", inside_player_front) - Vector2(player.size.x * 0.5, player.size.y)
	scene.call("_sync_player_visual")
	await process_frame
	await process_frame
	scene.call("_sync_terminal_occlusion")
	await process_frame
	_print_state(scene, "feet inside player_front (expect player in front)")

	quit()

func _print_state(scene: Node, label: String) -> void:
	var player_visual: Node = scene.get("player_visual")
	var terminal_sprite: Node = scene.get("hub_terminal_sprite")
	print(label, " -- player_visual.index=", player_visual.get_index(), " terminal.index=", terminal_sprite.get_index())
