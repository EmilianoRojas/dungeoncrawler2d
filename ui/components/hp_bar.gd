class_name HPBar
extends ProgressBar

@onready var label: Label = $Label

var is_shield: bool = false

func update_health(current: int, max_val: int) -> void:
	max_value = max_val
	value = current
	if label:
		label.text = "🛡 %d / %d" % [current, max_val] if is_shield else "%d / %d" % [current, max_val]

func update_health_animated(current: int, max_val: int, duration: float = 0.3) -> void:
	max_value = max_val
	var tween := create_tween()
	tween.tween_property(self, "value", float(current), duration)
	tween.tween_callback(func():
		if label:
			label.text = "🛡 %d / %d" % [current, max_val] if is_shield else "%d / %d" % [current, max_val]
	)

func set_as_shield() -> void:
	is_shield = true
	add_theme_stylebox_override("fill", _create_shield_style())

func _create_shield_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.6, 0.9, 1.0)
	style.set_corner_radius_all(2)
	return style
