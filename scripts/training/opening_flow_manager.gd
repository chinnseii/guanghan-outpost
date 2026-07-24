extends RefCounted
class_name OpeningFlowManager

const TrainingManagerScript := preload("res://scripts/training/training_manager.gd")

const STAGE_ASSIGNMENT_BLACK_SCREEN := "AssignmentBlackScreen"
const STAGE_AWAITING_LAUNCH_SEQUENCE := "AwaitingLaunchSequence"
const STAGE_AWAITING_ARRIVAL_CINEMATIC := "AwaitingArrivalCinematic"
const LAUNCH_SEQUENCE := "res://scenes/training/LaunchSequenceScene.tscn"
const ARRIVAL_CINEMATIC := "res://scenes/arrival/ArrivalCinematicScene.tscn"

static func accept_moon_assignment(tree: SceneTree) -> void:
	TrainingManagerScript.accept_assignment(STAGE_ASSIGNMENT_BLACK_SCREEN)
	tree.change_scene_to_file(TrainingManagerScript.BLACK_SCREEN)

## Hands off from AssignmentBlackScreenScene's text scroll to
## LaunchSequenceScene (launch_01/02/04.ogv + countdown/day-skip text --
## see launch_sequence_scene.gd), which itself continues on to
## ArrivalCinematicScene once its own sequence finishes. This function's
## fade-to-black + scene-change + fade-in is only the handoff INTO the
## launch sequence; LaunchSequenceScene owns all of its own internal
## video/text transitions and its own handoff onward to arrival.
static func transition_black_screen_to_arrival(tree: SceneTree) -> void:
	TrainingManagerScript.set_opening_flow_stage(STAGE_AWAITING_LAUNCH_SEQUENCE, LAUNCH_SEQUENCE)
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tree.root.add_child(overlay)

	var fade_out := tree.create_tween()
	fade_out.tween_property(overlay, "color:a", 1.0, 0.75)
	await fade_out.finished
	await tree.create_timer(0.45).timeout

	tree.change_scene_to_file(LAUNCH_SEQUENCE)
	await tree.process_frame

	var fade_in := tree.create_tween()
	fade_in.tween_property(overlay, "color:a", 0.0, 0.85)
	await fade_in.finished
	overlay.queue_free()

## LaunchSequenceScene's own final handoff onward to ArrivalCinematicScene,
## once launch_04.ogv finishes -- same fade-to-black / change-scene / fade-in
## shape as transition_black_screen_to_arrival() above, kept as its own
## function (rather than having LaunchSequenceScene duplicate the overlay
## dance inline) so both handoffs stay visually identical and there's one
## place to adjust the fade timing for either.
static func transition_launch_sequence_to_arrival(tree: SceneTree) -> void:
	TrainingManagerScript.set_opening_flow_stage(STAGE_AWAITING_ARRIVAL_CINEMATIC, ARRIVAL_CINEMATIC)
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tree.root.add_child(overlay)

	var fade_out := tree.create_tween()
	fade_out.tween_property(overlay, "color:a", 1.0, 0.75)
	await fade_out.finished

	tree.change_scene_to_file(ARRIVAL_CINEMATIC)
	await tree.process_frame

	var fade_in := tree.create_tween()
	fade_in.tween_property(overlay, "color:a", 0.0, 0.85)
	await fade_in.finished
	overlay.queue_free()
