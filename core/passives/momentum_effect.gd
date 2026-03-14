class_name MomentumEffect
extends PassiveEffect

func execute(entity: Entity, data: Dictionary) -> void:
	var state = get_state(entity)
	var stacks = mini(state.get("stacks", 0) + 1, 5)
	var bonus = int(data.get("damage", 0) * (stacks * 0.05))
	data["damage"] = data.get("damage", 0) + bonus
	state["stacks"] = stacks
	set_state(entity, state)
	log_passive(entity, "+%d dmg (stack %d/5)" % [bonus, stacks])

func on_miss(entity: Entity, _data: Dictionary) -> void:
	var state = get_state(entity)
	if state.get("stacks", 0) > 0:
		state["stacks"] = 0
		set_state(entity, state)
		log_passive(entity, "Streak broken — reset to 0")
