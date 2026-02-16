class_name StatsComponent
extends Resource

# Base stats (e.g., {StatTypes.STRENGTH: 10, StatTypes.MAX_HP: 100})
@export var base: Dictionary[StringName, int] = {}

# Bonus stats from equipment/buffs (e.g., {StatTypes.STRENGTH: 2})
var bonus: Dictionary[StringName, int] = {}

# Current temporary stats (e.g., {StatTypes.HP: 50})
var current: Dictionary[StringName, int] = {}

func finalize_initialization() -> void:
	initialize_from_base()

func initialize_from_base() -> void:
	current.clear()
	for key in base:
		current[key] = base[key]

const DEFAULTS = {
	StatTypes.HP: 10,
	StatTypes.MAX_HP: 10,
	StatTypes.STRENGTH: 5,
	StatTypes.SPEED: 5,
	StatTypes.DEFENSE: 0
}

func get_stat(stat_type: StringName) -> int:
	var base_val = base.get(stat_type, DEFAULTS.get(stat_type, 0))
	var bonus_val = bonus.get(stat_type, 0)
	return base_val + bonus_val

func get_current(stat_type: StringName) -> int:
	return current.get(stat_type, DEFAULTS.get(stat_type, 0))

func set_base_stat(stat_type: StringName, value: int) -> void:
	base[stat_type] = value

func add_bonus(stat_type: StringName, value: int) -> void:
	bonus[stat_type] = bonus.get(stat_type, 0) + value

func remove_bonus(stat_type: StringName, value: int) -> void:
	if bonus.has(stat_type):
		bonus[stat_type] -= value
		if bonus[stat_type] <= 0:
			bonus.erase(stat_type)

func modify_current(stat_type: StringName, amount: int) -> void:
	var current_val = current.get(stat_type, DEFAULTS.get(stat_type, 0))
	current[stat_type] = current_val + amount
	
	# Optional: Clamp logic if needed, e.g. HP vs MAX_HP
	if stat_type == StatTypes.HP:
		var max_hp = get_stat(StatTypes.MAX_HP)
		if max_hp > 0:
			current[stat_type] = clampi(current[stat_type], 0, max_hp)
