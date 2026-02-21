class_name RoomButton
extends Button

var node_reference: MapNode

@onready var icon_color: ColorRect = $VBoxContainer/IconPanel/ColorRect
@onready var icon_label: Label = $VBoxContainer/IconPanel/IconLabel
@onready var label: Label = $VBoxContainer/Label
@onready var modifier_container: HBoxContainer = $VBoxContainer/ModifierContainer

func setup(node: MapNode) -> void:
	node_reference = node
	
	if node.icons_hidden:
		label.text = "???"
		icon_color.color = Color.DIM_GRAY
		icon_label.text = "❓"
	else:
		label.text = node.get_type_name()
		icon_color.color = get_type_color(node.type)
		icon_label.text = get_type_icon(node.type)
	
	icon_label.add_theme_font_size_override("font_size", 28)
	
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

# --- Static helpers (reused by RoomSelector for previews) ---

static func get_type_icon(type: MapNode.Type) -> String:
	match type:
		MapNode.Type.ENEMY:
			return "⚔️"
		MapNode.Type.ELITE:
			return "💀"
		MapNode.Type.BOSS:
			return "👹"
		MapNode.Type.CHEST:
			return "📦"
		MapNode.Type.EVENT:
			return "❓"
		MapNode.Type.CAMP:
			return "⛺"
	return "•"

static func get_type_color(type: MapNode.Type) -> Color:
	match type:
		MapNode.Type.ENEMY:
			return Color(0.8, 0.2, 0.2)
		MapNode.Type.ELITE:
			return Color(0.6, 0.1, 0.1)
		MapNode.Type.BOSS:
			return Color(0.5, 0.1, 0.6)
		MapNode.Type.CHEST:
			return Color(0.85, 0.7, 0.1)
		MapNode.Type.EVENT:
			return Color(0.3, 0.5, 0.8)
		MapNode.Type.CAMP:
			return Color(0.2, 0.7, 0.3)
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
