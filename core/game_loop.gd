class_name GameLoop
extends Node

enum State {
	ROOM_SELECTION,
	COMBAT,
	EVENT,
	MENU
}

var current_state: State = State.ROOM_SELECTION

# Systems
var dungeon_manager: DungeonManager
var turn_manager: TurnManager
var player_entity: Entity
var game_ui: GameUI

const UI_SCENE = preload("res://ui/game_ui.tscn")

func _exit_tree() -> void:
	# Ensure we clean up listeners when scene changes or game quits
	GlobalEventBus.unsubscribe("damage_dealt", _on_damage_event)
	GlobalEventBus.unsubscribe("combat_log", _on_combat_log)

func _ready() -> void:
	print("Initializing GameLoop Instance: %d" % get_instance_id())
	GlobalEventBus.reset()
	
	# 1. Initialize UI (First so we can log to it)
	game_ui = UI_SCENE.instantiate()
	add_child(game_ui)
	game_ui.command_submitted.connect(handle_input)
	game_ui.skill_activated.connect(_on_ui_skill_activated)
	game_ui.room_selected.connect(_on_room_selected)
	
	# 2. Initialize Player
	player_entity = Entity.new()
	player_entity.name = "Player"
	player_entity.team = Entity.Team.PLAYER
	player_entity.initialize()
	
	# Load Warrior Class
	var warrior_class = load("res://data/classes/warrior.tres")
	if warrior_class:
		player_entity.apply_class(warrior_class)
		print("Loaded Class: %s" % warrior_class.title)
	else:
		print("Error: Could not load Warrior class!")
	
	# 3. Initialize Systems
	dungeon_manager = DungeonManager.new()
	add_child(dungeon_manager)
	
	turn_manager = TurnManager.new()
	add_child(turn_manager)
	
	# 4. Connect Signals
	turn_manager.turn_processing_end.connect(_on_battle_turn_end)
	turn_manager.battle_ended.connect(_on_battle_ended)
	GlobalEventBus.subscribe("damage_dealt", _on_damage_event)
	GlobalEventBus.subscribe("combat_log", _on_combat_log)
	
	# 5. Generate Dungeon
	dungeon_manager.generate_dungeon()
	
	_log("Dungeon Generated. Starting at Depth %d" % dungeon_manager.current_depth)
	_show_room_selection()

func handle_input(_command: String) -> void:
	# No more direct movement commands
	pass
	# Combat input is handled via _on_ui_skill_activated

func _on_ui_skill_activated(skill: Skill) -> void:
	if current_state != State.COMBAT: return
	
	# For prototype, assume single target (the first enemy)
	var target = turn_manager.get_first_alive_enemy()
	
	if target:
		var action = AttackAction.new(player_entity, target)
		# action.damage = 10 # REMOVED
		action.skill_reference = skill
		turn_manager.submit_player_action(action)

func _show_room_selection() -> void:
	current_state = State.ROOM_SELECTION
	var choices = dungeon_manager.get_next_choices()
	
	# Update UI with floor info
	game_ui.update_floor_info(
		dungeon_manager.current_floor,
		dungeon_manager.current_depth,
		dungeon_manager.floor_modifiers
	)
	game_ui.show_room_selection(choices)
	game_ui.set_mode(false)

func _on_room_selected(choice_index: int) -> void:
	var node = dungeon_manager.advance_to_room(choice_index)
	_log("Depth %d — %s" % [dungeon_manager.current_depth, node.get_type_name()])
	
	# Update top bar
	game_ui.update_floor_info(
		dungeon_manager.current_floor,
		dungeon_manager.current_depth,
		dungeon_manager.floor_modifiers
	)
	
	_process_room_event(node)

func _process_room_event(node: MapNode) -> void:
	var type_name = node.get_type_name()
	
	match node.type:
		MapNode.Type.ENEMY, MapNode.Type.ELITE, MapNode.Type.BOSS:
			_log("Encountered %s! Starting Combat." % type_name)
			_start_combat(node)
		MapNode.Type.CHEST:
			_log("Found a Chest!")
			_process_chest_loot()
			dungeon_manager.complete_current_room()
			call_deferred("_on_room_completed")
		MapNode.Type.EVENT:
			_log("Event Triggered! (Not implemented)")
			dungeon_manager.complete_current_room()
			call_deferred("_on_room_completed")
		MapNode.Type.CAMP:
			_log("Camp. Rested and recovered.")
			# Heal HP and reset Shield (GameSpec §1)
			player_entity.stats.modify_current(StatTypes.HP, player_entity.stats.get_stat(StatTypes.MAX_HP))
			player_entity.stats.reset_shield()
			dungeon_manager.complete_current_room()
			call_deferred("_on_room_completed")

func _start_combat(node: MapNode) -> void:
	current_state = State.COMBAT
	
	# TODO: Use node.type to pick enemy template (Elite/Boss = harder enemies)
	var enemy = EnemyFactory.create_goblin()
	_log("Floor %d - %s fight!" % [dungeon_manager.current_floor, node.get_type_name()])
	
	turn_manager.start_battle(player_entity, [enemy])
	game_ui.initialize_battle(player_entity, [enemy])
	game_ui.set_mode(true)

func _on_battle_turn_end() -> void:
	pass

func _on_battle_ended(result: TurnManager.Phase) -> void:
	if result == TurnManager.Phase.WIN:
		_log("Victory! Proceeding.")
		# Reset shield after battle (GameSpec §3)
		player_entity.stats.reset_shield()
		# Generate loot from the enemy
		_process_combat_loot()
		dungeon_manager.complete_current_room()
		await get_tree().create_timer(1.0).timeout
		_on_room_completed()
	else:
		_log("DEFEATED.")
		# Handle Game Over (Run ends, reset everything)

func _on_room_completed() -> void:
	# Show next choices
	_show_room_selection()

func _on_combat_log(data: Dictionary) -> void:
	var msg = data.get("message", "")
	if msg != "":
		_log(msg)

func _on_damage_event(data: Dictionary) -> void:
	# Update UI for the target
	var target = data.get("target")
	if target:
		var is_player = (target == player_entity)
		game_ui.update_hp(target, is_player)

# --- LOOT PROCESSING ---

func _process_combat_loot() -> void:
	var current_room = dungeon_manager.current_room
	var is_elite = current_room and current_room.type == MapNode.Type.ELITE
	var is_boss = current_room and current_room.type == MapNode.Type.BOSS
	var dungeon_floor = dungeon_manager.current_floor
	
	var rewards = LootSystem.generate_enemy_loot(dungeon_floor, is_elite, is_boss)
	
	if rewards.is_empty():
		_log("No loot dropped.")
		return
	
	for reward in rewards:
		if reward.type == RewardResource.Type.EQUIPMENT and reward.equipment:
			var equipped = RewardApplier.try_auto_equip(player_entity, reward.equipment)
			if equipped:
				_log("Equipped: %s [%s]" % [reward.equipment.display_name, reward.equipment.rarity])
				game_ui.update_hp(player_entity, true) # Refresh stats display
			else:
				_log("Found: %s [%s] (current gear is better)" % [reward.equipment.display_name, reward.equipment.rarity])
		else:
			RewardApplier.apply_reward(player_entity, reward)
			_log("Gained: %s" % reward.get_display_name())

func _process_chest_loot() -> void:
	var dungeon_floor = dungeon_manager.current_floor
	var rewards = LootSystem.generate_chest_loot(dungeon_floor)
	
	for reward in rewards:
		if reward.type == RewardResource.Type.EQUIPMENT and reward.equipment:
			var equipped = RewardApplier.try_auto_equip(player_entity, reward.equipment)
			if equipped:
				_log("Equipped: %s [%s]" % [reward.equipment.display_name, reward.equipment.rarity])
				game_ui.update_hp(player_entity, true)
			else:
				_log("Found: %s [%s] (current gear is better)" % [reward.equipment.display_name, reward.equipment.rarity])
		else:
			RewardApplier.apply_reward(player_entity, reward)
			_log("Gained: %s" % reward.get_display_name())

func _log(msg: String) -> void:
	# game_ui.add_log already prints to console, so we don't need print(msg) here
	if game_ui:
		game_ui.add_log(msg)
	else:
		print(msg) # Fallback if UI not ready
