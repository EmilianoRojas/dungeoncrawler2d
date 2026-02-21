class_name LevelUpSystem
extends Object

# XP / Level-Up System (GameSpec §4)
# Awards XP on enemy kill, handles level-up and random skill offers.

# XP required per level: 10 + level * 5
# Level 1→15 XP, Level 2→20, Level 3→25, etc.

# XP awards by enemy tier
const XP_NORMAL: int = 10
const XP_ELITE: int = 25
const XP_BOSS: int = 50

## Calculate XP needed to reach next level.
static func xp_for_level(level: int) -> int:
	return 10 + level * 5

## Award XP to entity. Returns true if entity leveled up.
static func award_xp(entity: Entity, amount: int) -> bool:
	entity.xp += amount
	var required = xp_for_level(entity.level)
	
	if entity.xp >= required:
		entity.xp -= required
		entity.level += 1
		print("LEVEL UP! Now level %d" % entity.level)
		return true
	
	return false

## Get XP amount based on enemy tier.
static func get_xp_for_tier(tier: int) -> int:
	match tier:
		0: return XP_NORMAL # EnemyTemplate.Tier.NORMAL
		1: return XP_ELITE # EnemyTemplate.Tier.ELITE
		2: return XP_BOSS # EnemyTemplate.Tier.BOSS
	return XP_NORMAL

## Get a random skill offer for the entity.
## Returns a Skill resource, possibly one they already know (for upgrade).
static func get_skill_offer(_entity: Entity) -> Skill:
	var all_skills = _load_all_skills()
	if all_skills.is_empty():
		return null
	
	# Shuffle and pick one
	all_skills.shuffle()
	return all_skills[0]

## Check if the offered skill can upgrade an existing one.
## Returns the matching existing skill, or null.
static func find_upgrade_match(entity: Entity, offered: Skill) -> Skill:
	if not entity.skills:
		return null
	for existing in entity.skills.known_skills:
		if existing.skill_name == offered.skill_name:
			return existing
	return null

## Apply a skill upgrade: increase the existing skill's level.
static func upgrade_skill(existing_skill: Skill) -> void:
	existing_skill.skill_level += 1
	print("Skill upgraded: %s → Lv %d" % [existing_skill.skill_name, existing_skill.skill_level])

## Learn a new skill, replacing one at the given index if needed.
static func learn_skill(entity: Entity, new_skill: Skill, replace_index: int = -1) -> void:
	if replace_index >= 0 and replace_index < entity.skills.known_skills.size():
		# Replace existing
		var old = entity.skills.known_skills[replace_index]
		entity.skills.unlearn_skill(old)
		print("Replaced %s with %s" % [old.skill_name, new_skill.skill_name])
	
	entity.skills.learn_skill(new_skill.duplicate())

## Load all skill resources from data/skills/ directory.
static func _load_all_skills() -> Array[Skill]:
	var skills: Array[Skill] = []
	
	var dir = DirAccess.open("res://data/skills/")
	if not dir:
		push_error("LevelUpSystem: Cannot open res://data/skills/")
		return skills
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path = "res://data/skills/" + file_name
			var res = load(path)
			if res is Skill:
				skills.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	return skills
