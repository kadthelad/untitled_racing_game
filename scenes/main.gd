class_name Main
extends Node

const MAIN_MENU_SCENE := preload("res://scenes/ui/screens/main_menu_ui.tscn")

var current_window: CanvasLayer
var current_map: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var main_menu_instance := MAIN_MENU_SCENE.instantiate()
	add_child(main_menu_instance)

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
