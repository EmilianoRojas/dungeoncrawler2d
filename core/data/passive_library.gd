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

static func _build() -> void:
	_passives = []
	var dir := DirAccess.open(PASSIVES_DIR)
	if not dir:
		push_error("PassiveLibrary: cannot open '%s'" % PASSIVES_DIR)
		return
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
