class_name SnipingEffect
extends PassiveEffect

func execute(entity: Entity, _data: Dictionary) -> void:
	var mod = StatModifier.new()
	mod.stat = StatTypes.CRIT_DAMAGE
	mod.type = StatModifier.Type.FLAT
	mod.value = 75.0
	entity.stats.add_modifier(mod, &"passive_sniping")
	log_passive(entity, "+50% crit damage")

func cleanup(entity: Entity) -> void:
	entity.stats.remove_modifiers_from_source(&"passive_sniping")
