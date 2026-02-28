class_name RuneResource
extends Resource

enum Tier { COMMON, RARE, LEGENDARY }

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var tier: Tier = Tier.COMMON
var stat_bonuses: Dictionary = {}  # StringName -> int
@export var passive_id: StringName = &""
