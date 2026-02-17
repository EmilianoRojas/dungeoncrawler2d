class_name InventoryComponent
extends Node

# Emitted when an item is added
signal item_added(item: InventoryItem)
# Emitted when an item is removed
signal item_removed(item: InventoryItem)

# The list of items currently in the inventory
var items: Array[InventoryItem] = []

@export var max_slots: int = 20

# Adds a new item based on an EquipmentResource definition
# Returns the created item, or null if inventory is full
func add_item(equipment_res: EquipmentResource) -> InventoryItem:
	if items.size() >= max_slots:
		return null
		
	var item = InventoryItem.new(equipment_res)
	items.append(item)
	item_added.emit(item)
	return item

# Adds an existing InventoryItem instance (e.g. from a save or trade)
func add_existing_item(item: InventoryItem) -> void:
	if items.size() >= max_slots:
		return
		
	if not item in items:
		items.append(item)
		item_added.emit(item)

# Removes an item instance
func remove_item(item: InventoryItem) -> void:
	if item in items:
		items.erase(item)
		item_removed.emit(item)

# Returns all items that match a specific equipment slot
func get_equippable_items(slot: EquipmentSlot.Type) -> Array[InventoryItem]:
	var result: Array[InventoryItem] = []
	for item in items:
		if item.equipment and item.equipment.slot == slot:
			result.append(item)
	return result

# Returns the total number of items
func get_item_count() -> int:
	return items.size()
