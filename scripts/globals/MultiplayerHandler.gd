extends Node

var peer: ENetMultiplayerPeer = null

func create_server() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_server(2222, 8)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(GameHandler.add_player)
	GameHandler.add_player()

func join_server() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client("127.0.0.1", 2222)
	multiplayer.multiplayer_peer = peer

func exit_game(id: int) -> void:
	multiplayer.peer_disconnected.connect(GameHandler.del_player)
	GameHandler.del_player(id)
