class_name EffectResource
extends Resource

@export var effect_id: StringName = "" # e.g. "lifesteal", "burn"

enum Trigger {
	ON_DAMAGE_DEALT,
	ON_DAMAGE_TAKEN,
	ON_TURN_START,
	ON_TURN_END,
	ON_DEATH,
	ON_CRIT,
	ON_KILL,
	ON_SKILL_CAST,
	ON_HEAL_RECEIVED
}

enum Operation {
	HEAL_PERCENT,
	HEAL_FLAT,
	MODIFY_STAT_PERCENT,
	MODIFY_STAT_FLAT,
	DEAL_DAMAGE_PERCENT_BACK
}

@export var trigger: Trigger
@export var operation: Operation

@export var value: float = 0.0
@export var stat_type: int = -1
@export var proc_chance: float = 1.0 # 0.0 to 1.0

enum StackRule {
	ADD,        # Sum stacks, refresh duration
	REFRESH,    # Refresh duration only
	REPLACE,    # Replace entire instance
	IGNORE      # Do nothing if exists
}

@export var stack_rule: StackRule = StackRule.ADD
@export var max_stacks: int = 99
@export var duration_turns: int = -1 # -1 = infinite, >0 = finite turns
