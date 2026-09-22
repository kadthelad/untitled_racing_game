class_name RaceHandler
extends Node

@onready var placing_check_timer: Timer = %PlacingCheckTimer

@export var racecourse: Racecourse

const SPAWN_BACK_OFFSET := 10.0
const SPAWN_SIDE_SPACING := 2.5
const SPAWN_UP_OFFSET := 2.0

var races_on_racecourse: Array[Race]

var current_race: Race
var current_track: Track

var race_started := false:
	set(value):
		race_started = value
		GameHandler.in_race = value
		if race_started:
			placing_check_timer.start()

var checkpoints: Array[Checkpoint] = []
var total_checkpoints := 0
var racer_array: Array[Racer]
var participating_racers: Array[Racer]
var starting_gates: StartingGates
var finish_line: FinishLine

func _ready() -> void:
	if racecourse == null:
		push_error("racecourse is not defined in RaceHandler!")
		return
	
	GameHandler.participating_message.connect(_on_wants_to_join_race)
	
	if MultiplayerHandler.is_host:
		const RACES_PATH := "res://scripts/resources/races/"
		var races_dir := DirAccess.open(RACES_PATH)
		if races_dir:
			for file in races_dir.get_files():
				if file.get_extension() != "tres":
					continue
				var race := load(RACES_PATH + file) as Race
				if race and race.racecourse and race.racecourse.resource_path == racecourse.scene_file_path:
					races_on_racecourse.append(race)
	
		prepare_next_race()
	
	# "spawned" only fires for replicated peers, not the spawning authority.
	get_parent().child_entered_tree.connect(_on_racer_node_added)


func _on_multiplayer_spawner_spawned(node: Node) -> void:
	_on_racer_node_added(node)

func _on_racer_node_added(node: Node) -> void:
	_register_racer.call_deferred(node) # Wait for the node's own _ready()

func _register_racer(node: Node) -> void:
	var racer := node as Racer
	if !racer or racer_array.has(racer):
		return
	
	racer.racer_race_controller.race_handler = self
	racer_array.append(racer)
	racer.tree_exiting.connect(_on_racer_tree_exiting.bind(racer))
	
	if MultiplayerHandler.is_authority_or_offline(racer):
		var runner := GameHandler.current_runner
		if MultiplayerHandler.is_host:
			_apply_and_broadcast_runner_data(racer.name, runner)
			_send_race_invitation_to(racer.name)
		else:
			_send_runner_data.rpc_id(1, racer.name, runner.i_name, runner.level, runner.skill_points, runner.get_stat_values())
			_request_race_invitation.rpc_id(1)

func _on_racer_tree_exiting(racer: Racer) -> void:
	racer_array.erase(racer)
	if participating_racers.has(racer):
		participating_racers.erase(racer)

# "authority": only the host may call this. "call_local": the host also applies it locally.
@rpc("authority", "call_local")
func _start_race(participant_names: Array[String]) -> void:
	if !current_race:
		return
	print("Race started!")
	race_started = true
	_spawn_local_racer_on_track(participant_names)

# Only ever moves the racer this specific peer owns — a remote racer's position is driven by
# replication from its own owning peer, so setting it locally here would just get overwritten.
func _spawn_local_racer_on_track(participant_names: Array[String]) -> void:
	if checkpoints.is_empty():
		return
	var local_racer := _find_local_racer() as Player
	if !local_racer:
		return
	var slot := participant_names.find(local_racer.name)
	if slot < 0:
		return
	
	# Place and prepare the starting gates and finish line
	starting_gates = SceneUtils.STARTING_GATES.instantiate()
	racecourse.add_child(starting_gates)
	_place_on_track(starting_gates, 0.0)
	var track_side := starting_gates.global_transform.basis.x
	starting_gates.global_position += track_side * -(current_track.checkpoint_generator.checkpoint_width * 0.35)
	starting_gates.rotate_y(deg_to_rad(-180))
	# participating_racers is only ever populated on the host; participant_names is
	# the same on every peer since it was broadcast with the race-start RPC.
	starting_gates.add_gates(current_race.max_participants)
	
	# Place the players in their gates
	local_racer.global_position = starting_gates.get_children()[slot].global_position
	local_racer.global_position.y += SPAWN_UP_OFFSET
	
	finish_line = SceneUtils.FINISH_LINE.instantiate()
	racecourse.add_child(finish_line)
	_place_on_track(finish_line, current_race.distance)
	finish_line.global_position += track_side * (current_track.checkpoint_generator.checkpoint_width * 0.5)
	finish_line.rotate_y(deg_to_rad(-90))

# Samples the track's curve at an arc-length distance, wrapping for laps longer than the track.
func _place_on_track(node: Node3D, distance: float) -> void:
	var curve := current_track.track_path.curve
	var length := curve.get_baked_length()
	if length <= 0.0:
		return
	var offset := fmod(distance, length)
	var next_offset := fmod(offset + 1.0, length)
	node.global_position = current_track.track_path.to_global(curve.sample_baked(offset))
	node.look_at(current_track.track_path.to_global(curve.sample_baked(next_offset)), Vector3.UP)

# Plain data, not a Runner object — RPCs can't send custom Objects.
@rpc("any_peer", "call_remote")
func _send_runner_data(racer_name: String, i_name: String, level: int, skill_points: int, stat_values: PackedInt32Array) -> void:
	if !MultiplayerHandler.is_host:
		return
	var runner := Runner.new(i_name, level, skill_points, Runner.stats_from_values(stat_values), [])
	_apply_and_broadcast_runner_data(racer_name, runner)

func _apply_and_broadcast_runner_data(racer_name: String, runner: Runner) -> void:
	var racer := _find_racer_by_name(racer_name) as Player
	if racer:
		racer.runner = runner
	_broadcast_runner_data.rpc(racer_name, runner.i_name, runner.level, runner.skill_points, runner.get_stat_values())
	_catch_up_new_peer(racer_name)

@rpc("authority", "call_remote")
func _broadcast_runner_data(racer_name: String, i_name: String, level: int, skill_points: int, stat_values: PackedInt32Array) -> void:
	var racer := _find_racer_by_name(racer_name) as Player
	if racer:
		racer.runner = Runner.new(i_name, level, skill_points, Runner.stats_from_values(stat_values), [])

# RPCs aren't replayed to late joiners; catch a new peer up on everyone else.
func _catch_up_new_peer(new_racer_name: String) -> void:
	var new_peer_id := int(new_racer_name)
	for other_racer: Racer in racer_array:
		if other_racer.name == new_racer_name:
			continue
		var player_racer := other_racer as Player
		if player_racer and player_racer.runner:
			var runner := player_racer.runner
			_broadcast_runner_data.rpc_id(new_peer_id, other_racer.name, runner.i_name, runner.level, runner.skill_points, runner.get_stat_values())

func _on_placing_check_timer_timeout() -> void:
	if !MultiplayerHandler.is_host:
		return
	
	var progress: Dictionary[Racer, float] = {}
	for racer: Racer in participating_racers:
		progress[racer] = calculate_progress_score(racer)
	
	# Dictionary.sort() sorts by key, not value.
	var ordered_racers := participating_racers.duplicate()
	ordered_racers.sort_custom(func(a: Racer, b: Racer) -> bool: return progress[a] > progress[b])
	
	var ordered_names: Array[String] = []
	for racer: Racer in ordered_racers:
		ordered_names.append(racer.name)
	_broadcast_placings.rpc(ordered_names)

@rpc("authority", "call_local")
func _broadcast_placings(ordered_names: Array[String]) -> void:
	var total := ordered_names.size()
	for i in total:
		var racer := _find_racer_by_name(ordered_names[i])
		if racer:
			racer.change_placing.emit(i + 1, total)

func _find_racer_by_name(racer_name: String) -> Racer:
	for racer: Racer in racer_array:
		if racer.name == racer_name:
			return racer
	return null

func _find_local_racer() -> Racer:
	for racer: Racer in racer_array:
		if MultiplayerHandler.is_authority_or_offline(racer):
			return racer
	return null

# Client -> host: "my racer is registered, send my invitation now" — avoids a race where the
# host pushes the invitation before the client's own racer even exists in its racer_array.
@rpc("any_peer", "call_remote")
func _request_race_invitation() -> void:
	if !MultiplayerHandler.is_host:
		return
	_send_race_invitation_to(str(multiplayer.get_remote_sender_id()))

func _send_race_invitation_to(racer_name: String) -> void:
	if !current_race or race_started:
		return
	if int(racer_name) == multiplayer.get_unique_id():
		_receive_race_invitation(current_race.resource_path)
	else:
		_receive_race_invitation.rpc_id(int(racer_name), current_race.resource_path)

# Sends a path, not the Race resource itself — Resources can't go over RPC either.
@rpc("authority", "call_remote")
func _receive_race_invitation(race_path: String) -> void:
	current_race = load(race_path) as Race
	search_for_track()
	if !current_track:
		return
	var local_racer := _find_local_racer() as Player
	if local_racer:
		local_racer.game_ui.propose_to_join_race(current_race, current_track)

func calculate_progress_score(racer: Racer) -> float:
	var progress = (racer.current_lap * total_checkpoints) + racer.checkpoints_passed
	
	var to_index := racer.expected_next_checkpoint_index
	var from_index := (to_index - 1 + total_checkpoints) % total_checkpoints
	# global_position: checkpoints and racers sit under differently-transformed parents.
	progress += get_fractional_progress(racer.global_position, checkpoints[from_index].global_position, checkpoints[to_index].global_position)
	
	return progress

func get_fractional_progress(racer_pos: Vector3, checkpoint_a: Vector3, checkpoint_b: Vector3) -> float:
	var segment := checkpoint_b - checkpoint_a
	var to_racer := racer_pos - checkpoint_a
	return clampf(to_racer.dot(segment) / segment.length_squared(), 0.0, 1.0)

func prepare_next_race() -> void:
	participating_racers.clear()
	current_race = races_on_racecourse.pick_random()

func search_for_track() -> void:
	for track: Track in racecourse.tracks:
		if track.id == current_race.track_id:
			current_track = track
			checkpoints.clear()
			for checkpoint: Checkpoint in track.checkpoints.get_children():
				checkpoints.append(checkpoint)
			total_checkpoints = checkpoints.size()
			return
	printerr("No racecourse found for track_id = ", current_race.track_id, " in race ", current_race.i_name, ", race can not start!")
	current_race = null

func _on_wants_to_join_race(player_id: int) -> void:
	if MultiplayerHandler.is_host:
		_register_participant(player_id)
	else:
		_register_participant.rpc_id(1, player_id)

@rpc("any_peer", "call_remote")
func _register_participant(player_id: int) -> void:
	if !MultiplayerHandler.is_host:
		return
	var player := _find_racer_by_name(str(player_id)) as Player
	if player and !participating_racers.has(player):
		participating_racers.append(player)
	
	if !race_started and participating_racers.size() >= GameHandler.min_racers_to_start:
		var names: Array[String] = []
		for racer: Racer in participating_racers:
			names.append(racer.name)
		_start_race.rpc(names)
