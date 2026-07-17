class_name SkillConditionGround
extends PassiveSkillCondition

@export var required_ground: GroundData.GROUND_TYPES

func is_met(context: SkillContext) -> bool:
	return context.ground_type == required_ground
