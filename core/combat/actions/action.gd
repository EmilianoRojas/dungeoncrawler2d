class_name Action
extends RefCounted

var source: Entity
var target: Entity
var priority: int = 0
var speed: int = 0

func _init(p_source: Entity, p_target: Entity) -> void:
	source = p_source
	target = p_target
	# Calculate total priority based on stats + skill priority
	# This can be overridden by subclasses
	if source and source.stats:
		speed = source.stats.get_stat("speed")

func execute() -> void:
	pass
