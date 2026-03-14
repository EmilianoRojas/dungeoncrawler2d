class_name PassiveEffect
extends Resource

@export var id: StringName = &""
@export var passive_name: String = ""
@export var description: String = ""
@export var trigger: String = ""

func execute(entity: Entity, data: Dictionary) -> void:
	pass

func cleanup(entity: Entity) -> void:
	pass

func on_miss(entity: Entity, data: Dictionary) -> void:
	pass

func consume(entity: Entity, data: Dictionary) -> bool:
	return false

func get_state(entity: Entity) -> Dictionary:
	if not entity.passive_state.has(id):
		entity.passive_state[id] = {}
	return entity.passive_state[id]

func set_state(entity: Entity, state: Dictionary) -> void:
	entity.passive_state[id] = state

func log_passive(entity: Entity, detail: String) -> void:
	GlobalEventBus.dispatch("combat_log", {
		"message": "[%s] %s: %s" % [entity.name, passive_name, detail]
	})
