extends Node

func _init():
	print("Starting Inventory System Test...")
	
	# 1. Create Mock Resources
	var sword_res = EquipmentResource.new()
	sword_res.id = "sword_001"
	sword_res.display_name = "Iron Sword"
	sword_res.slot = EquipmentSlot.Type.MAIN_HAND
	
	var shield_res = EquipmentResource.new()
	shield_res.id = "shield_001"
	shield_res.display_name = "Wooden Shield"
	shield_res.slot = EquipmentSlot.Type.OFF_HAND
	
	# 2. Test InventoryComponent
	var inventory = InventoryComponent.new()
	print("Adding items to inventory...")
	
	var sword_item = inventory.add_item(sword_res)
	var shield_item = inventory.add_item(shield_res)
	
	assert(inventory.items.size() == 2, "Inventory should have 2 items")
	assert(sword_item.equipment == sword_res, "Sword item should reference sword resource")
	assert(sword_item.instance_id != "", "Item should have an instance ID")
	
	print("Inventory items added successfully. IDs: ", sword_item.instance_id, ", ", shield_item.instance_id)
	
	# 3. Test LootSystem (Mock Data)
	print("Testing LootSystem...")
	var enemy_drop_table = {
		"loot_table": [
			{"item": sword_res, "chance": 1.0} # 100% chance
		]
	}
	LootSystem.drop_from_enemy(enemy_drop_table, inventory)
	assert(inventory.items.size() == 3, "Inventory should have 3 items after loot")
	
	# 4. Test EquipmentComponent Integration
	print("Testing EquipmentComponent integration...")
	var equipment_comp = EquipmentComponent.new()
	
	# Equip from inventory
	equipment_comp.equip_inventory_item(sword_item)
	
	assert(equipment_comp.equipped_items.has(EquipmentSlot.Type.MAIN_HAND), "Main hand should be equipped")
	assert(equipment_comp.equipped_instances.has(EquipmentSlot.Type.MAIN_HAND), "Main hand instance should be tracked")
	assert(equipment_comp.equipped_instances[EquipmentSlot.Type.MAIN_HAND] == sword_item, "Equipped instance should match inventory item")
	
	print("Equipped item: ", equipment_comp.equipped_items[EquipmentSlot.Type.MAIN_HAND].display_name)
	
	# Unequip
	equipment_comp.unequip(EquipmentSlot.Type.MAIN_HAND)
	assert(not equipment_comp.equipped_items.has(EquipmentSlot.Type.MAIN_HAND), "Main hand should be empty")
	assert(not equipment_comp.equipped_instances.has(EquipmentSlot.Type.MAIN_HAND), "Main hand instance should be cleared")
	
	print("Inventory System Test Passed!")
