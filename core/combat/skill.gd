class_name Skill
extends Resource

enum ScalingType {
	FLAT,
	STAT_PERCENT
}

@export var skill_name: String = "Skill"

# Scaling
@export var scaling_type: ScalingType = ScalingType.STAT_PERCENT
@export var scaling_stat: StatsComponent.StatType = StatsComponent.StatType.STRENGTH
@export var scaling_percent: float = 1.0

# Base
@export var base_power: int = 0
@export var max_cooldown: int = 0 # in turns
