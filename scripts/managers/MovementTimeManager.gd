extends Node

## Turns player movement into a real, budgeted action instead of a free
## camera pan: every tile moved accumulates fractional minutes in a buffer
## (so indoor movement doesn't feel punishing), and once a whole minute is
## banked it gets pushed to whichever time system actually owns the clock
## right now -- the real TimeManager during the mission, or
## TrainingTimeManager during ground training (never both, see
## flush_movement_time()). Explicitly out of scope this round: forcing a
## full minute per tile, direct large energy drains from walking, movement
## failure/falling/random accidents, real pathfinding time estimates,
## coordinate-level physics speed, and vehicles.

var base_move_tiles_per_minute: float = 10.0
var movement_time_buffer: float = 0.0
var min_move_multiplier: float = 0.30

func reset_to_arrival() -> void:
	movement_time_buffer = 0.0

## -- Core interface

## Call this whenever the player has moved `tile_count` tiles (whatever a
## "tile" means to the caller -- player_controller_2d.gd treats one
## 64px step as one tile). `context` picks which real clock gets advanced:
## "mission" (default) -> TimeManager, "training" -> TrainingTimeManager.
func on_player_moved_tiles(tile_count: int, terrain_type: String = "indoor", context: String = "mission") -> void:
	var minutes := calculate_move_minutes(tile_count, terrain_type)
	if minutes <= 0.0:
		return
	movement_time_buffer += minutes
	flush_movement_time(terrain_type, context)

func calculate_move_minutes(tile_count: int, terrain_type: String = "indoor") -> float:
	if tile_count <= 0:
		return 0.0
	var final_multiplier := get_final_move_multiplier(terrain_type)
	var actual_speed: float = base_move_tiles_per_minute * final_multiplier
	if actual_speed <= 0.0:
		return 0.0
	return float(tile_count) / actual_speed

## Only actually advances a time system once a whole minute has accumulated
## in the buffer -- the leftover fraction stays banked for next time. This
## is the one place that decides mission vs. training, and the one place
## that charges the suit for however many whole minutes just got spent.
func flush_movement_time(terrain_type: String = "indoor", context: String = "mission") -> void:
	if movement_time_buffer < 1.0:
		return
	var whole_minutes: int = int(floor(movement_time_buffer))
	movement_time_buffer -= float(whole_minutes)
	if context == "training":
		var training_time_manager := _training_time_manager()
		if training_time_manager != null and training_time_manager.has_method("advance_training_time"):
			training_time_manager.call("advance_training_time", whole_minutes, "training_move")
	else:
		var time_manager := _time_manager()
		if time_manager != null and time_manager.has_method("advance_time"):
			# "move" is deliberately reused from the pre-existing movement
			# reason string -- TimeManager already excludes it from
			# Health/Power/Water's one-time action-cost billing, so walking
			# only ever costs time, not a surprise extra resource hit.
			time_manager.call("advance_time", whole_minutes, "move")
	_consume_suit_resources_for_move(whole_minutes, terrain_type)

## -- Multipliers

func get_final_move_multiplier(terrain_type: String = "indoor") -> float:
	var health_multiplier := get_health_move_multiplier()
	var suit_multiplier := get_suit_move_multiplier()
	var load_multiplier := get_load_move_multiplier()
	var terrain_multiplier := get_terrain_move_multiplier(terrain_type)
	var final_multiplier: float = health_multiplier * suit_multiplier * load_multiplier * terrain_multiplier
	return max(final_multiplier, min_move_multiplier)

func get_health_move_multiplier() -> float:
	var health_manager := _health_manager()
	if health_manager == null or not health_manager.has_method("get_movement_health_multiplier"):
		return 1.0
	return float(health_manager.call("get_movement_health_multiplier"))

## 1.0 whenever the suit isn't worn -- being carried/stowed shouldn't slow
## anyone down; only actually wearing it applies its speed multiplier.
func get_suit_move_multiplier() -> float:
	var suit_manager := _suit_manager()
	if suit_manager == null:
		return 1.0
	if not bool(suit_manager.get("is_suit_worn")):
		return 1.0
	if not suit_manager.has_method("get_suit_speed_multiplier"):
		return 1.0
	return float(suit_manager.call("get_suit_speed_multiplier"))

func get_load_move_multiplier() -> float:
	var backpack_manager := _backpack_manager()
	if backpack_manager == null or not backpack_manager.has_method("get_load_level"):
		return 1.0
	var load_level := int(backpack_manager.call("get_load_level"))
	match load_level:
		1:
			return 1.0
		2:
			return 0.95
		3:
			return 0.85
		4:
			return 0.70
	return 1.0

func get_terrain_move_multiplier(terrain_type: String) -> float:
	match terrain_type:
		"indoor":
			return 1.0
		"old_base_clutter":
			return 0.85
		"lunar_flat":
			return 0.75
		"lunar_rough":
			return 0.60
	return 1.0

## -- Suit resource drain while moving

func _consume_suit_resources_for_move(minutes: int, terrain_type: String) -> void:
	if minutes <= 0:
		return
	var suit_manager := _suit_manager()
	if suit_manager == null:
		return
	var activity_type := get_suit_activity_type(terrain_type)
	if activity_type == "none":
		return
	if suit_manager.has_method("consume_suit_resources"):
		suit_manager.call("consume_suit_resources", minutes, activity_type)

## Lunar surface terrain always counts as an EVA activity regardless of
## suit state (consume_suit_resources() itself is a no-op if the suit isn't
## worn, so this doesn't double-guard); indoor movement only drains the
## suit if it's actually being worn around the base.
func get_suit_activity_type(terrain_type: String) -> String:
	if terrain_type == "lunar_flat" or terrain_type == "lunar_rough":
		return "eva_normal"
	var suit_manager := _suit_manager()
	if suit_manager != null and bool(suit_manager.get("is_suit_worn")):
		return "indoor_worn"
	return "none"

## -- Cross-system helpers

func _time_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TimeManager")

func _training_time_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TrainingTimeManager")

func _health_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("HealthManager")

func _suit_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("SuitManager")

func _backpack_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("BackpackManager")

## -- Debug helpers

func debug_values_text() -> String:
	return "\n".join([
		"MovementTimeManager: buffer=%.3f min" % movement_time_buffer,
		"multipliers: health=%.2f suit=%.2f load=%.2f (min floor=%.2f)" % [
			get_health_move_multiplier(), get_suit_move_multiplier(), get_load_move_multiplier(), min_move_multiplier,
		],
	])

func debug_simulate_move(tile_count: int = 10, terrain_type: String = "indoor", context: String = "mission") -> void:
	on_player_moved_tiles(tile_count, terrain_type, context)

func debug_reset() -> void:
	reset_to_arrival()
