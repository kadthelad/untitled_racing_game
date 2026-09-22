extends CanvasLayer

@onready var main: Main = get_parent()

@onready var min_players_spin_box: SpinBox = %MinPlayersSpinBox
@onready var join_address_line_edit: LineEdit = %JoinAddressLineEdit
@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	_show_pending_status()

# Shows a message left behind by MultiplayerHandler after a failed/aborted connection
# (e.g. connection_failed, server_disconnected), then clears it so it isn't shown again.
func _show_pending_status() -> void:
	if MultiplayerHandler.last_status_message != "":
		status_label.text = MultiplayerHandler.last_status_message
		MultiplayerHandler.last_status_message = ""

func _on_create_server_button_pressed() -> void:
	GameHandler.min_racers_to_start = int(min_players_spin_box.value)
	main.spawn_on_map(SceneUtils.TEST_MAP)
	MultiplayerHandler.create_server()
	if MultiplayerHandler.peer == null: # Synchronous failure (e.g. port already in use)
		main.close_map()
		_show_pending_status()
		return
	queue_free()

func _on_join_server_button_pressed() -> void:
	main.spawn_on_map(SceneUtils.TEST_MAP)
	MultiplayerHandler.join_server(join_address_line_edit.text)
	if MultiplayerHandler.peer == null: # Synchronous failure (e.g. malformed address)
		main.close_map()
		_show_pending_status()
		return
	queue_free()


func _on_create_character_button_pressed() -> void:
	main.open_window(SceneUtils.CREATE_CHARACTER_UI)


func _on_testmap_button_pressed() -> void:
	main.spawn_on_map(SceneUtils.TEST_MAP)
	GameHandler.add_player(multiplayer.get_unique_id())
	queue_free()
