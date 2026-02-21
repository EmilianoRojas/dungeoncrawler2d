class_name LootSystem
extends Node

# Procedural loot generation (GameSpec §5)
# Generates equipment rewards from enemy kills and chests.

# --- DROP RATES ---
const DROP_CHANCE_NORMAL: float = 0.20
const DROP_CHANCE_ELITE: float = 0.60
const DROP_CHANCE_BOSS: float = 1.00

# --- ENEMY LOOT ---

## Generate loot from defeating an enemy.
## Returns an array of RewardResource (may be empty if no drop).
static func generate_enemy_loot(dungeon_floor: int, is_elite: bool = false, is_boss: bool = false) -> Array[RewardResource]:
	var rewards: Array[RewardResource] = []
	
	# Determine drop chance
	var chance = DROP_CHANCE_NORMAL
	if is_boss:
		chance = DROP_CHANCE_BOSS
	elif is_elite:
		chance = DROP_CHANCE_ELITE
	
	# Roll for drop
	if randf() > chance:
		return rewards # No drop
	
	# Generate a random item
	var item = ItemFactory.generate_random_item(dungeon_floor)
	
	# Boss drops get +1 rarity tier
	if is_boss:
		item.rarity = ItemFactory.bump_rarity(item.rarity)
		# Prefix name if not already prefixed
		if not item.display_name.begins_with(item.rarity):
			item.display_name = "%s %s" % [item.rarity, item.display_name]
	
	# Wrap in RewardResource
	var reward = _wrap_equipment(item)
	rewards.append(reward)
	
	return rewards

# --- CHEST LOOT ---

## Generate loot from a chest room. Always drops at least 1 item.
static func generate_chest_loot(dungeon_floor: int) -> Array[RewardResource]:
	var rewards: Array[RewardResource] = []
	
	# First item (guaranteed)
	var item1 = ItemFactory.generate_random_item(dungeon_floor)
	rewards.append(_wrap_equipment(item1))
	
	# 30% chance of a second item
	if randf() < 0.30:
		var item2 = ItemFactory.generate_random_item(dungeon_floor)
		rewards.append(_wrap_equipment(item2))
	
	return rewards

# --- HELPERS ---

static func _wrap_equipment(item: EquipmentResource) -> RewardResource:
	var reward = RewardResource.new()
	reward.type = RewardResource.Type.EQUIPMENT
	reward.equipment = item
	return reward
