class_name StatModifierInstance
extends RefCounted

var resource: StatModifier
var remaining_turns: int
var source_id: StringName

func _init(res: StatModifier, _source_id_override: StringName = ""):
	resource = res
	remaining_turns = res.duration_turns
	
	# Use override if provided, else use resource default
	if _source_id_override != "":
		source_id = _source_id_override
	else:
		source_id = res.source_id
