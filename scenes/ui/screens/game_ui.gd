class_name GameUI
extends CanvasLayer

@onready var keybinds_rich_text_label: RichTextLabel = %KeybindsRichTextLabel
@onready var join_race_panel: Panel = %JoinRacePanel
@onready var race_info_label: Label = %RaceInfoLabel

func propose_to_join_race(current_race: Race, current_track: Track) -> void:
	race_info_label.text = "Race : %s
	Distance : %d
	Ground Type : %s
	Runners Participating : %d" % [current_race.i_name, current_race.distance, GroundData.GROUND_TYPES.keys()[current_track.ground_type], current_race.max_participants]
	UiAnimationHandler.animate_pop(join_race_panel)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action_show_keybinds"):
		if keybinds_rich_text_label.scale >= Vector2(1, 1):
			UiAnimationHandler.animate_shrink(keybinds_rich_text_label)
		else:
			UiAnimationHandler.animate_pop(keybinds_rich_text_label)


func _on_leave_lobby_button_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameHandler.game_state = GameHandler.GAME_STATES.RUNNING
	MultiplayerHandler.leave_game()


func _on_join_race_button_pressed() -> void:
	GameHandler.will_participate_in_race = true
	UiAnimationHandler.animate_shrink(join_race_panel)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_skip_race_button_pressed() -> void:
	UiAnimationHandler.animate_shrink(join_race_panel)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
