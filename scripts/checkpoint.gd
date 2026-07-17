# checkpoint.gd
class_name Checkpoint
extends Area3D

@export var checkpoint_index: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is Racer:
		body.racer_race_controller.on_checkpoint_entered(checkpoint_index)
