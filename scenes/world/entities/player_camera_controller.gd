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
const MAX_CAMERA_PITCH := 35
const MIN_CAMERA_PITCH := -50

enum CameraSide { RIGHT, LEFT, MIDDLE }
var camera_side: CameraSide = CameraSide.RIGHT
@onready var cam_offset_x := player_camera.position.x

# UI Variables
@onready var interaction_raycast_3d: RayCast3D = %InteractionRaycast3D
@onready var interact_label: Label
@onready var player_info_control: PlayerInfoControl
@onready var interacting_timer: Timer = %InteractingTimer
var can_interact := false:
	set(value):
		can_interact = value
		if interact_label:
			interact_label.visible = value
var watching_player: Player:
	set(value):
		watching_player = value
		if player_info_control:
			if value:
				player_info_control.show_info(player.runner)
				interacting_timer.start()
			else:
				player_info_control.hide()

var is_local := true

func _ready():
	is_local = MultiplayerHandler.is_authority_or_offline(self)
	if is_local:
		player_camera.current = true
	if MultiplayerHandler.peer != null:
		player_camera.current = is_multiplayer_authority()
	
	await player.ready
	interact_label = player.running_ui.interact_label
	player_info_control = player.running_ui.player_info_control

func _unhandled_input(event: InputEvent) -> void:
	if !is_local:
		return
	if GameHandler.game_state == GameHandler.GAME_STATES.PAUSED:
		return
	
	# Move the camera
	if event is InputEventMouseMotion:
		# CameraXPivot (yaw) is the outer pivot and CameraYPivot (pitch) is nested inside it,
		# so yaw always turns around a level world-up axis no matter the current pitch — no roll.
		camera_y_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		if !player_movement_controller.is_running:
			player.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		else:
			camera_x_pivot.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		# Clamping to prevent camera going upside down
		camera_y_pivot.rotation.x = clamp(camera_y_pivot.rotation.x, deg_to_rad(MIN_CAMERA_PITCH), deg_to_rad(MAX_CAMERA_PITCH))

func _input(event: InputEvent) -> void:
	if !is_local:
		return
	if GameHandler.game_state == GameHandler.GAME_STATES.PAUSED:
		return
	
	# Zoom/Unzoom
	if event.is_action_pressed("mouse_scroll_down"):
		player_camera.position.z = clampf(player_camera.position.z + ZOOM_SENSITIVITY, MIN_ZOOM, MAX_ZOOM)
	if event.is_action_pressed("mouse_scroll_up"):
		player_camera.position.z = clampf(player_camera.position.z - ZOOM_SENSITIVITY, MIN_ZOOM, MAX_ZOOM)
	
	# Change camera's side
	if event.is_action_pressed("game_change_camera_side"):
		camera_side = wrapi(camera_side + 1, 0, CameraSide.size()) as CameraSide
	
	# Interact
	if event.is_action_pressed("game_interact"):
		if can_interact:
			var collided_body := interaction_raycast_3d.get_collider()
			if collided_body is Player:
				watching_player = collided_body

func _process(delta: float) -> void:
	if !is_local:
		return
	if GameHandler.game_state == GameHandler.GAME_STATES.PAUSED:
		return
	
	# Smoothly move camera to the desired side
	var target_x := cam_offset_x
	match camera_side:
		CameraSide.LEFT:
			target_x = -cam_offset_x
		CameraSide.MIDDLE:
			target_x = 0.0
	player_camera.position.x = move_toward(player_camera.position.x, target_x, delta * CAM_MOVEMENT_SPEED)
	
	# Detect interactables
	if !player_movement_controller.is_running:
		if interaction_raycast_3d.is_colliding():
			can_interact = true
		else:
			can_interact = false


func _on_interacting_timer_timeout() -> void:
	watching_player = null
