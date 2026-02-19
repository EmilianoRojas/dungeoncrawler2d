class_name DungeonManager
extends Node

signal room_changed(new_room: MapNode)
signal dungeon_generated(start_node: MapNode)

# Configuration
var max_depth: int = 15
var choices_per_floor: int = 2

# State
var current_depth: int = 0
var current_room: MapNode
var next_room_choices: Array[MapNode] = []

func generate_dungeon() -> void:
	current_depth = 0
	# Create a starting safe room
	current_room = MapNode.new(MapNode.Type.SAFE, 0)
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
	current_depth += 1
	
	room_changed.emit(current_room)
	
	# Clear choices so they are regenerated for the NEXT floor after this one is done
	# actually we might want to generate them immediately or when requested.
	# Let's clear them for now.
	next_room_choices.clear()
	
	return current_room

func _generate_next_choices() -> void:
	next_room_choices.clear()
	var next_depth = current_depth + 1
	
	for i in range(choices_per_floor):
		var type = _get_weighted_room_type(next_depth)
		var node = MapNode.new(type, next_depth)
		
		# Generate connections for the next layer (Preview)
		_generate_future_nodes(node)
		
		next_room_choices.append(node)

func _generate_future_nodes(parent_node: MapNode) -> void:
	var future_depth = parent_node.depth + 1
	if future_depth > max_depth: return
	
	# Generate choices for the future layer
	# Note: In a real connected graph, these might link to shared nodes.
	# For this prototype, we generate unique future nodes for each path.
	for i in range(choices_per_floor):
		var type = _get_weighted_room_type(future_depth)
		var node = MapNode.new(type, future_depth)
		parent_node.connected_nodes.append(node)

func _get_weighted_room_type(depth: int) -> MapNode.Type:
	# Guaranteed Boss at specific depths
	if depth == max_depth:
		return MapNode.Type.BOSS
	
	var roll = randf()
	
	# Logic to increase difficulty as depth increases could go here
	
	if roll < 0.5:
		return MapNode.Type.ENEMY
	elif roll < 0.65:
		return MapNode.Type.EVENT
	elif roll < 0.8:
		return MapNode.Type.TREASURE
	elif roll < 0.9:
		return MapNode.Type.ELITE
	else:
		return MapNode.Type.SAFE
