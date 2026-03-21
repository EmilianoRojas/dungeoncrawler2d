class_name GameOverScreen
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
	title.text = "💀 DEFEATED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	vbox.add_child(title)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Your journey ends here..."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
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
	_add_stat_line(stats_box, "Level Reached", str(_stats.get("level", 1)))
	_add_stat_line(stats_box, "Floor", str(_stats.get("floor", 1)))
	_add_stat_line(stats_box, "Depth", str(_stats.get("depth", 0)))
	_add_stat_line(stats_box, "Rooms Cleared", str(_stats.get("rooms_cleared", 0)))
	
	# Runes unlocked this run
	var new_runes: Array = _stats.get("new_runes", [])
	if not new_runes.is_empty():
		vbox.add_child(HSeparator.new())
		var rune_title = Label.new()
		rune_title.text = "✨ Runes Unlocked"
		rune_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rune_title.add_theme_font_size_override("font_size", 16)
		rune_title.add_theme_color_override("font_color", Color(0.9, 0.75, 1.0))
		vbox.add_child(rune_title)
		for rune_id in new_runes:
			var rune = RuneLibrary.get_rune(StringName(str(rune_id)))
			if rune:
				var tier_colors = {
					RuneResource.Tier.COMMON:    Color(0.8, 0.8, 0.8),
					RuneResource.Tier.RARE:      Color(0.4, 0.6, 1.0),
					RuneResource.Tier.EPIC:      Color(0.8, 0.4, 1.0),
					RuneResource.Tier.LEGENDARY: Color(1.0, 0.75, 0.2),
				}
				var col = tier_colors.get(rune.tier, Color.WHITE)
				_add_stat_line(vbox, rune.display_name, RuneResource.Tier.keys()[rune.tier], col)

	# Separator
	vbox.add_child(HSeparator.new())

	# Return button
	var btn = Button.new()
	btn.text = "⚔ Return to Lobby"
	btn.custom_minimum_size = Vector2(0, 50)
	btn.pressed.connect(_on_return_pressed)
	vbox.add_child(btn)

func _add_stat_line(parent: VBoxContainer, label_text: String, value_text: String, value_color: Color = Color.WHITE) -> void:
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
	value.add_theme_color_override("font_color", value_color)
	hbox.add_child(value)

func _on_return_pressed() -> void:
	return_to_lobby.emit()
