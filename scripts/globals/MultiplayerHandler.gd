extends Node

const DEFAULT_PORT := 2222
const MAX_PLAYERS := 8

var peer: ENetMultiplayerPeer = null

## True when this instance is authoritative for race state: either genuinely hosting, or
## playing solo/offline (no peer at all, which should behave like a host of one). False only
## while connected as a client to someone else's server.
## Deliberately NOT using multiplayer.is_server() here: it's unreliable in practice (see
## https://github.com/godotengine/godot/issues/87023) and returned false even for the actual
## host in testing. This flag is set explicitly by us at the one place we know the truth.
var is_host := true

## Shown once by main_menu_ui after a failed/aborted connection attempt, then cleared.
var last_status_message := ""

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

## Returns true for single-player (no active peer) or for the node's own multiplayer authority,
## i.e. whether this machine should treat the given node as "mine" to control.
func is_authority_or_offline(node: Node) -> bool:
	return peer == null or node.is_multiplayer_authority()

func create_server(port: int = DEFAULT_PORT) -> void:
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_PLAYERS)
	if error != OK:
		last_status_message = "Could not start server (error %d)." % error
		peer = null
		return

	multiplayer.multiplayer_peer = peer
	is_host = true
	GameHandler.add_player(multiplayer.get_unique_id())

func join_server(address: String, port: int = DEFAULT_PORT) -> void:
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		last_status_message = "Could not connect to \"%s\" (error %d)." % [address, error]
		peer = null
		return
	
	multiplayer.multiplayer_peer = peer
	is_host = false

## Voluntary disconnect. If we're the host, closing our peer drops every client, who each land
## on _on_server_disconnected(). If we're a client, this signals the host cleanly so it can
## despawn our player for everyone else.
func leave_game() -> void:
	if peer == null:
		GameHandler.main.return_to_main_menu()
	_reset_peer()
	GameHandler.main.return_to_main_menu()

func _reset_peer() -> void:
	if peer:
		peer.close()
	multiplayer.multiplayer_peer = null
	peer = null
	is_host = true # Back to solo/offline, which is host-equivalent

# Fires on every peer whenever anyone (re)connects, but only the host spawns players.
func _on_peer_connected(id: int) -> void:
	if is_host:
		GameHandler.add_player(id)

# Fires on every peer whenever anyone disconnects, but only the host despawns players.
func _on_peer_disconnected(id: int) -> void:
	if is_host:
		GameHandler.del_player(id)

func _on_connection_failed() -> void:
	last_status_message = "Could not connect to host."
	_reset_peer()
	GameHandler.main.return_to_main_menu()

func _on_server_disconnected() -> void:
	last_status_message = "Disconnected from host."
	_reset_peer()
	GameHandler.main.return_to_main_menu()
