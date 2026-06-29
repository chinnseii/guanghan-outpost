extends Area2D
class_name InteractionDetector

signal focused_interactable_changed(interactable: Node)

var focused_interactable: Node

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func get_focused_label() -> String:
	if focused_interactable != null and focused_interactable.has_method("get_interaction_label"):
		return String(focused_interactable.call("get_interaction_label"))
	return ""

func try_interact(player: Node) -> bool:
	if focused_interactable == null:
		return false
	if focused_interactable.has_method("can_interact") and not bool(focused_interactable.call("can_interact", player)):
		return false
	if focused_interactable.has_method("interact"):
		focused_interactable.call("interact", player)
		return true
	return false

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("interact"):
		focused_interactable = area
		focused_interactable_changed.emit(focused_interactable)

func _on_area_exited(area: Area2D) -> void:
	if area == focused_interactable:
		focused_interactable = null
		focused_interactable_changed.emit(null)
