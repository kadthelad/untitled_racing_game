class_name Trait
extends Resource

@export var id := "REFERENCE_ID" # ID reference
@export var i_name := "UNNAMED TRAIT"
@export_multiline var description := "DESCRIPTION EMPTY"
@export var icon: Texture2D = PlaceholderTexture2D.new()
@export var is_positive := true
@export var cost := 1
@export var incompatible_with: Array[String]

@export var stat_modifiers: Dictionary[Runner.STATS, int]
@export var hidden_stat_multipliers: Dictionary[Runner.HIDDEN_STATS, float]

static func empty() -> Trait:
	return Trait.new()

func on_apply() -> void:
	return

func on_process() -> void:
	return

func on_remove() -> void:
	return

func is_compatible_with(other: Trait) -> bool:
	return other.id not in incompatible_with
