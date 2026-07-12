class_name BaseNavigationController
extends RefCounted

## BaseNavigationController (P4-05): stateless navigation-computation helpers extracted from
## sprint06_base_scene.gd. Pure functions -- given the player position, the scene kind, and the
## scene's target rect maps, it computes the current interaction target, the terrain type, and
## proximity. It owns NO state, performs NO Manager writes, NO save, and NO scene transition.
##
## Deliberately NARROW (P4-05A interface-prep scope): sprint06 navigation is largely flow-coupled
## -- `current_target` is consumed by ~40 flow sites, `_transition_to` is driven by task
## completion + input/fade UI, and `_interaction_target_rect` is dense with day/schedule/state
## logic. Those all stay in the scene. Only the safely-separable pure computation moves here, to
## establish a testable navigation interface without touching task/schedule/transition behavior.

const InteractionAreaScript := preload("res://scripts/controllers/interaction_area_2d.gd")

## Per-scene terrain default (no per-tile terrain map exists; scene_kind is the only signal).
func terrain_type_for(scene_kind: String) -> String:
	if scene_kind == "solar_array":
		return "lunar_flat"
	return "indoor"

func is_near(player_pos: Vector2, rect: Rect2) -> bool:
	return InteractionAreaScript.is_point_near_rect(player_pos, rect, 44.0)

## Current interaction-target key for the given position/scene, or "" if none. Behaviour mirrors
## the scene's previous _update_target() exactly (same iteration order, same sleep radius).
func compute_current_target(player_pos: Vector2, scene_kind: String, interior_targets: Dictionary, greenhouse_targets: Dictionary) -> String:
	if scene_kind == "interior":
		for key in interior_targets.keys():
			if is_near(player_pos, interior_targets[key]):
				return String(key)
	elif scene_kind == "greenhouse":
		for key in greenhouse_targets.keys():
			if is_near(player_pos, greenhouse_targets[key]):
				return String(key)
	elif scene_kind == "day_end" and player_pos.distance_to(Vector2(760, 570)) < 96.0:
		return "sleep"
	elif scene_kind == "day02_end" and player_pos.distance_to(Vector2(760, 570)) < 96.0:
		return "sleep"
	elif scene_kind == "week_end" and player_pos.distance_to(Vector2(760, 570)) < 96.0:
		return "sleep"
	return ""
