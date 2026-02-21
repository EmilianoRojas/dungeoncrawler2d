class_name FormulaCalculator
extends Object

static func calculate_damage(skill: Skill, source: Entity) -> int:
	var base_damage: int = 0
	
	match skill.scaling_type:
		Skill.ScalingType.FLAT:
			base_damage = skill.base_power

		Skill.ScalingType.STAT_PERCENT:
			var stat_value = 0
			if source.stats:
				stat_value = source.stats.get_stat(skill.scaling_stat)
			base_damage = int(stat_value * skill.scaling_percent) + skill.base_power
	
	# POW contributes to ALL skills (GameSpec §3)
	if source.stats:
		base_damage += source.stats.get_stat(StatTypes.POWER)
	
	# Skill level scaling: +10% per level above 1 (GameSpec §4)
	if skill.skill_level > 1:
		base_damage = int(base_damage * (1.0 + (skill.skill_level - 1) * 0.10))
	
	return base_damage
