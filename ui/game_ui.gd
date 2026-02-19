class_name GameUI
extends Control

signal command_submitted(cmd: String)
signal skill_activated(skill: Skill)
signal room_selected(index: int)

@onready var log_label: RichTextLabel = $Panel/RichTextLabel
@onready var battle_container: HBoxContainer = $BattleContainer
@onready var skill_container: HBoxContainer = $SkillContainer

# New Room Selector
const ROOM_SELECTOR_SCENE = preload("res://ui/components/room_selector.tscn")
var room_selector: RoomSelector

@onready var player_hp: HPBar = $BattleContainer/PlayerInfo/HPBar
@onready var enemy_hp: HPBar = $BattleContainer/EnemyInfo/HPBar
@onready var enemy_label: Label = $BattleContainer/EnemyInfo/Label

const SKILL_BTN_SCENE = preload("res://ui/components/skill_button.tscn")

func _ready() -> void:
	# Initialize Room Selector
	room_selector = ROOM_SELECTOR_SCENE.instantiate()
	add_child(room_selector)
	room_selector.visible = false
	room_selector.room_selected.connect(_on_room_selected)
	
	add_log("Welcome to Dungeon Crawler 2D!")

func _on_room_selected(index: int) -> void:
	room_selected.emit(index)

func add_log(text: String) -> void:
	print(text)
	if log_label:
		log_label.append_text(text + "\n")

func set_mode(is_combat: bool) -> void:
	battle_container.visible = is_combat
	skill_container.visible = is_combat
	
	if is_combat:
		room_selector.visible = false

func show_room_selection(choices: Array[MapNode]) -> void:
	room_selector.set_choices(choices)
	room_selector.visible = true

func initialize_battle(player: Entity, enemies: Array[Entity]) -> void:
	# Update HP Bars
	update_hp(player, true)
	if enemies.size() > 0:
		update_hp(enemies[0], false)
		enemy_label.text = enemies[0].name
	else:
		enemy_hp.visible = false
	
	# Populate Skills
	_populate_skills(player)

func update_hp(entity: Entity, is_player: bool) -> void:
	# Ensure stats exist
	if not entity.stats: return
	
	var current = entity.stats.get_current(StatTypes.HP)
	var max_hp = entity.stats.get_stat(StatTypes.MAX_HP)
	
	if is_player:
		player_hp.update_health(current, max_hp)
	else:
		enemy_hp.update_health(current, max_hp)

func _populate_skills(player: Entity) -> void:
	# Clear old buttons
	for child in skill_container.get_children():
		child.queue_free()
	
	# Create new buttons
	if player.skills:
		for skill in player.skills.known_skills:
			var btn = SKILL_BTN_SCENE.instantiate() as SkillButton
			skill_container.add_child(btn)
			btn.setup(skill)
			btn.pressed.connect(func(): _on_skill_pressed(skill))


func _on_skill_pressed(skill: Skill) -> void:
	skill_activated.emit(skill)
