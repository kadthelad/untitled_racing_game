class_name RacerRaceController
extends Node

@onready var racer: Racer = get_parent()
var race_handler: RaceHandler
var racer_placing: int

func on_checkpoint_entered(checkpoint_index: int) -> void:
	if !MultiplayerHandler.is_host: # Only the host tracks authoritative race progress
		return
	if !race_handler:
		return
	if !race_handler.race_started:
		return

	if checkpoint_index == racer.expected_next_checkpoint_index:
		racer.checkpoints_passed += 1
		racer.expected_next_checkpoint_index = (racer.expected_next_checkpoint_index + 1) % race_handler.total_checkpoints
		if racer.expected_next_checkpoint_index == 0:
			racer.current_lap += 1
			# Reset the per-lap counter: without this it keeps growing past total_checkpoints
			# on lap 2+, which both double-counts progress and eventually indexes the
			# checkpoints array out of bounds in calculate_progress_score().
			racer.checkpoints_passed = 0
	elif checkpoint_index == racer.expected_next_checkpoint_index - 1:
		# Went backwards through the last checkpoint
		racer.checkpoints_passed -= 1
		racer.expected_next_checkpoint_index = checkpoint_index


func _on_player_change_placing(placing: int, total_racers: int) -> void:
	racer_placing = placing
	var player := racer as Player
	if player:
		player.running_ui.position_label.text = "%d/%d" % [placing, total_racers]
