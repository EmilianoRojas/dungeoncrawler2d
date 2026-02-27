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

	# === OBSERVE SKILL ===
	if skill.is_observe:
		# Reveal enemy info
		var enemy_hp = target.stats.get_current(StatTypes.HP)
		var enemy_max_hp = target.stats.get_stat(StatTypes.MAX_HP)
		var enemy_shield = target.stats.get_current(StatTypes.SHIELD)
		var enemy_max_shield = target.stats.get_stat(StatTypes.MAX_SHIELD)
		
		var hp_text = "[color=red]HP: %d/%d[/color]" % [enemy_hp, enemy_max_hp]
		if enemy_max_shield > 0:
			hp_text += " | [color=cyan]Shield: %d/%d[/color]" % [enemy_shield, enemy_max_shield]
		
		# Reveal next action (peek at enemy AI)
		var next_action_text = ""
		if target.skills and target.skills.known_skills.size() > 0:
			# Enemy AI uses first available skill
			var next_skill: Skill = null
			for s in target.skills.known_skills:
				if target.skills.is_skill_ready(s):
					next_skill = s
					break
			if next_skill:
				next_action_text = " | Next: [color=yellow]%s[/color]" % next_skill.skill_name
			else:
				next_action_text = " | Next: [color=gray]Waiting (all on CD)[/color]"
		
		GlobalEventBus.dispatch("combat_log", {
			"message": "[color=white]👁 OBSERVE[/color] %s — %s%s" % [target.name, hp_text, next_action_text]
		})
		
		# Dispatch observe event so UI can reveal hidden HP bars
		GlobalEventBus.dispatch("observe_used", {
			"source": source, "target": target
		})
		
		# Apply on_cast effects
		for effect in skill.on_cast_effects:
			source.effects.apply_effect(effect)
		return

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
		GlobalEventBus.dispatch("heal_applied", {
			"source": source, "target": source, "amount": heal_amount
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
		GlobalEventBus.dispatch("avoid_success", {"entity": target, "attacker": source})
		target.effects.dispatch(EffectResource.Trigger.ON_DAMAGE_RECEIVED_CALC, context)
		return

	# 3. Hit Check — skill accuracy + source accuracy stat
	var total_hit = skill.hit_chance + source.stats.get_stat(StatTypes.ACCURACY)
	if randi() % 100 >= total_hit:
		GlobalEventBus.dispatch("combat_log", {
			"message": "[color=yellow]MISS![/color] %s's %s missed %s" % [source.name, skill.skill_name, target.name]
		})
		GlobalEventBus.dispatch("skill_miss", {"source": source, "target": target})
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
