class_name Track
extends Node3D

@export var id: String
@export var checkpoints: Node3D
@export var skill_triggers: Node3D
@export var track_path: Path3D
@export var ground_type: GroundData.GROUND_TYPES
@export var checkpoint_generator: CheckpointGenerator
