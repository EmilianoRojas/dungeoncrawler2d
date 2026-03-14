class_name TechniqueEffect
extends PassiveEffect

func execute(entity: Entity, _data: Dictionary) -> void:
	var accuracy = entity.stats.get_stat(StatTypes.ACCURACY)
	if accuracy > 0:
		var mod = StatModifier.new()
		mod.stat = StatTypes.CRIT_CHANCE
		mod.type = StatModifier.Type.FLAT
		mod.value = accuracy * 0.5
		entity.stats.add_modifier(mod, &"passive_technique")
		log_passive(entity, "+%d%% crit (from accuracy)" % int(accuracy * 0.5))

func cleanup(entity: Entity) -> void:
	entity.stats.remove_modifiers_from_source(&"passive_technique")
