class_name MainMenu
extends Control

const LOBBY_SCENE := "res://ui/lobby.tscn"

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(360, 0)
	vbox.add_theme_constant_override("separation", 32)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	# ── Title block ─────────────────────────────────────────────
	var title_panel := PanelContainer.new()
	var title_sty := StyleBoxFlat.new()
	title_sty.bg_color = Color(0.08, 0.08, 0.14, 0.95)
	title_sty.border_color = Color(0.5, 0.4, 0.7)
	title_sty.set_border_width_all(2)
	title_sty.set_corner_radius_all(8)
	title_sty.set_content_margin_all(20)
	title_panel.add_theme_stylebox_override("panel", title_sty)
	vbox.add_child(title_panel)

	var title_vbox := VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 10)
	title_panel.add_child(title_vbox)

	var title := Label.new()
	title.text = "DUNGEON\nCRAWLER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	title_vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "2D"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.55, 0.85))
	title_vbox.add_child(subtitle)

	var tagline := Label.new()
	tagline.text = "descend. survive. conquer."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 7)
	tagline.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	title_vbox.add_child(tagline)

	# ── Buttons ──────────────────────────────────────────────────
	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 14)
	vbox.add_child(btn_vbox)

	_add_button(btn_vbox, "▶  PLAY",     Color(0.25, 0.60, 0.30), Color(0.5, 1.0, 0.55), _on_play_pressed)
	_add_button(btn_vbox, "✕  QUIT",     Color(0.35, 0.10, 0.10), Color(0.9, 0.35, 0.35), _on_quit_pressed)

	# ── Version ──────────────────────────────────────────────────
	var ver := Label.new()
	ver.text = "v0.1 — alpha"
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 6)
	ver.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
	vbox.add_child(ver)

func _add_button(parent: VBoxContainer, label: String,
		bg: Color, fg: Color, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 52)
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", fg)

	var sty := StyleBoxFlat.new()
	sty.bg_color = bg
	sty.border_color = fg.darkened(0.2)
	sty.set_border_width_all(2)
	sty.set_corner_radius_all(4)
	sty.content_margin_left  = 20
	sty.content_margin_right = 20
	btn.add_theme_stylebox_override("normal", sty)

	var hover := sty.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)

	var press := sty.duplicate() as StyleBoxFlat
	press.bg_color = bg.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", press)

	btn.pressed.connect(callback)
	parent.add_child(btn)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(LOBBY_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()
