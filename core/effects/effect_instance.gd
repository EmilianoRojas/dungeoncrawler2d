class_name EffectInstance
extends RefCounted

var resource: EffectResource
var stacks: int = 1
var remaining_turns: int = -1
## Entity that applied this effect (used for caster-stat scaling, e.g. toxin_mastery DoT boost)
var caster: Entity = null

func _init(p_resource: EffectResource, p_caster: Entity = null):
	resource = p_resource
	remaining_turns = p_resource.duration_turns
	caster = p_caster

func tick_duration():
	if remaining_turns == -1:
		return
	remaining_turns -= 1

func is_expired() -> bool:
	return remaining_turns == 0
