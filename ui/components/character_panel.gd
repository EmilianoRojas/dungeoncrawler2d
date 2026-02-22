class_name CharacterPanel
extends CenterContainer

## Toggleable overlay showing player stats and equipped gear.

signal panel_closed

var _entity: Entity

func setup(entity: Entity) -> void:
	_entity = entity
	_build_ui()

func _build_ui() -> void:
	# Semi-transparent backdrop
	var backdrop = ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.55)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	
	# Panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.16, 0.95)
	style.border_color = Color(0.45, 0.55, 0.75)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
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
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	# Header
	var header = Label.new()
	header.text = "🛡 %s — Lv %d" % [_entity.name, _entity.level]
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	vbox.add_child(header)
	
	vbox.add_child(HSeparator.new())
	
	# === STATS SECTION ===
	var stats_header = Label.new()
	stats_header.text = "Stats"
	stats_header.add_theme_font_size_override("font_size", 16)
	stats_header.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	vbox.add_child(stats_header)
	
	var stats_grid = GridContainer.new()
	stats_grid.columns = 4
	stats_grid.add_theme_constant_override("h_separation", 16)
	stats_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(stats_grid)
	
	# Display stats in a clean grid
	var display_stats: Array[Array] = [
		[StatTypes.HP, "HP"],
		[StatTypes.MAX_HP, "Max HP"],
		[StatTypes.STRENGTH, "STR"],
		[StatTypes.DEFENSE, "DEF"],
		[StatTypes.SPEED, "SPD"],
		[StatTypes.INTELLIGENCE, "INT"],
		[StatTypes.DEXTERITY, "DEX"],
		[StatTypes.PIETY, "PIE"],
		[StatTypes.POWER, "POW"],
		[StatTypes.CRIT_CHANCE, "Crit%"],
		[StatTypes.CRIT_DAMAGE, "CritDmg"],
		[StatTypes.PARRY_CHANCE, "Parry%"],
		[StatTypes.AVOID_CHANCE, "Avoid%"],
		[StatTypes.ACCURACY, "Acc"],
		[StatTypes.SHIELD, "Shield"],
		[StatTypes.MAX_SHIELD, "Max Shld"],
	]
	
	for entry in display_stats:
		var stat_key: StringName = entry[0]
		var label_text: String = entry[1]
		var val = _entity.stats.get_stat(stat_key) if _entity.stats else 0
		if val == 0 and stat_key != StatTypes.HP:
			continue # Skip zero stats to declutter
		
		var name_lbl = Label.new()
		name_lbl.text = label_text
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		stats_grid.add_child(name_lbl)
		
		var val_lbl = Label.new()
		# For HP show current/max
		if stat_key == StatTypes.HP:
			var current_hp = _entity.stats.get_current(StatTypes.HP) if _entity.stats else 0
			val_lbl.text = "%d/%d" % [current_hp, _entity.stats.get_stat(StatTypes.MAX_HP)]
			val_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		else:
			val_lbl.text = str(val)
			val_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		val_lbl.add_theme_font_size_override("font_size", 13)
		stats_grid.add_child(val_lbl)
	
	vbox.add_child(HSeparator.new())
	
	# === EQUIPMENT SECTION ===
	var equip_header = Label.new()
	equip_header.text = "Equipment"
	equip_header.add_theme_font_size_override("font_size", 16)
	equip_header.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4))
	vbox.add_child(equip_header)
	
	var slot_names = {
		EquipmentSlot.Type.WEAPON: "⚔ Weapon",
		EquipmentSlot.Type.ARMOR: "🛡 Armor",
		EquipmentSlot.Type.HELMET: "🪖 Helmet",
	}
	
	for slot in slot_names:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)
		
		var slot_lbl = Label.new()
		slot_lbl.text = slot_names[slot] + ":"
		slot_lbl.custom_minimum_size = Vector2(100, 0)
		slot_lbl.add_theme_font_size_override("font_size", 13)
		slot_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		row.add_child(slot_lbl)
		
		var item_lbl = Label.new()
		if _entity.equipment and _entity.equipment.equipped_items.has(slot):
			var item = _entity.equipment.equipped_items[slot] as EquipmentResource
			item_lbl.text = "%s [%s]" % [item.display_name, item.rarity]
			var rarity_color = LootPanel.RARITY_COLORS.get(item.rarity, Color(0.8, 0.8, 0.8))
			item_lbl.add_theme_color_override("font_color", rarity_color)
		else:
			item_lbl.text = "— Empty —"
			item_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		item_lbl.add_theme_font_size_override("font_size", 13)
		row.add_child(item_lbl)
	
	# === SKILLS SECTION ===
	if _entity.skills and _entity.skills.known_skills.size() > 0:
		vbox.add_child(HSeparator.new())
		
		var skills_header = Label.new()
		skills_header.text = "Skills"
		skills_header.add_theme_font_size_override("font_size", 16)
		skills_header.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
		vbox.add_child(skills_header)
		
		for skill in _entity.skills.known_skills:
			var skill_lbl = Label.new()
			skill_lbl.text = "• %s (Lv %d)" % [skill.skill_name, skill.skill_level]
			skill_lbl.add_theme_font_size_override("font_size", 13)
			skill_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
			vbox.add_child(skill_lbl)
	
	vbox.add_child(HSeparator.new())
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "✖ Close"
	close_btn.custom_minimum_size = Vector2(0, 38)
	close_btn.pressed.connect(func(): panel_closed.emit())
	vbox.add_child(close_btn)
