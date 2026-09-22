class_name DynamicLabel
extends VBoxContainer

const MAX_LABELS := 10

func add_label(text: String, color: Color = Color.WHITE) -> void:
	if get_child_count() >= MAX_LABELS:
		get_child(0).queue_free()

	var label := _create_label(text, color)
	add_child(label)

	var timer := Timer.new()
	timer.wait_time = 5
	timer.timeout.connect(_label_timer_timeout.bind(label))
	label.add_child(timer)
	timer.start()

func set_unique_label(text: String, id: int, color: Color = Color.WHITE) -> void:
	for child: Label in get_children():
		if child.has_meta("id") and child.get_meta("id") == id:
			child.text = text
			child.modulate = color
			return

	if get_child_count() >= MAX_LABELS:
		get_child(0).queue_free()

	var label := _create_label(text, color)
	label.set_meta("id", id)
	add_child(label)
	move_child(label, 0) # Id-tagged labels stay above temporary ones

func _label_timer_timeout(label: Label) -> void:
	label.queue_free()

func _create_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.modulate = color
	return label
