class_name EquipmentResource
extends Resource

@export var id: StringName
@export var display_name: String
@export var slot: EquipmentSlot.Type

# A) Stat Modifiers (Applied once on equip)
@export var equip_effects: Array[EffectResource]

# B) Granted Skills (Added to SkillComponent)
@export var granted_skills: Array[Skill]

# C) Passive Effects (Auras/Triggers, active while equipped)
@export var passive_effects: Array[EffectResource]
