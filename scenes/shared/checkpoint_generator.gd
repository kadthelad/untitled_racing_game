@tool
class_name CheckpointGenerator
extends Node3D

@export var track_path: Path3D
@export var checkpoint_spacing: float = 20.0  # Distance between checkpoints
@export var checkpoint_width: float = 12.0    # Should match track width
@export var checkpoints_node: Node3D # Where the checkpoint nodes will appear
@export_tool_button("Generate Checkpoints") var generate_action := generate_checkpoints
@export_tool_button("Clear Checkpoints") var clear_action := clear_checkpoints

func generate_checkpoints() -> void:
	if track_path == null:
		push_error("No Path3D assigned")
		return
	if checkpoints_node == null:
		push_error("No Node3D assigned for checkpoints parent")
		return
	
	clear_checkpoints()
	
	var curve := track_path.curve
	var total_length := curve.get_baked_length()
	var checkpoint_count := int(total_length / checkpoint_spacing)
	var scene_root := checkpoints_node.owner if checkpoints_node.owner else checkpoints_node
	
	for i in range(checkpoint_count):
		var distance := i * checkpoint_spacing
		var pos := curve.sample_baked(distance)
		var next_pos := curve.sample_baked(minf(distance + 1.0, total_length))
		
		var checkpoint := Area3D.new()
		checkpoint.name = "Checkpoint%d" % i
		checkpoint.set_script(load("res://scripts/checkpoint.gd"))
		checkpoint.checkpoint_index = i
		
		checkpoints_node.add_child(checkpoint)
		checkpoint.owner = scene_root  # <-- This makes it visible + saveable
		checkpoint.global_position = pos
		checkpoint.look_at(next_pos, Vector3.UP)
		
		var collision := CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		var shape := BoxShape3D.new()
		shape.size = Vector3(checkpoint_width, 5.0, 1.0)
		collision.shape = shape
		checkpoint.add_child(collision)
		collision.owner = scene_root  # <-- Same for the child collision shape

func clear_checkpoints() -> void:
	if checkpoints_node == null:
		push_error("No Node3D assigned for checkpoints parent")
		return
	
	for child in checkpoints_node.get_children():
		child.queue_free()
