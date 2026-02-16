extends Node

func _init():
	print("Starting Skills & Effects Verification (From Disk)...")
	test_skills()
	print("Verification Complete!")
	

func test_skills():
	var caster = Entity.new()
	caster.name = "Hero"
	# Initialize stats manually for test since we don't have full scene
	caster.stats = StatsComponent.new()
	var caster_base: Dictionary[StringName, int] = {
		StatTypes.HP: 100,
		StatTypes.MAX_HP: 100,
		StatTypes.STRENGTH: 10,
		StatTypes.DEFENSE: 0
	}
	caster.stats.base = caster_base
	caster.stats.finalize_initialization()
	caster.effects = EffectManager.new(caster) # Ensure effects manager is init
	
	var target = Entity.new()
	target.name = "Dummy"
	target.stats = StatsComponent.new()
	var target_base: Dictionary[StringName, int] = {
		StatTypes.HP: 100,
		StatTypes.MAX_HP: 100,
		StatTypes.STRENGTH: 5,
		StatTypes.DEFENSE: 0
	}
	target.stats.base = target_base
	target.stats.finalize_initialization()
	target.effects = EffectManager.new(target)

	print("\n--- Test 1: Basic Attack (Scaling) ---")
	var basic = load("res://data/skills/basic_attack.tres")
	if not basic:
		print("❌ FAIL: Could not load basic_attack.tres")
		return
		
	SkillExecutor.execute(basic, caster, target)
	# Expected: 5 + (10 * 1.0) = 15 damage
	var hp = target.stats.get_current(StatTypes.HP)
	if hp == 85:
		print("✅ PASS: Basic Attack dealt 15 damage (100 - 15 = 85)")
	else:
		print("❌ FAIL: Basic Attack dealt wrong damage. HP: %d (Expected 85)" % hp)

	# Reset Target
	target.stats.modify_current(StatTypes.HP, 100)
	
	print("\n--- Test 2: Iron Skin (Damage Reduction from Skill) ---")
	# Load Defensive Stance which should trigger Iron Skin
	var def_stance = load("res://data/skills/defensive_stance.tres")
	if not def_stance:
		print("❌ FAIL: Could not load defensive_stance.tres")
		return

	# Apply Stance to TARGET (Simulating target using it, or just applying effect directly for test)
	# SkillExecutor executes skill from Source to Target. 
	# Defensive Stance has "on_cast_effects" (Self).
	SkillExecutor.execute(def_stance, target, caster) # Target determines to use stance
	
	# Verify Effect Applied
	if target.effects._find_instance("iron_skin"):
		print("✅ PASS: Iron Skin applied to target.")
	else:
		print("❌ FAIL: Iron Skin NOT applied.")
	
	# Attack again
	SkillExecutor.execute(basic, caster, target)
	# Expected: 15 damage * (1 - 0.3) = 15 * 0.7 = 10.5 -> 10 damage (int cast usually floors)
	hp = target.stats.get_current(StatTypes.HP)
	if hp == 90:
		print("✅ PASS: Iron Skin reduced damage to 10. (100 - 10 = 90)")
	else:
		print("❌ FAIL: Iron Skin failed. HP: %d (Expected 90)" % hp)

	# Reset
	target.stats.modify_current(StatTypes.HP, 100)
	target.effects.effects.clear()
	caster.effects.effects.clear()
	
	print("\n--- Test 3: Rage (Damage Buff from Skill) ---")
	var enrage = load("res://data/skills/enrage.tres")
	if not enrage:
		print("❌ FAIL: Could not load enrage.tres")
		return
		
	# Apply to caster
	SkillExecutor.execute(enrage, caster, target)
	
	if caster.effects._find_instance("rage"):
		print("✅ PASS: Rage applied to caster.")
	else:
		print("❌ FAIL: Rage NOT applied.")
	
	# Attack
	SkillExecutor.execute(basic, caster, target)
	# Expected: 15 damage * 1.5 = 22.5 -> 22 damage
	hp = target.stats.get_current(StatTypes.HP)
	if hp == 78:
		print("✅ PASS: Rage increased damage to 22. (100 - 22 = 78)")
	else:
		print("❌ FAIL: Rage failed. HP: %d (Expected 78)" % hp)
