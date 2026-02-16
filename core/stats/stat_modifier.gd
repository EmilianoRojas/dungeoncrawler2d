class_name StatModifier
extends Resource

enum Type {
	FLAT,        # +10
	PERCENT_ADD, # +20% (additive percentage)
	MULTIPLIER   # x1.5 (multiplicative)
}

@export var stat: StringName
@export var type: Type = Type.FLAT
@export var value: float = 0.0

# Optional metadata
@export var source_id: StringName = ""
@export var duration_turns: int = -1 # -1 for infinite (permanent until removed), >0 for temporary
