class_name SwordmanshipEffect
extends PassiveEffect

func execute(entity: Entity, _data: Dictionary) -> void:
	var mod = StatModifier.new()
	mod.stat = StatTypes.STRENGTH
	mod.type = StatModifier.Type.PERCENT_ADD
	mod.value = 0.15
	mod.duration = 5
	entity.stats.add_modifier(mod, &"passive_swordmanship")
	log_passive(entity, "Strengthen! +15% STR for 5 turns")

func cleanup(entity: Entity) -> void:
	entity.stats.remove_modifiers_from_source(&"passive_swordmanship")
