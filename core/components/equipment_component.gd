class_name EquipmentComponent
extends Node

@export var stats_component: StatsComponent
@export var skill_component: SkillComponent
@export var passive_effect_component: PassiveEffectComponent
# OperationExecutor is a static class, so we don't need a reference instance usually, 
# but if it needs state, we might need one. Based on prior view, it's static.

# Slot -> EquipmentResource
var equipped_items: Dictionary = {}

var owner_entity: Entity

func _init(entity: Entity = null):
	if entity:
		owner_entity = entity

func equip(item: EquipmentResource) -> void:
	if not item: return
	
	var slot = item.slot
	
	# 1. Unequip existing if any
	if equipped_items.has(slot):
		unequip(slot)
	
	# 2. Register new item
	equipped_items[slot] = item
	var source_id = _get_source_id(slot)
	
	# 3. Apply Equipment Effects (Stats)
	for effect in item.equip_effects:
		# Use OperationExecutor to apply stats.
		# Operations usually expect an EffectInstance.
		var instance = EffectInstance.new(effect)
		
		# We need a context. For equipping, it's mostly self-application.
		# However, OperationExecutor.execute expects a CombatContext usually.
		# Stat Modifiers in OperationExecutor are handled specially:
		# "owner.stats.add_modifier(effect.stat_modifier, effect.effect_id)"
		# We want to override the source ID.
		
		# We can use a trick: pass context with custom_source_id if we modify OperationExecutor,
		# OR we can manually call stats_component if we want to bypass OperationExecutor for simple stats.
		# But the plan said "Use OperationExecutor".
		
		# Let's create a dummy context or rely on a new override in OperationExecutor.
		var context = CombatContext.new()
		context.custom_source_id = source_id # We added this in the plan
		
		if owner_entity:
			OperationExecutor.execute(instance, owner_entity, context)
		else:
			push_error("EquipmentComponent: owner_entity is null, cannot apply stats!")

	# 4. Add Skills
	if skill_component:
		for skill in item.granted_skills:
			skill_component.add_skill(skill, source_id)
			
			
	# 5. Add Passives
	if passive_effect_component:
		for passive in item.passive_effects:
			passive_effect_component.add_passive(passive, source_id)
			
	print("Equipped %s to %s" % [item.display_name, EquipmentSlot.Type.keys()[slot]])

func unequip(slot: EquipmentSlot.Type) -> void:
	if not equipped_items.has(slot):
		return
		
	var source_id = _get_source_id(slot)
	
	# 1. Remove Stat Modifiers
	if stats_component:
		stats_component.remove_modifiers_from_source(source_id)
		
	# 2. Remove Skills
	if skill_component:
		skill_component.remove_skills_from_source(source_id)
		
	# 3. Remove Passives
	if passive_effect_component:
		passive_effect_component.remove_from_source(source_id)
	
	equipped_items.erase(slot)
	print("Unequipped slot %s" % EquipmentSlot.Type.keys()[slot])

func _get_source_id(slot: EquipmentSlot.Type) -> StringName:
	# Convert enum integer to string name for unique source ID
	# e.g. "MAIN_HAND", "HEAD"
	return EquipmentSlot.Type.keys()[slot]
