class_name RunePanel
extends CenterContainer

signal panel_closed

const TIER_COLORS: Dictionary = {
	RuneResource.Tier.COMMON:    Color(0.85, 0.85, 0.85),
	RuneResource.Tier.RARE:      Color(0.4,  0.6,  1.0),
	RuneResource.Tier.LEGENDARY: Color(1.0,  0.8,  0.2),
}
const TIER_LABELS: Dictionary = {
	RuneResource.Tier.COMMON:    "C",
	RuneResource.Tier.RARE:      "R",
	RuneResource.Tier.LEGENDARY: "L",
}

var _entity: Entity
var _class_title: String

var _cost_label: Label
var _equipped_list: VBoxContainer
var _available_list: VBoxContainer

func setup(entity: Entity, class_title: String) -> void:
	_entity      = entity
	_class_title = class_title
	_build_ui()
	_refresh()

func _build_ui() -> void:
	# Fullscreen dimmed backdrop
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.6)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	# Main panel
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(680, 0)
	var style := StyleBoxFlat.new()
	style.bg_color           = Color(0.08, 0.08, 0.13, 0.97)
	style.border_color       = Color(0.6, 0.45, 0.9)
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.corner_radius_top_left     = 8
	style.corner_radius_top_right    = 8
	style.corner_radius_bottom_left  = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left   = 20
	style.content_margin_right  = 20
	style.content_margin_top    = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	# Title
	var title := Label.new()
	title.text = "💎 Runes — %s" % _class_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.85, 0.7, 1.0))
	root.add_child(title)

	# Cost budget
	_cost_label = Label.new()
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost_label.add_theme_font_size_override("font_size", 13)
	root.add_child(_cost_label)

	root.add_child(HSeparator.new())

	# Two-column layout
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	root.add_child(columns)

	# --- Equipped column ---
	var eq_col := VBoxContainer.new()
	eq_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eq_col.add_theme_constant_override("separation", 6)
	columns.add_child(eq_col)

	var eq_header := Label.new()
	eq_header.text = "⚔ Equipped"
	eq_header.add_theme_font_size_override("font_size", 15)
	eq_header.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
	eq_col.add_child(eq_header)

	var eq_scroll := ScrollContainer.new()
	eq_scroll.custom_minimum_size = Vector2(0, 220)
	eq_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	eq_col.add_child(eq_scroll)

	_equipped_list = VBoxContainer.new()
	_equipped_list.add_theme_constant_override("separation", 4)
	eq_scroll.add_child(_equipped_list)

	# --- Available column ---
	var av_col := VBoxContainer.new()
	av_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	av_col.add_theme_constant_override("separation", 6)
	columns.add_child(av_col)

	var av_header := Label.new()
	av_header.text = "📦 Available"
	av_header.add_theme_font_size_override("font_size", 15)
	av_header.add_theme_color_override("font_color", Color(0.5, 0.75, 1.0))
	av_col.add_child(av_header)

	var av_scroll := ScrollContainer.new()
	av_scroll.custom_minimum_size = Vector2(0, 220)
	av_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	av_col.add_child(av_scroll)

	_available_list = VBoxContainer.new()
	_available_list.add_theme_constant_override("separation", 4)
	av_scroll.add_child(_available_list)

	root.add_child(HSeparator.new())

	# Tier legend
	var legend := HBoxContainer.new()
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	legend.add_theme_constant_override("separation", 14)
	root.add_child(legend)
	for tier in TIER_COLORS:
		var lbl := Label.new()
		lbl.text = "[%s] %s  Cost: %d" % [
			TIER_LABELS[tier],
			RuneResource.Tier.keys()[tier],
			RuneLibrary.get_cost(tier)
		]
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", TIER_COLORS[tier])
		legend.add_child(lbl)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "✖ Close"
	close_btn.custom_minimum_size = Vector2(0, 36)
	close_btn.pressed.connect(func(): panel_closed.emit())
	root.add_child(close_btn)

func _refresh() -> void:
	if not _cost_label or not _equipped_list or not _available_list:
		return

	var used  := RuneManager.get_used_cost(_class_title)
	var max_c := RuneManager.MAX_COST
	_cost_label.text = "Cost Used: %d / %d" % [used, max_c]
	_cost_label.add_theme_color_override("font_color",
		Color(1.0, 0.4, 0.4) if used >= max_c else Color(0.6, 1.0, 0.6))

	# Clear lists
	for c in _equipped_list.get_children():
		c.queue_free()
	for c in _available_list.get_children():
		c.queue_free()

	var equipped_ids := RuneManager.get_equipped(_class_title)

	# Equipped runes
	if equipped_ids.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "None equipped"
		empty_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		empty_lbl.add_theme_font_size_override("font_size", 12)
		_equipped_list.add_child(empty_lbl)
	else:
		for rune_id in equipped_ids:
			var rune := RuneLibrary.get_rune(rune_id)
			if rune:
				_equipped_list.add_child(_make_rune_button(rune, true))

	# Available (unlocked but not equipped)
	var any_available := false
	for rune_id in RuneManager.unlocked_rune_ids:
		if equipped_ids.has(rune_id):
			continue
		var rune := RuneLibrary.get_rune(rune_id)
		if rune:
			_available_list.add_child(_make_rune_button(rune, false))
			any_available = true

	if not any_available:
		var empty_lbl := Label.new()
		empty_lbl.text = "No runes unlocked yet.\nDefeat enemies to find them!"
		empty_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		_available_list.add_child(empty_lbl)

func _make_rune_button(rune: RuneResource, is_equipped: bool) -> Button:
	var cost       := RuneLibrary.get_cost(rune.tier)
	var tier_color := TIER_COLORS[rune.tier]
	var tier_tag   := TIER_LABELS[rune.tier]
	var affordable := is_equipped or RuneManager.can_equip(_class_title, rune.id)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 46)
	btn.clip_text = false

	# Style the button
	var btn_style := StyleBoxFlat.new()
	if is_equipped:
		btn_style.bg_color     = Color(0.1, 0.22, 0.12, 0.9)
		btn_style.border_color = Color(0.3, 0.9, 0.4, 0.8)
	elif affordable:
		btn_style.bg_color     = Color(0.1, 0.1, 0.18, 0.9)
		btn_style.border_color = tier_color * Color(1, 1, 1, 0.7)
	else:
		btn_style.bg_color     = Color(0.08, 0.08, 0.1, 0.7)
		btn_style.border_color = Color(0.3, 0.3, 0.3, 0.5)
	btn_style.border_width_top    = 1
	btn_style.border_width_bottom = 1
	btn_style.border_width_left   = 1
	btn_style.border_width_right  = 1
	btn_style.corner_radius_top_left     = 4
	btn_style.corner_radius_top_right    = 4
	btn_style.corner_radius_bottom_left  = 4
	btn_style.corner_radius_bottom_right = 4
	btn_style.content_margin_left  = 8
	btn_style.content_margin_right = 8
	btn.add_theme_stylebox_override("normal", btn_style)

	# Inner layout
	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 6)
	btn.add_child(hbox)

	# Tier badge
	var badge := Label.new()
	badge.text = "[%s]" % tier_tag
	badge.custom_minimum_size = Vector2(24, 0)
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", tier_color)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(badge)

	# Name + desc
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = rune.display_name
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color",
		tier_color if affordable else Color(0.4, 0.4, 0.4))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = rune.description
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(desc_lbl)

	# Cost badge
	var cost_lbl := Label.new()
	cost_lbl.text = "⚡%d" % cost
	cost_lbl.add_theme_font_size_override("font_size", 12)
	cost_lbl.add_theme_color_override("font_color",
		Color(1.0, 0.8, 0.2) if affordable else Color(0.5, 0.4, 0.3))
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(cost_lbl)

	# Action label
	var action_lbl := Label.new()
	action_lbl.add_theme_font_size_override("font_size", 11)
	action_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_equipped:
		action_lbl.text = "✕"
		action_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	elif affordable:
		action_lbl.text = "+"
		action_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	else:
		action_lbl.text = "✗"
		action_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		btn.disabled = true
	hbox.add_child(action_lbl)

	# Connect press
	if is_equipped:
		btn.pressed.connect(func(): _on_unequip(rune.id))
	elif affordable:
		btn.pressed.connect(func(): _on_equip(rune.id))

	return btn

func _on_equip(rune_id: StringName) -> void:
	if RuneManager.equip_rune(_class_title, rune_id):
		_apply_and_refresh()

func _on_unequip(rune_id: StringName) -> void:
	RuneManager.unequip_rune(_class_title, rune_id)
	_apply_and_refresh()

func _apply_and_refresh() -> void:
	if _entity:
		RuneManager.apply_runes_to_entity(_entity, _class_title)
	_refresh()
