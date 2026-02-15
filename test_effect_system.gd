extends Node

func _init():
	print("Starting Effect System Verification...")
	test_lifesteal()
	test_stacking()
	test_duration()
	quit()

func test_lifesteal():
	print("\n--- Testing Lifesteal Effect ---")
	
	# Setup Entities
	var attacker = Entity.new()
	attacker.name = "Attacker"
	attacker.initialize()
	attacker.stats.set_base_stat(StatsComponent.StatType.HP, 50)
	attacker.stats.set_base_stat(StatsComponent.StatType.MAX_HP, 100)
	attacker.stats.finalize_initialization()
	
	var defender = Entity.new()
	defender.name = "Defender"
	defender.initialize()
	defender.stats.set_base_stat(StatsComponent.StatType.HP, 100)
	defender.stats.set_base_stat(StatsComponent.StatType.MAX_HP, 100)
	defender.stats.finalize_initialization()
	
	# Create Lifesteal Effect
	var lifesteal = EffectResource.new()
	lifesteal.effect_id = "lifesteal"
	lifesteal.trigger = EffectResource.Trigger.ON_DAMAGE_DEALT
	lifesteal.operation = EffectResource.Operation.HEAL_PERCENT
	lifesteal.value = 0.5 # 50% Lifesteal
	
	attacker.effects.apply_effect(lifesteal)
	
	print("Initial Attacker HP: ", attacker.stats.current[StatsComponent.StatType.HP])
	print("Initial Defender HP: ", defender.stats.current[StatsComponent.StatType.HP])
	
	# Execute Combat
	var damage_amount = 20
	print("Dealing %d damage..." % damage_amount)
	CombatSystem.deal_damage(attacker, defender, damage_amount)
	
	# Assertions
	var expected_attacker_hp = 50 + int(damage_amount * 0.5) # 50 + 10 = 60
	var actual_attacker_hp = attacker.stats.current[StatsComponent.StatType.HP]
	
	var expected_defender_hp = 100 - damage_amount # 80
	var actual_defender_hp = defender.stats.current[StatsComponent.StatType.HP]
	
	print("Final Attacker HP: ", actual_attacker_hp)
	print("Final Defender HP: ", actual_defender_hp)
	
	if actual_attacker_hp == expected_attacker_hp:
		print("✅ PASS: Attacker healed correctly.")
	else:
		print("❌ FAIL: Attacker HP mismatch.")
		
	if actual_defender_hp == expected_defender_hp:
		print("✅ PASS: Defender took damage correctly.")
	else:
		print("❌ FAIL: Defender HP mismatch.")

func test_stacking():
	print("\n--- Testing Stacking (Poison) ---")
	var entity = Entity.new()
	entity.initialize()
	
	var poison = EffectResource.new()
	poison.effect_id = "poison"
	poison.stack_rule = EffectResource.StackRule.ADD
	poison.max_stacks = 5
	poison.duration_turns = 3
	
	# Apply 3 times
	print("Applying Poison 3 times...")
	entity.effects.apply_effect(poison)
	entity.effects.apply_effect(poison)
	entity.effects.apply_effect(poison)
	
	var instance = entity.effects._find_instance("poison")
	if instance and instance.stacks == 3:
		print("✅ PASS: Poison stacked to 3.")
	else:
		print("❌ FAIL: Poison stacks mismatch. Got: %d" % (instance.stacks if instance else 0))

func test_duration():
	print("\n--- Testing Duration Expiration ---")
	var entity = Entity.new()
	entity.initialize()
	
	var temp_buff = EffectResource.new()
	temp_buff.effect_id = "buff"
	temp_buff.duration_turns = 2
	
	print("Applying Buff (Duration: 2 turns)...")
	entity.effects.apply_effect(temp_buff)
	
	print("Tick 1...")
	entity.effects.tick_all()
	var instance = entity.effects._find_instance("buff")
	if instance:
		print("Pass: Effect still exists. Remaining: %d" % instance.remaining_turns)
	else:
		print("❌ FAIL: Effect expired too early.")
		
	print("Tick 2...")
	entity.effects.tick_all() # Should expire now (remaining becomes 0)
	
	# Ticking removes expired effects, so we check if it's gone
	instance = entity.effects._find_instance("buff")
	if instance == null:
		print("✅ PASS: Effect expired and removed.")
	else:
		print("❌ FAIL: Effect should have expired. Remaining: %d" % instance.remaining_turns)
