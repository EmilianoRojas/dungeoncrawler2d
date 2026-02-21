class_name ItemFactory
extends Object

# Procedural item generation system (GameSpec §5, §9.7)
# Creates EquipmentResource instances with floor-scaled stat budgets and rarity rolls.

# --- RARITY SYSTEM ---
# Higher rarity = larger stat budget multiplier
const RARITY_NAMES: Array[String] = ["Common", "Rare", "Epic", "Legendary"]
const RARITY_BUDGET_MULT: Array[float] = [1.0, 1.5, 2.0, 3.0]

# Stat value per budget point (some stats are worth more per point)
const STAT_VALUE_PER_POINT: Dictionary = {
	StatTypes.STRENGTH: 1,
	StatTypes.DEXTERITY: 1,
	StatTypes.INTELLIGENCE: 1,
	StatTypes.PIETY: 1,
	StatTypes.POWER: 1,
	StatTypes.MAX_HP: 5,
	StatTypes.DEFENSE: 1,
	StatTypes.MAX_SHIELD: 3,
	StatTypes.CRIT_CHANCE: 1,
	StatTypes.CRIT_DAMAGE: 5,
	StatTypes.PARRY_CHANCE: 1,
	StatTypes.AVOID_CHANCE: 1,
	StatTypes.ACCURACY: 2,
}

# --- MAIN API ---

## Generate a procedural item from a base template, scaled by floor.
static func generate_item(base_template: EquipmentResource, dungeon_floor: int) -> EquipmentResource:
	# 1. Duplicate the base template so we don't mutate the original
	var item = base_template.duplicate() as EquipmentResource
	
	# 2. Roll rarity
	var rarity_index = _roll_rarity(dungeon_floor)
	item.rarity = RARITY_NAMES[rarity_index]
	
	# 3. Calculate stat budget
	var base_budget = randi_range(dungeon_floor, dungeon_floor * 3)
	var budget = int(base_budget * RARITY_BUDGET_MULT[rarity_index])
	budget = max(1, budget) # At least 1 point
	
	# 4. Get allowed stats for this slot
	var allowed_stats = ItemTemplates.get_allowed_stats(item.slot)
	if allowed_stats.is_empty():
		return item
	
	# 5. Distribute budget into stat modifiers
	var stat_totals: Dictionary = {} # StringName -> accumulated value
	for i in range(budget):
		var stat = allowed_stats[randi() % allowed_stats.size()]
		if not stat_totals.has(stat):
			stat_totals[stat] = 0
		stat_totals[stat] += STAT_VALUE_PER_POINT.get(stat, 1)
	
	# 6. Create EffectResource + StatModifier for each rolled stat
	for stat_key in stat_totals:
		var mod = StatModifier.new()
		mod.stat = stat_key
		mod.type = StatModifier.Type.FLAT
		mod.value = float(stat_totals[stat_key])
		
		var effect = EffectResource.new()
		effect.effect_id = &"equip_%s" % stat_key
		effect.operation = EffectResource.Operation.ADD_STAT_MODIFIER
		effect.stat_modifier = mod
		
		item.equip_effects.append(effect)
	
	# 7. Update display name with rarity prefix
	if rarity_index > 0:
		item.display_name = "%s %s" % [item.rarity, item.display_name]
	
	return item

## Generate a random item from the template registry.
static func generate_random_item(dungeon_floor: int, slot: int = -1) -> EquipmentResource:
	var template = ItemTemplates.get_random_template(slot)
	return generate_item(template, dungeon_floor)

# --- RARITY ROLLS ---
# Floor affects chance: higher floors = better rarity odds

static func _roll_rarity(dungeon_floor: int) -> int:
	var roll = randf()
	
	# Legendary: 1% + floor×0.5%
	var legendary_chance = 0.01 + dungeon_floor * 0.005
	if roll < legendary_chance:
		return 3
	
	# Epic: 5% + floor×1%
	var epic_chance = legendary_chance + 0.05 + dungeon_floor * 0.01
	if roll < epic_chance:
		return 2
	
	# Rare: 15% + floor×2%
	var rare_chance = epic_chance + 0.15 + dungeon_floor * 0.02
	if roll < rare_chance:
		return 1
	
	# Common
	return 0

## Force a minimum rarity (used for boss drops)
static func bump_rarity(current_rarity: String) -> String:
	var index = RARITY_NAMES.find(current_rarity)
	if index < 0:
		index = 0
	var new_index = min(index + 1, RARITY_NAMES.size() - 1)
	return RARITY_NAMES[new_index]
