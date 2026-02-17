class_name RewardSystem
extends Node

# GENERA REWARDS - NO APLICA

# Generates a reward from an enemy drop table
# Returns a RewardResource (single) or null
static func generate_enemy_reward(enemy_data: Dictionary) -> RewardResource:
	# Implementation depends on enemy_data structure.
	# Assuming enemy_data has 'loot_table' (Array of RewardResource or weights)
	if not enemy_data.has("loot_table"):
		return null
		
	var loot_table = enemy_data.loot_table
	# Simple random pick for now
	if loot_table.size() > 0:
		var pick = loot_table.pick_random()
		# If table contains weights or more complex data, logic goes here.
		# For now assume it contains RewardResources directly or dicts to construct them.
		if pick is RewardResource:
			return pick
		elif pick is EquipmentResource:
			return _create_equipment_reward(pick)
			
	return null

# Helper to wrap equipment in reward
static func _create_equipment_reward(equip: EquipmentResource) -> RewardResource:
	var reward = RewardResource.new()
	reward.type = RewardResource.Type.EQUIPMENT
	reward.equipment = equip
	# Copy metadata if needed, usually comes from EquipmentResource data
	# reward.rarity = equip.rarity_value # if implies mapping
	return reward
