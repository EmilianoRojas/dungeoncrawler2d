class_name CombatSystem
extends Object

static func deal_damage(context: CombatContext) -> void:
	var source = context.source
	var target = context.target
	if not target: return

	# ===== STAGE 1: PRE CALC =====
	# Before base damage calculation (e.g. "Next attack +50% power")
	if source: source.effects.dispatch(EffectResource.Trigger.ON_PRE_DAMAGE_CALC, context)

	# ===== STAGE 2: OFFENSIVE =====
	# After base damage, before defenses (e.g. Crit, Attack Buffs, Elemental)
	if source: source.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_CALCULATED, context)

	# ===== STAGE 3: DEFENSIVE =====
	# Target modifies incoming damage (e.g. Shields, Armor, Resistances)
	target.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_RECEIVED_CALC, context)

	# ===== STAGE 4: FINAL =====
	# Final adjustments (e.g. Clamp damage, caps, special interactions)
	if source: source.effects.dispatch(EffectResource.Trigger.ON_PRE_DAMAGE_APPLY, context)
	target.effects.dispatch(EffectResource.Trigger.ON_PRE_DAMAGE_APPLY, context)

	# ===== APPLY DAMAGE =====
	target.stats.modify_current(StatsComponent.StatType.HP, -context.damage)

	# ===== POST DAMAGE =====
	if source: source.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_DEALT, context)
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
