## Racer is the class that takes in the Player and the AI class together
class_name Racer
extends CharacterBody3D

@warning_ignore("unused_signal") # Emitted here, consumed via a scene-file connection the analyzer can't see
signal change_placing(placing: int, total_racers: int)

@onready var racer_race_controller: RacerRaceController = %RacerRaceController

var current_lap: int = 0
var checkpoints_passed: int
var expected_next_checkpoint_index: int
