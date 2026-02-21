class_name StatsComponent
extends Resource

# Base stats (e.g., {StatTypes.STRENGTH: 10, StatTypes.MAX_HP: 100})
@export var base: Dictionary[StringName, int] = {}


# Bonus stats are now handled via `modifiers` dictionary below

# Current temporary stats (e.g., {StatTypes.HP: 50})
var current: Dictionary[StringName, int] = {}


# Stores arrays of StatModifierInstance per stat key
var modifiers: Dictionary = {} # StringName -> Array[StatModifierInstance]

func finalize_initialization() -> void:
	initialize_from_base()

func initialize_from_base() -> void:
	current.clear()
	for key in base:
		current[key] = base[key]
	# Fill resource bars from their max values
	if base.has(StatTypes.MAX_SHIELD) and not base.has(StatTypes.SHIELD):
		current[StatTypes.SHIELD] = base[StatTypes.MAX_SHIELD]

const DEFAULTS = {
	StatTypes.HP: 10,
	StatTypes.MAX_HP: 10,
	StatTypes.STRENGTH: 5,
	StatTypes.DEXTERITY: 5,
	StatTypes.INTELLIGENCE: 5,
	StatTypes.PIETY: 5,
	StatTypes.POWER: 0,
	StatTypes.SPEED: 5,
	StatTypes.DEFENSE: 0,
	StatTypes.SHIELD: 0,
	StatTypes.MAX_SHIELD: 0,
	StatTypes.CRIT_CHANCE: 5, # 5% base crit
	StatTypes.CRIT_DAMAGE: 150, # 1.5x crit multiplier
	StatTypes.PARRY_CHANCE: 0,
	StatTypes.AVOID_CHANCE: 0,
	StatTypes.ACCURACY: 0,
}

# --- Core Calculation Logic ---

func get_stat(stat_type: StringName) -> int:
	var base_val = base.get(stat_type, DEFAULTS.get(stat_type, 0))
	
	var flat = 0.0
	var percent_add = 0.0
	var mult = 1.0
	
	if modifiers.has(stat_type):
		for mod_instance in modifiers[stat_type]:
			var mod = mod_instance.resource
			match mod.type:
				StatModifier.Type.FLAT:
					flat += mod.value
				StatModifier.Type.PERCENT_ADD:
					percent_add += mod.value
				StatModifier.Type.MULTIPLIER:
					mult *= mod.value
	
	# Formula: (Base + Flat) * (1 + %Add) * Mult
	var result = (base_val + flat)
	result *= (1.0 + percent_add)
	result *= mult
	
	return int(result)

func get_current(stat_type: StringName) -> int:
	return current.get(stat_type, DEFAULTS.get(stat_type, 0))

func set_base_stat(stat_type: StringName, value: int) -> void:
	base[stat_type] = value

# --- Modifier Management ---

func add_modifier(mod: StatModifier, source_id_override: StringName = "") -> void:
	if not modifiers.has(mod.stat):
		modifiers[mod.stat] = []
	
	# Create runtime instance
	var instance = StatModifierInstance.new(mod, source_id_override)
	
	modifiers[mod.stat].append(instance)
	
	# If this adds MAX_SHIELD, fill current shield to the new max
	if mod.stat == StatTypes.MAX_SHIELD:
		var new_max = get_stat(StatTypes.MAX_SHIELD)
		current[StatTypes.SHIELD] = new_max

func remove_modifiers_from_source(source_id: StringName) -> void:
	for stat in modifiers:
		var list = modifiers[stat]
		var new_list: Array[StatModifierInstance] = []
		
		for mod in list:
			if mod.source_id != source_id:
				new_list.append(mod)
		
		modifiers[stat] = new_list

func tick_modifiers() -> void:
	for stat in modifiers:
		var list = modifiers[stat]
		var new_list: Array[StatModifierInstance] = []
		
		for mod in list:
			if mod.remaining_turns > 0:
				mod.remaining_turns -= 1
			
			# Keep infinite (-1) or non-expired (>0 after decrement)
			if mod.remaining_turns != 0:
				new_list.append(mod)
		
		modifiers[stat] = new_list

# --- Current Value Modification ---

func modify_current(stat_type: StringName, amount: int) -> void:
	var current_val = current.get(stat_type, DEFAULTS.get(stat_type, 0))
	current[stat_type] = current_val + amount
	
	# Clamp logic
	if stat_type == StatTypes.HP:
		var max_hp = get_stat(StatTypes.MAX_HP)
		if max_hp > 0:
			current[stat_type] = clampi(current[stat_type], 0, max_hp)
	elif stat_type == StatTypes.SHIELD:
		var max_shield = get_stat(StatTypes.MAX_SHIELD)
		if max_shield > 0:
			current[stat_type] = clampi(current[stat_type], 0, max_shield)

# Restore shield to 100% after battle (GameSpec rule)
func reset_shield() -> void:
	var max_shield = get_stat(StatTypes.MAX_SHIELD)
	current[StatTypes.SHIELD] = max_shield
