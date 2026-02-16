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
	target.stats.modify_current(StatTypes.HP, -context.damage)

	# ===== POST DAMAGE =====
	if source: source.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_DEALT, context)
	target.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_TAKEN, context)

	# Log/UI events
	GlobalEventBus.dispatch("combat_log", {
		"message": "%s attacks %s for %d damage" % [source.name if source else "Unknown", target.name, context.damage]
	}) 
	
	GlobalEventBus.dispatch("damage_dealt", {
		"source": source,
		"target": target,
		"damage": context.damage,
		"is_crit": context.is_crit,
		"is_kill": context.is_kill
	})
	
	# ===== DEATH CHECK =====
	var current_hp = target.stats.get_current(StatTypes.HP)
	if current_hp <= 0:
		context.is_kill = true
		
		# Triggers
		if source and source != target:
			source.effects.dispatch(EffectResource.Trigger.ON_KILL, context)
		target.effects.dispatch(EffectResource.Trigger.ON_DEATH, context)
		
		# Global Event
		GlobalEventBus.dispatch("entity_died", {"entity": target, "killer": source})

static func heal(context: CombatContext) -> void:
	var target = context.target
	var amount = context.heal_amount
	if not target:
		print("DEBUG: Heal failed - No target")
		return
	if amount <= 0:
		print("DEBUG: Heal failed - Amount <= 0 (%d)" % amount)
		return

	print("DEBUG: Applying Heal. Target: %s, Amount: %d, Current HP: %d" % [target.name, amount, target.stats.get_current(StatTypes.HP)])

	# Apply Heal
	target.stats.modify_current(StatTypes.HP, amount)
	
	# Dispatch ON_HEAL_RECEIVED
	target.effects.dispatch(EffectResource.Trigger.ON_HEAL_RECEIVED, context)
	
	GlobalEventBus.dispatch("combat_log", {"message": "%s healed for %d HP" % [target.name, amount]})
