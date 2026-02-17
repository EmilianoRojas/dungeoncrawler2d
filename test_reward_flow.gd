extends Node

func _init():
	print("Starting Reward Flow Test...")
	
	# 1. Setup Data
	var sword_res = EquipmentResource.new()
	sword_res.id = "sword_reward"
	sword_res.display_name = "Victory Sword"
	sword_res.slot = EquipmentSlot.Type.MAIN_HAND
	sword_res.rarity = "Epic"
	
	var mock_enemy_data = {
		"loot_table": [sword_res] # RewardSystem handles EquipmentResource -> RewardResource conversion
	}
	
	# 2. Setup Entity
	var player = Entity.new()
	player.name = "Hero"
	var equipment_comp = EquipmentComponent.new()
	equipment_comp.name = "EquipmentComponent"
	player.add_child(equipment_comp)
	# Inject dependency if needed (usually done in _ready or setup)
	# equipment_comp.owner_entity = player # _init handles this if passed, but here we added as child
	equipment_comp.initialize(player) # Use explicit initialize
	
	# 3. Test Generation (RewardSystem)
	print("Generating reward...")
	var reward = RewardSystem.generate_enemy_reward(mock_enemy_data)
	
	assert(reward != null, "Reward should be generated")
	assert(reward is RewardResource, "Result should be a RewardResource")
	assert(reward.type == RewardResource.Type.EQUIPMENT, "Reward type should be EQUIPMENT")
	assert(reward.equipment == sword_res, "Reward content should match")
	
	print("Generated Reward: %s (%s)" % [reward.get_display_name(), reward.equipment.rarity])
	
	# 4. Test Application (RewardApplier)
	print("Applying reward...")
	RewardApplier.apply_reward(player, reward)
	
	# 5. Verify Result
	assert(equipment_comp.equipped_items.has(EquipmentSlot.Type.MAIN_HAND), "Item should be equipped")
	assert(equipment_comp.equipped_items[EquipmentSlot.Type.MAIN_HAND] == sword_res, "Equipped item should be the reward")
	
	print("Reward Application Verified. Item equipped: ", equipment_comp.equipped_items[EquipmentSlot.Type.MAIN_HAND].display_name)
	
	# 6. Test LootSystem Integration
	print("Testing LootSystem generic wrapper...")
	var loot_rewards = LootSystem.generate_enemy_loot(mock_enemy_data)
	assert(loot_rewards.size() == 1, "LootSystem should return 1 reward")
	assert(loot_rewards[0].equipment == sword_res, "LootSystem reward should match")
	
	print("Reward Flow Test Passed!")

	# 7. Test Equipment Replacement
	print("Testing equipment replacement...")
	
	var new_sword_res = EquipmentResource.new()
	new_sword_res.id = "sword_reward_legendary"
	new_sword_res.display_name = "Legendary Sword"
	new_sword_res.slot = EquipmentSlot.Type.MAIN_HAND
	new_sword_res.rarity = "Legendary"
	
	var new_reward = RewardResource.new()
	new_reward.type = RewardResource.Type.EQUIPMENT
	new_reward.equipment = new_sword_res
	
	RewardApplier.apply_reward(player, new_reward)
	
	assert(equipment_comp.equipped_items[EquipmentSlot.Type.MAIN_HAND] == new_sword_res, "New sword should replace the old one")
	print("Replacement test passed!")
