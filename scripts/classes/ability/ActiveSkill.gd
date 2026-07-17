class_name ActiveSkill
extends Skill

enum ACTIVATION_PHASES {
	STARTING_GATE,
	END_GOAL,
	STRAIGHTAWAY,
	CORNER,
	PASSING,
	DUELLING,
	SURGING,
}

enum RUNNER_ACTIVE_STAT {
	VELOCITY,
	VISION,
	STAMINA,
	FATIGUE,
}

@export var activation_cause: ACTIVATION_PHASES
@export var skill_duration: float
@export var skill_affects: Dictionary[RUNNER_ACTIVE_STAT, float] # Affects a percentage of an active stat
