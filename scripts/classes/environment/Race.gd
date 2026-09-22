class_name Race
extends Resource

@export_category("Race Information")
@export var i_name: String = "UNNAMED RACE" # i_name = instance name
@export var distance: int = 1200
@export var max_participants: int = 6
@export var racecourse: PackedScene
@export var clockwise: bool = true
@export var track_id: String = ""
