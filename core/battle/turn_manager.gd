class_name TurnManager
extends Node

enum Phase {
	WAITING,
	DECISION,
	RESOLUTION,
	WIN,
	LOSS
}

signal phase_changed(new_phase: Phase)
signal turn_processing_start
signal turn_processing_end
signal battle_ended(result: Phase)

var current_phase: Phase = Phase.WAITING
var entities: Array[Entity] = []
var action_queue: ActionQueue
var turn_count: int = 0

func _init() -> void:
	action_queue = ActionQueue.new()
	add_child(action_queue)
	
	GlobalEventBus.subscribe("entity_died", _on_entity_died)

func _notification(what: int) -> void:
	# Cleanup if needed manually, though node removal usually handles it.
	# But GlobalEventBus is autoload, so unsubscription is good practice.
	if what == NOTIFICATION_PREDELETE:
		GlobalEventBus.unsubscribe("entity_died", _on_entity_died)

func start_battle(player: Entity, enemies: Array[Entity]) -> void:
	entities.clear()
	entities.append(player)
	entities.append_array(enemies)
	turn_count = 0
	
	# Start basic loop
	start_new_turn()

# --- Targeting Helpers ---

func get_first_alive_enemy() -> Entity:
	for e in entities:
		if e.team == Entity.Team.ENEMY and e.is_alive():
			return e
	return null

func get_alive_enemies() -> Array[Entity]:
	var result: Array[Entity] = []
	for e in entities:
		if e.team == Entity.Team.ENEMY and e.is_alive():
			result.append(e)
	return result

func get_alive_allies(entity: Entity) -> Array[Entity]:
	var result: Array[Entity] = []
	for e in entities:
		if e.team == entity.team and e.is_alive():
			result.append(e)
	return result

func are_all_enemies_dead() -> bool:
	for e in entities:
		if e.team == Entity.Team.ENEMY and e.is_alive():
			return false
	return true

func start_new_turn() -> void:
	turn_count += 1
	print("\n=== Turn %d Start ===" % turn_count)
	
	# 1. Tick Cooldowns & Effects
	for e in entities:
		e.skills.tick_cooldowns()
		e.effects.tick_all()
		if "stats" in e:
			e.stats.tick_modifiers()
			
		# Trigger Passives: ON_TURN_START
		if "passives" in e and e.passives:
			var passives_list = e.passives.get_passives_by_trigger(EffectResource.Trigger.ON_TURN_START)
			for p_data in passives_list:
				var effect = p_data.effect
				var source_id = p_data.source
				
				# Execute Passive
				var instance = EffectInstance.new(effect)
				var context = CombatContext.new()
				context.source = e
				context.target = e # Usually self-targeting for turn start (regen, etc)
				context.custom_source_id = source_id
				
				OperationExecutor.execute(instance, e, context)
	
	_set_phase(Phase.DECISION)
	_process_decision_phase()

func _set_phase(p: Phase) -> void:
	current_phase = p
	phase_changed.emit(p)

func _process_decision_phase() -> void:
	print("--- Phase: DECISION ---")
	action_queue.clear()
	
	var player_entity = entities[0] # Assuming player is 0 for now
	
	# Iterate all entities
	for entity in entities:
		if entity.name == "Player":
			# Player needs input.
			# We don't return here! We let other entities decide.
			print("Waiting for Player Input...")
			continue
		else:
			# Enemy AI
			var context = {"target": player_entity}
			
			# Check if enemy is alive before acting
			if not entity.is_alive(): continue
			
			var action = entity.decide_action(context)
			if action:
				action_queue.add_action(action)
				print("Enemy decided: %s" % action)
	
	# Now we just wait for submit_player_action to trigger resolution

func submit_player_action(action: Action) -> void:
	if current_phase != Phase.DECISION:
		print("Warning: Player submitted action outside DECISION phase")
		return
		
	print("Player submitted: %s" % action)
	action_queue.add_action(action)
	
	_set_phase(Phase.RESOLUTION)
	_process_resolution_phase()

func _process_resolution_phase() -> void:
	print("--- Phase: RESOLUTION ---")
	turn_processing_start.emit()
	
	while action_queue.has_actions():
		# Execution continues unless game ending state is reached by event
		if current_phase == Phase.WIN or current_phase == Phase.LOSS:
			break
			
		# Visual Wait
		await get_tree().create_timer(0.5).timeout
		
		# Execute next
		action_queue.process_next()
	
	# Trigger Passives: ON_TURN_END
	for e in entities:
		if "passives" in e and e.passives:
			var passives_list = e.passives.get_passives_by_trigger(EffectResource.Trigger.ON_TURN_END)
			for p_data in passives_list:
				var effect = p_data.effect
				var source_id = p_data.source
				
				var instance = EffectInstance.new(effect)
				var context = CombatContext.new()
				context.source = e
				context.target = e
				context.custom_source_id = source_id
				
				OperationExecutor.execute(instance, e, context)

	# Only start new turn if battle isn't over
	if current_phase != Phase.WIN and current_phase != Phase.LOSS:
		turn_processing_end.emit()
		await get_tree().create_timer(0.5).timeout
		start_new_turn()

func _on_entity_died(data: Dictionary) -> void:
	var dead_entity = data.get("entity")
	if not dead_entity: return
	
	print("TurnManager: %s died!" % dead_entity.name)
	
	if dead_entity.team == Entity.Team.PLAYER:
		print("DEFEAT!")
		_set_phase(Phase.LOSS)
		battle_ended.emit(Phase.LOSS)
		return
	
	# Check if enemies remain
	# Check if enemies remain
	if are_all_enemies_dead():
		print("VICTORY!")
		_set_phase(Phase.WIN)
		battle_ended.emit(Phase.WIN)
