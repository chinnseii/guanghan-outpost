extends Area2D
class_name Interactable

@export var data: Resource
@export var fallback_label := "Interact"
@export var disabled := false

signal interacted(interactable: Interactable, player: Node)

func can_interact(_player: Node) -> bool:
	return not disabled

func get_interaction_label() -> String:
	if data != null:
		var label: Variant = data.get("interaction_label")
		if label != null and not String(label).is_empty():
			return String(label)
		var display_name: Variant = data.get("display_name")
		if display_name != null and not String(display_name).is_empty():
			return String(display_name)
	return fallback_label

func interact(player: Node) -> void:
	if not can_interact(player):
		return
	interacted.emit(self, player)
