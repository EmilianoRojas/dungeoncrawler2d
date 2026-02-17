class_name LootSystem
extends Node

# This class handles loot generation logic.
# In a real game, this would likely be an Autoload or a Component on the GameLoop.
# For now, it provides static utility functions or can be instanced where needed.

# Assuming we might have an 'EnemyData' resource type in the future with a 'loot_table'.
# For now, we'll design the interface as requested.

# Generates loot from an enemy drop (using RewardSystem)
static func generate_enemy_loot(enemy_data: Dictionary) -> Array[RewardResource]:
    var rewards: Array[RewardResource] = []
    
    # Delegate to RewardSystem
    var reward = RewardSystem.generate_enemy_reward(enemy_data)
    if reward:
        rewards.append(reward)
        
    return rewards

# Generates loot from a chest (using RewardSystem)
static func generate_chest_loot(chest_data: Dictionary) -> Array[RewardResource]:
    var rewards: Array[RewardResource] = []
    
    if chest_data.has("guaranteed_loot"):
        for item_res in chest_data.guaranteed_loot:
            # Wrap equipment in RewardResource
            var reward = RewardSystem._create_equipment_reward(item_res)
            rewards.append(reward)
            
    return rewards
