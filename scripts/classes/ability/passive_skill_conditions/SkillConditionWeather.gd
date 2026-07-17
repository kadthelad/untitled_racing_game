class_name SkillConditionWeather
extends PassiveSkillCondition

@export var required_weather: Weather.WEATHER_TYPES

func is_met(context: SkillContext) -> bool:
	return context.current_weather == required_weather
