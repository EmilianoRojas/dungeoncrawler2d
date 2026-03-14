class_name PlatingEffect
extends PassiveEffect

func execute(entity: Entity, _data: Dictionary) -> void:
	var mod = StatModifier.new()
	mod.stat = StatTypes.DEFENSE
	mod.type = StatModifier.Type.FLAT
	mod.value = 5.0
	entity.stats.add_modifier(mod, &"passive_plating")
	log_passive(entity, "+5 Defense")

func cleanup(entity: Entity) -> void:
	entity.stats.remove_modifiers_from_source(&"passive_plating")
