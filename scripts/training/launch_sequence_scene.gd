extends Control

## LAUNCH-SEQ-01 Round 2 (2026-07-18): fills in the "TODO: Insert formal
## LaunchSequenceScene..." placeholder opening_flow_manager.gd's
## transition_black_screen_to_arrival() carried since the opening flow was
## first built. Plays the User's delivered launch videos
## (assets/ui/launch/launch_01..05.ogv) between AssignmentBlackScreenScene's
## text scroll and ArrivalCinematicScene.
##
## Sequence (matches the User's Round 2 spec, since revised once more --
## see Round 2 follow-up notes in ACTIVE_TASKS.md -- alternating video /
## scrolling-narration beats, plus a short big-centered countdown just
## before ignition):
## launch_01.ogv -> scroll ("你凝望脚下的土地..." x3 lines) -> launch_02.ogv ->
## scroll ("耳机传来数秒声" / "10，9，8，7，" / "6，5，4", 3 lines) ->
## countdown (3,2,1,点火, 1s each, big & centered) -> launch_03.ogv -> scroll
## ("距离发射已经过去了三天后..." x2 lines) -> launch_04.ogv -> scroll ("透过
## 舷窗..." x6 lines) -> launch_05.ogv -> handoff to ArrivalCinematicScene
## (OpeningFlowManager.transition_launch_sequence_to_arrival(), the same
## fade-to-black/change-scene/fade-in shape the black-screen->launch
## handoff already uses).
##
## The scrolling-narration beats deliberately reuse
## AssignmentBlackScreenScene's own look (font size 30, #d8e7f2, lines
## accumulating with a blank line between them, ~1.15s per line) since the
## User asked for "类似截图那种滚动文字" pointing at that exact scene's
## screenshot -- not a new text style.
const OpeningFlowManagerScript := preload("res://scripts/training/opening_flow_manager.gd")

const LAUNCH_01 := "res://assets/ui/launch/launch_01.ogv"
const LAUNCH_02 := "res://assets/ui/launch/launch_02.ogv"
const LAUNCH_03 := "res://assets/ui/launch/launch_03.ogv"
const LAUNCH_04 := "res://assets/ui/launch/launch_04.ogv"
const LAUNCH_05 := "res://assets/ui/launch/launch_05.ogv"
## Native resolution per video (ffprobe), used for the same hard-coded
## "cover-fill scale" approach main.gd's title background video already
## uses, since VideoStreamPlayer.get_size() isn't reliably available before
## the first frame decodes. launch_01/04/05 are 1920x1024 @ 24fps;
## launch_02/03 are separate footage at 2026x1080 @ 30fps -- each needs its
## own entry here so cover-fill scaling doesn't stretch/crop using the
## wrong aspect ratio.
const VIDEO_NATIVE_SIZE := {
	LAUNCH_01: Vector2(1920.0, 1024.0),
	LAUNCH_02: Vector2(2026.0, 1080.0),
	LAUNCH_03: Vector2(2026.0, 1080.0),
	LAUNCH_04: Vector2(1920.0, 1024.0),
	LAUNCH_05: Vector2(1920.0, 1024.0),
}

const SCROLL_LINE_SECONDS := 1.15
const SCROLL_FONT_SIZE := 30
const SCROLL_TEXT_COLOR := Color("#d8e7f2")

const COUNTDOWN_STEPS := ["3", "2", "1", "点火"]
const COUNTDOWN_STEP_SECONDS := 1.0
const COUNTDOWN_FONT_SIZE := 140
const COUNTDOWN_TEXT_COLOR := Color("#eaf4ff")

var background: ColorRect
var video_player: VideoStreamPlayer
var message_label: Label
var _current_video_native_size := Vector2(1920.0, 1024.0)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	background = ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	message_label = Label.new()
	message_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.visible = false
	add_child(message_label)

	call_deferred("_run_sequence")


func _run_sequence() -> void:
	await _play_video(LAUNCH_01)
	await _play_scrolling_text([
		"你凝望脚下的土地，",
		"而后一步一步走向发射架，",
		"缓慢却坚定。",
	])
	await _play_video(LAUNCH_02)
	await _play_scrolling_text([
		"耳机传来数秒声",
		"10，9，8，7，",
		"6，5，4",
	])
	await _play_countdown()
	await _play_video(LAUNCH_03)
	await _play_scrolling_text([
		"距离发射已经过去了三天，",
		"月球已经清晰可见",
	])
	await _play_video(LAUNCH_04)
	await _play_scrolling_text([
		"透过舷窗，",
		"你清晰的看到了月球基地，",
		"广寒前哨，",
		"飞船即将降落，",
		"你即将接管基地，",
		"成为新的开拓者",
	])
	await _play_video(LAUNCH_05)
	await OpeningFlowManagerScript.transition_launch_sequence_to_arrival(get_tree())


func _play_video(path: String) -> void:
	var stream: VideoStream = load(path) as VideoStream if ResourceLoader.exists(path) else null
	if stream == null:
		push_error("LaunchSequenceScene: missing or unreadable video %s -- skipping." % path)
		return
	if video_player == null:
		video_player = VideoStreamPlayer.new()
		video_player.name = "LaunchVideo"
		video_player.autoplay = false
		video_player.expand = true
		video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(video_player)
		move_child(video_player, background.get_index() + 1)
		resized.connect(_resize_video)
	video_player.stream = stream
	_current_video_native_size = VIDEO_NATIVE_SIZE.get(path, Vector2(1920.0, 1024.0))
	_resize_video()
	video_player.visible = true
	video_player.play()
	await video_player.finished
	video_player.visible = false
	video_player.stop()


func _resize_video() -> void:
	if video_player == null:
		return
	var avail: Vector2 = size
	if avail.x <= 0.0 or avail.y <= 0.0:
		return
	var fill_scale: float = max(avail.x / _current_video_native_size.x, avail.y / _current_video_native_size.y)
	var draw_size: Vector2 = _current_video_native_size * fill_scale
	video_player.size = draw_size
	video_player.position = (avail - draw_size) * 0.5


## Matches AssignmentBlackScreenScene's own scrolling-narration look exactly
## (same font size/color/per-line timing) since the User pointed at that
## scene's screenshot as the reference style -- lines accumulate one at a
## time with a blank line between them; once the last line has had its full
## on-screen interval, the text clears and the sequence moves on (same
## "no extra hold" behavior that scene's own _process() uses).
func _play_scrolling_text(lines: Array) -> void:
	message_label.add_theme_font_size_override("font_size", SCROLL_FONT_SIZE)
	message_label.modulate = SCROLL_TEXT_COLOR
	message_label.text = ""
	message_label.visible = true
	for line in lines:
		message_label.text += ("\n\n" if not message_label.text.is_empty() else "") + line
		await get_tree().create_timer(SCROLL_LINE_SECONDS).timeout
	message_label.visible = false
	message_label.text = ""


## Big centered hard-cut countdown for the final "3,2,1,点火" beat only
## (the lead-up "10..4" reads as scrolling narration instead -- see
## _run_sequence()); each step replaces the previous one directly, 1s per
## step, ending on "点火".
func _play_countdown() -> void:
	message_label.add_theme_font_size_override("font_size", COUNTDOWN_FONT_SIZE)
	message_label.modulate = COUNTDOWN_TEXT_COLOR
	message_label.visible = true
	for step in COUNTDOWN_STEPS:
		message_label.text = step
		await get_tree().create_timer(COUNTDOWN_STEP_SECONDS).timeout
	message_label.visible = false
	message_label.text = ""
