class_name EventPanel
extends Control

## UI for dungeon event encounters. Shows narrative text and choice buttons.

signal event_choice_made(choice_index: int)
signal event_dismissed

var _event_data: EventData
var _result_shown: bool = false

func setup(event_data: EventData) -> void:
	_event_data = event_data
	_build_ui()

func _build_ui() -> void:
	# Dark overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(450, 0)
	center.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "📜 %s" % _event_data.title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	
	# Description
	var desc = RichTextLabel.new()
	desc.bbcode_enabled = true
	desc.fit_content = true
	desc.scroll_active = false
	desc.text = _event_data.description
	desc.add_theme_font_size_override("normal_font_size", 14)
	vbox.add_child(desc)
	
	# Separator
	vbox.add_child(HSeparator.new())
	
	# Choices
	for i in range(_event_data.choices.size()):
		var choice = _event_data.choices[i]
		var choice_box = VBoxContainer.new()
		choice_box.add_theme_constant_override("separation", 2)
		vbox.add_child(choice_box)
		
		var btn = Button.new()
		btn.text = choice.label
		btn.custom_minimum_size = Vector2(0, 40)
		var idx = i
		btn.pressed.connect(func(): _on_choice_pressed(idx))
		choice_box.add_child(btn)
		
		if choice.description != "":
			var hint = Label.new()
			hint.text = choice.description
			hint.add_theme_font_size_override("font_size", 11)
			hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			choice_box.add_child(hint)

func _on_choice_pressed(index: int) -> void:
	if _result_shown:
		return
	_result_shown = true
	event_choice_made.emit(index)

func show_result(result_text: String) -> void:
	# Clear old content and show result
	for child in get_children():
		child.queue_free()
	
	var overlay = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 0)
	center.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)
	
	var result_label = Label.new()
	result_label.text = result_text
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(result_label)
	
	var btn = Button.new()
	btn.text = "Continue"
	btn.custom_minimum_size = Vector2(0, 40)
	btn.pressed.connect(func(): event_dismissed.emit())
	vbox.add_child(btn)
