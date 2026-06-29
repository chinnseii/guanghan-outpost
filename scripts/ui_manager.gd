extends Node

var root: Control
var hud_visible := true

func bind_root(new_root: Control) -> void:
	root = new_root

func set_hud_visible(visible: bool) -> void:
	hud_visible = visible
	if not is_instance_valid(root):
		return
	for child in root.get_children():
		if child is CanvasItem and String(child.name) not in ["MainMenu", "FadeLayer"]:
			(child as CanvasItem).visible = visible

func show_prompt(text: String) -> void:
	if not is_instance_valid(root) or not root.has_node("Hint"):
		return
	var hint: Label = root.get_node("Hint")
	hint.text = text
	hint.visible = not text.is_empty()

func show_dialogue(text: String) -> void:
	if not is_instance_valid(root):
		return
	if root.has_node("DialogueBox"):
		var label: Label = root.get_node("DialogueBox/Text")
		label.text = text
		var box: CanvasItem = root.get_node("DialogueBox")
		box.visible = true

func hide_dialogue() -> void:
	if is_instance_valid(root) and root.has_node("DialogueBox"):
		var box: CanvasItem = root.get_node("DialogueBox")
		box.visible = false

func debug_text() -> String:
	return "HUD %s" % ("on" if hud_visible else "off")
