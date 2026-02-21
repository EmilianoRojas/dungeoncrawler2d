class_name GameUI
extends Control

signal command_submitted(cmd: String)
signal skill_activated(skill: Skill)
signal room_selected(index: int)

# Top Bar
@onready var floor_label: Label = $TopBar/HBoxContainer/FloorLabel
@onready var depth_label: Label = $TopBar/HBoxContainer/DepthLabel
@onready var modifier_label: Label = $TopBar/HBoxContainer/ModifierLabel

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

# --- Log ---

func add_log(text: String) -> void:
	print(text)
	if log_label:
		log_label.append_text(text + "\n")
