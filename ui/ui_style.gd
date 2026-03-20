class_name UIStyle

const UI_PATH := "res://data/assets/ui/"

# Dark background color matching the panel interior
const BG_COLOR := Color(0.10, 0.06, 0.09, 1.0)
# Ornament tint — warm taupe to match the pack's palette
const ORNAMENT_COLOR := Color(0.72, 0.62, 0.50, 1.0)
# Scale factor for ornament sprites (2× so they read on a 720px-wide screen)
const ORNAMENT_SCALE := 2.0

## Returns a StyleBoxTexture using the gold-bordered panel (RectangleBox_96x96).
static func panel_stylebox() -> StyleBoxTexture:
	var sty := StyleBoxTexture.new()
	sty.texture = load(UI_PATH + "RectangleBox_96x96.png")
	sty.texture_margin_left   = 7
	sty.texture_margin_right  = 7
	sty.texture_margin_top    = 7
	sty.texture_margin_bottom = 7
	sty.set_content_margin_all(12.0)
	return sty

## Applies solid dark background + ornament corners to a Control node.
static func apply_background(node: Control) -> void:
	if node.has_node("PatternBG"):
		return

	# Solid dark base
	var bg := ColorRect.new()
	bg.name = "PatternBG"
	bg.color = BG_COLOR
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -10
	node.add_child(bg)
	node.move_child(bg, 0)

	# Bottom corners (128x112 each)
	_add_ornament(node, "ornament_bottom_left.png",  Control.PRESET_BOTTOM_LEFT,  false, false)
	_add_ornament(node, "ornament_bottom_left.png",  Control.PRESET_BOTTOM_RIGHT, true,  false)

	# Top corners (112x67 each)
	_add_ornament(node, "ornament_top_left.png",     Control.PRESET_TOP_LEFT,     false, false)
	_add_ornament(node, "ornament_top_left.png",     Control.PRESET_TOP_RIGHT,    true,  false)

	# Crown at top center
	_add_ornament(node, "ornament_crown.png",        Control.PRESET_CENTER_TOP,   false, false)

static func _add_ornament(
		parent: Control,
		filename: String,
		preset: int,
		flip_h: bool,
		flip_v: bool) -> void:

	var tex: Texture2D = load(UI_PATH + filename)
	if not tex:
		return

	var rect := TextureRect.new()
	rect.texture = tex
	rect.flip_h = flip_h
	rect.flip_v = flip_v
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.stretch_mode = TextureRect.STRETCH_KEEP  # pixel-perfect, no blur
	rect.modulate = ORNAMENT_COLOR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = -9

	# Size at 2× pixel scale
	var size := tex.get_size() * ORNAMENT_SCALE
	rect.custom_minimum_size = size
	rect.size = size

	parent.add_child(rect)

	# Position after adding so the parent has a valid size
	rect.set_anchors_preset(preset)

	# Offset center-top crown so it doesn't overlap corners
	if preset == Control.PRESET_CENTER_TOP:
		rect.anchor_left   = 0.5
		rect.anchor_right  = 0.5
		rect.offset_left   = -size.x * 0.5
		rect.offset_right  = size.x * 0.5
		rect.offset_top    = 0
		rect.offset_bottom = size.y

## Applies the panel style to a PanelContainer or Panel node.
static func apply_panel(node: Control) -> void:
	node.add_theme_stylebox_override("panel", panel_stylebox())
