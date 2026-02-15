class_name FormulaCalculator
extends Object

static func calculate_damage(skill: Skill, source: Entity) -> int:
	match skill.scaling_type:
		Skill.ScalingType.FLAT:
			return skill.base_power

		Skill.ScalingType.STAT_PERCENT:
			var stat_value = 0
			if source.stats:
				stat_value = source.stats.get_stat(skill.scaling_stat)
			return int(stat_value * skill.scaling_percent) + skill.base_power

	return 0
