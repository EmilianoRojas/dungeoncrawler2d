class_name RoomButton
extends Button

var node_reference: MapNode

@onready var icon_rect: ColorRect = $VBoxContainer/Icon
@onready var label: Label = $VBoxContainer/Label
@onready var modifier_container: HBoxContainer = $VBoxContainer/ModifierContainer

func setup(node: MapNode) -> void:
	node_reference = node
	
	if node.icons_hidden:
		label.text = "???"
		icon_rect.color = Color.DIM_GRAY
	else:
		label.text = node.get_type_name()
		_set_icon_color(icon_rect, node.type)
	
	# Show modifier badges
	for child in modifier_container.get_children():
		child.queue_free()
	
	if not node.icons_hidden:
		for mod in node.icons:
			if mod != MapNode.Modifier.NONE:
				var badge = Label.new()
				badge.text = _get_modifier_badge(mod)
				badge.add_theme_font_size_override("font_size", 10)
				modifier_container.add_child(badge)

static func get_type_color(type: MapNode.Type) -> Color:
	match type:
		MapNode.Type.ENEMY:
			return Color.RED
		MapNode.Type.ELITE:
			return Color.DARK_RED
		MapNode.Type.BOSS:
			return Color.PURPLE
		MapNode.Type.CHEST:
			return Color.GOLD
		MapNode.Type.EVENT:
			return Color.CORNFLOWER_BLUE
		MapNode.Type.CAMP:
			return Color.GREEN
	return Color.GRAY

func _get_modifier_badge(mod: MapNode.Modifier) -> String:
	match mod:
		MapNode.Modifier.TRACE:
			return "⚡TRC"
		MapNode.Modifier.SUBMERGED:
			return "🌊SUB"
		MapNode.Modifier.CATACOMB:
			return "💀CAT"
	return ""

func _set_icon_color(rect: ColorRect, type: MapNode.Type) -> void:
	rect.color = RoomButton.get_type_color(type)
