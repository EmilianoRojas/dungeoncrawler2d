class_name RuneLibrary
extends Object

static var _runes: Array[RuneResource] = []
static var _built: bool = false

# --- Cost table ---

static func get_cost(tier: RuneResource.Tier) -> int:
	match tier:
		RuneResource.Tier.COMMON:    return 2
		RuneResource.Tier.RARE:      return 4
		RuneResource.Tier.LEGENDARY: return 6
	return 2

# --- Public API ---

static func get_all_runes() -> Array[RuneResource]:
	_ensure_built()
	return _runes

static func get_rune(id: StringName) -> RuneResource:
	_ensure_built()
	for r in _runes:
		if r.id == id:
			return r
	return null

static func get_runes_by_tier(tier: RuneResource.Tier) -> Array[RuneResource]:
	_ensure_built()
	var result: Array[RuneResource] = []
	for r in _runes:
		if r.tier == tier:
			result.append(r)
	return result

# --- Internal ---

static func _ensure_built() -> void:
	if _built:
		return
	_built = true
	_build()

static func _build() -> void:
	_runes = [
		# ── COMMON ──────────────────────────────────────────────────
		_r(&"iron_will",   "Iron Will",   "+5 Max HP",             RuneResource.Tier.COMMON,
			{&"max_hp": 5}),
		_r(&"steady_hand", "Steady Hand", "+3 Accuracy",           RuneResource.Tier.COMMON,
			{&"accuracy": 3}),
		_r(&"tough_skin",  "Tough Skin",  "+2 Defense",            RuneResource.Tier.COMMON,
			{&"defense": 2}),
		_r(&"sharp_edge",  "Sharp Edge",  "+3 Strength",           RuneResource.Tier.COMMON,
			{&"strength": 3}),
		_r(&"quick_feet",  "Quick Feet",  "+2 Speed",              RuneResource.Tier.COMMON,
			{&"speed": 2}),

		# ── RARE ─────────────────────────────────────────────────────
		_r(&"battle_hardened",  "Battle Hardened",  "+8 Max HP, +3 Defense",
			RuneResource.Tier.RARE, {&"max_hp": 8, &"defense": 3}),
		_r(&"assassins_focus",  "Assassin's Focus", "+5 Dexterity, +5 Crit Chance",
			RuneResource.Tier.RARE, {&"dexterity": 5, &"crit_chance": 5}),
		_r(&"arcane_power",     "Arcane Power",     "+6 Intelligence",
			RuneResource.Tier.RARE, {&"intelligence": 6}),
		_r(&"warriors_might",   "Warrior's Might",  "+6 Strength",
			RuneResource.Tier.RARE, {&"strength": 6}),
		_r(&"counter_rune",     "Counter Rune",     "Reduce skill CDs by 1 when taking damage",
			RuneResource.Tier.RARE, {}, &"counter"),
		_r(&"plating_rune",     "Plating Rune",     "+5 Defense (always active)",
			RuneResource.Tier.RARE, {}, &"plating"),

		# ── LEGENDARY ────────────────────────────────────────────────
		_r(&"colossus",         "Colossus",         "+20 Max HP, +5 Defense",
			RuneResource.Tier.LEGENDARY, {&"max_hp": 20, &"defense": 5}),
		_r(&"death_dealer",     "Death Dealer",     "+10 Strength, +10 Crit Chance, +20 Crit Damage",
			RuneResource.Tier.LEGENDARY, {&"strength": 10, &"crit_chance": 10, &"crit_damage": 20}),
		_r(&"archmage",         "Archmage",         "+12 Intelligence, +5 Power",
			RuneResource.Tier.LEGENDARY, {&"intelligence": 12, &"power": 5}),
		_r(&"sniping_rune",     "Sniping Rune",     "+50% Crit Damage multiplier",
			RuneResource.Tier.LEGENDARY, {}, &"sniping"),
		_r(&"first_strike_rune","First Strike Rune","50% chance to reduce all CDs by 1 at battle start",
			RuneResource.Tier.LEGENDARY, {}, &"first_strike"),
	]

static func _r(id: StringName, display_name: String, description: String,
		tier: RuneResource.Tier, stat_bonuses: Dictionary = {},
		passive_id: StringName = &"") -> RuneResource:
	var r := RuneResource.new()
	r.id           = id
	r.display_name = display_name
	r.description  = description
	r.tier         = tier
	r.stat_bonuses = stat_bonuses
	r.passive_id   = passive_id
	return r
