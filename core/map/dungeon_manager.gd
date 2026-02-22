class_name DungeonManager
extends Node

signal room_changed(new_room: MapNode)
signal dungeon_generated(start_node: MapNode)
signal floor_completed(floor_number: int)

# Configuration
var max_depth: int = 15 # Rooms per floor
var choices_per_floor: int = 2 # How many paths to choose from
var current_floor: int = 1 # Which floor of the dungeon (for scaling)
var boss_depth: int = 15 # Default boss spawn depth
var total_floors: int = 3 # Total floors in this dungeon

# Dungeon data (set via configure())
var dungeon_data: DungeonData = null

# State
var current_depth: int = 0
var current_room: MapNode
var next_room_choices: Array[MapNode] = []
var floor_modifiers: Array[MapNode.Modifier] = []

## Configure the dungeon manager from a DungeonData resource.
func configure(data: DungeonData) -> void:
	dungeon_data = data
	max_depth = data.rooms_per_floor
	total_floors = data.total_floors
	current_floor = 1
	print("DungeonManager: Configured for '%s' (%d floors, %d rooms/floor)" % [data.display_name, data.total_floors, data.rooms_per_floor])

func generate_dungeon() -> void:
	current_depth = 0
	floor_modifiers.clear()
	
	# Roll floor-level modifiers
	_roll_floor_modifiers()
	
	# Adjust boss depth based on floor modifiers
	boss_depth = max_depth
	if floor_modifiers.has(MapNode.Modifier.TRACE):
		boss_depth = max_depth - 3 # Boss appears earlier
	elif floor_modifiers.has(MapNode.Modifier.SUBMERGED):
		boss_depth = max_depth + 3 # Boss appears later
	
	# Start at a Camp room (safe start)
	current_room = MapNode.new(MapNode.Type.CAMP, 0)
	current_room.visited = true
	current_room.completed = true
	
	_generate_next_choices()
	
	dungeon_generated.emit(current_room)

func get_next_choices() -> Array[MapNode]:
	if next_room_choices.is_empty():
		_generate_next_choices()
	return next_room_choices

func advance_to_room(choice_index: int) -> MapNode:
	if choice_index < 0 or choice_index >= next_room_choices.size():
		printerr("Invalid room choice index: %d" % choice_index)
		return current_room
		
	var next_room = next_room_choices[choice_index]
	current_room = next_room
	current_room.visited = true
	current_depth += 1
	
	room_changed.emit(current_room)
	
	next_room_choices.clear()
	
	return current_room

func complete_current_room() -> void:
	current_room.completed = true
	
	# Check if this was the boss — floor complete
	if current_room.type == MapNode.Type.BOSS:
		floor_completed.emit(current_floor)
		current_floor += 1
		# Reset for next floor
		current_depth = 0
		boss_depth = max_depth
		floor_modifiers.clear()
		_roll_floor_modifiers()

func _generate_next_choices() -> void:
	next_room_choices.clear()
	
	# KEY FIX: If the current room already has connected_nodes (from preview),
	# use those instead of generating new random rooms.
	if current_room.connected_nodes.size() > 0:
		for node in current_room.connected_nodes:
			next_room_choices.append(node)
			# Generate preview for the NEXT layer (so the tree keeps extending)
			if node.connected_nodes.size() == 0:
				_generate_future_nodes(node)
	else:
		# First room or no previews exist — generate fresh choices
		var next_depth = current_depth + 1
		
		for i in range(choices_per_floor):
			var type = _get_weighted_room_type(next_depth)
			var node = MapNode.new(type, next_depth)
			
			# Apply floor modifiers as room icons
			for mod in floor_modifiers:
				node.add_modifier(mod)
			
			# Randomly hide icons for some rooms (GameSpec §1: variable visibility)
			if randf() < 0.15:
				node.icons_hidden = true
			
			# Generate preview nodes (next layer)
			_generate_future_nodes(node)
			
			next_room_choices.append(node)
			current_room.connected_nodes.append(node)

func _generate_future_nodes(parent_node: MapNode) -> void:
	var future_depth = parent_node.depth + 1
	if future_depth > boss_depth: return
	
	for i in range(choices_per_floor):
		var type = _get_weighted_room_type(future_depth)
		var node = MapNode.new(type, future_depth)
		parent_node.connected_nodes.append(node)

func _get_weighted_room_type(depth: int) -> MapNode.Type:
	# Guaranteed Boss at boss_depth
	if depth >= boss_depth:
		return MapNode.Type.BOSS
	
	# Elite guaranteed at mid-floor
	if depth == int(boss_depth * 0.5):
		return MapNode.Type.ELITE
	
	var roll = randf()
	
	# Catacomb modifier increases enemy encounter rate
	var enemy_weight = 0.45
	if floor_modifiers.has(MapNode.Modifier.CATACOMB):
		enemy_weight = 0.60
	
	if roll < enemy_weight:
		return MapNode.Type.ENEMY
	elif roll < enemy_weight + 0.12:
		return MapNode.Type.EVENT
	elif roll < enemy_weight + 0.22:
		return MapNode.Type.CHEST
	elif roll < enemy_weight + 0.30:
		return MapNode.Type.CAMP
	elif roll < enemy_weight + 0.38:
		return MapNode.Type.ELITE
	else:
		return MapNode.Type.ENEMY # Fallback

func _roll_floor_modifiers() -> void:
	# Small chance of floor-wide modifiers
	if randf() < 0.15:
		var options = [
			MapNode.Modifier.TRACE,
			MapNode.Modifier.SUBMERGED,
			MapNode.Modifier.CATACOMB
		]
		floor_modifiers.append(options[randi() % options.size()])
		print("Floor Modifier Active: %s" % MapNode.Modifier.keys()[floor_modifiers[0]])
