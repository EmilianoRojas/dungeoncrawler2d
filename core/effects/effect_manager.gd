class_name EffectManager
extends Node

var effects: Array[Effect] = []
var owner_entity: Node

func _init(p_owner: Node) -> void:
	owner_entity = p_owner

func add_effect(effect: Effect) -> void:
	# Duplicate the resource so each entity has its own instance of the effect state if needed
	# usage: entity.effects.add_effect(preload("res://data/effects/Lifesteal.tres").duplicate())
	effects.append(effect)

func remove_effect(effect: Effect) -> void:
	effects.erase(effect)

func dispatch(event_name: String, data: Dictionary) -> void:
	# Sort by priority descending (higher first)
	effects.sort_custom(func(a, b): return a.priority > b.priority)
	
	for effect in effects:
		effect.on_event(event_name, data)
