class_name SkillExecutor
extends Object

static func execute(skill: Skill, source: Entity, target: Entity) -> void:
	if not skill or not source or not target:
		push_error("SkillExecutor: Invalid arguments")
		return

	var context = CombatContext.new(source, target, skill)
	context.is_penetrating = skill.ignores_shield

	# 1. Trigger ON_SKILL_CAST (before any rolls)
	source.effects.dispatch(EffectResource.Trigger.ON_SKILL_CAST, context)

	# === SELF-HEAL SKILLS ===
	if skill.is_self_heal:
		var heal_amount = FormulaCalculator.calculate_damage(skill, source)
		var heal_context = CombatContext.new(source, source, skill)
		heal_context.heal_amount = heal_amount
		CombatSystem.heal(heal_context)
		GlobalEventBus.dispatch("combat_log", {
			"message": "[color=green]HEAL![/color] %s healed for %d HP" % [source.name, heal_amount]
		})
		# Apply on_cast effects
		for effect in skill.on_cast_effects:
			source.effects.apply_effect(effect)
		# Update damage_dealt event so UI refreshes
		GlobalEventBus.dispatch("damage_dealt", {
			"source": source, "target": source,
			"damage": 0, "is_crit": false
		})
		return

	# === COMBAT ROLL SEQUENCE ===

	# 2. Avoid Check — target dodges entirely
	var avoid_chance = target.stats.get_stat(StatTypes.AVOID_CHANCE)
	if avoid_chance > 0 and randi() % 100 < avoid_chance:
		context.is_avoided = true
		GlobalEventBus.dispatch("combat_log", {
			"message": "[color=cyan]AVOIDED![/color] %s dodged %s's %s" % [target.name, source.name, skill.skill_name]
		})
		# Fire avoid event for passives
		target.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_RECEIVED_CALC, context)
		return

	# 3. Hit Check — skill accuracy + source accuracy stat
	var total_hit = skill.hit_chance + source.stats.get_stat(StatTypes.ACCURACY)
	if randi() % 100 >= total_hit:
		GlobalEventBus.dispatch("combat_log", {
			"message": "[color=yellow]MISS![/color] %s's %s missed %s" % [source.name, skill.skill_name, target.name]
		})
		return

	# 4. Parry Check — target deflects the attack
	var parry_chance = target.stats.get_stat(StatTypes.PARRY_CHANCE)
	if parry_chance > 0 and randi() % 100 < parry_chance:
		context.is_parry = true
		GlobalEventBus.dispatch("combat_log", {
			"message": "[color=orange]PARRIED![/color] %s deflected %s's %s" % [target.name, source.name, skill.skill_name]
		})
		# Fire parry event — ideal for Swordmanship passive
		GlobalEventBus.dispatch("parry_success", {"entity": target, "attacker": source})
		return

	# 5. Calculate base damage
	var damage = FormulaCalculator.calculate_damage(skill, source)
	context.damage = damage

	# 6. Crit Roll
	var crit_chance = source.stats.get_stat(StatTypes.CRIT_CHANCE)
	if crit_chance > 0 and randi() % 100 < crit_chance:
		context.is_crit = true
		var crit_mult = source.stats.get_stat(StatTypes.CRIT_DAMAGE) / 100.0
		context.damage = int(context.damage * crit_mult)

	# 7. Deal damage through the full pipeline
	CombatSystem.deal_damage(context)

	# 8. Apply Skill Effects (after damage resolves)
	# Effects on Self (e.g. Buffs, Recoil)
	for effect in skill.on_cast_effects:
		source.effects.apply_effect(effect)
	# Effects on Target (e.g. Debuffs, DoTs)
	for effect in skill.on_hit_effects:
		target.effects.apply_effect(effect)
