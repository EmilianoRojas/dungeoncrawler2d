class_name PassiveEffectComponent
extends Node

# Structure:
# {
#   "effect": EffectResource,
#   "source": source_id,
#   "instance": EffectInstance (optional, if we track state/stacks per passive)
# }
var active_passives: Array[Dictionary] = []

func add_passive(effect: EffectResource, source_id: StringName, passive_info: Dictionary = {}) -> void:
	if not effect and passive_info.is_empty(): return
	
	active_passives.append({
		"effect": effect,
		"source": source_id,
		"passive_info": passive_info
	})
	
	var label = ""
	if not passive_info.is_empty():
		label = str(passive_info.get("name", "Effect"))
	elif effect and "effect_id" in effect:
		label = str(effect.effect_id)
	else:
		label = "Effect"
	print("Passive added: %s from %s" % [label, source_id])

func remove_from_source(source_id: StringName) -> void:
	var new_list: Array[Dictionary] = []
	for p in active_passives:
		if p.source != source_id:
			new_list.append(p)
	active_passives = new_list

func get_passives_by_trigger(trigger: EffectResource.Trigger) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for p in active_passives:
		var eff = p.effect as EffectResource
		if eff and eff.trigger == trigger:
			result.append(p)
	return result
