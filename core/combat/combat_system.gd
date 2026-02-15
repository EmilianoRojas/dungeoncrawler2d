class_name CombatSystem
extends Object

static func deal_damage(source: Node, target: Node, amount: int) -> void:
	var data = {
		"source": source,
		"target": target,
		"damage": amount,
		"original_amount": amount # Keep track of original for logs/ui
	}
	
	# 1. Pre-damage events (modifiers might change 'damage' in data)
	# Source modifiers (e.g. increase damage dealt)
	source.effects.dispatch("before_damage_dealt", data)
	# Target modifiers (e.g. reduction, evasion - though evasion might be a separate check)
	target.effects.dispatch("before_damage_taken", data)
	
	# Global event
	GlobalEventBus.dispatch("combat_log", {"message": "%s attacks %s for %d damage" % [source.name, target.name, data.damage]})

	# 2. Apply Damage
	# (Here we ideally have a take_damage method on Entity or just modify HP directly in stats)
	apply_damage_to_stats(target, data.damage)
	
	# 3. Post-damage events (e.g. lifesteal, thorns)
	source.effects.dispatch("on_damage_dealt", data)
	target.effects.dispatch("on_damage_taken", data)
	
	# Notify UI/GameLoop
	GlobalEventBus.dispatch("damage_dealt", data)

static func apply_damage_to_stats(target: Node, amount: int) -> void:
	var current_hp = target.stats.get_stat(StatsComponent.StatType.HP)
	var new_hp = current_hp - amount
	target.stats.set_base_stat(StatsComponent.StatType.HP, new_hp) # Simplified: modifying base for now, usually HP is current_value vs max_value
	
	if new_hp <= 0:
		target.effects.dispatch("on_death", {})
		GlobalEventBus.dispatch("entity_died", {"entity": target})
