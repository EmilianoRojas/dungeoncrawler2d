class_name SkillLibrary
# Single source of truth for all skill resources.
# When you add a new skill .tres, add its path to SKILL_PATHS below.
# DirAccess can't enumerate files on Android exported builds, so we maintain
# this list manually — but it only lives in ONE place.

const SKILL_PATHS: Array[String] = [
	"res://data/skills/backstab.tres",
	"res://data/skills/basic_attack.tres",
	"res://data/skills/bite.tres",
	"res://data/skills/defensive_stance.tres",
	"res://data/skills/enrage.tres",
	"res://data/skills/fireball.tres",
	"res://data/skills/heal.tres",
	"res://data/skills/heavy_strike.tres",
	"res://data/skills/holy_smite.tres",
	"res://data/skills/ice_shard.tres",
	"res://data/skills/observe.tres",
	"res://data/skills/poison_strike.tres",
	"res://data/skills/quick_slash.tres",
	"res://data/skills/shield_bash.tres",
	"res://data/skills/tornado_slash.tres",
]

## Returns all skill resources. Tries DirAccess first, falls back to SKILL_PATHS.
static func get_all_skills() -> Array[Skill]:
	var skills: Array[Skill] = []

	# DirAccess works in editor/desktop; fails silently on Android PCK
	var dir = DirAccess.open("res://data/skills/")
	if dir:
		dir.list_dir_begin()
		var f = dir.get_next()
		while f != "":
			if f.ends_with(".tres"):
				var res = load("res://data/skills/" + f)
				if res is Skill:
					skills.append(res)
			f = dir.get_next()
		dir.list_dir_end()

	if skills.is_empty():
		for path in SKILL_PATHS:
			var res = load(path)
			if res is Skill:
				skills.append(res)
			else:
				push_warning("SkillLibrary: failed to load '%s'" % path)

	if skills.is_empty():
		push_error("SkillLibrary: no skills loaded — check SKILL_PATHS and export include_filter")

	return skills
