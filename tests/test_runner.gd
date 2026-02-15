extends Node

func _ready():
	print("Starting Architecture Verification...")
	
	# 1. Setup Warrior
	print("Creating Warrior...")
	var warrior = Entity.new()
	warrior.name = "Warrior"
	# We don't need to manually call _ready() if we add it to the tree, 
	# but for a unit test without adding to tree, we might need to simulate it 
	# or just instantiate components manually.
	# Since Entity uses _ready() to init stats/effects, we MUST call it if not in tree.
	warrior._ready()
	warrior.stats.base = {"strength": 10, "hp": 100}
	
	# 2. Add Lifesteal
	print("Adding Lifesteal...")
	var lifesteal = LifestealEffect.new()
	lifesteal.percent = 0.5
	warrior.effects.add_effect(lifesteal)
	
	# 3. Setup Enemy
	print("Creating Goblin...")
	var goblin = Entity.new()
	goblin.name = "Goblin"
	goblin._ready()
	goblin.stats.base = {"hp": 50}
	
	# 4. Setup Skill
	print("Preparing Tackle...")
	var tackle = Skill.new()
	tackle.skill_name = "Tackle"
	tackle.scaling_stat = "strength"
	tackle.multiplier = 1.5 # 10 * 1.5 = 15 damage
	
	# 5. Combat
	print("Warrior uses Tackle on Goblin!")
	print("Goblin HP before: %d" % goblin.stats.get_stat(StatsComponent.StatType.HP))
	print("Warrior HP before: %d" % warrior.stats.get_stat(StatsComponent.StatType.HP))
	
	tackle.use(warrior, goblin)
	
	print("Goblin HP after: %d" % goblin.stats.get_stat(StatsComponent.StatType.HP))
	print("Warrior HP after (expecting heal if damaged, but he was full): %d" % warrior.stats.get_stat(StatsComponent.StatType.HP))
	
	# Let's damage warrior first to see heal works
	print("\n--- Testing Heal ---")
	warrior.stats.set_base_stat(StatsComponent.StatType.HP, 50)
	print("Warrior HP set to 50.")
	print("Warrior attacks again...")
	tackle.use(warrior, goblin)
	print("Warrior HP after lifesteal (expect 50 + 7 [15*0.5 floor]): %d" % warrior.stats.get_stat(StatsComponent.StatType.HP))
	
	print("\nVerification Complete.")
	get_tree().quit()
