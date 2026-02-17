class_name EquipmentComponent
extends Node

@export var stats_component: StatsComponent
@export var skill_component: SkillComponent
@export var passive_effect_component: PassiveEffectComponent
# OperationExecutor is a static class, so we don't need a reference instance usually, 
# but if it needs state, we might need one. Based on prior view, it's static.

# Slot -> EquipmentResource (Data)
var equipped_items: Dictionary = {}

# Generic Modifiers (Sources like Passives, Events, Equipment)
var active_modifiers: Array[Resource] = []

var owner_entity: Entity

func initialize(entity: Entity):
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
	
	# 3. Apply Modifiers via Generic API
	_apply_equipment_modifiers(item)
			
	print("Equipped %s to %s" % [item.display_name, EquipmentSlot.Type.keys()[slot]])

# Wrapper to add modifiers from an equipment source
func _apply_equipment_modifiers(item: EquipmentResource) -> void:
	# Add the item itself as a source if needed, or iterate its effects
	# The prompt suggested "add_modifier(source: Resource)"
	# A single EquipmentResource might contain multiple effects.
	var source_id = _get_source_id(item.slot)
	
	# Apply Stats
	for effect in item.equip_effects:
		_apply_effect(effect, source_id)
		
	# Apply Skills
	if skill_component:
		for skill in item.granted_skills:
			skill_component.add_skill(skill, source_id)
			
	# Apply Passives
	if passive_effect_component:
		for passive in item.passive_effects:
			passive_effect_component.add_passive(passive, source_id)

# GENERIC MODIFIER API
func add_modifier(source: Resource) -> void:
	if not source: return
	
	if source is EquipmentResource:
		# If passed as a modifier directly (e.g. from RewardApplier generic path)
		# We might need to handle this carefully if it overlaps with equip()
		# Ideally equip() manages slots, add_modifier manages untracked buffs.
		pass
	elif source is EffectResource:
		# Apply a raw effect
		# We need a source ID for this. Maybe "Modifier_<ResourceID>"
		var source_id = "Mod_%s" % source.resource_name
		_apply_effect(source, source_id)
		active_modifiers.append(source)

func remove_modifier(source: Resource) -> void:
	if source in active_modifiers:
		active_modifiers.erase(source)
		# Todo: Remove logic needs source tracking mappping
		# For now, simplistic implementation
		pass

func _apply_effect(effect: EffectResource, source_id: StringName) -> void:
	# ... (Original effect application logic from equip) ...
	var instance = EffectInstance.new(effect)
	var context = CombatContext.new()
	context.custom_source_id = source_id
	
	if owner_entity:
		OperationExecutor.execute(instance, owner_entity, context)
	else:
		push_error("EquipmentComponent: owner_entity is null, cannot apply stats!")

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
	
	print("Unequipped slot %s" % EquipmentSlot.Type.keys()[slot])

func _get_source_id(slot: EquipmentSlot.Type) -> StringName:
	# Convert enum integer to string name for unique source ID
	# e.g. "MAIN_HAND", "HEAD"
	return EquipmentSlot.Type.keys()[slot]
