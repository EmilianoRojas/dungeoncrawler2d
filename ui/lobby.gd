class_name Lobby
extends Control

# ─── Colours ──────────────────────────────────────────────────────────────────
const C_BG        := Color(0.08, 0.08, 0.12)
const C_PANEL     := Color(0.12, 0.12, 0.20)
const C_HDR       := Color(0.06, 0.06, 0.10)
const C_GOLD      := Color(0.90, 0.75, 0.40)
const C_BLUE      := Color(0.50, 0.80, 1.00)
const C_PURP      := Color(0.70, 0.50, 1.00)
const C_GREEN     := Color(0.30, 0.90, 0.45)
const C_MUTED     := Color(0.55, 0.55, 0.60)
const C_WHITE     := Color(0.92, 0.92, 0.92)

const TIER_COLOR := {
	RuneResource.Tier.COMMON:    Color(0.80, 0.80, 0.80),
	RuneResource.Tier.RARE:      Color(0.40, 0.65, 1.00),
	RuneResource.Tier.LEGENDARY: Color(1.00, 0.80, 0.20),
}
const TIER_LABEL := {
	RuneResource.Tier.COMMON:    "C",
	RuneResource.Tier.RARE:      "R",
	RuneResource.Tier.LEGENDARY: "L",
}

# ─── Data ──────────────────────────────────────────────────────────────────────
var _classes:    Array[ClassData]        = []
var _camp_items: Array[CampItemResource] = []
var _dungeons:   Array[DungeonData]      = []

var _sel_class:     ClassData        = null
var _sel_camp:      CampItemResource = null
var _sel_dungeon:   DungeonData      = null

# ─── Tab state ─────────────────────────────────────────────────────────────────
var _tab_btns:   Array[Button]  = []
var _tab_panels: Array[Control] = []

# ─── Dungeon tab refs ──────────────────────────────────────────────────────────
var _d_class_row:    HBoxContainer
var _d_class_card:   PanelContainer
var _d_class_name:   Label
var _d_class_detail: RichTextLabel
var _d_camp_row:     HBoxContainer
var _d_camp_name:    Label
var _d_camp_desc:    Label
var _d_dg_list:      VBoxContainer
var _d_start_btn:    Button

# ─── Heroes tab refs ───────────────────────────────────────────────────────────
var _h_sidebar:    VBoxContainer
var _h_name:       Label
var _h_desc:       Label
var _h_slot_btns:  Array[Button] = []
var _h_cost_lbl:   Label
var _h_selected:   ClassData = null

# ─── Progress tab refs ─────────────────────────────────────────────────────────
var _p_root: VBoxContainer

# ─── Rune picker overlay ───────────────────────────────────────────────────────
var _rune_overlay: Control = null
var _rune_slot:    int     = -1

# ══════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	_load_data()
	_build_ui()

# ─── Data loading ──────────────────────────────────────────────────────────────
func _load_data() -> void:
	_classes.assign(_load_res("res://data/classes/",    ClassData))
	_camp_items.assign(_load_res("res://data/camp_items/", CampItemResource))
	_dungeons.assign(_load_res("res://data/dungeons/",   DungeonData))
	_classes.sort_custom(func(a, b): return a.title < b.title)
	_camp_items.sort_custom(func(a, b): return a.display_name < b.display_name)
	_dungeons.sort_custom(func(a, b): return a.difficulty < b.difficulty)

func _load_res(path: String, type) -> Array:
	var out := []
	var dir := DirAccess.open(path)
	if not dir:
		push_warning("Lobby: cannot open %s" % path)
		return out
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".tres"):
			var r = load(path + f)
			if is_instance_of(r, type):
				out.append(r)
		f = dir.get_next()
	dir.list_dir_end()
	return out

# ══════════════════════════════════════════════════════════════════════════════
# ROOT LAYOUT
# ══════════════════════════════════════════════════════════════════════════════
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	root.add_child(_make_header())
	root.add_child(_make_tab_bar())

	var content := Control.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	root.add_child(content)

	var panels := [
		_build_dungeon_tab(),
		_build_heroes_tab(),
		_build_progress_tab(),
	]
	for p in panels:
		p.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.add_child(p)
		_tab_panels.append(p)

	_switch_tab(0)

func _make_header() -> Control:
	var pc := PanelContainer.new()
	var sty := StyleBoxFlat.new()
	sty.bg_color = C_HDR
	pc.add_theme_stylebox_override("panel", sty)
	var mc := _margin(pc, 12, 10)
	var lbl := Label.new()
	lbl.text = "⚔  DUNGEON CRAWLER"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", C_GOLD)
	mc.add_child(lbl)
	return pc

func _make_tab_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 0)
	var defs := [["⚔\nDungeon", 0], ["🛡\nHeroes", 1], ["⭐\nProgress", 2]]
	for d in defs:
		var btn := Button.new()
		btn.text = d[0]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 54)
		btn.flat = true
		var idx: int = d[1]
		btn.pressed.connect(func(): _switch_tab(idx))
		_tab_btns.append(btn)
		bar.add_child(btn)
	return bar

func _switch_tab(idx: int) -> void:
	for i in _tab_panels.size():
		_tab_panels[i].visible = (i == idx)
	for i in _tab_btns.size():
		var active := (i == idx)
		_tab_btns[i].add_theme_color_override("font_color", C_GOLD if active else C_MUTED)
	if idx == 2:
		_refresh_progress()

# ══════════════════════════════════════════════════════════════════════════════
# TAB 0 — DUNGEON
# ══════════════════════════════════════════════════════════════════════════════
func _build_dungeon_tab() -> Control:
	var root := Control.new()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var mc := MarginContainer.new()
	for k in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mc.add_theme_constant_override(k, 14)
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(mc)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 12)
	mc.add_child(vb)

	# ── Class chips ─────────────────────────────────────────────────────
	_section(vb, "Choose Class", C_GOLD)

	var cls_scroll := _hscroll(62)
	vb.add_child(cls_scroll)
	_d_class_row = HBoxContainer.new()
	_d_class_row.add_theme_constant_override("separation", 8)
	cls_scroll.add_child(_d_class_row)

	# Class detail card (initially hidden)
	_d_class_card = _mk_panel(C_PANEL, 80)
	vb.add_child(_d_class_card)
	var cdm := _margin(_d_class_card, 12, 8)
	var cdvb := VBoxContainer.new()
	cdvb.add_theme_constant_override("separation", 4)
	cdm.add_child(cdvb)
	_d_class_name = Label.new()
	_d_class_name.text = "Select a class"
	_d_class_name.add_theme_font_size_override("font_size", 16)
	_d_class_name.add_theme_color_override("font_color", C_GOLD)
	cdvb.add_child(_d_class_name)
	_d_class_detail = RichTextLabel.new()
	_d_class_detail.bbcode_enabled = true
	_d_class_detail.fit_content = true
	_d_class_detail.scroll_active = false
	_d_class_detail.add_theme_font_size_override("normal_font_size", 12)
	_d_class_detail.add_theme_color_override("default_color", C_MUTED)
	cdvb.add_child(_d_class_detail)

	# ── Camp item chips ─────────────────────────────────────────────────
	_section(vb, "Camp Item", C_GOLD)

	var camp_scroll := _hscroll(62)
	vb.add_child(camp_scroll)
	_d_camp_row = HBoxContainer.new()
	_d_camp_row.add_theme_constant_override("separation", 8)
	camp_scroll.add_child(_d_camp_row)

	var camp_card := _mk_panel(C_PANEL, 56)
	vb.add_child(camp_card)
	var cmm := _margin(camp_card, 12, 8)
	var cmvb := VBoxContainer.new()
	cmvb.add_theme_constant_override("separation", 3)
	cmm.add_child(cmvb)
	_d_camp_name = Label.new()
	_d_camp_name.text = "Select a camp item"
	_d_camp_name.add_theme_font_size_override("font_size", 13)
	_d_camp_name.add_theme_color_override("font_color", C_WHITE)
	cmvb.add_child(_d_camp_name)
	_d_camp_desc = Label.new()
	_d_camp_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	_d_camp_desc.add_theme_font_size_override("font_size", 11)
	_d_camp_desc.add_theme_color_override("font_color", C_MUTED)
	cmvb.add_child(_d_camp_desc)

	# ── Dungeon cards ───────────────────────────────────────────────────
	_section(vb, "Select Dungeon", C_BLUE)

	_d_dg_list = VBoxContainer.new()
	_d_dg_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_d_dg_list.add_theme_constant_override("separation", 8)
	vb.add_child(_d_dg_list)

	# ── Start button ────────────────────────────────────────────────────
	vb.add_child(HSeparator.new())
	_d_start_btn = Button.new()
	_d_start_btn.text = "▶  START RUN"
	_d_start_btn.custom_minimum_size = Vector2(0, 54)
	_d_start_btn.disabled = true
	_d_start_btn.add_theme_font_size_override("font_size", 18)
	var ss := StyleBoxFlat.new()
	ss.bg_color = Color(0.10, 0.30, 0.10); ss.border_color = C_GREEN
	ss.set_border_width_all(2); ss.set_corner_radius_all(8)
	_d_start_btn.add_theme_stylebox_override("normal", ss)
	_d_start_btn.pressed.connect(_on_start_pressed)
	vb.add_child(_d_start_btn)

	var dev := Button.new()
	dev.text = "🧪 Battle Test (Dev)"
	dev.custom_minimum_size = Vector2(0, 36)
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.15, 0.10, 0.25, 0.9); ds.border_color = Color(0.5, 0.3, 0.8)
	ds.set_border_width_all(1); ds.set_corner_radius_all(5)
	dev.add_theme_stylebox_override("normal", ds)
	dev.pressed.connect(func(): get_tree().change_scene_to_file("res://test/battle_test.tscn"))
	vb.add_child(dev)

	# Populate chips and dungeon cards
	_populate_class_chips()
	_populate_camp_chips()
	_populate_dungeon_cards()

	return root

# ── Dungeon tab population ─────────────────────────────────────────────────────
func _populate_class_chips() -> void:
	for i in _classes.size():
		var btn := _chip(_classes[i].title, func(): _on_class(i))
		_d_class_row.add_child(btn)

func _populate_camp_chips() -> void:
	for i in _camp_items.size():
		var btn := _chip(_camp_items[i].display_name, func(): _on_camp(i))
		_d_camp_row.add_child(btn)

func _populate_dungeon_cards() -> void:
	for i in _dungeons.size():
		var dg: DungeonData = _dungeons[i]
		var locked := not DungeonProgress.is_unlocked(dg)
		var card := _mk_panel(Color(0.10, 0.13, 0.20), 0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_d_dg_list.add_child(card)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		var hbm := _margin(card, 12, 10)
		hbm.add_child(hb)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 3)
		hb.add_child(info)

		var nl := Label.new()
		var stars := "⭐".repeat(dg.difficulty)
		nl.text = ("🔒 " if locked else "") + dg.display_name + "  " + stars
		nl.add_theme_font_size_override("font_size", 15)
		nl.add_theme_color_override("font_color", C_MUTED if locked else C_WHITE)
		info.add_child(nl)

		var fl := Label.new()
		fl.text = "%d floors" % dg.total_floors
		fl.add_theme_font_size_override("font_size", 11)
		fl.add_theme_color_override("font_color", C_MUTED)
		info.add_child(fl)

		if dg.description != "":
			var dl := Label.new()
			dl.text = dg.description
			dl.autowrap_mode = TextServer.AUTOWRAP_WORD
			dl.add_theme_font_size_override("font_size", 11)
			dl.add_theme_color_override("font_color", C_MUTED)
			info.add_child(dl)

		if not locked:
			var sel := Button.new()
			sel.text = "Select"
			sel.custom_minimum_size = Vector2(70, 44)
			var sels := StyleBoxFlat.new()
			sels.bg_color = Color(0.10, 0.18, 0.32); sels.border_color = C_BLUE
			sels.set_border_width_all(1); sels.set_corner_radius_all(5)
			sel.add_theme_stylebox_override("normal", sels)
			var idx := i
			sel.pressed.connect(func(): _on_dungeon(idx))
			hb.add_child(sel)

# ── Dungeon tab selection ──────────────────────────────────────────────────────
func _on_class(i: int) -> void:
	_sel_class = _classes[i]
	_highlight_chips(_d_class_row, i)
	var cls := _sel_class
	_d_class_name.text = cls.title
	_d_class_detail.clear()
	var parts: Array[String] = []
	for k: StringName in cls.base_stats:
		parts.append("[b]%s[/b] %d" % [str(k).left(3).capitalize(), cls.base_stats[k]])
	_d_class_detail.append_text("  ".join(parts))
	var skills: Array[String] = []
	for sk in cls.starting_skills:
		if sk is Skill: skills.append(sk.skill_name)
	if skills.size() > 0:
		_d_class_detail.append_text("\n[color=#7fb8ff]Skills:[/color] %s" % ", ".join(skills))
	_update_start()

func _on_camp(i: int) -> void:
	_sel_camp = _camp_items[i]
	_highlight_chips(_d_camp_row, i)
	_d_camp_name.text = _sel_camp.display_name
	_d_camp_desc.text = _sel_camp.description
	_update_start()

func _on_dungeon(i: int) -> void:
	_sel_dungeon = _dungeons[i]
	for j in _d_dg_list.get_child_count():
		var card := _d_dg_list.get_child(j) as PanelContainer
		if not card: continue
		var sty := StyleBoxFlat.new()
		sty.bg_color = Color(0.10, 0.13, 0.20)
		sty.border_color = C_BLUE if j == i else Color(0.22, 0.25, 0.35)
		sty.set_border_width_all(2 if j == i else 1)
		sty.set_corner_radius_all(6)
		card.add_theme_stylebox_override("panel", sty)
	_update_start()

func _update_start() -> void:
	if _d_start_btn:
		_d_start_btn.disabled = not (_sel_class and _sel_camp and _sel_dungeon)

func _on_start_pressed() -> void:
	if not (_sel_class and _sel_camp and _sel_dungeon): return
	Engine.set_meta("selected_class",     _sel_class)
	Engine.set_meta("selected_camp_item", _sel_camp)
	Engine.set_meta("selected_dungeon",   _sel_dungeon)
	get_tree().change_scene_to_file("res://main.tscn")

# ══════════════════════════════════════════════════════════════════════════════
# TAB 1 — HEROES
# ══════════════════════════════════════════════════════════════════════════════
func _build_heroes_tab() -> Control:
	var root := Control.new()

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 0)
	root.add_child(hbox)

	# ── Left sidebar ───────────────────────────────────────────────────
	var left := Control.new()
	left.custom_minimum_size = Vector2(108, 0)

	var lbg := ColorRect.new()
	lbg.color = Color(0.07, 0.07, 0.12)
	lbg.set_anchors_preset(Control.PRESET_FULL_RECT)
	left.add_child(lbg)

	var lscroll := ScrollContainer.new()
	lscroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	lscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(lscroll)

	_h_sidebar = VBoxContainer.new()
	_h_sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_h_sidebar.add_theme_constant_override("separation", 4)
	var lmc := MarginContainer.new()
	for k in ["margin_left","margin_right","margin_top","margin_bottom"]:
		lmc.add_theme_constant_override(k, 6)
	lmc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lscroll.add_child(lmc)
	lmc.add_child(_h_sidebar)

	var hdr_lbl := Label.new()
	hdr_lbl.text = "HEROES"
	hdr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr_lbl.add_theme_font_size_override("font_size", 10)
	hdr_lbl.add_theme_color_override("font_color", C_MUTED)
	_h_sidebar.add_child(hdr_lbl)

	for i in _classes.size():
		var cls: ClassData = _classes[i]
		var btn := Button.new()
		btn.text = cls.title
		btn.custom_minimum_size = Vector2(0, 50)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.add_theme_font_size_override("font_size", 12)
		var sty := StyleBoxFlat.new()
		sty.bg_color = C_PANEL; sty.border_color = Color(0.28, 0.28, 0.42)
		sty.set_border_width_all(1); sty.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", sty)
		var idx := i
		btn.pressed.connect(func(): _on_hero(idx))
		_h_sidebar.add_child(btn)

	hbox.add_child(left)

	# ── Right detail area ──────────────────────────────────────────────
	var rscroll := ScrollContainer.new()
	rscroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rscroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	rscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hbox.add_child(rscroll)

	var rmc := MarginContainer.new()
	for k in ["margin_left","margin_right","margin_top","margin_bottom"]:
		rmc.add_theme_constant_override(k, 14)
	rmc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rscroll.add_child(rmc)

	var rvb := VBoxContainer.new()
	rvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rvb.add_theme_constant_override("separation", 12)
	rmc.add_child(rvb)

	_h_name = Label.new()
	_h_name.text = "Select a hero"
	_h_name.add_theme_font_size_override("font_size", 22)
	_h_name.add_theme_color_override("font_color", C_GOLD)
	rvb.add_child(_h_name)

	_h_desc = Label.new()
	_h_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	_h_desc.add_theme_font_size_override("font_size", 12)
	_h_desc.add_theme_color_override("font_color", C_MUTED)
	rvb.add_child(_h_desc)

	rvb.add_child(HSeparator.new())

	_section(rvb, "💎 Rune Slots", C_PURP)

	var slots_hb := HBoxContainer.new()
	slots_hb.add_theme_constant_override("separation", 8)
	slots_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rvb.add_child(slots_hb)

	_h_slot_btns.clear()
	for s in 3:
		var sb := Button.new()
		sb.custom_minimum_size = Vector2(0, 68)
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.add_theme_font_size_override("font_size", 11)
		_style_slot(sb, null)
		var si := s
		sb.pressed.connect(func(): _open_picker(si))
		_h_slot_btns.append(sb)
		slots_hb.add_child(sb)

	_h_cost_lbl = Label.new()
	_h_cost_lbl.add_theme_font_size_override("font_size", 11)
	_h_cost_lbl.add_theme_color_override("font_color", C_MUTED)
	rvb.add_child(_h_cost_lbl)

	return root

func _on_hero(i: int) -> void:
	_h_selected = _classes[i]
	# Highlight sidebar
	var children := _h_sidebar.get_children()
	for j in children.size():
		var btn := children[j] as Button
		if not btn: continue
		var sty := StyleBoxFlat.new()
		# j-1 because index 0 is the header label
		if j - 1 == i:
			sty.bg_color = C_PURP * Color(1,1,1,0.22)
			sty.border_color = C_PURP
			sty.set_border_width_all(2)
		else:
			sty.bg_color = C_PANEL; sty.border_color = Color(0.28, 0.28, 0.42)
			sty.set_border_width_all(1)
		sty.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", sty)
	_h_name.text = _h_selected.title
	_h_desc.text = _h_selected.description if _h_selected.description != "" else "A brave adventurer."
	_refresh_slots()

func _refresh_slots() -> void:
	if not _h_selected: return
	var equipped: Array[StringName] = RuneManager.get_equipped(_h_selected.title)
	for i in 3:
		var rune_id: StringName = equipped[i] if i < equipped.size() else &""
		var rune: RuneResource = RuneLibrary.get_rune(rune_id) if rune_id != &"" else null
		_style_slot(_h_slot_btns[i], rune)
	var used := RuneManager.get_used_cost(_h_selected.title)
	_h_cost_lbl.text = "Rune budget: %d / %d" % [used, RuneManager.MAX_COST]
	_h_cost_lbl.add_theme_color_override("font_color",
		Color(1.0, 0.4, 0.4) if used >= RuneManager.MAX_COST else C_MUTED)

func _style_slot(btn: Button, rune: RuneResource) -> void:
	var sty := StyleBoxFlat.new()
	sty.set_corner_radius_all(6); sty.set_border_width_all(1)
	sty.content_margin_left = 6; sty.content_margin_right = 6
	sty.content_margin_top = 6; sty.content_margin_bottom = 6
	if rune:
		var tc: Color = TIER_COLOR[rune.tier]
		sty.bg_color = tc * Color(1,1,1,0.14); sty.border_color = tc
		btn.text = "[%s] %s\n%s" % [TIER_LABEL[rune.tier], rune.display_name, rune.description]
		btn.add_theme_color_override("font_color", tc)
	else:
		sty.bg_color = Color(0.10, 0.10, 0.16); sty.border_color = Color(0.28, 0.28, 0.44)
		btn.text = "+ Add Rune"
		btn.add_theme_color_override("font_color", C_MUTED)
	btn.add_theme_stylebox_override("normal", sty)

# ── Rune picker overlay ────────────────────────────────────────────────────────
func _open_picker(slot: int) -> void:
	if not _h_selected: return
	if _rune_overlay:
		_rune_overlay.queue_free()
		_rune_overlay = null
	_rune_slot = slot
	var cls_title := _h_selected.title

	# Backdrop
	_rune_overlay = Control.new()
	_rune_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rune_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_rune_overlay)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.68)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_rune_overlay.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rune_overlay.add_child(center)

	# Panel
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(310, 0)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.08, 0.08, 0.14, 0.97); ps.border_color = C_PURP
	ps.set_border_width_all(2); ps.set_corner_radius_all(8)
	ps.content_margin_left = 16; ps.content_margin_right = 16
	ps.content_margin_top = 14; ps.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)

	var pvb := VBoxContainer.new()
	pvb.add_theme_constant_override("separation", 10)
	panel.add_child(pvb)

	var title_lbl := Label.new()
	title_lbl.text = "💎 Rune Slot %d" % (slot + 1)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", C_PURP)
	pvb.add_child(title_lbl)

	pvb.add_child(HSeparator.new())

	# Get current equipped, padded to 3
	var equipped: Array[StringName] = RuneManager.get_equipped(cls_title)
	var cur_id: StringName = equipped[slot] if slot < equipped.size() else &""

	# Rune list — scrollable
	var rscroll := ScrollContainer.new()
	rscroll.custom_minimum_size = Vector2(0, 260)
	rscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pvb.add_child(rscroll)

	var rvb := VBoxContainer.new()
	rvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rvb.add_theme_constant_override("separation", 6)
	rscroll.add_child(rvb)

	# Runes in other slots (to exclude from picker)
	var other_ids: Array[StringName] = []
	for s in 3:
		if s != slot and s < equipped.size() and equipped[s] != &"":
			other_ids.append(equipped[s])

	var unlocked: Array[StringName] = RuneManager.unlocked_rune_ids
	if unlocked.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No runes unlocked yet.\nWin combats to earn runes!"
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", C_MUTED)
		rvb.add_child(empty_lbl)
	else:
		# Sort by tier (Legendary → Rare → Common), skip runes in other slots
		for tier in [RuneResource.Tier.LEGENDARY, RuneResource.Tier.RARE, RuneResource.Tier.COMMON]:
			var tier_runes: Array[RuneResource] = RuneLibrary.get_runes_by_tier(tier)
			var shown := false
			for rune in tier_runes:
				if not unlocked.has(rune.id): continue
				if other_ids.has(rune.id): continue
				if not shown:
					var hdr := Label.new()
					match tier:
						RuneResource.Tier.LEGENDARY: hdr.text = "── Legendary ──"
						RuneResource.Tier.RARE:      hdr.text = "── Rare ──"
						RuneResource.Tier.COMMON:    hdr.text = "── Common ──"
					hdr.add_theme_font_size_override("font_size", 11)
					hdr.add_theme_color_override("font_color", TIER_COLOR[tier])
					rvb.add_child(hdr)
					shown = true
				rvb.add_child(_make_rune_entry(rune, cls_title, cur_id, slot))

	pvb.add_child(HSeparator.new())

	# Clear slot button (only if slot is occupied)
	if cur_id != &"":
		var clr := Button.new()
		clr.text = "✕  Clear Slot"
		clr.custom_minimum_size = Vector2(0, 44)
		var cs := StyleBoxFlat.new()
		cs.bg_color = Color(0.22, 0.07, 0.07); cs.border_color = Color(0.8, 0.3, 0.3)
		cs.set_border_width_all(1); cs.set_corner_radius_all(5)
		clr.add_theme_stylebox_override("normal", cs)
		clr.pressed.connect(func():
			RuneManager.unequip_rune(cls_title, cur_id)
			_close_picker()
		)
		pvb.add_child(clr)

	var close := Button.new()
	close.text = "✖  Close"
	close.custom_minimum_size = Vector2(0, 44)
	close.pressed.connect(_close_picker)
	pvb.add_child(close)

func _make_rune_entry(rune: RuneResource, cls_title: String,
		cur_id: StringName, slot: int) -> Button:
	var tc: Color = TIER_COLOR[rune.tier]
	var is_cur := (rune.id == cur_id)
	var cost    := RuneLibrary.get_cost(rune.tier)

	# Affordability check: if this rune would replace cur_id, compute adjusted cost
	var can: bool
	if is_cur:
		can = true
	else:
		var used := RuneManager.get_used_cost(cls_title)
		var cur_cost := 0
		if cur_id != &"":
			var cr := RuneLibrary.get_rune(cur_id)
			if cr: cur_cost = RuneLibrary.get_cost(cr.tier)
		can = (used - cur_cost + cost) <= RuneManager.MAX_COST

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 52)
	btn.disabled = not (is_cur or can)

	var sty := StyleBoxFlat.new()
	if is_cur:
		sty.bg_color = tc * Color(1,1,1,0.22); sty.border_color = tc
		sty.set_border_width_all(2)
	elif can:
		sty.bg_color = Color(0.10, 0.10, 0.18); sty.border_color = tc * Color(1,1,1,0.45)
		sty.set_border_width_all(1)
	else:
		sty.bg_color = Color(0.08, 0.08, 0.10); sty.border_color = Color(0.22, 0.22, 0.22)
		sty.set_border_width_all(1)
	sty.set_corner_radius_all(5)
	sty.content_margin_left = 8; sty.content_margin_right = 8
	sty.content_margin_top = 6; sty.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", sty)

	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 8)
	btn.add_child(hb)

	var badge := Label.new()
	badge.text = "[%s]" % TIER_LABEL[rune.tier]
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", tc if can or is_cur else C_MUTED)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(badge)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(info)

	var nl := Label.new()
	nl.text = rune.display_name
	nl.add_theme_font_size_override("font_size", 13)
	nl.add_theme_color_override("font_color", tc if can or is_cur else C_MUTED)
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(nl)

	var dl := Label.new()
	dl.text = rune.description
	dl.add_theme_font_size_override("font_size", 10)
	dl.add_theme_color_override("font_color", C_MUTED)
	dl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(dl)

	var cost_lbl := Label.new()
	cost_lbl.text = "⚡%d" % cost
	cost_lbl.add_theme_font_size_override("font_size", 12)
	cost_lbl.add_theme_color_override("font_color",
		Color(1.0, 0.85, 0.2) if (can or is_cur) else C_MUTED)
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(cost_lbl)

	if is_cur:
		btn.pressed.connect(_close_picker)
	elif can:
		var r := rune  # capture
		var ct := cls_title
		var ci := cur_id
		btn.pressed.connect(func():
			# Replace old rune in this slot if any
			if ci != &"":
				RuneManager.unequip_rune(ct, ci)
			RuneManager.equip_rune(ct, r.id)
			_close_picker()
		)

	return btn

func _close_picker() -> void:
	if _rune_overlay:
		_rune_overlay.queue_free()
		_rune_overlay = null
	_rune_slot = -1
	_refresh_slots()

# ══════════════════════════════════════════════════════════════════════════════
# TAB 2 — PROGRESS
# ══════════════════════════════════════════════════════════════════════════════
func _build_progress_tab() -> Control:
	var root := Control.new()

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var mc := MarginContainer.new()
	for k in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mc.add_theme_constant_override(k, 16)
	mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(mc)

	_p_root = VBoxContainer.new()
	_p_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_p_root.add_theme_constant_override("separation", 14)
	mc.add_child(_p_root)

	return root

func _refresh_progress() -> void:
	if not _p_root: return
	for c in _p_root.get_children():
		c.queue_free()

	var level   := PlayerProfile.get_level()
	var xp      := PlayerProfile.get_xp()
	var xp_next := PlayerProfile.get_xp_for_next_level()

	# ── Level header ───────────────────────────────────────────────────
	var lvl_lbl := Label.new()
	lvl_lbl.text = "🏆  Level %d" % level
	lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_lbl.add_theme_font_size_override("font_size", 26)
	lvl_lbl.add_theme_color_override("font_color", C_GOLD)
	_p_root.add_child(lvl_lbl)

	var xp_lbl := Label.new()
	xp_lbl.text = "XP  %d / %d  (runs)" % [xp, xp_next]
	xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_lbl.add_theme_font_size_override("font_size", 12)
	xp_lbl.add_theme_color_override("font_color", C_MUTED)
	_p_root.add_child(xp_lbl)

	# XP bar
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.15, 0.15, 0.20)
	bar_bg.custom_minimum_size = Vector2(0, 12)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_p_root.add_child(bar_bg)
	var fill := ColorRect.new()
	fill.color = C_GOLD
	var ratio := float(xp) / float(max(xp_next, 1))
	fill.anchor_left = 0.0; fill.anchor_top = 0.0
	fill.anchor_right = ratio; fill.anchor_bottom = 1.0
	bar_bg.add_child(fill)

	_p_root.add_child(HSeparator.new())

	# ── Stats ──────────────────────────────────────────────────────────
	_section(_p_root, "Statistics", C_BLUE)

	var runs  := PlayerProfile.runs_completed
	var wins  := PlayerProfile.runs_won
	var floor := PlayerProfile.floors_explored
	var wr_str := "—" if runs == 0 else ("%.0f%%" % (float(wins) / float(runs) * 100.0))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_p_root.add_child(grid)

	for pair in [
		["Runs Completed", str(runs)],
		["Runs Won",       str(wins)],
		["Win Rate",       wr_str],
		["Floors Explored", str(floor)],
		["Dungeons Cleared", str(DungeonProgress.cleared_dungeons.size())],
	]:
		var k := Label.new(); k.text = pair[0]
		k.add_theme_font_size_override("font_size", 13)
		k.add_theme_color_override("font_color", C_MUTED)
		grid.add_child(k)
		var v := Label.new(); v.text = pair[1]
		v.add_theme_font_size_override("font_size", 13)
		v.add_theme_color_override("font_color", C_WHITE)
		grid.add_child(v)

	_p_root.add_child(HSeparator.new())

	# ── Quests ─────────────────────────────────────────────────────────
	_section(_p_root, "Quests", C_GOLD)

	for q in PlayerProfile.get_quests():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		_p_root.add_child(row)

		var icon := Label.new()
		icon.text = "✔" if q["done"] else "○"
		icon.add_theme_font_size_override("font_size", 14)
		icon.add_theme_color_override("font_color", C_GREEN if q["done"] else C_MUTED)
		row.add_child(icon)

		var qvb := VBoxContainer.new()
		qvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(qvb)

		var qt := Label.new(); qt.text = q["title"]
		qt.add_theme_font_size_override("font_size", 13)
		qt.add_theme_color_override("font_color", C_GREEN if q["done"] else C_WHITE)
		qvb.add_child(qt)

		var qdesc := Label.new(); qdesc.text = q["desc"]
		qdesc.add_theme_font_size_override("font_size", 11)
		qdesc.add_theme_color_override("font_color", C_MUTED)
		qvb.add_child(qdesc)

		var prog := Label.new()
		prog.text = "%d / %d" % [q["current"], q["target"]]
		prog.add_theme_font_size_override("font_size", 11)
		prog.add_theme_color_override("font_color", C_GREEN if q["done"] else C_MUTED)
		row.add_child(prog)

# ══════════════════════════════════════════════════════════════════════════════
# SHARED HELPERS
# ══════════════════════════════════════════════════════════════════════════════
func _hscroll(min_h: int) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sc.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(0, min_h)
	return sc

func _chip(txt: String, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(78, 50)
	btn.pressed.connect(cb)
	var sty := StyleBoxFlat.new()
	sty.bg_color = C_PANEL; sty.border_color = Color(0.32, 0.32, 0.48)
	sty.set_border_width_all(1); sty.set_corner_radius_all(25)
	sty.content_margin_left = 12; sty.content_margin_right = 12
	btn.add_theme_stylebox_override("normal", sty)
	btn.add_theme_font_size_override("font_size", 13)
	return btn

func _highlight_chips(row: HBoxContainer, sel: int) -> void:
	for i in row.get_child_count():
		var btn := row.get_child(i) as Button
		if not btn: continue
		var sty := StyleBoxFlat.new()
		if i == sel:
			sty.bg_color = C_GOLD * Color(1,1,1,0.28); sty.border_color = C_GOLD
			sty.set_border_width_all(2)
		else:
			sty.bg_color = C_PANEL; sty.border_color = Color(0.32, 0.32, 0.48)
			sty.set_border_width_all(1)
		sty.set_corner_radius_all(25)
		sty.content_margin_left = 12; sty.content_margin_right = 12
		btn.add_theme_stylebox_override("normal", sty)

func _mk_panel(color: Color, min_h: int) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if min_h > 0:
		pc.custom_minimum_size = Vector2(0, min_h)
	var sty := StyleBoxFlat.new()
	sty.bg_color = color; sty.set_corner_radius_all(6)
	pc.add_theme_stylebox_override("panel", sty)
	return pc

## Creates a MarginContainer inside `parent` with horizontal/vertical margins.
## Returns the MarginContainer so children can be added to it.
func _margin(parent: Control, px_h: int, px_v: int = -1) -> MarginContainer:
	if px_v < 0: px_v = px_h
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left",   px_h)
	mc.add_theme_constant_override("margin_right",  px_h)
	mc.add_theme_constant_override("margin_top",    px_v)
	mc.add_theme_constant_override("margin_bottom", px_v)
	parent.add_child(mc)
	return mc

func _section(parent: Control, txt: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
