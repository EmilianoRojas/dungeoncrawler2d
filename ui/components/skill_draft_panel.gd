class_name SkillDraftPanel
extends PanelContainer

# Skill Draft UI (GameSpec §4)
# Shows on level-up: offered skill with Learn/Replace/Upgrade/Skip options.

signal draft_completed(action: String, slot_index: int)

var offered_skill: Skill
var current_skills: Array[Skill] = []
var max_slots: int = 4
var upgrade_match: Skill = null
var _upgrade_index: int = -1

# UI references (created dynamically)
var title_label: Label
var skill_info_label: RichTextLabel
var button_container: VBoxContainer
var replace_container: VBoxContainer
var replace_label: Label

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Main layout
	custom_minimum_size = Vector2(400, 350)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	# Title
	title_label = Label.new()
	title_label.text = "⬆ LEVEL UP!"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title_label)
	
	# Offered skill info
	skill_info_label = RichTextLabel.new()
	skill_info_label.bbcode_enabled = true
	skill_info_label.fit_content = true
	skill_info_label.custom_minimum_size = Vector2(0, 80)
	skill_info_label.scroll_active = false
	vbox.add_child(skill_info_label)
	
	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Button container (Learn / Upgrade)
	button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 8)
	vbox.add_child(button_container)
	
	# Replace section (shown when slots are full)
	replace_label = Label.new()
	replace_label.text = "Replace a skill:"
	replace_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	replace_label.visible = false
	vbox.add_child(replace_label)
	
	replace_container = VBoxContainer.new()
	replace_container.add_theme_constant_override("separation", 4)
	replace_container.visible = false
	vbox.add_child(replace_container)

func setup(offered: Skill, skills: Array[Skill], slots: int, upgrade: Skill = null) -> void:
	offered_skill = offered
	current_skills = skills
	max_slots = slots
	upgrade_match = upgrade
	
	# Find upgrade index
	if upgrade_match:
		for i in range(current_skills.size()):
			if current_skills[i] == upgrade_match:
				_upgrade_index = i
				break
	
	_update_display()

func _update_display() -> void:
	# Clear previous buttons
	for child in button_container.get_children():
		child.queue_free()
	for child in replace_container.get_children():
		child.queue_free()
	
	# Show offered skill info
	var scaling_text = ""
	match offered_skill.scaling_type:
		Skill.ScalingType.FLAT:
			scaling_text = "Flat %d" % offered_skill.base_power
		Skill.ScalingType.STAT_PERCENT:
			scaling_text = "%d%% %s + %d" % [int(offered_skill.scaling_percent * 100), offered_skill.scaling_stat, offered_skill.base_power]
	
	var cd_text = "%d turns" % offered_skill.max_cooldown if offered_skill.max_cooldown > 0 else "None"
	
	skill_info_label.text = ""
	skill_info_label.append_text("[b]%s[/b]\n" % offered_skill.skill_name)
	skill_info_label.append_text("Power: %s | Hit: %d%% | CD: %s" % [scaling_text, offered_skill.hit_chance, cd_text])
	
	# Check for upgrade
	if upgrade_match:
		var btn = Button.new()
		btn.text = "⬆ Upgrade %s (Lv %d → %d)" % [upgrade_match.skill_name, upgrade_match.skill_level, upgrade_match.skill_level + 1]
		btn.pressed.connect(func(): _on_upgrade())
		button_container.add_child(btn)
	
	# Check if slots available
	var has_space = current_skills.size() < max_slots
	
	if has_space and not upgrade_match:
		var learn_btn = Button.new()
		learn_btn.text = "✓ Learn Skill"
		learn_btn.pressed.connect(func(): _on_learn())
		button_container.add_child(learn_btn)
	elif not has_space and not upgrade_match:
		# Slots full — show replace options
		replace_label.visible = true
		replace_container.visible = true
		
		for i in range(current_skills.size()):
			var skill = current_skills[i]
			var btn = Button.new()
			btn.text = "Replace: %s (Lv %d)" % [skill.skill_name, skill.skill_level]
			var idx = i
			btn.pressed.connect(func(): _on_replace(idx))
			replace_container.add_child(btn)
	
	# Reroll button
	var reroll_cost := CurrencyManager.SKILL_REROLL_COST
	var can_reroll  := CurrencyManager.has_enough(reroll_cost)
	var reroll_btn  := Button.new()
	reroll_btn.text = "🔄 Reroll  (%d 🔷)" % reroll_cost
	reroll_btn.disabled = not can_reroll
	if not can_reroll:
		reroll_btn.tooltip_text = "Not enough Shards"
	reroll_btn.pressed.connect(func(): _on_reroll())
	button_container.add_child(reroll_btn)

	# Always show skip
	var skip_btn = Button.new()
	skip_btn.text = "✗ Skip"
	skip_btn.pressed.connect(func(): _on_skip())
	button_container.add_child(skip_btn)

func _on_learn() -> void:
	draft_completed.emit("learn", -1)
	queue_free()

func _on_upgrade() -> void:
	draft_completed.emit("upgrade", _upgrade_index)
	queue_free()

func _on_replace(index: int) -> void:
	draft_completed.emit("replace", index)
	queue_free()

func _on_reroll() -> void:
	draft_completed.emit("reroll", -1)
	# Don't free — GameLoop will replace this panel with a new offer

func _on_skip() -> void:
	draft_completed.emit("skip", -1)
	queue_free()
