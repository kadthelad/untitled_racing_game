class_name StartingGateSingle
extends Node3D

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var bracket_label: Label3D = %BracketLabel

func _ready() -> void:
	animation_player.play("Closed")
