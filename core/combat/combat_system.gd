class_name CombatSystem
extends Object

static func deal_damage(source: Entity, target: Entity, amount: int) -> void:
	var context = CombatContext.new(source, target)
	context.damage = amount
	
	# APPLY DAMAGE
	target.stats.modify_current(StatsComponent.StatType.HP, -context.damage)
	
	# Check death
	var current_hp = target.stats.current.get(StatsComponent.StatType.HP, 0)
	if current_hp <= 0:
		context.is_kill = true
		# Dispatch ON_KILL for the source (attacker)
		if source and source != target:
			source.effects.dispatch(EffectResource.Trigger.ON_KILL, context)
			
		target.effects.dispatch(EffectResource.Trigger.ON_DEATH, context)

	# POST DAMAGE
	source.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_DEALT, context)
	target.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_TAKEN, context)

	# Log/UI events
	# For global bus, we might still need a dict or update it to handle objects
	GlobalEventBus.dispatch("combat_log", {"message": "%s attacks %s for %d damage" % [source.name, target.name, context.damage]}) 
	# GlobalEventBus.dispatch("damage_dealt", context) # Passing context object might need GlobalBus update

static func heal(target: Entity, amount: int) -> void:
	if not target or amount <= 0: return

	# Apply Heal
	target.stats.modify_current(StatsComponent.StatType.HP, amount)
	
	# Dispatch ON_HEAL_RECEIVED
	var context = CombatContext.new(null, target)
	context.raw_data["amount"] = amount # Heal amount isn't damage, store in raw or add 'heal_amount' to context
	target.effects.dispatch(EffectResource.Trigger.ON_HEAL_RECEIVED, context)
	
	GlobalEventBus.dispatch("combat_log", {"message": "%s healed for %d HP" % [target.name, amount]})
