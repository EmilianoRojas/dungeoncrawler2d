class_name SuperStrengthEffect
extends PassiveEffect

const BASELINE: float = 90.0
const MAX_BONUS: float = 0.50

func execute(entity: Entity, data: Dictionary) -> void:
	var skill = data.get("skill") as Skill
	if not skill or skill.hit_chance >= BASELINE:
		return
	var ratio = (BASELINE - skill.hit_chance) / BASELINE
	var bonus = int(data.get("damage", 0) * ratio * MAX_BONUS)
	if bonus > 0:
		data["damage"] = data.get("damage", 0) + bonus
		log_passive(entity, "+%d dmg (+%d%%, %d%% hit)" % [bonus, int(ratio * MAX_BONUS * 100), skill.hit_chance])
