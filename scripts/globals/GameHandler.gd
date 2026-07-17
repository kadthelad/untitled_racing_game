extends Node

const PLAYER_SCENE := SceneUtils.PLAYER
var current_map: Node3D

enum GAME_STATES {
	PAUSED,
	RUNNING,
}

var game_state := GAME_STATES.RUNNING

func add_player(id: int = 1) -> void:
	if current_map != null:
		var player_instance = PLAYER_SCENE.instantiate()
		player_instance.name = str(id)
		current_map.add_child(player_instance)

func del_player(id: int) -> void:
	rpc("_del_player", id)

@rpc("any_peer", "call_local")
func _del_player(id: int) -> void:
	current_map.get_node(str(id)).queue_free()
