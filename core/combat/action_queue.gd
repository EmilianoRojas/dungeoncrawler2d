class_name ActionQueue
extends Node

var queue: Array[Action] = []

func add_action(action: Action) -> void:
	queue.append(action)
	# Sort: Higher speed/priority goes FIRST (index 0)
	queue.sort_custom(func(a, b):
		# Primary: Priority (For forced first actions)
		if a.priority != b.priority:
			return a.priority > b.priority
		# Secondary: Speed
		return a.speed > b.speed
	)

func peek_next() -> Action:
	if queue.is_empty(): return null
	return queue[0]

func has_actions() -> bool:
	return not queue.is_empty()

func process_next() -> void:
	if queue.is_empty():
		return
		
	var action = queue.pop_front()
	action.execute()

func clear() -> void:
	queue.clear()
