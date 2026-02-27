class_name PassiveResolver
extends Node

# Passive Effects Resolver (GameSpec §6 + §8)
# Subscribes to GlobalEventBus events and executes matching passives
# for registered entities.

var _registered_entities: Array[Entity] = []

## Register an entity's passives to listen for events.
func register(entity: Entity) -> void:
	if _registered_entities.has(entity):
		return
	_registered_entities.append(entity)

## Unregister an entity.
func unregister(entity: Entity) -> void:
	_registered_entities.erase(entity)

## Unregister all entities.
func clear() -> void:
	_registered_entities.clear()

## Called by GameLoop on battle_start event.
func on_battle_start(data: Dictionary) -> void:
	for entity in _registered_entities:
		_resolve_for_entity(entity, "battle_start", data)

## Called on damage_dealt event (attacker perspective).
func on_damage_dealt(data: Dictionary) -> void:
	var source = data.get("source") as Entity
	if source and _registered_entities.has(source):
		_resolve_for_entity(source, "damage_dealt", data)

## Called on damage_taken event (defender perspective).
func on_damage_taken(data: Dictionary) -> void:
	var target = data.get("target") as Entity
	if target and _registered_entities.has(target):
		_resolve_for_entity(target, "damage_taken", data)

## Called on pre_damage_calc event (before damage formula).
func on_pre_damage_calc(data: Dictionary) -> void:
	var source = data.get("source") as Entity
	if source and _registered_entities.has(source):
		_resolve_for_entity(source, "pre_damage_calc", data)

## Called on pre_damage_apply event (before HP/Shield reduction).
func on_pre_damage_apply(data: Dictionary) -> void:
	var target = data.get("target") as Entity
	if target and _registered_entities.has(target):
		_resolve_for_entity(target, "pre_damage_apply", data)

## Called on parry_success event.
func on_parry_success(data: Dictionary) -> void:
	var target = data.get("target") as Entity
	if target and _registered_entities.has(target):
		_resolve_for_entity(target, "parry_success", data)

## Called on avoid_success event.
func on_avoid_success(data: Dictionary) -> void:
	var target = data.get("target") as Entity
	if target and _registered_entities.has(target):
		_resolve_for_entity(target, "avoid_success", data)

func _resolve_for_entity(entity: Entity, trigger: String, data: Dictionary) -> void:
	if not entity.passives:
		return
	
	# Check all active passives on this entity
	for passive_dict in entity.passives.active_passives:
		var passive_data = passive_dict.get("passive_info") as Dictionary
		if not passive_data or passive_data.is_empty():
			continue
		
		if passive_data.get("trigger", "") != trigger:
			continue
		
		var logic_key = passive_data.get("logic", "") as String
		_execute_passive(entity, logic_key, data)

## Execute a specific passive's logic.
func _execute_passive(entity: Entity, logic_key: String, data: Dictionary) -> void:
	match logic_key:
		"super_strength":
			_passive_super_strength(entity, data)
		"hard_shield":
			_passive_hard_shield(entity, data)
		"plating":
			_passive_plating(entity)
		"avoid_critical":
			_passive_avoid_critical(entity, data)
		"poisonous":
			_passive_poisonous(entity, data)
		"damage_reduce":
			_passive_damage_reduce(entity, data)
		"technique":
			_passive_technique(entity)
		"counter":
			_passive_counter(entity)
		"weaken":
			_passive_weaken(data)
		"sniping":
			_passive_sniping(entity)
		"swordmanship":
			_passive_swordmanship(entity)
		"first_strike":
			_passive_first_strike(entity)
		"observation":
			_passive_observation(data)
		"supply_route":
			pass # Handled outside combat

# --- PASSIVE IMPLEMENTATIONS ---

## Super-strength: Lower accuracy → higher damage bonus (linear scale)
## 90%+ hit = 0% bonus, 0% hit = 50% bonus max
const SUPER_STRENGTH_MAX_BONUS: float = 0.50
const SUPER_STRENGTH_BASELINE: float = 90.0 # Hit chance at which bonus is 0

func _passive_super_strength(entity: Entity, data: Dictionary) -> void:
	var skill = data.get("skill") as Skill
	if not skill or skill.hit_chance >= SUPER_STRENGTH_BASELINE:
		return
	
	var ratio = (SUPER_STRENGTH_BASELINE - skill.hit_chance) / SUPER_STRENGTH_BASELINE
	var bonus_percent = ratio * SUPER_STRENGTH_MAX_BONUS
	var bonus = int(data.get("damage", 0) * bonus_percent)
	if bonus > 0:
		data["damage"] = data.get("damage", 0) + bonus
		_log_passive(entity, "Super-strength", "+%d dmg (+%d%%, %d%% hit)" % [bonus, int(bonus_percent * 100), skill.hit_chance])

## Hard Shield: 30% damage reduce when shield > 0
func _passive_hard_shield(entity: Entity, data: Dictionary) -> void:
	var shield = entity.stats.get_current(StatTypes.SHIELD)
	if shield > 0:
		var reduction = int(data.get("damage", 0) * 0.30)
		data["damage"] = data.get("damage", 0) - reduction
		_log_passive(entity, "Hard Shield", "-%d dmg (shield active)" % reduction)

## Plating: +5 Defense (applied as stat modifier at battle start)
func _passive_plating(entity: Entity) -> void:
	var mod = StatModifier.new()
	mod.stat = StatTypes.DEFENSE
	mod.type = StatModifier.Type.FLAT
	mod.value = 5.0
	entity.stats.add_modifier(mod, &"passive_plating")
	_log_passive(entity, "Plating", "+5 Defense")

## Avoid Critical: -20 enemy crit chance (applied to enemy context)
func _passive_avoid_critical(entity: Entity, data: Dictionary) -> void:
	var enemies = data.get("enemies", []) as Array
	for enemy in enemies:
		if enemy is Entity:
			var mod = StatModifier.new()
			mod.stat = StatTypes.CRIT_CHANCE
			mod.type = StatModifier.Type.FLAT
			mod.value = -20.0
			enemy.stats.add_modifier(mod, &"passive_avoid_critical")
	_log_passive(entity, "Avoid Critical", "Enemy crit -20%")

## Poisonous: +25% DoT damage (boost damage if skill has on_hit DoT effects)
func _passive_poisonous(_entity: Entity, data: Dictionary) -> void:
	var skill = data.get("skill") as Skill
	if skill and skill.on_hit_effects.size() > 0:
		var bonus = int(data.get("damage", 0) * 0.25)
		data["damage"] = data.get("damage", 0) + bonus

## Damage Reduce: 15% incoming damage reduction
func _passive_damage_reduce(entity: Entity, data: Dictionary) -> void:
	var reduction = int(data.get("damage", 0) * 0.15)
	data["damage"] = data.get("damage", 0) - reduction
	_log_passive(entity, "Damage Reduce", "-%d dmg" % reduction)

## Technique: Add crit chance equal to accuracy * 0.5
func _passive_technique(entity: Entity) -> void:
	var accuracy = entity.stats.get_stat(StatTypes.ACCURACY)
	if accuracy > 0:
		var mod = StatModifier.new()
		mod.stat = StatTypes.CRIT_CHANCE
		mod.type = StatModifier.Type.FLAT
		mod.value = accuracy * 0.5
		entity.stats.add_modifier(mod, &"passive_technique")
		_log_passive(entity, "Technique", "+%d%% crit (from accuracy)" % int(accuracy * 0.5))

## Counter: Reduce all own CDs by 1 when taking damage
func _passive_counter(entity: Entity) -> void:
	if entity.skills:
		entity.skills.tick_cooldowns()
		_log_passive(entity, "Counter", "CDs reduced by 1")

## Weaken: Reduce target's power by 2 on damage dealt
func _passive_weaken(data: Dictionary) -> void:
	var target = data.get("target") as Entity
	if target and target.stats:
		var mod = StatModifier.new()
		mod.stat = StatTypes.POWER
		mod.type = StatModifier.Type.FLAT
		mod.value = -2.0
		target.stats.add_modifier(mod, &"passive_weaken")
		GlobalEventBus.dispatch("combat_log", {"message": "Weaken: Enemy power -2"})

## Sniping: +50% crit damage multiplier at battle start
func _passive_sniping(entity: Entity) -> void:
	var mod = StatModifier.new()
	mod.stat = StatTypes.CRIT_DAMAGE
	mod.type = StatModifier.Type.FLAT
	mod.value = 75.0 # +75 on a 150 base = 225 = 2.25x
	entity.stats.add_modifier(mod, &"passive_sniping")
	_log_passive(entity, "Sniping", "+50% crit damage")

## Swordmanship: On parry, gain +15% STR for 5 turns
func _passive_swordmanship(entity: Entity) -> void:
	var mod = StatModifier.new()
	mod.stat = StatTypes.STRENGTH
	mod.type = StatModifier.Type.PERCENT_ADD
	mod.value = 0.15
	mod.duration = 5
	entity.stats.add_modifier(mod, &"passive_swordmanship")
	_log_passive(entity, "Swordmanship", "Strengthen! +15% STR for 5 turns")

## First Strike: 50% chance to reduce all CDs by 1 at battle start
func _passive_first_strike(entity: Entity) -> void:
	if randf() < 0.50:
		if entity.skills:
			entity.skills.tick_cooldowns()
			_log_passive(entity, "First Strike", "All CDs -1!")

## Observation: Reveal enemy HP and next action
func _passive_observation(data: Dictionary) -> void:
	var enemies = data.get("enemies", []) as Array
	for enemy in enemies:
		if enemy is Entity:
			var hp = enemy.stats.get_current(StatTypes.HP)
			var max_hp = enemy.stats.get_stat(StatTypes.MAX_HP)
			var next_skill = ""
			if enemy.skills and enemy.skills.known_skills.size() > 0:
				next_skill = enemy.skills.known_skills[0].skill_name
			GlobalEventBus.dispatch("combat_log", {
				"message": "Observation: %s HP %d/%d, next: %s" % [enemy.name, hp, max_hp, next_skill]
			})

func _log_passive(entity: Entity, passive_name: String, detail: String) -> void:
	GlobalEventBus.dispatch("combat_log", {
		"message": "[%s] %s: %s" % [entity.name, passive_name, detail]
	})

## Clean up modifiers added by passives (called on battle end).
func cleanup_battle_modifiers(entity: Entity) -> void:
	entity.stats.remove_modifiers_from_source(&"passive_plating")
	entity.stats.remove_modifiers_from_source(&"passive_technique")
	entity.stats.remove_modifiers_from_source(&"passive_sniping")
	entity.stats.remove_modifiers_from_source(&"passive_swordmanship")
	entity.stats.remove_modifiers_from_source(&"passive_avoid_critical")
	entity.stats.remove_modifiers_from_source(&"passive_weaken")
