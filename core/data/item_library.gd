class_name ItemLibrary
extends Object

# Static registry of base item templates for procedural generation.
# Each template is a minimal EquipmentResource with slot, name, and allowed stat pool.
# ItemFactory duplicates these and adds random bonuses.

# Allowed stats per slot — determines which stats get rolled
const WEAPON_STATS:   Array[StringName] = [&"strength", &"dexterity", &"intelligence", &"piety", &"power", &"crit_chance", &"max_hp", &"defense"]
const ARMOR_STATS:    Array[StringName] = [&"max_hp", &"defense", &"max_shield", &"parry_chance", &"strength", &"dexterity"]
const HELMET_STATS:   Array[StringName] = [&"max_hp", &"intelligence", &"piety", &"avoid_chance", &"accuracy", &"strength", &"dexterity"]
const SHIELD_STATS:   Array[StringName] = [&"defense", &"max_shield", &"parry_chance", &"max_hp"]
const BOW_STATS:      Array[StringName] = [&"dexterity", &"accuracy", &"crit_chance", &"crit_damage", &"power"]
const GLOVES_STATS:   Array[StringName] = [&"strength", &"dexterity", &"crit_chance", &"accuracy", &"power"]
const BOOTS_STATS:    Array[StringName] = [&"speed", &"avoid_chance", &"dexterity", &"max_hp"]
const RING_STATS:     Array[StringName] = [&"intelligence", &"piety", &"power", &"crit_chance", &"crit_damage", &"max_hp"]
const NECKLACE_STATS: Array[StringName] = [&"piety", &"intelligence", &"power", &"max_hp", &"defense", &"crit_chance"]

static func get_allowed_stats(slot: EquipmentSlot.Type) -> Array[StringName]:
	match slot:
		EquipmentSlot.Type.WEAPON:   return WEAPON_STATS
		EquipmentSlot.Type.ARMOR:    return ARMOR_STATS
		EquipmentSlot.Type.HELMET:   return HELMET_STATS
		EquipmentSlot.Type.SHIELD:   return SHIELD_STATS
		EquipmentSlot.Type.BOW:      return BOW_STATS
		EquipmentSlot.Type.GLOVES:   return GLOVES_STATS
		EquipmentSlot.Type.BOOTS:    return BOOTS_STATS
		EquipmentSlot.Type.RING:     return RING_STATS
		EquipmentSlot.Type.NECKLACE: return NECKLACE_STATS
	return WEAPON_STATS

# --- WEAPON TEMPLATES ---

static func _iron_sword() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"iron_sword"
	item.display_name = "Iron Sword"
	item.slot = EquipmentSlot.Type.WEAPON
	item.icon_path = "res://data/assets/items/sword_01.png"
	return item

static func _staff() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"staff"
	item.display_name = "Staff"
	item.slot = EquipmentSlot.Type.WEAPON
	item.icon_path = "res://data/assets/items/staff_01.png"
	return item

static func _mace() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"mace"
	item.display_name = "Mace"
	item.slot = EquipmentSlot.Type.WEAPON
	item.icon_path = "res://data/assets/items/sword_02.png"
	return item

static func _dagger() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"dagger"
	item.display_name = "Dagger"
	item.slot = EquipmentSlot.Type.WEAPON
	item.icon_path = "res://data/assets/items/sword_03.png"
	return item

# --- ARMOR TEMPLATES ---

static func _leather_armor() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"leather_armor"
	item.display_name = "Leather Armor"
	item.slot = EquipmentSlot.Type.ARMOR
	item.icon_path = "res://data/assets/items/armor_leather.png"
	return item

static func _chain_mail() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"chain_mail"
	item.display_name = "Chain Mail"
	item.slot = EquipmentSlot.Type.ARMOR
	item.icon_path = "res://data/assets/items/armor_chain.png"
	return item

static func _robe() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"robe"
	item.display_name = "Robe"
	item.slot = EquipmentSlot.Type.ARMOR
	item.icon_path = "res://data/assets/items/armor_robe.png"
	return item

# --- HELMET TEMPLATES ---

static func _iron_helm() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"iron_helm"
	item.display_name = "Iron Helm"
	item.slot = EquipmentSlot.Type.HELMET
	item.icon_path = "res://data/assets/items/helmet_iron.png"
	return item

static func _hood() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"hood"
	item.display_name = "Hood"
	item.slot = EquipmentSlot.Type.HELMET
	item.icon_path = "res://data/assets/items/hat_hood.png"
	return item

static func _crown() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"crown"
	item.display_name = "Crown"
	item.slot = EquipmentSlot.Type.HELMET
	item.icon_path = "res://data/assets/items/hat_crown.png"
	return item

# --- SHIELD TEMPLATES ---

static func _wooden_shield() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"wooden_shield"
	item.display_name = "Wooden Shield"
	item.slot = EquipmentSlot.Type.SHIELD
	item.icon_path = "res://data/assets/items/shield_01.png"
	return item

static func _iron_shield() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"iron_shield"
	item.display_name = "Iron Shield"
	item.slot = EquipmentSlot.Type.SHIELD
	item.icon_path = "res://data/assets/items/shield_02.png"
	return item

static func _tower_shield() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"tower_shield"
	item.display_name = "Tower Shield"
	item.slot = EquipmentSlot.Type.SHIELD
	item.icon_path = "res://data/assets/items/shield_03.png"
	return item

# --- BOW TEMPLATES ---

static func _short_bow() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"short_bow"
	item.display_name = "Short Bow"
	item.slot = EquipmentSlot.Type.BOW
	item.icon_path = "res://data/assets/items/bow_01.png"
	return item

static func _hunters_bow() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"hunters_bow"
	item.display_name = "Hunter's Bow"
	item.slot = EquipmentSlot.Type.BOW
	item.icon_path = "res://data/assets/items/bow_02.png"
	return item

static func _elven_bow() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"elven_bow"
	item.display_name = "Elven Bow"
	item.slot = EquipmentSlot.Type.BOW
	item.icon_path = "res://data/assets/items/bow_03.png"
	return item

# --- GLOVES TEMPLATES ---

static func _leather_gloves() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"leather_gloves"
	item.display_name = "Leather Gloves"
	item.slot = EquipmentSlot.Type.GLOVES
	item.icon_path = "res://data/assets/items/gloves_01.png"
	return item

# --- BOOTS TEMPLATES ---

static func _leather_boots() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"leather_boots"
	item.display_name = "Leather Boots"
	item.slot = EquipmentSlot.Type.BOOTS
	item.icon_path = "res://data/assets/items/boots_01.png"
	return item

# --- RING TEMPLATES ---

static func _iron_ring() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"iron_ring"
	item.display_name = "Iron Ring"
	item.slot = EquipmentSlot.Type.RING
	item.icon_path = "res://data/assets/items/ring_01.png"
	return item

static func _silver_ring() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"silver_ring"
	item.display_name = "Silver Ring"
	item.slot = EquipmentSlot.Type.RING
	item.icon_path = "res://data/assets/items/ring_02.png"
	return item

# --- NECKLACE TEMPLATES ---

static func _amulet() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"amulet"
	item.display_name = "Amulet"
	item.slot = EquipmentSlot.Type.NECKLACE
	item.icon_path = "res://data/assets/items/necklace_01.png"
	return item

# --- REGISTRY ---

static func get_all_templates() -> Array[EquipmentResource]:
	return [
		# Weapons
		_iron_sword(), _staff(), _mace(), _dagger(),
		# Armor
		_leather_armor(), _chain_mail(), _robe(),
		# Helmets
		_iron_helm(), _hood(), _crown(),
		# Shields
		_wooden_shield(), _iron_shield(), _tower_shield(),
		# Bows
		_short_bow(), _hunters_bow(), _elven_bow(),
		# Accessories
		_leather_gloves(), _leather_boots(),
		_iron_ring(), _silver_ring(),
		_amulet(),
	]

static func get_templates_for_slot(slot: EquipmentSlot.Type) -> Array[EquipmentResource]:
	var all = get_all_templates()
	var filtered: Array[EquipmentResource] = []
	for t in all:
		if t.slot == slot:
			filtered.append(t)
	return filtered

static func get_random_template(slot: int = -1) -> EquipmentResource:
	if slot >= 0:
		var templates = get_templates_for_slot(slot as EquipmentSlot.Type)
		if templates.size() > 0:
			return templates[randi() % templates.size()]
	var all = get_all_templates()
	return all[randi() % all.size()]
