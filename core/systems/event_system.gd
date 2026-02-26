class_name EventSystem
extends Object

## Resolves event choices and applies outcomes to the player entity.

static func resolve_choice(player: Entity, choice: EventChoice) -> String:
	if choice.outcome_type == EventChoice.OutcomeType.GAMBLE:
		return _resolve_gamble(player, choice)
	
	_apply_outcome(player, choice.outcome_type, choice.value, choice.buff_stat)
	if choice.secondary_type != EventChoice.OutcomeType.NOTHING:
		_apply_outcome(player, choice.secondary_type, choice.secondary_value, choice.secondary_buff_stat)
	return choice.result_text

static func _resolve_gamble(player: Entity, choice: EventChoice) -> String:
	var roll = randf()
	if roll < choice.gamble_chance:
		# Win
		_apply_outcome(player, choice.gamble_win_type, choice.gamble_win_value, choice.buff_stat)
		return choice.gamble_win_text if choice.gamble_win_text != "" else "You got lucky!"
	else:
		# Lose
		_apply_outcome(player, choice.gamble_lose_type, choice.gamble_lose_value, choice.buff_stat)
		return choice.gamble_lose_text if choice.gamble_lose_text != "" else "Bad luck..."

static func _apply_outcome(player: Entity, type: EventChoice.OutcomeType, value: float, buff_stat: StringName = "") -> void:
	match type:
		EventChoice.OutcomeType.HEAL_PERCENT:
			var max_hp = player.stats.get_stat(StatTypes.MAX_HP)
			var heal = int(max_hp * value / 100.0)
			player.stats.modify_current(StatTypes.HP, heal)
		
		EventChoice.OutcomeType.DAMAGE_PERCENT:
			var current_hp = player.stats.get_current(StatTypes.HP)
			var damage = int(current_hp * value / 100.0)
			damage = max(damage, 1) # At least 1 damage
			player.stats.modify_current(StatTypes.HP, -damage)
		
		EventChoice.OutcomeType.HEAL_FLAT:
			player.stats.modify_current(StatTypes.HP, int(value))
		
		EventChoice.OutcomeType.DAMAGE_FLAT:
			player.stats.modify_current(StatTypes.HP, -int(value))
		
		EventChoice.OutcomeType.GAIN_XP:
			LevelUpSystem.award_xp(player, int(value))
		
		EventChoice.OutcomeType.RANDOM_LOOT:
			pass # Handled by the caller (needs UI flow)
		
		EventChoice.OutcomeType.STAT_BUFF:
			if buff_stat != "":
				var mod = StatModifier.new()
				mod.stat = buff_stat
				mod.type = StatModifier.Type.FLAT
				mod.value = value
				mod.duration_turns = -1 # Permanent
				mod.source_id = "event_buff"
				player.stats.add_modifier(mod)
		
		EventChoice.OutcomeType.NOTHING:
			pass

static func pick_random_event(events: Array[EventData], current_floor: int) -> EventData:
	var valid: Array[EventData] = []
	var total_weight: float = 0.0
	
	for event in events:
		if event.min_floor > 0 and current_floor < event.min_floor:
			continue
		if event.max_floor > 0 and current_floor > event.max_floor:
			continue
		valid.append(event)
		total_weight += event.weight
	
	if valid.is_empty():
		return null
	
	var roll = randf() * total_weight
	var cumulative: float = 0.0
	for event in valid:
		cumulative += event.weight
		if roll <= cumulative:
			return event
	
	return valid[-1]
