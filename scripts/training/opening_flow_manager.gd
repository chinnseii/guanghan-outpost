extends RefCounted
class_name OpeningFlowManager

const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")

const STAGE_ASSIGNMENT_BLACK_SCREEN := "AssignmentBlackScreen"
const STAGE_AWAITING_ARRIVAL_CINEMATIC := "AwaitingArrivalCinematic"
const ARRIVAL_CINEMATIC := "res://scenes/arrival/ArrivalCinematicScene.tscn"

static func accept_moon_assignment(tree: SceneTree) -> void:
	TrainingManagerScript.accept_assignment(STAGE_ASSIGNMENT_BLACK_SCREEN)
	tree.change_scene_to_file(TrainingManagerScript.BLACK_SCREEN)

static func transition_black_screen_to_arrival(tree: SceneTree) -> void:
	TrainingManagerScript.set_opening_flow_stage(STAGE_AWAITING_ARRIVAL_CINEMATIC, ARRIVAL_CINEMATIC)
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tree.root.add_child(overlay)

	var fade_out := tree.create_tween()
	fade_out.tween_property(overlay, "color:a", 1.0, 0.75)
	await fade_out.finished
	await tree.create_timer(0.45).timeout

	# TODO: Insert formal LaunchSequenceScene / EarthMoonTransferScene / LandingSequenceScene here when art direction is ready.
	tree.change_scene_to_file(ARRIVAL_CINEMATIC)
	await tree.process_frame

	var fade_in := tree.create_tween()
	fade_in.tween_property(overlay, "color:a", 0.0, 0.85)
	await fade_in.finished
	overlay.queue_free()
