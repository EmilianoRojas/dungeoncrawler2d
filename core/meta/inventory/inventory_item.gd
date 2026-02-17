class_name InventoryItem
extends Resource

@export var equipment: EquipmentResource

var instance_id: StringName
var quantity: int = 1
var equipped_slot: StringName = ""

func _init(equipment_res: EquipmentResource = null):
	equipment = equipment_res
	# Generate a unique ID for this instance based on time and random value
	# Prefix "itm_" for clear identification
	instance_id = "itm_" + str(Time.get_ticks_usec()) + "_" + str(randi())

func is_equipped() -> bool:
	return equipped_slot != ""
