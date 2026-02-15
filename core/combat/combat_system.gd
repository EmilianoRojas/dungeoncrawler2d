class_name CombatSystem
extends Object

static func deal_damage(context: CombatContext) -> void:
	var source = context.source
	var target = context.target
	if not target: return
	
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
	# GlobalEventBus.dispatch("combat_log", {"message": "%s attacks %s for %d damage" % [source.name, target.name, context.damage]}) 
	# GlobalEventBus.dispatch("damage_dealt", context) # Passing context object might need GlobalBus update

static func heal(context: CombatContext) -> void:
	var target = context.target
	var amount = context.heal_amount
	if not target or amount <= 0: return

	# Apply Heal
	target.stats.modify_current(StatsComponent.StatType.HP, amount)
	
	# Dispatch ON_HEAL_RECEIVED
	target.effects.dispatch(EffectResource.Trigger.ON_HEAL_RECEIVED, context)
	
	# GlobalEventBus.dispatch("combat_log", {"message": "%s healed for %d HP" % [target.name, amount]})
