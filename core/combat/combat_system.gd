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

	# ===== PASSIVE RESOLVER HOOKS =====
	# pre_damage_calc — passives can modify context.damage via the data dict
	var pre_calc_data: Dictionary = {
		"source": source, "target": target,
		"damage": context.damage,
		"skill": context.skill
	}
	GlobalEventBus.dispatch("pre_damage_calc", pre_calc_data)
	context.damage = pre_calc_data.get("damage", context.damage)

	# ===== STAGE 4: FINAL =====
	# Final adjustments (e.g. Clamp damage, caps, special interactions)
	if source: source.effects.dispatch(EffectResource.Trigger.ON_PRE_DAMAGE_APPLY, context)
	target.effects.dispatch(EffectResource.Trigger.ON_PRE_DAMAGE_APPLY, context)

	# pre_damage_apply passive hook
	var pre_apply_data: Dictionary = {
		"source": source, "target": target,
		"damage": context.damage
	}
	GlobalEventBus.dispatch("pre_damage_apply", pre_apply_data)
	context.damage = pre_apply_data.get("damage", context.damage)

	# ===== APPLY DAMAGE (with Shield Absorption) =====
	var remaining_damage = context.damage
	
	if context.is_penetrating:
		# Penetrating: bypass Shield, go straight to HP
		target.stats.modify_current(StatTypes.HP, -remaining_damage)
	else:
		# Normal: Shield absorbs first, overflow hits HP
		var current_shield = target.stats.get_current(StatTypes.SHIELD)
		if current_shield > 0:
			if remaining_damage <= current_shield:
				# Shield absorbs all damage
				target.stats.modify_current(StatTypes.SHIELD, -remaining_damage)
				remaining_damage = 0
			else:
				# Shield breaks, overflow goes to HP
				remaining_damage -= current_shield
				target.stats.modify_current(StatTypes.SHIELD, -current_shield)
		
		# Apply remaining damage to HP
		if remaining_damage > 0:
			target.stats.modify_current(StatTypes.HP, -remaining_damage)

	# ===== POST DAMAGE =====
	if source: source.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_DEALT, context)
	target.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_TAKEN, context)

	# damage_taken passive hook (divine_retribution, counter, bloodlust update, etc.)
	GlobalEventBus.dispatch("damage_taken", {
		"source": source, "target": target,
		"damage": context.damage,
		"skill": context.skill
	})

	# Log/UI events
	var crit_tag = "[color=red]CRIT![/color] " if context.is_crit else ""
	GlobalEventBus.dispatch("combat_log", {
		"message": "%s%s attacks %s for %d damage" % [crit_tag, source.name if source else "Unknown", target.name, context.damage]
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
