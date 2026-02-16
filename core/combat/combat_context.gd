class_name CombatContext
extends RefCounted

var source: Entity
var target: Entity
var skill: Skill
# Optional source ID override for stat modifiers
var custom_source_id: StringName = ""

var damage: int = 0

var is_crit: bool = false
var is_kill: bool = false
var heal_amount: int = 0
var context_data: Dictionary = {}
var ignore_defense: bool = false
var stored_damage: int = 0
var effect_instance: EffectInstance = null # If triggered by an effect

# Optional/Extra data
var raw_data: Dictionary = {}

func _init(p_source: Entity = null, p_target: Entity = null, p_skill: Skill = null):
	source = p_source
	target = p_target
	skill = p_skill
