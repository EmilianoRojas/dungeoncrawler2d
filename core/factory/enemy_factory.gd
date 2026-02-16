class_name EnemyFactory

static func create_goblin() -> Entity:
	var enemy = Entity.new()
	enemy.name = "Goblin"
	enemy.team = Entity.Team.ENEMY
	
	# 1. Initialize components
	enemy.initialize()
	
	# 2. Set Stats
	enemy.stats.set_base_stat(StatTypes.HP, 30)
	enemy.stats.set_base_stat(StatTypes.MAX_HP, 30)
	enemy.stats.set_base_stat(StatTypes.STRENGTH, 5)
	enemy.stats.set_base_stat(StatTypes.SPEED, 3)
	
	# 3. Finalize Stats (Calc current values)
	enemy.stats.finalize_initialization()
	
	# 4. Add Skills
	# Use load() or preload(), load is safer if we want to avoid cyclic dependencies in some architectures, 
	# though preload is fine here.
	var bite = load("res://data/skills/bite.tres")
	if bite:
		enemy.skills.learn_skill(bite.duplicate()) # Duplicate to avoid shared state if modified
	else:
		push_error("EnemyFactory: Could not load bite.tres")
	
	return enemy
