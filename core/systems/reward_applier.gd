class_name RewardApplier
extends Node

# APLICA REWARDS - NO GENERA

static func apply_reward(entity: Entity, reward: RewardResource) -> void:
	if not entity or not reward:
		push_error("Cannot apply reward: invalid entity or reward")
		return
		
	match reward.type:
		RewardResource.Type.EQUIPMENT:
			_apply_equipment(entity, reward.equipment)
		RewardResource.Type.SKILL:
			# Assuming entity has SkillComponent
			pass # Todo: skill learning logic
		RewardResource.Type.PASSIVE:
			# Assuming entity has PassiveComponent or EffectManager
			_apply_passive(entity, reward.effect)
		RewardResource.Type.STAT:
			# Assuming entity has StatsComponent
			_apply_stat(entity, reward.stat_name, reward.value)
			
	print("Applied reward: %s to %s" % [reward.get_display_name(), entity.name])

static func _apply_equipment(entity: Entity, equip: EquipmentResource) -> void:
	var equipment_comp = entity.get_node_or_null("EquipmentComponent") # Or accessing via property if typed
	if equipment_comp and equipment_comp.has_method("equip"):
		equipment_comp.equip(equip)
	else:
		push_warning("Entity %s has no EquipmentComponent to equip %s" % [entity.name, equip.display_name])

static func _apply_passive(entity: Entity, effect: EffectResource) -> void:
	# Generic applier using add_modifier if supported by Architecture
	# If EquipmentComponent supports generic modifiers as requested:
	var equip_comp = entity.get_node_or_null("EquipmentComponent")
	if equip_comp and equip_comp.has_method("add_modifier"):
		equip_comp.add_modifier(effect)
	else:
		# Fallback to specifically PassiveComponent if exists
		pass

static func _apply_stat(entity: Entity, stat: StringName, value: float) -> void:
	# Access StatsComponent directly
	# This needs standardized access to components on Entity
	pass
