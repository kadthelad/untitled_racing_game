class_name StatSlider
extends HBoxContainer

@onready var value_label: Label = %ValueLabel
@onready var stat_slider: HSlider = %StatSlider
@onready var rank_label: Label = %RankLabel

func _on_stat_slider_value_changed(value: float) -> void:
	value_label.text = str(int(value))
	rank_label.text = Runner.get_rank(int(value))
