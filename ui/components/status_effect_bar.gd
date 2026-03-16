class_name StatusEffectBar
extends HBoxContainer

# ── Colour palette ────────────────────────────────────────────────────────────
const C_BUFF    := Color(0.25, 0.80, 0.40, 0.90)   # green   – positive effects
const C_DEBUFF  := Color(0.90, 0.30, 0.25, 0.90)   # red     – negative effects
const C_PASSIVE := Color(0.65, 0.45, 0.95, 0.90)   # purple  – passive procs
const C_NEUTRAL := Color(0.55, 0.65, 0.80, 0.90)   # blue    – no clear polarity

# effect_id → emoji/short label for display
const ICONS: Dictionary = {
	# Debuffs
	"burn":        "🔥",
	"poison":      "☠",
	"slow":        "🐌",
	"weaken":      "💔",
	"blind":       "👁",
	"stun":        "⚡",
	"bleed":       "🩸",
	# Buffs
	"iron_skin":   "🛡",
	"rage":        "💢",
	"regen":       "💚",
	"shield":      "🔰",
	"haste":       "💨",
	"lifesteal":   "🧛",
	"empower":     "⬆",
	# Neutral / misc
	"observe":     "🔍",
}

# effect_id prefixes / keywords that determine polarity
const DEBUFF_KEYWORDS := ["burn","poison","slow","weaken","blind","stun","bleed","dot","curse","reduce"]
const BUFF_KEYWORDS   := ["iron","rage","regen","shield","haste","life","empower","stealth","armor","strength"]

# ── State ─────────────────────────────────────────────────────────────────────
var _effect_cells: Dictionary = {}  # effect_id → Control node
var _passive_cells: Dictionary = {} # passive_id → Control node

# ── Setup ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_theme_constant_override("separation", 3)

# ══════════════════════════════════════════════════════════════════════════════
## Refresh the bar from an Entity's current state.
func refresh(entity: Entity) -> void:
	if not entity:
		_clear_all()
		return

	# ── Active timed effects (EffectManager) ──────────────────────────────────
	var seen_effects: Array[StringName] = []
	if entity.effects:
		for inst: EffectInstance in entity.effects.effects:
			var eid: StringName = inst.resource.effect_id
			seen_effects.append(eid)
			if _effect_cells.has(eid):
				_update_effect_cell(_effect_cells[eid], inst)
			else:
				var cell := _make_effect_cell(inst)
				add_child(cell)
				_effect_cells[eid] = cell

	# Remove cells for expired effects
	for eid in _effect_cells.keys():
		if not seen_effects.has(eid):
			_effect_cells[eid].queue_free()
			_effect_cells.erase(eid)

	# ── Active passives (PassiveEffectComponent) ──────────────────────────────
	var seen_passives: Array[StringName] = []
	if entity.passives:
		for entry in entity.passives.active_passives:
			var p: PassiveEffect = entry.get("passive")
			if not p: continue
			var pid: StringName = p.id
			seen_passives.append(pid)
			if not _passive_cells.has(pid):
				var cell := _make_passive_cell(p)
				add_child(cell)
				_passive_cells[pid] = cell

	for pid in _passive_cells.keys():
		if not seen_passives.has(pid):
			_passive_cells[pid].queue_free()
			_passive_cells.erase(pid)

# ══════════════════════════════════════════════════════════════════════════════
## Clear everything (e.g. when battle ends / entity changes).
func clear() -> void:
	_clear_all()

# ── Internal helpers ──────────────────────────────────────────────────────────
func _clear_all() -> void:
	for c in get_children():
		c.queue_free()
	_effect_cells.clear()
	_passive_cells.clear()

func _make_effect_cell(inst: EffectInstance) -> Control:
	var eid: StringName = inst.resource.effect_id
	var color := _effect_color(str(eid))

	var panel := PanelContainer.new()
	panel.name = "FX_" + str(eid)
	var sty := StyleBoxFlat.new()
	sty.bg_color = color * Color(1, 1, 1, 0.20)
	sty.border_color = color
	sty.set_border_width_all(1)
	sty.set_corner_radius_all(4)
	sty.content_margin_left  = 4
	sty.content_margin_right = 4
	sty.content_margin_top   = 2
	sty.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", sty)
	panel.tooltip_text = _effect_tooltip(inst)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	panel.add_child(vb)

	# Icon / short label
	var icon_lbl := Label.new()
	icon_lbl.name = "Icon"
	icon_lbl.text = _effect_icon(str(eid))
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 14)
	icon_lbl.add_theme_color_override("font_color", color)
	vb.add_child(icon_lbl)

	# Timer / stacks row
	var sub := Label.new()
	sub.name = "Sub"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 9)
	sub.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_set_sub_text(sub, inst)
	vb.add_child(sub)

	return panel

func _update_effect_cell(cell: Control, inst: EffectInstance) -> void:
	var sub := cell.get_node_or_null("PanelContainer/VBoxContainer/Sub") if cell is Control else null
	# Direct child path when cell IS the PanelContainer
	if not sub:
		sub = cell.find_child("Sub", true, false)
	if sub:
		_set_sub_text(sub, inst)
	cell.tooltip_text = _effect_tooltip(inst)

func _set_sub_text(lbl: Label, inst: EffectInstance) -> void:
	var parts: Array[String] = []
	if inst.stacks > 1:
		parts.append("x%d" % inst.stacks)
	if inst.remaining_turns > 0:
		parts.append("%dt" % inst.remaining_turns)
	elif inst.remaining_turns == -1:
		parts.append("∞")
	lbl.text = " ".join(parts)

func _make_passive_cell(p: PassiveEffect) -> Control:
	var panel := PanelContainer.new()
	panel.name = "PA_" + str(p.id)
	var sty := StyleBoxFlat.new()
	sty.bg_color = C_PASSIVE * Color(1, 1, 1, 0.15)
	sty.border_color = C_PASSIVE
	sty.set_border_width_all(1)
	sty.set_corner_radius_all(4)
	sty.content_margin_left  = 4
	sty.content_margin_right = 4
	sty.content_margin_top   = 2
	sty.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", sty)
	panel.tooltip_text = "%s\n%s" % [p.passive_name, p.description]

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	panel.add_child(vb)

	var icon_lbl := Label.new()
	icon_lbl.text = _passive_icon(p)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 14)
	icon_lbl.add_theme_color_override("font_color", C_PASSIVE)
	vb.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = p.passive_name.left(4) if p.passive_name.length() > 4 else p.passive_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 8)
	name_lbl.add_theme_color_override("font_color", Color(0.75, 0.65, 0.95))
	vb.add_child(name_lbl)

	return panel

# ── Utility ───────────────────────────────────────────────────────────────────
func _effect_icon(eid: String) -> String:
	if ICONS.has(eid): return ICONS[eid]
	# Fallback: first 2 chars uppercased
	return eid.substr(0, 2).to_upper()

func _passive_icon(p: PassiveEffect) -> String:
	if ICONS.has(p.id): return ICONS[p.id]
	return "✦"

func _effect_color(eid: String) -> Color:
	var lower := eid.to_lower()
	for kw in DEBUFF_KEYWORDS:
		if lower.contains(kw): return C_DEBUFF
	for kw in BUFF_KEYWORDS:
		if lower.contains(kw): return C_BUFF
	return C_NEUTRAL

func _effect_tooltip(inst: EffectInstance) -> String:
	var lines: Array[String] = []
	lines.append(str(inst.resource.effect_id).capitalize().replace("_", " "))
	if inst.stacks > 1:
		lines.append("Stacks: %d" % inst.stacks)
	if inst.remaining_turns > 0:
		lines.append("Turns left: %d" % inst.remaining_turns)
	elif inst.remaining_turns == -1:
		lines.append("Duration: permanent")
	return "\n".join(lines)
