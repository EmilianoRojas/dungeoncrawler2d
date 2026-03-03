## BattleTest — standalone scene for testing skills and core battle loop.
## Pick a class, an enemy, and a floor level, then fight.
## No dungeon, no progression — pure combat sandbox.
class_name BattleTest
extends Node

# ── Scenes ──────────────────────────────────────────────────────────────────
const UI_SCENE := preload("res://ui/game_ui.tscn")

# ── Class data ───────────────────────────────────────────────────────────────
const CLASSES: Dictionary = {
	"Warrior":   "res://data/classes/warrior.tres",
	"Wizard":    "res://data/classes/wizard.tres",
	"Rogue":     "res://data/classes/rogue.tres",
	"Ranger":    "res://data/classes/ranger.tres",
	"Cleric":    "res://data/classes/cleric.tres",
	"Berserker": "res://data/classes/berserker.tres",
	"Shaman":    "res://data/classes/shaman.tres",
	"Paladin":   "res://data/classes/paladin.tres",
}

# ── Enemy templates ──────────────────────────────────────────────────────────
const ENEMIES: Dictionary = {
	"Goblin":      "res://data/enemies/goblin.tres",
	"Skeleton":    "res://data/enemies/skeleton.tres",
	"Slime":       "res://data/enemies/slime.tres",
	"Bat":         "res://data/enemies/bat.tres",
	"Dark Knight": "res://data/enemies/dark_knight.tres",
	"Wraith":      "res://data/enemies/wraith.tres",
	"Dragon":      "res://data/enemies/dragon.tres",
	"Demon Lord":  "res://data/enemies/demon_lord.tres",
}

# ── State ────────────────────────────────────────────────────────────────────
var _game_ui: GameUI
var _turn_manager: TurnManager
var _passive_resolver: PassiveResolver
var _player: Entity
var _enemy: Entity

var _selected_class: String  = "Warrior"
var _selected_enemy: String  = "Goblin"
var _selected_floor: int     = 1

var _picker_root: Control   # the picker overlay
var _in_battle: bool        = false

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_picker()

func _build_picker() -> void:
	# Full-screen overlay
	_picker_root = Control.new()
	_picker_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_picker_root)

	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.07, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_picker_root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_picker_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.16, 0.97)
	style.border_color = Color(0.4, 0.6, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left   = 24
	style.content_margin_right  = 24
	style.content_margin_top    = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "⚔ Battle Test"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Class picker
	_add_section_label(vbox, "Class")
	var class_opts := OptionButton.new()
	class_opts.custom_minimum_size = Vector2(0, 36)
	for c in CLASSES.keys():
		class_opts.add_item(c)
	class_opts.selected = 0
	class_opts.item_selected.connect(func(i): _selected_class = CLASSES.keys()[i])
	vbox.add_child(class_opts)

	# Enemy picker
	_add_section_label(vbox, "Enemy")
	var enemy_opts := OptionButton.new()
	enemy_opts.custom_minimum_size = Vector2(0, 36)
	for e in ENEMIES.keys():
		enemy_opts.add_item(e)
	enemy_opts.selected = 0
	enemy_opts.item_selected.connect(func(i): _selected_enemy = ENEMIES.keys()[i])
	vbox.add_child(enemy_opts)

	# Floor slider
	_add_section_label(vbox, "Floor (1–10)")
	var floor_row := HBoxContainer.new()
	floor_row.add_theme_constant_override("separation", 10)
	vbox.add_child(floor_row)

	var floor_slider := HSlider.new()
	floor_slider.min_value = 1
	floor_slider.max_value = 10
	floor_slider.step = 1
	floor_slider.value = 1
	floor_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	floor_row.add_child(floor_slider)

	var floor_val_lbl := Label.new()
	floor_val_lbl.text = "1"
	floor_val_lbl.custom_minimum_size = Vector2(20, 0)
	floor_row.add_child(floor_val_lbl)
	floor_slider.value_changed.connect(func(v):
		_selected_floor = int(v)
		floor_val_lbl.text = str(int(v))
	)

	vbox.add_child(HSeparator.new())

	# Start button
	var start_btn := Button.new()
	start_btn.text = "▶  Start Battle"
	start_btn.custom_minimum_size = Vector2(0, 46)
	start_btn.pressed.connect(_start_battle)
	vbox.add_child(start_btn)

	# Back to lobby
	var lobby_btn := Button.new()
	lobby_btn.text = "← Back to Lobby"
	lobby_btn.custom_minimum_size = Vector2(0, 36)
	lobby_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://ui/lobby.tscn")
	)
	vbox.add_child(lobby_btn)

func _add_section_label(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.75, 1.0))
	parent.add_child(lbl)

# ── Battle ────────────────────────────────────────────────────────────────────

func _start_battle() -> void:
	if _in_battle:
		return
	_in_battle = true

	# Hide picker
	_picker_root.visible = false

	# ── Player ──
	_player = Entity.new()
	_player.name = "Player"
	_player.team = Entity.Team.PLAYER
	_player.initialize()

	var class_data := load(CLASSES[_selected_class]) as ClassData
	if class_data:
		_player.apply_class(class_data)

	# ── Enemy ──
	var template := load(ENEMIES[_selected_enemy]) as EnemyTemplate
	_enemy = EnemyFactory.create_enemy(template, _selected_floor)

	# ── UI ──
	_game_ui = UI_SCENE.instantiate()
	add_child(_game_ui)
	_game_ui.set_player_ref(_player)
	_game_ui.skill_activated.connect(_on_skill_activated)
	_game_ui.wait_turn_pressed.connect(_on_wait_turn)

	# ── Systems ──
	_passive_resolver = PassiveResolver.new()
	add_child(_passive_resolver)
	GlobalEventBus.subscribe("combat_log", _on_combat_log)
	GlobalEventBus.subscribe("damage_dealt", _game_ui.vfx_manager.on_damage_dealt)
	GlobalEventBus.subscribe("entity_died",  _game_ui.vfx_manager.on_entity_died)
	GlobalEventBus.subscribe("parry_success", _game_ui.vfx_manager.on_parry_success)
	GlobalEventBus.subscribe("avoid_success", _game_ui.vfx_manager.on_avoid_success)
	GlobalEventBus.subscribe("heal_applied",  _game_ui.vfx_manager.on_heal_applied)
	GlobalEventBus.subscribe("skill_miss",    _game_ui.vfx_manager.on_skill_miss)

	_passive_resolver.register(_player)
	_passive_resolver.register(_enemy)

	_turn_manager = TurnManager.new()
	add_child(_turn_manager)
	_turn_manager.vfx_manager = _game_ui.vfx_manager
	_turn_manager.phase_changed.connect(_on_phase_changed)
	_turn_manager.turn_processing_end.connect(_on_turn_end)
	_turn_manager.battle_ended.connect(_on_battle_ended)

	GlobalEventBus.dispatch("battle_start", {
		"player": _player,
		"source": _player,
		"target": _enemy,
		"enemies": [_enemy],
	})

	_turn_manager.start_battle(_player, [_enemy])
	_game_ui.initialize_battle(_player, [_enemy])
	_game_ui.set_mode(true)

	_game_ui.add_log("=== BATTLE TEST ===")
	_game_ui.add_log("%s (Lv %d) vs %s  [Floor %d]" % [
		_selected_class, _player.level, _selected_enemy, _selected_floor])

func _on_skill_activated(skill: Skill) -> void:
	if not _player.skills.is_skill_ready(skill):
		_game_ui.add_log("⏳ %s on cooldown (%d)" % [skill.skill_name, _player.skills.cooldowns.get(skill, 0)])
		return
	var target := _turn_manager.get_first_alive_enemy()
	if not target:
		return
	var action := AttackAction.new(_player, target)
	action.skill_reference = skill
	_player.skills.put_on_cooldown(skill)
	_game_ui.update_skill_cooldowns(_player)
	_turn_manager.submit_player_action(action)

func _on_wait_turn() -> void:
	_game_ui.add_log("⏳ Waiting...")
	_turn_manager.submit_player_action(null)

func _on_phase_changed(phase: TurnManager.Phase) -> void:
	_game_ui.set_turn_phase(phase)

func _on_turn_end() -> void:
	_game_ui.update_skill_cooldowns(_player)

func _on_combat_log(data: Dictionary) -> void:
	var msg: String = data.get("message", "")
	if msg != "":
		_game_ui.add_log(msg)

func _on_battle_ended(result: TurnManager.Phase) -> void:
	var msg := "Victory! 🏆" if result == TurnManager.Phase.WIN else "Defeated. 💀"
	_game_ui.add_log(msg)
	_game_ui.add_log("— Press Restart to fight again —")
	_cleanup_battle()
	_show_result_buttons(result)

func _cleanup_battle() -> void:
	GlobalEventBus.unsubscribe("combat_log", _on_combat_log)
	if _game_ui and _game_ui.vfx_manager:
		GlobalEventBus.unsubscribe("damage_dealt", _game_ui.vfx_manager.on_damage_dealt)
		GlobalEventBus.unsubscribe("entity_died",  _game_ui.vfx_manager.on_entity_died)
		GlobalEventBus.unsubscribe("parry_success", _game_ui.vfx_manager.on_parry_success)
		GlobalEventBus.unsubscribe("avoid_success", _game_ui.vfx_manager.on_avoid_success)
		GlobalEventBus.unsubscribe("heal_applied",  _game_ui.vfx_manager.on_heal_applied)
		GlobalEventBus.unsubscribe("skill_miss",    _game_ui.vfx_manager.on_skill_miss)
	GlobalEventBus.reset()
	_in_battle = false

func _show_result_buttons(result: TurnManager.Phase) -> void:
	var overlay := CenterContainer.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_ui.add_child(overlay)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_child(vbox)

	var result_lbl := Label.new()
	result_lbl.text = "🏆 Victory!" if result == TurnManager.Phase.WIN else "💀 Defeated"
	result_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_lbl.add_theme_font_size_override("font_size", 28)
	result_lbl.add_theme_color_override("font_color",
		Color(0.4, 1.0, 0.5) if result == TurnManager.Phase.WIN else Color(1.0, 0.35, 0.35))
	vbox.add_child(result_lbl)

	var restart_btn := Button.new()
	restart_btn.text = "🔄 Restart"
	restart_btn.custom_minimum_size = Vector2(180, 46)
	restart_btn.pressed.connect(_restart)
	vbox.add_child(restart_btn)

	var lobby_btn := Button.new()
	lobby_btn.text = "← Back to Lobby"
	lobby_btn.custom_minimum_size = Vector2(180, 36)
	lobby_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://ui/lobby.tscn")
	)
	vbox.add_child(lobby_btn)

func _restart() -> void:
	# Tear down everything and re-show the picker
	if _game_ui:
		_game_ui.queue_free()
		_game_ui = null
	if _turn_manager:
		_turn_manager.queue_free()
		_turn_manager = null
	if _passive_resolver:
		_passive_resolver.queue_free()
		_passive_resolver = null
	_player = null
	_enemy  = null
	GlobalEventBus.reset()
	_picker_root.visible = true
