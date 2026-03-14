class_name PassiveEffectComponent
extends Node

var active_passives: Array[Dictionary] = []

func add_passive(passive: PassiveEffect, source_id: StringName) -> void:
	if not passive: return
	active_passives.append({"passive": passive, "source": source_id})
	print("Passive added: %s from %s" % [passive.passive_name, source_id])

func remove_from_source(source_id: StringName) -> void:
	active_passives = active_passives.filter(func(p): return p.source != source_id)

func find_passive(passive_id: StringName) -> PassiveEffect:
	for entry in active_passives:
		var p = entry.get("passive") as PassiveEffect
		if p and p.id == passive_id:
			return p
	return null

func get_passives_by_trigger(trigger: String) -> Array[PassiveEffect]:
	var result: Array[PassiveEffect] = []
	for entry in active_passives:
		var p = entry.get("passive") as PassiveEffect
		if p and p.trigger == trigger:
			result.append(p)
	return result
