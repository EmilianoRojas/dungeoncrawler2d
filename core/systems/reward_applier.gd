class_name RewardApplier
extends Node

# Applies RewardResource to an Entity (GameSpec §5)
# Handles equipment auto-equip, skill learning, passive effects, and stat bonuses.

static func apply_reward(entity: Entity, reward: RewardResource) -> void:
	if not entity or not reward:
		push_error("Cannot apply reward: invalid entity or reward")
		return
		
	match reward.type:
		RewardResource.Type.EQUIPMENT:
			_apply_equipment(entity, reward.equipment)
		RewardResource.Type.SKILL:
			_apply_skill(entity, reward.skill)
		RewardResource.Type.PASSIVE:
			_apply_passive(entity, reward.effect)
		RewardResource.Type.STAT:
			_apply_stat(entity, reward.stat_name, reward.value)

static func _apply_equipment(entity: Entity, equip: EquipmentResource) -> void:
	if not equip: return
	if entity.equipment:
		entity.equipment.equip(equip)
	else:
		push_warning("Entity %s has no EquipmentComponent" % entity.name)

static func _apply_skill(entity: Entity, skill: Skill) -> void:
	if not skill: return
	if entity.skills:
		entity.skills.learn_skill(skill)

static func _apply_passive(entity: Entity, effect: EffectResource) -> void:
	if not effect: return
	if entity.effects:
		entity.effects.apply_effect(effect)

static func _apply_stat(entity: Entity, stat: StringName, value: float) -> void:
	if stat == &"" or not entity.stats: return
	# Create a temporary stat modifier
	var mod = StatModifier.new()
	mod.stat = stat
	mod.type = StatModifier.Type.FLAT
	mod.value = value
	entity.stats.add_modifier(mod, &"reward_bonus")

## Try to auto-equip an item. Returns true if equipped.
## Logic: equip if slot is empty, or if new item has more equip_effects (proxy for "better").
static func try_auto_equip(entity: Entity, equip: EquipmentResource) -> bool:
	if not entity.equipment or not equip:
		return false
	
	var slot = equip.slot
	if not entity.equipment.equipped_items.has(slot):
		# Slot empty — just equip
		entity.equipment.equip(equip)
		return true
	
	# Compare: new item has more effects = probably better (simple heuristic)
	var current = entity.equipment.equipped_items[slot] as EquipmentResource
	if equip.equip_effects.size() > current.equip_effects.size():
		entity.equipment.equip(equip) # unequip old is handled inside
		return true
	
	# Don't equip — current is equal or better
	return false
