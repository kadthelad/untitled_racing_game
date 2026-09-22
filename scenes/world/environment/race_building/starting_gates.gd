class_name StartingGates
extends Node3D

func add_gates(nb_gates:=1) -> void:
	const LEFT_MARGIN := 1.27
	clear_gates()
	
	for i in range(nb_gates):
		var gate: StartingGateSingle = SceneUtils.STARTING_GATES_SINGLE.instantiate()
		add_child(gate)
		gate.position.x -= LEFT_MARGIN * i
		gate.bracket_label.text = str(i+1)

func clear_gates() -> void:
	if get_child_count() > 0:
		for child in get_children():
			child.queue_free()

func open_all_gates() -> void:
	if get_child_count() > 0:
		for gate: StartingGateSingle in get_children():
			gate.animation_player.play("Opening")
