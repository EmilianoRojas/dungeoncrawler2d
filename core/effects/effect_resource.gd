class_name EffectResource
extends Resource

@export var effect_id: StringName = "" # e.g. "lifesteal", "burn"

enum Trigger {
	# --- SKILL FLOW ---
	ON_SKILL_CAST,

	# --- DAMAGE PIPELINE ---
	ON_PRE_DAMAGE_CALC,        # before base calculation
	ON_DAMAGE_CALCULATED,      # after base damage (attacker phase)
	ON_DAMAGE_RECEIVED_CALC,   # defender phase
	ON_PRE_DAMAGE_APPLY,       # final adjustments

	# --- AFTER APPLY ---
	ON_DAMAGE_DEALT,
	ON_DAMAGE_TAKEN,

	# --- RESULT EVENTS ---
	ON_KILL,
	ON_DEATH,
	ON_HEAL_RECEIVED,
	
	# --- TURN EVENTS ---
	ON_TURN_START,
	ON_TURN_END
}

enum Operation {
	# Offensive
	ADD_DAMAGE,
	ADD_DAMAGE_PERCENT,
	MULTIPLY_DAMAGE,
	SET_DAMAGE,

	# Defensive
	REDUCE_DAMAGE_FLAT,
	REDUCE_DAMAGE_PERCENT,
	ABSORB_DAMAGE,

	# Clamps
	CLAMP_MIN_DAMAGE,
	CLAMP_MAX_DAMAGE,

	# Special
	CONVERT_TO_TRUE_DAMAGE,
	STORE_DAMAGE,
	
	# Stat Modifiers
	ADD_STAT_MODIFIER
}

@export var trigger: Trigger
@export var operation: Operation

# For ADD_STAT_MODIFIER
@export var stat_modifier: StatModifier

@export var value: float = 0.0
@export var stat_type: StringName = ""
@export var proc_chance: float = 1.0 # 0.0 to 1.0
@export var conditions: Array[EffectCondition] = []

enum StackRule {
	ADD,        # Sum stacks, refresh duration
	REFRESH,    # Refresh duration only
	REPLACE,    # Replace entire instance
	IGNORE      # Do nothing if exists
}

@export var stack_rule: StackRule = StackRule.ADD
@export var max_stacks: int = 99
@export var duration_turns: int = -1 # -1 = infinite, >0 = finite turns
