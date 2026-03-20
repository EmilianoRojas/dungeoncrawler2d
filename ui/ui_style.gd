class_name UIStyle

const UI_PATH := "res://data/assets/ui/"

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

## Applies the tiled background pattern to a Control node.
static func apply_background(node: Control) -> void:
	if node.has_node("PatternBG"):
		return
	var bg := TextureRect.new()
	bg.name = "PatternBG"
	bg.texture = load(UI_PATH + "bg_tile.png")
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.stretch_mode = TextureRect.STRETCH_TILE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -10
	node.add_child(bg)
	node.move_child(bg, 0)

## Applies the panel style to a PanelContainer or Panel node.
static func apply_panel(node: Control) -> void:
	node.add_theme_stylebox_override("panel", panel_stylebox())
