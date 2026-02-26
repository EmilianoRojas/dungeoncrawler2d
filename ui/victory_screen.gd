class_name VictoryScreen
extends Control

signal return_to_lobby

var _stats: Dictionary = {}

func setup(stats: Dictionary = {}) -> void:
	_stats = stats
	_build_ui()

func _build_ui() -> void:
	# Dark overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(400, 0)
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "🏆 VICTORY!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "The dungeon has been conquered!"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	vbox.add_child(subtitle)
	
	# Separator
	vbox.add_child(HSeparator.new())
	
	# Run stats
	var stats_box = VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 6)
	vbox.add_child(stats_box)
	
	var stats_title = Label.new()
	stats_title.text = "Run Summary"
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_title.add_theme_font_size_override("font_size", 18)
	stats_box.add_child(stats_title)
	
	_add_stat_line(stats_box, "Class", _stats.get("class_name", "Unknown"))
	_add_stat_line(stats_box, "Final Level", str(_stats.get("level", 1)))
	_add_stat_line(stats_box, "Floors Cleared", str(_stats.get("floor", 1)))
	_add_stat_line(stats_box, "Rooms Cleared", str(_stats.get("rooms_cleared", 0)))
	
	# Separator
	vbox.add_child(HSeparator.new())
	
	# Return button
	var btn = Button.new()
	btn.text = "⚔ Return to Lobby"
	btn.custom_minimum_size = Vector2(0, 50)
	btn.pressed.connect(_on_return_pressed)
	vbox.add_child(btn)

func _add_stat_line(parent: VBoxContainer, label_text: String, value_text: String) -> void:
	var hbox = HBoxContainer.new()
	parent.add_child(hbox)
	
	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hbox.add_child(label)
	
	var value = Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	hbox.add_child(value)

func _on_return_pressed() -> void:
	return_to_lobby.emit()
