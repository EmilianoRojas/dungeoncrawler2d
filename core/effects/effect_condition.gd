class_name EffectCondition
extends Resource

enum Type {
    HP_PERCENT_BELOW,
    HP_PERCENT_ABOVE,
    HAS_EFFECT_ID,
    IS_CRIT,
    IS_KILL,
    CHANCE # Alternative to built-in proc_chance if we want multi-condition logic
}

enum TargetType {
    SELF,
    TARGET
}

@export var type: Type
@export var target: TargetType = TargetType.TARGET

@export var value: float = 0.0 # For numerical comparisons (e.g. 0.5 for 50%)
@export var string_value: StringName = "" # For ID checks (e.g. "poison")
