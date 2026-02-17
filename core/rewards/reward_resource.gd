class_name RewardResource
extends Resource

enum Type {
	EQUIPMENT,
	SKILL,
	PASSIVE,
	STAT
}

@export var type: Type

# Content (One of these should be populated based on type)
@export var equipment: EquipmentResource
@export var skill: Skill
@export var effect: EffectResource
@export var stat_name: StringName
@export var value: float

# Metadata
@export var rarity: int = 1 # 1: Common, 2: Rare, etc.
@export var weight: float = 1.0 # For RNG generation
@export var tags: Array[String] = []

func get_display_name() -> String:
	match type:
		Type.EQUIPMENT:
			return equipment.display_name if equipment else "Unknown Item"
		Type.SKILL:
			return skill.skill_name if skill else "Unknown Skill"
		Type.PASSIVE:
			return effect.resource_name if effect else "Unknown Effect" # EffectResource might prompt for name
		Type.STAT:
			return "+%s %s" % [value, stat_name]
	return "Unknown Reward"
