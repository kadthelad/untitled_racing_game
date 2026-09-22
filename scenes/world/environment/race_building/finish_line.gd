class_name FinishLine
extends Node3D

signal on_finish_line_crossed

var placing: Array[Racer] = []

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Racer:
		placing.append(body)
		on_finish_line_crossed.emit(body)
