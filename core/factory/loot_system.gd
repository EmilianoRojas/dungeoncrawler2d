class_name LootSystem
extends Node

# This class handles loot generation logic.
# In a real game, this would likely be an Autoload or a Component on the GameLoop.
# For now, it provides static utility functions or can be instanced where needed.

# Assuming we might have an 'EnemyData' resource type in the future with a 'loot_table'.
# For now, we'll design the interface as requested.

# Generates loot from an enemy drop and adds it to the target inventory
static func drop_from_enemy(enemy_data: Dictionary, target_inventory: InventoryComponent) -> void:
    # enemy_data is a placeholder for the actual EnemyResource or similar
    # It is expected to have a 'loot_table' property which is an Array of Dictionaries
    # each containing { "item": EquipmentResource, "chance": float (0.0 to 1.0) }
    if not enemy_data.has("loot_table"):
        return
        
    for drop in enemy_data.loot_table:
        if randf() <= drop.chance:
            target_inventory.add_item(drop.item)
            print("Dropped item: %s" % drop.item.display_name)

# Generates loot from a chest and adds it to the target inventory
static func open_chest(chest_data: Dictionary, target_inventory: InventoryComponent) -> void:
    # chest_data is a placeholder
    # It is expected to have 'guaranteed_loot' (Array[EquipmentResource])
    # and potentially 'random_loot'
    if chest_data.has("guaranteed_loot"):
        for item_res in chest_data.guaranteed_loot:
            target_inventory.add_item(item_res)
            print("Looted from chest: %s" % item_res.display_name)
    
    # Add random loot logic here if needed
