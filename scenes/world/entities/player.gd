class_name Player
extends Racer

@onready var player_camera_controller: PlayerCameraController = %PlayerCameraController
@onready var player_movement_controller: PlayerMovementController = %PlayerMovementController

@onready var running_ui: RunningUI = %RunningUI # UI During a race
@onready var game_ui: GameUI = %GameUI # UI In lobby (not in race)

var runner: Runner:
	set(value):
		runner = value
		player_movement_controller.runner = value

var is_local := true

func _ready() -> void:
	is_local = MultiplayerHandler.is_authority_or_offline(self)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # Hides and locks cursor
	
	runner = Runner.empty() if !GameHandler.current_runner else GameHandler.current_runner
	if !is_local:
		running_ui.hide()
		game_ui.hide()
		return

	GameHandler.in_race_changed.connect(_on_in_race_changed)
	_on_in_race_changed(GameHandler.in_race)

func _on_in_race_changed(value: bool) -> void:
	running_ui.visible = value
	game_ui.visible = !value

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
		running_ui.leave_match_button.visible = (GameHandler.game_state == GameHandler.GAME_STATES.PAUSED)

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int()) # To not control other players (multiplayer)
