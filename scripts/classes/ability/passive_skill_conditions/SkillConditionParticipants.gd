class_name SkillConditionParticipants
extends PassiveSkillCondition

@export var required_participants: int

func is_met(context: SkillContext) -> bool:
	return context.participant_count == required_participants
