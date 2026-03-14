class_name AvoidCriticalEffect
extends PassiveEffect

func execute(entity: Entity, data: Dictionary) -> void:
	var enemies = data.get("enemies", []) as Array
	for enemy in enemies:
		if enemy is Entity:
			var mod = StatModifier.new()
			mod.stat = StatTypes.CRIT_CHANCE
			mod.type = StatModifier.Type.FLAT
			mod.value = -20.0
			enemy.stats.add_modifier(mod, &"passive_avoid_critical")
	log_passive(entity, "Enemy crit -20%")

func cleanup(entity: Entity) -> void:
	entity.stats.remove_modifiers_from_source(&"passive_avoid_critical")
