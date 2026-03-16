class_name StatusEffectBar
extends HBoxContainer

# ── Colour palette ────────────────────────────────────────────────────────────
const C_BUFF    := Color(0.25, 0.85, 0.40)
const C_DEBUFF  := Color(0.95, 0.30, 0.25)
const C_PASSIVE := Color(0.70, 0.50, 1.00)
const C_NEUTRAL := Color(0.50, 0.70, 0.90)

# ASCII short labels for known effect IDs (no emoji)
const LABELS: Dictionary = {
	"burn":        "BRN",
	"poison":      "PSN",
	"slow":        "SLW",
	"weaken":      "WKN",
	"blind":       "BLD",
	"stun":        "STN",
	"bleed":       "BLD",
	"iron_skin":   "ARM",
	"rage":        "RAG",
	"regen":       "REG",
	"shield":      "SHD",
	"haste":       "HST",
	"lifesteal":   "LFS",
	"empower":     "EMP",
	"observe":     "OBS",
	"counter":     "CTR",
	"momentum":    "MOM",
	"shadow_step": "SHD",
	"first_strike":"FST",
	"sniping":     "SNP",
	"plating":     "PLT",
}

const DEBUFF_KEYWORDS := ["burn","poison","slow","weaken","blind","stun","bleed","dot","curse","reduce","damage_over"]
const BUFF_KEYWORDS   := ["iron","rage","regen","shield","haste","life","empower","stealth","armor","strength","counter","momentum","first","snip","plat"]

# ── State ─────────────────────────────────────────────────────────────────────
var _effect_cells:  Dictionary = {}
var _passive_cells: Dictionary = {}

func _ready() -> void:
	add_theme_constant_override("separation", 2)

# ══════════════════════════════════════════════════════════════════════════════
func refresh(entity: Entity) -> void:
	if not entity:
		_clear_all()
		return

	# ── Timed effects ─────────────────────────────────────────────────────────
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

	for eid in _effect_cells.keys():
		if not seen_effects.has(eid):
			_effect_cells[eid].queue_free()
			_effect_cells.erase(eid)

	# ── Passive effects ───────────────────────────────────────────────────────
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

func clear() -> void:
	_clear_all()

# ── Cell builders ─────────────────────────────────────────────────────────────
func _make_effect_cell(inst: EffectInstance) -> PanelContainer:
	var eid  := str(inst.resource.effect_id)
	var col  := _effect_color(eid)
	var cell := _base_panel(col)
	cell.name = "FX_" + eid
	cell.tooltip_text = _effect_tooltip(inst)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	cell.add_child(vb)

	var lbl := Label.new()
	lbl.name  = "Icon"
	lbl.text  = _effect_label(eid)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", col)
	vb.add_child(lbl)

	var sub := Label.new()
	sub.name = "Sub"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 9)
	sub.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_set_sub_text(sub, inst)
	vb.add_child(sub)

	return cell

func _make_passive_cell(p: PassiveEffect) -> PanelContainer:
	var cell := _base_panel(C_PASSIVE)
	cell.name = "PA_" + str(p.id)
	cell.tooltip_text = p.passive_name + "\n" + p.description

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	cell.add_child(vb)

	var lbl := Label.new()
	lbl.text = _passive_label(p)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", C_PASSIVE)
	vb.add_child(lbl)

	var name_lbl := Label.new()
	var short := p.passive_name.substr(0, 3).to_upper() if p.passive_name.length() >= 3 else p.passive_name.to_upper()
	name_lbl.text = short
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 8)
	name_lbl.add_theme_color_override("font_color", Color(0.80, 0.70, 1.00))
	vb.add_child(name_lbl)

	return cell

func _update_effect_cell(cell: Control, inst: EffectInstance) -> void:
	var sub: Label = cell.find_child("Sub", true, false)
	if sub:
		_set_sub_text(sub, inst)
	cell.tooltip_text = _effect_tooltip(inst)

func _set_sub_text(lbl: Label, inst: EffectInstance) -> void:
	var parts: PackedStringArray = []
	if inst.stacks > 1:
		parts.append("x%d" % inst.stacks)
	if inst.remaining_turns > 0:
		parts.append("%dt" % inst.remaining_turns)
	elif inst.remaining_turns == -1:
		parts.append("inf")
	lbl.text = " ".join(parts)

# ── Style helpers ─────────────────────────────────────────────────────────────
func _base_panel(col: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(32, 32)
	var sty := StyleBoxFlat.new()
	sty.bg_color = col * Color(1, 1, 1, 0.18)
	sty.border_color = col
	sty.set_border_width_all(1)
	sty.set_corner_radius_all(4)
	sty.content_margin_left   = 3
	sty.content_margin_right  = 3
	sty.content_margin_top    = 2
	sty.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", sty)
	return panel

func _effect_label(eid: String) -> String:
	if LABELS.has(eid): return LABELS[eid]
	return eid.substr(0, 3).to_upper()

func _passive_label(p: PassiveEffect) -> String:
	if LABELS.has(p.id): return LABELS[p.id]
	return str(p.id).substr(0, 3).to_upper()

func _effect_color(eid: String) -> Color:
	var lower := eid.to_lower()
	for kw in DEBUFF_KEYWORDS:
		if lower.contains(kw): return C_DEBUFF
	for kw in BUFF_KEYWORDS:
		if lower.contains(kw): return C_BUFF
	return C_NEUTRAL

func _effect_tooltip(inst: EffectInstance) -> String:
	var parts: PackedStringArray = []
	parts.append(str(inst.resource.effect_id).capitalize().replace("_", " "))
	if inst.stacks > 1:
		parts.append("Stacks: %d" % inst.stacks)
	if inst.remaining_turns > 0:
		parts.append("Turns left: %d" % inst.remaining_turns)
	elif inst.remaining_turns == -1:
		parts.append("Permanent")
	return "\n".join(parts)

# ── Cleanup ───────────────────────────────────────────────────────────────────
func _clear_all() -> void:
	for c in get_children():
		c.queue_free()
	_effect_cells.clear()
	_passive_cells.clear()
