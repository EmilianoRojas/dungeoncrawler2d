class_name PassiveResolver
extends Node

var _registered_entities: Array[Entity] = []

func register(entity: Entity) -> void:
	if not _registered_entities.has(entity):
		_registered_entities.append(entity)

func unregister(entity: Entity) -> void:
	_registered_entities.erase(entity)

func clear() -> void:
	_registered_entities.clear()

func on_battle_start(data: Dictionary) -> void:
	for entity in _registered_entities:
		if entity.passives:
			for entry in entity.passives.active_passives:
				var p = entry.get("passive") as PassiveEffect
				if p: p.cleanup(entity)
		_resolve_for_entity(entity, "battle_start", data)

func on_damage_dealt(data: Dictionary) -> void:
	var source = data.get("source") as Entity
	if source and _registered_entities.has(source):
		_resolve_for_entity(source, "damage_dealt", data)

func on_damage_taken(data: Dictionary) -> void:
	var target = data.get("target") as Entity
	if target and _registered_entities.has(target):
		_resolve_for_entity(target, "damage_taken", data)

func on_pre_damage_calc(data: Dictionary) -> void:
	var source = data.get("source") as Entity
	if source and _registered_entities.has(source):
		_resolve_for_entity(source, "pre_damage_calc", data)

func on_pre_damage_apply(data: Dictionary) -> void:
	var target = data.get("target") as Entity
	if target and _registered_entities.has(target):
		_resolve_for_entity(target, "pre_damage_apply", data)

func on_parry_success(data: Dictionary) -> void:
	var target = data.get("target") as Entity
	if target and _registered_entities.has(target):
		_resolve_for_entity(target, "parry_success", data)

func on_avoid_success(data: Dictionary) -> void:
	var target = data.get("entity") as Entity
	if target and _registered_entities.has(target):
		_resolve_for_entity(target, "avoid_success", data)

func on_skill_miss(data: Dictionary) -> void:
	var source = data.get("source") as Entity
	if source and _registered_entities.has(source):
		if source.passives:
			for entry in source.passives.active_passives:
				var p = entry.get("passive") as PassiveEffect
				if p: p.on_miss(source, data)

func cleanup_battle_modifiers(entity: Entity) -> void:
	if entity.passives:
		for entry in entity.passives.active_passives:
			var p = entry.get("passive") as PassiveEffect
			if p: p.cleanup(entity)

func _resolve_for_entity(entity: Entity, trigger: String, data: Dictionary) -> void:
	if not entity.passives: return
	for entry in entity.passives.active_passives:
		var p = entry.get("passive") as PassiveEffect
		if p and p.trigger == trigger:
			p.execute(entity, data)
