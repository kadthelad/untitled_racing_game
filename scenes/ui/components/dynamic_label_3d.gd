@tool
class_name DynamicLabel3D
extends Node3D

const MAX_LABELS := 10
@export var font: FontFile

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	const MARGIN := -0.15
	var label_order: Array[Label3D] = []
	for i in range(get_child_count()):
		var child := get_child(i) as Label3D
		if child:
			if child.has_meta("id"):
				label_order.insert(0, child)
		label_order.append(child)
	for i in range(label_order.size()):
		label_order[i].position.y = i * MARGIN

func add_label(text: String, color: Color = Color.WHITE) -> void:
	if get_child_count() >= MAX_LABELS:
		get_child(0).queue_free()
	
	var label := _create_label(text, color)
	add_child(label)
	
	# Add a timer to delete the Label3D after some time
	var timer := Timer.new()
	timer.wait_time = 5
	timer.timeout.connect(_label_timer_timeout.bind(label))
	label.add_child(timer)
	timer.start()

func set_unique_label(text: String, id: int, color: Color = Color.WHITE) -> void:
	for i in range(get_child_count()):
		var child := get_child(i) as Label3D
		if child:
			if child.has_meta("id"):
				if child.get_meta("id") == id:
					child.text = text
					child.modulate = color
					return
	
	if get_child_count() >= MAX_LABELS:
		get_child(0).queue_free()
	
	var label := _create_label(text, color)
	label.set_meta("id", id)
	add_child(label)

func _label_timer_timeout(label: Label3D):
	label.queue_free()

func _create_label(text: String, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.modulate = color
	label.font_size = 16
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.no_depth_test = true
	if font == null:
		label.font = font
	
	return label
