class_name SkillExecutor
extends Object

static func execute(skill: Skill, source: Entity, target: Entity) -> void:
	if not skill or not source or not target:
		push_error("SkillExecutor: Invalid arguments")
		return

	# 1. Trigger ON_SKILL_CAST
	var context = CombatContext.new(source, target, skill)
	source.effects.dispatch(EffectResource.Trigger.ON_SKILL_CAST, context)

	var damage = FormulaCalculator.calculate_damage(skill, source)
	context.damage = damage
	
	CombatSystem.deal_damage(context)
	
	# 2. Apply Skill Effects
	
	# Effects on Self (e.g. Buffs, Recoil)
	for effect in skill.on_cast_effects:
		source.effects.apply_effect(effect)
		
	# Effects on Target (e.g. Debuffs, DoTs)
	for effect in skill.on_hit_effects:
		target.effects.apply_effect(effect)
