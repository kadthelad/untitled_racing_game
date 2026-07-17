class_name PlayerMovementController
extends Node

@onready var player: Player = get_parent()
@onready var camera_y_pivot: Node3D = %CameraYPivot
@onready var camera_3d: Camera3D = %Camera3D

@onready var player_mesh: Node3D = %PlayerMesh

enum RUNNING_STAGE {
	WALK,
	TROT,
	PACING,
	SPRINT,
	SPURT,
}

var runner: Runner:
	set(value):
		runner = value
		
		acceleration = runner.get_acceleration()
		max_running_speed = runner.get_max_speed()
		max_stamina = runner.get_max_stamina()
		base_max_stamina = max_stamina
		current_stamina = max_stamina
		stamina_drain_rate = runner.get_stamina_drain()
		stamina_regen_rate = runner.get_stamina_regen()
		fatigue_buildup_rate = runner.get_fatigue_buildup()
		fatigue_cap = runner.fatigue_cap
		
		# Gait ceilings. The maxf chain guarantees strictly ascending order
		# even with odd stat combos (e.g. low max speed + high stamina)
		trot_speed = runner.get_trot_speed(WALK_SPEED)
		pacing_speed = maxf(runner.get_pacing_speed(), trot_speed + STAGE_GAP_MIN)
		sprint_speed = maxf(runner.get_sprint_speed(), pacing_speed + STAGE_GAP_MIN)
		spurt_speed = maxf(runner.get_spurt_speed(), sprint_speed + STAGE_GAP_MIN)
		
		stage_boundaries = [WALK_SPEED, trot_speed, pacing_speed, sprint_speed]
		cap_hold_boundary = -1.0

# Movement Variables
const WALK_SPEED := 5.0

var is_running := false
var max_running_speed := WALK_SPEED
var target_speed := WALK_SPEED:
	set(value):
		target_speed = value
		target_speed_value_bar.value = (target_speed / max_running_speed) * 100.0
const TARGET_SPEED_CHANGE := 0.5
const CTRL_SPEED_MULTIPLIER := 2.0
var current_speed := WALK_SPEED

var turning_speed := 0.5
var acceleration := 5.0
const DECELERATION := 5.0

# Running Stage Variables
var trot_speed := WALK_SPEED
var pacing_speed := WALK_SPEED
var sprint_speed := WALK_SPEED
var spurt_speed := WALK_SPEED
const STAGE_GAP_MIN := 0.5
var current_running_stage: RUNNING_STAGE = RUNNING_STAGE.WALK

# Soft speed-cap (gait ceiling) state
var stage_boundaries: Array[float] = [WALK_SPEED]
var cap_hold_boundary := -1.0
var cap_hold_start_time_ms := 0
const CAP_GRACE_DURATION_MS := 350

# Stamina/Fatigue Variables
var max_stamina := 10.0
var base_max_stamina := max_stamina
var current_stamina := max_stamina
var stamina_drain_rate := 1.0
var stamina_regen_rate := 3.0
var is_exhausted := false
const EXHAUSTION_RECOVERY_THRESHOLD := 0.15 # % of max stamina needed to lift exhaustion

var current_fatigue := 0.0
var fatigue_cap := 100.0
var fatigue_buildup_rate := 5.0 
var is_fatigued := false

const PACE_DRAIN_MULTIPLIER := 0.4
const SPRINT_DRAIN_MULTIPLIER := 1.0
const SPURT_DRAIN_MULTIPLIER := 1.8
const FATIGUED_DRAIN_MULTIPLIER := 2.0

# 3D UI Nodes
@onready var target_speed_value_bar: ValueBar3D = %TargetSpeedValueBar
@onready var stamina_value_bar: ValueBar3D = %StaminaValueBar
@onready var information_dynamic_label_3d: DynamicLabel3D = %InformationDynamicLabel3D

var is_local := true

func _ready():
	is_local = (MultiplayerHandler.peer == null or is_multiplayer_authority())

func _input(event: InputEvent) -> void:
	if !is_local:
		return
	if event.is_action_pressed("game_run"):
		is_running = !is_running
		cap_hold_boundary = -1.0
		if is_running:
			target_speed = current_speed
			# Set camera position
			const RUNNING_CAM_ROTATION := Vector3(-5, 0, 0)
			camera_y_pivot.rotation_degrees = RUNNING_CAM_ROTATION
		else:
			target_speed = WALK_SPEED
	
	if is_running:
		if event.is_action_pressed("mouse_scroll_up"):
			_handle_speed_scroll(1)
		if event.is_action_pressed("mouse_scroll_down"):
			_handle_speed_scroll(-1)

func _handle_speed_scroll(direction: int) -> void:
	if !is_running:
		return
	
	var ctrl_held := Input.is_action_pressed("key_ctrl")
	var upper_limit := max_running_speed
	if is_exhausted:
		upper_limit = minf(upper_limit, pacing_speed) # Exhaustion overrides even ctrl
	
	if ctrl_held:
		# Ctrl skips the pause entirely — meant for fast, deliberate speed changes
		var increment := TARGET_SPEED_CHANGE * CTRL_SPEED_MULTIPLIER * direction
		target_speed = clampf(target_speed + increment, 0.0, upper_limit)
		cap_hold_boundary = -1.0
		return
	
	var proposed_speed := clampf(target_speed + TARGET_SPEED_CHANGE * direction, 0.0, upper_limit)
	var crossed := _get_crossed_boundary(target_speed, proposed_speed)
	
	if crossed < 0.0:
		# No gait boundary in the way — move freely and drop any stale hold
		target_speed = proposed_speed
		cap_hold_boundary = -1.0
		return
	
	var now := Time.get_ticks_msec()
	if cap_hold_boundary == crossed:
		if now - cap_hold_start_time_ms < CAP_GRACE_DURATION_MS:
			return # Still pausing here — input absorbed so the player feels the cap
		target_speed = proposed_speed # Grace period elapsed, push through
		cap_hold_boundary = -1.0
	else:
		# First time reaching this boundary this pass — snap exactly and start the pause
		target_speed = crossed
		cap_hold_boundary = crossed
		cap_hold_start_time_ms = now

func _get_crossed_boundary(from_speed: float, to_speed: float) -> float:
	if to_speed > from_speed:
		for boundary: float in stage_boundaries:
			if boundary > from_speed and boundary <= to_speed:
				return boundary
	elif to_speed < from_speed:
		for i in range(stage_boundaries.size() - 1, -1, -1):
			var boundary: float = stage_boundaries[i]
			if boundary < from_speed and boundary >= to_speed:
				return boundary
	return -1.0

func _process(delta: float) -> void:
	_update_stamina(delta)
	
	if is_running:
		if current_speed != target_speed:
			var rate := acceleration if target_speed > current_speed else DECELERATION
			current_speed = move_toward(current_speed, target_speed, rate * delta)
			
			# velocity.length() gives you the scalar speed (ignoring Y so jumping doesn't affect it)
			var horizontal_velocity := Vector3(player.velocity.x, 0, player.velocity.z)
			var speed_ms := horizontal_velocity.length()         # meters per second
			var speed_kmh := speed_ms * 3.6                      # 1 m/s = 3.6 km/h
			
			player.running_ui.speed_label.text = "%.1f km/h" % speed_kmh
			target_speed_value_bar.value_bg = (current_speed / max_running_speed) * 100.0
			
			# Shift camera FOV with current speed
			const MIN_FOV := 75
			const MAX_FOV := 85
			camera_3d.fov = remap(current_speed, 0.0, max_running_speed, MIN_FOV, MAX_FOV)

func _update_stamina(delta: float) -> void:
	if is_running:
		if current_running_stage != _get_running_stage(current_speed):
			information_dynamic_label_3d.set_unique_label("Current running stage : " + RUNNING_STAGE.find_key(_get_running_stage(current_speed)), 1)
		current_running_stage = _get_running_stage(current_speed)
		match current_running_stage:
			RUNNING_STAGE.SPRINT:
				current_stamina = maxf(current_stamina - stamina_drain_rate * SPRINT_DRAIN_MULTIPLIER * delta, 0.0)
				current_fatigue = minf(current_fatigue + fatigue_buildup_rate * SPRINT_DRAIN_MULTIPLIER * delta, fatigue_cap)
			RUNNING_STAGE.SPURT:
				current_stamina = maxf(current_stamina - stamina_drain_rate * SPURT_DRAIN_MULTIPLIER * delta, 0.0)
				current_fatigue = minf(current_fatigue + fatigue_buildup_rate * SPURT_DRAIN_MULTIPLIER * delta, fatigue_cap)
			RUNNING_STAGE.PACING:
				current_stamina = maxf(current_stamina - stamina_drain_rate * PACE_DRAIN_MULTIPLIER * delta, 0.0)
				current_fatigue = minf(current_fatigue + fatigue_buildup_rate * PACE_DRAIN_MULTIPLIER * delta, fatigue_cap)
			_: # TROT - recovery, no drain at a sustainable speed
				current_stamina = minf(current_stamina + stamina_regen_rate * delta, max_stamina)
	else:
		current_running_stage = RUNNING_STAGE.WALK
		current_stamina = minf(current_stamina + stamina_regen_rate * delta, max_stamina)
	
	# Hysteresis: exhaustion clears at 15%, not 0%, so it doesn't flicker on/off every frame
	if current_stamina <= 0.0:
		is_exhausted = true
	elif current_stamina >= max_stamina * EXHAUSTION_RECOVERY_THRESHOLD:
		is_exhausted = false
	if current_fatigue <= 0.0:
		is_fatigued = true
	else:
		is_fatigued = false
	
	if is_exhausted and target_speed > pacing_speed:
		target_speed = WALK_SPEED
		cap_hold_boundary = -1.0 # Clear any stale hold so the next scroll starts fresh
	
	if is_fatigued:
		stamina_drain_rate = runner.get_stamina_drain() * FATIGUED_DRAIN_MULTIPLIER
	
	if current_fatigue > 0: # Cap the max_stamina to current_fatigue
		max_stamina = base_max_stamina * absf((current_fatigue / fatigue_cap) - 1.0)
		current_stamina = minf(current_stamina, max_stamina)
	
	stamina_value_bar.value = (current_stamina / base_max_stamina) * 100.0
	stamina_value_bar.value_bg = (current_fatigue / fatigue_cap) * 100.0

func _get_running_stage(speed: float) -> RUNNING_STAGE:
	if speed <= trot_speed:
		return RUNNING_STAGE.TROT
	elif speed <= pacing_speed:
		return RUNNING_STAGE.PACING
	elif speed <= sprint_speed:
		return RUNNING_STAGE.SPRINT
	else:
		return RUNNING_STAGE.SPURT

func _physics_process(delta: float) -> void:
	if !is_local: # To not control other players (multiplayer)
		return
	# Add the gravity.
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta
	
	if is_running: # Use acceleration and constantly run if the player is running
		var forward := -player_mesh.global_transform.basis.z
		player.velocity.x = forward.x * current_speed
		player.velocity.z = forward.z * current_speed
		# Turning player
		if Input.is_action_pressed("game_right"):
			player.rotate_y(-deg_to_rad(turning_speed))
		if Input.is_action_pressed("game_left"):
			player.rotate_y(deg_to_rad(turning_speed))
	else: # Get the input direction and handle the movement/deceleration if the player is walking
		var input_dir := Input.get_vector("game_left", "game_right", "game_forward", "game_backward")
		var input_vec := Vector3(input_dir.x, 0, input_dir.y)
		if input_vec.length_squared() > 0:
			var direction := (camera_y_pivot.global_transform.basis * input_vec.normalized()).normalized()
			if direction:
				# Move the player
				player.velocity.x = direction.x * WALK_SPEED
				player.velocity.z = direction.z * WALK_SPEED
				
				# Slightly tilt the player to give a cool effect
				# Convert world-space direction into player's local space for tilting
				var local_dir := player_mesh.global_transform.basis.inverse() * direction
				player_mesh.rotation.x = rotate_toward(player_mesh.rotation.x, deg_to_rad(local_dir.z * 10), delta) # Front/Back tilt
				player_mesh.rotation.z = rotate_toward(player_mesh.rotation.z, deg_to_rad(-local_dir.x * 10), delta) # Left/Right tilt
		else:
			# Go back to default velocity (0) and default tilting (none) when not moving
			player.velocity.x = move_toward(player.velocity.x, 0, WALK_SPEED)
			player.velocity.z = move_toward(player.velocity.z, 0, WALK_SPEED)
			
			player_mesh.rotation.x = rotate_toward(player_mesh.rotation.x, 0, delta)
			player_mesh.rotation.z = rotate_toward(player_mesh.rotation.z, 0, delta)
		
	player.move_and_slide()
