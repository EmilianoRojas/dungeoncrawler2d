class_name EffectInstance
extends RefCounted

var resource: EffectResource
var stacks: int = 1
var remaining_turns: int = -1

func _init(p_resource: EffectResource):
    resource = p_resource
    remaining_turns = p_resource.duration_turns

func tick_duration():
    if remaining_turns == -1:
        return
    
    remaining_turns -= 1

func is_expired() -> bool:
    return remaining_turns == 0
