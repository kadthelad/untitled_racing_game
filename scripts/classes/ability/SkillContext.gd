class_name SkillContext
extends RefCounted

var participant_count: int
var current_weather: Weather.WEATHER_TYPES
var ground_type: GroundData.GROUND_TYPES
var race_distance: int

func _init(p_participant_count: int, p_weather: Weather.WEATHER_TYPES, 
			p_ground_type: GroundData.GROUND_TYPES, p_race_distance: int) -> void:
	participant_count = p_participant_count
	current_weather = p_weather
	ground_type = p_ground_type
	race_distance = p_race_distance
