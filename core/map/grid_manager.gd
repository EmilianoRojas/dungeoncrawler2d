class_name GridManager
extends Node

signal player_moved(new_node: MapNode)

var grid: Dictionary = {} # {Vector2i: MapNode}
var current_position: Vector2i = Vector2i.ZERO
var width: int = 10
var height: int = 10

func generate_grid(p_width: int, p_height: int) -> void:
	width = p_width
	height = p_height
	grid.clear()
	
	for x in range(width):
		for y in range(height):
			var pos = Vector2i(x, y)
			var node = MapNode.new(pos, _get_random_type())
			grid[pos] = node
			
	# Ensure starting position is safe
	current_position = Vector2i(0, 0)
	if grid.has(current_position):
		grid[current_position].type = MapNode.Type.SAFE
		grid[current_position].visited = true

func _get_random_type() -> MapNode.Type:
	# Simple random generation
	var roll = randf()
	if roll < 0.2:
		return MapNode.Type.SAFE
	elif roll < 0.7:
		return MapNode.Type.ENEMY
	else:
		return MapNode.Type.EVENT

func get_grid_node(pos: Vector2i) -> MapNode:
	return grid.get(pos)

func get_current_node() -> MapNode:
	return grid.get(current_position)

func move(direction: Vector2i) -> bool:
	var target_pos = current_position + direction
	
	if grid.has(target_pos):
		current_position = target_pos
		var node = grid[target_pos]
		node.visited = true
		player_moved.emit(node)
		return true
		
	return false
