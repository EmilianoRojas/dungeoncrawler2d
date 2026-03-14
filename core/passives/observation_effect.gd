class_name ObservationEffect
extends PassiveEffect

func execute(_entity: Entity, data: Dictionary) -> void:
	var enemies = data.get("enemies", []) as Array
	for enemy in enemies:
		if enemy is Entity:
			var hp = enemy.stats.get_current(StatTypes.HP)
			var max_hp = enemy.stats.get_stat(StatTypes.MAX_HP)
			var next_skill = ""
			if enemy.skills and enemy.skills.known_skills.size() > 0:
				next_skill = enemy.skills.known_skills[0].skill_name
			GlobalEventBus.dispatch("combat_log", {
				"message": "Observation: %s HP %d/%d, next: %s" % [enemy.name, hp, max_hp, next_skill]
			})
