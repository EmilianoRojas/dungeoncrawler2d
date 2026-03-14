class_name HardShieldEffect
extends PassiveEffect

func execute(entity: Entity, data: Dictionary) -> void:
	if entity.stats.get_current(StatTypes.SHIELD) > 0:
		var reduction = int(data.get("damage", 0) * 0.30)
		data["damage"] = data.get("damage", 0) - reduction
		log_passive(entity, "-%d dmg (shield active)" % reduction)
