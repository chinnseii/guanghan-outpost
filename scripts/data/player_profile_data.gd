extends Resource
class_name PlayerProfileData

@export var player_name := ""
@export var birth_year := 2000
@export var gender_display := "男"
@export var application_id := "GHO-APP-2068-0421"
@export var candidate_file_status := "待提交"
@export var mission_identity := "常驻开拓者候选人"
@export var education_background := ""
@export var appearance_preset := "Standard"
@export var skin_preset := "Preset A"
@export var hair_preset := "Short"
@export var hair_color_preset := "Black"
@export var suit_marking := "GH-01"
@export var suit_marking_color := "Blue"
@export var application_submitted := false
@export var application_accepted := false
@export var current_application_step := "identity"
@export var next_scene_after_application := "res://scenes/application/TrainingPlaceholderScene.tscn"

func to_dictionary() -> Dictionary:
	return {
		"PlayerName": player_name,
		"BirthYear": birth_year,
		"GenderDisplay": gender_display,
		"ApplicationId": application_id,
		"CandidateFileStatus": candidate_file_status,
		"MissionIdentity": mission_identity,
		"EducationBackground": education_background,
		"AppearancePreset": appearance_preset,
		"SkinPreset": skin_preset,
		"HairPreset": hair_preset,
		"HairColorPreset": hair_color_preset,
		"SuitMarking": suit_marking,
		"SuitMarkingColor": suit_marking_color,
		"ApplicationSubmitted": application_submitted,
		"ApplicationAccepted": application_accepted,
		"CurrentApplicationStep": current_application_step,
		"NextSceneAfterApplication": next_scene_after_application,
	}

func load_dictionary(data: Dictionary) -> void:
	player_name = String(data.get("PlayerName", player_name))
	birth_year = int(data.get("BirthYear", birth_year))
	gender_display = String(data.get("GenderDisplay", gender_display))
	if gender_display != "女":
		gender_display = "男"
	application_id = String(data.get("ApplicationId", application_id))
	candidate_file_status = String(data.get("CandidateFileStatus", candidate_file_status))
	mission_identity = String(data.get("MissionIdentity", mission_identity))
	education_background = String(data.get("EducationBackground", education_background))
	appearance_preset = String(data.get("AppearancePreset", appearance_preset))
	skin_preset = String(data.get("SkinPreset", skin_preset))
	hair_preset = String(data.get("HairPreset", hair_preset))
	hair_color_preset = String(data.get("HairColorPreset", hair_color_preset))
	suit_marking = String(data.get("SuitMarking", suit_marking))
	suit_marking_color = String(data.get("SuitMarkingColor", suit_marking_color))
	application_submitted = bool(data.get("ApplicationSubmitted", application_submitted))
	application_accepted = bool(data.get("ApplicationAccepted", application_accepted))
	current_application_step = String(data.get("CurrentApplicationStep", current_application_step))
	next_scene_after_application = String(data.get("NextSceneAfterApplication", next_scene_after_application))
