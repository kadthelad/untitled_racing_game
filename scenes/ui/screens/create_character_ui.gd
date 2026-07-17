extends CanvasLayer

@onready var stats_tab: Panel = %StatsTab
@onready var traits_tab: Panel = %TraitsTab
@onready var skill_tab: Panel = %SkillTab

# Tabs
@onready var ui_tabs: Array[Control] = [stats_tab, traits_tab, skill_tab]
var current_tab_index := 0

# StatsTab
const DEFAULT_STAT_POINTS := 2500
@onready var stat_points_left_label: Label = %StatPointsLeftLabel
@onready var speed: StatSlider = %Speed
@onready var endurance: StatSlider = %Endurance
@onready var power: StatSlider = %Power
@onready var intelligence: StatSlider = %Intelligence
@onready var willpower: StatSlider = %Willpower
@onready var stat_sliders: Array[StatSlider] = [speed, endurance, power, intelligence, willpower]

# TraitsTab
@onready var trait_points_left_label: Label = %TraitPointsLeftLabel
@onready var pos_traits_item_list: ItemList = %PosTraitsItemList
@onready var neg_traits_item_list: ItemList = %NegTraitsItemList
@onready var active_traits_item_list: ItemList = %ActiveTraitsItemList
@onready var trait_effects_item_list: ItemList = %TraitEffectsItemList

const DEFAULT_TRAIT_POINTS := 6
var trait_points_left := 0:
	set(value):
		trait_points_left = value
		trait_points_left_label.text = "Points left to spend: " + str(trait_points_left)
var traits_array: Array[Trait]

# SkillsTab
const STARTING_SKILL_POINTS := 300

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# === Setup StatsTab
	for stat_slider : StatSlider in stat_sliders:
		stat_slider.stat_slider.value_changed.connect(_on_stat_value_changed)
	
	# === Setup TraitsTab
	trait_points_left = DEFAULT_TRAIT_POINTS
	# Load the traits in the ItemLists
	var TRAITS_PATH := "res://scripts/resources/traits/"
	var dir_access := DirAccess.open(TRAITS_PATH)
	if dir_access:
		for file in dir_access.get_files():
			traits_array.append(load(TRAITS_PATH + file))
		_build_trait_map()
		load_traits()
	
	switch_tab(stats_tab)

func switch_tab(tab_to_go: Control) -> void:
	if ui_tabs.has(tab_to_go):
		for tab: Control in ui_tabs:
			if tab != tab_to_go:
				tab.hide()
			else:
				tab.show()
				current_tab_index = ui_tabs.find(tab_to_go)


func _on_back_button_pressed() -> void:
	if current_tab_index - 1 >= 0: # Go to previous window if possible
		switch_tab(ui_tabs[current_tab_index - 1])
	else: # Else, return to main menu
		queue_free()


func _on_next_button_pressed() -> void:
	if current_tab_index + 1 < ui_tabs.size(): # Go to next window if possible
		switch_tab(ui_tabs[current_tab_index + 1])
	else: # Else, return to main menu
		queue_free()

# STATS
func _on_stat_value_changed(value: float) -> void:
	var stat_points_left := DEFAULT_STAT_POINTS 
	for stat_slider : StatSlider in stat_sliders:
		stat_points_left -= int(stat_slider.stat_slider.value)
	stat_points_left_label.text = "Points left to spend: " + str(stat_points_left)

func _on_stat_reset_button_pressed() -> void:
	for stat_slider : StatSlider in stat_sliders:
		stat_slider.stat_slider.value = 0

# TRAITS
var _traits_by_id: Dictionary[String, Trait] = {}

func _build_trait_map() -> void:
	for current_trait: Trait in traits_array:
		_traits_by_id[current_trait.id] = current_trait

func get_trait_from_id(trait_id: String) -> Trait:
	return _traits_by_id.get(trait_id, Trait.empty())

func load_traits() -> void:
	pos_traits_item_list.clear()
	neg_traits_item_list.clear()
	for current_trait: Trait in traits_array:
		var target_list := pos_traits_item_list if current_trait.is_positive else neg_traits_item_list
		_add_trait_to_list(target_list, current_trait)

func _add_trait_to_list(list: ItemList, current_trait: Trait) -> void:
	@warning_ignore("shadowed_global_identifier")
	var sign := "-" if current_trait.is_positive else "+"
	var color := Color.GREEN if current_trait.is_positive else Color.RED
	var idx := list.item_count
	list.add_item("%s %s%d" % [current_trait.i_name, sign, current_trait.cost], current_trait.icon)
	list.set_item_tooltip(idx, current_trait.description)
	list.set_item_metadata(idx, current_trait.id)
	list.set_item_custom_fg_color(idx, color)

func add_trait(trait_to_add: Trait) -> bool:
	for i in range(active_traits_item_list.item_count):
		var other := get_trait_from_id(active_traits_item_list.get_item_metadata(i))
		if !trait_to_add.is_compatible_with(other):
			return false
	
	_add_trait_to_list(active_traits_item_list, trait_to_add)
	trait_points_left += -trait_to_add.cost if trait_to_add.is_positive else trait_to_add.cost
	return true

func _on_pos_traits_item_list_item_selected(index: int) -> void:
	if add_trait(get_trait_from_id(pos_traits_item_list.get_item_metadata(index))):
		pos_traits_item_list.remove_item(index)
	pos_traits_item_list.deselect_all()

func _on_neg_traits_item_list_item_selected(index: int) -> void:
	if add_trait(get_trait_from_id(neg_traits_item_list.get_item_metadata(index))):
		neg_traits_item_list.remove_item(index)
	neg_traits_item_list.deselect_all()

func _on_active_traits_item_list_item_selected(index: int) -> void:
	var current_trait := get_trait_from_id(active_traits_item_list.get_item_metadata(index))
	var target_list := pos_traits_item_list if current_trait.is_positive else neg_traits_item_list
	_add_trait_to_list(target_list, current_trait)
	trait_points_left += current_trait.cost if current_trait.is_positive else -current_trait.cost
	active_traits_item_list.remove_item(index)

func _on_traits_reset_button_pressed() -> void:
	active_traits_item_list.clear()
	trait_points_left = DEFAULT_TRAIT_POINTS
	load_traits()
