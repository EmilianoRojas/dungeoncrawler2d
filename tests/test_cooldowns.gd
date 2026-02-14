extends Node

var turn_manager: TurnManager
var player: Entity
var enemy: Entity

func _ready():
	print("--- Starting Cooldown System Verification ---")
	
	# 1. Setup
	turn_manager = TurnManager.new()
	add_child(turn_manager)
	
	player = Entity.new()
	player.name = "Player"
	player._ready()
	
	enemy = Entity.new()
	enemy.name = "Enemy"
	enemy._ready()
	
	# 2. Setup Skill with Cooldown
	var heavy_strike = Skill.new()
	heavy_strike.skill_name = "Heavy Strike"
	heavy_strike.max_cooldown = 2 # 2 turns cooldown
	player.skills.learn_skill(heavy_strike)
	
	# 3. Test Loop
	print("Player using skill for the first time...")
	if player.skills.use_skill(heavy_strike, enemy):
		print("SUCCESS: Skill used.")
	else:
		print("FAILURE: Skill failed.")
		
	print("Checking Cooldown immediately after use (Expect 2)...")
	var cd = player.skills.cooldowns[heavy_strike]
	print("Current CD: %d" % cd)
	
	print("\n--- Simulating Turns ---")
	
	# Turn 1 (Player Turn Start -> Tick)
	# Logic: use_skill puts it on CD=2.
	# Next time player's turn starts, tick() reduces it to 1.
	
	# Manually ticking for test control or running via turn manager? 
	# Let's run via TurnManager to prove integration.
	
	# Start Battle (will trigger turn 1 for player)
	turn_manager.start_battle(player, [enemy])
	# TurnManager._next_turn() calls tick_cooldowns() immediately for the starter
	# So CD should go 2 -> 1
	print("Battle Started. Player's Turn.")
	print("Current CD: %d" % player.skills.cooldowns[heavy_strike])
	
	print("Attempting to use skill (Should fail)...")
	if player.skills.use_skill(heavy_strike, enemy):
		print("FAILURE: Skill used while on CD.")
	else:
		print("SUCCESS: Skill rejected due to CD.")
		
	# Pass turn to enemy
	print("\nPassing turn to enemy...")
	turn_manager._next_turn() # Enemy Turn
	# Pass turn back to player
	print("Passing turn back to player...")
	turn_manager._next_turn() # Player Turn (Tick happens here: 1 -> 0)
	
	print("Player's Turn again.")
	print("Current CD: %d" % player.skills.cooldowns[heavy_strike])
	
	print("Attempting to use skill (Should succeed)...")
	if player.skills.use_skill(heavy_strike, enemy):
		print("SUCCESS: Skill used after CD.")
	else:
		print("FAILURE: Skill failed after CD.")
	
	print("\nVerification Complete.")
	get_tree().quit()
