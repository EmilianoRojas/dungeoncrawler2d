class_name StatsComponent
extends Resource


enum StatType {
	HP,
	MAX_HP,
	STRENGTH,
	SPEED,
	DEFENSE
}

# Base stats (e.g., {StatType.STRENGTH: 10, StatType.MAX_HP: 100})
@export var base: Dictionary = {}

# Bonus stats from equipment/buffs (e.g., {StatType.STRENGTH: 2})
var bonus: Dictionary = {}

# Current temporary stats (e.g., {StatType.HP: 50})
var current: Dictionary = {}

func finalize_initialization() -> void:
	initialize_from_base()

func initialize_from_base() -> void:
	current.clear()
	for key in base:
		current[key] = base[key]

func get_stat(stat_type: StatType) -> int:
	var base_val = base.get(stat_type, 0)
	var bonus_val = bonus.get(stat_type, 0)
	return base_val + bonus_val

func set_base_stat(stat_type: StatType, value: int) -> void:
	base[stat_type] = value

func add_bonus(stat_type: StatType, value: int) -> void:
	bonus[stat_type] = bonus.get(stat_type, 0) + value

func remove_bonus(stat_type: StatType, value: int) -> void:
	if bonus.has(stat_type):
		bonus[stat_type] -= value
		if bonus[stat_type] <= 0:
			bonus.erase(stat_type)

static func get_stat_type_from_string(stat_name: String) -> int:
	match stat_name.to_lower():
		"hp": return StatType.HP
		"max_hp": return StatType.MAX_HP
		"strength": return StatType.STRENGTH
		"speed": return StatType.SPEED
		"defense": return StatType.DEFENSE
	return -1
