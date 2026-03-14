class_name PoisonousEffect
extends PassiveEffect

func execute(_entity: Entity, data: Dictionary) -> void:
	var skill = data.get("skill") as Skill
	if skill and skill.on_hit_effects.size() > 0:
		var bonus = int(data.get("damage", 0) * 0.25)
		data["damage"] = data.get("damage", 0) + bonus
