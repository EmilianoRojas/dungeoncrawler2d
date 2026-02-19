class_name RoomButton
extends Button

var node_reference: MapNode

@onready var icon_rect: ColorRect = $VBoxContainer/Icon
@onready var label: Label = $VBoxContainer/Label


@onready var preview_container: HBoxContainer = $VBoxContainer/PreviewContainer

func setup(node: MapNode) -> void:
	node_reference = node
	var type_name = MapNode.Type.keys()[node.type]
	label.text = type_name.capitalize()
	
	_set_icon_color(icon_rect, node.type)
	
	# Show connected nodes (Preview)
	for child in preview_container.get_children():
		child.queue_free()
		
	for next_node in node.connected_nodes:
		var preview = ColorRect.new()
		preview.custom_minimum_size = Vector2(16, 16)
		_set_icon_color(preview, next_node.type)
		preview_container.add_child(preview)

func _set_icon_color(rect: ColorRect, type: MapNode.Type) -> void:
	match type:
		MapNode.Type.ENEMY:
			rect.color = Color.RED
		MapNode.Type.ELITE:
			rect.color = Color.DARK_RED
		MapNode.Type.BOSS:
			rect.color = Color.PURPLE
		MapNode.Type.TREASURE:
			rect.color = Color.GOLD
		MapNode.Type.EVENT:
			rect.color = Color.BLUE
		MapNode.Type.SAFE:
			rect.color = Color.GREEN
