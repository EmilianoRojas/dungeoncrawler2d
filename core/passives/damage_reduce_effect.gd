class_name DamageReduceEffect
extends PassiveEffect

func execute(entity: Entity, data: Dictionary) -> void:
	var reduction = int(data.get("damage", 0) * 0.15)
	data["damage"] = data.get("damage", 0) - reduction
	log_passive(entity, "-%d dmg" % reduction)
