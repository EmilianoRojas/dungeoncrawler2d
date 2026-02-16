class_name InventoryItem
extends Resource

@export var equipment: EquipmentResource

var instance_id: StringName

func _init(equipment_res: EquipmentResource = null):
	equipment = equipment_res
	# Generate a unique ID for this instance based on time and random value
	instance_id = str(Time.get_ticks_usec()) + "_" + str(randi())
