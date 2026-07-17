extends CanvasLayer

@onready var keybinds_rich_text_label: RichTextLabel = %KeybindsRichTextLabel

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action_show_keybinds"):
		if keybinds_rich_text_label.scale >= Vector2(1, 1):
			UiAnimationHandler.animate_shrink(keybinds_rich_text_label)
		else:
			UiAnimationHandler.animate_pop(keybinds_rich_text_label)
