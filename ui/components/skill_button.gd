class_name SkillButton
extends Button

signal tooltip_requested(skill: Skill, global_pos: Vector2)

const HOLD_SECONDS := 0.40

var skill_reference: Skill
var _interactable: bool = true

var _cd_label: Label
var _hold_timer: Timer

func _ready() -> void:
	_hold_timer = Timer.new()
	_hold_timer.wait_time = HOLD_SECONDS
	_hold_timer.one_shot = true
	_hold_timer.timeout.connect(_on_hold_timeout)
	add_child(_hold_timer)

func setup(skill: Skill) -> void:
	skill_reference = skill
	custom_minimum_size = Vector2(72, 72)
	clip_contents = false

	if skill.icon:
		icon = skill.icon
		expand_icon = true
		text = ""
	else:
		text = skill.skill_name.left(4).to_upper()
		add_theme_font_size_override("font_size", 12)

	# ── Cooldown badge (full-rect overlay, hidden when ready) ─────────────────
	_cd_label = Label.new()
	_cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cd_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_cd_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cd_label.add_theme_font_size_override("font_size", 22)
	_cd_label.add_theme_color_override("font_color", Color.WHITE)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(4)
	_cd_label.add_theme_stylebox_override("normal", bg)
	_cd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cd_label.visible = false
	add_child(_cd_label)

func update_cooldown(current_cd: int) -> void:
	if not skill_reference:
		return
	if current_cd > 0:
		disabled = true
		modulate = Color(0.45, 0.45, 0.55, 1.0)
		if _cd_label:
			_cd_label.text = str(current_cd)
			_cd_label.visible = true
	else:
		# Only re-enable if the turn system also allows interaction
		disabled = not _interactable
		modulate = Color.WHITE if _interactable else Color(0.6, 0.6, 0.6, 1.0)
		if _cd_label:
			_cd_label.visible = false

func set_interactable(enabled: bool) -> void:
	_interactable = enabled
	# Only touch disabled if not already locked by a cooldown
	var on_cd = skill_reference and _cd_label and _cd_label.visible
	if not on_cd:
		disabled = not enabled
		modulate = Color.WHITE if enabled else Color(0.6, 0.6, 0.6, 1.0)

# ── Long-press detection ───────────────────────────────────────────────────────
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_hold_timer.start()
			else:
				_hold_timer.stop()
	elif event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_hold_timer.start()
		else:
			_hold_timer.stop()

func _on_hold_timeout() -> void:
	if skill_reference:
		tooltip_requested.emit(skill_reference, global_position)
