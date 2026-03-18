class_name ItemLibrary
extends Object

# Loads all EquipmentResource templates from res://data/items/
# Add a new item by creating a .tres file in that folder — no code changes needed.

const ITEMS_DIR := "res://data/items/"

static var _items: Array[EquipmentResource] = []
static var _built: bool = false

# --- Public API ---

static func get_all_templates() -> Array[EquipmentResource]:
	_ensure_built()
	return _items

static func get_templates_for_slot(slot: EquipmentSlot.Type) -> Array[EquipmentResource]:
	_ensure_built()
	var result: Array[EquipmentResource] = []
	for item in _items:
		if item.slot == slot:
			result.append(item)
	return result

static func get_random_template(slot: int = -1) -> EquipmentResource:
	_ensure_built()
	if slot >= 0:
		var filtered = get_templates_for_slot(slot as EquipmentSlot.Type)
		if filtered.size() > 0:
			return filtered[randi() % filtered.size()]
	if _items.is_empty():
		push_error("ItemLibrary: _items is empty — check that res://data/items/ is populated and exported")
		return null
	return _items[randi() % _items.size()]

static func get_allowed_stats(slot: EquipmentSlot.Type) -> Array[StringName]:
	match slot:
		EquipmentSlot.Type.WEAPON:   return [&"strength", &"dexterity", &"intelligence", &"piety", &"power", &"crit_chance", &"max_hp", &"defense"]
		EquipmentSlot.Type.ARMOR:    return [&"max_hp", &"defense", &"max_shield", &"parry_chance", &"strength", &"dexterity"]
		EquipmentSlot.Type.HELMET:   return [&"max_hp", &"intelligence", &"piety", &"avoid_chance", &"accuracy", &"strength", &"dexterity"]
		EquipmentSlot.Type.SHIELD:   return [&"defense", &"max_shield", &"parry_chance", &"max_hp"]
		EquipmentSlot.Type.BOW:      return [&"dexterity", &"accuracy", &"crit_chance", &"crit_damage", &"power"]
		EquipmentSlot.Type.GLOVES:   return [&"strength", &"dexterity", &"crit_chance", &"accuracy", &"power"]
		EquipmentSlot.Type.BOOTS:    return [&"speed", &"avoid_chance", &"dexterity", &"max_hp"]
		EquipmentSlot.Type.RING:     return [&"intelligence", &"piety", &"power", &"crit_chance", &"crit_damage", &"max_hp"]
		EquipmentSlot.Type.NECKLACE: return [&"piety", &"intelligence", &"power", &"max_hp", &"defense", &"crit_chance"]
	return [&"strength"]

# --- Internal ---

static func _ensure_built() -> void:
	if _built:
		return
	_built = true
	_build()

static func _build() -> void:
	_items = []
	var dir := DirAccess.open(ITEMS_DIR)
	if dir:
		dir.list_dir_begin()
		var file := dir.get_next()
		while file != "":
			if file.ends_with(".tres"):
				var item := load(ITEMS_DIR + file) as EquipmentResource
				if item:
					_items.append(item)
				else:
					push_warning("ItemLibrary: failed to load '%s'" % file)
			file = dir.get_next()
		dir.list_dir_end()
	else:
		push_warning("ItemLibrary: DirAccess failed, loading from fallback list")

	# Fallback: if DirAccess yielded nothing (common in Android exports),
	# load every known item explicitly so they're always available.
	if _items.is_empty():
		var fallback_paths: Array[String] = [
			"res://data/items/amulet.tres",
			"res://data/items/chain_mail.tres",
			"res://data/items/crown.tres",
			"res://data/items/dagger.tres",
			"res://data/items/elven_bow.tres",
			"res://data/items/hood.tres",
			"res://data/items/hunters_bow.tres",
			"res://data/items/iron_helm.tres",
			"res://data/items/iron_ring.tres",
			"res://data/items/iron_shield.tres",
			"res://data/items/iron_sword.tres",
			"res://data/items/leather_armor.tres",
			"res://data/items/leather_boots.tres",
			"res://data/items/leather_gloves.tres",
			"res://data/items/mace.tres",
			"res://data/items/robe.tres",
			"res://data/items/short_bow.tres",
			"res://data/items/silver_ring.tres",
			"res://data/items/staff.tres",
			"res://data/items/tower_shield.tres",
			"res://data/items/wooden_shield.tres",
		]
		for path in fallback_paths:
			var item := load(path) as EquipmentResource
			if item:
				_items.append(item)
			else:
				push_warning("ItemLibrary: fallback load failed for '%s'" % path)

	if _items.is_empty():
		push_error("ItemLibrary: no items loaded — loot will not work!")
