class_name RoomSelector
extends Control

signal room_selected(index: int)

@onready var container: HBoxContainer = $ChoicesContainer
const ROOM_BTN_SCENE = preload("res://ui/components/room_button.tscn")

func set_choices(choices: Array[MapNode]) -> void:
	# Clear previous choices
	for child in container.get_children():
		child.queue_free()
	
	# Create buttons for each choice
	for i in range(choices.size()):
		var choice = choices[i]
		var btn = ROOM_BTN_SCENE.instantiate() as RoomButton
		container.add_child(btn)
		btn.setup(choice)
		
		# Connect signal with the index
		# Using a bind to pass the index
		btn.pressed.connect(_on_btn_pressed.bind(i))

func _on_btn_pressed(index: int) -> void:
	room_selected.emit(index)
