class_name HPBar
extends ProgressBar

@onready var label: Label = $Label

var is_shield: bool = false

const UI_PATH := "res://data/assets/ui/"

func _ready() -> void:
	_apply_texture_style()

func _apply_texture_style() -> void:
	# Background: dark interior matching the frame's inner color
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.07, 0.10, 1.0)
	bg.set_content_margin_all(4.0)
	add_theme_stylebox_override("background", bg)

	# Fill: pixel art color strip stretched to fit interior
	var fill := StyleBoxTexture.new()
	fill.texture = load(UI_PATH + ("ValueBlue_120x8.png" if is_shield else "ValueRed_120x8.png"))
	fill.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_theme_stylebox_override("fill", fill)

	# Frame overlay (NinePatchRect) drawn on top of everything
	if not has_node("Frame"):
		var frame := NinePatchRect.new()
		frame.name = "Frame"
		frame.texture = load(UI_PATH + "ValueBar_128x16.png")
		frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		frame.patch_margin_left   = 4
		frame.patch_margin_right  = 4
		frame.patch_margin_top    = 4
		frame.patch_margin_bottom = 4
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.z_index = 2
		add_child(frame)

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
	# Re-apply with shield (blue) fill
	var fill := StyleBoxTexture.new()
	fill.texture = load(UI_PATH + "ValueBlue_120x8.png")
	fill.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_theme_stylebox_override("fill", fill)
