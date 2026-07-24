extends SceneTree

## TR-002-BLOCKOUT-01 verification: confirms the 训练中控室 (hub) blockout
## layout -- spawn point, 4 door entrances, center terminal, movable/collision
## bounds -- is geometrically sound using the SAME runtime functions the game
## itself uses (_is_near/_switch_room's movement_bounds formula), then
## produces one annotated screenshot labeling all of the above. Run only
## against an isolated sandbox project copy (separate project.godot
## config/name) so user:// never touches the real project's save directory.
const OUT_DIR := "res://docs/screenshots/training_hub_art"
const SCENE := "res://scenes/training/TrainingBaseMap.tscn"
const DOOR_IDS := ["door_suit", "door_power", "door_air", "door_greenhouse"]
const MOVE_MARGIN := 36.0

var _done := false

## Draws the labeled overlay directly in training_area's own local coordinate
## space (same space player.position / target.position already use), added
## as training_area's last child so it renders on top of everything else.
class BlockoutAnnotationLayer:
	extends Control
	var spawn_center := Vector2.ZERO
	var terminal_rect := Rect2()
	var door_rects: Dictionary = {}
	var movable_bounds := Rect2()

	func _draw() -> void:
		draw_rect(movable_bounds, Color(1, 1, 1, 0.9), false, 2.0)
		draw_string(ThemeDB.fallback_font, movable_bounds.position + Vector2(6, 18), "可移动区域 / 碰撞边界(房间四周)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1))
		draw_rect(terminal_rect, Color(0.3, 0.9, 1.0, 0.95), false, 3.0)
		draw_string(ThemeDB.fallback_font, terminal_rect.position + Vector2(0, -8), "终端位置", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 0.9, 1.0))
		for id in door_rects.keys():
			var info: Dictionary = door_rects[id]
			var rect: Rect2 = info["rect"]
			draw_rect(rect, Color(1.0, 0.7, 0.2, 0.95), false, 3.0)
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, -8), "门位置：%s" % String(info["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.7, 0.2))
		draw_circle(spawn_center, 10.0, Color(0.3, 1.0, 0.4, 0.95))
		draw_string(ThemeDB.fallback_font, spawn_center + Vector2(14, 4), "玩家出生点", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 1.0, 0.4))

func _initialize() -> void:
	call_deferred("_run")
	call_deferred("_force_quit_guard")

func _force_quit_guard() -> void:
	await create_timer(45.0).timeout
	if not _done:
		push_error("Verification script exceeded 45s guard; force quitting.")
		quit(1)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size = Vector2i(1920, 1080)
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.3).timeout
	scene.call("_close_briefing")
	await process_frame
	await create_timer(0.2).timeout

	var training_area: Control = scene.get("training_area")
	var player: Control = scene.get("player")
	var target_nodes: Dictionary = scene.get("target_nodes")
	var spawn_pos: Vector2 = player.position
	var movement_bounds := Rect2(Vector2(MOVE_MARGIN, MOVE_MARGIN), training_area.size - Vector2(MOVE_MARGIN * 2.0, MOVE_MARGIN * 2.0))

	print("== TR-002-BLOCKOUT-01 verification ==")
	print("training_area.size(logical viewport)=", training_area.size)
	print("movement_bounds(=collision boundary)=", movement_bounds)
	print("spawn=", spawn_pos, " player.size=", player.size)
	print("check[spawn inside movable bounds]=", movement_bounds.has_point(spawn_pos + player.size * 0.5))
	print("check[movable bounds fits inside training_area (camera never crops room)]=", training_area.size.x >= 760.0 and training_area.size.y >= 520.0)

	var results: Dictionary = {}
	for door_id in DOOR_IDS:
		results[door_id] = await _walk_toward(scene, player, target_nodes[door_id], spawn_pos, door_id, movement_bounds)
	results["terminal"] = await _walk_toward(scene, player, target_nodes["terminal"], spawn_pos, "terminal", movement_bounds)

	print("== per-target results ==")
	for key in results.keys():
		print(key, " -> ", results[key])

	# Reset to spawn, build the annotation overlay, capture.
	player.position = spawn_pos
	scene.call("_sync_player_visual")
	await process_frame

	var overlay := BlockoutAnnotationLayer.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.spawn_center = spawn_pos + player.size * 0.5
	var terminal: Control = target_nodes["terminal"]
	overlay.terminal_rect = Rect2(terminal.position, terminal.size)
	overlay.movable_bounds = movement_bounds
	for door_id in DOOR_IDS:
		var door: Control = target_nodes[door_id]
		overlay.door_rects[door_id] = {"rect": Rect2(door.position, door.size), "label": door.label_text}
	training_area.add_child(overlay)
	await process_frame
	await process_frame
	await _capture("02_tr002_blockout_verification_annotated.png")

	_done = true
	quit()

## Drives the player toward `target` using the real input actions the game
## itself reads (ui_left/right/up/down), one physics frame at a time via the
## engine's own already-running _process(), then reports whether the game's
## own proximity check (_is_near) confirms the target was actually reached --
## stops there (a few px before entering door rects) so door-crossing/room
## switching never fires mid-test.
func _walk_toward(scene: Node, player: Control, target: Control, spawn_pos: Vector2, target_id: String, movement_bounds: Rect2) -> Dictionary:
	player.position = spawn_pos
	scene.call("_sync_player_visual")
	await process_frame
	var start_pos := player.position
	var out_of_bounds := false
	var reached_near := false
	for i in range(1200):
		var target_center: Vector2 = target.position + target.size * 0.5
		var player_center: Vector2 = player.position + player.size * 0.5
		var to_target: Vector2 = target_center - player_center
		if bool(scene.call("_is_near", target_id)):
			reached_near = true
			break
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
		if not movement_bounds.grow(1.0).has_point(player.position + player.size * 0.5):
			out_of_bounds = true
	return {
		"reached_near": reached_near,
		"moved_distance": start_pos.distance_to(player.position),
		"stayed_in_bounds": not out_of_bounds,
		"final_position": player.position,
	}

func _capture(file_name: String) -> void:
	await process_frame
	await process_frame
	var texture := root.get_texture()
	if texture == null:
		push_error("Viewport texture unavailable. Run WITHOUT --headless.")
		return
	var image := texture.get_image()
	var err := image.save_png("%s/%s" % [OUT_DIR, file_name])
	print("capture ", file_name, " err=", err)
