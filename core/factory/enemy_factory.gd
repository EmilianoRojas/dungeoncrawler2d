class_name EnemyFactory

# Data-driven enemy factory (GameSpec §7.3)
# Creates Entity instances from EnemyTemplate resources with floor-scaled stats.

# Cache loaded templates
static var _templates_cache: Array[EnemyTemplate] = []

## Create an enemy from a specific template, scaled by floor.
static func create_enemy(template: EnemyTemplate, dungeon_floor: int) -> Entity:
	var enemy = Entity.new()
	enemy.name = template.enemy_name
	enemy.team = Entity.Team.ENEMY
	enemy.initialize()
	
	# Apply stats with floor scaling
	var scale_mult = 1.0 + dungeon_floor * template.stat_scaling
	for stat_key in template.base_stats:
		var base_val = template.base_stats[stat_key]
		var scaled_val = int(base_val * scale_mult)
		enemy.stats.set_base_stat(stat_key, scaled_val)
	
	# Ensure HP = MAX_HP after scaling
	if template.base_stats.has(StatTypes.MAX_HP):
		var scaled_hp = int(template.base_stats[StatTypes.MAX_HP] * scale_mult)
		enemy.stats.set_base_stat(StatTypes.HP, scaled_hp)
	
	enemy.stats.finalize_initialization()
	
	# Learn skills
	for skill in template.skills:
		if skill:
			enemy.skills.learn_skill(skill.duplicate())
	
	return enemy

## Create a random enemy of a given tier, scaled by floor.
static func create_random_enemy(tier: EnemyTemplate.Tier, dungeon_floor: int) -> Entity:
	var templates = _get_templates_by_tier(tier)
	
	if templates.is_empty():
		push_warning("EnemyFactory: No templates for tier %s, falling back to NORMAL" % EnemyTemplate.Tier.keys()[tier])
		templates = _get_templates_by_tier(EnemyTemplate.Tier.NORMAL)
	
	if templates.is_empty():
		push_error("EnemyFactory: No enemy templates found at all!")
		# Emergency fallback
		return _create_fallback_enemy(dungeon_floor)
	
	var template = templates[randi() % templates.size()]
	return create_enemy(template, dungeon_floor)

## Get all templates matching a tier.
static func _get_templates_by_tier(tier: EnemyTemplate.Tier) -> Array[EnemyTemplate]:
	_ensure_templates_loaded()
	
	var filtered: Array[EnemyTemplate] = []
	for t in _templates_cache:
		if t.tier == tier:
			filtered.append(t)
	return filtered

## Load all templates from data/enemies/ directory (cached).
static func _ensure_templates_loaded() -> void:
	if not _templates_cache.is_empty():
		return
	
	var dir = DirAccess.open("res://data/enemies/")
	if not dir:
		push_error("EnemyFactory: Cannot open res://data/enemies/")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path = "res://data/enemies/" + file_name
			var res = load(path)
			if res is EnemyTemplate:
				_templates_cache.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	print("EnemyFactory: Loaded %d enemy templates" % _templates_cache.size())

## Emergency fallback if no templates exist.
static func _create_fallback_enemy(dungeon_floor: int) -> Entity:
	var enemy = Entity.new()
	enemy.name = "Unknown Foe"
	enemy.team = Entity.Team.ENEMY
	enemy.initialize()
	
	var scale = 1.0 + dungeon_floor * 0.12
	enemy.stats.set_base_stat(StatTypes.HP, int(30 * scale))
	enemy.stats.set_base_stat(StatTypes.MAX_HP, int(30 * scale))
	enemy.stats.set_base_stat(StatTypes.STRENGTH, int(5 * scale))
	enemy.stats.set_base_stat(StatTypes.SPEED, 3)
	enemy.stats.finalize_initialization()
	
	var bite = load("res://data/skills/bite.tres")
	if bite:
		enemy.skills.learn_skill(bite.duplicate())
	
	return enemy
