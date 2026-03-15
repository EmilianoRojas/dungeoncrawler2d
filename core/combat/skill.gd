class_name Skill
extends Resource

enum ScalingType {
	FLAT,
	STAT_PERCENT
}

enum SkillType {
	DAMAGE,
	HEAL,
	BUFF,
	DEBUFF,
	DOT,
	UTILITY
}

@export var skill_name: String = "Skill"
@export var skill_type: SkillType = SkillType.DAMAGE

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
@export var icon: Texture2D
@export var vfx_spritesheet: Texture2D          # spritesheet PNG
@export var vfx_frame_size: Vector2i = Vector2i(64, 64)  # size of each frame
@export var vfx_fps: float = 12.0               # playback speed
@export var vfx_impact_frame: int = 0           # frame at which damage/buff applies
@export var vfx_on_target: bool = true          # true = plays on target, false = on caster
@export var vfx_color: Color = Color.WHITE      # tint (used for flash fallback)

# Derived: impact delay in seconds (auto-calculated from vfx_impact_frame / vfx_fps)
func get_impact_delay() -> float:
	if vfx_fps > 0.0:
		return vfx_impact_frame / vfx_fps
	return 0.0
