class_name VFXManager
extends Control

signal impact_reached     # emitted when vfx_impact_frame is reached
signal animation_finished # emitted when the full spritesheet animation is done

var _active_tweens: Array[Tween] = []
var _active_overlays: Array[Node] = []

var _sprites: Dictionary = {}         # Entity -> TextureRect
var _panels: Dictionary = {}          # Entity -> Control (used for floater positioning)
var _flash_materials: Dictionary = {}  # Entity -> ShaderMaterial
var _game_ui: Control

const SPRITE_SHADER = preload("res://ui/shaders/sprite.gdshader")

func setup(game_ui: Control) -> void:
	_game_ui = game_ui
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE

func clear_entities() -> void:
	_sprites.clear()
	_panels.clear()
	_flash_materials.clear()

func register_entity(entity: Entity, sprite: TextureRect, panel: Control) -> void:
	_sprites[entity] = sprite
	_panels[entity] = panel
	# Attach shader for hit flash + idle scale pulse
	var mat := ShaderMaterial.new()
	mat.shader = SPRITE_SHADER
	mat.set_shader_parameter("flash_amount", 0.0)
	sprite.material = mat
	_flash_materials[entity] = mat

# Called by TurnManager before processing each action.
# If skill has a spritesheet, plays the animation and emits impact_reached at the right frame.
# If not, falls back to color flash. Returns total animation duration (for post-anim wait).
func play_cast_vfx(action: Action) -> float:
	if not action:
		return 0.0
	var skill = action.get("skill_reference") as Skill
	if not skill:
		return 0.0

	# Flash caster sprite always
	var source = action.source
	if source and _sprites.has(source):
		_flash_modulate(_sprites[source], skill.vfx_color, 0.25)

	# Spritesheet animation
	if skill.vfx_spritesheet:
		var target_entity = action.get("target") if skill.vfx_on_target else source
		var target_panel: Control = _panels.get(target_entity)
		if target_panel:
			_play_spritesheet(skill, target_panel)
			# Total duration of the animation
			var frame_count = _get_frame_count(skill)
			return frame_count / skill.vfx_fps
		return skill.get_impact_delay()

	# Fallback: use impact frame timing without animation
	return skill.get_impact_delay()

func _get_frame_count(skill: Skill) -> int:
	if not skill.vfx_spritesheet:
		return 0
	var sheet_width = skill.vfx_spritesheet.get_width()
	return sheet_width / skill.vfx_frame_size.x

func _play_spritesheet(skill: Skill, panel: Control) -> void:
	var frame_count := _get_frame_count(skill)
	if frame_count <= 0:
		return

	var frame_duration := 1.0 / skill.vfx_fps
	var size := Vector2(skill.vfx_frame_size)

	# Pre-build all atlas frames
	var frames: Array[AtlasTexture] = []
	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = skill.vfx_spritesheet
		atlas.region = Rect2(i * skill.vfx_frame_size.x, 0, skill.vfx_frame_size.x, skill.vfx_frame_size.y)
		frames.append(atlas)

	# Create overlay TextureRect — size must be set explicitly (not inside a Container)
	var tex_rect := TextureRect.new()
	tex_rect.size = size
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_rect.z_index = 100
	tex_rect.texture = frames[0]
	add_child(tex_rect)

	# Position centered over panel (global rect matches VFXManager's local space)
	var panel_center := panel.get_global_rect().get_center()
	tex_rect.position = panel_center - size / 2.0

	_active_overlays.append(tex_rect)

	# Sequential tween: advance one frame at a time
	var tween := create_tween()
	_active_tweens.append(tween)
	for i in range(frame_count):
		var fi := i
		tween.tween_callback(func():
			if is_instance_valid(tex_rect):
				tex_rect.texture = frames[fi]
			if fi == skill.vfx_impact_frame:
				impact_reached.emit()
		).set_delay(0.0 if i == 0 else frame_duration)

	# Fade out after last frame, then clean up
	tween.tween_property(tex_rect, "modulate:a", 0.0, frame_duration * 0.5)
	tween.tween_callback(func():
		_active_tweens.erase(tween)
		_active_overlays.erase(tex_rect)
		animation_finished.emit()
		if is_instance_valid(tex_rect):
			tex_rect.queue_free()
	)

# --- EventBus subscribers ---

func on_damage_dealt(data: Dictionary) -> void:
	var target = data.get("target")
	var damage: int = data.get("damage", 0)
	var is_crit: bool = data.get("is_crit", false)

	# Animated HP bar update
	if target and target.get("team") != null:
		var is_player = (target.team == Entity.Team.PLAYER)
		_game_ui.update_hp(target, is_player)

	if not target:
		return

	var target_sprite: TextureRect = _sprites.get(target)
	var target_panel: Control = _panels.get(target)

	if is_crit:
		if target_sprite:
			_flash_modulate(target_sprite, Color(1, 0.85, 0), 0.35)
			_pulse_scale(target_sprite, 1.2, 0.35)
		if target_panel:
			_spawn_floater(target_panel, "⚡-%d CRIT!" % damage, Color(1, 0.85, 0.1))
	else:
		if target and _flash_materials.has(target):
			_shader_double_flash(_flash_materials[target], 0.12)
		if target_panel:
			_spawn_floater(target_panel, "-%d" % damage, Color(1, 0.35, 0.35))

func on_entity_died(data: Dictionary) -> void:
	var entity = data.get("entity")
	if entity and _sprites.has(entity):
		var sprite: TextureRect = _sprites[entity]
		if is_instance_valid(sprite):
			var tween = create_tween()
			tween.tween_property(sprite, "modulate", Color(1, 0.2, 0.2, 0.5), 0.4)
	_screen_flash(Color(1, 0, 0), 0.35, 0.5)

func on_parry_success(data: Dictionary) -> void:
	var entity = data.get("entity")
	if entity and _sprites.has(entity):
		_flash_modulate(_sprites[entity], Color(0, 1, 1), 0.4)
	if entity and _panels.has(entity):
		_spawn_floater(_panels[entity], "PARRY!", Color(0, 0.9, 1))

func on_avoid_success(data: Dictionary) -> void:
	var entity = data.get("entity")
	if entity and _sprites.has(entity):
		_flash_modulate(_sprites[entity], Color(0.8, 0.8, 1.0), 0.4)
	if entity and _panels.has(entity):
		_spawn_floater(_panels[entity], "DODGE!", Color(0.8, 0.8, 1.0))

func on_heal_applied(data: Dictionary) -> void:
	var source = data.get("source")
	var amount: int = data.get("amount", 0)
	if source and _sprites.has(source):
		_flash_modulate(_sprites[source], Color(0.3, 1, 0.4), 0.4)
	if source and _panels.has(source):
		_spawn_floater(_panels[source], "+%d HP" % amount, Color(0.3, 1, 0.4))
	# Animated HP bar update
	if source and source.get("team") != null:
		var is_player = (source.team == Entity.Team.PLAYER)
		_game_ui.update_hp(source, is_player)

func on_skill_miss(data: Dictionary) -> void:
	var source = data.get("source")
	if source and _panels.has(source):
		_spawn_floater(_panels[source], "MISS", Color(0.65, 0.65, 0.65))

# --- VFX Primitives ---

func _flash_modulate(node: CanvasItem, color: Color, duration: float) -> void:
	if not is_instance_valid(node):
		return
	var original = node.modulate
	var tween = create_tween()
	tween.tween_property(node, "modulate", color, duration * 0.35)
	tween.tween_property(node, "modulate", original, duration * 0.65)

func _shader_double_flash(mat: ShaderMaterial, duration: float) -> void:
	if not mat:
		return
	var tween := create_tween()
	tween.tween_method(func(v: float): mat.set_shader_parameter("flash_amount", v), 0.0, 1.0, duration * 0.25)
	tween.tween_method(func(v: float): mat.set_shader_parameter("flash_amount", v), 1.0, 0.0, duration * 0.25)
	tween.tween_method(func(v: float): mat.set_shader_parameter("flash_amount", v), 0.0, 1.0, duration * 0.25)
	tween.tween_method(func(v: float): mat.set_shader_parameter("flash_amount", v), 1.0, 0.0, duration * 0.25)

func _pulse_scale(node: Control, factor: float, duration: float) -> void:
	if not is_instance_valid(node):
		return
	var original_scale = node.scale
	var tween = create_tween()
	tween.tween_property(node, "scale", original_scale * factor, duration * 0.4)
	tween.tween_property(node, "scale", original_scale, duration * 0.6)

func _spawn_floater(panel: Control, text: String, color: Color) -> void:
	if not is_instance_valid(panel):
		return
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 18)
	label.z_index = 10
	add_child(label)

	# Position at center-top of the panel
	var panel_rect = panel.get_global_rect()
	var start_x = panel_rect.get_center().x - 40
	var start_y = panel_rect.position.y + panel_rect.size.y * 0.25
	label.position = Vector2(start_x, start_y)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", start_y - 50.0, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)

## Cancel all active animations immediately (call on battle end).
## Clears overlays and emits animation_finished so any pending awaits resolve.
func cancel_vfx() -> void:
	for tween in _active_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_active_tweens.clear()
	for overlay in _active_overlays:
		if is_instance_valid(overlay):
			overlay.queue_free()
	_active_overlays.clear()
	animation_finished.emit()

func _screen_flash(color: Color, alpha: float, duration: float) -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(color.r, color.g, color.b, alpha)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 100
	add_child(overlay)

	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, duration)
	tween.tween_callback(overlay.queue_free)
