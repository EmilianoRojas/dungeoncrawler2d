class_name DivineRetributionEffect
extends PassiveEffect

func execute(entity: Entity, data: Dictionary) -> void:
	var source = data.get("source") as Entity
	if not source or source == entity:
		return
	var incoming = data.get("damage", 0)
	if incoming <= 0:
		return
	var retaliation = max(1, int(incoming * 0.30))
	source.stats.modify_current(StatTypes.HP, -retaliation)
	log_passive(entity, "%d reflected to %s" % [retaliation, source.name])
	GlobalEventBus.dispatch("combat_log", {
		"message": "[color=gold]⚔ Divine Retribution[/color]: %s reflects %d to %s" % [entity.name, retaliation, source.name]
	})
