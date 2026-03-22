class_name GameUI
extends Control

signal command_submitted(cmd: String)
signal skill_activated(skill: Skill)
signal room_selected(index: int)
signal skill_draft_choice(action: String, slot_index: int)
signal camp_action_chosen(action: String)
signal loot_decision(equip: bool, item: EquipmentResource)
signal wait_turn_pressed
signal rune_panel_requested

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
@onready var player_sprite: TextureRect = $BattleContainer/PlayerInfo/SpriteRect
@onready var enemy_hp: HPBar = $BattleContainer/EnemyInfo/HPBar
@onready var enemy_shield: HPBar = $BattleContainer/EnemyInfo/ShieldBar
@onready var enemy_sprite: TextureRect = $BattleContainer/EnemyInfo/SpriteRect
@onready var enemy_label: Label = $BattleContainer/EnemyInfo/Label

# Log
@onready var log_label: RichTextLabel = $Panel/RichTextLabel

# Room Selector (instantiated dynamically)
const ROOM_SELECTOR_SCENE = preload("res://ui/components/room_selector.tscn")
var room_selector: RoomSelector

const SKILL_BTN_SCENE = preload("res://ui/components/skill_button.tscn")
const SKILL_DRAFT_SCENE = preload("res://ui/components/skill_draft_panel.tscn")

var vfx_manager: VFXManager

var active_draft: SkillDraftPanel = null
var _camp_menu_wrapper: CenterContainer = null
var _loot_panel: LootPanel = null
var _char_panel: CharacterPanel = null
var _stats_button: Button = null
var _rune_button: Button = null
var _currency_label: Label = null
var _player_ref: Entity = null
var _wait_button: Button = null
var _rune_panel: RunePanel = null

# Turn indicator nodes
var _player_turn_indicator: Label = null
var _enemy_turn_indicator: Label = null

# Status effect bars
var _player_status_bar: StatusEffectBar = null
var _enemy_status_bar: StatusEffectBar = null

# Skill tooltip
var _skill_tooltip: Control = null
var _tooltip_hide_timer: Timer = null

func _ready() -> void:
	# Pixel art: nearest-neighbor on sprite rects only (not global)
	player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	enemy_sprite.texture_filter  = CanvasItem.TEXTURE_FILTER_NEAREST

	# Initialize Room Selector
	room_selector = ROOM_SELECTOR_SCENE.instantiate()
	add_child(room_selector)
	room_selector.visible = false
	room_selector.room_selected.connect(_on_room_selected)

	# VFX Manager
	vfx_manager = VFXManager.new()
	add_child(vfx_manager)
	vfx_manager.setup(self)

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

	# Rune panel is lobby-only — no in-run rune button

	# Currency display
	_currency_label = Label.new()
	_currency_label.add_theme_font_size_override("font_size", 13)
	_currency_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	$TopBar/HBoxContainer.add_child(_currency_label)
	_refresh_currency_label()
	CurrencyManager.balance_changed.connect(_on_currency_changed)

func _refresh_currency_label() -> void:
	if _currency_label:
		_currency_label.text = "🔷 %d" % CurrencyManager.balance

func _on_currency_changed(_new_balance: int) -> void:
	_refresh_currency_label()

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
	if player.sprite:
		player_sprite.texture = player.sprite
		player_sprite.visible = true
	else:
		player_sprite.visible = false

	if enemies.size() > 0:
		update_hp(enemies[0], false)
		enemy_label.text = enemies[0].name
		if enemies[0].sprite:
			enemy_sprite.texture = enemies[0].sprite
			enemy_sprite.flip_h = true
			enemy_sprite.visible = true
		else:
			enemy_sprite.visible = false
	else:
		enemy_hp.visible = false
		enemy_shield.visible = false
		enemy_sprite.visible = false

	# Reset sprite modulates from previous battles
	player_sprite.modulate = Color.WHITE
	enemy_sprite.modulate = Color.WHITE

	# Register entities with VFXManager (clear old entries first)
	vfx_manager.clear_entities()
	vfx_manager.register_entity(player, player_sprite, $BattleContainer/PlayerInfo)
	if enemies.size() > 0:
		vfx_manager.register_entity(enemies[0], enemy_sprite, $BattleContainer/EnemyInfo)

	_populate_skills(player)
	update_skill_cooldowns(player)
	set_skills_interactable(false)
	_setup_turn_indicators()
	_setup_status_bars(player, enemies)

func _setup_status_bars(player: Entity, enemies: Array[Entity]) -> void:
	# Clear existing bars
	if _player_status_bar:
		_player_status_bar.queue_free()
	if _enemy_status_bar:
		_enemy_status_bar.queue_free()

	# Player status bar — under HP bars inside PlayerInfo VBox
	_player_status_bar = StatusEffectBar.new()
	_player_status_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$BattleContainer/PlayerInfo.add_child(_player_status_bar)

	# Enemy status bar — under HP bars inside EnemyInfo VBox
	_enemy_status_bar = StatusEffectBar.new()
	_enemy_status_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$BattleContainer/EnemyInfo.add_child(_enemy_status_bar)

	# Initial refresh
	update_status_effects(player, enemies)

func update_status_effects(player: Entity, enemies: Array[Entity]) -> void:
	if _player_status_bar:
		_player_status_bar.refresh(player)
	if _enemy_status_bar:
		_enemy_status_bar.refresh(enemies[0] if enemies.size() > 0 else null)

func _setup_turn_indicators() -> void:
	# Remove old indicators if reinitializing
	if _player_turn_indicator:
		_player_turn_indicator.queue_free()
	if _enemy_turn_indicator:
		_enemy_turn_indicator.queue_free()

	_player_turn_indicator = _make_turn_indicator(true)
	_enemy_turn_indicator = _make_turn_indicator(false)

	# Add as overlay on top of each sprite rect
	player_sprite.add_child(_player_turn_indicator)
	enemy_sprite.add_child(_enemy_turn_indicator)

	# Start hidden — will be shown by set_turn_phase()
	_player_turn_indicator.visible = false
	_enemy_turn_indicator.visible = false

func _make_turn_indicator(is_player: bool) -> Label:
	var lbl = Label.new()
	lbl.text = "▼"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2) if is_player else Color(1.0, 0.35, 0.35))
	# Anchor to top-center of the sprite rect
	lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lbl.offset_top = -24
	lbl.offset_bottom = -2
	return lbl

## Update which entity is highlighted based on the current turn phase.
## Call this from GameLoop when TurnManager.phase_changed fires.
func set_turn_phase(phase: int) -> void: # phase: TurnManager.Phase
	if not _player_turn_indicator or not _enemy_turn_indicator:
		return
	match phase:
		1: # DECISION — player is choosing
			_player_turn_indicator.visible = true
			_enemy_turn_indicator.visible = false
			set_skills_interactable(true)
		_: # WAITING, RESOLUTION, WIN, LOSS — disable buttons while processing
			_player_turn_indicator.visible = false
			_enemy_turn_indicator.visible = false
			set_skills_interactable(false)

func update_hp(entity: Entity, is_player: bool) -> void:
	if not entity.stats: return

	var current_hp = entity.stats.get_current(StatTypes.HP)
	var max_hp = entity.stats.get_stat(StatTypes.MAX_HP)
	var current_shield = entity.stats.get_current(StatTypes.SHIELD)
	var max_shield = entity.stats.get_stat(StatTypes.MAX_SHIELD)

	if is_player:
		player_hp.update_health_animated(current_hp, max_hp)
		_update_shield_bar(player_shield, current_shield, max_shield)
	else:
		enemy_hp.update_health_animated(current_hp, max_hp)
		_update_shield_bar(enemy_shield, current_shield, max_shield)

func _update_shield_bar(bar: HPBar, current: int, max_val: int) -> void:
	if max_val <= 0:
		bar.visible = false
	else:
		bar.visible = true
		bar.update_health_animated(current, max_val)

# --- Skills ---

func _populate_skills(player: Entity) -> void:
	for child in skill_container.get_children():
		child.queue_free()
	_wait_button = null
	
	if player.skills:
		for skill in player.skills.known_skills:
			var btn = SKILL_BTN_SCENE.instantiate() as SkillButton
			skill_container.add_child(btn)
			btn.setup(skill)
			btn.pressed.connect(func(): _on_skill_pressed(skill))
			btn.tooltip_requested.connect(_show_skill_tooltip)
	
	# Add Wait button (hidden by default, shown when all skills on CD)
	_wait_button = Button.new()
	_wait_button.text = "⏳ Wait"
	_wait_button.custom_minimum_size = Vector2(80, 40)
	_wait_button.visible = false
	_wait_button.pressed.connect(func(): wait_turn_pressed.emit())
	skill_container.add_child(_wait_button)

func _on_skill_pressed(skill: Skill) -> void:
	skill_activated.emit(skill)

func update_skill_cooldowns(player: Entity) -> void:
	var any_ready = false
	for child in skill_container.get_children():
		if child is SkillButton:
			var btn = child as SkillButton
			var skill = btn.skill_reference
			if skill and player.skills:
				var cd = player.skills.cooldowns.get(skill, 0)
				btn.update_cooldown(cd)
				if cd <= 0:
					any_ready = true
	
	# Show/hide wait button
	if _wait_button:
		_wait_button.visible = not any_ready

func set_skills_interactable(enabled: bool) -> void:
	for child in skill_container.get_children():
		if child is SkillButton:
			(child as SkillButton).set_interactable(enabled)
		elif child is Button:
			child.disabled = not enabled

# --- Skill tooltip ---

func _show_skill_tooltip(skill: Skill, btn_gpos: Vector2) -> void:
	_hide_skill_tooltip()

	var panel := PanelContainer.new()
	var sty := StyleBoxFlat.new()
	sty.bg_color    = Color(0.06, 0.06, 0.10, 0.96)
	sty.border_color = Color(0.55, 0.45, 0.80)
	sty.set_border_width_all(2)
	sty.set_corner_radius_all(8)
	sty.content_margin_left   = 14
	sty.content_margin_right  = 14
	sty.content_margin_top    = 10
	sty.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sty)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vb)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = skill.skill_name
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(name_lbl)

	vb.add_child(_tt_sep())

	# Damage line
	var dmg_str: String
	if skill.scaling_type == Skill.ScalingType.FLAT:
		dmg_str = "Deals %d damage" % skill.base_power
	else:
		var pct := int(skill.scaling_percent * 100.0)
		var stat := str(skill.scaling_stat).capitalize()
		if skill.base_power > 0:
			dmg_str = "Deals %d%% %s  +  %d base" % [pct, stat, skill.base_power]
		else:
			dmg_str = "Deals %d%% %s" % [pct, stat]

	if skill.is_self_heal:
		dmg_str = dmg_str.replace("Deals", "Heals for")

	vb.add_child(_tt_line(dmg_str, Color(0.85, 0.85, 0.85)))

	# Hit / CD
	var hit_str := "Hit: %d%%   |   Cooldown: %d turns" % [skill.hit_chance, skill.max_cooldown]
	if skill.max_cooldown == 0:
		hit_str = "Hit: %d%%   |   No cooldown" % skill.hit_chance
	vb.add_child(_tt_line(hit_str, Color(0.60, 0.70, 0.85)))

	# Special flags
	if skill.ignores_shield:
		vb.add_child(_tt_line("✦ Penetrating — ignores shield", Color(1.0, 0.55, 0.35)))
	if skill.is_observe:
		vb.add_child(_tt_line("✦ Reveals enemy info", Color(0.50, 0.85, 0.55)))

	# On-cast / on-hit effects
	if skill.on_cast_effects.size() > 0:
		var names := skill.on_cast_effects.map(func(e): return e.effect_id if "effect_id" in e else "?")
		vb.add_child(_tt_line("On cast: %s" % ", ".join(names), Color(0.75, 0.60, 1.00)))
	if skill.on_hit_effects.size() > 0:
		var names := skill.on_hit_effects.map(func(e): return e.effect_id if "effect_id" in e else "?")
		vb.add_child(_tt_line("On hit: %s" % ", ".join(names), Color(0.75, 0.60, 1.00)))

	# Skill level bonus
	if skill.skill_level > 1:
		vb.add_child(_tt_line("Lv.%d  (+%d%% damage)" % [skill.skill_level, (skill.skill_level - 1) * 10],
			Color(0.90, 0.75, 0.30)))

	# Add to scene so it renders on top
	add_child(panel)
	_skill_tooltip = panel

	# Position: above the button, clamped to viewport
	await get_tree().process_frame  # let panel compute its size
	var vp_size: Vector2 = get_viewport_rect().size
	var panel_size: Vector2 = panel.size
	var x: float = clampf(btn_gpos.x, 4.0, vp_size.x - panel_size.x - 4.0)
	var y: float = btn_gpos.y - panel_size.y - 8.0
	if y < 4.0:
		y = btn_gpos.y + 80.0  # flip below if too close to top
	panel.set_global_position(Vector2(x, y))

	# Auto-hide after 3 seconds
	if not _tooltip_hide_timer:
		_tooltip_hide_timer = Timer.new()
		_tooltip_hide_timer.one_shot = true
		_tooltip_hide_timer.timeout.connect(_hide_skill_tooltip)
		add_child(_tooltip_hide_timer)
	_tooltip_hide_timer.start(3.0)

func _hide_skill_tooltip() -> void:
	if _skill_tooltip:
		_skill_tooltip.queue_free()
		_skill_tooltip = null
	if _tooltip_hide_timer:
		_tooltip_hide_timer.stop()

func _tt_line(txt: String, color: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _tt_sep() -> HSeparator:
	var s := HSeparator.new()
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s

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

func show_loot_panel(item: EquipmentResource, current_equipped: EquipmentResource = null, dungeon_floor: int = 1) -> void:
	_close_loot_panel()
	room_selector.visible = false

	_loot_panel = LootPanel.new()
	_loot_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loot_panel.setup(item, current_equipped, dungeon_floor)
	_loot_panel.loot_choice.connect(_on_loot_choice)
	add_child(_loot_panel)

func _on_loot_choice(equip: bool) -> void:
	var item = _loot_panel._item if _loot_panel else null
	_close_loot_panel()
	loot_decision.emit(equip, item)

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

# --- Rune Panel ---

func show_rune_panel(entity: Entity, class_title: String) -> void:
	_close_rune_panel()
	_rune_panel = RunePanel.new()
	_rune_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rune_panel.setup(entity, class_title)
	_rune_panel.panel_closed.connect(_close_rune_panel)
	add_child(_rune_panel)

func _close_rune_panel() -> void:
	if _rune_panel:
		_rune_panel.queue_free()
		_rune_panel = null
