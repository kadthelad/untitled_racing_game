class_name Skill
extends Resource
 
@export var i_name: String = "UNNAMED SKILL" 
@export_multiline var description: String = "SKILL DESCRIPTION"
@export var focus_cost: int = 0 # How much focus is needed to equip it
@export var skill_points_cost: int = 0 # How much does it cost to unlock
@export var skill_icon: Texture2D = PlaceholderTexture2D.new() # Icon shown in the skill tree for this skill

var is_activated := false # To know if a skill is currently active
var was_used := false # To know if the skill was already used once


# Override method
func activate(context: SkillContext) -> void:
	pass

# Override method
func can_activate(context: SkillContext) -> bool:
	return true
