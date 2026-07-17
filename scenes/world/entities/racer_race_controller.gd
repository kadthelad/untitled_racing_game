class_name RacerRaceController
extends Node

@onready var position_label: Label3D = %PositionLabel
@onready var racer: Racer = get_parent()
var race_handler: RaceHandler
var racer_placing: int

func on_checkpoint_entered(checkpoint_index: int) -> void:
	if !race_handler:
		return
	if !race_handler.race_started:
		return
	
	if checkpoint_index == racer.expected_next_checkpoint_index:
		racer.checkpoints_passed += 1
		racer.expected_next_checkpoint_index = (racer.expected_next_checkpoint_index + 1) % race_handler.total_checkpoints
		if racer.expected_next_checkpoint_index == 0:
			racer.current_lap += 1
	elif checkpoint_index == racer.expected_next_checkpoint_index - 1:
		# Went backwards through the last checkpoint
		racer.checkpoints_passed -= 1
		racer.expected_next_checkpoint_index = checkpoint_index


func _on_player_change_placing(placing: int, total_racers: int) -> void:
	racer_placing = placing
	position_label.text = "%d/%d" % [placing, total_racers]
