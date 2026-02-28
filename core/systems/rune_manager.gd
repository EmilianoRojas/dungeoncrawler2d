class_name RuneManager
extends Node

const MAX_COST: int = 20
const SAVE_PATH: String = "user://rune_save.json"

var unlocked_rune_ids: Array[StringName] = []
# class_title (String) -> Array[StringName]
var equipped_runes: Dictionary = {}

func _ready() -> void:
	load_runes()

# --- Unlock ---

func unlock_rune(id: StringName) -> void:
	if not unlocked_rune_ids.has(id):
		unlocked_rune_ids.append(id)
		save_runes()

# --- Equip / Unequip ---

func get_equipped(class_title: String) -> Array[StringName]:
	if not equipped_runes.has(class_title):
		equipped_runes[class_title] = []
	return equipped_runes[class_title]

func get_used_cost(class_title: String) -> int:
	var total: int = 0
	for id: StringName in get_equipped(class_title):
		var rune: RuneResource = RuneLibrary.get_rune(id)
		if rune:
			total += RuneLibrary.get_cost(rune.tier)
	return total

func can_equip(class_title: String, rune_id: StringName) -> bool:
	var rune: RuneResource = RuneLibrary.get_rune(rune_id)
	if not rune:
		return false
	if get_equipped(class_title).has(rune_id):
		return false
	return get_used_cost(class_title) + RuneLibrary.get_cost(rune.tier) <= MAX_COST

func equip_rune(class_title: String, rune_id: StringName) -> bool:
	if not can_equip(class_title, rune_id):
		return false
	get_equipped(class_title).append(rune_id)
	save_runes()
	return true

func unequip_rune(class_title: String, rune_id: StringName) -> void:
	get_equipped(class_title).erase(rune_id)
	save_runes()

# --- Apply to Entity ---

## Apply equipped runes to the entity.
## Safe to call multiple times — removes previous rune bonuses first.
func apply_runes_to_entity(entity: Entity, class_title: String) -> void:
	if not entity or not entity.stats or not entity.passives:
		return

	# Remove previous rune stat modifiers and passives
	entity.stats.remove_modifiers_from_source(&"rune")
	entity.passives.remove_from_source(&"rune")

	for rune_id: StringName in get_equipped(class_title):
		var rune: RuneResource = RuneLibrary.get_rune(rune_id)
		if not rune:
			continue

		# Apply stat bonuses as permanent flat modifiers
		for stat_key: StringName in rune.stat_bonuses:
			var mod := StatModifier.new()
			mod.stat           = stat_key
			mod.type           = StatModifier.Type.FLAT
			mod.value          = float(rune.stat_bonuses[stat_key])
			mod.duration_turns = -1
			entity.stats.add_modifier(mod, &"rune")

		# Apply passive if any
		if rune.passive_id != &"":
			var passive_info: Dictionary = PassiveLibrary.get_passive(rune.passive_id)
			if not passive_info.is_empty():
				entity.passives.add_passive(null, &"rune", passive_info)

# --- Persistence ---

func save_runes() -> void:
	var data: Dictionary = {"unlocked": [], "equipped": {}}

	for id: StringName in unlocked_rune_ids:
		data["unlocked"].append(str(id))

	for class_title: String in equipped_runes:
		data["equipped"][class_title] = []
		for id: StringName in equipped_runes[class_title]:
			data["equipped"][class_title].append(str(id))

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_runes() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		return

	var data = json.get_data()
	if not data is Dictionary:
		return

	unlocked_rune_ids.clear()
	equipped_runes.clear()

	if data.has("unlocked"):
		for id_str in data["unlocked"]:
			unlocked_rune_ids.append(StringName(str(id_str)))

	if data.has("equipped"):
		for class_title in data["equipped"]:
			equipped_runes[str(class_title)] = []
			for id_str in data["equipped"][class_title]:
				equipped_runes[str(class_title)].append(StringName(str(id_str)))
