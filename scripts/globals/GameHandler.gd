extends Node

signal participating_message
signal in_race_changed(value: bool)
@warning_ignore("unused_signal") # Emitted in create_character_ui.gd, consumed in main.gd
signal return_to_main_menu_requested

var main: Main
var current_map: Node3D

var current_runner: Runner = Runner.empty()

## Host-configurable; RaceHandler waits for at least this many racers before starting.
var min_racers_to_start := 1

enum GAME_STATES {
	PAUSED,
	RUNNING,
}

var game_state := GAME_STATES.RUNNING

var will_participate_in_race := false:
	set(value):
		will_participate_in_race = value
		participating_message.emit(multiplayer.get_unique_id())
var in_race := false:
	set(value):
		in_race = value
		in_race_changed.emit(value)

func add_player(id: int) -> void:
	if current_map == null:
		return
	var player_instance := SceneUtils.PLAYER.instantiate()
	player_instance.name = str(id)
	current_map.add_child(player_instance)

func del_player(id: int) -> void:
	rpc("_del_player", id)

# "authority": only the host may call this (matches who's allowed to despawn nodes under the
# MultiplayerSpawner's spawn_path). "call_local": the host also runs it on its own view.
@rpc("authority", "call_local")
func _del_player(id: int) -> void:
	if current_map == null:
		return
	var player_node := current_map.get_node_or_null(str(id))
	if player_node:
		player_node.queue_free()
