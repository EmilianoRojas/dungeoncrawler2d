class_name Skill
extends Resource

enum ScalingType {
	FLAT,
	STAT_PERCENT
}

@export var skill_name: String = "Skill"

# Scaling
@export var scaling_type: ScalingType = ScalingType.STAT_PERCENT
@export var scaling_stat: StringName = StatTypes.STRENGTH
@export var scaling_percent: float = 1.0 # 1.0 = 100%
@export var on_cast_effects: Array[EffectResource] = [] # Self
@export var on_hit_effects: Array[EffectResource] = [] # Target
# Base
@export var base_power: int = 0
@export var max_cooldown: int = 0 # in turns

# Accuracy & Combat
@export var hit_chance: int = 90 # Percentage (0-100). 90 = 90% base hit
@export var ignores_shield: bool = false # Penetrating: bypasses Shield bar

# Skill type
@export var is_self_heal: bool = false # If true, heals the caster instead of damaging target
@export var is_observe: bool = false # If true, reveals enemy HP and next action

# Progression
@export var skill_level: int = 1 # Increases via Skill Draft upgrade (+10% damage per level)

# VFX
@export var impact_delay: float = 0.25  # seconds before damage applies
@export var vfx_color: Color = Color.WHITE  # cast animation tint
