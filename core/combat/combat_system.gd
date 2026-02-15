class_name CombatSystem
extends Object

static func deal_damage(source: Entity, target: Entity, amount: int) -> void:
	var data = {
		"source": source,
		"target": target,
		"damage": amount
	}

	# PRE DAMAGE (Optional, keeping placeholders if user wants to add them later)
	# source.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_DEALT, data) # Assuming ON_DAMAGE_DEALT is post-process usually
	# target.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_TAKEN, data)

	# APPLY DAMAGE
	# Use the new modify_current method. Subtract damage.
	target.stats.modify_current(StatsComponent.StatType.HP, -data.damage)
	
	# Check death (moved from apply_damage_to_stats logic to here or kept separate?)
	# Let's keep a death check helper or do it inline
	var current_hp = target.stats.current.get(StatsComponent.StatType.HP, 0)
	if current_hp <= 0:
		target.effects.dispatch(EffectResource.Trigger.ON_DEATH, {})
		# GlobalEventBus for death? Keeping legacy if needed.
		# GlobalEventBus.dispatch("entity_died", {"entity": target}) 

	# POST DAMAGE
	source.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_DEALT, data)
	target.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_TAKEN, data)

	# Log/UI events
	GlobalEventBus.dispatch("combat_log", {"message": "%s attacks %s for %d damage" % [source.name, target.name, data.damage]}) 
	GlobalEventBus.dispatch("damage_dealt", data)
