@tool
extends Node3D

@onready var trigger_collision_shape_3d: CollisionShape3D = $TriggerArea3D/TriggerCollisionShape3D

@export var trigger_condition: ActiveSkill.ACTIVATION_PHASES: set = _set_condition
@export var trigger_shape: Shape3D: set = _set_mesh

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _set_mesh(shape: Shape3D) -> void:
	if trigger_collision_shape_3d != null:
		trigger_shape = shape
		trigger_collision_shape_3d.shape = shape

func _set_condition(condition: ActiveSkill.ACTIVATION_PHASES) -> void:
	if trigger_collision_shape_3d != null:
		trigger_condition = condition
		name = "SkillTrigger" + ActiveSkill.ACTIVATION_PHASES.find_key(condition)
		# Give a color for each condition (to differentiate easier when creating racecourse)
		match condition:
			ActiveSkill.ACTIVATION_PHASES.CORNER:
				trigger_collision_shape_3d.debug_color = Color(0.825, 0.484, 0.218, 1.0)
			ActiveSkill.ACTIVATION_PHASES.STRAIGHTAWAY:
				trigger_collision_shape_3d.debug_color = Color(0.83, 0.445, 0.534, 1.0)
			ActiveSkill.ACTIVATION_PHASES.END_GOAL:
				trigger_collision_shape_3d.debug_color = Color(0.804, 0.0, 0.148, 1.0)
			ActiveSkill.ACTIVATION_PHASES.STARTING_GATE:
				trigger_collision_shape_3d.debug_color = Color(0.487, 0.58, 0.778, 1.0)
