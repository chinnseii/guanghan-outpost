extends SceneTree

## TR-002 z-index regression check (2026-07-24): User reported the terminal
## rendering ON TOP of the mission briefing popup right at scene entry --
## caused by TerminalFrontOccluder's z_index=3 out-ranking the popup's
## default z_index=0 globally, regardless of tree order. Fixed by rebuilding
## it via tree order (added as a sibling after player_visual, no z_index).
## This captures the briefing popup BEFORE closing it, to directly confirm
## the terminal no longer bleeds through.
const OUT_DIR := "res://docs/screenshots/training_hub_art"
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
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size = Vector2i(1600, 900)
	var scene: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await create_timer(0.3).timeout
	# Deliberately do NOT close the briefing -- capture it exactly as shown
	# at scene entry, matching the User's reported screenshot.
	await _capture("11_master_elements_briefing_popup_zorder.png")
	_done = true
	quit()

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
