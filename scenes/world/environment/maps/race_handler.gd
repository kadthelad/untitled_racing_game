class_name RaceHandler
extends Node

@onready var placing_check_timer: Timer = %PlacingCheckTimer

@export var racecourse: Racecourse

var race_started := false:
	set(value):
		race_started = value
		if race_started:
			placing_check_timer.start()

var checkpoints: Array[Checkpoint] = []
var total_checkpoints := 0
var racer_array: Array[Racer]

func _on_ready() -> void:
	if racecourse == null:
		push_error("racecourse is not defined in RaceHandler!")
		return
	
	for checkpoint: Checkpoint in racecourse.checkpoints.get_children():
		checkpoints.append(checkpoint)
	total_checkpoints = checkpoints.size()


func _on_multiplayer_spawner_spawned(node: Node) -> void:
	var racer := node as Racer
	if racer:
		racer.racer_race_controller.race_handler = self
		if !racer_array.has(racer):
			racer_array.append(racer)
		
		if racer_array.size() >= 3:
			print("Race started!")
			race_started = true

# Check everyone's placing
func _on_placing_check_timer_timeout() -> void:
	print("checking the placings...")
	var progress: Dictionary[Racer, float] = {}
	for racer: Racer in racer_array:
		progress[racer] = calculate_progress_score(racer)
	
	progress.sort()
	for i in progress.size():
		var racer: Racer = progress.keys()[i]
		racer.change_placing.emit(i+1, racer_array.size())
	print("placings: ", progress)

func calculate_progress_score(racer: Racer) -> float:
	var progress = (racer.current_lap * total_checkpoints) + racer.checkpoints_passed
	
	progress += get_fractional_progress(racer.position, checkpoints[racer.checkpoints_passed].position, checkpoints[racer.checkpoints_passed+1].position)
	
	return progress

func get_fractional_progress(racer_pos: Vector3, checkpoint_a: Vector3, checkpoint_b: Vector3) -> float:
	var segment := checkpoint_b - checkpoint_a
	var to_racer := racer_pos - checkpoint_a
	return clampf(to_racer.dot(segment) / segment.length_squared(), 0.0, 1.0)
