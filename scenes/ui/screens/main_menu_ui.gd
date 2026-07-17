extends CanvasLayer

@onready var main: Main = get_parent()

func _on_create_server_button_pressed() -> void:
	main.spawn_on_map(SceneUtils.TEST_MAP)
	MultiplayerHandler.create_server()
	queue_free()

func _on_join_server_button_pressed() -> void:
	main.spawn_on_map(SceneUtils.TEST_MAP)
	MultiplayerHandler.join_server()
	queue_free()


func _on_create_character_button_pressed() -> void:
	main.open_window(SceneUtils.CREATE_CHARACTER_UI)


func _on_testmap_button_pressed() -> void:
	main.spawn_on_map(SceneUtils.TEST_MAP)
	queue_free()
