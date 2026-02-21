class_name RoomSelector
extends Control

signal room_selected(index: int)

@onready var tree_container: HBoxContainer = $CenterContainer/TreeContainer
@onready var floor_info: Label = $CenterContainer/FloorInfo
const ROOM_BTN_SCENE = preload("res://ui/components/room_button.tscn")

func set_choices(choices: Array[MapNode], floor_num: int = 0, depth: int = 0) -> void:
	# Clear previous tree
	for child in tree_container.get_children():
		child.queue_free()
	
	# Update floor info
	if floor_info and (floor_num > 0 or depth > 0):
		floor_info.text = "Floor %d — Depth %d" % [floor_num, depth]
	elif floor_info:
		floor_info.text = ""
	
	# Build one column per choice:
	#   Row 1 (top):    preview nodes (connected_nodes of this choice)
	#   Row 2 (bottom): the clickable room button
	for i in range(choices.size()):
		var choice = choices[i]
		
		# Column VBox for this choice
		var column = VBoxContainer.new()
		column.alignment = BoxContainer.ALIGNMENT_END
		column.add_theme_constant_override("separation", 8)
		tree_container.add_child(column)
		
		# --- Row 1: Preview of future rooms ---
		var preview_row = HBoxContainer.new()
		preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
		preview_row.add_theme_constant_override("separation", 6)
		column.add_child(preview_row)
		
		if choice.connected_nodes.size() > 0:
			for future_node in choice.connected_nodes:
				var preview = _create_preview_rect(future_node)
				preview_row.add_child(preview)
		else:
			# Empty placeholder so columns stay aligned
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(60, 60)
			preview_row.add_child(spacer)
		
		# Connection line label
		var arrow = Label.new()
		arrow.text = "↑"
		arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(arrow)
		
		# --- Row 2: Clickable room button ---
		var btn = ROOM_BTN_SCENE.instantiate() as RoomButton
		column.add_child(btn)
		btn.setup(choice)
		btn.pressed.connect(_on_btn_pressed.bind(i))

func _create_preview_rect(node: MapNode) -> VBoxContainer:
	# Small preview: colored square with icon + label
	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Panel with colored bg + icon overlay
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(44, 44)
	box.add_child(panel)
	
	var rect = ColorRect.new()
	rect.custom_minimum_size = Vector2(44, 44)
	if node.icons_hidden:
		rect.color = Color.DIM_GRAY
	else:
		rect.color = RoomButton.get_type_color(node.type)
	panel.add_child(rect)
	
	var icon = Label.new()
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 20)
	if node.icons_hidden:
		icon.text = "❓"
	else:
		icon.text = RoomButton.get_type_icon(node.type)
	panel.add_child(icon)
	
	# Type name below
	var lbl = Label.new()
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if node.icons_hidden:
		lbl.text = "???"
	else:
		lbl.text = node.get_type_name()
	box.add_child(lbl)
	
	return box

func _on_btn_pressed(index: int) -> void:
	room_selected.emit(index)
