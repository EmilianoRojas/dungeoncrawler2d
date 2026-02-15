class_name GameLoop
extends Node

enum State {
	EXPLORATION,
	COMBAT,
	MENU
}

var current_state: State = State.EXPLORATION

# Systems
var grid_manager: GridManager
var turn_manager: TurnManager
var player_entity: Entity
var game_ui: GameUI

const UI_SCENE = preload("res://ui/game_ui.tscn")

func _exit_tree() -> void:
	# Ensure we clean up listeners when scene changes or game quits
	GlobalEventBus.unsubscribe("damage_dealt", _on_damage_event)

func _ready() -> void:
	print("Initializing GameLoop Instance: %d" % get_instance_id())
	GlobalEventBus.reset()
	
	# 1. Initialize UI (First so we can log to it)
	game_ui = UI_SCENE.instantiate()
	add_child(game_ui)
	game_ui.command_submitted.connect(handle_input)
	game_ui.skill_activated.connect(_on_ui_skill_activated)
	
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
	grid_manager = GridManager.new()
	add_child(grid_manager)
	
	turn_manager = TurnManager.new()
	add_child(turn_manager)
	
	# 4. Connect Signals
	turn_manager.turn_processing_end.connect(_on_battle_turn_end)
	GlobalEventBus.subscribe("damage_dealt", _on_damage_event)
	
	# 5. Generate Map
	grid_manager.generate_grid(5, 5)
	
	_log("Map Generated. Player at %s" % grid_manager.current_position)
	game_ui.set_mode(false) # Exploration mode

func handle_input(command: String) -> void:
	if current_state == State.EXPLORATION:
		match command:
			"move_n": _try_move(Vector2i(0, -1))
			"move_s": _try_move(Vector2i(0, 1))
			"move_e": _try_move(Vector2i(1, 0))
			"move_w": _try_move(Vector2i(-1, 0))
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

func _try_move(dir: Vector2i) -> void:
	if grid_manager.move(dir):
		_log("Moved to %s" % grid_manager.current_position)
		_check_room_event(grid_manager.get_current_node())
	else:
		_log("Cannot move that way.")

func _check_room_event(node: MapNode) -> void:
	var type_name = MapNode.Type.keys()[node.type]
	_log("Room Type: %s" % type_name)
	
	if node.type == MapNode.Type.ENEMY:
		_log("Encountered Enemy! Starting Combat.")
		_start_combat(node)

func _start_combat(node: MapNode) -> void:
	current_state = State.COMBAT
	
	var enemy = EnemyFactory.create_goblin()
	
	turn_manager.start_battle(player_entity, [enemy])
	game_ui.initialize_battle(player_entity, [enemy])
	game_ui.set_mode(true)

func _on_battle_turn_end() -> void:
	# Keep strictly in combat for now until Win Condition implemented
	pass

func _on_damage_event(data: Dictionary) -> void:
	# Update UI for the target
	var target = data.get("target")
	if target:
		var is_player = (target == player_entity)
		game_ui.update_hp(target, is_player)
		_log("%s took %d damage!" % [target.name, data.get("damage", 0)])

func _log(msg: String) -> void:
	# game_ui.add_log already prints to console, so we don't need print(msg) here
	if game_ui:
		game_ui.add_log(msg)
	else:
		print(msg) # Fallback if UI not ready
