class_name OperationExecutor
extends Object

static func execute(instance: EffectInstance, owner: Entity, context: CombatContext) -> void:
	# 1. Condition Check
	for condition in instance.resource.conditions:
		if not _check_condition(condition, instance, owner, context):
			# Condition failed, abort
			return

	# 2. Proc Check
	if instance.resource.proc_chance < 1.0:
		if randf() > instance.resource.proc_chance:
			return

	var effect = instance.resource
	match effect.operation:

		EffectResource.Operation.HEAL_PERCENT:
			_heal_percent(instance, owner, context)

		EffectResource.Operation.HEAL_FLAT:
			_heal_flat(instance, owner)

		EffectResource.Operation.MODIFY_STAT_PERCENT:
			_modify_stat_percent(instance, owner)

		EffectResource.Operation.DEAL_DAMAGE_PERCENT_BACK:
			_thorns(instance, owner, context)

static func _check_condition(cond: EffectCondition, instance: EffectInstance, owner: Entity, context: CombatContext) -> bool:
	var target_entity: Entity = owner
	
	# Determine target based on condition settings
	if cond.target == EffectCondition.TargetType.TARGET:
		# Try to find "target" in combat context
		if context.target and context.target is Entity:
			target_entity = context.target
		elif context.source and context.source != owner:
			# If we are the target of an attack, the "source" is our opponent
			target_entity = context.source
		else:
			# Fallback or specific logic needed
			pass
	
	if target_entity == null:
		# print("DEBUG: _check_condition target is null") # Reducing noise
		return false
	
	match cond.type:
		EffectCondition.Type.HP_PERCENT_BELOW:
			if not "stats" in target_entity: return false
			var hp = target_entity.stats.current.get(StatsComponent.StatType.HP, 0)
			var max_hp = target_entity.stats.get_stat(StatsComponent.StatType.MAX_HP)
			var pct = float(hp) / max_hp if max_hp > 0 else 0.0
			return pct < cond.value
			
		EffectCondition.Type.HP_PERCENT_ABOVE:
			if not "stats" in target_entity: return false
			var hp = target_entity.stats.current.get(StatsComponent.StatType.HP, 0)
			var max_hp = target_entity.stats.get_stat(StatsComponent.StatType.MAX_HP)
			var pct = float(hp) / max_hp if max_hp > 0 else 0.0
			return pct > cond.value
			
		EffectCondition.Type.HAS_EFFECT_ID:
			if not "effects" in target_entity: return false
			return target_entity.effects._find_instance(cond.string_value) != null
			
		EffectCondition.Type.IS_CRIT:
			return context.is_crit
			 
		EffectCondition.Type.IS_KILL:
			return context.is_kill
			 
		EffectCondition.Type.CHANCE:
			return randf() <= cond.value
			
	return true

# 🧪 Implementaciones reales

# Lifesteal
static func _heal_percent(instance: EffectInstance, owner: Entity, context: CombatContext):
	var effect = instance.resource
	var damage = context.damage
	# Scale with stacks? e.g. 50% * 2 stacks = 100%? Or just duration stacking?
	# For now, let's assume intensity stacking for percent effects too.
	var value = effect.value * instance.stacks
	var heal_amount = int(damage * value)
	
	if heal_amount > 0:
		var heal_ctx = CombatContext.new(null, owner)
		heal_ctx.heal_amount = heal_amount
		CombatSystem.heal(heal_ctx)

# Heal flat
static func _heal_flat(instance: EffectInstance, owner: Entity):
	var effect = instance.resource
	var value = effect.value * instance.stacks
	var heal_amount = int(value)
	
	if heal_amount > 0:
		var heal_ctx = CombatContext.new(null, owner)
		heal_ctx.heal_amount = heal_amount
		CombatSystem.heal(heal_ctx)

# Thorns
static func _thorns(instance: EffectInstance, owner: Entity, context: CombatContext):
	var effect = instance.resource
	var attacker = context.source
	if attacker and attacker is Entity:
		var damage = context.damage
		var value = effect.value * instance.stacks
		var reflected = int(damage * value)
		
		var thorns_ctx = CombatContext.new(owner, attacker)
		thorns_ctx.damage = reflected
		CombatSystem.deal_damage(thorns_ctx)

# Stat buff
static func _modify_stat_percent(instance: EffectInstance, owner: Entity):
	var effect = instance.resource
	var stat = effect.stat_type
	if owner.has_method("get_stats") or "stats" in owner:
		var base = owner.stats.get_stat(stat)
		var value = effect.value * instance.stacks
		var bonus = int(base * value)
		
		owner.stats.add_bonus(stat, bonus)
