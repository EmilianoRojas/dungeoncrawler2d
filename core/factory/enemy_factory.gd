class_name EnemyFactory

# Data-driven enemy factory (GameSpec §7.3)
# Creates Entity instances from EnemyTemplate resources with floor-scaled stats.

# Cache loaded templates
static var _templates_cache: Array[EnemyTemplate] = []

## Stat categories for differentiated scaling (GameSpec §10)
## HP/Shield scale at full rate, combat stats scale slower, utility barely scales
const SCALING_FULL: Array[StringName] = [StatTypes.MAX_HP, StatTypes.HP, StatTypes.MAX_SHIELD, StatTypes.SHIELD]
const SCALING_SLOW_FACTOR: float = 0.33 # Combat stats scale at 33% of the base rate (e.g. 0.15 * 0.33 ≈ 0.05)

## Create an enemy from a specific template, scaled by floor.
static func create_enemy(template: EnemyTemplate, dungeon_floor: int) -> Entity:
	var enemy = Entity.new()
	enemy.name = template.enemy_name
	if template.sprite:
		enemy.sprite = template.sprite
	enemy.team = Entity.Team.ENEMY
	enemy.initialize()
	
	# Apply stats with floor scaling (GameSpec §10)
	# HP/Shield: full scaling rate
	# Combat stats (STR, DEX, INT, etc.): slower scaling rate
	var base_rate = template.stat_scaling
	for stat_key in template.base_stats:
		var base_val = template.base_stats[stat_key]
		var rate = base_rate
		if stat_key not in SCALING_FULL:
			rate = base_rate * SCALING_SLOW_FACTOR
		var scaled_val = int(base_val * (1.0 + dungeon_floor * rate))
		enemy.stats.set_base_stat(stat_key, scaled_val)
	
	# Ensure HP = MAX_HP after scaling
	if template.base_stats.has(StatTypes.MAX_HP):
		var scaled_hp = int(template.base_stats[StatTypes.MAX_HP] * (1.0 + dungeon_floor * base_rate))
		enemy.stats.set_base_stat(StatTypes.HP, scaled_hp)
	
	enemy.stats.finalize_initialization()
	
	# Learn skills
	for skill in template.skills:
		if skill:
			enemy.skills.learn_skill(skill.duplicate())
	
	# Apply tier modifiers (GameSpec §10)
	match template.tier:
		EnemyTemplate.Tier.ELITE:
			_apply_elite_modifiers(enemy)
		EnemyTemplate.Tier.BOSS:
			_apply_boss_modifiers(enemy)
	
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

## Create an enemy from a dungeon-specific pool, filtered by tier and scaled by floor.
## Falls back to create_random_enemy() if pool is empty or has no matching tier.
static func create_from_pool(pool: Array[EnemyTemplate], boss_pool: Array[EnemyTemplate], tier: EnemyTemplate.Tier, dungeon_floor: int, scaling_mult: float = 1.0) -> Entity:
	# For bosses, use boss_pool first
	if tier == EnemyTemplate.Tier.BOSS and boss_pool.size() > 0:
		var template = boss_pool[randi() % boss_pool.size()]
		var enemy = create_enemy(template, dungeon_floor)
		_apply_scaling_mult(enemy, scaling_mult)
		return enemy
	
	# Filter pool by tier
	var matching: Array[EnemyTemplate] = []
	for t in pool:
		if t.tier == tier:
			matching.append(t)
	
	# If no exact tier match, use any from pool (for ELITE rooms in a normal-only pool)
	if matching.is_empty():
		matching = pool
	
	if matching.is_empty():
		# Fallback to global templates
		return create_random_enemy(tier, dungeon_floor)
	
	var template = matching[randi() % matching.size()]
	var enemy = create_enemy(template, dungeon_floor)
	_apply_scaling_mult(enemy, scaling_mult)
	return enemy

## Apply Elite modifiers (GameSpec §10): +50% HP, +20% POW, random elite passive
static func _apply_elite_modifiers(enemy: Entity) -> void:
	# +50% HP
	var max_hp = enemy.stats.base.get(StatTypes.MAX_HP, 50)
	enemy.stats.set_base_stat(StatTypes.MAX_HP, int(max_hp * 1.5))
	enemy.stats.set_base_stat(StatTypes.HP, int(max_hp * 1.5))
	
	# +20% POW (add flat if no POW exists)
	var pow_val = enemy.stats.base.get(StatTypes.POWER, 0)
	if pow_val > 0:
		enemy.stats.set_base_stat(StatTypes.POWER, int(pow_val * 1.2))
	else:
		# Give elites some POW even if template has none
		var str_val = enemy.stats.base.get(StatTypes.STRENGTH, 5)
		enemy.stats.set_base_stat(StatTypes.POWER, int(str_val * 0.2))
	
	enemy.stats.finalize_initialization()
	
	# Random elite passive (aggressive ones from GameSpec §10)
	var elite_passive_ids: Array[StringName] = [
		&"damage_reduce", &"counter", &"weaken",
		&"poisonous", &"sniping", &"first_strike"
	]
	var chosen_id = elite_passive_ids[randi() % elite_passive_ids.size()]
	_apply_passive_by_id(enemy, chosen_id, &"elite_passive")
	
	enemy.name = "Elite " + enemy.name

## Apply Boss modifiers (GameSpec §10): 300% HP, 200% Shield, boss immunity
static func _apply_boss_modifiers(enemy: Entity) -> void:
	# 300% HP
	var max_hp = enemy.stats.base.get(StatTypes.MAX_HP, 100)
	enemy.stats.set_base_stat(StatTypes.MAX_HP, int(max_hp * 3.0))
	enemy.stats.set_base_stat(StatTypes.HP, int(max_hp * 3.0))
	
	# 200% Shield (or grant shield if none)
	var max_shield = enemy.stats.base.get(StatTypes.MAX_SHIELD, 0)
	if max_shield > 0:
		enemy.stats.set_base_stat(StatTypes.MAX_SHIELD, int(max_shield * 2.0))
		enemy.stats.set_base_stat(StatTypes.SHIELD, int(max_shield * 2.0))
	else:
		# Give bosses a shield equal to 30% of their HP
		var boss_hp = enemy.stats.base.get(StatTypes.MAX_HP, 100)
		enemy.stats.set_base_stat(StatTypes.MAX_SHIELD, int(boss_hp * 0.3))
		enemy.stats.set_base_stat(StatTypes.SHIELD, int(boss_hp * 0.3))
	
	# Boost offensive stats
	var pow_val = enemy.stats.base.get(StatTypes.POWER, 0)
	var str_val = enemy.stats.base.get(StatTypes.STRENGTH, 10)
	enemy.stats.set_base_stat(StatTypes.POWER, int(max(pow_val, str_val * 0.3)))
	
	enemy.stats.finalize_initialization()
	
	# Boss immunity passive (avoid_critical — can't be insta-killed)
	_apply_passive_by_id(enemy, &"avoid_critical", &"boss_passive")
	
	enemy.name = "Boss: " + enemy.name

## Apply a passive by its PassiveLibrary ID.
static func _apply_passive_by_id(enemy: Entity, passive_id: StringName, source_id: StringName) -> void:
	if not enemy.passives:
		return
	var passive_info = PassiveLibrary.get_passive(passive_id)
	if not passive_info.is_empty():
		enemy.passives.add_passive(null, source_id, passive_info)

## Apply dungeon-specific stat scaling multiplier on top of base scaling.
static func _apply_scaling_mult(enemy: Entity, mult: float) -> void:
	if mult == 1.0:
		return
	for stat_key in enemy.stats.base:
		var current = enemy.stats.base[stat_key]
		if current > 0:
			enemy.stats.set_base_stat(stat_key, int(current * mult))
	# Sync HP with MAX_HP
	if enemy.stats.base.has(StatTypes.MAX_HP):
		enemy.stats.set_base_stat(StatTypes.HP, enemy.stats.base[StatTypes.MAX_HP])
	if enemy.stats.base.has(StatTypes.MAX_SHIELD):
		enemy.stats.set_base_stat(StatTypes.SHIELD, enemy.stats.base[StatTypes.MAX_SHIELD])
	enemy.stats.finalize_initialization()

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
