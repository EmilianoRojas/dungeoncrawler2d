class_name OperationExecutor
extends Object

static func execute(instance: EffectInstance, owner: Entity, context: CombatContext) -> void:
	# 1. Proc Check
	if instance.resource.proc_chance < 1.0:
		if randf() > instance.resource.proc_chance:
			return

	# 2. Conditions Check
	for condition in instance.resource.conditions:
		if not _check_condition(condition, instance, owner, context):
			return

	# 3. Calculate Effect Value (stack scaling included)
	var effect = instance.resource
	var value = effect.value * instance.stacks
	
	# 4. Apply Operation
	match effect.operation:
		
		# --- OFFENSIVE ---
		EffectResource.Operation.ADD_DAMAGE:
			context.damage += int(value)
		
		EffectResource.Operation.ADD_DAMAGE_PERCENT:
			context.damage += int(context.damage * value)
		
		EffectResource.Operation.MULTIPLY_DAMAGE:
			context.damage = int(context.damage * value)
		
		EffectResource.Operation.SET_DAMAGE:
			context.damage = int(value)
		
		# --- DEFENSIVE ---
		EffectResource.Operation.REDUCE_DAMAGE_FLAT:
			context.damage -= int(value)
		
		EffectResource.Operation.REDUCE_DAMAGE_PERCENT:
			context.damage = int(context.damage * (1.0 - value))
		
		EffectResource.Operation.ABSORB_DAMAGE:
			var absorbed = min(context.damage, int(value))
			context.damage -= absorbed
		
		# --- CLAMPS ---
		EffectResource.Operation.CLAMP_MIN_DAMAGE:
			context.damage = max(context.damage, int(value))
		
		EffectResource.Operation.CLAMP_MAX_DAMAGE:
			context.damage = min(context.damage, int(value))
		
		# --- SPECIAL ---
		EffectResource.Operation.CONVERT_TO_TRUE_DAMAGE:
			context.ignore_defense = true
		
		EffectResource.Operation.STORE_DAMAGE:
			context.stored_damage += context.damage

	# 5. Final Safety Clamp (Prevent negative damage in pipeline for damage ops)
	# (Only relevant if we modified damage)
	
	# --- STAT MODIFIERS ---
	match effect.operation:
		EffectResource.Operation.ADD_STAT_MODIFIER:
			if "stats" in owner and effect.stat_modifier:
				# Check for override from context (used by EquipmentComponent)
				var source_id = effect.effect_id
				if context and context.custom_source_id != "":
					source_id = context.custom_source_id
				
				# Pass the source_id so we can remove it later
				owner.stats.add_modifier(effect.stat_modifier, source_id)
				# print("Applied Stat Modifier from Effect: %s" % effect.effect_id)
	
		EffectResource.Operation.HEAL:
			if "stats" in owner:
				context.heal_amount = int(value)
				CombatSystem.heal(context)
		
		EffectResource.Operation.DAMAGE_OVER_TIME:
			if "stats" in owner:
				var dot_damage = int(value)
				
				# DoT bypasses Shield but respects Damage Reduce passive
				# Check if entity has damage_reduce passive
				if owner.passives:
					var dr_passives = owner.passives.get_passives_by_trigger(EffectResource.Trigger.ON_PRE_DAMAGE_APPLY)
					for p_data in dr_passives:
						var p_info = p_data.get("passive_info", {}) as Dictionary
						if p_info.get("logic", "") == "damage_reduce":
							dot_damage = int(dot_damage * 0.85) # 15% reduction
				
				dot_damage = max(1, dot_damage) # At least 1
				owner.stats.modify_current(StatTypes.HP, -dot_damage)
				
				# Color based on effect type
				var effect_name = instance.resource.effect_id
				var color = "purple" if effect_name == &"poison" else "orange"
				var icon = "☠" if effect_name == &"poison" else "🔥"
				GlobalEventBus.dispatch("combat_log", {
					"message": "[color=%s]%s %s takes %d %s damage![/color]" % [color, icon, owner.name, dot_damage, effect_name]
				})
				GlobalEventBus.dispatch("damage_dealt", {
					"source": null, "target": owner,
					"damage": dot_damage, "is_crit": false
				})
				# Death check
				if owner.stats.get_current(StatTypes.HP) <= 0:
					GlobalEventBus.dispatch("entity_died", {"entity": owner, "killer": null})

	# 5b. Final Safety Clamp again, just in case
	context.damage = max(0, context.damage)



static func _check_condition(cond: EffectCondition, instance: EffectInstance, owner: Entity, context: CombatContext) -> bool:
	var target_entity: Entity = owner
	
	# Determine target based on condition settings
	if cond.target == EffectCondition.TargetType.TARGET:
		# Try to find "target" in combat context
		if context.target and context.target is Entity:
			target_entity = context.target
		elif context.source and context.source != owner:
			target_entity = context.source
		else:
			target_entity = null # Explicitly null if not found
	
	match cond.type:
		EffectCondition.Type.HP_PERCENT_BELOW:
			if target_entity == null or not "stats" in target_entity: return false
			var hp = target_entity.stats.current.get(StatTypes.HP, 0)
			var max_hp = target_entity.stats.get_stat(StatTypes.MAX_HP)
			var pct = float(hp) / max_hp if max_hp > 0 else 0.0
			return pct < cond.value
			
		EffectCondition.Type.HP_PERCENT_ABOVE:
			if target_entity == null or not "stats" in target_entity: return false
			var hp = target_entity.stats.current.get(StatTypes.HP, 0)
			var max_hp = target_entity.stats.get_stat(StatTypes.MAX_HP)
			var pct = float(hp) / max_hp if max_hp > 0 else 0.0
			return pct > cond.value
			
		EffectCondition.Type.HAS_EFFECT_ID:
			if target_entity == null or not "effects" in target_entity: return false
			return target_entity.effects._find_instance(cond.string_value) != null
			
		EffectCondition.Type.IS_CRIT:
			return context.is_crit
			 
		EffectCondition.Type.IS_KILL:
			return context.is_kill
			 
		EffectCondition.Type.CHANCE:
			return randf() <= cond.value
			
	return true
