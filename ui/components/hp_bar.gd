class_name HPBar
extends ProgressBar

@onready var label: Label = $Label

func update_health(current: int, max_hp: int) -> void:
	max_value = max_hp
	value = current
	if label:
		label.text = "%d / %d" % [current, max_hp]
