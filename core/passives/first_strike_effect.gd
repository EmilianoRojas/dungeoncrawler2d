class_name FirstStrikeEffect
extends PassiveEffect

func execute(entity: Entity, _data: Dictionary) -> void:
	if randf() < 0.50:
		if entity.skills:
			entity.skills.tick_cooldowns()
			log_passive(entity, "All CDs -1!")
