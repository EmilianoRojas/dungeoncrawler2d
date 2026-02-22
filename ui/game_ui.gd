class_name GameUI
extends Control

signal command_submitted(cmd: String)
signal skill_activated(skill: Skill)
signal room_selected(index: int)
signal skill_draft_choice(action: String, slot_index: int)
signal camp_action_chosen(action: String)
signal loot_decision(equip: bool)

# Top Bar
@onready var floor_label: Label = $TopBar/HBoxContainer/FloorLabel
@onready var depth_label: Label = $TopBar/HBoxContainer/DepthLabel
@onready var modifier_label: Label = $TopBar/HBoxContainer/ModifierLabel
@onready var level_label: Label = $TopBar/HBoxContainer/LevelLabel
@onready var xp_label: Label = $TopBar/HBoxContainer/XPLabel

# Battle UI
@onready var battle_container: HBoxContainer = $BattleContainer
@onready var skill_container: HBoxContainer = $SkillContainer

@onready var player_hp: HPBar = $BattleContainer/PlayerInfo/HPBar
@onready var player_shield: HPBar = $BattleContainer/PlayerInfo/ShieldBar
@onready var enemy_hp: HPBar = $BattleContainer/EnemyInfo/HPBar
@onready var enemy_shield: HPBar = $BattleContainer/EnemyInfo/ShieldBar
@onready var enemy_label: Label = $BattleContainer/EnemyInfo/Label

# Log
@onready var log_label: RichTextLabel = $Panel/RichTextLabel

# Room Selector (instantiated dynamically)
const ROOM_SELECTOR_SCENE = preload("res://ui/components/room_selector.tscn")
var room_selector: RoomSelector

const SKILL_BTN_SCENE = preload("res://ui/components/skill_button.tscn")
const SKILL_DRAFT_SCENE = preload("res://ui/components/skill_draft_panel.tscn")

var active_draft: SkillDraftPanel = null
var _camp_menu_wrapper: CenterContainer = null
var _loot_panel: LootPanel = null
var _char_panel: CharacterPanel = null
var _stats_button: Button = null
var _player_ref: Entity = null

func _ready() -> void:
	# Initialize Room Selector
	room_selector = ROOM_SELECTOR_SCENE.instantiate()
	add_child(room_selector)
	room_selector.visible = false
	room_selector.room_selected.connect(_on_room_selected)
	
	# Style shield bars
	player_shield.set_as_shield()
	enemy_shield.set_as_shield()
	
	add_log("Welcome to Dungeon Crawler 2D!")
	
	# Add persistent Stats button to top bar
	_stats_button = Button.new()
	_stats_button.text = "📊 Stats"
	_stats_button.custom_minimum_size = Vector2(80, 0)
	_stats_button.pressed.connect(_toggle_character_panel)
	$TopBar/HBoxContainer.add_child(_stats_button)

func _on_room_selected(index: int) -> void:
	room_selected.emit(index)

# --- Top Bar ---

func update_floor_info(floor_num: int, depth: int, modifiers: Array = []) -> void:
	if floor_label:
		floor_label.text = "Floor %d" % floor_num
	if depth_label:
		depth_label.text = "Depth: %d" % depth
	if modifier_label:
		if modifiers.size() > 0:
			var mod_names = []
			for m in modifiers:
				mod_names.append(MapNode.Modifier.keys()[m])
			modifier_label.text = "⚡ " + ", ".join(mod_names)
		else:
			modifier_label.text = ""

# --- Mode Switching ---

func set_mode(is_combat: bool) -> void:
	battle_container.visible = is_combat
	skill_container.visible = is_combat
	
	if is_combat:
		room_selector.visible = false

func show_room_selection(choices: Array[MapNode]) -> void:
	room_selector.set_choices(choices)
	room_selector.visible = true

# --- Battle ---

func initialize_battle(player: Entity, enemies: Array[Entity]) -> void:
	update_hp(player, true)
	if enemies.size() > 0:
		update_hp(enemies[0], false)
		enemy_label.text = enemies[0].name
	else:
		enemy_hp.visible = false
		enemy_shield.visible = false
	
	_populate_skills(player)

func update_hp(entity: Entity, is_player: bool) -> void:
	if not entity.stats: return
	
	var current_hp = entity.stats.get_current(StatTypes.HP)
	var max_hp = entity.stats.get_stat(StatTypes.MAX_HP)
	var current_shield = entity.stats.get_current(StatTypes.SHIELD)
	var max_shield = entity.stats.get_stat(StatTypes.MAX_SHIELD)
	
	if is_player:
		player_hp.update_health(current_hp, max_hp)
		_update_shield_bar(player_shield, current_shield, max_shield)
	else:
		enemy_hp.update_health(current_hp, max_hp)
		_update_shield_bar(enemy_shield, current_shield, max_shield)

func _update_shield_bar(bar: HPBar, current: int, max_val: int) -> void:
	if max_val <= 0:
		bar.visible = false
	else:
		bar.visible = true
		bar.update_health(current, max_val)

# --- Skills ---

func _populate_skills(player: Entity) -> void:
	for child in skill_container.get_children():
		child.queue_free()
	
	if player.skills:
		for skill in player.skills.known_skills:
			var btn = SKILL_BTN_SCENE.instantiate() as SkillButton
			skill_container.add_child(btn)
			btn.setup(skill)
			btn.pressed.connect(func(): _on_skill_pressed(skill))

func _on_skill_pressed(skill: Skill) -> void:
	skill_activated.emit(skill)

func update_skill_cooldowns(player: Entity) -> void:
	for child in skill_container.get_children():
		if child is SkillButton:
			var btn = child as SkillButton
			var skill = btn.skill_reference
			if skill and player.skills:
				var cd = player.skills.cooldowns.get(skill, 0)
				btn.update_cooldown(cd)

# --- Log ---

func add_log(text: String) -> void:
	print(text)
	if log_label:
		log_label.append_text(text + "\n")

# --- Level / XP ---

func update_level_info(level: int, xp: int, xp_needed: int) -> void:
	if level_label:
		level_label.text = "Lv %d" % level
	if xp_label:
		xp_label.text = "XP: %d/%d" % [xp, xp_needed]

func show_skill_draft(offered: Skill, skills: Array[Skill], max_slots: int, upgrade: Skill = null) -> void:
	if active_draft:
		active_draft.queue_free()
	
	active_draft = SKILL_DRAFT_SCENE.instantiate() as SkillDraftPanel
	add_child(active_draft)
	active_draft.setup(offered, skills, max_slots, upgrade)
	active_draft.draft_completed.connect(_on_draft_completed)

func _on_draft_completed(action: String, slot_index: int) -> void:
	active_draft = null
	skill_draft_choice.emit(action, slot_index)

# --- Camp Menu ---

func show_camp_menu(camp_item: CampItemResource, cooldown: int, can_use: bool) -> void:
	# Remove previous camp menu if exists
	if _camp_menu_wrapper:
		_camp_menu_wrapper.queue_free()
		_camp_menu_wrapper = null
	
	# Full-screen CenterContainer for proper centering
	_camp_menu_wrapper = CenterContainer.new()
	_camp_menu_wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_camp_menu_wrapper)
	
	var menu = VBoxContainer.new()
	menu.custom_minimum_size = Vector2(300, 0)
	menu.add_theme_constant_override("separation", 12)
	_camp_menu_wrapper.add_child(menu)
	
	# Title
	var title = Label.new()
	title.text = "⛺ Camp"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	menu.add_child(title)
	
	# Rest button (always available)
	var rest_btn = Button.new()
	rest_btn.text = "🛌 Rest (Full Heal)"
	rest_btn.custom_minimum_size = Vector2(0, 45)
	rest_btn.pressed.connect(func():
		_close_camp_menu()
		camp_action_chosen.emit("rest")
	)
	menu.add_child(rest_btn)
	
	# Camp item button
	if camp_item:
		var item_btn = Button.new()
		if can_use:
			item_btn.text = "🎒 Use: %s" % camp_item.display_name
			item_btn.disabled = false
		else:
			if cooldown > 0:
				item_btn.text = "🎒 %s (CD: %d rooms)" % [camp_item.display_name, cooldown]
			else:
				item_btn.text = "🎒 %s (Consumed)" % camp_item.display_name
			item_btn.disabled = true
		item_btn.custom_minimum_size = Vector2(0, 45)
		item_btn.pressed.connect(func():
			_close_camp_menu()
			camp_action_chosen.emit("use_item")
		)
		menu.add_child(item_btn)
		
		# Description label
		var desc = Label.new()
		desc.text = camp_item.description
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		desc.add_theme_font_size_override("font_size", 12)
		menu.add_child(desc)
	else:
		var no_item = Label.new()
		no_item.text = "No camp item equipped."
		no_item.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		menu.add_child(no_item)

func _close_camp_menu() -> void:
	if _camp_menu_wrapper:
		_camp_menu_wrapper.queue_free()
		_camp_menu_wrapper = null

# --- Loot Panel ---

func show_loot_panel(item: EquipmentResource, current_equipped: EquipmentResource = null) -> void:
	_close_loot_panel()
	
	_loot_panel = LootPanel.new()
	_loot_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loot_panel.setup(item, current_equipped)
	_loot_panel.loot_choice.connect(_on_loot_choice)
	add_child(_loot_panel)

func _on_loot_choice(equip: bool) -> void:
	_close_loot_panel()
	loot_decision.emit(equip)

func _close_loot_panel() -> void:
	if _loot_panel:
		_loot_panel.queue_free()
		_loot_panel = null

# --- Character Panel ---

func set_player_ref(player: Entity) -> void:
	_player_ref = player

func _toggle_character_panel() -> void:
	if _char_panel:
		_close_character_panel()
	else:
		_show_character_panel()

func _show_character_panel() -> void:
	if not _player_ref:
		return
	_close_character_panel()
	
	_char_panel = CharacterPanel.new()
	_char_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_char_panel.setup(_player_ref)
	_char_panel.panel_closed.connect(_close_character_panel)
	add_child(_char_panel)

func _close_character_panel() -> void:
	if _char_panel:
		_char_panel.queue_free()
		_char_panel = null
