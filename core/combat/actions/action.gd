class_name Action
extends RefCounted

var source: Node
var target: Node
var priority: int = 0
var speed: int = 0
var _tiebreaker: float = 0.0

func _init(p_source: Node, p_target: Node) -> void:
	source = p_source
	target = p_target
	var source_entity = source
	if source_entity and source_entity.get("stats"):
		speed = source_entity.stats.get_stat(StatTypes.SPEED)
	_tiebreaker = randf()

func execute() -> void:
	pass
