class_name Lobby
extends Control

# Lobby / Class Selection UI
# Entry point scene — player picks a class, then starts the dungeon run.

var _classes: Array[ClassData] = []
var _selected_class: ClassData = null

# Camp Items
var _camp_items: Array[CampItemResource] = []
var _selected_camp_item: CampItemResource = null

# Dungeons
var _dungeons: Array[DungeonData] = []
var _selected_dungeon: DungeonData = null

# UI nodes (built dynamically)
var title_label: Label
var class_list: VBoxContainer
var detail_panel: VBoxContainer
var detail_name: Label
var detail_desc: Label
var detail_stats: RichTextLabel
var detail_skills: Label
var start_button: Button

# Camp item UI
var camp_section_label: Label
var camp_list: VBoxContainer
var camp_desc: Label
var camp_selected_label: Label

# Dungeon UI
var dungeon_list: VBoxContainer
var dungeon_desc: Label
var dungeon_selected_label: Label
var dungeon_difficulty_label: Label

func _ready() -> void:
	_build_ui()
	_load_classes()
	_load_camp_items()
	_load_dungeons()
	_populate_class_list()
	_populate_camp_list()
	_populate_dungeon_list()

func _build_ui() -> void:
	# Full-screen dark background
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Center container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.custom_minimum_size = Vector2(600, 500)
	main_vbox.add_theme_constant_override("separation", 20)
	center.add_child(main_vbox)
	
	# Title
	title_label = Label.new()
	title_label.text = "⚔ DUNGEON CRAWLER"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	main_vbox.add_child(title_label)
	
	# Subtitle
	var sub = Label.new()
	sub.text = "Choose your class"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	main_vbox.add_child(sub)
	
	# Content: class list + detail panel side by side
	var content = HBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content)
	
	# Left: Class list
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(200, 0)
	content.add_child(left_panel)
	
	class_list = VBoxContainer.new()
	class_list.add_theme_constant_override("separation", 8)
	var left_margin = MarginContainer.new()
	left_margin.add_theme_constant_override("margin_left", 10)
	left_margin.add_theme_constant_override("margin_right", 10)
	left_margin.add_theme_constant_override("margin_top", 10)
	left_margin.add_theme_constant_override("margin_bottom", 10)
	left_panel.add_child(left_margin)
	left_margin.add_child(class_list)
	
	# Right: Detail panel
	var right_panel = PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(right_panel)
	
	detail_panel = VBoxContainer.new()
	detail_panel.add_theme_constant_override("separation", 10)
	var right_margin = MarginContainer.new()
	right_margin.add_theme_constant_override("margin_left", 15)
	right_margin.add_theme_constant_override("margin_right", 15)
	right_margin.add_theme_constant_override("margin_top", 15)
	right_margin.add_theme_constant_override("margin_bottom", 15)
	right_panel.add_child(right_margin)
	right_margin.add_child(detail_panel)
	
	detail_name = Label.new()
	detail_name.text = "Select a class"
	detail_name.add_theme_font_size_override("font_size", 24)
	detail_panel.add_child(detail_name)
	
	detail_desc = Label.new()
	detail_desc.text = ""
	detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	detail_panel.add_child(detail_desc)
	
	var sep = HSeparator.new()
	detail_panel.add_child(sep)
	
	detail_stats = RichTextLabel.new()
	detail_stats.bbcode_enabled = true
	detail_stats.fit_content = true
	detail_stats.custom_minimum_size = Vector2(0, 100)
	detail_stats.scroll_active = false
	detail_panel.add_child(detail_stats)
	
	detail_skills = Label.new()
	detail_skills.text = ""
	detail_skills.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_panel.add_child(detail_skills)
	
	# --- Camp Item Section ---
	var camp_header = Label.new()
	camp_header.text = "Camp Item"
	camp_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	camp_header.add_theme_font_size_override("font_size", 18)
	camp_header.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4))
	main_vbox.add_child(camp_header)
	
	var camp_row = HBoxContainer.new()
	camp_row.add_theme_constant_override("separation", 10)
	camp_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(camp_row)
	
	camp_list = VBoxContainer.new()
	camp_list.add_theme_constant_override("separation", 4)
	camp_row.add_child(camp_list)
	
	var camp_detail = VBoxContainer.new()
	camp_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	camp_row.add_child(camp_detail)
	
	camp_selected_label = Label.new()
	camp_selected_label.text = "Select a camp item"
	camp_selected_label.add_theme_font_size_override("font_size", 14)
	camp_detail.add_child(camp_selected_label)
	
	camp_desc = Label.new()
	camp_desc.text = ""
	camp_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	camp_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	camp_desc.add_theme_font_size_override("font_size", 12)
	camp_detail.add_child(camp_desc)
	
	# --- Dungeon Selection Section ---
	var dg_header = Label.new()
	dg_header.text = "Dungeon"
	dg_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dg_header.add_theme_font_size_override("font_size", 18)
	dg_header.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	main_vbox.add_child(dg_header)
	
	var dg_row = HBoxContainer.new()
	dg_row.add_theme_constant_override("separation", 10)
	dg_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(dg_row)
	
	dungeon_list = VBoxContainer.new()
	dungeon_list.add_theme_constant_override("separation", 4)
	dg_row.add_child(dungeon_list)
	
	var dg_detail = VBoxContainer.new()
	dg_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dg_row.add_child(dg_detail)
	
	dungeon_selected_label = Label.new()
	dungeon_selected_label.text = "Select a dungeon"
	dungeon_selected_label.add_theme_font_size_override("font_size", 14)
	dg_detail.add_child(dungeon_selected_label)
	
	dungeon_difficulty_label = Label.new()
	dungeon_difficulty_label.text = ""
	dungeon_difficulty_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	dg_detail.add_child(dungeon_difficulty_label)
	
	dungeon_desc = Label.new()
	dungeon_desc.text = ""
	dungeon_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	dungeon_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	dungeon_desc.add_theme_font_size_override("font_size", 12)
	dg_detail.add_child(dungeon_desc)
	
	# Start button
	start_button = Button.new()
	start_button.text = "▶ Start Run"
	start_button.custom_minimum_size = Vector2(0, 50)
	start_button.disabled = true
	start_button.pressed.connect(_on_start_pressed)
	main_vbox.add_child(start_button)

func _load_classes() -> void:
	var dir = DirAccess.open("res://data/classes/")
	if not dir:
		push_error("Lobby: Cannot open res://data/classes/")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path = "res://data/classes/" + file_name
			var res = load(path)
			if res is ClassData:
				_classes.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	# Sort alphabetically
	_classes.sort_custom(func(a, b): return a.title < b.title)

func _populate_class_list() -> void:
	for i in range(_classes.size()):
		var cls = _classes[i]
		var btn = Button.new()
		btn.text = cls.title
		btn.custom_minimum_size = Vector2(180, 40)
		var idx = i
		btn.pressed.connect(func(): _on_class_selected(idx))
		class_list.add_child(btn)

func _on_class_selected(index: int) -> void:
	_selected_class = _classes[index]
	start_button.disabled = false
	
	# Update detail panel
	detail_name.text = _selected_class.title
	detail_desc.text = _selected_class.description if _selected_class.description != "" else "A brave adventurer."
	
	# Stats
	detail_stats.text = ""
	detail_stats.append_text("[b]Base Stats[/b]\n")
	for stat_name in _selected_class.base_stats:
		var val = _selected_class.base_stats[stat_name]
		detail_stats.append_text("  %s: %d\n" % [str(stat_name).capitalize(), val])
	
	# Starting skills
	var skill_names: Array[String] = []
	for skill in _selected_class.starting_skills:
		if skill is Skill:
			skill_names.append(skill.skill_name)
	detail_skills.text = "Starting Skills: %s" % ", ".join(skill_names) if skill_names.size() > 0 else "Starting Skills: None"
	_update_start_button()

func _load_camp_items() -> void:
	var dir = DirAccess.open("res://data/camp_items/")
	if not dir:
		push_warning("Lobby: Cannot open res://data/camp_items/")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path = "res://data/camp_items/" + file_name
			var res = load(path)
			if res is CampItemResource:
				_camp_items.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	_camp_items.sort_custom(func(a, b): return a.display_name < b.display_name)

func _populate_camp_list() -> void:
	for i in range(_camp_items.size()):
		var item = _camp_items[i]
		var btn = Button.new()
		btn.text = item.display_name
		btn.custom_minimum_size = Vector2(150, 32)
		var idx = i
		btn.pressed.connect(func(): _on_camp_item_selected(idx))
		camp_list.add_child(btn)

func _on_camp_item_selected(index: int) -> void:
	_selected_camp_item = _camp_items[index]
	camp_selected_label.text = _selected_camp_item.display_name
	camp_desc.text = _selected_camp_item.description
	_update_start_button()

func _update_start_button() -> void:
	start_button.disabled = not (_selected_class and _selected_camp_item and _selected_dungeon)

func _on_start_pressed() -> void:
	if not _selected_class or not _selected_camp_item or not _selected_dungeon:
		return
	
	# Store selections globally so GameLoop can read them
	_store_class_selection(_selected_class)
	Engine.set_meta("selected_camp_item", _selected_camp_item)
	Engine.set_meta("selected_dungeon", _selected_dungeon)
	
	# Transition to main game scene
	get_tree().change_scene_to_file("res://main.tscn")

func _store_class_selection(cls: ClassData) -> void:
	Engine.set_meta("selected_class", cls)

# --- Dungeon Loading ---

func _load_dungeons() -> void:
	var dir = DirAccess.open("res://data/dungeons/")
	if not dir:
		push_warning("Lobby: Cannot open res://data/dungeons/")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path = "res://data/dungeons/" + file_name
			var res = load(path)
			if res is DungeonData:
				_dungeons.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	_dungeons.sort_custom(func(a, b): return a.difficulty < b.difficulty)

func _populate_dungeon_list() -> void:
	for i in range(_dungeons.size()):
		var dg = _dungeons[i]
		var btn = Button.new()
		var locked = not DungeonProgress.is_unlocked(dg)
		
		var stars = "⭐".repeat(dg.difficulty)
		if locked:
			btn.text = "🔒 %s %s" % [dg.display_name, stars]
			btn.disabled = true
		else:
			btn.text = "%s %s" % [dg.display_name, stars]
			btn.disabled = false
		
		btn.custom_minimum_size = Vector2(200, 36)
		var idx = i
		btn.pressed.connect(func(): _on_dungeon_selected(idx))
		dungeon_list.add_child(btn)

func _on_dungeon_selected(index: int) -> void:
	_selected_dungeon = _dungeons[index]
	dungeon_selected_label.text = _selected_dungeon.display_name
	dungeon_difficulty_label.text = "⭐".repeat(_selected_dungeon.difficulty) + " (%d floors)" % _selected_dungeon.total_floors
	dungeon_desc.text = _selected_dungeon.description
	_update_start_button()
