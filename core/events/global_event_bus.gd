extends Node

# Signal for all game events (for generic listeners)
signal game_event(event_name: String, data: Dictionary)

# Dictionary to map event names to arrays of Callables
var _listeners: Dictionary = {}

func dispatch(event_name: String, data: Dictionary = {}) -> void:
	# 1. Emit generic signal
	game_event.emit(event_name, data)
	
	# 2. Notify specific subscribers
	if _listeners.has(event_name):
		# Debug for damage_dealt
		if event_name == "damage_dealt":
			print("GlobalEventBus: Dispatching 'damage_dealt'. Listener count: %d" % _listeners[event_name].size())
			
		for callback in _listeners[event_name]:
			if callback.is_valid():
				callback.call(data)
			else:
				pass

func subscribe(event_name: String, callback: Callable) -> void:
	if not _listeners.has(event_name):
		_listeners[event_name] = []
	
	if not _listeners[event_name].has(callback):
		_listeners[event_name].append(callback)
		print("GlobalEventBus: Subscribed to '%s'. Total: %d" % [event_name, _listeners[event_name].size()])
	else:
		print("GlobalEventBus: Duplicate subscription attempt for '%s'" % event_name)

func unsubscribe(event_name: String, callback: Callable) -> void:
	if _listeners.has(event_name):
		_listeners[event_name].erase(callback)

func reset() -> void:
	print("GlobalEventBus: Resetting all listeners.")
	_listeners.clear()
