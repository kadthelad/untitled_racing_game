class_name PlayerInfoControl
extends Control

@onready var name_label: Label = %NameLabel

@onready var speed: StatProgress = %Speed
@onready var stamina: StatProgress = %Stamina
@onready var strength: StatProgress = %Strength
@onready var intelligence: StatProgress = %Intelligence
@onready var willpower: StatProgress = %Willpower

func show_info(runner: Runner) -> void:
	var runner_stats := runner.stats
	name_label.text = runner.i_name
	speed.stat_slider.value = runner_stats[Runner.STATS.SPEED]
	stamina.stat_slider.value = runner_stats[Runner.STATS.STAMINA]
	strength.stat_slider.value = runner_stats[Runner.STATS.STRENGTH]
	intelligence.stat_slider.value = runner_stats[Runner.STATS.INTELLIGENCE]
	willpower.stat_slider.value = runner_stats[Runner.STATS.WILLPOWER]
	
	show()
