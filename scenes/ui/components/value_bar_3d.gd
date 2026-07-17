@tool
extends Node3D
class_name ValueBar3D

@export var text: String = "ValueBar3D" : set = _set_text
@export var bar_color: Color = Color.GRAY : set = _set_color
@export var background_color: Color = Color.WHITE : set = _set_color_bg
@export_range(0, 100, 1) var value: float = 100.0 : set = _set_value
@export_range(0, 100, 1) var value_bg: float = 100.0 : set = _set_value_bg

@onready var display_label: Label3D = %DisplayLabel
@onready var bar_progression: Node3D = %BarProgression
@onready var bar_progression_bg: Node3D = %BarProgressionBG
@onready var progression_bar_mesh: MeshInstance3D = %ProgressionBarMesh
@onready var progression_bar_bg_mesh: MeshInstance3D = %ProgressionBarBGMesh

func _ready() -> void:
	_make_material_unique(progression_bar_mesh)
	_make_material_unique(progression_bar_bg_mesh)
	_set_text(text)
	_set_color(bar_color)
	_set_color_bg(background_color)
	_set_value(value)
	_set_value_bg(value_bg)

func _make_material_unique(mesh: MeshInstance3D) -> void:
	if mesh == null:
		return
	var material := mesh.get_surface_override_material(0) as StandardMaterial3D
	if material:
		mesh.set_surface_override_material(0, material.duplicate())

func _set_text(new_value: String) -> void:
	text = new_value
	if display_label == null:
		return
	display_label.text = text

func _set_color(new_value: Color) -> void:
	bar_color = new_value
	if progression_bar_mesh == null:
		return
	var material := progression_bar_mesh.get_surface_override_material(0) as StandardMaterial3D
	if material:
		material.albedo_color = bar_color

func _set_color_bg(new_value: Color) -> void:
	background_color = new_value
	if progression_bar_bg_mesh == null:
		return
	var material := progression_bar_bg_mesh.get_surface_override_material(0) as StandardMaterial3D
	if material:
		material.albedo_color = background_color

func _set_value(new_value: float) -> void:
	value = new_value
	bar_progression.scale = Vector3(1, value / 100.0, 1)

func _set_value_bg(new_value: float) -> void:
	value_bg = new_value
	bar_progression_bg.scale = Vector3(1, value_bg / 100.0, 1)
