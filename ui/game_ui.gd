class_name GameUI
extends Control

signal command_submitted(cmd: String)
signal skill_activated(skill: Skill)

@onready var log_label: RichTextLabel = $Panel/RichTextLabel
@onready var battle_container: HBoxContainer = $BattleContainer
@onready var skill_container: HBoxContainer = $SkillContainer
@onready var nav_controls: Control = $Controls/Navigation

@onready var player_hp: HPBar = $BattleContainer/PlayerInfo/HPBar
@onready var enemy_hp: HPBar = $BattleContainer/EnemyInfo/HPBar
@onready var enemy_label: Label = $BattleContainer/EnemyInfo/Label

@onready var btn_north: Button = $Controls/Navigation/BtnNorth
@onready var btn_south: Button = $Controls/Navigation/BtnSouth
@onready var btn_east: Button = $Controls/Navigation/BtnEast
@onready var btn_west: Button = $Controls/Navigation/BtnWest

const SKILL_BTN_SCENE = preload("res://ui/components/skill_button.tscn")

func _ready() -> void:
	# Navigation Signals
	btn_north.pressed.connect(func(): command_submitted.emit("move_n"))
	btn_south.pressed.connect(func(): command_submitted.emit("move_s"))
	btn_east.pressed.connect(func(): command_submitted.emit("move_e"))
	btn_west.pressed.connect(func(): command_submitted.emit("move_w"))
	
	add_log("Welcome to Dungeon Crawler 2D!")

func add_log(text: String) -> void:
	print(text)
	if log_label:
		log_label.append_text(text + "\n")

func set_mode(is_combat: bool) -> void:
	nav_controls.visible = not is_combat
	battle_container.visible = is_combat
	skill_container.visible = is_combat

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
	
	var current = entity.stats.get_stat(StatsComponent.StatType.HP)
	var max_hp = entity.stats.get_stat(StatsComponent.StatType.MAX_HP)
	
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
