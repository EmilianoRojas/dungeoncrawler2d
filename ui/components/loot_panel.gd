class_name LootPanel
extends CenterContainer

## Emitted when the player makes a choice. true = equip, false = skip.
signal loot_choice(equip: bool)

# Rarity → color mapping
const RARITY_COLORS = {
	"Common": Color(0.8, 0.8, 0.8),
	"Rare": Color(0.3, 0.5, 1.0),
	"Epic": Color(0.7, 0.3, 0.9),
	"Legendary": Color(1.0, 0.65, 0.0),
}

var _item: EquipmentResource
var _current_item: EquipmentResource

func setup(item: EquipmentResource, current_equipped: EquipmentResource = null) -> void:
	_item = item
	_current_item = current_equipped
	_build_ui()

func _build_ui() -> void:
	# Semi-transparent backdrop
	var backdrop = ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.6)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP # block clicks behind
	add_child(backdrop)
	
	# Main panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	style.border_color = _get_rarity_color()
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_width_left = 3
	style.border_width_right = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	# Header: "LOOT FOUND"
	var header = Label.new()
	header.text = "🎁 LOOT FOUND"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	vbox.add_child(header)
	
	# Separator
	vbox.add_child(HSeparator.new())
	
	# Item name (rarity-colored)
	var name_label = Label.new()
	name_label.text = _item.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", _get_rarity_color())
	vbox.add_child(name_label)
	
	# Rarity + Slot
	var info_label = Label.new()
	info_label.text = "%s • %s" % [_item.rarity, EquipmentSlot.Type.keys()[_item.slot]]
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 13)
	info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(info_label)
	
	# Stat effects
	var effects_text = _format_effects(_item)
	if effects_text != "":
		var effects_label = RichTextLabel.new()
		effects_label.bbcode_enabled = true
		effects_label.fit_content = true
		effects_label.scroll_active = false
		effects_label.text = effects_text
		effects_label.add_theme_font_size_override("normal_font_size", 13)
		vbox.add_child(effects_label)
	
	# Skills granted
	if _item.granted_skills.size() > 0:
		var skills_label = Label.new()
		var skill_names: Array[String] = []
		for s in _item.granted_skills:
			if s is Skill:
				skill_names.append(s.skill_name)
		skills_label.text = "Grants: %s" % ", ".join(skill_names)
		skills_label.add_theme_color_override("font_color", Color(0.4, 0.85, 0.4))
		skills_label.add_theme_font_size_override("font_size", 13)
		vbox.add_child(skills_label)
	
	# Comparison with current equipped
	if _current_item:
		vbox.add_child(HSeparator.new())
		
		var compare_header = Label.new()
		compare_header.text = "Currently Equipped:"
		compare_header.add_theme_font_size_override("font_size", 12)
		compare_header.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		vbox.add_child(compare_header)
		
		var current_name = Label.new()
		current_name.text = "%s [%s]" % [_current_item.display_name, _current_item.rarity]
		current_name.add_theme_font_size_override("font_size", 13)
		var cur_color = RARITY_COLORS.get(_current_item.rarity, Color(0.7, 0.7, 0.7))
		current_name.add_theme_color_override("font_color", cur_color)
		vbox.add_child(current_name)
		
		var cur_effects = _format_effects(_current_item)
		if cur_effects != "":
			var cur_effects_label = RichTextLabel.new()
			cur_effects_label.bbcode_enabled = true
			cur_effects_label.fit_content = true
			cur_effects_label.scroll_active = false
			cur_effects_label.text = cur_effects
			cur_effects_label.add_theme_font_size_override("normal_font_size", 12)
			vbox.add_child(cur_effects_label)
	
	# Separator
	vbox.add_child(HSeparator.new())
	
	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)
	
	var equip_btn = Button.new()
	equip_btn.text = "✅ Equip"
	equip_btn.custom_minimum_size = Vector2(140, 42)
	equip_btn.pressed.connect(func(): loot_choice.emit(true))
	btn_row.add_child(equip_btn)
	
	var skip_btn = Button.new()
	skip_btn.text = "❌ Skip"
	skip_btn.custom_minimum_size = Vector2(140, 42)
	skip_btn.pressed.connect(func(): loot_choice.emit(false))
	btn_row.add_child(skip_btn)

func _get_rarity_color() -> Color:
	return RARITY_COLORS.get(_item.rarity, Color(0.8, 0.8, 0.8))

func _format_effects(item: EquipmentResource) -> String:
	var lines: Array[String] = []
	for effect in item.equip_effects:
		if effect.operation == EffectResource.Operation.ADD_STAT_MODIFIER and effect.stat_modifier:
			var mod = effect.stat_modifier
			var prefix = "+" if mod.value >= 0 else ""
			var type_str = "%" if mod.type == StatModifier.Type.PERCENT_ADD else ""
			lines.append("[color=#8aff8a]%s%s%s %s[/color]" % [prefix, int(mod.value), type_str, str(mod.stat).capitalize()])
		elif effect.stat_type != &"":
			var prefix = "+" if effect.value >= 0 else ""
			lines.append("[color=#8aff8a]%s%d %s[/color]" % [prefix, int(effect.value), str(effect.stat_type).capitalize()])
	for effect in item.passive_effects:
		lines.append("[color=#c89aff]Passive: %s[/color]" % str(effect.effect_id).capitalize())
	return "\n".join(lines)
