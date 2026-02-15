extends Node

func _init():
	print("Starting Condition System Verification...")
	test_hp_condition()
	test_effect_condition()

func test_hp_condition():
	print("\n--- Testing HP Condition (< 50%) ---")
	var entity = Entity.new()
	entity.initialize()
	entity.stats.set_base_stat(StatsComponent.StatType.HP, 100)
	entity.stats.set_base_stat(StatsComponent.StatType.MAX_HP, 100)
	entity.stats.finalize_initialization()
	
	# Condition: HP < 50%
	var condition = EffectCondition.new()
	condition.type = EffectCondition.Type.HP_PERCENT_BELOW
	condition.value = 0.5
	condition.target = EffectCondition.TargetType.SELF # Check self hp
	
	var effect = EffectResource.new()
	effect.effect_id = "desperation_heal"
	effect.operation = EffectResource.Operation.HEAL_FLAT
	effect.value = 50.0
	effect.conditions.append(condition)
	
	var instance = EffectInstance.new(effect)
	
	# Test 1: Full HP (Should fail)
	print("Test 1: HP at 100%...")
	OperationExecutor.execute(instance, entity, {})
	if entity.stats.current[StatsComponent.StatType.HP] == 100:
		print("✅ PASS: Effect blocked by condition.")
	else:
		print("❌ FAIL: Effect executed despite condition.")
		
	# Test 2: Low HP (Should succeed)
	print("Test 2: HP at 30%...")
	entity.stats.modify_current(StatsComponent.StatType.HP, -70) # Set to 30
	print("DEBUG: Current HP before exec: %d" % entity.stats.current[StatsComponent.StatType.HP])
	OperationExecutor.execute(instance, entity, {})
	if entity.stats.current[StatsComponent.StatType.HP] == 80: # 30 + 50
		print("✅ PASS: Effect executed when condition met.")
	else:
		print("❌ FAIL: Effect failed to execute. HP: %d" % entity.stats.current[StatsComponent.StatType.HP])

func test_effect_condition():
	print("\n--- Testing Has Effect Condition (Poisoned) ---")
	var entity = Entity.new()
	entity.initialize()
	entity.stats.set_base_stat(StatsComponent.StatType.HP, 100)
	entity.stats.finalize_initialization()
	
	# Setup Poison first
	var poison = EffectResource.new()
	poison.effect_id = "poison"
	
	# Condition: Has effect "poison"
	var condition = EffectCondition.new()
	condition.type = EffectCondition.Type.HAS_EFFECT_ID
	condition.string_value = "poison"
	condition.target = EffectCondition.TargetType.SELF
	
	var effect = EffectResource.new()
	effect.effect_id = "poison_cure"
	effect.operation = EffectResource.Operation.HEAL_FLAT
	effect.value = 10.0
	effect.conditions.append(condition)
	
	var instance = EffectInstance.new(effect)
	
	# Test 1: No Poison (Should fail)
	print("Test 1: No Poison...")
	OperationExecutor.execute(instance, entity, {})
	if entity.stats.current[StatsComponent.StatType.HP] == 100:
		print("✅ PASS: Effect blocked (No poison found).")
	else:
		print("❌ FAIL: Effect executed without poison.")
		
	# Test 2: With Poison (Should succeed)
	print("Test 2: With Poison...")
	entity.effects.apply_effect(poison)
	OperationExecutor.execute(instance, entity, {})
	if entity.stats.current[StatsComponent.StatType.HP] == 100: # Wait, heal adds 10, max is 100?
		# Ah, Entity max hp is 100.
		# Let's damage first
		entity.stats.modify_current(StatsComponent.StatType.HP, -20)
		# Try again
		OperationExecutor.execute(instance, entity, {})
	if entity.stats.current[StatsComponent.StatType.HP] == 90:
		print("✅ PASS: Effect executed when poison present.")
	else:
		print("❌ FAIL: Effect failed. HP: %d" % entity.stats.current[StatsComponent.StatType.HP])
