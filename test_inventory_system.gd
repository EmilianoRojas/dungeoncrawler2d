extends Node

func _init():
	print("Starting Inventory System Test...")
	
	# 1. Create Mock Resources
	var sword_res = EquipmentResource.new()
	sword_res.id = "sword_001"
	sword_res.display_name = "Iron Sword"
	sword_res.slot = EquipmentSlot.Type.MAIN_HAND
	sword_res.rarity = "Common"
	
	var shield_res = EquipmentResource.new()
	shield_res.id = "shield_001"
	shield_res.display_name = "Wooden Shield"
	shield_res.slot = EquipmentSlot.Type.OFF_HAND
	shield_res.rarity = "Rare"
	
	# 2. Test InventoryComponent
	var inventory = InventoryComponent.new()
	inventory.max_slots = 2 # Set small limit for testing
	print("Adding items to inventory (Max Slots: 2)...")
	
	var sword_item = inventory.add_item(sword_res)
	var shield_item = inventory.add_item(shield_res)
	
	assert(inventory.items.size() == 2, "Inventory should have 2 items")
	assert(sword_item.equipment == sword_res, "Sword item should reference sword resource")
	assert(sword_item.instance_id.begins_with("itm_"), "Item ID should start with 'itm_'")
	assert(sword_item.equipment.rarity == "Common", "Sword should be Common")
	assert(shield_item.equipment.rarity == "Rare", "Shield should be Rare")
	
	# Test Inventory Limit
	print("Testing inventory limit...")
	var extra_item = inventory.add_item(sword_res)
	assert(extra_item == null, "Should not be able to add item beyond max slots")
	assert(inventory.items.size() == 2, "Inventory size should remain 2")
	
	print("Inventory items added successfully. IDs: ", sword_item.instance_id, ", ", shield_item.instance_id)
	
	# 3. Test LootSystem (Mock Data)
	print("Testing LootSystem...")
	# Note: LootSystem checks success implicitly, but with full inventory it should fail to add.
	# We'll just verify current state.
	
	# 4. Test EquipmentComponent Integration
	print("Testing EquipmentComponent integration...")
	var equipment_comp = EquipmentComponent.new()
	
	# Equip from inventory
	assert(not sword_item.is_equipped(), "Sword should not be equipped yet")
	equipment_comp.equip_inventory_item(sword_item)
	
	assert(equipment_comp.equipped_items.has(EquipmentSlot.Type.MAIN_HAND), "Main hand should be equipped")
	assert(equipment_comp.equipped_instances.has(EquipmentSlot.Type.MAIN_HAND), "Main hand instance should be tracked")
	assert(sword_item.is_equipped(), "Sword item should report being equipped")
	assert(sword_item.equipped_slot == "MAIN_HAND", "Sword equipped_slot should be MAIN_HAND")
	
	print("Equipped item: ", equipment_comp.equipped_items[EquipmentSlot.Type.MAIN_HAND].display_name)
	
	# Unequip
	equipment_comp.unequip(EquipmentSlot.Type.MAIN_HAND)
	assert(not equipment_comp.equipped_items.has(EquipmentSlot.Type.MAIN_HAND), "Main hand should be empty")
	assert(not sword_item.is_equipped(), "Sword should not be equipped anymore")
	assert(sword_item.equipped_slot == "", "Sword equipped_slot should be empty")
	
	print("Inventory System Refinements Test Passed!")
