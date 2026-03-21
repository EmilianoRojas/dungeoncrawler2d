class_name PassiveLibrary
extends Object

const PASSIVES_DIR := "res://data/passives/"

static var _passives: Array[PassiveEffect] = []
static var _built: bool = false

static func get_passive(id: StringName) -> PassiveEffect:
	_ensure_built()
	for p in _passives:
		if p.id == id:
			return p
	return null

static func get_all() -> Array[PassiveEffect]:
	_ensure_built()
	return _passives

static func get_all_ids() -> Array[StringName]:
	_ensure_built()
	var ids: Array[StringName] = []
	for p in _passives:
		ids.append(p.id)
	return ids

static func _ensure_built() -> void:
	if _built: return
	_built = true
	_build()

## ⚠️  ADDING A NEW PASSIVE: create data/passives/your_passive.tres and add
##    its path to PASSIVE_PATHS below (Android can't enumerate PCK dirs).
const PASSIVE_PATHS: Array[String] = [
	"res://data/passives/avoid_critical.tres",
	"res://data/passives/bloodlust.tres",
	"res://data/passives/counter.tres",
	"res://data/passives/damage_reduce.tres",
	"res://data/passives/divine_retribution.tres",
	"res://data/passives/first_strike.tres",
	"res://data/passives/hard_shield.tres",
	"res://data/passives/momentum.tres",
	"res://data/passives/observation.tres",
	"res://data/passives/plating.tres",
	"res://data/passives/poisonous.tres",
	"res://data/passives/shadow_step.tres",
	"res://data/passives/sniping.tres",
	"res://data/passives/super_strength.tres",
	"res://data/passives/supply_route.tres",
	"res://data/passives/swordmanship.tres",
	"res://data/passives/technique.tres",
	"res://data/passives/toxin_mastery.tres",
	"res://data/passives/weaken.tres",
]

static func _build() -> void:
	_passives = []

	var dir := DirAccess.open(PASSIVES_DIR)
	if dir:
		dir.list_dir_begin()
		var file := dir.get_next()
		while file != "":
			if file.ends_with(".tres"):
				var p := load(PASSIVES_DIR + file) as PassiveEffect
				if p:
					_passives.append(p)
				else:
					push_warning("PassiveLibrary: failed to load '%s'" % file)
			file = dir.get_next()
		dir.list_dir_end()

	if _passives.is_empty():
		for path in PASSIVE_PATHS:
			var p := load(path) as PassiveEffect
			if p:
				_passives.append(p)
			else:
				push_warning("PassiveLibrary: fallback load failed for '%s'" % path)

	if _passives.is_empty():
		push_error("PassiveLibrary: No passives loaded!")
