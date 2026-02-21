class_name ItemTemplates
extends Object

# Static registry of base item templates for procedural generation.
# Each template is a minimal EquipmentResource with slot, name, and allowed stat pool.
# ItemFactory duplicates these and adds random bonuses.

# Allowed stats per slot — determines which stats get rolled
const WEAPON_STATS: Array[StringName] = [&"strength", &"dexterity", &"intelligence", &"piety", &"power", &"crit_chance"]
const ARMOR_STATS: Array[StringName] = [&"max_hp", &"defense", &"max_shield", &"parry_chance"]
const HELMET_STATS: Array[StringName] = [&"max_hp", &"intelligence", &"piety", &"avoid_chance", &"accuracy"]

static func get_allowed_stats(slot: EquipmentSlot.Type) -> Array[StringName]:
	match slot:
		EquipmentSlot.Type.WEAPON: return WEAPON_STATS
		EquipmentSlot.Type.ARMOR: return ARMOR_STATS
		EquipmentSlot.Type.HELMET: return HELMET_STATS
	return WEAPON_STATS

# --- WEAPON TEMPLATES ---

static func _iron_sword() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"iron_sword"
	item.display_name = "Iron Sword"
	item.slot = EquipmentSlot.Type.WEAPON
	return item

static func _staff() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"staff"
	item.display_name = "Staff"
	item.slot = EquipmentSlot.Type.WEAPON
	return item

static func _mace() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"mace"
	item.display_name = "Mace"
	item.slot = EquipmentSlot.Type.WEAPON
	return item

static func _dagger() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"dagger"
	item.display_name = "Dagger"
	item.slot = EquipmentSlot.Type.WEAPON
	return item

# --- ARMOR TEMPLATES ---

static func _leather_armor() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"leather_armor"
	item.display_name = "Leather Armor"
	item.slot = EquipmentSlot.Type.ARMOR
	return item

static func _chain_mail() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"chain_mail"
	item.display_name = "Chain Mail"
	item.slot = EquipmentSlot.Type.ARMOR
	return item

static func _robe() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"robe"
	item.display_name = "Robe"
	item.slot = EquipmentSlot.Type.ARMOR
	return item

# --- HELMET TEMPLATES ---

static func _iron_helm() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"iron_helm"
	item.display_name = "Iron Helm"
	item.slot = EquipmentSlot.Type.HELMET
	return item

static func _hood() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"hood"
	item.display_name = "Hood"
	item.slot = EquipmentSlot.Type.HELMET
	return item

static func _crown() -> EquipmentResource:
	var item = EquipmentResource.new()
	item.id = &"crown"
	item.display_name = "Crown"
	item.slot = EquipmentSlot.Type.HELMET
	return item

# --- REGISTRY ---

static func get_all_templates() -> Array[EquipmentResource]:
	return [
		_iron_sword(), _staff(), _mace(), _dagger(),
		_leather_armor(), _chain_mail(), _robe(),
		_iron_helm(), _hood(), _crown()
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
