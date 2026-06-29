extends Node

signal state_changed(previous_state: String, current_state: String)

const BOOT := "Boot"
const MAIN_MENU := "MainMenu"
const APPLICATION := "Application"
const TRAINING := "Training"
const LAUNCH := "Launch"
const LANDING := "Landing"
const MOON_SURFACE := "MoonSurface"
const BASE_INTERIOR := "BaseInterior"
const SLEEP := "Sleep"

const DEFAULT_STATES := [
	BOOT,
	MAIN_MENU,
	APPLICATION,
	TRAINING,
	LAUNCH,
	LANDING,
	MOON_SURFACE,
	BASE_INTERIOR,
	SLEEP,
]

var current_state := BOOT
var previous_state := ""
var debug_enabled := true

func change_state(next_state: String) -> void:
	if next_state.is_empty() or next_state == current_state:
		return
	previous_state = current_state
	current_state = next_state
	if debug_enabled:
		print("GameState: %s -> %s" % [previous_state, current_state])
	state_changed.emit(previous_state, current_state)

func is_state(state_name: String) -> bool:
	return current_state == state_name

func serialize() -> Dictionary:
	return {
		"current_state": current_state,
		"previous_state": previous_state,
	}

func deserialize(data: Dictionary) -> void:
	previous_state = String(data.get("previous_state", ""))
	current_state = String(data.get("current_state", BOOT))

func debug_text() -> String:
	return "State %s" % current_state
