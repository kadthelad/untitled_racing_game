class_name SkillConditionDistance
extends PassiveSkillCondition

@export var required_distance: int

func is_met(context: SkillContext) -> bool:
	return context.race_distance == required_distance
