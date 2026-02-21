class_name PassiveLibrary
extends Object

# Static registry of all 14 named passives from GameSpec §6.
# Each passive is a Dictionary with:
#   id: StringName, name: String, description: String,
#   trigger: String (event bus name), logic: String (handler key)

static var ALL_PASSIVES: Array[Dictionary] = [
	{
		"id": &"super_strength",
		"name": "Super-strength",
		"description": "Low accuracy skills deal +30% damage",
		"trigger": "pre_damage_calc",
		"logic": "super_strength"
	},
	{
		"id": &"hard_shield",
		"name": "Hard Shield",
		"description": "Reduce damage by 30% while shield > 0",
		"trigger": "pre_damage_apply",
		"logic": "hard_shield"
	},
	{
		"id": &"plating",
		"name": "Plating",
		"description": "+5 Defense (always active)",
		"trigger": "battle_start",
		"logic": "plating"
	},
	{
		"id": &"supply_route",
		"name": "Supply Route",
		"description": "Camp item CD -1 on Torch rooms",
		"trigger": "room_enter",
		"logic": "supply_route"
	},
	{
		"id": &"avoid_critical",
		"name": "Avoid Critical",
		"description": "Enemies have -20% crit chance against you",
		"trigger": "battle_start",
		"logic": "avoid_critical"
	},
	{
		"id": &"poisonous",
		"name": "Poisonous",
		"description": "+25% DoT damage",
		"trigger": "pre_damage_calc",
		"logic": "poisonous"
	},
	{
		"id": &"damage_reduce",
		"name": "Damage Reduce",
		"description": "Reduce incoming damage by 15%",
		"trigger": "pre_damage_apply",
		"logic": "damage_reduce"
	},
	{
		"id": &"technique",
		"name": "Technique",
		"description": "Crit chance increases with accuracy",
		"trigger": "battle_start",
		"logic": "technique"
	},
	{
		"id": &"counter",
		"name": "Counter",
		"description": "Reduce skill CDs by 1 when you take damage",
		"trigger": "damage_taken",
		"logic": "counter"
	},
	{
		"id": &"weaken",
		"name": "Weaken",
		"description": "Dealing damage reduces enemy power by 2",
		"trigger": "damage_dealt",
		"logic": "weaken"
	},
	{
		"id": &"sniping",
		"name": "Sniping",
		"description": "+50% crit damage multiplier",
		"trigger": "battle_start",
		"logic": "sniping"
	},
	{
		"id": &"swordmanship",
		"name": "Swordmanship",
		"description": "On parry, gain +15% STR for 5 turns",
		"trigger": "parry_success",
		"logic": "swordmanship"
	},
	{
		"id": &"first_strike",
		"name": "First Strike",
		"description": "50% chance to reduce all CDs by 1 at battle start",
		"trigger": "battle_start",
		"logic": "first_strike"
	},
	{
		"id": &"observation",
		"name": "Observation",
		"description": "See exact enemy HP and next action",
		"trigger": "battle_start",
		"logic": "observation"
	},
]

## Look up a passive by ID
static func get_passive(id: StringName) -> Dictionary:
	for p in ALL_PASSIVES:
		if p.id == id:
			return p
	return {}

## Get all passive IDs
static func get_all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for p in ALL_PASSIVES:
		ids.append(p.id)
	return ids
