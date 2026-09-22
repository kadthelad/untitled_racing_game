class_name Main
extends Node

var current_window: CanvasLayer
var current_map: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameHandler.main = self
	GameHandler.return_to_main_menu_requested.connect(return_to_main_menu)
	return_to_main_menu()

func open_window(window_screen: PackedScene) -> void:
	if current_window != null:
		current_window.queue_free()
	var window_instance := window_screen.instantiate()
	add_child(window_instance)
	current_window = window_instance

func spawn_on_map(map_scene: PackedScene) -> void:
	if current_map != null:
		current_map.queue_free()
	var instanciated_map := map_scene.instantiate()
	add_child(instanciated_map)
	current_map = instanciated_map
	GameHandler.current_map = instanciated_map

func close_map() -> void:
	if current_map != null:
		current_map.queue_free()
		current_map = null
		GameHandler.current_map = null

func return_to_main_menu() -> void:
	close_map()
	open_window(SceneUtils.MAIN_MENU_UI)
