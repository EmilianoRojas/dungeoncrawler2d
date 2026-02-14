extends Node

var turn_manager: TurnManager
var player: Entity
var enemy: Entity

func _ready():
	print("--- Starting Action Queue Verification ---")
	
	# 1. Setup
	turn_manager = TurnManager.new()
	add_child(turn_manager)
	
	player = Entity.new()
	player.name = "Player"
	player._ready()
	player.stats.base["speed"] = 10 # Faster
	
	enemy = Entity.new()
	enemy.name = "Enemy"
	enemy._ready()
	enemy.stats.base["speed"] = 5 # Slower
	
	# Give Enemy a skill so AI works
	var bite = Skill.new()
	bite.skill_name = "Bite"
	enemy.skills.learn_skill(bite)
	
	# 2. Start Battle
	print("Starting Battle...")
	turn_manager.start_battle(player, [enemy])
	
	# 3. Simulate Decision Phase (Turn 1)
	# TurnManager should be waiting for Player Input
	print("Simulating Player Decision...")
	await get_tree().create_timer(0.1).timeout # Let engine process frames
	
	if turn_manager.current_phase == TurnManager.Phase.DECISION:
		print("Confirmed: In DECISION phase.")
	else:
		print("FAILURE: System did not wait for player.")
		
	# Create Player Action
	var player_action = AttackAction.new(player, enemy)
	player_action.damage = 10
	player_action.priority = 0
	
	# Submit Action (Triggers Resolution)
	turn_manager.submit_player_action(player_action)
	
	# 4. Verify Resolution Order
	# Player Speed 10 vs Enemy Speed 5
	# Player action should execute first
	# We rely on logs for "AttackAction execute" -> CombatSystem logs
	
	print("Watching Resolution Phase...")
	await get_tree().create_timer(1.5).timeout # Wait for logic
	
	print("Verification Complete.")
	get_tree().quit()
