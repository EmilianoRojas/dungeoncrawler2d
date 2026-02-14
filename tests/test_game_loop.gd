extends Node

var game_loop: GameLoop

func _ready():
	print("--- Starting Game Loop Verification ---")
	
	game_loop = GameLoop.new()
	add_child(game_loop)
	
	# Allow initialization
	await get_tree().create_timer(0.1).timeout
	
	if game_loop.game_ui:
		print("SUCCESS: GameUI instantiated.")
	else:
		print("FAILURE: GameUI missing.")
	
	# Simulate movement until enemy found
	print("\n--- Exploring ---")
	var moves = ["move_e", "move_e", "move_s", "move_s", "move_w"]
	
	for move_cmd in moves:
		if game_loop.current_state == GameLoop.State.COMBAT:
			print("Combat started during exploration! Stopping movement.")
			break
			
		print("Command: %s" % move_cmd)
		game_loop.handle_input(move_cmd)
		await get_tree().create_timer(0.1).timeout
	
	# If we hit combat, test a combat action
	if game_loop.current_state == GameLoop.State.COMBAT:
		print("\n--- Testing Combat Integration ---")
		
		# Verify UI Mode
		if game_loop.game_ui.battle_container.visible:
			print("SUCCESS: Battle UI is visible.")
		else:
			print("FAILURE: Battle UI is NOT visible.")
			
		print("Player using 'skill' via UI signal...")
		# Simulate clicking the skill button
		var skill = game_loop.player_entity.skills.known_skills[0]
		game_loop.game_ui.skill_activated.emit(skill)
		
		await get_tree().create_timer(2.0).timeout
		print("Combat test sequence finished.")
	else:
		print("\nWarning: No enemy found in random moves. Try running again.")
	
	print("Verification Complete.")
	get_tree().quit()
