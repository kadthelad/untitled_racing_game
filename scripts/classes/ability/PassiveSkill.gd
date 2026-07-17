class_name PassiveSkill
extends Skill

@export var conditions: Array[PassiveSkillCondition]
@export var stat_bonus: Dictionary[Runner.STATS, int] = {} # How much will it add in a stat as a bonus

func can_activate(context: SkillContext) -> bool:
	for condition: PassiveSkillCondition in conditions:
		if !condition.is_met(context):
			return false
	return true
