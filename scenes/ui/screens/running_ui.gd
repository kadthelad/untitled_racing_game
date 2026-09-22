class_name RunningUI
extends CanvasLayer

@onready var speed_label: Label = %SpeedLabel
@onready var leave_match_button: Button = %LeaveMatchButton
@onready var interact_label: Label = %InteractLabel
@onready var player_info_control: Control = %PlayerInfoControl

# Only visible while actively running (not just in-race) — see PlayerMovementController.is_running
@onready var running_stats_container: Control = %RunningStatsContainer
@onready var target_speed_value_bar: ValueBar = %TargetSpeedValueBar
@onready var stamina_value_bar: ValueBar = %StaminaValueBar
@onready var position_label: Label = %PositionLabel
@onready var information_label: DynamicLabel = %InformationLabel

func _on_leave_match_button_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameHandler.game_state = GameHandler.GAME_STATES.RUNNING
	MultiplayerHandler.leave_game()
