class_name PlayerCameraController
extends Node

@onready var player: Player = get_parent()
@onready var player_movement_controller: PlayerMovementController = %PlayerMovementController
@onready var player_camera: Camera3D = %Camera3D
@onready var camera_y_pivot: Node3D = %CameraYPivot
@onready var camera_x_pivot: Node3D = %CameraXPivot

# Camera Variables
const CAM_MOVEMENT_SPEED := 5
const MOUSE_SENSITIVITY := 0.005
const MAX_ZOOM := 7.0
const MIN_ZOOM := 3.0
const ZOOM_SENSITIVITY := 0.5

var cam_side_right := true
@onready var cam_offset_x := player_camera.position.x

var is_local := true

func _ready():
	is_local = (MultiplayerHandler.peer == null or is_multiplayer_authority())
	if is_local:
		player_camera.current = true
	if MultiplayerHandler.peer != null:
		player_camera.current = is_multiplayer_authority()

func _unhandled_input(event: InputEvent) -> void:
	if !is_local:
		return
	if GameHandler.game_state == GameHandler.GAME_STATES.PAUSED:
		return
	
	# Move the camera
	if event is InputEventMouseMotion:
		if !player_movement_controller.is_running:
			player.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			camera_y_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		else:
			if !Input.is_action_pressed("game_left") and !Input.is_action_pressed("game_right"):
				player.rotate_y(deg_to_rad(clamp(-event.relative.x, -1 ,1) * player_movement_controller.turning_speed))
		# Clamping to prevent camera going upside down
		camera_y_pivot.rotation.x = clamp(camera_y_pivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _input(event: InputEvent) -> void:
	if !is_local:
		return
	if GameHandler.game_state == GameHandler.GAME_STATES.PAUSED:
		return
	
	# Zoom/Unzoom
	if !player.player_movement_controller.is_running:
		if event.is_action_pressed("mouse_scroll_down"):
			player_camera.position.z = clampf(player_camera.position.z + ZOOM_SENSITIVITY, MIN_ZOOM, MAX_ZOOM)
		if event.is_action_pressed("mouse_scroll_up"):
			player_camera.position.z = clampf(player_camera.position.z - ZOOM_SENSITIVITY, MIN_ZOOM, MAX_ZOOM)
	
	# Change camera's side
	if event.is_action_pressed("game_change_camera_side"):
		cam_side_right = !cam_side_right

func _process(delta: float) -> void:
	if !is_local:
		return
	if GameHandler.game_state == GameHandler.GAME_STATES.PAUSED:
		return
	
	# Smoothly move camera to the desired side
	var target_x = cam_offset_x if cam_side_right else -cam_offset_x
	player_camera.position.x = move_toward(player_camera.position.x, target_x, delta * CAM_MOVEMENT_SPEED)
