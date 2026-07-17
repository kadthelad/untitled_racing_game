extends TextureButton
class_name SkillNode

@onready var level_unlock_label: Label = %LevelUnlockLabel
@onready var connection_line_2d: Line2D = %ConnectionLine2D
@onready var skill_points_label: Label = %SkillPointsLabel
@onready var focus_points_label: Label = %FocusPointsLabel
@export var skill: Skill
@export var max_level := 5

var level := 0:
	set(value):
		level = value
		level_unlock_label.text = str(level) + "/" + str(max_level)

func _ready() -> void:
	if skill == null:
		printerr("Skill is not set for SkillNode ", name, "!")
		return
	
	# Setup
	texture_normal = skill.skill_icon
	tooltip_text = skill.i_name + "\n" + skill.description
	skill_points_label.text = str(skill.skill_points_cost) + " pts"
	focus_points_label.text = str(skill.focus_cost) + " fcs"
	
	# Connect the SkillNodes with lines
	if get_parent() is SkillNode:
		connection_line_2d.add_point(global_position + size/2)
		connection_line_2d.add_point(get_parent().global_position + size/2)


func _on_pressed() -> void:
	level = min(level + 1, max_level)
	
	if level == max_level: # If it's maxxed out, let the other skills be unlocked
		if get_child_count() > 0:
			for child in get_children():
				if child is SkillNode:
					child.disabled = false
