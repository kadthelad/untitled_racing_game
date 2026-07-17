class_name Player
extends Racer

@onready var player_camera_controller: PlayerCameraController = %PlayerCameraController
@onready var player_movement_controller: PlayerMovementController = %PlayerMovementController
@onready var ui_nodes: Node3D = %UINodes

@onready var information_dynamic_label_3d: DynamicLabel3D = %InformationDynamicLabel3D

@onready var running_ui: RunningUI = %RunningUI

var runner:
	set(value):
		runner = value
		player_movement_controller.runner = value

var is_local := true

func _ready() -> void:
	is_local = (MultiplayerHandler.peer == null or is_multiplayer_authority())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # Hides and locks cursor
	
	runner = Runner.empty()
	if !is_local:
		ui_nodes.hide()

func _input(event: InputEvent) -> void:
	if !is_local: # To not control other players (multiplayer)
		return
	# Escape to free/capture the mouse
	if event.is_action_pressed("ui_cancel"):
		if GameHandler.game_state != GameHandler.GAME_STATES.PAUSED:
			GameHandler.game_state = GameHandler.GAME_STATES.PAUSED
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			GameHandler.game_state = GameHandler.GAME_STATES.RUNNING
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int()) # To not control other players (multiplayer)
