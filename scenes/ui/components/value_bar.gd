class_name ValueBar
extends HBoxContainer

@export var text: String = "ValueBar": set = _set_text
@export var bar_color: Color = Color.GRAY: set = _set_bar_color
@export var background_color: Color = Color.WHITE: set = _set_background_color
@export_range(0, 100, 1) var value: float = 100.0: set = _set_value
@export_range(0, 100, 1) var value_bg: float = 100.0: set = _set_value_bg

@onready var display_label: Label = %DisplayLabel
@onready var background_bar: ColorRect = %BackgroundBar
@onready var foreground_bar: ColorRect = %ForegroundBar

func _ready() -> void:
	_set_text(text)
	_set_bar_color(bar_color)
	_set_background_color(background_color)
	_set_value(value)
	_set_value_bg(value_bg)

func _set_text(new_value: String) -> void:
	text = new_value
	if display_label:
		display_label.text = text

func _set_bar_color(new_value: Color) -> void:
	bar_color = new_value
	if foreground_bar:
		foreground_bar.color = bar_color

func _set_background_color(new_value: Color) -> void:
	background_color = new_value
	if background_bar:
		background_bar.color = background_color

func _set_value(new_value: float) -> void:
	value = new_value
	if foreground_bar:
		foreground_bar.anchor_right = value / 100.0

func _set_value_bg(new_value: float) -> void:
	value_bg = new_value
	if background_bar:
		background_bar.anchor_right = value_bg / 100.0
