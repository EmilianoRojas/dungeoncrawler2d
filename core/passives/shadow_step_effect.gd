class_name ShadowStepEffect
extends PassiveEffect

func execute(entity: Entity, _data: Dictionary) -> void:
	var state = get_state(entity)
	state["ready"] = true
	set_state(entity, state)
	log_passive(entity, "Dodge! Next attack: +80% dmg, guaranteed hit")

func consume(entity: Entity, data: Dictionary) -> bool:
	var state = get_state(entity)
	if not state.get("ready", false):
		return false
	state["ready"] = false
	set_state(entity, state)
	var bonus = int(data.get("damage", 0) * 0.8)
	data["damage"] = data.get("damage", 0) + bonus
	data["force_hit"] = true
	log_passive(entity, "+%d dmg (guaranteed hit consumed)" % bonus)
	return true
