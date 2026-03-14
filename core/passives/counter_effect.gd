class_name CounterEffect
extends PassiveEffect

func execute(entity: Entity, _data: Dictionary) -> void:
	if entity.skills:
		entity.skills.tick_cooldowns()
		log_passive(entity, "CDs reduced by 1")
