class_name WeakenEffect
extends PassiveEffect

func execute(_entity: Entity, data: Dictionary) -> void:
	var target = data.get("target") as Entity
	if target and target.stats:
		var mod = StatModifier.new()
		mod.stat = StatTypes.POWER
		mod.type = StatModifier.Type.FLAT
		mod.value = -2.0
		target.stats.add_modifier(mod, &"passive_weaken")
		GlobalEventBus.dispatch("combat_log", {"message": "Weaken: Enemy power -2"})
